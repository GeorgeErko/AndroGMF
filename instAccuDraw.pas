unit instAccuDraw;

// Панель параметров операций (рисование, перемещение, копирование и др.):
// числа и строки (TButton - значение в тексте кнопки, ввод цифровой
// клавиатурой панели), флажки (TCheckBox), выбор одного из (TRadioButton).
// Панель - дочерний элемент главной формы, Align = Bottom над строкой
// состояния. Show(CNames, CClass) расставляет элементы друг за другом в
// порядке массивов (перед TButton - TLabel с именем, у флажков и
// переключателей имя - их текст); справа - цифровая клавиатура (в
// DesignTime). Нажатие на TButton делает ее активной (ActiveEditButton) и
// очищает ее текст, клавиши дописывают текст активной кнопки, «←» удаляет
// последний символ, «⏎» (Enter) - OnEnter: значение применяется операцией,
// «↶» - OnUndoPoint: удаление последней точки рисуемого примитива, «X» -
// OnClearSnaps: сброс привязок, «🎤» - голосовой ввод (WinSpeech/VoskSpeech):
// число - в активную кнопку, «ввод», «назад», «сброс», «стереть» - команды.
// Values[Имя] - значение элемента: TButton - текст, флажок и переключатель -
// True/False (запись 'True' отмечает), список (TComboBox, перед ним - TLabel,
// строки - SetItems) - выбранная строка.
// FullKeyboard - полная клавиатура (буквы русские/латинские, цифры, пробел)
// под элементами вместо цифровой: ввод текста в активную кнопку

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.TextLayout, System.ImageList,
  FMX.ImgList, FMX.ListBox, AppForms;

type
  TInstAccuDrawFrame = class(TFrame)
    ControlsBox: THorzScrollBox;
    pnlKeys: TLayout;
    LayKeys1: TLayout;
    LayKeys2: TLayout;
    btnKey1: TButton;
    btnKey2: TButton;
    btnKey3: TButton;
    btnKey4: TButton;
    btnKey5: TButton;
    btnKey6: TButton;
    btnKey7: TButton;
    btnKey8: TButton;
    btnKey9: TButton;
    btnKey0: TButton;
    btnKeyDot: TButton;
    btnKeyBack: TButton;
    btnKeyUndo: TButton;
    btnKeySnaps: TButton;
    btnKeyMic: TButton;
    btnKeyEnter: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    ImageList1: TImageList;
    procedure KeyClick(Sender: TObject);
    procedure KeyBackClick(Sender: TObject);
    procedure KeyEnterClick(Sender: TObject);
    procedure KeyUndoClick(Sender: TObject);
    procedure KeySnapsClick(Sender: TObject);
    procedure KeyMicClick(Sender: TObject);
  private
    FControls: TDictionary<String, TControl>; // элементы по имени
    FItems: TList<TControl>; // созданные элементы (с метками) - для очистки
    FActiveEditButton: TButton;
  // голосовой ввод: распознаватель Windows (WinRT) или Vosk - выбирается при
  // первом включении; число - в активную кнопку, слова-команды - клавиши
    FWinSpeech: TObject;
    FVosk: TObject;
  // режим голосового ввода: включен нажатием «🎤», выключен отжатием
  // пользователем; при показе панели распознавание запускается снова;
  // хранится в настройках (AccuDraw_Voice)
    FVoiceOn: Boolean;
    FDownload: IInterface; // загрузка модели Vosk (IVoskModelDownload); nil - нет
  // полная клавиатура: клавиши по рядам для русской (False) и латинской (True)
  // раскладки; создается при первом показе
    FFullKeys: TLayout;
    FKeyRows: array[Boolean] of TArray<TArray<TButton>>;
    FFullKeyboard: Boolean;
    FLatin: Boolean; // раскладка: латиница
    FShift: Boolean; // следующая буква - заглавная
    FBaseHeight: Single; // высота панели без полной клавиатуры
    procedure SetFullKeyboard(const Value: Boolean);
    procedure BuildFullKeys;
    procedure UpdateFullKeys;
    procedure FullKeysResize(Sender: TObject);
    procedure FullKeyClick(Sender: TObject);
    procedure ComboChange(Sender: TObject);
    procedure DownloadModel(V: TObject);
    procedure SetVoiceOn(Value: Boolean);
    procedure ClearControls;
    procedure ControlClick(Sender: TObject);
    procedure SetActiveEditButton(const Value: TButton);
    function GetValue(const CName: String): String;
    procedure SetValue(const CName, Value: String);
    procedure PlaceAboveStatusBar;
    procedure VoiceResult(const Text: String);
    procedure VoiceError(const Text: String);
    function VoiceStart: Boolean;
    procedure VoiceStop;
  public
   // значение изменено (клавиша, флажок, переключатель, выбор кнопки)
    OnChange: TNotifyEvent;
   // кто показал панель (операция мыши): прячет ее только он - новая операция
   // создается раньше, чем освобождается прежняя
    ShownBy: TObject;
   // клавиша Enter (на панели или клавиатуре): применить значение активной
   // кнопки; Sender - кнопка
    OnEnter: TNotifyEvent;
   // «↶»: удалить последнюю точку рисуемого примитива (клавиша Z)
    OnUndoPoint: TNotifyEvent;
   // «X»: сбросить привязки (точка залипания, направляющие от нее; клавиша X)
    OnClearSnaps: TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Show(const CNames: array of String; const CClass: array of TComponentClass);
    procedure Hide;
    function ControlByName(const CName: String): TControl;
   // строки списка (TComboBox) по имени элемента
    procedure SetItems(const CName: String; const Items: array of String);
    function NameOf(Ctrl: TObject): String;
   // число из значения элемента (точка или запятая); False - не число
    function FloatValue(const CName: String; out V: Double): Boolean;
   // ввод с клавиатуры: символ в конец текста активной кнопки, удаление
   // последнего символа, Enter
    procedure AddChar(Ch: Char);
    procedure BackChar;
    procedure DoEnter;
    property ActiveEditButton: TButton read FActiveEditButton write SetActiveEditButton;
   // полная клавиатура вместо цифровой (панель выше на ее высоту)
    property FullKeyboard: Boolean read FFullKeyboard write SetFullKeyboard;
    property Values[const CName: String]: String read GetValue write SetValue; default;
  end;

