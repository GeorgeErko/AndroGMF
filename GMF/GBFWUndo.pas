unit GBFWUndo;

interface uses Collect, EcLot, WptForm2, EcDot, SysUtils,
               UndoItem;

const
 LU_AddPrim = 1;
 LU_ModifiedPrim = 2;
 LU_DeletedPrim = 3;

type
TGUIDLots=class(TSortedCollection)
 Function Compare(Key1,Key2:Pointer):Integer;override;
end;

TGUIDPoints=class(TSortedCollection)
 Function Compare(Key1,Key2:Pointer):Integer;override;
end;

type

 TPrimUndo = class (TUndoItem)
  GUIDLots:TGUIDLots;
  GUIDPoints:TGUIDPOints;
  Constructor Create(Form:Pointer;Opr:Integer;OprStr_:String);
  Procedure AddModifiedPrim(Prim:TObject;NewGuid:Boolean = False);
  Function Undo(TWGForm:TForm2 = nil):boolean;override;
  Function FoundPrim(Lot:TLot;Point:TPointDot;GUID:TGUID;var Index:Integer):TObject;
  Function DeletePrim(GUID:TGUID):Boolean;
 //
  Function UndoDelete:Integer;
  Function UndoUnModified:Integer;
  Function UndoUnDeleted:Integer;
 //
  Procedure CreateGUIDs;
  Procedure FreeGUIDs;
 end;

implementation uses EcText, WpTwigs, TwgColle, newClassBuilder, newSelector, RPrims,
                    UpdateMessages;

{ TPrimUndo }

constructor TPrimUndo.Create(Form: Pointer; Opr: Integer; OprStr_:String);
begin
 Inherited Create(Form,Opr);
 Name:=OprStr_;
end;

procedure TPrimUndo.AddModifiedPrim(Prim: TObject;NewGUID:Boolean = False);
var Lot,mainLot:TLot;PD:TPointDot;LotTwig,Twig:TTwig;
    I,J:Integer;
    Bm:TBmpMgr;
    F: TEFont;
begin
 If Prim is TLot then begin
  Lot:=TLotClass(Prim.ClassType).CreateAsLotWithAll(TLot(Prim));
  If not NewGUID then Lot.GUID:=TLot(Prim).GUID;
  mainLot:=TLot(Prim);
  For I:=0 to Lot.Coord.Count-1 do begin
   // вставляем ветки в зеркало
   LotTwig:=Lot.GetTwig(Twigs.Twigs,I);
   If LotTwig = nil then
    LotTwig:=Lot.GetTwig(Twigs.Twigs,I);
   Twig:=TTwigClass(LotTwig.ClassType).CreateAsTwig(LotTwig,True);
{    If Twig is tTwigArc then With TTwigArc(Twig) do begin
     For J:=0 to TwigCoord.Count-1 do With TDot(TwigCoord[J]) do If J=0 then PMoveTo(XDot,YDot) else PLineTo(XDot,YDot);
//     Writeln('add...Radius =',Radius,' ',C.XDot,' ',C.YDot);
//     readln;
    end;}
   Twig.Calculate;                                                        
   { If Twig is tTwigArc then With TTwigArc(Twig) do begin
     For J:=0 to TwigCoord.Count-1 do With TDot(TwigCoord[J]) do If J=0 then PMoveTo(XDot,YDot) else PLineTo(XDot,YDot);
     Writeln('addCalc...Radius =',Radius,' ',C.XDot,' ',C.YDot);
//     readln;
    end;}
   Mirror.Twigs.Insert(TWG_Twig,Twig);
   TLong(Lot.Coord[I]).Num:=(Mirror.Twigs.TwigsCount-1)*Trunc((TLong(mainLot.Coord[I]).Num/abs(TLong(mainLot.Coord[I]).Num)));
  end;
   Mirror.Twigs.Insert(TWG_Lot,Lot);
 end else If Prim is TPointDot then begin
  PD:=TPointDot(Prim);
  PD:=TPointClass(PD.ClassType).CreateAsPointDot_(PD,True);
  If not NewGUID then PD.GUID:=TPointDot(Prim).GUID;
  Mirror.Twigs.Insert(TWG_Point,PD);
 end else If Prim is TEFont then begin
  F:=TEFont.CreateAsFont(TEFont(Prim));
    If not NewGUID then F.GUID:=TEFont(Prim).GUID;
  Mirror.Twigs.Insert(TWG_Point,F);
 end else If Prim is TBmpMgr then begin
  Bm:=TBmpMgr.CreateAsParam(TBmpMgr(Prim).GetParams,TBmpMgr(Prim).BmName);
  If NewGUID then CreateGUID(Bm.GUID);
  Mirror.Twigs.Bitmaps.Bitmaps.Insert(Bm);
 end;
