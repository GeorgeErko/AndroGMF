# Формат потока GMF (TBufStream) — карта для копий объектов

Источник — текущие модули `Delphi-Andro\GMF` (Load/Store), регистрация типов — `uExecRegisterClass.RegPrimitives`.
Длины объекта в потоке нет: каждый тип должен быть прочитан точно, иначе поток сдвигается.

## 1. Базовые элементы потока

| Обозначение | Байт | Чтение |
|---|---|---|
| `i8/u8`, `Boolean`, `Byte`, `ShortInt`, перечисления (`Methods`, `AllBits`) | 1 | `Read` |
| `i16`, `SmallInt`, `Word` | 2 | `Read` |
| `i32`, `Integer`, `FixedInt`, `LongInt`* | 4 | `Read` / `ReadInt32` |
| `f32`, `Single` | 4 | `Read` |
| `f64`, `Double` | 8 | `Read` |
| `Ext80` | 10 | `ReadExtended` (80-битный Extended старого формата → Double) |
| `Real48` | 6 | `Read` (`TLot.Plo`, `ClearPlo`) |
| `TGUID` | 16 | `Read` |
| `TRgbRec` | 3 | `ARGB[1..3]` |
| `TZnakInd` | 4 | `LInd: i16`, `SPInd: i16` |
| `ShortString[N]` | N+1 | `TaheoNames: String[12]` = 13 байт |
| `Str32` | 4+L | `ReadString`/`ReadStr`: длина `i32`, L байт cp1251 (`CollectVer = 10`) |
| `Str16` | 2+L | `StrRead`: длина `Word`, L байт как есть (PAnsiChar), 0 → nil |
| `Obj` | 2+… | `Get`: код типа `i16` (0 → nil), затем `Load` класса |

\* `LongInt` читается через `ReadInt32` там, где это явно сделано (TTwigsCollect); на Android64 LongInt = 8 байт — в копиях везде 4.

Коллекция `PCollection` (и `TCollection`, `TSortedCollection`, `TCStrings`, `TFontManager*`, `TRealCollect`):
`Count: i16`, `Capacity: i16`, `Delta: i16`, затем `Count × Obj`.

## 2. Глобальное состояние чтения

Load части классов зависит не только от потока:

| Переменная | Где задается | Кто читает | Примечание |
|---|---|---|---|
| `newConsts.Version` | `TForm1.Load` := `About.Version` | почти все примитивы | вложенная форма блока (`TGeoBlock` → `TForm2`) **перезаписывает** Version и не восстанавливает — дальше внешняя карта читается версией блока |
| `ClassVersion` | `TLayerTable.Load` (первое поле) | `TResource.Load` | глобальная |
| `VersionOfZnk` | заголовок `.lib` (`GO1`/`GO2`/`GO3`, иначе 0) | `TDWG_*`, `TPoint_Sign` | только для файлов классификатора |
| `ver_geo_line` | `TGeoLine.Load` (сигнатура `#1#1#1`+2 байта) | `TLineStruct.Load` вложенной структуры | |
| `MirrorObject` | `About.MirrorObject = 1` | `TForm1.Load` | форма блока: нет FontColEx, Settings, LayerTable |

Текущая версия записи `VerConst = 57`.

### Решения

- Версии карты `Version <= 18` (старая загрузка TLot/TPointDot/TEFont) не поддерживаются — ошибка «формат не поддерживается».
- TExp (1104) и TExpColor (1105) в gmf не используются — в копиях не нужны (при встрече — ошибка).
- TFontScaleEx (153) не нужен (в TFontViewEx не пишется) — в копиях нет.
- Временно (до копий объектов) GRAPHER читает GMF через исходные модули GMF — `rewriteGMF\rewriteGMF.pas`.

## 3. Регистрация типов (код → класс)

