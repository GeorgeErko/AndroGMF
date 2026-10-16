unit FrameDendro;

// Проверки зеленых насаждений (ЗН) из старой программы (TMasterDendro):
//  CheckFLK(False) - ФЛК для ЗН (N36Click / MIFLKZNClick, кнопка sbFLKZN):
//   жизненная форма, порода (Dendro.ini), высота/диаметр, принадлежность
//   газону (*№Участка), цепочка Состояние+Уточнения+Характеристика+Рекомендации;
//  CheckFLK(True) - атрибуты в группах ЗН (MIAttrGroupClick, кнопка sbAttrZN):
//   одинаковые значения атрибутов у растений одной группы одного газона;
//  FindWithoutLawn - растения без газонов, газоны без номера и с несколькими
//   номерами (BitBtn3Click, меню sbFindZN);
//  DeleteDuplicates - удаление дубликатов растений (BitBtn4Click).
// Ошибки - линии от объекта к углу карты в системном слое FLK (свойство
// *ErrorFLK / *Error), как в старой программе.
// Общие процедуры ЗН (GetProp0, znPointIn, ReadNamesSection) - для FrameJSON и
// главной формы.

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes,
     System.IOUtils, FMX.Types, FMX.Controls, FMX.Forms, Collect, EcDot,
     EcLot, WpTwigs, WptForm2, LBN, AppForms;

const
// цвета линий ошибок - COLORREF ($00BBGGRR), как свойство 'Цвет' контура
  clrRed = $000000FF;
  clrGreen = $00008000;
  clrBlue = $00FF0000;
  clrYellow = $0000FFFF;
  clrOrange = $0000A5FF;   // RGB(255,165,0)
  clrSkyBlue = $00FFA500;  // RGB(0,165,255)
  OGHType = '*Тип (ОГХ)';

type
  TFrameDendro = class(TFrame)
  private
   FTwgForm: TForm2;
   FError: String;
   procedure DrawError(const LayerName: String; Color: Integer; const ErrProp: String; X, Y: Double);
  public
   procedure CheckFLK(AttrGroup: Boolean);
   procedure FindWithoutLawn;
   function DeleteDuplicates: Integer;
  //
   property TwgForm: TForm2 read FTwgForm write FTwgForm;
  end;

// значение без кода в скобках: 'Хорошее [good]' -> 'Хорошее'
 function GetProp0(const S: String): String;
// то же для списка через запятую
 function GetPropArray(const S: String): String;
// точечный знак ЗН (дерево, кустарник, группы, изгородь, цветник, газон...)
 function IsDendroZnak(PD: TPointDot): Boolean;
// контур ЗН для точки (znPointIn старой программы): группа/изгородь - контур,
// на линии которого точка; цветник (28) - площадной цветник с точкой внутри
// (точка переносится внутрь); газон (201) - газон с точкой внутри
 function znPointIn(TwgForm: TForm2; Point: TPointDot; var Lot: TLot; UseSystemNumeration: Boolean): Boolean;
// свойства по умолчанию из секции Names.txt (ReadNamesSection)
 procedure ReadNamesSection(TwgForm: TForm2; const SectionName: String; Point: TPointDot);
// путь к справочнику рядом с программой (MainPath)
 function DendroDictPath(const FileName: String): String;

implementation

uses newProcs, newConsts, newResource, newProperties, UserObject, newSelector;

{$R *.fmx}

function GetProp0(const S: String): String;
begin
 if Pos('[', S) <> 0 then Result := Trim(Copy(S, 1, Pos('[', S) - 1)) else Result := S;
end;

function GetPropArray(const S: String): String;
var St: TStrings;
    I: Integer;
begin
 Result := '';
 St := TStringList.Create;
 try
  St.Text := String(MakeString2(AnsiString(S), ','));
  for I := 0 to St.Count - 1 do
   if I <> 0 then Result := Result + ',' + GetProp0(St[I]) else Result := Result + GetProp0(St[I]);
 finally
  St.Free;
 end;
end;

function IsDendroZnak(PD: TPointDot): Boolean;
begin
 Result := PD.What in [40, 97, 95, 34, 98, 99, 28, 103, 201];
end;

