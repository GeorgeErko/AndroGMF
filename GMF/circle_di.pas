unit circle_di;

interface
 uses collect, types_dimano, math, maths_basic, System.Types, ogcBasic;

 const eps = 1.0E-3;
 const eps_point_on_circle : double = 1.0E-5;

 function sol_1( r1, xc1, yc1, xa1, ya1, xb1, yb1, r2, xc2, yc2,
                              xa2, ya2, xb2, yb2 : double ) : PCollection;
 function sol_2( x1, y1, x2, y2, r, xc, yc, xa, ya, xb, yb : double ) : PCollection;
 function solving_arc_circle( x1, y1, x2, y2, x3, y3 : double;
                              var x0, y0 : double ) : double;
 procedure arc_inverse( xc, yc, x1, y1, x2, y2 : double; var xcn, ycn : double );
 function segments_square2( xc, yc, x1, y1, x2, y2 : double ) : double;
 function segments_square( XCL, YCL, R, x_a, y_a, x_b, y_b : double;
                           var s : double ) : double;
 procedure parallel_arcs( xc, yc, x1, y1, x2, y2, x0, y0, dr1, dr2 : double;
                          var x11, y11, x21, y21, x12, y12, x22, y22 : double);
 function point_on_circle( xc, yc, r, x, y : double ) : boolean;
 { использует eps_point_on_circle. }
 function arc_Partition( xc, yc, x1, y1, x2, y2, x, y : double; var xp, yp : double ) : boolean;
 function dist_to_arc( xc, yc, xa, ya, xb, yb, x, y : double; var xp, yp : double ) : double;
  function angle( x_4, y_4, x_c, y_c : double ) : double;
  { функция вычисляет угол в правой декартовой системе координат (x,y) с
    центром в точке (x_c,y_c), образованный точкой (x_4,y_4). Угол
    отсчитывается от оси X  по часовой стрелке!}
  procedure r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi : double;
                      var x_rotate, y_rotate : double );
  { процедура поворачивает двухмерную точку на угол fi относительно
    точки (x_0,y_0) по часовой стрелки }
  procedure arc_rotate( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3, y_3, x_4,
                     y_4 : double; var ar1; var quants_number : integer );
  { роцедура поворачивает дугу эллипса, изначально заданного
    параллельным прямоугольником с диаметральнопротивоположными мершинами
    (x_1,y_1) и (x_2,y_2), и точками на элипсе, задающими дугу (x_3,y_3) и
    (x_4,y_4). Поворот происходит на угол fi по часовой стрелке относительно
    точки (x_0,y_0) }

  procedure arc_circle( x_c, y_c, x_3, y_3, x_4, y_4 : double;
                        var ar1; var quants_number : integer );
  { Процедура возвращает дугу окружности в отрезках с центром в точке (x_c,y_c),
    образованную точками (x_3,y_3) и (x_4,y_4) окружности. Причем!!!: в сдучае,
    когда угол между точками (x_3,y_3) и (x_4,y_4) больше 180 градусов,
    процедура меняет точки местами, т.е. она возвращает дугу окружности,
    образрванную точками (x_4,y_4) и (x_3,y_3).!!!!!!!! }
 function arc_circle1( x_c, y_c, r, alfa, beta : double;
                       var quants_number : integer ) : PCollection;
 { Процедура возвращает дугу окружности в отрезках с центром в точке (x_c,y_c),
   радиусом r и образованную углами alfa и beta. }
 function arc_rotate2( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3,
            y_3, x_4, y_4 : double; var quants_number : integer ) : PCollection;
 function arc_rotate3( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3,
            y_3, x_4, y_4 : double; var quants_number : integer ) : TogsCollection;
  { Процедура поворачивает дугу эллипса, изначально заданного
    параллельным прямоугольником с диаметральнопротивоположными мершинами
    (x_1,y_1) и (x_2,y_2), и точками на элипсе, задающими дугу (x_3,y_3) и
    (x_4,y_4). Поворот происходит на угол fi по часовой стрелке относительно
    точки (x_0,y_0) }
 procedure solving_centers_arc( var x_l, y_l, x_r, y_r : double;
                                x_a, y_a, x_b, y_b, r : double );
 { Процедура вычисляет координаты левого и правого центров окружностей,
   которые определяют две точки (x_a,y_a) и (x_b,y_b) через которые должна
   пройти дуга с заданным радиусом r. }
 procedure choice_center_arc_circle( x_0, y_0, x_a, y_a, x_b, y_b, r : double;
                                     var x, y : double );
 { Процедура определяет координаты центра окружности,
   который определяют две точки (x_a,y_a) и (x_b,y_b) через которые должна
   пройти дуга с зоданным радиусом r. Точка (x_0,y_0) выбирает один из двух
   возможных центров. }                                             
 function arc_circle2( x_C, y_c, x1, y1, x2, y2 : double;
                       var quants_number : integer ) : PCollection;          
 { Процедура возвращает дугу окружности в отрезках с центром в точке (x_c,y_c),            
   образованную точками (x_3,y_3) и (x_4,y_4) окружности. В случае, если               
   праметры функции заданы не верно, функция прекращает работу, а значение
   аргумента quants_number оказывается нулевым.}                                      
 function arc_circle3( x_C, y_c, x1, y1, x2, y2 : double;
                       var quants_number : integer ) : PCollection;                         
 { Процедура возвращает дугу окружности в отрезках с центром в точке (x_c,y_c),
   образованную точками (x_3,y_3) и (x_4,y_4) окружности. В случае, если
   праметры функции заданы не верно, функция прекращает работу, а значение
   аргумента quants_number оказывается нулевым.}
 function arc_circle4( x_C, y_c, x1, y1, x2, y2, dr1, dr2, x0, y0 : double;
                       var quants_number : integer; res2 : PCollection ) : PCollection;
 { Процедура возвращает параллельные дуги окружностей в отрезках с центром в
   точке (x_c,y_c), образованную точками (x_3,y_3) и (x_4,y_4) окружности.
   В случае, если праметры функции заданы не верно, функция прекращает работу,
   а значение аргумента quants_number оказывается нулевым. Точка (x0,y0)
   определяет внутренняя или внешняя будет первая дуга. Знак dr2
   может быть отрицательным. }
 procedure middle_point_of_arc_circle( x_c, y_c, x1, y1, x2, y2 : double;
                                       var x, y : double );
 function circle( x_c, y_c, r : double; var quants_number : integer ) : PCollection;
 function circle2( x_c, y_c, x1, y1, r : double; var quants_number : integer ) : PCollection;

