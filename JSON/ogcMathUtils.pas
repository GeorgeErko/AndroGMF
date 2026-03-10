unit ogcMathUtils;

// {$mode Delphi}

interface

uses Classes, SysUtils, Math, ogcBasic;

const
  ZNull = 6356752.30;
  XYNull = ZNull * Pi;
  eps = 1.0E-4;

type

{ TlDot - класс для доступа к точкам без учета текущей ogsMatrix }
 TlDot = class(TogsBasic)
  XDot, YDot: Double;
  constructor Create(X, Y: Double);
  constructor CreateAs(Dot: TlDot);
 end;

{ TDot - точка с учетом текущих значений TogsMatrix }
 TDot = class(TogsGeometry)
 private
  function GetX: Double; virtual;
  function GetY: Double; virtual;
  procedure SetX(AValue: Double); virtual;
  procedure SetY(AValue: Double); virtual;
 public
  fX, fY: Double;
  Z : Double;
  constructor Create(X_, Y_: Double; Z_: Double = 0);
  //
  property X: Double read GetX write SetX;
  property Y: Double read GetY write SetY;
 end;

// liner functions
function Distance( x_i, y_i, x_j, y_j : double ) : double;
function Dist_Point_Line(X0_,Y0_,X1_,Y1_,X2_,Y2_: double; var x, y:double): double;
//возвращает растояние от точки [X0_,Y0_] до прямой,проходящей через точки [X1_,Y1_] и [X2_,Y2_],
//и точку(x,y) пересечения исходной прямой и прямой, проходящей через точку [X0_,Y0_] и перпендикулярной исходной
function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double; overload;
function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double; overload;
//возвращает растояние от точки [X0_,Y0_] до отрезка ([X1_,Y1_] ; [X2_,Y2_])
//и точку(x,y) пересечения исходной прямой и прямой, проходящей через точку [X0_,Y0_] и перпендикулярной исходной
//если пересечения нет то возвращает ближайшую из точек [X1_,Y1_], [X2_,Y2_]
function intersection_straight_lines( x_1,y_1, x_2,y_2, x_a,y_a, x_b,y_b
                                      : double; var t, O  : double) : integer;
{ Функция пересечения двух прямых заданных двумя отрезками:
     x = x_1 + ( x_2 - x_1 ) * O,
     y = y_1 + ( y_2 - y_1 ) * O;
     x = x_a + ( x_b - x_a ) * t,
     y = y_a + ( y_b - y_a ) * t.
  Таким образом, точка пересечения двух прямых может быть найдена по
  формуле
     x = x_a + ( x_b - x_a ) * t
     y = y_a + ( y_b - y_a ) * t
   где параметры O и t отвечают за местонахождение точки пересечения на
   прямых (x_1,y_1),(x_2,y_2) и (x_a,y_a),(x_b,y_b) соответственно.
  Например, если
    t = 0, то точка пересечения (x_a,y_a).
    t = 1, то точка пересечения (x_b,y_b).
    0 < t < 1, то точка пересечения лежит внутри отрезка (x_a,y_a),(x_b,y_b)
  ПРИ Этом, если прямые совпадают, то по определению возвращается:
   Result := 0, O, t := 0.     }

// polygons
function orientation_of_polygon( polygon : TogsCollection; var square : double ) : integer;
{ if Result = 0 then "polygon is not correct"
  if Result = 1 then "polygon is right orientation"
  if Result = -1 then "polygon is left orientation";
  var-double-parametr square is square of the polygon. }
function point_on_polygon_border( x, y : double; xx : TogsCollection ) : boolean;
{ Функция определяет лежит ли точка на границе многоугольника. }
function point_and_polygon( x, y : double; p : TogsCollection ) : integer;
{ Функция вычисляет отношение точки и многоугольника:
  -1 точка вне многоугольника,
   0 точка на границе,
   1 точка в многоугольнике. !!! проверить на примере}
function clip_polygon( x_1, y_1, x_3, y_3 : double; Points : TogsCollection ): integer;
{ Процедура производит отсечение многоугольника по
  параллельному прямоугольнику с диаметральнопротивоположными мершинами
  (x_1,y_1) и (x_2,y_2)}
