unit MainFrmMouseObj;

interface

{$DEFINE MOUSE32}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmSkia, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.Skia, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, {$IFDEF MOUSE32}objMouse32{$ELSE}objMouse{$ENDIF}, System.IOUtils, WPTForm2,
  instPointSign, FMX.Ani, InstLineSign, InstBlockSign, InstLayerFrame,
  FramePropEditor, DlgRootPropEditor, StylusInput;

type
  TMainFormMouseObj = class(TMainFormSkia)
    ToolImageList: TImageList;
    ToolBarPaint: TToolBar;
    btnToolLine: TSpeedButton;
    btnToolPoint: TSpeedButton;
    btnToolPolyline: TSpeedButton;
    btnToolPolygon: TSpeedButton;
    btnToolSpline: TSpeedButton;
    btnToolArc: TSpeedButton;
    btnToolCircle: TSpeedButton;
    btnToolRect: TSpeedButton;
    btnToolParaline: TSpeedButton;
    btnToolMultiline: TSpeedButton;
    btnToolMultiAngle: TSpeedButton;
    btnToolText: TSpeedButton;
    Load: TButton;
    imgEsc: TImageList;
    instPanel: TPanel;
    Splitter2: TSplitter;
    FloatAnimation1: TFloatAnimation;
    btnInstLine: TSpeedButton;
    FloatAnimation3: TFloatAnimation;
    btnInstPoint: TSpeedButton;
    FloatAnimation4: TFloatAnimation;
    btnInstBlock: TSpeedButton;
    FloatAnimation2: TFloatAnimation;
    btnSelect: TSpeedButton;
    FloatAnimation5: TFloatAnimation;
    Splitter3: TSplitter;
    instProperties: TLayout;
    btnProperties: TSpeedButton;
    FloatAnimation6: TFloatAnimation;
    instHost: TLayout;
    btnDoc: TButton;
    Panel2: TPanel;
    btnEsc: TButton;
    Panel3: TPanel;
    cbOSM: TCheckBox;
    btnGPKGB: TButton;
    pnlView: TPanel;
    btnPlus1: TCornerButton;
    btnMinus1: TCornerButton;
    btnFrag: TCornerButton;
    btnPan: TCornerButton;
    ToolBarOZN: TToolBar;
  // панель ОЗН (бывшая pDendro старой программы MainSkinFormDendro): Tag - код
  // операции, как в старой программе. Бывший HelpContext: sbSetD 1, sbSetE 2,
  // sbSetK 3, cbOnlyAttr 4, sbGD 5, sbSetG 6, sbGI 7, sbGC 8, sbGR 9, sbNum 10,
  // sbNumUCH 11, sbNumUchDropDown 12, sbP2P 21, sSpeedButton40 22,
  // sSpeedButton39 23, UpDown1 24, sSpeedButton42 25, UpDown2 26
    ImageListOZN: TImageList;
    sbSetD: TSpeedButton;
    sbSetE: TSpeedButton;
    sbSetK: TSpeedButton;
    cbOnlyAttr: TCheckBox;
    sbGD: TSpeedButton;
    sbSetG: TSpeedButton;
    sbGI: TSpeedButton;
    sbGC: TSpeedButton;
    sbGR: TSpeedButton;
    sbNum: TSpeedButton;
    sbNumUCH: TSpeedButton;
    sbNumUchDropDown: TSpeedButton;
    dnrPerp: TSpeedButton;
    dnrZas: TSpeedButton;
    sbP2P: TSpeedButton;
    sSpeedButton40: TSpeedButton;
    sSpeedButton39: TSpeedButton;
  // бывшие TUpDown: пара кнопок-стрелок, Tag = 1 (вверх) / -1 (вниз)
    UpDown1: TLayout;
    UpDown1Up: TButton;
    UpDown1Down: TButton;
    sSpeedButton42: TSpeedButton;
    UpDown2: TLayout;
    UpDown2Up: TButton;
    UpDown2Down: TButton;
    SpeedButton6: TSpeedButton;
    sbCancel: TSpeedButton;
    LabelVer: TLabel;
    procedure OZNButtonApplyStyleLookup(Sender: TObject);
    procedure ToolButtonClick(Sender: TObject);
    procedure LoadClick(Sender: TObject);
    procedure btnEscClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToolInstClick(Sender: TObject);
    procedure instPanelResize(Sender: TObject);
    procedure btnPropertiesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGPKGBClick(Sender: TObject);
    procedure btnDocClick(Sender: TObject);
    procedure cbOSMChange(Sender: TObject);
    procedure btnPanClick(Sender: TObject);
    procedure btnPlusClick(Sender: TObject);
  private
   FMouseObject: TKeyMouseHook;
   FPropEditor: TPropEditorFrame;
   FOverlayPainter: TSkPaintBox;
   FOverlayInteractionImage: ISkImage;
   FOverlayInteractionValid: Boolean;
   FOverlayPendingRedraw: Boolean;
   FInteractionPrevActive: Boolean;
   FInteractionWatchTimer: TTimer;
   procedure CaptureOverlayInteractionImage;
   procedure SetMouseObject(const Value: TKeyMouseHook);
   procedure EnsureOverlayPainter;
   procedure OverlayDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
   procedure DrawOverlay(const ACanvas: ISkCanvas; const ADest: TRectF);
   procedure InteractionWatchTimer(Sender: TObject);
  // перо (StylusInput): наведение - движение мыши без нажатия, щелчок кнопкой
  // пера над экраном - правая кнопка
   procedure StylusHover(Action: TStylusHoverAction; const P: TPointF);
   procedure StylusButtonClick(const P: TPointF);
  protected
   InstPoints: TInstPointsFrame;
   InstLines : TInstLinesFrame;
   InstBlocks: TInstBlocksFrame;
   destructor Destroy; override;
   procedure Loaded; override;
   procedure SetTwgForm(const Value: TForm2); override;
   procedure SetSelectorParams; override;
  //
   procedure SkPainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
   procedure SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;
   procedure PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF); override;
   procedure PaintOverlayStatic(const ACanvas: ISkCanvas; const Rect: TRectF); override;
   procedure PaintOverlayLive(const ACanvas: ISkCanvas; const Rect: TRectF); override;
   procedure DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF); override;
   procedure UpdateEscButton(Index: Integer);
  // кнопки дендро (панель ОЗН) - в ToolButtonClick: True - кнопка обработана
  // (обрабатывает TMainFormDendro)
   function DendroButtonClick(Sender: TObject): Boolean; virtual;
   procedure ActivateToolsEvent(Sender: TObject);
  // кнопки установки знаков панели точечных знаков (objTopo32)
   procedure InstPointsTool(Sender: TObject; Opr: Integer);
   procedure InstPointsZnakSelected(Sender: TObject);
  // кнопки панели линейных знаков (objTopology32)
   procedure InstLinesTool(Sender: TObject; Opr: Integer);
  // кнопки панели блоков (objHotSpot32)
   procedure InstBlocksTool(Sender: TObject; Opr: Integer);
   procedure InstBlocksZnakSelected(Sender: TObject);
  // выбран слой в списке слоев - выделенные объекты переносятся в него
   procedure LayerSelected(Sender: TObject);
  //
   procedure OpenGmfFileSkia(const LocalPath: string); override;
  public
   procedure KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
   procedure KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState); override;
   procedure RequestOverlayRedraw;
   property OverlayPainter: TSkPaintBox read FOverlayPainter;
   property MouseObject: TKeyMouseHook read FMouseObject write SetMouseObject;
  end;

