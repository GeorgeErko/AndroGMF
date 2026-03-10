Unit EMath;
{$N+}
{==============================================================================}
interface
 const 	Decimal:integer=10;
{Uses GeoConst,WinCrt;}
{==============================================================================}
function Check_Line(XP,YP,x1,y1,x2,y2:integer):boolean;
function Check_Arc(XP,YP,x1,y1,x2,y2,x3,y3,x4,y4:integer):boolean;
function Inter(a,b1,b2:Double):boolean;
function Atan2(dx,dy:Double):single;
function Chet(dx,dy:Double):byte;
procedure swapme(var x,y:Double);far;
{==============================================================================}
Implementation
{==============================================================================}

Procedure SwapMe;
var
 z:Double;
begin
z:=x;
x:=y;
y:=z;
end;
{---------------------------------------------------------}
function Inter;
begin
if b1>b2 then swapMe(b1,b2);
if (a>=b1)and(a<=b2)then Result:=true else Result:=false;
end;
{---------------------------------------------------------}
function Atan2;
var
	u:Double;
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
if (dx<0) and (dy>0) then begin Atan2:=U+Pi;end;
if (dx>0) and (dy<0) then begin Atan2:=U+2*Pi;end;
if (dx<0) and (dy<0) then begin Atan2:=U+Pi;end;
end;

Function Chet(dx,dy:Double):Byte;
begin
 Chet:=1;
 if (dx<0) and (dy>0) then begin Chet:=2;end;
 if (dx>0) and (dy<0) then begin Chet:=3;end;
 if (dx<0) and (dy<0) then begin Chet:=4;end;
end;
{---------------------------------------------------------}
Function Check_Line(XP,YP,x1,y1,x2,y2:integer):boolean;
var
	k:Double;
        x,y:integer;
begin
	Check_Line:=false;
	if (not Inter(xp,x1,x2))or(not Inter(yp,y1,y2)) then exit;
	if (x1=x2)or(y1=y2) then
		begin
		Check_LIne:=true;
		exit;
		end;
	if (y2-y1)<(x2-x1) then
        	begin
		k:=(y2-y1)/(x2-x1);
		y:=round(y1+k*(xp-x1));
		x:=x1+(xp-x1);
		if abs(y-yp)<(4*Decimal/10) then Check_LIne:=true;
		end
	else
		begin
		k:=(x2-x1)/(y2-y1);
		x:=round(x1+k*(yp-y1));
		if abs(x-xp)<(4*Decimal/10) then Check_LIne:=true;
		end;

end;
{---------------------------------------------------------}
Function Check_Arc(XP,YP,x1,y1,x2,y2,x3,y3,x4,y4:integer):boolean;
var
	yr,xc,yc:Double;
	a,b,d,u1,u2,u:Double;
	r1,r2:integer;
begin
	Check_Arc:=false;
	xc:=(x1+x2)/2;
	yc:=(y1+y2)/2;
	a:=abs((x2-x1)/2);
	b:=abs((y2-y1)/2);
	if (abs(yc-yp)>b) or (abs(xc-xp)>a) then exit;
	d:=b*b*sqr(xp-xc)/a/a;
	if d>sqr(b) then exit;
	yr:=sqrt(b*b-d);	
        r1:=round(sqrt(sqr(xp-xc)+sqr(yr)));
	r2:=round(sqrt(sqr(xp-xc)+sqr(yp-yc)));	
	if abs(r1-r2)>(3*Decimal/10) then exit;

	if abs((yc+yr)-yp)<(3*Decimal/10) then
		begin
		u2:=atan2(x3-xc,y3-yc);
		u1:=atan2(x4-xc,y4-yc);
		u:=atan2(xp-xc,yp-yc);
		if u2<u1 then u2:=u2+2*Pi;
		if u1>u then begin
				u2:=u2-2*Pi;
				u1:=u1-2*Pi;
				end;

		if (u>u1) and (u<u2) then Check_Arc:=True;
                exit;
		end;

	if abs((yc-yr)-yp)<(3*Decimal/10) then
		begin
		u2:=atan2(x3-xc,y3-yc);
		u1:=atan2(x4-xc,y4-yc);
		u:=atan2(xp-xc,yp-yc);
		if u2<=u1 then u2:=u2+2*Pi;
		if u1>u then begin
				u2:=u2-2*Pi;
				u1:=u1-2*Pi;
				end;
		
		if (u>u1) and (u<u2) then Check_Arc:=True;
                exit;
		end;
end;
{---------------------------------------------------------}
{==============================================================================}
begin
end.