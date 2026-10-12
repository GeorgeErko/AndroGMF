unit FramePropEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  System.ImageList, FMX.ImgList,
  FMX.Edit,
  FMX.Layouts, FMX.ListBox, FMX.Grid, FMX.Grid.Style, Collect, TwgDraw, System.Rtti,
  EcLot, WpTwigs, newSelector, newProcs, WPTForm2, newProperties, SelectedObjects,
  DlgRootPropEditor, DlgPropColorEditor, FMX.Controls.Presentation;

type
  TUpdatePropObject = class(TLot)
   TwgForm:TForm2;
    Constructor Create(Form:TForm2);
    Destructor Destroy;override;
   // Своцства по умолчанию
    Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
    Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
    Procedure ClearProperties;
  end;

 //
  TPropEditorFrame = class(TFrame)
    ImageList1: TImageList;
  // панель кнопок (Panel2 TPropEditorForm старой программы): ImageIndex в
  // ImageListPanel - sbOr 0, sbAnd 1, sbSelectByLayer 2, sbAllSelect 3,
  // sbMinus 4, sbMinusMinus 5, sbUp 6, sbDown 7, sbAddProp 8; состояние
  // блокировки (sbLock) - 9 все, 10 нет, 11 часть объектов
    ImageListPanel: TImageList;
    PanelButtons: TLayout;
    sbOr: TSpeedButton;
    sbAnd: TSpeedButton;
    sbSelectByLayer: TSpeedButton;
    sbAllSelect: TSpeedButton;
    sbLock: TSpeedButton;
    sbMinus: TSpeedButton;
    sbMinusMinus: TSpeedButton;
    sbUp: TSpeedButton;
    sbDown: TSpeedButton;
    sbAddProp: TSpeedButton;
    procedure sbOrClick(Sender: TObject);
    procedure sbAndClick(Sender: TObject);
    procedure sbLockClick(Sender: TObject);
    procedure sbMoveClick(Sender: TObject);
    procedure sbMinusMinusClick(Sender: TObject);
    procedure sbAddPropClick(Sender: TObject);
  private
   FSelector: TSelector;
  //
   FGrid: TStringGrid;
   FColName: TStringColumn;
   FColValue: TStringColumn;
   FRows: TObjectList<TPropRow>;
   FLastMouseDown: TPointF;
   FSuppressEdit: Boolean;
   FPickCombo: TComboBox;
   FPickComboRow: Integer;
   FValueEdit: TEdit;
   FValueEditRow: Integer;
   FAligningCols: Boolean;
  //
   Objects: TSelectedObjects;
  // свойства по умолчанию для новых примитивов (UpdatePropObject старой
  // программы): показываются и редактируются, когда ничего не выделено
   FDefaults: TUpdatePropObject;
   FResetBtn: TButton;
   procedure ShowDefaults;
   procedure ResetBtnClick(Sender: TObject);
   procedure EnsureGrid;
   procedure ClearRows;
   class function BuildDisplayName(const RawName: string; out IsSystem, IsSystemDisabled, IsUserProp: Boolean): string; static;
   class function IsPointerType(const TypeName: string): Boolean; static;
   procedure UpdateRowPickLists;
   function GetToolImages: TImageList;
   function GetIconRectInValueCell(const CellBounds: TRectF; const IconIndexFromRight: Integer; const IconSize: Single): TRectF;
   procedure AlignColumns;
   procedure FrameResize(Sender: TObject);
   procedure ColumnResize(Sender: TObject);
   procedure AdjustInplaceEditor;
   procedure EnsureValueEdit;
   procedure HideValueEdit(const Commit: Boolean);
   procedure ShowValueEdit(const Row: Integer);
   procedure ValueEditExit(Sender: TObject);
   procedure ValueEditKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
   procedure PickComboChange(Sender: TObject);
   procedure PickComboClosePopup(Sender: TObject);
   procedure HidePickCombo;
 //
   procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure GridGetValue(Sender: TObject; const Col, Row: Integer; var Value: TValue);
   procedure GridSetValue(Sender: TObject; const Col, Row: Integer; const Value: TValue);
   procedure GridCellClick(const Column: TColumn; const Row: Integer);
   procedure GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
    const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
  //
   procedure SetSystemPropertiesValue(Objects: PCollection);
  //
   function RunPropertyEditorDialog(Row: TPropRow): string;
  // строка свойства под курсором таблицы; nil - нет
   function CurrentRow: TPropRow;
   procedure GridSelChanged(Sender: TObject);
   procedure UpdateLockButton;
  // выделение по свойству (sbOrClick старой программы): EqIndex - условие
  // (PropMatch), InObjects - только среди выделенных, AddObjects - к выделенным
   procedure SelectByProperty(EqIndex: Integer; const PropName, Pattern: String; Num, InObjects, AddObjects: Boolean);
  // свойства объектов изменены: строки заново, курсор - на свойство PropName
   procedure RefreshObjects(const PropName: String; OldRow: Integer);
   procedure MoveProperty(const PropName: String; Tag: Integer);
  public
   OnActivateSignInstrument: TNotifyEvent;
   ActivePropRow: TPropRow;
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure Update(Sender: TObject);
   procedure SetEnumProperties(Selector_: TSelector; Obj: TTD); overload;
   procedure SetEnumProperties(Selector_: TSelector; Objects: PCollection); overload;
  //
   procedure SetProperty(propName:String;propValue:String;Layer:Pointer = nil);
   procedure DetachObjects(AObjects: TObject);
  // свойства по умолчанию: новая карта (сброс на 'по слою'), сброс, установка,
  // применение к новому примитиву (вызывают обработчики рисования)
   function HasSelection: Boolean;
   procedure SetDefaultsForm(Form: TForm2);
   procedure ResetDefaults;
   procedure SetDefaultProperty(const propName, propValue: String);
   procedure ApplyDefaults(Obj: TTD);
   procedure ApplyToObjects(const UndoName: String; Layer: Pointer; Accept: TFunc<TObject, Boolean>; Apply: TProc<TObject>);
   function TwgForm: TForm2;
  end;

var PropEditorForm: TPropEditorFrame;

implementation uses TwgColle, newForm0, newResource, Writer, LBN, MainFrm,
                    UndoColNew, userObject, GBFWUndo, DlgPropFontEditor, UpdateMessages,
                    FMX.DialogService, EcDot, EcDot2, DlgPropAdd, DlgPropSelect, DlgDelProperties;

{$R *.fmx}

{ TPropEditorFrame }

constructor TPropEditorFrame.Create(AOwner: TComponent);
var W, CW1, CW2: Single;
begin
 inherited Create(AOwner);
 FRows := TObjectList<TPropRow>.Create(True);
 W := GReadFloat(Name + '_W', 0);
 CW1 := GReadInteger(Name + '_Col1', 170);
 CW2 := GReadInteger(Name + '_Col2', 0);
 if W > 0 then
  TControl(AOwner).Width := W;
 FPickCombo := TComboBox.Create(Self);
 FPickCombo.Parent := Self;
 FPickCombo.Stored := False;
 FPickCombo.Visible := False;
 FPickComboRow := -1;
 FValueEditRow := -1;
 FPickCombo.OnChange := PickComboChange;
 FPickCombo.OnClosePopup := PickComboClosePopup;
 OnResize := FrameResize;
 EnsureGrid;
 EnsureValueEdit;
 FGrid.ReadOnly := True;
 FGrid.Options := FGrid.Options - [TGridOption.Editing] - [TGridOption.AlwaysShowEditor];
 if sbSelectByLayer <> nil then sbSelectByLayer.IsPressed := GReadInteger(Name + '_SelectByLayer', 0) = 1;
 if sbAllSelect <> nil then sbAllSelect.IsPressed := GReadInteger(Name + '_AllSelect', 0) = 1;
 if FColName <> nil then FColName.Width := CW1;
 if (FColValue <> nil) and (CW2 > 0) then FColValue.Width := CW2;
 AlignColumns;
