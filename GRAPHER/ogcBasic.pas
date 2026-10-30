unit ogcBasic;

interface

uses Classes, SysUtils, Types, System.UITypes, System.JSON, FMX.Graphics,
     ogcMemStream, Math;

type
  TogsGeometry = class;
  TogsSelector = class;
  TogsDrawer = class;
  TogsStream = class;
  TogsDot = class;
  TogsRect = class;
  TogsCollection = class;
// семантика объектов (GeoJSON "properties") - стандартный объект System.JSON
  TogsProperties = TJSONObject;

  TColorBy = (colorByDef, colorByObject, colorByLayer, colorByBlock);

  { TogsColor }
  PogsColor = ^TogsColor;
  TogsColor = record
   ColorBy  : TColorBy;
   ColorRec : TColor;
   function Color(defColor, layerColor, blockColor: TColor): TColor;
  end;

  { TogsBasic }

  TogsBasic = class(TObject)
   function GetTrasactionID: Integer; virtual;
   procedure SetTransactionID(AValue: Integer); virtual;
  //
   class function ObjectID: Integer; virtual;
  // class function GUID: TGUID; virtual;
  //
   function GetGUID: TGUID; virtual; abstract;
   procedure SetGUID(GUID_: TGUID); virtual; abstract;
  //
   function GetColorBy: TColorBy; virtual;
   procedure SetColorBy(AValue: TColorBy); virtual;
   function GetColor: TColor; virtual;
   procedure SetColor(AValue: TColor); virtual;
   function GetSign: Pointer; virtual;
   procedure SetSign(AValue: Pointer); overload; virtual;
   function GetAttribute: String; virtual;
   procedure SetAttribute(AValue: String); virtual;
  // CreateEmpty - конструктор для создания пустого экземпляра объекта
  // применяется для работы с копиями объектов KeepObjects
  // при связи с атрибутами или генерализации при масштабированиии
  // и динамической установке свойств в блоках
   constructor CreateEmpty; virtual;
   constructor CreateAs(ogsObject:TogsBasic); virtual;
   constructor KeepAs(ogsObject:TogsBasic); virtual;
  // GUID
   procedure CreateGUID; virtual; abstract;
   function GUIDStr: String; virtual; abstract;
   property  GUID: TGUID read GetGUID write SetGUID;
  //
   procedure Clear; virtual;
  // constructor CreateAs(ogsObject:TogsProperties); virtual; overload;
   function Keep(ogsObject:TogsBasic): boolean; virtual;
   function Assign(ogsObject:TogsBasic): boolean; virtual;
   function isKeepObject: Boolean; virtual;
  //
   constructor Load(Stream: TogsStream); virtual; abstract;
   procedure Store(Stream: TogsStream); virtual; abstract;
  //
   function GetogsSelector: TogsSelector; virtual; abstract;
   procedure SetogsSelector(AValue: TogsSelector); virtual; abstract;
   property ogsSelector: TogsSelector read GetogsSelector write SetogsSelector;
  // JSON
   function GetogsProperties: TogsProperties; virtual; abstract;
   procedure SetogsProperties(AValue: TogsProperties); overload; virtual; abstract;
   function CreateSysProperties(strTemplate: String): TogsProperties; virtual;abstract;
   property ogsProperties: TogsProperties read GetogsProperties write SetogsProperties;
   function ToString: String; override;
  //
   function getogsRect: TogsRect; virtual; abstract;
   property ogsRect: TogsRect read getogsRect;
  // временные свойства
   property ColorBy: TColorBy read GetColorBy write SetColorBy;
   property Color  : TColor read GetColor write SetColor;
   property Sign : Pointer read GetSign write SetSign;
   property Attribute: String read GetAttribute write SetAttribute;
   function FindAttribute(AtrrName: String; out Prim: Pointer): boolean; virtual;
  // вывод объекта в консоль
   function WriteObj(Params: Array of Const): String; virtual;
  // для метафайлоы
   procedure Play(Drawer: TogsDrawer; playRect: TogsRect = nil); virtual; abstract;
  //
   function GetParent: TogsBasic; virtual;
   procedure SetParent(AValue: TogsBasic); virtual; abstract;
   property Parent: TogsBasic read GetParent write SetParent;
  //
   property TransactionID: Integer read GetTrasactionID write SetTransactionID;
  end;

  TogsBasicClass = class of TogsBasic;

  { TogsGeometry }

  TCalcAction = (calcLength, calcbBox, calcSquare, calcRelation, calcSortBy);
  TCalcActionSet = set of TCalcAction;

 // параметры захвата примитивов TogsGeometry
  TCaptureKind = (ckPoint, ckLine, ckSinglePolygon, ckPolygon, ckMultiPolygon, ckText, ckBlock, ckMidLine);
  TSetOfCapture = set of TCaptureKind;

  { TCaptureRec }

  TCaptureRec = record
   CaptureMode: Byte;
  // точка захвата
   XCapture, YCapture: Double;
   CaptureObject: TogsGeometry; // захваченный примитив в сложных объектах -
                                // блоках и типах линий
  // параметры захвата
   CaptureParam: Integer; // максимально допустимое расстояние до примитива
   CaptureFor: TSetOfCapture; // устанавливает, какие типы примитивов захватывать
   ignoreHoles: Boolean; // игнорировать при захвате дырки (не проверять)
  // возвращаемые результаты захвата
   resCapture: Integer; // расстояние в пикселах -> возвращает функция
                        // захвата примитива resObject
   resObject : Pointer; // захваченный примитив
   resCaptureOf: TCaptureKind;
   function ClearParams(CaptureDef: TSetOfCapture = [ckPoint, ckLine, ckPolygon]): TCaptureRec;
  // проверка: установлена точка захвата, или ее необходимо установить
   function nullPoint: Boolean;
   procedure SetCapPoint(X, Y: Double);
  end;

  TogsGeometry = class(TogsBasic)
  protected
   function GetCount: Integer; virtual; abstract;
   function GetItem(Index: Integer): TogsGeometry; virtual; abstract;
   procedure SetItem(Index: Integer; AValue: TogsGeometry); virtual; abstract;
   function GetSelected: boolean; virtual; abstract;
   procedure SetSelected(AValue: boolean); virtual; abstract;
   function GetSquare: Double; virtual; abstract;
   function GetogsID: Int64; virtual;
   procedure SetogsID(AValue: Int64); virtual;
   function GetRenderOrder: Integer; virtual;
   procedure SetRenderOrder(AValue: Integer); virtual;
  public
  // root functions
 //  function ogsParent: TogsGeometry; virtual; abstract; //родительский эдемент
  // basic function
   class function GeometryType (): String; virtual; abstract;
   class function SRID (): Integer; virtual; abstract;
  //
   function AsText (): String; virtual; abstract;
  // лиyейные-площадные ф-ции
   function IsClosed: Integer; virtual; abstract;
   function _Length (): Double; virtual; abstract;
   function StartPoint (): TogsDot; virtual; abstract;
   function EndPoint (): TogsDot; virtual; abstract;
   function IsRing (): Integer; virtual; abstract;
   property Square: Double read GetSquare;
  // геометрические ф-ции
   function Equals (ogsGeom: TogsGeometry): Integer; reintroduce; virtual; abstract;
   procedure Rotate(clockWise : Integer); virtual;
  // пространственные
   function Distance (ogsGeom: TogsGeometry): Double; virtual; abstract;
  // видимость
   function Visible(Rect: TogsRect): Boolean; virtual; abstract;
  // расчет геометрических харкктеристик примитива
  // возвращает значение (например: bool, кол-во, дескриптор, либо указатель)
   function Calculate(Action: TCalcActionSet): Integer; virtual; abstract;

  // отрисовка
   procedure Draw(Drawer: TogsDrawer); virtual; abstract; // стандартное рисование
   procedure DrawPoint(Drawer: TogsDrawer); virtual; abstract; // отрисовка точек примитива
                                                               // или самой точки
  // выделение
   property Selected: boolean read GetSelected write SetSelected;
   function SelectByPoint(X, Y: Double; var Params: TCaptureRec): boolean; virtual;
  // каскадная запись GeoJSON в текстовый поток: примитив пишет себя как Feature
  // (ToString), коллекция - FeatureCollection из своих элементов;
  // возвращает количество записанных Feature
   function StoreGeoJSON(Stream: TogsStream): Integer; virtual;
   property ogsID: Int64 read GetogsID write SetogsID;
   property RenderOrder: Integer read GetRenderOrder write SetRenderOrder;
  // для списков элементов
   property Item[Index: Integer]: TogsGeometry read GetItem write SetItem; default;
   property Count: Integer read GetCount;
   function Add(Item_: Pointer): Integer; virtual; abstract;
  end;

  TogsGeometryClass = class of TogsGeometry;

  { TSect }
  PSect = ^TSect;
  TSect = record
   function VisibleIn(Sect: TogsRect): boolean;
   Case shortInt of
    0:(XA, YA, XB, YB: Double);
    1:(XMin, YMin, XMax, YMax: Double);
    3:(Left, Top, Right, Bottom: Double); // сохранено для совместимости (Top < Bottom)
  end;

  { TogsDot }

  TogsDot = class(TogsGeometry)
  private
   function GetX: Double; virtual;
   function GetY: Double; virtual;
   procedure SetX(AValue: Double); virtual;
   procedure SetY(AValue: Double); virtual;
  // жмуляция ф-ций TogsSimpleGeometrySet
   function GetCount: Integer; override;
   function GetItem(Index: Integer): TogsGeometry; override;
   procedure SetItem(Index: Integer; AValue: TogsGeometry); override;
   procedure SetogsSelector(Data: TogsSelector); override;
  public
   fX, fY: Double;
   Z: Double;
   constructor Create(X_, Y_: Double; Z_: Double = 0);
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure   Store(Stream: TogsStream); override;
  // длина, начальная/конечная точка для примитивов типа: отрезок, дуга
   function _Length (): Double; override;
   function StartPoint (): TogsDot; override;
   function EndPoint (): TogsDot; override;
  //
   function Distance(ogsGeom: TogsGeometry): Double; overload; override;
   function Distance(X_, Y_: Double): Double; overload;
   function Equals(ogsGeom: TogsGeometry): Integer; override;
  //
   function Visible(Rect: TogsRect): Boolean; override;
  //
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  //
   function getogsRect: TogsRect; override;
  //
   property X: Double read GetX write SetX;
   property Y: Double read GetY write SetY;
  //
   function WriteObj(Params: Array of Const): String; override;
  end;

  { TogsSimpleGeometrySet }

  TogsSimpleGeometrySet = class(TogsGeometry)
  private
  //
   function GetCount: Integer; override;
   function GetogsRect: TogsRect; override;
  //
   function GetItem(Index: Integer): TogsGeometry; override;
   procedure SetItem(Index: Integer; AValue: TogsGeometry); override;
  protected
   fItems: TogsCollection;
   fogsRect: TogsRect;
  public
   constructor Create(Capacity_: Integer);
   destructor Destroy; override;
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure   Store(Stream: TogsStream); override;
  //
   property Items: TogsCollection read fItems write fItems; // !!! временный доступ для совместимости
   function List: TList;
   procedure Clear; override;
   function Add(Item_: TogsGeometry): Integer; reintroduce; virtual;
  //
   function Calculate(Action: TCalcActionSet): Integer; override;
   function Visible(Rect: TogsRect): Boolean; override;
  //
   procedure Draw(Drawer: TogsDrawer); override;
   procedure DrawPoint(Drawer: TogsDrawer); override;
  end;

  { TogsPolyCollection }

  TogsPolyCollection = class(TogsSimpleGeometrySet)
   // коллекция для обращения по Items
   constructor Create1(Capacity_: Integer);
  end;

  { TogsRect }
  TogsRect = class(TogsGeometry)
  public
  // временно в паблике
   XMin, YMin, XMax, YMax: Double;
   Iter:0..1;
   fOnChange: TNotifyEvent;
 //
   constructor Create;
   constructor CreateAs(MRect_: TogsRect); // override; ???
   constructor CreateRect(XMin_,YMin_,XMax_,YMax_: Double);
   procedure Assign(MRect_:TogsRect); // override; ???
  //
   constructor Load(Stream: TogsStream); override;
   procedure   Store(Stream: TogsStream); override;
  //
   procedure Clear;
   function Insert(X_, Y_: Double): Boolean;
   function InsertRect(Rect_: TogsRect): boolean;
   function isRect: Boolean;
   function Width: Double;
   function Height: Double;
   function isVertical: Boolean;
   procedure Move(Dx, Dy: Double);
   procedure Scale(X, Y, Koef: Double);
  // временная процедура, без обработки событиq OnChange, OnChanged для обновления в родительских оъектах
   function Inflate(deltaX, deltaY: Double): TogsRect;
  // видимость
   function PointIn(X, Y: Double): Boolean; overload;
   function PointIn(X, Y, Delta: Double): Boolean; overload;
   function Visible(Sect_: TSect): Boolean;
   function VisibleIn(Rect: TogsRect): Boolean;
   function VisibleAllIn(Rect: TogsRect): Boolean;
   function IntersectWith(Rect: TogsRect): TSect;
  //
   function GetSect: TSect;
   procedure SetSect(AValue: TSect);
   property Sect: TSect read GetSect write SetSect;
  // рисование
   procedure Draw(Drawer: TogsDrawer);
  //
   function WriteObj(Params: Array of Const): String; override;
  //
   property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

 { TogsCollection }

 // проверка на тип элементов в коллекции при вставке
 // для свойства TogsCollection.CheckTypeProc
  TCheckTypeProc = function(P: TogsBasic): Boolean;

  TogsCollection = class(TogsGeometry)
  protected
  //
   fList: TList;
  // статический метод для проверки типа добавляемых объектов
   fcheckTypeProc: TCheckTypeProc;
   function GetCount: Integer; override;
   function GetItem(Index: Integer): Pointer; reintroduce;
   procedure SetItem(Index: Integer; AValue: Pointer); reintroduce;
  public
   constructor Create(Capacity_: Integer = 1);
   destructor Destroy;override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
 //
   property Count: Integer read GetCount;
 //!!! небезопасный доступ к fList
   property List: TList read fList write fList;
   property Items[Index: Integer]: Pointer read GetItem write SetItem; default;
   property CheckTypeProc: TCheckTypeProc read fcheckTypeProc write fcheckTypeProc;
 //
   function Add(Item_: Pointer): Integer; override;
   function Insert(Index: Integer; Item_: Pointer): Integer;
   function IndexOf(Item_: Pointer): Integer; virtual;
 //
   function Delete(Index: Integer): Integer;
   function AtFree(Index: Integer): Integer;
   procedure DeleteAll;
   procedure FreeAll;
  end;

  { TogsSortedCollection }

  // сортированная коллекция для реализации двоичного поиска
  TogsSortedCollection = class(TogsCollection)
  protected
   fDuplicates: Boolean;
   fOnCompare: TListSortCompare;
  public
   constructor Create(OnCompare_: TListSortCompare; Duplicates_: Boolean = True; Capacity_: Integer = 1);
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function IndexOf(Item_: Pointer): Integer; override;
   function Add(Item_: Pointer): Integer; override;
   function KeyOf(Item_: Pointer): Pointer; virtual;
   function Search(Item_: Pointer; var Index: Integer): Boolean; virtual;
  //
   property Duplicates: Boolean read fDuplicates write fDuplicates;
   property OnCompare: TListSortCompare read fOnCompare write fOnCompare;
  end;

 { TogsStream }

 // функции поиска классов и их ID в списках зарегистрированных классов на чтение/запись
 // т.к. для оптимизации поиска, таких списков может быть несколько
 // в TogsStream предусмотрена установка событий для вызова
 // поиска из различных списков
 // по умолчанию список регистрации для чтения/записи - ogsRegisteredClasses
 // ф-ции LinearSearchGet(ClassNum: Integer): TogsBasicClass;
 //       LinearSearchPut(objClassType: TogsBasicClass): Integer;
  TOnSearchGetProc = function (ClassNum: Integer): TogsBasicClass;
  TOnSearchPutProc = function (objClassType: TogsBasicClass): Integer;

  TogsStream = class(TogsBasic)
  private
   fStream: TStream;
   fSelector: TogsSelector;
  // количество элементов в открытых списках JSON (стек вложенности)
   fListCounts: TArray<Integer>;
   function getPosition: Integer;
   procedure SetPosition(AValue: Integer);
  protected
   fOnSearchGetProc: TOnSearchGetProc;
   fOnSearchPutProc: TOnSearchPutProc;
  public
   Version : Byte; // для механизма поддержки версий объектов
  //
   constructor Create; // TMemoryStream
   constructor CreateMemoryStream(Capacity_: Integer = 0; Selector_: TogsSelector = nil);
   constructor CreateFileStream(FileName_: String; Mode_: Word; Selector_: TogsSelector = nil);
   constructor CreateStringStream(Data_: String; Selector_: TogsSelector = nil);
   destructor Destroy; override;
  //
   procedure AssignSearchProcs(SearchForGet: TOnSearchGetProc;
    SearchForPut: TOnSearchPutProc);
  //
   function GetogsSelector: TogsSelector; override;
   procedure SetogsSelector(AValue: TogsSelector); override;
  //
   property Stream: TStream read fStream write fStream;
   function Size: Integer;
   Property Position: Integer read getPosition write SetPosition;
  //
   function Read(var Buf; Count: Longint): Longint; overload;
   function Write(const Buf; Count: Longint): Longint;  overload;
   function Read(var Buf : AnsiString): Longint; overload;
   function Write(const Buf : AnsiString): Longint; overload;
  // byte, int, float
   function ReadByte: Byte;
   function ReadInt: Integer;
   function ReadLongInt: LongInt;
   function ReadFloat: Double;
   procedure WriteByte(Value: Byte);
   procedure WriteInt(Value: Integer);
   procedure WriteLongInt(Value: LongInt);
   procedure WriteFloat(Value: Double);
  // для совместимости Delphi
   function ReadString(var Buf : AnsiString): Longint;
   function WriteString(const Buf : AnsiString): Longint;
  // строка Unicode в потоке: длина (байт) + UTF-8
   function ReadUTF8: String;
   procedure WriteUTF8(const S: String);
   function Get: TogsBasic;
   procedure Put(ogsObject: TogsBasic);
  // семантика TogsProperties (TJSONObject) хранится в потоке строкой JSON (UTF-8)
   function GetJSON: TJSONObject;
   procedure PutJSON(jsonObject: TJSONObject);
  // загрузка объекта из специализированного потока
  // к примеру текстового файла JSON, используя методы чтения потока
  // P - объект, в который производится запись, если P = nil
  // объект создается в методе и возвращается вызывающему процессу
   function LoadDefaultObject(P: Pointer): Pointer; virtual; abstract;
  // текстовый поток: текст UTF-8 без префикса длины
   procedure WriteText(const S: String);
  // списки JSON для каскадной записи: Header + '[' ... ']' + Footer,
  // ListItem добавляет элемент с разделителем ','
   function ListLevel: Integer;
   procedure BeginList(const Header: String);
   procedure ListItem(const S: String);
   procedure EndList(const Footer: String);
  // содержимое потока CreateStringStream
   function DataString: String;
  end;

  { TogsObjectSwitcher }

  TogsObjectSwitcher = class(TogsBasic)
   fSwitch: TogsStream;
  end;

  { TogsRegisteredClass }

  TogsRegisteredClass = class(TogsGeometry)
   objClassType: TogsBasicClass;
   ClassNum: SmallInt;
   classRank: byte;
   constructor Create(objClassType_:TogsBasicClass; ClassNum_:SmallInt; classRank_:byte = 0);
  end;

  { TogsDrawer }

  TogsBlock = class(TogsGeometry)
  end;

  TogsLineType = class(TogsCollection)
  end;

  { TogsPen }

  TogsPen = class(TogsBasic)
   penColor: TColor;
   penWidth: Single;
   penType : TogsLineType;
   constructor Create(Color: TColor; Width: Single; Type_: TogsLineType);
   constructor CreateAs(ogsObject:TogsBasic); override;
  end;

  TogsBrushStyle = class(TogsCollection)
  end;

  { TogsBrush }

  TogsBrush = class(TogsBasic)
   brColor : TColor;
   brStyle : TogsBrushStyle;
   constructor Create(Color: TColor; Style_: TogsBrushStyle);
   constructor CreateAs(ogsObject:TogsBasic); override;
  end;

  { TogsBrush }

  TDrawerMode = (dmDraw, dmCapture, dmScene);

  TPlayerEvent = function (Drawer: TogsDrawer; SceneObject: TogsBasic): Boolean;

  TogsDrawer = class(TogsBasic)
  private
  // событие для отрисовки на внешней канве методом TogsDrawer.DrawTo
   fOnPaint: TNotifyEvent;
   fOnPlayerEvent: TPlayerEvent;
  // перо, кисть
   fPen: TogsPen;
   fBrush: TogsBrush;
  // сцена для отрисовки, состоящая из набора комманд - типа wmf, svg
  // комманды могут быть как простыми, так и вложенными
   fcmdPlayer: TogsCollection;
  // масштаб рисователя (для модулей GMF, как в JSON\ogcBasic)
   fScale: Single;
  //
   function GetcmdPlayerItem(Index: Integer): TogsBasic;
   function GetogsSelector: TogsSelector; override;
   procedure SetogsSelector(Data: TogsSelector); override;
   function GetScale: Single;
   procedure SetScale(const Value: Single);
  protected
   fogsSelector: TogsSelector;
   fDrawerMode: TDrawerMode;
   function GetWidth: Integer; virtual; abstract;
   procedure SetWidth(AValue: Integer); virtual; abstract;
   function GetHeight: Integer; virtual; abstract;
   procedure SetHeight(AValue: Integer); virtual; abstract;
   function GetPen: TogsPen; virtual;
   procedure SetPen(AValue: TogsPen); virtual;
   function GetBrush: TogsBrush; virtual;
   procedure SetBrush(AValue: TogsBrush); virtual;
   function GetCanvas: TCanvas; virtual;
  public
   Disable: Boolean;
  // для модулей GMF (JSON\ogcDrawerSkia, Lib, ECLot): цвет объекта и имя рисователя
   R, G, B: Byte;
   Name: String;
   constructor Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent); virtual;
   destructor Destroy; override;
   function DrawerMode: TDrawerMode; virtual;
  //
   procedure Clear(AColor: Longint); virtual;
 // рисованиев в системе координат объекта
   procedure DrawPoint(Point: TogsDot); virtual;
   procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); overload; virtual;
   procedure DrawLine(Point1, Point2: TogsDot; cutRequest: Boolean = True); overload; virtual;
   procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); overload; virtual;
  // точки - коллекция TlDot (модули GMF, JSON\ogcDrawerSkia)
   procedure DrawPolyline(Points: TogsCollection; cutRequest: Boolean = True); overload; virtual;
   procedure DrawPolygon(Points: TogsCollection; polyRect: TogsRect); virtual;
   procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); virtual;
   procedure DrawSect(Sect: TSect); virtual;
   procedure DrawCircle(XA, YA, Radius: Double); virtual;
   procedure DrawBitmap(Bitmap: TogsGeometry; bmRect: TogsRect); virtual;
 //для сложных объектов рисования - var-параметр
   procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); virtual;
   procedure DrawMarker(X, Y: Double; Text: String = ''); overload; virtual;
   procedure DrawMarker(Point: TogsDot; Text: String = ''); overload; virtual;
 // рисовагние в системе координат Canvas
   procedure MoveTo(X, Y: Integer); virtual;
   procedure LineTo(X, Y: Integer); virtual;
 //
   property Scale: Single read GetScale write SetScale;
   property Width: Integer read GetWidth write SetWidth;
   property Height: Integer read GetHeight write SetHeight;
   function geoWidth: Double; virtual; abstract;
   function geoHeight: Double; virtual; abstract;
 // события
   procedure MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean); virtual;
 //
   procedure BeginPaint; virtual;
   procedure EndPaint; virtual;
   property OnPaint: TNotifyEvent read fOnPaint write fOnPaint;
   procedure DoOnPaint(Sender: TObject); virtual;
   procedure DrawTo(Image_: TCanvas; Rect: TRect); overload; virtual; abstract;
  // запрос на перерисовку контрола-владельца канвы
   procedure RedrawAll; virtual;
 //
   property Canvas: TCanvas read GetCanvas;
   property Pen: TogsPen read GetPen write SetPen;
   property Brush: TogsBrush read GetBrush write SetBrush;
 // управление пером и кистью
   function SelectPen(Pen_: TogsPen): TogsPen; virtual; // возвращает предыдущий fPen
  // удаляет текущее перо, для возврата к предыдущему используется
  // конструкция :
  //               oldPen := SelectPen(TogsPen.Create(<newPenParams>));
  //               ...
  //               DeletePen(SelectPen(oldPen));
   procedure DeletePen(Pen_: TogsPen);
   function  SelectBrush(Brush_: TogsBrush): TogsBrush; virtual;
   procedure DeleteBrush(Brush_: TogsBrush);
  // проигрывать сцену - отрисовать все примитивы из fcmdSceneList
   property cmdPlayer: TogsCollection read fcmdPlayer write fcmdPlayer;
   property cmdPlayerItem[Index: Integer]: TogsBasic read GetcmdPlayerItem;
   property OnPlayerEvent: TPlayerEvent read fOnPlayerEvent write fOnPlayerEvent;
   procedure Play(Drawer: TogsDrawer; Rect: TogsRect = nil); virtual;
 end;

  {TogsSpacer}

 // класс для поддержки сложных составных объектов типа: блок, тип линии
 // может использоваться для:
 // рисования (унаследован от TDrawer)
 // захвата примитивов в составных объектах
 // экспорта в тайлы, метафайлы, передачи в сторонние форматы данных

  TogsSpacer = class(TogsDrawer)
  private
   function GetSelected: boolean;
  public
   CaptureRec: TCaptureRec;
   constructor Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent); override;
   constructor CreateCapture(Selector: TogsSelector); virtual;
  // выделение
   function SelectByPoint(X, Y: Double; ogsObject: TogsGeometry): boolean; virtual;
   property Selected: boolean read GetSelected;
  end;

  { TogsSelector }

  TSelectorModeBits = packed record
   smAdderLocked: boolean;
   smPainterLocked: boolean;
  end;

  TogsSelector = class(TogsBasic)
  private
   fDrawer: TogsDrawer;
   fglobalRect: TogsRect;
   factiveRect: TogsRect;
   fDx, fDy: Double;
   fPixelSize: Double;
   fParent: TogsBasic; // объект, в котором создан Selector
   mfs, mff: Integer; // начало -> конец замера memFree
                      // memFreeFinish = mff - mfs
   function getActiveRect: TogsRect;
   procedure setActiveRect(AValue: TogsRect);
   function GetDrawer: TogsDrawer;
   procedure SetDrawer(AValue: TogsDrawer);
   function GetParent: TogsBasic; override;
   procedure SetParent(AValue: TogsBasic); override;
  //
   procedure SetObjFlags(Index: Byte; AValue: boolean);
   function getogsRect: TogsRect; override;
   function GetDevScale: Double;
  public
   fScale : Double;
   fSelectorMode: Byte; // временно. перенести в приват
   SelectorMode: TSelectorModeBits;
   sName: String; // временно
  // для модулей GMF (как в JSON\ogcBasic)
   Name: String;
   memMgr: TMemoryManager; // для отладки - менеджер памяти
  // плотность пикселей устройства (точек на дюйм) для DevScale,
  // устанавливается рисователем (FMX: 96 * Scene.GetSceneScale)
   DevicePPI: Single;
   constructor Create(Drawer_: TogsDrawer); virtual;
   destructor Destroy;override;
  //
   function memFree: Integer;
   function memFreeStart: Integer;
   function memFreeFinish: Integer;
  // гкометрия
   property ogsDrawer: TogsDrawer read GetDrawer write SetDrawer;
   function AddCoord(X, Y: Double): Boolean;
   function AddPrim(Prim: TogsBasic): boolean;
   property ActiveRect: TogsRect read getActiveRect write setActiveRect;
   property GlobalRect: TogsRect read fGlobalRect;
   property PixelSize: Double read fPixelSize;
   function GetScale: Double;
   function GetDx: Double;
   function GetDy: Double;
   function XPix(X: Double): Integer; virtual;
   function YPix(Y: Double): Integer; virtual;
   function XGeo(X: Integer): Double; virtual;
   function YGeo(Y: Integer): Double; virtual;
   function geoDist(Value: Double): Double; virtual;
   function pixDist(Value: Double): Integer; virtual;
  // реальных единиц (мм) в пикселе -> масштаб
   property DevScale: Double read GetDevScale;
  //
   procedure Clear;
   function UpdateRects(fitView: boolean = False): boolean;
  //
   procedure Move(Dx, Dy: Double);
   procedure Scale(X, Y, Koef: Double);
  //
   function pointVisible(X, Y: Double): Boolean;
   function lineVisible(X, Y, X1, Y1: Double): Boolean;
   function RectVisible(Rect: TogsRect): Boolean;
   function SectVisible(Rect: TSect): Boolean;
   function cutLine(X, Y, X1, Y1: Double; var X_,Y_,X1_,Y1_: Double): Boolean;
   procedure BeginPaint;
   procedure EndPaint;
  //
   procedure OnChange(Sender: TObject);
  end;

