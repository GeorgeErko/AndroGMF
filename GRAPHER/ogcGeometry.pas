unit ogcGeometry;

interface

uses Classes, SysUtils, System.UITypes, System.JSON, ogcBasic, ogcProperties,
     ogcMathUtils, ogcClipPolyline;

type
  TogsMultiPoint = class;
  TogsLineString = class;

 { TogsGeometryCollection }

  TogsGeometryCollection = class(TogsSimpleGeometrySet)
  private
  //
   fogsSelector: TogsSelector;
   fogsProperties: TJSONObject;
   fSelected: boolean;
   fOgsID: Int64;
   fRenderOrder: Integer;
   function GetogsID: Int64; override;
   procedure SetogsID(AValue: Int64); override;
   function GetRenderOrder: Integer; override;
   procedure SetRenderOrder(AValue: Integer); override;
  // старые ф-ции
  // убираем метод Add из публичных объявлений
  // чтобы не дать возможность добавлять неконтролируемые данные
  // к примеру: добавление точки методом AddPoint(X, Y, Z),
  // приводит к пересчету габаритов примитива, а если использовать
  // Add(TogsDot.Create(...)) произойдет неконтролируемое добавление точки
  // function Add(Item_: Pointer): Integer; override;
  //   function GetTransactionID: Integer; override;
//   procedure SetTransactionID(AValue: Integer); override;
  //
   function Add(Item_: TogsGeometry): Integer; override;

  // корневой объект GeoJSON "properties": {name: <values>...} - TJSONObject
  // конструктор CreateJSON(jsonSpatialArray - массив "coordinates",
  //                        jsonProperties - объект "properties") создает копию свойств
  // при экспорте в JSON (ToString) формируется GeoJSON Feature:
  // {"type": "Feature", "geometry": {...}, "properties": {...}}
   function GetogsSelector: TogsSelector; override;
   function GetogsProperties: TogsProperties; override;
   procedure SetogsProperties(AValue: TogsProperties);override;
  //
   function GetItem(Index: Integer): TogsGeometry;
   procedure SetItem(Index: Integer; AValue: TogsGeometry);
  //
   function GetSelected: boolean; override;
   procedure SetSelected(AValue: boolean); override;
  //
  protected
   procedure SetogsSelector(Data: TogsSelector); override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
   constructor CreateAs(ogsObject:TogsBasic); override;
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector = nil);
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   procedure Clear; override;
  //
   function CreateSysProperties(strTemplate: String): TogsProperties; override;
  // OnlyGeometry = True  -> в массив spatialProps (TJSONArray) добавляются координаты
  // OnlyGeometry = False -> в объект spatialProps (TJSONObject, создается при nil)
  //                         добавляется пара "geometry": {"type", "coordinates"}
   function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: boolean = False): Integer; virtual;
  //
   function numGeometries (): Integer; virtual;
   function GeometryN (N: Integer): TogsGeometry; virtual;
   property Item[Index: Integer]: TogsGeometry read GetItem write SetItem; default;
  //
   property ogsProperties: TogsProperties read GetogsProperties write SetogsProperties;
  // "properties" Feature при экспорте: копия ogsProperties + служебные поля
  // наследников (результат освобождает вызывающий)
   function FeatureProperties: TJSONObject; virtual;
   function ToString: String; override;
  // GeometryCollection -> FeatureCollection из элементов (вложенные коллекции
  // раскрываются в тот же список), остальные наследники -> Feature
   function StoreGeoJSON(Stream: TogsStream): Integer; override;
  //
   function Visible(Rect: TogsRect): Boolean; override;
  //
   function SortByProc(sortProc: TListSortCompare; Duplicates_: Boolean): Integer;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  // Draw
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  // для отображения
  //
   function FindAttribute(AttrName_:String; out Prim: Pointer): Boolean; override;
  end;

 { TogsPoint - точка с bBox и семантикой }

  TogsPoint = class(TogsDot)
  private
   fogsRect: TogsRect;
   fogsSelector: TogsSelector;
   fogsProperties: TJSONObject;
   fSelected: Boolean;
   fOgsID: Int64;
   fRenderOrder: Integer;
   function GetogsID: Int64; override;
   procedure SetogsID(AValue: Int64); override;
   function GetRenderOrder: Integer; override;
   procedure SetRenderOrder(AValue: Integer); override;
  //
