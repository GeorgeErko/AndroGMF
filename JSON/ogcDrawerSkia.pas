unit ogcDrawerSkia;

interface

uses
  FMX.Skia,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Math,
  System.Math.Vectors,
  System.Generics.Collections,
  FMX.Graphics,
  FMX.Types,
  System.Skia,
  newFontScale,
  ogcBasic,
  ogcMathUtils,
  TwgDraw,
  newResource;

procedure RegisterSkiaFontFile(const FamilyName, FileName: string);
function GetRegisteredSkiaFontFile(const FamilyName: string): string;

type
  PCaptureRec = ^TCaptureRec;

  TogsSkiaObject = class
  private
    FPicture: ISkPicture;
    FId: Int64;
    FUserObject: TObject;
    FBoundsWorld: TRectF;
    FCheck: Byte;
    FLayer: TResource;
  public
    procedure Draw(const ACanvas: ISkCanvas);
    property Picture: ISkPicture read FPicture write FPicture;
    property Id: Int64 read FId write FId;
    property UserObject: TObject read FUserObject write FUserObject;
    property BoundsWorld: TRectF read FBoundsWorld write FBoundsWorld;
    property Check: Byte read FCheck write FCheck;
    property Layer: TResource read FLayer write FLayer;
  end;

  TogsSkiaList = class(TObjectList<TogsSkiaObject>)
  public
    procedure DrawAll(const ACanvas: ISkCanvas);
  end;

  TogsDrawerSkia = class(TogsSpacer)
  private
    FWidth: Integer;
    FHeight: Integer;
    FBitmap: TBitmap;
    FInScene: Boolean;
    FSkPainter: TSkPaintBox;
    FSkCanvas: ISkCanvas;
    FDest: TRectF;
    FUseWorldCoords: Boolean;
    FSkiaList: TogsSkiaList;
    FDebugDrawTextBounds: Boolean;
    FPrimitiveRecorder: ISkPictureRecorder;
    FPrimitiveCanvas: ISkCanvas;
    FPrimitiveOldCanvas: ISkCanvas;
    FPrimitiveId: Int64;
    FPrimitiveUserObject: TTD;
    FPrimitiveBoundsWorld: TRectF;
    function GetHeight: Integer; override;
    function GetWidth: Integer; override;
    procedure SetHeight(AValue: Integer); override;
    procedure SetWidth(AValue: Integer); override;
  protected
    function GetCanvas: TCanvas; override;
    procedure SetPen(AValue: TogsPen); override;
    procedure SetBrush(AValue: TogsBrush); override;
  public
    constructor Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent; SkPainter_: TSkPaintBox);
    destructor Destroy; override;

    procedure BeginFrame(const ACanvas: ISkCanvas; const ADest: TRectF);
    procedure EndFrame;

    procedure Clear(AColor: Longint); override;

    procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
    procedure DrawPolyline(Points: TogsCollection; cutRequest: Boolean = True); override;
    procedure DrawPolygon(Points: TogsCollection; polyRect: TogsRect); override;
    procedure DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect); override;
    procedure DrawCircle(XA, YA, Radius: Double); override;

    procedure MoveTo(X, Y: Integer); override;
    procedure LineTo(X, Y: Integer); override;

    function geoWidth: Double; override;
    function geoHeight: Double; override;

    procedure BeginPaint; override;
    procedure EndPaint; override;

    procedure DrawTextAlignedPix(const AnchorPix: TPointF; const Text: string;
      const Color: TAlphaColor; const FontSizePix: Single;
      const AngleRad: Single; const XP, YP: Double;
      const XKoef: Double = 1; const FontView: TFontViewEx = nil;
      const AAntiAlias: Boolean = True); virtual;

    procedure DrawBitmapAlignedPix(const AnchorPix: TPointF;
      const Bitmap: TBitmap; const Dst: TRectF; const AngleRad: Single);
      virtual;

    procedure DrawTo(Image_: TCanvas; Rect: TRect); override;

    procedure RedrawAll; override;

    procedure ClearSkiaList;
    procedure DrawSkiaList(const ACanvas: ISkCanvas);

    procedure BeginPrimitive(const AId: Int64; const AUserObject: TTD);
    procedure EndPrimitive;

    property Bitmap: TBitmap read FBitmap;
    property UseWorldCoords: Boolean read FUseWorldCoords write FUseWorldCoords;
    property DebugDrawTextBounds: Boolean read FDebugDrawTextBounds write FDebugDrawTextBounds;
    property SkiaList: TogsSkiaList read FSkiaList;
    property skPainter: TSkPaintBox read FskPainter;
    property SkCanvas: ISkCanvas read FSkCanvas;
  end;

  TogsCaptureDrawerSkia = class(TogsDrawerSkia)
  private
    FCapture: PCaptureRec;
    FCaptureX: Double;
    FCaptureY: Double;
    FCurrentUserObject: TObject;
    ForgDrawer: TogsDrawer;
    procedure ConsiderLine(const X0, Y0, X1, Y1: Double);
    procedure ConsiderLinePix(const X0, Y0, X1, Y1: Double);
    procedure ConsiderPolygon(const Points: TogsCollection);
  public
    constructor CreateCapture(Selector: TogsSelector); reintroduce;
    destructor Destroy; override;
    procedure BeginCapture(const X, Y: Double; var Params: TCaptureRec);
    procedure EndCapture;

    procedure BeginPrimitive(const AId: Int64; const AUserObject: TTD); reintroduce;
    procedure EndPrimitive; reintroduce;

    procedure DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean = True); override;
    procedure DrawPolyline(Points: TogsCollection; cutRequest: Boolean = True); override;
    procedure DrawPolygon(Points: TogsCollection; polyRect: TogsRect); override;

    procedure DrawTextAlignedPix(const AnchorPix: TPointF; const Text: string;
      const Color: TAlphaColor; const FontSizePix: Single;
      const AngleRad: Single; const XP, YP: Double;
      const XKoef: Double = 1; const FontView: TFontViewEx = nil; const AAntiAlias: Boolean = True); override;

    procedure DrawBitmapAlignedPix(const AnchorPix: TPointF;
      const Bitmap: TBitmap; const Dst: TRectF; const AngleRad: Single); override;
  end;

implementation uses Writer, newProcs;

procedure RegisterSkiaFontFile(const FamilyName, FileName: string);
begin
  newFontScale.RegisterSkiaFontFile(FamilyName, FileName);
end;

function GetRegisteredSkiaFontFile(const FamilyName: string): string;
begin
  Result := newFontScale.GetRegisteredSkiaFontFile(FamilyName);
end;

function EnsureOpaqueAlpha(const C: TAlphaColor): TAlphaColor;
begin
  if (C shr 24) = 0 then
    Result := C or $FF000000
  else
    Result := C;
