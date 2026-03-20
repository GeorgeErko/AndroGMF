unit SelectorObj;

interface uses Types, newSelector, Collect;

type
 TSelector = class (TTwgObject)
  Ms,Dx,Dy,HObject,WObject:Double;
  V25:Pointer;
   Constructor Create(V251:Pointer);
   Procedure Update;
 end;


implementation

{ TSelector }

constructor TSelector.Create;
begin
 V25:=V251;
{$IFDEF MASTER}
 TVer25Form(V25).GetParams(Ms,Dx,Dy,HObject,WObject);
{$ENDIF}
{$IFDEF NEWUNDO}
 TVer25Form(V25).GetParams(Ms,Dx,Dy,HObject,WObject);
{$ENDIF}
end;


procedure TSelector.Update;
begin
{$IFDEF MASTER}
 TVer25Form(V25).ResetParams(Ms,Dx,Dy,HObject,WObject);
// UpdateImage;
{$ENDIF}
{$IFDEF NEWUNDO}
 TVer25Form(V25).ResetParams(Ms,Dx,Dy,HObject,WObject);
// UpdateImage;
{$ENDIF}
end;

end.
