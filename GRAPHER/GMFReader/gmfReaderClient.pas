unit gmfReaderClient;

interface

// Вызывающая сторона библиотеки читателя GMF (gmfreader.dll / libgmfreader.so):
// загрузка библиотеки, вызов gmfReaderOpen, вывод результата через Writer.WriteIn
// (консоль на Windows, logcat на Android, тег DELPHI).

// FileName - путь к .gmf, AppPath - каталог вызывающей программы ('' -> по умолчанию
// в библиотеке); результат - как у gmfReaderOpen, -100 - библиотека не загружена
 function gmfReaderCheck(const FileName: String; const AppPath: String = ''): Integer;

implementation uses System.SysUtils, System.IOUtils, gmfReaderAPI, Writer
                    {$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

const
  cErrNoLibrary = -100;

var
  LibHandle: HMODULE = 0;
  ReaderVersion: TgmfReaderVersionFunc = nil;
  ReaderOpen: TgmfReaderOpenFunc = nil;
  ReaderLastError: TgmfReaderLastErrorFunc = nil;

// обратный вызов библиотеки: Msg действительна только во время вызова
procedure ReaderCallback(UserData: Pointer; Info: PgmfReaderInfo; Msg: PChar); cdecl;
begin
 WriteIn(['gmfreader: callback: ', String(Msg)]);
 if (Info <> nil) and (Info.Size >= SizeOf(TgmfReaderInfo)) then
  WriteIn(['gmfreader: Lots=', Info.LotsCount, ' Twigs=', Info.TwigsCount, ' Any=', Info.AnyCount, ' Blocks=', Info.BlocksCount]);
end;

function LoadReader: Boolean;
var LibName: String;
begin
 Result := Assigned(ReaderOpen);
 if Result then exit;
{$IFDEF ANDROID}
// по имени: системный загрузчик найдет .so из APK (library\lib\arm64-v8a)
 LibName := cGMFReaderLib;
 LibHandle := LoadLibrary(PChar(LibName));
 if LibHandle = 0 then begin
  LibName := TPath.Combine(TPath.GetLibraryPath, cGMFReaderLib);
  LibHandle := LoadLibrary(PChar(LibName));
 end;
{$ELSE}
 LibName := TPath.Combine(ExtractFilePath(ParamStr(0)), cGMFReaderLib);
 LibHandle := LoadLibrary(PChar(LibName));
{$ENDIF}
 if LibHandle = 0 then begin
  WriteIn(['gmfreader: не загружена библиотека ', LibName]);
  exit;
 end;
 @ReaderVersion := GetProcAddress(LibHandle, 'gmfReaderVersion');
 @ReaderOpen := GetProcAddress(LibHandle, 'gmfReaderOpen');
 @ReaderLastError := GetProcAddress(LibHandle, 'gmfReaderLastError');
 if not Assigned(ReaderVersion) or not Assigned(ReaderOpen) or not Assigned(ReaderLastError) then begin
  WriteIn(['gmfreader: в библиотеке нет функций gmfReader* ', LibName]);
  ReaderOpen := nil;
  exit;
 end;
 WriteIn(['gmfreader: загружена ', LibName, ' версия ', ReaderVersion()]);
 Result := True;
end;

function gmfReaderCheck(const FileName: String; const AppPath: String): Integer;
var Buf: array[0..1023] of Char;
begin
 Result := cErrNoLibrary;
 if not LoadReader then exit;
 WriteIn(['gmfreader: open ', FileName]);
 Result := ReaderOpen(PChar(FileName), PChar(AppPath), ReaderCallback, nil);
 if Result < 0 then begin
  Buf[0] := #0;
  ReaderLastError(@Buf[0], Length(Buf));
  WriteIn(['gmfreader: ошибка ', Result, ': ', String(PChar(@Buf[0]))]);
 end else
  WriteIn(['gmfreader: контуров ', Result]);
end;

initialization
finalization
// на Android библиотека остается загруженной до выхода из приложения
{$IFDEF MSWINDOWS}
 if LibHandle <> 0 then FreeLibrary(LibHandle);
{$ENDIF}
end.
