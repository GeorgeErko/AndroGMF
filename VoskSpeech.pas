unit VoskSpeech;

// Голосовой ввод: распознавание речи Vosk (офлайн, Kaldi) с поздним
// связыванием. Библиотека (libvosk.dll - Win64, libvosk.so - Android
// arm64-v8a) и модель (каталог vosk-model-small-ru, ~45 МБ) в программу не
// входят: загружаются при первом Start, если есть на устройстве; иначе
// Available = False, LastError - причина, программа работает без голосового
// ввода. Звук с микрофона: Windows - waveIn (WinAPI), Android - AudioRecord
// (JNI, разрешение RECORD_AUDIO запрашивается при Start; в Project Options -
// Uses Permissions - Record audio). PCM 16 кГц, 16 бит, моно.
// Грамматика (SetGrammar) ограничивает словарь - для чисел и команд точность
// выше даже на маленькой модели. Модель (секунды) и распознаватель создаются
// в потоке захвата - Start не задерживает интерфейс; модель загружается один
// раз и остается в памяти. Время шагов - в консоль (WriteIn).
// Результаты - в главном потоке: OnPartial
// (промежуточный текст), OnResult (законченная фраза).
// SpokenToNumber - число из слов («двенадцать точка пять» - '12.5').

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

type
  TVoskTextEvent = procedure(const Text: String) of object;

  TVoskRecognizer = class
  private
    FModelPath: String;
    FLibraryPath: String;
    FGrammar: String; // JSON-массив слов; '' - без грамматики
    FModel: Pointer;
    FThread: TThread;
    FLastError: String;
    FOnResult: TVoskTextEvent;
    FOnPartial: TVoskTextEvent;
    FOnError: TVoskTextEvent;
    procedure StartCapture;
    function GetActive: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
   // библиотека загружается (один раз) и есть каталог модели
    function Available: Boolean;
   // библиотека загружается (модели может не быть - VoskModelExists)
    function LibraryAvailable: Boolean;
   // слова грамматики (без нее - весь словарь модели); [unk] добавляется
    procedure SetGrammar(const Words: array of String);
   // запуск/остановка распознавания; False - недоступно (LastError)
    function Start: Boolean;
    procedure Stop(Discard: Boolean = False);
    property Active: Boolean read GetActive;
   // каталог модели (по умолчанию VoskDefaultModelPath), путь к библиотеке
   // (по умолчанию - имя библиотеки, поиск системой / рядом с программой)
    property ModelPath: String read FModelPath write FModelPath;
    property LibraryPath: String read FLibraryPath write FLibraryPath;
    property LastError: String read FLastError;
    property OnResult: TVoskTextEvent read FOnResult write FOnResult;
    property OnPartial: TVoskTextEvent read FOnPartial write FOnPartial;
   // ошибка в потоке распознавания (модель, распознаватель, микрофон) - в
   // главном потоке; распознавание после нее не идет (Stop)
    property OnError: TVoskTextEvent read FOnError write FOnError;
  end;

const
  VoskSampleRate = 16000;
// слова чисел и разделителей - грамматика для ввода длины, радиуса и т.п.
  VoskNumberWords: array[0..41] of String = (
   'ноль', 'один', 'одна', 'два', 'две', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять',
   'десять', 'одиннадцать', 'двенадцать', 'тринадцать', 'четырнадцать', 'пятнадцать', 'шестнадцать',
   'семнадцать', 'восемнадцать', 'девятнадцать', 'двадцать', 'тридцать', 'сорок', 'пятьдесят',
   'шестьдесят', 'семьдесят', 'восемьдесят', 'девяносто', 'сто', 'двести', 'триста', 'четыреста',
   'пятьсот', 'шестьсот', 'семьсот', 'восемьсот', 'девятьсот', 'точка', 'запятая', 'минус');

function VoskLibraryName: String;
// каталог модели по умолчанию: Windows - vosk-model-small-ru рядом с
// программой, Android - в каталоге документов приложения или во внешнем
// каталоге Android/data/<пакет>/files (копирование по USB)
function VoskDefaultModelPath: String;
// библиотека Vosk загружена (позднее связывание; повторная попытка - нет)
function VoskLoaded: Boolean;
// модель на месте (каталог с подкаталогом am)
function VoskModelExists(const Path: String): Boolean;
// каталог, куда загружается модель: Android - документы приложения, Windows -
// каталог программы
function VoskModelBaseDir: String;

