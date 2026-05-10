Unit ecdot;
Interface uses System.Classes, Collect, TwgDraw, Lib,
               SysUtils, FMX.Graphics, newResource, newConsts, newProcs, Maths_basic, Types_dimano,
               TextManager, UserObject, ObjBlockList, Maths_Lines, newFontScale, newProperties,
               newSelector, lib2, System.UITypes, System.Types, ogcBasic;

{ Точка-семантический код = TWG_Dot  }
 Const
  TWG_Dot=0;
  TWG_Point=102;
  ZNull=1000000;
  GCountDots:Integer = 0;
 // индексы свойств для условного знака
  ppColor = 0;
  ppZnak = 1;
  ppScale = 2;
  ppAngle = 3;
  ppFont = 6;
  ppSize = 7;
  ppStyle = 8;
  ppTransp = 9;
 // для блока
  ppBlock = 0;
  ppBlockAngle = 1;
  ppStretch = 2;
  ppXKoef = 3;
  ppYKoef = 4;
 //
  ppPointNames:Array[0..9] of AnsiString = ('Цвет','Знак','Масштаб','Угол','','','Шрифт','Размер','Стиль','Прозрачность');
  ppBlockNames:Array[0..4] of AnsiString = ('Блок','Угол','Растяжение','Коэф.X(мат)','Коэф.Y(мат)');

 var
  bmpTrue,bmpFalse,bmpMiddle,bmpInactive,bmpFalsePlus:TBitmap;

 Type
   TDot=class(TTD)
     XDot,YDot:Double;
     Z:Single;
     What     :SmallInt;
      Constructor   Create(X,Y:Extended;W:SmallInt);
      Constructor   CreateZ(X,Y,Z1:Extended;W:SmallInt);
      Constructor   CreateAsDot(D:TDot);
       Constructor Load(STream:TBufStream);Override;
       Procedure   Store(STream:TBufStream);Override;
       Function      GetDist(x,y:single):single;
     {}
      Function GetPrim(R:TSect;Col:PCollection):Boolean;override;
      Function GetHint(P:Pointer=nil):AnsiString;override;
    end;

  {-------------------------}

  TPDot=Class(TDot)
     Ugol:single;
//	 Rm,Gm,Bm:byte;
     Constructor   Create (X,Y:Extended;W:SmallInt;U:single);
     Constructor   CreateAs(D:TPDot);
     constructor Load(STream:TBufStream);Override;
     Procedure Store(STream:TBufStream);Override;
     Function      GetDist(x,y:single):single;
     Procedure     Draw(DC:hDc;MXX,MYY:single;PntZnk:TSortedCollection;R,G,B:byte;Reg:TRect;KFF:Double);
  end;

  {-------------------------}
  TWorkDot=Class(TObject)
   MainIndex:LongInt;
   DotIndex:SmallInt;
   Point:TDot;
   constructor Create(N:Longint;P:SmallInt;PD:TDot);
   Function isPointDot:boolean;
   Function isTwigPoint:boolean;
   Function isDataPoint:boolean;
  end;

  {-------------------------}

  { TPointDot }

  TPointDot=class(TDot)
  private
    fSelector:TSelector;
    function GetGUIDStr: AnsiString;
    procedure SetGUIDStr(const Value: AnsiString);
  public
     ParentIndex:Integer;// индекс в коллекции точек
     TaheoIndex:SmallInt;
    { Класс }
     Code:Double;
     ClassHandle:TResource;
    {}
     R,G,B:byte;
     Ugol:Single;
    {}
     DataFonts:PCollection;
     Fonts:PCollection;
     Lines:PCollection;
    {}
     NLot :Integer;
     Ins  :Integer;
     UID  :PAnsiChar;
    { высота }
     Control:Boolean;
    {}
     Inv  :Boolean;
     SqlClosed:Boolean;
    {}
     XKoef,YKoef:Single;
    {}
     TextManager:TTextManager;
     BlockTextBitmaps:PCollection;
     GUID:TGUID;
     Symbol:ShortInt;
    {}
     userObj:TUserObject;
    {}
     Koef:Single;
     Properties:TProperties;
     Extrusion:boolean;
     Masked:Boolean;
     blockStretch:Single;
    {}
     Bind:TPDot;
     Texture:TTexture;
     TexX,TexY:Double;
     Trees:PCollection;
    {}
     BlockSect:TShortSect;
     ZnakSect:TShortSect;
     Buffer:TMemoryStream;
    {}
     Selector:TSelector;
    //
     FDrawerObject: TObject;
       Function  GetSelector:TSelector;override;
       Procedure SetSelector(S:TSelector);override;
       Constructor Create(X,Y:Extended;W:SmallInt);
       Constructor CreateAsPoint_(P:TPointDot);virtual;
       Constructor CreateAsPointDot_(P:TPointDot;AddCollections:Boolean;CreateTreesCopy:boolean=True);virtual;
       Constructor CreateZ(X,Y,Z1:Extended;C:Boolean;W:SmallInt);
       Constructor CreateTaheo(PR:TResource;TInd:Integer;Nm:AnsiString;X1,Y1,Z1:Double;FontHandle:Pointer=nil);
       Constructor CreateTaheoTextManager(PR:TResource;Znak:TPoint_Sign;Name:AnsiString;X1,Y1,Z1:Double;TI:Integer;notNumberZ:Boolean = False);
       Destructor  Destroy;Override;
       constructor Load(Stream:TBufStream);Override;
       Procedure   Store(Stream:TBufStream);Override;
    { Новая загрузка }
       Procedure   LoadNew(Stream:TBufStream);
    {}
       Function      GetDist(x,y:single):single;
       Function      isVisible:Boolean;virtual;
       Function      isVisible2:Boolean;
    {}
       Procedure     FreeDataFonts;
    {}
//      Function Hint:AnsiString;override;
       Function Closed:Boolean;
      Function isNoClosed:Boolean;
    {}
     Function GetHint(P:Pointer=nil):AnsiString;Override;
    {Захват}
     Function GetDistance(X,Y:Double;Flag:Boolean=False):Double;virtual;
     Function GetMarkedPoint(R:TSect;AllSect:Boolean):boolean;
    {Работа с подписями в знаках}
     Procedure SetActiveZnkFont(Active:byte);
     Function GetZnkFont(X,Y,Ko:Double;var What1:Integer):Integer;virtual;
     Procedure SetTextManager;
     Procedure ResetTextManager;
     Procedure CreateTextManager(Znak:TPoint_Sign = nil);
     Procedure MoveFonts(Dx,Dy:Double);
     Procedure MoveLines(Dx,Dy:Double);
    {GUID}
     Property GUIDStr:AnsiString read GetGUIDStr write SetGUIDStr;
    // блоки
     Procedure Move(Dx,Dy:Double);
     Procedure AddUserObject(obj:TUserObject);
    // свойства
     Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
     Function GetProperty(propName:AnsiString):AnsiString;override;
     Function GetPropValue(propName:AnsiString):Pointer;override;
     Function propIndex(Index:Integer):AnsiString;override;
     Function UseProperty(propName: AnsiString): boolean;override;
     Procedure DeleteProperty(propName: AnsiString);override;
     Procedure AddProperty(propName: AnsiString);
     Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
     Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
     function GetLayer: TResource;override;
     procedure SetLayer(PR: TResource);override;
     Function PointColor:Integer;
     Function GlassFont:byte;
    //
     Function LocalPointName:AnsiString;
     Function NullTextManager:boolean;
    //
     Procedure ApplyInternalProps(Obj:TTD);override;
     Function PointInSect(Sect:TSect;invertSelect:Boolean):boolean;virtual;
     Function PointInSect2(P:PCollection;invertSelect:Boolean):boolean;virtual;
     Function GetSect:TSect;virtual;
     Function ResetParams(ParamID: Integer;Params: Pointer):boolean;override;
     Procedure ChangeXYKoef(XK,YK:Double);override;
     Function isBlock:Boolean;
    //
     Function GetZnak:Integer;
    //
     Procedure CreateTrees(TreeNames:AnsiString);// создаем диапазон Trees - копии точки Self
     Procedure ReCreateTrees(TreeNames:AnsiString);// редактируем диапазон Trees
    //
     Function BlockVisible:boolean;
     Function ZnakVisible:boolean;
     Procedure renderGabarites;
   // Рисование
     Function  DrawUserObject:Boolean;
   // Габариты
     Procedure SetGabarites(MRect_:TMRect);override;
   //
     procedure Draw32(Drawer: TogsDrawer; PntZnk:TSortedCollection;FontColEx:TFontManagerEx;AlwaysShowAttr:Boolean = False);virtual;
     function GetDrawerObject: TObject; override;
     procedure SetDrawerObject(Obj: TObject); override;
  end;

  TPointMessage = class(TPointDot)
   Condition:byte;
