Unit WPGeo;
{===========================================================================}
Interface Uses Collect, SysUtils,
               EMath,EcDOt,TWGColle,newSelector,Maths_Basic, tmpPainter;
{===========================================================================}

const
	TWG_Stvor=200;
	TWG_Polar=201;
	TWG_LineZas=202;
	TWG_InterLine=203;
	TWG_Perpend=204;

type
	TLineZasItem=Class(TTwgObject)
		Dot:TDot;
		Distanse:single;
		Constructor Create(X,Y,S:Single);
		Destructor Destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
   end;
{----------------------------------------------}
	TStvor=class(TTwgObject)
		Stay,Orient:TDot;
		Distanse:single;
	 	Constructor Create(pd1,pd2:TDot;S:Single);
		Destructor Destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
		Procedure Calc(var PD:TDot);
	 	Procedure Draw(DC:hDc;MX,MY:single);
	end;
{----------------------------------------------}
	TPolar=class(TTwgObject)
		Stay,Orient:TDot;
                Angle:extended;
		Distanse:single;
		RightAngle:boolean;

		Constructor Create(pd1,pd2:TDot;S:Single;A:extended;RA:boolean);
		Destructor Destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
		Procedure Calc(var PD:TDot);
		Procedure Draw(DC:hDc;MX,MY:single);
	end;
{----------------------------------------------}
	TLineZas=class(TTwgObject)
		Nabor:PCollection;
		Constructor Create;
		Destructor destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
		function Calc(var PD:TDot):boolean;
		function SmallCalc(I1,I2:TLineZAsItem;var D1,D2:TDot):boolean;
		function BigCalc(var PD:TDot):boolean;
		Procedure Draw(DC:hDc;MX,MY:single);
		Procedure AddItem(x,y,s:single);
		function Dist(P1,P2:TDot):single;
	end;
{----------------------------------------------}
	TInterLine=class(tTwgobject)
		Line1Dot1,Line1Dot2:TDot;
		Line2Dot1,Line2Dot2:TDot;
                Tw1,Tw2:Integer;
		Constructor Create(L1D1,L1D2,L2D1,L2D2:TDot);
		Destructor Destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
		Procedure Calc(var PD:TDot);
		Function Calc2(var PD:TDot;Otr:Boolean):boolean;
		Procedure Draw(DC:hDC;MX,MY:single);
	end;

	TPerpend=class(TTwgObject)
		Dot1,Dot2:TDot;
		Dist1,Dist2:single;
		RA:boolean;
		Constructor Create(D1,D2:TDot;Ds1,Ds2:single);
		Destructor Destroy;Override;
		Constructor Load(ST:TBufStream);Override;
		Procedure Store(ST:TBufStream);Override;
		Procedure Calc(var PD1,PD2:TDot);
		Procedure Draw(DC:hDC;MX,MY:single);
   end;
{----------------------------------------------}
function PolarDlg(var Dist:single;var Ang:extended;var RA:boolean):LongInt;
function PerpendDlg(var Dist1,Dist2:single):LongInt;
function LineZasDlg(var Coll:PCollection):LongInt;
{----------------------------------------------}
{	Const
		RStvor:TStreamRec=(
   	ObjType:10001;
      VmtLink:Ofs(TypeOf(TStvor));
      Load	 :@TStvor.Load;
		Store	 :@TStvor.Store);

		RPolar:TStreamRec=(
   	ObjType:10002;
      VmtLink:Ofs(TypeOf(TPolar));
      Load   :@TPolar.Load;
		Store  :@TPolar.Store);

		RLineZas:TStreamRec=(
		ObjType:10003;
		VmtLink:Ofs(TypeOf(TLineZas));
		Load	 :@TLineZas.Load;
		Store	 :@TLineZas.Store);

		RInterLine:TStreamRec=(
		ObjType:10004;
		VmtLink:Ofs(TypeOf(TInterLine));
		Load	 :@TInterLine.Load;
		Store	 :@TInterLine.Store);
}
{===========================================================================}
Implementation Uses newProcs;
{===========================================================================}

