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
// Список папки - WebDAV общей ссылки: старый /public.php/webdav (логин -
// токен ссылки) или новый /public.php/dav/files/<токен> (для защищенной ссылки
// логин anonymous); пароль общей ссылки запрашивается при 401/403.
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
    PasswordLay: TLayout;
    lPassword: TLabel;
    edPassword: TEdit;
    procedure btnOpenClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnGoClick(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FCallback: TPickGmfFileCallback;
    FLoading: Boolean;
    FCancel: TObject;
   // общая папка: сервер (https://сервер), токен, текущая папка ('/', '/a/b')
    FBase, FToken, FDir, FDavRoot, FDavUser: string;
    procedure SetLoading(Value: Boolean);
    procedure Navigate(const Url: string);
    procedure ListDir(const Dir: string);
    procedure ListDone(const Dir: string; const Items: TArray<TRemoteItem>;
     const Error: string; AuthRequired: Boolean);
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
  System.IOUtils, System.Threading, System.NetEncoding, System.Net.URLClient, System.Hash,
  System.Net.HttpClient, System.RegularExpressions, newProcs, OpenForm
{$IFDEF MSWINDOWS}
  , Winapi.Windows
{$ENDIF}
{$IFDEF ANDROID}
  , Androidapi.JNIBridge, Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Java.Net,
  Androidapi.JNI.Java.Security, Androidapi.JNI.Provider
{$ENDIF};

{$R *.fmx}

const
  UrlKey = 'GlobalOpenUrl'; // ключ Registry.ini: ссылка на папку открытого файла
  FixedUrlKey = 'GlobalOpenFixed'; // заданная для группы постоянная ссылка
  AuthUrlKey = 'GlobalOpenAuthUrl'; // ссылка, для которой сохранен пароль
  PasswordKey = 'GlobalOpenPassword';
  PasswordSizeKey = 'GlobalOpenPasswordSize';
  WindowsPasswordPrefix = 'win1:';
  AndroidPasswordPrefix = 'and1:';
  PasswordKeySalt = 'DlgGlobalOpen.Password.2026-11-13|';
 // первичная ссылка на облако: адрес не передан и в Registry.ini его еще нет
  DefaultCloudUrl = 'https://cloud.mggt.ru/s/z8EgYgx2N5WcW86';

{$IFDEF MSWINDOWS}
function CryptProtectData(DataIn: PDATA_BLOB; DataDescription: LPCWSTR;
 OptionalEntropy: PDATA_BLOB; Reserved: Pointer; PromptStruct: Pointer;
 Flags: DWORD; DataOut: PDATA_BLOB): BOOL; stdcall;
 external 'crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(DataIn: PDATA_BLOB; DataDescription: PPWideChar;
 OptionalEntropy: PDATA_BLOB; Reserved: Pointer; PromptStruct: Pointer;
 Flags: DWORD; DataOut: PDATA_BLOB): BOOL; stdcall;
 external 'crypt32.dll' name 'CryptUnprotectData';
{$ENDIF}

function BytesEqual(const Left, Right: TBytes): Boolean;
var I, Difference: Integer;
begin
 if Length(Left) <> Length(Right) then exit(False);
 Difference := 0;
 for I := 0 to High(Left) do Difference := Difference or (Left[I] xor Right[I]);
 Result := Difference = 0;
end;

function JoinBytes(const Left, Right: TBytes): TBytes;
begin
 SetLength(Result, Length(Left) + Length(Right));
 if Length(Left) > 0 then Move(Left[0], Result[0], Length(Left));
 if Length(Right) > 0 then Move(Right[0], Result[Length(Left)], Length(Right));
end;

{$IFDEF ANDROID}
function AndroidDeviceKey: TBytes;
var DeviceId: string;
begin
 DeviceId := JStringToString(TJSettings_Secure.JavaClass.getString(
  TAndroidHelper.Context.getContentResolver,
  TJSettings_Secure.JavaClass.ANDROID_ID));
 if DeviceId = '' then exit(nil);
 Result := THashSHA2.GetHashBytes(PasswordKeySalt + DeviceId);
end;

function AndroidRandomBytes(Count: Integer): TBytes;
var JavaBytes: TJavaArray<Byte>;
    I: Integer;
begin
 SetLength(Result, Count);
 JavaBytes := TJavaArray<Byte>.Create(Count);
 try
  TJSecureRandom.JavaClass.init.nextBytes(JavaBytes);
  for I := 0 to Count - 1 do Result[I] := JavaBytes[I];
 finally
  JavaBytes.Free;
 end;
