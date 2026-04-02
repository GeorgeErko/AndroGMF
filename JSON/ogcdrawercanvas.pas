unit ogcDrawerCanvas;

interface

uses Classes, SysUtils, FMX.Graphics, FMX.Controls, ogcBasic, FMX.Objects,
     FMX.Types,
     System.UITypes, System.Types, System.Math.Vectors;

type

 { TogsDrawerCanvas }

 TogsDrawerCanvas = class(TogsSpacer)
 private
  FOnUpdateImage: TNotifyEvent;
  FLastPoint: TPointF;
  FInScene: Boolean;
  fControl: TControl;
  FScale: Single;
  procedure SetOnUpdateImage(AValue: TNotifyEvent);
 //
  function GetHeight: Integer; override;
  function GetWidth: Integer; override;
  procedure SetHeight(AValue: Integer); override;
  procedure SetWidth(AValue: Integer); override;
 protected
  procedure SetPen(AValue: TogsPen); override;
  procedure SetBrush(AValue: TogsBrush); override;
  function GetCanvas: TCanvas; override;
 public
  Bitmap: TBitmap;
  constructor Create(ogsSelector_: TogsSelector; Control_: TControl; Scale_: Single;  OnPaint_:TNotifyEvent);
  destructor Destroy; override;
  procedure Clear(AColor: Longint); override;
  procedure SyncToControl(Scale_: Single);
 //
  procedure UpdateImage;
  property OnUpdateImage: TNotifyEvent read FOnUpdateImage write SetOnUpdateImage;
 //
  procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
  procedure DrawPolyline(Points: TogsCollection; cutRequest: Boolean = True); override;
  procedure DrawPolygon(Points: TogsCollection; polyRect: TogsRect); override;
  procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
  procedure DrawCircle(XA, YA, Radius: Double); override;
 // рисовагние в системе координат Canvas
  procedure MoveTo(X, Y: Integer); override;
  procedure LineTo(X, Y: Integer); override;
 //
  function geoWidth: Double; override;
  function geoHeight: Double; override;
 //
  procedure BeginPaint; override;
  procedure EndPaint; override;
  procedure DrawTo(Image_: TCanvas; Rect: TRect); override;
 //
 end;

implementation uses Writer, ogcMathUtils;

function EnsureOpaqueAlpha(const C: TAlphaColor): TAlphaColor;
begin
 if (C shr 24) = 0 then
  Result := C or $FF000000
 else
  Result := C;
end;

{ TogsDrawerCanvas }

procedure TogsDrawerCanvas.SetOnUpdateImage(AValue: TNotifyEvent);
begin
 FOnUpdateImage := AValue;
end;

function TogsDrawerCanvas.GetHeight: Integer;
begin
// Result := fControl.BoundsRect.Round.Bottom - fControl.BoundsRect.Round.Top;
 Result := Bitmap.Height;
end;

function TogsDrawerCanvas.GetWidth: Integer;
begin
// Result := fControl.BoundsRect.Round.Right - fControl.BoundsRect.Round.Left;
 Result := Bitmap.Width;
end;

procedure TogsDrawerCanvas.SetHeight(AValue: Integer);
begin
 //Bitmap.Height := AValue;
end;

procedure TogsDrawerCanvas.SetWidth(AValue: Integer);
begin
 //Bitmap.Width := AValue;
end;

function TogsDrawerCanvas.GetCanvas: TCanvas;
begin
 Result := Bitmap.Canvas;
end;

procedure TogsDrawerCanvas.SetPen(AValue: TogsPen);
begin
 inherited SetPen(AValue);
 Canvas.Stroke.Kind := TBrushKind.Solid;
 Canvas.Stroke.Color := EnsureOpaqueAlpha(AValue.penColor);
 if AValue.penWidth > 0 then begin
  Canvas.Stroke.Join:= TStrokeJoin.Round;// = (Miter, Round, Bevel);
  Canvas.Stroke.Thickness := AValue.penWidth
 end else
  Canvas.Stroke.Thickness := 1;
end;

procedure TogsDrawerCanvas.SetBrush(AValue: TogsBrush);
begin
 inherited SetBrush(AValue);
 Canvas.Fill.Color := EnsureOpaqueAlpha(AValue.brColor);
