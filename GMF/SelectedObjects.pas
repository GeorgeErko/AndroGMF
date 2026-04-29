unit SelectedObjects;

interface uses Collect, WptForm2, Classes, EcDot;

type
 TSelectedObjects =class (TTwgObject)
  private
   Objects:PCollection;
   Coords:PCollection;
   fOnUpdate: TNotifyEvent;
   function GetObject(Index: Integer): Pointer;
   procedure SetObject(Index: Integer; const Value: Pointer);
   function GetCoord(Index: Integer): TDot;
   procedure SetCoord(Index: Integer; const Value: TDot);
   function getObjects: PCollection;
  public
  TwgForm:TForm2;
  Locked:Boolean;
  Constructor Create(TwgForm_:TForm2;OnUpdateEvent:TNotifyEvent);
  Destructor Destroy;override;
 //
  Constructor   Load  (Stream :TBufStream);Override;
  Procedure     Store (Stream :TBufStream);Override;
 //
  Procedure Insert(Obj:Pointer);
  Procedure AtDelete(Index:Integer);
  Procedure DeleteAll;
  Function IndexOf(Obj:Pointer):Integer;
  Procedure Pack;
  Property ObjectIndex[Index:Integer]:Pointer read GetObject write SetObject;default;
  Property GeoObjects:PCollection read getObjects;
  Property Coord[Index:Integer]:TDot read GetCoord write SetCoord;
  Function Count:Integer;
  Property OnUpdate:TNotifyEvent read fOnUpdate write fOnUpdate;
  Procedure Update;
 //
  Function CreateTemporaryObject(TempTwigs:TForm2):boolean;
 //
 end;

implementation uses EcLot, WpTwigs, RPrims, TwgColle, objBlockList,
                    newLayersTable, newClassBuilder, newProcs, TWgDraw, Writer;


{ TSelectedObjects }

procedure TSelectedObjects.AtDelete(Index: Integer);
begin
 If (Objects[Index]<>nil) and (TObject(Objects[Index]) is TTD) then
  TTD(Objects[Index]).SetActive(0);
 Objects.AtDelete(Index);
 Coords.AtDelete(Index);
 If not Locked then If Assigned(OnUpdate) then OnUpdate(Self);
end;

function TSelectedObjects.Count: Integer;
begin
 Result:=Objects.Count;
end;

constructor TSelectedObjects.Create(TwgForm_:TForm2;OnUpdateEvent:TNotifyEvent);
begin
 Objects:=PCollection.Create(1);
 Coords:=PCollection.Create(1);
 TwgForm:=TwgForm_;
 OnUpdate:=OnUpdateEvent;
end;

procedure TSelectedObjects.DeleteAll;
var I:Integer;
begin
 try
  For I:=0 to Objects.Count-1 do
   If (Objects[I]<>nil) and (TObject(Objects[I]) is TTD) then
    TTD(Objects[I]).SetActive(0);
 except
  Writeln('ERROR 70');
 end;
 Objects.DeleteAll;
 WriteIn(['Deleteall1']);
 Coords.FreeAll;
  WriteIn(['Deleteall2=', Assigned(fOnUpdate)]);
 If not Locked then If Assigned(fOnUpdate) then OnUpdate(Self);
 WriteIn(['Deleteall3']);
end;

destructor TSelectedObjects.Destroy;
var I:Integer;
begin
 If Objects<>nil then
  For I:=0 to Objects.Count-1 do
   If (Objects[I]<>nil) and (TObject(Objects[I]) is TTD) then
    TTD(Objects[I]).SetActive(0);
 Objects.Free;
 Coords.Free;
end;

function TSelectedObjects.GetObject(Index: Integer): Pointer;
begin
 Result:=Objects[Index];
end;

function TSelectedObjects.IndexOf(Obj: Pointer): Integer;
begin
 Result:=Objects.IndexOf(Obj);
end;

procedure TSelectedObjects.Insert(Obj: Pointer);
begin
 Objects.Insert(Obj);
 If (Obj<>nil) and (TObject(Obj) is TTD) then
  TTD(Obj).SetActive(1);
 Coords.Insert(TDot.Create(ZNull,0,0));
 If not Locked then If Assigned(OnUpdate) then OnUpdate(Self);
