Unit lib;
interface Uses Collect, Twgdraw, newConsts, Maths_Basic,
               Classes,Circle_di, Polygons, FMX.Graphics, FMX.Types, newSelector, DWGText,
               System.Types, ogcBasic, TwgBitmaps;
{==============================================================================}

const VerConstOfZnk=1;
      VersionOfZnk:Integer=0;
      koefLine=0.1;

type
// геоточка
 PGeoPoint = ^TGeoPoint;
 { TGeoPoint - лднонаправленный список точек}
 TGeoPoint = record
  X, Y, Z: Double;
  Count: Integer;
  Next: PGeoPoint;
  procedure Create(X_, Y_, Z_: Double);
  procedure AddPoint(X_, Y_, Z_: Double);
  procedure FreeAll;
  procedure Write(S : String);
 end;

type
  Methods=(m_arc,m_line,m_Poly,m_text,m_Pie);

TLineEvent = procedure (Obj: Integer; X1, Y1, X2, Y2: Double); stdcall;
TArcEvent  = procedure (Obj: Integer; X1, Y1, X2, Y2, X3, Y3, X4, Y4: Double); stdcall;
TPolyEvent = procedure (Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
TTextEvent = procedure (Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                         txtColor: Integer; Align: byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;

{ TGeometryEvents }

TGeometryEvents = class
private
  fOnArc: TArcEvent;
  fOnLine: TLineEvent;
  fOnPie: TArcEvent;
  fOnPoly: TPolyEvent;
  fOnText: TTextEvent;
public
 Obj: Integer;
  constructor Create(Obj_: THandle; OnPoly_: TPolyEvent; OnText_: TTextEvent);
  property OnLine: TLineEvent read fOnLine write fOnLine;
  property OnArc : TArcEvent read fOnArc write fOnArc;
  property OnPie : TArcEvent read fOnPie write fOnPie;
  property OnPoly: TPolyEvent read fOnPoly write fOnPoly;
  property OnText: TTextEvent read fOnText write fOnText;
end;

{---------------------------------------------------------}
TMeth=Class(TTD)
   MT:Methods;
   PT:pointer;
   constructor Create(M:Methods;P:Pointer);
   constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
end;

{---------------------------------------------------------}

 { TDWG_Line }

 TDWG_Line=Class(TTD)
   x_b,y_b,x_e,y_e:single;
   usecolor: boolean;
   Color:Integer;
   lineW:single;
   Constructor Create(x1,y1,x2,y2:single{;c:SmallInt});
   Constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
 //
   Procedure DrawTo(Geometry: TGeometryEvents);
 //
   Procedure Draw32(X,Y:Double;Selector: TSelector;MXX,MYY,ko,Ugol:Double;bkColor:Boolean);
 end;
{---------------------------------------------------------}

{ TDWG_Arc }

TDWG_Arc=Class(TTD)
   x_1,y_1,x_2,y_2:single;
   xu_1,yu_1,xu_2,yu_2:single;
   usefill: boolean;
   color, fillcolor: integer;
   linew: single;
   Constructor Create(x1,y1,x2,y2,xu1,yu1,xu2,yu2:single{;c:SmallInt});
   Constructor Load(ST:TBufStream);Override;
   Procedure Store(ST:TBufStream);Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
 //
   Procedure DrawTo(Geometry: TGeometryEvents);
 //
   Procedure Draw32(X,Y:Double;Selector: TSelector; MXX,MYY,ko,Ugol:Double;R,G,B:Byte;bkColor:Boolean);
 end;

{ TDWG_Pie }

TDWG_Pie=Class(TDWG_Arc)
  Procedure DrawTo(Geometry: TGeometryEvents);
  Procedure Draw32(X,Y:Double;Selector: TSelector; MXX,MYY,ko,Ugol:Double;R,G,B:Byte;bkColor:Boolean);
end;

{---------------------------------------------------------}
TPn=class(TTwgObject)
   X,Y:Single;
   Constructor Create(X1,Y1:Single);
   Constructor Load(ST:TBufStream);override;
   Procedure Store(ST:TBufStream);override;
end;
{}

{ TDWG_Poly }

TDWG_Poly=Class(TTD)
   Vertex:PCollection;
   usefill: boolean;
   color, fillcolor: integer;
   linew: single;
   Constructor Create(P:PCollection);
   Constructor Load(ST:TBufStream);override;
   Procedure Store(ST:TBufStream);override;
   Destructor Destroy;Override;
   Procedure SetGabarites(MRect_:TMRect);override;
   Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
  //
   Procedure DrawTo(Geometry: TGeometryEvents);
   Procedure GetRect(var L,T,R,B:Single);
  //
   Procedure Draw32(X,Y:Double;Selector: TSelector; MXX,MYY,ko,Ugol:Double;R,G,B:Byte;bkColor:Boolean);
end;
{---------------------------------------------------------}

{ TPoint_Sign }

TPoint_Sign=Class(TTD)
  X,Y:Double;Ugol:single;
  MethodCol:PCollection;
  MyNameIs:array[0..100] of AnsiChar;
  BkColor:Boolean;
  MyInd:SmallInt;
  Drawing:Boolean;
  Sect:TSect;
  useMas:boolean;
  useFont:boolean;
  useInLot:boolean;
  XMax,XMin,YMax,YMin:Double;
  useLine:Boolean;
  Index:Integer;
  MRect:TMRect;
 //
  Selector: TSelector;
  LocalScale: Double;
  SignBitmap: TTwgBitmap;
  constructor Create(a,b:single;Name:String = '';Ind:SmallInt = -1);
  constructor Load(ST:TBufStream);Override;
  Procedure Store(ST:TBufStream);Override;
  Destructor Destroy;Override;
 //
  Procedure SetGabarites(MRect_:TMRect);override;
  Procedure SetGabaritesBlock(MRect_:TMRect; X_,Y_, kX, kY, Angle:Double);override;
  Function GetGabarites(MRect_:TMRect; X_,Y_, kX, kY, Angle:Double; TextBitmaps, Bitmaps:TTwgBitmaps):Integer;
 //
  Procedure DrawTo(Geometry: TGeometryEvents);
  Procedure DrawTextTo(txt: TDWG_Text; Geometry: TGeometryEvents);
  Function GetRect(Ko:Double):newSelector.TSect;
  Function GetRect1: TSect;
  Function GeometrySect: TSect;
 //
  Procedure GetRealSector(PP:PCollection;KO:Double);
  Function isVisible(Ko:Double):boolean;
  Procedure Draw32(Drawer:TogsDrawer;MXx,MYy:Double;R,G,B:byte;Flag:SmallInt;Reg:TRect;KO:Double;ShowAttr,ShowAttr2:boolean;ShowDot:boolean = False);
end;
{---------------------------------------------------------}

PLIB=Class(TSortedCollection)
  function Compare(Key1,Key2:Pointer):Integer;Override;
  procedure CreateBitmaps;
end;

function SearchThis(PC:TSortedCollection;Num:Integer):SmallInt;
{==============================================================================}
var Ar:Array[0..10000] of TPoint;
    PAr:Array[1..100] of TPoint;
    GLayer,GColor:String;
    DeviceHor,DeviceVert:Double;
var
 GlobalPoint: TPoint_Sign;
 GSignBmp: TBitmap;
 GSignBmpCanvas: TCanvas;
 GSignSect: TSect;
 GSignScale, GSignDX, GSignDY: Single;

 implementation Uses Types_Dimano, SysUtils, LConvEncoding, Writer, newProcs,
                    ogcMathUtils, Math.Vectors, System.UITypes, ogcDrawerSkia;

{ TGeoPoint }

procedure TGeoPoint.Create(X_, Y_, Z_: Double);
begin
 X := X_; Y := Y_; Z := Z_;
 Count := 0;
 Next := nil;
end;

procedure TGeoPoint.AddPoint(X_, Y_, Z_: Double);
begin
 New(Next);
 Next.Create(X_, Y_, Z_);
 Next.Count := Count + 1;
// Writeln('dllNext=', Next.X, Next.Y,' ', Next.Count);
end;

procedure TGeoPoint.FreeAll;
var P: PGeoPoint;
begin
// WriteIn(['dll.Free', Count]);
 If Next = nil then exit;
 Next.FreeAll;
 Dispose(Next);
end;

procedure TGeoPoint.Write(S: String);
begin
 WriteIn(['dllS=',S]);
end;



{ TGeometryEvents }

constructor TGeometryEvents.Create(Obj_: THandle; OnPoly_: TPolyEvent;
                                    OnText_: TTextEvent);
begin
 Obj := Obj_;
 OnPoly := OnPoly_;
// OnLine := OnLine_;
// OnArc  := OnArc_;
// OnPie  := OnPie_;
 OnText := OnText_;
end;

{----------------------------------------------------------------------}
function PLIB.Compare;
begin
 if TPoint_Sign(Key1).MyInd = TPoint_Sign(Key2).MyInd then Compare:=0 else
 if TPoint_Sign(Key1).MyInd < TPoint_Sign(Key2).MyInd then Compare:=-1 else
 Result:=1;
end;

{==============================================================================}
constructor TDWG_Line.Create(x1, y1, x2, y2: single);
begin
	x_b:=x1;
	y_b:=y1;
	x_e:=x2;
	y_e:=y2;
	{col:=c;}
end;
{---------------------------------------------------------}
procedure TDWG_Line.Store(ST: TBufStream);
var xx:boolean;
begin
	ST.write(x_b,SizeOf(x_b));
	ST.write(y_b,SizeOf(y_b));
	ST.write(x_e,SizeOf(x_e));
	ST.write(y_e,SizeOf(x_e));
        ST.write(color, sizeof(color));
        ST.write(linew, sizeof(linew));
        ST.write(xx, sizeof(xx));
{ST.write(col,4);}
end;

procedure TDWG_Line.SetGabarites(MRect_: TMRect);
begin
 MRect_.Insert(x_b,y_b);MRect_.Insert(x_e,y_e);
end;

procedure TDWG_Line.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
var XX,YY,XX1,YY1:Double;
begin
 XX:=X+(x_b*kX*cos(Angle)-y_b*kY*sin(Angle));
 YY:=Y+(x_B*kX*sin(Angle)+y_b*kY*cos(Angle));
 XX1:=X+(x_e*kX*cos(Angle)-y_e*kY*sin(Angle));
 YY1:=Y+(y_e*kY*cos(Angle)+x_E*kX*sin(Angle));
 MRect_.Insert(XX,YY);MRect_.Insert(XX1,YY1);
end;

procedure TDWG_Line.Draw32(X, Y: Double; Selector: TSelector; MXX, MYY, ko,
  Ugol: Double; bkColor: Boolean);
var XX,YY,XX1,YY1:Double;
    Pen: TogsPen;
begin
// Canvas.PenWidth:=round(Ko*Mxx*koefLine);
 Pen := Selector.Drawer.SelectPen(TogsPen.Create(Color, Ko*0.1, nil));
 if not BkColor then Selector.Drawer.Canvas.Stroke.Color:= Color;
 XX:=x+(x_b*ko*cos(Ugol)-y_b*ko*sin(Ugol));
 YY:=y+(x_B*ko*sin(Ugol)+y_b*ko*cos(Ugol));
 XX1:=x+(x_e*ko*cos(Ugol)-y_e*ko*sin(Ugol));
 YY1:=y+(y_e *ko*cos(Ugol)+x_E*ko*sin(Ugol));
  Selector.Drawer.DrawLine(XX,YY,XX1,YY1);
 Selector.Drawer.DeletePen(Selector.Drawer.SelectPen(Pen));
end;

procedure TDWG_Line.DrawTo(Geometry: TGeometryEvents);
var P, P1: PGeoPoint; I: Integer;
begin
 New(P);
 P.Create(x_b, y_b, 0);
 P.AddPoint(x_e, y_e, 0);
 P.Count := 2;
// WriteIn(['dllLine.Count=', P.Count]);
 P1 := P;
 For I := 0 to P.Count - 1 do begin
//  WriteIn([P1.X, P1.Y]);
  P1 := P1.Next;
 end;
  Geometry.OnPoly(Geometry.Obj, P, Color, 0, lineW, useColor, False);
 P1 := P;
 For I := 0 to P.Count - 1 do begin

   P1 := P1.Next;
 end;
 P.FreeAll;
 Dispose(P);
end;

{---------------------------------------------------------}
constructor TDWG_Line.Load(ST: TBufStream);
begin
  linew := 0.1;
	ST.read(x_b,SizeOf(X_b));
	ST.read(y_b,SizeOf(y_b));
	ST.read(x_e,SizeOf(x_e));
	ST.read(y_e,SizeOf(y_e));
        if VersionOfZnk > 1 then
        begin
          ST.read(color, sizeof(color));
          ST.read(linew, sizeof(linew));
          if linew = 0 then linew := 0.1;
          if VersionOfZnk > 2 then ST.read(usecolor, sizeof(usecolor));
        end;
{ST.read(col,4);}
end;

{==============================================================================}
constructor TDWG_Arc.Create(x1, y1, x2, y2, xu1, yu1, xu2, yu2: single);
begin
	x_1:=x1;
	y_1:=y1;
	x_2:=x2;
	y_2:=y2;
	xu_1:=xu1;
	yu_1:=yu1;
	xu_2:=xu2;
	yu_2:=yu2;
{col:=c;}
end;
{---------------------------------------------------------}
procedure TDWG_Arc.Store(ST: TBufStream);
begin
  ST.write(x_1,SizeOf(x_1));
  ST.write(y_1,SizeOf(y_1));
  ST.write(x_2,SizeOf(x_2));
  ST.write(y_2,SizeOf(y_2));
  ST.write(xu_1,SizeOf(xu_1));
  ST.write(yu_1,SizeOf(yu_1));
  ST.write(xu_2,SizeOf(xu_2));
  ST.write(yu_2,SizeOf(yu_2));
  ST.Write(color, sizeof(color));
  ST.write(usefill, sizeof(usefill));
  ST.Write(fillcolor, sizeof(fillcolor));
  ST.write(linew, sizeof(linew));
  ST.write(usefill, sizeof(usefill));
{ST.write(col,4);}
end;

procedure TDWG_Arc.SetGabarites(MRect_: TMRect);
begin
 MRect_.Insert(x_1,y_1);MRect_.Insert(x_2,y_2);MRect_.Insert(xu_1,yu_1);MRect_.Insert(xu_2,yu_2);
end;

procedure TDWG_Arc.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY, Angle: Double);
const N:Integer = 5;
var I:Integer;Col:PCollection;
begin
 Col:=Arc_Rotate2(X,Y,Angle,x+x_1*kX,y+y_1*kY,x+x_2*kX,y+y_2*kY,
                                         x+xu_1*kX,y+yu_1*kY,x+xu_2*kX,y+yu_2*kY,N);
 If Col = nil then exit;
 For I:=0 to Col.Count-1 do MRect_.Insert(TDot1(Col[I]).X,TDot1(Col[I]).Y);
 Col.Free;
end;

type
 TDot = class fX, fY: Double;
 end;

procedure TDWG_Arc.Draw32(X, Y: Double; Selector: TSelector; MXX, MYY, ko,
  Ugol: Double; R, G, B: Byte; bkColor: Boolean);
var Col: TogsCollection; I, N: Integer;
    C, S: Double;
    XP, YP: Double;
    Brush: TogsBrush;
    Pen: TogsPen;
    D: TlDot;
begin
 N := 25;
 Col := Arc_Rotate3(0, 0, 0, x_1*ko, y_1* ko, x_2*ko, y_2*ko,  xu_2*ko, yu_2*ko, xu_1*ko, yu_1*ko, N);
 If N > 1 then begin
  C := Cos(Ugol);
  S := Sin(Ugol);
  For I:= 0 to Col.Count - 1 do begin
   D:= Col[I];
   XP := D.XDot;
   YP := D.YDot;
   D.XDot := XP * C - YP * S + X;
   D.YDot := XP * S + YP * C + Y;
  end;
  With Selector do begin
   if Sqrt(Sqr(xu_1 - xu_2) + Sqr(yu_1 - yu_2)) <= 0.1 then begin
    if BkColor then begin
     if UseFill then
      Brush := Drawer.SelectBrush(TogsBrush.Create(RgbToCol(R,G,B), nil))
     else
      Brush := Drawer.SelectBrush(TogsBrush.Create(GlobalSettings.Settings.gsWindowColor, nil));
    //
     Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end else begin
     Brush := Drawer.SelectBrush(TogsBrush.Create(FillColor, nil));
      Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end;
   end;
   //
    Pen := Drawer.SelectPen(TogsPen.Create(Color, Ko * 0.1, nil));
     Selector.Drawer.DrawPolyline(Col, True);
    Drawer.DeletePen(Drawer.SelectPen(Pen));
  end;
 end;
//
 If Col <> nil then Col.Free;
end;


procedure TDWG_Arc.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection;
    N: Integer;
    xnc, ync: Single;
    P, rootP: PGeoPoint;
begin
 N := 25;
 Col := Arc_Rotate2(0, 0, 0, x_1, y_1, x_2, y_2,  xu_2, yu_2, xu_1, yu_1, N);
 If N > 1 then begin
  New(P); rootP := P;
  For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
   If N = 0 then P.Create(fX, fY, 0) else begin
                 P.AddPoint(fX, fY, 0);
                 P := P.Next;
                end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill,
                           Sqrt(Sqr(xu_1 - xu_2) + Sqr(yu_1 - yu_2)) <= 0.1);
  rootP.FreeAll;
  Dispose(rootP);
 end;
 If Col <> nil then Col.Free;
