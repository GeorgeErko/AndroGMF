unit DlgDelProperties;

// Удаление группы свойств выделенных объектов (DlgDelProperties.
// TDelPropertiesForm старой программы, кнопка sbMinusMinus редактора свойств):
// список свойств пользователя ('*') выделенных объектов с отметками, «все» -
// отметить/снять все. По OK вызывается OnOk со списком отмеченных свойств,
// затем окно освобождается (ShowDialog: Windows - модальное окно, Android - панель поверх главной формы)

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, SelectedObjects, AppForms;

type
  TDelPropertiesForm = class(TForm)
    cbCheck: TCheckBox;
    List: TListBox;
    LayButtons: TLayout;
    btnCancel: TButton;
    btnOk: TButton;
    procedure cbCheckChange(Sender: TObject);
  public
    class procedure Execute(Objects: TSelectedObjects; OnOk: TProc<TStrings>);
  end;

implementation

uses newProperties, EcLot, EcDot;

{$R *.fmx}

class procedure TDelPropertiesForm.Execute(Objects: TSelectedObjects; OnOk: TProc<TStrings>);
var F: TDelPropertiesForm;
    I, J: Integer;
    Props: TProperties;
    S: String;
begin
 F := TDelPropertiesForm.Create(Application);
 for I := 0 to Objects.Count - 1 do begin
  Props := nil;
  if TObject(Objects[I]) is TLot then Props := TLot(Objects[I]).Properties else
  if TObject(Objects[I]) is TPointDot then Props := TPointDot(Objects[I]).Properties;
  if Props = nil then continue;
  for J := 0 to Props.Count - 1 do begin
   S := String(Props[J].PropName);
   if (Pos('*', S) <> 0) and (F.List.Items.IndexOf(S) = -1) then F.List.Items.Add(S);
  end;
 end;
 ShowDialog(F, // модально: Windows - окно, Android - панель поверх формы
  procedure(ModalResult: TModalResult)
  var Names: TStrings;
      I: Integer;
  begin
   Names := TStringList.Create;
   try
    if ModalResult = mrOk then begin
     for I := 0 to F.List.Count - 1 do
      if F.List.ListItems[I].IsChecked then Names.Add(F.List.Items[I]);
     if Names.Count > 0 then OnOk(Names);
    end;
   finally
    Names.Free;
    F.Release;
   end;
  end);
end;

procedure TDelPropertiesForm.cbCheckChange(Sender: TObject);
var I: Integer;
begin
 for I := 0 to List.Count - 1 do List.ListItems[I].IsChecked := cbCheck.IsChecked;
end;

end.
