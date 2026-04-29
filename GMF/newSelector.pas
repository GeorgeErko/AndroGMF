unit newSelector;

interface uses System.Types, System.UITypes, {$IFDEF WIN64}Windows,{$ENDIF}Collect,
               newSettings, FMX.Controls, FMX.Graphics, FMX.Objects
               {$IFDEF UNIX},Types, tmpPainter{$ENDIF},
               ogcBasic, System.Skia, FMX.Skia;

 var
    { точности }
     Const_Of_DecimalHeight:Byte; // знаков после запятой для высот пикетов
     Const_Of_DecimalLength:Byte; // знаков после запятой для длин линий
     Const_Of_SqwearMetric :Byte; // в каких единицах измерения выдавать площади
     Const_Of_DecimalSqwear:Byte; // знаков после запятой для площадей
     Const_Of_AngleMetric  :Byte; // измерение углов до минут,секунд и т.п
     Const_Of_DecimalAngle :Byte; // измерение углов до минут c остатком
     Const_Of_DecimalCoord :Byte; // точность измерения координат
     Const_Of_CalcDirect   :Byte; // способ отсчета направлений
   { соотв. множители }
     Const_Of_PrecHeight:Integer;
     Const_Of_PrecLength:Integer;
     Const_Of_PrecSqwear:Integer;
     Const_Of_PrecCoord :Integer;
Const
    _LD = 15;
     Const_Meter=0;
     Const_Ga=1;
     Const_Seconds=0;
     Const_DecMinutes=1;
     Const_Minutes=2;
     Const_Direct=0;
     Const_Rumb=1;

Type
 TRealScaleLength = Function(Drawer: TogsDrawer; Value,Ko:Double):Double;

 TSect = ogcbasic.TSect;

 TShortSect=record
   Case boolean of
    False:(Left,Top,Right,Bottom:Double);
    True:(XA,YA,XB,YB:Double);
  end;

 PSect=^TSect;

 TRumb=record
   Dir:String;
   Angle:Double;
  end;

Const
  XYMax = MaxInt;
  XYMin = MaxInt;

Type

 { TMRect }
 TMRect = class
  XMin, YMin, XMax, YMax: double;
  Iter:0..1;
  Constructor Create;
  Constructor CreateAs(MRect_: TMRect);
  Procedure Clear;
  procedure Insert(X_, Y_: Double);
  function Visible(Sect: TSect): boolean;
  Function Sect: TSect;
 end;
//
 TUpdateProc = procedure(Check:boolean=False) of object;
//
 TInvalidateOverlayProc = procedure of object;
//
 TUpdateSceneMode = (usmNone, usmAdd, usmModify, usmDelete);
 TOnUpdateSceneProc = procedure (UpdateSceneMode: TUpdateSceneMode; Obj: TObject) of object;

 TSelector = class(TogsSelector)
  public
   GTwgForm:Pointer;
   GMemMakeIndex:Integer;
   GMemMake:AnsiString;
 //
   GNForm:TControl;
   ovrPainter: TSkPaintBox;
   ovrPaint: ISkPaint;
   OverlayDrawOnlyDepth: Integer;
   OnInvalidateOverlayLive: TInvalidateOverlayProc;
   OnInvalidateOverlayStatic: TInvalidateOverlayProc;
   HObject,WObject:Double;
   GGraphSet:TGraphSet;
   GLineCol,GSqwearCol,GPointCol:TSortedCollection;
   GlobalSettings: TGlobalSettings;
   GridPath: Pointer;
   GFontColEx:Pointer;
   FCurPos:TPointF;
   STSDrawing:boolean;
 //
   GFontCollect:PCollection;
   GFontSet    :PCollection;
 //
   LOperation: Integer;
 // добавление, удаление, редактирование примитивов в рендере
   OnUpdateScene: TOnUpdateSceneProc;
   SelName: String;
 // Создание
  Constructor Create(Drawer: TogsDrawer);
  Destructor Destroy; override;
 // Сравнение
  Function  EqualPoints(D1,D2:Pointer):Boolean;
  Function  EqualAnyPoints(X,Y,X2,Y2:Double):Boolean;
  Function  EqualCoord(P1,P2:Double):Boolean;
 // Видимость
  Function  PointVis(X,Y:Double):Boolean;
  Function  PointVis1(X,Y:Double):Boolean;
  Function  LineVis(XX,YY,XX1,YY1:Double):Boolean;
  Function  PointInSect(X,Y:Double;Sect:TSect):Boolean;
 // Поддержка старых функций по преобразованию
  Function  XRasst(XCoord:Double):LongInt;
  Function  YRasst(YCoord:Double):Longint;
  Function  YGeoRasst(YCoord:Double):Double;
  Function  XGeoRasst(XCoord:Double):Double;
 // Перевод
  Function  DirectToRumb(Angle:Double):TRumb;
  Function  AngleToStr(Angle:Double;UseCalc:Boolean;Razd:String):String;