end;

{---------------------------------------------------------}
constructor TDWG_Arc.Load(ST: TBufStream);
var XX:boolean;
begin
  ST.read(x_1,SizeOf(x_1));
  ST.read(y_1,SizeOf(y_1));
  ST.read(x_2,SizeOf(x_2));
  ST.read(y_2,SizeOf(y_2));
  ST.read(xu_1,SizeOf(xu_1));
  ST.read(yu_1,SizeOf(yu_1));
  ST.read(xu_2,SizeOf(xu_2));
  ST.read(yu_2,SizeOf(yu_2));
  if VersionOfZnk > 1 then begin
   ST.read(color, sizeof(color));
   ST.read(XX, sizeof(XX));
   ST.read(fillcolor, sizeof(fillcolor));
   ST.read(linew, sizeof(linew));
   if VersionOfZnk > 2 then ST.read(useFILL, sizeof(useFILL));
  end;
{ST.read(col,4);}
end;

{==============================================================================}
{ TDWG_Pie }

procedure TDWG_Pie.Draw32(X, Y: Double; Selector: TSelector; MXX, MYY, ko,
  Ugol: Double; R, G, B: Byte; bkColor: Boolean);
var Col: TogsCollection; I, N:Integer;
    ox, oy: Double;
    C, S: Double;
    XP, YP: Double;
    Brush: TogsBrush;
    Pen: TogsPen;
    D: TlDot;
