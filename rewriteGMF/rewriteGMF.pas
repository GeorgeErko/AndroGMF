unit rewriteGMF;

// Временное чтение GMF исходными модулями GMF (Delphi-Andro\GMF) и перевод
// примитивов в TogsMapSpace (GRAPHER) - по образцу TForm1.btnLoadGMFClick
// (C:\!theGrapher\unit1_.pas). Заменяется копиями объектов GMF (GMF_FORMAT.md).
// Проект: define GMF_READER (без форм FramePropEditor/VarSetForm); модули GMF
// собираются с GRAPHER\ogcBasic, ogcMathUtils и JSON\ogcDrawerSkia, ogcMarker,
// ogcPolyPolyline, ogcCaptureIntf; на Android - SetMultiByteConversionCodePage(1251).

interface uses ogcMapSpace;

// FileName - карта .gmf; AppPath - каталог классификатора (newProcs.MainPath),
// '' - каталог программы (Windows) / документов (Android);
// результат - число примитивов карты
function LoadGMF(Map: TogsMapSpace; const FileName: String; const AppPath: String = ''): Integer;

implementation uses System.SysUtils, System.Classes, System.IOUtils, System.UITypes, System.JSON, dwgtext,
                    ogcBasic, ogcGeometry, ttfGeometry, GMFGeometry, ogcCallbackTypes, ogcLType,
                    Collect, newProcs, newSelector, WPTForm2, WpTwigs, ECLot, EcDot, EcDot2,
                    newBlock, Lib, Lines2, Lines3, textmanager, uExecRegisterClass,
                    gmfReaderDrawer, Writer, newFontScale;

type
 TGmfImport = class
  Map: TogsMapSpace;
  Sel: TSelector;
  Form: TForm2;
  function SignBlock(P: TPoint_Sign): TgmfBlock;
  function GeoBlock(GB: TGeoBlock): TgmfBlock;
  function LineType(GL: Lines3.TGeoLine): TgmfLineType;
  procedure FillBlock(Block: TgmfBlock; Sign: TPoint_Sign; GB: TGeoBlock);
  procedure AddLot(Lot: TLot);
  procedure AddPointDot(PD: TPointDot);
 end;

// цвет GRAPHER - TColor ($00BBGGRR, COLORREF). В GMF цвета двух видов: COLORREF
// (знаки TDWG_*, тексты) и TAlphaColor ($AARRGGBB: RGBToCol, ColorRefToAlpha -
// LotColor, LotLineColor, PointColor); различаются по байту альфы (как ColorRefToAlpha)
function ToColorRef(C: Integer): Integer;
begin
 if (Cardinal(C) shr 24) = 0 then exit(C);
 Result := Integer(((Cardinal(C) shr 16) and $FF) or (Cardinal(C) and $FF00) or ((Cardinal(C) and $FF) shl 16));
end;

// блок, заполняемый событиями TGeometryEvents (DrawTo знака/блока GMF)
var CurBlock: TgmfBlock = nil;

procedure BlockPoly(Obj: Integer; Poly: Lib.PGeoPoint; penColor, brushColor: Integer; lineWidth: Double; useColor: Boolean; isPolygon: Boolean); stdcall;
begin
 if CurBlock <> nil then CurBlock.PolyEvent(ogcCallbackTypes.PGeoPoint(Poly), ToColorRef(penColor), ToColorRef(brushColor), lineWidth, useColor, isPolygon);
end;

procedure BlockText(Obj: Integer; X, Y: Double; FontName: PChar; txtHeight, txtAngle, txtScale: Double;
                    txtColor: Integer; Align: Byte; Bl, It, Un: Boolean; Text, AttrName: PChar); stdcall;
begin
 if CurBlock <> nil then CurBlock.TextEvent(X, Y, String(FontName), txtHeight, txtAngle, txtScale, ToColorRef(txtColor), Align, Bl, It, Un, String(Text), String(AttrName));
end;

function SearchPointSign(PC: TSortedCollection; Num: Integer): TPoint_Sign;
var Index: Integer;
begin
 Result := nil;
 if PC = nil then exit;
 Index := SearchThis(PC, Num);
 if Index <> -1 then Result := PC[Index];
end;

