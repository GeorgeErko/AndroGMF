unit AppForms;

// Базовые классы форм и фреймов программы: размеры интерфейса из AppUI.
// Перекрывающие классы (interposer): TForm и TFrame здесь - наследники
// FMX.Forms.TForm/TFrame. Модуль формы или фрейма пишет, как обычно,
// class(TForm)/class(TFrame) - дизайнер видит обычную форму и фрейм (с
// предком другого имени фрейм открывался в дизайнере как форма), а компилятор
// берет классы отсюда, если AppForms стоит в uses после FMX.Forms.
// RegisterClass для форм и фреймов-наследников не вызывать: он регистрирует и
// всех предков, а здешние TForm/TFrame одноименны с FMX.Forms ('A class named
// TFrame already exists'). Встроенному фрейму - опубликованное поле формы
// (класс находится по типу поля).
// TForm - главные формы и диалоги, TFrame - фреймы (панели и
// псевдо-диалоги поверх карты). В Loaded и при смене профиля или масштаба UI
// (TUIMetricsChangedMessage) вызывается ApplyUI: снятие закрепленных стилем
// платформы высот и правила кнопок (AppUI.ApplyUIRules). Наследник дополняет ApplyUI своими размерами.
// Фрейм непрозрачен (Opaque, по умолчанию True): FMX-фрейм и TLayout не имеют
// фона, и через псевдо-диалог на Android просвечивала карта. Фон - прямоугольник
// цвета UI.PanelColor с рамкой UI.PanelBorderColor под всеми элементами
// фрейма; он же перехватывает касания (до карты не доходят). Встроенным
// панелям со своим фоном (таблица слоев в тулбаре, панель GPS) - Opaque := False
// в конструкторе.
// Модальный диалог - ShowDialog(Форма, Процедура результата): форма-диалог
// рисуется в дизайнере как обычная форма. Windows - настоящее модальное окно
// (ShowModal: главная форма заблокирована, диалог не уходит за нее). Android -
// FMX показывает любую форму во весь экран, поэтому диалог - панель поверх
// главной формы: подложка на всё окно (перехватывает касания, DialogShade),
// на ней по центру панель размером с клиентскую область формы-диалога
// (ужимается до экрана) с заголовком (Caption формы, «✕» - отмена), рамкой и
// тенью на подложке, на панель переносятся элементы формы (владелец -
// форма-диалог, ее обработчики работают как прежде). OnShow формы
// вызывается при показе; закрытие (Close, кнопки с ModalResult, Esc / «Назад»
// - DialogKeyDown главной формы) возвращает элементы в форму, убирает панель
// и вызывает OnClose формы (caFree освобождает ее) и процедуру результата.
// Диалог из диалога - стопкой.

interface

uses
  System.SysUtils, System.Classes, System.Messaging, System.UITypes, System.Types, FMX.Types, FMX.Controls, FMX.Forms, FMX.Objects;

