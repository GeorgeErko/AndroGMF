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
  TStylusPinchAction = (spBegin, spMove, spEnd);
 // два пальца: Center - середина между ними (точки формы), Delta - ее сдвиг,
 // Ratio - изменение расстояния между пальцами
  TStylusPinchEvent = procedure(Action: TStylusPinchAction; const Center, Delta: TPointF; Ratio: Single) of object;

const
 // долгое нажатие, когда система значения не дает: мс и точки формы
  DefLongPressMs = 600;
  DefLongPressSlop = 10;

var
 // Android: до первого касания инструмент не известен - по умолчанию перо
 // (палец сразу только перемещает и масштабирует карту); касание задает
 // настоящий инструмент
{$IFDEF ANDROID}
  StylusTool: TStylusTool = stStylus;  // инструмент последнего касания
{$ELSE}
  StylusTool: TStylusTool = stUnknown; // инструмент последнего касания
{$ENDIF}
  StylusButton: Boolean = False;       // кнопка пера нажата (последнее касание)
{$IFDEF ANDROID}
  StylusDetected: Boolean = True;      // перо использовалось в этом сеансе
{$ELSE}
  StylusDetected: Boolean = False;     // перо использовалось в этом сеансе
{$ENDIF}
 // после первого касания или наведения пера палец только перемещает и
 // масштабирует карту (команды - только пером)
  StylusFingerPans: Boolean = True;
 // Windows, режим касания (кнопка «Стилус»): ёмкостный стилус (кнопка
 // включения, зарядка) система не отличает от пальца. True - касание одним
 // пальцем или стилусом выполняет команды, как мышь; карта - двумя пальцами
 // (перемещение и масштаб). False - касание перемещает карту, команды - мышью
 // или пером Windows
  StylusTouchMode: Boolean = False;

procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
// касание пальцем при работе пером: команды не выполняются, только карта
function FingerOnlyPans: Boolean;
// касание пером с нажатой кнопкой - как правая кнопка мыши
function StylusRightButton: Boolean;
// Windows: касание двумя и более пальцами - от касания вторым пальцем до отрыва
// всех (одиночное касание, начатое первым пальцем, отменяется)
function StylusMultiTouch: Boolean;
// Windows: перемещение и масштаб двумя пальцами по самим касаниям (жест Zoom
// FMX приходит только при изменении расстояния между пальцами - перемещение
// рывками); ставить после InstallStylus
procedure InstallStylusPinch(const OnPinch: TStylusPinchEvent);
// True - два пальца обрабатывает OnPinch, жест Zoom FMX не нужен
function StylusPinch: Boolean;
// Windows: есть сенсорный экран (встроенный или внешний)
function StylusTouchScreen: Boolean;
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

// Android: команды касанием - только пером, палец всегда перемещает карту
function StylusMultiTouch: Boolean;
begin
 Result := False;
end;

// Android: два пальца - жест Zoom FMX
procedure InstallStylusPinch(const OnPinch: TStylusPinchEvent);
begin
end;

function StylusPinch: Boolean;
begin
 Result := False;
end;

function StylusTouchScreen: Boolean;
begin
 Result := True;
end;
{$ELSEIF DEFINED(MSWINDOWS)}
// Windows (Torex RuggedTablet и др.): перо и касание Windows сама превращает в
// сообщения мыши, наведение пера - в WM_MOUSEMOVE (OnHover не нужен), касание
// пером с нажатой кнопкой - в правую кнопку. Окно формы подклассируется:
// по WM_POINTER* (приходят раньше синтезированных из них сообщений мыши)
// запоминается инструмент и кнопка пера, щелчок кнопкой пера над экраном -
// в OnButtonClick; касание - инструмент по режиму касания (StylusTouchMode) и
// число касаний (StylusMultiTouch); сообщения не перехватываются - их, как и раньше,
// обрабатывает FMX.
// Системные жесты пера (нажать и удерживать = правая кнопка, флики, круги
// отклика) для окна отключаются. Указатели (WM_POINTER) - Windows 8 и выше.
uses
  System.SysUtils, Winapi.Windows, Winapi.Messages, FMX.Platform.Win;

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

var
  GForm: TCommonCustomForm;
  GWnd: HWND;
  GOldWndProc: Pointer; // оконная процедура FMX (SetWindowSubclass без comctl32 - в FMX ее нет - не работает)
  GOnButtonClick: TStylusPointEvent;
  GHoverButton: Boolean; // кнопка пера была нажата (наведение или касание)
  GTouchCount: Integer;  // касаний на экране
  GMultiTouch: Boolean;  // было второе касание - до отрыва всех
 // два пальца: первые два касания - номера и точки формы; щипок начат - середина
 // и расстояние прошлого шага
  GOnPinch: TStylusPinchEvent;
  GPinchId: array[0..1] of UINT32;
  GPinchPt: array[0..1] of TPointF;
  GPinchN: Integer;
  GPinchActive: Boolean;
  GPinchCenter: TPointF;
  GPinchDist: Single;

// пикселы экрана - в координаты формы
function FormPoint(Wnd: HWND; P: TPoint): TPointF;
var S: Single;
begin
 Winapi.Windows.ScreenToClient(Wnd, P);
 S := 1;
 if (GForm <> nil) and (GForm.Handle <> nil) and (GForm.Handle.Scale > 0) then S := GForm.Handle.Scale;
 Result := TPointF.Create(P.X / S, P.Y / S);
end;