var
  ogsRegisteredClasses: TogsSortedCollection;
  pointSect: TogsRect;
// для совместимости с Delphi
// TCaptureRec functions
function CRClearParams(CaptureDef: TSetOfCapture = [ckPoint, ckLine, ckPolygon]): TCaptureRec;
// проверка: установлена точка захвата, или ее необходимо установить
function CRnullPoint(CaptureRec: TCaptureRec): Boolean;
procedure CRSetCapPoint(CaptureREc: TCaptureRec; X, Y: Double);

//
// соритровка коллекции классов по разным признакам: номер, ранг
function ogsListNumCompare(Item1, Item2: Pointer): Integer;
function ogsListRankCompare(Item1, Item2: Pointer): Integer;

// поиск экземляра класса по регистрационному номеру
Function LinearSearchGet(ClassNum: Integer): TogsBasicClass;
// поиск регистрационного номера по классу объекта
Function LinearSearchPut(objClassType: TogsBasicClass): Integer;

type

 { TMatrix }

 TogsMatrix = class(TogsDot)
  ID : Integer;
  X, Y: Double;
  Angle: Double;
  Scale: Double;
  constructor Create(X_,Y_,Angle_,Scale_:Double; ID_:Integer = 0);
 end;

function ogsMatrix: TogsMatrix;
function SelectMatrix(Matrix: TogsMatrix): TogsMatrix;
function DeleteMatrix(Matrix: TogsMatrix): Boolean;
function xMatrix(XBase, X_, Y_, Angle, Scale: Double): Double;
function yMatrix(YBase, X_, Y_, Angle, Scale: Double): Double;

