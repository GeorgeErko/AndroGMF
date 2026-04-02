unit MainFrmSkia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.DialogService,
  MainFrm, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Objects, FMX.Skia, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  ogcBasic, ogcDrawerSkia, newSelector;

type
  TMainFormSkia = class(TMainForm)
    SkPainter: TSkPaintBox;
    Popup1: TPopup;
    btnPDF: TCornerButton;
    procedure FormCreate(Sender: TObject);
    procedure btnPaintClick(Sender: TObject);
    procedure upmClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
  private
    FStatusLabel: TLabel;
    FDrawerSkia: TogsDrawerSkia;
    FCachedPicture: ISkPicture;
    FBuildingScene: Boolean;
    FRebuildQueued: Boolean;
    PanBitmap: TBitmap;
    FPanImage: ISkImage;
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

    procedure RequestRebuildScene;

    procedure RenderSceneToBackbufferSkia;

    procedure OpenGmfFileSkia(const LocalPath: string);
    procedure btnOpenClickSkia(Sender: TObject);
    procedure btnLocalOpenClickSkia(Sender: TObject);
    procedure btnPaintClickSkia(Sender: TObject);
    procedure btnPlusClickSkia(Sender: TObject);

    procedure SkPainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);

    procedure ResetInteractionState;
    procedure FinalizeZoom;
    procedure SetSkPainterCapture(const ACapture: Boolean);
    procedure BuildCachedPicture;
    procedure CapturePanBitmap;
   //
    procedure DoExportPdfWithName(const AName: string);
   //
    procedure WheelZoomTimer(Sender: TObject);
  protected
    procedure Loaded; override;
    procedure SetSelectorParams; virtual;
  // события мыши
    procedure SkPainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
    procedure SkPainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single); virtual;
    procedure SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;
    procedure SkPainterMouseLeave(Sender: TObject);
    procedure SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); virtual;
    procedure SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure SkPainterDblClick(Sender: TObject);
  // рисование перед-после
    procedure PaintBefore(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;
    procedure PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;

    function InteractionBitmapActive: Boolean; virtual;
    procedure DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF); virtual;
    procedure UpdateScene(UpdateSceneMode: TUpdateSceneMode; Obj: TObject);
  protected
    procedure UpdateStatusGeo(const X, Y: Single);
  public
   MousePos: TPointF;
    destructor Destroy; override;
    procedure OpenGmfFile(const LocalPath: string); override;
    function ExportSceneToPdf(const AFileName: string = ''): string;
  end;

var
  MainFormSkia: TMainFormSkia;

implementation

uses Collect, uExecRegisterClass, System.IOUtils, Writer, newProcs, FMX.FontManager,
     EcText, EcDot, EcDot2, EcLot, RPrims, WPTwigs, DlgLocalOpen,
     WPTForm2, mpMarker, objMouse, drawTwigs, UpdateMessages, TwgDraw
{$IFDEF ANDROID}
     , OpenForm, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes
{$ENDIF}
     ;

type
  TBitmapAccess = class(TBitmap);

var
  WheelZoomTmr: TTimer;
  WheelZoomLastTick: UInt64;

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

function TMainFormSkia.ExportSceneToPdf(const AFileName: string): string;
var
  OutPath: string;
  Stream: TFileStream;
  Doc: ISkDocument;
  C: ISkCanvas;
  R: TRectF;
  Pad: Single;
  PageW: Single;
  PageH: Single;
  PrevWorld: Boolean;
  ScaleToPdf: Single;
const
  PointsPerInch = 72;
  CmPerInch = 2.54;
  PointsPerCm = PointsPerInch / CmPerInch;
  MetersPerCmAtScale = 5;
  WorldUnitsPerMeter = 1;