function clip_interval( x_1, y_1, x_3, y_3 : double;
                          var x_a, y_a, x_b, y_b : double) : boolean;
{ отсечение отрезка прямоугольником. }
function angle( x_4, y_4, x_c, y_c : double ) : double;
{ функция вычисляет угол в правой декартовой системе координат (x,y) с
  центром в точке (x_c,y_c), образованный точкой (x_4,y_4). Угол
  отсчитывается от оси X  по часовой стрелке!}
function circle( x_c, y_c, r : double; var quants_number : integer ) : TogsCollection;
{ функция возвращает окружность в отрезках с центром в точке (x_c,y_c) }

function GStrToFloat(S: String): Double;
{ конвертация строки в вещественное число, с учетом разделителя ['.',',']}

implementation //uses ogcWriter;

{ TlDot }

{ TlDot }

constructor TlDot.Create(X, Y: Double);
begin
 XDot := X;
 YDot := Y;
end;

constructor TlDot.CreateAs(Dot: TlDot);
begin
 XDot := Dot.XDot;
 YDot := Dot.YDot;
end;

{ TDot }

function TDot.GetX: Double;
begin
 If ogsMatrix = nil then Result := fX else
 Result := xMatrix(ogsMatrix.X, fX, fY, ogsMatrix.Angle, ogsMatrix.Scale);
end;

function TDot.GetY: Double;
begin
 If ogsMatrix = nil then Result := fY else
 Result := yMatrix(ogsMatrix.Y, fX, fY, ogsMatrix.Angle, ogsMatrix.Scale);
end;

procedure TDot.SetX(AValue: Double);
begin
 fX := AValue;
end;

procedure TDot.SetY(AValue: Double);
begin
 fY := AValue;
end;

constructor TDot.Create(X_, Y_: Double; Z_:Double = 0);
begin
 X := X_;
 Y := Y_;
end;

function Distance(x_i, y_i, x_j, y_j: double): double;
begin
  Result := sqrt( sqr( x_i - x_j ) + sqr( y_i - y_j ) );
end;

function Dist_Point_Line(X0_, Y0_, X1_, Y1_, X2_, Y2_: double; var x, y: double): double;
var A, B, C:double;//Ax+By+C=0 уравнение прямой
begin
 if X1_<> X2_ then begin
   A := (Y2_- Y1_)/(X2_- X1_);
   B :=-1;
   C := Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);
 end else begin
   A := 1; B := 0; C := -X1_;
 end;
//
 Result := abs(A * X0_ + B * Y0_ + C) / sqrt(sqr(A) + sqr(B));
 y := (sqr(A) * Y0_ - B * C - A * B * X0_) / (sqr(A) + sqr(B));
 if A <> 0 then x := -( B * y + C) / A else x := X0_;
end;

function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
    s1,s2:double;//растояние до концов отрезка, используется если точка не принадлежит отрезку
begin
if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  y:=(sqr(A)*Y0_-B*C-A*B*X0_)/(sqr(A)+sqr(B));
  if A<>0 then x:=-(B*y+C)/A
  else x:=X0_;

  if ((x>=X1_)and(x<=X2_))or((x>=X2_)and(x<=X1_))then
    if ((y>=Y1_)and(y<=Y2_))or((y>=Y2_)and(y<=Y1_)) then
      result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B))
    else begin
      s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
      s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
      if s1<=s2 then begin
        result:=s1;
        x:=X1_;y:=Y1_;end
      else begin
        result:=s2;
        x:=X2_;y:=Y2_;end
    end
  else begin
    s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
    s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
    if s1<=s2 then begin
      result:=s1;
      x:=X1_;y:=Y1_;end
    else begin
      result:=s2;
      x:=X2_;y:=Y2_;end
  end;
end;

function intersection_straight_lines( x_1, y_1, x_2, y_2, x_a, y_a,
                          x_b, y_b : double; var t, O : double) : integer;
var
 a_11, a_12, a_21, a_22, b_1, b_2, delta : double;
 c, c1, a, a1, b, b1, xx : double;
