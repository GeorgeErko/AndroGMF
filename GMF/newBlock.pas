unit newBlock;

interface uses //tmpPainter,
               Collect, Classes, SysUtils, EcDot, WpTwigs, WPTForm2, newLayersTable,
               FMX.Graphics, UserObject, newConsts, newResource,
               TwgDraw, newProperties, newSelector, Lib, ogcBasic;

const
 Const_Block_Footer=4.3;
 Block_Drawing:boolean = False;

type
  TXY = record
   X,Y:Double;
  end;

var
 xyArray:Array[0..10000] of TXY;
 Stf:TStrings;

type

 { TGeoBlock }

 TGeoBlock = class(TUserObject)
  public
   Check:Byte; // 0 - блок; 1 - точка
   Name:AnsiString;
   TwgForm:TForm2;
   X,Y,OldDx,OldDy,OldAngle:Double; // координаты точки привязки относительно минимальных
   OldXKoef,OldYKoef:Double;
   Properties:TProperties;
   useUserParams:Boolean;
   blockRect:TSect;
   useBum:Boolean;
   useAutoScale:Boolean;
   useRect:Boolean;
   MyTwgForm:Boolean;
   AutoLayer:Single;
   emptyBlock:byte;
   Settings:Array[0..480-SizeOf(TExtended80Sect)-1-SizeOf(Single)-1] of Byte;
   NLotFixed:Integer;
   blkExtrusion:boolean;
   XBlock,YBlock:Double;
   useText:Integer;
   XText:Single;
   txtProperties:TProperties;
   usedInObject:boolean; // блок используется в объекте
   OldTwigsLarge,
   OldLotsLarge,
   OldAnyLarge:PCollection; // дублированные коллекции сегментов, контуров и точечных
 //  SelectorState:TSelector;
   DontFreeTwgForm:boolean;
   SSect:TShortSect;
   Buffer:TMemoryStream;
 //
   Selector:TSelector;
   class function objType:Integer;override;
   Constructor CreateForm(Form:TForm2);
   Constructor Create(Form:TForm2;objCol: PCollection);
   Constructor CreateAsUserObject(obj:TUserObject);override;
   Destructor Destroy;override;
   Constructor Load(Buf: TBufStream);override;
   Procedure Store(Buf: TBufStream);override;
   Constructor LoadHeader(Buf: TBufStream);override;
   Procedure StoreHeader(Buf: TBufStream);override;
   Procedure ClassBuild(Form:Pointer);override;
   Procedure Move(Dx,Dy,Angle:Double);override;
   Procedure Rotate(Angle:Double);override;
   Procedure MoveTo(toX,toY,Angle,XKoef,YKoef:Double;Extrusion:Boolean);override;
   Procedure MoveUp;override;
   Procedure ScaleTo(XKoef,YKoef:Double;TempDrawing:Boolean = False);override;
   procedure DoExtrusion;
  // возвращает коллекцию сегментов между дуг (при вставке окон и дверей в дугообразные проемы)
   Function BehindTheWheel(XB,YB,XKOef,YKoef,Angle:Double;Data:TTwigArc;arcDist:Boolean):PCollection;
   Procedure DrawTemp(Canvas:TCanvas;XB,YB,Angle,XKoef,YKoef:Double;Data:Pointer = nil);override;
   Function Draw(Canvas:TCanvas;XB,YB,Angle,XKoef,YKoef:Double;Extrusion,Inv:boolean):boolean;override;
   Procedure DrawMarker(Canvas:TCanvas);
   Function Draw32(Drawer:TogsDrawer;XB,YB,Angle,XKoef,YKoef:Double;Extrusion,Inv:boolean):boolean;
  //
   Function GetName: AnsiString;override;
   Function GetCheck: byte;override;
   Procedure SetCheck(const Value: byte);override;
  //
   Function RotateDots(XX,YY,Angle,Dx,Dy:Double;var Col:PCollection):boolean;
  //
   Procedure bumToTwgForm(toForm:TForm2;UndoBum:Boolean;CalcGabarites:Boolean;PackTwigs:Boolean);
  //
   Function Width:Double;override;
   Function Height:Double;override;
   Function rectWidth:Double;override;
   Function rectHeight:Double;override;
  //
   Function LayerExists(PR: TResource): Boolean;
  //
   Function isVisible(toX,toY,Angle,XKoef,YKoef:Double;Extrusion:boolean):Boolean;override;
 //  Function isVisible(toX,toY,Angle,XKoef,YKoef:Double;Extrusion:boolean):Boolean;override;
  //
  //
   Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
   Function GetProperty(propName:AnsiString):AnsiString;override;
   Function GetProperty2(propName: AnsiString): AnsiString;
   Function UseProperty(propName: AnsiString): boolean;override;
   Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
   Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
   Function ResetParams(ParamID: Integer;Params: Pointer):boolean;override;
  //
   Procedure ChangeXYKoef(XK,YK:Double);override;
  //
   Procedure SetAttribs(outProps, myProps: TProperties);override;
   Procedure ResetAttribs(inProps: TProperties);override;
  {}
   Function UseTextProps:boolean;
  //
   Procedure deRect(Color:Integer;XB, YB, Ugol,XKoef,YKoef: Double);
  // рисоывние на геометрической канве через вызов событий
   Procedure DrawTo(Geometry: TGeometryEvents);
  //
   Procedure deTriag(Color:Integer;XB, YB, Ugol,XKoef,YKoef: Double;de180:Boolean);
   Procedure deRound(Color:Integer;XB, YB, Ugol,XKoef,YKoef: Double);
   Procedure deRomb(Color:Integer;XB, YB, Ugol,XKoef,YKoef: Double);
   Procedure dePaint(XB, YB, Ugol,XKoef,YKoef: Double);
   Function  deVisible(XB, YB, Ugol,XKoef,YKoef: Double;var Sect:TShortSect):Boolean;override;
 end;

implementation uses TwgColle, newSettings, newForm0, ecLot,
                    TextManager, newProcs,
                    maths_basic, Lines2,
                    Lines3, EcDot2, newFontScale, Circle_di,
                    Intervals, Types_Dimano, Polygons, Writer, tmpPainter,
                    System.UITypes;

{ TGeoBlock }

constructor TGeoBlock.CreateForm(Form: TForm2);
begin
 X:=0;Y:=0;XText:=0;
 TwgForm:=Form;
// TwgForm.MirrorObject:=True;
// TwgForm.About.MirrorObject:=1;
 TwgForm.SetGabaritesPrivate;
 With TwgForm,blockRect do begin Left:=XXMin;Top:=YYMin;Right:=XXMax;Bottom:=YYMax;end;
 DontFreeTwgForm:=True;
// Buffer:=TMemoryStream.Create;
// binDraw(Buffer,X,Y,0,1,1,False);
//
end;

constructor TGeoBlock.Create(Form:TForm2;objCol: PCollection);
var I,J:Integer;
    Prim:TObject;
    Lot:TLot;
    LotTwig,Twig,TwigDup:TTwig;
    PD:TPointDot;
    N:Integer; // поворот ветки
begin
 TwgForm:=nil;
 If Form=nil then exit;
 X:=0;Y:=0;XText:=0;
 TwgForm:=Form.CreateAs(Form);
 TwgForm.MirrorObject:=True;
 TwgForm.About.MirrorObject:=1;
 TwgForm.Settings:=Form.Settings;
 If objCol <> nil then
 For J:=0 to objCol.Count-1 do begin
  Prim:=objCol[J];
  If Prim is TLot then begin
   Lot:=TLotClass(Prim.ClassType).CreateAsLotWithAll(TLot(Prim));
 //  Lot.GUID:=TLot(Prim).GUID;
    For I:=0 to Lot.Coord.Count-1 do begin
     // вставляем ветки в TwgForm
     LotTwig:=Lot.GetTwig(Form.Twigs,I);
     TwigDup:=TTwigClass(LotTwig.ClassType).CreateAsTwig(LotTwig,True);
     Quants_For_Arcs:=Form.Settings.psArcCount;TwigDup.Calculate;
     TwigDup.ArcView:=1;
     try
      Twig:=TTwig.CreateAsTwig(TwigDup,True);
     finally
      TwigDup.Free;
      Quants_For_Arcs:=Form.Settings.psArcCount;
     end;
     Twig.Calculate;Twig.SetMinMax;
     TwgForm.Twigs.Insert(TWG_Twig,Twig);
     N:=Round(TLong(Lot.Coord[I]).Num/TLong(Lot.Coord[I]).Num);
     TLong(Lot.Coord[I]).Num:=(TwgForm.Twigs.TwigsCount-1)*N;
    end;
    // контур
    Lot.SetMinMax(TwgForm.Twigs);
    Lot.SetFromTwig(TwgForm.Twigs);
    TwgForm.Twigs.Insert(TWG_Lot,Lot);
   end else If Prim is TPointDot then begin
    PD:=TPointDot(Prim);
    PD:=TPointClass(PD.ClassType).CreateAsPointDot_(TPointDot(Prim),True);
   // PD.GUID:=TPointDot(Prim).GUID;
    // точка
    TwgForm.Twigs.Insert(TWG_Point,PD);
    If PD is TDotText then
     If TDotText(PD).Text.AttrName<>'' then begin
      If Properties = nil then Properties:=TProperties.Create;
      Properties.AddProperty(TDotText(PD).Text.AttrName,TDotText(PD).Text.Text);
     end;
   end;
 end;
 TwgForm.SetGabaritesPrivate;
 With TwgForm,blockRect do begin Left:=XXMin;Top:=YYMin;Right:=XXMax;Bottom:=YYMax;end;
end;

constructor TGeoBlock.CreateAsUserObject(obj: TUserObject);
var Buf:TBufStream;P,F:Pointer;
begin
// P:=GPointCol;F:=GFontColEx;
 try