| Код | Класс | Модуль | Код | Класс | Модуль |
|---|---|---|---|---|---|
| 50 | PCollection | Collect | 3104 | THatchLot | HatchLot |
| 51 | TSortedCollection | Collect | 3105 | TPolyTwig | HatchLot |
| 52 | TCStrings | Collect | 31031 | THatches | ECLot |
| 53 | TStrClass | Collect | 31032 | TLine | ECLot |
| 101 | TBmpMgr | RPrims | 4001 | TGeoBlock | newBlock |
| 102 | TBmpSet | RPrims | 4010 | TProperty | newProperties |
| 121 | TMarkerOperation | mpMarker | 4011 | TProperties | newProperties |
| 122 | TMarkerView | mpMarker | 4012 | TPropValue | newProperties |
| 152 | TFontViewEx | newFontScale | 5100 | TDWG_Line | Lib |
| 153 | TFontScaleEx | newFontScale | 5101 | TDWG_Arc | Lib |
| 154 | TFontManagerEx (первым; TFontManager с тем же кодом не используется) | newFontScale | 5102 | TPoint_Sign | Lib |
| 280 | TResource | newResource | 5103 | TMeth | Lib |
| 1102 | TLong | TwgColle | 5104 | TSqwear_Sign | LIB2 |
| 1103 | TIntNum | TwgColle | 5105 | TPart | LIB2 |
| 1104 | TExp | TwgColle | 5106 | TGeoLine | Lines3 |
| 1105 | TExpColor | TwgColle | 5107 | TLineStruct | Lines3 |
| 1106 | TExt | TwgColle | 5111 | TPn | Lib |
| 3000 | TDot | EcDot | 5112 | TDWG_Poly | Lib |
| 3001 | TTwig | WpTwigs | 5113 | TDWG_Text | dwgtext |
| 3002 | TText | EcDot2 | 5114 | TDWG_Pie | Lib |
| 3003 | TDotText | EcDot2 | 5120 | TTextManager | textmanager |
| 3021 | TClassTwig | WpTwigs | 5121 | TTextParams | textmanager |
| 3022 | TArcTwig | WpArcs | 5200 | TEFont | ECText |
| 3023 | T3DTwig | WpTwigs | 5201 | TPDot | EcDot |
| 3024 | TTwigARC | WpTwigs | 5202 | TPointDot | EcDot |
| 3025 | TTwigSpline | WpArcs | 5203 | TPointMessage | EcDot |
| 3026 | TTwigSpline3D | WpArcs | 6002 | TBlockList | ObjBlockList |
| 3027 | TTwigSpline3DB | WpArcs | 6003 | TLinkFiles | ObjBlockList |
| 3028 | TTwigSpline3DHermit | WpArcs | 6004 | TTexture | ObjBlockList |
| 3029 | TTwigCircle | WpArcs | 6005 | TTextureList | ObjBlockList |
| 3030 | TTwigTriangle | WpTwigs | 6103 | T3DPoint | Types_dimano |
| 3031 | TTwigCoif | WpTwigs | 6104 | TRealCollect | Types_dimano |
| 3032 | TDataTwig | WpTwigs | 6105 | TDouble | Types_dimano |
| 3033 | TTwigRect | WpRects | 9000 | TTwigsCollect | newForm0 |
| 3103 | TLot | ECLot | 10000 | TForm2 | WPTForm2 |
| 3999 | TPtr | WpTwigs | 32009 | TLayerTable | newLayersTable |

Не через `Get` (читаются напрямую): `About` (заголовок карты), `TSettings`, `TGraphset`.

## 4. Карта (TForm2 = TForm1.Load)

```
About:
  Sign      8 байт  'VER25x'#0#0  ('VER251' → Version := 24)
  Version   u8      → newConsts.Version
  ModifiedObject i16
  DecimalHeight, DecimalLength, SqwearMetric, DecimalSqwear,
  AngleMetric, DecimalCoord, DecimalAngle, CalcDirect: u8 ×8
  Path, ObjectName, BasePath, idPrefix: Str32 ×4
  idAutoAddLot, GraphSet: Boolean ×2
  ClassName, MyName: Str32 ×2
  XMin, YMin, XMax, YMax: Ext80 ×4
  MaxLotNum i32
  Fragment.Left, Top, Right, Bottom: Ext80 ×4
  MirrorObject u8
  Dop       960 байт
if Version > 47 and not Mirror: FontColEx: Obj (TFontManagerEx)
Twigs: Obj (TTwigsCollect)
if Version > 20: fGraphSet: TGraphset (packed record, newSettings — копировать объявление дословно)
if Version > 35 and not Mirror:
  Settings: TSettings (напрямую)
  if Version > 44: TaheoFileName: Str32
-- далее только если не Mirror и существует файл классификатора MainPath + ClassName:
if About.Version > 33:
  LayerTable: Obj (TLayerTable)  (в оригинале под try/except)
  if About.Version > 56: urlNum, dbName: Str32 ×2
```