// Параметры координатной системы
  Procedure UpdateImage(UpdateSceneMode:TUpdateSceneMode = usmNone; Obj: TObject = nil);
  Procedure UpdateOverlay;
  Function Drawer: TogsDrawer;
  Function GCanvas:TCanvas;
//
  Function GRect: TSect;
  Function GPRect: TRect;
  Function GDx: Double;
  Function GDy :Double;
  Function GMS:Double;
  function RealDouble(V: Double): Double;
  function RealInt(V: Double): Int64;
//
  function execEscape: boolean;
 // процедуры для рисования на ISkCanvas в MouseObject.DrawTemp
  procedure DrawLine(X1, Y1, X2, Y2: Double);
  procedure MoveTo(X, Y: Double);
  procedure LineTo(X, Y: Double);
  procedure PMoveTo(X, Y: Double);
  procedure PLineTo(X, Y: Double);
  Procedure PSetPixel(X, Y: Double);
  Procedure PSetPixelDbl(X, Y: Double);
 end;

var RealScaleLength:TRealScaleLength;

Function ScrRealScaleLength(Drawer: TogsDrawer; Value: Double; Ko: Double): Double;
Function  MetersToGa(V:Double):Double;
Function  MetersGaStr(V:Double;UseText:boolean=True):String;

implementation uses EcDot, Intervals, SysUtils, Math, WPTForm0, WPTForm1,
                    drawGrid, Writer;

Function ScrRealScaleLength(Drawer: TogsDrawer; Value: Double; Ko: Double): Double;
begin
 If Ko < 0 then Result := Drawer.ogsSelector.geoDist(Value * Drawer.ogsSelector.DevScale) * Abs(Ko)
  else
 If Ko = 0 then Result := Drawer.ogsSelector.geoDist(Value)
  else
 Result := Value * Ko;
end;

Function  MetersToGa;
begin
 If Const_Of_SqwearMetric=Const_Ga then
  Result:=V/10000 else Result:=V;
end;

Function MetersGaStr;
begin
{ If UseText then begin
 If Const_Of_SqwearMetric=Const_Ga then
  Result:=FloatToStrF(MetersToGa(V),ffFixed,_LD,Const_Of_DecimalSqwear)+' га' else
  Result:=FloatToStrF(MetersToGa(V),ffFixed,_LD,Const_Of_DecimalSqwear)+' м.кв.';
 end else begin
}
 If Const_Of_SqwearMetric=Const_Ga then
  Result:=FloatToStrF(MetersToGa(V),ffFixed,_LD,Const_Of_DecimalSqwear) else
  Result:=FloatToStrF(MetersToGa(V),ffFixed,_LD,Const_Of_DecimalSqwear);
// end;
end;

{ TMrect }

constructor TMRect.Create;
begin
 Clear;
end;

procedure TMRect.Clear;
begin
 Iter:=0;
 XMin:=0;XMax:=0;YMin:=0;YMax:=0;
end;

constructor TMRect.CreateAs(MRect_: TMRect);
begin
 XMax:=MRect_.XMax;YMax:=MRect_.YMax;XMin:=MRect_.YMin;YMax:=MRect_.YMax;
 Iter:=MRect_.Iter;
end;

procedure TMRect.Insert(X_, Y_: Double);
begin
 If Iter = 0 then begin
  XMin:=X_;YMin:=Y_;XMax:=X_;YMax:=Y_;
  Iter:=1;
 end else begin
  if X_<XMin then XMin:=X_;
  if Y_<YMin then YMin:=Y_;
  if X_>XMax then XMax:=X_;
  if Y_>YMax then YMax:=Y_;
 end;
end;

function TMRect.Visible(Sect: TSect): boolean;
begin
 Result := True;
 If XMax < Sect.Left   then begin Result := False; exit;end;
 If XMin > Sect.Right  then begin Result := False; exit;end;
 If YMin > Sect.Top    then begin Result := False; exit;end;
 If YMax < Sect.Bottom then begin Result := False; exit;end;
end;

function TMRect.Sect: TSect;
begin
  Result.Left:=XMin;
  Result.Top:=YMax;
  Result.Right:=XMax;
  Result.Bottom:=YMin;
end;

{ TSelector }