begin
 t := 0;
 O := 0;
 if ( Distance(x_1, y_1, x_2, y_2 ) < 1.0E-14 ) or
    ( Distance( x_a, y_a, x_b, y_b ) < 1.0E-14 ) then
    begin
      Result := -1;
      Exit;
    end;
 a_11 := x_2 - x_1;
 a_12 := x_a - x_b;
 a_21 := y_2 - y_1;
 a_22 := y_a - y_b;
 b_1 := x_a - x_1;
 b_2 := y_a - y_1;
 delta := a_11 * a_22 - a_12 * a_21;
 if ( abs( delta ) > 1.0E-7 ) then
   begin
     t := ( b_2 * a_11 - a_21 * b_1 ) / delta;
     O := ( b_1 * a_22 - b_2 * a_12 ) / delta;
     Result := 1;
   end
  else begin
         c :=  y_1*(x_2-x_1)-x_1*(y_2-y_1);
         c1 := y_a*(x_b-x_a)-x_a*(y_b-y_a);
         a := y_2-y_1;
         b := -x_2+x_1;
         a1 := y_b-y_a;
         b1 := -x_b+x_a;
         c := c / sqrt( a*a + b*b );
         c1 := c1 / sqrt( a1*a1 + b1*b1 );
         if abs( c - c1 ) < 1.0E-4 then
           begin
             Result := 0;
             t := 1;
             O := 1;
             {
             o := 0.5;
             if abs( b1 ) > 1.0e-10 then
               begin
                 xx := ( x_1 - x_a ) / ( x_b - x_a );
                 if xx < 0 then t := xx
                  else t := ( x_2 - x_a ) / ( x_b - x_a );
               end
             else
               begin
                 xx := ( y_1 - y_a ) / ( y_b - y_a );
                 if xx < 0 then t := xx
                  else t := ( y_2 - y_a ) / ( y_b - y_a );
               end;
               }
           end
         else Result := -1;
       end;
end;

function Orientation_of_polygon( polygon : TogsCollection; var square : double ) : integer;
{ if Result = 0 then "polygon is not correct"
  if Result = 1 then "polygon is right orientation"
  if Result = -1 then "polygon is left orientation". }
var
 k : integer;
 sum, x, y1, y_1 : double;
begin
 Result := 0;
 square := 0;
 if polygon.Count < 3 then Exit;
 sum := 0;
 for k := 0 to polygon.Count-1 do
   begin
     if k = 0 then
       begin
         x := TDot( polygon[0] ).x;                 { X[n] }
         y1 := TDot( polygon[1] ).y;                {Y[n+1]}
         y_1 := TDot( polygon[polygon.Count-1] ).y; {Y[n-1]}
       end
     else
      if k = polygon.Count-1 then
        begin
          x := TDot( polygon[polygon.Count-1] ).x;   { X[n] }
          y1 := TDot( polygon[0] ).y;                {Y[n+1]}
          y_1 := TDot( polygon[polygon.Count-2] ).y; {Y[n-1]}
        end
      else
        begin
          x := TDot( polygon[k] ).x;       { X[n] }
          y1 := TDot( polygon[k+1] ).y;    {Y[n+1]}
          y_1 := TDot( polygon[k-1] ).y;   {Y[n-1]}
        end;
     sum := sum + x * ( y1 - y_1 );
   end;
 square := abs( sum / 2 );
 { orientation: }
 if sum > 0 then result := 1 else result := -1;
end;

function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
    s1,s2:double;//растояние до концов отрезка, используется если точка не принадлежит отрезку
    x,y:double;//точка пересечения
begin
  if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  y:=(sqr(A)*Y0_-B*C-A*B*X0_)/(sqr(A)+sqr(B));
  if A<>0 then x:=-(B*y+C)/A
  else x:=X0_;

  if ((x>=X1_)and(x<=X2_))or((x>=X2_)and(x<=X1_))then
    if ((y>=Y1_)and(y<=Y2_))or((y>=Y2_)and(y<=Y1_)) then
      result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B))
    else begin
      s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
      s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
      if s1<=s2 then result:=s1 else result:=s2;
    end
  else begin
    s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
    s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
    if s1<=s2 then result:=s1 else result:=s2;
  end;
end;

{ AI - assist }
function PointOnLine(X, Y, X1, Y1, X2, Y2: Double): Boolean;
var
  A, B, C: Double;
begin
  A := Y2 - Y1;
  B := X1 - X2;
  C := X2 * Y1 - X1 * Y2;
//  Writeln('ABC=',aA * X + B * Y + C,' ',eps);
  Result := (abs(A * X + B * Y + C) <= eps) and
            ((X >= X1) and (X <= X2) or (X >= X2) and (X <= X1)) and
            ((Y >= Y1) and (Y <= Y2) or (Y >= Y2) and (Y <= Y1));
