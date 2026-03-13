unit MainFrm;

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
     FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
     FMX.Controls.Presentation, FMX.StdCtrls, System.Skia, FMX.Skia,
     FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.ImageList, FMX.ImgList,
     FMX.Objects,
     WptForm2, newSelector, ogcDrawerCanvas;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    Splitter1: TSplitter;
    Panel1: TPanel;
    CornerButton1: TCornerButton;
    ImageList1: TImageList;
    CornerButton3: TCornerButton;
    PanelPainter: TPanel;
    Painter: TPaintBox;
    btnPaint: TCornerButton;
    StatusBar: TStatusBar;
    upm: TCornerButton;
    Label1: TSkLabel;
    procedure btnOpenClick(Sender: TObject);
    procedure btnLocalOpenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PainterPaint(Sender: TObject; Canvas: TCanvas);
    procedure btnPaintClick(Sender: TObject);
    procedure upmClick(Sender: TObject);
  private
    StatusLabel: TLabel;
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
    ZoomBaseDx: Double;
    ZoomBaseDy: Double;
    ZoomBaseScale: Double;
    procedure PainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PainterMouseLeave(Sender: TObject);
    procedure PainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure PainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure PainterDblClick(Sender: TObject);
    procedure ResetInteractionState;
    procedure FinalizeZoom;
    procedure UpdateStatusGeo(const X, Y: Single);
    procedure InitPainterInput;
    procedure SaveBackbufferToFile(const Tag: string);
    procedure RenderSceneToBackbuffer(const Canvas: TCanvas);
  public
    TwgForm: TForm2;
    Selector: TSelector;
    Drawer: TogsDrawerCanvas;
    objectRepaintAccess: boolean;
    SceneDirty: boolean;
    PanActive: Boolean;
    LastPanPoint: TPointF;
    LastZoomDistance: Single;
    LastCanvasScale: Single;
    ZoomActive: Boolean;
    InteractionActive: Boolean;
    BaseDx, BaseDy, BaseScale: Double;
   procedure OpenGmfFile(const LocalPath: string);
  end;

var
  MainForm: TMainForm;

procedure  runFonts;

implementation uses Collect, uExecRegisterClass,
                    System.IOUtils, Writer, newProcs,
                    FMX.FontManager,
                    OpenForm, EcText, EcDot, EcDot2, EcLot,
                    RPrims, WPTwigs, DlgLocalOpen;

{$R *.fmx}

{$R *.XLgXhdpiTb.fmx ANDROID}

procedure TMainForm.btnPaintClick(Sender: TObject);
begin
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.btnLocalOpenClick(Sender: TObject);
begin
 localOpenForm := TlocalOpenForm.Create(Self);
 localOpenForm.FCallBack := OpenGmfFile;
 localOpenForm.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 LastCanvasScale := 1;
 Painter.AutoCapture := True;
 PanBitmap := nil;
 PanBitmapActive := False;
 ZoomBitmapActive := False;
 ZoomStartDistance := 0;
 ZoomFactor := 1;
 if (StatusBar <> nil) and (StatusLabel = nil) then begin
  StatusLabel := TLabel.Create(StatusBar);
  StatusLabel.Parent := StatusBar;
  StatusLabel.Align := TAlignLayout.Client;
 end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
 PanBitmap.Free;
 PanBitmap := nil;
 Drawer.Free;
 Selector.Free;
 Drawer := nil;
 Selector := nil;
end;

procedure TMainForm.OpenGmfFile(const LocalPath: string);
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
 begin
  Dir := ExtractFilePath(GmfLocalPath);
  if Dir = '' then Exit;
  try
   Files := TDirectory.GetFiles(Dir, '*.ttf');
   for F in Files do
    try
     TFontManager.AddCustomFontFromFile(F);
     TSkDefaultProviders.RegisterTypeface(F);
     RegisterSkiaTypefaceFromFile(F);
     WriteIn(['addfnt=', F]);
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
   For I := 0 to TFontManager.CustomFontInfoCount - 1 do
    WriteIn(['fm=',TFontManager.CustomFontInfo[I].FamilyName]);
 end;
 procedure localSetGabarites;
 var
  I, J: Integer;
  Twig: TTwig;
 begin
  for I := 1 to TwgForm.Twigs.TwigsCount - 1 do begin
   Twig := TwgForm.Twigs.TAt(I);
   for J := 0 to Twig.Coord.Count - 1 do
    Selector.AddCoord(Twig[J].XDot, Twig[J].YDot);
  end;
 end;
