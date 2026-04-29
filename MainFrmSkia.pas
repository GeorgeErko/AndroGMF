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
    FOverlayStaticImage: ISkImage;
    FOverlayLiveImage: ISkImage;
    FOverlayStaticDirty: Boolean;
    FOverlayLiveDirty: Boolean;
    FLastDestW: Single;
    FLastDestH: Single;
    FLastAbsScale: Single;
    FLastMiddleDownTick: UInt64;
    FLastMiddleDownPos: TPointF;
    PanActive: Boolean;
    LastPanPoint: TPointF;
    LastZoomDistance: Single;
    ZoomActive: Boolean;
    InteractionActive: Boolean;
    BaseDx, BaseDy, BaseScale: Double;

    procedure InitSkPainterInput;

    procedure SkPainterResize(Sender: TObject);

    procedure RequestRebuildScene;

    procedure RenderSceneToBackbufferSkia;

    procedure OpenGmfFileSkia(const LocalPath: string);
    procedure btnOpenClickSkia(Sender: TObject);
    procedure btnLocalOpenClickSkia(Sender: TObject);
    procedure btnPaintClickSkia(Sender: TObject);
    procedure btnPlusClickSkia(Sender: TObject);

    procedure SkPainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);

    procedure ResetInteractionState;
    procedure BuildCachedPicture;
    procedure BuildCachedPictureFromList;
   //
    procedure DoExportPdfWithName(const AName: string);
   //
    procedure WheelZoomTimer(Sender: TObject);
    procedure EnsureOverlayImages;
    function BuildOverlayImage(const AIsStatic: Boolean): ISkImage;
    procedure DoInvalidateOverlayLive;
    procedure DoInvalidateOverlayStatic;
    procedure ClearOverlayAllCaches;
  protected
    procedure Loaded; override;
    procedure SetSelectorParams; virtual;
    procedure InvalidateOverlayStatic;
    procedure InvalidateOverlayLive;
    procedure InvalidateOverlayAll;
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
    procedure PaintOverlayStatic(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;
    procedure PaintOverlayLive(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;

    function InteractionBitmapActive: Boolean; virtual;
    procedure DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF); virtual;
    procedure UpdateScene(UpdateSceneMode: TUpdateSceneMode; Obj: TObject);
  protected
    procedure UpdateStatusGeo(const X, Y: Single; Hint: String);
  public
   MousePos: TPointF;
    destructor Destroy; override;
    procedure OpenGmfFile(const LocalPath: string); override;
    function ExportSceneToPdf(const AFileName: string = ''): string;

    procedure InvalidateCachedPictureOnly;
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

function Iff(const ACond: Boolean; const ATrue, AFalse: Integer): Integer;
begin
  if ACond then
    Result := ATrue
  else
    Result := AFalse;
end;

var
  WheelZoomTmr: TTimer;
  WheelZoomLastTick: UInt64;

{$R *.fmx}

procedure TMainFormSkia.InitSkPainterInput;
begin
  if SkPainter = nil then
    Exit;
  SkPainter.AutoCapture := True;
  SkPainter.OnResize := SkPainterResize;
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

procedure TMainFormSkia.SkPainterResize(Sender: TObject);
var
  R: TogsRect;
begin
  if (FDrawerSkia = nil) or (Selector = nil) or (SkPainter = nil) then
    Exit;
  if (SkPainter.Width <= 0) or (SkPainter.Height <= 0) then
    Exit;

  LastCanvasScale := SkPainter.AbsoluteScale.X;
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;

  FDrawerSkia.Width := Round(SkPainter.Width * LastCanvasScale);
  FDrawerSkia.Height := Round(SkPainter.Height * LastCanvasScale);

  R := TogsRect.Create;
  try
    R.Assign(Selector.ActiveRect);
    Selector.ActiveRect := R;
  finally
    R.Free;
  end;

  Selector.UpdateRects(False);
  if SkPainter <> nil then
    SkPainter.Redraw;
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

  FLastDestW := 0;
  FLastDestH := 0;
  FLastAbsScale := 0;

  FBuildingScene := False;

  PanActive := False;
  ZoomActive := False;
  InteractionActive := False;
  BaseDx := 0;
  BaseDy := 0;

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
  WriteIn(['RequestRebuildScene enter', ' Q=', FRebuildQueued, ' Building=', FBuildingScene, ' Dirty=', SceneDirty]);
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
        WriteIn(['RequestRebuildScene queued begin', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', FDrawerSkia.SkiaList.Count]);
        BuildCachedPicture;
      finally
        FRebuildQueued := False;
        if SkPainter <> nil then
        begin
          WriteIn(['RequestRebuildScene queued end', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', FDrawerSkia.SkiaList.Count]);
          SkPainter.Redraw;
          SkPainter.Repaint;
        end;
      end;
    end);
end;

procedure TMainFormSkia.Loaded;
begin
  inherited;
end;

destructor TMainFormSkia.Destroy;
begin
  FDrawerSkia.Free;
  FDrawerSkia := nil;
  FreeAndNil(TwgForm);
  inherited Destroy;
end;

procedure TMainFormSkia.WheelZoomTimer(Sender: TObject);
const TimeforZoom = 100;
begin
  if (WheelZoomLastTick = 0) or ((TThread.GetTickCount64 - WheelZoomLastTick) < TimeForZoom) then
    Exit;

  if WheelZoomTmr <> nil then
    WheelZoomTmr.Enabled := False;
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
          TF := TSkTypeface.MakeFromFile(F);
           if TF <> nil then
            begin
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

  FDrawerSkia.DebugDrawTextBounds := False;

  Memo1.Lines.Clear;
  FormCreate(Self);
 // InitSkPainterInput;
  {$IFDEF WIN64}
   GLines := nil;
   newProcs.MainPath := TPath.GetLibraryPath;
  {$ELSE}
   GLines := Memo1.Lines;
   newProcs.MainPath := ExtractFilePath(LocalPath);//TPath.GetDocumentsPath;
  {$ENDIF}
  RegPrimitives;
  objectRepaintAccess := False;
  Path := LocalPath;
  if LocalPath = '' then
  begin
    Exit;
  end;

  RegisterFontsNearGmf(LocalPath);

  Stream := TBufStream.InitFileStream(LocalPath, fmOpenRead);
  Selector.GNForm := TControl(skPainter);
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

    SceneDirty := True;
    BuildCachedPicture;
  finally
    Stream.Free;
  end;

  InitSkPainterInput;
  SkPainterResize(SkPainter);

  SceneDirty := (FCachedPicture = nil);
  GlobalRender := False;
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
  WriteIn(['btnPaintClick', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1)]);
  SkPainter.Redraw;
  SkPainter.Repaint;
end;

procedure TMainFormSkia.btnPaintClickSkia(Sender: TObject);
begin
  SceneDirty := True;
  if SkPainter <> nil then
  begin
    WriteIn(['btnPaintClickSkia', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1)]);
    SkPainter.Redraw;
    SkPainter.Repaint;
  end;
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
     BaseScale := 0;
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
       BaseScale := 0;
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

procedure TMainFormSkia.UpdateStatusGeo(const X, Y: Single; Hint: String);
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
    FStatusLabel.Text := S + ' '+Hint;
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
              if (Lot.TypeLot <> 254) {and (Lot.Closed = 1)} then
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
         // if PPoint.Closed then
         //   Continue;
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
  WriteIn(['BuildCachedPicture enter', ' Dirty=', SceneDirty, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1), ' ORA=', objectRepaintAccess]);
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
    WriteIn(['BuildCachedPicture exit', ' ms=', Dt, ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1)]);
  end;
