Unit newClassBuilder;

Interface uses  Collect, WPTwigs, EcLot, TwgColle, EcDot, newForm0,
                newConsts, newFontScale, newLayersTable, newSelector;

var binQuickPaint:boolean;

Procedure BuildPoint1(View:TSelector;LayerTable:TLayerTable;TWF:TTwigsCollect;PP:TPointDot);
Function Build1(View:TSelector;ClassName1:AnsiString;var TWF:TTwigsCollect;var MosLib:TMosLib;MirrorObject:Boolean=False):Boolean;

var ClassRebuildIndex,ClassRebuildSbor,ClassRebuildBlock:Boolean;

Implementation uses RPrims, Lib, TextManager,  SysUtils, newBlock, WPTForm2,
                    Classes, newProcs, DwgText, EcDot2, objBlockList,
                    userObject, FMX.Graphics, newResource, newProperties, Writer;

Procedure BuildPoint1(View:TSelector;LayerTable:TLayerTable;TWF:TTwigsCollect;PP:TPointDot);
var Res:TResource;UZnak:TPoint_Sign;P:PCollection;
    S:String;
    FName:String;
    propHFont,propFStyle:TPropValue;
    HFont:Double;FStyle:Integer;
    Index,J:Integer;
    Block:TGeoBlock;
    Sect:TSect;
    Color:Integer;
    propValue:TPropValue;
    BlockSect: TSect;
begin
// Writein(['cbp1']);
 Res:=LayerTable.SearchLayer(PP.Code);
 if Res=nil then Res:=LayerTable.NullLayer;
  PP.ClassHandle:=Res;
  wbRGB(View,PP.R,PP.G,PP.B);
  PP.SqlClosed:=Res.Check=0;
 // если не блок, устанавливаем параметры для текста
 If PP.userObj=nil then begin
 // установка свойств
    propValue:=PP.GetPropValue('Знак');
    If propValue<>nil then begin If propValue.isInteger then PP.What:=propValue.intValue else PP.What:=Res.ZnkInd.SPInd; end else PP.What:=Res.ZnkInd.SPInd;
    propValue:=PP.GetPropValue('Масштаб');
    If propValue<>nil then begin If propValue.isFloat then PP.Koef:=propValue.FloatValue else PP.Koef:=Res.ZnakKoef; end else PP.Koef:=Res.ZnakKoef;
    propValue:=PP.GetPropValue('Цвет');
    If propValue <> nil then begin
     If propValue.isInteger then begin
      PP.R:=GetR(propValue.intValue);
      PP.G:=GetG(propValue.intValue);
      PP.B:=GetB(propValue.intValue);
     end else begin
      PP.R:=Res.Rgb.Argb[1];
      PP.G:=Res.Rgb.Argb[2];
      PP.B:=Res.Rgb.Argb[3];
     end;
    end else begin
     PP.R:=Res.Rgb.Argb[1];
     PP.G:=Res.Rgb.Argb[2];
     PP.B:=Res.Rgb.Argb[3];
    end;
 // установка свойств для текста
  J:=SearchThis(LayerTable.MkLib.PSLib,(abs(PP.What)));
  if J<>-1 then begin
    UZnak:=LayerTable.MkLib.PSLib[J];
    if PP.TextManager<>nil then begin
      P:=PCollection.Create(1);P.Insert(UZnak);
       PP.TextManager.Update(P);
      P.DeleteAll;P.Free;
       FName:=PP.GetProperty('Шрифт');If (FName=byLayer)or(FName=byNone) then FName:='';
       propHFont:=PP.GetPropValue('Размер');If propHFont=nil then HFont:=0 else
                                             If propHFont.isFloat then HFont:=propHFont.floatValue else begin
                                              If propHFont.Value = byLayer then HFont:=0 else HFont:=-10000;
                                             end;
       propFStyle:=PP.GetPropValue('Стиль');If propFStyle=nil then FStyle:=-1 else begin If propFStyle.isInteger then FStyle:=propFStyle.intValue else FStyle:=-1; end;
       PP.TextManager.SetUserParams(FName,HFont,FStyle);
     end;
    end;
 end;
