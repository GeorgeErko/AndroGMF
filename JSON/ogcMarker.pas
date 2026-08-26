unit ogcMarker;

interface

uses System.Types, System.UITypes, System.Skia, System.Generics.Collections, System.Math,
     Classes, EcDot;

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
  pemTintModulate
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

procedure ogsDrawPictureEffect(const Canvas: ISkCanvas; const ClipRect: TRectF; const Pic: ISkPicture; const OverlayColor: TAlphaColor; const Mode: TogsPictureEffectMode; const OverlayAlpha: Byte = $60);
procedure ogsDrawPictureEffect2(const Canvas: ISkCanvas; const Points: TList;
  const LineColor: TAlphaColor; const LineWidthPix: Single;
  const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
  const RectFillColor: TAlphaColor;
  const ViewScale: Single; const RadiusPix: Single; const RectMode: TogsRectDrawMode);

implementation uses Writer;

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
 S := Max(2, FSize * 0.35) * InvScale;
 for I := 0 to FStickPts.Count - 1 do begin
  Pt := FStickPts[I];
  if Pt = nil then continue;
  PTo := TPointF.Create(Single(Pt.X), Single(Pt.Y));
  Paint.Color := Pt.LineColor;
  Canvas.DrawLine(FromP, PTo, Paint);
  Paint.Color := Pt.Color;
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
 Paint.Color := FColor;
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
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y - S), TPointF.Create(P.X + S, P.Y + S), Paint);
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y + S), TPointF.Create(P.X + S, P.Y - S), Paint);
   end;
  msRect: begin
    R := TRectF.Create(P.X - S, P.Y - S, P.X + S, P.Y + S);
    Canvas.DrawRect(R, Paint);
   end;
  msTriangle: begin
    A := TPointF.Create(P.X, P.Y - S);
    B := TPointF.Create(P.X - S, P.Y + S);
    C := TPointF.Create(P.X + S, P.Y + S);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  msInvTriangle: begin
    A := TPointF.Create(P.X, P.Y + S);
    B := TPointF.Create(P.X - S, P.Y - S);
    C := TPointF.Create(P.X + S, P.Y - S);
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

procedure ogsDrawPictureEffect(const Canvas: ISkCanvas; const ClipRect: TRectF; const Pic: ISkPicture; const OverlayColor: TAlphaColor; const Mode: TogsPictureEffectMode; const OverlayAlpha: Byte);
var Paint: ISkPaint;
    R: TRectF;
    Recorder: ISkPictureRecorder;
    OffCanvas: ISkCanvas;
    OffPic: ISkPicture;
begin
 if (Canvas = nil) or (Pic = nil) then exit;
 R := ClipRect;
 if (R.Width <= 0) or (R.Height <= 0) then R := Canvas.GetLocalClipBounds;
 Recorder := TSkPictureRecorder.Create;
 OffCanvas := Recorder.BeginRecording(R);
 OffCanvas.ClipRect(R);
 OffCanvas.DrawPicture(Pic);
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
  OffCanvas.DrawRect(R, Paint);
 end;
 OffPic := Recorder.FinishRecording;
 if OffPic = nil then exit;
 Canvas.Save;
 try
  Canvas.ClipRect(R);
  Canvas.DrawPicture(OffPic);
 finally
  Canvas.Restore;
 end;
end;

procedure ogsDrawPictureEffect2(const Canvas: ISkCanvas; const Points: TList;
  const LineColor: TAlphaColor; const LineWidthPix: Single;
  const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
  const RectFillColor: TAlphaColor;
  const ViewScale: Single; const RadiusPix: Single; const RectMode: TogsRectDrawMode);
var PaintLine, PaintRectStroke, PaintRectFill: ISkPaint;
    I: Integer;
    P0, P1: TPointF;
    InvScale: Single;
    R: Single;
    RR: TRectF;
    LineW, RectStrokeW: Single;
begin
 if (Canvas = nil) or (Points = nil) then exit;
 if Points.Count < 2 then exit;
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
 P0 := TPointF.Create(TDot(Points[0]).XDot, TDot(Points[0]).YDot);
 for I := 1 to Points.Count - 1 do begin
  P1 := TPointF.Create(Single(TDot(Points[I]).XDot), Single(TDot(Points[I]).YDot));
  Canvas.DrawLine(P0, P1, PaintLine);
  P0 := P1;
 end;
 for I := 0 to Points.Count - 1 do begin
  P0 := TPointF.Create(Single(TDot(Points[I]).XDot), Single(TDot(Points[I]).YDot));
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

end.