const
// модель для загрузки по требованию (zip с каталогом vosk-model-small-ru-0.22):
// источники по порядку - копия в релизе GitHub (alphacephei.com с части
// устройств недоступен), затем сайт Vosk. Архивы одинаковые - докачка
// продолжается с любого источника
  VoskModelUrls: array[0..1] of String = (
   'https://github.com/GeorgeErko/AndroGMF/releases/download/Vosk/vosk-model-small-ru-0.22.zip',
   'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip');
  VoskModelSizeMB = 45;

type
  TVoskDownloadProgress = reference to procedure(Received, Total: Int64);
  TVoskDownloadDone = reference to procedure(Ok: Boolean; const Error: String);

// загрузка модели в фоне: zip во временный файл, распаковка в VoskModelBaseDir;
// события - в главном потоке (OnProgress - при смене процента). Cancel -
// прервать: после него события не вызываются. Интерфейс со счетчиком ссылок -
// поток, отложенные события и владелец держат свои ссылки
  IVoskModelDownload = interface
  ['{6B0E2F55-2C5D-4E8B-9C4A-31D7A8E5F102}']
    procedure Cancel;
    function Canceled: Boolean;
  end;

  TVoskModelDownload = class(TInterfacedObject, IVoskModelDownload)
  private
    FCancel: Boolean;
    FOnProgress: TVoskDownloadProgress;
    FOnDone: TVoskDownloadDone;
    FLastPercent: Integer;
    FBase: Int64; // уже загружено до текущего запроса (докачка)
    FTotal: Int64; // полный размер архива; 0 - неизвестен
    procedure ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
    procedure Run;
  public
    procedure Cancel;
    function Canceled: Boolean;
    class function Start(OnProgress: TVoskDownloadProgress; OnDone: TVoskDownloadDone): IVoskModelDownload;
  end;
// число из слов: целая и дробная части (через «точка»/«запятая»), «минус»;
// часть из одних цифр («один два») - цифры подряд, иначе - сумма («сто
// двадцать пять»); не число - ''
function SpokenToNumber(const Text: String): String;

implementation

uses
  System.IOUtils, System.JSON, System.Diagnostics, System.Zip, System.Net.HttpClient,
  System.Net.URLClient, Writer
{$IFDEF MSWINDOWS}
  , Winapi.Windows, Winapi.MMSystem
{$ENDIF}
{$IFDEF ANDROID}
  , System.Types, System.Permissions, Androidapi.JNIBridge, Androidapi.JNI.Media, Posix.Stdlib
{$ENDIF}
  ;

{ функции libvosk (C API, cdecl) - адреса по GetProcAddress }

type
  Tvosk_set_log_level = procedure(level: Integer); cdecl;
  Tvosk_model_new = function(model_path: PAnsiChar): Pointer; cdecl;
  Tvosk_model_free = procedure(model: Pointer); cdecl;
  Tvosk_recognizer_new = function(model: Pointer; sample_rate: Single): Pointer; cdecl;
  Tvosk_recognizer_new_grm = function(model: Pointer; sample_rate: Single; grammar: PAnsiChar): Pointer; cdecl;
  Tvosk_recognizer_free = procedure(recognizer: Pointer); cdecl;
  Tvosk_recognizer_accept_waveform = function(recognizer: Pointer; data: PAnsiChar; length: Integer): Integer; cdecl;
  Tvosk_recognizer_result = function(recognizer: Pointer): PAnsiChar; cdecl;

var
  VoskLib: HMODULE = 0;
  VoskTried: Boolean = False;
  VoskLoadError: String = '';
  vosk_set_log_level: Tvosk_set_log_level;
  vosk_model_new: Tvosk_model_new;
  vosk_model_free: Tvosk_model_free;
  vosk_recognizer_new: Tvosk_recognizer_new;
  vosk_recognizer_new_grm: Tvosk_recognizer_new_grm;
  vosk_recognizer_free: Tvosk_recognizer_free;
  vosk_recognizer_accept_waveform: Tvosk_recognizer_accept_waveform;
  vosk_recognizer_result: Tvosk_recognizer_result;
  vosk_recognizer_partial_result: Tvosk_recognizer_result;
  vosk_recognizer_final_result: Tvosk_recognizer_result;