implementation uses ogcMathUtils;

function arc_circle1( x_c, y_c, r, alfa, beta : double;
                      var quants_number : integer ) : PCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i : integer;
  res : PCollection;
begin
  res := PCollection.Create(1);
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );                        
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  if ( abs( x_1 - x_2 ) < 1.0E-2 ) or ( abs( y_1 - y_2 ) < 1.0E-2 ) then
    begin
      Quants_Number:=0;
      Result := res;
      Exit
    end;
  if ( alfa < beta ) then gama := beta - alfa
   else gama := 2*pi + beta - alfa;
  if ( alfa = beta) then beta := 2*pi;
  gama_quant := gama / quants_number;
  x := x_c + r * cos( -alfa );
  y := y_c + r * sin( -alfa );
  res.Insert( TDot1.Create( x, y ) );
  for i := 1 to quants_number do
    begin
      alfa := alfa + gama_quant;
      x := x_c + r * cos( -alfa );
      y := y_c + r * sin( -alfa );
      res.Insert( TDot1.Create( x, y ) );
    end;
  Result := res;
end;

procedure solving_centers_arc( var x_l, y_l, x_r, y_r : double;
                               x_a, y_a, x_b, y_b, r : double );
var
    alfa, x, y, gamma, AB : double;
begin
   AB := sqrt( sqr( x_a-x_b ) + sqr( y_a-y_b ) );
   alfa := direct_angle( y_a, x_a, y_b, x_b );
  try
   if abs( 2*r - AB ) > 1.0E-2
    then gamma := ( pi - 2 * arctan( 1 / sqrt( sqr( 2*r / AB ) - 1 ) ) ) / 2
    else gamma := 0;
  except gamma:=0; end;
   x_l := x_a + r * sin( alfa + gamma );
   y_l := y_a + r * cos( alfa + gamma );
   x_r := x_a + r * sin( alfa - gamma );
   y_r := y_a + r * cos( alfa - gamma );
end;

procedure choice_center_arc_circle( x_0, y_0, x_a, y_a, x_b, y_b, r : double;
                                    var x, y : double );
 var
   a, b, c, x_l, y_l, x_r, y_r : double;
 begin
   a := y_b - y_a;
   b := x_a - x_b;
   c := y_a * ( x_b - x_a ) - x_a * ( y_b - y_a );
   solving_centers_arc( x_l, y_l, x_r, y_r, x_a, y_a, x_b, y_b, r );
   if ( a*x_0 + b*y_0 + c ) * ( a*x_l + b*y_l + c ) > 0 then
     begin
       x := x_l;
       y := y_l;
     end
    else
      begin
        x := x_r;
        y := y_r;
      end;
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

procedure r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi : double;
                    var x_rotate, y_rotate : double );
  begin
    x_rotate := ( x_not_rotate - x_0 ) * cos( radian(fi) ) +
                ( y_not_rotate - y_0 ) * sin( radian(fi) ) + x_0;
    y_rotate := -( x_not_rotate-x_0 ) * sin( radian(fi) ) +
                 ( y_not_rotate-y_0 ) * cos( radian(fi) ) + y_0;
  end;

procedure arc_rotate( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3,
        y_3, x_4, y_4 : double; var ar1; var quants_number : integer );
var
  x_c, y_c, a, b, alfa, beta, gama, gama_quant,
  x_rotate, x_not_rotate, y_rotate, y_not_rotate,
  x_4_rotate, y_4_rotate : double;
  i : integer;
  Ar : Array[0..1000] of TPoint absolute Ar1;
