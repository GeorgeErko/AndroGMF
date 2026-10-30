unit ogcClipPolyline;

interface

uses
  Classes, SysUtils, ogcBasic;

function ClipLineStringToRect(Points: TogsCollection; ClipRect: TogsRect): TogsCollection;

implementation

uses
  ogcMathUtils;

type
  TClipDot = class(TDot)
  public
    InVisible: Boolean;
    IsIntersection: Boolean;
  end;

const
  CS_INSIDE = 0;
  CS_LEFT   = 1;
  CS_RIGHT  = 2;
  CS_BOTTOM = 4;
  CS_TOP    = 8;

function ComputeOutCode(const X, Y, XMin, YMin, XMax, YMax: Double): Integer;
begin
  Result := CS_INSIDE;
  if X < XMin then
    Result := Result or CS_LEFT
  else if X > XMax then
    Result := Result or CS_RIGHT;

  if Y < YMin then
    Result := Result or CS_BOTTOM
  else if Y > YMax then
    Result := Result or CS_TOP;
end;

function ClipSegmentCohenSutherland(
  var X0, Y0, X1, Y1: Double;
  const XMin, YMin, XMax, YMax: Double
): Boolean;
var
  OutCode0, OutCode1, OutCodeOut: Integer;
  Accept: Boolean;
  X, Y: Double;
  DX, DY: Double;
begin
  OutCode0 := ComputeOutCode(X0, Y0, XMin, YMin, XMax, YMax);
  OutCode1 := ComputeOutCode(X1, Y1, XMin, YMin, XMax, YMax);
  Accept := False;

  while True do begin
    if ((OutCode0 or OutCode1) = 0) then begin
      Accept := True;
      Break;
    end else if ((OutCode0 and OutCode1) <> 0) then begin
      Break;
    end else begin
      if OutCode0 <> 0 then
        OutCodeOut := OutCode0
      else
        OutCodeOut := OutCode1;

      DX := X1 - X0;
      DY := Y1 - Y0;

      if (OutCodeOut and CS_TOP) <> 0 then begin
        if DY = 0 then Exit(False);
        X := X0 + DX * (YMax - Y0) / DY;
        Y := YMax;
      end else if (OutCodeOut and CS_BOTTOM) <> 0 then begin
        if DY = 0 then Exit(False);
        X := X0 + DX * (YMin - Y0) / DY;
        Y := YMin;
      end else if (OutCodeOut and CS_RIGHT) <> 0 then begin
        if DX = 0 then Exit(False);
        Y := Y0 + DY * (XMax - X0) / DX;
        X := XMax;
      end else begin
        if DX = 0 then Exit(False);
        Y := Y0 + DY * (XMin - X0) / DX;
        X := XMin;
      end;

      if OutCodeOut = OutCode0 then begin
        X0 := X;
        Y0 := Y;
        OutCode0 := ComputeOutCode(X0, Y0, XMin, YMin, XMax, YMax);
      end else begin
        X1 := X;
        Y1 := Y;
        OutCode1 := ComputeOutCode(X1, Y1, XMin, YMin, XMax, YMax);
      end;
    end;
  end;

  Result := Accept;
end;

function AlmostEqual(const A, B: Double): Boolean;
begin
  Result := Abs(A - B) <= 1e-4;
end;

procedure NormalizeRect(const R: TogsRect; out XMin, YMin, XMax, YMax: Double);
begin
  if R.XMin < R.XMax then begin
    XMin := R.XMin;
    XMax := R.XMax;
  end else begin
    XMin := R.XMax;
    XMax := R.XMin;
  end;

  if R.YMin < R.YMax then begin
    YMin := R.YMin;
    YMax := R.YMax;
  end else begin
    YMin := R.YMax;
    YMax := R.YMin;
  end;
end;

function ClipLineStringToRect(Points: TogsCollection; ClipRect: TogsRect): TogsCollection;
var
  parts: TogsCollection;
  copypoints: TogsCollection;
  i, k: Integer;
  p0, p1: TogsDot;
  c0: TClipDot;
  x0, y0, x1, y1: Double;
  ox0, oy0, ox1, oy1: Double;
  xmin, ymin, xmax, ymax: Double;
  eps: Double;
  outpart: TogsPolyCollection;
  inside: Boolean;

  function pointin(x, y: Double): Boolean;
  begin
    Result := (x >= xmin - eps) and (x <= xmax + eps) and (y >= ymin - eps) and (y <= ymax + eps);
  end;