end;

destructor TPropEditorFrame.Destroy;
begin
 GWriteFloat(Name + '_Col1', FColName.Width);
 GWriteFloat(Name + '_Col2', FColValue.Width);
 GWriteFloat(Name + '_W', Width);
 GWriteInteger(Name + '_SelectByLayer', Ord(sbSelectByLayer.IsPressed));
 GWriteInteger(Name + '_AllSelect', Ord(sbAllSelect.IsPressed));
//
 FreeAndNil(FDefaults);
 FRows.Free;
 inherited Destroy;
end;

procedure TPropEditorFrame.EnsureGrid;
begin
 If FGrid <> nil then Exit;
 //
 FGrid := TStringGrid.Create(Self);
 FGrid.Parent := Self;
 FGrid.Align := TAlignLayout.Client;
// FGrid.Options := FGrid.Options - [TGridOption.Editing];
 FGrid.RowCount := 0;
 FGrid.Stored := False;
 FGrid.OnMouseDown := GridMouseDown;
 FGrid.OnGetValue := GridGetValue;
 FGrid.OnSetValue := GridSetValue;
 FGrid.OnCellClick := GridCellClick;
 FGrid.OnDrawColumnCell := GridDrawColumnCell;
 FGrid.OnSelChanged := GridSelChanged;
 //
 FColName := TStringColumn.Create(FGrid);
 FColName.Parent := FGrid;
 FColName.Header := 'Свойство';
 FColName.ReadOnly := True;
 FColName.Width := 170;
 FColName.OnResize := ColumnResize;
 //
 FColValue := TStringColumn.Create(FGrid);
 FColValue.Parent := FGrid;
 FColValue.Header := 'Значение';
 FColValue.ReadOnly := False;
 FColValue.OnResize := ColumnResize;
 AlignColumns;
end;

function TPropEditorFrame.GetToolImages: TImageList;
begin
 Result := ImageList1;
end;

function TPropEditorFrame.GetIconRectInValueCell(const CellBounds: TRectF; const IconIndexFromRight: Integer; const IconSize: Single): TRectF;
var R: TRectF;
begin
 R := CellBounds;
 R.Right := R.Right - (IconIndexFromRight * IconSize);
 R.Left := R.Right - IconSize;
 R.Top := R.Top + (R.Height - IconSize) / 2;
 R.Bottom := R.Top + IconSize;
 Result := R;
end;

procedure TPropEditorFrame.AlignColumns;
var W, SBW: Single;
    wDelta: Single;
begin
 if FAligningCols then Exit;
 if (FGrid = nil) or (FColName = nil) or (FColValue = nil) then Exit;
 FAligningCols := True;
 try
  W := FGrid.Width;
  if W <= 0 then W := Width;
  if W <= 0 then Exit;

  SBW := 0;
  try
   if (FGrid.VScrollBar <> nil) and FGrid.VScrollBar.Visible then
    SBW := FGrid.VScrollBar.Width;
  except
  end;

  wDelta := 10;
  W := W - SBW - wDelta;
  if W < 0 then W := 0;

  if FColName.Width < 80 then FColName.Width := 80;
  if FColName.Width > (W - 80) then FColName.Width := W - 80;
  FColValue.Width := W - FColName.Width;
  if FColValue.Width < 80 then FColValue.Width := 80;
 finally
  FAligningCols := False;
 end;
   try
   if (FGrid.VScrollBar <> nil) and FGrid.VScrollBar.Visible and (FGrid.HScrollBar <> nil) then
   begin
    FGrid.HScrollBar.Visible := False;
    FGrid.HScrollBar.Enabled := False;
   end;
  except
  end;

end;

procedure TPropEditorFrame.FrameResize(Sender: TObject);
begin
 AlignColumns;
 HideValueEdit(False);
end;

procedure TPropEditorFrame.ColumnResize(Sender: TObject);
begin
 AlignColumns;
 HideValueEdit(False);
end;

procedure TPropEditorFrame.EnsureValueEdit;
begin
 if FValueEdit <> nil then Exit;
 FValueEdit := TEdit.Create(Self);
 FValueEdit.Parent := Self;
 FValueEdit.Stored := False;
 FValueEdit.Visible := False;
 FValueEdit.OnExit := ValueEditExit;
 FValueEdit.OnKeyDown := ValueEditKeyDown;
end;

procedure TPropEditorFrame.HideValueEdit(const Commit: Boolean);
var PropName, NewValue: string;
begin
 if (FValueEdit = nil) or (not FValueEdit.Visible) then Exit;
 if Commit and (FValueEditRow >= 0) and (FValueEditRow < FRows.Count) and (FRows[FValueEditRow] <> nil) then
 begin
  if not FRows[FValueEditRow].IsSystem then
  begin
   NewValue := FValueEdit.Text;
   if FRows[FValueEditRow].Value <> NewValue then
   begin
    FRows[FValueEditRow].Value := NewValue;
    PropName := FRows[FValueEditRow].RawName;
    if PropName <> '' then
     SetProperty(PropName, NewValue);
   end;
  end;
 end;
 FValueEdit.Visible := False;
end;

procedure TPropEditorFrame.ShowValueEdit(const Row: Integer);
var DataRow, BtnW: Integer;
    CellR: TRectF;
    RAbs: TRectF;
    W: Single;
    P, PAbs: TPointF;
    ACol, ARow: Integer;
begin
 EnsureValueEdit;
 if (FGrid = nil) or (FValueEdit = nil) then Exit;
 if (Row < 0) or (Row >= FGrid.RowCount) then Exit;
 DataRow := Row;
 if (DataRow < 0) or (DataRow >= FRows.Count) then Exit;
 if (FRows[DataRow] = nil) or FRows[DataRow].IsSystem then Exit;

 HidePickCombo;
 if not FGrid.CellByPoint(FLastMouseDown.X, FLastMouseDown.Y, ACol, ARow) then exit;
 CellR := FGrid.CellRect(1, Row);
 BtnW := 0;
 if ((FRows[DataRow].PickList <> nil) and (FRows[DataRow].PickList.Count > 0)) or IsPointerType(FRows[DataRow].TypeName) then
  BtnW := 18;
// WriteIn([CellR.Height, CellR.Top + CellR.Height,FLastMouseDown.Y, FGrid.VScrollBar.Position.Y]);
 P := PointF(CellR.Left, FLastMouseDown.Y - (CellR.Height / 2) + 1);
 // (ARow - FGrid.TopRow) * CellR.Height + CellR.Height);//FLastMouseDown.Y - (CellR.Height / 2) + 1);
 PAbs := FGrid.LocalToAbsolute(P);
 P := Self.AbsoluteToLocal(PAbs);

 FValueEditRow := DataRow;
 FValueEdit.Text := FRows[DataRow].Value;
 FValueEdit.Position.X := P.X + 1;
 FValueEdit.Position.Y := P.Y + 1;
 FValueEdit.Width := CellR.Width - BtnW - 2;
 FValueEdit.Height := CellR.Height - 2;
 FValueEdit.Visible := True;
 FValueEdit.BringToFront;
 try
  FValueEdit.SetFocus;
  FValueEdit.SelectAll;
 except
 end;
end;

procedure TPropEditorFrame.ValueEditExit(Sender: TObject);
begin
 HideValueEdit(True);
