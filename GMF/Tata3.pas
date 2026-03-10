Unit Tata3;
{============================================================================}
Interface
Uses Collect,ecDot,TwgColle,EMath, polygons;

function OnLine(x,y:Double;D1,D2:TDot;var XP,YP:Double):boolean;
function InContur222(PC:PCollection;X,Y:Double;var B:byte):boolean;
FUNCTION PL      (X1,Y1,X2,Y2,PX,PY:Single):INTEGER;
Function PL2(X11,Y11,X12,Y12,X21,Y21,X22,Y22:Single;var X1,Y1:Single):SmallInt;
function InContur333(P:PCollection;PointX,PointY:single;var What:byte):boolean;
{============================================================================}
Implementation
{function TSC.Compare;
begin
if round(PDot(Key1).XDot*1000)<round(PDot(Key2).XDot*1000) then compare:=-1;
if round(PDot(Key1).XDot*1000)=round(PDot(Key2).XDot*1000) then compare:=0;
if round(PDot(Key1).XDot*1000)>round(PDot(Key2).XDot*1000) then compare:=1;
end;
}
{----------------------------------------------------------------------}

function OnLine;
begin
	OnLine:=False;
	if D2.YDot=D1.YDot then
		begin
		exit;
		end;
	XP:=D1.XDot+(D2.XDot-D1.XDot)*(Y-D1.YDot)/(D2.YDot-D1.YDot);
	YP:=Y;
	if Inter(X,D2.XDot,D1.XDot)and Inter(Y,D2.YDot,D1.YDot) then
        if XP=X then OnLine:=true;
end;

{------------------------------------------------------}
function InContur222;
var
	i:Integer;
	Dot1,Dot2:TDot;
	X1,Y1:Double;
        UpSec,BotSec:Integer;
begin
{UpSec:=Point_And_Polygon(X,Y,PC);
 Result:=(UpSec=0) or (UpSec=1);}
 Result:=Point_Inside_Polygon(X,Y,PC)>-1;
{
UpSec:=0;BotSec:=0;
Result:=false;
for i:=0 to PC.Count-2 do
	begin
	Dot1:=PC.At(i);Dot2:=PC.At(i+1);
	if OnLine(x,y,Dot1,Dot2,x1,y1) then
		begin
		Result:=true;
		b:=2;
		exit;
		end
	else
		begin
		if Inter(X1,Dot1.XDot,Dot2.XDot)and Inter(Y1,Dot1.YDot,Dot2.YDot) then
			begin
                         if X>X1 then Inc(BotSec) else Inc(UpSec);
			end;
        end;
       end;
if Odd(UpSec) or Odd(BotSec) then Result:=True;
}
end;

{============================================================================}
FUNCTION  PL      (X1,Y1,X2,Y2,PX,PY:Single):INTEGER;
VAR
  H:INTEGER;
  CDUG,A,B,A1,B1,DX,DY,DYL:Single;
{    (А,В)-КООРДИНАТЫ ВЕКТОРА АВ                            }
{    (А1,В1)-КООРДИНАТЫ ВЕКТОРА С                           }
{    CDUG-КОСИНУС УГЛА МЕЖДУ ВЕКТОРАМИ                      }
{    DYL-РАССТОЯНИЕ ОТ ТОЧКИ Р ДО ВЕРТИКАЛЬНОГО ВЕКТОРА С   }
{    DY-РАССТОЯНИЕ ОТ ОТРЕЗКА АВ ДО ВЕРТИКАЛЬНОГО ВЕКТОРА С }
{    PL=1 - ТОЧКА Р ЛЕЖИТ СПРАВА ОТ ОТРЕЗКА АВ, ВНУТРИ      }
{    PL=2 - ТОЧКА Р ЛЕЖИТ НА ОТРЕЗКЕ АВ                     }
{    PL=3 - ТОЧКА Р ЛЕЖИТ СЛЕВА ОТ ОТРЕЗКА АВ               }
{    PL=4 - ОТРЕЗОК АВ: ЛИБО || OY,ЛИБО ТОЧКА               }
BEGIN{*-------- PL --------*}
  CDUG:=0; DY:=0;
{-------------------------------------------------------------}
{         ОПРЕДЕЛЕНИЕ   ПОЛОЖЕНИЯ   ОТРЕЗКА   АВ              }
{-------------------------------------------------------------}
  IF(Y1<Y2) AND (X1<X2) THEN
                           BEGIN
                            H:=1;
                               A:=Y2-Y1;
                               B:=X2-X1;
                               B1:=X2-X1;
                               DX:=ABS(PX-X1);
                               DYL:=ABS(PY-Y1);
 END
     ELSE IF (Y1<Y2) AND (X1>X2) THEN
                                  BEGIN
                                   H:=4;
                                  A:=Y2-Y1;
                                  B:=X2-X1;
                                  B1:=X2-X1;
                                  DX:=ABS(PX-X1);
                                  DYL:=ABS(PY-Y1);
     END
      ELSE IF(Y1>Y2) AND (X1>X2) THEN
                                  BEGIN
                                   H:=2;
                                  A:=Y1-Y2;
                                  B:=X1-X2;
                                  B1:=X1-X2;
                                  DX:=ABS(PX-X2);
                                  DYL:=ABS(PY-Y2);
 END
       ELSE IF(Y1>Y2) AND (X1<X2) THEN
                                   BEGIN
                                    H:=3;
                                    A:=Y1-Y2;
                                    B:=X1-X2;
                                    B1:=X1-X2;
                                    DX:=ABS(PX-X2);
                                    DYL:=ABS(PY-Y2);
                                   END
 {--------------------------------------------------------------------}
 { АВ || ОХ.   ОПРЕДЕЛЕНИЕ ПОЛОЖЕНИЯ ТОЧКИ Р ОТНОСИТЕЛЬНО ОТРЕЗКА АВ  }
 {--------------------------------------------------------------------}
     ELSE IF Y1=Y2
     THEN
      BEGIN
       IF (PY>Y1) AND ((X1<=PX) AND (PX<=X2) OR (X2<=PX) AND (PX<=X1))
        THEN PL:=1
       ELSE IF (PY=Y1) AND ((X1<=PX) AND (PX<=X2) OR (X2<=PX) AND (PX<=X1))
             THEN PL:=2
             ELSE PL:=3;
           Exit;
      END
          ELSE BEGIN
                PL:=4;
                EXIT
               END;
 {-------------------------------------------------------------}
 {    ОПРЕДЕЛЕНИЕ ПОЛОЖЕНИЯ ТОЧКИ Р ОТНОСИТЕЛЬНО ОТРЕЗКА АВ    }
 {-------------------------------------------------------------}
    IF ((X1<=PX) AND (PX<=X2) OR (X2<=PX) AND (PX<=X1)) AND
     (((H=1) OR (H=4)) AND (Y1<=PY) OR ((H=2) OR (H=3)) AND (Y2<=PY))
    THEN
     BEGIN
      CDUG:=(A*A1+B*B1)/(SQRT(SQR(A)+SQR(B))*SQRT(SQR(A1)+SQR(B1)));
       DY:=DX*(SQRT(1-SQR(CDUG))/CDUG);
        IF DY<DYL THEN PL:=1
         ELSE IF (DY>DYL) OR (DY>DYL) AND ((PX=X1) OR (PX=X2))
              THEN PL:=3
				  ELSE IF (DY=DYL) OR ((ABS(PX-X1)=DX) OR (ABS(PX-X2)=DX))
				  THEN  PL:=2;
     END
    ELSE  PL:=3;
