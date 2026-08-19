unit ogcJSON;


interface

uses Classes, SysUtils, ogcBasic, ogcProperties;

// глобальные переменные при чтении jsonStream
const gArrayLvl: Integer = 100;
      gObjectLvl: Integer = 100;
type

  { TjsonObject }

  TjsonObjectType = (jtObject, jtArray, jtPropName, jtPropValue, jtEndArray, jtEndObject);

  { TjsonBasic }

  TjsonBasic = class (TogsBasic)
   rootObj: Boolean;
   jsonType: TjsonObjectType; // тип элемента json: объект, массив, свойство, атомарное значение, конец обмасива, конец объекта
   jsonIndex: Integer;  // индекс в коллекции элементов json
   jsonLevel: Integer;  // уровень вложенности
//   LevelLocked: Boolean;
   jsonValue: String;   // атомарное значение
   jsonObject: TjsonBasic; // объект
   jsonParent: TjsonBasic; // родительский объект: TjsonArray, TjsonObject
   Destructor Destroy; override;
   Function prevParent: TjsonBasic;
  //
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
   Procedure TreeView(var Obj: TjsonBasic; Prefix: String; propObject: TogsPropValue); virtual;
  end;

  { TjsonObject }

  TjsonObject = class (TjsonBasic)
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
  end;

  { TjsonEndObject }

  TjsonEndObject = class(TjsonBasic)
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
  end;

  { TjsonPropName }

  TjsonPropName = class(TjsonBasic)
//   Name: AnsiString;
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
  end;

  { TjsonPropValue }

  TjsonPropValue = class(TjsonBasic)
//   jsonValue: AnsiString;
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
  end;

  { TjsonArray }

  TjsonArray = class(TjsonBasic)
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
   Procedure TreeView(var Obj: TjsonBasic; Prefix: String; propObject: TogsPropValue); override;
  end;

  { TjsonEndArray }

  TjsonEndArray = class(TjsonBasic)
   Constructor Create(Parent: TjsonBasic; Prims: TogsCollection);
  end;

  { TjsonStream }

  TjsonStream = class (TogsStream)
  private
   function CreateJSONObject: Pointer;
  public
   constructor CreateTextStream(FileName_: String; Mode_: Word; Selector_: TogsSelector = nil);
   destructor Destroy; override;
   function Read(var Buf: AnsiString; Count: Longint): Longint; overload;
   function Write(const Buf: AnsiString; Count: Longint): Longint;
  //
   function LoadDefaultObject(P: Pointer): Pointer; override;
  end;


var  Prims: TogsCollection;

implementation

{ TjsonBasic }

constructor TjsonBasic.Create(Parent: TjsonBasic; Prims: TogsCollection);
var S: String; I: Integer;
begin
 jsonIndex := Prims.Count;
 jsonParent:= Parent;
 Prims.Add(Self);
// WriteIN(['beginObject=']);
// If JSONObject = nil then WriteIn(['endObject=', jsonValue]) else
//                          WriteIn(['endObject=', JSONObject.ClassName,'jsonValue=',jsonValue]);
// ReadIn;
end;

destructor TjsonBasic.Destroy;
begin
 If jsonObject <> nil then jsonObject.Free;
end;

function TjsonBasic.prevParent: TjsonBasic;
begin
 Result:= jsonParent;
 While Result.rootObj = False do begin
// readin;
  If Result.jsonParent = nil then exit;
  If Result.jsonParent.jsonIndex <> Result.jsonIndex then begin
   Result := Result.jsonParent;
 //  WriteIn(['Index= ',Result.jsonIndex,Result.jsonParent.jsonIndex, Result.ClassName, Result.jsonParent.classname]);
    break;
  end;
  Result := Result.jsonParent;
 end;
end;

procedure TjsonBasic.TreeView(var Obj: TjsonBasic; Prefix: String; propObject: TogsPropValue);
var tmpObject: TogsPropValue;
    S: AnsiString;
begin
// показываем все объекты на уровне
 Obj := Self;
// WriteIn([Prefix + 'BeginObject=',obj.jsonLevel, obj.jsonIndex, obj.jsonValue, obj.ClassName]);
 While Obj <> nil do begin
  Obj := Obj.jsonObject;
  If Obj = nil then exit;
  If (Obj is TjsonEndObject) and (Obj.jsonLevel = jsonLevel) then begin
