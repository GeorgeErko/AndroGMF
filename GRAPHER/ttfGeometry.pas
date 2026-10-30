unit ttfGeometry;

interface

uses Classes, SysUtils, Types, System.UITypes, System.Skia,
     System.Generics.Collections, System.JSON, ogcBasic, ogcGeometry;

// Векторные TTF/OTF-шрифты: контуры глифов строятся средствами Skia
// (ISkFont.GetPath) и хранятся как мультиполигоны TFontSymbol.
// Координаты глифа - единицы шрифта при размере cFontUnits:
// X вправо, Y вниз (как во всей иерархии), Y = 0 - верх глифа (bearingY),
// базовая линия глифа - Y = Metrics.bearingY.

const
// размер шрифта Skia, задающий единицы координат глифов
  cFontUnits = 1024;

type
  TFEAlignment = (ftaLeft, ftaCenter, ftaRight, ftaJustify, ftaTop,
                  ftaVerticalCenter, ftaBaseline, ftaBottom);
  TFEAlignments = set of TFEAlignment;
  TFEStyle = (ftsBold, ftsItalic);
  TFEStyles = set of TFEStyle;

  { TCharPosition - позиция символа строки (в единицах шрифта, Y вниз) }

  TCharPosition = record
   x, width: Double;
   yTop, yBase, yBottom: Double;
  end;
  ArrayOfCharPosition = array of TCharPosition;

  { TGlyphMetrics - метрики глифа в единицах шрифта }

  TGlyphMetrics = record
   bBox: TRectF;         // габариты контура (Skia: Y вниз, базовая линия Y = 0)
   bearingX: Double;     // от точки привязки до левого края контура
   bearingY: Double;     // от базовой линии до верха контура
   horiAdvance: Double;  // шаг до следующего символа
  end;

  TogsTextString = class;

  { TFontSymbol - глиф шрифта как мультиполигон }

  TFontSymbol = class(TogsMultiPolygon)
  private
   fBounds: TRectF;
   fRect: TRectF;
  public
   fSymbol: Char;
   fIndex: Integer; // индекс глифа в шрифте
  //
   Metrics: TGlyphMetrics;
   advLine: TRectF;  // точка привязки (Left, Top) и шаг (Right) глифа
  //
   nullSymbol: TFontSymbol;
   constructor Create(Selector_: TogsSelector; Font_: ISkFont; GlyphIndex_: Word;
                      nullSymbol_: TFontSymbol);
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   property Bounds: TRectF read fBounds;
   property Rect: TRectF read fRect;
  end;

  { TFontCollect - шрифт и кэш его глифов }

  TLoadMode = (lmIncomplete, lmComplete);

  TFontCollect = class(TogsGeometryCollection)
  private
  // режим загрузки шрифта:
  //  lmIncomplete - загружены заголовки шрифта
  //  lmComplete   - вычислены метрики, глифы создаются по запросу
   fFileName: String;
   fFontName: String;
   fStyle: TFEStyles;
   fTypeface: ISkTypeface;
   fFont: ISkFont;
   fMetrics: TSkFontMetrics;
   fHeight: Integer; // высота символа: Ascent + Descent
   fbtmHeight: Integer; // высота над базовой линией: Ascent
   fGlyphs: TDictionary<Word, TFontSymbol>;
   fNullSymbol: TFontSymbol;
   function GetSymbol(Index: Integer): TFontSymbol;
   function GetStyleAsString: String;
  public
   fLoadMode: TLoadMode;
   constructor Create(Selector_: TogsSelector; FileName_: String; Mode: TLoadMode);
   destructor Destroy; override;
   procedure LoadModeComplete;
  //
   property Symbol[Index: Integer]: TFontSymbol read GetSymbol; default;
  // Поиск символа по коду Unicode
   function CharIndex(CharCode: Integer): Integer;
   function SymbolByIndex(CharCode: Integer): TFontSymbol;
  // позиции символов строки с учетом выравнивания и переводов строк
   function CharsPosition(const Text: String; Align: TFEAlignments): ArrayOfCharPosition;
  //
   property FileName: String read fFileName;
   property FontName: String read fFontName;
   property Style: TFEStyles read fStyle;
   property StyleAsString: String read GetStyleAsString;
   property SkTypeface: ISkTypeface read fTypeface;
   property SkFont: ISkFont read fFont;
  // коэффициент для вывода текста
   function ScaleOf(Height: Double): Double;
  end;

  { TogsSymbol - точка привязки глифа в строке }

  TogsSymbol = class(TogsPoint)
   fChar: PChar;
   fSymbol: TFontSymbol;
   constructor Create(Selector: TogsSelector; X_, Y_, Z_: Double; Char_: PChar; Symbol_: TFontSymbol);
  // расчет
   function Calculate(Action: TCalcActionSet): Integer; override;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  end;

  { TogsTextString }

  TogsTextString = class(TogsPoint)
  private
   fColorBy: TColorBy;
   fColor: TColor;
   function GetSymbol(Index: Integer): TogsSymbol;
   function GetAttribute: String; override;
   procedure SetAttribute(AttrName_: String); override;
   procedure SetColorBy(AValue: TColorBy); override;
   function GetColorBy: TColorBy; override;
   function GetColor: TColor; override;
   procedure SetColor(AValue: TColor); override;
  public
   fFontCollect: TFontCollect;
   fText: String;
   fSymbols: TogsGeometryCollection;
   ABC: ArrayOfCharPosition;
  // параметры вывода
   fHeight : Double;
   fAngle  : Double;
   fScale  : Double;
   fAlign  : TFEAlignments;
  //
   fAttrName: String; // имя атрибута в блоке
   fBlock: boolean;
  // временно в виде переменных, !!! необходимо реализовать в виде свойств
   constructor Create(Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_,
    Z_: Double; Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
    AttrName_: String; TextColor: Integer; InBlock: Boolean=False);
   constructor CreateAs(ogsObject: TogsBasic); override;
   destructor Destroy; override;
   constructor Load(Stream: TogsStream); override;
   procedure Store(Stream: TogsStream); override;
   function Assign(ogsObject: TogsBasic): Boolean; override;
  // расчет расстановки текста
   procedure CalculateText;
   procedure AddSymbol(X_,Y_: Double; Char_: PChar; Symbol: TFontSymbol);
  //
   function Count: Integer;
   property Symbol[Index: Integer]: TogsSymbol read GetSymbol; default;
  // расчет
   function Calculate(Action: TCalcActionSet): Integer; override;
  // рисование
   procedure Draw(Drawer: TogsDrawer); override;
  // захват
   function SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean; override;
  // GeoJSON: текст и параметры вывода в properties."ogs"
   function FeatureProperties: TJSONObject; override;
  end;

  { TogsTextParams }

  TogsTextParams = class(TogsTextString)
   fKeepObject: Boolean; // признак объекта - копии
  // KeepObject - объект для временного хранения полей TextString
  // которые замещаются атрибутами Self в блоке для:
  //                                    отрисовки, захвата, вычисления шабаритов
   KeepString : TogsTextParams;
   TextString : TogsTextString;
  // данный конструктор используется для создания объекта -> копии TogsTExtString
  // для временного сохранения полей оригинального объекта
   constructor CreateEmpty; override;
   constructor Create(TextString_: TogsTextString;
               Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_,
               Z_: Double; Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
               AttrName_: String; TextColor: Integer; InBlock: Boolean=False);
  // функция не создает копии полей -> объектов-указателей
  // применяется для копирования полей объекта, для
  // временного хранения их в KeepString
   function Assign(ogsObject:TogsBasic): boolean; override;
   procedure KeepObject;
   procedure ReleaseObject;
  //
   function isKeepObject: Boolean; override;
  end;

  { TTextAttribs }

  TTextAttribs = class(TogsCollection)
  private
   function GetAttr(Index: Integer): TogsTextParams;
  public
   constructor Create;
   constructor CreateAs(ogsObject: TogsBasic); override;
   constructor Load(Stream: TogsStream); override;
   function FindAttr(AttrName: String; CI: boolean): TogsTextParams;
   property Attr[Index: Integer]: TogsTextParams read GetAttr; default;
   procedure KeepObject;
   procedure ReleaseObject;
  end;

  { TFontItem }

  TFontItem = class(TogsBasic)
   fileName: String;
   fontName: String;
   fontStyle: TFEStyles;
   fontStyles: String;
   fontCollect: TFontCollect;
   Constructor Create(Selector: TogsSelector; fileName_: String);
   destructor Destroy; override;
  end;

  { TogsFontManager - класс для загрузки шрифтов из папки Fonts }

  TogsFontManager = class(TogsSortedCollection)
  private
   // незагруженные ttf - файлы
   ErrorList: TStrings;
   function GetItem(Index: Integer): TFontItem;
  public
   constructor Create;
   destructor Destroy; override;
  // FontsPath = '' -> папка Fonts рядом с exe (Windows) или в Documents (Android)
   function LoadFontList(Selector: TogsSelector; FontsPath: String = ''): Integer;
   function LoadFontFile(Selector: TogsSelector; const FileName: String): Integer;
   property Item[Index: Integer]: TFontItem read GetItem;
   property Errors: TStrings read ErrorList;
  //
   function FindBy(fontName: String; fontStyle: TFEStyles; var FC: TFontCollect): Integer;
  end;

  var ogsFontManager: TogsFontManager;

  function CompareFontItemProc(Item1, Item2: Pointer): Integer;
