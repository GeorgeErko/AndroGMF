Unit WPTForm2;
Interface uses
               WPTForm1, Collect, EcDot, WPTwigs, Classes, SysUtils,
               TwgColle, eMath, UpdateMessages, notLink_, WPGeo,
               newSelector, WPArcs;

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
 TPerehlests=class(TSortedCollection)
  Selector: TSelector;
   Constructor Create(Selector_: TSelector);
   Function Compare(Key1,Key2:Pointer):Integer;override;
 end;

Type
 TForm14 = class(TForm13)
  newForm:TForm14;
  InterLine:TInterLine;
  newPerehlests:TPerehlests;
  actPereIndex:Integer;
  Mode50:Boolean;
  GlobalPerehlests:Boolean;
 //
  Procedure InitPereParams;
  Procedure FreePereParams;
 //
  Procedure GetLinePere(Twig,Twig1:TTwig;P:PCollection);
  Procedure GetLineArcPere(TwigLine:TTwig;TwigArc:TTwigArc;P:PCollection);
  Procedure GetLineCirclePere(TwigLine:TTwig;TwigCircle:TTwigCircle;P:PCollection;InsertPerePoints:Boolean = True);
  Procedure GetArcPere(T,T1:TTwigArc;P:PCollection);
  Procedure GetArcCirclePere(T:TTwigArc;T1:TTwigCircle;P:PCollection;InsertPerePoint:Boolean = True);
  Procedure GetCirclePere(T,T1:TTwigCircle;P:PCollection;InsertPerePoint:Boolean = True);
 //
  Function  newPereTwigs(Twig,Twig1:TTwig;InsertPerePoint:Boolean = True):Boolean;
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


implementation uses EcLot, Maths_Basic, newSettings, TwgDraw, newProcs,
                    Polygons, newResource, Util, Types_Dimano, intervals,
                    circle_di, circle, Writer;

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

{ TPerehlests }
function TPerehlests.Compare(Key1, Key2: Pointer): Integer;
 var W,W1:TWorkPere;
 begin
  Compare:=ord(not Selector.EqualAnyPoints(TWorkPere(Key1).X,TWorkPere(Key1).Y,TWorkPere(Key2).X,TWorkPere(Key2).Y));
 end;

constructor TPerehlests.Create(Selector_: TSelector);
begin
 inherited Create(1);
 Selector := Selector_;
end;

{ TForm14 }

procedure TForm14.InitPereParams;
begin
 newPerehlests:=TPerehlests.Create(Selector);
 newPerehlests.Duplicates:=False;
 InterLine:=TInterLine.Create(nil,nil,nil,nil);
end;

Procedure TForm14.GetLinePere;
 var I,J:Integer;BDT,EDT,BDT1,EDT1:TDot;PD:TDot;
 var t,o:Double;x1,y1,x2,y2,xa,ya,xb,yb:Double;
     Edge1,Edge2:TEdge;
 begin
  Twig.DeleteMinOtr(1);Twig1.DeleteMinOtr(1);
  For I:=0 to Twig.Coord.Count-2 do
   begin
    BDT:=Twig.Coord[I];EDT:=Twig.Coord[I+1];
    x1:=BDT.XDot;y1:=BDT.YDot;x2:=EDT.XDot;y2:=EDT.YDot;
    If InterLine<>nil then begin InterLine.Line1Dot1:=BDT;InterLine.Line1Dot2:=EDT;end;
     For J:=0 to Twig1.Coord.Count-2 do
      begin
       BDT1:=Twig1.Coord[J];EDT1:=Twig1.Coord[J+1];
       xa:=BDT1.XDot;ya:=BDT1.YDot;xb:=EDT1.XDot;yb:=EDT1.YDot;
      //