//   function GetTrasactionID: Integer; override;
//   procedure SetTransactionID(AValue: Integer); override;
  //
   function GetogsRect: TogsRect; override;
   function GetogsSelector: TogsSelector; override;
   function GetogsProperties: TogsProperties; override;
   procedure SetogsProperties(AValue: TogsProperties); override;
  //
   function GetSquare: Double; override;
  protected
   procedure SetogsSelector(Data: TogsSelector); override;
  public
   M: Double;
   class function GeometryType: String; override;
   constructor Create(X_, Y_, Z_: Double; ogsSelector_: TogsSelector = nil);
   constructor CreateAs(ogsObject: TogsBasic); override;
  // массив geoJSON "coordinates" = TJSONArray
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector = nil);
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure   Store(Stream: TogsStream); override;
   procedure Clear; override;
  // видимость
   function Visible(Rect: TogsRect): Boolean; override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   function GetSelected: boolean; override;
   procedure SetSelected(AValue: boolean); override;
  //
   function CreateSysProperties(strTemplate: String): TogsProperties; override;
   property ogsProperties: TogsProperties read GetogsProperties write SetogsProperties;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: Boolean = False): Integer; virtual;
   function FeatureProperties: TJSONObject; virtual;
   function ToString: String; override;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  end;

 { TogsMultiPoint - коллекция TogsPoint }

   TogsMultiPoint = class(TogsGeometryCollection)
   private
    function GetPoint(Index: Integer): TogsDot;
   public
    class function GeometryType: String; override;
    constructor Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
    constructor CreateAs(ogsObject: TogsBasic); override;
    constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector = nil);
    constructor Load(Stream: TogsStream); override;
    procedure Store(Stream: TogsStream); override;
   //
    function PointN(N: Integer): TogsDot; virtual;
    procedure AddPoint(X, Y, Z: Double); overload; virtual;
    procedure AddPoint(P: TogsDot); overload;
   // bBox
    function Calculate(Action: TCalcActionSet): Integer; override;
   // Paint
    procedure Draw(Drawer: TogsDrawer); override;
    procedure DrawPoint(Drawer: TogsDrawer); override;
   //
    property Point[Index: Integer]: TogsDot read GetPoint;default;
   // захват
    function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   // координаты в JSON
    function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: Boolean = False): Integer; override;
   end;

  { TogsLineString - одномерная коллекция TogsDot }

  TogsLineString = class(TogsMultiPoint)
  private
   fLength: Double;
  protected
   function _Length: Double; override;
   function GetSquare: Double; override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector);
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure AddPoint(X, Y, Z: Double); overload; override;
  //
   property Length: Double read _Length;
   function StartPoint (): TogsDot; override;
   function EndPoint (): TogsDot; override;
   function IsClosed (): Integer; override;
   function IsRing (): Integer; override;
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
 //  constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector = nil);
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector);
   constructor CreateAs(ogsObject: TogsBasic); override;
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
   function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: Boolean): Integer; override;
  end;

 { TPoly_Single - площадной объект -> наследник TogsLineString }

  TPolyMode = packed record
   clockWise : boolean; // ориентация полигона
   isCorrect : boolean; // корректность: замыкание, отношения полигонов
   touchPoint: boolean; // касание полигона Parent юолее чем в одной точке
   interWith : boolean; // взаимное пересечение
   nullParent: boolean; // Parent = nil
  // multiPoly : boolean; // составной полигон -> multiPolygon
   intersect : boolean; // пересекается с другим полигоном
   extTag2,
   extFlag   : boolean; // доп тэги, extTag используется в качестве доп. флажка
                        // при calcRelation
  // дырки неограниченной вложенности: внешний контур (оболочка) того
  // OGC-полигона, к которому относится контур.
  // Для оболочки (четная вложенность 0, 2, 4...) GlobalParent = сам контур,
  // для дырки (нечетная вложенность) GlobalParent = Parent.
  // Остров внутри дырки - самостоятельная оболочка -> TogsPolygon.isMultiPolygon.
  // В поток не записывается, вычисляется TogsPolygon.CalcGlobalParents
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
   Tag: Integer;
   constructor Create(ogsSelector_: TogsSelector = nil);
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
  //
   property Parent: Pointer read fParent write SetParent;
  // захват - точка в полигоне
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // если параметр clockWise = 0 -> при вращении не происходит установкf флага PoluMode.clockWise
   procedure Rotate(clockWise : Integer); override;
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
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure AddPolygon(Polygon: TPoly_Single);
   property Polygon[Index: Integer]: TPoly_Single read GetPolygon;
   property Square: Double read fSquare;
  //
   function CalcSquares: Integer;
   function CalcRelations: Integer;
  // PolyMode.GlobalParent всех контуров по уже вычисленным Parent
   procedure CalcGlobalParents;
  // количество оболочек (контуров с GlobalParent = сам контур)
   function ShellCount: Integer;
   function isMultiPolygon: Boolean;
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  // захват - точка в Polygon[Index], если полигон - не дырка
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: Boolean = False): Integer; override;
  end;

 { TogsMultiPolygon - коллекция TogsPolygon }

  TogsMultiPolygon = class(TogsGeometryCollection)
   fSquare: Double;
   function GetPolygon(Index: Integer): TogsPolygon;
   function GetSquare: Double; override;
  public
   class function GeometryType: String; override;
   constructor Create(ogsSelector_: TogsSelector = nil);
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure AddPolygon(Polygon: TogsPolygon);
  // разбор ogsPolygon (после calcRelation) на оболочки с дырками любой
  // вложенности по PolyMode.GlobalParent, контуры переходят в Self
  // MoveItems = False -> в Self добавляются копии контуров, ogsPolygon не меняется
   procedure AddMultiPoly(ogsPolygon: TogsPolygon; MoveItems: Boolean = True);
   property Polygon[Index: Integer]: TogsPolygon read GetPolygon;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // координаты в JSON
   function UpdateSpatialProperties(var spatialProps: TJSONValue; OnlyGeometry: Boolean = False): Integer; override;
  end;

// проверка типа добавляемых пространственных примитивов
 function CheckogsDotType(P: TogsBasic): Boolean;
 function CheckogsPointType(P: TogsBasic): Boolean;
 function CheckogsLineType(P: TogsBasic): Boolean;
 function CheckPoly_SignType(P: TogsBasic): Boolean;
 function CheckogsPolygonType(P: TogsBasic): Boolean;
// сортировка пространственных данных
 function SortBySquareProc(Item1, Item2: Pointer): Integer;
// каскадная запись GeoJSON: строка / файл UTF-8, результат - количество Feature
 function GeoJSONToString(Geom: TogsGeometry; out jsonStr: String): Integer;
 function GeoJSONToFile(Geom: TogsGeometry; const FileName: String): Integer;
// цвет TColor ($00BBGGRR) -> '#RRGGBB'
 function ColorToHex(Color: TColor): String;
// '#RRGGBB' -> TColor ($00BBGGRR), Default - при ошибке формата
 function HexToColor(const S: String; Default: TColor = 0): TColor;
// служебный раздел "ogs" в properties Feature (создается при отсутствии)
 function FeatureOgsSection(Props: TJSONObject): TJSONObject;

implementation uses Writer;

// упаковка флажков TPolyMode в байт (формат записи в поток, GlobalParent не пишется)
function PolyModeToByte(const PM: TPolyMode): Byte;
begin
 Result := Ord(PM.clockWise) or (Ord(PM.isCorrect) shl 1) or (Ord(PM.touchPoint) shl 2) or
           (Ord(PM.interWith) shl 3) or (Ord(PM.nullParent) shl 4) or (Ord(PM.intersect) shl 5) or
           (Ord(PM.extTag2) shl 6) or (Ord(PM.extFlag) shl 7);
end;

procedure ByteToPolyMode(B: Byte; var PM: TPolyMode);
begin
 PM.clockWise := B and 1 <> 0;
 PM.isCorrect := B and 2 <> 0;
 PM.touchPoint := B and 4 <> 0;
 PM.interWith := B and 8 <> 0;
 PM.nullParent := B and 16 <> 0;
 PM.intersect := B and 32 <> 0;
 PM.extTag2 := B and 64 <> 0;
 PM.extFlag := B and 128 <> 0;
 PM.GlobalParent := nil;
end;

// GeoJSON Feature из семантики Props и геометрии Geom
function FeatureToString(Props: TJSONObject; Geom: TJSONValue): String;
var Feature: TJSONObject;
    I: Integer;
begin
 Feature := TJSONObject.Create;
 try
  Feature.AddPair('type', 'Feature');
 // пара "geometry" из Geom переносится в Feature
  if Geom is TJSONObject then
   for I := 0 to TJSONObject(Geom).Count - 1 do Feature.AddPair(TJSONPair(TJSONObject(Geom).Pairs[I].Clone));
  if Props <> nil then Feature.AddPair('properties', TJSONObject(Props.Clone)) else Feature.AddPair('properties', TJSONNull.Create);
  Result := Feature.ToJSON;
 finally
  Feature.Free;
 end;
end;