end;

{ TogsDrawerSkia }

constructor TogsDrawerSkia.Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent; SkPainter_: TSkPaintBox);
begin
  inherited Create(ogsSelector_, OnPaint_);
  fDrawerMode := dmScene;
  FWidth := 1;
  FHeight := 1;
  FBitmap := TBitmap.Create;
  FBitmap.SetSize(FWidth, FHeight);
  FInScene := False;
  FUseWorldCoords := False;
  FSkiaList := TogsSkiaList.Create(True);
  FSkPainter := SkPainter_;
end;

destructor TogsDrawerSkia.Destroy;
begin
  FSkiaList.Free;
  FSkiaList := nil;
   FBitmap.Free;
   FBitmap := nil;
  inherited;
 end;

{ TogsSkiaObject }

procedure TogsSkiaObject.Draw(const ACanvas: ISkCanvas);
begin
  if (ACanvas = nil) or (FPicture = nil) then
    Exit;

  if FLayer <> nil then
  begin
    if FLayer.Check = 0 then
      Exit;
  end
  else
  begin
    if FCheck = 0 then
      Exit;
  end;
  ACanvas.DrawPicture(FPicture);
end;

{ TogsSkiaList }

procedure TogsSkiaList.DrawAll(const ACanvas: ISkCanvas);
var
  I: Integer;
begin
  if ACanvas = nil then
    Exit;
  for I := 0 to Count - 1 do
    Items[I].Draw(ACanvas);
end;

procedure TogsDrawerSkia.BeginFrame(const ACanvas: ISkCanvas; const ADest: TRectF);
begin
  FSkCanvas := ACanvas;
  FDest := ADest;
  if FSkCanvas <> nil then
    FSkCanvas.Save;

  if (FBitmap <> nil) and ((FBitmap.Width <> FWidth) or (FBitmap.Height <> FHeight)) then
    FBitmap.SetSize(FWidth, FHeight);
end;

procedure TogsDrawerSkia.EndFrame;
begin
  if FSkCanvas <> nil then
    FSkCanvas.Restore;

  FSkCanvas := nil;
end;

procedure TogsDrawerSkia.ClearSkiaList;
begin
  if FSkiaList <> nil then
    FSkiaList.Clear;
end;

procedure TogsDrawerSkia.DrawSkiaList(const ACanvas: ISkCanvas);
begin
  if FSkiaList <> nil then
    FSkiaList.DrawAll(ACanvas);
end;

procedure TogsDrawerSkia.BeginPrimitive(const AId: Int64; const AUserObject: TTD);
begin
  if FSkCanvas = nil then
    Exit;
  if FPrimitiveRecorder <> nil then
    Exit;

  FPrimitiveId := AId;
  FPrimitiveUserObject := AUserObject;
  FPrimitiveBoundsWorld := FDest;

  FPrimitiveRecorder := TSkPictureRecorder.Create;
  FPrimitiveCanvas := FPrimitiveRecorder.BeginRecording(FPrimitiveBoundsWorld);
  FPrimitiveOldCanvas := FSkCanvas;
  FSkCanvas := FPrimitiveCanvas;
end;

procedure TogsDrawerSkia.EndPrimitive;
var
  Obj: TogsSkiaObject;
  L: TResource;
begin
  if FPrimitiveRecorder = nil then
    Exit;
  try
    Obj := TogsSkiaObject.Create;
    Obj.Id := FPrimitiveId;
    Obj.UserObject := FPrimitiveUserObject;
    Obj.BoundsWorld := FPrimitiveBoundsWorld;
    Obj.Picture := FPrimitiveRecorder.FinishRecording;
    L := nil;
    if FPrimitiveUserObject <> nil then
      L := FPrimitiveUserObject.GetLayer;
    Obj.Layer := L;
    if L <> nil then
      Obj.Check := L.Check
    else
      Obj.Check := 1;
    FPrimitiveUserObject.DrawerObject := Obj;
    if (FSkiaList <> nil) and (Obj.Picture <> nil) then
      FSkiaList.Add(Obj)
    else
      Obj.Free;
  finally
    FSkCanvas := FPrimitiveOldCanvas;
    FPrimitiveOldCanvas := nil;
    FPrimitiveCanvas := nil;
    FPrimitiveRecorder := nil;
    FPrimitiveUserObject := nil;
    FPrimitiveId := 0;
    FPrimitiveBoundsWorld := TRectF.Empty;
  end;
end;

function TogsDrawerSkia.GetCanvas: TCanvas;
begin
  Result := nil;
  if FBitmap <> nil then
    Result := FBitmap.Canvas;
end;

procedure TogsDrawerSkia.SetPen(AValue: TogsPen);
begin
  inherited SetPen(AValue);
end;

procedure TogsDrawerSkia.SetBrush(AValue: TogsBrush);
begin
  inherited SetBrush(AValue);
end;

function TogsDrawerSkia.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TogsDrawerSkia.GetWidth: Integer;
begin
  Result := FWidth;
end;

