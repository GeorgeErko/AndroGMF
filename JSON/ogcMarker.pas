unit ogcMarker;

interface uses System.Types, System.UITypes, System.Skia, System.Generics.Collections, System.Math,
     System.Math.Vectors, FMX.TextLayout, FMX.Graphics, Classes, ogcMathUtils, ogcPolyPolyline,
     ogcBasic;

type
 TogsMarkerType = (
  mtNone, // невидимый
  mtPolygon,
  mtLine,
  mtPoint,
  mtCenterLine,
  mtCenterLine2,
  mtCenterPoly,
  mtPerpend,
  mtLineStvor
 );

 TogsMarkerShape = (
  msNone,
  msCross,
  msDiagCross,
  msRect,
  msTriangle,
  msInvTriangle,
  ms2Triangle,
  msSmallCross, // по умолчанию msCross в 1.5 раза меньше
  msSmallDiagCross
 );

 TogsPictureEffectMode = (
  pemNone,
  pemTintSrcATop,
  pemTintScreen,
  pemTintModulate,
  pemHalo, // цветная обводка вокруг линий и знаков (морфологическое расширение)
  pemGlow // мягкое свечение вокруг объекта (размытие)
 );

 TogsRectDrawMode = (
  rdmStroke,
  rdmFill,
  rdmFillStroke
 );

 TStickPt = class
 public
  X: Double;
  Y: Double;
  Z: Double;
  Color: TAlphaColor;
  LineColor: TAlphaColor;
  constructor Create(const AX, AY: Double; const AColor: TAlphaColor; const ALineColor: TAlphaColor; const AZ: Double = 0);
 end;

 TogsMarker = class
 private
 //
  FState: TogsMarkerType;
  FSize: Single;
  FPtSize: Single;
  FWidth: Single;
  FColor: TAlphaColor;
  FLineColor: TAlphaColor;
  FStickPts: TObjectList<TStickPt>;
 public
  constructor Create;
  destructor Destroy; override;
 //
  class function StateToShape(const AState: TogsMarkerType): TogsMarkerShape; static;
 //
  procedure ClearStickPts;
  function StickPtCount: Integer;
  function StickPt(Index: Integer): TStickPt;
  procedure AddStickPt(Pt: TStickPt);
 //
  procedure Draw(const Canvas: ISkCanvas; const P: TPointF; const ViewScale: Single);
  procedure DrawStickPts(const Canvas: ISkCanvas; const FromP: TPointF; const ViewScale: Single);
 //
  property State: TogsMarkerType read FState write FState;
  property Size: Single read FSize write FSize;
  property Width: Single read FWidth write FWidth;
  property Color: TAlphaColor read FColor write FColor;
  property LineColor: TAlphaColor read FLineColor write FLineColor;
 end;

procedure ogsDrawPictureEffect(const Canvas: ISkCanvas; const ClipRect: TRectF; const Pic: ISkPicture; const OverlayColor: TAlphaColor; const Mode: TogsPictureEffectMode; const OverlayAlpha: Byte = $60; const RadiusPix: Single = 3);
procedure ogsDrawPictureEffectLot(const Canvas: ISkCanvas; const Points: TPolyPolyline;
  const LineColor: TAlphaColor; const LineWidthPix: Single;
  const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
  const RectFillColor: TAlphaColor;
  const ViewScale: Single; const RadiusPix: Single; const RectMode: TogsRectDrawMode);
//
procedure ogsGetPoint(const Points: TPolyPolyline; const Selector: TogsSelector; const X, Y: Double; var Params: TCaptureRec);

implementation uses Writer, System.Skia.API;

{ TStickPt }

constructor TStickPt.Create(const AX, AY: Double; const AColor: TAlphaColor; const ALineColor: TAlphaColor; const AZ: Double);
begin
 inherited Create;
 X := AX;
 Y := AY;
 Z := AZ;
 Color := AColor;
 LineColor := ALineColor;
