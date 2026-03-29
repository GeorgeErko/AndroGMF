Unit eclot;
Interface
uses  Classes, Collect, WpTwigs, TwgDraw,
       TWGColle, newForm0, EcDot, lib, Lib2,
         newConsts, Lines2, EMath, SysUtils, FMX.Graphics,
          newResource, Maths_Basic, Types_Dimano, Circle_di, newProcs, WpArcs,
           newProperties, userObject, objBlockList, newSelector,
            newPainter, System.Types, ogcBasic, Lines3, GMFLTDrawer;

{ Графические примитивы [.Twg] }
var
     FL:text;
     BigDel:Integer=0;
     GlobalObochina:Double = 1000;
     XGlobalIn,YGlobalIN:Double ;


Const
  Lot_Sbor  =0;
  Lot_AutoSbor=1;
  Lot_Scolka=2;
  Lot_Maths=3;
  Lot_Promer=10;
  Lot_PromerPlus=11;
  Lot_PromerAlfa=12;
  Lot_PromerBeta=13;
  gCountLots:Integer = 0;
 // индексы для фиксированных свойств площадного контура
  lpColor = 0;
  lpFillColor = 1;
  lpLineType = 2;
  lpFillType = 3;
  lpScale = 4;
  lpWidth = 5;
 // линейного контура
  lpLine2Type = 1;
  lpLineScale = 2;
  lpLineWidth = 3;
 //
  lpLotNames:Array[0..4] of AnsiString = ('Цвет','Цвет заливки','Тип линии','Масштаб','Толщина');
  lpLineLotNames:Array[1..3] of AnsiString = ('Тип линии','Масштаб','Толщина');

 Type
   PSC=Class(TSortedCollection)
     function Compare(Key1,Key2:Pointer):Integer;override;
    end;

{----------------------------------------------------------------------}
 Type
  TLine = class (TTwgObject)
  private
    function GetX: Double;
    function GetX1: Double;
    function GetY: Double;
    function GetY1: Double;
    procedure SetX(const Value: Double);
    procedure SetX1(const Value: Double);
    procedure SetY(const Value: Double);
    procedure SetY1(const Value: Double);
  public
   D,D1:TDot;
   Selector:TSelector;
   Constructor Create(Selector_:TSelector;XX,YY,XX1,YY1:Double);
   Constructor   Load  (Stream :TBufStream);Override;
   Procedure     Store (Stream :TBufStream);Override;
   Destructor Destroy;override;
   Procedure Draw(Dc:hDc;Color:Integer);
   Property X:Double read GetX write SetX;
   Property Y:Double read GetY write SetY;
   Property X1:Double read GetX1 write SetX1;
   Property Y1:Double read GetY1 write SetY1;
  end;

  THatches = class(PCollection)
  private
    function GetLine(Index: Integer): TLine;
    function GetHole(Index: Integer): PCollection;
  public
   Holes:PCollection;// коллекция сегментов
   Selector:TSelector;
   Constructor Create(Selector_:TSelector);
   Destructor Destroy;override;
   Constructor CreateAs(Hatches:THatches);
   Constructor   Load  (Stream :TBufStream);Override;
   Procedure     Store (Stream :TBufStream);Override;
  //
   procedure Draw(Dc: hDc;Color:Integer);
   Property Line[Index:Integer]:TLine read GetLine;default;
   Procedure Move(Dx,Dy:Double);
   Property Hole[Index:Integer]:PCollection read GetHole;
  end;

 TSurface = class(TTwgObject)
  Layer:TResource;
  TypeOf:AnsiString;
  Material:AnsiString;
  Index:Integer;
  Constructor Create(Layer_:TResource;TypeOf_,Material_:AnsiString;Index_:Integer = 0);
 end;


Type

   { TLot }

   TLot=Class(TTD)
    private
     function GetGUIDStr: AnsiString;
     procedure SetGUIDStr(const Value: AnsiString);
     function GetLine(Index: Integer): TLine;
    function GetUID: AnsiString;
    procedure SetUID(const Value: AnsiString);
    function GetUID1: AnsiString;
    procedure SetUID1(const Value: AnsiString);
    public
     ParentIndex:Integer; // индекс в коллекции контуров
     TaheoIndex:SmallInt;
   {}
     What:Byte;
   {Главное поле}
     ClassCode  :Double;
   {указатель на класс}
     ClassHandle:TResource;
   {Что из классификатора}
   //все оставляем
     TypeLot    :Byte;
     Closed     :Byte;
  {}
     NLot       :FixedInt;
     UID        :PAnsiChar; // уникальный строковый ID
  {}
     RKF        :Single;
     Coord      :PCollection;
     PLO        :Double;
     ClearPlo   :Double;
     Ins        :FixedInt;
     BaseIns    :FixedInt;
     XMax,YMax,XMin,YMin:Single;
    {}
{     XC,YC:Single;}
    {}
     Points     :PCollection;
     UZnaks     :PCollection;
   { По базе }
   {}
//     Text       :TEFont;
     DataFonts  :PCollection;
     Fonts      :PCollection;
     Copy 	    :Byte;
     Copy1      :Byte;
   {}
     Inv        :Byte;
   {}
     Lines      :PCollection;
     DataPoints :PCollection;
     GUID:TGUID;
     Symbol:ShortInt;
   {}
     Properties:TProperties;
   { стандартные штриховки }
     Hatches:THatches;
   // для принадлежности контуру
     LotMain:TLot;
     UID1:PAnsiChar;
     Texture:TTexture;
     TexX,TexY,TexAngle,TexScale:Single;
     Alpha:byte;
   //
     StoreProps:TProperties;
     Selector:TSelector;
   //
     FDrawerObject: TObject;
     Constructor   Create(Code:Extended;CH:TResource;LotType:Byte);virtual;
      Constructor   CreateWithParams(PR:TResource;Params:Pointer);virtual;abstract;
      Constructor   CreateAsLot(Lot:TLot;AddAllCollections:Boolean);virtual;
      Constructor   CreateAsLotWithAll(Lot:Tlot);virtual;
      Procedure     AssignLot(Lot:TLot;AddAllCollections:Boolean);virtual;
      Constructor   Load  (Stream :TBufStream);Override;
      Procedure     Store (Stream :TBufStream);Override;
    { Новые процедуры загрузки}
      Procedure     LoadNew  (Stream :TBufStream);
    { Процедуры загрузки из базы данных }
      Constructor   LoadDB(GUID_:TGUID;Twigs:TTwigsCollect;Stream:TBufStream);
      Procedure     StoreDB(Twigs:TTwigsCollect;Stream:TBufStream);
      Destructor    Destroy;Override;
    {}
      Procedure     MinMax(X,Y:Double);
      Procedure     SetMinMax(Twf:TTwigsCollect);virtual;
      Procedure     SetMinMax2(Twf:TTwigsCollect);virtual;
      Function      IsVisible(R:TRect):Boolean;
      Procedure     Insert(Index:LongInt);
      Procedure     AtPut (Num:LongInt;Index:LongInt);
      Procedure     AtInsert(Num:LongInt;Index:LongInt);
      Function      GetCount(TWF:TTwigsCollect;Ind:Longint):Integer;
 {Печать}
 {------}
 {}
      function SetClearSqwear(Index: Integer; TWF: TTwigsCollect; Os: AnsiString; PointsIns: boolean): Integer;virtual;
 {}
      Procedure     InsClipDots(Twf:TTwigsCollect);
      Procedure     InsClipDotsParall(Twf:TTwigsCollect);
      Procedure     Ins3DPoints(Twf:TTwigsCollect;UseArcPoints:boolean=False);
      Function      InsPointsRgn(Twf:TTwigsCollect):SmallInt;
      Procedure     InsClipDotsSqwear(Twf:TTwigsCollect);
      Procedure     SetTwigsRt(Twf:TTwigsCollect);
      Function      SetFromTwig(Twf:TTwigsCollect):SmallInt;
      Function      SetSqwear(TWF:TTwigsCollect):SmallInt;virtual;
      Function      SetOwner(TWF:TTwigsCollect):AnsiString;
      Procedure     SetChildsIns(Twf:TTwigsCollect);
      Procedure     DeleteWithChilds(Twf:TTwigsCollect);
      Function      PointIn   (Twf:TTwigsCollect;X,Y:Double;Param:Integer=-1):Boolean;virtual;
      Function      PointLotIn(Twf:TTwigsCollect;Lot:TLot):Boolean;
      Function      LotIn(Twf:TTwigsCollect;Lot:TLot;usePoints:boolean = false;LineLot:boolean = false):Boolean;
      Function      GetZnak(X,Y:Double;var S:Double):Integer;
     {}
      function       GetPointIn(PD:TDot;Twf:TTwigsCollect):boolean;
      procedure      FreeDelTwig(TWF:TTwigsCollect);
      procedure      FreeDoublTwig;
     {  }
      Procedure  SeeCoord(Twf:TTwigsCollect);
      Function	 TextNotOk(DC:hDC;Twf:TTwigsCollect):boolean;
      Function   SumTwigs:Integer;
      Function   EqualDelete(CR:PCollection):Integer;
      Function   SetTwgs(Twf:TTwigsCollect;NN:Byte;LotsCol1:PCollection = nil ):Boolean;
      Procedure  MakeLines(Twf:TTwigsCollect);
      Procedure  Reset(I,J:LongInt);
      Procedure  DelUdTwigs(Twf:TTwigsCollect;MinOtr:Double);
      Function   IntersectedWithTwig(TWF:TTwigsCollect;Twig:TTwig;var X,Y:Double):boolean;
      Function   IntersectedWithTwig2(TWF:TTwigsCollect;Twig:TTwig;var X,Y:Double):boolean;
    { Захват ветки из Lines }
    { }
      Function AddLot(TWF:TTwigsCollect;L:TLot):Boolean;
      Procedure DeleteTwigsWith(Twf:TTwigsCollect);
    { 3d}
      Function is3DPolygon(TWF:TTwigsCollect):Boolean;
      Function Make3dPoint(TWF:TTwigsCollect;P:TPointDot):Byte;
      Function UseTriangles:boolean;
    {Промер}
      Function  Perimeter(TWF:TTwigsCollect):Double;
      Procedure ResetPromer(TWF:TTwigsCollect);
    { Функции класса }
      Function LotColor:LongInt;
      Function LotLineColor:LongInt;
      Function CsLineColor:TRGBRec;
      Function CsColor:TRGBRec;
      Function CsRang :Byte;
      Function CsHatch:Byte;
      Function CsNBase:Byte;
      Function CsUZnak:SmallInt;
      Function CsKoef:Double;
      Function CsGlass:Boolean;
      Function csShowAttrib:Boolean;
      Function csLineZnak:Integer;
     {}
      Function GetCorrectInfo(TWF:TTwigsCollect;var S1,S2:AnsiString):boolean;
      Procedure GetCorrectPoint(TWF:TTwigsCollect;Var XDot,YDot:Double);
     { Twigolygon }
      Procedure InsTwigs(TWF:TTwigsCollect);
      Procedure objMoveTwigNumbers(N:Integer);
     { Taheo }
      Function GBS:Double;
      Procedure ResetTaheoIndexesForAllTwigs(TWF:TTwigsCollect);
      Procedure SetActiveLine(TWF:TTwigsCollect;XR,YR:Double;var Line:TSect);
      Procedure UpdateWithTwigs(TWF:TTwigsCollect;Index:Integer;P: PCollection;SetTwig:Boolean);
     { DataPoints }
      Procedure InsertDataPoint(P:TPointDot);
     {}
      Function GetTwig(Twigs:TTwigsCollect;Index:Integer):TTwig;
      Function FindTwig(Twigs:TTwigsCollect;X,Y:Double;Var Dist:Double):TTwig;
      Function FindTwigPoint(Twigs:TTwigsCollect;Twig:TTwig):Integer;
      Function DeleteTwig(Twigs:TTwigsCollect;Twig:TTwig):Boolean;
     {}
      Function isCircle(Twigs:TTwigsCollect;var X,Y,Rad:Double):boolean;
      Function isClosed(Twigs:TTwigsCollect):boolean;
      Procedure SetTwigsCloseProperty(Twigs:TTwigsCollect;Closeprop:Integer);
     {GUID}
      Property GUIDStr:AnsiString read GetGUIDStr write SetGUIDStr;
      Function DelMinOtr(TWF:TTwigsCollect;MinOtr:double):boolean;
     // свойства
      Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
      Function GetProperty(propName:AnsiString):AnsiString;override;
      Function GetPropValue(propName:AnsiString):Pointer;override;
      Function propIndex(Index:Integer):AnsiString;override;
      Function UseProperty(propName: AnsiString): boolean;override;
      Procedure DeleteProperty(propName: AnsiString);override;
      Procedure AddProperty(propName: AnsiString);override;
      Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
      Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
      Function GetLayer:TResource;override;
      Procedure SetLayer(PR:TResource);override;
     // перемещение
      Procedure RotationPoints(Col:PCollection);override;
      Procedure Move(Dx,Dy:Double);override;
     //
      Procedure CreateLotsView(TWF:TTwigsCollect);
     //
      Function GetLength(TWF:TTwigsCollect):Double;
      Function GetLinearPlo(Twigs:TTwigsCollect):Double;
     //
      Procedure CreateHatch(TWF:TTwigsCollect;Hatch_:Integer=-1;Dup:boolean = True);
     //
      Property UIDStr:AnsiString read GetUID write SetUID;
      Property UID1Str:AnsiString read GetUID1 write SetUID1;
     //
      procedure Draw32(Twf: TTwigsCollect);
      function GetDrawerObject: TObject; override;
      procedure SetDrawerObject(Obj: TObject); override;
    end;

 TLotClass=class of TLot;
 var KFF:Double;


{----------------------------------------------------------------------}


Implementation uses WptForm2, IniFiles, EcDot2, intervals, EcText, Tata3, Polygons,
                    Maths_Versia,  Writer, tmpPainter, System.UITypes;


 Function ArcCat(X1,Y1,X2,Y2:real;Var Znak:byte):Real;
 Var Res,R,EndRes,Dy,Dx,Gr,Min,Sec:Real;
  begin
   Dy:=Y2-Y1;
   Dx:=X2-X1;
   If Dx=0 then Dx:=1;
   Res:=Arctan(Dy/Dx);
   IF (Dy>=0) And (Dx>=0) then begin EndRes:=Res;Znak:=1 End;
   IF (DX<=0) And (Dy>=0) then Begin EndRes:=180-Res;Znak:=2 End;
   IF (Dx<=0) And (Dy<=0) then Begin EndRes:=180+Res;Znak:=3 End;
   IF (Dx>=0) And (Dy<=0) then Begin EndRes:=360-Res;Znak:=4 End;
   ArcCat:=Res;
  end;

{----------------------------------------------------------------------}
function PSC.Compare;
begin
//if round(TDot(Key1).XDot*Const_Of_PrecCoord)<round(TDot(Key2).XDot*Const_Of_PrecCoord) then compare:=-1;
//if round(TDot(Key1).XDot*Const_Of_PrecCoord)=round(TDot(Key2).XDot*Const_Of_PrecCoord) then compare:=0;
//if round(TDot(Key1).XDot*Const_Of_PrecCoord)>round(TDot(Key2).XDot*Const_Of_PrecCoord) then compare:=1;
if round(TDot(Key1).XDot*1000)<round(TDot(Key2).XDot*1000) then compare:=-1;
if round(TDot(Key1).XDot*1000)=round(TDot(Key2).XDot*1000) then compare:=0;
if round(TDot(Key1).XDot*1000)>round(TDot(Key2).XDot*1000) then compare:=1;
end;

{----------------------------------------------------------------------}
{ TLot                                                                 }
{----------------------------------------------------------------------}
    constructor TLot.Create(Code: Extended; CH: TResource; LotType: Byte);
   begin
   CreateGUID(GUID);
   Symbol:=-1;
    TaheoIndex:=-1;//GMemMakeIndex;
    What:=LotType;
    ClassCode:=Code;
    ClassHandle:=CH;
    TypeLot:=Trunc(ClassHandle.Rang);
    Closed   :=0;
    PLO      :=-2;
    ClearPlo :=-2;
    Closed   :=1;
    Coord    :=PCollection.Create(1);;
    UZnaks   :=PCollection.Create(1);;
//    FillChar(Color,3,#255);
    Ins:=-1;
    BaseIns:=-1;
//    UZnak:=-1;
    RKF:=1;
//     Length:=-1;
//     Width :=-1;
//     BStyle:=0;                                        
     {}
     Inv:=0;
     Copy1:=0;
     Copy:=0;
//     Rang:=255;                                               
     DataFonts:=PCollection.Create(1);
     Fonts:=PCollection.Create(1);
     Lines:=PCollection.Create(1);
     DataPoints:=PCollection.Create(1);
     Xmax:=-10000000;YMax:=-10000000;
     XMin:=10000000;YMin:=10000000;
   { уникальный ID }
     UID:=nil;
     Hatches:=THatches.Create(Selector);
     TexX:=1;TexY:=1;TexAngle:=0;
     TexScale:=1000;
     Alpha:=0;
  end;

    constructor TLot.CreateAsLot(Lot: TLot; AddAllCollections: Boolean);
   begin
    Selector:=Lot.Selector;
    CreateGUID(GUID);
    AssignLot(Lot,AddAllCollections);
   end;

  constructor TLot.CreateAsLotWithAll(Lot: Tlot);
  var I:Integer;
  begin
   Selector:=Lot.Selector;
   CreateGUID(GUID);
    AssignLot(Lot,True);
    TypeLot:=Lot.TypeLot;
    NLot:=Lot.NLot;
    Symbol:=Lot.Symbol;
     For I:=0 to Lot.Coord.Count-1 do
      Coord.Insert(TLong.Create(TLong(Lot.Coord[I]).Num));
  end;

    procedure TLot.AssignLot(Lot: TLot; AddAllCollections: Boolean);
   var P:TPDot;I:Integer;
   begin
    TaheoIndex:=Lot.TaheoIndex;
    What:=Lot.What;
    ClassCode:=Lot.ClassCode;
    ClassHandle:=Lot.ClassHandle;
    TypeLot:=Lot.TypeLot;
    PLO      :=Lot.Plo;
    ClearPlo :=Lot.ClearPlo;
    Closed   :=1;
    Coord    :=PCollection.Create(1);
    UZnaks   :=PCollection.Create(1);
