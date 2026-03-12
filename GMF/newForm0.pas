Unit newForm0;
Interface
uses Collect,Classes,
     SysUtils, newConsts, RPrims, WpTwigs,
     newFontScale, TextManager, objBlockList, newSelector;

Const
   Twg_PointMap =50;
   Twg_SqwearMap=51;
   Twg_Bitmap=52;
   Twg_Block=53;
{}
{ Коллекция графических примитивов }
{}
Type
  TSloyIndex=class(TSortedCollection)
    Selector:TSelector;
    Constructor Create(Selector_:TSelector);
    Function Compare(Key1,Key2:Pointer):Integer;override;
   end;

  TPloIndex=class(TSortedCollection)
    Selector:TSelector;
    Constructor Create(Selector_:TSelector);
    Function Compare(Key1,Key2:Pointer):Integer;override;
   end;

  TNumIndex=class(TSortedCollection)
    Selector:TSelector;
    Constructor Create(Selector_:TSelector);
    Function Compare(Key1,Key2:Pointer):Integer;override;
   end;

  TGUIDIndex=class(TSortedCollection)
    Selector:TSelector;
    Constructor Create(Selector_:TSelector);
    Function Compare(Key1,Key2:Pointer):Integer;override;
    Function KeyOf(Key:Pointer):Pointer;override;
   end;

 { TFontScaleCollect }
 Type
  TFontViewCollect = class(PCollection)
    function InsertFont(FontName:String;FH,FW:Double;CharSet:Integer;bl,it,un:Integer):TFontViewEx;
  end;

 { TTextManagerCollect }
 Type
  TTextManagerCollect = class(PCollection)
    function InsertManager(M:TTextManager):TTextManager;
  end;

Type
  TTWigsCollect=Class(TTwgObject)
  //
   TwgForm:Pointer;
  //
         BlockList:TBlockList;
         AllCount  :Extended;
         TwigsCount,
         AnyCount  ,
         LotsCount :LongInt;
         TwigsCol,AnyCol,LotsCol:Byte;
         Twigs :Array[0..99] of PCollection;
         Lots  :Array[0..99] of PCollection;
         Any   :Array[Byte ] of PCollection;
         PAny  :Array[Byte ] of PCollection;
       {}
         TwigsLarge :PCollection;
         LotsLarge  :PCollection;
         AnyLarge   :PCollection;
         PAnyLarge  :PCollection;
         IndexLarge :TSloyIndex;
//         IndexPlo   :TPloIndex;
//         IndexNum   :TNumIndex;
//         IndexGUID  :TGUIDIndex;
        {Тахеометрия}
        CountTaheo:Byte;
         TaheoNames:Array[0..10] of String[12];
         TaheoDots :Array[0..10] of PCollection;
         TaheoTwigs:Array[0..10] of PCollection;
         TaheoIndexes:TStrings;
        {Таблица фонтов}
         FontS    :PCollection;
         FontSet  :PCollection;
        {Горизонтали}
         HPoly    :PCollection;
        {}
         Bitmaps  :TBMPSet; // загружаемые растры
        {}
         FontViewCollect:TFontViewCollect;
         TextManagerCollect:TTextManagerCollect;
        {}
         LinkFiles:TLinkFiles;
         RasterFiles:TLinkFiles;
         TextureList:TTextureList;
         Selector:TSelector;
        {}
         Constructor Create(Selector_:TSelector);
        {}
         Function IndexCount:Integer;
         Procedure CreateIndexes;
         Procedure ToLarge;
         Procedure FromLarge;
         Procedure DestroyOld;
       {}
         Constructor Load(Stream:TBufStream);Override;
         Procedure  Store(Stream:TBufStream);Override;
         Function   TAt      (Index:Longint):Pointer;Virtual;
         Function   LAt      (Index:Longint):Pointer;Virtual;
         Function   LAtIndex (Index:Longint):Pointer;
         Function   AAt      (Index:LongInt;var What:Byte):Pointer;Virtual;
         Procedure  DelAAt   (Index:Longint);virtual;
         Function   PAt      (Index:Longint):Byte;Virtual;
       {}
         Procedure  OldInsert(What:Byte;P:Pointer);
         Function  Insert   (What:Byte;P:Pointer;AddIndexes:Boolean = True):Pointer;
       {}
         Procedure  AtPut    (What:Byte;Index:LongInt;P:Pointer);
         Procedure  AtDelete (What:Byte;Index:LongInt);virtual;
       {}
         Function   InsertProject(Name:String):Integer;
         Function   GetProject   (Name:String):SmallInt;
       {Horiz}
         Function  HorizCount:Integer;
         Destructor Destroy;Override;
       //
         Function FindTwigSpatial(Twig:TTwig):Integer;
       end;

 {  Указательный файл-содержит информацию о графических объектах  }

