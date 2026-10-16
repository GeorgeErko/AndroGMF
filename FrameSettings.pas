unit FrameSettings;

// копия панели CPPainter (C:\Geomaster24\MasterForm.pas): страницы Note
// переключают кнопки Panel333, элементы страниц - установки TwgForm.Settings
// и GlobalSettings.Settings (ResetSettings - заполнить, ApplySettings - записать)

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes,
     System.Variants, FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms,
     FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.TabControl,
     FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.NumberBox, FMX.ListBox,
     FMX.Layouts, FMX.Colors, FMX.Objects, System.Skia, FMX.Skia, WPTForm2;

type
  TSettingsFrame = class(TFrame)
   Panel333: TPanel;
   SpeedButton1: TSpeedButton;
   SpeedButton2: TSpeedButton;
   SpeedButton3: TSpeedButton;
   SpeedButton4: TSpeedButton;
   SpeedButton9: TSpeedButton;
   ResSpeedBtn1: TSpeedButton;
   Panel2: TPanel;
   Note: TTabControl;
  // рисование
   TS0: TTabItem;
   CbOrtho: TCheckBox;
   SEOrtho: TSpinBox;
   Label8: TLabel;
   CbAuto: TCheckBox;
   SEAuto: TSpinBox;
   GB: TGroupBox;
   CbInsert: TCheckBox;
   CbTwise: TCheckBox;
   CbTwiseLot: TCheckBox;
   CbStvor: TCheckBox;
   cbOrthoTwigs: TCheckBox;
   SEOrthoTwigsCount: TSpinBox;
   GroupBox1: TGroupBox;
   Label9: TLabel;
   Label10: TLabel;
   SEArc: TSpinBox;
   SESpline: TSpinBox;
   cbLineArc: TCheckBox;
   cbLineSpline: TCheckBox;
   GroupBox3: TGroupBox;
   cbQueryLayerDraw: TCheckBox;
   cbQueryLayerSbor: TCheckBox;
   cbQueryLayerAttrib: TCheckBox;
   cbNoAssociative: TCheckBox;
  // сетка
   TS1: TTabItem;
   cbShowGrid: TCheckBox;
   Label1: TLabel;
   RbDownScale: TComboBox;
   Label7: TLabel;
   Label12: TLabel;
   EGridX: TNumberBox;
   Label11: TLabel;
   Label13: TLabel;
   EGridY: TNumberBox;
   Label14: TLabel;
   TCGrid: TPanel;
   rbGridLines: TRadioButton;
   rbGridCross: TRadioButton;
   Label4Color: TLabel;
   CBGridColor: TColorComboBox;
   Label5: TLabel;
   SEGridWidth: TSpinBox;
   PanelSize: TPanel;
   Label6: TLabel;
   EGridSize: TNumberBox;
   cbHalfGrid: TCheckBox;
   cbGlass: TCheckBox;
  // растр
   TS2: TTabItem;
   GroupBox2: TGroupBox;
   Label2: TLabel;
   cbColorBitmap: TColorComboBox;
   Label3: TLabel;
   cbColorBack: TColorComboBox;
   cbGlassBitmap: TCheckBox;
   cbFrameBitmap: TCheckBox;
  // установки
   TS3: TTabItem;
   GroupBox8: TGroupBox;
   GroupBox4: TGroupBox;
   Label17: TLabel;
   Label18: TLabel;
   cbColorUzl: TColorComboBox;
   Label20: TLabel;
   cbColorDot: TColorComboBox;
   Label22: TLabel;
   cbColorPoint: TColorComboBox;
   Label19: TLabel;
   sePointSize: TSpinBox;
   cbFillPOint: TCheckBox;
   cbFillPointColor: TColorComboBox;
   Label21: TLabel;
   cbSelectColor: TColorComboBox;
   Label23: TLabel;
   cbSelectPointColor: TColorComboBox;
   Label28: TLabel;
   cbGlueMarkerColor: TColorComboBox;
   cbBinds: TCheckBox;
   Label15: TLabel;
   panColor: TPanel;
   Shape1: TRectangle;
   Shape2: TRectangle;
   Shape4: TRectangle;
   Label29: TLabel;
   cbWindowColor: TColorComboBox;
   cbColorZnaksCheck: TCheckBox;
   cbColorZnaks: TColorComboBox;
   Label444: TLabel;
   PS: TPanel;
   sbZnak: TSpeedButton;
  // маркеры
   TS4: TTabItem;
   Label24: TLabel;
   lbMarkerNames: TListBox;
   cbWidthPath: TCheckBox;
   Label25: TLabel;
   lbMarker: TSkPaintBox;
   GroupBox7: TGroupBox;
   Label26: TLabel;
   seMarkerSize: TSpinBox;
   cbRotate: TCheckBox;
   Label27: TLabel;
   cbMarkerColor: TColorComboBox;
   cbDoubleLine: TCheckBox;
  //
   procedure SpeedButton3Click(Sender: TObject);
   procedure ResSpeedBtn1Click(Sender: TObject);
   procedure TCGridChange(Sender: TObject);
   procedure Shape4MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure lbMarkerNamesChange(Sender: TObject);
   procedure lbMarkerNamesChangeCheck(Sender: TObject);
   procedure lbMarkerDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
   procedure lbMarkerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure seMarkerSizeClick(Sender: TObject);
   procedure sbZnakClick(Sender: TObject);
  private
   FTwgForm: TForm2;
   FMarkerIndex: Integer;
   LockCheck: Boolean;
   FOnApply: TNotifyEvent;
   FOnClose: TNotifyEvent;
   FOnZnakClick: TNotifyEvent;
  //
   function MarkerCount: Integer;
   function MarkerCellRect(Index: Integer): TRectF;
   procedure SelectWindowShape(Shape: TRectangle);
  public
   constructor Create(AOwner: TComponent); override;
  //
   procedure ResetSettings(ATwgForm: TForm2);
   procedure ApplySettings;
   procedure ShowPage(Index: Integer);
  //
   property TwgForm: TForm2 read FTwgForm;
  // после записи установок (обновить окно: цвет фона, перерисовка)
   property OnApply: TNotifyEvent read FOnApply write FOnApply;
  // кнопка "Закрыть" (установки уже записаны)
   property OnClose: TNotifyEvent read FOnClose write FOnClose;
  // кнопка "..." выбора условного знака точки
   property OnZnakClick: TNotifyEvent read FOnZnakClick write FOnZnakClick;
  end;

