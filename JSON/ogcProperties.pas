unit ogcProperties;


interface

uses Classes, SysUtils, StrUtils, ogcBasic;

const GID: Integer = 0;
    // значения nil (не инициализирован TogsPropValue) и null для переменных типа объект/массив
      nilValue   = '{30B65C70-EE6E-4009-9A98-A5102793DC53}';
      nullValue  = '{1D9E5D3E-0FEA-466A-BAA7-DC7599B9CDC3}';
      ss32: String = ''; //#32#32#32#32;
      ss1310: String = #13#10;

type
  TpropType = (ptString, ptNumber, ptBool, ptNull, ptArray, ptObject);
  TvarType  = (vtString, vtNumber, vtInt, vtBool, vtNull, vtEmpty);
  TjsonGeometryType = (gtnotDefined, gtPoint, gtLine, gtMultiPoint, gtLineString,
                       gtMultiLineString, gtPolygon, gtMultiPolygon);
  TpropState = (psCollapsed, psExpanded);

  TogsPropValue = class;
  TogsPropString = class;
  TogsPropArray = class;
  TogsPropObject = class;
  TogsProperty = class;
                                                         
  { TogsPropValue - абстрактный класс для работы со значениями свойств }

  TogsPropValue = class(TogsProperties)
  private
   fParent: TogsBasic; // родительский элемнт: TogsPropValue, TogsGEometry
  // Index : Integer; // индекс при чтении файла json в объекте/массиве
  //
   procedure SetParent(AValue: TogsBasic); virtual;
   procedure SetPropValue(AValue: TogsPropValue); virtual;
  //
   function GetItem(Index: Integer): TogsPropValue; virtual;
   function GetPropValue: TogsPropValue; virtual;
  //
   function GetPropName: String; virtual;
   procedure SetPropName(AValue: String); virtual;
   //
   function GetItemByName(ItemName: String): TogsPropValue; virtual;
  protected
  //
   function GetStringValue: String; override;
   function GetBoolValue: Boolean; virtual;
   function GetFloatValue: Double; virtual;
   function GetIntValue: Integer; virtual;
  //
   procedure SetStringValue(AValue: String); override;
   procedure SetFloatValue(AValue: Double); virtual;
   procedure SetIntValue(AValue: Integer); virtual;
   procedure SetBoolValue(AValue: Boolean); virtual;
  public
   Level: SmallInt; // уровень в иерархии объектов
   State: TPropState;
   constructor Create(Parent_: TogsPropValue; Level_, Index_: SmallInt);
   constructor CreateAs(ogsObject: TogsBasic); override;
  // для отладки constructor CreateAs(ogsObject: TogsProperties); overload;
   function Assign(ogsObject: TogsBasic): boolean; override;
   function TypeOf: TPropType; virtual; abstract;
   property Parent: TogsBasic read fParent write SetParent;
  //
   property AsString: String read GetStringValue write SetStringValue;
   property AsFloat: Double read GetFloatValue write SetFloatValue;
   property AsInt: Integer read GetIntValue write SetIntValue;
   property AsBoolean: Boolean read GetBoolValue write SetBoolValue;
  //
   function ValidateEntry(AValue: String): boolean; virtual;
  //
   function ToString : AnsiString; override;
   function FromString(jsonStr: AnsiString): Integer; virtual; abstract;
   function FromStream(jsonStream: TogsStream): Integer; virtual; abstract;
  //
   procedure ViewTree(); virtual;
   procedure Update(Level: Integer); virtual;
   function Space: String; virtual;
  //
   procedure Sort(SortProc: TListSortCompare); virtual;
   // доступ к propValue: TogsPropValue
   property propName : String read GetPropName write SetPropName;
   property propValue: TogsPropValue read GetPropValue write SetPropValue;
   //
   function Count: Integer; virtual;
   function AddItem(Value: TogsPropValue): TogsPropValue; virtual; abstract;
   property Item[Index: Integer]: TogsPropValue read GetItem;
  //
   property ItemByName[Name: String]: TogsPropValue read GetItemByName; default;
   function FindByNames(Params: Array of String; out notFoundStr: String): TogsPropValue;
   function CompareWith(Schema: TogsPropValue): TogsPropValue;
  end;

  { TogsProperty - свойство с именем и значением типа : атомарное, массив, объект Pr}

  TogsProperty = class(TogsPropValue)
  private
   fpropName: String;
   fpropValue: TogsPropValue;
   function GetItem(Index: Integer): TogsPropValue; override;
   function GetPropValue: TogsPropValue; override;
   procedure SetPropValue(AValue: TogsPropValue); override;
   function GetStringValue: String; override;
   procedure SetStringValue(AValue: String); override;
   function GetPropName: String; override;
   procedure SetPropName(AValue: String); override;
   //
   function GetItemByName(ItemName: String): TogsPropValue; override;
  public
   constructor Create(propName_: String; propValue_: TogsPropValue); overload;
   constructor Create(propName_: String; propValue_: String); overload;
   destructor Destroy;override;
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function TypeOf: TPropType; override;
   function AddItem(Value: TogsPropValue): TogsPropValue; override;
   procedure ViewTree(); override;
  //
   property propValue: TogsPropValue read GetPropValue write SetPropValue;
   property Item[Index: Integer]: TogsPropValue read GetItem;
  //
   function ToString : AnsiString; override;
  //
   procedure Sort(SortProc: TListSortCompare); override;
  end;

  { TogspropString - строковое значение свойства }

  TogsPropString = class(TogsPropValue)
  private
   fValue: String;
  protected
   function GetStringValue: String; override;
   function GetFloatValue: Double; override;
   function GetIntValue: Integer; override;
   function GetBoolValue: Boolean; override;
   procedure SetStringValue(AValue: String); override;
   procedure SetFloatValue(AValue: Double); override;
   procedure SetIntValue(AValue: Integer); override;
   procedure SetBoolValue(AValue: Boolean); override;
  public
   constructor Create(Value_: String);
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function TypeOf: TPropType; override;
  //
   function ToString: AnsiString; override;
  end;

  { TogsPropFloat }

  TogsPropFloat = class(TogsPropValue)
  private
   fValue : Double;
   fDecimal: Byte;
  protected
   function GetStringValue: String; override;
   function GetFloatValue: Double; override;
   function GetIntValue: Integer; override;
   function GetBoolValue: Boolean; override;
   procedure SetStringValue(AValue: String); override;
   procedure SetFloatValue(AValue: Double); override;
   procedure SetIntValue(AValue: Integer); override;
   procedure SetBoolValue(AValue: Boolean); override;
  public
   constructor Create(Value_: Double; Decimal_: ShortInt=-1);
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function TypeOf: TPropType; override;
  //
   function ValidateEntry(AValue: String): boolean; override;
  //
   function GetDecimal(Value: Double): Byte;
   function ToString : AnsiString; override;
  end;

  { TogsPropBool }

  TogsPropBool = class(TogsPropValue)
  private
   fValue : Boolean;
  protected
   function GetStringValue: String; override;
   function GetFloatValue: Double; override;
   function GetIntValue: Integer; override;
   function GetBoolValue: Boolean; override;
   procedure SetStringValue(AValue: String); override;
   procedure SetFloatValue(AValue: Double); override;
   procedure SetIntValue(AValue: Integer); override;
   procedure SetBoolValue(AValue: Boolean); override;
  public
   constructor Create(Value_: Boolean);
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function TypeOf: TPropType; override;
  //
   function ValidateEntry(AValue: String): boolean; override;
  //
   function ToString : AnsiString; override;
  end;

  { TogsPropNull }

  TogsPropNull = class(TogsPropValue)
  public
   constructor Create;
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function TypeOf: TPropType; override;
  //
   function ValidateEntry(AValue: String): boolean; override;
  //
   function ToString : AnsiString; override;
  end;

  { TogsPropArray - массив значений TogsPropValue}

  TogsPropArray = class(TogsPropValue)
  private
   Items: TogsCollection;
   function GetItem(Index: Integer): TogsPropValue; override;
   //
   function GetItemByName(ItemName: String): TogsPropValue; override;
  public
   constructor Create;
   destructor Destroy; override;
   constructor CreateAs(ogsObject: TogsBasic); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   function TypeOf: TPropType; override;
   function AddItem(Value: TogsPropValue): TogsPropValue; override;
  //
   function Count: Integer; override;
   function ToString : AnsiString; override;
   function FromString(jsonStr: AnsiString): Integer; override;
  //
   procedure Sort(SortProc: TListSortCompare); override;
  //
   procedure Update(Level: Integer); override;
  end;

  TogsPropArrayItem = class(TogsPropArray)
  end;

  { TogspropObject - массив значений TogsPropValue }

  TogsPropObject = class(TogsPropArray)
  private
   function GetItem(Index: Integer): TogsPropValue; override;
  public
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor CreateFrom(jsonStr: AnsiString); overload;
   constructor CreateFrom(jsonStream: TogsStream); overload;
   function TypeOf: TPropType; override;
   function AddItem(Value: TogsPropValue): TogsPropValue; override;
  // json
   function ToString : AnsiString; override;
   function FromString(jsonStr: AnsiString): Integer; override;
   function FromStream(jsonStream: TogsStream): Integer; override;
  end;

