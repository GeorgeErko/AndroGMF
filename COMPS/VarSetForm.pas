unit VarSetForm;

// Перенос модуля VarSetForm из Geomaster (Delphi 7, VCL): диалог ввода значений
// текстовых атрибутов знака (TTextManager.SetTexts, SetTexts2).
// Сетка FMX: строк-заголовков нет (заголовки - у колонок), строки атрибутов
// начинаются с 0 (в VCL - с 1). Колонка имен только для чтения.
// Справочник атрибута (ListByName / ListByDicts) - значок «…» в ячейке
// значения (бывшая кнопка CDop), по нему - список значений.
// Диалог показывается немодально для вызывающего кода (на Android синхронного
// ShowModal нет): результат приходит в обработчик Done, форма освобождается сама.
// Не перенесено: экспорт в Excel (Button3, Tree_Excel), вычисление площади
// (sbPlo, FormulaUnit), дерево атрибутов (TreeAttrForm), выбор из справочника
// (MsnpDlg) - вместо него список значений.

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Rtti, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, FMX.ListBox, FMX.Layouts,
  Collect, WptForm2, EcDot, LBN, textmanager;

type
 // результат диалога: OK - значения записаны в атрибуты
  TVarSetDone = TTextsDone;

  TVarSetDlg = class(TForm)
    Panel1: TPanel;
    Grid: TStringGrid;
    colName: TStringColumn;
    colValue: TStringColumn;
    ListCombo: TComboBox;
    Button1: TButton;
    Button2: TButton;
    CBCoord: TCheckBox;
    CBZ: TCheckBox;
    CInc: TCheckBox;
    sbPlo: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean); virtual;
    procedure GridSelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
    procedure GridKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure GridCellClick(const Column: TColumn; const Row: Integer);
    procedure GridCellDblClick(const Column: TColumn; const Row: Integer);
    procedure GridEditingDone(Sender: TObject; const ACol, ARow: Integer);
    procedure GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
      const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
    procedure ListComboChange(Sender: TObject);
    procedure ListComboClosePopup(Sender: TObject);
    procedure CBCoordChange(Sender: TObject);
    procedure CBZChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject); virtual;
    procedure Button4Click(Sender: TObject);
  private
    FLastMouseDown: TPointF;
    FListRow: Integer;
    FHasList: TArray<Boolean>;
    function ListIconRect(const CellBounds: TRectF): TRectF;
  protected
    FValues: PCollection;
    FTexts: PCollection;
    procedure UpdateListFlags;
   // значение строки ARow изменено (ввод, список, клавиатура): наследники
   // пересчитывают зависимые строки (дендро: ReplaceValues)
    procedure DoValueChanged(ARow: Integer); virtual;
   // значения справочника для списка (наследник может обработать строки)
    procedure GetListValues(SN: TSectionName; Values: TStrings); virtual;
    function FindSection(const AName: String): TSectionName; virtual;
    procedure StopEdit;
    procedure OpenList(ARow: Integer);
   // заполнение сетки именами и значениями; False - атрибутов нет
    function FillGrid(Names_: TStrings; Values: PCollection): Boolean; virtual;
   // OK: значения из сетки - в атрибуты и в реестр (последние введенные)
    procedure StoreResults; virtual;
   // показ: результат - в Done, затем форма освобождается
    procedure ShowDialog(const Done: TVarSetDone);
  public
    Closed: Boolean;
    XDot, YDot, ZDot: Double;
    UpdateResults: Boolean;
    TwgForm: TForm2;
    Names: TStrings;
    destructor Destroy; override;
   // TTextManager.SetTexts2: атрибуты знака точки (наследники - дендро-формы)
    procedure Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone); virtual;
   // TTextManager.SetTexts: имена, значения и тексты менеджера текстов
    procedure Execute_Old(Names_: TStrings; Values, TEXTS: PCollection; X, Y, Z: Double; UseCoord: Boolean;
      TwgForm_: TForm2; const Done: TVarSetDone);
  end;

  TVarSetDlgClass = class of TVarSetDlg;

var
// форма для SetTexts2: по умолчанию TVarSetDlg, в режиме TABLET - варианты
// TVarSetDlg1/2/3 (выбирает вызывающий код)
  GlobalVarSetDlgClass: TVarSetDlgClass;
// длина последнего нарисованного примитива (дендро: протяженность живой
// изгороди); задает обработчик мыши перед диалогом, -1 - нет
  GLastPrimLength: Double = -1;