begin
   x_c := ( x_2 + x_1 ) / 2;
   y_c := ( y_2 + y_1 ) / 2;
   a := x_c - x_1;
   b := y_c - y_1;
   If ( abs( x_1 - x_2 ) < 1 ) and ( abs( y_1 - y_2 ) < 1  ) then
     begin
       Quants_Number:=0;
       Exit
     end;
       alfa := angle( x_3, y_3, x_c, y_c );
       beta := angle( x_4, y_4, x_c, y_c);
       if ( alfa < beta ) then gama := beta - alfa
        else gama := 2*pi + beta - alfa;
       if ( alfa = beta) then beta := 2*pi;
       gama_quant := gama / quants_number;
       fi := -fi;
       x_not_rotate := x_c + a * cos( -alfa );
       y_not_rotate := y_c + b * sin( -alfa );
       r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi, x_rotate,
                                                           y_rotate );
       ar[0].x := round( x_rotate );
       ar[0].y := round( y_rotate );
       r_rotate( x_4, y_4, x_0, y_0, fi, x_4_rotate, y_4_rotate );
       for i := 1 to quants_number do
         begin
           alfa := alfa + gama_quant;
           x_not_rotate := x_c + a * cos( -alfa );
           y_not_rotate := y_c + b * sin( -alfa );
           r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi,
                                            x_rotate, y_rotate );
           ar[i].x := round( x_rotate );
           ar[i].y := round( y_rotate );
         end;
   fi := -fi;
 end;

procedure arc_circle( x_c, y_c, x_3, y_3, x_4, y_4 : double;
                      var ar1; var quants_number : integer );
var
  alfa, beta, gama, gama_quant,
  x_1, x_2, y_1, y_2, a, b, r, x, y : double;
  i : integer;
  Ar : Array[0..1000] of TPoint absolute Ar1;
begin
   r := sqrt( sqr( (x_c - x_3) ) + sqr( y_c - y_3 ) );
   x_1 := x_c - r * sqrt( 2 );
   y_1 := y_c - r * sqrt( 2 );
   x_2 := x_c + r * sqrt( 2 );
   y_2 := y_c + r * sqrt( 2 );
   if ( abs( x_1 - x_2 ) <= 2 ) or ( abs( y_1 - y_2 ) <= 2 ) then
     begin
       Quants_Number:=0;
       Exit
     end;
       alfa := angle( x_3, y_3, x_c, y_c );
       beta := angle( x_4, y_4, x_c, y_c);
       if ( alfa < beta ) then gama := beta - alfa
        else gama := 2*pi + beta - alfa;
       if ( gama > pi ) then
        begin
          a := x_3;
          b := y_3;
          x_3 := x_4;
          y_3 := y_4;
          x_4 := a;
          y_4 := b;
          alfa := beta;
          gama := -gama + 2*pi;
        end;
       gama_quant := gama / quants_number;
       x := x_c + r * cos( -alfa );
       y := y_c + r * sin( -alfa );
       ar[0].x := round( x );
       ar[0].y := round( y );
       for i := 1 to quants_number do
         begin
           alfa := alfa + gama_quant;
           x := x_c + r * cos( -alfa );
           y := y_c + r * sin( -alfa );
           ar[i].x := round( x );
           ar[i].y := round( y );
         end;
 end;
 
function angle_b( y1, x1, y2, x2, y3, x3 : double) : double;
 var
   a, b : double;
 begin
   a := direct_angle( y1, x1, y2, x2 );
   b := direct_angle( y1, x1, y3, x3 );
   if a > b then Result := 2 * pi - a + b else Result := b - a;
 end;

procedure find_tdot2( xc, yc, r, t, aa, bb, beta, x, y : double; res : PCollection );
 begin
   if point_on_circle( xc, yc, r, x, y ) = false then exit;
   if ( bb < aa )  then
     begin
       if beta < bb then beta := beta + 2*pi;
       bb := bb + 2*pi;
     end;
   if ( t >= 0 ) and ( t <= 1 ) then
     begin
       if ( beta >= aa ) and ( beta <= bb )
        then res.Insert( TDot1.Create( x, y ) );
     end;
 end;