function DendroDictPath(const FileName: String): String;
begin
 Result := TPath.Combine(String(MainPath), FileName);
end;

function znPointIn(TwgForm: TForm2; Point: TPointDot; var Lot: TLot; UseSystemNumeration: Boolean): Boolean;
var I, J: Integer;
    Tw: TTwig;
    MM: Double;
    D: TDot;
begin
 Result := False;
 with TwgForm do
  for J := Twigs.LotsCount - 1 downto 0 do begin
   Lot := Twigs.LAt(J);
   if (Lot.ClassHandle = nil) or (Lot.ClassHandle.Parent = nil) then continue;
   if Point.What in [98, 99, 95, 28, 103] then begin
   // номер участка и растения - только при системной нумерации
    if UseSystemNumeration then begin
     if Point.GetProperty('*№Участка') <> Lot.GetProperty('*№Участка') then continue;
     if Point.GetProperty('*№Растения') <> Lot.GetProperty('*№Растения') then continue;
    end;
   // цветник - площадной контур, точка переносится внутрь контура
    if (Lot.ClassHandle.Parent.ID = 1900) and (Point.What = 28) then begin
     if not Lot.PointIn(Twigs, Point.XDot, Point.YDot) then continue;
     Lot.InsClipDotsParall(Twigs);
     D := TDot.CreateAsDot(Point);
     try
      Result := Lot.GetPointIn(D, Twigs);
      if Result then begin
       Point.XDot := D.XDot;
       Point.YDot := D.YDot;
      end;
     finally
      D.Free;
      Lot.Points.Free;
      Lot.Points := nil;
     end;
     if Result then exit;
    end else
   // группа, изгородь - точка на линии контура
    if Lot.ClassHandle.Parent.ID = 2900 then
     for I := 0 to Lot.Coord.Count - 1 do begin
      Tw := Lot.GetTwig(Twigs, I);
      if Tw = nil then continue;
      if Tw.GetTwigDist(Point.XDot, Point.YDot, MM, MM) <= 0.03 then begin
       Result := True;
       exit;
      end;
     end;
   end else
  // газон
   if Point.What = 201 then begin
    if UseSystemNumeration and (Point.GetProperty('*№Участка') <> Lot.GetProperty('*№Участка')) then continue;
    if (Round(Lot.ClassHandle.Parent.ID) = 1800) and Lot.PointIn(Twigs, Point.XDot, Point.YDot) then begin
     Result := True;
     exit;
    end;
   end;
  end;
 Lot := nil;
end;

procedure ReadNamesSection(TwgForm: TForm2; const SectionName: String; Point: TPointDot);
var SN: TSectionName;
    LNames: TListByName;
    I: Integer;
    St: TStrings;
begin
 LNames := TListByName.Create;
 St := TStringList.Create;
 try
  LNames.LoadFromFile(AnsiString(DendroDictPath('Names.txt')), AnsiString(oghObjectType(TwgForm)));
  SN := LNames.FindByName2(AnsiString(SectionName), 0);
  if SN = nil then exit;
  for I := 0 to SN.Count - 1 do begin
   St.Text := String(MakeString(AnsiString(SN[I]), '='));
   if St.Count > 2 then Point.SetProperty(AnsiString('*' + St[0]), AnsiString(St[2]));
  end;
 finally
  St.Free;
  LNames.Free;
 end;
end;

{ TFrameDendro }

// линия ошибки от точки (X, Y) к углу карты (XXMax, YYMin) в системном слое
procedure TFrameDendro.DrawError(const LayerName: String; Color: Integer; const ErrProp: String; X, Y: Double);
var Tw: TTwig;
    LotX: TLot;
    Layer: TResource;
begin
 with FTwgForm do begin
  Layer := LayerTable.AddExistSysLayer(AnsiString(LayerName));
  LotX := TLot.Create(Layer.ID, Layer, 1);
  LotX.TypeLot := 1;
  LotX.SetProperty('$Type', 'Surface');
  LotX.SetProperty('Толщина', '0.4');
  LotX.SetProperty('Цвет', AnsiString(IntToStr(Color)));
  Tw := TTwig.Create(Selector, 0);
  Twigs.Insert(Twg_Twig, Tw);
  Tw.Insert(TDot.Create(X, Y, 0));
  Tw.Insert(TDot.Create(XXMax, YYMin, 0));
  Tw.SetMinMax;
  LotX.Insert(Twigs.TwigsCount - 1);
  LotX.SetProperty(AnsiString(ErrProp), AnsiString(FError));
  Twigs.Insert(Twg_Lot, LotX);
  LotX.SetMinMax(Twigs);
 end;
