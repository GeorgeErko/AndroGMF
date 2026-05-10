unit objEditMap;

interface

uses
  System.UITypes, System.Types, System.Classes, System.SysUtils, System.Skia,
  Collect, objMouseSelect, EcDot, EcDot2, WpTwigs, EcLot, RPrims, WPTForm2, polygons,
  ogcBasic, ogcDrawerSkia,
  objMouse, drawTwigs, SelectedObjects, FramePropEditor;

const
 em_GetObject = 500;

type
  TMouseEditMap = class(TMouseSelector)
  private
    FObjects: TSelectedObjects;
    FLastCaptureX: Double;
    FLastCaptureY: Double;
    FLastHitX: Double;
    FLastHitY: Double;
    FLastCapturedKind: TCaptureKind;
    FLastCapturedObject: Pointer;
    function GetObjects: TSelectedObjects;
    procedure ClearSelection;
    procedure ToggleSelection(Obj: TTwgObject);
    procedure AddSelection(Obj: TTwgObject);
  protected
    function emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState): TTwgObject;
    function emGetDotMarker(var varX, varY: Double; LastPoint: TDot; StvorLine: TStvorLine;
      out objPoint: TTwgObject; UsePathTwig: Boolean = True; UseGrid: Boolean = True;
      useSTS: boolean = False): boolean; override;
  public
    constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
    destructor Destroy; override;

    procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
    procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
    procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;

    property Objects: TSelectedObjects read GetObjects;
  end;

implementation uses TwgColle, mpMarker, Writer, TwgDraw, instLayerFrame;

function TMouseEditMap.emGetDotMarker(var varX, varY: Double; LastPoint: TDot; StvorLine: TStvorLine;
  out objPoint: TTwgObject; UsePathTwig: Boolean; UseGrid: Boolean; useSTS: boolean): boolean;
var
  XClick, YClick: Double;
  I: Integer;
  W: Byte;
  CaptureDrawer: TogsCaptureDrawerSkia;
  PrevDrawer: TogsDrawer;
  Params: TCaptureRec;
  OwnCapture: Boolean;
  Lot: TLot;
  PP: TPointDot;
begin
  Result := False;
  objPoint := nil;
  if Selector = nil then
    Exit;

  if LMouseDown then
  begin
    if (Marker <> nil) and Marker.Visible then
      Marker.Remove(nil);
    Exit;
  end else With Selector do begin
   If GGraphSet.PaintFragment<1 then GGraphSet.PaintFragment:=300;
 //WriteIn(['H=', Selector.Drawer.Height, Selector. YGeoRasst(Selector.Drawer.Height)]);
   If Selector.YGeoRasst(Selector.Drawer.Height) > GGraphSet.PaintFragment then
    exit;
  end;

  XClick := varX;
  YClick := varY;

  CaptureDrawer := nil;
  OwnCapture := False;
  With Twigs do
  try
//   WriteIn(['CreateCapture.emGetMarker=', Selector.Drawer.ClassName]);
    PrevDrawer := Selector.Drawer;
    CaptureDrawer := TogsCaptureDrawerSkia.CreateCapture(Selector);
    Params := CRClearParams([ckLine]);
    Params.CaptureParam := GlobalSettings.Settings.gsPointSize * 2;
    CaptureDrawer.BeginCapture(XClick, YClick, Params);
    CaptureDrawer.UseWorldCoords := True;

    for I := Twigs.IndexCount - 1 downto 0 do
    begin
      Lot := Twigs.LAtIndex(I);
      if (Lot = nil) or (Lot.Closed = 0) or (Lot.TypeLot = 254) then
        Continue;
      if not Lot.IsVisible(Selector.GPRect) then
        Continue;
      Lot.Selector := Selector;

      CaptureDrawer.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
      try
        Lot.Draw32(Twigs);
      finally
        CaptureDrawer.EndPrimitive;
      end;
    end;

    for I := Twigs.AnyCount - 1 downto 0 do
    begin
      PP := Twigs.AAt(I, W);
      if (W <> TWG_Point) or (PP = nil) then
        Continue;
      if not PP.isNoClosed then
        Continue;
      if not PP.isVisible then
        Continue;
      PP.Selector := Selector;

      CaptureDrawer.BeginPrimitive(Int64(NativeInt(PP)), PP);
      try
        PP.Draw32(CaptureDrawer, MkLib.PSLib, FontColEx, True);
      finally
        CaptureDrawer.EndPrimitive;
      end;
    end;

    if Params.resObject <> nil then
    begin
      objPoint := TTwgObject(Params.resObject);
      varX := Params.XCapture;
      varY := Params.YCapture;
      if Marker <> nil then
      begin
        Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvLine'], nil);
        Marker.Move(nil, varX, varY, MoveNone, 0, 'cap');
      end;
      TimerOpen;
      Result := True;
    end
    else
    begin
      if (Marker <> nil) and Marker.Visible then
        Marker.Remove(nil);
    end;
  finally
    CaptureDrawer.EndCapture;
    CaptureDrawer.Free;