end;

procedure TPropEditorFrame.ValueEditKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
 if Key = vkReturn then
 begin
  Key := 0;
  HideValueEdit(True);
 end;
 if Key = vkEscape then
 begin
  Key := 0;
  HideValueEdit(False);
 end;
end;

procedure TPropEditorFrame.AdjustInplaceEditor;
var CellR: TRectF;
    Obj: TFmxObject;
    Ctrl: TControl;
    I: Integer;
    W: Single;
begin
 if FGrid = nil then Exit;
 if FGrid.Col <> 1 then Exit;
 if (FGrid.Row < 0) or (FGrid.Row >= FGrid.RowCount) then Exit;
 CellR := FGrid.CellRect(1, FGrid.Row);
 W := CellR.Width - 18;
 if W < 10 then Exit;

 Ctrl := nil;
 try
  Obj := FGrid.FindStyleResource('editor');
  if (Obj <> nil) and (Obj is TControl) then
   Ctrl := TControl(Obj);
 except
 end;

 if Ctrl = nil then
  for I := 0 to FGrid.ChildrenCount - 1 do
   if (FGrid.Children[I] <> nil) and (FGrid.Children[I] is TEdit) and TEdit(FGrid.Children[I]).Visible then
   begin
    Ctrl := TControl(FGrid.Children[I]);
    Break;
   end;

 if Ctrl = nil then Exit;
 try
  Ctrl.Position.X := CellR.Left + 1;
  Ctrl.Width := W - 2;
 except
 end;
end;

procedure TPropEditorFrame.ClearRows;
begin
// строки освобождаются - ссылка на активную строку недействительна
 ActivePropRow := nil;
 FRows.Clear;
 If FGrid <> nil then
  FGrid.RowCount := 0;
 UpdateLockButton;
end;

procedure TPropEditorFrame.UpdateRowPickLists;
var I: Integer;
    S: string;
    SN: TSectionName;
begin
 if ListByDicts = nil then Exit;
 for I := 0 to FRows.Count - 1 do
  if (FRows[I] <> nil) and (FRows[I].RawName <> '') then
  begin
   if not ((Pos('##', FRows[I].RawName) = 1) or (Pos('*', FRows[I].RawName) = 1)) then Continue;
   S := FRows[I].RawName;
   if Pos('##', S) = 1 then Delete(S, 1, 2);
   SN := ListByDicts.FindByName2(AnsiString(S), 0);
   if SN = nil then Continue;
   if FRows[I].PickList = nil then FRows[I].PickList := TStringList.Create;
   FRows[I].PickList.Assign(SN.GetStrings(True));
  end;
end;

procedure TPropEditorFrame.HidePickCombo;
begin
 if FPickCombo = nil then Exit;
 FPickCombo.Visible := False;
 FPickComboRow := -1;
end;

procedure TPropEditorFrame.PickComboClosePopup(Sender: TObject);
begin
 HidePickCombo;
end;

procedure TPropEditorFrame.PickComboChange(Sender: TObject);
var PropName, NewValue: string;
begin
 if (FPickCombo = nil) or (FPickComboRow < 0) or (FPickComboRow >= FRows.Count) then Exit;
 if FRows[FPickComboRow] = nil then Exit;
 if FPickCombo.ItemIndex < 0 then Exit;
 NewValue := FPickCombo.Items[FPickCombo.ItemIndex];
 if FRows[FPickComboRow].Value <> NewValue then
 begin
  FRows[FPickComboRow].Value := NewValue;
  if not FRows[FPickComboRow].IsSystem then
  begin
   PropName := FRows[FPickComboRow].RawName;
   if PropName <> '' then
    SetProperty(PropName, NewValue);
  end;
 end;
 if FGrid <> nil then FGrid.Repaint;
end;

class function TPropEditorFrame.BuildDisplayName(const RawName: string; out IsSystem,
  IsSystemDisabled, IsUserProp: Boolean): string;
begin
 IsSystem := False;
 IsSystemDisabled := False;
 IsUserProp := False;
 //
 Result := RawName;
 If Result = '' then Exit;
 //
 If Result.StartsWith('##') then begin
  IsSystem := True;
  IsSystemDisabled := True;
  Result := Result.Substring(2);
  Exit;
 end;
 //
 If Result.StartsWith('#') then begin
  IsSystem := True;
  Result := Result.Substring(1);
  Exit;
 end;
 //
 If Result.StartsWith('*') then begin
  IsUserProp := True;
  Result := Result.Substring(1);
  Exit;
 end;
end;

procedure TPropEditorFrame.SetEnumProperties(Selector_: TSelector; Objects: PCollection);
var I, J: Integer; Obj, Base: TTD;
    PropNames, PropValues, PropTypes: TStrings;
    R: TPropRow;
    IsSystem, IsSystemDisabled, IsUserProp: Boolean;
    O: TObject;
begin
 FSelector := Selector_;
 EnsureGrid;
 ClearRows;
 //
 If (Objects = nil) or (Objects.Count = 0) then Exit;
 //
 Base := nil;
 For I := 0 to Objects.Count - 1 do begin
  O := TObject(Objects[I]);
  If O is TTD then begin Base := TTD(O); Break; end;
 end;
 If Base = nil then Exit;
 //
 PropNames := TStringList.Create;
 PropValues := TStringList.Create;
 PropTypes := TStringList.Create;
 try
  Base.GetObjectProps(PropNames, PropValues, PropTypes);
  //
  For I := 0 to Objects.Count - 1 do begin
   O := TObject(Objects[I]);
   If (O is TTD) and (TTD(O) <> Base) then
    TTD(O).GetPropMerge(Base, PropNames, PropValues, PropTypes);
  end;
  //
  For J := 0 to PropNames.Count - 1 do begin
   R := TPropRow.Create;
   R.RawName := PropNames[J];
   R.DisplayName := BuildDisplayName(R.RawName, IsSystem, IsSystemDisabled, IsUserProp);
   R.IsSystem := IsSystem;
   R.IsSystemDisabled := IsSystemDisabled;
   R.IsUserProp := IsUserProp;
   //
   If J <= PropValues.Count - 1 then begin
    R.Value := PropValues[J];
    If R.Value = 'None' then R.Value := 'По слою';
   end else
    R.Value := '';
   //
   If J <= PropTypes.Count - 1 then
    R.TypeName := PropTypes[J]
   else
    R.TypeName := '';
   //
   FRows.Add(R);
  end;
  //
  SetSystemPropertiesValue(Objects);
  UpdateRowPickLists;
  //
  FGrid.RowCount := FRows.Count;
//  TThread.Queue(nil, procedure
//  begin
   AlignColumns;
//  end);
  If FRows.Count > 0 then begin
   FGrid.Col := 1;
   FGrid.Row := 0;
  end;
  UpdateLockButton;
 finally
  PropNames.Free;
  PropValues.Free;
  PropTypes.Free;
 end;
end;

procedure TPropEditorFrame.SetEnumProperties(Selector_: TSelector; Obj: TTD);
var Objects: PCollection;
begin
 FSelector := Selector_;
 Objects :=PCollection.Create(1);
 try
  Objects.Insert(Obj);
  SetEnumProperties(Selector_, Objects);
 finally
  Objects.DeleteAll;
  Objects.Free;
 end;
end;

procedure TPropEditorFrame.SetSystemPropertiesValue(Objects: PCollection);
var I, J, Prec: Integer; V: Double; S: string; Obj: TObject; Lot: TLot;
    TWF: TTwigsCollect;