//  Writein(['cbp2']);
 //
  PP.ResetParams(0,nil); // TTextDot.What := 1;
  //  Writein(['cbp3']);
    If PP.userObj<>nil then begin
      Case PP.userObj.objType of
       TWG_Block:begin
                  Block:=TWF.BlockList.BlockByName(PP.userObj.sysName,Index);
                   If Block<>nil then begin // если найден блок
                   // try PP.blockStretch:=StrToFloat(PP.GetProperty('Растяжение')) except PP.blockStretch:=1;end;
                    If not Block.MyTwgForm then
                      If TGeoBlock(PP.userObj).TwgForm=nil then begin
                       PP.userObj.Free;PP.userObj:=Block;
                      end;
                      // PP.userObj:=Block;
                   end else PP.userObj:=nil;
                   If PP.userObj<>nil then begin
                     TGeoBlock(PP.userObj).deVisible(PP.XDot,PP.YDot,PP.Ugol,PP.XKoef,PP.YKoef,BlockSect);
                    If binQuickPaint then begin
                     If PP.Buffer<>nil then PP.Buffer.Free;
                     PP.Buffer:=TMemoryStream.Create;
                    // PP.binDraw(TWF,PP.Buffer);//,PP.XDot,PP.YDot,PP.Ugol,PP.XKoef,PP.YKoef);
                     PP.Buffer.Position:=0;
                    end;
                   end;
                 end;
       {TWG_Ole}100:begin
               end;
      end;
   end;
 If PP is TPointMessage then PP.What:=0;
 //  Writein(['cbp31']);
 PP.SetGabarites(nil);
  // Writein(['cbp4']);
end;

Function Build1(View:TSelector;ClassName1:AnsiString;var TWF:TTwigsCollect;var MosLib:TMosLib;MirrorObject:Boolean=False):Boolean;
var I,J,Index:Integer;
    LayerTable:TLayerTable;
    Twig:TTwig;CTW:TClassTwig;
    Res:TResource;
    Lot:TLot;
    PP:TPointDot;
    B:Byte;
    Bm:RPrims.TBmpMgr;Br:TBitmapRec;
    Block:TGeoBlock;
    primColor:Integer;
    primLineColor:Integer;
    primZnak:Integer;
    primKoef:Double;
    propValue:String;
    primLineWidth:Double;
    primLineCoor:Integer;
begin
//  If MosLib=nil then Exit;
// If not TForm2(TWF.TwgForm).MirrorObject then Screen.Cursor:=crHourGlass;
 With View do try
  If GGraphSet.fntFontRus then Char_Set:=Russian_CharSet else Char_Set:= 0;//Default_CharSet;  fmx
 // устанавливаем параметры
  LayerTable:=MosLib.LayerTable;
  LayerTable.ShowLayerTable;
  if LayerTable=nil then exit;
  // проходим по веткам для установки начальных параметров
//    WriteS(['Twigs']);
    For I:=1 to TWF.TwigsCount-1 do
     begin
      Twig:=Twf.TAt(I);
      Twig.SetMinMax;
      Twig.ParentIndex:=I;
      Twig.Rang:=0;
      Twig.ClassHandle:=LayerTable.NullLayer;
    {}
      If Twig is TClassTwig then begin
        CTW:=Twig as TClassTwig;
          Res:=LayerTable.SearchLayer(CTW.Code);
          if Res=nil then Res:=LayerTable.NullLayer;
           If Res<>nil then
            begin
             CTW.ClassHandle:=Res;
             CTW.MakeUsel:=CTW.ClassHandle.MakeUsel;
             CTW.UZnak:=CTW.ClassHandle.ZnkInd.LInd;
             CTW.StColor:=CTW.ClassHandle.LineColor;
             Twig.Rang :=Round(Frac(Res.Rang)*100);
           end else MessageInform('CTW.Resource=nil');
         end;
     end;
 // end of Twigs
//    WriteS(['Twigsend']);
 For I:=0 to TWF.TextureList.Textures.Count-1 do TWF.TextureList.Texture[I].Used:=False;
 // проходим по точкам и шрифтам
//    WriteS(['Any']);
 For I:=0 to TWF.AnyCount-1 do begin
  PP:=Twf.AAT(I,B);
   If B=TWG_Point then begin
      try
//    WriteS(['Any',I]);
       BuildPoint1(View,LayerTable,TWF,PP);
//    WriteS(['AnyE`',I]);
      except
     // BuildPoint1(LayerTable,TWF,PP);
       MessageError('Except BuildPoint N='+IntToStr(I));
      end;
  // билдим точки в биогруппах/диапазонах (ОЗН)
   If PP.Trees<>nil then For J:=0 to PP.Trees.Count-1 do BuildPoint1(View,LayerTable,TWF,PP.Trees[J]);
  end;
 end;
 // end of Any
 // проходим по контурам
//    WriteS(['Lots']);
 For I:=0 to TWF.LotsCount-1 do begin
   Lot:=TWF.LAt(I);
     {}
   Res:=LayerTable.SearchLayer(Lot.ClassCode);
   if Res=nil then begin
  //  ShowMEssage('Except BuidRes N='+IntToStr(I));
    Res:=LayerTable.NullLayer;
   end;
  Lot.Inv:=0;
  Lot.ClassHandle:=Res;
  If Lot.ClassHandle.OpWin then Lot.ClassHandle.OpColor:=GlobalSettings.Settings.gsWindowColor;
  Lot.Closed:=Res.Check;
