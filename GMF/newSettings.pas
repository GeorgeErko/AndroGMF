unit newSettings;

interface uses Collect, newProperties, FMX.Controls, FMX.Objects;


type
  TSettings = class (TTwgObject)
  private
    function GetProperties: TProperties;
    procedure SetProperties(const Value: TProperties);
  // рисование
  public
   psOrtho:Boolean;
   psOrthoDisst:Integer;
   psAuto:Boolean;
   psAutoDisst:Integer;
   psInsert:Boolean;
   psTwise:Boolean;
   psStvor:Boolean;
   psOrthoTwigs:Boolean;
   psOrthoTwigsCount:Integer;
   psArcCount:Integer;
   psSplineCount:Integer;
   psSaveOrthoTwigs:Boolean;
  //
   psLineArc:Boolean;
   psLineSpline:Boolean;
  // Bitmap
   bmColor:Integer;
   bmBackColor:Integer;
   bmGlass:Boolean;
   bmFrame:Boolean;
  // Grid
   gsShowGrid:boolean;
   gsScale:Integer;
   gsGridCellWidth :Double; // расстояние между узлами по X в сантиметрах
   gsGridCellHeight:Double;
   gsGridType:Integer;
   gsGridColor:Integer;
   gsGridLineWidth:Integer;
   gsGridSize:Double; // размер штриха креста в см
   gsHalfGrid:Boolean;
   gsGlass:Boolean;
  // рисование
   psQueryLayerDraw:Boolean;
   psQueryLayerSbor:Boolean;
   psQueryLayerAttrib:Boolean;
  //
   psTwiseLot:Boolean;
   psNoAssociativeFill:Boolean;
   psOrthoMode:Boolean;
   psWidthPath:Boolean;
   psNumberUch:Byte;
   Dop:Array[0..1990]of byte;
   Image:TImage;
   Vars:PCollection;
    Constructor Create(Scale:Integer;Name:String);
     Constructor Load(var Stream:TBufStream);
     Procedure  Store(var Stream:TBufStream);
    Destructor Destroy;override;
    Property Properties:TProperties read GetProperties write SetProperties;
  end;

 Const
    HD_Auto=1;
    HD_PAuto=2;
    HD_Manual=3;
   {}
    HF_Usl=1;
    HF_UslAll=2;
    HF_All=3;

 Type
   TGraphset=packed record
      KU         :Single;  { Увеличение }
      Scroll     :Byte;    { Прокрутка  }
      Selector   :Byte;    { Толщина выделенной ветви }
      RPoint     :Byte;    { Радиус точки }
     { Цвета }
      ColWin     :FixedInt;
      ColTwig    :FixedInt;
      ColActive1  :FixedInt;
      ColNoSbor  :FixedInt;
      WinInd  :Byte;
      TwigInd :Byte;
      ActiveInd:Byte;
      NoSborInd:Byte;
     {}
      TwigView,
      FillTwig,
      SborView :Byte;
     {}
      LotView,
      FillLot,
      TextLot  :Byte;
      ViewZnaks:Byte;
     {}
      TextView,
      PointView:Byte;
      UslPoint,
      TvdPoint,
      AllPoint,
      LotPoint:Byte;
      ColAll,
      ColTvd,
      ColUsl:FixedInt;
      PointStyle:Byte;
     { Несостыки }
      HardRad:Single;
      HardDelete,
      HardFind:Byte;
      PereDelete:Byte;
     {}
     { Экспликация }
      ExpLot:Byte;
      Page:Byte;
      AddLine:Byte;
      AddLinelen:Single;
      SetPere:Byte;
      MinOtr :Byte;
      FontPointIns:Byte;
     { Таблицы }
      TableFullName:Byte;
      TableVisible :Byte;
     {}
      TableFont:String[30];
      TableFSize:SmallInt;
      TableFBold:Byte;
      TableFColor:FixedInt;
      TableColor:FixedInt;
      TableVert:Byte;
      TableHoriz:Byte;
     { Марки }
      mGroups    :Byte;
      GroupName :String[50];
      mFixed    :Byte;
      FixName   :String[30];
      mH,mW     :Single;
      mInLot    :byte;
    {}
      OpenFon   :Byte;
      NotIndex  :Byte;
      IndexNum  :FixedInt;
    {}
      Taheo     :Byte;
    {}
      GetCode   :Byte;
    {}
      SaveScreen:Byte;
    {}
      ColorZnak :FixedInt;
      CZ1        :Boolean;
      CZR1,CZG1,CZB1:Byte;
    {}
      LinZnk    :Boolean;
      Kvant     :Integer;
      ArcKv     :Integer;
      SetFont   :Boolean;
      UgFont    :Single;
    {}
      UpLot     :Boolean;
    {}
      DelMarks  :Boolean;
    {}
      AddMarks  :Boolean;
      ClipMarks :Boolean;
      SkipMarks :Boolean;
      ActivateLot:Boolean;
    {}
      IndexPlo  :Boolean;
    {}
      InsertAsOld:Boolean;
    {}
      SprName:Array[0..25] of AnsiChar;
    {Детализация}
      FPoints:Double;
      FLines :Double;
      FPntZnk:Integer;
      FFonts :Integer;
      FUpdate:Double;
    {}
      HorPoly:Boolean;
    {}
      InsertInter:Boolean;
      InterRasst:Single;
      DelMinPere:Boolean;
      DelMinRasst:Single;
    {}
      PCOprIndex:Byte;
    { Растр }
      bmGlass:Boolean;
      bmBack:Integer;
      bmColor:Integer;
    { Сколка }
      skShift:Byte;
      skBreak:Boolean;
      skOrto:Boolean;
      skOrtoAngle:Single;
      skStvor:Boolean;
      skStvorAngle:Single;
      skShiftLineBool:Boolean;
      skShiftLine:Byte;
    {}
      fntMarker:Byte;
    {Детализация}
      FClipTwig:Double;
    {Просчет площадей}
      ploSetDim:Boolean;
    {}
      fntFontRus:Boolean;
    {Детализация}
      FAllZnaks:Double;
    {}
      ColorClosed:FixedInt;
      ShowClosed:Boolean;
    {}
      UseAutoScroll:Boolean;
      AutoScroll:Single;
    {}
      UseRastrRect:Boolean; // обрамление растра
    { Дополнения по пересечеиям }
      Pere_Line,Pere_PointPoint,Pere_PointLine:Boolean;
    {}
      MaxPlo:Double;
      ActiveFontColor:FixedInt;
    {Атрибуты}
      ShowAttributes:boolean;
    {Растры}
      UpRastr:boolean;
    {}
      ActiveRasterCol:Integer;
      PaintFragment:Double; // размер окна больше которого не происходит поиска маркера
      Dop:Array[0..876-sizeOf(Double)] of AnsiChar;
   end;

 var GGraphset:TGraphSet;

 type
 TSettingsRec = record
  gsPointSize:Integer;
  gsSelectColor:Integer;
  gsWindowColor:Integer;
  gsColorZnaksCheck:Boolean;
  gsColorZnaks:Integer;
  gsFillPointCheck:Boolean;
  gsFillPointColor:Integer;
  gsColorUzl:Integer;
  gsColorDot:Integer;
  gsColorPoint:Integer;
  gsSelectPointColor:Integer;
  gsGlueMarkerColor:Integer;
  gsShowPlan:Boolean;
  gsPointZnak:Integer;
  gsX,gsY,gsZoom:Single;
  gsLevelsSelect:Boolean;
  gsBinds:Boolean;
  Dop:Array[1..995-3*SizeOf(Single)-1-1] of byte;
 end;