function sol_2( x1, y1, x2, y2, r, xc, yc, xa, ya, xb, yb : double ) : PCollection;
 var
   i, j : integer;
   h, s, p, a2, b2, c2, aa, bb,  a, b, c, x, y, x0, y0, alfa, beta : double;
   t, o, xx, yy : double;
   res : PCollection;
 begin
   res := PCollection.Create(1);
   if ( ( abs( xa - xb ) < 1.0E-10 ) and ( abs( ya - yb ) < 1.0E-10 ) ) or
      ( ( abs( x1 - x2 ) < 1.0E-10 ) and ( abs( y1 - y2 ) < 1.0E-10 ) )
    then begin
           Result := res;
           Exit;
         end;
   aa := direct_angle( yc, xc, ya, xa );
   bb := direct_angle( yc, xc, yb, xb );
   a := y2 - y1;
   b := x1 - x2;
   c := - a * x1 - b * y1;
   h := abs( ( a * xc + b * yc + c ) / sqrt( a*a + b*b ) );
   if h < 1.0E-7 then
     begin
       a := ( x2 - x1 ) / sqrt( sqr( x2 - x1 ) + sqr( y2 - y1 ) );
       b := ( y2 - y1 ) / sqrt( sqr( x2 - x1 ) + sqr( y2 - y1 ) );
       x := xc + r * a;
       y := yc + r * b;
        if abs( x2 - x1 ) > 1.0E-4 then t := ( x - x1 ) / ( x2 - x1 )
         else begin
                t := ( y - y1 ) / ( y2 - y1 );
              end;
       beta := direct_angle( yc, xc, y, x );
       find_tdot2( xc, yc, r, t, aa, bb, beta, x, y, res );
       x := xc - r * a;
       y := yc - r * b;
        if abs( x1 - x2 ) > 1.0E-4 then t := ( x - x1 ) / ( x2 - x1 )
         else begin
                t := ( y - y1 ) / ( y2 - y1 );
              end;
       beta := direct_angle( yc, xc, y, x );
       find_tdot2( xc, yc, r, t, aa, bb, beta, x, y, res );
     end
   else
    if h <= r then
      begin
        alfa := abs( ArcSin( sqrt( r*r - h*h ) / r ) );
        a2 := b;
        b2 := -a;
        c2 := - a2 * xc - b2 * yc;
        beta := angle_b( yc, xc, ya, xa, yb, xb );
        intersection_two_straight_lines( a, b, c, a2, b2, c2, x0, y0 );
        x := xc + r * sin( direct_angle( yc, xc, y0, x0 ) - alfa );
        y := yc + r * cos( direct_angle( yc, xc, y0, x0 ) - alfa );
        if abs( x1 - x2 ) > 1.0E-4 then t := ( x - x1 ) / ( x2 - x1 )
         else begin
                t := ( y - y1 ) / ( y2 - y1 );
              end;
       beta := direct_angle( yc, xc, y, x );
       find_tdot2( xc, yc, r, t, aa, bb, beta, x, y, res );
        x := xc + r * sin( direct_angle( yc, xc, y0, x0 ) + alfa );
        y := yc + r * cos( direct_angle( yc, xc, y0, x0 ) + alfa );
        if abs( x1 - x2 ) > 1.0E-4 then t := ( x - x1 ) / ( x2 - x1 )
         else t := ( y - y1 ) / ( y2 - y1 );
       beta := direct_angle( yc, xc, y, x );
       find_tdot2( xc, yc, r, t, aa, bb, beta, x, y, res );
      end;
   Result := res;
 end;

procedure find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y : double;
                      res : PCollection );
 begin
   if ( point_on_circle( xc1, yc1, r1, x, y ) = false ) or
      ( point_on_circle( xc2, yc2, r2, x, y ) = false ) then exit;
   if ( b1 < a1 )  then
     begin
       if beta1 < b1 then beta1 := beta1 + 2*pi;
       b1 := b1 + 2*pi;
     end;
   if ( b2 < a2 )  then
     begin
       if beta2 < b2 then beta2 := beta2 + 2*pi;
       b2 := b2 + 2*pi;
     end;
   if ( beta1 <= b1 ) and ( beta1 >= a1 ) then
     begin
       if ( beta2 <= b2 ) and ( beta2 >= a2 ) then res.Insert( TDot1.Create( x, y ) );
     end;
 end;

function sol_1( r1, xc1, yc1, xa1, ya1, xb1, yb1, r2, xc2, yc2,
                              xa2, ya2, xb2, yb2 : double ) : PCollection;
 var
   res, c : PCollection;
   i, j : integer;
   d, p, s, alfa, x, y, beta : double;
   a, b, xx, yy : double;
   beta1, alfa1, beta2, a1, b1, a2, b2 : double;
 begin
   res := PCollection.Create(1);
   Result := res;
   d := Distance( xc1, yc1, xc2, yc2 );
   a1 := direct_angle( yc1, xc1, ya1, xa1 );
   b1 := direct_angle( yc1, xc1, yb1, xb1 );
   a2 := direct_angle( yc2, xc2, ya2, xa2 );
   b2 := direct_angle( yc2, xc2, yb2, xb2 );
   c := sol_2( xc1, yc1, xc2, yc2, r1, xc1, yc1, xa1, ya1, xb1, yb1 );
   i := c.Count;
   c.Free;
   c := sol_2( xc1, yc1, xc2, yc2, r2, xc2, yc2, xa2, ya2, xb2, yb2 );
   i := i + c.Count;
   c.Free;
   if i <> 2 then
     begin
       p := ( r1 + r2 + d ) / 2;
       if ( p * ( p - r1 ) * ( p - r2 ) * ( p - d ) ) < 0 then exit;
       s := sqrt( p * ( p - r1 ) * ( p - r2 ) * ( p - d ) );
       If d = 0 then exit;
       If 2 * s / r1 / d > 1 then exit;
       alfa := abs( ArcSin( 2 * s / r1 / d ) );
       alfa1 := pi - alfa;
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) - alfa1 );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) - alfa1 );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) + alfa1 );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) + alfa1 );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
       {}
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) - alfa );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) - alfa );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) + alfa );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) + alfa );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
       {}
     end
   else
     begin
       p := ( r1 + r2 + d ) / 2;
       if ( p * ( p - r1 ) * ( p - r2 ) * ( p - d ) ) < 0 then exit;
       s := sqrt( p * ( p - r1 ) * ( p - r2 ) * ( p - d ) );
       alfa := abs( ArcSin( 2 * s / r1 / d ) );
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) - alfa );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) - alfa );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
       x := xc1 + r1 * sin( direct_angle( yc1, xc1, yc2, xc2 ) + alfa );
       y := yc1 + r1 * cos( direct_angle( yc1, xc1, yc2, xc2 ) + alfa );
       beta1 := direct_angle( yc1, xc1, y, x );
       beta2 := direct_angle( yc2, xc2, y, x );
       find_tdot1( xc1, yc1, r1, xc2, yc2, r2, a1, b1, beta1, a2, b2, beta2, x, y, res );
     end;
 end;