// устанавливаем свойства
  primLineColor:=wbColor(View,Lot.LotLineColor);
  primKoef:=Lot.csKoef;
 If (Lot.UID<>nil) then If Lot.UID = '+++' then
  primZnak:=Lot.csLineZnak;
  primZnak:=Lot.csLineZnak;
  If Lot.Properties = nil then primLineWidth:=Res.LineWidth else primLineWidth:=Lot.Properties.GetFloatValueDef('Толщина',Res.LineWidth);
 // текстуры
  propValue:=Lot.GetProperty('#Текстура');
  If propValue<>byLayer then begin
   Lot.Texture:=TWF.TextureList.Add(propValue);
   If Lot.Texture<>nil then Lot.Texture.Used:=True;
  end else Lot.Texture:=nil;
  If Lot.Properties = nil then Lot.TexX:=1 else Lot.TexX:=Lot.Properties.GetFloatValueDef('#ТекстураMX',1);
  If Lot.Properties = nil then Lot.TexY:=1 else Lot.TexY:=Lot.Properties.GetFloatValueDef('#ТекстураMY',1);
  If Lot.Properties = nil then Lot.TexAngle:=0 else Lot.TexAngle:=Lot.Properties.GetFloatValueDef('#Текстура угол',0);
  If Lot.Properties = nil then Lot.TexScale:=500 else Lot.TexScale:=Lot.Properties.GetFloatValueDef('#Текстура М1:',500);
  If Lot.Properties = nil then Lot.Alpha:=0 else Lot.Alpha:=Lot.Properties.GetIntValueDef('#Прозрачность',0);
 // проходим по сегментам
  For J:=0 to Lot.Coord.Count-1 do begin
    Twig:=TWF.TAt(TLong(Lot.Coord.At(J)).Num);
   // если приоритет меньше
    If Twig.Rang<Round(Frac(Res.Rang)*100) then begin
    Twig.Rang :=Round(Frac(Res.Rang)*100);
    Twig.ClassHandle:=Lot.ClassHandle;
 {GB}If not (Twig.Locked = 1) then begin
      Twig.UZnak:=primZnak;//Res.Znkind.LInd;
      Twig.NotPere:=Res.NoPerehlest;
     end;
   Twig.StColor:=primLineColor;
   Twig.Koef:={abs(}primKoef{)};
   Twig.MakeUsel:=Res.MakeUsel;
   Twig.Closed:=Res.Check;
   Twig.MakeUsel:=Res.MakeUsel;
   Twig.LineWidth:=primLineWidth;
  end; // if Twig.Rang<
 end;// For J:=0 to Lot.Coord.Co..
end; // For I:=0 t...
// end of Lots
// растры
//    WriteS(['LotsEnd']);
  For I:=TWF.TextureList.Textures.Count-1 downTo 0 do If not TWF.TextureList.Texture[I].Used then TWF.TextureList.Textures.AtFree(I);
//    WriteS(['Bitmaps']);
   With TWF.Bitmaps do
    For I:=0 to Bitmaps.Count-1 do
     begin
      Bm:=Bitmaps[I];
      Res:=LayerTable.SearchLayer(Bm.Code);
       If Res<>nil then
        begin
           Bm.SqlClose:=False;
           Bm.ClassHandle:=Res;
           Br:=Res.GetBitmapRec;
         {if Br.Window then
            Res.FColor:=GGraphSet.ColWin;}
        end else Bm.ClassHandle:=nil;
     end;
//    Writeln('EndBitmap');
  If ClassReBuildIndex then begin TWF.CreateIndexes;ClassRebuildIndex:=False;end;
  try
//    WriteS(['Blocks']);
  If ClassRebuildBlock then
   If TWF.BlockList<>nil then
    For I:=0 to TWF.BlockList.Count-1 do begin
     TGeoBlock(TWF.BlockList[I]).TwgForm.MkLib:=MosLib;
     TGeoBlock(TWF.BlockList[I]).TwgForm.Settings:=TForm2(TWF.TwgForm).Settings;
     TGeoBlock(TWF.BlockList[I]).TwgForm.LayerTable:=MosLib.LayerTable;
     ClassRebuildIndex:=True;
     Build1(View,ClassName1,TGeoBlock(TWF.BlockList[I]).TwgForm.Twigs,MosLib,True);
     With TGeoBlock(TWF.BlockList[I]) do begin
      {If binQuickPaint then begin
       If Buffer<>nil then Buffer.Free;
       Buffer:=TMemoryStream.Create;
       binDraw(Buffer,X,Y,0,1,1,False);
       Buffer.Position:=0;
      end;}
     end;
    end;
 except
  MessageError('Except BuildBlocks N='+IntToStr(I));
 end;
  //
 finally
//  If not TForm2(TWF.TwgForm).MirrorObject then Screen.Cursor:=crDefault;
  ClassRebuildBlock:=False;
 end;
end;

var I:Integer;
begin
 ClassRebuildIndex:=True;
 ClassRebuildSbor:=False;
 ClassRebuildBlock:=False;
// allocConsole;
end.