//    try
    If AddAllCollections then
      For I:=0 to Lot.UZnaks.Count-1 do
       begin
        P:=Lot.UZnaks[I];
        UZnaks.Insert(TPDot.Create(P.XDot,P.YDot,P.What,P.Ugol));
       end;
//    except Uznaks:=PCollection.Create(1); end;
    Ins:=-1;
    BaseIns:=-1;
    RKF:=Lot.RKF;
   {}
    Inv:=0;
    Copy1:=0;
    Copy:=0;
   If AddAllCollections then
   begin
    DataFonts:=PCollection.Create(1);if Lot.DataFonts<>nil then For I:=0 to Lot.DataFonts.Count-1 do DataFonts.Insert(TEfont.CreateAsFont(Lot.DataFonts[I]));
    Fonts:=PCollection.Create(1);if Lot.Fonts<>nil then For I:=0 to Lot.Fonts.Count-1 do Fonts.Insert(TEfont.CreateAsFont(Lot.Fonts[I]));
    Lines:=PCollection.Create(1);if Lot.Lines<>nil then For I:=0 to Lot.Lines.Count-1 do Lines.Insert(TTwigClass(TTwig(Lot.Lines[I]).ClassType).CreateAsTwig(Lot.Lines[I],True));
    DataPoints:=PCollection.Create(1);if Lot.DataPoints<>nil then For I:=0 to Lot.DataPoints.Count-1 do DataPoints.Insert(TPointClass(TPointDot(Lot.DataPoints[I]).ClassType).CreateAsPointDot_(Lot.DataPoints[I],True));
   end else
   begin
    DataFonts:=PCollection.Create(1);
    Fonts:=PCollection.Create(1);
    Lines:=PCollection.Create(1);
    DataPoints:=PCollection.Create(1);
   end;
     Xmax:=-10000000;YMax:=-10000000;
     XMin:=10000000;YMin:=10000000;
   { уникальный ID }
    If Lot.UID<>nil then
     UID:=StrNew(Lot.UID) else
     UID:=nil;
     Symbol:=Lot.Symbol;
   //
    If Lot.Properties<>nil then Properties:=TProperties.CreateAs(Lot.Properties) else Properties:=nil;
    If AddAllCollections then Hatches:=THatches.CreateAs(Lot.Hatches) else Hatches:=THatches.Create(Selector);
    If AddAllCollections then Texture:=Lot.Texture;
    TexX:=Lot.TexX;TexY:=Lot.TexY;TexAngle:=Lot.TexAngle;TexScale:=Lot.TexScale;
    Alpha:=Lot.Alpha;
 end;

  procedure TLot.LoadNew(Stream: TBufStream);
 var TI:ShortInt;B:Byte;Plo48:Real48;
 begin
//  Inc(gCountLots);Writeln('cnt=',gCountLots);
//  WriteIn([1]);
  CreateGUID(GUID);
   TaheoIndex:=-1;
    If Version>21 then
     begin
      Stream.Read(What,SizeOf(What));
     If Version>22 then begin
      If Version<28 then begin
       Stream.Read(TI,SizeOf(TI));TaheoIndex:=TI;
      end else Stream.Read(TaheoIndex,SizeOf(TaheoIndex));
     end else TaheoIndex:=-1;
    end else What:=Lot_Sbor;
    Coord:=PCollection(Stream.Get);
    UZnaks:=PCollection(Stream.Get);
    DataFonts:=PCollection(Stream.Get);
   // If gCountLots=3539 then
//   WriteIn([2]);
     Stream.Read(ClassCode,SizeOf(ClassCode));
     Stream.Read(Closed,SizeOf(Closed));
     Stream.Read(Plo48,SizeOf(Plo48));Plo:=Plo48;
     Stream.Read(Plo48,SizeOf(Plo48));ClearPlo:=Plo48;
     Stream.Read(Ins,SizeOf(Ins));
     Stream.Read(RKF,SizeOf(RKF));
     Stream.Read(NLot,SizeOf(NLot));
     Stream.Read(TypeLot,SizeOf(TypeLot));
     Stream.Read(Copy,SizeOf(Copy));
     Stream.Read(Copy1,SizeOf(Copy1));
     Stream.Read(BaseIns,SizeOf(BaseIns));
//   WriteIn([3]);
{    Try
     if TypeLot=31 then  begin
      Stream.Position:=Stream.Position+2;
      Fonts:=PCollection(Stream.Get);
     end else}
//     Writeln(DataFonts.Count,' ',UZnaks.Count);
     Fonts:=PCollection(Stream.Get);
//  Writeln(22,' ',Fonts=nil);
{    except on E:Exception do begin
//     Writeln(ClassCode:8:2,' ',Closed,' ',Plo:8:3,' ',ClearPlo:8:3,' ',Ins,' ',TypeLot,' ',NLot);
//     ShowMessage(E.Message);
    end;end;}
     Lines:=PCollection(Stream.Get);
//  Writeln(3, LINES=NIL);
   { уникальный ID }
//   WriteIn([4]);
     UID:=Stream.StrRead;
//     WriteIn([5,UID = nil]);
     if Version>29 then begin
      DataPoints:=PCollection(Stream.Get);
       If Version>39 then begin
        Properties:=TProperties(Stream.Get);
//        WriteIn(['Properties=nil', Properties = nil]);
         If Version>49 then
          Hatches:=THatches(Stream.Get) else Hatches:=THatches.Create(Selector);
        If Version>53 then Stream.Read(GUID,SizeOf(TGUID));
//        WriteIn(['GUID=',GUIDStr]);
           //If Version>53 then Stream.Read(TexScale,SizeOf(TexScale)) else TexScale:=500;
       end else Properties:=nil;
     end else DataPoints:=PCollection.Create(1);
//  Writeln(4);
   TexX:=1;TexY:=1;TexAngle:=0;TexScale:=500;Alpha:=0;
//   WriteIn([6]);
  end;

  procedure TLot.Store(Stream: TBufStream);
  var B:Byte;Plo48:Real48;
  begin
   Stream.Write(What,SizeOf(What));
   Stream.Write(TaheoIndex,SizeOf(TaheoIndex));
   Stream.Put(Coord);
   Stream.Put(UZnaks);
   Stream.Put(DataFonts);
   Stream.Write(ClassCode,SizeOf(ClassCode));
   Stream.Write(Closed,SizeOf(Closed));
   Plo48:=Plo;
   Stream.Write(Plo48,SizeOf(Plo48));
   Plo48:=ClearPlo;
   Stream.Write(Plo48,SizeOf(Plo48));
   Stream.Write(Ins,SizeOf(Ins));
   Stream.Write(RKF,SizeOf(RKF));
   Stream.Write(NLot,SizeOf(NLot));
   Stream.Write(TypeLot,SizeOf(TypeLot));
   Stream.Write(Copy,SizeOf(Copy));
   Stream.Write(Copy1,SizeOf(Copy1));
   Stream.Write(BaseIns,SizeOf(BaseIns));
   Stream.Put(Fonts);
   Stream.Put(Lines);
 { уникальный ID }
   Stream.StrWrite(UID);
   Stream.Put(DataPoints);
   Stream.Put(Properties);
//   If not GlobalOldVersion then
    If VerConst>49 then begin
     Stream.Put(Hatches);
     Stream.Write(GUID,SizeOf(GUID));
    // Stream.Write(TexScale,SizeOf(TexScale));
    end;
  end;


  constructor TLot.Load(Stream: TBufStream);
   var X1,Y1,X2,Y2:SmallInt;
       N:Byte;L,I,J:LongInt;
       Tw:TTwig;Tx,Tx2:TEFont;
       CC:Extended;
     {Старые}
       Color      :TRgbRec;
       UZnak      :SmallInt;
       Rang       :Byte;
       Base:Byte;
       Hatch:Byte;
       BStyle:Byte;
       NBase:Byte;
       Length     :Single;
       Width      :Single;
       NumText:TEFont;
       Plo48:Real48;
     {}
  Procedure Del(DF:PCollection);
   var I,J:Integer;
   begin
    If DF<>nil then
     begin
      For I:=DF.Count-1 downTo 0 do begin
       Tx:=DF[I];
        For J:=I-1 downTo 0 do begin
         Tx2:=DF[J];
         If StrPas(Tx2.Named)=StrPas(Tx.Named) then
           begin DF.AtFree(I);Inc(BigDel);break;end;
        end;
      end;
    end;
   end;
   begin
//    LoadNew(Stream);Exit;
    Selector:=Stream.Selector;
    if Version>18 then LoadNew(Stream) else
    begin // старая загрузка
     Coord :=PCollection(Stream.Get);
     UZnaks:=PCollection(Stream.Get);
    if Version<12 then
     begin
      Tx  :=TEFont(Stream.Get);
      DataFonts:=PCollection.Create(1);
     if Tx<>nil then
      DataFonts.Insert(Tx);
     end else
     begin
      DataFonts:=PCollection(Stream.Get);
     end;
     Stream.Read(Color,SizeOf(Color));
     Stream.Read(CC,SizeOf(Extended));
     ClassCode:=CC;
     Stream.Read(Closed,SizeOf(Closed));
     Stream.Read(Plo48,SizeOf(Plo));Plo:=Plo48;
     Stream.Read(Plo48,SizeOf(Plo));ClearPlo:=Plo48;
	  Stream.Read(Ins,SizeOf(Ins));
          Xmax:=0;YMax:=0;
         XMin:=0;YMin:=0;
	 If version<4 then
		 begin
	          Stream.Read(X1,2);Stream.Read(X2,2);
                  Stream.Read(Y1,2);Stream.Read(Y2,2);
                  XMax:=X1;Ymax:=Y1;XMin:=X1;YMin:=Y1;
		 end else
              {if Version<6 then}
		  begin
			Stream.Read(XMax,SizeOf(Xmax));Stream.Read(XMin,SizeOf(XMin));
			Stream.Read(YMax,SizeOf(Ymax));Stream.Read(YMin,SizeOf(YMin));
		  end;
         Xmax:=-1000000;YMax:=-1000000;
         XMin:=1000000;YMin:=1000000;
	  Stream.Read(RKF,SizeOf(RKF));
     Stream.Read(NLot,SizeOf(NLot));
     Stream.Read(TypeLot,SizeOf(TypeLot));
     Stream.Read(NBase,SizeOf(NBase));
     Stream.Read(Hatch,SizeOf(Hatch));
     Stream.Read(Length,SizeOf(Length));
     Stream.Read(Width,SizeOf(Width));
          BaseIns:=Ins;
	 If (Version>0) then
		begin
		 If Version>1 then
        begin
       NumText:=TeFont(Stream.Get);
       Stream.Read(BStyle,sizeOf(BStyle));
		Copy1:=0;Copy:=0;
	  If version>2 then
      begin
		 Stream.Read(Copy,SizeOf(Copy));
		 Stream.Read(Copy1,SizeOf(Copy1));
		  end;
		 end;
          {}
              If Version>6 then
                begin
                 Stream.Read(BaseIns,SizeOf(BaseIns));
               //  Lines:=PCollection.Create(1);
                If Version>8 then
                 begin
                  Fonts:=PCollection(Stream.Get);
                 // Lines:=PCollection.Create(1);
                  Lines:=PCollection(Stream.Get);
                 end else
                 begin
                  Lines:=PCollection.Create(1);
                  Fonts:=PCollection.Create(1);
                 end;
                end;
		end else
  If Version=0 then
	  begin
           Numtext:=nil;
	  end;
{     XC:=0;YC:=0;}
    Rang:=255;
  end;
//   Del(DataFonts);
//   Del(Fonts);
//   Fonts:=nil;
 end;


    destructor TLot.Destroy;
   begin
    If Coord<>nil then
       Coord.Free;
    If UZnaks<>nil then
       UZnaks.Free;
{    If Text<>nil then
       Text.Free;}
{	 If NumText<>nil then
       Dispose(NumText,Done);}
    If Fonts<>nil then
     Fonts.Free;
    If Lines<>nil then
     Lines.Free;
    If DataFonts<>nil then
     DataFonts.Free;
    If Properties<>nil then Properties.Free;
    DataPoints.Free;
    Hatches.Free;
  end;

{------------}

    procedure TLot.SetMinMax(Twf: TTwigsCollect);
   var I:LongInt;Tw:TTwig;
   begin
     XMax:=-10000000;YMax:=-10000000;
     XMin:=10000000;YMin:=10000000;
     For I:=Coord.Count-1 downTo 0 do If TLong(Coord.At(I)).Num>=Twf.TwigsCount then Coord.AtFree(I);
     For I:=0 to Coord.Count-1 do
      begin
       Tw:=Twf.TAt(TLong(Coord.At(I)).Num);
       Tw.SetMinMax;
       //Tw.Calculate;
        If Tw.Closed<>254 then
         begin
          If Tw.XMin<XMin then XMin:=Tw.XMin;
          If Tw.XMax>XMax then XMax:=Tw.XMax;
          If Tw.YMin<YMin then YMin:=Tw.YMin;
          If Tw.YMax>YMax then YMax:=Tw.YMax;
         end;
      end;
   end;

    procedure TLot.SetMinMax2(Twf: TTwigsCollect);
   var I:LongInt;Tw:TTwig;
   begin
     XMax:=-10000000;YMax:=-10000000;
     XMin:=10000000;YMin:=10000000;
     For I:=Coord.Count-1 downTo 0 do begin
       Tw:=Twf.TAt(TLong(Coord.At(I)).Num);
        If Tw.Closed<>254 then
         begin
          If Tw.XMin<XMin then XMin:=Tw.XMin;
          If Tw.XMax>XMax then XMax:=Tw.XMax;
          If Tw.YMin<YMin then YMin:=Tw.YMin;
          If Tw.YMax>YMax then YMax:=Tw.YMax;
         end;
     end;    
   end;

    procedure TLot.MinMax(X, Y: Double);
   begin
    If X>XMax then XMax:=X;
    If X<XMin then XMin:=X;
    If Y>YMax then YMax:=Y;
    If Y<YMin then YMin:=Y;
   end;

    function TLot.IsVisible(R: Trect): Boolean;
   begin
      begin
        Result:=True;
    If GlobalRender then exit;
	  With Selector.GRect do
    begin
		 If XMax<Left then begin Result:=False;Exit;end;
		 If XMin>Right then begin Result:=False;Exit;end;
     If YMin<Bottom then begin Result:=False;Exit;end;
		 If YMax>Top then begin Result:=False;Exit;end;
       end;
     If TypeLot=2 then
      With ClassHandle do
       If Result and (Clip=1) then With Selector do
        begin
         if (XRasst(XMax-XMin)<ConGen) and
           (Abs(YRasst(YMax-YMin))<ConGen) then Result:=False;
        end;
      end;
   end;

    procedure TLot.Insert(Index: LongInt);
   begin
    Coord.Insert(TLong.Create(Index));
   end;

    procedure TLot.AtPut(Num: LongInt; Index: LongInt);
    begin
     Coord.AtPut(Num,TLong.Create(Index));
   end;

    procedure TLot.AtInsert(Num: LongInt; Index: LongInt);
   begin
     Coord.AtInsert(Num,TLong.Create(Index));
   end;



    function TLot.GetCount(TWF: TTwigsCollect; Ind: Longint): Integer;
   var I,J:LongInt;Lot:TLot;
  begin
   J:=0;
    For I:=Twf.LotsCount-1 downto 0  do
     begin
       Lot:=Twf.Lat(I);
       If Lot.Ins=Ind then Inc(J);
     end;
    getCount:=J;
  end;

{==========================================================================}
{ All Functions                                                            }
{==========================================================================}


procedure TLot.Ins3DPoints(Twf: TTwigsCollect; UseArcPoints: boolean);
  var I,J,AV:Integer;Twig:TTwig;D:TDot;
  begin
   if Coord.count=0 then
    begin
     TypeLot:=254;
      Points:=PCollection.Create(1);
     exit;
    end;
   If Coord.Count=1 then
    begin
     Points:=PCollection.Create(1);
     Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
     AV:=Twig.ArcView;Twig.ArcView:=ord(UseArcPoints);
      For I:=0 to Twig.Coord.Count-1 do
       begin
        D:=Twig.Coord.At(I);
        Points.Insert(TDot.CreateAsDot(D));
//        Writeln('Z=',D.Z);readln;
       end;
//     Twig.ArcView:=AV;
       {D:=Points.At(0);
       Points.Insert(TDot.CreateAsDot(D));}
      Exit;
    end;
      Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
      Points:=PCollection.Create(Twig.Coord.Count);
   For I:=0 to Coord.Count-1 do
     begin
        With TWF do
         begin
           Twig:=TAt(TLong(Coord.At(I)).Num);
            AV:=Twig.ArcView;Twig.ArcView:=ord(UseArcPoints);;
			  If Twig.Coord.Count-1=0 then
                            begin
                             Plo:=0;
                             Twig.ArcView:=AV;
                             exit;
                            end;
           If TLong(Coord.At(I)).Num>0 then
            begin
                D:=Twig.Coord.At(0);
            if (I=0) then Points.Insert(TDot.CreateZ(D.XDot,D.Ydot,D.Z,0));
            For J:=1 to Twig.Coord.Count-1 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot.CreateAsDot(D));
             end;
             end else
             begin
                D:=Twig.Coord.At(Twig.Coord.Count-1);
            if (I=0) then Points.Insert(TDot.CreateZ(D.XDot,D.Ydot,D.Z,0));
            For J:=Twig.Coord.Count-2 Downto 0 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot.CreateAsDot(D));
             end;
             end;
           Twig.ArcView:=AV;
         end;
       end;
    if TypeLot=2 then begin
     D:=Points.At(0);
     Points.Insert(TDot.CreateAsDot(D));
    end;
  end;