begin
// WriteIn(['dllPie']);
 N:= 25;
 Col:=Arc_Rotate3(0,0,0,x_1, y_1, x_2, y_2, xu_1, yu_1, xu_2, yu_2, N);
 If N > 1 then begin
  ox := x_1 + (x_2 - x_1) / 2;
  oy := y_1 + (y_2 - y_1) / 2;
  Col.Add(TDot1.Create(ox, oy));
  Col.Insert(0, TDot1.Create(ox, oy));
 //
  C := Cos(Ugol);
  S := Sin(Ugol);
  For I:= 0 to Col.Count - 1 do begin
   D:= Col[I];
   XP := D.XDot;
   YP := D.YDot;
   D.XDot := XP * C - YP * S + X;
   D.YDot := XP * S + YP * C + Y;
  end;
  With Selector do begin
   if Sqrt(Sqr(xu_1 - xu_2) + Sqr(yu_1 - yu_2)) <= 0.1 then begin
    if BkColor then begin
     if UseFill then
      Brush := Drawer.SelectBrush(TogsBrush.Create(RgbToCol(R,G,B), nil))
     else
      Brush := Drawer.SelectBrush(TogsBrush.Create(GlobalSettings.Settings.gsWindowColor, nil));
    //
     Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end else begin
     Brush := Drawer.SelectBrush(TogsBrush.Create(FillColor, nil));
      Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end;
   end;
   //
    Pen := Drawer.SelectPen(TogsPen.Create(Color, round(Ko*0.1), nil));
    Selector.Drawer.DrawPolyline(Col, True);
    Drawer.DeletePen(Drawer.SelectPen(Pen));
  end;
 end;
 //
 If Col <> nil then Col.Free;
end;

procedure TDWG_Pie.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection; N:Integer;
    ox, oy: Double; P, rootP: PGeoPoint;
