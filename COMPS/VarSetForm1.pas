unit VarSetForm1;

// Перенос модуля VarSetForm1 из Geomaster (Delphi 7, VCL): ввод атрибутов
// дендро-объектов (деревья, кустарники, живая изгородь) при установке знака.
// Справочники формы (Names, Dicts) загружаются при каждом вызове Execute, как
// в старой программе: список атрибутов - секция Names.txt по типу знака
// (Деревья/Кустарники_МГГТ, Цветники_МГГТ, Растения Красной книги_МГГТ,
// Газоны_МГГТ); значения - Dictionary_digits.txt ('*' + атрибут).
// Значения по знаку (жизненная форма, порода, тип, количество), возраст по
// породе и диаметру (возраст дерева.csv), площадь и протяженность; история
// введенных значений (файл <карта>.csv) - таблица hGrid, щелчок по строке
// подставляет диаметр, высоту и возраст. Значения пишутся в свойства точки
// ('*' + атрибут), номер - в первую надпись знака.
// Строки сетки FMX нумеруются с 0 (в VCL - с 1).

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, FMX.ListBox,
  FMX.Layouts, VarSetForm, System.Rtti, EcDot, WptForm2, LBN, System.ImageList,
  FMX.ImgList;

const
// строки атрибутов истории (в старой программе - Row - 1)
  idx_Num = 0;
  idx_Diam = 4;
  idx_Height = 5;
  idx_Age = 7;

type
  TVarSetDlg1 = class(TVarSetDlg)
    Button5: TButton;
    hGrid: TStringGrid;
    hcolNum: TStringColumn;
    hcolDiam: TStringColumn;
    hcolHeight: TStringColumn;
    hcolAge: TStringColumn;
    SpeedButton15: TSpeedButton;
    cbNotHistory: TCheckBox;
    sbLastNumber: TSpeedButton;
    ImageList1: TImageList;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean); override;
    procedure SpeedButton3Click(Sender: TObject); override;
    procedure hGridCellClick(const Column: TColumn; const Row: Integer);
    procedure Button5Click(Sender: TObject);
    procedure SpeedButton15Click(Sender: TObject);
    procedure sbLastNumberClick(Sender: TObject);
  protected
    FPoint: TPointDot;
    FHistFile: String;
   // история: окончание имени файла (<карта> + суффикс), строка файла - в hGrid,
   // строка hGrid - в атрибуты; ширина окна с историей; ключ автонумерации
    function HistorySuffix: String; virtual;
    procedure HistoryLineToGrid(St: TStrings; Row: Integer); virtual;
    procedure HistoryToGrid(Row: Integer); virtual;
    function HistoryWidth: Single; virtual;
    function IncKey: String; virtual;
    procedure LoadHistory;
    procedure SetHistoryVisible(Value: Boolean);
   // справочники формы и секция атрибутов GroupName; nil - секции нет (сообщение)
    function LoadDicts(const GroupName: String): TSectionName;
   // строки атрибутов секции: номер - последний введенный, остальные - свойства точки
    procedure FillFromSection(Section: TSectionName);
   // максимальный номер (первая надпись) знаков Znaks на карте + 1 - кнопка sbLastNumber
    procedure SetLastNumber(const Znaks: array of Integer);
    procedure FillAttrValues;
    function FindSection(const AName: String): TSectionName; override;
    procedure GetListValues(SN: TSectionName; Values: TStrings); override;
    procedure DoValueChanged(ARow: Integer); override;
    procedure StoreResults; override;
  public
   // справочники формы (перекрывают Names базовой формы - список имен)
    Names, Dicts: TListByName;
    Ages: TStringList;
    History: TStringList;
    MaxLastNumber: Integer;
    destructor Destroy; override;
    procedure ReplaceValues(const AName, Value: String);
    procedure Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone); override;
  end;

var
  VarSetDlg1: TVarSetDlg1;

// строка атрибута по имени; -1 - нет
function FindRow(Grid: TStringGrid; const CellName: String): Integer;

implementation

uses System.IOUtils, System.Math, FMX.DialogService, newProcs, textmanager, EcLot;

{$R *.fmx}