END;{*--------- PL --------*}

   Function pl2;
    var Dx1,Dy1,Dx2,Dy2,X,Y,A,C,B,D,Dxx1:Double;
     YMax,XMax,XMin,YMin:Double;
  begin
    If X11>X12 then begin XMax:=X11;XMin:=X12 end else begin XMax:=X12;XMin:=X11;end;
    If Y11>Y12 then begin YMax:=Y11;YMin:=Y12; end else begin YMax:=Y12;YMin:=Y11;end;
  If X21>XMax then begin pl2:=0;exit;end;
  If (Y21>Ymin) and (Y21<YMax) then begin Pl2:=0;Exit;end;
    Dx1:=X11-X12;Dx2:=X21-X22;
    Dy1:=Y11-Y12;Dy2:=Y21-Y22;
    Dxx1:=Dx1;
    If DX1=0 then begin DX1:=0.01;end;
    If Dy1=0 then begin DY1:=0.01;end;
    If Dy2=0 then
     begin
       Y:=Y21;
       A:=DY1/DX1;
       B:=Y11-A*X11;
       X:=(Y-B)/A;
     end else
    If Dx2=0 then
      begin
        X:=X21;
        A:=DY1/DX1;
        B:=Y11-A*X11;
        Y:=A*X+B;
       end else
      begin
       A:=DY1/DX1;C:=DY2/DX2;
       B:=Y11-A*X11;D:=Y22-C*X22;
       If A-C=0 then begin PL2:=0;exit;end;
       X:=Abs(D-B)/Abs(A-C);
       Y:=A*X+B;
     end;
      X1:=X;Y1:=Y;
      Pl2:=1;
    end;


Function InContur333(P:PCollection;PointX,PointY:Single;var What:Byte):Boolean;
 var I:Integer;J:Integer;P1,P2:TDot;IncOn:Integer;
      D,D2:Single;
 begin
	IncOn:=0;
  // PMoveTo(PointX,PointY);PLineTo(PointX+10000,PointY);
  For I:=0 To P.Count-1 do
    begin
     P1:=TDot(P.At(I));
    end;
  For I:=0 To P.Count-2 do
    begin
     P1:=TDot(P.At(I));
     P2:=TDot(P.At(I+1));
	  J:=Pl2(P1.XDot,P1.YDot,P2.XDot,P2.YDot,PointX,PointY,PointX+100000,PointY,D,D2);
     If (J<>0) then begin
						  Inc(IncOn);
                   end;
      If (J=2) then begin
							InContur333:=True;
							 What:=2;
                     exit;
							end
		 end;

	 What:=0;
	 If Odd(IncOn) then InContur333:=True else InContur333:=False;
 end;

begin
end.