//    WriteIn(['FreeCapture.emGetMarker=', Selector.Drawer.ClassName]);
  end;
end;

function TMouseEditMap.emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState): TTwgObject;
var
  X1, Y1: Double;
  XClick, YClick: Double;
  Twig: TTwig;
  Lot: TLot;
  I, J, K: Integer;
  W: Byte;
  PP: TPointDot;
  Bm: TBmpMgr;
  CaptureDrawer: TogsCaptureDrawerSkia;
  PrevDrawer: TogsDrawer;
  Params: TCaptureRec;
  Tw: TTwig;
  OwnCapture: Boolean;
  function PointIn(K: Integer): Boolean;
  var
    Tw: TTwig;
    J: Integer;
    S: Double;
  begin
    Result := False;
    with Lot do
      for J := 0 to Coord.Count - 1 do
      begin
        Tw := Twigs.Twigs.TAt(TLong(Coord[J]).Num);
        if Tw.IsVisible(Selector.GRect) then
        begin
          S := Tw.GetTwigDist(X, Y, X1, Y1);
          if Selector.XRasst(S) <= Twigs.Settings.psAutoDisst * K then
          begin
            Result := True;
            Break;
          end;
        end;
      end;
  end;
begin
  Result := nil;
  TypeLot := 0;
  FLastCapturedKind := ckPoint;
  FLastCapturedObject := nil;
  FLastHitX := 0;
  FLastHitY := 0;
  XClick := X;
  YClick := Y;
  FLastCaptureX := XClick;
  FLastCaptureY := YClick;

  if (Twigs.Twigs.TwigsCount = 1) and (Twigs.Twigs.AnyCount = 0) and (Twigs.Twigs.Bitmaps.Count = 0) then
    Exit;

  emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
  if (objTemporary <> nil) and (objTemporary is TPointDot) and (not (objTemporary is TDotText)) and TPointDot(objTemporary).isNoClosed then
  begin
    Result := objTemporary;
    X := TPointDot(objTemporary).XDot;
    Y := TPointDot(objTemporary).YDot;
    Exit;
  end;

  if (Marker <> nil) and Marker.Visible then
    Marker.Remove(nil);

  with Twigs do begin
    CaptureDrawer := nil;
    PrevDrawer := Selector.Drawer;
    OwnCapture := False;
    try
//     WriteIn(['CreateCapture.emGetObj=', Selector.Drawer.ClassName]);
      CaptureDrawer := TogsCaptureDrawerSkia.CreateCapture(Selector);
      Params := CRClearParams([ckLine, ckPolygon]);
      Params.CaptureParam := GlobalSettings.Settings.gsPointSize * 2;
      CaptureDrawer.BeginCapture(XClick, YClick, Params);
      CaptureDrawer.UseWorldCoords := True;

    for I := Twigs.AnyCount - 1 downto 0 do
    begin
      PP := Twigs.AAt(I, W);
      if (W <> TWG_Point) or (PP = nil) then
        Continue;
      if not PP.isNoClosed then
        Continue;
      if not PP.isVisible then
        Continue;

      PP.Selector := Selector;
      CaptureDrawer.BeginPrimitive(Int64(NativeInt(PP)), PP);
      try
        PP.Draw32(CaptureDrawer, MkLib.PSLib, FontColEx, True);
      finally
        CaptureDrawer.EndPrimitive;
      end;

      if Params.resObject = PP then
      begin
        TypeLot := 0;
        Result := TTwgObject(PP);
        Exit;
      end;
    end;

    for I := Twigs.IndexCount - 1 downto 0 do
    begin
      Lot := Twigs.LAtIndex(I);
      if (Lot.Closed = 0) or (Lot.TypeLot = 254) then
        Continue;
      if not Lot.IsVisible(Selector.GPRect) then
        Continue;

      Lot.Selector := Selector;
      CaptureDrawer.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
      try
        Lot.Draw32(Twigs);
      finally
        CaptureDrawer.EndPrimitive;
      end;

      if Params.resObject = Lot then
      begin
        TypeLot := Lot.TypeLot;
        Result := Lot;