Type
  TFormMain=class(TTwgObject)
    Filter   :Word;               { Флаги вывода на экран  }
    Twigs    :TTwigsCollect;
   end;

{----------------------------------------------------------------------}

Implementation uses EcLot, newResource, newProcs, ECText, TwgColle, ECDot,
                    Writer;

{----------------------------------------------------------------------}
{ TTwigsCollect                                                        }
{----------------------------------------------------------------------}

 Constructor  TTwigsCollect.Create;
  var I:SmallInt;
   begin
    Selector:=Selector_;
   { Объявляем большую коллекцию }
     TwigsLarge:=PCollection.Create(1);
     LotsLarge:=PCollection.Create(1);
     AnyLarge:=PCollection.Create(1);
     PAnyLarge:=PCollection.Create(1);
     IndexLarge:=TSloyIndex.Create(Selector);
     IndexLarge.Duplicates:=True;
//     IndexPlo:=TPloIndex.Create(1);
//     IndexPlo.Duplicates:=True;
//     IndexNum:=TNumIndex.Create(1);
//     IndexNum.Duplicates:=True;
//     IndexGUID:=TGUIDIndex.Create(1);
//     IndexGUID.Duplicates:=True;
     For I:=0 to 10 do
       begin                                                        
        TaheoDots [I]:=PCollection.Create(1);
        TaheoTwigs[I]:=PCollection.Create(1);;
       end;
      CountTaheo:=0;
     Fonts:=PCollection.Create(1);;
     FontSet:=PCollection.Create(1);;
   {}
     HPoly:=PCollection.Create(1);
   {}
     Bitmaps:=TBMPSet.Create;// создаем пустую коллекцию растров
   {}
    TwigsCount:=0;LotsCount:=0;AnyCount:=0;
    TaheoIndexes:=TStringList.Create;
   {}
    FontViewCollect:=TFontViewCollect.Create(1);
    TextManagerCollect:=TTextManagerCollect.Create(1);
    BlockList:=TBlockList.Create;
    LinkFiles:=TLinkFiles.Create;
    RasterFiles:=TLinkFiles.Create;
    TextureList:=TTextureList.Create;
   end;
                                                     

 Constructor TTwigsCollect.Load;
  var I,Cnt:SmallInt;
  begin
   Selector:=Stream.Selector;
   TextureList:=nil;
   try
   { Объявляем большую коллекцию }
     TwigsLarge:=PCollection.Create(1);
     LotsLarge:=PCollection.Create(1);
     AnyLarge:=PCollection.Create(1);
     PAnyLarge:=PCollection.Create(1);
     IndexLarge:=TSloyIndex.Create(Selector);
     IndexLarge.Duplicates:=True;
//     IndexPlo:=TPloIndex.Create(1);
//     IndexPlo.Duplicates:=True;
//     IndexNum:=TNumIndex.Create(1);
//     IndexNum.Duplicates:=True;
//     IndexGUID:=TGUIDIndex.Create(1);
//     IndexGUID.Duplicates:=True;
     For I:=0 to 10 do
       begin
         TaheoDots [I]:=PCollection.Create(1);
         TaheoTwigs[I]:=PCollection.Create(1);
       end;
   CountTaheo:=0;
//   WriteS(['Twigs']);
   AllCount:=Stream.ReadExtended;
   TwigsCount := Stream.ReadInt32;
   LotsCount  := Stream.ReadInt32;
   AnyCount   := Stream.ReadInt32;
//   WriteIn(['tc1=', Stream.Position]);
   Stream.Read(TwigsCol,SizeOf(TwigsCol));
   Stream.Read(LotsCol,SizeOf(LotsCol));
   Stream.Read(AnyCol,SizeOf(AnyCol));
   GTwigsCount:=0;
