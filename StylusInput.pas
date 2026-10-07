unit StylusInput;

// Перо (S-Pen) на Android.
// FMX превращает касание пером и пальцем в одинаковые события мыши (mbLeft),
// кнопку пера не читает, а наведение пера над экраном (без касания) не
// обрабатывает совсем. InstallStylus ставит на вид формы два слушателя:
// - касания: запоминается инструмент (перо, палец, ластик) и нажата ли кнопка
//   пера; касание не перехватывается - его, как и раньше, обрабатывает FMX;
// - наведения: движение пера над экраном - в OnHover, щелчок кнопкой пера
//   над экраном - в OnButtonClick (координаты - формы).
// Форма по StylusTool / StylusButton сама решает, что делать с касанием.
// На остальных платформах InstallStylus ничего не делает.

interface

uses
  System.Types, System.Classes, FMX.Forms;

type
  TStylusTool = (stUnknown, stFinger, stStylus, stEraser, stMouse);
  TStylusHoverAction = (shEnter, shMove, shExit);
  TStylusHoverEvent = procedure(Action: TStylusHoverAction; const P: TPointF) of object;
  TStylusPointEvent = procedure(const P: TPointF) of object;

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

implementation

{$IFDEF ANDROID}
uses
  System.SysUtils, Androidapi.JNIBridge, Androidapi.JNI.GraphicsContentViewText, FMX.Platform.Android;

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
{$ELSE}
procedure InstallStylus(Form: TCommonCustomForm; const OnHover: TStylusHoverEvent; const OnButtonClick: TStylusPointEvent);
begin
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
