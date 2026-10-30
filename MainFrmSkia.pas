unit MainFrmSkia;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.DialogService,
  FMX.Ani,
  MainFrm, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Objects, FMX.Skia, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  ogcBasic, ogcDrawerSkia, newSelector, FrameSettings, StylusInput, WPTForm2;

type
  TMainFormSkia = class(TMainForm)
    btnPDF: TCornerButton;
    SkPainter: TSkPaintBox;
    Popup1: TPopup;
    btnClose: TButton;
  // строка состояния (как в старой MasterForm): координаты, кнопка панели
  // установок, кнопки-переключатели, подсказка, масштаб; значки - ImageListStatus
    PanelXY: TLabel;
    ResSpeedBtn59: TSpeedButton;
    SbShowPoints: TSpeedButton;
    SbSaveOrthoTwigs: TSpeedButton;
    sbShowGrid: TSpeedButton;
    sbShowZnak: TSpeedButton;
    sbOrthoDraw: TSpeedButton;
    sbShowPlan: TSpeedButton;
    PanelHint: TLabel;
    pMas: TLabel;
    ImageListStatus: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure btnPaintClick(Sender: TObject);
    procedure upmClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPlusClickSkia(Sender: TObject);
   //
    procedure StatusButtonEnter(Sender: TObject);
    procedure StatusButtonLeave(Sender: TObject);
    procedure ResSpeedBtn59Click(Sender: TObject);
    procedure SbShowPointsClick(Sender: TObject);
    procedure SbSaveOrthoTwigsClick(Sender: TObject);
    procedure sbShowGridClick(Sender: TObject);
    procedure sbShowZnakClick(Sender: TObject);
    procedure sbOrthoDrawClick(Sender: TObject);
    procedure sbShowPlanClick(Sender: TObject);
  private
    FSettingsFrame: TSettingsFrame; // панель установок (CPPainter старой версии)
    FStatusSync: Boolean;
    FDrawerSkia: TogsDrawerSkia;
    FBuildingScene: Boolean;
    FRebuildQueued: Boolean;
    FIndicatorDepth: Integer;
    FIndicatorOverlay: TRectangle;
    FIndicator: TAniIndicator;
    FIndicatorText: FMX.Objects.TText;
    FMapLoading: Boolean; // карта читается в фоновом потоке: сцена не рисуется
    FOverlayStaticImage: ISkImage;
    FOverlayLiveImage: ISkImage;
    FOverlayStaticDirty: Boolean;
    FOverlayLiveDirty: Boolean;
    FLivePainter: TSkPaintBox; // live-слой поверх SkPainter: маркер, рамка, резиновые линии
    FLastDestW: Single;
    FLastDestH: Single;
    FLastAbsScale: Single;
   // левый верхний угол SkPainter на форме при прошлом пересчете ActiveRect
    FPainterPos: TPointF;
    FPainterPosValid: Boolean;
    FLastMiddleDownTick: UInt64;
    FLastMiddleDownPos: TPointF;
    PanActive: Boolean;
    LastPanPoint: TPointF;
    LastZoomDistance: Single;
    LastZoomPivot: TPointF; // середина между пальцами (координаты SkPainter) - перемещение двумя пальцами
    ZoomActive: Boolean;
    InteractionActive: Boolean;
    BaseDx, BaseDy, BaseScale: Double;
  // растровый снимок сцены (последний полный кадр): при сдвиге/масштабе рисуется
  // он со смещением и масштабом, полная перерисовка - после окончания жеста
    FSceneImage: ISkImage;
    FSnapRect: TRectF;
    FSnapK: Single;
    FSnapGx, FSnapGy, FSnapDx, FSnapDy, FSnapScale: Double;
    FUnderlayOnly: Boolean; // RedrawUnderlay: следующий кадр - снимок сцены, если вид тот же
    FSceneDirty: Boolean;
   // точки сегментов (SbShowPoints): вершины по What - 0, 10 (узловые), 20
   // (твердые); пересобираются, если карта изменилась
    FSegPoints: array[0..2] of TArray<TPointF>;
    FSegPointsDirty: Boolean;
    FSegPointsLots, FSegPointsTwigs, FSegPointsAny: Integer;
   // готовые примитивы вывода: изображение-атлас с квадратами трех видов точек
   // и для каждой точки - спрайт и положение (для масштаба FSegScale и
   // установок FSegKey); выводятся одним DrawAtlas
    FSegAtlas: ISkImage;
    FSegXForms: TArray<TSkRotationScaleMatrix>;
    FSegSprites: TArray<TRectF>;
    FSegScale: Single;
    FSegKey: String;
    FSegXFormsDirty: Boolean;
    procedure BuildSegmentPoints;
    procedure BuildSegmentAtlas(DevScale, Scale: Single; const Key: String);
    procedure DrawSegmentPoints(const C: ISkCanvas);
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
  // строка состояния
    procedure SettingsFrameApply(Sender: TObject);
    procedure SettingsFrameClose(Sender: TObject);
    procedure PlaceSettingsFrame;
    procedure UpdateScaleLabel;
    procedure ResizeActiveRect;
  protected
    procedure Loaded; override;
    procedure SetSelectorParams; virtual;
  // карта - центром в мировую точку (WX, WY), масштаб сохраняется
    procedure CenterMapOn(WX, WY: Double);
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
  // Windows: перемещение и масштаб двумя пальцами по касаниям (StylusInput)
    procedure TouchPinch(Action: TStylusPinchAction; const Center, Delta: TPointF; Ratio: Single);
    procedure SkPainterDblClick(Sender: TObject);
  // рисование перед-после
    procedure PaintBefore(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;
    procedure PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;
    procedure PaintOverlayStatic(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;
    procedure PaintOverlayLive(const ACanvas: ISkCanvas; const Rect: TRectF); virtual;

    function InteractionBitmapActive: Boolean; virtual;
    procedure DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF); virtual;
    procedure UpdateScene(UpdateSceneMode: TUpdateSceneMode; Obj: TObject);
    procedure SetHint(Sender: TObject); virtual;
  protected
    MousePos: TPointF;
    procedure UpdateStatusGeo(const X, Y: Single; Hint: String);
  // кнопки строки состояния - по установкам открытого файла
    procedure SyncStatusButtons;
    procedure OpenGmfFileSkia(const LocalPath: string); virtual;
   // карта прочитана в фоновом потоке (F = nil - ошибка Err): установка на экран
    procedure FinishOpenGmf(const LocalPath: string; F: TForm2; const Err: string);
   // карта показана - действия наследников после открытия; NewMap = False -
   // новая не прочитана, на экране снова прежняя
    procedure MapOpened(const LocalPath: string; NewMap: Boolean); virtual;
   // сохраненный фрагмент карты (About.Fragment) - в окно
    procedure ShowMapFragment;
   // карта выбрана на устройстве или скачана из облака: копия в папку
   // исполнителя (DlgGlobalSave.CopyMapToUserFolder) и открытие
    procedure OpenPickedMap(const LocalPath: string);
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
  // изменилась только подложка (PaintBefore, напр. пришел тайл OSM): сцена не
  // перерисовывается, если вид не менялся - выводится ее снимок FSceneImage
    procedure RedrawUnderlay;
    property SceneDirty: Boolean read FSceneDirty write SetSceneDirty;
  end;

var
  MainFormSkia: TMainFormSkia;

implementation

uses Selector32, Collect, uExecRegisterClass, System.IOUtils, Writer, newProcs, FMX.FontManager, System.Diagnostics, System.Math, System.Math.Vectors,
     EcText, EcDot, EcDot2, EcLot, RPrims, WPTwigs, DlgLocalOpen,
     mpMarker, objMouse, drawTwigs, UpdateMessages, TwgDraw, AppForms, HatchLot, newBlock, DlgGlobalSave
{$IFDEF ANDROID}
     , OpenForm, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes
{$ENDIF}
     , Lib, TwgColle;

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
 Application.OnHint := SetHint;
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
 // подпись под индикатором
  FIndicatorText := FMX.Objects.TText.Create(Self);
  FIndicatorText.Parent := FIndicatorOverlay;
  FIndicatorText.Align := TAlignLayout.Center;
  FIndicatorText.Margins.Top := 90;
  FIndicatorText.Size.Width := 300;
  FIndicatorText.Size.Height := 30;
  FIndicatorText.HitTest := False;
  FIndicatorText.TextSettings.FontColor := TAlphaColors.White;
  FIndicatorText.TextSettings.Font.Size := 16;
  FIndicatorText.Text := 'Загрузка карты...';
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
  if AValue then FSegPointsDirty := True;
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
begin
 if (FSettingsFrame <> nil) and FSettingsFrame.Visible then PlaceSettingsFrame;
  if (FDrawerSkia = nil) or (Selector = nil) or (SkPainter = nil) or FMapLoading then
    Exit;
  if (SkPainter.Width <= 0) or (SkPainter.Height <= 0) then
    Exit;

  LastCanvasScale := SkPainter.AbsoluteScale.X;
  if LastCanvasScale <= 0 then
    LastCanvasScale := 1;

  FDrawerSkia.Width := Round(SkPainter.Width * LastCanvasScale);
  FDrawerSkia.Height := Round(SkPainter.Height * LastCanvasScale);

  ResizeActiveRect;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

// размер или положение окна карты изменились (открыта/закрыта боковая панель,
// изменен размер формы): масштаб сохраняется, меняется видимая область
// (ActiveRect) - по новому размеру; сдвиг окна карты на форме учитывается,
// и изображение на экране остается на месте. Первый раз (масштаба еще нет) -
// прежняя область вписывается в окно
procedure TMainFormSkia.ResizeActiveRect;
var R: TogsRect;
    S: Double;
    P: TPointF;
begin
 S := Selector.GetScale;
 P := SkPainter.LocalToAbsolute(PointF(0, 0));
 R := TogsRect.Create;
 try
  R.Assign(Selector.ActiveRect);
  if (S > 0) and FPainterPosValid and (FDrawerSkia.Width > 0) and (FDrawerSkia.Height > 0) then begin
   R.XMin := R.XMin + (P.X - FPainterPos.X) * LastCanvasScale / S;
   R.YMin := R.YMin + (P.Y - FPainterPos.Y) * LastCanvasScale / S;
   R.XMax := R.XMin + FDrawerSkia.Width / S;
   R.YMax := R.YMin + FDrawerSkia.Height / S;
  end;
  Selector.ActiveRect := R;
 finally
  R.Free;
 end;
 FPainterPos := P;
 FPainterPosValid := True;
 Selector.UpdateRects(False);
end;

procedure TMainFormSkia.CenterMapOn(WX, WY: Double);
var R: TogsRect;
    Dx, Dy: Double;
begin
 if (Selector = nil) or (Selector.ActiveRect = nil) or not Selector.ActiveRect.isRect then exit;
 R := TogsRect.Create;
 try
  R.Assign(Selector.ActiveRect);
  Dx := WX - (R.XMin + R.XMax) / 2;
  Dy := WY - (R.YMin + R.YMax) / 2;
  R.XMin := R.XMin + Dx;
  R.XMax := R.XMax + Dx;
  R.YMin := R.YMin + Dy;
  R.YMax := R.YMax + Dy;
  Selector.ActiveRect := R;
 finally
  R.Free;
 end;
 Selector.UpdateRects(True);
 ClearOverlayAllCaches;
 SceneDirty := True;
 if SkPainter <> nil then SkPainter.Redraw;
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
 // колесо остановилось: конец жеста - полный кадр вместо снимка
 if PanActive or ZoomActive then Exit;
 InteractionActive := False;
 BaseScale := 0;
 if SkPainter <> nil then SkPainter.Redraw;
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

// дуги дыр штриховки (THatchLot.Zeros) карты и ее блоков - заново, с числом
// точек дуги из настроек карты. При чтении они строятся с текущим
// Quants_For_Arcs, а настройки карты читаются после блоков (TForm.Load:
// Twigs с блоками, затем Settings); без пересчета блок, перечитанный позже
// (проверка перед сохранением), отличался бы от загруженного
procedure RecalcHatchArcs(Form: TForm2);
procedure Recalc(F: TForm2);
var I, J: Integer;
    L: TObject;
begin
 if (F = nil) or (F.Twigs = nil) then exit;
 for I := 0 to F.Twigs.LotsCount - 1 do begin
  L := TObject(F.Twigs.LAt(I));
  if L is THatchLot then
   for J := 0 to THatchLot(L).Zeros.Count - 1 do THatchLot(L).Zero[J].Calculate;
 end;
end;
var I: Integer;
    B: TObject;
begin
 if (Form = nil) or (Form.Settings = nil) or (Form.Settings.psArcCount <= 0) then exit;
 Quants_For_Arcs := Form.Settings.psArcCount;
 Recalc(Form);
 if Form.Twigs.BlockList = nil then exit;
 for I := 0 to Form.Twigs.BlockList.Count - 1 do begin
  B := TObject(Form.Twigs.BlockList[I]);
  if B is TGeoBlock then Recalc(TGeoBlock(B).TwgForm);
 end;
end;

procedure TMainFormSkia.OpenGmfFileSkia(const LocalPath: string);
var
  Path: String;
  Src: string;
  Sel: TSelector;
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
begin
  if (LocalPath = '') or FMapLoading then Exit;
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
  Selector.GNForm := TControl(skPainter);
  ApplicationMainForm := Self;
 // прежняя карта (TwgForm) остается до конца чтения: на нее ссылаются фреймы
 // знаков и слоев; освобождается после установки новой (FinishOpenGmf)
 // чтение файла (с построением классов Build1 в LoadClassLib) - в фоновом
 // потоке, индикатор крутится; установка карты на экран - в главном потоке
  FMapLoading := True;
  StartIndicator;
  Src := LocalPath;
  Sel := Selector;
  TThread.CreateAnonymousThread(
   procedure
   var Stream: TBufStream;
       F: TForm2;
       Err: string;
   begin
    F := nil;
    Err := '';
    try
     Stream := TBufStream.InitFileStream(Src, fmOpenRead);
     try
      Stream.Selector := Sel;
      F := TForm2(Stream.Get);
     finally
      Stream.Free;
     end;
    except
     on E: Exception do Err := E.Message;
    end;
    if (F = nil) and (Err = '') then Err := 'файл не прочитан';
    TThread.Queue(nil,
     procedure
     begin
      FinishOpenGmf(Src, F, Err);
     end);
   end).Start;
end;

procedure TMainFormSkia.FinishOpenGmf(const LocalPath: string; F: TForm2; const Err: string);
var
  I: Integer;
  B: Byte;
  PP: TPointDot;
  Old: TForm2;
  NewMap: Boolean;
  MapPath: string;
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
  Old := TwgForm;
  NewMap := F <> nil;
  MapPath := LocalPath;
  try
    FMapLoading := False;
    if not NewMap then
    begin
      WriteIn(['Карта не открыта: ', Err]);
      TDialogService.ShowMessage('Карта не открыта: ' + Err);
     // Selector очищен перед чтением - прежняя карта устанавливается заново
      if Old = nil then Exit;
      F := Old;
      Old := nil;
      MapPath := F.About.Path + F.About.MyName;
    end;
    TwgForm := F;
    Old.Free;
    TwgForm.About.Path := ExtractFilePath(MapPath);
    TwgForm.About.MyName := ExtractFileName(MapPath);
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
    RecalcHatchArcs(TwgForm);
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
   // карта прочитана: дубликат успешно открытого файла рядом, расширение .gm2
    if NewMap and SameText(ExtractFileExt(LocalPath), '.gmf') then
      try
        TFile.Copy(LocalPath, ChangeFileExt(LocalPath, '.gm2'), True);
      except
        on E: Exception do WriteIn(['Копия .gm2 не создана: ', E.Message]);
      end;

    InitSkPainterInput;
    SkPainterResize(SkPainter);
    SyncStatusButtons;
    if (FSettingsFrame <> nil) and FSettingsFrame.Visible then FSettingsFrame.ResetSettings(TwgForm);
    GlobalRender := False;
  //  if SkPainter <> nil then
   //   SkPainter.Redraw;
    SkPainterDblClick(nil);
    if NewMap then ShowMapFragment;
    btnPaintClick(nil);
  finally
    StopIndicator;
  end;
  if TwgForm <> nil then MapOpened(MapPath, NewMap);
end;

procedure TMainFormSkia.MapOpened(const LocalPath: string; NewMap: Boolean);
begin
end;

// окно - на фрагмент, сохраненный в файле (TForm1.Store: About.Fragment = GRect).
// Пропорции окна могли измениться: фрагмент целиком, по центру окна. Фрагмента
// нет или он вне карты - остается вся карта (FitView)
procedure TMainFormSkia.ShowMapFragment;
var S: TSect;
    X1, Y1, X2, Y2, CX, CY, DW, DH, K: Double;
    R: TogsRect;
    G: TogsRect;
begin
 if (TwgForm = nil) or (Selector = nil) or (FDrawerSkia = nil) then exit;
 S := TwgForm.About.Fragment;
 if IsNan(S.Left) or IsNan(S.Right) or IsNan(S.Top) or IsNan(S.Bottom) or
    IsInfinite(S.Left) or IsInfinite(S.Right) or IsInfinite(S.Top) or IsInfinite(S.Bottom) then exit;
 X1 := Min(S.Left, S.Right);
 X2 := Max(S.Left, S.Right);
 Y1 := Min(S.Top, S.Bottom);
 Y2 := Max(S.Top, S.Bottom);
 DW := FDrawerSkia.Width;
 DH := FDrawerSkia.Height;
 if (X2 - X1 < 0.001) or (Y2 - Y1 < 0.001) or (DW <= 0) or (DH <= 0) then exit;
 G := Selector.GlobalRect;
 if (X2 < G.XMin) or (X1 > G.XMax) or (Y2 < G.YMin) or (Y1 > G.YMax) then exit;
 K := Max((X2 - X1) / DW, (Y2 - Y1) / DH);
 CX := (X1 + X2) / 2;
 CY := (Y1 + Y2) / 2;
 R := TogsRect.CreateRect(CX - K * DW / 2, CY - K * DH / 2, CX + K * DW / 2, CY + K * DH / 2);
 try
  Selector.ActiveRect := R;
 finally
  R.Free;
 end;
 Selector.UpdateRects;
end;

// окно сохранения - после закрытия окна выбора (облако вызывает ACallback до
// своего закрытия)
procedure TMainFormSkia.OpenPickedMap(const LocalPath: string);
var Src: string;
begin
 if LocalPath = '' then exit;
 Src := LocalPath;
 TThread.ForceQueue(nil,
  procedure
  begin
   CopyMapToUserFolder(Src,
    procedure(Path: string)
    begin
     if Path <> '' then OpenGmfFileSkia(Path);
    end);
  end);
end;

procedure TMainFormSkia.btnOpenClickSkia(Sender: TObject);
begin
 {$IFDEF ANDROID}
 PickGmfFile(OpenPickedMap);
{$ELSE}
 PickGmfFileWin64;
{$ENDIF}
end;

procedure TMainFormSkia.btnLocalOpenClickSkia(Sender: TObject);
begin
  localOpenForm := TlocalOpenForm.Create(Self);
{$IFDEF ANDROID}
  localOpenForm.BaseDir := UserMapsDir; // папка карт исполнителя (Documents/подпапка)
{$ENDIF}
  localOpenForm.FCallBack := OpenGmfFileSkia;
  ShowDialog(localOpenForm); // модально: Windows - окно, Android - панель поверх формы
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
// примитив добавлен/удален/изменен - точки сегментов собираются заново
 FSegPointsDirty := True;
 FUnderlayOnly := False;
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
  if PanelXY <> nil then PanelXY.Text := S;
  if PanelHint <> nil then PanelHint.Text := Hint;
end;
//
procedure TMainFormSkia.StatusButtonEnter(Sender: TObject);
begin
 if PanelHint <> nil then PanelHint.Text := TControl(Sender).Hint;
end;

procedure TMainFormSkia.StatusButtonLeave(Sender: TObject);
begin
 if PanelHint <> nil then PanelHint.Text := '';
end;

procedure TMainFormSkia.SyncStatusButtons;
begin
 if (TwgForm = nil) or (Selector = nil) or (SbShowPoints = nil) then exit;
 FStatusSync := True;
 try
  SbShowPoints.IsPressed := Selector.GGraphSet.PointView = 1;
  sbShowZnak.IsPressed := Selector.GGraphSet.ViewZnaks = 1;
  SbSaveOrthoTwigs.IsPressed := TwgForm.Settings.psSaveOrthoTwigs;
  sbShowGrid.IsPressed := TwgForm.Settings.gsShowGrid;
  sbOrthoDraw.IsPressed := TwgForm.Settings.psOrthoMode;
  if Selector.GlobalSettings <> nil then sbShowPlan.IsPressed := Selector.GlobalSettings.Settings.gsShowPlan;
 finally
  FStatusSync := False;
 end;
end;

// масштаб 1:N по размеру пиксела 0.28 мм (как TMainFormOSM.TryEstimateScaleDenom)
procedure TMainFormSkia.UpdateScaleLabel;
var Denom: Double;
    S: string;
begin
 if (pMas = nil) or (Selector = nil) or (Selector.GetScale <= 0) then exit;
 Denom := LastCanvasScale / Selector.GetScale / 0.00028;
 S := 'М 1:' + IntToStr(Round(Denom));
 if pMas.Text <> S then pMas.Text := S;
end;

// панель установок - над строкой состояния, от кнопки ResSpeedBtn59
procedure TMainFormSkia.PlaceSettingsFrame;
var P: TPointF;
begin
 if (FSettingsFrame = nil) or (ResSpeedBtn59 = nil) then exit;
// у FMX абсолютные координаты контрола - это координаты клиентской области формы
 P := ResSpeedBtn59.LocalToAbsolute(PointF(0, 0));
 if P.X + FSettingsFrame.Width > ClientWidth then P.X := ClientWidth - FSettingsFrame.Width;
 if P.X < 0 then P.X := 0;
 FSettingsFrame.Position.Point := PointF(P.X, StatusBar.Position.Y - FSettingsFrame.Height);
end;

procedure TMainFormSkia.ResSpeedBtn59Click(Sender: TObject);
begin
 if TwgForm = nil then exit;
 if (FSettingsFrame <> nil) and FSettingsFrame.Visible then begin
  FSettingsFrame.ApplySettings;
  FSettingsFrame.Visible := False;
  exit;
 end;
 if FSettingsFrame = nil then begin
  FSettingsFrame := TSettingsFrame.Create(Self);
  FSettingsFrame.Parent := Self;
  FSettingsFrame.Align := TAlignLayout.None;
  FSettingsFrame.OnApply := SettingsFrameApply;
  FSettingsFrame.OnClose := SettingsFrameClose;
 end;
 FSettingsFrame.ResetSettings(TwgForm);
 PlaceSettingsFrame;
 FSettingsFrame.Visible := True;
 FSettingsFrame.BringToFront;
end;

procedure TMainFormSkia.SettingsFrameApply(Sender: TObject);
begin
 SyncStatusButtons;
 SceneDirty := True;
 ClearOverlayAllCaches;
 if SkPainter <> nil then SkPainter.Redraw;
end;

procedure TMainFormSkia.SettingsFrameClose(Sender: TObject);
begin
 if FSettingsFrame <> nil then FSettingsFrame.Visible := False;
end;

procedure TMainFormSkia.SbShowPointsClick(Sender: TObject);
begin
 if FStatusSync or (TwgForm = nil) or (Selector = nil) then exit;
 TwgForm.fGraphSet.PointView := Ord(SbShowPoints.IsPressed);
 Selector.GGraphSet.PointView := TwgForm.fGraphSet.PointView;
// точки выводятся поверх сцены (DrawSegmentPoints): картинки контуров не
// перезаписываются, кадр собирается заново из них
 FUnderlayOnly := False;
 if SkPainter <> nil then SkPainter.Redraw;
end;

// точки сегментов (TTwig.ShowPoints и TDot.Draw32 старой программы): вершины
// ветвей контуров видимых слоев по What - 0 (AllPoint, gsColorDot), 10 -
// узловые (UslPoint, gsColorUzl), 20 - твердые (TvdPoint, gsColorPoint).
// Собираются один раз в FSegPoints (мировые координаты), ветвь, общая для
// нескольких контуров, - один раз; при изменении карты пересобираются
// (FSegPointsDirty, число контуров и ветвей)
procedure TMainFormSkia.BuildSegmentPoints;
var I, K, J, C: Integer;
    Lot: TLot;
    Tw: TTwig;
    D: TDot;
    Used: TBits;
    Cnt: array[0..2] of Integer;
    PD: TPointDot;
    W: Byte;
procedure Add(Kind: Integer);
begin
 if Cnt[Kind] >= Length(FSegPoints[Kind]) then SetLength(FSegPoints[Kind], Max(256, 2 * Length(FSegPoints[Kind])));
 FSegPoints[Kind][Cnt[Kind]] := TPointF.Create(D.XDot, D.YDot);
 Inc(Cnt[Kind]);
end;
begin
 FSegPointsDirty := False;
 for K := 0 to 2 do begin FSegPoints[K] := nil; Cnt[K] := 0; end;
 FSegPointsLots := -1;
 FSegPointsTwigs := -1;
 FSegPointsAny := -1;
 if (TwgForm = nil) or (TwgForm.Twigs = nil) then exit;
 FSegPointsLots := TwgForm.Twigs.LotsCount;
 FSegPointsTwigs := TwgForm.Twigs.TwigsCount;
 FSegPointsAny := TwgForm.Twigs.AnyCount;
 Used := TBits.Create;
 try
  Used.Size := TwgForm.Twigs.TwigsCount;
  for I := 0 to TwgForm.Twigs.LotsCount - 1 do begin
   Lot := TwgForm.Twigs.LAt(I);
   if Lot.TypeLot = 254 then continue;
   if (Lot.ClassHandle <> nil) and (Lot.ClassHandle.Check = 0) then continue;
   for K := 0 to Lot.Coord.Count - 1 do begin
    J := Abs(TLong(Lot.Coord[K]).Num);
    if (J >= Used.Size) or Used[J] then continue;
    Used[J] := True;
    Tw := TwgForm.Twigs.TAt(J);
    if (Tw = nil) or (Tw.Closed = 254) then continue;
    for C := 0 to Tw.Coord.Count - 1 do begin
     D := Tw.Coord[C];
     case D.What of
      0: Add(0);
      10: Add(1);
      20: Add(2);
     end;
    end;
   end;
  end;
 finally
  Used.Free;
 end;
// твердые точки - каждый точечный примитив (знаки, блоки, подписи); удаленные
// и выключенных слоев - нет
 for I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
  D := TwgForm.Twigs.AAt(I, W);
  if W <> TWG_Point then continue;
  PD := TPointDot(D);
  if PD.Closed then continue;
  if (PD.ClassHandle <> nil) and (PD.ClassHandle.Check = 0) then continue;
  Add(2);
 end;
 for K := 0 to 2 do SetLength(FSegPoints[K], Cnt[K]);
end;

// атлас и положения точек сегментов для текущего масштаба: квадрат вида K -
// сторона 2 * gsPointSize + 1 px устройства, рамка цветом вида точки и заливка
// gsFillPointColor при gsFillPointCheck; положения - в мировых координатах,
// спрайт масштабируется 1 / Scale (пиксел атласа = пиксел устройства).
// DevScale - пикселей устройства в логическом, Scale - пикселей устройства в
// мировой единице
procedure TMainFormSkia.BuildSegmentAtlas(DevScale, Scale: Single; const Key: String);
var Flags: array[0..2] of Byte;
    Colors: array[0..2] of TAlphaColor;
    PointSize, Side, Border, K, I, N: Integer;
    FillCheck: Boolean;
    FillColor: TAlphaColor;
    Surf: ISkSurface;
    Paint: ISkPaint;
    R: TRectF;
    S, Half: Single;
    P: TPointF;
begin
 FSegXFormsDirty := False;
 FSegScale := Scale;
 FSegKey := Key;
 FSegAtlas := nil;
 FSegXForms := nil;
 FSegSprites := nil;
 Flags[0] := Selector.GGraphSet.AllPoint;
 Flags[1] := Selector.GGraphSet.UslPoint;
 Flags[2] := Selector.GGraphSet.TvdPoint;
 PointSize := 4;
 FillCheck := False;
 FillColor := TAlphaColors.Black;
 Colors[0] := TAlphaColors.Blue;
 Colors[1] := TAlphaColors.Red;
 Colors[2] := TAlphaColors.Lime;
 if Selector.GlobalSettings <> nil then with Selector.GlobalSettings.Settings do begin
  PointSize := gsPointSize;
  FillCheck := gsFillPointCheck;
  FillColor := TAlphaColor(gsFillPointColor) or $FF000000;
  Colors[0] := TAlphaColor(gsColorDot) or $FF000000;
  Colors[1] := TAlphaColor(gsColorUzl) or $FF000000;
  Colors[2] := TAlphaColor(gsColorPoint) or $FF000000;
 end;
 Border := Max(1, Round(DevScale));
 Side := 2 * Round(Max(1, PointSize) * DevScale) + 1;
// атлас: три квадрата в ряд с промежутком 1 px (без наложения при выборке)
 Surf := TSkSurface.MakeRaster(3 * (Side + 1), Side);
 if Surf = nil then exit;
 Surf.Canvas.Clear(TAlphaColors.Null);
 Paint := TSkPaint.Create;
 Paint.AntiAlias := False;
 for K := 0 to 2 do begin
  R := TRectF.Create(K * (Side + 1), 0, K * (Side + 1) + Side, Side);
  Paint.Color := Colors[K];
  Surf.Canvas.DrawRect(R, Paint);
  R.Inflate(-Border, -Border);
  Paint.Color := FillColor;
  if FillCheck then Surf.Canvas.DrawRect(R, Paint) else begin
   Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.Clear);
   Surf.Canvas.DrawRect(R, Paint);
   Paint.Blender := nil;
  end;
 end;
 FSegAtlas := Surf.MakeImageSnapshot;