implementation

uses System.Math, newSettings, newSelector, newProcs, mpMarker, WpTwigs;

{$R *.fmx}

const MarkerCols = 3;

constructor TSettingsFrame.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FMarkerIndex := -1;
 ShowPage(GReadInteger('SettingsFrame_NotePage', 0));
end;

procedure TSettingsFrame.ShowPage(Index: Integer);
var Btn: TSpeedButton;
begin
 if (Index < 0) or (Index >= Note.TabCount) then Index := 0;
 Note.TabIndex := Index;
 case Index of
  0: Btn := SpeedButton1;
  1: Btn := SpeedButton2;
  2: Btn := SpeedButton3;
  3: Btn := SpeedButton4;
 else
  Btn := SpeedButton9;
 end;
 Btn.IsPressed := True;
end;

procedure TSettingsFrame.SpeedButton3Click(Sender: TObject);
begin
 Note.TabIndex := TControl(Sender).Tag;
 GWriteInteger('SettingsFrame_NotePage', Note.TabIndex);
 if Note.ActiveTab = TS4 then lbMarker.Redraw;
end;

procedure TSettingsFrame.ResSpeedBtn1Click(Sender: TObject);
begin
 ApplySettings;
 if Assigned(FOnClose) then FOnClose(Self);
end;

procedure TSettingsFrame.TCGridChange(Sender: TObject);
begin
 PanelSize.Visible := rbGridCross.IsChecked;
end;