procedure TLot.InsClipDots(Twf: TTwigsCollect);
  var I,J,AV:Integer;Twig:TTwig;D:TDot;D2:TDot1;
 begin
         if Coord.count=0 then
         begin
          TypeLot:=2;
          exit;
         end;
   If Coord.Count=1 then
    begin
     Points:=PCollection.Create(1);
     Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
     AV:=Twig.ArcView;Twig.ArcView:=1;
      For I:=0 to Twig.Coord.Count-1 do
       begin
        D:=Twig.Coord.At(I);
        Points.Insert(TDot1.Create(D.XDot,D.Ydot));
       end;
     Twig.ArcView:=AV;
       D2:=Points.At(0);
       Points.Insert(TDot1.Create(D2.X,D2.Y));
      Exit;
    end;
         Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
         Points:=PCollection.Create(Twig.Coord.Count);
   For I:=0 to Coord.Count-1 do
       begin
        With TWF do
         begin
           Twig:=TAt(TLong(Coord.At(I)).Num);
           AV:=Twig.ArcView;Twig.ArcView:=1;
			  If Twig.Coord.Count-1=0 then
				begin
				 Plo:=0;
                                 Twig.ArcView:=AV;
                                 exit;
				end;
           If TLong(Coord.At(I)).Num>0 then
            begin
                D:=Twig.Coord.At(0);
            For J:=1 to Twig.Coord.Count-1 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot1.Create(D.XDot,D.Ydot));
             end;
             end else
             begin
                D:=Twig.Coord.At(Twig.Coord.Count-2);
            For J:=Twig.Coord.Count-2 Downto 0 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot1.Create(D.XDot,D.YDot));
             end;
             end;
          Twig.ArcView:=AV;
         end;
       end;
{    if TypeLot=2 then
     begin}
      D2:=Points.At(0);
      Points.Insert(TDot1.Create(D2.X,D2.Y));
{     end;}
  end;

procedure TLot.InsClipDotsParall(Twf: TTwigsCollect);
var I,J,AV:Integer;Twig:TTwig;D:TDot;
 begin
  XMin:=100000000;
  XMax:=-100000000;
  YMin:=100000000;
  YMax:=-100000000;
  Points:=PCollection.Create(1);
   For I:=0 to Coord.Count-1 do
       begin
        With TWF do
         begin
           Twig:=TAt(TLong(Coord.At(I)).Num);
//            If Twig is TTwigArc then TTwigArc(Twig).CreateVirtualVertex;
           AV:=Twig.ArcView;Twig.ArcView:=1;
           If TLong(Coord.At(I)).Num>0 then
            begin
             D:=Twig.Coord.At(0);
                 MinMax(D.XDot,D.YDot);
             If (I=0) then Points.Insert(TDot.Create(D.XDot,D.Ydot,ord((Twig is TTwigArc)or(Twig is TTwigCircle)or(Twig is TTwigSpline))));
            For J:=1 to Twig.Coord.Count-1 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot.Create(D.XDot,D.Ydot,ord((Twig is TTwigArc)or(Twig is TTwigCircle)or(Twig is TTwigSpline))));
                 MinMax(D.XDot,D.YDot);
             end;
             end else
             begin
              D:=Twig.Coord.At(Twig.Coord.Count-1);
                 MinMax(D.XDot,D.YDot);
             if (I=0) then Points.Insert(TDot.Create(D.XDot,D.Ydot,ord((Twig is TTwigArc)or(Twig is TTwigCircle)or(Twig is TTwigSpline))));
            For J:=Twig.Coord.Count-2 Downto 0 do
             begin
                D:=Twig.Coord.At(J);
                 MinMax(D.XDot,D.YDot);
                 Points.Insert(TDot.Create(D.XDot,D.Ydot,ord((Twig is TTwigArc)or(Twig is TTwigCircle)or(Twig is TTwigSpline))));
             end;
             end;
           Twig.ArcView:=AV;
         end;
       end;
 end;

procedure TLot.InsClipDotsSqwear(Twf: TTwigsCollect);
var I,J,AV:Integer;Twig:TTwig;D:TDot;
 begin
  XMin:=100000000;
  XMax:=-100000000;
  YMin:=100000000;
  YMax:=-100000000;
  Points:=PCollection.Create(1);
   For I:=0 to Coord.Count-1 do
       begin
        With TWF do
         begin
           Twig:=TAt(TLong(Coord.At(I)).Num);
           If Twig is TTwigArc then TTwigArc(Twig).CreateVirtualVertex;
           If Twig is TTwigCircle then TTwigCircle(Twig).CreateVirtualVertex;
           AV:=Twig.ArcView;Twig.ArcView:=1;
           If TLong(Coord.At(I)).Num>0 then
            begin
             D:=Twig.Coord.At(0);
                 MinMax(D.XDot,D.YDot);
             if (I=0) then Points.Insert(TDot.Create(D.XDot,D.Ydot,0));
            For J:=1 to Twig.Coord.Count-1 do
             begin
                D:=Twig.Coord.At(J);
                 Points.Insert(TDot.Create(D.XDot,D.Ydot,0));
                 MinMax(D.XDot,D.YDot);
             end;
             end else
             begin
              D:=Twig.Coord.At(Twig.Coord.Count-1);
                 MinMax(D.XDot,D.YDot);
             if (I=0) then Points.Insert(TDot.Create(D.XDot,D.Ydot,0));
            For J:=Twig.Coord.Count-2 Downto 0 do
             begin
                D:=Twig.Coord.At(J);
                 MinMax(D.XDot,D.YDot);
                 Points.Insert(TDot.Create(D.XDot,D.Ydot,0));
             end;
             end;
           Twig.ArcView:=AV;
           If Twig is TTwigArc then begin
            TTwigArc(Twig).FreeVirtualVertex;
           // WRiteln('CCount=',TTwigArc(Twig).ArcCoord.Count,' ',Twig.ArcView);
           end;
           If Twig is TTwigCircle then TTwigCircle(Twig).FreeVirtualVertex;
         end;
       end;
 end;

function TLot.InsPointsRgn(Twf: TTwigsCollect): SmallInt;
   var I,J,K,AV:Integer;Twig:TTwig;D:TDot;
	begin
		if Coord.count=0 then
			begin
			 TypeLot:=2;
          exit;
         end;
//    WRiteln('InsRgn');
    Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
    AV:=Twig.ArcView;Twig.ArcView:=1;
    Xmin:=Trunc(TDot(Twig.Coord.At(0)).XDot);
    XMax:=Trunc(TDot(Twig.Coord.At(0)).XDot);
    Ymin:=Trunc(TDot(Twig.Coord.At(0)).YDot);
    YMax:=Trunc(TDot(Twig.Coord.At(0)).YDot);
    Twig.ArcView:=AV;
//    FillChar(LotRgn,Sizeof(LotRgn),#0);
   K:=0;
    For I:=0 to Coord.Count-1 do
       begin
        With Selector,TWF do
         begin
           Twig:=TAt(TLong(Coord.At(I)).Num);
            AV:=Twig.ArcView;Twig.ArcView:=1;
			  If Twig.Coord.Count-1=0 then
				begin
				 Plo:=0;
                                 Twig.ArcView:=AV;
             			 exit;
				end;
           If TLong(Coord.At(I)).Num>0 then
            begin
            For J:=1 to Twig.Coord.Count-1 do
             begin
                D:=Twig.Coord.At(J);
               K:=K+1;
                LotRgn[K].X:=XPix(D.XDot);
                LotRgn[K].Y:=YPix(D.YDot);
                MinMax(D.XDot,D.YDot);
             end;
             end else
            For J:=Twig.Coord.Count-2 Downto 0 do
             begin
                D:=Twig.Coord.At(J);
               K:=K+1;
                LotRgn[K].X:=XPix(D.XDot);
                LotRgn[K].Y:=YPix(D.YDot);
                 MinMax(D.XDot,D.YDot);
             end;
          Twig.ArcView:=AV;
         end;
       end;
  K:=K+1;
  LotRgn[K]:=LotRgn[1];
  InsPointsRgn:=K;
 end;


  procedure TLot.SetTwigsRt(Twf: TTwigsCollect);
   var Lot2:TLot;
       Long,Long1,Long2:TLong;I,J:Integer;
       Twig,Twig1,
       Twig2,Twig3:TTwig;
       DB,DE,DB1,DE1,Db0,DE0:TDot;
       InsTwig:Boolean;R:Trect;
   Function FindNum(Num:Longint):Boolean;
    var k:Integer;
    begin
	  For K:=0 to Lot2.Coord.Count-1 do
      begin
       If Abs(Num)=Abs(TLong(Lot2.Coord.At(K)).Num)
        then begin FindNum:=True;exit end;
      end;
      FindNum:=False;
    end;
   begin
     With Twf do
      begin
		 Lot2:=TLot.Create(ClassCode,ClassHandle,0);
		For I:=0 to Coord.Count-1 do
		 begin
		   Long:=TLong(Coord.At(I));
			Twig1 :=TAt(Long.Num);
       end;
		For I:=0 to Coord.Count-1 do
		 begin
		  Long:=TLong(Coord.At(I));
		  Long.Num:=Abs(Long.Num);
       end;
		 Long:=TLong(Coord.At(0));
       Lot2.Insert(Long.Num);
       { Вначале крутим веточки }
       { Пока колличество ветвей в Lot2<>Lot }
         Long :=Lot2.Coord.At(0);
			 Twig :=TAt(Long.Num);
			  DB:=Twig.Coord.At(0);
         J:=0;
         While ((Lot2.Coord.Count<>Coord.Count)) do
           begin
             { Найдем начало и конец Lot2 }
              Long1:=Lot2.Coord.At(Lot2.Coord.Count-1);
				  Twig1 :=TAt(Long1.Num);
               If Long1.Num<0 then DE:=Twig1.Coord.At(0) else
                  DE:=Twig1.Coord.At(Twig1.Coord.Count-1);
             { Перебираем все ветви Lot чтобы найти примыкающую к
               концу Lot2  началом или концом }
             I:=0;InsTwig:=False;
              While InsTwig=False do
               begin
                Long2:=Coord.At(I);
               If FindNum(Long2.Num)=False then
                begin
                Twig2:=TAt(Long2.Num);
                 DB1:=Twig2.Coord.At(0);
                 DE1:=Twig2.Coord.At(Twig2.Coord.Count-1);
                If (Abs(DB1.XDot-DE.XDot)<0.11) and (Abs(DB1.YDot-DE.YDot)<0.11) or
                   (Abs(DB1.XDot-DE.XDot)<0.11)
                                    and (Abs(DB1.YDot-DE.YDot)<0.11) then
                   begin
                     InsTwig:=True;
                     Lot2.Insert(Long2.Num);
                   end else
					 If (Abs(DE1.XDot-DE.XDot)<0.11) and (Abs(DE1.YDot-DE.YDot)<0.11) or
                   (Abs(DE1.XDot-DE.XDot)<0.11)
                                    and (Abs(DE1.YDot-DE.YDot)<0.11) then
                   begin
                     InsTwig:=True;
                     Lot2.Insert(-Long2.Num)
                   end;
               end;
                If I=Coord.Count-1 then InsTwig:=True;
                Inc(I);
           end;
          Inc(J);
          If J>500 then
           begin
             Lot2.Free;
            exit;
          end;
         end;
      end;
    Coord.FreeAll;                                               
    For I:=0 to Lot2.Coord.Count-1 do
     begin
      Insert(TLong(Lot2.Coord.At(I)).Num);
     end;
     Lot2.Free;
     InsClipDotsParall(Twf);
 end;

function TLot.SetFromTwig(Twf: TTwigsCollect): SmallInt;
 label 1;
 var
	Num,Num2:Longint;
	j,i:Integer;
	Twig1,Twig2:TTwig;
	DotB,DotE,TmTDot:TDot;
	PC:PCollection;
	connected,formok:boolean;
  AV,AV2:Integer;
  ColTwig:PCollection;                                        
 As0:Double;
 XX,YY:Double;
 B:Byte;
function CompareTwig(t1,t2:TTwig):boolean;
var
	Dt1,Dt2:TDot;
	i:LongInt;AV1,AV2:Integer;
begin
CompareTwig:=FALSE;
Dt1:=t1.coord.At(0);
Dt2:=t2.coord.At(0);
AV1:=t1.ArcView;t1.ArcView:=1;AV2:=t1.ArcView;t2.ArcView:=1;
try
If Selector.EqualPoints(Dt1,Dt2) then
	for i:=1 to t1.coord.count-1 do
		begin
		Dt1:=t1.coord.At(I);
		Dt2:=t2.coord.At(I);
		if (abs(Dt1.XDot-Dt2.Xdot)>As0)or(abs(Dt1.YDot-Dt2.Ydot)>As0) then exit;
   end
else
	for i:=0 to t1.coord.count-1 do
		begin
		Dt1:=t1.coord.At(I);
		Dt2:=t2.coord.At(t2.coord.count-1-I);
		if (abs(Dt1.XDot-Dt2.Xdot)>As0)or(abs(Dt1.YDot-Dt2.Ydot)>As0) then exit;
		end;
CompareTwig:=TRUE;
finally
 t1.ArcView:=AV1;t2.ArcView:=AV2;
end;
end;
 begin
//Const_Of_PrecCoord:=1000;
As0:=1/Const_Of_PrecCoord;
if TypeLot=254 then Exit;
SetFromTwig:=-4;
if Coord.Count=0 then exit;
{if Coord.Count=1 then
	begin
	 SetFromTwig:=-5;
	 Twig1:=TWF.TAt(abs(TLong(coord.At(0)).Num));
	 if (Twig1.Coord.Count=2)and(TypeLot=2) then exit;
	end;}
for i:=0 to Coord.Count-1 do
 begin
  TLong(Coord[I]).Num:=Abs(TLong(Coord[I]).Num);
 end;

for i:=coord.Count-1 downto 0 do
	begin
	Twig1:=TWF.TAt(TLong(coord.At(i)).Num);
	if Twig1.coord.Count<2 then
		begin
		{SetFromTwig:=-3;}
		coord.AtFree(i);
      {exit;}
      end;
	If Twig1.Closed=254 then
		begin
		SetFromTwig:=-2;
		exit;
		{Twig1.Closed:=1}
      end;
	end;

for i:=0 to coord.count-2 do
	begin
	Num:=abs(TLong(coord.At(i)).Num);
	for j:=i+1 to coord.count-1 do
		begin
		Num2:=abs(TLong(coord.At(j)).Num);
		if Num=Num2 then
			begin
			SetFromTwig:=-7;
         exit;
         end;
      end;
   end;
 If (TypeLot=1) or (TypeLot=0) then begin Plo:=0;ClearPlo:=0;SetFromTwig:=0;exit;end;
SetFromTwig:=-1;

{assign(f,'setfrt.tmp');
rewrite(f);}

PC:=PCollection.Create(1);
Num:=TLong(coord.At(0)).Num;
{write(f,Num);
}
PC.Insert(TLong.Create(abs(TLong(coord.At(0)).Num)));
Twig1:=TWF.TAt(Num);
DotB:=Twig1.coord.At(0);
DotE:=Twig1.coord.At(Twig1.coord.count-1);
Coord.AtFree(0);
if Selector.EqualPoints(DotB,DotE) then
	begin
	 DotB.XDot:=DotE.XDot;
	 DotB.YDot:=DotE.YDot;
	 formok:=true
	end
	else formok:=false;

connected:=false;
i:=0;

while (i<coord.Count)and(not formok) do
	begin
	Twig1:=TWF.TAt(abs(TLong(coord.At(i)).Num));
	connected:=false;
	TmTDot:=Twig1.coord.At(0);
        if Selector.EqualPoints(TmTDot,DotE) then
		begin
		TmTDot.XDot:=DotE.XDot;
		TmTDot.YDot:=DotE.YDot;
		PC.Insert(TLong.Create(abs(TLong(coord.At(i)).Num)));
		{Num:=TLong(coord.At(i)).Num;
		write(f,Num);}
		DotE:=Twig1.coord.At(Twig1.coord.count-1);
		Connected:=true;
		end
	else
		begin
        if Selector.EqualPoints(TmTDot,DotB) then
			begin
			TmTDot.XDot:=DotB.XDot;
			TmTDot.YDot:=DotB.YDot;
			PC.AtInsert(0,TLong.Create(-abs(TLong(coord.At(i)).Num)));
			DotB:=Twig1.coord.At(Twig1.coord.count-1);
			Connected:=true;
			end
		else
			begin
			TmTDot:=Twig1.coord.At(Twig1.coord.count-1);
        if Selector.EqualPoints(TmTDot,DotB) then
				begin
				TmTDot.XDot:=DotB.XDot;
				TmTDot.YDot:=DotB.YDot;
				PC.AtInsert(0,TLong.Create(abs(TLong(coord.At(i)).Num)));
				DotB:=Twig1.coord.At(0);
				Connected:=true;
				end
			else
				begin
        if Selector.EqualPoints(TmTDot,DotE) then
					begin
					TmTDot.XDot:=DotE.XDot;
					TmTDot.YDot:=DotE.YDot;
					PC.Insert(TLong.Create(-abs(TLong(coord.At(i)).Num)));
{					Num:=-TLong(coord.At(i)).Num;
					write(f,Num);}
					DotE:=Twig1.coord.At(0);
					Connected:=true;
               end;
            end;
         end;
		end;
	if Connected then
		begin
                 if Selector.EqualPoints(DotB,DotE) then formok:=true;
		Coord.AtFree(i);
		i:=0;
		end
	else
		inc(i);
	end;
//if Not FormOk then Writeln(-TmTDot.YDot:8:3,' ',TmTDot.XDot:8:3);
if FormOk then
	begin
	Coord.Free;
   coord:=pc;
  {xoord.FreeAll;
	seek(f,0);
	while not eof(f) do
		begin
		read(f,Num);
      coord.Insert(new(TLong,init(Num)));
		end;}
	SetFromTwig:=0;
	end
else
	begin
{	seek(f,0);
	while not eof(f) do
		begin
		read(f,Num);
      coord.Insert(new(TLong,init(Num)));
		end;
      }
	for i:=0 to Coord.Count-1 do
		begin
		PC.Insert(TLong.Create(abs(TLong(Coord.At(i)).Num)));
		end;
	Coord.Free;
	coord:=pc;
	end;
{close(f);}
if typeLot=1 then begin exit;end;
InsClipDotsParall(TWF);
Dotb:=TDot.Create(0,0,0);
if not GetPointIn(DotB,TWF) then
	begin
	 SetFromTwig:=-6;
  Goto 1;
	end;
