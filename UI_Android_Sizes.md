# Размеры элементов интерфейса Android / Windows

Состояние на 21.10.2026. Источник правил: `AppUI.pas`; пометки элементов — в
`HelpKeyword` (в .fmx или кодом).

## Как задаются уменьшения

- Пометка `ui:имя` в `HelpKeyword` действует везде, а `ui:android:имя` и
  `ui:win:имя` — только на своей платформе. В одном `HelpKeyword` может быть
  несколько пометок через пробел.
- **Шрифт** `ui:font-N` считается так: `Round(шрифт_стиля × UI.Scale) − N`, но
  не меньше 6. Шрифт стиля запоминается один раз, после первого применения
  стиля.
- **Строки и пункты** списков меняют высоту в той же пропорции, что и шрифт:
  `исходная × новый_шрифт / шрифт_стиля`. Это касается:
  - строк TListView (`ui:list`);
  - пунктов TListBox и TComboBox (не ниже 12);
  - `ItemHeight` списка, если он задан.
- **Высота TComboBox и TColorComboBox** меняется в той же пропорции (не ниже 16).
- **Значок пункта** (`icon`) и флажок пункта (ShowCheckboxes) уменьшаются в той
  же пропорции. Отсчёт всегда идёт от исходного размера, поэтому уменьшение не
  накапливается.
- **Квадратик флажка или переключателя** (`ui:check`) получает размер
  `CheckSize профиля × новый_шрифт / шрифт_стиля` (не меньше 10):
  - в стиле Android картинка рисуется своим размером, поэтому уменьшается
    масштаб рисования (`Scale`), а объект стиля остаётся 22×22;
  - контейнер квадратика сужается до размера квадратика + 2.
- **Кнопки** TButton, TCornerButton и их наследники: `ui:font-N` меняет шрифт
  текста кнопки после каждого применения стиля.
- **Таблицы** TStringGrid / TGrid:
  - шрифт ячеек — это шрифт таблицы, столбцы берут его от неё;
  - заголовки столбцов (TStringColumn и др.) получают тот же размер через
    `HeaderSettings`;
  - заданная высота строки (`RowHeight > 0`) меняется пропорционально шрифту
    (не ниже 12); при `RowHeight = 0` таблица считает её по шрифту сама.
- **Цвета**: `ui:colors16` оставляет в TColorComboBox только 16 основных
  цветов, остальные пункты скрываются.

## Таблица правил (UIRuleTable)

| Пометка | Действие |
|---|---|
| `font-4` / `font-3` / `font-2` / `font-1` | шрифт −4 / −3 / −2 / −1 px |
| `font+1` / `font+2` | шрифт +1 / +2 px |
| `small` / `normal` | шрифт SmallFontSize / FontSize профиля |
| `list` | TListView: шрифт строки, подробности −1, высота строки по шрифту |
| `check` | квадратик TCheckBox / TRadioButton по CheckSize |
| `colors16` | TColorComboBox: 16 основных цветов |
| `btn` / `toolsize` / `statussize` | высота кнопки ButtonHeight / ToolButtonSize / StatusButtonSize |
| `square` | кнопка без текста: ширина = высоте |
| `center` / `fill` / `client` | глиф: по центру / Client с растяжением и отступом GlyphMargin / Client без растяжения |
| `left` | глиф слева, квадрат по высоте кнопки с отступом (кнопки с текстом); текст справа |
| `margin=N` | отступ глифа N px вместо GlyphMargin профиля (для `fill`, `client` и `left`), например `ui:fill ui:margin=0`, `ui:android:margin=1`; дробное число — через точку |
| `skip` | кнопку не трогать |

## Значения по элементам (Android)

| Элемент | Пометка | Уменьшение |
|---|---|---|
| TLabel | `ui:android:font-4` | шрифт −4 |
| TGroupBox | `ui:android:font-4` | шрифт −4 |
| TSpinBox | `ui:android:font-4` | шрифт −4 |
| TNumberBox | `ui:android:font-4` | шрифт −4 |
| TComboBox | `ui:android:font-4` | шрифт пунктов −4, высота комбо и пунктов по шрифту |
| TColorComboBox | `ui:android:font-4 ui:android:colors16` | то же + 16 цветов |
| TCheckBox | `ui:android:font-2 ui:android:check` | шрифт −2, квадратик по шрифту |
| TRadioButton | `ui:android:font-2 ui:android:check` | шрифт −2, кружок по шрифту |
| TListBox (lbMarkerNames, кодом) | `ui:android:font-4` | шрифт пунктов −4, высота пунктов, значки и флажки по шрифту |
| TButton, TCornerButton (и наследники) | `ui:android:font-4` | шрифт текста −4 |
| TStringGrid (ячейки и заголовки TStringColumn) | `ui:android:font-4` | шрифт −4, заданная высота строки по шрифту |
| TButton, TEdit (DlgLocalOpen) | `ui:android:font-2` | шрифт −2 |
| TListView (DlgLocalOpen) | `ui:android:font-2 ui:android:list` | шрифт −2, высота строки по шрифту |
| TButton (instAccuDraw) | `ui:center` | глиф по центру |