//       Writeln(x1:-1:2,' ',y1:-1:2,' ',x2:-1:2,' ',y2:-1:2,' ',xa:-1:2,' ',ya:-1:2,' ',xb:-1:2,' ',yb:-1:2);
//       Writeln('Inter=',intersection_straight_lines(x1,y1,x2,y2,xa,ya,xb,yb,t,o),' ',t:-1:4,' ',o:-1:4);
      //
       If InterLine<>nil then begin InterLine.Line2Dot1:=BDT1;InterLine.Line2Dot2:=EDT1;end;
       PD:=TDot.Create(0,0,0);
       InterLine.Calc2(PD,True);
       If PD<>nil then begin
         P.Insert(TWorkPere.Create(PD.XDot,PD.YDot,Integer(Twig),Integer(Twig1),I,J));
         PD.Free;
       end else begin
        Edge1:=TEdge.Create(x1,y1,x2,y2);
        Edge2:=TEdge.Create(xa,ya,xb,yb);
        If point_on_edge(xa,ya,Edge1) then P.Insert(TWorkPere.Create(xa,ya,Integer(Twig),Integer(Twig1),I,J));
        If point_on_edge(xb,yb,Edge1) then P.Insert(TWorkPere.Create(xb,yb,Integer(Twig),Integer(Twig1),I,J));
        If point_on_edge(x1,y1,Edge2) then P.Insert(TWorkPere.Create(x1,y1,Integer(Twig),Integer(Twig1),I,J));
        If point_on_edge(x2,y2,Edge2) then P.Insert(TWorkPere.Create(x2,y2,Integer(Twig),Integer(Twig1),I,J));
        Edge1.Free;Edge2.Free;
       end;
      end;
   end;
 end;

Procedure TForm14.GetLineArcPere(TwigLine:TTwig;TwigArc:TTwigArc;P:PCollection);
 var I,J:Integer;D1,D2:TDot;PD:TDot1;R:Double;P2:PCollection;X,Y:Double;
     Tw:TTwig;
 begin
  R:=TwigArc.Radius;
  TwigLine.DeleteMinOtr(1);
  For I:=0 to TwigLine.Coord.Count-2 do
   begin
    D1:=TwigLine.Coord[I];D2:=TwigLine.Coord[I+1];
    J:=P.Count;
    If TwigArc.GetTwigDist(D1.XDot,D1.YDot,X,Y)<=(1/Const_Of_PrecCoord*2) then P.Insert(TWorkPere.Create(X,Y,Integer(TwigLine),Integer(TwigArc),I,-1));
    If TwigArc.GetTwigDist(D2.XDot,D2.YDot,X,Y)<=(1/Const_Of_PrecCoord*2) then P.Insert(TWorkPere.Create(X,Y,Integer(TwigLine),Integer(TwigArc),I,-1));
    If J<>P.Count then begin exit; end;
   With TwigArc do
    try P2:=sol_2(D1.XDot,D1.YDot,D2.XDot,D2.YDot,R,C.XDot,C.YDot,A.XDot,A.YDot,B.XDot,B.YDot); except P2:=PCollection.Create(1);end;
     For J:=0 to P2.Count-1 do begin
      PD:=P2[J];
       P.Insert(TWorkPere.Create(PD.X,PD.Y,Integer(TwigLine),Integer(TwigArc),I,-1));
     end;
    If P2.Count=0 then begin
     Tw:=TTwig.Create(Selector, 0);Tw.Insert(TDot.CreateAsDot(D1));Tw.Insert(TDot.CreateAsDot(D2));
      If Tw.GetTwigDist(TwigArc.A.XDot,TwigArc.A.YDot,X,Y)<=(1/Const_Of_PrecCoord*2) then P.Insert(TWorkPere.Create(X,Y,Integer(TwigArc),Integer(TwigLine),I,-1));
      If Tw.GetTwigDist(TwigArc.B.XDot,TwigArc.B.YDot,X,Y)<=(1/Const_Of_PrecCoord*2) then P.Insert(TWorkPere.Create(X,Y,Integer(TwigArc),Integer(TwigLine),I,-1));
     Tw.Free;
    end;
    P2.Free;
   end;
 end;

procedure TForm14.GetLineCirclePere(TwigLine: TTwig; TwigCircle: TTwigCircle; P: PCollection;InsertPerePoints:Boolean = True);
var I:Integer;D1,D2:TDot;
    P0,P01,P02,P1,P2:lPoint;
    a,b:Double;
