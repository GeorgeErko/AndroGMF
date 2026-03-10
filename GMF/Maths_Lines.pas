unit Maths_Lines;

interface

uses Collect, maths_basic;

 //возвращает растояние от точки [X0_,Y0_] до прямой,проходящей через точки [X1_,Y1_] и [X2_,Y2_]
 function Dist_Point_Line(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double;
 //возвращает растояние от точки [X0_,Y0_] до прямой,проходящей через точки [X1_,Y1_] и [X2_,Y2_],
 //и точку(x,y) пересечения исходной прямой и прямой, проходящей через точку [X0_,Y0_] и перпендикулярной исходной
 function DistPoint_Point_Line(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double;
 //возвращает расстояние от точки [X0_,Y0_] до отрезка ([X1_,Y1_] ; [X2_,Y2_])
 function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double;
 //возвращает растояние от точки [X0_,Y0_] до отрезка ([X1_,Y1_] ; [X2_,Y2_])
 //и точку(x,y) пересечения исходной прямой и прямой, проходящей через точку [X0_,Y0_] и перпендикулярной исходной
 //если пересечения нет то возвращает ближайшую из точек [X1_,Y1_], [X2_,Y2_]
 function DistPoint_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double;
 //возвращает новые координаты(XR_,YR_) точки (X0_,Y0_) повёрнутой относителтно точки (X_,Y_) на угол Angle_
 procedure RotateXY(Angle_,X_,Y_,X0_,Y0_:double;var XR_,YR_:double);
 //поворачивает коллекцию Points_ относительно точки(X_,Y_) на угол(Angle_)
 procedure RotatePoints(Angle_,X_,Y_:double;Points_:PCollection;XK:Double=1;YK:Double=1);
 //возвращает повернутую коллекцию Points_ относительно точки(X_,Y_) на угол(Angle_)
 function RotatePointsCol(Angle_,X_,Y_:double;Points_:PCollection):PCollection;
implementation

function Dist_Point_Line(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
begin
  if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B));
end;

function DistPoint_Point_Line(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
begin
  if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B));

  y:=(sqr(A)*Y0_-B*C-A*B*X0_)/(sqr(A)+sqr(B));
  if A<>0 then x:=-(B*y+C)/A
  else x:=X0_;
end;

function Dist_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
    s1,s2:double;//растояние до концов отрезка, используется если точка не принадлежит отрезку
    x,y:double;//точка пересечения
begin
  if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  y:=(sqr(A)*Y0_-B*C-A*B*X0_)/(sqr(A)+sqr(B));
  if A<>0 then x:=-(B*y+C)/A
  else x:=X0_;

  if ((x>=X1_)and(x<=X2_))or((x>=X2_)and(x<=X1_))then
    if ((y>=Y1_)and(y<=Y2_))or((y>=Y2_)and(y<=Y1_)) then
      result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B))
    else begin
      s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
      s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
      if s1<=s2 then result:=s1 else result:=s2;
    end
  else begin
    s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
    s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
    if s1<=s2 then result:=s1 else result:=s2;
  end;
end;



function DistPoint_Point_Edge(X0_,Y0_,X1_,Y1_,X2_,Y2_:double;var x,y:double):double;
var A,B,C:double;//Ax+By+C=0 уравнение прямой
    s1,s2:double;//растояние до концов отрезка, используется если точка не принадлежит отрезку
begin
if X1_<>X2_ then begin
    A:=(Y2_-Y1_)/(X2_-X1_);
    B:=-1;
    C:=Y1_-X1_*(Y2_-Y1_)/(X2_-X1_);end
  else begin
    A:=1;B:=0;C:=-X1_;end;

  y:=(sqr(A)*Y0_-B*C-A*B*X0_)/(sqr(A)+sqr(B));
  if A<>0 then x:=-(B*y+C)/A
  else x:=X0_;

  if ((x>=X1_)and(x<=X2_))or((x>=X2_)and(x<=X1_))then
    if ((y>=Y1_)and(y<=Y2_))or((y>=Y2_)and(y<=Y1_)) then
      result:=abs(A*X0_+B*Y0_+C)/sqrt(sqr(A)+sqr(B))
    else begin
      s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
      s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
      if s1<=s2 then begin
        result:=s1;
        x:=X1_;y:=Y1_;end
      else begin
        result:=s2;
        x:=X2_;y:=Y2_;end
    end
  else begin
    s1:=sqrt(sqr(X0_-X1_)+sqr(Y0_-Y1_));
    s2:=sqrt(sqr(X0_-X2_)+sqr(Y0_-Y2_));
    if s1<=s2 then begin
      result:=s1;
      x:=X1_;y:=Y1_;end
    else begin
      result:=s2;
      x:=X2_;y:=Y2_;end
  end;
end;

procedure RotateXY(Angle_,X_,Y_,X0_,Y0_:double;var XR_,YR_:double);
var R,Angle:double;
begin
 R:=sqrt(sqr(X_-X0_)+sqr(Y_-Y0_));
 Angle:=direct_angle(X_,Y_,X0_,Y0_);
 Angle:=Angle+Angle_;
 XR_:=X_+R*cos(Angle);
 YR_:=Y_+R*sin(Angle);
end;

type
 TDot = class(TTwgObject)
  X,Y,Z:Double;
 end;

procedure RotatePoints(Angle_,X_,Y_:double;Points_:PCollection;XK:Double=1;YK:Double=1);
var R,Angle,x,y:double;
    Dot:TDot;
    i:integer;
begin
 for i:=0 to Points_.Count-1 do begin
  Dot:=Points_[i];
  R:=sqrt(sqr(Dot.X-X_)+sqr(Dot.Y-Y_));
  Angle:=direct_angle(X_,Y_,Dot.X,Dot.Y)+Angle_;
  Dot.X:=X_+(R)*cos(Angle);
  Dot.Y:=Y_+(R)*sin(Angle);
 end;
end;

function RotatePointsCol(Angle_,X_,Y_:double;Points_:PCollection):PCollection;
var R,Angle,x,y:double;
    Dot,Dot_Add:TDot;
    i:integer;
    P_:PCollection;
begin
 P_:=PCollection.Create(1);
 for i:=0 to Points_.Count-1 do begin
  Dot:=Points_[i];
  R:=sqrt(sqr(Dot.X-X_)+sqr(Dot.Y-Y_));
  Angle:=direct_angle(X_,Y_,Dot.X,Dot.Y)+Angle_;
  Dot_Add:=TDot.Create;
  Dot_Add.X:=X_+R*cos(Angle);
  Dot_Add.Y:=Y_+R*sin(Angle);
  P_.Insert(Dot_Add);
 end;
 Result:=P_;
// P_.Free;
end;

end.
