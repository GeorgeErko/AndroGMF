unit Intervals;

interface uses collect, types_dimano, types2, Sysutils, maths_basic;

 procedure clip_intervals_xxx( x_1, y_1, x_3, y_3 : double; var x_a, y_a, x_b, y_b : double);
  { ??? использовалась в Ver25  под  Dlphi3  на моей машине  в модуле Selector. }
(* ===================================>>>>>>>>>>>>>>>>>>>>
  procedure intersection_intervals( x_1, y_1, x_2, y_2, x_3, y_3,  x_4, y_4,
                                    x_a, y_a, x_b, y_b : double;
                                    var x, y : double );
  procedure clip_intervals( x_1, y_1, x_3, y_3 : double;
                            var x_a, y_a, x_b, y_b : double);
  { Процедура пересечения отрезка (x_a,y_a),(x_b,y_b) с параллельным
    прямоугольником с диаметральнопротивоположными мершинами (x_1,y_1) и
    (x_2,y_2). Если отрезок не пересекается с прямоугольником, то
    процедура возвращает тот же отрезок. }
<<<<<<<<<<<<<<<<<<<<<,===================================*)
 function intersection_two_intervals( x1, y1, x2, y2, xa, ya, xb, yb : double ): PCollection;
 function clip_two_intervals( x1, y1, x2, y2, xa, ya, xb, yb : double ) : PCollection;
 function angle_between_edges( e1, e2 : TEdge ) : double;
 { ??? Функция вычисляет угол между двумя ребрами. }
 function equality_of_edges( e1, e2 : TEdge; eps : double ) : boolean;
 { ??? Функция определяющая являются ли тождественными два ребра. }
 function point_on_edge( x, y : double; edge : TEdge ) : boolean;
 { ??? Функция определяет принадлежит ли точка ребру. }
 function clip_interval( x_1, y_1, x_3, y_3 : double;
                         var x_a, y_a, x_b, y_b : double) : boolean;
 { отсечение отрезка прямоугольником. }

implementation

function angle_between_edges( e1, e2 : TEdge ) : double;
  var
    alfa, betta, res : double;
  begin
    alfa := direct_angle( e1.y2, e1.x2, e1.y1, e1.x1 );
    betta := direct_angle( e2.y1, e2.x1, e2.y2, e2.x2 );
    res := betta - alfa;
    if res < 0 then res := 2*pi + res;
    Result := res;
  end;

function equality_of_edges( e1, e2 : TEdge; eps : double ) : boolean;
  begin
    Result := FALSE;
    if abs( e1.x1 - e2.x1 ) < eps then if abs( e1.y1 - e2.y1 ) < eps then
     if abs( e1.x2 - e2.x2 ) < eps then if abs( e1.y2 - e2.y2 ) < eps
       then begin
              Result := TRUE;
              Exit;
            end;
    if abs( e1.x1 - e2.x2 ) < eps then if abs( e1.y1 - e2.y2 ) < eps then
     if abs( e1.x2 - e2.x1 ) < eps then if abs( e1.y2 - e2.y1 ) < eps
       then begin
              Result := TRUE;
              Exit;
            end;
  end;

function point_on_edge( x, y : double; edge : TEdge ) : boolean;
const Const_Of_DecimalCoord = 3;
 var
   i : integer;
   t, eps : double;
 begin
   Result := FALSE;
   if (Trunc( (edge.x1 - edge.x2)*Const_Of_DecimalCoord )=0) and (Trunc(( edge.y1 - edge.y2 )*Const_Of_DecimalCoord)=0) then Exit;
   eps := 1.0E-5;
   t := 0;
   if abs( ( x - edge.x2 ) * ( edge.y1- edge.y2 ) -
           ( y - edge.y2 ) * ( edge.x1 - edge.x2 ) ) < eps
    then begin
           Result := TRUE;
           if abs( edge.y1 - edge.y2 ) < eps
            then t := ( x - edge.x2 ) / ( edge.x1 - edge.x2 )
            else t := ( y - edge.y2 ) / ( edge.y1 - edge.y2 );
         end;
   if ( Round(t*1000) < 0 ) or ( Round(t*1000) > 1000 ) then Result := FALSE;
 end;