end;

function AndroidCrypt(const Data, Key, Nonce: TBytes): TBytes;
var BlockInput, KeyStream: TBytes;
    Offset, Counter, I, Count: Integer;
begin
 SetLength(Result, Length(Data));
 Offset := 0;
 Counter := 0;
 while Offset < Length(Data) do begin
  SetLength(BlockInput, Length(Nonce) + 4);
  if Length(Nonce) > 0 then Move(Nonce[0], BlockInput[0], Length(Nonce));
  BlockInput[Length(Nonce)] := Byte(Counter shr 24);
  BlockInput[Length(Nonce) + 1] := Byte(Counter shr 16);
  BlockInput[Length(Nonce) + 2] := Byte(Counter shr 8);
  BlockInput[Length(Nonce) + 3] := Byte(Counter);
  KeyStream := THashSHA2.GetHMACAsBytes(BlockInput, Key);
  Count := Length(KeyStream);
  if Count > Length(Data) - Offset then Count := Length(Data) - Offset;
  for I := 0 to Count - 1 do Result[Offset + I] := Data[Offset + I] xor KeyStream[I];
  Inc(Offset, Count);
  Inc(Counter);
 end;
end;

function ProtectAndroidPassword(const Password: string): string;
var Key, Nonce, PlainText, CipherText, MacData, Tag, Stored: TBytes;
begin
 Result := '';
 Key := AndroidDeviceKey;
 if Length(Key) = 0 then exit;
 Nonce := AndroidRandomBytes(16);
 PlainText := TEncoding.UTF8.GetBytes(Password);
 CipherText := AndroidCrypt(PlainText, Key, Nonce);
 MacData := JoinBytes(Nonce, CipherText);
 Tag := THashSHA2.GetHMACAsBytes(MacData, Key);
 SetLength(Stored, Length(MacData) + 16);
 if Length(MacData) > 0 then Move(MacData[0], Stored[0], Length(MacData));
 Move(Tag[0], Stored[Length(MacData)], 16);
 Result := AndroidPasswordPrefix + TNetEncoding.Base64.EncodeBytesToString(Stored);
 if Length(PlainText) > 0 then FillChar(PlainText[0], Length(PlainText), 0);
end;

function UnprotectAndroidPassword(const StoredPassword: string): string;
var Key, Stored, Nonce, CipherText, MacData, SavedTag, Tag, PlainText: TBytes;
    CipherLength: Integer;
begin
 Result := '';
 try
  Key := AndroidDeviceKey;
  if Length(Key) = 0 then exit;
  Stored := TNetEncoding.Base64.DecodeStringToBytes(
   Copy(StoredPassword, Length(AndroidPasswordPrefix) + 1, MaxInt));
  if Length(Stored) < 32 then exit;
  CipherLength := Length(Stored) - 32;
  SetLength(Nonce, 16);
  Move(Stored[0], Nonce[0], 16);
  SetLength(CipherText, CipherLength);
  if CipherLength > 0 then Move(Stored[16], CipherText[0], CipherLength);
  MacData := JoinBytes(Nonce, CipherText);
  SetLength(SavedTag, 16);
  Move(Stored[16 + CipherLength], SavedTag[0], 16);
  Tag := THashSHA2.GetHMACAsBytes(MacData, Key);
  SetLength(Tag, 16);
  if not BytesEqual(SavedTag, Tag) then exit;
  PlainText := AndroidCrypt(CipherText, Key, Nonce);
  Result := TEncoding.UTF8.GetString(PlainText);
  if Length(PlainText) > 0 then FillChar(PlainText[0], Length(PlainText), 0);
 except
  Result := '';
 end;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function ProtectWindowsPassword(const Password: string): string;
const CryptProtectUiForbidden = $1;
var PlainText, ProtectedData: TBytes;
    DataIn, DataOut: DATA_BLOB;
begin
 Result := '';
 PlainText := TEncoding.UTF8.GetBytes(Password);
 if Length(PlainText) = 0 then exit;
 DataIn.cbData := Length(PlainText);
 DataIn.pbData := @PlainText[0];
 DataOut.cbData := 0;
 DataOut.pbData := nil;
 if CryptProtectData(@DataIn, nil, nil, nil, nil, CryptProtectUiForbidden,
  @DataOut) then
  try
   SetLength(ProtectedData, DataOut.cbData);
   if DataOut.cbData > 0 then Move(DataOut.pbData^, ProtectedData[0], DataOut.cbData);
   Result := WindowsPasswordPrefix +
    TNetEncoding.Base64.EncodeBytesToString(ProtectedData);
  finally
   LocalFree(DataOut.pbData);
  end;
 FillChar(PlainText[0], Length(PlainText), 0);
