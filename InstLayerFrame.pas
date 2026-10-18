unit InstLayerFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.TreeView, FMX.TextLayout,
  newLayersTable, newResource, FMX.Controls.Presentation,
  MainFrmSkia, newProcs, System.ImageList, FMX.ImgList, AppForms;

type
  TLayerFrame = class(TFrame)
    HeaderLay: TLayout;
    HeaderBg: TRectangle;
    btnDrop: TButton;
    PopupLayers: TPopup;
    PopupLay: TLayout;
    TreeLayers: TTreeView;
    ButtonsLay: TLayout;
    btnAllOn: TButton;
    btnAllOff: TButton;
    btnInvert: TButton;
    btnCancel: TButton;
    btnOk: TButton;
    ImageList1: TImageList;
    Layout1: TLayout;
    SizeGrip1: TSizeGrip;
    procedure btnDropClick(Sender: TObject);
    procedure chkLayerChange(Sender: TObject);
    procedure TreeLayersMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnAllOnClick(Sender: TObject);
    procedure btnAllOffClick(Sender: TObject);
    procedure btnInvertClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FLayerTable: TLayerTable;
    FUpdating: Boolean;
    FLayerToItem: TObjectDictionary<TObject, TTreeViewItem>;

    FPopupResizing: Boolean;
    FPopupResizeStartAbs: TPointF;
    FPopupResizeStartSize: TPointF;
   // popup открыт и еще не вернулся во фрейм (OnClosePopup не пришел)
    FPopupShown: Boolean;
    FPopupClosedTick: UInt64;
   // Android: действия в списке - по двойному нажатию (одиночное бывает
   // концом прокрутки); пункт и время первого нажатия, точка нажатия
    FTapItem: TTreeViewItem;
    FTapTick: UInt64;
    FDownPos: TPointF;
    FDownValid: Boolean;
   // Android: окно списка ставится FMX со сдвигом по Y; поправка измеряется
   // после открытия (CorrectPopupY) и применяется при следующих открытиях
    FPopupYCorr: Single;
   // высота списка, заданная пользователем (Layers_PopupH); фактическая - не
   // ниже нижнего края главного окна минус 10 (ListHeight)
    FListWantH: Single;
    FListSizing: Boolean; // размер списка ставит программа (не пользователь)
    FResizeLeft: Single;  // Android: левый край списка на время перетаскивания SizeGrip1 (как окно на Windows)
   // Android: список - панелью поверх формы точно под btnDrop (TPopup открывается
   // отдельным окном, и FMX ставит его со сдвигом по Y): подложка на всю форму
   // (касание мимо списка закрывает его) и панель, на нее переносится PopupLay
    FListBack: TRectangle;
    FListPanel: TRectangle;
    procedure OpenList;
    procedure CloseList;
    procedure TraceList(const Step: String);
    function ListOpen: Boolean;
    procedure PlaceListPanel;
    function ListHeight: Single;
    procedure ListBackMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PopupLayersClosePopup(Sender: TObject);
    procedure PopupLayersPopup(Sender: TObject);
   // размер открытого списка изменил пользователь (Windows: SizeGrip1 меняет
   // окно TPopup средствами системы) - запомнить
    procedure PopupLayersResize(Sender: TObject);
    procedure CorrectPopupY;
    procedure TreeLayersMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);

    function ChkLayerCtrl: TCheckBox;
    function RectColorCtrl: TRectangle;
    function LayerNameCtrl: TLabel;

    procedure EnsureHeaderControls;
    procedure HeaderLayResize(Sender: TObject);
    procedure EnsurePopupResizeGrip;
    procedure LoadPopupSize;
    procedure SavePopupSize;
    procedure AlignPopupToDropButton;

    procedure NotifyLayerVisibilityChanged;

    procedure SetLayerCheckRecursive(Layer: TResource; ACheck: Byte);

    procedure PopupGripMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PopupGripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PopupGripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);

    procedure SetLayerTable(const Value: TLayerTable);
    function GetActiveLayer: TResource;
    procedure SetActiveLayer(const Value: TResource);
    procedure RebuildTree;
    procedure SyncTree;
    function EnsureItemForLayer(Layer: TResource): TTreeViewItem;
    procedure SyncHeader;
    procedure UpdateTreeChecksFromModel;
    procedure ApplyCheckAll(ACheck: Boolean);
    procedure ApplyInvert;
    function GetLayerText(Layer: TResource): string;
    function GetLayerFillColor(Layer: TResource): TAlphaColor;
    function GetLayerStrokeColor(Layer: TResource): TAlphaColor;

   // строка дерева рисуется самим пунктом (ItemPaint: флажок, цвет и имя слоя
   // по его текущему состоянию); флажок - по координате нажатия (X 2..22)
    procedure ItemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
   // строка слоя - одинаково в списке и в заголовке: флажок (картинка
   // ImageList1 LayerChkImageOff/On или рисованный) с X0+2, квадрат цвета с
   // X0+24, имя с X0+38 до Right (длинное - с многоточием); по высоте - по
   // середине полосы Top..Top+H
    procedure DrawLayerRow(Canvas: TCanvas; L: TResource; X0, Right, Top, H: Single; IsOn: Boolean);
   // заголовок рисуется как строка списка (активный слой); chkLayer невидим, но
   // принимает нажатия, квадрат и метка заголовка скрыты
    procedure HeaderBgPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
   // левый край строки: правее кнопки раскрытия группы (стиль пункта, 'button') -
   // иначе флажок группы под ней, и нажатие раскрывало/сворачивало группу
    function ItemContentLeft(Item: TTreeViewItem): Single;
    procedure ToggleLayerCheck(Layer: TResource);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshUI;
    procedure ActivateLayer(Layer: TResource; Symbol: Integer);
  public
   // слой выбран в списке слоев (щелчком по слою или кнопкой OK, в т.ч. группа):
   // форма переносит в него выделенные объекты; при активации программно не вызывается
    OnLayerSelected: TNotifyEvent;
   // сменился активный слой (любым способом, в т.ч. программно): быстрые слои
    OnActiveLayerChanged: TNotifyEvent;
    procedure SelectLayer(Layer: TResource);
    function IsGroupLayer(Layer: TResource): Boolean;
    property LayerTable: TLayerTable read FLayerTable write SetLayerTable;
    procedure SetActiveLayerByName(LayerName: String);
    property ActiveLayer: TResource read GetActiveLayer write SetActiveLayer;
  end;