function SearchLineType(PC: TSortedCollection; Num: Integer): Lines3.TGeoLine;
var Index: Integer;
begin
 Result := nil;
 if PC = nil then exit;
 Index := SearchLine(PC, Num);
 if Index <> -1 then Result := PC[Index];
end;

// текст (шаблон атрибута) условного знака по имени атрибута
function SignText(PZ: TPoint_Sign; const Name: String): TDWG_Text;
var I: Integer;
    M: TMeth;
begin
 Result := nil;
 if (PZ = nil) or (PZ.MethodCol = nil) then exit;
 for I := 0 to PZ.MethodCol.Count - 1 do begin
  M := PZ.MethodCol[I];
  if (M.MT = m_Text) and (AnsiCompareText(String(TDWG_Text(M.PT).FName), Name) = 0) then exit(TDWG_Text(M.PT));
 end;
end;

function FontOf(const Name: String; Bl, It: Boolean): TFontCollect;
begin
 Result := nil;
 if ogsFontManager.Count > 0 then ogsFontManager.FindBy(Name, ItalicBold(Bl, It), Result);
 if Result <> nil then Result.LoadModeComplete;
end;

// параметры по классификатору: без классификатора (ClassHandle = nil) функции
// TLot/TPointDot обращаются к nil - значения по умолчанию
function LotFill(Lot: TLot): Integer;
begin
 if Lot.ClassHandle <> nil then Result := ToColorRef(Lot.LotColor) else Result := Integer(TColors.Gray);
end;

function LotLine(Lot: TLot): Integer;
begin
 if Lot.ClassHandle <> nil then Result := ToColorRef(Lot.LotLineColor) else Result := Integer(TColors.Black);
end;

function LotLineZnak(Lot: TLot): Integer;
begin
 if Lot.ClassHandle <> nil then Result := Lot.csLineZnak else Result := -1;
end;

function LotKoef(Lot: TLot): Double;
begin
 if Lot.ClassHandle <> nil then Result := Lot.CsKoef else Result := 1;
 if Result <= 0 then Result := 1;
end;

function PointColorOf(PD: TPointDot): Integer;
begin
 if PD.ClassHandle <> nil then Result := ToColorRef(PD.PointColor) else Result := Integer(TColors.Black);
end;

// выравнивание значения атрибута (AlignX/AlignY = -1 - как у текста знака),
// коды - как TDWG_Text.TextAlign / AlignText
function ParamAlign(TP: TTextParams; Def: TFEAlignments): TFEAlignments;
var B: Byte;
begin
 Result := Def;
 if (TP.AlignX = -1) or (TP.AlignY = -1) then exit;
 B := 0;
 if TP.AlignX = 0 then B := 1 else if TP.AlignX = 0.5 then B := 5 else if TP.AlignX = 1 then B := 9;
 if B = 0 then exit;
 if TP.AlignY = 0.5 then Inc(B) else if TP.AlignY = 1 then Inc(B, 2) else if TP.AlignY <> 0 then exit;
 Result := AlignText(B);
end;

// системные свойства примитива (как в gmflib): {"System": {...}}
function SysRoot(out Sys: TJSONObject): TJSONObject;
begin
 Result := TJSONObject.Create;
 Sys := TJSONObject.Create;
 Result.AddPair('System', Sys);
end;

procedure SetSys(Prim: TogsGeometry; Root: TJSONObject);
begin
 try
  Prim.CreateSysProperties(Root.ToJSON);
 finally
  Root.Free;
 end;
end;

{ TGmfImport }

procedure TGmfImport.FillBlock(Block: TgmfBlock; Sign: TPoint_Sign; GB: TGeoBlock);
var Geometry: TGeometryEvents;
    I: Integer;
begin
 CurBlock := Block;
 Geometry := TGeometryEvents.Create(0, BlockPoly, BlockText);
 try
  if Sign <> nil then Sign.DrawTo(Geometry) else GB.DrawTo(Geometry);
 finally
  Geometry.Free;
  CurBlock := nil;
 end;
// тексты условного знака - шаблоны атрибутов: GMF рисует их только у точки с
// менеджером надписей (TPointDot.Draw32: ShowAttr2 = TextManager <> nil), значениями
// точки (TTextManager.UpdateText). В блоке - пустой текст, значения подставляют
// атрибуты точки (TogsTextParams.KeepObject)
 if Sign <> nil then
  for I := 0 to Block.Geometry.Count - 1 do
   if Block.Geometry.Item[I] is TogsTextString then
    with TogsTextString(Block.Geometry.Item[I]) do begin
     fText := '';
     CalculateText;
    end;
