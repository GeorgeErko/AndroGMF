unit WpArcs;
interface uses WpTwigs, Collect, newConsts, Maths_Basic, EcDot, SysUtils, Splines;

type
     // ветвь хранящая сглаженные точки старой
     // 1. При рисовании показывает точки старой ветви
  TArcTwig=class(TTwig)
   ArcCoord :PCollection;
     Constructor   Load  (Stream :TBufStream);Override;
     Procedure     Store (Stream :TBufStream);Override;
   end;

  TTwigSpline=class(TTwig)
   ArcCoord :PCollection;
     class function UseVirtualVertex: boolean;
     Constructor Create(W1:Integer;Data:Pointer=nil);override;
     Constructor CreateAsTwig(Twig:TTwig;AddCoord:Boolean);override;
     Destructor Destroy;Override;
    {}
     Constructor   Load  (Stream :TBufStream);Override;
     Procedure     Store (Stream :TBufStream);Override;
    {}
     Procedure AddTwigAndArc(Twig:TTwig);
     Procedure Calculate;Override;
     Procedure Rotation;override;
   { В случае операций с точками это TwigCoord в случае отрисовки ArcCoord }
     Function ReadTwigCoord:PCollection;Override;
     Procedure WriteTwigCoord(C: PCollection);Override;
   { Захват и перемещение}
     Function  GetNearestPoint(XDrag,YDrag:Double;var Index:Integer):TDot;override;
   {}
     Procedure SetMinMax;override;
     Function GetTwigDist(XDrag, YDrag: Double; var X1,Y1: Double): Double;override;
     Function GetSegment(x,y:Double):Integer;override;
   {}
   { Для перемещения знаков по линии }
    Function GetLineDistance(X1,Y1,XR,YR:Double):Double;override;
    Procedure Move(Dx,Dy:Double);override;
   end;

  TTwigSpline3D=class(TTwigSpline)
   Z:Single;
    Constructor Create(W1:Integer;Z1:Pointer=nil);override;
    constructor CreateAsTwig(Twig: TTwig; AddCoord: Boolean);override;
    {}
     Constructor   Load  (Stream :TBufStream);Override;
     Procedure     Store (Stream :TBufStream);Override;
    {}
    procedure Calculate;override;
    function GetData:Pointer;override;
    Function  ZValue:Double;override;
   end;

  TTwigSpline3DHermit=class(TTwigSpline3D)
   procedure Calculate;override;
  end;

  TTwigSpline3DB=class(TTwigSpline3D)
   procedure Calculate;override;
  end;

  TCircRecord=class(TTwgObject)
   XC,YC,XR,YR:Double;
    Constructor Create(XC1,YC1,XR1,YR1:Double);
   end;

 // коллекция содержит координаты точек типа TDot - сортирует их по углам от XC, YC

 TAngleCollection = class (TSortedCollection)
   XC,YC:Double;
   Constructor Create(XC_,YC_:Double);
   Function Compare(Key1,Key2:Pointer):Integer;override;
  end;

  TTwigCircle = class(TTwig)
   ArcCoord:PCollection;
   perePoints:TAngleCollection;
    Constructor Create(W1:Integer;Data:Pointer=nil);override;
    constructor CreateAsTwig(Twig: TTwig; AddCoord: Boolean);override;
    Constructor   Load  (Stream :TBufStream);Override;
    Procedure     Store (Stream :TBufStream);Override;
   {}
    Procedure Calculate;override;
    Function Radius:Double;
    Function C:TDot;
    Function R:TDot;
   { Доступ к координатам }
    Function ReadTwigCoord:PCollection;override;
    Procedure WriteTwigCoord(C:PCollection);override;
    Procedure Rotation;override;
    Function GetTwigDist(XDrag,YDrag:Double;Var X1,Y1:Double):Double;override;
    Function CreateVirtualVertex:Integer;
    Procedure FreeVirtualVertex;
    Procedure SetMinMax;override;
   { Для перемещения знаков по линии }
    Function GetLineDistance(X1,Y1,XR,YR:Double):Double;override;
   {}
    Destructor Destroy;override;
   {}
    Function GetSegment(X,Y:Double):Integer;override;
    Function ModifyPerePoints:PCollection;// возвращает дуги, как результат рассечения окружности
    Procedure InsertPerePoint(Dot:TDot);
    Procedure ClearPerePoints;
   {}
    Function GetLength:Double;override;
    Procedure Move(Dx,Dy:Double);override;
  end;