const
 // флажок видимости в строке дерева - картинки ImageList1 (выключен / включен);
 // картинки нет - флажок рисуется (ItemPaint)
  LayerChkImageOff = 4;
  LayerChkImageOn = 5;

var LayerFrame: TLayerFrame;
// ОПЫТ: True - при открытии списка активный слой в нем не выделяется
    SkipSelectOnOpen: Boolean = False;

implementation

uses Writer, AppUI, System.Math;

// размер шрифта списка слоев и заголовка (имя активного слоя) - UI.Metrics.ListFontSize;
// высота строки - по шрифту, не меньше 24 (флажок 20 + отступы)
function LayerRowHeight: Single;
begin
 Result := Round(UI.Metrics.ListFontSize * 1.7);
 if Result < 24 then Result := 24;
end;

// шрифт метки имени слоя - не из стиля
procedure SetLayerLabelFont(Nm: TLabel);
begin
 Nm.StyledSettings := Nm.StyledSettings - [TStyledSetting.Size];
 Nm.TextSettings.Font.Size := UI.Metrics.ListFontSize;
end;

{$R *.fmx}

procedure TLayerFrame.EnsurePopupResizeGrip;
var
 Grip: TSizeGrip;
 C: TComponent;
begin
 SizeGrip1.OnMouseUp := PopupGripMouseUp;
 exit;
 if PopupLay = nil then Exit;
 C := FindComponent('PopupSizeGrip');
 if (C <> nil) and (C is TSizeGrip) then Exit;
 Grip := TSizeGrip.Create(Self);
 Grip.Size.Height := 3; Grip.Size.Width := 3;
 Grip.Name := 'PopupSizeGrip';
 Grip.Stored := False;
 Grip.Parent := PopupLayers;
 Grip.Align := TAlignLayout.Bottom;
// Grip.Position.X := PopupLayers.Width - Grip.Width - 2;
// Grip.Position.Y := PopupLayers.Height - Grip.Height - 2;
 Grip.Anchors := [TAnchorKind.akRight, TAnchorKind.akBottom];
 Grip.OnMouseDown := PopupGripMouseDown;
 Grip.OnMouseMove := PopupGripMouseMove;
 Grip.OnMouseUp := PopupGripMouseUp;
end;

procedure TLayerFrame.LoadPopupSize;
var
 W, H: Single;
begin
 if PopupLayers = nil then Exit;
 W := GReadFloat('Layers_PopupW', PopupLayers.Width);
 H := GReadFloat('Layers_PopupH', PopupLayers.Height);
 if W < 200 then W := 200;
 if H < 160 then H := 160;
 PopupLayers.Width := W;
 PopupLayers.Height := H;
 FListWantH := H;
end;

procedure TLayerFrame.SavePopupSize;
begin
 if PopupLayers = nil then Exit;
 GWriteFloat('Layers_PopupW', PopupLayers.Width);
 GWriteFloat('Layers_PopupH', FListWantH);
end;

procedure TLayerFrame.PopupGripMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 AbsP: TPointF;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if PopupLayers = nil then Exit;
 if not (Sender is TControl) then Exit;
 FPopupResizing := True;
 AbsP := TControl(Sender).LocalToAbsolute(TPointF.Create(X, Y));
 FPopupResizeStartAbs := AbsP;
 FPopupResizeStartSize := TPointF.Create(PopupLayers.Width, ListHeight);
{$IFDEF ANDROID}
 if FListPanel <> nil then FResizeLeft := FListPanel.Position.X;
{$ENDIF}
end;

procedure TLayerFrame.PopupGripMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
 AbsP: TPointF;
 Dx, Dy: Single;
 NewW, NewH: Single;
begin
 if not FPopupResizing then Exit;
 if PopupLayers = nil then Exit;
 if not (Sender is TControl) then Exit;
 AbsP := TControl(Sender).LocalToAbsolute(TPointF.Create(X, Y));
 Dx := AbsP.X - FPopupResizeStartAbs.X;
 Dy := AbsP.Y - FPopupResizeStartAbs.Y;

 NewW := FPopupResizeStartSize.X + Dx;
 NewH := FPopupResizeStartSize.Y + Dy;
 if NewW < 200 then NewW := 200;
 if NewH < 160 then NewH := 160;
 PopupLayers.Width := NewW;
 PopupLayers.Height := NewH;
 FListWantH := NewH;

 if ListOpen then
  AlignPopupToDropButton;
end;

procedure TLayerFrame.PopupGripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FPopupResizing then Exit;
 FPopupResizing := False;
 SavePopupSize;
end;

function TLayerFrame.ListOpen: Boolean;
begin
{$IFDEF ANDROID}
 Result := FListBack <> nil;
{$ELSE}
 Result := (PopupLayers <> nil) and PopupLayers.IsOpen;
{$ENDIF}
end;

procedure TLayerFrame.OpenList;
begin
{$IFDEF ANDROID}
 if (FListBack <> nil) or not (Root.GetObject is TCommonCustomForm) then Exit;
 FListBack := TRectangle.Create(nil);
 FListBack.Fill.Kind := TBrushKind.None;
 FListBack.Stroke.Kind := TBrushKind.None;
 FListBack.HitTest := True;
 FListBack.OnMouseDown := ListBackMouseDown;
 FListBack.Align := TAlignLayout.Contents;
 FListBack.Parent := TCommonCustomForm(Root.GetObject);
 FListBack.BringToFront;
 FListPanel := TRectangle.Create(FListBack);
 FListPanel.Fill.Color := TAlphaColors.White;
 FListPanel.Stroke.Color := $FF808080;
 FListPanel.HitTest := True;
 FListPanel.ClipChildren := True;
 FListPanel.Parent := FListBack;
 PlaceListPanel;
 PopupLay.Parent := FListPanel;
{$ELSE}
 PopupLayers.IsOpen := True;
{$ENDIF}
end;

