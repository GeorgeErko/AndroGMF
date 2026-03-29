unit FramePropEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, TwgDraw;

type
  TPropEditorFrame = class(TFrame)
    ListBox1: TListBox;
  private
  public
   procedure SetEnumProperties(Obj: TTD);
 end;


var  PropEditorForm: TPropEditorFrame;

implementation

{$R *.fmx}

{ TPropEditorFrame }

procedure TPropEditorFrame.SetEnumProperties(Obj: TTD);
begin
//
end;

end.