end;

function UnprotectWindowsPassword(const StoredPassword: string): string;
const CryptProtectUiForbidden = $1;
var ProtectedData, PlainText: TBytes;
    DataIn, DataOut: DATA_BLOB;
begin
 Result := '';
 try
  ProtectedData := TNetEncoding.Base64.DecodeStringToBytes(
   Copy(StoredPassword, Length(WindowsPasswordPrefix) + 1, MaxInt));
  if Length(ProtectedData) = 0 then exit;
  DataIn.cbData := Length(ProtectedData);
  DataIn.pbData := @ProtectedData[0];
  DataOut.cbData := 0;
  DataOut.pbData := nil;
  if not CryptUnprotectData(@DataIn, nil, nil, nil, nil,
   CryptProtectUiForbidden, @DataOut) then exit;
  try
   SetLength(PlainText, DataOut.cbData);
   if DataOut.cbData > 0 then Move(DataOut.pbData^, PlainText[0], DataOut.cbData);
   Result := TEncoding.UTF8.GetString(PlainText);
   if Length(PlainText) > 0 then FillChar(PlainText[0], Length(PlainText), 0);
  finally
   LocalFree(DataOut.pbData);
  end;
 except
  Result := '';
 end;
end;
{$ENDIF}

function ProtectPassword(const Password: string): string;
begin
{$IFDEF MSWINDOWS}
 Result := ProtectWindowsPassword(Password);
{$ELSEIF Defined(ANDROID)}
 Result := ProtectAndroidPassword(Password);
{$ELSE}
 Result := '';
{$ENDIF}
end;

function UnprotectPassword(const StoredPassword: string): string;
begin
 if StoredPassword.StartsWith(WindowsPasswordPrefix) then begin
{$IFDEF MSWINDOWS}
  Result := UnprotectWindowsPassword(StoredPassword);
{$ELSE}
  Result := '';
{$ENDIF}
 end else if StoredPassword.StartsWith(AndroidPasswordPrefix) then begin
{$IFDEF ANDROID}
  Result := UnprotectAndroidPassword(StoredPassword);
{$ELSE}
  Result := '';
{$ENDIF}
 end else Result := StoredPassword; // старое незашифрованное значение
end;

function ReadStoredPassword: string;
const MaxStoredPasswordSize = 8192;
var StoredBytes: TBytes;
    StoredSize: Integer;
begin
 Result := '';
 StoredSize := GReadInteger(PasswordSizeKey, 0);
 if (StoredSize > 0) and (StoredSize <= MaxStoredPasswordSize) then begin
  SetLength(StoredBytes, StoredSize);
  if GReadBinary(PasswordKey, StoredBytes[0], StoredSize) then begin
   Result := TEncoding.UTF8.GetString(StoredBytes);
   exit;
  end;
 end;
 Result := string(GReadString(PasswordKey, '')); // миграция со старого строкового формата
end;

function WriteStoredPassword(const StoredPassword: string): Boolean;
var StoredBytes: TBytes;
begin
 Result := False;
 StoredBytes := TEncoding.UTF8.GetBytes(StoredPassword);
 if Length(StoredBytes) = 0 then exit;
 if not GWriteBinary(PasswordKey, StoredBytes[0], Length(StoredBytes)) then exit;
 Result := GWriteInteger(PasswordSizeKey, Length(StoredBytes));
end;

type
  TRemoteCancel = class
  private
    FCancelled: Boolean;
    FRequest: IURLRequest;
{$IFDEF ANDROID}
    FConnection: JHttpURLConnection;
{$ENDIF}
  public
    procedure Cancel;
    procedure SetRequest(const Request: IURLRequest);
    procedure ClearRequest(const Request: IURLRequest);
{$IFDEF ANDROID}
    procedure SetConnection(const Connection: JHttpURLConnection);
    procedure ClearConnection(const Connection: JHttpURLConnection);
{$ENDIF}
    function Cancelled: Boolean;
  end;

