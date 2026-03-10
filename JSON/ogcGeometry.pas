unit ogcGeometry;

// {$mode Delphi}{$H+}

interface

uses Classes, SysUtils, Graphics, ogcBasic, ogcProperties;

type

 { TogsGeometryCollection }

  TogsGeometryCollection = class(TogsSortedCollection)
  private
  // убираем метод Add из публичных объявлений
  // чтобы не дать возможность добавлять неконтролируемые данные
  // к примеру: добавление точки методом AddPoint(X, Y, Z),
  // приводит к пересчету габаритов примитива, а если использовать
  // Add(TogsDot.Create(...)) произойдет неконтролируемое добавление точки
   function Add(Item_: Pointer): Integer; override;
  private
   fogsRect: TogsRect;
   fogsSelector: TogsSelector;
  // корневой объект GeoJSON "properties": {name: <values>...}
  // в результате вызова конструктора CreateJSON(jsonSpatialArray: TogsPropValue)
  // исходный массив очищается от массива координат TogsPropArray
  // в TogsPropArray сохраняется ссылка propValue = TogsGeometry
  // при экспорте в JSON пространственные данные передаюися из TogsGeometry.ToString
   fogsProperties: TogsPropValue;
   fSelected: boolean;
   function GetogsRect: TogsRect; override;
   function GetogsSelector: TogsSelector; override;
   procedure SetogsSelector(Data: TogsSelector); override;
   function GetogsProperties: TogsProperties; override;
   procedure SetogsProperties(AValue: TogsProperties);override;
  //
   function GetItem(Index: Integer): TogsGeometry;
   procedure SetItem(Index: Integer; AValue: TogsGeometry);
  //
   function GetSelected: boolean; override;
   procedure SetSelected(AValue: boolean); override;
  //
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector = nil);
   destructor Destroy; override;
   procedure Clear; override;
   function CreateSysProperties(strTemplate: String): TogsProperties; override;
   function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: boolean = False): Integer; virtual;
  //
   function numGeometries (): Integer; virtual;
   function GeometryN (N: Integer): TogsGeometry; virtual;
   property Item[Index: Integer]: TogsGeometry read GetItem write SetItem; default;
  //
   property ogsProperties: TogsProperties read GetogsProperties write SetogsProperties;
   function ToString: AnsiString; override;
  //
   function Visible(Rect: TogsRect): Boolean; override;
  //
   function SortByProc(sortProc: TListSortCompare; Duplicates_: Boolean): Integer;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; virtual;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  // Draw
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  //
   function FindAttribute(AttrNAme_:String; out Prim: Pointer): Boolean; override;
  end;

 { TogsPoint - точка с bBox и семантикой }

  TogsPoint = class(TogsDot)
  private
   fogsRect: TogsRect;
   fogsSelector: TogsSelector;
   fogsProperties: TogsPropValue;
   fSelected: Boolean;
   function GetogsRect: TogsRect; override;
   function GetogsSelector: TogsSelector; override;
   procedure SetogsSelector(Data: TogsSelector); override;
   function GetogsProperties: TogsProperties; override;
   procedure SetogsProperties(AValue: TogsProperties); override;
  //
   function GetSquare: Double; override;
  public
   M: Double;
   class function GeometryType: String; override;
   constructor Create(X_, Y_, Z_: Double; ogsSelector_: TogsSelector = nil);
  // массив geoJSON "geometry" = TogsPropArray
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector = nil);
   constructor CreateAs(ogsPoint_: TogsPoint);
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure   Store(Stream: TogsStream); override;
   procedure Clear; override;
  // видимость
   function Visible(Rect: TogsRect): Boolean; override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; virtual;
   function GetSelected: boolean; override;
   procedure SetSelected(AValue: boolean); override;
  //
   function CreateSysProperties(strTemplate: String): TogsProperties; override;
   property ogsProperties: TogsProperties read GetogsProperties write SetogsProperties;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: Boolean = False): Integer; virtual;
   function ToString : AnsiString; override;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  end;

 { TogsMultiPoint - коллекция TogsPoint }

  type
   TogsMultiPoint = class(TogsGeometryCollection)
   private
    function GetPoint(Index: Integer): TogsPoint;
   public
    class function GeometryType: String; override;
    constructor Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
    constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector = nil);
    constructor Load(Stream: TogsStream); override;
    procedure Store(Stream: TogsStream); override;
   //
    function PointN(N: Integer): TogsPoint; Virtual;
    procedure AddPoint(X, Y, Z: Double); virtual;
   // bBox
    function Calculate(Action: TCalcActionSet): Integer; override;
   // Paint
    procedure Draw(Drawer: TogsDrawer); override;
    procedure DrawPoint(Drawer: TogsDrawer); override;
   //
    property Point[Index: Integer]: TogsPoint read GetPoint;default;
   // захват
    function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   // координаты в JSON
    function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: Boolean = False): Integer; override;
   end;

  { TogsLineString - одномерная коллекция TogsDot }

  TogsLineString = class(TogsMultiPoint)
  private
   fLength: Double;
   function _Length: Double; override;
   function GetSquare: Double; override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector);
   procedure AddPoint(X, Y, Z: Double); override;
  //
   property Length: Double read _Length;
   function StartPoint (): TogsPoint; virtual;
   function EndPoint (): TogsPoint; virtual;
   function IsClosed (): Integer; virtual;
   function IsRing (): Integer; virtual;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  //
//   function UpdateSpatialProperties(out spatialProps: TogsProp): Integer; override;
  end;

  { TogsMultiLine }

  { TogsMultiLineString }

  TogsMultiLineString = class(TogsGeometryCollection)
  private
   fLength: Double;
   function GetLine(Index: Integer): TogsLineString;
   function _Length: Double; override;
   function GetSquare: Double; override;
  public
 // необходимо рассмотрения примеров geoJSON
 //  constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector = nil);
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector);
   property Length: Double read _Length;
   procedure AddLine(Line: TogsLineString); virtual;
   function Calculate(Action: TCalcActionSet): Integer; override;
  //
   property Line[Index: Integer]: TogsLineString read GetLine; default;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: Boolean): Integer; override;
  end;

 { TPoly_Single - площадной объект -> наследник TogsLineString }

  TPolyMode = record
   clockWise : boolean; // ориентация полигона
   isCorrect : boolean; // корректность: замыкание, отношения полигонов
   touchPoint: boolean; // касание полигона Parent юолее чем в одной точке
   interWith : boolean; // взаимное пересечение
   nullParent: boolean; // Parent = nil
  // multiPoly : boolean; // составной полигон -> multiPolygon
   intersect : boolean; // пересекается с ругим полигоном
   extTag2,
   extFlag   : boolean; // доп тэги, extTag используется в качестве доп. флажка
                        // при calcRelation
   GlobalParent: Pointer;
  end;

  TPoly_Single = class(TogsLineString)
  private
  // родительский полигон
   fParent: Pointer;
   procedure SetParent(AValue: Pointer);
   function GetSquare: Double; override;
  public
   fSquare: Double;
   PolyMode: TPolyMode;
   constructor Create(ogsSelector_: TogsSelector = nil);
   function Calculate(Action: TCalcActionSet): Integer; override;
  //
   property Parent: Pointer read fParent write SetParent;
  // захват - точка в полигоне
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // если параметр clockWise = 0 -> при вращении не происходит установкf флага PoluMode.clockWise
   procedure Rotate(clockWise : Integer);
  // -1 - не входит в полигон Poly, 0 - входит не соприкасается,
  // 1 входит соприкасается в точке, 2..N - соприкасается в 2-х и более точках
   function PolygonIn(Poly: TPoly_Single; var touchCount: Integer): Integer;
  end;

 { TogsPolygon - коллекция полигонов -> предков TogsLineString }

  TogsPolygon = class(TogsGeometryCollection)
  private
   fSquare: Double;
   function GetPolygon(Index: Integer): TPoly_Single;
   function GetSquare: Double; override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector = nil);
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
   procedure AddPolygon(Polygon: TPoly_Single);
   property Polygon[Index: Integer]: TPoly_Single read GetPolygon;
   property Square: Double read fSquare;
  //
   function CalcSquares: Integer;
   function CalcRelations: Integer;
   function isMultiPolygon: Boolean;
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  // захват - точка в Polygon[Index], если полигон - не дырка
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: Boolean = False): Integer; override;
  end;

 { TogsMultiPolygon - коллекция TogsPolygon }

  TogsMultiPolygon = class(TogsGeometryCollection)
   fSquare: Double;
   function GetPolygon(Index: Integer): TogsPolygon;
   function GetSquare: Double; override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector = nil);
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
   procedure AddPolygon(Polygon: TogsPolygon);
   procedure AddMultiPoly(ogsPolygon: TogsPolygon);
   property Polygon[Index: Integer]: TogsPolygon read GetPolygon;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TogsPropValue; OnlyGeometry: Boolean = False): Integer; override;
  end;