var nilObject, nullObject : TogsPropValue;

function GeometryType(typeName: String): TjsonGeometryType;
// тип данных из строки
function TypeOfString(S: AnsiString): TvarType;
function DeleteQuotMarks(S: AnsiString): AnsiString;
// проверка типов
function CheckogsArrayType(P: TogsBasic): Boolean;
function CheckogsObjectType(P: TogsBasic): Boolean;

implementation uses ogcJSON, Dialogs;

function GeometryType(typeName: String): TjsonGeometryType;
begin
 If CompareText(typeName,'Point') = 0 then Result := gtPoint else
 If CompareText(typeName,'Line') = 0 then Result := gtLine else
 If CompareText(typeName,'LineString') = 0 then Result := gtLineString else
 If CompareText(typeName,'MultiLineString') = 0 then Result := gtMultiLineString else
 If CompareText(typeName,'Polygon') = 0 then Result := gtPolygon else
 If CompareText(typeName,'MultiPolygon') = 0 then Result := gtMultiPolygon else
    Result := gtNotDefined;
end;

function TypeOfString(S: String): TvarType;
var Next: Boolean;
    S1 : String;
    Int, Code: Integer;
    Float: Double;
begin
 Result := vtEmpty; Next:= False;
 S1 := ansiLowerCase(S);
 If S1 = '' then exit else
  If S1 = 'null'  then Result := vtNull else
   If (S1 = 'true') or (S1 = 'false') then Result := vtBool else begin
    If (S1[1] = '"') then Result := vtString else begin
   //   try StrToInt(S) except Next := True; end;
       Val(S, Int, Code); If Code > 0 then Next := True;
       If not Next then begin Result := vtInt; exit; end else begin
        Next := False;
   //     try StrToFloat(S) except Next := True; end;
        Val(S, Float, Code); If Code > 0 then Next := True;
        If not Next then begin Result := vtNumber; exit end;
       end;
    end;
   end;