procedure TRemoteCancel.Cancel;
var Request: IURLRequest;
{$IFDEF ANDROID}
    Connection: JHttpURLConnection;
{$ENDIF}
begin
 TMonitor.Enter(Self);
 try
  FCancelled := True;
  Request := FRequest;
{$IFDEF ANDROID}
  Connection := FConnection;
{$ENDIF}
 finally
  TMonitor.Exit(Self);
 end;
 if Request <> nil then Request.Cancel;
{$IFDEF ANDROID}
 if Connection <> nil then Connection.disconnect;
{$ENDIF}
end;

procedure TRemoteCancel.SetRequest(const Request: IURLRequest);
var IsCancelled: Boolean;
begin
 TMonitor.Enter(Self);
 try
  FRequest := Request;
  IsCancelled := FCancelled;
 finally
  TMonitor.Exit(Self);
 end;
 if IsCancelled and (Request <> nil) then Request.Cancel;
end;

procedure TRemoteCancel.ClearRequest(const Request: IURLRequest);
begin
 TMonitor.Enter(Self);
 try
  if FRequest = Request then FRequest := nil;
 finally
  TMonitor.Exit(Self);
 end;
end;

{$IFDEF ANDROID}
procedure TRemoteCancel.SetConnection(const Connection: JHttpURLConnection);
var IsCancelled: Boolean;
begin
 TMonitor.Enter(Self);
 try
  FConnection := Connection;
  IsCancelled := FCancelled;
 finally
  TMonitor.Exit(Self);
 end;
 if IsCancelled and (Connection <> nil) then Connection.disconnect;
end;

procedure TRemoteCancel.ClearConnection(const Connection: JHttpURLConnection);
begin
 TMonitor.Enter(Self);
 try
  if FConnection = Connection then FConnection := nil;
 finally
  TMonitor.Exit(Self);
 end;
end;
{$ENDIF}

function TRemoteCancel.Cancelled: Boolean;
begin
 TMonitor.Enter(Self);
 try
  Result := FCancelled;
 finally
  TMonitor.Exit(Self);
 end;
end;

procedure OpenUrlPicker(const ACallback: TPickGmfFileCallback; const Url: string = '');
var F: TGlobalOpenForm;
    S: string;
begin
 if not Assigned(ACallback) then exit;
// без владельца (освобождается сама - caFree): у одного владельца не может быть
// двух компонентов с одним именем, а окно сохранения (наследник) при загрузке
// получает сначала имя предка - GlobalOpenForm, пока окно открытия еще не
// освобождено
 F := TGlobalOpenForm.Create(nil);
 F.FCallback := ACallback;
 S := string(GReadString(FixedUrlKey, ''));
 if S = '' then begin
  if Url <> '' then S := Url
  else S := string(GReadString(UrlKey, AnsiString(DefaultCloudUrl)));
 end;
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

function NewClient(const User, Password: string): THTTPClient;
begin
 Result := THTTPClient.Create;
 Result.HandleRedirects := True;
 if User <> '' then
  Result.CustomHeaders['Authorization'] := 'Basic ' +
   TNetEncoding.Base64String.Encode(User + ':' + Password);
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

function PropfindRequest(const Url, Auth: string; Cancel: TRemoteCancel;
 out Status: Integer; out StatusText, Xml: string): Boolean;
var Conn: JHttpURLConnection;
    InS: JInputStream;
    Buf: TJavaArray<Byte>;
    Data: TBytes;
    Res: TBytesStream;
    N, I: Integer;
begin
 Status := 0;
 StatusText := '';
 Xml := '';
 Conn := TJHttpURLConnection.Wrap(JObjectToID(TJURL.JavaClass.init(StringToJString(Url)).openConnection));
 Cancel.SetConnection(Conn);
 try
  Conn.setConnectTimeout(20000);
  Conn.setReadTimeout(30000);
  Conn.setInstanceFollowRedirects(True);
  ForceRequestMethod(Conn, 'PROPFIND');
  Conn.setRequestProperty(StringToJString('Depth'), StringToJString('1'));
  Conn.setRequestProperty(StringToJString('X-Requested-With'),
   StringToJString('XMLHttpRequest'));
  if Auth <> '' then Conn.setRequestProperty(StringToJString('Authorization'), StringToJString(Auth));
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
  Cancel.ClearConnection(Conn);
  Conn.disconnect;
 end;
 Result := Status = 207;
end;
{$ELSE}
function PropfindRequest(const Url, Auth: string; Cancel: TRemoteCancel;
 out Status: Integer; out StatusText, Xml: string): Boolean;
var Http: THTTPClient;
    Req: IHTTPRequest;
    Resp: IHTTPResponse;