// проверка типа добавляемых пространственных примитивов
 function CheckogsDotType(P: TogsBasic): Boolean;
 function CheckogsPointType(P: TogsBasic): Boolean;
 function CheckogsLineType(P: TogsBasic): Boolean;
 function CheckPoly_SignType(P: TogsBasic): Boolean;
 function CheckogsPolygonType(P: TogsBasic): Boolean;
// сортировка пространственных данных
 function SortBySquareProc(Item1, Item2: Pointer): Integer;

implementation uses ogcMathUtils;

function CheckogsDotType(P: TogsBasic): Boolean;
begin
 Result := (P is TogsDot);
end;

function CheckogsPointType(P: TogsBasic): Boolean;
begin
 Result := (P is TogsDot) or (P is TogsPoint);
end;

function CheckogsLineType(P: TogsBasic): Boolean;
begin
 Result := P is TogsLineString;
end;

function CheckPoly_SignType(P: TogsBasic): Boolean;
begin
 Result := P is TPoly_Single;
end;

function CheckogsPolygonType(P: TogsBasic): Boolean;
begin
 Result := P is TogsPolygon;
end;

function SortBySquareProc(Item1, Item2: Pointer): Integer;
begin
// !!! не работает для сортировки с округлением
 If TPoly_Single(Item1).Square < TPoly_Single(Item2).Square then Result := 1 else
 If TPoly_Single(Item1).Square = TPoly_Single(Item2).Square then Result := 0 else
 If TPoly_Single(Item1).Square > TPoly_Single(Item2).Square then Result := -1;
end;

{ TogsGeometryCollection }

constructor TogsGeometryCollection.Create(ogsSelector_: TogsSelector; Capacity_: Integer);
begin
 inherited Create(nil, True, Capacity_);
 fogsRect := TogsRect.Create;
 fogsSelector := ogsSelector_;
end;

constructor TogsGeometryCollection.CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
begin
// If jsonProperties <> nil then
//  WriteIn(['Prop.ClassName',jsonProperties.ClassName, jsonProperties.Count,jsonProperties.toString]);
 If jsonProperties <> nil then begin
//  WriteIn(['ORIGINAL=',jsonProperties.toString]);
   fogsProperties := TogsBasicClass(jsonProperties.ClassType).CreateAs(jsonProperties) as TogsPropValue;
//  WriteIn(['ASSIGNED=',fogsProperties.toString]);
 end;
end;

destructor TogsGeometryCollection.Destroy;
begin
 Clear;
end;

procedure TogsGeometryCollection.Clear;
begin
// fogsSelector.Clear;
 fogsRect.Clear;
 FreeAll;
 If fogsProperties <> nil then FreeAndNil(fogsProperties);
end;

function TogsGeometryCollection.CreateSysProperties(strTemplate: String): TogsProperties;
begin
 if fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := TogsPropObject.Create;
 fogsProperties.FromString(strTemplate);
 Result := fogsProperties;
end;

class function TogsGeometryCollection.GeometryType: String;
begin
 Result := 'geometrycollection';
end;

function TogsGeometryCollection.UpdateSpatialProperties(var spatialProps: TogsPropValue;
 OnlyGeometry: boolean): Integer;
begin
// creating GeometryCollection Spatial properties
end;

function TogsGeometryCollection.GetogsProperties: TogsProperties;
begin
 Result := fogsProperties;
end;

function TogsGeometryCollection.GetogsSelector: TogsSelector;
begin
 Result := fogsSelector;
end;

procedure TogsGeometryCollection.SetogsSelector(Data: TogsSelector);
begin
 fogsSelector := Data;
end;

function TogsGeometryCollection.Add(Item_: Pointer): Integer;
begin
// raise Exception.Create('Вызов неконтролируемого добавления укзалеля в объект ' + ClassName);
 Result:=inherited Add(Item_);
end;

function TogsGeometryCollection.GetogsRect: TogsRect;
begin
 Result := fogsRect;
end;

function TogsGeometryCollection.GetItem(Index: Integer): TogsGeometry;
begin
 Result := TogsGeometry(List[Index]);
end;

procedure TogsGeometryCollection.SetItem(Index: Integer; AValue: TogsGeometry);
begin
 List[Index] := AValue;
end;

function TogsGeometryCollection.GetSelected: boolean;
begin
 Result := fSelected;
end;

procedure TogsGeometryCollection.SetSelected(AValue: boolean);
var I: Integer;
begin
 fSelected := AValue;
end;

procedure TogsGeometryCollection.SetogsProperties(AValue: TogsProperties);
begin
 If fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := TogsPropValue(AValue);
end;

function TogsGeometryCollection.numGeometries: Integer;
begin
 Result := fList.Count;
end;

function TogsGeometryCollection.GeometryN(N: Integer): TogsGeometry;
begin
 Result := TogsGeometry(fList[N]);
end;

function TogsGeometryCollection.ToString: AnsiString;
var tmpProps: TogsPropValue;
    spatialProps: TogsPropValue;
begin
// создаем объект -> копию ogsProperties
 tmpProps := TogsBasicClass(ogsProperties.ClassType).CreateAs(ogsProperties) as TogsPropValue;
// передаем атрибуты TogsPoint в JSON свойство типа TogsPropObject
  UpdateSpatialProperties(spatialProps);
// добавляем в ogsProperties
 tmpProps.AddItem(spatialProps);
//
 Result:= tmpProps.ToString;
//
 tmpProps.Free;
 spatialProps.Free;
end;

function TogsGeometryCollection.Visible(Rect: TogsRect): Boolean;
begin
 Result := fogsRect.VisibleIn(Rect);