//  Buf:=TBufStream.InitFileStream(MainPath+'\blk.tmp',fmCreate);
 // GFontColEx:=TGeoBlock(obj).TwgForm.FontColEx;
  Buf:=TBufStream.Create; // у BufStream должен быть параметр Selector, содержащий ссылки на глобальные переменные объекта FontColEx, PSLib и проч
  obj.Store(Buf);
  Buf.FlushBuffer;
//  Buf.Free;
//  Buf:=TBufStream.InitFileStream(MainPath+'\blk.tmp',fmOpenRead);
  Buf.Position:=0;
  Load(Buf);
  Buf.Free;
 finally
 // GPointCol:=P;
 // GFontColEx:=F;
 end;
end;

destructor TGeoBlock.Destroy;
begin
 If not DontFreeTwgForm then begin TwgForm.Free; end;
 If Buffer<>nil then Buffer.Free;
 If Properties<>nil then Properties.Free;
end;

constructor TGeoBlock.Load(Buf: TBufStream);
var I:Integer;PP:TPointDot;B:Byte;P:Pointer;BD:Boolean;
    N:Array[0..480-SizeOf(TExtended80Sect)-1-SizeOf(Single)-1] of Byte;
begin
 Selector:=Buf.Selector;
 Buf.Read(Check,SizeOf(Check));
 Name:=Buf.ReadString;
// WriteIn(['LoadBlock=', Name]);
// If Name = 'ЛЕГЕНДА' then
//  Writeln('Name=',Name);
 If Check=0 then begin
  Buf.Read(X,SizeOf(X));Buf.Read(Y,SizeOf(Y));
//  Writeln('EcConst=',Ecconst.Version);
// WriteIn(['Form.Load=',Name]);
  BD:=BLOCK_DEBUG; BLOCK_DEBUG:=False;
 // WriteIn([1]);
  TwgForm:=TForm2(Buf.Get);
 // WriteIn([2]);
//  WriteIn(['Form.Loaded=',Name]);
// Oh
  useText:=0;
  TwgForm.FontColEx := Selector.GFontColEx;
 // WriteIn(['FontColExBlock=',Name, ' ', TwgForm.FontColEx <> nil]);
  if TwgForm.FontColEx<>nil then
   For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
    PP:=TwgForm.Twigs.AAt(I,B);
    If PP.ResetParams(param_idResetFontView,TwgForm.FontColEx) then Inc(useText);
   end;
//  WriteIn(['End FontColEx=', Name, Buf.Position]);
///
  Buf.Read(useUserParams,SizeOf(useUserParams));
  With Buf.ReadSect do begin blockRect.Left:=Left;blockRect.Top:=Top;blockRect.Right:=Right;blockRect.Bottom:=Bottom;end;
//  WriteIn(['Rect=',Name,blockRect.Left,blockRect.Top,blockRect.Right,blockRect.Bottom]);
  Buf.Read(useBum,SizeOf(useBum));
  Buf.Read(useAutoScale,SizeOf(useautoScale));
  Buf.Read(useRect,SizeOf(useRect));
  Buf.Read(AutoLayer,SizeOf(AutoLayer));
  Buf.Read(emptyBlock,SizeOf(emptyBlock));
  Buf.Read(Settings,SizeOf(Settings));
 // WriteIn([4]);
//  Writeln('EcConst=',Ecconst.Version);
  If newConsts.Version>37 then begin
   Properties:=TProperties(Buf.Get);
  end;
//  WriteIn(['Properties=', Name, Buf.Position]);
  //  WriteIn([52]);
BLOCK_DEBUG:=BD;
 // Buf.GPointCol:=nil;
   TwgForm.SetGabaritesPrivate;
  //  WriteIn([6]);
//  WriteIn(['SetGabs=', Name, Buf.Position]);
  If newConsts.Version<39 then With TwgForm,blockRect do begin Left:=XXMin;Top:=YYMin;Right:=XXMax;Bottom:=YYMax;end;
  For I:=0 to TwgForm.Twigs.LotsCount-1 do begin
   TLot(TwgForm.Twigs.LAt(I)).SetFromTwig(TwgForm.Twigs);
  end;
 end;
 //   WriteIn([7]);
// WriteIn(['endOfBlock=',Name,SizeOf(N),' ',SizeOf(Self.Settings)]);
 If Name = 'MAF_OB_Skamya_sospin_met' then If Check=0 then begin
//  WriteIn(['endOfBlock_DEBUG=',Name]);
 end;
// WriteIn(['LoadBlockEnd=', Name]);
end;

procedure TGeoBlock.Store(Buf: TBufStream);
begin
 Buf.Write(Check,SizeOf(Check));
 Buf.WriteString(Name);
 If Check=0 then begin
   Buf.Write(X,SizeOf(X));Buf.Write(Y,SizeOf(Y));
   Buf.Put(TwgForm);
   Buf.Write(useUserParams,SizeOf(useUserParams));
  // не работает на WIN64 !!!
   Buf.Write(blockRect,SizeOf(blockRect));
   Buf.Write(useBum,SizeOf(useBum));
   Buf.Write(useAutoScale,SizeOf(useautoScale));
   Buf.Write(useRect,SizeOf(useRect));
   Buf.Write(AutoLayer,SizeOf(AutoLayer));
   Buf.Write(emptyBlock,SizeOf(emptyBlock));
   Buf.Write(Settings,SizeOf(Settings));
   Buf.Put(Properties);
 end;
end;

constructor TGeoBlock.LoadHeader(Buf: TBufStream);
begin
 Name:=Buf.ReadString;                   
end;                                     

procedure TGeoBlock.StoreHeader(Buf: TBufStream);
begin
 Buf.WriteString(Name);
end;

// производим ClassBuild для примитивов Objects

procedure TGeoBlock.ClassBuild(Form: Pointer);
begin
// инициализируем класификатор и таблицу слоев первого объекта
 If TwgForm<>nil then begin
  TwgForm.MkLib:=TForm2(Form).MkLib;
  TwgForm.LayerTable:=TForm2(Form).LayerTable;
 end;
end;

procedure TGeoBlock.MoveTo(toX, toY, Angle,XKoef,YKoef: Double;Extrusion:Boolean);
var Dx,Dy:Double;
begin
 Dx:=toX-(X+TwgForm.XXMin);Dy:=toY-(Y+TwgForm.YYMin);
 OldDx:=Dx;OldDy:=Dy;OldAngle:=Angle;
 Move(Dx,Dy,Angle);
 OldXKoef:=XKoef;OldYKoef:=YKoef;
 ScaleTo(XKoef,YKoef);
 Rotate(Angle);
 blkExtrusion:=Extrusion;
 XBlock:=toX;YBlock:=toY;
 If Extrusion then DoExtrusion;
end;

procedure TGeoBlock.DoExtrusion;
var I,J:Integer;Dot:TDot;Twig:TTwig;
    PD:TPointDot;B:Byte;Lot:TLot;
Procedure ExtrusionPoint(var XP,YP:Single);
begin
 XP:=XP+(XBlock-XP)*2;
end;
begin
 With TwgForm do begin
// Col:=PCollection.Create(1);
 // вычисляем смещение
  For I:=1 to Twigs.TwigsCount-1 do begin // смещаем ветки
   Twig:=Twigs.TAt(I);
   For J:=0 to Twig.Coord.Count-1 do begin
    Dot:=Twig.Coord[J];
    Dot.XDot:=Dot.XDot+(XBlock-Dot.XDot)*2;
   end;
   ExtrusionPoint(Twig.XMin,Twig.YMin);ExtrusionPoint(Twig.XMax,Twig.YMax);
  end;
  For I:=0 to Twigs.LotsCount-1 do begin
   Lot:=Twigs.LAt(I);
   ExtrusionPoint(Lot.XMin,Lot.YMin);ExtrusionPoint(Lot.XMax,Lot.YMax);
  end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin {Col.Insert(PD);}{If PD.NLot<>NLotFixed then} PD.XDot:=PD.XDot+(XBlock-PD.XDot)*2;end;
  end;
 end;
end;

procedure TGeoBlock.MoveUp;
begin
 if blkExtrusion then DoExtrusion;
 Move(-OldDx,-OldDy,-OldAngle);
 Rotate(-OldAngle);
 ScaleTo(-OldXKoef,-OldYKoef);
end;

procedure TGeoBlock.Move(Dx, Dy, Angle: Double);
var I:Integer;PD:TPointDot;B:Byte;Col:PCollection;
    Twig:TTwig;
begin
 With TwgForm do begin
 X:=X+Dx;Y:=Y+Dy;
// Col:=PCollection.Create(1);
 // вычисляем смещение
  For I:=1 to Twigs.TwigsCount-1 do begin // смещаем ветки
   Twig:=Twigs.TAt(I);Twig.Move(Dx,Dy);
  end;
  For I:=0 to Twigs.LotsCount-1 do TLot(Twigs.LAt(I)).Move(Dx,Dy);
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin {Col.Insert(PD);}{If PD.NLot<>NLotFixed then} PD.Move(Dx,Dy);end;
  end;
 end;
// Col.DeleteAll;Col.Free;
//TwgForm.XXMin:=TwgForm.XXMin+Dx;TwgForm.YYMin:=TwgForm.YYMin+Dy;
end;

function TGeoBlock.BehindTheWheel(XB, YB, XKOef, YKoef, Angle: Double;
 Data: TTwigArc; arcDist: Boolean): PCollection;
var I:Integer;
    Twig,Twig1:TTwig;TwigArc:TTwigArc;
    A1,A2,A3,A4,APoint:Double;
    X1,Y1,X2,Y2,X3,Y3:Double;
    Delta:Double;
    Minus:Integer;
    rectHeight1:Double;
Procedure FormPere(var XT,YT:Double);
var Form:TForm2;X,Y:Double;Twig1:TTwigArc;
    I:Integer;
