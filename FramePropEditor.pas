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
  DlgRootPropEditor, DlgPropColorEditor;

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
   function TwgForm: TForm2;
  end;

var PropEditorForm: TPropEditorFrame;

implementation uses TwgColle, newForm0, newResource, Writer, LBN, MainFrm,
                    UndoColNew, userObject, GBFWUndo, DlgPropFontEditor;

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
 if FColName <> nil then FColName.Width := CW1;
 if (FColValue <> nil) and (CW2 > 0) then FColValue.Width := CW2;
 AlignColumns;
end;

destructor TPropEditorFrame.Destroy;
begin
 GWriteFloat(Name + '_Col1', FColName.Width);
 GWriteFloat(Name + '_Col2', FColValue.Width);
 GWriteFloat(Name + '_W', Width);
//
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
 FRows.Clear;
 If FGrid <> nil then
  FGrid.RowCount := 0;
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

procedure TPropEditorFrame.Update(Sender: TObject);
var Def: TUpdatePropObject;
begin
 Objects := TSelectedObjects(Sender);
 If Objects = nil then begin
  ClearRows;
  Exit;
 end;
 //
 If Objects.Count = 0 then begin
  ClearRows;
  exit;
  Writein(['upd1']);
  Def := TUpdatePropObject.Create(Objects.TwgForm);
  try
     Writein(['upd11']);
   SetEnumProperties(Objects.TwgForm.Selector, Def);
  Writein(['upd2']);
  finally
   Def.Free;
  end;
 end else begin
  SetEnumProperties(Objects.TwgForm.Selector, Objects.GeoObjects);
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
  RunPropertyEditorDialog(RowObj);
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

Procedure TPropEditorFrame.SetProperty(propName:String;propValue:String;Layer:Pointer = nil);
var I,propSettingCount:Integer;Undo:TUndo;oldPropValue:String;oldLayer:TResource;
    badCol:PCollection;
begin
 GlobalPropertyUnLocked:=True;
 try
  If (Pos('#',PropName)<>0)and(Pos('##',PropName) = 0)and(Pos('#Текстура',PropName)=0)and(PropName<>'#Штриховка')and(Pos('#Прозрачность',PropName)=0)and(Pos('#Изображение',PropName)=0) then exit;
  Undo:=TwgForm.Undo;
  If propValue = '' then propValue:=byLayer;
  badCol:=PCollection.Create(1);
  If propName = 'Знак' then begin
  If Objects<>nil then
   For I:=0 to Objects.Count-1 do If TTD(Objects[I]).GetProperty(propName)<>propValue then begin
    oldPropValue:=TTD(Objects[I]).GetProperty(propName);
    oldLayer:=TTD(Objects[I]).GetLayer;
    TTD(Objects[I]).SetProperty(propName,propValue);
    If Layer<>nil then TTD(Objects[I]).SetLayer(Layer);
   // !!! If not updateMessage.ModifiedPrim(Objects[I]) then badCol.Insert(Objects[I]);
    TTD(Objects[I]).SetProperty(propName,OldpropValue);
    TTD(Objects[I]).SetLayer(oldLayer);
   end;
  end;
  Undo.StartTransAction;
  Undo.AddUndoItem(TPrimUndo.Create(TwgForm,LU_ModifiedPrim,'SetProperty...'+PropName+'='+PropValue));
  try
   propSettingCount:=0;
 //  Writeln(propName,' = ',propValue);
   If Objects<>nil then
    For I:=0 to Objects.Count-1 do If badCol.IndexOf(Objects[I])=-1 then begin
      TPrimUndo(Undo.Last).AddModifiedPrim(Objects[I]);
     If TTD(Objects[I]).SetProperty(propName,propValue) then begin
      Inc(propSettingCount);
      If Layer<>nil then TTD(Objects[I]).SetLayer(Layer);
     end;
    end;
 //  Writeln(propSettingCount);
  badCol.DeleteAll;badCol.Free;
   If propSettingCount=0 then begin
    Undo.RollBack;
 //!!!   UpdatePropObject.SetProperty(propName,propValue);
    exit;
   end;
   TForm2(TwgForm).ClassBuildII;
   TForm2(TwgForm).Modified:=True;
   FSelector.UpdateImage;
   Undo.Commit;
  except Undo.RollBack;end;
 finally
  GlobalPropertyUnlocked:=False;
 end;
end;

function TPropEditorFrame.RunPropertyEditorDialog(Row: TPropRow): string;
begin
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
 inherited SetProperty(propName,propValue);
end;

end.
