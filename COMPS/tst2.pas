unit tst2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation;

type
  Ttst2Frame = class(TFrame)
    Panel1: TPanel;
    Button1: TButton;
    CheckBox1: TCheckBox;
    RadioButton1: TRadioButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
