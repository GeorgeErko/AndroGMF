unit GMFGeometry;

interface

uses Classes, SysUtils, System.UITypes, System.JSON, FMX.Graphics,
    // OGC
     ogcGeometry, ogcBasic, ttfGeometry,
    // GMF
     ogcCallbackTypes, ogcLType, ogcTypedCollect, ogcMathUtils;

// примитивы для хранения/отображения примитивов
// с предустановленными свойчтвами: Color, Sign
// и выполнением рисовки из старых библиотек формата GMF

type
  TgmfBlock = class;

  { TgmfSpacer - объект для захвата сложных примитивов через методы
                 отрисовки их частей, где вместо рисования части сложного
                 примитива, происходит вызов ф-ция захвата
  }

  TgmfSpacer = class(TogsSpacer)
  protected
   function GetCanvas: TCanvas; override;
  public
   procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); overload; override;
   procedure DrawSect(Sect: TSect); override;
   procedure DrawCircle(XA, YA, Radius: Double); override;
   procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); overload; override;
   procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); override;
   procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
  //
   procedure MoveTo(X, Y: Integer); override;
   procedure LineTo(X, Y: Integer); override;
  end;


  TgmfSortedGeometry = class(TogsSortedCollection)
  // коллекция для сортировки пространственных примитивов GMF
  end;

 { TgmfLineType }

  TgmfLineType = class(TogsBasic)
  private
   fogsSelector: TogsSelector;
  // тип линии из библиотеки
   fSign: TGeoLine;
   //fSelected: Boolean;
   function GetName: String;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
  public
   constructor Create(Selector: TogsSelector; LTName: String; Sign_: TGeoLine);
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure AddPartOfLineType(PLT: TPartOfLineType);
   property Name: String read GetName;
   //property Selected: Boolean read fSelected write fSelected;
   procedure Draw(Drawer: TogsDrawer; ogsLine: TogsLineString; Scale: Double;
    Selected: Boolean);
   function SelectByPoint(ogsLine: TogsLineString; X_, Y_, Scale: Double;
    var Params: TCaptureRec): boolean;
  //
   procedure UpdateBlockTableItems(PSLib: TStrTypedCollection);
  end;

 { TgmfPoint }

  TColorByRec = packed record
  private
   fcolorByDefs  : boolean; // цвет примитива по умолчанию
   fcolorByObject: boolean; // цвет по объекту (глобальный параметр чертежа
                            // в ogsSelector)
   fcolorByLayer : boolean; // цвет по слою
   fcolorByBlock : boolean; // цвет по блоку
   procedure Init;
   procedure SetColorByObject;
   procedure SetColorByLayer;
   procedure SetColorByBlock;
  public
   property colorByDefs  : boolean read fcolorByDefs;
   property colorByObject: boolean read fcolorByObject;
   property colorByLayer : boolean read fcolorByLayer;
   property colorByBlock : boolean read fcolorByBlock;
  end;

  TgmfPoint = class(TogsPoint)
  private
   fSign : TgmfBlock;
   fAttribs: TTextAttribs;
   fColorBy: TcolorBy;
   fColor: TColor;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
  // временно в виде переменных, !!! необходимо реализовать в виде свойств
   Angle : Single;
   Scale : Single;
  // имя блока, прочитанное из потока (gmfBlock восстанавливается по таблице блоков)
   BlockName: String;
   constructor CreateAs(ogsObject: TogsBasic); override;
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   procedure Clear; override;
  //
   property gmfBlock: TgmfBlock read fSign write fSign;
   property Attribs : TTextAttribs read fAttribs;
  //
   procedure AddAttribute(Prim: TogsTextParams);
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   procedure SetSelected(AValue: boolean); override;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  // отрисовка
   procedure Draw(Drawer: TogsDrawer); override;
  // GeoJSON: служебные поля в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  end;

  { TgmfLineString }

  TgmfLineString = class(TogsLineString)
  private
   fSign :TgmfLineType;// тип линии
   fWidth,
   fScale: Single;
   fColorBy: TColorBy;
   fColor: TColor;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
  // имя типа линии, прочитанное из потока (lType восстанавливается по таблице типов линий)
   LineTypeName: String;
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   property lType : TgmfLineType read fSign write fSign;
   property Width : Single read fWidth write fWidth;
   property Scale : Single read fScale write fScale;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // GeoJSON: служебные поля в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TgmfArc }

  TgmfArc = class(TgmfLineString)
   A, B, C, D: TogsDot;
   constructor Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
   destructor Destroy; override;
  //
   procedure CreateVertexes;
   function Radius: Double;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TgmfMultiLineString }

  TgmfMultiLineString = class(TogsMultiLineString)
  private
   fSign : TgmfLineType;
   fScale,
   fWidth: Single;
   fColorBy: TColorBy;
   fColor: TColor;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
   procedure SetLineType(AValue: TgmfLineType);
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
   LineTypeName: String;
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   property LineType: TgmfLineType read fSign write SetLineType;
   property Scale: Single read fScale write fScale;
   property Width: Single read fWidth write fWidth;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // GeoJSON: служебные поля в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TgmfPolygon }

  TgmfPolygon = class(TogsPolygon)
  private
   fSign : Pointer;//TSquare_Sign;
   fColorBy: TColorBy;
   fColor : TColor;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
   LineColor: TColor; // временно для отображения
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure Draw(Drawer: TogsDrawer); override;
  // GeoJSON: служебные поля в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  end;

  { TgmfMultiPolygon }

  TgmfMultiPolygon = class(TogsMultiPolygon)
  private
   fSign : Pointer;//TSquare_Sign;
   fColorBy: TColorBy;
   fColor : TColor;
   function GetSign: Pointer; override;
   procedure SetSign(AValue: Pointer); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
   LineColor: TColor; // временно для отщбражения
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  //
   procedure Draw(Drawer: TogsDrawer); override;
  // GeoJSON: служебные поля в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  end;

  { TgmfBlock }

  TgmfBlock = class(TgmfPoint)
  protected
   procedure SetogsSelector(Data: TogsSelector); override;
  public
  // временно публичные свойства
   Name: String;
   ID: Integer;
   Geometry: TogsGeometryCollection;
   constructor Create(Selector: TogsSelector; Name_: String; ID_: Integer; X_, Y_,
    Z_: Double);
   destructor Destroy; override;
   procedure Clear; override;
  //
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
  // события, по которым происходит заполнение Geometry
   procedure PolyEvent(Poly: PGeoPoint; penColor, brushColor: TColor; lineWidth: Single; useColor: Boolean; isPolygon: Boolean);
   procedure TextEvent(X, Y: Double; FontName: String; txtHeight, txtAngle,
    txtScale: Double; txtColor: TColor; Align: byte; Bl, It, Un: Boolean; Text,
    AttrName: String);
   procedure Draw(Drawer: TogsDrawer); override;
   function AddPrim(Prim: TogsGeometry): Integer; virtual;
  // bBox
   function Calculate(Action: TCalcActionSet): Integer; override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
   procedure SetSelected(AValue: boolean); override;
  //
   function FindAttribute(AttrName_: String; out Prim: Pointer): Boolean; override;
  end;

 { TgmfFiller - площадная векторно-растровая заливка полигонов}

 TgmfHatchStyle = class(TgmfPoint)

 end;

 // сортировка пространственных данных, аналогично GMF-сортировке
 // по площади для площадных - > остальные в порядке добавления
 function SortByGMFProc(Item1, Item2: Pointer): Integer;


