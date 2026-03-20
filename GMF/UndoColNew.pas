unit UndoColNew;

interface uses Collect, WptForm2, EcLot, UndoItem, SelectorObj, newSelector, UpdateMessages,
               SysUtils, Classes, FMX.Controls;

Const MaxRedoCollCount:Integer = 10;

// операции связанные с созданием/удалением примитивов
type
 TUndoTrans = class(TUndoItem)
  GUID:TGUID;
  Constructor Create(GUID_:TGUID);
  Function Undo(TWGForm:TForm2 = nil):boolean;override;
 end;

Const UndoGUID:TGUID = '{7A4CF24D-A681-4099-9163-145C8DD38C6B}';

type
// коллекция объектов TUndoItem
 TUndo = class (TTwgObject)
  private
    FOnAddPrim: procAddPrim;
    FOnDeletePrim: procDeletePrim;
    FOnModifiedPrim: procModifiedPrim;
    fLocked:Boolean;
   function GetItem(Index: Integer): TUndoItem;
   function TransactionFree:Integer;
   function TransactionUndo:Integer;
    function GetLocked: boolean;
    procedure SetLocked(const Value: boolean);
  public
  Twigs:TForm2;
  UndoColl:PCollection;
  TransGUID:TGUID;
  List:TStrings;
  RedoColl:PCollection;
   Constructor Create(Form:TForm2);
    Function AddUndoItem(const Item:TUndoItem):TUndoItem;
    Procedure Undo;
    Procedure Redo;
    Procedure Clear;
   Destructor Destroy;override;
  //
   Property Item[Index:Integer]:TUndoItem read GetItem;default;
   Function Last:TUndoItem;
   Function LastFree:boolean;
   Procedure UpdateUndoList;
   Procedure Lock;
   Procedure UnLock;
   Procedure StartTransAction;
   Function Commit:Integer;
   Function RollBack:Integer;
   Function TransActionStarted:boolean;
   Function Count:Integer;
 {события об изменении метрик объектов}
   Property OnModifiedPrim:procModifiedPrim read FOnModifiedPrim write FOnModifiedPrim;
   Property OnAddPrim:procAddPrim read FOnAddPrim write FOnAddPrim;
   Property OnDeletePrim:procDeletePrim read FOnDeletePrim write FOnDeletePrim;
   Property Locked:boolean read GetLocked write SetLocked; 
 end;


implementation uses WpTwigs, newProcs, UndoStream, FMX.Forms, userObject;


{ TUndoTrans }

constructor TUndoTrans.Create(GUID_: TGUID);
begin
 Inherited Create(nil);
 Name:=GUIDToString(GUID_);
// Writeln('Name=',Name);
 GUID:=GUID_;
end;

function TUndoTrans.Undo(TWGForm:TForm2 = nil): boolean;
begin
 Result:=True;
end;

{ TUndo }

Function TUndo.AddUndoItem(const Item: TUndoItem):TUndoItem;
begin
 If Locked then begin
  Item.Free;Exit;
 end;
// Writeln('Add Add');
 UndoColl.Insert(Item);
 UpdateUndoList;
 Item.OnModifiedPrim:=OnModifiedPrim;
 Item.OnAddPrim:=OnAddPrim;;
 Item.OnDeletePrim:=OnDeletePrim;;
 Result:=Item;
end;

constructor TUndo.Create(Form: TForm2);
begin
 Twigs:=Form;
 UndoColl:=PCollection.Create(1);
 RedoColl:=PCollection.Create(1);
 Locked:=False;
 TransGUID:=UndoGUID;
end;

destructor TUndo.Destroy;
begin
 UndoColl.Free;
 RedoColl.Free;
end;

function TUndo.GetItem(Index: Integer): TUndoItem;
begin
 Result:=UndoColl[Index];
end;

function TUndo.Last: TUndoItem;
begin
 Result:=nil;
 If UndoColl.Count=0 then Exit;
 Result:=Item[UndoColl.Count-1]
end;

procedure TUndo.StartTransAction;
begin
 If Locked then Exit;
 CreateGUID(TransGUID);
 AddUndoItem(TUndoTrans.Create(TransGUID));
 Last.Name:='StartTansaction '+Last.Name;
end;

function TUndo.Commit: Integer;
begin
 If Locked then Exit;
 try
 if TransActionStarted then begin
  UndoColl.Insert(TUndoTrans.Create(TransGUID));
  Last.Name:='Commit '+Last.Name;
  TransGUID:=UndoGUID;
 end else raise Exception.Create('Undo.Commit.noTransactionStarted...');
 finally
  UpdateUndoList;
 end;
end;

