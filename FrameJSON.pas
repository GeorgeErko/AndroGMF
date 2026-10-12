unit FrameJSON;

// Импорт/экспорт перечетки зеленых насаждений в CSV (JSONForm.ExecuteImportExport
// старой программы, DlgJSON.pas): только то, что задействовано в
// ExecuteImportExport - sbExportClick (экспорт выбранных ЗН), sbImportClick
// (LoadCSV: точки по строкам CSV, слой и знак по типу насаждения и жизненной
// форме) и Button1Click (точки в карту, контуры групп по столбцу Geometry -
// бывший znList). JSON (TJSONImporter) для CSV не нужен и не перенесен.
// Файлы: Windows - стандартные диалоги; Android - открытие формой
// DlgLocalOpen (маска *.csv), запись - запрос имени файла, файл в каталоге
// открытой карты (TwgForm.About.Path). CSV пишется в cp1251 (как в старой
// программе), читается cp1251 или UTF-8 (по BOM); числа - с точкой.

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes,
     System.IOUtils, System.Generics.Collections, FMX.Types, FMX.Controls,
     FMX.Forms, FMX.Dialogs, Collect, EcDot, EcLot, WpTwigs, WptForm2, LBN,
     SelectedObjects;

var
// имя файла экспорта по умолчанию (GlobalCSV старой программы)
  GlobalCSV: String = '';

type
  TFrameJSON = class(TFrame)
  private
   FTwgForm: TForm2;
   FObjects: TSelectedObjects;
   FLNames: TListByName;
   FOnChanged: TNotifyEvent;
   procedure ExportCSV;
   procedure ImportCSV(const FileName: String);
   function LoadCSV(St: TStrings; Imported: TList<TPointDot>): Boolean;
   procedure ApplyImport(St: TStrings; Imported: TList<TPointDot>; const FileName: String);
   procedure LoadNames;
  public
   destructor Destroy; override;
  // Import: выбор файла и импорт; иначе - экспорт выбранных точечных ЗН
   procedure ExecuteImportExport(AObjects: TSelectedObjects; ATwgForm: TForm2; Import: Boolean);
  // число выбранных точечных ЗН для экспорта
   function ExportCount(AObjects: TSelectedObjects): Integer;
  // карта изменена (импорт) - обновить сцену
   property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

// выбор файла (Android - DlgLocalOpen с маской Mask, Windows - TOpenDialog)
 procedure DendroPickFile(AOwner: TComponent; const Dir, Mask: String; const OnPicked: TProc<String>);
// имя файла для записи (Android - запрос имени, файл в Dir; Windows -
// TSaveDialog); OnName вызывается всегда, при отмене - с пустым именем
 procedure DendroSaveFile(AOwner: TComponent; const Dir, DefaultName: String; const OnName: TProc<String>);
// CSV: чтение (cp1251 или UTF-8 по BOM) и запись (cp1251)
 procedure CsvLoad(const FileName: String; St: TStrings);
 procedure CsvSave(St: TStrings; const FileName: String);
// число из CSV (точка или запятая) и число для CSV (с точкой)
 function CsvToFloat(const S: String): Double;
 function CsvFloatStr(V: Double): String;

implementation

uses FMX.DialogService, newProcs, newConsts, newResource, newProperties,
     FrameDendro{$IFDEF ANDROID}, DlgLocalOpen{$ENDIF};

{$R *.fmx}

var GEnc1251: TEncoding = nil;

function Enc1251: TEncoding;
begin
 if GEnc1251 = nil then GEnc1251 := TEncoding.GetEncoding(1251);
 Result := GEnc1251;
end;