implementation uses ogcProperties, Writer, ogcLTDrawer;

{ TgmfArc }

constructor TgmfArc.Create(ogsSelector_: TogsSelector; ArcParams: TArcRec);
begin
 inherited Create(ogsSelector_);
 With ArcParams do begin
  A := TogsDot.Create(AX, AY);
  B := TogsDot.Create(BX, BY);
  D := TogsDot.Create(DX, DY);
 // расчитываем центр дуги окружности
  C := TogsDot.Create(0, 0);
  solving_arc_circle(A.fX, A.fY, B.fX, B.fY, D.fX, D.fY, C.fX, C.fY);
 end;
end;

destructor TgmfArc.Destroy;
begin
 inherited Destroy;
 A.Free; B.Free; D.Free; C.Free;
end;

procedure TgmfArc.CreateVertexes;
const qCount = 25;
var I, Quants: Integer; Col: TogsCollection;
begin
 Quants := qCount;
 Col := arc_Circle3(C.fX, C.fY, A.fX, A.fY, B.fX, B.fY, Quants);
 For I := 0 to Col.Count - 1 do
  AddPoint(TlDot(Col[I]).XDot, TlDot(Col[I]).YDot, 0);
 Col.Free;
end;

function TgmfArc.Radius: Double;
begin
 Result := Sqrt(Sqr(A.fX - C.fX ) + Sqr(A.fY - C.fY));
end;

procedure TgmfArc.Draw(Drawer: TogsDrawer);
var I: Integer;
begin
 inherited Draw(Drawer);
 A.Draw(Drawer);B.Draw(Drawer);C.Draw(Drawer);D.Draw(Drawer);
end;

function TgmfArc.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var X1, Y1: Double; Dist: Integer;
begin
// захват по траектории дуги
 Dist := ogsSelector.pixDist(dist_to_arc(C.fX, C.fY, A.fX, A.fY, B.fX, B.fY, X_, Y_, X1 , Y1));
 If (Dist >= 0 ) and (Dist <= Params.CaptureParam) then begin
  Params.resCapture := Dist;
  Params.resCaptureOf := ckLine;
  Params.resObject := Self;
  Result := True;
 end else
  Result := False;
end;

{ TColorByRec }

procedure TColorByRec.Init;
begin
 fcolorByObject := True;
 fcolorByLayer  := False;
 fcolorByBlock  := False;
end;

procedure TColorByRec.SetColorByObject;
begin
 fcolorByObject := True;
 fcolorByLayer  := False;
 fcolorByBlock  := False;
