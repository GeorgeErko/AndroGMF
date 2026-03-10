unit newResource;
interface
Uses SysUtils,Collect,newProcs,Classes,newConsts;
Const
  ZT_Point =0;
  ZT_Line  =1;
  ZT_Sqwear=2;
const
  Ot_Twig =0;
  Ot_Fill =1;
  sdNULL = 10000000000000;
  F_It=0;                                        
  F_Bl=1;
  F_Un=2;
Const
  ClassVersion:Integer=15;
  ClassVerConst=19;
  Russian_CharSet = 100 + 1; // заглушка FMX
  Use_Lot      =0;
  Use_Field    =1;
  Use_Mark     =2;
  Char_Set:Integer = Russian_CharSet;
 Type
    TRgbRec =packed record
          ARGB:Array[1..3] of Byte
         end;
    TAttr=Array[0..2] of Byte;
    TZnakind=packed record
      LInd:SmallInt;
      SPInd:SmallInt;
    end;

Type
   TObjectTypes = Set of (otPoint,otLinear,otPolygon,otFont);
 { TExt }
 TSymbData = class (TTwgObject)
  Active:Boolean;
  sdName:String;
  sdNumber:Integer;
  sdX,sdY:Double;
  sdWidth,sdHeight:Double;
  sdIndex:Integer;
  Constructor Create(sdName_:AnsiString;sdNumber_,Index:Integer);
 end;

 TSymbology = class (TTwgObject)
  private
    function GetIndex(Index: Integer): TSymbData;
    function GetName(Index: AnsiString): TSymbData;
    function GetNumber(Index: Integer): TSymbData;
    function GetCount: Integer;
  public
   symName:AnsiString;
   P:PCollection;
   Constructor Create(symName_:AnsiString);
   Destructor Destroy;override;
   Procedure Add(Name:AnsiString;Number:Integer);
   Function SetActiveSymbologyByName(Name:AnsiString):boolean;
   Function SetActiveSymbologyByNumber(Number:Integer):boolean;
   Function SetActiveSymbologyByIndex(Index:Integer):boolean;
   Function GetActiveSymbology:TSymbData;
   Property ByName[Index:AnsiString]:TSymbData read GetName;
   Property ByIndex[Index:Integer]:TSymbData read GetIndex;default;
   Property ByNumber[Index:Integer]:TSymbData read GetNumber;
   Property Count:Integer read GetCount;
   Property ActiveSymbology:TSymbData read GetActiveSymbology;
 end;

   TResRec=record
      RGB      :TRgbRec;
      ID       :Extended;
      Rang     :Extended;
      RecString:AnsiString;
      SSInd    :SmallInt;
      ZnkInd   :TZnakInd;
      Check    :SmallInt;
     { По базе }
      NBase    :Byte;
      Hatch    :Byte;
     { Ver 6 }
      NameBase :AnsiString;
      NameMark :AnsiString;
      NameLot  :AnsiString;
     { Ver 7 отображение}
      Lot      :Byte;  { Заливка-ветви }
      Znak     :Byte;  { Условные знаки }
      Fon      :Byte;  { Непрозрачный фон }
      Marked   :Byte;  { Подписывать }
      Standart :Byte;  { Использовать все стандартные установки }
      MakeUsel :Boolean;
     {Шрифт}
      FName    :AnsiString;
      FColor   :FixedInt;
      FAttr    :TAttr;
      FH,FW    :Single;
      Page     :Byte;
      Opaque   :Boolean;
      OpColor  :FixedInt;
      OpWin    :Boolean;
     {}
      Clip:Byte;
      ConGen   :Byte;
      FRasp    :Integer;
      FDx,FDy  :Single;
     { Дочерние классы }
      Childs   :PCollection;
     {}
      Self     :Pointer;
     {}
      FontHandle:Integer; //FMX
     {}
      brTabName:AnsiString;
      brFieldName:AnsiString;
      brFieldIn:AnsiString;
      brMark:AnsiString;
     {}
      Index    :Integer;
      Indexed  :Boolean;
     {}
      LineColor:FixedInt;
     {}
      NoPerehlest:Byte;
     {Report}
      RRepName:AnsiString;
      RUse:Byte;
      RMarkIndex:Byte;
      RFieldName:AnsiString;
      RPreview:Boolean;
     {}
      isPrevStandart:Integer;
     {}
      FLock,FUnLock:Boolean;
     {}
      idLot,idQuery:boolean;
     {}
      PereFree:Boolean;
     {}
      ColorK:SmallInt;
     {подписи}
      AlwaysHor,Relation:Boolean;
     {}
      ZnakKoef:Single;
      GlassFon:boolean;
     { внешние данные}
      obStruct:AnsiString;
     {растр сверху}
      UpRastr:boolean;
     {}
      ShowAttr:boolean;
      CheckWithGroup:boolean;
      Frozen:Boolean;
     //
      ObjectTypes:TObjectTypes;
      Symbology:TSymbology;
      Resources:PCollection;
      Parent:Pointer;
     //
      LineWidth:Single;
      usedInObject:boolean;
      notClearPod:boolean;
      notClearNad:boolean;
     //
      propDicts:AnsiString;
    end;

   TBitmapRec=record
     Color,
     Fon   :FixedInt;
     Glass,
     Window,
     UsePoint:Boolean;
     UpRastr:boolean;
    end;

 Var GResRec:TResRec;

