unit InstBlockSign;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  instPointSign, System.ImageList, FMX.ImgList, FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation, FMX.TabControl,
  newLayersTable, WPTForm2, FMX.Skia, System.Skia;

type
  TInstBlocksFrame = class(TInstPointsFrame)
  protected
   fGroup:TGroupCollection;
   procedure ClearExtraResources; override;
   procedure SetTwgForm(const Value: TForm2); override;
   procedure TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single); override;
  public
   function Group: TGroupCollection; override;
  end;

var
  InstBlocksFrame: TInstBlocksFrame;

implementation uses newBlock, newResource, newSelector, Lib, ogcDrawerSkia, Writer;

{$R *.fmx}

var
 GBlockTileCanvas: ISkCanvas;
 GBlockTileScale: Single;
 GBlockTileWorldCx: Single;
 GBlockTileWorldCy: Single;
 GBlockTileDestCx: Single;
 GBlockTileDestCy: Single;
 GBlockTileStrokePaint: ISkPaint;
 GBlockTileFillPaint: ISkPaint;

procedure SetBlockTilePaintColor(var Paint: ISkPaint; C: Integer; Stroke: Boolean; W: Single);
var
 A: TAlphaColor;
begin
 if Paint = nil then Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 if Stroke then Paint.Style := TSkPaintStyle.Stroke else Paint.Style := TSkPaintStyle.Fill;
 Paint.StrokeWidth := W;
 A := TAlphaColor($FF000000 or (Cardinal(C) and $00FFFFFF));
 Paint.Color := A;
end;

function BlockTileTP(X, Y: Double): TPointF;
begin
 Result := PointF(
  (Single(X) - GBlockTileWorldCx) * GBlockTileScale + GBlockTileDestCx,
  (Single(Y) - GBlockTileWorldCy) * GBlockTileScale + GBlockTileDestCy
 );
end;

