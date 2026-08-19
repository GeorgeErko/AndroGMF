unit DlgLocalOpen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, System.IOUtils,
  newProcs, FMX.DialogService, GmfPickTypes, FMX.ListBox, FMX.Edit,
  System.Generics.Collections;

function GetAppExternalFilesDir: string;

type
  TlocalOpenForm = class(TForm)
    ListView1: TListView;
    Panel1: TPanel;
    Panel2: TPanel;
    btnClose: TButton;
    btnOpen: TButton;
    btnDelete: TButton;
    lPath: TEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FAndroidDialogSetup: Boolean;
    FBaseDir: string;
    FRootDir: string;
    FCurrentDir: string;
    procedure SetupAndroidDialog;
    procedure RefreshFiles;
    procedure RefreshPath(const ADir: string);
    procedure Cancel;
    procedure SetBaseDir(const Value: string);
  public
    FCallback: TPickGmfFileCallback;
    property BaseDir: string read FBaseDir write SetBaseDir;
    procedure Init(const ACallback: TPickGmfFileCallback);
  end;

var
  localOpenForm: TlocalOpenForm;

implementation

{$IFDEF ANDROID}
 uses
  Androidapi.Helpers,
  Androidapi.JNI.JavaTypes;
{$ENDIF}

{$R *.fmx}

function GetAppExternalFilesDir: string;
{$IFDEF ANDROID}
var Dir: JFile;
{$ENDIF}
begin
 Result := '';
{$IFDEF ANDROID}
 Dir := TAndroidHelper.Context.getExternalFilesDir(nil);
 if Dir <> nil then
  Result := JStringToString(Dir.getAbsolutePath);
{$ENDIF}
end;

procedure TlocalOpenForm.Init(const ACallback: TPickGmfFileCallback);
begin
end;

procedure TlocalOpenForm.SetBaseDir(const Value: string);
begin
 FBaseDir := Value;
 FRootDir := '';
 FCurrentDir := Value;
end;

procedure TlocalOpenForm.RefreshPath(const ADir: string);
begin
 if lPath = nil then Exit;
 lPath.Text := ADir;
end;

procedure TlocalOpenForm.RefreshFiles;
var
 Files: TStringDynArray;
 Dirs: TStringDynArray;
 I: Integer;
 Item: TListViewItem;
 Dir: string;
 ParentDir: string;
 FileList: TList<string>;
begin
 if ListView1 = nil then Exit;
 ListView1.BeginUpdate;
 try
  ListView1.Items.Clear;
  Dir := FCurrentDir;
  if Dir = '' then
   Dir := BaseDir;
  if Dir = '' then
  {$IFDEF ANDROID}
   Dir := TPath.GetSharedDocumentsPath;
  {$ELSE}
   Dir := TPath.GetLibraryPath;
  {$ENDIF}
  if Dir = '' then
   exit;

  RefreshPath(Dir);

  ParentDir := TDirectory.GetParent(Dir);
  if (ParentDir <> '') and (ParentDir <> Dir) then
  begin
   Item := ListView1.Items.Add;
   Item.Text := '..';
   Item.TagString := ParentDir;
   Item.Tag := 1;
  end;

  Dirs := TDirectory.GetDirectories(Dir);
  for I := 0 to Length(Dirs) - 1 do
  begin
   Item := ListView1.Items.Add;
   Item.Text := ExtractFileName(Dirs[I]);
   Item.TagString := Dirs[I];
   Item.Tag := 2;
  end;

  FileList := TList<string>.Create;
  try
   Files := TDirectory.GetFiles(Dir, '*.gmf');
   for I := 0 to Length(Files) - 1 do
    FileList.Add(Files[I]);
   Files := TDirectory.GetFiles(Dir, '*.gpkg');
   for I := 0 to Length(Files) - 1 do
    FileList.Add(Files[I]);
   Files := FileList.ToArray;
  finally
   FileList.Free;
  end;

  for I := 0 to Length(Files) - 1 do begin
   Item := ListView1.Items.Add;
   Item.Text := ExtractFileName(Files[I]);
   Item.TagString := Files[I];
   Item.Tag := 0;
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
 if ListView1 <> nil then
  ListView1.OnDblClick := ListView1DblClick;
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
  btnOpen.Enabled := (ListView1.Selected.TagString <> '') and (ListView1.Selected.Tag = 0);
  btnDelete.Enabled := btnOpen.Enabled;
 end;
end;

procedure TlocalOpenForm.ListView1DblClick(Sender: TObject);
var
 Item: TListItem;
 Path: string;
begin
 if ListView1 = nil then Exit;
 Item := ListView1.Selected;
 if Item <> nil then Path := Item.TagString else Path := '';
 if (Item <> nil) and (Path <> '') and (Item.Tag <> 0) then
 begin
  FCurrentDir := Path;
  RefreshFiles;
  btnOpen.Enabled := False;
  btnDelete.Enabled := False;
  Exit;
 end;
 if (Item <> nil) and (Item.Tag = 0) then
  btnOpenClick(Sender);
end;

procedure TlocalOpenForm.btnDeleteClick(Sender: TObject);
var
  Item: TListItem;
  Path: string;
begin
  if ListView1 = nil then Exit;
  Item := ListView1.Selected;
  if Item <> nil then Path := Item.TagString else Path := '';
  if (Item <> nil) and (Item.Tag <> 0) then Exit;
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
 if (Item <> nil) and (Item.Tag <> 0) then Exit;
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