Где стоят пометки: `FrameSettings.fmx` — 24 TCheckBox, 2 TRadioButton,
30 TLabel, 7 TGroupBox, 9 TSpinBox, 3 TNumberBox, 1 TComboBox,
13 TColorComboBox; `lbMarkerNames` — в `FrameSettings.pas`, в конструкторе.

Диалоги `COMPS\VarSetForm.fmx` (TVarSetDlg) и наследники VarSetForm1–3
(пометки ставятся там, где объект объявлен; наследники получают их от предка):
- VarSetForm: Grid (TStringGrid), TComboBox, 3 TButton, 3 TCheckBox;
- VarSetForm1: hGrid (TStringGrid), 1 TButton, 1 TCheckBox;
- VarSetForm2 и VarSetForm3: своих таких элементов нет, всё унаследовано.

Главная форма TMainFormDendro. Её элементы объявлены в предках, поэтому
пометки стоят там:

| Файл | Элементы |
|---|---|
| `MainFrm.fmx` | TCornerButton: btnOpen, btnLocalOpen, btnPaint, btnPlus, ptnMinus |
| `MainFrmSkia.fmx` | TCornerButton btnPDF; TButton btnClose; TLabel PanelXY, pMas, PanelHint |
| `MainFrmMouseObj.fmx` | TButton: Load, btnDoc, btnEsc, btnGPKGB, UpDown1Down, UpDown2Down; TLabel LabelVer; TCheckBox: cbOSM, cbOnlyAttr |
| `MainFrmOSM.fmx` | TLabel lMas; TCheckBox cbNAV |
| `MainFrmDendro.fmx` | 2 собственных TCornerButton |

Во всех этих формах: кнопки, надписи, таблицы и комбо — `font-4`; флажки —
`font-2 check`. btnDrop принадлежит фрейму TLayerFrame и не помечен.

## Профили метрик (TUIMetrics)

| Метрика | мышь (Windows) | перо | палец |
|---|---|---|---|
| FontSize | 12 | 12 | 13 |
| SmallFontSize | 11 | 11 | 12 |
| TitleFontSize | 14 | 14 | 15 |
| ListFontSize | 13 | 12 | 14 |
| ButtonHeight | 22 | 22 | 28 |
| ToolButtonSize | 26 | 26 | 32 |
| StatusButtonSize | 21 | 21 | 26 |
| ToolBarHeight | 30 | 30 | 36 |
| StatusBarHeight | 23 | 23 | 28 |
| ItemHeight | 20 | 22 | 28 |
| GlyphMargin | 2 | 2 | 3 |
| Spacing | 4 | 4 | 6 |
| TouchExpansion | 0 | 4 | 8 |
| CheckSize | 16 | 16 | 20 |
| TitleHeight | 24 | 26 | 32 |

Масштаб `UI.Scale` можно менять от 0.5 до 2 (в настройках, «Масштаб интерфейса»,
%). Он хранится в AppUI.ini: на Android — в Documents, на Windows — рядом с exe.

## Прочие константы

| Константа | Значение | Где |
|---|---|---|
| AndroidLineKoef (толщина живого слоя) | 1.5 | `Geomaster\drawTwigs32.pas` |
| DialogBorderColor / DialogBorderWidth | $FF000000 / 0.5 | `AppForms.pas` |
| DialogCornerRadius | 4 | `AppForms.pas` |
| DialogShadowColor | $40000000 | `AppForms.pas` |
| DialogShadowOffset (справа, снизу) / DialogShadowEdge (слева, сверху) | 5 / 2 | `AppForms.pas` |
| DialogTitleColor | $FFDCDCDC | `AppForms.pas` |
| DialogShade (шторка) | $00000000 (прозрачная) | `AppForms.pas` |
| Список слоёв: флажок строки | 20 px, картинки ImageList1[4] / [5] | `InstLayerFrame.pas` |
| Список слоёв: нижний край | высота окна − 10 | `InstLayerFrame.pas` |