//   Parent:TWinControl;
   userName:AnsiString;
   urlNum:AnsiString;
   EventName:AnsiString;
   EventNum:AnsiString;
   NoAnswerMsg:boolean;
   PastDate:AnsiString;
    Constructor Create(X,Y:Extended;W:SmallInt);
   //
    Constructor Load(Stream:TBufStream);Override;
    Procedure   Store(Stream:TBufStream);Override;
   //
    Function  isVisible:Boolean;override;
    Procedure ShowMessages;
    Procedure HideMessages;
  end;

type
  TPointClass = class of TPointDot;

var FTest:TextFile;
{-----------------------------------------------------------------------}
implementation uses newBlock, Polygons, WptForm2, ECText, WPTwigs, newForm0, dwgText,
                    Writer, EcDot2;
{----------------------------------------------------------------------}
{ TDot                                                                 }
{----------------------------------------------------------------------}

  Constructor  TDot.Create;
   begin
    XDot:=X;YDot:=Y;
    What:=W;
    Z:=ZNull;
   end;

  Constructor  TDot.CreateZ;
   begin
    XDot:=X;YDot:=Y;
    What:=W;
    Z:=Z1;
   end;

  Constructor  TDot.CreateAsDot;
   begin
    XDot:=D.XDot;
    YDot:=D.YDot;
    What:=D.What;
    Z:=D.Z;
   end;

  Constructor  TDot.Load;
   var XC,YC:Single;
   begin
 //   Writeln('Dotload');
    If Version<=5 then
     begin
      Stream.Read(XC,SizeOf(XC));
      Stream.Read(YC,SizeOf(YC));
      XDot:=Xc;YDot:=Yc;
     end else
     begin
      Stream.Read(XDot,SizeOf(XDot));
      Stream.Read(YDot,SizeOf(YDot));
     end;
     Stream.Read(What,SizeOf(What));
     If Version>20 then
      begin
       Stream.Read(Z,SizeOf(Z));
      end else Z:=ZNull;
//    Writeln('EndDot=',XDot,' ',YDot,' ',Z);
   end;
                                                             
  Procedure  TDot.Store;
   begin
    Stream.Write(XDot,SizeOf(XDot));
    Stream.Write(YDot,SizeOf(YDot));
    Stream.Write(What,SizeOf(What));
    Stream.Write(Z,SizeOf(Z));
   end;

 Function TDot.GetPrim;
  begin
   If (XDot>=R.Left) and (XDot<=R.Right) and
      (YDot<=R.Top) and (YDot>=R.Bottom) then
       begin
        Col.Insert(Self);
        Result:=True;
       end;
  end;

  function TDot.GetDist;
   begin
    GetDist:=sqrt(sqr(XDot-x)+sqr(YDot-y));
   end;

 Function TDot.GetHint;
   Function PN:AnsiString;
    begin
     Case What of
      0 :Result:='Простая';
      10:Result:='Узловая';
      20:Result:='Твердая';
     end;
    end;
  begin
   Result:=PN+' точка. X='+FloatToStrF(XDot,ffFixed,_LD,Const_Of_DecimalCoord)+' Y='+FloatToStrF(YDot,ffFixed,_LD,Const_Of_DecimalCoord);
  end;

{---------------------------}
  Constructor  TPDot.Create;
   begin
    XDot:=X;YDot:=Y;What:=W;Ugol:=U;
   end;

  Constructor  TPDot.Load;
   begin
  {  Stream.Read(XDot,SizeOf(XDot));
    Stream.Read(YDot,SizeOf(YDot));
    Stream.Read(What,SizeOf(What));}
    Inherited load(Stream);
    Stream.Read(Ugol,SizeOf(Ugol));
//    Ugol:=0;
   end;

  Procedure  TPDot.Store;
   begin
    Stream.Write(XDot,SizeOf(XDot));
    Stream.Write(YDot,SizeOf(YDot));
    Stream.Write(What,SizeOf(What));
    Stream.Write(Z,SizeOf(Z));
    Stream.Write(Ugol,SizeOf(Ugol));
   end;

  function TPDot.GetDist;
   begin
    GetDist:=sqrt(sqr(XDot-x)+sqr(YDot-y));
   end;

  Procedure TPDot.Draw;
  var
    PZ:TPoint_Sign;W:Integer;
   begin
     W:=SearchThis(PntZnk,(abs(What)));
     if W<>-1 then begin
      PZ:=PntZnk.At(W);
      PZ.X:=XDot;
      PZ.Y:=YDot;
      PZ.Ugol:=Ugol;
     // PZ.Draw(DC,MXX,MYY,r,g,b,0,Reg,KFF,False,False)
     end;
   end;

constructor TPDot.CreateAs(D: TPDot);
begin
 What:=D.What;
 XDot:=D.XDot;
 YDot:=D.YDot;
 What:=D.What;
 Ugol:=D.Ugol;
end;

constructor TWorkDot.Create;
begin
 MainIndex:=n;
 DotIndex:=p;
 Point:=PD;
end;

function TWorkDot.isDataPoint: boolean;
begin
 Result:=Point<>nil;
end;

function TWorkDot.isPointDot: boolean;
begin
 Result:=(Point=nil) and (DotIndex=-1);
end;

function TWorkDot.isTwigPoint: boolean;
begin
 Result:=(Point=nil) and (DotIndex<>-1);
end;

{==============}

constructor TPointDot.Create(X, Y: Extended; W: SmallInt);
begin
  Symbol:=-1;
  CreateGUID(GUID);
  inherited Create(X,Y,W);
   TaheoIndex:=-1;//GMemMakeIndex;
   DataFonts:=nil;
   Fonts:=nil;
   ClassHandle:=nil;
   Code:=-1;
   Ugol:=0;
   Ins:=-1;
   Lines:=PCollection.Create(1);
   Inv:=False;
   Z:=ZNull;
   Control:=False;
   What:=-1;
   SqlClosed:=False;
   UID:=nil;
   XKoef:=-1;YKoef:=-1;
   TextManager:=nil;
  userObj:=nil;
  TexX:=1;TexY:=1;
end;

constructor TPointDot.CreateAsPoint_(P: TPointDot);
var J:Integer;Col:PCollection;UZnak:TPoint_Sign;I:Integer;
begin
 Selector:=P.Selector;
 NLot:=P.NLot;
  CreateGUID(GUID);
  CreateZ(P.XDot,P.YDot,P.Z,P.Control,P.What);
  Code:=P.Code;
  ClassHandle:=P.ClassHandle;
  TaheoIndex:=P.TaheoIndex;
  XKoef:=P.XKoef;YKoef:=P.Ykoef;
   If P.TextManager=nil then TextManager:=nil else begin
    J:=SearchThis(Selector.GPointCol,(abs(What)));
    If J<>-1 then begin
     UZnak:=Selector.GPointCol[J];
      Col:=PCollection.Create(1);Col.Insert(UZnak);
      TextManager:=TTextManager.CreateAsTextManager(P.TextManager,Col);
      Col.DeleteAll;Col.Free;
    end;
   end;
  Symbol:=P.Symbol;
  userObj:=P.userObj;
   If P.Bind<>nil then
    Bind:=TPDot.CreateAs(P.Bind);
  Texture:=P.Texture;TexX:=P.TexX;TexY:=P.TexY;
 If P.Trees<>nil then begin
  Trees:=PCollection.Create(1);
  For I:=0 to P.Trees.Count-1 do begin
   Trees.Insert(TPointDot.CreateAsPoint_(P.Trees[I]));
  end;
 end;
 BlockSect:=P.BlockSect;
 ZnakSect:=P.ZnakSect;
 Buffer:=nil;
end;

constructor TPointDot.CreateAsPointDot_(P: TPointDot; AddCollections: Boolean;
 CreateTreesCopy: boolean);
var I,J:Integer;Col:PCollection;UZnak:TPoint_Sign;
begin
  CreateGUID(GUID);
  inherited Create(P.XDot,P.YDot,P.What);
  Selector:=P.Selector;
  NLot:=P.NLot;
  XKoef:=P.XKoef;YKoef:=P.Ykoef;
  TaheoIndex:=P.TaheoIndex;
  What:=P.What;
   if P.DataFonts=nil then DataFonts:=nil else
   If AddCollections then
    begin
     DataFonts:=PCollection.Create(1);
     For I:=0 to P.DataFonts.Count-1 do DataFonts.Insert(TEFont.CreateAsFont(P.DataFonts[I]));
    end;
   If P.Fonts=nil then Fonts:=nil else
   If AddCollections then
    begin
     Fonts:=PCollection.Create(1);
     For I:=0 to P.Fonts.Count-1 do Fonts.Insert(TEFont.CreateAsFont(P.Fonts[I]));
    end;
   Lines:=PCollection.Create(1);
   If AddCollections then
    For I:=0 to P.Lines.count-1 do
     Lines.Insert(TClassTwig.CreateAsTwig(P.Lines[I],True));
   ClassHandle:=P.ClassHandle;
   Code:=P.Code;
   Ugol:=P.Ugol;
   Ins:=P.Ins;
   Inv:=False;
   Z:=P.Z;
   Control:=P.Control;
   SqlClosed:=False;
   If P.UID<>nil then
    UID:=StrNew(P.UID) else UID:=nil;
   If P.TextManager=nil then TextManager:=nil else begin
    J:=SearchThis(Selector.GPointCol,(abs(What)));
    If J<>-1 then begin
     UZnak:=Selector.GPointCol[J];
      Col:=PCollection.Create(1);Col.Insert(UZnak);
      TextManager:=TTextManager.CreateAsTextManager(P.TextManager,Col);
      Col.DeleteAll;Col.Free;
    end;
   end;
   Symbol:=P.Symbol;
   userObj:=nil;
   userObj:=P.userObj;
   If P.Properties<>nil then Properties:=TProperties.CreateAs(P.Properties) else Properties:=nil;
 {}
   Koef:=P.Koef;
   If P.Bind<>nil then
    Bind:=TPDot.CreateAs(P.Bind);
  Texture:=P.Texture;TexX:=P.TexX;TexY:=TexY;
  If CreateTreesCopy then
   If P.Trees<>nil then begin
    Trees:=PCollection.Create(1);
    For I:=0 to P.Trees.Count-1 do begin
     Trees.Insert(TPointDot.CreateAsPointDot_(P.Trees[I],False));
    end;
  end;
  BlockSect:=P.BlockSect;
  ZnakSect:=P.ZnakSect;
  Buffer:=nil;
 end;

