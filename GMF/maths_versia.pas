unit maths_versia;

interface
 uses collect, maths_basic, types_dimano, intervals, polygons, types2;
 
 procedure solve_point_on_polyline( polyline : PCollection; s : double;
                                    var x, y : double );
 { Процедура вычисляет координаты точки находящейся на ломанной линии,
   путь до которой по ломанной равен s. }
 function ovragi( polyline, polygon : PCollection; s, xx : double )
   : PCollection;
 { Функция создает коллекцию перпендикулярных отрезков по ломаной линии с
   начальным смещением xx и с шагом s, начала которых находится на ломанной,
   а концы отсекаются многоугольником. }
 function solving_point_on_polyline( polyline : PCollection; s : double;
                                     var x, y : double ) : integer;
 { Функция вычисляет координаты точки находящейся на ломанной линии,
   путь до которой по ломанной равен s и возвращает номер вершины после
   которой располагается вычисленная точка. }
 function parallel_twig( polyline : PCollection; s : double;
   x_0, y_0 : double ) : PCollection;
 { Функция создает параллельную ломанную линию заданной ломанной на
   расстоянии s со стороны точки (x_0,y_0). }
 function parallel_twig_II( polyline : PCollection; s, s1, x_0, y_0 : double )
   : PCollection;
 { Функция создает две параллельных ломанных линии для заданной ломанной на
   расстоянии s со стороны точки (x_0,y_0) и еще одну ломанную линию
   на расстоянии s1 с противоположной стороны. }
 function parallel_twig_III( polyline : PCollection; s, x_0, y_0 : double ) : PCollection;
 { Функция создает параллельную ломанную линию для заданной ломанной на
   расстоянии s со стороны точки (x_0,y_0) }
 function ovragi2( polyline : PCollection;
   s, lenght_perp, xx, x0, y0 : double ) : PCollection;
 { Функция создает коллекцию отрезков заданной длины lenght_perp с шагом
   s и начальным смещением xx по ломанной со стороны точки (x0,y0). }
 procedure gosha_mude( x1, y1, x2, y2, alfa, s : double; var x, y : double );
  { ha-ha! It is jest. Функция считает отвязку. }
 function perpendicular_on_polyline( polyline : PCollection;
    s, lenght_perp, x0, y0 : double; var x1, y1, x2, y2 : double ) : boolean;
 function min_dist_up_to_polyline( p : PCollection; x, y : double;
                                   var vertexs_number : integer ) : double;
 function min_dist_up_to_polyline1( p : PCollection; x, y : double; var
                                    vertexs_number, flag : integer ) : double;
 function intersection_polylines( p1, p2 : PCollection ) : Pcollection;
 { ??? функции к динамике }
 function intersection_two_twigolygons( P1, P2 : PCollection ) : PCollection;
 procedure zasechka( x1, y1, x2, y2, alfa, s : double; var x, y : double );
 procedure zasechka2( x1, y1, x2, y2, alfa, s : double; var x, y : double );

implementation

procedure solve_point_on_polyline( polyline : PCollection; s : double;
                                   var x, y : double );
 var
   i : integer;
   dist, aux_dist, alfa : double;
 begin
   dist := 0;
   for i := 0 to polyline.Count-2 do
     begin
       aux_dist := Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                             TDot1( polyline[i+1] ).x, TDot1( polyline[i+1] ).y );
       if ( s > ( dist + aux_dist ) ) then dist := dist + aux_dist
        else
          begin
            alfa := direct_angle( TDot1( polyline[i] ).y, TDot1( polyline[i] ).x,
                        TDot1( polyline[i+1] ).y, TDot1( polyline[i+1] ).x );
            x := TDot1( polyline[i] ).x + ( s - dist ) * sin( alfa );
            y := TDot1( polyline[i] ).y + ( s - dist ) * cos( alfa );
            break;
          end;
     end;
 end;

function solving_point_on_polyline( polyline : PCollection; s : double;
                                    var x, y : double ) : integer;
 var
   i : integer;
   dist, aux_dist, alfa : double;
 begin
   dist := 0;
   Result := -1;
   for i := 0 to polyline.Count-2 do
     begin
       aux_dist := Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                             TDot1( polyline[i+1] ).x, TDot1( polyline[i+1] ).y );
       if ( s > ( dist + aux_dist ) ) then dist := dist + aux_dist else
         begin
           alfa := direct_angle( TDot1( polyline[i] ).y, TDot1( polyline[i] ).x,
                          TDot1( polyline[i+1] ).y, TDot1( polyline[i+1] ).x );
           x := TDot1( polyline[i] ).x + ( s - dist ) * sin( alfa );
           y := TDot1( polyline[i] ).y + ( s - dist ) * cos( alfa );
           Result := i;
           break;
         end;
     end;
 end;