end;

procedure TMainFormSkia.BuildCachedPictureFromList;
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

  if (FDrawerSkia.SkiaList = nil) or (FDrawerSkia.SkiaList.Count = 0) then
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
      FDrawerSkia.BeginFrame(RecCanvas, R);
      try
        FDrawerSkia.DrawSkiaList(RecCanvas);
      finally
        FDrawerSkia.EndFrame;
      end;
    finally
      FDrawerSkia.UseWorldCoords := PrevWorld;
    end;
  finally
    FBuildingScene := False;
    FCachedPicture := Recorder.FinishRecording;
  end;
end;

procedure TMainFormSkia.InvalidateCachedPictureOnly;
begin
  FCachedPicture := nil;
end;

procedure TMainFormSkia.ResetInteractionState;
begin
  InteractionActive := False;
  PanActive := False;
  ZoomActive := False;
  LastZoomDistance := 0;
end;

procedure TMainFormSkia.InvalidateOverlayStatic;
begin
  FOverlayStaticDirty := True;
end;

procedure TMainFormSkia.InvalidateOverlayLive;
begin
  FOverlayLiveDirty := True;
end;

procedure TMainFormSkia.InvalidateOverlayAll;
begin
  FOverlayStaticDirty := True;
  FOverlayLiveDirty := True;
