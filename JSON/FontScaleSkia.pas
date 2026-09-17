unit FontScaleSkia;

interface uses System.Types, System.Skia, System.Generics.Collections, System.Math, Classes, EcDot;

const KoefZoom: Single = 1;
     styleSym_Height: Char = 'A';

type
  PointArray = array of TPointF;
  IntArray = array of Integer;

type
  TFontScaleSkia = class
   Symbol: Char;
   Lines: PointArray;
   Polygons: IntArray;
   PolyCount, PointsCount: Integer;
   XMin, XMax, YMin, YMax, MinX, MinY, MaxX, MaxY: Single;
   A, B, C: Single;
   constructor CreateFromText(const Ch: Char; const FontName: string; const FontSize: Single);
   destructor Destroy; override;
  end;

  TFontViewSkia = class
   FontScales: TList<TFontScaleSkia>;
   Scale: Integer;
   bl, it: Integer;
   FontName: string;
   CharSet: Byte;
   kUp, KDown, TE, TI, TH, TD, Kline, kW: Single;
   Index: Integer;
   constructor Create(const FName: string; const FH, FW: Double; const CharSet1: Byte; const bl1, it1: Integer; const FS: Integer = 10);
   destructor Destroy; override;
   procedure SetParams(const FH, FW: Double);
   procedure PaintText(const Canvas: ISkCanvas; const X, Y: Single; const Koef, Angle: Single; const Text: string);
   procedure FillText(const Canvas: ISkCanvas; const X, Y: Single; const Koef, Angle: Single; const Text: string);
   procedure GetTextLen(const X, Y: Single; const Koef, Angle: Single; const Text: string; var DX, DY: Single);
   function GetTextPoint(const XPoint, YPoint, X, Y: Single; const Koef, Angle: Single; const Text: string): boolean;
   function isEqual(const FName: string; const CHS: byte; const bl1, it1: Integer): boolean;
   function YMin(const C: Char): Single;
   function XMin(const C: Char): Single;
   function RH(const C: Char): Single;
  end;

  TFontManagerSkia = class(TList<TFontViewSkia>)
   function AddFont(const fntName: string; const H, W: Double; const CharSet: Byte; const bl1, it1: Integer; const fS: Integer = 10): integer;
  end;

implementation uses ogcBasic;

{ TFontScaleSkia }

constructor TFontScaleSkia.CreateFromText(const Ch: Char; const FontName: string; const FontSize: Single);
var Typeface: ISkTypeface;
    Paint: ISkPaint;
    Blob: ISkTextBlob;
    Path: ISkPath;
    Iter: TPathIterator;
    Verbs: TPathVerbArray;
    Points: TPointFArray;
    I, J, PtIdx, PolyIdx: Integer;
    Pts: TList<TPointF>;
    Polys: TList<Integer>;
    ABC: TSkFontMetrics;
    Font: ISkFont;