// список возвращается в PopupLayers, подложка освобождается позже (закрытие
// бывает из ее же обработчика нажатия)
procedure TLayerFrame.CloseList;
{$IFDEF ANDROID}
var B: TRectangle;
{$ENDIF}
begin
{$IFDEF ANDROID}
 if FListBack = nil then Exit;
 PopupLay.Parent := PopupLayers;
 B := FListBack;
 FListBack := nil;
 FListPanel := nil;
 B.Parent := nil;
 TThread.ForceQueue(nil, procedure begin B.Free; end);
 PopupLayersClosePopup(Self);
{$ELSE}
 if PopupLayers <> nil then PopupLayers.IsOpen := False;
{$ENDIF}
end;

// высота списка: заданная пользователем, но если нижний край списка доходит до
// низа главного окна - на 10 выше низа окна (не меньше 100)
function TLayerFrame.ListHeight: Single;
var F: TCommonCustomForm;
    Y: Single;
begin
 Result := FListWantH;
 if Result <= 0 then Result := PopupLayers.Height;
 if (btnDrop = nil) or not (Root.GetObject is TCommonCustomForm) then Exit;
 F := TCommonCustomForm(Root.GetObject);
 Y := btnDrop.LocalToAbsolute(TPointF.Create(0, btnDrop.Height)).Y;
 if Y + Result >= F.ClientHeight then Result := Max(100, F.ClientHeight - 10 - Y);
end;

// Android: правый край списка - по правому краю btnDrop, верх - по ее низу
// (координаты формы); ширина - заданная, высота - ListHeight. При изменении
// размера (SizeGrip1) правый край на месте - список растет влево и вниз
procedure TLayerFrame.PlaceListPanel;
var F: TCommonCustomForm;
    P: TPointF;
    X, Y, W, H: Single;
begin
 if (FListPanel = nil) or not (Root.GetObject is TCommonCustomForm) then Exit;
 F := TCommonCustomForm(Root.GetObject);
 W := PopupLayers.Width;
 H := ListHeight;
 P := btnDrop.LocalToAbsolute(TPointF.Create(btnDrop.Width, btnDrop.Height));
 X := P.X - W;
// перетаскивание SizeGrip1 - как окно списка на Windows: левый край на месте,
// правый и нижний - за пальцем; при следующем открытии - снова по btnDrop
 if FPopupResizing then X := FResizeLeft;
 Y := P.Y;
 FListPanel.SetBounds(X, Y, W, H);
end;

// касание мимо списка (по подложке) - закрыть
procedure TLayerFrame.ListBackMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 CloseList;
end;

procedure TLayerFrame.AlignPopupToDropButton;
begin
 if PopupLayers = nil then Exit;
 if btnDrop = nil then Exit;
{$IFDEF ANDROID}
 if FListPanel <> nil then begin
  PlaceListPanel;
  Exit;
 end;
{$ENDIF}
// своя установка высоты - не размер пользователя (PopupLayersResize)
 FListSizing := True;
 try
  PopupLayers.Height := ListHeight;
 finally
  FListSizing := False;
 end;
 PopupLayers.PlacementTarget := btnDrop;
 PopupLayers.Placement := TPlacement.Bottom;
 PopupLayers.VerticalOffset := {$IFDEF ANDROID}FPopupYCorr{$ELSE}0{$ENDIF};
 PopupLayers.HorizontalOffset := btnDrop.Width - PopupLayers.Width;
end;

procedure TLayerFrame.PopupLayersPopup(Sender: TObject);
begin
{$IFDEF ANDROID}
// окно уже размещено, но еще может выравниваться - замер после обработки события
 TThread.ForceQueue(nil, procedure begin CorrectPopupY; end);
{$ENDIF}
end;

// список - точно под HeaderBg: верх списка и низ заголовка в экранных
// координатах (у каждой формы - фактическое положение ее вида на экране);
// разница - сдвиг окна списка (PopupLayers лежит прямо на нем) и поправка
// для следующих открытий
procedure TLayerFrame.CorrectPopupY;
var F: TCustomPopupForm;
    D: Single;
begin
 if not FPopupShown or not (PopupLayers.Parent is TCustomPopupForm) then Exit;
 D := HeaderBg.LocalToScreen(TPointF.Create(0, HeaderBg.Height)).Y - PopupLayers.LocalToScreen(TPointF.Zero).Y;
 if Abs(D) < 1 then Exit;
 FPopupYCorr := FPopupYCorr + D;
 F := TCustomPopupForm(PopupLayers.Parent);
 F.Offset := TPointF.Create(F.Offset.X, F.Offset.Y + D);
end;

{ TLayerFrame }

constructor TLayerFrame.Create(AOwner: TComponent);
begin
 inherited;
 Opaque := False; // в тулбаре: фон - тулбара
 FLayerToItem := TObjectDictionary<TObject, TTreeViewItem>.Create([]);
 EnsureHeaderControls;
 EnsurePopupResizeGrip;
 LoadPopupSize;
 if PopupLayers <> nil then PopupLayers.OnClosePopup := PopupLayersClosePopup;
 if PopupLayers <> nil then PopupLayers.OnPopup := PopupLayersPopup;
 if PopupLayers <> nil then PopupLayers.OnResize := PopupLayersResize;
 TreeLayers.OnMouseDown := TreeLayersMouseDown;
{$IFDEF ANDROID}
// TSizeGrip меняет размер окна-формы, в которой лежит; список на Android -
// панель внутри главной формы (окна там не меняют размер) - размер панели
// меняют обработчики перетаскивания фрейма
 if SizeGrip1 <> nil then begin
 // все движения пальца - захвату до отпускания (иначе - только пока палец над
 // маленьким SizeGrip1)
  SizeGrip1.AutoCapture := True;
  SizeGrip1.OnMouseDown := PopupGripMouseDown;
  SizeGrip1.OnMouseMove := PopupGripMouseMove;
  SizeGrip1.OnMouseUp := PopupGripMouseUp;
 end;
{$ENDIF}
end;

// popup закрыт полностью: содержимое вернулось во фрейм
procedure TLayerFrame.PopupLayersClosePopup(Sender: TObject);
begin
 FPopupShown := False;
 FPopupClosedTick := TThread.GetTickCount64;