Классификатор (`ClassName` → `.lib`/`.lb2`/`.lb3` рядом, `TMosLib.LoadZnaks`) — отдельные файлы:
- `.lib`: 4 байта, `C[1..3] = 'GO1'|'GO2'|'GO3'` → VersionOfZnk 1..3, иначе 0 и возврат в начало; затем `Obj` — PCollection из TPoint_Sign;
- `.lb2`: `Obj` — PCollection из TSqwear_Sign;
- `.lb3`: `Obj` — PCollection из TGeoLine.

### TSettings (напрямую)
`psOrtho: Bool, psOrthoDisst: i32, psAuto: Bool, psAutoDisst: i32, psInsert, psTwise, psStvor, psOrthoTwigs: Bool ×4, psOrthoTwigsCount, psArcCount, psSplineCount: i32 ×3, psSaveOrthoTwigs: Bool, psArcCount, psSplineCount: i32 ×2 (повтор), bmColor, bmBackColor: i32 ×2, bmGlass, bmFrame: Bool ×2, gsShowGrid: Bool, gsScale: i32, gsGridType, gsGridColor: i32 ×2, gsGridSize, gsGridCellWidth, gsGridCellHeight: f64 ×3, psQueryLayerDraw, psQueryLayerSbor, psQueryLayerAttrib, psTwiseLot, psNoAssociativeFill, psOrthoMode, psLineArc, psLineSpline: Bool ×8, psWidthPath: Bool, psNumberUch: u8, Dop: 1991 байт, Vars: Obj (PCollection)`;
`if Version > 51: HasImage: Bool; if HasImage: компонент TImage (TStream.ReadComponent — двоичный DFM, 'TPF0'...)`.

## 5. TTwigsCollect (9000)

```
AllCount Ext80
TwigsCount, LotsCount, AnyCount: i32 ×3
TwigsCol, LotsCol, AnyCol: u8 ×3
Twigs[0..TwigsCol]: Obj ×(TwigsCol+1)   — PCollection ветвей
Lots[0..LotsCol]:   Obj ×(LotsCol+1)    — PCollection контуров
Any[0..AnyCol]:     Obj ×(AnyCol+1)     — PCollection точек/текстов
PAny[0..AnyCol]:    Obj ×(AnyCol+1)
if not EOF: CountTaheo u8; 11 × (TaheoNames ShortString[12] = 13 байт, TaheoDots Obj, TaheoTwigs Obj)
if not EOF: FontS Obj, FontSet Obj
if not EOF: HPoly Obj
if not EOF: Bitmaps Obj (TBmpSet)
if Version > 22:
  if not EOF: Cnt i16; Cnt × Str32 (TaheoIndexes)
  if Version > 24:
    if not EOF: BlockList Obj (TBlockList)
    if Version > 41: LinkFiles Obj          (в оригинале под try/except)
    if Version > 45: RasterFiles Obj; if Version > 52: TextureList Obj
```
«EOF» — `Position = Size` всего файла (для вложенной формы блока всегда «не EOF»).

## 6. Ветви