// Writeln('++++++++++++++++++ModifiedPrim=',Mirror.Twigs.LotsCount);
end;

function TPrimUndo.DeletePrim(GUID: TGUID): Boolean;
var I:Integer;B:Byte;PD:TPointDot;
begin
 Result:=False;
 With Twigs do begin
  For I:=0 to Twigs.LotsCount-1 do If isEqualGUID(TLot(Twigs.LAt(I)).GUID,GUID) then begin
   If UpdateMessage.DeletePrim(Twigs.LAt(I)) then begin
    Twigs.AtDelete(TWG_Lot,I);Result:=True;
   end;
   exit;
  end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin
    If isEqualGUID(PD.GUID,GUID) then begin
     If UpdateMessage.DeletePrim(Twigs.AAt(I,B)) then begin Twigs.DelAAt(I);Result:=True;end;
     exit;
    end;
   end else
   If B=TWG_Font then begin
    If isEqualGUID(TEFont(PD).GUID,GUID) then begin
     If UpdateMessage.DeletePrim(Twigs.AAt(I,B)) then begin Twigs.DelAAt(I);Result:=True;end;
     exit;
    end;
   end;
  end;
  For I:=0 to Twigs.Bitmaps.Count-1 do begin
   If isEqualGUID(Twigs.Bitmaps[I].GUID,GUID) then begin
    If UpdateMessage.DeletePrim(Twigs.Bitmaps[I]) then begin Twigs.Bitmaps.Bitmaps.AtFree(I);Result:=True;end;
    exit;
   end;
  end;
 end;
end;

function TPrimUndo.FoundPrim(Lot:TLot;Point:TPointDot;GUID:TGUID;var Index:Integer): TObject;
var I:Integer;B:Byte;PD:TPointDot;
begin
 Result:=nil;Index:=-1;
{ If Lot<>nil then begin
  If GUIDLots.Search(Lot,I) then begin
   Result:=GUIDLots[I];Index:=TLot(Result).ParentIndex;
  end else
   Writeln('NoLot');
 end else
 If Point<>nil then begin
  If GUIDPoints.Search(Point,I) then begin
   Result:=GUIDPoints[I];Index:=TPointDot(Result).ParentIndex;
  end else
   Writeln('NoPoint');
 end else With Twigs do
  For I:=0 to Twigs.Bitmaps.Count-1 do begin
   If isEqualGUID(Twigs.Bitmaps[I].GUID,GUID) then begin Result:=Twigs.Bitmaps[I];Index:=I;exit;end;
  end;
 exit;}
 With Twigs do begin
  For I:=0 to Twigs.LotsCount-1 do If isEqualGUID(TLot(Twigs.LAt(I)).GUID,GUID) then begin Result:=Twigs.LAt(I);Index:=I;exit;end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin
    If isEqualGUID(PD.GUID,GUID) then begin Result:=Twigs.AAt(I,B);Index:=I;exit;end;
   end else
   If B=TWG_Font then begin
    If isEqualGuid(TEFont(Twigs.AAt(I,B)).GUID,GUID) then begin Result:=Twigs.AAt(I,B);Index:=I;exit;end;
   end;
  end;
  For I:=0 to Twigs.Bitmaps.Count-1 do begin
   If isEqualGUID(Twigs.Bitmaps[I].GUID,GUID) then begin Result:=Twigs.Bitmaps[I];Index:=I;exit;end;
  end;
 end;