implementation uses Writer, ogcMathUtils;

// глобальная переменная - дескриптор Matrix
var activeMatrix : TogsMatrix = nil;

function ogsListNumCompare(Item1, Item2: Pointer): Integer;
var I: Integer;
begin
 Result := 0;
end;

function ogsListRankCompare(Item1, Item2: Pointer): Integer;
begin
 Result := 0;
end;

function ComparePointers(Item1, Item2: Pointer): Integer;
begin
//  if Item1 > Item2 then Result := -1 else
 // if Item1 < Item2 then Result := 1 else Result := 0;
 Result := -1;
end;

{ TogsPolyCollection }

constructor TogsPolyCollection.Create1(Capacity_: Integer);
begin
 inherited Create(Capacity_);
end;

{ TogsColor }

function TogsColor.Color(defColor, layerColor, blockColor: TColor): TColor;
begin
 case ColorBy of
  colorByObject: Result := ColorRec;
  colorByLayer : Result := layerColor;
  colorByBlock : Result := blockColor;
   else
    Result := defColor;
 end;
end;

{ TogsGeometry }

procedure TogsGeometry.Rotate(clockWise: Integer);
begin
// abstract
end;

function TogsGeometry.SelectByPoint(X, Y: Double; var Params: TCaptureRec): boolean;
begin
 Result := False;
 WriteIn(['AbstractError=', ClassName]);