// массив [X, Y] координат точки
function CoordToJSON(X, Y: Double): TJSONArray;
begin
 Result := TJSONArray.Create;
 Result.Add(X);
 Result.Add(Y);
end;

// пара "geometry": {"type": GeomType, "coordinates": Coords} в объект spatialProps
function AddGeometryPair(var spatialProps: TJSONValue; const GeomType: String; Coords: TJSONValue): TJSONObject;
begin
 if spatialProps = nil then spatialProps := TJSONObject.Create;
 if not (spatialProps is TJSONObject) then raise Exception.Create('UpdateSpatialProperties: spatialProps не является объектом JSON');
 Result := TJSONObject.Create;
 Result.AddPair('type', GeomType);
 Result.AddPair('coordinates', Coords);
 TJSONObject(spatialProps).SetItemValue('geometry', Result);
end;

function TogsGeometryCollection.GetogsID: Int64;
begin
 Result := fOgsID;
end;

procedure TogsGeometryCollection.SetogsID(AValue: Int64);
begin
 fOgsID := AValue;
end;

function TogsGeometryCollection.GetRenderOrder: Integer;
begin
 Result := fRenderOrder;
end;

procedure TogsGeometryCollection.SetRenderOrder(AValue: Integer);
begin
 fRenderOrder := AValue;
end;

function TogsPoint.GetogsID: Int64;
begin
 Result := fOgsID;
end;

procedure TogsPoint.SetogsID(AValue: Int64);
begin
 fOgsID := AValue;
end;

function TogsPoint.GetRenderOrder: Integer;
begin
 Result := fRenderOrder;
end;

procedure TogsPoint.SetRenderOrder(AValue: Integer);
begin
 fRenderOrder := AValue;
end;

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
 Result := 0;
 If TPoly_Single(Item1).Square < TPoly_Single(Item2).Square then Result := 1 else
 If TPoly_Single(Item1).Square > TPoly_Single(Item2).Square then Result := -1;
end;

{ TogsGeometryCollection }

constructor TogsGeometryCollection.Create(ogsSelector_: TogsSelector; Capacity_: Integer);
begin
 inherited Create(Capacity_);
 fogsSelector := ogsSelector_;
end;

constructor TogsGeometryCollection.CreateAs(ogsObject: TogsBasic);
var Obj: TogsGeometryCollection;
begin
 if not (ogsObject is TogsGeometryCollection) then raise Exception.Create(ClassName + 'CreateAs raised type conversion exception');
// элементы и габариты копируются в TogsSimpleGeometrySet.CreateAs
 inherited CreateAs(ogsObject);
 Obj := TogsGeometryCollection(ogsObject);
 fogsSelector := Obj.ogsSelector;
 fogsProperties := JSONCopy(Obj.fogsProperties);
end;

constructor TogsGeometryCollection.CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
begin
 If jsonProperties is TJSONObject then begin
  FreeAndNil(fogsProperties);
  fogsProperties := JSONCopy(TJSONObject(jsonProperties));
 end;
end;

destructor TogsGeometryCollection.Destroy;
begin
 FreeAndNil(fogsProperties);
 inherited Destroy;
end;

constructor TogsGeometryCollection.Load(Stream: TogsStream);
begin
// Stream.Read(fColorBy, SizeOf(fColorBy));
// Stream.Read(fColor, SizeOf(fColor));
 fogsSelector := Stream.ogsSelector;
 fogsProperties := Stream.GetJSON;
// Items + ogsRect
 inherited Load(Stream);
end;

procedure TogsGeometryCollection.Store(Stream: TogsStream);
begin
// Stream.Write(fColorBy, SizeOf(fColorBy));
// Stream.Write(fColor, SizeOf(fColor));
 Stream.PutJSON(fogsProperties);
 inherited Store(Stream);
end;

function TogsGeometryCollection.CreateSysProperties(strTemplate: String): TogsProperties;
begin
 FreeAndNil(fogsProperties);
 fogsProperties := JSONParseObject(strTemplate);
 if fogsProperties = nil then fogsProperties := TJSONObject.Create;
 Result := fogsProperties;
end;

class function TogsGeometryCollection.GeometryType: String;
begin
 Result := 'GeometryCollection';
end;

function TogsGeometryCollection.UpdateSpatialProperties(var spatialProps: TJSONValue;
 OnlyGeometry: boolean): Integer;
var Geometries: TJSONArray;
    Geom: TJSONValue;
    GeomObj: TJSONObject;
    I: Integer;
begin
 Result := 0;
 if OnlyGeometry then exit;
// GeoJSON GeometryCollection: "geometries": [{"type", "coordinates"}...]
 if spatialProps = nil then spatialProps := TJSONObject.Create;
 Geometries := TJSONArray.Create;
 for I := 0 to Count - 1 do begin
  Geom := nil;
  if Item[I] is TogsGeometryCollection then TogsGeometryCollection(Item[I]).UpdateSpatialProperties(Geom) else
  if Item[I] is TogsPoint then TogsPoint(Item[I]).UpdateSpatialProperties(Geom);
  if Geom is TJSONObject then begin
   Geometries.AddElement(TJSONObject(Geom).ItemByName['geometry'].Clone as TJSONValue);
   Inc(Result);
  end;
  Geom.Free;
 end;
 GeomObj := TJSONObject.Create;
 GeomObj.AddPair('type', GeometryType);
 GeomObj.AddPair('geometries', Geometries);
 TJSONObject(spatialProps).SetItemValue('geometry', GeomObj);
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
var I: Integer;
begin
 fogsSelector := Data;
 For I := 0 to Count - 1 do Item[I].ogsSelector := Data;
end;

function TogsGeometryCollection.Add(Item_: TogsGeometry): Integer;
begin
// raise Exception.Create('Вызов неконтролируемого добавления укзалеля в объект ' + ClassName);
 Result:=inherited Add(Item_);
end;

{function TogsGeometryCollection.GetogsRect: TogsRect;
begin
 Result := fogsRect;
end; }

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
 If fogsProperties = AValue then exit;
 If fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := AValue;
end;

function TogsGeometryCollection.numGeometries: Integer;
begin
 Result := List.Count;
end;

function TogsGeometryCollection.GeometryN(N: Integer): TogsGeometry;
begin
 Result := TogsGeometry(List[N]);
end;

function TogsGeometryCollection.FeatureProperties: TJSONObject;
begin
 Result := JSONCopy(fogsProperties);
end;

function TogsGeometryCollection.ToString: String;
var spatialProps: TJSONValue;
    Props: TJSONObject;
begin
 spatialProps := nil;
 Props := FeatureProperties;
 try
  UpdateSpatialProperties(spatialProps);
  Result := FeatureToString(Props, spatialProps);
 finally
  spatialProps.Free;
  Props.Free;
 end;