function ovragi( polyline, polygon : PCollection; s, xx : double ) : PCollection;
 var
   i, flag, j,k : integer;
   x, y, ss, a, b, c, aa, bb, cc, dist, t_0, t, O : double;
   a1, b1, c1, a2, b2, c2, a3, b3, c3, x_e, y_e : double;
   col, res : PCollection;
   edge : TEdge;
 begin   { первая и последняя вершины в polygon совпадают }
   res := PCollection.Create(1);
   col := PCollection.Create(1);
   Dist := 0;
   for i := 0 to polyline.Count-2 do
     dist := dist + Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
       TDot1( polyline[i+1] ).x, TDot1( polyline[i+1] ).y );
   ss := xx;                             
   repeat
     flag := solving_point_on_polyline( polyline, ss, x, y );
     if flag > -1 then
       begin
         a1 := TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y;
         b1 := TDot1( polyline[flag] ).x - TDot1( polyline[flag+1] ).x;
         c1 := TDot1( polyline[flag] ).y * ( TDot1( polyline[flag+1] ).x -
               TDot1( polyline[flag] ).x ) - TDot1( polyline[flag] ).x *
               ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y );
         a2 := -b1;
         b2 := a1;
         c2 := - a2 * x - b2 * y;
         for j := 0 to polygon.Count-2 do
           begin
             a3 := TDot1( polygon[j+1] ).y - TDot1( polygon[j] ).y;
             b3 := TDot1( polygon[j] ).x - TDot1( polygon[j+1] ).x;
             c3 := TDot1( polygon[j] ).y * ( TDot1( polygon[j+1] ).x -
                   TDot1( polygon[j] ).x ) - TDot1( polygon[j] ).x *
                   ( TDot1( polygon[j+1] ).y - TDot1( polygon[j] ).y );
             if intersection_two_straight_lines(
                  a3, b3, c3, a2, b2, c2, x_e, y_e ) = TRUE then
               begin
                 edge := TEdge.Create(
                           TDot1( polygon[j] ).x, TDot1( polygon[j] ).y,
                           TDot1( polygon[j+1] ).x, TDot1( polygon[j+1] ).y );
                 if point_on_edge( x_e, y_e, edge ) = TRUE then
                   begin
                     col := intersection_interval_and_polygon( polygon,
                                  x, y, x_e, y_e );
                     if col.Count > 0 then
                     for k := 0 to col.count-1 do
                      if ( Distance( TEdge( col[k] ).x1, TEdge( col[k] ).y1,
                                   TEdge( col[k] ).x2, TEdge( col[k] ).y2 )
                         > 1.0e-5 ) then
                      if ( ( abs(x-TEdge( col[k] ).x1) < 1.0E-3 )and
                           ( abs(y-TEdge( col[k] ).y1) < 1.0E-3 ) )
                      or ( ( abs(x-TEdge( col[k] ).x2) < 1.0E-3 )and
                           ( abs(y-TEdge( col[k] ).y2) < 1.0E-3 ) ) then
                        begin
                          res.Insert( TEdge.Create(
                              TEdge( col[k] ).x1, TEdge( col[k] ).y1,
                              TEdge( col[k] ).x2, TEdge( col[k] ).y2 ) );
                          break;
                        end;
                     col.FreeAll;
                   end;
               end;
           end;
       end;
     ss := ss + s;
   until ss > dist;
   i := res.Count-1;
   repeat
     j := res.Count-1;
     repeat
       if j < i then
        if ( TEdge( res[j] ).x1 = TEdge( res[i] ).x1 ) and
           ( TEdge( res[j] ).y1 = TEdge( res[i] ).y1 ) and
           ( TEdge( res[j] ).x2 = TEdge( res[i] ).x2 ) and
           ( TEdge( res[j] ).y2 = TEdge( res[i] ).y2 )
         then begin
                res.AtFree( j ); {?????????}
                i := i - 1;
              end;
       j := j - 1;
     until j < 0;
     i := i - 1;
   until i < 0;
   Result := res;
   col.Free;
 end;

function parallel_twig1( polyline : PCollection; s : double; x_0, y_0 : double;
                         var s1 : double ) : PCollection;
  var
    i, j, flag, sign : integer;
    new_polyline, pol : PCollection;
    a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4, x, y,
        x11, y11, s_min, square : double;
  begin
    new_polyline := PCollection.Create(1);
    Result := new_polyline;
    {}
    flag := 0;
    x11 := ( TDot1( polyline[0] ).x + TDot1( polyline[1] ).x ) / 2;
    y11 := ( TDot1( polyline[0] ).y + TDot1( polyline[1] ).y ) / 2;
    s_min := Distance( x_0, y_0, x11, y11 );
    for i := 1 to polyline.Count-2 do
      begin
        x11 := ( TDot1( polyline[i] ).x + TDot1( polyline[i+1] ).x ) / 2;
        y11 := ( TDot1( polyline[i] ).y + TDot1( polyline[i+1] ).y ) / 2;
        if s_min > Distance( x_0, y_0, x11, y11 ) then
          begin
            flag := i;
            s_min := Distance( x_0, y_0, x11, y11 );
          end;
      end;
    a1 := TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y;
    b1 := TDot1( polyline[flag] ).x - TDot1( polyline[flag+1] ).x;
    c1 := TDot1( polyline[flag] ).y * ( TDot1( polyline[flag+1] ).x -
          TDot1( polyline[flag] ).x ) - TDot1( polyline[flag] ).x *
          ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr( a1 ) + sqr( b1 ) );
    if abs( a2 ) > 1.0E-3 then
      begin
        y := 1;
        x := ( -c2 - b2 ) / a2;
      end
    else
      begin
        x := 1;
        y := ( -c2 - a2 ) / b2;
      end;
    if ( a1 * x_0 + b1 * y_0 + c1 ) * ( a1 * x + b1 * y + c1 ) < 0
     then s := -s else s1 := -s1;
    c2 := c1 + s * sqrt( sqr( a1 ) + sqr( b1 ) );
    {}
    a1 := TDot1( polyline[1] ).y - TDot1( polyline[0] ).y;
    b1 := TDot1( polyline[0] ).x - TDot1( polyline[1] ).x;
    c1 := TDot1( polyline[0] ).y *
             ( TDot1( polyline[1] ).x - TDot1( polyline[0] ).x )
          - TDot1( polyline[0] ).x *
              ( TDot1( polyline[1] ).y - TDot1( polyline[0] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
    a3 := b1;
    b3 := - a1;
    c3 := - a3 * TDot1( polyline[0] ).x - b3 * TDot1( polyline[0] ).y;
    if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2, x, y ) = TRUE then
     new_polyline.insert( TDot1.Create( x, y ) );
      {}
    if polyline.Count = 2 then
      begin
        c3 := - a3 * TDot1( polyline[1] ).x - b3 * TDot1( polyline[1] ).y;
        if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2, x, y ) = TRUE then
         new_polyline.insert( TDot1.Create( x, y ) );
        Result := new_polyline;
        Exit;
      end;
    for i := 0 to polyline.Count-3 do
      begin
        a1 := TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y;
        b1 := TDot1( polyline[i] ).x - TDot1( polyline[i+1] ).x;
        c1 := TDot1( polyline[i] ).y *
                ( TDot1( polyline[i+1] ).x - TDot1( polyline[i] ).x )
              - TDot1( polyline[i] ).x *
                  ( TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y );
        a3 := TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y;
        b3 := TDot1( polyline[i+1] ).x - TDot1( polyline[i+2] ).x;
        c3 := TDot1( polyline[i+1] ).y *
                ( TDot1( polyline[i+2] ).x - TDot1( polyline[i+1] ).x )
              - TDot1( polyline[i+1] ).x *
                 ( TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y );
        a2 := a1;
        b2 := b1;
        c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
        a4 := a3;
        b4 := b3;
        c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
        if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
         if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y ) = TRUE
          then new_polyline.insert( TDot1.Create( x, y ) );
      end;
    {}
    i := polyline.Count-1;
    a3 := b4;
    b3 := - a4;
    c3 := - a3 * TDot1( polyline[i] ).x - b3 * TDot1( polyline[i] ).y;
    if intersection_two_straight_lines( a3, b3, c3, a4, b4, c4, x, y ) = TRUE
     then new_polyline.insert( TDot1.Create( x, y ) );
    {}
    if Distance( TDot1( polyline[0] ).x, TDot1( polyline[0] ).y,
                 TDot1( polyline[polyline.Count-1] ).x,
                 TDot1( polyline[polyline.Count-1] ).y ) < 1.0E-2
     then begin
            i := polyline.Count-1;
            a3 := b4;
            b3 := - a4;
            c3 := - a3 * TDot1( polyline[i] ).x - b3 * TDot1( polyline[i] ).y;
            if intersection_two_straight_lines( a3, b3, c3, a4, b4, c4, x, y )= TRUE then
            new_polyline.insert( TDot1.Create( x, y ) );
          end;
  end;