begin
 Form:=TForm2(Selector.GTwgForm);
 For I:=1 to Form.Twigs.TwigsCount-1 do If TTwig(Form.Twigs.TAt(I)) is TTwigArc then begin
  Twig1:=Form.Twigs.TAt(I);
  If Twig1.GetTwigDist(XT,YT,X,Y)<=0.005 then begin
  // Writeln('OK',Twig1.GetTwigDist(XT,YT,XT,YT));
   Twig1.GetTwigDist(XT,YT,XT,YT);
  end;// else Writeln('Not=',Twig1.GetTwigDist(XT,YT,X,Y));
 end;
end;
begin
//  Writeln('==============================');
  Result:=PCollection.Create(1);
  // находим исходя из габаритов блока его кривоугольник
  // для этого вычисляем углы A1 - начало направления, A2 - конец направления
  A1:=Direct_Angle(TTwigArc(Data).C.XDot,TTwigArc(Data).C.YDot,XB,YB);
  TTwigArc(Data).GetTwigDist(XB,YB,XB,YB);
  Minus:=1;
  A2:=A1+(rectWidth*XKoef)/TTwigArc(Data).Radius*Minus;
  A3:=A1+((rectWidth*XKoef)/TTwigArc(Data).Radius)/2*Minus;
 With TwgForm do
  For I:=0 to Twigs.TwigsCount-1 do begin
   Twig:=Twigs.TAt(I);
   // если ветка горизонтальна
   If (Twig.Coord.Count = 2) and (Selector.EqualCoord(Twig[0].YDot,Twig[1].YDot)) and (not Selector.EqualPoints(Twig[0],Twig[1])) then begin
   // устанавливаем радиус -> начальные и конечные точки новой дуги
    TwigArc:=TTwigArc.CreateAsTwig(Data,True);
    TwigArc.ClassHandle:=Twig.ClassHandle;
    // по часовой стрелке вычисляем точку TwigArc.B
    Delta:=YB-Twig[0].YDot;
    X1:=TwigArc.C.XDot+(TwigArc.Radius+Delta)*cos(A2);
    Y1:=TwigArc.C.YDot+(TwigArc.Radius+Delta)*sin(A2);
    X2:=TwigArc.C.XDot+(TwigArc.Radius+Delta)*cos(A1);
    Y2:=TwigArc.C.YDot+(TwigArc.Radius+Delta)*sin(A1);
    X3:=TwigArc.C.XDot+(TwigArc.Radius+Delta)*cos(A3);
    Y3:=TwigArc.C.YDot+(TwigArc.Radius+Delta)*sin(A3);
  //  With TwigArc do begin PMoveTo(C.XDot,C.YDot);PLineTo(X1,Y1);PMoveTo(C.XDot,C.YDot);PLineTo(X2,Y2);end;
    // устанавливаем первую точку
    TwigArc.A.XDot:=X2;TwigArc.A.YDot:=Y2;
    TwigArc.B.XDot:=X1;TwigArc.B.YDot:=Y1;
    TwigArc.D.XDot:=X3;TwigArc.D.YDot:=Y3;
    //
    TwigArc.Calculate;
    Result.Insert(TwigArc);
   end else
   // если ветка вертикальная
   If (Twig.Coord.Count = 2) and (Selector.EqualCoord(Twig[0].XDot,Twig[1].XDot)) and (not Selector.EqualPoints(Twig[0],Twig[1])) then begin
    Delta:=YB-Twig[0].YDot;
//    Writeln('1=',Round(Delta*Const_Of_DecimalCoord),' ',Round((rectHeight*YKoef)*Const_Of_DecimalCoord));
    If Round(Delta*Const_Of_PrecCoord) = 0 then begin
     Delta:=0;
//     Writeln('Delta1=0');
    end else
    If Abs(Round(Delta*Const_Of_PrecCoord)) = Abs(Round((rectHeight*YKoef)*Const_Of_PrecCoord)) then begin
    rectHeight1:=Round(rectHeight*100)/100;
     Delta:=RectHeight1*YKoef*(Delta/Abs(Delta));
     Delta:=Round(Delta*1000)/1000;
//     Writeln('itsHeight1=',Delta,' ',I);
//     Delta:=Round(Delta*100)/100;
    end;
    A4:=A1+Abs(((Twig[1].XDot-XB)/TTwigArc(Data).Radius)*Minus);
    Twig1:=TTwig.CreateAsTwig(Twig,True);
    X1:=TTwigArc(Data).C.XDot+(TTwigArc(Data).Radius+Delta)*cos(A4);
    Y1:=TTwigArc(Data).C.YDot+(TTwigArc(Data).Radius+Delta)*sin(A4);
 //   If Delta = 0 then begin TTwigArc(Data).GetTwigDist(X1,Y1,X1,Y1);end else FormPere(X1,Y1);
    Delta:=YB-Twig1[1].YDot;
//    Writeln('2=',Abs(Round(Delta*Const_Of_DecimalCoord),' ',Round((rectHeight*YKoef)*Const_Of_DecimalCoord));
    If Round(Delta*Const_Of_PrecCoord) = 0 then begin
     Delta:=0;
//     Writeln('Delta2=0',I);
    end else
    If Abs(Round(Delta*Const_Of_PrecCoord)) = Abs(Round((rectHeight*YKoef)*Const_Of_PrecCoord)) then begin
     rectHeight1:=Round(rectHeight*100)/100;
     Delta:=Round(RectHeight1*100)/100*YKoef*(Delta/Abs(Delta));
     Delta:=Round(Delta*1000)/1000;
//     Writeln('itsHeight2=',Delta,' ',I);
//     Delta:=Round(Delta*100)/100;
    end;
    X2:=TTwigArc(Data).C.XDot+(TTwigArc(Data).Radius+Delta)*cos(A4);
    Y2:=TTwigArc(Data).C.YDot+(TTwigArc(Data).Radius+Delta)*sin(A4);
//    If Delta = 0 then begin TTwigArc(Data).GetTwigDist(X2,Y2,X2,Y2);end else FormPere(X2,Y2);
    Twig1[0].XDot:=X1;Twig1[0].YDot:=Y1;
    Twig1[1].XDot:=X2;Twig1[1].YDot:=Y2;
    Twig1.SetMinMax;
    Result.Insert(Twig1);
//    With Twig1 do PMoveTo(C.XDot,C.YDot,);
   end;
  end;
//  Writeln('==============================');
end;

procedure TGeoBlock.DrawTemp(Canvas: TCanvas; XB, YB, Angle,XKoef,YKoef: Double;Data:Pointer= nil);
var I,R:Integer;B:Byte;PD:TPointDot;Dx,Dy:Double;
    Twig:TTwig;
    P:PCollection;
    Value:TPropValue;
    oldValue:AnsiString;
begin
// Writeln('DrawTemp');
 If TwgForm = nil then exit;
 With TwgForm do begin
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
//   Writeln('One=',Angle*180/Pi:8:2);
 Self.Move(Dx,Dy,Angle);Self.ScaleTo(XKoef,YKoef,True);Self.Rotate(Angle);
 try
 // если ветка Arc -> заменяем горизонтальные ветки на дуги
  If (Data<>nil) and (TTwig(Data) is TTwigArc) and (UseBum) then begin
   P:=BehindTheWheel(XB,YB,XKoef,YKoef,Angle,Data,False); // arcDist = False -> пока расстояние по хорде
   For I:=0 to P.Count-1 do TTwig(P[I]).Draw;
   P.Free;
  end else
 // вычисляем смещение
  For I:=0 to Twigs.TwigsCount-1 do begin
   TTwig(Twigs.TAt(I)).Draw;//Paint(Canvas.Handle);
  end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin
    {R:=GGraphSet.RPoint;
    GGraphSet.RPoint:=GGraphSet.RPoint+1;
     PSetPixel(PD.XDot+Dx,PD.YDot+Dy);
    GGraphSet.RPoint:=R;}
    oldValue:=#0;
    If (txtProperties<>nil) and (PD is TDotText) then If TDotText(PD).Text.AttrName<>'' then begin
     Value:=txtProperties.PropValue[TDotText(PD).Text.AttrName];
     oldValue:=TDotText(PD).Text.Text;
     If Value<>nil then TDotText(PD).Text.Text:=Value.Value;
    end;
   // PD.Draw(0, MkLib.PSLib);
    If oldValue<>#0 then TDotText(PD).Text.Text:=oldValue;
   end;
 end;
 finally
  Self.Move(-Dx,-Dy,0);Self.Rotate(-Angle);Self.ScaleTo(-XKoef,-YKoef,True);
//   Writeln('Two=',-XKoef,' ',-YKoef);
 end;
 end;
// DrawMarker(Canvas);
end;

procedure TGeoBlock.deRect(Color: Integer; XB, YB, Ugol, XKoef, YKoef: Double);
var I:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1:Double;
    pen: HPEN;
    br: HBRUSH;
    YYMax1:Double;
begin
 Vertex:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
 With TwgForm do begin
  YYMax1:=YYMax-(YYMax-YYMin)/Const_Block_Footer;
  Vertex.Insert(TDot.Create(XXMin+Dx,YYMin+Dy,0));
  Vertex.Insert(TDot.Create(XXMin+Dx,YYMax1+Dy,0));
  Vertex.Insert(TDot.Create(XXMax+Dx,YYMax1+Dy,0));
  Vertex.Insert(TDot.Create(XXMax+Dx,YYMin+Dy,0));
 end;
 For I:=0 to Vertex.Count-1 do begin
  XX:=TDot(Vertex.At(I)).XDot;YY:=TDot(Vertex.At(I)).YDot;
	 xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
	 yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
	 Par[I+1].X:=Selector.Xpix(xx1);
	 Par[I+1].Y:=Selector.Ypix(yy1);
 end;
{  Pen:=SelectObject(Selector.GCanvas.Handle,CreatePen(PS_SOLID, 0, Color));
  Br:=SelectObject(Selector.GCanvas.Handle,CreateSolidBrush(RGBToCol(255,255,255)));
   PolyGon(Selector.GCanvas.Handle,Par,Vertex.Count);
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Pen));
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Br));
 }
 Vertex.Free;
