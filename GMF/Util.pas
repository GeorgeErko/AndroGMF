unit Util;

interface

uses SysUtils,Classes, math;


type
lpoint=record
        x,y:Double;
       end;

function dist(var a,b: lpoint): Extended;
{¬озвращает рассто€ние между точками а и b}

procedure set_otr_dl(var Va,Vb: lpoint;  R: Extended);
{”станавливает длину отрезка Vа,Vb равную R, путем передвижени€ точки Vb}

function perpend(var P0,P00,P1,P2: lpoint): Boolean;
{‘-€ опускает перпендикул€р из точки P0 на пр€мую(P1,P2). –00 - полученна€ точка.
   =true  - P00 лежит на отрезке (P1,P2)
   =false - P00 не лежит на отрезке (P1,P2)}

function line_okruzh_dist(var P0,P1,P2: lpoint; var R,D:double): Boolean;
{‘-€ определ€ет рассто€ние от пр€мой (P1,P2) до окружности  с центром P0 и радиусом R. D - рассто€ние.
   =true  - окружность пересекает пр€мую
   =false - окружность и пр€ма€ не пересекаютс€}

function line_okruzh_peres(var P0,P01,P02, P1,P2: lpoint; R:double): Boolean;
{‘-€ находит точки пересечени€ пр€мой (P1,P2) и окружности  с центром P0 и радиусом R.
–1, –2 - точки пересечени€.
   =true  - окружность пересекает пр€мую
   =false - окружность и пр€ма€ не пересекаютс€}

   
implementation


function dist(var a,b: lpoint): Extended;
{¬озвращает рассто€ние между точками а и b}
var
dx,dy: Extended;
begin
dx:=a.x-b.x;
dy:=a.y-b.y;
Result:=sqrt(sqr(dx)+sqr(dy));
end;

procedure set_otr_dl(var Va,Vb: lpoint;  R: Extended);
{”станавливает длину отрезка Vа,Vb равную R, путем передвижени€ точки Vb}
var
L12,k : Extended;
begin
L12:=dist(Va,Vb);
if R=L12 then EXIT;

if R<L12 then
  begin
    k:=R/(L12-R);
    Vb.x:=((Va.x+k*Vb.x)/(1+k));
    Vb.y:=((Va.y+k*Vb.y)/(1+k));
  end;
if R>L12 then
  begin
    k:=L12/(R-L12);
    if K=0 then begin
     Vb.x:=(1+k)*Vb.x-Va.x;
     Vb.y:=(1+k)*Vb.y-Va.y;
    end else begin
     Vb.x:=(((1+k)*Vb.x-Va.x)/k);
     Vb.y:=(((1+k)*Vb.y-Va.y)/k);
    end;
  end;
end;

function perpend(var P0,P00,P1,P2: lpoint): Boolean;
{‘-€ опускает перпендикул€р из точки P0 на пр€мую(P1,P2). –00 - полученна€ точка.
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
{‘-€ определ€ет рассто€ние от пр€мой (P1,P2) до окружности  с центром P0 и радиусом R. D - рассто€ние.
   =true  - окружность пересекает пр€мую
   =false - окружность и пр€ма€ не пересекаютс€}
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
{‘-€ находит точки пересечени€ пр€мой (P1,P2) и окружности  с центром P0 и радиусом R.
–1, –2 - точки пересечени€.
   =true  - окружность пересекает пр€мую
   =false - окружность и пр€ма€ не пересекаютс€}
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