begin
 TwigLine.DeleteMinOtr(1);
 For I:=0 to TwigLine.Coord.Count-2 do
  begin
   D1:=TwigLine.Coord[I];D2:=TwigLine.Coord[I+1];
   With TwigCircle do begin
    P0.X:=C.XDot;P0.Y:=C.YDot;
    P1.X:=D1.XDot;P1.Y:=D1.YDot;P2.X:=D2.XDot;P2.y:=D2.YDot;
    If line_okruzh_peres(P0,P01,P02, P1,P2, Radius) then begin
     If TwigLine.GetTwigDist(P01.X,P01.Y,a,b)<=0.001 then begin
      P.Insert(TWorkPere.Create(P01.x,P01.y,Integer(TwigLine),Integer(TwigCircle),I,-1));
      If InsertPerePoints then TwigCircle.InsertPerePoint(TDot.Create(P01.X,P01.Y,0));
     end;
     If TwigLine.GetTwigDist(P02.X,P02.Y,a,b)<=0.001 then begin
      P.Insert(TWorkPere.Create(P02.x,P02.y,Integer(TwigLine),Integer(TwigCircle),I,-1));
      If InsertPerePoints then TwigCircle.InsertPerePoint(TDot.Create(P02.X,P02.Y,0));
     end;
    end;
   end;
  end;
end;

Procedure TForm14.GetArcPere;
 var P2:PCollection;J:Integer;PD:TDot1;
 begin
//  Writeln('====',T.ParentIndex,' ',T1.ParentIndex,' ',T.ClassHAndle.ID,' ',T1.ClassHandle.ID);
  If Selector.EqualAnyPoints(T.XMin,T.YMin,T1.XMin,T1.YMin) and Selector.EqualAnyPoints(T.XMax,T.YMax,T1.XMax,T1.YMax) and Selector.EqualPoints(T.C,T1.C) then exit;
   P2:=sol_1(T.Radius,T.C.XDot,T.C.YDot,T.A.XDot,T.A.YDot,T.B.XDot,T.B.YDot,
             T1.Radius,T1.C.XDot,T1.C.YDot,T1.A.XDot,T1.A.YDot,T1.B.XDot,T1.B.YDot);
//  Writeln('====end');
//   P2:=sol_1(T.Radius,-T.C.YDot,T.C.XDot,-T.A.YDot,T.A.XDot,-T.B.YDot,T.B.XDot,
//             T1.Radius,-T1.C.YDot,T1.C.XDot,-T1.A.YDot,T1.A.XDot,-T1.B.YDot,T1.B.XDot);
   For J:=0 to P2.Count-1 do begin
    PD:=P2[J];
    P.Insert(TWorkPere.Create(PD.X,PD.Y,Integer(T),Integer(T1),-1,-1));
   end;
  P2.Free;
end;

procedure TForm14.GetArcCirclePere(T: TTwigArc; T1: TTwigCircle;P: PCollection;InsertPerePoint:Boolean = True);
var P2:PCollection;J:Integer;PD:TDot1;a,b:Double;
begin
 P2:=Intersection_2_Circles(T.C.XDot,T.C.YDot,T.Radius,T1.C.XDot,T1.C.YDot,T1.Radius);
  For J:=0 to P2.Count-1 do begin
   PD:=P2[J];
   If T.GetTwigDist(PD.X,PD.Y,a,b)<=0.001 then begin
    If InsertPerePoint then T1.InsertPerePoint(TDot.Create(PD.X,PD.Y,0));
    P.Insert(TWorkPere.Create(PD.X,PD.Y,Integer(T),Integer(T1),J,J));
   end;
  end;
 P2.Free;
end;

procedure TForm14.GetCirclePere(T, T1: TTwigCircle; P: PCollection;InsertPerePoint:Boolean = True);
var P2:PCollection;J:Integer;PD:TDot1;
begin
 P2:=Intersection_2_Circles(T.C.XDot,T.C.YDot,T.Radius,T1.C.XDot,T1.C.YDot,T1.Radius);
  For J:=0 to P2.Count-1 do begin
   PD:=P2[J];
    If InsertPerePoint then T.InsertPerePoint(TDot.Create(PD.X,PD.Y,0));
    If InsertPerePoint then T1.InsertPerePoint(TDot.Create(PD.X,PD.Y,0));
    P.Insert(TWorkPere.Create(PD.X,PD.Y,Integer(T),Integer(T1),J,J));
  end;
 P2.Free;
end;