end;

constructor TogsDrawerCanvas.Create(ogsSelector_: TogsSelector; Control_: TControl; Scale_: Single; OnPaint_: TNotifyEvent);
begin
 inherited Create(ogsSelector_, OnPaint_);
 fControl := Control_;
 fScale := Scale_;
 Bitmap := TBitmap.Create;
 SyncToControl(Scale_);
end;

procedure TogsDrawerCanvas.SyncToControl(Scale_: Single);
var
 W, H: Integer;
begin
 if Scale_ <= 0 then Exit;
 fScale := Scale_;
 if fControl = nil then Exit;
 W := Round(fControl.Width * fScale);
 H := Round(fControl.Height * fScale);
 if W < 1 then W := 1;
 if H < 1 then H := 1;
 if (Bitmap.Width <> W) or (Bitmap.Height <> H) then
  Bitmap.SetSize(W, H);
end;

procedure TogsDrawerCanvas.Clear(AColor: Longint);
var
 WasInScene: Boolean;
begin
 WasInScene := FInScene;
 if not FInScene then BeginPaint;
 Bitmap.Width := Bitmap.Width;
 Bitmap.Height := Bitmap.Height;
 Bitmap.Canvas.Clear(AColor);
 if not WasInScene then EndPaint;
// Canvas.Brush.Color := AColor);
 //Canvas.Rectangle(-2,-2,Image.Width+5,Image.Height+5);
end;

procedure TogsDrawerCanvas.UpdateImage;
begin
 If Assigned(OnUpdateImage) then OnUpdateImage(Self);
end;

procedure TogsDrawerCanvas.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
const C = 0;
var X_,Y_,X1_,Y1_:Double;
begin
//ё
 If Disable then exit;
 If not cutRequest then With ogsSelector do begin
  Bitmap.Canvas.Stroke.Color := Pen.penColor;
  Canvas.DrawLine(PointF(XPix(X), YPix(Y)), PointF(XPix(X1), YPix(Y1)), 1);
  exit;
 end;
//
 X_:=X; Y_:=Y; X1_:=X1; Y1_:=Y1;
 with ogsSelector, activeRect do
  If pointVisible(X, Y) and pointVisible(X1, Y1) then begin
   Canvas.Stroke.Color := EnsureOpaqueAlpha(Pen.penColor);
   Canvas.DrawLine(PointF(XPix(X_), YPix(Y_)), PointF(XPix(X1_), YPix(Y1_)), 1);
  end else
  If lineVisible(X, Y, X1, Y1) then
   If cutLine(XMin+C, YMin+C, XMax-C, YMax-C, X_,Y_,X1_,Y1_) then begin
    If (XPix(X_) > Self.Width) or (XPix(X1_) > Self.Width) or (YPix(Y_) > Self.Height) or (YPix(Y1_) > Self.Height) then exit;
    Canvas.Stroke.Color := EnsureOpaqueAlpha(Pen.penColor);
    Canvas.DrawLine(PointF(XPix(X_), YPix(Y_)), PointF(XPix(X1_), YPix(Y1_)), 1);
   end;
end;

procedure TogsDrawerCanvas.DrawPolyline(Points: TogsCollection; cutRequest: Boolean);
var
 I: Integer;
 P0: TDot;
 Path: TPathData;
 R: TogsRect;
begin
 if (Points = nil) or (Points.Count < 2) then Exit;
 if cutRequest then begin
  R := TogsRect.Create;
  try
   for I := 0 to Points.Count - 1 do begin
    P0 := TDot(Points.Items[I]);
    R.Insert(P0.fX, P0.fY);
   end;
   if not ogsSelector.RectVisible(R) then Exit;
  finally
   R.Free;
  end;
 end;
 Path := TPathData.Create;
 try
  P0 := TDot(Points.Items[0]);
  Path.MoveTo(PointF(ogsSelector.XPix(P0.fX), ogsSelector.YPix(P0.fY)));
  for I := 1 to Points.Count - 1 do begin
   P0 := TDot(Points.Items[I]);
   Path.LineTo(PointF(ogsSelector.XPix(P0.fX), ogsSelector.YPix(P0.fY)));
  end;
  Canvas.Stroke.Color := EnsureOpaqueAlpha(Pen.penColor);
  Canvas.DrawPath(Path, 1);
 finally
  Path.Free;
 end;
