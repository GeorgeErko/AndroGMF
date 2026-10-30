# GRAPHER — иерархия OGS для FMX (Win64 / Android)

Перенос иерархии классов из `C:\!theGrapher` (CodeTyphon) на Delphi FMX + Skia.
Имена модулей совпадают с `JSON\ogc*` — GRAPHER является их преемником,
в один проект с `JSON\ogcBasic/ogcGeometry/ogcProperties` не подключается.

| Модуль | Источник | Что изменено |
|---|---|---|
| ogcBasic | GlobalShared\ogcBasic | FMX/System.UITypes вместо LCL; `TogsProperties = TJSONObject`; `TogsStream.GetJSON/PutJSON`, `ReadUTF8/WriteUTF8`; DevScale через `Selector.DevicePPI`; убраны calcTess/DrawPolyTess; исправлены Load/Store `TogsSimpleGeometrySet`, `TogsRect.Store`; регистрация TogsRect (103) |
| ogcMemStream | GlobalShared\ogcmemstream | 64-битная адресация, Seek(Int64), без GlobalAlloc |
| ogcMathUtils | GlobalShared\ogcMathUtils | Dist_Point_Edge (проекция), point_in_polygon_xy, GStrToFloat |
| ogcProperties | новый | вместо TogsProp* и ogcJSON: class helper для TJSONValue/TJSONObject, разбор/запись строк и файлов |
| ogcGeometry | ogcGeometry | свойства TJSONObject, экспорт GeoJSON Feature; `TPolyMode.GlobalParent` — дырки и острова любой вложенности; ogcTess удален |
| ogcClipPolyline | ogcClipPolyline | без изменений логики |
| ttfGeometry | ttfgeometry | контуры глифов из Skia (`ISkFont.GetPath`), раскладка строки по метрикам Skia, глифы создаются по запросу; Load/Store текста |
| ogcCallbackTypes, ogcLType, ogcTypedCollect | одноименные | Delphi-совместимость, регистрация TLineStruct/TGeoLine |
| ogcLTDrawer | GMFLTDrawer | переименован (в проекте есть GMF\GMFLTDrawer) |
| GMFGeometry | GMFGeometry | исправлены Store (Read вместо Write), Load/Store TgmfLineType; регистрация классов 502..508 |
| ogcSkiaDrawer | новый | TogsDrawer на ISkCanvas: линии, ломаные, окружности, маркеры, заливка EvenOdd |

## Запись GeoJSON (каскадом)

Запись в стандартный GeoJSON выполняется каскадно в текстовый поток:
`TogsGeometry.StoreGeoJSON(Stream)` — примитив пишет себя как Feature (`ToString`),
коллекция `TogsGeometryCollection` открывает `FeatureCollection` и вызывает
`StoreGeoJSON` элементов (вложенные коллекции раскрываются в тот же список).
Служебные поля (класс, цвет, тип линии, блок, параметры текста) пишутся в
`properties.ogs`, пользовательская семантика — в остальные `properties`.
Обертки: `GeoJSONToString`, `GeoJSONToFile` (ogcGeometry).
Чтение GeoJSON — отдельным блоком на основе `CreateJSON` (не через Get/Put).

## Карта — TogsMapSpace (ogcMapSpace)

Корневой объект-карта, перенос `TogsMapObject` из theGrapher (наследник `TgmfBlock`):
владеет `ogsSelector`, таблицами `PLib` (блоки), `LLib` (типы линий), `SLib` (штриховки)
и примитивами `Geometry`.

- `LoadGeoJSON` / `LoadGeoJSONString` — FeatureCollection, Feature или одиночная геометрия;
  класс примитива из `properties.ogs.class` (иначе стандартный Togs*), служебные поля
  восстанавливаются, таблицы `ogs:linetypes` и `ogs:blocks` читаются до примитивов.
- `SaveGeoJSON` / `StoreGeoJSON` — features + `name`, `ogs:linetypes`, `ogs:blocks`
  (геометрия блока — FeatureCollection в его системе координат).
