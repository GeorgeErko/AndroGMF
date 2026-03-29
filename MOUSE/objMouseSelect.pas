unit objMouseSelect;

interface uses objMouse, newSelector, EcDot, WpTwigs, EcLot, mpMarker,
               FMX.Graphics, Collect, drawTwigs, sysUtils, Math,
               WPTForm2, System.UITypes, System.Classes, newSettings,
               DrawGrid, System.Skia, newProcs;

// объект для выбора примитивов на карте, редактированию примитивов
// (вставка точек, разбивка сегментов)

const
  tdNotUsed = 1;
  tdUsed = 2;
  tdDop = 3;

const
 //
  em_GetObject = 500;
  em_ObjectMove = 5001;
  em_ObjectRotate = 5002;
  em_GetObjectFrag = 5003;
  em_Mirror = 5004;
  em_Copy = 530;
  em_Scale = 5005;
  em_MoveObjectPoints = 5006;
 //

type
 TMouseSelector = class (TKeyMouseHook)
  mpTwig:TTwigPath;
  addAngle:Double;
  blockAngle:Double;
  pastRotation:Double;
  Marker,Marker2:TMarker;
  // операции захвата примитивов
  fRect:TSect;
  objTemporaryTwig:TTwig;
  //
  fixedPointObject:TDot; // точка - начало отмера...
  //
  fActiveLots:PCollection;
  TemporaryDot:TDot;
  markerOrthoTwig:TTwig;
  Stvor_: TStvorLine;
  Constructor Create(ATwigs:Pointer;AFreeProc:TFreeProc);override;
  Destructor Destroy;override;
  Procedure SetCur(curName:String);override;
 {}
  Function emGetDotMarker(var varX,varY:Double;LastPoint:TDot;StvorLine:TStvorLine;out objPoint:TTwgObject;UsePathTwig:Boolean=True;UseGrid:Boolean=True;useSTS:boolean = False):boolean;
  Function emGetNearestPoint(X, Y: Double): TDot;
  Function emInsertPointInTwig(X, Y : Double;LotCol:PCollection;selPoints:TNearestPoints):Integer;
  Function emFilterActiveLot(X,Y:Double):boolean;
 {}
  Function AddOrthoTwig(Twig:TTwig):Integer; // возвращает кол-во направляющих
  Procedure TimerOpen;virtual;
  Procedure TimerClose;virtual;
 {}
  Procedure MouseDown(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean); override;
  Procedure MouseUp(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean); override;
  Procedure MouseMove(Form:TForm2; Shift: TShiftState;X, Y: Double; var Hook:boolean); override;
  Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage:Boolean=False); override;
 //
  Function GlobalSettings: TGlobalSettings;
  Function GridPath: TGridPath;
 end;

implementation uses MathS, EMath, WpGeo, NotLink_,
                    WptForm0, newBlock, UndoColNew,
                    TwgColle, newClassBuilder, WpArcs, FMX.Dialogs,
                    Writer;

{ TMouseSelector }

constructor TMouseSelector.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 Marker:=TMarker.Create(Selector,Twigs.hWndParent,mtDiagCross,TAlphaColorRec.Red,20,2);
 Marker.Colors[0]:=TAlphaColorRec.Red;
 Marker.Colors[1]:=TAlphaColorRec.Blue;
 Marker.Colors[2]:=TAlphaColorRec.Lime;
 Marker.Colors[3]:=TAlphaColorRec.Maroon;
 OrthoTwigs := TOrthoTwigs.Create(Selector);
 addAngle:=Pi/2;
 fActiveLots:=PCollection.Create(1);
 TemporaryDot:=TDot.Create(0,0,tdNotUsed);
 markerOrthoTwig:=TTwig.Create(Selector, 0);markerOrthoTwig.Coord.Insert(TDot.Create(0,0,0));
// markerOrthoTwig
 pastRotation:=0;
//
 Stvor_.X1 := xyNull;
end;

destructor TMouseSelector.Destroy;
begin
 Error:='0';
 try
 Error:='1';
  Marker.Remove(nil);
  Marker.Free;
  inherited;
 Error:='2';
  fActiveLots.DeleteAll;fActiveLots.Free;
  TemporaryDot.Free;
  markerOrthoTwig.Free;
  OrthoTwigs.Free;
  except
  MessageError('Отладчик : сообщение от '+ClassName+'. Шаг отладки :'+Error);
 end;
end;


function TMouseSelector.emGetDotMarker(var varX, varY: Double;LastPoint:TDot;StvorLine:TStvorLine;out objPoint:TTwgObject;
                                       UsePathTwig:Boolean=True;UseGrid:Boolean=True;useSTS:boolean = False): boolean;