**TTwig (3001)**
```
if Version > 22: TaheoIndex = (Version < 28 ? i8 : i16)
Color TRgbRec, Rang i16, UZnak i16, Closed u8
TwigCoord Obj (PCollection из TDot)
if Version > 14:
  Locked u8, MakeUsel Bool
  if Version > 17: What u8
  if Version > 25:
    ZDx f32
    if Version > 37: Koef f32, Properties Obj
      if Version > 43: LineWidth f32
```
Наследники (каждый — `TTwig` + свое):
- TClassTwig (3021), TTwigTriangle (3030): `Code f64`
- T3DTwig (3023): `Z f32`
- TTwigARC (3024): `ArcCoord Obj`
- TArcTwig (3022), TTwigSpline (3025): `ArcCoord Obj` (Store сплайна пишет пустую коллекцию)
- TTwigSpline3D/3DB/3DHermit (3026–3028): TTwigSpline + `Z f32`
- TTwigCircle (3029): ничего
- TTwigRect (3033): `Proportional Bool`
- TTwigCoif (3031): TClassTwig + `Coif Obj (TRealCollect)`, `Pikets Obj`
- TDataTwig (3032): **без** inherited — `Size i32`, `Size` байт данных

**TPtr (3999)**: `Register u8`. **TDot (3000)**: `X, Y: (Version <= 5 ? f32 : f64)`, `What i16`, `if Version > 20: Z f32`. **TPDot (5201)**: TDot + `Ugol f32`.

## 7. Точки и тексты

**TPointDot (5202)** (Version > 18):
```
if Version > 22: TaheoIndex = (Version < 28 ? i8 : i16)
XDot f64, YDot f64, What i16, Ugol f32, Code f64
Fonts Obj, Lines Obj
NLot i32, Ins i32
DataFonts Obj
Z f32, Control Bool
UID Str16
if Version >= 29:
  TextManager Obj
  if Version > 36:
    userObj Obj (TGeoBlock с Check=1 — ссылка по имени)
    XKoef f32, YKoef f32
    if Version > 39:
      Properties Obj
      if Version > 48:
        Extrusion Bool
        if Version > 50:
          Bind Obj (TPDot)
          if Version > 54:
            Trees Obj
            if Version > 55: GUID
```
- TPointMessage (5203): TPointDot + `EventName Str32`, `EventNum Str32`
- TDotText (3003): TPointDot + `Text Obj (TText)` + `GyperLink Str32`
- TText (3002): `Text Str32, fontIndex i32, Height f32, Align u8, Color i32, Transparent u8, AttrName Str32`
- TTextManager (5120): `FValues Obj (PCollection из TTextParams)`, `FVars Obj (TCStrings)`
- TTextParams (5121): `FValue Str32`; `if Version > 30: FDx, FDy, FUgol, FH, FW: f32 ×5, FAttr u8; if Version > 40: AlignX, AlignY: f32 ×2, DxfLock Bool; if Version > 43: ShiftX, ShiftY: i16 ×2`; иначе `Dx, Dy, Ugol: f64 ×3`
- TEFont (5200) (Version > 18): `Fonts u8, UgolRotate i16, HF f32, WF f32, XF f64, YF f64, Named Str16, Palitra i32, it, bl, un: u8 ×3, ClassCode f64, Lock Bool, What u8; if Version > 23: TaheoIndex (Version < 28 ? i8 : i16); if Version > 32: ShiftX, ShiftY: i16 ×2`

## 8. Контуры

**TLot (3103)** (Version > 18):
```
if Version > 21: What u8; if Version > 22: TaheoIndex (Version < 28 ? i8 : i16)
Coord Obj (номера ветвей), UZnaks Obj, DataFonts Obj
ClassCode f64, Closed u8
Plo Real48, ClearPlo Real48
Ins i32, RKF f32, NLot i32, TypeLot u8, Copy u8, Copy1 u8, BaseIns i32
Fonts Obj, Lines Obj
UID Str16
if Version > 29:
  DataPoints Obj
  if Version > 39:
    Properties Obj
    if Version > 49: Hatches Obj (THatches)
    if Version > 53: GUID
```
Store всегда пишет Hatches + GUID (VerConst > 49).
- THatchLot (3104): TLot + `Zeros Obj`
- TPolyTwig (3105): `Square f64, Twigs Obj`
- THatches (31031): коллекция (TLine) + `Holes Obj`
- TLine (31032): `D Obj (TDot)`, `D1 Obj (TDot)`

