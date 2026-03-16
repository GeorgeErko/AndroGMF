unit objKeyMouse;

interface

uses
  System.Types, System.Classes,
  System.UITypes,
  FMX.Types, FMX.Forms,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  objMousePainter,
  ogcBasic,
  ogcDrawerCanvas,
  newSelector;

type
  TFreeProc = procedure of object;
  TKeyMouseHook = class;
  TKeyMouseHookClass = class of TKeyMouseHook;

  TKeyMouseHook = class(TMousePainter)
  private
    FFreeProc: TFreeProc;
    PanActive: Boolean;
    LastPanPoint: TPointF;
    ZoomActive: Boolean;
    InteractionActive: Boolean;

    BaseDx: Double;
    BaseDy: Double;
    BaseScale: Double;

    procedure ResetInteractionState;
    procedure FinalizeZoom;
    function GetDrawer: TogsDrawerCanvas;
  public
    constructor Create(Selector: TSelector; AFreeProc: TFreeProc); virtual;
    destructor Destroy; override;

    procedure Attach(ADrawer: TogsDrawerCanvas; ASelector: TSelector;
      AGetCanvasScale: TGetCanvasScaleFunc; AFastRepaint: TFastRepaintProc;
      AFullRepaint: TFullRepaintProc;
      AUpdateStatusGeo: TUpdateStatusGeoProc);

    procedure PainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseLeave(Sender: TObject);
    procedure PainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure PainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure PainterDblClick(Sender: TObject);

    procedure ViewAll;
    procedure Scale(const PivotLocal: TPointF; const Koef: Double);

    property CurrentDrawer: TogsDrawerCanvas read GetDrawer;
  end;

implementation

constructor TKeyMouseHook.Create(Selector: TSelector; AFreeProc: TFreeProc);
begin
  inherited Create;
  Attach(nil, Selector, nil, nil, nil, nil);
  FFreeProc := AFreeProc;
  PanActive := False;
  ZoomActive := False;
  InteractionActive := False;
  BaseDx := 0;
  BaseDy := 0;
  BaseScale := 0;
end;

destructor TKeyMouseHook.Destroy;
begin
  inherited;
end;

procedure TKeyMouseHook.Attach(ADrawer: TogsDrawerCanvas; ASelector: TSelector;
  AGetCanvasScale: TGetCanvasScaleFunc; AFastRepaint: TFastRepaintProc;
  AFullRepaint: TFullRepaintProc;
  AUpdateStatusGeo: TUpdateStatusGeoProc);
begin
  inherited Attach(ADrawer, ASelector, AGetCanvasScale, AFastRepaint, AFullRepaint, AUpdateStatusGeo);
end;

procedure TKeyMouseHook.ResetInteractionState;
begin
  InteractionActive := False;
  PanActive := False;
  ZoomActive := False;
end;

procedure TKeyMouseHook.FinalizeZoom;
var
  PivotPix: TPointF;
  PivotGeo: TPointF;
  OldScale: Double;
begin
  if Selector = nil then
    Exit;
  if not ZoomPreviewActive then
    Exit;

  if ZoomStartDistance <= 0 then
  begin
    EndZoomPreview;
    Exit;
  end;

  OldScale := ZoomBaseScale;
  if OldScale = 0 then
    OldScale := Selector.GetScale;
  if OldScale = 0 then
    Exit;
  if ZoomFactor <= 0 then
    Exit;

  if ZoomBaseRect = nil then
    Exit;
  if not ZoomBaseRect.isRect then
    Exit;

  PivotPix := PointF(ZoomPivot.X * CanvasScale, ZoomPivot.Y * CanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));

  Selector.ActiveRect := ZoomBaseRect;
  Selector.Scale(PivotGeo.X, PivotGeo.Y, ZoomFactor);

  EndZoomPreview;
  ZoomActive := False;
  InteractionActive := False;
end;

function TKeyMouseHook.GetDrawer: TogsDrawerCanvas;
begin
 Result := TogsDrawerCanvas(Selector.Drawer);
end;

procedure TKeyMouseHook.PainterMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
var
  P: TPoint;
  PF: TPointF;
  S: Single;
  Ctrl: TControl;
begin
  if Drawer = nil then
    Exit;
  if Selector = nil then
    Exit;

  InteractionActive := True;

  if BaseScale = 0 then
  begin
    BaseDx := Selector.GetDx;
    BaseDy := Selector.GetDy;
    BaseScale := Selector.GetScale;
  end;

  S := CanvasScale;
  if Sender is TControl then
    Ctrl := TControl(Sender)
  else
    Ctrl := nil;
  if Ctrl = nil then
    Exit;
  PF := Ctrl.AbsoluteToLocal(Screen.MousePos);
  P := Point(Round(PF.X * S), Round(PF.Y * S));

  Drawer.MouseWheel(Sender, Shift, WheelDelta, P, Handled);

  InteractionActive := False;
  FullRepaint;
