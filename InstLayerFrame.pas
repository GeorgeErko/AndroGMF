unit InstLayerFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.TreeView,
  newLayersTable, newResource, FMX.Controls.Presentation,
  MainFrmSkia, newProcs, System.ImageList, FMX.ImgList;

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
    procedure PopupLayersClosePopup(Sender: TObject);

    function ChkLayerCtrl: TCheckBox;
    function RectColorCtrl: TRectangle;
    function LayerNameCtrl: TLabel;

    procedure EnsureHeaderControls;
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
    function EnsureItemForLayer(Layer: TResource): TTreeViewItem;
    procedure SyncHeader;
    procedure UpdateTreeChecksFromModel;
    procedure ApplyCheckAll(ACheck: Boolean);
    procedure ApplyInvert;
    function GetLayerText(Layer: TResource): string;
    function GetLayerFillColor(Layer: TResource): TAlphaColor;
    function GetLayerStrokeColor(Layer: TResource): TAlphaColor;

    procedure ItemVisCheckChange(Sender: TObject);
    function FindItemVisCheck(const Item: TTreeViewItem): TCheckBox;
    function FindItemLabel(const Item: TTreeViewItem): TLabel;
    function FindItemColorRect(const Item: TTreeViewItem): TRectangle;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshUI;
    procedure ActivateLayer(Layer: TResource; Symbol: Integer);
  public
   // слой выбран в списке слоев (щелчком по слою или кнопкой OK, в т.ч. группа):
   // форма переносит в него выделенные объекты; при активации программно не вызывается
    OnLayerSelected: TNotifyEvent;
    procedure SelectLayer(Layer: TResource);
    function IsGroupLayer(Layer: TResource): Boolean;
    property LayerTable: TLayerTable read FLayerTable write SetLayerTable;
    procedure SetActiveLayerByName(LayerName: String);
    property ActiveLayer: TResource read GetActiveLayer write SetActiveLayer;
  end;

var LayerFrame: TLayerFrame;

implementation

{$R *.fmx}

procedure TLayerFrame.EnsurePopupResizeGrip;
var
 Grip: TSizeGrip;
 C: TComponent;
begin
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
end;

procedure TLayerFrame.SavePopupSize;
begin
 if PopupLayers = nil then Exit;
 GWriteFloat('Layers_PopupW', PopupLayers.Width);
 GWriteFloat('Layers_PopupH', PopupLayers.Height);
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
 FPopupResizeStartSize := TPointF.Create(PopupLayers.Width, PopupLayers.Height);
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

 if PopupLayers.IsOpen then
  AlignPopupToDropButton;
end;

procedure TLayerFrame.PopupGripMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FPopupResizing then Exit;
 FPopupResizing := False;
 SavePopupSize;
end;

procedure TLayerFrame.AlignPopupToDropButton;
begin
 if PopupLayers = nil then Exit;
 if btnDrop = nil then Exit;
 PopupLayers.PlacementTarget := btnDrop;
 PopupLayers.Placement := TPlacement.Bottom;
 PopupLayers.VerticalOffset := 0;
 PopupLayers.HorizontalOffset := btnDrop.Width - PopupLayers.Width;
end;

{ TLayerFrame }

constructor TLayerFrame.Create(AOwner: TComponent);
begin
 inherited;
 FLayerToItem := TObjectDictionary<TObject, TTreeViewItem>.Create([]);
 EnsureHeaderControls;
 EnsurePopupResizeGrip;
 LoadPopupSize;
 if PopupLayers <> nil then PopupLayers.OnClosePopup := PopupLayersClosePopup;
end;

// popup закрыт полностью: содержимое вернулось во фрейм
procedure TLayerFrame.PopupLayersClosePopup(Sender: TObject);
begin
 FPopupShown := False;
 FPopupClosedTick := TThread.GetTickCount64;
end;

destructor TLayerFrame.Destroy;
begin
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
 if (PopupLayers <> nil) and PopupLayers.IsOpen and FLayerToItem.TryGetValue(Layer, Item) then begin
  FUpdating := True;
  try
   TreeLayers.Selected := Item;
  finally
   FUpdating := False;
  end;
 end;
end;

