unit OpenForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  FMX.Forms, FMX.Dialogs,
  GmfPickTypes,
  DlgLocalOpen;

procedure PickGmfFile(const ACallback: TPickGmfFileCallback);
procedure PickGpkgFile(const ACallback: TPickGmfFileCallback);

implementation

uses
  System.Zip
{$IFDEF ANDROID}
  ,System.Messaging,
  Androidapi.Helpers,
  Androidapi.IOUtils,
  Androidapi.JNIBridge,
  Androidapi.JNI.App,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Net,
  Androidapi.JNI.Provider,
  FMX.Helpers.Android,
  FMX.Platform,
  Androidapi.JNI.GraphicsContentViewText
{$ENDIF};

{$IFDEF ANDROID}
type
  TAndroidGmfPicker = class
  private
    const REQUEST_CODE_PICK_GMF = 7017;
  private
    FSubId: Integer;
    FDone: Boolean;
    FCallback: TPickGmfFileCallback;
    function GetDisplayNameFromUri(const Uri: Jnet_Uri): string;
    procedure CopyUriToFile(const Uri: Jnet_Uri; const LocalPath: string);
    function ResolvePickedLocalPath(const PickedLocalPath: string): string;
    procedure Finish(const LocalPath: string);
    procedure OnMessage(const Sender: TObject; const M: TMessage);
  public
    class function Instance: TAndroidGmfPicker;
    procedure StartPick(const ACallback: TPickGmfFileCallback);
  end;

var
  _AndroidGmfPicker: TAndroidGmfPicker;

type
  TAndroidGpkgPicker = class
  private
    const REQUEST_CODE_PICK_GPKG = 7031;
  private
    FSubId: Integer;
    FDone: Boolean;
    FCallback: TPickGmfFileCallback;
    function GetDisplayNameFromUri(const Uri: Jnet_Uri): string;
    procedure CopyUriToFile(const Uri: Jnet_Uri; const LocalPath: string);
    procedure Finish(const LocalPath: string);
    procedure OnMessage(const Sender: TObject; const M: TMessage);
  public
    class function Instance: TAndroidGpkgPicker;
    procedure StartPick(const ACallback: TPickGmfFileCallback);
  end;

var
  _AndroidGpkgPicker: TAndroidGpkgPicker;

class function TAndroidGmfPicker.Instance: TAndroidGmfPicker;
begin
  if _AndroidGmfPicker = nil then _AndroidGmfPicker := TAndroidGmfPicker.Create;
  Result := _AndroidGmfPicker;
end;

procedure TAndroidGmfPicker.StartPick(const ACallback: TPickGmfFileCallback);
var
  Intent: JIntent;
begin
  FCallback := ACallback;
  if not Assigned(FCallback) then Exit;
  FDone := False;
  if FSubId <> 0 then TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FSubId);
  FSubId := TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification, OnMessage);
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('*/*'));
  Intent.putExtra(TJIntent.JavaClass.EXTRA_ALLOW_MULTIPLE, True);
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
  TAndroidHelper.Activity.startActivityForResult(Intent, REQUEST_CODE_PICK_GMF);
end;

class function TAndroidGpkgPicker.Instance: TAndroidGpkgPicker;
begin
  if _AndroidGpkgPicker = nil then _AndroidGpkgPicker := TAndroidGpkgPicker.Create;
  Result := _AndroidGpkgPicker;
end;

procedure TAndroidGpkgPicker.StartPick(const ACallback: TPickGmfFileCallback);
var
  Intent: JIntent;
begin
  FCallback := ACallback;
  if not Assigned(FCallback) then exit;
  FDone := False;
  if FSubId <> 0 then TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FSubId);
  FSubId := TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification, OnMessage);
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('*/*'));
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
  TAndroidHelper.Activity.startActivityForResult(Intent, REQUEST_CODE_PICK_GPKG);
end;

procedure TAndroidGpkgPicker.Finish(const LocalPath: string);
var
  CB: TPickGmfFileCallback;
begin
  if FDone then exit;
  FDone := True;
  if FSubId <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FSubId);
    FSubId := 0;
  end;
  CB := FCallback;
  FCallback := nil;
  if Assigned(CB) then CB(LocalPath);
end;

function TAndroidGpkgPicker.GetDisplayNameFromUri(const Uri: Jnet_Uri): string;
var
  Cursor: JCursor;
  NameIndex: Integer;
