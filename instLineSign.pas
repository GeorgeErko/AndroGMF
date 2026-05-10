unit instLineSign;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  instPointSign, System.ImageList, FMX.ImgList, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation, FMX.TabControl,
  newLayersTable, FMX.ScrollBox, FMX.Skia, System.Skia,
  Lines3, Collect, GMFLTDrawer, newSelector, ogcDrawerSkia, FMX.ExtCtrls;

type
  TInstLinesFrame = class(TInstPointsFrame)
    procedure btnMinusClick(Sender: TObject);
  private
   FVSB: TVertScrollBox;
   FEnsuringControls: Boolean;
   FDragScaleActiveL: Boolean;
   FDragScaleTileIdxL: Integer;
   FDragScaleStartL: Single;
   FDragScaleStartXL: Single;
   FDragScaleTileControlL: TControl;
   procedure VSBResize(Sender: TObject);
   procedure VSBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
   procedure VSBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure CBChange(Sender: TObject);
   procedure EnsureSelectedTileVisible; virtual;
   procedure TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
   procedure TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure DragScaleUpdateFromControlCoords(const AControl: TControl; const AX, AY: Single);
   procedure DragScaleCommit;
  public
   function Group: TGroupCollection; override;
  protected
   procedure EnsureControls; override;
   procedure InitControls; override;
   procedure RebuildTiles; override;
   procedure TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single); override;
   procedure LoadAllLocalScalesFromRegistry; override;
   procedure SaveAllLocalScalesToRegistry; override;
  end;

var
  InstLinesFrame: TInstLinesFrame;

implementation uses ogcBasic, types_dimano, newProcs;

{$R *.fmx}

{ TInstLinesFrame }

function LineLocalScaleKey(const AFrameName, ATabName: string; const ALineId: Integer): AnsiString; forward;

procedure TInstLinesFrame.TileMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var Idx: Integer;
    GL: TGeoLine;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not (Sender is TControl) then Exit;
 if (Group = nil) or (FTabName = '') then Exit;
 Idx := TControl(Sender).Tag;
 if (Idx < 0) or (Idx >= GetZnacksCount(FTabName)) then Exit;
 GL := TGeoLine(Group.GroupByName[FTabName].Item[Idx].Znak);
 if GL = nil then Exit;

 if (CB <> nil) and (Idx >= 0) and (Idx < CB.Items.Count) then
  CB.ItemIndex := Idx;

 FDragScaleActiveL := True;
 FDragScaleTileIdxL := Idx;
 FDragScaleTileControlL := TControl(Sender);
 if GL.LocalScale <= 0 then GL.LocalScale := 1;
 FDragScaleStartL := GL.LocalScale;
 FDragScaleStartXL := X;
 InvalidateTiles;
end;

procedure TInstLinesFrame.TileMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var Idx: Integer;
begin
 if not FDragScaleActiveL then Exit;
 if not (Sender is TControl) then Exit;
 Idx := TControl(Sender).Tag;
 if Idx <> FDragScaleTileIdxL then Exit;
 DragScaleUpdateFromControlCoords(TControl(Sender), X, Y);
end;

procedure TInstLinesFrame.TileMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FDragScaleActiveL then Exit;
 DragScaleCommit;
end;

procedure TInstLinesFrame.VSBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var AbsPt: TPointF;
    LocalPt: TPointF;
begin
 if not FDragScaleActiveL then Exit;
 if FVSB = nil then Exit;
 if FDragScaleTileControlL = nil then Exit;
 AbsPt := FVSB.LocalToAbsolute(PointF(X, Y));
 LocalPt := FDragScaleTileControlL.AbsoluteToLocal(AbsPt);
 DragScaleUpdateFromControlCoords(FDragScaleTileControlL, LocalPt.X, LocalPt.Y);
end;

procedure TInstLinesFrame.VSBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 if Button <> TMouseButton.mbLeft then Exit;
 if not FDragScaleActiveL then Exit;
 DragScaleCommit;
end;

procedure TInstLinesFrame.DragScaleUpdateFromControlCoords(const AControl: TControl; const AX, AY: Single);
var Idx: Integer;
    GL: TGeoLine;
    DeltaX: Single;
    NewScale: Single;
