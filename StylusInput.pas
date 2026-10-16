unit StylusInput;

// Перо (S-Pen) на Android, активное перо на Windows (см. ветку MSWINDOWS).
// FMX превращает касание пером и пальцем в одинаковые события мыши (mbLeft),
// кнопку пера не читает, а наведение пера над экраном (без касания) не
// обрабатывает совсем. InstallStylus ставит на вид формы два слушателя:
// - касания: запоминается инструмент (перо, палец, ластик) и нажата ли кнопка
//   пера; касание не перехватывается - его, как и раньше, обрабатывает FMX;
// - наведения: движение пера над экраном - в OnHover, щелчок кнопкой пера
//   над экраном - в OnButtonClick (координаты - формы).
// Форма по StylusTool / StylusButton сама решает, что делать с касанием.
// На остальных платформах (кроме Windows) InstallStylus ничего не делает.

interface

uses
  System.Types, System.Classes, FMX.Forms;

type
  TStylusTool = (stUnknown, stFinger, stStylus, stEraser, stMouse);
  TStylusHoverAction = (shEnter, shMove, shExit);
  TStylusHoverEvent = procedure(Action: TStylusHoverAction; const P: TPointF) of object;
  TStylusPointEvent = procedure(const P: TPointF) of object;

const
 // долгое нажатие, когда система значения не дает: мс и точки формы
  DefLongPressMs = 600;
  DefLongPressSlop = 10;

var
  StylusTool: TStylusTool = stUnknown; // инструмент последнего касания
  StylusButton: Boolean = False;       // кнопка пера нажата (последнее касание)
  StylusDetected: Boolean = False;     // перо использовалось в этом сеансе
 // после первого касания или наведения пера палец только перемещает и
 // масштабирует карту (команды - только пером)
  StylusFingerPans: Boolean = True;

procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
// касание пальцем при работе пером: команды не выполняются, только карта
function FingerOnlyPans: Boolean;
// касание пером с нажатой кнопкой - как правая кнопка мыши
function StylusRightButton: Boolean;
// долгое нажатие (правая кнопка): время, мс, и допуск сдвига пальца или пера,
// точки формы - системные (Android - ViewConfiguration; Windows - время не
// задается API, по умолчанию 600, допуск - SM_CXDRAG, не меньше 10)
function LongPressTimeout: Integer;
function LongPressSlop: Single;

implementation

{$IF DEFINED(ANDROID)}
uses
  System.SysUtils, Androidapi.JNIBridge, Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers, FMX.Platform.Android;

const
 // android.view.MotionEvent
  TOOL_TYPE_FINGER = 1;
  TOOL_TYPE_STYLUS = 2;
  TOOL_TYPE_MOUSE = 3;
  TOOL_TYPE_ERASER = 4;
  ACTION_DOWN = 0;
  ACTION_HOVER_MOVE = 7;
  ACTION_HOVER_ENTER = 9;
  ACTION_HOVER_EXIT = 10;
  BUTTON_SECONDARY = 2;
  BUTTON_STYLUS_PRIMARY = $20;
  BUTTON_STYLUS_SECONDARY = $40;
  PEN_BUTTONS = BUTTON_SECONDARY or BUTTON_STYLUS_PRIMARY or BUTTON_STYLUS_SECONDARY;

type
 // android.view.ViewConfiguration - в JNI-модулях Delphi нет, только нужное
  JViewConfiguration = interface;

  JViewConfigurationClass = interface(JObjectClass)
    ['{6DA76568-2A81-4A98-9E12-C95F57F5F4C2}']
    function get(context: JContext): JViewConfiguration; cdecl;
    function getLongPressTimeout: Integer; cdecl;
  end;

  [JavaSignature('android/view/ViewConfiguration')]
  JViewConfiguration = interface(JObject)
    ['{392BF1A7-77AE-441C-9D28-647137B588F1}']
    function getScaledTouchSlop: Integer; cdecl;
  end;

  TJViewConfiguration = class(TJavaGenericImport<JViewConfigurationClass, JViewConfiguration>) end;

  TStylusTouchListener = class(TJavaLocal, JView_OnTouchListener)
  public
    function onTouch(v: JView; event: JMotionEvent): Boolean; cdecl;
  end;

  TStylusHoverListener = class(TJavaLocal, JView_OnHoverListener)
  public
    function onHover(v: JView; event: JMotionEvent): Boolean; cdecl;
  end;