end;

procedure TColorByRec.SetColorByLayer;
begin
 fcolorByObject := False;
 fcolorByLayer  := True;
 fcolorByBlock  := False;
end;

procedure TColorByRec.SetColorByBlock;
begin
 fcolorByObject := False;
 fcolorByLayer  := True;
 fcolorByBlock  := True;
end;

{ TgmfSpacer }

function TgmfSpacer.GetCanvas: TCanvas;
begin
// WriteIn(['Seector=',ogsSelector = nil]);
// WriteIn(['Drawer=',ogsSelector.ogsDrawer = nil]);
// WriteIn(['Canvas=',ogsSelector.ogsDrawer.Canvas = nil]);
 Result := ogsSelector.ogsDrawer.Canvas;
end;

procedure TgmfSpacer.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
var Dist: Integer;
    PX, PY: Double;
begin
 Dist := ogsSelector.pixDist(Dist_Point_Edge(CaptureRec.XCapture, CaptureRec.YCapture, X, Y, X1, Y1, PX, PY));
 If Dist <= CaptureRec.CaptureParam then begin
  CaptureRec.resCapture := Dist;
  CaptureRec.resCaptureOf := ckLine;
  CaptureRec.resObject := CaptureRec.CaptureObject;
 end;
end;

procedure TgmfSpacer.DrawSect(Sect: TSect);
begin
end;

procedure TgmfSpacer.DrawCircle(XA, YA, Radius: Double);
var N: Integer;
    I: Integer;
    Col: TogsCollection;
    D1, D2: TlDot;
    Dist: Integer;
    PX, PY: Double;
begin
 If Disable then exit;
 N := 25;
 Col := circle(XA, YA, Radius, N);
 For I := 0 to Col.Count - 2 do begin
  D1 := Col[I]; D2 := Col[I + 1];
  Dist := ogsSelector.pixDist(Dist_Point_Edge(CaptureRec.XCapture, CaptureRec.YCapture,
                                               D1.XDot, D1.YDot, D2.XDot, D2.YDot, PX, PY));
  If Dist <= CaptureRec.CaptureParam then begin
   CaptureRec.resCapture := Dist;
   CaptureRec.resCaptureOf := ckLine;
   CaptureRec.resObject := CaptureRec.CaptureObject;
   break
  end;
 end;
 Col.Free;
end;

procedure TgmfSpacer.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
var
 I: Integer;
 P0, P1: TogsDot;
begin
 if Disable then Exit;
 if (Points = nil) or (Points.Count < 2) then Exit;
 for I := 0 to Points.Count - 2 do begin
  P0 := TogsDot(Points.Items[I]);
  P1 := TogsDot(Points.Items[I + 1]);
  DrawLine(P0.fX, P0.fY, P1.fX, P1.fY, cutRequest);
 end;
end;

procedure TgmfSpacer.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
var
 I: Integer;
 Part: TogsPolyCollection;
begin
 if Disable then Exit;
 if (Parts = nil) or (Parts.Count = 0) then Exit;
 for I := 0 to Parts.Count - 1 do begin
  Part := TogsPolyCollection(Parts[I]);
  DrawPolyline(Part, cutRequest);
 end;
end;

procedure TgmfSpacer.DrawPolyPolygon(Polygons: TogsCollection;
 polyRect: TogsRect);
begin
//
// WriteIn(['DrawPoly']);
end;

procedure TgmfSpacer.MoveTo(X, Y: Integer);
begin
//
end;

procedure TgmfSpacer.LineTo(X, Y: Integer);
begin
//
end;

{ TgmfBlock }

procedure TgmfBlock.SetogsSelector(Data: TogsSelector);
var I: Integer;
begin
 inherited SetogsSelector(Data);
 try
  If Geometry <> nil then
   For I := 0 to Geometry.Count - 1 do
   Geometry.Item[I].SetogsSelector(Data);
 except
   WriteIn(['TgmfBlock.SetogsSelector.Exceptclass=',Geometry.Item[I].ClassName]);
 end;
end;

constructor TgmfBlock.Create(Selector: TogsSelector; Name_: String;
 ID_: Integer; X_, Y_, Z_: Double);
begin
// для недобавления точки в габариты объекта
// 1. Selector.SelectorMode.smAddLocked
// 2. Selector = nil
 inherited Create(X_, Y_, Z_, {Selector} nil);
 Name := Name_;
 ID := ID_;
 Geometry := TogsGeometryCollection.Create(Selector);
 ogsSelector := Selector;
// WriteIn(['Create=',ogsRect]);
end;

destructor TgmfBlock.Destroy;
begin
 Geometry.Free;
 inherited Destroy;
end;

procedure TgmfBlock.Clear;
begin
 inherited Clear;
 Geometry.Items.FreeAll;
end;

constructor TgmfBlock.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 Name := Stream.ReadUTF8;
 Geometry := TogsGeometryCollection(Stream.Get);
 if Geometry = nil then Geometry := TogsGeometryCollection.Create(ogsSelector);
