unit MainFrmMouseObj;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmSkia, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.Skia, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, objMouse;

type
  TMainFormMouseObj = class(TMainFormSkia)
    btnDS: TButton;
    btnDraw: TButton;
    procedure btnDSClick(Sender: TObject);
    procedure btnDrawClick(Sender: TObject);
  private
   FMouseObject: TKeyMouseHook;
   FOverlayPainter: TSkPaintBox;
   FOverlayInteractionImage: ISkImage;
   FOverlayInteractionValid: Boolean;
   FOverlayPendingRedraw: Boolean;
   FInteractionPrevActive: Boolean;
   FInteractionWatchTimer: TTimer;
   procedure CaptureOverlayInteractionImage;
   procedure SetMouseObject(const Value: TKeyMouseHook);
   procedure EnsureOverlayPainter;
   procedure OverlayDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
   procedure DrawOverlay(const ACanvas: ISkCanvas; const ADest: TRectF);
   procedure InteractionWatchTimer(Sender: TObject);
  protected
   destructor Destroy; override;
   procedure Loaded; override;
   procedure SetSelectorParams; override;
  //
   procedure SkPainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
   procedure PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF); override;
   procedure DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF); override;
  public
   procedure RequestOverlayRedraw;
   property OverlayPainter: TSkPaintBox read FOverlayPainter;
   property MouseObject: TKeyMouseHook read FMouseObject write SetMouseObject;
  end;

var
  MainFormMouseObj: TMainFormMouseObj;

implementation uses objMouseSelect, objMouseDraw, UpdateMessages, Writer;

{$R *.fmx}

var
  OverlayStatLastTick: UInt64;
  OverlayStatCount: Integer;
  OverlayStatMaxDt: UInt64;
  OverlayDrawLastTick: UInt64;
  OverlayDrawCount: Integer;

{ TMainFormMouseObj }

procedure TMainFormMouseObj.Loaded;
begin
  inherited;
  EnsureOverlayPainter;
  if Selector <> nil then
    Selector.ovrPainter := FOverlayPainter;

  if FInteractionWatchTimer = nil then
  begin
    FInteractionPrevActive := InteractionBitmapActive;
    FOverlayPendingRedraw := False;
    FInteractionWatchTimer := TTimer.Create(Self);
    FInteractionWatchTimer.Interval := 30;
    FInteractionWatchTimer.Enabled := True;
    FInteractionWatchTimer.OnTimer := InteractionWatchTimer;
  end;
end;

procedure TMainFormMouseObj.EnsureOverlayPainter;
begin
  if (SkPainter = nil) or (FOverlayPainter <> nil) then
    Exit;
  FOverlayPainter := TSkPaintBox.Create(Self);
  FOverlayPainter.Name := 'OverlayPainter';
  FOverlayPainter.Parent := SkPainter.Parent;
  FOverlayPainter.Align := SkPainter.Align;
  FOverlayPainter.Position.Point := SkPainter.Position.Point;
  FOverlayPainter.Size.Size := SkPainter.Size.Size;
  FOverlayPainter.Margins := SkPainter.Margins;
  FOverlayPainter.Opacity := 1;
  FOverlayPainter.HitTest := False;
  FOverlayPainter.Stored := False;
  FOverlayPainter.OnDraw := OverlayDraw;
  FOverlayPainter.BringToFront;
end;

procedure TMainFormMouseObj.InteractionWatchTimer(Sender: TObject);
var
  CurActive: Boolean;
begin
  CurActive := InteractionBitmapActive;

  if FInteractionPrevActive and (not CurActive) then
  begin
    if FOverlayPendingRedraw then
      RequestOverlayRedraw;
  end;

  FInteractionPrevActive := CurActive;
end;

procedure TMainFormMouseObj.RequestOverlayRedraw;
begin
  if FOverlayPainter = nil then
    Exit;
  FOverlayInteractionValid := False;

  if InteractionBitmapActive then
  begin
    FOverlayPendingRedraw := True;
    Exit;
  end;

  FOverlayPendingRedraw := False;
  FOverlayPainter.Redraw;
end;

procedure TMainFormMouseObj.CaptureOverlayInteractionImage;
var
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  C: ISkCanvas;
  ViewScale: Single;
  Tx, Ty: Single;
  W, H: Integer;
begin
  if (SkPainter = nil) or (Selector = nil) or (MouseObject = nil) then
  begin
    FOverlayInteractionImage := nil;
    FOverlayInteractionValid := True;
    Exit;
  end;

  W := Round(SkPainter.Width * LastCanvasScale);
  H := Round(SkPainter.Height * LastCanvasScale);
  if W < 1 then W := 1;
  if H < 1 then H := 1;

  ImgInfo := TSkImageInfo.Create(W, H, TSkColorType.BGRA8888, TSkAlphaType.Premul);
  Surface := TSkSurface.MakeRaster(ImgInfo);
  if Surface = nil then
    Exit;
  C := Surface.Canvas;
  if C = nil then
    Exit;

  C.Clear(TAlphaColors.Null);

  ViewScale := Single(Selector.GetScale);
  if ViewScale <= 0 then
    Exit;

  Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
  Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
  C.Save;
  try
    C.Translate(Tx, Ty);
    C.Scale(ViewScale, ViewScale);
    MouseObject.DrawTemp(C, False);
  finally
    C.Restore;
  end;

  Surface.Flush;
  FOverlayInteractionImage := Surface.MakeImageSnapshot;
  FOverlayInteractionValid := True;