end;

procedure TFrameDendro.CheckFLK(AttrGroup: Boolean);
var I: Integer;
    PD: TPointDot;
    B: Byte;
    List: TListByName;
function DrawLine(Color: Integer; Point: TPointDot): Boolean;
begin
 DrawError('FLK', Color, '*ErrorFLK', Point.XDot, Point.YDot);
 Result := False;
end;
function TreeValid(Point: TPointDot): Boolean;
var S: String;
    SN: TSectionName;
    H: Double;
    LotGazonNum: TLot;
    SA: AnsiString;
function CorrectWH(const Field: String; CheckNumber: Boolean): Boolean;
begin
 Result := False;
 S := GetProp0(String(Point.GetProperty(AnsiString(Field))));
 if (S = byLayer) or (S = '-') then begin
  FError := 'Не указано значение: ' + Field;
  DrawLine(clrOrange, Point);
  exit;
 end;
 if CheckNumber then
  try
   H := GStrToFloat(AnsiString(S));
  except
   FError := 'Некорректное заполнение: ' + Field;
   DrawLine(clrOrange, Point);
   exit;
  end;
 Result := True;
end;
function GetGazonNum(P: TPointDot): TLot;
var I: Integer;
    Lot: TLot;
    InGazon: Boolean;
    T: String;
begin
 Result := nil;
 InGazon := False;
 with FTwgForm do
  for I := Twigs.LotsCount - 1 downto 0 do begin
   Lot := Twigs.LAtIndex(I);
   T := GetProp0(String(Lot.GetProperty(OGHType)));
   if ((T = 'Газоны') or (T = 'Цветники')) and Lot.PointIn(Twigs, P.XDot, P.YDot) then begin
    InGazon := True;
    if Lot.GetProperty('*№Участка') = P.GetProperty('*№Участка') then begin
     Result := Lot;
     exit;
    end;
   end;
  end;
 if not AttrGroup then begin
  if not InGazon then FError := 'Растение: ' + String(P.GetProperty('*№Растения')) + ' не принадлежит газону' else
   FError := 'Не найден участок: ' + String(P.GetProperty('*№Участка')) + ' для растения: ' + String(P.GetProperty('*№Растения'));
  DrawLine(clrSkyBlue, Point);
 end;
end;
function CorrectGroups: Boolean;
var I, J: Integer;
    PD2, P: TPointDot;
    B: Byte;
    PropName: AnsiString;
begin
 Result := True;
 P := TPointDot.Create(0, 0, 0);
 try
  P.Properties := TProperties.Create;
  ReadNamesSection(FTwgForm, 'Деревья/Кустарники', P);
  with FTwgForm do
   for I := 0 to Twigs.AnyCount - 1 do begin
    PD2 := Twigs.AAt(I, B);
    if PD2 = Point then exit;
    if B <> TWG_Point then continue;
    if PD2.GetProperty(OGHType) <> 'Деревья/Кустарники' then continue;
    if PD2.GetProperty('*№Растения') <> Point.GetProperty('*№Растения') then continue;
    if GetGazonNum(PD2) <> LotGazonNum then continue;
    for J := 0 to P.Properties.Count - 1 do begin
     PropName := P.Properties[J].PropName;
     if PD2.GetProperty(PropName) <> Point.GetProperty(PropName) then begin
      FError := 'В группе №' + String(PD2.GetProperty('*№Растения')) + ' поле ' + String(PropName) + ' имеет разные значения';
      if Pos('В группе', String(PD2.GetProperty('*ErrorFLK'))) = 0 then DrawLine(clrRed, PD2);
      if Pos('В группе', String(Point.GetProperty('*ErrorFLK'))) = 0 then DrawLine(clrRed, Point);
      Result := False;
     end;
    end;
   end;
 finally
  P.Free;
 end;
