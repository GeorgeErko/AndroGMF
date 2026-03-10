unit newGDICanvas;

interface uses VCL.Controls, VCL.Graphics, WPTForm2, newSelector;

type
 TGDICanvas = class(TControlCanvas)
  TwgForm:TForm2;
  Constructor Create(ParentControl:TControl;TwgForm_:TForm2);
  Function Selector:TSelector;
 end;

implementation

{ TGDICanvas }

constructor TGDICanvas.Create(ParentControl: TControl; TwgForm_: TForm2);
begin
 inherited Create;
 Control:=ParentControl;
 TwgForm:=TwgForm_;
end;

function TGDICanvas.Selector: TSelector;
begin
 Result:=TwgForm.Selector;
end;

end.
