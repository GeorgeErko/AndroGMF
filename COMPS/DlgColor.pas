unit DlgColor;

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
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
  private
   fResult: String;
  public
  // значение - в Done ('' - отмена); показ модальный (ShowDialog)
   procedure Execute(Row: TPropRow; const Done: TProc<String>);
  end;

var
  Form1: TForm1;

implementation

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

procedure TForm1.Execute(Row: TPropRow; const Done: TProc<String>);
var Form: TForm1;
begin
 Form := Self;
 ShowDialog(Self,
  procedure(Res: TModalResult)
  var S: String;
  begin
   if Res = mrCancel then S := '' else S := Form.fResult;
   Form.Release;
   if Assigned(Done) then Done(S);
  end);
end;

end.
