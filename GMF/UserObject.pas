unit UserObject;

interface uses Collect, FMX.Graphics, Classes, TwgDraw, newProperties;

const propNULL ='-123456789';
      binaryValue = 'Изображение';

type
  hRgn = Integer;

 TUserObject =class(TTD)
  public
  class function objType:Integer;virtual;abstract;
  Constructor CreateAsUserObject(obj:TUserObject);virtual;abstract;
 // загрузка/запись заголовка объекта
  Constructor LoadHeader(Buf: TBufStream);virtual;abstract;
  Procedure StoreHeader(Buf: TBufStream);virtual;abstract;
 //
  Procedure ClassBuild(Form:Pointer);virtual;abstract;
  Procedure DrawTemp(Canvas:TCanvas;XB,YB,Angle,XKoef,YKoef:Double;Data:Pointer = nil);virtual;abstract;
  Function Draw(Canvas:TCanvas;XB,YB,Angle,XKoef,YKoef:Double;Extrusion,Inv:boolean):boolean;virtual;abstract;
  Procedure MoveTo(toX,toY,Angle,XKoef,YKoef:Double;Extrusion:boolean);virtual;
  Procedure MoveUp;virtual;
  Procedure Move(Dx,Dy,Angle:Double);virtual;
  Procedure Rotate(Angle:Double);virtual;
  Procedure ScaleTo(XKoef,YKoef:Double;TempDrawing:Boolean = False);virtual;
 //
   Function GetName: AnsiString;virtual;
  Property sysName:AnsiString read GetName;
   Function GetCheck: byte;virtual;
   Procedure SetCheck(const Value: byte);virtual;
  Property Check:byte read GetCheck write SetCheck;
 //
  Function Width:Double;virtual;abstract;
  Function Height:Double;virtual;abstract;
  Function rectWidth:Double;virtual;abstract;
  Function rectHeight:Double;virtual;abstract;
//
  Function PointIn(X,Y:Double):Boolean;virtual;
  Function IsVisible(toX,toY,Angle,XKoef,YKoef:Double;Extrusion:boolean):boolean;virtual;
//
  Function GetClipRgn(XB, YB, Angle,XKoef,YKoef: Double;XPrintCenter,YPrintCenter:Integer;XPlanCenter,YPlanCenter:Extended): hRgn;virtual;
  Procedure SetAttribs(outProps,myProps:TProperties);virtual;
  Procedure ResetAttribs(inProps:TProperties);virtual;
 end;

 TUserClass  = class of TUserObject;

implementation uses newProcs, SysUtils;

{ TUserObject }

function TUserObject.GetCheck: byte;
begin
//
end;

function TUserObject.GetClipRgn(XB, YB, Angle,XKoef,YKoef: Double;XPrintCenter,YPrintCenter:Integer;XPlanCenter,YPlanCenter:Extended): hRgn;
begin
 Result:=0;
end;

function TUserObject.GetName: AnsiString;
begin
 Result:='*';
end;

function TUserObject.IsVisible(toX, toY, Angle, XKoef,
  YKoef: Double;Extrusion:boolean): boolean;
begin

end;

procedure TUserObject.Move(Dx, Dy, Angle: Double);
begin

end;

procedure TUserObject.MoveTo(toX, toY, Angle, XKoef, YKoef: Double;Extrusion:boolean);
begin

end;

procedure TUserObject.MoveUp;
begin

end;

function TUserObject.PointIn(X, Y: Double): Boolean;
begin
 //
end;

procedure TUserObject.Rotate(Angle: Double);
begin

end;

procedure TUserObject.ScaleTo(XKoef, YKoef: Double; TempDrawing: Boolean);
begin

end;

procedure TUserObject.SetAttribs(outProps, myProps: TProperties);
begin
end;

procedure TUserObject.ResetAttribs(inProps: TProperties);
begin
end;

procedure TUserObject.SetCheck(const Value: byte);
begin
end;

initialization
end.

