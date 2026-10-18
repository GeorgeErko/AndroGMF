unit AppUI;

// Единый источник размеров интерфейса (бывший AppFonts).
// Размеры - в логических точках FMX (на Android - примерно dp), собраны в
// профили по способу ввода:
//  uiMouse - Windows, мышь;
//  uiPen - Android, перо (S-Pen): мелкие кнопки и шрифт, как на Windows;
//  uiFinger - Android, палец: кнопки и строки крупнее.
// Метрики профиля умножаются на общий масштаб (Scale, 0.5..2) - один параметр
// делает весь интерфейс крупнее или мельче. Глобальный объект UI: UI.Metrics -
// текущие размеры, смена профиля или масштаба рассылает TUIMetricsChangedMessage
// (TMessageManager.DefaultManager) - формы и фреймы применяют размеры заново.
// Шрифт по умолчанию всех элементов (Size в StyledSettings) - служба
// IFMXSystemFontService подменяется своей (UI.Metrics.FontSize); модуль должен
// стоять в uses .dpr до модулей с формами.
// Высоты кнопок, тулбаров и строки состояния не навязываются стилем платформы
// (FixedHeight: Android 48): UnfixButtonHeights, UnfixFormButtonHeights,
// ApplyUIRules; ApplyUIRules применяет и правила кнопок (группы, пометки 'ui:').

interface

uses System.Classes, System.UITypes, System.Messaging;

type
  TUIProfile = (uiMouse, uiPen, uiFinger);

  TUIMetrics = record
    FontSize: Single;          // шрифт по умолчанию
    SmallFontSize: Single;     // подписи, строка состояния
    TitleFontSize: Single;     // заголовки панелей
    ListFontSize: Single;      // имена слоев в таблице слоев
    ButtonHeight: Single;      // TButton, TSpeedButton в панелях и диалогах
    ToolButtonSize: Single;    // кнопки тулбаров (квадратные)
    StatusButtonSize: Single;  // кнопки строки состояния
    ToolBarHeight: Single;
    StatusBarHeight: Single;
    ItemHeight: Single;        // строка списков и деревьев
    GlyphMargin: Single;       // отступ картинки от края кнопки
    Spacing: Single;           // интервал между элементами
    TouchExpansion: Single;    // расширение зоны касания за видимые границы
    CheckSize: Single;         // квадратик TCheckBox / кружок TRadioButton (ui:check)
    TitleHeight: Single;       // заголовок окна диалога на Android (AppForms.ShowDialog)
  end;

  TUIMetricsChangedMessage = class(TMessage);

  TAppUI = class
  private
    FProfile: TUIProfile;
    FScale: Single;
    FMetrics: TUIMetrics;
    procedure Recalc;
    procedure SetProfile(const Value: TUIProfile);
    procedure SetScale(const Value: Single);
  public
   // фон и рамка непрозрачных панелей (фреймы-диалоги поверх карты)
    PanelColor: TAlphaColor;
    PanelBorderColor: TAlphaColor;
    constructor Create;
   // размеры профиля без масштаба
    class function ProfileMetrics(P: TUIProfile): TUIMetrics; static;
   // масштаб - в AppUI.ini (Android - каталог документов, Windows - каталог
   // программы): свой файл, т.к. читается до создания форм (шрифт по
   // умолчанию), когда путь общих настроек (newProcs.MainPath) еще не задан
    class function SettingsFile: String; static;
    procedure LoadSettings;
    procedure SaveSettings;
    property Profile: TUIProfile read FProfile write SetProfile;
    property Scale: Single read FScale write SetScale;
   // размеры с учетом масштаба
    property Metrics: TUIMetrics read FMetrics;
  end;

var
  UI: TAppUI;