// панель главной формы: созданная панель регистрируется сама (первая);
// если ее еще нет - ищется среди компонентов главной формы или создается на
// ней (Align = Bottom, скрыта); nil - главной формы нет; CreateIfNone =
// False - только существующая панель (деструкторы, клавиатура)
function AccuDrawPanel(CreateIfNone: Boolean = True): TInstAccuDrawFrame;
// фокус - главному окну: ни один элемент не в фокусе (клавиши идут форме и
// операции мыши), окно активно
procedure FocusMainForm;

implementation

uses FMX.DialogService, System.Diagnostics, System.StrUtils, VoskSpeech, WinSpeech, Writer, newProcs, AppUI;

{$R *.fmx}

type
  TControlAccess = class(TControl);

var
  FPanel: TInstAccuDrawFrame;

function AccuDrawPanel(CreateIfNone: Boolean = True): TInstAccuDrawFrame;
var I: Integer;
    F: TCommonCustomForm;
begin
 if (FPanel = nil) and CreateIfNone then begin
  F := Application.MainForm;
  if F = nil then exit(nil);
  for I := 0 to F.ComponentCount - 1 do
   if F.Components[I] is TInstAccuDrawFrame then begin
    FPanel := TInstAccuDrawFrame(F.Components[I]);
    break;
   end;
  if FPanel = nil then begin
   FPanel := TInstAccuDrawFrame.Create(F);
   FPanel.Parent := F;
   FPanel.Align := TAlignLayout.Bottom;
   FPanel.Visible := False;
  end;
 end;
 Result := FPanel;
end;

procedure FocusMainForm;
var F: TCommonCustomForm;
begin
 F := Application.MainForm;
 if F = nil then exit;
 F.Focused := nil;
 if not F.Active then F.Activate;