begin
 If Drawer = nil then begin
  Drawer := TogsDrawerCanvas.Create(nil, Round(Painter.Width * Canvas.Scale), Round(Painter.Height * Canvas.Scale), nil);
  Selector:= TSelector.Create(Drawer);
  Drawer.ogsSelector := Selector;
  Drawer.Name := 'Drawer';
  Drawer.ogsSelector.Name := 'Selector';
  Selector.Drawer.Name := 'Drawer';
 end else
  Selector.Clear;
 Memo1.Lines.Clear;
 InitPainterInput;
 GLines := Memo1.Lines;
 newProcs.MainPath := TPath.GetDocumentsPath;
 WriteIn(['Test1',  TPath.GetDocumentsPath]);
 RegPrimitives;
 WriteIn(['Registered']);
 objectRepaintAccess := False;
 Path := LocalPath;
 if LocalPath = '' then begin WriteIn(['Path Space']); Exit; end;
 WriteIn(['Path=', ExtractFilePath(LocalPath), SizeOf(Single), SizeOf(Double)]);
 newProcs.MainPath := ExtractFilePath(LocalPath);
//
 RegisterFontsNearGmf(LocalPath);
//
 Stream := TBufStream.InitFileStream(LocalPath, fmOpenRead);
 Selector.GNForm := TControl(Self);
 Selector.GNForm := TControl(Self);
 WriteIn(['s.Drawer=',Selector.Drawer=nil]);
 ApplicationMainForm := Self;
 Stream.Selector:=Selector;
 try
  FreeAndNil(TwgForm);
 //
  TwgForm := TForm2(Stream.Get);
  Selector.GLineCol:=TwgForm.MkLib.LSLib;
  Selector.GSqwearCol:=TwgForm.MkLib.SSLib;
  Selector.GPointCol:=TwgForm.MkLib.PSLib;
  Selector.GFontCollect:=TwgForm.Twigs.FontS;
  Selector.GFontSet :=TwgForm.Twigs.FontSet;
  Selector.GGraphSet:=TwgForm.fGraphSet;
  if TwgForm.FontColEx <> nil then
   begin
    for I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
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
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.InitPainterInput;
begin
 if Painter = nil then Exit;
 Painter.OnMouseDown := PainterMouseDown;
 Painter.OnMouseMove := PainterMouseMove;
 Painter.OnMouseUp := PainterMouseUp;
 Painter.OnMouseLeave := PainterMouseLeave;
 Painter.OnMouseWheel := PainterMouseWheel;
 Painter.OnGesture := PainterGesture;
 Painter.OnDblClick := PainterDblClick;
 Painter.Touch.InteractiveGestures := [TInteractiveGesture.Zoom];
end;

procedure TMainForm.PainterMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
 P: TPoint;
 PF: TPointF;
begin
 if Drawer = nil then Exit;
 if Selector = nil then Exit;
 InteractionActive := True;
 if BaseScale = 0 then begin
  BaseDx := Selector.fDx;
  BaseDy := Selector.fDy;
  BaseScale := Selector.fScale;
 end;
 if LastCanvasScale <= 0 then LastCanvasScale := 1;
 PF := Painter.AbsoluteToLocal(Screen.MousePos);
 P := Point(Round(PF.X * LastCanvasScale), Round(PF.Y * LastCanvasScale));
 SceneDirty := True;
 Drawer.MouseWheel(Sender, Shift, WheelDelta, P, Handled);
 InteractionActive := False;
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.PainterMouseLeave(Sender: TObject);
begin
 if Selector = nil then Exit;
 if InteractionActive or PanActive or (LastZoomDistance <> 0) then begin
  ResetInteractionState;
  SceneDirty := True;
  Painter.Repaint;
 end;
end;

procedure TMainForm.ResetInteractionState;
begin
 InteractionActive := False;
 PanActive := False;
 ZoomActive := False;
 LastZoomDistance := 0;
end;

procedure TMainForm.FinalizeZoom;
var
 PivotPix: TPointF;
 NewScale: Double;
 OldScale: Double;
 K0, K1: Double;