end;

procedure TgmfBlock.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
 Stream.WriteUTF8(Name);
 Stream.Put(Geometry);
end;

procedure TgmfBlock.PolyEvent(Poly: PGeoPoint; penColor,
 brushColor: TColor; lineWidth: Single; useColor: Boolean; isPolygon: Boolean);
var PolyS: TPoly_Single;
    Polygon: TogsPolygon;
    PolyLine: TogsLineString;
    I: Integer;
    P: PGeoPoint;
begin
// добавляем полилинию или полигон в Geometry
// WriteIn(['exePolyevent', isPolygon]);
 If isPolygon then begin
//  WriteIn(['AddPolygon=',brushColor]);
  PolyS := TPoly_Single.Create(ogsSelector);
  Polygon := TgmfPolygon.Create(ogsSelector);
  Polygon.Color := brushColor;
  P := Poly;
//  WriteIn(['exeP.Count=', P.Count]);
  For I := 0 to P.Count - 1 do begin
 //  WriteIn([P.X, P.Y]);
   PolyS.AddPoint(P.X, P.Y, 0);
   P := P.Next;
  end;
  Polygon.Add(PolyS);
//  Polygon.Calculate([calcbBox]);
  Geometry.Add(Polygon);
 // Geometry.Calculate([calcbBox, calcSquare, calcRelation]);
 end else begin
//   WriteIn(['AddPolyline=',penColor]);
  PolyLine := TgmfLineString.Create(ogsSelector);
  PolyLine.Color := penColor;
  P := Poly;
  For I := 0 to P.Count - 1 do begin
   PolyLine.AddPoint(P.X, P.Y, 0);
   P := P.Next;
  end;
 //  WriteIn(['Geom.XY',TDot(Poly[I]).fX, TDot(Poly[I]).fY]);
  Geometry.Add(Polyline);
 // !!!
 // вычислено значение для непреобразованного примитива
 // после преобразований необходимо вызвать Geometry.Calculate
 // для расчета габаритов преобразованного блока
  Geometry.Calculate([calcbBox]);
//  With Geometry.ogsRect do WriteIn(['Geom.ogsRect=',xMin, xMax, ymin, Ymax]);
 end;
end;

procedure TgmfBlock.TextEvent(X, Y: Double; FontName: String; txtHeight, txtAngle, txtScale: Double;
                              txtColor: TColor; Align: byte; Bl, It, Un: Boolean; Text, AttrName: String);
var FC: TFontCollect;
    txtString: TogsTextString;
    Index: Integer;
begin
Index := ogsFontManager.FindBy(FontName, ItalicBold(Bl, It), FC);
 If (FC = nil) then begin
  WriteIn(['Не найден шрифт: ' + FontName]);
  exit;
 end;
// загружаем шрифт из файла
 FC.LoadModeComplete;
// WriteIn(['txtColor=', txtColor]);
 txtString := TogsTextString.Create(ogsSelector, FC, X, Y, 0, txtHeight,
                                     txtAngle, txtScale, AlignText(Align), Text, AttrName,
                                      txtColor, True);
// txtString.Calculate([calcbBox]);
// WriteIn(['Text',Geometry.ogsRect,txtString.ogsRect]);
 Geometry.Add(txtString);
// Geometry.Calculate([calcbBox]);
end;

procedure TgmfBlock.Draw(Drawer: TogsDrawer);
begin
// WriteIn(['Block=',Name,fX,fY]);
 Geometry.Draw(Drawer);
end;

function TgmfBlock.AddPrim(Prim: TogsGeometry): Integer;
begin
// WriteIN(['Block.AddPrim']);
 If Prim is TogsPoint then Prim.Calculate([calcbBox, calcRelation, calcSquare]) else
  If Prim is TogsMultiPoint then Prim.Calculate([calcLength, calcbBox]) else
                                 Prim.Calculate([calcRelation, calcSquare, calcbBox]);
 ogsRect.InsertRect(Prim.ogsRect);
 if ogsSelector <> nil then ogsSelector.AddPrim(Prim);
 Result := Geometry.Add(Prim);
end;

function SortByGMFProc(Item1, Item2: Pointer): Integer;
begin
 Result := 0;
 If TogsGeometry(Item1).Square < TogsGeometry(Item2).Square then Result := 1 else
 If TogsGeometry(Item1).Square = TogsGeometry(Item2).Square then begin
//   If (TObject(Item1) is TogsPoint) and (TObject(Item2) is TogsPoint) then
//     Result := -1 else
  Result := 0
 end else
 If TogsGeometry(Item1).Square > TogsGeometry(Item2).Square then Result := -1;
end;

function TgmfBlock.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
    Poly: TogsPolygon;
    mPoly: TogsMultiPolygon;