function parallel_twig2( polyline : PCollection; s : double; x_0, y_0 : double;
                         var s1 : double ) : PCollection;
  var
    i, j, flag, sign : integer;
    new_polyline : PCollection;
    a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4, x, y,
        x11, y11, s_min, square : double;
  begin
    new_polyline := PCollection.Create(1);
    sign := orientation_of_polygon( polyline, square );
    if point_and_polygon( x_0, y_0, polyline ) = 1
     then begin
            s := -sign * s;
            s1 := sign * s1;
          end
     else begin
            s1 := -sign * s1;
            s := sign * s;
          end;
    {}
    for i := 0 to polyline.Count-3 do
      begin
        a1 := TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y;
        b1 := TDot1( polyline[i] ).x - TDot1( polyline[i+1] ).x;
        c1 := TDot1( polyline[i] ).y * ( TDot1( polyline[i+1] ).x -
              TDot1( polyline[i] ).x ) - TDot1( polyline[i] ).x *
              ( TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y );
        a3 := TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y;
        b3 := TDot1( polyline[i+1] ).x - TDot1( polyline[i+2] ).x;
        c3 := TDot1( polyline[i+1] ).y * ( TDot1( polyline[i+2] ).x -
              TDot1( polyline[i+1] ).x ) - TDot1( polyline[i+1] ).x *
              ( TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y );
        a2 := a1;
        b2 := b1;
        c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
        a4 := a3;
        b4 := b3;
        c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
        if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
         if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
             = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
      end;
    {}
    a1 := TDot1( polyline[1] ).y - TDot1( polyline[0] ).y;
    b1 := TDot1( polyline[0] ).x - TDot1( polyline[1] ).x;
    c1 := TDot1( polyline[0] ).y * ( TDot1( polyline[1] ).x -
          TDot1( polyline[0] ).x ) - TDot1( polyline[0] ).x *
          ( TDot1( polyline[1] ).y - TDot1( polyline[0] ).y );
    i := polyline.Count-1;
    a3 := TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y;
    b3 := TDot1( polyline[i-1] ).x - TDot1( polyline[i] ).x;
    c3 := TDot1( polyline[i-1] ).y * ( TDot1( polyline[i] ).x -
          TDot1( polyline[i-1] ).x ) - TDot1( polyline[i-1] ).x *
          ( TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
    a4 := a3;
    b4 := b3;
    c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
    if abs ( a2 * b4 - b2 * a4 ) > 1.0E-2 then
     if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
         = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
    {}
    new_polyline.Insert( TDot1.Create( TDot1( new_polyline[0] ).x,
                                            TDot1( new_polyline[0] ).y ) );
    Result := new_polyline;
  end;

function parallel_twig( polyline : PCollection; s, x_0, y_0 : double )
   : PCollection;
  var
    i : integer;
    err : PCollection;
    s1 : double;
  begin
    s1 := 0;
    if polyline.Count > 1 then
      begin
        if Distance( TDot1( polyline[0] ).x, TDot1( polyline[0] ).y,
                     TDot1( polyline[polyline.Count-1] ).x,
                     TDot1( polyline[polyline.Count-1] ).y ) < 1.0E-2
         then begin
                for i := polyline.Count-1 downto 1 do
                 if Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                              TDot1( polyline[i-1] ).x, TDot1( polyline[i-1] ).y ) < 1.0e-4
                  then Polyline.AtFree(i);
                Result := parallel_twig2( polyline, s, x_0, y_0, s1 )
              end
         else begin
                for i := polyline.Count-1 downto 1 do
                 if Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                              TDot1( polyline[i-1] ).x, TDot1( polyline[i-1] ).y ) < 1.0e-4
                  then Polyline.AtFree(i);
                Result := parallel_twig1( polyline, s, x_0, y_0, s1 );
              end;
      end
    else begin
           err := PCollection.Create(1);
           Result := err;
         end;
  end;

function parallel_twig3( polyline : PCollection; s : double ) : PCollection;
  var
    i, j, flag : integer;
    new_polyline : PCollection;
    a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4, x, y,
        x11, y11, s_min : double;
  begin
    new_polyline := PCollection.Create(1);
    a1 := TDot1( polyline[1] ).y - TDot1( polyline[0] ).y;
    b1 := TDot1( polyline[0] ).x - TDot1( polyline[1] ).x;
    c1 := TDot1( polyline[0] ).y *
             ( TDot1( polyline[1] ).x - TDot1( polyline[0] ).x )
          - TDot1( polyline[0] ).x *
              ( TDot1( polyline[1] ).y - TDot1( polyline[0] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
    a3 := b1;
    b3 := - a1;
    c3 := - a3 * TDot1( polyline[0] ).x - b3 * TDot1( polyline[0] ).y;
    if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2, x, y ) = TRUE
     then new_polyline.insert( TDot1.Create( x, y ) );
    if polyline.Count = 2 then
      begin
        c3 := - a3 * TDot1( polyline[1] ).x - b3 * TDot1( polyline[1] ).y;
        if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2, x, y ) = TRUE
         then new_polyline.insert( TDot1.Create( x, y ) );
        Result := new_polyline;
        Exit;
      end;
    for i := 0 to polyline.Count-3 do
      begin
        a1 := TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y;
        b1 := TDot1( polyline[i] ).x - TDot1( polyline[i+1] ).x;
        c1 := TDot1( polyline[i] ).y *
                ( TDot1( polyline[i+1] ).x - TDot1( polyline[i] ).x )
              - TDot1( polyline[i] ).x *
                  ( TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y );
        a3 := TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y;
        b3 := TDot1( polyline[i+1] ).x - TDot1( polyline[i+2] ).x;
        c3 := TDot1( polyline[i+1] ).y *
                ( TDot1( polyline[i+2] ).x - TDot1( polyline[i+1] ).x )
              - TDot1( polyline[i+1] ).x *
                 ( TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y );
        a2 := a1;
        b2 := b1;
        c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
        a4 := a3;
        b4 := b3;
        c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
        if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
         if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
             = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
      end;
    {}
    i := polyline.Count-1;
    a3 := b4;
    b3 := - a4;
    c3 := - a3 * TDot1( polyline[i] ).x - b3 * TDot1( polyline[i] ).y;
    if intersection_two_straight_lines( a3, b3, c3, a4, b4, c4, x, y ) = TRUE
     then new_polyline.insert( TDot1.Create( x, y ) );
    {}
    if Distance( TDot1( polyline[0] ).x, TDot1( polyline[0] ).y,
                 TDot1( polyline[polyline.Count-1] ).x,
                 TDot1( polyline[polyline.Count-1] ).y ) < 1.0E-2
     then begin
            i := polyline.Count-1;
            a3 := b4;
            b3 := - a4;
            c3 := - a3 * TDot1( polyline[i] ).x - b3 * TDot1( polyline[i] ).y;
            if intersection_two_straight_lines( a3, b3, c3, a4, b4, c4, x, y )
                = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
          end;
    {}
    Result := new_polyline;
  end;