constructor TPointDot.CreateZ(X, Y, Z1: Extended; C: Boolean; W: SmallInt);
begin
  Symbol:=-1;
  CreateGUID(GUID);
  Create(X,Y,W);
  Z:=Z1;Control:=C;
  XKoef:=-1;YKoef:=-1;
  TextManager:=nil;
  TexX:=1;TexY:=1;
 end;

constructor TPointDot.CreateTaheo(PR: TResource; TInd: Integer; Nm: AnsiString;
 X1, Y1, Z1: Double; FontHandle: Pointer);
 var F:TEFont;S:TStrings;I:Integer;S1:AnsiString;
 Function GetHandle:TResource;
 begin
  if FontHandle=nil then Result:=ClassHandle else Result:=FontHandle;
 end;
 begin
  Symbol:=-1;
  CreateGUID(GUID);
  XKoef:=-1;YKoef:=-1;
  Create(X1,Y1,20);
  TaheoIndex:=TInd;
  If Nm<>'' then UID:=StrNew(PAnsiChar(Nm));
  If PR<>nil then begin
   ClassHandle:=PR;
   Code:=ClassHandle.ID;
  end;
  If Nm<>'' then begin
   S:=TStringList.Create;
   S1:='';
   For I:=1 to Length(Nm) do If Nm[I]='~' then S1:=S1+#13#10 else S1:=S1+Nm[I];
   S.Text:=S1;
  If PR<>nil then begin
   if S.Count>1 then begin {Writeln('Count=',S.Count);} {InsertMark(S,False)} end else begin
    F:=TEFont.CreateClass(GetHandle,0,X1{+GetHandle.fDy},Y1{+GetHandle.fDx},UID,Fnt_Taheo);
   // InsertFont(F);
   end;
  end;
   S.Free;
  end;
  Z:=Z1;
  TextManager:=nil;
 end;

destructor TPointDot.Destroy;
 begin
  Inherited Destroy;
  If TextManager<>nil then TextManager.Free;
  If BlockTextBitmaps<>nil then
   begin
    while BlockTextBitmaps.Count>0 do begin
     if TObject(BlockTextBitmaps[0])<>nil then TObject(BlockTextBitmaps[0]).Free;
     BlockTextBitmaps.AtDelete(0);
    end;
    BlockTextBitmaps.Free;
   end;
  if DataFonts<>nil then DataFonts.Free;
  if Fonts<>nil then Fonts.Free;
  If Lines<>nil then Lines.Free;
//  WriteS(['PI=',ParentIndex]);
  If Properties<>nil then Properties.Free;
  If Bind<>nil then Bind.Free;
  If Trees<>nil then Trees.Free;
 end;


function TPointDot.GetDist(x, y: single): single;
begin
  GetDist:=sqrt(sqr(XDot-x)+sqr(YDot-y));
end;

procedure TPointDot.Draw32(Drawer: TogsDrawer; PntZnk: TSortedCollection;
  FontColEx: TFontManagerEx; AlwaysShowAttr: Boolean);
Label 1;
var
    PZ:TPoint_Sign;
    x1,y1:SmallInt;
    I:Integer;
    N:Integer;
    Pen1:TogsPen;
    Brush: TogsBrush;
    RS:Double;
    Props: Pointer;
begin
// If Closed then exit;              9
 If userObj<>nil then
   If userObj.objType = TWG_Block then begin

//   GetProperty('Ðàñòÿæåíèå');
//   TGeoBlock(userObj).XText:=1;
 //  If GetProperty('Ðàñòÿæåíèå')<>byLayer then TGeoBlock(userObj).XText:=
//   try TGeoBlock(userObj).XText:=StrToFloat(S);except TGeoBlock(userObj).XText:=1;end;
   TGeoBlock(userObj).XText:=blockStretch;
 //  TGeoBlock(userObj).txtProperties:=Properties;
 //  buffer := nil;
  If BlockVisible then begin
   Props := TGeoBlock(userObj).txtProperties;
   If Properties <> nil then TGeoBlock(userObj).txtProperties := Properties;
    TGeoBlock(userObj).Draw32(Drawer,XDot,YDot,Ugol,XKoef,YKoef,Extrusion,Inv,BlockTextBitmaps);
   TGeoBlock(userObj).txtProperties := Props;
   What := 20;
   If Selector.PointVisible(XDot, YDot) then
   //inherited Draw32(Drawer, 0, 0, GMS, GMS)
  end;
  //
   If Bind<>nil then begin // ïðèâÿçêà ê çíàêó
    //Bitmap.PenColor:=clRed32;
   // DrawLine32(XDot,YDot,Bind.XDot,Bind.YDot);
   end;
  exit;
 end;// if UserObj<>nil
 If not ((Code<>-1) and (ClassHandle<>nil)) then exit;
 With Selector, GGraphSet do begin
   If userObj<>nil then begin
     If (Texture<>nil) and (fScale<=300) then
     // DrawTexture; !!!!!!!!!!!!!!!!!!!!!
    exit;
   end;
 If ViewZnaks=1 then begin
  If What=-1 then N:=-1 else N:=SearchThis(GPointCol,(abs(What)));
   If N<>-1 then PZ:=GPointCol.FList[N] else PZ:=nil;//ClassHandle.Point;
    If PZ<>nil then begin
      //If not ZnakVisible then exit;
         // óñòàíàâëèâàåì çíà÷åíèÿ äëÿ çíàêà
        if TextManager<>nil then TextManager.UpdateText(GlassFont);
         PZ.X:=XDot;PZ.Y:=YDot;PZ.Ugol:=Ugol;
         With GlobalSettings do
         If CZ then
          PZ.Draw32(Drawer,Gms,Gms,CZR,CZG,
                                       CZB,0,GPrect,Koef{ClassHandle.ZnakKoef},(GGraphSet.ShowAttributes),(TextManager<>nil)or AlwaysShowAttr,GGraphSet.PointView=1) else
          If (not Masked) then
          PZ.Draw32(Drawer,Gms,Gms,r,
                            g,b,0,GPrect,Koef{ClassHandle.ZnakKoef},(GGraphSet.ShowAttributes),(TextManager<>nil)or AlwaysShowAttr,GGraphSet.PointView=1) else
          PZ.Draw32(Drawer,Gms,Gms,255,
                            0,0,0,GPrect,Koef{ClassHandle.ZnakKoef},(GGraphSet.ShowAttributes),(TextManager<>nil)or AlwaysShowAttr,GGraphSet.PointView=1);
         if TextManager<>nil then TextManager.Restore;
     end else Goto 1;
   end else Goto 1;
      If (Bind<>nil)and (GlobalSettings.Settings.gsBinds) then begin
       // ?????? ìîæåò è íàäî îòîáðàæàòü
           If Bind<>nil then begin // ïðèâÿçêà ê çíàêó
            //Drawer.Bitmap.PenColor:=clRed32;
           // DrawLine32(XDot,YDot,Bind.XDot,Bind.YDot);
           end;
          exit;
     end else Goto 1;
      // If What<>-1 then
      If (Bind<>nil)and (GlobalSettings.Settings.gsBinds) then begin
        If Bind<>nil then begin // ïðèâÿçêà ê çíàêó
         //Drawer.Bitmap.PenColor:=clRed32;
         //DrawLine32(XDot,YDot,Bind.XDot,Bind.YDot);
        end;
      end;
    1:
    { òîëüêî â ñëó÷àå âèäèìîñòè âûâîäèì òî÷êó }
    RS:=XGeoRasst(GGraphSet.RPoint);
    If (XDot>Grect.Left-RS) and (XDot<Grect.Right+RS) and
       (YDot<Grect.Top+RS) and (YDot>Grect.Bottom-RS) then
       // inherited Draw32(Drawer,0,0,GMS,GMS);
      // PSetPixelDbl(XDot,YDot);
     // DeleteObject(SelectObject(Handle,Pen1));
    end;