Constructor TLineZasItem.Create;
begin
	Dot:=(TDot.Create(x,y,0));
   Distanse:=s;
end;

Destructor TLineZasItem.Destroy;
begin
	Dot.FRee;
end;

Procedure TLineZasItem.Store;
begin
ST.Put(Dot);
ST.write(Distanse,SizeOf(Distanse));
end;

Constructor TLineZasItem.Load;
begin
Dot:=TDot(ST.Get);
ST.Read(Distanse,SizeOf(Distanse));
end;

{===========================================================================}
Constructor TStvor.Create;
begin
	Stay:=Pd1;
	Orient:=Pd2;
	Distanse:=S;
end;

Destructor TStvor.Destroy;
begin
	Stay.Free;
	Orient.Free;
end;

Procedure TStvor.Store;
begin
	ST.Write(Stay,sizeof(Stay));
	ST.Write(Orient,sizeof(Orient));
	ST.Write(Distanse,sizeof(Distanse));
end;

Constructor TStvor.Load;
begin
	ST.Read(Stay,sizeof(Stay));
	ST.Read(Orient,sizeof(Orient));
	ST.Read(Distanse,sizeof(Distanse));
end;


Procedure TStvor.Calc;
var
	Angle:Extended;
begin
	Angle:=Atan2(Stay.Ydot-Orient.Ydot,Stay.Xdot-Orient.Xdot)-Pi/2;
	PD.XDot:=Stay.XDot-Distanse*cos(Angle);
	PD.YDot:=Stay.YDot+Distanse*sin(Angle);
end;

Procedure TStvor.Draw;
var
	x,y,x1,y1,x2,y2:LongInt;
	PDT:TDot;
	Pen,OldPen:hPen;
begin
	Pen:=CreatePen(ps_solid,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);
	PDt:=(TDot.Create(0,0,0));
	x1:=round(Stay.XDot*MX);
	y1:=round(Stay.YDot*MY);
	RectAngle(DC,x1-2,y1-2,x1+2,y1+2);
	RectAngle(DC,x1-4,y1-4,x1+4,y1+4);
	x2:=round(Orient.XDot*MX);
	y2:=round(Orient.YDot*MY);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);
	Calc(PDt);
	x:=round(PDt.XDot*MX);
	y:=round(PDt.YDot*MY);
//	Arc(DC,x-2,y-2,x+2,y+2,0,0,0,0);

//	MoveTo(DC,x1,y1);LineTo(DC,x,y);
	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	Pen:=CreatePen(ps_dot,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);

	MoveTo(DC,x,y);LineTo(DC,x2,y2);

	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	PDt.Free;
end;
{----------------------------------------------}
Constructor TPolar.Create;
begin
	Stay:=Pd1;
	Orient:=Pd2;
	Distanse:=S;
	Angle:=a;
   RightAngle:=RA;
end;

Destructor TPolar.Destroy;
begin
	Stay.Free;
	Orient.Free;
end;

Procedure TPolar.Store;
begin
	ST.Write(Stay,sizeof(Stay));
	ST.Write(Orient,sizeof(Orient));
	ST.Write(Distanse,sizeof(Distanse));
	ST.Write(Angle,sizeof(Angle));
	ST.Write(RightAngle,SizeOf(RightAngle));
end;

Constructor TPolar.Load;
begin
	ST.Read(Stay,sizeof(Stay));
	ST.Read(Orient,sizeof(Orient));
	ST.Read(Distanse,sizeof(Distanse));
	ST.Read(Angle,sizeof(Angle));
	ST.Read(RightAngle,SizeOf(RightAngle));
end;

Procedure TPolar.Calc;
var
	An:extended;