//   WriteIn([Prefix + 'EndObject=',jsonLevel,  'Parent=', Obj.jsonParent.ClassName, Obj.jsonParent.jsonIndex]);
   exit;
  end else
  If (Obj is TjsonObject) and (Obj.jsonLevel <> jsonLevel) then begin
   tmpObject := TogsPropObject.Create;
   Obj.TreeView(Obj, Prefix + '    ', tmpObject);
   propObject.AddItem(tmpObject);
  end else
  If (Obj is TjsonArray) then begin
   tmpObject := TogsPropArray.Create;
   Obj.TreeView(Obj, Prefix + '    ' + '    ', tmpObject);
   propObject.AddItem(tmpObject);
  end else
  If (Obj is TjsonPropName) then begin
   tmpObject := TogsProperty.Create(Obj.jsonValue, nil);
  // Obj.TreeView(Obj, Prefix + '    ', tmpObject);
   propObject.AddItem(tmpObject);
  end else
  If Obj.jsonValue <> '' then begin
//   EnableIn;
   Case TypeOfString(Obj.jsonValue) of
    vtEmpty:
        propObject.AddItem(TogsPropString.Create(Obj.jsonValue));
    vtString : begin
               // EnableIn;
                S := DeleteQuotMarks(Obj.jsonValue);
              //  S := Obj.jsonValue;
              //  WriteIn(['S=',S]);
                propObject.AddItem(TogsPropString.Create(S));
               //9 DisableIn;
               end;
    vtNumber : begin
               //WriteIn(['CreateFloat=',Obj.jsonValue]);
               propObject.AddItem(TogsPropFloat.Create(StrToFloat(Obj.jsonValue)));
    end;
    vtNull   :
               propObject.AddItem(TogsPropNull.Create);
    vtInt    : begin
              // WriteIn(['Createint=',Obj.jsonValue]);
               propObject.AddItem(TogsPropFloat.Create(StrToInt(Obj.jsonValue), 0));
    end;
    vtBool   :begin
              // WriteIn(['CreateBool',Obj.jsonValue]);
               propObject.AddItem(TogsPropBool.Create(StrToBool(Obj.jsonValue)));
    end;
   end;
//   DisableIn;
 //  S := DeleteQuotMarks(Obj.jsonValue);
 //  propObject.AddItem(TogsPropString.Create(Obj.jsonValue));
  end;
//  If Obj.jsonValue <> '' then begin
//   WriteIn([Prefix + Obj.ClassName, Obj.jsonLevel, Obj.jsonValue, 'Parent=',Obj.jsonParent.ClassName, Obj.jsonParent.jsonIndex]);
// readIn;
 end;
end;

{ TjsonEndObject }

constructor TjsonEndObject.Create(Parent: TjsonBasic; Prims: TogsCollection);
begin
 jsonType := jtEndObject;
 Dec(gObjectLvl); jsonLevel := gObjectLvl;
 jsonIndex := Prims.Count;
 jsonParent := Parent;
// If Parent.jSonParent <> nil then Parent := Parent.jsonParent;
 inherited Create(Parent, Prims);
end;

{ TjsonEndArray }

constructor TjsonEndArray.Create(Parent: TjsonBasic; Prims: TogsCollection);
begin
 jsonType := jtEndArray;
 Dec(gArrayLvl); jsonLevel := gArrayLvl;
 jsonIndex := Prims.Count;
 jsonParent := Parent;
// If Parent.jSonParent <> nil then Parent := Parent.jsonParent;
 inherited Create(Parent, Prims);
end;

{ TjsonArray }

constructor TjsonArray.Create(Parent: TjsonBasic; Prims: TogsCollection);
var S: String; I: Integer;
begin
 jsonType := jtArray;
 jsonLevel := gArrayLvl; Inc(gArrayLvl);
 jsonIndex := Prims.Count;
 jsonParent:= Parent;
// WriteIn(['Array.Parent=',Parent.ClassName, Parent.jsonIndex]);
 Prims.Add(Self);
 jsonValue := '';
// WriteIN(['beginArray=']);
// If JSONObject = nil then WriteIn(['endArray=', jsonValue]) else
//                          WriteIn(['endArray=', JSONObject.ClassName, 'Vslue=', jsonValue]);
// ReadIn;
end;

