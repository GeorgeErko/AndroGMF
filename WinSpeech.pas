unit WinSpeech;

// Голосовой ввод Windows: распознавание речи системы (WinRT
// Windows.Media.SpeechRecognition), без своих библиотек и моделей. Нужен
// русский речевой пакет Windows (Параметры - Время и язык - Язык - Русский -
// Распознавание речи) и доступ программ к микрофону (Параметры -
// Конфиденциальность - Микрофон). Available - есть язык распознавания с
// грамматикой на «ru». Распознавание непрерывное (ContinuousRecognitionSession),
// ограничено словами SetGrammar: последовательность слов из списка (грамматика
// SRGS во временном файле), как грамматика Vosk; без SetGrammar - только
// слова чисел (VoskNumberWords). Результаты - в главном потоке: OnPartial
// (промежуточный текст), OnResult (законченная фраза). Тот же интерфейс, что
// у TVoskRecognizer (VoskSpeech). На других платформах Available = False.

interface

uses
  System.SysUtils, System.Classes
{$IFDEF MSWINDOWS}
  , Winapi.CommonTypes, WinAPI.Media
{$ENDIF}
  ;

type
  TSpeechTextEvent = procedure(const Text: String) of object;

  TWinSpeechRecognizer = class
  private
    FWords: TArray<String>;
    FLastError: String;
    FLanguageTag: String;
    FOnResult: TSpeechTextEvent;
    FOnPartial: TSpeechTextEvent;
{$IFDEF MSWINDOWS}
    FRec: SpeechRecognition_ISpeechRecognizer;
    FSession: SpeechRecognition_ISpeechContinuousRecognitionSession;
    FResultToken: EventRegistrationToken;
    FHypToken: EventRegistrationToken;
    FHandlers: TInterfaceList; // обработчики событий WinRT (ссылка на распознаватель)
    procedure DetachHandlers;
{$ENDIF}
    function GetActive: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
   // в системе есть распознавание на русском (язык грамматик ru-*)
    function Available: Boolean;
   // слова грамматики: фраза - последовательность слов из списка
    procedure SetGrammar(const Words: array of String);
    function Start: Boolean;
    procedure Stop;
    property Active: Boolean read GetActive;
    property LanguageTag: String read FLanguageTag;
    property LastError: String read FLastError;
    property OnResult: TSpeechTextEvent read FOnResult write FOnResult;
    property OnPartial: TSpeechTextEvent read FOnPartial write FOnPartial;
  end;

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows, System.IOUtils, FMX.Forms, Winapi.WinRT, System.Win.WinRT,
  WinAPI.Foundation, WinAPI.Globalization, WinAPI.Storage, Winapi.HSTRINGIterables,
  VoskSpeech;

type
// объект без привязки к апартаменту - события WinRT приходят из других потоков
  IAgileObject = interface(IUnknown)
  ['{94EA2B94-E9CC-49E0-C0FF-EE64CA8F5B90}']
  end;

  TSpeechHandler = class(TInterfacedObject, IAgileObject)
  protected
    FOwner: TWinSpeechRecognizer;
    procedure Post(const Text: String; Final: Boolean);
  public
    constructor Create(AOwner: TWinSpeechRecognizer);
  end;

  TResultHandler = class(TSpeechHandler,
    TypedEventHandler_2__SpeechRecognition_ISpeechContinuousRecognitionSession__SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs)
    procedure Invoke(sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
      args: SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs); safecall;
  end;

  THypothesisHandler = class(TSpeechHandler,
    TypedEventHandler_2__SpeechRecognition_ISpeechRecognizer__SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs)
    procedure Invoke(sender: SpeechRecognition_ISpeechRecognizer;
      args: SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs); safecall;
  end;

constructor TSpeechHandler.Create(AOwner: TWinSpeechRecognizer);
begin
 inherited Create;
 FOwner := AOwner;
end;

// в главный поток; распознаватель мог быть остановлен (FOwner = nil)
procedure TSpeechHandler.Post(const Text: String; Final: Boolean);
var Keep: IInterface;
    H: TSpeechHandler;
begin
 if (FOwner = nil) or (Text = '') then exit;
 Keep := Self; // обработчик жив до доставки
 H := Self;
 TThread.Queue(nil,
  procedure
  begin
   if (Keep = nil) or (H.FOwner = nil) then exit;
   if Final then begin
    if Assigned(H.FOwner.FOnResult) then H.FOwner.FOnResult(Text);
   end else
    if Assigned(H.FOwner.FOnPartial) then H.FOwner.FOnPartial(Text);
  end);
end;