function solving_arc_circle( x1, y1, x2, y2, x3, y3 : double;
                             var x0, y0 : double ) : double;
 var
   r3, xi1, xi2, a : double;
 begin
 {
   if distance( x1, y1, x2, y2 ) < 1.0E-7 then
     some_point_on_arc_circle( x_c, y_c, x1, y1, x2, y2  : double;
                                      var x, y : double );

                                      }
   xi2 := ( x1*x1 + y1*y1 - x3*x3 - y3*y3 ) / 2;
   xi1 := ( x2*x2 + y2*y2 - x3*x3 - y3*y3 ) / 2;
//   writeln('1:',x1,y1);
//   writeln('2:',x2,y2);
//   writeln('3:',x3,y3);
//   writeln(xi1,xi2);

//   writeln(y1 - y3 , ( x1 - x3 ) * ( y2 - y3 ) , ( x2 - x3 ));
   a := y1 - y3 - ( x1 - x3 ) * ( y2 - y3 ) / ( x2 - x3 );
//   writeln('--->', x2 - x3, a );
//   writeln(';lktyrhtlyhlkre');
   y0 := ( xi2 - xi1 * (x1 - x3)/(x2 - x3) ) / a;
//   writeln(';lktyrhtlyhlkre2');
   x0 := ( xi1 - y0 * ( y2 - y3 ) ) / ( x2 - x3 );
//   writeln(';lktyrhtlyhlkre3');
   r3 := sqrt( sqr( x3 - x0 ) + sqr( y3 - y0 ) );
//   writeln(';lktyrhtlyhlkre4');
   Result := r3;
 end;

procedure arc_inverse( xc, yc, x1, y1, x2, y2 : double; var xcn, ycn : double );
 var
   r, xx1, yy1, xx2, yy2 : double;
 begin
   r := sqrt( sqr(x1-xc) + sqr(y1-yc) );
   solving_centers_arc(  xx1, yy1, xx2, yy2, x1, y1, x2, y2, r );
   if sqrt( sqr(xx1-xc) + sqr(yy1-yc) ) < 0.001 then
     begin
       xcn := xx2;
       ycn := yy2;
     end
    else
     begin
       xcn := xx1;
       ycn := yy1;
     end;
 end;

function segments_square2( xc, yc, x1, y1, x2, y2 : double ) : double;
 var
   r, alfa, beta, gama : double;
 begin
   r := sqrt( sqr(x1-xc) + sqr(y1-yc) );
      alfa := angle( x1, y1, xc, yc );
      beta := angle( x2, y2, xc, yc);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
   Result := r*r * ( gama - sin( gama ) ) / 2;
 end;

function arc_Partition( xc, yc, x1, y1, x2, y2, x, y : double; var xp, yp : double ) : boolean;
 var
   xi, gama1, alfa, r, gama, beta, xx, yy : double;
   col : PCollection;
 begin
   r := sqrt( sqr(x1-xc) + sqr(y1-yc) );
   xp := 0;
   yp := 0;
   result := true;
   {
   alfa := angle( x1, y1, xc, yc );
   beta := angle( x2, y2, xc, yc);
   if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
   }
   xi := angle( x, y, xc, yc);
   x := xc + 2 * r * cos( -xi );
   y := yc + 2 * r * sin( -xi );
   col := sol_2( x1, y1, x2, y2, r, xc, yc, x, y, xc, yc );
   if col.Count = 0 then result := false
    else
      begin
        xp := TDot1( col[0] ).x;
        yp := TDot1( col[0] ).y;
      end;
   col.Free;
   {
   if abs( sqr(x-xc) + sqr(y-yc) - r*r ) < eps_point_on_circle then
     begin
       xi := angle( x, y, xc, yc);
       if alfa < xi then gama1 := xi - alfa else gama1 := 2*pi + xi - alfa;
       if gama1 > gama then result := -1
        else
          begin
            xp := x;
            yp := y;
          end;
     end
    else
      begin
        result := 0;
        col := sol_2( x1, y1, x2, y2, r, xc, yc, x, y, xc, yc );
        if col.Count = 0 then result := -1
         else
           begin
             xp := TDot1( col[0] ).x;
             yp := TDot1( col[0] ).y;
           end;
      end;
      }
 end;