begin
// WriteIn(['dllPie']);
 N:= 25;
 Col:=Arc_Rotate2(0,0,0,x_1, y_1, x_2, y_2, xu_1, yu_1, xu_2, yu_2, N);
 If N > 1 then begin
  ox := x_1 + (x_2 - x_1) / 2;
  oy := y_1 + (y_2 - y_1) / 2;
  Col.Insert(TDot1.Create(ox, oy));
  Col.AtInsert(0, TDot1.Create(ox, oy));
  New(P); rootP := P;
  For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
   If N = 0 then P.Create(fX, fY, 0) else begin
                 P.AddPoint(fX, fY, 0);
                 P := P.Next;
                end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill, True);
  rootP.FreeAll;
  Dispose(rootP);
 end;
 Col.Free;
end;

{==============================================================================}
constructor TPn.Create;
begin
 X:=X1;Y:=Y1;
end;
{---------------------------------------------------------}
procedure TPn.store;
begin
 ST.Write(X,SizeOf(X));
 ST.Write(Y,SizeOf(Y));
end;
{---------------------------------------------------------}
constructor TPn.load;
begin
 ST.Read(X,SizeOf(X));
 ST.Read(Y,SizeOf(Y));
end;
{}
constructor TDWG_Poly.Create(P: PCollection);
begin
 Vertex:=P;
end;
{---------------------------------------------------------}
procedure TDWG_Poly.Store(ST: TBufStream);
begin
 ST.Put(Vertex);
   ST.write(color, sizeof(color));
   ST.write(usefill, sizeof(usefill));
   ST.write(fillcolor, sizeof(fillcolor));
   ST.write(linew, sizeof(linew));
   ST.write(usefill, sizeof(usefill));
end;
{---------------------------------------------------------}
constructor TDWG_Poly.Load(ST: TBufStream);
var XX:boolean;
begin
 Vertex:=PCollection(St.Get);
  if VersionOfZnk > 1 then
  begin
    ST.read(color, sizeof(color));
    ST.read(XX, sizeof(XX));
    ST.read(fillcolor, sizeof(fillcolor));
    ST.read(linew, sizeof(linew));
    if VersionOfZnk > 2 then ST.read(USEFILL, sizeof(USEFILL));
  end;
end;
{---------------------------------------------------------}

destructor TDWG_Poly.Destroy;
 begin
  Vertex.Free;
 end;

procedure TDWG_Poly.SetGabarites(MRect_: TMRect);
var I:Integer;XX,YY:Double;
begin
 For I:=0 to Vertex.Count-1 do
  begin
   XX:=TPn(Vertex.At(I)).X;YY:=TPn(Vertex.At(I)).Y;
   MRect_.Insert(XX,YY);
  end;
end;

procedure TDWG_Poly.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
var I:Integer;X0,Y0,XX,YY:Double;
begin
 For I:=0 to Vertex.Count-1 do
  begin
   X0:=TPn(Vertex.At(I)).X;Y0:=TPn(Vertex.At(I)).Y;
   XX:=x+(X0*kX*cos(Angle)-Y0*kX*sin(Angle));
   YY:=y+(X0*kY*sin(Angle)+Y0*kY*cos(Angle));
   MRect_.Insert(XX,YY);
  end;
end;

procedure TDWG_Poly.Draw32(X, Y: Double; Selector: TSelector; MXX, MYY, ko,
  Ugol: Double; R, G, B: Byte; bkColor: Boolean);
var Col: TogsCollection;
    I, N: Integer;
    C, S, XP, YP: Double;
    D: TlDot;
    Pen: TogsPen;
    Brush: TogsBrush;
  	XX,YY, XXE, YYE:Double;
begin
// WriteIn(['dllPoly']);
 Col := TogsCollection.Create(1);
 For I := 0 to Vertex.Count - 1 do Col.Add(TlDot.Create(TPn(Vertex[I]).X *ko, TPn(Vertex[I]).Y*ko));
  C := Cos(Ugol);
  S := Sin(Ugol);
  For I:= 0 to Col.Count - 1 do begin
   D:= Col[I];
   XP := D.XDot;
   YP := D.YDot;
   D.XDot := XP * C - YP * S + X;
   D.YDot := XP * S + YP * C + Y;
  end;
  XX:=TPn(Vertex.At(0)).X;YY:=TPn(Vertex.At(0)).Y;
  XXE:=TPn(Vertex.At(Vertex.Count - 1)).X;YYE:=TPn(Vertex.At(Vertex.Count - 1)).Y;
  With Selector do begin
   if Sqrt(Sqr(XX - XXE) + Sqr(YY - YYE)) <= 0.1 then begin
    if BkColor then begin
     if UseFill then
      Brush := Drawer.SelectBrush(TogsBrush.Create(RgbToCol(R,G,B), nil))
     else
      Brush := Drawer.SelectBrush(TogsBrush.Create(GlobalSettings.Settings.gsWindowColor, nil));
    //
     Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end else begin
     Brush := Drawer.SelectBrush(TogsBrush.Create(FillColor, nil));
      Selector.Drawer.DrawPolygon(Col, nil);
     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
    end;
   end;
   //
    Pen := Drawer.SelectPen(TogsPen.Create(Color, round(Ko*0.1), nil));
    Selector.Drawer.DrawPolyline(Col, True);
    Drawer.DeletePen(Drawer.SelectPen(Pen));
  end;
//
 If Col <> nil then Col.Free;
end;

procedure TDWG_Poly.DrawTo(Geometry: TGeometryEvents);
var Col: PCollection;
    I, N: Integer;
    X1, Y1, X2, Y2: Double; P, rootP: PGeoPoint;
begin
// WriteIn(['dllPoly']);
 Col := PCollection.Create(1);
 For I := 0 to Vertex.Count - 1 do Col.Insert(TDot1.Create(TPn(Vertex[I]).X, TPn(Vertex[I]).Y));
  X1 := TDot1(Col[0]).X; Y1 := TDot1(Col[0]).Y;
  X2 := TDot1(Col[Col.Count - 1]).X; Y2 := TDot1(Col[Col.Count - 1]).Y;
  New(P); rootP := P;
   For N := 0 to Col.Count - 1 do With TDot(Col.List[N]) do
    If N = 0 then P.Create(fX, fY, 0) else begin
                  P.AddPoint(fX, fY, 0);
                  P := P.Next;
                 end;
  rootP.Count := Col.Count;
  Geometry.OnPoly(Geometry.Obj, rootP, Color, fillColor, lineW, useFill,
                   Sqrt(Sqr(rootP.X - P.X)) + Sqr(rootP.Y - P.Y) <= 0.1);
  rootP.FreeAll;
  Dispose(rootP);
 //
 Col.Free;
end;

procedure TDWG_Poly.GetRect(var L, T, R, B: Single);
var
  I:Integer;
  XX,YY:Single;
begin
 L:=1000000;T:=1000000;R:=-1000000;B:=-1000000;
 For I:=0 to Vertex.Count-1 do
	begin
	 XX:=TPn(Vertex.At(I)).X;YY:=TPn(Vertex.At(I)).Y;
         If XX<L then L:=XX;
         If XX>R then R:=XX;
        {}
         If YY<T then T:=YY;
         If YY>B then B:=YY;
	end;
 end;