// выравнивание текста GMF (0..11) и стиль шрифта
  function AlignText(B: Byte): TFEAlignments;
  function ItalicBold(Bl, It: Boolean): TFEStyles;

implementation uses System.IOUtils, System.Math, System.Character, ogcProperties,
     Writer;

function AlignText(B: Byte): TFEAlignments;
begin
 case B of
  0 : Result:= [ftaLeft, ftaBottom];
  1 : Result:= [ftaLeft, ftaBaseLine];
  2 : Result:= [ftaLeft, ftaVerticalCenter];
  3 : Result:= [ftaLeft, ftaTop];
  4 : Result:= [ftaCenter, ftaBottom];
  5 : Result:= [ftaCenter, ftaBaseLine];
  6 : Result:= [ftaCenter, ftaVerticalCenter];
  7 : Result:= [ftaCenter, ftaTop];
  8 : Result:= [ftaRight, ftaBottom];
  9 : Result:= [ftaRight, ftaBaseLine];
  10: Result:= [ftaRight, ftaVerticalCenter];
  11: Result:= [ftaRight, ftaTop];
 else
  Result:= [ftaLeft, ftaBaseLine];
 end;
end;

function ItalicBold(Bl, It: Boolean): TFEStyles;
begin
 Result := [];
 if It then Result:= Result + [ftsItalic];
 if Bl then Result:= Result + [ftsBold];
end;

