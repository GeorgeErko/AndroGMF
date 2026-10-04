unit instPointSign;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.TabControl, FMX.Controls.Presentation,
  WPTForm2, newLayersTable, System.ImageList, FMX.ImgList, FMX.Layouts,
  FMX.ListBox, FMX.ScrollBox, FMX.Skia,
  Lib, System.Skia, instLayerFrame, newResource;

type
 // запуск операции установки знаков (Opr - код операции objTopo32, Tag кнопки)
  TInstToolEvent = procedure(Sender: TObject; Opr: Integer) of object;

  TInstPointsFrame = class(TFrame)
    TC: TTabControl;
    Panel1: TPanel;
    btnTabs: TButton;
    ImageList1: TImageList;
    LB: TListBox;
    CB: TComboBox;
    Lay: TLayout;
    SB: THorzScrollBox;
    btnPlus: TButton;
    btnMinus: TButton;
    btnScaleM: TButton;
    btnScaleP: TButton;
    pnlTools: TLayout;
    sbSetPoint: TSpeedButton;
    sbRotatePoint: TSpeedButton;
    sbSetAttrib: TSpeedButton;
    sbSetPerLine: TSpeedButton;
    cbActivate: TCheckBox;
    Label1: TLabel;
    ImageList2: TImageList;
    procedure Button2Click(Sender: TObject);
    procedure sbSetPointClick(Sender: TObject);
    procedure btnTabsClick(Sender: TObject);
    procedure LBChange(Sender: TObject);
    procedure btnMinusClick(Sender: TObject);
    procedure CBChange(Sender: TObject);
  protected
   FTwgForm: TForm2;
   RowHeight: Integer;
   FTabName: String;
   FVisRows: Integer;
   FScale: Single;
   TilesLay: TLayout;
   FDragScaleActive: Boolean;
   FDragScaleTileIdx: Integer;
   FDragScaleStart: Single;
   FDragScaleStartDist: Single;
   FDragScaleKey: AnsiString;
   FDragScaleTileControl: TControl;
   FDirtyScales: TStringList;
   FTabChanging: Boolean; // смена вкладки: знак выбирается без изменения выделенных объектов
   procedure MarkDirtyScale(const AKey: AnsiString; const AObj: TObject);
   procedure DragScaleUpdateFromControlCoords(const AControl: TControl; const AX, AY: Single);
   procedure DragScaleCommit;
   procedure LoadAllLocalScalesFromRegistry; virtual;
   procedure SaveAllLocalScalesToRegistry; virtual;
   procedure InvalidateTiles; virtual;
   procedure EnsureSelectedTileVisible; virtual;
    procedure ClearExtraResources; virtual;
    procedure SetTwgForm(const Value: TForm2); virtual;
    procedure ChangeTab(Sender: TObject);
    procedure EnsureControls; virtual;
    procedure InitControls; virtual;
    procedure TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single); virtual;
    procedure TileClick(Sender: TObject);
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure SBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure SBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  // доступ к коллекции знаков
    function GetZnacksCount(TabName_: String): Integer; virtual;
    function GetZnakIndex(TabName_:String;Index:Integer):Integer;virtual;
    function GetZnakName (TabName_:String;Index:Integer):String;virtual;
    function GetZnakLayer(TabName_:String;Index:Integer):String;virtual;
    function GetZnakPoint(TabName_:String;Index:Integer):TPoint_Sign;virtual;
    procedure DoZnakSelected;
    procedure SelectZnak(Idx: Integer);
   // группа текущей вкладки - по имени вкладки (вкладки создаются скрытыми,
   // номер вкладки не всегда совпадает с номером группы)
    function CurGroup: TGroupZnk;
    function LayerToObjects: Boolean;
    function ObjectsLayer(ZV: TZnakView): TResource; virtual;
    function AcceptObject(Obj: TObject): Boolean; virtual;
    procedure ApplyZnak(Obj: TObject; ZV: TZnakView); virtual;
    function ZnakDiffers(Obj: TObject; ZV: TZnakView): Boolean; virtual;
  public
  // кнопки установки знаков (бывшие sbSetPoint.. старого instPointSign):
  // обработчик мыши (objTopo32) создает форма
   OnTool: TInstToolEvent;
  // выбран другой знак - форма передает его в обработчик мыши
   OnZnakSelected: TNotifyEvent;
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   function Group: TGroupCollection; virtual;
   function SelectedZnakNum: Integer; virtual;
  // выбрать вкладку TabName и в ней знак с номером ZnakNum (как щелчком по
  // плитке); False - вкладки или знака нет
   function SelectZnakByNum(const TabName: String; ZnakNum: Integer): Boolean;
   property TwgForm: TForm2 read FTwgForm write SetTwgForm;
   property Scale: Single read FScale write FScale;
   procedure ClearTilesAndResources; virtual;
   procedure RebuildTiles; virtual;
   function UserPropName: String; virtual;
  end;

