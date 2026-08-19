unit MainFrmMouseObj;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmSkia, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.Skia, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, objMouse, System.IOUtils, WPTForm2, instPointSign, FMX.Ani,
  InstLineSign, InstBlockSign, InstLayerFrame, FramePropEditor, DlgRootPropEditor;

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
    btnEsc: TCornerButton;
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
    Button1: TButton;
    btnGPKGB: TButton;
    btnDoc: TButton;
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
   procedure ActivateToolsEvent(Sender: TObject);
  //
   procedure OpenGmfFileSkia(const LocalPath: string); override;
  public
   procedure RequestOverlayRedraw;
   property OverlayPainter: TSkPaintBox read FOverlayPainter;
   property MouseObject: TKeyMouseHook read FMouseObject write SetMouseObject;
  end;

var
  MainFormMouseObj: TMainFormMouseObj;

implementation uses objMouseSelect, objMouseDraw, objEditMap, UpdateMessages,
                    Writer, newSelector, LBN, newProcs, tstForm, OpenForm,
                    GPKGReader, DlgLocalOpen;

{$R *.fmx}

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
// загружаем uf,fhbns панелей
 instProperties.Width := GReadFloat(Name + '_instPropertiesW',  instProperties.Width);
 skPainter.Width := GReadFloat(Name + '_skPainterW',  skPainter.Width);
 instProperties.Visible := GReadInteger(Name + '_instPropertiesVis',  0) = 1;
 instPanel.Width:= GReadFloat(Name + '_instPanelW', instPanel.Width);
//
 LayerFrame := FindComponent('LayerFrame1') as TLayerFrame;
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
 FPropEditor.Align := TAlignLayout.Client;
 FPropEditor.Visible := True;
 FPropEditor.OnActivateSignInstrument := ActivateToolsEvent;
 PropEditorForm := FPropEditor;
//
 instPanel.OnResize := instPanelResize;
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
  OpenGmfFile('C:\!!!ГЗ\Борт\19.gmf')
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
  WriteIn(['================2']);
 FreeAndNil(ListByName);
 ListByName:=TListByName.Create;
 ListByName.LoadFromFile(MainPath+'Names.txt', oghObjectType(TwgForm));
 FreeAndNil(ListByName);
 ListByDicts:=TListByName.Create;
 ListByDicts.LoadFromFile(MainPath + 'Dictionary_digits.txt', oghObjectType(TwgForm));
end;

procedure TMainFormMouseObj.ToolButtonClick(Sender: TObject);
var Op: Integer;
begin
 if Selector = nil then exit;
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
   MouseObject := TMouseEditMap.Create(TwgForm, nil)
  else
   MouseObject := TMousePainter.Create(TwgForm, nil);
  MouseObject.OnAddPrim := UpdateMessage.AddPrim;
  MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
  MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
  MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
  UpdateEscButton(1);
 end
end;

procedure TMainFormMouseObj.ToolInstClick(Sender: TObject);
var
 TagV: Integer;
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
  end;
end;
begin
// показываем панель знаков (точечные, линейные, блоки)
 TagV := TControl(Sender).Tag;
 If Sender <> btnInstPoint then btnInstPoint.IsPressed := False;
 If Sender <> btnInstLine then btnInstLine.IsPressed := False;
 If Sender <> btnInstBlock then btnInstBlock.IsPressed := False;
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
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseDown(TwgForm, Button, Shift, XGeo, YGeo, Hook);
  if (Button = TMouseButton.mbMiddle) or (not Hook) then
    inherited;
 end else
  inherited;
end;

procedure TMainFormMouseObj.SkPainterMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
var Hook: Boolean;
    XPix, YPix, XGeo, YGeo: Double;
begin
 Hook := False;
 MousePos := PointF(X, Y);
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseMove(TwgForm, Shift, XGeo, YGeo, Hook);
  UpdateStatusGeo(X, Y, MouseObject.Hint);
  InvalidateOverlayLive;
  if SkPainter <> nil then
    SkPainter.Redraw;
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
 If MouseObject <> nil then begin
  XPix := X * LastCanvasScale; YPix := Y * LastCanvasScale;
  XGeo := Selector.XGeo(Round(XPix)); YGeo := Selector.YGeo(Round(YPix));
  MouseObject.MouseUp(TwgForm, Button, Shift, XGeo, YGeo, Hook);
  if (Button = TMouseButton.mbMiddle) or (not Hook) then
  begin
    inherited;
    RequestOverlayRedraw;
  end;
 end else
  inherited;
end;

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
