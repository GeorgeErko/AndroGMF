unit AssetRefresh;

// Обновление файлов из APK (assets\internal) в рабочей папке программы на Android.
// System.StartUpCopy копирует файлы из APK только если их еще нет на устройстве,
// поэтому новая версия справочника, собранная в APK, не доходит до рабочей папки.
// RefreshAssetFiles при запуске перезаписывает файлы, содержимое которых отличается
// от APK; файлы пользователя (NoRefreshFiles) не трогаются.

interface

procedure RefreshAssetFiles;

implementation

uses
  System.SysUtils, System.IOUtils
  {$IFDEF ANDROID}, Androidapi.AssetManager, Androidapi.NativeActivity, Androidapi.IOUtils{$ENDIF};

{$IFDEF ANDROID}
const
  AssetsInternal = 'internal';
  // файлы, которые программа меняет сама (настройки) - не перезаписываются
  NoRefreshFiles: array[0..0] of String = ('registry.ini');

// содержимое файла из APK; False - файла нет
function ReadAsset(AM: PAAssetManager; const AssetName: String; out Data: TBytes): Boolean;
var A: PAAsset;
    L, N, R: Integer;
    M: TMarshaller;
begin
 A := AAssetManager_open(AM, M.AsUtf8(AssetName).ToPointer, AASSET_MODE_BUFFER);
 Result := A <> nil;
 if not Result then exit;
 try
  L := AAsset_getLength(A);
  SetLength(Data, L);
  N := 0;
  while N < L do begin
   R := AAsset_read(A, @Data[N], L - N);
   if R <= 0 then break;
   Inc(N, R);
  end;
  SetLength(Data, N);
 finally
  AAsset_close(A);
 end;
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
 Result := (Length(A) = Length(B)) and ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function NoRefresh(const FileName: String): Boolean;
var S: String;
begin
 Result := True;
 for S in NoRefreshFiles do
  if SameText(S, FileName) then exit;
 Result := False;
end;

procedure RefreshAssetFiles;
var AM: PAAssetManager;
    Dir: PAAssetDir;
    P: MarshaledAString;
    FileName, Dest: String;
    Data: TBytes;
    M: TMarshaller;
begin
 if System.DelphiActivity = nil then exit;
 AM := ANativeActivity(System.DelphiActivity^).assetManager;
 if AM = nil then exit;
 Dir := AAssetManager_openDir(AM, M.AsUtf8(AssetsInternal).ToPointer);
 if Dir = nil then exit;
 try
  P := AAssetDir_getNextFileName(Dir);
  while P <> nil do begin
   FileName := Trim(UTF8ToString(P));
   if (FileName <> '') and not NoRefresh(FileName) then
    try
     Dest := TPath.Combine(GetFilesDir, FileName);
     if ReadAsset(AM, AssetsInternal + '/' + FileName, Data) then
      if not TFile.Exists(Dest) or not SameBytes(Data, TFile.ReadAllBytes(Dest)) then
       TFile.WriteAllBytes(Dest, Data);
    except
    end;
   P := AAssetDir_getNextFileName(Dir);
  end;
 finally
  AAssetDir_close(Dir);
 end;
end;
{$ELSE}
procedure RefreshAssetFiles;
begin
end;
{$ENDIF}

end.