begin
  Symbol := Ch;
  Typeface := TSkTypeface.MakeFromName(FontName);
  if Typeface = nil then exit;
  Paint := TSkPaint.Create;
  Paint.AntiAlias := true;
  Paint.Typeface := Typeface;
  Paint.TextSize := FontSize;
  Font := TSkFont.Create(Typeface, FontSize);
  Blob := TSkTextBlob.MakeFromText(Ch, Paint);
  if Blob = nil then exit;
  Path := TSkPath.Create;
  if Path = nil then exit;
  Blob.toPath(Path);
  Pts := TList<TPointF>.Create;
  Polys := TList<Integer>.Create;
  try
   Iter := Path.GetPathIterator;
   while Iter.Next(Verbs, Points) <> TPathIterator.kDone do begin
    PtIdx := 0;
    PolyIdx := 0;
    for I := 0 to High(Verbs) do begin
     case Verbs[I] of
      TPathIterator.kMove: begin
       if PolyIdx > 0 then Polys.Add(PtIdx);
       PtIdx := 0;
       if PtIdx < Length(Points) then Pts.Add(Points[PtIdx]);
       Inc(PtIdx);
      end;
      TPathIterator.kLine: begin
       if PtIdx < Length(Points) then Pts.Add(Points[PtIdx]);
       Inc(PtIdx);
      end;
      TPathIterator.kClose: begin
       if PtIdx < Length(Points) then Pts.Add(Points[PtIdx]);
       Inc(PtIdx);
       Polys.Add(PtIdx);
      end;
     end;
    end;
   end;
   if Pts.Count > 0 then begin
    SetLength(Lines, Pts.Count);
    for I := 0 to Pts.Count - 1 do Lines[I] := Pts[I];
    SetLength(Polygons, Polys.Count);
    for I := 0 to Polys.Count - 1 do Polygons[I] := Polys[I];
    PolyCount := Polys.Count;
    PointsCount := Pts.Count;
    XMin := Lines[0].X;
    YMin := Lines[0].Y;
    XMax := XMin;
    YMax := YMin;
    for I := 1 to PointsCount - 1 do begin
     if Lines[I].X < XMin then XMin := Lines[I].X;
     if Lines[I].X > XMax then XMax := Lines[I].X;
     if Lines[I].Y < YMin then YMin := Lines[I].Y;
     if Lines[I].Y > YMax then YMax := Lines[I].Y;
    end;
    MinX := XMin;
    MinY := YMin;
    MaxX := XMax;
    MaxY := YMax;
    Font.GetMetrics(ABC);
    A := ABC.fLeft;
    B := ABC.fWidth;
    C := ABC.fRight;
   end;
  finally
   Pts.Free;
   Polys.Free;
  end;
end;

destructor TFontScaleSkia.Destroy;
begin
  SetLength(Lines, 0);
  Lines := nil;
  SetLength(Polygons, 0);
  Polygons := nil;
  inherited;
end;

{ TFontViewSkia }

constructor TFontViewSkia.Create(const FName: string; const FH, FW: Double;
  const CharSet1: Byte; const bl1, it1: Integer; const FS: Integer);
var I: Integer;
    FS1: TFontScaleSkia;
begin
  FontName := FName;
  Scale := FS;
  bl := bl1;
  it := it1;
  CharSet := CharSet1;
  FontScales := TList<TFontScaleSkia>.Create;
  for I := 0 to 255 do FontScales.Add(TFontScaleSkia.CreateFromText(Chr(I), FontName, FS));
  FS1 := FontScales[Ord(styleSym_Height)];
  if FS1 <> nil then begin
   TE := FS1.YMax;
   TD := FS1.YMin;
   TH := FS1.YMax - FS1.YMin;
   kUp := FS1.YMin / Scale;
   KDown := FS1.YMax / Scale;
  end;
  kW := FW;
end;

destructor TFontViewSkia.Destroy;
var I: Integer;
begin
  for I := 0 to FontScales.Count - 1 do FontScales[I].Free;
  FontScales.Free;
  inherited;
end;

procedure TFontViewSkia.SetParams(const FH, FW: Double);
begin
  kW := FW;
end;

procedure TFontViewSkia.PaintText(const Canvas: ISkCanvas; const X, Y: Single; const Koef, Angle: Single; const Text: string);
var I, J, PointCount, PolyCount: Integer;
    F: TFontScaleSkia;
    X1, Y1, Max: Single;
    AllLin: PointArray;
    AllPoly: IntArray;
    Rad: Single;
    Paint: ISkPaint;
    PtIdx: Integer;
