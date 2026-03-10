unit Types2;


interface
 Uses Types_dimano, Collect, SysUtils, Classes, FMX.Graphics, maths_basic,
      System.Types;

type
  TEdgeConnection=class;

  TConnectionPoint=class(TTwgObject)
   X,Y:Double;
   Points:TEdgeConnection;
   Dot:Pointer;
   Index:Integer;
   Min,Max:TConnectionPoint;
    Constructor Create(Dot1:Pointer);
    Function DirectAngleTo(P:TConnectionPoint):Double;
    Function DistanceTo(P:TConnectionPoint):Double;
    Procedure InsertPoint(Dot_:TConnectionPoint);
    Procedure SetMinMax(I:Integer;Debug:boolean=False);
    Function GetIndex(P:TConnectionPoint;Debug:boolean=False):Integer;
    Destructor Destroy;Override;
  end;

  TEdgeConnection=class(TSortedCollection)
   KeyPoint:TConnectionPoint;
   function Compare(Key1,Key2:Pointer):integer;override;
  end;

  TConnectionPoints=class(TSortedCollection)
    function Compare(Key1,Key2:Pointer):integer;override;
    Procedure InsertEdge(Dt1,Dt2:Pointer);
  end;

  TConnectionPolygons=class(TSortedCollection)
    function Compare(Key1,Key2:Pointer):integer;override;
  end;

  TConnectionPolygons2=class(TSortedCollection)
    function Compare(Key1,Key2:Pointer):integer;override;
  end;
  // коллекция отрезков для TConnectionPoint

Type
  TPolygon = class(TTwgObject)
   Active:byte;
   ID, xmin, ymin, xmax, ymax : Double;
   Points:PCollection;
   Holes:PCollection;
    Constructor Create(ID1:Double);
    Constructor SuperCreate( ID1 : Double;
      points1 : PCollection; xmin1, ymin1, xmax1, ymax1 : double );

    Procedure Insert(X,Y:Double);
    Procedure InsertHole(P:Pointer);
    Destructor Destroy;Override;
      Function GetPoint(Index:Integer):TDot1;
     Property Point[Index:Integer]:TDot1 read GetPoint;Default;
      Function GetHole(Index:Integer):TPolygon;
     Property Hole[Index:Integer]:TPolygon read GetHole;
     Function Count:Integer;
     procedure AtDelete( i : integer );
     procedure AtFree( i : integer );
     procedure AtInsert( i : integer; x, y : double );
   {}
     Procedure Draw;
  end;

  TSortedInt = class(TSortedCollection)
    function Compare(Key1,Key2:Pointer):Integer;Override;
    function KeyOf(Item: Pointer): Pointer;Override;
   end;

implementation
//  Uses Selector;

 { TSortedInt }

function TSortedInt.Compare(Key1,Key2:Pointer):Integer;
begin
if TInt(Key1).Num<TInt(Key2).Num then Compare:=-1;
if TInt(Key1).Num=TInt(Key2).Num then Compare:=0;
if TInt(Key1).Num>TInt(Key2).Num then Compare:=1;
end;

function TSortedInt.KeyOf(Item: Pointer): Pointer;
begin
 Result:=Item;
end;

 { TPolygon }

Constructor TPolygon.Create(ID1:Double);
 begin
  ID:=ID1;
  Points:=PCollection.Create(1);
  Holes:=PCollection.Create(1);
  Active:=0;
 end;

Procedure TPolygon.Insert;
 begin
  Points.Insert(TDot1.Create(X,Y));
 end;

Procedure TPolygon.AtDelete;
 begin
  Points.AtDelete( i );
 end;

procedure TPolygon.AtInsert;
 begin
  Points.AtInsert( i, TDot1.Create( x, y ) );
 end;

procedure TPolygon.AtFree;
 begin
  Points.AtFree( i );
 end;

Procedure TPolyGon.InsertHole;
 begin
  Holes.Insert(P);
 end;

Function TPolygon.GetPoint(Index:Integer):TDot1;
 begin
  Result:=Points[Index];
 end;

Function TPolygon.GetHole(Index:Integer):TPolygon;
 begin
  Result:=Holes[Index];
 end;

Function TPolygon.Count:Integer;
 begin
  Result:=Points.Count;
 end;