// габариты блока - в его собственной системе координат (как TogsMapSpace.ReadBlocks)
 for I := 0 to Block.Geometry.Count - 1 do Block.Geometry.Item[I].Calculate([calcRelation, calcSquare, calcbBox]);
 Block.Geometry.Calculate([calcbBox]);
 Block.Scale := 1;
 Map.AddBlock(Block);
end;

// условный знак классификатора -> блок (имя блока - имя знака)
function TGmfImport.SignBlock(P: TPoint_Sign): TgmfBlock;
var Name: String;
begin
 Result := nil;
 if P = nil then exit;
 Name := String(PAnsiChar(@P.MyNameIs[0]));
 Result := Map.SearchPLib(Name);
 if Result <> nil then exit;
 Result := TgmfBlock.Create(Map.ogsSelector, Name, P.MyInd, P.X, P.Y, 0);
 FillBlock(Result, P, nil);
end;

// блок карты; в точке может быть только ссылка по имени (Check = 1, без TwgForm)
function TGmfImport.GeoBlock(GB: TGeoBlock): TgmfBlock;
var Index: Integer;
    Real: TGeoBlock;
begin
 Result := nil;
 if GB = nil then exit;
 Result := Map.SearchPLib(String(GB.Name));
 if Result <> nil then exit;
 Real := GB;
 if (GB.TwgForm = nil) and (Form.Twigs.BlockList <> nil) then Real := TGeoBlock(Form.Twigs.BlockList.BlockByName(GB.Name, Index));
 if (Real = nil) or (Real.TwgForm = nil) then exit;
 Result := TgmfBlock.Create(Map.ogsSelector, String(Real.Name), -1, Real.X, Real.Y, 0);
 FillBlock(Result, nil, Real);
end;

// тип линии классификатора; части bt_Custom - блоки знаков (Param4S - имя блока)
function TGmfImport.LineType(GL: Lines3.TGeoLine): TgmfLineType;
var Name: String;
    I: Integer;
    PS: Lines3.TLineStruct;
    NS: ogcLType.TLineStruct;
    Block: TgmfBlock;
begin
 Result := nil;
 if GL = nil then exit;
 Name := String(PAnsiChar(@GL.NameOf[0]));
 Result := Map.SearchLLib(Name);
 if Result <> nil then exit;
 Result := TgmfLineType.Create(Map.ogsSelector, Name, nil);
 ogcLType.TGeoLine(Result.Sign).idNum := GL.IdNum;
 for I := 0 to GL.Structura.Count - 1 do begin
  PS := GL.Structura.At(I);
  NS := ogcLType.TLineStruct.Create;
  NS.BitOf := ogcLType.AllBits(Ord(PS.BitOf));
  NS.DrawState := PS.DrawState;
  NS.Param0 := PS.Param0; NS.Param1 := PS.Param1; NS.Param2 := PS.Param2;
  NS.Param3 := PS.Param3; NS.Param4 := PS.Param4; NS.Param5 := PS.Param5;
  NS.Param6 := PS.Param6; NS.Param7 := PS.Param7; NS.Param8 := PS.Param8;
  NS.lVorign := PS.lVorign; NS.rVOrign := PS.rVOrign;
  NS.Color := PS.Color; NS.bkColor := PS.bkColor;
  if PS.BitOf = Lines3.bt_Custom then begin
   Block := SignBlock(SearchPointSign(Sel.GPointCol, Round(PS.Param4)));
   if Block <> nil then NS.Param4S := AnsiString(Block.Name);
  end;
  ogcLType.TGeoLine(Result.Sign).Structura.Add(NS);
 end;
 Map.AddLineType(Result);
end;

procedure TGmfImport.AddLot(Lot: TLot);
var J, K: Integer;
    LT: TgmfLineType;
    MLine: TgmfMultiLineString;
    Line: TogsLineString;
    GLine: TgmfLineString;
    PolyS: TPoly_Single;
    Polygon: TgmfPolygon;
    Twig: TTwig;
    Znak: Integer;
    Root, Sys: TJSONObject;
begin
 Lot.InsClipDotsParall(Form.Twigs);
 if Lot.Points = nil then exit;
