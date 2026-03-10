Unit ECText;

Interface

Uses
     Collect, TwgDraw, EMath, newConsts, newResource, MathS_Basic, newFontScale,
     System.Types, tmpPainter;

Const
	Twg_Font=101;
	In_Any=1;
	In_Contur=2;
	In_EPMap=3;
	In_ESMap=4;
	In_TaheoTwig=6;
	In_TaheoDot=5;
  In_LotFonts=7;
  In_PointFonts=8;
  In_PointDataFonts=9;
{ Какого типа подпись }
  Fnt_Any=0;     // простая подпись
  Fnt_ZPoint=1;  // отметка высоты
  Fnt_Promer=2;  // промер
  Fnt_Taheo=3;   // номер тахео точки
  Fnt_Dxf=4;     // из DXF
  Fnt_Data=5;      // марка из БД
  Fnt_PromerAlfa=6;
  Fnt_PromerBeta=7;
{}
  Add_To_Font=0;

var      Frg:Array[1..5] of tPoint;
         AllPoly1:Array[0..4] of tPoint;

type
 hDc = Integer;

 TWhatFont=class(TTwgObject)
   What:byte;
   Nomer:Longint;
   Lot:LongInt;
   Constructor Create(a:byte;b,Lt:longint);
 end;

TEFont=class(TTD)
 private
   function GetGUIDStr: AnsiString;
   procedure SetGUIDStr(const Value: AnsiString);
  public
   TaheoIndex:SmallInt;
   ParentIndex:Integer; // индекс в коллекции шрифтов
  {}
   ClassCode  :Double;
   ClassHandle:TResource;
   {}
   Inv,Fonts:byte;
   {}
   UgolRotate:SmallInt;
   Hf,Wf:Single; {изменено с SmallInt}
   XF,YF:Double;
   X2,Y2:Double;
   Dx,Dy:Single;
 {}
   Named:PAnsiChar;
   What:Byte;
   Palitra:Longint;
 {}
   it,bl,un:Byte;
 {}
   Lock:boolean;
 {}
   Ins:Integer;
 {}
   isMarked:Byte;
 {}
   ShiftX,ShiftY:Smallint;// смещение относительно точки
   inPoint:Pointer;
 {}
   FontView:TFontViewEx;
   GUID:TGUID;
   Constructor Create(F:byte;U:SmallInt;H,W:single;X,Y:single;S:AnsiString;W1:Byte);
   Constructor CreateClass(Hand:TResource;U:SmallInt;X,Y:single;S:AnsiString;W1:Byte);
   Constructor CreateLockClass(Hand:TResource;U:SmallInt;X,Y:single;S:AnsiString;H,W:Double;W1:Byte);
   Constructor CreateLock(F:byte;U:SmallInt;H,W:single;X,Y:single;S:AnsiString;W1:Byte);
   Constructor CreateAsFont(Fnt:TEFont);
   Destructor Destroy;override;
   Function CreatehFont(Dc:HDc;Flag:boolean):hFont;
   Procedure AssignFont(Fnt:TEFont);
   Constructor Load(St:TBufStream);Override;
   Procedure Store(St:TBufStream);Override;
   { Новая загрузка }
   Procedure LoadNew(St:TBufStream);
   {}
   {GUID}
   Property GUIDStr:AnsiString read GetGUIDStr write SetGUIDStr;
  end;

 Const
     ft_Modern=2;
     ft_Roman=4;
     ft_Script=8;
     ft_italik=1;
     ft_Bold=16;
     ft_NewRoman=32;

Implementation uses SysUtils, newProcs;

constructor TEFont.Create;
 var N:Array[0..255] of AnsiChar;
     TmpUg:Single;
begin
 CreateGUID(GUID);
// TaheoIndex:=GMemMakeIndex;
 Fonts:=F;
 UgolRotate:=U;
 case F of
	2:
	  	begin
		HF:=22;
		WF:=10;
		end;
	4:
		begin
		HF:=33;
		WF:=11;
		end;
	8:
		begin
		HF:=44;
		WF:=21;
		end;
	16:
		begin
		HF:=50;
		WF:=23;
		end;
	else
		begin
		  HF:=H;
		  WF:=W;
		end;
 end;
 StrPCopy(N,S);
 Xf:=X;
 Yf:=Y;
  Named:=StrNew(N);
 Inv:=0;
 What:=W1;
  ClassCode:=-1;
  Lock:=False;
  Ins:=-1;
  isMarked:=0;
 X2:=-1000000;
 FontView:=nil;
 ShiftX:=0;ShiftY:=0;
 inPoint:=nil;