const
  WidthNoHistory = 581; // ширина окна без истории

function FindRow(Grid: TStringGrid; const CellName: String): Integer;
var I: Integer;
begin
 Result := -1;
 for I := 0 to Grid.RowCount - 1 do
  if Grid.Cells[0, I] = CellName then exit(I);
end;

// значение справочника без пояснения в квадратных скобках (GetProp0)
function GetProp0(const S: String): String;
begin
 if Pos('[', S) <> 0 then Result := Trim(Copy(S, 1, Pos('[', S) - 1)) else Result := S;
end;

// возраст по породе и диаметру (строки 'порода;диаметр;возраст')
function FindAge(Ages: TStrings; const TypeZN, DiamZN: String): String;
var I: Integer;
    St: TStringList;
begin
 Result := '';
 if Ages = nil then exit;
 St := TStringList.Create;
 try
  for I := 1 to Ages.Count - 1 do begin
   St.Text := String(MakeString(AnsiString(Ages[I]), ';'));
   if St.Count <> 3 then continue;
   if (AnsiLowerCase(TypeZN) = AnsiLowerCase(St[0])) and (DiamZN = St[1]) then Result := St[2];
  end;
 finally
  St.Free;
 end;
end;

// тип насаждения задает жизненную форму и количество
procedure _TypeZN(Grid: TStringGrid; const Value: String);
var Row, Row2: Integer;
begin
 Row := FindRow(Grid, 'Жизненная форма ДИТ');
 Row2 := FindRow(Grid, 'Количество, шт.');
 if (Row = -1) or (Row2 = -1) then exit;
 if (Value = 'Многорядная живая изгородь') or (Value = 'Однорядная живая изгородь') then begin
  Grid.Cells[1, Row] := 'Живая изгородь';
  Grid.Cells[1, Row2] := '';
 end else
 if Value = 'Одиночный' then begin
  Grid.Cells[1, Row] := 'Кустарник';
  Grid.Cells[1, Row2] := '1';
 end else begin
  Grid.Cells[1, Row] := 'Дерево';
  if Value = 'Группа' then Grid.Cells[1, Row2] := '' else Grid.Cells[1, Row2] := '1';
 end;
end;

// жизненная форма задает тип насаждения и количество
procedure _LifeForm(Grid: TStringGrid; const Value: String);
var Row, Row2: Integer;
begin
 Row := FindRow(Grid, 'Тип насаждения');
 Row2 := FindRow(Grid, 'Количество, шт.');
 if (Row = -1) or (Row2 = -1) then exit;
 if Value = 'Живая изгородь' then begin
  Grid.Cells[1, Row] := 'Однорядная живая изгородь';
  Grid.Cells[1, Row2] := '';
 end else
 if Value = 'Кустарник' then begin
  Grid.Cells[1, Row] := 'Одиночный';
  Grid.Cells[1, Row2] := '1';
 end else begin
  Grid.Cells[1, Row] := 'Одиночная';
  Grid.Cells[1, Row2] := '1';
 end;
end;

{ TVarSetDlg1 }

destructor TVarSetDlg1.Destroy;
begin
 Names.Free;
 Dicts.Free;
 Ages.Free;
 History.Free;
 inherited;
end;

// справочник значений - Dicts (Dictionary_digits.txt), секция '*' + атрибут
function TVarSetDlg1.FindSection(const AName: String): TSectionName;
begin
 Result := nil;
 if (AName = '') or (Dicts = nil) then exit;
 Result := Dicts.FindByName2(AnsiString('*' + AName), 0);
end;

procedure TVarSetDlg1.GetListValues(SN: TSectionName; Values: TStrings);
var I: Integer;
begin
 inherited;
 for I := 0 to Values.Count - 1 do Values[I] := GetProp0(Values[I]);
end;

procedure TVarSetDlg1.DoValueChanged(ARow: Integer);
begin
 if (ARow >= 0) and (ARow < Grid.RowCount) then ReplaceValues(Grid.Cells[0, ARow], Grid.Cells[1, ARow]);
end;