// стиль платформы: у speedbuttonstyle, toolbarstyle и statusbarstyle
// снимается FixedHeight - кнопки, тулбары и строка состояния получают высоту
// из формы (Height). Вызов - в .dpr после Application.Initialize, до создания
// форм: элементы берут стиль из исправленного образца
procedure UnfixButtonHeights;
// то же в стилях формы: элементы ищут образец сначала в StyleBook формы, затем
// в стиле ее сцены, и только потом в общем - там своя копия speedbuttonstyle
// (FixedHeight 48). Вызов - в Loaded формы, до первой отрисовки
procedure UnfixFormButtonHeights(Form: TObject);
// Правила кнопок (TButton, TSpeedButton, TCornerButton - все TCustomButton).
// Группа кнопки: по контейнеру - в TStatusBar 'status', в TToolBar 'tool',
// иначе 'button'; затем пометки в HelpKeyword (справка в программе не
// используется; TagString в FMX не публикуется и в fmx не сохраняется) -
// слова с префиксом 'ui:'
// (например 'ui:center ui:small'), применяются по порядку поверх группы
// контейнера; с платформой - только на ней: 'ui:android:font-2',
// 'ui:win:font-1' (без платформы - везде). Правила групп - таблица UIRuleTable (константы в начале
// реализации): высота (метрика UI), квадратная кнопка без текста, глиф
// (по центру, на всю кнопку с отступом GlyphMargin, на всю кнопку без
// растяжения), шрифт текста (мелкий, обычный, обычный +-N: ui:font-2).
// 'ui:skip' - кнопку не трогать.
// Остальные элементы (TEdit, TLabel, TCheckBox и т.п., TListView) - только по
// пометкам 'ui:' (без групп контейнеров): шрифт; TListView с ui:list - шрифт
// текста строк и высота строки по шрифту; TCheckBox / TRadioButton с ui:check
// (ui:android:check) - квадратик (кружок) размером CheckSize профиля.
// Зона касания всех кнопок расширяется на TouchExpansion.
// Глиф и текст стиля меняются после каждого применения стиля
// (OnApplyStyleLookup). У кнопки со своим OnApplyStyleLookup он не заменяется:
// обработчик кнопки сам вызывает UIApplyButtonStyle(Sender)
type
  TUISize = (usKeep, usButton, usTool, usStatus);
  TUIGlyph = (ugKeep, ugCenter, ugFill, ugClient);
  TUIText = (utKeep, utSmall, utNormal);

  TUIRule = record
    Height: TUISize;           // высота - метрика UI
    Square: Boolean;           // без текста: ширина = высоте
    Glyph: TUIGlyph;           // ugFill - Align Client, отступ GlyphMargin, растяжение;
                               // ugClient - Align Client без растяжения
    Text: TUIText;
    Skip: Boolean;             // не трогать кнопку
    FontDelta: Integer;        // шрифт = обычный (FontSize) + FontDelta; 0 - не меняется
    List: Boolean;             // TListView: шрифт строки и высота строки по шрифту
    Check: Boolean;            // TCheckBox / TRadioButton: квадратик (кружок) - CheckSize
  end;

// размеры, правила кнопок, снятие закрепленных стилем высот - у всех элементов
// Root (форма, фрейм, панель); повторный вызов - по новым размерам UI.
// Вызов - в Loaded формы/фрейма (AppForms) и после создания элементов кодом
procedure ApplyUIRules(Root: TObject);
// правило кнопки: группа контейнера и пометки 'ui:' в HelpKeyword
function UIButtonRule(Button: TObject): TUIRule;
// глиф и текст стиля кнопки по ее правилу (для своих OnApplyStyleLookup)
procedure UIApplyButtonStyle(Sender: TObject);

implementation

uses System.SysUtils, System.Types, System.Math, FMX.Types, FMX.Controls, FMX.Styles, FMX.Forms,
     FMX.StdCtrls, FMX.Platform, FMX.Graphics, FMX.ImgList, System.IOUtils, System.IniFiles,
     FMX.ListView, FMX.ListView.Appearances, FMX.ListView.Types, System.Generics.Collections,
     FMX.Styles.Objects, Writer;