var
  GForm: TCommonCustomForm;
  GOnHover: TStylusHoverEvent;
  GOnButtonClick: TStylusPointEvent;
  GTouchListener: JView_OnTouchListener;
  GHoverListener: JView_OnHoverListener;
  GHoverButton: Boolean; // кнопка пера была нажата при наведении

function ToolOf(event: JMotionEvent): TStylusTool;
begin
 case event.getToolType(0) of
  TOOL_TYPE_FINGER: Result := stFinger;
  TOOL_TYPE_STYLUS: Result := stStylus;
  TOOL_TYPE_ERASER: Result := stEraser;
  TOOL_TYPE_MOUSE: Result := stMouse;
 else
  Result := stUnknown;
 end;
end;

// пикселы вида - в координаты формы
function FormPoint(event: JMotionEvent): TPointF;
var S: Single;
begin
 S := 1;
 if (GForm <> nil) and (GForm.Handle <> nil) and (GForm.Handle.Scale > 0) then S := GForm.Handle.Scale;
 Result := TPointF.Create(event.getX / S, event.getY / S);
end;

// инструмент и кнопка пера - до обработки касания FMX (слушатель вызывается
// раньше onTouchEvent вида); False - касание обрабатывается как обычно
function TStylusTouchListener.onTouch(v: JView; event: JMotionEvent): Boolean;
begin
 Result := False;
 if event.getActionMasked = ACTION_DOWN then StylusTool := ToolOf(event);
 StylusButton := (StylusTool in [stStylus, stEraser]) and ((event.getButtonState and PEN_BUTTONS) <> 0);
 if StylusTool in [stStylus, stEraser] then StylusDetected := True;
end;

function TStylusHoverListener.onHover(v: JView; event: JMotionEvent): Boolean;
var P: TPointF;
    Btn: Boolean;
    Action: Integer;
begin
 Result := False;
 if not (ToolOf(event) in [stStylus, stEraser]) then exit;
 StylusDetected := True;
// перо над экраном - текущий инструмент (после жестов пальцами StylusTool
// оставался stFinger, и движения пера считались движениями пальца)
 StylusTool := ToolOf(event);
 StylusButton := False;
 Result := True;
 P := FormPoint(event);
// щелчок кнопкой пера над экраном (без касания)
 Btn := (event.getButtonState and PEN_BUTTONS) <> 0;
 if Btn and not GHoverButton and Assigned(GOnButtonClick) then GOnButtonClick(P);
 GHoverButton := Btn;
 Action := event.getActionMasked;
 if not Assigned(GOnHover) then exit;
 if Action = ACTION_HOVER_ENTER then GOnHover(shEnter, P) else
 if Action = ACTION_HOVER_MOVE then GOnHover(shMove, P) else
 if Action = ACTION_HOVER_EXIT then begin
  GHoverButton := False;
  GOnHover(shExit, P);
 end;
end;

function LongPressTimeout: Integer;
begin
 Result := TJViewConfiguration.JavaClass.getLongPressTimeout;
 if Result <= 0 then Result := DefLongPressMs;
end;

// пикселы экрана - в точки формы
function LongPressSlop: Single;
var S: Single;
begin
 S := 1;
 if (GForm <> nil) and (GForm.Handle <> nil) and (GForm.Handle.Scale > 0) then S := GForm.Handle.Scale;
 Result := TJViewConfiguration.JavaClass.get(TAndroidHelper.Context).getScaledTouchSlop / S;
 if Result <= 0 then Result := DefLongPressSlop;