var
  MainFormMouseObj: TMainFormMouseObj;

// MOUSE32 (параметры проекта): обработчики мыши, перенесенные из Geomaster (Geomaster\*32)
implementation uses {$IFDEF MOUSE32}objMouseSelect32, objMouseDraw32, objEditMap32, FrameObjects, objTopo32, objTopology32, objHotSpot32, newBlock,
                    {$ELSE}objMouseSelect, objMouseDraw, objEditMapCaptureDbg, {$ENDIF}
                    objMouseView, UpdateMessages,
                    Writer, newSelector, LBN, newProcs, tstForm, OpenForm,
                    GPKGReader, DlgLocalOpen, FMX.Edit, TwgDraw, EcDot, EcLot, newResource
                    {$IFDEF ANDROID}, Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText{$ENDIF};

{$R *.fmx}

// версия сборки: Android - versionName (VerInfo_Keys) и versionCode (номер
// сборки VerInfo_Build) из манифеста APK; Windows - версия из ресурса exe
function AppVersion: String;
{$IFDEF ANDROID}
var Info: JPackageInfo;
{$ENDIF}
{$IFDEF MSWINDOWS}
var Major, Minor, Build: Cardinal;
{$ENDIF}
begin
 Result := '?';
 try
{$IFDEF ANDROID}
  Info := TAndroidHelper.Context.getPackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);
  if Info <> nil then Result := JStringToString(Info.versionName) + ' (' + IntToStr(Info.versionCode) + ')';
{$ENDIF}
{$IFDEF MSWINDOWS}
  if GetProductVersion(ParamStr(0), Major, Minor, Build) then Result := Format('%d.%d.%d', [Major, Minor, Build]);
{$ENDIF}
 except
 end;
end;

var
  OverlayStatLastTick: UInt64;
  OverlayStatCount: Integer;
  OverlayStatMaxDt: UInt64;
  OverlayDrawLastTick: UInt64;
  OverlayDrawCount: Integer;

procedure PrintGPKGLayers(const Reader: TGPKGReader);
var I: Integer;
    Layer: TGPKGLayer;
    Sample: TStringList;
begin
 if Reader = nil then exit;
 WriteIn(['layers: ', Reader.GetLayerCount]);
 for I := 0 to Reader.GetLayerCount - 1 do
 begin
  Layer := Reader.GetLayer(I);
  WriteIn([' layer ', I, ': ', Layer.TableName, ' | ', Layer.Identifier, ' | ', Layer.DataType]);
  if Layer.GeometryColumn <> '' then
   WriteIn(['  geom: ', Layer.GeometryColumn, ' | ', Layer.GeometryType, ' | srid=', Layer.SrsId, ' z=', Layer.HasZ, ' m=', Layer.HasM]);
  if Layer.SrsOrganization <> '' then
   WriteIn(['  srs: ', Layer.SrsOrganization, ':', Layer.SrsOrganizationCoordSysId]);
  WriteIn(['  bbox: ', Format('%.6f, %.6f, %.6f, %.6f', [Layer.MinX, Layer.MinY, Layer.MaxX, Layer.MaxY])]);
  if Layer.LastChange <> '' then
   WriteIn(['  last_change: ', Layer.LastChange]);
  if (Layer.GeometryColumn <> '') and SameText(Layer.DataType, 'features') then
  begin
   Sample := Reader.GetFeatureSample(Layer.TableName, 2);
   try
    if (Sample <> nil) and (Sample.Count > 0) then
     WriteIn(['  sample: ', Sample[0]]);
   finally
    Sample.Free;
   end;
  end;
 end;
end;

{ TMainFormMouseObj }

