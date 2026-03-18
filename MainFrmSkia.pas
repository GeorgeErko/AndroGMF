unit MainFrmSkia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts,
  MainFrm, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Objects, FMX.Skia, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  ogcBasic, ogcDrawerSkia;

type
  TMainFormSkia = class(TMainForm)
    SkPainter: TSkPaintBox;
    SceneProgressOverlay: TLayout;
    SceneProgressBar: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure btnPaintClick(Sender: TObject);
    procedure upmClick(Sender: TObject);
  private
    FStatusLabel: TLabel;
    FDrawerSkia: TogsDrawerSkia;
    FCachedPicture: ISkPicture;
    FBuildingScene: Boolean;
    PanBitmap: TBitmap;
    PanBitmapActive: Boolean;
    PanStartPoint: TPointF;
    PanShift: TPointF;
    PanBaseDx: Double;
    PanBaseDy: Double;
    ZoomBitmapActive: Boolean;
    ZoomStartDistance: Single;
    ZoomFactor: Single;
    ZoomPivot: TPointF;
    ZoomBaseRect: TogsRect;
    ZoomBaseDx: Double;
    ZoomBaseDy: Double;
    ZoomBaseScale: Double;
    PanActive: Boolean;
    LastPanPoint: TPointF;
    LastZoomDistance: Single;
    ZoomActive: Boolean;
    InteractionActive: Boolean;
    BaseDx, BaseDy, BaseScale: Double;

    procedure InitSkPainterInput;

    procedure RenderSceneToBackbufferSkia;

    procedure OpenGmfFileSkia(const LocalPath: string);
    procedure btnOpenClickSkia(Sender: TObject);
    procedure btnLocalOpenClickSkia(Sender: TObject);
    procedure btnPaintClickSkia(Sender: TObject);
    procedure btnPlusClickSkia(Sender: TObject);

    procedure SkPainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);

    procedure SkPainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure SkPainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure SkPainterMouseLeave(Sender: TObject);
    procedure SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure SkPainterDblClick(Sender: TObject);

    procedure ResetInteractionState;
    procedure FinalizeZoom;
    procedure UpdateStatusGeo(const X, Y: Single);
    procedure BuildCachedPicture;
    procedure CapturePanBitmap;

    procedure SceneProgressShow(const AMax: Single);
    procedure SceneProgressSet(const AValue: Single);
    procedure SceneProgressHide;
  protected
    procedure Loaded; override;
  public
    destructor Destroy; override;
    procedure OpenGmfFile(const LocalPath: string); override;
  end;

var
  MainFormSkia: TMainFormSkia;

implementation

uses Collect, uExecRegisterClass, System.IOUtils, Writer, newProcs, FMX.FontManager,
     OpenForm, EcText, EcDot, EcDot2, EcLot, RPrims, WPTwigs, DlgLocalOpen,
     newSelector, WPTForm2;

{$R *.fmx}

procedure TMainFormSkia.InitSkPainterInput;
begin
  if SkPainter = nil then
    Exit;

  SkPainter.AutoCapture := True;
  SkPainter.OnMouseDown := SkPainterMouseDown;
  SkPainter.OnMouseMove := SkPainterMouseMove;
  SkPainter.OnMouseUp := SkPainterMouseUp;
  SkPainter.OnMouseLeave := SkPainterMouseLeave;
  SkPainter.OnMouseWheel := SkPainterMouseWheel;
  SkPainter.OnGesture := SkPainterGesture;
  SkPainter.OnDblClick := SkPainterDblClick;
  SkPainter.OnDraw := SkPainterDraw;
  SkPainter.Touch.InteractiveGestures := [TInteractiveGesture.Zoom];
end;

