unit ogcMapSpace;

interface

uses Classes, SysUtils, System.UITypes, System.JSON, ogcBasic, ogcGeometry,
     ttfGeometry, GMFGeometry, ogcLType, ogcTypedCollect, ogcMapIndex;

// TogsMapSpace - корневой объект-карта (перенос TogsMapObject из theGrapher):
// владеет ogsSelector, таблицами блоков, типов линий, штриховок и
// примитивами карты (Geometry). Чтение/запись:
//   двоичный поток - SaveToFile / LoadFromFile (Load/Store);
//   GeoJSON - LoadGeoJSON / LoadGeoJSONString, SaveGeoJSON / StoreGeoJSON.
// GeoJSON: features - примитивы карты, служебные поля - properties.ogs,
// таблицы - члены верхнего уровня "ogs:linetypes" и "ogs:blocks".
// Geometry - хранение в порядке добавления (ogsID, запись в файл), не сортируется;
// порядок отрисовки и захвата задает индекс PloIndex (см. ogcMapIndex).
// Примитивы добавляются/удаляются/изменяются только через AddPrim/RemovePrim/
// UpdatePrim; массовая загрузка - между BeginUpdate/EndUpdate (одна перестройка).

type

  { TogsMapSpace }

  TogsMapSpace = class(TgmfBlock)
  private
   fOnPaint: TNotifyEvent;
   fNextOgsID: Int64;
   fOwnSelector: TogsSelector; // Selector, созданный картой
   fPloIndex: TogsPloIndex;
   fUpdateCount: Integer;
   procedure AssignOgsIDs;
   procedure CalcPrim(Prim: TogsGeometry);
   function GetPLibItem(Index: Integer): TgmfBlock;
   function GetLLibItem(Index: Integer): TgmfLineType;
   procedure CreateTables;
  // GeoJSON
   function FeatureToPrim(Feature: TJSONObject): TogsGeometry;
   procedure ReadLineTypes(Value: TJSONValue);
   procedure ReadBlocks(Value: TJSONValue);
   function LineTypesToJSON: TJSONArray;
   function BlocksToJSON: TJSONArray;
   procedure ResolveCollection(Collection: TogsGeometryCollection);
  protected
   procedure SetogsSelector(Data: TogsSelector); override;
  public
   PLib: TStrTypedCollection; // блоки
   LLib: TStrTypedCollection; // типы линий
   SLib: TStrTypedCollection; // штриховки
   Drawer: TogsDrawer;
  // FontsPath - папка шрифтов (см. TogsFontManager.LoadFontList),
  // шрифты загружаются, если ogsFontManager пуст
   constructor Create(Drawer_: TogsDrawer; FontsPath: String = '');
   destructor Destroy; override;
  //
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   class function LoadFromFile(const FileName: String; Drawer_: TogsDrawer): TogsMapSpace;
   procedure SaveToFile(const FileName: String);
  //
   procedure Clear; override;
  // открытие файла по расширению: .geojson/.json - GeoJSON
   function OpenFile(FileName_: String): Integer; virtual;
  // связи по именам: блоки вставок, типы линий, атрибуты блоков;
  // габариты и экран (FitView - вписать карту)
   procedure ResolveReferences;
   procedure UpdateObject(FitView: boolean = False);
  // доступ
   property PLibItem[Index: Integer]: TgmfBlock read GetPLibItem;
   property LLibItem[Index: Integer]: TgmfLineType read GetLLibItem;
  // поиск в библиотеках
   function SearchPLib(ItemName_: String): TgmfBlock;
   function SearchLLib(ItemName_: String): TgmfLineType;
   function SearchSLib(ItemName_: String): TgmfHatchStyle;
  // таблица блоков, типов линий
   procedure AddBlock(Block: TgmfBlock);
   procedure AddLineType(LT: TgmfLineType);
  // вставка в Geometry, возвращает индекс элемента
   function AddPrim(Prim: TogsGeometry): Integer; override;
  // удаление из Geometry и индексов (FreeIt - уничтожить примитив)
   function RemovePrim(Prim: TogsGeometry; FreeIt: Boolean = True): Boolean;
  // после изменения геометрии примитива: пересчет и перестановка в индексах
   procedure UpdatePrim(Prim: TogsGeometry);
  // массовое добавление: индексы перестраиваются один раз в EndUpdate
   procedure BeginUpdate;
   procedure EndUpdate;
   procedure RebuildIndexes;
   property PloIndex: TogsPloIndex read fPloIndex;
  // GeoJSON: Append = False - карта предварительно очищается;
  // результат - количество загруженных примитивов
   function LoadGeoJSONString(const jsonStr: String; Append: Boolean = False): Integer;
   function LoadGeoJSON(const FileName: String; Append: Boolean = False): Integer;
   function StoreGeoJSON(Stream: TogsStream): Integer; override;
   function SaveGeoJSON(const FileName: String): Integer;
  //
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // рисовка
   procedure Draw(Drawer: TogsDrawer); override;
   property OnPaint: TNotifyEvent read fOnPaint write fOnPaint;
  end;

