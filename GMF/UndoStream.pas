unit UndoStream;

interface uses Collect, WpTForm2, FMX.Controls, SysUtils, UndoItem;

Type                                             
 TUndoStream = class (TUndoItem)
  Stream:TBufStream; // хранение MemoryStyream с TForm2
  Constructor Create(Form:Pointer;Opr:Integer;OprStr_:String);
   Procedure StoreForm(F:TForm2;Nm:String);
   Function LoadForm:TForm2;
  Function Undo(TWGForm:TForm2 = nil):boolean;override;
  Destructor Destroy;override;
 end;

var StreamUndo:TUndoStream;

implementation

{ TUndoStream }

constructor TUndoStream.Create;
begin
 inherited Create(Form,Opr);
 Name:='StreamUndo_TwgForm = '+TForm2(Form).About.MyName;
end;

procedure TUndoStream.StoreForm(F: TForm2; Nm: String);
var M:TBufStream;
begin
  M:=TBufStream.Create;
  M.Put(F);
  M.FlushBuffer;
  Stream:=M;
  M.Position:=0;
//  If Nm<>'*' then F.About.Modified:=1;
//  If List.Items.Count>10 then DeleteForm(1);
end;

function TUndoStream.Undo(TWGForm:TForm2 = nil): boolean;
var F:TForm2;
begin
 Result:=False;
 F:=TForm2(Stream.Get);
 TBufStream(Stream).Position:=0;
 F.ClassBuildII;
 F.SetGabarites;
 F.Modified:=True;
 TwgForm.ClearObject;TwgForm.AddObject(F);TwgForm.Modified:=True;
 Result:=True;
end;

function TUndoStream.LoadForm: TForm2;
var F:TForm2;
begin
 Result:=nil;
 F:=TForm2(Stream.Get);
 TBufStream(Stream).Position:=0;
 F.ClassBuildII;
 F.SetGabarites;
 F.Modified:=True;
 Result:=F;
end;

destructor TUndoStream.Destroy;
begin
 Stream.Free;
end;

{procedure TUndoStream.ResetForm(F:TForm2);
var M:TBufStream;FF:TForm2;
begin
 if List.ItemIndex=List.Items.Count-1 then begin
  M:=TBufStream.Create;
  M.Put(F);
  M.FlushBuffer;
  M.Position:=0;
  TBufStream(Streams[List.ItemIndex]).Free;
  Streams.AtPut(List.ItemIndex,M);
 end;
end;
}


end.
