unit Lines3;
interface
Uses Collect, Lib, TwgDraw,
     Maths_Basic, EcDot, Math, newResource, System.Types;

const
        ver_geo_line: integer = 1;
        DrawLineCounter:Integer=0;
        BlockGlobalWidth:boolean = False;
const
	ls_Dinamic1=1;
	ls_Dinamic2=32;
	ls_DblLine=2;
	ls_Solid1=4;
	ls_Solid2=8;
	ls_OrientOn=16;
	ls_OnlyInDot=32;
	ls_ToNext=64;
	ls_ToPred=128;
	AllReg:TRect=(Left:-32000;Top:32000;Right:32000;Bottom:-32000);
{-------------------------------------------------}
type
	AllBits=(bt_Line,bt_Arc,bt_Custom);
  hDc = Integer;
{-------------------------------------------------}
	TGeoPoint=Class(TTwgObject)
		x,y:Double;
		constructor Create(a,b:Double);
  end;
{-------------------------------------------------}

{ TLineStruct }

TLineStruct=class(TTwgObject)
	BitOf:AllBits;
	DrawState:SmallInt; 	{флаги для линии}
	Param0:single;		{смещение dL (1)}
	Param1:single;		{толщина линии (1)}
	Param2:single;		{отрезок линии (1)/радиус окружности/угол поворота объекта}
	Param3:single;		{начальное смещение (0>=..<1)*Param0}
      	                        {для 2 линий}
	Param4:single;		{расстояние м-ду линиями/Номер усл. зн.}
	Param5:single;		{смещение dL (1)}
	Param6:single;		{толщина линии (2)}
	Param7:single;		{отрезок линии (2)}
	Param8:single;		{начальное смещение (2)}
  lVorign: single;        {поперечное смещение}
  rVOrign: single;        {поперечное смещение}
  Color  : integer;
  bkColor: integer;
                         {конечное смещение}
  Param4S: AnsiString;
	constructor Create;
	constructor Load(ST:TBufStream);override;
	procedure Store(ST:TBufStream);override;
//  procedure FillPartOfLineType(var PL: TPartOfLineType);
  procedure Write;
end;
{-------------------------------------------------}
TGeoLine=class(TTD)
	Structura:PCollection;
	NameOf:array[0..59] of AnsiChar;
  IdNum:SmallInt;
  LocalScale: Double;
  Points:PCollection;
  Layer:TResource;
	constructor Create(Name:String = '';Id:Integer = -1);
	constructor Load(ST:TBufStream);override;
        procedure Store(ST:TBufStream);override;
        procedure CreatePoints(P:TSortedCollection);
	destructor Destroy;Override;
end;
{-------------------------------------------------}

Type
   TPixProc = Function  (X:Double):Int64; // функция для XPix
   TDrawLineProc = Procedure (X1,Y1,X2,Y2:Double); // функция DrawLine
   TArcProc = Procedure(DC:hdc;X1,Y1,X2,Y2:Double);

var //UXPix,UYPix:TPixProc;
    //UDrawLine:TDrawLineProc;
    //UArc:TArcProc;
    //GMx,GMy,GMAll:Double;
    ZnakDrawMode:integer;
    ScreenDc:hDc;// контекст при рисовке знака its_test
    ZnakNil:Pointer;

implementation uses newProcs, Types_Dimano, circle_di, SysUtils, LConvEncoding,
                    Writer;



Procedure ArcTwg(Col:PCollection;aX1,aY1,aX2,aY2:Double);
var
   xnc,ync,xc,yc,dx,dy:Double;
   x1,y1,x2,y2,XB,YB,XE,YE:Double;
   XX1,XX2,YY1,YY2,XY:Double;
   NN,I:Integer;
   Ug:Double;
 {}
   Ko:Double;
   P:PCollection;
   D1,D2:TDot1;
   Ugol:Double;
begin
  Ko:=1;
  xc:=(ax1+ax2)/2;
  yc:=(ay1+ay2)/2;
  dx:=(ax2-ax1)/2*ko;
  dy:=(ay2-ay1)/2*ko;
  Ugol:=0;
  xnc:=(xc*ko*cos(Ugol)-yc*ko*sin(Ugol));
  ync:=(yc*ko*cos(Ugol)+xc*ko*sin(Ugol));
  NN:=25; //GGraphSet.Kvant;
  P:=Arc_Rotate2( Xc, Yc, 0, aX1,aY1,aX2,aY2,ax1,ay1,ax1,ay1,NN);
  Col.Insert(P);
end;

