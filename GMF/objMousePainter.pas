unit objMousePainter;

interface

uses
  System.Types,
  System.Classes,
  System.UITypes,
  FMX.Types,
  FMX.Graphics,
  ogcBasic,
  ogcDrawerCanvas,
  newSelector,
  WPTForm2;

type
  TGetCanvasScaleFunc = reference to function: Single;
  TFastRepaintProc = reference to procedure;
  TFullRepaintProc = reference to procedure;
  TUpdateStatusGeoProc = reference to procedure(const X, Y: Single);

  TMousePainter = class
  private
    FDrawer: TogsDrawerCanvas;
    FSelector: TSelector;
    FGetCanvasScale: TGetCanvasScaleFunc;
    FFastRepaint: TFastRepaintProc;
    FFullRepaint: TFullRepaintProc;
    FUpdateStatusGeo: TUpdateStatusGeoProc;

    FCurrentCanvasScale: Single;

    FObjectRepaintAccess: Boolean;
    FSceneDirty: Boolean;
    FBaseDx: Double;
    FBaseDy: Double;
    FBaseScale: Double;

    FPanBitmap: TBitmap;
    FPanBitmapActive: Boolean;
    FPanStartPoint: TPointF;
    FPanShift: TPointF;

    FZoomBitmapActive: Boolean;
    FZoomStartDistance: Single;
    FZoomFactor: Single;
    FZoomPivot: TPointF;
    FZoomBaseRect: TogsRect;
    FZoomBaseScale: Double;

    procedure DrawPanPreviewToDrawer;
    procedure DrawZoomPreviewToDrawer;
    function GetTwgForm: TForm2;
  protected
    function CanvasScale: Single;
    procedure FastRepaint;
    procedure FullRepaint;

    property Drawer: TogsDrawerCanvas read FDrawer;
    property Selector: TSelector read FSelector;
    property UpdateStatusGeo: TUpdateStatusGeoProc read FUpdateStatusGeo;
  public
    constructor Create; virtual;
    destructor Destroy; override;
   //
    property TwgForm: TForm2 read GetTwgForm;

    property objectRepaintAccess: Boolean read FObjectRepaintAccess write FObjectRepaintAccess;
    property SceneDirty: Boolean read FSceneDirty write FSceneDirty;
    property BaseDx: Double read FBaseDx write FBaseDx;
    property BaseDy: Double read FBaseDy write FBaseDy;
    property BaseScale: Double read FBaseScale write FBaseScale;

    procedure Attach(ADrawer: TogsDrawerCanvas; ASelector: TSelector;
      AGetCanvasScale: TGetCanvasScaleFunc; AFastRepaint: TFastRepaintProc;
      AFullRepaint: TFullRepaintProc; AUpdateStatusGeo: TUpdateStatusGeoProc);

    procedure BeginPanPreview(const X, Y: Single);
    procedure UpdatePanPreview(const X, Y: Single);
    procedure EndPanPreview;

    procedure BeginZoomPreview(const Pivot: TPointF; const StartDistance: Single);
    procedure UpdateZoomPreview(const Distance: Single);
    procedure EndZoomPreview;

    procedure PainterPaint(const Canvas: TCanvas; const LocalRect: TRectF);
    procedure RenderSceneToBackbuffer(const Canvas: TCanvas);

    property PanPreviewBitmap: TBitmap read FPanBitmap;
    property PanPreviewActive: Boolean read FPanBitmapActive;
    property PanPreviewShift: TPointF read FPanShift;
    property ZoomPreviewActive: Boolean read FZoomBitmapActive;
    property ZoomPreviewPivot: TPointF read FZoomPivot;
    property ZoomPreviewFactor: Single read FZoomFactor;

    property ZoomStartDistance: Single read FZoomStartDistance;
    property ZoomFactor: Single read FZoomFactor;
    property ZoomPivot: TPointF read FZoomPivot;
    property ZoomBaseRect: TogsRect read FZoomBaseRect;
    property ZoomBaseScale: Double read FZoomBaseScale write FZoomBaseScale;
  end;

implementation

uses
  Collect, Writer, EcText, EcDot, EcDot2, EcLot, RPrims, WPTwigs, System.SysUtils;

constructor TMousePainter.Create;
begin
  inherited Create;
  FCurrentCanvasScale := 1;
  FObjectRepaintAccess := False;
  FSceneDirty := False;
  FBaseDx := 0;
  FBaseDy := 0;
  FBaseScale := 0;
  FPanBitmap := nil;
  FPanBitmapActive := False;
  FPanShift := PointF(0, 0);

  FZoomBaseRect := nil;
  FZoomBitmapActive := False;
  FZoomStartDistance := 0;
  FZoomFactor := 1;
  FZoomBaseScale := 0;
end;

destructor TMousePainter.Destroy;
begin
  FPanBitmap.Free;
  FPanBitmap := nil;
  FZoomBaseRect.Free;
  FZoomBaseRect := nil;
  inherited;