end;

function TogsGeometry.StoreGeoJSON(Stream: TogsStream): Integer;
var S: String;
begin
 Result := 0;
 S := ToString;
 if S = '' then exit;
 Stream.ListItem(S);
 Result := 1;
end;

function TogsGeometry.GetRenderOrder: Integer;
begin
 Result := 0;
end;

procedure TogsGeometry.SetRenderOrder(AValue: Integer);
begin
// базовая реализация: по умолчанию порядок не хранится
end;

function TogsGeometry.GetogsID: Int64;
begin
 Result := 0;
end;

procedure TogsGeometry.SetogsID(AValue: Int64);
begin
//
end;

{ TSect }

function TSect.VisibleIn(Sect: TogsRect): boolean;
begin
 Result := False;
 If XMin > Sect.XMax then exit;
 If YMin > Sect.YMax then exit;
 If XMax < Sect.XMin then exit;
 If YMax < Sect.YMin then exit;
 Result := True;
end;

{ TMatrix }

constructor TogsMatrix.Create(X_, Y_, Angle_, Scale_: Double; ID_:Integer = 0);
begin
 ID := ID_;
 X := X_; Y := Y_;
 Angle := Angle_;
 Scale := Scale_;
end;

function ogsMatrix: TogsMatrix;
begin
 Result := activeMatrix;
end;

function SelectMatrix(Matrix: TogsMatrix): TogsMatrix;
begin
 Result := ogsMatrix;
 activeMatrix := Matrix;
end;

function DeleteMatrix(Matrix: TogsMatrix): Boolean;
begin
 Result := Matrix <> nil;
 If Result then begin Matrix.Free; Matrix := nil; end;
end;

function xMatrix(XBase, X_, Y_, Angle, Scale: Double): Double;
begin
 If Angle = 0 then
  If Scale = 1 then Result := XBase + X_ else Result := XBase + (X_* Scale)
 else
  Result := XBase + (X_* Scale * cos(Angle) - Y_* Scale * sin(Angle));
end;

function yMatrix(YBase, X_, Y_, Angle, Scale: Double): Double;
begin
 If Angle = 0 then
  If Scale = 1 then Result := YBase + Y_ else Result := YBase +(Y_ * Scale)
 else
  Result := YBase +(X_ * Scale * sin(Angle) + Y_* Scale * cos(Angle))
end;

{ TogsBasic }

constructor TogsBasic.CreateEmpty;
begin
// заглушка во избежание EAbtractError
end;

constructor TogsBasic.CreateAs(ogsObject: TogsBasic);
begin
// заглушка во избежание EAbtractError
end;

constructor TogsBasic.KeepAs(ogsObject: TogsBasic);
begin
//
end;

procedure TogsBasic.Clear;
begin
//
end;

function TogsBasic.Keep(ogsObject: TogsBasic): boolean;
begin
 Result := True;
end;

function TogsBasic.GetAttribute: String;
begin
 Result := '';
end;

procedure TogsBasic.SetAttribute(AValue: String);
begin
//
end;

function TogsBasic.GetTrasactionID: Integer;
begin
 Result := 0;
end;

procedure TogsBasic.SetTransactionID(AValue: Integer);
begin
// abstract
end;

class function TogsBasic.ObjectID: Integer;
begin
 Result := 0;
end;

function TogsBasic.GetColorBy: TColorBy;
begin
 Result := colorByDef;
end;

procedure TogsBasic.SetColorBy(AValue: TColorBy);
begin
//
end;

function TogsBasic.GetColor: TColor;
begin
 Result := 0;
end;

function TogsBasic.GetSign: Pointer;
begin
 Result := nil;
end;

procedure TogsBasic.SetColor(AValue: TColor);
begin
//
end;

procedure TogsBasic.SetSign(AValue: Pointer);
begin
//
end;

function TogsBasic.Assign(ogsObject: TogsBasic): boolean;
begin
 Result := False;
end;

function TogsBasic.isKeepObject: Boolean;
begin
 Result := False;
end;

function TogsBasic.ToString: String;
begin
 Result := '';
end;

function TogsBasic.FindAttribute(AtrrName: String; out Prim: Pointer): boolean;
begin
 Prim := nil;
 Result := False;
end;

function TogsBasic.WriteObj(Params: array of const): String;
begin
 Result := Fmt([ClassName,':',Fmt(Params)]);
end;

function TogsBasic.GetParent: TogsBasic;
begin
 Result := nil;
end;

{ TCaptureParams }
 type
  PCaptureRec = ^TCaptureRec;