end;

{ TogsMarker }

constructor TogsMarker.Create;
begin
 inherited Create;
 FState := mtPolygon;
 FSize := 15;
 FPtSize := 5;
 FWidth := 2;
 FColor := TAlphaColors.Red;
 FLineColor := TAlphaColors.Red;
 FStickPts := TObjectList<TStickPt>.Create(True);
end;

destructor TogsMarker.Destroy;
begin
 FStickPts.Free;
 inherited;
end;

class function TogsMarker.StateToShape(const AState: TogsMarkerType): TogsMarkerShape;
begin
 case AState of
  mtPolygon: Result := msCross;
  mtLine: Result := msDiagCross;
  mtPoint: Result := msRect;
  mtCenterLine: Result := msTriangle;
  mtCenterLine2: Result := msInvTriangle;
  mtCenterPoly: Result := ms2Triangle;
  mtPerpend: Result := msSmallCross;
  mtLineStvor: Result := msSmallDiagCross;
 else
  Result := msCross;
 end;
end;

procedure TogsMarker.ClearStickPts;
begin
 FStickPts.Clear;
end;

function TogsMarker.StickPtCount: Integer;
begin
 Result := FStickPts.Count;
end;

function TogsMarker.StickPt(Index: Integer): TStickPt;
begin
 Result := FStickPts[Index];
end;

procedure TogsMarker.AddStickPt(Pt: TStickPt);
begin
 if Pt = nil then Exit;
 FStickPts.Add(Pt);
end;

procedure TogsMarker.DrawStickPts(const Canvas: ISkCanvas; const FromP: TPointF; const ViewScale: Single);
var I: Integer;
    Pt: TStickPt;
    Paint: ISkPaint;
    PTo: TPointF;
    R: TRectF;
    S: Single;
    InvScale: Single;
begin
 if (Canvas = nil) or (FStickPts = nil) or (FStickPts.Count = 0) then Exit;
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 if ViewScale <= 0 then
  InvScale := 1
 else
  InvScale := 1 / ViewScale;
 Paint.StrokeWidth := Max(0.5, FWidth) * InvScale;
 S := Max(FPtSize, FSize * 0.35) * InvScale;
 for I := 0 to FStickPts.Count - 1 do begin
  Pt := FStickPts[I];
  if Pt = nil then continue;
  PTo := TPointF.Create(Single(Pt.X), Single(Pt.Y));
  Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.Difference);
  Paint.Color := $FFFFFFFF;
  Canvas.DrawLine(FromP, PTo, Paint);
  R := TRectF.Create(PTo.X - S, PTo.Y - S, PTo.X + S, PTo.Y + S);
  Canvas.DrawRect(R, Paint);
 end;
end;

procedure TogsMarker.Draw(const Canvas: ISkCanvas; const P: TPointF; const ViewScale: Single);
var Paint: ISkPaint;
    Shape: TogsMarkerShape;
    S: Single;
    R: TRectF;
    A, B, C: TPointF;
    InvScale: Single;
begin
 if Canvas = nil then Exit;
 WriteIn(['Markerpos=', P.X, P.Y]);
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.Luminosity);
 Paint.Color := $FFFFFFFF;
 if ViewScale <= 0 then
  InvScale := 1
 else
  InvScale := 1 / ViewScale;
 Paint.StrokeWidth := Max(0.5, FWidth) * InvScale;
//
 Shape := StateToShape(FState);
 S := Max(1, FSize) * InvScale;
