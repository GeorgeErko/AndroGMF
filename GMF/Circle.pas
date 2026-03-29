unit circle;

interface
 uses collect, types_dimano, math, maths_basic, circle_di;
 function intersection_2_circles( xa, ya, r1, xb, yb, r2 : double ) : PCollection;
 function sol_3( xc1, yc1, r1, xc, yc, r, xa, ya, xb, yb : double ) : PCollection;
 function sol_4( xc1, yc1, r1, x1, y1, x2, y2 : double ) : PCollection;

implementation

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

function intersection_2_circles( xa, ya, r1, xb, yb, r2 : double ) : PCollection;
 var
   x, y, bb, delta, beta, d3, alfa, a, b, x1, y1, x2, y2, d1, d2, c : double;
   res : PCollection;
 begin
   res := PCollection.Create(1);
   result := res;
   a := r1;
   b := r2;
   d1 := -( Power(xa - xb,2)*( -Power(a - b,2) + Power(xa - xb,2) + Power(ya - yb,2) ) *
             (-Power(a + b,2) + Power(xa - xb,2) + Power(ya - yb,2)
             ) );
   if d1 < 0 then exit;
   x1 := ((xa - xb)*(Power(b,2)*(xa - xb) + Power(a,2)*(-xa + xb) + (xa + xb)*(Power(xa - xb,2) + Power(ya - yb,2))) +
        Sqrt( d1 )*(ya - yb))/
      (2.*(xa - xb)*(Power(xa - xb,2) + Power(ya - yb,2) ) );
   y1 := (-Sqrt( d1 )
      + Power(b,2)*(ya - yb) + Power(a,2)*(-ya + yb) +
           (Power(xa - xb,2) + Power(ya - yb,2))*(ya + yb))/(2.*(Power(xa - xb,2) + Power(ya - yb,2)) );
   x2 := ((xa - xb)*(Power(b,2)*(xa - xb) + Power(a,2)*(-xa + xb) + (xa + xb)*(Power(xa - xb,2) + Power(ya - yb,2))) +
           Sqrt( d1 )*(-ya + yb))/
         (2.*(xa - xb)*(Power(xa - xb,2) + Power(ya - yb,2) ) );
   y2 := (Sqrt( d1 ) + Power(b,2)*(ya - yb) + Power(a,2)*(-ya + yb) +
           (Power(xa - xb,2) + Power(ya - yb,2))*(ya + yb))/(2.*(Power(xa - xb,2) + Power(ya - yb,2)));
   res.Insert( TDot1.Create( x1, y1 ) );
   res.Insert( TDot1.Create( x2, y2 ) );
 end;

function intersection_line_and_circle( xa, ya, r, a1, b1, c : double ) : PCollection;
 var
   x, y, bb, delta, beta, d3, alfa, x1, y1, x2, y2, d1, d2 : double;
   res : PCollection;
 begin
   res := PCollection.Create(1);
   result := res;
   if abs( a1 ) > 1.0E-7 then
     begin
       d1 := Power(a1,2)*( ( Power(a1,2) + Power(b1,2) )*Power(r,2) -
                           Power(c + a1*xa + b1*ya,2) );
       if d1 < 0 then exit;
       x1 := ( a1*Power(b1,2)*xa - Power(a1,2)*(c + b1*ya) -
               b1*Sqrt( d1 ) ) /
                  ( a1*( Power(a1,2) + Power(b1,2) ) );
       y1 := (-(b1*(c + a1*xa)) + Power(a1,2)*ya +
              Sqrt( d1 ))/(Power(a1,2) + Power(b1,2) );
       x2 :=  ( a1*Power(b1,2)*xa - Power(a1,2)*(c + b1*ya) +
            b1*Sqrt( D1 ))/(a1*(Power(a1,2) + Power(b1,2) ) );
       y2 := -( (b1*(c + a1*xa) - Power(a1,2)*ya + Sqrt( d1 )) /
        (Power(a1,2) + Power(b1,2) ) );
       res.Insert( TDot1.Create( x1, y1 ) );
       res.Insert( TDot1.Create( x2, y2 ) );
     end
    else
      begin
       d1 := (-c - b1*(-r + ya))*(c + b1*(r + ya));
       if d1 < 0 then exit;
       y := - c / b1;
       x1 := xa - Sqrt( d1 ) / b1;
       x2 := xa + Sqrt( d1 ) / b1;
       res.Insert( TDot1.Create( x1, y ) );
       res.Insert( TDot1.Create( x2, y ) );
      end;
 end;

function sol_3( xc1, yc1, r1, xc, yc, r, xa, ya, xb, yb : double ) : PCollection;
//function sol_2( x1, y1, x2, y2, r, xc, yc, xa, ya, xb, yb : double ) : PCollection;
 var
   i, j : integer;
   a2, b2, c2, aa, bb,  a, b, c, x, y, x0, y0, alfa, beta : double;
   t, o, xx, yy : double;
   res, col : PCollection;
   p : TDot1;
 begin
   res := PCollection.Create(1);
   result := res;
   aa := direct_angle( yc, xc, ya, xa );
   bb := direct_angle( yc, xc, yb, xb );
   col := intersection_2_circles( xc1, yc1, r1, xc, yc, r );
   for i := 0 to col.Count-1 do
     begin
       p := col[i];
       x := p.x;
       y := p.y;
       beta := direct_angle( yc, xc, y, x );
       find_tdot2( xc, yc, r, 0.5, aa, bb, beta, x, y, res );
     end;
 end;

function sol_4( xc1, yc1, r1, x1, y1, x2, y2 : double ) : PCollection;
 var
   i, j : integer;
   a2, b2, c2, aa, bb,  a, b, c, x, y, x0, y0, alfa, beta : double;
   t, h, o, xx, yy : double;
   res, col : PCollection;
   p : TDot1;
 begin
   res := PCollection.Create(1);
   result := res;
   a := y2 - y1;
   b := x1 - x2;
   c := - a * x1 - b * y1;
   h := abs( ( a * xc1 + b * yc1 + c ) / sqrt( a*a + b*b ) );
   col := intersection_line_and_circle( xc1, yc1, r1, a, b, c );
   for i := 0 to col.Count-1 do
    begin
      p := col[i];
      x := p.x;
      y := p.y;
      if abs( x1 - x2 ) > 1.0E-4 then t := ( x - x1 ) / ( x2 - x1 )
       else t := ( y - y1 ) / ( y2 - y1 );
      find_tdot2( xc1, yc1, r1, t, 1, 3, 2, x, y, res );
    end;
 end;

end.