end;

function TogsGeometryCollection.StoreGeoJSON(Stream: TogsStream): Integer;
var I: Integer;
    Root: Boolean;
begin
// наследники-геометрии (MultiPoint, LineString, Polygon...) пишутся одним Feature
 if GeometryType <> 'GeometryCollection' then begin Result := inherited StoreGeoJSON(Stream); exit; end;
 Result := 0;
// корневая коллекция открывает FeatureCollection, вложенные пишут в ее список
 Root := Stream.ListLevel = 0;
 if Root then Stream.BeginList('{"type":"FeatureCollection","features":');
 for I := 0 to Count - 1 do Inc(Result, Item[I].StoreGeoJSON(Stream));
 if Root then Stream.EndList('}');
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
 //               2.список, дерево
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
 // WriteIn(['DrawGMCol=',Item[I].ClassNAme,Item[I].ogsRect.XMin,Item[I].ogsRect.XMax]);
  Item[I].Draw(Drawer);
 end;
end;

procedure TogsGeometryCollection.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do Item[I].DrawPoint(Drawer);
end;

function TogsGeometryCollection.FindAttribute(AttrName_: String; out
 Prim: Pointer): Boolean;
var I: Integer;
begin
 Prim := nil;
 For I := 0 to Count - 1 do
  If AnsiCompareText(AttrName_, Item[I].Attribute) = 0 then begin
   Prim := Items[I];
   Result := True;
   exit;
  end;
 Result := False;
end;

procedure TogsGeometryCollection.Clear;
begin
// fogsSelector.Clear;
 fogsRect.Clear;
 Items.FreeAll;
 FreeAndNil(fogsProperties);
end;

{ TogsPoint }

constructor TogsPoint.Create(X_, Y_, Z_: Double; ogsSelector_: TogsSelector = nil);
begin
 fX := X_;
 fY := Y_;
 Z := Z_;
 M := 0;
 fogsRect := TogsRect.Create;
 fogsRect.Insert(fX, fY);
 fogsSelector := ogsSelector_;
//!!! спорный вопрос при добавлении блоков и атрибутов
// If fOgsSelector <> nil then fogsSelector.AddCoord(X, Y);
end;

constructor TogsPoint.CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector = nil);
begin
 fogsRect := TogsRect.Create;
 fogsSelector := ogsSelector_;
 If jsonProperties is TJSONObject then
  fogsProperties := JSONCopy(TJSONObject(jsonProperties));
// по умолчанию однмерный массив [13420.363, 1753.199] с 2 значениями
 if (jsonSpatialArray = nil) or (jsonSpatialArray.ItemCount < 2) then exit; // добавить обработку ошибки
 fX := jsonSpatialArray.Item[0].AsFloat;
 fY := -jsonSpatialArray.Item[1].AsFloat;
 If jsonSpatialArray.ItemCount > 2 then
  Z := jsonSpatialArray.Item[2].AsFloat
 else
  Z := ZNull;
//  WriteIn(['Point_XY=', X, Y]);
 fogsRect.Insert(fX, fY);
 if fogsSelector <> nil then fogsSelector.AddCoord(fX, fY);
end;

constructor TogsPoint.CreateAs(ogsObject: TogsBasic);
var Obj: TogsPoint;
begin
 if not (ogsObject is TogsPoint) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 Obj := TogsPoint(ogsObject);
 fX := Obj.fX;
 fY := Obj.fY;
 Z := Obj.Z;
 M := Obj.M;
 fogsRect := TogsRect.CreateAs(Obj.ogsRect);
 fogsSelector := Obj.ogsSelector;
 fogsProperties := JSONCopy(Obj.fogsProperties);
end;

destructor TogsPoint.Destroy;
begin
 fogsRect.Free;
 FreeAndNil(fogsProperties);
 inherited Destroy;
end;

constructor TogsPoint.Load(Stream: TogsStream);
begin
 Stream.Read(fX, SizeOf(fX));
 Stream.Read(fY, SizeOf(fY));
 Stream.Read(Z, SizeOf(Z));
 Stream.Read(M, SizeOf(M));
// Stream.Read(fColorBy, SizeOf(fColorBy));
// Stream.Read(fColor, SizeOf(fColor));
 fogsRect := TogsRect(Stream.Get);
 if fogsRect = nil then begin
  fogsRect := TogsRect.Create;
  fogsRect.Insert(fX, fY);
 end;
 fogsProperties := Stream.GetJSON;
 fogsSelector := Stream.ogsSelector;
end;

procedure TogsPoint.Store(Stream: TogsStream);
begin
 Stream.Write(fX, SizeOf(fX));
 Stream.Write(fY, SizeOf(fY));
 Stream.Write(Z, SizeOf(Z));
 Stream.Write(M, SizeOf(M));
// Stream.Write(fColorBy, SizeOf(fColorBy));
// Stream.Write(fColor, SizeOf(fColor));
 Stream.Put(fogsRect);
 Stream.PutJSON(fogsProperties);
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
 Result := 1;
end;

// ogsProperties

function TogsPoint.GetogsProperties: TogsProperties;
begin
 Result := fogsProperties;
end;

procedure TogsPoint.SetogsProperties(AValue: TogsProperties);
begin
 If fogsProperties = AValue then exit;
 If fogsProperties <> nil then fogsProperties.Free;
 fogsProperties := AValue;
end;

function TogsPoint.CreateSysProperties(strTemplate: String): TogsProperties;
begin
 FreeAndNil(fogsProperties);
 fogsProperties := JSONParseObject(strTemplate);
 if fogsProperties = nil then fogsProperties := TJSONObject.Create;
 Result := fogsProperties;
end;

function TogsPoint.UpdateSpatialProperties(var spatialProps: TJSONValue;
 OnlyGeometry: Boolean): Integer;
begin
// если передаем только геометрию - > используем spatialProps
// в качестве контейнера от родительского объекта
// иначе -> создаем новую ветку JSON со всеми характеристиками
// Y хранится с обратным знаком (см. CreateJSON)
 If OnlyGeometry then begin
  If not (spatialProps is TJSONArray) then raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps не TJSONArray');
  TJSONArray(spatialProps).AddElement(CoordToJSON(X, -Y));
 end else
  AddGeometryPair(spatialProps, GeometryType, CoordToJSON(X, -Y));
 Result := 1; // добавлен одие элемент
end;

function TogsPoint.FeatureProperties: TJSONObject;
begin
 Result := JSONCopy(fogsProperties);
end;

function TogsPoint.ToString: String;
var spatialProps: TJSONValue;
    Props: TJSONObject;
