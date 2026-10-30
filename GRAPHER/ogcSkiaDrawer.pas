unit ogcSkiaDrawer;

interface

uses Classes, SysUtils, Types, System.UITypes, System.Math, FMX.Graphics,
     FMX.Skia, System.Skia, ogcBasic;

// Рисователь иерархии GRAPHER на канве Skia (FMX: Win64 и Android).
// Кадр рисования - обработчик TSkPaintBox.OnDraw:
//   Drawer.BeginFrame(ACanvas, ADest);
//   try Geometry.Draw(Drawer) finally Drawer.EndFrame end;
// Цвета пера и кисти (TogsPen.penColor, TogsBrush.brColor) - TColor ($00BBGGRR).
// Координаты:
//   DrawLine/DrawPolyline/DrawPolyPolyLine/DrawCircle/DrawSect - уже вычисленные
//   (с учетом ogsMatrix) координаты, используются TogsDot.fX/fY;
//   DrawPolyPolygon - контуры TPoly_Single, вершины пересчитываются текущей
//   ogsMatrix (TogsDot.X/Y), заливка по правилу EvenOdd (дырки любой вложенности).

type

  { TogsSkiaDrawer }

  TogsSkiaDrawer = class(TogsDrawer)
  private
   FSkCanvas: ISkCanvas;
   FPaintBox: TSkPaintBox;
   FDest: TRectF;
   FWidth: Integer;
   FHeight: Integer;
   FStrokeCap: TSkStrokeCap;
   FStrokeJoin: TSkStrokeJoin;
   FAntiAlias: Boolean;
   FCurrent: TPointF;
   function StrokePaint: ISkPaint;
   function FillPaint: ISkPaint;
   function Pix(X, Y: Double): TPointF;
  protected
   function GetWidth: Integer; override;
   procedure SetWidth(AValue: Integer); override;
   function GetHeight: Integer; override;
   procedure SetHeight(AValue: Integer); override;
   function GetCanvas: TCanvas; override;
  public
   constructor Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent); override;
   constructor CreatePaintBox(ogsSelector_: TogsSelector; PaintBox_: TSkPaintBox);
  // кадр рисования (ADest - область контрола, задает Width/Height)
   procedure BeginFrame(const ACanvas: ISkCanvas; const ADest: TRectF);
   procedure EndFrame;
  //
   procedure Clear(AColor: Longint); override;
   procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); overload; override;
   procedure DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean = True); overload; override;
   procedure DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean = True); override;
   procedure DrawSect(Sect: TSect); override;
   procedure DrawCircle(XA, YA, Radius: Double); override;
   procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
   procedure DrawMarker(X, Y: Double; Text: String = ''); overload; override;
  // рисование в системе координат канвы
   procedure MoveTo(X, Y: Integer); override;
   procedure LineTo(X, Y: Integer); override;
  //
   function geoWidth: Double; override;
   function geoHeight: Double; override;
   procedure DrawTo(Image_: TCanvas; Rect: TRect); override;
   procedure RedrawAll; override;
  //
   property SkCanvas: ISkCanvas read FSkCanvas;
   property PaintBox: TSkPaintBox read FPaintBox write FPaintBox;
   property StrokeCap: TSkStrokeCap read FStrokeCap write FStrokeCap;
   property StrokeJoin: TSkStrokeJoin read FStrokeJoin write FStrokeJoin;
   property AntiAlias: Boolean read FAntiAlias write FAntiAlias;
  end;

// TColor ($00BBGGRR, системные цвета) -> TAlphaColor ($FFRRGGBB)
function ogsAlphaColor(Color: TColor): TAlphaColor;

implementation

function ogsAlphaColor(Color: TColor): TAlphaColor;
var C: Cardinal;
begin
 C := Cardinal(TColorRec.ColorToRGB(Color));
 Result := $FF000000 or ((C and $FF) shl 16) or (C and $FF00) or ((C shr 16) and $FF);
end;

{ TogsSkiaDrawer }

constructor TogsSkiaDrawer.Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 fDrawerMode := dmDraw;
 FWidth := 1;
 FHeight := 1;
 FStrokeCap := TSkStrokeCap.Round;
 FStrokeJoin := TSkStrokeJoin.Round;
 FAntiAlias := True;
end;