end;

function TogsGeometryCollection.SortByProc(sortProc: TListSortCompare;
 Duplicates_: Boolean): Integer;
var I: Integer;
    sortedCol: TogsSortedCollection;
begin
 // сортируем по площади
 Result := 0;
 If Count <= 1 then exit;
 sortedCol := TogsSortedCollection.Create(sortProc, Duplicates_);
 For I := 0 to Count - 1 do sortedCol.Add(List[I]);
 // присваиваем отсортированные двнные
 // (оптимизация: 1.наследование от TogsSortedCollection
 //               2.хэш-тпблица
 For I := 0 to sortedCol.Count - 1 do List[I] := sortedCol.List[I];
 sortedCol.DeleteAll; sortedCol.Free;
 Result := Count;
end;

function TogsGeometryCollection.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
begin
 Result := False;
 For I := 0 to Count -1 do begin
  Result := Item[I].SelectByPoint(X_,Y_,Params);
  If Result then exit;
 end;
end;

function TogsGeometryCollection.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
// WriteIn(['Calculate.Count = ', Count]);
 For I := 0 to Count -1 do
  Item[I].Calculate(Action);
 If calcbBox in Action then begin
  fogsRect.Clear;
  For I := 0 to Count - 1 do
   fOgsRect.InsertRect(Item[I].ogsRect);
 end;
end;

procedure TogsGeometryCollection.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do begin
//  WriteIn(['DrawGMCol=',Item[I].ClassNAme,Item[I].ogsRect.XMin,Item[I].ogsRect.XMax]);
  Item[I].Draw(Drawer);
 end;
end;

procedure TogsGeometryCollection.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do Item[I].DrawPoint(Drawer);
end;

function TogsGeometryCollection.FindAttribute(AttrNAme_: String; out
 Prim: Pointer): Boolean;
var I: Integer;
begin
 For I := 0 to Count - 1 do
  If AnsiCompareText(AttrName_, Item[I].Attribute) = 0 then begin
   Prim := Items[I];
   Result := True;
   exit;
  end;
 Result := False;
end;

{ TogsPoint }

constructor TogsPoint.Create(X_, Y_, Z_: Double; ogsSelector_: TogsSelector = nil);
begin
 X := X_;
 Y := Y_;
 Z := Z_;
 M := 0;
 fogsRect := TogsRect.Create;
 fogsRect.Insert(X, Y);
 fogsSelector := ogsSelector_;
//!!! спорный вопрос при добавлении блоков и атрибутов
// If fOgsSelector <> nil then fogsSelector.AddCoord(X, Y);
end;

constructor TogsPoint.CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector = nil);
begin
 fogsRect := TogsRect.Create;
 fogsSelector := ogsSelector_;
// по умолчанию однмерный массив [13420.363, 1753.199] с 2 значениями
 if jsonSpatialArray.Count < 2 then exit; // добавить обработку ошибки
  X := StrToFloat(jsonSpatialArray.Item[0].ToString);
  Y := -StrToFloat(jsonSpatialArray.Item[1].ToString);
  If jsonSpatialArray.Count > 2 then
   Z := StrToFloat(jsonSpatialArray.Item[2].ToString)
  else
   Z := ZNull;
//  WriteIn(['Point_XY=', X, Y]);
 fogsRect.Insert(X, Y);
 if fogsSelector <> nil then fogsSelector.AddCoord(X, Y);
 If jsonProperties <> nil then
  ogsProperties := TogsBasicClass(jsonProperties.ClassType).CreateAs(jsonProperties) as TogsPropValue;
//
end;

constructor TogsPoint.CreateAs(ogsPoint_: TogsPoint);
begin
 X := ogsPoint_.X;
 Y := ogsPoint_.Y;
 Z := ogsPoint_.Z;
 M := ogsPoint_.M;
 fogsSelector := ogsPoint_.ogsSelector;
end;

destructor TogsPoint.Destroy;
begin
 if ogsProperties <> nil then ogsProperties.Free;
end;

function TogsPoint.GetogsRect: TogsRect;
begin
 Result := fogsRect;
end;

function TogsPoint.GetogsSelector: TogsSelector;
begin
 Result := fogsSelector;
end;

procedure TogsPoint.SetogsSelector(Data: TogsSelector);
begin
 fogsSelector := Data;
end;

function TogsPoint.GetSelected: boolean;
begin
 Result := fSelected;
end;

procedure TogsPoint.SetSelected(AValue: boolean);
begin
 fSelected := AValue;
end;

function TogsPoint.GetSquare: Double;
begin
 Result := -3;
end;

class function TogsPoint.GeometryType: String;
begin
 Result := 'Point';
end;

constructor TogsPoint.Load(Stream: TogsStream);
begin
 Stream.Read(fX, SizeOf(fX));
 Stream.Read(fY, SizeOf(fY));
 Stream.Read(Z, SizeOf(Z));
 Stream.Read(M, SizeOf(M));
end;

procedure TogsPoint.Store(Stream: TogsStream);
begin
 Stream.Write(fX, SizeOf(fX));
 Stream.Write(fY, SizeOf(fY));
 Stream.Write(Z, SizeOf(Z));
 Stream.Write(M, SizeOf(M));
end;

procedure TogsPoint.Clear;
begin
// ogsSelector.Clear;
 fogsRect.Clear;
 FreeAndNil(fogsProperties);
end;

function TogsPoint.Visible(Rect: TogsRect): Boolean;
begin
 Result := fogsRect.VisibleIn(Rect);
end;

function TogsPoint.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var Dist: Integer;
begin
 Result := False;
 If ckPoint in Params.CaptureFor then begin
  Dist := ogsSelector.pixDist(Self.Distance(X_, Y_));
  If Dist <= Params.CaptureParam then begin
   Params.resCapture := Dist;
   Params.resCaptureOf := ckPoint;
   Params.resObject := Self;
   Result := Params.resCapture <= Params.CaptureParam;
  end;
 end else
end;

function TogsPoint.Calculate(Action: TCalcActionSet): Integer;
begin
 fogsRect.Clear;
 fogsRect.Insert(X, Y);
end;

// ogsProperties

function TogsPoint.GetogsProperties: TogsProperties;
begin
 Result := fogsProperties;
end;

procedure TogsPoint.SetogsProperties(AValue: TogsProperties);
begin
 If fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := TogsPropValue(AValue);
end;

function TogsPoint.CreateSysProperties(strTemplate: String): TogsProperties;
begin
 if fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := TogsPropObject.Create;
 fogsProperties.FromString(strTemplate);
 Result := fogsProperties;
end;

function TogsPoint.UpdateSpatialProperties(var spatialProps: TogsPropValue;
 OnlyGeometry: Boolean): Integer;