//   WriteIn(['Count.LA', LotsCount, AnyCount]);
    For I:=0 to TwigsCol do begin
      Twigs[I]:=PCollection(Stream.Get);
    end;
  // WriteIn(['tc2=', Stream.Position]);
    gCountLots:=0;
    For I:=0 to LotsCol  do
     Lots[I]:=PCollection(Stream.Get);
  // WriteIn(['tc3=', Stream.Position]);
    gCountDots:=0;
    For I:=0 to AnyCol  do
     Any [I]:=PCollection(Stream.Get);
   For I:=0 to AnyCol  do
     PAny[I]:=PCollection(Stream.Get);
 //  WriteIn(['tc4=', Stream.Position]);
     Fonts:=PCollection.Create(1);
     FontSet:=PCollection.Create(1);
     ToLarge;
     DestroyOld;
   If Stream.GetPos<>Stream.GetSize then
   begin
 { 000 }
   Stream.Read(CountTaheo,1);
    For I:=0 to 10 do
     begin
       Stream.Read(TaheoNames[I],SizeOf(TaheoNames[I]));
       TaheoDots[I]:=PCollection(Stream.Get);
       TaheoTwigs[I]:=PCollection(Stream.Get);
     end;
   end;
  // WriteIn(['Taheo=', Stream.Position]);
   If Stream.GetPos<>Stream.GetSize then
    begin
     Fonts:=PCollection(Stream.Get);
     FontSet:=PCollection(Stream.Get);
    end;
   {}
    HPoly:=PCollection.Create(1);
   If Stream.GetPos<>Stream.GetSize then
    begin
     HPoly.Free;
     HPoly:=PCollection(Stream.Get);
    end;
   // загрузка растра
   If Stream.GetPos<>Stream.GetSize then
     Bitmaps:=TBmpSet(Stream.Get) else
     Bitmaps:=TBmpSet.Create;
  // WriteIn(['Bitmap=', Stream.Position]);
//     Bitmaps:=TBmpSet.Create;
   // загрузка тахеометрии
   TaheoIndexes:=TStringList.Create;
   If newConsts.Version>22 then
    begin
     If Stream.GetPos<>Stream.GetSize then
      begin
       Stream.Read(Cnt,SizeOf(Cnt));
       For I:=1 to Cnt do TaheoIndexes.Add(Stream.ReadString);
      end;
     If newConsts.Version>24 then
      begin
       If Stream.GetPos<>Stream.GetSize then begin
       // If TwigsCount = 1285 then BLOCK_DEBUG:=True;
         BlockList:=TBlockList(Stream.Get);
      //  WriteIn(['Blocks=', Stream.Position]);
// If TwigsCount = 1285 then BLOCK_DEBUG:=False;
         //  WriteMsg(['BlockList.Pos=',Stream.Position,TwigsCount,LotsCount,'Size=',Stream.Size]);
        // BlockList.Blocks.FreeAll;
        // If BlockList.Blocks.Count>1 then BlockList.Blocks.AtFree(BlockList.Blocks.Count-1);
       end else BlockList:=TBlockList.Create;
       try
//        WriteS(['LinkFiles',Stream.Position]);
        If newConsts.Version>41 then LinkFiles:=TLinkFiles(Stream.Get) else LinkFiles:=TLinkFiles.Create;
//        WriteS(['endLinkFiles=',LinkFiles.Count]);
       except
        LinkFiles:=TLinkFiles.Create;
       end;
       try
        If newConsts.Version>45 then begin
//         WriteS(['begRasterFiles']);
         RasterFiles:=TLinkFiles(Stream.Get);
//         WriteS(['endRasterFiles=',RasterFiles.Count]);
          If newConsts.Version>52 then TextureList:=TTextureList(Stream.Get);
        end else RasterFiles:=TLinkFiles.Create;
       except
        RasterFiles:=TLinkFiles.Create;
       end;
      end else BlockList:=TBlockList.Create;
    end else BlockList:=TBlockList.Create;
   except
//    Writeln('finally');
   // BlockList:=TBlockList.Create;
   end;
   FontViewCollect:=TFontViewCollect.Create(1);
   TextManagerCollect:=TTextManagerCollect.Create(1);
   If TextureList = nil then TextureList:=TTextureList.Create;
  // If AnyCount >0 then DelAAt(0);
  end;


 Procedure   TTwigsCollect.Store;
 var I,Cnt:SmallInt;
  begin
   FromLarge;
  // не работает allCount WIN64!!!
   Stream.Write(AllCount,SizeOf(AllCount));
   Stream.Write(TwigsCount,SizeOf(TwigsCount));
   Stream.Write(LotsCount,SizeOf(LotsCount));
   Stream.Write(AnyCount,SizeOf(AnyCount));
   Stream.Write(TwigsCol,SizeOf(TwigsCol));
   Stream.Write(LotsCol,SizeOf(LotsCol));
   Stream.Write(AnyCol,SizeOf(AnyCol));
    For I:=0 to TwigsCol do
      Stream.Put(Twigs[I]);
    For I:=0 to LotsCol do
     Stream.Put(Lots[I]);
    For I:=0 to AnyCol do
     Stream.Put(Any[I]);
    For I:=0 to AnyCol do
     Stream.Put(PAny[I]);