procedure TjsonArray.TreeView(var Obj: TjsonBasic; Prefix: String; propObject: TogsPropValue);
var tmpObject: TogsPropValue;
    S: AnsiString;
begin
// показываем все объекты на уровне
// WriteIn([Prefix + 'BeginArray=',jsonLevel, jsonValue]);
 Obj := Self;
 While True do begin
  Obj := Obj.jsonObject;
  If Obj = nil then exit;
  If (Obj is TjsonEndArray) and (Obj.jsonLevel = jsonLevel) then begin
//   WriteIn([Prefix + 'EndArray=',jsonLevel, 'Parent=',Obj.jsonParent.ClassName, Obj.jsonParent.jsonIndex]);
   exit;
  end else
  If (Obj is TjsonArray) and (Obj.jsonLevel <> jsonLevel) then begin
   tmpObject := TogsPropArray.Create;
   Obj.TreeView(Obj, Prefix + '    ', tmpObject);
   propObject.AddItem(tmpObject);
  end else
  If (Obj is TjsonObject) then begin
   tmpObject := TogsPropObject.Create;
   Obj.TreeView(Obj, Prefix + '    ' + '    ', tmpObject);
   propObject.AddItem(tmpObject);
  end else
  If (Obj is TjsonPropValue) and (Obj.jsonValue <> '') then begin
   Case TypeOfString(Obj.jsonValue) of
    vtEmpty:
            propObject.AddItem(TogsPropString.Create(Obj.jsonValue));
    vtString : begin
               // EnableIn;
                S := DeleteQuotMarks(Obj.jsonValue);
              //  S := Obj.jsonValue;
              //  WriteIn(['S=',S]);
                propObject.AddItem(TogsPropString.Create(S));
               // DisableIn;
               end;
    vtNumber : propObject.AddItem(TogsPropFloat.Create(StrToFloat(Obj.jsonValue)));
    vtNull   : propObject.AddItem(TogsPropNull.Create);
    vtInt    : propObject.AddItem(TogsPropFloat.Create(StrToInt(Obj.jsonValue), 0));
    vtBool   : propObject.AddItem(TogsPropBool.Create(StrToBool(Obj.jsonValue)));
   end;

  //  S := DeleteQuotMarks(Obj.jsonValue);
 //  propObject.AddItem(TogsPropString.Create(Obj.jsonValue));
  end;
//  WriteIn([Prefix +Obj.ClassName, Obj.jsonLevel, Obj.jsonValue,'Parent=', Obj.jsonParent.ClassName, Obj.jsonParent.jsonIndex]);
//  readIn;
 end;
end;

{ TjsonPropName }

constructor TjsonPropName.Create(Parent: TjsonBasic; Prims: TogsCollection);
var S: String; I: Integer;
begin
 jsonType := jtPropName;
 jsonLevel := Parent.jsonLevel;
 jsonIndex := Prims.Count;
 jsonParent:= Parent;
 Prims.Add(Self);
 jsonValue := '';
// WriteIN(['beginPropName=']);
// If JSONObject = nil then WriteIn(['endPropName=', jsonValue]) else
//                          WriteIn(['endPropName=', JSONObject.ClassName, 'Vslue=', jsonValue]);
// ReadIn;
end;

{ TjsonPropValue }

constructor TjsonPropValue.Create(Parent: TjsonBasic; Prims: TogsCollection);
var S: String; I: Integer;
    qMarkCount: Integer;
    qMark: Boolean;
begin
 jsonType := jtPropValue;
 jsonLevel := Parent.jsonLevel;
 jsonIndex := Prims.Count;
 jsonParent:= Parent;
 Prims.Add(Self);
 jsonValue := '';
// если встретились кавычки -> открываем счетчик
// If JSONObject = nil then WriteIn(['endValue', 'Vslue=', jsonValue]) else
//                          WriteIn(['endValue=', JSONObject.ClassName, 'Vslue=', jsonValue]);
// ReadIn;
end;

{ TjsonObject }

constructor TjsonObject.Create(Parent: TjsonBasic; Prims: TogsCollection);
begin
 jsonType := jtObject;
 jsonLevel := gObjectLvl; Inc(gObjectLvl);
// If Parent <> nil then
// WriteIn(['Object.Parent=',Parent.ClassName, Parent.jsonIndex]);
 inherited Create(Parent, Prims);
end;

{ TjsonStream }