function TForm14.newPereTwigs(Twig, Twig1: TTwig; InsertPerePoint: Boolean): Boolean;
 var BDT,EDT,BDT1,EDT1,BT,ET,BT1,ET1,PD:TDot;
     I,J:Integer;
     W:TWorkPere;
     Sect,Sect1:TSect;
     P:PCollection;
 Function Found:boolean;
  var I:Integer;
  begin
   Found:=False;
   For I:=0 to newPerehlests.Count-1 do
    begin
     if newPerehlests.Compare(newPerehlests[I],W)=0 then begin Found:=True;Exit;end;
    end;
  end;
 begin
  P:=PCollection.Create(1);
  BT:=Twig.TwigCoord.At(0);ET:=Twig.TwigCoord.At(Twig.TwigCoord.Count-1);
  BT1:=Twig1.TwigCoord.At(0);ET1:=Twig1.TwigCoord.At(Twig1.TwigCoord.Count-1);
//  Writeln(Twig.ClassName,' ',Twig1.ClassName);
  If (Twig is TTwigCircle) and (Twig1 is TTwigCircle) then begin
   try  GetCirclePere(TTwigCircle(Twig),TTwigCircle(Twig1),P, InsertPerePoint);except end;
  end else
  If (Twig is TTwigArc) and (Twig1 is TTwigCircle) then begin
   try GetArcCirclePere(TTwigArc(Twig),TTwigCircle(Twig1),P, InsertPerePoint);except end;
  end else
  If (Twig is TTwigCircle) and (Twig1 is TTwigArc) then begin
   try GetArcCirclePere(TTwigArc(Twig1),TTwigCircle(Twig),P, InsertPerePoint);except end;
  end else
  If (Twig is TTwig) and (Twig1 is TTwigCircle) then
   begin
    GetLineCirclePere(Twig,TTwigCircle(Twig1),P, InsertPerePoint);
   end else
  If (Twig is TTwigCircle) and (Twig1 is TTwig) then
   begin
    GetLineCirclePere(Twig1,TTwigCircle(Twig),P, InsertPerePoint);
   end else
  If (Twig is TTwigArc) and (Twig1 is TTwigArc) then
   begin
    GetArcPere(TTwigArc(Twig),TTwigArc(Twig1),P);
   end else
  If (Twig is TTwigArc) and not(Twig1 is TTwigArc) then
   begin
    GetLineArcPere(Twig1,TTwigArc(Twig),P);
   end else
  If not(Twig is TTwigArc) and (Twig1 is TTwigArc) then
   begin
    GetLineArcPere(Twig,TTwigArc(Twig1),P);
   end else GetLinePere(Twig,Twig1,P);
    For I:=0 to P.Count-1 do With Selector do
     begin
      W:=P[I];
//      If PointVis(W.X,W.Y) then
       If not ((EqualAnyPoints(W.X,W.Y,BT.XDot,BT.YDot) or EqualAnyPoints(W.X,W.Y,ET.XDot,ET.YDot)) and
               (EqualAnyPoints(W.X,W.Y,BT1.XDot,BT1.YDot) or EqualAnyPoints(W.X,W.Y,ET1.XDot,ET1.YDot))) then
        if Not Found then
         newPerehlests.Insert(TWorkPere.Create(W.X,W.Y,w.Twig1,w.twig2,W.Seg1,W.Seg2));
     end;
    P.Free;
 end;

procedure TForm14.FreePereParams;
begin
 InterLine.Line1Dot1:=nil; InterLine.Free;
 newPerehlests.Free;
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
  If not mirrorobject then
   WriteIn(['LoadF2']);
   thIndexPointsXY:=TIndexPointsXY.Create(1);thIndexPointsXY.Duplicates:=True;
   thIndexLotsXY  :=TIndexLotsXY.Create(1);thIndexLotsXY.Duplicates:=True;
   thIndexTwigsXY :=TIndexTwigsXY.Create(1);thIndexTwigsXY.Duplicates:=True;
   thIndexPointsUID:=TIndexPointsUID.Create(1);thIndexPointsUID.Duplicates:=True;
   thIndexLotsUID :=TIndexLotsUID.Create(1);thIndexLotsUID.Duplicates:=True;
  WriteIn(['+*LoadF22']);
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