procedure TileOnPoly(Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
procedure TileOnText(Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                     txtColor: Integer; Align: byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;

var
 GTileCanvas: ISkCanvas;
 GTileScale: Single;
 GTileDX: Single;
 GTileDY: Single;
 GTileStrokePaint: ISkPaint;
 GTileFillPaint: ISkPaint;

implementation uses newProcs, newSelector, ogcDrawerSkia, FMX.Platform, Writer,
                    FramePropEditor, EcDot, EcDot2, TwgDraw, System.Generics.Collections;

{$R *.fmx}

procedure SetTilePaintColor(var Paint: ISkPaint; C: Integer; Stroke: Boolean; W: Single);
var A: TAlphaColor;
begin
 if Paint = nil then Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 if Stroke then Paint.Style := TSkPaintStyle.Stroke else Paint.Style := TSkPaintStyle.Fill;
 Paint.StrokeWidth := W;
 A := TAlphaColor($FF000000 or (Cardinal(C) and $00FFFFFF));
 Paint.Color := A;
end;

// гарнитура для надписей плиток: загрузка шрифта из файла дорогая, а плитки
// перерисовываются часто - гарнитуры кэшируются по имени и начертанию
// (в т.ч. ненайденные - nil)
var GTileTypefaces: TDictionary<string, ISkTypeface>;
function TileTypeface(const AName: string; Bl, It: Boolean; const AStyle: TSkFontStyle): ISkTypeface;
var Key, FontFile: string;
begin
 Result := nil;
 if AName = '' then exit;
 Key := AName + '|' + IntToStr(Ord(Bl)) + IntToStr(Ord(It));
 if GTileTypefaces = nil then GTileTypefaces := TDictionary<string, ISkTypeface>.Create;
 if GTileTypefaces.TryGetValue(Key, Result) then exit;
 FontFile := GetRegisteredSkiaFontFile(AName);
 if FontFile <> '' then
  try
   Result := TSkTypeface.MakeFromFile(FontFile);
  except
   Result := nil;
  end;
 if Result = nil then
  try
   Result := TSkTypeface.MakeFromName(AName, TSkFontStyle.Normal);
  except
   Result := nil;
  end;
 if Result = nil then
  try
   Result := TSkTypeface.MakeFromName(AName, AStyle);
  except
   Result := nil;
  end;
 GTileTypefaces.Add(Key, Result);
end;

function TileTP(X, Y: Double): TPointF;
begin
 Result := PointF(Single(X) * GTileScale + GTileDX, Single(Y) * GTileScale + GTileDY);
end;

function SignLocalScaleKey(const AFrameName, ATabName: string; const ASign: TPoint_Sign): AnsiString;
begin
 Result := AnsiString(AFrameName + '_' + ATabName + '_LocalScale_' + IntToStr(ASign.MyInd));
end;

procedure TInstPointsFrame.LoadAllLocalScalesFromRegistry;
var I: Integer;
    TabName: String;
    Idx: Integer;
    Sign: TPoint_Sign;
    K: AnsiString;
begin
 if Group = nil then Exit;
 for I := 0 to Group.Count - 1 do
 begin
  TabName := Group[I].Name;
  if TabName = '' then Continue;
  for Idx := 0 to GetZnacksCount(TabName) - 1 do
  begin
   Sign := GetZnakPoint(TabName, Idx);
   if Sign = nil then Continue;
   K := SignLocalScaleKey(Name, TabName, Sign);
   Sign.LocalScale := GReadFloat(K, Sign.LocalScale);
   if Sign.LocalScale <= 0 then Sign.LocalScale := 1;
  end;
 end;
end;

procedure TInstPointsFrame.MarkDirtyScale(const AKey: AnsiString; const AObj: TObject);
var N: Integer;
begin
 if AKey = '' then Exit;
 if AObj = nil then Exit;
 if FDirtyScales = nil then
 begin
  FDirtyScales := TStringList.Create;
  FDirtyScales.Sorted := True;
  FDirtyScales.Duplicates := dupIgnore;
 end;
 N := FDirtyScales.IndexOf(string(AKey));
 if N < 0 then
  FDirtyScales.AddObject(string(AKey), AObj)
 else
  FDirtyScales.Objects[N] := AObj;
end;

procedure TInstPointsFrame.SaveAllLocalScalesToRegistry;
var I: Integer;
    TabName: String;
    Idx: Integer;
    Sign: TPoint_Sign;
    K: AnsiString;
begin
 if (FDirtyScales = nil) or (FDirtyScales.Count = 0) then Exit;
 for I := 0 to FDirtyScales.Count - 1 do
 begin
  K := AnsiString(FDirtyScales[I]);
  Sign := TPoint_Sign(FDirtyScales.Objects[I]);
  if Sign = nil then Continue;
  if Sign.LocalScale <= 0 then Sign.LocalScale := 1;
  GWriteFloat(K, Sign.LocalScale);
 end;
 FDirtyScales.Clear;
end;

procedure TileOnPoly(Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
var
 I: Integer;
 P0: PGeoPoint;
 Pt: TPointF;
 SW: Single;
 PathBuilder: ISkPathBuilder;
 Path: ISkPath;
begin
 if (GTileCanvas = nil) or (Poly = nil) then Exit;
 if Poly.Count < 1 then Exit;
 PathBuilder := TSkPathBuilder.Create;
 P0 := Poly;
 for I := 0 to Poly.Count - 1 do begin
  Pt := TileTP(P0.X, P0.Y);
  if I = 0 then PathBuilder.MoveTo(Pt.X, Pt.Y) else PathBuilder.LineTo(Pt.X, Pt.Y);
  P0 := P0.Next;
  if P0 = nil then Break;
 end;
 if isPolygon then PathBuilder.Close;
 Path := PathBuilder.Detach;
 if isPolygon and (brushColor <> 0) then begin
  SetTilePaintColor(GTileFillPaint, brushColor, False, 0);
  GTileCanvas.DrawPath(Path, GTileFillPaint);
 end;
 SW := Max(1, Single(lineWidth) * GTileScale);
 SetTilePaintColor(GTileStrokePaint, penColor, True, SW);
 GTileCanvas.DrawPath(Path, GTileStrokePaint);
end;

procedure TileOnText(Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                     txtColor: Integer; Align: byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;
var
 S: string;
 Typeface: ISkTypeface;
 PaintT: ISkPaint;
 Pt: TPointF;
 LocalFontName: string;
 CutPos: Integer;
 FontFile: string;
 Weight: TSkFontWeight;
 Slant: TSkFontSlant;
 FontStyle: TSkFontStyle;
 ProbeFont: ISkFont;
 ProbeMetrics: TSkFontMetrics;
 Font: ISkFont;
 Metrics: TSkFontMetrics;
 Bounds: TRectF;
 AscentAbs: Single;
 Full: Single;
 HFullPix: Single;
 HBaselinePix: Single;
 XP: Single;
 YP: Single;
 DrawX: Single;
 DrawY: Single;
begin
 if (GTileCanvas = nil) or (Text = nil) then Exit;
 S := string(Text);
 if S = '' then Exit;
 Pt := TileTP(X, Y);
 PaintT := TSkPaint.Create;
 SetTilePaintColor(PaintT, txtColor, False, 0);

 LocalFontName := '';
 if FontName <> nil then
  LocalFontName := Trim(string(FontName));
 if (LocalFontName <> '') and (LocalFontName[1] = '@') then
  LocalFontName := Trim(Copy(LocalFontName, 2, MaxInt));
 CutPos := Pos(',', LocalFontName);
 if CutPos > 0 then
  LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));
 CutPos := Pos('(', LocalFontName);
 if CutPos > 0 then
  LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));

 Weight := TSkFontWeight.Normal;
 if Bl then Weight := TSkFontWeight.Bold;
 Slant := TSkFontSlant.Upright;
 if It then Slant := TSkFontSlant.Italic;
 FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);
 Typeface := TileTypeface(LocalFontName, Bl, It, FontStyle);

 HFullPix := Single(txtHeight) * GTileScale;
 if HFullPix <= 0 then Exit;

 ProbeFont := TSkFont.Create(Typeface, 100);
 ProbeFont.GetMetrics(ProbeMetrics);
 AscentAbs := -ProbeMetrics.Ascent;
 Full := (-ProbeMetrics.Ascent) + ProbeMetrics.Descent;
 if (AscentAbs > 0.01) and (Full > 0.01) then
  HBaselinePix := HFullPix * (AscentAbs / Full)
 else
  HBaselinePix := HFullPix;

 Font := TSkFont.Create(Typeface, HBaselinePix);
 Font.GetMetrics(Metrics);
 Font.MeasureText(S, Bounds, PaintT);

 XP := 0;
 YP := 0;
 case Align of
  2: begin XP := 0;   YP := 0.5; end;
  3: begin XP := 0;   YP := 1;   end;
  5: begin XP := 0.5; YP := 0;   end;
  6: begin XP := 0.5; YP := 0.5; end;
  7: begin XP := 0.5; YP := 1;   end;
  9: begin XP := 1;   YP := 0;   end;
 10: begin XP := 1;   YP := 0.5; end;
 11: begin XP := 1;   YP := 1;   end;
 end;

 DrawX := - (Bounds.Left + XP * Bounds.Width);
 if YP < 0 then
  DrawY := 0
 else
  DrawY := - (Metrics.Ascent + (-Metrics.Ascent) * YP);

 GTileCanvas.Save;
 try
  GTileCanvas.Translate(Pt.X, Pt.Y);
  if Abs(txtAngle) > 1e-6 then
   GTileCanvas.Rotate(Single(txtAngle * 180 / Pi));
  if Abs(txtScale - 1) > 1e-6 then
   GTileCanvas.Scale(Single(txtScale), 1);
  GTileCanvas.DrawSimpleText(S, DrawX, DrawY, Font, PaintT);
 finally
  GTileCanvas.Restore;
 end;
