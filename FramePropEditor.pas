unit FramePropEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Grid, FMX.Grid.Style, Collect, TwgDraw, System.Rtti,
  EcLot, WpTwigs, newSelector, newProcs, WPTForm2, newProperties, SelectedObjects;

type
  TPropRow = class
  public
   RawName: string;
   DisplayName: string;
   Value: string;
   TypeName: string;
   IsSystem: Boolean;
   IsSystemDisabled: Boolean;
   IsUserProp: Boolean;
  end;

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
  private
   FSelector: TSelector;
  //
   FGrid: TStringGrid;
   FColName: TStringColumn;
   FColValue: TStringColumn;
   FRows: TObjectList<TPropRow>;
   FLastMouseDown: TPointF;
   FSuppressEdit: Boolean;
 //
   procedure EnsureGrid;
   procedure ClearRows;
   class function BuildDisplayName(const RawName: string; out IsSystem, IsSystemDisabled, IsUserProp: Boolean): string; static;
   class function IsPointerType(const TypeName: string): Boolean; static;
 //
   procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure GridGetValue(Sender: TObject; const Col, Row: Integer; var Value: TValue);
   procedure GridSetValue(Sender: TObject; const Col, Row: Integer; const Value: TValue);
   procedure GridCellClick(const Column: TColumn; const Row: Integer);
   procedure GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
    const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
 //
   procedure SetSystemPropertiesValue(Objects: PCollection);
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure Update(Sender: TObject);
   procedure SetEnumProperties(Selector_: TSelector; Obj: TTD); overload;
   procedure SetEnumProperties(Selector_: TSelector; Objects: PCollection); overload;
   function TwgForm: TForm2;
  end;

var PropEditorForm: TPropEditorFrame;

implementation uses TwgColle, newForm0, newResource, Writer;

{$R *.fmx}

{ TPropEditorFrame }

constructor TPropEditorFrame.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FRows := TObjectList<TPropRow>.Create(True);
 EnsureGrid;
end;

destructor TPropEditorFrame.Destroy;
begin
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
 FGrid.Options := FGrid.Options + [TGridOption.Editing];
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
 //
 FColValue := TStringColumn.Create(FGrid);
 FColValue.Parent := FGrid;
 FColValue.Header := 'Значение';
 FColValue.ReadOnly := False;
end;

procedure TPropEditorFrame.ClearRows;
begin
 FRows.Clear;
 If FGrid <> nil then
  FGrid.RowCount := 0;
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
  //
  FGrid.RowCount := FRows.Count;
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
  Objects.INsert(Obj);
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
var Objects: TSelectedObjects; Def: TUpdatePropObject;
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
begin
 If (Row < 0) or (Row >= FRows.Count) then begin Value := ''; Exit; end;
 //
 If Col = 0 then
  Value := FRows[Row].RawName
 else
  Value := FRows[Row].Value;
end;

procedure TPropEditorFrame.GridSetValue(Sender: TObject; const Col, Row: Integer; const Value: TValue);
begin
 If (Row < 0) or (Row >= FRows.Count) then Exit;
 If Col <> 1 then Exit;
 If (FRows[Row] <> nil) and (FRows[Row].IsSystem) then Exit;
 //
 FRows[Row].Value := Value.ToString;
end;

procedure TPropEditorFrame.GridCellClick(const Column: TColumn; const Row: Integer);
var RowObj: TPropRow; CellR: TRectF;
begin
 If (Column = nil) or (Column.Index <> 1) then Exit;
 If (Row < 0) or (Row >= FRows.Count) then Exit;
 //
 RowObj := FRows[Row];
 If (RowObj = nil) or (RowObj.TypeName = '') then Exit;
 //
 If not IsPointerType(RowObj.TypeName) then Exit;
 //
 CellR := FGrid.CellRect(Column.Index, Row);
 If FLastMouseDown.X >= (CellR.Right - 24) then begin
  try
   FGrid.EditorMode := False;
  except
  end;
  FSuppressEdit := True;
  FGrid.Options := FGrid.Options - [TGridOption.Editing];
  ShowMessage(RowObj.TypeName);
 end;
end;

procedure TPropEditorFrame.GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
  const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var R: TRectF; S: string; RowObj: TPropRow;
    PrevFill: TBrush; PrevFontColor: TAlphaColor;
begin
 If (Row < 0) or (Row >= FRows.Count) then Exit;
 //
 RowObj := FRows[Row];
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
  If (Column.Index = 0) then S := RowObj.RawName else S := RowObj.Value;
  //
  R := Bounds;
  R.Left := R.Left + 6;
  If (Column.Index = 1) and IsPointerType(RowObj.TypeName) then
   R.Right := R.Right - 24;
  Canvas.FillText(R, S, False, 1, [], TTextAlign.Leading, TTextAlign.Center);

  If (Column.Index = 1) and IsPointerType(RowObj.TypeName) then
  begin
   R := Bounds;
   R.Right := R.Right - 6;
   R.Left := R.Right - 24;
   Canvas.FillText(R, '...', False, 1, [], TTextAlign.Center, TTextAlign.Center);
  end;
 finally
  Canvas.Fill.Kind := PrevFill.Kind;
  Canvas.Fill.Color := PrevFill.Color;
  PrevFill.Free;
 end;
end;

{ TUpdatePropObject }

{ TUpdateObject }

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
