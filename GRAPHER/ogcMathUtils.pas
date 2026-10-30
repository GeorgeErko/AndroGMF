unit ogcMathUtils;

interface

uses Classes, SysUtils, Math, ogcBasic;

const
  ZNull = 6356752.30;
  XYNull = ZNull * Pi;
  eps = 1.0E-4;
  eps_point_on_circle : double = 1.0E-5;

type

 { TArcRec }

 TArcRec = record
  AX, AY, AZ, BX, BY, BZ, DX, DY, DZ: Double;
  Bulge: Double;
  constructor Create(AX_,AY_,AZ_,BX_,BY_,BZ_,DX_,DY_,DZ_: Double);
  constructor CreateBulge(AX_, AY_, AZ_, BX_, BY_, BZ_, Bulge_: Double);
 end;

 TCircRecord = class(TogsBasic)
  XC, YC, XR, YR:Double;
//  constructor Create(XC_, YC_, XR_, YR_:Double);
 end;

{ TlDot - класс для доступа к точкам без учета текущей ogsMatrix }
 TlDot = class(TogsBasic)
  XDot, YDot: Double;
  Z: Double; //!!!
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

 { TInt }

 TInt=class(TogsBasic)
  Num: Integer;
  constructor Create(Num_: Integer);
 end;

 { TDouble }

 TDouble=class(TogsBasic)
  Num: Double;
  constructor Create(Num_: Double);
 end;


 { TIntCollect }

 TIntCollect=class(TogsCollection)
//  Function Get(Index: Integer): Pointer;Override;
//  Procedure Put(Index: Integer; Item: Pointer);Override;
  function GetI(Index: Integer):Integer;
  procedure PutI(Index: Integer; Item: Integer);
  property Point[Index: Integer]:Integer read GetI write PutI; default;
 end;

 { TFloatCollect }

 TFloatCollect = class(TogsCollection)
  function GetI(Index:Integer): Double;
  procedure PutI(Index: Integer; Item: Double);
  property Point[Index: Integer]: Double read GetI write PutI; default;
 end;

 { TMatrica }

 TMatrica=class(TogsBasic)
  P: TogsCollection;
  constructor Create(XC, YC: Integer);
  destructor Destroy; override;
  function GetPoint(X, Y: Integer): Double;
  procedure SetPoint(X, Y: Integer; Value: Double);
  property Point[X, Y: Integer]: Double read GetPoint write SetPoint; default;
 end;

// matrix
procedure Solve ( N : integer; A, B : TFloatCollect; Ipvt : TIntCollect );
procedure Decomp ( N : integer; A, Work : TFloatCollect; Ipvt : TIntCollect;
                   var Cond : double );
function Indx ( N, i, j : integer ) : integer;
function solving_linear_system_by_gauss( a : TMatrica; h : TFloatCollect;
                                         var cond : double ) : boolean;
{ метод гауса - решение системы линейных урравнений }
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

function intersection_two_straight_lines( a1, b1, c1, a2, b2, c2 : double;
                                          var x, y  : double) : boolean;
{ Функция находит пересечение двух прямых линий заданных общими уравнениями:
    a1 * x + b1 * y + c1 = 0,
    a2 * x + b2 * y + c2 = 0. }

// polygons
function point_in_polygon_xy( x, y : double; const px, py : array of double ) : boolean;
{ точка (x,y) внутри многоугольника с вершинами (px[i],py[i]) или на его
  границе (ближе eps); правило четности пересечений луча, контур замыкается }
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
function direct_angle( X1, Y1, X2, Y2 : double ) : double;
{ Функция вычисляет дирекционный угол в левой системе координат (y,x). }
function circle( x_c, y_c, r : double; var quants_number : integer ) : TogsCollection;
{ функция возвращает окружность в отрезках с центром в точке (x_c,y_c) }

function solving_arc_circle( x1, y1, x2, y2, x3, y3 : double;
                             var x0, y0 : double ) : double;
{ вычисление центра дуги окружности, возвращает радиус }

function point_on_circle( xc, yc, r, x, y : double ) : boolean;
{ возвращает принадлежность точки окружности
  использует eps_point_on_circle. }

function arc_circle3( x_C, y_c, x1, y1, x2, y2 : double;
                      var quants_number : integer ) : TogsCollection;
{ процедура возвращает дугу окружности в отрезках с центром в точке (x_c,y_c),
  образованную точками (x_3,y_3) и (x_4,y_4) окружности. В случае, если
  праметры функции заданы не верно, функция прекращает работу, а значение
  аргумента quants_number оказывается нулевым.}