begin
  Result := '';
  if (Selector = nil) or (Selector.GlobalRect = nil) or (not Selector.GlobalRect.isRect) then
    Exit;
  if FDrawerSkia = nil then
    Exit;

  if (FDrawerSkia.SkiaList.Count = 0) or SceneDirty then
    BuildCachedPicture;
  if FDrawerSkia.SkiaList.Count = 0 then
    Exit;

  Pad := 10;
  R := TRectF.Create(
    Single(Selector.GlobalRect.XMin),
    Single(Selector.GlobalRect.YMin),
    Single(Selector.GlobalRect.XMax),
    Single(Selector.GlobalRect.YMax));
  if R.IsEmpty then
    Exit;
  R.Inflate(Pad, Pad);

  ScaleToPdf := (PointsPerCm / MetersPerCmAtScale) / WorldUnitsPerMeter;
  PageW := R.Width * ScaleToPdf;
  PageH := R.Height * ScaleToPdf;
  if PageW < 1 then
    PageW := 1;
  if PageH < 1 then
    PageH := 1;

  if AFileName <> '' then
    OutPath := AFileName
  else
    OutPath := TPath.Combine(TPath.GetDocumentsPath, 'scene.pdf');
  if ExtractFileExt(OutPath) = '' then
    OutPath := OutPath + '.pdf';

  Stream := TFileStream.Create(OutPath, fmCreate);
  try
    Doc := TSkDocument.MakePDF(Stream);
    if Doc = nil then
      Exit;
    C := Doc.BeginPage(PageW, PageH);
    try
      if C <> nil then
      begin
        C.Clear(TAlphaColors.White);
        C.Save;
        try
          C.Scale(ScaleToPdf, ScaleToPdf);
          C.Translate(-R.Left, -R.Top);
          PrevWorld := FDrawerSkia.UseWorldCoords;
          FDrawerSkia.UseWorldCoords := True;
          try
            FDrawerSkia.DrawSkiaList(C);
          finally
            FDrawerSkia.UseWorldCoords := PrevWorld;
          end;
        finally
          C.Restore;
        end;
      end;
    finally
      Doc.EndPage;
      Doc.Close;
    end;
  finally
    Stream.Free;
  end;

  Result := OutPath;
end;

procedure TMainFormSkia.FormCreate(Sender: TObject);
begin
//
  LastCanvasScale := 1;

  FBuildingScene := False;

  PanBitmap := nil;
  FPanImage := nil;
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
  if btnOpen <> nil then
    btnOpen.OnClick := btnOpenClickSkia;
  if btnPDF <> nil then
    btnPDF.OnClick := btnPDFClick;

  InitSkPainterInput;

  if WheelZoomTmr = nil then
  begin
    WheelZoomTmr := TTimer.Create(nil);
    WheelZoomTmr.Enabled := False;
    WheelZoomTmr.Interval := 200;
    WheelZoomTmr.OnTimer := WheelZoomTimer;
  end;
end;

procedure TMainFormSkia.btnPDFClick(Sender: TObject);
var
  DefaultName: string;
begin
  DefaultName := '/scene.pdf';

{$IFDEF ANDROID}
  TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
  TDialogService.InputQuery('Export PDF', ['File name (Documents)'], [DefaultName],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if AResult <> mrOk then
        Exit;
      if Length(AValues) < 1 then
        Exit;
      DoExportPdfWithName(AValues[0]);
    end);
{$ELSE}
  if InputQuery('Export PDF', 'File name (Documents)', DefaultName) then
    DoExportPdfWithName(DefaultName);
{$ENDIF}
end;

procedure TMainFormSkia.DoExportPdfWithName(const AName: string);
var
  FileName: string;
  FullPath: string;
  SavedPath: string;
  BaseDir: string;
begin
  FileName := Trim(AName);
  if FileName = '' then
    Exit;
  while (FileName <> '') and ((FileName[Low(string)] = '/') or (FileName[Low(string)] = '\\')) do
    Delete(FileName, Low(string), 1);
  FileName := StringReplace(FileName, '/', '_', [rfReplaceAll]);
  FileName := StringReplace(FileName, '\\', '_', [rfReplaceAll]);
  if ExtractFileExt(FileName) = '' then
    FileName := FileName + '.pdf';