// положения всех включенных точек
 N := 0;
 for K := 0 to 2 do if Flags[K] = 1 then Inc(N, Length(FSegPoints[K]));
 SetLength(FSegXForms, N);
 SetLength(FSegSprites, N);
 S := 1 / Scale;
 Half := Side / 2 * S;
 N := 0;
 for K := 0 to 2 do begin
  if Flags[K] <> 1 then continue;
  R := TRectF.Create(K * (Side + 1), 0, K * (Side + 1) + Side, Side);
  for I := 0 to High(FSegPoints[K]) do begin
   P := FSegPoints[K][I];
   FSegXForms[N] := TSkRotationScaleMatrix.Create(S, 0, P.X - Half, P.Y - Half);
   FSegSprites[N] := R;
   Inc(N);
  end;
 end;
end;

// вывод точек сегментов поверх сцены (канва в мировых координатах) одним
// DrawAtlas готовых примитивов; пересчет - только при изменении карты,
// масштаба или установок точек, сдвиг карты пересчета не требует; точки
// выводятся при высоте видимой области не больше FPoints (детализация)
procedure TMainFormSkia.DrawSegmentPoints(const C: ISkCanvas);
var M: TMatrix;
    Scale: Single;
    Key: String;
begin
 if (C = nil) or (TwgForm = nil) or (TwgForm.Twigs = nil) or (Selector = nil) then exit;
 if Selector.GGraphSet.PointView <> 1 then exit;
 if (Selector.GGraphSet.FPoints > 0) and (Abs(C.GetLocalClipBounds.Height) > Selector.GGraphSet.FPoints) then exit;
 M := C.GetLocalToDeviceAs3x3;
 Scale := Sqrt(Sqr(M.m11) + Sqr(M.m12));
 if Scale <= 0 then exit;
 if FSegPointsDirty or (FSegPointsLots <> TwgForm.Twigs.LotsCount) or (FSegPointsTwigs <> TwgForm.Twigs.TwigsCount) or (FSegPointsAny <> TwgForm.Twigs.AnyCount) then begin
  BuildSegmentPoints;
  FSegXFormsDirty := True;
 end;
 Key := Format('%d %d %d %g', [Selector.GGraphSet.AllPoint, Selector.GGraphSet.UslPoint, Selector.GGraphSet.TvdPoint, LastCanvasScale]);
 if Selector.GlobalSettings <> nil then with Selector.GlobalSettings.Settings do
  Key := Key + Format(' %d %d %d %d %d %d', [gsPointSize, Ord(gsFillPointCheck), gsFillPointColor, gsColorDot, gsColorUzl, gsColorPoint]);
 if FSegXFormsDirty or (FSegAtlas = nil) or (Key <> FSegKey) or (Abs(Scale - FSegScale) > 1E-6 * Scale) then BuildSegmentAtlas(LastCanvasScale, Scale, Key);
 if (FSegAtlas = nil) or (Length(FSegXForms) = 0) then exit;
 C.DrawAtlas(FSegAtlas, FSegXForms, FSegSprites, TSkBlendMode.Modulate, TSkSamplingOptions.Create(TSkFilterMode.Nearest, TSkMipmapMode.None));
