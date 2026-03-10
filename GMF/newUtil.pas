UNIT newUtil;

INTERFACE

USES SysUtils;


TYPE
lpoint=record
        x,y:Double;
       end;

function dist(var a,b: lpoint): Extended;
{Возвращает расстояние между точками а и b}

procedure set_otr_dl(var Va,Vb: lpoint;  R: Extended);
{Устанавливает длину отрезка Vа,Vb равную R, путем передвижения точки Vb}

function perpend(var P0,P00,P1,P2: lpoint): Boolean;
{Ф-я опускает перпендикуляр из точки P0 на прямую(P1,P2). Р00 - полученная точка.
   =true  - P00 лежит на отрезке (P1,P2)
   =false - P00 не лежит на отрезке (P1,P2)}

function line_okruzh_dist(var P0,P1,P2: lpoint; var R,D:double): Boolean;
{Ф-я определяет расстояние от прямой (P1,P2) до окружности  с центром P0 и радиусом R. D - расстояние.
   =true  - окружность пересекает прямую
   =false - окружность и прямая не пересекаются}

function line_okruzh_peres(var P0,P01,P02, P1,P2: lpoint; R:double): Boolean;
{Ф-я находит точки пересечения прямой (P1,P2) и окружности  с центром P0 и радиусом R.
Р1, Р2 - точки пересечения.
   =true  - окружность пересекает прямую
   =false - окружность и прямая не пересекаются}


IMPLEMENTATION


function dist(var a,b: lpoint): Extended;
{Возвращает расстояние между точками а и b}
var
dx,dy: Extended;
begin
dx:=a.x-b.x;
dy:=a.y-b.y;
Result:=sqrt(sqr(dx)+sqr(dy));
end;

procedure set_otr_dl(var Va,Vb: lpoint;  R: Extended);
{Устанавливает длину отрезка Vа,Vb равную R, путем передвижения точки Vb}
var
L12,k : Extended;
begin
L12:=dist(Va,Vb);
IF R=L12 THEN EXIT;

IF R<L12 THEN
  begin
    k:=R/(L12-R);
    Vb.x:=((Va.x+k*Vb.x)/(1+k));
    Vb.y:=((Va.y+k*Vb.y)/(1+k));
  end;
IF R>L12 THEN
  begin
    k:=L12/(R-L12);
    If K=0 then begin
     Vb.x:=(1+k)*Vb.x-Va.x;
     Vb.y:=(1+k)*Vb.y-Va.y;
    end else begin
     Vb.x:=(((1+k)*Vb.x-Va.x)/k);
     Vb.y:=(((1+k)*Vb.y-Va.y)/k);
    end;
  end;
end;

function perpend(var P0,P00,P1,P2: lpoint): Boolean;
{Ф-я опускает перпендикуляр из точки P0 на прямую(P1,P2). Р00 - полученная точка.
   =true  - P00 лежит на отрезке (P1,P2)
   =false - P00 не лежит на отрезке (P1,P2)}
var
dx,dy,R_R,t: double;
begin
dx:=P1.x-P2.x;
dy:=P1.y-P2.y;
R_R:=sqr(dx)+sqr(dy);
if R_R =0 then begin
  Result:=(abs(P0.x-P1.x)+abs(P0.y-P1.y))=0;
  P00:=P1;
  exit
end;
t:=dx*(P0.x-P2.x)+dy*(P0.y-P2.y);
t:=t/R_R;

Result:=(t>=0)and(t<=1);
P00.x:=P2.x+(dx*t);
P00.y:=P2.y+(dy*t);
end;

function line_okruzh_dist(var P0,P1,P2: lpoint; var R,D:double): Boolean;
{Ф-я определяет расстояние от прямой (P1,P2) до окружности  с центром P0 и радиусом R. D - расстояние.
   =true  - окружность пересекает прямую
   =false - окружность и прямая не пересекаются}
var
dx,dy,R_R,t: double;
P00:lpoint;
begin       
perpend(P0,P00,P1,P2);
D:=dist(P0,P00);
Result:=(D<=R);
D:=D-R;
end;

function line_okruzh_peres(var P0,P01,P02, P1,P2: lpoint; R:double): Boolean;
{Ф-я находит точки пересечения прямой (P1,P2) и окружности  с центром P0 и радиусом R.
Р1, Р2 - точки пересечения.
   =true  - окружность пересекает прямую
   =false - окружность и прямая не пересекаются}
var
dx,dy,R_R,t,D: double;
P00:lpoint;
begin
perpend(P0,P00,P1,P2);
D:=dist(P0,P00);
if D<=R then begin
Result:=true;
P01:=P1;
set_otr_dl(P00,P01,sqrt(sqr(R)-sqr(D)));
P02:=P2;
set_otr_dl(P00,P02,sqrt(sqr(R)-sqr(D)));
             end
        else Result:=false;
end;

END.