const
  Profiles: array[TUIProfile] of TUIMetrics = (
  // мышь (Windows)
   (FontSize: 12; SmallFontSize: 11; TitleFontSize: 14; ListFontSize: 13;
    ButtonHeight: 22; ToolButtonSize: 26; StatusButtonSize: 21;
    ToolBarHeight: 30; StatusBarHeight: 23; ItemHeight: 20;
    GlyphMargin: 2; Spacing: 4; TouchExpansion: 0; CheckSize: 16; TitleHeight: 24),
  // перо: размеры Windows, зона касания чуть шире
   (FontSize: 12; SmallFontSize: 11; TitleFontSize: 14; ListFontSize: 12;
    ButtonHeight: 22; ToolButtonSize: 26; StatusButtonSize: 21;
    ToolBarHeight: 30; StatusBarHeight: 23; ItemHeight: 22;
    GlyphMargin: 2; Spacing: 4; TouchExpansion: 4; CheckSize: 16; TitleHeight: 26),
  // палец: крупнее, зона касания заметно шире видимой кнопки
   (FontSize: 13; SmallFontSize: 12; TitleFontSize: 15; ListFontSize: 14;
    ButtonHeight: 28; ToolButtonSize: 32; StatusButtonSize: 26;
    ToolBarHeight: 36; StatusBarHeight: 28; ItemHeight: 28;
    GlyphMargin: 3; Spacing: 6; TouchExpansion: 8; CheckSize: 20; TitleHeight: 32));

type
  TUIRuleItem = record
    Name: String;
    Rule: TUIRule;
  end;

const
  UIPrefix = 'ui:';
 // правила групп кнопок: группы контейнеров (button, tool, status) и пометки
 // HelpKeyword ('ui:center' и т.д.); поле Keep/False - не меняется. Группы
 // контейнеров размеры не меняют (кнопки тулбаров разные: 25x48 с Align,
 // 35x40 в MainFrmDendro, стрелки UpDown 16x20) - размер включается пометкой
 // ui:toolsize / ui:statussize / ui:btn
  UIRuleTable: array[0..18] of TUIRuleItem = (
   (Name: 'button'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'tool'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'status'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utSmall; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'toolsize'; Rule: (Height: usTool; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'statussize'; Rule: (Height: usStatus; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'center'; Rule: (Height: usKeep; Square: False; Glyph: ugCenter; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'fill'; Rule: (Height: usKeep; Square: False; Glyph: ugFill; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'client'; Rule: (Height: usKeep; Square: False; Glyph: ugClient; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'small'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utSmall; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'normal'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utNormal; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'square'; Rule: (Height: usKeep; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'btn'; Rule: (Height: usButton; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: False)),
   (Name: 'skip'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: True; FontDelta: 0; List: False; Check: False)),
   (Name: 'font-2'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: -2; List: False; Check: False)),
   (Name: 'font-1'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: -1; List: False; Check: False)),
   (Name: 'font+1'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 1; List: False; Check: False)),
   (Name: 'font+2'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 2; List: False; Check: False)),
   (Name: 'list'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: True; Check: False)),
   (Name: 'check'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False; FontDelta: 0; List: False; Check: True)));

{ TAppUI }

constructor TAppUI.Create;
begin
 inherited Create;
{$IFDEF ANDROID}
 FProfile := uiPen;
{$ELSE}
 FProfile := uiMouse;
{$ENDIF}
 FScale := 1;
 PanelColor := $FFF0F0F0;
 PanelBorderColor := $FFB4B4B4;
 Recalc;
end;

class function TAppUI.ProfileMetrics(P: TUIProfile): TUIMetrics;
begin
 Result := Profiles[P];
end;

class function TAppUI.SettingsFile: String;
begin
{$IFDEF ANDROID}
 Result := TPath.Combine(TPath.GetDocumentsPath, 'AppUI.ini');
{$ELSE}
 Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'AppUI.ini');
{$ENDIF}
end;

