unit objEditMapCaptureDbg;

interface

uses System.UITypes, System.Types, System.Classes, System.SysUtils, System.Skia,
     Collect, objMouseSelect, EcDot, EcDot2, WpTwigs, EcLot, RPrims, WPTForm2, polygons,
     ogcBasic, ogcDrawerSkia,
     objMouse, drawTwigs, SelectedObjects, FramePropEditor,
     ogcCaptureIntf, ogcMarker;

type
 TMouseEditMap2 = class(TMouseSelector)
 private
  FObjects: TSelectedObjects;
  FCapturer: IogsPrimitiveCapturer;
  FSelection: IogsSelectionAccess;
  FMarker: TogsMarker;
  FMarkerPos: TPointF;
  FMarkerVisible: Boolean;
  function GetObjects: TSelectedObjects;
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

  property Objects: TSelectedObjects read GetObjects;
 end;

implementation uses Writer;

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
 FObjects := nil;
 FCapturer := nil;
 FSelection := nil;
 FMarker := TogsMarker.Create;
 FMarkerPos := TPointF.Create(0, 0);
 FMarkerVisible := False;
 if Twigs <> nil then begin
  Supports(Twigs, IogsPrimitiveCapturer, FCapturer);
  Supports(Twigs, IogsSelectionAccess, FSelection);
 end;
end;

destructor TMouseEditMap2.Destroy;
begin
 if FMarker <> nil then FMarker.Free;
 FMarker := nil;
 if FObjects <> nil then FObjects.Free;
 FObjects := nil;
 inherited;
end;

function TMouseEditMap2.GetObjects: TSelectedObjects;
begin
 Result := FObjects;
end;

procedure TMouseEditMap2.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 inherited;
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
begin
 Hook := True;
 inherited;
 if FCapturer = nil then exit;
 Filter := TogsCaptureFilter.AllKinds;
 T0 := TThread.GetTickCount64;
 Cnt := FCapturer.GetHitTestMarker(X, Y, 0, Filter, 1);
 Dt := TThread.GetTickCount64 - T0;
 NewVisible := (Cnt = 1);
 if NewVisible then begin
  WriteIn(['capture', 'dt_ms', Dt, 'of', ord(Form.LastCaptureRec.resCaptureOf)]);
  case Form.LastCaptureRec.resCaptureOf of
   ckPoint: NewState := mtPoint;
   ckLine: NewState := mtLine;
   ckPolygon: NewState := mtPolygon;
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
 if FMarkerVisible then
  FMarkerPos := TPointF.Create(X, Y);
end;

procedure TMouseEditMap2.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if (FMarker <> nil) and FMarkerVisible then
  FMarker.Draw(Canvas, FMarkerPos);
end;

end.