procedure TMainFormMouseObj.FormCreate(Sender: TObject);
begin
 LabelVer.Text := 'gmfv:' + AppVersion;
// загружаем uf,fhbns панелей
 instProperties.Width := GReadFloat(Name + '_instPropertiesW',  instProperties.Width);
 skPainter.Width := GReadFloat(Name + '_skPainterW',  skPainter.Width);
 instProperties.Visible := GReadInteger(Name + '_instPropertiesVis',  0) = 1;
 instPanel.Width:= GReadFloat(Name + '_instPanelW', instPanel.Width);
//
 LayerFrame := FindComponent('LayerFrame1') as TLayerFrame;
 if LayerFrame <> nil then LayerFrame.OnLayerSelected := LayerSelected;
//
 InstPoints := TInstPointsFrame.Create(instHost);
 InstLines := TInstLinesFrame.Create(nil);
 InstBlocks := TInstBlocksFrame.Create(nil);
//
 InstPoints.Parent := InstHost;
 InstLines.Parent := InstHost;
 InstBlocks.Parent := InstHost;
//
 InstPoints.Align := TAlignLayout.Client;
 InstLines.Align := TAlignLayout.Client;
 InstBlocks.Align := TAlignLayout.Client;
//
 InstPoints.Visible := False;
 InstLines.Visible := False;
 InstBlocks.Visible := False;
//
 ToolInstClick(btnInstPoint);
 btnPropertiesClick(btnProperties);
//
 FPropEditor := TPropEditorFrame.Create(instProperties);
 FPropEditor.Parent := instProperties;
{$IFDEF MOUSE32}
// меню выделенных объектов (FlyObjects.PMEditMap) - TEditMap берет его при
// создании; сам фрейм невидим, на экран выходит только его TPopup
 ObjectsFrame := TObjectsFrame.Create(Self);
 ObjectsFrame.Parent := Self;
 ObjectsFrame.HitTest := False;
 ObjectsFrame.SetBounds(0, 0, 0, 0);
{$ENDIF}
 FPropEditor.Align := TAlignLayout.Client;
 FPropEditor.Visible := True;
 FPropEditor.OnActivateSignInstrument := ActivateToolsEvent;
 PropEditorForm := FPropEditor;
// кнопки установки знаков в панели точечных знаков
 InstPoints.OnTool := InstPointsTool;
 InstPoints.OnZnakSelected := InstPointsZnakSelected;
 InstLines.OnTool := InstLinesTool;
 InstBlocks.OnTool := InstBlocksTool;
 InstBlocks.OnZnakSelected := InstBlocksZnakSelected;
//
 instPanel.OnResize := instPanelResize;
// перо: слушатели ставятся на вид уже созданной формы
 TThread.ForceQueue(nil, procedure begin InstallStylus(Self, StylusHover, StylusButtonClick); end);
end;

// перо над экраном - движение мыши без нажатия (резиновые линии, маркер,
// координаты), как мышь на Windows
procedure TMainFormMouseObj.StylusHover(Action: TStylusHoverAction; const P: TPointF);
var L: TPointF;
begin
 if (SkPainter = nil) or (Action = shExit) then exit;
 L := SkPainter.AbsoluteToLocal(P);
 SkPainterMouseMove(SkPainter, [], L.X, L.Y);
end;

// щелчок кнопкой пера над экраном - щелчок правой кнопкой мыши
procedure TMainFormMouseObj.StylusButtonClick(const P: TPointF);
var L: TPointF;
begin
 if SkPainter = nil then exit;
 L := SkPainter.AbsoluteToLocal(P);
 SkPainterMouseDown(SkPainter, TMouseButton.mbRight, [ssRight], L.X, L.Y);
 SkPainterMouseUp(SkPainter, TMouseButton.mbRight, [ssRight], L.X, L.Y);
end;

procedure TMainFormMouseObj.FormDestroy(Sender: TObject);
begin
  inherited;
// сохраняем  панели
 GWriteFloat(Name + '_instPropertiesW',  instProperties.Width);
 GWriteInteger(Name + '_instPropertiesVis',  ord(instProperties.Visible));
 GWriteFloat(Name + '_skPainterW',  skPainter.Width);
 GWriteInteger(Name + '_instPanelVis', ord(instPanel.Visible));
 GWriteFloat(Name + '_instPanelW', instPanel.Width);
end;