end;

constructor TInstPointsFrame.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 if (AOwner <> nil) and (Name = 'InstPointsFrame') then begin
  TControl(AOwner).Width := GReadFloat(Name + '_W',TControl(AOwner).Width);
  Writein(['Load=', Name, Width, TControl(AOwner).Name]);
 end;
 if cbActivate <> nil then cbActivate.IsChecked := GReadInteger(Name + '_cbActivate', 1) = 1;
end;

destructor TInstPointsFrame.Destroy;
begin
if Name = 'InstPointsFrame' then begin
 GWriteFloat(Name + '_W', TControl(Owner).Width);
    Writein(['Save=', Name, Width]);
end;
 if cbActivate <> nil then GWriteInteger(Name + '_cbActivate', Ord(cbActivate.IsChecked));
 try
  SaveAllLocalScalesToRegistry;
 finally
  FreeAndNil(FDirtyScales);
  inherited;
 end;
end;

procedure TInstPointsFrame.btnTabsClick(Sender: TObject);
var I: Integer;
    H: Single;
begin
 if LB.Visible then begin LB.Visible := False; exit; end;
//
  LB.ApplyStyleLookup;
  LB.RecalcSize;
  H := 0;
  if LB.Items.Count > 0 then begin
    if LB.ItemHeight > 0 then
      H := LB.ItemHeight * LB.Items.Count
    else begin
      for I := 0 to LB.Count - 1 do begin
        H := H + LB.ListItems[I].Height;
      end;
    end;
  end;
  LB.Height := H + LB.Padding.Top + LB.Padding.Bottom;
 LB.Visible := True;
 LB.BringToFront;