begin
	An:=Atan2(Orient.Ydot-Stay.Ydot,Orient.Xdot-Stay.Xdot)-Pi/2;
	if RightAngle then
		An:=AN-Angle
	else An:=An+Angle;
	PD.XDot:=Stay.XDot+Distanse*cos(An);
	PD.YDot:=Stay.YDot-Distanse*sin(An);
end;

Procedure TPolar.Draw;
var
	x,y,x1,y1,x2,y2:LongInt;
	PDT:TDot;
	Pen,OldPen:hPen;
begin
	Pen:=CreatePen(ps_solid,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);

	PDt:=(TDot.Create(0,0,0));
	x1:=round(Stay.XDot*MX);
	y1:=round(Stay.YDot*MY);
	RectAngle(DC,x1-4,y1-4,x1+4,y1+4);
	RectAngle(DC,x1-2,y1-2,x1+2,y1+2);
	x2:=round(Orient.XDot*MX);
	y2:=round(Orient.YDot*MY);
	Calc(PDt);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);		
	x:=round(PDt.XDot*MX);
	y:=round(PDt.YDot*MY);
	Arc(DC,x-2,y-2,x+2,y+2,0,0,0,0);
	MoveTo(Dc,x1,y1);LineTo(Dc,x,y);
	if RightAngle then
		Arc(Dc,x1-round(Distanse*MX/5),y1-round(Distanse*MY/5),
			 x1+round(Distanse*MX/5),y1+round(Distanse*MY/5),
			 x,y,x2,y2)
	else
		Arc(Dc,x1-round(Distanse*MX/5),y1-round(Distanse*MY/5),
			 x1+round(Distanse*MX/5),y1+round(Distanse*MY/5),
			 x2,y2,x,y);
	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	Pen:=CreatePen(ps_dot,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);

	MoveTo(Dc,x1,y1);LineTo(Dc,x2,y2);

	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	PDt.Free;
end;
{----------------------------------------------}
Constructor TLineZas.Create;
begin
	Nabor:=(PCOllection.Create(1));
end;

Destructor TLineZas.Destroy;
begin
	Nabor.Free;
end;

Procedure TLineZas.Store;
begin
	ST.put(Nabor);
end;

Constructor TLineZas.Load;
begin
	Nabor:=PCollection(ST.Get);
end;

function TLineZas.Dist(P1,P2:TDot):single;
begin
	Dist:=sqrt(sqr(P1.XDot-p2.XDot)+sqr(P1.YDot-p2.YDot));
end;

function TLineZas.Calc;
var
	DT1,Dt2:TDot;
	DT3,Dt4:TDot;
	Point:TDot;
begin
Calc:=true;
Dt1:=TDot.Create(1,1,1);
Dt2:=TDot.Create(1,1,1);
if not SmallCalc(Nabor.At(0),Nabor.At(1),dt1,dt2) then
	begin
	calc:=false;
	Dt1.Free;
	Dt2.Free;
   exit;
   end;
if Nabor.Count=2 then
	begin
	PD.XDot:=Dt1.XDot;
	PD.YDot:=Dt1.YDot;
	Dt1.Free;
	Dt2.Free;
   exit;
	end;
Dt3:=(TDot.Create(1,1,1));
Dt4:=(TDot.Create(1,1,1));
if not SmallCalc(Nabor.At(0),Nabor.At(2),dt3,dt4) then
	begin
	Calc:=false;
	Dt1.Free;
	Dt2.Free;
	Dt3.Free;
	Dt4.Free;
   exit;
	end;