end;

const
  ItemHeight = 28;
  ButtonHeight = 24;
  ItemGap = 6;
  ButtonWidth = 80;
  ComboWidth = 130;
  FullKeyHeight = {$IFDEF ANDROID}40{$ELSE}30{$ENDIF};
  FullKeyCols = 12; // ширина ряда в клавишах

constructor TInstAccuDrawFrame.Create(AOwner: TComponent);
begin
 inherited;
 FControls := TDictionary<String, TControl>.Create;
 FItems := TList<TControl>.Create;
 if FPanel = nil then FPanel := Self;
 FVoiceOn := GReadInteger('AccuDraw_Voice', 0) = 1;
end;

destructor TInstAccuDrawFrame.Destroy;
begin
 if FDownload <> nil then (FDownload as IVoskModelDownload).Cancel;
 FDownload := nil;
 VoiceStop;
 FWinSpeech.Free;
 FVosk.Free;
 if FPanel = Self then FPanel := nil;
 FControls.Free;
 FItems.Free;
 inherited;
end;

procedure TInstAccuDrawFrame.ClearControls;
var I: Integer;
begin
 FActiveEditButton := nil;
 FControls.Clear;
 for I := FItems.Count - 1 downto 0 do FItems[I].Free;
 FItems.Clear;
end;

// ширина текста шрифтом элемента
function TextWidth(Ctrl: TPresentedTextControl; const S: String): Single;
var L: TTextLayout;
begin
 L := TTextLayoutManager.DefaultTextLayout.Create;
 try
  L.BeginUpdate;
  L.Font.Assign(Ctrl.TextSettings.Font);
  L.Text := S;
  L.WordWrap := False;
  L.EndUpdate;
  Result := L.TextWidth;
 finally
  L.Free;
 end;
end;

// элементы друг за другом слева направо; переключатели - одна группа
procedure TInstAccuDrawFrame.Show(const CNames: array of String; const CClass: array of TComponentClass);
var I: Integer;
    X: Single;
    C: TControl;
    L: TLabel;
    First: TButton;
procedure Place(Ctrl: TControl; W: Single; H: Single = ItemHeight);
begin
 Ctrl.Parent := ControlsBox;
 Ctrl.SetBounds(X, (ControlsBox.Height - H) / 2, W, H);
 X := X + W + ItemGap;
 FItems.Add(Ctrl);
end;
begin
 ClearControls;
// полную клавиатуру включает показавшая панель операция после Show
 FullKeyboard := False;
 X := ItemGap;
 First := nil;
 for I := 0 to High(CNames) do begin
  if I > High(CClass) then break;
  if (CClass[I] = TButton) or (CClass[I] = TComboBox) then begin
   L := TLabel.Create(Self);
   L.Text := CNames[I];
   L.TextSettings.WordWrap := False;
   Place(L, TextWidth(L, CNames[I]) + 4);
   UISetRule(L, 'ui:android:font-3');
  end;
  C := TControl(CClass[I].Create(Self));
  C.CanFocus := False;
  if C is TPresentedTextControl then
   if C is TButton then TButton(C).Text := '' else TPresentedTextControl(C).Text := CNames[I];
  if C is TButton then begin
   TButton(C).StaysPressed := True;
   if First = nil then First := TButton(C);
   Place(C, ButtonWidth, ButtonHeight);
  end else
  if C is TComboBox then begin
   Place(C, ComboWidth, ButtonHeight);
   TComboBox(C).OnChange := ComboChange;
  end else
  if C is TPresentedTextControl then Place(C, TextWidth(TPresentedTextControl(C), CNames[I]) + 32) else
   Place(C, ButtonWidth);
  if C is TRadioButton then TRadioButton(C).GroupName := 'AccuDraw' + IntToStr(NativeInt(Self));
  if not (C is TComboBox) then TControlAccess(C).OnClick := ControlClick;
  FControls.AddOrSetValue(CNames[I], C);
 end;
 // ширина области элементов - по правому краю последнего элемента
 ControlsBox.Align := TAlignLayout.Left;
 ControlsBox.Width := X;
 PlaceAboveStatusBar;
 Visible := True;
 BringToFront;
 ActiveEditButton := First;
