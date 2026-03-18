unit ogcDrawerSkia;

interface

uses
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
  ogcBasic,
  ogcMathUtils;

procedure RegisterSkiaFontFile(const FamilyName, FileName: string);
function GetRegisteredSkiaFontFile(const FamilyName: string): string;

type
  TogsSkiaObject = class
  private
    FPicture: ISkPicture;
    FId: Int64;
    FUserObject: TObject;
    FBoundsWorld: TRectF;
  public
    procedure Draw(const ACanvas: ISkCanvas);
    property Picture: ISkPicture read FPicture write FPicture;
    property Id: Int64 read FId write FId;
    property UserObject: TObject read FUserObject write FUserObject;
    property BoundsWorld: TRectF read FBoundsWorld write FBoundsWorld;
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
    FSkCanvas: ISkCanvas;
    FDest: TRectF;
    FUseWorldCoords: Boolean;
    FSkiaList: TogsSkiaList;
    FPrimitiveRecorder: ISkPictureRecorder;
    FPrimitiveCanvas: ISkCanvas;
    FPrimitiveOldCanvas: ISkCanvas;
    FPrimitiveId: Int64;
    FPrimitiveUserObject: TObject;
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
    constructor Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent); override;
    destructor Destroy; override;

    procedure BeginFrame(const ACanvas: ISkCanvas; const ADest: TRectF);
    procedure EndFrame;

    procedure Clear(AColor: Integer); override;

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
      const XKoef: Double = 1; const FontName: string = '';
      const Bold: Boolean = False; const Italic: Boolean = False);

    procedure DrawBitmapAlignedPix(const AnchorPix: TPointF;
      const Bitmap: TBitmap; const Dst: TRectF; const AngleRad: Single);

    procedure DrawTo(Image_: TCanvas; Rect: TRect); override;

    procedure ClearSkiaList;
    procedure DrawSkiaList(const ACanvas: ISkCanvas);

    procedure BeginPrimitive(const AId: Int64; const AUserObject: TObject = nil);
    procedure EndPrimitive;

    property Bitmap: TBitmap read FBitmap;
    property UseWorldCoords: Boolean read FUseWorldCoords write FUseWorldCoords;
    property SkiaList: TogsSkiaList read FSkiaList;
  end;

implementation uses Writer, newProcs;

var
  SkiaFontFiles: TStringList;

procedure RegisterSkiaFontFile(const FamilyName, FileName: string);
var
  Idx: Integer;
begin
  if (FamilyName = '') or (FileName = '') then
    Exit;
  if SkiaFontFiles = nil then
  begin
    SkiaFontFiles := TStringList.Create;
    SkiaFontFiles.CaseSensitive := False;
    SkiaFontFiles.Duplicates := dupIgnore;
    SkiaFontFiles.Sorted := True;
  end;
  Idx := SkiaFontFiles.IndexOfName(FamilyName);
  if Idx < 0 then
    SkiaFontFiles.Add(FamilyName + '=' + FileName)
  else
  begin
    SkiaFontFiles.Delete(Idx);
    SkiaFontFiles.Add(FamilyName + '=' + FileName);
  end;
end;

function GetRegisteredSkiaFontFile(const FamilyName: string): string;
var
  Idx: Integer;
begin
  Result := '';
  if (SkiaFontFiles = nil) or (FamilyName = '') then
    Exit;
  Idx := SkiaFontFiles.IndexOfName(FamilyName);
  if Idx >= 0 then
    Result := SkiaFontFiles.ValueFromIndex[Idx];
end;

function EnsureOpaqueAlpha(const C: TAlphaColor): TAlphaColor;
begin
  if (C shr 24) = 0 then
    Result := C or $FF000000
  else
    Result := C;
end;

{ TogsDrawerSkia }

constructor TogsDrawerSkia.Create(ogsSelector_: TogsSelector; OnPaint_: TNotifyEvent);
begin
  inherited Create(ogsSelector_, OnPaint_);
  FWidth := 1;
  FHeight := 1;
  FBitmap := TBitmap.Create;
  FBitmap.SetSize(FWidth, FHeight);
  FInScene := False;
  FUseWorldCoords := False;
  FSkiaList := TogsSkiaList.Create(True);
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

procedure TogsDrawerSkia.BeginPrimitive(const AId: Int64; const AUserObject: TObject);
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
begin
  if FPrimitiveRecorder = nil then
    Exit;
  try
    Obj := TogsSkiaObject.Create;
    Obj.Id := FPrimitiveId;
    Obj.UserObject := FPrimitiveUserObject;
    Obj.BoundsWorld := FPrimitiveBoundsWorld;
    Obj.Picture := FPrimitiveRecorder.FinishRecording;
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