end;

function TPointDot.DrawUserObject: Boolean;
var Props:TProperties;S:AnsiString;
begin
 If userObj=nil then Exit;
 If XKoef=0 then XKoef:=1;If YKoef=0 then YKoef:=1;
// Props:=TProperties.Create;
// if Properties<>nil then userObj.SetAttribs(Properties,Props);

  If userObj.objType = TWG_Block then begin
//   GetProperty('Растяжение');
//   TGeoBlock(userObj).XText:=1;
 //  If GetProperty('Растяжение')<>byLayer then TGeoBlock(userObj).XText:=
//   try TGeoBlock(userObj).XText:=StrToFloat(S);except TGeoBlock(userObj).XText:=1;end;
   TGeoBlock(userObj).XText:=blockStretch;
   TGeoBlock(userObj).txtProperties:=Properties;
  end;
{  If Buffer<>nil then begin
  If (BlockVisible) then With BlockSect do
   If(YRasst(Bottom-Top)>GGraphSet.fPntZnk) or (XRasst(Right-Left)>GGraphSet.fPntZnk) then DrawBuffer(Buffer,nil,GFontColEx);
  end else}
  If BlockVisible then
   Result:=userObj.Draw(Selector.GCanvas,XDot,YDot,Ugol,XKoef,YKoef,Extrusion,Inv);
// if Properties<>nil then userObj.ReSetAttribs(Props);
// Props.Free;
end;

function TPointDot.isVisible: Boolean;
 begin
  Result := True;
  If GlobalRender then exit;
  With Selector do
  Result:=(XDot>Grect.Left-2) and (XDot<Grect.Right+2) and
      (YDot<Grect.Top+2) and (YDot>Grect.Bottom-2);
 end;

function TPointDot.isVisible2: Boolean;
 begin
 Result := True;
 If GlobalRender then exit;
 With Selector do
  isVisible2:=(XDot>Grect.Left) and (XDot<Grect.Right) and
      (YDot<Grect.Top) and (YDot>Grect.Bottom);
 end;


procedure TPointDot.FreeDataFonts;
 begin
  If DataFonts<>nil then
   begin
    DataFonts.Free;
    DataFonts:=nil;
   end;
 end;

function TPointDot.Closed: Boolean;
 begin
  Result:=False;
  If ClassHandle=nil then Exit;
  If SqlClosed then Result:=True else
   Result:=ClassHandle.Check=0;
 end;

constructor TPointDot.Load(Stream: TBufStream);
 begin
// LoadNew(Stream);Exit;
 Selector:=Stream.Selector;
  TaheoIndex:=-1;
  If Version>18 then LoadNew(Stream) else
  begin
   Z:=ZNull;Control:=False;SqlClosed:=False;
   Inherited load(Stream);
	 Stream.Read(r,SizeOf(r));
	 Stream.Read(g,SizeOf(g));
	 Stream.Read(b,SizeOf(b));
        If Version>7 then
         begin
	  Stream.Read(Ugol,SizeOf(Ugol));
          Stream.Read(Code,SizeOf(Code));
          Fonts:=nil;
 //         Lines:=PCollection.Create(1);
         If Version>8 then
          begin
           Fonts:=PCollection(Stream.Get);
           Lines:=PCollection(Stream.Get);
            If Version>=11 then
             begin
              Stream.Read(NLot,SizeOf(NLot));
             end else
              NLot:=0;
          end;
          ClassHandle:=nil;
          If Version>12 then
           begin
            Stream.Read(Ins,SizeOf(Ins));
            DataFonts:=PCollection(Stream.Get);
             If Version>13 then
              begin
               Stream.Read(Z,SizeOf(Z));
               Stream.Read(Control,SizeOf(Control));
              end;
           end else
           begin
            Ins:=-1;
            DataFonts:=nil;
           end;
         end else
         begin
          Ugol:=0;
          Code:=-1;
          ClassHandle:=nil;
          Lines:=PCollection.Create(1);
          Fonts:=nil;
          DataFonts:=nil;
          NLot:=0;Ins:=-1;
         end;
     Inv:=False;
    end;
   end;

procedure TPointDot.LoadNew(Stream: TBufStream);
var TI:ShortInt;
 begin
  Selector:=Stream.Selector;
   CreateGUID(GUID);
//    Inc(gCountDots);Writeln('cnt=',gCountDots);
 //   Writeln(1);
  try
    TexX:=1;TexY:=1;
    SqlClosed:=False;Inv:=False;
   {}
     If Version>22 then begin
      If Version<28 then begin
       Stream.Read(TI,SizeOf(TI));TaheoIndex:=TI;
      end else Stream.Read(TaheoIndex,SizeOf(TaheoIndex))
     end else TaheoIndex:=-1;
    Stream.Read(XDot,SizeOf(XDot));
    Stream.Read(YDot,SizeOf(YDot));
    Stream.Read(What,SizeOf(What));
    Stream.Read(Ugol,SizeOf(Ugol));
    Stream.Read(Code,SizeOf(Code));
//    Writeln(2);
    Fonts:=PCollection(Stream.Get);
//    Writeln(3);
    Lines:=PCollection(Stream.Get);
//    Writeln(4);
    Stream.Read(NLot,SizeOf(NLot));
    Stream.Read(Ins,SizeOf(Ins));
//    Writeln(5,' ',Stream.Size,' ',Stream.Position);
    If GCountDots = 432 then begin
//    Writeln(111);
     Collect432:=True;
    end;
    DataFonts:=PCollection(Stream.Get);
    If GCountDots = 432 then begin
//     Writeln(111);
     Collect432:=False;
    end;
//    Writeln(6);
    Stream.Read(Z,SizeOf(Z));
    Stream.Read(Control,SizeOf(Control));
    UID:=Stream.StrRead;
//    Writeln(7);
    if Version<29 then TextManager:=nil else begin
      TextManager:=TTextManager(Stream.Get);
      If Version>36 then begin
       userObj:=TUserObject(Stream.Get);
       Stream.Read(XKoef,SizeOf(XKoef));
       Stream.Read(YKoef,SizeOf(YKoef));
       If Version>39 then begin
        Properties:=TProperties(Stream.Get);
         If Version>48 then begin
          Stream.Read(Extrusion,1);
           If Version>50 then begin
            Bind:=TPDot(Stream.Get);
            If Version>54 then begin
             Trees:=PCollection(Stream.Get);
            // If Trees<>nil then begin ShowMessage('1');end;
             If Version>55 then Stream.Read(GUID,SizeOf(TGUID));
            end;
           end;
         end;
       end;
      end;
    end;
//   Writeln(8);
   except
    MessageError('Except');
   end;
//   SetGabarites(MRect);
  end;

    procedure TPointDot.Store(Stream: TBufStream);
   begin
    Stream.Write(TaheoIndex,SizeOf(TaheoIndex));
    Stream.Write(XDot,SizeOf(XDot));
    Stream.Write(YDot,SizeOf(YDot));
    Stream.Write(What,SizeOf(What));
    Stream.Write(Ugol,SizeOf(Ugol));
    Stream.Write(Code,SizeOf(Code));
    Stream.Put(Fonts);
    Stream.Put(Lines);
    Stream.Write(NLot,SizeOf(NLot));
    Stream.Write(Ins,SizeOf(Ins));
    Stream.Put(DataFonts);
    Stream.Write(Z,SizeOf(Z));
    Stream.Write(Control,SizeOf(Control));
    Stream.StrWrite(UID);
    Stream.Put(TextManager);
    if userObj<>nil then userObj.Check:=1;
    try Stream.Put(userObj) finally if userObj<>nil then userObj.Check:=0;end;
    Stream.Write(XKoef,SizeOf(XKoef));
    Stream.Write(YKoef,SizeOf(YKoef));
    Stream.Put(Properties);
    Stream.Write(Extrusion,1);
    If VerConst>50 then begin
     Stream.Put(Bind);
     Stream.Put(Trees);
    end;
    Stream.Write(GUID,SizeOf(GUID));
   end;

  function TPointDot.isNoClosed: Boolean;
  begin
   With Selector do
   if ClassHandle<>nil then
    begin
     Result:=ClassHandle.Check=1;
    end else
     Result:=(GGraphSet.PointView=1) and (GGraphSet.TvdPoint=1);
  end;

  function TPointDot.GetHint(P: Pointer): AnsiString;
   Function GetZ:AnsiString;
    begin
     if Z=ZNull then Result:='' else
        Result:=' H='+FloatToStrF(Z,ffFixed,_LD,Const_Of_DecimalHeight);
    end;
  begin
  if UID<>nil then
   Result:='Точка. Класс='+FloatToStrF(Code,ffFixed,_LD,2)+' Легенда='+IntToStr(Symbol)+
           ' Имя='+''+ClassHandle.RecString+' ID='+UID+' X='+FloatToStrF(-YDot,ffFixed,_LD,Const_Of_DecimalCoord)+' Y='+FloatToStrF(XDot,ffFixed,_LD,Const_Of_DecimalCoord)+GetZ+' thIndex ='+IntToStr(TaheoIndex) else
   Result:='Точка. Класс='+FloatToStrF(Code,ffFixed,_LD,2)+' Легенда='+IntToStr(Symbol)+
           ' Имя='+ClassHandle.RecString+' ID '+'[Нет]'+' X='+FloatToStrF(-YDot,ffFixed,_LD,Const_Of_DecimalCoord)+' Y='+FloatToStrF(XDot,ffFixed,_LD,Const_Of_DecimalCoord)+GetZ+' thIndex ='+IntToStr(TaheoIndex)+' '+IntToStr(NLot)+' '+GUIDStr;
   Result:=Result+' Ins='+IntToStr(Ins);
  end;

