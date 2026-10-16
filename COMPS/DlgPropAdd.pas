unit DlgPropAdd;

// Свойства из справочника (DlgPropAdd.TPropAddForm старой программы, кнопка
// sbAddProp редактора свойств). Справочники - ini-файлы в каталоге программы
// (Properties.ini, Dictionary.txt, Dictionary_odh.txt): секция - группа
// свойств, строки «имя=значение». Группу можно изменить в тексте и запомнить
// («Запомнить»), удалить, записать справочник в файл («Записать», в
// кодировке файла). По OK строки текста - в PropNames/PropValues (имя с '*',
// кроме начинающихся с '$'), затем OnOk и окно освобождается (ShowModal с
// процедурой, как требует Android). Вкладки справочников заменены списком

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.ComboEdit,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.ImageList, FMX.ImgList, AppForms;

type
  TPropAddForm = class(TForm)
    LayFile: TLayout;
    lblFile: TLabel;
    cbFile: TComboBox;
    LayGroup: TLayout;
    lblGroup: TLabel;
    cbGroup: TComboEdit;
    sbGroupSave: TSpeedButton;
    sbGroupDel: TSpeedButton;
    sbFileSave: TSpeedButton;
    lblMemo: TLabel;
    Memo: TMemo;
    lblNote: TLabel;
    LayButtons: TLayout;
    btnCancel: TButton;
    btnOk: TButton;
    ImageList1: TImageList;
    cbClear: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbFileChange(Sender: TObject);
    procedure cbGroupChange(Sender: TObject);
    procedure sbGroupSaveClick(Sender: TObject);
    procedure sbGroupDelClick(Sender: TObject);
    procedure sbFileSaveClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  private
    FFiles: TStringList;
    FSections: TStringList; // группы; Objects - строки группы (TStringList)
    FUtf8: Boolean; // справочник в UTF-8 (иначе cp1251)
    FLoading: Boolean;
    procedure LoadSections;
  public
    PropNames, PropValues: TStringList;
    class procedure Execute(const Files: array of String; OnOk: TProc<TPropAddForm>);
  end;

implementation

uses System.IOUtils, FMX.DialogService, newProcs, LBN;

{$R *.fmx}

class procedure TPropAddForm.Execute(const Files: array of String; OnOk: TProc<TPropAddForm>);
var F: TPropAddForm;
    I: Integer;
begin
 F := TPropAddForm.Create(Application);
 for I := 0 to High(Files) do begin
  F.FFiles.Add(Files[I]);
  F.cbFile.Items.Add(ExtractFileName(Files[I]));
 end;
 I := GReadInteger(AnsiString(F.Name + '_TabIndex'), 0);
 if (I < 0) or (I >= F.FFiles.Count) then I := 0;
 F.cbFile.ItemIndex := I;
 F.LoadSections;
 F.ShowModal(
  procedure(ModalResult: TModalResult)
  begin
   try
    if ModalResult = mrOk then begin
     GWriteInteger(AnsiString(F.Name + '_TabIndex'), F.cbFile.ItemIndex);
     OnOk(F);
    end;
   finally
    F.Release;
   end;
  end);
end;

procedure TPropAddForm.FormCreate(Sender: TObject);
begin
 FFiles := TStringList.Create;
 FSections := TStringList.Create(True);
 PropNames := TStringList.Create;
 PropValues := TStringList.Create;
end;

procedure TPropAddForm.FormDestroy(Sender: TObject);
begin
 FSections.Free;
 FFiles.Free;
 PropNames.Free;
 PropValues.Free;
end;

// группы справочника: секции '[имя]', строки - непустые, кроме комментариев
procedure TPropAddForm.LoadSections;
var L: TStringList;
    I: Integer;
    S: String;
    Cur: TStringList;