Type
 TResource=class(TTwgObject)
    RGB      :TRgbRec;
    ID       :Extended;
    Rang     :Extended;
    RecString:AnsiString;
    SSInd    :SmallInt;
    ZnkInd   :TZnakInd;
    Check    :SmallInt;
   { По базе }
    NBase    :Byte;
    Hatch    :Byte;
   { Ver 6 }
    NameBase :Array[0..25] of AnsiChar;
//  NameMark :Array[0..25] of char;
    NameMark :AnsiString;
    NameLot  :Array[0..25] of Ansichar;
   {}
    Flag:Boolean;
   {Ver 7 отображение}
    Lot      :Byte;  { Заливка-ветви }
    Znak     :Byte;  { Условные знаки }
    Fon      :Byte;  { Непрозрачный фон }
    Marked   :Byte;  { Подписывать }
    Standart :Byte;  { Использовать все стандартные установки }
    MakeUsel :Boolean;
   {}
    FName    :AnsiString;
    FColor   :FixedInt;
    FAttr    :TAttr;
    FH,FW    :Single;
    FRasp    :Integer;
    FDx,FDy  :Single;
    Opaque   :Boolean;
    OpColor  :FixedInt;
    OpWin    :Boolean;
   {}
    Page     :Byte;
   {}
    Clip     :Byte;
    ConGen   :Byte;
   { Броузер }
    brTabName:Array[0..24] of AnsiChar;
    brFieldName:Array[0..49] of AnsiChar;
    brFieldIn:Array[0..49] of AnsiChar;
    brMark:AnsiString;
   {}
    Index:Integer;
    Indexed:Boolean;
   {}
    LineColor:FixedInt;
   {}
    NoPerehlest:Byte;
   {Report}
    RRepName:AnsiString;
    RUse:Byte;
    RMarkIndex:Byte;
    RFieldName:AnsiString;
    RPreview:Boolean;
   {}
    isPrevStandart:Integer;
   {}
    FLock,FUnLock:Boolean;
   {}
    idLot,idQuery:boolean;
   {}
    PereFree:Boolean;
   {}
    ColorK:SmallInt;
   {подписи}
    AlwaysHor,Relation:Boolean;
   {}
    ZnakKoef:Single;
    GlassFon:boolean;
   {}
    obStruct:Array [0..24] of AnsiChar;
   {}
    UpRastr:Boolean;
    notClearPod:Boolean;
    notClearNad:Boolean;
    Dop:Array[0..306] of AnsiChar;
   {}
   { Дочерние классы }
    Childs   :PCollection;
    Point,Line,Sqwear:Pointer;
   {}
    FontHandle: Integer; //АЬЧ
   {}
    privDLL:Pointer; // DllLoader
   {}
    ShowAttr:boolean;
    CheckWithGroup:boolean;
    Frozen:Boolean;
   {}
    UseNObject:boolean; // используется ли объектом
   //
    ObjectTypes:TObjectTypes;
    Level:Integer; // уникальный номер слоя
    Symbology:TSymbology;
    Resources:PCollection;
    Parent:TResource;
   //
    LineWidth:Single;
    usedInObject:boolean;
   //
    propDicts:AnsiString;
    Properties:Pointer;
     Constructor  CreateNew;
     Constructor  CreateRes(F:TResRec);
     Constructor  Create(Id1:Extended;RecString1:PAnsiChar;
                         Rang1:Extended;RGB1:TRgbRec;ZType:SmallInt;
                         ZInd:TZnakInd;Check1:SmallInt;NBase1,Hatch1:Byte;N1,N2,N3:AnsiString;
                         Opaq:Boolean);
     Procedure    Restruct(F:TResRec;ResetID:boolean = True);
     Function     GetResRec:TResRec;
     Procedure    RestructBitmap(F:TBitmapRec);
     Function     GetBitmapRec:TBitmapRec;
   {}
     Constructor  Load(Stream:TBufStream);Override;
     Procedure    Store(Stream:TBufstream);Override;
     Function     FoundChild(Pr:Pointer):TResource;
     Procedure    ISetCheck(C:Boolean);
     Function     GetBrowInfo(var BName,Lot,InLot,Mark:AnsiString):Boolean;
   { Марки для внешних данных и броузера }
     Function GetOutMarks(S:TStrings):Boolean;
     Function GetBrowMarks(S:TStrings):Boolean;
     Function GetColor:Integer;
     Procedure SetColor(C:Integer);
   {}
     Function ValidReport(St:TStrings):Boolean;
   { Запрос на изменение идентификатора }
     Procedure idQueryOnUID(L,P:Pointer);
   {}
     Property DLL:Pointer read privDll write privDll;
   {}
     Destructor   Destroy;Override;
   {
     Function GetModelLayer:TLayerRec; // закрыто unit vModel;
   }
     function GetLayer(Index: Integer): TResource;
     Property Items[Index:Integer]:TResource read GetLayer;default;
     Procedure InsertLayer(PR:TResource);
   {}
     Procedure CreateProperties;
     Procedure FreeProperties;
  end;
{ Для ОДХ (работа с бортами)
var BortODH:TListByName;
    BortDT:TListByName;
}
//Function BortHandle(Handle:TResource;var BortWidth:Double;Var Material,Inter:String;DT:boolean):String;
implementation uses newProperties, TwgColle, LConvEncoding, Writer;
  { TExt }
{----------------------------------------------------------------------}
{ Методы Tresource                                                     }
{----------------------------------------------------------------------}
  Constructor TResource.CreateNew;
   begin
    FName:='';
    Flag:=True;
     Restruct(GResRec);
    Childs:=PCollection.Create(1);
    Flag:=False;
    Check:=1;
    Symbology:=nil;
    Resources:=PCollection.Create(1);
    LineWidth:=-1;
    propDicts:='Имя слоя='+RecString+#13#10+'Группа='+#13#10;
   end;
  Constructor TResource.CreateRes;
   begin
    FName:='';
    Flag:=True;
     Restruct(F);
    Flag:=False;
    Resources:=PCollection.Create(1);
   end;
  Procedure  TResource.Restruct;
   begin
    RGB      :=F.Rgb;
    If ResetID then ID:=F.ID;
    Rang     :=F.Rang;
  // If not Flag then DisposeStr(RecString);
    RecString:=F.RecString;
    SSInd  :=F.SSInd;
    ZnkInd   :=F.ZnkInd;
    Check    :=F.Check;
    NBase    :=F.NBase;
    Hatch    :=F.Hatch;
   {}
    StrPCopy(NameBase,F.NameBase);
    NameMark:=F.NameMark;
    StrPCopy(NameLot,F.NameLot);
   {}
    Lot      :=F.Lot;
    Znak     :=F.Znak;
    Fon      :=F.Fon;
    Marked   :=F.Marked;
    Standart :=F.Standart;
    MakeUsel :=F.MakeUsel;
   {}