begin
 If (Objects = nil) or (FSelector = nil) then Exit;
 //
 TWF := nil;
 If FSelector.GTwgForm <> nil then
  TWF := TwgForm.Twigs;
 //
 For I := 0 to FRows.Count - 1 do If (FRows[I] <> nil) and (FRows[I].RawName <> '') then
  If (Pos('#', FRows[I].RawName) = 1) and (Pos('##', FRows[I].RawName) <> 1) then begin
   S := FRows[I].RawName;
   V := 0;
   Prec := Const_Of_DecimalLength;
   //
   For J := 0 to Objects.Count - 1 do begin
    Obj := TObject(Objects[J]);
    If Obj is TLot then begin
     Lot := TLot(Obj);
     If (S = '#Длина') or (S = '#Периметр') then begin
      If TWF <> nil then
       V := V + RoundDblToDbl(Lot.Perimeter(TWF), Const_Of_DecimalLength);
      Prec := Const_Of_DecimalLength;
     end;
     If S = '#Площадь' then begin
      V := V + RoundDblToDbl(Lot.Plo, Const_Of_DecimalSqwear);
      Prec := Const_Of_DecimalSqwear;
     end;
     If S = '#Площадь[лин]' then begin
      If TWF <> nil then
       V := V + RoundDblToDbl(Lot.GetLinearPlo(TWF), Const_Of_DecimalSqwear);
      Prec := Const_Of_DecimalSqwear;
     end;
     If S = '#Чистая площадь' then begin
      V := V + RoundDblToDbl(Lot.ClearPlo, Const_Of_DecimalSqwear);
      Prec := Const_Of_DecimalSqwear;
     end;
    end;
   end;
   //
   If (S = '#Длина') or (S = '#Периметр') then
    FRows[I].Value := FloatToStrF(V, ffFixed, _LD, Prec)
   else
   If (S = '#Площадь') or (S = '#Площадь[лин]') or (S = '#Чистая площадь') then
    FRows[I].Value := MetersGaStr(V);
  end;
end;

// выделение изменилось: свойства выделенных объектов; ничего не выделено (или
// выделения нет - активен не TEditMap) - свойства по умолчанию
procedure TPropEditorFrame.Update(Sender: TObject);
begin
 Objects := TSelectedObjects(Sender);
 If not HasSelection then begin
  ShowDefaults;
  Exit;
 end;
 If FResetBtn <> nil then FResetBtn.Visible := False;
 SetEnumProperties(Objects.TwgForm.Selector, Objects.GeoObjects);
end;

function TPropEditorFrame.HasSelection: Boolean;
begin
 Result := (Objects <> nil) and (Objects.Count > 0);
end;

// новая карта: свойства по умолчанию создаются заново (все - 'по слою'),
// номера знаков и типов линий другой карты могут не совпадать
procedure TPropEditorFrame.SetDefaultsForm(Form: TForm2);
begin
 FreeAndNil(FDefaults);
 Objects := nil;
 if Form = nil then begin
  ClearRows;
  exit;
 end;
 FSelector := Form.Selector;
 FDefaults := TUpdatePropObject.Create(Form);
 FDefaults.Selector := FSelector;
 ShowDefaults;
end;

// строки свойств по умолчанию и кнопка сброса
procedure TPropEditorFrame.ShowDefaults;
begin
 if FDefaults = nil then begin
  ClearRows;
  exit;
 end;
 if FResetBtn = nil then begin
  FResetBtn := TButton.Create(Self);
  FResetBtn.Stored := False;
  FResetBtn.Parent := Self;
  FResetBtn.Align := TAlignLayout.Top;
  FResetBtn.Height := 24;
  FResetBtn.Text := 'Сбросить все на «по слою»';
  FResetBtn.Hint := 'Свойства новых объектов по умолчанию - по слою';
  FResetBtn.OnClick := ResetBtnClick;
 end;
 FResetBtn.Visible := True;
 SetEnumProperties(FSelector, FDefaults);
end;

procedure TPropEditorFrame.ResetBtnClick(Sender: TObject);
begin
 ResetDefaults;
end;

procedure TPropEditorFrame.ResetDefaults;
begin
 if FDefaults = nil then exit;
 FDefaults.ClearProperties;
 if not HasSelection then ShowDefaults;
end;

// свойство по умолчанию (из редактора без выделения или из панели знаков);
// пустое значение - 'по слою'
procedure TPropEditorFrame.SetDefaultProperty(const propName, propValue: String);
var I: Integer;
    V: String;
begin
 if FDefaults = nil then exit;
 V := propValue;
 if V = '' then V := byLayer;
 FDefaults.SetProperty(AnsiString(propName), AnsiString(V));
 if HasSelection then exit;
 for I := 0 to FRows.Count - 1 do
  if (FRows[I] <> nil) and (FRows[I].RawName = propName) then FRows[I].Value := V;
 if FGrid <> nil then FGrid.Repaint;
end;

// новый примитив получает свойства по умолчанию, заданные не 'по слою', - только
// те, что есть у самого объекта (TPropEditorForm.SetEnumProperties старой программы)
procedure TPropEditorFrame.ApplyDefaults(Obj: TTD);
var I, J: Integer;
    ObjNames, ObjValues, ObjTypes, DefNames, DefValues, DefTypes: TStrings;
    V: String;
begin
 if (FDefaults = nil) or (Obj = nil) then exit;
 ObjNames := TStringList.Create;
 ObjValues := TStringList.Create;
 ObjTypes := TStringList.Create;
 DefNames := TStringList.Create;
 DefValues := TStringList.Create;
 DefTypes := TStringList.Create;
 GlobalPropertyUnLocked := True;
 try
  Obj.GetObjectProps(ObjNames, ObjValues, ObjTypes);
  FDefaults.GetObjectProps(DefNames, DefValues, DefTypes);
  for I := 0 to DefNames.Count - 1 do begin
   if I >= DefValues.Count then break;
   V := DefValues[I];
   if (V = '') or (V = byLayer) or (V = 'None') then continue;
   J := ObjNames.IndexOf(DefNames[I]);
   if J <> -1 then Obj.SetProperty(AnsiString(DefNames[I]), AnsiString(V));
  end;
 finally
  GlobalPropertyUnLocked := False;
  ObjNames.Free;
  ObjValues.Free;
  ObjTypes.Free;
  DefNames.Free;
  DefValues.Free;
  DefTypes.Free;
 end;
end;

function TPropEditorFrame.TwgForm: TForm2;
begin
 If FSelector = nil then
  Result := nil
 else
  Result := FSelector.GTwgForm;
end;

class function TPropEditorFrame.IsPointerType(const TypeName: string): Boolean;
begin
 Result := SameText(TypeName, 'Color') or SameText(TypeName, 'LineType') or SameText(TypeName, 'PointType') or
           SameText(TypeName, 'SquareType') or SameText(TypeName, 'Sign') or SameText(TypeName, 'StringSpr') or
           SameText(TypeName, 'FontName') or
           SameText(TypeName, 'FontStyle') or SameText(TypeName, 'GeoData') or SameText(TypeName, 'Percents') or
           SameText(TypeName, 'Explication') or SameText(TypeName, 'JSON') or SameText(TypeName, 'Memo') or
           SameText(TypeName, 'Foto') or SameText(TypeName, 'Tree') or SameText(TypeName, 'Block') or
           SameText(TypeName, 'Hatch') or SameText(TypeName, 'Texture') or SameText(TypeName, 'UNOM') or
           SameText(TypeName, 'ImageFile');
end;

procedure TPropEditorFrame.GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 If FSuppressEdit then begin
  FSuppressEdit := False;
  If FGrid <> nil then
   FGrid.Options := FGrid.Options + [TGridOption.Editing];
 end;
 //
 FLastMouseDown := PointF(X, Y);