end;

function DeleteQuotMarks(S: AnsiString): AnsiString;
begin
 S := Trim(S);
 Result := S;
 If Length(S)  = 0 then exit;
 If S[1] = '"' then Delete(S, 1, 1);
 If S[Length(S)] = '"' then Delete(S, Length(S), 1);
 Result := S;
end;

function CheckogsArrayType(P: TogsBasic): Boolean;
begin
 Result := (P is TogsPropValue) and (P.ClassType <> TogsPropValue);
end;

function CheckogsObjectType(P: TogsBasic): Boolean;
begin
 Result := (P is TogsProperty) or (P is TogsPropObject) or (P is TogsPropArray);
end;

{ TogsPropValue }

constructor TogsPropValue.Create(Parent_: TogsPropValue; Level_, Index_: SmallInt);
begin
 Parent := Parent_;
 Level := Level_;
// Index := Index_;
end;

constructor TogsPropValue.CreateAs(ogsObject: TogsBasic);
begin
// WriteMsg('Basic'); exit;
 fParent := TogsPropValue(ogsObject).Parent;
 Level := TogsPropValue(ogsObject).Level;
end;

function TogsPropValue.Assign(ogsObject: TogsBasic): boolean;
begin
 fParent := TogsPropValue(ogsObject).Parent;
 Level := TogsPropValue(ogsObject).Level;
// Index := ogsObject.Index;
end;

function TogsPropValue.ValidateEntry(AValue: String): boolean;
begin
 Result := True;
end;

function TogsPropValue.ToString: AnsiString;
begin
// на время отладки
 EAbstractError.Create('TogsPropValue.AsString');
end;

{constructor TogsPropValue.CreateAs(ogsObject: TogsProperties);
begin
// WriteMsg('Property'); exit;
 CreateAs(ogsObject);
end;
}
procedure TogsPropValue.SetStringValue(AValue: String);
begin
// abstract
end;

function TogsPropValue.GetItem(Index: Integer): TogsPropValue;
begin
 Result := nil;
end;

function TogsPropValue.GetPropValue: TogsPropValue;
begin
 Result := Self;
end;

procedure TogsPropValue.SetFloatValue(AValue: Double);
begin
// abstarct
end;

procedure TogsPropValue.SetIntValue(AValue: Integer);
begin
// abstract
end;

procedure TogsPropValue.SetParent(AValue: TogsBasic);
begin
 fParent := AValue;
end;

procedure TogsPropValue.SetPropValue(AValue: TogsPropValue);
begin
// abstract
end;

function TogsPropValue.Space: String;
var I: Integer;
begin
 Result := '';
 For I :=1 to Level do Result := Result + ss32;//#32#32#32#32{ + Fmt([Level])};
end;

function TogsPropValue.GetStringValue: String;
begin
 Result := '';