// старое   If FName<>nil then DisposeStr(FName);
    FName    :=F.FName;
    FColor   :=F.FColor;
    FAttr    :=F.FAttr;
    FH       :=F.FH;
    FW       :=F.FW;
    Opaque   :=F.Opaque;
    OpColor  :=F.OPColor;
    OpWin    :=F.OpWin;
    Page     :=F.Page;
    Clip     :=F.Clip;
    ConGen   :=F.ConGen;
    FRasp    :=F.FRasp;
    FDx:=F.FDx;FDy:=F.FDy;
   {}
    Childs   :=F.Childs;
   {}
    StrPCopy(brTabName,F.brTabName);
    StrPCopy(brFieldName,F.brFieldName);
    StrPCopy(brFieldIn,F.brFieldIn);
    brMark:=F.brMark;
   {}
    Index    :=F.Index;
    Indexed  :=F.Indexed;
   {}
    LineColor:=F.LineColor;
   {}
    NoPerehlest:=F.NoPerehlest;
   {}
    RRepName:=F.RRepName;
    RUse:=F.RUse;
    RFieldName:=F.RFieldName;
    RMarkIndex:=F.RMarkIndex;
    RPreview:=F.RPreview;
    isPrevStandart:=F.isPrevStandart;
    FLock:=F.FLock;
    FUnLock:=F.FUnLock;
    idLot:=F.idLot;
    idQuery:=F.idQuery;
    PereFree:=F.PereFree;
    ColorK:=F.ColorK;
    Relation:=F.Relation;
    AlwaysHor:=F.AlwaysHor;
    ZnakKoef:=F.ZnakKoef;
    GlassFon:=F.GlassFon;
    StrPCopy(obStruct,F.obStruct);
    UpRastr:=F.UpRastr;
    ShowAttr:=F.ShowAttr;
    CheckWithGroup:=F.CheckWithGroup;
    ObjectTypes:=F.ObjectTypes;
    Symbology:=F.Symbology;
    Resources:=F.Resources;
    Parent:=F.Parent;
    Frozen:=F.Frozen;
   //
    LineWidth:=F.LineWidth;
    usedInObject:=F.usedInObject;
    notClearPod:=F.notClearPod;
    notClearNad:=F.notClearNad;
    propDicts:=F.propDicts;
   end;
  Function TResource.GetResRec;
  var F:TResRec;
   begin
    F.RGB      :=Rgb;
    F.ID       :=ID;
    F.Rang     :=Rang;
    F.RecString:=RecString;
    F.SSInd  :=SSInd;
    F.ZnkInd   :=ZnkInd;
    F.Check    :=Check;
    F.NBase    :=NBase;
    F.Hatch    :=Hatch;
   {}
    F.NameBase:=NameBase;
    F.NameMark:=NameMark;
    F.NameLot:=NameLot;
   {}
    F.Lot      :=Lot;
    F.Znak     :=Znak;
    F.Fon      :=Fon;
    F.Marked   :=Marked;
    F.Standart :=Standart;
    F.MakeUsel :=MakeUsel;
   {}
 //  If FName=nil then F.FName:='Arial' else
    F.FName    :=FName;
    F.FColor   :=FColor;
    F.FAttr    :=FAttr;
    F.FH       :=FH;
    F.FW       :=FW;
    F.Page     :=Page;
    F.Opaque   :=Opaque;
    F.OpColor  :=OPColor;
    F.OpWin    :=OpWin;
    F.Clip     :=Clip;
    F.ConGen   :=ConGen;
   {}
    F.FRasp    :=FRasp;
    F.FDx:=FDx;F.FDy:=FDy;
   {}
    F.Childs   :=Childs;
    F.Self     :=Self;
   {}
    F.brTabName:=brTabName;
    F.brFieldName:=brFieldName;
    F.brFieldIn:=brFieldIn;
    F.brMark:=brMark;
   {}
    F.Index    :=Index;
    F.Indexed  :=Indexed;
   {}
    F.LineColor:=LineColor;
   {}
    F.NoPerehlest:=NoPerehlest;
   {}
    F.RRepName:=RRepName;
    F.RUse:=RUse;
    F.RFieldName:=RFieldName;
    F.RMarkIndex:=RMarkIndex;
    F.RPreview:=RPreview;
   {}
    F.isPrevStandart:=isPrevStandart;
    F.FLock:=FLock;
    F.FUnLock:=FUnLock;
    F.idLot:=idLot;
    F.idQuery:=idQuery;
   {}
    F.PereFree:=PereFree;
    F.ColorK:=ColorK;
    F.Relation:=Relation;
    F.AlwaysHor:=AlwaysHor;
    F.ZnakKoef:=ZnakKoef;
    F.GlassFon:=GlassFon;
    F.obStruct:=obStruct;
    F.UpRastr:=UpRastr;
    F.ShowAttr:=ShowAttr;
    F.CheckWithGroup:=CheckWithGroup;
    F.ObjectTypes:=ObjectTypes;
    F.Symbology:=Symbology;
    F.Resources:=Resources;
    F.Parent:=Parent;
    F.Frozen:=Frozen;
   {}
    F.LineWidth:=LineWidth;
    F.usedInObject:=usedInObject;
    F.notClearPod:=notClearPod;
    F.notClearNad:=notClearNad;
    F.propDicts:=propDicts;
   {}
    Result:=F;
   end;
  Procedure  TResource.RestructBitmap;
   begin
    // цвет
    RGB.Argb[1]:=GetR(F.Color);
    RGB.Argb[2]:=GetG(F.Color);
    RGB.Argb[3]:=GetB(F.Color);
    // фон
    FColor   :=F.Fon;
    // прозрачный
    Opaque   :=F.Glass;
    // окна
    OpWin    :=F.Window;
   // использовать точки
    RUse:=ord(F.UsePoint);
    UpRastr:=F.UpRastr;
   end;
  Function TResource.GetBitmapRec;
  var F:TBitmapRec;
   begin
     // цвет
     F.Color:=RGBToCol(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]);
     // фон
     F.Fon:=FColor;
     // прозрачный
     F.Glass:=Opaque;
     // окна
     F.Window:=OpWin;
     // использовать точки
     F.UsePoint:=Boolean(RUse);
     F.UpRastr:=UpRastr;
    Result:=F;
   end;
  Constructor TResource.Create;
   begin
    ID:=Id1;
    Rgb:=Rgb1;
    RecString:=RecString1;
    Rang:=Rang1;
    SSInd:=ZType;
    ZnkInd :=ZInd;
    Check:=Check1;
    Hatch:=Hatch1;
    NBase:=NBase1;
    StrPCopy(NameBase,N1);
    StrPCopy(NameLot,N2);
    NameMark:=N3;
    Flag:=False;
    FName:='';
    FH:=4;
    FW:=2;
    Opaque:=Opaq;
    Childs:=PCollection.Create(1);
    ColorK:=0;
    LineWidth:=-1;
    propDicts:='Имя слоя='+RecString+#13#10+'Группа='+#13#10;
   end;

  Constructor TResource.Load;
   var I:Integer;
       LM: Array [0..255] of AnsiChar;
       NM :Array[0..25] of AnsiChar;
       P:PAnsiChar;S:AnsiString;
   begin