begin
// If not(calcbBox in Action) and not(calcSortBy in Action) and
 //    not(calcTess in Action) then }
      Result := Geometry.Calculate(Action);
 If calcbBox in Action then ogsRect.Sect := Geometry.ogsRect.Sect;
 // сортируем по площадям примитивов, аналогично GMF
 If calcSortBy in Action then
 begin
  for I := 0 to Geometry.Count - 1 do
   if (Geometry.Item[I] is TogsPolygon) then
   begin
    Poly := TogsPolygon(Geometry.Item[I]);
    if Poly.Square = -1 then Poly.Calculate([calcSquare]);
   end else
   if (Geometry.Item[I] is TogsMultiPolygon) then
   begin
    mPoly := TogsMultiPolygon(Geometry.Item[I]);
    if mPoly.Square = -1 then mPoly.Calculate([calcSquare]);
   end;
  Result := Geometry.SortByProc(SortByGMFProc, True);
 end;
end;

function TgmfBlock.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
begin
 Result := Geometry.SelectByPoint(X_, Y_, Params);
end;

procedure TgmfBlock.SetSelected(AValue: boolean);
var I: Integer;
begin
 For I := 0 to Geometry.Count - 1 do Geometry[I].Selected := AValue;
end;

function TgmfBlock.FindAttribute(AttrName_: String; out Prim: Pointer): Boolean;
begin
// !!! обратить внимание на вложенность объектов
// осуществлять ли поиск по иерархии ???
 Result := Geometry.FindAttribute(AttrName_, Prim);
end;

{ TgmfLineType }

function TgmfLineType.GetSign: Pointer;
begin
 Result := fSign;
end;

procedure TgmfLineType.SetSign(AValue: Pointer);
begin
 fSign := AVAlue;
end;

function TgmfLineType.GetName: String;
begin
 if fSign = nil then begin Result := ''; exit; end;
 Result := fSign.NameOf;
end;

constructor TgmfLineType.Create(Selector: TogsSelector; LTName: String; Sign_: TGeoLine);
var Mem: TogsStream;
    I: Integer; PS: TLineStruct;
begin
// делаем копию экземпляра типа линии GMF
{ старый вызов
 Mem := TogsStream.CreateMemoryStream;
 Sign_.Store(Mem); Mem.Position := 0;
 fSign := TGeoLine.Load(Mem);
 Mem.Free;
}
 fSign := TGeoLine.Create(LTName);
 fogsSelector := Selector;
end;

procedure TgmfLineType.AddPartOfLineType(PLT: TPartOfLineType);
begin
 fSign.Structura.Add(TLineStruct.AssignPartOfLineType(PLT));
end;

destructor TgmfLineType.Destroy;
begin
 fSign.Free;
 inherited Destroy;
end;

constructor TgmfLineType.Load(Stream: TogsStream);
begin
 fogsSelector := Stream.ogsSelector;
 fSign := TGeoLine(Stream.Get);
end;

procedure TgmfLineType.Store(Stream: TogsStream);
begin
 Stream.Put(fSign);
end;

procedure TgmfLineType.Draw(Drawer: TogsDrawer; ogsLine: TogsLineString; Scale: Double; Selected: Boolean);
var I: Integer;
begin
 ogcLTDrawer.DrawGeoLine(Drawer, fSign, ogsLine, Scale, 0.3, 0, Selected);
end;

function TgmfLineType.SelectByPoint(ogsLine: TogsLineString; X_, Y_, Scale: Double; var Params: TCaptureRec): boolean;
var Drawer: TgmfSpacer;
begin
 Result := False;
 Drawer := TgmfSpacer.CreateCapture(nil);
 Drawer.ogsSelector := fogsSelector;
 Drawer.CaptureRec.XCapture := X_; Drawer.CaptureRec.YCapture := Y_;
 Drawer.CaptureRec.CaptureObject := ogsLine;
  ogcLTDrawer.DrawGeoLine(Drawer, fSign, ogsLine, Scale, 0.3, 0, False);
  If Drawer.CaptureRec.resObject <> nil then begin
   Result := True;
   Params := Drawer.CaptureRec;
  end;
 Drawer.Free;
end;

procedure TgmfLineType.UpdateBlockTableItems(PSLib: TStrTypedCollection);
var I: Integer;
    PS: ogcLType.TLineStruct;
    Block: TgmfBlock;
begin
// WriteIn(['Update', Sign=nil]);
If fSign = nil then exit;
fSign.Points.DeleteAll;
for I:=0 to fSign.Structura.Count-1 do begin
 PS := fSign.Structura[I];
  If PS.BitOf = bt_Custom then begin
   Block := TgmfBlock(PSLib.SearchBy(PS.Param4S));
  // WriteIn(['Block=', Block = nil]);
   If Block <> nil then
    fSign.Points.Add(Block) else
    fSign.Points.Add(@ZnakNil);
  end else
   fSign.Points.Add(@ZnakNil);
 end;
//WriteIn(['Points.Count = ', fSign.Points.Count]);
end;

{ TgmfPoint }

function TgmfPoint.GetSign: Pointer; begin Result := fSign; end;

procedure TgmfPoint.SetSign(AValue: Pointer); begin fSign := AValue; end;

procedure TgmfPoint.SetColorBy(AValue: TColorBy); begin fColorBy := AValue; end;