begin
  Result := '';
  Cursor := nil;
  try
    Cursor := TAndroidHelper.ContentResolver.query(Uri, nil, nil, nil, nil);
    if (Cursor <> nil) and Cursor.moveToFirst then
    begin
      NameIndex := Cursor.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME);
      if NameIndex >= 0 then Result := JStringToString(Cursor.getString(NameIndex));
    end;
  finally
    if Cursor <> nil then Cursor.close;
  end;
end;

procedure TAndroidGpkgPicker.CopyUriToFile(const Uri: Jnet_Uri; const LocalPath: string);
var
  InStream: JInputStream;
  OutStream: TFileStream;
  Bytes: TJavaArray<System.Byte>;
  Buffer: TBytes;
  ReadCount: Integer;
begin
  InStream := TAndroidHelper.ContentResolver.openInputStream(Uri);
  if InStream = nil then raise Exception.Create('openInputStream=nil');
  try
    OutStream := TFileStream.Create(LocalPath, fmCreate);
    try
      SetLength(Buffer, 64*1024);
      Bytes := TJavaArray<System.Byte>.Create(Length(Buffer));
      try
        while True do
        begin
          ReadCount := InStream.read(Bytes, 0, Bytes.Length);
          if ReadCount <= 0 then Break;
          if ReadCount > Length(Buffer) then ReadCount := Length(Buffer);
          Move(Bytes.Data^, Buffer[0], ReadCount);
          OutStream.WriteBuffer(Buffer[0], ReadCount);
        end;
      finally
        Bytes.Free;
      end;
    finally
      OutStream.Free;
    end;
  finally
    InStream.close;
  end;
end;

procedure TAndroidGpkgPicker.OnMessage(const Sender: TObject; const M: TMessage);
var
  Msg: TMessageResultNotification;
  DataIntent: JIntent;
  Uri: Jnet_Uri;
  DisplayName: string;
  LocalPath: string;
  PersistFlags: Integer;
begin
  if FDone then exit;
  if not (M is TMessageResultNotification) then exit;
  Msg := TMessageResultNotification(M);
  if Msg.RequestCode <> REQUEST_CODE_PICK_GPKG then exit;
  DataIntent := Msg.Value;
  if (Msg.ResultCode <> TJActivity.JavaClass.RESULT_OK) or (DataIntent = nil) then begin Finish(''); exit; end;
  Uri := DataIntent.getData;
  if Uri = nil then begin Finish(''); exit; end;
  PersistFlags := DataIntent.getFlags and (TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION or TJIntent.JavaClass.FLAG_GRANT_WRITE_URI_PERMISSION);
  if PersistFlags <> 0 then
  begin
    try
      TAndroidHelper.ContentResolver.takePersistableUriPermission(Uri, PersistFlags);
    except
    end;
  end;
  DisplayName := GetDisplayNameFromUri(Uri);
  if DisplayName = '' then DisplayName := 'import.gpkg';
  LocalPath := TPath.Combine(TPath.GetDocumentsPath, DisplayName);
  try
    CopyUriToFile(Uri, LocalPath);
    Finish(LocalPath);
  except
    Finish('');
  end;
end;

procedure TAndroidGmfPicker.Finish(const LocalPath: string);
var
  CB: TPickGmfFileCallback;
begin
  if FDone then Exit;
  FDone := True;
  if FSubId <> 0 then
  begin
    TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, FSubId);
    FSubId := 0;
  end;
  CB := FCallback;
  FCallback := nil;
  if Assigned(CB) then CB(LocalPath);
end;

function TAndroidGmfPicker.GetDisplayNameFromUri(const Uri: Jnet_Uri): string;
var
  Cursor: JCursor;
  NameIndex: Integer;
begin
  Result := '';
  Cursor := nil;
  try
    Cursor := TAndroidHelper.ContentResolver.query(Uri, nil, nil, nil, nil);
    if (Cursor <> nil) and Cursor.moveToFirst then
    begin
      NameIndex := Cursor.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME);
      if NameIndex >= 0 then Result := JStringToString(Cursor.getString(NameIndex));
    end;
  finally
    if Cursor <> nil then Cursor.close;
  end;
end;

function TAndroidGmfPicker.ResolvePickedLocalPath(const PickedLocalPath: string): string;
var
  Ext: string;
  ZipBaseName: string;
  ExtractDir: string;
  Gmfs: TStringDynArray;
  S: TFileStream;
  Sig: array[0..3] of Byte;
  IsZip: Boolean;