end;

procedure TInstPointsFrame.Button2Click(Sender: TObject);
begin
//
end;

procedure TInstPointsFrame.btnMinusClick(Sender: TObject);
var Delta: Integer;
    Idx: Integer;
    Sign: TPoint_Sign;
    K: AnsiString;
    I: Integer;
    TabName: String;
    DeltaScale: Single;
begin
 if Abs(TControl(Sender).Tag) = 10  then begin
  if Group = nil then Exit;
  DeltaScale := 0.1 * (TControl(Sender).Tag / 10);
  for I := 0 to Group.Count - 1 do
  begin
   TabName := Group[I].Name;
   if TabName = '' then Continue;
   for Idx := 0 to GetZnacksCount(TabName) - 1 do
   begin
    Sign := GetZnakPoint(TabName, Idx);
    if Sign = nil then Continue;
    if Sign.LocalScale <= 0 then Sign.LocalScale := 1;
    Sign.LocalScale := Sign.LocalScale + DeltaScale;
    if Sign.LocalScale < 0.1 then Sign.LocalScale := 0.1;
    if Sign.LocalScale > 10 then Sign.LocalScale := 10;
    K := SignLocalScaleKey(Name, TabName, Sign);
    MarkDirtyScale(K, Sign);
   end;
  end;
  InvalidateTiles;
 end else begin
  Delta := -4;
  if TControl(Sender).Tag <> 0 then
   Delta := 4 * TControl(Sender).Tag;
  RowHeight := RowHeight + Delta;
  if RowHeight < 12 then RowHeight := 12;
  GWriteInteger(Name + '_RowHeight', RowHeight);
  RebuildTiles;
 end;
end;

function TInstPointsFrame.GetZnacksCount(TabName_: String): Integer;
begin
 Result := Group.GroupByName[TabName_].Items.Count;
end;

function TinstPointsFrame.GetZnakIndex(TabName_: String;Index: Integer): Integer;
begin
 Result := TPoint_Sign(Group.GroupByName[TabName_].Item[Index].Znak).MyInd;
end;

function TinstPointsFrame.GetZnakName(TabName_: String; Index: Integer): String;
begin
 Result := Group.GroupByName[TabName_].Item[Index].ZnakName;
end;

function TinstPointsFrame.GetZnakLayer(TabName_: String; Index: Integer): String;
begin
 Result := Group.GroupByName[TabName_].Item[Index].ZnakLayer;
end;

function TinstPointsFrame.GetZnakPoint(TabName_: String; Index: Integer): TPoint_Sign;
begin
 Result := Group.GroupByName[TabName_].Item[Index].Znak;
end;

function TInstPointsFrame.Group: TGroupCollection;
begin
 Result := nil;
 if TwgForm = nil then exit;
 Result:=TwgForm.LayerTable.MkLib.PointGroup;
end;

procedure TInstPointsFrame.ClearTilesAndResources;
begin
 if TilesLay <> nil then
 begin
  TilesLay.BeginUpdate;
  try
   while TilesLay.ControlsCount > 0 do TilesLay.Controls[0].Free;
  finally
   TilesLay.EndUpdate;
  end;
 end;
 GTileCanvas := nil;
 GTileStrokePaint := nil;
 GTileFillPaint := nil;
 ClearExtraResources;
end;

procedure TInstPointsFrame.ClearExtraResources;
begin
//
end;

procedure TInstPointsFrame.InitControls;
begin
 FScale := GReadFloat(Name + '_Scale', 3);
 RowHeight := GReadInteger(Name+'_RowHeight', 48);
end;

procedure TInstPointsFrame.LBChange(Sender: TObject);
begin
 If LB.ItemIndex = - 1 then exit;
 TC.TabIndex:= LB.ItemIndex;
 LB.Visible := False;
 ChangeTab(nil);
end;

procedure TInstPointsFrame.SetTwgForm(const Value: TForm2);
var I: Integer; Tab: TTabItem;
begin
 SaveAllLocalScalesToRegistry;
 ClearTilesAndResources;
 FTwgForm := Value;