type
  TDialogResultProc = TProc<TModalResult>;

  TForm = class(FMX.Forms.TForm)
  private
    FUIMessageId: Integer;
    FDialogWidth, FDialogHeight: Single; // размер диалога: из fmx, затем DialogClientWidth
                                         // (Android размер формы не соблюдает)
    FDialogHost: TObject;                // показ панелью поверх главной формы (Android)
    procedure UIMetricsChanged(const Sender: TObject; const M: TMessage);
    function GetDialogClientWidth: Single;
    procedure SetDialogClientWidth(const Value: Single);
  protected
    procedure Loaded; override;
    procedure DoClose(var CloseAction: TCloseAction); override;
   // размеры UI - элементам формы
    procedure ApplyUI; virtual;
   // нажатие на форме-хозяине, пока этот диалог открыт на ней панелью (Android):
   // MouseDown самой формы-диалога тогда не вызывается. Координаты - формы-
   // хозяина (= абсолютные элементов диалога на панели). Диалог, которому
   // нужна точка нажатия (VarSetDlg - значок «…»), переопределяет
    procedure HostMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
  public
   // нажатие на форме при открытом на ней диалоге-панели - и диалогу
   // (HostMouseDown); фреймам формы с WatchFormMouse - FormMouseDown
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
   // закрыть диалог с результатом - вместо ModalResult := R: у формы на панели
   // (Android) установка ModalResult ее не закрывает
    procedure EndDialog(R: TModalResult);
   // ширина диалога: Windows - ClientWidth окна, Android - ширина панели (при
   // изменении панель меняет ширину); вместо ClientWidth в диалогах, меняющих
   // свою ширину (панель истории VarSetDlg1-3)
    property DialogClientWidth: Single read GetDialogClientWidth write SetDialogClientWidth;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFrame = class(FMX.Forms.TFrame)
  private
    FUIMessageId: Integer;
    FOpaque: Boolean;
    FBackground: TRectangle;
    FWatchFormMouse: Boolean;
    procedure UIMetricsChanged(const Sender: TObject; const M: TMessage);
    procedure SetOpaque(const Value: Boolean);
    procedure UpdateBackground;
    procedure SetWatchFormMouse(const Value: Boolean);
  protected
    procedure Loaded; override;
   // размеры и фон UI - элементам фрейма
    procedure ApplyUI; virtual;
   // нажатие на форме, где лежит фрейм (при WatchFormMouse): MouseDown
   // элементов фрейма вызывается не всегда (у TStringGrid нажатие получает
   // представление сетки). Координаты - формы (= абсолютные элементов фрейма)
    procedure FormMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
    property WatchFormMouse: Boolean read FWatchFormMouse write SetWatchFormMouse;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
   // непрозрачный фон с рамкой (по умолчанию True)
    property Opaque: Boolean read FOpaque write SetOpaque;
  end;

const
 // затемнение фона под модальным диалогом на Android, если тема его не дает
 // (android:backgroundDimAmount темы Material - 0.6)
  DialogDimDefault: Single = 0.6;
 // окно диалога на Android: рамка, скругление углов, тень на подложке
 // (полупрозрачная, со сдвигом вправо-вниз)
  DialogBorderColor: TAlphaColor = $FF000000;
  DialogBorderWidth: Single = 0.5;
  DialogCornerRadius: Single = 4;
  DialogShadowColor: TAlphaColor = $40000000;
  DialogShadowOffset: Single = 5;  // тень справа и снизу
  DialogShadowEdge: Single = 2;    // тень слева и сверху
 // заголовок окна: фон (чуть темнее фона окна), высота - UI.Metrics.TitleHeight,
 // шрифт - UI.Metrics.TitleFontSize, текст - Caption формы, справа «✕» (отмена)
  DialogTitleColor: TAlphaColor = $FFDCDCDC;

// модальный показ формы-диалога (Windows - ShowModal, Android - панель поверх
// главной формы); ResultProc - после закрытия, с ModalResult (mrCancel, если
// не задан)
procedure ShowDialog(Dialog: TForm; const ResultProc: TDialogResultProc = nil);
// открыт диалог панелью (Android)
function DialogOpen: Boolean;
// клавиша главной формы при открытом диалоге: Esc / «Назад» закрывают его
// (mrCancel), True - клавиша обработана; остальные клавиши - элементам диалога,
// не операциям карты (проверять DialogOpen)
function DialogKeyDown(var Key: Word; var KeyChar: WideChar): Boolean;
// подложка модального диалога на Android: черная с прозрачностью затемнения
// фона стандартных окон Android (android:backgroundDimAmount текущей темы,
// иначе DialogDimDefault); перехватывает касания
function DialogShade: TAlphaColor;

implementation uses System.Math, System.Generics.Collections, FMX.StdCtrls, AppUI,
                    FMX.Graphics, FMX.Layouts
{$IFDEF ANDROID}
                    , Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Util
{$ENDIF};

const
  AttrBackgroundDimAmount = $01010032; // android.R.attr.backgroundDimAmount

var
  GDialogDim: Single = -1; // затемнение из темы (-1 - еще не прочитано)

function DialogShade: TAlphaColor;
{$IFDEF ANDROID}
var TV: JTypedValue;
{$ENDIF}
begin
 if GDialogDim < 0 then begin
  GDialogDim := DialogDimDefault;
 {$IFDEF ANDROID}
  try
   TV := TJTypedValue.JavaClass.init;
   if TAndroidHelper.Context.getTheme.resolveAttribute(AttrBackgroundDimAmount, TV, True) then GDialogDim := TV.getFloat;
  except
  end;
 {$ENDIF}
  GDialogDim := EnsureRange(GDialogDim, 0, 1);
 end;
 Result := TAlphaColor(Round(GDialogDim * 255) shl 24); // черный, альфа - затемнение