end;

procedure TMainFormMouseObj.DrawOverlay(const ACanvas: ISkCanvas; const ADest: TRectF);
var
  ViewScale: Single;
  Tx, Ty: Single;
begin
  if (ACanvas = nil) or (Selector = nil) then
    Exit;
  ViewScale := Single(Selector.GetScale);
  if ViewScale <= 0 then
    Exit;
  Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
  Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
  ACanvas.Save;
  try
    ACanvas.Translate(Tx, Ty);
    ACanvas.Scale(ViewScale, ViewScale);
    PaintAfter(ACanvas, ADest);
  finally
    ACanvas.Restore;
  end;
end;

procedure TMainFormMouseObj.OverlayDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var NowT: UInt64;
begin
  if ACanvas = nil then
    Exit;
  if InteractionBitmapActive then
    Exit;
  ACanvas.Clear(TAlphaColors.Null);

  Inc(OverlayDrawCount);
  NowT := TThread.GetTickCount64;
  if (OverlayDrawLastTick = 0) then OverlayDrawLastTick := NowT;
  if (NowT - OverlayDrawLastTick) >= 1000 then
  begin
    WriteIn(['OverlayDraw fps=', OverlayDrawCount]);
    OverlayDrawLastTick := NowT;
    OverlayDrawCount := 0;
  end;

  DrawOverlay(ACanvas, ADest);
end;

procedure TMainFormMouseObj.DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF);
var
  Paint: ISkPaint;
begin
  if (ACanvas = nil) or (not InteractionBitmapActive) then
    Exit;

  if not FOverlayInteractionValid then
    CaptureOverlayInteractionImage;

  if FOverlayInteractionImage = nil then
    Exit;

  Paint := TSkPaint.Create;
  Paint.AntiAlias := True;
  ACanvas.DrawImageRect(FOverlayInteractionImage, ASceneDst, Paint);
end;

procedure TMainFormMouseObj.btnDrawClick(Sender: TObject);
begin
 If TwgForm = nil then exit;
 If btnDraw.isPressed then begin
  Selector.LOperation := 100111;
  MouseObject := TMousePainter.Create(TwgForm, nil);
  MouseObject.OnAddPrim := UpdateMessage.AddPrim;
  MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
  MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
  MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 end else
  MouseObject := nil;
end;

procedure TMainFormMouseObj.btnDSClick(Sender: TObject);
begin
 If TwgForm = nil then exit;
 If btnDS.isPressed then begin
  MouseObject := TMouseSelector.Create(TwgForm, nil);
 end else
  MouseObject := nil;
end;

procedure TMainFormMouseObj.SetMouseObject(const Value: TKeyMouseHook);
begin
 If MouseObject <> nil then MouseObject.Free;
 FMouseObject := Value;
end;

procedure TMainFormMouseObj.SetSelectorParams;
begin
 EnsureOverlayPainter;
 inherited;
 Selector.ovrPainter := FOverlayPainter;
 MouseObject := nil;
end;

destructor TMainFormMouseObj.Destroy;
begin
  if FInteractionWatchTimer <> nil then
  begin
    FInteractionWatchTimer.Enabled := False;
    FInteractionWatchTimer.Free;
    FInteractionWatchTimer := nil;
  end;
  if FMouseObject <> nil then begin
   FMouseObject.Free;
   FMouseObject := nil;
  end;
  if FOverlayPainter <> nil then begin
   FOverlayPainter.Free;
   FOverlayPainter := nil;
  end;
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseDown(TwgForm, Button, Shift, XGeo, YGeo, Hook);
  If not Hook then
   inherited;
 end else
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
MousePos := PointF(X, Y);
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseMove(TwgForm, Shift, XGeo, YGeo, Hook);
  if Hook then
  begin
     RequestOverlayRedraw;
  end;
  If not Hook then
   inherited;
 end else
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseUp(TwgForm, Button, Shift, X, Y, Hook);
  If not Hook then
   inherited;
 end else
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var T0, Dt: UInt64;
begin
 T0 := TThread.GetTickCount64;
 inherited;
 Dt := TThread.GetTickCount64 - T0;
// WriteIn(['MWheel ms=', Dt]);
end;

procedure TMainFormMouseObj.PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF);
var T0, Dt: UInt64;
    NowT: UInt64;
begin
  if MouseObject <> nil then
  begin
    T0 := TThread.GetTickCount64;
    MouseObject.DrawTemp(ACanvas, False);
    Dt := TThread.GetTickCount64 - T0;
    Inc(OverlayStatCount);
    if Dt > OverlayStatMaxDt then OverlayStatMaxDt := Dt;
    NowT := TThread.GetTickCount64;
    if (OverlayStatLastTick = 0) then OverlayStatLastTick := NowT;
    if (NowT - OverlayStatLastTick) >= 1000 then
    begin
      WriteIn(['Overlay fps=', OverlayStatCount, ' maxDt=', OverlayStatMaxDt]);
      OverlayStatLastTick := NowT;
      OverlayStatCount := 0;
      OverlayStatMaxDt := 0;
    end;
  end
end;

end.
