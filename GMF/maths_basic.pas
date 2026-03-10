unit maths_basic;

interface
 uses Types_Dimano, DSolve, Collect;

 function intersection_two_straight_lines2( a1, b1, c1, a2, b2, c2 : double;
                                            var x, y  : double) : boolean;
 procedure stright_line_transition( x1, y1, x2, y2 : double;
                                    var a, b, c : double );
// function point_parameter_on_straight_lines( x_1, y_1, x_2, y_2, x_a, y_a : double ) : double;
 function angle_between_vectors( x1, y1, x2, y2, xx1, yy1, xx2, yy2 : double ): double;
 function three_points_on_stright( x1, y1, x2, y2, x3, y3 : double ) : boolean;
 function Solve_2equations_SI( f1, f2 : TF; var a, b : double;
   epsilon : double ) : integer;
{ ??? Решение системы двух нелинейных уравнений методом простых итераций. }   
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
 function radian( gradus : double ) : double;
  { ??? функция переводит градусы в радианы... }
 function max( x, y : double ) : double;
 function min( x, y : double ) : double;
 { Функии возвращают максимальное и минимальное число из двух чисел х и у
   соответственно. }
 function Distance( x_i, y_i, x_j, y_j : double ) : double;
 function sign( x : double ) : integer;
 { Функция возвращаят знак величины x. }
 function direct_angle( X1, Y1, X2, Y2 : double ) : double;
 { Функция вычисляет дирекционный угол в левой системе координат (y,x). }
 function intersection_two_straight_lines( a1, b1, c1, a2, b2, c2 : double;
                                           var x, y  : double) : boolean;
 { Функция находит пересечение двух прямых линий заданных общими уравнениями:
     a1 * x + b1 * y + c1 = 0,
     a2 * x + b2 * y + c2 = 0. }
 function chetvert( rad : double ) : integer;
 { Функция возвращает номер четверти (1,2,3 или 4), к которой принадлежит угол.
   Причем, если угол больше, чем 2*pi, то Result := 0. }
 procedure gradus( rad : double; var g, m, s : double; flag : integer );
 procedure gradus1( rad : double; var g, m, s : double; flag : integer );
 { функции перевода радианной меры в градусную, отличающиеся тем, что вторая
   функция возвращает результат, который не может быть больше 360 градусов. }
 function rad( gradus, minuta, sec : double ) : double;
 function rad1( gradus, minuta, sec : double ) : double; // rad1 == -rad.
 { функции перевода градусной меры в радианную, отличающиеся направлением
   отсчета измерения углов.}
 function left_angle( x1, y1, x2, y2, x3, y3 : double ) : double;
 {}
 function Distance3D( x1, y1, z1, x2, y2, z2 : double ) : double;
 { расстояния между 2 точками в 3-х мерном Евклидовом пространстве. }
 function max3( a, b, c : double ) : double;
 function min3( a, b, c : double ) : double;
 { функции нахождения min и max из 3 элементов. }
 function Orientation_of_polygon( polygon : PCollection; var square : double )
  : integer;
 { if Result = 0 then "polygon is not correct"
   if Result = 1 then "polygon is right orientation"
   if Result = -1 then "polygon is left orientation";
   var-double-parametr square is square of the polygon. }
 function lines_intersection( x1, y1, x2, y2, xa, ya, xb, yb : double;
                              var x, y : double ) : boolean;
 function point_on_plane( d1, d2, d3 : T3DPoint; x0, y0 : double; var z : double )
          : boolean;
 function point_and_line( xa, ya, x1, y1, x2, y2 : double ) : double;
 procedure double_transform_sys_coords2D( xa, ya, alfa, x0, y0,
                                   beta, x01, y01 : double; var x, y : double );
 function det3( a11, a12, a13,
                a21, a22, a23,
                a31, a32, a33 : double ) : double;
implementation

function point_and_line( xa, ya, x1, y1, x2, y2 : double ) : double;
 var
   a, b, c : double;
 begin
   stright_line_transition( x1, y1, x2, y2, a, b, c );
   result := - sign( c ) * ( a * xa + b * ya + c ) / sqrt( sqr( a ) + sqr( b ) );
 end;

function power( x, s : double ) : double;
 var res : double;
 begin
   if x > 0 then res := exp( s * ln( x ) ) else res := 0;
   result := res;
 end;