begin
 Xml := '';
 Http := THTTPClient.Create;
 try
  Http.HandleRedirects := True;
  Http.ConnectionTimeout := 20000;
  Http.ResponseTimeout := 30000;
  Req := Http.GetRequest('PROPFIND', Url);
  Req.AddHeader('Depth', '1');
  Req.AddHeader('X-Requested-With', 'XMLHttpRequest');
  if Auth <> '' then Req.AddHeader('Authorization', Auth);
  Cancel.SetRequest(Req);
  try
   Resp := Http.Execute(Req);
  finally
   Cancel.ClearRequest(Req);
  end;
  Status := Resp.StatusCode;
  StatusText := Resp.StatusText;
  if Status = 207 then Xml := Resp.ContentAsString(TEncoding.UTF8);
 finally
  Http.Free;
 end;
 Result := Status = 207;
end;
{$ENDIF}

// PROPFIND Depth 1: папки и файлы папки Dir (вызов в фоновом потоке)
function ListRemote(const Base, Token, Dir, Password: string;
 Cancel: TRemoteCancel;
 out Items: TArray<TRemoteItem>; out Error: string;
 out AuthRequired: Boolean; out DavRoot, DavUser: string): Boolean;
var Root, Auth, AuthUser, StatusText: string;
    Attempt, P, Status: Integer;
    Xml, Href, RelPath, Prefix: string;
    M: TMatch;
    It: TRemoteItem;
    List: TArray<TRemoteItem>;
begin
 Result := False;
 Items := nil;
 Error := '';
 AuthRequired := False;
 DavRoot := '';
 DavUser := '';
 for Attempt := 0 to 1 do begin
  if Cancel.Cancelled then begin
   Error := 'Прервано...';
   exit;
  end;
 // старый адрес WebDAV общих ссылок Nextcloud (логин - токен) и новый
 // (без пароля - без логина, с паролем - anonymous)
  if Attempt = 0 then begin
   Root := '/public.php/webdav';
   AuthUser := Token;
  end else begin
   Root := '/public.php/dav/files/' + Token;
   if Password <> '' then AuthUser := 'anonymous'
   else AuthUser := '';
  end;
  if AuthUser <> '' then
   Auth := 'Basic ' +
    TNetEncoding.Base64String.Encode(AuthUser + ':' + Password)
  else Auth := '';
  try
   if not PropfindRequest(Base + Root + EncodePath(Dir) + '/', Auth, Cancel,
    Status, StatusText, Xml) then begin
    Error := Format('Папка недоступна: %d %s', [Status, StatusText]);
    if (Status = 401) or (Status = 403) then AuthRequired := True;
    continue;
   end;
  except
   on E: Exception do begin
    if Cancel.Cancelled then begin
     Error := 'Прервано...';
     exit;
    end;
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
  AuthRequired := False;
  DavRoot := Root;
  DavUser := AuthUser;
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
function DownloadMap(const Urls: array of string;
 const User, Password, Name, GmfDir, OtherDir: string;
 Cancel: TRemoteCancel;
 out LocalPath, Error: string): Boolean;
var Http: THTTPClient;
    Req: IHTTPRequest;
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
  if Cancel.Cancelled then begin
   Error := 'Прервано...';
   break;
  end;
  if I = 0 then Http := NewClient(User, Password)
  else Http := NewClient('', '');
  try
   try
    FS := TFileStream.Create(Tmp, fmCreate);
    try
     Req := Http.GetRequest('GET', Urls[I]);
     Cancel.SetRequest(Req);
     try
      Resp := Http.Execute(Req, FS);
     finally
      Cancel.ClearRequest(Req);
     end;
    finally
     FS.Free;
    end;
    if Resp.StatusCode = 200 then break;
    Error := Format('Ошибка загрузки: %d %s', [Resp.StatusCode, Resp.StatusText]);
    Resp := nil;
   except
    on E: Exception do begin
     if Cancel.Cancelled then Error := 'Прервано...'
     else Error := 'Ошибка загрузки: ' + E.Message;
     Resp := nil;
    end;
   end;
  finally
   Http.Free;
  end;
  if Cancel.Cancelled then break;
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
 btnCancel.Enabled := True;
 ListView1.Enabled := not Value;
 edPassword.Enabled := not Value;
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
var Base, Token, Dir, AuthUrl, StoredPassword: string;
begin
 if Trim(Url) = '' then exit;
 if ParseShareUrl(Trim(Url), Base, Token, Dir) then begin
  if not SameText(FBase, Base) or (FToken <> Token) then begin
   edPassword.Text := '';
   PasswordLay.Visible := False;
   AuthUrl := string(GReadString(AuthUrlKey, ''));
   if SameText(AuthUrl, Base + '/s/' + Token) then begin
    StoredPassword := ReadStoredPassword;
    edPassword.Text := UnprotectPassword(StoredPassword);
   end;
  end;
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
var Base, Token, Password: string;
    Cancel: TRemoteCancel;
