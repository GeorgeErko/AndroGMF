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
// контейнера. Правила групп - таблица UIRuleTable (константы в начале
// реализации): высота (метрика UI), квадратная кнопка без текста, глиф
// (по центру, на всю кнопку с отступом GlyphMargin, на всю кнопку без
// растяжения), шрифт текста (мелкий, обычный). 'ui:skip' - кнопку не трогать.
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
     FMX.StdCtrls, FMX.Platform, FMX.Graphics, FMX.ImgList, System.IOUtils, System.IniFiles;

const
  Profiles: array[TUIProfile] of TUIMetrics = (
  // мышь (Windows)
   (FontSize: 12; SmallFontSize: 11; TitleFontSize: 14; ListFontSize: 13;
    ButtonHeight: 22; ToolButtonSize: 26; StatusButtonSize: 21;
    ToolBarHeight: 30; StatusBarHeight: 23; ItemHeight: 20;
    GlyphMargin: 2; Spacing: 4; TouchExpansion: 0),
  // перо: размеры Windows, зона касания чуть шире
   (FontSize: 12; SmallFontSize: 11; TitleFontSize: 14; ListFontSize: 12;
    ButtonHeight: 22; ToolButtonSize: 26; StatusButtonSize: 21;
    ToolBarHeight: 30; StatusBarHeight: 23; ItemHeight: 22;
    GlyphMargin: 2; Spacing: 4; TouchExpansion: 4),
  // палец: крупнее, зона касания заметно шире видимой кнопки
   (FontSize: 13; SmallFontSize: 12; TitleFontSize: 15; ListFontSize: 14;
    ButtonHeight: 28; ToolButtonSize: 32; StatusButtonSize: 26;
    ToolBarHeight: 36; StatusBarHeight: 28; ItemHeight: 28;
    GlyphMargin: 3; Spacing: 6; TouchExpansion: 8));

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
  UIRuleTable: array[0..12] of TUIRuleItem = (
   (Name: 'button'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'tool'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'status'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utSmall; Skip: False)),
   (Name: 'toolsize'; Rule: (Height: usTool; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'statussize'; Rule: (Height: usStatus; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'center'; Rule: (Height: usKeep; Square: False; Glyph: ugCenter; Text: utKeep; Skip: False)),
   (Name: 'fill'; Rule: (Height: usKeep; Square: False; Glyph: ugFill; Text: utKeep; Skip: False)),
   (Name: 'client'; Rule: (Height: usKeep; Square: False; Glyph: ugClient; Text: utKeep; Skip: False)),
   (Name: 'small'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utSmall; Skip: False)),
   (Name: 'normal'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utNormal; Skip: False)),
   (Name: 'square'; Rule: (Height: usKeep; Square: True; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'btn'; Rule: (Height: usButton; Square: False; Glyph: ugKeep; Text: utKeep; Skip: False)),
   (Name: 'skip'; Rule: (Height: usKeep; Square: False; Glyph: ugKeep; Text: utKeep; Skip: True)));

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
end;

function UIButtonRule(Button: TObject): TUIRule;
var P: TFmxObject;
    Group, W: String;
    S: TUIRule;
begin
 FillChar(Result, SizeOf(Result), 0);
 if not (Button is TControl) then exit;
 Group := 'button';
 P := TFmxObject(Button).Parent;
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
 for W in TControl(Button).HelpKeyword.Split([' ', ',', ';'], TStringSplitOptions.ExcludeEmpty) do
  if W.StartsWith(UIPrefix, True) and FindRule(W.Substring(Length(UIPrefix)), S) then MergeRule(Result, S);
end;

procedure UIApplyButtonStyle(Sender: TObject);
var R: TUIRule;
    G: TFmxObject;
    M: Single;
begin
 if not (Sender is TCustomButton) then exit;
 R := UIButtonRule(Sender);
 if R.Skip or (R.Glyph = ugKeep) then exit;
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
 case R.Text of
  utSmall: begin
    B.StyledSettings := B.StyledSettings - [TStyledSetting.Size];
    B.TextSettings.Font.Size := UI.Metrics.SmallFontSize;
   end;
  utNormal: begin
    B.StyledSettings := B.StyledSettings - [TStyledSetting.Size];
    B.TextSettings.Font.Size := UI.Metrics.FontSize;
   end;
 end;
end;

type
  TStyledControlAccess = class(TStyledControl);
  TControlAccess = class(TControl);

  TUIHandler = class
    class procedure ApplyStyleLookup(Sender: TObject);
  end;

// стиль применен: закрепленная стилем высота (AdjustFixedSize, FixedHeight)
// снимается, выравнивание родителя пересчитывается; у кнопки - глиф по правилу
class procedure TUIHandler.ApplyStyleLookup(Sender: TObject);
begin
 if not (Sender is TStyledControl) then exit;
 if TStyledControl(Sender).AdjustType <> TAdjustType.None then begin
  TStyledControlAccess(Sender).SetAdjustType(TAdjustType.None);
  if TControl(Sender).ParentControl <> nil then TControlAccess(TControl(Sender).ParentControl).Realign;
 end;
 UIApplyButtonStyle(Sender);
end;

procedure ApplyUIRules(Root: TObject);
var I: Integer;
    C: TFmxObject;
    R: TUIRule;
begin
 if not (Root is TFmxObject) then exit;
 for I := 0 to TFmxObject(Root).ChildrenCount - 1 do begin
  C := TFmxObject(Root).Children[I];
  if (C is TCustomButton) or (C is TToolBar) or (C is TStatusBar) then begin
   if C is TCustomButton then begin
    R := UIButtonRule(C);
    if not R.Skip then ApplyButtonRule(TCustomButton(C), R);
   end;
  // свой обработчик кнопки не заменяется - он вызывает UIApplyButtonStyle сам
   if not Assigned(TStyledControl(C).OnApplyStyleLookup) then TStyledControl(C).OnApplyStyleLookup := TUIHandler.ApplyStyleLookup;
   TUIHandler.ApplyStyleLookup(C);
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
 FreeAndNil(UI);
end.
