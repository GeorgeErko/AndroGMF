unit polygons;
interface
 uses collect, types_Dimano, types2, intervals, math, maths_basic {,
 red_lines_types};

{ function intersection_interval_and_polygon2( polygon, p1 : PCollection;
                                  x1, y1, x2, y2 : double ) : PCollection;
--    Unknown.}
 function point_on_quasipolygon_border( x, y : double; xx : PCollection;
        var j : integer ) : boolean;
 { Функция определяет принадлежит ли точка границе многоугольника, точки
   которого имеют третью координату (высоту), и возвращает номер вершины после
   которой располагается данная точка. }
 function polygon_triangulations( pol : PCollection ) : PCollection;
 function intersection_interval_and_polygon( polygon : PCollection;
                                  x1, y1, x2, y2 : double ) : PCollection;
 { Функция пересечения отрезка (x_1,y_1),(x_2,y_2) с многоугольником. }
 function intervals_of_intersection_two_polygons( Polygon1,
        Polygon2 : PCollection ) : PCollection;
 function intersection_two_polygons( polygon1, polygon2 : PCollection ) : PCollection;
 { Функция пересечения двух многоугольников. }
 function point_and_polygon( x, y : double; p : PCollection ) : integer;
 { Функция вычисляет отношение точки и многоугольника:
   -1 точка вне многоугольника,
    0 точка на границе,
    1 точка в многоугольнике. }
 function assembly_polygon_from_segments( segments : PCollection ) : PCollection;
 { ??? Функция собирает из коллекции ребер многоугольники. }
 function assembly_polygons( tp : TConnectionPoints ) : TConnectionPolygons2;
 function CuttingOff_polygon_by_polygon( polygon1, polygon2 : PCollection )
  : PCollection;
 function equality_two_polygons( pol1, pol2 : PCollection ) : boolean;
 function polygon_in_polygon( p1, p2 : PCollection ) : integer;
   { result = 0 ==> p1 and p2 can be intersected
              1 ==> p1 belongs p2
              2 ==> p1 completely covers p2.  }
{ ne dokontsa protestirovan !!! }
 function polygon_out_polygon( p1, p2 : PCollection ) : integer;
   { result = 0 ==> p1 and p2 can be intersected
              1 or 2 (!!!) ==> p1 outside of p2.  }
{ ne dokontsa protestirovan !!! }
 function point_inside_polygon( x, y : double; p : PCollection ) : integer;
 function point_inside_polygon2( x, y, xmax, ymax, xmin, ymin : double;
                                 p : PCollection ) : integer;
 { Функции point_inside_polygon и point_inside_polygon2 отличаются от функции
   point_аnd_polygon тем, что анализируется, что находится ли точка (x,y) вне
   прямоугольника, охватывающего полигон. }
 function Shading_of_polygon( polygon, ps : PCollection; alfa, s : double )
  : PCollection;
 { Функция штрихует многоугольник прямыми линиями с заданным углом наклона к
   оси Х. Если существуют многоугольники с ненулевым пересечением с основрым
   многоугольником, то функция эти многоугольники не щтрихует. }
 function out_intersection_interval_and_polygon( polygon : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
 { Функция возвращает отрезки, не принадлежащие многоугольнику, полученные в
   результате пересечения одного отрезка с этим многоугольником. }
 function square_polygon( polygon : PCollection ) : double;
 { ??? Функция вычисляет площадь многоугольника. }
 procedure clip_polygon( x_1, y_1, x_3, y_3 : double; Points : PCollection );
 { Процедура производит отсечение многоугольника по
    параллельному прямоугольнику с диаметральнопротивоположными мершинами
    (x_1,y_1) и (x_2,y_2). }
 function point_on_polygon_border( x, y : double; xx : PCollection ) : boolean;
 { Функция определяет лежит ли точка на границе многоугольника. }
 function communications_and_uchastok( uch, b, houses : PCollection;
              ccc : boolean ) : PCollection;
 function communication_and_uchastok( uch, b : PCollection ) : PCollection;
 procedure qu_qu( h, o : PCollection );
// function magazine_of_intersections( uch, houses, obrem : PCollection ) : PCollection;
 function assembly_polygons2( tp : TConnectionPoints ) : PCollection;
 { wich is not cliping }

implementation 

function intersection_interval_and_polygon( polygon : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
  var
    col, intervals, xx, yy : PCollection;
    i, j, intersect : integer;
    t, O, x, y : double;                      
    p : pointer;
  begin
    xx := PCollection.Create(1);
    xx.insert( TDot1.Create( x1, y1 ) );
    xx.insert( TDot1.Create( x2, y2 ) );
    for i := 0 to polygon.count-1 do
      if ( i = polygon.count-1 )
       then
        begin
         intersect :=intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                  TDot1( polygon[polygon.count-1] ).x,
                  TDot1( polygon[polygon.count-1] ).y, t, O );
//          Writeln('Int1=',InterSect,' ',t:8:8,' ',O:8:8);
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.AtInsert( xx.count-1,
                            TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
         if intersect = 0 then
           begin
             col := intersection_two_intervals( x1, y1, x2, y2,
                       TDot1( polygon[0] ).x, TDot1( polygon[0] ).y, TDot1( polygon[polygon.count-1] ).x,
                       TDot1( polygon[polygon.count-1] ).y );
             if col.Count > 0 then
               begin
                 for j := 0 to col.Count-1 do xx.AtInsert( xx.Count-1, col[j] );
                 col.DeleteAll;
               end;
             col.Free;
           end;
        end
       else
       begin
        intersect:=intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                  TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y, t, O );
//        Writeln('Int2=',InterSect,' ',t:8:8,' ',O:8:8);
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.AtInsert( xx.count-1,
                            TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
         if intersect = 0 then
           begin
             col := intersection_two_intervals( x1, y1, x2, y2,
                       TDot1( polygon[i] ).x, TDot1( polygon[i] ).y, TDot1( polygon[i+1] ).x,
                       TDot1( polygon[i+1] ).y );
             if col.Count > 0 then
               begin
                 for j := 0 to col.Count-1 do xx.AtInsert( xx.Count-1, col[j] );
                 col.DeleteAll;
               end;
             col.Free;
           end;
       end;
    for j := 1 to xx.count-1 do
      for i := 1 to xx.count-1 do
        if Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
              TDot1( xx[j] ).x, TDot1( xx[j] ).y )
            < Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
                TDot1( xx[i] ).x, TDot1( xx[i] ).y ) then
          begin
            p := xx[i];
            xx[i] := xx[j];
            xx[j] := p;
          end;
    intervals := PCOllection.Create(1);
    Result := intervals;
    for i := 1 to xx.count-1 do
      begin
        x := ( TDot1( xx[i-1] ).x + TDot1( xx[i] ).x ) / 2;
        y := ( TDot1( xx[i-1] ).y + TDot1( xx[i] ).y ) / 2;
//        PSetPixel(x,y);
        if ( point_and_polygon( x, y, polygon ) in [0,1] ) and
           ( Distance( TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
                       TDot1( xx[i] ).x, TDot1( xx[i] ).y ) > 1.0E-3 ) then  { -1!!! }
          begin
          intervals.Insert( TEdge.Create(
            TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
            TDot1( xx[i] ).x, TDot1( xx[i] ).y ) );
//            writeln('...',distance(  TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y, TDot1( xx[i] ).x, TDot1( xx[i] ).y ) );
          end;
      end;
//      writeln('------ ',xx.count);
//      readln;
    xx.Free;
  end;