end;

procedure TKeyMouseHook.PainterMouseLeave(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  if InteractionActive or PanActive or (ZoomStartDistance <> 0) then
  begin
    ResetInteractionState;
    FullRepaint;
  end;
end;

procedure TKeyMouseHook.PainterDblClick(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  InteractionActive := False;
  PanActive := False;
  EndZoomPreview;
  BaseScale := 0;
  Selector.UpdateRects(True);
  SceneDirty := True;
  FullRepaint;
end;

procedure TKeyMouseHook.ViewAll;
begin
  if Selector = nil then
    Exit;
  InteractionActive := False;
  PanActive := False;
  EndZoomPreview;
  BaseScale := 0;
  Selector.UpdateRects(True);
  SceneDirty := True;
  FullRepaint;
end;

procedure TKeyMouseHook.Scale(const PivotLocal: TPointF; const Koef: Double);
var
  PivotPix: TPointF;
  PivotGeo: TPointF;
begin
  if Selector = nil then
    Exit;
  if Koef <= 0 then
    Exit;

  PivotPix := PointF(PivotLocal.X * CanvasScale, PivotLocal.Y * CanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, Koef);
  SceneDirty := True;
  FullRepaint;
end;

procedure TKeyMouseHook.PainterMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Selector = nil then
    Exit;
  if ZoomPreviewActive or ZoomActive then
    Exit;

  if Assigned(UpdateStatusGeo) then
    UpdateStatusGeo(X, Y);

  PanActive := True;
  ZoomActive := False;
  EndZoomPreview;
  InteractionActive := True;

  BeginPanPreview(X, Y);

  if BaseScale = 0 then
  begin
    BaseDx := Selector.GetDx;
    BaseDy := Selector.GetDy;
    BaseScale := Selector.GetScale;
  end;

  LastPanPoint := PointF(X, Y);
end;

procedure TKeyMouseHook.PainterMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  DxPix, DyPix: Single;
  DxGeo, DyGeo: Double;
  S: Single;
begin
  if Selector = nil then
    Exit;

  if Assigned(UpdateStatusGeo) then
    UpdateStatusGeo(X, Y);

  if ZoomActive then
    Exit;
  if not PanActive then
    Exit;

  if PanPreviewActive then
  begin
    UpdatePanPreview(X, Y);
    Exit;
  end;

  if Selector.GetScale = 0 then
    Exit;

  S := CanvasScale;
  DxPix := (X - LastPanPoint.X) * S;
  DyPix := (Y - LastPanPoint.Y) * S;
  LastPanPoint := PointF(X, Y);

  DxGeo := DxPix / Selector.GetScale;
  DyGeo := DyPix / Selector.GetScale;
  Selector.Move(-DxGeo, -DyGeo);
  FullRepaint;
end;

procedure TKeyMouseHook.PainterMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  DxPix, DyPix: Double;
  DxGeo, DyGeo: Double;
  S: Single;
begin
  if ZoomPreviewActive and (Selector <> nil) then
    FinalizeZoom;

  if PanPreviewActive and (Selector <> nil) and (Selector.GetScale <> 0) then
  begin
    S := CanvasScale;
    DxPix := PanPreviewShift.X * S;
    DyPix := PanPreviewShift.Y * S;
    DxGeo := DxPix / Selector.GetScale;
    DyGeo := DyPix / Selector.GetScale;
    Selector.Move(-DxGeo, -DyGeo);
  end;

  EndPanPreview;
  ResetInteractionState;
  FullRepaint;
end;

procedure TKeyMouseHook.PainterGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if Drawer = nil then
    Exit;
  if Selector = nil then
    Exit;

  EndPanPreview;
  PanActive := False;
  Handled := True;

  if EventInfo.Distance <= 0 then
  begin
    FinalizeZoom;
    ResetInteractionState;
    FullRepaint;
    Exit;
  end;

  InteractionActive := True;
  ZoomActive := True;
  PanActive := False;

  if (not ZoomPreviewActive) and (ZoomStartDistance = 0) then
  begin
    BeginZoomPreview(EventInfo.Location, EventInfo.Distance);
    Exit;
  end;

  if ZoomStartDistance <= 0 then
    Exit;

  UpdateZoomPreview(EventInfo.Distance);
end;

end.