implementation uses StrUtils, System.IOUtils, ogcProperties;

const
// выравнивание текста по умолчанию (лево, базовая линия)
  cDefAlign: TFEAlignments = [ftaLeft, ftaBaseline];

// значения служебного раздела ogs: Default, если поле отсутствует
function OgsStr(Ogs: TJSONValue; const Name, Default: String): String;
var V: TJSONValue;
begin
 Result := Default;
 if Ogs = nil then exit;
 V := Ogs.ItemByName[Name];
 if (V <> nil) and not (V is TJSONNull) then Result := V.AsString;
end;

function OgsFloat(Ogs: TJSONValue; const Name: String; Default: Double): Double;
var V: TJSONValue;
begin
 Result := Default;
 if Ogs = nil then exit;
 V := Ogs.ItemByName[Name];
 if (V <> nil) and not (V is TJSONNull) then Result := V.AsFloat;
end;

function OgsInt(Ogs: TJSONValue; const Name: String; Default: Integer): Integer;
var V: TJSONValue;
begin
 Result := Default;
 if Ogs = nil then exit;
 V := Ogs.ItemByName[Name];
 if (V <> nil) and not (V is TJSONNull) then Result := V.AsInt;
end;

function OgsBool(Ogs: TJSONValue; const Name: String; Default: Boolean): Boolean;
var V: TJSONValue;
begin
 Result := Default;
 if Ogs = nil then exit;
 V := Ogs.ItemByName[Name];
 if (V <> nil) and not (V is TJSONNull) then Result := V.AsBoolean;
end;

function JSONStr(const S: String): String;
var V: TJSONString;
begin
 V := TJSONString.Create(S);
 try
  Result := V.ToJSON;
 finally
  V.Free;
 end;
end;

{ TogsMapSpace }

procedure TogsMapSpace.CreateTables;
begin
 PLib := TStrTypedCollection.CreateTyped;
 LLib := TStrTypedCollection.CreateTyped;
 SLib := TStrTypedCollection.CreateTyped;
 fPloIndex := TogsPloIndex.Create;
 fNextOgsID := 1;
end;

procedure TogsMapSpace.SetogsSelector(Data: TogsSelector);
var I: Integer;
begin
 inherited SetogsSelector(Data);
 if PLib <> nil then
  For I := 0 to PLib.Count - 1 do TgmfBlock(PLib[I].Data).SetogsSelector(Data);
end;

constructor TogsMapSpace.Create(Drawer_: TogsDrawer; FontsPath: String);
begin
 CreateTables;
//
 Drawer := Drawer_;
 fOwnSelector := TogsSelector.Create(Drawer_);
 fOwnSelector.Parent := Self;
 fOwnSelector.sName := 'MapSpace';
// шрифты общие для всех карт (глобальный ogsFontManager)
 // глифам Selector не нужен (захват по вхождению точки), карта может быть
// уничтожена раньше шрифтов -> nil
 if ogsFontManager.Count = 0 then ogsFontManager.LoadFontList(nil, FontsPath);
// вызов
 inherited Create(fOwnSelector, '', -2, 0, 0, 0);
 Scale := 1;
 Clear;
 fOwnSelector.GlobalRect.Assign(ogsRect);
 if Drawer <> nil then fOwnSelector.UpdateRects(True);
end;

destructor TogsMapSpace.Destroy;
begin
 inherited Destroy;
 fPloIndex.Free;
 PLib.Free;
 LLib.Free;
 SLib.Free;
 fOwnSelector.Free;
end;

constructor TogsMapSpace.Load(Stream: TogsStream);
var I, N: Integer;
    Obj: TogsBasic;
begin
 CreateTables;
 inherited Load(Stream);
// таблицы: блоки, типы линий
 N := Stream.ReadInt;
 for I := 0 to N - 1 do begin
  Obj := Stream.Get;
  if Obj is TgmfBlock then AddBlock(TgmfBlock(Obj)) else Obj.Free;
 end;
 N := Stream.ReadInt;
 for I := 0 to N - 1 do begin
  Obj := Stream.Get;
  if Obj is TgmfLineType then AddLineType(TgmfLineType(Obj)) else Obj.Free;
 end;
 ResolveReferences;
