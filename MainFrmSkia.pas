unit MainFrmSkia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.DialogService,
  FMX.Ani,
  MainFrm, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Objects, FMX.Skia, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  ogcBasic, ogcDrawerSkia, newSelector;

type
  TMainFormSkia = class(TMainForm)
    btnPDF: TCornerButton;
    SkPainter: TSkPaintBox;
    Popup1: TPopup;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnPaintClick(Sender: TObject);
    procedure upmClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPlusClickSkia(Sender: TObject);
  private
    FStatusLabel: TLabel;
    FDrawerSkia: TogsDrawerSkia;
    FBuildingScene: Boolean;
    FRebuildQueued: Boolean;
    FIndicatorDepth: Integer;
    FIndicatorOverlay: TRectangle;
    FIndicator: TAniIndicator;
    FOverlayStaticImage: ISkImage;
    FOverlayLiveImage: ISkImage;
    FOverlayStaticDirty: Boolean;
    FOverlayLiveDirty: Boolean;
    FLivePainter: TSkPaintBox; // live-слой поверх SkPainter: маркер, рамка, резиновые линии
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
    FSceneDirty: Boolean;
    procedure SetSceneDirty(AValue: Boolean);
  //
    procedure InitSkPainterInput;
  //
    procedure SkPainterResize(Sender: TObject);
  //
    procedure RenderSceneToBackbufferSkia;
    procedure SetPrimitiveBounds(Obj: TObject);
  //
    procedure btnOpenClickSkia(Sender: TObject);
    procedure btnLocalOpenClickSkia(Sender: TObject);
    procedure btnPaintClickSkia(Sender: TObject);
  //
    procedure SkPainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
    procedure LivePainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
  //
    procedure ResetInteractionState;
   //
    procedure DoExportPdfWithName(const AName: string);
   //
    procedure WheelZoomTimer(Sender: TObject);
    procedure EnsureOverlayImages;
    function BuildOverlayImage(const AIsStatic: Boolean): ISkImage;
    procedure DoInvalidateOverlayLive;
    procedure DoInvalidateOverlayStatic;
    procedure ClearOverlayAllCaches;
    procedure EnsureIndicator;
  protected
    procedure Loaded; override;
    procedure SetSelectorParams; virtual;
    procedure InvalidateOverlayStatic;
    procedure InvalidateOverlayLive;
    procedure InvalidateOverlayAll;
    procedure RepaintLive;
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
    MousePos: TPointF;
    procedure UpdateStatusGeo(const X, Y: Single; Hint: String);
    procedure OpenGmfFileSkia(const LocalPath: string); virtual;
   // карта перемещается мышью (нажата кнопка над картой, перемещение начато)
    property IsPanning: Boolean read PanActive;
  public
    destructor Destroy; override;
    procedure OpenGmfFile(const LocalPath: string); override;
    function ExportSceneToPdf(const AFileName: string = ''): string;
    procedure StartIndicator;
    procedure StopIndicator;
   //
    procedure InvalidateCachedPictureOnly;
    property SceneDirty: Boolean read FSceneDirty write SetSceneDirty;
  end;

var
  MainFormSkia: TMainFormSkia;

implementation

uses Selector32, Collect, uExecRegisterClass, System.IOUtils, Writer, newProcs, FMX.FontManager,
     EcText, EcDot, EcDot2, EcLot, RPrims, WPTwigs, DlgLocalOpen,
     WPTForm2, mpMarker, objMouse, drawTwigs, UpdateMessages, TwgDraw
{$IFDEF ANDROID}
     , OpenForm, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes
{$ENDIF}
     , Lib, StylusInput;

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
  GSceneDrawCount: Integer = 0; // отладка фризов: число отрисовок сцены

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
{$IFDEF MSWINDOWS}
// над картой - системный курсор-крестик (на Android курсора нет)
  SkPainter.Cursor := crCross;
{$ENDIF}
  SkPainter.OnMouseWheel := SkPainterMouseWheel;
  SkPainter.OnGesture := SkPainterGesture;
  SkPainter.OnDblClick := SkPainterDblClick;
  SkPainter.OnDraw := SkPainterDraw;
  SkPainter.Touch.InteractiveGestures := [TInteractiveGesture.Zoom];