procedure parallel_arcs( xc, yc, x1, y1, x2, y2, x0, y0, dr1, dr2 : double;
                         var x11, y11, x21, y21, x12, y12, x22, y22 : double);
 var
   r, r1, r2, Alfa, beta, Gama : Double;
 begin
   r := Distance( xc, yc, x1, y1 );
   if r > Distance( xc, yc, x0, y0 ) then r1 := r - dr1 else r1 := r + dr1;
   alfa := angle( x1, y1, xc, yc );
   beta := angle( x2, y2, xc, yc);
   if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
   x11 := xc + r1 * cos( -alfa );
   y11 := yc + r1 * sin( -alfa );
   alfa := alfa + gama;
   x21 := xc + r1 * cos( -alfa );
   y21 := yc + r1 * sin( -alfa );
   if abs( dr2 ) > 1.0E-3 then
     begin
       alfa := angle( x1, y1, xc, yc );
       beta := angle( x2, y2, xc, yc);
       if dr1 * dr2 < 0 then
          begin
            if r < Distance( xc, yc, x0, y0 ) then r2 := r + dr2
             else r2 := r - dr2;
          end
         else
          begin
            if r < Distance( xc, yc, x0, y0 ) then r2 := r - dr2
             else r2 := r + dr2;
          end;
       x12 := xc + r2 * cos( -alfa );
       y12 := yc + r2 * sin( -alfa );
       alfa := alfa + gama;
       x22 := xc + r2 * cos( -alfa );
       y22 := yc + r2 * sin( -alfa );
     end;
 end;

function point_on_circle( xc, yc, r, x, y : double ) : boolean;
{ использует eps_point_on_circle. }
 begin
   result := false;
   if abs( sqr(x-xc) + sqr(y-yc) - r*r ) < eps_point_on_circle then result := true;
 end;

function dist_to_arc( xc, yc, xa, ya, xb, yb, x, y : double; var xp, yp : double ) : double;
 var
   c : PCollection;
   xi, d, res, r : double;
 begin
   r := sqrt( sqr(xa-xc) + sqr(ya-yc) );
   d := Distance( xc, yc, x, y );
   res := abs( d - r );
   {}
   xp := 0;
   yp := 0;
   xi := angle( x, y, xc, yc);
//   function sol_2( x1, y1, x2, y2, r, xc, yc, xa, ya, xb, yb : double ) :
   x := xc + 2 * r * cos( -xi );
   y := yc + 2 * r * sin( -xi );
   c := sol_2( xc, yc, x, y, r, xc, yc, xa, ya, xb, yb );
   if c.Count = 0 then result := -1
    else
      begin
        xp := TDot1( c[0] ).x;
        yp := TDot1( c[0] ).y;
        result := res;
      end;
   c.Free;
 end;

function arc_circle2( x_c, y_c, x1, y1, x2, y2 : double;
                      var quants_number : integer ) : PCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : PCollection;
  r, Alfa, beta, Gamma, a, b : Double;
begin
  res := PCollection.create(1);
  {
  if abs( Distance( x_c, y_c, x1, y1 ) - Distance( x_c, y_c, x2, y2 ) ) > 1.0E-5
   then begin
          Result := res;
          quants_number := 0;
          Exit;
        end;
        }
  r := Distance( x_c, y_c, x1, y1 );
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then
    begin
      Result := res;
      Quants_Number:=0;
      Exit
    end;
    flag := 0;
    {}
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa
       else begin
              gama := 2*pi + beta - alfa;
              flag := 1;
            end;
      {
      alfa := direct_angle( y1, x1, y_c, x_c ) + 3*pi/2;
      beta := direct_angle( y2, x2, y_c, x_c ) + 3*pi/2;
      if alfa > beta then beta := beta + 2*pi;
      gama := beta - alfa;
      }
      {}
      if ( gama > pi ) then
       begin
         a := x1;
         b := y1;
         x1 := x2;
         y1 := y2;
         x2 := a;
         y2 := b;
         alfa := beta;
         gama := -gama + 2*pi;
       end;
       {}
      gama_quant := gama / quants_number;
      x := x_c + r * cos( -alfa );
      y := y_c + r * sin( -alfa );
      res.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r * cos( -alfa );
          y := y_c + r * sin( -alfa );
          res.Insert( TDot1.Create( x, y ) );
        end;
     {}
   if flag = 1 then
     begin
       res1 := PCollection.create(1);
       for i := res.Count-1 downto 0 do
         res1.Insert( res[i] );
       res.DeleteAll;
       res.Free;
       res := res1;
     end;
     {}
  Result := res;
end;