begin
 FLoading := True;
 try
  FSections.Clear;
  cbGroup.Items.Clear;
  cbGroup.Text := '';
  Memo.Lines.Clear;
  if (cbFile.ItemIndex < 0) or not TFile.Exists(FFiles[cbFile.ItemIndex]) then exit;
  L := TStringList.Create;
  try
   FUtf8 := LoadDictLines(FFiles[cbFile.ItemIndex], L);
   Cur := nil;
   for I := 0 to L.Count - 1 do begin
    S := Trim(L[I]);
    if (S = '') or (S[1] = ';') then continue;
    if (S[1] = '[') and (S[Length(S)] = ']') then begin
     Cur := TStringList.Create;
     FSections.AddObject(Copy(S, 2, Length(S) - 2), Cur);
     continue;
    end;
    if Cur <> nil then Cur.Add(S);
   end;
  finally
   L.Free;
  end;
  cbGroup.Items.Assign(FSections);
 finally
  FLoading := False;
 end;
end;

procedure TPropAddForm.cbFileChange(Sender: TObject);
begin
 if FLoading then exit;
 LoadSections;
end;

procedure TPropAddForm.cbGroupChange(Sender: TObject);
var I: Integer;
begin
 if FLoading then exit;
 I := FSections.IndexOf(cbGroup.Text);
 if I <> -1 then Memo.Lines.Assign(TStringList(FSections.Objects[I])) else Memo.Lines.Clear;
end;

// группа из текста: новая - добавляется, существующая - с подтверждением
procedure TPropAddForm.sbGroupSaveClick(Sender: TObject);
var I: Integer;
    S: String;
begin
 S := Trim(cbGroup.Text);
 if S = '' then exit;
 I := FSections.IndexOf(S);
 if I = -1 then begin
  FSections.AddObject(S, TStringList.Create);
  TStringList(FSections.Objects[FSections.Count - 1]).Assign(Memo.Lines);
  FLoading := True;
  try
   cbGroup.Items.Add(S);
  finally
   FLoading := False;
  end;
  exit;
 end;
 TDialogService.MessageDialog('Группа с таким именем уже существует. Сохранить изменения?', TMsgDlgType.mtConfirmation,
  [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
  procedure(const AResult: TModalResult)
  begin
   if AResult = mrYes then TStringList(FSections.Objects[I]).Assign(Memo.Lines);
  end);
end;

procedure TPropAddForm.sbGroupDelClick(Sender: TObject);
var I: Integer;
begin
 I := FSections.IndexOf(cbGroup.Text);
 if I = -1 then exit;
 FLoading := True;
 try
  FSections.Delete(I);
  cbGroup.Items.Delete(I);
  cbGroup.Text := '';
  Memo.Lines.Clear;
 finally
  FLoading := False;
 end;
end;

// справочник в файл (текущая группа - из текста), в кодировке файла
procedure TPropAddForm.sbFileSaveClick(Sender: TObject);
var I, J: Integer;
    L: TStringList;
    Enc: TEncoding;
begin
 if cbFile.ItemIndex < 0 then exit;
 I := FSections.IndexOf(cbGroup.Text);
 if I <> -1 then TStringList(FSections.Objects[I]).Assign(Memo.Lines);
 L := TStringList.Create;
 if FUtf8 then Enc := TEncoding.UTF8 else Enc := TEncoding.GetEncoding(1251);
 try
  for I := 0 to FSections.Count - 1 do begin
   L.Add('[' + FSections[I] + ']');
   for J := 0 to TStringList(FSections.Objects[I]).Count - 1 do L.Add(TStringList(FSections.Objects[I])[J]);
   L.Add('');
  end;
  L.SaveToFile(FFiles[cbFile.ItemIndex], Enc);
 finally
  if not TEncoding.IsStandardEncoding(Enc) then Enc.Free;
  L.Free;
 end;
end;

// строки «имя=значение»: имя - свойство пользователя ('*'), кроме '$...'
procedure TPropAddForm.btnOkClick(Sender: TObject);
var I, P: Integer;
    S, N: String;
begin
 PropNames.Clear;
 PropValues.Clear;
 for I := 0 to Memo.Lines.Count - 1 do begin
  S := Memo.Lines[I];
  P := Pos('=', S);
  if P = 0 then continue;
  N := Trim(Copy(S, 1, P - 1));
  if N = '' then continue;
  if N[1] <> '$' then N := '*' + N;
  PropNames.Add(N);
  PropValues.Add(Trim(Copy(S, P + 1, MaxInt)));
 end;
 ModalResult := mrOk;
end;

end.