//
 case Shape of
  msCross: begin
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y), TPointF.Create(P.X + S, P.Y), Paint);
    Canvas.DrawLine(TPointF.Create(P.X, P.Y - S), TPointF.Create(P.X, P.Y + S), Paint);
   end;
  msDiagCross: begin
    S := S * 0.70710678;
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y - S), TPointF.Create(P.X + S, P.Y + S), Paint);
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y + S), TPointF.Create(P.X + S, P.Y - S), Paint);
   end;
  msRect: begin
    R := TRectF.Create(P.X - S, P.Y - S, P.X + S, P.Y + S);
    Canvas.DrawRect(R, Paint);
   end;
  msTriangle: begin
    A := TPointF.Create(P.X, P.Y - S - (S / 3));
    B := TPointF.Create(P.X - S, P.Y + S - (S / 3));
    C := TPointF.Create(P.X + S, P.Y + S - (S / 3));
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  msInvTriangle: begin
    A := TPointF.Create(P.X, P.Y + S + (S / 3));
    B := TPointF.Create(P.X - S, P.Y - S + (S / 3));
    C := TPointF.Create(P.X + S, P.Y - S + (S / 3));
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  ms2Triangle: begin
    A := TPointF.Create(P.X, P.Y - S);
    B := TPointF.Create(P.X - S, P.Y);
    C := TPointF.Create(P.X + S, P.Y);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
  //
    A := TPointF.Create(P.X, P.Y + S);
    B := TPointF.Create(P.X - S, P.Y);
    C := TPointF.Create(P.X + S, P.Y);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  msNone: begin
    Canvas.DrawCircle(P.X, P.Y, S, Paint);
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y), TPointF.Create(P.X + S, P.Y), Paint);
    Canvas.DrawLine(TPointF.Create(P.X, P.Y - S), TPointF.Create(P.X, P.Y + S), Paint);
   end;
 end;
//
 DrawStickPts(Canvas, P, ViewScale);
end;

function _ogsApplyAlpha(const C: TAlphaColor; const A: Byte): TAlphaColor;
var R: TAlphaColorRec;
begin
 R := TAlphaColorRec(C);
 R.A := A;
 Result := R.Color;
end;

procedure ogsDrawPictureEffect(const Canvas: ISkCanvas; const ClipRect: TRectF; const Pic: ISkPicture; const OverlayColor: TAlphaColor; const Mode: TogsPictureEffectMode; const OverlayAlpha: Byte; const RadiusPix: Single);
var Paint, MaskPaint, FilterPaint: ISkPaint;
    R: TRectF;
    M: TMatrix;
    CanvasScale, RWorld: Single;
begin
 if (Canvas = nil) or (Pic = nil) then exit;
 R := ClipRect;
 if (R.Width <= 0) or (R.Height <= 0) then R := Canvas.GetLocalClipBounds;
// радиус фильтров задается в пикселах; параметры фильтров - в локальных координатах канвы
 RWorld := 0;
 if Mode in [pemHalo, pemGlow] then begin
  M := Canvas.GetLocalToDeviceAs3x3;
  CanvasScale := Sqrt(Sqr(M.m11) + Sqr(M.m12));
  if CanvasScale <= 0 then CanvasScale := 1;
  RWorld := Max(0.5, RadiusPix) / CanvasScale;
 // обводка и свечение выходят за габариты объекта
  if Mode = pemHalo then R.Inflate(RWorld, RWorld) else R.Inflate(3 * RWorld, 3 * RWorld);
 end;
 Canvas.Save;
 try
  Canvas.ClipRect(R);
 // объект рисуется в отдельный прозрачный слой размером R: эффект смешивается
 // только с пикселями объекта и не затрагивает примитивы под ним
  Canvas.SaveLayer(R, nil);
  try
   case Mode of
    pemHalo, pemGlow: begin
     FilterPaint := TSkPaint.Create;
     if Mode = pemHalo then
      FilterPaint.ImageFilter := TSkImageFilter.MakeColorFilter(TSkColorFilter.MakeBlend(_ogsApplyAlpha(OverlayColor, OverlayAlpha), TSkBlendMode.SrcIn), TSkImageFilter.MakeDilate(RWorld, RWorld))
     else
      FilterPaint.ImageFilter := TSkImageFilter.MakeDropShadowOnly(0, 0, RWorld, RWorld, _ogsApplyAlpha(OverlayColor, OverlayAlpha));
    // эффект под объектом, сам объект поверх
     Canvas.SaveLayer(R, FilterPaint);
     try
      Canvas.DrawPicture(Pic);
     finally
      Canvas.Restore;
     end;
     Canvas.DrawPicture(Pic);
    end;
   else
    Canvas.DrawPicture(Pic);
    if Mode <> pemNone then begin
     Paint := TSkPaint.Create;
     Paint.AntiAlias := true;
     Paint.Color := _ogsApplyAlpha(OverlayColor, OverlayAlpha);
     case Mode of
      pemTintSrcATop: Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcATop);
      pemTintScreen: Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.Screen);
      pemTintModulate: Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.Modulate);
     else
      Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcATop);
     end;
     Canvas.DrawRect(R, Paint);
    // Screen закрашивает и прозрачные пиксели слоя - оставляем только пиксели объекта
     if Mode = pemTintScreen then begin
      MaskPaint := TSkPaint.Create;
      MaskPaint.Blender := TSkBlender.MakeMode(TSkBlendMode.DestIn);
      Canvas.SaveLayer(R, MaskPaint);
      try
       Canvas.DrawPicture(Pic);
      finally
       Canvas.Restore;
      end;
     end;
    end;
   end;
  finally
   Canvas.Restore;
  end;
 finally
  Canvas.Restore;
 end;