type
 TGlobalSettings = class(TTwgObject)
  Settings:TSettingsRec;
  MarkerView:TTwgObject;
  Constructor Create;
  Destructor Destroy;override;
  Function CZ:Boolean;
  Function CZR:Byte;
  Function CZG:Byte;
  Function CZB:Byte;
 end;

implementation uses newProcs, newConsts, mpMarker, System.UITypes;

{ TSettings }

constructor TSettings.Create(Scale: Integer;Name:string);
begin
// If (Name='*') then exit;
 Vars:=PCollection.Create(1);
 //
  psOrtho:=(Scale>100) and (Scale<10000); // маркер прямоугольного рисования
  psOrthoDisst:=4;
  psAuto:=True; // автопритягивание при рисовании
  psAutoDisst:=3;
  psInsert:=(Scale>100) and (Scale<10000); // вставка точек при притяжении к сегменту
  psTwise:=psInsert; // разбивка сегмента при притяжении
  psStvor:=True; // притяжение к сегменту по створу рисуемой полилинии
 //
  psOrthoTwigs:=False; // направляющие
  psOrthoTwigsCount:=20; // максимальное количество направляющих
  psSaveOrthoTwigs:=False; // запоминать направляющие
 //
  psArcCount:=10; // отрезков на дуге
  psSplineCount:=5; // отрезков на сплайне
 // растр
  bmColor:= TAlphaColors.Silver;
  bmBackColor:= TAlphaColors.White;
  bmGlass:=(Scale>100) and (Scale<25000);
  bmFrame:=False;
 // сетка
  gsShowGrid:=False;
  gsScale:=Scale;
  gsGridType:=1;
  gsGridColor:= TAlphaColors.Black;
  gsGridLineWidth:=0;
  gsGridSize:=1;
  gsGridCellWidth:=10;
  gsGridCellHeight:=10;
 //
  psQueryLayerDraw:=True;
  psQueryLayerSbor:=True;
  psNoAssociativeFill:=True;
 //
  psTwiseLot:=False;
  Image:=nil;