//   If UstnTaheo.Rec=0 then
    begin
    For I:=0 to CountTaheo-1 do
     begin
      TaheoDots[I].FreeAll;
      TaheoTwigs[I].FreeAll;
     end;
    end;
    Stream.Write(CountTaheo,1);
    For I:=0 to 10 do
     begin
       Stream.Write(TaheoNames[I],SizeOf(TaheoNames[I]));
       Stream.Put(TaheoDots[I]);
       Stream.Put(TaheoTwigs[I]);
     end;
   Stream.Put(Fonts);
   Stream.Put(FontSet);
{   Stream.Truncate;}
  {}
   DestroyOld;
  { Horiz }
   Stream.Put(HPoly);
   // запись растра
   Stream.Put(Bitmaps);
   Cnt:=TaheoIndexes.Count;
   Stream.Write(Cnt,SizeOf(Cnt));
   For I:=0 to Cnt-1 do Stream.WriteString(TaheoIndexes[I]);
  {}
   Stream.Put(BlockList);
   Stream.Put(LinkFiles);
   Stream.Put(RasterFiles);
   Stream.Put(TextureList);
 end;

 Function TTwigsCollect.IndexCount;
  begin
   Result:=IndexLarge.Count;
  end;

 Procedure  TTwigsCollect.ToLarge;
  var I,J:LongInt;
  begin
    For I:=0 to TwigsCol do
     For J:=0 to Twigs[I].Count-1 do
        TwigsLarge.Insert(Twigs[I].At(J));
    For I:=0 to LotsCol do
     For J:=0 to Lots[I].Count-1 do  begin
//       If Lots[I].At(J)<>nil then
        LotsLarge.Insert(Lots[I].At(J));// else WRiteln(I,' ',J,' nil');
       end;
    For I:=0 to AnyCol do
     For J:=0 to Any[I].Count-1 do
        AnyLarge.Insert(Any[I].At(J));
    For I:=0 to AnyCol do
     For J:=0 to PAny[I].Count-1 do
        PanyLarge.Insert(PAny[I].At(J));
   AnyCount:=AnyLarge.Count;TwigsCount:=TwigsLarge.Count;
   LotsCount:=LotsLarge.Count;
  end;

 Procedure TTwigsCollect.DestroyOld;
  var I,J:LongInt;
  begin
    For I:=0 to TwigsCol do
      begin
       Twigs[I].DeleteAll;
       Twigs[I].Free;
       Twigs[I]:=nil;
      end;
    For I:=0 to LotsCol do
     begin
       Lots[I].DeleteAll;
       Lots[I].Free;
       Lots[I]:=nil;
     end;
    For I:=0 to AnyCol do
      begin
       Any[I].DeleteAll;
       Any[I].Free;
       Any[I]:=nil;
      end;
    For I:=0 to AnyCol do
      begin
       PAny[I].DeleteAll;
       PAny[I].Free;
       Pany[I]:=nil;
      end;
  end;

 Procedure TTwigsCollect.FromLarge;
  var I,J:Longint;
      Lv:Longint;
      Inm:LongInt;
      I16:LongInt;
   begin
   {}
    TwigsCol:=0;AnyCol:=0;LotsCol:=0;
     Twigs[0]:=PCollection.Create(1);;
      For I:=1 to 99 do Twigs[I]:=Nil;
     Lots[0]:=PCollection.Create(1);
      For I:=1 to 99 do Lots[I]:=Nil;
     Any [0]:=PCollection.Create(1);
      For I:=1 to SizeOf(Byte) do Any [I]:=Nil;
     PAny [0]:=PCollection.Create(1);
      For I:=1 to SizeOf(Byte) do PAny [I]:=Nil;
     TwigsCount:=0;LotsCount:=0;AnyCount:=0;
    {}
    For I:=0 to TwigsLarge.Count-1 do
       OldInsert(Twg_Twig,TwigsLarge[I]);
     For I:=0 to Lotslarge.Count-1 do
       OldInsert(Twg_Lot,LotsLarge[I]);
     For I:=0 to AnyLarge.Count-1 do
      OldInsert(TPtr(PAnyLarge[I]).Register,AnyLarge[I]);
   end;


 Function  TTwigsCollect.Insert(What:Byte;P:Pointer;AddIndexes:Boolean=True):Pointer;
 var Lot:TLot;I:Integer;C:String;
  begin
     Result:=nil;
   If What=Twg_Twig then
    begin
     TwigsLarge.Insert(P);
     TwigsCount:=TwigsLarge.Count;
     TTwig(P).ParentIndex:=TwigsCount-1;
     Result:=P;
    end else
   If What=Twg_Lot then
    begin
     Lot:=P;
    { If Lot.ClassName<>'TLot' then
      Writeln(Lot.ClassName);}
     LotsLarge.Insert(P);
     TLot(P).ParentIndex:=LotsCount;
    If AddIndexes then begin
     IndexLarge.Insert(P);
   { If IndexLarge.Count<20 then begin
     WriteOn(nil,['---------------']);
     For I:=0 to IndexLarge.Count-1 do begin
      If P=IndexLarge[I] then C:='*' else C:='';
      WriteOn(nil,[TLot(IndexLarge[I]).Plo,C]);
     end;
     WriteOn(nil,['---------------'])
    end;}
