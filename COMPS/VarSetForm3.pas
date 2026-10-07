unit VarSetForm3;

// Перенос модуля VarSetForm3 из Geomaster (Delphi 7, VCL): атрибуты цветника
// (знак 28, кнопка sbGC, режим TABLET).
// Точка ставится только на цветник (контур слоя из группы с ID 1900); номер
// участка - газона под точкой (группа 1800), площадь - цветника. Атрибуты -
// секция «Цветники_МГГТ», без истории.

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, FMX.ListBox,
  FMX.Layouts, VarSetForm2, System.Rtti, VarSetForm, EcDot, EcLot, WptForm2,
  System.ImageList, FMX.ImgList;

type
  TVarSetDlg3 = class(TVarSetDlg2)
  private
    FLotFlower: TLot;
    FLotLawn3: TLot;
    function LawnNumber: String;
  protected
    function IncKey: String; override;
    procedure StoreResults; override;
  public
    procedure Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone); override;
  end;

var
  VarSetDlg3: TVarSetDlg3;

implementation

uses newProcs, textmanager, LBN;

{$R *.fmx}

const
  FlowerClientWidth = 585; // окно без истории

{ TVarSetDlg3 }

function TVarSetDlg3.IncKey: String;
begin
 Result := '_IncFlower';
end;

// номер участка - газона под точкой; без газона или номера - '1'
function TVarSetDlg3.LawnNumber: String;
begin
 Result := '1';
 if FLotLawn3 = nil then exit;
 Result := String(FLotLawn3.GetProperty('*№Участка'));
 if Result = byLayer then Result := '1';
end;

// атрибуты - в свойства точки, номер - в первую надпись знака (истории нет)
procedure TVarSetDlg3.StoreResults;
var I: Integer;
begin
 GWriteInteger(AnsiString(Name + IncKey), Ord(CInc.IsChecked));
 if Grid.RowCount > 0 then GWriteString(AnsiString(Name + '_' + Grid.Cells[0, 0]), AnsiString(Grid.Cells[1, 0]));
 FPoint.SetProperty('*Тип (ОГХ)', 'Цветники');
 for I := 0 to Grid.RowCount - 1 do
  if Grid.Cells[0, I] <> '' then begin
   FPoint.SetProperty(AnsiString('*' + Grid.Cells[0, I]), AnsiString(Grid.Cells[1, I]));
   if I = 0 then FPoint.SetProperty('*№Участка', AnsiString(LawnNumber));
  end;
 if (FPoint.TextManager <> nil) and (FPoint.TextManager.FValues.Count > 0) and (Grid.RowCount > 0) then
  TTextParams(FPoint.TextManager.FValues[0]).FValue := AnsiString(Grid.Cells[1, 0]);
end;

procedure TVarSetDlg3.Execute(TwgForm_: TForm2; Point: TPointDot; EditMode: Boolean; Mode: Byte; const Done: TVarSetDone);
var I: Integer;
    Lot: TLot;
    Section: TSectionName;
procedure Fail;
begin
 if Assigned(Done) then Done(False);
 TThread.ForceQueue(nil, procedure begin Free; end);
end;
begin
 TwgForm := TwgForm_;
 FPoint := Point;
 if (TwgForm = nil) or (Point = nil) then begin Fail; exit; end;
// газон (группа 1800) и цветник (группа 1900) под точкой
 FLotLawn3 := nil;
 FLotFlower := nil;
 for I := TwgForm.Twigs.IndexCount - 1 downto 0 do begin
  Lot := TwgForm.Twigs.LAtIndex(I);
  if (Lot.ClassHandle = nil) or (Lot.ClassHandle.Parent = nil) then continue;
  if not Lot.PointIn(TwgForm.Twigs, Point.XDot, Point.YDot) then continue;
  if (FLotLawn3 = nil) and (Round(Lot.ClassHandle.Parent.ID) = 1800) then FLotLawn3 := Lot;
  if (FLotFlower = nil) and (Round(Lot.ClassHandle.Parent.ID) = 1900) then FLotFlower := Lot;
  if (FLotLawn3 <> nil) and (FLotFlower <> nil) then break;
 end;
 if FLotFlower = nil then begin
  FMX.Dialogs.ShowMessage('Установите точку на цветник');
  Fail;
  exit;
 end;
// максимальный номер цветника, окно без истории
 SetLastNumber([28]);
 ClientWidth := FlowerClientWidth;
 History := TStringList.Create;
 CInc.IsChecked := GReadInteger(AnsiString(Name + IncKey), 0) = 1;
// атрибуты секции «Цветники_МГГТ»
 Section := LoadDicts('Цветники_МГГТ');
 if Section = nil then begin Fail; exit; end;
 FillFromSection(Section);
 if CInc.IsChecked and (Grid.RowCount > 0) then
  try Grid.Cells[1, 0] := IntToStr(StrToInt(Grid.Cells[1, 0]) + 1);
  except end;
// номер участка (газон) и площадь цветника
 if Grid.RowCount > 1 then Grid.Cells[1, 1] := LawnNumber;
 if Grid.RowCount > 2 then Grid.Cells[1, 2] := FloatToStrF(FLotFlower.ClearPlo, ffFixed, 15, 2);
 Grid.Row := 0;
 ShowDialog(Done);
end;

end.