// без рассылки: вызывается при запуске, до создания форм
procedure TAppUI.LoadSettings;
var Ini: TIniFile;
begin
 try
  Ini := TIniFile.Create(SettingsFile);
  try
   FScale := EnsureRange(Ini.ReadFloat('UI', 'Scale', 1), 0.5, 2);
  finally
   Ini.Free;
  end;
 except
  FScale := 1;
 end;
 Recalc;
end;

procedure TAppUI.SaveSettings;
var Ini: TIniFile;
begin
 try
  Ini := TIniFile.Create(SettingsFile);
  try
   Ini.WriteFloat('UI', 'Scale', FScale);
  finally
   Ini.Free;
  end;
 except
 end;
end;

procedure TAppUI.Recalc;
var M: TUIMetrics;
begin
 M := Profiles[FProfile];
 FMetrics.FontSize := Round(M.FontSize * FScale);
 FMetrics.SmallFontSize := Round(M.SmallFontSize * FScale);
 FMetrics.TitleFontSize := Round(M.TitleFontSize * FScale);
 FMetrics.ListFontSize := Round(M.ListFontSize * FScale);
 FMetrics.ButtonHeight := Round(M.ButtonHeight * FScale);
 FMetrics.ToolButtonSize := Round(M.ToolButtonSize * FScale);
 FMetrics.StatusButtonSize := Round(M.StatusButtonSize * FScale);
 FMetrics.ToolBarHeight := Round(M.ToolBarHeight * FScale);
 FMetrics.StatusBarHeight := Round(M.StatusBarHeight * FScale);
 FMetrics.ItemHeight := Round(M.ItemHeight * FScale);
 FMetrics.GlyphMargin := Round(M.GlyphMargin * FScale);
 FMetrics.Spacing := Round(M.Spacing * FScale);
 FMetrics.TouchExpansion := Round(M.TouchExpansion * FScale);
 FMetrics.CheckSize := Round(M.CheckSize * FScale);
 FMetrics.TitleHeight := Round(M.TitleHeight * FScale);
end;

procedure TAppUI.SetProfile(const Value: TUIProfile);
begin
 if FProfile = Value then exit;
 FProfile := Value;
 Recalc;
 TMessageManager.DefaultManager.SendMessage(Self, TUIMetricsChangedMessage.Create);
end;

procedure TAppUI.SetScale(const Value: Single);
var V: Single;
begin
 V := EnsureRange(Value, 0.5, 2);
 if SameValue(FScale, V) then exit;
 FScale := V;
 Recalc;
 TMessageManager.DefaultManager.SendMessage(Self, TUIMetricsChangedMessage.Create);
end;

{ высоты из стиля платформы }

procedure UnfixStyle(S: TFmxObject);
const Names: array[0..2] of String = ('speedbuttonstyle', 'toolbarstyle', 'statusbarstyle');
var R: TFmxObject;
    N: String;
begin
 if S = nil then exit;
 for N in Names do begin
  R := S.FindStyleResource(N);
  if R is TControl then TControl(R).FixedSize := TSize.Create(0, 0);
 end;
end;

procedure UnfixButtonHeights;
begin
 UnfixStyle(TStyleManager.ActiveStyle(nil));
end;

procedure UnfixFormButtonHeights(Form: TObject);
var F: TCustomForm;
    Scene: IScene;
begin
 if not (Form is TCustomForm) then exit;
 F := TCustomForm(Form);
 if F.StyleBook <> nil then UnfixStyle(F.StyleBook.Style);
 if Supports(F, IScene, Scene) then UnfixStyle(TStyleManager.ActiveStyleForScene(Scene));
end;

{ правила кнопок }

function FindRule(const Name: String; out Rule: TUIRule): Boolean;
var I: Integer;
begin
 for I := Low(UIRuleTable) to High(UIRuleTable) do
  if SameText(UIRuleTable[I].Name, Name) then begin
   Rule := UIRuleTable[I].Rule;
   exit(True);
  end;
 Result := False;
end;