// заполнение вкладок
 If Group = nil then Exit;
 InitControls;
 LoadAllLocalScalesFromRegistry;

 if CB <> nil then CB.Parent := nil;
 if SB <> nil then SB.Parent := nil;
 if Lay <> nil then Lay.Parent := nil;
 if TilesLay <> nil then TilesLay.Parent := nil;

 if LB <> nil then LB.Items.Clear;

 if TC <> nil then TC.OnChange := nil;
 For I := TC.TabCount - 1 downto 0 do TC.Delete(I);
 TC.TabPosition := TTabPosition.Bottom;
 I := Group.Count;
 WriteIn(['TC.Count=', TC.TabCount]);
 For I := 0 to Group.Count - 1 do begin
  LB.Items.Add(Group[I].Name);
  Tab := TC.Add;
  Tab.Text := Group[I].Name;
  Tab.Visible := False;
 end;
 If TC.TabCount = 0 then Exit;
 TC.TabIndex := 0;
 TC.OnChange := ChangeTab;
 EnsureControls;
 ChangeTab(nil);
end;

procedure TInstPointsFrame.EnsureControls;
begin
 if TC <> nil then TC.Align := TAlignLayout.Client;
 if CB = nil then CB := TComboBox.Create(Self);
 CB.Stored := False;
 CB.OnChange := CBChange;
 if SB = nil then SB := THorzScrollBox.Create(Self);
 SB.Stored := False;
  SB.ShowScrollBars := True;
  SB.AutoHide := True;
  SB.OnMouseMove := SBMouseMove;
  SB.OnMouseUp := SBMouseUp;
 Lay.Stored := False;
 Lay.Align := TAlignLayout.None;
 Lay.Position.X := 0;
 Lay.Position.Y := 0;
 if TilesLay = nil then
 begin
  TilesLay := TLayout.Create(Self);
  TilesLay.Stored := False;
  TilesLay.Align := TAlignLayout.None;
  TilesLay.Position.X := 0;
  TilesLay.Position.Y := 0;
 end;
 if TilesLay.Parent <> SB then
  TilesLay.Parent := SB;
end;

procedure TInstPointsFrame.ChangeTab(Sender: TObject);
var Tab: TTabItem;
    Idx: Integer;
    I: Integer;
    N: Integer;
    TabName: String;
begin
 if TC = nil then exit;
 Idx := TC.TabIndex;
 if (Idx < 0) or (Idx >= TC.TabCount) then exit;
 Tab := TC.Tabs[Idx]; Tab.Visible := True;
 if Tab = nil then exit;
 EnsureControls;
//
 CB.Parent := Tab;
 CB.Align := TAlignLayout.Bottom;
//
 Lay.Parent := Tab;
 Lay.Align := TAlignLayout.Client;
 SB.Parent := Lay;
 SB.Align := TAlignLayout.Client;
//
 TabName := Tab.Text;
 FTabName := TabName;
 CB.Items.BeginUpdate;
 try
  CB.Items.Clear;
  if Group <> nil then begin
   N := GetZnacksCount(TabName);
   for I := 0 to N - 1 do begin
    CB.Items.Add(GetZnakName(TabName, I));
   end;
  end;
 finally
  CB.Items.EndUpdate;
 end;
 FTabChanging := True;
 try
  if CB.Items.Count > 0 then CB.ItemIndex := 0;
 finally
  FTabChanging := False;
 end;
 RebuildTiles;
{$IFDEF ANDROID}
 For I := 0 to TC.TabCount - 1 do
  if TC.Tabs[I] <> Tab then TC.Tabs[I].Visible := False;
{$ENDIF} ;
end;

procedure TInstPointsFrame.RebuildTiles;
var N: Integer;
    H: Single;
    VisRows: Integer;
    Cols: Integer;
    Idx: Integer;
    Col: Integer;
    Row: Integer;
    T: TSkPaintBox;
begin
 if SB = nil then exit;
 if TilesLay = nil then exit;
 if Group = nil then exit;
 if FTabName = '' then exit;
 if RowHeight <= 0 then RowHeight := 48;
//
 TilesLay.BeginUpdate;
 try
  while TilesLay.ControlsCount > 0 do TilesLay.Controls[0].Free;
//
  N := GetZnacksCount(FTabName);
  H := SB.Height;
  if H <= 0 then H := 1;
  VisRows := Trunc(H / RowHeight);
  if VisRows < 1 then VisRows := 1;
  Cols := Ceil(N / VisRows);
  if Cols < 1 then Cols := 1;
  FVisRows := VisRows;
//
  TilesLay.Width := Cols * RowHeight;
  TilesLay.Height := VisRows * RowHeight;
//
  for Idx := 0 to N - 1 do begin
   Col := Idx div VisRows;
   Row := Idx mod VisRows;
   T := TSkPaintBox.Create(Self);
   T.Stored := False;
   T.Parent := TilesLay;
   T.Width := RowHeight;
   T.Height := RowHeight;
   T.Position.X := Col * RowHeight;
   T.Position.Y := Row * RowHeight;
   T.HitTest := True;
   T.Tag := Idx;
// плитка рисуется из кэша: на GPU-канве форма перерисовывается целиком при
// каждой перерисовке карты (кэш Raster там не работает); InvalidateTiles -> Redraw
   T.DrawCacheKind := TSkDrawCacheKind.Always;
   T.OnDraw := TileDraw;
   T.OnClick := TileClick;
   T.OnMouseDown := TileMouseDown;
   T.OnMouseMove := TileMouseMove;
   T.OnMouseUp := TileMouseUp;
  end;
 finally
  TilesLay.EndUpdate;
 end;
end;

