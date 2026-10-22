unit DlgGlobalOpen;

// Открытие карты из облака по ссылке, как PickGmfFile (OpenForm) для файла
// на устройстве. Ссылка на общую папку Nextcloud
// (https://сервер/s/<токен>?dir=/папка/...) - окно показывает ее содержимое
// (папки и карты .gmf, .zip), по папкам можно переходить; выбранный файл
// скачивается в папку карт программы (Android - личное внешнее хранилище
// приложения, как у PickGmfFile; .zip - распаковка в рабочую папку с
// перезаписью, как там же - OpenForm.ResolvePickedMap), в ACallback - локальный
// путь карты. Ссылка
// другого вида - адрес самого файла, он скачивается сразу.
// Список папки - WebDAV общей ссылки (PROPFIND /public.php/webdav, логин -
// токен ссылки, пароль пустой; иначе /public.php/dav/files/<токен>).
// Ссылка на папку открытого файла хранится в Registry.ini (GlobalOpenUrl) и
// подставляется при следующем открытии; ссылка на сам файл - GlobalOpenFileUrl

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Layouts, FMX.Controls.Presentation, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  System.ImageList, FMX.ImgList, GmfPickTypes, AppForms;

type
  // элемент папки облака
  TRemoteItem = record
    Name: string;
    IsDir: Boolean;
  end;

  TGlobalOpenForm = class(TForm)
    TopLay: TLayout;
    edUrl: TEdit;
    btnGo: TButton;
    ListView1: TListView;
    lStatus: TLabel;
    Panel1: TPanel;
    btnOpen: TButton;
    btnCancel: TButton;
    ImageList1: TImageList;
    procedure btnOpenClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnGoClick(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FCallback: TPickGmfFileCallback;
    FLoading: Boolean;
   // общая папка: сервер (https://сервер), токен, текущая папка ('/', '/a/b')
    FBase, FToken, FDir: string;
    procedure SetLoading(Value: Boolean);
    procedure Navigate(const Url: string);
    procedure ListDir(const Dir: string);
    procedure ListDone(const Dir: string; const Items: TArray<TRemoteItem>; const Error: string);
    procedure Download(const FileUrl, Name: string);
    procedure DownloadDone(const LocalPath, Error: string);
    function DirUrl(const Dir: string): string;
  end;

// окно выбора: Url - ссылка (пусто - последняя из Registry.ini, а если ее нет -
// первичная ссылка на облако DefaultCloudUrl); ACallback -
// локальный путь скачанной карты ('' - отмена)
procedure OpenUrlPicker(const ACallback: TPickGmfFileCallback; const Url: string = '');

var
  GlobalOpenForm: TGlobalOpenForm;
 // ссылка на последний открытый из облака файл
  GlobalOpenFileUrl: string;

implementation

uses
  System.IOUtils, System.Threading, System.NetEncoding, System.Net.URLClient,
  System.Net.HttpClient, System.RegularExpressions, newProcs, OpenForm
{$IFDEF ANDROID}
  , Androidapi.JNIBridge, Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Java.Net
{$ENDIF};

{$R *.fmx}

const
  UrlKey = 'GlobalOpenUrl'; // ключ Registry.ini: ссылка на папку открытого файла
 // первичная ссылка на облако: адрес не передан и в Registry.ini его еще нет
  DefaultCloudUrl = 'https://cloud.mggt.ru/s/z8EgYgx2N5WcW86';
  PropfindBody = '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>';

procedure OpenUrlPicker(const ACallback: TPickGmfFileCallback; const Url: string = '');
var F: TGlobalOpenForm;
    S: string;
begin
 if not Assigned(ACallback) then exit;
 F := TGlobalOpenForm.Create(Application.MainForm);
 F.FCallback := ACallback;
 if Url <> '' then S := Url else S := string(GReadString(UrlKey, AnsiString(DefaultCloudUrl)));
 if S = '' then S := DefaultCloudUrl;
 F.edUrl.Text := S;
 F.lStatus.Text := '';
 F.btnOpen.Enabled := False;
// чтение папки - до показа: на Windows ShowDialog модальный (ответ сети
// приходит в его цикле сообщений)
 if S <> '' then F.Navigate(S);
 ShowDialog(F); // модально: Windows - окно, Android - панель поверх формы
end;

// путь в адресе: UTF-8, кроме латиницы, цифр, '-._~/' - %XX
function EncodePath(const S: string): string;
var B: TBytes;
    I: Integer;
begin
 Result := '';
 B := TEncoding.UTF8.GetBytes(S);
 for I := 0 to High(B) do
  if CharInSet(Char(B[I]), ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~', '/']) then Result := Result + Char(B[I])
  else Result := Result + '%' + IntToHex(B[I], 2);
end;

// папка: с '/' в начале, без '/' в конце (корень - '/')
function NormDir(const S: string): string;
begin
 Result := S;
 if (Result = '') or (Result[1] <> '/') then Result := '/' + Result;
 while (Length(Result) > 1) and (Result[Length(Result)] = '/') do Delete(Result, Length(Result), 1);
end;

function JoinPath(const Dir, Name: string): string;
begin
 if Dir = '/' then Result := '/' + Name else Result := Dir + '/' + Name;
end;

function ParentDir(const Dir: string): string;
var P: Integer;
begin
 P := LastDelimiter('/', Dir);
 if P <= 1 then Result := '/' else Result := Copy(Dir, 1, P - 1);
end;

// ссылка на общую папку: https://сервер/s/<токен>[?dir=/...]
function ParseShareUrl(const Url: string; out Base, Token, Dir: string): Boolean;
var U: TURI;
    P: Integer;
    Path: string;
begin
 Result := False;
 try
  U := TURI.Create(Url);
 except
  exit;
 end;
 Path := U.Path;
 P := Pos('/s/', Path);
 if P = 0 then exit;
 Token := Copy(Path, P + 3, MaxInt);
 P := Pos('/', Token);
 if P > 0 then Token := Copy(Token, 1, P - 1);
 if Token = '' then exit;
 Base := U.Scheme + '://' + U.Host;
 if (U.Port > 0) and (U.Port <> 80) and (U.Port <> 443) then Base := Base + ':' + IntToStr(U.Port);
// папка - параметр dir= (до '&'), раскодированный из %XX (UTF-8)
 Dir := '/';
 P := Pos('?', Url);
 if P > 0 then begin
  Path := '&' + Copy(Url, P + 1, MaxInt);
  P := Pos('&dir=', LowerCase(Path));
  if P > 0 then begin
   Path := Copy(Path, P + Length('&dir='), MaxInt);
   P := Pos('&', Path);
   if P > 0 then Path := Copy(Path, 1, P - 1);
   Dir := TNetEncoding.URL.Decode(Path);
  end;
 end;
 Dir := NormDir(Dir);
 Result := True;
end;

function NewClient(const Token: string): THTTPClient;
begin
 Result := THTTPClient.Create;
 Result.HandleRedirects := True;
 if Token <> '' then Result.CustomHeaders['Authorization'] := 'Basic ' + TNetEncoding.Base64String.Encode(Token + ':');
end;

{$IFDEF ANDROID}
// Android: HttpURLConnection (через него работает и THTTPClient) принимает только
// стандартные методы - PROPFIND дает java.net.ProtocolException. Имя метода
// записывается в поле HttpURLConnection.method (reflection); у HTTPS-соединения
// (обертка с полем delegate) - и во внутреннее соединение
procedure ForceRequestMethod(Conn: JObject; const Method: string);
var F: JField;
    Cls: Jlang_Class;
    D: JObject;
begin
 F := TJlang_Class.JavaClass.forName(StringToJString('java.net.HttpURLConnection')).getDeclaredField(StringToJString('method'));
 F.setAccessible(True);
 F.&set(Conn, StringToJString(Method));
 Cls := Conn.getClass;
 while Cls <> nil do begin
  D := nil;
  try
   F := Cls.getDeclaredField(StringToJString('delegate'));
   F.setAccessible(True);
   D := F.&get(Conn);
  except
   D := nil;
  end;
  if D <> nil then begin
   ForceRequestMethod(D, Method);
   exit;
  end;
  Cls := Cls.getSuperclass;
 end;
end;

function PropfindRequest(const Url, Auth: string; out Status: Integer; out StatusText, Xml: string): Boolean;
var Conn: JHttpURLConnection;
    OS: JOutputStream;
    InS: JInputStream;
    Body, Buf: TJavaArray<Byte>;
    Data: TBytes;
    Res: TBytesStream;
    N, I: Integer;
begin
 Status := 0;
 StatusText := '';
 Xml := '';
 Conn := TJHttpURLConnection.Wrap(JObjectToID(TJURL.JavaClass.init(StringToJString(Url)).openConnection));
 try
  Conn.setConnectTimeout(20000);
  Conn.setReadTimeout(30000);
  Conn.setInstanceFollowRedirects(True);
  ForceRequestMethod(Conn, 'PROPFIND');
  Conn.setRequestProperty(StringToJString('Depth'), StringToJString('1'));
  Conn.setRequestProperty(StringToJString('Content-Type'), StringToJString('application/xml; charset=utf-8'));
  if Auth <> '' then Conn.setRequestProperty(StringToJString('Authorization'), StringToJString(Auth));
  Data := TEncoding.UTF8.GetBytes(PropfindBody);
  Body := TJavaArray<Byte>.Create(Length(Data));
  try
   for I := 0 to High(Data) do Body.Items[I] := Data[I];
   Conn.setDoOutput(True);
   OS := Conn.getOutputStream;
   OS.write(Body);
   OS.close;
  finally
   Body.Free;
  end;
  Status := Conn.getResponseCode;
  if Conn.getResponseMessage <> nil then StatusText := JStringToString(Conn.getResponseMessage);
  if Status >= 400 then InS := Conn.getErrorStream else InS := Conn.getInputStream;
  if InS <> nil then begin
   Res := TBytesStream.Create;
   Buf := TJavaArray<Byte>.Create(16384);
   try
    repeat
     N := InS.read(Buf);
     if N > 0 then begin
      SetLength(Data, N);
      for I := 0 to N - 1 do Data[I] := Buf.Items[I];
      Res.WriteBuffer(Data[0], N);
     end;
    until N <= 0;
    InS.close;
    Xml := TEncoding.UTF8.GetString(Res.Bytes, 0, Res.Size);
   finally
    Buf.Free;
    Res.Free;
   end;
  end;
 finally
  Conn.disconnect;
 end;
 Result := Status = 207;
end;
{$ELSE}
function PropfindRequest(const Url, Auth: string; out Status: Integer; out StatusText, Xml: string): Boolean;
var Http: THTTPClient;
    Req: IHTTPRequest;
    Resp: IHTTPResponse;
    Body: TStringStream;
begin
 Xml := '';
 Http := THTTPClient.Create;
 Body := TStringStream.Create(PropfindBody, TEncoding.UTF8);
 try
  Http.HandleRedirects := True;
  Req := Http.GetRequest('PROPFIND', Url);
  Req.AddHeader('Depth', '1');
  Req.AddHeader('Content-Type', 'application/xml; charset=utf-8');
  if Auth <> '' then Req.AddHeader('Authorization', Auth);
  Req.SourceStream := Body;
  Resp := Http.Execute(Req);
  Status := Resp.StatusCode;
  StatusText := Resp.StatusText;
  if Status = 207 then Xml := Resp.ContentAsString(TEncoding.UTF8);
 finally
  Body.Free;
  Http.Free;
 end;
 Result := Status = 207;
end;
{$ENDIF}

// PROPFIND Depth 1: папки и файлы папки Dir (вызов в фоновом потоке)
function ListRemote(const Base, Token, Dir: string; out Items: TArray<TRemoteItem>; out Error: string): Boolean;
var Root, Auth, StatusText: string;
    Attempt, P, Status: Integer;
    Xml, Href, RelPath, Prefix: string;
    M: TMatch;
    It: TRemoteItem;
    List: TArray<TRemoteItem>;
begin
 Result := False;
 Items := nil;
 Error := '';
 for Attempt := 0 to 1 do begin
 // старый адрес WebDAV общих ссылок Nextcloud (логин - токен) и новый (без логина)
  if Attempt = 0 then begin
   Root := '/public.php/webdav';
   Auth := 'Basic ' + TNetEncoding.Base64String.Encode(Token + ':');
  end else begin
   Root := '/public.php/dav/files/' + Token;
   Auth := '';
  end;
  try
   if not PropfindRequest(Base + Root + EncodePath(Dir) + '/', Auth, Status, StatusText, Xml) then begin
    Error := Format('Папка недоступна: %d %s', [Status, StatusText]);
    continue;
   end;
  except
   on E: Exception do begin
    Error := 'Ошибка соединения: ' + E.Message;
    continue;
   end;
  end;
 // ответ: <d:response><d:href>/public.php/webdav/папка/имя[/]</d:href>...
 // <d:resourcetype><d:collection/></d:resourcetype>...</d:response>
  List := nil;
  Prefix := NormDir(Dir);
  for M in TRegEx.Matches(Xml, '<(?:\w+:)?response\b.*?</(?:\w+:)?response>', [roIgnoreCase, roSingleLine]) do begin
   Href := TRegEx.Match(M.Value, '<(?:\w+:)?href>(.*?)</(?:\w+:)?href>', [roIgnoreCase, roSingleLine]).Groups[1].Value;
   RelPath := TNetEncoding.URL.Decode(Href);
   P := Pos(Root, RelPath);
   if P > 0 then RelPath := Copy(RelPath, P + Length(Root), MaxInt);
   RelPath := NormDir(RelPath);
   if SameText(RelPath, Prefix) then continue; // сама папка
   It.IsDir := TRegEx.IsMatch(M.Value, '<(?:\w+:)?collection\s*/?>', [roIgnoreCase]);
   It.Name := Copy(RelPath, LastDelimiter('/', RelPath) + 1, MaxInt);
   if It.Name = '' then continue;
   if not It.IsDir and not (SameText(ExtractFileExt(It.Name), '.gmf') or SameText(ExtractFileExt(It.Name), '.zip')) then continue;
   List := List + [It];
  end;
  Items := List;
  Error := '';
  exit(True);
 end;
end;

// имя файла: из заголовка Content-Disposition (filename=...), иначе последняя
// часть пути адреса; без расширения - .gmf
function ResponseFileName(const Resp: IHTTPResponse; const Url: string): string;
var S: string;
    P: Integer;
    U: TURI;
begin
 Result := '';
 S := Resp.HeaderValue['Content-Disposition'];
 P := Pos('filename=', LowerCase(S));
 if P > 0 then begin
  Result := Trim(Copy(S, P + Length('filename='), MaxInt));
  P := Pos(';', Result);
  if P > 0 then Result := Copy(Result, 1, P - 1);
  Result := Result.Trim(['"', ' ']);
 end;
 if Result = '' then
  try
   U := TURI.Create(Url);
   Result := TNetEncoding.URL.Decode(U.Path);
   P := LastDelimiter('/', Result);
   if P > 0 then Result := Copy(Result, P + 1, MaxInt);
  except
   Result := '';
  end;
 if Result = '' then Result := 'download';
 Result := TPath.GetFileName(Result);
 if ExtractFileExt(Result) = '' then Result := Result + '.gmf';
end;

// скачивание (вызов в фоновом потоке): Urls - адреса по очереди (первый
// удачный); Name - имя файла ('' - из ответа). Как у PickGmfFile (OpenForm):
// карта .gmf - в GmfDir, остальные (.zip) - в OtherDir (рабочая папка), затем
// ResolvePickedMap - архив распаковывается в рабочую папку с перезаписью
// одноименных файлов, карта - первый .gmf архива
function DownloadMap(const Urls: array of string; const Token, Name, GmfDir, OtherDir: string; out LocalPath, Error: string): Boolean;
var Http: THTTPClient;
    Resp: IHTTPResponse;
    FS: TFileStream;
    Tmp, FileName, Dst: string;
    I: Integer;
begin
 Result := False;
 LocalPath := '';
 Error := '';
 Tmp := TPath.Combine(OtherDir, 'download.tmp');
 Resp := nil;
 for I := 0 to High(Urls) do begin
  if I = 0 then Http := NewClient(Token) else Http := NewClient('');
  try
   try
    FS := TFileStream.Create(Tmp, fmCreate);
    try
     Resp := Http.Get(Urls[I], FS);
    finally
     FS.Free;
    end;
    if Resp.StatusCode = 200 then break;
    Error := Format('Ошибка загрузки: %d %s', [Resp.StatusCode, Resp.StatusText]);
    Resp := nil;
   except
    on E: Exception do begin
     Error := 'Ошибка загрузки: ' + E.Message;
     Resp := nil;
    end;
   end;
  finally
   Http.Free;
  end;
 end;
 try
  if Resp = nil then exit;
  Error := '';
  if Name <> '' then FileName := Name else FileName := ResponseFileName(Resp, Urls[0]);
  if SameText(ExtractFileExt(FileName), '.gmf') then Dst := TPath.Combine(GmfDir, FileName)
  else Dst := TPath.Combine(OtherDir, FileName);
  try
   if TFile.Exists(Dst) then TFile.Delete(Dst);
   TFile.Move(Tmp, Dst);
   LocalPath := ResolvePickedMap(Dst);
   if LocalPath = '' then
    if SameText(ExtractFileExt(Dst), '.zip') then Error := 'В архиве нет карты (.gmf)'
    else Error := 'Файл не является картой (.gmf или .zip): ' + FileName;
  except
   on E: Exception do Error := 'Ошибка сохранения: ' + E.Message;
  end;
  Result := LocalPath <> '';
 finally
  if TFile.Exists(Tmp) then
   try
    TFile.Delete(Tmp);
   except
   end;
 end;
end;

{ TGlobalOpenForm }

procedure TGlobalOpenForm.SetLoading(Value: Boolean);
begin
 FLoading := Value;
 btnGo.Enabled := not Value;
 btnCancel.Enabled := not Value;
 ListView1.Enabled := not Value;
 if Value then btnOpen.Enabled := False;
end;

// ссылка на папку Dir общей папки (в таком виде хранится в Registry.ini)
function TGlobalOpenForm.DirUrl(const Dir: string): string;
begin
 Result := FBase + '/s/' + FToken;
 if Dir <> '/' then Result := Result + '?dir=' + EncodePath(Dir);
end;

// ссылка на общую папку - ее содержимое; ссылка другого вида - адрес файла,
// он скачивается сразу
procedure TGlobalOpenForm.Navigate(const Url: string);
var Base, Token, Dir: string;
begin
 if Trim(Url) = '' then exit;
 if ParseShareUrl(Trim(Url), Base, Token, Dir) then begin
  FBase := Base;
  FToken := Token;
  ListDir(Dir);
 end else begin
  FBase := '';
  FToken := '';
  ListView1.Items.Clear;
  Download(Trim(Url), '');
 end;
end;

procedure TGlobalOpenForm.ListDir(const Dir: string);
var Base, Token: string;
begin
 Base := FBase;
 Token := FToken;
 SetLoading(True);
 lStatus.Text := 'Чтение папки...';
 TTask.Run(
  procedure
  var Items: TArray<TRemoteItem>;
      Error: string;
  begin
   ListRemote(Base, Token, Dir, Items, Error);
   TThread.Queue(nil,
    procedure
    begin
     ListDone(Dir, Items, Error);
    end);
  end);
end;

// список папки: '..' (кроме корня), папки, карты
procedure TGlobalOpenForm.ListDone(const Dir: string; const Items: TArray<TRemoteItem>; const Error: string);
var It: TRemoteItem;
    Item: TListViewItem;
    Pass: Integer;
begin
 SetLoading(False);
 if Error <> '' then begin
  lStatus.Text := Error;
  exit;
 end;
 FDir := Dir;
 edUrl.Text := DirUrl(Dir);
 lStatus.Text := Dir;
 ListView1.BeginUpdate;
 try
  ListView1.Items.Clear;
  if Dir <> '/' then begin
   Item := ListView1.Items.Add;
   Item.Text := '..';
   Item.Tag := 1;
   Item.ImageIndex := -1;
  end;
  for Pass := 0 to 1 do
   for It in Items do
    if It.IsDir = (Pass = 0) then begin
     Item := ListView1.Items.Add;
     Item.Text := It.Name;
     Item.TagString := It.Name;
     if It.IsDir then begin
      Item.Tag := 2;
      Item.ImageIndex := 0; // ImageList1: папка
     end else begin
      Item.Tag := 0;
      if SameText(ExtractFileExt(It.Name), '.gmf') then Item.ImageIndex := 1 else Item.ImageIndex := -1;
     end;
    end;
 finally
  ListView1.EndUpdate;
 end;
 btnOpen.Enabled := False;
end;

// папка или '..' - переход; файл - выбор (кнопка «Открыть»)
procedure TGlobalOpenForm.ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
 if (AItem = nil) or FLoading then exit;
 case AItem.Tag of
  1: ListDir(ParentDir(FDir));
  2: ListDir(JoinPath(FDir, AItem.TagString));
 else
  btnOpen.Enabled := True;
 end;
end;

procedure TGlobalOpenForm.btnGoClick(Sender: TObject);
begin
 if not FLoading then Navigate(edUrl.Text);
end;

// выбранный файл папки: WebDAV, иначе ссылка скачивания общей папки
procedure TGlobalOpenForm.btnOpenClick(Sender: TObject);
var Item: TListViewItem;
    Path: string;
begin
 if FLoading or (FToken = '') then exit;
 Item := ListView1.Selected as TListViewItem;
 if (Item = nil) or (Item.Tag <> 0) then exit;
 Path := JoinPath(FDir, Item.TagString);
 GlobalOpenFileUrl := FBase + '/s/' + FToken + '/download?path=' + EncodePath(FDir) + '&files=' + EncodePath(Item.TagString);
 Download(FBase + '/public.php/webdav' + EncodePath(Path), Item.TagString);
end;

// скачивание в фоновом потоке, окно не закрывается до его конца
// (FormCloseQuery); папка карт - здесь, в главном потоке (JNI)
procedure TGlobalOpenForm.Download(const FileUrl, Name: string);
var GmfDir, OtherDir, Token, Fallback: string;
begin
// папки - как у PickGmfFile (OpenForm.PickedFileDir)
 GmfDir := PickedFileDir('map.gmf');
 OtherDir := PickedFileDir('map.zip');
 Token := FToken;
 Fallback := GlobalOpenFileUrl;
 if Token = '' then GlobalOpenFileUrl := FileUrl;
 SetLoading(True);
 lStatus.Text := 'Загрузка ' + Name + '...';
 TTask.Run(
  procedure
  var LocalPath, Error: string;
  begin
   if Token <> '' then DownloadMap([FileUrl, Fallback], Token, Name, GmfDir, OtherDir, LocalPath, Error)
   else DownloadMap([FileUrl], '', Name, GmfDir, OtherDir, LocalPath, Error);
   TThread.Queue(nil,
    procedure
    begin
     DownloadDone(LocalPath, Error);
    end);
  end);
end;

// загрузка закончена: ошибка - в окне; карта - ссылка на ее папку в
// Registry.ini, путь - в ACallback, окно закрывается
procedure TGlobalOpenForm.DownloadDone(const LocalPath, Error: string);
var CB: TPickGmfFileCallback;
begin
 SetLoading(False);
 if LocalPath = '' then begin
  lStatus.Text := Error;
  btnOpen.Enabled := FToken <> '';
  exit;
 end;
 if FToken <> '' then GWriteString(UrlKey, AnsiString(DirUrl(FDir)))
 else GWriteString(UrlKey, AnsiString(GlobalOpenFileUrl));
 CB := FCallback;
 FCallback := nil;
 if Assigned(CB) then CB(LocalPath);
 Close;
end;

procedure TGlobalOpenForm.btnCancelClick(Sender: TObject);
begin
 Close;
end;

procedure TGlobalOpenForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 CanClose := not FLoading;
end;

// закрытие без открытой карты - ACallback('')
procedure TGlobalOpenForm.FormClose(Sender: TObject; var Action: TCloseAction);
var CB: TPickGmfFileCallback;
begin
 CB := FCallback;
 FCallback := nil;
 if Assigned(CB) then CB('');
 Action := TCloseAction.caFree;
end;

end.