var Dist:Double;XX,YY,XX1,YY1:Double;Twig:TTwig;
    D:TDot;Cnt:Integer;IndexTwig:Integer;
    DrawDot:TDot;
    Seg:Integer;D1,D2,D3,D4,PD:TDot;
    IL:TInterLine;
    LinkTwigs:PCollection;
    oldTwigs:TForm2;
    I:Integer;W:Byte;
    PP:TPointDot;
    Stvor_:TStvorLine;
    SaveTemporaryTwig:TTwig;
    UsedOperation:Boolean;
    Moved:Boolean;
    MS:TMouseSelector;
    Twigs_:TForm2;
    T0: UInt64;
    DtMs: UInt64;
    GetTwigProcessed: Integer;
    GetTwigAdded: Integer;
    GetTwigVisible: Integer;
    GetTwigScanned: Integer;
    GetTwigDistCalls: Integer;
    GetTwigIsVisibleMs: UInt64;
    GetTwigDistMs: UInt64;
    DtGetTwig: UInt64;
    TGetTwig0: UInt64;
Function PerpendOn(P1,P2:TDot;var XOut,YOut: Double):boolean;
var X,Y:Double;Tw1,Tw2:TTwig;Angle:Double;
    W:TWorkPere;
begin
 Result:=False;
 If mpTwig = nil then exit;
 X:=mpTwig.LastPoint.XDot;Y:=mpTwig.LastPoint.YDot;
 Tw1:=TTwig.Create(Selector, 0);Tw1.Insert(TDot.CreateAsDot(P1));Tw1.Insert(TDot.CreateAsDot(P2));
 Tw1.SetMinMax;
 Angle:=Direct_Angle(P1.XDot,P1.YDot,P2.XDot,P2.YDot);
 Tw2:=TTwig.Create(Selector, 0);Tw2.Insert(TDot.Create(X-10000*Cos(Angle+Pi/2),Y-10000*sin(Angle+Pi/2),0));Tw2.Insert(TDot.Create(X+10000*Cos(Angle+Pi/2),Y+10000*sin(Angle+Pi/2),0));
 Tw2.SetMinMax;
 Twigs.InitPereParams;
   try Twigs.newPereTwigs(Tw1,Tw2,False);except ShowMessage('objMouseSelect '+IntToStr(121));end;
  If Twigs.newPerehlests.Count=1 then begin
   W:=Twigs.newPerehlests[0];
   XOut:=W.X;YOut:=W.Y;
   Result:=True;
  end;
 Twigs.FreePereParams;
end;
Function GetNearestPointFromLink(P:PCollection;var X,Y:Double):boolean; // возвращает расстояние до ближайшей точки пересечения
var Tw,Tw2:TTwig;I,J:Integer;
    Min:Double;
    W,Pnt:TWorkPere;
begin
 Result:=False;
 objPoint:=nil;
 Twigs.InitPereParams;
// Writeln('LinksBeg',TimeToStr(Now),' ',P.Count);
 For I:=0 to P.Count-2 do begin
  Tw:=P[I];
//  If not((Tw is TTwigCircle) and (Tw.What = Twig_OrthoPoint)) then
  For J:=I+1 to P.Count-1 do begin
   Tw2:=P[J];
   If (Tw.Coord.Count=Tw2.Coord.Count) and (Selector.EqualAnyPoints(Tw.XMin,Tw.YMin,Tw2.XMin,Tw2.YMin)) then continue;
   try Twigs.newPereTwigs(Tw,Tw2,False);except ShowMessage('objMouseSelect '+IntToStr(119));end;
  end;// else
 end;
 Min:=1000000;Pnt:=nil;
// WRiteln('PereCount=',TimeToStr(Now),' ',Twigs.newPerehlests.Count);
 For I:=0 to Twigs.newPerehlests.Count-1 do begin
  W:=Twigs.newPerehlests[I];
  If Distance(W.X,W.Y,X,Y)<Min then begin Min:=Distance(W.X,W.Y,X,Y);Pnt:=W;end;
 end;
 if Pnt<>nil then begin
 // Writeln('CountPere=',Twigs.newPerehlests.Count,' ',Distance(W.X,W.Y,X,Y):8:2,' ',P.Count);
  Result:=True;
  X:=Pnt.X;Y:=Pnt.Y;
 end;
 Twigs.FreePereParams;
// Writeln('LinksEnd',TimeToStr(Now));
end;
Function GetTwig(var aDist:Double;P:PCollection):TTwig;
var I:Integer;Ms:Double;Twig:TTwig;a,b:Double;
    S:Double;
    V, nV: Integer;
    Vis: Boolean;
    T1: UInt64;
    Sect: TSect;
    AllowNonClosed: Boolean;
begin
 V := 0; nV := 0;
 Ms:=10000;Result:=nil;aDist:=10000;