begin
// если передаем только геометрию - > используем spatialProps
// в качестве контейнера от родительского объекта
// иначе -> создаем новую ветку JSON со всеми характеристиками
 If OnlyGeometry then begin
  If spatialProps = nil then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps = nil');
  With spatialProps.propValue.AddItem(TogsPropArray.Create) do begin
   propValue.AddItem(TogsPropFloat.Create(X));
   propValue.AddItem(TogsPropFloat.Create(Y));
  // propValue.AddItem(TogsPropFloat.Create(Z));
  end;
 end else begin
  spatialProps.AddItem(TogsProperty.Create('geometry', TogsPropObject.Create));
  With spatialProps.propValue do begin
   propValue.Additem(TogsProperty.Create('type', TogsPropString.Create({'"' +} GeometryType {+ '"'})));
    With propValue.Additem(TogsProperty.Create('coordinates', TogsPropArray.Create)) do begin
     propValue.AddItem(TogsPropFloat.Create(X));
     propValue.AddItem(TogsPropFloat.Create(Y));
   //  propValue.AddItem(TogsPropFloat.Create(Z));
    end;
  end;
 end;
 Result := 1; // добавлен одие элемент
end;

function TogsPoint.ToString: AnsiString;
var tmpProps: TogsPropValue;
    spatialProps: TogsPropValue;
begin
// создаем объект -> копию ogsProperties
 tmpProps := TogsBasicClass(ogsProperties.ClassType).CreateAs(ogsProperties) as TogsPropValue;
// передаем атрибуты TogsPoint в JSON свойство типа TogsPropObject
 UpdateSpatialProperties(spatialProps);
// добавляем в ogsProperties
 tmpProps.AddItem(spatialProps);
//
 Result:= tmpProps.ToString;
//
 tmpProps.Free;
 spatialProps.Free;
end;

{ TogsMultiPoint }

constructor TogsMultiPoint.Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
begin
 inherited Create(ogsSelector_,Capacity_);
 checkTypeProc := @CheckogsDotType;
end;

constructor TogsMultiPoint.CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
var I: Integer;
    X, Y, Z: Double;
    xyArray: TogsPropValue;
begin
 Create(ogsSelector_);
// WriteIn(['ArrayCount=',jsonSpatialArray.Count, jsonSpatialArray.Item[0].Count]);
 if jsonSpatialArray.Count < 2 then exit; // // добавить обработку ошибок и предупреждение в протокол
//
// WriteIn(['Count=',jsonSpatialArray.Count, jsonSpatialArray.ToString]);
 For I := 0 to jsonSpatialArray.Count - 1 do begin
  xyArray := jsonSpatialArray.Item[I];
//  WriteIn(['xyCount=', xyArray.Count]);
  If xyArray.Count < 2 then break;
 //
  X := StrToFloat(xyArray.Item[0].ToString);// добавить обработку ошибок
  Y := -StrToFloat(xyArray.Item[1].ToString);
  If xyArray.Count > 2 then
   Z := StrToFloat(xyArray.Item[2].ToString)
  else
   Z := ZNull;
 //
//  WriteIn(['Line_XY=', X, Y]);
  AddPoint(X, Y, Z);
  fogsRect.Insert(X, Y);
  if fogsSelector <> nil then fogsSelector.AddCoord(X, Y);
 //
  inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
 end;
end;

function TogsMultiPoint.GetPoint(Index: Integer): TogsPoint;
begin
 Result := TogsPoint(FList[Index]);
end;

class function TogsMultiPoint.GeometryType: String;
begin
 Result := 'Multipoint';
end;

constructor TogsMultiPoint.Load(Stream: TogsStream);
var I: Integer;
begin
 inherited;
 ogsSelector := Stream.ogsSelector;
 fogsRect := TogsRect.Create;
 For I:= 0 to Count - 1 do begin
  fogsRect.Insert(TogsPoint(FList[I]).X, TogsPoint(FList[I]).Y);
 end;
end;

procedure TogsMultiPoint.Store(Stream: TogsStream);
begin
 inherited;
end;

function TogsMultiPoint.PointN(N: Integer): TogsPoint;
begin
 Result := TogsPoint(fList[N]);
end;

procedure TogsMultiPoint.AddPoint(X, Y, Z: Double);
begin
 inherited Add(TogsPoint.Create(X, Y, Z, ogsSelector));
 ogsRect.Insert(X, Y);
end;

function TogsMultiPoint.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 If calcbBox in Action then begin
  ogsRect.Clear;
  For I := 0 to Count - 1 do With TogsPoint(List[I]) do begin
 //  WriteIn(['Calc.I=',I,X,Y]);
   Self.ogsRect.Insert(X, Y);
  If ogsMatrix <> nil then
//   With Self.ogsRect do WriteIn(['Count=', Count,'XY=',X,Y,'XY.Rect=',XMin, YMin, XMAx, YMax]);
  end;
//  If ogsMatrix <> nil  then  With ogsRect do WriteIn(['MP.Rect=',XMin, YMin, XMax, YMax]);
 end;
end;

procedure TogsMultiPoint.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do TogsPoint(Items[I]).Draw(Drawer);
end;

procedure TogsMultiPoint.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do TogsDot(Items[I]).DrawPoint(Drawer);
end;

function TogsMultiPoint.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
begin
 Result:= False;
 If ckPoint in Params.CaptureFor then
  For I := 0 to Count - 1 do begin
   Result := TogsPoint(Items[I]).SelectByPoint(X_, Y_,Params);
   If Result then exit;
  end
 else
end;

function TogsMultiPoint.UpdateSpatialProperties(var spatialProps: TogsPropValue;
 OnlyGeometry: Boolean): Integer;
var I: Integer;
begin
 If OnlyGeometry then begin
  If spatialProps = nil then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps = nil');
  With spatialProps.AddItem(TogsPropArray.Create) do begin
//   WriteIn(['clName=',propValue.ClassName]);
   For I := 0 to Self.Count -1 do
    With propValue.AddItem(TogsPropArray.Create) do begin
//     WriteIn([Point[I].X,Point[I].Y,Point[I].Z,'clName=',propValue.ClassName]);
     propValue.AddItem(TogsPropFloat.Create(Point[I].X));
     propValue.AddItem(TogsPropFloat.Create(Point[I].Y));
    // propValue.AddItem(TogsPropFloat.Create(Point[I].Z));
    end;
  end;
 end else begin
  spatialProps.AddItem(TogsProperty.Create('geometry', TogsPropObject.Create));
  With spatialProps.propValue do begin
//  With spatialProps do begin
   propValue.AddItem(TogsProperty.Create('type', TogsPropString.Create({'"' +} GeometryType {+ '"'})));
    With propValue.AddItem(TogsProperty.Create('coordinates', TogsPropArray.Create)) do begin
    // добавляем координаты
//     WriteIn(['clName=',propValue.ClassName]);
     For I := 0 to Self.Count -1 do
      With propValue.AddItem(TogsPropArray.Create) do begin
 //      WriteIn([Point[I].X,Point[I].Y,Point[I].Z,'clName=',propValue.ClassName]);
       propValue.AddItem(TogsPropFloat.Create(Point[I].X));
       propValue.AddItem(TogsPropFloat.Create(Point[I].Y));
   //    propValue.AddItem(TogsPropFloat.Create(Point[I].Z));
//       WriteIn([I,Point[I].X,Point[I].Y,Point[I].Z]);
      end;
    end;
  end;
 end;
 Result := Count; // добавлен одие элемент
end;

{ TogsLineString }

constructor TogsLineString.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 checkTypeProc := @CheckogsDotType;
 fLength := -1;
end;

function TogsLineString._Length: Double;
begin
 Result := fLength;
end;

function TogsLineString.GetSquare: Double;
begin
 Result := -1;