end;

function TogsPropValue.GetBoolValue: Boolean;
begin
 Result := False;
end;

function TogsPropValue.GetFloatValue: Double;
begin
 Result := 0;
end;

function TogsPropValue.GetIntValue: Integer;
begin
 Result := 0;
end;

procedure TogsPropValue.SetBoolValue(AValue: Boolean);
begin
// abstract
end;

function TogsPropValue.GetPropName: String;
begin
 If Self is TogsPropObject then Result := 'Object' else
 If Self is TogsPropArray then Result := 'Array' else
 Result := '';
end;

procedure TogsPropValue.SetPropName(AValue: String);
begin
// abstract
end;

function TogsPropValue.GetItemByName(ItemName: String): TogsPropValue;
begin
 Result := nilObject;
end;

function TogsPropValue.Count: Integer;
begin
 Result := 0;
end;

procedure TogsPropValue.ViewTree;
begin
// abstract
end;

procedure TogsPropValue.Update(Level: Integer);
begin
 Level := Level;
 If propValue <> Self then propValue.Update(Level + 1);
end;

procedure TogsPropValue.Sort(SortProc: TListSortCompare);
begin
// abstract
end;

function TogsPropValue.FindByNames(Params: array of String; out notFoundStr: String): TogsPropValue;
var I:Integer;
    propValue: TogsPropValue;
begin
 // сравниваем Params[] с элементами иерархии json
 Result := nilObject;
 notFoundStr := '';
 propValue := Self;
 For I := Low(Params) to High(Params) do begin
  propValue := propValue.ItemByName[Params[I]];
  if notFoundStr <> '' then notFoundStr := notFoundStr + '->' + Params[I] else
                            notFoundStr := Params[I];
  If (propValue = nilObject) then exit else begin
  // Params[I] найден -> переходим на нижний элемент иерархии
   notFoundStr := '';
   Result := propValue;
  end;
 end;
end;

function TogsPropValue.CompareWith(Schema: TogsPropValue): TogsPropValue;
var ownValue, schemaValue: TogsPropValue;
function EqualObjects: TogsPropValue;
var I : Integer;
    propValue: TogsPropValue;
begin
 Result := nilObject;
 // сравнение на наличие атрибутов в объекте
 For I := 0 to schemaValue.Count - 1 do begin
  propValue := ownValue[schemaValue.Item[I].propName];
  If not (propValue = nilObject) then exit else
 // первый объект или массив -> запоминаем индекс
  If (Result = nilObject ) and ((propValue is TogsPropArray) or
                                (propValue is TogsPropObject)) then begin
                                  Result := propValue;
                                  schemaValue := schemaValue.Item[I];
                                  exit;
                                 end;
 end;
end;
begin
 Result := nilObject;
 // сравниваем пообъектно со схемой, аналогично FindByNames +
 //                                             сравнение типов объектов в иерархи
 // если один из атрибутов на уровне не найден -> объекты неидентичны
 ownValue := Self; schemaValue := Schema;
 While True do begin
  If ownValue.ClassType <> schemaValue.ClassType then exit else
  If EqualObjects = nil then exit;
 end;
end;

{ TogsProperty }

constructor TogsProperty.Create(propName_: String; propValue_: TogsPropValue);
begin
 fpropName := propName_;
 fpropValue := propValue_;
end;

constructor TogsProperty.Create(propName_: String; propValue_: String);
var varType: TvarType;
begin
 fPropName := propName_;
 varType := TypeOfString(propValue_);
 Case varType of
  vtNumber : propValue := TogsPropFloat.Create(StrToFloat(propValue_));
  vtBool   : propValue := TogsPropBool.Create(StrToBool(propValue_));
//  vtNULL   : propValue := TogsPropNull.Create;
  else
   propValue := TogsPropString.Create(propValue_);
 end;
end;

destructor TogsProperty.Destroy;
begin
 inherited Destroy;
 If fpropValue <> nil then fpropValue.Free;
end;

constructor TogsProperty.CreateAs(ogsObject: TogsBasic);
var Obj: TogsPropArray;
begin
 inherited CreateAs(ogsObject);
 Assign(ogsObject);
end;

// перенесено из раздела методов TogsProperty. вернуть!!!

function TogsProperty.Assign(ogsObject: TogsBasic): Boolean;
var Obj: TogsPropValue;
begin
// if ogsObject is TogsProperty then raise Exception.Create();
 Obj := TogsPropValue(ogsObject);
// WriteIn(['ogsProperty.CreateAs']);
//  WriteIn(['ObjProperty.Class=',Obj.ClassName, Obj.Count,TogsProperty(ogsObject).propName]);
 fpropName := TogsProperty(ogsObject).propName;