function arc_rotate2( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3,
        y_3, x_4, y_4 : double; var quants_number : integer ) : PCollection;
var
  x_c, y_c, a, b, alfa, beta, gama, gama_quant,
  x_rotate, x_not_rotate, y_rotate, y_not_rotate,
  x_4_rotate, y_4_rotate, eps : double;
  i : integer;
  res : PCollection;
begin
   res := PCollection.Create(1);
   eps := 1.0E-5;
   x_c := ( x_2 + x_1 ) / 2;
   y_c := ( y_2 + y_1 ) / 2;
   a := x_c - x_1;
   b := y_c - y_1;
   If ( abs( x_1 - x_2 ) < eps ) or ( abs( y_1 - y_2 ) <eps ) then
     begin
       Quants_Number:=0;
       res.Free;
       Result := nil;
       exit;
     end;
       alfa := angle( x_3, y_3, x_c, y_c );
       beta := angle( x_4, y_4, x_c, y_c);
       if ( alfa < beta ) then gama := beta - alfa
        else gama := 2*pi + beta - alfa;
       if ( alfa = beta) then beta := 2*pi;
       gama_quant := gama / quants_number;
       fi := -fi;
       x_not_rotate := x_c + a * cos( -alfa );
       y_not_rotate := y_c + b * sin( -alfa );
       r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi, x_rotate,
                                                           y_rotate );
       res.Insert( TDot1.Create( x_rotate, y_rotate ) );
       r_rotate( x_4, y_4, x_0, y_0, fi, x_4_rotate, y_4_rotate );
       for i := 1 to quants_number do
         begin
           alfa := alfa + gama_quant;
           x_not_rotate := x_c + a * cos( -alfa );
           y_not_rotate := y_c + b * sin( -alfa );
           r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi,
                                            x_rotate, y_rotate );
           res.Insert( TDot1.Create( x_rotate, y_rotate ) );
         end;
   fi := -fi;
   Result := res;
 end;

function arc_rotate3( x_0, y_0, fi, x_1, y_1, x_2, y_2, x_3,
        y_3, x_4, y_4 : double; var quants_number : integer ) : TogsCollection;
var
  x_c, y_c, a, b, alfa, beta, gama, gama_quant,
  x_rotate, x_not_rotate, y_rotate, y_not_rotate,
  x_4_rotate, y_4_rotate, eps : double;
  i : integer;
  res : TogsCollection;
begin
   res := TogsCollection.Create(1);
   eps := 1.0E-5;
   x_c := ( x_2 + x_1 ) / 2;
   y_c := ( y_2 + y_1 ) / 2;
   a := x_c - x_1;
   b := y_c - y_1;
   If ( abs( x_1 - x_2 ) < eps ) or ( abs( y_1 - y_2 ) <eps ) then
     begin
       Quants_Number:=0;
       res.Free;
       Result := nil;
       exit;
     end;
       alfa := angle( x_3, y_3, x_c, y_c );
       beta := angle( x_4, y_4, x_c, y_c);
       if ( alfa < beta ) then gama := beta - alfa
        else gama := 2*pi + beta - alfa;
       if ( alfa = beta) then beta := 2*pi;
       gama_quant := gama / quants_number;
       fi := -fi;
       x_not_rotate := x_c + a * cos( -alfa );
       y_not_rotate := y_c + b * sin( -alfa );
       r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi, x_rotate,
                                                           y_rotate );
       res.Add( TlDot.Create( x_rotate, y_rotate ) );
       r_rotate( x_4, y_4, x_0, y_0, fi, x_4_rotate, y_4_rotate );
       for i := 1 to quants_number do
         begin
           alfa := alfa + gama_quant;
           x_not_rotate := x_c + a * cos( -alfa );
           y_not_rotate := y_c + b * sin( -alfa );
           r_rotate( x_not_rotate, y_not_rotate, x_0, y_0, fi,
                                            x_rotate, y_rotate );
           res.Add( TlDot.Create( x_rotate, y_rotate ) );
         end;
   fi := -fi;
   Result := res;
 end;

function arc_circle3( x_c, y_c, x1, y1, x2, y2 : double;
                      var quants_number : integer ) : PCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : PCollection;
  r, Alfa, beta, Gamma, a, b : Double;
begin
  res := PCollection.create(1);
  r := Distance( x_c, y_c, x1, y1 );
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then
    begin
      Result := res;
      Quants_Number:=0;
      Exit
    end;
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
      gama_quant := gama / quants_number;
      x := x_c + r * cos( -alfa );
      y := y_c + r * sin( -alfa );
      res.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r * cos( -alfa );
          y := y_c + r * sin( -alfa );
          res.Insert( TDot1.Create( x, y ) );
        end;
  Result := res;
end;

function arc_circle4( x_c, y_c, x1, y1, x2, y2, dr1, dr2, x0, y0 : double;
                      var quants_number : integer; res2 : PCollection ) : PCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res : PCollection;
  r, r1, r2, Alfa, beta, Gamma, a, b : Double;
