unit DlgPropSelect;

// Условие выделения объектов по свойству (DlgPropSelect.TPropSelectForm старой
// программы, кнопка sbAnd редактора свойств): строка «знак + значение» -
// '=', '<>', '>=', '<=', '>', '<', '%' (содержит) или 'a...b' (диапазон),
// сравнение строк или чисел, область - выделить заново, среди выделенных или
// добавить к выделенным. Окно немодальное для вызывающего (ShowModal с
// процедурой, как требует Android): по OK вызывается OnOk, затем окно
// освобождается

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.ComboEdit, FMX.Layouts, AppForms;

type
  TPropSelectForm = class(TForm)
    LayExpr: TLayout;
    lblExpr: TLabel;
    cbSelect: TComboEdit;
    LayType: TLayout;
    rbStr: TRadioButton;
    rbNum: TRadioButton;
    cbInObjects: TCheckBox;
    cbAddObjects: TCheckBox;
    LayButtons: TLayout;
    btnCancel: TButton;
    btnOk: TButton;
    procedure cbInObjectsChange(Sender: TObject);
    procedure cbAddObjectsChange(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  private
    procedure ParseExpr;
  public
   // результат: условие (0 '=', 1 '<>', 2 '>=', 3 '<=', 4 '>', 5 '<', 6 '%',
   // 7 'a...b'), значение без знака, сравнение чисел, область выделения
    ZnakIndex: Integer;
    Pattern: String;
    IsNumber: Boolean;
    InObjects: Boolean;
    AddObjects: Boolean;
    class procedure Execute(const PropName, PropValue: String; OnOk: TProc<TPropSelectForm>);
  end;

const
  znArray: array[0..7] of String = ('=', '<>', '>=', '<=', '>', '<', '%', '...');

implementation

uses newProcs;

{$R *.fmx}

class procedure TPropSelectForm.Execute(const PropName, PropValue: String; OnOk: TProc<TPropSelectForm>);
var F: TPropSelectForm;
    I: Integer;
    D: Double;
begin
 F := TPropSelectForm.Create(Application);
 F.Caption := 'Свойство: "' + PropName + '"';
 for I := 0 to High(znArray) do F.cbSelect.Items.Add(znArray[I]);
 F.cbSelect.Text := '=' + PropValue;
 if TryStrToFloat(StringReplace(Trim(PropValue), ',', '.', []), D, TFormatSettings.Invariant) then F.rbNum.IsChecked := True else
  F.rbStr.IsChecked := True;
 F.ShowModal(
  procedure(ModalResult: TModalResult)
  begin
   try
    if ModalResult = mrOk then OnOk(F);
   finally
    F.Release;
   end;
  end);
end;

// диапазон - 'a...b' (можно с '=' в начале); знак - в начале строки
// (двухсимвольные проверяются раньше), значение после знака - как есть; без
// знака - равенство
procedure TPropSelectForm.ParseExpr;
const Order: array[0..6] of Integer = (1, 2, 3, 0, 4, 5, 6);
var I: Integer;
    S: String;
begin
 S := TrimLeft(cbSelect.Text);
 if Pos('...', S) <> 0 then begin
  ZnakIndex := 7;
  if Pos('=', S) = 1 then Delete(S, 1, 1);
  Pattern := Trim(S);
  exit;
 end;
 ZnakIndex := 0;
 Pattern := S;
 for I := 0 to High(Order) do
  if Pos(znArray[Order[I]], S) = 1 then begin
   ZnakIndex := Order[I];
   Pattern := Copy(S, Length(znArray[Order[I]]) + 1, MaxInt);
   exit;
  end;
end;

procedure TPropSelectForm.btnOkClick(Sender: TObject);
begin
 if Trim(cbSelect.Text) = '' then begin
  MessageError('Введите условие поиска');
  exit;
 end;
 ParseExpr;
 IsNumber := rbNum.IsChecked;
 InObjects := cbInObjects.IsChecked;
 AddObjects := cbAddObjects.IsChecked;
 ModalResult := mrOk;
end;

procedure TPropSelectForm.cbInObjectsChange(Sender: TObject);
begin
 if cbInObjects.IsChecked then cbAddObjects.IsChecked := False;
end;

procedure TPropSelectForm.cbAddObjectsChange(Sender: TObject);
begin
 if cbAddObjects.IsChecked then cbInObjects.IsChecked := False;
end;

end.