//   WriteIn(['TREsource.Load=', Stream.Position]);
    ID:=Stream.ReadExtended;
    P :=  Stream.StrRead;
    RecString:=P; StrDispose(P);
//    Writein(['Name=',RecString,'ID=',ID]);
    Rang:=Stream.ReadExtended;//(Rang,SizeOf(Rang));
    Stream.Read(RGB,SizeOf(Rgb));
    Stream.Read(SSInd,SizeOf(SSInd));
    Stream.Read(ZnkInd,SizeOf(ZnkInd));
    Stream.Read(Check,SizeOf(Check));
    Stream.Read(NBase,SizeOf(Nbase));
    Stream.Read(Hatch,SizeOf(Hatch));
  {}
   If newConsts.Version>5 then
    begin
     Stream.Read(NameBase,SizeOf(NameBase));
     StrPCopy(NameBase, AnsiToUtf8(NameBase));
     Stream.Read(NameLot,SizeOf(NameLot));
     StrPCopy(NameLot, AnsiToUtf8(NameLot[0]));
    If ClassVersion<12 then
     begin
      Stream.Read(NM,SizeOf(NM));
      NameMark:=AnsiToUtf8(NM);
     end else
      NameMark:=Stream.ReadString;
    end;
   If newConsts.Version>6 then
    begin
     Stream.Read(Lot,SizeOf(Lot));
     Stream.Read(Znak,SizeOf(Znak));
     Stream.Read(Marked,SizeOf(Marked));
     Stream.Read(Fon,SizeOf(Fon));
     Stream.Read(Standart,SizeOf(Standart));
    {}
     S:=Stream.ReadStr;
     FName:=S;
     Stream.Read(FColor,SizeOf(FColor));
     Stream.Read(FAttr,SizeOf(FAttr));
     Stream.Read(FH,SizeOf(FH));
     Stream.Read(FW,SizeOf(FW));
     Stream.Read(Page,SizeOf(Page));
     Stream.Read(Opaque,SizeOf(Opaque));
     Stream.Read(OpColor,SizeOf(OpColor));
    {}
     Stream.Read(Clip,SizeOf(Clip));
     Stream.Read(Congen,SizeOf(ConGen));
    {}
     Stream.Read(FRasp,SizeOf(FRasp));
     Stream.Read(FDx,SizeOf(FDy));
     Stream.Read(FDy,SizeOf(FDy));
    { Childs }
     //Childs:=PCollection.Create(1);
     Childs:=PCollection(Stream.Get);
     Stream.Read(MakeUsel,1);
     Stream.Read(OpWin,1);
     Stream.Read(brTabName,SizeOf(brTabName)); StrPCopy(brTabName, CP1251ToUtf8(brTabName));
     Stream.Read(brFieldName,SizeOf(brFieldName));StrPCopy(brFieldName,CP1251ToUtf8(brFieldName));
     Stream.Read(brFieldIn,SizeOf(brFieldIn));StrPCopy(brFieldIn, CP1251ToUtf8(brFieldIn));
    If ClassVersion>11 then
     brMark:=Stream.ReadString;
    {}
     Stream.Read(Index,SizeOf(Index));
     Stream.Read(Indexed,SizeOf(Indexed));
    {}
     Stream.Read(LineColor,SizeOf(LineColor));
     Stream.Read(NoPerehlest,SizeOf(Byte));
    {Report}
     if ClassVersion>13 then
      begin
       RRepName:=Stream.ReadString;
       Stream.Read(RUse,1);
       Stream.Read(RMarkIndex,1);
       RFieldName:=Stream.ReadString;
       Stream.Read(RPreview,1);
       If ClassVersion>16 then begin
        Resources:=PCollection(Stream.Get);
       end else Resources:=PCollection.Create(1);
      end;
    {}
     Stream.Read(isPrevStandart,SizeOf(isPrevStandart));
     Stream.Read(FLock,1);
     Stream.Read(FUnLock,1);
     Stream.Read(idLot,1);
     Stream.Read(idQuery,1);
     Stream.Read(PereFree,1);
     Stream.Read(ColorK,SizeOf(ColorK));
     Stream.Read(AlwaysHor,1);
     Stream.Read(Relation,1);
     Stream.Read(ZnakKoef,SizeOf(ZnakKoef));
     Stream.Read(GlassFon,SizeOf(GlassFon));
     Stream.Read(ObStruct,SizeOf(ObStruct)); StrPCopy(obStruct, CP1251ToUtf8(obStruct));
     Stream.Read(UpRastr,SizeOf(UpRastr));
     Stream.Read(ShowAttr,1);
     Stream.Read(CheckWithGroup,1);
     Stream.Read(Level,SizeOf(Level));
     Stream.Read(Frozen,1);
     Stream.Read(LineWidth,SizeOf(LineWidth));
     If (LineWidth>10) or (LineWidth<=0) then LineWidth:=-1;
     Stream.Read(notClearPod,1);
     Stream.Read(notClearNad,1);
     Stream.Read(Dop,SizeOf(Dop));
     If ClassVersion<=18 then
      propDicts:='Имя слоя='+RecString+#13#10+'Группа='+#13#10
     else propDicts:=Stream.ReadString;
    end else
    begin
     FName:='Arial';
     Standart:=1;
     FH:=4;
     FW:=2;
     Childs:=PCollection.Create(1);
     ColorK:=0;
     propDicts:='Имя слоя='+RecString+#13#10+'Группа='+#13#10;
    end;
    Flag:=False;
   end;


  Procedure TResource.Store;
   var P:PCollection;I:Integer;C:PAnsiChar;
   begin