function CompareFontItemProc(Item1, Item2: Pointer): Integer;
begin
 If TFontItem(Item1).fontName < TFontItem(Item2).fontName then Result:= -1 else
 If TFontItem(Item1).fontName > TFontItem(Item2).fontName then Result:= 1
  else
 If TFontItem(Item1).fontStyles < TFontItem(Item2).fontStyles then Result := -1 else
 If TFontItem(Item1).fontStyles > TFontItem(Item2).fontStyles then Result := 1
  else
 If TFontItem(Item1).fileName < TFontItem(Item2).fileName then Result := -1 else
 If TFontItem(Item1).fileName > TFontItem(Item2).fileName then Result := 1
  else
   Result := 0;
end;

{ TFontItem }

constructor TFontItem.Create(Selector: TogsSelector; fileName_: String);
begin
 fileName := fileName_;
 if fileName <> '' then begin
  fontCollect := TFontCollect.Create(Selector, fileName, lmIncomplete);
  fontName := fontCollect.FontName;
  fontStyle:= fontCollect.Style;
  fontStyles := fontCollect.StyleAsString;
 end;
end;

destructor TFontItem.Destroy;
begin
 fontCollect.Free;
 inherited Destroy;
end;

{ TogsFontManager }

constructor TogsFontManager.Create;
begin
 inherited Create(CompareFontItemProc, True);
 ErrorList := TStringList.Create;
end;

destructor TogsFontManager.Destroy;
begin
 inherited Destroy;
 ErrorList.Free;
end;

function TogsFontManager.GetItem(Index: Integer): TFontItem;
begin
 Result := List[Index];
end;

function TogsFontManager.LoadFontFile(Selector: TogsSelector; const FileName: String): Integer;
begin
 Result := -1;
 try
  Result := Add(TFontItem.Create(Selector, FileName));
 except
  on E: Exception do ErrorList.Add(FileName + ': ' + E.Message);
 end;
end;

function TogsFontManager.LoadFontList(Selector: TogsSelector; FontsPath: String): Integer;
var FileList: TStringDynArray;
    I: Integer;
begin
 Result := 0;
 if FontsPath = '' then
 {$IFDEF ANDROID}
  FontsPath := TPath.Combine(TPath.GetDocumentsPath, 'Fonts');
 {$ELSE}
  FontsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Fonts');
 {$ENDIF}
 if not TDirectory.Exists(FontsPath) then exit;
 FileList := TDirectory.GetFiles(FontsPath, '*.*', TSearchOption.soTopDirectoryOnly);
 for I := 0 to High(FileList) do
  if SameText(ExtractFileExt(FileList[I]), '.ttf') or SameText(ExtractFileExt(FileList[I]), '.otf') then begin
   LoadFontFile(Selector, FileList[I]);
   Inc(Result);
  end;
 WriteIn(['Fonts.Count=', Result, ' Errors=', ErrorList.Count]);
end;

function TogsFontManager.FindBy(fontName: String; fontStyle: TFEStyles; var FC: TFontCollect): Integer;
var I: Integer;
begin
 Result := -1;
 If Count = 0 then raise Exception.Create('Нет загруженных шрифтов');
 FC := Item[0].FontCollect;
 For I := 0 to Count - 1 do begin
  If Result = -1 then
   If AnsiLowerCase(Item[I].fontName) = AnsiLowerCase(fontName) then FC := Item[I].fontCollect;
  If (AnsiLowerCase(Item[I].fontName) = AnsiLowerCase(fontName)) and (Item[I].fontStyle = fontStyle) then begin
   FC := Item[I].FontCollect;
   Result := I;
   exit;
  end;
 end;
end;

{ TFontSymbol }

constructor TFontSymbol.Create(Selector_: TogsSelector; Font_: ISkFont; GlyphIndex_: Word;
                               nullSymbol_: TFontSymbol);
var Path: ISkPath;
    Elem: TSkPathIteratorElem;
    Poly_S: TPoly_Single;
    Poly: TogsPolygon;
    Glyphs: TArray<Word>;
    Widths: TArray<Single>;
    GlyphBounds: TArray<TRectF>;
    Tol: Double;
procedure CloseRing;
begin
 if Poly_S = nil then exit;
// контур из менее чем 3 точек не образует площади
 if Poly_S.Count >= 3 then begin
  Poly_S.Calculate([calcbBox, calcSquare]);
  Poly.AddPolygon(Poly_S);
 end else Poly_S.Free;
 Poly_S := nil;
end;
procedure AddPt(const P: TPointF);
begin
 if Poly_S = nil then Poly_S := TPoly_Single.Create(ogsSelector);
 Poly_S.AddPoint(P.X, Metrics.bearingY + P.Y, 0);
end;
function Segments(const P0, P1, P2, P3: TPointF): Integer;
begin
// число отрезков аппроксимации по длине контрольной ломаной
 Result := EnsureRange(Ceil((P0.Distance(P1) + P1.Distance(P2) + P2.Distance(P3)) / Tol), 2, 64);
end;
procedure AddQuad(const P0, P1, P2: TPointF);
var I, N: Integer;
    T, U: Double;
begin
 N := Segments(P0, P1, P2, P2);
 for I := 1 to N do begin
  T := I / N; U := 1 - T;
  AddPt(PointF(U * U * P0.X + 2 * U * T * P1.X + T * T * P2.X,
               U * U * P0.Y + 2 * U * T * P1.Y + T * T * P2.Y));
 end;
end;
procedure AddConic(const P0, P1, P2: TPointF; W: Double);
var I, N: Integer;
    T, U, D: Double;