end;

constructor TEfont.CreateClass(Hand:TResource;U:SmallInt;X,Y:single;S:AnsiString;W1:Byte);
begin
  CreateGUID(GUID);
//  TaheoIndex:=GMemMakeIndex;
  ClassCode:=Hand.ID;
  ClassHandle:=Hand;
  UgolRotate:=U;
  XF:=X;YF:=Y;
  Named:=StrNew(PAnsiChar(S));
  X2:=-1000000;
  Inv:=0;
  HF:=ClassHandle.FH;
  WF:=ClassHandle.FW;
  if ClassHandle.FLock then Lock:=True else
  if ClassHandle.FUnLock then Lock:=False else Lock:=False;
  What:=W1;
  Ins:=-1;
  isMarked:=0;
  FontView:=nil;
 ShiftX:=0;ShiftY:=0;
 inPoint:=nil;
 end;

function TEFont.CreatehFont(Dc: HDc; Flag: boolean): hFont;
begin
 //
end;

constructor TEfont.CreateLockClass;
begin
  CreateGUID(GUID);
//  TaheoIndex:=GMemMakeIndex;
  Lock:=True;
  ClassCode:=Hand.ID;
  ClassHandle:=Hand;
  UgolRotate:=U;
  XF:=X;YF:=Y;
  Named:=StrNew(PAnsiChar(S));
  HF:=H;WF:=W;
  Inv:=0;
  Ins:=-1;
  What:=W1;
  isMarked:=0;
  FontView:=nil;
 ShiftX:=0;ShiftY:=0;
 inPoint:=nil;
 end;

constructor TEFont.CreateLock;
 var N:Array[0..255] of AnsiChar;
     TmpUg:Single;
begin
 CreateGUID(GUID);
// TaheoIndex:=GMemMakeIndex;
 Lock:=True;
 Fonts:=F;
 UgolRotate:=U;
 HF:=H;
 WF:=W;
 StrPCopy(N,S);
 Xf:=X;
 Yf:=Y;
  Named:=StrNew(N);
 Inv:=0;
  ClassCode:=-1;
{ X2:=-1000000;}
  Ins:=-1;
  What:=W1;
  isMarked:=0;
 FontView:=nil;
 ShiftX:=0;ShiftY:=0;
 inPoint:=nil;
end;

Destructor  TEFont.Destroy;
 begin
  StrDispose(Named);
 end;

function TEFont.GetGUIDStr: AnsiString;
begin

end;

Constructor TEFont.CreateAsFont;
begin
 CreateGUID(GUID);
  TaheoIndex:=fnt.TaheoIndex;
  ClassCode:=fnt.ClassCode;
  ClassHandle:=fnt.ClassHandle;
  Inv:=fnt.Inv;
  Fonts:=Fnt.Fonts;
  UgolRotate:=Fnt.UgolRotate;
  Hf:=fnt.Hf;
  Wf:=fnt.Wf;
  Xf:=fnt.Xf;
  Yf:=fnt.Yf;
  X2:=fnt.X2;
  Y2:=fnt.Y2;
  DX:=fnt.DX;DY:=fnt.DY;
  Named:=StrNew(fnt.Named);
  What:=fnt.What;
  Palitra:=fnt.Palitra;
  it:=fnt.it;
  bl:=fnt.bl;
  un:=fnt.un;
  Lock:=fnt.Lock;
  Ins:=fnt.Ins;
  isMarked:=fnt.isMarked;
  FontView:=fnt.FontView;
  ShiftX:=fnt.ShiftX;ShiftY:=fnt.ShiftY;
  inPoint:=nil;
 end;

Procedure TEFont.AssignFont;
 begin
  TaheoIndex:=fnt.TaheoIndex;
  ClassCode:=fnt.ClassCode;
  ClassHandle:=fnt.ClassHandle;
  Fonts:=Fnt.Fonts;
  UgolRotate:=Fnt.UgolRotate;
  Hf:=fnt.Hf;
  Wf:=fnt.Wf;
  Xf:=fnt.Xf;
  Yf:=fnt.Yf;
  X2:=fnt.X2;
  Y2:=fnt.Y2;
  DX:=fnt.DX;DY:=fnt.DY;
  StrDispose(Named);
  Named:=StrNew(fnt.Named);
  What:=fnt.What;
  Palitra:=fnt.Palitra;
  it:=fnt.it;
  bl:=fnt.bl;
  un:=fnt.un;
  Lock:=fnt.Lock;
  Ins:=fnt.Ins;
  isMarked:=fnt.isMarked;
  FontView:=fnt.FontView;
  ShiftX:=fnt.ShiftX;ShiftY:=fnt.ShiftY;
  inPoint:=nil;
 end;