end;

procedure TMainFormSkia.SbSaveOrthoTwigsClick(Sender: TObject);
begin
 if FStatusSync or (TwgForm = nil) then exit;
 TwgForm.Settings.psSaveOrthoTwigs := SbSaveOrthoTwigs.IsPressed;
 ClearOverlayAllCaches;
 if SkPainter <> nil then SkPainter.Redraw;
end;

procedure TMainFormSkia.sbShowGridClick(Sender: TObject);
begin
 if FStatusSync or (TwgForm = nil) then exit;
 TwgForm.Settings.gsShowGrid := sbShowGrid.IsPressed;
 if (FSettingsFrame <> nil) and FSettingsFrame.Visible then FSettingsFrame.cbShowGrid.IsChecked := sbShowGrid.IsPressed;
 if SkPainter <> nil then SkPainter.Redraw;
end;

procedure TMainFormSkia.sbShowZnakClick(Sender: TObject);
var I: Integer;
begin
 if FStatusSync or (TwgForm = nil) or (Selector = nil) then exit;
 TwgForm.fGraphSet.ViewZnaks := Ord(sbShowZnak.IsPressed);
 Selector.GGraphSet.ViewZnaks := TwgForm.fGraphSet.ViewZnaks;
 for I := 0 to TwgForm.LayerTable.LinearLayers.Count - 1 do TwgForm.LayerTable.LinearLayer[I].Znak := TwgForm.fGraphSet.ViewZnaks;
 SceneDirty := True;
 if SkPainter <> nil then SkPainter.Redraw;