procedure TSettingsFrame.SelectWindowShape(Shape: TRectangle);
begin
 Shape.BringToFront;
 Label29.Position.X := Shape.Position.X + 2;
 Label29.BringToFront;
 cbWindowColor.Color := Shape.Fill.Color;
end;

procedure TSettingsFrame.Shape4MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 SelectWindowShape(TRectangle(Sender));
end;

procedure TSettingsFrame.ResetSettings(ATwgForm: TForm2);
var GS: TGlobalSettings;
    Shape: TRectangle;
    Item: TListBoxItem;
    I: Integer;
begin
 FTwgForm := ATwgForm;
 if FTwgForm = nil then exit;
 LockCheck := True;
 try
  with FTwgForm.Settings do begin
   SEOrtho.Value := psOrthoDisst;
   SEAuto.Value := psAutoDisst;
   SEOrthoTwigsCount.Value := psOrthoTwigsCount;
   SEArc.Value := psArcCount;
   SESpline.Value := psSplineCount;
 //
   cbLineArc.IsChecked := psLineArc;
   cbLineSpline.IsChecked := psLineSpline;
 //
   CbOrtho.IsChecked := psOrtho;
   CbAuto.IsChecked := psAuto;
   CbInsert.IsChecked := psInsert;
   CbTwise.IsChecked := psTwise;
   CbStvor.IsChecked := psStvor;
   cbOrthoTwigs.IsChecked := psOrthoTwigs;
  // растр
   cbColorBitmap.Color := TAlphaColor(bmColor);
   cbColorBack.Color := TAlphaColor(bmBackColor);
   cbGlassBitmap.IsChecked := bmGlass;
   cbFrameBitmap.IsChecked := bmFrame;
  // сетка
   cbShowGrid.IsChecked := gsShowGrid;
   RbDownScale.ItemIndex := RbDownScale.Items.IndexOf(IntToStr(gsScale));
   rbGridLines.IsChecked := gsGridType = 0;
   rbGridCross.IsChecked := gsGridType > 0;
   CBGridColor.Color := TAlphaColor(gsGridColor);
   SEGridWidth.Value := gsGridLineWidth;
   PanelSize.Visible := gsGridType > 0;
   EGridSize.Value := gsGridSize;
   EGridX.Value := gsGridCellWidth;
   EGridY.Value := gsGridCellHeight;
   cbHalfGrid.IsChecked := gsHalfGrid;
   cbGlass.IsChecked := gsGlass;
 //
   cbQueryLayerDraw.IsChecked := psQueryLayerDraw;
   cbQueryLayerSbor.IsChecked := psQueryLayerSbor;
   cbQueryLayerAttrib.IsChecked := psQueryLayerAttrib;
 //
   CbTwiseLot.IsChecked := psTwiseLot;
   cbNoAssociative.IsChecked := not psNoAssociativeFill;
   cbWidthPath.IsChecked := psWidthPath;
  end;
 // отображение
  GS := nil;
  if FTwgForm.Selector <> nil then GS := FTwgForm.Selector.GlobalSettings;
  if GS = nil then exit;
  with GS.Settings do begin
   sePointSize.Value := gsPointSize;
   cbSelectColor.Color := gsSelectColor;
   cbWindowColor.Color := TAlphaColor(gsWindowColor);
   cbColorZnaks.Color := TAlphaColor(gsColorZnaks);
   cbColorZnaksCheck.IsChecked := gsColorZnaksCheck;
   cbFillPOint.IsChecked := gsFillPointCheck;
   cbFillPointColor.Color := TAlphaColor(gsFillPointColor);
   cbColorUzl.Color := TAlphaColor(gsColorUzl);
   cbColorDot.Color := TAlphaColor(gsColorDot);
   cbColorPoint.Color := TAlphaColor(gsColorPoint);
   cbSelectPointColor.Color := TAlphaColor(gsSelectPointColor);
   cbGlueMarkerColor.Color := TAlphaColor(gsGlueMarkerColor);
   cbBinds.IsChecked := gsBinds;
  // фон окна: одна из трех плашек (иначе белая)
   if TAlphaColor(gsWindowColor) = Shape2.Fill.Color then Shape := Shape2 else
   if TAlphaColor(gsWindowColor) = Shape4.Fill.Color then Shape := Shape4 else Shape := Shape1;
  end;
  SelectWindowShape(Shape);
 // маркеры
  lbMarkerNames.BeginUpdate;
  try
   lbMarkerNames.Clear;
   if GS.MarkerView <> nil then
    for I := 0 to GS.MarkerView.Count - 1 do begin
     Item := TListBoxItem.Create(lbMarkerNames);
     Item.Parent := lbMarkerNames;
     Item.Text := GS.MarkerView[I].Name;
     Item.IsChecked := GS.MarkerView[I].Checked;
    end;
  finally
   lbMarkerNames.EndUpdate;
  end;
 finally
  LockCheck := False;
 end;
 if lbMarkerNames.Count > 0 then lbMarkerNames.ItemIndex := 0;
 lbMarkerNamesChange(nil);