end;

function TGeoBlock.deVisible(XB, YB, Ugol, XKoef, YKoef: Double;var Sect:TShortSect): Boolean;
var I:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1:Double;
    pen: HPEN;
    br: HBRUSH;
    YYMax1:Double;
    XMin,YMin,XMax,YMax:Double;
begin
 Result := True;
 If GlobalRender then exit;
 Vertex:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
 With TwgForm do begin
  YYMax1:=YYMax-(YYMax-YYMin)/Const_Block_Footer;
  Vertex.Insert(TDot.Create(XXMin+Dx,YYMin+Dy,0));
  Vertex.Insert(TDot.Create(XXMin+Dx,YYMax1+Dy,0));
  Vertex.Insert(TDot.Create(XXMax+Dx,YYMax1+Dy,0));
  Vertex.Insert(TDot.Create(XXMax+Dx,YYMin+Dy,0));
 end;
 XMin:=10000000;YMin:=10000000;XMax:=-10000000;YMax:=-10000000;
 For I:=0 to Vertex.Count-1 do begin
  XX:=TDot(Vertex.At(I)).XDot;YY:=TDot(Vertex.At(I)).YDot;
  xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
  yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
  If xx1>XMax then XMax:=xx1;If xx1<XMin then XMin:=xx1;
  If yy1>YMax then YMax:=yy1;If yy1<YMin then YMin:=yy1;
 end;
 Vertex.Free;
  Sect.Left:=XMin;Sect.Top:=YMin;Sect.Right:=XMax;Sect.Bottom:=YMax;
{
 If Extrusion then begin
  ExtrusionPoint(Sect.Left,Sect.Top);
  ExtrusionPoint(Sect.Right,Sect.Bottom);
 end;
}
 With Selector,GRect do begin
  If Sect.Right<Left then begin Result:=False;Exit;end;
  If Sect.Left>Right then begin Result:=False;Exit;end;
  If Sect.Top>Top then begin Result:=False;Exit;end;
  If Sect.Bottom<Bottom then begin Result:=False;Exit;end;
 end;
 Result:=True;
end;

procedure TGeoBlock.deTriag(Color: Integer; XB, YB, Ugol, XKoef, YKoef: Double;
 de180: Boolean);
var I:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1:Double;
    pen: HPEN;
    br: HBRUSH;
    YYMax1:Double;
begin
 Vertex:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
 With TwgForm do begin
  YYMax1:=YYMax-(YYMax-YYMin)/Const_Block_Footer;
  If not de180 then begin
   Vertex.Insert(TDot.Create(XXMin+Dx,YYMax1+Dy,0));
   Vertex.Insert(TDot.Create((XXMin+XXMax)/2+Dx,YYMin+Dy,0));
   Vertex.Insert(TDot.Create(XXMax+Dx,YYMax1+Dy,0));
  end else begin
   Vertex.Insert(TDot.Create(XXMin+Dx,YYMin+Dy,0));
   Vertex.Insert(TDot.Create((XXMin+XXMax)/2+Dx,YYMax1+Dy,0));
   Vertex.Insert(TDot.Create(XXMax+Dx,YYMin+Dy,0));
  end;
//  Vertex.Insert(TDot.Create(XXMin+Dx,YYMax+Dy,0));
 end;
 For I:=0 to Vertex.Count-1 do begin
  XX:=TDot(Vertex.At(I)).XDot;YY:=TDot(Vertex.At(I)).YDot;
	 xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
	 yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
	 Par[I+1].X:=Selector.Xpix(xx1);
	 Par[I+1].Y:=Selector.Ypix(yy1);
	end;
{  Pen:=SelectObject(Selector.GCanvas.Handle,CreatePen(PS_SOLID, 0, Color));
  Br:=SelectObject(Selector.GCanvas.Handle,CreateSolidBrush(RgbToCol(255,255,255)));
   PolyGon(Selector.GCanvas.Handle,Par,Vertex.Count);
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Pen));
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Br));
 }
//  For I:=1 to 3 do
//   TextOut(GCanvas.Handle,Par[I].X,Par[I].Y,PAnsiChar(IntToStr(I)),1);
 Vertex.Free;
end;

procedure TGeoBlock.deRound(Color: Integer; XB, YB, Ugol, XKoef,
  YKoef: Double);
var I:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1:Double;
    pen: HPEN;
    br: HBRUSH;
    YYMax1:Double;
    D1,D2:TDot;
    P:PCollection;
begin
 Vertex:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
//!!!
 With TwgForm do begin
  YYMax1:=YYMax-(YYMax-YYMin)/Const_Block_Footer;
  Vertex.Insert(TDot.Create(XXMin+Dx,YYMax1+Dy,0));
  Vertex.Insert(TDot.Create(XXMax+Dx,YYMin+Dy,0));
 end;
 D1:=Vertex[0];D2:=Vertex[1];
 XX:=(D1.XDot+D2.XDot)/2;YY:=(D1.YDot+D2.YDot)/2;
 I:=25;
 P:=Circle2(XX,YY,D1.XDot,YY,Width/2,I);
 Vertex.Free;Vertex:=P;
 For I:=0 to Vertex.Count-1 do begin
  XX:=TDot(Vertex.At(I)).XDot;YY:=TDot(Vertex.At(I)).YDot;
	 xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
	 yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
	 Par[I+1].X:=Selector.Xpix(xx1);
	 Par[I+1].Y:=Selector.Ypix(yy1);
	end;
 { Pen:=SelectObject(Selector.GCanvas.Handle,CreatePen(PS_SOLID, 0, Color));
  Br:=SelectObject(Selector.GCanvas.Handle,CreateSolidBrush(RgbToCol(255,255,255)));
   PolyGon(Selector.GCanvas.Handle,Par,Vertex.Count);
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Pen));
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Br));
 }
//  For I:=1 to 2 do
//   TextOut(GCanvas.Handle,Par[I].X,Par[I].Y,PAnsiChar(IntToStr(I)),1);
 Vertex.Free;
end;

procedure TGeoBlock.deRomb(Color: Integer; XB, YB, Ugol, XKoef,
  YKoef: Double);
var I:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1:Double;
    pen: HPEN;
    br: HBRUSH;
    YYMax1:Double;
begin
 Vertex:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
 With TwgForm do begin
  YYMax1:=YYMax-(YYMax-YYMin)/Const_Block_Footer;
  Vertex.Insert(TDot.Create(XXMin+Dx,(YYMax1+YYMin)/2+Dy,0));
  Vertex.Insert(TDot.Create((XXMin+XXMax)/2+Dx,YYMin+Dy,0));
  Vertex.Insert(TDot.Create((XXMax)+Dx,(YYMax1+YYMin)/2+Dy,0));
  Vertex.Insert(TDot.Create((XXMin+XXMax)/2+Dx,YYMax1+Dy,0));
//  Vertex.Insert(TDot.Create(XXMin+Dx,YYMax+Dy,0));
 end;
 For I:=0 to Vertex.Count-1 do begin
  XX:=TDot(Vertex.At(I)).XDot;YY:=TDot(Vertex.At(I)).YDot;
	 xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
	 yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
	 Par[I+1].X:=Selector.Xpix(xx1);
	 Par[I+1].Y:=Selector.Ypix(yy1);
	end;
{  Pen:=SelectObject(Selector.GCanvas.Handle,CreatePen(PS_SOLID, 0, Color));
  Br:=SelectObject(Selector.GCanvas.Handle,CreateSolidBrush(RgbToCol(255,255,255)));
   PolyGon(Selector.GCanvas.Handle,Par,Vertex.Count);
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Pen));
  DeleteObject(SelectObject(Selector.GCanvas.Handle,Br)); \
 }
//  For I:=1 to 3 do
//   TextOut(GCanvas.Handle,Par[I].X,Par[I].Y,PAnsiChar(IntToStr(I)),1);
 Vertex.Free;
end;

procedure TGeoBlock.DrawTo(Geometry: TGeometryEvents);
var I, J: Integer;
    Lot: TLot;
    Twig: TTwig;
    pLine: PCollection;
    XB, YB, Dx, Dy: Double;
    PD: TpointDot; B: Byte;
    DT: TDotText;
    P, rootP: PGeoPoint;
    N: Integer;
begin
// TwgForm.SetGabaritesPrivate;
// WriteIn(['Dot=',Name, ' ', TwgForm.XXMin,' ',blockRect.Left, blockRect.Top]); readin;
// WriteIn(['XTBlock=',XBlock,YBlock]);
//  WriteIn(['Name=', Name]);
  TwgForm.SetGabaritesPrivate;
//  WriteIn(['block12345=', X , Y , blockRect.Left, blockRect.Top, 'XYMin=', TwgForm.XXMin, TwgForm.YYMin]);
//  WriteIn(['XYblock=', XBlock , YBlock]);
 Dx:= (X + TwgForm.XXMin); Dy:= (Y + TwgForm.YYMin);
// двигаем точки контуров относительно 0
 For I := 0 to TwgForm.Twigs.LotsCount -1 do begin
  Lot := TwgForm.Twigs.LAt(I);
  Lot.InsClipDotsParall(TwgForm.Twigs);
  New(P); N := 0;
  rootP := P;
//  Dx := -(TwgForm.XXMin + X); Dy := -(TwgForm.YYMin + Y);
  For J := 0 to Lot.Points.Count - 1 do With TDot(Lot.Points[J]) do begin
 // смещаем относительно координат блока, т.е. фактически передаем смещения
 //  WriteIn(['XY=', XDot, YDot]);
 //  Dx:= blockRect.Left - XDot + X ;