{$IFDEF ANDROID}
  BaseDir := '';
  try
    BaseDir := JStringToString(
      TJEnvironment.JavaClass.getExternalStoragePublicDirectory(
        TJEnvironment.JavaClass.DIRECTORY_DOWNLOADS).getAbsolutePath);
  except
    BaseDir := '';
  end;
  if (BaseDir <> '') and (BaseDir[Low(string)] <> '/') then
    BaseDir := '/' + BaseDir;
  if BaseDir = '' then
    BaseDir := TPath.GetDocumentsPath;
{$ELSE}
  BaseDir := TPath.GetDocumentsPath;
{$ENDIF}

  FullPath := TPath.Combine(BaseDir, FileName);
  try
    SavedPath := ExportSceneToPdf(FullPath);
    if SavedPath <> '' then
      newProcs.ShowMessage(AnsiString('Saved: ' + FullPath))
    else
      newProcs.MessageError('PDF export failed');
  except
    on E: Exception do
      newProcs.MessageError(AnsiString(E.Message));
  end;
end;


procedure TMainFormSkia.RequestRebuildScene;
var
  Total: Single;
begin
  if FRebuildQueued then
    Exit;
  if FBuildingScene then
    Exit;
  if (FDrawerSkia = nil) or (Selector = nil) or (SkPainter = nil) then
    Exit;
  if (SkPainter.Width <= 0) or (SkPainter.Height <= 0) then
    Exit;

  Total := 1;
  if TwgForm <> nil then
    Total := TwgForm.Twigs.LotsCount + TwgForm.Twigs.AnyCount;
  if Total < 1 then
    Total := 1;

  FRebuildQueued := True;
  TThread.Queue(nil,
    procedure
    begin
      try
        BuildCachedPicture;
        CapturePanBitmap;
      finally
        FRebuildQueued := False;
        if SkPainter <> nil then
          SkPainter.Redraw;
      end;
    end);
end;

procedure TMainFormSkia.Loaded;
begin
  inherited;
end;

destructor TMainFormSkia.Destroy;
begin
 WriteIn(['Skia1']);
  FDrawerSkia.Free;
  FDrawerSkia := nil;
  FreeAndNil(TwgForm);
   WriteIn(['Skia2']);
  inherited Destroy;
end;

procedure TMainFormSkia.WheelZoomTimer(Sender: TObject);
const TimeforZoom = 100;
begin
  if (WheelZoomLastTick = 0) or ((TThread.GetTickCount64 - WheelZoomLastTick) < TimeForZoom) then
    Exit;

  if WheelZoomTmr <> nil then
    WheelZoomTmr.Enabled := False;

  if ZoomBitmapActive and (Selector <> nil) then
  begin
    SetSkPainterCapture(False);
    FinalizeZoom;
    ResetInteractionState;
    if SkPainter <> nil then
      SkPainter.Redraw;
  end;
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
    PP: TPointDot;
    B: Byte;
  begin
    for I := 1 to TwgForm.Twigs.TwigsCount - 1 do
    begin
      Twig := TwgForm.Twigs.TAt(I);
      for J := 0 to Twig.Coord.Count - 1 do
        Selector.AddCoord(Twig[J].XDot, Twig[J].YDot);
    end;
    for I := 0 to TwgForm.Twigs.AnyCount - 1 do
    begin
      PP := TwgForm.Twigs.AAt(I, B);
      Selector.AddCoord(PP.XDot, PP.YDot);
    end;
  end;