const hsLeft = 1000;
      hsRight = 1001;
      hsCenter = 1002;

{type
  TTwigParaLine = class(TTwig)
   TwigL,TwigR:TTwig;
   HotSpot:Integer; // 0 - лево, 1 - право, 2 - центр
    Constructor Create(W1:Integer;Data:Pointer=nil);override;
    Constructor CreateAsTwig(Twig: TTwig; AddCoord: Boolean);override;
    Procedure Calculate;override;
    Procedure Paint(Dc:hDc);override;
  end;
}
var DoubleZ:Double=ZNull;

implementation uses  Types_Dimano, circle_di, newUtil, newProperties;

{ TArcTwig }

Constructor TArcTwig.Load;
 begin
  inherited Load(Stream);
  ArcCoord:=PCollection(Stream.Get);
 end;

Procedure TArcTwig.Store;
 begin
  inherited Store(Stream);
  Stream.Put(ArcCoord);
 end;
{-----------------------------------------------------------------------}

{ TTwigSpline }

Constructor TTwigSpline.Create;
 begin
  inherited Create(W1);
  ArcCoord:=PCollection.Create(1);
 end;

constructor TTwigSpline.CreateAsTwig(Twig: TTwig; AddCoord: Boolean);
begin
 inherited CreateAsTwig(Twig,AddCoord);
 If Twig is TTwigSpline then
  begin
   ArcCoord:=PCollection.Create(1);
   Calculate; // сглаживаем ветвь
  end;
end;

Destructor TTwigSpline.Destroy;
 begin
  inherited Destroy;
  ArcCoord.Free;
 end;

Constructor TTwigSpline.Load;
 begin
  ArcView:=0;
  ArcCoord:=nil;
  inherited Load(Stream);
  ArcCoord:=PCollection(Stream.Get);
  ArcView:=0;
  Calculate;
 end;

Procedure TTwigSpline.Store;
var P:Pointer;
 begin
  inherited Store(Stream);
  P:=ArcCoord;ArcCoord:=PCollection.Create(1);
  Stream.Put(ArcCoord);
  ArcCoord.Free;ArcCoord:=P;
 end;

{-----------------------------------------------------------------------}
Procedure TTwigSpline.AddTwigAndArc;
 var I:Integer;
 begin
  For I:=0 to Twig.Coord.Count-1 do
   Coord.Insert(TDot.CreateAsDot(Twig.Coord[I]));
   UZnak:=Twig.UZnak;
   Rang :=Twig.Rang;
   Color:=Twig.Color;
  // кривим
  Calculate;
 end;

var Xs,Ys,Xs1,Ys1:array[0..100000] of double;

Procedure TTwigSpline.Calculate;
 var I,N,ArcKV:Integer;AV:Byte;
 begin
  ArcCoord.FreeAll;
  if TwigCoord.Count<2 then exit else
  If TwigCoord.Count=2 then begin
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[0]));
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[1]));
    SetMinMax;
   exit;
  end;
  AddLines(2,True);
  // Заполняем массивы
   For I:=0 to TwigCoord.Count-1 do
    begin                                                                
     Xs[I]:=(TDot(TwigCoord[I]).XDot);
     Ys[I]:=(TDot(TwigCoord[I]).YDot);
    end;
  // Делим
   ArcKV:=25;//GGraphSet.ArcKV;
   CatMull_Rom(Xs,TwigCoord.Count,ArcKV,Xs1,N);
   CatMull_Rom(Ys,TwigCoord.Count,ArcKV,Ys1,N);
  // Вставляем координаты
   For I:=0 to N do
    If (I=0) or (I=N) then
     ArcCoord.Insert(TDot.Create(Xs1[I],Ys1[I],10)) else
     ArcCoord.Insert(TDot.Create(Xs1[I],Ys1[I],0));
  // Удаляем лишние 2 точки из ArcCoord
  TwigCoord.AtFree(0);
  TwigCoord.AtFree(TwigCoord.Count-1);
  TDot(TwigCoord[0]).What:=10;
  TDot(TwigCoord[TwigCoord.Count-1]).What:=10;
  TDot(ArcCoord[0]).What:=10;
  TDot(ArcCoord[ArcCoord.Count-1]).What:=10;
  AV:=ArcView;ArcView:=1;SetMinMax;ArcView:=AV;