begin
  res := PCollection.create(1);
  r := Distance( x_c, y_c, x1, y1 );
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then
    begin
      Result := res;
      Quants_Number:=0;
      Exit
    end;
  if r < Distance( x_c, y_c, x0, y0 ) then r1 := r - dr1 else r1 := r + dr1;
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
      gama_quant := gama / quants_number;
      x := x_c + r1 * cos( -alfa );
      y := y_c + r1 * sin( -alfa );
      res.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r1 * cos( -alfa );
          y := y_c + r1 * sin( -alfa );
          res.Insert( TDot1.Create( x, y ) );
        end;
  if abs( dr2 ) > 1.0E-3 then
    begin
      if dr1 * dr2 < 0 then
        begin
          if r < Distance( x_c, y_c, x0, y0 ) then r2 := r + dr2
           else r2 := r - dr2;
        end
       else
        begin
          if r < Distance( x_c, y_c, x0, y0 ) then r2 := r - dr2
           else r2 := r + dr2;
        end;
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
      gama_quant := gama / quants_number;
      x := x_c + r2 * cos( -alfa );
      y := y_c + r2 * sin( -alfa );
      res2.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r2 * cos( -alfa );
          y := y_c + r2 * sin( -alfa );
          res2.Insert( TDot1.Create( x, y ) );
        end;
    end;
  Result := res;
end;

function segments_square( XCL, YCL, R, x_a, y_a, x_b, y_b : double;
                          var s : double ) : double;
  var
    i : integer;
    res, phi, a1, a2 : double;
  begin
    phi := angle_between_vectors( XCL, YCL, x_a, y_a,
                                  XCL, YCL, x_b, y_b );
    res := sqr( R ) * ( phi - sin( phi ) ) / 2;
    if phi > pi
     then
       begin
         phi := 2 * pi - phi;
         s := sqr( R ) * ( phi - sin( phi ) ) / 2;
       end
     else s := res;
    Result := res;
  end;

procedure middle_point_of_arc_circle( x_c, y_c, x1, y1, x2, y2 : double;
                                      var x, y : double );
var
  x_1, y_1, x_2, y_2, gama, gama_quant : double;
  i, flag : integer;
  res, res1 : PCollection;
  r, Alfa, beta, Gamma, a, b : Double;
begin
  r := Distance( x_c, y_c, x1, y1 );
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  x := 0;
  y := 0;
  if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then Exit;
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
      alfa := alfa + gama / 2;
      x := x_c + r * cos( -alfa );
      y := y_c + r * sin( -alfa );
end;

procedure some_point_on_arc_circle( x_c, y_c, x1, y1, x2, y2  : double;
                                      var x, y : double );
var
  x_1, y_1, x_2, y_2, gama, gama_quant : double;
  i, flag : integer;
  res, res1 : PCollection;
  r, Alfa, beta, Gamma, a, b : Double;
begin
  r := Distance( x_c, y_c, x1, y1 );
  x_1 := x_c - r * sqrt( 2 );
  y_1 := y_c - r * sqrt( 2 );
  x_2 := x_c + r * sqrt( 2 );
  y_2 := y_c + r * sqrt( 2 );
  x := 0;
  y := 0;
  if ( abs( x_1 - x_2 ) < 1.0E-3 ) or ( abs( y_1 - y_2 ) < 1.0E-3 ) then Exit;
      alfa := angle( x1, y1, x_c, y_c );
      beta := angle( x2, y2, x_c, y_c);
      if alfa < beta then gama := beta - alfa else gama := 2*pi + beta - alfa;
      gamma := pi / 4;
      alfa := alfa + gama / 2;
      x := x_c + r * cos( -alfa );
      y := y_c + r * sin( -alfa );
end;

function circle( x_c, y_c, r : double; var quants_number : integer ) : PCollection;
var
  x1, y1, x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : PCollection;
  Alfa, beta, Gamma, a, b : Double;
begin
// Writeln(1111);
  res := PCollection.create(1);
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
      res.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r * sin( -alfa );
          y := y_c + r * cos( -alfa );
          res.Insert( TDot1.Create( x, y ) );
        end;
  Result := res;
// Writeln(22222);
end;

function circle2( x_c, y_c, x1, y1, r : double; var quants_number : integer ) : PCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : PCollection;
  Alfa, beta, Gamma, a, b : Double;
begin
// Writeln(1111);
  res := PCollection.create(1);
//  x1 := x_c + r;
//  y1 := y_c + r;
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
      alfa := -angle( x1, y1, x_c, y_c ) + 3/2 * pi;
      gama := 2*pi;
      gama_quant := gama / quants_number;
      x := x_c + r * sin( -alfa );
      y := y_c + r * cos( -alfa );
      res.Insert( TDot1.Create( x, y ) );
      for i := 1 to quants_number do
        begin
          alfa := alfa + gama_quant;
          x := x_c + r * sin( -alfa );
          y := y_c + r * cos( -alfa );
          res.Insert( TDot1.Create( x, y ) );
        end;
  Result := res;
// Writeln(22222);
end;

end.
