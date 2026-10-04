unit VarSetForm2;

// Перенос модуля VarSetForm2 из Geomaster (Delphi 7, VCL): номер участка газона
// (знак 201, кнопки sbNumUCH / sbNumUchDropDown, Tag = 14).
// Точка ставится только на газон (контур слоя из группы с ID 1800); если газону
// уже присвоен №Участка - подтверждение.
// Mode > 1 (пункт меню «тип + состояние» в режиме TABLET): атрибуты без диалога -
// номер = Mode, десятки - тип газона, единицы - состояние, площадь газона.
// Иначе - диалог атрибутов секции «Газоны_МГГТ»: площадь газона, история
// (файл <карта>_lawn.csv: номер, состояние, тип).

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, FMX.ListBox,
  FMX.Layouts, VarSetForm1, System.Rtti, VarSetForm, EcDot, EcLot, WptForm2;

type
  TVarSetDlg2 = class(TVarSetDlg1)
  private
    FLotLawn: TLot;
    procedure ExecuteLawn(EditMode: Boolean; Mode: Byte; const Done: TVarSetDone);
  protected
    function HistorySuffix: String; override;
    procedure HistoryLineToGrid(St: TStrings; Row: Integer); override;
    procedure HistoryToGrid(Row: Integer); override;
    function HistoryWidth: Single; override;
    function IncKey: String; override;
    procedure StoreResults; override;
  public
    procedure Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone); override;
  end;

var
  VarSetDlg2: TVarSetDlg2;

implementation

uses FMX.DialogService, newProcs, textmanager, LBN;

{$R *.fmx}

{ TVarSetDlg2 }

function TVarSetDlg2.HistorySuffix: String;
begin
 Result := '_lawn.csv';
end;

function TVarSetDlg2.HistoryWidth: Single;
begin
 Result := 934;
end;

function TVarSetDlg2.IncKey: String;
begin
 Result := '_IncLawn';
end;

// строка истории: номер, состояние, тип
procedure TVarSetDlg2.HistoryLineToGrid(St: TStrings; Row: Integer);
begin
 if St.Count > 0 then hGrid.Cells[0, Row] := St[0];
 if St.Count > 1 then hGrid.Cells[1, Row] := St[1];
 if St.Count > 2 then hGrid.Cells[2, Row] := St[2];
end;

// строка истории - номер, состояние, тип
procedure TVarSetDlg2.HistoryToGrid(Row: Integer);
var I: Integer;
begin
 if (Row < 0) or (Row >= hGrid.RowCount) then exit;
 StopEdit;
 for I := 0 to 2 do
  if I < Grid.RowCount then Grid.Cells[1, I] := hGrid.Cells[I, Row];
end;

// атрибуты - в свойства точки, номер - в первую надпись знака, строка - в историю
procedure TVarSetDlg2.StoreResults;
var I: Integer;
    S: String;
begin
 GWriteInteger(AnsiString(Name + '_Width'), Round(ClientWidth));
 GWriteInteger(AnsiString(Name + IncKey), Ord(CInc.IsChecked));
 if Grid.RowCount > 0 then GWriteString(AnsiString(Name + '_' + Grid.Cells[0, 0]), AnsiString(Grid.Cells[1, 0]));
 FPoint.SetProperty('*Тип (ОГХ)', 'Газоны_МГГТ');
 S := '';
 for I := 0 to Grid.RowCount - 1 do
  if Grid.Cells[0, I] <> '' then begin
   FPoint.SetProperty(AnsiString('*' + Grid.Cells[0, I]), AnsiString(Grid.Cells[1, I]));
   if I = 0 then S := Grid.Cells[1, I] else S := S + ';' + Grid.Cells[1, I];
  end;
 if not cbNotHistory.IsChecked then begin
  History.Insert(0, S);
  if FHistFile <> '' then
   try History.SaveToFile(FHistFile); except end;
 end;
 if (FPoint.TextManager <> nil) and (FPoint.TextManager.FValues.Count > 0) and (Grid.RowCount > 0) then
  TTextParams(FPoint.TextManager.FValues[0]).FValue := AnsiString(Grid.Cells[1, 0]);
end;