end;

procedure TSettingsFrame.ApplySettings;
var GS: TGlobalSettings;
begin
 if FTwgForm = nil then exit;
 with FTwgForm.Settings do begin
  psOrtho := CbOrtho.IsChecked;
  psAuto := CbAuto.IsChecked;
  psInsert := CbInsert.IsChecked;
  psTwise := CbTwise.IsChecked;
  psStvor := CbStvor.IsChecked;
  psOrthoTwigs := cbOrthoTwigs.IsChecked;
 //
  psOrthoDisst := Round(SEOrtho.Value);
  psAutoDisst := Round(SEAuto.Value);
  psOrthoTwigsCount := Round(SEOrthoTwigsCount.Value);
  psArcCount := Round(SEArc.Value);
  psSplineCount := Round(SESpline.Value);
  FTwgForm.fGraphSet.ArcKV := psSplineCount;
  FTwgForm.fGraphSet.Kvant := psArcCount;
  newSettings.GGraphSet := FTwgForm.fGraphSet;
  if FTwgForm.Selector <> nil then FTwgForm.Selector.GGraphSet := FTwgForm.fGraphSet;
  Quants_For_Arcs := psArcCount;
 //
  psLineArc := cbLineArc.IsChecked;
  psLineSpline := cbLineSpline.IsChecked;
 //
  if RbDownScale.ItemIndex >= 0 then gsScale := StrToIntDef(RbDownScale.Items[RbDownScale.ItemIndex], gsScale);
  gsShowGrid := cbShowGrid.IsChecked;
  gsGridCellWidth := EGridX.Value;
  gsGridCellHeight := EGridY.Value;
  gsGridSize := EGridSize.Value;
  gsGridType := Ord(rbGridCross.IsChecked);
  gsGridLineWidth := Round(SEGridWidth.Value);
  gsGridColor := Integer(CBGridColor.Color);
  gsHalfGrid := cbHalfGrid.IsChecked;
  gsGlass := cbGlass.IsChecked;
 //
  bmColor := Integer(cbColorBitmap.Color);
  bmBackColor := Integer(cbColorBack.Color);
  bmGlass := cbGlassBitmap.IsChecked;
  bmFrame := cbFrameBitmap.IsChecked;
 //
  psQueryLayerDraw := cbQueryLayerDraw.IsChecked;
  psQueryLayerSbor := cbQueryLayerSbor.IsChecked;
  psQueryLayerAttrib := cbQueryLayerAttrib.IsChecked;
 //
  psTwiseLot := CbTwiseLot.IsChecked;
  psNoAssociativeFill := not cbNoAssociative.IsChecked;
  psWidthPath := cbWidthPath.IsChecked;
 end;
 GS := nil;
 if FTwgForm.Selector <> nil then GS := FTwgForm.Selector.GlobalSettings;
 if GS <> nil then
  with GS.Settings do begin
   gsPointSize := Round(sePointSize.Value);
   gsSelectColor := cbSelectColor.Color;
   gsWindowColor := Integer(cbWindowColor.Color);
   gsColorZnaks := Integer(cbColorZnaks.Color);
   gsColorZnaksCheck := cbColorZnaksCheck.IsChecked;
   gsFillPointCheck := cbFillPOint.IsChecked;
   gsFillPointColor := Integer(cbFillPointColor.Color);
   gsColorUzl := Integer(cbColorUzl.Color);
   gsColorDot := Integer(cbColorDot.Color);
   gsColorPoint := Integer(cbColorPoint.Color);
   gsSelectPointColor := Integer(cbSelectPointColor.Color);
   gsGlueMarkerColor := Integer(cbGlueMarkerColor.Color);
   gsBinds := cbBinds.IsChecked;
  end;
 FTwgForm.ClassBuildII;
 if Assigned(FOnApply) then FOnApply(Self);