## 9. Блоки, слои, ресурсы

**TGeoBlock (4001)**:
```
Check u8, Name Str32
if Check = 0:
  X f64, Y f64
  TwgForm Obj (TForm2 с MirrorObject = 1; меняет Version!)
  useUserParams Bool
  blockRect: Ext80 ×4
  useBum, useAutoScale, useRect: Bool ×3
  AutoLayer f32, emptyBlock u8
  Settings 435 байт  (480 − 40 − 1 − 4 − 1 + 1)
  if Version > 37: Properties Obj
```
- TBlockList (6002): `Blocks Obj`
- TLinkFiles (6003): `Paths Obj (TCStrings)`, `Objects Obj (TCStrings)`
- TTexture (6004): `FileName Str32, Settings 21 байт`; TTextureList (6005): `Textures Obj, Settings 21 байт`
- TLayerTable (32009): `ClassVersion i32 → глобальная, ActiveID f64, Layers Obj`
- **TResource (280)**: `ID Ext80, RecString Str16, Rang Ext80, RGB TRgbRec, SSInd i16, ZnkInd TZnakInd, Check i16, NBase u8, Hatch u8`;
  `if Version > 5: NameBase 26 байт, NameLot 26 байт, NameMark (ClassVersion < 12 ? 26 байт : Str32)`;
  `if Version > 6: Lot, Znak, Marked, Fon, Standart: u8 ×5, FName Str32, FColor i32, FAttr 3 байта, FH f32, FW f32, Page u8, Opaque Bool, OpColor i32, Clip u8, ConGen u8, FRasp i32, FDx f32, FDy f32, Childs Obj (PCollection из TExt), MakeUsel Bool, OpWin Bool, brTabName 25 байт, brFieldName 50 байт, brFieldIn 50 байт, [ClassVersion > 11: brMark Str32], Index i32, Indexed Bool, LineColor i32, NoPerehlest u8, [ClassVersion > 13: RRepName Str32, RUse u8, RMarkIndex u8, RFieldName Str32, RPreview Bool, [ClassVersion > 16: Resources Obj]], isPrevStandart i32, FLock, FUnLock, idLot, idQuery, PereFree: Bool ×5, ColorK i16, AlwaysHor, Relation: Bool ×2, ZnakKoef f32, GlassFon Bool, ObStruct 25 байт, UpRastr, ShowAttr, CheckWithGroup: Bool ×3, Level i32, Frozen Bool, LineWidth f32, notClearPod, notClearNad: Bool ×2, Dop 307 байт, [ClassVersion > 18: propDicts Str32]`

## 10. Свойства, мелкие типы

- TProperties (4011): `Properties Obj`; TProperty (4010): `PropName Str32, PropValue Obj`
- TPropValue (4012): `varType i32, Value Str32; if Value = 'Изображение': HasImage Bool; if HasImage: компонент TImage (двоичный DFM)`
- TStrClass (53): `S Str32`; TLong (1102): `Num i32`; TIntNum (1103): `Num i16`; TExt (1106): `Num Ext80`; TDouble (6105): `Num f64`; T3DPoint (6103): `X, Y, Z: f64 ×3`
- TExp (1104): `Num, Name Str16, Plo, Plo2` — `Num/Plo/Plo2` читаются `SizeOf(Extended)`: на Win64/Android это 8 байт, в файлах Win32 — 10 (**проверить**, встречается ли тип в gmf)
- TExpColor (1105): `Color i32, Name Str32, Plo1, Plo2 (то же замечание), DoName Str32`

## 11. Растры, шрифты, маркеры