//Writeln('GetTwigBeg',TimeToStr(now));
 If UsePathTwig then begin
  Twig:=OrthoTwigs.GetNearestTwig(varX,varY,a,b,S,P);
  If Twig<>nil then begin
   If (S<Ms) then begin Ms:=S;Result:=Twig;aDist:=S end;
  end;
 end;
// Writeln('Twigs1................');
 Sect := Selector.GRect;
  For I:=1 to Twigs.Twigs.TwigsCount-1 do begin
  Inc(GetTwigScanned);
  Twig:=Twigs.Twigs.TAt(I);
//  Writeln(I);
  if (not AllowNonClosed) and (Twig.Closed <> 1) then
  begin
   Inc(nV);
   Continue;
  end;
  Vis := Twig.IsVisible(Sect);
  if Vis then Inc(V) else Inc(nV);
  If Vis then   Inc(GetTwigProcessed);
  if Vis then If Twig.Closed=1 then begin
   Inc(GetTwigDistCalls);
   T1 := TThread.GetTickCount64;
   S:=Twig.GetTwigDist(varX,varY,a,b);
   Inc(GetTwigDistMs, TThread.GetTickCount64 - T1);
   If Selector.XRasst(S)<=Twigs.Settings.psAutoDisst then
    If P.IndexOf(Twig)=-1 then begin
     P.Insert(Twig);
     Inc(GetTwigAdded);
    end;
   If (S<=Ms) then begin Ms:=S;Result:=Twig;aDist:=S;end;
  end else
 // WriteIn(['notvis', varX, varY]);
 end;
// Writeln('TwigsEnd............');
 If Result<>nil then begin
 // Writeln('Dist=',S:8:2,' ',Ms:8:2,' ',Result.ClassName);
 end;// else Writeln('FALSE TWIG');
//Writeln('GetTwigEnd',TimeToStr(now));
 GetTwigVisible := V;
with selector do
 //WriteIn(['CntTw=', V, nV, grect.left, grect.top, grect.right,grect.bottom]);
end;
begin;
 T0 := TThread.GetTickCount64;
 GetTwigProcessed := 0;
 GetTwigAdded := 0;
 GetTwigVisible := 0;
 GetTwigScanned := 0;
 GetTwigDistCalls := 0;
 GetTwigIsVisibleMs := 0;
 GetTwigDistMs := 0;
 DtGetTwig := 0;
 // Marker.Move(nil,varX,varY,MoveNone,0,'DrawDot');
 try
 If GGraphSet.PaintFragment<1 then GGraphSet.PaintFragment:=300;
 //WriteIn(['H=', Selector.Drawer.Height, Selector. YGeoRasst(Selector.Drawer.Height)]);
 If Selector.YGeoRasst(Selector.Drawer.Height) > GGraphSet.PaintFragment then begin
  exit;
 end;
 addAngle:=Pi/2;blockAngle:=0;
 LinkTwigs:=PCollection.Create(1);
 Marker.Remove(nil);Marker.mZ:=ZNull;
  If Twigs.Settings.psSaveOrthoTwigs then OrthoTwigs.HideLines(Selector.GCanvas);
 objPoint:=nil;
 objMemory:=nil;
 objTemporaryTwig:=nil;
 TemporaryDot.What:=tdNotUsed;
//try
 try
    If not Marker.Visible then If (UseGrid)and(GlobalSettings.MarkerView.Checked['mvGrid']) then begin // ищем притяжение по сетке
     If GridPath.GetNearestPoint(varX,varY) then begin
     // Marker.Color:=Twigs.Settings.gsGridColor;
 {} // Marker.Size:=Marker.OriginalSize;
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvGrid'], nil);
      Marker.Move(nil,varX,varY,MoveNone,0,'GridPath');
      TemporaryDot.What:=tdUsed;TemporaryDot.XDot:=varX;TemporaryDot.YDot:=varY;
      objPoint:=nil;
      TimerOpen;
      exit;
     end;// else Marker.Remove(GCanvas);
    end;
//  WRiteln('GetNearestPointBeg',TimeToStr(Now));
   DrawDot:=emGetNearestPoint(varX,varY);