// ogsID в поток не пишется -> назначаем заново, затем индексы
 AssignOgsIDs;
 RebuildIndexes;
end;

procedure TogsMapSpace.Store(Stream: TogsStream);
var I: Integer;
begin
 inherited Store(Stream);
 Stream.WriteInt(PLib.Count);
 for I := 0 to PLib.Count - 1 do Stream.Put(PLibItem[I]);
 Stream.WriteInt(LLib.Count);
 for I := 0 to LLib.Count - 1 do Stream.Put(LLibItem[I]);
end;

class function TogsMapSpace.LoadFromFile(const FileName: String; Drawer_: TogsDrawer): TogsMapSpace;
var Selector: TogsSelector;
    Stream: TogsStream;
    Obj: TogsBasic;
begin
 Result := nil;
 Selector := TogsSelector.Create(Drawer_);
 Stream := TogsStream.CreateFileStream(FileName, fmOpenRead or fmShareDenyWrite, Selector);
 try
  Obj := Stream.Get;
  if not (Obj is TogsMapSpace) then begin
   Obj.Free;
   raise Exception.Create('Файл не содержит карту: ' + FileName);
  end;
  Result := TogsMapSpace(Obj);
  Result.fOwnSelector := Selector;
  Selector.Parent := Result;
  Selector := nil;
  Result.Drawer := Drawer_;
  Result.UpdateObject(True);
 finally
  Stream.Free;
  Selector.Free;
 end;
end;

procedure TogsMapSpace.SaveToFile(const FileName: String);
var Stream: TogsStream;
begin
 Stream := TogsStream.CreateFileStream(FileName, fmCreate, ogsSelector);
 try
  Stream.Put(Self);
 finally
  Stream.Free;
 end;
end;

procedure TogsMapSpace.Clear;
begin
 inherited Clear;
 ogsRect.Clear;
 ogsRect.Insert(0, 0);
 ogsRect.Insert(10, 10);
 PLib.FreeAll; LLib.FreeAll; SLib.FreeAll;
 if fPloIndex <> nil then fPloIndex.Clear;
 fNextOgsID := 1;
end;

procedure TogsMapSpace.AssignOgsIDs;
var I: Integer;
    G: TogsGeometry;
begin
 if Geometry = nil then Exit;
 for I := 0 to Geometry.Count - 1 do begin
  G := Geometry.Item[I];
  if (G <> nil) and (G.ogsID = 0) then begin
   G.ogsID := fNextOgsID;
   Inc(fNextOgsID);
  end;
 end;
end;

function TogsMapSpace.GetPLibItem(Index: Integer): TgmfBlock;
begin
 Result := TgmfBlock(PLib[Index].Data);
end;

function TogsMapSpace.GetLLibItem(Index: Integer): TgmfLineType;
begin
 Result := TgmfLineType(LLib[Index].Data);
end;

function TogsMapSpace.OpenFile(FileName_: String): Integer;
var Ext: String;
begin
 Result := 0;
 Ext := LowerCase(ExtractFileExt(FileName_));
 if (Ext = '.geojson') or (Ext = '.json') then Result := LoadGeoJSON(FileName_) else
  raise Exception.Create('Неизвестный формат файла: ' + FileName_);
end;

procedure TogsMapSpace.ResolveCollection(Collection: TogsGeometryCollection);
var I, J: Integer;
    G: TogsGeometry;
    P: Pointer;
    Attr_: TogsTextParams;
begin
 for I := 0 to Collection.Count - 1 do begin
  G := Collection.Item[I];
 // вставка блока: блок по имени, атрибуты -> тексты блока с тем же именем атрибута
  if G is TgmfPoint then
   with TgmfPoint(G) do begin
    if (gmfBlock = nil) and (BlockName <> '') then gmfBlock := SearchPLib(BlockName);
    if (gmfBlock <> nil) and (Attribs <> nil) then
     for J := 0 to Attribs.Count - 1 do begin
      Attr_ := Attribs[J];
      if (Attr_.TextString = nil) and gmfBlock.FindAttribute(Attr_.fAttrName, P) and (TObject(P) is TogsTextString) then Attr_.TextString := TogsTextString(P);
     end;
   end
  else
  if G is TgmfLineString then
   with TgmfLineString(G) do begin
    if (lType = nil) and (LineTypeName <> '') then lType := SearchLLib(LineTypeName);
   end
  else
  if G is TgmfMultiLineString then
   with TgmfMultiLineString(G) do begin
    if (LineType = nil) and (LineTypeName <> '') then LineType := SearchLLib(LineTypeName);
   end
  else
  if (G is TogsGeometryCollection) and (G.GeometryType = 'GeometryCollection') then ResolveCollection(TogsGeometryCollection(G));
 end;