function dist_to_arc( xc, yc, xa, ya, xb, yb, x, y : double; var xp, yp : double ) : double;
{ расстояние до дуги }

function circle2( x_c, y_c, x1, y1, r : double; var quants_number : integer ) : TogsCollection;
{ вычисление ломаной (кол-во вершин - quants_number) для отображени окружности }

function GStrToFloat(S: String): Double;
{ конвертация строки в вещественное число, с учетом разделителя ['.',',']}

implementation uses Writer;

 { TArcRec }

constructor TArcRec.Create(AX_, AY_, AZ_, BX_, BY_, BZ_, DX_, DY_, DZ_: Double);
begin
 AX := AX_; AY := AY_; AZ := AZ_; BX := BX_; BY := BY_; BZ := BZ_;
 DX := DX_; DY := DY_; DZ := DZ_;
 Bulge := 0;
end;

constructor TArcRec.CreateBulge(AX_, AY_, AZ_, BX_, BY_, BZ_, Bulge_: Double);
begin
 AX := AX_; AY := AY_; AZ := AZ_; BX := BX_; BY := BY_; BZ := BZ_;
// DX := DX_; DY := DY_; DZ := DZ_;
 Bulge := Bulge_;
end;

{ TInt }

constructor TInt.Create(Num_: Integer);
begin
 Num := Num_;
end;

{ TIntCollect }

function TIntCollect.GetI(Index: Integer): Integer;
begin
 Result := TInt(fList[Index - 1]).Num;
end;

procedure TIntCollect.PutI(Index: Integer; Item: Integer);
begin
 TInt(fList[Index - 1]).Num := Item;
end;

{ TDouble }

constructor TDouble.Create(Num_: Double);
begin
 Num := Num_;
end;

{ TFloatCollect }

function TFloatCollect.GetI(Index: Integer): Double;
begin
 Result := TDouble(fList[Index - 1]).Num;
end;

procedure TFloatCollect.PutI(Index: Integer; Item: Double);
begin
 TDouble(fList[Index - 1]).Num := Item;
end;

{ TMatrica }

constructor TMatrica.Create;
var I, J: Integer; PC: TogsCollection;
begin
 P := TogsCollection.Create(1);
  For I := 1 to YC do
   begin
    PC := TogsCollection.Create(1);
    P.Add(PC);
     For J := 1 to XC do PC.Add(TDouble.Create(0));
   end;
end;

destructor TMatrica.Destroy;
begin
 P.Free;
end;

function TMatrica.GetPoint;
var PC: TogsCollection;
begin
 PC := P[Y - 1];
 Result := TDouble(PC[X - 1]).Num;
end;

procedure TMatrica.SetPoint;
var PC: TogsCollection;
begin
 PC := P[Y - 1];
 TDouble(PC[X - 1]).Num := Value;
end;

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

// ========================================================================

function Indx ( N, i, j : integer ) : integer;
begin
 Indx := N * pred( i ) + j
end;

procedure Solve ( N : integer; A, B : TFloatCollect; Ipvt : TIntCollect );
var
  T : double;
  i, k, m, kb : integer;
begin
  if N <> 1 then
    begin
      for k := 1 to N-1 do
        begin
          m := Ipvt[k];
          T := B[m];
          B[m] := B[k];
          B[k] := T;
          for i := k+1 to N do B[i] := B[i] + A[ Indx( N, i, k ) ] * T;
        end;
      for kb := 1 to N-1 do
        begin
          k := N - kb +1;
          B[k] := B[k] / A[ Indx( N, k, k ) ];
          T := -B[k];
          for i := 1 to N-kb do B[i] := B[i] + A[ Indx( N, i, k ) ] * T
        end
    end;
  B[1] := B[1] / A[1]
end;

procedure Decomp ( N : integer; A, Work : TFloatCollect; Ipvt : TIntCollect;
                   var Cond : double );
var
  i, j, k, m, kb : integer;
  EK, T, Anorm, Ynorm, Znorm : double;