//  WRiteln('GetNearestPointEnd',TimeToStr(Now));
  // Marker.Draw(GCanvas,Marker.mX,Marker.mY);
   If DrawDot<>nil then begin
   // Marker.Remove(GCanvas,'DrawDot');
    If DrawDot is TPointDot then begin
     UsedOperation:=GlobalSettings.MarkerView.Checked['mvPointDot'];
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPointDot'],nil)
    end else begin
     UsedOperation:=GlobalSettings.MarkerView.Checked['mvPoint'];
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPoint'],nil);
    end;
    If UsedOperation then begin
     Marker.Move(nil,DrawDot.XDot,DrawDot.YDot,MoveNone,0,'DrawDot');
     varX:=DrawDot.XDot;varY:=DrawDot.YDot;
     objPoint:=DrawDot;
     Marker.mZ:=DrawDot.Z;
     TemporaryDot.What:=tdUsed;TemporaryDot.XDot:=varX;TemporaryDot.YDot:=varY;
     TimerOpen;
     exit;
    end;
   end else With Twigs do begin
    TGetTwig0 := TThread.GetTickCount64;
    Twig:=GetTwig(Dist,LinkTwigs);
    DtGetTwig := TThread.GetTickCount64 - TGetTwig0;
    XX:=varX;YY:=varY;
    If Selector.XRasst(Dist)<=Settings.psAutoDisst then
     objPoint:=Twig;
    If GetNearestPointFromLink(LinkTwigs,XX,YY) and not(Twig is TTwigCircle) then
     If Selector.XRasst(Distance(varX,varY,XX,YY))<=Settings.psAutoDisst then begin
      // выбрали точку пересечения - выход
      UsedOperation:=GlobalSettings.MarkerView.Checked['mvInterSect'];
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvInterSect'],nil);
      If UsedOperation then begin
       Marker.Move(nil,XX,YY,MoveNone,0,'FromLink');
       If Settings.psSaveOrthoTwigs then
        If Round(Distance(varX,varY,XX,YY)*Const_Of_DecimalCoord*1000)>0  then
         OrthoTwigs.DrawLines(Selector.GCanvas,LinkTwigs);
       TemporaryDot.What:=tdDop;TemporaryDot.XDot:=XX;TemporaryDot.YDot:=YY;
       TimerOpen;
       varX:=XX;varY:=YY;
       objPoint:=Twig;
       exit;
      end;
      exit;
     end;
    If (Twig<>nil)and(not Marker.Visible) then begin
     If Selector.XRasst(Dist)<=Settings.psAutoDisst then begin
      Dist:=Twig.GetTwigDist(varX,varY,XX,YY);
      If Twig is TTwigArc then begin
       UsedOperation:=GlobalSettings.MarkerView.Checked['mvLine'];
       Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvLine'],nil);
       If UsedOperation then begin
        Marker.Move(nil,XX,YY,MoveNone,0,'DrawDot');
        varX:=XX;varY:=YY;
        exit;
       end;
      end else
      If Twig is TTwigCircle then begin
       UsedOperation:=GlobalSettings.MarkerView.Checked['mvLine'];
       Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvLine'],nil);
       If UsedOperation then begin
      //  Writeln('XX=',XX,' ',YY);
        Marker.Move(nil,XX,YY,MoveNone,0,'DrawDot');
      //  Writeln(Marker.Mx);
        varX:=XX;varY:=YY;
        exit;
       end;
      end else
      try Twig.ArcView:=1;
       Seg:=Twig.GetSegment(XX,YY);
        If Settings.psStvor and (StvorLine.X1<>xyNull) and (Seg<>-1) then begin
         // ловим пересечение по створу, если находим - выход из процедуры
         D1:=Twig[Seg-1];D2:=Twig[Seg];
         D3:=TDot.Create(StvorLine.X1,StvorLine.Y1,0);D4:=TDot.Create(StvorLine.X2,StvorLine.Y2,0);
         IL:=TInterLine.Create(D1,D2,D3,D4);
         PD:=TDot.Create(0,0,0);
         IL.Calc2(PD,False);
          D1:=nil;D3.Free;D4.Free;
         IL.Free;
         If PD<>nil then If Selector.XRasst(Distance(PD.XDot,PD.YDot,varX,varY))<=Settings.psAutoDisst then begin
          UsedOperation:=GlobalSettings.MarkerView.Checked['mvInterSect'];
          If UsedOperation then begin
           varX:=PD.XDot;varY:=PD.YDot;
           TemporaryDot.What:=tdUsed;TemporaryDot.XDot:=varX;TemporaryDot.YDot:=varY;
           TimerOpen;
           PD.Free;
           Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvInterSect'],nil);
           If Settings.psSaveOrthoTwigs then
            OrthoTwigs.DrawLines(Selector.GCanvas,LinkTwigs);
           TemporaryDot.What:=tdUsed;TemporaryDot.XDot:=XX;TemporaryDot.YDot:=YY;
           objPoint:=Twig;
           exit;
          end;
         end else begin {Marker.Remove(GCanvas,'Stvor_else');}PD.Free;end;
        end;
        // устанавливаем близжайшую точку к найденному сегменту
       If Seg<>-1 then begin
        D1:=Twig[Seg-1];D2:=Twig[Seg];
         addAngle:=Direct_Angle(D2.XDot,D2.YDot,D1.XDot,D1.YDot);
        If not OrthoTwigs.FindOrthoTwig(Twig) then begin
         blockAngle:=Direct_Angle(D2.XDot,D2.YDot,D1.XDot,D1.YDot)-Pi;
         pastRotation:=blockAngle;
        end else begin
         blockAngle:=Direct_Angle(D2.XDot,D2.YDot,D1.XDot,D1.YDot);
         pastRotation:=blockAngle;
        end;
       end;
      finally Twig.ArcView:=0;end;
     try
      Twig.ArcView:=1;
      Seg:=Twig.GetSegment(XX,YY);
      If Seg<>-1 then begin
       D1:=Twig[Seg-1];D2:=Twig[Seg];
        // ищем пересечение перпендикуляра к линии
         If PerpendOn(D1,D2,XX1,YY1) and (Selector.XRasst(Distance(XX1,YY1,varX,varY))<=Settings.psAutoDisst) then begin
          UsedOperation:=GlobalSettings.MarkerView.Checked['mvPerpend'];
          Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPerpend'],nil);
          Marker.Move(nil,XX1,YY1,MoveNone,0,'PerpendOn');
          XX:=XX1;YY:=YY1;