//   Dy:= YDot - blockRect.Top - Y;
   XB := XDot - Dx;
   YB := YDot - Dy;
//   WriteIn(['DDXY=', XB, YB]);
   If N = 0 then P.Create(XB, YB, 0) else begin
                 P.AddPoint(XB, YB, 0);
                 P := P.Next;
                end;
   Inc(N);
  end;
  rootP.Count := Lot.Points.Count;
 //
//  WriteIn(['PolyBlock.I=',I,Lot.LotLineColor, Lot.LotColor, Lot.Plo]);
  Geometry.OnPoly(Geometry.Obj, rootP, Lot.LotLineColor, Lot.LotColor, 0, True, Lot.TypeLot = 2);
  rootP.FreeAll;
  Dispose(rootP);
//
  Lot.Points.Free;
 end;
// передаем атрибуты
  For I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
   PD := TwgForm.Twigs.AAt(I, B);
   If PD is TDotText then begin
    DT := PD as TDotText;
//    (X, Y: Double; FontName: String; txtHeight, txtAngle, txtScale: Double;
//     txtColor: TColor; Align: byte; Bl, It, Un: Boolean; Text, AttrName: String)
    Geometry.OnText(Geometry.Obj, DT.XDot - Dx, DT.YDot - Dy,
                    PChar(DT.Text.fontView.FontName), DT.Text.Height,
                    DT.Ugol, DT.XKoef, DT.Text.Color, DT.Text.Align, boolean(DT.Text.fontView.Bl), boolean(DT.Text.fontView.It), boolean(DT.Text.fontView.Un),
                    PChar(DT.Text.Text), PChar(DT.Text.AttrName));
   end;
  end;
end;

procedure TGeoBlock.dePaint(XB, YB, Ugol, XKoef, YKoef: Double);
var I,J:Integer;Vertex:PCollection;
    XX,YY, Dx, Dy, xx1, yy1,xx3,yy3,xx4,yy4:Double;
    Twig,Twig1:TTwig;D,D1:TDot;Lot,Lot1:TLot;
    TwigsLarge:PCollection;// коллекция сегментов
    LotsLarge:PCollection;
    AnyLarge:PCollection;
    Col:PCollection;
    PD:TPointDot;W:Byte;PD1:TPointDot;
    TP:TTextParams;
begin
 TwigsLarge:=PCollection.Create(1);LotsLarge:=PCollection.Create(1);AnyLarge:=PCollection.Create(1);
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
 With TwgForm do begin
 // двигаем точки сегментов, сегменты ставляем в коллекцию
  For I:=0 to Twigs.TwigsCount-1 do begin
   Twig:=Twigs.TAt(I);Twig1:=TTwig.CreateAsTwig(Twig,False);TwigsLarge.Insert(Twig1);
   With Twig1 do begin XMax:=-100000000;YMax:=-100000000;XMin:=100000000;YMin:=100000000;end;
    For J:=0 to Twig.Coord.Count-1 do begin
     D:=Twig.Coord[J];
//     Stf.Add(FloatToStrF(D.XDot,ffFixed,_LD,0)+' '+FloatToStrF(D.YDot,ffFixed,_LD,0));
     Twig1.Coord.Insert(TDot.Create(D.XDot+Dx,D.YDot+Dy,ord(J=0)));
     D:=TDot(Twig1.Coord.At(J));
     XX:=D.XDot;YY:=D.YDot;
//     Stf.Add(FloatToStrF(XX,ffFixed,_LD,0)+' '+FloatToStrF(YY,ffFixed,_LD,0));
     xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
     yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
//     Stf.Add(FloatToStrF(XX1,ffFixed,_LD,0)+' '+FloatToStrF(YY1,ffFixed,_LD,0));
     D.XDot:=xx1;D.YDot:=yy1;
     Twig1.MinMax(xx1,yy1);
    end;
   end;
 // двигаем заливки в контурах
   Col:=PCollection.Create(1);
   For I:=0 to Twigs.LotsCount-1 do begin
    Lot:=Twigs.LAt(I);Lot1:=TLot.CreateAsLot(Lot,True);LotsLarge.Insert(Lot1);
    Lot1.RotationPoints(Col);
     For J:=0 to Col.Count-1 do begin
      D:=Col[I];
      D.XDot:=D.XDot+Dx;D.YDot:=D.YDot+Dy;
      XX:=D.XDot;YY:=D.YDot;
      xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
      yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
      D.XDot:=xx1;D.YDot:=yy1;
     end;
    Col.DeleteAll;
   end;
   For I:=0 to Twigs.AnyCount-1 do begin
    PD:=Twigs.AAt(I,W);PD1:=TPointClass(PD.ClassType).CreateAsPointDot_(PD,True);AnyLarge.Insert(PD1);
    PD1.Ugol:=PD1.Ugol+Ugol;
    PD1.XDot:=PD1.XDot+Dx;PD1.YDot:=PD1.YDot+Dy;
    XX:=PD1.XDot;YY:=PD1.YDot;
    xx1:=XB+((xx-Xb)*XKoef*cos(Ugol)-((yy-yb)*YKoef*sin(Ugol)));
    yy1:=YB+((xx-xb)*XKoef*sin(Ugol)+((yy-yb)*YKoef*cos(Ugol)));
    PD1.XDot:=xx1;PD1.YDot:=yy1;
    If PD1 is TDotText then begin
     If YKoef<>0 then begin
      TDotText(PD1).Text.Height:=TDotText(PD1).Text.Height*YKoef;
      //If XText<>0 then TDotText(PD1).XKoef:=XKoef*(XText);
     end;
    end else If PD1.TextManager<>nil then begin
     For J:=0 to PD1.TextManager.FValues.Count-1 do begin
      TP:=PD1.TextManager.FValues[J];
      If XKoef<>0 then TP.FW:=TP.FW*XKoef;
      If YKoef<>0 then TP.FH:=TP.FH*YKoef;
     end;
  end;
  end;
  Col.DeleteAll;Col.Free;
 // присваиваем временные коллекции примитивов
  OldTwigsLarge:=Twigs.TwigsLarge;
  Twigs.TwigsLarge:=TwigsLarge;
  OldLotsLarge:=Twigs.LotsLarge;
  Twigs.LotsLarge:=LotsLarge;
  OldAnyLarge:=Twigs.AnyLarge;
  Twigs.AnyLarge:=AnyLarge;
 end;
end;

function TGeoBlock.Draw(Canvas: TCanvas; XB, YB, Angle, XKoef, YKoef: Double;
 Extrusion, Inv: boolean): boolean;
var I,J:Integer;Lot:TLot;PD:TPointDot;B,UP,TP,AP:Byte;
    Dx,Dy:Double;XM,YM,ZM:AnsiString;
    PrecXY,PrecZ:Integer;
    Value:TPropValue;
    oldValue:AnsiString;
    Twig:TTwig;
    dupForm,oldForm:TForm2;
    D1,D2:TDot;
Function TwgDc:hDc;
begin
 Result := 0;
end;
begin
 Result:=False;
//  writeln('Draw');
 If TwgForm = nil then exit;
{ With TwgForm,GGraphSet do begin
  Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
  DrawLine(XB,YB,X+Dx,Y+Dy);
 end;}
// If not IsVisible(XB,YB,Angle,XKoef,YKoef,Extrusion) then begin
  //IsVisible(XB,YB,Angle,XKoef,YKoef,Extrusion);
//  Result:=True;exit;
// end;
 {  If not deVisible(XB,YB,Angle,XKoef,Ykoef) then begin
    Result:=True;exit;
   end;
  } 
 // подготавливаем атрибуты (считываем значения после запятой)
 PrecXY:=Const_Of_PrecCoord;PrecZ:=Const_Of_PrecHeight;
{
 If Properties<>nil then begin
  If Properties.PropValue['$XY']<>nil then try PrecXY:=Properties.PropValue['$XY'].AsInteger;except end;
  If Properties.PropValue['$Z']<>nil then try PrecZ:=Properties.PropValue['$Z'].AsInteger;except end;
 end;
}
 With Selector do
 If (XRasst(Width)<=GGraphSet.fPntZnk) and (YRasst(Height)<=GGraphSet.fPntZnk) then begin
  Case emptyBlock of
   0:deRect(0,XB,YB,Angle,XKoef,Ykoef);
   1:deRect(TAlphaColors.Blue,XB,YB,Angle,XKoef,Ykoef);
   2:deRound(TAlphaColors.Red,XB,YB,Angle,XKoef,Ykoef);
   3:deRound(TAlphaColors.Blue,XB,YB,Angle,XKoef,Ykoef);
   4:deTriag(TAlphaColors.Red,XB,YB,Angle,XKoef,Ykoef,false);
   5:deRomb(0,XB,YB,Angle,XKoef,YKoef);
   6:deTriag(TAlphaColors.Red,XB,YB,Angle,XKoef,YKoef,true);
  end;
  Result:=false;
  exit;
 end;
 if Block_Drawing then exit;
 Block_Drawing:=True;
// Stf:=TStringList.Create;
 dePaint(XB,YB,Angle,XKoef,Ykoef);
// Stf.SaveToFile('D:\stfText.txt');
// Stf.Free;
// экспериментальная рисовка
 Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
//
 With TwgForm,Selector,GGraphSet do begin
  UP:=GGraphSet.UslPoint;
  TP:=GGraphSet.TvdPoint;
  AP:=GGraphSet.AllPoint;
  GGraphSet.UslPoint:=0;
  GGraphSet.TvdPoint:=0;
  GGraphSet.AllPoint:=0;
  Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
  XBlock:=XB;YBlock:=YB;
