unit DlgLocalOpen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, System.IOUtils,
  newProcs, FMX.DialogService, GmfPickTypes;

type
  TlocalOpenForm = class(TForm)
    ListView1: TListView;
    btnOpen: TButton;
    btnClose: TButton;
    btnDelete: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
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
 RefreshFiles;
 btnOpen.Enabled := False;
 btnDelete.Enabled := False;
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