//          varX:=XX;varY:=YY;
          If UsedOperation then begin
           TemporaryDot.What:=tdDop;TemporaryDot.XDot:=XX;TemporaryDot.YDot:=YY;
           TimerOpen;
          end;
         end else
        // ищем пересечение с центром
         If Selector.XRasst(Distance((D1.XDot+D2.XDot)/2,(D1.YDot+D2.YDot)/2,XX,YY))<=Settings.psAutoDisst then begin
          XX:=(D1.XDot+D2.XDot)/2;YY:=(D1.YDot+D2.YDot)/2;
          UsedOperation:=GlobalSettings.MarkerView.Checked['mvCenterLine'];
          Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvCenterLine'],nil);
          If UsedOperation then begin
           TemporaryDot.What:=tdDop;TemporaryDot.XDot:=XX;TemporaryDot.YDot:=YY;
           TimerOpen;
          end;
        end else begin
         UsedOperation:=GlobalSettings.MarkerView.Checked['mvLine'];
         Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvLine'],nil);
         If UsedOperation then If Settings.psSaveOrthoTwigs then
          OrthoTwigs.DrawLines(Selector.GCanvas,LinkTwigs);
        end;
  {}  //If Marker.Color = Marker.Colors[0] then Marker.Size:=Marker.OriginalSize else Marker.Size:=Marker.OriginalSize div 2;
       If UsedOperation then begin
        Marker.Move(nil,XX,YY,MoveNone,blockAngle,'StvorLine');
        varX:=XX;varY:=YY;
        objPoint:=Twig;
        exit;
       end;
      end;
     finally Twig.ArcView:=0;end;
     end;// else Marker.Remove(GCanvas,'end1');
    end; //else Marker.Remove(GCanvas,'end2');
    If not Marker.Visible and (LastPoint<>nil) then begin
     Twig:=nil;
    { If (DrawTwig<>nil) then Twig:=DrawTwig else If TwigSpline<>nil then Twig:=TwigSpline;
     If Twig<>nil then If Twig.Coord.Count>2 then begin}
      D:=LastPoint;
      If Selector.XRasst(Distance(D.XDot,D.YDot,varX,varY))<=Settings.psAutoDisst then begin
       //Marker.Remove(GCanvas,'LastPoint');
       UsedOperation:=GlobalSettings.MarkerView.Checked['mvPoint'];
       Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPoint'],nil);
       If UsedOperation then begin
        Marker.Move(nil,D.XDot,D.YDot,MoveNone,0,'LastPoint');
        varX:=D.XDot;varY:=D.YDot;
        objPoint:=nil;
        exit;
       end;
      end;
     end;
    end;
    If not Marker.Visible then begin // ищем притяжение к блокам
 //    Writeln('Blocks_begin');
     Stvor_.X1:=xyNull;
     For I:=0 to Twigs.Twigs.AnyCount-1 do begin
   //   Writeln('begI=',I);
      PP:=Twigs.Twigs.AAt(I,W);
      If W=TWG_Point then
       If PP.isNoClosed then begin
        If PP.userObj<>nil then begin // ищем точку в блоке
         If PP.userObj.objType = {TWG_Ole}10000 then begin
          //If PP.userObj.PointIn(varX,varY) then begin
          If Selector.XRasst(Distance(varX,varY,PP.XDot,PP.YDot))<=Twigs.Settings.psAutoDisst then begin
         // If PP.userObj.PointIn(varX,varY) then begin
          // Marker.Color:=Marker.Colors[0];
           UsedOperation:=GlobalSettings.MarkerView.Checked['mvPoint'];
           If UsedOperation then begin
            varX:=PP.XDot;varY:=PP.YDot;
   {}    // Marker.Size:=Marker.OriginalSize;
            Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPoint'],nil);
            Marker.Move(nil,varX,varY,MoveNone,0,'OLE');
            objPoint:=PP;
            break;
           end;
          end;
         end;
         If PP.userObj.objType = 53{TWG_Block} then begin
          try
          oldTwigs:=Twigs;
          Twigs:=TGeoBlock(PP.userObj).TwgForm;
          If Twigs = nil then begin { нулевой Twigs } Moved:=False; continue;end;
           If not PP.BlockVisible{(PP.XDot,PP.YDot,PP.Ugol,PP.XKoef,PP.YKoef,)} then begin Moved:=False;continue;end;
          Moved:=True;
          PP.userObj.MoveTo(PP.XDot,PP.YDot,PP.Ugol,PP.XKoef,PP.YKoef,PP.Extrusion);
          saveTemporaryTwig:=objTemporaryTwig;
          If emGetDotMarker(varX,varY,nil,Stvor_,objPoint,UsePathTwig,UseGrid,False) then begin
           objMemory:=objPoint;
           objPoint:=PP;
           break;
          end;