function parallel_twig4( polyline : PCollection; s : double ) : PCollection;
  var
    i, j, flag : integer;
    new_polyline : PCollection;
    a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4, x, y,
        x11, y11, s_min : double;
  begin
    new_polyline := PCollection.Create(1);
    if polyline.Count < 3 then
      begin
        Result := new_polyline;
        Exit;
      end;
    for i := 0 to polyline.Count-3 do
      begin
        a1 := TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y;
        b1 := TDot1( polyline[i] ).x - TDot1( polyline[i+1] ).x;
        c1 := TDot1( polyline[i] ).y * ( TDot1( polyline[i+1] ).x -
              TDot1( polyline[i] ).x ) - TDot1( polyline[i] ).x *
              ( TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y );
        a3 := TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y;
        b3 := TDot1( polyline[i+1] ).x - TDot1( polyline[i+2] ).x;
        c3 := TDot1( polyline[i+1] ).y * ( TDot1( polyline[i+2] ).x -
              TDot1( polyline[i+1] ).x ) - TDot1( polyline[i+1] ).x *
              ( TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y );
        a2 := a1;
        b2 := b1;
        c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
        a4 := a3;
        b4 := b3;
        c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
        if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
         if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
             = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
      end;
    {}
    a1 := TDot1( polyline[1] ).y - TDot1( polyline[0] ).y;
    b1 := TDot1( polyline[0] ).x - TDot1( polyline[1] ).x;
    c1 := TDot1( polyline[0] ).y * ( TDot1( polyline[1] ).x -
          TDot1( polyline[0] ).x ) - TDot1( polyline[0] ).x *
          ( TDot1( polyline[1] ).y - TDot1( polyline[0] ).y );
    i := polyline.Count-1;
    a3 := TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y;
    b3 := TDot1( polyline[i-1] ).x - TDot1( polyline[i] ).x;
    c3 := TDot1( polyline[i-1] ).y * ( TDot1( polyline[i] ).x -
          TDot1( polyline[i-1] ).x ) - TDot1( polyline[i-1] ).x *
          ( TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
    a4 := a3;
    b4 := b3;
    c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
    if abs ( a2 * b4 - b2 * a4 ) > 1.0E-2 then
     if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
         = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
    new_polyline.Insert( TDot1.Create( TDot1( new_polyline[0] ).x,
                                            TDot1( new_polyline[0] ).y ) );
    Result := new_polyline;
  end;

function parallel_twig_II( polyline : PCollection; s, s1, x_0, y_0 : double )
   : PCollection;
  var
    pl1, pl2, res : PCollection;
    i : integer;
  begin
    res := PCollection.Create(1);
    if polyline.Count > 1 then
      begin
        if Distance( TDot1( polyline[0] ).x, TDot1( polyline[0] ).y,
                     TDot1( polyline[polyline.Count-1] ).x,
                     TDot1( polyline[polyline.Count-1] ).y ) < 1.0E-2
         then begin
                for i := polyline.Count-1 downto 1 do
                 if Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                              TDot1( polyline[i-1] ).x, TDot1( polyline[i-1] ).y ) < 1.0e-4
                  then Polyline.AtFree(i);
                pl1 := parallel_twig2( polyline, s, x_0, y_0, s1 );
                res.Insert( pl1 );
                pl2 := parallel_twig4( polyline, s1 );
                res.Insert( pl2 );
                Result := res;
              end
         else begin
                for i := polyline.Count-1 downto 1 do
                 if Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
                              TDot1( polyline[i-1] ).x, TDot1( polyline[i-1] ).y ) < 1.0e-4
                  then Polyline.AtFree(i);
                pl1 := parallel_twig1( polyline, s, x_0, y_0, s1 );
                res.Insert( pl1 );
                pl2 := parallel_twig3( polyline, s1 );
                res.Insert( pl2 );
                Result := res;
              end;
      end
     else Result := res;
  end;