function VoskLibraryName: String;
begin
{$IFDEF MSWINDOWS}
 Result := 'libvosk.dll';
{$ELSE}
 Result := 'libvosk.so';
{$ENDIF}
end;

// каталог модели: первый vosk-model*ru* (имя из архива, например
// vosk-model-small-ru-0.22, переименовывать не нужно); нет - vosk-model-small-ru
function VoskModelBaseDir: String;
begin
{$IFDEF ANDROID}
 Result := TPath.GetDocumentsPath;
{$ELSE}
 Result := ExtractFilePath(ParamStr(0));
{$ENDIF}
end;

function VoskModelExists(const Path: String): Boolean;
begin
 Result := TDirectory.Exists(TPath.Combine(Path, 'am'));
end;

// первый vosk-model*ru* в Base с моделью внутри; распакованный архив бывает
// вложен в одноименную папку - смотрим и на уровень глубже
function FindModelIn(const Base: String; var Path: String): Boolean;
var D, S: String;
begin
 Result := False;
 if (Base = '') or not TDirectory.Exists(Base) then exit;
 for D in TDirectory.GetDirectories(Base, 'vosk-model*ru*') do begin
  if VoskModelExists(D) then begin
   Path := D;
   exit(True);
  end;
  for S in TDirectory.GetDirectories(D, 'vosk-model*ru*') do
   if VoskModelExists(S) then begin
    Path := S;
    exit(True);
   end;
 end;
end;

// Android: сначала каталог загрузки (внутренний), затем внешний каталог
// приложения Android/data/<пакет>/files - туда модель можно скопировать по USB
function VoskDefaultModelPath: String;
begin
 Result := TPath.Combine(VoskModelBaseDir, 'vosk-model-small-ru');
 if FindModelIn(VoskModelBaseDir, Result) then exit;
{$IFDEF ANDROID}
 FindModelIn(TPath.GetPublicPath, Result);
{$ENDIF}
end;

// вычисления Kaldi (OpenBLAS/OpenMP) - в одном потоке: иначе библиотека
// постоянно создает рабочие потоки (под отладчиком каждый старт потока -
// событие, загрузка модели растягивается на минуты); маленькой модели одного
// потока хватает. Переменные читаются при загрузке библиотеки - задаются до нее
procedure SetSingleThreadEnv;
const Names: array[0..3] of String = ('OPENBLAS_NUM_THREADS', 'OMP_NUM_THREADS', 'GOTO_NUM_THREADS', 'MKL_NUM_THREADS');
var N: String;
begin
 for N in Names do
{$IFDEF MSWINDOWS}
  SetEnvironmentVariable(PChar(N), '1');
{$ELSE}
  setenv(PAnsiChar(AnsiString(N)), '1', 1);
{$ENDIF}
end;

function LoadVosk(const LibPath: String): Boolean;
function Bind(const Name: String): Pointer;
begin
 Result := GetProcAddress(VoskLib, PChar(Name));
 if Result = nil then raise Exception.Create('в библиотеке нет функции ' + Name);
end;
begin
 if VoskTried then exit(VoskLib <> 0);
 VoskTried := True;
 SetSingleThreadEnv;
 VoskLib := SafeLoadLibrary(LibPath);
 if VoskLib = 0 then begin
  VoskLoadError := 'Не найдена библиотека ' + LibPath;
  exit(False);
 end;
 try
  @vosk_set_log_level := Bind('vosk_set_log_level');
  @vosk_model_new := Bind('vosk_model_new');
  @vosk_model_free := Bind('vosk_model_free');
  @vosk_recognizer_new := Bind('vosk_recognizer_new');
  @vosk_recognizer_new_grm := Bind('vosk_recognizer_new_grm');
  @vosk_recognizer_free := Bind('vosk_recognizer_free');
  @vosk_recognizer_accept_waveform := Bind('vosk_recognizer_accept_waveform');
  @vosk_recognizer_result := Bind('vosk_recognizer_result');
  @vosk_recognizer_partial_result := Bind('vosk_recognizer_partial_result');
  @vosk_recognizer_final_result := Bind('vosk_recognizer_final_result');
  vosk_set_log_level(-1);
  Result := True;
 except
  on E: Exception do begin
   VoskLoadError := 'Библиотека ' + LibPath + ': ' + E.Message;
   FreeLibrary(VoskLib);
   VoskLib := 0;
   Result := False;
  end;
 end;