function Orientation_of_polygon( polygon : PCollection; var square : double )
  : integer;
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
            x := TDot1( polygon[0] ).x;                 { X[n] }
            y1 := TDot1( polygon[1] ).y;                {Y[n+1]}
            y_1 := TDot1( polygon[polygon.Count-1] ).y; {Y[n-1]}
          end
        else
         if k = polygon.Count-1 then
           begin
             x := TDot1( polygon[polygon.Count-1] ).x;   { X[n] }
             y1 := TDot1( polygon[0] ).y;                {Y[n+1]}
             y_1 := TDot1( polygon[polygon.Count-2] ).y; {Y[n-1]}
           end
         else
           begin
             x := TDot1( polygon[k] ).x;       { X[n] }
             y1 := TDot1( polygon[k+1] ).y;    {Y[n+1]}
             y_1 := TDot1( polygon[k-1] ).y;   {Y[n-1]}
           end;
        sum := sum + x * ( y1 - y_1 );
      end;
    square := abs( sum / 2 );
    { orientation: }
    if sum > 0 then result := -1 else result := 1;
  end;

function Solve_2equations_SI( f1, f2 : TF; var a, b : double; epsilon : double )
  : integer;
 var
   s, i : integer;
   res_f1, res_f2 : double;
 begin
   i := 0;
   s := 0;
   repeat
     i := i + 1;
     res_f1 := a * a + a;
     res_f2 := b * a + b;
     if ( ( abs( a - res_f1 ) < epsilon ) and
          ( abs( b - res_f2 ) < epsilon ) ) then s := 1;
     a := res_f1;
     b := res_f2;
   until s = 1;
   Result := i;
 end;

function sign( x : double ) : integer;
 begin
   if x = 0 then Result := 0
    else if x > 0 then Result := 1
          else Result := -1;
 end;

function direct_angle( X1, Y1, X2, Y2 : double ) : double;
{ X and Y in left system of coordinates }
 var
   Res, Dy, Dx : double;
 begin
   Dy := Y2 - Y1;
   Dx := X2 - X1;
   If Dx = 0
    then if Dy > 0 then Result := pi/2
                   else Result := 3*pi/2
    else
     If Dy = 0
      then If Dx < 0 then Result := pi
                     else Result := 0
      else
       begin
         Res := Abs( Arctan( Dy/Dx ) );
         if ( ( Dy > 0 ) and ( Dx > 0 ) ) then Result := Res;
         if ( ( DX < 0 ) and ( Dy > 0 ) ) then Result := pi - Res;
         if ( ( Dx < 0 ) and ( Dy < 0 ) ) then Result := pi + Res;
         if ( ( Dx > 0 ) and ( Dy < 0 ) ) then Result := 2*pi - Res;
       end;
 end;

function intersection_two_straight_lines( a1, b1, c1, a2, b2, c2 : double;
                                          var x, y  : double) : boolean;
 var
   a : TMatrica;
   h : TRealCollect;
   cond : double;
 begin
   a := TMatrica.Create(2,2);
   h := TRealCollect.Create(1);
   a[1,1] := a1; a[1,2] := b1;
   a[2,1] := a2; a[2,2] := b2;
   h.insert( TDouble.Create( -c1 ) );
   h.insert( TDouble.Create( -c2 ) );
   if solving_linear_system_by_gauss( a, h, cond ) = TRUE then
     begin
      Result := TRUE;
      x := h[1];
      y := h[2];
     end
    else Result := FALSE;
   h.Free;
   a.Free;
 end;

function Distance( x_i, y_i, x_j, y_j : double ) : double;
  begin Result := sqrt( sqr( x_i - x_j ) + sqr( y_i - y_j ) ) end;

function max( x, y : double ) : double;
  begin
    if x > y then Result := x
     else Result := y;
  end;

function min( x, y : double ) : double;
  begin
    if x < y then Result := x
     else Result := y;
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

function radian( gradus : double ) : double;
  begin  radian := pi * gradus / 180;   end;

function chetvert( rad : double ) : integer;
 begin
   if rad > 2*pi then
     begin
       Result := 0;
       Exit;
     end;
   if ( rad >=0 ) and ( rad <= pi/2 ) then
     begin
       Result := 1;
       Exit;
     end;
   if ( rad > pi/2 ) and ( rad <= pi ) then
     begin
       Result := 2;
       Exit;
     end;
   if ( rad >pi ) and ( rad <= 3*pi/2 ) then
     begin
       Result := 3;
       Exit;
     end;
   if ( rad > 3*pi/2 ) and ( rad <= pi*2 ) then
     begin
       Result := 4;
       Exit;
     end;
 end;