end;

type
  TButtonSave = record
    Result: TModalResult;
    Click: TNotifyEvent;
  end;

 // диалог панелью поверх главной формы (Android)
  TDialogHost = class
  private
    FDialog: TForm;
    FHostForm: TCommonCustomForm;
    FBack: TRectangle;
    FPanel: TRectangle;
    FFrame: TLayout;       // панель и тень (тень выходит за край панели, а панель обрезает свои элементы)
    FShadow: TRectangle;
    FTitle: TRectangle;    // заголовок: Caption формы и «✕»
    FContent: TLayout;     // элементы формы-диалога (под заголовком, внутри рамки)
    FControls: TList<TControl>;
    FButtons: TDictionary<TObject, TButtonSave>;
    FResultProc: TDialogResultProc;
    FClosed: Boolean;
    procedure WrapButtons(Root: TFmxObject);
    procedure ButtonClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure Restore;
  public
    constructor Create(ADialog: TForm; AHostForm: TCommonCustomForm; const AResultProc: TDialogResultProc);
    destructor Destroy; override;
    procedure Show;
    procedure UpdateSize;
    procedure Closed(R: TModalResult);
  end;

var GDialogs: TList<TDialogHost>;
   // фреймы, получающие нажатия своей формы (TFrame.WatchFormMouse)
    GMouseFrames: TList<TFrame>;

function DialogStack: TList<TDialogHost>;
begin
 if GDialogs = nil then GDialogs := TList<TDialogHost>.Create;
 Result := GDialogs;
end;

constructor TDialogHost.Create(ADialog: TForm; AHostForm: TCommonCustomForm; const AResultProc: TDialogResultProc);
begin
 inherited Create;
 FDialog := ADialog;
 FHostForm := AHostForm;
 FResultProc := AResultProc;
 FControls := TList<TControl>.Create;
 FButtons := TDictionary<TObject, TButtonSave>.Create;
end;

destructor TDialogHost.Destroy;
begin
 FControls.Free;
 FButtons.Free;
 inherited;
end;

// кнопки с ModalResult: после переноса на панель кнопка ищет форму через сцену
// - нашла бы главную; на время показа ModalResult снят, щелчок - ButtonClick
procedure TDialogHost.WrapButtons(Root: TFmxObject);
var I: Integer;
    B: TCustomButton;
    S: TButtonSave;
begin
 for I := 0 to Root.ChildrenCount - 1 do begin
  if Root.Children[I] is TCustomButton then begin
   B := TCustomButton(Root.Children[I]);
   if B.ModalResult <> mrNone then begin
    S.Result := B.ModalResult;
    S.Click := B.OnClick;
    FButtons.AddOrSetValue(B, S);
    B.ModalResult := mrNone;
    B.OnClick := ButtonClick;
   end;
  end;
  WrapButtons(Root.Children[I]);
 end;
end;

procedure TDialogHost.Show;
var I: Integer;
    C: TControl;
    Btn: TSpeedButton;
    Lbl: TLabel;
begin
 FBack := TRectangle.Create(nil);
 FBack.Fill.Color := DialogShade;
 FBack.Stroke.Kind := TBrushKind.None;
 FBack.HitTest := True;
 FBack.Align := TAlignLayout.Contents;
 FBack.Parent := FHostForm;
 FBack.BringToFront;
 FFrame := TLayout.Create(FBack);
 FFrame.HitTest := False;
 FFrame.Align := TAlignLayout.Center;
 FFrame.Parent := FBack;
 FShadow := TRectangle.Create(FFrame);
 FShadow.Fill.Color := DialogShadowColor;
 FShadow.Stroke.Kind := TBrushKind.None;
 FShadow.XRadius := DialogCornerRadius;
 FShadow.YRadius := DialogCornerRadius;
 FShadow.HitTest := False;
 FShadow.Parent := FFrame;
 FPanel := TRectangle.Create(FFrame);
 FPanel.Fill.Color := UI.PanelColor;
 FPanel.Stroke.Color := DialogBorderColor;
 FPanel.Stroke.Thickness := DialogBorderWidth;
 FPanel.XRadius := DialogCornerRadius;
 FPanel.YRadius := DialogCornerRadius;
 FPanel.HitTest := True;
 FPanel.ClipChildren := True;