end;

destructor TSettings.Destroy;
begin
 Vars.Free;
 If Image<>nil then Image.Free;
 // восстанавливаем предыдущие значения
end;

function TSettings.GetProperties: TProperties;
begin
 If Vars.Count = 0 then begin Vars.Insert(TProperties.Create);end;
 Result:=Vars[0];
end;

procedure TSettings.SetProperties(const Value: TProperties);
begin
 TTwgObject(Vars[0]).Free;Vars[0]:=Value;
end;

constructor TSettings.Load(var Stream: TBufStream);
var B:Boolean;
begin
  Stream.Read(psOrtho, SizeOf(psOrtho));
  Stream.Read(psOrthoDisst, SizeOf(psOrthoDisst));
  Stream.Read(psAuto, SizeOf(psAuto));
  Stream.Read(psAutoDisst, SizeOf(psAutoDisst));
  Stream.Read(psInsert, SizeOf(psInsert));
  Stream.Read(psTwise, SizeOf(psTwise));
  Stream.Read(psStvor, SizeOf(psStvor));
  Stream.Read(psOrthoTwigs, SizeOf(psOrthoTwigs));
  Stream.Read(psOrthoTwigsCount, SizeOf(psOrthoTwigsCount));
  Stream.Read(psArcCount, SizeOf(psArcCount));
  Stream.Read(psSplineCount, SizeOf(psSplineCount));
  Stream.Read(psSaveOrthoTwigs, SizeOf(psSaveOrthoTwigs));
 //
  Stream.Read(psArcCount, SizeOf(psArcCount));
  Stream.Read(psSplineCount, SizeOf(psSplineCount));
 //
  Stream.Read(bmColor, SizeOf(bmColor));
  Stream.Read(bmBackColor, SizeOf(bmBackColor));
  Stream.Read(bmGlass, SizeOf(bmGlass));
  Stream.Read(bmFrame, SizeOf(bmFrame));
 // сетка
  Stream.Read(gsShowGrid, SizeOf(gsShowGrid));
  Stream.Read(gsScale, SizeOf(gsScale));
  Stream.Read(gsGridType, SizeOf(gsGridType));
  Stream.Read(gsGridColor, SizeOf(gsGridColor));
  Stream.Read(gsGridSize, SizeOf(gsGridSize));
  Stream.Read(gsGridCellWidth, SizeOf(gsGridCellWidth));
  Stream.Read(gsGridCellHeight, SizeOf(gsGridCellHeight));
 //
  Stream.Read(psQueryLayerDraw, SizeOf(psQueryLayerDraw));
  Stream.Read(psQueryLayerSbor, SizeOf(psQueryLayerSbor));
  Stream.Read(psQueryLayerAttrib, SizeOf(psQueryLayerAttrib));
 //
  Stream.Read(psTwiseLot, SizeOf(psTwiseLot));
  Stream.Read(psNoAssociativeFill, SizeOf(psNoAssociativeFill));
  Stream.Read(psOrthoMode, SizeOf(psOrthoMode));
 //
  Stream.Read(psLineArc, SizeOf(psLineArc));
  Stream.Read(psLineSpline, SizeOf(psLineSpline));
  Stream.Read(psWidthPath,1);
  Stream.Read(psNumberUch,1);
  Stream.Read(Dop,SizeOf(Dop));
  Vars:=PCollection(Stream.Get);
  If Version>51 then begin
   Stream.Read(B,1);
   If B then begin
    Image:=TImage(Stream.Stream.ReadComponent(Image));
   // Stream.Position:=Stream.Stream.Position;
   end;
  end else Image:=nil;
end;