{============================================================}
constructor TPoint_Sign.Create(a, b: single; Name: String; Ind: SmallInt);
begin
 MRect:=TMRect.Create;
 x:=a;
 y:=b;
 MRect.Insert(x,y);
 MethodCol:=PCollection.Create(1);
 Drawing:=True;
 StrPCopy(MyNameIs,AnsiString(Name));MyInd:=Ind;
 SignBitmap := nil;
end;
{---------------------------------------------------------}
destructor TPoint_Sign.Destroy;
begin
 If MRect<>nil then MRect.Free;
 if SignBitmap<>nil then SignBitmap.Free;
 MethodCol.Destroy;
end;

procedure TPoint_Sign.SetGabaritesBlock(MRect_: TMRect; X_, Y_, kX, kY,
 Angle: Double);
var I:Integer;PP:TMeth;
begin
 // проходим по всем примитивам и вычисляем габариты
 // Mrect_ может быть nil
 For I:=0 to MethodCol.Count-1 do begin
  pp:=MethodCol[I];
//  WriteMsg(['Meth=',ord(pp.Mt)]);
  TTD(pp.pt).SetGabaritesBlock(MRect_,X_,Y_,kX,kY,Angle);
 end;
end;

function TPoint_Sign.GetGabarites(MRect_: TMRect; X_, Y_, kX, kY, Angle: Double; TextBitmaps, Bitmaps: TTwgBitmaps): Integer;
var I, TextIndex:Integer;PP:TMeth;
    mRect, mSource:TMRect;
    SourceSect:TSect;
    TextBitmap:TTwgBitmap;
begin
 Result:=0;
 if Bitmaps<>nil then Bitmaps.DeleteAll;
 mRect:=TMRect.Create;
 mSource:=TMRect.Create;
 try
  TextIndex:=0;
  For I:=0 to MethodCol.Count-1 do begin
   PP:=MethodCol[I];
   if PP.mt=m_Text then begin
    TextBitmap:=nil;
    if TDWG_Text(PP.pt).IsTextVisible then begin
     if (TextBitmaps<>nil) and (TextIndex<TextBitmaps.Count) then
      TextBitmap:=TTwgBitmap(TextBitmaps[TextIndex])
     else if Bitmaps<>nil then
      TextBitmap:=TTwgBitmap.Create(TDWG_Text(PP.pt));
     TDWG_Text(PP.pt).TextBitmap:=TextBitmap;
     TDWG_Text(PP.pt).SetGabaritesBlock(mRect, X_, Y_, kX, kY, Angle);
    end;
    if Bitmaps<>nil then begin
     if TextBitmap<>nil then Bitmaps.Insert(TextBitmap) else Bitmaps.Insert(Bitmaps);
    end;
    Inc(TextIndex);
    Continue;
   end;
   TTD(PP.pt).SetGabarites(mSource);
   TTD(PP.pt).SetGabaritesBlock(mRect, X_, Y_, kX, kY, Angle);
   if Bitmaps<>nil then Bitmaps.Insert(Bitmaps);
  end;
  if (Bitmaps<>nil) and (mSource.Iter<>0) then begin
   SourceSect:=mSource.Sect;
   Bitmaps.Bitmap.SetTransformedBounds(SourceSect, 0, 0, X_, Y_, kX, kY, Angle);
  end;
  if mRect.Iter<>0 then begin
   Result:=1;
   if MRect_<>nil then begin
    MRect_.Insert(mRect.Sect.Left, mRect.Sect.Top);
    MRect_.Insert(mRect.Sect.Right, mRect.Sect.Bottom);
   end;
  end;
 finally
  mSource.Free;
  mRect.Free;
 end;
end;

procedure TPoint_Sign.DrawTo(Geometry: TGeometryEvents);
var pp:TMeth;
    p1:TDWG_Line;
    p2:TDWG_Arc;
    p3:TDWG_Poly;
    p4:TDwg_Text;
    p5:TDwg_Pie;
    I:Integer;
    Coord: TList;
begin
 for i:=0 to Methodcol.Count-1 do begin
  pp:=MethodCol.At(i);
//  Writeln('DrawTo ', I,' ',Methodcol.Count, pp.mt);
  case pp.mt of
 	  m_Line:
 		  begin
 		   p1:=pp.pt;
                   p1.DrawTo(Geometry);
 	       	  end else
           if (pp.mt=m_Arc) then
 		   begin
 		   p2:=pp.pt;
                   p2.DrawTo(Geometry);
 		   end else
           if pp.mt=m_Poly then
                  begin
 		   p3:=pp.pt;
                   p3.DrawTo(Geometry);
 		  end else
           if pp.mt=m_Pie then begin
 		  p5:=pp.pt;
                  p5.DrawTo(Geometry);
           end else
           if pp.mt=m_Text then begin
                  p4 := pp.pt;
                  DrawTextTo(P4, Geometry);
           end;
  end;
//  Writeln('End=',I);
 end;
end;


Function TPoint_Sign.GetRect1:TSect;
 var
	pp:TMeth;
	p1:TDWG_Line;
	p2:TDWG_Arc;
	i:Integer;
  L,T,R,B,L1,T1,R1,B1:Single;
 begin
 L:=0;T:=0;R:=0;B:=0;
 useLine:=False;
 for I:=0 to Methodcol.count-1 do
	begin
	pp:=MethodCol.At(i);
	case pp.mt of
		m_Line:
			begin
			 p1:=pp.pt;
			 If P1.X_B<L then L:=P1.X_B;
			 If P1.Y_B<T then T:=P1.Y_B;
			 If P1.X_B>R then R:=P1.X_B;
			 If P1.Y_B>B then B:=P1.Y_B;
                        {}
			 If P1.X_E<L then L:=P1.X_E;
			 If P1.Y_E<T then T:=P1.Y_E;
			 If P1.X_E>R then R:=P1.X_E;
			 If P1.Y_E>B then B:=P1.Y_E;
       useLine:=True;
                        //PMoveTo(L,T);PLineTo(R,T);PLineTo(R,B);PLineTo(L,B);PLineTo(L,T);
			end;
		m_arc,m_Pie:begin
			 p2:=pp.pt;
			 If P2.X_1<L then L:=P2.X_1;
			 If P2.Y_1<T then T:=P2.Y_1;
			 If P2.X_1>R then R:=P2.X_1;
			 If P2.Y_1>B then B:=P2.Y_1;
                        {}
			 If P2.X_2<L then L:=P2.X_2;
			 If P2.Y_2<T then T:=P2.Y_2;
			 If P2.X_2>R then R:=P2.X_2;
			 If P2.Y_2>B then B:=P2.Y_2;
                        {}
			 If P2.Xu_1<L then L:=P2.Xu_1;
			 If P2.Yu_1<T then T:=P2.Yu_1;
			 If P2.Xu_1>R then R:=P2.Xu_1;
			 If P2.Yu_1>B then B:=P2.Yu_1;
                        {}
			 If P2.Xu_2<L then L:=P2.Xu_2;
			 If P2.Yu_2<T then T:=P2.Yu_2;
			 If P2.Xu_2>R then R:=P2.Xu_2;
			 If P2.Yu_2>B then B:=P2.Yu_2;
                        //PMoveTo(L,T);PLineTo(R,T);PLineTo(R,B);PLineTo(L,B);PLineTo(L,T);
       useLine:=True;
			end;
               m_Poly:
                       begin
                        TDWG_Poly(pp.pt).GetRect(L1,T1,R1,B1);
                       //PMoveTo(L1,T1);PLineTo(R1,T1);PLineTo(R1,B1);PLineTo(L1,B1);PLineTo(L1,T1);
                        If L1<L then L:=L1;
                        If R1>R then R:=R1;
                        If T1<T then T:=T1;
                        If B1>B then B:=B1;
                        useLine:=True;
                       end;
              m_Text:begin
                       continue;
  //                    UseFont:=True;
                      TDWG_Text(pp.pt).Ugol1:=Ugol;
                      TDWG_Text(pp.pt).GetRect(L1,T1,R1,B1);
                       //PMoveTo(L1,T1);PLineTo(R1,T1);PLineTo(R1,B1);PLineTo(L1,B1);PLineTo(L1,T1);
                       If L1<L then L:=L1;
                       If R1>R then R:=R1;
                       If T1<T then T:=T1;
                       If B1>B then B:=B1;
                     end;
        end;
    end;
  With Result do
   begin
    Left:=L;
    Top:=T;
    Right:=R;
    Bottom:=B;
    if Right-Left<=0.1 then begin
     Left:=Left-0.1;Right:=Right+0.1;
    end;
    if Bottom-Top<=0.1 then begin
     Bottom:=Bottom+0.1;Top:=Top-0.1;
    end;
   end;
 end;