Point:=(TDot.Create(1,1,1));
if Dist(Dt1,Dt3)<Dist(Dt1,Dt4) then
{1}begin
	if Dist(Dt2,Dt3)<Dist(Dt2,Dt4) then
		begin
		if Dist(Dt1,Dt3)<Dist(Dt2,Dt3) then
			begin
			Point.XDot:=Dt1.XDot;
			Point.YDot:=Dt1.YDot;
			end
		else
			begin
			Point.XDot:=Dt2.XDot;
			Point.YDot:=Dt2.YDot;
			end;
		end
	else
		begin
		if Dist(Dt1,Dt3)<Dist(Dt2,Dt4) then
			begin
			Point.XDot:=Dt1.XDot;
			Point.YDot:=Dt1.YDot;
			end
		else
			begin
			Point.XDot:=Dt2.XDot;
			Point.YDot:=Dt2.YDot;
			end;
		end;
{1}end
else
{1}begin
	if Dist(Dt2,Dt3)<Dist(Dt2,Dt4) then
		begin
		if Dist(Dt1,Dt4)<Dist(Dt2,Dt3) then
			begin
			Point.XDot:=Dt1.XDot;
			Point.YDot:=Dt1.YDot;
			end
		else
			begin
			Point.XDot:=Dt2.XDot;
			Point.YDot:=Dt2.YDot;
			end;
		end
	else
		begin
		if Dist(Dt1,Dt4)<Dist(Dt2,Dt4) then
			begin
			Point.XDot:=Dt1.XDot;
			Point.YDot:=Dt1.YDot;
			end
		else
			begin
			Point.XDot:=Dt2.XDot;
			Point.YDot:=Dt2.YDot;
			end;
		end;
{1}end;
Point.What:=0;
if not BigCalc(Point) then
	begin
	Calc:=false;
	Dt1.Free;
	Dt2.Free;
	Dt3.Free;
	Dt4.Free;
	Point.Free;
	exit;
	end;
PD.XDot:=Point.XDot;
PD.YDot:=Point.YDot;
	Dt1.Free;
	Dt2.Free;
	Dt3.Free;
	Dt4.Free;
	Point.Free;
end;

function TLineZas.SmallCalc;
var
	DirUgol,P,R,alfa,beta,gama:extended;
	s1,s2,bazis:single;
begin
SmallCalc:=true;
Bazis:=sqrt(sqr(i1.Dot.XDot-i2.Dot.XDot)+sqr(i1.Dot.YDot-i2.Dot.YDot));
s1:=i1.Distanse;
s2:=i2.Distanse;
if (Bazis-s1-s2)>=0 then
	begin
	SmallCalc:=false;
   exit;
	end;
P:=(Bazis+s1+s2)/2;
r:=sqrt((p-s1)*(p-s2)*(p-bazis)/p);
alfa:=2*arctan(r/(p-s2));
beta:=2*arctan(r/(p-s1));
gama:=2*arctan(r/(p-bazis));
DirUgol:=Atan2(i2.Dot.XDot-i1.Dot.XDot,i2.Dot.YDot-i1.Dot.YDot);
D1.XDot:=i1.Dot.XDot+s1*cos(DirUgol-Alfa);
D1.YDot:=i1.Dot.YDot+s1*sin(DirUgol-Alfa);
D2.XDot:=i1.Dot.XDot+s1*cos(DirUgol+Alfa);
D2.YDot:=i1.Dot.YDot+s1*sin(DirUgol+Alfa);
end;

function TLineZas.BigCalc;
var
	j,i:LongInt;
	Dt1,Dt2:TDot;
   I1,i2:TLineZasItem;
begin
BigCalc:=true;
Dt1:=(TDot.Create(1,1,1));
Dt2:=(TDot.Create(1,1,1));
for I:=0 to Nabor.Count-2 do
	begin
	i1:=Nabor.AT(i);
	for j:=i+1 to Nabor.Count-1 do
		begin
		i2:=Nabor.At(j);
		if not SmallCalc(i1,i2,Dt1,Dt2) then
			begin
			BigCalc:=false;
			Dt1.Free;
			Dt2.Free;
         exit;
         end;
		if Dist(Pd,Dt1)<Dist(Pd,Dt2) then
			begin
			PD.XDot:=(PD.XDot*PD.What+Dt1.XDot)/(PD.What+1);
			PD.YDot:=(PD.YDot*PD.What+Dt1.YDot)/(PD.What+1);
			inc(PD.What)
			end
		else
			begin
			PD.XDot:=(PD.XDot*PD.What+Dt2.XDot)/(PD.What+1);
			PD.YDot:=(PD.YDot*PD.What+Dt2.YDot)/(PD.What+1);
			inc(PD.What)
         end;
		end;
	end;