constructor TogsSkiaDrawer.CreatePaintBox(ogsSelector_: TogsSelector; PaintBox_: TSkPaintBox);
begin
 Create(ogsSelector_, nil);
 FPaintBox := PaintBox_;
 if FPaintBox <> nil then begin
  FWidth := Max(1, Round(FPaintBox.Width));
  FHeight := Max(1, Round(FPaintBox.Height));
 end;
end;

procedure TogsSkiaDrawer.BeginFrame(const ACanvas: ISkCanvas; const ADest: TRectF);
begin
 FSkCanvas := ACanvas;
 FDest := ADest;
 Width := Round(ADest.Width);
 Height := Round(ADest.Height);
 if FSkCanvas <> nil then FSkCanvas.Save;
 if ogsSelector <> nil then ogsSelector.BeginPaint;
end;

procedure TogsSkiaDrawer.EndFrame;
begin
 if ogsSelector <> nil then ogsSelector.EndPaint;
 if FSkCanvas <> nil then FSkCanvas.Restore;
 FSkCanvas := nil;
end;

function TogsSkiaDrawer.GetWidth: Integer;
begin
 Result := FWidth;
end;

procedure TogsSkiaDrawer.SetWidth(AValue: Integer);
begin
 FWidth := Max(1, AValue);
end;

function TogsSkiaDrawer.GetHeight: Integer;
begin
 Result := FHeight;
end;

procedure TogsSkiaDrawer.SetHeight(AValue: Integer);
begin
 FHeight := Max(1, AValue);
end;

function TogsSkiaDrawer.GetCanvas: TCanvas;
begin
// рисование выполняется на ISkCanvas (SkCanvas)
 Result := nil;
end;

function TogsSkiaDrawer.Pix(X, Y: Double): TPointF;
begin
 Result := PointF(FDest.Left + ogsSelector.XPix(X), FDest.Top + ogsSelector.YPix(Y));
end;

function TogsSkiaDrawer.StrokePaint: ISkPaint;
begin
 Result := TSkPaint.Create(TSkPaintStyle.Stroke);
 Result.AntiAlias := FAntiAlias;
 Result.Color := ogsAlphaColor(Pen.penColor);
// ширина пера в пикселах: 0 -> линия в 1 пиксел
 Result.StrokeWidth := Max(1.0, Pen.penWidth);
 Result.StrokeCap := FStrokeCap;
 Result.StrokeJoin := FStrokeJoin;
end;

function TogsSkiaDrawer.FillPaint: ISkPaint;
begin
 Result := TSkPaint.Create(TSkPaintStyle.Fill);
 Result.AntiAlias := FAntiAlias;
 Result.Color := ogsAlphaColor(Brush.brColor);
end;

procedure TogsSkiaDrawer.Clear(AColor: Longint);
begin
 if FSkCanvas <> nil then FSkCanvas.Clear(ogsAlphaColor(AColor));
end;

procedure TogsSkiaDrawer.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
var P0, P1: TPointF;
begin
 if Disable or (FSkCanvas = nil) or (ogsSelector = nil) then exit;
 if cutRequest and not ogsSelector.lineVisible(X, Y, X1, Y1) then exit;
 P0 := Pix(X, Y);
 P1 := Pix(X1, Y1);
 FSkCanvas.DrawLine(P0, P1, StrokePaint);
end;

procedure TogsSkiaDrawer.DrawPolyline(Points: TogsPolyCollection; cutRequest: Boolean);
var I: Integer;
    D: TogsDot;
    Builder: ISkPathBuilder;
begin
 if Disable or (FSkCanvas = nil) or (ogsSelector = nil) then exit;
 if (Points = nil) or (Points.Count < 2) then exit;
 if cutRequest and (Points.ogsRect.Iter <> 0) and not ogsSelector.RectVisible(Points.ogsRect) then exit;
// ломаная одним путем: изломы по StrokeJoin, концы по StrokeCap
 Builder := TSkPathBuilder.Create;
 for I := 0 to Points.Count - 1 do begin
  D := TogsDot(Points.Items[I]);
  if I = 0 then Builder.MoveTo(Pix(D.fX, D.fY)) else Builder.LineTo(Pix(D.fX, D.fY));
 end;
 FSkCanvas.DrawPath(Builder.Detach, StrokePaint);
end;

procedure TogsSkiaDrawer.DrawPolyPolyLine(Parts: TogsCollection; cutRequest: Boolean);
var I: Integer;
begin
 if Disable or (Parts = nil) then exit;
 for I := 0 to Parts.Count - 1 do DrawPolyline(TogsPolyCollection(Parts[I]), cutRequest);