// поля S, отличные от Keep/False, - поверх R
procedure MergeRule(var R: TUIRule; const S: TUIRule);
begin
 if S.Height <> usKeep then R.Height := S.Height;
 if S.Square then R.Square := True;
 if S.Glyph <> ugKeep then R.Glyph := S.Glyph;
 if S.Text <> utKeep then R.Text := S.Text;
 if S.Skip then R.Skip := True;
 if S.FontDelta <> 0 then R.FontDelta := S.FontDelta;
 if S.List then R.List := True;
 if S.Check then R.Check := True;
end;

// пометка с платформой: 'android:имя' - только на Android, 'win:имя' - только
// на Windows; без платформы - везде. False - пометка не для этой платформы
function PlatformRuleName(const Tag: String; out Name: String): Boolean;
const Platforms: array[0..1] of String = ('android:', 'win:');
{$IFDEF ANDROID}
      Current = 'android:';
{$ELSE}
      Current = 'win:';
{$ENDIF}
var P: String;
begin
 Name := Tag;
 for P in Platforms do
  if Tag.StartsWith(P, True) then begin
   Name := Tag.Substring(Length(P));
   exit(SameText(P, Current));
  end;
 Result := True;
end;

// группа контейнера (только кнопки) и пометки 'ui:' в HelpKeyword
function UIControlRule(Ctrl: TObject; UseContainer: Boolean): TUIRule;
var P: TFmxObject;
    Group, W: String;
    S: TUIRule;
begin
 FillChar(Result, SizeOf(Result), 0);
 if not (Ctrl is TStyledControl) then exit;
 if UseContainer then begin
  Group := 'button';
  P := TFmxObject(Ctrl).Parent;
  while (P <> nil) and not (P is TCommonCustomForm) do begin
   if P is TStatusBar then begin
    Group := 'status';
    break;
   end;
   if P is TToolBar then begin
    Group := 'tool';
    break;
   end;
   P := P.Parent;
  end;
  if FindRule(Group, S) then MergeRule(Result, S);
 end;
 for W in TStyledControl(Ctrl).HelpKeyword.Split([' ', ',', ';'], TStringSplitOptions.ExcludeEmpty) do
  if W.StartsWith(UIPrefix, True) and PlatformRuleName(W.Substring(Length(UIPrefix)), Group) and FindRule(Group, S) then
   MergeRule(Result, S);
end;

function UIButtonRule(Button: TObject): TUIRule;
begin
 Result := UIControlRule(Button, True);
end;

// Базовые размеры элементов: шрифт, полученный от стиля (у TListView - шрифт
// строки из ресурсов стиля списка), и исходная высота строки списка.
// Запоминаются один раз, после первого применения стиля: потом размер
// шрифта задан явно, и стиль его уже не дает. ui:font-N считается от базы
// (стиль Android крупнее 12), высота строки - пропорционально шрифту.
// Запись удаляется при уничтожении элемента (FreeNotification)
type
  TUIBase = record
    Font: Single;
    Row: Single;
  end;

  TUIBaseStore = class(TComponent)
  private
    FItems: TDictionary<TComponent, TUIBase>;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TryGet(C: TComponent; out B: TUIBase): Boolean;
    procedure Put(C: TComponent; const B: TUIBase);
  end;

var
  GBase: TUIBaseStore;

constructor TUIBaseStore.Create(AOwner: TComponent);
begin
 inherited;
 FItems := TDictionary<TComponent, TUIBase>.Create;
end;

destructor TUIBaseStore.Destroy;
var C: TComponent;
begin
 for C in FItems.Keys do C.RemoveFreeNotification(Self);
 FItems.Free;
 inherited;
end;

procedure TUIBaseStore.Notification(AComponent: TComponent; Operation: TOperation);
begin
 inherited;
 if (Operation = opRemove) and (FItems <> nil) then FItems.Remove(AComponent);
end;

function TUIBaseStore.TryGet(C: TComponent; out B: TUIBase): Boolean;
begin
 Result := FItems.TryGetValue(C, B);
end;