procedure TMainFormSkia.FormCreate(Sender: TObject);
begin
//
  LastCanvasScale := 1;

  FBuildingScene := False;

  PanBitmap := nil;
  PanBitmapActive := False;
  ZoomBaseRect := nil;
  ZoomBitmapActive := False;
  ZoomStartDistance := 0;
  ZoomFactor := 1;
  PanActive := False;
  ZoomActive := False;
  InteractionActive := False;
  LastZoomDistance := 0;
  BaseScale := 0;

  if (StatusBar <> nil) and (FStatusLabel = nil) then
  begin
    FStatusLabel := TLabel.Create(StatusBar);
    FStatusLabel.Parent := StatusBar;
    FStatusLabel.Align := TAlignLayout.Client;
  end;

  if btnPaint <> nil then
    btnPaint.OnClick := btnPaintClickSkia;
  if btnPlus <> nil then
    btnPlus.OnClick := btnPlusClickSkia;
  if ptnMinus <> nil then
    ptnMinus.OnClick := btnPlusClickSkia;
  if CornerButton1 <> nil then
    CornerButton1.OnClick := btnOpenClickSkia;

  InitSkPainterInput;
end;

procedure TMainFormSkia.SceneProgressShow(const AMax: Single);
begin
  if SceneProgressOverlay <> nil then
  begin
    SceneProgressOverlay.Visible := True;
    SceneProgressOverlay.BringToFront;
  end;
  if SceneProgressBar <> nil then
  begin
    SceneProgressBar.Min := 0;
    SceneProgressBar.Max := AMax;
    SceneProgressBar.Value := 0;
  end;
end;

procedure TMainFormSkia.SceneProgressSet(const AValue: Single);
begin
  if (SceneProgressOverlay <> nil) and (not SceneProgressOverlay.Visible) then
    Exit;
  if SceneProgressBar <> nil then
    SceneProgressBar.Value := AValue;
end;

procedure TMainFormSkia.SceneProgressHide;
begin
  if SceneProgressOverlay <> nil then
    SceneProgressOverlay.Visible := False;
end;

procedure TMainFormSkia.Loaded;
begin
  inherited;
  FormCreate(Self);
end;

destructor TMainFormSkia.Destroy;
begin
  PanBitmap.Free;
  PanBitmap := nil;
  ZoomBaseRect.Free;
  ZoomBaseRect := nil;
  FDrawerSkia.Free;
  FDrawerSkia := nil;
  inherited Destroy;
end;

procedure TMainFormSkia.OpenGmfFile(const LocalPath: string);
begin
  OpenGmfFileSkia(LocalPath);
end;

procedure TMainFormSkia.OpenGmfFileSkia(const LocalPath: string);
var
  Stream: TBufStream;
  Path: String;
  I: Integer;
  B: Byte;
  PP: TPointDot;
  procedure RegisterFontsNearGmf(const GmfLocalPath: string);
  var
    Dir: string;
    Files: TStringDynArray;
    F: string;
    I: Integer;
    TF: ISkTypeface;
  begin
    Dir := ExtractFilePath(GmfLocalPath);
    if Dir = '' then
      Exit;
    try
      Files := TDirectory.GetFiles(Dir, '*.ttf');
      for F in Files do
        try
          TFontManager.AddCustomFontFromFile(F);
          TSkDefaultProviders.RegisterTypeface(F);
          RegisterSkiaTypefaceFromFile(F);
          WriteIn(['addfnt=', F]);
          TF := TSkTypeface.MakeFromFile(F);
           if TF <> nil then
            begin
             WriteIn(['sk_fam=', TF.FamilyName, ' file=', F]);
             RegisterSkiaFontFile(TF.FamilyName, F);
            end;
        except
        end;
    except
    end;
    try
      Files := TDirectory.GetFiles(Dir, '*.otf');
      for F in Files do
        try
          TFontManager.AddCustomFontFromFile(F);
          TSkDefaultProviders.RegisterTypeface(F);
          RegisterSkiaTypefaceFromFile(F);
        except
        end;
    except
    end;
    for I := 0 to TFontManager.CustomFontInfoCount - 1 do
      WriteIn(['fm=', TFontManager.CustomFontInfo[I].FamilyName]);
  end;

  procedure localSetGabarites;
  var
    I, J: Integer;
    Twig: TTwig;
  begin
    for I := 1 to TwgForm.Twigs.TwigsCount - 1 do
    begin
      Twig := TwgForm.Twigs.TAt(I);
      for J := 0 to Twig.Coord.Count - 1 do
        Selector.AddCoord(Twig[J].XDot, Twig[J].YDot);
    end;
  end;