begin
 Base := FBase;
 Token := FToken;
 Password := edPassword.Text;
 Cancel := TRemoteCancel.Create;
 FCancel := Cancel;
 SetLoading(True);
 lStatus.Text := 'Чтение папки...';
 TTask.Run(
  procedure
  var Items: TArray<TRemoteItem>;
      Error, DavRoot, DavUser: string;
      AuthRequired: Boolean;
  begin
   ListRemote(Base, Token, Dir, Password, Cancel, Items, Error, AuthRequired,
    DavRoot, DavUser);
   if Cancel.Cancelled then begin
    Items := nil;
    Error := 'Прервано...';
    AuthRequired := False;
   end;
   TThread.Queue(nil,
    procedure
    begin
     if FCancel = Cancel then FCancel := nil;
     try
      if Error = '' then begin
       FDavRoot := DavRoot;
       FDavUser := DavUser;
      end;
      ListDone(Dir, Items, Error, AuthRequired);
     finally
      Cancel.Free;
     end;
    end);
  end);
end;

// список папки: '..' (кроме корня), папки, карты
procedure TGlobalOpenForm.ListDone(const Dir: string;
 const Items: TArray<TRemoteItem>; const Error: string;
 AuthRequired: Boolean);
var It: TRemoteItem;
    Item: TListViewItem;
    Pass: Integer;
    EncryptedPassword: string;
begin
 SetLoading(False);
 if Error <> '' then begin
  if AuthRequired then begin
   PasswordLay.Visible := True;
   if edPassword.Text = '' then
    lStatus.Text := 'Для доступа к папке введите пароль'
   else
    lStatus.Text := 'Неверный пароль';
   edPassword.SetFocus;
  end else
   lStatus.Text := Error;
  exit;
 end;
 FDir := Dir;
 if edPassword.Text <> '' then begin
  EncryptedPassword := ProtectPassword(edPassword.Text);
  if EncryptedPassword <> '' then begin
   if WriteStoredPassword(EncryptedPassword) then
    GWriteString(AuthUrlKey, AnsiString(FBase + '/s/' + FToken));
  end;
 end;
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
 Download(FBase + FDavRoot + EncodePath(Path), Item.TagString);
end;

// скачивание в фоновом потоке, окно не закрывается до его конца
// (FormCloseQuery); папка карт - здесь, в главном потоке (JNI)
procedure TGlobalOpenForm.Download(const FileUrl, Name: string);
var GmfDir, OtherDir, Token, User, Password, Fallback: string;
    Cancel: TRemoteCancel;
begin
// папки - как у PickGmfFile (OpenForm.PickedFileDir)
 GmfDir := PickedFileDir('map.gmf');
 OtherDir := PickedFileDir('map.zip');
 Token := FToken;
 User := FDavUser;
 Password := edPassword.Text;
 Fallback := GlobalOpenFileUrl;
 if Token = '' then GlobalOpenFileUrl := FileUrl;
 Cancel := TRemoteCancel.Create;
 FCancel := Cancel;
 SetLoading(True);
 lStatus.Text := 'Загрузка ' + Name + '...';
 TTask.Run(
  procedure
  var LocalPath, Error: string;
  begin
   if Token <> '' then
    DownloadMap([FileUrl, Fallback], User, Password, Name, GmfDir,
     OtherDir, Cancel, LocalPath, Error)
   else
    DownloadMap([FileUrl], '', '', Name, GmfDir, OtherDir,
     Cancel, LocalPath, Error);
   if Cancel.Cancelled then begin
    LocalPath := '';
    Error := 'Прервано...';
   end;
   TThread.Queue(nil,
    procedure
    begin
     if FCancel = Cancel then FCancel := nil;
     try
      DownloadDone(LocalPath, Error);
     finally
      Cancel.Free;
     end;
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
 if FLoading then begin
  if FCancel is TRemoteCancel then TRemoteCancel(FCancel).Cancel;
  btnCancel.Enabled := False;
  lStatus.Text := 'Прервано...';
  exit;
 end;
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