end;

procedure ogsDrawPictureEffectLot(const Canvas: ISkCanvas; const Points: TPolyPolyline;
  const LineColor: TAlphaColor; const LineWidthPix: Single;
  const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
  const RectFillColor: TAlphaColor;
  const ViewScale: Single; const RadiusPix: Single; const RectMode: TogsRectDrawMode);
var PaintLine, PaintRectStroke, PaintRectFill: ISkPaint;
    IPoly, I: Integer;
    Poly: TList;
    P0, P1: TPointF;
    InvScale: Single;
    R: Single;
    RR: TRectF;
    LineW, RectStrokeW: Single;
begin
 if (Canvas = nil) or (Points = nil) then exit;
 if Points.PolylineCount < 1 then exit;
//
 if ViewScale <= 0 then InvScale := 1 else InvScale := 1 / ViewScale;
 R := RadiusPix * InvScale;
 LineW := LineWidthPix * InvScale;
 RectStrokeW := RectStrokeWidthPix * InvScale;
//
 PaintLine := TSkPaint.Create;
 PaintLine.AntiAlias := true;
 PaintLine.Color := LineColor;
 PaintLine.Style := TSkPaintStyle.Stroke;
 PaintLine.StrokeWidth := LineW;
 PaintRectStroke := TSkPaint.Create;
 PaintRectStroke.AntiAlias := true;
 PaintRectStroke.Color := RectStrokeColor;
 PaintRectStroke.Style := TSkPaintStyle.Stroke;
 PaintRectStroke.StrokeWidth := RectStrokeW;
 PaintRectFill := TSkPaint.Create;
 PaintRectFill.AntiAlias := true;
 PaintRectFill.Color := RectFillColor;
 PaintRectFill.Style := TSkPaintStyle.Fill;
 WriteIn(['polyCount=', Points.PolylineCount]);
 for IPoly := 0 to Points.PolylineCount - 1 do begin
  Poly := Points.Polyline[IPoly];
   WriteIn(['pointsCount=', Poly.Count]);
  if (Poly = nil) or (Poly.Count < 1) then continue;
  P0 := TPointF.Create(TPolyDot(Poly[0]).XDot, TPolyDot(Poly[0]).YDot);
  WriteIn(['0=', P0.X, P0.Y]);
  for I := 1 to Poly.Count - 1 do begin
   P1 := TPointF.Create(Single(TPolyDot(Poly[I]).XDot), Single(TPolyDot(Poly[I]).YDot));
   Canvas.DrawLine(P0, P1, PaintLine);
   WriteIn(['1=', P1.X, P1.Y]);
   P0 := P1;
  end;
  P0 := TPointF.Create(TPolyDot(Poly[0]).XDot, TPolyDot(Poly[0]).YDot);
  for I := 1 to Poly.Count - 1 do begin
   P1 := TPointF.Create(Single(TPolyDot(Poly[I]).XDot), Single(TPolyDot(Poly[I]).YDot));
   Canvas.DrawCircle((P0.X + P1.X) / 2, (P0.Y + P1.Y) / 2, R, PaintRectFill);
   P0 := P1;
  end;
  for I := 0 to Poly.Count - 1 do begin
   P0 := TPointF.Create(Single(TPolyDot(Poly[I]).XDot), Single(TPolyDot(Poly[I]).YDot));
   RR := TRectF.Create(P0.X - R, P0.Y - R, P0.X + R, P0.Y + R);
   case RectMode of
    rdmStroke: Canvas.DrawRect(RR, PaintRectStroke);
    rdmFill: Canvas.DrawRect(RR, PaintRectFill);
    rdmFillStroke: begin
     Canvas.DrawRect(RR, PaintRectFill);
     Canvas.DrawRect(RR, PaintRectStroke);
    end;
   end;
  end;
 end;
