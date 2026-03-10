Unit WPTForm2;
Interface uses
               WPTForm1, Collect, EcDot, WPTwigs, Classes, SysUtils,
               TwgColle, eMath, UpdateMessages;

Type
 TForm11=Class(TForm1)
  Procedure AddObject(F:TForm11;Rebuild:Boolean = True;OnlySQW:Boolean = False);
  Procedure Pack(OnModifiedPrim:procModifiedPrim);override;
  procedure ProcessLayerTable;
 end;

Type
 TForm12=Class(TForm11)
  Procedure Rotate(X2,Y2,Angle:Double;var X,Y:Double);
  Procedure Move(Dx,Dy:Double;var X,Y:Double);
  Procedure RotateObjects(X2,Y2,Angle:Double);virtual;abstract;
  Procedure MoveObjects(Dx,Dy:Double);virtual;abstract;
 end;

Type
 TForm13=class(TForm12)
  ObjView:TForm13;
  Function  CreateObjectView(QueryOnCreate:Boolean):Boolean;virtual;abstract;// ñîçäàåò íîâûé îáúåêò
  Function  CreateView:Pointer;virtual;abstract;// ñîçäàåò íîâûé îáúåêò
  Procedure SaveObjView(View:Pointer);virtual;abstract;
 end;

Type
 TForm14 = class(TForm13)
  newForm:TForm14;
//  InterLine:TInterLine;
//  newPerehlests:TPerehlests;
  actPereIndex:Integer;
  Mode50:Boolean;
  GlobalPerehlests:Boolean;
 //
  Procedure ShowPerehlests(DC:hDC);virtual;abstract;
  Procedure ShowNotLink_Up(DC:hDC;Ind:Integer);virtual;abstract;
 end;

{ Внимание: линейные контура индексируются по G=[габаритов]}
Type
  TIndexPointsXY=class(TSortedCollection)
//    Function Compare(Key1,Key2:pointer):Integer;override;
   end;
  TIndexLotsXY=class(TSortedCollection)
//    Function Compare(Key1,Key2:pointer):Integer;override;
   end;
  TIndexTwigsXY=class(TSortedCollection)
//    Function Compare(Key1,Key2:pointer):Integer;override;
   end;
  TIndexPointsUID=class(TSortedCollection)
//    Function Compare(Key1,Key2:pointer):Integer;override;
//    Function KeyOf(P:Pointer):Pointer;override;
   end;
  TIndexLotsUID=class(TSortedCollection)
//    Function Compare(Key1,Key2:pointer):Integer;override;
   end;

  TDeleteTaheoProject = function (IndexOf: Integer):boolean of object;

Type
 TFormTaheo = class(TForm14)
  thIndexPointsXY:TIndexPointsXY;
  thIndexLotsXY:TIndexLotsXY;
  thIndexTwigsXY:TIndexTwigsXY;
  thIndexPointsUID:TIndexPointsUID;
  thIndexLotsUID:TIndexLotsUID;
  OnDeleteTaheoProject:TDeleteTaheoProject;
  Constructor Create(Count1:Byte);
  Constructor Load   (Stream :TBufStream);override;
  Destructor  Destroy;override;
 end;

Type
 TForm2=Class(TFormTaheo)
  APoint:TPointDot;
  ParentMap:Pointer;
  Function  CreateAs(F:TForm2):TForm2;
  Function  CreateObjectView(QueryOnCreate:Boolean):Boolean;override;
  Function  CreateView:Pointer;override;
  Procedure SaveObjView(View:Pointer);override;
 //
  Procedure ClearObject;
 //
 end;


Type
  TOnLine=class(TTwgObject)
    D1,D2,D3:TDot;
   end;

{
 Const RForm:TStreamRec=(
         ObjType:10000;
         VmtLink:Ofs(TypeOf(TForm2)^);
         Load   :@TForm2.Load;
         Store  :@TForm2.Store);
}
{----------------------------------------------------------------------}


implementation uses EcLot, Maths_Basic, newSelector, newSettings, TwgDraw, newProcs,
                    Polygons, newResource, WpArcs;

{ TForm11 }

procedure TForm11.AddObject(F: TForm11; Rebuild, OnlySQW: Boolean);
begin
 //
end;

procedure TForm11.Pack(OnModifiedPrim: procModifiedPrim);
begin
 //
end;

procedure TForm11.ProcessLayerTable;
begin
 //
end;

{ TForm12 }

procedure TForm12.Move(Dx, Dy: Double; var X, Y: Double);
begin
 X:=X+Dx;Y:=Y+Dy;
end;

procedure TForm12.Rotate(X2, Y2, Angle: Double; var X, Y: Double);
var XD,YD,XD1:Double;
    Dx,Dy:Double;
begin
 XD:=-Y;
 YD:=X;XD1:=XD;
 XD:=XD*COS(Angle)-SIN(Angle)*YD;
 YD:=COS(Angle)*YD+SIN(Angle)*XD1;
 X:=YD;
 Y:=-XD;