end;

function TPrimUndo.Undo(TWGForm:TForm2 = nil): boolean;
var Lot:TLot;PD:TPointDot;Font:TEFont;Count:Integer;
begin
 Result:=Inherited Undo;
 Case Operation of
  LU_AddPrim:begin
              // удаление объекта, добавленного ранее
              Writeln('DelphiTest.dll -> UndoCol.DeleteObjects...');
              Count:=UndoDelete;
              if Count>0 then Writeln('DelphiTest.dll -> UndoCol.Deleted ',IntToStr(Count),' objects...') else
                              Writeln('DelphiTest.dll -> UndoCol.DeleteTransactionFailed.')
             end;
  LU_ModifiedPrim:begin
              Writeln('DelphiTest.dll -> UndoCol.UnModifiedObjects...');
                   Count:=UndoUnModified;
                   if Count>0 then Writeln('DelphiTest.dll -> UndoCol.Modified ',IntToStr(Count),' objects...') else
                              Writeln('DelphiTest.dll -> UndoCol.ModifyTransactionFailed.')
                  end;
  LU_DeletedPrim:begin
                  Writeln('DelphiTest.dll -> UndoCol.UnDeletedObjects...');
                  Count:=UndoUnDeleted;
                 end;
 end;
end;

function TPrimUndo.UndoDelete: Integer;
var I:Integer;B:Byte;PD:TPointDot;F:TEFont;
    Lot:tLot;
    ThisPack:Boolean;
begin
 Result:=0;
 ThisPack:=False;
// If Assigned(On
 For I:=Mirror.Twigs.LotsCount-1 downTo 0 do begin
  Lot:=Mirror.Twigs.LAt(I);
//  Writeln(1);
  If DeletePrim(Lot.GUID) then begin
   Mirror.Twigs.AtDelete(TWG_Lot,I);
   Inc(Result);
   ThisPack:=True;
  end;
 end;
//  Mirror.ClassBuildII;
//  Mirror.Pack(nil);
 For I:=Mirror.Twigs.AnyCount-1 downTo 0 do begin
  PD:=Mirror.Twigs.AAt(I,B);
  If B=TWG_Point then begin
   If DeletePrim(PD.GUID) then begin Mirror.Twigs.DelAAT(I);Inc(Result);end;
  end else If B=TWG_Font then begin
   If DeletePrim(TEFont(PD).GUID) then begin Mirror.Twigs.DelAAT(I);Inc(Result);end;
  end;
 end;
 For I:=Mirror.Twigs.Bitmaps.Count-1 downTo 0 do begin
   If DeletePrim(Mirror.Twigs.Bitmaps[I].GUID) then begin Mirror.Twigs.Bitmaps.Bitmaps.AtFree(I);Inc(Result);end;
 end;
 If ThisPack then begin
   Twigs.ClassBuildII;
   Twigs.Pack(nil);
 end;
end;

function TPrimUndo.UndoUnModified: Integer;
var I,J,K:Integer;B:Byte;PD,PD1:TPointDot;F:TEFont;
    MirrorLot,Lot,FreeLot:TLot;
    Index:Integer;
    LotTwig,Twig:TTwig;
    FreeTwigCount:Integer;
    FreePoint:Pointer;
    LayerChange:Boolean;
    BM, BM1:TBmpMgr;
    MI:Integer;