end;

procedure TogsMapSpace.ResolveReferences;
var I: Integer;
begin
// вложенные блоки и типы линий внутри блоков
 for I := 0 to PLib.Count - 1 do ResolveCollection(PLibItem[I].Geometry);
 ResolveCollection(Geometry);
end;

procedure TogsMapSpace.UpdateObject(FitView: boolean);
var I: Integer;
begin
// получение ссылок на блоки из типов линий
 For I := 0 to LLib.Count - 1 do LLibItem[I].UpdateBlockTableItems(PLib);
 Geometry.Calculate([calcbBox]);
 if Geometry.ogsRect.Iter <> 0 then begin
  ogsSelector.Clear;
  ogsSelector.GlobalRect.Assign(Geometry.ogsRect);
 end;
 if Drawer <> nil then begin
 // масштаб еще не вычислен -> только вписывание
  ogsSelector.UpdateRects(FitView or (ogsSelector.GetScale = 0));
  Drawer.RedrawAll;
 end;
end;

procedure TogsMapSpace.AddBlock(Block: TgmfBlock);
begin
 PLib.Add(AnsiString(Block.Name), Block);
end;

procedure TogsMapSpace.AddLineType(LT: TgmfLineType);
begin
 LLib.Add(AnsiString(LT.Name), LT);
end;

procedure TogsMapSpace.CalcPrim(Prim: TogsGeometry);
begin
 If Prim is TogsPoint then Prim.Calculate([calcbBox, calcRelation, calcSquare, calcSortBy]) else
  If Prim is TogsMultiPoint then Prim.Calculate([calcLength, calcbBox]) else
                                 Prim.Calculate([calcRelation, calcSquare, calcbBox]);
end;

function TogsMapSpace.AddPrim(Prim: TogsGeometry): Integer;
begin
// ogsID - часть ключа индекса, назначается до вставки
 if Prim.ogsID = 0 then begin
  Prim.ogsID := fNextOgsID;
  Inc(fNextOgsID);
 end;
 CalcPrim(Prim);
 If Geometry.Count = 0 then ogsSelector.Clear;
 ogsSelector.AddPrim(Prim);
 Result := Geometry.Add(Prim);
 if fUpdateCount = 0 then fPloIndex.InsertPrim(Prim);
end;

function TogsMapSpace.RemovePrim(Prim: TogsGeometry; FreeIt: Boolean): Boolean;
var Index: Integer;
begin
 fPloIndex.RemovePrim(Prim);
 Index := Geometry.Items.IndexOf(Prim);
 Result := Index >= 0;
 if not Result then exit;
 if FreeIt then Geometry.Items.AtFree(Index) else Geometry.Items.Delete(Index);
end;

procedure TogsMapSpace.UpdatePrim(Prim: TogsGeometry);
var Indexed: Boolean;
begin
// удаление до пересчета: ключ индекса - закэшированная площадь примитива
 Indexed := (fUpdateCount = 0) and fPloIndex.RemovePrim(Prim);
 CalcPrim(Prim);
 ogsSelector.AddPrim(Prim);
 if Indexed then fPloIndex.InsertPrim(Prim);
end;

procedure TogsMapSpace.BeginUpdate;
begin
 Inc(fUpdateCount);
end;

procedure TogsMapSpace.EndUpdate;
begin
 if fUpdateCount > 0 then Dec(fUpdateCount);
 if fUpdateCount = 0 then RebuildIndexes;
end;

procedure TogsMapSpace.RebuildIndexes;
begin
 fPloIndex.Rebuild(Geometry);
end;

function TogsMapSpace.SearchPLib(ItemName_: String): TgmfBlock;
begin
 Result := TgmfBlock(PLib.SearchBy(AnsiString(ItemName_)));
end;

function TogsMapSpace.SearchLLib(ItemName_: String): TgmfLineType;
begin
 Result := TgmfLineType(LLib.SearchBy(AnsiString(ItemName_)));
end;

function TogsMapSpace.SearchSLib(ItemName_: String): TgmfHatchStyle;
begin
 Result := SLib.SearchBy(AnsiString(ItemName_)) as TgmfHatchStyle;