procedure CsvLoad(const FileName: String; St: TStrings);
var Bytes: TBytes;
begin
 Bytes := TFile.ReadAllBytes(FileName);
 if (Length(Bytes) >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
  St.Text := TEncoding.UTF8.GetString(Bytes, 3, Length(Bytes) - 3)
 else
  St.Text := Enc1251.GetString(Bytes);
end;

procedure CsvSave(St: TStrings; const FileName: String);
begin
 St.WriteBOM := False;
 St.SaveToFile(FileName, Enc1251);
end;

function CsvToFloat(const S: String): Double;
var FS: TFormatSettings;
begin
 FS := TFormatSettings.Invariant;
 Result := StrToFloat(Trim(S).Replace(',', '.'), FS);
end;

function CsvFloatStr(V: Double): String;
begin
 Result := FloatToStr(V, TFormatSettings.Invariant);
end;

procedure DendroPickFile(AOwner: TComponent; const Dir, Mask: String; const OnPicked: TProc<String>);
{$IFDEF ANDROID}
var F: TlocalOpenForm;
{$ELSE}
var D: TOpenDialog;
{$ENDIF}
begin
{$IFDEF ANDROID}
 F := TlocalOpenForm.Create(AOwner);
 F.BaseDir := Dir;
 F.FileMask := Mask;
 F.FCallback :=
  procedure(const LocalPath: string)
  begin
   if LocalPath <> '' then OnPicked(LocalPath);
  end;
 F.Show;
{$ELSE}
 D := TOpenDialog.Create(nil);
 try
  D.Filter := 'Файлы (' + Mask + ')|' + Mask;
  D.InitialDir := Dir;
  if D.Execute then OnPicked(D.FileName);
 finally
  D.Free;
 end;
{$ENDIF}
end;

procedure DendroSaveFile(AOwner: TComponent; const Dir, DefaultName: String; const OnName: TProc<String>);
{$IFNDEF ANDROID}
var D: TSaveDialog;
{$ENDIF}
begin
{$IFDEF ANDROID}
 TDialogService.InputQuery('Сохранить файл в ' + Dir, ['Имя файла'], [DefaultName],
  procedure(const AResult: TModalResult; const AValues: array of string)
  var Name: String;
  begin
   Name := '';
   if AResult = mrOk then Name := Trim(AValues[0]);
   if (Name <> '') and (ExtractFileExt(Name) = '') then Name := Name + ExtractFileExt(DefaultName);
   if Name <> '' then Name := TPath.Combine(Dir, Name);
   OnName(Name);
  end);
{$ELSE}
 D := TSaveDialog.Create(nil);
 try
  D.InitialDir := Dir;
  D.FileName := DefaultName;
  D.DefaultExt := Copy(ExtractFileExt(DefaultName), 2, MaxInt);
  D.Filter := 'Файлы (*' + ExtractFileExt(DefaultName) + ')|*' + ExtractFileExt(DefaultName);
  if D.Execute then OnName(D.FileName) else OnName('');
 finally
  D.Free;
 end;
{$ENDIF}
end;

{ TFrameJSON }

destructor TFrameJSON.Destroy;
begin
 FreeAndNil(FLNames);
 inherited;
end;

procedure TFrameJSON.LoadNames;
begin
 FreeAndNil(FLNames);
 FLNames := TListByName.Create(1);
 FLNames.LoadFromFile(AnsiString(DendroDictPath('Names.txt')), AnsiString(oghObjectType(FTwgForm)));
end;

// точечные ЗН, которые выгружаются в перечетку (группы цветника/газона - нет)
function IsExportZnak(PD: TPointDot): Boolean;
begin
 Result := PD.What in [40, 97, 95, 34, 98, 99];
end;

function TFrameJSON.ExportCount(AObjects: TSelectedObjects): Integer;
var I: Integer;
begin
 Result := 0;
 if AObjects = nil then exit;
 for I := 0 to AObjects.Count - 1 do
  if (TObject(AObjects[I]) is TPointDot) and IsExportZnak(TPointDot(AObjects[I])) then Inc(Result);
end;

procedure TFrameJSON.ExecuteImportExport(AObjects: TSelectedObjects; ATwgForm: TForm2; Import: Boolean);
var Dir: String;
begin
 FTwgForm := ATwgForm;
 FObjects := AObjects;
 if FTwgForm = nil then exit;
 Dir := String(FTwgForm.About.Path);
 if Import then
  DendroPickFile(Self, Dir, '*.csv',
   procedure(FileName: String)
   begin
    ImportCSV(FileName);
   end)
 else
  ExportCSV;
end;

// экспорт выбранных точечных ЗН (sbExportClick): столбцы - из секции Names.txt
// по *Тип (ОГХ) первого объекта, затем X, Y и Geometry (контур группы)
procedure TFrameJSON.ExportCSV;
const Sep = ';';
var PD: TPointDot;
    I: Integer;
    St, Header, Lines: TStrings;
    Name: String;
function GetProp(const S: String): String;
begin
 if GetProp0(S) = '' then Result := '-' else Result := GetProp0(S);
end;
function HeaderLine: String;
var I: Integer;
    Section: TSectionName;
begin
 Result := '';
 Section := FLNames.FindByName2(PD.GetProperty('*Тип (ОГХ)'), 0);
 if Section = nil then exit;
 for I := 0 to Section.Count - 1 do
  if Trim(String(Section[I])) <> '' then Result := Result + String(Section.GetValueForIndex(I, 0)) + Sep;
 Result := Result + 'X' + Sep + 'Y' + Sep + 'Geometry';
end;
function RowLine: String;
var I: Integer;
    pS, sSpatial: String;
    Lot: TLot;
begin
 Result := '';
 for I := 0 to Header.Count - 1 do
  if (Header[I] <> 'X') and (Header[I] <> 'Y') and (Header[I] <> 'Geometry') then begin
   pS := String(PD.GetProperty(AnsiString('*' + Header[I])));
   if pS <> byLayer then Result := Result + GetProp(pS) + Sep else Result := Result + '-' + Sep;
  end;
 Result := Result + CsvFloatStr(-PD.YDot) + Sep + CsvFloatStr(PD.XDot);
// группа, изгородь - координаты контура (znGetPointSpatialJSON)
 if PD.What in [98, 99, 95] then begin
  sSpatial := '';
  if znPointIn(FTwgForm, PD, Lot, False) and (Lot <> nil) then begin
   Lot.InsClipDotsParall(FTwgForm.Twigs);
   try
    for I := 0 to Lot.Points.Count - 1 do begin
     sSpatial := sSpatial + CsvFloatStr(-TDot(Lot.Points[I]).YDot) + ',' + CsvFloatStr(TDot(Lot.Points[I]).XDot);
     if I <> Lot.Points.Count - 1 then sSpatial := sSpatial + '|';
    end;
   finally
    Lot.Points.Free;
    Lot.Points := nil;
   end;
  end;
  Result := Result + Sep + sSpatial;
 end;
end;
begin
 if ExportCount(FObjects) = 0 then begin
  MessageError('Выберите точечные ЗН для экспорта');
  exit;
 end;
 LoadNames;
 St := TStringList.Create;
 Header := TStringList.Create;
 try
  for I := 0 to FObjects.Count - 1 do begin
   if not (TObject(FObjects[I]) is TPointDot) then continue;
   PD := TPointDot(FObjects[I]);
   if not IsExportZnak(PD) then continue;
   if St.Count = 0 then begin
    Header.Text := String(MakeString(AnsiString(HeaderLine), Sep));
    if Header.Count = 0 then begin
     MessageError(AnsiString('Не найдена секция "' + String(PD.GetProperty('*Тип (ОГХ)')) + '" в файле Names.txt'));
     exit;
    end;
    St.Add(HeaderLine);
   end;
   St.Add(RowLine);
  end;
  if St.Count = 0 then exit;
 // имя по умолчанию: GlobalCSV или имя карты
  if GlobalCSV <> '' then Name := ExtractFileName(GlobalCSV) else Name := ChangeFileExt(String(FTwgForm.About.MyName), '.csv');
 // запрос имени на Android асинхронный: строки освобождает обработчик
 // (вызывается и при отмене - с пустым именем)
  Lines := St;
  St := nil;
  DendroSaveFile(Self, String(FTwgForm.About.Path), Name,
   procedure(FileName: String)
   begin
    try
     if FileName = '' then exit;
     CsvSave(Lines, FileName);
     GlobalCSV := '';
     MessageInform(AnsiString(IntToStr(Lines.Count - 1) + ' ЗН сохранено в файле ' + FileName));
    finally
     Lines.Free;
    end;
   end);
 finally
  St.Free;
  Header.Free;
 end;
end;

// разбор CSV в точки (LoadCSV): свойства *<столбец>, X/Y - координаты, слой и
// знак - по типу насаждения и жизненной форме
function TFrameJSON.LoadCSV(St: TStrings; Imported: TList<TPointDot>): Boolean;
var I, J, pIndex, Idx: Integer;
    Header, Body, StElka: TStrings;
    PD: TPointDot;
    Error: AnsiString;
procedure DoIt(const lName: String; znkNum: Integer; const symName: String; Koef: Double);
begin
 PD.ClassHandle := FTwgForm.LayerTable.LayerName[AnsiString(lName)];
 if PD.ClassHandle = nil then raise Exception.Create('Не найден слой ' + lName + ' для строки ' + IntToStr(I + 1));
 PD.Code := PD.ClassHandle.ID;
 if lName = 'Дерево одиночное' then begin
  if (PD.GetProperty('*Порода') <> byLayer) and (PD.GetProperty('*Порода') <> '-') and (PD.GetProperty('*Порода') <> '') then begin
   if StElka.IndexOf(String(PD.GetProperty('*Порода'))) <> -1 then PD.What := 34 else PD.What := znkNum;
  end else
  if (PD.GetProperty('*Порода МГГТ') <> byLayer) and (PD.GetProperty('*Порода МГГТ') <> '-') and (PD.GetProperty('*Порода МГГТ') <> '') then begin
   if PD.GetProperty('*Порода МГГТ') = 'Лиственное' then PD.What := znkNum else PD.What := 34;
  end else
   PD.What := znkNum;
 end else
  PD.What := znkNum;
 PD.SetProperty('Знак', AnsiString(IntToStr(PD.What)));
 PD.SetProperty('Масштаб', AnsiString(FloatToStrF(Koef, ffFixed, 15, 2)));
 PD.CreateTextManager;
 if PD.TextManager <> nil then begin
  PD.TextManager.SetAttrValue('№ растения', PD.GetProperty('*№Растения'));
  if symName <> '' then PD.TextManager.SetAttrValue('NAME', AnsiString(symName));
 end;
end;
procedure SetPointHandle;
var TypeOf, LifeForm: String;
procedure ByForm(const Tree, Bush: String; TreeZnk, BushZnk: Integer; const TreeSym, BushSym: String; TreeK, BushK: Double; Strict: Boolean);
begin
 if LifeForm = 'дерево' then DoIt(Tree, TreeZnk, TreeSym, TreeK) else
 if LifeForm = 'кустарник' then DoIt(Bush, BushZnk, BushSym, BushK) else
 if Strict then raise Exception.Create('Неверно заполнена Жизненная форма = ' + LifeForm + ' в строке ' + IntToStr(I + 1));
end;
begin
 TypeOf := Trim(AnsiLowerCase(String(PD.GetProperty('*Тип насаждения'))));
 LifeForm := Trim(AnsiLowerCase(String(PD.GetProperty('*Жизненная форма ДИТ'))));
 if TypeOf = 'группа' then begin
  if Trim(String(PD.GetProperty('*Количество, шт.'))) <> '1' then
   ByForm('Дерево массив', 'Кустарник массив', 99, 98, 'гд', 'гк', 0.25, 0.25, True)
  else
   ByForm('Дерево одиночное', 'Кустарник одиночный', 40, 97, '', '', 0.15, 0.25, True);
 end else
 if Pos('изгородь', TypeOf) <> 0 then DoIt('Кустарник ряд', 95, 'жи', 0.25) else
 if (TypeOf = 'одиночная') or (TypeOf = 'одиночный') then
  ByForm('Дерево одиночное', 'Кустарник одиночный', 40, 97, '', '', 0.15, 0.25, True)
 else
 // проверка типа насаждения убрана (задача SGEO 120)
  ByForm('Дерево одиночное', 'Кустарник одиночный', 40, 97, '', '', 0.15, 0.25, False);
end;
procedure CheckInt(const Name: AnsiString);
begin
 if StrToIntDef(String(PD.GetProperty(Name)), MaxInt) = MaxInt then PD.SetProperty(Name, '-');
end;
begin
 Result := False;
 if St.Count = 0 then exit;
 Header := TStringList.Create;
 Body := TStringList.Create;
 StElka := TStringList.Create;
 try
  TStringList(StElka).Sorted := True;
  if FileExists(DendroDictPath('Хвойные.csv')) then CsvLoad(DendroDictPath('Хвойные.csv'), StElka);
  Header.Text := String(MakeString2(AnsiString(St[0]), ';'));
  for I := 1 to St.Count - 1 do begin
   if Trim(St[I]) = '' then continue;
   Body.Text := String(MakeString2(AnsiString(St[I]), ';'));
   if Header.Count - Body.Count >= 2 then begin
    MessageError(AnsiString('Не совпадает кол-во столбцов с таблицей. Строка ' + IntToStr(I)));
    exit;
   end;
   PD := TPointDot.Create(0, 0, 0);
   PD.Selector := FTwgForm.Selector;
   Imported.Add(PD);
   pIndex := 1;
   for J := 0 to Header.Count - 1 do begin
    if Header[J] = 'X' then PD.YDot := -CsvToFloat(Body[J]) else
    if Header[J] = 'Y' then PD.XDot := CsvToFloat(Body[J]) else begin
     if J > Body.Count - 1 then break;
     if Body[J] = '' then Body[J] := '-';
     PD.SetProperty(AnsiString('*' + Header[J]), AnsiString(Body[J]));
     Idx := PD.Properties.IndexOf(AnsiString('*' + Header[J]));
     if Idx <> -1 then begin
      PD.Properties[Idx].Index := pIndex;
      Inc(pIndex);
     end;
    end;
   end;
  // числовые поля: некорректное значение -> '-'
   Error := '*Количество, шт.';
   CheckInt(Error);
   Error := '*Диаметр на высоте 1.3м., см.';
   if (PD.GetProperty(Error) <> '-') and (PD.GetProperty(Error) <> '') then CheckInt(Error);
   Error := '*Высота, м.';
   try CsvToFloat(String(PD.GetProperty(Error))); except PD.SetProperty(Error, '-'); end;
   Error := '*Возраст, лет';
   CheckInt(Error);
   try
    SetPointHandle;
   except
    on E: Exception do begin
     MessageError(AnsiString(E.Message));
     exit;
    end;
   end;
  end;
  Result := True;
 finally
  Header.Free;
  Body.Free;
  StElka.Free;
 end;
end;

// импортированные точки - в карту (Button1Click): контур группы/изгороди по
// столбцу Geometry ('X,Y|X,Y...'), хвойные по *Порода МГГТ - знак 34
procedure TFrameJSON.ApplyImport(St: TStrings; Imported: TList<TPointDot>; const FileName: String);
var I, J, IdCol, GeoCol: Integer;
    Header, Body: TStrings;
    Geo: TDictionary<String, String>;
    PD: TPointDot;
procedure ImportGeometry(PD: TPointDot);
var S: String;
    Pts: TArray<String>;
    XY: TArray<String>;
    LotX: TLot;
    Tw: TTwig;
    Pr: TResource;
    K: Integer;
begin
 if not Geo.TryGetValue(String(PD.GetProperty('*№Растения')), S) or (Trim(S) = '') then exit;
 with FTwgForm do begin
  if PD.GetProperty('*Тип насаждения') = 'Однорядная живая изгородь' then Pr := LayerTable.LayerName['Кустарник ряд'] else
  if (PD.GetProperty('*Тип насаждения') = 'Группа') and (PD.GetProperty('*Жизненная форма ДИТ') = 'Дерево') then Pr := LayerTable.LayerName['Дерево массив'] else
   Pr := LayerTable.LayerName['Кустарник массив'];
  if Pr = nil then raise Exception.Create('Не найден слой "Кустарник ряд", "Дерево массив" или "Кустарник массив". Загрузите корректный шаблон');
  Tw := TTwig.Create(Selector, 0);
  Pts := S.Split(['|']);
  for K := 0 to High(Pts) do begin
   XY := Trim(Pts[K]).Split([',']);
   try
    if Length(XY) = 2 then Tw.Insert(TDot.Create(CsvToFloat(XY[1]), -CsvToFloat(XY[0]), 0)) else
   // числа с десятичной запятой: x,xx,y,yy
    if Length(XY) = 4 then Tw.Insert(TDot.Create(CsvToFloat(XY[2] + '.' + XY[3]), -CsvToFloat(XY[0] + '.' + XY[1]), 0));
   except
   end;
  end;
  if Tw.Coord.Count < 2 then begin
   Tw.Free;
   exit;
  end;
  LotX := TLot.Create(Pr.ID, Pr, 1);
  LotX.TypeLot := 1;
  LotX.SetProperty('$Type', 'Surface');
  LotX.SetProperty('Толщина', '0.4');
  LotX.SetProperty('Цвет', AnsiString(IntToStr(clrRed)));
  Twigs.Insert(Twg_Twig, Tw);
  Tw.SetMinMax;
  LotX.Insert(Twigs.TwigsCount - 1);
  Twigs.Insert(Twg_Lot, LotX);
  LotX.SetMinMax(Twigs);
 end;
end;
begin
 Header := TStringList.Create;
 Body := TStringList.Create;
 Geo := TDictionary<String, String>.Create;
 try
 // геометрия групп по номеру растения
  Header.Text := String(MakeString2(AnsiString(St[0]), ';'));
  IdCol := Header.IndexOf('№Растения');
  GeoCol := Header.IndexOf('Geometry');
  if (IdCol <> -1) and (GeoCol <> -1) then
   for I := 1 to St.Count - 1 do begin
    Body.Text := String(MakeString2(AnsiString(St[I]), ';'));
    if (Body.Count > GeoCol) and (Body.Count > IdCol) then Geo.AddOrSetValue(Body[IdCol], Body[GeoCol]);
   end;
  for J := 0 to Imported.Count - 1 do begin
   PD := Imported[J];
   ImportGeometry(PD);
   if (PD.GetProperty('*Порода') = '-') and (Pos('хвой', String(PD.GetProperty('*Порода МГГТ'))) <> 0) and (PD.GetZnak = 40) then begin
    PD.SetProperty('Знак', '34');
    PD.What := 34;
   end;
   FTwgForm.Twigs.Insert(TWG_Point, PD);
  // точка - в карте: при ошибке дальше не освобождается
   Imported[J] := nil;
  end;
  MessageInform(AnsiString(IntToStr(Imported.Count) + ' ЗН импортировано из файла ' + FileName));
  Imported.Clear;
  FTwgForm.ClassBuildII;
  FTwgForm.Modified := True;
  if Assigned(FOnChanged) then FOnChanged(Self);
 finally
  Header.Free;
  Body.Free;
  Geo.Free;
 end;
end;

procedure TFrameJSON.ImportCSV(const FileName: String);
var St: TStrings;
    Imported: TList<TPointDot>;
    I: Integer;
begin
 St := TStringList.Create;
 Imported := TList<TPointDot>.Create;
 try
  try
   CsvLoad(FileName, St);
   if LoadCSV(St, Imported) then ApplyImport(St, Imported, FileName);
  except
   on E: Exception do MessageError(AnsiString(E.Message));
  end;
 finally
 // точки, не попавшие в карту (ошибка разбора), освобождаются
  for I := 0 to Imported.Count - 1 do
   if Imported[I] <> nil then Imported[I].Free;
  Imported.Free;
  St.Free;
 end;
end;

end.