procedure TUIBaseStore.Put(C: TComponent; const B: TUIBase);
begin
 if not FItems.ContainsKey(C) then C.FreeNotification(Self);
 FItems.AddOrSetValue(C, B);
end;

function BaseStore: TUIBaseStore;
begin
 if GBase = nil then GBase := TUIBaseStore.Create(nil);
 Result := GBase;
end;

type
  TListViewAccess = class(TListView);

// размер шрифта по правилу от базового Base; False - не меняется.
// ui:font-N - от шрифта стиля с учетом масштаба; ui:small/normal - метрики UI
function RuleFontSize(const R: TUIRule; Base: Single; out Size: Single): Boolean;
begin
 Result := True;
 if R.FontDelta <> 0 then Size := Max(Single(6), Single(Round(Base * UI.Scale) + R.FontDelta)) else
 if R.Text = utSmall then Size := UI.Metrics.SmallFontSize else
 if R.Text = utNormal then Size := UI.Metrics.FontSize else
  Result := False;
end;

// шрифт элемента с TextSettings (кнопка, поле ввода, надпись, флажок...).
// StyleReady - стиль применен (вызов из OnApplyStyleLookup): только тогда
// берется база для ui:font-N; до этого шрифт стиля еще не известен
procedure ApplyTextRule(const Ctrl: TObject; const R: TUIRule; StyleReady: Boolean);
var TS: ITextSettings;
    B: TUIBase;
    Size: Single;
begin
 if not Supports(Ctrl, ITextSettings, TS) or not (Ctrl is TComponent) then exit;
 if (R.FontDelta = 0) and (R.Text = utKeep) then exit;
 B.Font := 0;
 if R.FontDelta <> 0 then
  if not BaseStore.TryGet(TComponent(Ctrl), B) then begin
   if not StyleReady then exit;
   B.Font := TS.ResultingTextSettings.Font.Size;
   if B.Font <= 0 then B.Font := UI.Metrics.FontSize;
   B.Row := 0;
   BaseStore.Put(TComponent(Ctrl), B);
  end;
 if not RuleFontSize(R, B.Font, Size) then exit;
 TS.StyledSettings := TS.StyledSettings - [TStyledSetting.Size];
 TS.TextSettings.Font.Size := Size;
end;

// TListView (ui:list): шрифт текста строки (подробности - на 1 меньше) и
// высота строки - пропорционально шрифту от исходных шрифта стиля и высоты
procedure ApplyListRule(L: TListView; const R: TUIRule; StyleReady: Boolean);
var B: TUIBase;
    Size: Single;
    O: TItemAppearanceObjects;
    F: TFont;
begin
 if not R.List then exit;
 if not BaseStore.TryGet(L, B) then begin
  if not StyleReady then exit;
  F := TListViewAccess(L).GetStyleResources.DefaultTextFont;
  if F <> nil then B.Font := F.Size else B.Font := 0;
  if B.Font <= 0 then B.Font := UI.Metrics.FontSize;
  B.Row := L.ItemAppearance.ItemHeight;
  BaseStore.Put(L, B);
 end;
 if not RuleFontSize(R, B.Font, Size) then Size := Round(B.Font * UI.Scale);
 O := L.ItemAppearanceObjects.ItemObjects;
 if O <> nil then begin
  if O.Text <> nil then O.Text.Font.Size := Size;
  if O.Detail <> nil then O.Detail.Font.Size := Max(Single(6), Size - 1);
 end;
 if B.Row > 0 then L.ItemAppearance.ItemHeight := Max(16, Round(B.Row * Size / B.Font));
end;

// квадратик флажка (кружок переключателя) в стиле элемента: имен FMX не задает
// (у стилей Windows и Android разные) - первый объект-картинка стиля
// (TCustomStyleObject), выровненный влево/вправо или без выравнивания, не
// шире 48: фон всего элемента выровнен по всей площади и не подходит
function FindCheckBox(Root: TFmxObject): TControl;
var I: Integer;
    C: TFmxObject;