end;

procedure TPropEditorFrame.GridGetValue(Sender: TObject; const Col, Row: Integer; var Value: TValue);
var DataRow: Integer;
begin
 DataRow := Row;
 If (DataRow < 0) or (DataRow >= FRows.Count) then begin Value := ''; Exit; end;
 //
 If Col = 0 then
  Value := FRows[DataRow].RawName
 else
  Value := FRows[DataRow].Value;
end;

procedure TPropEditorFrame.GridSetValue(Sender: TObject; const Col, Row: Integer; const Value: TValue);
var DataRow: Integer; PropName, NewValue: string;
begin
 DataRow := Row;
 If (DataRow < 0) or (DataRow >= FRows.Count) then Exit;
 If Col <> 1 then Exit;
 If (FRows[DataRow] <> nil) and (FRows[DataRow].IsSystem) then Exit;
 If (FPickCombo <> nil) and FPickCombo.Visible and (FPickComboRow = DataRow) and (Value.ToString = '') then Exit;
 If (FRows[DataRow] <> nil) and (FRows[DataRow].Value <> '') and (Value.ToString = '') then Exit;
 //
 NewValue := Value.ToString;
 if (FRows[DataRow] <> nil) and (FRows[DataRow].Value <> NewValue) then
 begin
  FRows[DataRow].Value := NewValue;
  PropName := FRows[DataRow].RawName;
  if PropName <> '' then
   SetProperty(PropName, NewValue);
 end;
end;

procedure TPropEditorFrame.GridCellClick(const Column: TColumn; const Row: Integer);
var RowObj: TPropRow; CellR: TRectF;
    NewValue: string;
    P, PAbs: TPointF;
    IconSize: Single;
    RBtn: TRectF;
    DataRow: Integer;
    Pt: TPointF;
begin
 If (Column = nil) or (Column.Index <> 1) then Exit;
 DataRow := Row;
 If (DataRow < 0) or (DataRow >= FRows.Count) then Exit;
 //
  RowObj := FRows[DataRow];
 If RowObj = nil then Exit;
 //
 ActivePropRow := RowObj;
 UpdateLockButton;
//
 Pt := FLastMouseDown;
 if (Pt.X = 0) and (Pt.Y = 0) then
  Pt := FGrid.AbsoluteToLocal(Screen.MousePos);
  //
  CellR := FGrid.CellRect(Column.Index, Row);
  IconSize := 18;
  RBtn := GetIconRectInValueCell(CellR, 0, IconSize);

 if (Pt.X >= (CellR.Right - IconSize)) then
 begin
  HideValueEdit(False);
  if (RowObj.PickList <> nil) and (RowObj.PickList.Count > 0) then
  begin
   if FPickCombo = nil then Exit;
   try
    FGrid.EditorMode := False;
   except
   end;
   FPickCombo.Parent := Self;
   FPickCombo.Items.BeginUpdate;
   try
    FPickCombo.Items.Clear;
    FPickCombo.Items.Assign(RowObj.PickList);
   finally
    FPickCombo.Items.EndUpdate;
   end;
   FPickComboRow := DataRow;
   FPickCombo.ItemIndex := FPickCombo.Items.IndexOf(RowObj.Value);
   FPickCombo.Position.X := 0;
   P := PointF(CellR.Left, FLastMouseDown.Y - (CellR.Height / 2) + 1);
   PAbs := FGrid.LocalToAbsolute(P);
   P := Self.AbsoluteToLocal(PAbs);
   FPickCombo.Position.Y := P.Y;
   FPickCombo.Width := Self.Width;
   FPickCombo.Height := CellR.Height - 2;
   FPickCombo.ItemIndex := FPickCombo.Items.IndexOf(RowObj.Value);
   FPickCombo.Visible := True;
   FPickCombo.BringToFront;
   try
    FPickCombo.SetFocus;
   except
   end;
   TThread.Queue(nil, procedure
   begin
    try
     if (FPickCombo <> nil) and FPickCombo.Visible then
      FPickCombo.DropDown;
    except
    end;
   end);
   Exit;
  end;
  If (RowObj.TypeName = '') or (not IsPointerType(RowObj.TypeName)) then Exit;
  try
   FGrid.EditorMode := False;
  except
  end;
  FSuppressEdit := True;
  FGrid.Options := FGrid.Options - [TGridOption.Editing];
 // значение из диалога (цвет, шрифт и др.) - выделенным объектам; '' - отмена.
 // Знаки (PointType, LineType, Block) выбираются в панелях знаков
  NewValue := RunPropertyEditorDialog(RowObj);
  if (NewValue <> '') and (RowObj.RawName <> '') then begin
   RowObj.Value := NewValue;
   SetProperty(RowObj.RawName, NewValue);
  end;
  Exit;
 end;
//
 HidePickCombo;
 ShowValueEdit(Row);
end;

procedure TPropEditorFrame.GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
  const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var R: TRectF; S: string; RowObj: TPropRow;
    PrevFill: TBrush; PrevFontColor: TAlphaColor;
    Images: TImageList;
    IconSize: Single;
    RBtn: TRectF;
    IconIndex: Integer;
    DataRow: Integer;
begin
 DataRow := Row;
 If (DataRow < 0) or (DataRow >= FRows.Count) then Exit;
 //
 RowObj := FRows[DataRow];
 PrevFill := TBrush.Create(TBrushKind.Solid, Canvas.Fill.Color);
 try
  PrevFontColor := Canvas.Fill.Color;
 //
  If RowObj.IsSystem then begin
   Canvas.Fill.Kind := TBrushKind.Solid;
   If RowObj.IsSystemDisabled then
    Canvas.Fill.Color := TAlphaColorRec.Gainsboro
   else
    Canvas.Fill.Color := TAlphaColorRec.MistyRose;
   Canvas.FillRect(Bounds, 0, 0, [], 1);
  end;
 //
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := TAlphaColorRec.Black;
  If RowObj.IsSystemDisabled and (Column.Index = 0) then
   Canvas.Fill.Color := TAlphaColorRec.Gray;
 //
  If RowObj.RawName[1] = '*' then
   Canvas.Fill.Color := TAlphaColorRec.Gray;
 //
  If (Column.Index = 0) then S := RowObj.DisplayName else S := RowObj.Value;
  //
  R := Bounds;
  R.Left := R.Left + 6;
  If (Column.Index = 1) and ((RowObj.PickList <> nil) and (RowObj.PickList.Count > 0) or IsPointerType(RowObj.TypeName)) then
   R.Right := R.Right - 18;
  Canvas.FillText(R, S, False, 1, [], TTextAlign.Leading, TTextAlign.Center);

  if (Column.Index = 1) and ((RowObj.PickList <> nil) and (RowObj.PickList.Count > 0) or IsPointerType(RowObj.TypeName)) then
  begin
   Images := GetToolImages;
   if Images <> nil then
   begin
    IconSize := 18;
    RBtn := GetIconRectInValueCell(Bounds, 0, IconSize);
    if (RowObj.PickList <> nil) and (RowObj.PickList.Count > 0) then IconIndex := 1 else
     IconIndex := 0;
    try
     Images.Draw(Canvas, RBtn, IconIndex, 1);
    except
    end;
   end;
  end;
 finally
  Canvas.Fill.Kind := PrevFill.Kind;
  Canvas.Fill.Color := PrevFill.Color;
  PrevFill.Free;
 end;
end;

