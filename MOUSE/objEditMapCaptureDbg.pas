unit objEditMapCaptureDbg;

interface

uses System.UITypes, System.Types, System.Classes, System.SysUtils, System.Skia, FMX.Types,
     Collect, objMouseSelect, EcDot, EcDot2, WpTwigs, EcLot, RPrims, WPTForm2, polygons,
     ogcBasic, ogcDrawerSkia,
     objMouse, drawTwigs, SelectedObjects, FramePropEditor,
     ogcCaptureIntf, ogcMarker, ogcPolyPolyline,
     System.Generics.Collections;

const
 TIME_OF_CAPTURE = 2000; // время залипания курсора для захвата точки, мс
 DWELL_TIMER_INTERVAL = 100; // период проверки залипания, мс

type
 TMouseEditMap2 = class(TMouseSelector)
 private
  ICapturer: IogsPrimitiveCapturer;
  ISelection: IogsSelectionAccess;
  FMarker: TogsMarker;
  FMarkerPos: TPointF;
  FMarkerVisible: Boolean;
 // захват точки по залипанию курсора
  FDwellTimer: FMX.Types.TTimer;
  FDwellActive: Boolean; // есть кандидат на захват
  FDwellFired: Boolean; // кандидат уже захвачен
  FDwellStart: UInt64;
  FDwellRec: TCaptureRec;
  FCaptureTime: Integer;
  FCapturePoly: TPolyPolyline; // временная: полилинии через текущую захваченную точку
  fTimerPoints: TObjectList<TPolyDot>; // захваченные точки - источники направляющих
 //
  function FindTimerPoint(X, Y, Eps: Double): Integer;
  function IsDwellCandidate(const CRec: TCaptureRec): Boolean;
  procedure UpdateDwell(IsCandidate: Boolean; const CRec: TCaptureRec);
  procedure StopDwell;
  procedure CheckDwell;
  procedure DoDwellCapture;
  procedure DwellTimerProc(Sender: TObject);
 protected
  function emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState): TTwgObject;
  function emGetDotMarker(var varX, varY: Double; LastPoint: TDot; StvorLine: TStvorLine;
    out objPoint: TTwgObject; UsePathTwig: Boolean = True; UseGrid: Boolean = True;
    useSTS: boolean = False): boolean; override;
 public
  constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
  destructor Destroy; override;
 //
  procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  procedure ClearTimerPoints;
 //
  property CaptureTime: Integer read FCaptureTime write FCaptureTime;
  property CapturePoly: TPolyPolyline read FCapturePoly;
  property TimerPoints: TObjectList<TPolyDot> read fTimerPoints;
 end;

implementation uses Writer, System.Math;

function TMouseEditMap2.emGetDotMarker(var varX, varY: Double; LastPoint: TDot; StvorLine: TStvorLine;
  out objPoint: TTwgObject; UsePathTwig: Boolean; UseGrid: Boolean; useSTS: boolean): boolean;
begin
 Result := False;
 objPoint := nil;
end;

function TMouseEditMap2.emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState): TTwgObject;
begin
 Result := nil;
 TypeLot := 0;
end;

constructor TMouseEditMap2.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 ICapturer := nil;
 ISelection := nil;
 FMarker := TogsMarker.Create;
 FMarkerPos := TPointF.Create(0, 0);
 FMarkerVisible := False;
 FCaptureTime := TIME_OF_CAPTURE;
 FCapturePoly := TPolyPolyline.Create;
 fTimerPoints := TObjectList<TPolyDot>.Create(True);
 FDwellTimer :=FMX.Types.TTimer.Create(nil);
 FDwellTimer.Enabled := False;
 FDwellTimer.Interval := DWELL_TIMER_INTERVAL;
 FDwellTimer.OnTimer := DwellTimerProc;
 if Twigs <> nil then begin
  Supports(Twigs, IogsPrimitiveCapturer, ICapturer);
  Supports(Twigs, IogsSelectionAccess, ISelection);
 end;
end;

destructor TMouseEditMap2.Destroy;
begin
 FDwellTimer.Free;
 FCapturePoly.Free;
 fTimerPoints.Free;
 if ICapturer <> nil then ICapturer.ClearSelection;
//
 if FMarker <> nil then FMarker.Free;
 FMarker := nil;
 inherited;
end;

procedure TMouseEditMap2.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Filter: TogsCaptureFilter;
begin
 Hook := False;
 if Button = TMouseButton.mbMiddle then exit;
 inherited;
 Hook := True;
 if ICapturer = nil then exit;
 if ICapturer.HitTestPointWorld(X, Y, 1, Filter) > 0 then begin
  Selector.OnInvalidateOverlayStatic;
 end;
end;

procedure TMouseEditMap2.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 inherited;
end;

procedure TMouseEditMap2.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var T0, Dt: UInt64;
    Cnt: Integer;
    Filter: TogsCaptureFilter;
    NewVisible: Boolean;
    NewState: TogsMarkerType;
    CRec: TCaptureRec;