end;

function VoskLoaded: Boolean;
begin
 Result := VoskLib <> 0;
end;

// поле text/partial из ответа Vosk (JSON в UTF-8)
function JsonField(P: PAnsiChar; const Name: String): String;
var V: TJSONValue;
begin
 Result := '';
 if P = nil then exit;
 V := TJSONObject.ParseJSONValue(UTF8ToString(P));
 try
  if V is TJSONObject then Result := Trim(TJSONObject(V).GetValue<String>(Name, ''));
 finally
  V.Free;
 end;
end;

{ поток захвата: микрофон - распознаватель - события в главном потоке }

type
  TVoskThread = class(TThread)
  private
    FOwner: TVoskRecognizer;
    FRec: Pointer;
    FGrammar: String;
    FLastPartial: String;
    procedure Feed(Data: Pointer; Bytes: Integer);
    procedure PostText(const Text: String; Final: Boolean);
    procedure PostError(const Text: String);
    function Prepare: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TVoskRecognizer);
  end;

constructor TVoskThread.Create(AOwner: TVoskRecognizer);
begin
 FOwner := AOwner;
 FGrammar := AOwner.FGrammar;
 inherited Create(False);
end;

procedure TVoskThread.PostError(const Text: String);
var O: TVoskRecognizer;
begin
 O := FOwner;
 WriteIn(['Vosk: ', Text]);
 TThread.Queue(Self,
  procedure
  begin
   O.FLastError := Text;
   if Assigned(O.FOnError) then O.FOnError(Text);
  end);
end;

// для сообщения: ключевые файлы модели, которых нет или они пустые (неполное
// копирование)
function ModelMissing(const Path: String): String;
const Files: array[0..4] of String = ('am/final.mdl', 'conf/model.conf', 'conf/mfcc.conf', 'ivector/final.ie', 'graph/phones/word_boundary.int');
var N, F: String;
begin
 Result := '';
 for N in Files do begin
  F := TPath.Combine(Path, N.Replace('/', TPath.DirectorySeparatorChar));
  if not TFile.Exists(F) or (TFile.GetSize(F) = 0) then Result := Result + sLineBreak + N;
 end;
 if Result <> '' then Result := sLineBreak + 'нет файлов:' + Result;
end;

// модель (один раз на распознаватель) и распознаватель с грамматикой
function TVoskThread.Prepare: Boolean;
var SW: TStopwatch;
begin
 Result := False;
{$IFDEF CPUX64}
// библиотека C/C++: исключения плавающей точки маскируются, как ждет код
// Kaldi (у потока Delphi часть из них открыта)
 SetMXCSR($1F80);
{$ENDIF}
 SW := TStopwatch.StartNew;
 if FOwner.FModel = nil then begin
  FOwner.FModel := vosk_model_new(PAnsiChar(UTF8Encode(FOwner.FModelPath)));
  WriteIn(['Vosk: модель загружена за ', SW.ElapsedMilliseconds, ' мс']);
  if FOwner.FModel = nil then begin
   PostError('Модель не загружена: ' + FOwner.FModelPath + ModelMissing(FOwner.FModelPath));
   exit;
  end;
 end;
 SW := TStopwatch.StartNew;
 if FGrammar <> '' then FRec := vosk_recognizer_new_grm(FOwner.FModel, VoskSampleRate, PAnsiChar(UTF8Encode(FGrammar))) else
  FRec := vosk_recognizer_new(FOwner.FModel, VoskSampleRate);
 WriteIn(['Vosk: распознаватель создан за ', SW.ElapsedMilliseconds, ' мс']);
 if FRec = nil then begin
  PostError('Распознаватель не создан');
  exit;
 end;
 Result := True;