(*
function intersection_interval_and_polygon2( polygon, p1 : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
  var
    intervals, xx, yy : PCollection;
    i, j, intersect : integer;
    t, O, x, y : double;
    p : pointer;
  begin
    xx := PCollection.Create(1);
    Result := xx;
    xx.insert( TDot1.Create( x1, y1 ) );
    xx.insert( TDot1.Create( x2, y2 ) );
    for i := 0 to polygon.count-1 do
      if ( i = polygon.count-1 )
       then
        begin
         intersect :=intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                  TDot1( polygon[polygon.count-1] ).x,
                  TDot1( polygon[polygon.count-1] ).y, t, O );
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.AtInsert( xx.count-1,
                            TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
          if intersect = 0 then
            begin
              yy := PCollection.Create(1);
              yy.insert( TDot1.Create( x1, y1 ) );
              yy.insert( TDot1.Create( x2, y2 ) );
              yy.insert( TDot1.Create( TDot1( polygon[0] ).x, TDot1( polygon[0] ).y ) );
              yy.insert( TDot1.Create( TDot1( polygon[polygon.count-1] ).x,
                         TDot1( polygon[polygon.count-1] ).y ) );
              for j := 0 to 3 do
               if (point_on_polygon_border(TDot1( yy[j] ).x,TDot1( yy[j] ).y,polygon))
               and (point_on_polygon_border(TDot1( yy[j] ).x,TDot1( yy[j] ).y,p1)) then
                xx.AtInsert( xx.count-1, TDot1.Create( TDot1( yy[j] ).x,
                                                         TDot1( yy[j] ).y ) );
              yy.Free;
            end;
        end
       else
       begin
        intersect:=intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                  TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y, t, O );
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.Insert( TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
          if intersect = 0 then
            begin
              yy := PCollection.Create(1);
              yy.insert( TDot1.Create( x1, y1 ) );
              yy.insert( TDot1.Create( x2, y2 ) );
              yy.insert( TDot1.Create( TDot1( polygon[i] ).x, TDot1( polygon[i] ).y ) );
              yy.insert( TDot1.Create( TDot1( polygon[i+1] ).x,
                         TDot1( polygon[i+1] ).y ) );
              for j := 0 to 3 do
               if (point_on_polygon_border(TDot1( yy[j] ).x,TDot1( yy[j] ).y,polygon))
               and (point_on_polygon_border(TDot1( yy[j] ).x,TDot1( yy[j] ).y,p1)) then
                xx.Insert( TDot1.Create( TDot1( yy[j] ).x,
                                                         TDot1( yy[j] ).y ) );
              yy.Free;
            end;
       end;
    for j := 1 to xx.count-2 do
      for i := 1 to xx.count-2 do
        if S( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
              TDot1( xx[j] ).x, TDot1( xx[j] ).y )
            <S( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
                TDot1( xx[i] ).x, TDot1( xx[i] ).y ) then
          begin
            p := xx[i];
            xx[i] := xx[j];
            xx[j] := p;
          end;
    intervals := PCOllection.Create(1);
    for i := 1 to xx.count-1 do
      begin
        x := ( TDot1( xx[i-1] ).x + TDot1( xx[i] ).x ) / 2;
        y := ( TDot1( xx[i-1] ).y + TDot1( xx[i] ).y ) / 2;
        if ( point_and_polygon( x, y, polygon ) > -1 ) then  { -1!!! }
          intervals.Insert( TEdge.Create(
            TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
            TDot1( xx[i] ).x, TDot1( xx[i] ).y ) );
      end;
    xx.Free;
    Result := intervals;
  end;
*)

function intervals_of_intersection_two_polygons( Polygon1,
            Polygon2 : PCollection ) : PCollection;
  var
    i, j : integer;
    xx, intervals : PCollection;
  begin
    intervals := PCollection.Create(1);
    Result := intervals;
    for i := 0 to polygon2.count-1 do
      begin
        if ( i = polygon2.count-1 ) then
          xx := intersection_interval_and_polygon( polygon1,
                  TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                  TDot1( polygon2[0] ).x, TDot1( polygon2[0] ).y )
         else
           xx := intersection_interval_and_polygon( polygon1,
                   TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                   TDot1( polygon2[i+1] ).x, TDot1( polygon2[i+1] ).y );
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
    for i := 0 to polygon1.count-1 do
      begin
        if ( i = polygon1.count-1 ) then
          xx := intersection_interval_and_polygon( polygon2,
                  TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                  TDot1( polygon1[0] ).x, TDot1( polygon1[0] ).y )
         else
           xx := intersection_interval_and_polygon( polygon2,
                   TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                   TDot1( polygon1[i+1] ).x, TDot1( polygon1[i+1] ).y );
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
    Result := intervals;
  end;

function polygon_triangulations( pol : PCollection ) : PCollection;
 var
   i, j, flag, k : integer;
   res, col, intervals : PCollection;
   p1, p2, p3 : TDot1;
   e : tedge;
 begin
   res := PCollection.Create(1);
   result := res;
   if distance( TDot1( pol[0] ).x, TDot1( pol[0] ).y,
                TDot1( pol[pol.Count-1] ).x, TDot1( pol[pol.Count-1] ).y ) < 1.0E-7
    then pol.AtFree( pol.Count-1 );
   flag := sqr( pol.Count );
   j := 0;
   while pol.Count > 3 do
     begin
       for i := 0 to pol.Count-1 do
         begin
           p2 := pol[i];
           if i = 0 then p1 := pol[pol.Count-1] else p1 := pol[i-1];
           if i = pol.Count-1 then p3 := pol[0] else p3 := pol[i+1];
           intervals := nil;
           intervals := intersection_interval_and_polygon( pol, p1.x, p1.y,
                                                                p3.x, p3.y );
           if ( intervals.Count = 1 ) then
             begin
               e := intervals[0];
              if abs( distance( p1.x, p1.y, p3.x, p3.y ) -
                      distance( e.x1,e.y1,e.x2,e.y2 ) ) < 1.0E-5 then
                begin
                  col := PCollection.Create(1);
                  col.Insert( TDot1.Create( p1.x, p1.y ) );
                  col.Insert( TDot1.Create( p2.x, p2.y ) );
                  col.Insert( TDot1.Create( p3.x, p3.y ) );
                  res.Insert( col );
                  pol.AtFree( i );
                  intervals.Free;
                  intervals := nil;
                  break;
                end;
             end;
         end;
       if intervals <> nil then intervals.Free;
       if j > flag then
         begin
//           writeln(j,'/',flag,'i can not take triangulation. ',pol.count,' --> ',res.count );
           break;
         end;
       j := j + 1;
     end; // while ... do.
   if pol.Count = 3 then
     begin
       p2 := pol[1];
       p1 := pol[0];
       p3 := pol[2];
       col := PCollection.Create(1);
       col.Insert( TDot1.Create( p1.x, p1.y ) );
       col.Insert( TDot1.Create( p2.x, p2.y ) );
       col.Insert( TDot1.Create( p3.x, p3.y ) );
       res.Insert( col );
     end
   else begin
//     writeln('ewthuqhlkjthklqwrehthewjlrhtlkjhe');
   end;
 end;

function intersection_two_polygons( polygon1, polygon2 : PCollection )
  : PCollection;
  var
    i, flag, count, counter : integer;
    e : TEdge;
    x_begin, x_end, y_begin, y_end, eps : double;
    {cp,} intervals, polygon, polygons : PCollection;
    TP : TConnectionPoints;
    cp : TConnectionPolygons2;
  begin
    intervals := intervals_of_intersection_two_polygons( polygon1, polygon2 );
    eps := 0.001;
    for i := intervals.Count-1 downto 0 do
      begin
        e := intervals[i];
        if Distance( e.x1, e.y1, e.x2, e.y2 ) < eps then intervals.AtFree( i );
      end;
{
      TP := TConnectionPoints.Create(1);
      TP.Duplicates:=False;
      for i := 0 to intervals.Count-1 do
        begin
          e := intervals[i];
          TP.InsertEdge(
            TDot1.Create( e.x1, e.y1 ),
            TDot1.Create( e.x2, e.y2 )
          );
        end;
      cp := assembly_polygons2( tp );
      result := cp;
      exit;
      polygons := PCollection.Create(1);
      for i := 0 to cp.Count-1 do
        begin
          polygon := cp[i];
          polygons.Insert( polygon );
        end;
      cp.DeleteAll;
      cp.Free;
      tp.Free;
      intervals.Free;
      result := polygons;
      exit;
//}
                     {++++++++++++++++++++++++++++++++}
    polygons := PCollection.Create(1);
    Result := polygons;
    if intervals.Count = 0 then Exit;
    repeat
      flag := 0;
      polygon := PCollection.Create(1);
      e := intervals[intervals.count-1];
      x_begin := e.x1;
      y_begin := e.y1;
      x_end := e.x2;
      y_end := e.y2;
      polygon.insert( TDot1.Create( x_begin, y_begin ) );
      polygon.insert( TDot1.Create( x_end, y_end ) );
      intervals.AtFree( intervals.count-1 );
      count := 0;
      counter := 10 * intervals.Count;
      repeat
        count := count +1;
        for i := intervals.count-1 downto 0 do
          begin
            e := intervals[i];
            if ( ( ( abs( x_end - e.x2 ) < eps ) and
                   ( abs( y_end - e.y2 ) < eps ) and
                   ( abs( x_begin - e.x1 ) < eps ) and
                   ( abs( y_begin - e.y1 ) < eps ) )
                 or
                 ( ( abs( x_begin - e.x2 ) < eps ) and
                   ( abs( y_begin - e.y2 ) < eps ) and
                   ( abs( x_end - e.x1 ) < eps ) and
                   ( abs( y_end - e.y1 ) < eps ) ) )
             then
               begin
                 intervals.AtFree( i );
                 polygons.Insert( polygon );
                 flag := 1;
                 break;
               end
             else
               if ( ( abs( x_end - e.x1 ) < eps ) and
                    ( abs( y_end - e.y1 ) < eps ) )
                then
                  begin
                    x_end := e.x2;
                    y_end := e.y2;
                    polygon.Insert( TDot1.Create( x_end, y_end ) );
                    intervals.AtFree( i );
                  end
                else
                  if ( ( abs( x_begin - e.x1 ) < eps ) and
                       ( abs( y_begin - e.y1 ) < eps ) )
                   then
                     begin
                       x_begin := e.x2;
                       y_begin := e.y2;
                       polygon.AtInsert( 0, TDot1.Create( x_begin,
                                                         y_begin ) );
                       intervals.AtFree( i );
                     end
                   else
                     if ( ( abs( x_end - e.x2 ) < eps ) and
                          ( abs( y_end - e.y2 ) < eps ) )
                      then
                        begin
                          x_end := e.x1;
                          y_end := e.y1;
                          polygon.Insert( TDot1.Create( x_end, y_end ) );
                          intervals.AtFree( i );
                        end
                      else
                        if ( ( abs( x_begin - e.x2 ) < eps ) and
                             ( abs( y_begin - e.y2 ) < eps ) ) then
                          begin
                            x_begin := e.x1;
                            y_begin := e.y1;
                            polygon.AtInsert( 0, TDot1.Create( x_begin,
                                                              y_begin ) );
                            intervals.AtFree( i );
                          end;
          end;
        if count > counter then
          begin
            writeln('Error: I can not stop process 0.',polygons.count);
          {
            for i := 0 to intervals.count-1 do
             begin
               e := intervals[i];
               writeln(e.x1, e.y1);
               writeln('              ',e.x2, e.y2);
             end;
//                                                         }
            intervals.free;
            Exit;
          end;
      until ( flag = 1 );
    until intervals.count = 0;
    intervals.free;
  end;

function point_on_polygon_border( x, y : double; xx : PCollection )
  : boolean;
  var
    i : integer;
    t, eps, epsilon, x1, y1 : double;
  begin
    Result := FALSE;
{}
    t := 0;         
    eps := 1.0E-4;
    epsilon := 1.0E-4;
{}
    x1 := TDot1( xx[0] ).x;
    y1 := TDot1( xx[0] ).y;
    xx.insert( TDot1.Create( x1, y1 ) );
    for i := 0 to xx.count-1 do
     if Distance( TDot1(xx[i]).x, TDot1(xx[i]).y, x, y ) < epsilon then
       begin
         Result := TRUE;
         xx.AtFree( xx.Count-1 );
         EXIT;
       end;
    for i := 0 to xx.count-1 do
     if i = xx.count-1 then
      begin
        if Distance( TDot1(xx[i]).x, TDot1(xx[i]).y,
                     TDot1(xx[0]).x, TDot1(xx[0]).y ) > epsilon then
          begin
            if abs( ( x-TDot1(xx[i]).x )*( TDot1(xx[0]).y-TDot1(xx[i]).y ) -
                    ( y-TDot1(xx[i]).y )*( TDot1(xx[0]).x-TDot1(xx[i]).x ) )
                    < eps
             then begin
                    if ( abs( (TDot1(xx[i]).y-TDot1(xx[0]).y) ) < eps )
                      then
                        t := (x-TDot1(xx[0]).x)/(TDot1(xx[i]).x-
                                                         TDot1(xx[0]).x)
                      else
                        t := (y-TDot1(xx[0]).y)/(TDot1(xx[i]).y-
                                                         TDot1(xx[0]).y);
                    if ( Round(t*10000) >= 0 ) and ( Round(t*10000) <= 10000 )
                     then begin
                            Result := TRUE;
                            break;
                          end;
                  end;
          end;
      end
     else
       begin
         if Distance( TDot1(xx[i]).x, TDot1(xx[i]).y,
                     TDot1(xx[i+1]).x, TDot1(xx[i+1]).y ) > epsilon then
          begin
            if abs( ( x-TDot1(xx[i]).x )*( TDot1(xx[i+1]).y-TDot1(xx[i]).y ) -
                    ( y-TDot1(xx[i]).y )*( TDot1(xx[i+1]).x-TDot1(xx[i]).x ) )
                    < eps
             then begin
                    if ( abs( (TDot1(xx[i]).y-TDot1(xx[i+1]).y) ) < eps )
                      then
                        t := (x-TDot1(xx[i+1]).x)/(TDot1(xx[i]).x-
                                                         TDot1(xx[i+1]).x)
                      else
                        t := (y-TDot1(xx[i+1]).y)/(TDot1(xx[i]).y-
                                                         TDot1(xx[i+1]).y);
                    if ( Round(t*10000) >= 0 ) and ( Round(t*10000) <= 10000 )
                     then begin
                            Result := TRUE;
                            break;
                          end;
                  end;
          end;
       end;
    xx.AtFree( xx.Count-1 );
 end;

procedure new_vertex_to_polygon( x_1, y_1, x_2, y_2 : double;
                                             Points : PCollection );
  var
    d0, d1 : TDot1;
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
             x := d0.x + ( d1.x - d0.x ) * t;
             y := d0.y + ( d1.y - d0.y ) * t;
             Points.AtInsert( i+1, TDot1.Create( X, Y ) );
             i := i + 1;
           end;
      i := i + 1;
    until ( i > Points.count-1 );
  end;

procedure clip_polygon( x_1, y_1, x_3, y_3 : double; Points : PCollection );
  var
    x_2, y_2, x_4, y_4 : double;
    i : integer;
  begin
    x_2 := x_1; y_2 := y_3;
    x_4 := x_3; y_4 := y_1;
    new_vertex_to_polygon( x_1, y_1, x_2, y_2, Points );
    for i := Points.count-1 downTo 0 do
     if ( TDot1( Points[i] ).x - x_1 ) < -1.0E-10 then Points.AtFree(i);
     if Points.Count=0 then Exit;

    new_vertex_to_polygon( x_2, y_2, x_3, y_3, Points );
    for i := Points.count-1 downTo 0 do
     if ( TDot1( Points[i] ).y - y_2 ) > 1.0E-10 then Points.AtFree(i);
     if Points.Count=0 then Exit;

    new_vertex_to_polygon( x_3, y_3, x_4, y_4, Points );
    for i := Points.count-1 downTo 0 do
     if ( TDot1( Points[i] ).x - x_3 ) > 1.0E-10 then Points.AtFree(i);
     if Points.Count=0 then Exit;

    new_vertex_to_polygon( x_4, y_4, x_1, y_1, Points );
    for i := Points.Count-1 downTo 0 do
     if ( TDot1( Points[i] ).y - y_1 ) < -1.0E-10 then Points.AtFree(i);
     if Points.Count=0 then Exit;
  end;

function point_and_polygon( x, y : double; p : PCollection ) : integer;
 var
   i, j, k, c, intersect : integer;
   ss, x1, y1, t, o : double;
   p1, p2 : TDot1;
   label label_1;
 begin
   t := 0;
   O := 0;
   k := 1;
   if point_on_polygon_border( x, y, p ) = TRUE then begin Result := 0;
                                                           Exit;
                                                     end;
   Result := -1;
   j:=0;
   repeat
       c := 0;
       k := 0;
       if i  < p.Count-1 then
         begin
           p1 := TDot1( p[j] );
           p2 := TDot1( p[j+1] );
         end
       else
         begin
           p1 := TDot1( p[j] );
           p2 := TDot1( p[0] );
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
     {}
   if k = 1 then
     begin
       writeln('pizdets!!!!!!!!!: Point and Polygon !!!!!!!!!!!!!!');
   //     readln;
     end;
 end;

function assembly_polygon_from_segments( segments : PCollection )
  : PCollection;
 var
   i, j, k, m, flag, count, counter : integer;
   edge, edge1, edge2 : TEdge;
   pol, polygons, col, col1, res, intervals : PCollection;
   eps, beta, x, y : double;
   p : pointer;
   B : Boolean;
 begin
   res := PCollection.Create(1);
   eps := 1.0E-5;
   counter := segments.Count;
   for i := segments.Count-1 downto 0 do
     begin
       edge := TEdge( segments[i] );
       if Distance( edge.X1, edge.Y1, edge.X2, edge.Y2 ) < 1.0E-10 then
         segments.AtFree( i ); {???????????}
     end;
   if segments.Count < 2 then
     begin
       Result := res;
       Exit;
     end;
   for i := 0 to segments.Count-1 do
     begin
       intervals := PCollection.Create(1);
       edge := TEdge( segments[i] );
       edge := TEdge.Create( edge.x1, edge.y1, edge.x2, edge.y2 );
       intervals.Insert( TEdge.Create( edge.x1, edge.y1, edge.x2, edge.y2 ) );
       count := 0;
       repeat
         col1 := PCollection.Create(1);
         for j := 0 to segments.Count-1 do
          if equality_of_edges( edge, TEdge( segments[j] ), 1.0E-5 ) = FALSE then
             begin
               edge1 := TEdge( segments[j] );
               if ( abs( edge.x2 - edge1.x1 ) < eps ) and
                  ( abs( edge.y2 - edge1.y1 ) < eps ) then
                    col1.Insert( TEdge.Create( edge1.x1, edge1.y1,
                                                  edge1.x2, edge1.y2 ) )
                else
                 if ( abs( edge.x2 - edge1.x2 ) < eps ) and
                    ( abs( edge.y2 - edge1.y2 ) < eps )
                  then
                    col1.Insert( TEdge.Create( edge1.x2, edge1.y2,
                                                  edge1.x1, edge1.y1 ) );
             end;
         for k := 1 to col1.Count-1 do
          if angle_between_edges( edge, col1[0] )
               > angle_between_edges( edge, col1[k] ) then
            begin
              p := col1[0];
              col1[0] := col1[k];
              col1[k] := p;
            end;
         if col1.Count > 0 then
           begin
             edge.x1 := TEdge( col1[0] ).x1;
             edge.y1 := TEdge( col1[0] ).y1;
             edge.x2 := TEdge( col1[0] ).x2;
             edge.y2 := TEdge( col1[0] ).y2;
             intervals.Insert( TEdge.Create( edge.x1, edge.y1,
                                             edge.x2, edge.y2 ) );
           end;
         col1.Free;
         { ?????????????????????????????? }
         if ( intervals.Count > segments.Count ) or ( count > 10 * counter ) then
           begin
             intervals.DeleteAll;
             Result := intervals;
             break;
           end;
         { end: ????????????????????????? }
         count := count + 1;
       until ( TEdge( intervals[0] ).x1
                = TEdge( intervals[intervals.Count-1] ).x2 ) and
             ( TEdge( intervals[0] ).y1
                = TEdge( intervals[intervals.Count-1] ).y2 );
         { ?????????????????????????????? }
       if intervals.Count > 0 then
       if equality_of_edges( TEdge( intervals[0] ),
                             TEdge( intervals[intervals.Count-1] ), 1.0E-5 )
           = TRUE then begin
                         intervals.AtFree( 0 ); {?????????????}
                         intervals.AtFree( intervals.Count-1 );
                       end;
         { end: ????????????????????????? }
       if intervals.Count > 0 then res.insert( intervals );
     end;
   polygons := PCollection.Create(1);
   for i := 0 to res.Count-1 do
     begin
       col := res[i];
       pol := PCollection.Create(1);
       for j := 0 to col.Count-1 do
         pol.Insert( TDot1.Create( TEdge( col[j] ).x1, TEdge( col[j] ).y1 ) );
       if col.Count > 0 then
         begin
           pol.Insert( TDot1.Create( TEdge( col[0] ).x1, TEdge( col[0] ).y1 ) );
           polygons.Insert( pol );
         end;
     end;
     {}
   While not B do
     begin
       B:=True;
       for i := 0 to polygons.Count-1 do
        for j := i+1 to polygons.Count-1 do
          begin
            try
               col := polygons[i];
               col1 := polygons[j];
            except
             Col:=nil;
            end;
            if ( col <> nil ) then if  ( col1.Count = col.Count ) and
               ( abs( square_polygon( col ) - square_polygon( col1 ) ) < 1.0E-15 )
               and ( equality_two_polygons( col1, col ) = TRUE )
             then begin
                    polygons.AtFree( j );
                    B := False;
                  end;
          end;
     end;
     {}
   for i := polygons.Count-1 downto 0 do
    if PCollection( polygons[i] ).Count = 0
     then PCollection( polygons[i] ).AtFree( i );
   Result := polygons;
   res.Free;
 end;

function square_polygon( polygon : PCollection ) : double;
  var
    k : integer;
    sum, x, y1, y_1 : double;
  begin
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
    Result := abs( sum / 2 );
  end;

function out_intersection_interval_and_polygon( polygon : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
  var
    intervals, xx : PCollection;
    i, j : integer;
    t, O, x, y : double;
    p : pointer;
  begin
    xx := PCollection.Create(1);
    xx.insert( TDot1.Create( x1, y1 ) );
    xx.insert( TDot1.Create( x2, y2 ) );
    for i := 0 to polygon.count-1 do
      if ( i = polygon.count-1 )
       then
        begin
         if ( ( intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                  TDot1( polygon[polygon.count-1] ).x,
                  TDot1( polygon[polygon.count-1] ).y, t, O )
                = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.AtInsert( xx.count-1,
                            TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
        end
       else
         if ( ( intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                  TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y, t, O )
                = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) )
          then xx.AtInsert( xx.count-1,
                            TDot1.Create( x1 + ( x2 - x1 ) * O,
                                         y1 + ( y2 - y1 ) * O ) );
    for j := 1 to xx.count-2 do
      for i := 1 to xx.count-2 do
        if Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
              TDot1( xx[j] ).x, TDot1( xx[j] ).y )
            < Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
                TDot1( xx[i] ).x, TDot1( xx[i] ).y ) then
          begin
            p := xx[i];
            xx[i] := xx[j];
            xx[j] := p;
          end;
    intervals := PCOllection.Create(1);
    Result := intervals;
    for i := 1 to xx.count-1 do
      begin
        x := ( TDot1( xx[i-1] ).x + TDot1( xx[i] ).x ) / 2;
        y := ( TDot1( xx[i-1] ).y + TDot1( xx[i] ).y ) / 2;
        if ( point_and_polygon( x, y, polygon ) = -1 ) then
          intervals.Insert( TEdge.Create(
            TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
            TDot1( xx[i] ).x, TDot1( xx[i] ).y ) );
      end;
    xx.Free;
    Result := intervals;
  end;

function Shading_of_polygon( polygon, ps : PCollection; alfa, s : double )
  : PCollection;          {??????????}
 var
   i, j, k, l : integer;
   y, x, x_e, y_e, a, b, c, a1, b1, c1, x_min, y_min, x_max, y_max : double;
   edges, pol, polygons, res, col, res1, res2 : PCollection;
   edge : TEdge;
 begin
  x_min := TDot1(polygon[0]).x;
  for i := 1 to polygon.count-1 do
   if TDot1(polygon[i]).x < x_min then x_min := TDot1(polygon[i]).x;
  x_max := TDot1(polygon[0]).x;
  for i := 1 to polygon.count-1 do
   if TDot1(polygon[i]).x > x_max then x_max := TDot1(polygon[i]).x;
  y_min := TDot1(polygon[0]).y;
  for i := 1 to polygon.count-1 do
   if TDot1(polygon[i]).y < y_min then y_min := TDot1(polygon[i]).y;
  y_max := TDot1(polygon[0]).y;
  for i := 1 to polygon.count-1 do
   if TDot1(polygon[i]).y > y_max then y_max := TDot1(polygon[i]).y;
  pol := PCollection.Create(1);
  pol.Insert( tdot1.create( x_min, y_min ) );
  pol.Insert( tdot1.create( x_min, y_max ) );
  pol.Insert( tdot1.create( x_max, y_max ) );
  pol.Insert( tdot1.create( x_max, y_min ) );
  pol.Insert( tdot1.create( x_min, y_min ) );
  res := PCollection.Create(1);
  edges := PCollection.Create(1);
  col := PCollection.Create(1);
  if ( abs( sin( alfa ) ) > 1.0E-3 ) then
    begin
      s := s / abs( sin( alfa ) );
      x := x_min - abs( ( y_max - y_min ) / tan( alfa ) );
      x_max := x_max + abs( ( y_max - y_min ) / tan( alfa ) );
      if abs( cos( alfa ) ) < 1.0E-3 then begin
                                           c := -x_min;
                                           a := 1;
                                           b := 0;
                                         end
         else begin
                c := -y_max + x * tan( alfa );
                a := -tan( alfa );
                b := 1;
              end;
       repeat
         col := PCollection.Create(1);
         for i := 0 to pol.Count-2 do
           begin
             if TDot1( pol[i] ).x = TDot1( pol[i+1] ).x then
               begin
                 a1 := 1;
                 b1 := 0;
                 c1 := -TDot1( pol[i] ).x;
               end
              else begin
                     a1 := 0;
                     b1 := 1;
                     c1 := -TDot1( pol[i] ).y;
                   end;
             edge := TEdge.Create( TDot1( pol[i] ).x, TDot1( pol[i] ).y,
                       TDot1( pol[i+1] ).x, TDot1( pol[i+1] ).y );
             if ( intersection_two_straight_lines( a, b, c, a1, b1, c1, x_e, y_e )
                   = TRUE) and ( point_on_edge( x_e, y_e, edge ) = TRUE ) then
              col.insert( TDot1.Create( x_e, y_e ) );
           end;
         for i := 0 to col.count-2 do
          if ( abs( TDot1( col[i] ).x - TDot1( col[i+1] ).x ) < 1.0E-10 ) and
             ( abs( TDot1( col[i] ).y - TDot1( col[i+1] ).y ) < 1.0E-10 )
           then begin
                  TDot1( col[i] ).x := 1.0E+20;
                  TDot1( col[i] ).y := 1.0E+20;
                end;
         for i:= col.count-1 downto 0 do
          if ( TDot1( col[i] ).x = 1.0E+20 ) and ( TDot1( col[i] ).y = 1.0E+20 )
           then col.AtFree( i ); {??????????}
         if col.Count > 1 then
           edges.Insert( TEdge.Create( TDot1( col[0] ).x, TDot1( col[0] ).y,
                                       TDot1( col[1] ).x, TDot1( col[1] ).y ) );
         col.Free;
         x := x + s;
         if abs( cos( alfa ) ) < 1.0E-3 then c := -x
          else c := - y_max + x * tan( alfa );
       until x > x_max;
    end
  else
   begin
     y := y_min;
     c := -y_min;
     a := 0;
     b := 1;
     repeat
       col := PCollection.Create(1);
       for i := 0 to pol.Count-2 do
         begin
           if TDot1( pol[i] ).x = TDot1( pol[i+1] ).x then
             begin
               a1 := 1;
               b1 := 0;
               c1 := -TDot1( pol[i] ).x;
             end
            else begin
                   a1 := 0;
                   b1 := 1;
                   c1 := -TDot1( pol[i] ).y;
                 end;
           edge := TEdge.Create( TDot1( pol[i] ).x, TDot1( pol[i] ).y,
                     TDot1( pol[i+1] ).x, TDot1( pol[i+1] ).y );
           if ( intersection_two_straight_lines( a, b, c, a1, b1, c1, x_e, y_e )
                 = TRUE) and ( point_on_edge( x_e, y_e, edge ) = TRUE ) then
            col.insert( TDot1.Create( x_e, y_e ) );
         end;
       for i := 0 to col.count-2 do
        if ( abs( TDot1( pol[i] ).x - TDot1( pol[i+1] ).x ) < 1.0E-10 ) and
           ( abs( TDot1( pol[i] ).y - TDot1( pol[i+1] ).y ) < 1.0E-10 )
         then begin
                TDot1( pol[i] ).x := 1.0E+20;
                TDot1( pol[i] ).y := 1.0E+20;
              end;
       for i := col.count-1 downto 0 do
        if ( TDot1( pol[i] ).x = 1.0E+20 ) and ( TDot1( pol[i] ).y = 1.0E+20 )
         then col.AtFree( i );
       if col.Count > 1 then
         edges.Insert( TEdge.Create( TDot1( col[0] ).x, TDot1( col[0] ).y,
                                     TDot1( col[1] ).x, TDot1( col[1] ).y ) );
       col.Free;
       y := y + s;
       c := -y;
     until y > y_max;
   end;
        {}
   for i := 0 to edges.Count-1 do
     begin
       col := intersection_interval_and_polygon(
                       polygon, TEdge( edges[i] ).x1, TEdge( edges[i] ).y1,
                                TEdge( edges[i] ).x2, TEdge( edges[i] ).y2 );
       for j := 0 to col.count-1 do
         res.insert( TEdge.Create( TEdge( col[j] ).x1, TEdge( col[j] ).y1,
                                   TEdge( col[j] ).x2, TEdge( col[j] ).y2 ) );
     end;
   for i := 0 to ps.count-1 do
     begin
       res2 := PCollection.Create(1);
       polygons := ps[i];
       for j := 0 to res.count-1 do
         begin
           res1 := out_intersection_interval_and_polygon( polygons,
                      TEDge( res[j] ).x1, TEDge( res[j] ).y1,
                      TEDge( res[j] ).x2, TEDge( res[j] ).y2 );
           for k := 0 to res1.count-1 do res2.insert( res1[k] );
           res1.DeleteAll;
           res1.Free;
         end;
       res.DeleteAll;
       for l := 0 to res2.Count-1 do res.Insert( TEdge.Create(
         TEdge( res2[l] ).x1, TEdge( res2[l] ).y1,
         TEdge( res2[l] ).x2, TEdge( res2[l] ).y2 ) );
       res2.Free;
     end;
   Result := res;
   edges.Free;
   pol.Free;
 end;

function point_inside_polygon( x, y : double; p : PCollection ) : integer;
 var
   i, j, k, c, intersect : integer;
   x1, y1, t, O, xmax, ymax, xmin, ymin : double;
   p1, p2 : TDot1;
 begin
   Result := -1;
   xmax := TDot1( p[0] ).x;
   ymax := TDot1( p[0] ).y;
   xmin := TDot1( p[0] ).x;
   ymin := TDot1( p[0] ).y;
   for i := 1 to p.Count-1 do
     begin
       if xmax < TDot1( p[i] ).x then xmax := TDot1( p[i] ).x;
       if ymax < TDot1( p[i] ).y then ymax := TDot1( p[i] ).y;
       if xmin > TDot1( p[i] ).x then xmin := TDot1( p[i] ).x;
       if ymin > TDot1( p[i] ).y then ymin := TDot1( p[i] ).y;
     end;
   if ( x >= xmin - 0.001 ) and ( x <= xmax + 0.001 ) and ( y >= ymin - 0.001 )
   and ( y <= ymax + 0.001 ) then
     begin
       if point_on_polygon_border( x, y, p ) = TRUE
        then begin Result := 0;
                   Exit;
             end;
       t := 0;
       O := 0;
       for j := 0 to p.Count-1 do
         begin
           c := 0;
           k := 0;
           if i  < p.Count-1 then
             begin
               p1 := p[j];
               p2 := p[j+1];
             end
           else
             begin
               p1 := p[j];
               p2 := p[0];
             end;
           x1 := ( p1.x + p2.x ) / 2;
           y1 := ( p1.y + p2.y ) / 2;
           { for i... }
           for i := 0 to p.Count-1 do
             begin
               if i < p.Count-1 then p2 := p[i+1] else p2 := p[0];
               p1 := p[i];
               intersect := intersection_straight_lines( p1.x, p1.y, p2.x, p2.y,
                                                              x, y, x1, y1, t, o );
               if ( intersect = 1 ) and ( t < 0 ) and ( O >= 0 ) and ( O <= 1 ) then
                 begin
                   if ( abs( O ) < 1.0E-10 ) or ( abs( O - 1 ) < 1.0E-10 ) then
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
         end;
         {}
       if k = 1 then writeln('pizdets!!!!!!!!!: Point and Polygon !!!!!!!!!!!!!!');
     end;
 end;

function point_inside_polygon2( x, y, xmax, ymax, xmin, ymin : double;
                                p : PCollection ) : integer;
 var
   i, j, k, c, intersect : integer;
   x1, y1, t, o  : double;
   p1, p2 : TDot1;
 begin
   Result := -1;
   if ( x >= xmin - 0.01 ) and ( x <= xmax + 0.01 ) and ( y >= ymin - 0.01 ) and
      ( y <= ymax + 0.01 ) then
     begin
       if point_on_polygon_border( x, y, p ) = TRUE
        then begin Result := 0;
                   Exit;
             end;
       t := 0;
       O := 0;
       for j := 0 to p.Count-1 do
         begin
           c := 0;
           k := 0;
           if i  < p.Count-1 then
             begin
               p1 := p[j];
               p2 := p[j+1];
             end
           else
             begin
               p1 := p[j];
               p2 := p[0];
             end;
           x1 := ( p1.x + p2.x ) / 2;
           y1 := ( p1.y + p2.y ) / 2;
           { for i... }
           for i := 0 to p.Count-1 do
             begin
               if i < p.Count-1 then p2 := p[i+1] else p2 := p[0];
               p1 := p[i];
               intersect := intersection_straight_lines( p1.x, p1.y, p2.x, p2.y,
                                                              x, y, x1, y1, t, o );
               if ( intersect = 1 ) and ( t < 0 ) and ( O >= 0 ) and ( O <= 1 ) then
                 begin
                   if ( abs( O ) < 1.0E-10 ) or ( abs( O - 1 ) < 1.0E-10 ) then
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
         end;
         {}
       if k = 1 then writeln('pizdets!!!!!!!!!: Point and Polygon !!!!!!!!!!!!!!');
     end;
 end;

function equality_two_polygons( pol1, pol2 : PCollection ) : boolean;
 var
   i : integer;
 begin
   Result := TRUE;
   for i := 0 to pol1.Count-1 do
    if point_on_polygon_border( TDot1( pol1[i] ).x, TDot1( pol1[i] ).y, pol2 ) = FALSE
     then begin
            Result := FALSE;
            Exit;
          end;
   for i := 0 to pol2.Count-1 do
    if point_on_polygon_border( TDot1( pol2[i] ).x, TDot1( pol2[i] ).y, pol1 ) = FALSE
     then Result := FALSE;
 end;

function polygon_out_polygon( p1, p2 : PCollection ) : integer;
   { result = 0 ==> p1 and p2 can be intersected
              1 or 2 (!!!) ==> p1 outside of p2.  }
{ ne dokontsa protestirovan !!! }
 var
   i, res, flag1, flag2, flag3, flag21, flag22, flag23, flg : integer;
   p : TDot1;
   x, y : double;
 begin
   result := 0;
   if ( p1.Count < 2 ) or ( p2.Count < 2 ) then Exit;
   flag21 := 0;
   flag22 := 0;
   flag23 := 0;
   res := 0;
   for i := 0 to p1.Count-1 do
     begin
       x := TDot1( p1[i] ).x;
       y := TDot1( p1[i] ).y;
       flg := point_and_polygon( x, y, p2 );
       case flg of
         -1 : flag21 := 1;
          0 : flag22 := 1;
          1 : flag23 := 1;
       end;
     end;
   if ( flag21 = 1 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then res := 1;
   if ( flag21 = 1 ) and ( flag22 = 0 ) and ( flag23 = 0 ) then res := 1;
   if res = 1 then
     begin
       result := res;
       exit;
     end;
   flag1 := 0;
   flag2 := 0;
   flag3 := 0;
   p1.Insert( TDot1.Create( TDot1( p1[0] ).x, TDot1( p1[0] ).y ) );
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then
     begin
       for i := 0 to p1.Count-2 do
         begin
           x := ( TDot1( p1[i] ).x + TDot1( p1[i+1] ).x ) / 2;
           y := ( TDot1( p1[i] ).y + TDot1( p1[i+1] ).y ) / 2;
           flg := point_and_polygon( x, y, p2 );
           case flg of
             -1 : flag1 := 1;
              0 : flag2 := 1;
              1 : flag3 := 1;
           end;
         end;
       if ( flag1 = 1 ) and ( flag2 = 1 ) and ( flag3 = 0 ) then res := 1;
       if ( flag1 = 1 ) and ( flag2 = 0 ) and ( flag3 = 0 ) then res := 1;
     end;
   p1.AtFree(p1.Count-1);
   if res = 1 then
     begin
       result := res;
       exit;
     end;
{------------------------------------------------------------------------------}
   flag21 := 0;
   flag22 := 0;
   flag23 := 0;
   for i := 0 to p2.Count-1 do
     begin
       x := TDot1( p2[i] ).x;
       y := TDot1( p2[i] ).y;
       flg := point_and_polygon( x, y, p1 );
       case flg of
         -1 : flag21 := 1;
          0 : flag22 := 1;
          1 : flag23 := 1;
       end;
     end;
   if ( flag21 = 1 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then res := 2;
   if ( flag21 = 1 ) and ( flag22 = 0 ) and ( flag23 = 0 ) then res := 2;
   if res = 1 then
     begin
       result := res;
       exit;
     end;
   flag1 := 0;
   flag2 := 0;
   flag3 := 0;
   p2.Insert( TDot1.Create( TDot1( p2[0] ).x, TDot1( p2[0] ).y ) );
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then
     begin
       for i := 0 to p2.Count-2 do
         begin
           x := ( TDot1( p2[i] ).x + TDot1( p2[i+1] ).x ) / 2;
           y := ( TDot1( p2[i] ).y + TDot1( p2[i+1] ).y ) / 2;
           flg := point_and_polygon( x, y, p1 );
           case flg of
             -1 : flag1 := 1;
              0 : flag2 := 1;
              1 : flag3 := 1;
           end;
         end;
       if ( flag1 = 1 ) and ( flag2 = 1 ) and ( flag3 = 0 ) then res := 2;
       if ( flag1 = 1 ) and ( flag2 = 0 ) and ( flag3 = 0 ) then res := 2;
     end;
   p2.AtFree(p2.Count-1);
   result := res;
 end;

function polygon_in_polygon( p1, p2 : PCollection ) : integer;
   { result = 0 ==> p1 and p2 can be intersected
              1 ==> p1 belongs p2
              2 ==> p1 completely covers p2.  }
{ ne dokontsa protestirovan !!! }
 var
   i, res, flag1, flag2, flag3, flag21, flag22, flag23, flg : integer;
   p : TDot1;
   x, y : double;
 begin
   result := 0;
   if ( p1.Count < 2 ) or ( p2.Count < 2 ) then Exit;
   flag21 := 0;
   flag22 := 0;
   flag23 := 0;
   res := 0;
   for i := 0 to p1.Count-1 do
     begin
       x := TDot1( p1[i] ).x;
       y := TDot1( p1[i] ).y;
       flg := point_and_polygon( x, y, p2 );
       case flg of
         -1 : flag21 := 1;
          0 : flag22 := 1;
          1 : flag23 := 1;
       end;
     end;
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 1 ) then res := 1;
   if ( flag21 = 0 ) and ( flag22 = 0 ) and ( flag23 = 1 ) then res := 1;
   if res = 1 then
     begin
       result := res;
       exit;
     end;
   flag1 := 0;
   flag2 := 0;
   flag3 := 0;
   p1.Insert( TDot1.Create( TDot1( p1[0] ).x, TDot1( p1[0] ).y ) );
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then
     begin
       for i := 0 to p1.Count-2 do
         begin
           x := ( TDot1( p1[i] ).x + TDot1( p1[i+1] ).x ) / 2;
           y := ( TDot1( p1[i] ).y + TDot1( p1[i+1] ).y ) / 2;
           flg := point_and_polygon( x, y, p2 );
           case flg of
             -1 : flag1 := 1;
              0 : flag2 := 1;
              1 : flag3 := 1;
           end;
         end;
       if ( flag1 = 0 ) and ( flag2 = 1 ) and ( flag3 = 1 ) then res := 1;
       if ( flag1 = 0 ) and ( flag2 = 0 ) and ( flag3 = 1 ) then res := 1;
     end;
   p1.AtFree(p1.Count-1);
   if res = 1 then
     begin
       result := res;
       exit;
     end;
{------------------------------------------------------------------------------}
   flag21 := 0;
   flag22 := 0;
   flag23 := 0;
   for i := 0 to p2.Count-1 do
     begin
       x := TDot1( p2[i] ).x;
       y := TDot1( p2[i] ).y;
       flg := point_and_polygon( x, y, p1 );
       case flg of
         -1 : flag21 := 1;
          0 : flag22 := 1;
          1 : flag23 := 1;
       end;
     end;
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 1 ) then res := 2;
   if ( flag21 = 0 ) and ( flag22 = 0 ) and ( flag23 = 1 ) then res := 2;
   if res = 1 then
     begin
       result := res;
       exit;
     end;
   flag1 := 0;
   flag2 := 0;
   flag3 := 0;
   p2.Insert( TDot1.Create( TDot1( p2[0] ).x, TDot1( p2[0] ).y ) );
   if ( flag21 = 0 ) and ( flag22 = 1 ) and ( flag23 = 0 ) then
     begin
       for i := 0 to p2.Count-2 do
         begin
           x := ( TDot1( p2[i] ).x + TDot1( p2[i+1] ).x ) / 2;
           y := ( TDot1( p2[i] ).y + TDot1( p2[i+1] ).y ) / 2;
           flg := point_and_polygon( x, y, p1 );
           case flg of
             -1 : flag1 := 1;
              0 : flag2 := 1;
              1 : flag3 := 1;
           end;
         end;
       if ( flag1 = 0 ) and ( flag2 = 1 ) and ( flag3 = 1 ) then res := 2;
       if ( flag1 = 0 ) and ( flag2 = 0 ) and ( flag3 = 1 ) then res := 2;
     end;
   p2.AtFree(p2.Count-1);
   result := res;
 end;

const flag_continue : integer = 0;

function stop_asembility( pol : PCollection ) : integer;
{
result =
0 - сбор закончен
1 - бесконечный цикл
2 - продолжаем
}
 var
   i, j, count, res, flg : integer;
   p1, p2, p3 : TDot1;
 begin
   result := 0;
   p1 := pol[0];
   count := pol.Count;
   p2 := pol[count-1];
   if distance( p1.x, p1.y, p2.x, p2.y ) < 1.0E-7 then exit;
   for i := 1 to count-2 do
     begin
       p1 := pol[i];
       if distance( p1.x, p1.y, p2.x, p2.y ) < 1.0E-7 then
         begin
           result := 1;
           exit;
         end;
     end;
   result := 2;
 end;

procedure asembl_pol1( p1 : TConnectionPoint; var polygon : PCollection );
 var
   flg, ind1, count, i, ind, int : integer;
   p0, p2, p3, p4 : TConnectionPoint;
 begin
   p0 := p1;
   p2 := p1.Points[0];
//   polygon.Insert( p2.Dot );
   polygon.Insert( TDot1.Create( p2.x, p2.y ) );
   flg := 1;
   count := 0;
   repeat
     ind := p2.GetIndex( p1 );
     p1 := p2;
     p2 := p2.Max;
//     polygon.Insert( p2.Dot );
     polygon.Insert( TDot1.Create( p2.x, p2.y ) );
     if count > 0 then
       begin
         ind := stop_asembility( polygon );
         case ind of
           0: exit;
           1: begin
                polygon.FreeAll;
                flag_continue := 1;
                exit;
              end;
         end; // case of ... end.
       end;
     count := count + 1;
   until flg = 0;
 end;

procedure asembl_pol2( p1 : TConnectionPoint; var polygon : PCollection );
 var
   flg, ind2, ind, count : integer;
   p0, p2, p3 : TConnectionPoint;
 begin
   p0 := p1;
   p2 := p1.Points[0];
//   polygon.Insert( p2.Dot );
   polygon.Insert( TDot1.Create( p2.x, p2.y ) );
   flg := 1;
   count := 0;
   repeat
     ind := p2.GetIndex( p1 );
     p1 := p2;
     p2:=p2.Min;
//     polygon.Insert( p2.Dot );
     polygon.Insert( TDot1.Create( p2.x, p2.y ) );
     if distance( p0.x, p0.y, p2.x, p2.y ) < 1.0E-7 then break;
     if count > 0 then
       begin
         ind := stop_asembility( polygon );
         case ind of
           0: exit;
           1: begin
                polygon.FreeAll;
                flag_continue := 2;
                exit;
              end;
         end; // case of ... end.
       end;
     count := count + 1;
   until flg = 0;
 end;

procedure asembl_pol12( p1 : TConnectionPoint; var polygon : PCollection );
 var
   flg, ind1, count, i, ind, int : integer;
   p0, p2, p3, p4 : TConnectionPoint;
 begin
   p0 := p1;
   p2 := p1.Points[0];
//   polygon.Insert( p2.Dot );
   polygon.Insert( TDot1.Create( p2.x, p2.y ) );
   flg := 1;
   count := 0;
   repeat
     ind := p2.GetIndex( p1 );
     p1 := p2;
     p2 := p2.Max;
//     polygon.Insert( p2.Dot );
     polygon.Insert( TDot1.Create( p2.x, p2.y ) );
     if count > 0 then
       begin
         ind := stop_asembility( polygon );
         case ind of
           0: exit;
           1: begin
                polygon.FreeAll;
                flag_continue := 1;
                exit;
              end;
         end; // case of ... end.
       end;
     count := count + 1;
   until flg = 0;
 end;

function assembly_polygons( tp : TConnectionPoints ) : TConnectionPolygons2;
 var
   i, j, flg, count : integer;
   p1, p3, p2 : TConnectionPoint;
   CP : TConnectionPolygons2;
   polygon1, c, c1 : PCollection;
 begin
   CP := TConnectionPolygons2.Create(1);
   CP.Duplicates := False;
   result := CP;
   while tp.Count > 0 do
     begin
       p1 := tp[0];
       polygon1 := PCollection.Create(1);
//        polygon1.Insert( p1.Dot );
       polygon1.Insert( TDot1.Create( p1.x, p1.y ) );
       flag_continue := 0;
       asembl_pol1( p1, polygon1 );
       if flag_continue <> 0 then polygon1.Free else cp.Insert( polygon1 );
//       if flag_continue <> 0 then writeln('i can not asemblity polygons !!!');
       polygon1 := PCollection.Create(1);
//        polygon1.Insert( p1.Dot );
       polygon1.Insert( TDot1.Create( p1.x, p1.y ) );
       flag_continue := 0;
       asembl_pol2( p1, polygon1 );
       if flag_continue <> 0 then polygon1.Free else cp.Insert( polygon1 );
//       if flag_continue <> 0 then writeln('i can not asemblity polygons !!!');
       tp.AtDelete(0);
     end;
   for i := 0 to cp.Count-1 do for j := i+1 to cp.Count-1 do
      begin
         c1 := cp[i];
         c := cp[j];
         flg := 0;
         flg := polygon_in_polygon( c1, c );
         if flg = 1 then
           begin
             PCollection( cp[j] ).FreeAll;
             continue;
           end;
           {
         if flg = 2 then
           begin
             PCollection( segments[i] ).FreeAll;
             continue
           end;
//           }
       end;
   for i := cp.Count-1 downto 0 do
     begin
       c1 := cp[i];
       if c1.Count < 3 then cp.AtFree( i );
     end;
 end;

function assembly_polygons2( tp : TConnectionPoints ) : PCollection;
{ wich is not cliping }
 var
   i, j, flg, count : integer;
   p1, p3, p2 : TConnectionPoint;
   cp, polygon1, c, c1 : PCollection;
 begin
   CP := PCollection.Create(1);
   result := CP;
   while tp.Count > 0 do
     begin
       p1 := tp[0];
       polygon1 := PCollection.Create(1);
//        polygon1.Insert( p1.Dot );
       polygon1.Insert( TDot1.Create( p1.x, p1.y ) );
       flag_continue := 0;
       asembl_pol12( p1, polygon1 );
       if flag_continue <> 0 then polygon1.Free else cp.Insert( polygon1 );
//       if flag_continue <> 0 then writeln('i can not asemblity polygons !!!');
       tp.AtDelete(0);
     end;
     (*
   for i := 0 to cp.Count-1 do for j := i+1 to cp.Count-1 do
      begin
         c1 := cp[i];
         c := cp[j];
         flg := 0;
         flg := polygon_in_polygon( c1, c );
         if flg = 1 then
           begin
             PCollection( cp[j] ).FreeAll;
             continue;
           end;
           {
         if flg = 2 then
           begin
             PCollection( segments[i] ).FreeAll;
             continue
           end;
//           }
       end;
   for i := cp.Count-1 downto 0 do
     begin
       c1 := cp[i];
       if c1.Count < 3 then cp.AtFree( i );
     end;
     *)
 end;

function intersection_interval_and_polygon_II( polygon, p1 : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
  var
    col, intervals, xx, yy : PCollection;
    i, j, intersect : integer;
    t, O, x, y : double;
    p : pointer;
    e :TEdge;
  begin
    xx := PCollection.Create(1);
    xx.insert( TDot1.Create( x1, y1 ) );
    xx.insert( TDot1.Create( x2, y2 ) );
    for i := 0 to polygon.count-1 do
     if ( i = polygon.count-1 ) then
       begin
         if ( Distance(x1,y1,x2,y2) < 1.0E-7 ) or
            ( Distance( TDot1( polygon[i] ).x,TDot1( polygon[i] ).y,
                        TDot1( polygon[0] ).x,TDot1( polygon[0] ).y ) < 1.0E-7 ) then continue;
         intersect := intersection_straight_lines( x1, y1, x2, y2,
                 TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                 TDot1( polygon[polygon.count-1] ).x,
                 TDot1( polygon[polygon.count-1] ).y, t, O );
         if ( abs( t ) < 1.5 ) and ( abs( O ) < 1.5 ) then
{
          if ( ( intersect = 1 ) and ( round( 1000000000000000000 * t ) >= 0 ) and ( round( 1000000000000000000 * t ) <= 1000000000000000000 )
                and ( round( 1000000000000000000 * O ) >= 0 ) and ( round( 1000000000000000000 * O ) <= 1000000000000000000 ) )
//}
//{
          if ( ( intersect = 1 ) and ( round( 1000000000 * t ) >= 0 ) and ( round( 1000000000 * t ) <= 1000000000 )
                and ( round( 1000000000 * O ) >= 0 ) and ( round( 1000000000 * O ) <= 1000000000 ) )
//}
           then xx.AtInsert( xx.Count-1, TDot1.Create( x1 + ( x2 - x1 ) * O,
                                                      y1 + ( y2 - y1 ) * O ) );
         if intersect = 0 then
           begin
             col := clip_two_intervals( x1, y1, x2, y2, TDot1( polygon[0] ).x,
                       TDot1( polygon[0] ).y, TDot1( polygon[polygon.count-1] ).x,
                       TDot1( polygon[polygon.count-1] ).y );
             if col.Count > 0 then
               begin
                 for j := 0 to col.Count-1 do xx.AtInsert( xx.Count-1, col[j] );
                 col.DeleteAll;
               end;
             col.Free;
           end;
       end
      else
       begin
         if ( Distance(x1,y1,x2,y2) < 1.0E-7 ) or
            ( Distance( TDot1( polygon[i] ).x,TDot1( polygon[i] ).y,
                        TDot1( polygon[i+1] ).x,TDot1( polygon[i+1] ).y ) < 1.0E-7 ) then continue;
         intersect := intersection_straight_lines( x1, y1, x2, y2,
                 TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                 TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y, t, O );
         if ( abs( t ) < 1.5 ) and ( abs( O ) < 1.5 ) then
{
          if ( ( intersect = 1 ) and ( round( 1000000000000000000 * t ) >= 0 ) and ( round( 1000000000000000000 * t ) <= 1000000000000000000 )
                and ( round( 1000000000000000000 * O ) >= 0 ) and ( round( 1000000000000000000 * O ) <= 1000000000000000000 ) )
//}
//{
          if ( ( intersect = 1 ) and ( round( 1000000000 * t ) >= 0 ) and ( round( 1000000000 * t ) <= 1000000000 )
                and ( round( 1000000000 * O ) >= 0 ) and ( round( 1000000000 * O ) <= 1000000000 ) )
//}
           then begin
           xx.AtInsert( xx.Count-1, TDot1.Create( x1 + ( x2 - x1 ) * O,
                                                      y1 + ( y2 - y1 ) * O ) );
                end;
         if intersect = 0 then
           begin
             col := clip_two_intervals( x1, y1, x2, y2,
                       TDot1( polygon[i] ).x, TDot1( polygon[i] ).y, TDot1( polygon[i+1] ).x,
                       TDot1( polygon[i+1] ).y );
             if col.Count > 0 then
               begin
                 for j := 0 to col.Count-1 do xx.AtInsert( xx.Count-1, col[j] );
                 col.DeleteAll;
               end;
             col.Free;
           end;
       end;
    for j := 0 to xx.count-1 do
      for i := j+1 to xx.count-1 do
       begin
        if Distance( x1, y1,
              TDot1( xx[j] ).x, TDot1( xx[j] ).y )
           < Distance( x1, y1,
                TDot1( xx[i] ).x, TDot1( xx[i] ).y ) then
          begin
            p := xx[i];
            xx[i] := xx[j];
            xx[j] := p;
          end;
       end;
    intervals := PCOllection.Create(1);
    for i := 1 to xx.count-1 do
      begin
        x := ( TDot1( xx[i-1] ).x + TDot1( xx[i] ).x ) / 2;
        y := ( TDot1( xx[i-1] ).y + TDot1( xx[i] ).y ) / 2;
        if ( point_and_polygon( x, y, polygon ) < 1 )  then
          begin
            e := TEdge.Create( TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
                                         TDot1( xx[i] ).x, TDot1( xx[i] ).y );
            intervals.Insert( e );
          end;
      end;
    xx.Free;
    Result := intervals;
  end;

function intervals_of_intersection_two_polygons_II( Polygon1,
            Polygon2 : PCollection ) : PCollection;
  var
    i, j : integer;
    xx, intervals : PCollection;
   f:textfile;
   e:tedge;
  begin
    intervals := PCollection.Create(1);
    Result := intervals;
    for i := 0 to polygon2.count-1 do
      begin
        if ( i = polygon2.count-1 ) then
          begin
          xx := intersection_interval_and_polygon_II( polygon1, polygon2,
                  TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                  TDot1( polygon2[0] ).x, TDot1( polygon2[0] ).y );
          end
         else
           begin
           xx := intersection_interval_and_polygon_II( polygon1,polygon2,
                   TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                   TDot1( polygon2[i+1] ).x, TDot1( polygon2[i+1] ).y );
           end;
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
    for i := 0 to polygon1.count-1 do
      begin
        if ( i = polygon1.count-1 ) then
          xx := intersection_interval_and_polygon( polygon2,
                  TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                  TDot1( polygon1[0] ).x, TDot1( polygon1[0] ).y )
         else
           xx := intersection_interval_and_polygon( polygon2,
                   TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                   TDot1( polygon1[i+1] ).x, TDot1( polygon1[i+1] ).y );
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
  end;

function CuttingOff_polygon_by_polygon( polygon1, polygon2 : PCollection )
  : PCollection;
 var
   i, flag, j, ind, count, counter : integer;
   e, e1 : TEdge;
   x_begin, x_end, y_begin, y_end, eps : double;
   intervals, polygon, polygons : PCollection;
   d : TDot1;
   cp : TConnectionPolygons2;
   TP : TConnectionPoints;
   p3, p1, p2 : TConnectionPoint;
 begin
   eps := 1.0E-7;
   intervals := intervals_of_intersection_two_polygons_II( polygon1, polygon2 );
   for i := intervals.count-1 downto 0 do
    begin
      e := intervals[i];
      if Distance( e.x1,e.y1, e.x2, e.y2 ) < 1.0E-7
       then intervals.AtFree( i );
    end;
   if intervals.Count > 2
    then begin
      TP := TConnectionPoints.Create(1);
      TP.Duplicates:=False;
      for i := 0 to intervals.Count-1 do
        begin
          e := intervals[i];
          TP.InsertEdge(
            TDot1.Create( e.x1, e.y1 ),
            TDot1.Create( e.x2, e.y2 )
          );
        end;
      cp := assembly_polygons( tp );
      polygons := PCollection.Create(1);
      for i := 0 to cp.Count-1 do
        begin
          polygon := cp[i];
          polygons.Insert( polygon );
        end;
      cp.DeleteAll;
      cp.Free;
      tp.Free;
      intervals.Free;
      Result := polygons;
    end
    else begin
      intervals.FreeAll;
      Result := intervals;
    end;
 end;

function point_on_quasipolygon_border( x, y : double; xx : PCollection;
        var j : integer ) : boolean;
  var
    i : integer;
    t, eps : double;
  begin
    Result := FALSE;
    eps := 1.0E-7;
    t := -10;
    j := -1;
    for i := 0 to xx.count-1 do
      begin
        if i = xx.count-1 then
          begin
           if ( TDot1(xx[i]).x <> TDot1(xx[0]).x ) and
              ( TDot1(xx[i]).y <> TDot1(xx[0]).y ) then
            if abs( (x-TDot1(xx[xx.count-1]).x)*(TDot1(xx[0]).y-
                                                TDot1(xx[xx.count-1]).y) -
                    (y-TDot1(xx[xx.count-1]).y)*(TDot1(xx[0]).x-
                                        TDot1(xx[xx.count-1]).x) ) < eps
             then begin
                    Result := TRUE;
                    if Result = TRUE then
                     if abs( (TDot1(xx[0]).y-TDot1(xx[xx.count-1]).y) ) < eps
                      then
                        t := (x-TDot1(xx[xx.count-1]).x) /
                                ( TDot1(xx[0]).x - TDot1(xx[xx.count-1]).x )
                      else
                        t := (y-TDot1(xx[xx.count-1]).y) /
                                ( TDot1(xx[0]).y - TDot1(xx[xx.count-1]).y);
                    break;
                  end;
          end
         else
           begin
           if ( TDot1(xx[i]).x <> TDot1(xx[i+1]).x ) and
              ( TDot1(xx[i]).y <> TDot1(xx[i+1]).y ) then
             if abs( (x-TDot1(xx[i]).x)*(TDot1(xx[i+1]).y-
                                                 TDot1(xx[i]).y) -
                     (y-TDot1(xx[i]).y)*(TDot1(xx[i+1]).x-
                                                 TDot1(xx[i]).x) ) < eps
              then begin
                     Result := TRUE;
                     if abs( (TDot1(xx[i]).y-TDot1(xx[i+1]).y) ) < eps
                       then
                         t := (x-TDot1(xx[i+1]).x)/(TDot1(xx[i]).x-
                                                          TDot1(xx[i+1]).x)
                       else
                         t := (y-TDot1(xx[i+1]).y)/(TDot1(xx[i]).y-
                                                          TDot1(xx[i+1]).y);
                     break;
                   end;
            end;
      end;
    if ( Round(t*1000) < 0 ) or ( Round(t*1000) > 1000  ) then Result := FALSE;
    if Result = TRUE then j := i;
 end;

procedure qu_qu( h, o : PCollection );
 var
   i, j : integer;
   c, c1 : PCollection;
 begin
   for i := 0 to h.Count-1 do
     begin
       c := h[i];
       for j := 0 to o.Count-1 do
         begin
            c1 := o[j];
            if ( abs( square_polygon( c ) - square_polygon( c1 ) ) < 0.01 ) and
               ( equality_two_polygons( c1, c ) = TRUE ) then c1.FreeAll;
         end;
     end;
   for i := o.Count-1 downto 0 do
     begin
       c := o[i];
       if c.Count < 3 then o.AtFree( i );
     end;
 end;

function pp( p1, p2 : PCollection ) : boolean;
 var
   i : integer;
   x, y : double;
   d1, d2 : TDot1;
 begin
   Result := TRUE;
   for i := 0 to p2.Count-1 do
     begin
       if i = p2.Count-1 then d2 := p2[0] else d2 := p2[i+1];
       d1 := p2[i];
       x := ( d1.x + d2.x ) / 2;
       y := ( d1.y + d2.y ) / 2;
       if point_and_polygon( x, y, p1 ) = 1 then
         begin
           Result := FALSE;
           Exit;
         end;
     end;
 end;

function mean_point_of_polygon( VAR x, y : double; pol : PCollection ) : boolean;
 var
   i : integer;
   intervals : PCollection;
   x1, x2, y1, y2, XMAX, xmin, ymax, ymin : double;
 begin
   Result := FALSE;
   x := 0;
   y := 0;
   x1 := XMin;
   y1 := ( YMin + YMax ) / 2;
   x2 := XMax;
   y2 := y1;
   intervals := intersection_interval_and_polygon( pol, x1, y1, x2, y2 );
   if intervals.Count > 0 then
     begin
       Result := TRUE;
       X := ( TEdge( intervals[0] ).x1 +  TEdge( intervals[0] ).x2 ) / 2;
       Y := ( TEdge( intervals[0] ).y1 +  TEdge( intervals[0] ).y2 ) / 2;
     end
    else Result := FALSE;
    Intervals.Free;
  end;

  (*
function intersection_interval_and_polygon_xx( polygon, zhur : PCollection;
                                 x1, y1, x2, y2 : double ) : PCollection;
  var
    intervals, xx, yy : PCollection;
    i, j, intersect : integer;
    t, O, x, y : double;
    p : pointer;
    pxy : Tpz;
  begin
    xx := PCollection.Create(1);
    Result := xx;
    xx.insert( TDot1.Create( x1, y1 ) );
    xx.insert( TDot1.Create( x2, y2 ) );
    for i := 0 to polygon.count-1 do
     if ( i = polygon.count-1 ) then
       begin
         intersect := intersection_straight_lines( x1, y1, x2, y2,
                 TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                 TDot1( polygon[polygon.count-1] ).x,
                 TDot1( polygon[polygon.count-1] ).y, t, O );
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
              and ( O >= 0 ) and ( O <= 1 ) ) then
         begin
           xx.AtInsert( xx.count-1, TDot1.Create( x1 + ( x2 - x1 ) * O,
                                                  y1 + ( y2 - y1 ) * O ) );
           zhur.Insert( Tpz.Create( x1 + ( x2 - x1 ) * O, y1 + ( y2 - y1 ) * O,
                  x1, y1, x2, y2, TDot1( polygon[0] ).x, TDot1( polygon[0] ).y,
                  TDot1( polygon[polygon.count-1] ).x,
                  TDot1( polygon[polygon.count-1] ).y ) );
         end;
       end
     else begin
         intersect := intersection_straight_lines( x1, y1, x2, y2,
                  TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                  TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y, t, O );
         if ( ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 )
               and ( O >= 0 ) and ( O <= 1 ) ) then
          begin
            xx.AtInsert( xx.count-1, TDot1.Create( x1 + ( x2 - x1 ) * O,
                                                   y1 + ( y2 - y1 ) * O ) );
            zhur.Insert( Tpz.Create( x1 + ( x2 - x1 ) * O, y1 + ( y2 - y1 ) * O,
                   x1, y1, x2, y2, TDot1( polygon[i] ).x, TDot1( polygon[i] ).y,
                   TDot1( polygon[i+1] ).x, TDot1( polygon[i+1] ).y ) );
          end;
     end; { esle. }
    for j := 1 to xx.count-2 do
      for i := 1 to xx.count-2 do
        if Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
              TDot1( xx[j] ).x, TDot1( xx[j] ).y )
            < Distance( TDot1( xx[0] ).x, TDot1( xx[0] ).y,
                TDot1( xx[i] ).x, TDot1( xx[i] ).y ) then
          begin
            p := xx[i];
            xx[i] := xx[j];
            xx[j] := p;
          end;
    intervals := PCOllection.Create(1);
    for i := 1 to xx.count-1 do
      begin
        x := ( TDot1( xx[i-1] ).x + TDot1( xx[i] ).x ) / 2;
        y := ( TDot1( xx[i-1] ).y + TDot1( xx[i] ).y ) / 2;
        if ( point_and_polygon( x, y, polygon ) > -1 ) then  { -1!!! }
          intervals.Insert( TEdge.Create(
            TDot1( xx[i-1] ).x, TDot1( xx[i-1] ).y,
            TDot1( xx[i] ).x, TDot1( xx[i] ).y ) );
      end;
    xx.Free;
    Result := intervals;
  end;
    *)
    (*
function intervals_of_intersection_two_polygons_xx( Polygon1, Polygon2, zhur :
  PCollection ) : PCollection;
  var
    i, j : integer;
    xx, intervals : PCollection;
  begin
    intervals := PCollection.Create(1);
    Result := intervals;
    for i := 0 to polygon2.count-1 do
      begin
        xx := PCollection.Create(1);
        if ( i = polygon2.count-1 ) then
          xx := intersection_interval_and_polygon_xx( polygon1, zhur,
                  TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                  TDot1( polygon2[0] ).x, TDot1( polygon2[0] ).y )
         else
           xx := intersection_interval_and_polygon_xx( polygon1, zhur,
                   TDot1( polygon2[i] ).x, TDot1( polygon2[i] ).y,
                   TDot1( polygon2[i+1] ).x, TDot1( polygon2[i+1] ).y );
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
    for i := 0 to polygon1.count-1 do
      begin
        xx := PCollection.Create(1);
        if ( i = polygon1.count-1 ) then
          xx := intersection_interval_and_polygon( polygon2,
                  TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                  TDot1( polygon1[0] ).x, TDot1( polygon1[0] ).y )
         else
           xx := intersection_interval_and_polygon( polygon2,
                   TDot1( polygon1[i] ).x, TDot1( polygon1[i] ).y,
                   TDot1( polygon1[i+1] ).x, TDot1( polygon1[i+1] ).y );
        for j := 0 to xx.count-1 do intervals.Insert( xx[j] );
        xx.DeleteAll;
        xx.Free;
      end;
    Result := intervals;
  end;
*)
function communications_and_uchastok( uch, b, houses : PCollection;
 ccc : boolean ) : PCollection;
 var
   i, j, k, q, r, flg : integer;
//   pz1, pz2 : Tpz;
   res, a, aa, d, f, g, ff, res1, p1, p2, c, e : PCollection;
//   c, e : TConnectionPolygons2;
   fx:textfile;
 begin
   res := PCollection.Create(1);
   a := PCollection.Create(1);
   c := intersection_two_polygons( uch, b );
   if c.Count > 0 then
    for j := c.Count-1 downto 0 do
      begin
        d := c[j];
        if d.Count > 0 then
          begin
            d.insert( TDot1.Create( TDot1( d[0] ).x, TDot1( d[0] ).y ) );
            a.Insert( d )
          end
        else c.AtFree( j );
      end;
   c.DeleteAll;
   c.Free;
   if houses.Count = 0 then
     begin
       Result := a;
       Exit;
     end;
   for j := 0 to houses.Count-1 do
     begin
       d := houses[j];
       i := 0;
       if a.Count > 0 then
         repeat
           b := a[i];
           if b.Count > 0 then e := CuttingOff_polygon_by_polygon( d, b );
           if e.Count > 0 then
            for r := e.Count-1 downto 0 do
              begin
                f := e[r];
                if ( f.Count > 0 ) then
                  begin
                    f.insert( TDot1.Create( TDot1( f[0] ).x, TDot1( f[0] ).y ) );
                    res.Insert( f )
                  end
                else e.AtFree( r );
              end;
           e.DeleteAll;
           e.Free;
           i := i + 1;
         until i > a.count-1;
       if j < houses.Count-1 then
         begin
           a.FreeAll;
           a := res;
           res := PCollection.Create(1);
         end
       else a.Free;
     end;
{ ++++++++++++++++++++++++ <> ++++++++++++++++++++++ }
   if ccc then
     begin
       for i := 0 to res.Count-1 do
         begin
           a := res[i];
           e := Pcollection.Create(1);
           for j := 0 to a.Count-1 do e.Insert(
                         TDot1.Create( TDot1( a[j] ).x, TDot1( a[j] ).y ) );
           houses.Insert(e);
         end;
//         {
       for i := 0 to houses.Count-2 do
        for j := i+1 to houses.Count-1 do
          begin
            flg := polygon_in_polygon( houses[i], houses[j] );
            if flg = 1 then PCollection( houses[i] ).FreeAll;
            if flg = 2 then PCollection( houses[j] ).FreeAll;
          end;
          //}
       for i := houses.Count-1 downto 0 do
        if PCollection( houses[i] ).Count = 0 then houses.AtFree(i);
     end;
   Result := res;
 end;
 
{
function magazine_of_intersections( uch, houses, obrem : PCollection ) : PCollection;
 var
   res, c, col, house : PCollection;
   i, j : integer;
 begin
   res := PCollection.Create(1);
   for i := 0 to obrem.Count-1 do
     begin
       col := obrem[i];
       c := intervals_of_intersection_two_polygons_xx( uch, col, res );
       c.Free;
     end;
   for j := 0 to houses.Count-1 do
     begin
       house := houses[j];
       for i := 0 to obrem.Count-1 do
         begin
           col := obrem[i];
           c := intervals_of_intersection_two_polygons_xx( house, col, res );
           c.Free;
         end;
     end;
   Result := res;
 end;
}
function communication_and_uchastok( uch, b : PCollection ) : PCollection;
 var
   i, j, k, q, r, flg : integer;
//   pz1, pz2 : Tpz;
   res, a, aa,  c, d, e, f, g, ff, res1, p1, p2 : PCollection;
 begin
   a := PCollection.Create(1);
   c := intersection_two_polygons( uch, b );
   if c.Count > 0 then
    for j := c.Count-1 downto 0 do
      begin
        d := c[j];
        if d.Count > 0 then
          begin
            d.insert( TDot1.Create( TDot1( d[0] ).x, TDot1( d[0] ).y ) );
            a.Insert( d )
          end
        else c.AtFree( j );
      end;
   c.DeleteAll;
   c.Free;
   Result := a;
 end;
 
function equality_2_polygons( p1, p2 : PCollection ) : boolean;
 var
   i, j, flg : integer;
   d1, d2 : TDot1;
 begin
   result := true;
   for i := 0 to p1.Count-1 do
     begin
       d1 := p1[i];
       flg := 0;
       for j := 0 to p2.Count-1 do
         begin
           d2 := p2[j];
           if Distance( d1.x, d1.y, d2.x, d2.y ) < 1.0E-7 then
             begin
               flg := 1;
               break;
             end;
         end;
       if flg = 0 then
         begin
           result := false;
           exit;
         end;
     end;
 end;

end.