// Points - новые точки на каждый вызов InsClipDotsParall, TLot их не освобождает
 try
  if Lot.TypeLot = 1 then begin
  // линейный: тип линии из классификатора, масштаб типа линии - CsKoef
   LT := nil;
   Znak := LotLineZnak(Lot);
   if Znak <> -1 then LT := LineType(SearchLineType(Sel.GLineCol, Znak));
   Root := SysRoot(Sys);
   Sys.AddPair('Color', TJSONNumber.Create(LotLine(Lot)));
   Sys.AddPair('Sign', TJSONNumber.Create(Znak));
   if Lot.Coord.Count > 1 then begin
    MLine := TgmfMultiLineString.Create(Map.ogsSelector);
    SetSys(MLine, Root);
    MLine.Color := LotLine(Lot);
    MLine.LineType := LT;
    MLine.Scale := LotKoef(Lot);
    for J := 0 to Lot.Coord.Count - 1 do begin
     Twig := Lot.GetTwig(Form.Twigs, J);
     if Twig = nil then continue;
     Line := TogsLineString.Create(Map.ogsSelector);
     for K := 0 to Twig.Coord.Count - 1 do with TDot(Twig.Coord[K]) do Line.AddPoint(XDot, YDot, 0);
     MLine.AddLine(Line);
    end;
    Map.AddPrim(MLine);
   end else begin
    if Lot.Points.Count < 2 then begin Root.Free; exit; end;
    GLine := TgmfLineString.Create(Map.ogsSelector);
    SetSys(GLine, Root);
    GLine.Color := LotLine(Lot);
    GLine.lType := LT;
    GLine.Scale := LotKoef(Lot);
    for J := 0 to Lot.Points.Count - 1 do with TDot(Lot.Points[J]) do GLine.AddPoint(XDot, YDot, 0);
    Map.AddPrim(GLine);
   end;
  end else begin
  // площадной
   if Lot.Points.Count < 3 then exit;
   PolyS := TPoly_Single.Create(Map.ogsSelector);
   for J := 0 to Lot.Points.Count - 1 do with TDot(Lot.Points[J]) do PolyS.AddPoint(XDot, YDot, 0);
   Polygon := TgmfPolygon.Create(Map.ogsSelector);
   Polygon.AddPolygon(PolyS);
   Root := SysRoot(Sys);
   Sys.AddPair('Color', TJSONNumber.Create(LotFill(Lot)));
   SetSys(Polygon, Root);
   Polygon.Color := LotFill(Lot);
   Polygon.LineColor := LotLine(Lot);
   Map.AddPrim(Polygon);
  end;
 finally
  FreeAndNil(Lot.Points);
 end;
end;

procedure TGmfImport.AddPointDot(PD: TPointDot);
var DT: TDotText;
    FV: TFontViewEx;
    TS: TogsTextString;
    Point: TgmfPoint;
    Block: TgmfBlock;
    I: Integer;
    P: Pointer;
    TP: TTextParams;
    TM: TTextManager;
    PZ: TPoint_Sign;
    Txt: TDWG_Text;
    Name, FontName: String;
    H: Double;
    Root, Sys: TJSONObject;
