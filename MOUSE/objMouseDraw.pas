unit objMouseDraw;

interface uses objMouse, Collect, Windows, drawTwigs, Selector,
               Graphics, WpTwigs, WpArcs, WptForm2, Controls, Classes,
               objMouseSelect, SysUtils, varConsts, DlgAccuDraw,
               mpMarker, extCtrls, ecLot;

// корневой объект для отрисовки примитивов во время создания,
// редактирования, одиночного и группового выделения

const
 SysDrawPoint = 10010;
 SysDrawLine = 10011;
 SysDrawLine2 = 100111;
 SysDrawPoly = 10012;
 SysDrawSpline = 10013;
 SysDrawArc = 10014;
 SysDrawCircle = 10015;
 SysDrawRect = 10016;
 SysDrawParaLine = 10017;
 SysLine = 10018;
 sysDrawKvant = 10019;
 sysDrawMultiLine = 10020;
 sysDrawArc2 = 10021;
 sysDrawArc3 = 10022;
 em_MovePoint = 501;
// MergedOperations
 sysDrawRastr = 1;

type
 TMousePainter = class (TMouseSelector)
  private
    fOnCreateLine: TNotifyEvent;
   function GetHatchTwig(Index: Integer): TTwig;
  public
   X0,Y0:Double;
   fixLength:Double;
   fixAngle:Double;
   fixBlock:Double;
   fixKoef:Double;
   arcfixLength:Double;
   arcfixRadius:Double;
   circfixRadius:Double;
   Stvor_:TStvorLine;
   ftwigStyle:Integer;
   fixPoint1:TMarker;
   fixPoint2:TMarker;
   fixDistance:Double;
   objTmp:Pointer;
   fixTimer:TTimer;
   PathMarker:TPathMarker;
  //
   cirKvant:Integer;
  //
   timerNoStarting:Boolean;
  //
   isMultiline:Boolean;
   LockedMultiLine:Boolean;
   LastPrim:Pointer;
   MultiLot:TLot;
   MergedOpr:Integer;
   HatchLot:PCollection;
   Constructor Create(ATwigs:Pointer;AFreeProc:TFreeProc);override;
   Destructor Destroy;override;
   Procedure DrawTemp(Canvas:TCanvas;PaintOnImage:Boolean=False);override;
  //
   Function mpTwigVisible:Boolean;
   Procedure mpDrawTwig(Canvas:TCanvas);
   Procedure CreateTwig(TwigClass:TTwigClass=nil);
   Procedure CreateTwigAs(Twig_:TTwig);
 //
   Function isKeyDownCheck: boolean;virtual;
   Procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState;var Hook: boolean);override;
   Procedure MouseDown(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);override;
   Procedure MouseRightDown(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);override;
   Procedure mpCreatePrim(Form:TForm2;itsEndOfMultiLine:boolean = false);
   Procedure MouseUp(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);override;
   Procedure MouseMove(Form:TForm2; Shift: TShiftState;X, Y: Double; var Hook:boolean);override;
 //
   Procedure mpUpdateTwigPath(X,Y:Double); // создает сегмент или вставляет в него точку
   Procedure mpMoveTwigPath(X,Y:Double);
   Procedure Return(Sender:TObject);override;
   Procedure SetCur(CurName:String);override;
    function GetTwigStyle: Integer;
    procedure SetTwigStyle(const Value: Integer);
   Property twigStyle:Integer read GetTwigStyle write SetTwigStyle;
  //
   Function CanDoUndo:Boolean;override;
  //
   Procedure UpdateFixedPoints(X,Y:Double);
   Procedure DrawFixedPoints(Canvas:TCanvas);
   Procedure OnTimer(Sender:TObject);
   Procedure TimerOpen;override;
   Procedure TimerClose;override;
  //
   Procedure MakeHatchLot;
   Procedure DrawHatchLot(Canvas:TCanvas);
   Property HatchTwig[Index:Integer]:TTwig read GetHatchTwig;
   Property onCreateLine2:TNotifyEvent read fOnCreateLine write fOnCreateLine;
  end;

implementation uses Procs, GBFWUndo, EcDot,
                    DlgSelectLayer, Resource, InstParaLine,
                    maths_basic, ClassMak, DlgPropEditor, Dialogs,
                    InstPolygon, ustnGlobalSettings, Forms, Math,
                    RectLot, WpRects, WptBlock, WpForm0;

{ TMousePainter }

constructor TMousePainter.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
// Writeln('PainterCreate=',ClassName);
 inherited;
 mpTwig:=nil;
 If Assigned(GlobalAccuDraw) then GlobalAccuDraw.OnReturn:=Return;
 fixLength:=xyNull;
 arcfixLength:=xyNull;
 arcfixRadius:=xyNull;
 circfixRadius:=xyNull;
 fixKoef:=xyNull;
 fixAngle:=xyNull;
 Stvor_.X1:=xyNull;
 cirKvant:=Twigs.Settings.psArcCount;
 Case LOperation of
  sysDrawParaLine:begin
                   ParaLineForm:=TParaLineForm.Create(ApplicationMainForm);
                   ParaLineForm.OnReturn:=Return;
                   ParaLineForm.Execute2(Twigs);
                   twigStyle:=GReadInteger('ParaLineForm_lbHotSpot',0)+1000;
                    cirKvant:=Twigs.Settings.psArcCount;
                   ParaLineForm.Show;
                   mForms.Add(ParaLineForm);
                  end;
  sysDrawKvant:begin
                LayerPolygon:=TLayerPolygon.Create(ApplicationMainForm);
                LayerPolygon.OnReturn:=Return;
                 LayerPolygon.Execute2(Twigs);
                 cirKvant:=GReadInteger('LayerPolygon_SE',6);
                LayerPolygon.Show;
                mForms.Add(LayerPolygon);
               end;
 end;
 fixPoint1:=TMarker.Create(Twigs.HWndParent,mtRect,clBlue,8,2);
 fixPoint2:=TMarker.Create(Twigs.HWndParent,mtCross,clBlue,4,2);
 fixTimer:=TTimer.Create(nil);
 fixTimer.Interval:=500;
 fixTimer.OnTimer:=OnTimer;
 PathMarker:=TPathMarker.Create(0,0);
 MultiLot:=nil;
 HatchLot:=PCollection.Create(1);
{ unfixTimer:=TTimer.Create(nil);
 unfixTimer.Interval:=2000;
 unfixTimer.OnTimer:=OnTimer;}
end;

destructor TMousePainter.Destroy;
var I:Integer;
begin
 TimerClose;
 try
 Error:='0';
 inherited Destroy;
 If mpTwig<>nil then begin mpTwig.Twig:=nil;mpTwig.Free;mpTwig:=nil;end;
 Error:='1';
 If GlobalAccuDraw<>nil then GlobalAccuDraw.Hide;
 Error:='2';
 Error:='3';
 If ParaLineForm<>nil then begin ParaLineForm.Free;ParaLineForm:=nil;end;
 If LayerPolygon<>nil then begin LayerPolygon.Free;LayerPolygon:=nil;end;
 Error:='4';
 fixPoint1.Free;fixPoint2.Free;
 Error:='5';
 fixTimer.Free;
 PathMarker.Free;
 // удаляем ветки не вошедшие в MultiLot
 For I:=Twigs.Twigs.TwigsCount-1 downto 1 do If TTwig(Twigs.Twigs.TAt(I)).What = Twig_MultiLine then
  Twigs.Twigs.AtDelete(TWG_Twig,I);
 except
  MessageError('Отладчик : сообщение от '+ClassName+'. Шаг отладки :'+Error);
  If Assigned(FreeProc) then FreeProc;
  fixTimer.Free;
 { If Error='1' then  begin AccuDrawForm:=TAccuDrawForm.Create(ApplicationMainForm);
                           AccuDrawForm.OnReturn:=Return;
                     end;}
 end;
 HatchLot.Free;