function TUndo.RollBack: Integer;
begin
 If Locked then Exit;
 try
 if TransActionStarted then begin
  If TransActionFree>0 then begin
   If isEqualGUID(TUndoTrans(Last).GUID,TransGUID) then begin
    UndoColl.AtFree(UndoColl.Count-1);
   end else Exception.Create('Undo.RollBack.noTransactionRollBack...');
  end;
 end else raise Exception.Create('Undo.RollBack.noTransactionStarted...');
 finally
  TransGUID:=UndoGUID;
  UpdateUndoList;
 end;
end;

function TUndo.TransactionFree: Integer;
begin
 Result:=0;
 While True do begin                    
  If UndoColl.Count=0 then exit;
  If Last is TUndoTrans then begin exit;end;
  try UndoColl.AtFree(UndoColl.Count-1);Inc(Result);except raise Exception.Create('Undo.TransActionAtFreeException...');end;
 end;
end;

function TUndo.TransActionStarted: boolean;
begin
 If Locked then Exit;
 Result:=not isEqualGUID(TransGUID,UndoGUID);
end;

procedure TUndo.Undo;
var Count:Integer;US:TUndoStream;
begin
 If UndoColl.Count=0 then Exit;
 Twigs.Selector.execEscape;
 GlobalPropertyUnlocked:=True;
 try
 If Last is TUndoTrans then begin
  // запоминаем объект до Undo в Redo
//  US:=TUndoStream.Create(Twigs,0,'RedoByUndoCol...Undo');
//  US.StoreForm(Twigs,'');
  // выполняем Undo - транзакцию
  Count:=TransactionUndo;
{  If Count>0 then begin  // запоминаем объект до Undo в Redo
   If RedoColl.Count=MaxRedoCollCount then RedoColl.AtFree(0);
   RedoColl.Insert(US);
  end else US.Free;}
  UpdateUndoList;
 end else begin
  // запоминаем объект до Undo в Redo
//  US:=TUndoStream.Create(Twigs,0,'RedoByUndoCol...Undo');
//  US.StoreForm(Twigs,'');
  // стандартный Undo на одну операцию
  If Item[UndoColl.Count-1].Undo(Twigs) then begin
   Twigs.Modified:=True;
   UndoColl.AtFree(UndoColl.Count-1);
  // If RedoColl.Count=MaxRedoCollCount then RedoColl.AtFree(0);
 //  RedoColl.Insert(US);
   UpdateUndoList;
  end;// else US.Free;
 end;
 finally
  GlobalPropertyUnlocked:=False;
 end;
end;

procedure TUndo.UnLock;
begin
 Locked:=False;
end;

procedure TUndo.Lock;
begin
 Locked:=True;
end;

procedure TUndo.UpdateUndoList;
var I:Integer;
begin
// writeln('Update=',List=nil);
 If ParamStr(1)='CON' then
 If Assigned(List) then begin
  List.Clear;
  For I:=0 to UndoColl.Count-1 do begin
   List.Add(Item[I].Name);
//   Writeln(Item[I].Name);
  end;
 end;
// writeln('UpdateEnd');
end;

function TUndo.Count: Integer;
begin
 Result:=UndoColl.Count;
end;

function TUndo.TransactionUndo: Integer;
begin
 Result:=0;
 LastFree;
 try
  While True do begin
   If UndoColl.Count=0 then exit;
   If Last is TUndoTrans then begin LastFree;exit;end;
   try
    Last.Undo(Twigs);
    LastFree;
    Inc(Result);
    Twigs.Modified:=True;
   except on E:Exception do begin
    raise Exception.Create('Undo.TransActionUndoFree...'+E.Message);end;
   end;
  end;
 finally
  TransGUID:=UndoGUID;
  UpdateUndoList;
 end;
end;

function TUndo.LastFree:boolean;
begin
 Result:=False;
 If UndoColl.Count>0 then begin
  UndoColl.AtFree(UndoColl.Count-1);
  Result:=True;
 end;
end;

procedure TUndo.Clear;
begin
 UndoColl.FreeAll;
 RedoColl.FreeAll;
 UpdateUndoList;
end;

procedure TUndo.Redo;
var US:TUndoStream;
begin
 exit;
 If RedoColl.Count>0 then begin
  Twigs.Selector.execEscape;
 try
 // вставляем объект в Undo
  US:=TUndoStream.Create(Twigs,0,'UndoByUndoCol...Redo');
  US.StoreForm(Twigs,'');
 // стандартный Undo на одну операцию
  UndoColl.Insert(US);
  UpdateUndoList;
 //
  TUndoStream(RedoColl[RedoColl.Count-1]).Undo(Twigs);
  RedoColl.AtFree(RedoColl.Count-1);
 finally
 //
 end;
 end;
end;

function TUndo.GetLocked: boolean;
begin
// fLocked:=True;
 Result:=fLocked;
end;

procedure TUndo.SetLocked(const Value: boolean);
begin
 fLocked:=Value;
end;

initialization
finalization
end.

