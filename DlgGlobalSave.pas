unit DlgGlobalSave;

// Сохранение карты в папку пользователя: окно TGlobalSaveForm - наследник окна
// открытия из облака (TGlobalOpenForm), работает с локальными папками.
// Корень - Android: «Внутреннее хранилище/Download», Windows: «Документы»;
// пользователь выбирает подпапку корня (можно перейти во вложенные и создать
// новую), для «Сохранить как» - и имя файла. Выбранная подпапка (путь от
// корня) хранится в Registry.ini (GlobalSaveFolder) и предлагается при
// следующем сохранении.
// Android 11 и новее: в Download программа видит и перезаписывает свои файлы и
// папки; файлы, положенные туда другими программами или с компьютера, могут
// быть не видны

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Layouts, FMX.Controls.Presentation, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  System.ImageList, FMX.ImgList, AppForms, DlgGlobalOpen;

type
  TGlobalSaveForm = class(TGlobalOpenForm)
    NameLay: TLayout;
    lName: TLabel;
    edName: TEdit;
  private
    FRoot: string;      // корень: Download (Android) или Документы (Windows)
    FLocalDir: string;  // текущая папка (полный путь)
    FFileName: string;  // имя файла по умолчанию (для «Сохранить»)
    FDone: TProc<string>;
    procedure ShowDir(const Dir: string);
    procedure LocalItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure SaveClick(Sender: TObject);
    procedure NewFolderClick(Sender: TObject);
    procedure SaveFormClose(Sender: TObject; var Action: TCloseAction);
    procedure Finish(const FullPath: string);
  end;

// окно сохранения: FileName - имя файла карты; AskName - «Сохранить как» (поле
// имени файла); Done - полный путь файла ('' - отмена)
procedure SaveMapPicker(const FileName: string; AskName: Boolean; const Done: TProc<string>);
// открываемая карта (выбранная на устройстве или скачанная из облака) -
// копия в папку исполнителя: окно сохранения, как у кнопки «Сохранить»; в той
// папке уже есть файл с тем же именем - заменить его, открыть имеющийся или
// отменить. Done - путь открываемой карты: копия, имеющийся файл; окно
// закрыто без выбора папки - исходный LocalPath; '' - не открывать
procedure CopyMapToUserFolder(const LocalPath: string; const Done: TProc<string>);

var
  GlobalSaveForm: TGlobalSaveForm;

implementation

uses
  System.IOUtils, FMX.DialogService, newProcs;

{$R *.fmx}

const
  FolderKey = 'GlobalSaveFolder'; // ключ Registry.ini: подпапка корня последнего сохранения

// корень папок сохранения
function SaveRoot: string;
begin
{$IFDEF ANDROID}
 Result := TPath.GetSharedDownloadsPath;
{$ELSE}
 Result := TPath.GetDocumentsPath;
{$ENDIF}
 Result := ExcludeTrailingPathDelimiter(Result);
end;

function WithGmf(const Name: string): string;
begin
 Result := Trim(Name);
 if (Result <> '') and not SameText(ExtractFileExt(Result), '.gmf') then Result := Result + '.gmf';
end;

procedure SaveMapPicker(const FileName: string; AskName: Boolean; const Done: TProc<string>);
var F: TGlobalSaveForm;
    Dir, Folder: string;
begin
 if not Assigned(Done) then exit;
 F := TGlobalSaveForm.Create(Application.MainForm);
 F.FDone := Done;
 F.FRoot := SaveRoot;
 F.FFileName := WithGmf(FileName);
 if F.FFileName = '' then F.FFileName := 'map.gmf';
// обработчики окна открытия заменяются своими
 F.OnClose := F.SaveFormClose;
 F.btnOpen.OnClick := F.SaveClick;
 F.btnGo.OnClick := F.NewFolderClick;
 F.ListView1.OnItemClick := F.LocalItemClick;
 F.edUrl.ReadOnly := True;
 F.btnOpen.Text := 'Сохранить';
 F.btnGo.Text := 'Новая папка';
 F.NameLay.Visible := AskName;
 F.edName.Text := F.FFileName;
 if AskName then F.Caption := 'Сохранить как' else F.Caption := 'Сохранить';
// папка прошлого сохранения (если она еще есть), иначе корень
 Folder := string(GReadString(FolderKey, ''));
 Dir := F.FRoot;
 if Folder <> '' then Dir := TPath.Combine(F.FRoot, Folder);
 try
  ForceDirectories(F.FRoot);
 except
 end;
 if not TDirectory.Exists(Dir) then Dir := F.FRoot;
 F.ShowDir(Dir);
 ShowDialog(F); // модально: Windows - окно, Android - панель поверх формы
end;

// копия Src в Dst (одноименный файл заменяется) и открытие копии; ошибка
// копирования - сообщение и открытие Src
procedure CopyMapAndOpen(const Src, Dst: string; const Done: TProc<string>);
begin
 try
  if TFile.Exists(Dst) then begin
   try
    TFile.SetAttributes(Dst, []);
   except
   end;
   TFile.Delete(Dst);
  end;
  TFile.Copy(Src, Dst);
 except
  on E: Exception do begin
   ShowMessage('Карта не скопирована в папку: ' + E.Message);
   Done(Src);
   exit;
  end;
 end;
 Done(Dst);
end;