// unfixTimer.Free;
end;

procedure TMousePainter.CreateTwig;
begin
 if mpTwig<>nil then mpTwig.Free;
 if TwigClass=nil then mpTwig:=TTwigPath.Create(TTwig) else mpTwig:=TTwigPath.Create(TwigClass);
end;

procedure TMousePainter.CreateTwigAs(Twig_: TTwig);
begin
 if mpTwig<>nil then mpTwig.Free;
 mpTwig:=TTwigPath.CreateAsTwig(Twig_);
end;

procedure TMousePainter.DrawTemp(Canvas: TCanvas;PaintOnImage:Boolean=False);
var Kvant:Integer;Pen:hPen;R2,Mode:Integer;
    I:Integer;
begin
 If Twigs.Settings.psSaveOrthoTwigs then OrthoTwigs.HideLines(GCanvas);
 if Marker.Visible then Marker.Draw(Canvas,Marker.mX,Marker.mY);
 Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant,
   sysDrawArc2,
   sysDrawArc3 :begin
                // OrthoTwigs.UpdateTwigs;OrthoTwigs.Draw(Canvas);
                 Kvant:=Quants_For_Arcs;
                 try
                  Quants_For_Arcs:=cirKvant;
                  If Twigs.Settings.psWidthPath then
                  Pen:=selectObject(Canvas.Handle,CreatePen(ps_Solid,2,winColor(clRed))) else
                  Pen:=selectObject(Canvas.Handle,CreatePen(ps_Dot,0,winColor(clRed)));
                  R2:=SetRop2(Canvas.Handle,R2_notXorPen);
                  Mode:=SetBkMode(Canvas.Handle,TransParent);
                  try
                   If MultiLot<>nil then
                    For I:=0 to MultiLot.Coord.Count-1 do TTwig(MultiLot.GetTwig(Twigs.Twigs,I)).Paint(Canvas.Handle);
                  finally DeleteObject(SelectObject(Canvas.Handle,Pen));SetRop2(Canvas.Handle,R2);SetBkMode(Canvas.Handle,Mode);end;
                  mpDrawTwig(Canvas);
                  DrawHatchLot(Canvas);
                 finally
                  Quants_For_Arcs:=Kvant;
                 end;
                end;
 end;
 DrawFixedPoints(Canvas);
end;

Function TMousePainter.isKeyDownCheck:boolean;
begin
 Result:=(mpTwig<> nil) or fixPoint1.Visible;
end;

procedure TMousePainter.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState;
  var Hook: boolean);
Function isNumericKey:boolean;
begin
 Result:=Key in [ord('0')..Ord('9'),190,96..105,107,187];
 If Key in [96..105] then Key:=Ord('0')+(Key-96);
 If Key = 110 then Key := 190;
 If Key = 107 then Key:=187;
end;
Procedure SetTwigStyle(Key:Word);               
begin
// If Key in [ord('Q'),ord('q'),ord('Й'),ord('й')] then twigStyle:=hsLeft else
 If Key in [ord('W'),ord('w'),ord('Ц'),ord('ц')] then twigStyle:=hsCenter else
// If Key in [ord('E'),ord('e'),ord('У'),ord('у')] then twigStyle:=hsRight;
end;
begin
 isNumericKey;
// Application.Hint:=IntToStr(Key);
 inherited;
 If Shift <> [] then exit;
 Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawCircle,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant  :If isKeyDownCheck then if isNumericKey or (Key in [ord('a'),ord('A'),ord('ф'),ord('Ф'),ord('d'),ord('D'),ord('в'),ord('В')]) then begin
                    If Key=190 then Key:=46;If (Key=187) then Key:=ord('+');
                    GlobalAccuDraw.ResetPrim(prim_Line,chr(Key));
                   end;                                                           
   sysDrawArc:If isKeyDownCheck then If isNumericKey then begin
               If Key=190 then Key:=46;
               If mpTwig=nil then GlobalAccuDraw.ResetPrim(prim_Line,chr(Key)) else begin
                If TTwigPathArc(mpTwig).CondArc=0 then GlobalAccuDraw.ResetPrim(prim_Line,chr(Key)) else
                                                    GlobalAccuDraw.ResetPrim(prim_Arc,chr(Key))
               end;
              end;
   sysDrawRect:If isKeyDownCheck then If isNumericKey then begin
                If Key = 190 then Key:=46;
                 GlobalAccuDraw.ResetPrim(prim_Rect,chr(Key));
               end;
   em_ObjectMove,
   em_MoveObjectPoints,
   em_ObjectRotate,
   em_Copy,
   em_Scale:begin
                   If isNumericKey or (Key in [ord('a'),ord('A'),ord('ф'),ord('Ф')]) then begin
                     If Key = 190 then Key:=46;
                     GlobalAccuDraw.ResetPrim(prim_Line,chr(Key));
                    end else
                    if (LOperation = em_Scale) and (Key in [ord('k'),ord('K'),ord('Л'),ord('л'),190,110]) then begin
                     If Key = 190 then Key:=46;
                     GlobalAccuDraw.ResetPrim(prim_Koef,chr(Key));
                    end;
                    if (LOperation = em_ObjectMove) and (Key in [ord('k'),ord('K'),ord('Л'),ord('л'),190,110]) then begin
                     If Key = 190 then Key:=46;
                     GlobalAccuDraw.ResetPrim(prim_Coord,chr(Key));
                    end;
                   end;
   em_MovePoint:begin
                   if isNumericKey or (Key in [ord('a'),ord('A'),ord('ф'),ord('Ф'),ord('.')]) then begin
                    If (Key in [190,110]) then Key:=46;
                    GlobalAccuDraw.ResetPrim(prim_Line,chr(Key));
                   end;
                 end;
 end;
 If Key in [ord('Q'),ord('q'),ord('W'),ord('w'),ord('E'),ord('e'),ord('Й'),ord('й'),ord('Ц'),ord('ц'),ord('У'),ord('у')] then
  If LOperation = sysDrawParaLine then begin
   SetTwigStyle(Key);
  end;
 If Key in [ord('Z'),ord('z'),ord('Я'),ord('я')] then TimerClose;
 If (Key in [ord('X'),ord('x'),ord('Ч'),ord('ч')])and(Shift = []) then begin
  //TimerOpen;
  If (Marker.Visible) then begin
   TimerClose;
   TemporaryDot.What:=tdUsed;
  // TemporaryDot.XDot:=Marker.mX;TemporaryDot.YDot:=Marker.mY;
   OrthoTwigs.addAngle:=Pi*2 - addAngle;
   OnTimer(nil);
  //OrthoTwigs.Draw(GCanvas,True);
//   readln;
  end;
 end;
end;