end;

class function TogsLineString.GeometryType: String;
begin
 Result := 'Linestring';
end;

procedure TogsLineString.AddPoint(X, Y, Z: Double);
begin
 inherited Add(TogsDot.Create(X, Y, Z));
 fogsRect.Insert(X, Y);
end;

function TogsLineString.StartPoint: TogsPoint;
begin
 Result := TogsPoint(fList[0]);
end;

function TogsLineString.EndPoint: TogsPoint;
begin
 Result := TogsPoint(fList[fList.Count -1]);
end;

function TogsLineString.IsClosed: Integer;
begin
 Result := StartPoint.Equals(EndPoint);
end;

function TogsLineString.IsRing: Integer;
var I, J: Integer;
begin
 Result := isClosed;
 If isClosed = 1 then
  For I := 1 to Count - 2 do
   For J := I + 1 to Count - 3 do
    If TogsPoint(fList[I]).Equals(TogsGeometry(fList[J])) = 1 then begin
     Result := 1; exit;
    end;
end;

function TogsLineString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer; P1, P2: TogsDot;
begin
 Result := 0 ;
 If calcLength in Action then begin
  fLength := 0;
  For I := 0 to fList.Count - 2 do begin
   P1 := TogsDot(fList[I]); P2 := TogsDot(fList[I+1]);
  // один из методов вычисления длины - обращение к методу ogsBasic.Meter
   fLength := fLength + P1.Distance(P2);
  end;
  Result := 1;
 end;
 If calcbBox in Action then inherited Calculate(Action);
end;

procedure TogsLineString.Draw(Drawer: TogsDrawer);
var I: Integer; fullVis: Boolean;
begin
 fullVis := ogsRect.VisibleAllIn(Drawer.ogsSelector.ActiveRect);
 For I := 0 to Count - 2 do begin
  Drawer.DrawLine(Point[I], Point[I+1], not fullVis);
 end;
end;

function TogsLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    Dist: Integer;
    P1, P2: TogsDot;
    PX, PY, Delta: Double;
begin
 Result:= False;
 If ckLine in Params.CaptureFor then begin
// проверяем на принадлежность ogsRect
// If not ((ogsSelector.pixDist(ogsRect.XMin - ogsRect.XMax) = 0) or
//         (ogsSelector.pixDist(ogsRect.YMin - ogsRect.YMax) = 0)) then
//   WriteIn(['Pix=',ogsSelector.pixDist(ogsRect.XMin - ogsRect.XMax)
//             ,ogsSelector.pixDist(ogsRect.YMin - ogsRect.YMax)]);
//  WriteIn(['Res=',ogsRect.XMin - ogsRect.XMax,ogsRect.YMin - ogsRect.YMax]);
   Delta := ogsSelector.geoDist(5);
   ogsRect.Inflate(Delta, Delta);
   If not Self.ogsRect.PointIn(X_,Y_) then begin
    ogsRect.Inflate(-Delta, -Delta);
    exit;
   end;
   ogsRect.Inflate(-Delta, -Delta);
 //
  For I := 0 to Count - 2 do begin
   P1 := List[I]; P2 := List[I+1];
   Dist := ogsSelector.pixDist(Dist_Point_Edge(X_,Y_,P1.X, P1.Y, P2.X, P2.Y, PX, PY));
   If Dist <= Params.CaptureParam then begin
    Params.resCapture := Dist;
    Params.resCaptureOf := ckLine;
    Params.resObject := Self;
    Result := Params.resCapture <= Params.CaptureParam;
    exit;
   end;
  end;
 end;
end;

{ TogsMultiLineString }

constructor TogsMultiLineString.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 checkTypeProc := @CheckogsLineType;
 fLength := -1;
end;

function TogsMultiLineString._Length: Double;
var I: Integer;
begin
 Result := 0;
 For I := 0 to Count -1 do Result := Result + Line[I].Length;
end;

function TogsMultiLineString.GetLine(Index: Integer): TogsLineString;
begin
 Result := fList[Index];
end;

function TogsMultiLineString.GetSquare: Double;
begin
 Result := -1;
end;

class function TogsMultiLineString.GeometryType: String;
begin
 Result := 'Multilinestring';
end;

procedure TogsMultiLineString.AddLine(Line: TogsLineString);
begin
 inherited Add(Line);
 ogsRect.InsertRect(Line.ogsRect);
end;

function TogsMultiLineString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 If calcLength in Action then begin
  fLength := 0;
  For I := 0 to Count - 1 do begin
   Line[I].Calculate([calcLength]);
   fLength := Line[I].Length;
  end;
 end else
  Result := inherited Calculate(Action);
end;

procedure TogsMultiLineString.Draw(Drawer: TogsDrawer);
begin
 inherited Draw(Drawer);
end;

function TogsMultiLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
begin
 Result := inherited SelectByPoint(X_, Y_, Params);
end;

function TogsMultiLineString.UpdateSpatialProperties(var spatialProps: TogsPropValue;
 OnlyGeometry: Boolean): Integer;
var I: integer;
    propItem: TogsPropValue;