end;

procedure TMainFormSkia.sbOrthoDrawClick(Sender: TObject);
begin
 if FStatusSync or (TwgForm = nil) then exit;
 TwgForm.Settings.psOrthoMode := sbOrthoDraw.IsPressed;
end;

procedure TMainFormSkia.sbShowPlanClick(Sender: TObject);
begin
 if FStatusSync or (Selector = nil) or (Selector.GlobalSettings = nil) then exit;
 Selector.GlobalSettings.Settings.gsShowPlan := sbShowPlan.IsPressed;
 if SkPainter <> nil then SkPainter.Redraw;
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
 // отладка скорости: контуры - из картинки / записаны заново / слой выключен /
 // вне экрана / видимые и из них меньше 2 пикселей; вершины видимых; время
  nCached, nRecorded, nHidden, nOff, nVis, nTiny, nVerts: Integer;
  SWDraw, SWRec: TStopwatch;
  VisR: TSect;
  ScalePix, SizePix: Double;
  procedure CountLot(L: TLot);
  var K: Integer;
  begin
   if (L.ClassHandle <> nil) and (L.ClassHandle.Check = 0) then begin Inc(nHidden); exit; end;
   if (L.XMax < VisR.XMin) or (L.XMin > VisR.XMax) or (L.YMax < VisR.YMin) or (L.YMin > VisR.YMax) then begin Inc(nOff); exit; end;
   Inc(nVis);
   SizePix := Max(L.XMax - L.XMin, L.YMax - L.YMin) * ScalePix;
   if SizePix < 2 then Inc(nTiny);
   for K := 0 to L.Coord.Count - 1 do Inc(nVerts, L.GetTwig(TwgForm.Twigs, K).Coord.Count);
  end;
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
            nCached := 0; nRecorded := 0; nHidden := 0; nOff := 0; nVis := 0; nTiny := 0; nVerts := 0;
            SWDraw := TStopwatch.Create; SWRec := TStopwatch.Create;
           // Self.Selector: внутри with GGraphSet имя Selector - поле записи;
           // видимая область - ActiveRect (у TSect из GRect YMin/YMax переставлены)
            VisR.XMin := Self.Selector.ActiveRect.XMin; VisR.XMax := Self.Selector.ActiveRect.XMax;
            VisR.YMin := Min(Self.Selector.ActiveRect.YMin, Self.Selector.ActiveRect.YMax);
            VisR.YMax := Max(Self.Selector.ActiveRect.YMin, Self.Selector.ActiveRect.YMax);
            ScalePix := Self.Selector.GetScale;
            for I := 0 to TwgForm.Twigs.LotsCount - 1 do
            begin
              Lot := TwgForm.Twigs.LAt(I);
              try
                if (Lot.TypeLot <> 254) {and (Lot.Closed = 1)} then
                begin
                  CountLot(Lot);
                  SkObj := Lot.DrawerObject;
                  if (not Lot.Modified) and (SkObj is TogsSkiaObject) and
                     (TogsSkiaObject(SkObj).Picture <> nil) then
                  begin
                    Inc(nCached);
                    SWDraw.Start;
                    Lot.SkiaDraw(FDrawerSkia.SkCanvas);
                    SWDraw.Stop;
                  end
                  else
                  begin
                    Inc(nRecorded);
                   // контур перезаписан (изменен) - и его точки сегментов
                    FSegPointsDirty := True;
                    SWRec.Start;
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
                    SWRec.Stop;
                  end;
                end;
              except
                Exit;
              end;
              Prog := Prog + 1;
            end;
            WriteIn(['Lots: всего=', TwgForm.Twigs.LotsCount, ' из картинки=', nCached, ' записано=', nRecorded,
              ' слой выкл=', nHidden, ' вне экрана=', nOff, ' видимых=', nVis, ' <2px=', nTiny, ' вершин видимых=', nVerts,
              ' мс вывод=', Round(SWDraw.Elapsed.TotalMilliseconds), ' мс запись=', Round(SWRec.Elapsed.TotalMilliseconds),
              ' масштаб px/ед=', FloatToStrF(ScalePix, ffGeneral, 6, 0),
              ' область X ', Round(VisR.XMin), '..', Round(VisR.XMax), ' Y ', Round(VisR.YMin), '..', Round(VisR.YMax)]);
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
           // if PPoint.Closed then  continue;
           // if PPoint.userObj <> nil then exit;
            try
              SkObj := PPoint.DrawerObject;
              if (not PPoint.Modified) and (SkObj is TogsSkiaObject) then begin
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
                if PPoint.Closed then  continue;
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

