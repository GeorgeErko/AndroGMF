unit ogcProperties;

interface

uses Classes, SysUtils, System.JSON, ogcBasic;

// Семантика объектов (GeoJSON "properties") хранится в стандартных
// объектах System.JSON: TogsProperties = TJSONObject (см. ogcBasic).
// Модуль заменяет прежнюю иерархию TogsPropValue/TogsPropObject/... и ogcJSON:
// разбор и запись выполняет System.JSON, а доступ к дереву значений
// в стиле прежнего API реализован классовыми помощниками.

const
  ss32: String = #32#32#32#32;
  ss1310: String = #13#10;

type
  TpropType = (ptString, ptNumber, ptBool, ptNull, ptArray, ptObject);
  TvarType  = (vtString, vtNumber, vtInt, vtBool, vtNull, vtEmpty);
  TjsonGeometryType = (gtnotDefined, gtPoint, gtLine, gtMultiPoint, gtLineString,
                       gtMultiLineString, gtPolygon, gtMultiPolygon);

  { TogsJSONHelper - доступ к значению и дочерним элементам любого узла JSON }

  TogsJSONHelper = class helper for TJSONValue
  private
   function GetAsString: String;
   function GetAsFloat: Double;
   function GetAsInt: Integer;
   function GetAsBoolean: Boolean;
   function GetItemCount: Integer;
   function GetItem(Index: Integer): TJSONValue;
   function GetItemByName(const ItemName: String): TJSONValue;
  public
   function TypeOf: TpropType;
  // атомарные значения (для объекта/массива AsString возвращает JSON-текст)
   property AsString: String read GetAsString;
   property AsFloat: Double read GetAsFloat;
   property AsInt: Integer read GetAsInt;
   property AsBoolean: Boolean read GetAsBoolean;
  // дочерние элементы массива/объекта (для объекта - значения пар)
   property ItemCount: Integer read GetItemCount;
   property Item[Index: Integer]: TJSONValue read GetItem;
   property ItemByName[const ItemName: String]: TJSONValue read GetItemByName;
  // поиск по пути имен: Obj.FindByNames(['geometry', 'coordinates'], S)
  // nil - если элемент не найден, notFoundStr - путь до ненайденного элемента
   function FindByNames(const Params: array of String; out notFoundStr: String): TJSONValue;
  // структурное сравнение со схемой: все имена схемы присутствуют
  // и типы значений совпадают; FailPath - путь первого несовпадения
   function CompareWith(Schema: TJSONValue; out FailPath: String): Boolean;
  // текст JSON: Pretty - с отступами
   function AsText(Pretty: Boolean = False): String;
  end;

  { TogsJSONObjectHelper - изменение пар объекта }

  TogsJSONObjectHelper = class helper(TogsJSONHelper) for TJSONObject
  public
   function NameOf(Index: Integer): String;
  // заменяет значение пары Name (пара создается, если ее нет)
   procedure SetItemValue(const Name: String; Value: TJSONValue);
   procedure SetString(const Name, Value: String);
   procedure SetFloat(const Name: String; Value: Double; Decimal: Integer = -1);
   procedure SetInt(const Name: String; Value: Int64);
   procedure SetBool(const Name: String; Value: Boolean);
   procedure DeleteItem(const Name: String);
   procedure ClearItems;
  // замещает содержимое объекта разобранной строкой/файлом
   function LoadFromString(const jsonStr: String): Boolean;
   function LoadFromFile(const FileName: String): Boolean;
   procedure SaveToFile(const FileName: String; Pretty: Boolean = True);
  end;

// разбор строки/файла JSON в объект: nil, если текст не является объектом JSON
function JSONParseObject(const jsonStr: String): TJSONObject;
function JSONLoadFromFile(const FileName: String): TJSONObject;
function JSONParseValue(const jsonStr: String): TJSONValue;
procedure JSONSaveToFile(Value: TJSONValue; const FileName: String; Pretty: Boolean = True);
// копия объекта (nil -> nil)
function JSONCopy(Obj: TJSONObject): TJSONObject;
// число с ограничением количества знаков после запятой (Decimal = -1 - без округления)
function JSONNumber(Value: Double; Decimal: Integer = -1): TJSONNumber;
//
function GeometryType(typeName: String): TjsonGeometryType;
// тип данных из строки
function TypeOfString(S: String): TvarType;
function DeleteQuotMarks(S: String): String;
//
function AssignedProps(Prop: TJSONValue): Boolean;

implementation uses System.IOUtils, System.Math;

function JSONParseValue(const jsonStr: String): TJSONValue;
begin
 Result := TJSONObject.ParseJSONValue(jsonStr, True, False);
end;

function JSONParseObject(const jsonStr: String): TJSONObject;
var Value: TJSONValue;
begin
 Result := nil;
 Value := JSONParseValue(jsonStr);
 if Value is TJSONObject then Result := TJSONObject(Value) else Value.Free;
end;