// пересчет зависимых значений: тип/жизненная форма, возраст, площадь и протяженность
procedure TVarSetDlg1.ReplaceValues(const AName, Value: String);
var Row, P1, P2, RowLF, RowCount, RowSQ, RowLen: Integer;
    Age: String;
begin
 if AName = 'Тип насаждения' then _TypeZN(Grid, Value) else
 if AName = 'Жизненная форма ДИТ' then _LifeForm(Grid, Value);
 Row := FindRow(Grid, 'Возраст, лет');
 P1 := FindRow(Grid, 'Порода МГГТ');
 P2 := FindRow(Grid, 'Диаметр на высоте 1.3м., см.');
 if (P1 = -1) or (P2 = -1) then exit;
 Age := FindAge(Ages, Grid.Cells[1, P1], Grid.Cells[1, P2]);
 if Row = -1 then exit;
 if Age <> '' then Grid.Cells[1, Row] := Age;
 RowLF := FindRow(Grid, 'Жизненная форма ДИТ');
 RowCount := FindRow(Grid, 'Количество, шт.');
 RowSQ := FindRow(Grid, 'Площадь, кв.м.');
 RowLen := FindRow(Grid, 'Протяженность, п.м.');
 if (RowLF = -1) or (RowCount = -1) or (RowSQ = -1) or (RowLen = -1) then exit;
 try
  if (Grid.Cells[1, RowLF] = 'Кустарник') or (Grid.Cells[1, RowLF] = 'Живая изгородь') then begin
   Grid.Cells[1, RowSQ] := FloatToStrF(StrToInt(Grid.Cells[1, RowCount]) * 0.3, ffFixed, 15, 1);
  // протяженность - длина нарисованной линии (живая изгородь)
   if GLastPrimLength >= 0 then Grid.Cells[1, RowLen] := FloatToStrF(GLastPrimLength, ffFixed, 15, 2) else
                                Grid.Cells[1, RowLen] := '-';
   if Grid.Cells[1, RowLF] <> 'Живая изгородь' then Grid.Cells[1, RowLen] := '-';
  end else
  if Grid.Cells[1, RowLF] = 'Дерево' then begin
   Grid.Cells[1, RowSQ] := FloatToStrF(StrToInt(Grid.Cells[1, RowCount]) * 0.5, ffFixed, 15, 1);
   Grid.Cells[1, RowLen] := '-';
  end;
 except
 end;
end;

// значения по знаку: дерево лиственное/хвойное, кустарник, группы, живая изгородь
procedure TVarSetDlg1.FillAttrValues;
var RowLF, RowType, RowPoroda, RowCount, Z: Integer;
begin
 RowLF := FindRow(Grid, 'Жизненная форма ДИТ');
 RowPoroda := FindRow(Grid, 'Порода МГГТ');
 RowType := FindRow(Grid, 'Тип насаждения');
 RowCount := FindRow(Grid, 'Количество, шт.');
 if (RowLF = -1) or (RowType = -1) or (RowPoroda = -1) or (RowCount = -1) then exit;
 Z := FPoint.GetZnak;
 if (Z = 40) or (Z = 99) then begin
  Grid.Cells[1, RowLF] := 'Дерево';
  Grid.Cells[1, RowPoroda] := 'Лиственное';
  Grid.Cells[1, RowType] := 'Одиночная';
  Grid.Cells[1, RowCount] := '1';
  if Z = 99 then begin
   Grid.Cells[1, RowType] := 'Группа';
   Grid.Cells[1, RowCount] := '';
  end;
 end else
 if Z = 34 then begin
  Grid.Cells[1, RowLF] := 'Дерево';
  Grid.Cells[1, RowPoroda] := 'Хвойное';
  Grid.Cells[1, RowType] := 'Одиночная';
  Grid.Cells[1, RowCount] := '1';
 end else
 if (Z = 95) or (Z = 98) or (Z = 97) then begin
  Grid.Cells[1, RowLF] := 'Кустарник';
  Grid.Cells[1, RowPoroda] := 'Лиственное';
  Grid.Cells[1, RowType] := 'Одиночный';
  Grid.Cells[1, RowCount] := '1';
  if Z = 95 then begin
   Grid.Cells[1, RowLF] := 'Живая изгородь';
   Grid.Cells[1, RowType] := 'Однорядная живая изгородь';
   Grid.Cells[1, RowCount] := '';
  end;
  if Z = 98 then begin
   Grid.Cells[1, RowType] := 'Группа';
   Grid.Cells[1, RowCount] := '';
  end;
 end;