// флаги GPU выставляются в .dpr до Application.Initialize
// сцена рендерится в буфер контрола; OnDraw вызывается только по Redraw.
// Never и Raster на GPU-канве (TGrCanvas) рисуют прямо в канву формы без кэша,
// а Skia-канва формы не поддерживает SupportClipRects: любая инвалидация
// любого контрола перерисовывает всю форму вместе со сценой. Кэш дает только Always
 SkPainter.DrawCacheKind := TSkDrawCacheKind.Always;
// live-слой: отдельный контрол поверх сцены, рисует прямо в канву формы (Never)
// на каждой перерисовке; сцена при этом выводится из буфера SkPainter
 if FLivePainter = nil then begin
  FLivePainter := TSkPaintBox.Create(Self);
  FLivePainter.Parent := SkPainter;
  FLivePainter.Align := TAlignLayout.Client;
  FLivePainter.HitTest := False;
  FLivePainter.DrawCacheKind := TSkDrawCacheKind.Never;
  FLivePainter.OnDraw := LivePainterDraw;
 end;
end;

procedure TMainFormSkia.EnsureIndicator;
begin
  if FIndicatorOverlay <> nil then
    exit;
  FIndicatorOverlay := TRectangle.Create(Self);
  FIndicatorOverlay.Parent := Self;
  FIndicatorOverlay.Align := TAlignLayout.Contents;
  FIndicatorOverlay.Fill.Color := $40000000;
  FIndicatorOverlay.Stroke.Kind := TBrushKind.None;
  FIndicatorOverlay.HitTest := True;
  FIndicatorOverlay.Visible := False;

  FIndicator := TAniIndicator.Create(Self);
  FIndicator.Parent := FIndicatorOverlay;
  FIndicator.Align := TAlignLayout.Center;
  FIndicator.Enabled := False;
  FIndicator.Visible := False;
end;

procedure TMainFormSkia.StartIndicator;
begin
  inc(FIndicatorDepth);
  if FIndicatorDepth <> 1 then
    exit;
  EnsureIndicator;
  if FIndicatorOverlay <> nil then
  begin
    FIndicatorOverlay.Visible := True;
    FIndicatorOverlay.BringToFront;
  end;
  if FIndicator <> nil then
  begin
    FIndicator.Enabled := True;
    FIndicator.Visible := True;
    FIndicator.BringToFront;
  end;
  Application.ProcessMessages;
end;

procedure TMainFormSkia.StopIndicator;
begin
  if FIndicatorDepth <= 0 then
    exit;
  dec(FIndicatorDepth);
  if FIndicatorDepth <> 0 then
    exit;
  if FIndicator <> nil then
  begin
    FIndicator.Enabled := False;
    FIndicator.Visible := False;
  end;
  if FIndicatorOverlay <> nil then
    FIndicatorOverlay.Visible := False;
end;

procedure TMainFormSkia.SetSceneDirty(AValue: Boolean);
var I: Integer; Lot: TLot; PD: TPointDot; B: Byte;
begin
  FSceneDirty := AValue;
  if (TwgForm = nil) or (TwgForm.Twigs = nil) then Exit;
  if AValue then
  begin
    for I := 0 to TwgForm.Twigs.LotsCount - 1 do
    begin
      Lot := TwgForm.Twigs.LAt(I);
      Lot.Modified := True;
    end;
    for I := 0 to TwgForm.Twigs.AnyCount - 1 do
    begin
      PD := TwgForm.Twigs.AAt(I, B);
    //  if B = TWG_Point then
      PD.Modified := True;
    end;
  end;
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
  WorldRect: TRectF;
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
            WorldRect := R;
            WorldRect.Inflate(1000, 1000);
            FDrawerSkia.BeginFrame(C, WorldRect);
            try
              RenderSceneToBackbufferSkia;
            finally
              FDrawerSkia.EndFrame;
            end;
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