- TBmpSet (102): `FileName Str32, Bitmaps Obj; if Version > 42: FActive i32`
- TBmpMgr (101): `X f64, Y f64, XR i32, YR i32, Left, Top, Right, Bottom: f64 ×4, LeftR, TopR, RightR, BottomR: i32 ×4, Name Str32, FileName Str32, Mas i32, Code f64; if Version > 33: CheckVisible Bool, Dop 100 байт; if Version > 34: Regions Obj; if Version > 37: Properties Obj`
- TFontViewEx (152): `Scale, bl, it, un, ov: i32 ×5, FontName Str32, CharSet u8, Index i32`
- TFontScaleEx (153): `Symbol Char` (D7 — 1 байт, Unicode Delphi — 2: **проверить**), `PolyCount i32, PointsCount i32, Lines PointsCount×8+1 байт, Polygons PolyCount×4 байт, XMin..MaxY i32 ×8, XNext, YNext i32 ×2, TI2 f64`; в TFontViewEx больше не пишется
- TMarkerView (122): `Operations Obj`; TMarkerOperation (121): `fixName Str32, Name Str32, Color i32, Size i32, mWidth i32, Rotation Bool, mType i32, Checked Bool, Dop 96 байт`

## 12. Классификатор (.lib/.lb2/.lb3)

- TPoint_Sign (5102): `X f32, Y f32, Ugol f32, MyNameIs (VersionOfZnk > 0 ? 101 : 24 байта), [VersionOfZnk > 1: useMas Bool], BkColor Bool, MyInd i16, MethodCol Obj`
- TMeth (5103): `MT u8 (m_arc, m_line, m_Poly, m_text, m_Pie), PT Obj`
- TDWG_Line (5100): `x_b, y_b, x_e, y_e: f32 ×4; [VersionOfZnk > 1: Color i32, lineW f32; [> 2: useColor Bool]]`
- TDWG_Arc (5101), TDWG_Pie (5114): `x_1, y_1, x_2, y_2, xu_1, yu_1, xu_2, yu_2: f32 ×8; [VersionOfZnk > 1: Color i32, XX Bool, FillColor i32, lineW f32; [> 2: useFill Bool]]`
- TDWG_Poly (5112): `Vertex Obj (из TPn); [VersionOfZnk > 1: как у дуги]`; TPn (5111): `X f32, Y f32`
- TDWG_Text (5113): `FX f32, FY f32, FColor i32, FFontIndex i32, FAng f32, FWidth f32, FHeight f32, FName Str32, FText Str32, FCharSet u8, FBl, Fit, FUn, FScale: i32 ×4, FFntName Str32, FVisible Bool, FBg Bool, FBgColor i32, FVarType u16, FTextAlignX f32, FTextAlignY f32, FParams 113 байт`
- TSqwear_Sign (5104): `NameOf 30 байт, IdNum i16, Structura Obj (из TPart)`; TPart (5105): `LineDx, Dx, Dy, MoveX, MoveY, RotateAngle: f32 ×6, IndexOf i32`
- TGeoLine (5106): `сигнатура 5 байт (#1#1#1, ver = s[3]*10 + s[4]; иначе ver = 0 и возврат на 5 байт), NameOf 30 байт, IdNum i16, Structura Obj (из TLineStruct)`
- TLineStruct (5107): `BitOf u8, DrawState i16, Param0..Param8: f32 ×9; [ver_geo_line > 0: lVorign f32, rVorign f32, Color i32, bkColor i32]`

## 13. Расхождения Load/Store в старом коде (копии их не повторяют)

- Имена знаков (`TPoint_Sign.MyNameIs`, `TSqwear_Sign.NameOf`, `TGeoLine.NameOf`) Load перекодирует в UTF-8 прямо в массиве — копии хранят байты как есть.
- `TDWG_Line.Store` пишет неинициализированный байт вместо `useColor`; `TPoint_Sign.Store` пишет `useMas` всегда, Load — только при VersionOfZnk > 1.
- `TDataTwig.Load` читает данные в саму переменную-указатель (порча памяти) — копия читает в буфер.
- `TTwigSpline.Store` пишет пустую `ArcCoord`.
- `TDotText.GyperLink` проходит через `TStringList.Text` (меняет переводы строк) — копия хранит строку как есть.
- Компоненты TImage (`TSettings`, `TPropValue` «Изображение») — двоичный DFM: копии нужен разбор формата TReader только для пропуска/сохранения байт.