begin
 N := Segments(P0, P1, P2, P2);
 for I := 1 to N do begin
  T := I / N; U := 1 - T;
  D := U * U + 2 * W * U * T + T * T;
  AddPt(PointF((U * U * P0.X + 2 * W * U * T * P1.X + T * T * P2.X) / D,
               (U * U * P0.Y + 2 * W * U * T * P1.Y + T * T * P2.Y) / D));
 end;
end;
procedure AddCubic(const P0, P1, P2, P3: TPointF);
var I, N: Integer;
    T, U: Double;
begin
 N := Segments(P0, P1, P2, P3);
 for I := 1 to N do begin
  T := I / N; U := 1 - T;
  AddPt(PointF(U * U * U * P0.X + 3 * U * U * T * P1.X + 3 * U * T * T * P2.X + T * T * T * P3.X,
               U * U * U * P0.Y + 3 * U * U * T * P1.Y + 3 * U * T * T * P2.Y + T * T * T * P3.Y));
 end;
end;
begin
 inherited Create(Selector_);
 nullSymbol := nullSymbol_;
 fIndex := GlyphIndex_;
 Poly_S := nil;
// метрики глифа
 Glyphs := [GlyphIndex_];
 Font_.GetWidthsAndBounds(Glyphs, Widths, GlyphBounds);
 Metrics.bBox := GlyphBounds[0];
 Metrics.bearingX := GlyphBounds[0].Left;
 Metrics.bearingY := -GlyphBounds[0].Top;
 Metrics.horiAdvance := Widths[0];
 fBounds := GlyphBounds[0];
// точка привязки глифа (лево-низ): Left = 0, Top = bearingY, Right = шаг
 advLine := RectF(0, Metrics.bearingY, Metrics.horiAdvance, Metrics.bearingY);
// перевернутый Rect: высота контура и горизонтальные границы
 fRect := RectF(fBounds.Left, fBounds.Height, fBounds.Right, 0);
// пустой глиф (пробел, управляющие символы)
 if fBounds.IsEmpty then exit;
 Path := Font_.GetPath(GlyphIndex_);
 if Path = nil then exit;
 Tol := Max(1, Font_.Size / 100);
// заполняем геометрию: контуры пути Skia -> TPoly_Single
 Poly := TogsPolygon.Create(ogsSelector);
 try
  for Elem in Path.GetIterator(False) do
   case Elem.Verb of
    TSkPathVerb.Move: begin CloseRing; AddPt(Elem.Points[0]); end;
    TSkPathVerb.Line: AddPt(Elem.Points[1]);
    TSkPathVerb.Quad: AddQuad(Elem.Points[0], Elem.Points[1], Elem.Points[2]);
    TSkPathVerb.Conic: AddConic(Elem.Points[0], Elem.Points[1], Elem.Points[2], Elem.ConicWeight);
    TSkPathVerb.Cubic: AddCubic(Elem.Points[0], Elem.Points[1], Elem.Points[2], Elem.Points[3]);
    TSkPathVerb.Close: CloseRing;
   end;
  CloseRing;
 except
  Poly_S.Free;
  Poly.Free;
  raise;
 end;
 If Poly.Count = 0 then begin Poly.Free; exit; end;
// отношения контуров: оболочки, дырки и острова любой вложенности (PolyMode.GlobalParent)
 Poly.Calculate([calcSquare, calcbBox, calcRelation]);
 // если полигон состоит из нескольких оболочек ->
 // формируем мультиполигон из нескольких полигонов,
 // иначе просто добавляем полигон
 If not Poly.isMultiPolygon then
  AddPolygon(Poly)
 else begin
  AddMultiPoly(Poly);
 // контуры перенесены в мультиполигон -> удаляем Poly
  Poly.Free;
 end;
 Calculate([calcbBox, calcSquare]);
end;

constructor TFontSymbol.Load(Stream: TogsStream);
begin
 Stream.Read(fSymbol, SizeOf(fSymbol));
 Stream.Read(fIndex, SizeOf(fIndex));
 Stream.Read(fBounds, SizeOf(fBounds));
 Stream.Read(fRect, SizeOf(fRect));
 Stream.Read(advLine, SizeOf(advLine));
 Stream.Read(Metrics, SizeOf(Metrics));
 inherited Load(Stream);
end;

procedure TFontSymbol.Store(Stream: TogsStream);
begin
 Stream.Write(fSymbol, SizeOf(fSymbol));
 Stream.Write(fIndex, SizeOf(fIndex));
 Stream.Write(fBounds, SizeOf(fBounds));
 Stream.Write(fRect, SizeOf(fRect));
 Stream.Write(advLine, SizeOf(advLine));
 Stream.Write(Metrics, SizeOf(Metrics));
 inherited Store(Stream);
end;

{ TFontCollect }

constructor TFontCollect.Create(Selector_: TogsSelector; FileName_: String; Mode: TLoadMode);
begin
 inherited Create(Selector_);
 fFileName := FileName_;
 fGlyphs := TDictionary<Word, TFontSymbol>.Create;
 fTypeface := TSkTypeface.MakeFromFile(fFileName);
 if fTypeface = nil then raise Exception.Create('Не удалось загрузить шрифт: ' + fFileName);
 fFontName := fTypeface.FamilyName;
 fStyle := [];
 if fTypeface.IsBold then Include(fStyle, ftsBold);
 if fTypeface.IsItalic then Include(fStyle, ftsItalic);
// контуры без хинтинга в единицах cFontUnits
 fFont := TSkFont.Create(fTypeface, cFontUnits);
 fFont.Hinting := TSkFontHinting.None;
 fFont.LinearMetrics := True;
 fFont.Subpixel := True;
 fFont.GetMetrics(fMetrics);
 fLoadMode := lmIncomplete;
 If Mode = lmComplete then LoadModeComplete;