function TPointDot.GetDistance(X, Y: Double; Flag: Boolean): Double;
Function Dist:Double;
 begin
  Result:=Distance(X,Y,XDot,YDot);
 end;
Function DistZnak:Double;
var PZ:TPoint_Sign;N:Integer;
 begin
  Result:=ZNull*100;
  If userObj<>nil then exit;
  With Selector do
  If GPointCol<>nil then With ClassHandle do
   begin
     N:=SearchThis(GPointCol,(abs(What)));
        If N<>-1 then
         begin
           PZ:=GPointCol.At(N);
           PZ.X:=XDot;
           PZ.Y:=YDot;
           PZ.Ugol:=Ugol;
       if TextManager<>nil then TextManager.UpdateText(GlassFont);
         //  Result:=PZ.GetDist(X,Y,Koef,TextManager<>nil{ZnakKoef});
       if TextManager<>nil then TextManager.Restore;
         end;
   end;
 end;
begin                                   
Result:=100000000;
if (Closed) then Exit;
 If (Code<>-1) and (ClassHandle<>nil) then
  begin
   If ClassHandle.Standart=0 then
    begin
     If ClassHandle.Znak=0 then Result:=Dist else Result:=DistZnak;
    end else
    begin
     If Selector.GGraphSet.ViewZnaks=1 then Result:=DistZnak else Result:=Dist;
    end;
  end else Result:=Dist;
end;

function TPointDot.GetMarkedPoint(R: TSect; AllSect: Boolean): boolean;
var P,P2:PCollection;I,J,Cnt,N:Integer;TmpUg:Double;D1,D2,D3,D4:TDot1;t,o:Double;PZ:TPoint_Sign;
Function GetMarkedZnak:boolean;
Label 1;
 var I,J:Integer;
 Function SectAsCollect:boolean;
  begin
   P2:=PCollection.Create(5);
   With R do begin
    P2.Insert(TDot.Create(Left,Top,0));P2.Insert(TDot.Create(Right,Top,0));P2.Insert(TDot.Create(Right,Bottom,0));
    P2.Insert(TDot.Create(Left,Bottom,0));P2.Insert(TDot.Create(Left,Top,0));
   end;
  end;
begin
 Result:=False;
 P:=PCollection.Create(1);
  if Selector.GPointCol<>nil then With ClassHandle do
   begin
     N:=SearchThis(Selector.GPointCol,(abs(What)));
        If N<>-1 then begin
          // PZ:=GPointCol.At(N);PZ.X:=XDot;PZ.Y:=YDot;PZ.Ugol:=Ugol;PZ.GetRealSector(P,Koef{ZnakKoef});
         end;
   end;
  if P.Count<>0 then begin
  if AllSect then begin
   Cnt:=0;
   For I:=0 to P.Count-1 do
    With TDot1(P[I]) do
     If Selector.PointInSect(XDot,YDot,R) then Inc(Cnt);
   If Cnt=P.Count then Result:=True;
  end else
  begin
   SectAsCollect;
   For I:=0 to P.Count-2 do
    begin
     D1:=P[I];D2:=P[I+1];
      For J:=0 to P2.Count-2 do
       begin
        D3:=P2[J];D4:=P2[J+1];
        if (intersection_straight_lines(D1.X,D1.Y,D2.X,D2.Y,D3.X,D3.Y,D4.X,D4.Y,t,o)=1)
            and (Round(o*Const_Of_PrecCoord)>=0) and (Round(o*Const_Of_PrecCoord)<=Const_Of_PrecCoord)
            and (Round(t*Const_Of_PrecCoord)>=0) and (Round(t*Const_Of_PrecCoord)<=Const_Of_PrecCoord) then
         begin
          Result:=True;
          Goto 1;
         end;
       end;
    end;
   1:
   P2.Free;
  end;
 end;
 P.Free;
end;
begin
 Result:=False;
 If Closed then Exit;
 If (Code<>-1) and (ClassHandle<>nil) then
  begin
   If ClassHandle.Standart=0 then
    begin
     If ClassHandle.Znak=0 then Result:=Selector.PointInSect(XDot,YDot,R) else Result:=GetMarkedZnak;
    end else
    begin
     If Selector.GGraphSet.ViewZnaks=1 then Result:=GetMarkedZnak else Result:=Selector.PointInSect(XDot,YDot,R);
    end;
  end else Result:=Selector.PointInSect(XDot,YDot,R);
end;


procedure TPointDot.SetActiveZnkFont(Active: byte);
var I,J,N:Integer;PZ:TPoint_Sign;
begin
With Selector do
if GPointCol<>nil then With ClassHandle do
 begin
  N:=SearchThis(GPointCol,(abs(What)));
   If N<>-1 then begin
      PZ:=GPointCol.At(N);
    //  PZ.SetActiveFont(Active);
    end;
 end;
end;

function TPointDot.GetZnkFont(X,Y,Ko:Double;var What1:Integer): Integer;
var N,Res:Integer;PZ:TPoint_Sign;
begin
Result:=-1;
With Selector do
if TextManager=nil then begin
  N:=SearchThis(GPointCol,(abs(What)));
   If N<>-1 then begin
     PZ:=GPointCol.At(N);
     PZ.X:=XDot;PZ.Y:=YDot;PZ.Ugol:=Ugol;
    // If PZ.useFont then begin
     // If (PZ.GetDist(X,Y,Koef)=0) then Result:=100;
    // endж
   end;
 exit;
end;
With Selector do
if GPointCol<>nil then With ClassHandle do
 begin
  N:=SearchThis(GPointCol,(abs(What)));
   If N<>-1 then begin
     PZ:=GPointCol.At(N);
     PZ.X:=XDot;PZ.Y:=YDot;PZ.Ugol:=Ugol;
//   Writeln('GetZnkFont=',1);
    If (PZ.UseFont) then  {If (PZ.GetDist(X,Y,Koef)=0) then} begin
     Result:=100;
    end;
//   Writeln('GetZnkFont=',2);
     SetTextManager;
//   Writeln('GetZnkFont=',3);
    //  try Res:=TextManager.GetFontIndex(PZ.GetFont(X,Y,Koef,What1));except TextManager:=nil;exit;end;
//   Writeln('GetZnkFont=',4,' ',Res,' ',Result);
     ReSetTextManager;
     If (Res = -1) and (Result = 100) then Result:=-1 else Result:=Res;
   end;
 end;
end;

procedure TPointDot.ResetTextManager;
begin
 if TextManager<>nil then TextManager.Restore;
end;

procedure TPointDot.SetTextManager;
begin
 if TextManager<>nil then TextManager.UpdateText(GlassFont);
end;

procedure TPointDot.MoveFonts(Dx, Dy: Double);
var F:TEFont;I:Integer;
begin
 If Fonts<>nil then
 For I:=0 to Fonts.Count-1 do begin
  F:=Fonts[I];
  F.XF:=F.XF+Dx;F.YF:=F.YF+Dy;
 end;
 If DataFonts<>nil then
 For I:=0 to DataFonts.Count-1 do begin
  F:=DataFonts[I];
  F.XF:=F.XF+Dx;F.YF:=F.YF+Dy;
 end;
end;

procedure TPointDot.CreateTextManager(Znak: TPoint_Sign);
var P:PCollection;DT:TDwg_Text;I:Integer;
    N:Integer;PZ:TPoint_Sign;
begin
 if ClassHandle=nil then exit;
 if Znak=nil then begin
  P:=PCollection.Create(1);
  N:=SearchThis(Selector.GPointCol,(abs(What)));
   If N<>-1 then begin
     PZ:=Selector.GPointCol.At(N);
    P.Insert(PZ);
    TextManager:=TTextManager.Create;
    TextManager.SetZnaks(P);
   end;
  P.DeleteAll;P.Free;
 end else
 If Znak<>nil then begin
  P:=PCollection.Create(1);P.Insert(Znak);
  TextManager:=TTextManager.Create;        
  TextManager.SetZnaks(P);
  P.DeleteAll;P.Free;
 end;
end;

function TPointDot.GetGUIDStr: AnsiString;
begin
 Result:=GUIDToString(GUID);
end;

procedure TPointDot.SetGUIDStr(const Value: AnsiString);
begin
 GUID:=StringToGUID(Value);
end;