end;

// GeoJSON: чтение

function TogsMapSpace.FeatureToPrim(Feature: TJSONObject): TogsGeometry;
var Geom, Coords, Ogs, V: TJSONValue;
    Props: TJSONObject;
    GType, ClassStr, FontName: String;
    FC: TFontCollect;
    I: Integer;
    B: Byte;
    MLine: TogsMultiLineString;
    Block: TgmfBlock;
    P: Pointer;
    TS: TogsTextString;
    JAttribs: TJSONValue;
begin
 Result := nil;
 Geom := Feature.ItemByName['geometry'];
 if not (Geom is TJSONObject) then exit;
 GType := OgsStr(Geom, 'type', '');
 Coords := Geom.ItemByName['coordinates'];
// пользовательская семантика - properties без служебного раздела ogs
 Props := nil;
 Ogs := nil;
 V := Feature.ItemByName['properties'];
 if V is TJSONObject then begin
  Props := JSONCopy(TJSONObject(V));
  Ogs := TJSONObject(V).ItemByName['ogs'];
  if not (Ogs is TJSONObject) then Ogs := nil;
  Props.DeleteItem('ogs');
 end;
 ClassStr := OgsStr(Ogs, 'class', '');
 try
  case ogcProperties.GeometryType(GType) of
   gtPoint: begin
    if (Coords = nil) or (Coords.ItemCount < 2) then exit;
    if (ClassStr = 'TogsTextString') or (ClassStr = 'TogsTextParams') then begin
     FC := nil;
     FontName := OgsStr(Ogs, 'font', '');
     if ogsFontManager.Count > 0 then ogsFontManager.FindBy(FontName, ItalicBold(ContainsText(OgsStr(Ogs, 'fontStyle', ''), 'Bold'), ContainsText(OgsStr(Ogs, 'fontStyle', ''), 'Italic')), FC);
     B := OgsInt(Ogs, 'align', Byte(cDefAlign));
     Result := TogsTextString.Create(ogsSelector, FC, Coords.Item[0].AsFloat, -Coords.Item[1].AsFloat, 0,
                                     OgsFloat(Ogs, 'height', 1), OgsFloat(Ogs, 'angle', 0), OgsFloat(Ogs, 'scale', 1),
                                     TFEAlignments(B), OgsStr(Ogs, 'text', ''), OgsStr(Ogs, 'attr', ''),
                                     HexToColor(OgsStr(Ogs, 'color', ''), 0), OgsBool(Ogs, 'inBlock', False));
     TogsTextString(Result).ogsProperties := Props;
     Props := nil;
    end else
    if (ClassStr = 'TgmfPoint') or (ClassStr = 'TgmfBlock') then begin
     Result := TgmfPoint.CreateJSON(Coords, Props, ogsSelector);
     with TgmfPoint(Result) do begin
      Angle := OgsFloat(Ogs, 'angle', 0);
      Scale := OgsFloat(Ogs, 'scale', 1);
      Color := HexToColor(OgsStr(Ogs, 'color', ''), 0);
      BlockName := OgsStr(Ogs, 'block', '');
      Block := SearchPLib(BlockName);
      gmfBlock := Block;
     // атрибуты вставки: копия текста блока с новым значением
      JAttribs := nil;
      if Ogs <> nil then JAttribs := Ogs.ItemByName['attribs'];
      if (Block <> nil) and (JAttribs is TJSONArray) then
       for I := 0 to JAttribs.ItemCount - 1 do
        if Block.FindAttribute(OgsStr(JAttribs.Item[I], 'attr', ''), P) and (TObject(P) is TogsTextString) then begin
         TS := TogsTextString(P);
         AddAttribute(TogsTextParams.Create(TS, ogsSelector, TS.fFontCollect, TS.fX, TS.fY, TS.Z,
                      TS.fHeight, TS.fAngle, TS.fScale, TS.fAlign, OgsStr(JAttribs.Item[I], 'text', ''),
                      TS.fAttrName, TS.Color, True));
        end;
     end;
    end else
     Result := TogsPoint.CreateJSON(Coords, Props, ogsSelector);
   end;
   gtMultiPoint:
    Result := TogsMultiPoint.CreateJSON(Coords, Props, ogsSelector);
   gtLine, gtLineString:
    if ClassStr = 'TgmfLineString' then begin
     Result := TgmfLineString.CreateJSON(Coords, Props, ogsSelector);
     with TgmfLineString(Result) do begin
      Color := HexToColor(OgsStr(Ogs, 'color', ''), 0);
      LineTypeName := OgsStr(Ogs, 'linetype', '');
      lType := SearchLLib(LineTypeName);
      Width := OgsFloat(Ogs, 'width', 0);
      Scale := OgsFloat(Ogs, 'scale', 1);
     end;
    end else
     Result := TogsLineString.CreateJSON(Coords, Props, ogsSelector);
   gtMultiLineString: begin
    if ClassStr = 'TgmfMultiLineString' then MLine := TgmfMultiLineString.Create(ogsSelector) else MLine := TogsMultiLineString.Create(ogsSelector);
    if Coords <> nil then
     for I := 0 to Coords.ItemCount - 1 do MLine.AddLine(TogsLineString.CreateJSON(Coords.Item[I], nil, ogsSelector));
    MLine.ogsProperties := Props;
    Props := nil;
    if MLine is TgmfMultiLineString then
     with TgmfMultiLineString(MLine) do begin
      Color := HexToColor(OgsStr(Ogs, 'color', ''), 0);
      LineTypeName := OgsStr(Ogs, 'linetype', '');
      LineType := SearchLLib(LineTypeName);
      Width := OgsFloat(Ogs, 'width', 0);
      Scale := OgsFloat(Ogs, 'scale', 1);
     end;
    Result := MLine;
   end;
   gtPolygon:
    if ClassStr = 'TgmfPolygon' then begin
     Result := TgmfPolygon.CreateJSON(Coords, Props, ogsSelector);
     TgmfPolygon(Result).Color := HexToColor(OgsStr(Ogs, 'fill', ''), 0);
     TgmfPolygon(Result).LineColor := HexToColor(OgsStr(Ogs, 'stroke', ''), 0);
    end else
     Result := TogsPolygon.CreateJSON(Coords, Props, ogsSelector);
   gtMultiPolygon:
    if ClassStr = 'TgmfMultiPolygon' then begin
     Result := TgmfMultiPolygon.CreateJSON(Coords, Props, ogsSelector);
     TgmfMultiPolygon(Result).Color := HexToColor(OgsStr(Ogs, 'fill', ''), 0);
     TgmfMultiPolygon(Result).LineColor := HexToColor(OgsStr(Ogs, 'stroke', ''), 0);
    end else
     Result := TogsMultiPolygon.CreateJSON(Coords, Props, ogsSelector);
  end;
 finally
 // CreateJSON создает собственную копию свойств
  Props.Free;
 end;