// проверка на самопересечения
 ColTwig:=PCollection.Create(1);
 For I:=0 to Points.Count-2 do begin
  Twig1:=TTwig.Create(Selector, 0);
  Twig1.Insert(TDot.Create(TDot(Points[I]).XDot,TDot(Points[I]).YDot,0));Twig1.Insert(TDot.Create(TDot(Points[I+1]).XDot,TDot(Points[I+1]).YDot,0));
  ColTwig.Insert(Twig1);
 end;
 For I:=0 to ColTwig.Count-2 do begin
  Twig1:=ColTwig[I];
  For J:=I+1 to ColTwig.Count-1 do begin
   Twig2:=ColTwig[J];
   B:=Twig1.InterWith2(Twig2,XX,YY);
   If B<>0 then begin
    SetFromTwig:=-8;
    ColTwig.Free;
    Goto 1;
   end;
  end;
 end;
 ColTwig.Free;
 For I:=0 to Coord.Count-2 do
  begin
   Twig1:=TWF.TAT(TLong(Coord[I]).Num);
   AV:=Twig1.ArcView;Twig1.ArcView:=1;
    For J:=I to Coord.Count-1 do
     begin
       Twig2:=TWF.TAT(TLong(Coord[J]).Num);
       AV2:=Twig2.ArcView;Twig2.ArcView:=1;
        B:=Twig1.InterWith2(Twig2,XX,YY);
        If B<>0 then begin
          SetFromTwig:=-8;
          Twig2.ArcView:=AV2;
          Goto 1;
        end;
       Twig2.ArcView:=AV2;
     end;
   Twig1.ArcView:=AV;
  end;
{XC:=Dotb.XDot;YC:=DotB.YDot;}
1:
DotB.Free;
Points.Free;
{InsPoints(Twf);}
end;

function TLot.SetSqwear(TWF: TTwigsCollect): SmallInt;
 var b,K:Integer;PrB,PrE,PrPcb:TDot1;Tw:TTwig;
  begin
  Result:=-1;
if TypeLot=254 then Exit;
If Closed=0 then exit;
 If (TypeLot=1) or (TypeLot=0) then begin Plo:=0;ClearPlo:=0;SetSqwear:=0;exit;end;
 {		b:=SetFromTwig(TWF);
		If (b<0) then
		  begin
 			 SetSqwear:=0;
			 Plo:=-1;
          exit;
        end
	else}
	 InsClipDotsSqwear(Twf);
//	 InsClipDotsParall(Twf);
		With Points do
		 begin
                  Plo:=0;
          for K:=0 to Count-2 do
                 begin
                  If K=0 then begin
                   PrB :=(At(K));      {X[n]  }
                   Pre :=(At(K+1));    {Y[n+1]}
                   PrPcb:=(At(Count-2));{Y[n-1]}
                   end
                  else
                  If K=Count-2 then begin
                   PrB :=(At(K));      {X[n]  }
                   Pre :=(At(0));    {Y[n+1]}
                   PrPcb:=(At(K-1));    {Y[n-1]}
                   end
                  else
                  Begin
                   PrB :=(At(K));      {X[n]  }
                   Pre :=(At(K+1));    {Y[n+1]}
                   PrPcb:=(At(K-1));    {Y[n-1]}
						end;
                  Plo:=Plo+(Prb.X*(Pre.Y-PrPcb.Y));
                 end;
      Points.Free;
      Plo:=Abs(Plo/2);
  end;
  SetSqwear:=1;
  If Coord.Count=0 then Exit;
  Tw:=Twf.TAt(TLong(Coord[0]).Num);
  If Tw.ClassName='TTwigCircle' then begin
   Plo:=TTwigCircle(Tw).Radius*TTwigCircle(Tw).Radius*Pi;
  end;
  ClearPlo:=Plo;
end;

function TLot.SetClearSqwear(Index: Integer; TWF: TTwigsCollect;
 Os: AnsiString; PointsIns: boolean): Integer;
 var I,J,K:LongInt;XCenter,YCenter:Double;Lot:TLot;
		 B:Byte;
		 PD:TDot;
		 F:Boolean;
  Procedure SetFontsIns;
   var I:Integer;
   begin
  try
    if Fonts<>nil then
    For I:=0 to Fonts.Count-1 do
      TEFont(Fonts[I]).Ins:=NLot;
   except
   end;
  try
    if DataFonts<>nil then
    For I:=0 to DataFonts.Count-1 do
      TEFont(DataFonts[I]).Ins:=NLot;
   except
    DataFonts:=PCollection.Create(1);
   end;
   end;