// голосовой ввод был включен - снова (кнопка нажата); не запустился - режим
// выключается (сообщение - в VoiceStart)
 if FVoiceOn and (btnKeyMic <> nil) then begin
  btnKeyMic.IsPressed := True;
  if not VoiceStart then begin
   btnKeyMic.IsPressed := False;
   SetVoiceOn(False);
  end;
 end;
end;

procedure TInstAccuDrawFrame.Hide;
begin
 FullKeyboard := False;
 FActiveEditButton := nil;
 ShownBy := nil;
 OnEnter := nil;
 OnChange := nil;
 OnUndoPoint := nil;
 OnClearSnaps := nil;
 VoiceStop;
 Visible := False;
end;

// над строкой состояния (TStatusBar, Align = Bottom, среди элементов родителя)
procedure TInstAccuDrawFrame.PlaceAboveStatusBar;
var I: Integer;
begin
 Align := TAlignLayout.Bottom;
 if Parent = nil then exit;
 for I := 0 to Parent.ChildrenCount - 1 do
  if Parent.Children[I] is TStatusBar then begin
   Position.Y := TStatusBar(Parent.Children[I]).Position.Y - Height;
   exit;
  end;
end;

// активная кнопка нажата, остальные - отпущены
procedure TInstAccuDrawFrame.SetActiveEditButton(const Value: TButton);
var C: TControl;
begin
 FActiveEditButton := Value;
 for C in FControls.Values do
  if C is TButton then TButton(C).IsPressed := C = Value;
end;

procedure TInstAccuDrawFrame.ControlClick(Sender: TObject);
begin
// с полной клавиатурой (ввод текста) текст не очищается - правка «←»
 if Sender is TButton then begin
  ActiveEditButton := TButton(Sender);
  if not FFullKeyboard then TButton(Sender).Text := '';
 end;
 if Assigned(OnChange) then OnChange(Sender);
 FocusMainForm;
end;

// выбрана строка списка
procedure TInstAccuDrawFrame.ComboChange(Sender: TObject);
begin
 if Assigned(OnChange) then OnChange(Sender);
 FocusMainForm;
end;

// клавиша цифровой клавиатуры - текст клавиши в конец текста активной кнопки
procedure TInstAccuDrawFrame.KeyClick(Sender: TObject);
begin
 if TButton(Sender).Text <> '' then AddChar(TButton(Sender).Text[1]);
 FocusMainForm;
end;

procedure TInstAccuDrawFrame.AddChar(Ch: Char);
begin
 if FActiveEditButton = nil then exit;
 FActiveEditButton.Text := FActiveEditButton.Text + Ch;
 FActiveEditButton.IsPressed := True;
 if Assigned(OnChange) then OnChange(FActiveEditButton);
end;

procedure TInstAccuDrawFrame.KeyEnterClick(Sender: TObject);
begin
 DoEnter;
 FocusMainForm;
end;

procedure TInstAccuDrawFrame.KeyUndoClick(Sender: TObject);
begin
 if Assigned(OnUndoPoint) then OnUndoPoint(Self);
 FocusMainForm;
end;

procedure TInstAccuDrawFrame.KeySnapsClick(Sender: TObject);
begin
 if Assigned(OnClearSnaps) then OnClearSnaps(Self);
 FocusMainForm;
end;

// слова грамматики: числа и команды
const
  VoiceCommands: array[0..5] of String = ('ввод', 'назад', 'сброс', 'стереть', 'очистить', 'удалить');

function VoiceWords: TArray<String>;
var I: Integer;
begin
 SetLength(Result, Length(VoskNumberWords) + Length(VoiceCommands));
 for I := 0 to High(VoskNumberWords) do Result[I] := VoskNumberWords[I];
 for I := 0 to High(VoiceCommands) do Result[Length(VoskNumberWords) + I] := VoiceCommands[I];
