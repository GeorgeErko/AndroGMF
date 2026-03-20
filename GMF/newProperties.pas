unit newProperties;

interface uses Collect, Classes, SysUtils, FMX.Controls, FMX.Objects;

const propNULL ='-123456789';
      binaryValue = 'Изображение';


type
 TPropValue = class(TTwgObject)
  fValue:AnsiString;
  intValue:Integer;
  floatValue:Double;
  exceptValue:byte;
 //
  varType:Integer;
  Binary:TImage;
  Constructor Create(Value_:AnsiString);
  Destructor Destroy;override;
  Constructor CreateAs(P:TPropValue);
  Function AsFloat:Double;
  Function AsInteger:Integer;
  Function AsString:AnsiString;
  Constructor Load(Buf: TBufStream);override;
  Procedure Store(Buf: TBufStream);override;
  Procedure SetValue(Value_:AnsiString);
  Property Value:AnsiString read fValue write SetValue;
  Function isInteger:boolean;
  Function isFloat:boolean;
 end;

 TProperty = class (TTwgObject)
  PropName : AnsiString;
  PropValue : TPropValue; // данные простого типа
  Index:Integer;
  Constructor Create(pName:AnsiString;pValue:AnsiString;pIndex:Integer=-1);
  Constructor CreateAs(Prop:TProperty);
   Constructor Load(Buf: TBufStream);override;
   Procedure Store(Buf: TBufStream);override;
  Destructor Destroy;override;
 end;

 TProperties = class (TTwgObject)
 private
   function GetPropIndex(Index: Integer): TProperty;
   function GetPropValue(PropName: AnsiString): TPropValue;
   procedure SetPropValue(PropName: AnsiString; const Value: TPropValue);
    function GetCount: Integer;
  public
  Properties:PCollection;
  Constructor Create;
  Constructor CreateAs(Prop:TProperties);
   Constructor Load(Buf: TBufStream);override;
   Procedure Store(Buf: TBufStream);override;
  Destructor Destroy;override;
 //
  Procedure AddProperty(pName:AnsiString;pValue:AnsiString;pIndex:Integer=-1);
  Procedure AddPropertyPost(pName:AnsiString;pValue:AnsiString;pIndex:Integer=-1);
  Procedure InsertProperty(Index:Integer;pName:AnsiString;pValue:AnsiString);overload;
  Procedure InsertProperty(Index:AnsiString;pName:AnsiString;pValue:AnsiString);overload;
  Procedure DeleteProperty(pName:AnsiString);
  Property PropValue[PropName:AnsiString]:TPropValue read GetPropValue write SetPropValue;
  Property PropIndex[Index:Integer]:TProperty read GetPropIndex;default;
  Property Count:Integer read GetCount;
  Function GetIntValueDef(propName:AnsiString;defValue:Integer):Integer;
  Function GetFloatValueDef(propName:AnsiString;defValue:Double):Double;
  Function GetStringValueDef(propName:AnsiString;defValue:AnsiString):AnsiString;
  Procedure RenameProperty(oldName,newName:AnsiString);
 //
  Procedure SetList(St:TStrings);
  Procedure GetList(St:TStrings);
 //
  Procedure Up(Name:AnsiString);
  Procedure Down(Name:AnsiString);
 //
  Function IndexOf(pName:AnsiString):Integer;
 end;

implementation uses newProcs, newConsts, Writer;

{ TPropValue }

constructor TPropValue.Create(Value_: AnsiString);
begin
 Value:=Value_;
end;

constructor TPropValue.CreateAs(P: TPropValue);
begin
 Value:=P.Value;
 If Value = binaryValue then begin
  Binary:=TImage.Create(nil);
 // Binary.Picture.Bitmap.Assign(P.Binary.Picture.Bitmap);  fmx
 end;
end;

function TPropValue.AsFloat: Double;
begin
 Result:=GStrToFloat(Value);
end;

function TPropValue.AsInteger: Integer;
begin
 Result:=StrToInt(Value);
end;

function TPropValue.AsString: AnsiString;
begin
 Result:=Value;
end;

constructor TPropValue.Load(Buf: TBufStream);
var B:Boolean;
begin
 Buf.Read(varType,SizeOf(varType));
 Value:=Buf.ReadString;
 If (Value = BinaryValue) then begin
  Buf.Read(B,1);
  If B then Binary:=TImage(Buf.Stream.ReadComponent(Binary));
 end;
// Writeln('Value=',Value);
end;

procedure TPropValue.Store(Buf: TBufStream);
var B:Boolean;
begin
 Buf.Write(varType,SizeOf(varType));
 Buf.WriteString(fValue);
 If Value = BinaryValue then begin
  B:=Binary<>nil;
  Buf.Write(B,1);
  If B then Buf.Stream.WriteComponent(Binary);
 end;