begin
 spatialProps := nil;
 Props := FeatureProperties;
 try
  UpdateSpatialProperties(spatialProps);
  Result := FeatureToString(Props, spatialProps);
 finally
  spatialProps.Free;
  Props.Free;
 end;
end;

function GeoJSONToString(Geom: TogsGeometry; out jsonStr: String): Integer;
var Stream: TogsStream;
begin
 Stream := TogsStream.CreateStringStream('', Geom.ogsSelector);
 try
  Result := Geom.StoreGeoJSON(Stream);
  jsonStr := Stream.DataString;
 finally
  Stream.Free;
 end;
end;

function GeoJSONToFile(Geom: TogsGeometry; const FileName: String): Integer;
var Stream: TogsStream;
begin
 Stream := TogsStream.CreateFileStream(FileName, fmCreate, Geom.ogsSelector);
 try
  Result := Geom.StoreGeoJSON(Stream);
 finally
  Stream.Free;
 end;
end;

function ColorToHex(Color: TColor): String;
var C: Cardinal;
begin
 C := Cardinal(TColorRec.ColorToRGB(Color));
 Result := Format('#%.2x%.2x%.2x', [C and $FF, (C shr 8) and $FF, (C shr 16) and $FF]);
end;

function HexToColor(const S: String; Default: TColor): TColor;
var C: Integer;
begin
 Result := Default;
 if (Length(S) <> 7) or (S[1] <> '#') then exit;
 if not TryStrToInt('$' + Copy(S, 2, 6), C) then exit;
 Result := TColor(((C and $FF) shl 16) or (C and $FF00) or ((C shr 16) and $FF));
end;

function FeatureOgsSection(Props: TJSONObject): TJSONObject;
var Value: TJSONValue;
begin
 Value := Props.ItemByName['ogs'];
 if Value is TJSONObject then exit(TJSONObject(Value));
 Result := TJSONObject.Create;
 Props.SetItemValue('ogs', Result);
end;

{ TogsMultiPoint }

constructor TogsMultiPoint.Create(ogsSelector_: TogsSelector; Capacity_: Integer = 1);
begin
 inherited Create(ogsSelector_,Capacity_);
 Items.checkTypeProc := CheckogsDotType;
end;

constructor TogsMultiPoint.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsMultiPoint) then raise Exception.Create(ClassName + 'CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Items.checkTypeProc := CheckogsDotType;
end;

constructor TogsMultiPoint.CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
var I: Integer;
    X, Y, Z: Double;
    xyArray: TJSONValue;
begin
 Create(ogsSelector_);
 inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
 if (jsonSpatialArray = nil) or (jsonSpatialArray.ItemCount < 2) then exit; // // добавить обработку ошибок и предупреждение в протокол
//
 For I := 0 to jsonSpatialArray.ItemCount - 1 do begin
  xyArray := jsonSpatialArray.Item[I];
  If xyArray.ItemCount < 2 then break;
 //
  X := xyArray.Item[0].AsFloat;
  Y := -xyArray.Item[1].AsFloat;
  If xyArray.ItemCount > 2 then
   Z := xyArray.Item[2].AsFloat
  else
   Z := ZNull;
 //
  AddPoint(X, Y, Z);
  fogsRect.Insert(X, Y);
  if fogsSelector <> nil then fogsSelector.AddCoord(X, Y);
 end;
end;

function TogsMultiPoint.GetPoint(Index: Integer): TogsDot;
begin
 Result := TogsPoint(Items.List[Index]);
end;

class function TogsMultiPoint.GeometryType: String;
begin
 Result := 'MultiPoint';
end;

constructor TogsMultiPoint.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
end;

procedure TogsMultiPoint.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
end;

function TogsMultiPoint.PointN(N: Integer): TogsDot;
begin
 Result := TogsDot(Items.List[N]);
end;

procedure TogsMultiPoint.AddPoint(X, Y, Z: Double);
begin
 inherited Add(TogsPoint.Create(X, Y, Z, ogsSelector));
 ogsRect.Insert(X, Y);
end;

procedure TogsMultiPoint.AddPoint(P: TogsDot);
begin
 inherited Add(P);
 ogsRect.Insert(P.fX, P.fY);
end;

function TogsMultiPoint.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 Result := 0;
 If calcbBox in Action then begin
  ogsRect.Clear;
  For I := 0 to Count - 1 do With TogsGeometry(List[I]) do begin
 //  WriteIn(['Calc.I=',I,X,Y]);
   Self.ogsRect.InsertRect(ogsRect);
  If ogsMatrix <> nil then
//   With Self.ogsRect do WriteIn(['Count=', Count,'XY=',X,Y,'XY.Rect=',XMin, YMin, XMAx, YMax]);
  end;
//  If ogsMatrix <> nil  then  With ogsRect do WriteIn(['MP.Rect=',XMin, YMin, XMax, YMax]);
 end;
end;

procedure TogsMultiPoint.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do TogsDot(Items[I]).Draw(Drawer);
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
   Result := TogsDot(Items[I]).SelectByPoint(X_, Y_,Params);
   If Result then exit;
  end
 else
end;

function TogsMultiPoint.UpdateSpatialProperties(var spatialProps: TJSONValue;
 OnlyGeometry: Boolean): Integer;
var I: Integer;
    Coords: TJSONArray;
begin
// массив координат [[X, Y], ...], Y хранится с обратным знаком
 Coords := TJSONArray.Create;
 For I := 0 to Count -1 do Coords.AddElement(CoordToJSON(Point[I].X, -Point[I].Y));
 If OnlyGeometry then begin
  If not (spatialProps is TJSONArray) then begin
   Coords.Free;
   raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps не TJSONArray');
  end;
  TJSONArray(spatialProps).AddElement(Coords);
 end else
  AddGeometryPair(spatialProps, GeometryType, Coords);
 Result := Count;
end;

{ TogsLineString }

constructor TogsLineString.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 Items.checkTypeProc := CheckogsDotType;
 fLength := -1;
end;

constructor TogsLineString.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsLineString) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 fLength := TogsLineString(ogsObject).Length;
end;

constructor TogsLineString.Load(Stream: TogsStream);
begin
 Stream.Read(fLength, SizeOf(fLength));
 inherited Load(Stream);
end;

procedure TogsLineString.Store(Stream: TogsStream);
begin
 Stream.Write(fLength, SizeOf(fLength));
 inherited Store(Stream);
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
 Result := 'LineString';
end;

procedure TogsLineString.AddPoint(X, Y, Z: Double);
begin
 inherited Add(TogsDot.Create(X, Y, Z));
 fogsRect.Insert(X, Y);
end;

function TogsLineString.StartPoint: TogsDot;
begin
 Result := TogsDot(Items.List[0]);
end;