function parallel_twig_III( polyline : PCollection; s, x_0, y_0 : double )
 : PCollection;
  var
    i, j, flag, sign : integer;
    new_polyline : PCollection;
    a1, b1, c1, a2, b2, c2, a3, b3, c3, a4, b4, c4, x, y,
        x11, y11, s_min, square : double;
  begin
    new_polyline := PCollection.Create(1);
    sign := -orientation_of_polygon( polyline, square );
    if point_and_polygon( x_0, y_0, polyline ) = -1 then s := -sign * s;
    {}
    for i := 0 to polyline.Count-3 do
      begin
        a1 := TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y;
        b1 := TDot1( polyline[i] ).x - TDot1( polyline[i+1] ).x;
        c1 := TDot1( polyline[i] ).y * ( TDot1( polyline[i+1] ).x -
              TDot1( polyline[i] ).x ) - TDot1( polyline[i] ).x *
              ( TDot1( polyline[i+1] ).y - TDot1( polyline[i] ).y );
        a3 := TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y;
        b3 := TDot1( polyline[i+1] ).x - TDot1( polyline[i+2] ).x;
        c3 := TDot1( polyline[i+1] ).y * ( TDot1( polyline[i+2] ).x -
              TDot1( polyline[i+1] ).x ) - TDot1( polyline[i+1] ).x *
              ( TDot1( polyline[i+2] ).y - TDot1( polyline[i+1] ).y );
        a2 := a1;
        b2 := b1;
        c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
        a4 := a3;
        b4 := b3;
        c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
        if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
          begin
            if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
                 = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
          end
        else
          begin
            a4 := b2;
            b4 := -a2;
            c4 := -a4 * TDot1( polyline[i+1] ).x - b4 * TDot1( polyline[i+1] ).y;
            if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
                 = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
          end;
      end;
    {}
    a1 := TDot1( polyline[1] ).y - TDot1( polyline[0] ).y;
    b1 := TDot1( polyline[0] ).x - TDot1( polyline[1] ).x;
    c1 := TDot1( polyline[0] ).y * ( TDot1( polyline[1] ).x -
          TDot1( polyline[0] ).x ) - TDot1( polyline[0] ).x *
          ( TDot1( polyline[1] ).y - TDot1( polyline[0] ).y );
    i := polyline.Count-1;
    a3 := TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y;
    b3 := TDot1( polyline[i-1] ).x - TDot1( polyline[i] ).x;
    c3 := TDot1( polyline[i-1] ).y * ( TDot1( polyline[i] ).x -
          TDot1( polyline[i-1] ).x ) - TDot1( polyline[i-1] ).x *
          ( TDot1( polyline[i] ).y - TDot1( polyline[i-1] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + s * sqrt( sqr(a1 ) + sqr( b1 ) );
    a4 := a3;
    b4 := b3;
    c4 := c3 + s * sqrt( sqr(a3 ) + sqr( b3 ) );
    if abs ( a2 * b4 - b2 * a4 ) > 1.0E-5 then
      begin
        if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
             = TRUE then new_polyline.insert( TDot1.Create( x, y ) );
      end
    else
      begin
        a4 := b2;
        b4 := -a2;
        c4 := -a4 * TDot1( polyline[i+1] ).x - b4 * TDot1( polyline[i+1] ).y;
        if intersection_two_straight_lines( a2, b2, c2, a4, b4, c4, x, y )
             = TRUE then new_polyline.insert( TDot1.Create( x, y ) )
      end;
    {}
    new_polyline.Insert( TDot1.Create( TDot1( new_polyline[0] ).x,
                                       TDot1( new_polyline[0] ).y ) );
    Result := new_polyline;
  end;

function ovragi2( polyline : PCollection;
    s, lenght_perp, xx, x0, y0 : double ) : PCollection;
 var
   i, flag, j : integer;
   x, y, ss, a, b, c, aa, bb, cc, dist, t_0, t, O, x11, y11, s_min,
      a1, b1, c1, a2, b2, c2, a3, b3, c3, x_e, y_e : double;
   col, res : PCollection;
   edge : TEdge;
 begin   { первая и последняя вершины в polygon совпадают }
   t_0 := 0.01;
   res := PCollection.Create(1);
   col := PCollection.Create(1);
   Dist := 0;
   for i := 0 to polyline.Count-2 do
     dist := dist + Distance( TDot1( polyline[i] ).x, TDot1( polyline[i] ).y,
       TDot1( polyline[i+1] ).x, TDot1( polyline[i+1] ).y );
   ss := xx;
   {}
    flag := 0;
    x11 := ( TDot1( polyline[0] ).x + TDot1( polyline[1] ).x ) / 2;
    y11 := ( TDot1( polyline[0] ).y + TDot1( polyline[1] ).y ) / 2;
    s_min := Distance( x0, y0, x11, y11 );
    for i := 1 to polyline.Count-2 do
      begin
        x11 := ( TDot1( polyline[i] ).x + TDot1( polyline[i+1] ).x ) / 2;
        y11 := ( TDot1( polyline[i] ).y + TDot1( polyline[i+1] ).y ) / 2;
        if s_min > Distance( x0, y0, x11, y11 ) then
          begin
            flag := i;
            s_min := Distance( x0, y0, x11, y11 );
          end;
      end;
    a1 := TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y;
    b1 := TDot1( polyline[flag] ).x - TDot1( polyline[flag+1] ).x;
    c1 := TDot1( polyline[flag] ).y * ( TDot1( polyline[flag+1] ).x -
          TDot1( polyline[flag] ).x ) - TDot1( polyline[flag] ).x *
          ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y );
    a2 := a1;
    b2 := b1;
    c2 := c1 + lenght_perp * sqrt( sqr( a1 ) + sqr( b1 ) );
    if abs( a2 ) > 1.0E-3 then
      begin
        y := 1;
        x := ( -c2 - b2 ) / a2;
      end
    else
      begin
        x := 1;
        y := ( -c2 - a2 ) / b2;
      end;
    if ( a1 * x0 + b1 * y0 + c1 ) * ( a1 * x + b1 * y + c1 ) < 0
     then lenght_perp := -lenght_perp;
   {}
   repeat
     flag := solving_point_on_polyline( polyline, ss, x, y );
     if flag > -1 then
       begin
         a1 := TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y;
         b1 := TDot1( polyline[flag] ).x - TDot1( polyline[flag+1] ).x;
         c1 := TDot1( polyline[flag] ).y * ( TDot1( polyline[flag+1] ).x -
               TDot1( polyline[flag] ).x ) - TDot1( polyline[flag] ).x *
               ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y );
         a2 := -b1;
         b2 := a1;
         c2 := - a2 * x - b2 * y;
         a3 := a1;
         b3 := b1;
         c3 := c1 + lenght_perp * sqrt( sqr(a1 ) + sqr( b1 ) );
         if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2,
            x_e, y_e ) = TRUE then res.insert(TEdge.Create( x, y, x_e, y_e ));
       end;
     ss := ss + s;
   until ss > dist;
   Result := res;
   col.Free;
 end;

procedure gosha_mude( x1, y1, x2, y2, alfa, s : double; var x, y : double );
 var
   a : double;
 begin
   a := direct_angle( x1, y1, x2, y2 ) + alfa;
   x := x1 + s * cos( a );
   y := y1 + s * sin( a );
 end;

