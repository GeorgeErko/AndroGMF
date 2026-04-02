unit instPointSign;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.TabControl, FMX.Controls.Presentation,
  WPTForm2, newLayersTable, System.ImageList, FMX.ImgList, FMX.Layouts,
  FMX.ListBox, FMX.ScrollBox, FMX.Skia,
  Lib, System.Skia;

type
  TInstPointsFrame = class(TFrame)
    TC: TTabControl;
    Panel1: TPanel;
    btnTabs: TButton;
    ImageList1: TImageList;
    LB: TListBox;
    CB: TComboBox;
    Lay: TLayout;
    SB: THorzScrollBox;
    procedure Button2Click(Sender: TObject);
    procedure btnTabsClick(Sender: TObject);
    procedure LBChange(Sender: TObject);
  private
   FTwgForm: TForm2;
   RowHeight: Integer;
   FTabName: String;
   FVisRows: Integer;
   TilesLay: TLayout;
    procedure SetTwgForm(const Value: TForm2);
    procedure ChangeTab(Sender: TObject);
    procedure EnsureControls;
    procedure InitControls; virtual;
    procedure TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single);
    procedure TileClick(Sender: TObject);
    procedure RebuildTiles;
  // доступ к коллекции знаков
    function GetZnacksCount(TabName_: String): Integer;
    function GetZnakIndex(TabName_:String;Index:Integer):Integer;virtual;
    function GetZnakName (TabName_:String;Index:Integer):String;virtual;
    function GetZnakLayer(TabName_:String;Index:Integer):String;virtual;
    function GetZnakPoint(TabName_:String;Index:Integer):TPoint_Sign;virtual;
  public
   function Group: TGroupCollection;
   property TwgForm: TForm2 read FTwgForm write SetTwgForm;
  end;

implementation uses newProcs;

{$R *.fmx}

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

procedure TInstPointsFrame.InitControls;
begin
{ TabName:=GReadString(Name+'_TabName','');
 ZnakNum:=GReadInteger(Name+'_ZnakNum',1);
 Koef:=GReadInteger(Name+'_Koef',3);
 Columns:=GReadInteger(Name+'_Columns',5);
 RowHeight:=GReadInteger(Name+'_RowHeight',48);
 CBPointZnak.Columns:=Columns;
 CBPointZnak.ItemHeight:=RowHeight;
}
 RowHeight := GReadInteger(Name+'_RowHeight',48);
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
 FTwgForm := Value;
// заполнение вкладок
 If Group = nil then Exit;
 InitControls;
 For I := TC.TabCount - 1 downto 0  do TC.Delete(I);
 TC.TabPosition := TTabPosition.Bottom;
 For I := 0 to Group.Count - 1 do begin
  LB.Items.Add(Group[I].Name);
  Tab := TC.Add;
  Tab.Text := Group[I].Name;
  Tab.Visible := True;
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
 if SB = nil then SB := THorzScrollBox.Create(Self);
 SB.Stored := False;
  SB.ShowScrollBars := True;
  SB.AutoHide := True;
 Lay.Stored := False;
 Lay.Align := TAlignLayout.None;
 Lay.Position.X := 0;
 Lay.Position.Y := 0;
 if TilesLay = nil then begin
  TilesLay := TLayout.Create(Self);
  TilesLay.Stored := False;
  TilesLay.Align := TAlignLayout.None;
  TilesLay.Position.X := 0;
  TilesLay.Position.Y := 0;
  TilesLay.Parent := SB;
 end;
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
 Tab := TC.Tabs[Idx];
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
 if CB.Items.Count > 0 then CB.ItemIndex := 0;
 RebuildTiles;
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
   T.OnDraw := TileDraw;
   T.OnClick := TileClick;
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
 if (CB <> nil) and (Idx >= 0) and (Idx < CB.Items.Count) then CB.ItemIndex := Idx;
end;

procedure TInstPointsFrame.TileDraw(Sender: TObject; const Canvas: ISkCanvas; const Dest: TRectF; const Opacity: Single);
var Idx: Integer;
    S: String;
    P: ISkPaint;
    F: ISkFont;
    R: TRectF;
begin
 if not (Sender is TControl) then exit;
 Idx := TControl(Sender).Tag;
 S := '';
 if (Group <> nil) and (FTabName <> '') then begin
  if (Idx >= 0) and (Idx < GetZnacksCount(FTabName)) then S := GetZnakName(FTabName, Idx);
 end;
//
 P := TSkPaint.Create;
 P.AntiAlias := True;
 P.Color := $FFEFEFEF;
 Canvas.DrawRect(Dest, P);
 P.Color := $FF808080;
 P.Style := TSkPaintStyle.Stroke;
 Canvas.DrawRect(Dest, P);
//
 if S <> '' then begin
  P.Style := TSkPaintStyle.Fill;
  P.Color := $FF202020;
  F := TSkFont.Create(nil, 12);
  R := Dest;
  R.Inflate(-2, -2);
  Canvas.ClipRect(R);
  Canvas.DrawSimpleText(S, R.Left, R.Top + 12, F, P);
 end;
end;

end.