begin
 if PD is TDotText then begin
 // текст
  DT := TDotText(PD);
  if DT.Text = nil then exit;
  FV := DT.Text.fontView;
  if FV <> nil then FontName := String(FV.FontName) else FontName := '';
  if FV <> nil then TS := TogsTextString.Create(Map.ogsSelector, FontOf(FontName, FV.bl = 1, FV.it = 1), DT.XDot, DT.YDot, 0,
                                                DT.Text.Height, DT.Ugol, DT.XKoef, AlignText(DT.Text.Align), String(DT.Text.Text),
                                                String(DT.Text.AttrName), ToColorRef(DT.Text.Color), False)
  else TS := TogsTextString.Create(Map.ogsSelector, nil, DT.XDot, DT.YDot, 0,
                                   DT.Text.Height, DT.Ugol, DT.XKoef, AlignText(DT.Text.Align), String(DT.Text.Text),
                                   String(DT.Text.AttrName), ToColorRef(DT.Text.Color), False);
  Root := SysRoot(Sys);
  Sys.AddPair('Color', TJSONNumber.Create(ToColorRef(DT.Text.Color)));
  Sys.AddPair('Text', String(DT.Text.Text));
  Sys.AddPair('FontName', FontName);
  SetSys(TS, Root);
  Map.AddPrim(TS);
  exit;
 end;
 Point := TgmfPoint.Create(PD.XDot, PD.YDot, PD.Z, Map.ogsSelector);
 Point.Color := PointColorOf(PD);
 Point.Angle := PD.Ugol;
 Root := SysRoot(Sys);
 Sys.AddPair('Color', TJSONNumber.Create(Point.Color));
 if PD.userObj is TGeoBlock then begin
 // вставка блока: значения атрибутов - свойства точки (TGeoBlock.txtProperties)
  Block := GeoBlock(TGeoBlock(PD.userObj));
  Point.Scale := PD.XKoef;
  Sys.AddPair('Block', String(TGeoBlock(PD.userObj).Name));
  if (Block <> nil) and (PD.Properties <> nil) then
   for I := 0 to PD.Properties.Count - 1 do
    if Block.FindAttribute(String(PD.Properties[I].PropName), P) and (TObject(P) is TogsTextString) then begin
     TS := TogsTextString(P);
     Point.AddAttribute(TogsTextParams.Create(TS, Map.ogsSelector, TS.fFontCollect, TS.fX, TS.fY, TS.Z,
                        TS.fHeight, TS.fAngle, TS.fScale, TS.fAlign, String(PD.Properties[I].PropValue.Value),
                        TS.fAttrName, TS.Color, True));
    end;
 end else begin
 // условный знак: значения атрибутов - менеджер надписей точки (TTextManager.UpdateText:
 // значение замещает текст знака - положение FDx/FDy в координатах знака, высота FH
 // (-1 - как у знака), угол FUgol, выравнивание AlignX/AlignY; ShiftX/ShiftY - сдвиг в пикселях)
  PZ := SearchPointSign(Sel.GPointCol, PD.GetZnak);
  Block := SignBlock(PZ);
  Point.Scale := PD.Koef;
  Sys.AddPair('Sign', TJSONNumber.Create(PD.GetZnak));
  TM := PD.TextManager;
  if (Block <> nil) and (TM <> nil) and (TM.FValues <> nil) and Sel.GGraphSet.ShowAttributes then
   for I := 0 to TM.FValues.Count - 1 do begin
   // имена атрибутов: после построения по классификатору (AfterLoad) - тексты знака
   // FTexts, FValues в их порядке, FVars = nil; иначе - имена из файла (FVars)
    if (TM.FTexts <> nil) and (I < TM.FTexts.Count) then Txt := TM.FTexts[I] else
    if (TM.FVars <> nil) and (I < TM.FVars.Count) then Txt := SignText(PZ, String(TM.FVars[I])) else continue;
    if Txt <> nil then Name := String(Txt.FName) else Name := String(TM.FVars[I]);
   // текст знака невидимый (FVisible = False) - TDWG_Text.Draw32 не рисует и значение точки
    if (Txt <> nil) and not Txt.FVisible then continue;
    if not (Block.FindAttribute(Name, P) and (TObject(P) is TogsTextString)) then continue;
    TS := TogsTextString(P);
    TP := TTextParams(TM.FValues[I]);
    H := TP.FH;
    if H <= 0 then H := TS.fHeight;
    Point.AddAttribute(TogsTextParams.Create(TS, Map.ogsSelector, TS.fFontCollect, TP.FDx, TP.FDy, 0,
                       H, TP.FUgol, TS.fScale, ParamAlign(TP, TS.fAlign), String(TP.FValue), TS.fAttrName, TS.Color, True));
   end;
 end;
 SetSys(Point, Root);
 if Block <> nil then begin
  Point.gmfBlock := Block;
  Point.BlockName := Block.Name;
 end;
 Map.AddPrim(Point);
end;

function LoadGMF(Map: TogsMapSpace; const FileName: String; const AppPath: String): Integer;
var Imp: TGmfImport;
    Drawer: TgmfReaderDrawer;
    Stream: TBufStream;
    Obj: TObject;
    I: Integer;
    B: Byte;
    PP: TPointDot;
    Lot: TLot;
begin
 Result := 0;
 if not FileExists(FileName) then raise Exception.Create('Файл не найден: ' + FileName);
 RegPrimitives;