begin
 if not FDragScaleActiveL then Exit;
 if (Group = nil) or (FTabName = '') then Exit;
 Idx := FDragScaleTileIdxL;
 if (Idx < 0) or (Idx >= GetZnacksCount(FTabName)) then Exit;
 GL := TGeoLine(Group.GroupByName[FTabName].Item[Idx].Znak);
 if GL = nil then Exit;
 if AControl = nil then Exit;
//
 DeltaX := AX - FDragScaleStartXL;
 NewScale := FDragScaleStartL + (DeltaX * 0.01);
 if NewScale < 0.1 then NewScale := 0.1;
 if NewScale > 10 then NewScale := 10;
 GL.LocalScale := NewScale;
 MarkDirtyScale(LineLocalScaleKey(Name, FTabName, GL.IdNum), GL);
 InvalidateTiles;
end;

procedure TInstLinesFrame.DragScaleCommit;
begin
 if not FDragScaleActiveL then Exit;
 FDragScaleActiveL := False;
 FDragScaleTileIdxL := -1;
 FDragScaleTileControlL := nil;
 InvalidateTiles;
end;

function LineLocalScaleKey(const AFrameName, ATabName: string; const ALineId: Integer): AnsiString;
begin
 Result := AnsiString(AFrameName + '_' + ATabName + '_LineLocalScale_' + IntToStr(ALineId));
end;

procedure TInstLinesFrame.LoadAllLocalScalesFromRegistry;
var I: Integer;
    TabName: String;
    Idx: Integer;
    GL: TGeoLine;
    K: AnsiString;
begin
 if Group = nil then Exit;
 for I := 0 to Group.Count - 1 do
 begin
  TabName := Group[I].Name;
  if TabName = '' then Continue;
  for Idx := 0 to GetZnacksCount(TabName) - 1 do
  begin
   GL := TGeoLine(Group.GroupByName[TabName].Item[Idx].Znak);
   if GL = nil then Continue;
   K := LineLocalScaleKey(Name, TabName, GL.IdNum);
   GL.LocalScale := GReadFloat(K, GL.LocalScale);
   if GL.LocalScale <= 0 then GL.LocalScale := 1;
  end;
 end;
end;

procedure TInstLinesFrame.SaveAllLocalScalesToRegistry;
var I: Integer;
    GL: TGeoLine;
    K: AnsiString;
begin
 if (FDirtyScales = nil) or (FDirtyScales.Count = 0) then Exit;
 for I := 0 to FDirtyScales.Count - 1 do
 begin
  K := AnsiString(FDirtyScales[I]);
  GL := TGeoLine(FDirtyScales.Objects[I]);
  if GL = nil then Continue;
  if GL.LocalScale <= 0 then GL.LocalScale := 1;
  GWriteFloat(K, GL.LocalScale);
 end;
 FDirtyScales.Clear;
end;

function TInstLinesFrame.Group: TGroupCollection;
begin
 Result := nil;
 if TwgForm = nil then exit;
 Result:=TwgForm.LayerTable.MkLib.LineGroup;
end;

procedure TInstLinesFrame.InitControls;
begin
 inherited;
 if RowHeight <= 0 then RowHeight := 24;
 if RowHeight > 64 then RowHeight := 64;
end;

procedure TInstLinesFrame.EnsureControls;
var
 Tab: TTabItem;
 PrevOnResize: TNotifyEvent;
