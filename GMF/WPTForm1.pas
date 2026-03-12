Unit WPTForm1;
Interface uses WpTwigs, Collect, WPTForm0, WpArcs, EcLot, HatchLot,
               EcDot, newSelector, SysUtils, newProcs, newForm0, newConsts,
               Math, Classes, TwgColle, newResource, newFontScale, newSettings,
               UpdateMessages, ECText,
               WpRects;
{}
  Type
  TMinMax=Record XMax,YMax,YMin,XMin,Koeff:Extended;end;

  TSortTextNum=class(TSortedCollection)
   function Compare(Key1,Key2:Pointer):Integer;override;
  end;

{ Указательный файл-содержит информацию о графических объектах         }

Type
  TForm1=Class(TForm0)
  private
    function GetModified: boolean;
    procedure SetModified(const Value: boolean);virtual;
  public
 {}
    GloLot:TLot;
    GloLot2:TLot;
    GTwigArc:TTwigArc;
    GTwigSpline:TTwigSpline;
    GTwigCircle:TTwigCircle;
    ClName:AnsiString;
    Visible:Boolean;
    GabaritesFlag:Boolean;
    FGraphSet:TGraphSet;
    ActiveLotIndex:FixedInt; // индекс активного контура
    MirrorObject:Boolean;
  {}
    Settings:TSettings;
  {}
    OnSetGabarites:TNotifyEvent;
  {}
    TaheoFileName:AnsiString;
  //
    FontColEx:TFontManagerEx;
    Modified2:boolean;
    urlNum,dbNAme:AnsiString;
    Selector:TSelector;
  // старье
    ActiveTwig:TSortTextNum;
    ActiveText:TSortTextNum;
    ActiveLotZnak:TSortTextNum;

        Constructor  Create(Count1:Byte);
         Constructor Load   (Stream :TBufStream);override;
         Procedure CreateLayersView(Layers:PCollection;Znaks:PCollection = nil;MapInfo:Boolean =False);virtual;abstract;
         Procedure Store  (Stream :TBufStream);override;
         Function  CreateUndoView:AnsiString;// создает объект на диске для Undo
         Function  GetUndoMax:AnsiString;// возвращает последний объект Undo
         Destructor Destroy;override;
         Procedure StoreMkLib;
         Procedure Pack(OnModifiedPrim:procModifiedPrim);virtual;abstract;
	{}
         Procedure SetCoor(VX,VY:Extended);
         Procedure RestoreCoords;
         Procedure SetGabaritesPrivate;
         Procedure SetGabarites;
         Procedure LoadClassLib(CreateLayerTable:boolean=False);
         Procedure StoreClassLib;
         Procedure ClassBuildII;
         Procedure ClassBuildIII;
        {}
         Function  LotIndex(L:TLot):Integer;
         Procedure DelLot(L:TLot);
         Procedure DrawTempTwig;
         Procedure ClearObject;
        {}
        {}
         Procedure CreateViewArc;
         Procedure FreeViewArc;
         Function  MakeLineLot: boolean;
      	 Function	 MakeLot(PT:TResource):TLot;
        {}
         Function  SetLotFromTwigs(LotNum:LongInt):Double;
         Function  SortSqwear(C:LongInt):LongInt;
         Procedure SetSqwear;virtual;
         Procedure SetClearSqwear(Os:AnsiString='');virtual;
        {}
         Function  ObjectName:AnsiString;
//         Function GetHandLot:Integer;
      Property Modified:boolean read GetModified write SetModified;
   end;

{------------------------------------------------------}


Implementation uses newClassBuilder, newLayersTable, DWGText, EcDot2, newBlock,
                    TextManager, Writer, System.Types;

{ TSortTextNum }

function TSortTextNum.Compare(Key1, Key2: pointer): Integer;
var K1,K2:TWhatFont;
begin
 if TLong(Key1).Num>TLong(Key2).Num then
    Result:=-1
 else
 if TLong(Key1).Num<TLong(Key2).Num then
    Result:=1
 else
    Result:=0;
end;