//  DrawLine(XB,YB,X+Dx,Y+Dy);
//  P:=PCollection.Create(1);
//  Self.Move(Dx,Dy,Angle);
//  If not ((XKoef = 1) and (YKoef = 1) and (XText = 1))  then
//  Self.ScaleTo(XKoef,YKoef);
//  If Angle<>0 then
//  Self.Rotate(Angle);
//  If Extrusion then Self.DoExtrusion;
 // For I:=0 to Twigs.TwigsCount-1 do begin
//   Writeln(I,' ',TTwig(Twigs.TAt(I)).isVisible(GPRect));//Paint(Canvas.Handle);
//  end;
 // Self.ScaleTo(XKoef,YKoef);
{  For I:=0 to Twigs.TwigsCount-1 do begin
   If TTwig(Twigs.TAt(I)) is TTwigArc then begin
    Writeln('RadiusPered = ',TTwigArc(Twigs.TAt(I)).Radius);
   end;
   // TTwig(Twigs.TAt(I)).Draw;//Paint(Canvas.Handle);
  end;}
  try
  If LotView=1 then begin
   If FillLot=1 then begin
    For I:=0 to  TwgForm.Twigs.IndexCount-1 do begin
     Lot:=TwgForm.Twigs.LAtIndex(I);If Lot.ClassHandle.Check = 0 then continue;
     Lot.SetMinMax2(TwgForm.Twigs);
     If True {FMX} then Lot.Inv:=ord(Inv) else BlockGlobalWidth:=True;
     // If Lot.ClassHandle.Standart=1 then Lot.FillDraw(TwgForm.Twigs,TwgDc) else Lot.FillDraw2(TwgForm.Twigs,TwgDc);
     BlockGlobalWidth:=False;
      Lot.Inv:=0;
    end;
   end else
   For I:=0 to  TwgForm.Twigs.IndexCount-1 do begin
     Lot:=TwgForm.Twigs.LAtIndex(I);If Lot.ClassHandle.Check = 0 then continue;
     Lot.SetMinMax2(TwgForm.Twigs);
     If True {FMX} then Lot.Inv:=ord(Inv) else BlockGlobalWidth:=True;
    //  If Lot.ClassHandle.Standart=0 then Lot.FillDraw2(TwgForm.Twigs,TwgDc) else Lot.DrawRopLines(TwgForm.Twigs);
     BlockGlobalWidth:=False;
      Lot.Inv:=0;
   end;
  end else
  For I:=0 to Twigs.TwigsCount-1 do begin
   Twig:=Twigs.TAt(I);
   Twig.Inv:=ord(Inv);
   //Twig.Draw;//Paint(Canvas.Handle);
    For J:=0 to Twig.Coord.Count-2 do begin
 //    D1:=Twig.Coord[J];D2:=Twig.Coord[J+1];DrawLine(D1.XDot,D1.YDot,D2.XDot,D2.YDot);
    end;
   Twig.Inv:=0;
  end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin
 // двигаем точечные объекты
    If PD.ClassHandle.Check = 0 then continue;
    If PD.TextManager<>nil then begin
     Zm:='';Xm:=FloatToStrF(-PD.YDot,ffFixed,_LD,PrecXY);Ym:=FloatToStrF(PD.XDot,ffFixed,_LD,PrecXY);
     PD.TextManager.SetSysSpatialData(Xm,Ym,Zm);
    end;
    oldValue:=#0;
    If (txtProperties<>nil) and (PD is TDotText) then If TDotText(PD).Text.AttrName<>'' then begin
     Value:=txtProperties.PropValue[TDotText(PD).Text.AttrName];
     If Value<>nil then begin
      oldValue:=TDotText(PD).Text.Text;
      TDotText(PD).Text.Text:=Value.Value;
      TDotText(PD).Selected:=Inv;
     end;
    end;
    //PD.Draw(Canvas.Handle,MkLib.PSLib);   fmx
    If oldValue<>#0 then begin
     TDotText(PD).Text.Text:=oldValue;
     TDotText(PD).Selected:=False;
    end;
   end;
  end;
  finally
  Block_Drawing:=False; // отрисовали блок, установили признак отрисованного блока
  GGraphSet.UslPoint:=UP;
  GGraphSet.TvdPoint:=TP;
  GGraphSet.AllPoint:=AP;
  Twigs.TwigsLarge.Free;Twigs.LotsLarge.Free;Twigs.AnyLarge.Free;
  Twigs.TwigsLarge:=oldTwigsLarge;Twigs.LotsLarge:=oldLotsLarge;Twigs.AnyLarge:=oldAnyLarge;
//   If Extrusion then DoExtrusion;
//   Self.Move(-Dx,-Dy,0);
//    If Angle<>0 then                         
//     Self.Rotate(-Angle);
//   If not ((XKoef = 1) and (YKoef = 1)) then
//    Self.ScaleTo(-XKoef,-YKoef);
 // Self.ScaleTo(-XKoef,-YKoef);
 { For I:=0 to Twigs.TwigsCount-1 do begin
   If TTwig(Twigs.TAt(I)) is TTwigArc  then begin
   end;
   // TTwig(Twigs.TAt(I)).Draw;//Paint(Canvas.Handle);
  end;}
  end;
 end;
// DrawMarker(Canvas);
 Result:=True;
end;

function TGeoBlock.Draw32(Drawer: TogsDrawer; XB, YB, Angle, XKoef,
  YKoef: Double; Extrusion, Inv: boolean): boolean;
var I,J:Integer;Lot:TLot;PD:TPointDot;B,UP,TP,AP:Byte;
    Dx,Dy:Double;XM,YM,ZM:String;
    PrecXY,PrecZ:Integer;
    Value:TPropValue;
    oldValue:String;
    Twig:TTwig;
    dupForm,oldForm:TForm2;
    D1,D2:TDot;
    Sect:TShortSect;
begin
 // ïîäãîòàâëèâàåì àòðèáóòû (ñ÷èòûâàåì çíà÷åíèÿ ïîñëå çàïÿòîé)
 If not deVisible(XB,YB,Angle,XKoef,YKoef,Sect) then begin
  Result:=True;exit;
 end;
//
 Block_Drawing:=True; // îòðèñîâàëè áëîê, óñòàíîâèëè ïðèçíàê îòðèñîâàííîãî áëîêà
 dePaint(XB,YB,Angle,XKoef,Ykoef);
 PrecXY:=Const_Of_PrecCoord;PrecZ:=Const_Of_PrecHeight;
 If (Selector.XRasst(Width)<=GGraphSet.fPntZnk) and (Selector.YRasst(Height)<=GGraphSet.fPntZnk)
     and (not GlobalRender) then exit;
 //dePaint(XB,YB,Angle,XKoef,Ykoef);
 With TwgForm,GGraphSet do begin
  Dx:=XB-(X+TwgForm.XXMin);Dy:=YB-(Y+TwgForm.YYMin);
  XBlock:=XB;YBlock:=YB;
  try
   For I:=0 to  TwgForm.Twigs.IndexCount-1 do begin
     Lot:=TwgForm.Twigs.LAtIndex(I);If Lot.ClassHandle.Check = 0 then continue;
     Lot.SetMinMax2(TwgForm.Twigs);
     Lot.Draw32(TwgForm.Twigs);
   end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin
 // äâèãàåì òî÷å÷íûå îáúåêòû
    If PD.ClassHandle.Check = 0 then continue;
    If PD.TextManager<>nil then begin
     Zm:='';Xm:=FloatToStrF(-PD.YDot,ffFixed,_LD,PrecXY);Ym:=FloatToStrF(PD.XDot,ffFixed,_LD,PrecXY);
     PD.TextManager.SetSysSpatialData(Xm,Ym,Zm);
    end;
    oldValue:=#0;
    If (txtProperties<>nil) and (PD is TDotText) then If TDotText(PD).Text.AttrName<>'' then begin
     Value:=txtProperties.PropValue[TDotText(PD).Text.AttrName];
     If Value<>nil then begin
      oldValue:=TDotText(PD).Text.Text;
      TDotText(PD).Text.Text:=Value.Value;
     end;
    end;
    PD.Draw32(Drawer,TwgForm.MkLib.PSLib,TwgForm.FontColEx);
    If oldValue<>#0 then begin
     TDotText(PD).Text.Text:=oldValue;
     TDotText(PD).Selected:=False;
    end;
   end;
  end;
  finally
  Block_Drawing:=False; // îòðèñîâàëè áëîê, óñòàíîâèëè ïðèçíàê îòðèñîâàííîãî áëîêà
  GGraphSet.UslPoint:=UP;
  GGraphSet.TvdPoint:=TP;
  GGraphSet.AllPoint:=AP;
  Twigs.TwigsLarge.Free;Twigs.LotsLarge.Free;Twigs.AnyLarge.Free;
  Twigs.TwigsLarge:=oldTwigsLarge;Twigs.LotsLarge:=oldLotsLarge;Twigs.AnyLarge:=oldAnyLarge;
  end;
 end;
end;

procedure TGeoBlock.DrawMarker(Canvas: TCanvas);
var Pn:hPen;
begin
 {With TwgForm,Selector do begin
  Pn:=SelectObject(GCanvas.Handle,CreatePen(ps_Solid,0,clMaroon));
   PRectEx2(XXMin+X,YYMin+Y,4);
  DeleteObject(SelectObject(GCanvas.Handle,Pn));
  Pn:=SelectObject(GCanvas.Handle,CreatePen(ps_Solid,0,clLime));
   PRectEx2(XXMin+X,YYMin+Y,3);
  DeleteObject(SelectObject(GCanvas.Handle,Pn));
  Pn:=SelectObject(GCanvas.Handle,CreatePen(ps_Dot,0,clRed));
  SetBkMode(GCanvas.Handle,TransParent);
   With blockRect do begin
//    PMoveTo(Left,Top);PLineTo(Right,Top);PLineTo(Right,Bottom);PLineTo(Left,Bottom);PLineTo(Left,Top);
   end;
  DeleteObject(SelectObject(GCanvas.Handle,Pn));
 end;
 }