Dt1.Free;
Dt2.Free;
end;

Procedure TLineZas.Draw;
var
	DT1,Dt2:TDot;
	i:LongInt;
	Pen,OldPen:hPen;
   x1,y1,x2,y2:LongInt;
begin
Dt1:=(TDot.Create(1,1,1));
if not calc(Dt1) then
	begin
	Dt1.Free;
   exit;
   end;
Pen:=createPen(ps_Solid,1,RGBToCol(255,0,0));
OldPen:=SelectObject(DC,Pen);
x1:=Round(Dt1.XDot*MX);y1:=Round(Dt1.YDot*MY);
Arc(DC,x1-2,y1-2,x1+2,y1+2,0,0,0,0);
for i:=0 to Nabor.count-1 do
	begin
	Dt2:=TLineZasItem(Nabor.At(i)).Dot;
	x2:=Round(Dt2.XDot*MX);y2:=Round(Dt2.YDot*MY);
	RectAngle(DC,x2-4,y2-4,x2+4,y2+4);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);
   MoveTo(DC,x1,y1);LineTo(DC,x2,y2);
   end;
SelectObject(DC,OldPen);
DeleteObject(Pen);
Dt1.Free;
end;

Procedure TLineZas.AddItem;
begin
	Nabor.Insert(TLineZasItem.Create(x,y,s));
end;
{----------------------------------------------}
Constructor TInterLine.Create;
begin
 if L1D1=nil then Exit;
  Line1Dot1:=(TDot.Create(L1D1.XDot,L1D1.YDot,0));
  Line1Dot2:=(TDot.Create(L1D2.XDot,L1D2.YDot,0));
  Line2Dot1:=(TDot.Create(L2D1.XDot,L2D1.YDot,0));
  Line2Dot2:=(TDot.Create(L2D2.XDot,L2D2.YDot,0));
end;

Destructor TInterLine.Destroy;
begin
 if Line1Dot1=nil then Exit;
	Line1Dot1.Free;
	Line1Dot2.Free;
	Line2Dot1.Free;
	Line2Dot2.Free;
end;

Constructor TInterLine.Load;
begin
	Line1Dot1:=TDot(ST.Get);
	Line1Dot2:=TDot(ST.Get);
	Line2Dot1:=TDot(ST.Get);
	Line2Dot2:=TDot(ST.Get);
end;

Procedure TInterLine.Store;
begin
	ST.Put(Line1Dot1);
	ST.Put(Line1Dot2);
	ST.Put(Line2Dot1);
	ST.Put(Line2Dot2);
end;

Procedure TInterLine.Calc;
var
	a1,b1,a2,b2:extended;
	procedure GetAB(d1,d2:TDot;var A,B:extended);
	begin
		if (D2.XDot-D1.XDot)<>0 then
      	begin
			A:=(D2.YDot-D1.YDot)/(D2.XDot-D1.XDot);
			B:=D2.YDot-A*D2.XDot;
         end
		else
			begin
			A:=999999999999999999999999999.99;
			B:=0
         end;
	end;
begin
	GetAB(Line1Dot1,Line1Dot2,a1,b1);
	GetAB(Line2Dot1,Line2Dot2,a2,b2);
	if (a1-a2)<>0 then
		begin
		 PD.XDot:=(b2-b1)/(a1-a2);
		 PD.YDot:=a1*PD.XDot+b1;
		end
	else
   	begin
		PD.Free;
		PD:=nil;
      end;
end;