// установка свойства выделенных объектов (TPropEditorForm.SetProperty старой
// программы): системные свойства ('#...') не меняются, кроме перечисленных;
// пустое значение - 'по слою'. Знак, который UpdateMessage.ModifiedPrim не
// разрешает, объекту не ставится. Изменение с отменой, измененные объекты
// перестраиваются в сцене, значение строки редактора обновляется
Procedure TPropEditorFrame.SetProperty(propName:String;propValue:String;Layer:Pointer = nil);
var I,propSettingCount:Integer;Undo:TUndo;oldPropValue:String;oldLayer:TResource;
    badCol,Changed:PCollection;
    Obj:TTD;
begin
// ничего не выделено - свойство по умолчанию для новых примитивов
 If not HasSelection then begin
  SetDefaultProperty(propName, propValue);
  exit;
 end;
 If TwgForm = nil then exit;
 If (Pos('#',PropName)<>0)and(Pos('##',PropName) = 0)and(Pos('#Текстура',PropName)=0)and(PropName<>'#Штриховка')and(Pos('#Прозрачность',PropName)=0)and(Pos('#Изображение',PropName)=0) then exit;
 If propValue = '' then propValue:=byLayer;
 Undo:=TwgForm.Undo;
 badCol:=PCollection.Create(1);
 Changed:=PCollection.Create(1);
 GlobalPropertyUnLocked:=True;
 try
 // знак: проверка нового знака сообщением ModifiedPrim (объект временно получает
 // знак и слой, затем они возвращаются)
  If (propName = 'Знак') and (UpdateMessage <> nil) then
   For I:=0 to Objects.Count-1 do begin
    Obj:=TTD(Objects[I]);
    If Obj.GetProperty(propName)<>propValue then begin
     oldPropValue:=Obj.GetProperty(propName);
     oldLayer:=Obj.GetLayer;
     Obj.SetProperty(propName,propValue);
     If Layer<>nil then Obj.SetLayer(Layer);
     If not UpdateMessage.ModifiedPrim(Obj) then badCol.Insert(Obj);
     Obj.SetProperty(propName,oldPropValue);
     If oldLayer<>nil then Obj.SetLayer(oldLayer);
    end;
   end;
  Undo.StartTransAction;
  try
   Undo.AddUndoItem(TPrimUndo.Create(TwgForm,LU_ModifiedPrim,'SetProperty...'+PropName+'='+PropValue));
   propSettingCount:=0;
   For I:=0 to Objects.Count-1 do If badCol.IndexOf(Objects[I])=-1 then begin
    TPrimUndo(Undo.Last).AddModifiedPrim(Objects[I]);
    If TTD(Objects[I]).SetProperty(propName,propValue) then begin
     Inc(propSettingCount);
     If Layer<>nil then TTD(Objects[I]).SetLayer(Layer);
     Changed.Insert(Objects[I]);
    end;
   end;
   If propSettingCount=0 then begin
    Undo.RollBack;
    exit;
   end;
   TwgForm.ClassBuildII;
   TwgForm.Modified:=True;
   Undo.Commit;
  except
   on E: Exception do begin
    WriteIn(['SetProperty ', propName, ' exception ', E.Message]);
    Undo.RollBack;
    exit;
   end;
  end;
 // измененные объекты - в сцену
  For I:=0 to Changed.Count-1 do FSelector.UpdateImage(usmModify,Changed[I]);
 // значение в строке редактора ('по слою' вместо пустого)
  For I:=0 to FRows.Count-1 do
   If (FRows[I]<>nil) and (FRows[I].RawName = propName) then FRows[I].Value:=propValue;
  If FGrid<>nil then FGrid.Repaint;
 finally
  GlobalPropertyUnlocked:=False;
  badCol.DeleteAll;badCol.Free;
  Changed.DeleteAll;Changed.Free;
 end;
end;

// коллекция выделенных объектов освобождается (TEditMap.Destroy) - редактор
// больше на нее не ссылается
procedure TPropEditorFrame.DetachObjects(AObjects: TObject);
begin
 if (AObjects <> nil) and (TObject(Objects) = AObjects) then Update(nil);
end;

// знак из панели знаков (inst...Sign) - выделенным объектам: Accept отбирает
// объекты, Apply меняет знак, Layer <> nil - объекты переносятся в этот слой.
// Изменение с отменой, объекты перестраиваются в сцене, строки редактора
// заполняются заново
procedure TPropEditorFrame.ApplyToObjects(const UndoName: String; Layer: Pointer; Accept: TFunc<TObject, Boolean>; Apply: TProc<TObject>);
var I: Integer;
    Col: PCollection;
    Undo: TUndo;
begin
 if (Objects = nil) or (Objects.Count = 0) or (TwgForm = nil) then exit;
 Col := PCollection.Create(1);
 try
  for I := 0 to Objects.Count - 1 do
   if Accept(TObject(Objects[I])) then Col.Insert(Objects[I]);
  if Col.Count = 0 then exit;
  Undo := TwgForm.Undo;
  GlobalPropertyUnLocked := True;
  try
   Undo.StartTransAction;
   try
    Undo.AddUndoItem(TPrimUndo.Create(TwgForm, LU_ModifiedPrim, UndoName));
    for I := 0 to Col.Count - 1 do begin
     TPrimUndo(Undo.Last).AddModifiedPrim(Col[I]);
     Apply(TObject(Col[I]));
     if Layer <> nil then TTD(Col[I]).SetLayer(Layer);
    end;
    TwgForm.ClassBuildII;
    TwgForm.Modified := True;
    Undo.Commit;
   except
    on E: Exception do begin
     WriteIn([UndoName, ' exception ', E.Message]);
     Undo.RollBack;
     exit;
    end;
   end;
  finally
   GlobalPropertyUnLocked := False;
  end;
  for I := 0 to Col.Count - 1 do FSelector.UpdateImage(usmModify, Col[I]);
  Update(Objects);
 finally
  Col.DeleteAll;
  Col.Free;
 end;
end;

function TPropEditorFrame.RunPropertyEditorDialog(Row: TPropRow): string;
begin
  Result := '';
  if Row = nil then exit;
 //
  if SameText(Row.TypeName, 'Color') then begin
   PropColorEditorForm := TPropColorEditorForm.Create(MainForm);
    Result := PropColorEditorForm.Execute(Row);
   PropColorEditorForm.Free;
  end else
  if (SameText(Row.TypeName, 'PointType') or
      SameText(Row.TypeName, 'LineType') or SameText(Row.TypeName, 'Block')) then
  begin
   ActivePropRow := Row;
   OnActivateSignInstrument(Row);
  end else
  if SameText(Row.TypeName, 'FontName') then begin
   PropFontEditorForm := TPropFontEditorForm.Create(MainForm);
    Result := PropFontEditorForm.Execute(Row);
   PropFontEditorForm.Free;
  end else begin
   RootPropEditorForm := TRootPropEditorForm.Create(MainForm);
    Result := RootPropEditorForm.Execute(Row);
   RootPropEditorForm.Free;
  end;
end;

{ панель кнопок (Panel2 TPropEditorForm старой программы) }

function PropNum(const S: String; out V: Double): Boolean;
begin
 Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', []), V, TFormatSettings.Invariant);
end;

// условие на значение свойства: 0 '=', 1 '<>', 2 '>=', 3 '<=', 4 '>', 5 '<',
// 6 '%' (содержит), 7 'a...b' (в диапазоне); Num - сравнение чисел
function PropMatch(EqIndex: Integer; const Value, Pattern: String; Num: Boolean): Boolean;
var A, B, V: Double;
    C, P: Integer;
    S1, S2: String;