procedure TLayerFrame.SetActiveLayerByName(LayerName: String);
begin
 if FLayerTable.LayerName[LayerName] <> nil then
  SetActiveLayer(FLayerTable.LayerName[LayerName]);
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
begin
 if HeaderBg = nil then Exit;

 Chk := ChkLayerCtrl;
 if Chk = nil then
 begin
  Chk := TCheckBox.Create(Self);
  Chk.Name := 'chkLayer';
  Chk.Stored := False;
  Chk.Position.X := 2;
  Chk.Position.Y := 4;
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
  Col.Position.X := 24;
  Col.Position.Y := 8;
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
  Nm.Position.Y := 4;
  Nm.Height := 20;
  Nm.Width := 420;
//  Nm.StyledSettings := Nm.StyledSettings - [TStyledSetting.WordWrap];
  Nm.TextSettings.WordWrap := False;
  Nm.HitTest := False;
  Nm.Parent := HeaderBg;
 end;
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
 end;
end;

procedure TLayerFrame.RebuildTree;
var
 I: Integer;
 L: TResource;
 Item: TTreeViewItem;
begin
 if FUpdating then Exit;
 FUpdating := True;
 try
  TreeLayers.Clear;
  FLayerToItem.Clear;
  if FLayerTable = nil then Exit;

  for I := 0 to FLayerTable.L2Count - 1 do
  begin
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
end;

function TLayerFrame.EnsureItemForLayer(Layer: TResource): TTreeViewItem;
var
 ParentLayer: TResource;
 ParentItem: TTreeViewItem;
 Item: TTreeViewItem;
 Chk: TCheckBox;
 C: TRectangle;
 Nm: TLabel;
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
 Item.Height := 24;

 Chk := TCheckBox.Create(Item);
 Chk.Stored := False;
 Chk.Name := 'chkVis';
 Chk.Position.X := 2;
 Chk.Position.Y := 2;
 Chk.Width := 20;
 Chk.Height := 20;
 Chk.IsChecked := (Layer.Check <> 0);
 Chk.TagObject := Layer;
 Chk.OnChange := ItemVisCheckChange;
 Item.AddObject(Chk);

 C := TRectangle.Create(Item);
 C.Stored := False;
 C.Name := 'rectColor';
 C.Position.X := 24;
 C.Position.Y := 6;
 C.Size.Width := 10;
 C.Size.Height := 10;
 C.Fill.Color := GetLayerFillColor(Layer);
 C.Stroke.Color := GetLayerStrokeColor(Layer);
 C.HitTest := False;
 Item.AddObject(C);

 Nm := TLabel.Create(Item);
 Nm.Stored := False;
 Nm.Name := 'lblName';
 Nm.Position.X := 38;
 Nm.Position.Y := 2;
 Nm.Height := 20;
 Nm.Width := 400;
// Nm.StyledSettings := Nm.StyledSettings - [TStyledSetting.WordWrap];
 Nm.TextSettings.WordWrap := False;
 Nm.Text := GetLayerText(Layer);
 Nm.HitTest := False;
 Item.AddObject(Nm);

 if ParentItem <> nil then
  Item.Parent := ParentItem
 else
  Item.Parent := TreeLayers;

 FLayerToItem.Add(Layer, Item);
 Result := Item;
end;

procedure TLayerFrame.UpdateTreeChecksFromModel;
var
 Pair: TPair<TObject, TTreeViewItem>;
 L: TResource;
 Chk: TCheckBox;
 Nm: TLabel;
 C: TRectangle;
begin
 if FUpdating then Exit;
 FUpdating := True;
 try
  for Pair in FLayerToItem do
  begin
   L := TResource(Pair.Key);
   Chk := FindItemVisCheck(Pair.Value);
   if Chk <> nil then
   begin
    Chk.TagObject := L;
    Chk.IsChecked := (L <> nil) and (L.Check <> 0);
   end;
   Nm := FindItemLabel(Pair.Value);
   if Nm <> nil then
    Nm.Text := GetLayerText(L);
   C := FindItemColorRect(Pair.Value);
   if C <> nil then
   begin
    C.Fill.Color := GetLayerFillColor(L);
    C.Stroke.Color := GetLayerStrokeColor(L);
   end;
  end;
 finally
  FUpdating := False;
 end;
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

procedure TLayerFrame.btnDropClick(Sender: TObject);
begin
 if PopupLayers = nil then Exit;