//          PP.userObj.MoveUp;
          objTemporaryTwig:=saveTemporaryTwig;
          finally
           Twigs:=oldTwigs;If Moved then PP.userObj.MoveUp;
          end;
         end;
        end;
     end;
    end;
   end;
 finally LinkTwigs.DeleteAll;LinkTwigs.Free;Result:=Marker.Visible or (ObjPOint<>nil);Twigs.ActiveTwig.DeleteAll;end;
//except
// Writeln('excepted1');
// emGetDotMarker(varX, varY,LastPoint,StvorLine,objPoint,UsePathTwig,UseGrid);
// Writeln('excepted2...');
//end;
 finally
  DtMs := TThread.GetTickCount64 - T0;
  if DtMs >= 50 then
   Writein(['emGetDotMarker ms=', DtMs,
            ' getTwigMs=', DtGetTwig,
            ' getTwigScanned=', GetTwigScanned,
            ' getTwigProcessed=', GetTwigProcessed,
            ' getTwigVisible=', GetTwigVisible,
            ' getTwigAdded=', GetTwigAdded,
            ' getTwigIsVisMs=', GetTwigIsVisibleMs,
            ' getTwigDistCalls=', GetTwigDistCalls,
            ' getTwigDistMs=', GetTwigDistMs]);
 end;
end;

function TMouseSelector.emGetNearestPoint(X, Y: Double): TDot;
var D:TDot;I,N:Integer;D1,D2:Double;MinS,S:Double;
    W:byte;Tw:TTwig;
    PD:TPointDot;
    oldTwigs:TForm2;
    TmpDot:TDot;
    SS:String;
begin
 MinS:=Selector.XGeoRasst(Twigs.Settings.psAutoDisst);Result:=nil;
 For I:=1 to Twigs.Twigs.TwigsCount-1 do begin
  Tw:=Twigs.Twigs.TAt(I);
//  writeln('I=',I);
  If Tw.Closed=1 then begin
   D:=Tw.GetNearestPoint(X,Y,N);
    if D<>nil then begin
    //Writeln(I,' ',D.XDot,' ',Tw.ClassName,' ',Tw.Dots[0].XDot=Tw.Dots[1].XDot);
     S:=Distance(X,Y,D.XDot,D.YDot);
     If S<=MinS then begin
      Result:=D;MinS:=S;objTemporaryTwig:=Tw;
      SS:=FloatToStr(S);If (SS = 'NAN') or (SS='-NAN') then begin
       Writeln('NAN');
       Tw.Closed:=254;
      end;
     end;                             
    end;                                   
  end;                                                
//  writeln('EndI=',I);
 end;
// WRiteln(MinS,' ',Result<>nil);
 For I:=0 to Twigs.Twigs.AnyCount-1 do begin
  PD:=Twigs.Twigs.AAt(I,W);
  If W=TWG_Point then begin
   If PD.isNoClosed then If PD.isVisible then begin
{
    If PD.userObj<>nil then try // ищем точку в блоке
     If PD.userObj.objType = TWG_Block then begin
      oldTwigs:=Twigs;
      Twigs:=TGeoBlock(PD.userObj).TwgForm;
      PD.userObj.MoveTo(PD.XDot,PD.YDot);
      TmpDot:=emGetNearestPoint(X,Y);
      If TmpDot<>nil then begin
       Result:=TmpDot.CreateAsDot(TmpDot);MinS:=Distance(X,Y,Result.XDot,Result.YDot);
      // Result.What:=111;
      // Writeln(X:8:2,' ',Y:8:2,' ',TmpDot.XDot:8:2,' ',TmpDot.YDot:8:2);
      end;
     end;
    finally Twigs:=oldTwigs;PD.userObj.MoveUp;end;
}
   If LOperation = em_GetObject then begin
    S:=PD.GetDistance(X,Y);
    If S=0 then begin
     Result:=PD;MinS:=S;objTemporaryTwig:=nil;
      PD.GetDistance(X,Y);
     exit;                   
    end;
   end;
    S:=Distance(X,Y,PD.XDot,PD.YDot);
    If S<=MinS then begin Result:=PD;MinS:=S;objTemporaryTwig:=nil;end;
   end;                 
  end;
 end;