end;

Function TTwigSpline.ReadTwigCoord;
 begin
 { If (ArcCoord.Count=0) or (LOperation in [Lo_MovePoint]) then Result:=TwigCoord else Result:=ArcCoord1;}
{  If (ArcCoord.Count=0) then Result:=TwigCoord else Result:=ArcCoord;}
  if ArcView>0 then Result:=ArcCoord else Result:=TwigCoord;
 end;

Procedure TTwigSpline.WriteTwigCoord(C: PCollection);
begin
 if ArcView>0 then begin ArcCoord:=C;end else TwigCoord:=C;
end;


function TTwigSpline.GetNearestPoint(XDrag, YDrag: Double;
  var Index: Integer): TDot;
begin
 Result:=inherited GetNearestPoint(XDrag,YDrag,Index);
end;



procedure TTwigSpline.Rotation;
 var AC:Integer;
begin
 inherited Rotation;
 AC:=ArcView;ArcView:=1;
 try inherited Rotation; finally ArcView:=AC;end;
 Calculate;
 SetMinMax;
end;

procedure TTwigSpline.SetMinMax;
 var AV,I:Integer;
begin
 If ArcCoord<>nil then
 begin
  AV:=ArcView;ArcView:=1;
   inherited SetMinMax;
  ArcView:=AV;
 end;
 For I:=0 to TwigCoord.Count-1 do
  begin
   If (I=0) or (I=TwigCoord.Count-1) then TDot(TwigCoord[I]).What:=10 else TDot(TwigCoord[I]).What:=0;
  end;
end;

function TTwigSpline.GetTwigDist(XDrag, YDrag: Double; var X1,
  Y1: Double): Double;
var AV:Integer;
begin
 AV:=ArcView;ArcView:=1;
 Result:=inherited GetTwigDist(XDrag,YDrag,X1,Y1);
 ArcView:=AV;
end;

function TTwigSpline.GetSegment(x, y: Double): Integer;
var I:Integer;D1,D2:TDot;x1,y1:Double;S,S2:Double;Tw:TTwig;
begin
S:=inherited GetTwigDist(x,y,x1,y1);
I:=1;
Tw:=TTwig.Create(0);
S2:=10000;Result:=-1;
 For I:=0 to Coord.Count-2 do
  begin
   D1:=Coord[I];D2:=Coord[I+1];
   Tw.Coord.Insert(D1);Tw.Coord.Insert(D2);
   S2:=Tw.GetTwigDist(x,y,x1,y1);
   Tw.Coord.DeleteAll;
    If S=S2 then begin Result:=I+1;break;end;
  end;
Tw.Free;
end;

function TTwigSpline.GetLineDistance(X1, Y1, XR, YR: Double): Double;
begin
 Result:=0;
end;

class function TTwigSpline.UseVirtualVertex: boolean;
begin
 Result:=True;
end;


procedure TTwigSpline.Move(Dx, Dy: Double);
var I:Integer;D:TDot;
begin
 inherited Move(Dx,Dy);
 For I:=0 to ArcCoord.Count-1 do begin
  D:=ArcCoord.FList[I];
  D.XDot:=D.XDot+Dx;
  D.YDot:=D.YDot+Dy;
 end;
end;