procedure TogsDrawerSkia.SetHeight(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FHeight := AValue;
  if FBitmap <> nil then
    FBitmap.SetSize(FWidth, FHeight);
end;

procedure TogsDrawerSkia.SetWidth(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FWidth := AValue;
  if FBitmap <> nil then
    FBitmap.SetSize(FWidth, FHeight);
end;

procedure TogsDrawerSkia.Clear(AColor: LongInt);
var
  Paint: ISkPaint;
begin
  if FSkCanvas <> nil then
    FSkCanvas.Clear(AColor);

  if (FBitmap <> nil) and FInScene then
    FBitmap.Canvas.Clear(AColor);

  Paint := nil;
end;

procedure TogsDrawerSkia.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
var
  Paint: ISkPaint;
  P0, P1: TPointF;
  X_, Y_, X1_, Y1_: Double;
  D: Single;
begin
  if Disable then
    Exit;
  if ogsSelector = nil then
    Exit;

//  if (Pen.penColor shr 24) = 0 then
//    Exit;

  X_ := X;
  Y_ := Y;
  X1_ := X1;
  Y1_ := Y1;

  If GlobalRender then cutRequest := False;

  if cutRequest then
    with ogsSelector, ActiveRect do
      if not lineVisible(X_, Y_, X1_, Y1_) then
        Exit;

  if FUseWorldCoords then
  begin
    P0 := PointF(Single(X_), Single(Y_));
    P1 := PointF(Single(X1_), Single(Y1_));
  end
  else
  begin
    P0 := PointF(ogsSelector.XPix(X_), ogsSelector.YPix(Y_));
    P1 := PointF(ogsSelector.XPix(X1_), ogsSelector.YPix(Y1_));
  end;

  if FSkCanvas <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := False;
    Paint.Style := TSkPaintStyle.Stroke;
    Paint.Color := EnsureOpaqueAlpha(Pen.penColor);
   if Pen.penWidth > 0 then
    begin
      if FUseWorldCoords and (ogsSelector.GetScale > 0) then begin
        D := Max(0.03, Pen.penWidth);
        Paint.StrokeWidth := D;
      end
      else
        Paint.StrokeWidth := Max(1.0, Pen.penWidth);
    end
    else
      Paint.StrokeWidth := 0.03;
    FSkCanvas.DrawLine(P0.X, P0.Y, P1.X, P1.Y, Paint);
  end
  else if Canvas <> nil then begin
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := EnsureOpaqueAlpha(Pen.penColor);
   Canvas.Stroke.Thickness := Max(1.0, Pen.penWidth);
    Canvas.DrawLine(P0, P1, 1);
  end;
end;

procedure TogsDrawerSkia.DrawPolyline(Points: TogsCollection; cutRequest: Boolean);
var
  I: Integer;
  P0: TlDot;
  PathBuilder: ISkPathBuilder;
  Path: ISkPath;
  Paint: ISkPaint;
  R: TogsRect;
  D: Single;
begin
  if (Points = nil) or (Points.Count < 2) then
    Exit;
  if ogsSelector = nil then
    Exit;

  if cutRequest then
  begin
    R := TogsRect.Create;
    try
      for I := 0 to Points.Count - 1 do
      begin
        P0 := TlDot(Points.Items[I]);
        R.Insert(P0.XDot, P0.YDot);
      end;
      if (not ogsSelector.RectVisible(R)) and (not GlobalRender) then
        Exit;
    finally
      R.Free;
    end;
  end;

  if FSkCanvas <> nil then
  begin
    PathBuilder := TSkPathBuilder.Create;
    P0 := TlDot(Points.Items[0]);
    if FUseWorldCoords then
      PathBuilder.MoveTo(Single(P0.XDot), Single(P0.YDot))
    else
      PathBuilder.MoveTo(ogsSelector.XPix(P0.XDot), ogsSelector.YPix(P0.YDot));
    for I := 1 to Points.Count - 1 do
    begin
      P0 := TlDot(Points.Items[I]);
      if FUseWorldCoords then
        PathBuilder.LineTo(Single(P0.XDot), Single(P0.YDot))
      else
        PathBuilder.LineTo(ogsSelector.XPix(P0.XDot), ogsSelector.YPix(P0.YDot));
    end;
    Path := PathBuilder.Detach;

    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    Paint.Style := TSkPaintStyle.Stroke;
    Paint.Color := EnsureOpaqueAlpha(Pen.penColor);
    if FUseWorldCoords and (ogsSelector.GetScale > 0) then begin
      D := Max(0.03, Pen.penWidth);
      Paint.StrokeWidth := D;
    end   else
      Paint.StrokeWidth := Max(1.0, Pen.penWidth);
    FSkCanvas.DrawPath(Path, Paint);
  end
  else if Canvas <> nil then
  begin
    for I := 0 to Points.Count - 2 do
    begin
      P0 := TlDot(Points.Items[I]);
      DrawLine(P0.XDot, P0.YDot, TlDot(Points.Items[I + 1]).XDot, TlDot(Points.Items[I + 1]).YDot, False);
    end;
  end;
end;

procedure TogsDrawerSkia.DrawPolygon(Points: TogsCollection; polyRect: TogsRect);
var
  I: Integer;
  P0: TlDot;
  PathBuilder: ISkPathBuilder;
  Path: ISkPath;
  Paint: ISkPaint;
  XP, YP: Integer;
begin
  if (Points = nil) or (Points.Count < 3) then
    Exit;
  if ogsSelector = nil then
    Exit;

  if FSkCanvas <> nil then
  begin
    PathBuilder := TSkPathBuilder.Create;
    P0 := TlDot(Points[0]);
    if FUseWorldCoords then
      PathBuilder.MoveTo(P0.XDot, P0.YDot)
    else
      PathBuilder.MoveTo(ogsSelector.XPix(P0.XDot), ogsSelector.YPix(P0.YDot));
    for I := 1 to Points.Count - 1 do
    begin
      P0 := TlDot(Points[I]);
      if FUseWorldCoords then
        PathBuilder.LineTo(Single(P0.XDot), Single(P0.YDot))
      else
        PathBuilder.LineTo(ogsSelector.XPix(P0.XDot), ogsSelector.YPix(P0.YDot));
    end;
    PathBuilder.Close;
    Path := PathBuilder.Detach;

    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    Paint.Style := TSkPaintStyle.Fill;
    Paint.Color := EnsureOpaqueAlpha(Brush.brColor);
    FSkCanvas.DrawPath(Path, Paint);
  end
  else if Canvas <> nil then
  begin
    // fallback: use existing canvas drawing by polyline
    for I := 0 to Points.Count - 2 do
      DrawLine(TlDot(Points[I]).XDot, TlDot(Points[I]).YDot, TlDot(Points[I + 1]).XDot, TlDot(Points[I + 1]).YDot, False);
  end;
end;

procedure TogsDrawerSkia.DrawPolyPolygon(Polygons: TogsCollection; polyRect: TogsRect);
var
  I: Integer;
  Poly: TogsCollection;
begin
  if (Polygons = nil) or (Polygons.Count = 0) then
    Exit;
  for I := 0 to Polygons.Count - 1 do
  begin
    Poly := TogsCollection(Polygons[I]);
    if (Poly <> nil) and (Poly.Count >= 3) then
      DrawPolygon(Poly, polyRect);
  end;
end;

procedure TogsDrawerSkia.DrawCircle(XA, YA, Radius: Double);
var
  Paint: ISkPaint;
  C: TPointF;
  R: Single;
begin
  if ogsSelector = nil then
    Exit;
  if FUseWorldCoords then
  begin
    C := PointF(Single(XA), Single(YA));
    R := Single(Radius);
  end
  else
  begin
    C := PointF(ogsSelector.XPix(XA), ogsSelector.YPix(YA));
    R := Radius * ogsSelector.GetScale;
  end;

  if FSkCanvas <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    Paint.Style := TSkPaintStyle.Stroke;
    Paint.Color := EnsureOpaqueAlpha(Pen.penColor);
    if FUseWorldCoords and (ogsSelector.GetScale > 0) then
      Paint.StrokeWidth := Max(1.0, Pen.penWidth / ogsSelector.GetScale)
    else
      Paint.StrokeWidth := Max(1.0, Pen.penWidth);
    FSkCanvas.DrawCircle(C.X, C.Y, R, Paint);
  end
  else if Canvas <> nil then
  begin
    Canvas.Stroke.Color := EnsureOpaqueAlpha(Pen.penColor);
    Canvas.DrawEllipse(RectF(C.X - R, C.Y - R, C.X + R, C.Y + R), 1);
  end;
end;

procedure TogsDrawerSkia.MoveTo(X, Y: Integer);
begin
  if Canvas <> nil then
   // Canvas.MoveTo(PointF(X, Y));
end;

procedure TogsDrawerSkia.RedrawAll;
begin
 If FSkPainter <> nil then
  FSkPainter.Redraw;
end;

procedure TogsDrawerSkia.LineTo(X, Y: Integer);
begin
  if Canvas <> nil then
   // Canvas.LineTo(PointF(X, Y));
end;

function TogsDrawerSkia.geoWidth: Double;
begin
  if ogsSelector <> nil then
    Result := ogsSelector.activeRect.XMax - ogsSelector.activeRect.XMin
  else
    Result := Width;
end;

function TogsDrawerSkia.geoHeight: Double;
begin
  if ogsSelector <> nil then
    Result := ogsSelector.activeRect.YMax - ogsSelector.activeRect.YMin
  else
    Result := Height;
end;

procedure TogsDrawerSkia.BeginPaint;
begin
  if FInScene then
    Exit;
  if (FBitmap <> nil) and (FBitmap.Canvas <> nil) then
    if FBitmap.Canvas.BeginScene then
      FInScene := True;
end;

procedure TogsDrawerSkia.EndPaint;
begin
  if not FInScene then
    Exit;
  if (FBitmap <> nil) and (FBitmap.Canvas <> nil) then
    FBitmap.Canvas.EndScene;
  FInScene := False;
end;

procedure TogsDrawerSkia.DrawBitmapAlignedPix(const AnchorPix: TPointF; const Bitmap: TBitmap;
  const Dst: TRectF; const AngleRad: Single);
var
  D: TBitmapData;
  Img: ISkImage;
  Paint: ISkPaint;
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  Pixmap: ISkPixmap;
  OldColor: TAlphaColor;
  OldWidth: Single;
  AnchorC: TPointF;
  C, S: Single;
  P0, P1, P2, P3: TPointF;
  X0, Y0, X1, Y1: Double;
  MS: TMemoryStream;
begin
  if Disable then
    Exit;
  if (FSkCanvas = nil) or (Bitmap = nil) then
    Exit;
  if (Bitmap.Width <= 0) or (Bitmap.Height <= 0) then
    Exit;

  Img := nil;

{$IFDEF ANDROID}
  // На Android создаём изображение через кодек (SaveToStream + MakeFromEncodedStream),
  // чтобы обойти возможные несоответствия формата сырых пикселей.
  MS := TMemoryStream.Create;
  try
    Bitmap.SaveToStream(MS);
    MS.Position := 0;
    Img := TSkImage.MakeFromEncodedStream(MS);
  finally
    MS.Free;
  end;
{$ENDIF}

  // Общий путь: если по какой‑то причине Img всё ещё nil, пробуем чтение сырых пикселей.
  if Img = nil then
  begin
    if Bitmap.Map(TMapAccess.Read, D) then
    try
      ImgInfo := TSkImageInfo.Create(Bitmap.Width, Bitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
      Surface := TSkSurface.MakeRasterDirect(ImgInfo, D.Data, D.Pitch);
      if Surface <> nil then
      begin
        Pixmap := Surface.PeekPixels;
        if Pixmap <> nil then
          Img := TSkImage.MakeFromRaster(Pixmap);
      end;
    finally
      Bitmap.Unmap(D);
    end;
  end;

  if Img = nil then
    Exit;

  FSkCanvas.Save;
  try
    FSkCanvas.Translate(AnchorPix.X, AnchorPix.Y);
    if Abs(AngleRad) > 1e-6 then
      FSkCanvas.Rotate(AngleRad * 180 / Pi);
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    FSkCanvas.DrawImageRect(Img, Dst, Paint);
  finally
    FSkCanvas.Restore;
  end;

  AnchorC := AnchorPix;
  P0 := PointF(Dst.Left, Dst.Top);
  P1 := PointF(Dst.Right, Dst.Top);
  P2 := PointF(Dst.Right, Dst.Bottom);
  P3 := PointF(Dst.Left, Dst.Bottom);
  if Abs(AngleRad) > 1e-6 then
  begin
    C := Cos(AngleRad);
    S := Sin(AngleRad);
    P0 := PointF(P0.X * C - P0.Y * S, P0.X * S + P0.Y * C);
    P1 := PointF(P1.X * C - P1.Y * S, P1.X * S + P1.Y * C);
    P2 := PointF(P2.X * C - P2.Y * S, P2.X * S + P2.Y * C);
    P3 := PointF(P3.X * C - P3.Y * S, P3.X * S + P3.Y * C);
  end;
  P0 := PointF(P0.X + AnchorC.X, P0.Y + AnchorC.Y);
  P1 := PointF(P1.X + AnchorC.X, P1.Y + AnchorC.Y);
  P2 := PointF(P2.X + AnchorC.X, P2.Y + AnchorC.Y);
  P3 := PointF(P3.X + AnchorC.X, P3.Y + AnchorC.Y);

  OldColor := Pen.penColor;
  OldWidth := Pen.penWidth;
  Pen.penColor := TAlphaColor($00000000);
  Pen.penWidth := 0;
  try
    if UseWorldCoords then
    begin
    //  DrawLine(P0.X, P0.Y, P1.X, P1.Y, False);
    //  DrawLine(P1.X, P1.Y, P2.X, P2.Y, False);
    //  DrawLine(P2.X, P2.Y, P3.X, P3.Y, False);
    //  DrawLine(P3.X, P3.Y, P0.X, P0.Y, False);
//     WriteIn(['DrawRect=',P0.X, P0.Y, P1.X, P1.Y,  P2.X, P2.Y, P3.X, P3.Y]);
    end
    else
    begin
      X0 := ogsSelector.XGeo(Round(P0.X)); Y0 := ogsSelector.YGeo(Round(P0.Y));
      X1 := ogsSelector.XGeo(Round(P1.X)); Y1 := ogsSelector.YGeo(Round(P1.Y));
      DrawLine(X0, Y0, X1, Y1, False);
      X0 := ogsSelector.XGeo(Round(P1.X)); Y0 := ogsSelector.YGeo(Round(P1.Y));
      X1 := ogsSelector.XGeo(Round(P2.X)); Y1 := ogsSelector.YGeo(Round(P2.Y));
      DrawLine(X0, Y0, X1, Y1, False);
      X0 := ogsSelector.XGeo(Round(P2.X)); Y0 := ogsSelector.YGeo(Round(P2.Y));
      X1 := ogsSelector.XGeo(Round(P3.X)); Y1 := ogsSelector.YGeo(Round(P3.Y));
      DrawLine(X0, Y0, X1, Y1, False);
      X0 := ogsSelector.XGeo(Round(P3.X)); Y0 := ogsSelector.YGeo(Round(P3.Y));
      X1 := ogsSelector.XGeo(Round(P0.X)); Y1 := ogsSelector.YGeo(Round(P0.Y));
      DrawLine(X0, Y0, X1, Y1, False);
    end;
  finally
    Pen.penColor := OldColor;
    Pen.penWidth := OldWidth;
  end;
end;

procedure TogsDrawerSkia.DrawTextAlignedPix(const AnchorPix: TPointF; const Text: string;
  const Color: TAlphaColor; const FontSizePix: Single; const AngleRad: Single;
  const XP, YP: Double; const XKoef: Double; const FontView: TFontViewEx; const AAntiAlias: Boolean);
var
  Paint: ISkPaint;
  DebugPaint: ISkPaint;
  Typeface: ISkTypeface;
  Font: ISkFont;
  ProbeFont: ISkFont;
  FontStyle: TSkFontStyle;
  Weight: TSkFontWeight;
  Slant: TSkFontSlant;
  Metrics: TSkFontMetrics;
  ProbeMetrics: TSkFontMetrics;
  Bounds: TRectF;
  DrawX, DrawY: Single;
  LocalFontName: string;
  EffectiveFontSize: Single;
  Oversample: Single;
  ProbeSize: Single;
  AscentRatio: Single;
  AscentAbs: Single;
  TightAscentAbs: Single;
  AscentAlign: Single;
  ScaleCorr: Single;
  R: TRectF;
  RBox: TRectF;
  AnchorC: TPointF;
  C, S: Single;
  SX: Single;
  P0, P1, P2, P3: TPointF;
  OldColor: TAlphaColor;
  OldWidth: Single;
  X0, Y0, X1, Y1: Double;
begin
  if (FSkCanvas = nil) or (Text = '') then
    Exit;

  Paint := TSkPaint.Create;
  Paint.AntiAlias := AAntiAlias;
  Paint.Color := EnsureOpaqueAlpha(Color);

  if FontView <> nil then
    LocalFontName := newFontScale.NormalizeSkiaFontFamilyName(string(FontView.FontName))
  else
    LocalFontName := '';

  Weight := TSkFontWeight.Normal;
  if (FontView <> nil) and (FontView.Bl <> 0) then
    Weight := TSkFontWeight.Bold;
  Slant := TSkFontSlant.Upright;
  if (FontView <> nil) and (FontView.It <> 0) then
    Slant := TSkFontSlant.Italic;
  FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

  if FontView <> nil then
    Typeface := newFontScale.ResolveSkiaTypefaceForView(FontView)
  else
    Typeface := newFontScale.ResolveSkiaTypeface(LocalFontName, False, False);

  Oversample := 1;
  if UseWorldCoords then
    Oversample := 10;

  ProbeSize := 100;
  ProbeFont := TSkFont.Create(Typeface, ProbeSize);
  ProbeFont.GetMetrics(ProbeMetrics);
  if (-ProbeMetrics.Ascent) > 0.01 then
    AscentRatio := (-ProbeMetrics.Ascent) / ProbeSize
  else
    AscentRatio := 1;

  EffectiveFontSize := (FontSizePix / AscentRatio) * Oversample;
  Font := TSkFont.Create(Typeface, EffectiveFontSize);
  Font.GetMetrics(Metrics);

  Font.MeasureText(Text, Bounds, Paint);

  // Text.Height semantics: FontSizePix is the desired ASCENT (Top->Baseline).
  // Skia line metrics ascent can be larger than glyph's tight bounds. To make the
  // visible glyph reach the ascent box, normalize using tight ascent (-Bounds.Top).
  TightAscentAbs := -Bounds.Top;
  if TightAscentAbs > 0.01 then
  begin
    ScaleCorr := (FontSizePix * Oversample) / TightAscentAbs;
    if Abs(ScaleCorr - 1) > 1e-4 then
    begin
      EffectiveFontSize := EffectiveFontSize * ScaleCorr;
      Font := TSkFont.Create(Typeface, EffectiveFontSize);
      Font.GetMetrics(Metrics);
      Font.MeasureText(Text, Bounds, Paint);
    end;
  end;

  DrawX := - (Bounds.Left + Single(XP) * Bounds.Width);
  AscentAlign := FontSizePix * Oversample;
  if YP < 0 then
    DrawY := 0
  else
    DrawY := AscentAlign * (1 - Single(YP));

  // Bounding box for the "ascent only" area: baseline is the bottom edge of the box.
  R := TRectF.Create(DrawX + Bounds.Left, DrawY - AscentAlign, DrawX + Bounds.Right, DrawY);

  FSkCanvas.Save;
  try
    FSkCanvas.Translate(AnchorPix.X, AnchorPix.Y);
    if Abs(AngleRad) > 1e-6 then
      FSkCanvas.Rotate(AngleRad * 180 / Pi);
    if Abs(Oversample - 1) > 1e-6 then
      FSkCanvas.Scale(1 / Oversample, 1 / Oversample);
    if Abs(XKoef - 1) > 1e-6 then
      FSkCanvas.Scale(Single(XKoef), 1);
    FSkCanvas.DrawSimpleText(Text, DrawX, DrawY, Font, Paint);
  //
    if DebugDrawTextBounds then
    begin
      DebugPaint := TSkPaint.Create;
      DebugPaint.AntiAlias := True;
      DebugPaint.Style := TSkPaintStyle.Stroke;
      DebugPaint.Color := Paint.Color;
      DebugPaint.StrokeWidth := 0.1;
      FSkCanvas.DrawLine(R.Left, R.Top, R.Right, R.Top, DebugPaint);
      FSkCanvas.DrawLine(R.Right, R.Top, R.Right, R.Bottom, DebugPaint);
      FSkCanvas.DrawLine(R.Right, R.Bottom, R.Left, R.Bottom, DebugPaint);
      FSkCanvas.DrawLine(R.Left, R.Bottom, R.Left, R.Top, DebugPaint);
    end;
  finally
    FSkCanvas.Restore;
  end;
end;

procedure TogsDrawerSkia.DrawTo(Image_: TCanvas; Rect: TRect);
begin
  // Not used in Skia paintbox path
end;

{ TogsCaptureDrawerSkia }

constructor TogsCaptureDrawerSkia.CreateCapture(Selector: TogsSelector);
begin
  inherited Create(nil, nil, nil);
  ForgDrawer := Selector.ogsDrawer;
//  WriteIn(['CreateCapture=', ForgDrawer.ClassName]);
  Width := ForgDrawer.Width;
  Height := ForgDrawer.Height;
  if ForgDrawer is TogsDrawerSkia then
    UseWorldCoords := TogsDrawerSkia(ForgDrawer).UseWorldCoords
  else
    UseWorldCoords := True;
  Selector.ogsDrawer := Self;
  fOgsSelector := Selector;
  fDrawerMode := dmCapture;
end;

destructor TogsCaptureDrawerSkia.Destroy;
begin
 if (fogsSelector <> nil) and (fogsSelector.ogsDrawer = Self) then
  fogsSelector.ogsDrawer := ForgDrawer;
//   WriteIn(['FreeCapture=', ForgDrawer.ClassName]);
 inherited;
end;

procedure TogsCaptureDrawerSkia.BeginCapture(const X, Y: Double; var Params: TCaptureRec);
begin
  FCapture := @Params;
  FCaptureX := X;
  FCaptureY := Y;
  FCurrentUserObject := nil;
end;

procedure TogsCaptureDrawerSkia.EndCapture;
begin
  FCapture := nil;
  FCurrentUserObject := nil;
end;

procedure TogsCaptureDrawerSkia.BeginPrimitive(const AId: Int64; const AUserObject: TTD);
begin
  FCurrentUserObject := AUserObject;
end;

procedure TogsCaptureDrawerSkia.EndPrimitive;
begin
  FCurrentUserObject := nil;
end;

procedure TogsCaptureDrawerSkia.ConsiderLine(const X0, Y0, X1, Y1: Double);
var
  PX, PY: Double;
  AX, AY: Double;
  BX, BY: Double;
  VX, VY, WX, WY: Double;
  C1, C2, T: Double;
  CX, CY: Double;
  DistPix: Double;
  DistScore: Double;
  Threshold: Double;
begin
  if (FCapture = nil) or (ogsSelector = nil) then
    Exit;
  if not (ckLine in FCapture^.CaptureFor) then
    Exit;

  if UseWorldCoords then
  begin
    PX := FCaptureX;
    PY := FCaptureY;
    AX := X0;
    AY := Y0;
    BX := X1;
    BY := Y1;
    Threshold := ogsSelector.geoDist(FCapture^.CaptureParam);
  end
  else
  begin
    ConsiderLinePix(
      ogsSelector.XPix(X0), ogsSelector.YPix(Y0),
      ogsSelector.XPix(X1), ogsSelector.YPix(Y1)
    );
    Exit;
  end;

  VX := BX - AX;
  VY := BY - AY;
  WX := PX - AX;
  WY := PY - AY;
  C1 := VX * WX + VY * WY;
  if C1 <= 0 then
  begin
    CX := AX;
    CY := AY;
    DistPix := Hypot(PX - AX, PY - AY);
  end
  else
  begin
    C2 := VX * VX + VY * VY;
    if C2 <= 1e-18 then
    begin
      CX := AX;
      CY := AY;
      DistPix := Hypot(PX - AX, PY - AY);
    end
    else if C1 >= C2 then
    begin
      CX := BX;
      CY := BY;
      DistPix := Hypot(PX - BX, PY - BY);
    end
    else
    begin
      T := C1 / C2;
      CX := AX + T * VX;
      CY := AY + T * VY;
      DistPix := Hypot(PX - CX, PY - CY);
    end;
  end;

  if UseWorldCoords then
    DistScore := ogsSelector.pixDist(DistPix)
  else
    DistScore := DistPix;

  if (DistPix <= Threshold) and
     ((FCapture^.resObject = nil) or (DistScore < FCapture^.resCapture)) then
  begin
    FCapture^.resCapture := Round(DistScore);
    FCapture^.resObject := FCurrentUserObject;
    FCapture^.resCaptureOf := ckLine;
    if UseWorldCoords then
    begin
      FCapture^.XCapture := CX;
      FCapture^.YCapture := CY;
    end
    else
    begin
      FCapture^.XCapture := ogsSelector.XGeo(Round(CX));
      FCapture^.YCapture := ogsSelector.YGeo(Round(CY));
    end;

    if FCurrentUserObject <> nil then
     // Writein([Format('capLine obj=%s dist=%.6f score=%.3f thr=%.6f', [FCurrentUserObject.ClassName, DistPix, DistScore, Threshold])])
    else
     // Writein([Format('capLine obj=nil dist=%.6f score=%.3f thr=%.6f', [DistPix, DistScore, Threshold])]);
  end;
end;

procedure TogsCaptureDrawerSkia.ConsiderLinePix(const X0, Y0, X1, Y1: Double);
var PX, PY: Double; AX, AY: Double; BX, BY: Double;
    VX, VY, WX, WY: Double; C1, C2, T: Double; CX, CY: Double;
    DistPix: Double; DistScore: Double; Threshold: Double;
begin
  if (FCapture = nil) or (ogsSelector = nil) then
    Exit;
  if not (ckLine in FCapture^.CaptureFor) then
    Exit;
  if UseWorldCoords then
    Exit;

  PX := ogsSelector.XPix(FCaptureX);
  PY := ogsSelector.YPix(FCaptureY);
  AX := X0;
  AY := Y0;
  BX := X1;
  BY := Y1;
  Threshold := FCapture^.CaptureParam;

  VX := BX - AX;
  VY := BY - AY;
  WX := PX - AX;
  WY := PY - AY;
  C1 := VX * WX + VY * WY;
  if C1 <= 0 then
  begin
    CX := AX;
    CY := AY;
    DistPix := Hypot(PX - AX, PY - AY);
  end
  else
  begin
    C2 := VX * VX + VY * VY;
    if C2 <= 1e-18 then
    begin
      CX := AX;
      CY := AY;
      DistPix := Hypot(PX - AX, PY - AY);
    end
    else if C1 >= C2 then
    begin
      CX := BX;
      CY := BY;
      DistPix := Hypot(PX - BX, PY - BY);
    end
    else
    begin
      T := C1 / C2;
      CX := AX + T * VX;
      CY := AY + T * VY;
      DistPix := Hypot(PX - CX, PY - CY);
    end;
  end;

  DistScore := DistPix;
  if (DistPix <= Threshold) and
     ((FCapture^.resObject = nil) or (DistScore < FCapture^.resCapture)) then
  begin
    FCapture^.resCapture := Round(DistScore);
    FCapture^.resObject := FCurrentUserObject;
    FCapture^.resCaptureOf := ckLine;
    FCapture^.XCapture := ogsSelector.XGeo(Round(CX));
    FCapture^.YCapture := ogsSelector.YGeo(Round(CY));
  end;
end;

procedure TogsCaptureDrawerSkia.ConsiderPolygon(const Points: TogsCollection);
var
  I, J: Integer;
  Xi, Yi, Xj, Yj: Double;
  Inside: Boolean;
  PObj: TObject;
  MinX, MinY, MaxX, MaxY: Double;

  function GetPointXY(const AIndex: Integer; out AX, AY: Double): Boolean;
  begin
    Result := False;
    if (AIndex < 0) or (AIndex >= Points.Count) then
      Exit;
    PObj := TObject(Points.Items[AIndex]);
    if PObj = nil then
      Exit;
    if PObj is TlDot then
    begin
      AX := TlDot(PObj).XDot;
      AY := TlDot(PObj).YDot;
      Exit(True);
    end;
    if PObj is TogsDot then
    begin
      AX := TogsDot(PObj).fX;
      AY := TogsDot(PObj).fY;
      Exit(True);
    end;
  end;
begin
  if (FCapture = nil) then
    Exit;
  if not ((ckPolygon in FCapture^.CaptureFor) or (ckSinglePolygon in FCapture^.CaptureFor)) then
    Exit;
  if (Points = nil) or (Points.Count < 3) then
    Exit;

  if FCapture^.resObject <> nil then
    Exit;

  if not GetPointXY(0, MinX, MinY) then
    Exit;
  MaxX := MinX;
  MaxY := MinY;
  for I := 1 to Points.Count - 1 do
    if GetPointXY(I, Xi, Yi) then
    begin
      if Xi < MinX then MinX := Xi;
      if Xi > MaxX then MaxX := Xi;
      if Yi < MinY then MinY := Yi;
      if Yi > MaxY then MaxY := Yi;
    end;
  if (FCaptureX < MinX) or (FCaptureX > MaxX) or (FCaptureY < MinY) or (FCaptureY > MaxY) then
    Exit;

  Inside := False;
  J := Points.Count - 1;
  for I := 0 to Points.Count - 1 do
  begin
    if (not GetPointXY(I, Xi, Yi)) or (not GetPointXY(J, Xj, Yj)) then
    begin
      J := I;
      Continue;
    end;
    if (((Yi > FCaptureY) <> (Yj > FCaptureY)) and
        (FCaptureX < (Xj - Xi) * (FCaptureY - Yi) / (Yj - Yi + 1e-30) + Xi)) then
      Inside := not Inside;
    J := I;
  end;

  if Inside then
  begin
    FCapture^.resCapture := MaxInt;
    FCapture^.resObject := FCurrentUserObject;
    FCapture^.resCaptureOf := ckPolygon;
    FCapture^.XCapture := FCaptureX;
    FCapture^.YCapture := FCaptureY;

    if FCurrentUserObject <> nil then
      Writein([Format('capPoly obj=%s', [FCurrentUserObject.ClassName])])
    else
      Writein(['capPoly obj=nil']);
  end;
end;

procedure TogsCaptureDrawerSkia.DrawLine(X, Y, X1, Y1: Double; cutRequest: Boolean);
begin
  ConsiderLine(X, Y, X1, Y1);
end;

procedure TogsCaptureDrawerSkia.DrawPolyline(Points: TogsCollection; cutRequest: Boolean);
var
  I: Integer;
  O0, O1: TObject;
  X0, Y0, X1, Y1: Double;

  function GetPointXY(const AObj: TObject; out AX, AY: Double): Boolean;
  begin
    Result := False;
    if AObj = nil then
      Exit;
    if AObj is TlDot then
    begin
      AX := TlDot(AObj).XDot;
      AY := TlDot(AObj).YDot;
      Exit(True);
    end;
    if AObj is TogsDot then
    begin
      AX := TogsDot(AObj).fX;
      AY := TogsDot(AObj).fY;
      Exit(True);
    end;
  end;
begin
  if (Points = nil) or (Points.Count < 2) then
    Exit;
  for I := 0 to Points.Count - 2 do
  begin
    O0 := TObject(Points.Items[I]);
    O1 := TObject(Points.Items[I + 1]);
    if GetPointXY(O0, X0, Y0) and GetPointXY(O1, X1, Y1) then
      ConsiderLine(X0, Y0, X1, Y1);
  end;
end;

procedure TogsCaptureDrawerSkia.DrawPolygon(Points: TogsCollection; polyRect: TogsRect);
begin
  ConsiderPolygon(Points);
end;

procedure TogsCaptureDrawerSkia.DrawBitmapAlignedPix(const AnchorPix: TPointF; const Bitmap: TBitmap;
  const Dst: TRectF; const AngleRad: Single);
var
  AnchorC: TPointF;
  C, S: Single;
  P0, P1, P2, P3: TPointF;
  AnchorPixLocal: TPointF;
begin
  if (FCapture = nil) or (ogsSelector = nil) then
    Exit;
  if not (ckLine in FCapture^.CaptureFor) then
    Exit;

  AnchorPixLocal := AnchorPix;
  if not UseWorldCoords then
    AnchorPixLocal := PointF(
      ogsSelector.XPix(AnchorPixLocal.X),
      ogsSelector.YPix(AnchorPixLocal.Y)
    );
  AnchorC := AnchorPixLocal;

  P0 := PointF(Dst.Left, Dst.Top);
  P1 := PointF(Dst.Right, Dst.Top);
  P2 := PointF(Dst.Right, Dst.Bottom);
  P3 := PointF(Dst.Left, Dst.Bottom);

  if Abs(AngleRad) > 1e-6 then
  begin
    C := Cos(AngleRad);
    S := Sin(AngleRad);
    P0 := PointF(P0.X * C - P0.Y * S, P0.X * S + P0.Y * C);
    P1 := PointF(P1.X * C - P1.Y * S, P1.X * S + P1.Y * C);
    P2 := PointF(P2.X * C - P2.Y * S, P2.X * S + P2.Y * C);
    P3 := PointF(P3.X * C - P3.Y * S, P3.X * S + P3.Y * C);
  end;
  P0 := PointF(P0.X + AnchorC.X, P0.Y + AnchorC.Y);
  P1 := PointF(P1.X + AnchorC.X, P1.Y + AnchorC.Y);
  P2 := PointF(P2.X + AnchorC.X, P2.Y + AnchorC.Y);
  P3 := PointF(P3.X + AnchorC.X, P3.Y + AnchorC.Y);

  if UseWorldCoords then
  begin
    ConsiderLine(P0.X, P0.Y, P1.X, P1.Y);
    ConsiderLine(P1.X, P1.Y, P2.X, P2.Y);
    ConsiderLine(P2.X, P2.Y, P3.X, P3.Y);
    ConsiderLine(P3.X, P3.Y, P0.X, P0.Y);
  end
  else
  begin
    ConsiderLinePix(P0.X, P0.Y, P1.X, P1.Y);
    ConsiderLinePix(P1.X, P1.Y, P2.X, P2.Y);
    ConsiderLinePix(P2.X, P2.Y, P3.X, P3.Y);
    ConsiderLinePix(P3.X, P3.Y, P0.X, P0.Y);
  end;
end;

procedure TogsCaptureDrawerSkia.DrawTextAlignedPix(const AnchorPix: TPointF; const Text: string;
  const Color: TAlphaColor; const FontSizePix: Single; const AngleRad: Single;
  const XP, YP: Double; const XKoef: Double; const FontView: TFontViewEx; const AAntiAlias: Boolean);
var
  Paint: ISkPaint;
  Typeface: ISkTypeface;
  Font: ISkFont;
  ProbeFont: ISkFont;
  FontStyle: TSkFontStyle;
  Weight: TSkFontWeight;
  Slant: TSkFontSlant;
  Metrics: TSkFontMetrics;
  ProbeMetrics: TSkFontMetrics;
  Bounds: TRectF;
  DrawX, DrawY: Single;
  LocalFontName: string;
  EffectiveFontSize: Single;
  Oversample: Single;
  ProbeSize: Single;
  AscentRatio: Single;
  TightAscentAbs: Single;
  AscentAlign: Single;
  ScaleCorr: Single;
  AnchorC: TPointF;
  AnchorPixLocal: TPointF;
  C, S: Single;
  R: TRectF;
  SX, SY: Single;
  P0, P1, P2, P3: TPointF;
begin
  if (FCapture = nil) or (ogsSelector = nil) then
    Exit;
  if not (ckLine in FCapture^.CaptureFor) then
    Exit;
  if Text = '' then
    Exit;

    AnchorPixLocal := AnchorPix;
    if not UseWorldCoords then
      AnchorPixLocal := PointF(
        ogsSelector.XPix(AnchorPixLocal.X),
        ogsSelector.YPix(AnchorPixLocal.Y)
      );
    AnchorC := AnchorPixLocal;

    Paint := TSkPaint.Create;
    Paint.AntiAlias := AAntiAlias;

    if FontView <> nil then
      LocalFontName := newFontScale.NormalizeSkiaFontFamilyName(string(FontView.FontName))
    else
      LocalFontName := '';

    Weight := TSkFontWeight.Normal;
    if (FontView <> nil) and (FontView.Bl <> 0) then
      Weight := TSkFontWeight.Bold;
    Slant := TSkFontSlant.Upright;
    if (FontView <> nil) and (FontView.It <> 0) then
      Slant := TSkFontSlant.Italic;
    FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

    if FontView <> nil then
      Typeface := newFontScale.ResolveSkiaTypefaceForView(FontView)
    else
      Typeface := newFontScale.ResolveSkiaTypeface(LocalFontName, False, False);

    Oversample := 1;
    if UseWorldCoords then
      Oversample := 10;

    ProbeSize := 100;
    ProbeFont := TSkFont.Create(Typeface, ProbeSize);
    ProbeFont.GetMetrics(ProbeMetrics);
    if (-ProbeMetrics.Ascent) > 0.01 then
      AscentRatio := (-ProbeMetrics.Ascent) / ProbeSize
    else
      AscentRatio := 1;

    EffectiveFontSize := (FontSizePix / AscentRatio) * Oversample;
    Font := TSkFont.Create(Typeface, EffectiveFontSize);
    Font.GetMetrics(Metrics);
    Font.MeasureText(Text, Bounds, Paint);

    // Text.Height semantics: FontSizePix is the desired ASCENT (Top->Baseline).
    // Normalize using tight ascent (-Bounds.Top) so visible glyphs reach the ascent box.
    TightAscentAbs := -Bounds.Top;
    if TightAscentAbs > 0.01 then
    begin
      ScaleCorr := (FontSizePix * Oversample) / TightAscentAbs;
      if Abs(ScaleCorr - 1) > 1e-4 then
      begin
        EffectiveFontSize := EffectiveFontSize * ScaleCorr;
        Font := TSkFont.Create(Typeface, EffectiveFontSize);
        Font.GetMetrics(Metrics);
        Font.MeasureText(Text, Bounds, Paint);
      end;
    end;

    DrawX := - (Bounds.Left + Single(XP) * Bounds.Width);
    AscentAlign := FontSizePix * Oversample;
    if YP < 0 then
      DrawY := 0
    else
      DrawY := AscentAlign * (1 - Single(YP));

    // Bounding box for the "ascent only" area: baseline is the bottom edge of the box.
    R := TRectF.Create(DrawX + Bounds.Left, DrawY - AscentAlign, DrawX + Bounds.Right, DrawY);

    SX := Single(XKoef);
    if Abs(SX) < 1e-6 then
      SX := 1;
    SY := 1;
    if Abs(Oversample) < 1e-6 then
      Oversample := 1;
    R.Left := R.Left * (SX / Oversample);
    R.Right := R.Right * (SX / Oversample);
    R.Top := R.Top * (SY / Oversample);
    R.Bottom := R.Bottom * (SY / Oversample);

    P0 := PointF(R.Left, R.Top);
    P1 := PointF(R.Right, R.Top);
    P2 := PointF(R.Right, R.Bottom);
    P3 := PointF(R.Left, R.Bottom);
    if Abs(AngleRad) > 1e-6 then
    begin
      C := Cos(AngleRad);
      S := Sin(AngleRad);
      P0 := PointF(P0.X * C - P0.Y * S, P0.X * S + P0.Y * C);
      P1 := PointF(P1.X * C - P1.Y * S, P1.X * S + P1.Y * C);
      P2 := PointF(P2.X * C - P2.Y * S, P2.X * S + P2.Y * C);
      P3 := PointF(P3.X * C - P3.Y * S, P3.X * S + P3.Y * C);
    end;
    P0 := PointF(P0.X + AnchorC.X, P0.Y + AnchorC.Y);
    P1 := PointF(P1.X + AnchorC.X, P1.Y + AnchorC.Y);
    P2 := PointF(P2.X + AnchorC.X, P2.Y + AnchorC.Y);
    P3 := PointF(P3.X + AnchorC.X, P3.Y + AnchorC.Y);

  //  Writein(['Text=', Text, UseWorldCoords,P0.X, P0.Y, P1.X, P1.Y ]);

    if UseWorldCoords then
    begin
      ConsiderLine(P0.X, P0.Y, P1.X, P1.Y);
      ConsiderLine(P1.X, P1.Y, P2.X, P2.Y);
      ConsiderLine(P2.X, P2.Y, P3.X, P3.Y);
      ConsiderLine(P3.X, P3.Y, P0.X, P0.Y);
    end
    else
    begin
      ConsiderLinePix(P0.X, P0.Y, P1.X, P1.Y);
      ConsiderLinePix(P1.X, P1.Y, P2.X, P2.Y);
      ConsiderLinePix(P2.X, P2.Y, P3.X, P3.Y);
      ConsiderLinePix(P3.X, P3.Y, P0.X, P0.Y);
    end;
end;

initialization
 // SkiaFontFiles := nil;
finalization
end.