implementation uses System.Math, newProcs, dwgtext;

{$R *.fmx}

const
  DigitsCoord = 3;  // знаков после запятой для координат
  DigitsHeight = 3; // для высоты

{ TVarSetDlg }

procedure TVarSetDlg.FormCreate(Sender: TObject);
begin
 FListRow := -1;
 colName.Header := 'Имя переменной';
 colValue.Header := 'Значение';
 ListCombo.Visible := False;
end;

destructor TVarSetDlg.Destroy;
begin
 FreeAndNil(Names);
 inherited;
end;

// справочник атрибута: Names.txt (ListByName) или словари (ListByDicts)
function TVarSetDlg.FindSection(const AName: String): TSectionName;
begin
 Result := nil;
 if AName = '' then exit;
 if ListByName <> nil then Result := ListByName.FindByName(AnsiString(AName));
 if (Result = nil) and (ListByDicts <> nil) then begin
  Result := ListByDicts.FindByName2(AnsiString(AName), 0);
  if Result = nil then Result := ListByDicts.FindByName2(AnsiString('*' + AName), 0);
 end;
end;

procedure TVarSetDlg.DoValueChanged(ARow: Integer);
begin
end;

procedure TVarSetDlg.GetListValues(SN: TSectionName; Values: TStrings);
var St: TStrings;
begin
 St := SN.GetStrings(False);
 try
  Values.Assign(St);
 finally
  St.Free;
 end;
end;

procedure TVarSetDlg.GridEditingDone(Sender: TObject; const ACol, ARow: Integer);
begin
 if ACol = 1 then DoValueChanged(ARow);
end;

procedure TVarSetDlg.UpdateListFlags;
var I: Integer;
begin
 SetLength(FHasList, Grid.RowCount);
 for I := 0 to Grid.RowCount - 1 do FHasList[I] := FindSection(Grid.Cells[0, I]) <> nil;
end;

// значок «…» справочника - справа в ячейке значения
function TVarSetDlg.ListIconRect(const CellBounds: TRectF): TRectF;
begin
 Result := CellBounds;
 Result.Left := Result.Right - Min(22, CellBounds.Height);
end;

// закончить редактирование ячейки (перед программной записью в Cells)
procedure TVarSetDlg.StopEdit;
begin
 if Grid.EditorMode then Grid.EditorMode := False;
end;

function TVarSetDlg.FillGrid(Names_: TStrings; Values: PCollection): Boolean;
var I: Integer;
    V: String;
begin
 Result := (Names_ <> nil) and (Names_.Count > 0);
 if not Result then exit;
 Grid.RowCount := Names_.Count;
 for I := 0 to Names_.Count - 1 do begin
  Grid.Cells[0, I] := Names_[I];
  V := '';
  if (Values <> nil) and (I < Values.Count) then begin
  // первое значение (номер) и не обновляемые - последние введенные
   if (not UpdateResults) or (I = 0) then
    V := String(GReadString(AnsiString(Name + '_' + Names_[I]), TTextParams(Values[I]).FValue))
   else
    V := String(TTextParams(Values[I]).FValue);
  end;
  Grid.Cells[1, I] := V;
 end;
 UpdateListFlags;
 if CInc.IsChecked then
  try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) + 1);
  except end;
 Grid.Col := 1;
 Grid.Row := 0;
end;

procedure TVarSetDlg.StoreResults;
var I: Integer;
begin
 GWriteInteger(AnsiString(Name + '_Inc'), Ord(CInc.IsChecked));
 for I := 0 to Grid.RowCount - 1 do begin
  GWriteString(AnsiString(Name + '_' + Grid.Cells[0, I]), AnsiString(Grid.Cells[1, I]));
  if (FTexts <> nil) and (I < FTexts.Count) then TDwg_Text(FTexts[I]).FName := AnsiString(Grid.Cells[0, I]);
  if (FValues <> nil) and (I < FValues.Count) then TTextParams(FValues[I]).FValue := AnsiString(Grid.Cells[1, I]);
 end;
end;

procedure TVarSetDlg.ShowDialog(const Done: TVarSetDone);
begin
 Closed := False;
 ShowModal(
  procedure(AResult: TModalResult)
  var OK: Boolean;
  begin
   OK := (AResult = mrOk) or Closed;
   if OK then StoreResults;
   try
    if Assigned(Done) then Done(OK);
   finally
    TThread.ForceQueue(nil, procedure begin Free; end);
   end;
  end);