procedure TPointDot.Move(Dx, Dy: Double);
begin
 MoveFonts(Dx,Dy);
 MoveLines(Dx,Dy);
 XDot:=XDot+Dx;YDot:=YDot+Dy;
 If userObj<>nil then userObj.Move(Dx,Dy,0);
end;

procedure TPointDot.MoveLines(Dx, Dy: Double);
var I:Integer;Tw:TTwig;
begin
 If Lines=nil then Exit;
 For I:=0 to Lines.Count-1 do begin
  Tw:=Lines[I];
  Tw.Move(Dx,Dy);
 end;
end;

procedure TPointDot.AddUserObject(obj: TUserObject);
begin
 If userObj<>nil then userObj.Free;
 userObj:=obj;
end;

//=============================================================================

function TPointDot.SetProperty(propName: AnsiString; propValue: AnsiString;Obj:TTD = nil):boolean;
label 1;
var Angle, W, H:Double;
begin
// Writeln('SetProperty for Point = '+propName+'  '+propValue);
{
 if UserObj <> nil then begin
  If UserObj.objType = TWG_Block then begin
   userObj.SetProperty(propName,propValue,Obj);
  end;
  exit;
 end;
}
 If PropName = 'Угол' then begin Ugol:=StrToFloat(propValue)*Pi/180;Result:=True;exit;end;
 If UserObj<>nil then begin
  If UserObj.objType = TWG_Block then begin
   If propName ='#Изображение' then If PropValue = byLayer then  Texture:=nil else Texture:=TForm2(Selector.GTwgForm).Twigs.TextureList.Add(propValue);
   If propName ='#ИзображениеMX' then try TexX:=StrToFloat(propValue);except TexX:=1;end;
   If propName ='#ИзображениеМY' then try TexY:=StrToFloat(propValue); except TexY:=1;end;
   If propName = 'Коэф.X(мат)' then XKoef:=StrToFloat(propValue) else
   If propName = 'Коэф.Y(мат)' then YKoef:=StrToFloat(propValue) else
   If propName = 'Блок' then begin
{    userObj:=TGeoBlock.CreateAsUserObject(userObj);
    TGeoBlock(userObj).TwgForm.Free;TGeoBlock(userObj).TwgForm:=nil;
    TGeoBlock(userObj).Name:=propValue;}
    userObj:=TGeoBlock.Create(nil,nil);
  //  TGeoBlock(userObj).TwgForm.Free;TGeoBlock(userObj).TwgForm:=nil;
    TGeoBlock(userObj).Name:=propValue;
   end else
   {If propName = 'Растяжение' then }Goto 1;
   Result:=True;
   exit;
  end;
 end;
 If Pos('##',PropName) = 1 then begin
  If PropValue = byLayer then propValue:='';
  If Obj = nil then TextManager.SetAttrValue(DelSubStr(propName,'##'),propValue) else
  If (Obj is TPointDot) and (TPointDot(Obj).TextManager<>nil) then begin
   If TPointDot(Obj).TextManager.GetAttrParams(DelSubStr(propName,'##'),Angle,W,H) then begin
     TextManager.SetAttrParams(DelSubStr(propName,'##'),Angle,W,H);
   end;
  end;
  Result:=True;
  exit;
 end;
1:If Properties=nil then  begin
  If AnsiString(PropValue) = byLayer then exit;
  Properties:=TProperties.Create;
 end;
 If AnsiString(PropValue) = byLayer then begin
  Properties.DeleteProperty(propName);
  Result:=True;
  If Properties.Count = 0 then begin Properties.Free;Properties:=nil;end;
 end else begin
  Result:=True;
  If AnsiString(GetProperty(propName)) <> AnsiString(propValue) then begin
   Properties.AddProperty(propName,propValue);
   If (propName = 'Масштаб') and (propValue<>byNone) and (propValue<>byLayer) then begin
    XKoef:=GStrToFloat(propValue);YKoef:=GStrToFloat(propValue);
   end;
  If propName ='#Изображение' then If PropValue = byLayer then  Texture:=nil else Texture:=TForm2(Selector.GTwgForm).Twigs.TextureList.Add(propValue);
  If propName ='#ИзображениеMX' then try TexX:=StrToFloat(propValue);except TexX:=1;end;
  If propName ='#ИзображениеМY' then try TexY:=StrToFloat(propValue); except TexY:=1;end;
  end else Result:=False;
 end;
end;

procedure TPointDot.SetSelector(S: TSelector);
begin
 fSelector:=S;
end;

function TPointDot.GetProperty(propName:AnsiString): AnsiString;
var V:TPropValue;I:Integer;Res:AnsiString;
begin
 If Properties<>nil then begin
  V:=Properties.PropValue[propName];
  If (V=nil) then begin
   Result:=byLayer;
  // ищем в TextManager
  Res:='';
   If (Pos('##',PropName)=1) and (TextManager<>nil) then begin
    Res:=TextManager.AttrValue(DelSubStr(propName,'##'));
    If Res<>'' then begin Result:=Res;exit;end;
   end;
   If PropName = 'Угол' then Result:=FloatToStrF(Ugol*180/Pi,ffFixed,_LD,1);
   If UserObj<>nil then begin
    If propName = 'Коэф.X(мат)' then Result:=FloatToStrF(XKoef,ffFixed,_LD,2) else
    If propName = 'Коэф.Y(мат)' then Result:=FloatToStrF(YKoef,ffFixed,_LD,2) else
    If propName = 'Блок' then Result:=TGeoBlock(userObj).Name;
   end;
  end else begin
   Result:=V.Value;
  end;
 end else begin
  Result:=byNone;
   If PropName = 'Угол' then
    Result:=FloatToStrF(Ugol*180/Pi,ffFixed,_LD,1);
   If UserObj<>nil then begin
    If propName = 'Коэф.X(мат)' then Result:=FloatToStrF(XKoef,ffFixed,_LD,2) else
    If propName = 'Коэф.Y(мат)' then Result:=FloatToStrF(YKoef,ffFixed,_LD,2) else
    If propName = 'Блок' then  Result:=TGeoBlock(userObj).Name;
   end;
 end;
//Writeln(FTest,propName,'-----------------------end');
end;

function TPointDot.GetPropValue(propName: AnsiString): Pointer;
begin
 If Properties<>nil then
  Result:=Properties.PropValue[propName] else Result:=nil;
end;

function TPointDot.propIndex(Index: Integer): AnsiString;
begin
 Result:=byLayer;
 If Properties = nil then exit;
 If Index<Properties.Properties.Count then begin
  If userObj<>nil then begin
   If TProperty(Properties.Properties.FList[Index]).propName = ppBlockNames[Index] then
      Result:=TProperty(Properties.Properties.FList[Index]).propName;
  end else
   If TProperty(Properties.Properties.FList[Index]).propName = ppPointNames[Index] then
      Result:=TProperty(Properties.Properties.FList[Index]).propName;
 end;
end;

procedure TPointDot.GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);
var tmNames,tmValues:TStrings;I:Integer;
    Value:TPropValue;
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
  If TextManager<>nil then begin
    tmNames:=TStringList.Create;tmValues:=TStringList.Create;
    TextManager.GetAttrNames(tmNames,tmValues);
    For I:=0 to tmNames.Count-1 do begin
     propNames.Add('##'+tmNames[I]);propTypes.Add('AnsiString');propValues.Add(tmValues[I]);
    end;
   tmNames.Free;tmValues.Free;
  end;
  If Properties<>nil then
   For I:=0 to Properties.Count-1 do begin
    If (Pos('*',Properties[I].PropName)=1) then If FindLayer(Properties[I].PropName) then begin
     PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);
    end;
   end;
  exit;
 end;
}
 if UserObj <> nil then begin
  If UserObj.objType = TWG_Block then begin
    PropNames.Add('Блок');
    PropNames.Add('Угол');PropNames.Add('Растяжение');PropNames.Add('Коэф.X(мат)');PropNames.Add('Коэф.Y(мат)');
    PropTypes.Add('Block');PropTypes.Add('Float');PropTypes.Add('Float');PropTypes.Add('Float');PropTypes.Add('Float');
    PropValues.Add(GetProperty('Блок'));
    PropValues.Add(GetProperty('Угол'));
    PropValues.Add(GetProperty('Растяжение'));
    PropValues.Add(FloatToStrF(XKoef,ffFixed,_LD,2));
    PropValues.Add(FloatToStrF(YKoef,ffFixed,_LD,2));
    TGeoBlock(userObj).txtProperties:=Properties;
    userObj.GetObjectProps(propNames,propValues,propTypes);
   {If Properties=nil then begin
    Properties:=TProperties.Create;
    For I:=0 to propNames.Count-1 do If (propNames[I]<>'Угол')and(propNames[I]<>'Блок') then Properties.AddProperty(propNames[I],propValues[I]);
   end else
   For I:=0 to propNames.Count-1 do If propNames[I]<>'Угол' then begin
    Value:=Properties.PropValue[propNames[I]];
    If Value<>nil then begin propValues[I]:=Value.Value;end;
   end;}
  end;
  If Properties<>nil then
   For I:=0 to Properties.Count-1 do begin
    If (Pos('#',Properties[I].PropName)=1) and (Pos('#Изо',Properties[I].PropName)=0) then begin PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);end;
   end;
  If Properties<>nil then
   For I:=0 to Properties.Count-1 do begin
    If Pos('*',Properties[I].PropName)=1 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);end;
   end;