var GFontFiles: TStringList = nil; // зарегистрированные файлы шрифтов

// шрифт регистрируется один раз за сеанс (а не при каждом открытии карты)
function NewFontFile(const F: string): Boolean;
begin
 if GFontFiles = nil then begin
  GFontFiles := TStringList.Create;
  GFontFiles.CaseSensitive := False;
 end;
 Result := GFontFiles.IndexOf(F) = -1;
 if Result then GFontFiles.Add(F);
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
    Dir := GmfLocalPath;
    WriteIn(['START===']);
    if Dir = '' then
      Exit;
    try
      Files := TDirectory.GetFiles(Dir, '*.ttf');
      for F in Files do
        try
         if not NewFontFile(F) then continue;
        // Windows: TFontManager рассылает WM_FONTCHANGE всем окнам системы
        // (SendMessage(HWND_BROADCAST) - висит, если какое-то окно не отвечает);
        // текст FMX рисует Skia (GlobalUseSkia) - достаточно RegisterTypeface
        {$IFNDEF MSWINDOWS}
         TFontManager.AddCustomFontFromFile(F);
        {$ENDIF}
          TSkDefaultProviders.RegisterTypeface(F);
          RegisterSkiaTypefaceFromFile(F);
          TF := TSkTypeface.MakeFromFile(F);
           if TF <> nil then
            begin
             WriteIn(['RegisterFont=',TF.FamilyName]);
             RegisterSkiaFontFile(TF.FamilyName, F);
            end;
           WriteIn(['===', F]);
        except
        end;
    except
    end;
    try
      Files := TDirectory.GetFiles(Dir, '*.otf');
      for F in Files do
        try
          if not NewFontFile(F) then continue;
        {$IFNDEF MSWINDOWS}
          TFontManager.AddCustomFontFromFile(F);
        {$ENDIF}
          TSkDefaultProviders.RegisterTypeface(F);
          RegisterSkiaTypefaceFromFile(F);
        except
        end;
    except
    end;
    WriteIn(['END===']);
  end;
  procedure localSetGabarites;
  var
    I, J: Integer;
    Twig: TTwig;
    PP: TPointDot;
    B: Byte;
    Lot: TLot;
  begin
    for I := 1 to TwgForm.Twigs.TwigsCount - 1 do
    begin
      Twig := TwgForm.Twigs.TAt(I);
      Twig.SetMinMax;
      for J := 0 to Twig.Coord.Count - 1 do
        Selector.AddCoord(Twig[J].XDot, Twig[J].YDot);
    end;
    for I := 0 to TwgForm.Twigs.AnyCount - 1 do
    begin
      PP := TwgForm.Twigs.AAt(I, B);
      Selector.AddCoord(PP.XDot, PP.YDot);
    end;
    for I := 1 to TwgForm.Twigs.LotsCount - 1 do begin
     Lot := TwgForm.Twigs.LAt(I);
     Lot.SetMinMax(TwgForm.Twigs);
    end;
  end;