// размер, заданный пользователем, - в настройки (при следующем открытии он же)
 SavePopupSize;
end;

procedure TLayerFrame.PopupLayersResize(Sender: TObject);
begin
 if FListSizing or not ListOpen then Exit;
 FListWantH := PopupLayers.Height;
end;

destructor TLayerFrame.Destroy;
begin
{$IFDEF ANDROID}
 if FListBack <> nil then begin
  PopupLay.Parent := PopupLayers;
  FreeAndNil(FListBack);
 end;
{$ENDIF}
 FreeAndNil(FLayerToItem);
 inherited;
end;

procedure TLayerFrame.SetLayerTable(const Value: TLayerTable);
begin
// дерево перестраивается всегда: при открытии карты старая форма освобождается,
// и новая таблица слоев может оказаться по тому же адресу - тогда пункты
// дерева ссылались бы на слои освобожденной таблицы
 FLayerTable := Value;
 RebuildTree;
 SyncHeader;
end;

function TLayerFrame.GetActiveLayer: TResource;
begin
 Result := nil;
 if FLayerTable <> nil then
  Result := FLayerTable.ActiveLayer;
end;

procedure TLayerFrame.SetActiveLayer(const Value: TResource);
begin
 if (FLayerTable = nil) or (Value = nil) then Exit;
 if FLayerTable.ActiveLayer = Value then Exit;
 FLayerTable.ActiveLayer := Value;
 SyncHeader;
 HeaderBg.Hint := Value.RecString;
 if Assigned(OnActiveLayerChanged) then OnActiveLayerChanged(Self);
end;

// активный слой по сообщению UpdateMessage.SetActiveLayer (например, выбран
// объект в TEditMap); бывший TFlyLayer.SetActiveLayer старой программы
procedure TLayerFrame.ActivateLayer(Layer: TResource; Symbol: Integer);
var Item: TTreeViewItem;
begin
 if (FLayerTable = nil) or (Layer = nil) then Exit;
// TLayerTable.SetActiveLayer вызывает исключение для слоя не из таблицы
 if FLayerTable.LinearLayers.IndexOf(Layer) = -1 then Exit;
 SetActiveLayer(Layer);
// открытый список слоев - выделить слой и в нем
 if (PopupLayers <> nil) and ListOpen and FLayerToItem.TryGetValue(Layer, Item) then begin
  FUpdating := True;
  try
   TreeLayers.Selected := Item;
  finally
   FUpdating := False;
  end;
 end;
end;

// слой по имени (имя слоя знака из описания групп): без учета регистра и
// пробелов по краям (в описаниях групп бывают хвостовые пробелы)
procedure TLayerFrame.SetActiveLayerByName(LayerName: String);
var I: Integer;
    L: TResource;
    N: String;
begin
 if FLayerTable = nil then Exit;
 N := AnsiUpperCase(Trim(LayerName));
 if N = '' then Exit;
 for I := 0 to FLayerTable.LinearLayers.Count - 1 do begin
  L := FLayerTable.LinearLayer[I];
  if (L <> nil) and (AnsiUpperCase(Trim(String(L.RecString))) = N) then begin
   SetActiveLayer(L);
   Exit;
  end;
 end;
 WriteIn(['SetActiveLayerByName: не найден слой "', LayerName, '"']);
end;

procedure TLayerFrame.RefreshUI;
begin
 RebuildTree;
 SyncHeader;
end;

function TLayerFrame.GetLayerText(Layer: TResource): string;
begin
 Result := '';
 if Layer = nil then Exit;
 try
  Result := string(Layer.RecString);
 except
  Result := '';
 end;
end;

function TLayerFrame.GetLayerFillColor(Layer: TResource): TAlphaColor;
begin
 Result := $FF00AAFF;
 if Layer = nil then Exit;
 try
  Result := TAlphaColor($FF000000 or Cardinal(Layer.GetColor));
 except
 end;
end;

function TLayerFrame.GetLayerStrokeColor(Layer: TResource): TAlphaColor;
begin
 Result := $FF202020;
 if Layer = nil then Exit;
 try
  Result := TAlphaColor(ColorRefToAlpha(Layer.LineColor));
 except
 end;
end;

function TLayerFrame.ChkLayerCtrl: TCheckBox;
var
 C: TComponent;
begin
 Result := nil;
 C := FindComponent('chkLayer');
 if (C <> nil) and (C is TCheckBox) then
  Result := TCheckBox(C);
end;

function TLayerFrame.RectColorCtrl: TRectangle;
var
 C: TComponent;
begin
 Result := nil;
 C := FindComponent('rectColor');
 if (C <> nil) and (C is TRectangle) then
  Result := TRectangle(C);
end;

function TLayerFrame.LayerNameCtrl: TLabel;
var
 C: TComponent;
begin
 Result := nil;
 C := FindComponent('lblLayerName');
 if (C <> nil) and (C is TLabel) then
  Result := TLabel(C);
end;

procedure TLayerFrame.EnsureHeaderControls;
var
 Chk: TCheckBox;
 Col: TRectangle;
 Nm: TLabel;
 H: Single;
begin
 if HeaderBg = nil then Exit;
 H := LayerRowHeight + 4;
 HeaderLay.Height := H;

 Chk := ChkLayerCtrl;
 if Chk = nil then
 begin
  Chk := TCheckBox.Create(Self);
  Chk.Name := 'chkLayer';
  Chk.Stored := False;
  Chk.Position.X := 2;
  Chk.Position.Y := (H - 20) / 2;
  Chk.Width := 20;
  Chk.Height := 20;
  Chk.OnChange := chkLayerChange;
  Chk.Parent := HeaderBg;
 end;

 Col := RectColorCtrl;
 if Col = nil then
 begin
  Col := TRectangle.Create(Self);
  Col.Name := 'rectColor';
  Col.Stored := False;
  Col.Position.X := 23;
  Col.Position.Y := (H - 10) / 2 - 1;
  Col.Size.Width := 10;
  Col.Size.Height := 10;
  Col.HitTest := False;
  Col.Parent := HeaderBg;
 end;

 Nm := LayerNameCtrl;
 if Nm = nil then
 begin
  Nm := TLabel.Create(Self);
  Nm.Name := 'lblLayerName';
  Nm.Stored := False;
  Nm.Position.X := 38;
  Nm.Position.Y := 0;
  Nm.Height := H - 4;
  SetLayerLabelFont(Nm);