end;

procedure TMainFormSkia.ClearOverlayAllCaches;
begin
  FOverlayStaticImage := nil;
  FOverlayLiveImage := nil;
  InvalidateOverlayAll;
end;

procedure TMainFormSkia.DoInvalidateOverlayLive;
begin
  InvalidateOverlayLive;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.DoInvalidateOverlayStatic;
begin
  InvalidateOverlayStatic;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.PaintOverlayStatic(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
end;

procedure TMainFormSkia.PaintOverlayLive(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
end;

function TMainFormSkia.BuildOverlayImage(const AIsStatic: Boolean): ISkImage;
var
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  C: ISkCanvas;
  ViewScale: Single;
  Tx, Ty: Single;
  W, H: Integer;
  BaseXMin, BaseYMin: Double;
begin
  Result := nil;
  if (SkPainter = nil) or (Selector = nil) then
    Exit;

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

  Tx := -Single(BaseXMin + Selector.GetDx) * ViewScale;
  Ty := -Single(BaseYMin + Selector.GetDy) * ViewScale;
  C.Save;
  try
    C.Translate(Tx, Ty);
    C.Scale(ViewScale, ViewScale);
    if AIsStatic then
      PaintOverlayStatic(C, TRectF.Create(0, 0, W, H))
    else
      PaintOverlayLive(C, TRectF.Create(0, 0, W, H));
  finally
    C.Restore;
  end;

  Surface.Flush;
  Result := Surface.MakeImageSnapshot;
end;

procedure TMainFormSkia.EnsureOverlayImages;
begin
  if InteractionBitmapActive then
    Exit;

  if FOverlayStaticDirty then
  begin
    FOverlayStaticImage := BuildOverlayImage(True);
    FOverlayStaticDirty := False;
  end;

  if FOverlayLiveDirty then
  begin
    FOverlayLiveImage := BuildOverlayImage(False);
    FOverlayLiveDirty := False;
  end;
end;

procedure TMainFormSkia.SetSelectorParams;
begin
 Selector.OnUpdateScene := UpdateScene;
 Selector.OnInvalidateOverlayLive := DoInvalidateOverlayLive;
 Selector.OnInvalidateOverlayStatic := DoInvalidateOverlayStatic;
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
const
  MiddleDblClickTimeMs = 350;
  MiddleDblClickDist = 12;
var
  NowT: UInt64;
  Xpx, Ypx: Double;
  BaseXMin, BaseYMin: Double;
  WldX, WldY: Double;
  RectOK: Boolean;
begin
  if Selector = nil then
    Exit;
  if ZoomActive then
    Exit;

  if Button = TMouseButton.mbMiddle then
  begin
    NowT := TThread.GetTickCount64;
    Xpx := X * LastCanvasScale;
    Ypx := Y * LastCanvasScale;
    BaseXMin := 0;
    BaseYMin := 0;
    if Selector.GlobalRect <> nil then
    begin
      BaseXMin := Selector.GlobalRect.XMin;
      BaseYMin := Selector.GlobalRect.YMin;
    end
    else if Selector.ActiveRect <> nil then
    begin
      BaseXMin := Selector.ActiveRect.XMin;
      BaseYMin := Selector.ActiveRect.YMin;
    end;
    if Selector.GetScale <> 0 then
    begin
      WldX := BaseXMin + Selector.GetDx + (Xpx / Selector.GetScale);
      WldY := BaseYMin + Selector.GetDy + (Ypx / Selector.GetScale);
    end
    else
    begin
      WldX := 0;
      WldY := 0;
    end;
    if (FLastMiddleDownTick <> 0) and ((NowT - FLastMiddleDownTick) <= MiddleDblClickTimeMs) and
       (Abs(X - FLastMiddleDownPos.X) <= MiddleDblClickDist) and (Abs(Y - FLastMiddleDownPos.Y) <= MiddleDblClickDist) then
    begin
      FLastMiddleDownTick := 0;
      InteractionActive := False;
      PanActive := False;
      LastZoomDistance := 0;
      BaseScale := 0;
      Selector.UpdateRects(True);
      ClearOverlayAllCaches;
      if SkPainter <> nil then
        SkPainter.Redraw;
      Exit;
    end;

    FLastMiddleDownTick := NowT;
    FLastMiddleDownPos := PointF(X, Y);
  end;

  UpdateStatusGeo(X, Y, '');
  PanActive := True;
  ZoomActive := False;
  LastZoomDistance := 0;
  InteractionActive := True;
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
  UpdateStatusGeo(X, Y, '');
  if ZoomActive then
    Exit;
  if not PanActive then
    Exit;
  if Selector.GetScale = 0 then
    Exit;
  DxPix := (X - LastPanPoint.X) * LastCanvasScale;
  DyPix := (Y - LastPanPoint.Y) * LastCanvasScale;
  LastPanPoint := PointF(X, Y);
  DxGeo := DxPix / Selector.GetScale;
  DyGeo := DyPix / Selector.GetScale;
  Selector.Move(-DxGeo, -DyGeo);
  ClearOverlayAllCaches;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  DxPix, DyPix: Double;
  DxGeo, DyGeo: Double;
  Xpx, Ypx: Double;
  BaseXMin, BaseYMin: Double;
  WldX, WldY: Double;
  RectOK: Boolean;
begin
 If Selector = nil then Exit;

  WriteIn(['MouseUp', ' Btn=', Ord(Button), ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1)]);

  if Button = TMouseButton.mbMiddle then
  begin
    Xpx := X * LastCanvasScale;
    Ypx := Y * LastCanvasScale;
    BaseXMin := 0;
    BaseYMin := 0;
    if Selector.GlobalRect <> nil then
    begin
      BaseXMin := Selector.GlobalRect.XMin;
      BaseYMin := Selector.GlobalRect.YMin;
    end
    else if Selector.ActiveRect <> nil then
    begin
      BaseXMin := Selector.ActiveRect.XMin;
      BaseYMin := Selector.ActiveRect.YMin;
    end;
    if Selector.GetScale <> 0 then
    begin
      WldX := BaseXMin + Selector.GetDx + (Xpx / Selector.GetScale);
      WldY := BaseYMin + Selector.GetDy + (Ypx / Selector.GetScale);
    end
    else
    begin
      WldX := 0;
      WldY := 0;
    end;
  end;

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
  PF: TPointF;
  Step: Single;
  PivotPix: TPointF;
  PivotGeo: TPointF;
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

  if WheelDelta > 0 then
    Step := 1.15
  else
    Step := 1 / 1.15;

  PivotPix := PointF(PF.X * LastCanvasScale, PF.Y * LastCanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, Step);
  ClearOverlayAllCaches;

  WheelZoomLastTick := TThread.GetTickCount64;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  StepRatio: Single;
  PivotPix: TPointF;
  PivotGeo: TPointF;
begin
  if FDrawerSkia = nil then
    Exit;
  if Selector = nil then
    Exit;
  PanActive := False;
  Handled := True;
  InteractionActive := True;
  ZoomActive := True;
  PanActive := False;

  if (EventInfo.Distance <= 0) then
  begin
    LastZoomDistance := 0;
    ResetInteractionState;
    Exit;
  end;

  if (EventInfo.Distance < 2) then
    Exit;

  if LastZoomDistance = 0 then
  begin
    LastZoomDistance := EventInfo.Distance;
    Exit;
  end;

  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;

  if LastZoomDistance <= 0 then
    Exit;

  StepRatio := EventInfo.Distance / LastZoomDistance;
  if (StepRatio > 1.8) or (StepRatio < (1 / 1.8)) then
  begin
    LastZoomDistance := EventInfo.Distance;
    Exit;
  end;
  LastZoomDistance := EventInfo.Distance;

  PivotPix := PointF(EventInfo.Location.X * LastCanvasScale, EventInfo.Location.Y * LastCanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, StepRatio);
  ClearOverlayAllCaches;

  if SkPainter <> nil then
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
 Result := False;
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
  RAct: TogsRect;
  OverlayPaint: ISkPaint;
const
  DebugDirectSkia = false;
begin
  T0 := TThread.GetTickCount64;
  try
//  WriteIn(['SkPainterDraw enter', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1), ' Dest=', ADest.Width, 'x', ADest.Height]);
    if FDrawerSkia = nil then Exit;
    if SkPainter <> nil then
      LastCanvasScale := SkPainter.AbsoluteScale.X
    else
      LastCanvasScale := 1;
    if LastCanvasScale <= 0 then LastCanvasScale := 1;

    if (Selector <> nil) and (SkPainter <> nil) then
      if (Abs(FLastDestW - ADest.Width) > 0.1) or (Abs(FLastDestH - ADest.Height) > 0.1) or (Abs(FLastAbsScale - LastCanvasScale) > 0.001) then
      begin
        FLastDestW := ADest.Width;
        FLastDestH := ADest.Height;
        FLastAbsScale := LastCanvasScale;

        FDrawerSkia.Width := Round(ADest.Width * LastCanvasScale);
        FDrawerSkia.Height := Round(ADest.Height * LastCanvasScale);

        RAct := TogsRect.Create;
        try
          RAct.Assign(Selector.ActiveRect);
          Selector.ActiveRect := RAct;
        finally
          RAct.Free;
        end;
        Selector.UpdateRects(False);
        InvalidateOverlayAll;
      end;
    if ACanvas <> nil then ACanvas.Clear(TAlphaColors.White);

    EnsureOverlayImages;

    if not InteractionBitmapActive then PaintBefore(ACanvas, ADest);

    if (FDrawerSkia.SkiaList.Count = 0) then
    begin
      WriteIn(['SkPainterDraw exit: empty', ' Dirty=', SceneDirty, ' Cnt=', FDrawerSkia.SkiaList.Count, ' PicNil=', FCachedPicture = nil]);
      RequestRebuildScene;
      PaintBefore(ACanvas, ADest);
      Exit;
    end;

    if SceneDirty then
    begin
      WriteIn(['SkPainterDraw dirty: request rebuild', ' Cnt=', FDrawerSkia.SkiaList.Count, ' PicNil=', FCachedPicture = nil]);
      RequestRebuildScene;
    end;

    if (FCachedPicture = nil) then
    begin
      if (not SceneDirty) and (FDrawerSkia.SkiaList.Count > 0) then
      begin
        BuildCachedPictureFromList;
      end;

      if (FCachedPicture = nil) then
      begin
        WriteIn(['SkPainterDraw exit: no pic', ' Dirty=', SceneDirty, ' Cnt=', FDrawerSkia.SkiaList.Count]);
        SceneDirty := True;
        RequestRebuildScene;
        PaintBefore(ACanvas, ADest);
        Exit;
      end;
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
    end;

    if (Pic = nil) and (ACanvas <> nil) and (FDrawerSkia.SkiaList.Count > 0) and (Selector <> nil) then
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

    if (ACanvas <> nil) then
    begin
      OverlayPaint := TSkPaint.Create;
      OverlayPaint.AntiAlias := True;
      if FOverlayStaticImage <> nil then
        ACanvas.DrawImageRect(FOverlayStaticImage, ADest, OverlayPaint);
      if FOverlayLiveImage <> nil then
        ACanvas.DrawImageRect(FOverlayLiveImage, ADest, OverlayPaint);
    end;
  finally
    Dt := TThread.GetTickCount64 - T0;
  end;
end;

end.