begin
  if LocalPath = '' then Exit;
 // StartIndicator;
  try
    if FDrawerSkia = nil then
    begin
      FDrawerSkia := TogsDrawerSkia.Create(nil, nil, SkPainter);
      Selector := TSelector.Create(FDrawerSkia);
     // текущий селектор для модулей, перенесенных из Geomaster (Selector32)
      SetGSelector(Selector);
      FDrawerSkia.ogsSelector := Selector;
      FDrawerSkia.Name := 'DrawerSkia';
      Selector.Name := 'Selector';
      UpdateMessage:=TUpdateMessage.Create(nil);
    end else
      Selector.Clear;
   //
    FDrawerSkia.DebugDrawTextBounds := False;
   //
   // Memo1.Lines.Clear;
    FormCreate(Self);
   // InitSkPainterInput;
    {$IFDEF WIN64}
     GLines := nil;
     newProcs.MainPath := TPath.GetLibraryPath {+ 'dicts\'};
    {$ELSE}
   // GLines := Memo1.Lines;
     newProcs.MainPath := TPath.GetDocumentsPath + '/';
     WriteIn(['OSM CachePath: ', TPath.GetCachePath]);
     WriteIn(['Path1 ========', MainPath,  FileExists(MainPath), TPath.GetHomePath, TPath.GetLibraryPath, TPath.GetDocumentsPath, TPath.GetCachePath]);
    {$ENDIF}
    RegPrimitives;
    objectRepaintAccess := False;
    Path := LocalPath;

    RegisterFontsNearGmf(MainPath);

    Stream := TBufStream.InitFileStream(LocalPath, fmOpenRead);
    Selector.GNForm := TControl(skPainter);
    ApplicationMainForm := Self;
    Stream.Selector := Selector;
    try
      FreeAndNil(TwgForm);
     //
      TwgForm := TForm2(Stream.Get);
     //
      TwgForm.About.Path := ExtractFilePath(LocalPath);
      TwgForm.About.MyName := ExtractFileName(LocalPath);
     //
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
      TwgForm.Twigs.BlockList.CreateBitmaps;
      PLib(TwgForm.MkLib.PSLib).CreateBitmaps;
    finally
      Stream.Free;
    end;

    InitSkPainterInput;
    SkPainterResize(SkPainter);
    GlobalRender := False;
  //  if SkPainter <> nil then
   //   SkPainter.Redraw;
    SkPainterDblClick(nil);
    btnPaintClick(nil);
  finally
   // StopIndicator;
  end;
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
{$IFDEF ANDROID}
  localOpenForm.BaseDir := GetAppExternalFilesDir;
{$ENDIF}
  localOpenForm.FCallBack := OpenGmfFileSkia;
  localOpenForm.Show;
end;

procedure TMainFormSkia.btnPaintClick(Sender: TObject);
begin
 SceneDirty := True;
  SkPainter.Redraw;
  SkPainter.Repaint;
end;

procedure TMainFormSkia.btnPaintClickSkia(Sender: TObject);
begin
 SceneDirty := True;
  SkPainter.Redraw;
  SkPainter.Repaint;
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

// объект добавлен, изменен или удален: картинка объекта (DrawerObject)
// сбрасывается и перезаписывается при следующей отрисовке сцены
procedure TMainFormSkia.UpdateScene(UpdateSceneMode: TUpdateSceneMode; Obj: TObject);
begin
 if Obj is TTD then TTD(Obj).Modified := True;
 if SkPainter <> nil then SkPainter.Redraw;
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
  XGeo := - Selector.YGeo(Round(YPix));; YGeo := Selector.XGeo(Round(XPix));
  S := Fmt(['XGeo=', XGeo, 'YGeo=', YGeo]);//, 'objRect=', Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
  if FStatusLabel <> nil then
    FStatusLabel.Text := S + ' '+Hint;
end;

procedure TMainFormSkia.upmClick(Sender: TObject);
begin
// Memo1.GoToTextEnd;
 ExportSceneToPdf(MainPath + 'test.pdf')
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
  SkObj: TObject;
  StartTick, ElapsedMs: UInt64;
begin
  Error := 1;
  if FDrawerSkia = nil then
    Exit;
  if TwgForm = nil then
    Exit;
  if not objectRepaintAccess then
    Exit;
  StartTick := TThread.GetTickCount64;
  WriteIn(['StartDraw32===========',StartTick ]);
  try
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
                  SkObj := Lot.DrawerObject;
                  if (not Lot.Modified) and (SkObj is TogsSkiaObject) and
                     (TogsSkiaObject(SkObj).Picture <> nil) then
                  begin
                    Lot.SkiaDraw(FDrawerSkia.SkCanvas);
                  end
                  else
                  begin
                    FDrawerSkia.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
                    try
                    // GGraphSet.ViewZnaks := 0;
                    //Writein(['l.draw32=', 1, i]);
                      Lot.Draw32(TwgForm.Twigs);
                    //Writein(['l.draw32=', 2]);
                    finally
                      FDrawerSkia.EndPrimitive;
                    end;
                    Lot.SetMinMax(TwgForm.Twigs);
                    SetPrimitiveBounds(Lot);
                    Lot.SkiaDraw(FDrawerSkia.SkCanvas);
                  end;
                end;
              except
                Exit;
              end;
              Prog := Prog + 1;
            end;
          end;
        end;
        ElapsedMs := TThread.GetTickCount64 - StartTick;
        StartTick :=TThread.GetTickCount64;
        WriteIn(['RenderSceneToBackbufferSkia lots s=', ElapsedMs / 1000]);
        for I := 0 to TwgForm.Twigs.AnyCount - 1 do
        begin
          PP := TwgForm.Twigs.AAt(I, B);
          if (B = TWG_Point) then
          begin
            PPoint := PP;
           // if PPoint.Closed then
           //   Continue;
           // if PPoint.userObj <> nil then exit;
            try
              SkObj := PPoint.DrawerObject;
              if (not PPoint.Modified) and (SkObj is TogsSkiaObject) then
              begin
               //If PPoint.BlockTextBitmaps <> nil then
               // if Self.Selector.SectVisible(PPoint.BlockTextBitmaps.Sect) then
                 PPoint.SkiaDraw(FDrawerSkia.SkCanvas)
                 // else
                 //  WriteIn(['nv', i]);
              end
              else
              If not False {PPoint.isCaptured} {((PPoint is TDotText) or (PPoint.userObj <> nil))} then  begin
                FDrawerSkia.BeginPrimitive(Int64(NativeInt(PPoint)), PPoint);
                try
                // WriteIn(['p1---',I]);
                 PPoint.Draw32(FDrawerSkia, TwgForm.MkLib.PSLib, TwgForm.FontColEx);
                // WriteIn(['p2=',I]);
                finally
                  FDrawerSkia.EndPrimitive;
                end;
              // LOD2 пока не используется, а TDotText.DrawSelected повторно выполняет Draw32
              //  PPoint.DrawSelected(FDrawerSkia);
                SetPrimitiveBounds(PPoint);
                PPoint.SkiaDraw(FDrawerSkia.SkCanvas);
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
    BaseDx := Selector.GetDx;
    BaseDy := Selector.GetDy;
    BaseScale := Selector.GetScale;
  finally
    ElapsedMs := TThread.GetTickCount64 - StartTick;
   WriteIn(['RenderScene points s=', ElapsedMs / 1000]);
  end;
end;

procedure TMainFormSkia.SetPrimitiveBounds(Obj: TObject);
const MARGIN_PIX = 64;       // запас контура на толщину линий и знаки, пикселы
      MARGIN_POINT_MIN = 0.05; // наименьший запас точечного объекта, мировые единицы
var SkObj: TObject;
    XMin, YMin, XMax, YMax, Margin, Size: Double;
    HasBounds: Boolean;
    Lot: TLot;
    Twig: TTwig;
    PD: TPointDot;
    I, J: Integer;
procedure AddPoint(X, Y: Double);
begin
 if not HasBounds then begin
  XMin := X; XMax := X; YMin := Y; YMax := Y;
  HasBounds := True;
  exit;
 end;
 if X < XMin then XMin := X;
 if X > XMax then XMax := X;
 if Y < YMin then YMin := Y;
 if Y > YMax then YMax := Y;
end;
procedure AddSect(const S: TSect);
begin
 if (S.XMin = S.XMax) and (S.YMin = S.YMax) then exit;
 AddPoint(S.XMin, S.YMin);
 AddPoint(S.XMax, S.YMax);
end;
begin
 if (Obj = nil) or (Selector = nil) or (Selector.GetScale <= 0) or (TwgForm = nil) then exit;
 SkObj := TTD(Obj).DrawerObject;
 if not (SkObj is TogsSkiaObject) then exit;
 HasBounds := False;
 if Obj is TLot then begin
  Lot := TLot(Obj);
 // габариты участка; если не рассчитаны (SetMinMax не вызывался) - по вершинам ветвей
  if (Lot.XMin <= Lot.XMax) and (Lot.YMin <= Lot.YMax) then begin
   AddPoint(Lot.XMin, Lot.YMin);
   AddPoint(Lot.XMax, Lot.YMax);
  end else
   for I := 0 to Lot.Coord.Count - 1 do begin
    Twig := Lot.GetTwig(TwgForm.Twigs, I);
    if Twig = nil then continue;
    for J := 0 to Twig.Coord.Count - 1 do AddPoint(Twig[J].XDot, Twig[J].YDot);
   end;
 end else if Obj is TPointDot then begin
  PD := TPointDot(Obj);
  AddSect(PD.Sect);
  if PD.BlockTextBitmaps <> nil then AddSect(PD.BlockTextBitmaps.Sect);
  if (PD is TDotText) and (TDotText(PD).TextBitmap <> nil) then AddSect(TDotText(PD).TextBitmap.Sect);
 // габариты неизвестны - объект не отсекаем (остаются границы всего мира)
  if not HasBounds then exit;
  AddPoint(PD.XDot, PD.YDot);
 end;
 if not HasBounds then exit;
 Size := XMax - XMin;
 if YMax - YMin > Size then Size := YMax - YMin;
// у точечного объекта габариты уже включают знак и надписи - запас только от
// размера объекта; запас в пикселах считался бы по масштабу записи картинки
// (обычно мелкому) и раздувал границы при приближении
 if Obj is TPointDot then begin
  Margin := 0.1 * Size;
  if Margin < MARGIN_POINT_MIN then Margin := MARGIN_POINT_MIN;
 end else
  Margin := MARGIN_PIX / Selector.GetScale + 0.1 * Size;
 TogsSkiaObject(SkObj).BoundsWorld := TRectF.Create(XMin - Margin, YMin - Margin, XMax + Margin, YMax + Margin);
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
 RepaintLive;
//  if SkPainter <> nil then
//    SkPainter.Redraw;
end;

procedure TMainFormSkia.RepaintLive;
begin
 if FLivePainter <> nil then FLivePainter.Repaint;
end;

procedure TMainFormSkia.LivePainterDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var ViewScale, Tx, Ty: Single;
    LayerPaint: ISkPaint;
    T0, Dt: UInt64;
begin
 if (ACanvas = nil) or (Selector = nil) or (Selector.GlobalRect = nil) then exit;
 if InteractionBitmapActive then exit;
 ViewScale := Single(Selector.GetScale);
 if ViewScale <= 0 then exit;
 T0 := TThread.GetTickCount64;
 try
// та же матрица вида, что у сцены в SkPainterDraw
 Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
 Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
 ACanvas.Save;
 try
 // канва - это канва всей формы: ограничиваем границами контрола
  ACanvas.ClipRect(ADest);
 // статический оверлей (выделение): готовое изображение, пересобирается только после сброса
  EnsureOverlayImages;
  if FOverlayStaticImage <> nil then begin
   LayerPaint := TSkPaint.Create;
   LayerPaint.AntiAlias := True;
   ACanvas.DrawImageRect(FOverlayStaticImage, ADest, LayerPaint);
  end;
 // слой смешивается со сценой в режиме Difference, как раньше изображение live-слоя
  LayerPaint := TSkPaint.Create;
  LayerPaint.Blender := TSkBlender.MakeMode(TSkBlendMode.Difference);
  ACanvas.SaveLayer(ADest, LayerPaint);
  try
   ACanvas.Translate(Tx, Ty);
   ACanvas.Scale(ViewScale, ViewScale);
   PaintOverlayLive(ACanvas, ADest);
  finally
   ACanvas.Restore;
  end;
 finally
  ACanvas.Restore;
 end;
 finally
 // отладка фризов: отрисовка live-слоя 30 мс и больше; номер отрисовки сцены
  Dt := TThread.GetTickCount64 - T0;
  if Dt >= 30 then WriteIn(['LivePainterDraw ms=', Dt, ' scene#', GSceneDrawCount]);
 end;
end;

procedure TMainFormSkia.DoInvalidateOverlayStatic;
begin
  InvalidateOverlayStatic;
 RepaintLive;
//  if SkPainter <> nil then
//    SkPainter.Redraw;
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

procedure TMainFormSkia.btnCloseClick(Sender: TObject);
begin
  inherited;
 Close;
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

// live-слой рисует FLivePainter (LivePainterDraw), здесь он не строится
  FOverlayLiveDirty := False;
end;

procedure TMainFormSkia.SetSelectorParams;
begin
 Selector.OnUpdateScene := UpdateScene;
 Selector.OnInvalidateOverlayLive := DoInvalidateOverlayLive;
 Selector.OnInvalidateOverlayStatic := DoInvalidateOverlayStatic;
end;

// FitView - вся карта в окне. Вызов из кода (Sender = nil, после открытия
// карты) - всегда. Двойной щелчок (OnDblClick - левая кнопка или касание):
// на Windows не выполняется (FitView - двойной щелчок средней кнопкой,
// SkPainterMouseDown), на Android - только пальцем, не пером
procedure TMainFormSkia.SkPainterDblClick(Sender: TObject);
begin
  if Selector = nil then
    Exit;
  if Sender <> nil then
  begin
{$IFDEF ANDROID}
    if StylusTool in [stStylus, stEraser, stMouse] then Exit;
{$ELSE}
    Exit;
{$ENDIF}
  end;
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
//  UpdateStatusGeo(X, Y, '');
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

  WriteIn(['MouseUp', ' Btn=', Ord(Button)]);

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

procedure TMainFormSkia.InvalidateCachedPictureOnly;
begin
  if SkPainter <> nil then
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
  Img: ISkImage;
  Paint: ISkPaint;
  DstRect: TRectF;
  T0, Dt: UInt64;
  RAct: TogsRect;
  WorldRect: TRectF;
  PrevWorld: Boolean;
const
  DebugDirectSkia = false;
var Clipped: Boolean;
begin
  T0 := TThread.GetTickCount64;
  Clipped := False;
  try
//  WriteIn(['SkPainterDraw enter', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1), ' Dest=', ADest.Width, 'x', ADest.Height]);
    if FDrawerSkia = nil then Exit;
// при прямой отрисовке канва - это канва всей формы: ограничиваем ее границами контрола
  ACanvas.Save;
  Clipped := True;
  ACanvas.ClipRect(ADest);
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

  // оверлеи (статический и live) рисует FLivePainter - LivePainterDraw
    if not InteractionBitmapActive then PaintBefore(ACanvas, ADest);

    if (Selector <> nil) then
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

          WorldRect := TRectF.Create(
            Single(Selector.GlobalRect.XMin),
            Single(Selector.GlobalRect.YMin),
            Single(Selector.GlobalRect.XMax),
            Single(Selector.GlobalRect.YMax));
         // WorldRect.Inflate(1000, 1000);

          PrevWorld := FDrawerSkia.UseWorldCoords;
          FDrawerSkia.UseWorldCoords := True;
          try
            FDrawerSkia.BeginFrame(ACanvas, WorldRect);
            try
              RenderSceneToBackbufferSkia;
            finally
              FDrawerSkia.EndFrame;
            end;
          finally
            FDrawerSkia.UseWorldCoords := PrevWorld;
          end;
        finally
          ACanvas.Restore;
        end;
      end;
    end;

  finally
  if Clipped then ACanvas.Restore;
    Dt := TThread.GetTickCount64 - T0;
   // отладка фризов: номер отрисовки сцены (растет при движении мыши - сцена
   // перерисовывается) и время, если 30 мс и больше
    Inc(GSceneDrawCount);
    if Dt >= 30 then WriteIn(['SkPainterDraw #', GSceneDrawCount, ' ms=', Dt]);
  end;
end;

initialization
 newProcs.MainPath := TPath.GetLibraryPath;
finalization
 FreeAndNil(GFontFiles);
end.