end;

procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
var View: JView;
begin
 if (Form = nil) or (Form.Handle = nil) then exit;
 GForm := Form;
 GOnHover := OnHover;
 GOnButtonClick := OnButtonClick;
 View := WindowHandleToPlatform(Form.Handle).View;
 if View = nil then exit;
 if GTouchListener = nil then GTouchListener := TStylusTouchListener.Create;
 if GHoverListener = nil then GHoverListener := TStylusHoverListener.Create;
 View.setOnTouchListener(GTouchListener);
 View.setOnHoverListener(GHoverListener);
end;
{$ELSEIF DEFINED(MSWINDOWS)}
// Windows (Torex RuggedTablet и др.): перо и касание Windows сама превращает в
// сообщения мыши, наведение пера - в WM_MOUSEMOVE (OnHover не нужен), касание
// пером с нажатой кнопкой - в правую кнопку. Окно формы подклассируется:
// по WM_POINTER* (приходят раньше синтезированных из них сообщений мыши)
// запоминается инструмент и кнопка пера, щелчок кнопкой пера над экраном -
// в OnButtonClick; сообщения не перехватываются - их, как и раньше, обрабатывает FMX.
// Системные жесты пера (нажать и удерживать = правая кнопка, флики, круги
// отклика) для окна отключаются. Указатели (WM_POINTER) - Windows 8 и выше.
uses
  System.SysUtils, Winapi.Windows, Winapi.Messages, Winapi.CommCtrl, FMX.Platform.Win;

const
 // winuser.h: POINTER_INPUT_TYPE
  PTR_TOUCH = 2;
  PTR_PEN = 3;
 // сообщения мыши, синтезированные из пера или касания (GetMessageExtraInfo)
  MI_WP_SIGNATURE = $FF515700;
  SIGNATURE_MASK = $FFFFFF00;
 // tpcshrd.h: отключение системных жестов пера и касания для окна
  TABLET_DISABLE_PRESSANDHOLD = $00000001;
  TABLET_DISABLE_PENTAPFEEDBACK = $00000008;
  TABLET_DISABLE_PENBARRELFEEDBACK = $00000010;
  TABLET_DISABLE_FLICKS = $00010000;
  TABLET_GESTURE_FLAGS = TABLET_DISABLE_PRESSANDHOLD or TABLET_DISABLE_PENTAPFEEDBACK or TABLET_DISABLE_PENBARRELFEEDBACK or TABLET_DISABLE_FLICKS;
  TABLET_PROP = 'MicrosoftTabletPenServiceProperty';
  STYLUS_SUBCLASS_ID = $5354594C;

var
  GForm: TCommonCustomForm;
  GWnd: HWND;
  GOnButtonClick: TStylusPointEvent;
  GHoverButton: Boolean; // кнопка пера была нажата (наведение или касание)

// пикселы экрана - в координаты формы
function FormPoint(Wnd: HWND; P: TPoint): TPointF;
var S: Single;
begin
 Winapi.Windows.ScreenToClient(Wnd, P);
 S := 1;
 if (GForm <> nil) and (GForm.Handle <> nil) and (GForm.Handle.Scale > 0) then S := GForm.Handle.Scale;
 Result := TPointF.Create(P.X / S, P.Y / S);
end;

procedure PointerMessage(Wnd: HWND; Msg: UINT; wParam: WPARAM);
var Id: UINT32;
    PType: POINTER_INPUT_TYPE;
    Info: POINTER_PEN_INFO;
    Btn: Boolean;
    P: TPointF;
begin
 Id := GET_POINTERID_WPARAM(wParam);
 if not GetPointerType(Id, @PType) then exit;
 if PType = PTR_TOUCH then begin
  if Msg = WM_POINTERDOWN then StylusTool := stFinger;
  exit;
 end;
 if PType <> PTR_PEN then exit;
 FillChar(Info, SizeOf(Info), 0);
 if not GetPointerPenInfo(Id, @Info) then exit;
 StylusDetected := True;