function TCaptureRec.ClearParams(CaptureDef: TSetOfCapture): TCaptureRec;
begin
 FillChar(Self, SizeOf(TCaptureRec), #0);
 XCapture := XYNull;
 YCapture := XYNull;
 CaptureObject :=nil;
 CaptureParam := 4;
 CaptureFor := CaptureDef;
 ignoreHoles := False;
 resObject := nil;
 Result := PCaptureRec(@Self)^;
end;

function TCaptureRec.nullPoint: Boolean;
begin
 Result := (XCapture = xyNull) and (YCapture = xyNull);
end;

procedure TCaptureRec.SetCapPoint(X, Y: Double);
begin
 XCapture := X;
 YCapture := Y;
end;

function CRClearParams(CaptureDef: TSetOfCapture = [ckPoint, ckLine, ckPolygon]): TCaptureRec;
begin
 FillChar(Result, SizeOf(TCaptureRec), #0);
 With Result do begin
  XCapture := XYNull;
  YCapture := XYNull;
  CaptureObject :=nil;
  CaptureParam := 4;
  CaptureFor := CaptureDef;
  ignoreHoles := False;
  resObject := nil;
 end;
// Result := PCaptureRec(@Self)^;
end;

function CRnullPoint(CaptureRec: TCaptureRec): Boolean;
begin
 Result := (CaptureRec.XCapture = xYNull) and (CaptureRec.YCapture = XYNull);
end;

procedure CRSetCapPoint(CaptureRec: TCaptureRec; X, Y: Double);
begin
 CaptureRec.XCapture := X;
 CaptureRec.YCapture := Y;
end;

{ TogsSelector }

function TogsSelector.GetDrawer: TogsDrawer;
begin
 Result := fDrawer;
end;

function TogsSelector.getActiveRect: TogsRect;
begin
 Result := factiveRect;
end;

function TogsSelector.GetDevScale: Double;
begin
// реальных единиц в миллиметре экрана * 1000 (знаменатель масштаба для метров)
// вместо GetDeviceCaps(HORZSIZE/HORZRES) используется DevicePPI
 if (fScale = 0) or (DevicePPI <= 0) then begin Result := 970; exit; end;
 Result := Round(geoDist(DevicePPI / 25.4) * 1000);
end;

function TogsSelector.GetScale: Double;
begin
 Result := fScale;
end;

function TogsSelector.GetDx: Double;
begin
 Result := fDx;
end;

function TogsSelector.GetDy: Double;
begin
 Result := fDy;
end;

function TogsSelector.getogsRect: TogsRect;
begin
 Result := fglobalRect;
end;

procedure TogsSelector.setActiveRect(AValue: TogsRect);
var scaleX, scaleY: Double;
begin
 factiveRect.Assign(AValue);
// WriteIn(['activeRect.Width=',factiveRect.Width, factiveRect.Height]);
// WriteIn(['Drawer.Width=',fDrawer.Width, fDrawer.Height]);
 fDx := - fglobalRect.XMin + factiveRect.XMin;
 fDy := - fglobalRect.YMin + factiveRect.YMin;
 If not factiveRect.isRect then begin
  factiveRect.Inflate(-1, -1);
 // exit;
 end;
 if (fDrawer = nil) then Exit;
 if (factiveRect.Width = 0) or (factiveRect.Height = 0) then Exit;
 scaleX := {factiveRect.Width / fglobalRect.Width *} (fDrawer.Width / factiveRect.Width);
 scaleY := {factiveRect.Height / fglobalRect.Height *} (fDrawer.Height / factiveRect.Height);
// WriteIn(['Selector.Params',fdx,fdy,scaleX]);
 fScale := Min(scaleX, scaleY);
//
// SelectorMode[smLockedPaint] := fScale = 0;
end;

procedure TogsSelector.SetDrawer(AValue: TogsDrawer);
begin
 fDrawer := AValue;
end;

function TogsSelector.GetParent: TogsBasic;
begin
 Result := fParent;
end;

procedure TogsSelector.SetParent(AValue: TogsBasic);
begin
 fParent := AValue;
end;

procedure TogsSelector.SetObjFlags(Index: Byte; AValue: boolean);
begin
end;

constructor TogsSelector.Create(Drawer_: TogsDrawer);
begin
 fglobalRect :=  TogsRect.Create();
 factiveRect :=  TogsRect.Create();
 If Drawer_<> nil then begin
  fDrawer := Drawer_;
  fDrawer.fogsSelector := Self;
 end;
 DevicePPI := 96;
end;

destructor TogsSelector.Destroy;
begin
 fglobalRect.Free;
 factiveRect.Free;
 inherited Destroy;
end;

function TogsSelector.memFree: Integer;
{$IFDEF MSWINDOWS}
var State: TMemoryManagerState;
    I: Integer;
    Used: NativeUInt;
{$ENDIF}
begin
// в Delphi нет THeapStatus.TotalFree для всех платформ ->
// возвращаем занятую память со знаком минус, разность memFreeFinish сохраняет смысл
{$IFDEF MSWINDOWS}
 GetMemoryManagerState(State);
 Used := State.TotalAllocatedMediumBlockSize + State.TotalAllocatedLargeBlockSize;
 for I := Low(State.SmallBlockTypeStates) to High(State.SmallBlockTypeStates) do
  Used := Used + State.SmallBlockTypeStates[I].AllocatedBlockCount * State.SmallBlockTypeStates[I].UseableBlockSize;
 Result := -Integer(Used);
{$ELSE}
// на Android/POSIX статистика менеджера памяти недоступна
 Result := 0;
{$ENDIF}
end;

function TogsSelector.memFreeStart: Integer;
begin
 mfs := memFree;
 Result := mfs;
end;

function TogsSelector.memFreeFinish: Integer;
begin
 mff := memFree;
 Result := mff - mfs;
end;

function TogsSelector.AddCoord(X, Y: Double): Boolean;
begin
 Result := False;
 if SelectorMode.smAdderLocked then exit;
 Result := fglobalRect.Insert(X, Y);
 If fglobalRect.isRect then begin
 end;
end;

function TogsSelector.AddPrim(Prim: TogsBasic): boolean;
begin
 Result := False;
 if SelectorMode.smAdderLocked then exit;
 Result := fglobalRect.InsertRect(Prim.ogsRect);
 If fglobalRect.isRect then begin
 end;
end;

function TogsSelector.XPix(X: Double): Integer;
begin
 Result := Round((X - fglobalRect.XMin - fDx) * fScale);
end;

function TogsSelector.YPix(Y: Double): Integer;
begin
 YPix:=Round((Y - fglobalRect.YMin - fDy) * fScale);
end;

function TogsSelector.XGeo(X: Integer): Double;
begin
// If SelectorMode.smPaintLocked then exit;// raise Exception expected
 Result := fglobalRect.XMin + fDx + X / fScale;
end;

function TogsSelector.YGeo(Y: Integer): Double;
begin
// If SelectorMode[smLockedPaint] then exit;// raise Exception expected
 Result := fglobalRect.YMin + fDy + Y / fScale;
end;

function TogsSelector.geoDist(Value: Double): Double;
begin
 Result := Value / fScale;
end;

function TogsSelector.pixDist(Value: Double): Integer;
begin
 Result := Round(Value * fScale);
end;

procedure TogsSelector.Clear;
begin
 fGlobalRect.Clear;
 fActiveRect.Clear;
end;

function TogsSelector.UpdateRects(fitView: boolean = False): boolean;
begin
// присваиваем габариты объекта
// WriteIn([fGlobalRect.XMin,fGlobalRect.YMin,fGlobalRect.XMax, fGlobalRect.YMax]);
 If fitView then ActiveRect := fglobalRect;
// пересчитываем габариты окна
 factiveRect.XMin := XGeo(0); activeRect.YMin := YGeo(0);
 factiveRect.XMax := XGeo(ogsDrawer.Width); activeRect.YMax := YGeo(ogsDrawer.Height);
// WriteIn(['Drawer.Width=======',ogsDrawer.Width,XGeo(ogsDrawer.Width)]);
 fActiveRect.Iter := 1;
 Result := factiveRect.isRect;
end;

procedure TogsSelector.Move(Dx, Dy: Double);
begin
 activeRect.Move(Dx, Dy);
// переустанавливаем локальные параметры ogsSelector
 activeRect:=activeRect;
end;

procedure TogsSelector.Scale(X, Y, Koef: Double);
var pX, pY: Integer;
    gX, gY: Double;
begin
// фиксируем положение точки масштабирования
 pX := XPix(X); pY := YPix(Y);
 activeRect := activeRect.Inflate(geoDist(10 * Koef), geoDist(10 * Koef));
 SetActiveRect(activeRect);
 UpdateRects(False);
 gX := XGeo(pX); gY := YGeo(pY);
 Move(X - gX, Y- gY);
end;

function TogsSelector.pointVisible(X, Y: Double): Boolean;
begin
 Result := (X <= activeRect.XMax) and (X >= activeRect.XMin) and (Y <= activeRect.YMax) and (Y >= activeRect.YMin);
end;

function TogsSelector.lineVisible(X, Y, X1, Y1: Double): Boolean;
var mRect: TogsRect;
begin
 Result := fActiveRect.PointIn(X, Y) and fActiveRect.PointIn(X1, Y1);
 If Result then exit;
 mRect := TogsRect.Create;
// если использовать TogsRect
  mRect.Insert(X, Y); mRect.Insert(X1, Y1);
  If mRect.XMax < factiveRect.XMin then begin mRect.Free; exit;end;
  If mRect.XMin > factiveRect.XMax then begin mRect.Free; exit;end;
  If mRect.YMax < factiveRect.YMin then begin mRect.Free; exit;end;
  If mRect.YMin > factiveRect.YMax then begin mRect.Free; exit;end;
 Result := True;
 mRect.Free;
end;

function TogsSelector.RectVisible(Rect: TogsRect): Boolean;
begin
 Result := Rect.Visiblein(factiveRect);
end;

function TogsSelector.SectVisible(Rect: TSect): Boolean;
begin
 Result := Rect.VisibleIn(factiveRect);
end;

function TogsSelector.cutLine(X, Y, X1, Y1: Double; var X_, Y_, X1_, Y1_: Double ): Boolean;
begin
 if pointVisible(X_, Y_) and pointVisible(X1_, Y1_) then
  Result := True
 else
  Result := clip_interval(X, Y, X1, Y1, X_,Y_,X1_,Y1_);
end;

procedure TogsSelector.BeginPaint;
begin
 fPixelSize := geoDist(2);
end;

procedure TogsSelector.EndPaint;
begin
//
end;

procedure TogsSelector.OnChange(Sender: TObject);
begin
 If Sender = ActiveRect then
  SetActiveRect(ActiveRect);
end;

{ TogsPen }

constructor TogsPen.Create(Color: TColor; Width: Single; Type_: TogsLineType);
begin
 penColor := Color;
 penWidth := Width;
 penType := Type_;
end;

constructor TogsPen.CreateAs(ogsObject: TogsBasic);
begin
 If ogsObject is TogsPen then begin
  penColor := TogsPen(ogsObject).penColor;
  penWidth := TogsPen(ogsObject).penWidth;
 // penStyle := TPenStyle.CreateAs(Pen.PenStyle);
 end else raise Exception.Create('Несоответствие типов TogsPen.CreateAs :' + ogsObject.ClassName);
end;

{ TogsBrush }

constructor TogsBrush.Create(Color: TColor; Style_: TogsBrushStyle);
begin
 brColor := Color;
 brStyle := Style_;
end;

constructor TogsBrush.CreateAs(ogsObject: TogsBasic);
begin
 If ogsObject is TogsBrush then begin
  brColor := TogsBrush(ogsObject).brColor;
 // brStyle := TBrushStyle.CfreateAs(Brush.brStyle);
 end else raise Exception.Create('Несоответствие типов TogsBrush.CreateAs :' + ogsObject.ClassName);
end;

{ TogsDrawer }

constructor TogsDrawer.Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent);
begin
 fOgsSelector := ogsSelector_;
 fOnPaint := OnPaint_;
 If ogsSelector_ <> nil then fogsSelector.ogsDrawer := Self;
 fPen := TogsPen.Create(0, 0, nil);
 fBrush := TogsBrush.Create(0, nil);
 fDrawerMode := dmDraw;
 fcmdPlayer := nil;
 fScale := 1;
end;

function TogsDrawer.GetScale: Single;
begin
 Result := fScale;
end;

procedure TogsDrawer.SetScale(const Value: Single);
begin
 fScale := Value;
end;

destructor TogsDrawer.Destroy;
begin
 DeletePen(fPen);
 DeleteBrush(fBrush);
 If fcmdPlayer <> nil then
  fcmdPlayer.Free;
 inherited Destroy;
end;

function TogsDrawer.GetogsSelector: TogsSelector;
begin
 Result := fogsSelector;
end;

function TogsDrawer.GetcmdPlayerItem(Index: Integer): TogsBasic;
begin
 Result := fcmdPlayer.List[Index];
end;

function TogsDrawer.GetCanvas: TCanvas;
begin
// абстрактный метод
end;

procedure TogsDrawer.SetogsSelector(Data: TogsSelector);
begin
 fogsSelector := Data;
end;

procedure TogsDrawer.SetPen(AValue: TogsPen);
begin
 If AValue = nil then begin
  If fPen <> nil then fPen.Free;
  fPen := TogsPen.Create(0, 0, nil)
 end
  else fPen := AValue;
end;

function TogsDrawer.GetPen: TogsPen;
begin
 Result := fPen;
end;

function TogsDrawer.GetBrush: TogsBrush;
begin
 Result := fBrush;
end;

procedure TogsDrawer.SetBrush(AValue: TogsBrush);
begin
 If AValue = nil then begin
  If fBrush <> nil then fBrush.Free;
  fBrush := TogsBrush.Create(0, nil)
 end
  else fBrush := AValue;
end;

function TogsDrawer.DrawerMode: TDrawerMode;
begin
 Result := fDrawerMode;
end;

procedure TogsDrawer.Clear(AColor: Longint);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawPoint(Point: TogsDot);
begin
 Point.Draw(Self);
end;

procedure TogsDrawer.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawLine(Point1, Point2: TogsDot; cutRequest: Boolean);
begin
 DrawLine(Point1.X, Point1.Y, Point2.X, Point2.Y, cutRequest);
end;

procedure TogsDrawer.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawPolyline(Points: TogsCollection; cutRequest: Boolean);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawPolygon(Points: TogsCollection; polyRect: TogsRect);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawSect(Sect: TSect);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawCircle(XA, YA, Radius: Double);
begin
 // virtual abstract procedure
end;

procedure TogsDrawer.DrawBitmap(Bitmap: TogsGeometry; bmRect: TogsRect);
begin
 // virtual abstract procedure
end;

procedure TogsDrawer.DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect);
begin
// virtual abstract procedure
end;

procedure TogsDrawer.DrawMarker(X, Y: Double; Text: String);
const R = 2;
var X_, Y_: Integer;
begin
 X_:= ogsSelector.XPix(X); Y_:= ogsSelector.YPix(Y);
 MoveTo(X_ - R, Y_ - R); LineTo(X_ + R, Y_ + R);
 MoveTo(X_ - R, Y_ + R); LineTo(X_ + R, Y_ - R);
end;

procedure TogsDrawer.DrawMarker(Point: TogsDot; Text: String);
const R = 2;
var X_, Y_: Integer;
begin
 With Point do begin
  X_:= ogsSelector.XPix(X); Y_:= ogsSelector.YPix(Y);
  MoveTo(X_ - R, Y_ - R); LineTo(X_ + R, Y_ + R);
  MoveTo(X_ - R, Y_ + R); LineTo(X_ + R, Y_ - R);
 end;
end;

procedure TogsDrawer.MoveTo(X, Y: Integer);
begin
// abstract
end;

procedure TogsDrawer.LineTo(X, Y: Integer);
begin
// abstract
end;

procedure TogsDrawer.MouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 With fogsSelector do
  If WheelDelta < 0 then fogsSelector.Scale(XGeo(MousePos.X), YGeo(MousePos.Y), 5) else
                         fogsSelector.Scale(XGeo(MousePos.X), YGeo(MousePos.Y), -5);
 DoOnPaint(Sender);
end;

procedure TogsDrawer.BeginPaint;
begin
// abstract
end;

procedure TogsDrawer.EndPaint;
begin
 // abstract
end;

procedure TogsDrawer.DoOnPaint(Sender: TObject);
begin
 If Assigned(fOnPaint) then fOnPaint(Sender);
end;

procedure TogsDrawer.RedrawAll;
begin
 DoOnPaint(Self);
end;

function TogsDrawer.SelectPen(Pen_: TogsPen): TogsPen;
begin
 Result := fPen;
 Pen := Pen_;
end;

