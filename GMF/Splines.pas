unit Splines;

interface
  (* ============================================= *)
  function bs_spline_3( var p1; t : double; i : integer ) : double;
  procedure bs_spline( var p1; m, di : integer; var out_p_1 );
  { Составной кубический огибающий опорные точки В-сплайн кривых.
    p1 - опорная ломанная сплайна, ее элементы р[0]...p[m-1].
    m - число вершин опорной ломанной,
    di - чмсло звеньев аппроксимирующей ломанной,
    out_p_1 - выходной массив размерности N = (m-3) * di + 1.
    Пример: bs_spline( xp, m, di, oxp );
            bs_spline( yp, m, di, oyp );
      где хр и ур - входные массивы составленные из абсцисс и ординат
      опорных точек соответственно. }
  (* ============================================= *)
  procedure find_q( q_0, q_m : double; var p1; m : integer; var q1 );
  function hermite_3( var p1, q1; t : double; i : integer ) : double;
  procedure hermite( var p1;  m : integer; q_0, q_m : double; di : integer;
                   var out_p1 );
  { Составная кубическая кривая Эрмита.
    p1 - опорная ломанная сплайна, ее элементы р[0]...p[m-1].
    m - число вершин опорной ломанной,
    q_0, q_m - компоненты касательных векторов,
    di - число звеньев аппроксимирующей ломанной,
    out_p_1 - выходной массив размерности N = (m-1) * di + 1.
    Пример: hermite( xp, m, q_0_x, q_m_x, di, oxp );
            hermite( yp, m, q_0_y, q_m_y, di, oyp );
      где хр и ур - входные массивы составленные из абсцисс и ординат
      опорных точек соответственно. }
  (* ============================================= *)
  function catmull_rom_3( var p1; t : double; i : integer ) : double;
  procedure catmull_rom( var p1;  m, di : integer; var out_p1; var n : integer );
  { Cocтавная сплайновая кривая Catmull-Rom.
    p1 - опорная ломанная сплайна, ее элементы р[0]...p[m-1].
    m - число вершин опорной ломанной,
    di - чмсло звеньев аппроксимирующей ломанной,
    out_p_1 - выходной массив размерности N = (m-3) * di.
    Пример: catmull_rom( xp, m, di, oxp );
            catmull_rom( yp, m, di, oyp );
      где хр и ур - входные массивы составленные из абсцисс и ординат
      опорных точек соответственно. }
  (* ============================================= *)

implementation

function bs_spline_3( var p1; t : double; i : integer ) : double;
  var
    s, t2, t3 : double;
    p : array[0..10000] of double absolute p1;
  begin
    s := 1 - t;
    t2 := t*t;
    t3 := t*t*t;
    bs_spline_3 := ( s*s*S * p[i] + ( 3*t3 - 6*t2 + 4 ) * p[i+1] +
                   ( -3*t3 + 3*t2 + 3*t + 1 ) * p[i+2] + t3 * p[i+3] ) / 6;
  end;

procedure bs_spline( var p1; m, di : integer; var out_p_1 );
  var
    t, dt : double;
    i, d, first : integer;
    p : array[0..10000] of double absolute p1;
    out_p : array[0..10000] of double absolute out_p_1;
  begin
    dt := 1 / di;
    first := 0;
    for i := 1 to m-3 do
      begin
        t := 0;
        for d := 0 to di do
          begin
            out_p[ first + d ] := bs_spline_3( p, t, i-1 );
            t := t + dt
          end;
        first := first + di
      end
  end;

procedure find_q( q_0, q_m : double; var p1; m : integer; var q1 );
  var
    p : array[0..10000] of double absolute p1;
    q : array[0..10000] of double absolute q1;
    a, b : array[1..10000] of double;
    i : integer;
  begin
    a[1] := 0;
    b[1] := q_0;
    q[m] := q_m;
    for i := 1 to m-1 do
      begin
        a[i+1] := -1 / ( 4 + a[i] );
        b[i+1] := ( b[i] - 3 * ( p[i+1] - p[i] ) ) * a[i]
      end;
    for i := m-1 downto 0 do q[i] := a[i+1] * q[i+1] + b[i+1];
  end;

function hermite_3( var p1, q1; t : double; i : integer ) : double;
  var
    p : array[0..10000] of double absolute p1;
    q : array[0..10000] of double absolute q1;
    t2, t3 : double;
  begin
    t2 := t*t;
    t3 := t2*t;
    hermite_3 := ( 1 - 3*t2 + 2*t3 ) * p[i] + t2 * ( 3 - 2*t ) * p[i+1]
                 +  t * ( 1 - 2*t + t2 ) * q[i] - t2 * ( 1 - t ) * q[i+1]
  end;

procedure hermite( var p1;  m : integer; q_0, q_m : double; di : integer;
                   var out_p1 );
  var
    p : array[0..10000] of double absolute p1;
    out_p : array[0..10000] of double absolute out_p1;
    q : array[0..10000] of double;
    i, d, first : integer;
    t, dt : double;
  begin
    dt := 1 / di;
    first := 0;
    find_q( q_0, q_m, p, m-1, q );
    for i := 1 to m-1 do
      begin
        t := 0;
        for d := 0 to di do
          begin
            out_p[ first + d ] := hermite_3( p, q, t, i-1 );
            t := t + dt
          end;
        first := first + di
      end
  end;

function catmull_rom_3( var p1; t : double; i : integer ) : double;
  var
    p : array[0..10000] of double absolute p1;
    s, t2, t3 : double;
  begin
    t2 := t*t;
    t3 := t2*t;
    s := 1 - t;
    catmull_rom_3 := 0.5 * ( - t * s*s * p[i] + ( 2 - 5*t2 + 3*t3 ) * p[i+1]
                 +  t * ( 1 + 4*t - 3*t2 ) * p[i+2] - t2 * s * p[i+3] );
  end;

procedure catmull_rom( var p1;  m, di : integer; var out_p1; var n : integer );
  var
    p : array[0..10000] of double absolute p1;
    out_p : array[0..10000] of double absolute out_p1;
    q : array[0..10000] of double;
    i, d, first : integer;
    t, dt : double;
  begin
    dt := 1 / di;
    first := 0;
    for i := 1 to m-2 do
      begin
        t := 0;
        for d := 0 to di do
          begin
            out_p[ first + d ] := catmull_rom_3( p, t, i-1 );
            t := t + dt
          end;
        first := first + di
      end;
    n := ( m - 3 ) * di
  end;

end.