function rad( gradus, minuta, sec : double ) : double;
 var
   rad0, g, m, s : double;
 begin
   g := pi * gradus / 180;
   m := pi * minuta / 60 / 180;
   s := pi * sec / 3600 / 180;
   rad0 :=  g + m + s;
   Result := -rad0;
 end;

function rad1( gradus, minuta, sec : double ) : double;
 var
   rad, g, m, s : double;
 begin
   g := pi * gradus / 180;
   m := pi * minuta / 60 / 180;
   s := pi * sec / 3600 / 180;
   rad :=  g + m + s;
   Result := rad;
 end;

procedure gradus( rad : double; var g, m, s : double; flag : integer );
 var
   t, f : double;
 begin
   g := 0;   m := 0;   s := 0;
   g := 180 * rad / pi;
   f := frac( g );
   g := trunc( g );
   m := 60 * f;
       if (round(m * 100000) = 60 * 100000 ) and ( flag <> 1) then
         begin
           g := g + 1;
           m := 0;
         end;

   if flag = 1 then
     begin
       f := frac( m );
       m := trunc( m );
       s := 60 * f;
       s := round( s);
       if s = 60 then
         begin
           m := m + 1;
           s := 0;
         end;
       if m = 60 then
         begin
           g := g + 1;
           m := 0;
         end;
     end;
 end;

procedure gradus1( rad : double; var g, m, s : double; flag : integer );
 var
   t, f : double;
 begin
   if abs( rad ) > pi then
     begin
       if rad < 0 then repeat rad := rad + 2*pi; until rad > -pi
        else repeat rad := rad - 2*pi; until rad < pi;
     end;
   g := 0;   m := 0;   s := 0;
   g := 180 * rad / pi;
   f := frac( g );
   g := trunc( g );
   m := 60 * f;
   if flag = 1 then
     begin
       f := frac( m );
       m := trunc( m );
       if m = 60 then
         begin
           g := g + 1;
           m := 0;
         end;
       s := 60 * f;
       s := round( s );
       if s = 60 then
         begin
           m := m + 1;
           s := 0;
         end;
     end;
 end;

function left_angle( x1, y1, x2, y2, x3, y3 : double ) : double;
 var
   a, b, res : double;
 begin
   res := 0;
   a := direct_angle( y2, x2, y1, x1 );
   b := direct_angle( y2, x2, y3, x3 );
   if b > a then res := b - a else res := 2*pi - a + b;
   res := 2*pi - res; { right system choordinates !!! }
   Result := res;
 end;


function Distance3D( x1, y1, z1, x2, y2, z2 : double ) : double;
 begin Result := sqrt( sqr(x1-x2) + sqr(y1-y2) + sqr(z1-z2) ); end;

function max3( a, b, c : double ) : double;
 var res : double;
 begin
   res := a;
   if res < b then res := b;
   if res < c then res := c;
   Result := res;
 end;

function min3( a, b, c : double ) : double;
 var res : double;
 begin
   res := a;
   if res > b then res := b;
   if res > c then res := c;
   Result := res;
 end;

function three_points_on_stright( x1, y1, x2, y2, x3, y3 : double ) : boolean;
 begin
   result := false;
   if abs( x2*y3 - y2*x3 - x1*y3 + y1*x3 + x1*y2 - y1*x2 ) < 1.0E-5
    then result := true;
 end;

function intersection_two_straight_lines2( a1, b1, c1, a2, b2, c2 : double;
                                          var x, y  : double) : boolean;
 var
   d : double;
 begin
   result := false;
   d := a1 * b2 - a2 * b1;
   if abs( d ) > 1.0E-10 then
     begin
       x := ( c2 * b1 - b2 * c1 ) / d;
       y := ( c1 * a2 - c2 * a1 ) / d;
       result := true;
     end;
 end;

procedure stright_line_transition( x1, y1, x2, y2 : double;
                                   var a, b, c : double );
 begin
   a := y2 - y1;
   b := x1 - x2;
   c := - y1 * b - x1 * a;
 end;