begin
 Result := nil;
 for I := 0 to Root.ChildrenCount - 1 do begin
  C := Root.Children[I];
  if (C is TCustomStyleObject) and (TControl(C).Width <= 48) and
     (TControl(C).Align in [TAlignLayout.None, TAlignLayout.Left, TAlignLayout.Right, TAlignLayout.MostLeft, TAlignLayout.MostRight, TAlignLayout.Center]) then
   exit(TControl(C));
  Result := FindCheckBox(C);
  if Result <> nil then exit;
 end;
end;

// ui:check: квадратик (кружок) - CheckSize профиля, по высоте - по центру элемента
procedure ApplyCheckRule(Ctrl: TStyledControl; const R: TUIRule);
var Box: TControl;
    S, M: Single;
begin
 if not R.Check or not ((Ctrl is TCheckBox) or (Ctrl is TRadioButton)) then exit;
 Box := FindCheckBox(Ctrl);
 if Box = nil then begin
  WriteIn(['ui:check: в стиле ', Ctrl.ClassName, ' ', Ctrl.Name, ' квадратик не найден']);
  exit;
 end;
 S := UI.Metrics.CheckSize;
 M := Max(Single(0), (Ctrl.Height - S) / 2);
 Box.Width := S;
 if Box.Align = TAlignLayout.None then begin
  Box.Height := S;
  Box.Position.Y := M;
 end else
 if Box.Align <> TAlignLayout.Center then begin
  Box.Margins.Top := M;
  Box.Margins.Bottom := M;
 end else
  Box.Height := S;
end;

procedure UIApplyButtonStyle(Sender: TObject);
var R: TUIRule;
    G: TFmxObject;
    M: Single;
begin
 if not (Sender is TCustomButton) then exit;
 R := UIButtonRule(Sender);
 if R.Skip then exit;
 ApplyTextRule(Sender, R, True);
 if R.Glyph = ugKeep then exit;
 G := TCustomButton(Sender).FindStyleResource('glyphstyle');
 if not (G is TGlyph) then exit;
 case R.Glyph of
  ugCenter: TGlyph(G).Align := TAlignLayout.Center;
  ugFill: begin
    M := UI.Metrics.GlyphMargin;
    TGlyph(G).Align := TAlignLayout.Client;
    TGlyph(G).Margins.Rect := TRectF.Create(M, M, M, M);
    TGlyph(G).Stretch := True;
   end;
  ugClient: begin
    TGlyph(G).Align := TAlignLayout.Client;
    TGlyph(G).Stretch := False;
   end;
 end;
end;

// размеры, шрифт текста, зона касания кнопки - по правилу
procedure ApplyButtonRule(B: TCustomButton; const R: TUIRule);
var H, E: Single;
begin
 E := UI.Metrics.TouchExpansion;
 B.TouchTargetExpansion.Rect := TRectF.Create(E, E, E, E);
 case R.Height of
  usButton: H := UI.Metrics.ButtonHeight;
  usTool: H := UI.Metrics.ToolButtonSize;
  usStatus: H := UI.Metrics.StatusButtonSize;
 else
  H := 0;
 end;
 if H > 0 then begin
  B.Height := H;
  if R.Square and (B.Text = '') then B.Width := H;
 end;
 ApplyTextRule(B, R, False);
end;

type
  TStyledControlAccess = class(TStyledControl);
  TControlAccess = class(TControl);

  TUIHandler = class
    class procedure ApplyStyleLookup(Sender: TObject);
  end;