end;

destructor TFontCollect.Destroy;
begin
// глифы принадлежат Items (уничтожаются в inherited Destroy)
 fGlyphs.Free;
 inherited Destroy;
end;

procedure TFontCollect.LoadModeComplete;
begin
 If fLoadMode = lmComplete then exit;
 try
 // высота символа - высота строки шрифта (Ascent + Descent),
 // аналог ABC.yTop - ABC.yBottom прежнего feFontEngine
  fHeight := Round(Abs(fMetrics.Ascent) + Abs(fMetrics.Descent));
  fbtmHeight := Round(Abs(fMetrics.Ascent));
  if fHeight = 0 then fHeight := cFontUnits;
 // символ с индексом 0 (.notdef) - пустой символ шрифта
  fNullSymbol := TFontSymbol.Create(ogsSelector, fFont, 0, nil);
  Items.Add(fNullSymbol);
  fGlyphs.Add(0, fNullSymbol);
  fLoadMode := lmComplete;
 except
  fLoadMode := lmIncomplete;
 end;
end;

function TFontCollect.GetSymbol(Index: Integer): TFontSymbol;
begin
 If fLoadMode = lmIncomplete then LoadModeComplete;
 if (Index < 0) or (Index > High(Word)) then Index := 0;
// глиф создается при первом обращении
 if not fGlyphs.TryGetValue(Index, Result) then begin
  Result := TFontSymbol.Create(ogsSelector, fFont, Index, fNullSymbol);
  Items.Add(Result);
  fGlyphs.Add(Index, Result);
 end;
end;

function TFontCollect.GetStyleAsString: String;
begin
 if fStyle = [] then Result := 'Regular' else Result := '';
 if ftsBold in fStyle then Result := 'Bold';
 if ftsItalic in fStyle then
  if Result = '' then Result := 'Italic' else Result := Result + ' Italic';
end;

function TFontCollect.CharIndex(CharCode: Integer): Integer;
begin
 Result := fFont.UnicharToGlyph(CharCode);
end;

function TFontCollect.SymbolByIndex(CharCode: Integer): TFontSymbol;
var Index: Integer;
begin
 Index := CharIndex(CharCode);
 If Index < 0 then raise Exception.Create(Fmt(['Неверный код символа ',CharCode]));
 Result := Symbol[Index];
end;

function TFontCollect.ScaleOf(Height: Double): Double;
begin
 If fLoadMode = lmIncomplete then LoadModeComplete;
 Result := Height / fHeight;
end;

function TFontCollect.CharsPosition(const Text: String; Align: TFEAlignments): ArrayOfCharPosition;
var I, N, LineStart: Integer;
    CharCode: Integer;
    X, YBase, LineHeight, Ascent, Descent: Double;
procedure AlignLine(FromIndex, ToIndex: Integer; LineWidth: Double);
var J: Integer;
    Dx: Double;
begin
 Dx := 0;
 if ftaCenter in Align then Dx := -LineWidth / 2 else
 if ftaRight in Align then Dx := -LineWidth;
 for J := FromIndex to ToIndex do Result[J].x := Result[J].x + Dx;
end;
begin
 SetLength(Result, Length(Text));
 Ascent := Abs(fMetrics.Ascent);
 Descent := Abs(fMetrics.Descent);
 LineHeight := Ascent + Descent + fMetrics.Leading;
// положение базовой линии первой строки относительно точки привязки (Y вниз)
 if ftaTop in Align then YBase := Ascent else
 if ftaVerticalCenter in Align then YBase := (Ascent - Descent) / 2 else
 if ftaBottom in Align then YBase := -Descent else
  YBase := 0;
 X := 0; N := 0; LineStart := 0;
 I := 1;
 while I <= Length(Text) do begin
  CharCode := Ord(Text[I]);
  if Text[I].IsHighSurrogate and (I < Length(Text)) then CharCode := Char.ConvertToUtf32(Text[I], Text[I + 1]);
  Result[N].x := X;
  Result[N].yBase := YBase;
  Result[N].yTop := YBase - Ascent;
  Result[N].yBottom := YBase + Descent;
  if CharCode = 10 then begin
  // перевод строки: выравниваем завершенную строку, переходим на следующую
   Result[N].width := 0;
   AlignLine(LineStart, N, X);
   X := 0;
   YBase := YBase + LineHeight;
   LineStart := N + 1;
  end else
  if CharCode = 13 then Result[N].width := 0 else begin
   Result[N].width := fFont.GetWidths([fFont.UnicharToGlyph(CharCode)])[0];
   X := X + Result[N].width;
  end;
  Inc(N);
  if CharCode > $FFFF then Inc(I, 2) else Inc(I);
 end;
 SetLength(Result, N);
 if N > 0 then AlignLine(LineStart, N - 1, X);
end;

{ TogsSymbol }

constructor TogsSymbol.Create(Selector: TogsSelector; X_, Y_, Z_: Double;
 Char_: PChar; Symbol_: TFontSymbol);
begin
 inherited Create(X_,Y_,Z_,Selector);
 fChar := Char_;
 fSymbol := Symbol_;
 ogsRect.Clear;
 ogsRect.InsertRect(fSymbol.ogsRect);
 ogsRect.Move(X_, Y_);
end;

function TogsSymbol.Calculate(Action: TCalcActionSet): Integer;
var oldSect: TSect;
    Matrix: TogsMatrix;
