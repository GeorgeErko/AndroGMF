unit instQuickLayers;

// Быстрые слои (FlyQuickLayers.TQuickLayerForm старой программы): список
// слоев, отмеченных в таблице слоев (TResource.Level <> 0 - хранится в GMF).
// Щелчок по слою - он становится активным (в списке слоев LayerFrame);
// «Добавить» - активный слой добавляется в список (с подтверждением, без окна
// выбора слоя), «Удалить» - выбранный слой убирается из списка, «Применить» -
// активный слой задается выделенным объектам (OnApply формы).
// Не перенесено: меню «Паспорт ГУ ИС».

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation,
  newLayersTable, newResource, System.ImageList, FMX.ImgList;

type
  TQuickLayersFrame = class(TFrame)
    List: TListBox;
    ButtonsLay: TLayout;
    sbPrim: TSpeedButton;
    sbAdd: TSpeedButton;
    sbDel: TSpeedButton;
    ImageList1: TImageList;
    procedure ListItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure sbAddClick(Sender: TObject);
    procedure sbDelClick(Sender: TObject);
    procedure sbPrimClick(Sender: TObject);
  private
    FLayerTable: TLayerTable;
    FLayers: TList<TResource>; // слои пунктов списка (по индексу)
    procedure SetLayerTable(const Value: TLayerTable);
    function LayerInTable(Layer: TResource): Boolean;
  public
   // слой выбран щелчком в списке: форма делает его активным (LayerFrame)
    OnLayerClick: TNotifyEvent;
   // «Применить»: активный слой - выделенным объектам
    OnApply: TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateItems;
   // активный слой сменился (в т.ч. в списке слоев): выделить его в списке
    procedure ChangeQuickLayer(Layer: TResource);
    function SelectedLayer: TResource;
    property LayerTable: TLayerTable read FLayerTable write SetLayerTable;
  end;

implementation

uses FMX.DialogService;

{$R *.fmx}

constructor TQuickLayersFrame.Create(AOwner: TComponent);
begin
 inherited;
 FLayers := TList<TResource>.Create;
end;

destructor TQuickLayersFrame.Destroy;
begin
 FLayers.Free;
 inherited;
end;

procedure TQuickLayersFrame.SetLayerTable(const Value: TLayerTable);
begin
 FLayerTable := Value;
 UpdateItems;
end;

function TQuickLayersFrame.LayerInTable(Layer: TResource): Boolean;
begin
 Result := (FLayerTable <> nil) and (Layer <> nil) and (FLayerTable.LinearLayers.IndexOf(Layer) <> -1);
end;

// список - слои таблицы с Level <> 0; выбранный пункт сохраняется, если слой
// остался в списке, иначе выделяется активный слой
procedure TQuickLayersFrame.UpdateItems;
var I: Integer;
    L, Sel: TResource;
begin
 Sel := SelectedLayer;
 List.BeginUpdate;
 try
  List.Clear;
  FLayers.Clear;
  if FLayerTable <> nil then
   for I := 0 to FLayerTable.LinearLayers.Count - 1 do begin
    L := FLayerTable.LinearLayer[I];
    if (L = nil) or (L.Level = 0) then continue;
    List.Items.Add(String(L.RecString));
    FLayers.Add(L);
   end;
 finally
  List.EndUpdate;
 end;
 if (Sel <> nil) and (FLayers.IndexOf(Sel) <> -1) then List.ItemIndex := FLayers.IndexOf(Sel) else
 if FLayerTable <> nil then ChangeQuickLayer(FLayerTable.ActiveLayer);
end;

function TQuickLayersFrame.SelectedLayer: TResource;
begin
 Result := nil;
 if (List.ItemIndex >= 0) and (List.ItemIndex < FLayers.Count) then Result := FLayers[List.ItemIndex];
end;

procedure TQuickLayersFrame.ChangeQuickLayer(Layer: TResource);
var I: Integer;
begin
 I := FLayers.IndexOf(Layer);
 if I <> -1 then List.ItemIndex := I;
end;

// щелчок по слою: слой активный; слоя уже нет в таблице - пункт удаляется
procedure TQuickLayersFrame.ListItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
var L: TResource;
begin
 L := SelectedLayer;
 if L = nil then exit;
 if not LayerInTable(L) then begin
  UpdateItems;
  exit;
 end;
 if Assigned(OnLayerClick) then OnLayerClick(Self) else FLayerTable.ActiveLayer := L;
end;

// добавление активного слоя (вместо окна выбора слоя старой программы)
procedure TQuickLayersFrame.sbAddClick(Sender: TObject);
var L: TResource;
begin
 if FLayerTable = nil then exit;
 L := FLayerTable.ActiveLayer;
 if not LayerInTable(L) then begin
  TDialogService.ShowMessage('Нет активного слоя');
  exit;
 end;
 if L.Level <> 0 then begin
  ChangeQuickLayer(L);
  TDialogService.ShowMessage('Слой "' + String(L.RecString) + '" уже есть в списке');
  exit;
 end;
 TDialogService.MessageDialog('Добавить слой "' + String(L.RecString) + '"?', TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
  procedure(const AResult: TModalResult)
  begin
   if (AResult <> mrYes) or not LayerInTable(L) then exit;
   L.Level := -1;
   UpdateItems;
   ChangeQuickLayer(L);
  end);
end;

procedure TQuickLayersFrame.sbDelClick(Sender: TObject);
var L: TResource;
begin
 L := SelectedLayer;
 if L = nil then exit;
 L.Level := 0;
 UpdateItems;
end;

procedure TQuickLayersFrame.sbPrimClick(Sender: TObject);
begin
 if Assigned(OnApply) then OnApply(Self);
end;

end.