constructor TEFont.Load;
 Var H,W:SmallInt;
     TmpUg:Single;
     XC,YC:Single;
begin
//LoadNew(ST);Exit;
 if Version>18 then LoadNew(ST) else
 begin // старая загрузка
  ST.read(Fonts,1);
  ST.read(UgolRotate,sizeof(UgolRotate));
   ST.read(H,SizeOf(H));
   ST.read(W,SizeOf(W));
   HF:=H/10;
   WF:=W/10;
   if HF=0 then begin HF:=0.44;WF:=0.22;end;
  {}
 If Version<=5 then
  begin
   ST.read(XC,SizeOf(XC));
   ST.read(YC,SizeOf(YC));
    XF:=XC;YF:=YC;
  end else
  begin
   ST.read(XF,SizeOf(XF));
   ST.read(YF,SizeOf(YF));
  end;
  Named:=ST.StrRead;
  Inv:=0;
          If Version>1 then
                 begin
                  St.Read(Palitra,sizeOf(Palitra));
       end
                 else
          Palitra:=RGBToCol(255,0,0);
   If Version>4 then
    begin
     ST.Read(it,1);
     ST.Read(bl,1);
     ST.Read(un,1);
    end else
    begin
     It:=0;bl:=0;Un:=0;
    end;
   If Version>8 then
    begin
     ST.Read(ClassCode,SizeOf(ClassCode));
      if Version>15 then
       begin
        ST.Read(Lock,SizeOf(Lock));
         if Version>16 then
          ST.Read(What,SizeOf(What)) else What:=Fnt_Any;
       end;
    end else
    begin
      ClassCode:=-1;
    end;
  X2:=-1000000;Y2:=-1000000;
  Ins:=-1;
 end;
 isMarked:=0;
 FontView:=nil;
 InPoint:=nil;
end;

Procedure TEFont.LoadNew;
var TI:ShortInt;
 begin
  ST.Read(Fonts,1);
  ST.Read(UgolRotate,sizeof(UgolRotate));
 {}
  ST.Read(HF,SizeOf(HF));
  ST.Read(WF,SizeOf(WF));                                                
 {}
  ST.Read(XF,SizeOf(XF));
  ST.Read(YF,SizeOf(YF));
  Named:=ST.StrRead;
  ST.Read(Palitra,SizeOf(Palitra));
  ST.Read(it,1);
  ST.Read(bl,1);
  ST.Read(un,1);
  ST.Read(ClassCode,SizeOf(ClassCode));
  ST.Read(Lock,SizeOf(Lock));
  ST.Read(What,SizeOf(What));
     If Version>23 then begin                               
      If Version<28 then begin
       ST.Read(TI,SizeOf(TI));TaheoIndex:=TI;
      end else ST.Read(TaheoIndex,SizeOf(TaheoIndex));
      If Version>32 then begin
       ST.Read(ShiftX,SizeOf(ShiftX));
       ST.Read(ShiftY,SizeOf(ShiftY));
      end;
     end else TaheoIndex:=-1;
  isMarked:=0;                    
 {}
  X2:=-1000000;Y2:=-1000000;
  Ins:=-1;
  FontView:=nil;
  InPoint:=nil;
 end;

procedure TEFont.SetGUIDStr(const Value: AnsiString);
begin

end;

procedure TEFont.Store;
 var H,W:SmallInt;
begin
 ST.write(Fonts,1);
 ST.write(UgolRotate,sizeof(UgolRotate));
{ H:=Round(HF*10);
 W:=Round(WF*10);}
 ST.write(HF,SizeOf(HF));
 ST.write(WF,SizeOf(WF));
 ST.write(XF,SizeOf(XF));
 ST.write(YF,SizeOf(YF));
 ST.StrWrite(Named);
 ST.write(Palitra,SizeOf(Palitra));
 ST.write(it,1);
 ST.write(bl,1);
 ST.write(un,1);
 ST.Write(ClassCode,SizeOf(ClassCode));
 ST.Write(Lock,SizeOf(Lock));
 ST.Write(What,SizeOf(What));
 ST.Write(TaheoIndex,SizeOf(TaheoIndex));
 ST.Write(ShiftX,SizeOf(ShiftX));
 ST.Write(ShiftY,SizeOf(ShiftY));
// ST.Write(Ins,SizeOf(Ins));
end;


{ TWhatFont }

constructor TWhatFont.Create(a: byte; b, Lt: longint);
begin
 //
end;

initialization
end.