constructor TSelector.Create(Drawer: TogsDrawer);
begin
 inherited Create(Drawer);
 GlobalSettings:=TGlobalSettings.Create(Self);
 GridPath:=TGridPath.Create(Self);
 RealScaleLength := ScrRealScaleLength;
 ovrPaint := TSkPaint.Create;
 ovrPaint.AntiAlias := True;
 SelName := TimeToStr(Time);
end;

destructor TSelector.Destroy;
begin
 Writein(['sel.destr1']);
 inherited Destroy;
 Writein(['sel.destr2']);
 GlobalSettings.Free;
 Writein(['sel.destr3']);
 TGridPath(GridPath).Free;
 Writein(['sel.destr4']);
end;

function TSelector.EqualAnyPoints(X, Y, X2, Y2: Double): Boolean;
begin
 Result:=(Abs(X-X2)<1/Const_Of_PrecCoord) and (Abs(Y-Y2)<1/Const_Of_PrecCoord);
end;

function TSelector.EqualCoord(P1, P2: Double): Boolean;
begin
 Result:=(Abs(P1-P2)<1/Const_Of_PrecCoord);
end;

function TSelector.EqualPoints(D1, D2: Pointer): Boolean;
begin
 Result:=(Abs(TDot(D1).XDot-TDot(D2).XDot)<1/Const_Of_PrecCoord) and (Abs(TDot(D1).YDot-TDot(D2).YDot)<1/Const_Of_PrecCoord);
end;

function TSelector.execEscape: boolean;
begin
 //raise Exception.Create('Error Message Selector.execEscape');
end;

function TSelector.GCanvas: TCanvas;
begin
 Result := ogsDrawer.Canvas;
end;

function TSelector.GDx: Double;
begin
 Result := GetDx;
end;

function TSelector.GDy: Double;
begin
 Result := GetDy;
end;

function TSelector.GMS: Double;
begin
 Result := GetScale;
end;

function TSelector.GPRect: TRect;
begin
 Result := GNForm.BoundsRect.Round;
end;

function TSelector.GRect: TSect;
begin
 Result.Left := ActiveRect.XMin; Result.Right := ActiveRect.XMax;
 Result.Bottom := ActiveRect.YMin; Result.Top := ActiveRect.YMax;
end;

procedure TSelector.LineTo(X, Y: Double);
begin
 assert(True, 'Selector.LineTo');
end;

function TSelector.LineVis(XX, YY, XX1, YY1: Double): Boolean;
begin

end;

procedure TSelector.MoveTo(X, Y: Double);
begin
 assert(True, 'Selector.MoveTo');
end;

Function TSelector.XRasst;
 begin
  XRasst := inherited pixDist(XCoord);
 end;

Function TSelector.YRasst;
 begin
  YRasst := pixDist(YCoord);
 end;

Function TSelector.XGeoRasst;
 begin
   XGeoRasst := geoDist(XCoord);
 end;

Function TSelector.YGeoRasst;
 begin
  YGeoRasst := geoDist(YCoord);
 end;

procedure TSelector.PLineTo(X, Y: Double);
begin
 LineTo(X, Y);
end;

procedure TSelector.PMoveTo(X, Y: Double);
begin
 MoveTo(X, Y);
end;

function TSelector.PointInSect(X, Y: Double; Sect: TSect): Boolean;
Const C=100;
begin
 With Sect do
  begin
   If (X>=Left) and (X<=Right) and
      (Y<=Bottom) and (Y>=Top) then PointInSect:=True else
                                    PointInSect:=False;
  end;
end;

Function TSelector.PointVis;
 begin
  With GRect do
   begin
    If (X>=Left) and (X<=Right) and
       (Y<=Bottom) and (Y>=Top) then PointVis:=True else
                                   PointVis:=False;
   end;
 end;

Function TSelector.PointVis1;
 begin
  With GRect do
   begin
    If (X>=Left) and (X<=Right) and
       (Y>=Bottom) and (Y<=Top) then PointVis1:=True else
                                     PointVis1:=False;
   end;
 end;

procedure TSelector.PSetPixel(X, Y: Double);
begin
 With GGraphSet do
  // PointViewer[PointStyle](X,Y);
end;

procedure TSelector.PSetPixelDbl(X, Y: Double);
begin
 With GGraphSet do
  // PointViewerDbl[PointStyle](X,Y);
end;

function TSelector.RealDouble(V: Double): Double;
begin
 Result:=Round(V*Const_Of_PrecCoord)/Const_Of_PrecCoord;
end;

function TSelector.RealInt(V: Double): Int64;
begin
Result:=Round(V*Const_Of_PrecCoord);
end;