begin
  Cond := 1.0E+32;
  Ipvt[N] := 1;
  if N = 1 then begin if A[1] <> 0 then Cond := 1;
                      Exit
                end;
  Anorm := 0;
  for j := 1 to N do
    begin
      T := 0;
      for i := 1 to N do T := T + abs( A[ Indx( N, i, j ) ] );
      if T > Anorm then Anorm := T
    end;
  for k := 1 to N-1 do
    begin
      m := k;
      for i := k+1 to N
       do if abs( A[ Indx( N, i, k ) ] )  > abs( A[ Indx( N, m, k ) ] )
           then m := i;
      Ipvt[k] := m;
      if m <> k then Ipvt[N] := -Ipvt[N];
      T := A[ Indx( N, m, k ) ];
      A[ Indx( N, m, k ) ] := A[ Indx( N, k, k ) ];
      A[ Indx( N, k, k ) ] := T;
      if T <> 0 then
        begin
          for i := k+1 to N
           do A[ Indx( N, i, k ) ] := -A[ Indx( N, i, k ) ] / T;
          for j := k+1 to N do
            begin
              T := A[ Indx( N, m, j ) ];
              A[ Indx( N, m, j ) ] := A[ Indx( N, k, j ) ];
              A[ Indx( N, k, j ) ] := T;
              if T <> 0 then for i := k+1 to N
               do A[ Indx( N, i, j ) ] := A[ Indx( N, i, j ) ] +
                                        A[ Indx( N, i, k ) ] * T
            end
        end
    end;
  for k := 1 to N do
    begin
      T := 0;
      if k <> 1 then for i := 1 to k-1
                      do T := T + A[ Indx( N, i, k ) ] * Work[i];
      EK := 1;
      if T < 0 then Ek := -1;
      if A[ Indx( N, k, k ) ] = 0 then Exit;
      Work[k] := -( EK + T ) / A[ Indx( N, k, k ) ]
    end;
  for kb := 1 to N-1 do
    begin
      k := N - kb;
      T := 0;
      for i := k+1 to N do T := T + A[ Indx( N, i, k ) ] * Work[k];
      Work[k] := T;
      m := Ipvt[k];
      if m <> k then begin
                       T := Work[m];
                       Work[m] := Work[k];
                       Work[k] := T;
                     end
    end;
  Ynorm := 0;
  for i := 1 to N do Ynorm := Ynorm + abs( Work[i] );
  Solve( N, A, Work, Ipvt );
  Znorm := 0;
  for i := 1 to N do Znorm := Znorm + abs( Work[i] );

  Cond := Anorm * Znorm / Ynorm;
  if Cond < 1 then Cond := 1;
end;

function solving_linear_system_by_gauss(a: TMatrica; h: TFloatCollect;
 var cond: double): boolean;
var
  Work, bb : TFloatCollect;
  Ipvt : TIntCollect;
  i, j, n : integer;
begin
  Result := TRUE;
  Ipvt := TIntCollect.Create(1);
  Work := TFloatCollect.Create(1);
  bb := TFloatCollect.Create(1);
  n := h.Count;
   for i := 1 to n do
     begin
       for j := 1 to n do bb.Add( TDouble.Create(1) );
       Work.Add( TDouble.Create(1) );
       Ipvt.Add( TInt.Create(1) );
     end;
  for i := 1 to n do for j := 1 to n do bb[indx(n, i, j)] := A[i, j];
  Decomp( N, bb, Work, Ipvt, Cond );
  if ( cond + 1 = cond ) then Result := FALSE else solve( N, bb, h, Ipvt );
  bb.Free;
  Work.Free;
  Ipvt.Free;
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
var Dx, Dy, Len2, T: Double;
begin
// проекция точки на отрезок с ограничением параметра T в [0..1]
 Dx := X2_ - X1_;
 Dy := Y2_ - Y1_;
 Len2 := Dx * Dx + Dy * Dy;
 if Len2 <= 1e-30 then begin
  x := X1_;
  y := Y1_;
  Result := sqrt(sqr(X0_ - x) + sqr(Y0_ - y));
  exit;
 end;
 T := ((X0_ - X1_) * Dx + (Y0_ - Y1_) * Dy) / Len2;
 if T < 0 then T := 0 else if T > 1 then T := 1;
 x := X1_ + Dx * T;
 y := Y1_ + Dy * T;
 Result := sqrt(sqr(X0_ - x) + sqr(Y0_ - y));
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

function intersection_two_straight_lines( a1, b1, c1, a2, b2, c2 : double;
                                          var x, y  : double) : boolean;
var
  a : TMatrica;
  h : TFloatCollect;
  cond : double;
begin
  a := TMatrica.Create(2,2);
  h := TFloatCollect.Create(1);
  a[1,1] := a1; a[1,2] := b1;
  a[2,1] := a2; a[2,2] := b2;
  h.Add( TDouble.Create( -c1 ) );
  h.Add( TDouble.Create( -c2 ) );
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