//  WriteIn(['ObjProperty,PropValue=', Obj.propValue.ClassName,'Cnt=', Obj.propValue.Count]);
 fpropValue := TogsBasicClass(Obj.propValue.ClassType).CreateAs(Obj.propValue) as TogsPropValue;
// WriteIn(['EndCreateAsProperty=',fPropName]);
end;

constructor TogsProperty.Load(Stream: TogsStream);
begin
 Stream.ReadString(fpropName);
 fpropValue := TogsPropValue(Stream.Get);
end;

procedure TogsProperty.Store(Stream: TogsStream);
begin
 Stream.WriteString(fpropName);
 Stream.Put(fpropValue);
end;

function TogsProperty.GetItem(Index: Integer): TogsPropValue;
begin
 Result := propValue;
end;

function TogsProperty.GetPropValue: TogsPropValue;
begin
 Result := fpropValue;
end;

procedure TogsProperty.SetPropValue(AValue: TogsPropValue);
begin
 fPropValue := AValue;
end;

function TogsProperty.GetStringValue: String;
begin
 If propValue = nil then Result := nilValue else
                         Result := propValue.AsString;
end;

procedure TogsProperty.SetStringValue(AValue: String);
begin
 If propValue <> nil then propValue.SetStringValue(AValue);
end;

function TogsProperty.GetPropName: String;
begin
 Result := fPropName;
end;

procedure TogsProperty.SetPropName(AValue: String);
begin
 fpropName := AValue;
end;

function TogsProperty.GetItemByName(ItemName: String): TogsPropValue;
begin
// WriteIn([ClassName,'-> GetItemByName -> Compare',AnsiCompareStr(ItemName, propName)]);
 Result := nilObject;
 Writeln('compare=',ItemNAme,' ',propName);
 If AnsiCompareText(ItemName, propName) = 0 then
  If fpropValue <> nil then Result:= propValue;
end;

function TogsProperty.TypeOf: TPropType;
begin
 Result := propValue.TypeOf;
end;

function TogsProperty.AddItem(Value: TogsPropValue): TogsPropValue;
begin
 If propValue <> nil then propValue.Free;
 propValue := Value;
 Result := propValue;
end;

procedure TogsProperty.ViewTree;
begin
 If propValue <> nil then begin
  If propValue.TypeOf = ptString then {WriteIn([ToString])} else begin
                                       {WriteIn([ToString]); }
                                       propValue.ViewTree();
                                      end;
 end else
//  WriteIn([propName,'=nil', parent.ToString]);
end;

function TogsProperty.ToString: AnsiString;
begin
// Resilt = propName + propValue.ToString
 If propValue = nil then Result := Space + propName + ' : nil' else begin
  propValue.Level := Level;
  Result := Space + '"' + propName + '"' + ': '+ propValue.ToString;
 end;
end;

procedure TogsProperty.Sort(SortProc: TListSortCompare);
begin
 If propValue <> nil then propValue.Sort(SortProc);
end;

{ TogsPropString }

constructor TogsPropString.Create(Value_: String);
begin
 fValue := Value_;
end;

constructor TogsPropString.CreateAs(ogsObject: TogsBasic);
begin
 inherited CreateAs(ogsObject);
 Assign(ogsObject);
end;

function TogsPropString.Assign(ogsObject: TogsBasic): Boolean;
begin
 // if ogsObject is TogsProperty then raise Exception.Create();
// WriteIn(['ogsPropString.CreateAs',ogsObject.ClassName]);
 fValue := TogsPropString(ogsObject).AsString;
// WriteIn(['ogsPropStringEnd=',fValue]);
end;

constructor TogsPropString.Load(Stream: TogsStream);
begin
 Stream.ReadString(fValue);
end;

procedure TogsPropString.Store(Stream: TogsStream);
begin
 Stream.WriteString(fValue);
end;

function TogsPropString.GetStringValue: String;
begin
 Result := fValue;
end;

function TogsPropString.GetFloatValue: Double;
begin
 Result := StrToFloat(FValue);
end;

function TogsPropString.GetIntValue: Integer;
begin
 Result := StrToInt(fValue);
end;

function TogsPropString.GetBoolValue: Boolean;
begin
 Result := ansiLowerCase(fValue) = 'true';
end;

procedure TogsPropString.SetStringValue(AValue: String);
var useMarks: boolean;
begin
// временно, до типизации свойств
 If Length(fValue) >= 2 then
  useMarks := (fValue[1] = '"') and (fValue[Length(fValue)] = '"') else
  useMarks := false;
//
 fValue := AValue;
 If useMarks then fValue:= '"' + fValue + '"';
end;