constructor TjsonStream.CreateTextStream(FileName_: String; Mode_: Word; Selector_: TogsSelector);
begin
 inherited CreateFileStream(FileName_, Mode_, Selector_);
end;

destructor TjsonStream.Destroy;
begin
 inherited Destroy;
end;

function TjsonStream.Read(var Buf: AnsiString; Count: Longint): Longint;
var L: Integer;
begin
 SetLength(Buf, Count);
 Result := Stream.Read(Buf[1], Count);
end;

function TjsonStream.Write(const Buf: AnsiString; Count: Longint): Longint;
var L: Integer;
begin
 Stream.Write(Buf[1], Count);
end;

function TjsonStream.CreateJSONObject: Pointer;
label X, Y;
var jsonType: TjsonObjectType; currentObj, jsonObj: TjsonBasic;
    S, prevSym: String;
    qMark: Boolean;
    qMarkCount: Integer;
    Parent: TjsonBasic;
function CreateObjectFrom(Parent_:TjsonBasic; C: Char; Check: boolean = True): boolean;
begin
 If (C = '{') and Check then jsonObj := TjsonObject.Create(Parent_, Prims) else
 If (C = '[') and Check then jsonObj := TjsonArray.Create(Parent_, Prims) else
 If (C = ']') and Check then jsonObj := TjsonEndArray.Create(Parent_, Prims) else
 If (C = '}') and Check then jsonObj := TjsonEndObject.Create(Parent_, Prims);
 Result := jsonObj <> nil;
 If Result then
  Case jsonObj.jsonType of
   jtObject, jtArray: Parent := jsonObj; // родительский элемент = текущий объект
   jtEndObject, jtEndArray: Parent := Parent_.jsonParent; // для всех дочерних элементов
                                                             // родительский элемент объект или массив
  end;
end;
begin
 Result := nil;
 While S<>'{' do begin
  Read(S,1);
  If Position = Size then exit;
 end;
 currentObj := TjsonObject.Create(nil, Prims);
 Parent := currentObj;
 currentObj.jsonParent := currentObj;
 Result := currentObj;
 prevSym := '';
X:
 S := '';
 jsonObj := nil;
 Case currentObj.jsonType of
  jtObject,
  jtEndObject,
  jtEndArray     :begin
                  // считываем объект до закрывающей скобки
                   While S <> '}' do begin
                    if Self.Position = Self.Size then Goto Y;
                    Self.Read(S, 1);
                    prevSym := prevSym + S[1]; //If Length(prevSym) > 2 then Delete(prevSym, 1,1);
                    If not CreateObjectFrom(Parent, S[1]) then
                    If S = ':' then jsonObj := TjsonPropValue.Create(Parent, Prims) else
                    If S = '"' then begin
                     // если массив -> создаем TjsonPropValue, объект - > TjsonPropName
                     Self.Position := Self.Position - 1;
                     If Parent is TjsonObject then jsonObj := TjsonPropName.Create(Parent, Prims) else
                     If Parent is TjsonArray then jsonObj := TjsonPropValue.Create(Parent, Prims) else