begin
 Result := False;
 if EqIndex = 6 then exit(Pos(Pattern, Value) <> 0);
 if EqIndex = 7 then begin
  P := Pos('...', Pattern);
  if P = 0 then exit;
  S1 := Trim(Copy(Pattern, 1, P - 1));
  S2 := Trim(Copy(Pattern, P + 3, MaxInt));
  if not Num then exit((Value >= S1) and (Value <= S2));
  if PropNum(S1, A) and PropNum(S2, B) and PropNum(Value, V) then Result := (V >= A) and (V <= B);
  exit;
 end;
 if Num then begin
  if not (PropNum(Value, V) and PropNum(Pattern, A)) then exit;
  if V < A then C := -1 else if V > A then C := 1 else C := 0;
 end else
  C := CompareStr(Value, Pattern);
 case EqIndex of
  0: Result := C = 0;
  1: Result := C <> 0;
  2: Result := C >= 0;
  3: Result := C <= 0;
  4: Result := C > 0;
  5: Result := C < 0;
 end;
end;

function ObjProps(O: TObject): TProperties;
begin
 Result := nil;
 if O is TLot then Result := TLot(O).Properties else
 if O is TPointDot then Result := TPointDot(O).Properties;
end;

function TPropEditorFrame.CurrentRow: TPropRow;
begin
 Result := nil;
 if (FGrid = nil) or (FGrid.Row < 0) or (FGrid.Row >= FRows.Count) then exit;
 Result := FRows[FGrid.Row];
end;

procedure TPropEditorFrame.GridSelChanged(Sender: TObject);
begin
 UpdateLockButton;
end;

// блокировка замены свойства при автоматизированных расчетах (sbLock,
// ObjInsp1SelectCell): только свойства пользователя ('*'); значок - у всех
// объектов со свойством заблокировано, у части или ни у одного
procedure TPropEditorFrame.UpdateLockButton;
var R: TPropRow;
    I, N, Cnt: Integer;
    PV: TPropValue;
begin
 if sbLock = nil then exit;
 R := CurrentRow;
 sbLock.Enabled := HasSelection and (R <> nil) and (Pos('*', R.RawName) = 1);
 if not sbLock.Enabled then begin
  sbLock.ImageIndex := 10;
  exit;
 end;
 N := 0;
 Cnt := 0;
 for I := 0 to Objects.Count - 1 do begin
  if not TTD(Objects[I]).UseProperty(AnsiString(R.RawName)) then continue;
  Inc(N);
  PV := TPropValue(TTD(Objects[I]).GetPropValue(AnsiString(R.RawName)));
  if (PV <> nil) and (PV.varType = varTypeLocked) then Inc(Cnt);
 end;
 if (Cnt > 0) and (Cnt = N) then sbLock.ImageIndex := 9 else
 if Cnt > 0 then sbLock.ImageIndex := 11 else sbLock.ImageIndex := 10;
end;

// заблокировано у всех - блокировка снимается, иначе - ставится всем
procedure TPropEditorFrame.sbLockClick(Sender: TObject);
var R: TPropRow;
    I: Integer;
    PV: TPropValue;
    Lock: Boolean;
begin
 R := CurrentRow;
 if (R = nil) or not HasSelection then exit;
 Lock := sbLock.ImageIndex <> 9;
 for I := 0 to Objects.Count - 1 do begin
  if not TTD(Objects[I]).UseProperty(AnsiString(R.RawName)) then continue;
  PV := TPropValue(TTD(Objects[I]).GetPropValue(AnsiString(R.RawName)));
  if PV = nil then continue;
  if Lock then PV.varType := varTypeLocked else PV.varType := 0;
 end;
 if TwgForm <> nil then TwgForm.Modified := True;
 UpdateLockButton;
end;

// выделение объектов вида образца (первого выделенного объекта: контур, текст,
// точка; sbAllSelect - всех видов), sbSelectByLayer - только слоя образца.
// Точке подходит и атрибут подписи с тем же именем (без '#')
procedure TPropEditorFrame.SelectByProperty(EqIndex: Integer; const PropName, Pattern: String; Num, InObjects, AddObjects: Boolean);
var Sample, Obj: TTD;
    SampleKind, I: Integer;
    Layer: TResource;
    B: Byte;
    Sel: TSelectedObjects;
    Twigs: TTwigsCollect;
function Kind(O: TObject): Integer;
begin
 if O is TLot then Result := 0 else
 if O is TDotText then Result := 1 else
 if O is TPointDot then Result := 2 else Result := -1;
end;
function Accept(O: TTD): Boolean;
var A: String;
begin
 Result := False;
 if (Kind(O) = -1) or ((Kind(O) <> SampleKind) and not sbAllSelect.IsPressed) then exit;
 if sbSelectByLayer.IsPressed and (O.GetLayer <> Layer) then exit;
 Result := PropMatch(EqIndex, String(O.GetProperty(AnsiString(PropName))), Pattern, Num);
 if Result or not (O is TPointDot) or (TPointDot(O).TextManager = nil) then exit;
 A := PropName;
 while (A <> '') and (A[1] = '#') do Delete(A, 1, 1);
 Result := PropMatch(EqIndex, String(TPointDot(O).TextManager.AttrValue(AnsiString(A))), Pattern, Num);
end;
procedure Check(O: TTD);
begin
 if Accept(O) and (Sel.IndexOf(O) = -1) then Sel.Insert(O);
end;
begin
 if not HasSelection or (TwgForm = nil) then exit;
 Sel := Objects;
 Sample := TTD(Sel[0]);
 SampleKind := Kind(Sample);
 Layer := Sample.GetLayer;
 Sel.Locked := True;
 try
  if InObjects then begin
   for I := Sel.Count - 1 downto 0 do
    if not Accept(TTD(Sel[I])) then Sel.AtDelete(I);
  end else begin
   if not AddObjects then Sel.DeleteAll;
   Twigs := TwgForm.Twigs;
   for I := 0 to Twigs.LotsCount - 1 do begin
    Obj := Twigs.LAt(I);
    if TLot(Obj).Closed = 1 then Check(Obj);
   end;
   for I := 0 to Twigs.AnyCount - 1 do begin
    Obj := Twigs.AAt(I, B);
    if (B = TWG_Point) and not TPointDot(Obj).Closed then Check(Obj);
   end;
  end;
 finally
  Sel.Locked := False;
  Sel.Update;
 end;
end;

// ИЛИ: к выделенным - объекты с тем же значением свойства
procedure TPropEditorFrame.sbOrClick(Sender: TObject);
var R: TPropRow;
begin
 R := CurrentRow;
 if (R = nil) or not HasSelection then exit;
 SelectByProperty(0, R.RawName, R.Value, False, False, True);
end;

// И: условие из диалога (DlgPropSelect)
procedure TPropEditorFrame.sbAndClick(Sender: TObject);
var R: TPropRow;
    PropName: String;
begin
 R := CurrentRow;
 if (R = nil) or not HasSelection then exit;
 PropName := R.RawName;
 TPropSelectForm.Execute(R.DisplayName, R.Value,
  procedure(F: TPropSelectForm)
  var A: Double;
      P: Integer;
      Ok: Boolean;
  begin
   if F.IsNumber then begin
    P := Pos('...', F.Pattern);
    if F.ZnakIndex = 7 then Ok := (P <> 0) and PropNum(Copy(F.Pattern, 1, P - 1), A) and PropNum(Copy(F.Pattern, P + 3, MaxInt), A) else
     Ok := PropNum(F.Pattern, A);
    if not Ok then begin
     MessageError('Задайте число (числа) в строке выражения');
     exit;
    end;
   end;
   SelectByProperty(F.ZnakIndex, PropName, F.Pattern, F.IsNumber, F.InObjects, F.AddObjects);
  end);