end;

procedure TSettingsFrame.lbMarkerNamesChange(Sender: TObject);
var GS: TGlobalSettings;
    M: TMarker;
begin
 FMarkerIndex := lbMarkerNames.ItemIndex;
 GS := nil;
 if (FTwgForm <> nil) and (FTwgForm.Selector <> nil) then GS := FTwgForm.Selector.GlobalSettings;
 if (GS = nil) or (GS.MarkerView = nil) or (FMarkerIndex < 0) or (FMarkerIndex >= GS.MarkerView.Count) then begin
  FMarkerIndex := -1;
  lbMarker.Redraw;
  exit;
 end;
 M := GS.MarkerView[FMarkerIndex].Marker;
 LockCheck := True;
 try
  seMarkerSize.Value := M.Size;
  cbMarkerColor.Color := TAlphaColor(M.Color);
  cbDoubleLine.IsChecked := M.mWidth > 0;
  cbRotate.IsChecked := M.Rotation;
 finally
  LockCheck := False;
 end;
 lbMarker.Redraw;
end;

procedure TSettingsFrame.lbMarkerNamesChangeCheck(Sender: TObject);
var GS: TGlobalSettings;
    Item: TListBoxItem;
begin
 if LockCheck then exit;
 if not (Sender is TListBoxItem) then exit;
 if (FTwgForm = nil) or (FTwgForm.Selector = nil) then exit;
 GS := FTwgForm.Selector.GlobalSettings;
 Item := TListBoxItem(Sender);
 if (GS <> nil) and (GS.MarkerView <> nil) and (Item.Index < GS.MarkerView.Count) then GS.MarkerView[Item.Index].Checked := Item.IsChecked;
end;

procedure TSettingsFrame.seMarkerSizeClick(Sender: TObject);
var GS: TGlobalSettings;
    M: TMarker;
begin
 if LockCheck then exit;
 lbMarker.Redraw;
 if (FTwgForm = nil) or (FTwgForm.Selector = nil) or (FMarkerIndex < 0) then exit;
 GS := FTwgForm.Selector.GlobalSettings;
 if (GS = nil) or (GS.MarkerView = nil) or (FMarkerIndex >= GS.MarkerView.Count) then exit;
 M := GS.MarkerView[FMarkerIndex].Marker;
 M.Size := Round(seMarkerSize.Value);
 M.Color := Integer(cbMarkerColor.Color);
 M.mWidth := Ord(cbDoubleLine.IsChecked) * 2;
 M.Rotation := cbRotate.IsChecked;
end;

function TSettingsFrame.MarkerCount: Integer;
begin
 if MarkerList <> nil then Result := MarkerList.Markers.Count else Result := 6;
end;

// ячейка списка маркеров (3 колонки, высота - четверть списка, как в старом lbMarker)
function TSettingsFrame.MarkerCellRect(Index: Integer): TRectF;
var W, H: Single;
begin
 W := lbMarker.Width / MarkerCols;
 H := lbMarker.Height / 4;
 Result := TRectF.Create(0, 0, W, H);
 Result.Offset((Index mod MarkerCols) * W, (Index div MarkerCols) * H);