function intersection_two_intervals( x1, y1, x2, y2, xa, ya, xb, yb : double )
 : PCollection;
 var
   i : integer;
   res : PCollection;
   x, y : double;
 begin
   res := PCollection.Create(1);
   Result := res;
   if ( Distance(x1, y1, x2, y2 ) < 1.0E-7 ) or
      ( Distance(xa, ya, xb, yb ) < 1.0E-7 ) then Exit; // ?????????????????
   if abs( x1-x2 ) > 1.0E-2 then
     begin
       if x1 > x2 then
         begin
           x := x1;       y := y1;
           x1 := x2;      y1 := y2;
           x2 := x;       y2 := y;
         end;
       if xa > xb then
         begin
           x := xa;       y := ya;
           xa := xb;      ya := yb;
           xb := x;       yb := y;
         end;
       if ( x2 < xa ) or ( xa > x1 ) then Exit;
       if ( x2 > xb ) or ( x1 > xa ) then Exit;
       {}
       if ( x2 <= xb ) and ( x1 <= xb ) and ( x2 >= xa ) and ( x1 >= xa ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( xb <= x2 ) and ( xa <= x2 ) and ( xa >= x1 ) and ( xb >= x1 ) then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       { good }
       if ( x1 < xb ) and ( xb < x2 ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       if ( xa < x2 ) and ( x2 < xb ) then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {???????????????}
       if abs( xb-x1 ) < 1.0E-7 then
         begin
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       if abs( xa-x2 ) < 1.0E-7 then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           Exit;
         end;
     end
   else { if... }
     begin
       if y1 > y2 then
         begin
           x := x1;       y := y1;
           x1 := x2;      y1 := y2;
           x2 := x;       y2 := y;
         end;
       if ya > yb then
         begin
           x := xa;       y := ya;
           xa := xb;      ya := yb;
           xb := x;       yb := y;
         end;
       if ( y2 < ya ) or ( ya > y1 ) then Exit;
       if ( y2 > yb ) or ( y1 > ya ) then Exit;
       {}
       if ( y2 <= yb ) and ( y1 <= yb ) and ( y2 >= ya ) and ( y1 >= ya ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( yb <= y2 ) and ( ya <= y2 ) and ( ya >= y1 ) and ( yb >= y1 ) then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       { good }
       if ( y1 < yb ) and ( yb < y2 ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       if ( ya < y2 ) and ( y2 < yb ) then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if abs( yb-y1 ) < 1.0E-7 then
         begin
           res.Insert( TDot1.Create( xb, yb ) );
           Exit;
         end;
       if abs( ya-y2 ) < 1.0E-7 then
         begin
           res.Insert( TDot1.Create( xa, ya ) );
           Exit;
         end;
     end;
 end;

function clip_two_intervals( x1, y1, x2, y2, xa, ya, xb, yb : double ) : PCollection;
 var
   i : integer;
   res : PCollection;
   x, y : double;
 begin
   res := PCollection.Create(1);
   Result := res;
   if ( Distance(x1, y1, x2, y2 ) < 1.0E-5 ) or
      ( Distance(xa, ya, xb, yb ) < 1.0E-5 ) then Exit; // ?????????????????
   if abs( x1-x2 ) > 1.0E-2 then
     begin
       if x1 > x2 then
         begin
           x := x1;       y := y1;
           x1 := x2;      y1 := y2;
           x2 := x;       y2 := y;
         end;
       if xa > xb then
         begin
           x := xa;       y := ya;
           xa := xb;      ya := yb;
           xb := x;       yb := y;
         end;
       if ( x2 <= xb ) and ( x1 <= xb ) and ( x2 >= xa ) and ( x1 >= xa ) then
         begin
           Exit;
         end;
       if ( x2 <= xa ) and ( x1 <= xa ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( x2 >= xb ) and ( x1 >= xb ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( xb <= x2 ) and ( xa <= x2 ) and ( xa >= x1 ) and ( xb >= x1 ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( xb, yb ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       { good }
       if ( x2 >= xb ) and ( x1 >= xa ) then
         begin
           res.Insert( TDot1.Create( xb, yb ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       if ( x1 <= xa ) and ( x2 <= xb ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xa, ya ) );
           Exit;
         end;
     end
   else { if... }
     begin
       if y1 > y2 then
         begin
           x := x1;       y := y1;
           x1 := x2;      y1 := y2;
           x2 := x;       y2 := y;
         end;
       if ya > yb then
         begin
           x := xa;       y := ya;
           xa := xb;      ya := yb;
           xb := x;       yb := y;
         end;
       if ( y2 <= yb ) and ( y1 <= yb ) and ( y2 >= ya ) and ( y1 >= ya ) then Exit;
       if ( y2 <= ya ) and ( y1 <= ya ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( y2 >= yb ) and ( y1 >= yb ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       {}
       if ( yb <= y2 ) and ( ya <= y2 ) and ( ya >= y1 ) and ( yb >= y1 ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xa, ya ) );
           res.Insert( TDot1.Create( xb, yb ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       { good }
       if ( y2 >= yb ) and ( y1 >= ya ) then
         begin
           res.Insert( TDot1.Create( xb, yb ) );
           res.Insert( TDot1.Create( x2, y2 ) );
           Exit;
         end;
       if ( y1 <= ya ) and ( y2 <= yb ) then
         begin
           res.Insert( TDot1.Create( x1, y1 ) );
           res.Insert( TDot1.Create( xa, ya ) );
           Exit;
         end;
     end;
 end;

procedure intersection_intervals( x_1, y_1, x_2, y_2, x_3, y_3,  x_4, y_4,
                                  x_a, y_a, x_b, y_b : double;
                                  var x, y : double );
  var
    t, O : double;
  begin

    if ( ( intersection_straight_lines( x_1, y_1, x_2, y_2, x_a, y_a,
          x_b, y_b, t, O ) = 1 ) and ( t >= 0 ) and ( t <= 1 ) and
         ( O >= 0 ) and ( O <= 1 ) )
     then
       begin
         x := x_a + ( x_b - x_a ) * t;
         y := y_a + ( y_b - y_a ) * t
       end
     else
       if ( ( intersection_straight_lines( x_2, y_2, x_3, y_3, x_a, y_a,
          x_b, y_b, t, O ) = 1 ) and ( t >= 0 ) and ( t <= 1 ) and
          ( O >= 0 ) and ( O <= 1 ) )
        then
          begin
            x := x_a + ( x_b - x_a ) * t;
            y := y_a + ( y_b - y_a ) * t
          end
        else
          if ( ( intersection_straight_lines( x_3, y_3, x_4, y_4, x_a, y_a,
             x_b, y_b, t, O ) = 1 ) and ( t >= 0 ) and ( t <= 1 )
             and ( O <= 1 ) and ( O >= 0 ) )
           then
             begin
               x := x_a + ( x_b - x_a ) * t;
               y := y_a + ( y_b - y_a ) * t;
             end
           else
             if ( ( intersection_straight_lines( x_4, y_4, x_1, y_1, x_a, y_a,
                     x_b, y_b, t, O ) = 1 ) and ( t >= 0 ) and ( t <= 1 )
                     and ( O <= 1 ) and ( O >= 0 ) )
              then
                begin
                  x := x_a + ( x_b - x_a ) * t;
                  y := y_a + ( y_b - y_a ) * t
                end;
  end;

procedure clip_intervals_xxx( x_1, y_1, x_3, y_3 : double;
                          var x_a, y_a, x_b, y_b : double);
  var
    x_2, y_2, x_4, y_4, x_a_new, x_b_new, y_a_new, y_b_new : double;
  begin
    x_2 := x_3;
    y_2 := y_1;
    x_4 := x_1;
    y_4 := y_3;
    x_a_new := x_a;
    x_b_new := x_b;
    y_a_new := y_a;
    y_b_new := y_b;
    if ( ( x_a - x_1 > 1.0E-5 ) and ( x_a < x_3 ) and ( y_a - y_1 > 1.0E-5 ) and
         ( y_a < y_3 ) )
     then intersection_intervals( x_1, y_1, x_2, y_2, x_3, y_3, x_4, y_4,
                                            x_a, y_a, x_b, y_b, x_b, y_b )
     else
       if ( ( x_b - x_1 > 1.0E-5) and ( x_b < x_3 ) and ( y_b - y_1 > 1.0E-5 ) and
            ( y_b < y_3 ) )
        then intersection_intervals( x_1, y_1, x_2, y_2, x_3, y_3, x_4, y_4,
                                               x_a, y_a, x_b, y_b, x_a, y_a )
        else
          begin
            intersection_intervals( x_1, y_1, x_2, y_2, x_3, y_3, x_4, y_4,
                                     x_a, y_a, x_b, y_b, x_a_new, y_a_new );
            if  ( ABS( x_a_new - x_1 ) < 1.0E-5 ) and
                ( ABS( y_a_new - y_1 ) < 1.0E-5 )
             then intersection_intervals( x_2, y_2, x_3, y_3, x_4, y_4, x_1,
                                          y_1, x_a, y_a, x_b, y_b, x_b_new,
                                          y_b_new )
             else intersection_intervals( x_1, y_1, x_4, y_4, x_3, y_3, x_2,
                                          y_2, x_a, y_a, x_b, y_b, x_b_new,
                                          y_b_new );
            x_a := x_a_new;
            y_a := y_a_new;
            x_b := x_b_new;
            y_b := y_b_new;
          end;
  end;

function clip_interval( x_1, y_1, x_3, y_3 : double;
                        var x_a, y_a, x_b, y_b : double) : boolean;
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

end.