procedure TMainFormSkia.SetHint(Sender: TObject);
begin
 If Application.Hint <> '' then begin
  If Pos('#',Application.Hint) = 1 then exit;
  PanelHint.Text := Application.Hint;
 end else
  PanelHint.Text := '';
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
 if (ACanvas = nil) or (Selector = nil) or (Selector.GlobalRect = nil) or FMapLoading then exit;
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

// FitView - вся карта в окне: только из кода (после открытия карты); двойное
// нажатие на карте вид не меняет. Мышью - двойной щелчок средней кнопкой
// (SkPainterMouseDown)
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
 // WriteIn(['MouseUp', ' Btn=', Ord(Button)]);
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
 if WheelZoomTmr <> nil then begin WheelZoomTmr.Enabled := False; WheelZoomTmr.Enabled := True; end;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.SkPainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
var
  StepRatio: Single;
  PivotLocal: TPointF;
  PivotPix: TPointF;
  PivotGeo: TPointF;
begin
  if FDrawerSkia = nil then
    Exit;
  if Selector = nil then
    Exit;
 // Windows: два пальца обрабатывает TouchPinch
 if StylusPinch then begin
  Handled := True;
  exit;
 end;
  PanActive := False;
  Handled := True;
  InteractionActive := True;
  ZoomActive := True;
  PanActive := False;

  if (EventInfo.Distance <= 0) or (TInteractiveGestureFlag.gfEnd in EventInfo.Flags) then
  begin
    LastZoomDistance := 0;
    ResetInteractionState;
   // конец щипка: полный кадр вместо снимка
    if SkPainter <> nil then SkPainter.Redraw;
    Exit;
  end;

  if (EventInfo.Distance < 2) then
    Exit;

 // точка жеста - в координатах формы: переводится в координаты окна карты
 // (панель слева - instProperties - сдвигает SkPainter вправо)
  PivotLocal := SkPainter.AbsoluteToLocal(EventInfo.Location);

  if LastZoomDistance = 0 then
  begin
    LastZoomDistance := EventInfo.Distance;
    LastZoomPivot := PivotLocal;
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
    LastZoomPivot := PivotLocal;
    Exit;
  end;
  LastZoomDistance := EventInfo.Distance;

 // перемещение двумя пальцами - на сдвиг середины между пальцами, затем масштаб
 if Selector.GetScale <> 0 then Selector.Move(-(PivotLocal.X - LastZoomPivot.X) * LastCanvasScale / Selector.GetScale, -(PivotLocal.Y - LastZoomPivot.Y) * LastCanvasScale / Selector.GetScale);
  LastZoomPivot := PivotLocal;
  PivotPix := PointF(PivotLocal.X * LastCanvasScale, PivotLocal.Y * LastCanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, StepRatio);
  ClearOverlayAllCaches;

  if SkPainter <> nil then
    SkPainter.Redraw;