function JSONLoadFromFile(const FileName: String): TJSONObject;
begin
 Result := nil;
 if not FileExists(FileName) then exit;
 Result := JSONParseObject(TFile.ReadAllText(FileName, TEncoding.UTF8));
end;

procedure JSONSaveToFile(Value: TJSONValue; const FileName: String; Pretty: Boolean);
begin
 if Value = nil then exit;
 TFile.WriteAllText(FileName, Value.AsText(Pretty), TEncoding.UTF8);
end;

function JSONCopy(Obj: TJSONObject): TJSONObject;
begin
 if Obj = nil then Result := nil else Result := TJSONObject(Obj.Clone);
end;

function JSONNumber(Value: Double; Decimal: Integer): TJSONNumber;
begin
 if Decimal >= 0 then Value := RoundTo(Value, -Decimal);
 Result := TJSONNumber.Create(Value);
end;

function GeometryType(typeName: String): TjsonGeometryType;
begin
 if CompareText(typeName,'Point') = 0 then Result := gtPoint else
 if CompareText(typeName,'MultiPoint') = 0 then Result := gtMultiPoint else
 if CompareText(typeName,'Line') = 0 then Result := gtLine else
 if CompareText(typeName,'LineString') = 0 then Result := gtLineString else
 if CompareText(typeName,'MultiLineString') = 0 then Result := gtMultiLineString else
 if CompareText(typeName,'Polygon') = 0 then Result := gtPolygon else
 if CompareText(typeName,'MultiPolygon') = 0 then Result := gtMultiPolygon else
    Result := gtNotDefined;
end;

function TypeOfString(S: String): TvarType;
var S1 : String;
    Int: Int64;
    Float: Double;
begin
 Result := vtEmpty;
 S1 := AnsiLowerCase(Trim(S));
 if S1 = '' then exit;
 if S1 = 'null' then Result := vtNull else
 if (S1 = 'true') or (S1 = 'false') then Result := vtBool else
 if S1[1] = '"' then Result := vtString else
 if TryStrToInt64(S1, Int) then Result := vtInt else
 if TryStrToFloat(S1, Float, TFormatSettings.Invariant) then Result := vtNumber else
  Result := vtString;
end;

function DeleteQuotMarks(S: String): String;
begin
 S := Trim(S);
 Result := S;
 if Length(S) = 0 then exit;
 if S[1] = '"' then Delete(S, 1, 1);
 if (Length(S) > 0) and (S[Length(S)] = '"') then Delete(S, Length(S), 1);
 Result := S;
end;

function AssignedProps(Prop: TJSONValue): Boolean;
begin
 Result := Assigned(Prop) and not (Prop is TJSONNull);
end;

{ TogsJSONHelper }

function TogsJSONHelper.TypeOf: TpropType;
begin
 if Self is TJSONNumber then Result := ptNumber else
 if Self is TJSONString then Result := ptString else
 if Self is TJSONBool then Result := ptBool else
 if Self is TJSONArray then Result := ptArray else
 if Self is TJSONObject then Result := ptObject else
  Result := ptNull;
end;

function TogsJSONHelper.GetAsString: String;
begin
 if Self is TJSONString then Result := TJSONString(Self).Value else
 if Self is TJSONBool then begin
  if TJSONBool(Self).AsBoolean then Result := 'true' else Result := 'false';
 end else
 if Self is TJSONNull then Result := 'null' else
  Result := ToJSON;
end;

function TogsJSONHelper.GetAsFloat: Double;
var S: String;
begin
 Result := 0;
 if Self is TJSONNumber then Result := TJSONNumber(Self).AsDouble else
 if Self is TJSONString then begin
  S := StringReplace(Trim(TJSONString(Self).Value), ',', '.', [rfReplaceAll]);
  if not TryStrToFloat(S, Result, TFormatSettings.Invariant) then Result := 0;
 end else
 if Self is TJSONBool then Result := Ord(TJSONBool(Self).AsBoolean);
end;

function TogsJSONHelper.GetAsInt: Integer;
begin
 if Self is TJSONNumber then Result := Round(TJSONNumber(Self).AsDouble) else
  Result := Round(GetAsFloat);
end;

function TogsJSONHelper.GetAsBoolean: Boolean;
begin
 if Self is TJSONBool then Result := TJSONBool(Self).AsBoolean else
 if Self is TJSONNumber then Result := TJSONNumber(Self).AsDouble <> 0 else
 if Self is TJSONString then Result := SameText(TJSONString(Self).Value, 'true') else
  Result := False;
end;

function TogsJSONHelper.GetItemCount: Integer;
begin
 if Self is TJSONArray then Result := TJSONArray(Self).Count else
 if Self is TJSONObject then Result := TJSONObject(Self).Count else
  Result := 0;
end;

function TogsJSONHelper.GetItem(Index: Integer): TJSONValue;
begin
 Result := nil;
 if (Index < 0) or (Index >= GetItemCount) then exit;
 if Self is TJSONArray then Result := TJSONArray(Self).Items[Index] else
 if Self is TJSONObject then Result := TJSONObject(Self).Pairs[Index].JsonValue;