procedure TMousePainter.MouseDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
var P:PCollection;B:Boolean;
begin
 inherited MouseDown(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 if Button=mbRight then Exit;
 Hook:=True;
// Writeln('MouseDown=',X,' ',Y,' ', LOperation);
{}
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant   :begin
                    if fixPoint1.Visible then begin
                     X0:=fixPoint2.mX;Y0:=fixPoint2.mY;
                    end;// else begin X0:=X;Y0:=Y;end;
                    B:=False;
                    If (paraLineForm<>nil) then
                      B:=paraLineForm.sbHatch.Down;
                    mpUpdateTwigPath(X0,Y0);
                    {
                    If B then
                     If (ObjTemporary<>nil) then If (objTemporary is TTwig) then
                      If TTwig(objTemporary).Properties<>nil then
                       If TTwig(objTemporary).Properties.PropValue['Ширина']<>nil then
                        If paraLineForm<>nil then begin
                         paraLineForm.SetWidth(TTwig(objTemporary).Properties.PropValue['Ширина'].asFloat);
                        end;
                     }
                    {
                    If (ObjTemporary<>nil) then If (objTemporary is TTwig) then If mpTwig<>nil then begin
                     If mpTwig.Count=1 then
                      mpTwig.interFirst:=TTwig(objTemporary);
                    end;
                    }
//                     P:=PCollection.Create(1);
//                     Writeln('FindTwigs=',Twigs.FindTwigs(X0,Y0,P));
//                     P.DeleteAll;P.Free;
                   end;
  sysDrawArc2,
  sysDrawArc3:begin
               if fixPoint1.Visible then begin
                X0:=fixPoint2.mX;Y0:=fixPoint2.mY;
               end;// else begin X0:=X;Y0:=Y;end;
               If mpTwig=nil then mpUpdateTwigPath(X0,Y0) else begin
                 If TTwigPathArc(mpTwig).CondArc<2 then mpUpdateTwigPath(X0,Y0) else begin
                  If mpTwig.Twig is TTwigArc then begin
                   B:=Distance(X,Y,TTwigArc(mpTwig.Twig).A.XDot,TTwigArc(mpTwig.Twig).A.YDot)<Distance(X,Y,TTwigArc(mpTwig.Twig).B.XDot,TTwigArc(mpTwig.Twig).B.YDot);
                   If B then xyACB:=TTwigArc(mpTwig.Twig).A else xyACB:=TTwigArc(mpTwig.Twig).B;
                  end;
                   mpCreatePrim(Form);
                   mpUpdateTwigPath(X0,Y0);
                 end
               end;  
              end;
  end;
end;

procedure TMousePainter.MouseMove(Form: TForm2; Shift: TShiftState; X,
  Y: Double; var Hook: boolean);
var Kvant:Integer;
begin
 inherited MouseMove(Form,Shift,X,Y,Hook);
 if ShiftPress or ControlPresS then begin Hook:=False;Exit;end;
 Hook:=True;
 SetCur('');
{}
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant,
   sysDrawArc2,
   sysDrawArc3    :begin
                    Kvant:=Quants_For_Arcs;
                    try
                     Quants_For_Arcs:=cirKvant;
                     DrawFixedPoints(GCanvas);
                     If mpTwig<>nil then begin
                      X0:=X;Y0:=Y;
                      if Twigs.Settings.psAuto then emGetDotMarker(X0,Y0,mpTwig.FirstPoint,mpTwig.mpStvor,objTemporary,True,True,True);
                      mpMoveTwigPath(X0,Y0);
                      If fixPoint1.Visible then begin fixPoint2.mX:=X0;fixPoint2.mY:=Y0;end;
                     end else begin
                      Stvor_.X1:=xyNull;
                      if Twigs.Settings.psAuto then emGetDotMarker(X,Y,nil,Stvor_,objTemporary,True,True,True);
                      X0:=X;Y0:=Y;
                      If fixPoint1.Visible then begin fixPoint2.mX:=X0;fixPoint2.mY:=Y0;end;
                     end;
 //                     Writeln('1===',fixPoint2.mX,' ',fixPoint2.mY);
                     UpdateFixedPoints(fixPoint2.mX,fixPoint2.mY);
 //                     Writeln('2===',fixPoint2.mX,' ',fixPoint2.mY);
                     DrawFixedPoints(GCanvas);
                    finally
                     Quants_For_Arcs:=Kvant;
                    end;
                   end;
  end;
end;

procedure TMousePainter.MouseRightDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
var I:Integer;D1,D2:TDot;PD:TPointDot;
    DrawTwig:TTwig;Lot,twLot:TLot;
    R1:TRect;
    Layer,Layer1:TResource;
    SavedTwig:TTwigPath;
    QLD:Boolean;
    Tw:TTwig;
    CountTwig,CountLot,Kvant:Integer;
    B:Boolean;
    Block:TGeoBlock;
    GUID:TGUID;
    XBl,YBl:Double;
begin
 inherited MouseRightDown(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 Hook:=True;
{}
  Case LOperation of
   sysDrawPoint:If mpTwig<>nil then begin
                  SelectLayerForm:=TSelectLayerForm.Create(ApplicationMainForm);
                  If Twigs.Settings.psQueryLayerDraw then Layer:=SelectLayerForm.Execute('Выбор слоя для точечного объекта...',Form.LayerTable) else
                                                          Layer:=Twigs.LayerTable.ActiveLayer;
                  try
                   If Layer<>nil then begin
                    If Twigs.Settings.psQueryLayerDraw then If SelectLayerForm.SetActive then Form.LayerTable.ActiveLayer:=Layer;
                     Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_CreatePoint'));
                     For I:=0 to mpTwig.Count-1 do begin
                      D1:=mpTwig.Coord[I];
                     {$IFDEF GEOBUILDER}
                      PD:=TPointDot.CreateTaheo(Form.LayerTable.ActiveLayer,-1,'',D1.XDot,D1.YDot,ZNull);
                      PD.Symbol:=Form.LayerTable.ActiveSymbology;
                     {$ELSE}
                      PD:=TPointDot.CreateTaheo(Layer,-1,'',D1.XDot,D1.YDot,ZNull);
                     {$ENDIF}
                      If OnAddPrim(PD) then begin
                       PropEditorForm.SetEnumProperties(PD);
                       Twigs.Twigs.Insert(TWG_Point,PD);
                       TPrimUndo(Undo.Last).AddModifiedPrim(PD);
                      end else PD.Free;
                     end;
                     OrthoTwigs.Pack('');
                     mpTwig.Free;mpTwig:=nil;
                     Marker.Remove(GCanvas);
                     Form.ClassBuildII;
                     TimerClose;
                     Modified;
                     UpdateImage;
                  end; // If Layer<>nil
                  finally SelectLayerForm.Free; end;
                end;
   sysDrawLine,sysDrawLine2,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysLine,
   sysDrawKvant,
   sysDrawArc2,
   sysDrawArc3  :begin
                  //If LOperation = sysDrawArc3 then
                  { If mpTwig<>nil then
                    If mpTwig.Twig is TTwigArc then begin
                     B:=Distance(X,Y,TTwigArc(mpTwig.Twig).A.XDot,TTwigArc(mpTwig.Twig).A.YDot)<Distance(X,Y,TTwigArc(mpTwig.Twig).B.XDot,TTwigArc(mpTwig.Twig).B.YDot);
                     If B then xyACB:=TTwigArc(mpTwig.Twig).A else xyACB:=TTwigArc(mpTwig.Twig).B;
                    end;}
                   If (isMultiLine)and(not LockedMultiLine) then begin
                    If LOperation = sysDrawArc3 then begin

                    end;
                    PopupMenuPopup(X,Y);
                   // LockedMultiLine:=True;
                    exit;
                   end else begin
                   If (LOperation = sysDrawLine2) and (PopUpMenu<>nil) then begin
                    PopupMenuPopup(X,Y);
                   end else
                    mpCreatePrim(Form);
                   end;
                  end;
   sysDrawParaLine: If mpTwig = nil then begin
                     // ищем сегмент, устанавливаем автоширину паралинии
                     If (ObjTemporary<>nil) then If (objTemporary is TTwig) then
                      If TTwig(objTemporary).Properties<>nil then
                       If TTwig(objTemporary).Properties.PropValue['Ширина']<>nil then
                        If paraLineForm<>nil then begin
                         paraLineForm.SetWidth(TTwig(objTemporary).Properties.PropValue['Ширина'].asFloat);
                        end;
                    end else
                    If mpTwig<>nil then If mpTwig.Count>1 then With Twigs do try
                    SelectLayerForm:=TSelectLayerForm.Create(ApplicationMainForm);
                    If Settings.psQueryLayerDraw then Layer:=SelectLayerForm.Execute('Выбор слоя линейного/площадного объекта...',Form.LayerTable) else
                                                      Layer:=LayerTable.ActiveLayer;
                    RMouseDown:=False;
                    If Layer<>nil then
                     If Settings.psQueryLayerDraw then If SelectLayerForm.SetActive then Form.LayerTable.ActiveLayer:=Layer;
                    SelectLayerForm.Free;
                    QLD:=Form.Settings.psQueryLayerDraw;
                    Form.Settings.psQueryLayerDraw:=False;
                    SavedTwig:=mpTwig;mpTwig:=TTwigPath.Create(TTwig);mpTwig.Twig:=TTwigParaLine(SavedTwig).TwigL;
                    LOperation:=sysDrawLine;
                    X0:=SavedTwig.FirstPoint.XDot;Y0:=SavedTwig.FirstPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interFirst:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interFirst:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    X0:=SavedTwig.LastPoint.XDot;Y0:=SavedTwig.LastPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interSecond:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interSecond:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    mpTwig.Twig.SetProperty('Ширина',FloatToStr(SavedTwig.Width));//!!!!!
                   // если чертим параллельные - рисуем первую линию, если штриховку - не рисуем
                     MouseRightDown(Form,Button,Shift,X,Y,Hook);
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=0;
                   //
                    X0:=SavedTwig.FirstPoint.XDot;Y0:=SavedTwig.FirstPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interFirst:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interFirst:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    X0:=SavedTwig.LastPoint.XDot;Y0:=SavedTwig.LastPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interSecond:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interSecond:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    if not ((ParaLineForm.sbHatch.Down)or(ParaLineForm.sbStroke.Down)or(ParaLineForm.sbSolid.Down)or(ParaLineForm.sbIDN.Down)) then TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=1;
                   // добавляем mpTwig.Rects
                     mpTwig:=TTwigPath.Create(TTwig);mpTwig.Twig:=TTwigParaLine(SavedTwig).TwigR;
                    mpTwig.Twig.SetProperty('Ширина',FloatToStr(SavedTwig.Width));
                    twLot:=nil;
                   Self.Undo.StartTransAction;
                   try
                    B:=False;
                    // создаем блок -> добавляем в него новые примитивы
                    //Block:=TGeoBlock.Create(Form,nil);
                    For I:=0 to TTwigParaLine(SavedTwig).Rects.Count-1 do With Self.Twigs do begin
                    {}
                     If ParaLineForm.sbHatch.Down then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка ИДН');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If ParaLineForm.sbStroke.Down then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка прерывистая');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If ParaLineForm.sbSolid.Down then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка сплошная желтая');
                      Layer.RGB.ARGB[1]:=GetRValue(clYellow);Layer.RGB.ARGB[2]:=GetGValue(clYellow);Layer.RGB.ARGB[3]:=GetBValue(clYellow);
                      Layer:=LayerTable.AddExistSysLayer('Разметка сплошная');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If ParaLineForm.sbIDN.Down then begin
                      {If I>2 then begin
                       Layer:=LayerTable.AddExistSysLayer('ИДН желтая краска');
                       Layer.RGB.ARGB[1]:=GetRValue(clYellow);Layer.RGB.ARGB[2]:=GetGValue(clYellow);Layer.RGB.ARGB[3]:=GetBValue(clYellow);
                      end else} begin
                       Layer:=LayerTable.AddExistSysLayer('ИДН');
                       Layer.RGB.ARGB[1]:=40;Layer.RGB.ARGB[2]:=40;Layer.RGB.ARGB[3]:=40;
                      end;
                     end;
                     If I=0 then begin
//                      twLot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур из всех сегментов Rects
//                      twLot.TypeLot:=1;
                     end;
                    {}
                     Twigs.Insert(TWG_Twig,TTwigParaLine(SavedTwig).Rects[I]);
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=1;
                     If I=0 then begin
                      XBl:=TTwig(Twigs.TAt(Twigs.TwigsCount-1))[0].XDot;YBl:=TTwig(Twigs.TAt(Twigs.TwigsCount-1))[0].YDot;
                     end;
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).SetMinMax;
                     Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                     If (ParaLineForm.sbIDN.Down)and(I>2) then Lot.SetProperty('Цвет заливки',IntToStr(clYellow));
                     Lot.SetProperty('Тип линии','-1');
                    // Lot.SetProperty('Цвет',IntToStr(Rgb(1,100,1)));
                    // Lot.SetProperty('Цвет заливки',IntToStr(Rgb(1,,1)));
                     Lot.Insert(Twigs.TwigsCount-1);
                     Lot.SetMinMax(Twigs);
                    // twLot.Insert(Twigs.TwigsCount-1);
                    // twLot.SetMinMax(Twigs);
                     Twigs.Insert(TWG_Lot,Lot);
                     TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'UndoAddNewPointBlock...em_SetBlock'))).AddModifiedPrim(Lot);