procedure TInstPointsFrame.TileClick(Sender: TObject);
var Idx: Integer;
begin
 if not (Sender is TControl) then exit;
 Idx := TControl(Sender).Tag;
 if (CB <> nil) and (Idx >= 0) and (Idx < CB.Items.Count) then begin
 // при смене знака слой и обработчик мыши обновляет CBChange
  if CB.ItemIndex <> Idx then CB.ItemIndex := Idx else SelectZnak(Idx);
 // передаем знак в TPropEditorFrame (PropEditorForm)
  if PropEditorForm.ActivePropRow <> nil then
   if (PropEditorForm.ActivePropRow.TypeName = 'PointType') or
       (PropEditorForm.ActivePropRow.TypeName = 'PointType') then begin
    PropEditorForm.ActivePropRow.Value := IntToStr(CurGroup.Item[Idx].znakNum);
   // update
   end else
   if (PropEditorForm.ActivePropRow.TypeName = 'Block') then begin
    PropEditorForm.ActivePropRow.Value := CurGroup.Item[Idx].znakName;
   end;
  InvalidateTiles;
 end;
end;

procedure TInstPointsFrame.CBChange(Sender: TObject);
begin
 if CB.ItemIndex = -1 then Exit;
 EnsureSelectedTileVisible;
 SelectZnak(CB.ItemIndex);
 InvalidateTiles;
end;

// выбор знака (TinstPoints.CBPointZnakClick старой программы): слой знака
// становится активным; выделенные объекты TEditMap.Objects, подходящие фрейму
// (AcceptObject), у которых знак другой (ZnakDiffers), получают знак и слой
// знака (ObjectsLayer). Объекты с этим знаком не меняются совсем, в т.ч. слой.
// При смене вкладки (первый знак) выделенные объекты не меняются
function TInstPointsFrame.CurGroup: TGroupZnk;
begin
 Result := nil;
 if Group = nil then exit;
 if FTabName <> '' then Result := Group.GroupByName[FTabName];
 if (Result = nil) and (TC <> nil) and (TC.TabIndex >= 0) and (TC.TabIndex < Group.Count) then Result := Group.Group[TC.TabIndex];
end;

procedure TInstPointsFrame.SelectZnak(Idx: Integer);
var ZV: TZnakView;
    G: TGroupZnk;
begin
 G := CurGroup;
 if (G = nil) or (Idx < 0) or (Idx >= G.Items.Count) then exit;
 ZV := G.Item[Idx];
 if ZV = nil then exit;
 if LayerFrame <> nil then LayerFrame.SetActiveLayerByName(ZV.znakLayer);
 if not FTabChanging and (PropEditorForm <> nil) then
 // ничего не выделено - знак становится свойством по умолчанию новых примитивов
  if not PropEditorForm.HasSelection then begin
   if UserPropName <> '' then PropEditorForm.SetDefaultProperty(UserPropName, IntToStr(ZV.znakNum));
  end else
  try
   PropEditorForm.ApplyToObjects('SetZnak...' + UserPropName, ObjectsLayer(ZV),
    function(Obj: TObject): Boolean begin Result := AcceptObject(Obj) and ZnakDiffers(Obj, ZV); end,
    procedure(Obj: TObject) begin ApplyZnak(Obj, ZV); end);
  except
   exit;
  end;
 DoZnakSelected;
end;

// слой для объектов, получивших знак: слой знака; nil (слой знака не задан
// или не найден) - слой объектов не меняется
function TInstPointsFrame.ObjectsLayer(ZV: TZnakView): TResource;
begin
 Result := nil;
 if (TwgForm <> nil) and (ZV.znakLayer <> '') then Result := TwgForm.LayerTable.LayerName[AnsiString(ZV.znakLayer)];
end;

// у объекта другой знак (свойство UserPropName) - знак будет применен
function TInstPointsFrame.ZnakDiffers(Obj: TObject; ZV: TZnakView): Boolean;
begin
 Result := string(TTD(Obj).GetProperty(AnsiString(UserPropName))) <> IntToStr(ZV.znakNum);
end;

// знак меняется у точек без блока (TDotText - надписи)
function TInstPointsFrame.AcceptObject(Obj: TObject): Boolean;
begin
 Result := (Obj is TPointDot) and not (Obj is TDotText) and (TPointDot(Obj).userObj = nil);
end;

procedure TInstPointsFrame.ApplyZnak(Obj: TObject; ZV: TZnakView);
begin
 TTD(Obj).SetProperty(AnsiString(UserPropName), AnsiString(IntToStr(ZV.znakNum)));
end;

function TInstPointsFrame.SelectZnakByNum(const TabName: String; ZnakNum: Integer): Boolean;
var I, T: Integer;
    G: TGroupZnk;
begin
 Result := False;
 if (Group = nil) or (TC = nil) or (CB = nil) then exit;
 T := -1;
 for I := 0 to TC.TabCount - 1 do
  if TC.Tabs[I].Text = TabName then begin T := I; break; end;
 if T = -1 then exit;
 if TC.TabIndex <> T then TC.TabIndex := T;
 G := Group.Group[T];
 for I := 0 to G.Items.Count - 1 do
  if G.Item[I].znakNum = ZnakNum then begin
   if CB.ItemIndex <> I then CB.ItemIndex := I else SelectZnak(I);
   InvalidateTiles;
   exit(True);
  end;
end;