procedure TogsDrawer.DeletePen(Pen_: TogsPen);
begin
 If Pen_ <> nil then begin Pen_.Free; Pen_:= nil; end;
end;

function TogsDrawer.SelectBrush(Brush_: TogsBrush): TogsBrush;
begin
 Result := fBrush;
 fBrush := Brush_;
end;

procedure TogsDrawer.DeleteBrush(Brush_: TogsBrush);
begin
 If Brush_ <> nil then begin Brush_.Free; Brush_:= nil; end;
end;

procedure TogsDrawer.Play(Drawer: TogsDrawer; Rect: TogsRect);
var I: Integer;
begin
 If not Assigned(fOnPlayerEvent) then
  For I := 0 to fcmdPlayer.Count - 1 do
   cmdPlayerItem[I].Play(Drawer, Rect)
    else
     For I := 0 to fcmdPlayer.Count - 1 do
      fOnPlayerEvent(Drawer, cmdPlayerItem[I]);
end;

{ TogsSpacer }

function TogsSpacer.GetSelected: boolean;
begin
 Result := CaptureRec.resObject <> nil;
end;

constructor TogsSpacer.Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 With CaptureRec.ClearParams do begin
  // установка свойств по умолчанию
 end;
 fDRawerMode := dmCapture;
end;

constructor TogsSpacer.CreateCapture(Selector: TogsSelector);
begin
 inherited Create(Selector, nil);
 With CaptureRec.ClearParams do begin
  // установка свойств по умолчанию
 end;
 fDRawerMode := dmCapture;
end;

function TogsSpacer.SelectByPoint(X, Y: Double; ogsObject: TogsGeometry): boolean;
begin
 Result := ogsObject.SelectByPoint(X, Y, CaptureRec);
end;

{ TogsSortedCollection }

constructor TogsSortedCollection.Create(OnCompare_: TListSortCompare;
 Duplicates_: Boolean = True; Capacity_: Integer = 1);
begin
 inherited Create(Capacity_);
 fOnCompare := OnCompare_;
 if not Assigned(fOnCompare) then fOnCompare := ComparePointers;
 fDuplicates := Duplicates_;
end;

constructor TogsSortedCollection.Load(Stream: TogsStream);
begin
 Stream.Read(fDuplicates, SizeOf(fDuplicates));
 inherited Load(Stream);
end;

procedure TogsSortedCollection.Store(Stream: TogsStream);
begin
 Stream.Write(fDuplicates, SizeOf(fDuplicates));
 inherited Store(Stream);
end;

function TogsSortedCollection.IndexOf(Item_: Pointer): Integer;
var Index: Integer;
begin
 Result := -1;
 if Search(KeyOf(Item_), Index) then
  begin
    if fDuplicates then
      while (Index < Count) and (Item_<> Items[Index]) do Inc(Index);
    if Index < Count then Result := Index;
  end;
end;

function TogsSortedCollection.Add(Item_: Pointer): Integer;
var Index: Integer;
begin
 Result := -1;
 Index := -1;
// WriteIn(['Search=',Search(KeyOf(Item_),Index), Index]);
 if (not Search(KeyOf(Item_),Index)) or Duplicates  then begin
  If Index = -1 then
   Result := inherited Add(Item_) else
   Result := inherited Insert(Index, Item_);
 end;
end;

function TogsSortedCollection.KeyOf(Item_: Pointer): Pointer;
begin
 Result := Item_;
end;

function TogsSortedCollection.Search(Item_: Pointer; var Index: Integer): Boolean;
var L, H, I, C: Integer;
begin
 Result := False;
 L := 0;
 H := fList.Count - 1;
 while L <= H do
 begin
   I := (L + H) shr 1;
   C := fOnCompare(KeyOf(Items[I]), Item_);
   if C < 0 then L := I + 1 else
   begin
     H := I - 1;
     if C = 0 then
     begin
       Result := True;
       if not fDuplicates then L := I;
     end;
   end;
 end;
// if Result then Index := L else Index := -1;
 Index := L;
end;

{ TogsStream }

{
const
  fmCreate        = $FF00;
  fmOpenRead      = 0;
  fmOpenWrite     = 1;
  fmOpenReadWrite = 2;
}

function TogsStream.getPosition: Integer;
begin
 Result := fStream.Position;
end;

procedure TogsStream.SetPosition(AValue: Integer);
begin
 fStream.Position := Avalue;
end;

constructor TogsStream.Create;
begin
 CreateMemoryStream();
 AssignSearchProcs(nil, nil);
end;

constructor TogsStream.CreateMemoryStream(Capacity_: Integer = 0; Selector_: TogsSelector = nil);
begin
 fStream := TMemStream.Create(Capacity_ <> -1);
// TExtMemoryStream(fStream).Capacity := Capacity_;
 fSelector := Selector_;
 AssignSearchProcs(nil, nil);
end;

constructor TogsStream.CreateFileStream(FileName_: String; Mode_: Word; Selector_: TogsSelector = nil);
begin
 fStream := TBufferedFileStream.Create(FileName_, Mode_);
 fSelector := Selector_;
 AssignSearchProcs(nil, nil);
end;

constructor TogsStream.CreateStringStream(Data_: String; Selector_: TogsSelector);
begin
// UTF-8: WriteText пишет байты UTF-8, DataString декодирует их без потерь
 fStream := TStringStream.Create(Data_, TEncoding.UTF8);
 fSelector := Selector_;
 AssignSearchProcs(nil, nil);
end;

destructor TogsStream.Destroy;
begin
 fStream.Free;
 inherited Destroy;
end;

procedure TogsStream.AssignSearchProcs(SearchForGet: TOnSearchGetProc; SearchForPut: TOnSearchPutProc);
begin
 If Assigned(SearchForGet) then fOnSearchGetProc := SearchForGet else
                                   fOnSearchGetProc := LinearSearchGet;
 If Assigned(SearchForPut) then fOnSearchPutProc := SearchForPut else
                                   fOnSearchPutProc := LinearSearchPut;
end;

function TogsStream.GetogsSelector: TogsSelector;
begin
 Result := fSelector;
end;

procedure TogsStream.SetogsSelector(AValue: TogsSelector);
begin
 fSelector := AValue;
end;

function TogsStream.Size: Integer;
begin
 Result := fStream.Size;
end;

function TogsStream.Read(var Buf; Count: Longint): Longint;
begin
 Result := fStream.Read(Buf, Count);
end;

function TogsStream.Write(const Buf; Count: Longint): Longint;
begin
 Result := fStream.Write(Buf, Count);
end;

function TogsStream.Read(var Buf: AnsiString): Longint;
begin
 Stream.Read(Result, SizeOf(Result));
 SetLength(Buf, Result);
 If Result <> 0 then Stream.Read(Buf[1], Result) else Buf := '';
end;

function TogsStream.Write(const Buf: AnsiString): Longint;
begin
 Result := System.Length(Buf);
 Stream.Write(Result, SizeOf(Result));
 If Result <> 0 then FStream.Write(Buf[1], Result);
end;

function TogsStream.ReadByte: Byte;
begin
 Stream.Read(Result, SizeOf(Byte));
end;

function TogsStream.ReadInt: Integer;
begin
 Stream.Read(Result, SizeOf(Integer));
end;

function TogsStream.ReadLongInt: LongInt;
begin
 Stream.Read(Result, SizeOf(LongInt));
end;

function TogsStream.ReadFloat: Double;
begin
 Stream.Read(Result, SizeOf(Double));
end;

procedure TogsStream.WriteByte(Value: Byte);
begin
 Stream.Write(Value, SizeOf(Byte));
end;

procedure TogsStream.WriteInt(Value: Integer);
begin
 Stream.Write(Value, SizeOf(Integer));
end;

procedure TogsStream.WriteLongInt(Value: LongInt);
begin
 Stream.Write(Value, SizeOf(LongInt));
end;

procedure TogsStream.WriteFloat(Value: Double);
begin
 Stream.Write(Value, SizeOf(Double));
end;

function TogsStream.ReadString(var Buf: AnsiString): Longint;
begin
 Stream.Read(Result, SizeOf(Result));
 SetLength(Buf, Result);
 If Result <> 0 then Stream.Read(Buf[1], Result) else Buf := '';
end;

function TogsStream.WriteString(const Buf: AnsiString): Longint;
begin
 Result := System.Length(Buf);
 Stream.Write(Result, SizeOf(Result));
 If Result <> 0 then FStream.Write(Buf[1], Result);
end;

procedure TogsStream.WriteText(const S: String);
var B: TBytes;
begin
 B := TEncoding.UTF8.GetBytes(S);
 if System.Length(B) > 0 then fStream.Write(B[0], System.Length(B));
end;

function TogsStream.ListLevel: Integer;
begin
 Result := System.Length(fListCounts);
end;

procedure TogsStream.BeginList(const Header: String);
begin
 WriteText(Header + '[');
 fListCounts := fListCounts + [0];
end;

procedure TogsStream.ListItem(const S: String);
var L: Integer;
begin
 L := System.Length(fListCounts);
 if L = 0 then begin WriteText(S); exit; end;
 if fListCounts[L - 1] > 0 then WriteText(',' + S) else WriteText(S);
 Inc(fListCounts[L - 1]);
end;

procedure TogsStream.EndList(const Footer: String);
begin
 if System.Length(fListCounts) > 0 then SetLength(fListCounts, System.Length(fListCounts) - 1);
 WriteText(']' + Footer);
end;

function TogsStream.DataString: String;
begin
 if fStream is TStringStream then Result := TStringStream(fStream).DataString else Result := '';
end;

function TogsStream.ReadUTF8: String;
var B: TBytes;
    L: Integer;
begin
 fStream.Read(L, SizeOf(L));
 if L <= 0 then exit('');
 SetLength(B, L);
 fStream.Read(B[0], L);
 Result := TEncoding.UTF8.GetString(B);
end;

procedure TogsStream.WriteUTF8(const S: String);
var B: TBytes;
    L: Integer;
begin
 B := TEncoding.UTF8.GetBytes(S);
 L := System.Length(B);
 fStream.Write(L, SizeOf(L));
 if L > 0 then fStream.Write(B[0], L);
end;

// поиск класса по регистрациогному номеру

Function LinearSearchGet(ClassNum: Integer): TogsBasicClass;
var I: Integer; ogsRegObj: TogsRegisteredClass;
begin
 Result := nil;
 For I := 0 to ogsRegisteredClasses.Count - 1 do begin
  ogsRegObj := TogsRegisteredClass(ogsRegisteredClasses[I]);
  If ogsRegObj.ClassNum = ClassNum then begin
   Result := ogsRegObj.objClassType;
   exit;
  end;
 end;
end;

// поиск регистрационного номера по классу объекта