end;

// распознаватель: Windows (WinRT, русский речевой пакет), иначе Vosk
// (библиотека и модель); ни одного - сообщение с причинами
function TInstAccuDrawFrame.VoiceStart: Boolean;
var W: TWinSpeechRecognizer;
    V: TVoskRecognizer;
    Err: String;
    SW: TStopwatch;
    Ok: Boolean;
begin
 Result := False;
 if (FWinSpeech = nil) and (FVosk = nil) then begin
  W := TWinSpeechRecognizer.Create;
  SW := TStopwatch.StartNew;
  Ok := W.Available;
  WriteIn(['Голос: проверка распознавания Windows ', SW.ElapsedMilliseconds, ' мс']);
  if Ok then begin
   W.SetGrammar(VoiceWords);
   W.OnResult := VoiceResult;
   FWinSpeech := W;
  end else begin
   Err := W.LastError;
   W.Free;
   V := TVoskRecognizer.Create;
   SW := TStopwatch.StartNew;
   Ok := V.Available;
   WriteIn(['Голос: загрузка libvosk ', SW.ElapsedMilliseconds, ' мс']);
   if Ok then begin
    V.SetGrammar(VoiceWords);
    V.OnResult := VoiceResult;
    V.OnError := VoiceError;
    FVosk := V;
   end else
  // библиотека есть, модели нет - загрузка по требованию (кнопка нажата)
   if V.LibraryAvailable and not VoskModelExists(V.ModelPath) then begin
    V.SetGrammar(VoiceWords);
    V.OnResult := VoiceResult;
    V.OnError := VoiceError;
    FVosk := V;
    DownloadModel(V);
    exit(True);
   end else begin
    Err := Err + sLineBreak + V.LastError;
    V.Free;
    TDialogService.ShowMessage('Голосовой ввод недоступен:' + sLineBreak + Err);
    exit;
   end;
  end;
 end;
 if FWinSpeech <> nil then begin
  Result := TWinSpeechRecognizer(FWinSpeech).Start;
  if not Result then TDialogService.ShowMessage(TWinSpeechRecognizer(FWinSpeech).LastError);
 end else begin
 // модель еще загружается или загрузка была отменена - ждать / предложить снова
  if FDownload <> nil then exit(True);
  if not VoskModelExists(TVoskRecognizer(FVosk).ModelPath) then begin
   TVoskRecognizer(FVosk).ModelPath := VoskDefaultModelPath;
   if not VoskModelExists(TVoskRecognizer(FVosk).ModelPath) then begin
    DownloadModel(FVosk);
    exit(True);
   end;
  end;
  Result := TVoskRecognizer(FVosk).Start;
  if not Result then TDialogService.ShowMessage(TVoskRecognizer(FVosk).LastError);
 end;
end;

// ошибка в потоке распознавания (модель, микрофон): остановка, сообщение
procedure TInstAccuDrawFrame.VoiceError(const Text: String);
begin
 VoiceStop;
 SetVoiceOn(False);
 TDialogService.ShowMessage('Голосовой ввод: ' + Text);
end;

// модели нет: вопрос, загрузка в фоне (процент - на кнопке «🎤»), затем запуск
procedure TInstAccuDrawFrame.DownloadModel(V: TObject);
var MicText: String;
begin
 if FDownload <> nil then exit;
 MicText := btnKeyMic.Text;
 TDialogService.MessageDialog('Для голосового ввода нужна модель распознавания речи (около ' +
  IntToStr(VoskModelSizeMB) + ' МБ). Скачать сейчас?', TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
  procedure(const AResult: TModalResult)
  begin
   if AResult <> mrYes then begin
    btnKeyMic.IsPressed := False;
    SetVoiceOn(False);
    exit;
   end;
   btnKeyMic.Text := '0%';
   FDownload := TVoskModelDownload.Start(
    procedure(Received, Total: Int64)
    begin
     btnKeyMic.Text := IntToStr(Received * 100 div Total) + '%';
    end,
    procedure(Ok: Boolean; const Error: String)
    begin
     FDownload := nil;
     btnKeyMic.Text := MicText;
     if not Ok then begin
      btnKeyMic.IsPressed := False;
      SetVoiceOn(False);
      TDialogService.ShowMessage('Модель не загружена: ' + Error);
      exit;
     end;
     TVoskRecognizer(V).ModelPath := VoskDefaultModelPath;
    // загружено, пока кнопка нажата - сразу распознавание
     if btnKeyMic.IsPressed then begin
      if TVoskRecognizer(V).Start then SetVoiceOn(True) else begin
       btnKeyMic.IsPressed := False;
       TDialogService.ShowMessage(TVoskRecognizer(V).LastError);
      end;
     end;
    end);
  end);