end;

// два пальца (Windows): сдвиг середины между пальцами - перемещение карты,
// изменение расстояния - масштаб вокруг середины; Center, Delta - точки формы
procedure TMainFormSkia.TouchPinch(Action: TStylusPinchAction; const Center, Delta: TPointF; Ratio: Single);
var L, PivotPix, PivotGeo: TPointF;
begin
 if (FDrawerSkia = nil) or (Selector = nil) or (SkPainter = nil) then exit;
// конец: полный кадр вместо снимка
 if Action = spEnd then begin
  ResetInteractionState;
  SkPainter.Redraw;
  exit;
 end;
 InteractionActive := True;
 ZoomActive := True;
 PanActive := False;
 if (Action = spBegin) or (Selector.GetScale = 0) then exit;
 if LastCanvasScale <= 0 then LastCanvasScale := 1;
 Selector.Move(-Delta.X * LastCanvasScale / Selector.GetScale, -Delta.Y * LastCanvasScale / Selector.GetScale);
// скачок расстояния (палец сорвался) - без масштаба
 if (Ratio > 1 / 1.8) and (Ratio < 1.8) and (Abs(Ratio - 1) > 0.0005) then begin
  L := SkPainter.AbsoluteToLocal(Center);
  PivotPix := PointF(L.X * LastCanvasScale, L.Y * LastCanvasScale);
  PivotGeo := PointF(Selector.XGeo(Round(PivotPix.X)), Selector.YGeo(Round(PivotPix.Y)));
  Selector.Scale(PivotGeo.X, PivotGeo.Y, Ratio);
 end;
 ClearOverlayAllCaches;
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
  FUnderlayOnly := False;
  if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormSkia.RedrawUnderlay;