procedure TogsPropString.SetFloatValue(AValue: Double);
begin
 fValue := FloatToStr(AValue);
end;

procedure TogsPropString.SetIntValue(AValue: Integer);
begin
 fValue := IntToStr(AValue);
end;

procedure TogsPropString.SetBoolValue(AValue: Boolean);
begin
 fValue := BoolToStr(AVAlue);
end;

function TogsPropString.TypeOf: TPropType;
begin
 Result := ptString;
end;

function TogsPropString.ToString: AnsiString;
begin
 Result := '"' + fValue + '"'; //}'"' + fValue + '"';
end;

{ TogsPropFloat }

constructor TogsPropFloat.Create(Value_: Double; Decimal_: ShortInt = -1);
begin
 fValue  := Value_;
 If Decimal_ = -1 then
  fDecimal := GetDecimal(Value_) else  // если 0 - целое число
  fDecimal := Decimal_;
end;

constructor TogsPropFloat.CreateAs(ogsObject: TogsBasic);
begin
 Assign(ogsObject);
end;

function TogsPropFloat.Assign(ogsObject: TogsBasic): Boolean;
begin
 If not (ogsObject is TogsPropValue) then begin
   raise Exception.Create('TogsPropFloat.CreateAs: объект невозможно присвоить ' + ogsObject.ClassName);
   exit;
 end;
 fValue := TogsPropValue(ogsObject).AsFloat;
 fDecimal := GetDecimal(fValue);
// WriteIn(['Prop.AssigFloat',fValue]);
end;

constructor TogsPropFloat.Load(Stream: TogsStream);
begin
 Stream.Read(fValue, SizeOf(fValue));
 Stream.Read(fDecimal, SizeOf(fDecimal));
end;

procedure TogsPropFloat.Store(Stream: TogsStream);
begin
 Stream.Write(fValue, SizeOf(fValue));
 Stream.Write(fDecimal, SizeOf(fDecimal));
end;

function TogsPropFloat.GetStringValue: String;
begin
 Result := FloatToStrF(fValue, ffFixed, -1, fDecimal);
end;

function TogsPropFloat.GetFloatValue: Double;
begin
 Result := fValue;
end;

function TogsPropFloat.GetIntValue: Integer;
begin
 Result := Trunc(fValue);
end;

function TogsPropFloat.GetBoolValue: Boolean;
begin
 Result := fValue <> 0;
end;

procedure TogsPropFloat.SetStringValue(AValue: String);
begin
 fValue := StrToFloat(AVAlue);
 fDecimal := GetDecimal(fValue);
end;

procedure TogsPropFloat.SetFloatValue(AValue: Double);
begin
 fValue := AVAlue;
 fDecimal := GetDecimal(AVAlue);
end;

procedure TogsPropFloat.SetIntValue(AValue: Integer);
begin
 fValue := AVAlue;
 fDecimal := 0;
end;

procedure TogsPropFloat.SetBoolValue(AValue: Boolean);
begin
 fValue := ord(AValue);
end;


function TogsPropFloat.TypeOf: TPropType;
begin
 Result := ptNumber;
end;

function TogsPropFloat.ValidateEntry(AValue: String): boolean;
begin
 Result := TypeOfString(AValue) = vtNumber;
end;

function TogsPropFloat.GetDecimal(Value: Double): Byte;
var I: Integer;
    S: String;
begin
 S := FloatToStr(Value);
 If Pos('.', S)  = 0 then Result := 0
  else
   Result := Length(S) - Pos('.', S);
end;

function TogsPropFloat.ToString: AnsiString;
begin
 Result := FloatToStrF(fValue, ffFixed, 15, fDecimal);
end;

{ TogsPropBool }

constructor TogsPropBool.Create(Value_: Boolean);
begin
 fValue := Value_;
end;

constructor TogsPropBool.CreateAs(ogsObject: TogsBasic);
begin
 Assign(ogsObject);
end;

function TogsPropBool.Assign(ogsObject: TogsBasic): Boolean;
begin
 If not (ogsObject is TogsPropValue) then begin
   raise Exception.Create('TogsPropBool.CreateAs: объект невозможно присвоить ' + ogsObject.ClassName);
   exit;
 end;
 fValue := TogsPropvalue(ogsObject).AsBoolean;
end;

constructor TogsPropBool.Load(Stream: TogsStream);
begin
 Stream.Read(fValue, SizeOf(fValue));
end;

procedure TogsPropBool.Store(Stream: TogsStream);
begin
 Stream.Write(fValue, SizeOf(fValue));
end;

function TogsPropBool.GetStringValue: String;
begin
 Result := BoolToStr(fValue);
end;

function TogsPropBool.GetFloatValue: Double;
begin
 Result := 0;