//        WriteIn(['lot.exit']);
        Exit;
      end;
    end;
    finally
      FLastCapturedKind := Params.resCaptureOf;
      FLastCapturedObject := Params.resObject;
      FLastHitX := Params.XCapture;
      FLastHitY := Params.YCapture;
      CaptureDrawer.EndCapture;
      CaptureDrawer.Free;
//      WriteIn(['FreeCapture.emGetObj=', Selector.Drawer.ClassName]);
    end;
  end;
end;

constructor TMouseEditMap.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
  inherited;
  If PropEditorForm <> nil then
    FObjects := TSelectedObjects.Create(Twigs, PropEditorForm.Update)
  else
    FObjects := TSelectedObjects.Create(Twigs, nil);
end;

destructor TMouseEditMap.Destroy;
begin
  if FObjects <> nil then
  begin
   Writein(['EM.Destroy1']);
    FObjects.Locked := True;
    FObjects.OnUpdate := nil;
    FObjects.DeleteAll;
    PropEditorForm.Update(FObjects);
   Writein(['EM.Destroy2']);
    FObjects.Free;
    FObjects := nil;
      Writein(['EM.Destroy3']);
  end;
  inherited;
     Writein(['EM.Destroy4']);
end;

function TMouseEditMap.GetObjects: TSelectedObjects;
begin
 Result := FObjects;
end;

procedure TMouseEditMap.ClearSelection;
begin
  if FObjects = nil then
    Exit;
  FObjects.DeleteAll;
  if Selector <> nil then
    Selector.UpdateOverlay;
end;

procedure TMouseEditMap.AddSelection(Obj: TTwgObject);
begin
  if (Obj = nil) or (FObjects = nil) then
    Exit;
  if FObjects.IndexOf(Obj) < 0 then begin
   FObjects.Insert(Obj);
   If Assigned(LayerFrame) then
    If Obj is TLot then
     LayerFrame.ActiveLayer := TLot(Obj).ClassHandle else
      If Obj is TPointDot then
       LayerFrame.ActiveLayer := TPointDot(Obj).ClassHandle else
  end;
  if Selector <> nil then
    Selector.UpdateOverlay;
end;

procedure TMouseEditMap.ToggleSelection(Obj: TTwgObject);
var
  Idx: Integer;
begin
  if (Obj = nil) or (FObjects = nil) then
    Exit;
  Idx := FObjects.IndexOf(Obj);
  if Idx >= 0 then
    FObjects.AtDelete(Idx)
  else begin
   FObjects.Insert(Obj);
   If Assigned(LayerFrame) then
    If Obj is TLot then
     LayerFrame.ActiveLayer := TLot(Obj).ClassHandle else
      If Obj is TPointDot then
       LayerFrame.ActiveLayer := TPointDot(Obj).ClassHandle else
  end;
  if Selector <> nil then
    Selector.UpdateOverlay;
end;

procedure TMouseEditMap.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var
  Obj: TTwgObject;
  TypeLot: Byte;
  XX, YY: Double;
begin
  Hook := True;
  if Button <> TMouseButton.mbLeft then begin
   inherited;
   exit;
  end;
  XX := X;
  YY := Y;
  Obj := emGetObject(XX, YY, TypeLot, Shift);
  ToggleSelection(Obj);
  if Selector <> nil then
    Selector.UpdateOverlay;
end;