//   Writeln('R1=',1);
    Stream.WriteExtended(Id);
    C:=StrNew(PAnsiChar(RecString));
    Stream.StrWrite(C);
    StrDispose(C);
//   Writeln('R1=',2);
    Stream.WriteExtended(Rang);
    Stream.Write   (RGB,SizeOf(Rgb));
    Stream.Write   (SSInd,SizeOf(SSInd));
    Stream.Write   (ZnkInd,SizeOf(ZnkInd));
    Stream.Write   (Check,SizeOf(Check));
    Stream.Write   (NBase,SizeOf(Nbase));
    Stream.Write   (Hatch,SizeOf(Hatch));
//   Writeln('R1=',3);
  {}
   If newConsts.Version>5 then
    begin
     Stream.Write(NameBase,SizeOf(NameBase));
     Stream.Write(NameLot,SizeOf(NameLot));
     Stream.WriteString(NameMark);
    end;
//   Writeln('R1=',4);
   If newConsts.Version>6 then
    begin
     Stream.Write(Lot,SizeOf(Lot));
     Stream.Write(Znak,SizeOf(Znak));
     Stream.Write(Marked,SizeOf(Marked));
     Stream.Write(Fon,SizeOf(Fon));
     Stream.Write(Standart,SizeOf(Standart));
    {}
     Stream.WriteStr(FName);
//   Writeln('R1=',5);
     Stream.Write(FColor,SizeOf(FColor));
     Stream.Write(FAttr,SizeOf(FAttr));
     Stream.Write(FH,SizeOf(FH));
     Stream.Write(FW,SizeOf(FW));
     Stream.Write(Page,SizeOf(Page));
     Stream.Write(Opaque,SizeOf(Opaque));
     Stream.Write(OpColor,SizeOf(OpColor));
    {}
     Stream.Write(Clip,SizeOf(Clip));
     Stream.Write(Congen,SizeOf(ConGen));
    {}