end;

function TogsPropBool.GetIntValue: Integer;
begin
 Result := 0;
end;

function TogsPropBool.GetBoolValue: Boolean;
begin
 Result := fValue;
end;

procedure TogsPropBool.SetStringValue(AValue: String);
begin
 fValue := lowerCase(AVAlue) = 'true';
end;

procedure TogsPropBool.SetFloatValue(AValue: Double);
begin
 fValue := AValue = 0;
end;

procedure TogsPropBool.SetIntValue(AValue: Integer);
begin
 fValue := AValue = 0;
end;

procedure TogsPropBool.SetBoolValue(AValue: Boolean);
begin
 fValue := AValue;
end;

function TogsPropBool.TypeOf: TPropType;
begin
 Result := ptBool;
end;

function TogsPropBool.ValidateEntry(AValue: String): boolean;
begin
 Result := (lowerCase(AVAlue) = 'true') or (lowerCase(AVAlue) = 'false');
end;

function TogsPropBool.ToString: AnsiString;
begin
 Result := BoolToStr(fValue);
end;

{ TogsPropNull }

constructor TogsPropNull.Create;
begin
//
end;

constructor TogsPropNull.CreateAs(ogsObject: TogsBasic);
begin
 Assign(ogsObject);
end;

function TogsPropNull.Assign(ogsObject: TogsBasic): Boolean;
begin
 If not (ogsObject is TogsPropValue) then begin
   raise Exception.Create('TogsPropNull.CreateAs: объект невозможно присвоить ' + ogsObject.ClassName);
   exit;
 end;
end;

constructor TogsPropNull.Load(Stream: TogsStream);
begin
//
end;

procedure TogsPropNull.Store(Stream: TogsStream);
begin
//
end;

function TogsPropNull.TypeOf: TPropType;
begin
 Result := ptNULL;
end;

function TogsPropNull.ValidateEntry(AValue: String): boolean;
begin
 Result := AValue = '';
end;

function TogsPropNull.ToString: AnsiString;
begin
 Result := 'null';
end;

{ TogsPropArray }

constructor TogsPropArray.Create;
begin
 Items := TogsCollection.Create;
 Items.CheckTypeProc := CheckogsArrayType;
end;

destructor TogsPropArray.Destroy;
begin
 If Count > 0 then
  If (Items[Count - 1] = nil) then Items.Delete(Count - 1);
 Items.Free;
end;

constructor TogsPropArray.CreateAs(ogsObject: TogsBasic);
var S: TogsStream;
begin
 {
 S := TogsStream.Create
  ogsObject.Store(S);
  Load(S);
 S.Free;
 }
 inherited CreateAs(ogsObject);
 Items := TogsCollection.Create;
 Items.CheckTypeProc := CheckogsArrayType;
 Assign(ogsObject);
end;

function TogsPropArray.Assign(ogsObject: TogsBasic): Boolean;
var I: Integer;
    Obj: TogsPropValue;
begin
// If not (ogsObject is TogsPropValue) then Exception.Create();
// WriteIn([ClassName+'.CreateAs']);
 Obj := TogsPropValue(ogsObject);
// WriteIn(['_Obj.Class=',Obj.ClassName, Obj.Count]);
 For I := 0 to Obj.Count - 1 do begin
//  WriteIn(['__I1=',I,Obj.Item[I].ClassName]);
  Items.Add(TogsBasicClass(Obj.Item[I].ClassType).CreateAs(Obj.Item[I]));
//  WriteIn(['__I2=',I,Obj.Item[I].ClassName]);
 end;
// WriteIn([ClassNAme+'__EndCreate']);
end;

constructor TogsPropArray.Load(Stream: TogsStream);
begin
 Items := TogsCollection(Stream.Get);
end;

procedure TogsPropArray.Store(Stream: TogsStream);
begin
 Stream.Put(Items);
end;

function TogsPropArray.GetItem(Index: Integer): TogsPropValue;
begin
 Result := Items[Index];
end;

function TogsPropArray.GetItemByName(ItemName: String): TogsPropValue;
var I: Integer; propValue: TogsPropValue;
begin
// WriteIn(['Get=',ItemName]);
 For I := 0 to Items.Count - 1 do begin
 // проверяем свойства всех TogsProperty, включая вложенные
// WriteIn(['Class=',I,Item[I].ClassName,Item[I].MyName]);
  Result := Item[I][ItemName];
// WriteIn(['Index=', I, Result.AsString]);
  If Result <> nilObject then
                             exit;
 end;
 Result := nilObject;
end;

function TogsPropArray.TypeOf: TPropType;
begin
 Result := ptArray;
end;