end;

procedure TogsMapSpace.ReadLineTypes(Value: TJSONValue);
var I, J: Integer;
    Item, Parts, Part: TJSONValue;
    LT: TgmfLineType;
    PS: TLineStruct;
begin
 if not (Value is TJSONArray) then exit;
 for I := 0 to Value.ItemCount - 1 do begin
  Item := Value.Item[I];
  LT := TgmfLineType.Create(ogsSelector, OgsStr(Item, 'name', ''), nil);
  TGeoLine(LT.Sign).idNum := OgsInt(Item, 'id', -1);
  Parts := Item.ItemByName['parts'];
  if Parts is TJSONArray then
   for J := 0 to Parts.ItemCount - 1 do begin
    Part := Parts.Item[J];
    PS := TLineStruct.Create;
    PS.BitOf := AllBits(OgsInt(Part, 'bitOf', 0));
    PS.DrawState := OgsInt(Part, 'drawState', ls_Solid1);
    PS.Param0 := OgsFloat(Part, 'param0', 0);
    PS.Param1 := OgsFloat(Part, 'param1', 0.1);
    PS.Param2 := OgsFloat(Part, 'param2', 0);
    PS.Param3 := OgsFloat(Part, 'param3', 0);
    PS.Param4 := OgsFloat(Part, 'param4', 0);
    PS.Param5 := OgsFloat(Part, 'param5', 0);
    PS.Param6 := OgsFloat(Part, 'param6', 0);
    PS.Param7 := OgsFloat(Part, 'param7', 0);
    PS.Param8 := OgsFloat(Part, 'param8', 0);
    PS.lVorign := OgsFloat(Part, 'lVorign', 0);
    PS.rVOrign := OgsFloat(Part, 'rVorign', 0);
    PS.Color := HexToColor(OgsStr(Part, 'color', ''), 0);
    PS.bkColor := HexToColor(OgsStr(Part, 'bkColor', ''), 0);
    PS.Param4S := AnsiString(OgsStr(Part, 'param4S', ''));
    TGeoLine(LT.Sign).Structura.Add(PS);
   end;
  AddLineType(LT);
 end;
