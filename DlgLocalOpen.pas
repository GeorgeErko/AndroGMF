unit DlgLocalOpen;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  GmfPickTypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView;

type
  TlocalOpenForm = class(TForm)
    ListView1: TListView;
    btnOpen: TButton;
    btnClose: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
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
end;

procedure TlocalOpenForm.ListView1Click(Sender: TObject);
begin
 If ListView1.Selected <> nil then
  btnOpen.Enabled := (ListView1.Selected.TagString <> '');
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
