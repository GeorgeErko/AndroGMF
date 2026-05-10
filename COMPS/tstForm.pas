unit tstForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  DropDownButton, tst2, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ExtCtrls, FMX.ListBox;

type
  Ttsts2DF = class(TForm)
    PopupBox1: TPopupBox;
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
    FDrop: TDropDownButton;
    FTst2Frame: Ttst2Frame;
  public
    { Public declarations }
  end;

var
  tsts2DF: Ttsts2DF;

implementation

{$R *.fmx}

type
 TPopupBoxAccess = class(TPopupBox)

 end;

procedure OpenPopupBox(PB: TPopupBox);
var X, Y: Single;
begin
 if PB = nil then Exit;
 PB.SetFocus;
 X := PB.Width - 2;
 Y := PB.Height / 2;
// PB.Click;
end;

procedure Ttsts2DF.FormCreate(Sender: TObject);
begin
 PopupBox1.Items.Add('Item1');
 PopupBox1.Items.Add('Item2');
 PopupBox1.Items.Add('Item3');
 PopupBox1.Items.Add('Item4');
 PopupBox1.ItemIndex := 0;

 FTst2Frame := Ttst2Frame.Create(Self);
 FTst2Frame.Stored := False;

 FDrop := TDropDownButton.Create(Self);
 FDrop.Parent := Self;
 FDrop.Stored := False;
 FDrop.Position.X := 14;
 FDrop.Position.Y := 12;
 FDrop.Width := 160;
 FDrop.Height := 29;
 FDrop.Text := 'Drop';
 FDrop.Content := FTst2Frame;
 FDrop.Popup.Width := FTst2Frame.Width;
 FDrop.Popup.Height := FTst2Frame.Height;
end;

procedure Ttsts2DF.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
 OpenPopupBox(PopupBox1);
end;

end.
