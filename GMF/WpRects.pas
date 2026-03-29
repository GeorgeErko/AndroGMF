unit WpRects;

interface uses Collect, WpTwigs, newSelector;


type
 TTwigRect = class(TTwig)
  private
    procedure SetSect(const Value: TSect);
  public
  Proportional:Boolean;
  Inversion:Boolean;
  Constructor Create(Selector_: TSelector; W1:Integer;Data:Pointer = nil);override;
  Constructor   CreateAsTwig(Twig:TTwig;AddCoord:Boolean);override;
  Constructor   Load  (Stream :TBufStream);Override;
  Procedure     Store (Stream :TBufStream);Override;
  Function Angle:Double;
  Function YXAngle: Double;
  Function Width:Double;
  Function Height:Double;
 //
  Property Sect:TSect write SetSect;
  Procedure ReScale(var X,Y:Double;Scale:Double);
 end;

implementation uses EcDot, mpMarker, Maths_Basic;

{ TTwigRect }

constructor TTwigRect.Create(Selector_: TSelector; W1: Integer; Data: Pointer);
begin
 inherited;
 If Data<>nil then With TSect(Data^) do begin
  TwigCoord.Insert(TDot.Create(Left,Top,0));TwigCoord.Insert(TDot.Create(Right,Top,0));TwigCoord.Insert(TDot.Create(Right,Bottom,0));TwigCoord.Insert(TDot.Create(Left,Bottom,0));TwigCoord.Insert(TDot.Create(Left,Top,0));
 end;
 Calculate;
 notPere:=1;
 Locked:=1;
end;

constructor TTwigRect.CreateAsTwig(Twig: TTwig; AddCoord: Boolean);
begin
 inherited;
 Proportional:=TTwigRect(Twig).Proportional;
end;

constructor TTwigRect.Load(Stream: TBufStream);
begin
 inherited;
 Stream.Read(Proportional,SizeOf(Proportional));
 notPere:=1;
 Locked:=1;
end;

procedure TTwigRect.Store(Stream: TBufStream);
begin
  inherited;
 Stream.Read(Proportional,SizeOf(Proportional));
end;

function TTwigRect.Angle: Double;
var Dot1,Dot2:TDot;
begin
 Dot1:=TwigCoord.At(0);Dot2:=TwigCoord.At(1);
 Result:=Direct_Angle(Dot1.XDot,Dot1.YDot,Dot2.XDot,Dot2.YDot);
end;

function TTwigRect.YXAngle: Double;
var Dot1,Dot2:TDot;
begin
 Dot1:=TwigCoord.At(0);Dot2:=TwigCoord.At(1);
 Result:=Direct_Angle(Dot1.YDot,Dot1.XDot,Dot2.YDot,Dot2.XDot);
end;

function TTwigRect.Width: Double;
var Ugol,X,Y:Double;
begin
 X:=0;Y:=0;Ugol:=Angle;
 Rotate(-Ugol,X,Y);
  Result:=XMax-XMin;
 Rotate(Ugol,X,Y);
end;

function TTwigRect.Height: Double;
var X,Y,Ugol:Double;
begin
 X:=0;Y:=0;Ugol:=Angle;
 Rotate(-Ugol,X,Y);
  Result:=YMax-YMin;
 Rotate(Ugol,X,Y);
end;

procedure TTwigRect.SetSect(const Value: TSect);
var Ugol,X,Y:Double;
begin
 X:=0;Y:=0;
 Ugol:=Angle;
 With Value do begin
  Rotate(-Ugol,X,Y);
//  Item[0].XDot:=Left;Item[0].YDot:=Top;
  Item[1].XDot:=Item[0].XDot+Right; // ширина
  Item[2].XDot:=Item[0].XDot+Right; // высота
  Item[2].YDot:=Item[0].YDot+Bottom; // высота
  Item[3].YDot:=Item[0].YDot+Bottom;
//  Item[4].XDot:=Left;Item[4].YDot:=Top;
  Rotate(Ugol,X,Y);
 end;
end;

procedure TTwigRect.ReScale(var X, Y: Double; Scale: Double);
var Ugol,Dx,Dy:Double;newHeight,newWidth:Double;
    XX,YY:Double;
begin
 // запоминаем координату X,Y относительно сегмента в виде смещений Dx,Dy
 XX:=X;YY:=Y;
 Ugol:=Angle;
 Rotate(-Ugol,XX,YY);
 Dx:=XX-Item[0].XDot;Dy:=YY-Item[0].YDot;
 newWidth:=Width*Scale;newHeight:=Height*Scale;
 //
  Item[1].XDot:=Item[0].XDot+newWidth; // ширина
  Item[2].XDot:=Item[0].XDot+newWidth; // высота
  Item[2].YDot:=Item[0].YDot+newHeight; // высота
  Item[3].YDot:=Item[0].YDot+newHeight;
  Dx:=Dx*Scale;Dy:=Dy*Scale;
  X:=XX+Dx;Y:=YY+Dy;
//  Item[4].XDot:=Left;Item[4].YDot:=Top;
  Rotate(Ugol,X,Y);
//  X:=XX;Y:=YY
end;                                            

initialization
end.