Destructor TPolygon.Destroy;
 begin
  Points.Free;
  Holes.DeleteAll;Holes.Free;
 end;

Procedure TPolygon.Draw;
 var I:Integer;Ar:Array[0..100] of TPoint;P:TDot1;
 begin
 {
//  SEtRop2(GCanvas.Handle,R2_NotXorPen);
  For I:=0 to Points.Count do
   begin
    If I=Points.Count then P:=Point[0] else P:=Point[I];
    Ar[I].X:=XPix(P.X);Ar[I].Y:=YPix(P.Y);
   end;
 if Active=0 then
  GCanvas.Brush.Color:=clYellow else
 If Active=1 then  GCanvas.Brush.Color:=clREd else
 If Active=3 then  GCanvas.Brush.Color:=clBlack;
  PolyGon(GCanvas.Handle,Ar,I);
  For I:=0 to Holes.Count-1 do
   begin
    TPolyGon(Hole[I]).Active:=3;
    TPolyGon(Hole[I]).Draw;
   end;
   }
 end;

constructor TPolygon.SuperCreate( ID1 : Double; points1: PCollection;
                                  xmin1, ymin1, xmax1, ymax1 : Double );
begin
  ID:=ID1;
  points := points1;
  Holes:=PCollection.Create(1);
  Active:=0;
  xmin := xmin1;
  ymin := ymin1;
  xmax := xmax1;
  ymax := ymax1;
end;

{ TConnectionPoint }

constructor TConnectionPoint.Create;
begin
 X:=TDot1(Dot1).X;Y:=TDot1(Dot1).Y;
 Dot:=Dot1;
 Points:=TEdgeConnection.Create(1);
 Points.KeyPoint:=Self;
 Points.Duplicates:=False;
 Min:=nil;Max:=nil;
end;

destructor TConnectionPoint.Destroy;
begin
 Points.DeleteAll;Points.Free;
end;

function TConnectionPoint.DirectAngleTo(P: TConnectionPoint): Double;
begin
 Result := Direct_Angle(Y,X,P.Y,P.X);
end;

procedure TConnectionPoint.SetMinMax;
 var D0,D1,D2:Double;IPlus,IMinus:Integer;
begin
 If I=Points.Count-1 then IPlus:=0 else IPlus:=I+1;
 If I=0 then IMinus:=Points.Count-1 else IMinus:=I-1;
// if Debug then Writeln('RPM=',I,' ',IMinus,' ',IPlus,' ',Points.Count);
 D0:=DirectAngleTo(Points[I]);
 D1:=DirectAngleTo(Points[IMinus]);
 D2:=DirectAngleTo(Points[IPlus]);
 D1:=D1-D0; If D1<0 then D1:=2*Pi+D1;
 D2:=D2-D0; If D2<0 then D2:=2*Pi+D2;
 If D1<D2 then begin Min:=Points[IMinus];Max:=Points[IPlus]; end else
 begin Min:=Points[IPlus];Max:=Points[IMinus];end;
// Writeln('Min=Max ',Min=Max);
end;

function TConnectionPoint.GetIndex;
var i : integer;
begin
 For I:=0 to Points.Count-1 do
  If Points[I]=P then begin
{   if Points.Count=2 then begin
    Writeln('Da');
    // устанавливаем Min=Max
    if I=0 then Min:=Points[1] else Min:=Points[0];
    Max:=Min;
    Exit;
   end;}
   Result:=I;
    SetMinMax(I, Debug);
//    Writeln('Point=',Round(X),' ',Round(Y),' ',' from=', Round(P.X),' ',Round(P.Y));
//    Writeln('Min=',Round(Min.X),' ',Round(Min.Y),'  Max=',Round(Max.X),' ',Round(Max.Y));
   Exit;
  end;
 Result:=-1;
end;

procedure TConnectionPoint.InsertPoint(Dot_: TConnectionPoint);
begin
 Points.Insert(Dot_);
// Dot.Points.Insert(Self);
end;


function TConnectionPoint.DistanceTo(P: TConnectionPoint): Double;
begin
 Result := Distance(Y,X,P.Y,P.X);
end;

{ TEdgeConnection }