// перевернутое перо или кнопка ластика - ластик
 if (Info.penFlags and (PEN_FLAG_INVERTED or PEN_FLAG_ERASER)) <> 0 then StylusTool := stEraser else StylusTool := stStylus;
 Btn := (Info.penFlags and PEN_FLAG_BARREL) <> 0;
 if IS_POINTER_INCONTACT_WPARAM(wParam) then begin
  StylusButton := Btn;
  GHoverButton := Btn;
  exit;
 end;
 StylusButton := False;
 if Msg = WM_POINTERLEAVE then begin
  GHoverButton := False;
  exit;
 end;
// щелчок кнопкой пера над экраном (без касания); вызов - вне оконной процедуры
 if Btn and not GHoverButton and Assigned(GOnButtonClick) then begin
  P := FormPoint(Wnd, Info.pointerInfo.ptPixelLocation);
  TThread.ForceQueue(nil, procedure begin if Assigned(GOnButtonClick) then GOnButtonClick(P); end);
 end;
 GHoverButton := Btn;
end;

function StylusWndProc(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM; uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT; stdcall;
begin
 case Msg of
  WM_POINTERENTER, WM_POINTERDOWN, WM_POINTERUPDATE, WM_POINTERUP, WM_POINTERLEAVE: PointerMessage(Wnd, Msg, wParam);
 // настоящая мышь (не синтезирована из пера или касания)
  WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN: if (DWORD(GetMessageExtraInfo) and SIGNATURE_MASK) <> MI_WP_SIGNATURE then StylusTool := stMouse;
  WM_TABLET_QUERYSYSTEMGESTURESTATUS: exit(TABLET_GESTURE_FLAGS);
 end;
 Result := DefSubclassProc(Wnd, Msg, wParam, lParam);
end;

// время «нажать и удерживать» Windows через API не получить - по умолчанию
function LongPressTimeout: Integer;
begin
 Result := DefLongPressMs;
end;

// порог начала перетаскивания (пикселы экрана) - в точки формы; рассчитан на
// мышь (обычно 4), для пальца мал - не меньше DefLongPressSlop
function LongPressSlop: Single;
var S: Single;
begin
 S := 1;
 if (GForm <> nil) and (GForm.Handle <> nil) and (GForm.Handle.Scale > 0) then S := GForm.Handle.Scale;
 Result := GetSystemMetrics(SM_CXDRAG) / S;
 if Result < DefLongPressSlop then Result := DefLongPressSlop;
end;

procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
var Wnd: HWND;
    Atom: Word;
begin
 if (Form = nil) or (Form.Handle = nil) then exit;
 GForm := Form;
 GOnButtonClick := OnButtonClick;
 if not TOSVersion.Check(6, 2) then exit;
 Wnd := FormToHWND(Form);
 if (Wnd = 0) or (Wnd = GWnd) then exit;
 if GWnd <> 0 then RemoveWindowSubclass(GWnd, @StylusWndProc, STYLUS_SUBCLASS_ID);
 GWnd := Wnd;
 SetWindowSubclass(Wnd, @StylusWndProc, STYLUS_SUBCLASS_ID, 0);
// Windows 8+: системные жесты пера отключаются свойством окна
 Atom := GlobalAddAtom(TABLET_PROP);
 SetProp(Wnd, TABLET_PROP, THandle(TABLET_GESTURE_FLAGS));
 GlobalDeleteAtom(Atom);
end;
{$ELSE}
procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
begin
end;

function LongPressTimeout: Integer;
begin
 Result := DefLongPressMs;
end;

function LongPressSlop: Single;
begin
 Result := DefLongPressSlop;
end;
{$ENDIF}

function FingerOnlyPans: Boolean;
begin
 Result := StylusFingerPans and StylusDetected and (StylusTool = stFinger);
end;

function StylusRightButton: Boolean;
begin
 Result := StylusButton and (StylusTool in [stStylus, stEraser]);
end;

end.