- `SaveToFile` / `LoadFromFile` — двоичный формат (Load/Store + таблицы), класс 509.
- `ResolveReferences` — блоки вставок, типы линий, тексты атрибутов по именам;
  `UpdateObject(FitView)` — габариты и перерисовка.
- `OpenFile` — пока только `.geojson`/`.json` (чтение GMF — отдельно).

Регистрационные номера классов: 100..105 ogcBasic, 200..208 ogcGeometry,
400..403 ttfGeometry, 500..501 ogcLType, 502..508 GMFGeometry.

## Индексы карты (ogcMapIndex)

`Geometry` карты — хранение в порядке добавления, не сортируется. Порядок
отрисовки и захвата задает `TogsPloIndex` (аналог `TPloIndex` старого GMF) —
наследник `TogsSortedCollection`, хранит только указатели на примитивы `Geometry`
(не владеет ими). Ключ — закэшированная площадь по убыванию (линии = -1,
точки и тексты = -3), затем `ogsID`, затем адрес объекта; `Duplicates = False`.
`UpdatePrim`: удаление из индекса до пересчета площади, затем вставка. `Draw` — прямой обход (большие площади снизу, затем линии,
точки), `SelectByPoint` — обратный. Изменения — только через
`AddPrim` / `RemovePrim` / `UpdatePrim`; загрузка — между `BeginUpdate` / `EndUpdate`
(одна перестройка, как `CreateIndexes`). Ранг слоя в ключ войдет вместе с таблицей слоев.

## Тестовый проект — Test\GrapherTest.dpr

FMX-форма с TSkPaintBox: загрузка/сохранение GeoJSON и двоичного `.ogs`
(TogsMapSpace), отрисовка ogcSkiaDrawer, текст шрифтом из папки `Fonts`
(кнопка «Текст», загрузка шрифта — «Шрифт...»). Колесо — масштаб, левая кнопка — сдвиг.
`sample.geojson` и `Fonts` ищутся рядом с exe, затем в папке проекта (exe в Win64\Debug).
`.dproj` и `.res` создаются Delphi при первом открытии `GrapherTest.dpr`.

## Читатель GMF в библиотеке — GMFReader\gmfreader.dpr

Минимальная проверка импорта GMF через библиотеку: Win64 — `gmfreader.dll`,
Android64 — `libgmfreader.so`. Библиотека собирается со старыми модулями GMF
и `JSON\ogcBasic` (76 модулей, пути как в `AndroGMF.dpr`), поэтому не конфликтует
с GRAPHER в вызывающей программе. Контракт — `gmfReaderAPI.pas`: только простые
типы, записи, `PChar` и указатели, соглашение `cdecl`.

Функции: `gmfReaderVersion`, `gmfReaderOpen(FileName, AppPath, Callback, UserData)`
(результат — число контуров или код ошибки < 0, один обратный вызов со сведениями
о файле), `gmfReaderLastError(Buf, BufLen)`.

Сборка:
1. Открыть `GMFReader\gmfreader.dpr`, добавить платформы Win64 и Android64.
2. Project Options → Building → Delphi Compiler → Conditional defines: `GMF_READER`
   (все конфигурации и платформы). Без него сборка останавливается сообщением.
   В общих модулях GMF под `GMF_READER` отключены `WPTForm2 → FramePropEditor`
   и `textmanager → VarSetForm` (формы приложения); в AndroGMF ничего не меняется.
3. Windows: dll ищется рядом с `GrapherTest.exe`, затем в `GMFReader\Win64\Debug|Release`.
4. Android64: в Deployment GrapherTest добавить `libgmfreader.so` с Remote Path
   `library\lib\arm64-v8a\`; `.gmf` и классификатор — в каталог данных приложения
   (`TPath.GetDocumentsPath`).
5. `AppPath` (→ `newProcs.MainPath`) — каталог вызывающей программы: Windows — каталог exe,
   Android — `TPath.GetDocumentsPath`; пустая строка — то же по умолчанию в библиотеке.
   Диагностика — logcat (WriteIn).

Кнопка «Проверка GMF» в GrapherTest загружает библиотеку и показывает число
контуров и сообщение из обратного вызова (кириллица — проверка передачи строк).