begin
  if (Canvas = nil) or (Text = '') then exit;
  Max := 0;
  PointCount := 0;
  PolyCount := 0;
  for I := 1 to Length(Text) do begin
   F := FontScales[Ord(Text[I])];
   if F = nil then continue;
   SetLength(AllLin, Length(AllLin) + F.PointsCount);
   for J := 0 to F.PointsCount - 1 do begin
    AllLin[PointCount].X := F.Lines[J].X * kW + Max;
    AllLin[PointCount].Y := F.Lines[J].Y;
    Inc(PointCount);
   end;
   SetLength(AllPoly, Length(AllPoly) + F.PolyCount);
   for J := 0 to F.PolyCount - 1 do begin
    AllPoly[PolyCount] := F.Polygons[J];
    Inc(PolyCount);
   end;
   Max := Max + (F.A + F.B + F.C) * kW;
  end;
  Rad := Angle * Pi / 180;
  for I := 0 to PointCount - 1 do begin
   X1 := AllLin[I].X * Koef;
   Y1 := AllLin[I].Y * Koef;
   AllLin[I].X := X + (Cos(Pi / 2 - Rad) * Y1 + Cos(Rad) * X1);
   AllLin[I].Y := Y + (Sin(Pi / 2 - Rad) * Y1 - Sin(Rad) * X1);
  end;
  Paint := TSkPaint.Create;
  Paint.AntiAlias := true;
  Paint.Style := TSkPaintStyle.Stroke;
  Paint.Color := TAlphaColors.Black;
  Paint.StrokeWidth := 1;
  PtIdx := 0;
  for I := 0 to PolyCount - 1 do begin
   for J := 0 to AllPoly[I] - 1 do begin
    if PtIdx < PointCount then begin
     if J = 0 then Canvas.DrawPoint(AllLin[PtIdx], Paint)
     else if PtIdx > 0 then Canvas.DrawLine(AllLin[PtIdx - 1], AllLin[PtIdx], Paint);
     Inc(PtIdx);
    end;
   end;
  end;
end;

procedure TFontViewSkia.FillText(const Canvas: ISkCanvas; const X, Y: Single; const Koef, Angle: Single; const Text: string);
var I, J, PointCount, PolyCount: Integer;
    F: TFontScaleSkia;
    X1, Y1, Max: Single;
    AllLin: PointArray;
    AllPoly: IntArray;
    Rad: Single;
    Paint: ISkPaint;
    Path: ISkPath;
    PtIdx: Integer;
begin
  if (Canvas = nil) or (Text = '') then exit;
  Max := 0;
  PointCount := 0;
  PolyCount := 0;
  for I := 1 to Length(Text) do begin
   F := FontScales[Ord(Text[I])];
   if F = nil then continue;
   SetLength(AllLin, Length(AllLin) + F.PointsCount);
   for J := 0 to F.PointsCount - 1 do begin
    AllLin[PointCount].X := F.Lines[J].X * kW + Max;
    AllLin[PointCount].Y := F.Lines[J].Y;
    Inc(PointCount);
   end;
   SetLength(AllPoly, Length(AllPoly) + F.PolyCount);
   for J := 0 to F.PolyCount - 1 do begin
    AllPoly[PolyCount] := F.Polygons[J];
    Inc(PolyCount);
   end;
   Max := Max + (F.A + F.B + F.C) * kW;
  end;
  Rad := Angle * Pi / 180;
  for I := 0 to PointCount - 1 do begin
   X1 := AllLin[I].X * Koef;
   Y1 := AllLin[I].Y * Koef;
   AllLin[I].X := X + (Cos(Pi / 2 - Rad) * Y1 + Cos(Rad) * X1);
   AllLin[I].Y := Y + (Sin(Pi / 2 - Rad) * Y1 - Sin(Rad) * X1);
  end;
  Paint := TSkPaint.Create;
  Paint.AntiAlias := true;
  Paint.Style := TSkPaintStyle.Fill;
  Paint.Color := TAlphaColors.Black;
  PtIdx := 0;
  for I := 0 to PolyCount - 1 do begin
   Path := TSkPath.Create;
   if Path <> nil then begin
    for J := 0 to AllPoly[I] - 1 do begin
     if PtIdx < PointCount then begin
      if J = 0 then Path.moveTo(AllLin[PtIdx].X, AllLin[PtIdx].Y)
      else Path.lineTo(AllLin[PtIdx].X, AllLin[PtIdx].Y);
      Inc(PtIdx);
     end;
    end;
    Path.close;
    Canvas.DrawPath(Path, Paint);
   end;
  end;
end;