// StyleReady: вызов из OnApplyStyleLookup (стиль применен) или из обхода
procedure ApplyStyleRules(Sender: TObject; StyleReady: Boolean);
var R: TUIRule;
begin
 if not (Sender is TStyledControl) then exit;
 if TStyledControl(Sender).AdjustType <> TAdjustType.None then begin
  TStyledControlAccess(Sender).SetAdjustType(TAdjustType.None);
  if TControl(Sender).ParentControl <> nil then TControlAccess(TControl(Sender).ParentControl).Realign;
 end;
 if Sender is TCustomButton then begin
  if StyleReady then UIApplyButtonStyle(Sender);
  exit;
 end;
 if Pos(UIPrefix, LowerCase(TStyledControl(Sender).HelpKeyword)) = 0 then exit;
 R := UIControlRule(Sender, False);
 if R.Skip then exit;
 ApplyTextRule(Sender, R, StyleReady);
 if Sender is TListView then ApplyListRule(TListView(Sender), R, StyleReady);
// объекты стиля есть только после его применения
 if StyleReady then ApplyCheckRule(TStyledControl(Sender), R);
end;

// стиль применен: закрепленная стилем высота снимается, выравнивание
// родителя пересчитывается; глиф и шрифт - по правилу
class procedure TUIHandler.ApplyStyleLookup(Sender: TObject);
begin
 ApplyStyleRules(Sender, True);
end;

procedure ApplyUIRules(Root: TObject);
var I: Integer;
    C: TFmxObject;
    R: TUIRule;
    Hook: Boolean;
begin
 if not (Root is TFmxObject) then exit;
 for I := 0 to TFmxObject(Root).ChildrenCount - 1 do begin
  C := TFmxObject(Root).Children[I];
  Hook := (C is TCustomButton) or (C is TToolBar) or (C is TStatusBar) or
          ((C is TStyledControl) and (Pos(UIPrefix, LowerCase(TStyledControl(C).HelpKeyword)) > 0));
  if Hook then begin
   if C is TCustomButton then begin
    R := UIButtonRule(C);
    if not R.Skip then ApplyButtonRule(TCustomButton(C), R);
   end;
  // свой обработчик элемента не заменяется - он вызывает UIApplyButtonStyle сам
   if not Assigned(TStyledControl(C).OnApplyStyleLookup) then TStyledControl(C).OnApplyStyleLookup := TUIHandler.ApplyStyleLookup;
  // повторный вызов (смена масштаба): база уже известна - применяется сразу
   ApplyStyleRules(C, False);
  end;
  ApplyUIRules(C);
 end;
end;

{ шрифт по умолчанию }

// TFont запоминает службу при первом обращении к размеру по умолчанию, поэтому
// подмена - в initialization, до создания форм (Application.CreateForm).
// Семейство - системное (Android - Roboto, Windows - Segoe UI), размер - UI
type
  TAppFontService = class(TInterfacedObject, IFMXSystemFontService)
  private
   FOld: IFMXSystemFontService;
  public
   constructor Create(const AOld: IFMXSystemFontService);
   function GetDefaultFontFamilyName: string;
   function GetDefaultFontSize: Single;
  end;

constructor TAppFontService.Create(const AOld: IFMXSystemFontService);
begin
 inherited Create;
 FOld := AOld;
end;

function TAppFontService.GetDefaultFontFamilyName: string;
begin
 if FOld <> nil then Result := FOld.GetDefaultFontFamilyName else
{$IFDEF ANDROID}
  Result := 'Roboto';
{$ELSE}
  Result := 'Segoe UI';
{$ENDIF}
end;

// UI нет (завершение программы) - размер профиля
function TAppFontService.GetDefaultFontSize: Single;
begin
 if UI <> nil then Result := UI.Metrics.FontSize else Result := Profiles[uiMouse].FontSize;
end;

procedure InstallAppFontService;
var Old: IFMXSystemFontService;
begin
 Old := nil;
 if TPlatformServices.Current.SupportsPlatformService(IFMXSystemFontService, Old) then TPlatformServices.Current.RemovePlatformService(IFMXSystemFontService);
 TPlatformServices.Current.AddPlatformService(IFMXSystemFontService, TAppFontService.Create(Old));
end;

initialization
 UI := TAppUI.Create;
 UI.LoadSettings;
 InstallAppFontService;
finalization
 FreeAndNil(GBase);
 FreeAndNil(UI);
end.