// MainPath - каталог классификатора карты (MainPath + About.ClassName)
 if AppPath <> '' then newProcs.MainPath := AnsiString(IncludeTrailingPathDelimiter(AppPath)) else
{$IFDEF ANDROID}
  newProcs.MainPath := AnsiString(IncludeTrailingPathDelimiter(TPath.GetDocumentsPath));
{$ELSE}
  newProcs.MainPath := AnsiString(ExtractFilePath(ParamStr(0)));
{$ENDIF}
 Imp := TGmfImport.Create;
// Selector GMF с невизуальным рисователем (примитивы берут область окна у Drawer)
 Drawer := TgmfReaderDrawer.CreateSize(1024, 1024);
 Imp.Sel := TSelector.Create(Drawer);
 Imp.Map := Map;
 try
  Stream := TBufStream.InitFileStream(AnsiString(FileName), fmOpenRead);
  try
   Stream.Selector := Imp.Sel;
   Obj := Stream.Get;
  finally
   Stream.Free;
  end;
  if not (Obj is TForm2) then begin
   Obj.Free;
   raise Exception.Create('Файл не является картой GMF: ' + FileName);
  end;
  Imp.Form := TForm2(Obj);
  try
   WriteIn(['rewriteGMF: Lots=', Imp.Form.Twigs.LotsCount, ' Twigs=', Imp.Form.Twigs.TwigsCount, ' Any=', Imp.Form.Twigs.AnyCount]);
  // окружение Selector после загрузки - как в TMainFormSkia.OpenGmfFileSkia
   with Imp.Sel do begin
    if Imp.Form.MkLib <> nil then begin
     GLineCol := Imp.Form.MkLib.LSLib;
     GSqwearCol := Imp.Form.MkLib.SSLib;
     GPointCol := Imp.Form.MkLib.PSLib;
    end;
    GFontCollect := Imp.Form.Twigs.FontS;
    GFontSet := Imp.Form.Twigs.FontSet;
    GGraphSet := Imp.Form.fGraphSet;
   end;
  // связи с классификатором (ClassHandle, надписи знаков) - как в gmflib; без
  // классификатора (MkLib = nil) - значения по умолчанию (LotFill, PointColorOf...)
   if Imp.Form.MkLib <> nil then Imp.Form.ClassBuildII;
   if Imp.Form.FontColEx <> nil then
    for I := 0 to Imp.Form.Twigs.AnyCount - 1 do begin
     PP := Imp.Form.Twigs.AAt(I, B);
     PP.ResetParams(param_idResetFontView, Imp.Form.FontColEx);
    end;
  // перевод в GRAPHER
   Map.Clear;
   Map.BeginUpdate;
   try
  // отбор - как при рисовании в AndroGMF (TMainFormSkia, TPointDot.Draw32):
  // контур удаленный (TypeLot = 254) или слоя, выключенного в таблице слоев
  // (ClassHandle.Check = 0) - не выводится
    for I := 0 to Imp.Form.Twigs.LotsCount - 1 do begin
     Lot := Imp.Form.Twigs.LAt(I);
     if (Lot = nil) or (Lot.TypeLot = 254) then continue;
     if (Lot.ClassHandle <> nil) and (Lot.ClassHandle.Check = 0) then continue;
     Imp.AddLot(Lot);
    end;
  // точки: только TWG_Point; слой выключен или SqlClosed (Closed) - не выводится;
  // условный знак без класса (Code = -1 или ClassHandle = nil) GMF не рисует
    for I := 0 to Imp.Form.Twigs.AnyCount - 1 do begin
     PP := Imp.Form.Twigs.AAt(I, B);
     if (PP = nil) or (B <> TWG_Point) or PP.Closed then continue;
     if not (PP is TDotText) and not (PP.userObj is TGeoBlock) and ((PP.Code = -1) or (PP.ClassHandle = nil)) then continue;
     Imp.AddPointDot(PP);
    end;
   finally
    Map.EndUpdate;
   end;
   Map.UpdateObject(True);
   Result := Map.Geometry.Count;
   WriteIn(['rewriteGMF: примитивов ', Result, ' блоков ', Map.PLib.Count, ' типов линий ', Map.LLib.Count]);
  finally
   Imp.Form.Free;
  end;
 finally
  Imp.Sel.Free;
  Drawer.Free;
  Imp.Free;
 end;
end;

end.