begin
 if Selector = nil then Exit;
 if not ZoomBitmapActive then Exit;
 if ZoomStartDistance <= 0 then begin
  ZoomBitmapActive := False;
  ZoomStartDistance := 0;
  ZoomFactor := 1;
  Exit;
 end;
 if LastCanvasScale <= 0 then LastCanvasScale := 1;
 OldScale := ZoomBaseScale;
 if OldScale = 0 then OldScale := Selector.fScale;
 if OldScale = 0 then Exit;
 if ZoomFactor <= 0 then Exit;

 PivotPix := PointF(ZoomPivot.X * LastCanvasScale, ZoomPivot.Y * LastCanvasScale);
 NewScale := OldScale * ZoomFactor;
 if NewScale = 0 then Exit;

 K0 := 1 / OldScale;
 K1 := 1 / NewScale;
 Selector.fScale := NewScale;
 Selector.fDx := ZoomBaseDx + PivotPix.X * (K0 - K1);
 Selector.fDy := ZoomBaseDy + PivotPix.Y * (K0 - K1);
 Selector.UpdateRects(False);
 SceneDirty := True;

 ZoomBitmapActive := False;
 ZoomStartDistance := 0;
 ZoomFactor := 1;
 ZoomActive := False;
 InteractionActive := False;
end;

procedure TMainForm.UpdateStatusGeo(const X, Y: Single);
var
 XPix, YPix: Double;
 XGeo, YGeo: Double;
 S: string;