Function TInterLine.Calc2;
 var t,o:Double;x1,y1,x2,y2,xa,ya,xb,yb:Double;
 Function Intersect:Boolean;
 begin
  // Writeln('Inter = ',intersection_straight_lines(x1,y1,x2,y2,xa,ya,xb,yb,t,o));
  if intersection_straight_lines(x1,y1,x2,y2,xa,ya,xb,yb,t,o)=1 then
   begin
    if not(Otr) or ((Round(t*Const_Of_PrecCoord)>=0) and (Round(t*Const_Of_PrecCoord)<=Const_Of_PrecCoord)
       and (Round(o*Const_Of_PrecCoord)>=0) and (Round(o*Const_Of_PrecCoord)<=Const_Of_PrecCoord)) then
     begin
      PD.XDot:=xa+(xb-xa)*t;
      PD.YDot:=ya+(yb-ya)*t;
      Result:=True;
     end else Result:=False;
   end else Result:=False;
 end;
 begin
  x1:=Line1Dot1.XDot;x2:=Line1Dot2.XDot;
  y1:=Line1Dot1.YDot;y2:=Line1Dot2.YDot;
  xa:=Line2Dot1.XDot;xb:=Line2Dot2.XDot;
  ya:=Line2Dot1.YDot;yb:=Line2Dot2.YDot;
  Result:=Intersect;
  if not Result then begin PD.Free;PD:=nil;end;
 end;

Procedure TInterLine.Draw;
var
	x1,y1,x2,y2:LongInt;
	Dot:TDot;
   Pen,OldPen:hPen;
begin
	Dot:=(TDot.Create(0,0,0));
	Calc(Dot);
	if Dot=nil then
		begin
      exit;
		end;
	Pen:=createPen(ps_Dash,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);
	x1:=round(Dot.XDot*MX);y1:=round(Dot.YDot*MY);
	x2:=round(Line1Dot1.XDot*MX);y2:=round(Line1Dot1.YDot*MY);
	MoveTo(DC,X2,y2);
	LineTo(DC,X1,Y1);
	x2:=round(Line2Dot1.XDot*MX);y2:=round(Line2Dot1.YDot*MY);
	LineTo(DC,X2,Y2);
	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	Pen:=createPen(ps_solid,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);
	Arc(DC,x1-2,y1-2,x1+2,y1+2,0,0,0,0);
	x1:=round(Line1Dot1.XDot*MX);y1:=round(Line1Dot1.YDot*MY);
	x2:=round(Line1Dot2.XDot*MX);y2:=round(Line1Dot2.YDot*MY);
	RectAngle(DC,x2-4,y2-4,x2+4,y2+4);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);
	RectAngle(DC,x1-4,y1-4,x1+4,y1+4);
	RectAngle(DC,x1-2,y1-2,x1+2,y1+2);
	MoveTo(DC,X2,y2);
	LineTo(DC,X1,Y1);

	x1:=round(Line2Dot1.XDot*MX);y1:=round(Line2Dot1.YDot*MY);
	x2:=round(Line2Dot2.XDot*MX);y2:=round(Line2Dot2.YDot*MY);
	RectAngle(DC,x2-4,y2-4,x2+4,y2+4);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);
	RectAngle(DC,x1-4,y1-4,x1+4,y1+4);
	RectAngle(DC,x1-2,y1-2,x1+2,y1+2);
	MoveTo(DC,X2,y2);
	LineTo(DC,X1,Y1);

	SelectObject(DC,OldPen);
	DeleteObject(Pen);
end;
{----------------------------------------------}
{===========================================================================}
function PolarDlg;
{var
	PD:PPolarDlg;}
begin
(*PD:=new(PPolarDlg,Create(AParent,Dist,Ang,RA));
if Application.ExecDialog(PD)=id_Ok then
	begin
{	Dist:=PD.Distanse;
	Ang:=PD.Angle;
	RA:=PD.RightAngle;}
	PolarDlg:=id_Ok;
	end;*)
end;
{===========================================================================}
function PerpendDlg;
{var
	PD:PPerpendDlg;}