{ TTwigSpline3D }

procedure TTwigSpline3D.Calculate;
 var I:Integer;
begin
 inherited Calculate;
  For I:=0 to TwigCoord.Count-1 do
   TDot(TwigCoord[I]).Z:=Z;
  For I:=0 to ArcCoord.Count-1 do
   TDot(ArcCoord[I]).Z:=Z;
end;

Constructor  TTwigSpline3D.Create;
begin
 inherited Create(Twig_3DSpline);
 if Z1<>nil then Z:=PDouble(Z1)^ else Z:=ZNull;
end;

constructor TTwigSpline3D.CreateAsTwig(Twig: TTwig; AddCoord: Boolean);
begin
 Inherited CreateAsTwig(Twig,AddCoord);
 if (Twig is TTwigSpline3D) then Z:=TTwigSpline3D(Twig).Z else Z:=ZNull;
end;

function TTwigSpline3D.GetData: Pointer;
begin
 DoubleZ:=Z;
 Result:=@DoubleZ;
end;

constructor TTwigSpline3D.Load(Stream: TBufStream);
begin
 inherited Load(Stream);
 Stream.Read(Z,SizeOf(Z));
 Calculate;
end;

procedure TTwigSpline3D.Store(Stream: TBufStream);
begin
 inherited Store(Stream);
 Stream.Write(Z,SizeOf(Z));
end;

function TTwigSpline3D.ZValue: Double;
begin
 Result:=Z;
end;

{ TTwigSpline3DHermit }

procedure TTwigSpline3DHermit.Calculate;
// var Xs,Ys,Xs1,Ys1,OutX,OutY:array[0..10000] of double;
var  I,N,ArcKV:Integer;AV:Byte;
     DB,DB1,DE,DE1:TDot1;Xk,Yk:Double;
 begin
{  inherited Calculate;
  exit;}
  ArcCoord.FreeAll;
  if TwigCoord.Count<2 then exit else
  If TwigCoord.Count=2 then begin
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[0]));
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[1]));
    SetMinMax;
   exit;
  end;
  AddLines(2,True);
  DB:=Coord[0];DB1:=Coord[1];DE:=Coord[Coord.Count-2];DE1:=Coord[Coord.Count-1];
   Xk:=((DB.X-DB1.X)-(DB.Y-DB1.Y))/Distance(DB.X,DB.Y,DB1.X,DB1.Y);
   Yk:=((DE.X-DE1.X)-(DE.Y-DE1.Y))/Distance(DE.X,DE.Y,DE1.X,DE1.Y);
  TwigCoord.AtFree(0);
  TwigCoord.AtFree(TwigCoord.Count-1);
  // Заполняем массивы
   For I:=0 to TwigCoord.Count-1 do
    begin
     Xs[I]:=(TDot(TwigCoord[I]).XDot);
     Ys[I]:=(TDot(TwigCoord[I]).YDot);
    end;
  // Делим
   ArcKV:=25;//GGraphSet.ArcKV;
   Hermite(Xs,TwigCoord.Count,Xk,Yk,ArcKV,Xs1);
   Hermite(Ys,TwigCoord.Count,Xk,Yk,ArcKV,Ys1);
   N:= (TwigCoord.Count-1) * ArcKV + 1;
  // Вставляем координаты
   For I:=0 to N-1 do
    If (I=0) or (I=N-1) then
     ArcCoord.Insert(TDot.Create(Xs1[I],Ys1[I],10)) else
     ArcCoord.Insert(TDot.Create(Xs1[I],Ys1[I],0));
  // Удаляем лишние 2 точки из ArcCoord
  TDot(TwigCoord[0]).What:=10;
  TDot(TwigCoord[TwigCoord.Count-1]).What:=10;
  TDot(ArcCoord[0]).What:=10;
  TDot(ArcCoord[ArcCoord.Count-1]).What:=10;
  AV:=ArcView;ArcView:=1;SetMinMax;ArcView:=AV;
end;

{ TTwigSpline3DB }