function TogsLineString.EndPoint: TogsDot;
begin
 Result := TogsDot(Items.List[Items.List.Count -1]);
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
    If TogsPoint(Items.List[I]).Equals(TogsGeometry(Items.List[J])) = 1 then begin
     Result := 1; exit;
    end;
end;

function TogsLineString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer; P1, P2: TogsDot;
begin
 Result := 0 ;
 If calcLength in Action then begin
  fLength := 0;
  For I := 0 to Items.List.Count - 2 do begin
   P1 := TogsDot(Items.List[I]); P2 := TogsDot(Items.List[I+1]);
  // один из методов вычисления длины - обращение к методу ogsBasic.Meter
   fLength := fLength + P1.Distance(P2);
  end;
  Result := 1;
 end;
 If calcbBox in Action then inherited Calculate(Action);
end;

procedure TogsLineString.Draw(Drawer: TogsDrawer);
var I: Integer;
    fullVis: Boolean;
    Parts: TogsCollection;
    Part: TogsPolyCollection;
begin
// WriteIn([Drawer.ogsSelector.ActiveRect]);
 // Drawer.ogsSelector.ActiveRect.Inflate(-2, -2);
 fullVis := ogsRect.VisibleAllIn(Drawer.ogsSelector.ActiveRect);
 if fullVis then begin
  Part := TogsPolyCollection.Create1(Count);
  //
   for I := 0 to Count - 1 do
    Part.Items.Add(TogsDot.Create(Point[I].X, Point[I].Y, 0));
  //
   Drawer.DrawPolyline(Part, False);
  Part.Free;
 end else begin
  Parts := ogcClipPolyline.ClipLineStringToRect(Items, Drawer.ogsSelector.ActiveRect);
//  WriteIn(['Parts=', parts.Count]);
  if Parts.Count > 0 then Drawer.DrawPolyPolyLine(Parts, False);
  Parts.Free;
 end;
 // Drawer.ogsSelector.ActiveRect.Inflate(2, 2);
end;

function TogsLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    Dist: Integer;
    P1, P2: TogsDot;
    PX, PY, Delta: Double;
begin
 Result:= False;
 If ckLine in Params.CaptureFor then begin
   Delta := ogsSelector.geoDist(5);
 //  ogsRect.Inflate(Delta, Delta);
   If not Self.ogsRect.PointIn(X_,Y_,Delta) then exit;
 //  ogsRect.Inflate(-Delta, -Delta);
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
 Items.checkTypeProc := CheckogsLineType;
 fLength := -1;
end;

constructor TogsMultiLineString.CreateAs(ogsObject: TogsBasic);
begin
 if not (ogsObject is TogsMultiLineString) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 fLength := TogsMultiLineString(ogsObject).Length;
 Items.checkTypeProc := CheckogsLineType;
end;

function TogsMultiLineString._Length: Double;
var I: Integer;
begin
 Result := 0;
 For I := 0 to Count -1 do Result := Result + Line[I].Length;
end;

function TogsMultiLineString.GetLine(Index: Integer): TogsLineString;
begin
 Result := Items.List[Index];
end;

function TogsMultiLineString.GetSquare: Double;
begin
 Result := -1;
end;

class function TogsMultiLineString.GeometryType: String;
begin
 Result := 'MultiLineString';
end;

procedure TogsMultiLineString.AddLine(Line: TogsLineString);
begin
 inherited Add(Line);
 ogsRect.InsertRect(Line.ogsRect);
end;

function TogsMultiLineString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 Result := 0;
 If calcLength in Action then begin
  fLength := 0;
  For I := 0 to Count - 1 do begin
   Line[I].Calculate([calcLength]);
   fLength := fLength + Line[I].Length;
  end;
  Result := 1;
 end;
 If calcbBox in Action then Result := inherited Calculate(Action - [calcLength]);
end;

procedure TogsMultiLineString.Draw(Drawer: TogsDrawer);
begin
 inherited Draw(Drawer);
end;

function TogsMultiLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
begin
 Result := inherited SelectByPoint(X_, Y_, Params);
end;

function TogsMultiLineString.UpdateSpatialProperties(var spatialProps: TJSONValue;
 OnlyGeometry: Boolean): Integer;
var I: integer;
    Coords: TJSONValue;
begin
// [[[X, Y], ...], ...] - массив линий
 Coords := TJSONArray.Create;
 For I := 0 to Count - 1 do Line[I].UpdateSpatialProperties(Coords, {OnlyGeometry} True);
 If OnlyGeometry then begin // добавляем только геометрию
  If not (spatialProps is TJSONArray) then begin
   Coords.Free;
   raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps не TJSONArray');
  end;
  TJSONArray(spatialProps).AddElement(Coords);
 end else // добавляем геометрию с заголовком
  AddGeometryPair(spatialProps, GeometryType, Coords);
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
 Items.checkTypeProc := CheckogsDotType;
 fSquare := -1;
end;

constructor TPoly_Single.CreateAs(ogsObject: TogsBasic);
var Obj: TPoly_Single;
begin
 if not (ogsObject is TPoly_Single) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Items.checkTypeProc := CheckogsDotType;
 Obj := TPoly_Single(ogsObject);
 fSquare := Obj.Square;
 PolyMode := Obj.PolyMode;
 PolyMode.GlobalParent := nil;
 Tag := Obj.Tag;
 //Parent := Obj.Parent;  - должно устанавливаться внешним полигоном TogsPolygon
end;

constructor TPoly_Single.Load(Stream: TogsStream);
var B: Byte;
begin
 Stream.Read(fSquare, SizeOf(fSquare));
 Stream.Read(B, SizeOf(B));
 ByteToPolyMode(B, PolyMode);
 Stream.Read(Tag, SizeOf(Tag)); // чтение индекса полигона Parent
 inherited Load(Stream);
end;

procedure TPoly_Single.Store(Stream: TogsStream);
var B: Byte;
    ParentIndex: Integer;
begin
 Stream.Write(fSquare, SizeOf(fSquare));
 B := PolyModeToByte(PolyMode);
 Stream.Write(B, SizeOf(B));
// индекс Parent в коллекции TogsPolygon (Tag контуров устанавливает TogsPolygon.Store)
 If Parent = nil then ParentIndex := -1 else ParentIndex := TPoly_Single(fParent).Tag;
 Stream.Write(ParentIndex, SizeOf(ParentIndex));
 inherited Store(Stream);
end;

function TPoly_Single.Calculate(Action: TCalcActionSet): Integer;
begin
 Result := 0;
 If calcSquare in Action then begin
  Result := Orientation_of_polygon(Items, fSquare);
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
  Res := point_and_polygon(X_, Y_, Items);
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
   Res := point_and_polygon(X, Y, Poly.Items);
  // WriteIn(['Res=',Res]);
   If Res = -1 then exit else
    If Res = 0 then Inc(touchCount) else
     If Res = 1 then Inc(fullEntryCount) else
  end else exit;