Procedure TwgDrawLine(Col:PCollection;P:PCollection;W:Double);
var S:String;PD,PD1:TDot;I,J:Integer;
begin
  {P-коллекция с точками ломаной}
  if P.Count=0 then Exit;
   For I:=P.Count-1 downTo 1 do
    With TDot(P[I]) do
     begin
      PD:=P[I-1];
      if (PD.XDot=XDot) and (PD.YDot=YDot) then P.AtFree(I);
     end;
  For I:=0 to P.Count-2 do begin
   PD:=P[I];PD1:=P[I+1];
   Col.Insert(TDWG_Line.Create(PD.XDot,PD.YDot,PD1.XDot,PD1.YDot));
  end;
end;

{=============================================================}
Function Atan2(dx,dy:single):single;
var
	u:single;
begin
if dx=0 then
	begin
	if dy>0 then Atan2:=Pi/2 else Atan2:=Pi*3/2;
        exit;
	end;
if dy=0 then
	begin
	if dx>0 then Atan2:=0 else Atan2:=Pi;
        exit;
	end;
u:=arctan(dy/dx);
Atan2:=U;
if (dx<0) and (dy<0) then Atan2:=U+Pi;
if (dx<0) and (dy>0) then Atan2:=U+Pi;
if (dx>0) and (dy<0) then Atan2:=U+2*Pi;
end;

Function CutLine(Coord:PCollection;dNext,dPrev:Double):PCollection;
var I,J,K:Integer;D,D1:TDot;X,Y:Double;LineLength,AllLength,Angle:Double;
begin
 Result:=nil;
 K:=-1;AllLength:=0;
 For I:=0 to Coord.Count-2 do begin
   D:=Coord.FList[I];D1:=Coord.FList[I+1];
    LineLength:=Distance(D.XDot,D.YDot,D1.XDot,D1.YDot);
    AllLength:=AllLength+LineLength;
    if K=-1 then begin
     If dNext>LineLength then begin
       dNext:=dNext-LineLength;
     end else begin K:=I;Angle:=Atan2(D1.XDot-D.XDot,D1.YDot-D.YDot);end;
    end;// if K=-1
  end;
  if (K<>-1) and (dNext+dPrev<AllLength) then begin
   Result:=PCollection.Create(Coord.Count);
   // получив точку вставляем все остальные в коллекцию
   For I:=K to Coord.Count-1 do Result.Insert(TDot.CreateAsDot(Coord[I]));
   D:=REsult.FList[0];
   D.XDot:=D.XDot+dNext*cos(Angle);D.YDot:=D.YDot+dNext*sin(Angle);
    For I:=Result.Count-1 downto 1 do begin
     D:=Result.FList[I];D1:=Result.FList[I-1];
     LineLength:=Distance(D.XDot,D.YDot,D1.XDot,D1.YDot);
     if dPrev>LineLength then begin
      dPrev:=dPrev-LineLength;Result.AtDelete(I);end else
      begin Angle:=Atan2(D1.XDot-D.XDot,D1.YDot-D.YDot);break;end;
    end;
   D:=Result.FList[Result.FList.Count-1];
   D.XDot:=D.XDot+dPrev*cos(Angle);D.YDot:=D.YDot+dPrev*sin(Angle);
  end;
end;

Function LenPoints(Points:PCollection):Double;
 var I:Integer;D,D1:TDot;
 begin
  Result:=0;
  For I:=0 to Points.Count-2 do
   begin
    D:=Points[I];D1:=Points[I+1];
    Result:=Result+Distance(D.XDot,D.YDot,D1.XDot,D1.YDot);
   end;
 end;
{-------------------------------------------------}
Function ScreenPix(X:Double):Int64;
begin
  Result:=Round(X);
end;

Procedure DrawScreenLine(X,Y,X1,Y1:Double);
begin
// MoveTo(ScreenDc,Round(X),Round(Y));LineTo(ScreenDc,Round(X1),Round(Y1));
end;

{ TLineStruct }

constructor TLineStruct.Create;
begin
  BitOf:=bt_Line;
  DrawState:=Ls_Solid1;
  Param0:=0;
  Param1:=0.1;
  Param2:=0;
  Param3:=0;
  Param4:=0;
  Param5:=0;
  Param6:=0;
  Param7:=0;
  Param8:=0;
 //
  Param4S := '';
end;
{-------------------------------------------}
constructor TGeoLine.Create;
begin
  Structura:=Pcollection.Create(1);
   Structura.Insert(TLineStruct.Create);
 StrPCopy(NameOf,AnsiString(Name));
 WriteIn(['NameLine=',NameOf]);
 IdNum:=Id;
 LocalScale := 1;
end;
{-------------------------------------------}
procedure TGeoLine.CreatePoints(P: TSortedCollection);
var I,Index:Integer;PS:TLineStruct;
begin
Points.DeleteAll;
for I:=0 to Structura.Count-1 do
  begin
   PS:=Structura.At(I);
   if PS.BitOf=bt_Custom then begin
    Index:=SearchThis(P,Round(PS.Param4));
    If Index<>-1 then begin
      Points.Insert(P.FList[Index]);
     end else Points.Insert(@ZnakNil);
    end else Points.Insert(@ZnakNil);
  end;