end;

// строки заново после изменения свойств объектов; курсор - на PropName или
// на прежнюю строку
procedure TPropEditorFrame.RefreshObjects(const PropName: String; OldRow: Integer);
var I: Integer;
begin
 if TwgForm <> nil then TwgForm.Modified := True;
 Update(Objects);
 if (FGrid = nil) or (FRows.Count = 0) then exit;
 if PropName <> '' then
  for I := 0 to FRows.Count - 1 do
   if FRows[I].RawName = PropName then begin
    FGrid.Row := I;
    UpdateLockButton;
    exit;
   end;
 if OldRow >= FRows.Count then OldRow := FRows.Count - 1;
 if OldRow < 0 then OldRow := 0;
 FGrid.Row := OldRow;
 UpdateLockButton;
end;

// Tag: 1 - вверх, 2 - вниз, 0 - удаление (sbDownClick)
procedure TPropEditorFrame.MoveProperty(const PropName: String; Tag: Integer);
var I, Row: Integer;
    Props: TProperties;
begin
 if not HasSelection then exit;
 Row := FGrid.Row;
 for I := 0 to Objects.Count - 1 do begin
  Props := ObjProps(TObject(Objects[I]));
  if Props = nil then continue;
  case Tag of
   1: Props.Up(AnsiString(PropName));
   2: Props.Down(AnsiString(PropName));
  else
   Props.DeleteProperty(AnsiString(PropName));
  end;
 end;
 if Tag = 0 then RefreshObjects('', Row) else RefreshObjects(PropName, Row);
end;

procedure TPropEditorFrame.sbMoveClick(Sender: TObject);
var R: TPropRow;
    PropName: String;
begin
 R := CurrentRow;
 if (R = nil) or not HasSelection then exit;
 PropName := R.RawName;
 if TComponent(Sender).Tag <> 0 then begin
  MoveProperty(PropName, TComponent(Sender).Tag);
  exit;
 end;
 TDialogService.MessageDialog('Удалить свойство "' + R.DisplayName + '"?', TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
  procedure(const AResult: TModalResult)
  begin
   if AResult = mrYes then MoveProperty(PropName, 0);
  end);
end;

// удаление группы свойств: отмеченные в диалоге (DlgDelProperties)
procedure TPropEditorFrame.sbMinusMinusClick(Sender: TObject);
begin
 if not HasSelection then exit;
 TDelPropertiesForm.Execute(Objects,
  procedure(Names: TStrings)
  var I, J: Integer;
  begin
   if not HasSelection then exit;
   for I := 0 to Names.Count - 1 do
    for J := 0 to Objects.Count - 1 do TTD(Objects[J]).DeleteProperty(AnsiString(Names[I]));
   RefreshObjects('', FGrid.Row);
  end);
end;

// свойства из справочника (DlgPropAdd): значение '--' - свойство удаляется,
// '++' - только добавляется (если его нет), иначе - устанавливается;
// «очистить *» - сначала удаляются все свойства пользователя
procedure TPropEditorFrame.sbAddPropClick(Sender: TObject);
begin
 if not HasSelection then begin
  MessageInform('Выберите объекты...');
  exit;
 end;
 TPropAddForm.Execute([String(MainPath) + 'Properties.ini', String(MainPath) + 'Dictionary.txt', String(MainPath) + 'Dictionary_odh.txt'],
  procedure(F: TPropAddForm)
  var I, J: Integer;
      Obj: TTD;
      Props: TProperties;
      N, V: AnsiString;
  begin
   if not HasSelection then exit;
   for I := 0 to Objects.Count - 1 do begin
    Obj := TTD(Objects[I]);
    if F.cbClear.IsChecked then begin
     Props := ObjProps(Obj);
     if Props <> nil then
      for J := Props.Count - 1 downto 0 do
       if Pos('*', String(Props[J].PropName)) = 1 then Obj.DeleteProperty(Props[J].PropName);
    end;
    for J := 0 to F.PropNames.Count - 1 do begin
     N := AnsiString(F.PropNames[J]);
     V := AnsiString(F.PropValues[J]);
     if V = '--' then begin
      if Obj.UseProperty(N) then Obj.DeleteProperty(N);
     end else
     if V = '++' then begin
      if not Obj.UseProperty(N) then Obj.AddProperty(N);
     end else
      Obj.SetProperty(N, V);
    end;
   end;
   RefreshObjects('', FGrid.Row);
  end);
end;

{ TUpdatePropObject }

procedure TUpdatePropObject.ClearProperties;
begin
 SetProperty('Цвет',byLayer);
 SetProperty('Цвет заливки',byLayer);
 SetProperty('Тип линии',byLayer);
 SetProperty('Тип заливки',byLayer);
 SetProperty('Масштаб',byLayer);
 SetProperty('Толщина',byLayer);
 SetProperty('Знак',byLayer);
 SetProperty('Шрифт',byLayer);
 SetProperty('Размер',byLayer);
 SetProperty('Стиль',byLayer);
end;

constructor TUpdatePropObject.Create(Form: TForm2);
var Pr:TResource;
begin
 Pr:=TResource.CreateRes(GResRec);
 inherited Create(Pr.ID,Pr,1);
 TwgForm:=Form;
 Properties:=TProperties.Create;
 Properties.AddProperty('Цвет',byLayer);
 Properties.AddProperty('Цвет заливки',byLayer);
 Properties.AddProperty('Тип линии',byLayer);
 Properties.AddProperty('Тип заливки',byLayer);
 Properties.AddProperty('Масштаб',byLayer);
 Properties.AddProperty('Толщина',byLayer);
 Properties.AddProperty('Знак',byLayer);
 Properties.AddProperty('Шрифт',byLayer);
 Properties.AddProperty('Размер',byLayer);
 Properties.AddProperty('Стиль',byLayer);
end;

destructor TUpdatePropObject.Destroy;
begin
 inherited Destroy;
 ClassHandle.Free;
end;

procedure TUpdatePropObject.GetObjectProps(propNames, propValues, propTypes: TStrings;Data:Pointer = nil);
begin
{1}
 PropNames.Add('Цвет');PropNames.Add('Цвет заливки');PropNames.Add('Тип линии');PropNames.Add('Тип заливки');PropNames.Add('Масштаб');PropNames.Add('Толщина');
 If PropTypes<>nil then begin
  propTypes.Add('Color');propTypes.Add('Color');propTypes.Add('LineType');propTypes.Add('SquareType');propTypes.Add('Float');propTypes.Add('Float');
 end;
 If propValues<>nil then begin
  propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Цвет заливки'));propValues.Add(GetProperty('Тип линии'));propValues.Add(GetProperty('Тип заливки'));propValues.Add(GetProperty('Масштаб'));propValues.Add(GetProperty('Толщина'));
 end;
{2}
 PropNames.Add('Знак');PropNames.Add('Шрифт');PropNames.Add('Размер');PropNames.Add('Стиль');
 If PropTypes<>nil then begin
  propTypes.Add('PointType');propTypes.Add('FontName');propTypes.Add('Float');propTypes.Add('FontStyle');
 end;
 If propValues<>nil then begin
  propValues.Add(GetProperty('Знак'));propValues.Add(GetProperty('Шрифт'));propValues.Add(GetProperty('Размер'));propValues.Add(GetProperty('Стиль'));
 end;
end;

function TUpdatePropObject.SetProperty(propName: AnsiString; propValue: AnsiString; Obj:TTD = nil): boolean;
begin
 Result := inherited SetProperty(propName,propValue);
end;

end.