end;

procedure TSettingsFrame.lbMarkerDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var P: ISkPaint;
    I, mType: Integer;
    R: TRectF;
    Cx, Cy, Rad: Single;
    GS: TGlobalSettings;
procedure Tri(Sign: Single);
begin
 ACanvas.DrawLine(Cx, Cy - Sign * Rad, Cx + Rad, Cy + Sign * Rad, P);
 ACanvas.DrawLine(Cx + Rad, Cy + Sign * Rad, Cx - Rad, Cy + Sign * Rad, P);
 ACanvas.DrawLine(Cx - Rad, Cy + Sign * Rad, Cx, Cy - Sign * Rad, P);
end;
begin
 P := TSkPaint.Create;
 P.AntiAlias := True;
 GS := nil;
 if (FTwgForm <> nil) and (FTwgForm.Selector <> nil) then GS := FTwgForm.Selector.GlobalSettings;
 if GS <> nil then P.Color := TAlphaColor(GS.Settings.gsWindowColor) or $FF000000 else P.Color := TAlphaColors.White;
 ACanvas.DrawRect(ADest, P);
 mType := -1;
 if (GS <> nil) and (GS.MarkerView <> nil) and (FMarkerIndex >= 0) and (FMarkerIndex < GS.MarkerView.Count) then mType := GS.MarkerView[FMarkerIndex].Marker.mType;
 for I := 0 to MarkerCount - 1 do begin
  R := MarkerCellRect(I);
  if I = mType then begin
   P.Style := TSkPaintStyle.Stroke;
   P.StrokeWidth := 1;
   P.Color := TAlphaColors.Gray;
   ACanvas.DrawRect(R, P);
  end;
  Cx := (R.Left + R.Right) * 0.5;
  Cy := (R.Top + R.Bottom) * 0.5;
  Rad := Min(Round(seMarkerSize.Value), Min(R.Width, R.Height) - 4) * 0.5;
  if Rad < 1 then Rad := 1;
  P.Style := TSkPaintStyle.Stroke;
  P.Color := cbMarkerColor.Color or $FF000000;
  if cbDoubleLine.IsChecked then P.StrokeWidth := 3 else P.StrokeWidth := 1.5;
  case I of
   mtCross: begin ACanvas.DrawLine(Cx - Rad, Cy, Cx + Rad, Cy, P); ACanvas.DrawLine(Cx, Cy - Rad, Cx, Cy + Rad, P); end;
   mtDiagCross: begin ACanvas.DrawLine(Cx - Rad, Cy - Rad, Cx + Rad, Cy + Rad, P); ACanvas.DrawLine(Cx + Rad, Cy - Rad, Cx - Rad, Cy + Rad, P); end;
   mtRect: ACanvas.DrawRect(TRectF.Create(Cx - Rad, Cy - Rad, Cx + Rad, Cy + Rad), P);
   mtTriangle: Tri(1);
   mtInvTriangle: Tri(-1);
   mt2Triangle: begin Tri(1); Tri(-1); end;
  else
   ACanvas.DrawCircle(Cx, Cy, Rad, P);
  end;
 end;
end;

procedure TSettingsFrame.lbMarkerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var I: Integer;
    GS: TGlobalSettings;
begin
 if (FTwgForm = nil) or (FTwgForm.Selector = nil) or (FMarkerIndex < 0) then exit;
 GS := FTwgForm.Selector.GlobalSettings;
 if (GS = nil) or (GS.MarkerView = nil) or (FMarkerIndex >= GS.MarkerView.Count) then exit;
 for I := 0 to MarkerCount - 1 do
  if MarkerCellRect(I).Contains(PointF(X, Y)) then begin
   GS.MarkerView[FMarkerIndex].Marker.mType := I;
   lbMarker.Redraw;
   exit;
  end;
end;

procedure TSettingsFrame.sbZnakClick(Sender: TObject);
begin
 if Assigned(FOnZnakClick) then FOnZnakClick(Self);
end;

end.