function TogsPropArray.AddItem(Value: TogsPropValue): TogsPropValue;
begin
 Result := Value;
// если последний указатель TogsPropValue = nil -> заменяем
 If (Items.Count = 0) then Items.Add(Value) else
 If (Items[Items.Count - 1] = nil) then begin
  Items[Items.Count - 1] := Value;
 end else
  Items.Add(Value);
end;

function TogsPropArray.Count: Integer;
begin
 Result := Items.Count;
end;

function TogsPropArray.ToString: AnsiString;
var I: Integer;
begin
 Result := '[]';
 If Items.Count = 0 then exit;
 Result :='[';
  For I := 0 to Items.Count - 1 do begin
{ debug ->} //  If I>10 then exit;
   Item[I].Level :=Level;
   Result := Result + Item[I].ToString;
   If I < Items.Count -1 then Result := Result + ', ' else begin
    If Item[Count - 1].TypeOf = ptObject then
     Result := Result + ss1310{#13#10} + Space +']' else
     Result := Result + ']';
   end;
  end;
end;

function TogsPropArray.FromString(jsonStr: AnsiString): Integer;
begin
 Result := 0;
end;

procedure TogsPropArray.Sort(SortProc: TListSortCompare);
var I: Integer; SortCol: TogsSortedCollection;
begin
 SortCol := TogsSortedCollection.Create(SortProc);
// заполняем сортированную коллекцию
  For I := 0 to Items.Count - 1 do SortCol.Add(Items[I]);
// перезаписываем Items
 Items.DeleteAll;
 For I := 0 to SortCol.Count - 1 do begin
  Items.Add(SortCol[I]);
 // сортируем дочерние
  Item[I].Sort(SortProc);
 end;
 SortCol.DeleteAll;
 SortCol.Free;
end;

procedure TogsPropArray.Update(Level: Integer);
var I: Integer;
begin
 Level := Level;
 For I := 0 to Count -1 do Item[I].Update(Level + 1);
end;

{ TogsPropObject }

constructor TogsPropObject.CreateAs(ogsObject: TogsBasic);
begin
// WriteIn(['Object.CreateAs']);
 inherited CreateAs(ogsObject);
end;

constructor TogsPropObject.CreateFrom(jsonStr: AnsiString);
begin
 inherited Create;
 FromString(jsonStr);
end;

constructor TogsPropObject.CreateFrom(jsonStream: TogsStream);
begin
 inherited Create;
 FromStream(jsonStream);
end;

function TogsPropObject.GetItem(Index: Integer): TogsPropValue;
begin
 Result := Items[Index];
end;

function TogsPropObject.TypeOf: TPropType;
begin
 Result := ptObject;
end;

function TogsPropObject.AddItem(Value: TogsPropValue): TogsPropValue;
begin
 Result := Value;
 // последний указатель TogsPropValue = nil -> заменяем
 If (Items.Count = 0) then Items.Add(Value) else
 If (TogsProperty(Items[Items.Count - 1]).propValue = nil) then begin
  TogsPropValue(Items[Items.Count-1]).AddItem(Value);
 end else
  Items.Add(Value);
end;

function TogsPropObject.ToString: AnsiString;
var I: Integer;
begin
 Result := '{ ';
 If Items.Count = 0 then exit;
// WriteIn(['Level=', Level]);
// If Level = 0 then Result :='{' + #13#10 else Result := #13#10 + Space + '{' + #13#10;
 If Level = 0 then Result :='{' + ss1310 else Result := ss1310  + ss32 + '{' + ss1310;
//
 For I := 0 to Items.Count - 1 do begin
   Item[I].Level := Level + 1;
   Result := Result + Item[I].ToString;
   If I < Items.Count - 1 then Result := Result + ','+ ss1310;
  end;
 Result :=  Result + ss1310 + Space + '}';
end;

function TogsPropObject.FromString(jsonStr: AnsiString): Integer;
var Stream: TjsonStream; propObj: TogsPropObject;
begin
 Stream := TjsonStream.CreateStringStream(jsonStr);
  Result := FromStream(Stream);
 Stream.Free;
end;

function TogsPropObject.FromStream(jsonStream: TogsStream): Integer;
begin
 jsonStream.LoadDefaultObject(Pointer(Self));
 Result := Items.Count;
end;

initialization
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropString, 301, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsProperty, 302, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropArray, 303, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropObject, 304, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropFloat, 305, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropBool, 306, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPropNull, 307, 1));
//
 nilObject := TogsProperty.Create('nil',TogsPropString.Create(nilValue));
 nullObject := TogsProperty.Create('null',TogsPropString.Create(nullValue));
finalization
 nilObject.Free;
 nullObject.Free;
end.

