unit DlgRootPropEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation;

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
   function Execute(Row: TPropRow): String;
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

function TRootPropEditorForm.Execute(Row: TPropRow): String;
var Res: TModalResult;
begin
 Res := ShowModal;
 If Res = mrCancel then  Result := '' else
  Result := fResult;
end;

procedure TRootPropEditorForm.Button3Click(Sender: TObject);
begin
 fResult := byLayer;
 ModalResult := mrNone;
 Close;
end;

end.