function TPoint_Sign.GeometrySect: TSect;
var I: Integer;
    pp: TMeth;
    mRect: TogsRect;
    L,T,R,B,L1,T1,R1,B1:Single;
begin
 mRect := TogsRect.Create;
 for I:=0 to Methodcol.count-1 do begin
 	pp:=MethodCol.At(i);
	case pp.mt of
	 m_Line: with TDWG_Line(pp.pt) do begin
	          mRect.Insert(X_B, Y_B);
	          mRect.Insert(X_E, Y_E);
	          useLine:=True;
	         end;
	 m_arc,
	 m_Pie:  with TDWG_Arc(pp.pt) do begin
	          mRect.Insert(X_1, Y_1);
	          mRect.Insert(X_2, Y_2);
	          mRect.Insert(Xu_1, Yu_1);
	          mRect.Insert(Xu_2, Yu_2);
	          useLine:=True;
	         end;
	 m_Poly: with TDWG_Poly(pp.pt) do begin
	          GetRect(L1,T1,R1,B1);
	          mRect.Insert(L1, T1);
	          mRect.Insert(R1, B1);
	          useLine:=True;
	         end;
	end;
 end;
 Result := mRect.Sect;
 mRect.Free;
end;

function TPoint_Sign.isVisible;
var PP:PCollection;
begin
 Result:=True;
 If GlobalRender then exit;
 PP:=PCollection.Create(1);
 Sect:=GetRect1;
 GetRealSector(PP,Ko);
 With Selector do
  Result:=not ((XMin>GRect.Right)or(XMax<GRect.Left)or(YMax>GRect.Top)or(YMin<GRect.Bottom));
 PP.Free;
end;

procedure TPoint_Sign.GetRealSector(PP: PCollection;KO:Double);
var xa,xb,ya,yb:Double;XX,YY:Double;
    I:Integer;
begin
 XMax:=-900000000;YMax:=-900000000;XMin:=900000000;YMin:=900000000;

  xa:=RealScaleLength(Selector.Drawer,Sect.Left,Ko);xb:=RealScaleLength(Selector.Drawer,Sect.Right,Ko);
  ya:=RealScaleLength(Selector.Drawer,Sect.Top,Ko);yb:=RealScaleLength(Selector.Drawer,Sect.Bottom,Ko);
//  Writeln('xa=',XA:8:3,' ya=', ya:8:3, ' xb=',xb:8:3,' yb=',yb:8:3);
//
     XX:=x+(xa*cos(Ugol)-ya*sin(Ugol));
     YY:=y+(xa*sin(Ugol)+ya*cos(Ugol));
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
    PP.Insert(TDot1.Create(XX,YY));
     XX:=x+(xb*cos(Ugol)-ya*sin(Ugol));
     YY:=y+(xb*sin(Ugol)+ya*cos(Ugol));
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
    PP.Insert(TDot1.Create(XX,YY));
     XX:=x+(xb*cos(Ugol)-yb*sin(Ugol));
     YY:=y+(xb*sin(Ugol)+yb*cos(Ugol));
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
    PP.Insert(TDot1.Create(XX,YY));
     XX:=x+(xa*cos(Ugol)-yb*sin(Ugol));
     YY:=y+(xa*sin(Ugol)+yb*cos(Ugol));
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
    PP.Insert(TDot1.Create(XX,YY));
     XX:=x+(xa*cos(Ugol)-ya*sin(Ugol));
     YY:=y+(xa*sin(Ugol)+ya*cos(Ugol));
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
    PP.Insert(TDot1.Create(XX,YY));
{ For I:=0 to PP.Count-1 do With TDot1(PP[I]) do begin
  If I=0 then PMoveTo(X,Y) else PLineTo(X,Y);
  XX:=X;YY:=Y;
  If XX>XMax then XMax:=XX;If XX<XMin then XMin:=XX;
  If YY>YMax then YMax:=YY;If YY<YMin then YMin:=YY;
 end;
}
end;

Function  TPoint_Sign.GetRect(Ko:Double):newSelector.TSect;
begin
 Result:=GetRect1;
 With Result do begin
  Right:=Right*Ko;Left:=Left*Ko;Top:=Top*Ko;Bottom:=Bottom*Ko;
 end;
end;

procedure TPoint_Sign.Draw32(Drawer: TogsDrawer; MXx, MYy: Double; R, G,
  B: byte; Flag: SmallInt; Reg: TRect; KO: Double; ShowAttr, ShowAttr2,
  ShowDot: boolean);
var
	pp:TMeth;
	p1:TDWG_Line;
	p2:TDWG_Arc;
	p3:TDWG_Poly;
  p4:TDwg_Text;
  p5:TDwg_Pie;
	i, J:Integer;
	OldX,OldY:Double;
  BB:Boolean;
  Ko2:Double;
  Vis:Boolean;
  X1,Y1:Integer;
  W, H: Double;
  AnchorPix: TPointF; Dst: TRectF;
  WW,HH,OffX,OffY:Single;
 procedure DrawText(DT: TDWG_Text);
 begin
  If (ShowAttr)and(ShowAttr2) then
                       begin
                        If Ko2<0 then
                         DT.Draw32(x,y,Selector,MXX,MYY,Ko2,Ugol,R,G,B, bkcolor, OldX, OldY, Flag) else
                         DT.Draw32(x,y,Selector,MXX,MYY,Ko,Ugol,R,G,B, bkcolor, OldX, OldY, Flag);
                       end;
 end;