procedure CopyMapToUserFolder(const LocalPath: string; const Done: TProc<string>);
begin
 if not Assigned(Done) then exit;
 if LocalPath = '' then begin
  Done('');
  exit;
 end;
 SaveMapPicker(ExtractFileName(LocalPath), False,
  procedure(FullPath: string)
  begin
  // папка не выбрана - карта открывается там, куда ее положил выбор/скачивание
   if FullPath = '' then begin
    Done(LocalPath);
    exit;
   end;
   if SameText(ExpandFileName(FullPath), ExpandFileName(LocalPath)) then begin
    Done(FullPath);
    exit;
   end;
   if not TFile.Exists(FullPath) then begin
    CopyMapAndOpen(LocalPath, FullPath, Done);
    exit;
   end;
  // в папке исполнителя уже есть эта карта (возможно, с его изменениями)
   TDialogService.MessageDialog('В папке уже есть ' + ExtractFileName(FullPath) + '.' + sLineBreak +
    'Да - заменить ее открываемой картой, Нет - открыть имеющуюся.', TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel], TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
     case AResult of
      mrYes: CopyMapAndOpen(LocalPath, FullPath, Done);
      mrNo: Done(FullPath);
     end;
    end);
  end);
end;

{ TGlobalSaveForm }

// содержимое папки: '..' (кроме корня), папки, карты .gmf (выбор - имя файла)
procedure TGlobalSaveForm.ShowDir(const Dir: string);
var Item: TListViewItem;
    S: string;
begin
 FLocalDir := ExcludeTrailingPathDelimiter(Dir);
 edUrl.Text := FLocalDir;
 ListView1.BeginUpdate;
 try
  ListView1.Items.Clear;
  if not SameText(FLocalDir, FRoot) then begin
   Item := ListView1.Items.Add;
   Item.Text := '..';
   Item.Tag := 1;
   Item.ImageIndex := -1;
  end;
  try
   for S in TDirectory.GetDirectories(FLocalDir) do begin
    Item := ListView1.Items.Add;
    Item.Text := ExtractFileName(S);
    Item.TagString := S;
    Item.Tag := 2;
    Item.ImageIndex := 0; // ImageList1: папка
   end;
   for S in TDirectory.GetFiles(FLocalDir, '*.gmf') do begin
    Item := ListView1.Items.Add;
    Item.Text := ExtractFileName(S);
    Item.TagString := S;
    Item.Tag := 0;
    Item.ImageIndex := 1; // ImageList1: карта
   end;
   lStatus.Text := '';
  except
   on E: Exception do lStatus.Text := 'Папка недоступна: ' + E.Message;
  end;
 finally
  ListView1.EndUpdate;
 end;
 btnOpen.Enabled := True;
end;

// '..' и папки - переход (не выше корня); карта - ее имя в поле имени
procedure TGlobalSaveForm.LocalItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
 if AItem = nil then exit;
 case AItem.Tag of
  1: ShowDir(ExtractFileDir(FLocalDir));
  2: ShowDir(AItem.TagString);
 else
  if NameLay.Visible then edName.Text := AItem.Text;
 end;
end;

procedure TGlobalSaveForm.NewFolderClick(Sender: TObject);
begin
 TDialogService.InputQuery('Новая папка', ['Имя папки'], [''],
  procedure(const AResult: TModalResult; const AValues: array of string)
  var Name, Dir: string;
  begin
   if AResult <> mrOk then exit;
   Name := Trim(AValues[0]);
   if (Name = '') or not TPath.HasValidFileNameChars(Name, False) then begin
    lStatus.Text := 'Недопустимое имя папки';
    exit;
   end;
   Dir := TPath.Combine(FLocalDir, Name);
   try
    ForceDirectories(Dir);
    ShowDir(Dir);
   except
    on E: Exception do lStatus.Text := 'Папка не создана: ' + E.Message;
   end;
  end);
end;

// путь файла: текущая папка + имя; «Сохранить как» с именем существующего
// файла - подтверждение перезаписи
procedure TGlobalSaveForm.SaveClick(Sender: TObject);
var Name, FullPath: string;
begin
 if NameLay.Visible then Name := WithGmf(edName.Text) else Name := FFileName;
 if (Name = '') or not TPath.HasValidFileNameChars(Name, False) then begin
  lStatus.Text := 'Недопустимое имя файла';
  exit;
 end;
 FullPath := TPath.Combine(FLocalDir, Name);
 if NameLay.Visible and TFile.Exists(FullPath) then
  TDialogService.MessageDialog('Файл ' + Name + ' уже есть. Заменить?', TMsgDlgType.mtConfirmation,
   [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
   procedure(const AResult: TModalResult)
   begin
    if AResult = mrYes then Finish(FullPath);
   end)
 else
  Finish(FullPath);
end;

// подпапка - в Registry.ini; окно закрывается, Done - после закрытия
// (сохранение и его сообщение - уже без окна)
procedure TGlobalSaveForm.Finish(const FullPath: string);
var CB: TProc<string>;
    Folder: string;
begin
 Folder := '';
 if Length(FLocalDir) > Length(FRoot) then Folder := Copy(FLocalDir, Length(FRoot) + 2, MaxInt);
 GWriteString(FolderKey, AnsiString(Folder));
 CB := FDone;
 FDone := nil;
 Close;
 if Assigned(CB) then TThread.ForceQueue(nil, procedure begin CB(FullPath); end);
end;

// закрытие без сохранения - Done('')
procedure TGlobalSaveForm.SaveFormClose(Sender: TObject; var Action: TCloseAction);
var CB: TProc<string>;
begin
 CB := FDone;
 FDone := nil;
 if Assigned(CB) then CB('');
 Action := TCloseAction.caFree;
end;

end.