procedure TMouseEditMap.MouseUp(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
end;

procedure TMouseEditMap.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var
  I, J, K: Integer;
  Obj: TTwgObject;
  PD: TPointDot;
  DT: TDotText;
  Paint: ISkPaint;
  R: TRectF;
  D: Single;
  NominalPxHeight: Double;
  XP, YP: Double;
  GX, GY: Double;
  SX, SY: Double;
  Wt, Ht: Double;
  OffX, OffY: Double;
  X0, Y0, X1, Y1, X2, Y2, X3, Y3: Double;
  C, S: Double;
  RX, RY: Double;
  Poly: array[0..3] of TPointF;
  Lot: TLot; Tw: TTwig;
  procedure DrawPointRect(const Xg, Yg: Double);
  var
    Inset: Single;
    D2: Single;
  begin
    D := Single(geoDist(Twigs.FGraphset.RPoint));
    R := TRectF.Create(Single(Xg) - D, Single(Yg) - D, Single(Xg) + D, Single(Yg) + D);
    Canvas.DrawRect(R, Paint);

    Inset := Single(geoDist(1));
    D2 := D + Inset;
    R := TRectF.Create(Single(Xg) - D2, Single(Yg) - D2, Single(Xg) + D2, Single(Yg) + D2);
    Canvas.DrawRect(R, Paint);
  end;

begin
  inherited;
  if Canvas = nil then
    Exit;
  Paint := TSkPaint.Create;
  Paint.AntiAlias := True;
  Paint.Style := TSkPaintStyle.Stroke;
  Paint.Color := TAlphaColors.Lime;
  Paint.StrokeWidth := Single(geoDist(2));

  if FObjects = nil then
    Exit;

  for I := 0 to FObjects.Count - 1 do
  begin
    Obj := TTwgObject(FObjects[I]);
    if Obj = nil then
      Continue;

    if Obj is TPointDot then
    begin
      PD := TPointDot(Obj);
      DrawPointRect(PD.XDot, PD.YDot);
      Continue;
    end;

    if Obj is TDotText then
    begin
      DT := TDotText(Obj);
      if (DT.Text = nil) or (DT.TextBitmap = nil) or (DT.TextBitmap.Width <= 0) or (DT.TextBitmap.Height <= 0) then
        Continue;

      NominalPxHeight := 100;
      GX := DT.Text.Height / NominalPxHeight;
      GY := DT.Text.Height / NominalPxHeight;
      SX := GX;
      SY := GY;
      if DT.XKoef <> 0 then
        SX := SX * DT.XKoef;

      Wt := DT.TextBitmap.Width * SX;
      Ht := DT.TextBitmap.Height * SY;

      DT.Text.GetXPYP(XP, YP);
      OffX := (DT.BaseLineXPix + (DT.TextBitmap.Width - DT.BaseLineXPix - DT.RightPadPix) * XP) * SX;
      if YP < 0 then
        OffY := DT.BaseLinePix * SY
      else
        OffY := (DT.SymbolTopPix + DT.SymbolHeightPix * YP) * SY;

      X0 := -OffX;
      Y0 := -OffY;
      X1 := -OffX + Wt;
      Y1 := -OffY;
      X2 := -OffX + Wt;
      Y2 := -OffY + Ht;
      X3 := -OffX;
      Y3 := -OffY + Ht;

      C := Cos(DT.Ugol);
      S := Sin(DT.Ugol);
      RX := X0 * C - Y0 * S; RY := X0 * S + Y0 * C; Poly[0] := TPointF.Create(Single(DT.XDot + RX), Single(DT.YDot + RY));
      RX := X1 * C - Y1 * S; RY := X1 * S + Y1 * C; Poly[1] := TPointF.Create(Single(DT.XDot + RX), Single(DT.YDot + RY));
      RX := X2 * C - Y2 * S; RY := X2 * S + Y2 * C; Poly[2] := TPointF.Create(Single(DT.XDot + RX), Single(DT.YDot + RY));
      RX := X3 * C - Y3 * S; RY := X3 * S + Y3 * C; Poly[3] := TPointF.Create(Single(DT.XDot + RX), Single(DT.YDot + RY));

      Canvas.DrawLine(Poly[0], Poly[1], Paint);
      Canvas.DrawLine(Poly[1], Poly[2], Paint);
      Canvas.DrawLine(Poly[2], Poly[3], Paint);
      Canvas.DrawLine(Poly[3], Poly[0], Paint);
      Continue;
    end;

    if Obj is TLot then
    begin
      Lot := TLot(Obj);
      for J := 0 to Lot.Coord.Count - 1 do
      begin
        Tw := Twigs.Twigs.TAt(TLong(Lot.Coord[J]).Num);
        if Tw = nil then
          Continue;
        if not Tw.IsVisible(Selector.GRect) then
          Continue;
        for K := 0 to Tw.Coord.Count - 2 do
          Canvas.DrawLine(TPointF.Create(Single(Tw[K].XDot), Single(Tw[K].YDot)), TPointF.Create(Single(Tw[K + 1].XDot), Single(Tw[K + 1].YDot)), Paint);

        for K := 0 to Tw.Coord.Count - 1 do
          DrawPointRect(Tw[K].XDot, Tw[K].YDot);
      end;
      Continue;
    end;

    if Obj is TTwig then
    begin
      Tw := TTwig(Obj);
      if Tw.IsVisible(Selector.GRect) then
      begin
        for K := 0 to Tw.Coord.Count - 2 do
          Canvas.DrawLine(TPointF.Create(Single(Tw[K].XDot), Single(Tw[K].YDot)), TPointF.Create(Single(Tw[K + 1].XDot), Single(Tw[K + 1].YDot)), Paint);
        for K := 0 to Tw.Coord.Count - 1 do
          DrawPointRect(Tw[K].XDot, Tw[K].YDot);
      end;
      Continue;
    end;
  end;
end;

end.