function TgmfPoint.GetColorBy: TColorBy; begin Result := fColorBy; end;

function TgmfPoint.GetColor: TColor; begin Result := fColor; end;

procedure TgmfPoint.SetColor(AValue: TColor); begin fColor := AVAlue; end;

constructor TgmfPoint.CreateAs(ogsObject: TogsBasic);
var Obj: TgmfPoint;
begin
 if not (ogsObject is TgmfPoint) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TgmfPoint(ogsObject);
 Angle := Obj.Angle;
 Scale := Obj.Scale;
 fSign := Obj.gmfBlock;
 BlockName := Obj.BlockName;
 if Obj.Attribs <> nil then fAttribs:= TTextAttribs.CreateAs(Obj.Attribs);
end;

destructor TgmfPoint.Destroy;
begin
 If fAttribs <> nil then fAttribs.Free;
 inherited Destroy;
end;

constructor TgmfPoint.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 BlockName := Stream.ReadUTF8;
 fAttribs := TTextAttribs(Stream.Get);
 Stream.Read(Angle, SizeOf(Angle));
 Stream.Read(Scale, SizeOf(Scale));
end;

procedure TgmfPoint.Store(Stream: TogsStream);
var bName: String;
begin
 inherited Store(Stream);
//
 If fSign = nil then
  bName := BlockName
 else
  bName := gmfBlock.Name;
 Stream.WriteUTF8(bName);
//
 Stream.Put(fAttribs);
 Stream.Write(Angle, SizeOf(Angle));
 Stream.Write(Scale, SizeOf(Scale));
end;

procedure TgmfPoint.Clear;
begin
 inherited Clear;
// устанавливаем масштаб по умолчанию
// Scale := 1;
end;

procedure TgmfPoint.AddAttribute(Prim: TogsTextParams);
begin
 If fAttribs = nil then fAttribs := TTextAttribs.Create;
 fAttribs.Add(Prim);
end;

function TgmfPoint.FeatureProperties: TJSONObject;
var Ogs, A: TJSONObject;
    Arr: TJSONArray;
    I: Integer;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 if gmfBlock <> nil then Ogs.SetString('block', gmfBlock.Name) else
 if BlockName <> '' then Ogs.SetString('block', BlockName);
 Ogs.SetFloat('angle', Angle);
 Ogs.SetFloat('scale', Scale);
 Ogs.SetString('color', ColorToHex(Color));
// значения текстовых атрибутов вставки блока: [{"attr": имя, "text": значение}]
 if (fAttribs <> nil) and (fAttribs.Count > 0) then begin
  Arr := TJSONArray.Create;
  for I := 0 to fAttribs.Count - 1 do begin
   A := TJSONObject.Create;
   A.AddPair('attr', fAttribs[I].fAttrName);
   A.AddPair('text', fAttribs[I].fText);
   Arr.AddElement(A);
  end;
  Ogs.SetItemValue('attribs', Arr);
 end;
end;

procedure TgmfPoint.Draw(Drawer: TogsDrawer);
var Matrix: TogsMatrix;
begin
// Drawer.DrawSect(ogsRect.Sect);
 If not Visible(ogsSelector.ActiveRect) then exit;
 If Sign <> nil then begin
   If fAttribs <> nil then fAttribs.KeepObject;
   Drawer.DrawMarker(X, Y);
   Matrix := SelectMatrix(TogsMatrix.Create(X, Y, Angle, Scale));
   gmfBlock.Selected := Selected;
  try
   gmfBlock.Calculate([calcbBox]);
   gmfBlock.Draw(Drawer);
  // Drawer.penColor := clRed;
   ogsRect.Draw(Drawer);
  finally
   If fAttribs <> nil then fAttribs.ReleaseObject;
   DeleteMatrix(SelectMatrix(Matrix));
   gmfBlock.Selected := False;
  end;
 end else inherited Draw(Drawer);
end;

function TgmfPoint.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var Matrix: TogsMatrix;
begin
 Result := False;
 If Sign <> nil then begin
  if not ogsRect.PointIn(X_,Y_) then exit;
  If fAttribs <> nil then fAttribs.KeepObject;
   Matrix := SelectMatrix(TogsMatrix.Create(X, Y, Angle, Scale));
  try
   gmfBlock.Calculate([calcbBox]);
   Result:= gmfBlock.SelectByPoint(X_, Y_, Params);
  finally
   If fAttribs <> nil then fAttribs.ReleaseObject;
   DeleteMatrix(SelectMatrix(Matrix));
  end;
 end else begin
  Result:=inherited SelectByPoint(X_, Y_, Params);
 end;
end;

procedure TgmfPoint.SetSelected(AValue: boolean);
begin
 inherited SetSelected(AValue);
end;

function TgmfPoint.Calculate(Action: TCalcActionSet): Integer;
var Matrix: TogsMatrix;
begin
 Result := 0;
 If Scale = 0 then Scale := 0;
 If Sign <> nil then begin
  If fAttribs <> nil then fAttribs.KeepObject;