//var Xs,Ys,Xs1,Ys1:array[0..10000] of double;

procedure TTwigSpline3DB.Calculate;
var  I,N,ArcKV:Integer;AV:Byte;
     m:Integer;Poly:PCollection;P1,P2:TDot1;
 begin
  ArcCoord.FreeAll;
  if TwigCoord.Count<2 then exit else
  If TwigCoord.Count=2 then begin
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[0]));
    ArcCoord.Insert(TDot.CreateAsDot(TwigCoord[1]));
    SetMinMax;
   exit;
  end;
   Poly:=TwigCoord;
   m := poly.count;
   if m > 1 then begin
     p1 := poly[0];
     p2 := poly[1];
     poly.AtInsert( 0, TDot.CreateZ( 2 * p1.x - p2.x, 2 * p1.y - p2.y, Z ,0) );
     m := poly.count;
     p1 := poly[m-2];
     p2 := poly[m-1];
     poly.Insert( TDot.CreateZ( 2 * p2.x - p1.x, 2 * p2.y - p1.y, Z, 0 ) );
   end;
//  AddLines(2,True);
  // Заполняем массивы
   For I:=0 to TwigCoord.Count-1 do
    begin
     Xs[I]:=(TDot(TwigCoord[I]).XDot);
     Ys[I]:=(TDot(TwigCoord[I]).YDot);
    end;
  // Делим
    ArcKV:=25;//GGraphSet.ArcKV;
    if ArcKV=0 then ArcKV:=5;
   BS_Spline(Xs,TwigCoord.Count,ArcKV,Xs1);
   BS_Spline(Ys,TwigCoord.Count,ArcKV,Ys1);
   N:= (TwigCoord.Count-3) * ArcKV;
  // Вставляем координаты
//  Writeln(Z);
   For I:=0 to N do
    If (I=0) or (I=N) then
     ArcCoord.Insert(TDot.CreateZ(Xs1[I],Ys1[I],Z,10)) else
     ArcCoord.Insert(TDot.CreateZ(Xs1[I],Ys1[I],Z,0));
  // Удаляем лишние 2 точки из ArcCoord
  TwigCoord.AtFree(0);
  TwigCoord.AtFree(TwigCoord.Count-1);
  TDot(TwigCoord[0]).What:=10;
  TDot(TwigCoord[TwigCoord.Count-1]).What:=10;
  TDot(ArcCoord[0]).What:=10;
  TDot(ArcCoord[ArcCoord.Count-1]).What:=10;
  AV:=ArcView;ArcView:=1;SetMinMax;ArcView:=AV;
end;

{ TCircRecord }

constructor TCircRecord.Create(XC1, YC1, XR1, YR1: Double);
begin
 XC:=XC1;YC:=YC1;XR:=XR1;YR:=YR1;
end;

{ TTwigCircle }

constructor TTwigCircle.Create(W1: Integer; Data: Pointer);
begin
 inherited Create(W1);
 With TCircRecord(Data) do
  begin
   Insert(TDot.Create(XC,YC,10));
   Insert(TDot.Create(XR,YR,10));
   Insert(TDot.Create(XC,YC,10));
  end;
ArcCoord:=PCollection.Create(1);
end;

procedure TTwigCircle.Calculate;                
var P:PCollection;I:Integer;D1:TDot1;D2:TDot1;Kv:Integer;
begin
 Kv:=Quants_For_Arcs;                            
 P:=Circle2(C.XDot,C.YDot,R.XDot,R.YDot,Radius,Kv);
 ArcCoord.FreeAll;
 For I:=0 to P.Count-1 do
  begin                         
   D1:=P[I];//D2:=P[I+1];
   ArcCoord.Insert(TDot.Create(D1.X,D1.Y,0));
  end;
 P.Free;
// Writeln(ArcCoord.Count);
// TDot(TwigCoord[2]).XDot:=C.XDot;TDot(TwigCoord[2]).YDot:=C.YDot;
 SetMinMax;
end;