Procedure UpdateFreeLot(ModifyFreeLot:boolean);
var K:Integer;
begin
 For K:=Twigs.Twigs.TwigsCount-1 downTo FreeTwigCount do Twigs.Twigs.AtDelete(Twg_Twig,K);
 Lot.Free;
 Twigs.Twigs.LotsLarge[Index]:=FreeLot;
 If FreeLot.Coord.Count=0 then Twigs.Twigs.AtDelete(TWG_Lot,Index) else
  If ModifyFreeLot then OnModifiedPrim(FreeLot);
end;
Procedure UpdateLot;
begin
 Lot.SetMinMax(Twigs.Twigs);
 {If Lot.TypeLot=2 then} Lot.SetFromTwig(Twigs.Twigs);
// Inc(Result);
 FreeLot.Free;
end;
begin
 Result:=0;
 try
//  CreateGUIDS;
// Writeln('+++++++++++++++++++++++++++Deleted=',Mirror.Twigs.LotsCount);
 For I:=Mirror.Twigs.LotsCount-1 downTo 0 do begin
  MirrorLot:=TLot(Mirror.Twigs.LAt(I));
//  WRiteln('MirrorLot = ',MirrorLot.GuidStr,' ',MirrorLot.Coord.Count);
  Lot:=TLot(FoundPrim(MirrorLot,nil,MirrorLot.GUID,Index));
  LayerChange:=True;
//  Writeln('I=',I,' ',Lot=nil);
  If Lot=nil then begin
   // добавляем псевдо-контур
   FreeLot:=TLot.Create(MirrorLot.ClassHandle.ID,MirrorLot.ClassHandle,MirrorLot.TypeLot);
   FreeLot.GUID:=MirrorLot.GUID;
//   Writeln('NirrorLotCoordCount=',MirrorLot.Coord.Count);
   try
    Twigs.Twigs.Insert(TWG_Lot,FreeLot,False);
   except
   //Writeln('Error GBFWUNDO =',FreeLot.ClassName);
   { For K:=0 to Twigs.Twigs.IndexLarge.Count-1 do begin
     Writeln('Klas=',TLot(Twigs.Twigs.IndexLarge[K]).ClassName);
    end;}
   end;              
   Index:=Twigs.Twigs.LotsCount-1;
   LayerChange:=False;
  end;                              
  If Index<>-1 then begin
   If LayerChange then LayerChange:=Round(MirrorLot.ClassCode*100)<>Round(Lot.ClassCode*100);
   //TLot(Twigs.Twigs.LotsLarge[Index]).Free;
   FreeLot:=Twigs.Twigs.LotsLarge[Index];// запоминаем контур к-й был перед заменой
                                         // если не удасться модифицировать контур -> вернем его по индексу Index
   FreeTwigCount:=Twigs.Twigs.TwigsCount;
   Lot:=TLotClass(MirrorLot.ClassType).CreateAsLotWithAll(MirrorLot);
   Lot.GUID:=FreeLot.GUID;
//   Writeln('UnModifiedUndo=====',Lot.GUIDStr,' ',Lot.Coord.Count);
   Twigs.Twigs.LotsLarge[Index]:=Lot;
 {перекладываем ветки в новом контуре}
