Unit NotLink_;
{--------------------------------------------------------------}
Interface  Uses Collect, ECdot,WPTwigs, newSelector, newSettings, Maths_Basic;
{--------------------------------------------------------------}

type
	TWorkPere=class(TTwgObject)
		X,Y:Double;
		Twig1,Twig2:LongInt;
                Seg1,Seg2:Integer;
                Twigs:PCollection;
                Rasst:Double;
		constructor Create(a,b:double;n1,n2:longint;s1,s2:Integer);
		constructor CreateRasst(a,b,R:double;s1,s2:Integer);
                procedure Draw(DC:Hdc;MX,MY:single;dx,dy:Double);
	end;

        TLineNesost=class(TTwgObject)
               X,Y,XP,YP:double;
               Dot:TDot;TwigXY,TwigXYP:Integer;
               DotInd:Integer;
               Rasst:Double;
               Constructor Create(X1,Y1:Double;D:TDot;TInd,TIndP,DI:Integer;S:Double);
               Procedure Rebuild;
               Procedure Draw;
        end;

       TTwigsLink=class(TTwgObject)
               Dot:TDot;
               Points:PCollection;
               Constructor Create(D:TDot);
                Procedure AddPoint(D:TDot);
                Procedure Rebuild(Dt:TDot);
               Destructor Destroy;override;
        end;

function GetPerehlestDlg(var M:byte):SmallInt;
function EditPerehlestDlg(var M:byte;PW:TWorkPere;TW1,TW2:TTwig):SmallInt;
{--------------------------------------------------------------}
Implementation uses FMX.Graphics;
{--------------------------------------------------------------}
function GetPerehlestDlg;
{var
	PD:PPerehlestDlg;}
begin
{GetPerehlestDlg:=-1;
PD:=new(PPerehlestDlg,init(AParent,M));
if Application^.ExecDialog(PD)=Id_Ok then
	GetPerehlestDlg:=M;}
     getPerehlestDlg:=1;
end;
{--------------------------------------------------------------}
function EditPerehlestDlg;
{var
	PD:PEditPerehlestDlg;}
begin
{EditPerehlestDlg:=id_Cancel;
PD:=new(PEditPerehlestDlg,init(AParent,M,PW,Tw1,Tw2));
if Application^.ExecDialog(PD)=Id_Ok then
	EditPerehlestDlg:=id_Ok;}
end;
{--------------------------------------------------------------}
constructor TWorkPere.Create;
begin
X:=a;
Y:=b;
Twig1:=N1;
Twig2:=N2;
Seg1:=s1;
Seg2:=s2;
end;

Constructor TWorkPere.CreateRasst;
 begin
 end;

Procedure TWorkPere.Draw;
begin
// PArc2(X,Y);
end;

{--------------------------------------------------------------}
constructor TLineNesost.Create;
begin
 X:=X1;
 Y:=Y1;
 Dot:=D;
 DotInd:=DI;
 XP:=D.XDot;
 YP:=D.YDot;
 TwigXY:=TInd;TwigXYP:=TIndP;
 Rasst:=S;
end;

Procedure TLineNesost.Rebuild;
begin
 XP:=Dot.XDot;
 YP:=Dot.YDot;
 Rasst:=Distance(XP,YP,X,Y);
end;

Procedure TLineNesost.Draw;
 var C:LongInt;Angle:Single;
begin
{
  GCanvas.Pen.Color:=clRed;
 try
 if PointVis(XP,YP) or PointVis(X,Y) then
  begin
   PMoveTo(XP,YP);
   PLineTo(X,Y);
    Angle:=Direct_Angle(XP,YP,X,Y);
    Angle:=(Angle+Pi)+Pi/4;
   LineTo(GCanvas.Handle,XPix(X)+Round(10*Cos(Angle)),YPix(Y)+Round((10*Sin(Angle))));
   PMoveTo(X,Y);
    Angle:=(Angle+Pi)+Pi/2;
   LineTo(GCanvas.Handle,XPix(X)+Round(10*Cos(Angle)),YPix(Y)+Round((10*Sin(Angle))));
 end;
 finally
 end; }
end;
{--------------------------------------------------------------}
Constructor TTwigsLink.Create;
 begin
  Dot:=D;
  Points:=PCollection.Create(1);
 end;

Procedure TTwigsLink.AddPoint;
 begin
  Points.Insert(D);
 end;

Procedure TTwigsLink.Rebuild;
 var I:Integer;D:TDot;Dist:Double;
 begin
  For I:=Points.Count-1 downTo 0 do
   begin
    D:=Points.At(I);
    Dist:=Distance(Dot.XDot,Dot.YDot,D.XDot,D.YDot);
    If Dt=Dot then Points.AtDelete(I) else
    If (Dist > GGraphset.HardRad/2) or (Round(Dist*Const_Of_PrecCoord)/Const_Of_PrecCoord=0) then
     begin
      Points.AtDelete(I);
     end;
   end;
 end;

Destructor TTwigsLink.Destroy;
 begin
  Points.DeleteAll;Points.Free;
 end;

begin
end.