Function LinearSearchPut(objClassType: TogsBasicClass): Integer;
var I: Integer; ogsRegObj: TogsRegisteredClass;
begin
 Result := -1;
 For I := 0 to ogsRegisteredClasses.Count - 1 do begin
  ogsRegObj := TogsRegisteredClass(ogsRegisteredClasses[I]);
  If ogsRegObj.objClassType = objClassType then begin
   Result := ogsRegObj.ClassNum;
   exit;
  end;
 end;
end;

function TogsStream.Get: TogsBasic;
var objType: SmallInt;
    ogsBasicClass: TogsBasicClass;
begin
 fStream.Read(objType, SizeOf(objType));
 If objType = 0 then begin Result := nil; exit;end;
 // ищем в ogsRegisteredObjects класс для загрузки объекта
 ogsBasicClass:= fOnSearchGetProc(objType);
 if ogsBasicClass = nil then raise Exception.Create(Fmt(['Не найден регистрационный код (Stream.Get): ',objType]));
 Result := ogsBasicClass.Load(Self);
end;

procedure TogsStream.Put(ogsObject: TogsBasic);
var objType: SmallInt;
    ogsBasicClass: TogsBasicClass;
begin
 If ogsObject = nil then begin
  objType := 0; FStream.Write(objType, SizeOf(ObjType));
  exit;
 end;
 // ищем в ogsRegisteredObjects класс для сохранения объекта
 objType := fOnSearchPutProc(TogsBasicClass(ogsObject.ClassType));
 if objType = -1 then raise Exception.Create(Fmt(['Не зарегистрирован класс (Stream.Put): ',ogsObject.ClassName]));
 Self.Write(objType, SizeOf(objType));
 ogsObject.Store(Self);
end;

function TogsStream.GetJSON: TJSONObject;
var S: UTF8String;
    Len: Integer;
    Value: TJSONValue;
begin
 Result := nil;
 fStream.Read(Len, SizeOf(Len));
 if Len <= 0 then exit;
 SetLength(S, Len);
 fStream.Read(S[1], Len);
 Value := TJSONObject.ParseJSONValue(String(S));
 if Value is TJSONObject then Result := TJSONObject(Value) else Value.Free;
end;

procedure TogsStream.PutJSON(jsonObject: TJSONObject);
var S: UTF8String;
    Len: Integer;
begin
 if jsonObject = nil then S := '' else S := UTF8String(jsonObject.ToJSON);
 Len := System.Length(S);
 fStream.Write(Len, SizeOf(Len));
 if Len <> 0 then fStream.Write(S[1], Len);
end;

{ TogsCollection }

function TogsCollection.GetCount: Integer;
begin
 Result := fList.Count;
end;

function TogsCollection.GetItem(Index: Integer): Pointer;
begin
 Result := fList[Index];
end;

procedure TogsCollection.SetItem(Index: Integer; AValue: Pointer);
begin
 TObject(Items[Index]).Free;
 fList[Index] := AValue;
end;

constructor TogsCollection.Create(Capacity_: Integer = 1);
begin
 fList := TList.Create;
 fList.Capacity := Capacity_;
end;

destructor TogsCollection.Destroy;
var I: Integer;
begin
 If fList <> nil then begin
  for I := fList.Count - 1 downto 0 do TObject(Items[I]).Free;
  fList.Free;
 end;
 inherited Destroy;
end;

constructor TogsCollection.Load(Stream: TogsStream);
var I, Count_, Capacity: Integer;
begin
  Stream.Read(Count_, SizeOf(Count_));
  Stream.Read(Capacity, SizeOf(Capacity));
  Create(Capacity);
  for I := 0 to Count_ - 1 do fList.Add(Stream.Get);
//  WriteIn(['col.Load.Count=',fList.Count ]);
end;

procedure TogsCollection.Store(Stream: TogsStream);
var I, Count_, Capacity: Integer;
begin
 Count_:= 0;
 Capacity := 1;
 if Assigned(fList) then begin
    Count_       := fList.Count;
    Capacity    := fList.Capacity;
  end;
  Stream.Write(Count_,SizeOf(Count_));
  Stream.Write(Capacity, SizeOf(Capacity));
 //
  for I := 0 to Count_ - 1 do Stream.Put(TogsGeometry(fList[I]));
end;

function TogsCollection.Add(Item_: Pointer): Integer;
begin
 If Assigned(fcheckTypeProc) then
  If not fcheckTypeProc(TogsGeometry(Item_)) then raise Exception.Create('Тип объекта не соответствует типу элемента коллекции TogsCollection.Add');
 Result := fList.Add(Item_);
end;

function TogsCollection.Insert(Index: Integer; Item_: Pointer): Integer;
begin
 If Assigned(fcheckTypeProc) then
  If not fcheckTypeProc(TogsGeometry(Item_)) then raise Exception.Create('Тип объекта не соответствует типу элемента коллекции TogsCollection.Insert');
 fList.Insert(Index, Item_);
 Result := Index;
end;

function TogsCollection.IndexOf(Item_: Pointer): Integer;
begin
 Result := fList.IndexOf(Item_);
end;

function TogsCollection.Delete(Index: Integer): Integer;
begin
 fList.Delete(Index);
// возвращает -1 если Index >= Count
 If fList.Count < Index then Result := -1 else Result := Index;
end;

function TogsCollection.AtFree(Index: Integer): Integer;
begin
 TogsGeometry(fList[Index]).Free;
 Result := Delete(Index);
end;

procedure TogsCollection.DeleteAll;
begin
 FList.Clear;
end;

procedure TogsCollection.FreeAll;
var I: Integer;
begin
 For I := 0 to FList.Count - 1 do TObject(FList[I]).Free;
 DeleteAll;
end;

{ TogsPoint2D }

function TogsDot.GetX: Double;
begin
 If ogsMatrix = nil then Result := fX else
  Result := xMatrix(ogsMatrix.X, fX, fY, ogsMatrix.Angle, ogsMatrix.Scale);
end;

function TogsDot.GetY: Double;
begin
 If ogsMatrix = nil then Result := fY else
    Result := yMatrix(ogsMatrix.Y, fX, fY, ogsMatrix.Angle, ogsMatrix.Scale);
end;

procedure TogsDot.SetX(AValue: Double);
begin
 fX := AValue;
end;

procedure TogsDot.SetY(AValue: Double);
begin
 fY := AValue;
end;

function TogsDot.GetCount: Integer;
begin
 Result := 1;
end;

function TogsDot.GetItem(Index: Integer): TogsGeometry;
begin
 Result := Self;
end;

procedure TogsDot.SetItem(Index: Integer; AValue: TogsGeometry);
begin
 If AValue is TogsDot then begin
 // Delphi не допускает вызов конструктора через экземпляр -> копируем поля (как TogsDot.CreateAs)
  fX := TogsDot(AValue).fX;
  fY := TogsDot(AValue).fY;
  Z := TogsDot(AValue).Z;
 end else
 // вызываем исключение, т.к. метод CreateAs не имеет проверки на тип
  raise Exception.Create(ClassName + 'SetItem raised type conversion exception');
end;

procedure TogsDot.SetogsSelector(Data: TogsSelector);
begin
 //
end;

constructor TogsDot.Create(X_, Y_: Double; Z_: Double = 0);
begin
 fX := X_;
 fY := Y_;
 Z := Z_;
end;

constructor TogsDot.CreateAs(ogsObject: TogsBasic);
var ogsDot: TogsDot;
begin
// !!!проверка отключена
// if not (ogsObject is TogsDot) then raise Exception.Create(ClassName + 'CreateAs raised type conversion exception');
 ogsDot := TogsDot(ogsObject);
 fX := ogsDot.fX;
 fY := ogsDot.fY;
 Z := ogsDot.Z;
end;

constructor TogsDot.Load(Stream: TogsStream);
begin
 Stream.Read(fX, SizeOf(fX));
 Stream.Read(fY, SizeOf(fY));
 Stream.Read(Z, SizeOf(Z));
end;

procedure TogsDot.Store(Stream: TogsStream);
begin
 Stream.Write(fX, SizeOf(fX));
 Stream.Write(fY, SizeOf(fY));
 Stream.Write(Z, SizeOf(Z));
end;

function TogsDot._Length: Double;
begin
 Result := 0;
end;

function TogsDot.StartPoint: TogsDot;
begin
 Result := Self;
end;

function TogsDot.EndPoint: TogsDot;
begin
 Result := Self;
end;

function TogsDot.Distance(ogsGeom: TogsGeometry): Double;
begin
 Result := ogcMathUtils.Distance(fX, fY, TogsDot(ogsGeom).X, TogsDot(ogsGeom).Y);
end;

function TogsDot.Distance(X_, Y_: Double): Double;
begin
 Result := ogcMathUtils.Distance(fX, fY, X_, Y_);
end;

function TogsDot.Equals(ogsGeom: TogsGeometry): Integer;
begin
 Result := ord((fX = TogsDot(ogsGeom).X) and (fY = TogsDot(ogsGeom).Y));
end;

function TogsDot.Visible(Rect: TogsRect): Boolean;
begin
// нет проверки Rect.Selector на nil
 Result := (fX <= Rect.XMax) and (fX >= Rect.XMin) and
           (fY <= Rect.YMax) and (fY >= Rect.YMin);
end;

procedure TogsDot.Draw(Drawer: TogsDrawer);
begin
 Drawer.DrawMarker(fX, fY);
end;

procedure TogsDot.DrawPoint(Drawer: TogsDrawer);
begin
 Drawer.DrawMarker(fX, fY);
end;

function TogsDot.getogsRect: TogsRect;
begin
 pointSect.XMin := X; pointSect.YMin := Y; pointSect.XMax := X; pointSect.YMax := Y;
 Result := pointSect;
end;

function TogsDot.WriteObj(Params: array of const): String;
begin
 WriteIn([ClassName,':',Fmt(Params)]);
 If (fX = X) and (fY = Y) then Result := String(Fmt(['X:',X,'Y:',Y])) else
  Result := String(Fmt(['X: ',X,'{',fX,')','Y:',Y,'{',fY,')']));
end;

{ TogsSimpleGeometrySet }

constructor TogsSimpleGeometrySet.Create(Capacity_: Integer);
begin
 fItems := TogsCollection.Create(Capacity_);
 fOgsRect := TogsRect.Create;
end;

destructor TogsSimpleGeometrySet.Destroy;
begin
 fItems.Free;
 fogsRect.Free;
 inherited Destroy;
end;

constructor TogsSimpleGeometrySet.CreateAs(ogsObject: TogsBasic);
var Obj: TogsSimpleGeometrySet;
    I: Integer;
begin
 if not (ogsObject is TogsSimpleGeometrySet) then raise Exception.Create(ClassName + 'CreateAs raised type conversion exception');
 Obj := TogsSimpleGeometrySet(ogsObject);
 fItems := TogsCollection.Create(Obj.Items.List.Capacity);
 fItems.CheckTypeProc := Obj.Items.CheckTypeProc;