// WriteIn(['Touch&Entry',touchCount,fullEntryCount]);
// если полное вхождение Result = 0, если касание Result = кол-во касаний
 If touchCount <> 0 then Result := touchCount else Result := 0;
 If Result > 0 then
//  Writeln('touches=',Result);
// Writeln('EndPolygonIn=========================', Result);
end;

{ TogsPolygon }

constructor TogsPolygon.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 Items.checkTypeProc := CheckPoly_SignType;
 fSquare := -1;
end;

constructor TogsPolygon.CreateAs(ogsObject: TogsBasic);
var I, Index: Integer;
    Obj: TogsPolygon;
begin
 if not (ogsObject is TogsPolygon) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TogsPolygon(ogsObject);
 fSquare := Obj.Square;
 // восстанавливаем отношения Parent между копиями контуров по индексам оригинала
 For I := 0 to Obj.Count - 1 do begin
  Index := Obj.Items.IndexOf(Obj.Polygon[I].Parent);
  if Index = -1 then Polygon[I].Parent := nil else Polygon[I].Parent := Polygon[Index];
 end;
 CalcGlobalParents;
end;

constructor TogsPolygon.CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
var I: Integer;
procedure ImportPolygon(propArray: TJSONValue; isHole: boolean);
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
// считываем последовательно полигоны и дырки в коллекцию TPoly_Single
 if jsonSpatialArray <> nil then
  For I := 0 to jsonSpatialArray.ItemCount - 1 do
   ImportPolygon(jsonSpatialArray.Item[I], I > 0);
 Calculate([calcRelation,calcSquare]);
 inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
end;

constructor TogsPolygon.Load(Stream: TogsStream);
var I: Integer;
begin
 Stream.Read(fSquare, SizeOf(fSquare));
 inherited Load(Stream);
// устанавливаем Parent для полигонов из коллекции Items (Tag - индекс Parent)
 For I := 0 to Count - 1 do
  If (Polygon[I].Tag < 0) or (Polygon[I].Tag >= Count) then Polygon[I].Parent := nil else
    Polygon[I].Parent := Polygon[Polygon[I].Tag];
 CalcGlobalParents;
end;

procedure TogsPolygon.Store(Stream: TogsStream);
var I: Integer;
begin
// Tag = индекс контура, используется TPoly_Single.Store для записи индекса Parent
 For I := 0 to Count - 1 do Polygon[I].Tag := I;
 Stream.Write(fSquare, SizeOf(fSquare));
 inherited Store(Stream);
end;

procedure TogsPolygon.AddPolygon(Polygon: TPoly_Single);
begin
 Items.List.Add(Polygon);
 ogsRect.InsertRect(Polygon.ogsRect);
end;

function TogsPolygon.GetPolygon(Index: Integer): TPoly_Single;
begin
 Result := TPoly_Single(Items.List[Index]);
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
 Result := 0;
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
//  Writeln('Square=',Polygon[I].Square);
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
 Orientation := orientation_of_polygon(Polygon[0].Items, Polygon[0].fSquare);
 If Orientation = -1 then Polygon[0].Rotate(Orientation);
 // остальные полигоны
 For I := 0 to Count - 1 do
  If Polygon[I].Parent <> nil then begin
   Poly := Polygon[I];
 //  WriteIn(['hasParent=',I, ' ptCount=',Poly.Count, Poly.fSquare, TPoly_Single(Poly.Parent).fSquare]);
   Orientation := orientation_of_polygon(Poly.Items, Poly.fSquare);
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
   Orientation := orientation_of_polygon(Poly.Items, Poly.fSquare);
   If Orientation = -1 then Poly.Rotate(Orientation);
   Poly.PolyMode.nullParent:= True;
  end;
// оболочки и дырки любой вложенности
 CalcGlobalParents;
 Result := Count;
end;

procedure TogsPolygon.CalcGlobalParents;
var I, Nesting: Integer;
    Poly, P: TPoly_Single;
begin
 For I := 0 to Count - 1 do begin
  Poly := Polygon[I];
 // вложенность контура: 0, 2, 4.. - оболочка, 1, 3.. - дырка
  Nesting := 0;
  P := Poly;
  While P.Parent <> nil do begin
   Inc(Nesting);
   P := TPoly_Single(P.Parent);
  end;
  If odd(Nesting) then Poly.PolyMode.GlobalParent := Poly.Parent else Poly.PolyMode.GlobalParent := Poly;
 end;
end;

function TogsPolygon.ShellCount: Integer;
var I: Integer;
begin
 Result := 0;
 For I := 0 to Count - 1 do
  If Polygon[I].PolyMode.GlobalParent = Polygon[I] then Inc(Result);
end;

function TogsPolygon.isMultiPolygon: Boolean;
begin
// несколько оболочек: независимые полигоны (Parent = nil)
// или острова внутри дырок (четная вложенность > 0)
 Result := ShellCount > 1;
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
  constructor Create(PolyMode_: TPolyMode; var Points: TogsCollection);
  destructor Destroy; override;
 end;

{ TTmpPoly }

constructor TTmp_Poly.Create(PolyMode_: TPolyMode; var Points: TogsCollection);
var I: Integer;
begin
 PolyMode := PolyMode_;
 Items := Points;
// чтобы не уничтожить Points.List <> nil при вызове деструктора Points.Destroy
 Points := TogsCollection.Create;
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
 If Selected then goto 1;
// заливка контуров с дырками выполняется Drawer.DrawPolyPolygon
// (Skia: путь из всех контуров, правило EvenOdd) - тесселяция не требуется
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
//   WriteIn(['Pooints.Count = ', Points.Count]);
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
1:For I := 0 to Count - 1 do
   Polygon[I].Draw(Drawer)
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

function TogsPolygon.UpdateSpatialProperties(var spatialProps: TJSONValue;
 OnlyGeometry: Boolean): Integer;
var I: integer;
    Coords: TJSONValue;
    MultiPoly: TogsMultiPolygon;
begin
// полигон с островами внутри дырок в GeoJSON - MultiPolygon
// (внутри массива MultiPolygon - каждая оболочка отдельным полигоном)
 If isMultiPolygon then begin
  MultiPoly := TogsMultiPolygon.Create(ogsSelector);
  try
   MultiPoly.AddMultiPoly(Self, False);
   If OnlyGeometry then begin
    Result := 0;
    For I := 0 to MultiPoly.Count - 1 do Inc(Result, MultiPoly.Polygon[I].UpdateSpatialProperties(spatialProps, True));
   end else
    Result := MultiPoly.UpdateSpatialProperties(spatialProps, False);
  finally
   MultiPoly.Free;
  end;
  exit;
 end;