// заголовок и содержимое - внутри рамки: элементы у края ее не закрывают
 FPanel.Padding.Rect := TRectF.Create(DialogBorderWidth, DialogBorderWidth, DialogBorderWidth, DialogBorderWidth);
 FPanel.Parent := FFrame;
 FTitle := TRectangle.Create(FPanel);
 FTitle.Fill.Color := DialogTitleColor;
 FTitle.Stroke.Color := DialogBorderColor;
 FTitle.Sides := [TSide.Bottom];
 FTitle.HitTest := True;
 FTitle.Height := UI.Metrics.TitleHeight;
 FTitle.Align := TAlignLayout.Top;
 FTitle.Parent := FPanel;
 Btn := TSpeedButton.Create(FTitle);
 Btn.Text := #$2715;
 Btn.Hint := 'Закрыть';
 Btn.StyledSettings := Btn.StyledSettings - [TStyledSetting.Size];
 Btn.TextSettings.Font.Size := UI.Metrics.TitleFontSize;
 Btn.Width := UI.Metrics.TitleHeight;
 Btn.Align := TAlignLayout.Right;
 Btn.OnClick := CloseClick;
 Btn.Parent := FTitle;
// кнопка создана после Loaded формы - правила AppUI ей отдельно: иначе стиль
// Android закрепляет высоту 48, и Align = Right ее не меняет
 ApplyUIRules(FTitle);
 Lbl := TLabel.Create(FTitle);
 Lbl.Text := FDialog.Caption;
 Lbl.StyledSettings := Lbl.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
 Lbl.TextSettings.Font.Size := UI.Metrics.TitleFontSize;
 Lbl.TextSettings.Font.Style := [TFontStyle.fsBold];
 Lbl.TextSettings.WordWrap := False;
 Lbl.TextSettings.Trimming := TTextTrimming.Character;
 Lbl.Margins.Left := 8;
 Lbl.HitTest := False;
 Lbl.Align := TAlignLayout.Client;
 Lbl.Parent := FTitle;
 FContent := TLayout.Create(FPanel);
 FContent.ClipChildren := True;
 FContent.Align := TAlignLayout.Client;
 FContent.Parent := FPanel;
 UpdateSize;
 for I := 0 to FDialog.ChildrenCount - 1 do
  if FDialog.Children[I] is TControl then FControls.Add(TControl(FDialog.Children[I]));
 for C in FControls do C.Parent := FContent;
 WrapButtons(FContent);
 FDialog.FDialogHost := Self;
 DialogStack.Add(Self);
 if Assigned(FDialog.OnShow) then FDialog.OnShow(FDialog);
end;

// размер панели: содержимое - размер диалога (FDialogWidth/Height), плюс
// заголовок и рамка; не больше окна. Тень выступает за панель справа и снизу
// на DialogShadowOffset, слева и сверху - на DialogShadowEdge
procedure TDialogHost.UpdateSize;
var W, H: Single;
begin
 if FPanel = nil then exit;
 W := FDialog.FDialogWidth;
 H := FDialog.FDialogHeight;
 if W <= 0 then W := FDialog.ClientWidth;
 if H <= 0 then H := FDialog.ClientHeight;
 W := W + 2 * DialogBorderWidth;
 H := H + 2 * DialogBorderWidth + UI.Metrics.TitleHeight;
 W := Min(W, FHostForm.ClientWidth - 16 - DialogShadowOffset - DialogShadowEdge);
 H := Min(H, FHostForm.ClientHeight - 16 - DialogShadowOffset - DialogShadowEdge);
 FFrame.Width := W + DialogShadowEdge + DialogShadowOffset;
 FFrame.Height := H + DialogShadowEdge + DialogShadowOffset;
 FShadow.SetBounds(0, 0, FFrame.Width, FFrame.Height);
 FPanel.SetBounds(DialogShadowEdge, DialogShadowEdge, W, H);