begin
  if FDrawerSkia = nil then
  begin
    FDrawerSkia := TogsDrawerSkia.Create(nil, nil, SkPainter);
    Selector := TSelector.Create(FDrawerSkia);
    FDrawerSkia.ogsSelector := Selector;
    FDrawerSkia.Name := 'DrawerSkia';
    Selector.Name := 'Selector';
    UpdateMessage:=TUpdateMessage.Create(nil);
  end else
    Selector.Clear;

  Memo1.Lines.Clear;
  FormCreate(Self);
 // InitSkPainterInput;
  {$IFDEF WIN64}
   GLines := nil;
   newProcs.MainPath := TPath.GetLibraryPath;
  {$ELSE}
   GLines := Memo1.Lines;
  newProcs.MainPath := TPath.GetDocumentsPath;
  {$ENDIF}
  WriteIn(['Test1', MainPath]);
  RegPrimitives;
  WriteIn(['Registered']);
  objectRepaintAccess := False;
  Path := LocalPath;
  WriteIn(['Path=', LocalPath]);
  if LocalPath = '' then
  begin
    WriteIn(['Path Space']);
    Exit;
  end;
  WriteIn(['Path=', ExtractFilePath(LocalPath), MainPath, SizeOf(Single), SizeOf(Double)]);

  RegisterFontsNearGmf(LocalPath);

  Stream := TBufStream.InitFileStream(LocalPath, fmOpenRead);
  Selector.GNForm := TControl(skPainter);
  WriteIn(['s.Drawer=', Selector.Drawer = nil]);
  ApplicationMainForm := Self;
  Stream.Selector := Selector;
  try
    FreeAndNil(TwgForm);
   //
    TwgForm := TForm2(Stream.Get);
    Selector.GLineCol := TwgForm.MkLib.LSLib;
    Selector.GSqwearCol := TwgForm.MkLib.SSLib;
    Selector.GPointCol := TwgForm.MkLib.PSLib;
    Selector.GFontCollect := TwgForm.Twigs.FontS;
    Selector.GFontSet := TwgForm.Twigs.FontSet;
    Selector.GGraphSet := TwgForm.fGraphSet;
    SetSelectorParams;
    if TwgForm.FontColEx <> nil then
    begin
      for I := 0 to TwgForm.Twigs.AnyCount - 1 do
      begin
        PP := TwgForm.Twigs.AAt(I, B);
        PP.ResetParams(param_idResetFontView, TwgForm.FontColEx);
      end;
    end;
    localSetGabarites;

    if SkPainter <> nil then
      LastCanvasScale := SkPainter.AbsoluteScale.X
    else
      LastCanvasScale := 1;
    if LastCanvasScale <= 0 then
      LastCanvasScale := 1;
    if FDrawerSkia <> nil then
    begin
      FDrawerSkia.Width := Round(SkPainter.Width * LastCanvasScale);
      FDrawerSkia.Height := Round(SkPainter.Height * LastCanvasScale);
    end;

    Selector.UpdateRects(True);
    objectRepaintAccess := True;
    WriteIn(['TwgForm=', TwgForm.Twigs.TwigsCount, TwgForm.Twigs.LotsCount, TwgForm.Twigs.AnyCount]);
    WriteIn(['Sel.Rect=', Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
  finally
    Stream.Free;
  end;

  InitSkPainterInput;

  SceneDirty := True;
  GlobalRender := True;
//  if SkPainter <> nil then
 //   SkPainter.Redraw;
  SkPainterDblClick(nil);
  btnPaintClick(nil);
end;

procedure TMainFormSkia.btnOpenClickSkia(Sender: TObject);
begin
 {$IFDEF ANDROID}
 PickGmfFile(OpenGmfFile);
{$ELSE}
 PickGmfFileWin64;
{$ENDIF}
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
  CenterLocal: TPointF;
  Handled: Boolean;
  WheelDelta: Integer;
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

  CenterLocal := PointF(SkPainter.Width * 0.5, SkPainter.Height * 0.5);
  MousePos := CenterLocal;

  WheelDelta := 120;
  if (Btn <> nil) and (Btn.Tag < 0) then
    WheelDelta := -WheelDelta;

  Handled := False;
  SkPainterMouseWheel(SkPainter, [], WheelDelta, Handled);

  WheelZoomLastTick := TThread.GetTickCount64 - 1000;
  WheelZoomTimer(nil);
end;

procedure TMainFormSkia.UpdateScene(UpdateSceneMode: TUpdateSceneMode; Obj: TObject);
var
 DrawIndex, I: Integer;
 B: Byte;
 PP: Pointer;
 Lot: TLot;
 PPoint: TPointDot;
 SceneRect: TRectF;
 DummyRecorder: ISkPictureRecorder;
 DummyCanvas: ISkCanvas;
 PrevWorld: Boolean;
 AddedObj: TogsSkiaObject;
 SkObj: TObject;
begin
 if (FDrawerSkia = nil) or (Selector = nil) or (TwgForm = nil) or (Obj = nil) then Exit;

 case UpdateSceneMode of
  usmDelete:
   if Obj is TTD then
   begin
    SkObj := TTD(Obj).DrawerObject;
    if (SkObj is TogsSkiaObject) and (FDrawerSkia.SkiaList <> nil) then
    begin
     FDrawerSkia.SkiaList.Remove(TogsSkiaObject(SkObj));
     TTD(Obj).DrawerObject := nil;
     SceneDirty := True;
     BuildCachedPicture;
     ResetInteractionState;
     PanShift := PointF(0, 0);
     BaseScale := 0;
     FPanImage := nil;
     if SkPainter <> nil then SkPainter.Redraw;
    end;
   end;

  usmModify:
   begin
    UpdateScene(usmDelete, Obj);
    UpdateScene(usmAdd, Obj);
   end;

  usmAdd:
   begin
    if (Obj is TTD) and (TTD(Obj).DrawerObject <> nil) then Exit;

    if (Selector.GlobalRect <> nil) and Selector.GlobalRect.isRect then
     SceneRect := TRectF.Create(Single(Selector.GlobalRect.XMin - 1000), Single(Selector.GlobalRect.YMin - 1000),
       Single(Selector.GlobalRect.XMax + 1000), Single(Selector.GlobalRect.YMax + 1000))
    else if (Selector.ActiveRect <> nil) and Selector.ActiveRect.isRect then
     SceneRect := TRectF.Create(Single(Selector.ActiveRect.XMin - 1000), Single(Selector.ActiveRect.YMin - 1000),
       Single(Selector.ActiveRect.XMax + 1000), Single(Selector.ActiveRect.YMax + 1000))
    else
     SceneRect := TRectF.Create(-10000000, -10000000, 10000000, 10000000);

    DummyRecorder := TSkPictureRecorder.Create;
    DummyCanvas := DummyRecorder.BeginRecording(SceneRect);
    PrevWorld := FDrawerSkia.UseWorldCoords;
    FDrawerSkia.UseWorldCoords := True;
    FDrawerSkia.BeginFrame(DummyCanvas, SceneRect);
    try
     AddedObj := nil;
     DrawIndex := 0;
     with Selector, GGraphset do
     begin
      if FillLot = 1 then
       for I := 0 to TwgForm.Twigs.LotsCount - 1 do
       begin
        Lot := TwgForm.Twigs.LAt(I);
        if (Lot.TypeLot = 254) or (Lot.Closed <> 1) then Continue;
        if Lot = Obj then
        begin
         Lot.Selector := Self.Selector;
         FDrawerSkia.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
         try Lot.Draw32(TwgForm.Twigs); finally FDrawerSkia.EndPrimitive; end;
         AddedObj := TogsSkiaObject(Lot.DrawerObject);
         Break;
        end;
        Inc(DrawIndex);
       end;

      if AddedObj = nil then
       for I := 0 to TwgForm.Twigs.AnyCount - 1 do
       begin
        PP := TwgForm.Twigs.AAt(I, B);
        if B <> TWG_Point then Continue;
        PPoint := PP;
        if PPoint.Closed then Continue;
        if PPoint = Obj then begin
         PPoint.Selector := Self.Selector;
         FDrawerSkia.BeginPrimitive(Int64(NativeInt(PPoint)), PPoint);
         try PPoint.Draw32(FDrawerSkia, TwgForm.MkLib.PSLib, TwgForm.FontColEx); finally FDrawerSkia.EndPrimitive; end;
         AddedObj := TogsSkiaObject(PPoint.DrawerObject);
         Break;
        end;
        Inc(DrawIndex);
       end;
     end;

     if (AddedObj <> nil) and (FDrawerSkia.SkiaList <> nil) then
     begin
      if FDrawerSkia.SkiaList.IndexOf(AddedObj) >= 0 then
      begin
       SceneDirty := True;
       BuildCachedPicture;
       ResetInteractionState;
       PanShift := PointF(0, 0);
       BaseScale := 0;
       FPanImage := nil;
       if SkPainter <> nil then SkPainter.Redraw;
      end;
     end;
    finally
     FDrawerSkia.EndFrame;
     FDrawerSkia.UseWorldCoords := PrevWorld;
     DummyRecorder.FinishRecording;
    end;
   end;
 end;
end;

procedure TMainFormSkia.UpdateStatusGeo(const X, Y: Single);
var
  XPix, YPix, XGeo, YGeo: Double;
  S: string;
begin
  if StatusBar = nil then
    Exit;
  if Selector = nil then
    Exit;
  if Selector.GetScale = 0 then
    Exit;
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
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
 //
  with Selector, GGraphset do
    try
     for I := 0 to TwgForm.Twigs.TwigsCount - 1 do
      begin
       Tw := TwgForm.Twigs.TAt(I);
       Tw.isVis := False;
      end;
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
end;

procedure TMainFormSkia.BuildCachedPicture;
var
  Recorder: ISkPictureRecorder;
  RecCanvas: ISkCanvas;
  R: TRectF;
  PrevWorld: Boolean;
  Pad: Single;
  T0, Dt: UInt64;
begin
  T0 := TThread.GetTickCount64;
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
        begin
          RenderSceneToBackbufferSkia;
          FDrawerSkia.DrawSkiaList(RecCanvas);
        end;
      finally
        FDrawerSkia.EndFrame;
      end;
    finally
      FDrawerSkia.UseWorldCoords := PrevWorld;
    end;
  finally
    FBuildingScene := False;
   // SceneProgressHide;
    FCachedPicture := Recorder.FinishRecording;
    if FCachedPicture <> nil then
      SceneDirty := False;

    Dt := TThread.GetTickCount64 - T0;
    if Dt > 30 then
      WriteIn(['BuildCachedPicture ms=', Dt, ' ObjCnt=', FDrawerSkia.SkiaList.Count]);
  end;
end;

procedure TMainFormSkia.CapturePanBitmap;
var
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  C: ISkCanvas;
  ViewScale: Single;
  Tx, Ty: Single;
  W, H: Integer;
  BaseXMin: Double;
  BaseYMin: Double;
begin
  if FDrawerSkia = nil then
    Exit;
  if Selector = nil then
    Exit;
  if SkPainter = nil then
    Exit;

  if (FDrawerSkia.SkiaList.Count = 0) or SceneDirty then
    BuildCachedPicture;

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

  C.Clear(TAlphaColors.White);

  ViewScale := Single(Selector.GetScale);
  if ViewScale <= 0 then
  begin
    Selector.UpdateRects(True);
    ViewScale := Single(Selector.GetScale);
  end;
  if ViewScale <= 0 then
    ViewScale := 1;

  if (Selector.GlobalRect <> nil) then
  begin
    BaseXMin := Selector.GlobalRect.XMin;
    BaseYMin := Selector.GlobalRect.YMin;
  end
  else if (Selector.ActiveRect <> nil) then
  begin
    BaseXMin := Selector.ActiveRect.XMin;
    BaseYMin := Selector.ActiveRect.YMin;
  end
  else
  begin
    BaseXMin := 0;
    BaseYMin := 0;
  end;

  if ViewScale > 0 then
  begin
    Tx := -Single(BaseXMin + Selector.GetDx) * ViewScale;
    Ty := -Single(BaseYMin + Selector.GetDy) * ViewScale;
    C.Save;
    try
      C.Translate(Tx, Ty);
      C.Scale(ViewScale, ViewScale);
      if FCachedPicture <> nil then
        C.DrawPicture(FCachedPicture)
      else
        FDrawerSkia.DrawSkiaList(C);
    finally
      C.Restore;
    end;
  end;

  Surface.Flush;
  FPanImage := Surface.MakeImageSnapshot;
end;

procedure TMainFormSkia.ResetInteractionState;
begin
  InteractionActive := False;
  PanActive := False;
  ZoomActive := False;
  PanBitmapActive := False;
  ZoomBitmapActive := False;
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

  CapturePanBitmap;
end;

procedure TMainFormSkia.SetSelectorParams;
begin
 Selector.OnUpdateScene := UpdateScene;
end;

procedure TMainFormSkia.SetSkPainterCapture(const ACapture: Boolean);
begin
  // no-op: this FMX version does not expose a compatible capture API for TSkPaintBox
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
    if FPanImage = nil then
      CapturePanBitmap;
    if (FPanImage <> nil) then
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
 MousePos := PointF(X, Y);
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

  CapturePanBitmap;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterMouseLeave(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  if InteractionActive or PanActive or (LastZoomDistance <> 0) or PanBitmapActive or ZoomBitmapActive then
  begin
    ResetInteractionState;
    if SkPainter <> nil then
      SkPainter.Redraw;
  end;
end;

procedure TMainFormSkia.SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  PF: TPointF;
  Step: Single;
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
  Handled := True;

  PF := MousePos;

  ZoomPivot := PF;
  ZoomActive := True;
  InteractionActive := True;

  if not ZoomBitmapActive then
  begin
    SetSkPainterCapture(True);
    ZoomStartDistance := 100;
    LastZoomDistance := 100;
    ZoomFactor := 1;
    if ZoomBaseRect = nil then
      ZoomBaseRect := TogsRect.Create;
    ZoomBaseRect.Assign(Selector.ActiveRect);
    ZoomBaseDx := Selector.GetDx;
    ZoomBaseDy := Selector.GetDy;
    ZoomBaseScale := Selector.GetScale;
    if FPanImage = nil then
      CapturePanBitmap;
    if FPanImage <> nil then
      ZoomBitmapActive := True;
  end;

  if WheelDelta > 0 then
    Step := 1.15
  else
    Step := 1 / 1.15;

  ZoomFactor := ZoomFactor * Step;
  if ZoomFactor < 0.05 then
    ZoomFactor := 0.05;
  if ZoomFactor > 20 then
    ZoomFactor := 20;

  WheelZoomLastTick := TThread.GetTickCount64;
  if WheelZoomTmr <> nil then
    WheelZoomTmr.Enabled := True;

  InteractionActive := False;
  SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  StepRatio: Single;
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

  if (EventInfo.Distance <= 0) or (EventInfo.Distance < 2) then
  begin
    SetSkPainterCapture(False);
    FinalizeZoom;
    ZoomPivot := EventInfo.Location;
    if ZoomBaseRect = nil then
      ZoomBaseRect := TogsRect.Create;
    ZoomBaseRect.Assign(Selector.ActiveRect);
    ZoomBaseDx := Selector.GetDx;
    ZoomBaseDy := Selector.GetDy;
    ZoomBaseScale := Selector.GetScale;
    if FPanImage = nil then
      CapturePanBitmap;
    if (FPanImage <> nil) then
      ZoomBitmapActive := True;
    Exit;
  end;

  if ZoomStartDistance <= 0 then
    Exit;

  if LastZoomDistance > 0 then
  begin
    StepRatio := EventInfo.Distance / LastZoomDistance;
    if (StepRatio > 1.8) or (StepRatio < (1 / 1.8)) then
    begin
      LastZoomDistance := EventInfo.Distance;
      Exit;
    end;
  end;
  LastZoomDistance := EventInfo.Distance;

  ZoomFactor := EventInfo.Distance / ZoomStartDistance;
  if ZoomFactor < 0.05 then
    ZoomFactor := 0.05;
  if ZoomFactor > 20 then
    ZoomFactor := 20;
  SkPainter.Redraw;
end;


procedure TMainFormSkia.PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
//
end;

procedure TMainFormSkia.PaintBefore(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
//
end;

function TMainFormSkia.InteractionBitmapActive: Boolean;
begin
 Result := PanBitmapActive or ZoomBitmapActive;
end;

procedure TMainFormSkia.DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF);
begin
//
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
  Img: ISkImage;
  Paint: ISkPaint;
  DstRect: TRectF;
  Pic: ISkPicture;
  T0, Dt: UInt64;
const
  DebugDirectSkia = false;
begin
  T0 := TThread.GetTickCount64;
  try
    if FDrawerSkia = nil then Exit;
    if SkPainter <> nil then
      LastCanvasScale := SkPainter.AbsoluteScale.X
    else
      LastCanvasScale := 1;
    if LastCanvasScale <= 0 then LastCanvasScale := 1;
    if ACanvas <> nil then ACanvas.Clear(TAlphaColors.White);

    if not InteractionBitmapActive then PaintBefore(ACanvas, ADest);

    if PanBitmapActive and (FPanImage <> nil) then
    begin
      Img := FPanImage;
      Paint := TSkPaint.Create;
      Paint.AntiAlias := True;
      DstRect := TRectF.Create(ADest.Left + PanShift.X, ADest.Top + PanShift.Y, ADest.Right + PanShift.X, ADest.Bottom + PanShift.Y);
      ACanvas.Save;
      try
        ACanvas.ClipRect(ADest, TSkClipOp.Intersect, True);
        ACanvas.DrawImageRect(Img, DstRect, Paint);
        DrawInteractionOverlay(ACanvas, ADest, DstRect);
      finally
        ACanvas.Restore;
      end;
      Exit;
    end;

    if ZoomBitmapActive and (FPanImage <> nil) then
    begin
      Pivot := ZoomPivot;
      F := ZoomFactor;
      Img := FPanImage;
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
        DrawInteractionOverlay(ACanvas, ADest, DstRect);
      finally
        ACanvas.Restore;
      end;
      Exit;
    end;

    if (FDrawerSkia.SkiaList.Count = 0) or SceneDirty then
    begin
      RequestRebuildScene;
      if (FPanImage <> nil) then
      begin
        Paint := TSkPaint.Create;
        Paint.AntiAlias := True;
        ACanvas.DrawImageRect(FPanImage, ADest, Paint);
      end;
      PaintBefore(ACanvas, ADest);
      Exit;
    end;

    if (FCachedPicture = nil) then
    begin
      SceneDirty := True;
      RequestRebuildScene;
      if (FPanImage <> nil) then
      begin
        Paint := TSkPaint.Create;
        Paint.AntiAlias := True;
        ACanvas.DrawImageRect(FPanImage, ADest, Paint);
      end;
      PaintBefore(ACanvas, ADest);
      Exit;
    end;

    Pic := FCachedPicture;
    if (Pic <> nil) and (Selector <> nil) then
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
          ACanvas.DrawPicture(Pic);
        finally
          ACanvas.Restore;
        end;
      end;
      Exit;
    end;

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
  finally
    Dt := TThread.GetTickCount64 - T0;
    if Dt > 15 then
      WriteIn(['SkPainterDraw ms=', Dt, ' PanBmp=', PanBitmapActive, ' ZoomBmp=', ZoomBitmapActive, ' SceneDirty=', SceneDirty]);
  end;
end;

end.