// Изображение
 propNames.Add('#Изображение');propTypes.Add('Texture');propValues.Add(GetProperty('#Изображение'));
 propNames.Add('#ИзображениеMX');propTypes.Add('AnsiString');propValues.Add(GetProperty('#ИзображениеMX'));
 propNames.Add('#ИзображениеМY');propTypes.Add('AnsiString');propValues.Add(GetProperty('#ИзображениеМY'));
//
  exit;
 end;
 tmNames:=nil;
 PropNames.Add('Цвет');PropNames.Add('Знак');PropNames.Add('Масштаб');PropNames.Add('Угол');{$IFDEF GEOPLAN}PropNames.Add('#Геоданные');PropNames.Add('#Экспликация');{$ENDIF}
 If TextManager<>nil then begin PropNames.Add('Шрифт');PropNames.Add('Размер');PropNames.Add('Стиль');PropNames.Add('Прозрачность');end;
  If PropTypes<>nil then begin propTypes.Add('Color');propTypes.Add('PointType');propTypes.Add('Float');propTypes.Add('Float');{$IFDEF GEOPLAN}propTypes.Add('GeoData');propTypes.Add('Explication');{$ENDIF}
   If TextManager<>nil then begin
    propTypes.Add('FontName');propTypes.Add('Float');propTypes.Add('FontStyle');propTypes.Add('Boolean');
    tmNames:=TStringList.Create;tmValues:=TStringList.Create;
    TextManager.GetAttrNames(tmNames,tmValues);
    For I:=0 to tmNames.Count-1 do begin
     propNames.Add('##'+tmNames[I]);propTypes.Add('AnsiString');
    end;
   end;
  end;
  If propValues<>nil then begin propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Знак'));propValues.Add(GetProperty('Масштаб'));propValues.Add(GetProperty('Угол'));{$IFDEF GEOPLAN}propValues.Add('#');propValues.Add('#');{$ENDIF}
   If TextManager<>nil then begin
    propValues.Add(GetProperty('Шрифт'));propValues.Add(GetProperty('Размер'));propValues.Add(GetProperty('Стиль'));propValues.Add(GetProperty('Прозрачность'));
    For I:=0 to tmNames.Count-1 do propValues.Add(tmValues[I]);
   end;
  end;
// Изображение
 propNames.Add('#Изображение');propTypes.Add('Texture');propValues.Add(GetProperty('#Изображение'));
 propNames.Add('#ИзображениеMX');propTypes.Add('AnsiString');propValues.Add(GetProperty('#ИзображениеMX'));
 propNames.Add('#ИзображениеМY');propTypes.Add('AnsiString');propValues.Add(GetProperty('#ИзображениеМY'));
//
 If tmNames<>nil then begin tmNames.Free;tmValues.Free;end;
 If Properties<>nil then
  For I:=0 to Properties.Count-1 do begin
   If Pos('*',Properties[I].PropName)=1 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);end;
  end;
end;

procedure TPointDot.GetPropMerge(Obj:TTD;propNames,propValues,propTypes: TStrings);
var I,Index:Integer;Names,Values,Types:TStrings;
begin
 if UserObj <> nil then begin
  If UserObj.objType = TWG_Block then begin
   userObj.GetPropMerge(Obj,propNames,propValues,propTypes);
  Names:=TStringList.Create;Values:=TStringList.Create;Types:=TStringList.Create;
  GetObjectProps(Names,Values,Types);
  For I:=0 to Names.Count-1 do begin
   Index:=propNames.IndexOf(Names[I]);
   If Index<>-1 then propNames.Objects[Index]:=Self;
  end;
  Names.Free;Values.Free;Types.Free;
{}
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
  exit;
  end;
 end;
 If propNames.Count=0 then begin
  GetObjectProps(propNames,propValues,propTypes);
 end else begin
//  If (Obj is Self.ClassType) then Exit;
 //
{  Index:=propNames.IndexOf('Цвет');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Знак');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Масштаб');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Шрифт');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Текст');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Размер');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Стиль');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Прозрачность');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('#Геоданные');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('#Экспликация');If Index<>-1 then propNames.Objects[Index]:=Self;
}
  Names:=TStringList.Create;Values:=TStringList.Create;Types:=TStringList.Create;
  GetObjectProps(Names,Values,Types);
  For I:=0 to Names.Count-1 do begin
   Index:=propNames.IndexOf(Names[I]);
   If Index<>-1 then propNames.Objects[Index]:=Self;
  end;
  Names.Free;Values.Free;Types.Free;
{}
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
 end;
end;

function TPointDot.GetLayer: TResource;
begin
 Result:=ClassHandle;
end;

procedure TPointDot.SetLayer(PR: TResource);
begin
 ClassHandle:=PR;Code:=PR.ID;
end;

function TPointDot.PointColor: Integer;
var S:AnsiString;
begin
With Selector do begin
//If (GlobalSettings.Settings.gsColorZnaksCheck) then Result:=GlobalSettings.Settings.gsColorZnaks else begin
 S:=GetProperty('Цвет');
 If S=byLayer then Result:=RgbToCol(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]) else
 If S=byNone then Result:=RGBToCol(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]) else
 try
  Result:=StrToInt(S);
 except
  Result:=RGBToCol(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]);
  SetProperty('Цвет',byLayer);
 end;
end;
end;

function TPointDot.UseProperty(propName: AnsiString): boolean;
begin
 Result:=False;
 If Properties<>nil then Result:=Properties.PropValue[propName]<>nil;
end;

procedure TPointDot.DeleteProperty(propName: AnsiString);
begin
 If Properties<>nil then Properties.DeleteProperty(propName);
end;

procedure TPointDot.AddProperty(propName: AnsiString);
begin
 If Properties<>nil then Properties.AddProperty(propName,'');
end;

constructor TPointDot.CreateTaheoTextManager(PR: TResource; Znak: TPoint_Sign; Name: AnsiString; X1, Y1, Z1: Double;TI:Integer;notNumberZ:Boolean = False);
var B, B1:Boolean;
begin
 Create(X1,Y1,-1);Z:=Z1;
 TaheoIndex:=TI;                       
 Code:=PR.ID;ClassHandle:=PR;
 If Znak<>nil then begin
  What:=Znak.MyInd;
  If (Znak.useFont) {and (Znak.UseAttrType([tt_Number,tt_Z]) or notNumberZ)} then begin // создаем TextManager и устанавливаем имя и высоту для атрибутов
   CreateTextManager(Znak);
   B:=TextManager.SetSysValue(3,Name);
   If not(B) and notNumberZ then TextManager.SetAttrValue('*',Name);
   If Z<>ZNull then
    B1:=TextManager.SetSysValue(4,FloatToStrF(Z,ffFixed,_LD,Const_Of_DecimalHeight)) else B1:=False;
   B:=B or B1;
   If UID<>nil then StrDispose(UID);UID:=StrNew(PAnsiChar(Name));
   If not(B) and (notNumberZ=False) then begin TextManager.Free;TextManager:=nil;end;
  end;
 end;
end;

function TPointDot.GlassFont: byte;
var S:AnsiString;
begin
 Result:=0;
 S:=GetProperty('Прозрачность');
 If S = 'Нет' then Result:= 1 else
 If S = 'Да' then Result:=2;
end;

function TPointDot.LocalPointName: AnsiString;
begin
 If TextManager<>nil then begin
  TextManager.UpdateText;
  Result:=TextManager.GetSysValue(3);
  TextManager.Restore;
 end;
end;

function TPointDot.NullTextManager: boolean;
begin
end;

procedure TPointDot.ApplyInternalProps(Obj: TTD);
begin
 If Obj is TPointDot then begin
  Ugol:=TPointDot(Obj).Ugol;
 end;
end;

function TPointDot.PointInSect(Sect: TSect;invertSelect:Boolean): boolean;
begin
 Result:=Selector.PointInSect(XDot,YDot,Sect)
end;

function TPointDot.PointInSect2(P:PCollection;invertSelect:Boolean): boolean;
begin
 Result:=Point_And_Polygon(XDot,YDot,P)>-1
end;

function TPointDot.GetSect: TSect;
var Sect:TSect;N:Integer;PZ:TPoint_Sign;
begin
 With Result do begin
  Left:=XDot;Top:=YDot;Right:=XDot;Bottom:=YDot;