//                     twLot.Insert(Twigs.TwigsCount-1);
                    {With Block do begin
                     TwgForm.SetGabaritesPrivate;
                     With TwgForm,blockRect do begin Left:=XXMin;Top:=YYMin;Right:=XXMax;Bottom:=YYMax;
                      Block.X:=XBl-XXMin;//(XXMin+XXMax)/2;
                      Block.Y:=YBl-YYMin;//(YYMin+YYMax)/2;
                      //Writeln(XXMin:8:2,' ',YYMin:8:2,' ',XXMax:8:2,' ',YYMax:8:2);
                     end;
                    }
                    end;
                    ClassBuildII;
                    CreateGUID(GUID);
                   {                                        `
                    Block.Name:=GUIDToString(GUID);
                    Twigs.Insert(TWG_Block,Block);
                   // создаем точку с блоком
                     PD:=TPointDot.Create(XBl,YBl,0);
                     PD.userObj:=Block;
                     PD.Code:=Self.Twigs.LayerTable.ActiveLayer.ID;
                     PD.ClassHandle:=Self.Twigs.LayerTable.ActiveLayer;
                     PD.XKoef:=1;PD.YKoef:=1;
                    //
                     TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'UndoAddNewPointBlock...em_SetBlock'))).AddModifiedPrim(PD);
                     Twigs.Insert(TWG_Point,PD);
                   //
                    }
                     B:=True;
                   finally
                    If B then Self.Undo.Commit else Self.Undo.RollBack;
                   end;
                   // если чертим параллельные - рисуем первую линию, если штриховку - не рисуем
                   // if twLot<>nil then Twigs.Insert(TWG_Lot,twLot);
                    TTwigParaLine(SavedTwig).Rects.DeleteAll;
                  // если чертим параллельные - рисуем вторую линию, если штриховку - не рисуем
                     MouseRightDown(Form,Button,Shift,X,Y,Hook);
                   finally
                    LOperation:=sysDrawParaLine;
                    Form.Settings.psQueryLayerDraw:=QLD;
                   end;
  end;
end;

procedure TMousePainter.mpCreatePrim(Form:TForm2;itsEndOfMultiLine:boolean = False);
var DrawTwig,RectTwig:TTwig;Lot:TLot;
    R1:TRect;
    Layer:TResource;
    SavedTwig:TTwigPath;
    QLD:Boolean;
    Tw:TTwig;
    CountTwig,CountLot,Kvant:Integer;
    I,M,Index:Integer;D1,D2:TDot;PD:TPointDot;
Procedure CreateLotArcTwig;
var M:Integer;
begin
If Twigs.Settings.psLineArc then
 For M:=0 to Lot.Coord.Count-1 do begin
  Tw:=Lot.GetTwig(Twigs.Twigs,M);
  If Tw is TTwigArc then begin
   Index:=Twigs.Twigs.TwigsLarge.IndexOf(Tw);
   TTwigArc(Tw).ArcView:=1;
   Tw:=TTwig.CreateAsTwig(Tw,True);
   Twigs.Twigs.TwigsLarge.AtPut(Index,Tw);
  end;
 end;
end;
begin
LastPrim:=nil;
If mpTwig<>nil then With Twigs do begin
                   If LOperation = sysDrawArc3 then begin
                   If mpTwig is TTwigPathArc then begin
                    If TTwigPathArc(mpTwig).CondArc = 1 then begin
                     MessageError('Закончите построение дуги...');
                    LockedMultiLine:=False;
                    exit;
                    end;
                   end;
                   end;
                   If mpTwig.Count<2 then begin
                    If LOperation=sysDrawLine then MessageError('Укажите как минимум 2 точки');
                    If LOperation=sysDrawPoly then MessageError('Укажите как минимум 3 точки');
                    If LOperation=sysDrawSpline then MessageError('Укажите как минимум 3 точки');
                    LockedMultiLine:=False;
                    exit;
                   end else
                    If LOperation=sysDrawPoly then If mpTwig.Count<3 then begin
                     MessageError('Укажите как минимум 3 точки');
                     LockedMultiLine:=False;
                     exit;
                    end;
                     If (not isMultiLine)or(itsEndOfMultiLine) then Self.Undo.StartTransAction;
                     try
                    // разбиваем сегменты, если сработало автопритягивание
                    If LOperation = sysDrawKvant then begin
                     Kvant:=Quants_For_Arcs;
                      Quants_For_Arcs:=cirKvant;
                     try
                      mpTwig.Twig.ArcView:=1;mpTwig.Twig.Calculate;
                      DrawTwig:=TTwig.CreateAsTwig(mpTwig.Twig,True);DrawTwig.Closed:=1;
                      DrawTwig.Calculate;
                      mpTwig.Twig.Free;
                     finally Quants_For_Arcs:=Kvant;end;
                    end else begin
                     DrawTwig:=mpTwig.Twig;DrawTwig.Closed:=1;
                     DrawTwig.Calculate;
                    end;
                    //Writeln('CC=',DrawTwig.Coord.Count);
                   // try DrawTwig.Calculate;except exit; end;
                    If (LOperation<>sysDrawKvant) and (LOperation<>sysDrawCircle) and (LOperation<>sysDrawRect) then
                    If (Settings.psAuto)and(Settings.psInsert or Settings.psTwise) then begin
                      emInsertPointInTwig(mpTwig.FirstPoint.XDot,mpTwig.FirstPoint.YDot,nil,nil);
                      emInsertPointInTwig(mpTwig.LastPoint.XDot,mpTwig.LastPoint.YDot,nil,nil);
                    end;
                  // запрашиваем слой
                    If Settings.psQueryLayerDraw then SelectLayerForm:=TSelectLayerForm.Create(ApplicationMainForm);
                    If Settings.psQueryLayerDraw then Layer:=SelectLayerForm.Execute('Выбор слоя линейного/площадного объекта...',Form.LayerTable) else
                                                      Layer:=LayerTable.ActiveLayer;
                    If LOperation = sysDrawLine2 then Layer:=LayerTable.AddExistSysLayer('Линия раздела');
                    RMouseDown:=False;
                   If Layer<>nil then try
                     If Settings.psQueryLayerDraw then If SelectLayerForm.SetActive then Form.LayerTable.ActiveLayer:=Layer;
                   {$IFDEF GEOBUILDER}
                     Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                    // Lot.Insert(Twigs.TwigsCount-1);
                      If LOperation=sysDrawPoly then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                      Lot.Symbol:=LayerTable.ActiveSymbology;
                   {$ELSE}
                      If isMultiLine then begin
                       If MultiLot=nil then begin
                        Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                        PropEditorForm.SetEnumProperties(Lot);
                        If (LOperation=sysDrawPoly) {or (LOperation=sysDrawRect)} then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                       end else Lot:=MultiLot;
                      end else begin
                       // создание контура по MergedOpr
                       Case MergedOpr of
                        sysDrawRastr:Lot:=TRectLot.Create(Layer);
                       else
                        Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                       end;
                       PropEditorForm.SetEnumProperties(Lot);
                       If (LOperation=sysDrawPoly) {or (LOperation=sysDrawRect)} then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                        If LOperation = sysDrawLine2 then begin
                         Lot.SetProperty('Цвет',IntToStr(clRed));Lot.SetProperty('Толщина','0.5');
                        end;
                      end;
                   {$ENDIF}
                       If Lot.TypeLot=2 then begin
                        DrawTwig.Insert(TDot.CreateAsDot(DrawTwig[0]));
                       end;
                      If LOperation<>sysLine then begin
                       Case MergedOpr of
                        sysDrawRastr:begin
                                      RectTwig:=TTwigRect.CreateAsTwig(DrawTwig,True);
                                      DrawTwig.Free;DrawTwig:=RectTwig;
                                     end;
                       end;
                       If paraLineForm=nil then begin
                        Twigs.Insert(Twg_Twig,DrawTwig);
                        DrawTwig.SetMinMax;
                        Lot.Insert(Twigs.TwigsCount-1);
                        Lot.SetMinMax(Twigs);
                        Lot.NLot:=10000000;
                        If (Operation = sysDrawLine2) and Assigned(OnCreateLine2) then begin
                         LMouseDown := False;
                         RMouseDown := False;
                         onCreateLine2(Lot);exit;
                        end;
                       end else                         
                       If not ((ParaLineForm.sbHatch.Down)or(ParaLineForm.sbStroke.Down)or(ParaLineForm.sbSolid.Down)or(ParaLineForm.sbIDN.Down)) then begin
                        Twigs.Insert(Twg_Twig,DrawTwig);
                        DrawTwig.SetMinMax;
                        Lot.Insert(Twigs.TwigsCount-1);
                        Lot.SetMinMax(Twigs);
                       end;
                      end else begin
                       CountTwig:=Twigs.TwigsCount;CountLot:=Twigs.LotsCount;
                       For I:=0 to DrawTwig.Coord.Count-2 do begin
                        D1:=DrawTwig[I];D2:=DrawTwig[I+1];
                        Tw:=TTwig.Create(0);Tw.Insert(TDot.CreateAsDot(D1));Tw.Insert(TDot.CreateAsDot(D2));
                        Tw.SetMinMax;
                        Twigs.Insert(TWG_Twig,Tw);
                        If I<>0 then begin
                         Lot:=TLot.Create(Layer.ID,Layer,1);Lot.TypeLot:=1;
                         PropEditorForm.SetEnumProperties(Lot);
                        end;
                        Lot.Insert(Twigs.TwigsCount-1);Lot.SetMinMax(Twigs);
                        If OnAddPrim(Lot) then begin
                         Twigs.Insert(Twg_Lot,Lot);
                         TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                        end else begin
                         Twigs.AtDelete(TWG_Lot,Twigs.LotsCount-1);
                         Lot.Free;
                         Lot:=nil;
                        end;
                       end;
                       DrawTwig.Coord.DeleteAll;DrawTwig.Free;
                      end;
                      If LOperation<>sysLine then begin
                       If OnAddPrim(Lot) then begin
                         If isMultiLine then begin If MultiLot<>nil then begin
                          If itsEndOfMultiLine then begin
                           Twigs.Insert(Twg_Lot,Lot);
                           // делаем из дуг точки
                           CreateLotArcTwig;
                           TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                          end;
                         end else begin
                          If itsEndOfMultiLine then begin
                           Twigs.Insert(Twg_Lot,Lot);
                           // делаем из дуг точки
                           CreateLotArcTwig;
                           TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                          end;
                          MultiLot:=Lot;
                         end;
                         MultiLot.SetMinMax(Form.Twigs);
                        end else begin
                         Twigs.Insert(Twg_Lot,Lot);
                         // делаем из дуг точки
                           CreateLotArcTwig;
                         TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                       end;
                      end else begin
                       Twigs.AtDelete(TWG_Lot,Twigs.LotsCount-1);
                       Lot.Free;Lot:=nil;
                      end;
                     end;
                    If Lot<>nil then If Lot.TypeLot = 2 then Lot.SetSqwear(Twigs);
                    Modified;
                    LockedMultiLine:=False;
                   finally
                      If Settings.psQueryLayerDraw then SelectLayerForm.Free;
                      ClassRebuildIndex:=True;
                      ClassBuildII;
                      Marker.Remove(GCanvas);
                      OrthoTwigs.Pack('');
                      If isMultiLine then begin
                       If itsEndOfMultiLine then begin
                        For I:=0 to MultiLot.Coord.Count-1 do MultiLot.GetTwig(Twigs,I).What:=0;
                       end else
                       If mpTwig.Twig<>nil then mpTwig.Twig.What:=Twig_MultiLine;
                      end;
                      mpTwig.Twig:=nil;mpTwig.Free;mpTwig:=nil;
                      OrthoTwigs.Free;OrthoTwigs:=TOrthoTwigs.Create;
                      TimerClose;
                   end;
                     If (not isMultiLine) or(itsEndOfMultiLine) then Self.Undo.Commit;
                    LastPrim:=Form.Twigs.TAt(Form.Twigs.TwigsCount-1);
                    If Assigned(OnCreateLine2) then begin
                     LMouseDown := False;
                     RMouseDown := False;
                     onCreateLine2(Lot);exit;
                    end;
                    except
                      _ShowMessage('objMouseDraw '+IntToStr(481));
                      If (not isMultiLine)or(itsEndOfMultiLine) then Self.Undo.RollBack;
                     end;
                 end;
end;

procedure TMousePainter.MouseUp(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited MouseUp(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 Hook:=True;
end;

procedure TMousePainter.mpDrawTwig(Canvas: TCanvas);
var I:Integer;
begin
 If mpTwig<>nil then begin
  mpTwig.TwigVisible:=False;
  try
   mpTwig.Move(Canvas,X0,Y0);mpTwig.Calculate;
//   PSetPixel(X0,Y0);
  except _ShowMEssage('objMouseDraw '+IntToStr(551));end;
  If mpTwig.Marker.Visible then mpTwig.Marker.Draw(Canvas,mpTwig.Marker.mx,mpTwig.Marker.mY);
 // if Canvas<>GImage.Canvas then mpTwig.Draw(GImage.Canvas);
 end;
end;

function TMousePainter.mpTwigVisible: Boolean;
begin
 Result:=False;
 if mpTwig<>nil then Result:=mpTwig.TwigVisible;
end;

procedure TMousePainter.mpUpdateTwigPath(X, Y: Double);
var AR:TArcRecord;CR:TCircRecord;
begin
try
 If mpTwig=nil then begin
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysLine    :begin
                mpTwig:=TTwigPath.Create(TTwig);
                mpTwig.fixLength:=fixLength;
                mpTwig.fixAngle:=fixAngle;
                mpTwig.AddPoint(GCanvas,X,Y);
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawSpline:begin
                  mpTwig:=TTwigPath.Create(TTwigSpline);
                  mpTwig.fixLength:=fixLength;
                  mpTwig.AddPoint(GCanvas,X,Y);
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawArc:begin
               AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
               mpTwig:=TTwigPathArc.Create(TTwigArc,AR);
               AR.Free;
               mpTwig.fixLength:=arcfixLength;
               fixPoint1.Remove(GCanvas);
              end;
   sysDrawArc2:begin
                AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR);
                AR.Free;
                mpTwig.AddPoint(GCanvas,X,Y);
                mpTwig.fixLength:=arcfixLength;
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawArc3:begin
                AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
                If (MultiLot<>nil) and (MultiLot.Coord.Count>0) then
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR,MultiLot.GetTwig(Twigs.Twigs,MultiLot.Coord.Count-1)) else
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR);
                AR.Free;
                mpTwig.AddPoint(GCanvas,X,Y);
                mpTwig.fixLength:=arcfixLength;
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawCircle:begin
                  CR:=TCircRecord.Create(X,Y,X+2,Y+2);
                  mpTwig:=TTwigPath.Create(TTwigCircle,CR);
                  CR.Free;
                  mpTwig.fixLength:=circfixRadius;
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawKvant :begin
                  CR:=TCircRecord.Create(X,Y,X+2,Y+2);
                  mpTwig:=TTwigPathKvant.Create(TTwigCircle,CR,X,Y);
                  mpTwig.twigStyle:=1;
                  mpTwig.cirKvant:=cirKvant;
                  mpTwig.twigStyle:=LayerPolygon.TwigStyle;
                  CR.Free;
                  mpTwig.fixLength:=circfixRadius;
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawRect:begin
                  mpTwig:=TTwigPathRect.Create(TTwig);
                  mpTwig.fixLength:=fixLength;
                  mpTwig.AddPoint(GCanvas,X,Y);
                  fixPoint1.Remove(GCanvas);
               end;
   sysDrawParaLine:begin
                    mpTwig:=TTwigParaLine.Create(TTwig);
                    mpTwig.fixLength:=fixLength;
                    mpTwig.Width:=ParaLineForm.Width;
                    mpTwig.twigStyle:=twigStyle;
                    mpTwig.AddPoint(GCanvas,X,Y);
                    fixPoint1.Remove(GCanvas);
                   end else begin
                    mpTwig:=TTwigPath.Create(TTwig);
                    mpTwig.AddPoint(GCanvas,X,Y);
                    fixPoint1.Remove(GCanvas);
                   end;
  end;
  If (mpTwig<>nil) and (LOperation<>sysDrawRect)and(LOperation<>sysDrawPoint){and(LOperation<>sysDrawCircle)
   and(LOperation<>sysDrawKvant)} then begin
   mpTwig.addAngle:=addAngle;
   OrthoTwigs.Add(mpTwig.Twig,'');
  end;
 end else begin
 // OrthoTwigs.Draw(GCanvas);
  mpTwig.AddPoint(GCanvas,X,Y);
   OrthoTwigs.UpdateTwigs;OrthoTwigs.Draw(GCanvas);
  mpDrawTwig(GCanvas);
  fixPoint1.Remove(GCanvas);
//  UpdateImage;
 end;
 except _ShowMessage('objMouseDraw '+intToStr(636));end;
end;

procedure TMousePainter.mpMoveTwigPath(X, Y: Double);
var Dot:TDot;
begin
 if mpTwig<>nil then begin
  mpTwig.Move(GCanvas,X,Y);
  X0:=mpTwig.mX;
  Y0:=mpTwig.mY;
  Dot:=mpTwig[mpTwig.Twig.Coord.Count-1];
  Application.Hint:='#L='+FloatToStrF(Distance(Dot.XDot,Dot.YDot,X0,Y0),ffFixed,_LD,Const_Of_DecimalLength);
 end;
end;

procedure TMousePainter.Return(Sender: TObject);
var Hook:Boolean;CRect:Integer;Kvant:Integer;
Function GetIncrementDistance:Double;
var I:Integer;Angle,prevAngle:Double;
    D1,D2:TDot;
begin
 Result:=0;
 If mpTwig.Count>1 then
 If GlobalAccuDraw.useIncrementDistance then begin
//  Angle:=Direct_Angle(mpTwig.LastPoint.XDot,mpTwig.LastPoint.YDot,mpTwig.mX,mpTwig.mY);
  For I:=mpTwig.Twig.Coord.Count-1 downTo 1  do begin
   D1:=mpTwig.Twig[I];D2:=mpTwig.Twig[I-1];
   prevAngle:=Direct_Angle(D2.XDot,D2.YDot,D1.XDot,D1.YDot)-Pi/2;
   If I=mpTwig.Twig.Coord.Count-1 then Angle:=prevAngle;
   mpTwig.SaveAngle:=mpTwig.fixAngle;mpTwig.fixAngle:=Angle*180/Pi;
   If Round(prevAngle) = Round(Angle) then Result:=Result+Distance(D1.XDot,D1.YDot,D2.XDot,D2.YDot) else exit;
  end;
 end;
end;
begin
 Case TComponent(Sender).Tag of
  -1:begin
      fixDistance:=xyNull;
      fixAngle:=xyNull;
      fixLength:=xyNull;
      arcFixLength:=xyNull;
      UpdateFixedPoints(fixPoint2.mX,fixpoint2.mY);
      if mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
      if mpTwig<>nil then mpTwig.SetAngle(GCanvas,fixAngle,False);
      UpdateImage;
     end;
  1,2,3:begin
         // если Distance = xyNull тогда режим фиксации длины отключен
         If fixPoint1.Visible then begin
          fixDistance:=GlobalAccuDraw.Distance;
          UpdateFixedPoints(fixPoint2.mX,fixpoint2.mY);
          SetFocus(Twigs.hWndParent);
          If fixDistance<>xyNull then begin
           If fixPoint1.markermoveStyle = 0 then begin
            MouseDown(Twigs,mbLeft,[],fixPoint2.mX,fixpoint2.mY,Hook);
            MouseUp(Twigs,mbLeft,[],fixPoint2.mX,fixpoint2.mY,Hook);
            GlobalAccuDraw.C1.Checked:=False;fixDistance:=xyNull;
            UpdateImage;
           end else begin
            TimerClose;
            TemporaryDot.What:=tdUsed;
            TemporaryDot.XDot:=fixPoint2.mX;TemporaryDot.YDot:=fixPoint2.mY;
            OrthoTwigs.addAngle:=Pi*2 - addAngle;
            OnTimer(Self);
           end;
          end;
          exit;
         end;
         fixLength:=GlobalAccuDraw.Distance;
         if (mpTwig<>nil)and(fixLength<>xyNull) then begin
          if fixLength-GetIncrementDistance<=0 then begin
           MessageInform('Расстояние задано неверно');
           GlobalAccuDraw.C1.Checked:=False;
           GlobalAccuDraw.CA.Checked:=False;
           mpTwig.fixAngle:=xyNull;
           fixLength:=xyNull;
           exit;
          end;
          If GlobalAccuDraw.useIncrementDistance then begin
          // Writeln(fixLength:8:2,' ',GetIncrementDistance:8:2);
           mpTwig.SetIncrementalLength(GCanvas,fixLength-GetIncrementDistance)
          end else
           mpTwig.SetLength(GCanvas,fixLength-GetIncrementDistance);
          If (LOperation = sysDrawCircle)or(LOperation = sysDrawKvant) then begin
           //If mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
           mpTwig.fixAngle:=xyNull;
           fixLength:=xyNull;
           OrthoTwigs.UpdateTwigs;
            MouseDown(Twigs,mbRight,[],mpTwig.mX,mpTwig.mY,Hook);
            MouseUp(Twigs,mbRight,[],0,0,Hook);
           exit;
          end else
          If LOperation = sysDrawRect then CRect:=TTwigPathRect(mpTwig).CondRect;
          mpTwig.AddPoint(GCanvas,mpTwig.mX,mpTwig.mY);
          GlobalAccuDraw.C1.Checked:=False;
          mpTwig.fixAngle:=xyNull;
          fixLength:=xyNull;
          OrthoTwigs.UpdateTwigs;
           If LOperation = sysDrawRect then begin If CRect = 2 then begin
             mpTwig.Move(GCanvas,mpTwig.mX,mpTwig.mY);
             MouseDown(Twigs,mbRight,[],mpTwig.mX,mpTwig.mY,Hook);
             MouseUp(Twigs,mbRight,[],0,0,Hook);
             SetFocus(Twigs.hWndParent);
             exit;
           end;
          end;
         end;
         If mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
         SetFocus(Twigs.hWndParent);
         UpdateImage;
       end;
  4:begin
     If GlobalAccuDraw.Angle<>xyNull then fixAngle:=GlobalAccuDraw.Angle+180 else fixAngle:=xyNull;
     if mpTwig<>nil then mpTwig.SetAngle(GCanvas,fixAngle,GlobalAccuDraw.useDirectAngle);
     SetFocus(Twigs.hWndParent);
     UpdateImage;
    end;
  5:begin
     arcFixLength:=GlobalAccuDraw.Distance;
      if mpTwig<>nil then mpTwig.SetLength(GCanvas,arcFixLength);
     SetFocus(Twigs.hWndParent);
     UpdateImage;
    end;
  hsLeft,
  hsRight,
  hsCenter:begin
            twigStyle:=TComponent(Sender).Tag;                         
           end;
  10:begin
      twigStyle:=ftwigStyle;
     end;
  21:begin
      cirKvant:=LayerPolygon.cirKvant;
      If mpTwig<>nil then begin
       mpTwig.twigStyle:=LayerPolygon.TwigStyle;
      // WRiteln('twSt=',LayerPolygon.TwigStyle);
       mpTwig.cirKvant:=cirKvant;
       mpTwig.Calculate;
       If mpTwig.twigStyle = 0 then With TTwigPathKvant(mpTwig) do begin
        Coord[0].XDot:=X1;Coord[0].YDot:=Y1;
       end;
      end;
      UpdateImage;
     end;
 end;
end;


procedure TMousePainter.SetCur(CurName: String);
begin
 If Marker=nil then Inherited else begin
  If not Marker.Visible then Inherited else begin
   Cursor:=LoadCursor(HInstance,'V25Arrow');
   SetActiveCursor(Cursor);
  end;
 end;
// Cursor:=LoadCursor(HInstance,'V25Arrow');
// SetActiveCursor(Cursor);
end;

function TMousePainter.GetTwigStyle: Integer;
begin
 Result:=ftwigStyle;
end;

procedure TMousePainter.SetTwigStyle(const Value: Integer);
begin
 ftwigStyle:=Value;
 If mpTwig<>nil then begin
  mpTwig.twigStyle:=Value;
  mpTwig.Width:=ParaLineForm.Width;
  ParaLineForm.HotSpot:=Value;
  mpTwig.Calculate;
  UpdateImage;
 end;
end;

function TMousePainter.CanDoUndo: Boolean;
begin
 Result:=False;
 If mpTwig<>nil then begin
  If (LOperation = sysLine)or(LOperation = sysDrawPoly)or(LOperation = sysDrawParaLine)or(LOperation = sysDrawLine)or(LOperation = sysDrawLine2) then begin
   mpTwig.DeletePoint(GCanvas);
   UpdateImage;
   Result:=True;
  end else Result:=True;
 end;
end;

procedure TMousePainter.UpdateFixedPoints;
var Angle,pointAngle,XArc,YArc,D,S:Double;Arc:TTwigArc;
begin
 If not fixPoint1.Visible then exit;
 PathMarker.GetPoint(X,Y);
 If fixDistance=xyNull then begin
  fixPoint2.mX:=X;fixPoint2.mY:=Y;
  exit;
 end;
//
 If objTemporary<>nil then
  If objTemporary is TTwigArc then begin
  // расчитывем по угловой мере введенную длину
  //!!!! учесть не точку маркера, а точку начала дуги
   Arc:=TTwigArc(objTemporary);
  // расчитываем по хорде
   If fixDistance<0 then S:=2*Arc.Radius*arcSin(Abs(fixDistance)/(2*Arc.Radius)) else S:=Abs(fixDistance);
  //
   Angle:=S/Arc.Radius;
   pointAngle:=Direct_Angle(Arc.C.XDot,Arc.C.YDot,fixPoint1.mX,fixPoint1.mY);
   Angle:=pointAngle+Angle;
   XArc:=Arc.C.XDot+Arc.Radius*Cos(Angle);
   YArc:=Arc.C.YDot+Arc.Radius*Sin(Angle);
   D:=Distance(fixPoint1.mX,fixPoint1.mY,XArc,YArc);
   Angle:=Direct_Angle(fixPoint1.mX,fixPoint1.mY,XArc,YArc);
   fixPoint2.mX:=fixPoint1.mX+D*Cos(Angle);
   fixPoint2.mY:=fixPoint1.mY+D*Sin(Angle);
  //
   exit;
  end;
 Angle:=Direct_Angle(fixPoint1.mX,fixPoint1.mY,X,Y);
 fixPoint2.mX:=fixPoint1.mX+fixDistance*Cos(Angle);
 fixPoint2.mY:=fixPoint1.mY+fixDistance*Sin(Angle);
end;

procedure TMousePainter.DrawFixedPoints(Canvas:TCanvas);
var Pen:hPen;Mode,Rop,Col:Integer;
begin
 If not fixPoint1.Visible then begin
 // Writeln('esit',TimeToStr(Now));
  exit;                             
 end;                                                
 Rop:=SetRop2(Canvas.Handle,R2_notXorPen);
 Pen:=SelectObject(Canvas.Handle,CreatePen(ps_Dot,0,winColor(clLime)));
 Mode:=SetBkMode(Canvas.Handle,TransParent);
// Col:=SetBkColor(Canvas.Handle,GlobalSettings.Settings.gsWindowColor);
  {If not Twigs.Settings.psSaveOrthoTwigs then} DrawLine(fixPoint1.mX,fixPoint1.mY,fixPoint2.mX,fixPoint2.mY);
//  PathMarker.Draw(Canvas);
 DeleteObject(SelectObject(Canvas.Handle,Pen));
 SetBkMode(Canvas.Handle,Mode);
// SetBkColor(Canvas.Handle,Col);
 SetRop2(Canvas.Handle,Rop);
 fixPoint1.Size:=GlobalSettings.Settings.gsPointSize*2;
 fixPoint2.Size:=GlobalSettings.Settings.gsPointSize*2-2;
 fixPoint1.Color:=GlobalSettings.Settings.gsGlueMarkerColor;
 fixPoint2.Color:=GlobalSettings.Settings.gsGlueMarkerColor;
 fixPoint1.mWidth:=1;
 fixPoint2.mWidth:=1;
 fixPoint1.Draw(Canvas,fixPoint1.mX,fixPoint1.mY);
// fixPoint2.Draw(Canvas,fixPoint2.mX,fixPoint2.mY);
end;

procedure TMousePainter.OnTimer(Sender: TObject);
var I, J:Integer;
begin
// If Key in [ord('Z'),ord('z'),ord('Я'),ord('я')] then begin
 try
 If ((TemporaryDot.What = tdUsed) and (Sender<>fixTimer))or(TemporaryDot.What = tdDop) then With TemporaryDot do begin
  DrawFixedPoints(GCanvas);
   fixPoint1.mX:=XDot;fixPoint1.mY:=YDot;fixPoint1.markerMoveStyle:=ord(Sender = nil);
   fixPoint2.mX:=XDot;fixPoint2.mY:=YDot;
   PathMarker.Restore(XDot,YDot); // маркер для притягивания к осям X,Y
  DrawFixedPoints(GCanvas);
  fixDistance:=xyNull;
  markerOrthoTwig[0].XDot:=XDot;markerOrthoTwig[0].YDot:=YDot;
 // OrthoTwigs.Draw(GCanvas,True);
//  Writeln('SETMarkedTwig=');
  OrthoTwigs.Add(markerOrthoTwig,'fixPoint');
 end else
 If Marker.Visible then
   If objTemporary = objTmp then If objTemporary is TDot then With TDot(objTemporary) do begin
   // Writeln('SetFixedTwig');
  DrawFixedPoints(GCanvas);
  fixPoint1.mX:=XDot;fixPoint1.mY:=YDot;fixPoint1.markerMoveStyle:=0;
  fixPoint2.mX:=XDot;fixPoint2.mY:=YDot;
  PathMarker.Restore(XDot,YDot); // маркер для притягивания к осям X,Y
  emFilterActiveLot(XDot,YDot);
//  OrthoTwigs.Pack('fixPoint');
// Writeln('ActLot.Count=',fActiveLots.Count);
  For I:=0 to fActiveLots.Count-1 do begin For J:=0 to TLot(fActiveLots[I]).Coord.Count-1 do OrthoTwigs.Add(TLot(fActiveLots[I]).GetTwig(Twigs.Twigs,J),'fixPoint');end;
  fActiveLots.DeleteAll;
//  UpdateImage;
//  OrthoTwigs.Draw(GCanvas,True);
  OrthoTwigs.addAngle:=Pi/2;
  fixDistance:=xyNull;
  DrawFixedPoints(GCanvas);
 end;
 except _ShowMessage('objMouseDraw '+IntToStr(864));fixTimer.Enabled:=False;OrthoTwigs.Pack('fixPoint'); end;
end;

procedure TMousePainter.TimerOpen;
begin
 If not timerNoStarting then begin
  fixTimer.Enabled:=False;
  fixTimer.Enabled:=True;
 end else
  fixTimer.Enabled:=False;
 objTmp:=objTemporary;
 timernoStarting:=False;
end;

procedure TMousePainter.TimerClose;
begin
 fixTimer.Enabled:=False;
 fixPoint1.Remove(GCanvas);
 fixPoint1.markermoveStyle:=0;
  OrthoTwigs.Pack('');
  OrthoTwigs.Pack('fixPoint');
 try UpdateImage;except end;
end;


procedure TMousePainter.DrawHatchLot(Canvas: TCanvas);
var I:Integer;
begin
 For I:=0 to HatchLot.Count-1 do
  HatchTwig[I].Paint(Canvas.Handle);
// Writeln(TTwigParaLine(mpTwig).);
end;

function TMousePainter.GetHatchTwig(Index: Integer): TTwig;
begin
 Result:=HatchLot[Index];
end;

procedure TMousePainter.MakeHatchLot;
begin

end;

initialization
 AddMouseHook(TMousePainter);
end.