procedure TResultHandler.Invoke(sender: SpeechRecognition_ISpeechContinuousRecognitionSession;
  args: SpeechRecognition_ISpeechContinuousRecognitionResultGeneratedEventArgs);
var R: SpeechRecognition_ISpeechRecognitionResult;
begin
 R := args.get_Result;
 if (R = nil) or (R.get_Status <> SpeechRecognition_SpeechRecognitionResultStatus.Success) then exit;
 if R.get_Confidence = SpeechRecognition_SpeechRecognitionConfidence.Rejected then exit;
 Post(Trim(HSTRINGToString(R.get_Text)), True);
end;

procedure THypothesisHandler.Invoke(sender: SpeechRecognition_ISpeechRecognizer;
  args: SpeechRecognition_ISpeechRecognitionHypothesisGeneratedEventArgs);
begin
 Post(Trim(HSTRINGToString(args.get_Hypothesis.get_Text)), False);
end;

// ожидание асинхронной операции WinRT с обработкой сообщений (операции
// короткие: файл грамматики, компиляция, запуск); ошибка - исключение
procedure WaitAsync(const Op: IInterface; TimeoutMs: Cardinal = 15000);
var Info: IAsyncInfo;
    T0: UInt64;
begin
 if not Supports(Op, IAsyncInfo, Info) then raise Exception.Create('Нет IAsyncInfo');
 T0 := GetTickCount64;
 while Info.Status = AsyncStatus.Started do begin
  Application.ProcessMessages;
  Sleep(10);
  if GetTickCount64 - T0 > TimeoutMs then begin
   Info.Cancel;
   raise Exception.Create('Превышено время ожидания');
  end;
 end;
 if Info.Status <> AsyncStatus.Completed then
  raise Exception.CreateFmt('%s (0x%.8x)', [SysErrorMessage(Cardinal(Info.ErrorCode)), Cardinal(Info.ErrorCode)]);
end;

// язык распознавания с грамматикой на русском
function FindRussian(out Lang: ILanguage; out Tag: String): Boolean;
var V: IVectorView_1__ILanguage;
    I: Integer;
    L: ILanguage;
begin
 Result := False;
 V := TSpeechRecognition_SpeechRecognizer.SupportedGrammarLanguages;
 if V = nil then exit;
 for I := 0 to Integer(V.get_Size) - 1 do begin
  L := V.GetAt(I);
  Tag := HSTRINGToString(L.get_LanguageTag);
  if SameText(Copy(Tag, 1, 2), 'ru') then begin
   Lang := L;
   exit(True);
  end;
 end;
end;

// грамматика SRGS: любая последовательность (1-20) слов из списка
function WriteSrgs(const Words: TArray<String>; const Tag: String): String;
var S: TStringBuilder;
    W: String;
begin
 S := TStringBuilder.Create;
 try
  S.AppendLine('<?xml version="1.0" encoding="utf-8"?>');
  S.AppendLine('<grammar version="1.0" xml:lang="' + Tag + '" root="seq" xmlns="http://www.w3.org/2001/06/grammar">');
  S.AppendLine(' <rule id="seq" scope="public">');
  S.AppendLine('  <item repeat="1-20"><one-of>');
  for W in Words do
   S.AppendLine('   <item>' + StringReplace(StringReplace(W, '&', '', [rfReplaceAll]), '<', '', [rfReplaceAll]) + '</item>');
  S.AppendLine('  </one-of></item>');
  S.AppendLine(' </rule>');
  S.AppendLine('</grammar>');
  Result := TPath.Combine(TPath.GetTempPath, 'GeomasterSpeech.grxml');
  TFile.WriteAllText(Result, S.ToString, TEncoding.UTF8);
 finally
  S.Free;
 end;
end;

{$ENDIF}

{ TWinSpeechRecognizer }

constructor TWinSpeechRecognizer.Create;
begin
 inherited;
{$IFDEF MSWINDOWS}
 FHandlers := TInterfaceList.Create;
{$ENDIF}
end;

destructor TWinSpeechRecognizer.Destroy;
begin
 Stop;
{$IFDEF MSWINDOWS}
 FHandlers.Free;
{$ENDIF}
 inherited;
end;

function TWinSpeechRecognizer.GetActive: Boolean;
begin
{$IFDEF MSWINDOWS}
 Result := FSession <> nil;
{$ELSE}
 Result := False;
{$ENDIF}
end;

procedure TWinSpeechRecognizer.SetGrammar(const Words: array of String);
var I: Integer;
begin
 SetLength(FWords, Length(Words));
 for I := 0 to High(Words) do FWords[I] := Words[I];
end;