end;

procedure TInstAccuDrawFrame.VoiceStop;
begin
 if FWinSpeech <> nil then TWinSpeechRecognizer(FWinSpeech).Stop;
 if FVosk <> nil then TVoskRecognizer(FVosk).Stop;
 if btnKeyMic <> nil then btnKeyMic.IsPressed := False;
end;

procedure TInstAccuDrawFrame.SetVoiceOn(Value: Boolean);
begin
 if FVoiceOn = Value then exit;
 FVoiceOn := Value;
 GWriteInteger('AccuDraw_Voice', Ord(Value));
end;

// нажатие - режим голосового ввода, отжатие пользователем - без голоса
procedure TInstAccuDrawFrame.KeyMicClick(Sender: TObject);
begin
 if btnKeyMic.IsPressed then begin
  if VoiceStart then SetVoiceOn(True) else begin
   btnKeyMic.IsPressed := False;
   SetVoiceOn(False);
  end;
 end else begin
  if FDownload <> nil then begin
   (FDownload as IVoskModelDownload).Cancel;
   FDownload := nil;
   btnKeyMic.Text := #$D83C#$DFA4;
  end;
  VoiceStop;
  SetVoiceOn(False);
 end;
 FocusMainForm;
end;

// фраза: команда или число - в активную кнопку (как ввод с клавиатуры)
// команда - первое слово-команда фразы (распознаватель может вернуть ее вместе
// с другими словами: «стереть стереть», «стереть пять»)
procedure TInstAccuDrawFrame.VoiceResult(const Text: String);
var T, N, W, Cmd: String;
begin
 T := Trim(AnsiLowerCase(Text));
 WriteIn(['Голос: «', T, '»']);
 if T = '' then exit;
 Cmd := '';
 for W in T.Split([' '], TStringSplitOptions.ExcludeEmpty) do
  if MatchStr(W, VoiceCommands) then begin
   Cmd := W;
   break;
  end;
 if Cmd = 'ввод' then DoEnter else
 if Cmd = 'назад' then begin
  if Assigned(OnUndoPoint) then OnUndoPoint(Self);
 end else
 if Cmd = 'сброс' then begin
  if Assigned(OnClearSnaps) then OnClearSnaps(Self);
 end else
 if (Cmd = 'стереть') or (Cmd = 'очистить') or (Cmd = 'удалить') then begin
  if FActiveEditButton <> nil then begin
   FActiveEditButton.Text := '';
   if Assigned(OnChange) then OnChange(FActiveEditButton);
  end;
 end else begin
  N := SpokenToNumber(T);
  if (N = '') or (FActiveEditButton = nil) then exit;
  FActiveEditButton.Text := N;
  FActiveEditButton.IsPressed := True;
  if Assigned(OnChange) then OnChange(FActiveEditButton);
 end;
end;

procedure TInstAccuDrawFrame.DoEnter;
begin
 if (FActiveEditButton <> nil) and Assigned(OnEnter) then OnEnter(FActiveEditButton);
end;

// «←» - удаление последнего символа текста активной кнопки
procedure TInstAccuDrawFrame.KeyBackClick(Sender: TObject);
begin
 BackChar;
 FocusMainForm;
end;