begin
{     If UZnak=-1 then exit;}
if TypeLot=254 then exit;
If Closed=0 then exit;
 If (TypeLot=1) or (TypeLot=0) then begin Plo:=0;ClearPlo:=0;Ins:=-1;exit;end;
  If Twf.LotsCount<2 then exit;
     If Index=0 then
       begin
         ClearPlo:=Plo;
          SetFontsIns;
         exit;
       end;
	  ClearPlo:=Plo;
   If PointsIns then InsClipDotsParall(Twf);
    If Plo=-3 then
     begin
      Plo:=0;
      exit;
     end;
     For I:=Index-1 downTo 0 do
      With Twf do
      begin
       Lot:=LAtIndex(I);
        If (Round(XMin*Const_Of_PrecCoord)>=Round(Lot.Xmin*Const_Of_PrecCoord)) and
           (Round(YMin*Const_Of_PrecCoord)>=Round(Lot.YMin*Const_Of_PrecCoord))  and
           (Round(XMax*Const_Of_PrecCoord)<=Round(Lot.XMax*Const_Of_PrecCoord)) and
           (Round(YMax*Const_Of_PrecCoord)<=Round(Lot.YMax*Const_Of_PrecCoord))
{          or
           ((Round(XMin*Const_Of_PrecCoord)>=Round(Lot.Xmin*Const_Of_PrecCoord) and
           (Round(YMin*Const_Of_PrecCoord)>=Round(Lot.YMin*Const_Of_PrecCoord) and
           (Round(XMax*Const_Of_PrecCoord)<=Round(Lot.XMax*Const_Of_PrecCoord) and
           (Round(YMax*Const_Of_PrecCoord)<=Round(Lot.YMax*Const_Of_PrecCoord))} then
					 begin
      If (lot.TypeLot<>254) AND (lot.Closed<>0) then
			     begin
         If PointsIns then Lot.InsClipDotsParall(Twf);
    				  PD:=TDot.Create(0,0,10);
      If Os='' then F:=GetPointin(PD,TWF) else
      begin
       If Lot.GetProperty('*Ось')=Os then
        F:=GetPointin(PD,TWF)
         else F:=False;
      end;
				  If F then begin                                              
           If (ClassHandle.notClearPod=False) and (Lot.ClassHandle.notClearNad=False) then
					 If  InContur222(Lot.Points,PD.XDot,PD.YDot,B) then
							begin
                                            if Plo>0 then
                                             Lot.ClearPlo:=Lot.ClearPlo-Plo;
                                             Ins:=Lot.NLot;
                                              If BaseIns=-1 then
                                               BaseIns:=Lot.NLot;
							       If PointsIns then Points.Free;
								PD.Free;
							       If PointsIns then LOt.Points.Free;
                SetFontsIns;
							 exit;
							end;
					end
				else
					begin
                                        end;
		If PointsIns then Lot.Points.Free;
		 PD.Free;
	  end;
	 end;
	 end;
    If PointsIns then Points.Free;
   SetFontsIns;
  end;


function TLot.SetOwner(TWF: TTwigsCollect): AnsiString;
   begin
   end;

    procedure TLot.SetChildsIns(Twf: TTwigsCollect);
   var I:LongInt;L:TLot;
    begin
      For I:=0 to Twf.LotsCount-1 do
       begin
         L:=Twf.LAt(I);
         If L.TypeLot<>254 then
         If L.Closed<>0 then
          begin
           If L.Ins=NLot then L.SetOwner(Twf);
          end;
       end;
    end;


    procedure TLot.DeleteWithChilds(Twf: TTwigsCollect);
   var I:LongInt;L:TLot;
    begin
      For I:=0 to Twf.LotsCount-1 do
       begin
         L:=Twf.LAt(I);
          If L.Ins=NLot then L.DeleteWithChilds(Twf);
       end;
      TypeLot:=254;
    end;


  
function TLot.PointIn(Twf: TTwigsCollect; X, Y: Double; Param: Integer): Boolean;
  var W:Byte;I:Integer;Tw:TTwig;MM,S:Double;
   begin
    Result:=False;
	 if TypeLot=254 then begin PointIn:=False;Exit;end;
   if Coord.Count<1 then begin PointIn:=False;Exit;end;
	  If Closed=0 then begin PointIn:=False;Exit;end;
      If TypeLot=1 then
       begin
        S:=100;
         For I:=0 to Coord.Count-1 do
          With Selector do begin
           Tw:=TWF.TAt(TLong(Coord[I]).Num);
           If Tw.IsVisible(GRect) then
           If (X>Tw.XMax)or(X<Tw.XMin)or(Y>Tw.YMax)or(Y<Tw.YMin) then continue;
              S:=Tw.GetTwigDist(X,Y,MM,MM);
             If XRasst(S)<=4 then begin
              PointIn:=True;Break;
              end
              else PointIn:=False;
          end;
        Exit;
       end;
     InsClipDotsParall(Twf);
      PointIn:=Point_Inside_Polygon(X,Y,{XMax,YMax,XMin,YMin,}Points)>Param;
     Points.Free;
    If Result and (Hatches.Holes.Count>0) then begin
     For I:=0 to Hatches.Holes.Count-1 do If Point_Inside_Polygon(X,Y,{XMax,YMax,XMin,YMin,}Hatches.Holes[I])>Param then begin
      Result:=False;exit;
     end;
    end;
   end;

function TLot.PointLotIn(Twf: TTwigsCollect; Lot: TLot): Boolean;
var I:Integer;D:TDot1;
begin
 Result:=False;
 InsClipDotsParall(Twf);
 Lot.InsClipDotsParall(Twf);
  For I:=0 to Lot.Points.Count-1 do begin
   D:=Lot.Points[I];
   if Point_Inside_Polygon(D.X,D.Y,{XMax,YMax,XMin,YMin,}Points)>0 then begin  Result:=True; break;end;
  end;
 Lot.Points.Free; 
 Points.Free;
end;

    function TLot.LotIn(Twf: TTwigsCollect; Lot: TLot; usePoints: boolean;
   LineLot: boolean): Boolean;
  label 1;
  var I:Integer;D:TDot;
   begin
    Result:=False;XGlobalIn:=ZNull;
    if TypeLot=254 then Exit;
    if Coord.Count<1 then Exit;
    If Closed=0 then Exit;
    If not LineLot then If TypeLot=1 then Exit else If LineLot and UsePoints then Goto 1;
   //  вначале смотрим по габаритам
    If Round(Lot.Plo*10000)/10000>Round(Plo*10000)/10000 then Exit;
    Lot.SetMinMax(Twf);SetMinMax(Twf);
    If not ((Lot.XMin>=XMin) and (Lot.YMin>=YMin) and (Lot.XMax<=XMax) and (Lot.YMax<=YMax)) then Exit;
    Lot.InsClipDotsParall(Twf);
    InsClipDotsParall(Twf);
     For I:=0 to Lot.Points.Count-1 do
      begin
       D:=Lot.Points[I];
       if Point_Inside_Polygon2(D.XDot,D.YDot,XMax,YMax,XMin,YMin,Points)=-1 then
        begin
         XGlobalIn:=D.XDot;YGlobalIn:=D.YDot;
         Lot.Points.Free;Points.Free;
         Exit;
        end;
      end;
    Result:=True;
  1: If UsePoints then begin
     D:=TDot.Create(0,0,0);
     Result:=True;
     If LineLot then begin
      If Lot.GetPointIn(D,Twf) then
       Result:=Point_Inside_Polygon2(D.XDot,D.YDot,XMax,YMax,XMin,YMin,Points)>-1;
     end else
     If Lot.TypeLot<>1 then
      If Lot.GetPointIn(D,Twf) then
       Result:=Point_Inside_Polygon2(D.XDot,D.YDot,XMax,YMax,XMin,YMin,Points)>-1;
     D.Free;
   end;
     Points.Free;
     Lot.Points.Free;
   end;

  function TLot.GetZnak(X, Y: Double; var S: Double): Integer;
  var
     i:Integer;
     MinS:Double;
     PD:TPDot;
   begin
   Result:=-1;
	 if TypeLot=254 then exit;
	If (TypeLot<>2) then begin Plo:=0;ClearPlo:=0;exit;end;
	MinS:=10000;
    for i:=0 to UZnaks.count-1 do
      begin
        PD:=UZnaks.At(i);
        S:=sqrt(sqr(x-PD.xDot)+sqr(y-PD.yDot));
        if s<MinS then
           begin
            Mins:=S;
            Result:=I;
           end;
      end;
     S:=MinS;
   end;


  function TLot.GetPointIn(PD: TDot; Twf: TTwigsCollect): boolean;
  label
	a10;
  var
	TmpX,x1,y1,x2,y2:Double;
	I,J:integer;
	Dot1,Dot2:TDot;
	PC:PSC;
	b:byte;
	F:boolean;
 Tw:TTwig;
 C:byte;
  { ====================================== }
  x_min, x_max, y_min, y_max : double;
  pol, intervals : PCollection;
  { ====================================== }
   Procedure LineXY(var X,Y:Double);
    var I,J:Integer;Len,Len2,Len3:Double;D,D1:TDot1;
        Pnts:PCollection;
    begin
     // найдем центральную точку = 1/2 по периметру
     Len:=0;
     For I:=0 to Coord.Count-1 do
       begin
        Len:=Len+TTwig(TWF.TAT(TLong(Coord[I]).Num)).GetLength;
       end;
      If (Len<>0) then
      begin
       Pnts:=Points;               
      // InsClipDots(TWF);
         Solve_point_on_polyline(Points,Len/2,X,Y);
      // Points.Free;
       Points:=Pnts;
      end else
      begin
         X:=(Xmax+XMin)/2;
         Y:=(Ymax+YMin)/2;
      end;
    end;
  begin
  GetPointIn:=false;
   if TypeLot=254 then Exit;
  if TypeLot=1 then
    begin
     if Points.Count<2 then Exit;
      LineXY(PD.XDot,PD.YDot);
      GetPointIn:=True;
     Exit;
    end;
  SetMinMax(Twf);
  { ====================================== }
  pol := PCollection.Create(1);
  for i := 0 to Points.Count-1 do
   pol.Insert( TDot1.Create( TDot( Points[i] ).XDot, TDot( Points[i] ).YDot ) );
{
  x1 := XMin;
  y1 := ( YMin + YMax ) / 2;
  x2 := XMax;
  y2 := y1;
}
  x1 := XMin-1;
  y1 := (YMin+YMax)/2;
  x2 := XMax+1;
  y2 := y1;
//  DrawLine(x1,y1,x2,y2);
//  if NLot=5 then Writeln('X2=',XMax:8:4);

//  DrawLine(X1,Y1,X2,Y2);
  intervals := intersection_interval_and_polygon( pol, x1, y1, x2, y2 );
  if intervals.Count > 0 then  
    begin
      Result := TRUE;
{
      For I:=0 to Intervals.Count-1 do
      With TEdge(Intervals[I]) do begin
       Tw:=TTwig.Create(0);
       TWF.Insert(TWG_Twig,Tw);
       Tw.Insert(TDot.Create(x1,y1,0));
       Tw.Insert(TDot.Create(x2,y2,0));
       Tw.SetMinMax;
      end;//}
{
       Tw:=TTwig.Create(0);
       TWF.Insert(TWG_Twig,Tw);
       Tw.Insert(TDot.Create(x1,y1,0));Tw.Insert(TDot.Create(x2,y2,0));
       Tw.SetMinMax;
      writeln('...',intervals.count,'  ',distance(TEdge( intervals[1] ).x1,TEdge( intervals[1] ).y1,
      TEdge( intervals[1] ).x2,TEdge( intervals[1] ).y2));

      writeln(Pol.Count);
      readln;
}
//
      PD.XDot := ( TEdge( intervals[0] ).x1 +  TEdge( intervals[0] ).x2 ) / 2;
      PD.YDot := ( TEdge( intervals[0] ).y1 +  TEdge( intervals[0] ).y2 ) / 2;
//      PArcEx(PD.XDot,PD.YDot,10);
    end
  else begin
         Result := FALSE;
       end;
   Pol.Free;
   Intervals.Free;
  { ====================================== }
end;



procedure 	  TLot.FreeDoublTwig;
var
	i,j:Integer;
   N1,N2:longint;
begin
	 if TypeLot=254 then Exit;
	i:=0;
	while i<coord.Count do
		begin
		N1:=Abs(TLong(coord.At(i)).Num);
		inc(i);
      j:=i;
		while j<coord.Count do
			begin
			N2:=Abs(TLong(coord.At(j)).Num);
			IF n2=N1 THEN coord.AtFree(j)
			else inc(j);
         end;
      end;

end;

procedure TLot.FreeDelTwig(TWF: TTwigsCollect);
var
   Twig:TTwig;
   i,j:Integer;
   N1,N2:longint;
begin
if TypeLot=254 then Exit;
for i:=coord.Count-1 downto 0 do
 begin
   Twig:=TWF.TAt(TLong(coord.At(i)).Num);
   if Twig.Closed=254 then
            coord.AtFree(i);
 end;
end;


function TLot.TextNotOk(DC: hDC; Twf: TTwigsCollect): boolean;
var
	x,y,TmpUg:Double;
	Dx,Dy:word;
	w:byte;
begin
 {111}
(*	TextNotOk:=false;

	if text<>nil then
		if text.Named=nil then
      	begin
			Text.Free;
			Text:=nil;
         end;


	if text<>nil then
		begin
                                                                   
		InsPoints(Twf);

		x:=text.Xf;
		y:=text.yf;
		if not InContur222(Points,X,Y,W) then TextNotOk:=true
		else
			begin
			TmpUg:=Text.UgolRotate/1800*Pi;
			x:=text.Xf+cos(Pi/2-TmpUg)*(text.HF/10);
			y:=text.YF+sin(Pi/2-TmpUg)*(text.HF/10);
			if not InContur222(Points,X,Y,W) then TextNotOk:=true;
			end;

                points.Free;
		end;
*)
end;


procedure TLot.SeeCoord(Twf: TTwigsCollect);
var
	i:Integer;
	Twig:TTWig;
	Dot:TDot;
   N:longint;
begin
for i:=0 to coord.count-1 do
	begin
	N:=TLong(coord.At(i)).Num;
	Twig:=twf.TAt(N);
	writeln(Twig.coord.count-1);
	if N<0 then
		begin
		dot:=Twig.coord.At(Twig.coord.count-1);
		writeln(Dot.XDot:10:4,' ',Dot.YDot:10:4);
		dot:=Twig.coord.At(0);
		write(Dot.XDot:10:4,' ',Dot.YDot:10:4);
		end
	else
		begin
		dot:=Twig.coord.At(0);
		writeln(Dot.XDot:10:4,' ',Dot.YDot:10:4);
		dot:=Twig.coord.At(Twig.coord.count-1);
		write(Dot.XDot:10:4,' ',Dot.YDot:10:4);
		end;
   readln;
	end;
writeln;
end;

function TLot.SumTwigs: Integer;
 var I:Integer;
  begin
   Result:=0;
   For I:=0 to Coord.Count-1 do
    begin
     Result:=Result+Abs(TLong(Coord.At(I)).Num);
    end;
  end;

function TLot.EqualDelete(CR: PCollection): Integer;
 var I,J:Integer;
     Num,NumCR,CntEqual:Integer;
 begin
  CntEqual:=0;
  For I:=0 to CR.Count-1 do
   begin
    NumCr:=Abs(TLong(CR.At(I)).Num);
     For J:=0 to Coord.Count-1 do
      If Abs(TLong(Coord.At(J)).Num)=NumCr then
       Inc(CntEqual);
   end;
 Result:=CntEqual;
 // узнаем есть-ли в контуре ветви из коллекции CR
{
 If Result then
 begin
  CntEqual:=0;
  For I:=0 to CR.Count-1 do
   begin
    NumCr:=Abs(TLong(CR.At(I)).Num);
     For J:=Coord.Count-1 downTo 0 do
      If Abs(TLong(Coord.At(J)).Num)=NumCr then begin Coord.AtFree(J);Inc(CntEqual);end;
   end;
 end;
}
end;

function TLot.SetTwgs(Twf: TTwigsCollect; NN: Byte; LotsCol1: PCollection
 ): Boolean;
 var J,I,K:integer;XD,YD:Double;Twig:TTwig;M:Integer;
     NTwig:Integer;L:TLot;Sum:Integer;
begin
Result:=False;
// устанавливает для всех ветвей признак удаления
With TWF do
 For I:=0 to Coord.Count-1 do
   begin
    NTwig:=Abs(TLong(Coord.At(I)).Num);
    Twig:=TAt(NTwig);
    Twig.Closed:=NN;
   end;
//
With TWF do
  If NN=254 then
   begin
    For I:=0 to LotsCount-1 do begin
      L:=LAt(I);
      K:=L.Coord.Count;
      If L.EqualDelete(Coord)=L.Coord.Count then begin
       If LotsCol1<>nil then LotsCol1.Insert(L);
       // If L.Coord.Count = 0 then L.Closed:=254;
        { L.Coord.Insert(TLong.Create(TwigsCount-1));
         L.SetMinMax(TWF);
         L.SetFromTwig(TWF);
         If LotsCol<>nil then begin
          LotsCol.Insert(L);
         end; }
         Result:=True;
       end;
     end;
   end;
end;

      procedure TLot.MakeLines(Twf: TTwigsCollect);
	var J,I,K:Integer;XD,YD:Double;Twig:TTwig;M:Integer;
	begin
         For I:=0 to Coord.Count-1 do
          begin
          With TWF do
           begin
            Twig:=TAt(Abs(TLong(Coord.At(I)).Num));
            Twig.Color:=ClassHandle.RGB;
           end;
	end;
  end;

  procedure TLot.Reset(I, J: LongInt);
  var T:TLong;
  begin
   For I:=0 to Coord.Count-1 do
    begin
     T:=Coord[I];
      If ABS(T.Num)=I then BEGIN T.Num:=J;END;
    end;
  end;

procedure TLot.DelUdTwigs(Twf: TTwigsCollect; MinOtr: Double);
  var I,N:Integer;Tw,Tw1:TTwig;D1,D2,D3,D4:TDot;B:Boolean;
  begin
  B:=True;
   With Selector,GGraphset do
   For I:=Coord.Count-1 downto 0 do
    begin
      N:=TLong(Coord[I]).Num;
      Tw:=TWF.TAt(N);
       If (Tw.Closed=254) and (Tw.Coord.Count=2) then begin
         D1:=Tw.Coord[0];
         D2:=Tw.Coord[1];
          If Sqrt(Sqr(D1.XDot-D2.XDot)+Sqr(D1.YDot-D2.YDot))<=MinOtr then
           begin
            Coord.AtDelete(I);
            B:=False;
           end;
        end;
    end;
//  If not B then
   For I:=0 to Coord.Count-2 do
    begin
      Tw:=TWF.TAt(TLong(Coord[I]).Num);
      Tw1:=TWF.TAt(TLong(Coord[I+1]).Num);
      D1:=Tw.Coord[0];D2:=Tw.Coord[Tw.Coord.Count-1];
      D3:=Tw1.Coord[0];D4:=Tw1.Coord[Tw1.Coord.Count-1];
       If Sqrt(Sqr(D1.XDot-D3.XDot)+Sqr(D1.YDot-D3.YDot))<=MinOtr then
        begin
         D1.XDot:=D3.XDot;D1.YDot:=D3.YDot;
        end else
       If Sqrt(Sqr(D2.XDot-D3.XDot)+Sqr(D2.YDot-D3.YDot))<=MinOtr then
        begin
         D2.XDot:=D3.XDot;D2.YDot:=D3.YDot;
        end else
       If Sqrt(Sqr(D1.XDot-D4.XDot)+Sqr(D1.YDot-D4.YDot))<=MinOtr then
        begin
         D1.XDot:=D4.XDot;D1.YDot:=D4.YDot;
        end else
       If Sqrt(Sqr(D2.XDot-D4.XDot)+Sqr(D2.YDot-D4.YDot))<=MinOtr then
        begin
         D2.XDot:=D4.XDot;D2.YDot:=D4.YDot;
        end;
    end;
  end;


{--------------------------------------------------------------}
{ Lines                                                        }
{--------------------------------------------------------------}
{--------------------------------------------------------------}
{ Добавление контура                                           }
{--------------------------------------------------------------}
function TLot.AddLot(TWF: TTwigsCollect; L: TLot): Boolean;
 var I,J:Integer;
  Function FindTwig(Ind:Integer):Boolean;
   var I:Integer;
   begin
    Result:=False;
    For I:=0 to Coord.Count-1 do
     If TLong(Coord[I]).Num=Ind then begin Result:=True;Exit;end;
   end;
 begin
  Result:=False;
  try
  { добавляем ветки }
   For I:=0 to L.Coord.Count-1 do
    If not FindTwig(TLong(L.Coord[I]).Num) then
     begin
      Coord.Insert(L.Coord[I]);
      TTwig(Twf.TAt(TLong(L.Coord[I]).Num)).SetMinMax;
     end;
   L.Coord.DeleteAll;
   { добавляем подписи }
   If L.DataFonts<>nil then
   begin
    if DataFonts=nil then DataFonts:=PCollection.Create(1);
    For I:=0 to L.DataFonts.Count-1 do
     DataFonts.Insert(L.DataFonts[I]);
    L.DataFonts.DeleteAll;
   end;
   If L.Fonts<>nil then
   begin
    if Fonts=nil then Fonts:=PCollection.Create(1);
     For I:=0 to L.Fonts.Count-1 do
      Fonts.Insert(L.Fonts[I]);
     L.Fonts.DeleteAll;
   end;
  { добавляем линии }
   If L.Lines<>nil then
   begin
    if Lines=nil then Lines:=PCollection.Create(1);
     For I:=0 to L.Lines.Count-1 do
      Lines.Insert(L.Lines[I]);
     L.Lines.DeleteAll;
   end;
  { знаки не добавляем }
   SetMinMax(TWF);
    Result:=True;
   SetFromTwig(TWF);
  Except on E:Exception do
  end;
 end;

{--------------------------------------------------------------}
{ Удаление веток с контуром                                    }
{--------------------------------------------------------------}
procedure TLot.DeleteTwigsWith(Twf: TTwigsCollect);
 var I,J,K:Integer;L:TLot;B:Boolean;T:TTwig;
 begin
  // помечаем ветви которые нельзя удалять
  For I:=0 to Twf.LotsCount-1 do
   begin
    L:=Twf.Lat(I);
     if L<>Self then
     if (L.TypeLot<>254) then
      For J:=Coord.Count-1 downTo 0 do
       For K:=L.Coord.Count-1 downTo 0 do
        begin
         If Abs(TLong(Coord[J]).Num)=Abs(TLong(L.Coord[K]).Num) then
          begin
           TTwig(Twf.TAt((TLong(Coord[J]).Num))).Closed:=252;
          end;
        end;
   end;
  // удаляем ветви из смежных включенных (и удаленных) контуров если они не помечены 252
{  For I:=0 to Twf.LotsCount-1 do
   begin
    L:=Twf.Lat(I);
    If L<>Self then
    If (L.TypeLot=254)or(L.Closed<>0) then
      For J:=Coord.Count-1 downTo 0 do
       For K:=L.Coord.Count-1 downTo 0 do
        begin
         If Abs(TLong(Coord[J]).Num)=Abs(TLong(L.Coord[K]).Num) then
          begin
           T:=Twf.TAt(TLong(Coord[J]).Num);
            If T.Closed<>252 then
             begin
              T.Closed:=253;
              Coord.AtFree(J);L.Coord.AtFree(K);
             end;
          end;
        end;
   end;}
   // удаляем ветви из контура которые не помечены
   For J:=Coord.Count-1 downTo 0 do
    begin
     T:=Twf.TAt(TLong(Coord[J]).Num);
     If T.Closed<>252 then
      begin
       T.Closed:=253;
      end else T.Closed:=0;
    end;
 end;

{--------------------------------------------------------------}
{ 3D                                                           }
{--------------------------------------------------------------}
function TLot.is3DPolygon(TWF: TTwigsCollect): Boolean;
 var I,J:Integer;Twig:TTwig;
 begin
  Result:=True;
  With TWF do
   begin
    For I:=0 to Coord.Count-1 do
     begin
      Twig:=TAt(TLong(Coord.At(I)).Num);
       For J:=0 to Twig.Coord.Count-1 do
        begin
         if TDot(Twig.Coord[J]).Z=ZNull then begin Result:=False;Exit;end;
        end;
     end;
   end;
 end;

function TLot.Make3dPoint(TWF: TTwigsCollect; P: TPointDot): Byte;
 var PD:TDot;I,J,TC,LC:Integer;Twig:TTwig;
 begin
  TC:=0;LC:=0;Result:=0;
    For I:=0 to Coord.Count-1 do
     begin
      Twig:=TWf.TAt(TLong(Coord.At(I)).Num);
       For J:=0 to Twig.Coord.Count-1 do
        begin
         PD:=Twig.Coord[J];
         if Selector.EqualPoints(PD,P) then begin PD.Z:=P.Z;Inc(TC);Result:=1;end;
        end;
     end;
    For I:=0 to Lines.Count-1 do begin
      Twig:=Lines[I];If Twig is TTwigTriangle then
       For J:=0 to Twig.Coord.Count-1 do begin
         PD:=Twig.Coord[J];
         if Selector.EqualPoints(PD,P) then begin PD.Z:=P.Z;Inc(LC);Result:=Result+2;end;
        end;
    end;
 end;

function TLot.Perimeter(TWF: TTwigsCollect): Double;
 var D1,D2:TDot1;I:Integer;N:Double;
 begin
  Result:=0;
  For I:=0 to Coord.Count-1 do begin
   Result:=Result+GetTwig(TWF,I).GetLength;
  end;
  exit;
  N:=0;
  InsClipDotsParall(TWF);
   For I:=0 to Points.Count-2 do
    begin
     D1:=Points[I];D2:=Points[I+1];
     N:=N+Distance(D1.X,D1.Y,D2.X,D2.Y);
    end;
   Result:=N;
  Points.Free;
 end;

procedure TLot.ResetPromer(TWF: TTwigsCollect);
 var I:Integer;D,D1,D2:TDot;XC,YC,R1,RPlus,Ugol,Beta,U1,U2:Double;S:AnsiString;F:TEFont;C:Byte;
     FlagBeta:Boolean;Clock:Boolean;
  Procedure MoveFont(F:TEFont;Disst,Ugol:Double); // возвращает угол
   var S,DX,DY:Double;WX,WY:Word;
   begin
{    F.GetTextDim(GCanvas.Handle,WX,WY);
    S:=XGeoRasst(WX)/2;}
    S:=Disst;DX:=S*Cos(Ugol);DY:=S*Sin(Ugol);
    F.XF:=F.XF-DX;F.YF:=F.YF-DY;
   end;
  Procedure UpdatePromer(F:TEFont;D,D1:TDot);
   var S,DX,DY:Double;WX,WY:Word;FlagBeta:Boolean;
   begin
    Ugol:=ArcCat(D.XDot,D.YDot,D1.XDot,D1.YDot,C)*Pi/180;
    If C in [1,4] then
     begin
      F.UgolRotate:=Round(-1800/Pi*Ugol);
      MoveFont(F,ClassHandle.FW*StrLen(F.Named)/2,Ugol);
      if (What=Lot_Promer)or(What=Lot_PromerPlus) then MoveFont(F,ClassHandle.FH,Ugol+Pi/2);
     end else
     begin
      Ugol:=ArcCat(D1.XDot,D1.YDot,D.XDot,D.YDot,C)*Pi/180;
      F.UgolRotate:=Round(-1800/Pi*Ugol);
      MoveFont(F,ClassHandle.FW*StrLen(F.Named)/2,Ugol);
      if (What=Lot_Promer)or(What=Lot_PromerPlus) then MoveFont(F,ClassHandle.FH,Ugol+Pi/2);
     end;
   end;
 begin                                                           
  If What<Lot_Promer then Exit;
   if Fonts=nil then Fonts:=PCollection.Create(1);
   For I:=Fonts.Count-1 downTo 0 do If TEFont(Fonts[I]).What in [fnt_Promer,fnt_PromerAlfa,fnt_PromerBeta] then Fonts.AtFree(I);
   InsClipDotsParall(TWF);
   If Points.Count=1 then Exit;
   RPlus:=0;
    Clock:=Selector.EqualPoints(Points[0],Points[Points.Count-1]);
    For I:=0 to Points.Count-2 do
     begin
      D:=Points[I];D1:=Points[I+1];
      If I<>0 then D2:=Points[I-1] else If Clock then D2:=Points[Points.Count-2];
     // координаты центра и расстояния
      XC:=(D.XDot+D1.XDot)/2;YC:=(D.YDot+D1.YDot)/2;
      R1:=Distance(D.XDot,D.YDot,D1.XDot,D1.YDot);
      If What=Lot_Promer then RPlus:=R1 else RPlus:=RPlus+R1; // расстояние
      Ugol:=ArcCat(-D.YDot,D.XDot,-D1.YDot,D1.XDot,C); // напрaвление
      If (I<>0)or Clock then // угол
       begin
        FlagBeta:=True;
        U1:=ArcCat(-D.YDot,D.XDot,-D1.YDot,D1.XDot,C);
        U2:=ArcCat(-D.YDot,D.XDot,-D2.YDot,D2.XDot,C);
        Beta:=U1-U2;If Beta<0 then Beta:=(360+Beta);
       end else FlagBeta:=False;
   // создаем подпись
      Case What of
       Lot_PromerAlfa:F:=TEfont.CreateClass(ClassHandle,0,XC,YC,Selector.AngleToStr(Ugol,True,'.'),fnt_PromerAlfa);
       Lot_Promer    :F:=TEfont.CreateClass(ClassHandle,0,XC,YC,FloatToStrF(RPlus,ffFixed,_LD,Const_Of_DecimalLength),fnt_Promer);
       Lot_PromerPlus:F:=TEfont.CreateClass(ClassHandle,0,XC,YC,FloatToStrF(RPlus,ffFixed,_LD,Const_Of_DecimalLength),fnt_Promer);
       Lot_PromerBeta:if FlagBeta then F:=TEfont.CreateClass(ClassHandle,0,D.XDot,D.YDot,Selector.AngleToStr(Beta,False,'.'),fnt_PromerBeta) else F:=nil;
      end;
       if F<>nil then Fonts.Insert(F);
        if What<>Lot_PromerBeta then UpdatePromer(F,D,D1);
     end;
   Points.Free;
 end;

 function TLot.LotColor: LongInt;
 var S:AnsiString;
 begin
 // With Selector do If (GlobalSettings.Settings.gsColorZnaksCheck) and (TypeLot<>2) then Result:=GlobalSettings.Settings.gsColorZnaks else begin
   If Properties = nil then Result:=ClassHandle.GetColor else
   Result:=Properties.GetIntValueDef('Цвет заливки',ClassHandle.GetColor);
{ старая процедура
   S:=GetProperty('Цвет заливки');
   If S=byLayer then Result:=RGB(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]) else
   try
    Result:=StrToInt(S);
   except Result:=RGB(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]); SetProperty('Цвет заливки',byLayer);end;
}
//  end;
 end;

function TLot.LotLineColor: LongInt;
var S:AnsiString;Color:Integer;
begin
// With Selector do If (GlobalSettings.Settings.gsColorZnaksCheck) then Result:=GlobalSettings.Settings.gsColorZnaks else begin
  //S:=propIndex(lpColor);
  If Properties = nil then Result:=ClassHandle.LineColor else
  Result:=Properties.GetIntValueDef('Цвет',ClassHandle.LineColor);
 { старая процедура
  If S=byLayer then Result:=ClassHandle.LineColor else
  try
   Result:=StrToInt(S);
  except Result:=ClassHandle.LineColor;SetProperty('Цвет',byLayer);end;
 }
// end;
end;

function TLot.CsColor: TRGBRec;
var S:AnsiString;Res:Integer;
begin
//   If TypeLot =2 then S:=propIndex(lpFillColor) else S:=byLayer;
  If Properties = nil then Result:=ClassHandle.RGB else begin
   Res:=Properties.GetIntValueDef('Цвет заливки',ClassHandle.GetColor);
   Result.ARGB[1]:=GetR(Res);Result.ARGB[2]:=GetG(Res);Result.ARGB[3]:=GetB(Res);
  end;
 {
   If S<>byLayer then
   try
    Res:=StrToInt(S);
    Result.ARGB[1]:=GetRValue(Res);Result.ARGB[2]:=GetGValue(Res);Result.ARGB[3]:=GetBValue(Res);
   except SetProperty('Цвет заливки',byLayer);end;
  }
end;

  function TLot.CsLineColor: TRGBRec;
 var S:AnsiString;Res:Integer;Color:Integer;
  begin
   Color:=LotLineColor;
   Result.ARGB[1]:=GetR(Color);Result.ARGB[2]:=GetG(Color);Result.ARGB[3]:=GetB(Color);
   exit;
  //
   S:=GetProperty('Цвет');
   If S<>byLayer then
   try
    Res:=StrToInt(S);
    Result.ARGB[1]:=GetR(Res);Result.ARGB[2]:=GetG(Res);Result.ARGB[3]:=GetB(Res);
   except SetProperty('Цвет',byLayer);end;
  end;

  function TLot.CsRang: Byte;
  begin
   Result:=Round(Frac(ClassHandle.Rang)*100);
  end;

  function TLot.CsHatch: Byte;
  var Prop:AnsiString;
  begin
   Result:=ClassHandle.Hatch;
//   If Properties = nil then exit else Result:=Properties.GetIntValueDef('#Штриховка',ClassHandle.Hatch);
   prop:=GetProperty('#Штриховка');
   If prop<>byLayer then begin
    try Result:=StrToInt(prop); {If Result<>-1 then If UZnaks.Count = 0 then Result:=-2;}except end;
   end;
  end;

  function TLot.CsNBase: Byte;
  begin
   Result:=ClassHandle.NBase;
  end;

  function TLot.CsUZnak: SmallInt;
 var prop:AnsiString;
  begin                                                    
   Result:=ClassHandle.SSInd;
//   If Result<>-1 then If UZnaks.Count = 0 then Result:=-1;
   prop:=GetProperty('Тип заливки');
   If prop<>byLayer then begin
    try Result:=StrToInt(prop); {If Result<>-1 then If UZnaks.Count = 0 then Result:=-2;}except end;
   end;
  end;

function TLot.csLineZnak: Integer;
 var prop:AnsiString;
  begin
   Result:=ClassHandle.ZnkInd.LInd;
   If Properties = nil then exit else Result:=Properties.GetIntValueDef('Тип линии',ClassHandle.ZnkInd.LInd);
  (*
//   If Result<>-1 then If UZnaks.Count = 0 then Result:=-1;
   prop:=GetProperty('Тип линии');
   If prop<>byLayer then begin
    try Result:=StrToInt(prop); {If Result<>-1 then If UZnaks.Count = 0 then Result:=-2;}except end;
   end;
  *)
  end;

 function TLot.CsKoef: Double;
 var prop:AnsiString;
  begin
   Result:=ClassHandle.ZnakKoef;
   If Properties = nil then exit else Result:=Properties.GetFloatValueDef('Масштаб',ClassHandle.ZnakKoef)
  {
   prop:=GetProperty('Масштаб');
   If prop<>byLayer then begin
    try Result:=GStrToFloat(prop); except end;
   end;
  }                                                  
  end;

function TLot.CsGlass: Boolean;
begin
 With Selector do
 If ClassHandle=nil then Result:=GGraphSet.bmGlass else
 If ClassHandle.Standart=0 then Result:=ClassHandle.GlassFon else Result:=GGraphSet.bmGlass;
end;

function TLot.csShowAttrib: Boolean;
begin
 With Selector do
 If ClassHandle=nil then Result:=GGraphSet.ShowAttributes else
 If ClassHandle.Standart=0 then Result:=ClassHandle.ShowAttr else Result:=GGraphSet.ShowAttributes;
end;

procedure TLot.InsTwigs(TWF: TTwigsCollect);
 var Tw:TTwig;Twig:TTwig;I:Integer;D,D2:TDot;P:PCollection;
 begin
    Points:=PCollection.Create(1);
   If Coord.Count=0 then Exit;
   For I:=0 to Coord.Count-1 do
    begin
     Twig:=TWF.TAt(TLong(Coord.At(I)).Num);
     Tw:=TTwigClass(Twig.ClassType).CreateAsTwig(Twig,True);
     Points.Insert(Tw);
    end;
 exit;
   If Coord.Count=0 then Exit;
   If Coord.Count=1 then
    begin
     Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
     Tw:=TTwig.Create(Selector, 0);Tw.AddTwig(Twig);
     Points.Insert(Tw.Coord);
     Exit;
    end;                      
  { крутим ветки }
   Twig:=TWF.TAt(TLong(Coord.At(0)).Num);
   Tw:=TTwig.Create(Selector, 0);Tw.AddTwig(Twig);
   Points.Insert(Tw.Coord);
   For I:=1 to Coord.Count-1 do
    With TWF do
     begin
      Twig:=TAt(TLong(Coord.At(I)).Num);
       If TLong(Coord.At(I)).Num>0 then
        begin // положительное направление
         Tw:=TTwig.Create(Selector, 0);Tw.AddTwig(Twig);
         Points.Insert(Tw.Coord);
        end else
        begin
         Tw:=TTwig.Create(Selector, 0);Tw.AddTwig(Twig);Tw.Rotation;
         Points.Insert(Tw.Coord);
        end;
     end;
{    For I:=0 to Points.Count-1 do
     If PCollection(Points[I]).Count=2 then
      begin
       P:=Points[I];
       D:=P[0];D2:=P[1];
       If EqualPoints(D,D2) then
        begin
         Writeln('EST');
         readln;
        end;
      end;}
 end;

procedure TLot.objMoveTwigNumbers(N: Integer);
 var I:Integer;L:TLong;
 begin
  For I:=0 to Coord.Count-1 do
   begin
    L:=Coord[I];
    L.Num:=L.Num+N;
   end;
 end;

{--------------------------------------------------------------}
{ GBS                                                          }
{--------------------------------------------------------------}
function TLot.GBS: Double;
 begin
  Result:=XMax+XMin+YMax+YMin;
 end;

procedure TLot.ResetTaheoIndexesForAllTwigs(TWF: TTwigsCollect);
 var Tw:TTwig;I:Integer;
 begin
  For I:=0 to Coord.Count-1 do
   begin
    Tw:=TWF.TAt(TLong(Coord[I]).Num);
    Tw.TaheoIndex:=-1;
   end;
 end;

procedure TLot.SetActiveLine(TWF: TTwigsCollect; XR, YR: Double;
  var Line: TSect);
var TW:TTwig;I,Index:Integer;X,Y,MinD,D:Double;D1,D2:TDot;
begin
 Line.XA:=ZNull;
 With TWF do begin
  MinD:=1000000000;Index:=-1;
   For I:=0 to Coord.Count-1 do
    begin
     TW:=TAt(TLong(Coord[I]).Num);
     D:=TW.GetTwigDist(XR,YR,X,Y);
     If D<MinD then if TW.Coord.Count>1 then begin MinD:=D;Index:=I;end;
    end;
   if Index=-1 then Exit;
   TW:=TAt(TLong(Coord[Index]).Num);
   Index:=TW.GetSegment(XR,YR);
   If Index=-1 then Exit;
   D1:=TW.Coord[Index-1];D2:=TW.Coord[Index];
   With Line do begin XA:=D1.XDot;YA:=D1.YDot;XB:=D2.XDot;YB:=D2.YDot;end;
  end;
end;

procedure TLot.UpdateWithTwigs(TWF:TTwigsCollect;Index:Integer;P: PCollection;SetTwig:Boolean);
 var I:Integer;
 Function Found(N:Integer):boolean;
  var I:Integer;
  begin
   Result:=False;
   For I:=0 to P.Count-1 do
    if Abs(TLong(P[I]).Num)=Abs(N) then begin Result:=True;Exit;end;
  end;
begin
 For I:=0 to Coord.Count-1 do
  If Found(TLong(Coord[I]).Num) then begin
   If SetTwig then SetFromTwig(TWF);
   SetMinMax(TWF);SetSqwear(TWF);ReSetPromer(TWF);Exit;
  end;
end;

function TLot.GetCorrectInfo(TWF: TTwigsCollect; var S1, S2: AnsiString
 ): boolean;
var D1,D2:TDot;
begin
 S1:='Нет.';S2:='Нет';
 If SetFromTwig(TWF)=-1 then
  begin
   InsClipDotsParall(TWF);
   D1:=Points[0];D2:=Points[Points.Count-1];
   S1:='X1= '+FloatToStrF(-D1.YDot,ffFixed,_LD,Const_Of_DecimalCoord)+', Y1= '+
                 FloatToStrF(D1.XDot,ffFixed,_LD,Const_Of_DecimalCoord)+
           '; X2= '+FloatToStrF(-D2.YDot,ffFixed,_LD,Const_Of_DecimalCoord)+', Y1= '+
                 FloatToStrF(D2.XDot,ffFixed,_LD,Const_Of_DecimalCoord);
   S2:='Встать на точку';
   Points.Free;
  end;
end;

procedure TLot.GetCorrectPoint(TWF: TTwigsCollect; var XDot, YDot: Double);
var D1,D2:TDot;
 begin
   InsClipDotsParall(TWF);
   D1:=Points[0];D2:=Points[Points.Count-1];
   XDot:=D1.XDot;YDot:=D1.YDot;
   Points.Free;
end;



function TLot.IntersectedWithTwig(TWF: TTwigsCollect; Twig: TTwig; var X,
 Y: Double): boolean;
var I:Integer;Tw:TTwig;
begin
 Result:=False;
 For I:=0 to Coord.Count-1 do begin
  Tw:=TWF.TAt(TLong(Coord[I]).Num);
  if Tw.InterWith(Twig,X,Y) then begin Result:=True;break;end;
 end;
end;

function TLot.IntersectedWithTwig2(TWF: TTwigsCollect; Twig: TTwig; var X,
 Y: Double): boolean;
var I:Integer;Tw:TTwig;
begin
 Result:=False;
 For I:=0 to Coord.Count-1 do begin
  Tw:=TWF.TAt(TLong(Coord[I]).Num);
  if Tw.InterWith2(Twig,X,Y,0)>0 then begin Result:=True;break;end;
 end;
end;

procedure TLot.InsertDataPoint(P: TPointDot);
begin
 DataPoints.Insert(P);
end;

function TLot.GetTwig(Twigs: TTwigsCollect; Index: Integer): TTwig;
begin
 Result:=Twigs.TAt(TLong(Coord[Index]).Num);
end;

function TLot.FindTwig(Twigs:TTwigsCollect;X, Y: Double;var Dist:Double): TTwig;
var S:Double;X1,Y1:Double;I:Integer;
begin
 Dist:=100000000000;Result:=nil;
 For I:=0 to Coord.Count-1 do begin
  S:=GetTwig(Twigs,I).GetTwigDist(X,Y,X1,Y1);
  if S<Dist then begin Dist:=S;Result:=GetTwig(Twigs,I);end;
 end;
end;

function TLot.isCircle(Twigs:TTwigsCollect;var X, Y, Rad: Double): boolean;
var Tw:TTwig;
begin
 Result:=False;
 if Coord.Count=1 then begin
  Tw:=GetTwig(Twigs,0);
  If Tw.ClassName='TTwigCircle' then begin
   Result:=True;
   X:=TTwigCircle(Tw).C.XDot;Y:=TTwigCircle(Tw).C.YDot;
   Rad:=TTwigCircle(Tw).Radius;
  end;
 end;
end;

procedure TLot.SetTwigsCloseProperty(Twigs: TTwigsCollect;
  Closeprop: Integer);
var I:Integer;
begin
 For I:=0 to Coord.Count-1 do GetTwig(Twigs,I).Closed:=CloseProp;
end;

function TLot.GetGUIDStr: AnsiString;
begin
 Result:=GUIDToString(GUID);
end;

procedure TLot.SetGUIDStr(const Value: AnsiString);
begin
  GUID:=StringToGUID(Value);
end;

function TLot.DelMinOtr(TWF:TTwigsCollect;MinOtr: double): boolean;
var I:Integer;
begin
 For I:=0 to Coord.Count-1 do If GetTwig(TWF,I).DeleteMinOtr(MinOtr*100) then Result:=True;
 DelUdTwigs(TWF,MinOtr*100);
end;

function TLot.FindTwigPoint(Twigs: TTwigsCollect; Twig: TTwig): Integer;
var I:Integer;
begin
 Result:=-1;
 For I:=0 to Coord.count-1 do
  If GetTwig(Twigs,I)=Twig then begin Result:=I;exit;end;
end;

constructor TLot.LoadDB(GUID_:TGUID;Twigs:TTwigsCollect;Stream: TBufStream);
var I, Count:Integer;P:Pointer;N:ShortInt;
Procedure IndexedCoord;
var I,Index:Integer;Tw:TTwig;
begin
//пока линейный алгоритм
 For I:=0 to Coord.Count-1 do begin
  Index:=Twigs.FindTwigSpatial(Coord[I]);
  If Index=ZNULL*100 then begin // ветка не найдена
   Tw:=Coord[I];
   Twigs.Insert(Twg_Twig,Tw);
   Coord[I]:=TLong.Create((Twigs.TwigsCount-1)*ShortInt(Tw.Inv));
   Tw.Inv:=0;
  end else begin
   Tw:=Coord[I];
   Coord[I]:=TLong.Create(Index*ShortInt(Tw.Inv));
   TTwig(Twigs.TAt(Index)).Closed:=1;
   TTwig(Twigs.TAt(Index)).Inv:=0;
   Tw.Free;
  end;
 end;
end;
begin
 GUID:=GUID_;
  TaheoIndex:=-1;
  Stream.Read(What,SizeOf(What));
  Stream.Read(TaheoIndex,SizeOf(TaheoIndex));
  Stream.Read(Count,SizeOf(Count));
  Coord:=PCollection.Create(1);
  For I:=0 to Count-1 do begin
   Stream.Read(N,SizeOf(N));
   P:=Stream.Get;
   TTwig(P).Inv:=N;
   Coord.Insert(P);
  end;  // вначале считываем ветки
  // затем превращаем их в индексы
  IndexedCoord;
  //
  UZnaks:=PCollection(Stream.Get);
  DataFonts:=PCollection(Stream.Get);
  Stream.Read(ClassCode,SizeOf(ClassCode));
  Stream.Read(Closed,SizeOf(Closed));
  Stream.Read(Plo,SizeOf(Plo));
  Stream.Read(ClearPlo,SizeOf(Plo));
  Stream.Read(Ins,SizeOf(Ins));
  Stream.Read(RKF,SizeOf(RKF));
  Stream.Read(NLot,SizeOf(NLot));
  Stream.Read(TypeLot,SizeOf(TypeLot));
  Stream.Read(Copy,SizeOf(Copy));
  Stream.Read(Copy1,SizeOf(Copy1));
  Stream.Read(BaseIns,SizeOf(BaseIns));
  Fonts:=PCollection(Stream.Get);
  Lines:=PCollection(Stream.Get);
  { уникальный ID }
  UID:=Stream.StrRead;
  DataPoints:=PCollection(Stream.Get);
end;

procedure TLot.StoreDB(Twigs:TTwigsCollect;Stream: TBufStream);
var I:Integer;N:ShortInt;
begin
  Stream.Write(What,SizeOf(What));
  Stream.Write(TaheoIndex,SizeOf(TaheoIndex));
  I:=Coord.Count;
  Stream.Write(I,SizeOf(Integer));
  For I:=0 to Coord.Count-1 do begin
   If TLong(Coord[I]).Num<0 then N:=-1 else N:=1;
   Stream.Write(N,SizeOf(N));
   Stream.Put(GetTwig(Twigs,I));
  end;
  Stream.Put(UZnaks);
  Stream.Put(DataFonts);
  Stream.Write(ClassCode,SizeOf(ClassCode));
  Stream.Write(Closed,SizeOf(Closed));
  Stream.Write(Plo,SizeOf(Plo));
  Stream.Write(ClearPlo,SizeOf(Plo));
  Stream.Write(Ins,SizeOf(Ins));
  Stream.Write(RKF,SizeOf(RKF));
  Stream.Write(NLot,SizeOf(NLot));
  Stream.Write(TypeLot,SizeOf(TypeLot));
  Stream.Write(Copy,SizeOf(Copy));
  Stream.Write(Copy1,SizeOf(Copy1));
  Stream.Write(BaseIns,SizeOf(BaseIns));
  Stream.Put(Fonts);
  Stream.Put(Lines);
  Stream.StrWrite(UID);
  Stream.Put(DataPoints);
end;

//=============================================================================

function TLot.SetProperty(propName: AnsiString; propValue: AnsiString; Obj: TTD
 ): boolean;
var Tw:TTwig;PD:TPointDot;X,Y:Double;
Function sysProperty(propName:AnsiString):boolean;
begin
 Result:=(Pos('[S]',UpperCase(propName))<>0) or (Pos('[М]',UpperCase(PropName))<>0) or (Pos('[F]',UpperCase(PropName))<>0);
end;
Function GScale:Single;
var XM,XMM:Double;
begin
 Result := 1;
 {
 With Selector do begin
  XMM:=(GetDeviceCaps(GCanvas.Handle,HorzSize));
  XM:=XGeoRasst(GetDeviceCaps(GCanvas.Handle,HorzRes));
  Result:=Round(XM/XMM*1000);
      //    fmx
  end;}
end;
begin                                          
// Writeln('SetProperty for Lot = '+propName+'  '+propValue);
 If Properties=nil then  begin
  If AnsiString(PropValue) = byLayer then exit;
  Properties:=TProperties.Create;
 end;
 If sysProperty(propName) then begin
  Properties.AddProperty(propName,propValue);
 end else
 If AnsiString(PropValue) = byLayer then begin
  Properties.DeleteProperty(propName);
  Result:=True;
 // If propName='#Текстура' then If Texture<>nil then begin Texture.Free;Texture:=nil; end;
  If Properties.Count = 0 then begin Properties.Free;Properties:=nil;end;
 end else begin
  Result:=True;
  If propName ='#Текстура' then If PropValue = byLayer then Texture:=nil else Texture:=TForm2(Selector.GTwgForm).Twigs.TextureList.Add(propValue);
  If propName ='#ТекстураMX' then begin try TexX:=StrToFloat(propValue);except TexX:=1;end;TexScale:=GScale;SetProperty('#Текстура М1:',FloatToStrF(TexScale,ffFixed,_LD,1));end;
  If propName ='#ТекстураMY' then begin try TexY:=StrToFloat(propValue);except TexY:=1;end;TexScale:=GScale;SetProperty('#Текстура М1:',FloatToStrF(TexScale,ffFixed,_LD,1));end;
  If propName ='#Текстура М1:' then try TexScale:=StrToFloat(propValue);except TexScale:=500;end;
  If propName ='#Текстура угол' then try TexAngle:=StrToFloat(propValue);except TexAngle:=0;end;
  If propName ='#Прозрачность' then try Alpha:=StrToInt(propValue);except Alpha:=255;SetProperty('#Прозрачность','0');end;
  If propName ='*UID' then begin Properties.AddProperty('*UID',propValue); If UID<>nil then StrDispose(UID);UID:=StrNew(PAnsiChar(propValue));end else begin
   If GetProperty(propName) <> propValue then Properties.AddProperty(propName,propValue) else Result:=False;
  end;
 end;
end;

function TLot.GetProperty(propName:AnsiString): AnsiString;
var V:TPropValue;
begin
 If Properties<>nil then begin
  V:=Properties.PropValue[propName];
  If V=nil then Result:=byLayer else Result:=V.Value;
 end else Result:=byLayer;
end;

function TLot.GetPropValue(propName: AnsiString): Pointer;
begin
 If Properties<>nil then
  Result:=Properties.PropValue[propName] else Result:=nil;
end;

function TLot.propIndex(Index: Integer): AnsiString;
begin
 Result:=byLayer;
 If Properties = nil then exit;
 If Index<Properties.Properties.Count then begin
  If TypeLot = 1 then begin
   If TProperty(Properties.Properties.FList[Index]).propName = lpLineLotNames[Index] then
      Result:=TProperty(Properties.Properties.FList[Index]).propName;
  end else
   If TProperty(Properties.Properties.FList[Index]).propName = lpLotNames[Index] then
      Result:=TProperty(Properties.Properties.FList[Index]).propName;
 end;
end;

procedure TLot.GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);
var I:Integer;
Function AddSquareForLinear(B:Byte):boolean;          
begin
{
 If Data=nil then exit;
 TypeLot:=2;try If SetFromTwig(Data)<0 then begin TypeLot:=1;exit;end; except TypeLot:=1;exit;end;
 try
 Case B of
  0:PropNames.Add('#Площадь[лин]');
  1:PropTypes.Add('Float');
  2:begin
   SetSqwear(Data);
   PropValues.Add(FloatToStrF(Plo,ffFixed,_LD,Const_Of_DecimalSqwear));
   end;
 end;
 finally
 TypeLot:=1;
 end;
 SetSqwear(Data);
 }
end;
Function FindLayer(propName:AnsiString):boolean;
var I:Integer;Props:TProperties;
begin
 Result:=False;
 If (propName = '*Наименование') or (propName = '*Адрес (описание)') or
    (propName = '*Наименование поселения') or (propName = '*Наменование поселения') or (propName = '*ID АСУ ОДС') then exit;
 If (propName = '*Балансодержатель') and ((getProperty('*Балансодержатель')=byLayer) or ((getProperty('*Балансодержатель')='-'))) then exit; 
 ClassHandle.CreateProperties;
 try
  Props:=ClassHandle.Properties;
  For I:=0 to Props.Count-1 do
   If Props[I].propName=propName then begin
    Result:=True;
    exit;
   end;
 finally
  ClassHandle.FreeProperties;
 end;
end;
begin
{ If GlobalASUODSProps then begin
  If Properties<>nil then
   For I:=0 to Properties.Count-1 do begin
    If Pos('*',Properties[I].PropName)=1 then If FindLayer(Properties[I].PropName) then begin
     PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);
    end;
   end;
  exit;
 end;
}
  If TypeLot = 2 then begin
   PropNames.Add('Цвет');PropNames.Add('Цвет заливки');PropNames.Add('Тип линии');PropNames.Add('Тип заливки');PropNames.Add('Масштаб');PropNames.Add('Толщина');PropNames.Add('#Периметр');PropNames.Add('#Площадь');PropNames.Add('#Чистая площадь');{$IFDEF GEOPLAN}PropNames.Add('#Геоданные');PropNames.Add('#Экспликация');{$ENDIF}
   If PropTypes<>nil then begin propTypes.Add('Color');propTypes.Add('Color');propTypes.Add('LineType');propTypes.Add('SquareType');propTypes.Add('Float');propTypes.Add('Float');propTypes.Add('Float');propTypes.Add('Float');propTypes.Add('Float');{$IFDEF GEOPLAN}propTypes.Add('GeoData');propTypes.Add('Explication');{$ENDIF}end;
   If propValues<>nil then begin propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Цвет заливки'));propValues.Add(GetProperty('Тип линии'));propValues.Add(GetProperty('Тип заливки'));propValues.Add(GetProperty('Масштаб'));PropValues.Add(GetProperty('Толщина'));propValues.Add('#');propValues.Add('#');propValues.Add('#');{$IFDEF GEOPLAN}propValues.Add('#');propValues.Add('#');{$ENDIF}end;
   PropNames.Add('#Прозрачность');
   PropNames.Add('#Штриховка');PropNames.Add('#Текстура');PropNames.Add('#ТекстураMX');PropNames.Add('#ТекстураMY');PropNames.Add('#Текстура угол');PropNames.Add('#Текстура М1:');
   If PropTypes<>nil then begin PropTypes.Add('String');PropTypes.Add('Hatch');PropTypes.Add('Texture');PropTypes.Add('String');PropTypes.Add('String');PropTypes.Add('String');PropTypes.Add('String');end;
   If PropValues<>nil then begin PropValues.Add(GetProperty('#Прозрачность'));PropValues.Add(GetProperty('#Штриховка'));PropValues.Add(GetProperty('#Текстура'));PropValues.Add(GetProperty('#ТекстураMX'));PropValues.Add(GetProperty('#ТекстураMY'));PropValues.Add(GetProperty('#Текстура угол'));PropValues.Add(GetProperty('#Текстура М1:')); end;
  end else begin
   PropNames.Add('Цвет');PropNames.Add('Тип линии');PropNames.Add('Масштаб');PropNames.Add('Толщина');PropNames.Add('#Длина');AddSquareForLinear(0);{$IFDEF GEOPLAN}PropNames.Add('#Геоданные');PropNames.Add('#Экспликация');{$ENDIF}
   If propTypes<>nil then begin propTypes.Add('Color');propTypes.Add('LineType');propTypes.Add('Float');propTypes.Add('Float');propTypes.Add('Float');AddSquareForLinear(1);{$IFDEF GEOPLAN}propTypes.Add('GeoData');propTypes.Add('Explication');{$ENDIF}end;
   If propValues<>nil then begin propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Тип линии'));propValues.Add(GetProperty('Масштаб'));PropValues.Add(GetProperty('Толщина'));propValues.Add('#');AddSquareForLinear(2);{$IFDEF GEOPLAN}propValues.Add('#');propValues.Add('#');{$ENDIF}end;
  end;
  If Properties<>nil then
   For I:=0 to Properties.Count-1 do begin
    If Pos('[S]',Properties[I].PropName)<>0 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('String');propValues.Add(Properties[I].PropValue.Value); end else
    If Pos('[M]',Properties[I].PropName)<>0 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('Memo');propValues.Add(Properties[I].PropValue.Value);end else
    If Pos('[F]',Properties[I].PropName)<>0 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('Foto');propValues.Add(Properties[I].PropValue.Value);end else
    If Properties[I].PropName='*Адрес (UNOM)' then begin PropNames.Add(Properties[I].PropName);propTypes.Add('UNOM');propValues.Add(Properties[I].PropValue.Value);end else
    If Properties[I].PropName='*Фотофиксация' then begin PropNames.Add(Properties[I].PropName);propTypes.Add('ImageFile');propValues.Add(Properties[I].PropValue.Value);end else
    If Pos('*',Properties[I].PropName)=1 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('String');propValues.Add(Properties[I].PropValue.Value);end;
   end;
end;

procedure TLot.GetPropMerge(Obj:TTD;propNames,propValues,propTypes: TStrings);
var I,Index:Integer;
begin
 If propNames.Count=0 then begin
  GetObjectProps(propNames,propValues,propTypes);
 end else begin
  If (Obj is Self.ClassType) then If TLot(Obj).TypeLot = TypeLot then Exit;
 //
  If TypeLot=2 then begin
   Index:=propNames.IndexOf('Цвет');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Цвет заливки');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Тип линии');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Тип заливки');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Масштаб');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Толщина');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Периметр');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Площадь');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Чистая площадь');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Геоданные');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Экспликация');If Index<>-1 then propNames.Objects[Index]:=Self;
  end else begin
   Index:=propNames.IndexOf('Цвет');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Тип линии');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Масштаб');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('Толщина');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Длина');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Площадь');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Геоданные');If Index<>-1 then propNames.Objects[Index]:=Self;
   Index:=propNames.IndexOf('#Экспликация');If Index<>-1 then propNames.Objects[Index]:=Self;
  end;
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
 end;