function TWinSpeechRecognizer.Available: Boolean;
{$IFDEF MSWINDOWS}
var Lang: ILanguage;
begin
 try
  Result := FindRussian(Lang, FLanguageTag);
  if not Result then FLastError := 'В Windows нет русского речевого пакета (Параметры - Время и язык - Язык - Русский - Распознавание речи)';
 except
  on E: Exception do begin
   FLastError := 'Распознавание речи Windows недоступно: ' + E.Message;
   Result := False;
  end;
 end;
end;
{$ELSE}
begin
 FLastError := 'Распознавание речи Windows - только в Windows';
 Result := False;
end;
{$ENDIF}

function TWinSpeechRecognizer.Start: Boolean;
{$IFDEF MSWINDOWS}
var Lang: ILanguage;
    Path: String;
    HPath: HSTRING;
    FileOp: IAsyncOperation_1__IStorageFile;
    CompileOp: IAsyncOperation_1__SpeechRecognition_ISpeechRecognitionCompilationResult;
    Constraint: SpeechRecognition_ISpeechRecognitionGrammarFileConstraint;
    Rec2: SpeechRecognition_ISpeechRecognizer2;
    Status: SpeechRecognition_SpeechRecognitionResultStatus;
    RH: TResultHandler;
    HH: THypothesisHandler;
    Words: TArray<String>;
    I: Integer;
begin
 Result := FSession <> nil;
 if Result then exit;
 try
  if not FindRussian(Lang, FLanguageTag) then begin
   FLastError := 'В Windows нет русского речевого пакета (Параметры - Время и язык - Язык - Русский - Распознавание речи)';
   exit;
  end;
  FRec := TSpeechRecognition_SpeechRecognizer.Create(Lang);
 // грамматика: слова SetGrammar или слова чисел
  Words := FWords;
  if Length(Words) = 0 then begin
   SetLength(Words, Length(VoskNumberWords));
   for I := 0 to High(VoskNumberWords) do Words[I] := VoskNumberWords[I];
  end;
  Path := WriteSrgs(Words, FLanguageTag);
  HPath := CreateHSTRING(Path);
  try
   FileOp := TStorageFile.GetFileFromPathAsync(HPath);
   WaitAsync(FileOp);
  finally
   DeleteHSTRING(HPath);
  end;
  Constraint := TSpeechRecognition_SpeechRecognitionGrammarFileConstraint.Create(FileOp.GetResults);
  FRec.get_Constraints.Append(Constraint as SpeechRecognition_ISpeechRecognitionConstraint);
  CompileOp := FRec.CompileConstraintsAsync;
  WaitAsync(CompileOp);
  Status := CompileOp.GetResults.get_Status;
  if Status <> SpeechRecognition_SpeechRecognitionResultStatus.Success then begin
   FLastError := 'Грамматика не принята распознавателем (код ' + IntToStr(Ord(Status)) + ')';
   FRec := nil;
   exit;
  end;
 // непрерывное распознавание: фразы и промежуточный текст
  Rec2 := FRec as SpeechRecognition_ISpeechRecognizer2;
  FSession := Rec2.get_ContinuousRecognitionSession;
  RH := TResultHandler.Create(Self);
  HH := THypothesisHandler.Create(Self);
  FHandlers.Add(RH);
  FHandlers.Add(HH);
  FResultToken := FSession.add_ResultGenerated(RH);
  FHypToken := Rec2.add_HypothesisGenerated(HH);
  WaitAsync(FSession.StartAsync);
  Result := True;
 except
  on E: Exception do begin
   FLastError := 'Распознавание речи Windows: ' + E.Message +
    '. Проверьте доступ к микрофону (Параметры - Конфиденциальность - Микрофон)';
   DetachHandlers;
   FSession := nil;
   FRec := nil;
   Result := False;
  end;
 end;
end;
{$ELSE}
begin
 FLastError := 'Распознавание речи Windows - только в Windows';
 Result := False;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
// обработчики больше не обращаются к распознавателю (уже отправленные
// результаты в главном потоке пропускаются)
procedure TWinSpeechRecognizer.DetachHandlers;
var I: Integer;
begin
 for I := 0 to FHandlers.Count - 1 do (FHandlers[I] as TSpeechHandler).FOwner := nil;
 FHandlers.Clear;
end;
{$ENDIF}

procedure TWinSpeechRecognizer.Stop;
begin
{$IFDEF MSWINDOWS}
 if FSession = nil then exit;
 DetachHandlers;
 try
  FSession.remove_ResultGenerated(FResultToken);
  (FRec as SpeechRecognition_ISpeechRecognizer2).remove_HypothesisGenerated(FHypToken);
  FSession.CancelAsync;
 except
 end;
 FSession := nil;
 FRec := nil;
{$ENDIF}
end;

end.