//  Writeln('Pered_Twig= LotrCount=',Lot.Coord.Count,' MirrorCount=',MirrorLot.Coord.Count);
   For J:=0 to MirrorLot.Coord.Count-1 do begin
    // вставляем ветки в зеркало
    LotTwig:=MirrorLot.GetTwig(Mirror.Twigs,J);
    Twig:=TTwigClass(LotTwig.ClassType).CreateAsTwig(LotTwig,True);
    Twig.Calculate;
    {If Twig is tTwigArc then With TTwigArc(Twig) do begin
     Writeln('mirror...Radius =',Radius,' ',C.XDot,' ',C.YDot);
    end;}
    Twigs.Twigs.Insert(TWG_Twig,Twig);
    TLong(Lot.Coord[J]).Num:=(Twigs.Twigs.TwigsCount-1){*Trunc(TLong(mirrorLot.Coord[I]).Num/abs(TLong(mirrorLot.Coord[I]).Num))};
   end;
   If not LayerChange then begin
    if not OnModifiedPrim(Lot,True) then begin
     // возвращаем исходное состояние
     UpdateFreeLot(False);
    end else begin
     // принимаем контур
     Inc(Result);
     UpdateLot;
    end;
   end else begin // было изменение слоя
    OnDeletePrim(Lot);
    If not OnAddPrim(Lot) then begin
     UpdateFreeLot(True);
    end else begin
     Inc(Result);
     UpdateLot;
    end;
   end;
  end else raise Exception.Create('Undo.NotUnModified.NotFoundLotGUID = '+GUIDToString(MirrorLot.GUID));
 end;
 For I:=Mirror.Twigs.AnyCount-1 downTo 0 do begin
 end;
 For I:=Mirror.Twigs.AnyCount-1 downTo 0 do begin
  PD1:=Mirror.Twigs.AAt(I,B);
  If B=TWG_Point then begin
   PD:=FoundPrim(nil,PD1,PD1.GUID,Index) as TPointDot;
   LayerChange:=True;
   If PD=nil then begin
    FreePoint:=TPointDot.Create(ZNULL,0,0);
    Twigs.Twigs.Insert(TWG_Point,FreePoint);
    Index:=Twigs.Twigs.AnyCount-1;
    LayerChange:=False;                             
   end;
   If Index<>-1 then begin
    FreePoint:=Twigs.Twigs.AnyLarge[Index];
    if LayerChange then LayerChange:=Round(PD1.Code*100)<>Round(PD.Code*100);
    PD:=TPointClass(PD1.ClassType).CreateAsPointDot_(PD1,True);
    PD.GUID:=PD1.GUID;
    Twigs.Twigs.AnyLarge[Index]:=PD;
    If PD.Z<>ZNull then begin
     //проходим по контурам - меняем в треугольниках Z
     For MI:=0 to Twigs.Twigs.LotsCount-1 do TLot(Twigs.Twigs.LAt(MI)).Make3dPoint(Twigs.Twigs,PD);
    end;
    If not LayerChange then begin
     if not UpdateMessage.ModifiedPrim(PD) then begin
      // возвращаем исходное состояние
      PD.Free;
      Twigs.Twigs.AnyLarge[Index]:=FreePoint;
      If TPointDot(FreePoint).XDot=ZNull then Twigs.Twigs.DelAAt(Index);
     end else begin
      Inc(Result);
      TObject(FreePoint).Free;
     end;
    end else begin
     //OnDeletePrim(FreePoint);
     If not OnAddPrim(PD) then begin
      PD.Free;
      Twigs.Twigs.AnyLarge[Index]:=FreePoint;
      If TPointDot(FreePoint).XDot=ZNull then Twigs.Twigs.DelAAt(Index);// else OnModifiedPrim(FreePoint);
     end else begin
      Inc(Result);
      TObject(FreePoint).Free;
     end;
    end;
   end else raise Exception.Create('Undo.NotUnModified.NotFoundPointGUID = '+GUIDToString(PD.GUID));
  end else If B=TWG_Font then begin
   F:=FoundPrim(nil,nil,TEFont(PD).GUID,Index) as TEFont;
   If F<>nil then begin
    FreePoint:=Twigs.Twigs.AnyLarge[Index];
    F:=TEFont.CreateAsFont(F);
    F.GUID:=TEFont(FreePoint).GUID;
    Twigs.Twigs.AnyLarge[Index]:=F;
    if not OnModifiedPrim(F) then begin
     // возвращаем исходное состояние
     F.Free;
     Twigs.Twigs.AnyLarge[Index]:=FreePoint;
    end else begin
     Inc(Result);
     TObject(FreePoint).Free;
    end;
   end else raise Exception.Create('Undo.NotUnModified.NotFoundFontGUID = '+GUIDToString(TEFont(PD).GUID));
  end;
 end;
  For I:=Mirror.Twigs.Bitmaps.Count-1 downTo 0 do begin
   BM1:=Mirror.Twigs.Bitmaps[I];
   BM:=FoundPrim(nil,nil,BM1.GUID,Index) as TBmpMgr;
   LayerChange:=True;
   If BM=nil then begin
    // добавляем псевдо-контур
    FreePoint:=TBmpMgr.CreateAsParam(TBmpMgr(BM1).GetParams,TBmpMgr(BM1).BmName);;
    Twigs.Twigs.Bitmaps.Bitmaps.Insert(FreePoint);
    Index:=Twigs.Twigs.Bitmaps.Count-1;
    LayerChange:=False;
   end;
   If Index<>-1 then begin
    FreePoint:=Twigs.Twigs.Bitmaps[Index];
    BM:=TBmpMgr.CreateAsParam(TBmpMgr(BM1).GetParams,TBmpMgr(BM1).BmName);
    Twigs.Twigs.Bitmaps.Bitmaps[Index]:=BM;
    if not OnModifiedPrim(BM) then begin
     // возвращаем исходное состояние
     BM.Free;
     Twigs.Twigs.Bitmaps.Bitmaps[Index]:=FreePoint;
    end else begin
     Inc(Result);
     TObject(FreePoint).Free;
    end;
   end else
   {If Index<>-1 then begin // добавляем Bitmap

   end else }raise Exception.Create('Undo.NotUnModified.NotFoundBitmapGUID = '+GUIDToString(Bm.GUID));
  end;
 finally