procedure zasechka2( x1, y1, x2, y2, alfa, s : double; var x, y : double );
 var
   a : double;
 begin
   a := direct_angle( x2, y2, x1, y1 ) + abs( alfa );
   x := x2 + s * cos( abs( a ) );
   y := y2 + s * sin( abs( a ) );
   {
   writeln(':::::::::    ', a,' := ', direct_angle( x2, y2, x1, y1 ),' + ',abs( alfa ) );
   readln;
   }
 end;

procedure zasechka( x1, y1, x2, y2, alfa, s : double; var x, y : double );
 var
   a : double;
 begin
   a := direct_angle( y2, x2, y1, x1 ) - alfa;
   x := x1 + s * cos( -a );
   y := y1 + s * sin( -a );
 {
   a := direct_angle( y2, x2, y1, x1 ) + alfa;
   x := x1 + s * sin( -a );
   y := y1 + s * cos( -a );
   writeln('        ',x,y);
   x := x1 + s * sin( a );
   y := y1 + s * cos( a );
   writeln('        ',x,y);
   x := x1 - s * sin( a );
   y := y1 - s * cos( a );
   writeln('        ',x,y);
   x := x1 - s * sin( -a );
   y := y1 - s * cos( -a );
   writeln('??????????        ',x,y);
   x := x1 + s * cos( -a );
   y := y1 + s * sin( -a );
   writeln('        ',x,y);
   x := x1 + s * cos( a );
   y := y1 + s * sin( a );
   writeln('        ',x,y);
   x := x1 - s * cos( a );
   y := y1 - s * sin( a );
   writeln('        ',x,y);
   x := x1 - s * cos( -a );
   y := y1 - s * sin( -a );
   writeln('??????????        ',x,y);
   readln;
//   }
 end;

function perpendicular_on_polyline( polyline : PCollection;
    s, lenght_perp, x0, y0 : double; var x1, y1, x2, y2 : double ) : boolean;
 var
   flag2, i, flag, j : integer;
   xx, yy, ss, a, b, c, aa, bb, cc, dist, t_0, t, O, x11, y11, s_min,
      a1, b1, c1, a2, b2, c2, a3, b3, c3, x_e, y_e : double;
   col, res : PCollection;
   edge : TEdge;
 begin
   Result := FALSE;
   flag2 := solving_point_on_polyline( polyline, s, x1, y1 );
   if flag2 < 0 then Exit else Result := TRUE;
   { <<<<<<<<<<<<<<<< x0 and y0 >>>>>>>>>>>>>>>>>> }
   flag := 0;
   x11 := ( TDot1( polyline[0] ).x + TDot1( polyline[1] ).x ) / 2;
   y11 := ( TDot1( polyline[0] ).y + TDot1( polyline[1] ).y ) / 2;
   s_min := Distance( x0, y0, x11, y11 );
   for i := 1 to polyline.Count-2 do
     begin
       x11 := ( TDot1( polyline[i] ).x + TDot1( polyline[i+1] ).x ) / 2;
       y11 := ( TDot1( polyline[i] ).y + TDot1( polyline[i+1] ).y ) / 2;
       if s_min > Distance( x0, y0, x11, y11 ) then
         begin
           flag := i;
           s_min := Distance( x0, y0, x11, y11 );
         end;
     end;
               { -------------------- }
   a1 := TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y;
   b1 := TDot1( polyline[flag] ).x - TDot1( polyline[flag+1] ).x;
   c1 := TDot1( polyline[flag] ).y * ( TDot1( polyline[flag+1] ).x -
         TDot1( polyline[flag] ).x ) - TDot1( polyline[flag] ).x *
         ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag] ).y );
   a2 := a1;
   b2 := b1;
   c2 := c1 + lenght_perp * sqrt( sqr( a1 ) + sqr( b1 ) );
   if abs( a2 ) > 1.0E-3 then
     begin
       yy := 1;
       xx := ( -c2 - b2 ) / a2;
     end
   else
     begin
       xx := 1;
       yy := ( -c2 - a2 ) / b2;
     end;
   if ( a1 * x0 + b1 * y0 + c1 ) * ( a1 * xx + b1 * yy + c1 ) < 0
    then lenght_perp := -lenght_perp;
  { ============================================== }
  a1 := TDot1( polyline[flag2+1] ).y - TDot1( polyline[flag2] ).y;
  b1 := TDot1( polyline[flag2] ).x - TDot1( polyline[flag2+1] ).x;
  c1 := TDot1( polyline[flag2] ).y * ( TDot1( polyline[flag2+1] ).x -
        TDot1( polyline[flag2] ).x ) - TDot1( polyline[flag2] ).x *
        ( TDot1( polyline[flag+1] ).y - TDot1( polyline[flag2] ).y );
  a2 := -b1;
  b2 := a1;
  c2 := - a2 * x1 - b2 * y1;
  a3 := a1;
  b3 := b1;
  c3 := c1 + lenght_perp * sqrt( sqr(a1 ) + sqr( b1 ) );
  if intersection_two_straight_lines( a3, b3, c3, a2, b2, c2,
     x_e, y_e ) = TRUE then
    begin
      x2 := x_e;
      y2 := y_e;
    end;
 end;

function intersection_polylines( p1, p2 : PCollection ) : Pcollection;
 var
   p11, p12, p21, p22 : TDot1;
   i, j, k, intersect : integer;
   x, y, t, o : double;
   res : PCollection;
 begin
   res := PCollection.Create(1);
   Result := res;
   for i := 0 to p1.Count-2 do
     begin
       p11 := p1[i];
       p12 := p1[i+1];
       for j := 0 to p2.Count-2 do
         begin
           p21 := p2[j];
           p22 := p2[j+1];
           intersect := intersection_straight_lines( p11.x, p11.y, p12.x, p12.y,
                                             p21.x, p21.y, p22.x, p22.y, t, o );
           if ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 ) and
              ( O >= 0 ) and ( O <= 1 ) then
             begin
               x := p22.x + ( p21.x - p22.x ) * t;
               y := p22.y + ( p21.y - p22.y ) * t;
               res.Insert( TDot1.Create( x, y ) );
             end;
         end;
     end;
   Result := res;
 end;