begin
  Result := '';
  if PickedLocalPath = '' then
    Exit;
  Ext := LowerCase(ExtractFileExt(PickedLocalPath));
  if Ext = '.gmf' then
  begin
    Result := PickedLocalPath;
    Exit;
  end;
  IsZip := (Ext = '.zip');
  if not IsZip then
  begin
    try
      S := TFileStream.Create(PickedLocalPath, fmOpenRead or fmShareDenyNone);
      try
        if S.Read(Sig, SizeOf(Sig)) = SizeOf(Sig) then
          IsZip := (Sig[0] = $50) and (Sig[1] = $4B);
      finally
        S.Free;
      end;
    except
      IsZip := False;
    end;
  end;
  if not IsZip then Exit;

  ZipBaseName := ChangeFileExt(ExtractFileName(PickedLocalPath), '');
  if ZipBaseName = '' then
    ZipBaseName := 'import_zip';
 // ExtractDir := TPath.Combine(TPath.GetDocumentsPath, ZipBaseName);
   ExtractDir := TPath.GetDocumentsPath;
  try
    ForceDirectories(ExtractDir);
    TZipFile.ExtractZipFile(PickedLocalPath, ExtractDir);
    Gmfs := TDirectory.GetFiles(ExtractDir, '*.gmf', TSearchOption.soAllDirectories);
    if Length(Gmfs) > 0 then
      Result := Gmfs[0];
  except
    Result := '';
  end;
end;

procedure TAndroidGmfPicker.CopyUriToFile(const Uri: Jnet_Uri; const LocalPath: string);
var
  InStream: JInputStream;
  OutStream: TFileStream;
  Bytes: TJavaArray<System.Byte>;
  Buffer: TBytes;
  ReadCount: Integer;
begin
  InStream := TAndroidHelper.ContentResolver.openInputStream(Uri);
  if InStream = nil then raise Exception.Create('openInputStream=nil');
  try
    OutStream := TFileStream.Create(LocalPath, fmCreate);
    try
      SetLength(Buffer, 64*1024);
      Bytes := TJavaArray<System.Byte>.Create(Length(Buffer));
      try
        while True do
        begin
          ReadCount := InStream.read(Bytes, 0, Bytes.Length);
          if ReadCount <= 0 then Break;
          if ReadCount > Length(Buffer) then ReadCount := Length(Buffer);
          Move(Bytes.Data^, Buffer[0], ReadCount);
          OutStream.WriteBuffer(Buffer[0], ReadCount);
        end;
      finally
        Bytes.Free;
      end;
    finally
      OutStream.Free;
    end;
  finally
    InStream.close;
  end;
end;

procedure TAndroidGmfPicker.OnMessage(const Sender: TObject; const M: TMessage);
var
  Msg: TMessageResultNotification;
  DataIntent: JIntent;
  Uri: Jnet_Uri;
  Clip: JClipData;
  Item: JClipData_Item;
  I: Integer;
  TargetUri: Jnet_Uri;
  DisplayName: string;
  LocalPath: string;
  FirstGmfLocalPath: string;
  ResolvedPath: string;
  PersistFlags: Integer;