end;

procedure TVarSetDlg.Execute_Old(Names_: TStrings; Values, TEXTS: PCollection; X, Y, Z: Double;
  UseCoord: Boolean; TwgForm_: TForm2; const Done: TVarSetDone);
begin
 CInc.IsChecked := GReadInteger(AnsiString(Name + '_Inc'), 0) = 1;
 TwgForm := TwgForm_;
 FreeAndNil(Names);
 Names := TStringList.Create;
 if Names_ <> nil then Names.Assign(Names_);
 FValues := Values;
 FTexts := TEXTS;
 XDot := X;
 YDot := Y;
 ZDot := Z;
 CBCoord.Visible := UseCoord;
 CBZ.Visible := ZDot <> ZNull;
 if not FillGrid(Names, FValues) then begin
  if Assigned(Done) then Done(False);
  TThread.ForceQueue(nil, procedure begin Free; end);
  exit;
 end;
 ShowDialog(Done);
end;

// атрибуты знака точки (менеджер текстов точки); наследники заполняют сетку
// по своим правилам (дендро: порода, тип, история значений)
procedure TVarSetDlg.Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte;
  const Done: TVarSetDone);
var SL: TStringList;
    I: Integer;
begin
 if (Point = nil) or (Point.TextManager = nil) then begin
  if Assigned(Done) then Done(False);
  TThread.ForceQueue(nil, procedure begin Free; end);
  exit;
 end;
 UpdateResults := EditMode or Point.TextManager.UpdateResults;
 SL := TStringList.Create;
 try
  for I := 0 to Point.TextManager.FTexts.Count - 1 do SL.Add(String(TDwg_Text(Point.TextManager.FTexts[I]).FName));
  Execute_Old(SL, Point.TextManager.FValues, Point.TextManager.FTexts, Point.XDot, Point.YDot, Point.Z, False, TwgForm_, Done);
 finally
  SL.Free;
 end;
end;

procedure TVarSetDlg.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var I, J: Integer;
begin
 CanClose := True;
 if (ModalResult <> mrOk) and not Closed then exit;
 StopEdit;
 for I := 0 to Grid.RowCount - 2 do
  for J := I + 1 to Grid.RowCount - 1 do
   if AnsiCompareText(Grid.Cells[0, I], Grid.Cells[0, J]) = 0 then begin
    FMX.Dialogs.ShowMessage(Format('Ошибка: переменная с именем "%s" уже есть', [Grid.Cells[0, I]]));
    CanClose := False;
    exit;
   end;
end;

procedure TVarSetDlg.GridSelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
begin
// колонка имен не выбирается (в VCL - CanSelect := ACol > 0)
 CanSelect := ACol > 0;
end;

procedure TVarSetDlg.GridKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
// Enter - ввод закончен (как в старой программе)
 if Key = vkReturn then begin
  Key := 0;
  StopEdit;
  Closed := True;
  ModalResult := mrOk;
 end;
end;

procedure TVarSetDlg.GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 FLastMouseDown := PointF(X, Y);
end;

procedure TVarSetDlg.GridDrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
  const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var R: TRectF;
