unit uExecRegisterClass;

interface
 uses
  newProcs,Collect,WpTwigs,WptForm2,WpRects,WpArcs,Types_Dimano,TwgColle,TextManager,RPrims,
  ObjBlockList,newProperties,newLayersTable,newForm0,newFontScale,newBlock,mpMarker,Lines2,
  Lines3, Lib2,
  Lib,HatchLot,DwgText,ecDot,ecDot2,ecLot,ecText,newResource,
  FMX.Dialogs;

procedure RegPrimitives;

implementation uses FMX.Forms, System.IOUtils, Writer;

procedure RegPrimitives;
begin
// newProcs
 MainPath := Application.GetNamePath;
// Collect
 RegisterObject(PCollection,50);
 RegisterObject(TSortedCollection,51);
 RegisterObject(TCStrings,52);
 RegisterObject(TStrClass,53);
// WpTwigs
 RegisterObject(TDot, 3000);
 RegisterObject(TTwig, 3001);
 RegisterObject(TClassTwig, 3021);
 RegisterObject(T3DTwig, 3023);
 RegisterObject(TPtr, 3999);
 RegisterObject(TTwigARC, 3024);
 RegisterObject(TTwigTriangle, 3030);
 RegisterObject(TTwigCoif, 3031);
 RegisterObject(TDataTwig, 3032);
// WptForm2
 RegisterObject(TForm2,10000);
// WpRects
 RegisterObject(TTwigRect,3033);
// WpArcs
 RegisterObject(TArcTwig,3022);
 RegisterObject(TTwigSpline,3025);
 RegisterObject(TTwigSpline3D,3026);
 RegisterObject(TTwigSpline3DB,3027);
 RegisterObject(TTwigSpline3DHermit,3028);
 RegisterObject(TTwigCircle,3029);
// Types_Dimano
 RegisterObject(T3DPoint,6103);
 RegisterObject(TRealCollect,6104);
 RegisterObject(TDouble,6105);
// TwgColle
 RegisterObject(TLong,1102);
 RegisterObject(TIntNum,1103);
 RegisterObject(TExp,1104);
 RegisterObject(TExpColor,1105);
 RegisterObject(TExt,1106);
// TextManager
  RegisterObject(TTextManager, 5120);
  RegisterObject(TTextParams, 5121);
// RPrims
 RegisterObject(TBmpMgr,101);
 RegisterObject(TBmpSet,102);
// ObjBlockList
 RegisterObject(TBlockList,6002);
 RegisterObject(TLinkFiles,6003);
 RegisterObject(TTexture,6004);
 RegisterObject(TTextureList,6005);
// newProperties
 RegisterObject(TProperty,4010);
 RegisterObject(TProperties,4011);
 RegisterObject(TPropValue,4012);
// newLayerTable
 RegisterObject(TLayerTable,32009);
// newForm0
 RegisterObject(TTwigsCollect,9000);
// neFontScale
 RegisterObject(TFontViewEx,152);
 RegisterObject(TFontScaleEx,153);
 RegisterObject(TFontManagerEx,154);
// newBlock
  RegisterObject(TGeoBlock,4001);
//mpMarker
 RegisterObject(TMarkerOperation,121);
 RegisterObject(TMarkerView,122);
 MarkerList:=TMarkerList.Create;
 MarkerList.AddMarker(mtCross);MarkerList.AddMarker(mtDiagCross);MarkerList.AddMarker(mtRect);MarkerList.AddMarker(mtTriangle);MarkerList.AddMarker(mtInvTriangle);
 MarkerList.AddMarker(mt2Triangle);
// Lines2
 GlobalLine:=TGeoLine.Create('Global_Line');
 RegisterObject(TGeoLine,5106);
 RegisterObject(TLineStruct,5107);
// Lib2
 GlobalSqwear:=TSqwear_Sign.Create('Global_SQ');
 RegisterObject(TSqwear_Sign,5104);
 RegisterObject(TPart,5105);
// Lib
 GlobalPoint:=TPoint_Sign.Create(0,0,'Global_Point');
  RegisterObject(TDWG_Line,5100);
  RegisterObject(TDWG_Arc,5101);
  RegisterObject(TMeth,5103);
  RegisterObject(TPoint_Sign,5102);
  RegisterObject(TPn,5111);
  RegisterObject(TDWG_Poly,5112);
  RegisterObject(TDWG_Text, 5113);
  RegisterObject(TDWG_Pie, 5114);
// HatchLot
 RegisterObject(THatchLot,3104);
 RegisterObject(TPolyTwig,3105);
// DwgText
  PointDrawText:=True;
  RegisterObject(TFontManager,154);
// ecDot
 RegisterObject(TPDot,5201);
 RegisterObject(TPointDot,5202);
 RegisterObject(TPointMessage,5203);
// ecDot2
 RegisterObject(TText,3002);
 RegisterObject(TDotText,3003);
// ecLot
 RegisterObject(TLot,3103);
 RegisterObject(THatches,31031);
 RegisterObject(TLine,31032);
// ecText
 RegisterObject(TEFont,5200);
// newResource
 RegisterObject(TResource,280);
 {}
   With GResRec do
    begin
      RGB.Argb[1]:=120;
      RGB.Argb[2]:=120;
      RGB.Argb[3]:=120;
      ID:=0;
      Rang:=2.99;
      RecString:='Новый+Новый';
      SSInd:=-1;
      ZnkInd.LInd :=-1;
      ZnkInd.SpInd :=-1;                                 {89101772713}
      Check:=1;
     { По базе }
      NBase:=1;
      Hatch:=4;
     { Ver 6 }
      NameBase:='Нет связей';
      NameMark:='Не подписывать';
      NameLot:='Erko';
     { Ver 7 отображение}
      Lot  :=Ot_Twig;  { Заливка-ветви }
      Znak :=0;  { Условные знаки }
      ZnakKoef:=0.5;
      Fon  :=0;  { Непрозрачный фон }
      Marked:=1;  { Подписывать }
      Standart:=1;
      MakeUsel:=True;
     {}
      FName:='System';
      FColor:=RGBToCol(90,90,90);
      FAttr[F_It]:=0;
      FAttr[F_Bl]:=0;
      FAttr[F_Un]:=0;
      FH:=4;
      FW:=2;
     // FRasp:=Ta_Left;
      FDx:=0;FDy:=0;
     {}
      Page:=0;
     {}
      ConGen:=4;
      Clip:=0;
     {}
      Opaque:=False;
      OpColor:=RGBToCol(255,255,255);
      OpWin:=False;
      Childs:=PCollection.Create(1);
     {}
      brTabName:='';
      brFieldName:='';
      brFieldIn:='';
      brMArk:='';
     {}
      Index:=-1;
     {}
      LineColor:=RGBToCol(0,0,0);
      NoPerehlest:=0;
     {}
      RRepName:='';
      RUse:=0;
      RMarkIndex:=0;
      RFieldName:='';
      RPreview:=False;
     {}
      isPrevStandart:=0;
      ObjectTypes:=[otPoint,otLinear,otPolygon,otFont];
     {}
      LineWidth:=-1;
     end;
end;


end.