begin
 if StatusBar = nil then Exit;
 if Selector = nil then Exit;
 if Selector.fScale = 0 then Exit;
 XPix := X * LastCanvasScale;
 YPix := Y * LastCanvasScale;
 XGeo :=Selector.XGeo(Round(X));
 YGeo :=Selector.YGeo(Round(Y));
 S := Fmt(['XGeo=', XGeo, 'YGeo=', YGeo, 'objRect=', Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
 if StatusLabel <> nil then StatusLabel.Text := S;
end;


procedure TMainForm.upmClick(Sender: TObject);
begin
 Memo1.ScrollTo(0, Memo1.Lines.Count);
end;

procedure TMainForm.PainterDblClick(Sender: TObject);
begin
 if Selector = nil then Exit;
 InteractionActive := False;
 PanActive := False;
 LastZoomDistance := 0;
 BaseScale := 0;
 Selector.UpdateRects(True);
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.PainterMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Selector = nil then Exit;
 if ZoomBitmapActive or ZoomActive then Exit;
 UpdateStatusGeo(X, Y);
 PanActive := True;
 ZoomActive := False;
 LastZoomDistance := 0;
 InteractionActive := True;
 PanBitmapActive := False;
 if (Drawer <> nil) and (Drawer.Bitmap <> nil) and (Drawer.Bitmap.Width > 0) and (Drawer.Bitmap.Height > 0) then begin
  if PanBitmap = nil then PanBitmap := TBitmap.Create;
  PanBitmap.Assign(Drawer.Bitmap);
  PanStartPoint := PointF(X, Y);
  PanShift := PointF(0, 0);
  PanBaseDx := Selector.fDx;
  PanBaseDy := Selector.fDy;
  PanBitmapActive := True;
 end;
 if BaseScale = 0 then begin
  BaseDx := Selector.fDx;
  BaseDy := Selector.fDy;
  BaseScale := Selector.fScale;
 end;
 LastPanPoint := PointF(X, Y);
end;

procedure TMainForm.PainterMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
 DxPix, DyPix: Single;
 DxGeo, DyGeo: Double;
begin
 if Selector = nil then Exit;
 UpdateStatusGeo(X, Y);
 if ZoomActive then Exit;
 if not PanActive then Exit;
 if PanBitmapActive then begin
  PanShift := PointF(X - PanStartPoint.X, Y - PanStartPoint.Y);
  Painter.Repaint;
  Exit;
 end;
 if Selector.fScale = 0 then Exit;
 DxPix := (X - LastPanPoint.X) * LastCanvasScale;
 DyPix := (Y - LastPanPoint.Y) * LastCanvasScale;
 LastPanPoint := PointF(X, Y);
 DxGeo := DxPix / Selector.fScale;
 DyGeo := DyPix / Selector.fScale;
 Selector.fDx := Selector.fDx - DxGeo;
 Selector.fDy := Selector.fDy - DyGeo;
 Selector.UpdateRects(False);
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.PainterMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 DxPix, DyPix: Double;
 DxGeo, DyGeo: Double;
begin
 if ZoomBitmapActive and (Selector <> nil) then FinalizeZoom;
 if PanBitmapActive and (Selector <> nil) and (Selector.fScale <> 0) then begin
  DxPix := PanShift.X * LastCanvasScale;
  DyPix := PanShift.Y * LastCanvasScale;
  DxGeo := DxPix / Selector.fScale;
  DyGeo := DyPix / Selector.fScale;
  Selector.fDx := PanBaseDx - DxGeo;
  Selector.fDy := PanBaseDy - DyGeo;
  Selector.UpdateRects(False);
 end;
 PanBitmapActive := False;
 ResetInteractionState;
 SceneDirty := True;
 Painter.Repaint;
end;

procedure TMainForm.PainterGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
 if Drawer = nil then Exit;
 if Selector = nil then Exit;
 PanBitmapActive := False;
 PanActive := False;
 Handled := True;
 if EventInfo.Distance <= 0 then begin
  FinalizeZoom;
  ResetInteractionState;
  Painter.Repaint;
  Exit;
 end;
 InteractionActive := True;
 ZoomActive := True;
 PanActive := False;
 if (not ZoomBitmapActive) and (ZoomStartDistance = 0) then begin
  ZoomStartDistance := EventInfo.Distance;
  ZoomFactor := 1;
  ZoomPivot := EventInfo.Location;
  ZoomBaseDx := Selector.fDx;
  ZoomBaseDy := Selector.fDy;
  ZoomBaseScale := Selector.fScale;
  if (Drawer.Bitmap <> nil) and (Drawer.Bitmap.Width > 0) and (Drawer.Bitmap.Height > 0) then begin
   if PanBitmap = nil then PanBitmap := TBitmap.Create;
   PanBitmap.Assign(Drawer.Bitmap);
   ZoomBitmapActive := True;
  end;
  Exit;
 end;
 if ZoomStartDistance <= 0 then Exit;
 ZoomFactor := EventInfo.Distance / ZoomStartDistance;
 if ZoomFactor < 0.05 then ZoomFactor := 0.05;
 if ZoomFactor > 20 then ZoomFactor := 20;
 Painter.Repaint;
end;

procedure TMainForm.RenderSceneToBackbuffer(const Canvas: TCanvas);
var
 I,J,N,CL,TWC,Counter:LongInt;Tw:TTwig;Lot:TLot;
 PP:Pointer;F:TEFont;PPoint:TPointDot;BMP:TBmpSet;
 B:Byte;
 Kl:SmallInt;
 W:Word;
 R:TRect;
{}
 TwgDc:hDc;
 UpLot:Boolean;
 LCo:Integer;
 Error:Integer;
 X1,X2,X3,X4:Double;
 NeedW, NeedH: Integer;
begin
 Error := 1;
 if Drawer = nil then Exit;
 if TwgForm = nil then Exit;
 if not objectRepaintAccess then Exit;
 GLines := nil;
 NeedW := Round(Painter.Width * Canvas.Scale);
 NeedH := Round(Painter.Height * Canvas.Scale);
 if (Drawer.Width <> NeedW) or (Drawer.Height <> NeedH) then begin
  Drawer.Width := NeedW;
  Drawer.Height := NeedH;
 end;
 Drawer.BeginPaint;
 Drawer.Clear(TAlphaColors.White);
  With Selector, GGraphset do try
   Error := 6;
   Error := 7;
   TWC := 0;
   begin
    If FillLot = 1 then begin
     For I := 0 to TwgForm.Twigs.IndexCount - 1 do begin
      Lot := TwgForm.Twigs.LAtIndex(I);
      try
       If (Lot.TypeLot <> 254) and (Lot.Closed = 1) then Lot.Draw32(TwgForm.Twigs);
      except
      // Lot.Draw32(TwgForm.Twigs);
       exit;
      end;
     end;
    end;
   end;
   For I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
    PP := TwgForm.Twigs.AAt(I, B);
    if (B = TWG_Point) then begin
     PPoint := PP;
     If PPoint.Closed then continue;
     try
      PPoint.Draw32(Drawer, TwgForm.MkLib.PSLib,TwgForm.FontColEx);
     except
     end;
    end;
   end;
   Error := 16;
  finally
   Drawer.EndPaint;
   For I := 0 to TwgForm.Twigs.TwigsCount - 1 do begin
    Tw := TwgForm.Twigs.TAt(I);
    Tw.isDraw := False;
   end;
  end;
  SceneDirty := False;
  BaseDx := Selector.fDx;
  BaseDy := Selector.fDy;
  BaseScale := Selector.fScale;
  SaveBackbufferToFile('render');
 end;

procedure TMainForm.SaveBackbufferToFile(const Tag: string);
var
 Dir: string;
 FileName: string;
 SafeTag: string;
begin
 if Drawer = nil then Exit;
 if Drawer.Bitmap = nil then Exit;
 if (Drawer.Bitmap.Width <= 0) or (Drawer.Bitmap.Height <= 0) then Exit;
 SafeTag := Tag;
 if SafeTag = '' then SafeTag := 'bmp';
 {$IFDEF ANDROID}
 Dir := TPath.GetSharedDownloadsPath;
 if Dir = '' then Dir := TPath.GetDocumentsPath;
 {$ELSE}
 Dir := TPath.GetDocumentsPath;
 {$ENDIF}
 try
  if not TDirectory.Exists(Dir) then TDirectory.CreateDirectory(Dir);
 except
  Exit;
 end;
 FileName := TPath.Combine(Dir, 'debug_' + SafeTag + '.png');
 try
  Drawer.Bitmap.SaveToFile(FileName);
 except
 end;
end;

procedure TMainForm.PainterPaint(Sender: TObject; Canvas: TCanvas);
var
 SrcRect, DstRect: TRectF;
 St: TCanvasSaveState;
 Pivot: TPointF;
 F: Single;
begin
 if Drawer = nil then Exit;
 LastCanvasScale := Canvas.Scale;
 if PanBitmapActive and (PanBitmap <> nil) then begin
  St := Canvas.SaveState;
  try
   Canvas.IntersectClipRect(Painter.LocalRect);
   SrcRect := RectF(0, 0, PanBitmap.Width, PanBitmap.Height);
   DstRect := RectF(Painter.LocalRect.Left + PanShift.X, Painter.LocalRect.Top + PanShift.Y, Painter.LocalRect.Right + PanShift.X, Painter.LocalRect.Bottom + PanShift.Y);
   Canvas.DrawBitmap(PanBitmap, SrcRect, DstRect, 1, True);
  finally
   Canvas.RestoreState(St);
  end;
  Exit;
 end;
 if ZoomBitmapActive and (PanBitmap <> nil) then begin
  Pivot := ZoomPivot;
  F := ZoomFactor;
  St := Canvas.SaveState;
  try
   Canvas.IntersectClipRect(Painter.LocalRect);
   SrcRect := RectF(0, 0, PanBitmap.Width, PanBitmap.Height);
   DstRect := RectF(Pivot.X + (Painter.LocalRect.Left - Pivot.X) * F,
                    Pivot.Y + (Painter.LocalRect.Top - Pivot.Y) * F,
                    Pivot.X + (Painter.LocalRect.Right - Pivot.X) * F,
                    Pivot.Y + (Painter.LocalRect.Bottom - Pivot.Y) * F);
   Canvas.DrawBitmap(PanBitmap, SrcRect, DstRect, 1, True);
  finally
   Canvas.RestoreState(St);
  end;
  Exit;
 end;
 if SceneDirty and (TwgForm <> nil) and objectRepaintAccess then RenderSceneToBackbuffer(Canvas);
 Drawer.DrawTo(Canvas, Painter.LocalRect.Round);
end;

procedure TMainForm.btnOpenClick(Sender: TObject);
begin
 PickGmfFile(OpenGmfFile);
end;

procedure  runFonts;
 var
  Dir: string;
  Files: TStringDynArray;
  F: string;
  I: Integer;
 begin
  Dir := ExtractFilePath(TPath.GetDocumentsPath);
  if Dir = '' then Exit;
  try
   Files := TDirectory.GetFiles(Dir, '*.ttf');
   for F in Files do
    try
     TFontManager.AddCustomFontFromFile(F);
    except
    end;
  except
  end;
  try
   Files := TDirectory.GetFiles(Dir, '*.otf');
   for F in Files do
    try
     TFontManager.AddCustomFontFromFile(F);
    except
    end;
  except
  end;
 end;

 end.