end;

procedure ogsGetPoint(const Points: TPolyPolyline; const Selector: TogsSelector; const X, Y: Double; var Params: TCaptureRec);
var IPoly, I: Integer;
    Poly: TList;
    P0, P1: TPolyDot;
    MidX, MidY: Double;
    Dist: Integer;
    PX, PY: Double;
begin
  if (Points = nil) or (Selector = nil) then exit;
  if Points.PolylineCount < 1 then exit;
  Params.resCapture := MaxInt;
  Params.resObject := nil;
  if ckPoint in Params.CaptureFor then begin
   for IPoly := 0 to Points.PolylineCount - 1 do begin
    Poly := Points.Polyline[IPoly];
    if Poly = nil then continue;
    for I := 0 to Poly.Count - 1 do begin
     P0 := TPolyDot(Poly[I]);
     Dist := Selector.pixDist(Distance(X, Y, P0.XDot, P0.YDot));
     if Dist <= Params.CaptureParam then
      if (Dist < Params.resCapture) and (Dist <= Params.CaptureParam) then begin
       Params.resCapture := Dist;
       Params.resObject := P0;
       Params.resCaptureOf := ckPoint;
       Params.XCapture := P0.XDot; Params.YCapture := P0.YDot;
      end;
    end;
   end;
  end;
  if ckLine in Params.CaptureFor then begin
   for IPoly := 0 to Points.PolylineCount - 1 do begin
    Poly := Points.Polyline[IPoly];
    if Poly = nil then continue;
    for I := 0 to Poly.Count - 2 do begin
     P0 := TPolyDot(Poly[I]);
     P1 := TPolyDot(Poly[I + 1]);
     MidX := (P0.XDot + P1.XDot) / 2;
     MidY := (P0.YDot + P1.YDot) / 2;
    // середина линии
     Dist := Selector.pixDist(Distance(X, Y, MidX, MidY));
     if (Dist < Params.resCapture) and (Dist <= Params.CaptureParam) then begin
      Params.resCapture := Dist;
      Params.resObject := P0;
      Params.resCaptureOf := ckMidLine;
      Params.XCapture := MidX; Params.YCapture := MidY;
     end;
    // сама линия
     Dist := Selector.pixDist(Dist_Point_Edge(X, Y, P0.XDot, P0.YDot, P1.XDot, P1.YDot, PX, PY));
     if Dist <= Params.CaptureParam then
      if (Dist < Params.resCapture) and (Dist <= Params.CaptureParam) then begin
       Params.resCapture := Dist;
       Params.resObject := P0;
       Params.resCaptureOf := ckLine;
       Params.XCapture := PX; Params.YCapture := PY;
      end;
    end;
   end;
  end;
end;


end.