// копия каждого элемента создается по классу элемента
 For I := 0 to Obj.Count - 1 do
  fItems.Add(TogsBasicClass(Obj.Item[I].ClassType).CreateAs(Obj.Item[I]));
 //
 fOgsRect := TogsRect.CreateAs(Obj.ogsRect);
end;

constructor TogsSimpleGeometrySet.Load(Stream: TogsStream);
begin
 fItems := TogsCollection(Stream.Get);
 fogsRect := TogsRect(Stream.Get);
 if fItems = nil then fItems := TogsCollection.Create;
 if fogsRect = nil then fogsRect := TogsRect.Create;
end;

procedure TogsSimpleGeometrySet.Store(Stream: TogsStream);
begin
 Stream.Put(fItems);
 Stream.Put(fogsRect);
end;

function TogsSimpleGeometrySet.List: TList;
begin
 REsult := fItems.List;
end;

procedure TogsSimpleGeometrySet.Clear;
begin
 fogsRect.Clear;
 fItems.FreeAll;
end;

function TogsSimpleGeometrySet.Add(Item_: TogsGeometry): Integer;
begin
 Result := fItems.Add(Item_);
 fogsRect.InsertRect(Item_.ogsRect);
end;

function TogsSimpleGeometrySet.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
begin
 For I := 0 to Count -1 do
  Item[I].Calculate(Action);
 If calcbBox in Action then begin
  fogsRect.Clear;
  For I := 0 to Count - 1 do
   fOgsRect.InsertRect(Item[I].ogsRect);
 end;
end;

function TogsSimpleGeometrySet.Visible(Rect: TogsRect): Boolean;
begin
 Result := fogsRect.VisibleIn(Rect);
end;

function TogsSimpleGeometrySet.GetogsRect: TogsRect;
begin
 Result := fogsRect;
end;

function TogsSimpleGeometrySet.GetCount: Integer;
begin
 Result := fItems.Count;
end;

function TogsSimpleGeometrySet.GetItem(Index: Integer): TogsGeometry;
begin
 Result := TogsGeometry(fItems.List[Index]);
end;

procedure TogsSimpleGeometrySet.SetItem(Index: Integer; AValue: TogsGeometry);
begin
 fItems.List[Index] := AValue;
end;

procedure TogsSimpleGeometrySet.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do begin
  Item[I].Draw(Drawer);
 end;
end;

procedure TogsSimpleGeometrySet.DrawPoint(Drawer: TogsDrawer);
var I: Integer;
begin
 For I := 0 to Count - 1 do Item[I].DrawPoint(Drawer);
end;

{ TogsRect }

function TogsRect.GetSect: TSect;
begin
 Result.XMin := XMin;
 Result.XMax := XMax;
 Result.YMin := YMin;
 Result.YMax := YMax;
end;

procedure TogsRect.SetSect(AValue: TSect);
begin
 XMin := AValue.XMin;
 XMax := AValue.XMax;
 YMin := AValue.YMin;
 YMax := AValue.YMax;
 Iter := 1; // !!!!?
end;

constructor TogsRect.Create;
begin
 Clear;
end;

procedure TogsRect.Clear;
begin
 Iter := 0;
 XMin := 0; XMax := 0; YMin :=0 ; YMax := 0;
end;

constructor TogsRect.CreateAs(MRect_: TogsRect);
begin
 XMax := MRect_.XMax; YMax := MRect_.YMax; XMin := MRect_.XMin; YMin := MRect_.YMin;
 Iter := MRect_.Iter;
end;

constructor TogsRect.CreateRect(XMin_, YMin_, XMax_, YMax_: Double);
begin
 Insert(XMin_, YMin_);
 Insert(XMax_, YMax_);
end;

procedure TogsRect.Assign(MRect_: TogsRect);
begin
 Iter := MRect_.Iter;
 XMax := MRect_.XMax;
 YMax := MRect_.YMax;
 XMin := MRect_.XMin;
 YMin := MRect_.YMin;
end;

constructor TogsRect.Load(Stream: TogsStream);
var Sect_: TSect;
begin
 Stream.Read(Iter, SizeOf(Iter));
 If Iter = 1 then begin
  Stream.Read(Sect_, SizeOf(Sect_));
  XMin := Sect_.XMin; YMin := Sect_.YMin;
  XMax := Sect_.XMax; YMax := Sect_.YMax;
 end;
end;

procedure TogsRect.Store(Stream: TogsStream);
var Sect_: TSect;
begin
 Stream.Write(Iter, SizeOf(Iter));
 If Iter = 1 then begin
  Sect_.XMin := XMin; Sect_.YMin := YMin;
  Sect_.XMax := XMax; Sect_.YMax := YMax;
  Stream.Write(Sect_, SizeOf(Sect_));
 end;
end;

function TogsRect.Insert(X_, Y_: Double): Boolean;
begin
 Result := False;
 If Iter = 0 then begin
  XMin := X_; YMin := Y_; XMax := X_; YMax := Y_;
  Result := True;
  Iter := 1;
 end else begin
  if X_< XMin then begin XMin := X_; Result := True; end;
  if Y_< YMin then begin YMin := Y_; Result := True; end;
  if X_> XMax then begin XMax := X_; Result := True; end;
  if Y_> YMax then begin YMax := Y_; Result := True; end;
 end;
end;

function TogsRect.InsertRect(Rect_: TogsRect): boolean;
begin
 If Rect_.Iter = 0 then begin Result := False; exit; end;
 Insert(Rect_.XMax, Rect_.YMax);
 Insert(Rect_.XMin, Rect_.YMin);
 Insert(Rect_.XMax, Rect_.YMin);
 Insert(Rect_.XMin, Rect_.YMax);
 Result := True;
end;

function TogsRect.Visible(Sect_: TSect): Boolean;
begin
 Result := True;
 If XMax < Sect_.XMin   then begin Result := False; exit;end;
 If XMin > Sect_.XMax  then begin Result := False; exit;end;
 If YMin > Sect_.YMax    then begin Result := False; exit;end;
 If YMax < Sect_.YMin then begin Result := False; exit;end;
end;

function TogsRect.isRect: Boolean;
begin
 Result := False;
 If Iter = 0 then exit;
 Result := (XMin <> XMax) and (YMin <> YMax);
end;

function TogsRect.Width: Double;
begin
 Result := XMax - XMin;
end;

function TogsRect.Height: Double;
begin
 Result := YMax - YMin;
end;

function TogsRect.isVertical: Boolean;
begin
 Result := Height >= Width;
end;

procedure TogsRect.Move(Dx, Dy: Double);
begin
 If Iter = 0 then exit;
 XMin := XMin + Dx; YMin := YMin + Dy;
 XMax := XMax + Dx; YMax := YMax + Dy;
end;

procedure TogsRect.Scale(X, Y, Koef: Double);
begin
 // масштабирование относительно точки
end;

function TogsRect.Inflate(deltaX, deltaY: Double): TogsRect;
begin
 If Iter <> 0 then begin
  XMin := XMin - deltaX; XMax := XMax + deltaX;
  YMin := YMin - deltaY; YMax := YMax + deltaY;
 //
  If Assigned(fOnChange) then fOnChange(Self);
 end;
 Result := Self;
end;

function TogsRect.PointIn(X, Y: Double): Boolean;
begin
// WriteIn(['XY=',X,Y,'XMin',XMin,'XMax',XMax,'YMin',YMin,'YMax=',YMax]);
 Result := (X >= XMin) and (X<= XMax) and
           (Y >= YMin) and (Y<= YMax);
end;

function TogsRect.PointIn(X, Y, Delta: Double): Boolean;
begin
// WriteIn(['XY=',X,Y,'XMin',XMin,'XMax',XMax,'YMin',YMin,'YMax=',YMax]);
 Result := (X >= XMin - Delta) and (X <= XMax + Delta) and
           (Y >= YMin - Delta) and (Y<= YMax + Delta);
end;

function TogsRect.VisibleIn(Rect: TogsRect): Boolean;
begin
 Result := False;
 If XMin > Rect.XMax then exit;
 If YMin > Rect.YMax then exit;
 If XMax < Rect.XMin then exit;
 If YMax < Rect.YMin then exit;
 Result := True;
end;

function TogsRect.VisibleAllIn(Rect: TogsRect): Boolean;
begin
 Result := (XMin >= Rect.XMin) and (XMax <= Rect.XMax) and (YMin >=Rect.YMin) and (YMax <= Rect.YMax)
end;

function TogsRect.IntersectWith(Rect: TogsRect): TSect;
begin
 Result.XMin := 0;
 Result.YMin := 0;
 Result.XMax := 0;
 Result.YMax := 0;
 if (Rect = nil) then Exit;
 if (Iter = 0) or (Rect.Iter = 0) then Exit;

 Result.XMin := Max(XMin, Rect.XMin);
 Result.YMin := Max(YMin, Rect.YMin);
 Result.XMax := Min(XMax, Rect.XMax);
 Result.YMax := Min(YMax, Rect.YMax);

 // no intersection
 if (Result.XMin >= Result.XMax) or (Result.YMin >= Result.YMax) then
 begin
  Result.XMin := 0;
  Result.YMin := 0;
  Result.XMax := 0;
  Result.YMax := 0;
 end;
end;

procedure TogsRect.Draw(Drawer: TogsDrawer);
begin
// Drawer.DrawSect(Sect);
end;

function TogsRect.WriteObj(Params: array of const): String;
begin
 WriteIn([ClassName,':',Fmt(Params)]);
 If Iter = 0 then
  Result := Fmt(['Iter:',Iter]) else
  Result := Fmt(['XMin:',XMin,'YMin:',YMin,'XMax:',XMax,'YMax:',YMax]);
end;

{ TogsRegisteredClass }
function RegisteredObjectsCompare(Item1, Item2: Pointer): Integer;
begin
 Result := TogsRegisteredClass(Item1).ClassNum - TogsRegisteredclass(Item2).ClassNum;
end;

constructor TogsRegisteredClass.Create(objClassType_: TogsBasicClass;
 ClassNum_: SmallInt; classRank_: byte);
begin
 objClassType := objClassType_;
 ClassNum := ClassNum_;
 classRank := classRank_;
end;

{ TogsProperties }


initialization
 pointSect := TogsRect.Create; pointSect.Iter := 1;
//
 ogsRegisteredClasses := TogsSortedCollection.Create(RegisteredObjectsCompare, True);
// регистрация классов
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsRegisteredClass, 102, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsSortedCollection, 101, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsCollection, 100, 1));
// габариты и простые наборы записываются Stream.Put в составе геометрий
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsRect, 103, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsSimpleGeometrySet, 104, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsPolyCollection, 105, 1));
finalization
 ogsRegisteredClasses.Free;
 PointSect.Free;
end.