procedure intersection_polylines_2( p1, p2 : PCollection );
 var
   p11, p12, p21, p22 : TDot1;
   i, j, k, r, q, intersect : integer;
   x, y, t, o : double;
   res, res1 : PCollection;
   p : pointer;
 begin
   i := 0;
   repeat
     res := PCollection.Create(1);
     res1 := PCollection.Create(1);
     p11 := p1[i];
     p12 := p1[i+1];
     j := 0;
     repeat
       p21 := p2[j];
       p22 := p2[j+1];
       intersect := intersection_straight_lines( p11.x, p11.y, p12.x, p12.y,
                                             p21.x, p21.y, p22.x, p22.y, t, O );
       if ( intersect = 1 ) and ( t >= 0 ) and ( t <= 1 ) and
          ( O >= 0 ) and ( O <= 1 ) then
         begin
           x := p21.x + ( p22.x - p21.x ) * t;
           y := p21.y + ( p22.y - p21.y ) * t;
           res.Insert( TDot1.Create( x, y ) );
           res1.Insert( TDot1.Create( x, y ) );
//           p2.AtInsert( j+1, TDot1.Create( x, y ) );
           j := j + 1;
         end;
       for r := 0 to res1.Count-1 do
        for q := r+1 to res1.Count-1 do
         if Distance( p21. x, p21.y, TDot1( res1[r] ).x, TDot1( res1[r] ).y ) <
            Distance( p21. x, p21.y, TDot1( res1[q] ).x, TDot1( res1[q] ).y ) then
           begin
             p := res1[r];
             res1[r] := res1[q];
             res1[q] := p;
           end;
       for q := 0 to res1.Count-1 do p2.AtInsert( j+1, res1[q] );
       j := j + 1 + res1.Count;
     until j > p2.Count-2;
     {}
     for r := 0 to res.Count-1 do
      for q := r+1 to res.Count-1 do
       if Distance( p11. x, p11.y, TDot1( res[r] ).x, TDot1( res[r] ).y ) <
          Distance( p11. x, p11.y, TDot1( res[q] ).x, TDot1( res[q] ).y ) then
         begin
           p := res[r];
           res[r] := res[q];
           res[q] := p;
         end;
     for q := 0 to res.Count-1 do p1.AtInsert( i+1, res[q] );
     i := i + 1 + res.Count;
   until i > p1.Count-2;
 end;

function min_dist_up_to_polyline1( p : PCollection; x, y : double; var
                                   vertexs_number, flag : integer ) : double;
 var
   i, flg1, flg2 : integer;
   sxx, spp, x11, y11, s_min, a1, b1, c1, a2, b2, c2 : double;
   ax, ay, bx, by, ab, lambda, delta : double;
   p1, p2 : TDot1;
 begin
   flag := 0;
   sxx := Distance( TDot1( p[0] ).x, TDot1( p[0] ).y, x, y );
   flg1 := 0;
   for i := 1 to p.Count-1 do
     begin
      x11 := Distance( TDot1( p[i] ).x, TDot1( p[i] ).y, x, y );
      if x11 < sxx then
        begin
          sxx := Distance( TDot1( p[0] ).x, TDot1( p[0] ).y, x, y );
          flg1 := i
        end;
     end; { min distance from vertex of polyline }
   p1 := p[0];
   p2 := p[1];
   ax := x - p1.x;
   ay := y - p1.y;
   bx := p2.x - p1.x;
   by := p2.y - p1.y;
   ab := ax * bx + ay * by;
   lambda := ab / ( bx*bx + by*by );
   if ( lambda >= 0 ) and ( lambda <= 1 ) then
     begin
       a1 := p2.y - p1.y;
       b1 := -p2.x + p1.x;
       c1 := -p1.x * a1 - p1.y * b1;
       delta := abs( a1 * x + b1 * y + c1 ) / sqrt( a1*a1 + b1*b1 );
       if delta < spp then spp := delta;
     end;
   for i := 1 to p.Count-2 do
     begin
       p1 := p[i];
       p2 := p[i+1];
       ax := x - p1.x;
       ay := y - p1.y;
       bx := p2.x - p1.x;
       by := p2.y - p1.y;
       ab := ax * bx + ay * by;
       lambda := ab / ( bx*bx + by*by );
       if ( lambda >= 0 ) and ( lambda <= 1 ) then
         begin
           a1 := p2.y - p1.y;
           b1 := -p2.x + p1.x;
           c1 := -p1.x * a1 - p1.y * b1;
           delta := abs( a1 * x + b1 * y + c1 ) / sqrt( a1*a1 + b1*b1 );
           if delta < spp then
             begin
               flg2 := i;
               spp := delta;
             end;
         end;
     end;
   if sxx < spp
    then begin
           flag := 1;
           vertexs_number := flg1;
           s_min := sxx;
         end
    else begin
           vertexs_number := flg2;
           s_min := spp;
         end;
   Result := s_min;
 end;

function min_dist_up_to_polyline( p : PCollection; x, y : double; var
                                  vertexs_number : integer ) : double;
 var
   flag, i, flg1, flg2 : integer;
   sxx, spp, x11, y11, s_min, a1, b1, c1, a2, b2, c2 : double;
   a, b : double;
   ax, ay, bx, by, ab, lambda, delta : double;
   p1, p2 : TDot1;
 begin
   flag := 0;
   spp := 1.0E+30;
   flg2 := 0;
   sxx := Distance( TDot1( p[0] ).x, TDot1( p[0] ).y, x, y );
   flg1 := 0;
   for i := 1 to p.Count-1 do
     begin
      x11 := Distance( TDot1( p[i] ).x, TDot1( p[i] ).y, x, y );
      if x11 < sxx then
        begin