end;
begin
 Result := False;
// жизненная форма, порода, высота/диаметр
 if not AttrGroup and (Point.ClassHandle <> nil) and (Point.ClassHandle.Parent <> nil) and (Pos('Деревья', String(Point.ClassHandle.Parent.RecString)) <> 0) then begin
  S := GetProp0(String(Point.GetProperty('*Жизненная форма ДИТ')));
  if (S <> 'Дерево') and (S <> 'Кустарник') then begin
   FError := 'Жизненная форма заполнена некорректно';
   DrawLine(clrOrange, Point);
   exit;
  end;
  SN := List.FindByName(AnsiString(S));
  if (SN = nil) or (SN.Find(AnsiString(GetProp0(String(Point.GetProperty('*Порода')))), True) = -1) then begin
   FError := 'Порода заполнена некорректно';
   DrawLine(clrOrange, Point);
   exit;
  end;
  if S = 'Дерево' then begin
   if not CorrectWH('*Высота, м.', True) then exit;
   if (H > 1.3) and not CorrectWH('*Диаметр на высоте 1.3м., см.', True) then exit;
  end else
   if not CorrectWH('*Высота, м.', True) then exit;
 end;
 LotGazonNum := GetGazonNum(Point);
 if LotGazonNum = nil then exit;
// Состояние -> Уточнения состояния -> Характеристика -> Рекомендации
 if not AttrGroup then begin
  S := GetProp0(String(Point.GetProperty('*Состояние'))) + ';' + GetProp0(String(Point.GetProperty('*Уточнения состояния'))) + ';' +
       GetProp0(String(Point.GetProperty('*Характеристика состояния'))) + ';' + GetProp0(String(Point.GetProperty('*Рекомендации по уходу')));
  SN := List.FindByName('Состояние+Уточнения состояния+Характеристика состояния+Рекомендации по уходу');
  SA := '';
  if not SN.Tree.FindByTree(AnsiString(S), SA) then begin
   FError := String(SN.Tree.Error);
   DrawLine(clrYellow, Point);
   exit;
  end;
 end;
// группы - одинаковые атрибуты
 if AttrGroup and not CorrectGroups then exit;
 Result := True;