end;

procedure TVoskThread.PostText(const Text: String; Final: Boolean);
var O: TVoskRecognizer;
begin
 O := FOwner;
 TThread.Queue(Self,
  procedure
  begin
   if Final then begin
    if Assigned(O.FOnResult) then O.FOnResult(Text);
   end else
    if Assigned(O.FOnPartial) then O.FOnPartial(Text);
  end);
end;

procedure TVoskThread.Feed(Data: Pointer; Bytes: Integer);
var S: String;
begin
 if vosk_recognizer_accept_waveform(FRec, Data, Bytes) <> 0 then begin
  S := JsonField(vosk_recognizer_result(FRec), 'text');
  FLastPartial := '';
  if S <> '' then PostText(S, True);
 end else begin
  S := JsonField(vosk_recognizer_partial_result(FRec), 'partial');
  if S <> FLastPartial then begin
   FLastPartial := S;
   PostText(S, False);
  end;
 end;
end;

procedure TVoskThread.Execute;
{$IFDEF MSWINDOWS}
const BufCount = 4;
      BufBytes = VoskSampleRate div 10 * 2; // 0,1 с
var Fmt: TWaveFormatEx;
    H: HWAVEIN;
    Hdr: array[0..BufCount - 1] of TWaveHdr;
    Buf: array[0..BufCount - 1] of array[0..BufBytes - 1] of Byte;
    I, Cur: Integer;