procedure TMainFormMouseObj.PaintOverlayStatic(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
  if (ACanvas = nil) or (MouseObject = nil) then
    Exit;
  MouseObject.DrawTempStatic(ACanvas, True);
end;

procedure TMainFormMouseObj.PaintOverlayLive(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
  if (ACanvas = nil) or (MouseObject = nil) then
    Exit;
  MouseObject.DrawTemp(ACanvas, True);
end;

procedure TMainFormMouseObj.instPanelResize(Sender: TObject);
begin
 if (InstPoints <> nil) and InstPoints.Visible and (InstPoints.Parent = InstHost) then
  InstPoints.RebuildTiles;
 if (InstLines <> nil) and InstLines.Visible and (InstLines.Parent = InstHost) then
  InstLines.RebuildTiles;
 if (InstBlocks <> nil) and InstBlocks.Visible and (InstBlocks.Parent = InstHost) then
  InstBlocks.RebuildTiles;
end;

procedure TMainFormMouseObj.LoadClick(Sender: TObject);
begin
{$IFDEF Android}
  OpenGmfFile(TPath.GetDocumentsPath+'/18.gmf')
{$ELSE}
  OpenGmfFile('C:\!!!ГЗ\Борт\29.gmf')
 //  OpenGmfFile('C:\!!!ГЗ\Борт\29488_ul._Generala_Belova,_vl._19,_korp._3Kam.gmf');
{$ENDIF}
end;

procedure TMainFormMouseObj.Loaded;
begin
  inherited;
  if FInteractionWatchTimer = nil then
  begin
    FInteractionPrevActive := InteractionBitmapActive;
    FOverlayPendingRedraw := False;
    FInteractionWatchTimer := TTimer.Create(Self);
    FInteractionWatchTimer.Interval := 30;
    FInteractionWatchTimer.Enabled := True;
    FInteractionWatchTimer.OnTimer := InteractionWatchTimer;
  end;
end;

procedure TMainFormMouseObj.OpenGmfFileSkia(const LocalPath: string);
begin
 if Selector<> nil then WriteIn(['1=', Selector.Drawer.ClassName]);
  MouseObject := nil;
 if Selector<> nil then WriteIn(['2=',Selector.Drawer.ClassName]);
  inherited;
 if Selector<> nil then WriteIn(['3=',Selector.Drawer.ClassName]);
  MouseObject := nil;
 if Selector<> nil then WriteIn(['4=',Selector.Drawer.ClassName]);
end;

procedure TMainFormMouseObj.SetTwgForm(const Value: TForm2);
var LF: TLayerFrame; ilVisible: Boolean;
begin
 WriteIn(['================1']);
 inherited;
 if InstPoints <> nil then InstPoints.ClearTilesAndResources;
 if InstLines <> nil then begin
  InstLines.ClearTilesAndResources;
  ilVisible := InstLines.Visible;
  InstLines.Free;
 end;
 if InstBlocks <> nil then InstBlocks.ClearTilesAndResources;
//
 InstLines := TInstLinesFrame.Create(nil);
 InstLines.Parent := InstHost;
 InstLines.Align := TAlignLayout.Client;
 InstLines.Visible := ilVisible;
 InstLines.OnTool := InstLinesTool;
//
 LF := FindComponent('LayerFrame1') as TLayerFrame;
 if LF <> nil then
  if Value <> nil then
   LF.LayerTable := Value.LayerTable
  else
   LF.LayerTable := nil;
//
 InstPoints.TwgForm := Value;
 InstLines.TwgForm  := Value;
 InstBlocks.TwgForm := Value;
// свойства по умолчанию новых примитивов - заново для новой карты ('по слою')
 if FPropEditor <> nil then FPropEditor.SetDefaultsForm(Value);
  WriteIn(['================2']);
 FreeAndNil(ListByName);
 ListByName:=TListByName.Create;
 ListByName.LoadFromFile(MainPath + 'attribs.ini'{'Names.txt'}, ''{oghObjectType(TwgForm)});
// FreeAndNil(ListByName);
 ListByDicts:=TListByName.Create;
 ListByDicts.LoadFromFile(MainPath + 'Dictionary_digits.txt', oghObjectType(TwgForm));
end;

function TMainFormMouseObj.DendroButtonClick(Sender: TObject): Boolean;
begin
 Result := False;
end;

procedure TMainFormMouseObj.ToolButtonClick(Sender: TObject);
var Op: Integer;
begin
 if Selector = nil then exit;
 if DendroButtonClick(Sender) then exit;
 if MouseObject <> nil then
  if MouseObject.LOperation = TSpeedButton(Sender).Tag then
   TSpeedButton(Sender).IsPressed := False;
//
 if not TSpeedButton(Sender).IsPressed then
   MouseObject := nil
 else begin
  Selector.LOperation := TSpeedButton(Sender).Tag;
  MouseObject := nil;
  Op := TSpeedButton(Sender).Tag;
  if Op = em_GetObject then
{$IFDEF MOUSE32}
  // выделение и редактирование (перенос objEditMap)
   MouseObject := TEditMap.Create(TwgForm, nil)
{$ELSE}
  // MouseObject := TMouseEditMap2.Create(TwgForm, nil)
   MouseObject := TMouseSelector.Create(TwgForm, nil)
{$ENDIF}
  else
  if (Sender = btnPan) or (Sender = btnFrag) then
{$IFDEF MOUSE32}
  // TMouseView еще не перенесен: пан - средней кнопкой
   exit
{$ELSE}
   MouseObject := TMouseView.Create(TwgForm, nil)
{$ENDIF}
  else
   MouseObject := TMousePainter.Create(TwgForm, nil);
 //
  MouseObject.OnAddPrim := UpdateMessage.AddPrim;
  MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 // выбранный объект делает свой слой активным в панели слоев
  if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
  MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
  MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
  UpdateEscButton(1);
 end
end;

procedure TMainFormMouseObj.ToolInstClick(Sender: TObject);
var TagV: Integer;
procedure UpdateSkPainter;
begin
 If (btnInstPoint.IsPressed) or (btnInstLine.IsPressed) or (btnInstBlock.IsPressed) then
  begin
 //  skPainter.Align := TAlignLayout.Left;
 //  InstPanel.Align := TAlignLayout.Right;
   InstPanel.Visible := True;
   Splitter2.Visible := True;
   Splitter2.Position.X := InstPanel.Position.X;
   skPainter.Align := TAlignLayout.Client;
  // InstPanel.Align := TAlignLayout.Client;
  end else begin
   InstPanel.Visible := False;
   Splitter2.Visible := False;
   skPainter.Align := TAlignLayout.Client;
  // btnEscClick(btnEsc);
  end;
end;
begin
// показываем панель знаков (точечные, линейные, блоки)
 TagV := TControl(Sender).Tag;
 If Sender <> btnInstPoint then btnInstPoint.IsPressed := False;
 If Sender <> btnInstLine then btnInstLine.IsPressed := False;
 If Sender <> btnInstBlock then btnInstBlock.IsPressed := False;
// if TwgForm = nil then exit;
//
 if InstPoints <> nil then
 begin
  InstPoints.Parent := nil;
  InstPoints.Visible := False;
 end;
 if InstLines <> nil then
 begin
  InstLines.Parent := nil;
  InstLines.Visible := False;
 end;
 if InstBlocks <> nil then
 begin
  InstBlocks.Parent := nil;
  InstBlocks.Visible := False;
 end;
//
 UpdateSkPainter;
case TagV of
  0:
   if btnInstPoint.IsPressed then
   begin
    InstPoints.Parent := InstHost;
    InstPoints.Align := TAlignLayout.Client;
    InstPoints.Visible := True;
    InstPoints.BringToFront;
   end;
  1:
   if btnInstLine.IsPressed then
   begin
    InstLines.Parent := InstHost;
    InstLines.Align := TAlignLayout.Client;
    InstLines.Visible := True;
    InstLines.BringToFront;
   end;
  2:
   if btnInstBlock.IsPressed then
   begin
    InstBlocks.Parent := InstHost;
    InstBlocks.Align := TAlignLayout.Client;
    InstBlocks.Visible := True;
    InstBlocks.BringToFront;
   end;
 end;
end;

procedure TMainFormMouseObj.UpdateEscButton(Index: Integer);
begin
 btnEsc.ImageIndex := Index;
end;

procedure TMainFormMouseObj.EnsureOverlayPainter;
begin
  Exit;
end;

procedure TMainFormMouseObj.InteractionWatchTimer(Sender: TObject);
var
  CurActive: Boolean;
begin
  CurActive := InteractionBitmapActive;

  if FInteractionPrevActive and (not CurActive) then
  begin
    if FOverlayPendingRedraw then
      RequestOverlayRedraw;
  end;

  FInteractionPrevActive := CurActive;
end;

procedure TMainFormMouseObj.RequestOverlayRedraw;
begin
  FOverlayPendingRedraw := True;
  InvalidateOverlayAll;
 if SkPainter <> nil then
    SkPainter.Redraw;
end;

procedure TMainFormMouseObj.btnPanClick(Sender: TObject);
begin
  inherited;
 //
end;

procedure TMainFormMouseObj.btnPlusClick(Sender: TObject);
begin
  inherited btnPlusClickSkia(Sender);
end;

procedure TMainFormMouseObj.btnPropertiesClick(Sender: TObject);
begin
// показываем/прячем TPropEditor
// btnProperties.IsPressed := not btnProperties.Visible;
 If btnProperties.IsPressed then begin
  instProperties.Position.X:= -100;
  instProperties.Visible := True;
  Splitter3.Visible := True;
  Splitter3.Position.X := instProperties.Width;
 end else begin
  instProperties.Visible := False;
  Splitter3.Visible := False;
 end;
 btnProperties.IsPressed := instProperties.Visible;
end;

procedure TMainFormMouseObj.Button1Click(Sender: TObject);
begin
// instHost.Width := instHost.Width +30;
 tsts2DF.Show;
end;

procedure TMainFormMouseObj.btnDocClick(Sender: TObject);
begin
 WriteIn(['log ', 100, ' ====================================================================']);
 inherited;
 localOpenForm := TlocalOpenForm.Create(Self);
{$IFDEF ANDROID}
 localOpenForm.BaseDir := GetAppExternalFilesDir;
{$ENDIF}
 localOpenForm.FCallback :=
  procedure(const LocalPath: string)
  begin
   if LocalPath <> '' then
    ShowMessage(LocalPath);
  end;
 localOpenForm.Show;
end;

procedure TMainFormMouseObj.CaptureOverlayInteractionImage;
var
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  C: ISkCanvas;
  ViewScale: Single;
  Tx, Ty: Single;
  W, H: Integer;
  Sel: TSelector;
begin
  if (SkPainter = nil) or (Selector = nil) or (MouseObject = nil) then
  begin
    FOverlayInteractionImage := nil;
    FOverlayInteractionValid := True;
    Exit;
  end;

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

  Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
  Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
  C.Save;
  try
    C.Translate(Tx, Ty);
    C.Scale(ViewScale, ViewScale);
    Sel := TSelector(Selector);
    if Sel <> nil then
    begin
      Inc(Sel.OverlayDrawOnlyDepth);
      try
        MouseObject.DrawTemp(C, False);
      finally
        Dec(Sel.OverlayDrawOnlyDepth);
      end;
    end
    else
      MouseObject.DrawTemp(C, False);
  finally
    C.Restore;
  end;

  Surface.Flush;
  FOverlayInteractionImage := Surface.MakeImageSnapshot;
  FOverlayInteractionValid := True;
end;

procedure TMainFormMouseObj.cbOSMChange(Sender: TObject);
begin
  inherited;
//
end;

procedure TMainFormMouseObj.DrawOverlay(const ACanvas: ISkCanvas; const ADest: TRectF);
var
  ViewScale: Single;
  Tx, Ty: Single;
begin
  if (ACanvas = nil) or (Selector = nil) then
    Exit;
  ViewScale := Single(Selector.GetScale);
  if ViewScale <= 0 then
    Exit;
  Tx := -Single(Selector.GlobalRect.XMin + Selector.GetDx) * ViewScale;
  Ty := -Single(Selector.GlobalRect.YMin + Selector.GetDy) * ViewScale;
  ACanvas.Save;
  try
    ACanvas.Translate(Tx, Ty);
    ACanvas.Scale(ViewScale, ViewScale);
    PaintAfter(ACanvas, ADest);
  finally
    ACanvas.Restore;
  end;
end;

procedure TMainFormMouseObj.OverlayDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var NowT: UInt64;
    Paint: ISkPaint;
begin
  if ACanvas = nil then
    Exit;
  ACanvas.Clear(TAlphaColors.Null);

  if InteractionBitmapActive then
    Exit;

  CaptureOverlayInteractionImage;

  if FOverlayInteractionImage <> nil then
  begin
    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;
    ACanvas.DrawImageRect(FOverlayInteractionImage, ADest, Paint);
  end;

  Inc(OverlayDrawCount);
  NowT := TThread.GetTickCount64;
  if (OverlayDrawLastTick = 0) then OverlayDrawLastTick := NowT;
  if (NowT - OverlayDrawLastTick) >= 1000 then
  begin
    WriteIn(['OverlayDraw fps=', OverlayDrawCount]);
    OverlayDrawLastTick := NowT;
    OverlayDrawCount := 0;
  end;
end;

procedure TMainFormMouseObj.DrawInteractionOverlay(const ACanvas: ISkCanvas; const ADest, ASceneDst: TRectF);
begin
  // legacy interaction overlay image is not used anymore;
  // overlay surfaces are composed in the base SkPainterDraw.
end;

procedure TMainFormMouseObj.SetMouseObject(const Value: TKeyMouseHook);
begin
 If MouseObject <> nil then MouseObject.Free;
 FMouseObject := Value;
 InvalidateOverlayAll;
 if SkPainter <> nil then
   SkPainter.Redraw;
end;

procedure TMainFormMouseObj.SetSelectorParams;
begin
 inherited;
 MouseObject := nil;
end;

procedure TMainFormMouseObj.ActivateToolsEvent(Sender: TObject);
var Btn: TSpeedButton;
begin
 If Sender = nil then exit;
 Btn := nil;
 If TPropRow(Sender).TypeName = 'PointType' then Btn := btnInstPoint else
 If TPropRow(Sender).TypeName = 'LineType' then Btn := btnInstLine else
 If TPropRow(Sender).TypeName = 'Block' then Btn := btnInstBlock;
//
 If Btn <> nil then begin
  Btn.IsPressed := True;
  ToolInstClick(Btn);
 end;
end;

procedure TMainFormMouseObj.btnEscClick(Sender: TObject);
var I: Integer;
begin
 For I := 0 to ComponentCount - 1 do
  If Components[I] is TSpeedButton then
   If (TSpeedButton(Components[I]).Tag > 0) and (TSpeedButton(Components[I]).isPressed) then
    begin
     TSpeedButton(Components[I]).isPressed := False;
     MouseObject := nil;
     Selector.UpdateOverlay;
     UpdateEscButton(0);
    end;
// операция, запущенная не кнопкой панели инструментов (установка знаков)
 if MouseObject <> nil then begin
  MouseObject := nil;
  Selector.UpdateOverlay;
  UpdateEscButton(0);
 end;
end;

// кнопка установки знаков (Opr - код операции objTopo32): обработчик мыши
// TMouseTopo, как TinstPoints.sbSetPointClick старой программы
procedure TMainFormMouseObj.InstPointsTool(Sender: TObject; Opr: Integer);
{$IFDEF MOUSE32}
var I: Integer;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if (Selector = nil) or (TwgForm = nil) then exit;
// кнопки инструментов рисования отжимаются
 for I := 0 to ComponentCount - 1 do
  if (Components[I] is TSpeedButton) and (TSpeedButton(Components[I]).GroupName = 'PaintTools') then TSpeedButton(Components[I]).IsPressed := False;
 TopoZnakNum := InstPoints.SelectedZnakNum;
 Selector.LOperation := Opr;
 MouseObject := nil;
 MouseObject := TMouseTopo.Create(TwgForm, nil);
 MouseObject.OnAddPrim := UpdateMessage.AddPrim;
 MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
 MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
 MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 UpdateEscButton(1);
{$ENDIF}
end;

// кнопки панели ОЗН: глиф в размер картинки (слой ImageListOZN), стиль
// кнопки по умолчанию уменьшает его до 16-18 пикселов
procedure TMainFormMouseObj.OZNButtonApplyStyleLookup(Sender: TObject);
var G: TFmxObject;
    B: TSpeedButton;
    D: TCustomDestinationItem;
begin
 if not (Sender is TSpeedButton) then exit;
 B := TSpeedButton(Sender);
 if not (B.Images is TCustomImageList) or (B.ImageIndex < 0) or (B.ImageIndex >= TCustomImageList(B.Images).Destination.Count) then exit;
 D := TCustomImageList(B.Images).Destination[B.ImageIndex];
 if D.Layers.Count = 0 then exit;
 G := B.FindStyleResource('glyphstyle');
 if G is TGlyph then begin
  TGlyph(G).Align := TAlignLayout.Center;
  TGlyph(G).Width := D.Layers[0].SourceRect.Width;
  TGlyph(G).Height := D.Layers[0].SourceRect.Height;
 end;
end;

// кнопка панели линейных знаков (Opr - код операции objTopology32): обработчик
// мыши TMouseTopology, как TinstLines.sbLineRotateClick старой программы
procedure TMainFormMouseObj.InstLinesTool(Sender: TObject; Opr: Integer);
{$IFDEF MOUSE32}
var I: Integer;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if (Selector = nil) or (TwgForm = nil) then exit;
// кнопки инструментов рисования отжимаются
 for I := 0 to ComponentCount - 1 do
  if (Components[I] is TSpeedButton) and (TSpeedButton(Components[I]).GroupName = 'PaintTools') then TSpeedButton(Components[I]).IsPressed := False;
 Selector.LOperation := Opr;
 MouseObject := nil;
 MouseObject := TMouseTopology.Create(TwgForm, nil);
 MouseObject.OnAddPrim := UpdateMessage.AddPrim;
 MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
 MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
 MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 UpdateEscButton(1);
{$ENDIF}
end;

// кнопка панели блоков (Opr - код операции objHotSpot32): обработчик мыши
// TMouseHotSpot с выбранным блоком, как TinstBlocks.sbSetPointClick старой программы
procedure TMainFormMouseObj.InstBlocksTool(Sender: TObject; Opr: Integer);
{$IFDEF MOUSE32}
var I: Integer;
    B: TObject;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if (Selector = nil) or (TwgForm = nil) then exit;
 B := InstBlocks.SelectedBlock;
 if not (B is TGeoBlock) then exit;
// кнопки инструментов рисования отжимаются
 for I := 0 to ComponentCount - 1 do
  if (Components[I] is TSpeedButton) and (TSpeedButton(Components[I]).GroupName = 'PaintTools') then TSpeedButton(Components[I]).IsPressed := False;
 Selector.LOperation := Opr;
 MouseObject := nil;
 MouseObject := TMouseHotSpot.Create(TwgForm, nil);
 TMouseHotSpot(MouseObject).Block := TGeoBlock(B);
 MouseObject.OnAddPrim := UpdateMessage.AddPrim;
 MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
 MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
 MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 UpdateEscButton(1);
{$ENDIF}
end;

// выбран другой блок: он становится устанавливаемым блоком
// (TinstBlocks.CBPointZnakClick старой программы)
procedure TMainFormMouseObj.InstBlocksZnakSelected(Sender: TObject);
{$IFDEF MOUSE32}
var B: TObject;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if not (MouseObject is TMouseHotSpot) then exit;
 B := InstBlocks.SelectedBlock;
 if not (B is TGeoBlock) then exit;
 TMouseHotSpot(MouseObject).Block := TGeoBlock(B);
 MouseObject.Return(InstBlocks);
{$ENDIF}
end;

// слой, выбранный в списке слоев, - выделенным объектам (контурам и точечным),
// которые еще не в нем; изменение с отменой (PropEditorForm.ApplyToObjects)
procedure TMainFormMouseObj.LayerSelected(Sender: TObject);
var L: TResource;
begin
 if (LayerFrame = nil) or (PropEditorForm = nil) then exit;
 L := LayerFrame.ActiveLayer;
 if L = nil then exit;
 if MouseObject = nil then exit;
 PropEditorForm.ApplyToObjects('SetLayer...', L,
  function(Obj: TObject): Boolean
  begin
   Result := ((Obj is TLot) or (Obj is TPointDot)) and (TTD(Obj).GetLayer <> L);
  end,
  procedure(Obj: TObject)
  begin
  end);
end;

// выбран другой знак: он становится знаком новых точек (в старой программе -
// пользовательское свойство 'Знак' и MouseObject.Return)
procedure TMainFormMouseObj.InstPointsZnakSelected(Sender: TObject);
begin
{$IFDEF MOUSE32}
 TopoZnakNum := InstPoints.SelectedZnakNum;
 if MouseObject is TMouseTopo then MouseObject.Return(InstPoints);
{$ENDIF}
end;

// клавиши - в обработчик мыши (выбор операции, Esc, Shift/Ctrl), кроме ввода
// в поля редактирования; только для перенесенных обработчиков (MOUSE32)
procedure TMainFormMouseObj.KeyDown(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
{$IFDEF MOUSE32}
var Hook: Boolean;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if (MouseObject <> nil) and (Key <> 0) and not ((Focused <> nil) and ((Focused.GetObject is TCustomEdit) or (Focused.GetObject is TCustomMemo))) then begin
  Hook := False;
  MouseObject.KeyDown(TwgForm, Key, Shift, Hook);
  if Hook then begin
   Key := 0;
   KeyChar := #0;
   exit;
  end;
 end;
{$ENDIF}
 inherited;
end;

procedure TMainFormMouseObj.KeyUp(var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
{$IFDEF MOUSE32}
var Hook: Boolean;
{$ENDIF}
begin
{$IFDEF MOUSE32}
// отпускание Shift/Ctrl передается всегда, иначе ShiftPress/ControlPress залипают
 if (MouseObject <> nil) and (Key <> 0) then begin
  Hook := False;
  MouseObject.KeyUp(TwgForm, Key, Shift, Hook);
 end;
{$ENDIF}
 inherited;
end;

procedure TMainFormMouseObj.btnGPKGBClick(Sender: TObject);
begin
 inherited;
 pickGpkgFile(
  procedure(const LocalPath: string)
  var Reader: TGPKGReader;
   Tables: TStringList;
   I: Integer;
   Layer: TGPKGLayer;
   Msg, S: string;
  begin
   if LocalPath = '' then exit;
   WriteIn(['gpkg: ', LocalPath]);
   try
    WriteIn(['size: ', TFile.GetSize(LocalPath)]);
   except
   end;
   Reader := TGPKGReader.Create(LocalPath);
   try
    if not Reader.Open then
    begin
     ShowMessage('open gpkg failed');
     exit;
    end;
    PrintGPKGLayers(Reader);
    Msg := 'file: ' + LocalPath + sLineBreak;
    try
     Msg := Msg + 'size: ' + IntToStr(TFile.GetSize(LocalPath)) + sLineBreak;
    except
    end;
    Msg := Msg + sLineBreak;

    Tables := Reader.GetTableNames;
    try
     Msg := Msg + 'tables:' + sLineBreak;
     for I := 0 to Tables.Count - 1 do
      Msg := Msg + ' ' + Tables[I] + sLineBreak;
    finally
     Tables.Free;
    end;
    Msg := Msg + sLineBreak;

    Msg := Msg + 'layers (gpkg_contents):' + sLineBreak;
    for I := 0 to Reader.GetLayerCount - 1 do
    begin
     Layer := Reader.GetLayer(I);
     S := Layer.TableName;
     if Layer.Identifier <> '' then S := S + ' | ' + Layer.Identifier;
     if Layer.DataType <> '' then S := S + ' | ' + Layer.DataType;
     if Layer.Description <> '' then S := S + sLineBreak + '  ' + Layer.Description;
     S := S + sLineBreak + '  bbox: ' +
      Format('%.6f, %.6f, %.6f, %.6f', [Layer.MinX, Layer.MinY, Layer.MaxX, Layer.MaxY]);
     if Layer.LastChange <> '' then S := S + sLineBreak + '  last_change: ' + Layer.LastChange;
     Msg := Msg + S + sLineBreak + sLineBreak;
    end;

    ShowMessage(Msg);
   finally
    Reader.Free;
   end;
  end);
end;

destructor TMainFormMouseObj.Destroy;
begin
 FreeAndNil(instPoints);
 FreeAndNil(instLines);
 FreeAndNil(instBlocks);
   WriteIn(['Mouse1']);
  if FInteractionWatchTimer <> nil then
  begin
    FInteractionWatchTimer.Enabled := False;
    FInteractionWatchTimer.Free;
    FInteractionWatchTimer := nil;
  end;
  if FOverlayPainter <> nil then begin
   FOverlayPainter.Free;
   FOverlayPainter := nil;
  end;
 //
  if FMouseObject <> nil then begin
   FMouseObject.Free;
   FMouseObject := nil;
  end;
   WriteIn(['Mouse2']);
  inherited Destroy;
end;

procedure TMainFormMouseObj.SkPainterMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
 Hook := False;
// средняя кнопка (перемещение карты) - всегда форме, в обработчик мыши не попадает
 If Button = TMouseButton.mbMiddle then begin
  inherited;
  exit;
 end;
// работа пером: палец только перемещает карту; перо с нажатой кнопкой - правая кнопка
 If FingerOnlyPans then begin
  inherited;
  exit;
 end;
 If StylusRightButton then begin
  Button := TMouseButton.mbRight;
  Shift := Shift - [ssLeft] + [ssRight];
 end;
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseDown(TwgForm, Button, Shift, XGeo, YGeo, Hook);
  if not Hook then
    inherited;
 end else
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
    T0, T1: UInt64;
begin
 Hook := False;
 MousePos := PointF(X, Y);
// карта перемещается (нажато колесо или начато формой) - движение только форме:
// обработчики мыши перехватывают каждое движение (Hook) и обрывали перемещение
 If IsPanning or (ssMiddle in Shift) or FingerOnlyPans then begin
  inherited;
  UpdateStatusGeo(X, Y, '');
  exit;
 end;
 If StylusRightButton and (ssLeft in Shift) then Shift := Shift - [ssLeft] + [ssRight];
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  T0 := TThread.GetTickCount64;
  MouseObject.MouseMove(TwgForm, Shift, XGeo, YGeo, Hook);
  T1 := TThread.GetTickCount64;
  UpdateStatusGeo(X, Y, MouseObject.Hint);
  InvalidateOverlayLive;
 // live-слой (резиновые линии, рамка) перерисовывается без перерендера сцены
  RepaintLive;
 // отладка фризов: обработка движения инструментом и строка состояния 30 мс и больше
  if TThread.GetTickCount64 - T0 >= 30 then
   WriteIn(['MouseMove ', MouseObject.ClassName, ' tool ms=', T1 - T0, ' status+live ms=', TThread.GetTickCount64 - T1]);
 // if SkPainter <> nil then
 //   SkPainter.Redraw;
  if not Hook then
    inherited;
 end
 else begin
  inherited;
  UpdateStatusGeo(X, Y, '');
 end;
end;

procedure TMainFormMouseObj.SkPainterMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
 Hook := False;
// средняя кнопка (конец перемещения карты) - всегда форме
 If (Button = TMouseButton.mbMiddle) or FingerOnlyPans then begin
  inherited;
  RequestOverlayRedraw;
  exit;
 end;
 If StylusRightButton then begin
  Button := TMouseButton.mbRight;
  Shift := Shift - [ssLeft] + [ssRight];
 end;
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseUp(TwgForm, Button, Shift, XGeo, YGeo, Hook);
 // перемещение, начатое формой, заканчивает форма (иначе PanActive остался бы
 // включенным и обработчик мыши перестал бы получать движения)
  if not Hook or IsPanning then
  begin
    inherited;
    RequestOverlayRedraw;
  end;
 end else
  inherited;
end;

// колесо (масштабирование) - всегда форме, обработчикам мыши не передается
procedure TMainFormMouseObj.SkPainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var T0, Dt: UInt64;
begin
 T0 := TThread.GetTickCount64;
 inherited;
 RequestOverlayRedraw;
 Dt := TThread.GetTickCount64 - T0;
// WriteIn(['MWheel ms=', Dt]);
end;

procedure TMainFormMouseObj.PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF);
var T0, Dt: UInt64;
    NowT: UInt64;
begin
  // live overlay is drawn into the sfOverlayLive surface and composed in SkPainterDraw
end;

initialization
 RegisterClass(TLayerFrame);
finalization
 UnRegisterClass(TLayerFrame);
end.