procedure TogsDrawerSkia.Clear(AColor: Integer);
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
begin
  if Disable then
    Exit;
  if ogsSelector = nil then
    Exit;

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
    Paint.AntiAlias := True;
    Paint.Style := TSkPaintStyle.Stroke;
    Paint.Color := EnsureOpaqueAlpha(Pen.penColor);
    if Pen.penWidth > 0 then
    begin
      if FUseWorldCoords and (ogsSelector.GetScale > 0) then
        Paint.StrokeWidth := Max(0.05, Pen.penWidth/10)
      else
        Paint.StrokeWidth := Max(1.0, Pen.penWidth);
    end
    else
      Paint.StrokeWidth := 1;
    FSkCanvas.DrawLine(P0.X, P0.Y, P1.X, P1.Y, Paint);
  end
  else if Canvas <> nil then
  begin
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
      if not ogsSelector.RectVisible(R) then
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
    if FUseWorldCoords and (ogsSelector.GetScale > 0) then
      Paint.StrokeWidth := Max(0.05, Pen.penWidth/10)
    else
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
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  Img: ISkImage;
  Paint: ISkPaint;
begin
  if (FSkCanvas = nil) or (Bitmap = nil) then
    Exit;
  if (Bitmap.Width <= 0) or (Bitmap.Height <= 0) then
    Exit;

  if not Bitmap.Map(TMapAccess.Read, D) then
    Exit;
  try
    ImgInfo := TSkImageInfo.Create(Bitmap.Width, Bitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
    Surface := TSkSurface.MakeRasterDirect(ImgInfo, D.Data, D.Pitch);
    if Surface = nil then
      Exit;
    Img := Surface.MakeImageSnapshot;
  finally
    Bitmap.Unmap(D);
  end;

  if Img = nil then
    Exit;

  Paint := TSkPaint.Create;
  Paint.AntiAlias := True;

  FSkCanvas.Save;
  try
    FSkCanvas.Translate(AnchorPix.X, AnchorPix.Y);
    if Abs(AngleRad) > 1e-6 then
      FSkCanvas.Rotate(AngleRad * 180 / Pi);
    FSkCanvas.DrawImageRect(Img, Dst, Paint);
  finally
    FSkCanvas.Restore;
  end;
end;

procedure TogsDrawerSkia.DrawTextAlignedPix(const AnchorPix: TPointF; const Text: string;
  const Color: TAlphaColor; const FontSizePix: Single; const AngleRad: Single;
  const XP, YP: Double; const XKoef: Double; const FontName: string;
  const Bold: Boolean; const Italic: Boolean);
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
  CutPos: Integer;
  FontFile: string;
  EffectiveFontSize: Single;
  Oversample: Single;
  ProbeSize: Single;
  AscentRatio: Single;
begin
  if (FSkCanvas = nil) or (Text = '') then
    Exit;

  Paint := TSkPaint.Create;
  Paint.AntiAlias := True;
  Paint.Color := EnsureOpaqueAlpha(Color);

  LocalFontName := Trim(FontName);
  if (LocalFontName <> '') and (LocalFontName[1] = '@') then
    LocalFontName := Trim(Copy(LocalFontName, 2, MaxInt));
  CutPos := Pos(',', LocalFontName);
  if CutPos > 0 then
    LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));
  CutPos := Pos('(', LocalFontName);

  if CutPos > 0 then
    LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));

  Weight := TSkFontWeight.Normal;
  if Bold then
    Weight := TSkFontWeight.Bold;
  Slant := TSkFontSlant.Upright;
  if Italic then
    Slant := TSkFontSlant.Italic;
  FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

  Typeface := nil;
  FontFile := '';
  if LocalFontName <> '' then
    FontFile := GetRegisteredSkiaFontFile(LocalFontName);
  if FontFile <> '' then
    Typeface := TSkTypeface.MakeFromFile(FontFile);
  if (Typeface = nil) and (LocalFontName <> '') then
    Typeface := TSkTypeface.MakeFromName(LocalFontName, FontStyle);

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

  DrawX := - (Bounds.Left + Single(XP) * Bounds.Width);
  if YP < 0 then
    DrawY := 0
  else
    DrawY := - (Metrics.Ascent + (-Metrics.Ascent) * Single(YP));

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
  finally
    FSkCanvas.Restore;
  end;
end;

procedure TogsDrawerSkia.DrawTo(Image_: TCanvas; Rect: TRect);
begin
  // Not used in Skia paintbox path
end;

initialization
  SkiaFontFiles := nil;

finalization
  SkiaFontFiles.Free;
  SkiaFontFiles := nil;

end.