end;

function TMouseSelector.emInsertPointInTwig(X, Y: Double;LotCol:PCollection;selPoints:TNearestPoints): Integer;
var P:PCollection;I,J,K,M:Integer;Twig:TTwig;Seg:Integer;Dot:TDot;Index:Integer;
    Twise:Boolean;
    TransAction:Boolean; // сейчас выполняется транзакция
    ArcCol:PCollection;
begin
try
 Result:=0;
 TransAction:=Undo.TransActionStarted;
 Twise:=False;
 P:=PCollection.Create(1);
 Twigs.ActiveTwig.FreeAll;
 If Twigs.FindTwigs(X,Y,P)>0 then begin
  If not TransAction then Undo.StartTransAction;
  try
   LotCol:=PCollection.Create(1);
   Twigs.ModifiedTwigsUndo(P,LotCol); // записываем в Undo все контура к-е будут изменяться
//   Writeln('ModifyLots= ',LotCol.Count);
   For I:=0 to P.Count-1 do begin
    Twig:=P[I];
    If Twig.notPere = 1 then continue;
    If Twig is TTwigArc then begin
     If selPoints<>nil then If selPoints.FindTwig(Twig) then continue;
     Dot:=Twig.GetNearestPoint(X,Y,Index);If Distance(X,Y,Dot.XDot,Dot.YDot)<=1/Const_Of_DecimalCoord then continue;
     If selPoints<>nil then If selPoints.FindNearestPoint(X,Y)<>nil then If selPoints.FindNearestPoint(X,Y).Twig=nil then continue;
     If Twigs.Settings.psTwise then Twigs.TwiseArc(X,Y,Twig as TTwigArc);
     Inc(Result);
    end else
    If Twig is TTwigCircle then begin
     If selPoints<>nil then If selPoints.FindTwig(Twig) then continue;
     Dot:=Twig.GetNearestPoint(X,Y,Index);If Distance(X,Y,Dot.XDot,Dot.YDot)<=1/Const_Of_DecimalCoord then continue;
    If selPoints<>nil then If selPoints.FindNearestPoint(X,Y)<>nil then If selPoints.FindNearestPoint(X,Y).Twig=nil then continue;
      If Twigs.Settings.psTwise then begin
       TTwigCircle(Twig).InsertPerePoint(TDot.Create(X,Y,0));
       If TTwigCircle(Twig).perePoints.Count=2 then begin
        ArcCol:=TTwigCircle(Twig).ModifyPerePoints;
        For J:=0 to LotCol.Count-1 do TLot(LotCol[J]).DeleteTwig(Twigs.Twigs,Twig);
        Twig.Closed:=254;
        For K:=0 to ArcCol.Count-1 do begin
         Twigs.Twigs.Insert(TWG_Twig,ArcCol[K]);
        // TTwigArc(ArcCol[I]).Opr:=15;
         For J:=0 to LotCol.Count-1 do TLot(LotCol[J]).Insert(Twigs.Twigs.TwigsCount-1);
        end;
      //  If (Twigs.Settings.psTwiseLot) then begin For M:=LotCol.Count-1 downto 0 do Twigs.TwiseLot(LotCol[M]);end else
      If not (Twigs.Settings.psTwiseLot) then begin
      // Undo.AddUndoItem(TPrimUndo.Create(Self,LU_ModifiedPrim,'UndoLotsModified...C='+IntToStr(LotCol.Count)));
        For J:=0 to LotCol.Count-1 do begin
         TLot(LotCol[J]).SetMinMax(Twigs.Twigs);
       //  TPrimUndo(Undo.Last).AddModifiedPrim(LotCol[I]);
        end;
     end;
       // LotCol.DeleteAll;LotCol.Free;
        ArcCol.DeleteAll;ArcCol.Free;
        TTwigCircle(Twig).ClearPerePoints;
        Inc(Result);
       end;                                                    
      end;
    end else begin
     Seg:=Twig.GetSegment(X,Y);
     Dot:=Twig.GetNearestPoint(X,Y,Index);
    // вставляем точку, устанавливаем возможность разбивки
 //   Writeln('PeredRazbivkoi->',Index,' ',P.Count);
    // если ветвь активна - пропускаем ее
    If selPoints<>nil then If selPoints.FindTwig(Twig) then continue;
 //   Writeln('PosleRazbivki....',Distance(Dot.XDot,Dot.YDot,X,Y):8:4);
    If selPoints<>nil then If selPoints.FindNearestPoint(X,Y)<>nil then If selPoints.FindNearestPoint(X,Y).Twig=nil then continue;
     If (Distance(Dot.XDot,Dot.YDot,X,Y)>0.001) then begin
      If Twigs.Settings.psInsert then begin Twig.Coord.AtInsert(Seg,TDot.Create(X,Y,10));Twise:=True;end else Twise:=False;
     end else begin
      If ((Dot=Twig[0]) or (Dot=Twig[Twig.Coord.Count-1])) then continue;
      Twise:=True; {РАЗБИВКА !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
     end;
 //    Writeln('Twice=',Twise);
      Result:=Twigs.Twigs.TwigsCount;
     If (Twigs.Settings.psTwise) and (Twise) then begin
 //     Writeln('TwiseTwig = ',X:8:3,' ',Y:8:3);
      Twigs.TwiseTwig2(X,Y,Twig,OnModifiedPrim);
     end else begin {Writeln('NoooooTwise = ',X:8:3,' ',Y:8:3);}end;
     Result:=ord(Result<>Twigs.Twigs.TwigsCount);
    end;
   end;
  except If not TransAction then Undo.RollBack else raise Exception.Create('emInsertP0ointInTwig '+IntToStr(455));exit;end;
  If Result>0 then begin
    If (Twigs.Settings.psTwiseLot) then For I:=LotCol.Count-1 downto 0 do Twigs.TwiseLot(LotCol[I]);
   If not TransAction then Undo.Commit;
  end;// else If not TransAction then Undo.RollBack;
  P.DeleteAll;P.Free;
  LotCol.DeleteAll;LotCol.Free;
 end;
except ShowMessage('objMouseSelect '+IntToStr(464));end;
end;

function TMouseSelector.GlobalSettings: TGlobalSettings;
begin
 Result :=Selector.GlobalSettings;
end;

function TMouseSelector.GridPath: TGridPath;
begin
 Result := SElector.GridPath;
end;

function TMouseSelector.AddOrthoTwig(Twig:TTwig): Integer;
begin
 OrthoTwigs.Add(Twig,'');
end;

procedure TMouseSelector.SetCur(curName: String);
begin
 Inherited SetCur(curName);
{ If (LOperation=em_GetObject) or (Loperation=em_ObjectMove) or (Loperation=em_GetObjectFrag) or
    (LOperation=em_ObjectRotate) or (LOperation=em_Copy) or (LOperation = em_Scale) then Cursor:=LoadCursor(HInstance,'V25Default') else
}
// Cursor:=LoadCursor(HInstance,'V25ARROW');
// SetActiveCursor(Cursor);
end;

procedure TMouseSelector.TimerClose;              
begin                                                   
//
end;

procedure TMouseSelector.TimerOpen;            
begin
//
end;

function TMouseSelector.emFilterActiveLot(X, Y: Double): boolean;
var I,J,K:Integer;Lot:TLot;Twig:TTwig;Dot:TDot;Dist:Double;
begin
 For I:=0 to Twigs.Twigs.LotsCount-1 do begin
  Lot:=Twigs.Twigs.LAt(I);
  For J:=0 to Lot.Coord.Count-1 do begin
   Twig:=Lot.GetTwig(Twigs.Twigs,J);
    For K:=0 to Twig.Coord.Count-1 do begin
    Dot:=Twig[K];
    If Selector.EqualAnyPoints(Dot.XDot,Dot.YDot,X,Y) then
     If fActiveLots.IndexOf(Lot)=-1 then begin fActiveLots.Insert(Lot);break;end;
    end;
  end;
 end;
end;

procedure TMouseSelector.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := False;
end;

procedure TMouseSelector.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var
  PrevX, PrevY: Double;
  PrevVis, NewVis: Boolean;
  PrevMX, PrevMY: Double;
begin
 PrevX := MouseX;
 PrevY := MouseY;

 inherited;
 Hook := False;
 exit;
 if LMouseDown then
   Exit;

 PrevVis := (Marker <> nil) and Marker.Visible;
 if Marker <> nil then
 begin
   PrevMX := Marker.mX;
   PrevMY := Marker.mY;
 end
 else
 begin
   PrevMX := 0;
   PrevMY := 0;
 end;
 emGetDotMarker(X, Y, nil, Stvor_, objTemporary);
 NewVis := (Marker <> nil) and Marker.Visible;
 if (PrevVis <> NewVis) then
   Hook := True
 else if (Marker <> nil) and (Marker.mX <> PrevMX) then
   Hook := True
 else if (Marker <> nil) and (Marker.mY <> PrevMY) then
   Hook := True;
end;

procedure TMouseSelector.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := False;
end;

procedure TMouseSelector.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 exit;
  inherited;
  if (Marker <> nil) and Marker.Visible then
    Marker.Draw(Canvas, Marker.mX, Marker.mY, True);
end;

end.
