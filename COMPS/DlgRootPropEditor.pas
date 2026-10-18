unit DlgRootPropEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, AppForms;

type
  TPropRow = class
  public
   RawName: string;
   DisplayName: string;
   Value: string;
   TypeName: string;
   IsSystem: Boolean;
   IsSystemDisabled: Boolean;
   IsUserProp: Boolean;
   PickList: TStringList;
   constructor Create;
   destructor Destroy; override;
  end;

type
  TRootPropEditorForm = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button3Click(Sender: TObject);
  protected
   fResult: String;
  public
   procedure LoadPosition;
   procedure SavePosition;
  // значение - в Done ('' - отмена, byLayer - «по слою»); показ модальный
  // (ShowDialog: Windows - окно, Android - панель поверх главной формы),
  // форма освобождается после Done
   procedure Execute(Row: TPropRow; const Done: TProc<String>);
  end;

var
  RootPropEditorForm: TRootPropEditorForm;

implementation uses newProcs;

{$R *.fmx}

{ TPropRow }

constructor TPropRow.Create;
begin
 inherited Create;
 PickList := TStringList.Create;
end;

destructor TPropRow.Destroy;
begin
 if PickList <> nil then PickList.Free;
 inherited Destroy;
end;


{ TForm1 }
procedure TRootPropEditorForm.LoadPosition;
begin
 Left := GReadInteger(Name + '_Left', Left);
 Top := GReadInteger(Name + '_Top', Top);
 Width := GReadInteger(Name + '_Width', Width);
 Height := GReadInteger(Name + '_Height', Height);
end;

procedure TRootPropEditorForm.SavePosition;
begin
 GWriteInteger(Name + '_Left', Left);
 GWriteInteger(Name + '_Top', Top);
 GWriteInteger(Name + '_Width', Width);
 GWriteInteger(Name + '_Height', Height);
end;

procedure TRootPropEditorForm.Execute(Row: TPropRow; const Done: TProc<String>);
var Form: TRootPropEditorForm;
begin
 Form := Self;
 ShowDialog(Self,
  procedure(Res: TModalResult)
  var S: String;
  begin
   if Form.fResult = byLayer then S := byLayer else
   if Res = mrCancel then S := '' else
    S := Form.fResult;
   Form.Release;
   if Assigned(Done) then Done(S);
  end);
end;

procedure TRootPropEditorForm.Button3Click(Sender: TObject);
begin
 fResult := byLayer;
 ModalResult := mrNone;
 Close;
end;

end.