procedure TInstAccuDrawFrame.BackChar;
var S: String;
begin
 if FActiveEditButton = nil then exit;
 S := FActiveEditButton.Text;
 if S = '' then exit;
 FActiveEditButton.Text := Copy(S, 1, Length(S) - 1);
 FActiveEditButton.IsPressed := True;
 if Assigned(OnChange) then OnChange(FActiveEditButton);
end;

function TInstAccuDrawFrame.ControlByName(const CName: String): TControl;
begin
 if not FControls.TryGetValue(CName, Result) then Result := nil;
end;

procedure TInstAccuDrawFrame.SetItems(const CName: String; const Items: array of String);
var C: TControl;
    S: String;
begin
 C := ControlByName(CName);
 if not (C is TComboBox) then exit;
 TComboBox(C).BeginUpdate;
 try
  TComboBox(C).Items.Clear;
  for S in Items do TComboBox(C).Items.Add(S);
 finally
  TComboBox(C).EndUpdate;
 end;
end;

function TInstAccuDrawFrame.NameOf(Ctrl: TObject): String;
var P: TPair<String, TControl>;
begin
 Result := '';
 for P in FControls do
  if P.Value = Ctrl then exit(P.Key);
end;

function TInstAccuDrawFrame.FloatValue(const CName: String; out V: Double): Boolean;
begin
 Result := TryStrToFloat(StringReplace(Trim(GetValue(CName)), ',', '.', []), V, TFormatSettings.Invariant);
end;

// TButton - текст; флажок, переключатель - 'True' отмечает; список - строка
procedure TInstAccuDrawFrame.SetValue(const CName, Value: String);
var C: TControl;
begin
 C := ControlByName(CName);
 if C = nil then exit;
 if C is TComboBox then TComboBox(C).ItemIndex := TComboBox(C).Items.IndexOf(Value) else
 if C is TCheckBox then TCheckBox(C).IsChecked := SameText(Value, 'True') else
 if C is TRadioButton then TRadioButton(C).IsChecked := SameText(Value, 'True') else
 if C is TPresentedTextControl then TPresentedTextControl(C).Text := Value;
end;

function TInstAccuDrawFrame.GetValue(const CName: String): String;
var C: TControl;
begin
 Result := '';
 C := ControlByName(CName);
 if C = nil then exit;
 if C is TComboBox then begin
  if TComboBox(C).ItemIndex >= 0 then Result := TComboBox(C).Items[TComboBox(C).ItemIndex];
 end else
 if C is TCheckBox then Result := BoolToStr(TCheckBox(C).IsChecked, True) else
 if C is TRadioButton then Result := BoolToStr(TRadioButton(C).IsChecked, True) else
 if C is TPresentedTextControl then Result := TPresentedTextControl(C).Text;
end;

// ряды полной клавиатуры: буквы и знаки; служебные клавиши - по Tag, у букв
// Tag = 0, символ - в TagString
const
  KeyShift = 1;
  KeyLang = 2;
  KeySpace = 3;
  KeyBack = 4;
  KeyEnter = 5;
  RusRows: array[0..3] of String = ('1234567890-', 'йцукенгшщзхъ', 'фывапролджэё', 'ячсмитьбю.,');
  LatRows: array[0..3] of String = ('1234567890-', 'qwertyuiop', 'asdfghjkl', 'zxcvbnm.,');

// клавиши обеих раскладок (видна одна): ряд 0 - цифры и «←», ряд 3 - «⇧» и
// буквы, ряд 4 - раскладка, пробел, «⏎»
procedure TInstAccuDrawFrame.BuildFullKeys;
var Lat: Boolean;
    R: Integer;
    Ch: Char;
    Row: TArray<TButton>;
function AddKey(const Caption: String; KeyTag: Integer; Units: Single): TButton;
begin
 Result := TButton.Create(Self);
 Result.Parent := FFullKeys;
 Result.CanFocus := False;
 Result.Text := Caption;
 Result.TextSettings.Trimming := TTextTrimming.None;
 Result.Tag := KeyTag;
 Result.TagFloat := Units;
 Result.OnClick := FullKeyClick;
 UISetRule(Result, 'ui:android:font-1');
 Row := Row + [Result];