end;

procedure TogsSkiaDrawer.DrawSect(Sect: TSect);
begin
 if Disable then exit;
 with Sect do begin
  DrawLine(XMin, YMin, XMin, YMax);
  DrawLine(XMin, YMax, XMax, YMax);
  DrawLine(XMax, YMax, XMax, YMin);
  DrawLine(XMax, YMin, XMin, YMin);
 end;
end;

procedure TogsSkiaDrawer.DrawCircle(XA, YA, Radius: Double);
var C: TPointF;
begin
 if Disable or (FSkCanvas = nil) or (ogsSelector = nil) then exit;
 C := Pix(XA, YA);
 FSkCanvas.DrawCircle(C, ogsSelector.pixDist(Radius), StrokePaint);
end;

procedure TogsSkiaDrawer.DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect);
var I, J, N: Integer;
    Ring: TogsSimpleGeometrySet;
    D: TogsDot;
    Builder: ISkPathBuilder;
    P: TPointF;
begin
 if Disable or (FSkCanvas = nil) or (ogsSelector = nil) then exit;
 if (Polygons = nil) or (Polygons.Count = 0) then exit;
// полигон меньше пиксела -> точка цветом кисти
 if (polyRect <> nil) and (polyRect.Iter <> 0) and (polyRect.Width <= ogsSelector.PixelSize) and (polyRect.Height <= ogsSelector.PixelSize) then begin
  P := Pix(polyRect.XMin, polyRect.YMin);
  FSkCanvas.DrawPoint(P, FillPaint);
  exit;
 end;
// все контуры (оболочки, дырки, острова) в одном пути с правилом EvenOdd
 Builder := TSkPathBuilder.Create(TSkPathFillType.EvenOdd);
 N := 0;
 for I := 0 to Polygons.Count - 1 do begin
  Ring := TogsSimpleGeometrySet(Polygons[I]);
  if (Ring = nil) or (Ring.Count < 3) then continue;
  for J := 0 to Ring.Count - 1 do begin
   D := TogsDot(Ring.Items[J]);
   if J = 0 then Builder.MoveTo(Pix(D.X, D.Y)) else Builder.LineTo(Pix(D.X, D.Y));
  end;
  Builder.Close;
  Inc(N);
 end;
 if N = 0 then exit;
 FSkCanvas.DrawPath(Builder.Detach, FillPaint);
end;

procedure TogsSkiaDrawer.DrawMarker(X, Y: Double; Text: String);
const R = 2;
var P: TPointF;
    Paint: ISkPaint;
begin
 if Disable or (FSkCanvas = nil) or (ogsSelector = nil) then exit;
 P := Pix(X, Y);
 Paint := StrokePaint;
 Paint.StrokeWidth := 1;
 FSkCanvas.DrawLine(PointF(P.X - R, P.Y - R), PointF(P.X + R, P.Y + R), Paint);
 FSkCanvas.DrawLine(PointF(P.X - R, P.Y + R), PointF(P.X + R, P.Y - R), Paint);
end;

procedure TogsSkiaDrawer.MoveTo(X, Y: Integer);
begin
 FCurrent := PointF(FDest.Left + X, FDest.Top + Y);
end;

procedure TogsSkiaDrawer.LineTo(X, Y: Integer);
var P: TPointF;
begin
 P := PointF(FDest.Left + X, FDest.Top + Y);
 if not Disable and (FSkCanvas <> nil) then FSkCanvas.DrawLine(FCurrent, P, StrokePaint);
 FCurrent := P;
end;

function TogsSkiaDrawer.geoWidth: Double;
begin
 if ogsSelector <> nil then Result := ogsSelector.ActiveRect.Width else Result := Width;
end;

function TogsSkiaDrawer.geoHeight: Double;
begin
 if ogsSelector <> nil then Result := ogsSelector.ActiveRect.Height else Result := Height;
end;

procedure TogsSkiaDrawer.DrawTo(Image_: TCanvas; Rect: TRect);
begin
// вывод на TCanvas FMX не используется: кадр рисуется в TSkPaintBox.OnDraw
 RedrawAll;
end;

procedure TogsSkiaDrawer.RedrawAll;
begin
 if FPaintBox <> nil then FPaintBox.Redraw else inherited RedrawAll;
end;

end.