procedure TVarSetDlg2.Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone);
var I: Integer;
    Lot: TLot;
    Num: String;
begin
 TwgForm := TwgForm_;
 FPoint := Point;
 FLotLawn := nil;
 if (TwgForm <> nil) and (Point <> nil) then
  for I := TwgForm.Twigs.IndexCount - 1 downto 0 do begin
   Lot := TwgForm.Twigs.LAtIndex(I);
   if (Lot.ClassHandle <> nil) and (Lot.ClassHandle.Parent <> nil) and (Round(Lot.ClassHandle.Parent.ID) = 1800) and
      Lot.PointIn(TwgForm.Twigs, Point.XDot, Point.YDot) then begin
    FLotLawn := Lot;
    break;
   end;
  end;
 if FLotLawn = nil then begin
  FMX.Dialogs.ShowMessage('Установите точку на газон');
  if Assigned(Done) then Done(False);
  TThread.ForceQueue(nil, procedure begin Free; end);
  exit;
 end;
 Num := String(FLotLawn.GetProperty('*№Участка'));
 if Num <> byLayer then
  TDialogService.MessageDialog('Газону уже присвоен №Участка = ' + Num + '. Продолжить?', TMsgDlgType.mtConfirmation,
   [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
   procedure(const AResult: TModalResult)
   begin
    if AResult = mrYes then ExecuteLawn(EditMode, Mode, Done) else begin
     if Assigned(Done) then Done(False);
     TThread.ForceQueue(nil, procedure begin Free; end);
    end;
   end)
 else
  ExecuteLawn(EditMode, Mode, Done);
end;

procedure TVarSetDlg2.ExecuteLawn(EditMode: Boolean; Mode: Byte; const Done: TVarSetDone);
var Section: TSectionName;
    Area: String;
begin
 Area := FloatToStrF(FLotLawn.ClearPlo, ffFixed, 15, 2);
// Mode > 1: номер, тип и состояние газона - по коду, без диалога
 if Mode > 1 then begin
  if (FPoint.TextManager <> nil) and (FPoint.TextManager.FValues.Count > 0) then
   TTextParams(FPoint.TextManager.FValues[0]).FValue := AnsiString(IntToStr(Mode));
  FPoint.SetProperty('*№Участка', AnsiString(IntToStr(Mode)));
  case Mode mod 10 of
   1: FPoint.SetProperty('*Состояние газона', 'Хорошее');
   2: FPoint.SetProperty('*Состояние газона', 'Удовлетворительное');
   3: FPoint.SetProperty('*Состояние газона', 'Неудовлетворительное');
  end;
  case Mode div 10 of
   1: FPoint.SetProperty('*Тип газона', 'Обыкновенный');
   2: FPoint.SetProperty('*Тип газона', 'Луговой');
   3: FPoint.SetProperty('*Тип газона', 'Партерный');
   4: FPoint.SetProperty('*Тип газона', 'На откосе');
   5: FPoint.SetProperty('*Тип газона', 'Иного типа');
  end;
  FPoint.SetProperty('*Площадь, кв.м.', AnsiString(Area));
  if Assigned(Done) then Done(True);
  TThread.ForceQueue(nil, procedure begin Free; end);
  exit;
 end;
// диалог: максимальный номер газона, история, атрибуты секции «Газоны_МГГТ»
 SetLastNumber([201]);
 SetHistoryVisible(GReadInteger(AnsiString(Name + '_Width'), 581) >= HistoryWidth);
 LoadHistory;
 CInc.IsChecked := GReadInteger(AnsiString(Name + IncKey), 0) = 1;
 Section := LoadDicts('Газоны_МГГТ');
 if Section = nil then begin
  if Assigned(Done) then Done(False);
  TThread.ForceQueue(nil, procedure begin Free; end);
  exit;
 end;
 FillFromSection(Section);
 if not EditMode then HistoryToGrid(0);
// площадь газона
 if Grid.RowCount > 3 then Grid.Cells[1, 3] := Area;
 if CInc.IsChecked and (Grid.RowCount > 0) then
  try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) + 1);
  except end;
 Grid.Row := 0;
 ShowDialog(Done);
end;

end.