function TSelector.AngleToStr(Angle: Double; UseCalc: Boolean;
  Razd: String): String;
var R:TRumb;
Function GrMin:String;
 var Gr,Min:String[10];Min1:Extended;
 begin
  Str(Trunc(Angle),Gr);
  Min1:=Abs((Angle-Trunc(Angle))*60);
  Str(Min1:3:0,Min);
    If Length(Min)=1 then Min:='0'+Min;
    Result:=Gr+Razd+Min;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
Function GrMinSec:String;
 var Gr,Min:String[10];Min1:Extended;
 begin
  Str(Trunc(Angle),Gr);
  Min1:=Trunc((Angle-Trunc(Angle))*60);
  Str(Min1:-1:Const_Of_DecimalAngle,Min);
    Result:=Gr+Razd+Min;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
Function GrMinsSec:String;
 var Gr,Min,Sec:String[10];Min1,SSec:Extended;
 begin
      Str(Trunc(Angle),Gr);
 Min1:=Abs(Trunc((Angle-Trunc(Angle))*60));
       SSec :=Abs(Trunc(Frac((Angle-Trunc(Angle))*60)*60));
 Str(Min1:-1:0,Min);
 Str(SSec:-1:0,Sec);
     If Length(Min)=1 then Min:='0'+Min;
     If Length(Sec)=1 then Sec:='0'+Sec;
   Result:=Gr+Razd+Min+Razd+Sec;
   If Gr='0' then If Angle<0 then Result:='-'+Result;
 end;
begin
 if UseCalc then
  begin
   R:=DirectToRumb(Angle);
   Angle:=R.Angle;
  end else
  begin
   R.Dir:='';
   R.Angle:=Angle;
  end;
  If Const_Of_AngleMetric=Const_Seconds then
   Result:=R.Dir+' '+GrMinSSec else
  If Const_Of_AngleMetric=Const_DecMinutes then
   Result:=R.Dir+' '+GrMinSec else
  If Const_Of_AngleMetric=Const_Minutes then
   Result:=R.Dir+' '+GrMin;
 Result:=Trim(Result);
end;

Function TSelector.DirectToRumb;
 begin
  if Const_Of_CalcDirect=Const_Rumb then
   begin
    if (Angle>90)and(Angle<180) then begin Angle:=-Angle+180;Result.Dir:='ЮВ';end else
    if (Angle>180)and(Angle<270) then begin Angle:=Angle-180;Result.Dir:='ЮЗ';end else
    if (Angle>270)and(Angle<360) then begin Angle:=-Angle+360;Result.Dir:='CЗ';end else
    if (Angle=0)or(Angle=360) then begin Angle:=0;Result.Dir:='C ' end else
    if (Angle=90) then begin Angle:=0;Result.Dir:='З ' end else
    if (Angle=180) then begin Angle:=0;Result.Dir:='Ю ' end else
    if (Angle=270) then begin Angle:=0;Result.Dir:='В ' end else Result.Dir:='CВ';
    Result.Angle:=Angle;
   end else
   begin
    Result.Dir:='';
    Result.Angle:=Angle;
   end;
 end;

function TSelector.Drawer: TogsDrawer;
begin
 Result := ogsDrawer;
end;

procedure TSelector.DrawLine(X1, Y1, X2, Y2: Double);
begin
 assert(True, 'Selector.DrawLine')
end;

procedure TSelector.UpdateImage(UpdateSceneMode:TUpdateSceneMode = usmNone; Obj: TObject = nil);
begin
 If OverlayDrawOnlyDepth > 0 then
  Exit;
 Writein(['ui=1']);
 If UpdateSceneMode = usmNone then
  Drawer.RedrawAll
 else
 begin
  OnUpdateScene(UpdateSceneMode, Obj);
  if Assigned(OnInvalidateOverlayStatic) then
   OnInvalidateOverlayStatic;
  if Assigned(OnInvalidateOverlayLive) then
   OnInvalidateOverlayLive;
  if (not Assigned(OnInvalidateOverlayStatic)) and (not Assigned(OnInvalidateOverlayLive)) then
   if ovrPainter <> nil then
    ovrPainter.Redraw;
 end;
 Writein(['ui=2']);
end;

procedure TSelector.UpdateOverlay;
begin
 If OverlayDrawOnlyDepth > 0 then
  Exit;
 if Assigned(OnInvalidateOverlayLive) then
  OnInvalidateOverlayLive
 else
  if ovrPainter <> nil then
   ovrPainter.Redraw
  else
   UpdateImage;
end;

initialization
end.