end;

procedure TMousePainter.Attach(ADrawer: TogsDrawerCanvas; ASelector: TSelector;
  AGetCanvasScale: TGetCanvasScaleFunc; AFastRepaint: TFastRepaintProc;
  AFullRepaint: TFullRepaintProc; AUpdateStatusGeo: TUpdateStatusGeoProc);
begin
  FDrawer := ADrawer;
  FSelector := ASelector;
  FGetCanvasScale := AGetCanvasScale;
  FFastRepaint := AFastRepaint;
  FFullRepaint := AFullRepaint;
  FUpdateStatusGeo := AUpdateStatusGeo;
end;

function TMousePainter.CanvasScale: Single;
begin
  if Assigned(FGetCanvasScale) then
    Result := FGetCanvasScale()
  else
    Result := FCurrentCanvasScale;
  if Result <= 0 then Result := 1;
end;

procedure TMousePainter.FastRepaint;
begin
  if Assigned(FFastRepaint) then
    FFastRepaint();
end;

procedure TMousePainter.FullRepaint;
begin
  FSceneDirty := True;
  if Assigned(FFullRepaint) then
    FFullRepaint();
end;

function TMousePainter.GetTwgForm: TForm2;
begin
 Result := TForm2(Selector.GTwgForm);
end;

procedure TMousePainter.DrawPanPreviewToDrawer;
var
  SrcRect, DstRect: TRectF;
  St: TCanvasSaveState;
  ShiftPix: TPointF;
begin
  Exit;
end;

procedure TMousePainter.DrawZoomPreviewToDrawer;
var
  SrcRect, DstRect: TRectF;
  St: TCanvasSaveState;
  PivotPix: TPointF;
  F: Single;
begin
  Exit;
end;

procedure TMousePainter.BeginPanPreview(const X, Y: Single);
begin
  FPanBitmapActive := False;
  FPanShift := PointF(0, 0);

  if (FDrawer <> nil) and (FDrawer.Bitmap <> nil) and (FDrawer.Bitmap.Width > 0) and (FDrawer.Bitmap.Height > 0) then
  begin
    if FPanBitmap = nil then
      FPanBitmap := TBitmap.Create;
    FPanBitmap.Assign(FDrawer.Bitmap);

    FPanStartPoint := PointF(X, Y);
    FPanShift := PointF(0, 0);
    FPanBitmapActive := True;
  end;
end;

procedure TMousePainter.UpdatePanPreview(const X, Y: Single);
begin
  if not FPanBitmapActive then
    Exit;

  FPanShift := PointF(X - FPanStartPoint.X, Y - FPanStartPoint.Y);
  FastRepaint;
end;

procedure TMousePainter.EndPanPreview;
begin
  FPanBitmapActive := False;
  FPanShift := PointF(0, 0);
end;

procedure TMousePainter.BeginZoomPreview(const Pivot: TPointF; const StartDistance: Single);
begin
  FZoomBitmapActive := False;
  FZoomStartDistance := StartDistance;
  FZoomFactor := 1;
  FZoomPivot := Pivot;

  if (FDrawer <> nil) and (FDrawer.Bitmap <> nil) and (FDrawer.Bitmap.Width > 0) and (FDrawer.Bitmap.Height > 0) then
  begin
    if FPanBitmap = nil then
      FPanBitmap := TBitmap.Create;
    FPanBitmap.Assign(FDrawer.Bitmap);
    FZoomBitmapActive := True;
  end;

  if FZoomBaseRect = nil then
    FZoomBaseRect := TogsRect.Create;
  if FSelector <> nil then
    FZoomBaseRect.Assign(FSelector.ActiveRect);

  if FSelector <> nil then
    FZoomBaseScale := FSelector.GetScale;
end;

procedure TMousePainter.UpdateZoomPreview(const Distance: Single);
begin
  if not FZoomBitmapActive then
    Exit;
  if FZoomStartDistance <= 0 then
    Exit;

  FZoomFactor := Distance / FZoomStartDistance;
  if FZoomFactor < 0.05 then
    FZoomFactor := 0.05;
  if FZoomFactor > 20 then
    FZoomFactor := 20;
  FastRepaint;
end;

procedure TMousePainter.EndZoomPreview;
begin
  FZoomBitmapActive := False;
  FZoomStartDistance := 0;
  FZoomFactor := 1;
end;

procedure TMousePainter.RenderSceneToBackbuffer(const Canvas: TCanvas);
var
 I,J,N,CL,TWC,Counter:LongInt;Tw:TTwig;Lot:TLot;
 PP:Pointer;F:TEFont;PPoint:TPointDot;BMP:TBmpSet;
 B:Byte;
 Kl:SmallInt;
 W:Word;
 R:TRect;
{}
 TwgDc:hDc;
 UpLot:Boolean;
 LCo:Integer;
 Error:Integer;
 X1,X2,X3,X4:Double;
 NeedW, NeedH: Integer;