begin
(*	PD:=new(PPerpendDlg,Create(AParent,Dist1,Dist2));
	if Application.ExecDialog(PD)=id_Ok then
		PerpendDlg:=id_Ok;*)
end;
{===========================================================================}
{===========================================================================}
function LineZasDlg;
{var
	PD:PLineZasDlg;}
begin
(*	LineZasDlg:=id_Cancel;
	PD:=new(PLineZasDlg,Create(AParent,Coll));
	if Application.ExecDialog(PD)=id_Ok then
		LineZasDlg:=id_Ok;*)
end;
{===========================================================================}
{----------------------------------------------}
Constructor TPerpend.Create;
begin
	Dot1:=(TDot.Create(D1.XDot,D1.YDot,0));
	Dot2:=(TDot.Create(D2.XDot,D2.YDot,0));
	Dist1:=Ds1;
	Dist2:=Ds2;
end;

Destructor TPerpend.Destroy;
begin
	Dot1.Free;
	Dot2.Free;
end;

Constructor TPerpend.Load;
begin
	Dot1:=TDot(ST.Get);
	Dot2:=TDot(ST.Get);
	ST.read(Dist1,SizeOF(Dist1));
	ST.read(Dist2,SizeOF(Dist2));
	ST.read(RA,SizeOF(RA));
end;

Procedure TPerpend.Store;
begin
	ST.Put(Dot1);
	ST.Put(Dot2);
	ST.write(Dist1,SizeOF(Dist1));
	ST.write(Dist2,SizeOF(Dist2));
	ST.write(RA,SizeOF(RA));
end;

Procedure TPerpend.Calc;
var
	Angle:extended;
begin
	Angle:=Atan2(Dot1.Ydot-Dot2.Ydot,Dot1.Xdot-Dot2.Xdot)-Pi/2;
	PD2.XDot:=Dot1.XDot-Dist1*cos(Angle);
	PD2.YDot:=Dot1.YDot+Dist1*sin(Angle);
	Angle:=Angle+Pi/2;
	PD1.XDot:=PD2.XDot-Dist2*cos(Angle);
	PD1.YDot:=PD2.YDot+Dist2*sin(Angle);
end;

Procedure TPerpend.Draw;
var
	x1,y1,x2,y2:LongInt;
	x3,y3,x4,y4:LongInt;
	PDT1,PDT2:TDot;
	Pen,OldPen:hPen;
begin
	Pen:=CreatePen(ps_solid,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);

	PDt1:=(TDot.Create(0,0,0));
	PDt2:=(TDot.Create(0,0,0));

	x1:=round(Dot1.XDot*MX);
	y1:=round(Dot1.YDot*MY);
	RectAngle(DC,x1-2,y1-2,x1+2,y1+2);
	RectAngle(DC,x1-4,y1-4,x1+4,y1+4);
	x2:=round(Dot2.XDot*MX);
	y2:=round(Dot2.YDot*MY);
	RectAngle(DC,x2-2,y2-2,x2+2,y2+2);
	Calc(PDt1,PDt2);
	x3:=round(PDt1.XDot*MX);
	y3:=round(PDt1.YDot*MY);
	x4:=round(PDt2.XDot*MX);
	y4:=round(PDt2.YDot*MY);
	MoveTo(DC,x1,y1);
	LineTo(Dc,x4,y4);
	LineTo(Dc,x3,y3);
	Arc(DC,x3-2,y3-2,x3+2,y3+2,0,0,0,0);

	SelectObject(DC,OldPen);
	DeleteObject(Pen);
	Pen:=CreatePen(ps_dot,1,RGBToCol(255,0,0));
	OldPen:=SelectObject(DC,Pen);

	MoveTo(DC,x4,y4);
	LineTo(Dc,x2,y2);

	PDt1.Free;
	PDt2.Free;

	SelectObject(DC,OldPen);
	DeleteObject(Pen);
end;
{===========================================================================}
begin
{	RegisterType(RStvor);
	RegisterType(RPolar);
	RegisterType(RLineZas);
}
end.