end;

// «✕» заголовка - отмена (как Esc и «Назад»)
procedure TDialogHost.CloseClick(Sender: TObject);
begin
 if FClosed then exit;
 FDialog.ModalResult := mrCancel;
 FDialog.Close;
end;

// щелчок кнопки с ModalResult: результат, ее обработчик, затем закрытие
procedure TDialogHost.ButtonClick(Sender: TObject);
var S: TButtonSave;
begin
 if not FButtons.TryGetValue(Sender, S) then exit;
// результат - до обработчика: он может сам закрыть диалог (Close)
 FDialog.ModalResult := S.Result;
 if Assigned(S.Click) then S.Click(Sender);
 if FClosed then exit;
 FDialog.Close;
end;

procedure TDialogHost.Restore;
var C: TControl;
    P: TPair<TObject, TButtonSave>;
begin
 for P in FButtons do begin
  TCustomButton(P.Key).ModalResult := P.Value.Result;
  TCustomButton(P.Key).OnClick := P.Value.Click;
 end;
 for C in FControls do C.Parent := FDialog;
end;

// форма-диалог закрыта (TForm.DoClose, после ее OnClose): элементы - обратно в
// форму, панель убирается, процедура результата. Сам объект освобождается
// позже: Closed вызывается из обработчиков, которые еще работают с ним
procedure TDialogHost.Closed(R: TModalResult);
var Proc: TDialogResultProc;
    Back: TRectangle;
    Self_: TDialogHost;
begin
 if FClosed then exit;
 FClosed := True;
 Restore;
 DialogStack.Remove(Self);
 Back := FBack;
 FBack := nil;
 Back.Parent := nil;
 Proc := FResultProc;
 FResultProc := nil;
 Self_ := Self;
 TThread.ForceQueue(nil, procedure begin Back.Free; Self_.Free; end);
 if R = mrNone then R := mrCancel;
 if Assigned(Proc) then Proc(R);
end;

procedure ShowDialog(Dialog: TForm; const ResultProc: TDialogResultProc);
var Host: TCommonCustomForm;
begin
 if Dialog = nil then exit;
{$IF DEFINED(ANDROID) or DEFINED(IOS)}
 Host := Application.MainForm;
 if (Host = nil) or (Host = Dialog) then Host := Screen.ActiveForm;
 if (Host <> nil) and (Host <> Dialog) then begin
  TDialogHost.Create(Dialog, Host, ResultProc).Show;
  exit;
 end;
{$ENDIF}
 Dialog.ShowModal(
  procedure(R: TModalResult)
  begin
   if R = mrNone then R := mrCancel;
   if Assigned(ResultProc) then ResultProc(R);
  end);
end;

function DialogOpen: Boolean;
begin
 Result := (GDialogs <> nil) and (GDialogs.Count > 0);
end;

function DialogKeyDown(var Key: Word; var KeyChar: WideChar): Boolean;
var D: TForm;
begin
 Result := False;
 if not DialogOpen or not ((Key = vkEscape) or (Key = vkHardwareBack)) then exit;
 D := GDialogs.Last.FDialog;
 Key := 0;
 KeyChar := #0;
 D.ModalResult := mrCancel;
 D.Close;
 Result := True;
end;

{ TForm }

constructor TForm.Create(AOwner: TComponent);
begin
 FUIMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TUIMetricsChangedMessage, UIMetricsChanged);
 inherited;
end;

destructor TForm.Destroy;
begin
 TMessageManager.DefaultManager.Unsubscribe(TUIMetricsChangedMessage, FUIMessageId);
 inherited;
end;

// образцы стиля формы исправляются до первой отрисовки, элементы - после загрузки
procedure TForm.Loaded;
begin
// размер диалога - из fmx: OriginalContainerSize запоминается при чтении
// ClientWidth/ClientHeight; сам ClientWidth на Android уже равен экрану
 FDialogWidth := OriginalContainerSize.X;
 FDialogHeight := OriginalContainerSize.Y;
 if FDialogWidth <= 0 then FDialogWidth := ClientWidth;
 if FDialogHeight <= 0 then FDialogHeight := ClientHeight;
 UnfixFormButtonHeights(Self);
 inherited;
 ApplyUI;