begin
 if FEnsuringControls then Exit;
 FEnsuringControls := True;
 PrevOnResize := nil;
 try
 inherited;
 if SB <> nil then SB.Visible := False;
 if CB <> nil then
  CB.OnChange := CBChange;
 if FVSB = nil then
 begin
  FVSB := TVertScrollBox.Create(Self);
  FVSB.Stored := False;
  FVSB.ShowScrollBars := True;
  FVSB.AutoHide := True;
  FVSB.OnResize := VSBResize;
  FVSB.OnMouseMove := VSBMouseMove;
  FVSB.OnMouseUp := VSBMouseUp;
 end;

 PrevOnResize := FVSB.OnResize;
 FVSB.OnResize := nil;
 FVSB.Parent := Lay;
 FVSB.Align := TAlignLayout.Client;
 FVSB.OnResize := PrevOnResize;
 if TilesLay <> nil then
  TilesLay.Parent := FVSB;

 // Ensure CB/Lay are placed exactly as in TInstPointsFrame.ChangeTab
 if TC <> nil then
 begin
  Tab := TC.ActiveTab;
  if (Tab = nil) and (TC.TabIndex >= 0) and (TC.TabIndex < TC.TabCount) then
   Tab := TC.Tabs[TC.TabIndex];
  if Tab <> nil then
  begin
   if CB <> nil then
   begin
    if not (csDestroying in Tab.ComponentState) then
     CB.Parent := Tab;
    CB.Align := TAlignLayout.Bottom;
   end;
   if Lay <> nil then
   begin
    if not (csDestroying in Tab.ComponentState) then
     Lay.Parent := Tab;
    Lay.Align := TAlignLayout.Client;
   end;
  end;
 end;
 finally
  FEnsuringControls := False;
 end;
end;

procedure TInstLinesFrame.btnMinusClick(Sender: TObject);
var Idx: Integer;
    GL: TGeoLine;
    K: AnsiString;
    DeltaScale: Single;
    I: Integer;
    TabName: String;
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
    GL := TGeoLine(Group.GroupByName[TabName].Item[Idx].Znak);
    if GL = nil then Continue;
    if GL.LocalScale <= 0 then GL.LocalScale := 1;
    GL.LocalScale := GL.LocalScale + DeltaScale;
    if GL.LocalScale < 0.1 then GL.LocalScale := 0.1;
    if GL.LocalScale > 10 then GL.LocalScale := 10;
    K := LineLocalScaleKey(Name, TabName, GL.IdNum);
    MarkDirtyScale(K, GL);
   end;
  end;
  InvalidateTiles;
 end else
  inherited;
end;

procedure TInstLinesFrame.CBChange(Sender: TObject);
var
 Idx: Integer;
begin
 if CB = nil then Exit;
 if FVSB = nil then Exit;
 EnsureSelectedTileVisible;
 Idx := CB.ItemIndex;
 if Idx < 0 then Exit;
 inherited CBChange(Sender);
end;

procedure TInstLinesFrame.EnsureSelectedTileVisible;
var
 Idx: Integer;
 TileTop: Single;
 TileBottom: Single;
 ViewTop: Single;
 ViewBottom: Single;
 NewViewTop: Single;
 MaxViewTop: Single;
 H: Single;
begin
 if CB = nil then Exit;
 if FVSB = nil then Exit;
 if TilesLay = nil then Exit;
 if RowHeight <= 0 then Exit;
 Idx := CB.ItemIndex;
 if Idx < 0 then Exit;

 TileTop := Idx * RowHeight;
 TileBottom := TileTop + RowHeight;

 ViewTop := FVSB.ViewportPosition.Y;
 H := FVSB.Height;
 if H <= 0 then Exit;
 ViewBottom := ViewTop + H;

 // if fully visible - do nothing
 if (TileTop >= ViewTop) and (TileBottom <= ViewBottom) then Exit;

 NewViewTop := ViewTop;
 if TileTop < ViewTop then
  NewViewTop := TileTop
 else if TileBottom > ViewBottom then
  NewViewTop := TileBottom - H;

 MaxViewTop := Max(0, TilesLay.Height - H);
 if NewViewTop < 0 then NewViewTop := 0;
 if NewViewTop > MaxViewTop then NewViewTop := MaxViewTop;

 if Abs(NewViewTop - ViewTop) > 0.1 then
  FVSB.ViewportPosition := PointF(FVSB.ViewportPosition.X, NewViewTop);
end;

procedure TInstLinesFrame.VSBResize(Sender: TObject);
begin
 if FEnsuringControls then Exit;
 RebuildTiles;
end;

procedure TInstLinesFrame.RebuildTiles;
var
 N: Integer;
 Idx: Integer;
 T: TSkPaintBox;
 W: Single;