end;

function TogsJSONHelper.GetItemByName(const ItemName: String): TJSONValue;
var I: Integer;
begin
 Result := nil;
 if not (Self is TJSONObject) then exit;
// имена сравниваются без учета регистра, как в прежнем TogsPropObject
 for I := 0 to TJSONObject(Self).Count - 1 do
  if SameText(TJSONObject(Self).Pairs[I].JsonString.Value, ItemName) then begin
   Result := TJSONObject(Self).Pairs[I].JsonValue;
   exit;
  end;
end;

function TogsJSONHelper.FindByNames(const Params: array of String; out notFoundStr: String): TJSONValue;
var I: Integer;
begin
 Result := Self;
 notFoundStr := '';
 for I := Low(Params) to High(Params) do begin
  if notFoundStr <> '' then notFoundStr := notFoundStr + '->' + Params[I] else notFoundStr := Params[I];
  Result := Result.ItemByName[Params[I]];
  if Result = nil then exit;
 end;
 notFoundStr := '';
end;

function TogsJSONHelper.CompareWith(Schema: TJSONValue; out FailPath: String): Boolean;
function CompareNode(Own, Sch: TJSONValue; const Path: String): Boolean;
var I: Integer;
    Name: String;
begin
 Result := False;
 if Own = nil then begin FailPath := Path; exit; end;
// null в схеме - значение любого типа
 if Sch is TJSONNull then exit(True);
 if Own.TypeOf <> Sch.TypeOf then begin FailPath := Path; exit; end;
 if Sch is TJSONObject then
  for I := 0 to TJSONObject(Sch).Count - 1 do begin
   Name := TJSONObject(Sch).Pairs[I].JsonString.Value;
   if not CompareNode(Own.ItemByName[Name], TJSONObject(Sch).Pairs[I].JsonValue, Path + '->' + Name) then exit;
  end
 else
// массив схемы: первый элемент - образец для всех элементов массива
 if (Sch is TJSONArray) and (TJSONArray(Sch).Count > 0) then
  for I := 0 to TJSONArray(Own).Count - 1 do
   if not CompareNode(TJSONArray(Own).Items[I], TJSONArray(Sch).Items[0], Path + '[' + IntToStr(I) + ']') then exit;
 Result := True;
end;
begin
 FailPath := '';
 if Schema = nil then exit(True);
 Result := CompareNode(Self, Schema, '');
end;

function TogsJSONHelper.AsText(Pretty: Boolean): String;
begin
 if Pretty then Result := Format(2) else Result := ToJSON;
end;

{ TogsJSONObjectHelper }

function TogsJSONObjectHelper.NameOf(Index: Integer): String;
begin
 Result := Pairs[Index].JsonString.Value;
end;

procedure TogsJSONObjectHelper.SetItemValue(const Name: String; Value: TJSONValue);
begin
 DeleteItem(Name);
 AddPair(Name, Value);
end;

procedure TogsJSONObjectHelper.SetString(const Name, Value: String);
begin
 SetItemValue(Name, TJSONString.Create(Value));
end;

procedure TogsJSONObjectHelper.SetFloat(const Name: String; Value: Double; Decimal: Integer);
begin
 SetItemValue(Name, JSONNumber(Value, Decimal));
end;

procedure TogsJSONObjectHelper.SetInt(const Name: String; Value: Int64);
begin
 SetItemValue(Name, TJSONNumber.Create(Value));
end;

procedure TogsJSONObjectHelper.SetBool(const Name: String; Value: Boolean);
begin
 SetItemValue(Name, TJSONBool.Create(Value));
end;

procedure TogsJSONObjectHelper.DeleteItem(const Name: String);
var Pair: TJSONPair;
begin
 Pair := RemovePair(Name);
 Pair.Free;
end;

procedure TogsJSONObjectHelper.ClearItems;
begin
 while Count > 0 do RemovePair(Pairs[Count - 1].JsonString.Value).Free;
end;

function TogsJSONObjectHelper.LoadFromString(const jsonStr: String): Boolean;
var Obj: TJSONObject;
    I: Integer;
begin
 Obj := JSONParseObject(jsonStr);
 Result := Obj <> nil;
 if not Result then exit;
 try
  ClearItems;
  for I := 0 to Obj.Count - 1 do AddPair(TJSONPair(Obj.Pairs[I].Clone));
 finally
  Obj.Free;
 end;
end;

function TogsJSONObjectHelper.LoadFromFile(const FileName: String): Boolean;
begin
 Result := FileExists(FileName) and LoadFromString(TFile.ReadAllText(FileName, TEncoding.UTF8));
end;

procedure TogsJSONObjectHelper.SaveToFile(const FileName: String; Pretty: Boolean);
begin
 JSONSaveToFile(Self, FileName, Pretty);
end;

end.