end;

function TVarSetDlg1.HistorySuffix: String;
begin
 Result := '.csv';
end;

function TVarSetDlg1.HistoryWidth: Single;
begin
 Result := 854;
end;

function TVarSetDlg1.IncKey: String;
begin
 Result := '_Inc';
end;

// строка истории: номер, диаметр, высота, возраст
procedure TVarSetDlg1.HistoryLineToGrid(St: TStrings; Row: Integer);
begin
 if St.Count > idx_Num then hGrid.Cells[0, Row] := St[idx_Num];
 if St.Count > idx_Diam then hGrid.Cells[1, Row] := St[idx_Diam];
 if St.Count > idx_Height then hGrid.Cells[2, Row] := St[idx_Height];
 if St.Count > idx_Age then hGrid.Cells[3, Row] := St[idx_Age];
end;

// история введенных значений: файл <имя карты> + HistorySuffix рядом с картой
procedure TVarSetDlg1.LoadHistory;
var I: Integer;
    St: TStringList;
    Path, MapName: String;
begin
 History := TStringList.Create;
 FHistFile := '';
 Path := String(TwgForm.About.Path);
 MapName := String(TwgForm.About.MyName);
 if (Path <> '') and (MapName <> '') then FHistFile := TPath.Combine(Path, TPath.GetFileNameWithoutExtension(MapName) + HistorySuffix);
 if (FHistFile <> '') and TFile.Exists(FHistFile) then
  try History.LoadFromFile(FHistFile); except end;
 hGrid.RowCount := History.Count;
 St := TStringList.Create;
 try
  for I := 0 to History.Count - 1 do begin
   St.Text := String(MakeString2(AnsiString(History[I]), ';'));
   HistoryLineToGrid(St, I);
  end;
 finally
  St.Free;
 end;
 if hGrid.RowCount > 0 then hGrid.Row := 0;
end;

function TVarSetDlg1.LoadDicts(const GroupName: String): TSectionName;
begin
 FreeAndNil(Names);
 FreeAndNil(Dicts);
 Names := TListByName.Create;
 Names.LoadFromFile(MainPath + 'Names.txt', AnsiString(oghObjectType(TwgForm)));
 Dicts := TListByName.Create(0);
 Dicts.LoadFromFile(MainPath + 'Dictionary_digits.txt', AnsiString(oghObjectType(TwgForm)));
 Result := Names.FindByName2(AnsiString(GroupName), 0);
 if Result = nil then
  FMX.Dialogs.ShowMessage('Не найдена секция ' + GroupName + ' в справочнике ' + String(MainPath) + 'Names.txt' +
   '. Тип объекта: ' + oghObjectType(TwgForm));
end;

procedure TVarSetDlg1.FillFromSection(Section: TSectionName);
var I: Integer;
    V: String;
begin
 Grid.RowCount := Section.Count;
 for I := 0 to Section.Count - 1 do begin
  Grid.Cells[0, I] := String(Section.GetValueForIndex(I, 0));
  if I = 0 then V := String(GReadString(AnsiString(Name + '_' + Grid.Cells[0, I]), '1')) else begin
   V := String(FPoint.GetProperty(AnsiString('*' + Grid.Cells[0, I])));
   if V = byLayer then V := '';
  end;
  Grid.Cells[1, I] := V;
 end;
 UpdateListFlags;
 Grid.Col := 1;
end;

procedure TVarSetDlg1.SetLastNumber(const Znaks: array of Integer);
var I, J, K, N, Z: Integer;
    PD: TPointDot;
    B: Byte;