begin
 if FSceneImage <> nil then FUnderlayOnly := True;
 if SkPainter <> nil then SkPainter.Redraw;
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
  WorldRect: TRectF;
  PrevWorld: Boolean;
  M: TMatrix;
  K, R: Single;
  W, H: Integer;
  Surf: ISkSurface;
  SnapDest: TRectF;
  SnapDone: Boolean;
const
  DebugDirectSkia = false;
var Clipped: Boolean;
// полный кадр сцены на канве C (Tx, Ty, ViewScale уже посчитаны)
procedure DrawScene(const C: ISkCanvas);
begin
 C.Save;
 try
  C.Translate(Tx, Ty);
  C.Scale(ViewScale, ViewScale);
  WorldRect := TRectF.Create(Single(Selector.GlobalRect.XMin), Single(Selector.GlobalRect.YMin), Single(Selector.GlobalRect.XMax), Single(Selector.GlobalRect.YMax));
  PrevWorld := FDrawerSkia.UseWorldCoords;
  FDrawerSkia.UseWorldCoords := True;
  try
   FDrawerSkia.BeginFrame(C, WorldRect);
   try
    RenderSceneToBackbufferSkia;
    DrawSegmentPoints(C);
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
begin
  T0 := TThread.GetTickCount64;
  Clipped := False;
  try