{ TForm1 }

  Procedure TForm1.SetCoor;
	 var I,J,K:LongInt;
             D:TDot;
             Twig:TTwig;
             PD:TPointDot;
             P:Pointer;
             W:Byte;
             F:TEFont;
             Lot:TLot;
  begin
    For I:=1 to Twigs.TwigsCount-1 do
      begin
       Twig:=Twigs.TAt(I);
        For J:=0 to Twig.Coord.Count-1 do
         begin
          D:=Twig.Coord[J];
          D.YDot:=D.YDot+VY;
          D.XDot:=D.XDot-VX;
         end;
      end;
    For I:=0 to Twigs.LotsCount-1 do
      begin
       Lot:=Twigs.LAt(I);
       If Lot.DataFonts<>nil then
         begin
           F:=Lot.DataFonts[0];
            F.YF:=F.YF+VY;
            F.XF:=F.XF-VX;
         end;
        If Lot.Fonts<>nil then
        For J:=0 to Lot.Fonts.Count-1 do
         begin
           F:=Lot.Fonts[J];
            F.YF:=F.YF+VY;
            F.XF:=F.XF-VX;
         end;
        if Lot.Lines<>nil then
        For J:=0 to Lot.Lines.Count-1 do
         begin
          Twig:=Lot.Lines[J];
          For K:=0 to Twig.Coord.Count-1 do
           begin
            D:=Twig.Coord[K];
            D.YDot:=D.YDot+VY;
            D.XDot:=D.XDot-VX;
           end;
         end;
      end;
     For I:=0 to Twigs.AnyCount-1 do
      begin
       P:=Twigs.AAt(I,W);
        If W=Twg_Font then
         begin
           F:=P;
            F.YF:=F.YF+VY;
            F.XF:=F.XF-VX;
            F.Y2:=F.Y2+VY;
            F.X2:=F.X2-VX;
         end else
        If W=Twg_Point then
         begin
          PD:=P;
          PD.YDot:=PD.YDot+VY;
          PD.XDot:=PD.XDot-VX;
         if PD.Lines<>nil then
         For J:=0 to PD.Lines.Count-1 do
          begin
           Twig:=PD.Lines[J];
           For K:=0 to Twig.Coord.Count-1 do
            begin
             D:=Twig.Coord[K];
             D.YDot:=D.YDot+VY;
             D.XDot:=D.XDot-VX;
            end;
          end;
         end;
      end;
     About.XMax:=About.XMax{+About.XMin};
     About.YMax:=About.YMax{+About.YMin};
     About.XMin:=0;
     About.YMin:=0;
     SetGabarites;
   end;


  Procedure TForm1.RestoreCoords;
	 var I,J,K:LongInt;
             D:TDot;
             Twig:TTwig;
             P:Pointer;
             W:Byte;
             F:TEFont;
             Lot:TLot;
  begin
    For I:=1 to Twigs.TwigsCount-1 do
      begin
       Twig:=Twigs.TAt(I);
        For J:=0 to Twig.Coord.Count-1 do
         begin
          D:=Twig.Coord[J];
          D.XDot:=D.XDot+About.XMin;
          D.YDot:=D.YDot-About.YMin;
         end;
      end;
    For I:=0 to Twigs.LotsCount-1 do
      begin
       Lot:=Twigs.LAt(I);
        If Lot.DataFonts[0]<>nil then
         begin
           F:=Lot.DataFonts[0];
            F.XF:=F.XF+About.XMin;
            F.YF:=F.YF-About.YMin;
         end;
      end;
     For I:=0 to Twigs.AnyCount-1 do
      begin
       P:=Twigs.AAt(I,W);
        If W=Twg_Font then
         begin
           F:=P;
            F.XF:=F.XF+About.XMin;
            F.YF:=F.YF-About.YMin;
         end else
{        If W=Twg_Point then
         begin
          TD:=P;
          TD.XDot:=TD.XDot+About.XMin;
          TD.YDot:=TD.YDot-About.YMin;
         end;}
      end;
     About.XMax:=About.XMax{+About.XMin};
     About.YMax:=About.YMax{+About.YMin};
     About.XMin:=0;                                              
     About.YMin:=0;
   end;                                                                      


  Procedure TForm1.SetGabaritesPrivate;
   var I,J,K:LongInt;
       Twig:TTwig;
       TP:TPointDot;
       Lot:TLot;
       W:Byte;
       FF:TEfont;
       Sect:TSect;
       MRect:TMRect;
    Function AllTaheo:Boolean;
     var I,J:Integer;
     begin
      J:=0;
      For I:=0 to Twigs.CountTaheo-1 do
       begin
        J:=J+Twigs.TaheoDots[I].Count+Twigs.TaheoTwigs[I].Count;
       end;
      Alltaheo:=J=0;
     end;
      begin
       XXMin:=100000000;YYMin:=1000000000;XXMax:=-100000000;YYMax:=-100000000;
     //  Writein(['twc=',Twigs.TwigsCount]);
      If (Twigs.TwigsCount=1) and
        AllTaheo then
        begin
         try
          if Twigs.Bitmaps.Bitmaps.Count<>0 then
          begin
           Sect:=Twigs.Bitmaps.GetGabarites;
           If XXMin>Sect.Left then XXMin:=Sect.Left;
           If XXMax<Sect.Right then XXMax:=Sect.Right;
           If YYMin>Sect.Top then YYMin:=Sect.Top;
           If YYMax<Sect.Bottom then YYMax:=Sect.Bottom;
          end;
         Except
         end;
          if Twigs.Bitmaps.Bitmaps.Count=0 then
          begin
           Twig:=Twigs.TAt(0);
           Twig.SetMinMax;
            XXMin:=Twig.XMin;
            XXMax:=Twig.XMax;
            YYMin:=Twig.YMin;
            YYMax:=Twig.YMax;
          end;
          About.XMin:=0;About.YMin:=0;
         If Twigs.AnyCount<1 then exit;
        end;
   //  Writein(['next']);
     XXMin:=100000000;YYMin:=1000000000;XXMax:=-1000000000;YYMax:=-1000000000;
      For I:=1 to Twigs.TwigsCount-1 do
           begin
             Twig:=Twigs.TAt(I);
              If (Twig.Closed<>254)  then
                           begin
                            Twig.SetMinMax;
                             If XXMin>Twig.XMin then XXMin:=Twig.XMin;
                             If XXMax<Twig.XMax then XXMax:=Twig.XMax;
                             If YYMin>Twig.YMin then YYMin:=Twig.YMin;
                             If YYMax<Twig.YMax then YYMax:=Twig.YMax;
                           end;
			  end;
          For I:=0 to Twigs.LotsCount-1 do
           begin
             Lot:=Twigs.Lat(I);
             If Lot.TypeLot<>254 then begin
              Lot.SetMinMax(Twigs);
             end;
           end;
         // WriteIn(['SG1=',Twigs.AnyCount]);
     MRect:=TMRect.Create;
     For I:=0 to Twigs.AnyCount-1 do
      begin
       TP:=Twigs.AAt(I,W);
        If W=Twg_Point then
         begin
         // WriteIn(['GetS1 ', TP.XDot, TP.YDot, TP.ClassName]);

          Sect := TP.GetSect;//(MRect);
         // WriteIn(['GetS2 ', TP.XDot, TP.YDot, TP.ClassName]);
          // If XXMin>MRect.XMin then XXMin:=MRect.XMin;
          // If XXMax<MRect.YMax then XXMax:=MRect.YMax;
          // If YYMin>MRect.YMin then YYMin:=MRect.YMin;
         //  If YYMax<MRect.YMax then YYMax:=MRect.YMax;
           If XXMin>Sect.Left then XXMin:=Sect.Left;
           If XXMax<Sect.Right then XXMax:=Sect.Right;
           If YYMin>Sect.Top then YYMin:=Sect.Top;
           If YYMax<Sect.Bottom then YYMax:=Sect.Bottom;
        //   With Sect do WriteIn(['mrect=',Left, Top, Right, Bottom]);
         end;// else
        if W=Twg_Font then
         begin
          FF:=TEFont(Pointer(TP));
           If XXMin>FF.XF then XXMin:=FF.XF;
           If XXMax<FF.XF then XXMax:=FF.XF;
           If YYMin>FF.YF then YYMin:=FF.YF;
           If YYMax<FF.YF then YYMax:=FF.YF;
         // FF.ClassHandle.Standart:=1;
         end;
      end;
     MRect.Free;
      {
         try
          if Twigs.Bitmaps.Bitmaps.Count<>0 then
          begin
           Sect:=Twigs.Bitmaps.GetGabarites;
           If XXMin>Sect.Left then XXMin:=Sect.Left;
           If XXMax<Sect.Right then XXMax:=Sect.Right;
           If YYMin>Sect.Top then YYMin:=Sect.Top;
           If YYMax<Sect.Bottom then YYMax:=Sect.Bottom;
          end;
         Except
         end;}
     About.XMin:=0;About.YMin:=0;
 // WriteIn(['SG2=',XXMin, YYMin, XXMax, YYMax]);
 end;

 Procedure TForm1.SetGabarites;
 begin
   if Assigned(OnSetGabarites) then OnSetGabarites(Self);
 end;