// номер выбранного знака; -1 - знак не выбран (знак по слою)
function TInstPointsFrame.SelectedZnakNum: Integer;
begin
 Result := -1;
 if (CB = nil) or (CB.ItemIndex < 0) or (Group = nil) or (TC.TabIndex < 0) then exit;
 Result := CurGroup.Item[CB.ItemIndex].znakNum;
end;

// флажок cbActivate («активировать слой при выборе»): выделенные объекты при
// смене знака переносятся в слой знака
function TInstPointsFrame.LayerToObjects: Boolean;
begin
 Result := (pnlTools <> nil) and pnlTools.Visible and (cbActivate <> nil) and cbActivate.Enabled and cbActivate.IsChecked;
end;

procedure TInstPointsFrame.DoZnakSelected;
begin
 if Assigned(OnZnakSelected) then OnZnakSelected(Self);
end;

// кнопки установки знаков: Tag - код операции objTopo32 (mp_SetP = 1,
// mp_RotateP = 2, mp_SetPAttr = 3, mp_SetPPerLine = 5)
procedure TInstPointsFrame.sbSetPointClick(Sender: TObject);
begin
 if Assigned(OnTool) then OnTool(Self, TComponent(Sender).Tag);
end;

procedure TInstPointsFrame.EnsureSelectedTileVisible;
var
 Idx: Integer;
 Col: Integer;
 TileLeft: Single;
 TileRight: Single;
 ViewLeft: Single;
 ViewRight: Single;
 NewViewLeft: Single;
 MaxViewLeft: Single;
 W: Single;
begin
 if CB = nil then Exit;
 if SB = nil then Exit;
 if TilesLay = nil then Exit;
 if FVisRows <= 0 then Exit;
 if RowHeight <= 0 then Exit;
 Idx := CB.ItemIndex;
 if Idx < 0 then Exit;

 Col := Idx div FVisRows;
 TileLeft := Col * RowHeight;
 TileRight := TileLeft + RowHeight;

 ViewLeft := SB.ViewportPosition.X;
 W := SB.Width;
 if W <= 0 then Exit;
 ViewRight := ViewLeft + W;

 // if fully visible - do nothing
 if (TileLeft >= ViewLeft) and (TileRight <= ViewRight) then Exit;

 NewViewLeft := ViewLeft;
 if TileLeft < ViewLeft then
  NewViewLeft := TileLeft
 else if TileRight > ViewRight then
  NewViewLeft := TileRight - W;

 MaxViewLeft := Max(0, TilesLay.Width - W);
 if NewViewLeft < 0 then NewViewLeft := 0;
 if NewViewLeft > MaxViewLeft then NewViewLeft := MaxViewLeft;

 if Abs(NewViewLeft - ViewLeft) > 0.1 then
  SB.ViewportPosition := PointF(NewViewLeft, SB.ViewportPosition.Y);
end;

procedure TInstPointsFrame.InvalidateTiles;
var
 I: Integer;
begin
 if TilesLay = nil then Exit;
 for I := 0 to TilesLay.ControlsCount - 1 do
  if TilesLay.Controls[I] is TSkPaintBox then
   TSkPaintBox(TilesLay.Controls[I]).Redraw;
end;

procedure TInstPointsFrame.TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
 Idx: Integer;
 Sign: TPoint_Sign;
 H: Single;
 CenterY: Single;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not (Sender is TControl) then Exit;
 if (Group = nil) or (FTabName = '') then Exit;
 Idx := TControl(Sender).Tag;
 if (Idx < 0) or (Idx >= GetZnacksCount(FTabName)) then Exit;
 Sign := GetZnakPoint(FTabName, Idx);
 if Sign = nil then Exit;

 // select tile
 if (CB <> nil) and (Idx >= 0) and (Idx < CB.Items.Count) then
  CB.ItemIndex := Idx;

 // remember tile index where the drag started
 FDragScaleActive := True;
 FDragScaleTileIdx := Idx;
 FDragScaleKey := SignLocalScaleKey(Name, FTabName, Sign);
 FDragScaleTileControl := TControl(Sender);
 if Sign.LocalScale <= 0 then Sign.LocalScale := 1;
 FDragScaleStart := Sign.LocalScale;
 H := TControl(Sender).Height;
 if H <= 1 then H := 1;
 CenterY := H * 0.5;
 FDragScaleStartDist := Abs(Y - CenterY);
 InvalidateTiles;
end;

procedure TInstPointsFrame.TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
 Idx: Integer;
begin
 if not FDragScaleActive then Exit;
 if not (Sender is TControl) then Exit;
 Idx := TControl(Sender).Tag;
 if Idx <> FDragScaleTileIdx then Exit;
 DragScaleUpdateFromControlCoords(TControl(Sender), X, Y);
end;

procedure TInstPointsFrame.TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FDragScaleActive then Exit;
 DragScaleCommit;
end;

function TInstPointsFrame.UserPropName: String;
begin
 Result := 'Знак';
end;

procedure TInstPointsFrame.SBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
 AbsPt: TPointF;
 LocalPt: TPointF;
begin
 if not FDragScaleActive then Exit;
 if SB = nil then Exit;
 if FDragScaleTileControl = nil then Exit;
 // Convert SB local coords -> screen/absolute -> active tile local coords
 AbsPt := SB.LocalToAbsolute(PointF(X, Y));
 LocalPt := FDragScaleTileControl.AbsoluteToLocal(AbsPt);
 DragScaleUpdateFromControlCoords(FDragScaleTileControl, LocalPt.X, LocalPt.Y);