begin
// if not Drawing then Exit;
Ko2:=Ko;
If Ko<0 then begin
 Ko:=abs(Ko);
 if Flag=its_Printer then begin
  //MXX:=1/DInform.XAspect;MYY:=1/DInform.YAspect;
  //Ko:=MMYSP(Ko);
 end else begin
  MXX:=DeviceHor;MYY:=DeviceVert;
 end;
end;
// Writeln('Znak=',WinToDos(MyNameIs));
 Vis:=True;
	OldX:=X;
	OldY:=Y;
  BB:=True;
	if Flag<>its_test then With Selector do
		begin
     Sect:=GetRect(Abs(Ko));
         BB:=isVisible(Ko);
     // WriteIn([MyNameis]);
         // BB:=True;
           if not BB {and not UseFont} then Exit;
           W := Abs(Sect.Right-Sect.Left); H := Abs(Sect.Bottom-Sect.Top);
           // LOD: draw SignBitmap for small signs instead of vector geometry
           if (SignBitmap<>nil) and (Drawer is TogsDrawerSkia) and
             TogsDrawerSkia(Drawer).DebugRoughDrawing and TogsDrawerSkia(Drawer).DebugBitmapDrawing and
             (XRasst(W) < 40) and (YRasst(H) < 40) and
             (XRasst(W) > 0) and (YRasst(H) > 0) then
           begin
            if TogsDrawerSkia(Drawer).UseWorldCoords then
            begin
             AnchorPix := PointF(Single(X), Single(Y));
             WW := XRasst(W) / GetScale;
             HH := YRasst(H) / GetScale;
            end else
            begin
             AnchorPix := PointF(XPix(X), YPix(Y));
             WW := XRasst(W);
             HH := YRasst(H);
            end;
            OffX := WW * 0.5; OffY := HH * 0.5;
            Dst := RectF(-OffX, -OffY, -OffX + WW, -OffY + HH);
            TogsDrawerSkia(Drawer).DrawBitmapAlignedPix(AnchorPix, SignBitmap.Bitmap, Dst, Ugol);
            For J := 0 to Methodcol.Count-1 do
             if TMeth(MethodCol.At(J)).mt = m_Text then
               DrawText(TMeth(MethodCol.At(J)).pt);
            exit;
           end;
           If (XRasst(W)<=10) and (YRasst(H)<=10) and (not GlobalRender) then begin
            If useLine then begin
             If BB then begin
               //If gGraphSet.FPntZnk>=2 then exit;
              // Writeln(1);
               // Drawer.Canvas.Stroke.Color:=RGBToCol(r,g,b);
               // Canvas.PenWidth:=round(Ko*Mxx*koefLine);
                X1:=XPix(x);Y1:=YPix(y);
             //  Dc:=GCanvas.Handle;
               //  Drawer.DrawLine(X1,Y1,X1+2,Y1); Drawer.DrawLine(X1,Y1+1,X1+2,Y1+1);
              // Writeln(2);
               end;
             end;
            If UseFont then
             for i:=0 to Methodcol.Count-1 do begin
              pp:=MethodCol.At(i);
              If (ShowAttr)and(ShowAttr2)and(pp.mt = m_Text) then begin
                 p4 := pp.pt;
              try
                If Ko2<0 then
                         p4.Draw32(x,y,Selector,GMS,GMS,Ko2,Ugol,R,G,B, bkcolor, OldX, OldY, Flag) else
                         p4.Draw32(x,y,Selector,MXX,MYY,Ko,Ugol,R,G,B, bkcolor, OldX, OldY, Flag);
              except
                If Ko2<0 then
                         p4.Draw32(x,y,Selector,GMS,GMS,Ko2,Ugol,R,G,B, bkcolor, OldX, OldY, Flag) else
                         p4.Draw32(x,y,Selector,MXX,MYY,Ko,Ugol,R,G,B, bkcolor, OldX, OldY, Flag);
              end;
              end;
             end;
            exit;
           end;
      X:=x;
      Y:=y;
		{KO:=KO*MX;}
		end else
    begin
     X:=Round(X);Y:=Round(Y);
    end;
If not Vis then Exit;
Drawer.Canvas.Stroke.Color:=RGBToCol(r,g,b);
//Canvas.PenWidth:=round(Ko*Mxx*koefLine);
// Mxx:=Mxx;Myy:=Myy;Ko:=Ko;
for i:=0 to Methodcol.Count-1 do With Selector do begin
 pp:=MethodCol.At(i);
	case pp.mt of
		m_Line:
			begin
			 p1:=pp.pt;
			 if BB then p1.draw32(x,y,Selector,MXX,MYY,ko,Ugol,bkColor);
      end else
      if (pp.mt=m_Arc) then
			begin
      // Writeln('begArc',I);
			p2:=pp.pt;
		    	 if BB then p2.draw32(x,y,Selector,MXX,MYY,ko,Ugol,R,G,B,bkColor);
      // Writeln('endArc',I);
			end else
                if pp.mt=m_Poly then
                       begin
      // Writeln('begPoly',I);
			p3:=pp.pt;
		 	if BB then p3.draw32(x,y,Selector,MXX,MYY,ko,Ugol,R,G,B,bkColor);
      // Writeln('endPoly',I);
		       end else
                if pp.mt=m_Pie then begin
			           p5:=pp.pt;
		 	//if BB then p5.draw32(x,y,Canvas,MXX,MYY,ko,Ugol,R,G,B,bkColor);
                end else begin
                 p4 := pp.pt;
                 DrawText(p4);
                end;
        end;
		  end;
{  If ShowDot then begin // iieacuaaai oi?eo i?eaycee
   SetPixel(DC,Round(X),Round(Y),rgb(255,0,0));
  end;
}
	X:=OldX;
	Y:=OldY;
end;

procedure TPoint_Sign.DrawTextTo(txt: TDWG_Text; Geometry: TGeometryEvents);
begin
// (X, Y: Double; FontName: String; txtHeight, txtAngle: Double;
//                        txtColor: TColor; Align: byte; Bl, It, Un: Boolean; Text: String)
 Geometry.OnText(Geometry.Obj, txt.FX, txt.FY, PChar(txt.fFntName), txt.fHeight, txt.fAng, txt.fScale/1000,
                 txt.fColor, txt.TextAlign,
                 boolean(txt.fBl), boolean(txt.fIt), boolean(txt.fUn), PChar(txt.fText), PChar(txt.fName));
end;

procedure TPoint_Sign.SetGabarites(MRect_: TMRect);
var I:Integer;
    pp:TMeth;
begin
 // проходим по всем примитивам и вычисляем габариты
 // Mrect_ может быть nil
 For I:=0 to MethodCol.Count-1 do begin
  pp:=MethodCol[I];
  TTD(pp.mt).SetGabarites(MRect);
 end;
 If MRect_<>nil then MRect_.CreateAs(MRect);
end;

{---------------------------------------------------------}
procedure TPoint_Sign.Store(ST: TBufStream);
var XX,YY:Single;
begin
 XX:=X;YY:=Y;
  ST.write(xx,SizeOf(xx));
  ST.write(yy,SizeOf(yy));
  ST.write(Ugol,SizeOf(Ugol));
  ST.write(MyNameIs,SizeOf(MyNameIs));
  ST.write(usemas, SizeOf(usemas));
  ST.Write(BkColor,1);
  ST.write(MyInd,SizeOf(MyInd));
  ST.put(MethodCol);