//   Writeln('R1=',6);
     Stream.Write(FRasp,SizeOf(FRasp));
     Stream.Write(FDx,SizeOf(FDy));
     Stream.Write(FDy,SizeOf(FDy));
//   Writeln('R1=',7);
    { Сохраняем ссылки }
     P:=PCollection.Create(1);
//   Writeln('R111=',Childs=nil);
     For I:=0 to Childs.Count-1 do
      begin
       Writeln(TResource(Childs[I]).ID);
       P.Insert(TExt.Create(TResource(Childs[I]).ID));
      end;
//   Writeln('R222=',1);
     Stream.Put(P);
//   Writeln('R223=',1);
    P.Free;
     Stream.Write(MakeUsel,1);
     Stream.Write(OpWin,1);
     Stream.Write(brTabName,SizeOf(brTabName));
     Stream.Write(brFieldName,SizeOf(brFieldName));
     Stream.Write(brFieldIn,SizeOf(brFieldIn));
     Stream.WriteString(brMark);
    {}
     Stream.Write(Index,SizeOf(Index));
     Stream.Write(Indexed,SizeOf(Indexed));
    {}
     Stream.Write(LineColor,SizeOf(LineColor));
     Stream.Write(NoPerehlest,SizeOf(Byte));
    {Report}
       Stream.WriteString(RRepName);
       Stream.Write(RUse,1);
       Stream.Write(RMarkIndex,1);
       Stream.WriteString(RFieldName);
       Stream.Write(RPreview,1);
//       Writeln(100);
       Stream.Put(Resources);
//   Writeln('R3=',1);
//       Writeln(101);
    {}
     Stream.Write(isPrevStandart,SizeOf(isPrevStandart));
     Stream.Write(FLock,1);
     Stream.Write(FUnLock,1);
     Stream.Write(idLot,1);
     Stream.Write(idQuery,1);
     Stream.Write(PereFree,1);
     Stream.Write(ColorK,SizeOf(ColorK));
     Stream.Write(AlwaysHor,1);
     Stream.Write(Relation,1);
     Stream.Write(ZnakKoef,SizeOf(ZnakKoef));
     Stream.Write(GlassFon,SizeOf(GlassFon));
     Stream.Write(ObStruct,SizeOf(ObStruct));
     Stream.Write(UpRastr,SizeOf(UpRastr));
     Stream.Write(ShowAttr,1);
     Stream.Write(CheckWithGroup,1);
     Stream.Write(Level,SizeOf(Level));
     Stream.Write(Frozen,1);
     Stream.Write(LineWidth,SizeOf(LineWidth));
     Stream.Write(notClearPod,1);
     Stream.Write(notClearNad,1);
     Stream.Write(Dop,SizeOf(Dop));
     Stream.WriteString(propDicts);
//   Writeln('R4=',1);
    end;
   end;
  Function TResource.FoundChild;
   var I,J:Integer;
   begin
    Result:=nil;
    For I:=0 to Childs.Count-1 do
     begin
      {ShowMessage(StrPas(TResource(Childs[I]).RecString)+'   '+StrPas(TResource(Pr).RecString));}
      If TResource(Childs[I]).Id=TResource(Pr).ID then
       begin
        Result:=Self;
        Exit;
       end;
     {Продумаем на 2 уровня}
      Result:=TResource(Childs[I]).FoundChild(Pr);
      If Result<>nil then Exit;
{       For J:=0 to TResource(Childs[I]).Childs.Count-1 do
        begin
         Result:=TResource(TResource(Childs[I]).Childs[J]).FoundChild(Pr);
         If Result then Exit;
        end;}
     end;
   end;
  Procedure TResource.ISetCheck;
   var I:Integer;
   begin
    Check:=ord(C);
    For I:=0 to Childs.Count-1 do
     begin
      If TResource(Childs[I])= Self then begin
       Writeln('Child-ID duplicate=',ID);
      end else If TResource(Childs[I]).CheckWithGroup then TResource(Childs[I]).ISetCheck(C);
     end;
   end;
  Function TResource.GetBrowInfo;
   begin
    BName:=StrPas(brTabName);
    Mark:='';
    Lot:=StrPas(brFieldName);
    InLot:=StrPas(brFieldIn);
     if (BName<>'')and(Lot<>'') then GetBrowInfo:=True;
   end;
  Function TResource.ValidReport;
   Function Make(S:AnsiString):AnsiString;
     var I:Integer;
    begin
      Result:='';
      For I:=1 to Length(S) do
       If S[I]=';' then
        Result:=Result+#13#10 else Result:=Result+S[I];
    end;
   begin
    Result:=False;
     If RRepName='' then Exit;
     St.Text:=Make(RRepName);
    Result:=True;
   end;
  Function TResource.GetOutMarks;
   var I:Integer;SS:AnsiString;
   begin
    SS:='';S.Text:='';
    For I:=1 to Length(NameMark)-1 do If NameMark[I]=';' then SS:=SS+#13#10 else SS:=SS+NameMark[I];
    S.Text:=SS;
    Result:=SS<>'';
   end;
  Function TResource.GetBrowMarks;
   var I:Integer;SS:AnsiString;
   begin
    SS:='';S.Text:='';                             
    For I:=1 to Length(brMark)-1 do If brMark[I]=';' then SS:=SS+#13#10 else SS:=SS+brMark[I];
    S.Text:=SS;
    Result:=SS<>'';
   end;
  Procedure TResource.idQueryOnUID;
   begin
   { старый код
    If IDLot then
     IDForm.GenUID else
    if IDQuery then
     begin
      IDForm.OpenWindow(L,P);
     end else GlobalID:=EmptyID;
    }
   end;
  Destructor TResource.Destroy;
   begin
  //  DisposeStr(RecString);
  // If FName<>nil then
  //  DisposeStr(FName);
    Childs.DeleteAll;
    Childs.Free;
    if Symbology<>nil then Symbology.Free;
    FreeProperties;
    Resources.DeleteAll;Resources.Free;
   end;