Procedure TForm1.LoadClassLib;
var Layers:PCollection;
begin
{       Version:=VerConst;}
{        ShowMessage(MainPath+'\'+StrPas(About.ClassName));}
 ClName:=MainPath+Slash+SetSlashCorrect(About.ClassName);
 MkLib:=TMosLib.Create(ClName);
 MkLib.Selector := Selector;
 MkLib.LoadZnaks(About.ObjectName);
 If CreateLayerTable then begin
  If LayerTable<>nil then LayerTable.Free;
  LayerTable:=TLayerTable.Create(MkLib);
  {}
  Layers:=PCollection.Create(1);
  CreateLayersView(Layers);
   LayerTable.CreateLayersView(Layers);
  Layers.Free;
  LayerTable.MkLib:=MkLib;
  LayerTable.CreateSignView;
 end;
 MkLib.LayerTable:=LayerTable;
 LayerTable.MkLib:=MkLib;
 Selector.GPointCol:=MkLib.PSLib;Selector.GSqwearCol:=MkLib.SSLib;Selector.GLineCol:=MkLib.LSLib;
//  LayerTable.ResetChildsLayerMkLib;
 ClassRebuildBlock:=True;
 Build1(Selector,ClName,Twigs,MkLib);
end;

  procedure TForm1.StoreClassLib;
  begin
   // MkLib.StoreAll(MainPath+'\'+(About.ClassName));
  end;

  Constructor TForm1.Create;
   var I:LongInt;
   begin
    Selector := TSelector.Create(nil);
    FontColEx:=TFontManagerEx.Create(1);
    FillChar(ClName,SizeOf(ClName),#0);
    MemMake:='';
    MemMakeIndex:=-1;
     GabaritesFlag:=True;
    Visible:=True;
    TmpColl:=PCollection.Create(1);
    Twigs:=TTwigsCollect.Create(Selector);
    Twigs.TwgForm:=Self;
    ActiveTwig:=(TSortTextNum.Create(1));
   {}
    ActiveText:=(TSortTextNum.Create(1));
   {}
    ActiveLotZnak:=(TSortTextNum.Create(1));
    ActivePoint:=PCollection.Create(1);
    UndoColl:=PCollection.Create(1);
    ActivePoint2:=PCollection.Create(1);
    NotLink_Up:=PCollection.Create(1);
    Perehlests:=PCollection.Create(1);
    ActivePntLine:=PCollection.Create(1);
    NeedTwigs:=PCollection.Create(1);
    LotPoints:=PCollection.Create(1);
    ActiveHPoly:=PCollection.Create(1);
    TempPoints:=PCollection.Create(1);
    LineNesost:=PCollection.Create(1);
//    TempTwig:=TTwig.Create(Twig_Any);
    thTwig:=nil;
    ActiveLotBool:=False;
    OneLotNum:=-1;
     LotBool:=False;
     ActiveMapBool:=False;
     ActiveMap    :=-1;
     Parametr:=0;
    { Новые }
       LotActive:=PCollection.Create(1);
       LotTwig:=PCollection.Create(1);
      {}
       Modified:=False;
       fGraphSet:=GGraphSet;
    {}
     TransformPoints:=PCollection.Create(1);
    {}
     ActiveLotIndex:=-1;
     GloLot2:=nil;
     GTwigArc:=nil;
     GTwigSpline:=nil;
    {}
     ArcTwigs:=PCollection.Create(1);
     TTFViews:=PCollection.Create(1);
    {}
     Mklib:=nil;
     LayerTable:=nil;
     Settings:=TSettings.Create(500,'*');
     TaheoFileName:='';
     urlNum:='';dbName:='';
   end;

  Constructor TForm1.Load;
   var I,J:Integer;
       F:TextFile;
       PP:TPointDot;B:Byte;
       L:TLot;
       E:Exception;
       D:TDot;DB:Double;
       Layers:PCollection;
       ClFile: String;
   begin
     Selector:=Stream.Selector;
//     Undo:=TUndo.Create(Pointer(Self));
     MemMake:='';
     MemMakeIndex:=-1;
     GloLot2:=nil;
     GabaritesFlag:=True;
     ActiveLotIndex:=-1;
     {1000}
      LoadAbout(About,Stream);
      MirrorObject:=About.MirrorObject=1;
     If not MirrorObject then begin
      Selector.GTwgForm:=Self;
     // Selector.GRect := About.Fragment;
     end;
      Version:=About.Version;
         With About,Selector do
          begin
           Const_Of_DecimalCoord:=DecimalCoord;
           Const_Of_DecimalHeight:=DecimalHeight;
           Const_Of_DecimalLength:=DecimalLength;
           Const_Of_DecimalSqwear:=DecimalSqwear;
           Const_Of_SqwearMetric:=SqwearMetric;
           Const_Of_AngleMetric:=AngleMetric;
           Const_Of_DecimalAngle:=DecimalAngle;
           Const_Of_CalcDirect:=CalcDirect;
         {}
           Const_Of_PrecHeight:=Round(IntPower(10,DecimalHeight));
           Const_Of_PrecLength:=Round(IntPower(10,DecimalLength));
           Const_Of_PrecSqwear:=Round(IntPower(10,DecimalSqwear));
           Const_Of_PrecCoord :=Round(IntPower(10,DecimalCoord));
          {}
          end;
        Try
       If not MirrorObject then WriteIn(['LoadAbout=', Stream.Position]);
        If Version>47 then begin
          If not MirrorObject then begin FontColEx:=TFontManagerEx(Stream.Get);
           For I:=0 to FontColEx.Count-1 do TFontViewEx(FontColEx[I]).RecreateLoadedFonts(Selector.GCanvas);
           If not MirrorObject then Selector.GFontColEx:=FontColEx;
          end;
         end else If not MirrorObject then begin
          FontColEx:=TFontManagerEx.Create(1);
          If not MirrorObject then Selector.GFontColEx:=FontColEx;
         end;
        If not MirrorObject then  WriteIn(['FontCol', Stream.Position]);
	       Twigs:=TTwigsCollect(Stream.Get);
        If not MirrorObject then WriteIn(['TwgCol', Stream.Position]);
         Twigs.TwgForm:=Self;
         If not MirrorObject then begin
         end;
         if Version>20 then
          Stream.Read(fGraphSet,SizeOf(fGraphSet)) else fGraphSet:=GGraphSet;
          If not MirrorObject then WriteIn(['GraphSet', Stream.Position]);
        GGraphSet:=fGraphSet;
        GGraphSet:=fGraphSet;
        If (Version>35) then begin
         If not MirrorObject then begin
          Settings:=TSettings.Load(Stream);
           If not MirrorObject then WriteIn(['Settings=', Stream.Position]);
           If Version>44 then begin
            TaheoFileName:=Stream.ReadString;
            If not MirrorObject then WriteIn(['TaheoFN=', Stream.Position]);
           end else TaheoFileName:='';
         end;
        end else Settings:=TSettings.Create(500,'TForm.Load');
        // GGraphset:=fGraphSet;
        Except on E:Exception do begin
         Stream.Status:=100;
         raise Exception.Create('Неверный формат файла.');
        end;end;
    {}
//If not MirrorObject then WriteS(['Next1']);//      SetGabarites;
    If VerSion<=5 then
      begin
       RestoreCoords;
      end;
    {}
	 TmpColl:=PCollection.Create(1);
	 ActiveTwig:=(TSortTextNum.Create(1));
         ActiveText:=(TSortTextNum.Create(1));
	 ActiveLotZnak:=(TSortTextNum.Create(1));
	 ActivePoint:=PCollection.Create(1);
	 UndoColl:=PCollection.Create(1);
	 ActivePoint2:=PCollection.Create(1);
	 NotLink_Up:=PCollection.Create(1);
	 Perehlests:=PCollection.Create(1);
         ActivePntLine:=PCollection.Create(1);
    	 NeedTwigs:=PCollection.Create(1);
         ActiveLotBool:=False;
         OneLotNum:=-1;
	 ActiveMapBool:=False;
         ActiveMap    :=-1;
	 ActiveLotBool:=False;
         OneLotNum:=-1;
         LotBool:=False;
         LotPoints:=PCollection.Create(1);
         ActiveHPoly:=PCollection.Create(1);
         TempPoints:=PCollection.Create(1);
         LineNesost:=PCollection.Create(1);
//         TempTwig:=TTwig.Create(Twig_Any);
      { Новые }
       LotActive:=PCollection.Create(1);
       LotTwig:=PCollection.Create(1);
       TransformPoints:=PCollection.Create(1);
       thTwig:=nil;
       GTwigArc:=nil;
       GTwigSpline:=nil;
       ArcTwigs:=PCollection.Create(1);
       TTFViews:=PCollection.Create(1);
//   CollectVer:=10;
//   Version:=10;
      {}
       Modified:=False;
       MkLib:=nil;
     if Version<20 then
      With About do
       begin
        DecimalCoord:=3;
        DecimalHeight:=2;
        DecimalLength:=2;
        DecimalSqwear:=2;
        SqwearMetric:=0;
        AngleMetric:=0;
        DecimalAngle:=1;
        CalcDirect:=0;
       end;
      // Version:=VerConst;
      {}
      {}
   About.ClassName:=AnsiUpperCase(About.ClassName);
   //    WriteS(['Next2LoadLib=',MainPath+Slash+SetSlashCorrect(About.ClassName),FileExists(MainPath+Slash+SetSlashCorrect(AnsiUpperCase(About.ClassName)))]);
   // Writein(['ClassNAme=', MainPath+Slash+(ExtractFileName(About.ClassName))]);
    DelSubStr(About.ClassName, 'VCLASS\');
   If not MirrorObject then
    If FileExists(MainPath+(About.ClassName)) then
     begin
{       Version:=6;}
     ClName:=MainPath+(About.ClassName);
     ClassRebuildIndex:=True;
     ClassRebuildSbor:=True;
     Const_Of_PrecCoord:=Round(IntPower(10,About.DecimalCoord));
//    If not MirrorObject then Writeln('begin load Class');
      try
   //  If About.MyName = '4 этаж.gmf' then
   //   Writeln('1xxxx ',About.MyName);
       If About.Version>33 then begin
       If MirrorObject then LayerTable:=nil else begin
        try LayerTable:=TLayerTable(Stream.Get);except LayerTable := nil;end;
        If About.Version>56 then begin
         urlNum:=Stream.ReadString;
         dbName:=Stream.ReadString;
        end else begin
         urlNum:='';
         dbName:='';
        end;
        If LayerTable = nil then LoadClassLib(True);
//        LayerTable.ShowLayerTable;
      If not MirrorObject then
       // WriteS(['LoadClassLib']);
        LoadClassLib(False);
        MkLib.LayerTable:=LayerTable;
       end;
       end else
       LoadClassLib(True);
     //  ClassBuild(nil,ClName,Twigs,MkLib);
      Except
       Stream.Status:=200;
//       If Version>47 then FontColEx:=oldFontCol;
       raise;
      end;
     end else
     begin
    If (About.XMin<>-100000000)and not(MirrorObject) then
      begin
       //MessageError('Не найден файл классификатора '+MainPath+'\'+(About.ClassName));
//       If Version>47 then FontColEx:=oldFontCol;
       // raise EStreamError.Create('File not Found');
      end;
     end;
//    If not MirrorObject then Writeln('end load Class');
//   Version:=10;
    if Version<11 then
     For I:=0 to Twigs.AnyCount-1 do
      begin
       PP:=Twigs.AAt(I,B);
       If B=Twg_Point then begin
       If PP.NLot=0 then
        begin
         Inc(About.MaxLotNum);
         PP.NLot:=About.MaxLotNum;
        end;
        CreateGUID(PP.GUID);
       end;
      end;
     For I:=Twigs.TwigsCount-1 downTo 1 do
      begin
       if TTwig(Twigs.TAt(I)) is TArcTwig then begin Twigs.AtPut(TWG_Twig,I,TTwig.CreateAsTwig(Twigs.TAt(I),True)); end;
      end;
{     For I:=Twigs.TwigsCount-1 downTo 1 do
      begin
       if TTwig(Twigs.TAt(I)) is TArcTwig then begin Writeln('DA');end;
      end;}
(*     For I:=1 to Twigs.TwigsCount-1 do
      begin
       if TTwig(Twigs.TAt(I)) is TTwigArc then begin
        if TTwig(Twigs.TAt(I)).ArcView>0 then Writeln('AVLoad=',TTwig(Twigs.TAt(I)).ArcView);
        With TTwigArc(Twigs.TAt(I)) do begin
         If D.XDot = NAN then Closed:=254;
         If C.XDot = NAN then Closed:=254;
         If A.XDot = NAN then Closed:=254;
         If B.XDot = NAN then Closed:=254;
         WRiteln('NAN=',I,' ',TTwigArc(Twigs.TAt(I)).Closed);
        end;
       end;
      end;
*)
     // GUIDы
//     if not MirrorObject  then WriteS(['LayerTable=',LayerTable = nil]);

    If Version<34 then begin
     For I:=0 to Twigs.AnyCount-1 do  begin
      PP:=Twigs.AAt(I,B);If B=Twg_Point then CreateGUID(PP.GUID);
     end;
     For I:=0 to Twigs.LotsCount-1 do begin
      L:=Twigs.LAt(I);CreateGUID(L.GUID);
     end;
    end;
    If Version>47 then begin
     If not MirrorObject then begin
//      For I:=0 to FontColEx.Count-1 do TFontViewEx(FontColEx[I]).RecreateLoadedFonts;
      For I:=0 to Twigs.AnyCount-1 do begin
       PP:=Twigs.AAt(I,B);
       PP.ResetParams(param_idResetFontView,FontColEx);
       PP.ParentIndex:=I;
      end;
     // Twigs.DelAAT(370);
      For I:=0 to Twigs.BlockList.Count-1 do begin
       TGeoBlock(Twigs.BlockList[I]).TwgForm.FontColEx := FontColEx;
      end;
     end;
    end;
   //  If HObject<WObject then HObject:=WObject else WObject:=HObject;
 //   If not MirrorObject then
 //    WriteS(['EndLoad']);
    // ClassBuild(nil,ClName,Twigs,MkLib);
 end;

  Procedure   TForm1.Store;
   var I:LongInt;Buf:TBufStream;
    begin
     {$IFDEF DEMO}
      About.Version:=DEMOVERSION;
     {$ELSE}
      About.Version:=VerConst;
     {$ENDIF}
     About.Fragment:=Selector.GRect;
     If MirrorObject then About.MirrorObject:=1 else About.MirrorObject:=0;
 //    If not MirrorObject then begin Writeln(1);end;
     StoreAbout(About,Stream);
     If not MirrorObject then begin
      Stream.Put(FontColEx);
    {  Buf:=TBufStream.InitFileStream('C:\GoFontEx',fmCreate);
       Buf.Put(FontColEx);
      Buf.Free;}
     end;
     Stream.Put(Twigs);
 //    If not MirrorObject then begin Writeln(982);end;
     Stream.Write(fGraphSet,SizeOf(fGraphSet));
     If not MirrorObject then begin
      Settings.Store(Stream);
      Stream.WriteString(TaheoFileName);
     end;
//     Stream.Write(Layers); // сохраняем таблицу слоев
     Version:=VerConst;
//     Stream.FlushBuffer;
//     Writeln('Storepos=',Stream.Position);
     If not MirrorObject then begin
      Stream.Put(LayerTable);
      Stream.WriteString(urlNum);Stream.WriteString(dbName);
//      Writeln(3);
     end;
     { If FileExists(MainPath+'\'+StrPas(About.ClassName)) then
       MkLib.StoreAll(MainPath+'\'+StrPas(About.ClassName));}
    end;

  Function TForm1.CreateUndoView;
   var N:Integer;S1,S2:AnsiString;Buf:TBufStream;
   begin
    Result:='';
    N:=0;
    S1:=(About.Path);
    S2:=(About.MyName);
    DelSubStr(S2,'.twg');DelSubStr(S2,'.tw2');DelSubStr(S2,'.tw3');
     While FileExists(S1+'\'+S2+'.'+intToStr(N)) do Inc(N);
    try
     Buf:=TBufStream.InitFileStream(S1+'\'+S2+'.'+intToStr(N),fmCreate);
      Buf.Put(Twigs);
      if not Buf.FlushBuffer then begin Buf.Free;raise Exception.Create('Не могу записать файл'); end;
     Buf.Free;
    except
     Exit;
    end;
     Result:=S1+'\'+S2+'.'+intToStr(N);
   end;

  Function TForm1.GetUndoMax:AnsiString;
   var N:Integer;S1,S2:AnsiString;Buf:TBufStream;
   begin
    Result:='';
    N:=0;
    S1:=(About.Path);
    S2:=(About.MyName);
    DelSubStr(S2,'.twg');DelSubStr(S2,'.tw2');DelSubStr(S2,'.tw3');
    While FileExists(S1+'\'+S2+'.'+intToStr(N)) do Inc(N);
    if N<>0 then
     begin
      Result:=S1+'\'+S2+'.'+intToStr(N-1);
     end;
   end;

  Destructor TForm1.Destroy;
   var I:LongInt;
    begin
     { Пытаемся удалить временные файлы в Undo }
 {     For I:=0 to UndoColl.Count-1 do
       begin
        Undo:=UndoColl[I];
        If Undo.What=Lo_SaveObject then
         If FileExists(Undo.Text) then DeleteFile(Undo.Text);
       end;
  }
  //    UNdoColl.Free;
    //  Selector.Free;
//    WriteIn(['Free1']);
      ActiveLotBool:=False;
      ActivePoint.Free;
      ActivePoint2.Free;
//      WriteIn(['Free11']);
      Twigs.Free;
//      WriteIn(['Free12']);
      ActiveText.Free;
      ActiveTwig.Free;
      ActiveLotZnak.Free;
      TmpColl.Free;
      NotLink_Up.Free;
      Perehlests.Free;
      ActivePntLine.Free;
      NeedTwigs.DeleteAll;
      NeedTwigs.Free;
 //     WriteIn(['Free2']);
     { Новые }
     { Контура }
      LotActive.DeleteAll;
      LotActive.Free;
      LotPoints.DeleteAll;
      LotPoints.Free;
      LotTwig.DeleteAll;
      LotTwig.Free;
      ActiveHPoly.DeleteAll;
      ActiveHPoly.Free;
      TempPoints.Free;
      LineNesost.Free;
//      WriteIn(['Free3']);
     {}
     try
      If not MirrorObject then begin
       MkLib.Free;
       LayerTable.Free;
       FontColEx.Free;
      end;
     except end;
//     WriteIn(['Free4']);
     {}
      TransformPoints.Free;
      ArcTwigs.DeleteAll;ArcTwigs.Free;
      TTFViews.FreeAll;TTFViews.Free;
//      WriteIn(['Free5']);
     //
      If not MirrorObject then Settings.Free;
     // If Undo<>nil then Undo.Free;
//     WriteIn(['Free6']);
    end;

{-----------------------------------------------------------------}
{ Функции интерфейса                                              }
{-----------------------------------------------------------------}
function TForm1.LotIndex(L: TLot): Integer;
var I:Integer;
begin
 Result:=-1;
 For I:=0 to Twigs.LotsCount-1 do
  If Twigs.Lat(I)=L then
   begin
    Result:=I;Exit;
   end;
end;

procedure TForm1.DelLot;
 var I,J,Index:Integer;Tw:TTwig;
begin
 Index:=LotIndex(L);
 if I>-1 then begin
  For I:=0 to L.Coord.Count-1 do
   begin
    Tw:=Twigs.TAt(TLong(L.Coord[I]).Num);
    TW.Closed:=254;
   end;
  Twigs.AtDelete(TWG_LOT,Index);
 end;
 Selector.UpdateImage;
end;

Procedure TForm1.DrawTempTwig;
 begin
{  SetRop2(GCanvas.Handle,R2_Not);
   TempTwig.Paint(GNForm.Canvas.Handle);
  SetRop2(GCanvas.Handle,R2_CopyPen);}
 end;

procedure TForm1.ClearObject;
var TW:TTwig;
begin
 TW:=TTwig.CreateAsTwig(Twigs.TAt(0),True);
 Twigs.TwigsLarge.FreeAll;
 Twigs.LotsLarge.FreeAll;
 Twigs.AnyLarge.FreeAll;
 Twigs.Insert(Twg_Twig,TW);
 Twigs.TwigsCount:=1;Twigs.LotsCount:=0;Twigs.AnyCount:=0;
 Twigs.CreateIndexes;
 Selector.UpdateImage;
end;

procedure TForm1.CreateViewArc;
 var I:Integer;Tw:TTwig;
begin
 If ArcTwigs.Count<>0 then Exit;
 For I:=0 to Twigs.TwigsCount-1 do
  begin
   Tw:=Twigs.TAt(I);
   If (Tw is TTwigSpline) or (Tw is TTwigArc) then     
    begin
     ArcTwigs.Insert(Tw);Tw.ArcView:=1;
    end;
  end;
end;

procedure TForm1.FreeViewArc;
 var I:Integer;
begin
 if ArcTwigs.Count=0 then Exit;
 For I:=0 to ArcTwigs.Count-1 do With TTwig(ArcTwigs[I]) do begin ArcView:=0;
 try
  Calculate;
 except
  Closed:=254;
 end;
 end;
 ArcTwigs.DeleteAll;
end;

procedure TForm1.SetSqwear;
   var Plo:Real;I,j:Longint;Full:LongInt;L,Lot,LotI,LotI1:TLot;Twig:TTwig;Pr:LongInt;
       PD:TPointDot;FF:TEFont;
  begin
   Modified:=True;
   If LotActive.Count<>0 then
      LotActive.DeleteAll;
   Full:=0;
   try
    For I:=0 to Twigs.LotsCount-1 do
     begin
      Lot:=Twigs.LAt(I);
      //  If Lot.IsVisible(GPRect) then
    {$IFDEF DENDRO}
     If Lot.ClassHandle.Parent<>nil then If ansiUpperCase(Lot.ClassHandle.Parent.RecString) = 'ЭЛЕМЕНТЫ ОЗЕЛЕНЕНИЯ, ЗЕЛЕНЫЕ НАСАЖДЕНИЯ' then Lot.TypeLot:=1;
    {$ENDIF}
    {$IFDEF DENDROPLAN}
     If Lot.ClassHandle.Parent<>nil then If ansiUpperCase(Lot.ClassHandle.Parent.RecString) = 'ЭЛЕМЕНТЫ ОЗЕЛЕНЕНИЯ, ЗЕЛЕНЫЕ НАСАЖДЕНИЯ'{Round(Lot.ClassHandle.Parent.ID*100) = -737} then Lot.TypeLot:=1;
    {$ENDIF}
         begin
          try Lot.SetSqwear(Twigs); except Lot.TypeLot:=254; MessageInform(IntTOStr(Twigs.LotsCount-1)+' '+IntTOStr(I));end;
         end;
       end;
     finally
     //Twigs.CreateIndexes;
    //Twigs.LotsLarge.DeleteAll;
    //For I:=0 to Twigs.IndexPlo.Count-1 do Twigs.LotsLarge.Insert(Twigs.IndexPlo[I]);
     end;
   end;

procedure TForm1.ClassBuildII;
begin
// ClassBuildIII;
// exit;
 If LayerTable<>nil then LayerTable.CreateSignView;
 Build1(Selector,ClName,Twigs,MkLib);
end;

procedure TForm1.ClassBuildIII;
begin
 If LayerTable<>nil then LayerTable.CreateSignView;
 Build1(Selector,ClName,Twigs,MkLib);
end;


Function TForm1.MakeLineLot:boolean;
 var
	Add:boolean;
	x1,y1,x2,y2:Double;
	Twig1,Twig2:TTwig;
   i:LongInt;
 begin
  MakeLineLot:=False;
 if ActiveTwig.Count=0 then exit;
 TmpColl.FreeAll;
 Add:=true;
 TmpColl.Insert(ActiveTwig.At(0));
 ActiveTwig.AtDelete(0);
 Twig1:=twigs.TAT(TLong(TmpColl.At(0)).Num);
 Twig1.Inv:=0;
 x1:=TDot(Twig1.Coord.At(0)).XDot; y1:=TDot(Twig1.Coord.At(0)).yDot;
 x2:=TDot(Twig1.Coord.At(Twig1.Coord.count-1)).XDot; y2:=TDot(Twig1.Coord.At(Twig1.Coord.count-1)).yDot;
 while Add and (ActiveTwig.Count>0) do
	begin
	i:=0;
	while i<ActiveTwig.Count do
   	begin
		Twig2:=twigs.TAT(TLong(ActiveTwig.At(i)).Num);
		if (round(TDot(Twig2.Coord.At(0)).XDot*Const_Of_PrecCoord)=round(x1*Const_Of_PrecCoord))and
			(round(TDot(Twig2.Coord.At(0)).yDot*Const_Of_PrecCoord)=round(y1*Const_Of_PrecCoord)) then
			begin
			TmpColl.ATInsert(0,(TLong.Create(-TLong(ActiveTwig.At(i)).Num)));
			ActiveTwig.AtFree(i);                          
			i:=17000;
			Add:=true;
			Twig2.Inv:=0;
			x1:=TDot(Twig2.Coord.At(Twig2.Coord.count-1)).XDot;
			y1:=TDot(Twig2.Coord.At(Twig2.Coord.count-1)).yDot;
			end
		else
			if (round(TDot(Twig2.Coord.At(0)).XDot*Const_Of_PrecCoord)=round(x2*Const_Of_PrecCoord))and
				(round(TDot(Twig2.Coord.At(0)).yDot*Const_Of_PrecCoord)=round(y2*Const_Of_PrecCoord)) then
				begin
				TmpColl.Insert((TLong.Create(TLong(ActiveTwig.At(i)).Num)));
				ActiveTwig.AtFree(i);
				i:=17000;
				Add:=true;
				Twig2.Inv:=0;
				x2:=TDot(Twig2.Coord.At(Twig2.Coord.count-1)).XDot;
				y2:=TDot(Twig2.Coord.At(Twig2.Coord.count-1)).yDot;
				end
			else
				if (round(TDot(Twig2.Coord.At(Twig2.Coord.count-1)).XDot*Const_Of_PrecCoord)=round(x1*Const_Of_PrecCoord))and
				(round(TDot(Twig2.Coord.At(Twig2.Coord.count-1)).yDot*Const_Of_PrecCoord)=round(y1*Const_Of_PrecCoord)) then
					begin
					TmpColl.ATInsert(0,(TLong.Create(TLong(ActiveTwig.At(i)).Num)));
					ActiveTwig.AtFree(i);
					i:=17000;
					Add:=true;
					Twig2.Inv:=0;
					x1:=TDot(Twig2.Coord.At(0)).XDot;
					y1:=TDot(Twig2.Coord.At(0)).yDot;
					end
	         else
					if (round(TDot(Twig2.Coord.At(Twig2.Coord.count-1)).XDot*Const_Of_PrecCoord)=round(x2*Const_Of_PrecCoord))and
					(round(TDot(Twig2.Coord.At(Twig2.Coord.count-1)).yDot*Const_Of_PrecCoord)=round(y2*Const_Of_PrecCoord)) then
						begin
						TmpColl.Insert((TLong.Create(-TLong(ActiveTwig.At(i)).Num)));
						ActiveTwig.AtFree(i);
						i:=17000;
						Add:=true;
						Twig2.Inv:=0;
						x2:=TDot(Twig2.Coord.At(0)).XDot;
						y2:=TDot(Twig2.Coord.At(0)).yDot;
						end
					else
               	  begin
						inc(i);
						Add:=false;
                  end;
      end;
	end;
 MakeLineLot:=true;
 Modified:=True;
end;

Function TForm1.MakeLot(PT: TResource):TLot;
 var
   i:LongInt;
	Twig:TTwig;
	Num:Extended;
        Lot:TLot;
 begin
// if trunc(pt.rang)=0 then exit;
 OneLot:=TLot.Create(PT.ID,PT,Lot_Sbor);
 OneLot.ClassHandle:=PT;
// OneLot.idSetNewUID;
 Result:=Lot;
 with OneLot do
	begin
// 	Color:=PT.RGB;
//	UZnak:=PT.ZnkInd.SPInd;
	Closed:=1;
	Ins:=-1;
	TypeLot:=Trunc(PT.Rang);
	for i:=0 to TmpColl.Count-1 do
  Coord.Insert(TmpColl.At(i));
	TmpColl.DeleteAll;
	RKF:=1;
	end;
    Inc(About.MaxLotNum);
	 OneLot.NLot:=About.MaxLotNum;
//         OneLot.Hatch:=PT.Hatch;
  OneLot.SetSqwear(Twigs);
  Twigs.Insert(Twg_Lot,OneLot);
        {THI}
   OneLot.ResetTaheoIndexesForAllTwigs(Twigs);
        {}
  OneLot:=Twigs.Lat(Twigs.LotsCount-1);
  OneLot.SetMinMax(Twigs);
	 { OneLot.SetClearSqwear(I,Twigs,About.XMin,About.YMin);}
	{ OneLot:=nil;}{было закрыто}
  OneLot.SetFromTwig(Twigs);
  Modified:=True;
 end;

procedure TForm1.StoreMkLib;
begin
 // MkLib.StoreAll(MainPath+'\'+(About.ClassName));
end;

procedure TForm1.SetClearSqwear;
var Plo:Real;I,j:Longint;Full:LongInt;Lot:TLot;Twig:TTwig;pr:LongInt;
    PD:TPointDot;FF:TEFont;W:Byte;X,Y:Double;
    SaveLots:pointer;
    B:Boolean;
Function GetPloPoint(Point:TPointDot):Double;
var S,GF,TN:AnsiString;
begin
 Result:=0;
 {$IFDEF DENDROPLAN}
  If Point.TextManager = nil then exit;
  S:=Point.TextManager.AttrValue('Количество (кв.м)');
  If S='' then exit;
  try Result:=GStrToFloat(S); except exit; end;
  If DendroGetZnak(PD.GetZnak)=98 then exit;
  GF:=PD.TextManager.AttrValue('Жизненная форма');
  TN:=PD.TextManager.AttrValue('Тип насаждения');
  If Pos('Поросль',TN)<>0 then exit else begin
   If GF = 'Дерево' then S:='0.5' else S:='0.3';
  end;
  Result:=GStrToFloat(S);
//  If (Round(Point.Code*100) = -852) or (Round(Point.Code*100) = -867) then Result:=0;
//  If Point.TextManager.AttrValue('Тип насаждения') = 'Группа' then Result:=0;
 {$ENDIF}
 {$IFDEF DENDRO}
  If Point.TextManager = nil then exit;
  S:=Point.TextManager.AttrValue('Количество (кв.м)');
  If S='' then exit;
  try Result:=StrToFloat(S); except exit; end;
  If DendroGetZnak(PD.GetZnak)=98 then exit;
  S:=PD.TextManager.AttrValue('Жизненная форма');
  If S = 'Дерево' then S:='0.5' else S:='0.3';
  If Point.TextManager.AttrValue('Тип насаждения') = 'Группа' then Result:=0;
//  If (Round(Point.Code*100) = -852) or (Round(Point.Code*100) = -867) then Result:=0;
 {$ENDIF}
end;
Procedure SetPointPlus(Point:TPointDot);
var S:AnsiString;
begin
 {$IFDEF DENDROPLAN}
  If Point.TextManager = nil then exit;
  S:=Point.TextManager.AttrValue('Количество (кв.м)');
  If S='' then exit;
  try StrToFloat(S); except exit; end;
  If S[1]<>'+' then Point.TextManager.SetAttrValue('Количество (кв.м)','+'+S);
 {$ENDIF}
 {$IFDEF DENDRO}
  If Point.TextManager = nil then exit;
  S:=Point.TextManager.AttrValue('Количество (кв.м)');
  If S='' then exit;
  try StrToFloat(S); except exit; end;
  If S[1]<>'+' then Point.TextManager.SetAttrValue('Количество (кв.м)','+'+S);
 {$ENDIF}
end;
Function GetODHPoint(Point:TPointDot):Double;
begin
 Result:=0;
 If Point.ClassHandle.Parent = nil then exit;
 If Point.ClassHandle.Parent<>LayerTable.NullLayer then exit;
 If UpperCase(Point.ClassHandle.RecString) <> 'BORT' then exit;
 If Point.TextManager = nil then exit;
 try
  Result:=GStrToFloat(TTextParams(Point.TextManager.FValues[0]).FValue);
 except end;
end;
begin
   Modified:=True;
   If LotActive.Count<>0 then
      LotActive.DeleteAll;
   Full:=0;
//   Aborted:=False;
    For I:=0 to Twigs.IndexCount-1 do begin
     try
      TLot(Twigs.LAtIndex(I)).InsClipDotsParall(Twigs);
     except TLot(Twigs.LAtIndex(I)).TypeLot:=254; end;
    end;
    For I:=0 to Twigs.IndexCount-1 do
     begin
      Lot:=Twigs.LAtIndex(I);
      //  If Lot.IsVisible(GPRect) then
      If Os='' then B:=True else B:=Lot.GetProperty('*Ось')=Os;
     // If I=48 then
      //  Lot.Ins:=-1;
       If B then
         begin
           Lot.Ins:=-1;
           Lot.ClearPlo:=Lot.Plo;
           If Lot.ClassHandle.notClearNad then continue;
           If Lot.TypeLot=2 then Lot.SetClearSqwear(I,Twigs,Os,False);
          // Writeln(Lot.Plo,' ',Lot.ClearPlo)
         end;
     end; // for I
    For I:=0 to Twigs.IndexCount-1 do TLot(Twigs.LAtIndex(I)).Points.Free;
  if GGraphSet.FontPointIns=1 then
   begin
//      Aborted:=False;
        For I:=0 to Twigs.AnyCount-1 do
         begin
          PD:=Twigs.AAt(I,W);
           If PD.Closed then continue;
           if W=Twg_Point then begin X:=PD.XDot;Y:=PD.YDot;PD.Ins:=-1; end else
           if W=Twg_Font  then begin FF:=TEFont(Pointer(PD));X:=FF.XF;Y:=FF.YF;FF.Ins:=-1;end else PD:=nil;
           // If PD.TextManager<>nil then begin
             //If PD.TextManager.AttrValue('Количество (кв.м)')='' then continue;
           // end else

        //    if PointVis(X,Y) then
            For J:=Twigs.IndexCount-1 downTo 0 do  
             begin
              Lot:=Twigs.LAtIndex(J);
               If Lot.Closed<>0 then
                If Lot.TypeLot=2 then
                   begin
                    if Lot.PointIn(Twigs,X,Y) then
                     begin
                       if W=Twg_Point then begin
{                         If PD.TextManager<>nil then begin
                         If PD.TextManager.AttrVAlue('№ растения') = '6' then
                         If Trunc(Lot.ClearPlo*10)<>Round(GetPloPoint(PD)*10) then
                           Lot.ClearPlo:=Lot.ClearPlo-GetPloPoint(PD);
                         end;
}
                        {If Trunc(Lot.Plo*10)<>Round(GetPloPoint(PD)*10) then}
                       {$IFDEF ODH}
                         Lot.ClearPlo:=Lot.ClearPlo-GetODHPoint(PD);
                       {$ENDIF}
                       {$IFDEF DENDROPLAN}
                         Lot.ClearPlo:=Lot.ClearPlo-GetPloPoint(PD);// else SetPointPlus(PD);
                       {$ENDIF}
                       {$IFDEF DENDRO}
                         Lot.ClearPlo:=Lot.ClearPlo-GetPloPoint(PD);// else SetPointPlus(PD);
                       {$ENDIF}
                         PD.Ins:=Lot.NLot
                       end;
                      Break;
                     end;
                   end;
              end; // j
           end;
      end;
end;

function TForm1.SetLotFromTwigs(LotNum: LongInt): Double;
var I:LongInt;Lot:TLot;R:TRect;
begin
With Twigs do
 begin
  Lot:=LAt(LotNum);
  If Lot.IsVisible(Selector.GPRect) then
  If Lot.SetSqwear(Self.Twigs)=ord(True) then
     begin
       SetLotFromTwigs:=Lot.Plo;
     end
     else
     begin
       Lot.Plo:=0;
       SetLotFromTwigs:=-1;
      end;
 end;
end;

function TForm1.SortSqwear(C: LongInt): LongInt;
var I:Integer;IndexPlo:TPloIndex;
begin                                                
//  Twigs.CreateIndexes;
  IndexPlo:=TPloIndex.Create(Selector);
  For I:=0 to Twigs.LotsLarge.Count-1 do IndexPlo.Insert(Twigs.LotsLarge[I]);
  Twigs.LotsLarge.DeleteAll;
  For I:=0 to IndexPlo.Count-1 do Twigs.LotsLarge.Insert(IndexPlo[I]);
  IndexPlo.DeleteAll;IndexPlo.Free;
end;

function TForm1.ObjectName: AnsiString;
begin                                                           
 Result:=About.Path+'\'+About.MyName;
end;

function TForm1.GetModified: boolean;
begin
 Result:=About.ModifiedObject=1;
end;

procedure TForm1.SetModified(const Value: boolean);
begin
 About.ModifiedObject:=ord(Value);
 Modified2:=Value;
end;


initialization
// Writeln(525+3*2.9*600+2.8*1.5*1020+357+840+1260);
end.