//  FreeGUIDS;
  If Result<>0 then begin ClassRebuildIndex:=True;
  Twigs.ClassBuildII;
  If Mirror.Twigs.LotsCount>0 then
   Twigs.Pack(nil);
  end;
 // Writeln('CountLotsAfterUndo=',Twigs.Twigs.LotsCount,' ',Twigs.Twigs.AnyCount);
 { For I:=0 to Twigs.Twigs.LotsCount-1 do begin
   Writeln('Lot=',I,' Count=',TLot(Twigs.Twigs.LAt(I)).Coord.Count);
  end;}
 end;
end;


function TPrimUndo.UndoUnDeleted: Integer;
var I,J,K:Integer;B:Byte;PD,PD1:TPointDot;F:TEFont;
    MirrorLot,Lot,FreeLot:TLot;
    Index:Integer;
    LotTwig,Twig:TTwig;
    FreeTwigCount:Integer;
    FreePoint:Pointer;
    LayerChange:Boolean;
    BM, BM1:TBmpMgr;
    MI:Integer;  
Procedure UpdateLot;
begin
 Lot.SetMinMax(Twigs.Twigs);
 {If Lot.TypeLot=2 then} Lot.SetFromTwig(Twigs.Twigs);
// Inc(Result);
end;
begin
 Result:=0;
 With Mirror do begin
  For I:=0 to Twigs.AnyCount-1 do begin                          
   PD:=Twigs.AAt(I,B);
   If Assigned(UpdateMessage.OnAddPrim) then If not UpdateMessage.AddPrim(PD) then exit;
  end;
 end;
 Twigs.AddObject(Mirror,False);
 Mirror:=nil;
 ClassRebuildIndex:=True;ClassRebuildSbor:=True;
 Twigs.ClassBuildII;
 exit;
end;

procedure TPrimUndo.CreateGUIDs;
var I:Integer;PD:TPointDot;W:Byte;
begin
 GUIDLots:=TGUIDLOts.Create(Twigs.Twigs.LotsCount);
 GUIDPoints:=TGUIDPoints.Create(Twigs.Twigs.AnyCount);
 For I:=0 to Twigs.Twigs.LotsCount-1 do begin GUIDLots.Insert(Twigs.Twigs.LAt(I));TLot(Twigs.Twigs.LAt(I)).ParentIndex:=I;end;
 For I:=0 to Twigs.Twigs.AnyCount-1 do begin
  PD:=Twigs.Twigs.AAt(I,W);
  If W = TWG_Point then begin GUIDPoints.Insert(PD);PD.ParentIndex:=I;end;
 end;