begin
 Result := 0;
 If calcbBox in Action then begin
 // перевычисление габаритов символа
  oldSect := fSymbol.ogsRect.Sect;
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, ogsMatrix.Angle, ogsMatrix.Scale));
  try
   fSymbol.Calculate([calcbBox]);
   ogsRect.Assign(fSymbol.ogsRect);
  finally
   DeleteMatrix(SelectMatrix(Matrix));
   fSymbol.ogsRect.Sect := oldSect;
  end;
  Result := 1;
 end;
end;

procedure TogsSymbol.Draw(Drawer: TogsDrawer);
var oldSect: TSect;
    Matrix: TogsMatrix;
begin
 If not Visible(ogsSelector.ActiveRect) then exit;
 Matrix := SelectMatrix(TogsMatrix.Create(X, Y, ogsMatrix.Angle, ogsMatrix.Scale));
 try
  oldSect:= fSymbol.ogsRect.Sect;
  fSymbol.Calculate([calcbBox]);
  fSymbol.Draw(Drawer);
 finally
  DeleteMatrix(SelectMatrix(Matrix));
  fSymbol.ogsRect.Sect := oldSect;
 end;
end;

function TogsSymbol.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var oldSect: TSect;
    Matrix: TogsMatrix;
begin
 Result := False;
 If not ogsRect.PointIn(X_,Y_) then exit;
 oldSect := fSymbol.ogsRect.Sect;
 Matrix := SelectMatrix(TogsMatrix.Create(X, Y, ogsMatrix.Angle, ogsMatrix.Scale));
 try
  fSymbol.Calculate([calcbBox]);
  Result := fSymbol.SelectByPoint(X_,Y_,Params);
 finally
  DeleteMatrix(SelectMatrix(Matrix));
  fSymbol.ogsRect.Sect := oldSect;
 end;
end;

{ TogsTextString }

constructor TogsTextString.Create(Selector: TogsSelector;
 FontCollect_: TFontCollect; X_, Y_, Z_: Double; Height_, Angle_,
 Scale_: Double; Align_: TFEAlignments; Text_, AttrName_: String;
 TextColor: Integer; InBlock: Boolean);
begin
 inherited Create(X_,Y_,Z_,Selector);
 fFontCollect := FontCollect_;
 fText := Text_;
// создание коллекции символов TogsSymbol
 fSymbols := TogsGeometryCollection.Create(Selector);
//
 fHeight:= Height_;
 fAngle := Angle_;
 fScale := Scale_;
 fAlign := Align_;
//
 fAttrName := AttrName_;
 Color := TextColor;
 fBlock := InBlock;
 CalculateText;
end;

constructor TogsTextString.CreateAs(ogsObject: TogsBasic);
begin
 inherited CreateAs(ogsObject);
 Assign(ogsObject);
// собственная коллекция символов копии
 fSymbols := TogsGeometryCollection.Create(ogsSelector);
 CalculateText;
end;

destructor TogsTextString.Destroy;
begin
// TogsTextString может быть копируемым объектом
 If not isKeepObject then begin
  fSymbols.Free;
  SetLength(ABC, 0);
 end;
 inherited Destroy;
end;

constructor TogsTextString.Load(Stream: TogsStream);
var fontName: String;
    fontStyle: TFEStyles;
    B: Byte;
begin
 inherited Load(Stream);
 fText := Stream.ReadUTF8;
 fAttrName := Stream.ReadUTF8;
 fontName := Stream.ReadUTF8;
 Stream.Read(fontStyle, SizeOf(fontStyle));
 Stream.Read(fHeight, SizeOf(fHeight));
 Stream.Read(fAngle, SizeOf(fAngle));
 Stream.Read(fScale, SizeOf(fScale));
 Stream.Read(fAlign, SizeOf(fAlign));
 Stream.Read(fColorBy, SizeOf(fColorBy));
 Stream.Read(fColor, SizeOf(fColor));
 Stream.Read(B, SizeOf(B)); fBlock := B <> 0;
// шрифт восстанавливается по имени и стилю из ogsFontManager
 fSymbols := TogsGeometryCollection.Create(ogsSelector);
 fFontCollect := nil;
 if (ogsFontManager <> nil) and (ogsFontManager.Count > 0) then begin
  ogsFontManager.FindBy(fontName, fontStyle, fFontCollect);
  if fFontCollect <> nil then CalculateText;
 end;
end;

procedure TogsTextString.Store(Stream: TogsStream);
var fontName: String;
    fontStyle: TFEStyles;
    B: Byte;
begin
 inherited Store(Stream);
 fontName := ''; fontStyle := [];
 if fFontCollect <> nil then begin fontName := fFontCollect.FontName; fontStyle := fFontCollect.Style; end;
 Stream.WriteUTF8(fText);
 Stream.WriteUTF8(fAttrName);
 Stream.WriteUTF8(fontName);
 Stream.Write(fontStyle, SizeOf(fontStyle));
 Stream.Write(fHeight, SizeOf(fHeight));
 Stream.Write(fAngle, SizeOf(fAngle));
 Stream.Write(fScale, SizeOf(fScale));
 Stream.Write(fAlign, SizeOf(fAlign));
 Stream.Write(fColorBy, SizeOf(fColorBy));
 Stream.Write(fColor, SizeOf(fColor));
 B := Ord(fBlock);
 Stream.Write(B, SizeOf(B));
end;