//      IndexPlo.Insert(P);
//      IndexNum.Insert(P);
//      IndexGUID.Insert(P);
    end;
     LotsCount:=LotsLarge.Count;
     Result:=P;
     {SendMessage(TForm(gForm.Owner).Handle,12333,0,0);}
    end else
   If What=Twg_Font then
    begin
     AnyLarge.Insert(P);
     PAnyLarge.Insert(Pointer(TPtr.Create(Twg_Font)));
     AnyCount:=AnyLarge.Count;
     Result:=P;
    end else
   If What=Twg_Point then
    begin
     AnyLarge.Insert(P);
     PAnyLarge.Insert(Pointer(TPtr.Create(Twg_Point)));
     TPointDot(P).ParentIndex:=AnyCount;
     AnyCount:=AnyLarge.Count;
     Result:=P;
     end else
   If What=Twg_Block then begin
     BlockList.Insert(P);
    // PAnyLarge.Insert(Pointer(TPtr.Create(What)));
     Result:=P;
   end else
    begin
     AnyLarge.Insert(P);
     PAnyLarge.Insert(Pointer(TPtr.Create(What)));
     AnyCount:=AnyLarge.Count;
     Result:=P;
    end;
  end;

 Procedure  TTwigsCollect.OldInsert;
  var Old:Byte;
      Lv:Longint;
      Inm:LongInt;
      I16:LongInt;
  begin
    If What=TWG_Twig then
	  begin
           Twigs[TwigsCol].Insert(P);
		  Inc(TwigsCount);
		  Inm:=TwigsCol+1;
                   I16:=16000;
		  Lv:=LongInt(I16*Inm);
			If TwigsCount>=Lv  then
			 begin
			  Inc(TwigsCol);
                          Twigs[TwigsCol]:=PCollection.Create(1);
                        end;
       end else
    If What=TWG_Lot then
     begin     
          Lots[LotsCol].Insert(P);
        Inc(LotsCount);
		  Inm:=LotsCol+1;
                   I16:=16000;
		  Lv:=LongInt(I16*Inm);
         If LotsCount>=Lv then
          begin
			  Inc(LotsCol);
           Lots[LotsCol]:=PCollection.Create(1);
			 end;
          { 000 }
{         SendMessage(TForm(gForm.Owner).Handle,12333,0,0);}
	  end else
	 if What=TWG_Point then
		begin
		  Any[AnyCol].Insert(P);
        PAny[AnyCol].Insert(TPtr.Create(Twg_Point));
		  Inc(AnyCount);
         If AnyCount>16000*(AnyCol+1) then
          begin
           Inc(AnyCol);
           Any[AnyCol]:=PCollection.Create(1);
           PAny[AnyCol]:=PCollection.Create(1);;
          end;
      end else
    If What=TWG_Font then
     begin
		  Any[AnyCol].Insert(P);
        PAny[AnyCol].Insert(TPtr.Create(Twg_Font));
		  Inc(AnyCount);
         If AnyCount>16000*(AnyCol+1) then
          begin
           Inc(AnyCol);
           Any[AnyCol]:=PCollection.Create(1);;
           PAny[AnyCol]:=PCollection.Create(1);;
          end;
       end;
     end;

  Procedure  TTwigsCollect.AtPut;
  var Old:Byte;ClIndex:LongInt;
  begin
    If What=TWG_Twig then
     begin
       TTwgObject(TwigsLarge[Index]).Free;
       TwigsLarge[Index]:=P;
     end else
    If What=TWG_Lot then
     begin
     // LotsLarge[Index].Free;
       LotsLarge[Index]:=P;
     end else                                                                    
    If What=TWG_Point then begin
       AnyLarge[Index]:=P;                                    
    end;
  end;


 Function  TTwigsCollect.TAt;
  var ClIndex:SmallInt;                                      
  begin
   if Abs(Index)>TwigsCount-1 then Exception.Create(Format('Выход за пределы диапазона при доступе к ветви [%d, %d, %d]',[Index,TwigsCount-1,TwigsLarge.Count-1]));
    Tat:=TwigsLarge[Abs(Index)];
  end;

 Function  TTwigsCollect.LAt;
  var ClIndex:SmallInt;
  begin
   Lat:=LotsLarge.FList[Index];
  end;

 Function  TTwigsCollect.LAtIndex;
  begin
    LAtIndex:=IndexLarge[Index];
 end;

  Function  TTwigsCollect.AAt;
  var ClIndex:SmallInt;
  begin
    Aat:=AnyLarge[Index];
    What:=PAt(Index);
  end;

  Procedure TTwigsCollect.AtDelete;
   var i,BazC:Byte;P:Pointer;
    begin                                                       
      If What=Twg_Lot then
        begin
         P:=LotsLarge[Index];
{$IFDEF NEWCOL}
         IndexLarge.AtDelete(IndexLarge.IndexOf(P));