procedure PinchEnd;
begin
 if GPinchActive and Assigned(GOnPinch) then GOnPinch(spEnd, GPinchCenter, TPointF.Zero, 1);
 GPinchActive := False;
end;

// два пальца на экране: начало щипка, затем сдвиг середины и изменение
// расстояния с прошлого шага (каждое движение любого из пальцев)
procedure PinchUpdate;
var C: TPointF;
    D: Single;
begin
 if (GPinchN < 2) or not Assigned(GOnPinch) then exit;
 C := GPinchPt[0].MidPoint(GPinchPt[1]);
 D := GPinchPt[0].Distance(GPinchPt[1]);
 if D < 2 then exit;
 if not GPinchActive then begin
  GPinchActive := True;
  GOnPinch(spBegin, C, TPointF.Zero, 1);
 end else GOnPinch(spMove, C, C - GPinchCenter, D / GPinchDist);
 GPinchCenter := C;
 GPinchDist := D;
end;

// касание (стилус и палец экран не различает - размер пятна не сообщает):
// первое касание задает инструмент по режиму касания (StylusTouchMode);
// второе касание - StylusMultiTouch до отрыва всех; первые два касания - щипок
procedure TouchMessage(Wnd: HWND; Msg: UINT; wParam: WPARAM);
var Id: UINT32;
    Info: POINTER_INFO;
    P: TPointF;
    I, K: Integer;
    Ok: Boolean;
begin
 Id := GET_POINTERID_WPARAM(wParam);
 FillChar(Info, SizeOf(Info), 0);
 Ok := GetPointerInfo(Id, @Info);
 if Ok then P := FormPoint(Wnd, Info.ptPixelLocation) else P := TPointF.Zero;
 K := -1;
 for I := 0 to GPinchN - 1 do if GPinchId[I] = Id then K := I;
 case Msg of
  WM_POINTERDOWN: begin
  // первое касание - счет заново (отрыв мог потеряться)
   if IS_POINTER_PRIMARY_WPARAM(wParam) then begin
    PinchEnd;
    GPinchN := 0;
    K := -1;
    GTouchCount := 0;
    GMultiTouch := False;
    StylusButton := False;
    StylusDetected := True;
    if StylusTouchMode then StylusTool := stStylus else StylusTool := stFinger;
   end;
   Inc(GTouchCount);
   if GTouchCount >= 2 then GMultiTouch := True;
   if Ok and (K < 0) and (GPinchN < 2) then begin
    GPinchId[GPinchN] := Id;
    GPinchPt[GPinchN] := P;
    Inc(GPinchN);
    PinchUpdate;
   end;
  end;
  WM_POINTERUPDATE: if Ok and (K >= 0) then begin
   GPinchPt[K] := P;
   PinchUpdate;
  end;
  WM_POINTERUP: begin
   if GTouchCount > 0 then Dec(GTouchCount);
   if GTouchCount = 0 then GMultiTouch := False;
   if K >= 0 then begin
    PinchEnd;
    if K = 0 then begin
     GPinchId[0] := GPinchId[1];
     GPinchPt[0] := GPinchPt[1];
    end;
    Dec(GPinchN);
   end;
  end;
 end;
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
  TouchMessage(Wnd, Msg, wParam);
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

function StylusWndProc(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
 case Msg of
  WM_POINTERENTER, WM_POINTERDOWN, WM_POINTERUPDATE, WM_POINTERUP, WM_POINTERLEAVE: PointerMessage(Wnd, Msg, wParam);
 // настоящая мышь (не синтезирована из пера или касания)
  WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN: if (DWORD(GetMessageExtraInfo) and SIGNATURE_MASK) <> MI_WP_SIGNATURE then StylusTool := stMouse;
  WM_TABLET_QUERYSYSTEMGESTURESTATUS: exit(TABLET_GESTURE_FLAGS);
 end;
 Result := CallWindowProc(GOldWndProc, Wnd, Msg, wParam, lParam);
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
 if (GWnd <> 0) and (GOldWndProc <> nil) and IsWindow(GWnd) then SetWindowLongPtr(GWnd, GWLP_WNDPROC, LONG_PTR(GOldWndProc));
 GWnd := Wnd;
 GOldWndProc := Pointer(SetWindowLongPtr(Wnd, GWLP_WNDPROC, LONG_PTR(@StylusWndProc)));
 if GOldWndProc = nil then begin
  GWnd := 0;
  exit;
 end;
// Windows 8+: системные жесты пера отключаются свойством окна
 Atom := GlobalAddAtom(TABLET_PROP);
 SetProp(Wnd, TABLET_PROP, THandle(TABLET_GESTURE_FLAGS));
 GlobalDeleteAtom(Atom);
end;

function StylusMultiTouch: Boolean;
begin
 Result := GMultiTouch;
end;

procedure InstallStylusPinch(const OnPinch: TStylusPinchEvent);
begin
 GOnPinch := OnPinch;
end;

function StylusPinch: Boolean;
begin
 Result := (GOldWndProc <> nil) and Assigned(GOnPinch);
end;

function StylusTouchScreen: Boolean;
begin
 Result := (GetSystemMetrics(SM_DIGITIZER) and (NID_INTEGRATED_TOUCH or NID_EXTERNAL_TOUCH)) <> 0;
end;
{$ELSE}
procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
begin
end;

function StylusMultiTouch: Boolean;
begin
 Result := False;
end;

procedure InstallStylusPinch(const OnPinch: TStylusPinchEvent);
begin
end;

function StylusPinch: Boolean;
begin
 Result := False;
end;

function StylusTouchScreen: Boolean;
begin
 Result := False;
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