begin
  if FDrawerSkia = nil then
  begin
    FDrawerSkia := TogsDrawerSkia.Create(nil, nil);
    Selector := TSelector.Create(FDrawerSkia);
    FDrawerSkia.ogsSelector := Selector;
    FDrawerSkia.Name := 'DrawerSkia';
    Selector.Name := 'Selector';
  end
  else
    Selector.Clear;

  Memo1.Lines.Clear;
  FormCreate(Self);
 // InitSkPainterInput;
  GLines := Memo1.Lines;
  newProcs.MainPath := TPath.GetDocumentsPath;
  WriteIn(['Test1', TPath.GetDocumentsPath]);
  RegPrimitives;
  WriteIn(['Registered']);
  objectRepaintAccess := False;
  Path := LocalPath;
  if LocalPath = '' then
  begin
    WriteIn(['Path Space']);
    Exit;
  end;
  WriteIn(['Path=', ExtractFilePath(LocalPath), SizeOf(Single), SizeOf(Double)]);
  newProcs.MainPath := ExtractFilePath(LocalPath);

  RegisterFontsNearGmf(LocalPath);

  Stream := TBufStream.InitFileStream(LocalPath, fmOpenRead);
  Selector.GNForm := TControl(Self);
  Selector.GNForm := TControl(Self);
  WriteIn(['s.Drawer=', Selector.Drawer = nil]);
  ApplicationMainForm := Self;
  Stream.Selector := Selector;
  try
    FreeAndNil(TwgForm);

    TwgForm := TForm2(Stream.Get);
    Selector.GLineCol := TwgForm.MkLib.LSLib;
    Selector.GSqwearCol := TwgForm.MkLib.SSLib;
    Selector.GPointCol := TwgForm.MkLib.PSLib;
    Selector.GFontCollect := TwgForm.Twigs.FontS;
    Selector.GFontSet := TwgForm.Twigs.FontSet;
    Selector.GGraphSet := TwgForm.fGraphSet;
    if TwgForm.FontColEx <> nil then
    begin
      for I := 0 to TwgForm.Twigs.AnyCount - 1 do
      begin
        PP := TwgForm.Twigs.AAt(I, B);
        PP.ResetParams(param_idResetFontView, TwgForm.FontColEx);
      end;
    end;
    localSetGabarites;
    Selector.UpdateRects(True);
    objectRepaintAccess := True;
    WriteIn(['TwgForm=', TwgForm.Twigs.TwigsCount, TwgForm.Twigs.LotsCount, TwgForm.Twigs.AnyCount]);
    WriteIn(['Sel.Rect=', Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
  finally
    Stream.Free;
  end;

  InitSkPainterInput;
  SceneDirty := True;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.btnOpenClickSkia(Sender: TObject);
begin
  PickGmfFile(OpenGmfFileSkia);
end;

procedure TMainFormSkia.btnLocalOpenClickSkia(Sender: TObject);
begin
  localOpenForm := TlocalOpenForm.Create(Self);
  localOpenForm.FCallBack := OpenGmfFileSkia;
  localOpenForm.Show;
end;

procedure TMainFormSkia.btnPaintClick(Sender: TObject);
begin
  SceneDirty := True;
  SkPainter.Redraw;
end;

procedure TMainFormSkia.btnPaintClickSkia(Sender: TObject);
begin
  SceneDirty := True;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.btnPlusClickSkia(Sender: TObject);
var
  Btn: TControl;
  Koef: Double;
  CenterLocal: TPointF;
  CenterPix: TPointF;
  PivotGeo: TPointF;
begin
  if Selector = nil then
    Exit;
  if SkPainter = nil then
    Exit;
  if Sender is TControl then
    Btn := TControl(Sender)
  else
    Btn := nil;
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;

  Koef := 1.20;
  if (Btn <> nil) and (Btn.Tag < 0) then
    Koef := 1 / Koef;
  if Koef <= 0 then
    Exit;

  CenterLocal := PointF(SkPainter.Width * 0.5, SkPainter.Height * 0.5);
  CenterPix := PointF(CenterLocal.X * LastCanvasScale, CenterLocal.Y * LastCanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(CenterPix.X)), Selector.YGeo(Round(CenterPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, Koef);
  SkPainter.Redraw;
end;

procedure TMainFormSkia.UpdateStatusGeo(const X, Y: Single);
var
  XPix, YPix: Double;
  XGeo, YGeo: Double;
  S: string;
begin
  if StatusBar = nil then
    Exit;
  if Selector = nil then
    Exit;
  if Selector.GetScale = 0 then
    Exit;
  XPix := X * LastCanvasScale;
  YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix));
  YGeo := Selector.YGeo(Round(YPix));
  S := Fmt(['XGeo=', XGeo, 'YGeo=', YGeo, 'objRect=', Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
  if FStatusLabel <> nil then
    FStatusLabel.Text := S;
end;

procedure TMainFormSkia.upmClick(Sender: TObject);
begin
 Memo1.GoToTextEnd;
end;

procedure TMainFormSkia.RenderSceneToBackbufferSkia;
var
  I, J, N, CL, TWC, Counter: LongInt;
  Tw: TTwig;
  Lot: TLot;
  PP: Pointer;
  F: TEFont;
  PPoint: TPointDot;
  BMP: TBmpSet;
  B: Byte;
  Kl: SmallInt;
  W: Word;
  R: TRect;
  TwgDc: hDc;
  UpLot: Boolean;
  LCo: Integer;
  Error: Integer;
  X1, X2, X3, X4: Double;
  Total: Single;
  Prog: Single;
begin
  Error := 1;
  if FDrawerSkia = nil then
    Exit;
  if TwgForm = nil then
    Exit;
  if not objectRepaintAccess then
    Exit;
  GLines := nil;

  FDrawerSkia.Width := Round(SkPainter.Width * LastCanvasScale);
  FDrawerSkia.Height := Round(SkPainter.Height * LastCanvasScale);
  FDrawerSkia.Clear(TAlphaColors.White);

  Total := 0;
  if TwgForm <> nil then
    Total := TwgForm.Twigs.LotsCount + TwgForm.Twigs.AnyCount;
  if Total < 1 then
    Total := 1;
  Prog := 0;
  GlobalRender := True;
  SceneProgressShow(Total);
  SceneProgressSet(0);

  with Selector, GGraphset do
    try
      Error := 6;
      Error := 7;
      TWC := 0;
      begin
        if FillLot = 1 then
        begin
          for I := 0 to TwgForm.Twigs.LotsCount - 1 do
          begin
            Lot := TwgForm.Twigs.LAt(I);
            try
              if (Lot.TypeLot <> 254) and (Lot.Closed = 1) then
              begin
                FDrawerSkia.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
                try
                  Lot.Draw32(TwgForm.Twigs);
                finally
                  FDrawerSkia.EndPrimitive;
                end;
              end;
            except
              Exit;
            end;

            Prog := Prog + 1;
            if (I mod 25) = 0 then
            begin
              SceneProgressSet(Prog);
            end;
          end;
        end;
      end;
      for I := 0 to TwgForm.Twigs.AnyCount - 1 do
      begin
        PP := TwgForm.Twigs.AAt(I, B);
        if (B = TWG_Point) then
        begin
          PPoint := PP;
          if PPoint.Closed then
            Continue;
          try
            FDrawerSkia.BeginPrimitive(Int64(NativeInt(PPoint)), PPoint);
            try
              PPoint.Draw32(FDrawerSkia, TwgForm.MkLib.PSLib, TwgForm.FontColEx);
            finally
              FDrawerSkia.EndPrimitive;
            end;
          except
          end;
        end;

        Prog := Prog + 1;
        if (I mod 50) = 0 then
        begin
          SceneProgressSet(Prog);
        end;
      end;
      Error := 16;
    finally
     GlobalRender := False;
      for I := 0 to TwgForm.Twigs.TwigsCount - 1 do
      begin
        Tw := TwgForm.Twigs.TAt(I);
        Tw.isDraw := False;
      end;
    end;
  SceneDirty := False;
  BaseDx := Selector.GetDx;
  BaseDy := Selector.GetDy;
  BaseScale := Selector.GetScale;

  SceneProgressSet(Total);
  SceneProgressHide;
end;

procedure TMainFormSkia.BuildCachedPicture;
var
  Recorder: ISkPictureRecorder;
  RecCanvas: ISkCanvas;
  R: TRectF;
  PrevWorld: Boolean;
  Pad: Single;
begin
  if FBuildingScene then
    Exit;
  if FDrawerSkia = nil then
    Exit;
  if SkPainter = nil then
    Exit;
  if (SkPainter.Width <= 0) or (SkPainter.Height <= 0) then
    Exit;

  if (Selector <> nil) and (Selector.GlobalRect <> nil) and Selector.GlobalRect.isRect then
  begin
    R := TRectF.Create(Single(Selector.GlobalRect.XMin), Single(Selector.GlobalRect.YMin),
      Single(Selector.GlobalRect.XMax), Single(Selector.GlobalRect.YMax));
    Pad := 1000;
    R.Inflate(Pad, Pad);
  end
  else if (Selector <> nil) and (Selector.ActiveRect <> nil) and Selector.ActiveRect.isRect then
  begin
    R := TRectF.Create(Single(Selector.ActiveRect.XMin), Single(Selector.ActiveRect.YMin),
      Single(Selector.ActiveRect.XMax), Single(Selector.ActiveRect.YMax));
    Pad := 1000;
    R.Inflate(Pad, Pad);
  end
  else
    R := TRectF.Create(-10000000, -10000000, 10000000, 10000000);
  Recorder := TSkPictureRecorder.Create;
  RecCanvas := Recorder.BeginRecording(R);
  try
    FBuildingScene := True;
    PrevWorld := FDrawerSkia.UseWorldCoords;
    FDrawerSkia.UseWorldCoords := True;
    try
      FDrawerSkia.ClearSkiaList;
      FDrawerSkia.BeginFrame(RecCanvas, R);
      try
        if (TwgForm <> nil) and objectRepaintAccess then
          RenderSceneToBackbufferSkia;
      finally
        FDrawerSkia.EndFrame;
      end;
    finally
      FDrawerSkia.UseWorldCoords := PrevWorld;
    end;
  finally
    FBuildingScene := False;
    SceneProgressHide;
    FCachedPicture := Recorder.FinishRecording;
  end;
end;

procedure TMainFormSkia.CapturePanBitmap;
var
  D: TBitmapData;
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  C: ISkCanvas;
  ViewScale: Single;
  Tx, Ty: Single;
begin
  if FDrawerSkia = nil then
    Exit;
  if Selector = nil then
    Exit;
  if SkPainter = nil then
    Exit;

  if (FDrawerSkia.SkiaList.Count = 0) or SceneDirty then
    BuildCachedPicture;

  if PanBitmap = nil then
    PanBitmap := TBitmap.Create;

  PanBitmap.SetSize(Round(SkPainter.Width * LastCanvasScale), Round(SkPainter.Height * LastCanvasScale));
  if (PanBitmap.Width <= 0) or (PanBitmap.Height <= 0) then
    Exit;

  if not PanBitmap.Map(TMapAccess.ReadWrite, D) then
    Exit;
  try
    ImgInfo := TSkImageInfo.Create(PanBitmap.Width, PanBitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
    Surface := TSkSurface.MakeRasterDirect(ImgInfo, D.Data, D.Pitch);
    if Surface = nil then
      Exit;
    C := Surface.Canvas;
    if C = nil then
      Exit;

    C.Clear(TAlphaColors.White);

    ViewScale := Single(Selector.GetScale);
    if ViewScale > 0 then
    begin
      Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
      Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
      C.Save;
      try
        C.Translate(Tx, Ty);
        C.Scale(ViewScale, ViewScale);
        FDrawerSkia.DrawSkiaList(C);
      finally
        C.Restore;
      end;
    end;
  finally
    PanBitmap.Unmap(D);
  end;
end;

procedure TMainFormSkia.ResetInteractionState;
begin
  InteractionActive := False;
  PanActive := False;
  ZoomActive := False;
  LastZoomDistance := 0;
end;

procedure TMainFormSkia.FinalizeZoom;
var
  PivotPix: TPointF;
  NewScale: Double;
  OldScale: Double;
  PivotGeo: TPointF;
begin
  if Selector = nil then
    Exit;
  if not ZoomBitmapActive then
    Exit;
  if ZoomStartDistance <= 0 then
  begin
    ZoomBitmapActive := False;
    ZoomStartDistance := 0;
    ZoomFactor := 1;
    Exit;
  end;
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;
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

  PivotPix := PointF(ZoomPivot.X * LastCanvasScale, ZoomPivot.Y * LastCanvasScale);
  NewScale := OldScale * ZoomFactor;
  if NewScale = 0 then
    Exit;

  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));

  Selector.ActiveRect := ZoomBaseRect;
  Selector.Scale(PivotGeo.X, PivotGeo.Y, ZoomFactor);

  ZoomBitmapActive := False;
  ZoomStartDistance := 0;
  ZoomFactor := 1;
  ZoomActive := False;
  InteractionActive := False;
end;

procedure TMainFormSkia.SkPainterDblClick(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  InteractionActive := False;
  PanActive := False;
  LastZoomDistance := 0;
  BaseScale := 0;
  Selector.UpdateRects(True);
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Selector = nil then
    Exit;
  if ZoomBitmapActive or ZoomActive then
    Exit;
  UpdateStatusGeo(X, Y);
  PanActive := True;
  ZoomActive := False;
  LastZoomDistance := 0;
  InteractionActive := True;
  PanBitmapActive := False;
  if (not SceneDirty) and (FDrawerSkia <> nil) and (FDrawerSkia.SkiaList.Count > 0) then
  begin
    CapturePanBitmap;
    if (PanBitmap <> nil) and (PanBitmap.Width > 0) and (PanBitmap.Height > 0) then
    begin
      PanStartPoint := PointF(X, Y);
      PanShift := PointF(0, 0);
      PanBaseDx := Selector.GetDx;
      PanBaseDy := Selector.GetDy;
      PanBitmapActive := True;
    end;
  end;
  if BaseScale = 0 then
  begin
    BaseDx := Selector.GetDx;
    BaseDy := Selector.GetDy;
    BaseScale := Selector.GetScale;
  end;
  LastPanPoint := PointF(X, Y);
end;

procedure TMainFormSkia.SkPainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  DxPix, DyPix: Single;
  DxGeo, DyGeo: Double;
begin
  if Selector = nil then
    Exit;
  UpdateStatusGeo(X, Y);
  if ZoomActive then
    Exit;
  if not PanActive then
    Exit;
  if PanBitmapActive then
  begin
    PanShift := PointF(X - PanStartPoint.X, Y - PanStartPoint.Y);
    if SkPainter <> nil then
      SkPainter.Redraw;
    Exit;
  end;
  if Selector.GetScale = 0 then
    Exit;
  DxPix := (X - LastPanPoint.X) * LastCanvasScale;
  DyPix := (Y - LastPanPoint.Y) * LastCanvasScale;
  LastPanPoint := PointF(X, Y);
  DxGeo := DxPix / Selector.GetScale;
  DyGeo := DyPix / Selector.GetScale;
  Selector.Move(-DxGeo, -DyGeo);
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  DxPix, DyPix: Double;
  DxGeo, DyGeo: Double;
begin
 If Selector = nil then Exit;
  if ZoomBitmapActive and (Selector <> nil) then
    FinalizeZoom;
  if PanBitmapActive and (Selector <> nil)  then
   If (Selector.GetScale <> 0) then
   begin
    DxPix := PanShift.X * LastCanvasScale;
    DyPix := PanShift.Y * LastCanvasScale;
    DxGeo := DxPix / Selector.GetScale;
    DyGeo := DyPix / Selector.GetScale;
    Selector.Move(-DxGeo, -DyGeo);
  end;
  PanBitmapActive := False;
  ResetInteractionState;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterMouseLeave(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  if InteractionActive or PanActive or (LastZoomDistance <> 0) then
  begin
    ResetInteractionState;
    if SkPainter <> nil then
      SkPainter.Redraw;
  end;
end;

procedure TMainFormSkia.SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  P: TPoint;
  PF: TPointF;
begin
  if FDrawerSkia = nil then
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
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;
  PF := SkPainter.AbsoluteToLocal(Screen.MousePos);
  P := Point(Round(PF.X * LastCanvasScale), Round(PF.Y * LastCanvasScale));
  FDrawerSkia.MouseWheel(Sender, Shift, WheelDelta, P, Handled);
  InteractionActive := False;
  SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if FDrawerSkia = nil then
    Exit;
  if Selector = nil then
    Exit;
  PanBitmapActive := False;
  PanActive := False;
  Handled := True;
  InteractionActive := True;
  ZoomActive := True;
  PanActive := False;

  if EventInfo.Distance <= 0 then
  begin
    FinalizeZoom;
    ResetInteractionState;
    SkPainter.Redraw;
    Exit;
  end;

  if (not ZoomBitmapActive) and (ZoomStartDistance = 0) then
  begin
    ZoomStartDistance := EventInfo.Distance;
    ZoomFactor := 1;
    ZoomPivot := EventInfo.Location;
    if ZoomBaseRect = nil then
      ZoomBaseRect := TogsRect.Create;
    ZoomBaseRect.Assign(Selector.ActiveRect);
    ZoomBaseDx := Selector.GetDx;
    ZoomBaseDy := Selector.GetDy;
    ZoomBaseScale := Selector.GetScale;
    CapturePanBitmap;
    if (PanBitmap <> nil) and (PanBitmap.Width > 0) and (PanBitmap.Height > 0) then
      ZoomBitmapActive := True;
    Exit;
  end;

  if ZoomStartDistance <= 0 then
    Exit;
  ZoomFactor := EventInfo.Distance / ZoomStartDistance;
  if ZoomFactor < 0.05 then
    ZoomFactor := 0.05;
  if ZoomFactor > 20 then
    ZoomFactor := 20;
  SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  Pivot: TPointF;
  F: Single;
  DebugPaint: ISkPaint;
  DebugFont: ISkFont;
  DebugTypeface: ISkTypeface;
  Family: string;
  FontFile: string;
  I: Integer;
  ViewScale: Single;
  Tx, Ty: Single;
  D: TBitmapData;
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  Img: ISkImage;
  Paint: ISkPaint;
  DstRect: TRectF;
const
  DebugDirectSkia = false;
begin
  if FDrawerSkia = nil then
    Exit;
  if SkPainter <> nil then
    LastCanvasScale := SkPainter.AbsoluteScale.X
  else
    LastCanvasScale := 1;
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;

  if ACanvas <> nil then
    ACanvas.Clear(TAlphaColors.White);

  if DebugDirectSkia and (ACanvas <> nil) then
  begin
    DebugPaint := TSkPaint.Create;
    DebugPaint.AntiAlias := True;
    DebugPaint.Color := $FF202020;

    Family := 'Do431';
    FontFile := GetRegisteredSkiaFontFile(Family);
    DebugTypeface := nil;
    if FontFile <> '' then
      DebugTypeface := TSkTypeface.MakeFromFile(FontFile);
    if (DebugTypeface = nil) and (Family <> '') then
      DebugTypeface := TSkTypeface.MakeFromName(Family, TSkFontStyle.Normal);

    DebugFont := TSkFont.Create(DebugTypeface, 24);

    ACanvas.DrawSimpleText('Skia DebugDirectSkia: Do431 + XKoef + Angle', 20, 50, DebugFont, DebugPaint);

    DebugFont := TSkFont.Create(DebugTypeface, 18);
    ACanvas.Save;
    try
      ACanvas.Translate(20, 90);
      ACanvas.Scale(0.7, 1);
      ACanvas.DrawSimpleText('XKoef=0.7  1234567890', 0, 0, DebugFont, DebugPaint);
    finally
      ACanvas.Restore;
    end;

    ACanvas.Save;
    try
      ACanvas.Translate(20, 120);
      ACanvas.Scale(1.0, 1);
      ACanvas.DrawSimpleText('XKoef=1.0  1234567890', 0, 0, DebugFont, DebugPaint);
    finally
      ACanvas.Restore;
    end;

    ACanvas.Save;
    try
      ACanvas.Translate(20, 150);
      ACanvas.Scale(1.4, 1);
      ACanvas.DrawSimpleText('XKoef=1.4  1234567890', 0, 0, DebugFont, DebugPaint);
    finally
      ACanvas.Restore;
    end;

    ACanvas.Save;
    try
      ACanvas.Translate(420, 160);
      ACanvas.Rotate(30);
      ACanvas.Scale(1.2, 1);
      ACanvas.DrawSimpleText('Angle=30deg      Do431', 0, 0, DebugFont, DebugPaint);
    finally
      ACanvas.Restore;
    end;

    DebugFont := TSkFont.Create(DebugTypeface, 14);
    ACanvas.DrawSimpleText('Note: rotation uses canvas matrix (degrees).', 20, 210, DebugFont, DebugPaint);
    Exit;
  end;

  if PanBitmapActive and (PanBitmap <> nil) and (PanBitmap.Width > 0) and (PanBitmap.Height > 0) then
  begin
    if not PanBitmap.Map(TMapAccess.Read, D) then
      Exit;
    try
      ImgInfo := TSkImageInfo.Create(PanBitmap.Width, PanBitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
      Surface := TSkSurface.MakeRasterDirect(ImgInfo, D.Data, D.Pitch);
      if Surface = nil then
        Exit;
      Img := Surface.MakeImageSnapshot;
    finally
      PanBitmap.Unmap(D);
    end;
    if Img = nil then
      Exit;
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    DstRect := TRectF.Create(ADest.Left + PanShift.X, ADest.Top + PanShift.Y, ADest.Right + PanShift.X, ADest.Bottom + PanShift.Y);
    ACanvas.Save;
    try
      ACanvas.ClipRect(ADest, TSkClipOp.Intersect, True);
      ACanvas.DrawImageRect(Img, DstRect, Paint);
    finally
      ACanvas.Restore;
    end;
    Exit;
  end;

  if ZoomBitmapActive and (PanBitmap <> nil) and (PanBitmap.Width > 0) and (PanBitmap.Height > 0) then
  begin
    Pivot := ZoomPivot;
    F := ZoomFactor;
    if not PanBitmap.Map(TMapAccess.Read, D) then
      Exit;
    try
      ImgInfo := TSkImageInfo.Create(PanBitmap.Width, PanBitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
      Surface := TSkSurface.MakeRasterDirect(ImgInfo, D.Data, D.Pitch);
      if Surface = nil then
        Exit;
      Img := Surface.MakeImageSnapshot;
    finally
      PanBitmap.Unmap(D);
    end;
    if Img = nil then
      Exit;
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    DstRect := TRectF.Create(
      Pivot.X + (ADest.Left - Pivot.X) * F,
      Pivot.Y + (ADest.Top - Pivot.Y) * F,
      Pivot.X + (ADest.Right - Pivot.X) * F,
      Pivot.Y + (ADest.Bottom - Pivot.Y) * F);
    ACanvas.Save;
    try
      ACanvas.ClipRect(ADest, TSkClipOp.Intersect, True);
      ACanvas.DrawImageRect(Img, DstRect, Paint);
    finally
      ACanvas.Restore;
    end;
    Exit;
  end;

  if (FDrawerSkia.SkiaList.Count = 0) or SceneDirty then
    BuildCachedPicture;
  if (ACanvas <> nil) and (FDrawerSkia.SkiaList.Count > 0) and (Selector <> nil) then
  begin
    ViewScale := Single(Selector.GetScale);
    if ViewScale > 0 then
    begin
      Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
      Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
      ACanvas.Save;
      try
        ACanvas.Translate(Tx, Ty);
        ACanvas.Scale(ViewScale, ViewScale);
        FDrawerSkia.DrawSkiaList(ACanvas);
      finally
        ACanvas.Restore;
      end;
    end;
  end;
end;

end.