//                      WriteIn([Parent.ClassName]); // ошибка или исключение (для отладки)
                    end;
                    If jsonObj <> nil then begin
                     currentObj.jsonObject := jsonObj;
                     currentObj := jsonObj;
                     Goto X;
                    end;
                   end;
                  end;
  jtArray        :begin
                  // считываем объект, массив, значение до закрывающей скобки
                   While (S <> ']') do begin
                    if Self.Position = Self.Size then Goto Y;
                    Self.Read(S, 1);
                    prevSym := prevSym + S[1]; //If Length(prevSym) > 2 then Delete(prevSym, 1,1);
                    If not CreateObjectFrom(Parent, S[1]) then
                    If S = ',' then jsonObj := TjsonPropValue.Create(Parent, Prims) else
                  // для корректного считывания значения инициируем TjsonPropValue.Create
                    If not (S[1] in [#32, ',', ']', #9, #13, #10]) then begin
                     Self.Position := Self.Position - 1;
                     jsonObj := TjsonPropValue.Create(Parent, Prims);
                    end;
                    If jsonObj <> nil then begin
                     currentObj.jsonObject := jsonObj;
                     currentObj := jsonObj;
                     Goto X;
                    end;
                   end;
                  end;
  jtPropName     :begin
                  // считываем имя свойства до двоеточия
                   While S <> ':' do begin
                    if Self.Position = Self.Size then Goto Y;
                    Self.Read(S, 1);
                    prevSym := prevSym + S[1]; //If Length(prevSym) > 2 then Delete(prevSym, 1,1);
                    If not CreateObjectFrom(Parent, S[1]) then
                    If S = ':' then jsonObj := TjsonPropValue.Create(Parent, Prims) else
                    If not (S[1] in [']', '}', '"', #9, #13, #10]) then currentObj.jsonValue := currentObj.jsonValue + S;
                    If jsonObj <> nil then begin
                     currentObj.jsonObject := jsonObj;
                     currentObj.jsonValue := Trim(currentObj.jsonValue);
                     currentObj := jsonObj;
                     Goto X;
                    end;
                   end;
                   //jsonValue := Trim(jsonValue);
                  end;
  jtPropValue    :begin
                   qMarkCount := 0;
                  // считываем объект, массив, значение до закятой
                  // за исключением строкового значения в кавычках
                   qMark := True;
                   While True (*(S <> ',') and (S <> ']') and (S <> '}') *) do begin
                    if Self.Position = Self.Size then Goto Y;
                    Self.Read(S, 1);
                    prevSym := prevSym + S[1]; //If Length(prevSym) > 2 then Delete(prevSym, 1,1);
                   // считаем кавычки дл допуска разделителей внутри строки формата "..."
                    If (prevSym[System.Length(prevSym)] = '"') then
                     If (prevSym[System.Length(prevSym)-1] <> '\') then Inc(qMarkCount);
                    qMark := ((qMarkCount = 0)) or (qMarkCount = 2);
                   //
                    If not CreateObjectFrom(Parent, S[1], qMark) then
                   // если массив -> создаем TjsonPropValue, объект - > TjsonPropName
                    If (S = ',') and (qMark) then begin
                     If Parent is TjsonArray then jsonObj := TjsonPropValue.Create(Parent, Prims) else
                     If Parent is TjsonObject then jsonObj := TjsonPropName.Create(Parent, Prims) else
//                     WriteIn([Parent.ClassName]); // ошибка или исключение (для отладки)
                    end else
                    If not (S[1] in [#9, #13, #10]) then currentObj.jsonValue := currentObj.jsonValue + S;
                    If jsonObj <> nil then begin
                     currentObj.jsonObject := jsonObj;
                     currentObj.jsonValue := Trim(currentObj.jsonValue);
                     currentObj := jsonObj;
                     Goto X;
                    end;
                   end;
                  end;
 end;
 Y:{:)}
end;

function TjsonStream.LoadDefaultObject(P: Pointer): Pointer;
var I, Cnt: Integer;
    jsonObject: TjsonBasic;
    propObject: TogsPropObject;
    Time: Int64;
begin
// DisableIn;
// WriteIn(['BeginLoad']);
// Time := GetTickCount;
// парсер
 jsonObject := CreateJSONObject;
// WriteIn(['EndLoad', Prims.Count,GetTickCount - Time]);
 If jsonObject = nil then exit;
 jsonObject := Prims[0]; jsonObject.rootObj := True;
// инициализация объекта TogsPropObject
 If P <> nil then propObject := P else
                  propObject := TogsPropObject.Create;
// outDisabled := True;
// Time := GetTickCount;
 jsonObject.TreeView(jsonObject, '', propObject);
 Result := propObject;
// outDisabled := False;
// WriteIn(['EndParse', Prims.Count,GetTickCount - Time]);
// exit;
 Cnt := 0;
 For I := 1 to Prims.Count - 1 do begin
  jsonObject := Prims[I];
  If jsonObject.jsonValue = '' then Inc(Cnt);
 // WriteIn(['Name=',jsonObj.ClassName,'Index=',jsonObj.jsonIndex,'Parent=',jsonObj.jsonParent.jsonIndex, jsonObj.jsonValue]);
 end;
// WriteIn(['CountEmpty',Cnt,GetTickCount - Time]);
 Prims.DeleteAll;
 jsonObject.Free;
//
// ClipBoard.AsText := propObject.ToString;
// WriteIn(['Len=',System.Length(ClipBoard.AsText)]);
// EnableIn;
end;

initialization
// временно для отладки json - парсера
 Prims := TogsCollection.Create;
end.