function TResource.GetColor: Integer;
begin
 Result:=RGBToCol(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]);
end;
procedure TResource.SetColor(C: Integer);
begin
 RGB.Argb[1]:=GetR(C);RGB.Argb[2]:=GetG(C);RGB.Argb[3]:=GetB(C);
end;
{function TResource.GetModelLayer: TLayerRec;
begin
  Result.ID:=ID;
  Result.Name:=RecString;
  Result.LayerType:=TLayerType(Trunc(Rang));
  Result.Color:=GetColor;
  Result.LineColor:=LineColor;
  Result.Visible:=Check=1;
  Result.fName:=fName^;
  Result.fColor:=fColor;
  Result.fHeight:=fH;
  Result.fWidth:=fW;
  Result.fIt:=fAttr[0];
  Result.fBl:=fAttr[1];
  Result.fUn:=fAttr[2];
 end;
}
{ TSymbology }
procedure TSymbology.Add(Name: AnsiString; Number: Integer);
begin
 P.Insert(TSymbData.Create(Name,Number,P.Count));
end;
constructor TSymbology.Create;
begin
 symName:=symName_;
 P:=PCollection.Create(1);
end;
destructor TSymbology.Destroy;
begin
 P.Free;
  inherited;
end;
function TSymbology.GetActiveSymbology: TSymbData;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to P.Count-1 do If byIndex[I].Active then begin
  Result:=P[I];exit;
 end;
end;
function TSymbology.GetCount: Integer;
begin
 Result:=P.Count;
end;
function TSymbology.GetIndex(Index: Integer): TSymbData;
begin
 Result:=P[Index];
end;
function TSymbology.GetName(Index: AnsiString): TSymbData;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to P.Count-1 do If ByIndex[I].sdName = Index then begin
  Result:=ByIndex[I];exit;
 end;
end;
function TSymbology.GetNumber(Index: Integer): TSymbData;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to P.Count-1 do If ByIndex[I].sdNumber = Index then begin
  Result:=ByIndex[I];exit;
 end;
end;
function TSymbology.SetActiveSymbologyByIndex(Index: Integer): boolean;
var I:Integer;
begin
 Result:=False;
  For I:=0 to P.Count-1 do ByIndex[I].Active:=False;
  ByIndex[Index].Active:=True;
  Result:=True;
end;
function TSymbology.SetActiveSymbologyByName(Name: AnsiString): boolean;
var I:Integer;
begin
 Result:=False;
  For I:=0 to P.Count-1 do ByIndex[I].Active:=False;
 If ByName[Name]<>nil then begin
  ByName[Name].Active:=True;
  Result:=True;
 end;
end;
function TSymbology.SetActiveSymbologyByNumber(Number: Integer): boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to P.Count-1 do ByIndex[I].Active:=False;
 If ByNumber[Number]<>nil then begin
  ByNumber[Number].Active:=True;
  Result:=True;
 end;
end;
{ TSymbData }
constructor TSymbData.Create(sdName_: AnsiString; sdNumber_,Index: Integer);
begin
 sdName:=sdName_;sdNumber:=sdNumber_;
 sdX:=sdNULL;sdY:=sdNULL;
 sdWidth:=100;sdHeight:=100;
 sdIndex:=Index
end;
function TResource.GetLayer(Index: Integer): TResource;
begin
 Result:=Resources[Index];
end;
procedure TResource.InsertLayer(PR: TResource);
begin
 PR.Parent:=Self;
 Resources.Insert(PR);