function TEdgeConnection.Compare(Key1, Key2: Pointer): integer;
begin
 If KeyPoint.DirectAngleTo(Key1)>KeyPoint.DirectAngleTo(Key2) then Result:=-1 else
 If abs( KeyPoint.DirectAngleTo(Key1) - KeyPoint.DirectAngleTo(Key2) ) < 1.0E-4
 then begin
  If abs(KeyPoint.DistanceTo(Key1)-KeyPoint.DistanceTo(Key2))< 1.0E-4 then Result:=0 else
  If KeyPoint.DistanceTo(Key1)>KeyPoint.DistanceTo(Key2) then Result:=-1 else
  Result:=1;
//  Writeln(Key1=Key2);readln;
 end else
 Result:=1;
end;

{ TConnectionPoints }

function TConnectionPoints.Compare(Key1, Key2: Pointer): integer;
 var P1,P2:TConnectionPoint;
begin
 P1:=Key1;P2:=Key2;
 If abs((P1.X+P1.Y)-(P2.X+P2.Y))<1.0E-4 then begin
  If (abs(P1.X-P2.X)<1.0E-4) and (abs(P1.Y-P2.Y)<1.0E-4) then Result:=0 else
  If abs(P1.X-P2.X)<1.0E-4 then begin
                     If P1.Y>P2.Y then Result:=1 else Result:=-1; // по оси Y
                    end else
  If P1.X>P2.X then Result:=1 else Result:=-1;
 end else
 If P1.X+P1.Y>P2.X+P2.Y then Result:=1 else
 Result:=-1;
end;

procedure TConnectionPoints.InsertEdge(Dt1, Dt2: Pointer);
 var DP,DP2:TConnectionPoint;I1,I2:Integer;
     Dot1,Dot2:TDot1;
begin
 Dot1:=Dt1;Dot2:=Dt2;
 // соблюдение правил соединения
 I1:=IndexOf(Dot1);
 If I1<>-1 then begin DP:=At(I1);end else
  begin
   DP:=TConnectionPoint.Create(Dot1);
   Insert(DP);
  end;
 I2:=IndexOf(Dot2);
 If I2<>-1 then begin DP2:=At(I2);end else
  begin
   DP2:=TConnectionPoint.Create(Dot2);
   Insert(DP2);
  end;
 // если найдена первая точка -> вставляем и устанавливаем соединение
 DP.InsertPoint(DP2);DP2.InsertPoint(DP);
end;

{ TCoonectionPolygons }

function TConnectionPolygons.Compare(Key1, Key2: Pointer): integer;
var P1,P2:TPolygon;D1,D2:Double;
begin
{ P1:=Key1;P2:=Key2;
 Orientation_Of_Polygon(P1.Points,D1);Orientation_Of_Polygon(P2.Points,D2);
 If D1>D2 then Result:=-1 else
 If D1=D2 then Result:=0 else
 Result:=1;
 }
 Orientation_Of_Polygon(Key1,D1);
 Orientation_Of_Polygon(Key2,D2);
  If abs( D1 - D2 ) < 1.0E-5 then
   begin
    {if equality_two_polygons( key1, key2 ) then Result := 0
     else result := -1;}
     Result := 0;
  end else
 If D1 > D2 then Result:=1 else Result:=-1;
end;

{ TConnectionPolygons2 }

function TConnectionPolygons2.Compare(Key1, Key2: Pointer): integer;
var
  D1, D2 : Double;
begin
{
  if equality_two_polygons( key1, key2 ) then Result := 0 else Result:=-1;
exit;
}
 Orientation_Of_Polygon(Key1,D1);
 Orientation_Of_Polygon(Key2,D2);
  If abs( D1 - D2 ) < 1.0E-5 then
   begin
    {if equality_two_polygons( key1, key2 ) then Result := 0
     else result := -1;}
     Result := 0;
  end else
 If D1 > D2 then Result:=1 else Result:=-1;
end;


{ TPiki }

initialization
end.
(*
var TP:TConnectionPoints;
    D1,D2:TDot1;
    CP,P1,P2:TConnectionPoint;

TP:=TConnectionPoints.Create(1);
 TP.InsertEdge(D1,D2);

 CP:=TP[0];

  P1:=CP.Points[0];
  P2:=CP.Points[1];

  {P1-CP-P2}

TP.Free;
*)