end;

destructor TPropValue.Destroy;
begin
 If Value = binaryValue then Binary.Free;
end;

procedure TPropValue.SetValue(Value_: AnsiString);
var S: string;
    Code: Integer;
begin
{
exceptValue:=0;
fValue:=Value_;
If fValue = byLayer then begin
 exceptValue:=3;
end else
If Length(fValue)>0 then If (fValue[1] in ['0'..'9']) then begin
  Val(fValue,intValue,Code);
  If Code > 0 then begin
   exceptValue:=1;
   Val(fValue,floatValue,Code);
   If Code > 0 then
    exceptValue := exceptValue or 2;
  end;
end else exceptValue:=3;
exit;   }
 exceptValue:=0;
 fValue:=Value_;
 If fValue = byLayer then begin
  exceptValue:=3;
 end else
 If Length(fValue)>0 then If (fValue[1] in ['0'..'9', '+', '-']) then begin
  S := string(fValue);
  if not TryStrToInt(S, intValue) then
    exceptValue := exceptValue or 1;

  if (FormatSettings.DecimalSeparator = ',') and (Pos('.', S) <> 0) then
    S[Pos('.', S)] := ','
  else if (FormatSettings.DecimalSeparator = '.') and (Pos(',', S) <> 0) then
    S[Pos(',', S)] := '.';

  if not TryStrToFloat(S, floatValue, FormatSettings) then
    exceptValue := exceptValue or 2;
 end else exceptValue:=3;
end;

function TPropValue.isFloat: boolean;
begin
 Result:=(exceptValue and 2) <> 2;
end;

function TPropValue.isInteger: boolean;
begin
 Result:=exceptValue and 1 <> 1;
end;

{ TProperty }

constructor TProperty.Create(pName: AnsiString; pValue: AnsiString;pIndex:Integer = -1);
begin
 PropName:=pName;
 PropValue:=TPropValue.Create(pValue);
 Index:=pIndex;
end;

constructor TProperty.CreateAs(Prop: TProperty);
begin
 PropName:=Prop.PropName;
 PropValue:=TPropValue.CreateAs(Prop.PropValue);
end;

destructor TProperty.Destroy;
begin
 PropValue.Free;
end;

constructor TProperty.Load(Buf: TBufStream);
var D:Double;I:Integer;S:AnsiString;VarType:Integer;
begin
 PropName:=Buf.ReadString();
 PropValue:=TPropValue(Buf.Get);
end;

procedure TProperty.Store(Buf: TBufStream);
var VarType:Integer;D:Double;S:AnsiString;I:Integer;
begin
 Buf.WriteString(PropName);
 Buf.Put(PropValue);
end;

{ TProperties }

procedure TProperties.AddProperty(pName: AnsiString; pValue: AnsiString;pIndex:Integer=-1);
var V:AnsiString;Found:Boolean;
begin
// If pName = 'Угол' then
//  Writeln('angle');
 If  (PropValue[pName] = nil) then begin
//  If pIndex<>-1 then Properties.Atinsert(pIndex,TProperty.Create(pName,pValue,pIndex)) else
  Properties.Insert(TProperty.Create(pName,pValue,pIndex));
 end else begin
  PropValue[pName].Value:=pValue;
 end;
end;

procedure TProperties.InsertProperty(Index: Integer; pName,
  pValue: AnsiString);
begin
 If  (PropValue[pName] = nil) then begin
  Properties.AtInsert(Index,TProperty.Create(pName,pValue));
 end else
  PropValue[pName].Value:=pValue;
end;

procedure TProperties.InsertProperty(Index, pName, pValue: AnsiString);
var N:Integer;
Function IndexByName:Integer;
var I:Integer;
begin
 Result:=-1;
 For I:=0 to Properties.Count-1 do
  If TProperty(Properties[I]).propName = Index then Result:=I;
end;
begin
 If  (PropValue[pName] = nil) then begin
  N:=IndexByName;
  If N<>-1 then Properties.AtInsert(N+1,TProperty.Create(pName,pValue)) else
                AddProperty(pName,pValue);
 end else
  PropValue[pName].Value:=pValue;
end;

constructor TProperties.Create;
begin
 Properties:=PCollection.Create(1);
end;

constructor TProperties.CreateAs(Prop: TProperties);
var I:Integer;
begin
 Properties:=PCollection.Create(1);
 For I:=0 to Prop.Properties.Count-1 do Properties.Insert(TProperty.CreateAs(Prop.Properties[I]))
end;

destructor TProperties.Destroy;
begin
 Properties.Free;
end;

constructor TProperties.Load(Buf: TBufStream);
begin
 Properties:=PCollection(Buf.Get);