end;

procedure TogsMapSpace.ReadBlocks(Value: TJSONValue);
var I, J: Integer;
    Item, Features: TJSONValue;
    Block: TgmfBlock;
    Prim: TogsGeometry;
begin
 if not (Value is TJSONArray) then exit;
// блоки читаются по порядку: вложенный блок должен быть описан раньше
 for I := 0 to Value.ItemCount - 1 do begin
  Item := Value.Item[I];
  Block := TgmfBlock.Create(ogsSelector, OgsStr(Item, 'name', ''), OgsInt(Item, 'id', 0),
                            OgsFloat(Item, 'x', 0), -OgsFloat(Item, 'y', 0), 0);
  Block.Scale := 1;
  Features := nil;
  if Item.ItemByName['collection'] <> nil then Features := Item.ItemByName['collection'].ItemByName['features'];
  if Features is TJSONArray then
   for J := 0 to Features.ItemCount - 1 do
    if Features.Item[J] is TJSONObject then begin
     Prim := FeatureToPrim(TJSONObject(Features.Item[J]));
     if Prim = nil then continue;
    // габариты блока - в его собственной системе координат (без ogsSelector.AddPrim)
     Prim.Calculate([calcRelation, calcSquare, calcbBox]);
     Block.Geometry.Add(Prim);
    end;
  Block.Geometry.Calculate([calcbBox]);
  AddBlock(Block);
 end;
end;

function TogsMapSpace.LoadGeoJSONString(const jsonStr: String; Append: Boolean): Integer;
var Root, Features: TJSONValue;
    I: Integer;
    Prim: TogsGeometry;
    Wrapper: TJSONObject;
procedure AddFeature(Feature: TJSONValue);
begin
 if not (Feature is TJSONObject) then exit;
 Prim := FeatureToPrim(TJSONObject(Feature));
 if Prim = nil then exit;
 AddPrim(Prim);
 Inc(Result);
end;
begin
 Result := 0;
 Root := JSONParseValue(jsonStr);
 if Root = nil then raise Exception.Create('Ошибка разбора GeoJSON');
 if not Append then Clear;
// массовая загрузка: индексы перестраиваются один раз в EndUpdate
 BeginUpdate;
 try
 // таблицы до примитивов: вставки ссылаются на блоки и типы линий
  ReadLineTypes(Root.ItemByName['ogs:linetypes']);
  ReadBlocks(Root.ItemByName['ogs:blocks']);
  if SameText(OgsStr(Root, 'type', ''), 'FeatureCollection') then begin
   Features := Root.ItemByName['features'];
   if Features is TJSONArray then
    for I := 0 to Features.ItemCount - 1 do AddFeature(Features.Item[I]);
  end else
  if SameText(OgsStr(Root, 'type', ''), 'Feature') then AddFeature(Root) else
  if Root is TJSONObject then begin
  // одиночная геометрия без Feature
   Wrapper := TJSONObject.Create;
   try
    Wrapper.AddPair('type', 'Feature');
    Wrapper.AddPair('geometry', TJSONValue(Root.Clone));
    AddFeature(Wrapper);
   finally
    Wrapper.Free;
   end;
  end;
 finally
  Root.Free;
  EndUpdate;
 end;
 ResolveReferences;
 AssignOgsIDs;
 UpdateObject(True);
end;

function TogsMapSpace.LoadGeoJSON(const FileName: String; Append: Boolean): Integer;
begin
 Result := LoadGeoJSONString(TFile.ReadAllText(FileName, TEncoding.UTF8), Append);
end;

// GeoJSON: запись

function TogsMapSpace.LineTypesToJSON: TJSONArray;
var I, J: Integer;
    LT: TgmfLineType;
    GL: TGeoLine;
    PS: TLineStruct;
    Obj, Part: TJSONObject;
    Parts: TJSONArray;