//   WriteIn(['Calc=',X, ' ',Y, ClassName]);
   Matrix := SelectMatrix(TogsMatrix.Create(X, Y, Angle, Scale));
  try
   Result:= gmfblock.Calculate(Action);
   ogsRect.Sect := gmfBlock.Geometry.ogsRect.Sect;
 //  With ogsRect do WriteIn(['Block.Calculate', XMin, YMin, XMax, YMax]);
 //  WriteIn(['Block.XY', X, Y]);
  finally
   If fAttribs <> nil then fAttribs.ReleaseObject;
   DeleteMatrix(SelectMatrix(Matrix));
   gmfBlock.Selected := False;
  end;
 end else Result := inherited Calculate(Action);
end;

{ TgmfLineString }

function TgmfLineString.GetSign: Pointer; begin Result := fSign; end;

procedure TgmfLineString.SetSign(AValue: Pointer); begin fSign := AValue; end;

procedure TgmfLineString.SetColorBy(AValue: TColorBy); begin fColorBy := AValue; end;

function TgmfLineString.GetColorBy: TColorBy; begin Result := fColorBy; end;

function TgmfLineString.GetColor: TColor; begin Result := fColor; end;

procedure TgmfLineString.SetColor(AValue: TColor); begin fColor := AValue; end;

constructor TgmfLineString.CreateAs(ogsObject: TogsBasic);
var Obj: TgmfLineString;
begin
 if not (ogsObject is TgmfLineString) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TgmfLineString(ogsObject);
 lType := Obj.lType;
 Width := Obj.Width;
 Scale := Obj.Scale;
 LineTypeName := Obj.LineTypeName;
 Color := Obj.Color;
end;

constructor TgmfLineString.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 LineTypeName := Stream.ReadUTF8;
// восттановление типа линии из таблицы типов линий
//
 Stream.Read(fScale, SizeOf(fScale));
 Stream.Read(fWidth, SizeOf(fWidth));
end;

procedure TgmfLineString.Store(Stream: TogsStream);
var lName: String;
begin
 inherited Store(Stream);
 If lType = nil then
  lName := LineTypeName
 else
  lName := fSign.Name;
 Stream.WriteUTF8(lName);
 Stream.Write(fScale, SizeOf(fScale));
 Stream.Write(fWidth, SizeOf(fWidth));
end;

function TgmfLineString.FeatureProperties: TJSONObject;
var Ogs: TJSONObject;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 Ogs.SetString('color', ColorToHex(Color));
 if lType <> nil then Ogs.SetString('linetype', lType.Name) else
 if LineTypeName <> '' then Ogs.SetString('linetype', LineTypeName);
 Ogs.SetFloat('width', Width);
 Ogs.SetFloat('scale', Scale);
end;