//         IndexPlo.AtDelete(IndexPlo.IndexOf(P));
//        if IndexNum.Count<>0 then
//         IndexNum.AtDelete(IndexNum.IndexOf(P));
//         IndexGUID.AtDelete(IndexGUID.IndexOf(P));
{$ELSE}
         IndexLarge.AtDelete(IndexLarge.FList.IndexOf(P));
//         IndexPlo.AtDelete(IndexPlo.FList.IndexOf(P));
//         IndexGUID.AtDelete(IndexGUID.FList.IndexOf(P));
//        if IndexNum.Count<>0 then
//         IndexNum.AtDelete(IndexNum.FList.IndexOf(P));
{$ENDIF}
      // нотификационные сообщения
//         For I:=0 to LotsCount-1 do TLot(LotsLarge[I]).ZeroNotification(LAt(I));
         LotsLarge.AtFree(Index);
         Dec(LotsCount);
        end else
      If What=Twg_Twig then
        begin
         TwigsLarge.AtFree(Abs(Index));
         Dec(TwigsCount);
        end
        else
        begin
         DelAAT(Index);
        end;
    end;


  Procedure TTwigsCollect.DelAAt;
   var ClIndex:SmallInt;P:Pointer;What:Byte;Pr:TPtr;
  begin
   AnyLarge.AtFree(Index);
   PAnyLarge.AtFree(Index);
   Dec(AnyCount);
  end;


  Function  TTwigsCollect.PAt;
  var ClIndex:SmallInt;
  begin
   PAT:=TPtr(PAnyLarge[Index]).Register;
  end;


  Function TTwigsCollect.InsertProject;
   begin
    If GetProject(Name)=-1 then TaheoIndexes.Add(Name);
    Result:=GetProject(Name);
   end;

  Function TTwigsCollect.GetProject;
   var I:SmallInt;
   begin
    GetProject:=-1;
     For I:=0 to TaheoIndexes.Count-1 do
        If AnsiUpperCase(Name)=AnsiUpperCase(TaheoIndexes[I]) then
          begin GetProject:=I;break;end;
   end;

Destructor TTwigsCollect.Destroy;
 var I:SmallInt;
  begin
   try
    AnyLarge.Free;
    PAnyLarge.Free;
    TwigsLarge.Free;
    LotsLarge.Free;
    IndexLarge.DeleteAll;IndexLarge.Free;