begin
 Result := TJSONArray.Create;
 for I := 0 to LLib.Count - 1 do begin
  LT := LLibItem[I];
  GL := TGeoLine(LT.Sign);
  Obj := TJSONObject.Create;
  Obj.AddPair('name', LT.Name);
  Parts := TJSONArray.Create;
  if GL <> nil then begin
   Obj.SetInt('id', GL.idNum);
   for J := 0 to GL.Structura.Count - 1 do begin
    PS := TLineStruct(GL.Structura[J]);
    Part := TJSONObject.Create;
    Part.SetInt('bitOf', Ord(PS.BitOf));
    Part.SetInt('drawState', PS.DrawState);
    Part.SetFloat('param0', PS.Param0);
    Part.SetFloat('param1', PS.Param1);
    Part.SetFloat('param2', PS.Param2);
    Part.SetFloat('param3', PS.Param3);
    Part.SetFloat('param4', PS.Param4);
    Part.SetFloat('param5', PS.Param5);
    Part.SetFloat('param6', PS.Param6);
    Part.SetFloat('param7', PS.Param7);
    Part.SetFloat('param8', PS.Param8);
    Part.SetFloat('lVorign', PS.lVorign);
    Part.SetFloat('rVorign', PS.rVOrign);
    Part.SetString('color', ColorToHex(PS.Color));
    Part.SetString('bkColor', ColorToHex(PS.bkColor));
    if PS.Param4S <> '' then Part.SetString('param4S', String(PS.Param4S));
    Parts.AddElement(Part);
   end;
  end;
  Obj.AddPair('parts', Parts);
  Result.AddElement(Obj);
 end;
end;

function TogsMapSpace.BlocksToJSON: TJSONArray;
var I: Integer;
    Block: TgmfBlock;
    Obj: TJSONObject;
    S: String;
    Collection: TJSONValue;
begin
 Result := TJSONArray.Create;
 for I := 0 to PLib.Count - 1 do begin
  Block := PLibItem[I];
  Obj := TJSONObject.Create;
  Obj.AddPair('name', Block.Name);
  Obj.SetInt('id', Block.ID);
  Obj.SetFloat('x', Block.fX);
  Obj.SetFloat('y', -Block.fY);
 // геометрия блока - FeatureCollection в собственной системе координат блока
  GeoJSONToString(Block.Geometry, S);
  Collection := JSONParseValue(S);
  if Collection <> nil then Obj.AddPair('collection', Collection);
  Result.AddElement(Obj);
 end;
end;

function TogsMapSpace.StoreGeoJSON(Stream: TogsStream): Integer;
var I: Integer;
    LTypes, Blocks: TJSONArray;
    Footer: String;
begin
 Result := 0;
 Stream.BeginList('{"type":"FeatureCollection","features":');
 for I := 0 to Geometry.Count - 1 do Inc(Result, Geometry.Item[I].StoreGeoJSON(Stream));
// таблицы - члены верхнего уровня (RFC 7946, 6.1)
 LTypes := LineTypesToJSON;
 Blocks := BlocksToJSON;
 try
  Footer := '';
  if Name <> '' then Footer := Footer + ',"name":' + JSONStr(Name);
  if LTypes.Count > 0 then Footer := Footer + ',"ogs:linetypes":' + LTypes.ToJSON;
  if Blocks.Count > 0 then Footer := Footer + ',"ogs:blocks":' + Blocks.ToJSON;
  Stream.EndList(Footer + '}');
 finally
  LTypes.Free;
  Blocks.Free;
 end;
end;

function TogsMapSpace.SaveGeoJSON(const FileName: String): Integer;
var Stream: TogsStream;
begin
 Stream := TogsStream.CreateFileStream(FileName, fmCreate, ogsSelector);
 try
  Result := StoreGeoJSON(Stream);
 finally
  Stream.Free;
 end;
end;

function TogsMapSpace.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    G: TogsGeometry;
begin
 Result := False;
 Selected := False;
// обратный обход индекса: сначала верхние (точки, линии, мелкие площади)
 For I := fPloIndex.Count - 1 downto 0 do begin
  G := fPloIndex[I];
  Result := G.SelectByPoint(X_, Y_, Params);
  If Result then begin
   Params.resObject := G;
   exit;
  end;
 end;
end;

procedure TogsMapSpace.Draw(Drawer: TogsDrawer);
var Pen:TogsPen; Brush: TogsBrush;
    I: Integer;
    G: TogsGeometry;
begin
 Pen := Drawer.SelectPen(TogsPen.Create(0, 0, nil));
 Brush := Drawer.SelectBrush(TogsBrush.Create(0, nil));
 try
 // во время массового добавления индекс не актуален -> порядок хранения
  if fUpdateCount > 0 then inherited Draw(Drawer) else
  // прямой обход индекса: большие площади снизу, затем линии и точки
   for I := 0 to fPloIndex.Count - 1 do begin
    G := fPloIndex[I];
    if G.Visible(Drawer.ogsSelector.ActiveRect) then G.Draw(Drawer);
   end;
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
 end;
end;

initialization
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsMapSpace, 509, 1));
end.