function TTwigCircle.CreateVirtualVertex: Integer;
var A3,sErr:Double;N:Integer;
begin
 sErr:=0.1;//GGraphSet.MaxPlo;
 A3:=Pi*2;
 N:=Round(SQRT(SQR(Radius)*A3*A3*A3/(12*sErr)));
end;

procedure TTwigCircle.FreeVirtualVertex;
begin

end;

destructor TTwigCircle.Destroy;
begin
 Inherited Destroy;
 ArcCoord.Free;
 If perePoints<>nil then perePoints.Free;
end;

function TTwigCircle.GetLineDistance(X1, Y1, XR, YR: Double): Double;
begin
 //
end;

function TTwigCircle.GetTwigDist(XDrag, YDrag: Double; var X1,
  Y1: Double): Double;
var fromRadius:Double;
    Va,Vb:lPoint;
begin
 fromRadius:=Distance(XDrag,YDrag,C.XDot,C.YDot);
 Result:=abs(fromRadius-Radius);
// Writeln(fromRadius,' ',Radius,' Res=', Result);
 Va.X:=C.XDot;Va.Y:=C.YDot;Vb.X:=XDrag;Vb.Y:=YDrag;
 set_otr_dl(Va,Vb,Radius);
 X1:=Vb.X;Y1:=Vb.Y;
// Writeln('X1=',X1,' Y1=',Y1);
end;


function TTwigCircle.ReadTwigCoord: PCollection;
begin
 If ArcView=1 then Result:=ArcCoord else Result:=TwigCoord;
end;

procedure TTwigCircle.Rotation;
begin
 inherited Rotation;
end;

procedure TTwigCircle.SetMinMax;
 var AV:Integer;
begin
 if ArcCoord<>nil then
 begin
  AV:=ArcView;ArcView:=1;
   inherited SetMinMax;
  ArcView:=AV;
 end;
end;

procedure TTwigCircle.WriteTwigCoord(C: PCollection);
begin
 if ArcView>0 then begin ArcCoord:=C;end else TwigCoord:=C;
end;


function TTwigCircle.Radius: Double;
begin
 Result:=Distance(C.XDot,C.YDot,R.XDot,R.YDot);
end;

function TTwigCircle.C: TDot;
begin
 Result:=TwigCoord[0];
end;

function TTwigCircle.R: TDot;
begin
 Result:=TwigCoord[1];
end;


constructor TTwigCircle.Load(Stream: TBufStream);
begin
 inherited Load(Stream);
// Writeln('CCountLoad=',TwigCoord.Count);
 ArcCoord:=PCollection.Create(1);
 Calculate;
end;

procedure TTwigCircle.Store(Stream: TBufStream);
begin
 inherited Store(Stream);
end;

constructor TTwigCircle.CreateAsTwig(Twig: TTwig; AddCoord: Boolean);
var Tw:tTwigCircle;
begin
 inherited CreateAsTwig(Twig,AddCoord);
 Tw:=TTwigCircle(Twig);
//  Insert(TDot.Create(Tw.C.XDot,Tw.C.YDot,10));
//  Insert(TDot.Create(Tw.R.XDot,Tw.R.YDot,10));
//  Insert(TDot.Create(Tw.C.XDot,Tw.C.YDot,10));
 ArcCoord:=PCollection.Create(1);
 perePoints:=perePoints;
end;

{ TTwigParaLine }
{                                                    
procedure TTwigParaLine.Calculate;
begin
end;

constructor TTwigParaLine.Create(W1: Integer; Data: Pointer);
begin
  inherited;

end;

constructor TTwigParaLine.CreateAsTwig(Twig: TTwig; AddCoord: Boolean);
begin
  inherited;

end;

procedure TTwigParaLine.Paint(Dc: hDc);
begin
  inherited;

end;
}
function TTwigCircle.GetSegment(X, Y: Double): Integer;
var I:Integer;D1,D2:TDot;x1,y1:Double;S,S2:Double;Tw:TTwig;
begin
S:=inherited GetTwigDist(x,y,x1,y1);
I:=1;
Tw:=TTwig.Create(0);
S2:=10000;Result:=-1;
 For I:=0 to Coord.Count-2 do
  begin
   D1:=Coord[I];D2:=Coord[I+1];
   Tw.Coord.Insert(D1);Tw.Coord.Insert(D2);
   S2:=Tw.GetTwigDist(x,y,x1,y1);
   Tw.Coord.DeleteAll;
    If S=S2 then begin Result:=I+1;break;end;
  end;
