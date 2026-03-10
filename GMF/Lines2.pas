Unit Lines2;
{=============================================================}
Interface
{=============================================================}
Uses Collect, SysUtils, Lib, TwgDraw, EcDot,
     Maths_Basic, Lines3;

type
 hDc = Integer;

var
 GlobalLine:TGeoLine;

{-------------------------------------------------}
procedure DevDrawGeoLine(DC:hdc;GL:TGeoLine;PCTwig:PCollection;PC2:TSortedCollection;Ko,MXX,MYY:single;R,G,B:byte;Flag:SmallInt;
	XGeoCent,YGeoCent:Single;XPrintCent,YPrintCent:SmallInt;KoPoint:Single;MakeUsel:Boolean;ZDx:Single;LineWidth:Single);
{-------------------------------------------------}
 Type

   { LLIB }

   LLIB=Class(PLib)
    Function Compare(Key1,Key2:Pointer):Integer;override;
    end;

function SearchLine(PC:TSortedCollection;Num:Integer):SmallInt;
{=============================================================}
Implementation

function LLIB.Compare(Key1, Key2: Pointer): Integer;
begin
 If TGeoLine(Key1).idNum < TGeoLine(Key2).idNum then Result:=-1 else
 If TGeoLine(Key1).idNum = TGeoLine(Key2).idNum then Result:=-0 else Result:=1;
end;
{-------------------------------------------------}

function SearchLine;
var
   p:TGeoLine;
   i:Integer;
begin
Result:=-1;
if pc=nil then exit;
 GlobalLine.idNum:=Num;
 If Pc.Search(GlobalLine,I) then
   Result:=I;
end;
{=============================================================}
 procedure DevDrawGeoLine(DC:hdc;GL:TGeoLine;PCTwig:PCollection;PC2:TSortedCollection;Ko,MXX,MYY:single;R,G,B:byte;Flag:SmallInt;
  	XGeoCent,YGeoCent:Single;XPrintCent,YPrintCent:SmallInt;KoPoint:Single;MakeUsel:Boolean;ZDx:Single;LineWidth:Single);
 begin
 end;

initialization
 GlobalLine := nil;
finalization
 If GlobalLine <> nil then
  GlobalLine.Free;
end.
