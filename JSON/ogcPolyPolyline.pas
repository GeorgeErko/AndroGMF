unit ogcPolyPolyline;

interface

uses Classes, ogcMathUtils;

type
{ TPolyDot - точка полиполилинии (копия исходной точки) }
 TPolyDot = class(TlDot)
 public
  Angle: Double;   // угол поворота точечного объекта
  Source: Pointer; // исходный объект (не владеет)
  constructor Create(X, Y: Double; ASource: Pointer = nil; AAngle: Double = 0);
 end;

{ TPolyPolyline - список полилиний, владеет своими точками TPolyDot }
 TPolyPolyline = class(TList)
 private
  function GetPolylineCount: Integer;
  function GetPolyline(Index: Integer): TList;
  function GetPointCount(PolyIndex: Integer): Integer;
  function GetPoint(PolyIndex, PtIndex: Integer): TPolyDot;
 public
  destructor Destroy; override;
 //
  function AddPolyline: TList;
  procedure AddPoint(PolyIndex: Integer; Pt: TPolyDot); overload;
  function AddPoint(PolyIndex: Integer; X, Y: Double; ASource: Pointer = nil; AAngle: Double = 0): TPolyDot; overload;
  procedure ClearAll;
 // добавляет в Dest короткие полилинии (предыдущая вершина, точка, следующая вершина)
 // для каждого вхождения точки X, Y в вершину или внутрь отрезка; возвращает их число
  function ExtractAtPoint(X, Y, Eps: Double; Dest: TPolyPolyline): Integer;
 //
  property PolylineCount: Integer read GetPolylineCount;
  property Polyline[Index: Integer]: TList read GetPolyline;
  property PointCount[PolyIndex: Integer]: Integer read GetPointCount;
  property Point[PolyIndex, PtIndex: Integer]: TPolyDot read GetPoint;
 end;

implementation

{ TPolyDot }

constructor TPolyDot.Create(X, Y: Double; ASource: Pointer; AAngle: Double);
begin
 inherited Create(X, Y);
 Source := ASource;
 Angle := AAngle;
end;

{ TPolyPolyline }

destructor TPolyPolyline.Destroy;
begin
 ClearAll;
 inherited;
end;

function TPolyPolyline.AddPolyline: TList;
begin
 Result := TList.Create;
 Add(Result);
end;

procedure TPolyPolyline.AddPoint(PolyIndex: Integer; Pt: TPolyDot);
begin
 if Pt = nil then exit;
 GetPolyline(PolyIndex).Add(Pt);
end;

function TPolyPolyline.AddPoint(PolyIndex: Integer; X, Y: Double; ASource: Pointer; AAngle: Double): TPolyDot;
begin
 Result := TPolyDot.Create(X, Y, ASource, AAngle);
 GetPolyline(PolyIndex).Add(Result);
end;

procedure TPolyPolyline.ClearAll;
var I, J: Integer;
    Poly: TList;
begin
 for I := 0 to Count - 1 do begin
  Poly := TList(Items[I]);
  if Poly = nil then continue;
  for J := 0 to Poly.Count - 1 do
   TPolyDot(Poly[J]).Free;
  Poly.Free;
 end;
 Clear;
end;

function TPolyPolyline.ExtractAtPoint(X, Y, Eps: Double; Dest: TPolyPolyline): Integer;
var IPoly, I, N, K: Integer;
    Poly: TList;
    Closed: Boolean;
    P, Prev, Next: TPolyDot;
    PX, PY: Double;

 function IsNear(D: TPolyDot): Boolean;
 begin
  Result := Distance(X, Y, D.XDot, D.YDot) <= Eps;
 end;

 procedure CopyDot(Index: Integer; D: TPolyDot);
 begin
  Dest.AddPoint(Index, D.XDot, D.YDot, D.Source, D.Angle);
 end;

begin
 Result := 0;
 if Dest = nil then exit;
 for IPoly := 0 to Count - 1 do begin
  Poly := TList(Items[IPoly]);
  if Poly = nil then continue;
  N := Poly.Count;
  if N = 0 then continue;
  P := TPolyDot(Poly[N - 1]);
  Closed := (N > 2) and (Distance(TPolyDot(Poly[0]).XDot, TPolyDot(Poly[0]).YDot, P.XDot, P.YDot) <= Eps);
 // точка совпадает с вершиной
  for I := 0 to N - 1 do begin
   if Closed and (I = N - 1) then continue;
   P := TPolyDot(Poly[I]);
   if not IsNear(P) then continue;
   if I > 0 then
    Prev := TPolyDot(Poly[I - 1])
   else if Closed then
    Prev := TPolyDot(Poly[N - 2])
   else
    Prev := nil;
   if I < N - 1 then Next := TPolyDot(Poly[I + 1]) else Next := nil;
   Dest.AddPolyline;
   K := Dest.PolylineCount - 1;
   if Prev <> nil then CopyDot(K, Prev);
   CopyDot(K, P);
   if Next <> nil then CopyDot(K, Next);
   Inc(Result);
  end;
 // точка лежит внутри отрезка (середина и т.п.)
  for I := 0 to N - 2 do begin
   Prev := TPolyDot(Poly[I]);
   Next := TPolyDot(Poly[I + 1]);
   if IsNear(Prev) or IsNear(Next) then continue;
   if Dist_Point_Edge(X, Y, Prev.XDot, Prev.YDot, Next.XDot, Next.YDot, PX, PY) > Eps then continue;
   Dest.AddPolyline;
   K := Dest.PolylineCount - 1;
   CopyDot(K, Prev);
   Dest.AddPoint(K, X, Y);
   CopyDot(K, Next);
   Inc(Result);
  end;
 end;
end;

function TPolyPolyline.GetPolylineCount: Integer;
begin
 Result := Count;
end;

function TPolyPolyline.GetPolyline(Index: Integer): TList;
begin
 Result := TList(Items[Index]);
end;

function TPolyPolyline.GetPointCount(PolyIndex: Integer): Integer;
begin
 Result := GetPolyline(PolyIndex).Count;
end;

function TPolyPolyline.GetPoint(PolyIndex, PtIndex: Integer): TPolyDot;
begin
 Result := TPolyDot(GetPolyline(PolyIndex)[PtIndex]);
end;

end.