//  If What =-1 then exit;
//  SetTextManager;
  try
  if Selector.GPointCol<>nil then
   begin
    N:=SearchThis(Selector.GPointCol,(abs(What)));
     If N<>-1 then begin
       PZ:=Selector.GPointCol.At(N);
       PZ.X:=XDot;PZ.Y:=YDot;PZ.Ugol:=Ugol;
     try  Sect:=PZ.GetRect(Koef); except exit;end;
       Sect.Left:=Sect.Left+XDot;Sect.Right:=Sect.Right+XDot;
       Sect.Top:=Sect.Top+YDot;Sect.Bottom:=Sect.Bottom+YDot;
      // Rectangle(GCanvas.Handle,XPix(Sect.Left),YPix(Sect.Top),XPix(Sect.Right),YPix(Sect.Bottom));
       Result:=Sect;
     end;
   end;
  finally
  // ResetTextManager;
  end;
 end;
end;

procedure TPointDot.SetGabarites(MRect_: TMRect);
var N:Integer;PZ:TPoint_Sign;
begin
 MRect_.Insert(XDot,YDot);
exit;
 If userObj <> nil then begin
 end else
 With Selector do begin
  N:=SearchThis(GPointCol,(abs(What)));
    If N<>-1 then begin
     PZ:=GPointCol.At(N);
     PZ.SetGabaritesBlock(nil,XDot,YDot,Ugol,XKoef,YKoef);
    end;
 end;
end;

function TPointDot.GetSelector: TSelector;
begin
 Result:=fSelector;
end;

function TPointDot.ResetParams(ParamID: Integer;Params: Pointer):boolean;
var I2: Integer; PD2: TPointDot; B2: Byte;
begin
 Result:=False;
 case ParamID of
  1:If userObj<>nil then begin
     If userObj.objType = TWG_Block then
     begin
      if (TGeoBlock(userObj).TwgForm<>nil) then
      begin
       if BlockTextBitmaps=nil then BlockTextBitmaps:=PCollection.Create(1);
       if BlockTextBitmaps.Count<>TGeoBlock(userObj).TwgForm.Twigs.AnyCount then
       begin
        while BlockTextBitmaps.Count>0 do begin
         if TObject(BlockTextBitmaps[0])<>nil then TObject(BlockTextBitmaps[0]).Free;
         BlockTextBitmaps.AtDelete(0);
        end;
        for I2:=0 to TGeoBlock(userObj).TwgForm.Twigs.AnyCount-1 do begin
         PD2:=TGeoBlock(userObj).TwgForm.Twigs.AAt(I2,B2);
         if (B2=TWG_Point) and (PD2 is TDotText) then
          BlockTextBitmaps.Insert(TBitmap.Create)
         else
          BlockTextBitmaps.Insert(nil);
        end;
       end;
      end;
      Result:=userObj.ResetParams(ParamID,Params);
     end;
    end;
 end;
end;

procedure TPointDot.ChangeXYKoef(XK, YK: Double);
begin
  If userObj<>nil then begin
   If userObj.objType = TWG_Block then userObj.ChangeXYKoef(XK,YK);
  end;
end;

function TPointDot.isBlock: Boolean;
begin
 Result:=False;
 If userObj<>nil then if userObj.objType = TWG_Block then Result:=True;
end;

function TPointDot.GetZnak: Integer;
var S:String;
begin
 S:=GetProperty('Знак');
 If (S=byLayer) or (S=byNone) then Result:=What else try Result:=StrToInt(S);except SetProperty('Знак',byLayer);Result:=What;end;
end;

procedure TPointDot.CreateTrees(TreeNames: AnsiString);
var I:Integer;dMin,dMax:Integer;PD:TPointDot;St:TStrings;
begin
 St:=TStringList.Create;
 St.Text:=MakeString(TreeNames,'-');
 If St.Count=2 then begin
  try
   dMin:=StrToInt(Trim(St[0]));dMax:=StrToInt(Trim(St[1]));
  except
   raise Exception.Create('При разборе диапазона ['+TreeNames+'] возникла ошибка: один из параметров не является целым числом.');
   exit;
  end;
  If Trees<>nil then Trees.Free;
  Trees:=PCollection.Create(1);
   For I:=dMin to dMax do begin
    PD:=TPointDot.CreateAsPointDot_(Self, False, False);
    PD.TextManager.SetAttrValue('№ растения',IntToStr(I));
    Trees.Insert(PD);
   end;
  St.Free;
 end else begin
  St.Free;
  raise Exception.Create('При разборе диапазона ['+TreeNames+'] возникла ошибка: неверное количество аргументов');
 end;
end;

procedure TPointDot.ReCreateTrees(TreeNames: AnsiString);
var I:Integer;dMin,dMax:Integer;PD:TPointDot;St:TStrings;TreesDup:PCollection;
Function Found(S:AnsiString):TPointDot;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to Trees.Count-1 do
  If TPointDot(Trees[I]).TextManager.AttrValue('№ растения')=S then begin
   Result:=Trees[I];
   exit;
  end;
end;
begin
 St:=TStringList.Create;
 St.Text:=MakeString(TreeNames,'-');
 If St.Count=2 then begin
  try
   dMin:=StrToInt(Trim(St[0]));dMax:=StrToInt(Trim(St[1]));
  except
   raise Exception.Create('При разборе диапазона ['+TreeNames+'] возникла ошибка: один из параметров не является целым числом.');
   exit;
  end;
   If Trees.Count<>dMin-dMax+1 then begin // пересоздаем
    TreesDup:=PCollection.Create(1);
    For I:=dMin to dMax do begin
     PD:=Found(IntToStr(I));
     If PD=nil then begin
      PD:=TPointDot.CreateAsPointDot_(Self, False, False);
      PD.TextManager.SetAttrValue('№ растения',IntToStr(I));
     end else Trees.AtDelete(Trees.IndexOf(PD));
     TreesDup.Insert(PD);
    end;
    Trees.Free;Trees:=TreesDup;
   end;
  St.Free;
 end else begin
  St.Free;
  raise Exception.Create('При разборе диапазона ['+TreeNames+'] возникла ошибка: неверное количество аргументов');
 end;
end;

function TPointDot.BlockVisible: boolean;
begin
 Result:=True;
 If GlobalRender then exit;
 With Selector do
 With GRect do begin
  If BlockSect.Right<Left then begin Result:=False;Exit;end;
  If BlockSect.Left>Right then begin Result:=False;Exit;end;
  If BlockSect.Top>Top then begin Result:=False;Exit;end;
  If BlockSect.Bottom<Bottom then begin Result:=False;Exit;end;
 end;
end;

function TPointDot.ZnakVisible: boolean;
begin
 Result:=True;
 //Selector.GCanvas.Pen.Color:=RGBToCol(255,0,0);
 With Selector.GRect do begin
 {
  If ZnakSect.Right<Left then begin Result:=False;Exit;end;
  If ZnakSect.Left>Right then begin Result:=False;Exit;end;
  If ZnakSect.Top>Top then begin Result:=False;Exit;end;
  If ZnakSect.Bottom<Bottom then begin Result:=False;Exit;end;
 }
With ZnakSect do begin
//   PMoveTo(Left,Top);PLineTo(Right,Top);PLineTo(Right,Bottom);PLineTo(Left,Bottom);PLineTo(Left,Top);
//   AllocConsole;
//   Writeln(XPix(Left),' ',YPix(Top));Writeln(XPix(Right),' ',YPix(Bottom));Writeln('-------------------');
  end;
 end;
 Result:=False;
end;

procedure TPointDot.renderGabarites;
begin
end;

function TPointDot.GetDrawerObject: TObject;
begin
 Result := FDrawerObject;
end;

procedure TPointDot.SetDrawerObject(Obj: TObject);
begin
 FDrawerObject := Obj;
end;
{ TPointMessage }

constructor TPointMessage.Create(X, Y: Extended; W: SmallInt);
begin
 inherited;
 PastDate:='';
end;

function TPointMessage.isVisible: Boolean;
begin
 With Selector do
  Result:=(XDot>Grect.Left) and (XDot<Grect.Right) and
          (YDot<Grect.Top) and (YDot>Grect.Bottom);
end;

procedure TPointMessage.ShowMessages;
begin
// If wndParent = nil then exit;
// wndParent.InsertControl(ChatForm.Chat);
// ChatForm.Chat.Visible:=False;ChatForm.Chat.Visible:=True;
// ChatForm.Chat.ShowAt(XPix(XDot)+8,YPix(YDot)+8,bpLeftTop);
end;

procedure TPointMessage.HideMessages;
begin
// ChatForm.InsertControl(ChatForm.Chat);
end;

constructor TPointMessage.Load(Stream: TBufStream);
begin
 inherited;
 EventName:=Stream.ReadString;
 EventNum:=Stream.ReadString;
end;

procedure TPointMessage.Store(Stream: TBufStream);
begin
 inherited;
 Stream.WriteString(EventName);
 Stream.WriteString(EventNum);
end;

initialization
// AllocConsole;
// Writeln('IS=',TTextManager.InstanceSize);
// AssignFile(FTest,'D:\TEST_prop.txt');
// Rewrite(FTest);
// AllocConsole;
 bmpTrue:=TBitmap.Create;bmpFalse:=TBitmap.Create;bmpMiddle:=TBitmap.Create;bmpInactive:=TBitmap.Create;bmpFalsePlus:=TBitmap.Create;
finalization
 bmpTrue.Free;bmpFalse.Free;
end.