end;

function TLot.DeleteTwig(Twigs: TTwigsCollect; Twig: TTwig): Boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Coord.Count-1 do If GetTwig(Twigs,I)=Twig then begin
  Result:=True;
  Coord.AtDelete(I);
  exit;
 end;
end;

function TLot.GetLayer: TResource;
begin
 Result:=ClassHandle;
end;

procedure TLot.SetLayer(PR: TResource);
begin
 ClassHandle:=PR;ClassCode:=PR.ID;
end;


function TLot.UseTriangles: boolean;
var I:Integer;
begin
 Result:=True;
 For I:=0 to Lines.Count-1 do If TObject(Lines[I]) is TTwigTriangle then exit;
 Result:=False;
end;

function TLot.UseProperty(propName: AnsiString): boolean;
begin
 Result:=False;
 If Properties<>nil then Result:=Properties.PropValue[propName]<>nil;
end;

procedure TLot.DeleteProperty(propName: AnsiString);
begin
 If Properties<>nil then Properties.DeleteProperty(propName);
end;

procedure TLot.AddProperty(propName: AnsiString);
begin
 If Properties<>nil then Properties.AddProperty(propName,'');
end;

function TLot.isClosed(Twigs: TTwigsCollect): boolean;
begin
 InsClipDotsParall(Twigs);                
  Result:=Selector.EqualPoints(Points[0],Points[Points.Count-1]);
 Points.Free;