//    IndexPlo.DeleteAll;IndexPlo.Free;IndexNum.DeleteAll;IndexNum.Free;IndexGUID.DeleteAll;
   Except
   end;
   Try
{	 For I:=0 to TwigsCol do
	  Dispose(Twigs[I],Done);
	 For I:=0 to LotsCol  do
	  Dispose(Lots[I],Done);
    For I:=0 to AnyCol do
	  Dispose(Any[I],Done);
    For I:=0 to AnyCol Div 16000  do
	  Dispose(PAny[I],Done);}
     For I:=0 to 10 do
       begin
         TaheoDots[I].Free;
         TaheoTwigs[I].Free;
       end;
        Fonts.Free;
        FontSet.Free;
   {}
//   HPoly.Free;
    BitMaps.Free;
    TaheoIndexes.Free;
    FontViewCollect.Free;
    TextManagerCollect.Free;
    BlockList.Free;
   Except
   end;
  end;

{----------------------------------------------------------------------}
Function TTwigsCollect.HorizCount;
 begin
 end;
{}                                                              
 Procedure TTwigsCollect.CreateIndexes;
  var I:Integer;                                           
  begin
   IndexLarge.DeleteAll;
//   IndexPlo.DeleteAll;
//   IndexNum.DeleteAll;
//   IndexGUID.DeleteAll;
//  if GGraphSet.NotIndex=1 then
   For I:=0 to LotsLarge.Count-1 do
    begin
     IndexLarge.Insert(LotsLarge[I]);
    end;
  (*
   For I:=0 to LotsLarge.Count-1 do
    begin
     IndexPlo.Insert(LotsLarge[I]);
    end;
   For I:=0 to LotsLarge.Count-1 do
    begin
     IndexNum.Insert(LotsLarge[I]);
    end;
   For I:=0 to LotsLarge.Count-1 do
    begin
     IndexGUID.Insert(LotsLarge[I]);
    end;
   *)
  { else
   For I:=0 to LotsLarge.Count-1 do
    begin
     IndexLarge.Insert(LotsLarge[I]);
     IndexPlo.Insert(LotsLarge[I]);
    end; }
  end;
{----------------------------------------------------------------------}
// контура индексированные по слоям

Constructor TSloyIndex.Create(Selector_:TSelector);
begin
 inherited Create(1);
 Selector:=Selector_;
end;

Function TSloyIndex.Compare;
var Lot:TLot;P:TPointdot;
begin
{
if not GGraphSet.IndexPlo then
 begin
  Compare:=-1; exit;
 end;}
With Selector do begin
If GGraphSet.IndexPlo then begin
 If TLot(Key1).TypeLot<TLot(Key2).TypeLot then compare:=1 else
 If TLot(Key1).TypeLot=TLot(Key2).TypeLot then begin
  If TLot(Key1).TypeLot = 1 then begin
   If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then
   Compare:=1 else Compare:=-1;
  end else begin
  // if Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=1 else
  // if Round(TLot(Key1).Plo*Const_of_PrecCoord)=Round(TLot(Key2).Plo*Const_of_PrecCoord) then begin
    If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then Compare:=-1 else
    If Frac(TLot(Key1).ClassHandle.Rang)=Frac(TLot(Key2).ClassHandle.Rang) then begin
     If Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then Compare:=1 else Compare:=-1;
    end else
    Compare:=1;
  // end else compare:=-1;
  end;
 end;
exit;
end else
//
 try
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=1 else
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)=Round(TLot(Key2).Plo*Const_of_PrecCoord) then
   begin
    If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then
    Compare:=-1 else Compare:=1;
   end else Compare:=-1;
  except
   Lot:=Key1;P:=Key1;
//   WriteOn(nil,['Except=',Lot=nil,' ',P=nil]);
   raise;
  end;
  exit;
 if (not TLot(Key1).ClassHandle.Indexed) or (not GGraphSet.IndexPlo) then
 begin
  If TLot(Key2).ClassHandle.Indexed then begin compare:=-1; Exit;end;
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=1;
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)=Round(TLot(Key2).Plo*Const_of_PrecCoord) then
   begin
//    wRITELN(11,'=');
//    wRITELN(TLot(Key1).ClassHandle.rANG,' ',TLot(Key2).ClassHandle.rANG);
    If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then
    Compare:=-1 else Compare:=1;