procedure BlockTileOnPoly(Obj: Integer; Poly: PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
var
 I: Integer;
 P0: PGeoPoint;
 Pt: TPointF;
 SW: Single;
 PathBuilder: ISkPathBuilder;
 Path: ISkPath;
begin
 if (GBlockTileCanvas = nil) or (Poly = nil) then Exit;
 if Poly.Count < 1 then Exit;
 PathBuilder := TSkPathBuilder.Create;
 P0 := Poly;
 for I := 0 to Poly.Count - 1 do
 begin
  Pt := BlockTileTP(P0.X, P0.Y);
  if I = 0 then PathBuilder.MoveTo(Pt.X, Pt.Y) else PathBuilder.LineTo(Pt.X, Pt.Y);
//  WriteIn(['xy=', Pt.X, Pt.Y]);
  P0 := P0.Next;
  if P0 = nil then Break;
 end;
 if isPolygon then PathBuilder.Close;
 Path := PathBuilder.Detach;
 if isPolygon and (brushColor <> 0) then
 begin
  SetBlockTilePaintColor(GBlockTileFillPaint, brushColor, False, 0);
  GBlockTileCanvas.DrawPath(Path, GBlockTileFillPaint);
 end;
 SW := Max(1, Single(lineWidth) * GBlockTileScale);
 SetBlockTilePaintColor(GBlockTileStrokePaint, penColor, True, SW);
 GBlockTileCanvas.DrawPath(Path, GBlockTileStrokePaint);
end;

procedure BlockTileOnText(Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
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
 if (GBlockTileCanvas = nil) or (Text = nil) then Exit;
 S := string(AnsiString(PAnsiChar(Text)));
 if S = '' then Exit;
 Pt := BlockTileTP(X, Y);
 PaintT := TSkPaint.Create;
 SetBlockTilePaintColor(PaintT, txtColor, False, 0);

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

 FontFile := '';
 if LocalFontName <> '' then
  FontFile := GetRegisteredSkiaFontFile(LocalFontName);
 if FontFile <> '' then
  try
   Typeface := TSkTypeface.MakeFromFile(FontFile);
  except
   Typeface := nil;
  end;
 if (Typeface = nil) and (LocalFontName <> '') then
  try
   Typeface := TSkTypeface.MakeFromName(LocalFontName, TSkFontStyle.Normal);
  except
   Typeface := nil;
  end;

 Weight := TSkFontWeight.Normal;
 if Bl then Weight := TSkFontWeight.Bold;
 Slant := TSkFontSlant.Upright;
 if It then Slant := TSkFontSlant.Italic;
 FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

 if (Typeface = nil) and (LocalFontName <> '') then
  try
   Typeface := TSkTypeface.MakeFromName(LocalFontName, FontStyle);
  except
   Typeface := nil;
  end;

 if Typeface = nil then
  try
{$IFDEF ANDROID}
   Typeface := TSkTypeface.MakeFromName('Roboto', FontStyle);
{$ELSE}
   Typeface := TSkTypeface.MakeFromName('Segoe UI', FontStyle);
{$ENDIF}
  except
   Typeface := nil;
  end;

 if Typeface = nil then Exit;

 HFullPix := Single(txtHeight) * GBlockTileScale;
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

 GBlockTileCanvas.Save;
 try
  GBlockTileCanvas.Translate(Pt.X, Pt.Y);
  if Abs(txtAngle) > 1e-6 then
   GBlockTileCanvas.Rotate(Single(txtAngle * 180 / Pi));
  if Abs(txtScale - 1) > 1e-6 then
   GBlockTileCanvas.Scale(Single(txtScale), 1);
  GBlockTileCanvas.DrawSimpleText(S, DrawX, DrawY, Font, PaintT);
 finally
  GBlockTileCanvas.Restore;
 end;
end;

{ TInstPointsFrame1 }

function TInstBlocksFrame.Group: TGroupCollection;
begin
 Result := fGroup;
end;

procedure TInstBlocksFrame.ClearExtraResources;
begin
 inherited;
 GBlockTileCanvas := nil;
 GBlockTileStrokePaint := nil;
 GBlockTileFillPaint := nil;
end;

procedure TInstBlocksFrame.SetTwgForm(const Value: TForm2);
var B:TGeoBlock;I:Integer;GroupName:String;
    GZ:TGroupZnk;ZV:TZnakView;
    Layer:TResource;
begin
 ClearTilesAndResources;
 FreeAndNil(fGroup);
 fGroup:=TGroupCollection.Create(1);
 FTwgForm := Value;
 With Value.Twigs.BlockList do begin
  // заполняем группы
  For I:=0 to Count-1 do begin
   B:=Block[I];
//   If B.GetProperty('Группа')=byLayer then B.SetProperty('Группа','Общие');
   GroupName:=B.GetProperty('Группа');
   GZ:=Group.GetGroupByName(GroupName);
   If GZ=nil then Group.AddGroup(GroupName);
   GZ:=Group.GetGroupByName(GroupName);
   ZV:=TZnakView.Create(B.Name{+':'+B.GetProperty('Идентификатор')},IntToStr(I),B);
   ZV.znakNum:=I;
   Layer:=Value.LayerTable.SearchLayer(B.AutoLayer);
   If Layer = nil then Layer:=Value.LayerTable.NULLLayer;
   ZV.znakLayer:=Layer.RecString;
   GZ.AddItem(ZV);
  end;
 end;
 inherited SetTwgForm(Value);
end;

procedure TInstBlocksFrame.TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single);
var
 Idx: Integer;
 Blk: TGeoBlock;
 Sect: TSect;
 BW: Single;
 BH: Single;
 Cx: Single;
 Cy: Single;
 Sx: Single;
 Sy: Single;
 S: Single;
 PixPerMm: Single;
 DX: Single;
 DY: Single;
 L: Single;
 T: Single;
 P: ISkPaint;
 Geo: TGeometryEvents;
 R: TRectF;
 Pad: Single;
 IsSelected: Boolean;
begin
 if not (Sender is TControl) then Exit;
 Idx := TControl(Sender).Tag;

 Blk := nil;
 if (Group <> nil) and (FTabName <> '') then
  if (Idx >= 0) and (Idx < GetZnacksCount(FTabName)) then
   Blk := TGeoBlock(Group.GroupByName[FTabName].Item[Idx].Znak);

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

 if Blk = nil then Exit;

 // draw via shared callbacks from instPointSign
 R := Dest;
 Pad := 5;
 R.Inflate(-Pad, -Pad);

 Sect := Blk.blockRect;
 if (Blk.TwgForm <> nil) then
 begin
  L := Min(Single(Sect.Left - (Blk.X + Blk.TwgForm.XXMin)), Single(Sect.Right - (Blk.X + Blk.TwgForm.XXMin)));
  T := Min(Single(Sect.Top - (Blk.Y + Blk.TwgForm.YYMin)), Single(Sect.Bottom - (Blk.Y + Blk.TwgForm.YYMin)));
 end
 else
 begin
  L := Min(Single(Sect.Left), Single(Sect.Right));
  T := Min(Single(Sect.Top), Single(Sect.Bottom));
 end;
 BW := Abs(Single(Sect.Right - Sect.Left));
 BH := Abs(Single(Sect.Bottom - Sect.Top));
 if BW <= 0 then BW := 1;
 if BH <= 0 then BH := 1;

 Sx := R.Width / BW;
 Sy := R.Height / BH;
 S := Min(Sx, Sy);
 if S <= 0 then Exit;
 DX := R.Left + (R.Width - BW * S) * 0.5 - L * S;
 DY := R.Top + (R.Height - BH * S) * 0.5 - T * S;

 GBlockTileCanvas := Canvas;
 GBlockTileScale := S;
 GBlockTileWorldCx := 0;
 GBlockTileWorldCy := 0;
 GBlockTileDestCx := DX;
 GBlockTileDestCy := DY;

 Geo := TGeometryEvents.Create(0, BlockTileOnPoly, BlockTileOnText);
 try
  Blk.DrawTo(Geo);
 finally
  Geo.Free;
  GBlockTileCanvas := nil;
 end;
end;

end.