end;
{
Function BortHandle(Handle:TResource;var BortWidth:Double;Var Material,Inter:AnsiString;DT:Boolean):AnsiString;
var S:AnsiString;SN:TSectionName;
begin
 If DT then SN:=BortDT.FindByName('Бортовой камень из Гранита') else SN:=BortODH.FindByName('Бортовой камень из Гранита');
 If SN=nil then exit;
 If SN.FindParam(Handle.RecString)<>'' then begin
  Inter:='Бортовой камень из гранита [fence_granite_stone;2]';Result:=SN.FindParam(Handle.RecString);
  Material:='Гранит';
 end;
 If DT then SN:=BortDT.FindByName('Бортовой камень из Бетона') else SN:=BortODH.FindByName('Бортовой камень из Бетона');
 If SN = nil then exit;
 If SN.FindParam(Handle.RecString)<>'' then begin
  Inter:='Бортовой камень из бетона [fence_beton_stone;1]';Result:=SN.FindParam(Handle.RecString);
  Material:='Бетон';
 end;
 If DT then SN:=BortDT.FindByName('Дорожный бортовой камень') else SN:=BortODH.FindByName('Дорожный бортовой камень');
 If SN = nil then exit;
 If SN.FindParam(Handle.RecString)<>'' then begin
  Inter:='Дорожный бортовой камень [fence_road_stone;4]';Result:=SN.FindParam(Handle.RecString);
  Material:='Бетон';
 end;
 If DT then SN:=BortDT.FindByName('Садовый бортовой камень') else SN:=BortODH.FindByName('Садовый бортовой камень');
 If SN = nil then exit;
 If SN.FindParam(Handle.RecString)<>'' then begin
  Inter:='Садовый бортовой камень [fence_garden_stone;3]';Result:=SN.FindParam(Handle.RecString);
  Material:='Бетон';
 end;
exit;
 S:=AnsiUpperCase(Handle.RecString);
 BortWidth:=0.15;Material:='Бетон';Inter:='Дорожный бортовой камень [fence_road_stone;4]';
 If S = 'BORT_DOROGI_L_БР 100.30.18' then Result:='БР 100.30.15' else
 If S = 'BORT_DOROGI_L_БР 100.45.15' then Result:='БР 100.30.15' else
 If S = 'BORT_DOROGI_L_БР 100.45.18' then Result:='БР 100.30.15' else
 If S = 'BORT_DOROGI_L_БР 100.30.8' then Result:='БР 100.30.8' else
 If S = 'BORT_DOROGI_L_БР 100.30.12' then Result:='БР 100.30.12' else
 If S = 'BORT_TROTUARA_L_DOR_БР 100.30.18' then begin Result:='БР 100.30.18';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_DOR_БР 100.30.12' then begin Result:='БР 100.30.12';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_DOR_БР 100.30.8' then begin Result:='БР 100.30.8';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_DOR_БР 100.45.15' then begin Result:='БР 100.45.15';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_DOR_БР 100.45.18' then begin Result:='БР 100.45.18';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_БР 100.30.18' then begin Result:='БР 100.30.18';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_БР 100.45.15' then begin Result:='БР 100.30.15';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_БР 100.45.18' then begin Result:='БР 100.30.18';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
  If S = 'BORT_TROTUARA_L_БР 100.30.12' then begin Result:='БР 100.30.12';Inter:='  [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_БР 100.30.8' then begin Result:='БР 100.30.8';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_(100X20X8)' then begin Result:='БР 100.20.8';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_(50X20X8)' then begin Result:='БР 50.20.8';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_DOROGI_L_GRANIT_GP1' then begin Result:='1ГП'; BortWidth:=0.15;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GRANIT_GP2' then begin Result:='2ГП'; BortWidth:=0.18;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GRANIT_GP3' then begin Result:='3ГП'; BortWidth:=0.20;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GRANIT_GP4' then begin Result:='4ГП';BortWidth:=0.10;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GRANIT_GP5' then begin Result:='5ГП';BortWidth:=0.08;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GRANIT_GPV' then begin Result:='ГПВ';BortWidth:=0.08;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_DOROGI_L_GP 70-200.60.45' then begin Result:='ГПВ';BortWidth:=0.45;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GP 70-200.60.25' then begin Result:='ГПВ';BortWidth:=0.25;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GP 70-200.60.45' then begin Result:='ГПВ';BortWidth:=0.45;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP1' then begin Result:='1ГП';BortWidth:=0.15;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP2' then begin Result:='2ГП';BortWidth:=0.18;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP3' then begin Result:='3ГП';BortWidth:=0.20;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP4' then begin Result:='4ГП';BortWidth:=0.10;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP5' then begin Result:='5ГП';BortWidth:=0.08;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GPV' then begin Result:='ГПВ';BortWidth:=0.08;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L' then begin Result:='БР 100.20.8';BortWidth:=0.08;Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_SAD' then begin Result:='БР 50.20.8';BortWidth:=0.08;Inter:='Садовый бортовой камень [fence_garden_stone;3]'; end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP1_30CM' then begin Result:='1ГП';BortWidth:=0.30;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_GRANIT_GP1_40CM' then begin Result:='1ГП';BortWidth:=0.40;Material:='Гранит';Inter:='Бортовой камень из Гранита [fence_granite_stone;2]' end else
 If S = 'BORT_TROTUARA_L_БР 100.30.12' then begin Result:='БР 100.30.12';Inter:='Бортовой камень из Бетона [fence_beton_stone;1]'; end else
 If S = 'BORT_TROTUARA_L_SAD_8' then begin Result:='БР 50.20.8';BortWidth:=0.08;Inter:='Садовый бортовой камень [fence_garden_stone;3]'; end else
 If S = 'BORT_TROTUARA_L_SAD_10' then begin Result:='БР 50.20.8';BortWidth:=0.08;Inter:='Садовый бортовой камень [fence_garden_stone;3]'; end else
 Result:='';
end;
}
procedure TResource.CreateProperties;
var ST:TStrings;Props:TProperties;
begin
 FreeProperties;
 Props:=TProperties.Create;
 St:=TStringList.Create;
  St.Text:=propDicts;
  Props.GetList(St);
  Properties:=Props;
 St.Free;
end;
procedure TResource.FreeProperties;
begin
 If Properties<>nil then TObject(Properties).Free;
 Properties:=nil;
end;
initialization
finalization
end.                                