function TogsTextString.Assign(ogsObject: TogsBasic): Boolean;
var Obj: TogsTextString;
begin
 If not(ogsObject is TogsTextString) then
   raise Exception.Create(ClassName+'.Assign: попытка присвоить объект типа ' + ogsObject.ClassName);
 Obj := TogsTextString(ogsObject);
 fFontCollect := Obj.fFontCollect;
 fText := Obj.fText;
 fSymbols := Obj.fSymbols;
 ABC := Obj.ABC;
 fHeight := Obj.fHeight;
 fAngle  := Obj.fAngle;
 fScale  := Obj.fScale;
 fAlign  := Obj.fAlign;
 fAttrName := Obj.fAttrName;
 Color := Obj.Color;
 Result := True;
end;

function TogsTextString.GetSymbol(Index: Integer): TogsSymbol;
begin
 Result := fSymbols.List[Index];
end;

function TogsTextString.GetAttribute: String;
begin
 Result := fAttrName;
end;

procedure TogsTextString.SetAttribute(AttrName_: String);
begin
 fAttrName := AttrName_;
end;

procedure TogsTextString.SetColorBy(AValue: TColorBy); begin fColorBy := AValue; end;

function TogsTextString.GetColorBy: TColorBy; begin Result := fColorBy; end;

function TogsTextString.GetColor: TColor; begin Result := fColor; end;

procedure TogsTextString.SetColor(AValue: TColor); begin fColor := AValue; end;

procedure TogsTextString.CalculateText;
var Index, ABCIndex: Integer;
    charCode, charLen, glyphIndex: Integer;
    fontSymbol: TFontSymbol;
    XF, YF: Double;
begin
 fSymbols.Items.FreeAll;
 if (fFontCollect = nil) or (fText = '') then exit;
// выстраиваем последовательность символов
 ABC := fFontCollect.CharsPosition(fText, fAlign);
 Index := 1;
 ABCIndex := 0;
 While (Index <= Length(fText)) and (ABCIndex < Length(ABC)) do begin
  charCode := Ord(fText[Index]); charLen := 1;
  if fText[Index].IsHighSurrogate and (Index < Length(fText)) then begin
   charCode := Char.ConvertToUtf32(fText[Index], fText[Index + 1]);
   charLen := 2;
  end;
 // управляющие символы (переводы строк) не имеют геометрии
  if charCode >= 32 then begin
   glyphIndex := fFontCollect.CharIndex(charCode);
   fontSymbol := fFontCollect[glyphIndex];
   fontSymbol.fSymbol := fText[Index];
   YF := - fontSymbol.advLine.Top + ABC[ABCIndex].yBase;
   XF := ABC[ABCIndex].x;
   AddSymbol(XF, YF, PChar(@fText[Index]), fontSymbol);
  end;
  Inc(Index, charLen);
  Inc(ABCIndex);
 end;
end;

procedure TogsTextString.AddSymbol(X_, Y_: Double; Char_: PChar;
 Symbol: TFontSymbol);
begin
 fSymbols.Add(TogsSymbol.Create(ogsSelector, X_,Y_,Z, Char_, Symbol));
end;

function TogsTextString.Calculate(Action: TCalcActionSet): Integer;
var I: Integer;
    Matrix: TogsMatrix;
    Symb: TogsSymbol;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
begin
 Result := 0;
 If not(calcbBox in Action) then exit;
 If fFontCollect = nil then exit;
// вычисляем габариты строки текста и каждого символа внутри строки
 txScale := fFontCollect.ScaleOf(fHeight);
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 ogsRect.Clear;
 try
  For I := 0 to fSymbols.Count - 1 do begin
   Symb := Symbol[I];
  // вычисляем статические габариты символа
   Symb.Calculate([calcbBox]);
   ogsRect.InsertRect(Symb.ogsRect);
  end;
  Result := 1;
 finally
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

procedure TogsTextString.Draw(Drawer: TogsDrawer);
var I: Integer;
    Matrix: TogsMatrix;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
    Pen: TogsPen;
    Brush: TogsBrush;
begin
 If not Visible(ogsSelector.ActiveRect) then exit;
 If fFontCollect = nil then exit;
 If Selected then
  Pen := Drawer.SelectPen(TogsPen.Create(TColorRec.Lime, 0, nil)) else
  Pen := Drawer.SelectPen(TogsPen.Create(Color, 0, nil));
 Brush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
 txScale := fFontCollect.ScaleOf(fHeight);
 ogsRect.Draw(Drawer);
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 try
  For I := 0 to Count - 1 do
   Symbol[I].Draw(Drawer);
  If fBlock then Drawer.DrawMarker(X, Y) else
                  Drawer.DrawMarker(fX, fY);
 finally
  Drawer.DeletePen(Drawer.SelectPen(Pen));
  Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

function TogsTextString.SelectByPoint(X_, Y_: Double; var Params: TCaptureRec): boolean;
var I: Integer;
    Matrix: TogsMatrix;
    txScale: Double;
    mxAngle: Double;
    mxScale: Double;
begin
 Result := False;
 If not(ogsRect.PointIn(X_,Y_)) then exit;
 If fFontCollect = nil then exit;
 txScale := fFontCollect.ScaleOf(fHeight);
 If ogsMatrix <> nil then mxAngle := ogsMatrix.Angle else mxAngle := 0;
 If ogsMatrix <> nil then mxScale := ogsMatrix.Scale else mxScale := 1;
 If fBlock then
  Matrix := SelectMatrix(TogsMatrix.Create(X, Y, mxAngle + fAngle, txScale * mxScale)) else
  Matrix := SelectMatrix(TogsMatrix.Create(fX, fY, fAngle, txScale * fScale));
 try
  For I := 0 to Count - 1 do begin
   Result := Symbol[I].SelectByPoint(X_,Y_,Params);
   If Result then begin
    Params.resObject := Self;
    Params.resCaptureOf := ckText;
    exit;
   end;
  end;
 finally
  DeleteMatrix(SelectMatrix(Matrix));
 end;