end;
begin
 if FTwgForm = nil then exit;
 List := TListByName.Create;
 try
  if FileExists(DendroDictPath('Dendro.ini')) then List.LoadFromFile(AnsiString(DendroDictPath('Dendro.ini')), '');
  if (List.FindByName('Состояние+Уточнения состояния+Характеристика состояния+Рекомендации по уходу') = nil) or
     (List.FindByName('Дерево') = nil) or (List.FindByName('Кустарник') = nil) then begin
   MessageError('В файле Dendro.ini (' + AnsiString(DendroDictPath('Dendro.ini')) + ') отсутствуют обязательные секции:'#13#10 +
                'Состояние+Уточнения состояния+Характеристика состояния+Рекомендации по уходу'#13#10'Дерево'#13#10'Кустарник');
   exit;
  end;
  gEqualCaseInsProps := False;
  try
   with FTwgForm do
    for I := 0 to Twigs.AnyCount - 1 do begin
     PD := Twigs.AAt(I, B);
     if (B = TWG_Point) and (PD.GetProperty(OGHType) = 'Деревья/Кустарники') then TreeValid(PD);
    end;
  finally
   gEqualCaseInsProps := True;
  end;
  FTwgForm.ClassBuildII;
 finally
  List.Free;
 end;
end;

// растения без газонов, газоны без номера / с несколькими номерами
procedure TFrameDendro.FindWithoutLawn;
var I, N, CountLawn, Count: Integer;
    P: TPointDot;
    B: Byte;
    Lot: TLot;
function InLawn: Boolean;
var I: Integer;
    L: TLot;
begin
 Result := False;
 with FTwgForm do
  for I := Twigs.LotsCount - 1 downto 0 do begin
   L := Twigs.LAtIndex(I);
   if (Pos('Газоны', String(L.GetProperty(OGHType))) = 1) and L.PointIn(Twigs, P.XDot, P.YDot) then begin
    Result := True;
    exit;
   end;
  end;
end;
function LawnNumbers: Integer;
var I: Integer;
    PD: TPointDot;
    B: Byte;
begin
 Result := 0;
 with FTwgForm do
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if B <> TWG_Point then continue;
   if (PD.GetZnak = 201) and (PD.Symbol <> 10) and Lot.PointIn(Twigs, PD.XDot, PD.YDot) then begin
    Inc(Result);
    PD.Symbol := 10;
   end;
  end;
end;
procedure DrawLot(Color: Integer; const Err: String);
var D: TPointDot;
begin
 D := TPointDot.Create(0, 0, 0);
 try
  Lot.InsClipDotsParall(FTwgForm.Twigs);
  Lot.GetPointIn(D, FTwgForm.Twigs);
  Lot.Points.Free;
  Lot.Points := nil;
  FError := Err;
  DrawError('TreeWithoutLawn', Color, '*Error', D.XDot, D.YDot);
 finally
  D.Free;
 end;
end;
begin
 if FTwgForm = nil then exit;
 Count := 0;
 with FTwgForm do begin
  for I := 0 to Twigs.AnyCount - 1 do begin
   P := Twigs.AAt(I, B);
   if B <> TWG_Point then continue;
   N := P.GetZnak;
   if not (N in [40, 97, 34, 95, 98, 99, 103]) then continue;
   if not InLawn then begin
    FError := 'Растение не лежит на газоне';
    DrawError('TreeWithoutLawn', clrRed, '*Error', P.XDot, P.YDot);
    Inc(Count);
   end;
  end;
  for I := Twigs.LotsCount - 1 downto 0 do begin
   Lot := Twigs.LAtIndex(I);
   if Pos('Газоны', String(Lot.GetProperty(OGHType))) <> 1 then continue;
   CountLawn := LawnNumbers;
   if CountLawn = 0 then begin
    DrawLot(clrBlue, 'На газоне не найден идентификатор');
    Inc(Count);
   end else
   if CountLawn > 1 then begin
    DrawLot(clrGreen, 'Газон пронумерован более одного раза');
    Inc(Count);
   end;
  end;
  for I := 0 to Twigs.AnyCount - 1 do begin
   P := Twigs.AAt(I, B);
   if B = TWG_Point then P.Symbol := -1;
  end;
  ClassBuildII;
 end;
 if Count = 0 then MessageInform('Не найдено') else MessageInform(AnsiString('Найдено ' + IntToStr(Count)));
end;

// дубликаты растений: одинаковое положение и знак; удаляется точка без
// атрибутов (или без номера растения), если у другой они есть
function TFrameDendro.DeleteDuplicates: Integer;
var P, P1: TPointDot;
    I, J: Integer;
    B: Byte;
begin
 Result := 0;
 if FTwgForm = nil then exit;
 with FTwgForm do begin
  for I := 0 to Twigs.AnyCount - 1 do begin
   P := Twigs.AAt(I, B);
   if B <> TWG_Point then continue;
   for J := I + 1 to Twigs.AnyCount - 1 do begin
    P1 := Twigs.AAt(J, B);
    if B <> TWG_Point then continue;
    if not (Selector.EqualPoints(P, P1) and (P1.GetZnak = P.GetZnak)) then continue;
    if (P1.TextManager = nil) and (P.TextManager <> nil) then P1.Symbol := 100 else
    if (P.TextManager = nil) and (P1.TextManager <> nil) then P.Symbol := 100 else
    if (P.TextManager <> nil) and (P1.TextManager <> nil) then begin
     if (P1.TextManager.AttrValue('№ растения') = '') and (P.TextManager.AttrValue('№ растения') <> '') then P1.Symbol := 100 else
     if (P.TextManager.AttrValue('№ растения') = '') and (P1.TextManager.AttrValue('№ растения') <> '') then P.Symbol := 100;
    end;
   end;
  end;
  for I := Twigs.AnyCount - 1 downto 0 do begin
   P := Twigs.AAt(I, B);
   if (B = TWG_Point) and (P.Symbol = 100) then begin
    Twigs.DelAAt(I);
    Inc(Result);
   end;
  end;
 end;
 MessageInform(AnsiString('Найдено и удалено ' + IntToStr(Result) + ' точек.'));
end;

end.