//  WriteIn(['SkPainterDraw enter', ' Dirty=', SceneDirty, ' PicNil=', FCachedPicture = nil, ' Cnt=', Iff(FDrawerSkia <> nil, FDrawerSkia.SkiaList.Count, -1), ' Dest=', ADest.Width, 'x', ADest.Height]);
    if (FDrawerSkia = nil) or FMapLoading then Exit;
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

        ResizeActiveRect;
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
       // масштаб канвы в пиксели устройства (без поворота), иначе снимок не делаем
        M := ACanvas.GetLocalToDeviceAs3x3;
        K := M.m11;
        if (K <= 0) or (Abs(M.m12) > 1E-4) or (Abs(M.m21) > 1E-4) or (Abs(M.m22 - K) > 1E-4) then K := 0;
        W := Ceil(ADest.Width * K);
        H := Ceil(ADest.Height * K);
        SnapDone := False;
       // идет сдвиг/масштаб: рисуем снимок со смещением и масштабом, без полной отрисовки
       // RedrawUnderlay: снимок годится, только если вид с момента снимка не менялся
        if FUnderlayOnly and ((FSnapGx <> Selector.GlobalRect.XMin) or (FSnapGy <> Selector.GlobalRect.YMin) or (FSnapDx <> Selector.GetDx) or (FSnapDy <> Selector.GetDy) or (FSnapScale <> ViewScale)) then FUnderlayOnly := False;
        if (InteractionActive or FUnderlayOnly) and (FSceneImage <> nil) and (K > 0) and (Abs(FSnapK - K) < 1E-4) and (FSceneImage.Width = W) and (FSceneImage.Height = H) and (FSnapScale > 0) then
        begin
         // точка снимка P0 переходит в P = P0 * S/S0 + (G0 + D0 - G - D) * S
          R := ViewScale / FSnapScale;
          ACanvas.Save;
          try
            ACanvas.Translate(Single((FSnapGx + FSnapDx - Selector.GlobalRect.XMin - Selector.GetDx) * ViewScale), Single((FSnapGy + FSnapDy - Selector.GlobalRect.YMin - Selector.GetDy) * ViewScale));
            ACanvas.Scale(R, R);
            ACanvas.DrawImageRect(FSceneImage, FSnapRect, TSkSamplingOptions.Create(TSkFilterMode.Linear, TSkMipmapMode.None));
          finally
            ACanvas.Restore;
          end;
          SnapDone := True;
        end;
       // полный кадр: рисуем в поверхность (снимок для жестов), затем выводим ее
        if not SnapDone and (K > 0) and (W > 0) and (H > 0) then
        begin
          Surf := ACanvas.MakeSurface(TSkImageInfo.Create(W, H));
          if Surf <> nil then
          begin
           // прозрачный фон: под снимком видна подложка (OSM в TMainFormOSM.PaintBefore)
            Surf.Canvas.Clear(TAlphaColors.Null);
            Surf.Canvas.Scale(K, K);
            Surf.Canvas.Translate(-ADest.Left, -ADest.Top);
            DrawScene(Surf.Canvas);
            FSceneImage := Surf.MakeImageSnapshot;
            FSnapRect := TRectF.Create(ADest.Left, ADest.Top, ADest.Left + W / K, ADest.Top + H / K);
            FSnapK := K;
            FSnapGx := Selector.GlobalRect.XMin;
            FSnapGy := Selector.GlobalRect.YMin;
            FSnapDx := Selector.GetDx;
            FSnapDy := Selector.GetDy;
            FSnapScale := ViewScale;
            ACanvas.DrawImageRect(FSceneImage, FSnapRect);
            SnapDone := True;
          end;
        end;
       // поверхность не создалась - прямая отрисовка, снимка нет
        if not SnapDone then
        begin
          FSceneImage := nil;
          DrawScene(ACanvas);
        end;
      end;
    end;

  finally
  if Clipped then ACanvas.Restore;
   // масштаб в строке состояния (после сдвига/зума и полного кадра)
    if not InteractionActive then UpdateScaleLabel;
    FUnderlayOnly := False;
    Dt := TThread.GetTickCount64 - T0;
   // отладка фризов: номер отрисовки сцены (растет при движении мыши - сцена
   // перерисовывается) и время, если 30 мс и больше
    Inc(GSceneDrawCount);
    if Dt >= 30 then WriteIn(['SkPainterDraw #', GSceneDrawCount, ' ms=', Dt]);
  end;
end;

initialization
// каталог настроек (Registry.ini, GWrite*) и словарей до открытия карты:
// Android - документы приложения (каталог библиотек APK только для чтения,
// словари развернуты в assets\internal = документы), Windows - каталог программы
{$IFDEF ANDROID}
 newProcs.MainPath := TPath.GetDocumentsPath + '/';
{$ELSE}
 newProcs.MainPath := TPath.GetLibraryPath;
{$ENDIF}
finalization
 FreeAndNil(GFontFiles);
end.

