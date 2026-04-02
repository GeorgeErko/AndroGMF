unit FrameParaLine;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation;

type
  TParaLineFrame = class(TFrame)
    Label1: TLabel;
    EWidth: TEdit;
  private
    fOnReturn: TNotifyEvent;
  public
   property OnReturn: TNotifyEvent read fOnReturn write fOnReturn;
   function paraWidth: Double;
  end;

 var paraLineForm: TParaLineFrame;

implementation

{$R *.fmx}

{ TParaLineFrame }

function TParaLineFrame.paraWidth: Double;
begin
 Result := 0.5;
// чтение EWidth
end;

end.