end;

procedure TInstPointsFrame.SBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FDragScaleActive then Exit;
 DragScaleCommit;
end;

procedure TInstPointsFrame.DragScaleUpdateFromControlCoords(const AControl: TControl; const AX, AY: Single);
var
 Idx: Integer;
 Sign: TPoint_Sign;
 H: Single;
 CenterY: Single;
 Dist: Single;
 DeltaDist: Single;
 NewScale: Single;
begin
 if not FDragScaleActive then Exit;
 if (Group = nil) or (FTabName = '') then Exit;
 Idx := FDragScaleTileIdx;
 if (Idx < 0) or (Idx >= GetZnacksCount(FTabName)) then Exit;
 Sign := GetZnakPoint(FTabName, Idx);
 if Sign = nil then Exit;
 if AControl = nil then Exit;

 H := AControl.Height;
 if H <= 1 then Exit;

 CenterY := H * 0.5;
 Dist := Abs(AY - CenterY);
 DeltaDist := Dist - FDragScaleStartDist;
 // debug-friendly: linear scale from delta distance to center
 NewScale := FDragScaleStart + (DeltaDist * 0.1);
 if NewScale < 0.1 then NewScale := 0.1;
 if NewScale > 10 then NewScale := 10;
 Sign.LocalScale := NewScale;
 MarkDirtyScale(SignLocalScaleKey(Name, FTabName, Sign), Sign);
 InvalidateTiles;
end;

procedure TInstPointsFrame.DragScaleCommit;
var
 Idx: Integer;
 Sign: TPoint_Sign;
begin
 if not FDragScaleActive then Exit;
 Idx := FDragScaleTileIdx;
 FDragScaleActive := False;

 if (Group = nil) or (FTabName = '') then
 begin
  FDragScaleKey := '';
  FDragScaleTileIdx := -1;
  FDragScaleTileControl := nil;
  Exit;
 end;
 if (Idx < 0) or (Idx >= GetZnacksCount(FTabName)) then
 begin
  FDragScaleKey := '';
  FDragScaleTileIdx := -1;
  FDragScaleTileControl := nil;
  Exit;
 end;
 Sign := GetZnakPoint(FTabName, Idx);
 if Sign <> nil then
  if Sign.LocalScale <= 0 then Sign.LocalScale := 1;

 FDragScaleKey := '';
 FDragScaleTileIdx := -1;
 FDragScaleTileControl := nil;
 InvalidateTiles;
end;

procedure TInstPointsFrame.TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single);
var Idx: Integer;
    Sign: TPoint_Sign;
    Sect: TSect;
    W0: Single;
    H0: Single;
    PixPerMm: Single;
    DX: Single;
    DY: Single;
    P: ISkPaint;
    Geo: TGeometryEvents;
    R: TRectF;
    Pad: Single;
    IsSelected: Boolean;
begin
 if not (Sender is TControl) then exit;
 Idx := TControl(Sender).Tag;
 Sign := nil;
 if (Group <> nil) and (FTabName <> '') then begin
  if (Idx >= 0) and (Idx < GetZnacksCount(FTabName)) then Sign := GetZnakPoint(FTabName, Idx);
 end;
//
 P := TSkPaint.Create;
 P.AntiAlias := True;
 IsSelected := (CB <> nil) and (CB.ItemIndex = Idx);
 if IsSelected then
  P.Color := $FFE8F3FF
 else
  P.Color := $FFF8F8F8;
 Canvas.DrawRect(Dest, P);
 if IsSelected then
  P.Color := $FF3399FF
 else
  P.Color := $FFB0B0B0;
 P.Style := TSkPaintStyle.Stroke;
 Canvas.DrawRect(Dest, P);
 if Sign = nil then Exit;
//
 Sect := Sign.GetRect1;
 W0 := Abs(Sect.Right - Sect.Left);
 H0 := Abs(Sect.Bottom - Sect.Top);
 if W0 <= 0 then W0 := 1;
 if H0 <= 0 then H0 := 1;
 Pad := 4;
 R := Dest;
 R.Inflate(-Pad, -Pad);
 if R.Width <= 1 then Exit;
 if R.Height <= 1 then Exit;

 if Sign.LocalScale <= 0 then Sign.LocalScale := 1;

 PixPerMm := Min(R.Width, R.Height) * FScale * Sign.LocalScale / 48;
 if PixPerMm <= 0 then Exit;
 DX := R.Left + (R.Width - W0 * PixPerMm) * 0.5 - Sect.Left * PixPerMm;
 DY := R.Top + (R.Height - H0 * PixPerMm) * 0.5 - Sect.Top * PixPerMm;
//
 GTileCanvas := Canvas;
 GTileScale := PixPerMm;
 GTileDX := DX;
 GTileDY := DY;
 Geo := TGeometryEvents.Create(0, TileOnPoly, TileOnText);
 try
  Sign.DrawTo(Geo);
 finally
  Geo.Free;
  GTileCanvas := nil;
 end;
end;

initialization
finalization
 FreeAndNil(GTileTypefaces);
end.