procedure TgmfLineString.Draw(Drawer: TogsDrawer);
var Pen: TogsPen;
begin
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(TColorRec.Lime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 try
  If lType <> nil then begin
   lType.Draw(Drawer, Self, Scale, Selected)
  end else
   inherited Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
 end;
end;

function TgmfLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
begin
 If lType <> nil then
  Result := lType.SelectByPoint(Self, X_, Y_, Scale, Params) else
  Result:=inherited SelectByPoint(X_, Y_, Params);
end;

{ TgmfMultiLineString }

function TgmfMultiLineString.GetSign: Pointer; begin Result := fSign; end;

procedure TgmfMultiLineString.SetSign(AValue: Pointer);
var I: Integer;
begin
 fSign := AValue;
 For I := 0 to Count - 1 do Line[I].Sign := AValue;
end;

procedure TgmfMultiLineString.SetLineType(AValue: TgmfLineType); begin SetSign(AValue); end;

procedure TgmfMultiLineString.SetColorBy(AValue: TColorBy);
begin
 fColorBy := AValue;
end;

function TgmfMultiLineString.GetColorBy: TColorBy;
begin
 Result := fColorBy;
end;

function TgmfMultiLineString.GetColor: TColor;
begin
 Result := fColor;
end;

procedure TgmfMultiLineString.SetColor(AValue: TColor);
begin
 fColor := AValue;
end;

constructor TgmfMultiLineString.CreateAs(ogsObject: TogsBasic);
var Obj: TgmfMultiLineString;
begin
 if not (ogsObject is TgmfMultiLineString) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TgmfMultiLineString(ogsObject);
 LineType := Obj.LineType;
 Width := Obj.Width;
 Scale := Obj.Scale;
 LineTypeName := Obj.LineTypeName;
 Color := Obj.Color;
end;

constructor TgmfMultiLineString.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 LineTypeName := Stream.ReadUTF8;
 Stream.Read(fScale, SizeOf(fScale));
 Stream.Read(fWidth, SizeOf(fWidth));
end;

procedure TgmfMultiLineString.Store(Stream: TogsStream);
var lName: String;
begin
 inherited Store(Stream);
 If LineType = nil then
  lName := LineTypeName
 else
  lName := LineType.Name;
 Stream.WriteUTF8(lName);
 Stream.Write(fScale, SizeOf(fScale));
 Stream.Write(fWidth, SizeOf(fWidth));
end;

function TgmfMultiLineString.FeatureProperties: TJSONObject;
var Ogs: TJSONObject;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 Ogs.SetString('color', ColorToHex(Color));
 if LineType <> nil then Ogs.SetString('linetype', LineType.Name) else
 if LineTypeName <> '' then Ogs.SetString('linetype', LineTypeName);
 Ogs.SetFloat('width', Width);
 Ogs.SetFloat('scale', Scale);
end;

procedure TgmfMultiLineString.Draw(Drawer: TogsDrawer);
var Pen: TogsPen;
    I: Integer;
begin
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(TColorRec.Lime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 try
  If LineType <> nil then
   For I := 0 to Count - 1 do
    LineType.Draw(Drawer, Line[I], Scale, Selected)
  else
   inherited Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
 end;
end;

function TgmfMultiLineString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
begin
 Result := False;
 If LineType <> nil then begin
  For I := 0 to Count - 1 do begin
   Result := LineType.SelectByPoint(Line[I], X_, Y_, Scale, Params);
   If Result then exit;
  end;
 end else
  Result:=inherited SelectByPoint(X_, Y_, Params);
end;

{ TgmfPolygon }

function TgmfPolygon.GetSign: Pointer; begin Result := fSign; end;

procedure TgmfPolygon.SetSign(AValue: Pointer); begin fSign := AVAlue; end;

procedure TgmfPolygon.SetColorBy(AValue: TColorBy); begin fColorBy := AValue end;

function TgmfPolygon.GetColorBy: TColorBy; begin Result := fColorBy end;

function TgmfPolygon.GetColor: TColor; begin Result := fColor; end;

procedure TgmfPolygon.SetColor(AValue: TColor); begin fColor := AVAlue; end;

constructor TgmfPolygon.CreateAs(ogsObject: TogsBasic);
var Obj: TgmfPolygon;
begin
 if not (ogsObject is Tgmfpolygon) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TgmfPolygon(ogsObject);
 Color := Obj.Color;
 fSign := Obj.Sign;
//
 LineColor := Obj.LineColor;
end;

constructor TgmfPolygon.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 Color := Stream.ReadInt;
end;

procedure TgmfPolygon.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
 Stream.Writeint(Color);
end;

function TgmfPolygon.FeatureProperties: TJSONObject;
var Ogs: TJSONObject;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 Ogs.SetString('fill', ColorToHex(Color));
 Ogs.SetString('stroke', ColorToHex(LineColor));
end;

procedure TgmfPolygon.Draw(Drawer: TogsDrawer);
var Pen: TogsPen; Brush: TogsBrush;
begin
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(TColorRec.Lime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(LineColor, 0, nil));
  Brush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
//  WriteIn(['Color=', Color]);
 try
  inherited Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
 end;
end;

{ TgmfMultiPolygon }

function TgmfMultiPolygon.GetSign: Pointer; begin Result := fSign; end;

procedure TgmfMultiPolygon.SetSign(AValue: Pointer); begin fSign := AVAlue; end;

procedure TgmfMultiPolygon.SetColorBy(AValue: TColorBy); begin fColorBy := AValue; end;

function TgmfMultiPolygon.GetColorBy: TColorBy; begin Result := fColorBy; end;

function TgmfMultiPolygon.GetColor: TColor; begin Result := fColor; end;

procedure TgmfMultiPolygon.SetColor(AValue: TColor); begin fColor := AValue; end;

constructor TgmfMultiPolygon.CreateAs(ogsObject: TogsBasic);
var Obj: TgmfMultiPolygon;
begin
 if not (ogsObject is TgmfMultiPolygon) then raise Exception.Create(ClassName +'.CreateAs raised type conversion exception');
 inherited CreateAs(ogsObject);
 Obj := TgmfMultiPolygon(ogsObject);
 Color := Obj.Color;
 fSign := Obj.Sign;
//
 LineColor := Obj.LineColor;
end;

constructor TgmfMultiPolygon.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 Color := Stream.ReadInt;
end;

procedure TgmfMultiPolygon.Store(Stream: TogsStream);
begin
 inherited Store(Stream);
 Stream.WriteInt(Color);
end;

function TgmfMultiPolygon.FeatureProperties: TJSONObject;
var Ogs: TJSONObject;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 Ogs.SetString('fill', ColorToHex(Color));
 Ogs.SetString('stroke', ColorToHex(LineColor));
end;

procedure TgmfMultiPolygon.Draw(Drawer: TogsDrawer);
var Pen: TogsPen; Brush: TogsBrush;
begin
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(TColorRec.Lime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(LineColor, 0, nil));
  Brush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
 try
  inherited Draw(Drawer);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
 end;
end;

initialization
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfLineType, 502, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfPoint, 503, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfLineString, 504, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfMultiLineString, 505, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfPolygon, 506, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfMultiPolygon, 507, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TgmfBlock, 508, 1));
end.