// [[[X, Y], ...], ...] - внешний контур и дырки
 Coords := TJSONArray.Create;
 For I := 0 to Count - 1 do Polygon[I].UpdateSpatialProperties(Coords, {OnlyGeometry} True);
 If OnlyGeometry then begin // добавляем только геометрию
  If not (spatialProps is TJSONArray) then begin
   Coords.Free;
   raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps не TJSONArray');
  end;
  TJSONArray(spatialProps).AddElement(Coords);
 end else // добавляем геометрию с заголовком
  AddGeometryPair(spatialProps, GeometryType, Coords);
 Result := Count;
end;

{ TogsMultiPolygon }

constructor TogsMultiPolygon.Create(ogsSelector_: TogsSelector);
begin
 inherited Create(ogsSelector_);
 Items.CheckTypeProc := CheckogsPolygonType;
 fSquare := -1;
end;

constructor TogsMultiPolygon.CreateAs(ogsObject: TogsBasic);
var Obj: TogsMultiPolygon;
begin
 if not (ogsObject is TogsMultiPolygon) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TogsMultiPolygon(ogsObject);
 fSquare := Obj.Square;
end;

constructor TogsMultiPolygon.CreateJSON(jsonSpatialArray, jsonProperties: TJSONValue; ogsSelector_: TogsSelector);
var I: Integer; ogsPoly: TogsPolygon;
begin
 Create(ogsSelector_);
// считываем последовательно полигоны и дырки в коллекцию TogsPolygon
 if jsonSpatialArray <> nil then
  For I := 0 to jsonSpatialArray.ItemCount - 1 do begin
   ogsPoly := TogsPolygon.CreateJSON(jsonSpatialArray.Item[I], nil, ogsSelector_);
   ogsPoly.Calculate([calcSquare]);
   AddPolygon(ogsPoly);
   ogsRect.InsertRect(ogsPoly.ogsRect);
  end;
 Calculate([calcSquare]);
 //
 inherited CreateJSON(jsonSpatialArray, jsonProperties, ogsSelector_);
end;

constructor TogsMultiPolygon.Load(Stream: TogsStream);
begin
 Stream.Read(fSquare, SizeOf(fSquare));
 inherited Load(Stream);
end;

procedure TogsMultiPolygon.Store(Stream: TogsStream);
begin
 Stream.Write(fSquare, SizeOf(fSquare));
 inherited Store(Stream);
end;

procedure TogsMultiPolygon.AddPolygon(Polygon: TogsPolygon);
begin
 Items.List.Add(Polygon);
 ogsRect.InsertRect(Polygon.ogsRect);
end;

procedure TogsMultiPolygon.AddMultiPoly(ogsPolygon: TogsPolygon; MoveItems: Boolean);
var I: Integer;
function TakeRing(Ring: TPoly_Single): TPoly_Single;
begin
 if MoveItems then Result := Ring else Result := TPoly_Single.CreateAs(Ring);
end;
procedure CreatePolygon(Shell: TPoly_Single; Index: Integer);
var Poly: TogsPolygon;
    NewShell, Hole: TPoly_Single;
    J: Integer;
begin
 Poly := TogsPolygon.Create(ogsSelector);
 NewShell := TakeRing(Shell);
 NewShell.Parent := nil;
 NewShell.PolyMode.GlobalParent := NewShell;
 Poly.AddPolygon(NewShell);
// дырки оболочки: контуры с GlobalParent = Shell (непосредственно вложенные),
// контуры отсортированы по убыванию площади -> дырки после оболочки
 For J := Index + 1 to ogsPolygon.Count - 1 do
  If (ogsPolygon.Polygon[J] <> Shell) and (ogsPolygon.Polygon[J].PolyMode.GlobalParent = Shell) then begin
   Hole := TakeRing(ogsPolygon.Polygon[J]);
   Hole.Parent := NewShell;
   Hole.PolyMode.GlobalParent := NewShell;
   Poly.AddPolygon(Hole);
  end;
 Poly.Calculate([calcSquare]);
 AddPolygon(Poly);
end;
begin
 ogsPolygon.CalcGlobalParents;
// каждая оболочка (внешний контур или остров внутри дырки) -> отдельный TogsPolygon
 For I := 0 to ogsPolygon.Count - 1 do
  If ogsPolygon.Polygon[I].PolyMode.GlobalParent = ogsPolygon.Polygon[I] then CreatePolygon(ogsPolygon.Polygon[I], I);
// контуры перенесены -> очищаем коллекцию полигонов ogsPolygon без уничтожения
 if MoveItems then ogsPolygon.Items.DeleteAll;
end;

function TogsMultiPolygon.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
    Poly: TogsPolygon;
begin
 Result := 0;
 If calcSquare in Action then begin
  fSquare := 0;
  For I := 0 to Count - 1 do begin
   Poly := Polygon[I];
   If Poly.Square = -1 then Poly.Calculate([calcSquare]);
   If Poly.Square <> -1 then fSquare := fSquare + Poly.Square;
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
 Result := TogsPolygon(Items.list[Index]);
end;

function TogsMultiPolygon.GetSquare: Double;
begin
 Result := fSquare;
end;

class function TogsMultiPolygon.GeometryType: String;
begin
 Result := 'MultiPolygon';
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
 C := Drawer.Pen.penColor;
 If Selected then Drawer.Pen.penColor := TColorRec.Lime;
 For I := 0 to Count - 1 do begin
  Polygon[I].DrawPoint(Drawer);
 end;
 Drawer.Pen.penColor := C;
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
 var spatialProps: TJSONValue; OnlyGeometry: Boolean): Integer;
var I: integer;
    Coords: TJSONValue;
begin
// [[[[X, Y], ...], ...], ...] - массив полигонов
 Coords := TJSONArray.Create;
 For I := 0 to Count - 1 do Polygon[I].UpdateSpatialProperties(Coords, {OnlyGeometry} True);
 If OnlyGeometry then begin // добавляем только геометрию
  If not (spatialProps is TJSONArray) then begin
   Coords.Free;
   raise Exception.Create('Вызов UpdateSpatialProperties: spatialProps не TJSONArray');
  end;
  TJSONArray(spatialProps).AddElement(Coords);
 end else // добавляем геометрию с заголовком
  AddGeometryPair(spatialProps, GeometryType, Coords);
 Result := Count;
end;

initialization
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsGeometryCollection, 200, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsDot, 201, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPoint, 202, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsMultiPoint, 203, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsLineString, 204, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsMultiLineString, 205, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TPoly_Single, 206, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPolygon, 207, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsMultiPolygon, 208, 1));
end.