//  Nm.StyledSettings := Nm.StyledSettings - [TStyledSetting.WordWrap];
  Nm.TextSettings.WordWrap := False;
  Nm.HitTest := False;
  Nm.TextSettings.Trimming := TTextTrimming.Character;
  Nm.Parent := HeaderBg;
 end;
// заголовок рисуется как строка списка (HeaderBgPaint): флажок невидим, но
// принимает нажатия; квадрат и метка не показываются
 Chk.Opacity := 0;
 Col.Visible := False;
 Nm.Visible := False;
 HeaderBg.OnPaint := HeaderBgPaint;
 HeaderLay.OnResize := HeaderLayResize;
 HeaderLayResize(HeaderLay);
end;

// имя активного слоя - до кнопки списка (btnDrop) с отступом 5, длинное
// обрезается многоточием
procedure TLayerFrame.HeaderLayResize(Sender: TObject);
var Nm: TLabel;
    W: Single;
begin
 Nm := LayerNameCtrl;
 if Nm = nil then exit;
// btnDrop - Align = Right: его левый край по ширине заголовка (в OnResize
// Position.X кнопки может быть еще прежним)
 W := HeaderLay.Width - btnDrop.Margins.Right - btnDrop.Width - btnDrop.Margins.Left - 5 - Nm.Position.X;
 if W < 0 then W := 0;
 Nm.Width := W;
// невидимый флажок - по середине заголовка по высоте, как нарисованный
 if ChkLayerCtrl <> nil then ChkLayerCtrl.Position.Y := (HeaderBg.Height - ChkLayerCtrl.Height) / 2;
 HeaderBg.Repaint;
end;

procedure TLayerFrame.SyncHeader;
var
 L: TResource;
 Chk: TCheckBox;
 Col: TRectangle;
 Nm: TLabel;
begin
 if FUpdating then Exit;
 FUpdating := True;
 try
  L := ActiveLayer;
  Chk := ChkLayerCtrl;
  Col := RectColorCtrl;
  Nm := LayerNameCtrl;
  if L = nil then
  begin
   if Chk <> nil then Chk.IsChecked := False;
   if Nm <> nil then Nm.Text := '';
   if Col <> nil then
   begin
    Col.Fill.Color := $00000000;
    Col.Stroke.Color := $FFB0B0B0;
   end;
   Exit;
  end;

  if Chk <> nil then Chk.IsChecked := (L.Check <> 0);
  if Nm <> nil then Nm.Text := GetLayerText(L);
  if Col <> nil then
  begin
   Col.Fill.Color := GetLayerFillColor(L);
   Col.Stroke.Color := GetLayerStrokeColor(L);
  end;
 finally
  FUpdating := False;
  HeaderBg.Repaint;
 end;
end;

procedure TLayerFrame.RebuildTree;
var
 I: Integer;
 L: TResource;
 Item: TTreeViewItem;
begin
 TraceList('RebuildTree start (FUpdating=' + BoolToStr(FUpdating, True) + ')');
 if FUpdating then Exit;
 FUpdating := True;
 try
// не TreeLayers.Clear: он обходит Content.Controls по индексу, запомненному до
// освобождения пунктов, и на заполненном дереве выходил за границу ("List index
// out of bounds"); здесь последний пункт верхнего уровня берется заново после
// каждого освобождения
  TreeLayers.BeginUpdate;
  try
   TreeLayers.Selected := nil;
   while TreeLayers.Count > 0 do begin
   // ОТЛАДКА: Items[] - это Content.Controls[] (TList<TControl>)
    if TreeLayers.Count - 1 >= TreeLayers.Content.ControlsCount then
     WriteIn(['LayerList RebuildTree free: index ', TreeLayers.Count - 1, ' >= content ', TreeLayers.Content.ControlsCount]);
    TreeLayers.Items[TreeLayers.Count - 1].Free;
   end;
  finally
   TreeLayers.EndUpdate;
  end;
  FLayerToItem.Clear;
  FTapItem := nil;
  if FLayerTable = nil then Exit;

  for I := 0 to FLayerTable.L2Count - 1 do
  begin
   if I >= FLayerTable.L2Count then begin
    WriteIn(['LayerList RebuildTree layers: index ', I, ' >= L2Count ', FLayerTable.L2Count]);
    Break;
   end;
   L := FLayerTable.LinearLayer[I];
   if L = nil then Continue;
   EnsureItemForLayer(L);
  end;

  UpdateTreeChecksFromModel;

  Item := nil;
  L := ActiveLayer;
  if (L <> nil) and FLayerToItem.TryGetValue(L, Item) then
  begin
   TreeLayers.Selected := Item;
   Item.Expand;
  end;
 finally
  FUpdating := False;
 end;
 TraceList('RebuildTree end');
end;

// дерево по модели без перестройки: видимость, цвета и имена слоев, выделен
// активный слой
procedure TLayerFrame.SyncTree;
var Item: TTreeViewItem;
begin
 UpdateTreeChecksFromModel;
 TraceList('SyncTree: checks done');
// ОПЫТ: без программного выделения при открытии (поиск «List index out of
// bounds»: выделение раскрывает группы и прокручивает дерево). Если ошибка
// пропала - причина в выделении; затем убрать
 if SkipSelectOnOpen then begin
  TraceList('SyncTree: select skipped');
  Exit;
 end;
 if FUpdating then Exit;
 if (ActiveLayer = nil) or not FLayerToItem.TryGetValue(ActiveLayer, Item) then Exit;
 FUpdating := True;
 try
  TreeLayers.Selected := Item;
 finally
  FUpdating := False;
 end;
 TraceList('SyncTree: selected ' + IntToStr(Item.GlobalIndex));
end;