begin
 J := 0;
 for I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
  PD := TwgForm.Twigs.AAt(I, B);
  if not (TObject(PD) is TPointDot) or (PD.TextManager = nil) or (PD.TextManager.FValues.Count = 0) then continue;
  Z := PD.GetZnak;
  for K := 0 to High(Znaks) do
   if Z = Znaks[K] then begin
    try
     N := StrToInt(String(TTextParams(PD.TextManager.FValues[0]).FValue));
     if N > J then J := N;
    except end;
    break;
   end;
 end;
 sbLastNumber.Text := IntToStr(J) + ' + 1';
 MaxLastNumber := J + 1;
end;

// строка истории - диаметр, высота, возраст
procedure TVarSetDlg1.HistoryToGrid(Row: Integer);
begin
 if (Row < 0) or (Row >= hGrid.RowCount) then exit;
 StopEdit;
 if idx_Diam < Grid.RowCount then Grid.Cells[1, idx_Diam] := hGrid.Cells[1, Row];
 if idx_Height < Grid.RowCount then Grid.Cells[1, idx_Height] := hGrid.Cells[2, Row];
 if idx_Age < Grid.RowCount then Grid.Cells[1, idx_Age] := hGrid.Cells[3, Row];
end;

procedure TVarSetDlg1.hGridCellClick(const Column: TColumn; const Row: Integer);
begin
 HistoryToGrid(Row);
end;

procedure TVarSetDlg1.SetHistoryVisible(Value: Boolean);
begin
 if Value then ClientWidth := Round(HistoryWidth) else ClientWidth := WidthNoHistory;
 if Value then Button5.Text := '< История' else Button5.Text := 'История >';
end;

procedure TVarSetDlg1.Button5Click(Sender: TObject);
begin
 SetHistoryVisible(ClientWidth < HistoryWidth);
end;

procedure TVarSetDlg1.SpeedButton15Click(Sender: TObject);
begin
 TDialogService.MessageDialog('Очистить историю?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
  procedure(const AResult: TModalResult)
  begin
   if AResult <> mrYes then exit;
   History.Clear;
   hGrid.RowCount := 0;
   if FHistFile <> '' then
    try History.SaveToFile(FHistFile); except end;
  end);
end;

procedure TVarSetDlg1.sbLastNumberClick(Sender: TObject);
begin
 StopEdit;
 if Grid.RowCount > 0 then Grid.Cells[1, 0] := IntToStr(MaxLastNumber);
end;

// цифровая клавиатура - текущая строка: Tag - цифра, -1 - очистить, -2 - точка
procedure TVarSetDlg1.SpeedButton3Click(Sender: TObject);
var R: Integer;
begin
 StopEdit;
 R := Grid.Row;
 if (R < 0) or (R >= Grid.RowCount) then exit;
 case TComponent(Sender).Tag of
  -1: Grid.Cells[1, R] := '';
  -2: if Pos('.', Grid.Cells[1, R]) = 0 then Grid.Cells[1, R] := Grid.Cells[1, R] + '.';
 else
  Grid.Cells[1, R] := Grid.Cells[1, R] + IntToStr(TComponent(Sender).Tag);
 end;
 ReplaceValues(Grid.Cells[0, R], Grid.Cells[1, R]);
end;

// OK: все атрибуты должны быть заполнены
procedure TVarSetDlg1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var I: Integer;
begin
 CanClose := True;
 if (ModalResult <> mrOk) and not Closed then exit;
 StopEdit;
 for I := 0 to Grid.RowCount - 1 do
  if (Grid.Cells[0, I] <> '') and (Trim(Grid.Cells[1, I]) = '') then begin
   FMX.Dialogs.ShowMessage('Введите значение для атрибута ' + Grid.Cells[0, I]);
   Grid.Col := 1;
   Grid.Row := I;
   Grid.SetFocus;
   CanClose := False;
   Closed := False;
   exit;
  end;
end;

// атрибуты - в свойства точки ('*' + атрибут), номер - в первую надпись знака;
// строка значений - в историю
procedure TVarSetDlg1.StoreResults;
var I, J: Integer;
    S: String;
    Lot, LotLawn: TLot;
begin
 GWriteInteger(AnsiString(Name + '_Width'), Round(ClientWidth));
 GWriteInteger(AnsiString(Name + IncKey), Ord(CInc.IsChecked));
 if Grid.RowCount > 0 then GWriteString(AnsiString(Name + '_' + Grid.Cells[0, 0]), AnsiString(Grid.Cells[1, 0]));