procedure TSettings.Store(var Stream: TBufStream);
var B:Boolean;
begin
  Stream.Write(psOrtho, SizeOf(psOrtho));
  Stream.Write(psOrthoDisst, SizeOf(psOrthoDisst));
  Stream.Write(psAuto, SizeOf(psAuto));
  Stream.Write(psAutoDisst, SizeOf(psAutoDisst));
  Stream.Write(psInsert, SizeOf(psInsert));
  Stream.Write(psTwise, SizeOf(psTwise));
  Stream.Write(psStvor, SizeOf(psStvor));
  Stream.Write(psOrthoTwigs, SizeOf(psOrthoTwigs));
  Stream.Write(psOrthoTwigsCount, SizeOf(psOrthoTwigsCount));
  Stream.Write(psArcCount, SizeOf(psArcCount));
  Stream.Write(psSplineCount, SizeOf(psSplineCount));
  Stream.Write(psSaveOrthoTwigs, SizeOf(psSaveOrthoTwigs));
 //
  Stream.Write(psArcCount, SizeOf(psArcCount));
  Stream.Write(psSplineCount, SizeOf(psSplineCount));
 //
  Stream.Write(bmColor, SizeOf(bmColor));
  Stream.Write(bmBackColor, SizeOf(bmBackColor));
  Stream.Write(bmGlass, SizeOf(bmGlass));
  Stream.Write(bmFrame, SizeOf(bmFrame));
 // сетка
  Stream.Write(gsShowGrid, SizeOf(gsShowGrid));
  Stream.Write(gsScale, SizeOf(gsScale));
  Stream.Write(gsGridType, SizeOf(gsGridType));
  Stream.Write(gsGridColor, SizeOf(gsGridColor));
  Stream.Write(gsGridSize, SizeOf(gsGridSize));
  Stream.Write(gsGridCellWidth, SizeOf(gsGridCellWidth));
  Stream.Write(gsGridCellHeight, SizeOf(gsGridCellHeight));
 //
  Stream.Write(psQueryLayerDraw, SizeOf(psQueryLayerDraw));
  Stream.Write(psQueryLayerSbor, SizeOf(psQueryLayerSbor));
  Stream.Write(psQueryLayerAttrib, SizeOf(psQueryLayerAttrib));
 //
  Stream.Write(psTwiseLot, SizeOf(psTwiseLot));
  Stream.Write(psNoAssociativeFill, SizeOf(psNoAssociativeFill));
  Stream.Write(psOrthoMode, SizeOf(psOrthoMode));
 //
  Stream.Write(psLineArc, SizeOf(psLineArc));
  Stream.Write(psLineSpline, SizeOf(psLineSpline));
 //
  Stream.Write(psWidthPath,1);
  Stream.Write(psNumberUch,1);
  Stream.Write(Dop,SizeOf(Dop));
  Stream.Put(Vars);
//  B:=Image<>nil;
  B:=False;
  Stream.Write(B,1);
  If B then begin
   Stream.Stream.WriteComponent(Image);
   Stream.Position:=Stream.Stream.Position;
  end;
end;

{ TGlobalSettings }

constructor TGlobalSettings.Create;
var St:TSettingsRec;
begin
 With Settings do begin
  gsPointSize:=4;gsSelectColor:= TAlphaColors.Lime;gsWindowColor:=TAlphaColors.White;gsColorZnaksCheck:=False;gsColorZnaks:=TAlphaColors.Black;
  gsFillPointColor:=TAlphaColors.Black;gsFillPointCheck:=False;
  gsColorUzl:=TAlphaColors.Red;gsColorDot:=TAlphaColors.Blue;gsColorPoint:=TAlphaColors.Lime;
 end;
 exit;
 If GReadBinary('GlobalSettings',St,SizeOf(TSettingsRec)) then Settings:=St;
// MarkerView:=TMarkerView(GReadObject('GlobalSettings_MarkerView'));
 If MarkerView=nil then MarkerView:=TMarkerView.Create(0);
end;

function TGlobalSettings.CZ: Boolean;
begin
 Result:=Settings.gsColorZnaksCheck;
end;

function TGlobalSettings.CZB: Byte;
begin
 Result:=GetB(Settings.gsColorZnaks);
end;

function TGlobalSettings.CZG: Byte;
begin
 Result:=GetG(Settings.gsColorZnaks);
end;

function TGlobalSettings.CZR: Byte;
begin
 Result:=GetR(Settings.gsColorZnaks);
end;

destructor TGlobalSettings.Destroy;
begin
// GWriteBinary('GlobalSettings',Settings,SizeOf(Settings));
// GWriteObject('GlobalSettings_MarkerView',MarkerView);
 MarkerView.Free;
end;

initialization
finalization
end.