begin
 if not Prepare then exit;
 FillChar(Fmt, SizeOf(Fmt), 0);
 Fmt.wFormatTag := WAVE_FORMAT_PCM;
 Fmt.nChannels := 1;
 Fmt.nSamplesPerSec := VoskSampleRate;
 Fmt.wBitsPerSample := 16;
 Fmt.nBlockAlign := 2;
 Fmt.nAvgBytesPerSec := VoskSampleRate * 2;
 if waveInOpen(@H, WAVE_MAPPER, @Fmt, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then begin
  PostError('Микрофон не открыт (нет устройства записи или доступа к микрофону)');
  exit;
 end;
 WriteIn(['Vosk: микрофон открыт']);
 try
  for I := 0 to BufCount - 1 do begin
   FillChar(Hdr[I], SizeOf(TWaveHdr), 0);
   Hdr[I].lpData := @Buf[I];
   Hdr[I].dwBufferLength := BufBytes;
   waveInPrepareHeader(H, @Hdr[I], SizeOf(TWaveHdr));
   waveInAddBuffer(H, @Hdr[I], SizeOf(TWaveHdr));
  end;
  waveInStart(H);
  Cur := 0;
  while not Terminated do begin
   if Hdr[Cur].dwFlags and WHDR_DONE = 0 then begin
    Sleep(10);
    continue;
   end;
   Feed(Hdr[Cur].lpData, Hdr[Cur].dwBytesRecorded);
   Hdr[Cur].dwFlags := Hdr[Cur].dwFlags and not WHDR_DONE;
   waveInAddBuffer(H, @Hdr[Cur], SizeOf(TWaveHdr));
   Cur := (Cur + 1) mod BufCount;
  end;
  waveInReset(H);
  for I := 0 to BufCount - 1 do waveInUnprepareHeader(H, @Hdr[I], SizeOf(TWaveHdr));
 finally
  waveInClose(H);
 end;
{$ENDIF}
{$IFDEF ANDROID}
// источник VOICE_RECOGNITION = 6, CHANNEL_IN_MONO = 16, ENCODING_PCM_16BIT = 2
const SrcVoice = 6;
      ChMono = 16;
      Pcm16 = 2;
var Rec: JAudioRecord;
    Size, N: Integer;
    JBuf: TJavaArray<Byte>;
begin
 if not Prepare then exit;
 Size := TJAudioRecord.JavaClass.getMinBufferSize(VoskSampleRate, ChMono, Pcm16);
 if Size < VoskSampleRate div 5 then Size := VoskSampleRate div 5; // не меньше 0,1 с
 Rec := TJAudioRecord.JavaClass.init(SrcVoice, VoskSampleRate, ChMono, Pcm16, Size * 2);
 JBuf := TJavaArray<Byte>.Create(Size);
 try
  Rec.startRecording;
  while not Terminated do begin
   N := Rec.read(JBuf, 0, Size);
   if N > 0 then Feed(JBuf.Data, N);
  end;
  Rec.stop;
 finally
  Rec.release;
  JBuf.Free;
 end;
{$ENDIF}
{$IF not Defined(MSWINDOWS) and not Defined(ANDROID)}
begin
{$ENDIF}
// остаток фразы при остановке
 if FRec <> nil then begin
  FLastPartial := JsonField(vosk_recognizer_final_result(FRec), 'text');
  if FLastPartial <> '' then PostText(FLastPartial, True);
 end;
end;

{ TVoskRecognizer }

constructor TVoskRecognizer.Create;
begin
 inherited;
 FModelPath := VoskDefaultModelPath;
 FLibraryPath := VoskLibraryName;
end;

destructor TVoskRecognizer.Destroy;
begin
 Stop(True);
 if (FModel <> nil) and VoskLoaded then vosk_model_free(FModel);
 inherited;
end;

function TVoskRecognizer.LibraryAvailable: Boolean;
begin
 Result := LoadVosk(FLibraryPath);
 if not Result then FLastError := VoskLoadError;
end;

function TVoskRecognizer.Available: Boolean;
begin
 Result := LoadVosk(FLibraryPath);
 if not Result then begin
  FLastError := VoskLoadError;
  exit;
 end;
 Result := TDirectory.Exists(FModelPath);
 if not Result then FLastError := 'Не найдена модель ' + FModelPath;
end;

// JSON-массив строк вручную: кириллица - как есть (в UTF-8), без экранирования
procedure TVoskRecognizer.SetGrammar(const Words: array of String);
var I: Integer;
begin
 if Length(Words) = 0 then begin
  FGrammar := '';
  exit;
 end;
 FGrammar := '[';
 for I := 0 to High(Words) do FGrammar := FGrammar + '"' + StringReplace(Words[I], '"', '', [rfReplaceAll]) + '", ';
 FGrammar := FGrammar + '"[unk]"]';
end;

function TVoskRecognizer.GetActive: Boolean;
begin
 Result := FThread <> nil;
end;

procedure TVoskRecognizer.StartCapture;
begin
 if FThread <> nil then exit;
 FThread := TVoskThread.Create(Self);
end;

function TVoskRecognizer.Start: Boolean;
{$IFDEF ANDROID}
const PermRecordAudio = 'android.permission.RECORD_AUDIO';
{$ENDIF}
begin
 Result := Available;
 if not Result then exit;
{$IFDEF ANDROID}
 if not PermissionsService.IsPermissionGranted(PermRecordAudio) then begin
  PermissionsService.RequestPermissions([PermRecordAudio],
   procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
   begin
    if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then StartCapture else
     FLastError := 'Нет разрешения на запись звука';
   end);
  exit;
 end;
{$ENDIF}
 StartCapture;
 Result := FThread <> nil;
end;

// Discard - результаты, еще не доставленные в главный поток, отбрасываются
// (освобождение распознавателя)
procedure TVoskRecognizer.Stop(Discard: Boolean);
var T: TVoskThread;
begin
 if FThread = nil then exit;
 T := TVoskThread(FThread);
 FThread := nil;
 T.Terminate;
 T.WaitFor;
 if Discard then TThread.RemoveQueuedEvents(T);
 if T.FRec <> nil then vosk_recognizer_free(T.FRec);
 T.Free;
end;

{ TVoskModelDownload }

class function TVoskModelDownload.Start(OnProgress: TVoskDownloadProgress; OnDone: TVoskDownloadDone): IVoskModelDownload;
var D: TVoskModelDownload;
    Keep: IVoskModelDownload;
begin
 D := TVoskModelDownload.Create;
 D.FOnProgress := OnProgress;
 D.FOnDone := OnDone;
 D.FLastPercent := -1;
 Keep := D;
 Result := Keep;
// ссылка Keep в потоке - объект D жив до конца загрузки
 TThread.CreateAnonymousThread(
  procedure
  begin
   D.Run;
   Keep := nil;
  end).Start;
end;

procedure TVoskModelDownload.Cancel;
begin
 FCancel := True;
end;

function TVoskModelDownload.Canceled: Boolean;
begin
 Result := FCancel;
end;

// прогресс - от всего архива: FBase (докачка) + текущий запрос
procedure TVoskModelDownload.ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
var P: Integer;
    Cb: TVoskDownloadProgress;
    Keep: IVoskModelDownload;
    Rcv, Tot: Int64;
begin
 AAbort := FCancel;
 if FCancel or (AContentLength <= 0) then exit;
 Rcv := FBase + AReadCount;
 Tot := FBase + AContentLength;
 FTotal := Tot;
 P := Rcv * 100 div Tot;
 if P = FLastPercent then exit;
 FLastPercent := P;
 Cb := FOnProgress;
 Keep := Self;
 if Assigned(Cb) then
  TThread.Queue(nil, procedure begin if not Keep.Canceled then Cb(Rcv, Tot); end);
end;

// поток загрузки: zip - распаковка - событие. Сервер модели медленный, бывают
// паузы и обрывы (на Android - исключение timeout): таймауты увеличены, после
// обрыва - докачка с места остановки (Range), до MaxAttempts попыток. Часть
// каждого запроса пишется в отдельный файл и дописывается к архиву только при
// ответе 206 (сервер не поддержал Range - 200 - архив заново). Попытка без
// единого байта или ответ с ошибкой - переход к следующему источнику
procedure TVoskModelDownload.Run;
const MaxAttempts = 8;
var Http: THTTPClient;
    F, Part: TFileStream;
    Zip, PartName, Err, Url: String;
    Ok, Complete, Got: Boolean;
    Done: TVoskDownloadDone;
    Resp: IHTTPResponse;
    Keep: IVoskModelDownload;
    Attempt, Src: Integer;
begin
 Ok := False;
 Err := '';
 Zip := TPath.Combine(TPath.GetTempPath, 'vosk-model.zip');
 PartName := Zip + '.part';
 try
  try
   if TFile.Exists(Zip) then TFile.Delete(Zip);
   Complete := False;
   Attempt := 0;
   Src := 0;
   while not Complete and not FCancel do begin
    Inc(Attempt);
    Url := VoskModelUrls[Src];
    Got := False;
    FBase := 0;
    if TFile.Exists(Zip) then FBase := TFile.GetSize(Zip);
    Resp := nil;
    Http := THTTPClient.Create;
    try
     Http.ConnectionTimeout := 60000;
     Http.ResponseTimeout := 300000; // ожидание данных - до 5 минут
     Http.OnReceiveData := ReceiveData;
     if FBase > 0 then Http.CustomHeaders['Range'] := 'bytes=' + IntToStr(FBase) + '-';
     Part := TFileStream.Create(PartName, fmCreate);
     try
      try
       Resp := Http.Get(Url, Part);
      except
       on E: Exception do begin
        WriteIn(['Vosk: загрузка прервана (попытка ', Attempt, ', ', Url, '): ', E.Message]);
        if Attempt >= MaxAttempts then raise;
       end;
      end;
      Got := Part.Size > 0;
     // полученное - в архив (обрыв тоже: следующая попытка докачает)
      if Got and ((Resp = nil) or (Resp.StatusCode = 206) or ((Resp.StatusCode = 200) and (FBase = 0))) then begin
       if FBase = 0 then F := TFileStream.Create(Zip, fmCreate) else begin
        F := TFileStream.Create(Zip, fmOpenReadWrite);
        F.Seek(0, soEnd);
       end;
       try
        Part.Position := 0;
        F.CopyFrom(Part, Part.Size);
       finally
        F.Free;
       end;
      end else
      if Got and (Resp <> nil) and (Resp.StatusCode = 200) then begin
      // сервер прислал архив целиком - он и есть результат
       Part.Position := 0;
       F := TFileStream.Create(Zip, fmCreate);
       try
        F.CopyFrom(Part, Part.Size);
       finally
        F.Free;
       end;
      end;
     finally
      Part.Free;
     end;
    finally
     Http.Free;
    end;
    if FCancel then exit;
    if (Resp <> nil) and ((Resp.StatusCode = 200) or (Resp.StatusCode = 206) or (Resp.StatusCode = 416)) then
     Complete := True // 416 - запрошен диапазон за концом: архив уже целиком
    else begin
     if Resp <> nil then begin
      WriteIn(['Vosk: ', Url, ' ответил ', Resp.StatusCode, ' ', Resp.StatusText]);
      if Attempt >= MaxAttempts then raise Exception.CreateFmt('сервер ответил %d %s', [Resp.StatusCode, Resp.StatusText]);
     end;
     if (Resp <> nil) or not Got then Src := (Src + 1) mod Length(VoskModelUrls);
     Sleep(2000); // пауза перед докачкой
    end;
   end;
   if FCancel then exit;
   TZipFile.ExtractZipFile(Zip, VoskModelBaseDir);
   Ok := VoskModelExists(VoskDefaultModelPath);
   if not Ok then Err := 'в архиве нет модели';
  except
   on E: Exception do Err := E.Message;
  end;
 finally
  if TFile.Exists(Zip) then TFile.Delete(Zip);
  if TFile.Exists(PartName) then TFile.Delete(PartName);
  if not FCancel then begin
   Done := FOnDone;
   Keep := Self;
   TThread.Queue(nil, procedure begin if Assigned(Done) and not Keep.Canceled then Done(Ok, Err); end);
  end;
  WriteIn(['Vosk: загрузка модели ', Ok, ' ', Err]);
 end;
end;

{ SpokenToNumber }

function SpokenToNumber(const Text: String): String;
const Words: array[0..38] of String = (
  'ноль', 'один', 'одна', 'два', 'две', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять',
  'десять', 'одиннадцать', 'двенадцать', 'тринадцать', 'четырнадцать', 'пятнадцать', 'шестнадцать',
  'семнадцать', 'восемнадцать', 'девятнадцать', 'двадцать', 'тридцать', 'сорок', 'пятьдесят',
  'шестьдесят', 'семьдесят', 'восемьдесят', 'девяносто', 'сто', 'двести', 'триста', 'четыреста',
  'пятьсот', 'шестьсот', 'семьсот', 'восемьсот', 'девятьсот');
  Values: array[0..38] of Integer = (0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9,
  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 30, 40, 50, 60, 70, 80, 90,
  100, 200, 300, 400, 500, 600, 700, 800, 900);
var Parts: array[0..1] of TArray<Integer>;
    PartIdx, I, J, Sum: Integer;
    Neg, Digits: Boolean;
    Tokens: TArray<String>;
    S: String;
function PartStr(const P: TArray<Integer>): String;
var K: Integer;
begin
 Result := '';
 if Length(P) = 0 then exit;
 Digits := Length(P) > 1;
 for K := 0 to High(P) do
  if P[K] > 9 then Digits := False;
 if Digits then begin
  for K := 0 to High(P) do Result := Result + IntToStr(P[K]);
  exit;
 end;
 Sum := 0;
 for K := 0 to High(P) do Sum := Sum + P[K];
 Result := IntToStr(Sum);
end;
begin
 Result := '';
 Neg := False;
 PartIdx := 0;
 Tokens := Text.ToLower.Split([' '], TStringSplitOptions.ExcludeEmpty);
 for I := 0 to High(Tokens) do begin
  S := Tokens[I];
  if S = 'минус' then begin
   if (PartIdx = 0) and (Length(Parts[0]) = 0) then Neg := True;
   continue;
  end;
  if (S = 'точка') or (S = 'запятая') then begin
   PartIdx := 1;
   continue;
  end;
  for J := 0 to High(Words) do
   if Words[J] = S then begin
    Parts[PartIdx] := Parts[PartIdx] + [Values[J]];
    break;
   end;
 end;
 if (Length(Parts[0]) = 0) and (Length(Parts[1]) = 0) then exit;
 Result := PartStr(Parts[0]);
 if Result = '' then Result := '0';
 if Length(Parts[1]) > 0 then Result := Result + '.' + PartStr(Parts[1]);
 if Neg then Result := '-' + Result;
end;

end.