begin
 EnsureControls;
 if FVSB = nil then Exit;
 if TilesLay = nil then Exit;
 if Group = nil then Exit;
 if FTabName = '' then Exit;
 if RowHeight <= 0 then RowHeight := 24;

 TilesLay.BeginUpdate;
 try
  while TilesLay.ControlsCount > 0 do TilesLay.Controls[0].Free;
  N := GetZnacksCount(FTabName);

  W := FVSB.Width;
  if W <= 0 then W := Lay.Width;
  if W <= 0 then W := 1;

  TilesLay.Position.X := 0;
  TilesLay.Position.Y := 0;
  TilesLay.Width := W;
  TilesLay.Height := N * RowHeight;

  for Idx := 0 to N - 1 do
  begin
   T := TSkPaintBox.Create(Self);
   T.Stored := False;
   T.Parent := TilesLay;
   T.Align := TAlignLayout.None;
   T.Width := W;
   T.Height := RowHeight;
   T.Position.X := 0;
   T.Position.Y := Idx * RowHeight;
   T.HitTest := True;
   T.Tag := Idx;
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

procedure TInstLinesFrame.TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single);
var
 Idx: Integer;
 S: String;
 P: ISkPaint;
 F: ISkFont;
 R: TRectF;
 GL: TGeoLine;
 Drawer: TogsDrawer;
 DrawerSkia: TogsDrawerSkia;
 OldUseWorldCoords: Boolean;
 SampleLine: PCollection;
 SampleRect: TRectF;
 X0, X1, Y0: Single;
 IsSelected: Boolean;
begin
 if not (Sender is TControl) then Exit;
 Idx := TControl(Sender).Tag;
 S := '';
 GL := nil;
 if (Group <> nil) and (FTabName <> '') then
  if (Idx >= 0) and (Idx < GetZnacksCount(FTabName)) then
  begin
   S := GetZnakName(FTabName, Idx);
   GL := TGeoLine(Group.GroupByName[FTabName].Item[Idx].Znak);
  end;

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

 if S <> '' then
 begin
  P.Style := TSkPaintStyle.Fill;
  P.Color := $FF202020;
  F := TSkFont.Create(nil, 12);
  R := Dest;
  R.Inflate(-4, -2);
  // left side: draw line sample; right side: draw name
  SampleRect := R;
  SampleRect.Right := Min(SampleRect.Left + 160, SampleRect.Right);

  Drawer := nil;
  if (TwgForm <> nil) and (TwgForm.Selector <> nil) then
   Drawer := TwgForm.Selector.Drawer;

  if (GL <> nil) and (Drawer is TogsDrawerSkia) then
  begin
   DrawerSkia := TogsDrawerSkia(Drawer);
   OldUseWorldCoords := DrawerSkia.UseWorldCoords;
   DrawerSkia.UseWorldCoords := True;
   SampleLine := PCollection.Create(2);
   try
    X0 := SampleRect.Left + 4;
    X1 := SampleRect.Right - 4;
    Y0 := SampleRect.Top + SampleRect.Height * 0.5;
    SampleLine.Insert(TDot1.Create(X0, Y0));
    SampleLine.Insert(TDot1.Create(X1, Y0));

    Canvas.Save;
    try
     Canvas.ClipRect(SampleRect);
     DrawerSkia.BeginFrame(Canvas, Dest);
     try
      if GL.LocalScale <= 0 then GL.LocalScale := 1;
      DrawGeoLine(DrawerSkia, GL, SampleLine, 10 * GL.LocalScale, 1, 0, False, $000000);
     finally
      DrawerSkia.EndFrame;
     end;
    finally
     Canvas.Restore;
    end;
   finally
    SampleLine.Free;
    DrawerSkia.UseWorldCoords := OldUseWorldCoords;
   end;
  end;

  R.Left := SampleRect.Right + 8;
  if R.Left < R.Right then
  begin
   Canvas.Save;
   try
    Canvas.ClipRect(R);
    Canvas.DrawSimpleText(S, R.Left, R.Top + 12, F, P);
   finally
    Canvas.Restore;
   end;
  end;
 end;
end;

end.