//          sxx := Distance( TDot1( p[0] ).x, TDot1( p[0] ).y, x, y );
          flg1 := i;
          sxx := x11;
        end;
     end; { min distance from vertex of polyline }
   p1 := p[0];
   p2 := p[1];
   ax := x - p1.x;
   ay := y - p1.y;
   bx := p2.x - p1.x;
   by := p2.y - p1.y;
   ab := ax * bx + ay * by;
   a := sqrt( ax*ax + ay*ay );
   b := sqrt( bx*bx + by*by );
   if ( a > 0.0000001 ) and ( b > 0.0000001 ) then
     begin
       lambda := ab / sqrt( a*a * b*b );
       if ( lambda * a < b ) and ( lambda > 0 ) then
         begin
           a1 := p2.y - p1.y;
           b1 := -p2.x + p1.x;
           c1 := -p1.x * a1 - p1.y * b1;
           delta := abs( a1 * x + b1 * y + c1 ) / sqrt( a1*a1 + b1*b1 );
           spp := delta;
           flg2 := 0;
         end;
     end;
   for i := 1 to p.Count-2 do
     begin
       p1 := p[i];
       p2 := p[i+1];
       ax := x - p1.x;
       ay := y - p1.y;
       bx := p2.x - p1.x;
       by := p2.y - p1.y;
       ab := ax * bx + ay * by;
       a := sqrt( ax*ax + ay*ay );
       b := sqrt( bx*bx + by*by );
       if ( a > 0.0000001 ) and ( b > 0.0000001 ) then
         begin
           lambda := ab / sqrt( a*a * b*b );
           if ( lambda * a < b ) and ( lambda > 0 ) then
             begin
               a1 := p2.y - p1.y;
               b1 := -p2.x + p1.x;
               c1 := -p1.x * a1 - p1.y * b1;
               delta := abs( a1 * x + b1 * y + c1 ) / sqrt( a1*a1 + b1*b1 );
               if delta < spp then
                 begin
                   flg2 := i;
                   spp := delta;
                 end;
             end;
         end;
     end;
   if sxx < spp
    then begin
           flag := 1;
           vertexs_number := flg1;
           s_min := sxx;
         end
    else begin
           vertexs_number := flg2;
           s_min := spp;
         end;
         {
           vertexs_number := flg1;
           s_min := sxx;
          // }
   Result := s_min;
 end;

(* Twigoligon is polygon, consisting not from pieces, and from polyline.
   This polylines are directed all to one party, that is the end of the first
   polyline coincides with the beginning second. *)
function point_on_twigolygon_border( x, y : double; p : PCollection )
  : boolean;
  var
    i, j : integer;
    t, eps, epsilon, x1, y1 : double;
    xx : PCollection;
  begin
    Result := FALSE;
    t := 0;
    eps := 1.0E-5;
    epsilon := 1.0E-5;
{}
    for j := 0 to p.Count-1 do
      begin
        xx := p[j];
        for i := 0 to xx.count-2 do
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
                      if ( Round(t*1000) >= 0 ) and ( Round(t*1000) <= 1000 )
                       then begin
                              Result := TRUE;
                              Exit;
                            end;
                    end;
            end;
   end;
 end;

function point_and_twigolygon( x, y : double; tl : PCollection ) : integer;
 var
   i, j, k, c, intersect, q : integer;
   x1, y1, t, o : double;
   p1, p2 : TDot1;
   p, xx : PCollection;
 begin
   Result := -1;
   t := 0;
   O := 0;
   if point_on_twigolygon_border( x, y, tl ) = TRUE
    then begin Result := 0;
               Exit;
         end;
   p := PCollection.Create(1);
   for i := 0 to tl.Count-1 do
     begin
       xx := tl[i];
       for j := 0 to xx.Count-1 do p.Insert( TDot1.Create( TDot1( xx[j] ).x,
                                                           TDot1( xx[j] ).y ) );
     end;
     {
   for i:=p.count-1 downto 1 do
     if Distance( tdot1( p[i] ).x, tdot1( p[i] ).y,
                  tdot1( p[i-1] ).x,tdot1( p[i-1] ).y ) < 1.0e-5
                  then p.Atfree(i);
              }
   for j := 0 to p.Count-2 do
     begin
       c := 0;
       k := 0;
       p1 := p[j];
       p2 := p[j+1];
       x1 := ( p1.x + p2.x ) / 2;
       y1 := ( p1.y + p2.y ) / 2;
       { for i... }
       for i := 0 to p.Count-1 do
         begin
           if i < p.Count-1 then p2 := TDot1( p[i+1] ) else p2 := TDot1( p[0] );
           p1 := TDot1( p[i] );
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
   p.Free;
   if k = 1 then writeln('pizdets!!!!!!!!!: Point and Polygon !!!!!!!!!!!!!!');
 end;

function intersection_two_twigolygons( P1, P2 : PCollection ) : PCollection;
  var
    i, j, k, flg1, flg2 : integer;
    xx1, xx2, intervals, pk : PCollection;
    x1, y1 : double;
    p11, p12 : TDot1;
  begin
    intervals := PCollection.Create(1);
    Result := intervals;

    for i := 0 to p1.Count-1 do
      begin
        xx1 := p1[i];
        for j := 0 to p2.Count-1 do
          begin
            xx2 := p2[j];
            intersection_polylines_2( xx1, xx2 );
          end;
       end;
      {}
    for i := 0 to p2.Count-1 do
      begin
        xx1 := p2[i];
        for j := 0 to xx1.Count-2 do
          begin
            p11 := xx1[j];
            p12 := xx1[j+1];
            x1 := ( p11.x + p12.x ) / 2;
            y1 := ( p11.y + p12.y ) / 2;
            if j = 0 then pk := PCollection.Create(1);
            if point_and_twigolygon( x1, y1, p1 ) > 0 then flg1 := 1 else flg1 := 0;
            if flg1 = 1 then pk.Insert( TDot1.Create( p11.x, p11.y ) );
            if ( flg1 = 0 ) and ( pk.Count > 0 ) then
              begin
                pk.Insert( TDot1.Create( p11.x, p11.y ) );
                intervals.Insert( pk );
                pk := PCollection.Create(1);
              end;
            if ( j = xx1.Count-2 ) and ( pk.Count > 0 ) then
              begin
                pk.Insert( TDot1.Create( p12.x, p12.y ) );
                intervals.Insert( pk );
              end;
          end;
      end;
      {}
    for i := 0 to p1.Count-1 do
      begin
        xx1 := p1[i];
        for j := 0 to xx1.Count-2 do
          begin
            p11 := xx1[j];
            p12 := xx1[j+1];
            x1 := ( p11.x + p12.x ) / 2;
            y1 := ( p11.y + p12.y ) / 2;
            if j = 0 then pk := PCollection.Create(1);
            if point_and_twigolygon( x1, y1, p2 ) > 0 then flg1 := 1 else flg1 := 0;
            if flg1 = 1 then pk.Insert( TDot1.Create( p11.x, p11.y ) );
            if ( flg1 = 0 ) and ( pk.Count > 0 ) then
              begin
                pk.Insert( TDot1.Create( p11.x, p11.y ) );
                intervals.Insert( pk );
                pk := PCollection.Create(1);
              end;
            if ( j = xx1.Count-2 ) and ( pk.Count > 0 ) then
              begin
                pk.Insert( TDot1.Create( p12.x, p12.y ) );
                intervals.Insert( pk );
              end;
          end;
      end;
    Result := intervals;
  end;

end.
