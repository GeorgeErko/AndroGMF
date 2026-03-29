unit UndoItem;

interface uses Collect, SelectorObj, UpdateMessages, WptForm2;
                                                             
type
// базовый объект обеспечивающий откат операции с восстановлением исходного состояния
 TUndoItem = class (TTwgObject)
  private
    FOnAddPrim: procAddPrim;
    FOnDeletePrim: procDeletePrim;    
    FOnModifiedPrim: procModifiedPrim;
  public
  Twigs:TForm2;
  Mirror:TForm2;
  Prims:PCollection;
  SelectorState:TSelectorObj;
  Operation:Integer;
  Name:String;
  Constructor Create(Form:Pointer; Opr :Integer = 0);
  Destructor Destroy;override;
 {}
  Function Undo(TwgForm:TForm2 = nil):boolean;virtual;
 {события об изменении метрик объектов}
  Property OnModifiedPrim:procModifiedPrim read FOnModifiedPrim write FOnModifiedPrim;
  Property OnAddPrim:procAddPrim read FOnAddPrim write FOnAddPrim;
  Property OnDeletePrim:procDeletePrim read FOnDeletePrim write FOnDeletePrim;
 end;

implementation uses UndoColNew;

{ TUndoItem }

constructor TUndoItem.Create(Form: Pointer; Opr:Integer = 0);
begin
 If (Form<>nil){and not(TForm2(Form).MirrorObject)} then begin
  Twigs:=Form;
  Prims:=PCollection.Create(1);
  SelectorState:=TSelectorObj.Create(Twigs.V25); // запоминаем состояние селектора
  Operation:=Opr;
  Name:='SelectorState';
  Twigs.CreateObjectView(False);
  Mirror:=TForm2(Twigs.ObjView);
  OnModifiedPrim:=TUndo(TForm2(Twigs)).OnModifiedPrim;
  OnDeletePrim:=TUndo(TForm2(Twigs)).OnDeletePrim;
  OnAddPrim:=TUndo(TForm2(Twigs)).OnAddPrim;
 end else Mirror:=nil;
end;

Function TUndoItem.Undo(TWGForm:TForm2 = nil):boolean;
begin
 Result:=True;
 SelectorState.Update; // возвращаем на предыдущий фрагмент
 Twigs.Modified:=True;
end;

destructor TUndoItem.Destroy;
begin
 If Twigs<>nil then begin
  Prims.Free;
  SelectorState.Free;
  If Mirror<>nil then Mirror.Free;
 end;
end;

end.