end;

procedure TLot.RotationPoints(Col: PCollection);
var I:Integer;
begin
 For I:=0 to UZnaks.Count-1 do begin
  Col.Insert(UZnaks[I]);
 end;
 For I:=0 to Hatches.Count-1 do begin
  Col.Insert(Hatches[I].D);Col.Insert(Hatches[I].D1);
 end;
end;

procedure TLot.Move(Dx, Dy: Double);
var I:Integer;PD:TPDot;
begin
 For I:=0 to UZnaks.Count-1 do begin
  PD:=UZnaks.FList[I];
  PD.XDot:=PD.XDot+Dx;PD.YDot:=PD.YDot+Dy;
 end;
 XMax:=XMax+Dx;YMax:=YMax+Dy;XMin:=XMin+Dx;YMin:=YMin+Dy;
 Hatches.Move(Dx,Dy);
end;

procedure TLot.CreateLotsView(TWF: TTwigsCollect);
var Tw:TTwig;I:Integer;
begin
 For I:=0 to Coord.Count-1 do GetTwig(TWF,I).CreateLotsView(Self);
end;

function TLot.GetLength(TWF: TTwigsCollect): Double;
var I:Integer;
begin
Result:=0;
For I:=0 to Coord.Count-1 do Result:=Result+TTwig(TWF.TAT(TLong(Coord[I]).Num)).GetLength;
end;

function TLot.GetLinearPlo(Twigs: TTwigsCollect): Double;
begin
 TypeLot:=2;try If SetFromTwig(Twigs)<0 then exit; except TypeLot:=1;exit;end;
 SetSqwear(Twigs);
 Result:=Plo;
 TypeLot:=1;
 SetSqwear(Twigs);
end;

{ TLine }

Constructor TLine.Create;
begin
 D:=TDot.Create(XX,YY,0);D1:=TDot.Create(XX1,YY1,0);
end;

destructor TLine.Destroy;
begin
 D.Free;D1.Free;
end;

procedure TLine.Draw(Dc: hDc; Color: Integer);
var Pen:hPen;
begin
// Pen:=SelectObject(Dc,CreatePen(ps_Solid,0,Color));
//  Selector.DrawLine(X,Y,X1,Y1);
 // PTextOut(X,Y,'1'); PTextOut(X1,Y1,'2');
// DeleteObject(SelectObject(Dc,Pen));
end;

{procedure TLine.DrawTemplate(Dc: hDc; Color: Integer;);
var Pen:hPen;
begin
 Pen:=SelectObject(Dc,CreatePen(ps_Solid,0,Color));
  DrawLine(X,Y,X1,Y1);
//  PTextOut(X,Y,'1'); PTextOut(X1,Y1,'2');
 DeleteObject(SelectObject(Dc,Pen));
end;
}
function TLine.GetX: Double;
begin
 Result:=D.XDot;
end;

function TLine.GetX1: Double;
begin
 Result:=D1.XDot;
end;

function TLine.GetY: Double;
begin
 Result:=D.YDot;
end;

function TLine.GetY1: Double;
begin
 Result:=D1.YDot;
end;

constructor TLine.Load(Stream: TBufStream);
begin
 Selector:=Stream.Selector;
 D:=TDot(Stream.Get);
 D1:=TDot(Stream.Get);
end;

procedure TLine.SetX(const Value: Double);
begin
 D.XDot:=Value;
end;

procedure TLine.SetX1(const Value: Double);
begin
 D1.XDot:=Value;
end;

procedure TLine.SetY(const Value: Double);
begin
 D.YDot:=Value;
end;

procedure TLine.SetY1(const Value: Double);
begin
 D1.YDot:=Value;
end;

{ TSortDist }

type
 TDist=class(TTwgObject)
  Dist:Double;
  X,Y:Double;
  Twig:TTwig;
  Constructor Create(Dist_,X_,Y_:Double;Twig_:TTwig = nil);
 end;

type
 TSortDist=class(TSortedCollection)
  private
    function GetDist(Index:Integer): TDist;
  public
  Constructor Create(Dup:Boolean);
  Function Compare(Key1,Key2:Pointer):Integer;override;
  Property Dist[Index:Integer]:TDist read GetDist;default;
 end;

procedure TLine.Store(Stream: TBufStream);
begin
 Stream.Put(D);Stream.Put(D1);
end;

{ TDist }

constructor TDist.Create(Dist_, X_, Y_: Double;Twig_:TTwig = nil);
begin
 Dist:=Dist_;X:=X_;Y:=Y_;
 Twig:=Twig_;
end;

constructor TSortDist.Create(Dup:boolean);
begin
 inherited Create(1);
 Duplicates:=Dup;
end;

function TSortDist.Compare(Key1, Key2: Pointer): Integer;
begin
 if TDist(Key1).Dist<TDist(Key2).Dist then compare:=-1;
 if TDist(Key1).Dist=TDist(Key2).Dist then compare:=0;
 if TDist(Key1).Dist>TDist(Key2).Dist then compare:=1;
end;

function TSortDist.GetDist(Index:Integer): TDist;
begin
 Result:=At(Index);
end;

{ THatches }

constructor THatches.Create;
begin
 inherited Create(1);
 Holes:=PCollection.Create(1);
 Selector:=Selector_;
end;

destructor THatches.Destroy;
begin
 inherited;
 Holes.Free;
end;

constructor THatches.CreateAs(Hatches: THatches);
var I:Integer;J:Integer;
begin
 inherited Create(1);
 Selector:=Hatches.Selector;
 For I:=0 to Hatches.Count-1 do With TLine(Hatches[I]) do
  Insert(TLine.Create(Selector,X,Y,X1,Y1));
 Holes:=PCollection.Create(1);
 For I:=0 to Hatches.Holes.Count-1 do begin
  Holes.Insert(PCollection.Create(1));
  For J:=0 to Hatches.Hole[I].Count-1 do begin
   Hole[I].Insert(TDot.Create(TDot(Hatches.Hole[I][J]).XDot,TDot(Hatches.Hole[I][J]).YDot,100));
  end;
 end;
end;

constructor THatches.Load(Stream: TBufStream);
begin
 inherited Load(Stream);
 Selector:=Stream.Selector;
 Holes:=PCollection(Stream.Get);
 If Holes = nil then Holes:=PCollection.Create(1);
end;

procedure THatches.Store(Stream: TBufStream);
begin
 inherited Store(Stream);
 Stream.Put(Holes);
end;

Procedure THatches.Draw(Dc:hDc;Color:Integer);
var I:Integer;
begin
 For I:=0 to Count-1 do
  TLine(At(I)).Draw(Dc,Color);
end;

Procedure THatches.Move(Dx,Dy:Double);
var I:Integer;Hole:PCollection;P:TDot;
begin
 For I:=0 to Count-1 do begin
  TLine(At(I)).X:=TLine(At(I)).X+Dx;TLine(At(I)).Y:=TLine(At(I)).Y+Dy;
  TLine(At(I)).X1:=TLine(At(I)).X1+Dx;TLine(At(I)).Y1:=TLine(At(I)).Y1+Dy;
 end;
end;

function THatches.GetLine(Index:Integer):TLine;
begin
 Result:=Items[Index];
end;


procedure TLot.CreateHatch(TWF: TTwigsCollect;Hatch_:Integer = -1;Dup: boolean = True);
var I,J,Count:Integer;Dist:Double;W,H:Double;
    xb, yb:Double;
    SortDist:TSortDist;
    XMinR,YMinR:Double;
    B:Boolean;L:TLot;
    Holes:PCollection;
    MAF:TResource;
    NotUborka:boolean;
Function Intersect(X,Y,X1,Y1:Double;AddHoles:boolean):boolean;
var I:Integer;L:TLot;Prev:Integer;
Function InterWithCoord2(Lot:TLot):boolean;
var I,J:Integer;Tw:TTwig;
    D1,D2:TDot;
    xint,yint,t,o,xa,ya,xb,yb:Double;