function angle_between_vectors( x1, y1, x2, y2, xx1, yy1, xx2, yy2 : double )
  : double;
  var
    alfa, betta, res : double;
  begin
    alfa := direct_angle( y1, x1, y2, x2 );
    betta := direct_angle( yy1, xx1, yy2, xx2 );
    res := betta - alfa;
    Result := abs( res );
  end;

function lines_intersection( x1, y1, x2, y2, xa, ya, xb, yb : double;
                             var x, y : double ) : boolean;
 var
   a1, b1, c1, a2, b2, c2 : double;
 begin
   stright_line_transition( x1, y1, x2, y2, a1, b1, c1 );
   stright_line_transition( xa, ya, xb, yb, a2, b2, c2 );
   result := intersection_two_straight_lines2( a1, b1, c1, a2, b2, c2, x, y  );
 end;

 (*
function point_parameter_on_straight_lines( x_1, y_1, x_2, y_2,
                                            x_a, y_a : double ) : double;
  var
    a_11, a_12, a_21, a_22, b_1, b_2, t : double;
  begin
    t := 0;
    a_11 := x_2 - x_1;
    a_12 := x_a - x_b;
    b_1 := x_a - x_1;
    b_2 := y_a - y_1;
    if abs( a_11 ) > 1.0E-7 then t := b_1 / a_11 else t := b_2 / a_21;
    Result := t;
  end;
//   *)

function point_on_plane( d1, d2, d3 : T3DPoint; x0, y0 : double; var z : double )
: boolean;
var
   z1, z2, z3, x1, x2, x3, y1, y2, y3, delta, delta1, delta2, delta3 : double;
begin
   result := true;
   z := 0;
   x1 := d1.x;
   y1 := d1.y;
   z1 := d1.z;
   x2 := d2.x;
   y2 := d2.y;
   z2 := d2.z;
   x3 := d3.x;
   y3 := d3.y;
   z3 := d3.z;
   delta := x1 * ( y2*z3 - z2*y3 ) - y1 * ( x2*z3 - z2 *x3 ) + z1 * ( x2*y3 - y2*x3 );
   delta1 := y2*z3 - z2*y3 - y1*z3 + z1*y3 + y1*z2 - z1*y2;
   delta2 := z2*x3 - x2*z3 - z1*x3 + x1*z3 + z1*x2 - x1*z2;
   delta3 := -y2*x3 + x2*y3 + y1*x3 - x1*y3 - y1*x2 + x1*y2;
   if abs( delta ) < 1.0E-8 then
     begin
       result := false;
       z := 0;
     end
    else z := ( delta - x0 * delta1 - y0 * delta2 ) / delta3;
end;

{ vozvrashaet koordinaty tochki a (x,y) v ishodnoy sisteme koordinat, esli
tochka a imeet koordinaty (xa,ya) v nekotoroy sisteme koordinat, kotoraya
povernuta na ugol alfa i imeet nachalo koordinat v tochke (x0,y0) otnositelno
ishodnoy sistemy koordinat.
ugol povorota otschityvaetsya protiv chasovoy strelki.}
procedure transform_sys_coords2D( xa, ya, alfa, x0, y0 : double;
                                  var x, y : double );
begin
  x := x0 + xa * cos( alfa ) - ya * sin( alfa );
  y := y0 + xa * sin( alfa ) + ya * cos( alfa );
end;
procedure transform_sys_coords2D1( xa, ya, alfa, x0, y0 : double;
                                  var x, y : double );
begin
  x := x0 + xa * cos( alfa ) - ya * sin( alfa );
  y := y0 + xa * sin( alfa ) + ya * cos( alfa );
end;

procedure double_transform_sys_coords2D( xa, ya, alfa, x0, y0,
                                   beta, x01, y01 : double; var x, y : double );
var
  x1, y1, y2, x2, x3, y3, y4, x4 : double;
begin
  transform_sys_coords2D( xa, ya, alfa, x0, y0, x1, y1 );
  transform_sys_coords2D( x1, y1, beta, x01, y01, x, y );
end;

function det3( a11, a12, a13,
               a21, a22, a23,
               a31, a32, a33 : double ) : double;
begin
  result := a11 * a22 * a33 - a11 * a32 * a23 - a12 * a21 * a33 + a12 * a23 * a31 + a13 * a21 * a32 - a13 * a22 * a31;
end;

end.