end;
begin
 FFullKeys := TLayout.Create(Self);
 FFullKeys.Parent := Self;
 FFullKeys.Align := TAlignLayout.Bottom;
 FFullKeys.Height := 5 * FullKeyHeight + 4;
 FFullKeys.Visible := False;
 FFullKeys.OnResize := FullKeysResize;
 for Lat := False to True do begin
  FKeyRows[Lat] := nil;
  for R := 0 to 4 do begin
   Row := nil;
   if R = 3 then AddKey(#$21E7, KeyShift, 1);
   if R < 4 then
    for Ch in IfThen(Lat, LatRows[R], RusRows[R]) do AddKey(Ch, 0, 1).TagString := Ch;
   if R = 0 then AddKey(#$2190, KeyBack, 1);
   if R = 4 then begin
    AddKey(IfThen(Lat, 'RU', 'EN'), KeyLang, 2);
    AddKey('', KeySpace, 7);
    AddKey(#$23CE, KeyEnter, 3);
   end;
   FKeyRows[Lat] := FKeyRows[Lat] + [Row];
  end;
 end;
end;

// видна текущая раскладка, буквы - по Shift
procedure TInstAccuDrawFrame.UpdateFullKeys;
var Lat: Boolean;
    Row: TArray<TButton>;
    B: TButton;
begin
 for Lat := False to True do
  for Row in FKeyRows[Lat] do
   for B in Row do begin
    B.Visible := Lat = FLatin;
    if B.Tag = 0 then
     if FShift then B.Text := AnsiUpperCase(B.TagString) else B.Text := B.TagString;
    if B.Tag = KeyShift then B.IsPressed := FShift;
   end;
 FullKeysResize(nil);
end;

// ряды по ширине панели: клавиша - 1/12 ширины (служебные - TagFloat долей),
// ряд по центру
procedure TInstAccuDrawFrame.FullKeysResize(Sender: TObject);
var Row: TArray<TButton>;
    B: TButton;
    W, X, Y, Units: Single;
begin
 if FFullKeys = nil then exit;
 W := (FFullKeys.Width - 4) / FullKeyCols;
 if W <= 0 then exit;
 Y := 2;
 for Row in FKeyRows[FLatin] do begin
  Units := 0;
  for B in Row do Units := Units + B.TagFloat;
  X := 2 + (FullKeyCols - Units) * W / 2;
  for B in Row do begin
   B.SetBounds(X + 1, Y + 1, B.TagFloat * W - 2, FullKeyHeight - 2);
   X := X + B.TagFloat * W;
  end;
  Y := Y + FullKeyHeight;
 end;
end;

procedure TInstAccuDrawFrame.FullKeyClick(Sender: TObject);
var B: TButton;
begin
 B := TButton(Sender);
 case B.Tag of
  KeyShift: begin
    FShift := not FShift;
    UpdateFullKeys;
   end;
  KeyLang: begin
    FLatin := not FLatin;
    FShift := False;
    UpdateFullKeys;
   end;
  KeySpace: AddChar(' ');
  KeyBack: BackChar;
  KeyEnter: DoEnter;
 else
  if B.Text <> '' then AddChar(B.Text[1]);
 // заглавная - одна буква
  if FShift then begin
   FShift := False;
   UpdateFullKeys;
  end;
 end;
 FocusMainForm;
end;

// полная клавиатура - под элементами на всю ширину панели, цифровая скрыта
procedure TInstAccuDrawFrame.SetFullKeyboard(const Value: Boolean);
begin
 if FFullKeyboard = Value then exit;
 if not FFullKeyboard then FBaseHeight := Height;
 FFullKeyboard := Value;
 if Value and (FFullKeys = nil) then BuildFullKeys;
 if FFullKeys <> nil then FFullKeys.Visible := Value;
 pnlKeys.Visible := not Value;
 if Value then Height := FBaseHeight + FFullKeys.Height else Height := FBaseHeight;
 PlaceAboveStatusBar;
 if Value then UpdateFullKeys;
end;

end.