end;

procedure TPrimUndo.FreeGUIDs;
begin
 GUIDLots.DeleteAll;GUIDLots.Free;
 GUIDPOints.DeleteAll;GUIDPoints.Free;
end;

{ TGUIDLots }

function TGUIDLots.Compare(Key1, Key2: Pointer): Integer;
begin
 if TLot(Key1).GUIDStr<TLot(Key2).GUIDStr then compare:=1 else
 if TLot(Key1).Guidstr=TLot(Key2).Guidstr then
  compare:=0
  else compare:=-1;
end;

{ TGUIDPoints }

function TGUIDPoints.Compare(Key1, Key2: Pointer): Integer;
begin
 if TPointDot(Key1).Guidstr<TPointDot(Key2).Guidstr then compare:=1 else
 if TPointDot(Key1).Guidstr=TPointDot(Key2).Guidstr then
  compare:=0
  else compare:=-1;
end;

initialization
end.


function TPrimUndo.UndoUnModified: Integer;
var I,J,K:Integer;B:Byte;PD,PD1:TPointDot;F:TEFont;
    MirrorLot,Lot,FreeLot:TLot;
    Index:Integer;
    LotTwig,Twig:TTwig;
    FreeTwigCount:Integer;
    FreePoint:Pointer;
    LayerChange:Boolean;
    BM, BM1:TBmpMgr;
    MI:Integer;
    FreeCol:PCollection; // коллекция удаляемых контуров и точек
Procedure UpdateFreeLot(ModifyFreeLot:boolean);
var K:Integer;
begin
 For K:=Twigs.Twigs.TwigsCount-1 downTo FreeTwigCount do Twigs.Twigs.AtDelete(Twg_Twig,K);
 Lot.Free;
 Twigs.Twigs.LotsLarge[Index]:=FreeLot;
 If FreeLot.Coord.Count=0 then Twigs.Twigs.AtDelete(TWG_Lot,Index) else
  If ModifyFreeLot then OnModifiedPrim(FreeLot);
end;
Procedure UpdateLot;
begin
 Lot.SetMinMax(Twigs.Twigs);
 {If Lot.TypeLot=2 then} Lot.SetFromTwig(Twigs.Twigs);
// Inc(Result);
end;
begin
 Result:=0;
 Write('CGUIDs=',TimeToStr(Now));CreateGUIDS;Writeln('  ECGUIDs=',TimeToStr(Now));
 try
// Writeln('+++++++++++++++++++++++++++Deleted=',Mirror.Twigs.LotsCount);
 FreeCol:=PCollection.Create(1);
 For I:=Mirror.Twigs.LotsCount-1 downTo 0 do begin
  MirrorLot:=TLot(Mirror.Twigs.LAt(I));
  Lot:=TLot(FoundPrim(MirrorLot,nil,MirrorLot.GUID,Index));
  LayerChange:=True;
  If Index<>-1 then begin
//   If LayerChange then LayerChange:=Round(MirrorLot.ClassCode*100)<>Round(Lot.ClassCode*100);
   FreeLot:=Twigs.Twigs.LotsLarge[Index];// запоминаем контур к-й был перед заменой
                                         // если не удасться модифицировать контур -> вернем его по индексу Index
   FreeCol.Insert(FreeLot);
   FreeTwigCount:=Twigs.Twigs.TwigsCount;
  // Lot:=TLotClass(MirrorLot.ClassType).CreateAsLotWithAll(MirrorLot);
  // Lot.GUID:=MirrorLot.GUID;