function onborder(x, y: Double): Boolean;
begin
 Result := (Abs(x - xmin) <= eps) or (Abs(x - xmax) <= eps) or
           (Abs(y - ymin) <= eps) or (Abs(y - ymax) <= eps);
end;

  function clipseg(var ax0, ay0, ax1, ay1: Double): Boolean;
  begin
    Result := ClipSegmentCohenSutherland(ax0, ay0, ax1, ay1, xmin, ymin, xmax, ymax);
  end;

  procedure addcopypoint(x, y: Double; isinter: Boolean);
  var
    d: TClipDot;
    last: TClipDot;
    inter: Boolean;
  begin
    inter := isinter or onborder(x, y);
    if copypoints.Count > 0 then begin
      last := TClipDot(copypoints[copypoints.Count - 1]);
      if (Abs(last.fX - x) <= eps) and (Abs(last.fY - y) <= eps) then begin
        last.InVisible := last.InVisible or (not pointin(x, y));
        last.IsIntersection := last.IsIntersection or inter;
        if last.IsIntersection then
          last.InVisible := False;
        Exit;
      end;
    end;
    d := TClipDot.Create(x, y, 0);
    d.IsIntersection := inter;
    d.InVisible := (not pointin(x, y));
    if d.IsIntersection then
      d.InVisible := False;
    copypoints.Add(d);
  end;

  procedure finishpart;
  begin
    if outpart = nil then Exit;
    if outpart.Count >= 2 then
      parts.Add(outpart)
    else
      outpart.Free;
    outpart := nil;
  end;

begin
  parts := TogsCollection.Create;
  Result := parts;
  if (Points = nil) or (ClipRect = nil) then Exit;
  if Points.Count < 2 then Exit;

  NormalizeRect(ClipRect, xmin, ymin, xmax, ymax);
  eps := 1e-4;

  copypoints := TogsCollection.Create;
  try
    p0 := TogsDot(Points[0]);
    addcopypoint(p0.X, p0.Y, False);

    for i := 0 to Points.Count - 2 do begin
      p0 := TogsDot(Points[i]);
      p1 := TogsDot(Points[i + 1]);
     // используем еоординаты текущей ogsMatrix (не fX/fY)
      ox0 := p0.X; oy0 := p0.Y;
      ox1 := p1.X; oy1 := p1.Y;
     //
      x0 := ox0; y0 := oy0;
      x1 := ox1; y1 := oy1;

      if clipseg(x0, y0, x1, y1) then begin
        if (Abs(x0 - ox0) > eps) or (Abs(y0 - oy0) > eps) then
          addcopypoint(x0, y0, True);
        if (Abs(x1 - ox1) > eps) or (Abs(y1 - oy1) > eps) then
          addcopypoint(x1, y1, True);
      end;
      addcopypoint(ox1, oy1, False);
    end;

    outpart := nil;
    inside := False;

    k := 0;
    while k < copypoints.Count do begin
      c0 := TClipDot(copypoints[k]);

      if not inside then begin
        if (not c0.InVisible) then begin
          outpart := TogsPolyCollection.Create1(4);
          outpart.Items.Add(TogsDot.Create(c0.fX, c0.fY, 0));
          inside := True;
        end else if c0.IsIntersection and (k + 1 < copypoints.Count) and (not TClipDot(copypoints[k + 1]).InVisible) then begin
          outpart := TogsPolyCollection.Create1(4);
          outpart.Items.Add(TogsDot.Create(c0.fX, c0.fY, 0));
          inside := True;
        end;
      end else begin
        if (not c0.InVisible) then
          outpart.Items.Add(TogsDot.Create(c0.fX, c0.fY, 0))
        else if c0.IsIntersection then begin
          outpart.Items.Add(TogsDot.Create(c0.fX, c0.fY, 0));
          finishpart;
          inside := False;
        end else begin
          finishpart;
          inside := False;
        end;
      end;

      Inc(k);
    end;
    finishpart;
  finally
    copypoints.Free;
  end;
end;

end.