// газон под точкой (слой - в группе с ID 1800) - номер участка
 LotLawn := nil;
 for J := TwgForm.Twigs.IndexCount - 1 downto 0 do begin
  Lot := TwgForm.Twigs.LAtIndex(J);
  if (Lot.ClassHandle <> nil) and (Lot.ClassHandle.Parent <> nil) and (Round(Lot.ClassHandle.Parent.ID) = 1800) and
     Lot.PointIn(TwgForm.Twigs, FPoint.XDot, FPoint.YDot) then begin
   LotLawn := Lot;
   break;
  end;
 end;
 FPoint.SetProperty('*Тип (ОГХ)', 'Деревья/Кустарники');
 S := '';
 for I := 0 to Grid.RowCount - 1 do
  if Grid.Cells[0, I] <> '' then begin
   FPoint.SetProperty(AnsiString('*' + Grid.Cells[0, I]), AnsiString(Grid.Cells[1, I]));
   if I = 0 then begin
    S := Grid.Cells[1, I];
    if (LotLawn = nil) or (LotLawn.GetProperty('*№Участка') = byLayer) then FPoint.SetProperty('*№Участка', '1') else
                                                                         FPoint.SetProperty('*№Участка', LotLawn.GetProperty('*№Участка'));
   end else
    S := S + ';' + Grid.Cells[1, I];
  end;
 if not cbNotHistory.IsChecked then begin
  History.Insert(0, S);
  if FHistFile <> '' then
   try History.SaveToFile(FHistFile); except end;
 end;
 if (FPoint.TextManager <> nil) and (FPoint.TextManager.FValues.Count > 0) and (Grid.RowCount > 0) then
  TTextParams(FPoint.TextManager.FValues[0]).FValue := AnsiString(Grid.Cells[1, 0]);
end;

procedure TVarSetDlg1.Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone);
var I, RowCount: Integer;
    GroupName: String;
    Section: TSectionName;
    AgesFile: String;
procedure Fail;
begin
 if Assigned(Done) then Done(False);
 TThread.ForceQueue(nil, procedure begin Free; end);
end;
begin
 TwgForm := TwgForm_;
 FPoint := Point;
 if (TwgForm = nil) or (Point = nil) then begin Fail; exit; end;
// максимальный номер дендро-знаков на карте
 SetLastNumber([40, 99, 34, 95, 97, 98]);
// окно и история
 SetHistoryVisible(GReadInteger(AnsiString(Name + '_Width'), WidthNoHistory) >= HistoryWidth);
 LoadHistory;
// возраст по породе и диаметру
 Ages := TStringList.Create;
 AgesFile := String(MainPath) + 'возраст дерева.csv';
 if TFile.Exists(AgesFile) then
  try Ages.LoadFromFile(AgesFile); except end;
// секция атрибутов по типу знака
 case Point.GetZnak of
  28: GroupName := 'Цветники_МГГТ';
  103: GroupName := 'Растения Красной книги_МГГТ';
  201: GroupName := 'Газоны_МГГТ';
 else
  GroupName := 'Деревья/Кустарники_МГГТ';
 end;
 CInc.IsChecked := GReadInteger(AnsiString(Name + IncKey), 0) = 1;
// чтение справочников
 Section := LoadDicts(GroupName);
 if Section = nil then begin Fail; exit; end;
 FillFromSection(Section);
 if not EditMode then HistoryToGrid(0);
 FillAttrValues;
 I := FindRow(Grid, 'Порода МГГТ');
 if I <> -1 then ReplaceValues(Grid.Cells[0, I], Grid.Cells[1, I]);
 if CInc.IsChecked and (Grid.RowCount > 0) then
  try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) + 1);
  except end;
 RowCount := FindRow(Grid, 'Количество, шт.');
 if (RowCount <> -1) and (Grid.Cells[1, RowCount] = '') then Grid.Row := RowCount else Grid.Row := 0;
 ShowDialog(Done);
end;

end.