end;

function TGeoBlock.GetCheck: byte;
begin
 Result:=Check;
end;

procedure TGeoBlock.SetCheck(const Value: byte);
begin
 Check:=Value;
end;

function TGeoBlock.GetName: AnsiString;
begin
 Result:=Name;
end;

class function TGeoBlock.objType: Integer;
begin
 Result:=TWG_Block;
end;

function TGeoBlock.RotateDots(XX, YY, Angle, Dx, Dy: Double; var Col: PCollection): boolean;
var I:Integer;Dot:TDot;Dxx,Dyy:Double;XXX,YYY:Double;X0,Y0:Double;
    XX1,YY1:Double;
begin
 Result:=False;
  XX:=XX+TwgForm.XXMin;YY:=YY+TwgForm.YYMin;
  TwgForm.Rotate(XX,YY,Angle,XX1,YY1);
  For I:=0 to Col.Count-1 do begin
   Dot:=Col[I];
   TwgForm.Rotate(0,0,Angle,Dot.XDot,Dot.YDot);
   XXX:=XX;YYY:=YY;
   TwgForm.Rotate(XXX,YYY,Angle,XXX,YYY);
   Dxx:=XXX-XX;Dyy:=YYY-YY;
   TwgForm.Move(-Dxx,-Dyy,Dot.XDot,Dot.YDot);
  end;
 Result:=True;
end;

procedure TGeoBlock.Rotate(Angle: Double);
var I:Integer;PD:TPointDot;B:Byte;Col:PCollection;
    Twig:TTwig;
begin
 With TwgForm do begin
 Col:=PCollection.Create(1);
 // вычисляем смещение
  For I:=1 to Twigs.TwigsCount-1 do begin // смещаем ветки
   Twig:=Twigs.TAt(I);RotateDots(X,Y,Angle,0,0,Twig.TwigCoord);Twig.Calculate;
  end;
  For I:=0 to Twigs.LotsCount-1 do begin
   TLot(Twigs.LAt(I)).RotationPoints(Col);
   TLot(Twigs.LAt(I)).SetMinMax(TwgForm.Twigs);
  end;
  For I:=0 to Twigs.AnyCount-1 do begin
   PD:=Twigs.AAt(I,B);
   If B=TWG_Point then begin Col.Insert(PD);PD.Ugol:=PD.Ugol+Angle;end;
  end;
 end;
 RotateDots(X,Y,Angle,0,0,Col);
 Col.DeleteAll;Col.Free;
//TwgForm.XXMin:=TwgForm.XXMin+Dx;TwgForm.YYMin:=TwgForm.YYMin+Dy;
end;

procedure TGeoBlock.ScaleTo(XKoef, YKoef: Double;TempDrawing:Boolean = False);
var I,J:Integer;Twig:TTwig;Dot:TDot;
    Dx,Dy:Double;XX,YY:Double;
    PD:TPointDot;B:Byte;
    TM:TTextManager;
    TP:TTextParams;
Procedure ScalePoint(P:TDot);
begin
 Dx:=P.XDot-XX;Dy:=P.YDot-YY;
   If XKoef > 0 then begin
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Do=',Dot.XDot:8:4,' ',I,' = ',J);
    P.XDot:=XX+Dx*XKoef;
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Do=',Dot.XDot:8:4,' ',Dx:8:4,' ',XKoef:8:4);
    P.YDot:=YY+Dy*YKoef;//*Sin(Angle);
   end else begin
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Posle=',Dot.XDot:8:4,' ',I,' = ',J);
    P.XDot:=XX-Dx/XKoef;
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Posle=',Dot.XDot:8:4,' ',Dx:8:4,' ',XKoef:8:4);
    P.YDot:=YY-Dy/YKoef;//*Sin(Angle);
   end;
end;
begin
//exit;
// перемещаем точки относительно точки привязки
If XKoef=0 then exit;
// Writeln('Set==',XKoef,' ',YKoef);
// Writeln('===============');
XX:=X+TwgForm.XXMin;YY:=Y+TwgForm.YYMin;
With TwgForm do begin
 For I:=1 to Twigs.TwigsCount-1 do begin
  Twig:=Twigs.TAt(I);
  If TempDrawing then Twig.ArcView:=1;
//  Writeln(Twig.ClassName,' ',Twig.Coord.Count);
  For J:=0 to Twig.Coord.Count-1 do begin
   Dot:=Twig.Coord.FList[J];
   Dx:=Dot.XDot-XX;Dy:=Dot.YDot-YY;
   If XKoef > 0 then begin
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Do=',Dot.XDot:8:4,' ',I,' = ',J);
    Dot.XDot:=XX+Dx*XKoef;
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Do=',Dot.XDot:8:4,' ',Dx:8:4,' ',XKoef:8:4);
    Dot.YDot:=YY+Dy*YKoef;//*Sin(Angle);
    //PSetPixel(Dot.XDot,Dot.YDot);
   end else begin
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Posle=',Dot.XDot:8:4,' ',I,' = ',J);
    Dot.XDot:=XX-Dx/XKoef;
//    If J in [1,2] then If Twig is TTwigArc then Writeln('Posle=',Dot.XDot:8:4,' ',Dx:8:4,' ',XKoef:8:4);
    Dot.YDot:=YY-Dy/YKoef;//*Sin(Angle);
    //PSetPixel(Dot.XDot,Dot.YDot);
   end;
  end;
  If TempDrawing then Twig.ArcView:=0;
  Twig.Calculate;
{  Twig:=TTwig.CreateAsTwig(Twig,True);
  SetRop2(GCanvas.Handle,R2_Not);
  Twig.Paint(GCanvas.Handle);
  SetRop2(GCanvas.Handle,R2_CopyPen);
  Twig.Free; }
 end;
//Writeln('===============');
 For I:=0 to Twigs.LotsCount-1 do TLot(Twigs.LAt(I)).SetMinMax(TwgForm.Twigs);
 For I:=0 to Twigs.AnyCount-1 do begin
  PD:=Twigs.AAt(I,B);
  If B=TWG_Point then begin
   Dx:=PD.XDot-XX;Dy:=PD.YDot-YY;
   If XKoef > 0 then begin
    PD.XDot:=XX+Dx*XKoef;
    PD.YDot:=YY+Dy*YKoef;
   end else begin
    PD.XDot:=XX-Dx/XKoef;
    PD.YDot:=YY-Dy/YKoef;
   end;
   If PD is TDotText then begin
    If YKoef<>0 then begin
     If YKoef>0 then TDotText(PD).Text.Height:=TDotText(PD).Text.Height*YKoef else
                                     TDotText(PD).Text.Height:=TDotText(PD).Text.Height/abs(YKoef);
     If XText<>0 then If YKoef>0 then TDotText(PD).XKoef:=XKoef*(XText) else TDotText(PD).XKoef:=XText/abs(XText);
    end;
   // If XKoef<>0 then If XKoef>0 then PD.XKoef:=(PD.XKoef*XKoef) else PD.XKoef:=PD.XKoef- PD.XKoef/XKoef;
   end;
   TM:=PD.TextManager;
   If TM<>nil then begin
   // TM:=TM.CreateAsTextManager(TM,GPointCol);
    For J:=0 to PD.TextManager.FValues.Count-1 do begin
     TP:=PD.TextManager.FValues[J];
     If XKoef<>0 then begin If XKoef>0 then TP.FW:=TP.FW*XKoef else TP.FW:=TP.FW/abs(XKoef){ else TP.FH:=TP.FH/XKoef; }end;
     If YKoef<>0 then begin If YKoef>0 then TP.FH:=TP.FH*YKoef else TP.FH:=TP.FH/abs(YKoef){ else TP.FW:=TP.FW/YKoef;}end;
    end;
  end;
 end;
 end;
end;
end;

procedure TGeoBlock.bumToTwgForm(toForm:TForm2;UndoBum:Boolean;CalcGabarites:Boolean;PackTwigs:Boolean);
var I,J:Integer;F:TForm2;
    PD:TPointDot;Lot:TLot;Twig:TTwig;
    B:Byte;
    LocalTransAction:Boolean;
    fView:TFontViewEx;
begin
 F:=TwgForm;
 For I:=0 to F.Twigs.AnyCount-1 do begin
  PD:=F.Twigs.AAt(I,B);
  If B = TWG_Point then begin

//  If PD.TextManager<>nil thn With PD.TextManager do Writeln('BUMValue=',TTextParams(fValues[0]).fValue,' ',I);
   PD:=TPointClass(PD.ClassType).CreateAsPointDot_(PD,True);
//  If PD.TextManager<>nil then With PD.TextManager do Writeln('BUMValue2=',TTextParams(fValues[0]).fValue,' ',I);

    toForm.Twigs.Insert(Twg_Point,PD);
   { If PD is TDotText then TDotText(PD).Text.fontView:=toForm.FontColEx.AddFontView(Selector.GCanvas.Handle,TDotText(PD).Text.fontView);
     fmx}
   end;

  end;
 For I:=0 to F.Twigs.LotsCount-1 do begin
  Lot:=F.Twigs.LAt(I);
   Lot:=TLotClass(Lot.ClassType).CreateAsLotWithAll(Lot);
   Lot.ClassHandle:=toForm.LayerTable.SearchLayer(Lot.ClassCode);
    For J:=0 to Lot.Coord.Count-1 do begin
     Twig:=TTwigClass(Lot.GetTwig(F.Twigs,J).ClassType).CreateAsTwig(Lot.GetTwig(F.Twigs,J),True);
     Twig.Calculate;
      toForm.Twigs.Insert(Twg_Twig,Twig);
      TLong(Lot.Coord[J]).Num:=toForm.Twigs.TwigsCount-1;
     end;
   Lot.SetMinMax(toForm.Twigs);
    toForm.Twigs.Insert(TWG_Lot,Lot);
    Lot.SetFromTwig(toForm.Twigs);
 end;
 If CalcGabarites then toForm.SetGabaritesPrivate;