function TLayerFrame.EnsureItemForLayer(Layer: TResource): TTreeViewItem;
var
 ParentLayer: TResource;
 ParentItem: TTreeViewItem;
 Item: TTreeViewItem;
 H: Single;
begin
 if Layer = nil then Exit(nil);
 if FLayerToItem.TryGetValue(Layer, Result) then Exit;

 ParentItem := nil;
 ParentLayer := Layer.Parent;
 if ParentLayer <> nil then
  ParentItem := EnsureItemForLayer(ParentLayer);

 Item := TTreeViewItem.Create(TreeLayers);
 Item.Stored := False;
 Item.TagObject := Layer;
 Item.Text := '';
 H := LayerRowHeight;
 Item.Height := H;

// флажок, цвет и имя слоя рисует сам пункт (OnPaint): дочерних элементов у
// пункта нет - FMX TTreeView обращался к дочерним элементам пункта по индексу
// на единицу больше их числа («List index out of bounds» после прокрутки и
// выбора слоя: 4 при 0..3 с флажком, квадратом и меткой, 2 при 0..1 с одним)
 Item.OnPaint := ItemPaint;

 if ParentItem <> nil then
  Item.Parent := ParentItem
 else
  Item.Parent := TreeLayers;

 FLayerToItem.Add(Layer, Item);
 Result := Item;
end;

// строки рисуются по состоянию слоев - достаточно перерисовать
procedure TLayerFrame.UpdateTreeChecksFromModel;
var Pair: TPair<TObject, TTreeViewItem>;
begin
 for Pair in FLayerToItem do Pair.Value.Repaint;
end;

procedure TLayerFrame.ApplyCheckAll(ACheck: Boolean);
begin
 if FLayerTable = nil then Exit;
 FLayerTable.CheckAllLayers(ACheck);
 UpdateTreeChecksFromModel;
 SyncHeader;
end;

procedure TLayerFrame.ApplyInvert;
var
 I: Integer;
 L: TResource;
begin
 if FLayerTable = nil then Exit;
 for I := 0 to FLayerTable.L2Count - 1 do
 begin
  L := FLayerTable.LinearLayer[I];
  if L = nil then Continue;
  if L.Check = 0 then L.Check := 1 else L.Check := 0;
 end;
 UpdateTreeChecksFromModel;
 SyncHeader;
end;

// отладка «List index out of bounds» при открытии списка: шаг и состояние дерева
procedure TLayerFrame.TraceList(const Step: String);
var Sel: String;
begin
 if TreeLayers.Selected <> nil then Sel := IntToStr(TreeLayers.Selected.GlobalIndex) else Sel := '-';
 WriteIn(['LayerList ', Step, ': count=', TreeLayers.Count, ' global=', TreeLayers.GlobalCount,
  ' sel=', Sel, ' vpY=', TreeLayers.ViewportPosition.Y, ' content=', TreeLayers.Content.ControlsCount]);
end;

procedure TLayerFrame.btnDropClick(Sender: TObject);
begin
 if PopupLayers = nil then Exit;
// TPopup сначала сбрасывает IsOpen (BeforeClose), а возвращает содержимое во
// фрейм позже (ClosePopup, после анимации). Пока закрытие не завершено,
// дерево не перестраивается и popup повторно не открывается
 if FPopupShown then
 begin
  CloseList;
  Exit;
 end;
// щелчок по кнопке при открытом списке сам закрыл его (потеря фокуса) - не открываем снова
 if TThread.GetTickCount64 - FPopupClosedTick < 300 then Exit;
// состав дерева меняется только при смене таблицы слоев (SetLayerTable);
// перед открытием - только флажки, цвета, имена и выделение активного слоя
 TraceList('open start');
 try
  SyncTree;
 except
  on E: Exception do begin
   TraceList('SyncTree error ' + E.Message);
   raise;
  end;
 end;
 TraceList('after SyncTree');
 AlignPopupToDropButton;
 FPopupShown := True;
 try
  OpenList;
 except
  on E: Exception do begin
   TraceList('OpenList error ' + E.Message);
   FPopupShown := False;
   raise;
  end;
 end;
 TraceList('after OpenList');
// ошибка после выхода (выравнивание и отрисовка открытого списка)
 TThread.ForceQueue(nil, procedure begin TraceList('queued after open'); end);
end;

procedure TLayerFrame.chkLayerChange(Sender: TObject);
var
 L: TResource;
 Chk: TCheckBox;
begin
 HeaderBg.Repaint;
 if FUpdating then Exit;
 L := ActiveLayer;
 if L = nil then Exit;
 Chk := ChkLayerCtrl;
 if Chk = nil then Exit;
 if Chk.IsChecked then
  SetLayerCheckRecursive(L, 1)
 else
  SetLayerCheckRecursive(L, 0);

 UpdateTreeChecksFromModel;
 SyncHeader;
 NotifyLayerVisibilityChanged;
end;

// группа слоев: в списке у ее пункта есть вложенные слои
function TLayerFrame.IsGroupLayer(Layer: TResource): Boolean;
var Item: TTreeViewItem;
begin
 Result := (Layer <> nil) and FLayerToItem.TryGetValue(Layer, Item) and (Item.Count > 0);
end;

// слой выбран: становится активным, выделенные объекты переносятся в него
// (форма - OnLayerSelected), список закрывается. Вызывается щелчком по слою
// (не группе) и кнопкой OK (и для группы). Слой не из текущей таблицы (дерево
// устарело) - дерево перестраивается
procedure TLayerFrame.SelectLayer(Layer: TResource);
begin
 if (FLayerTable = nil) or (Layer = nil) then Exit;
 if FLayerTable.LinearLayers.IndexOf(Layer) = -1 then begin
  RebuildTree;
  Exit;
 end;
 SetActiveLayer(Layer);
 if Assigned(OnLayerSelected) then OnLayerSelected(Self);
 if (PopupLayers <> nil) and FPopupShown then
  TThread.ForceQueue(nil, procedure begin CloseList; end);
end;

procedure TLayerFrame.TreeLayersMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 FDownPos := TPointF.Create(X, Y);
 FDownValid := True;
end;