end;

function point_on_polygon_border( x, y : double; xx : TogsCollection ): boolean;
var
  i : integer;
  x1, y1, x2, y2 : double;
begin
  result := FALSE;
// предполагаемая точность = eps
//  x1 := TDot( xx[0] ).x;
//  y1 := TDot( xx[0] ).y;
// Writeln('XY=',x, y,'==========================');
 For i := 0 to xx.count - 2 do begin
  x1 := TDot(xx[i]).x; y1 := TDot(xx[i]).y;
  x2 := TDot(xx[i+1]).x; y2 := TDot(xx[i+1]).y;
  If PointOnLine(x, y, x1, y1, x2, y2) then begin
 //  Writeln('EXIT ', I,' ',PointOnLine(x, y, x1, y1, x2, y2));
   result := true;
   exit;
  end else
 //  Writeln('DistPE=',PointOnLine(x, y, x1, y1, x2, y2),' ',x1, y1,' ',Dist_Point_Edge(X,Y,X1,Y1,X2,Y2));
 end;
end;

function point_and_polygon(x, y: double; p: TogsCollection): integer;
label label_1;
var
 i, j, k, c, intersect : integer;
 ss, x1, y1, t, o : double;
 p1, p2 : TDot;
begin
{ Writeln('XY=',X,' ',Y,'  Count=',P.Count);
 For I := 0 to P.Count - 1 do begin
  Writeln('XY=',TDot(P[I]).X,' ',TDot(P[I]).Y);
 end;
 Writeln('END');
}
 t := 0;
 O := 0;
 k := 1;

 if point_on_polygon_border( x, y, p )  then begin
                                              Result := 0;
                                              exit;
                                             end;
 Result := -1;
 j:=0;
 repeat
     c := 0;
     k := 0;
     if i  < p.Count-1 then
       begin
         p1 := TDot( p[j] );
         p2 := TDot( p[j+1] );
       end
     else
       begin
         p1 := TDot( p[j] );
         p2 := TDot( p[0] );
       end;
     x1 := ( p1.x + p2.x ) / 2;
     y1 := ( p1.y + p2.y ) / 2;
     { for i... }
     for i := 1 to p.Count-1 do
       begin
         if i < p.Count-1 then p2 := p[i+1] else p2 := p[0];
         p1 := p[i];
         ss := abs( x*(p2.y-p1.y)+ y*(p1.x-p2.x) -x1*(p2.y-p1.y)+ y1*(p2.x-p1.x) );
         {
     if abs( ss ) < 1.0e-5  then
       begin
         writeln('///////////////////////////////////////////  ',ss);
         goto label_1;
       end;
//}
         intersect := intersection_straight_lines( p1.x, p1.y, p2.x, p2.y,
                                                        x, y, x1, y1, t, o );
         if ( intersect = 1 ) and ( t < 0 ) and ( o >= 0 ) and ( o <= 1 ) then
           begin
             if ( abs( o ) < 1.0E-10 ) or ( abs( o - 1 ) < 1.0E-10 ) then
               begin
                 k := 1;
                 break;
               end;
             c := c + 1;
           end;
       end;
     { end for i... }
     if k = 0 then
       begin
         if ( ODD( c ) = TRUE ) and ( c > 0 ) then Result := 1;
         break;
       end;
 label_1:;
   j := j + 1;
 until j = p.Count-1;
//
 if k = 1 then
   begin
    Writeln('pizdets!!!!!!!!!: Point and Polygon !!!!!!!!!!!!!!');
   end;
end;

procedure new_vertex_to_polygon( x_1, y_1, x_2, y_2 : double;
                                             Points : TogsCollection );
var
  d0, d1 : TDot;
  t, O, x, y : double;
  i : integer;
begin
  i := 0;
  repeat
    d0 := Points[i];
    if ( i < Points.count-1 ) then d1 := Points[i+1] else d1 := Points[0];
    if ( ( intersection_straight_lines( x_1, y_1, x_2, y_2, d0.x, d0.y,
             d1.x, d1.y, t, O ) = 1 ) and ( t >= 0 ) and ( t <= 1 ) )
     then
         begin
           x := d0.fx + ( d1.fx - d0.fx ) * t;
           y := d0.fy + ( d1.fy - d0.fy ) * t;
           Points.Insert( i+1, TogsDot.Create( X, Y ) );
           i := i + 1;
         end;
    i := i + 1;
  until ( i > Points.count-1 );
end;

function clip_polygon( x_1, y_1, x_3, y_3 : double; Points : TogsCollection ): integer;
var
  x_2, y_2, x_4, y_4 : double;
  i : integer;
begin
 Result := 0;
//
  x_2 := x_1; y_2 := y_3;
  x_4 := x_3; y_4 := y_1;
  new_vertex_to_polygon( x_1, y_1, x_2, y_2, Points );
  for i := Points.count-1 downTo 0 do
   if ( TDot( Points[i] ).x - x_1 ) < -1.0E-10 then Points.AtFree(i);
   if Points.Count = 0 then exit;

  new_vertex_to_polygon( x_2, y_2, x_3, y_3, Points );
  for i := Points.count-1 downTo 0 do
   if ( TDot( Points[i] ).y - y_2 ) > 1.0E-10 then Points.AtFree(i);
   if Points.Count = 0 then exit;

  new_vertex_to_polygon( x_3, y_3, x_4, y_4, Points );
  for i := Points.count-1 downTo 0 do
   if ( TDot( Points[i] ).x - x_3 ) > 1.0E-10 then Points.AtFree(i);
   if Points.Count = 0 then exit;

  new_vertex_to_polygon( x_4, y_4, x_1, y_1, Points );
  for i := Points.Count-1 downTo 0 do
   if ( TDot( Points[i] ).y - y_1 ) < -1.0E-10 then Points.AtFree(i);
   if Points.Count = 0 then exit;
//
 Result := Points.Count;
end;

function clip_interval(x_1, y_1, x_3, y_3: double; var x_a, y_a, x_b, y_b: double): boolean;
var
  x_2, y_2, x_4, y_4, x_a_new, x_b_new, y_a_new, y_b_new, t, o : double;
  count, f1, f2, f3 : integer;
  label l_end;
begin
  x_2 := x_3;
  y_2 := y_1;
  x_4 := x_1;
  y_4 := y_3;
  count := 0;
  Result := FALSE;
  f1 := 0;
  if ( x_a > x_1 ) and ( x_a < x_3 ) and ( y_a > y_1 ) and ( y_a < y_3 ) then
    begin
      x_a_new := x_a;
      y_a_new := y_a;
      f1 := 1;
      count := 1;
    end;
  if ( x_b > x_1 ) and ( x_b < x_3 ) and ( y_b > y_1 ) and ( y_b < y_3 ) then
    begin
      if f1 = 1 then
        begin
          x_b_new := x_b;
          y_b_new := y_b;
          Result := TRUE;
          goto l_end;
        end
       else f1 := 2;
      count := 1;
      x_a_new := x_b;
      y_a_new := y_b;
    end;
{ begin 1 and 2 }
  if intersection_straight_lines( x_1, y_1, x_2, y_2, x_a, y_a,
                                                      x_b, y_b, t, O ) = 1 then
    begin
      if ( t >= 0 ) and ( t <= 1 ) and ( o >= 0 ) and ( o < 1 ) then
        begin
          if count = 0 then
            begin
              x_a_new := x_a + ( x_b - x_a ) * t;
              y_a_new := y_a + ( y_b - y_a ) * t;
            end
          else
            begin
              x_b_new := x_a + ( x_b - x_a ) * t;
              y_b_new := y_a + ( y_b - y_a ) * t;
            end;
          count := count + 1;
          if count = 2 then
            begin
              Result := TRUE;
              goto l_end;
            end;
        end;
    end;
{ begin 2 and 3 }
  if intersection_straight_lines( x_2, y_2, x_3, y_3, x_a, y_a,
                                                      x_b, y_b, t, O ) = 1 then
    begin
      if ( t >= 0 ) and ( t <= 1 ) and ( o >= 0 ) and ( o < 1 ) then
        begin
          if count = 0 then
            begin
              x_a_new := x_a + ( x_b - x_a ) * t;
              y_a_new := y_a + ( y_b - y_a ) * t;
            end
          else
            begin
              x_b_new := x_a + ( x_b - x_a ) * t;
              y_b_new := y_a + ( y_b - y_a ) * t;
            end;
          count := count + 1;
          if count = 2 then
            begin
              Result := TRUE;
              goto l_end;
            end;
        end;
    end;
{ begin 3 and 4 }
  if intersection_straight_lines( x_3, y_3, x_4, y_4, x_a, y_a,
                                                      x_b, y_b, t, O ) = 1 then
    begin
      if ( t >= 0 ) and ( t <= 1 ) and ( o >= 0 ) and ( o < 1 ) then
        begin
          if count = 0 then
            begin
              x_a_new := x_a + ( x_b - x_a ) * t;
              y_a_new := y_a + ( y_b - y_a ) * t;
            end
          else
            begin
              x_b_new := x_a + ( x_b - x_a ) * t;
              y_b_new := y_a + ( y_b - y_a ) * t;
            end;
          count := count + 1;
          if count = 2 then
            begin
              Result := TRUE;
              goto l_end;
            end;
        end;
    end;
{ begin 4 and 1 }
  if intersection_straight_lines( x_4, y_4, x_1, y_1, x_a, y_a,
                                                      x_b, y_b, t, O ) = 1 then
    begin
      if ( t >= 0 ) and ( t <= 1 ) and ( o >= 0 ) and ( o < 1 ) then
        begin
          if count = 0 then
            begin
              x_a_new := x_a + ( x_b - x_a ) * t;
              y_a_new := y_a + ( y_b - y_a ) * t;
            end
          else
            begin
              x_b_new := x_a + ( x_b - x_a ) * t;
              y_b_new := y_a + ( y_b - y_a ) * t;
            end;
          count := count + 1;
          if count = 2 then
            begin
              Result := TRUE;
              goto l_end;
            end;
        end;
    end;
 l_end: ;
 x_a := x_a_new;
 y_a := y_a_new;
 x_b := x_b_new;
 y_b := y_b_new;
end;

function angle( x_4, y_4, x_c, y_c : double ) : double;
var
  a : double;
begin
    if ( ( (x_4-x_c)=0 ) and ( (y_4-y_c)<0 ) ) then  angle := pi/2
     else
      if ( ( (x_4-x_c)=0 ) and ( (y_4-y_c)>0 ) ) then  angle := 3*pi/2
       else
        if ( ( (x_4-x_c)<0 ) and ( (y_4-y_c)=0 ) ) then  angle := pi
         else
          if ( ( (x_4-x_c)>0 ) and ( (y_4-y_c)=0 ) ) then  angle := 0
           else
             begin
              if x_4-x_c=0 then a:=0 else
               a := arctan( abs( ( y_4 - y_c ) / ( x_4 - x_c ) ) );
               if ( ( (x_4-x_c)<0 ) and ( (y_4-y_c)<0 ) )
                then
                  begin
                    a := arctan( abs( ( x_4 - x_c ) / ( y_4 - y_c ) ) );
                    a := pi/2 + a;
                  end
                else
                 if ( ( (x_4-x_c)<0 ) and ( (y_4-y_c)>0 ) )
                  then  a := pi + a
                  else
                   if ( ( (x_4-x_c)>0 ) and ( (y_4-y_c)>0 ) )
                    then
                      begin
                        a := 2*pi - a;
                      end;
               angle := a;
             end;
end;

function circle( x_c, y_c, r : double; var quants_number : integer ) : TogsCollection;
var
  x1, y1, x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : TogsCollection;
  Alfa, beta, Gamma, a, b : Double;
begin
 res := TogsCollection.create(1);
 x1 := x_c + r;
 y1 := y_c + r;
 x_1 := x_c - r * sqrt( 2 );
 y_1 := y_c - r * sqrt( 2 );
 x_2 := x_c + r * sqrt( 2 );
 y_2 := y_c + r * sqrt( 2 );
 if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then
   begin
     Result := res;
     Quants_Number:=0;
     Exit;
   end;
     alfa := angle( x1, y1, x_c, y_c ) + 3/2 * pi;
     gama := 2*pi;
     gama_quant := gama / quants_number;
     x := x_c + r * sin( -alfa );
     y := y_c + r * cos( -alfa );
     res.Add( TlDot.Create( x, y ) );
     for i := 1 to quants_number do
       begin
         alfa := alfa + gama_quant;
         x := x_c + r * sin( -alfa );
         y := y_c + r * cos( -alfa );
         res.Add( TlDot.Create( x, y ) );
       end;
 Result := res;
end;

function GStrToFloat(S: String): Double;
begin
// Val(S, V, Code);
end;

end.