end;

function TGeoBlock.Height: Double;
begin
 Result:=TwgForm.YYMax-TwgForm.YYMin;
end;

function TGeoBlock.Width: Double;
begin
 Result:=TwgForm.XXMax-TwgForm.XXMin;
end;

function TGeoBlock.rectHeight: Double;
begin
 With blockRect do Result:=Bottom-Top;
end;

function TGeoBlock.rectWidth: Double;
begin
 With blockRect do Result:=Right-Left;
end;


function TGeoBlock.LayerExists(PR: TResource): Boolean;
var I:Integer;B:Byte;Lot:TLot;PD:TPointDot;
begin
 Result:=True;
 For I:=0 to TwgForm.Twigs.LotsCount-1 do begin
  Lot:=TwgForm.Twigs.LAt(I);
  If Lot.ClassHandle = PR then exit;
 end;
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassHandle = PR then Exit;
 end;
 Result:=False;
end;

function TGeoBlock.isVisible(toX, toY, Angle, XKoef, YKoef: Double;Extrusion:boolean): Boolean;
var Sect:TShortSect;Col:PCollection;
    Dx,Dy,Dxx,Dyy,XX,YY,XXX,YYY:Double;
    XMin,YMin,XMax,YMax:Double;
    I:Integer;
Procedure ExtrusionPoint(var XP,YP:Double);
begin
 XP:=XP+(toX-XP)*2;
end;
begin
// result:=True;exit;
 Sect.Left:=blockRect.Left;Sect.Top:=blockRect.Top;Sect.Right:=blockRect.Right;Sect.Bottom:=blockRect.Bottom;
 If not ((XKoef=1) and (YKoef=1)) then begin
  XX:=X+TwgForm.XXMin;YY:=Y+TwgForm.YYMin;
  Dx:=Sect.Left-XX;Dy:=Sect.Top-YY;Sect.Left:=XX+Dx*XKoef;Sect.Left:=YY+Dy*XKoef;
  Dx:=Sect.Right-XX;Dy:=Sect.Bottom-YY;Sect.Right:=XX+Dx*XKoef;Sect.Bottom:=YY+Dy*XKoef;
 end;
 Dx:=toX-(X+TwgForm.XXMin);Dy:=toY-(Y+TwgForm.YYMin);
 TwgForm.Move(Dx,Dy,Sect.Left,Sect.Top);TwgForm.Move(Dx,Dy,Sect.Right,Sect.Bottom);
 If Angle<>0 then begin
  Col:=PCollection.Create(4);
   Col.Insert(TDot.Create(Sect.Left,Sect.Top,0));Col.Insert(TDot.Create(Sect.Right,Sect.Top,0));Col.Insert(TDot.Create(Sect.Right,Sect.Bottom,0));Col.Insert(TDot.Create(Sect.Left,Sect.Bottom,0));
   XMin:=10000000;YMin:=10000000;XMax:=-10000000;YMax:=-10000000;
   For I:=0 to Col.Count-1 do With TDot(Col.FList[I]) do begin
    TwgForm.Rotate(0,0,Angle,XDot,YDot);
    XXX:=toX;YYY:=toY;
    TwgForm.Rotate(XXX,YYY,Angle,XXX,YYY);
    Dxx:=XXX-toX;Dyy:=YYY-toY;
    TwgForm.Move(-Dxx,-Dyy,XDot,YDot);
    If XDot>XMax then XMax:=XDot;If XDot<XMin then XMin:=XDot;
    If YDot>YMax then YMax:=YDot;If YDot<YMin then YMin:=YDot;
   end;
   Sect.Left:=XMin;Sect.Top:=YMin;Sect.Right:=XMax;Sect.Bottom:=YMax;
  Col.Free;
 end;
// With Sect do PRectangle(Sect.Left,Sect.Bottom,Sect.Right,Sect.Top);
 If Extrusion then begin
  ExtrusionPoint(Sect.Left,Sect.Top);
  ExtrusionPoint(Sect.Right,Sect.Bottom);
 end;
// PSetPixel(Sect.Left,Sect.Top);//,Sect.Right,Sect.Bottom);
// PSetPixel(Sect.Right,Sect.Bottom);//,Sect.Right,Sect.Bottom);
 SSect:=Sect;
 With Selector,GRect do begin
  If Sect.Right<Left then begin Result:=False;Exit;end;
  If Sect.Left>Right then begin Result:=False;Exit;end;
  If Sect.Top>Top then begin Result:=False;Exit;end;
  If Sect.Bottom<Bottom then begin Result:=False;Exit;end;
 end;
 Result:=True;
end;

procedure TGeoBlock.GetObjectProps(propNames, propValues, propTypes: TStrings;Data:Pointer = nil);
var PD:TDotText;I:Integer;B:Byte;Value:TPropValue;S:AnsiString;
begin
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassName = 'TDotText' then If PD.Text.AttrName<>'' then begin
   propNames.Add(PD.Text.AttrName);
   If Properties=nil then Value:=nil else begin S:=GetProperty(PD.Text.AttrName); If S<>byLayer then propValues.Add(S) else Value:=nil; end;
   If Value = nil then propValues.Add(PD.Text.Text);
   propTypes.Add('AnsiString');
  end;
 end;
end;

function TGeoBlock.GetProperty(propName: AnsiString): AnsiString;
var PD:TDotText;I:Integer;B:Byte;Value:TPropValue;
begin
 Result:=byLayer;
 If Properties=nil then exit;
 Value:=Properties.PropValue[propName];
 If Value = nil then Result:=byLayer else begin Result:=Value.Value;exit;end;
 If TxtProperties<>nil then begin
  Value:=TxtProperties.PropValue[propName];
  If Value<>nil then begin Result:=Value.Value;exit; end else Result:=byLayer;
 end;
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassName = 'TDotText' then If PD.Text.Text<>'' then If PD.Text.AttrName=propName then begin
   Result:=PD.Text.Text;exit;
  end;
 end;
end;

function TGeoBlock.GetProperty2(propName: AnsiString): AnsiString;
var PD:TDotText;I:Integer;B:Byte;Value:TPropValue;
begin
 Result:=byLayer;
 If Properties=nil then exit;
 Value:=Properties.PropValue[propName];
 If Value = nil then Result:=byLayer else begin Result:=Value.Value;end;
 If TxtProperties<>nil then begin
  Value:=TxtProperties.PropValue[propName];
  If Value<>nil then begin Result:=Value.Value;exit; end else Result:=byLayer;
 end;
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassName = 'TDotText' then If PD.Text.Text<>'' then If PD.Text.AttrName=propName then begin
   Result:=PD.Text.Text;exit;
  end;
 end;
end;

procedure TGeoBlock.GetPropMerge(Obj: TTD; propNames, propValues, propTypes: TStrings);
var PD:TDotText;I, Index:Integer;B:Byte;Value:TPropValue;
begin
exit;
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassName = 'TDotText' then If PD.Text.Text<>'' then begin
   Index:=propNames.IndexOf(PD.Text.AttrName);If Index<>-1 then propNames.Objects[Index]:=Self;
  end;
 end;
 For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
  propNames.Delete(I);
  propValues.Delete(I);
  propTypes.Delete(I);
 end;
end;

function TGeoBlock.SetProperty(propName: AnsiString; propValue: AnsiString; Obj: TTD): boolean;
var PD:TDotText;I:Integer;B:Byte;Value:TPropValue;
begin
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD.ClassName = 'TDotText' then If PD.Text.AttrName=propName then begin
   Properties.AddProperty(PD.Text.AttrName,propValue);exit;
  end;
 end;
end;

function TGeoBlock.UseProperty(propName: AnsiString): boolean;
var PD:TDotText;I:Integer;B:Byte;
begin
 For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
  PD:=TwgForm.Twigs.AAt(I,B);
  If PD is TDotText then If PD.Text.AttrName<>'' then If PD.Text.AttrName = propName then begin
   Result:=True;exit;
  end;
 end;
end;

function TGeoBlock.ResetParams(ParamID: Integer;Params: Pointer):boolean;
var I:Integer;PP:TPointDot;B:Byte;
begin
 If TwgForm = nil then exit;
 Case ParamID of
 1:For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
    PP:=TwgForm.Twigs.AAt(I,B);
    PP.ResetParams(param_idResetFontView,Params);
   end;
 end;
end;

procedure TGeoBlock.ChangeXYKoef(XK, YK: Double);
begin
//
end;

procedure TGeoBlock.SetAttribs(outProps, myProps: TProperties);
var Value:TPropValue;I:Integer;
begin
 If (Properties=nil) then exit;
 For I:=0 to outProps.Count-1 do begin
  Value:=Properties.PropValue[outProps[I].propName];
  if Value<>nil then myProps.AddProperty(outProps[I].propName,Value.Value);
  Properties.AddProperty(outProps[I].propName,outProps[I].propValue.Value);
 end;
end;

procedure TGeoBlock.ResetAttribs(inProps: TProperties);
var I:Integer;
begin
 if Properties = nil then exit;
 For I:=0 to inProps.Count-1 do
  Properties.AddProperty(inProps[I].propName,inProps[I].PropValue.Value);
end;

function TGeoBlock.UseTextProps: boolean;
var I:Integer;B:Byte;PD:TPointDot;
 Value:TPropValue;
begin
Result:=False;
For I:=0 to TwgForm.Twigs.AnyCount-1 do begin
 PD:=TwgForm.Twigs.AAt(I,B);
 If (txtProperties<>nil) and (PD is TDotText) then If TDotText(PD).Text.AttrName<>'' then begin
     Value:=txtProperties.PropValue[TDotText(PD).Text.AttrName];
  If Value<>nil then begin
   Result:=True;exit;
  end;
 end;
end;
end;



initialization
end.
