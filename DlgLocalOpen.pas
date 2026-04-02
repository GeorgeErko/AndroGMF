unit DlgLocalOpen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, System.IOUtils,
  newProcs, FMX.DialogService, GmfPickTypes;

type
  TlocalOpenForm = class(TForm)
    ListView1: TListView;
    btnDelete: TButton;
    btnOpen: TButton;
    btnClose: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FAndroidDialogSetup: Boolean;
    procedure SetupAndroidDialog;
    procedure RefreshFiles;
    procedure Cancel;
  public
    FCallback: TPickGmfFileCallback;
    procedure Init(const ACallback: TPickGmfFileCallback);
  end;

var
  localOpenForm: TlocalOpenForm;

implementation

{$R *.fmx}

procedure TlocalOpenForm.Init(const ACallback: TPickGmfFileCallback);
begin
end;

procedure TlocalOpenForm.RefreshFiles;
var
 Files: TStringDynArray;
 I: Integer;
 Item: TListViewItem;
begin
 if ListView1 = nil then Exit;
 ListView1.BeginUpdate;
 try
  ListView1.Items.Clear;
  Files := TDirectory.GetFiles(TPath.GetDocumentsPath, '*.gmf');
  for I := 0 to Length(Files) - 1 do begin
   Item := ListView1.Items.Add;
   Item.Text := ExtractFileName(Files[I]);
   Item.TagString := Files[I];
  end;
 finally
  ListView1.EndUpdate;
 end;
 btnClose.Enabled := True;
end;

procedure TlocalOpenForm.Cancel;
var
 CB: TPickGmfFileCallback;
begin
 CB := FCallback;
 FCallback := nil;
 if Assigned(CB) then CB('');
end;

procedure TlocalOpenForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Cancel;
 Action := TCloseAction.caFree;
end;

procedure TlocalOpenForm.FormShow(Sender: TObject);
begin
{$IFDEF ANDROID}
// SetupAndroidDialog;
{$ENDIF}
 RefreshFiles;
 btnOpen.Enabled := False;
 btnDelete.Enabled := False;
end;

procedure TlocalOpenForm.SetupAndroidDialog;
var
  Overlay: TLayout;
  DimRect: TRectangle;
  PanelRect: TRectangle;
  PanelW: Single;
  PanelH: Single;
begin
  if FAndroidDialogSetup then
    Exit;
  FAndroidDialogSetup := True;

  Overlay := TLayout.Create(Self);
  Overlay.Parent := Self;
  Overlay.Align := TAlignLayout.Contents;
  Overlay.Stored := False;

  DimRect := TRectangle.Create(Self);
  DimRect.Parent := Overlay;
  DimRect.Align := TAlignLayout.Contents;
  DimRect.Fill.Kind := TBrushKind.Solid;
  DimRect.Fill.Color := $88000000;
  DimRect.Stroke.Kind := TBrushKind.None;
  DimRect.Stored := False;

  PanelRect := TRectangle.Create(Self);
  PanelRect.Parent := Overlay;
  PanelRect.Fill.Kind := TBrushKind.Solid;
  PanelRect.Fill.Color := $FFF0F0F0;
  PanelRect.Stroke.Kind := TBrushKind.Solid;
  PanelRect.Stroke.Color := $FF808080;
  PanelRect.XRadius := 12;
  PanelRect.YRadius := 12;
  PanelRect.Stored := False;

  PanelW := ClientWidth;
  PanelH := ClientHeight;
  if PanelW <= 0 then PanelW := 420;
  if PanelH <= 0 then PanelH := 440;
  if PanelW > 600 then PanelW := 600;
  if PanelH > 800 then PanelH := 800;
  PanelRect.Width := PanelW;
  PanelRect.Height := PanelH;
  PanelRect.Align := TAlignLayout.Center;

  if ListView1 <> nil then ListView1.Parent := PanelRect;
  if btnOpen <> nil then btnOpen.Parent := PanelRect;
  if btnClose <> nil then btnClose.Parent := PanelRect;
  if btnDelete <> nil then btnDelete.Parent := PanelRect;

  PanelRect.BringToFront;
end;

procedure TlocalOpenForm.ListView1Click(Sender: TObject);
begin
 If ListView1.Selected <> nil then
 begin
  btnOpen.Enabled := (ListView1.Selected.TagString <> '');
  btnDelete.Enabled := btnOpen.Enabled;
 end;
end;

procedure TlocalOpenForm.btnDeleteClick(Sender: TObject);
var
  Item: TListItem;
  Path: string;
begin
  if ListView1 = nil then Exit;
  Item := ListView1.Selected;
  if Item <> nil then Path := Item.TagString else Path := '';
  if Path = '' then Exit;

{$IFDEF ANDROID}
  TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
  TDialogService.MessageDialog('Delete file?', TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult <> mrYes then
        Exit;
      if TFile.Exists(Path) then
        TFile.Delete(Path);
      RefreshFiles;
      btnOpen.Enabled := False;
      btnDelete.Enabled := False;
    end);
{$ELSE}
  if newProcs.MessageConfirm('Delete file?') <> mrYes then
    Exit;
  if TFile.Exists(Path) then
    TFile.Delete(Path);
  RefreshFiles;
  btnOpen.Enabled := False;
  btnDelete.Enabled := False;
{$ENDIF}
end;

procedure TlocalOpenForm.btnOpenClick(Sender: TObject);
var
 Item: TListItem;
 Path: string;
 CB: TPickGmfFileCallback;
begin
 Item := ListView1.Selected;
 if Item <> nil then Path := Item.TagString else Path := '';
 CB := FCallback;
 FCallback := nil;
 if Assigned(CB) then CB(Path);
 Close;
end;

procedure TlocalOpenForm.btnCloseClick(Sender: TObject);
begin
 Close;
end;

end.