begin
 Hook := False;
 if ssMiddle in Shift then exit;
 Hook := True;
 inherited;
 if ICapturer = nil then exit;
 Filter := TogsCaptureFilter.AllKinds;
 T0 := TThread.GetTickCount64;
 Cnt := ICapturer.GetHitTestMarker(X, Y, 0, Filter, 1);
 Dt := TThread.GetTickCount64 - T0;
 NewVisible := (Cnt = 1);
 if NewVisible then begin
  WriteIn(['capture', 'dt_ms', Dt, 'of', ord(ICapturer.getLastCaptureRec.resCaptureOf)]);
  case ICapturer.getLastCaptureRec.resCaptureOf of
   ckPoint: NewState := mtPoint;
   ckLine: NewState := mtLine;
   ckPolygon: NewState := mtPolygon;
   ckMidLine: NewState := mtCenterLine;
  else
   NewState := mtPoint;
  end;
 end else
  NewState := mtNone;
 if (FMarkerVisible <> NewVisible) or ((FMarker <> nil) and (FMarker.State <> NewState)) then begin
  FMarkerVisible := NewVisible;
  if FMarker <> nil then FMarker.State := NewState;
  if Assigned(Selector.OnInvalidateOverlayLive) then
   Selector.OnInvalidateOverlayLive;
 end;
 if FMarkerVisible then begin
  FMarkerPos := TPointF.Create(ICapturer.getLastCaptureRec.XCapture, ICapturer.getLastCaptureRec.YCapture);
 end;
 CRec := ICapturer.getLastCaptureRec;
 UpdateDwell(NewVisible and IsDwellCandidate(CRec), CRec);
end;

function TMouseEditMap2.IsDwellCandidate(const CRec: TCaptureRec): Boolean;
begin
// вершина линейного объекта, середина отрезка или отдельно стоящая точка
 Result := (CRec.resCaptureOf in [ckPoint, ckMidLine]) or
  ((CRec.resObject <> nil) and (TObject(CRec.resObject) is TPointDot));
end;

procedure TMouseEditMap2.UpdateDwell(IsCandidate: Boolean; const CRec: TCaptureRec);
begin
 if not IsCandidate then begin
  StopDwell;
  exit;
 end;
// курсор остается на той же точке захвата
 if FDwellActive and (FDwellRec.resObject = CRec.resObject) and
  SameValue(FDwellRec.XCapture, CRec.XCapture) and SameValue(FDwellRec.YCapture, CRec.YCapture) then begin
  CheckDwell;
  exit;
 end;
// новый кандидат - начинаем отсчет заново
 FDwellRec := CRec;
 FDwellActive := True;
 FDwellFired := False;
 FDwellStart := TThread.GetTickCount64;
 FDwellTimer.Enabled := True;
end;

procedure TMouseEditMap2.StopDwell;
begin
 FDwellActive := False;
 FDwellFired := False;
 FDwellTimer.Enabled := False;
end;

procedure TMouseEditMap2.CheckDwell;
begin
 if (not FDwellActive) or FDwellFired then exit;
 if TThread.GetTickCount64 - FDwellStart < UInt64(FCaptureTime) then exit;
 FDwellFired := True;
 FDwellTimer.Enabled := False;
 DoDwellCapture;
end;

procedure TMouseEditMap2.DoDwellCapture;
var EpsWorld, Angle: Double;
    I: Integer;
begin
 if ICapturer = nil then exit;
// допуск совпадения координат - 1 пиксел
 EpsWorld := 0;
 if (Selector <> nil) and (Selector.GetScale > 0) then
  EpsWorld := 1 / Selector.GetScale;
// точка уже захвачена ранее
 if FindTimerPoint(FDwellRec.XCapture, FDwellRec.YCapture, EpsWorld) >= 0 then exit;
 ICapturer.HitTestPointTimer(FDwellRec, EpsWorld, FCapturePoly);
 WriteIn(['dwell capture', FDwellRec.XCapture, FDwellRec.YCapture, 'polylines', FCapturePoly.PolylineCount]);
 for I := 0 to FCapturePoly.PolylineCount - 1 do
  WriteIn(['  poly', I, 'points', FCapturePoly.PointCount[I]]);
// сохраняем точку; здесь же по FCapturePoly будут рассчитываться ее направляющие
 if TObject(FDwellRec.resObject) is TPointDot then Angle := TPointDot(FDwellRec.resObject).Ugol else Angle := 0;
 fTimerPoints.Add(TPolyDot.Create(FDwellRec.XCapture, FDwellRec.YCapture, FDwellRec.resObject, Angle));
 WriteIn(['timer points', fTimerPoints.Count]);
end;

function TMouseEditMap2.FindTimerPoint(X, Y, Eps: Double): Integer;
var I: Integer;
begin
 for I := 0 to fTimerPoints.Count - 1 do
  if (Abs(fTimerPoints[I].XDot - X) <= Eps) and (Abs(fTimerPoints[I].YDot - Y) <= Eps) then exit(I);
 Result := -1;
end;

procedure TMouseEditMap2.ClearTimerPoints;
begin
 fTimerPoints.Clear;
 FCapturePoly.ClearAll;
end;

procedure TMouseEditMap2.DwellTimerProc(Sender: TObject);
begin
 CheckDwell;
end;

procedure TMouseEditMap2.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var ViewScale: Single;
begin
 if (FMarker <> nil) and FMarkerVisible then
 begin
  if (Selector <> nil) then
   ViewScale := Single(Selector.GetScale)
  else
   ViewScale := 1;
  FMarker.Draw(Canvas, FMarkerPos, ViewScale);
 end;
end;

procedure TMouseEditMap2.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 WriteIn(['DTS1=', Now]);
  ICapturer.PainSelection(Canvas);
 WriteIn(['DTS2=', Now]);
end;

end.