begin
  if FDone then Exit;
  if not (M is TMessageResultNotification) then Exit;
  Msg := TMessageResultNotification(M);
  if Msg.RequestCode <> REQUEST_CODE_PICK_GMF then Exit;
  DataIntent := Msg.Value;
  if (Msg.ResultCode <> TJActivity.JavaClass.RESULT_OK) or (DataIntent = nil) then begin Finish(''); Exit; end;
  PersistFlags := DataIntent.getFlags and (TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION or TJIntent.JavaClass.FLAG_GRANT_WRITE_URI_PERMISSION);
  FirstGmfLocalPath := '';
  Clip := DataIntent.getClipData;
  if Clip <> nil then
  begin
    for I := 0 to Clip.getItemCount - 1 do
    begin
      Item := Clip.getItemAt(I);
      if Item = nil then Continue;
      TargetUri := Item.getUri;
      if TargetUri = nil then Continue;
      if PersistFlags <> 0 then
      begin
        try
          TAndroidHelper.ContentResolver.takePersistableUriPermission(TargetUri, PersistFlags);
        except
        end;
      end;
      DisplayName := GetDisplayNameFromUri(TargetUri);
      if DisplayName = '' then DisplayName := 'import_' + I.ToString;
      LocalPath := TPath.Combine(TPath.GetDocumentsPath, DisplayName);
      try
        CopyUriToFile(TargetUri, LocalPath);
        if FirstGmfLocalPath = '' then
        begin
          ResolvedPath := ResolvePickedLocalPath(LocalPath);
          if ResolvedPath <> '' then
            FirstGmfLocalPath := ResolvedPath;
        end;
      except
      end;
    end;
    Finish(FirstGmfLocalPath);
    Exit;
  end;
  Uri := DataIntent.getData;
  if Uri = nil then begin Finish(''); Exit; end;
  if PersistFlags <> 0 then
  begin
    try
      TAndroidHelper.ContentResolver.takePersistableUriPermission(Uri, PersistFlags);
    except
    end;
  end;
  DisplayName := GetDisplayNameFromUri(Uri);
  if DisplayName = '' then DisplayName := 'import';
  LocalPath := TPath.Combine(TPath.GetDocumentsPath, DisplayName);
  try
    CopyUriToFile(Uri, LocalPath);
    ResolvedPath := ResolvePickedLocalPath(LocalPath);
    Finish(ResolvedPath);
  except
    Finish('');
  end;
end;

{$ENDIF}

procedure PickGmfFile(const ACallback: TPickGmfFileCallback);
var
  Dlg: TOpenDialog;
  SrcPath: string;
  Ext: string;
  DstZipPath: string;
  ZipBaseName: string;
  ExtractDir: string;
  Gmfs: TStringDynArray;
  ResolvedPath: string;
begin
  if not Assigned(ACallback) then Exit;

{$IFDEF ANDROID}
  TAndroidGmfPicker.Instance.StartPick(ACallback);
{$ELSE}
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'GMF (*.gmf)|*.gmf|ZIP (*.zip)|*.zip|All files (*.*)|*.*';
    Dlg.Options := Dlg.Options + [TOpenOption.ofFileMustExist];
    if not Dlg.Execute then
    begin
      ACallback('');
      Exit;
    end;

    SrcPath := Dlg.FileName;
    if SrcPath = '' then
    begin
      ACallback('');
      Exit;
    end;

    Ext := LowerCase(ExtractFileExt(SrcPath));
    if Ext = '.gmf' then
    begin
      ACallback(SrcPath);
      Exit;
    end;

    if Ext = '.zip' then
    begin
      ZipBaseName := ChangeFileExt(ExtractFileName(SrcPath), '');
      if ZipBaseName = '' then
        ZipBaseName := 'import_zip';

      DstZipPath := TPath.Combine(TPath.GetDocumentsPath, ExtractFileName(SrcPath));
      ExtractDir := TPath.Combine(TPath.GetDocumentsPath, ZipBaseName);

      try
        ForceDirectories(ExtractDir);
        if not SameText(SrcPath, DstZipPath) then
          TFile.Copy(SrcPath, DstZipPath, True);
        TZipFile.ExtractZipFile(DstZipPath, ExtractDir);
        Gmfs := TDirectory.GetFiles(ExtractDir, '*.gmf', TSearchOption.soAllDirectories);
        if Length(Gmfs) > 0 then
          ResolvedPath := Gmfs[0]
        else
          ResolvedPath := '';
      except
        ResolvedPath := '';
      end;

      ACallback(ResolvedPath);
      Exit;
    end;

    ACallback('');
  finally
    Dlg.Free;
  end;
{$ENDIF}
end;

procedure PickGpkgFile(const ACallback: TPickGmfFileCallback);
var
  Dlg: TOpenDialog;
  SrcPath: string;
begin
  if not Assigned(ACallback) then exit;

{$IFDEF ANDROID}
  TAndroidGpkgPicker.Instance.StartPick(ACallback);
{$ELSE}
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'GeoPackage (*.gpkg)|*.gpkg|All files (*.*)|*.*';
    Dlg.Options := Dlg.Options + [TOpenOption.ofFileMustExist];
    if not Dlg.Execute then
    begin
      ACallback('');
      exit;
    end;
    SrcPath := Dlg.FileName;
    if SrcPath = '' then
    begin
      ACallback('');
      exit;
    end;
    ACallback(SrcPath);
  finally
    Dlg.Free;
  end;
{$ENDIF}
end;

end.