Tw.Free;
end;

procedure TTwigCircle.InsertPerePoint(Dot: TDot);
begin
 if perePoints = nil then perePoints:=TAngleCollection.Create(C.XDot,C.YDot);
 perePoints.Insert(Dot);
end;

function TTwigCircle.ModifyPerePoints: PCollection;
var D1,D2:TDot;XD,YD:Double;
    AR:TArcRecord;
    Tw:TTwigArc;
    I:Integer;
begin
 If perePoints = nil then exit;
 Result:=PCollection.Create(1);
// Writeln('======================================');
 For I:=0 to perePoints.Count-1 do begin
  D1:=perePoints[I];
//  Writeln(Direct_Angle(C.XDot,C.YDot,D1.XDot,D1.YDot)*180/Pi:8:2)
 end;
 For I:=0 to perePoints.Count-1 do begin
   If I+1>perePoints.Count-1 then begin
    D1:=perePoints[I];D2:=perePoints[0];
   end else begin
    D1:=perePoints[I];D2:=perePoints[I+1];
   end;
   middle_point_of_arc_circle(C.XDot,C.YDot,D1.XDot,D1.YDot,D2.XDot,D2.YDot,XD,YD);
   AR:=TArcRecord.Create(C.XDot,C.YDot,D1.XDot,D1.YDot,D2.XDot,D2.YDot,XD,YD);
   Tw:=TTwigArc.Create(0,AR);Tw.Calculate;
   If Properties<>nil then Tw.Properties:=TProperties.CreateAs(Properties) else Tw.Properties:=nil;
   Tw.Koef:= Koef;
   Tw.What:= What;
  AR.Free;
  Result.Insert(Tw);
 end;
// Writeln('CountArcs = ',Result.Count);
 perePoints.FreeAll;perePoints:=nil;
end;

procedure TTwigCircle.ClearPerePoints;
begin
 perePoints.Free;perePoints:=nil;
end;

function TTwigCircle.GetLength: Double;
begin
 Result:=2*Pi*Radius;
end;

procedure TTwigCircle.Move(Dx, Dy: Double);
var I:Integer;D:TDot;
begin
 inherited Move(Dx,Dy);
 For I:=0 to ArcCoord.Count-1 do begin
  D:=ArcCoord.FList[I];
  D.XDot:=D.XDot+Dx;
  D.YDot:=D.YDot+Dy;
 end;
end;

{ TAngleCollection }

Function  EqualPoints(D1,D2:TDot): boolean;
 begin
  //Result:=(Abs(TDot(D1).XDot-TDot(D2).XDot)<1/Const_Of_PrecCoord) and (Abs(TDot(D1).YDot-TDot(D2).YDot)<1/Const_Of_PrecCoord);
  Result:=(Abs(TDot(D1).XDot-TDot(D2).XDot)<1/1000) and (Abs(TDot(D1).YDot-TDot(D2).YDot)<1/1000);
 end;

function TAngleCollection.Compare(Key1, Key2: Pointer): Integer;
var D1,D2:TDot;
begin
 D1:=TDot(Key1);D2:=TDot(Key2);
 If EqualPoints(D1,D2) then Result:=0 else
 If Direct_Angle(XC,YC,D1.XDot,D1.YDot)<Direct_Angle(XC,YC,D2.XDot,D2.YDot) then Result:=1 else Result:=-1;
end;

constructor TAngleCollection.Create(XC_, YC_: Double);
begin
 XC:=XC_;YC:=YC_;Duplicates:=False;
 inherited Create(1);
end;

Initialization
end.