end;

procedure TSelectedObjects.Pack;
begin
 Objects.Pack;
end;

procedure TSelectedObjects.SetObject(Index: Integer; const Value: Pointer);
begin
 If (Objects[Index]<>nil) and (TObject(Objects[Index]) is TTD) then
  TTD(Objects[Index]).SetActive(0);
 Objects[Index]:=Value;
 If (Value<>nil) and (TObject(Value) is TTD) then
  TTD(Objects[Index]).SetActive(1);
end;

procedure TSelectedObjects.Update;
begin
 If not Locked then If Assigned(OnUpdate) then OnUpdate(Self);
end;

//---------------------------------------------------

procedure TSelectedObjects.Store(Stream: TBufStream);
var Form:TForm2;BL:TBlockList;LT:TLayerTable;FS:Pointer;
begin
 Form:=TForm2.Create(0);
 Form.Twigs.Insert(TWG_Twig,TTwig.Create(TwgForm.Selector, 0));
 Form.About:=TwgForm.About;
// GlobalIniLoad:=False;
 Form.LoadClassLib(True);
 CreateTemporaryObject(Form);
 BL:=Form.Twigs.BlockList;LT:=Form.LayerTable;FS:=Form.FontColEx;
 Form.Twigs.BlockList:=TwgForm.Twigs.BlockList;Form.LayerTable:=TwgForm.LayerTable;Form.FontColEx:=TwgForm.FontColEx;
 Stream.Put(Form);
 Form.Twigs.BlockList:=BL;Form.LayerTable:=LT;Form.FontColEx:=FS;
 Form.Free;
end;

constructor TSelectedObjects.Load(Stream: TBufStream);
var Form:TForm2;
begin
 TwgForm:=TForm2(Stream.Get);
 TwgForm.SetGabarites;
 TwgForm.ClassBuildII;
end;

Function TSelectedObjects.CreateTemporaryObject(TempTwigs:TForm2):boolean;
var Lot:TLot;PD:TPointDot;LotTwig,Twig:TTwig;
    I,J,K:Integer;
    Bm:TBmpMgr;
    Prim:TObject;
    divLayers:PCollection;
begin
 TempTwigs.LayerTable.MergeTable(TwgForm.LayerTable,nil,True); ///!!!!!!
 For K:=0 to Objects.Count-1 do begin
  Prim:=Objects[K];
  If Prim is TLot then begin
   Lot:=TLotClass(Prim.ClassType).CreateAsLotWithAll(TLot(Prim));
   Lot.GUID:=TLot(Prim).GUID;
   For I:=0 to Lot.Coord.Count-1 do begin
    // вставляем ветки в зеркало
    LotTwig:=Lot.GetTwig(TwgForm.Twigs,I);
    Twig:=TTwigClass(LotTwig.ClassType).CreateAsTwig(LotTwig,True);
    Twig.Calculate;
    TempTwigs.Twigs.Insert(TWG_Twig,Twig);
    TLong(Lot.Coord[I]).Num:=TempTwigs.Twigs.TwigsCount-1;
   end;
    TempTwigs.Twigs.Insert(TWG_Lot,Lot);
  end else If Prim is TPointDot then begin
   PD:=TPointDot(Prim);
   PD:=TPointClass(PD.ClassType).CreateAsPointDot_(PD,True);
   PD.GUID:=TPointDot(Prim).GUID;
   TempTwigs.Twigs.Insert(TWG_Point,PD);
  end else If Prim is TBmpMgr then begin
   Bm:=TBmpMgr.CreateAsParam(TBmpMgr(Prim).GetParams,TBmpMgr(Prim).BmName);
   TempTwigs.Twigs.Bitmaps.Bitmaps.Insert(Bm);
  end;
 end;
end;


function TSelectedObjects.GetCoord(Index: Integer): TDot;
begin
 Result:=Coords[Index];
end;

procedure TSelectedObjects.SetCoord(Index: Integer; const Value: TDot);
begin
 TDot(Coords[Index]).Free;
 Coords[Index]:=Value;
end;

function TSelectedObjects.getObjects: PCollection;
begin
 Result := Objects;
end;

end.