procedure TFontViewSkia.GetTextLen(const X, Y: Single; const Koef, Angle: Single; const Text: string; var DX, DY: Single);
var I: Integer;
    F: TFontScaleSkia;
    DDX: Single;
begin
  DDX := 0;
  for I := 1 to Length(Text) do begin
   F := FontScales[Ord(Text[I])];
   if F = nil then continue;
   DDX := DDX + (F.A + F.B + F.C) * Koef;
   if I = 1 then DY := (F.YMax - F.YMin) * Koef;
  end;
  DX := DDX * kW;
end;

function TFontViewSkia.GetTextPoint(const XPoint, YPoint, X, Y: Single; const Koef, Angle: Single; const Text: string): boolean;
var I, J, PointCount, PolyCount: Integer;
    F: TFontScaleSkia;
    X1, Y1, Max: Single;
    AllLin: PointArray;
    AllPoly: IntArray;
    Rad: Single;
begin
  Result := false;
  Max := 0;
  PointCount := 0;
  PolyCount := 0;
  for I := 1 to Length(Text) do begin
   F := FontScales[Ord(Text[I])];
   if F = nil then continue;
   SetLength(AllLin, Length(AllLin) + F.PointsCount);
   for J := 0 to F.PointsCount - 1 do begin
    AllLin[PointCount].X := F.Lines[J].X * kW + Max;
    AllLin[PointCount].Y := F.Lines[J].Y;
    Inc(PointCount);
   end;
   SetLength(AllPoly, Length(AllPoly) + F.PolyCount);
   for J := 0 to F.PolyCount - 1 do begin
    AllPoly[PolyCount] := F.Polygons[J];
    Inc(PolyCount);
   end;
   Max := Max + (F.A + F.B + F.C) * kW;
  end;
  Rad := Angle * Pi / 180;
  for I := 0 to PointCount - 1 do begin
   X1 := AllLin[I].X * Koef;
   Y1 := AllLin[I].Y * Koef;
   AllLin[I].X := X + (Cos(Pi / 2 - Rad) * Y1 + Cos(Rad) * X1);
   AllLin[I].Y := Y + (Sin(Pi / 2 - Rad) * Y1 - Sin(Rad) * X1);
  end;
  for I := 1 to PointCount - 1 do begin
   if Dist_Point_Edge(XPoint, YPoint, AllLin[I].X, AllLin[I].Y, AllLin[I - 1].X, AllLin[I - 1].Y) <= 2 then begin
    Result := true;
    exit;
   end;
  end;
end;

function TFontViewSkia.isEqual(const FName: string; const CHS: byte; const bl1, it1: Integer): boolean;
begin
  Result := (AnsiUpperCase(FontName) = AnsiUpperCase(FName)) and (bl = bl1) and (it = it1) and (CharSet = CHS);
end;

function TFontViewSkia.YMin(const C: Char): Single;
var FS: TFontScaleSkia;
begin
  FS := FontScales[Ord(C)];
  if FS <> nil then Result := FS.MinY else Result := 0;
end;

function TFontViewSkia.RH(const C: Char): Single;
var FS: TFontScaleSkia;
begin
  FS := FontScales[Ord(C)];
  if FS <> nil then Result := FS.YMax - FS.YMin else Result := 0;
end;

function TFontViewSkia.XMin(const C: Char): Single;
var FS: TFontScaleSkia;
begin
  FS := FontScales[Ord(C)];
  if FS <> nil then Result := FS.MinX else Result := 0;
end;

{ TFontManagerSkia }

function TFontManagerSkia.AddFont(const fntName: string; const H, W: Double; const CharSet: Byte; const bl1, it1: Integer; const fS: Integer): integer;
var I: Integer;
    fv: TFontViewSkia;
begin
  Result := -1;
  for I := 0 to Count - 1 do begin
   fv := Items[I];
   if fv.isEqual(fntName, CharSet, bl1, it1) then begin
    Result := I;
    exit;
   end;
  end;
  fv := TFontViewSkia.Create(fntName, H, W, CharSet, bl1, it1, fS);
  Add(fv);
  fv.Index := Count - 1;
  Result := Count - 1;
end;

end.
