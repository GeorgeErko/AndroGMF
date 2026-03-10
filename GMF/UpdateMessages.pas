unit UpdateMessages;

interface uses Collect, newResource;

const point_Object = 0;
      lot_Object = 1;
      bitmap_Object = 2;
      layers_Object = 11;
      lib_Object = 12;

type
  procModifiedPrim = function (Prim:TObject;UpdateSymbology:Boolean=False):boolean of object;
  procAddPrim = function (Prim:TObject):boolean of object;
  procSetLayer = procedure (Layer: TResource; Symbol: Integer) of object;
  procDeletePrim = function (Prim:TObject):boolean of object;
  procActivatePrim = procedure (Prim:TObject) of object;
  procOpenFile = procedure (FileName:AnsiString; Sender:Pointer = nil) of object;
  procSetOperation = procedure (ID, Opr:AnsiString) of object;

type
 TUpdateMessage = class (TTwgObject)
  private
    fOnAddPrim: procAddPrim;
    fOnModifiedPrim: procAddPrim;
    fOnDeletePrim: procAddPrim;
  public
   Constructor Create(UpdateObject:TObject);virtual;
  // реализация события об изменении объекта
   function ModifiedPrim(Prim:TObject;UpdateSymbology:Boolean=False):boolean;virtual;
   function AddPrim(Prim:TObject):boolean;virtual;
   function DeletePrim(Prim:TObject):boolean;virtual;
   procedure ActivatePrim(Prim:TObject);virtual;
   procedure SetActiveLayer(Layer:TResource;Symbol:Integer);virtual;
   function DeleteTaheoProject(TaheoIndex: Integer):boolean;virtual;
   procedure SetOperation(ID,Opr:AnsiString);
   property onAddPrim:procAddPrim read fOnAddPrim write fOnAddPrim;
   property onModifiedPrim:procAddPrim read fOnModifiedPrim write fOnModifiedPrim;
   property onDeletePrim:procAddPrim read fOnDeletePrim write fOnDeletePrim;
 end;

 Function SearchLot(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;
 Function SearchPoint(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;
 Function SearchBitmap(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;

var UpdateMessage:TUpdateMessage = nil;
//    MyHelp:TRichEdit = nil;

implementation uses WpTForm2, EcDot, RPrims, EcLot, newProcs, SysUtils, newSelector;

{ TUpdateMessage }

constructor TUpdateMessage.Create(UpdateObject: TObject);
begin
// abstract
end;

procedure TUpdateMessage.ActivatePrim(Prim: TObject);
begin
// abstract
end;

function TUpdateMessage.AddPrim(Prim: TObject): boolean;
begin
 Result:=True;
 If Assigned(OnAddPrim) then Result:=OnAddPrim(Prim);
 If not Result then exit;
// If GTwgForm<>nil then TForm2(GTwgForm).Modified:=True;
end;

function TUpdateMessage.DeletePrim(Prim: TObject): boolean;
begin
 Result:=True;
 If Assigned(OnDeletePrim) then Result:=OnDeletePrim(Prim);
 If not Result then exit;
// If GTwgForm<>nil then TForm2(GTwgForm).Modified:=True;
end;

function TUpdateMessage.DeleteTaheoProject(TaheoIndex: Integer): boolean;
begin
 Result:=True;
end;

function TUpdateMessage.ModifiedPrim(Prim: TObject;
  UpdateSymbology: Boolean): boolean;
begin
 Result:=True;
 If Assigned(OnModifiedPrim) then Result:=OnModifiedPrim(Prim);
 If not Result then exit;
// If GTwgForm<>nil then TForm2(GTwgForm).Modified:=True;
end;

procedure TUpdateMessage.SetActiveLayer(Layer: TResource; Symbol: Integer);
begin
// abstract
// ShowMessage('SetLayer');
// FlySloy.SetActiveLayer(Layer,Symbol);
// If Symbol<>-1 then If FlyLayer<>nil then FlyLayer.SetActiveLayer(Layer,Symbol);
end;

Function SearchLot(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;
var I:Integer;Lot:TLot;
begin
 Result:=False;
 With TForm2(TwgForm) do
  For I:=0 to Twigs.LotsCount-1 do begin
   Lot:=Twigs.LAt(I);
   If Lot.GUIDStr=GUID_ then begin
    Result:=True;
    Index_:=I;
    exit;
   end;
  end;
end;

Function SearchPoint(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;
var I:Integer;B:Byte;PD:TPointDot;
begin
 Result:=False;
 With TForm2(TwgForm) do
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then If PD.GUIDStr=GUID_ then begin
    Result:=True;
    Index_:=I;
    exit;
   end;
  end;
end;

Function SearchBitmap(GUID_:AnsiString;TwgForm:TObject;var Index_:Integer):boolean;
var I:Integer;Bm:TBmpMgr;
begin
 Result:=False;
 With TForm2(TwgForm) do
  For I:=0 to Twigs.Bitmaps.Bitmaps.Count-1 do begin
   Bm:=Twigs.Bitmaps.Bitmaps[I];
   If Bm.GUIDStr=GUID_ then begin
    Result:=True;
    Index_:=I;
    exit;
   end;
  end;
end;

procedure TUpdateMessage.SetOperation(ID, Opr: AnsiString);
begin
{
try If Assigned(MyHelp) then MyHelp.Lines.LoadFromFile(MainPath+'\Help\'+ID+'+'+Opr+'.rtf');
except on E:Exception do
 MyHelp.Lines.Text:=ID+'+'+Opr+'.rtf '+E.Message;
end;
 If Assigned(MyHelp) then MyHelp.Hint:='Расширеная подсказка ['+MainPath+'\Help\'+ID+'+'+Opr+'.rtf'+']';
}
end;

end.