//    wRITELN(12,'=');
   end;
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)>Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=-1;
 end else
 begin
   If not TLot(Key2).ClassHandle.Indexed then begin compare:=1; Exit;end;
   if TLot(Key1).ClassHandle.Index<TLot(Key2).ClassHandle.Index then compare:=1;
   if TLot(Key1).ClassHandle.Index=TLot(Key2).ClassHandle.Index then
    begin
     if Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=1;
     if Round(TLot(Key1).Plo*Const_of_PrecCoord)=Round(TLot(Key2).Plo*Const_of_PrecCoord) then
      begin
       If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then
       Compare:=-1 else Compare:=1;
      end;
     if Round(TLot(Key1).Plo*Const_of_PrecCoord)>Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=-1;
    end;
   if TLot(Key1).ClassHandle.Index>TLot(Key2).ClassHandle.Index then Compare:=-1;
 end;
end;
// Writeln(22222);
end;
{}
// контура индексированные по площади
Constructor TPloIndex.Create(Selector_:TSelector);
begin
 inherited Create(1);
 Selector:=Selector_;
end;

function TPloIndex.Compare;
begin
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)<Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=1 else
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)=Round(TLot(Key2).Plo*Const_of_PrecCoord) then
   begin
    If Frac(TLot(Key1).ClassHandle.Rang)<Frac(TLot(Key2).ClassHandle.Rang) then
    Compare:=-1 else Compare:=1;
   end else
  if Round(TLot(Key1).Plo*Const_of_PrecCoord)>Round(TLot(Key2).Plo*Const_of_PrecCoord) then compare:=-1;
end;
{}
// контура индексированные по номерам
Constructor TNumIndex.Create(Selector_:TSelector);
begin
 inherited Create(1);
 Selector:=Selector_;
end;

function TNumIndex.Compare;
begin
 if TLot(Key1).NLot<TLot(Key2).NLot then compare:=1 else
 if TLot(Key1).NLot=TLot(Key2).NLot then compare:=0 else compare:=-1;
end;

{ TGUIDIndex }

Constructor TGUIDIndex.Create(Selector_:TSelector);
begin
 inherited Create(1);
 Selector:=Selector_;
end;

function TGUIDIndex.Compare(Key1, Key2: Pointer): Integer;
var I:Integer;
begin
 if TLot(Key1).Guidstr<TLot(Key2).Guidstr then compare:=1 else
 if TLot(Key1).Guidstr=TLot(Key2).Guidstr then compare:=0 else compare:=-1;
end;

function TGUIDIndex.KeyOf(Key: Pointer): Pointer;
begin
 Result:=Key;
end;

{----------------------------------------------------------------------}

{ TFontScaleCollect }

function TFontViewCollect.InsertFont;
var F:TFontViewEx;I:Integer;DC:hDc;
begin
 For I:=0 to Count-1 do begin
  F:=At(I);
  if F.isEqual(FontName,Char_Set,bl,it,un) then begin
   Result:=F;Exit;
  end;
 end;
 {$IFDEF WIN64}Dc:=GetDC(0);{$ELSE}Dc:=0;{$ENDIF}
 F:=TFontViewEx.Create(DC,FontName,FH,FH*0.4,Char_Set,bl,it,un);
 Insert(F);
 Result:=F;
  {$IFDEF WIN64}ReleaseDc(0,Dc);{$ENDIF}
end;


{ TTextManagerCollect }

function TTextManagerCollect.InsertManager(M: TTextManager): TTextManager;
var I:Integer;
begin
 if M=nil then begin Result:=nil; Exit;end;
 For I:=0 to Count-1 do
  If TTextManager(At(I)).Equal(M) then begin
   Result:=At(I);
   if M<>Result then M.Free;
   Exit;                                                      
  end;                                       
 Result:=M;                            
 Insert(M);                                                 
end;

function TTWigsCollect.FindTwigSpatial(Twig: TTwig): Integer;
var I:Integer;
    SumTwig:Double;
    Twig_:TTwig;
begin
 Result:=ZNULL*100;
 exit;
 SumTwig:=Twig.SUMTwig;
 For I:=1 to TwigsCount-1 do begin
  Twig_:=TAT(I);
  If Round(Twig_.SUMTwig*1000)=Round(SumTwig*1000) then begin
   //If EqualPoints(Twig_.First,Twig.Last) then Result:=-I else
   //If EqualPoints(Twig_.First,Twig.First) then Result:=I else continue;
   Result:=I;
   exit;
  end;
 end;
end;

begin
end.