function orientation_of_polygon(polygon: TogsCollection; var square: double
 ): integer;
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
var x, y: Double;
begin
 Result := Dist_Point_Edge(X0_, Y0_, X1_, Y1_, X2_, Y2_, x, y);
end;

function point_in_polygon_xy(x, y: double; const px, py: array of double): boolean;
var i, j, n: Integer;
begin
 Result := False;
 n := Length(px);
 if (n < 3) or (Length(py) <> n) then exit;
 j := n - 1;
 for i := 0 to n - 1 do begin
  if Dist_Point_Edge(x, y, px[j], py[j], px[i], py[i]) <= eps then exit(True);
  if ((py[i] > y) <> (py[j] > y)) and (x < (px[j] - px[i]) * (y - py[i]) / (py[j] - py[i]) + px[i]) then Result := not Result;
  j := i;
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
     if j  < p.Count-1 then
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
    WriteIn(['point_and_polygon: точка на вершине луча']);
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

function solving_arc_circle(x1, y1, x2, y2, x3, y3: double; var x0, y0: double): double;
var
  r3, xi1, xi2, a : double;
begin
  xi2 := ( x1*x1 + y1*y1 - x3*x3 - y3*y3 ) / 2;
  xi1 := ( x2*x2 + y2*y2 - x3*x3 - y3*y3 ) / 2;
  a := y1 - y3 - ( x1 - x3 ) * ( y2 - y3 ) / ( x2 - x3 );
  y0 := ( xi2 - xi1 * (x1 - x3)/(x2 - x3) ) / a;
  x0 := ( xi1 - y0 * ( y2 - y3 ) ) / ( x2 - x3 );
  r3 := sqrt( sqr( x3 - x0 ) + sqr( y3 - y0 ) );
  Result := r3;
end;

function point_on_circle(xc, yc, r, x, y: double): boolean;
begin
 result := false;
 if abs( sqr(x-xc) + sqr(y-yc) - r*r ) < eps_point_on_circle then result := true;
end;

function arc_circle3(x_C, y_c, x1, y1, x2, y2: double; var quants_number: integer): TogsCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : TogsCollection;
  r, Alfa, beta, Gamma, a, b : Double;
begin
 res := TogsCollection.create(1);
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
     res.Add( TlDot.Create( x, y ) );
     for i := 1 to quants_number do
       begin
         alfa := alfa + gama_quant;
         x := x_c + r * cos( -alfa );
         y := y_c + r * sin( -alfa );
         res.Add( TlDot.Create( x, y ) );
       end;
 Result := res;
end;

function angle_b( y1, x1, y2, x2, y3, x3 : double) : double;
var
  a, b : double;
begin
  a := direct_angle( y1, x1, y2, x2 );
  b := direct_angle( y1, x1, y3, x3 );
  if a > b then Result := 2 * pi - a + b else Result := b - a;
end;

procedure find_tdot2( xc, yc, r, t, aa, bb, beta, x, y : double; res : TogsCollection );
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
       then res.Add( TlDot.Create( x, y ) );
    end;
end;

function sol_2( x1, y1, x2, y2, r, xc, yc, xa, ya, xb, yb : double ) : TogsCollection;
var
  i, j : integer;
  h, s, p, a2, b2, c2, aa, bb,  a, b, c, x, y, x0, y0, alfa, beta : double;
  t, o, xx, yy : double;
  res : TogsCollection;
begin
  res := TogsCollection.Create(1);
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

function dist_to_arc(xc, yc, xa, ya, xb, yb, x, y: double; var xp, yp: double): double;
var
  c : TogsCollection;
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
      xp := TlDot( c[0] ).xdot;
      yp := TlDot( c[0] ).ydot;
      result := res;
    end;
 c.Free;
end;

function circle2(x_c, y_c, x1, y1, r: double; var quants_number: integer): TogsCollection;
var
  x_1, y_1, x_2, y_2, gama, gama_quant, x, y : double;
  i, flag : integer;
  res, res1 : TogsCollection;
  Alfa, beta, Gamma, a, b : Double;
begin
  res := TogsCollection.create(1);
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
var FS: TFormatSettings;
begin
 FS := TFormatSettings.Invariant;
 Result := StrToFloat(StringReplace(Trim(S), ',', '.', [rfReplaceAll]), FS);
end;

end.