// TPopup сначала сбрасывает IsOpen (BeforeClose), а возвращает содержимое во
// фрейм позже (ClosePopup, после анимации). Пока закрытие не завершено,
// дерево не перестраивается и popup повторно не открывается
 if FPopupShown then
 begin
  PopupLayers.IsOpen := False;
  Exit;
 end;
// щелчок по кнопке при открытом списке сам закрыл его (потеря фокуса) - не открываем снова
 if TThread.GetTickCount64 - FPopupClosedTick < 300 then Exit;
 RebuildTree;
 AlignPopupToDropButton;
 FPopupShown := True;
 try
  PopupLayers.IsOpen := True;
 except
  FPopupShown := False;
  raise;
 end;
end;

procedure TLayerFrame.chkLayerChange(Sender: TObject);
var
 L: TResource;
 Chk: TCheckBox;
begin
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
  TThread.ForceQueue(nil, procedure begin PopupLayers.IsOpen := False; end);
end;

// смена выделения в дереве (в т.ч. клавишами) слой не выбирает - выбор
// щелчком (TreeLayersMouseUp) или кнопкой OK
procedure TLayerFrame.TreeLayersMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 Item: TTreeViewItem;
 L: TResource;
 PAbs: TPointF;
 PItem: TPointF;
begin
 if FUpdating then Exit;
 Item := TreeLayers.ItemByPoint(X, Y) as TTreeViewItem;
 if Item = nil then Exit;
 L := TResource(Item.TagObject);
 if L = nil then Exit;
// флажок видимости - X=2..22 (EnsureItemForLayer): щелчок по нему слой не выбирает
 PAbs := TreeLayers.LocalToAbsolute(TPointF.Create(X, Y));
 PItem := Item.AbsoluteToLocal(PAbs);
 if (PItem.X >= 2) and (PItem.X <= 22) then Exit;
 TreeLayers.Selected := Item;
// группа слоев - только раскрыть/свернуть (выбрать группу - кнопкой OK)
 if IsGroupLayer(L) then begin
  if Item.IsExpanded then Item.Collapse else Item.Expand;
  Exit;
 end;
 SelectLayer(L);
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
 TThread.ForceQueue(nil, procedure begin PopupLayers.IsOpen := False; end);
end;

procedure TLayerFrame.btnCancelClick(Sender: TObject);
begin
 TThread.ForceQueue(nil, procedure begin PopupLayers.IsOpen := False; end);
end;

function TLayerFrame.FindItemVisCheck(const Item: TTreeViewItem): TCheckBox;
var
 I: Integer;
 Obj: TFmxObject;
begin
 Result := nil;
 if Item = nil then Exit;
 for I := 0 to Item.ChildrenCount - 1 do
 begin
  Obj := Item.Children[I];
  if (Obj is TCheckBox) and SameText(Obj.Name, 'chkVis') then
   Exit(TCheckBox(Obj));
 end;
end;

function TLayerFrame.FindItemLabel(const Item: TTreeViewItem): TLabel;
var
 I: Integer;
 Obj: TFmxObject;
begin
 Result := nil;
 if Item = nil then Exit;
 for I := 0 to Item.ChildrenCount - 1 do
 begin
  Obj := Item.Children[I];
  if (Obj is TLabel) and SameText(Obj.Name, 'lblName') then
   Exit(TLabel(Obj));
 end;
end;

function TLayerFrame.FindItemColorRect(const Item: TTreeViewItem): TRectangle;
var
 I: Integer;
 Obj: TFmxObject;
begin
 Result := nil;
 if Item = nil then Exit;
 for I := 0 to Item.ChildrenCount - 1 do
 begin
  Obj := Item.Children[I];
  if (Obj is TRectangle) and SameText(Obj.Name, 'rectColor') then
   Exit(TRectangle(Obj));
 end;
end;

procedure TLayerFrame.ItemVisCheckChange(Sender: TObject);
var
 Chk: TCheckBox;
 L: TResource;
begin
 if FUpdating then Exit;
 if not (Sender is TCheckBox) then Exit;
 Chk := TCheckBox(Sender);
 L := TResource(Chk.TagObject);
 if L = nil then Exit;
 if Chk.IsChecked then
  SetLayerCheckRecursive(L, 1)
 else
  SetLayerCheckRecursive(L, 0);

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