// смена выделения в дереве (в т.ч. клавишами) слой не выбирает - выбор
// щелчком (TreeLayersMouseUp) или кнопкой OK. На Android - по двойному
// нажатию: первое только выделяет пункт (группа не раскрывается), отпускание
// после сдвига пальца (прокрутка) нажатием не считается; второе нажатие на тот
// же пункт - флажок видимости, раскрытие/свертывание группы или выбор слоя
procedure TLayerFrame.TreeLayersMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 Item: TTreeViewItem;
 L: TResource;
 PAbs: TPointF;
 PItem: TPointF;
{$IFDEF ANDROID}
 Moved: Boolean;
{$ENDIF}
begin
{$IFDEF ANDROID}
 Moved := FDownValid and ((Abs(X - FDownPos.X) > 10) or (Abs(Y - FDownPos.Y) > 10));
{$ENDIF}
 FDownValid := False;
 if FUpdating then Exit;
 Item := TreeLayers.ItemByPoint(X, Y) as TTreeViewItem;
 if Item = nil then Exit;
 L := TResource(Item.TagObject);
 if L = nil then Exit;
// флажок видимости - X=2..22 (EnsureItemForLayer): щелчок по нему слой не выбирает
 PAbs := TreeLayers.LocalToAbsolute(TPointF.Create(X, Y));
 PItem := Item.AbsoluteToLocal(PAbs);
{$IFDEF ANDROID}
 if Moved then begin
  FTapItem := nil;
  Exit;
 end;
 if (FTapItem <> Item) or (TThread.GetTickCount64 - FTapTick > 500) then begin
  FTapItem := Item;
  FTapTick := TThread.GetTickCount64;
  TreeLayers.Selected := Item;
  Exit;
 end;
 FTapItem := nil;
{$ENDIF}
// флажок видимости (зона X 2..22 правее кнопки раскрытия) - переключить слой
// (у группы - и вложенные), слой не выбирается
 if (PItem.X >= ItemContentLeft(Item) + 2) and (PItem.X <= ItemContentLeft(Item) + 22) then begin
  TThread.ForceQueue(nil, procedure begin ToggleLayerCheck(L); end);
  Exit;
 end;
 TreeLayers.Selected := Item;
// действия - после выхода из обработки нажатия деревом: выбор слоя (через
// OnActiveLayerChanged / OnLayerSelected формы) и раскрытие группы меняют
// элементы, а FMX после обработчика еще перебирает элементы прокрученного
// дерева - «List index out of bounds» при выборе слоя после прокрутки списка.
// Пункт - заново по слою: к моменту вызова дерево могло перестроиться
 TThread.ForceQueue(nil,
  procedure
  var It: TTreeViewItem;
  begin
  // группа слоев - только раскрыть/свернуть (выбрать группу - кнопкой OK)
   if IsGroupLayer(L) then begin
    if FLayerToItem.TryGetValue(L, It) then
     if It.IsExpanded then It.Collapse else It.Expand;
    Exit;
   end;
   SelectLayer(L);
  end);
end;

procedure TLayerFrame.btnAllOnClick(Sender: TObject);
begin
 ApplyCheckAll(True);
end;

procedure TLayerFrame.btnAllOffClick(Sender: TObject);
begin
 ApplyCheckAll(False);
end;

procedure TLayerFrame.btnInvertClick(Sender: TObject);
begin
 ApplyInvert;
end;

// кнопки лежат внутри popup: закрытие (перенос содержимого обратно во фрейм)
// выполняется после выхода из обработчика кнопки
procedure TLayerFrame.btnOkClick(Sender: TObject);
var L: TResource;
begin
// выбранный в списке слой или группа слоев - активный и выделенным объектам
 L := nil;
 if TreeLayers.Selected <> nil then L := TResource(TreeLayers.Selected.TagObject);
 if L <> nil then SelectLayer(L);
 TThread.ForceQueue(nil, procedure begin CloseList; end);
end;

procedure TLayerFrame.btnCancelClick(Sender: TObject);
begin
 TThread.ForceQueue(nil, procedure begin CloseList; end);
end;

// флажок видимости (картинка ImageList1 или рисованный), квадрат цвета слоя,
// имя слоя - по текущему состоянию слоя (TagObject строки)
function TLayerFrame.ItemContentLeft(Item: TTreeViewItem): Single;
var B: TFmxObject;
begin
 Result := 0;
 if Item = nil then Exit;
 B := Item.FindStyleResource('button');
 if B is TControl then Result := TControl(B).Position.X + TControl(B).Width;
end;

// картинка флажка - в масштабе, вписывающем ее в R, и со сдвигом: середина ее
// непрозрачной части (сам квадратик, прозрачные поля картинки бывают разными)
// совпадает с серединой R - то есть с серединой строки по Y
function CenteredImageRect(B: TBitmap; const R: TRectF): TRectF;
var D: TBitmapData;
    X, Y, L, T, Rt, Bt: Integer;
    K, CX, CY: Single;
begin
 K := Min(R.Width / B.Width, R.Height / B.Height);
 CX := B.Width / 2;
 CY := B.Height / 2;
 if B.Map(TMapAccess.Read, D) then
  try
   L := B.Width;
   T := B.Height;
   Rt := -1;
   Bt := -1;
   for Y := 0 to B.Height - 1 do
    for X := 0 to B.Width - 1 do
     if TAlphaColorRec(D.GetPixel(X, Y)).A > 16 then begin
      if X < L then L := X;
      if X > Rt then Rt := X;
      if Y < T then T := Y;
      if Y > Bt then Bt := Y;
     end;
   if Rt >= L then begin
    CX := (L + Rt + 1) / 2;
    CY := (T + Bt + 1) / 2;
   end;
  finally
   B.Unmap(D);
  end;
 Result := TRectF.Create(0, 0, B.Width * K, B.Height * K);
 Result.Offset(R.CenterPoint.X - CX * K, R.CenterPoint.Y - CY * K);
end;

procedure TLayerFrame.DrawLayerRow(Canvas: TCanvas; L: TResource; X0, Right, Top, H: Single; IsOn: Boolean);
var S: Single;
    R: TRectF;
    B: TBitmap;
    Idx: Integer;
    TL: TTextLayout;
    Sz: TSizeF;