end;

{ TFormTaheo }

constructor TFormTaheo.Create(Count1: Byte);
begin
  inherited Create(Count1);
   thIndexPointsXY:=TIndexPointsXY.Create(1);thIndexPointsXY.Duplicates:=True;
   thIndexLotsXY  :=TIndexLotsXY.Create(1);thIndexLotsXY.Duplicates:=True;
   thIndexTwigsXY :=TIndexTwigsXY.Create(1);thIndexTwigsXY.Duplicates:=True;
   thIndexPointsUID:=TIndexPointsUID.Create(1);thIndexPointsUID.Duplicates:=True;
   thIndexLotsUID :=TIndexLotsUID.Create(1);thIndexLotsUID.Duplicates:=True;
end;

destructor TFormTaheo.Destroy;
begin
  inherited Destroy;
   thIndexPointsXY.DeleteAll;thIndexPointsXY.Free;
   thIndexLotsXY.DeleteAll;thIndexLotsXY.Free;;
   thIndexTwigsXY.DeleteAll;thIndexTwigsXY.Free;
   thIndexPointsUID.DeleteAll;thIndexPointsUID.Free;
   thIndexLotsUID.DeleteAll;thIndexLotsUID.Free;
end;

constructor TFormTaheo.Load(Stream: TBufStream);
begin
  inherited Load(Stream);
   thIndexPointsXY:=TIndexPointsXY.Create(1);thIndexPointsXY.Duplicates:=True;
   thIndexLotsXY  :=TIndexLotsXY.Create(1);thIndexLotsXY.Duplicates:=True;
   thIndexTwigsXY :=TIndexTwigsXY.Create(1);thIndexTwigsXY.Duplicates:=True;
   thIndexPointsUID:=TIndexPointsUID.Create(1);thIndexPointsUID.Duplicates:=True;
   thIndexLotsUID :=TIndexLotsUID.Create(1);thIndexLotsUID.Duplicates:=True;
end;

{ TForm2 }

Function TForm2.CreateObjectView;
 var I:Integer;
 begin
  try
   ObjView:=TForm2.Create(0);
   ObjView.Twigs.Insert(TWG_Twig,TTwig.CreateAsTwig(Twigs.TAt(0),True));
   ObjView.About.XMin:=-100000000;
   ObjView.About:=About;
   ObjView.ClName:=ClName;
   ObjView.hWndParent:=hWndParent;
   ObjView.V25:=V25;
   ObjView.Taheo:=Taheo;
   ObjView.MkLib:=MkLib;
   ObjView.LayerTable:=LayerTable;
   ObjView.MirrorObject:=True;
   // тахеометрия
   For I:=0 to Twigs.TaheoIndexes.Count-1 do ObjView.Twigs.TaheoIndexes.Add(Twigs.TaheoIndexes[I]);
   Result:=True;
  except Result:=False;raise;end;
 end;

Function TForm2.CreateView;
 begin
   Result:=TForm2.Create(0);
   TForm2(Result).Twigs.Insert(TWG_Twig,TTwig.CreateAsTwig(Twigs.TAt(0),True));
   TForm2(Result).About:=About;
 end;

 Procedure TForm2.saveObjView;
  var Buf:TBufStream;S:String;I:Integer;V:TForm2;
  begin
   V:=View;
   S:=(TForm2(View).About.Path)+'\'+(TForm2(View).About.MyName);
   try
    Buf:=TBufStream.InitFileStream(S,fmCreate);
    try
//     Writeln('Info==================');
//     Writeln(V.Twigs.TwigsCount);
     For I:=1 to V.Twigs.TwigsCount-1 do begin
//      writeln('Cnt=', TTwig(V.Twigs.TAt(I)).Coord.Count,' ',TTwig(V.Twigs.TAT(I)).ClassName);
     end;
     Buf.Put(TForm2(View));
//     Writeln('End==================');
    finally
     Buf.Free;
    end;
   except on E:Exception do
    MessageError('Невозможно создать файл '+S+'->'+E.Message)
   end;
  end;

Function TForm2.CreateAs(F: TForm2):TForm2;
begin
 If CreateObjectView(False) then begin
  Result:=TForm2(ObjView);
  ObjView:=nil;
 end else Result:= nil;
end;

procedure TForm2.ClearObject;
var I:Integer;
begin
 For I:=Twigs.TwigsCount-1 downTo 1 do begin
  Twigs.AtDelete(TWG_Twig,I);
 end;
 For I:=Twigs.LotsCount-1 downTo 0 do begin
  Twigs.AtDelete(TWG_Lot,I);
 end;
 For I:=Twigs.AnyCount-1 downTo 0 do begin
  Twigs.DelAAt(I);
 end;
 Twigs.Bitmaps.Bitmaps.FreeAll;
end;


initialization
end.