end;

destructor TGeoLine.Destroy;
begin
  Structura.Free;
  If Assigned(Points) then begin
   Points.DeleteAll;Points.Free;
  end;
end;

{-------------------------------------------}
constructor TGeoPoint.Create;
begin
  x:=a;
  y:=b;
end;
{-------------------------------------------}
constructor TGeoLine.Load;
var s: array[0..4] of AnsiChar;
begin
  st.read(s, sizeof(s));
  if (s[0] = #1) and (s[1] = #1) and (s[2] = #1) then ver_geo_line := ord(s[3]) * 10 + ord(s[4])
  else ver_geo_line := 0;
  if ver_geo_line < 1 then st.Position := st.Position - sizeof(s);
  ST.read(NameOf,30); StrPCopy(NameOf, CP1251ToUtf8(NameOf));
  ST.read(IdNum,SizeOf(IdNum));
  structura:=Pcollection(st.get);
  Points:=PCollection.Create(Structura.Count);
end;
{-------------------------------------------}
procedure TGeoLine.Store;
const s: array[0..4] of AnsiChar = #1#1#1#0#1;
begin
  st.Write(s, sizeof(s));
  StrPCopy(NameOf, Utf8ToCP1251(NameOf));
	ST.Write(NameOf,30);
	ST.write(IdNum,SizeOf(IdNum));
   ST.put(structura);
end;
{=============================================================}
constructor TLineStruct.Load(ST: TBufStream);
begin
  ST.read(BitOf,SizeOf(BitOf));
  ST.read(DrawState,SizeOf(DrawState));
  ST.read(Param0,SizeOf(Param0));
  ST.read(Param1,SizeOf(Param1));
  ST.read(Param2,SizeOf(Param2));
  ST.read(Param3,SizeOf(Param3));
  ST.read(Param4,SizeOf(Param4));
  ST.read(Param5,SizeOf(Param5));
  ST.read(Param6,SizeOf(Param6));
  ST.read(Param7,SizeOf(Param7));
  ST.read(Param8,SizeOf(Param8));
  if ver_geo_line > 0 then
  begin
   ST.read(lvorign, SizeOf(lvorign));
   ST.read(rvorign, SizeOf(rvorign));
   st.read(color, sizeof(color));
   St.read(bkcolor, sizeof(bkcolor));
  end;
  Param4S := '';
end;
{-------------------------------------------}
procedure TLineStruct.Store(ST: TBufStream);
begin
  ST.Write(BitOf,SizeOf(BitOf));
  ST.Write(DrawState,SizeOf(DrawState));
  ST.write(Param0,SizeOf(Param0));
  ST.write(Param1,SizeOf(Param1));
  ST.write(Param2,SizeOf(Param2));
  ST.write(Param3,SizeOf(Param3));
  ST.write(Param4,SizeOf(Param4));
  ST.write(Param5,SizeOf(Param5));
  ST.write(Param6,SizeOf(Param6));
  ST.write(Param7,SizeOf(Param7));
  ST.write(Param8,SizeOf(Param8));

  ST.write(lvorign, SizeOf(lvorign));
  ST.write(rvorign, SizeOf(rvorign));

  st.Write(color, sizeof(color));
  st.Write(bkcolor, sizeof(bkcolor));
end;

{procedure TLineStruct.FillPartOfLineType(var PL: TPartOfLineType);
begin
 PL.BitOf := ord(BitOf);
 PL.DrawState := DrawState;
 PL.Param0 := Param0;
 PL.Param1 := Param1;
 PL.Param2 := Param2;
 PL.Param3 := Param3;
 PL.Param4 := Param4;
 PL.Param5 := Param5;
 PL.Param6 := Param6;
 PL.Param7 := Param7;
 PL.Param8 := Param8;
 PL.Color  := Color;
 PL.bkColor := bkColor;
 PL.SetParam4S(Param4S);
end;
}
procedure TLineStruct.Write;
begin
{ WriteIn(['LineStruct Lines3.pas']);
 WriteIn(['bitOf', BitOf]);
 WriteIn(['DrawState', DrawState]);
 WriteIn(['Param0', Param0]);
 WriteIn(['Param1', Param1]);
 WriteIn(['Param2', Param2]);
 WriteIn(['Param3', Param3]);
 WriteIn(['Param4', Param4]);
 WriteIn(['Param5', Param5]);
 WriteIn(['Param6', Param6]);
 WriteIn(['Param7', Param7]);
 WriteIn(['Param8', Param8]);
 WriteIn(['Color', Color]);
 WriteIn(['bkColor', bkColor]);
 WriteIn(['Param4S', Param4S]);}
end;


{-------------------------------------------}
end.