//   Writeln('UnModifiedUndo=====',Lot.GUIDStr,' ',Lot.Coord.Count);
   Twigs.Twigs.LotsLarge[Index]:=MirrorLot;
 {перекладываем ветки в новом контуре}
//  Writeln('Pered_Twig= LotrCount=',Lot.Coord.Count,' MirrorCount=',MirrorLot.Coord.Count);
   For J:=0 to MirrorLot.Coord.Count-1 do begin
    // вставляем ветки в зеркало
    LotTwig:=MirrorLot.GetTwig(Mirror.Twigs,J);
   // Twig:=TTwigClass(LotTwig.ClassType).CreateAsTwig(LotTwig,True);
   // Twig.Calculate;
    {If Twig is tTwigArc then With TTwigArc(Twig) do begin
     Writeln('mirror...Radius =',Radius,' ',C.XDot,' ',C.YDot);
    end;}
    Twigs.Twigs.Insert(TWG_Twig,LotTwig);
    TLong(Lot.Coord[J]).Num:=(Twigs.Twigs.TwigsCount-1){*Trunc(TLong(mirrorLot.Coord[I]).Num/abs(TLong(mirrorLot.Coord[I]).Num))};
   end;
   UpdateLot;
   Inc(Result);
  end else raise Exception.Create('Undo.NotUnModified.NotFoundLotGUID = '+GUIDToString(MirrorLot.GUID));
 end;
 For I:=Mirror.Twigs.AnyCount-1 downTo 0 do begin
  PD1:=Mirror.Twigs.AAt(I,B);
  If B=TWG_Point then begin
   PD:=FoundPrim(nil,PD1,PD1.GUID,Index) as TPointDot;
   LayerChange:=True;
   If Index<>-1 then begin
    FreePoint:=Twigs.Twigs.AnyLarge[Index];
    FreeCol.Insert(FreePoint);
   // PD:=TPointDot.CreateAsPointDot(PD1,True);
    PD.GUID:=PD1.GUID;
    Twigs.Twigs.AnyLarge[Index]:=PD1;
    If PD.Z<>ZNull then begin
     //проходим по контурам - меняем в треугольниках Z
     For MI:=0 to Twigs.Twigs.LotsCount-1 do TLot(Twigs.Twigs.LAt(MI)).Make3dPoint(Twigs.Twigs,PD);
    end;
    Inc(Result);
   end else raise Exception.Create('Undo.NotUnModified.NotFoundPointGUID = '+GUIDToString(PD.GUID));
  end;
 end;
  For I:=Mirror.Twigs.Bitmaps.Count-1 downTo 0 do begin
   BM1:=Mirror.Twigs.Bitmaps[I];
   BM:=FoundPrim(nil,nil,BM1.GUID,Index) as TBmpMgr;
   LayerChange:=True;
   If Index<>-1 then begin
    FreePoint:=Twigs.Twigs.Bitmaps[Index];
    FreeCol.Insert(FreePoint);
//    BM:=TBmpMgr.CreateAsParam(TBmpMgr(BM1).GetParams,TBmpMgr(BM1).BmName);
    Twigs.Twigs.Bitmaps.Bitmaps[Index]:=BM1;
    Inc(Result);
   end else raise Exception.Create('Undo.NotUnModified.NotFoundBitmapGUID = '+GUIDToString(Bm.GUID));
  end;
 finally
  FreeCol.Free;
  FreeGUIDS;
  If Result<>0 then begin ClassRebuildIndex:=True;
  Twigs.ClassBuildII;
   With Mirror do begin
    Twigs.TwigsLarge.DeleteAll;
    Twigs.LotsLarge.DeleteAll;
    Twigs.AnyLarge.DeleteAll;
    Twigs.Bitmaps.Bitmaps.DeleteAll;
   end;
   Mirror.Free;Mirror:=nil;
  end;
 end;
end;