end;

procedure TogsDrawerCanvas.DrawPolygon(Points: TogsCollection; polyRect: TogsRect);
var AllLin: TPolygon;
    I, XI, YI: Integer;
    X, Y: Double;
begin
 SetLength(AllLin, Points.Count);
 For I := 0 to Points.Count - 1 do
  With ogsSelector do
   With TlDot(Points[I]) do begin
    AllLin[I] := PointF(XPix(XDot), YPix(YDot));
    XI := XPix(XDot);
    YI := YPix(YDot);
    X := TlDot(Points[I]).XDot;
    Y := TlDot(Points[I]).YDot;
    XPix(0);
//    WriteIn(['Poly=',I, Alllin[I].X, Alllin[I].Y]);
   end;
 Canvas.Fill.Color := EnsureOpaqueAlpha(Brush.brColor);
 Canvas.FillPolygon(AllLin, Points.Count);
end;

procedure TogsDrawerCanvas.DrawPolyPolygon(Polygons: TogsCollection;
 polyRect: TogsRect);
var
 I, J: Integer;
 Poly: TogsCollection;
 P: TPointF;
 Path: TPathData;
begin
 If Disable then exit;
 Path := TPathData.Create;
 try
  With ogsSelector do
   for I := 0 to Polygons.Count - 1 do begin
    Poly := TogsCollection(Polygons[I]);
    if (Poly = nil) or (Poly.Count = 0) then Continue;
    with TDot(Poly[0]) do P := PointF(XPix(X), YPix(Y));
    Path.MoveTo(P);
    for J := 1 to Poly.Count - 1 do begin
     with TDot(Poly[J]) do P := PointF(XPix(X), YPix(Y));
     Path.LineTo(P);
    end;
    Path.ClosePath;
   end;
  Canvas.Fill.Color := Brush.brColor;
  Canvas.FillPath(Path, 1);
  Canvas.Stroke.Color := Pen.penColor;
  Canvas.DrawPath(Path, 1);
 finally
  Path.Free;
 end;
end;

destructor TogsDrawerCanvas.Destroy;
begin
 inherited;
 Bitmap.Free;
end;

procedure TogsDrawerCanvas.DrawCircle(XA, YA, Radius: Double);
const N: Integer = 25;
var
    I: Integer;
    Col: TogsCollection;
    D1, D2: TlDot;
begin
 If Disable then exit;
 Col := circle( XA, YA, Radius, N);
 For I := 0 to Col.Count - 2 do begin
  D1 := Col[I]; D2 := Col[I + 1];
  DrawLine(D1.XDot, D1.YDot, D2.XDot, D2.YDot);
 end;
 Col.Free;
end;

procedure TogsDrawerCanvas.MoveTo(X, Y: Integer);
begin
 FLastPoint := PointF(X, Y);
end;

procedure TogsDrawerCanvas.LineTo(X, Y: Integer);
begin
 Canvas.DrawLine(FLastPoint, PointF(X, Y), 1);
 FLastPoint := PointF(X, Y);
end;

function TogsDrawerCanvas.geoWidth: Double;
begin
 Result := ogsSelector.activeRect.XMax - ogsSelector.activeRect.XMin;
end;

function TogsDrawerCanvas.geoHeight: Double;
begin
 Result := ogsSelector.activeRect.YMax - ogsSelector.activeRect.YMin;
end;

procedure TogsDrawerCanvas.BeginPaint;
begin
 if FInScene then Exit;
 if Bitmap.Canvas.BeginScene then
  FInScene := True;
end;

procedure TogsDrawerCanvas.EndPaint;
begin
 if not FInScene then Exit;
 Bitmap.Canvas.EndScene;
 FInScene := False;
end;

procedure TogsDrawerCanvas.DrawTo(Image_: TCanvas; Rect: TRect);
var
 Dst: TRectF;
begin
 Dst := RectF(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
 Image_.DrawBitmap(Bitmap, RectF(0, 0, Bitmap.Width, Bitmap.Height), Dst, 1, False);
end;

end.

