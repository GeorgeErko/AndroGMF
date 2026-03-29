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
   Property OnReturn: TNotifyEvent read fOnReturn write fOnReturn;
  end;

 var paraLineForm: TParaLineFrame;

implementation

{$R *.fmx}

end.