begin
// флажок
 S := 20;
 R := TRectF.Create(X0 + 2, Top + (H - S) / 2, X0 + 2 + S, Top + (H + S) / 2);
 if IsOn then Idx := LayerChkImageOn else Idx := LayerChkImageOff;
 B := nil;
// картинка - в ее размере, ближайшем к нужному (BestSize): картинку другого
// размера TImageList не растягивает, а кладет в угол - флажок был выше середины;
// затем вписывается в квадрат флажка с сохранением пропорций, по центру
 if (ImageList1 <> nil) and (Idx < ImageList1.Count) then begin
  Sz := TSizeF.Create(S * Canvas.Scale, S * Canvas.Scale);
  if ImageList1.BestSize(Idx, Sz) then B := ImageList1.Bitmap(Sz, Idx);
 end;
 if B <> nil then
  Canvas.DrawBitmap(B, TRectF.Create(0, 0, B.Width, B.Height), CenteredImageRect(B, R), 1)
 else begin
  R.Inflate(-3, -3);
  Canvas.Fill.Kind := TBrushKind.Solid;
  if IsOn then Canvas.Fill.Color := $FF1E78FF else Canvas.Fill.Color := TAlphaColors.White;
  Canvas.FillRect(R, 2, 2, AllCorners, 1);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := $FF606060;
  Canvas.Stroke.Thickness := 1;
  Canvas.DrawRect(R, 2, 2, AllCorners, 1);
  if IsOn then begin
   Canvas.Stroke.Color := TAlphaColors.White;
   Canvas.Stroke.Thickness := 2;
   Canvas.DrawLine(TPointF.Create(R.Left + 3, R.CenterPoint.Y), TPointF.Create(R.Left + R.Width * 0.42, R.Bottom - 3), 1);
   Canvas.DrawLine(TPointF.Create(R.Left + R.Width * 0.42, R.Bottom - 3), TPointF.Create(R.Right - 3, R.Top + 3), 1);
  end;
 end;
 if L = nil then Exit;
// цвет слоя
 R := TRectF.Create(X0 + 24, Top + (H - 10) / 2, X0 + 34, Top + (H + 10) / 2);
 Canvas.Fill.Kind := TBrushKind.Solid;
 Canvas.Fill.Color := GetLayerFillColor(L);
 Canvas.FillRect(R, 0, 0, [], 1);
 Canvas.Stroke.Kind := TBrushKind.Solid;
 Canvas.Stroke.Color := GetLayerStrokeColor(L);
 Canvas.Stroke.Thickness := 1;
 Canvas.DrawRect(R, 0, 0, [], 1);
// имя слоя: в одну строку, не дальше Right, длинное - с многоточием
 if Right <= X0 + 38 then Exit;
 TL := TTextLayoutManager.DefaultTextLayout.Create;
 try
  TL.BeginUpdate;
  try
   TL.TopLeft := TPointF.Create(X0 + 38, Top);
   TL.MaxSize := TPointF.Create(Right - X0 - 38, H);
   TL.Text := GetLayerText(L);
   TL.Font.Size := UI.Metrics.ListFontSize;
   TL.Color := TAlphaColors.Black;
   TL.WordWrap := False;
   TL.Trimming := TTextTrimming.Character;
   TL.HorizontalAlign := TTextAlign.Leading;
   TL.VerticalAlign := TTextAlign.Center;
  finally
   TL.EndUpdate;
  end;
  TL.RenderLayout(Canvas);
 finally
  TL.Free;
 end;
end;

procedure TLayerFrame.ItemPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var L: TResource;
    Row: TTreeViewItem;
begin
 Row := TTreeViewItem(Sender);
 L := TResource(Row.TagObject);
 if L = nil then Exit;
// по высоте - по середине прямоугольника отрисовки пункта (видимая строка)
 DrawLayerRow(Canvas, L, ItemContentLeft(Row), Row.Width, ARect.Top, ARect.Height, L.Check <> 0);
end;

// заголовок: строка активного слоя до btnDrop (с отступом 5)
procedure TLayerFrame.HeaderBgPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var Chk: TCheckBox;
    Right: Single;
begin
 Chk := ChkLayerCtrl;
 Right := HeaderBg.AbsoluteToLocal(btnDrop.LocalToAbsolute(TPointF.Zero)).X - 5;
 if Right > HeaderBg.Width then Right := HeaderBg.Width;
 DrawLayerRow(Canvas, ActiveLayer, 0, Right, ARect.Top, ARect.Height, (Chk <> nil) and Chk.IsChecked);
end;

// флажок видимости строки: слой и вложенные - вкл/выкл, строки, заголовок, карта
procedure TLayerFrame.ToggleLayerCheck(Layer: TResource);
begin
 if Layer = nil then Exit;
 if Layer.Check <> 0 then SetLayerCheckRecursive(Layer, 0) else SetLayerCheckRecursive(Layer, 1);
 UpdateTreeChecksFromModel;
 SyncHeader;
 NotifyLayerVisibilityChanged;
end;

procedure TLayerFrame.SetLayerCheckRecursive(Layer: TResource; ACheck: Byte);
var
 I: Integer;
 Child: TResource;
begin
 if Layer = nil then Exit;
 Layer.Check := ACheck;
 if Layer.Resources = nil then Exit;
 for I := 0 to Layer.Resources.Count - 1 do
 begin
  Child := TResource(Layer.Resources[I]);
  if Child <> nil then
   SetLayerCheckRecursive(Child, ACheck);
 end;
end;

procedure TLayerFrame.NotifyLayerVisibilityChanged;
var
 Obj: TFmxObject;
 F: TCommonCustomForm;
begin
 F := nil;
 Obj := Self;
 while (Obj <> nil) and (F = nil) do
 begin
  if Obj is TCommonCustomForm then
   F := TCommonCustomForm(Obj)
  else
   Obj := Obj.Parent;
 end;

 if (F <> nil) and (F is TMainFormSkia) then
 begin
  TMainFormSkia(F).InvalidateCachedPictureOnly;
  if TMainFormSkia(F).SkPainter <> nil then
   TMainFormSkia(F).SkPainter.Redraw;
 end;
end;

end.