end;

// закрытие формы, показанной панелью: панель убирается (после OnClose формы)
procedure TForm.DoClose(var CloseAction: TCloseAction);
var H: TDialogHost;
begin
 inherited;
 if (CloseAction = TCloseAction.caNone) or (FDialogHost = nil) then exit;
 H := TDialogHost(FDialogHost);
 FDialogHost := nil;
 H.Closed(ModalResult);
end;

procedure TForm.EndDialog(R: TModalResult);
begin
 ModalResult := R;
 if FDialogHost <> nil then Close;
end;

function TForm.GetDialogClientWidth: Single;
begin
{$IF DEFINED(ANDROID) or DEFINED(IOS)}
 Result := FDialogWidth;
{$ELSE}
 Result := ClientWidth;
{$ENDIF}
end;

procedure TForm.SetDialogClientWidth(const Value: Single);
begin
 FDialogWidth := Value;
{$IF not (DEFINED(ANDROID) or DEFINED(IOS))}
 ClientWidth := Round(Value);
{$ENDIF}
 if FDialogHost <> nil then TDialogHost(FDialogHost).UpdateSize;
end;

procedure TForm.HostMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
end;

procedure TForm.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var H: TDialogHost;
    F: TFrame;
begin
 if DialogOpen then begin
  H := GDialogs.Last;
  if (H.FHostForm = Self) and (H.FDialog <> Self) then H.FDialog.HostMouseDown(Button, Shift, X, Y);
 end;
 if GMouseFrames <> nil then
  for F in GMouseFrames.ToArray do
   if (F.Root <> nil) and (F.Root.GetObject = Self) then F.FormMouseDown(Button, Shift, X, Y);
 inherited;
end;

procedure TForm.ApplyUI;
begin
 ApplyUIRules(Self);
end;

procedure TForm.UIMetricsChanged(const Sender: TObject; const M: TMessage);
begin
 ApplyUI;
end;

{ TFrame }

constructor TFrame.Create(AOwner: TComponent);
begin
 FOpaque := True;
 FUIMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TUIMetricsChangedMessage, UIMetricsChanged);
 inherited;
end;

destructor TFrame.Destroy;
begin
 WatchFormMouse := False;
 TMessageManager.DefaultManager.Unsubscribe(TUIMetricsChangedMessage, FUIMessageId);
 inherited;
end;

procedure TFrame.SetWatchFormMouse(const Value: Boolean);
begin
 if FWatchFormMouse = Value then exit;
 FWatchFormMouse := Value;
 if Value then begin
  if GMouseFrames = nil then GMouseFrames := TList<TFrame>.Create;
  GMouseFrames.Add(Self);
 end else
 if GMouseFrames <> nil then GMouseFrames.Remove(Self);
end;

procedure TFrame.FormMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
end;

procedure TFrame.Loaded;
begin
 inherited;
 ApplyUI;
end;

procedure TFrame.ApplyUI;
begin
 ApplyUIRules(Self);
 UpdateBackground;
end;

procedure TFrame.UIMetricsChanged(const Sender: TObject; const M: TMessage);
begin
 ApplyUI;
end;

procedure TFrame.SetOpaque(const Value: Boolean);
begin
 if FOpaque = Value then exit;
 FOpaque := Value;
 UpdateBackground;
end;

// фон - первым дочерним (под остальными), Align = Contents: отступы и
// выравнивание элементов фрейма не меняются; не сохраняется в fmx
procedure TFrame.UpdateBackground;
begin
 if not FOpaque then begin
  FreeAndNil(FBackground);
  exit;
 end;
 if FBackground = nil then begin
  FBackground := TRectangle.Create(Self);
  FBackground.Stored := False;
  FBackground.Locked := True;
  FBackground.Align := TAlignLayout.Contents;
  FBackground.Parent := Self;
  FBackground.SendToBack;
 end;
 FBackground.Fill.Color := UI.PanelColor;
 FBackground.Stroke.Color := UI.PanelBorderColor;
 FBackground.Stroke.Thickness := 1;
 FBackground.HitTest := True;
end;

initialization
finalization
 FreeAndNil(GDialogs);
 FreeAndNil(GMouseFrames);
end.