begin
 if (Column <> colValue) or (Row < 0) or (Row >= Length(FHasList)) or not FHasList[Row] then exit;
 R := ListIconRect(Bounds);
 R.Inflate(-2, -2);
 Canvas.Fill.Color := TAlphaColors.Lightgray;
 Canvas.FillRect(R, 2, 2, AllCorners, 1);
 Canvas.Fill.Color := TAlphaColors.Black;
 Canvas.FillText(R, '…', False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

// щелчок по значку «…» ячейки значения - список значений справочника
procedure TVarSetDlg.GridCellClick(const Column: TColumn; const Row: Integer);
var R: TRectF;
begin
 if (Column <> colValue) or (Row < 0) or (Row >= Length(FHasList)) or not FHasList[Row] then exit;
 R := ListIconRect(Grid.CellRect(1, Row));
 if FLastMouseDown.X >= R.Left then OpenList(Row);
end;

procedure TVarSetDlg.GridCellDblClick(const Column: TColumn; const Row: Integer);
begin
 if (Row >= 0) and (Row < Length(FHasList)) and FHasList[Row] then OpenList(Row);
end;

// список значений справочника под ячейкой (вместо MsnpDlg старой программы)
procedure TVarSetDlg.OpenList(ARow: Integer);
var SN: TSectionName;
    St: TStringList;
    P: TPointF;
begin
 SN := FindSection(Grid.Cells[0, ARow]);
 if SN = nil then exit;
 StopEdit;
 St := TStringList.Create;
 try
  GetListValues(SN, St);
  ListCombo.OnChange := nil;
  ListCombo.Items.Assign(St);
  ListCombo.ItemIndex := ListCombo.Items.IndexOf(Grid.Cells[1, ARow]);
  ListCombo.OnChange := ListComboChange;
 finally
  St.Free;
 end;
 FListRow := ARow;
// по высоте - у ячейки, по которой щелкнули
 P := Panel1.AbsoluteToLocal(Grid.LocalToAbsolute(PointF(0, FLastMouseDown.Y)));
 ListCombo.Position.X := Grid.Position.X + colName.Width;
 ListCombo.Position.Y := P.Y;
 ListCombo.Width := Max(colValue.Width, 120);
 ListCombo.Visible := True;
 ListCombo.BringToFront;
 TThread.Queue(nil, procedure begin if ListCombo.Visible then ListCombo.DropDown; end);
end;

procedure TVarSetDlg.ListComboChange(Sender: TObject);
begin
 if (FListRow < 0) or (FListRow >= Grid.RowCount) or (ListCombo.ItemIndex < 0) then exit;
 Grid.Cells[1, FListRow] := ListCombo.Items[ListCombo.ItemIndex];
 DoValueChanged(FListRow);
end;

procedure TVarSetDlg.ListComboClosePopup(Sender: TObject);
begin
 ListCombo.Visible := False;
 FListRow := -1;
end;

// плановые координаты точки - в первые две строки
procedure TVarSetDlg.CBCoordChange(Sender: TObject);
begin
 StopEdit;
 if Grid.RowCount < 2 then exit;
 if CBCoord.IsChecked then begin
  Grid.Cells[1, 0] := FloatToStrF(-YDot, ffFixed, 15, DigitsCoord);
  Grid.Cells[1, 1] := FloatToStrF(XDot, ffFixed, 15, DigitsCoord);
 end else begin
  Grid.Cells[1, 0] := '';
  Grid.Cells[1, 1] := '';
 end;
end;

// высота точки: в третью строку, при одной строке - в нее
procedure TVarSetDlg.CBZChange(Sender: TObject);
var S: AnsiString;
    Row: Integer;
begin
 StopEdit;
 if Grid.RowCount > 2 then Row := 2 else
 if Grid.RowCount = 1 then Row := 0 else exit;
 if CBZ.IsChecked then begin
  S := AnsiString(FloatToStrF(ZDot, ffFixed, 15, DigitsHeight));
  if Pos('.', String(S)) <> 0 then begin
   DelSubStr(S, '.000000'); DelSubStr(S, '.00000'); DelSubStr(S, '.0000');
   DelSubStr(S, '.000'); DelSubStr(S, '.00'); DelSubStr(S, '.0');
  end;
  Grid.Cells[1, Row] := String(S);
 end else
  Grid.Cells[1, Row] := '';
end;

// номер (первая строка) +1 / -1
procedure TVarSetDlg.SpeedButton1Click(Sender: TObject);
begin
 StopEdit;
 if Grid.RowCount = 0 then exit;
 try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) + 1);
 except end;
end;

procedure TVarSetDlg.SpeedButton2Click(Sender: TObject);
begin
 StopEdit;
 if Grid.RowCount = 0 then exit;
 try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) - 1);
 except end;
end;

// цифровая клавиатура номера (первая строка): Tag - цифра, -1 - очистить, -2 - '-'
procedure TVarSetDlg.SpeedButton3Click(Sender: TObject);
begin
 StopEdit;
 if Grid.RowCount = 0 then exit;
 case TComponent(Sender).Tag of
  -1: Grid.Cells[1, 0] := '';
  -2: Grid.Cells[1, 0] := '-';
 else
  Grid.Cells[1, 0] := Grid.Cells[1, 0] + IntToStr(TComponent(Sender).Tag);
 end;
end;

// очистить значения, кроме номера
procedure TVarSetDlg.Button4Click(Sender: TObject);
var I: Integer;
begin
 StopEdit;
 for I := 1 to Grid.RowCount - 1 do Grid.Cells[1, I] := '';
end;

initialization
 GlobalVarSetDlgClass := TVarSetDlg;
end.