begin
 If OnlyGeometry then begin // добавляем только геометрию
  If spatialProps = nil then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps = nil');
  With spatialProps.AddItem(TogsPropArray.Create) do begin
   propItem := propValue;
   For I := 0 to Self.Count - 1 do
    Line[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
  end;
 end else begin // добавляем геометрию с заголовком
  spatialProps := TogsProperty.Create('geometry', TogsPropObject.Create);
 //
  With spatialProps do begin
   propValue.AddItem(TogsProperty.Create('type', TogsPropString.Create({'"' +} GeometryType {+ '"'})));
    With propValue.AddItem(TogsProperty.Create('coordinates', TogsPropArray.Create)) do begin
     propItem := propValue;
    // WriteIn(['CreatePolyJSON']);
     For I := 0 to Self.Count - 1 do
      Line[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
    end;
   // WriteIn(['EndPolyJSON']);
  end;
 end;
 Result := Count;
end;

{ TPoly_Single }

procedure TPoly_Single.SetParent(AValue: Pointer);
begin
 if fParent = AValue then exit;
 fParent:=AValue;
 PolyMode.nullParent := Parent = nil;
end;

function TPoly_Single.GetSquare: Double;
begin
 Result := fSquare;
end;

constructor TPoly_Single.Create(ogsSelector_: TogsSelector = nil);
begin
 inherited Create(ogsSelector_);
 checkTypeProc := @CheckogsDotType;
 fSquare := -1;
end;

function TPoly_Single.Calculate(Action: TCalcActionSet): Integer;
begin
 If calcSquare in Action then begin
  Result := Orientation_of_polygon(Self, fSquare);
  PolyMode.clockWise := Result <> -1;
//  WriteIn(['Lot',Square,'Clock,isHole',PolyMode.clockWise,PolyMode.isHole]);
 end;
 If calcbBox in Action then inherited Calculate(Action);
end;

procedure TPoly_Single.Rotate(clockWise: Integer);
var I: Integer; P: Pointer;
begin
 If clockWise <> 0 then PolyMode.clockWise := clockWise <> -1;
// поворот
 For I:= List.Count-1 downTo 0 do begin List.Add(List[I]); List[I]:=nil; end;
 List.Pack;
// PolyMode
 If clockWise <> 0 then PolyMode.clockWise := not PolyMode.clockWise;
end;

function TPoly_Single.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    Res: Integer;
begin
 Result:= False;
 If ckPolygon in Params.CaptureFor then begin
  If Square = -1 then begin
   raise Exception.Create('TPoly_Single.Square = -1'); // обработка ошибки, добавление в протокол
  // exit;
  end;
 // проверяем на принадлежность ogsRect
// WriteIn(['Poly=',ogsRect.XMin, ogsRect.YMin, ogsRect.XMin, ogsRect.YMax]);
 If not ogsRect.PointIn(X_,Y_) then exit;
 //
  Res := point_and_polygon(X_, Y_, Self);
 // точка на линии или в полигоне
  If Res <> - 1 then begin
   Params.resCapture := 0;
   Params.resCaptureOf := ckSinglePolygon;
   Params.resObject := Self;
   Result := True;
  end;
 end;
end;

function TPoly_Single.PolygonIn(Poly: TPoly_Single; var touchCount: Integer): Integer;
var I: Integer;
    Res, fullEntryCount: Integer;
begin
 Result := -1; touchCount := 0; fullEntryCount := 0;
 If not ogsRect.VisibleIn(Poly.ogsRect) then exit;
 // при расчете соприкосновения точек не берем последнюю,поэтому Count - 2
// Writeln('PolygonIn=========================');
 For I := 0 to Count - 2 do With TDot(List[I]) do
  If Poly.ogsRect.PointIn(X, Y) then begin
//   Writeln('1=====',X:8:3, Y:8:3,' ',point_and_polygon(X, Y, Poly));
//   Writeln('2=====',X:8:3, Y:8:3,' ',point_and_polygon(X, Y, Poly));
//   Writeln('3=====',X:8:3, Y:8:3,' ',point_and_polygon(X, Y, Poly));
//   Writeln('4=====',X:8:3, Y:8:3,' ',point_and_polygon(X, Y, Poly));
   Res := point_and_polygon(X, Y, Poly);
  // WriteIn(['Res=',Res]);
   If Res = -1 then exit else
    If Res = 0 then Inc(touchCount) else
     If Res = 1 then Inc(fullEntryCount) else
  end else exit;
// WriteIn(['Touch&Entry',touchCount,fullEntryCount]);
// если полное вхождение Result = 0, если касание Result = кол-во касаний
 If touchCount <> 0 then Result := touchCount else Result := 0;
// If Result > 0 then
//  Writeln('touches=',Result);
// Writeln('EndPolygonIn=========================', Result);
end;

{ TogsPolygon }

constructor TogsPolygon.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 checkTypeProc := @CheckPoly_SignType;
 fSquare := -1;
end;

constructor TogsPolygon.CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
var I: Integer;
procedure ImportPolygon(propArray: TogsPropValue; isHole: boolean);
var I: Integer;
    Poly: TPoly_Single;
begin
 Poly := TPoly_Single.CreateJSON(propArray, nil, ogsSelector_);
// WriteIn(['isHole',isHole]);
 Poly.Calculate([calcSquare]);
 AddPolygon(Poly);
 ogsRect.InsertRect(Poly.ogsRect);
end;
begin
 Create(ogsSelector_);
// WriteIn(['Poly================',jsonSpatialArray.Count,jsonSpatialArray.Item[0].Count]);
// WriteIn(['TextPoly',jsonSpatialArray.ToString]);
// If jsonSpatialArray.Count < 2  then exit;
// WriteIn(['Poly================']);
// считываем последовательно полигоны и дырки в коллекцию TPoly_Single
 For I := 0 to jsonSpatialArray.Count - 1 do begin
  ImportPolygon(jsonSpatialArray.Item[I], I > 0);
 end;
 Calculate([calcRelation,calcSquare]);
 inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
// WriteIn(['Poly================']);
end;

procedure TogsPolygon.AddPolygon(Polygon: TPoly_Single);
begin
 fList.Add(Polygon);
 ogsRect.InsertRect(Polygon.ogsRect);
end;

function TogsPolygon.GetPolygon(Index: Integer): TPoly_Single;
begin
 Result := TPoly_Single(fList[Index]);
end;

function TogsPolygon.GetSquare: Double;
begin
 Result := fSquare;
end;

class function TogsPolygon.GeometryType: String;
begin
 Result := 'Polygon';
end;

function TogsPolygon.CalcSquares: Integer;
var I:Integer;
    Poly: TPoly_Single;
begin
// ogsRect.Clear;;
 fSquare := 0;
// Writeln('CalcSquare==============',Count);
 For I := 0 to Count - 1 do begin
  Poly := Polygon[I];
  Poly.Calculate([calcSquare]);
//  Writeln('Square=',Poly.Square,' ',Poly.PolyMode.clockWise);
//  ogsRect.InsertRect(Poly.ogsRect);
  If Poly.Square <> -1 then begin
   If Poly.PolyMode.clockWise then fSquare := fSquare + Poly.Square else
                                   fSquare := fSquare - Poly.Square;
  end
  else begin
  // не может быть площади = -1 -> обработчик ошибок
   Result := 0;
   raise Exception.Create('TogsPolygon.Square = -1'); // временно -> протокол ошибок
  end;
 end;
// Writeln('EndCalcSquare ==============',fSquare);
 Result := 1;
end;

function TogsPolygon.CalcRelations: Integer;
var I :Integer;
    SortedCol: TogsSortedCollection;
    Poly: TPoly_Single;
    Nesting, Orientation: Integer;
Procedure CalcPolyRelation(PolyI: TPoly_Single; Index: Integer);
var J: Integer; PolyJ: TPoly_Single;
    touchCount: Integer;
begin
 For J := Index - 1 downto 0 do begin
  PolyJ := Polygon[J];
  If PolyJ = PolyI then continue;
  If PolyI.PolygonIn(PolyJ, touchCount) = - 1 then continue;
   PolyI.Parent := PolyJ;
   PolyI.PolyMode.touchPoint := touchCount > 1;
   exit;
 end;
// если полигон PolyI не принадлежит -> ошибка TogsPolygon
// raise Exception.Create('TogsPolygon incorrect relation'); // обработка ошибки
end;
Function CalcNesting(Poly: TPoly_Single): Integer;
begin
 Result := 0;
 While Poly.Parent <> nil do begin
  Inc(Result);
  Poly := TPoly_Single(Poly.Parent);
 end;
end;
begin
 Result := 0;
 If Count = 0 then exit;
 // сортировка
 SortByProc(SortBySquareProc, True);
 // обнуляем Parent всех полигонов
// Writeln('InRelations================', Count);
 For I := 0 to Count - 1 do begin
 // Writeln('Square=',Polygon[I].Square);
  Polygon[I].Parent := nil;
  Polygon[I].PolyMode.nullParent := True;                         
 // Polygon[I].PolyMode.multiPoly := False;
 end;
// Writeln('EndInRelations================');
 // вычисляем отношения между полиглнами в порядке сортировки
 // вычисляем принадлежность
 For I := Count - 1 downto 1 do CalcPolyRelation(Polygon[I], I);
 // поворот полигонов
 // поворачиваем основной полигон по часовой (дырка - PolyMode.ClockWise = false)
 Orientation := orientation_of_polygon(Polygon[0], Polygon[0].fSquare);
 If Orientation = -1 then Polygon[0].Rotate(Orientation);
 // остальные полигоны
 For I := 0 to Count - 1 do
  If Polygon[I].Parent <> nil then begin
   Poly := Polygon[I];
 //  WriteIn(['hasParent=',I, ' ptCount=',Poly.Count, Poly.fSquare, TPoly_Single(Poly.Parent).fSquare]);
   Orientation := orientation_of_polygon(Poly, Poly.fSquare);
   Nesting := CalcNesting(Poly);              
  // поворот полигшона если ыложенность
   Poly.PolyMode.nullParent := False;
   If odd(Nesting) and (Orientation = 1) then Poly.Rotate(Orientation) else
   If not odd(Nesting) and (Orientation = -1) then Poly.Rotate(Orientation);
  end else begin
  // полигон без Parent = ogsMultiPolygon
  // !!! raise Exception.Create(Fmt(['Полигон без Parent. Index =',I])); //!!! временно, нужен обработчик ошибок
   Poly := Polygon[I];
 //  WriteIn(['noPerent=',I, ' ptCount=',Poly.Count, Poly.Square]);
  // поворачиваем по часовой стрелке, как основной полигон
   Orientation := orientation_of_polygon(Poly, Poly.fSquare);
   If Orientation = -1 then Poly.Rotate(Orientation);
   Poly.PolyMode.nullParent:= True;
  end;
end;

function TogsPolygon.isMultiPolygon: Boolean;
var I: Integer;
begin
 Result := False;
 For I := 1 to Count - 1 do
  If (Polygon[I].PolyMode.nullParent) or (Polygon[I].PolyMode.ClockWise) then begin
   Result := True;
   exit;
  end;
end;

function TogsPolygon.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 Result := 0;
// порядок  -> [calcRelation, calcSquare]
 If calcRelation in Action then Result := CalcRelations;
 If calcSquare in Action then Result := CalcSquares;
 If calcSortBy in Action then Result := SortByProc(SortBySquareProc, True);
 If calcbBox in Action then begin
  ogsRect.Clear;
  For I := 0 to Count - 1 do begin
   Polygon[I].Calculate([calcbBox]);
   ogsRect.InsertRect(Polygon[I].ogsRect);
  end;
 end;
end;

type

 { TTmp_Poly - наследник TPoly_Single для процедуры отсечения }

 TTmp_Poly = class(TPoly_Single)
  constructor Create(PolyMode_: TPolyMode; Points: TogsCollection);
  destructor Destroy; override;
 end;

{ TTmpPoly }

constructor TTmp_Poly.Create(PolyMode_: TPolyMode; Points: TogsCollection);
var I: Integer;
begin
 PolyMode := PolyMode_;
 List.Free; List := Points.List;
// чтобы не уничтожить Points.List <> nil при вызове деструктора Points.Destroy
 Points.List := nil;
end;

destructor TTmp_Poly.Destroy;
begin
 inherited Destroy;
end;

procedure TogsPolygon.Draw(Drawer: TogsDrawer);
Label 1;
var I, J: Integer;
    Clipped: Boolean;
    Poly: TPoly_Single;
    Points: TogsCollection;
    Polygs: TogsCollection;
function ClipProc(): Boolean;
var I: Integer;
begin
 For I := 0 to Poly.Count - 1 do Points.List.Add(TogsDot.CreateAs(Poly.List[I]));
  With Drawer.ogsSelector.ActiveRect do
   Result := clip_polygon(XMin, YMin, XMax, YMax, Points) > 1;
 // Result := True;
end;
begin
// exit;
 goto 1;
// WriteIn([I,Polygon[I].PolyMode.clockWise]);
// собираем только видимые полигоны TogsPolygon
 Polygs := TogsCollection.Create(Count);
 For I := 0 to Count - 1 do begin
  Poly := Polygon[I];
//  With Poly.ogsRect do WriteIn(['PolySign.Rect=',XMin, YMin, XMAx, YMax]);
  // если полигон полностью в ogsSelector.ActiveRect - > не выполняем клипирование
  if Poly.ogsRect.VisibleAllIn(Drawer.ogsSelector.ActiveRect) then begin
  // WriteIn(['AllVisible']);
   Points := TogsCollection.Create(Poly.Count);
   For J := 0 to Poly.Count -1 do Points.List.Add(TogsDot.CreateAs(Poly.List[J]));
   Polygs.Add(TTmp_Poly.Create(Poly.PolyMode, Points));
   Points.Free;
  end else
  // клиппируем
  If (I = 0) or Poly.Visible(Drawer.ogsSelector.ActiveRect) then begin
   Points := TogsCollection.Create(Poly.Count);
  // если отсечение успещно -> создаем полигон с указанием Poly.PolyMode
  // для учета дырок при рисовании
   Clipped := ClipProc;
   If Clipped then begin
    Polygs.Add(TTmp_Poly.Create(Poly.PolyMode, Points));
   // WriteIn(['PolyIndex=',I,'pCount=',TTmp_Poly(Polygs[Polygs.Count -1 ]).Count]);
   end;// else WriteIn(['PolyIndex=',I,'NOTCLIPPED']);
   Points.Free;
   If not Clipped and (I = 0) then break;
  end;
 end;
// вызываем метод для отрисовки Polygs
// WriteIn(['PolyC=',Polygs.Count]);
// If Count = 1 then Drawer.Brush.brColor := clSilver else
//                   Drawer.Brush.brColor := clMoneyGreen;
 Drawer.DrawPolyPolygon(Polygs, ogsRect);
//
 Polygs.Free;
//exit;
1:For I := 0 to Count - 1 do begin
   Polygon[I].Draw(Drawer);
  end;
end;

procedure TogsPolygon.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do begin
  Polygon[I].DrawPoint(Drawer);
 end;
end;

function TogsPolygon.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I:Integer; Params1: TCaptureRec;
begin
 Result := False;
// использовалось для отладки поворота полигонов
//!!! CalcRelations;
 Params1 := CRClearParams;                     
 If ckPolygon in Params.CaptureFor then begin
//  With ogsRect do WriteIn(['Select.Rect=', XMin, XMax, YMin, YMax]);
  If not ogsRect.PointIn(X_,Y_) then exit;
  For I := Count - 1 downto 0 do
  // если не дырка -> проверяем на вхождение
   If Polygon[I].PolyMode.clockWise then begin
    Result := Polygon[I].SelectByPoint(X_,Y_,Params);
  //  WriteIn(['Poly=',I,'Res=', Result, 'pCount=', Polygon[I].Count, 'Square=',Polygon[I].Square]);
    If Result then exit;
   end else //!!! проверять дырки  If not Params.ignoreHoles then
  //  WriteIn(['Hole=',I,' Res=',Polygon[I].SelectByPoint(X_,Y_,Params1),'pCount=', Polygon[I].Count, 'Square=',Polygon[I].Square]);
   If Polygon[I].SelectByPoint(X_,Y_,Params1) then begin
   // если дырка -> установим параметр
    Result := False; exit;
   end;
 end;
end;

function TogsPolygon.UpdateSpatialProperties(var spatialProps: TogsPropValue;
 OnlyGeometry: Boolean): Integer;
var I: integer;
    propItem: TogsPropValue;
begin
 If OnlyGeometry then begin // добавляем только геометрию
  If spatialProps = nil then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps = nil');
  With spatialProps.AddItem(TogsPropArray.Create) do begin
   propItem := propValue;
   For I := 0 to Self.Count - 1 do
    Polygon[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
  end;
 end else begin // добавляем геометрию с заголовком
  spatialProps.AddItem(TogsProperty.Create('geometry', TogsPropObject.Create));
 //
  With spatialProps do begin
   propValue.AddItem(TogsProperty.Create('type', TogsPropString.Create({'"' +} GeometryType {+ '"'})));
    With propValue.AddItem(TogsProperty.Create('coordinates', TogsPropArray.Create)) do begin
     propItem := propValue;
    // WriteIn(['CreatePolyJSON']);
     For I := 0 to Self.Count - 1 do
      Polygon[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
    end;
   // WriteIn(['EndPolyJSON']);
  end;
 end;
 Result := Count;
end;

{ TogsMultiPolygon }

constructor TogsMultiPolygon.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 CheckTypeProc := @CheckogsPolygonType;
 fSquare := -1;
 fogsProperties := nil;
end;

constructor TogsMultiPolygon.CreateJSON(jsonSpatialArray, jsonProperties: TogsPropValue; ogsSelector_: TogsSelector);
var I, J: Integer; ogsPoly: TogsPolygon;
begin
 Create(ogsSelector_);
// считываем последовательно полигоны и дырки в коллекцию TogsPolygon
// WriteIn(['MultiPolyC=',jsonSpatialArray.Count]);
// WriteIn([jsonSpatialArray.item[0].ToString]);
// WriteIn([jsonSpatialArray.item[1].ToString]);
 For I := 0 to jsonSpatialArray.Count - 1 do begin
//  WriteIn(['jsonSpatialArray.Item',I,'Cnt=',jsonSpatialArray.Item[0].count,'Cnt2=',jsonSpatialArray.Item[0].Item[0].Count]);
  ogsPoly := TogsPolygon.CreateJSON(jsonSpatialArray.Item[I], nil, ogsSelector_);
  ogsPoly.Calculate([calcSquare]);
  AddPolygon(ogsPoly);
  ogsRect.InsertRect(ogsPoly.ogsRect);
 end;
 Calculate([calcSquare]);
 //
 inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
end;

procedure TogsMultiPolygon.AddPolygon(Polygon: TogsPolygon);
begin
 fList.Add(Polygon);
 ogsRect.InsertRect(Polygon.ogsRect);
end;

procedure TogsMultiPolygon.AddMultiPoly(ogsPolygon: TogsPolygon);
const add_with_parent = 1;
      add_without_parent = 0;
var I: Integer;
procedure CreatePolygon(Poly_Single: TPoly_Single; Index: Integer; Flag: Integer);
var Poly: TogsPolygon;
    I: Integer;
begin
 Poly := TogsPolygon.Create(ogsSelector);
 Poly.AddPolygon(Poly_Single);
 AddPolygon(Poly);
// добавляем полигон
  For I := Index + 1 to ogsPolygon.Count - 1 do
   If ogsPolygon.Polygon[I].Parent = Poly_Single then
   // добавляем дырку в полигон
    Poly.AddPolygon(ogsPolygon.Polygon[I]) else begin
   // добавляем
     //CreatePolygon();
    end;
 // добавляем полигон
end;
begin
// вставляем самостоятельные полигоны
 Writeln('AddMulti.Count', ogsPolygon.Count);
 For I := 0 to ogsPolygon.Count - 1 do begin
  Writeln('I=', I, ' ', ogsPolygon.Polygon[I].Parent = nil);
  If (ogsPolygon.Polygon[I].Parent = nil) or (ogsPolygon.Polygon[I].PolyMode.ClockWise) then
   CreatePolygon(ogsPolygon.Polygon[I], I, add_with_parent);
 end;
 Writeln('AddMulti.end=', Count);
// очищаем коллекцию полигонов ogsPolygon
 ogsPolygon.DeleteAll;
end;

function TogsMultiPolygon.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
    Poly: TogsPolygon;
begin
 Result := 0;
 If calcSquare in Action then begin
  For I := 0 to Count - 1 do begin
   Poly := Polygon[I];
   If Poly.Square <> -1 then fSquare := fSquare + Poly.Square
   else
    // обработчик ошибок
  end;
  Result := 1;
 end;
 If calcbBox in Action then begin
  ogsRect.Clear;
  For I := 0 to Count - 1 do begin
   Polygon[I].Calculate([calcbBox]);
   ogsRect.InsertRect(Polygon[I].ogsRect);
  end;
 end;
end;

function TogsMultiPolygon.GetPolygon(Index: Integer): TogsPolygon;
begin
 Result := TogsPolygon(flist[Index]);
end;

function TogsMultiPolygon.GetSquare: Double;
begin
 Result := fSquare;
end;

class function TogsMultiPolygon.GeometryType: String;
begin
 Result := 'Multipolygon';
end;

procedure TogsMultiPolygon.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
// WriteIn(['MultiPoly.Color=',Drawer.penColor, 'cnt=',Count]);
 For I := 0 to Count - 1 do begin
  Polygon[I].Draw(Drawer);
 end;
end;

procedure TogsMultiPolygon.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
    C: TColor;
begin
 C := Drawer.Pen.Color;
 If Selected then Drawer.Pen.penColor := clLime;
 For I := 0 to Count - 1 do begin
  Polygon[I].DrawPoint(Drawer);
 end;
 Drawer.Pen.Color := C;
end;

function TogsMultiPolygon.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I:Integer;
begin
 Result := False;
 If ckPolygon in Params.CaptureFor then
  For I := 0 to Count - 1 do begin
   Result := Polygon[I].SelectByPoint(X_,Y_,Params);
   If Result then exit;
  end
 else;
end;

function TogsMultiPolygon.UpdateSpatialProperties(
 var spatialProps: TogsPropValue; OnlyGeometry: Boolean): Integer;
var I: integer;
    propItem: TogsPropValue;
begin
 If OnlyGeometry then begin // добавляем только геометрию
  If spatialProps = nil then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps = nil');
  With spatialProps.AddItem(TogsPropArray.Create) do begin
   propItem := propValue;
   For I := 0 to Self.Count - 1 do
    Polygon[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
  end;
 end else begin // добавляем геометрию с заголовком
  spatialProps := TogsProperty.Create('geometry', TogsPropObject.Create);
 //
  With spatialProps do begin
   propValue.AddItem(TogsProperty.Create('type', TogsPropString.Create({'"' +} GeometryType {+ '"'})));
    With propValue.AddItem(TogsProperty.Create('coordinates', TogsPropArray.Create)) do begin
     propItem := propValue;
    // WriteIn(['CreatePolyJSON']);
     For I := 0 to Self.Count - 1 do
      Polygon[I].UpdateSpatialProperties(propItem, {OnlyGeometry} True);
    end;
   // WriteIn(['EndPolyJSON']);
  end;
 end;
 Result := Count;
end;

initialization
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsDot, 200, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPoint, 201, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsMultiPoint, 202, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsLineString, 203, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsGeometryCollection, 204, 1));
end.