end;
{---------------------------------------------------------}

constructor TPoint_Sign.Load(ST: TBufStream);
var a,b:single;I:Integer;p5:TDwg_Pie;XX,YY:single;
    S:AnsiString;
begin
 Selector := ST.Selector;
 UseFont:=False;
 MRect:=TMRect.Create;
  ST.read(XX,SizeOf(XX));
  ST.read(YY,SizeOf(YY));
  X:=XX;Y:=YY;
  MRect.Insert(X,Y);
  ST.read(Ugol,SizeOf(Ugol));
  If VersionOfZnk>0 then
  ST.read(MyNameIs,SizeOf(MyNameIs)) else ST.read(MyNameIs,24);
  //    S:=CP1251ToUtf8(MyNameIs);
  StrPCopy(MyNameIs, CP1251ToUtf8(MyNameIs));
  if VersionOfZnk > 1 then
  ST.read(usemas,SizeOf(usemas));

  ST.Read(BkColor,1);
  ST.read(MyInd,SizeOf(MyInd));
  MethodCol:=PCollection(ST.Get);
  {!!!!!!!!!!}
 // Ugol:=0; это видимо для отладки что-то было
 // Drawing:=True;
  {}
  if VersionOfZnk < 3 then
  begin
  //          bkcolor := false;
  For i := 0 to MethodCol.Count - 1 do
    begin
      case TMeth(MethodCol[i]).MT of
        m_arc: TDWG_Arc(TMeth(MethodCol[i]).PT).usefill := BkColor;
  //              m_line: TDWG_Line(TMeth(MethodCol).PT).usefill := BkColor;
        m_Poly: TDWG_Poly(TMeth(MethodCol[i]).PT).usefill := BkColor;
        m_Text: UseFont:=True;
      end;
    end;
    bkcolor := true;
  end else
  For i := 0 to MethodCol.Count - 1 do
   If TMeth(MethodCol[i]).MT=m_Text then UseFont:=True else
   If TMeth(MethodCol[i]).MT=m_Pie then begin
    p5:=TMeth(MethodCol[i]).pt;
   end;
end;

{==============================================================================}
Constructor TMeth.Create;
begin
	MT:=M;
	PT:=P;
end;
{---------------------------------------------------------}
Procedure TMeth.store;
begin
	St.write(MT,SizeOf(MT));
  St.Put(PT);
end;
{---------------------------------------------------------}
constructor TMeth.load;
begin
	St.read(MT,SizeOf(MT));
  PT:=St.Get;
end;
{---------------------------------------------------------}

function SearchThis;
var I:Integer;
begin
Result:=-1;
if pc=nil then exit;
 GlobalPoint.MyInd:=Num;
 If Pc.Search(GlobalPoint,I) then begin
  Result:=I;
 end;
end;

{==============================================================================}

procedure SignBitmapOnPoly(Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
var I: Integer;
    P: PGeoPoint;
    Points: TPolygon;
    StrokeColor, FillColor: TAlphaColor;
begin
 if (GSignBmpCanvas = nil) or (Poly = nil) or (Poly.Count < 1) then Exit;
 SetLength(Points, Poly.Count);
 P := Poly;
 for I := 0 to Poly.Count - 1 do begin
  Points[I] := PointF(
   Single(P.X) * GSignScale + GSignDX,
   Single(P.Y) * GSignScale + GSignDY
  );
  P := P.Next;
  if P = nil then Break;
 end;
 StrokeColor := TAlphaColor($FF000000 or (Cardinal(penColor) and $00FFFFFF));
 FillColor := TAlphaColor($FF000000 or (Cardinal(brushColor) and $00FFFFFF));
 GSignBmpCanvas.Stroke.Kind := TBrushKind.Solid;
 GSignBmpCanvas.Stroke.Color := StrokeColor;
 if lineWidth > 0 then
  GSignBmpCanvas.Stroke.Thickness := lineWidth * GSignScale
 else
  GSignBmpCanvas.Stroke.Thickness := 1;
 if isPolygon and useColor then begin
  GSignBmpCanvas.Fill.Kind := TBrushKind.Solid;
  GSignBmpCanvas.Fill.Color := FillColor;
  GSignBmpCanvas.FillPolygon(Points,1);
 end;
 GSignBmpCanvas.DrawPolygon(Points,1);
end;

procedure SignBitmapOnText(Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                     txtColor: Integer; Align: byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;
begin
 // текст для иконок знаков не используем
end;

{==============================================================================}

procedure PLIB.CreateBitmaps;
var I: Integer;
    PS: TPoint_Sign;
    Sect: TSect;
    W0,H0,Pad,InnerW,InnerH,Scale: Single;
    Geo: TGeometryEvents;
begin
 for I := 0 to Count - 1 do begin
  PS := TPoint_Sign(At(I));
  if PS = nil then Continue;
//  WriteIn([PS.MyNameIs, PS.MethodCol = nil]);
  Sect := PS.GeometrySect; // используем локальный сектор знака только для геометрии
  W0 := Abs(Sect.Right - Sect.Left); H0 := Abs(Sect.Bottom - Sect.Top);
  if W0 <= 0 then W0 := 1;
  if H0 <= 0 then H0 := 1;
  Pad := 2;
  InnerW := 100 - Pad * 2; InnerH := 100 - Pad * 2;
  if (InnerW <= 0) or (InnerH <= 0) then Continue;
  if InnerW / W0 < InnerH / H0 then Scale := InnerW / W0 else Scale := InnerH / H0;
  GSignSect := Sect;
  GSignScale := Scale;
  // как в TileDraw: Xpix = X*Scale + DX, Ypix = Y*Scale + DY, центрируем в прямоугольнике Pad..100-Pad
  GSignDX := Pad + (InnerW - W0 * Scale) * 0.5 - Sect.Left * Scale;
  GSignDY := Pad + (InnerH - H0 * Scale) * 0.5 - Sect.Top * Scale;
  if PS.SignBitmap = nil then PS.SignBitmap := TTwgBitmap.Create(PS);
  PS.SignBitmap.Bitmap.SetSize(100,100);
  GSignBmp := PS.SignBitmap.Bitmap;
  GSignBmpCanvas := GSignBmp.Canvas;
  GSignBmpCanvas.BeginScene;
  try
   GSignBmpCanvas.Clear(0);
   Geo := TGeometryEvents.Create(0, SignBitmapOnPoly, SignBitmapOnText);
   try
    PS.DrawTo(Geo);
   finally
    Geo.Free;
   end;
  finally
   GSignBmpCanvas.EndScene;
   PS.SignBitmap.Bitmap.SaveToFile(MainPath + IntToStr(PS.MyInd)+'.bmp');
   GSignBmpCanvas := nil; GSignBmp := nil;
  end;
 end;
end;

initialization
 GlobalPoint := nil;
finalization
 If GlobalPoint <> nil then GlobalPoint.Free;
end.