end;

function TogsTextString.FeatureProperties: TJSONObject;
var Ogs: TJSONObject;
begin
 Result := inherited FeatureProperties;
 if Result = nil then Result := TJSONObject.Create;
 Ogs := FeatureOgsSection(Result);
 Ogs.SetString('class', ClassName);
 Ogs.SetString('text', fText);
 if fAttrName <> '' then Ogs.SetString('attr', fAttrName);
 if fFontCollect <> nil then begin
  Ogs.SetString('font', fFontCollect.FontName);
  Ogs.SetString('fontStyle', fFontCollect.StyleAsString);
 end;
 Ogs.SetFloat('height', fHeight);
 Ogs.SetFloat('angle', fAngle);
 Ogs.SetFloat('scale', fScale);
 Ogs.SetInt('align', Byte(fAlign));
 Ogs.SetString('color', ColorToHex(Color));
 if fBlock then Ogs.SetBool('inBlock', True);
end;

function TogsTextString.Count: Integer;
begin
 Result := fSymbols.Count;
end;

{ TogsTextParams }

constructor TogsTextParams.CreateEmpty;
begin
 inherited CreateEmpty;
 fKeepObject := True;
end;

constructor TogsTextParams.Create(TextString_: TogsTextString;
 Selector: TogsSelector; FontCollect_: TFontCollect; X_, Y_, Z_: Double;
 Height_, Angle_, Scale_: Double; Align_: TFEAlignments; Text_,
 AttrName_: String; TextColor: Integer; InBlock: Boolean);
begin
 inherited Create(Selector, FontCollect_, X_,Y_,Z_,
                  Height_,Angle_,Scale_,Align_,Text_,AttrName_, TextColor, InBlock);
 TextString := TextString_;
end;

function TogsTextParams.Assign(ogsObject: TogsBasic): boolean;
begin
 Result := inherited Assign(ogsObject);
 if ogsObject is TogsTextParams then KeepString := TogsTextParams(ogsObject);
end;

procedure TogsTextParams.KeepObject;
begin
// если KeepObject уже создан -> выход
 If KeepString <> nil then exit;
// оригинальный текст блока не задан (например, после загрузки из потока)
 If TextString = nil then exit;
// создаем пустой объект
 KeepString := TogsTextParams.CreateEmpty;
// присваивем указатели
 KeepString.Assign(TextString);
 TextString.Assign(Self);
// положение атрибута в системе координат блока (Assign его не переносит)
 KeepString.fX := TextString.fX; KeepString.fY := TextString.fY; KeepString.Z := TextString.Z;
 TextString.fX := fX; TextString.fY := fY; TextString.Z := Z;
end;

procedure TogsTextParams.ReleaseObject;
begin
// если KeepObject уничтожен -> возможно был вложенный вызов ReleaseObject -> выход
 If KeepString = nil then exit;
 TextString.Assign(KeepString);
 TextString.fX := KeepString.fX; TextString.fY := KeepString.fY; TextString.Z := KeepString.Z;
 KeepString.Free;
 KeepString := nil;
end;

function TogsTextParams.isKeepObject: Boolean;
begin
 Result := fKeepObject;
end;

{ TTextAttribs }

function CheckAttrProc (P: TogsBasic): Boolean;
begin
 Result := P is TogsTextParams;
end;

constructor TTextAttribs.Create;
begin
 inherited Create;
 CheckTypeProc := CheckAttrProc;
end;

constructor TTextAttribs.CreateAs(ogsObject: TogsBasic);
var I: Integer;
    Obj: TTextAttribs;
    Attr_: TogsTextParams;
begin
 Create;
 if not (ogsObject is TTextAttribs) then exit;
 Obj := TTextAttribs(ogsObject);
 for I := 0 to Obj.Count - 1 do begin
  Attr_ := TogsTextParams.CreateAs(Obj.Attr[I]);
  Attr_.TextString := Obj.Attr[I].TextString;
  Add(Attr_);
 end;
end;

constructor TTextAttribs.Load(Stream: TogsStream);
begin
 inherited Load(Stream);
 CheckTypeProc := CheckAttrProc;
end;

function TTextAttribs.FindAttr(AttrName: String; CI: boolean): TogsTextParams;
var I: Integer;
begin
 Result := nil;
 For I := 0 to Count - 1 do
  If (CI and (AnsiCompareText(AttrName, Attr[I].fAttrName) = 0)) or (not CI and (AttrName = Attr[I].fAttrName)) then begin
   Result := Attr[I];
   exit;
  end;
end;

function TTextAttribs.GetAttr(Index: Integer): TogsTextParams;
begin
 Result := Items[Index];
end;

procedure TTextAttribs.KeepObject;
var I: Integer;
begin
 For I := 0 to Count - 1 do Attr[I].KeepObject;
end;

procedure TTextAttribs.ReleaseObject;
var I: Integer;
begin
 For I := 0 to Count - 1 do Attr[I].ReleaseObject;
end;

initialization
 ogsFontManager := TogsFontManager.Create;
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TFontSymbol, 400, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsTextString, 401, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TogsTextParams, 402, 1));
 ogsRegisteredClasses.Add(TogsRegisteredClass.Create(TTextAttribs, 403, 1));
finalization
 ogsFontManager.Free;
end.