begin
 Result:=False;
 Lot.InsClipDotsParall(TWF);
 With Lot do
 For J:=0 to Points.Count-2 do begin
   D1:=Points[J];D2:=Points[J+1]; //If EqualPoints(D1,D2) then ShowMessage('1');
   xa:=D1.XDot;ya:=D1.YDot;xb:=D2.XDot;yb:=D2.YDot;
  // DrawLine(x,y,x1,y1);
   If intersection_straight_lines( x, y, x1, y1, xa,ya,xb,yb, t, o )=1 then
    If ((RoundDblToDbl(t*Const_Of_PrecCoord*1000,0)>=0) and (RoundDblToDbl(t*Const_Of_PrecCoord*1000,0)<=Const_Of_PrecCoord*1000)
       and (RoundDblToDbl(o*Const_Of_PrecCoord*1000,0)>=0) and (RoundDblToDbl(o*Const_Of_PrecCoord*1000,0)<=Const_Of_PrecCoord*1000)) then
    If ((RoundDblToDbl(t*Const_Of_PrecCoord,0)>=0) and (RoundDblToDbl(t*Const_Of_PrecCoord,0)<=Const_Of_PrecCoord)
       and (RoundDblToDbl(o*Const_Of_PrecCoord,0)>=0) and (RoundDblToDbl(o*Const_Of_PrecCoord,0)<=Const_Of_PrecCoord)) then
     begin
      xint:=xa+(xb-xa)*t;
      yint:=ya+(yb-ya)*t;
      SortDist.Insert(TDist.Create(Distance(x,y,xint,yint),xint,yint));
     // Selector.gcANVAS.Pen.Color:=CLrED;  fmx
     // PSetPixel(xInt,yInt);
     // Writeln('Inter');readln;
      Result:=True;
     end;
  end;
 Lot.Points.Free;
end;
Function InterWithCoord(Lot:TLot):boolean;
var I,J:Integer;Tw:TTwig;
    D1,D2:TDot;
    xint,yint,t,o,xa,ya,xb,yb:Double;
begin
 Result:=False;
 With Lot do
 For I:=0 to Coord.Count-1 do begin
  Tw:=TTwig(TWF.TAt(Abs(TLong(Coord[I]).Num)));
  Tw.ArcView:=1;
  For J:=0 to Tw.Coord.Count-2 do begin //ищем пересечения
   D1:=Tw.Coord[J];D2:=Tw.Coord[J+1]; //If EqualPoints(D1,D2) then ShowMessage('1');
   xa:=D1.XDot;ya:=D1.YDot;xb:=D2.XDot;yb:=D2.YDot;
   If intersection_straight_lines( x, y, x1, y1, xa,ya,xb,yb, t, o )=1 then
   // Writeln('t=',RoundDblToDbl(t*Const_Of_PrecCoord*1000,0),' o=',RoundDblToDbl(o*Const_Of_PrecCoord*1000,0),' ',Const_Of_PrecCoord*1000);
    If ((RoundDblToDbl(t*Const_Of_PrecCoord*1000,0)>=0) and (RoundDblToDbl(t*Const_Of_PrecCoord*1000,0)<=Const_Of_PrecCoord*1000)
       and (RoundDblToDbl(o*Const_Of_PrecCoord*1000,0)>=0) and (RoundDblToDbl(o*Const_Of_PrecCoord*1000,0)<=Const_Of_PrecCoord*1000)) then
     begin
    //  Writeln('Yes!!!!','t=',RoundDblToDbl(t*Const_Of_PrecCoord*1000,0),' o=',RoundDblToDbl(o*Const_Of_PrecCoord*1000,0));
      xint:=xa+(xb-xa)*t;
      yint:=ya+(yb-ya)*t;
      SortDist.Insert(TDist.Create(Distance(x,y,xint,yint),xint,yint));
     // Selector.GCanvas.Pen.Color:=CLrED;
     // Selector.PSetPixel(xInt,yInt);
      Result:=True;
     end;
  end;
  Tw.ArcView:=0;
 end;
end;
begin
 Result:=InterWithCoord2(Self);
 Prev:=SortDist.Count;
 For I:=0 to Holes.Count-1 do begin
   Result:=InterWithCoord2(Holes[I]);
 end;
 Result:=SortDist.Count mod 2 = 0;
// Result:=SortDist.Count<>Prev;
end;
Procedure CreateVerticalHatch;
var I,J:Integer;                  
begin
 // PMoveTo(XMin+I*Dist,YMin);PLineTo(XMin+I*Dist,YMax);
 Count:=Round(W/Dist);                                    
 For I:=1 to Count+1 do begin
  SortDist:=TSortDist.Create(Dup);
  If InterSect(XMinR+I*Dist,YMin,XMinR+I*Dist,YMax,I=Count) then begin
   //PMoveTo(XMin+I*Dist,YMin);PLineTo(XMin+I*Dist,YMax);
   // вставляем в коллекцию линий резудьтаты пересечения
   For J:=0 to SortDist.Count-2 do if not odd(J) then begin
    Hatches.Insert(TLine.Create(Selector,SortDist[J].X,SortDist[J].Y,SortDist[J+1].X,SortDist[J+1].Y));
   // PMoveTo(SortDist[J].X,SortDist[J].Y);PLineTo(SortDist[J+1].X,SortDist[J+1].Y);
   end;
  end;
  SortDist.Free;
 end;                                      
end;
Procedure CreateHorizontalHatch;
var I,J:Integer;
begin
 // PMoveTo(XMin+I*Dist,YMin);PLineTo(XMin+I*Dist,YMax);
 Count:=Round(H/Dist);
 For I:=1 to Count do begin
  SortDist:=TSortDist.Create(Dup);
  If InterSect(XMin,YMinR+I*Dist,XMax,YMinR+I*Dist,I=Count) then begin
   // вставляем в коллекцию линий резудьтаты пересечения
   For J:=0 to SortDist.Count-2 do if not odd(J) then begin
    Hatches.Insert(TLine.Create(Selector,SortDist[J].X,SortDist[J].Y,SortDist[J+1].X,SortDist[J+1].Y));
   end;
  end;
 SortDist.Free;
 end;
end;
Procedure Create45Hatch(Pi4:Double);
var I,J:Integer;XC,YC:Double;X,Y,X1,Y1:Double;MinusDist:Double;
    XMinM,XMaxM:Double;
begin
// PMoveTo(XMin+I*Dist,YMin);PLineTo(XMin+I*Dist,YMax);
 XC:=(XMinR+XMax)/2;
 YC:=(YMinR+YMax)/2;
 YC:=Trunc(YC/Dist)*Dist;
 XC:=Trunc(XC/Dist)*Dist;
 X:=XC+H*cos(Pi4);
 Y:=YC-H*sin(Pi4);
 XMinM:=XMin-abs(XC-X);
 XMaxM:=XMax+abs(XC-X);
 X:=XC-H*cos(Pi4);
 Y:=YC+H*sin(Pi4);
// exit;
 Count:=Round((XMaxM-XMinM)/Dist);
 For I:=0 to Count div 2  do begin
  SortDist:=TSortDist.Create(Dup);
  If InterSect(XC+I*Dist+H*cos(Pi4),YC-H*sin(Pi4),XC+I*Dist-H*cos(Pi4),YC+H*sin(Pi4),False) then begin
   // вставляем в коллекцию линий резудьтаты пересечения
   For J:=0 to SortDist.Count-2 do if not odd(J) then begin
    Hatches.Insert(TLine.Create(Selector,SortDist[J].X,SortDist[J].Y,SortDist[J+1].X,SortDist[J+1].Y));
   end;
  end;
  SortDist.Free;
 end;
 For I:=0 to Count div 2  do begin
  SortDist:=TSortDist.Create(Dup);
  If InterSect(XC-I*Dist+H*cos(Pi4),YC-H*sin(Pi4),XC-I*Dist-H*cos(Pi4),YC+H*sin(Pi4),False) then begin
   // вставляем в коллекцию линий резудьтаты пересечения
   For J:=0 to SortDist.Count-2 do if not odd(J) then begin
    Hatches.Insert(TLine.Create(Selector,SortDist[J].X,SortDist[J].Y,SortDist[J+1].X,SortDist[J+1].Y));
   end;
  end;
  SortDist.Free;
 end;
end;
Function FoundInHoles(L1:TLot):boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Holes.Count-1 do
  If TLot(Holes[I]).LotIn(TWF,L1,True) then begin
   Result:= True;exit;
  end;
end;
begin
// WRiteln('beginLot====================');
 // размечаем линии в прямоугольнике контура
 Dist:=0.17505*csKoef;
 // расчитываем начало координат для значений XMinR и YMinR
 XMinR:=Trunc(XMin/Dist)*Dist;
 YMinR:=Trunc(YMin/Dist)*Dist;
 W:=(XMax-XMin);H:=(YMax-YMin)*2;
 Hatches.Free;Hatches:=THatches.Create(Selector);
 If Hatch_=-1 then Hatch_:=csHatch;
// ищем дырки в контурах
 Holes:=PCollection.Create(1);
 MAF:=TForm2(Selector.GTwgForm).LayerTable.LayerName['66_Штриховка_МАФ'];
 NotUborka:=(ClassHandle=TForm2(Selector.GTwgForm).LayerTable.LayerName['105_Штриховка_5-ти метровая зона']) or
            (ClassHandle=TForm2(Selector.GTwgForm).LayerTable.LayerName['77_Штриховка_тротуар без уборки']) or
            (ClassHandle=TForm2(Selector.GTwgForm).LayerTable.LayerName['106_Штриховка_выходы из жилых домов']);
// try If Round(StrToFloat(L.GetProperty('*Маф'))*1000) = 0 then MAF:=TForm2(GTwgForm).LayerTable.LayerName['66_Штриховка_МАФ'];except;
// end;
 For I:=0 to TWF.LotsCount-1 do begin
  L:=TWF.LAtIndex(I); If L = Self then continue;
//  If NotUborka and (L.ClassHandle=MAF) then continue;
  If Plo>L.Plo then
  If (L.ClassHandle.Check=1) and (L.TypeLot=2) then
//  If (L.UID<>nil) and (L.UID = '*') then
   If LotIn(TWF,L,True) then If not FoundInHoles(L) then begin
     Holes.Insert(L); // вставили ссылку
  end;
 end;
// нашли дырки - строим штриховки
 Case Hatch_ of
   0,1:Hatches.FreeAll;
   2:CreateHorizontalHatch;
   3:CreateVerticalHatch;
   6:begin CreateHorizontalHatch;CreateVerticalHatch;end;
   4:Create45Hatch(2*Pi-Pi/4);
   5:Create45Hatch(Pi/4);
   7:begin Create45Hatch(Pi/4);Create45Hatch(2*Pi-Pi/4);end;
  end;
 For I:=0 to Holes.Count-1 do begin
  L:=Holes[I];
  L.InsClipDotsParall(TWF);
  Hatches.Holes.Insert(L.Points);
 end;
 Holes.DeleteAll;Holes.Free;
// WRiteln('endLot====================');
end;

function TLot.GetLine(Index: Integer): TLine;
begin
 Result:=Hatches[Index];
end;

function THatches.GetHole(Index: Integer): PCollection;
begin
 Result:=Holes[Index];
end;

function TLot.GetUID: AnsiString;
begin
 Result:=UID;
end;

procedure TLot.SetUID(const Value: AnsiString);
begin
 If UID<>nil then StrDispose(UID);
 UID:=StrNew(PAnsiChar(Value));
end;

function TLot.GetUID1: AnsiString;
begin
 Result:=UID1;
end;

procedure TLot.SetUID1(const Value: AnsiString);
begin
 If UID1<>nil then StrDispose(UID1);
 UID1:=StrNew(PAnsiChar(Value));
end;

// Новые функции
procedure TLot.Draw32(Twf: TTwigsCollect);
const C = 100;
var Tw:TTwig;I,J:Integer;AlphaColor:Integer;
    Pen: TogsPen; Brush: TogsBrush;
    Points2: TogsCollection;
    D: Double;
Procedure DrawLine(X,Y,X1,Y1:Double);
var XX,YY,XX1,YY1:Integer; Pen: TogsPen;
begin
 With Selector do
  try
   XX:=XPix(X);YY:=YPix(Y);XX1:=XPix(X1);YY1:=YPix(Y1);
   If (XX=XX1) and (YY=YY1) then exit;
   If PointVis(X,Y) and PointVis(X1,Y1) then begin
     ogsDrawer.DrawLine(XX,YY,XX1,YY1,True);
   end else
    If Clip_Interval(GRect.Left,GRect.Bottom,Grect.Right,Grect.Top,X,Y,X1,Y1) then begin
     Drawer.DrawLine(X, Y, X1, Y1, True);
  //  Bitmap.FrameRectS(XX-2,YY-2,XX-2,YY-2);Bitmap.FrameRectS(XX1-2,YY1-2,XX1-2,YY1-2);
   end;
  except
    raise Exception.Create('Polygon Line Exception 1');
     //Image.Bitmap.Line(XPix(X),YPix(Y),XPix(X1),YPix(Y1),Image.Bitmap.PenColor,True);
     //Writeln(1);
  end;
end;
Procedure DrawTwig(Twig: TTwig);
var Ind: Integer;
    J: Integer;
    Pen: TogsPen;
    NewPen: TogsPen;
begin
// If ClassHandle.RecString = 'Фотофиксация' then
 With  Selector do
 try
   If not Twig.isVisible(GRect) then exit;
    If (ClassHandle.Standart = 1) and (GGraphSet.ViewZnaks=1) then begin
     Ind:=SearchLine(GLineCol, Twig.UZnak);
      If Ind>-1 then begin
       TGeoLine(GLineCol.At(Ind)).Layer:=Twig.ClassHandle;
       DrawGeoLine(Drawer,TGeoLine(GLineCol.At(Ind)),Twig.Coord,Twig.Koef,Twig.LineWidth ,Twig.Zdx,Inv = 1, Twig.TwigColor);
     end else
      For J:=0 to Twig.Coord.Count-2 do Drawer.DrawLine(Twig[J].XDot,Twig[J].YDot,Twig[J+1].XDot,Twig[J+1].YDot);
    end else
   If (ClassHandle.Standart = 0) and (ClassHandle.Znak = 1) then begin
     Ind:=SearchLine(GLineCol, Twig.UZnak);
      If Ind>-1 then begin
       TGeoLine(GLineCol.At(Ind)).Layer:=Twig.ClassHandle;
        DrawGeoLine(Drawer,TGeoLine(GLineCol.At(Ind)),Twig.Coord,Twig.Koef,Twig.LineWidth ,Twig.Zdx,Inv = 1, Twig.TwigColor);
     end else
      For J:=0 to Twig.Coord.Count-2 do DrawLine(Twig[J].XDot,Twig[J].YDot,Twig[J+1].XDot,Twig[J+1].YDot);
  end else
   For J:=0 to Tw.Coord.Count-2 do Drawer.DrawLine(Twig[J].XDot,Twig[J].YDot,Twig[J+1].XDot,Twig[J+1].YDot);
  // If GGraphSet.PointView = 1 then For J:=0 to Tw.Coord.Count-1 do TDot(Twig.Coord[J]).Draw32(Drawer, 0, 0, GMS, GMS);
 finally
 end;
end;
begin
 If TypeLot=254 then Exit;
 If (Closed=0) and (not Selector.GGraphSet.ShowClosed) then Exit;
// WriteIn(['sel=nil', Selector=nil]);
 //WriteIn([Selector.ActiveRect.XMin, Selector.ActiveRect.YMin, Selector.ActiveRect.XMax, Selector.ActiveRect.YMax]);
 If not isVisible(Selector.GPRect) then exit;
 //D := Properties.GetFloatValueDef('Масштаб',0.23);
 // WriteIn([ClassHandle.RecString, 'Масштаб=', D, GetProperty('Масштаб')]);
  If (TypeLot=1) then With Selector, GRect do begin// ðèñóåì ëèíåéíûé
   If Inv = 1 then Pen := Selector. Drawer.SelectPen(TogsPen.Create(TAlphaColorRec.Lime, 0, nil)) else
    Pen := Selector.Drawer.SelectPen(TogsPen.Create(LotLineColor, 0, nil));
   try
    For I:=0 to Coord.Count-1 do begin
     Tw:=GetTwig(Twf,I);
      Tw.ArcView:=1;
      DrawTwig(Tw);
     // For J:=0 to Tw.Coord.Count-2 do DrawLine(Tw[J].XDot,Tw[J].YDot,Tw[J+1].XDot,Tw[J+1].YDot);
      Tw.ArcView:=0;
    end;
   finally
    Drawer.DeletePen(Drawer.SelectPen(Pen));
   end;
  end else With Selector do begin// ðèñóåì ïëîùàäíîé
   If Alpha>0 then AlphaColor:=255-Alpha else AlphaColor:=255;
   InsClipDotsParall(Twf);
  //  Drawer.brushStyle := TBrushStyle(CsHatch);
    Brush := Drawer.SelectBrush(TogsBrush.Create(LotColor, nil));
    If Inv = 1 then Pen := Drawer.SelectPen(TogsPen.Create(TAlphaColorRec.Lime, 0, nil)) else
     Pen := Drawer.SelectPen(TogsPen.Create(LotLineColor, 0, nil));
    Points2 := TogsCollection.Create;
    try
     For I := 0 to Points.Count - 1 do With TDot(Points[I]) do
      Points2.Add(TogsDot.Create(XDot, YDot, 0));
     Drawer.drawPolygon(Points2, nil);
    finally
  //
    end;
     For I:=0 to Coord.Count-1 do begin
     Tw:=GetTwig(Twf,I);
      Tw.ArcView:=1;
       DrawTwig(Tw);
     // For J:=0 to Tw.Coord.Count-2 do DrawLine(Tw[J].XDot,Tw[J].YDot,Tw[J+1].XDot,Tw[J+1].YDot);
      Tw.ArcView:=0;
    end;
   //
    Selector.Drawer.DeletePen(Drawer.SelectPen(Pen));
    Selector.Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
   Points.Free;
 end;
end;

function TLot.GetDrawerObject: TObject;
begin
 Result := FDrawerObject;
end;

procedure TLot.SetDrawerObject(Obj: TObject);
begin
 FDrawerObject := Obj;
end;



{ TSurface }

constructor TSurface.Create(Layer_: TResource;TypeOf_, Material_: AnsiString;Index_:Integer = 0);
begin
 Layer:=Layer_;Material:=Material_;
 TypeOf:=TypeOf_;
 Index:=Index_;
end;

initialization
end.