end;


procedure TProperties.Store(Buf: TBufStream);
begin
 Buf.Put(Properties);
end;

function TProperties.GetPropIndex(Index: Integer): TProperty;
begin
 Result:=Properties[Index];
end;

procedure TProperties.GetList(St: TStrings);
var I,J:Integer;S:TStrings;
begin
 J:=0;
 For I:=0 to St.Count-1 do begin
  S:=TStringList.Create;S.Text:=MakeStringOne(St[I],'=');
  If S.Count=2 then begin
   If J=0 then begin Properties.FreeAll;J:=1;end;
   Properties.Insert(TProperty.Create(S[0],S[1]));
  end;
  S.Free;
 // end;
 end;
end;

procedure TProperties.SetList(St: TStrings);
var S:TStrings;I:Integer;Res:AnsiString;
begin
 For I:=0 to Properties.Count-1 do begin
  If PropIndex[I].PropValue.Value = propNULL then Res:='' else Res:=PropIndex[I].PropValue.Value;
  If I<>0 then St.Add(PropIndex[I].PropName+'='+Res) else St[0]:=(PropIndex[I].PropName+'='+Res);
 end;
end;

function TProperties.GetPropValue(PropName: AnsiString): TPropValue;
var I:Integer; S1, S2:AnsiString; B: Boolean;
begin
 Result:=nil;
 For I:=0 to Properties.Count-1 do begin
  S1 := PropName; S2:= TProperty(Properties[I]).PropName;
  B := S1 = S2;
//  WriteIn(['    FindProp=',TProperty(Properties[I]).PropName, PropName, TProperty(Properties[I]).PropName = PropName]);
  If TProperty(Properties[I]).PropName = PropName then
   Result:=TProperty(Properties[I]).PropValue;
 end;
end;

procedure TProperties.SetPropValue(PropName: AnsiString; const Value: TPropValue);
var I:Integer;
begin
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = PropName then
  TProperty(Properties[I]).PropValue:=Value;
end;

procedure TProperties.DeleteProperty(pName: AnsiString);
var I:Integer;
begin
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = pName then begin
  Properties.AtDelete(I);
  exit;
 end;
end;

function TProperties.GetCount: Integer;
begin
 Result:=Properties.Count;
end;


function TProperties.GetFloatValueDef(propName: AnsiString; defValue: Double): Double;
var Value:TPropValue;
begin
 Value:=PropValue[propName];
 If Value = nil then
  Result:=defValue else
   If Value.isFloat then
    Result:=Value.floatValue else
     Result:=defValue;
end;

function TProperties.GetIntValueDef(propName: AnsiString; defValue: Integer): Integer;
var Value:TPropValue;
begin
 Value:=PropValue[propName];
 If Value = nil then Result:=defValue else If Value.isInteger then Result:=Value.intValue else Result:=defValue;
end;

function TProperties.GetStringValueDef(propName, defValue: AnsiString): AnsiString;
var Value:TPropValue;
begin
 Value:=PropValue[propName];
 If Value = nil then Result:=defValue else If (Value.fValue = byLayer) or (Value.fValue = byNone) then Result:=defValue else Result:=Value.fValue;
end;

procedure TProperties.Down(Name: AnsiString);
var I,Index:Integer;P1,P2:Pointer;
begin
 Index:=-1;
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = Name then Index:=I;
 If (Index=-1) or (Index=Properties.Count-1) then exit;
 P1:=Properties[Index];
 P2:=Properties[Index+1];
 Properties[Index]:=P2;
 Properties[Index+1]:=P1;
end;

procedure TProperties.Up(Name: AnsiString);
var I,Index:Integer;P1,P2:Pointer;
begin
 Index:=-1;
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = Name then Index:=I;
 If (Index=-1) or (Index=0) then exit;
 P1:=Properties[Index];
 P2:=Properties[Index-1];
 Properties[Index]:=P2;
 Properties[Index-1]:=P1;
end;

procedure TProperties.RenameProperty(oldName, newName: AnsiString);
var I:Integer;
begin
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = oldName then
  TProperty(Properties[I]).PropName:=newName;
end;

function TProperties.IndexOf(pName: AnsiString): Integer;
var I,Index:Integer;
begin
 Index:=-1;
 For I:=0 to Properties.Count-1 do If TProperty(Properties[I]).PropName = pName then Index:=I;
 Result:=Index;
end;

procedure TProperties.AddPropertyPost(pName, pValue: AnsiString;pIndex: Integer);
var Index:Integer;
begin
 Index:=IndexOf('Характеристика движения');
 If Index = -1 then AddProperty(pName,pValue,pIndex) else begin
  InsertProperty(Index,pName,pValue);
 end;
end;

initialization
end.