begin
 Error := 1;
 if FDrawer = nil then Exit;
 if TwgForm = nil then Exit;
 if not FObjectRepaintAccess then Exit;

 NeedW := FDrawer.Bitmap.Width;
 NeedH := FDrawer.Bitmap.Height;
 if (NeedW <= 0) or (NeedH <= 0) then Exit;

 FDrawer.BeginPaint;
 FDrawer.Clear(TAlphaColors.White);
  With FSelector, GGraphset do try
   Error := 6;
   Error := 7;
   TWC := 0;
   begin
    WriteIn(['paint = ', FormatDateTime('hh:nn:ss', Now)]);
    If FillLot = 1 then begin
     For I := 0 to TwgForm.Twigs.IndexCount - 1 do begin
      Lot := TwgForm.Twigs.LAtIndex(I);
      try
       If (Lot.TypeLot <> 254) and (Lot.Closed = 1) then Lot.Draw32(TwgForm.Twigs);
      except
       exit;
      end;
     end;
    end;
   end;
   WriteIn(['endpaint = ', FormatDateTime('hh:nn:ss', Now)]);
   For I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
    PP := TwgForm.Twigs.AAt(I, B);
    if (B = TWG_Point) then begin
     PPoint := PP;
     If PPoint.Closed then continue;
     try
      PPoint.Draw32(FDrawer, TwgForm.MkLib.PSLib,TwgForm.FontColEx);
     except
     end;
    end;
   end;
   WriteIn(['endpointspaint = ', FormatDateTime('hh:nn:ss', Now)]);
   Error := 16;
  finally
   FDrawer.EndPaint;
   For I := 0 to TwgForm.Twigs.TwigsCount - 1 do begin
    Tw := TwgForm.Twigs.TAt(I);
    Tw.isDraw := False;
   end;
  end;
  FSceneDirty := False;
  FBaseDx := FSelector.GetDx;
  FBaseDy := FSelector.GetDy;
  FBaseScale := FSelector.GetScale;
 end;

procedure TMousePainter.PainterPaint(const Canvas: TCanvas; const LocalRect: TRectF);
var
 SrcRect, DstRect: TRectF;
 St: TCanvasSaveState;
 Pivot: TPointF;
 F: Single;
 NeedW, NeedH: Integer;
begin
 if FDrawer = nil then Exit;
 if Canvas = nil then Exit;

 FCurrentCanvasScale := Canvas.Scale;

 if (TwgForm <> nil) and (not FObjectRepaintAccess) then
 begin
  FObjectRepaintAccess := True;
  FSceneDirty := True;
 end;

 if FPanBitmapActive and (FPanBitmap <> nil) then
 begin
  St := Canvas.SaveState;
  try
   Canvas.IntersectClipRect(LocalRect);
   SrcRect := RectF(0, 0, FPanBitmap.Width, FPanBitmap.Height);
   DstRect := RectF(LocalRect.Left + FPanShift.X, LocalRect.Top + FPanShift.Y,
                    LocalRect.Right + FPanShift.X, LocalRect.Bottom + FPanShift.Y);
   Canvas.DrawBitmap(FPanBitmap, SrcRect, DstRect, 1, True);
  finally
   Canvas.RestoreState(St);
  end;
  Exit;
 end;

 if FZoomBitmapActive and (FPanBitmap <> nil) then
 begin
  Pivot := FZoomPivot;
  F := FZoomFactor;
  St := Canvas.SaveState;
  try
   Canvas.IntersectClipRect(LocalRect);
   SrcRect := RectF(0, 0, FPanBitmap.Width, FPanBitmap.Height);
   DstRect := RectF(Pivot.X + (LocalRect.Left - Pivot.X) * F,
                    Pivot.Y + (LocalRect.Top - Pivot.Y) * F,
                    Pivot.X + (LocalRect.Right - Pivot.X) * F,
                    Pivot.Y + (LocalRect.Bottom - Pivot.Y) * F);
   Canvas.DrawBitmap(FPanBitmap, SrcRect, DstRect, 1, True);
  finally
   Canvas.RestoreState(St);
  end;
  Exit;
 end;

 if FSceneDirty and (TwgForm <> nil) and FObjectRepaintAccess then
 begin
  NeedW := Round(LocalRect.Width * Canvas.Scale);
  NeedH := Round(LocalRect.Height * Canvas.Scale);
  if (NeedW > 0) and (NeedH > 0) then
  begin
   if (FDrawer.Width <> NeedW) or (FDrawer.Height <> NeedH) then
   begin
    FDrawer.Width := NeedW;
    FDrawer.Height := NeedH;
   end;
  end;
  RenderSceneToBackbuffer(Canvas);
 end;

 FDrawer.DrawTo(Canvas, LocalRect.Round);
end;


end.
