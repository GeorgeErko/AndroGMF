unit drawTwigs32;

// Перенос модуля drawTwigs из Geomaster (Delphi 7, GDI) на Skia.
// Объекты для динамической отрисовки сегментов (линейный, сплайн, дуга,
// окружность, прямоугольник...) и направляющие (TOrthoTwigs).
// В старой программе Draw/Move/AddPoint рисовали в GCanvas в режиме XOR
// (повторная отрисовка стирала предыдущую). Здесь:
//  - Move, AddPoint, DeletePoint только изменяют геометрию (UpdateGeometry);
//  - Draw(ISkCanvas) только рисует текущее состояние; вызывается из DrawTemp;
//  - параметр Canvas: TCanvas у Move, AddPoint, DrawLines, HideLines оставлен
//    для совместимости со старыми вызовами и не используется.
// Видимые направляющие (DrawLines/HideLines) хранятся копиями в ActiveLines
// и рисуются в TOrthoTwigs.DrawActive с отсечением по видимой области.

interface

uses System.Types, System.UITypes, System.Skia, FMX.Graphics, Collect, WpTwigs,
     WpArcs, mpMarker, EcDot, WptForm2, Math;

const pathLen: Integer = 100000000;
      xyACB: TDot = nil;

type
 TStvorLine = record
  X1, Y1, X2, Y2: Double;
 end;

type
 TOrthoTwig = class (TTwgObject)
  private
   function GetTwig(Index: Integer): TTwig;
  public
   ParentTwig: TTwig;
   Twigs: PCollection;
   Name: String;
   addAngle: Double;
  //
   Constructor Create(Twig_: TTwig; Name_: String; addAngle_: Double = Pi/2);
   Destructor Destroy; override;
   Procedure Draw(const Canvas: ISkCanvas; const Paint: ISkPaint); virtual;
   Procedure UpdateTwig;
   Function GetNearestPoint(X, Y: Double; var a, b, Dist: Double; P: PCollection): TTwig;
   Property TwigIndex[Index: Integer]: TTwig read GetTwig; default;
   Function FindOrthoTwig(fTwig: TTwig): Boolean;
 end;

 TOrthoTwigs = class (TTwgObject)
  private
   FCountOrthoTwigs: Integer;
   function GetTwig(Index: Integer): TOrthoTwig;
   procedure SetCountOrthoTwigs(const Value: Integer);
   function GetCountOrthoTwigs: Integer;
  public
   Twigs: PCollection;
   ActiveLines: PCollection; // копии видимых направляющих (DrawLines/HideLines)
   addAngle: Double;
  //
   Constructor Create;
   Procedure Draw(const Canvas: ISkCanvas; RealyDraw: Boolean = False); virtual;
   Procedure DrawLines(Canvas: TCanvas; Lines: PCollection);
   Procedure HideLines(Canvas: TCanvas);
   Procedure DrawActive(const Canvas: ISkCanvas);
   Destructor Destroy; override;
   Procedure UpdateTwigs;
   Procedure Add(Tw: TTwig; Nm: String);
   Procedure Pack(Nm: String);
   Procedure Delete(Tw: TTwig);
   Function GetNearestTwig(X, Y: Double; var a, b, Dist: Double; P: PCollection): TTwig;
  //
   Property Twig[Index: Integer]: TOrthoTwig read GetTwig; default;
   Property CountOrthoTwigs: Integer read GetCountOrthoTwigs;
  //
   Function FindOrthoTwig(fTwig: TTwig): Boolean;
  //
   Procedure OnDestroy(Sender: TObject);
 end;

var orthoTwigs: TOrthoTwigs;

type
 TPathMarker = class (TTwgObject)
 public
  XMark, YMark: Double;
  verTwig, horTwig, visTwig: TTwig;
  Visible: Boolean;
 //
  Constructor Create(X, Y: Double);
  Procedure Restore(X, Y: Double);
  Procedure GetPoint(var X, Y: Double);
  Procedure Draw(const Canvas: ISkCanvas);
  Destructor Destroy; override;
 end;

type
 TTwigPath = class (TTwgObject)
  private
   function GetCoord(Index: Integer): TDot;
   procedure SetCoord(Index: Integer; const Value: TDot);
  public
   Color: TAlphaColor;
   mX, mY: Double; // координаты мыши при рисовке
   Twig: TTwig;
   TwigVisible: boolean;
   fixLength, fix2Length,
   fixAngle: Double;
   Marker: TMarker;
   addAngle: Double;
   mpStvor: TStvorLine;
  //
   interFirst, interSecond: TTwig;
   twigStyle: Integer;
   Width: Double;
  //
   PathMarker: TPathMarker;
   useDirectAngle: Boolean;
  //
   saveAngle: Double;
   cirKvant: Integer;
  //
   Constructor Create(TwigClass: TTwigClass; Params: Pointer = nil; Color_: TAlphaColor = TAlphaColorRec.Red);
   Constructor CreateAsTwig(Twig_: TTwig; Color_: TAlphaColor = TAlphaColorRec.Red);
   Destructor Destroy; override;
   Procedure Draw(const Canvas: ISkCanvas); virtual;
   Procedure UpdateGeometry; virtual;
   Procedure UpdateOrthoMarker;
   Procedure Move(Canvas: TCanvas; X, Y: Double); virtual;
   Procedure AddPoint(Canvas: TCanvas; X, Y: Double); virtual;
   Procedure DeletePoint(Canvas: TCanvas); virtual;
   Procedure Calculate; virtual;
   Procedure SetLength(Canvas: TCanvas; newLength: Double);
   Procedure SetIncrementalLength(Canvas: TCanvas; newLength: Double);
   Procedure SetAngle(Canvas: TCanvas; newAngle: Double; UDA: Boolean);
   Function LastPoint: TDot;
   Function FirstPoint: TDot;
   Procedure UpdateStvor;
  //
   Function Count: Integer;
   Property Coord[Index: Integer]: TDot read GetCoord write SetCoord; default;
 end;

 TArcStyle = (asArc, asArc2, asArc3);

 TTwigPathArc = class (TTwigPath)
  public
   CondArc: Integer;
   ArcStyle: TArcStyle;
  //
   Procedure Draw(const Canvas: ISkCanvas); override;
   Procedure UpdateGeometry; override;
   Procedure Move(Canvas: TCanvas; X, Y: Double); override;
   Procedure AddPoint(Canvas: TCanvas; X, Y: Double); override;
 end;

 TTwigPathArc2 = class (TTwigPathArc)
  private
   FArcValid: Boolean; // дуга рассчитана в UpdateGeometry
   Procedure calcTangentTwig(var X, Y: Double);
  public
   X1, Y1, X2, Y2, XR, YR, XC, YC: Double;
   prevTwig: TTwig;
  //
   Constructor Create(TwigClass: TTwigClass; Params: Pointer = nil; prevTwig_: TTwig = nil; Color_: TAlphaColor = TAlphaColorRec.Red);
   Procedure Draw(const Canvas: ISkCanvas); override;
   Procedure UpdateGeometry; override;
   Procedure Move(Canvas: TCanvas; X, Y: Double); override;
   Procedure AddPoint(Canvas: TCanvas; X, Y: Double); override;
 end;

 TTwigPathRect = class (TTwigPath)
  public
   CondRect: Integer;
  //
   Procedure Draw(const Canvas: ISkCanvas); override;
   Procedure UpdateGeometry; override;
   Procedure Move(Canvas: TCanvas; X, Y: Double); override;
   Procedure AddPoint(Canvas: TCanvas; X, Y: Double); override;
 end;

// заливка параллельной линии (кнопки sbHatch, sbStroke, sbSolid, sbIDN старой ParaLineForm)
 TParaFillStyle = (pfNone, pfHatch, pfStroke, pfSolid, pfIDN);

 TTwigParaLine = class (TTwigPath)
  public
   TwigL, TwigR, TwigT, TwigB: TTwig;
   Rects: PCollection;
  // параметры из ParaLineForm (seParam, seWidth, seSpace - в сотых долях)
   ParaStyle: TParaFillStyle;
   RectParam, RectWidth, RectSpace: Double;
  //
   Constructor Create(TwigClass: TTwigClass; Params: Pointer = nil; Color_: TAlphaColor = TAlphaColorRec.Red);
   Destructor Destroy; override;
   Procedure Calculate; override;
   Procedure Draw(const Canvas: ISkCanvas); override;
   Procedure UpdateGeometry; override;
 end;

 TTwigPathKvant = class (TTwigPath)
  public
   X1, Y1: Double;
  //
   Constructor Create(TwigClass: TTwigClass; Params: Pointer; X, Y: Double);
   Procedure Calculate; override;
   Procedure Draw(const Canvas: ISkCanvas); override;
 end;

 TNearestPoint = class (TDot)
  public
   X, Y: Double;
   Dot: TDot;
   Twig: TTwig;
   RootTwig: TTwig;
  //
   Constructor Create(Dot_: TDot; Twig_: TTwig);
   Procedure DrawTo(const Canvas: ISkCanvas; X, Y: Double);
   Procedure UpdateTwig;
 end;

 TNearestPoints = class (TTwgObject)
  private
   function GetselPoint(Index: Integer): TNearestPoint;
  public
   TwgForm: TForm2;
  //
   Objects: PCollection;
   selPoints: PCollection; // коллекция TNearestPoint
   XSelect, YSelect: Double;
  //
   Constructor Create(Form: TForm2);
   Destructor Destroy; override;
   Procedure DrawTo(const Canvas: ISkCanvas; X, Y: Double);
   Function SetXY(X, Y: Double): boolean;
   Function GetPoints(Objs: PCollection; X, Y: Double): Integer;
   Function FindTwig(Tw: TTwig): Boolean;
  //
   Property selPoint[Index: Integer]: TNearestPoint read GetselPoint;
   Function FindNearestPoint(X, Y: Double): TNearestPoint;
   Function isBlock(X, Y: Double): boolean;
 end;

// отрисовка на ISkCanvas в мировых координатах; толщины и штрихи - в пикселах
 function SkPixToWorld(const Canvas: ISkCanvas; Pix: Single): Single;
 function SkPen(const Canvas: ISkCanvas; Color: TAlphaColor; WidthPix: Single; Dashed: Boolean): ISkPaint;
 procedure SkDrawLineClipped(const Canvas: ISkCanvas; X1, Y1, X2, Y2: Double; const Paint: ISkPaint);
 procedure SkDrawTwig(const Canvas: ISkCanvas; Tw: TTwig; const Paint: ISkPaint);

implementation

uses System.Math.Vectors, EMath, MathS, newSettings, circle_di, WptForm1,
     maths_versia, types_dimano, WPGeo, EcLot, UpdateMessages, UserObject,
     FMX.Dialogs, SysUtils, newProcs, WpRects, Writer, Selector32;

function SkPixToWorld(const Canvas: ISkCanvas; Pix: Single): Single;
var M: TMatrix;
    Scale: Single;
begin
 Result := Pix;
 if Canvas = nil then exit;
 M := Canvas.GetLocalToDeviceAs3x3;
 Scale := Sqrt(Sqr(M.m11) + Sqr(M.m12));
 if Scale > 0 then Result := Pix / Scale;
end;

function SkPen(const Canvas: ISkCanvas; Color: TAlphaColor; WidthPix: Single; Dashed: Boolean): ISkPaint;
var Dash: Single;
begin
 Result := TSkPaint.Create;
 Result.AntiAlias := True;
 Result.Style := TSkPaintStyle.Stroke;
 Result.Color := Color;
 Result.StrokeWidth := SkPixToWorld(Canvas, WidthPix);
// аналог пера ps_Dot
 if Dashed then begin
  Dash := SkPixToWorld(Canvas, 3);
  Result.PathEffect := TSkPathEffect.MakeDash([Dash, Dash], 0);
 end;
end;

procedure SkDrawLineClipped(const Canvas: ISkCanvas; X1, Y1, X2, Y2: Double; const Paint: ISkPaint);
var R: TRectF;
    XMin, YMin, XMax, YMax, Dx, Dy, T0, T1: Double;
function Clip(P, Q: Double): Boolean;
var T: Double;
begin
 Result := True;
 if P = 0 then begin
  if Q < 0 then Result := False;
  exit;
 end;
 T := Q / P;
 if P < 0 then begin
  if T > T1 then Result := False else if T > T0 then T0 := T;
 end else begin
  if T < T0 then Result := False else if T < T1 then T1 := T;
 end;
end;
begin
// направляющие имеют концы ~1e8: в Single такая линия смещается, поэтому
// отрезок обрезается видимой областью в Double (Лианг-Барски) и только потом рисуется
 if Canvas = nil then exit;
 R := Canvas.GetLocalClipBounds;
 XMin := R.Left; YMin := R.Top; XMax := R.Right; YMax := R.Bottom;
 Dx := X2 - X1;
 Dy := Y2 - Y1;
 T0 := 0;
 T1 := 1;
 if not Clip(-Dx, X1 - XMin) then exit;
 if not Clip(Dx, XMax - X1) then exit;
 if not Clip(-Dy, Y1 - YMin) then exit;
 if not Clip(Dy, YMax - Y1) then exit;
 Canvas.DrawLine(X1 + T0 * Dx, Y1 + T0 * Dy, X1 + T1 * Dx, Y1 + T1 * Dy, Paint);
end;

procedure SkDrawTwig(const Canvas: ISkCanvas; Tw: TTwig; const Paint: ISkPaint);
var I: Integer;
    D0, D1: TDot;
    OldView: Byte;
begin
 if (Canvas = nil) or (Tw = nil) then exit;
// ArcView = 1: у дуг и окружностей - аппроксимирующая ломаная
 OldView := Tw.ArcView;
 Tw.ArcView := 1;
 try
  for I := 1 to Tw.Coord.Count - 1 do begin
   D0 := Tw[I - 1];
   D1 := Tw[I];
   SkDrawLineClipped(Canvas, D0.XDot, D0.YDot, D1.XDot, D1.YDot, Paint);
  end;
 finally
  Tw.ArcView := OldView;
 end;
end;

{ TPathMarker }

constructor TPathMarker.Create(X, Y: Double);
begin
 XMark := X;
 YMark := Y;
 horTwig := TTwig.Create(GSelector, 0);
 verTwig := TTwig.Create(GSelector, 0);
 horTwig.Insert(TDot.Create(0, 0, 0));
 horTwig.Insert(TDot.Create(0, 0, 0));
 verTwig.Insert(TDot.Create(0, 0, 0));
 verTwig.Insert(TDot.Create(0, 0, 0));
 visTwig := nil;
end;

destructor TPathMarker.Destroy;
begin
 horTwig.Free;
 verTwig.Free;
end;

procedure TPathMarker.GetPoint(var X, Y:Double);
const DMax:Integer = 1000000;
var Dist1,Dist2,a,b,c,d:Double;
begin
 horTwig[0].XDot:=XMark-DMAx;horTwig[0].YDot:=YMark;horTwig[1].XDot:=XMark+DMax;horTwig[1].YDot:=YMark;
 verTwig[0].XDot:=XMark;verTwig[0].YDot:=YMark-DMax;verTwig[1].XDot:=XMark;verTwig[1].YDot:=YMark+DMAx;
 Dist1:=horTwig.GetTwigDist(X,Y,a,b);Dist2:=verTwig.GetTwigDist(X,Y,c,d);
// If not Visible then Draw(GCanvas);
//Writeln(XRasst(Dist1));
 If XRasst(Dist1)<=TForm2(GTwgForm).Settings.psOrthoDisst then begin
  visTwig:=horTwig;
  X:=a;Y:=b;
//  If not Visible then Draw(GCanvas);
 end else
 If XRasst(Dist2)<=TForm2(GTwgForm).Settings.psOrthoDisst then begin
  visTwig:=verTwig;
  X:=c;Y:=d;
//  If not Visible then Draw(GCanvas);
 end else begin
//  If Visible then Draw(GCanvas);
  visTwig:=nil;
 end;
end;

procedure TPathMarker.Draw(const Canvas: ISkCanvas);
begin
// активная ось (горизонталь или вертикаль через точку фиксации)
 if (Canvas = nil) or (visTwig = nil) then exit;
 SkDrawTwig(Canvas, visTwig, SkPen(Canvas, TAlphaColorRec.Gray, 1, True));
end;

procedure TPathMarker.Restore(X, Y: Double);
begin
 XMark:=X;YMark:=Y;
 Visible:=False;
end;

{ TTwigPath }

constructor TTwigPath.Create(TwigClass: TTwigClass; Params: Pointer; Color_: TAlphaColor);
begin
 Twig := TwigClass.Create(GSelector, 0, Params);
 Color := Color_;
 mX := xyNull;
 mY := xyNull;
 TwigVisible := False;
 fixLength := xyNull;
 Marker := TMarker.Create(GSelector, 0, mtMarker, TAlphaColorRec.Blue, 25, 0);
 addAngle := Pi;
 UpdateStvor;
 fixAngle := xyNull;
 SaveAngle := xyNull;
 PathMarker := TPathMarker.Create(0, 0);
end;

constructor TTwigPath.CreateAsTwig(Twig_: TTwig; Color_: TAlphaColor);
begin
// в старом коде параметр Twig перекрывал поле, и копия ветви терялась
 Twig := TTwigClass(Twig_.ClassType).CreateAsTwig(Twig_, True);
 Color := Color_;
 mX := xyNull;
 mY := xyNull;
 TwigVisible := False;
 fixLength := xyNull;
 UpdateStvor;
 PathMarker := TPathMarker.Create(0, 0);
end;

destructor TTwigPath.Destroy;
begin
 if Twig <> nil then Twig.Free;
 PathMarker.Free;
// маркер зарегистрирован в оверлее маркеров (mpMarker) - освобождаем, чтобы не остался на экране
 if Marker <> nil then Marker.Free;
end;

procedure TTwigPath.Draw(const Canvas: ISkCanvas);
var Paint: ISkPaint;
    D: TDot;
    TempDot: Boolean;
begin
 if (Canvas = nil) or (Twig.Coord.Count = 0) then exit;
 if TForm2(GTwgForm).Settings.psWidthPath then Paint := SkPen(Canvas, Color, 2, False) else Paint := SkPen(Canvas, Color, 1, True);
// у сплайна положение мыши - временная последняя точка (как в старом Draw)
 TempDot := (Twig is TTwigSpline) and (mX <> xyNull);
 if TempDot then begin
  Twig.Insert(TDot.Create(mX, mY, 0));
  Twig.Calculate;
 end;
 try
  SkDrawTwig(Canvas, Twig, Paint);
 finally
  if TempDot then Twig.Coord.AtFree(Twig.Coord.Count - 1);
 end;
 PathMarker.Draw(Canvas);
// резиновая линия от последней точки к мыши
 D := Twig[Twig.Coord.Count - 1];
 if not (Twig is TTwigSpline) and (mX <> xyNull) then Canvas.DrawLine(D.XDot, D.YDot, mX, mY, Paint);
end;

procedure TTwigPath.UpdateGeometry;
begin
 if Twig.Coord.Count = 0 then exit;
 if (Twig is TTwigCircle) and (mX <> xyNull) then begin
  TTwigCircle(Twig).R.XDot := mX;
  TTwigCircle(Twig).R.YDot := mY;
 end;
 Twig.Closed := 1;
 Twig.Calculate;
 TwigVisible := True;
 UpdateOrthoMarker;
end;

procedure TTwigPath.UpdateOrthoMarker;
var D, D2: TDot;
begin
// маркер прямых углов в последней точке (режим psOrtho)
 if (Marker = nil) or (Twig.Coord.Count = 0) then exit;
 if not TForm2(GTwgForm).Settings.psOrtho then exit;
 D := Twig[Twig.Coord.Count - 1];
 if Twig.Coord.Count = 1 then
  Marker.Move(GCanvas, D.XDot, D.YDot, MoveNone, addAngle)
 else begin
  D2 := Twig[Twig.Coord.Count - 2];
  Marker.Move(GCanvas, D.XDot, D.YDot, MoveNone, Atan2(D2.XDot - D.XDot, D2.YDot - D.YDot));
 end;
end;

procedure TTwigPath.AddPoint(Canvas: TCanvas; X, Y: Double);
begin
 if not (Twig is TTwigCircle) then Twig.Insert(TDot.Create(X, Y, 0));
 Twig.Calculate;
 PathMarker.Restore(Twig.Last.XDot, Twig.Last.YDot);
 Move(Canvas, Twig.Last.XDot, Twig.Last.YDot);
end;

procedure TTwigPath.DeletePoint(Canvas: TCanvas);
begin
 if (Twig.ClassName = 'TTwig') and (Twig.Coord.Count > 1) then Twig.Coord.AtFree(Twig.Coord.Count - 1);
 Twig.Calculate;
 Calculate;
 PathMarker.Restore(Twig.Last.XDot, Twig.Last.YDot);
 Move(Canvas, Twig.Last.XDot, Twig.Last.YDot);
end;

procedure TTwigPath.Move(Canvas: TCanvas; X, Y: Double);
var Angle,addFixAngle,Dist:Double;D,D1,D2:TDot;
    X90,Y90:Double;
begin
 If Twig.Coord.Count=0 then exit;
//
   mX:=X;mY:=Y;
   X90:=X;Y90:=Y;
  // расчитываем координату с учетом приближения к прямому углу
 If TForm2(GTwgForm).Settings.psOrtho then begin
 // притягиваем к оси абсцисс/ординат                              
   PathMarker.GetPoint(mX,mY);
   X90:=mX;Y90:=mY;
 // если нет то притягиваем по маркеру прямоугольного рисования
//  Writeln('AddAngle=',AddAngle*180/Pi);
  Twig.OrthoTwig(X90,Y90,addAngle,False);
//  Writeln(XRasst(Distance(X,Y,X90,Y90)/2),' ',TForm2(GTwgForm).Settings.psOrthoDisst);
//  PMoveTo(Twig[Twig.Coord.Count-1].XDot,Twig[Twig.Coord.Count-1].YDot);PLineTo(X90,Y90);
  If TForm2(GTwgForm).Settings.psOrthoMode then begin
    X:=X90;Y:=Y90;
    mX:=X;mY:=Y;
  end else
  If XRasst(Distance(X,Y,X90,Y90)/2)<=TForm2(GTwgForm).Settings.psOrthoDisst then begin
    X:=X90;Y:=Y90;
    mX:=X;mY:=Y;
  end;// else begin mx:=X90;mY:=Y90;end;// else Writeln(XRasst(Distance(X,Y,X90,Y90)/2),' ',psOrthoDisst);// else begin mx:=X90;mY:=Y90;end;
 end;
 If (fixAngle<>xyNull)and(Twig.Coord.Count>1) then begin
  D2:=LastPoint;D1:=Twig[Twig.Coord.Count-2];
  Angle:=Atan2(D1.YDot-D2.YDot,D1.XDot-D2.XDot)+Pi/2;
  Angle:=Angle+fixAngle*Pi/180;
  If useDirectAngle then begin
   Angle:=(fixAngle-180)*Pi/180;
   X:=D2.XDot+Distance(D2.XDot,D2.YDot,mX,mY)*sin(Angle);
   Y:=D2.YDot-Distance(D2.XDot,D2.YDot,mX,mY)*cos(Angle);
  end else begin
   X:=D2.XDot+Distance(D2.XDot,D2.YDot,mX,mY)*cos(Angle);
   Y:=D2.YDot-Distance(D2.XDot,D2.YDot,mX,mY)*sin(Angle);
  end;
   mX:=X;mY:=Y;
 end else If (fixAngle<>xyNull)and(useDirectAngle)and(Twig.Coord.Count=1) then begin
   Angle:=(fixAngle-180)*Pi/180;
  // Writeln('fixA=',fixAngle:8:4);
   D2:=LastPoint;
   X:=D2.XDot+Distance(D2.XDot,D2.YDot,mX,mY)*sin(Angle);
   Y:=D2.YDot-Distance(D2.XDot,D2.YDot,mX,mY)*cos(Angle);
   mX:=X;mY:=Y;
  //
 end;
 If fixLength<>xyNull then begin  // расчитываем координату с учетом fixLength
  D:=Twig[Twig.Coord.Count-1];
  if fixAngle=xyNull then Angle:=Atan2(D.YDot-Y,D.XDot-X)+Pi/2;
 //
  If useDirectAngle then begin
   X:=D.XDot+fixLength*sin(Angle);
   Y:=D.YDot-fixLength*cos(Angle);
  end else begin
   X:=D.XDot+fixLength*cos(Angle);
   Y:=D.YDot-fixLength*sin(Angle);
  end;
  mX:=X;mY:=Y;
 end;
 UpdateStvor;
 try Calculate; except ShowMessage('drawTwigs '+IntToStr(384));end;
 UpdateGeometry;
end;

procedure TTwigPath.SetLength(Canvas:TCanvas;newLength: Double);
begin
  fixLength:=newLength;
 Move(Canvas,mX,mY);
end;

procedure TTwigPath.SetIncrementalLength(Canvas:TCanvas;newLength: Double);
var UDA:boolean;
begin
  fixLength:=newLength;
  UDA:=useDirectAngle;
  useDirectAngle:=True;
 Move(Canvas,mX,mY);
  useDirectAngle:=UDA;
end;

function TTwigPath.LastPoint: TDot;
begin
 Result:=nil;
 If Twig.Coord.Count=0 then Exit;
 Result:=Twig[Twig.Coord.Count-1]
end;

function TTwigPath.FirstPoint: TDot;
begin
 Result:=nil;
 If Twig.Coord.Count=0 then Exit;
 Result:=Twig[0];
end;

function TTwigPath.Count: Integer;
begin
 Result:=Twig.Coord.Count;
end;

function TTwigPath.GetCoord(Index: Integer): TDot;
begin
 Result:=Twig.Coord[Index];
end;

procedure TTwigPath.SetCoord(Index: Integer; const Value: TDot);
begin
 TDot(Twig.Coord[Index]).Free;
 Twig.Coord[Index]:=Value;
end;

procedure TTwigPath.UpdateStvor;
begin
 If Twig.Coord.Count<1 then mpStvor.X1:=xyNull else
 With mpStvor do begin
  X1:=mX;Y1:=mY;
  X2:=LastPoint.XDot;Y2:=LastPoint.YDot;
 end;
end;

procedure TTwigPath.SetAngle(Canvas: TCanvas; newAngle: Double;UDA:Boolean);
begin
  fixAngle:=newAngle;
  useDirectAngle:=UDA;
 Move(Canvas,mX,mY);
end;

procedure TTwigPath.Calculate;
begin
//
end;

{ TTwigPathArc }

procedure TTwigPathArc.AddPoint(Canvas: TCanvas; X, Y: Double);
begin
 if CondArc = 0 then begin
  TTwigArc(Twig).B.XDot := X;
  TTwigArc(Twig).B.YDot := Y;
  UpdateGeometry;
 end;
 CondArc := 1;
end;

procedure TTwigPathArc.Draw(const Canvas: ISkCanvas);
var Paint: ISkPaint;
    D: TDot;
begin
 if (Canvas = nil) or (Twig.Coord.Count = 0) then exit;
 Paint := SkPen(Canvas, Color, 1, True);
// пока вторая точка не задана - линия, иначе дуга
 if EqualPoints(TTwigArc(Twig).A, TTwigArc(Twig).B) then begin
  D := Twig[Twig.Coord.Count - 1];
  if mX <> xyNull then Canvas.DrawLine(D.XDot, D.YDot, mX, mY, Paint);
 end else
  SkDrawTwig(Canvas, Twig, Paint);
end;

procedure TTwigPathArc.UpdateGeometry;
var X1, Y1, X2, Y2, XC, YC: Double;
    B: Boolean;
begin
 if Twig.Coord.Count = 0 then exit;
 TwigVisible := True;
 if EqualPoints(TTwigArc(Twig).A, TTwigArc(Twig).B) then exit;
// дуга через A, B и положение мыши
 X1 := TTwigArc(Twig).A.XDot;
 Y1 := TTwigArc(Twig).A.YDot;
 X2 := TTwigArc(Twig).B.XDot;
 Y2 := TTwigArc(Twig).B.YDot;
 if (mX = xyNull) or EqualAnyPoints(X2, Y2, mX, mY) then exit;
 B := True;
 try
  solving_arc_circle(X1, Y1, X2, Y2, mX, mY, XC, YC);
 except
  B := False;
 end;
 if B then TTwigArc(Twig).ReCreate(XC, YC, X1, Y1, X2, Y2, mX, mY);
end;

procedure TTwigPathArc.Move(Canvas: TCanvas; X, Y: Double);
var Angle,Dist:Double;D:TDot;
    XX,YY:Double;X1,Y1,X2,Y2,XL,YL,XR,YR:Double;
begin
 If Twig.Coord.Count=0 then exit;
//
   mX:=X;mY:=Y;
  if (fixLength<>xyNull)then begin   // расчитываем координату с учетом fixLength
   if (CondArc=0) then begin
    D:=TTwigArc(Twig).A;
    Angle:=Atan2(D.YDot-Y,D.XDot-X)+Pi/2;
   //
    X:=D.XDot+fixLength*cos(Angle);
    Y:=D.YDot-fixLength*sin(Angle);
    mX:=X;mY:=Y;
   end else With TTwigArc(Twig) do begin // учитываем радиус
    X1:=A.XDot;Y1:=A.YDot;X2:=B.XDot;Y2:=B.YDot;
    If Distance(X,Y,A.XDot,A.YDot)<Distance(X,Y,B.XDot,B.YDot) then begin
    // XX:=x1;YY:=y1;x1:=x2;y1:=y2;x2:=XX;y2:=YY;
     AChangeB;
     X1:=A.XDot;Y1:=A.YDot;X2:=B.XDot;Y2:=B.YDot;
    end;
    try solving_centers_arc( xl, yl, xr, yr, x1, y1, x2, y2, fixLength );except Exit; end;
    If Distance(XR,YR,X,Y)<Distance(XL,YL,X,Y) then begin
     C.XDot:=xr;C.YDot:=yr;
    end else begin
     C.XDot:=xl;C.YDot:=yl;
    end;
    MiddlePointSet;
    Calculate;
    mX:=TTwigArc(Twig).D.XDot;mY:=TTwigArc(Twig).D.YDot;
   end;
  end;
 UpdateGeometry;
end;


{ TTwigPathArc2 }

constructor TTwigPathArc2.Create(TwigClass: TTwigClass; Params: Pointer; prevTwig_: TTwig; Color_: TAlphaColor);
begin
 inherited Create(TwigClass, Params, Color_);
 prevTwig := prevTwig_;
end;

procedure TTwigPathArc2.calcTangentTwig(var X, Y: Double);
begin
 // вычисляем положение

end;

procedure TTwigPathArc2.AddPoint(Canvas: TCanvas; X, Y: Double);
begin
 ArcStyle := asArc2;
 if CondArc = 0 then begin
  X1 := X; Y1 := Y; X2 := X; Y2 := Y;
  if prevTwig <> nil then CondArc := 2;
  Inc(CondArc);
 end else if CondArc < 2 then begin
  X2 := X; Y2 := Y;
  UpdateGeometry;
  Inc(CondArc);
 end;
end;

procedure TTwigPathArc2.Move(Canvas: TCanvas; X, Y: Double);
begin
 if CondArc = 0 then exit;
 if CondArc = 1 then begin
  X2 := X; Y2 := Y;
 end else begin
  XR := X; YR := Y;
 end;
 mX := X;
 mY := Y;
 UpdateGeometry;
end;

procedure TTwigPathArc2.Draw(const Canvas: ISkCanvas);
var Paint: ISkPaint;
begin
 if (Canvas = nil) or (Twig.Coord.Count = 0) then exit;
 Paint := SkPen(Canvas, Color, 1, True);
// хорда, пока не задана третья точка, затем дуга
 if (prevTwig = nil) and (CondArc < 2) then
  Canvas.DrawLine(X1, Y1, X2, Y2, Paint)
 else if FArcValid then
  SkDrawTwig(Canvas, Twig, Paint);
end;

procedure TTwigPathArc2.UpdateGeometry;
var B: Boolean;
    Ro, Radius, Fi, Pi2: Double;
    Tw: TTwig;
    X, Y, XPrev, YPrev: Double;
begin
 FArcValid := False;
 if Twig.Coord.Count = 0 then exit;
 TwigVisible := True;
 if prevTwig = nil then begin
  if CondArc < 2 then exit;
  B := True;
  try
   solving_arc_circle(X1, Y1, X2, Y2, XR, YR, XC, YC);
  except
   B := False;
  end;
  if B then begin
   TTwigArc(Twig).ReCreate(XC, YC, X1, Y1, XR, YR, X2, Y2);
   FArcValid := True;
  end;
  exit;
 end;
// пересчет с учетом касательной к предыдущей ветви: находим радиус
 Tw := prevTwig;
 if Tw is TTwigArc then begin
  X := xyACB.XDot; Y := xyACB.YDot;
  if xyACB = TTwigArc(Tw).A then Pi2 := 0 else Pi2 := Pi;
  XPrev := TTwigArc(Tw).C.XDot; YPrev := TTwigArc(Tw).C.YDot;
 end else begin
  X := Tw.Last.XDot; Y := Tw.Last.YDot;
  XPrev := Tw[Tw.Coord.Count - 2].XDot; YPrev := Tw[Tw.Coord.Count - 2].YDot;
  Pi2 := Pi / 2;
 end;
 Ro := Distance(X, Y, XR, YR);
 Fi := (direct_angle(X, Y, XR, YR) - (direct_angle(X, Y, XPrev, YPrev) - Pi2));
 if Fi > 0 then Fi := Pi * 2 - Fi else Fi := Pi * 2 + Fi;
 Radius := (Ro / cos(Fi)) / 2;
// нашли радиус - находим центр окружности
 XC := X + Radius * cos(direct_angle(X, Y, XPrev, YPrev) - Pi2);
 YC := Y + Radius * sin(direct_angle(X, Y, XPrev, YPrev) - Pi2);
 with TTwigArc(Twig) do begin
  C.XDot := XC; C.YDot := YC;
  A.XDot := XR; A.YDot := YR;
  B.XDot := X; B.YDot := Y;
  if (Fi < Pi * 3 / 2) and (Fi > Pi / 2) then AChangeB;
  try
   MiddlePointSet;
   Calculate;
  except
   exit;
  end;
 end;
 FArcValid := True;
end;

{ TTwigPathRect }

procedure TTwigPathRect.AddPoint(Canvas: TCanvas; X, Y: Double);
begin
 if CondRect = 0 then begin
  Twig.Insert(TDot.Create(X, Y, 10));
  CondRect := 1;
 end else if CondRect = 1 then begin
  Twig.Insert(TDot.Create(X, Y, 0));
  Twig.Insert(TDot.CreateAsDot(Twig[1]));
  Twig.Insert(TDot.CreateAsDot(Twig[0]));
  Twig.Insert(TDot.CreateAsDot(Twig[0]));
  CondRect := 2;
 end;
 UpdateGeometry;
end;

procedure TTwigPathRect.Draw(const Canvas: ISkCanvas);
begin
 if CondRect = 1 then begin
  inherited;
  exit;
 end;
 if Canvas = nil then exit;
 SkDrawTwig(Canvas, Twig, SkPen(Canvas, Color, 1, True));
end;

procedure TTwigPathRect.UpdateGeometry;
begin
 if CondRect = 1 then begin
  inherited;
  exit;
 end;
 Twig.Closed := 1;
 Twig.Calculate;
 TwigVisible := True;
end;

procedure TTwigPathRect.Move(Canvas: TCanvas; X, Y: Double);
var Tw:TTwig;D:tDot;Angle:Double;fix,XX,YY,XXX,YYY,a,b,Distance:Double;
    Ortho:TOrthoTwig;
begin
 If Twig.Coord.Count=0 then exit;
 If CondRect=1 then begin inherited; exit;end;
//
 try
   mX:=X;mY:=Y;XX:=X;YY:=Y;
  If CondRect=2 then begin
//   PTextOut(Twig[0].XDot,Twig[0].YDot,'p1');PTextOut(Twig[1].XDot,Twig[1].YDot,'p2');
   Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.CreateAsDot(Twig[0]));Tw.Insert(TDot.CreateAsDot(Twig[1]));
   Ortho:=TOrthoTwig.Create(Tw,'');Ortho.UpdateTwig;
   Distance:=Ortho.TwigIndex[1].GetTwigDist(X,Y,XX,YY);//Ortho.Draw(Canvas);
//   Writeln('Dist=',Distance);
 {  With Ortho do begin
    PTextOut(TwigIndex[1][0].XDot,TwigIndex[1][0].YDot,'p1');PTextOut(TwigIndex[1][1].XDot,TwigIndex[1][1].YDot,'p2');
   end;}
// Writeln('Dist=',Distance);
   If Distance = ZNull then Exit;
//   Writeln('Dist1=',Distance:8:10,' ',X:8:5,' ',Y:8:5);
   Angle:=Atan2(YY-Y,XX-X)+Pi/2;
   D:=Twig[1];
    X:=D.XDot+Distance*cos(Angle);
    Y:=D.YDot-Distance*sin(Angle);
  //  Tw.OrthoTwig(X,Y,addAngle,True);
   Twig[2].XDot:=X;Twig[2].YDot:=Y;
//   Writeln('Dist2=',Maths.Distance(Twig[1].XDot,Twig[1].YDot,Twig[2].XDot,Twig[2].YDot):8:10);
   mX:=X;mY:=Y;
   Ortho.Free;
   Tw.Free;
  // Writeln('fix=',fixLength);
   if (fixLength<>xyNull)then begin  // расчитываем координату с учетом fixLength
    D:=Twig[1];
    Angle:=Atan2(D.YDot-Y,D.XDot-X)+Pi/2;
   //
    X:=D.XDot+fixLength*cos(Angle);
    Y:=D.YDot-fixLength*sin(Angle);
   // mX:=xyNull;mY:=Y;
    Twig[2].XDot:=X;Twig[2].YDot:=Y;
    mX:=X;mY:=Y;
   end;
   //
   Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.CreateAsDot(Twig[0]));Tw.Insert(TDot.CreateAsDot(Twig[1]));
   Ortho:=TOrthoTwig.Create(Tw,'');Ortho.UpdateTwig;//Ortho.Draw(Canvas);
   Distance:=Ortho.TwigIndex[1].GetTwigDist(X,Y,XX,YY);
   Angle:=Atan2(YY-Y,XX-X)+Pi/2;
   D:=Twig[0];
   X:=D.XDot+Distance*cos(Angle);
   Y:=D.YDot-Distance*sin(Angle);
  //  Tw.OrthoTwig(X,Y,addAngle,True);
   Twig[3].XDot:=X;Twig[3].YDot:=Y;
   mX:=X;mY:=Y;
   Ortho.Free;
   Tw.Free;
   if (fixLength<>xyNull)then begin  // расчитываем координату с учетом fixLength
    D:=Twig[0];
    Angle:=Atan2(D.YDot-Y,D.XDot-X)+Pi/2;
   //
    X:=D.XDot+fixLength*cos(Angle);
    Y:=D.YDot-fixLength*sin(Angle);
   // mX:=xyNull;mY:=Y;
    Twig[3].XDot:=X;Twig[3].YDot:=Y;
    mX:=X;mY:=Y;
   end;
//    Tw.OrthoTwig(XX,YY,addAngle,True);
{   fix:=Distance(TDot(Twig[0]).XDot,TDot(Twig[0]).YDot,TDot(Twig[1]).XDot,TDot(Twig[1]).YDot);
   if (fix<>xyNull)then begin  // расчитываем координату с учетом fixLength
    D:=Twig[2];
    Angle:=Atan2(D.YDot-YY,D.XDot-XX)+Pi/2;
   //
    X:=D.XDot+fix*cos(Angle);
    Y:=D.YDot-fix*sin(Angle);
    mx:=X;my:=Y;
    Twig[3].XDot:=X;Twig[3].YDot:=Y;
    If Distance(X,Y,Twig[0].XDot,Twig[0].YDot)<Distance(Twig[2].XDot,Twig[2].YDot,Twig[0].XDot,Twig[0].YDot) then begin
     mX:=X;mY:=Y;
     Twig[3].XDot:=X;Twig[3].YDot:=Y;
    end else begin
     X:=Twig[2].XDot+fix*cos(Pi+Angle);
     Y:=Twig[2].YDot-fix*sin(Pi+Angle);
     Tw.OrthoTwig(X,Y,addAngle,True);
     Twig[3].XDot:=X;Twig[3].YDot:=Y;
     mX:=X;mY:=Y;
   end;
   Tw.Free;
   end;    }
  end;
 finally UpdateGeometry; end;
end;

{ TTwigPathKvant }

constructor TTwigPathKvant.Create(TwigClass: TTwigClass; Params: Pointer; X, Y: Double);
begin
 inherited Create(TwigClass, Params);
 X1 := X;
 Y1 := Y;
end;

procedure TTwigPathKvant.Calculate;
var XC1,YC1,XC2,YC2,xC,yC:Double;
    PL:TLineZas;
    D:TDot;
    Angle,dirAngle,a1,a2:Double;
    R:Double;Tw1,Tw2:TTwig;
begin
 If TwigStyle = 0 then inherited else begin
  If Twig.Coord.Count<2 then exit;
  // расчитываем центр окружности
  PL:=TLineZas.Create;
  Coord[1].XDot:=X1;Coord[1].YDot:=Y1;
 D:=Coord[0];
  Angle:=(Pi*(cirKvant-2))/cirKvant/2;
  dirAngle:=Direct_Angle(X1,Y1,mx,my);
  a1:=dirAngle-Angle;
  XC1:=X1+10*cos(a1);
  YC1:=Y1+10*sin(a1);
  dirAngle:=Direct_Angle(mX,mY,X1,Y1);
  a2:=dirAngle+Angle;
  XC2:=mX+15*cos(a2);
  YC2:=mY+15*sin(a2);
  lines_intersection( x1, y1, xc1, yc1, mX, mY, xc2, yc2, xC, yC );
//   PSetPixel(xC,yC);
  Coord[0].XDot:=XC;Coord[0].YDot:=YC;
//  XC:=
//   Twig.Calculate;
 end;
end;

procedure TTwigPathKvant.Draw(const Canvas: ISkCanvas);
begin
 inherited;
end;

{ TOrthoTwig }

constructor TOrthoTwig.Create(Twig_: TTwig; Name_: String; addAngle_: Double);
begin
 ParentTwig := Twig_;
 Twigs := PCollection.Create(1);
 Name := Name_;
 addAngle := addAngle_;
end;

destructor TOrthoTwig.Destroy;
begin
 ParentTwig.OnDestroy:=nil;
 Twigs.Free;
end;

procedure TOrthoTwig.Draw(const Canvas: ISkCanvas; const Paint: ISkPaint);
var I: Integer;
begin
 if ParentTwig.Closed <> 1 then exit;
 for I := 0 to Twigs.Count - 1 do SkDrawTwig(Canvas, TwigIndex[I], Paint);
end;

function TOrthoTwig.FindOrthoTwig(fTwig: TTwig): Boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Twigs.Count-1 do If fTwig=Twigs[I] then begin Result:=True;Exit;end;
end;

function TOrthoTwig.GetNearestPoint(X,Y:Double;var a, b, Dist: Double;P:Pcollection): TTwig;
var Twig:TTwig;S,MinDist:Double;
    I:Integer;
begin
 Result:=nil;
 MinDist:=Dist;Twig:=nil;
 For I:=0 to Twigs.Count-1 do begin
  If ParentTwig.Closed=1 then begin
   S:=TwigIndex[I].GetTwigDist(X,Y,a,b);
   If XRasst(S)<=TForm2(GTwgForm).Settings.psAutoDisst then If P.IndexOf(TwigIndex[I])=-1 then P.Insert(TwigIndex[I]);
   If (S<MinDist) then begin Twig:=TwigIndex[I];MinDist:=S;end;
   end;
 end;
 If Twig<>nil then begin Result:=Twig;Dist:=MinDist;end;
end;

function TOrthoTwig.GetTwig(Index: Integer): TTwig;
begin
 Result:=Twigs[Index];
end;


procedure TOrthoTwig.UpdateTwig;
var I:Integer;
    D1,D2:TDot;Angle:Double;Tw:TTwig;X,Y:Double;
    TC:TTwigCircle;
    CR:TCircRecord;
Function PackOrtho:Integer;
begin
end;
begin
 Twigs.FreeAll;
// if not TForm2(GTwgForm).Settings.psOrthoTwigs then exit;
// if ParentTwig.Coord.Count>TForm2(GTwgForm).Settings.psOrthoTwigsCount then exit;
 If ParentTwig is TTwigCircle then exit;
 If ParentTwig.Coord.Count=1 then begin
 {}
  D1:=ParentTwig[0];
  X:=D1.XDot+pathLen*cos(addAngle);
  Y:=D1.YDot-pathLen*sin(addAngle);
   Tw:=TTwig.Create(GSelector, 0);
    Tw.Insert(TDot.Create(X,Y,0));
   X:=D1.XDot-pathLen*cos(addAngle);
   Y:=D1.YDot+pathLen*sin(addAngle);
    Tw.Insert(TDot.Create(X,Y,0));
   Twigs.Insert(Tw);
    Tw.SetMinMax;
 {}
   X:=D1.XDot+pathLen*cos(addAngle+Pi/2);
   Y:=D1.YDot-pathLen*sin(addAngle+Pi/2);
   Tw:=TTwig.Create(GSelector, 0);
    Tw.Insert(TDot.Create(X,Y,0));
   X:=D1.XDot-pathLen*cos(addAngle+Pi/2);
   Y:=D1.YDot+pathLen*sin(addAngle+Pi/2);
    Tw.Insert(TDot.Create(X,Y,0));
   Twigs.Insert(Tw);
    Tw.SetMinMax;
  exit;
 end;
 If ParentTwig.Coord.Count<2 then exit;
 If ParentTwig is TTwigArc then With TTwigArc(ParentTwig) do begin
  CR:=TCircRecord.Create(C.XDot,C.YDot,D.XDot,D.YDot);
  TC:=TTwigCircle.Create(GSelector, Twig_OrthoPoint,CR);
  TC.Calculate;
  CR.Free;
  Twigs.Insert(TC);
  Tw:=TTwig.Create(GSelector, 0);
  Tw.Insert(TDot.Create(C.XDot-pathLen,C.YDot,0));Tw.Insert(TDot.Create(C.XDot+pathLen,C.YDot,0));
  Tw.Insert(TDot.Create(C.XDot,C.YDot-pathLen,0));Tw.Insert(TDot.Create(C.XDot,C.YDot+pathLen,0));
  Twigs.Insert(Tw);
  exit;
 end;{ else
 If ParentTwig is TTwigCircle then With TTwigCircle(ParentTwig) do begin
  Tw:=TTwig.Create(GSelector, 0);
  Tw.Insert(TDot.Create(C.XDot-pathLen,C.YDot,0));Tw.Insert(TDot.Create(C.XDot+pathLen,C.YDot,0));
  Tw.Insert(TDot.Create(C.XDot,C.YDot-pathLen,0));Tw.Insert(TDot.Create(C.XDot,C.YDot+pathLen,0));
  Twigs.Insert(Tw);
  exit;
 end; }
 D1:=ParentTwig[0];D2:=ParentTwig[1];
 Angle:=Atan2(D1.YDot-D2.YDot,D1.XDot-D2.XDot);
//
 X:=D1.XDot+pathLen*cos(Angle);
 Y:=D1.YDot-pathLen*sin(Angle);
 Tw:=TTwig.Create(GSelector, 0);
  Tw.Insert(TDot.Create(X,Y,0));
 X:=D1.XDot-pathLen*cos(Angle);
 Y:=D1.YDot+pathLen*sin(Angle);
  Tw.Insert(TDot.Create(X,Y,0));
 Twigs.Insert(Tw);
  Tw.SetMinMax;
 For I:=0 to ParentTwig.Coord.Count-2 do begin
  D1:=ParentTwig[I];D2:=ParentTwig[I+1];
  Angle:=Atan2(D1.YDot-D2.YDot,D1.XDot-D2.XDot)+Pi/2;
  X:=D1.XDot+pathLen*cos(Angle);
  Y:=D1.YDot-pathLen*sin(Angle);
  Tw:=TTwig.Create(GSelector, 0);
   Tw.Insert(TDot.Create(X,Y,0));
  X:=D2.XDot-pathLen*cos(Angle);
  Y:=D2.YDot+pathLen*sin(Angle);
   Tw.Insert(TDot.Create(X,Y,0));
  Twigs.Insert(Tw);//If ParentTwig.Properties<>nil then Tw.Properties:=TProperties.CreateAs(ParentTwig.Properties);
  Tw.SetMinMax;
 end;
 D1:=ParentTwig[ParentTwig.Coord.Count-1];D2:=ParentTwig[ParentTwig.Coord.Count-2];
 Angle:=Atan2(D1.YDot-D2.YDot,D1.XDot-D2.XDot);
//
 X:=D1.XDot+pathLen*cos(Angle);
 Y:=D1.YDot-pathLen*sin(Angle);
 Tw:=TTwig.Create(GSelector, 0);//If ParentTwig.Properties<>nil then Tw.Properties:=TProperties.CreateAs(ParentTwig.Properties);
  Tw.Insert(TDot.Create(X,Y,0));
 X:=D1.XDot-pathLen*cos(Angle);
 Y:=D1.YDot+pathLen*sin(Angle);
  Tw.Insert(TDot.Create(X,Y,0));
 Twigs.Insert(Tw);//If ParentTwig.Properties<>nil then Tw.Properties:=TProperties.CreateAs(ParentTwig.Properties);
  Tw.SetMinMax;
//
 PackOrtho;
end;

{ TOrthoTwigs }

procedure TOrthoTwigs.Add(Tw: TTwig;Nm:String);
var  I:Integer;
begin
// Writeln('ortho');
// Writeln('ortho1 ',Twigs.Count,' ',Tw.Coord.Count);
 Tw.OnDestroy:=OnDestroy;
 For I:=0 to Twigs.Count-1 do If (TOrthoTwig(Twigs.List[I]).ParentTwig.Coord.Count = 1) and (Tw.Coord.Count = 1) then begin
  If EqualPoints(TOrthoTwig(Twigs.List[I]).ParentTwig[0],Tw[0]) then Exit;
 end else
  If TOrthoTwig(Twigs.List[I]).ParentTwig=Tw then Exit;
// Writeln('ortho2');
 Twigs.Insert(TOrthoTwig.Create(Tw,Nm,addAngle));
// Writeln('ortho3');
 Twig[Twigs.Count-1].UpdateTwig;
// Writeln('ortho4');
end;

procedure TOrthoTwigs.Delete(Tw: TTwig);
var  I:Integer;
begin
 For I:=0 to Twigs.Count-1 do If TOrthoTwig(Twigs.List[I]).ParentTwig=Tw then begin
  Twigs.AtFree(I);
  Exit;
 end;
end;

constructor TOrthoTwigs.Create;
begin
 Twigs := PCollection.Create(1);
 ActiveLines := PCollection.Create(1);
end;

destructor TOrthoTwigs.Destroy;
begin
 Twigs.FreeAll;
 ActiveLines.FreeAll;
 ActiveLines.Free;
end;

procedure TOrthoTwigs.Draw(const Canvas: ISkCanvas; RealyDraw: Boolean);
var I: Integer;
    Paint: ISkPaint;
begin
// все направляющие (отладка)
 if (Canvas = nil) or not RealyDraw then exit;
 Paint := SkPen(Canvas, TAlphaColorRec.Silver, 1, True);
 for I := 0 to Twigs.Count - 1 do Twig[I].Draw(Canvas, Paint);
end;

function TOrthoTwigs.GetCountOrthoTwigs: Integer;
var I,Count:Integer;
begin
 Count:=0;
 For I:=0 to Twigs.Count-1 do begin
  Inc(Count,Twig[I].Twigs.Count);
 end;
 Result:=Count;
end;

function TOrthoTwigs.GetNearestTwig(X, Y: Double; var a, b, Dist: Double;P:PCollection): TTwig;
var MinDist:Double;Twig:TTwig;
    I:Integer;
begin
 Result:=nil;MinDist:=10000000000;
 For I:=0 to Twigs.Count-1 do begin
  Dist:=MinDist;
  Twig:=Self.Twig[I].GetNearestPoint(X,Y,a,b,Dist,P);
  If Twig<>nil then
   If Dist<MinDist then begin MinDist:=Dist;Result:=Twig;end;
 end;
end;

function TOrthoTwigs.GetTwig(Index: Integer): TOrthoTwig;
begin
 Result:=Twigs[Index];
end;

procedure TOrthoTwigs.SetCountOrthoTwigs(const Value: Integer);
begin
end;

procedure TOrthoTwigs.UpdateTwigs;
var I:Integer;
begin
 For I:=Twigs.Count-1 downTo 0 do try
  Twig[I].UpdateTwig;
 except ShowMessage('drawTwigs '+IntToStr(895));Twigs.AtFree(I);WriteIn(['errorUpdateOrtho']);end;
end;

procedure TOrthoTwigs.Pack(Nm: String);
var I:Integer;
begin
 For I:=Twigs.Count-1 downTo 0 do
  If Twig[I].Name = Nm then Twigs.AtFree(I);
end;

function TOrthoTwigs.FindOrthoTwig(fTwig: TTwig): boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Twigs.Count-1 do If Twig[I].FindOrthoTwig(fTwig) then begin Result:=True;Exit;end;
end;

procedure TOrthoTwigs.OnDestroy(Sender: TObject);
var I:Integer;
begin
 For I:=0 to Twigs.Count-1 do If Twig[I].ParentTwig = Sender then begin
 // Writeln('OnDestroy=',I);
  Twigs.AtFree(I);
  exit;
 end;
end;

procedure TOrthoTwigs.DrawLines(Canvas: TCanvas; Lines: PCollection);
var I: Integer;
    Tw: TTwig;
function FindOrthos(Tw: TTwig): Boolean;
var J: Integer;
    OrTwig: TTwig;
begin
 Result := False;
 for J := 0 to ActiveLines.Count - 1 do begin
  OrTwig := ActiveLines[J];
  if (OrTwig.Coord.Count < 2) or (Tw.Coord.Count < 2) then continue;
  if Round((Direct_Angle(OrTwig[0].XDot, OrTwig[0].YDot, OrTwig[1].XDot, OrTwig[1].YDot) - Direct_Angle(Tw[0].XDot, Tw[0].YDot, Tw[1].XDot, Tw[1].YDot)) * 1000) = 0 then exit(True);
 end;
end;
begin
// направляющие из Lines, к которым притянулся курсор, становятся видимыми:
// не больше двух разного направления; хранятся копии (исходные ветви
// направляющих пересоздаются в UpdateTwig)
 for I := 0 to Lines.Count - 1 do begin
  if ActiveLines.Count > 1 then break;
  Tw := Lines[I];
  if not FindOrthoTwig(Tw) then continue;
  if FindOrthos(Tw) then continue;
  ActiveLines.Insert(TTwigClass(Tw.ClassType).CreateAsTwig(Tw, True));
 end;
end;

procedure TOrthoTwigs.HideLines(Canvas: TCanvas);
begin
 ActiveLines.FreeAll;
end;

procedure TOrthoTwigs.DrawActive(const Canvas: ISkCanvas);
var I: Integer;
    Paint: ISkPaint;
begin
 if (Canvas = nil) or (ActiveLines.Count = 0) then exit;
 Paint := SkPen(Canvas, TAlphaColorRec.Silver, 1, True);
 for I := 0 to ActiveLines.Count - 1 do SkDrawTwig(Canvas, TTwig(ActiveLines[I]), Paint);
end;

{ TTwigParaLine }

constructor TTwigParaLine.Create(TwigClass: TTwigClass; Params: Pointer; Color_: TAlphaColor);
begin
 inherited Create(TwigClass, Params, Color_);
 TwigL := TTwig.Create(GSelector, 0);
 TwigR := TTwig.Create(GSelector, 0);
 TwigT := TTwig.Create(GSelector, 0);
 TwigB := TTwig.Create(GSelector, 0);
 Rects := PCollection.Create(1);
// параметры заливки, раньше бравшиеся из формы ParaLineForm
 ParaStyle := pfNone;
 RectParam := 100;
 RectWidth := 100;
 RectSpace := 100;
end;

destructor TTwigParaLine.Destroy;
begin
 inherited;
 TwigL.Free;TwigR.Free;TwigT.Free;TwigB.Free;
 Rects.Free;
end;

procedure TTwigParaLine.Calculate;
var P,P1,P2:PCollection;x0,y0,x1,y1,Angle:Double;
    D,D2:TDot;
    I,J:Integer;
    WL,WR:Double;
    addPi:Double;
    triAngle:Double;
    DD1,DD2,DD3:tDot;
Procedure GetDotInter(var XInter,YInter:Double;XInter2,YInter2:Double;WithTwig:TTwig);
var Dist:Double;D1,D2,D3,D4:TDot;XX,YY:Double;
    IL:TInterLine;PD:TDot;Seg:Integer;
begin
 if WithTwig=nil then exit;
// дотягивание точек до сегментов
 Dist:=WithTwig.GetTwigDist(XInter,YInter,XX,YY);
 If XRasst(Distance(XInter,YInter,XX,YY))<=TForm2(GTwgForm).Settings.psAutoDisst*4 then begin
// WithTwig.Paint(GCanvas.Handle);
 Seg:=WithTwig.GetSegment(XX,YY);
 If (Seg<>-1) then begin
  D1:=WithTwig[Seg-1];D2:=WithTwig[Seg];
  D3:=TDot.Create(XInter,YInter,0);D4:=TDot.Create(XInter2,YInter2,0);
  //PMoveTo(D3.XDot,D3.YDot);PLineTo(D4.XDot,D4.YDot);
  IL:=TInterLine.Create(D1,D2,D3,D4);
  PD:=TDot.Create(0,0,0);
  D1:=nil;D3.Free;D4.Free;
  If IL.Calc2(PD,False) then begin
   XInter:=PD.XDot;YInter:=PD.YDot;
   PSetPixel(XInter,YInter);
   PD.Free;
  end;
  IL.Free;
 end;
end;
end;
Procedure DoInter(interTwig:TTwig);
begin
 GetDotInter(interTwig[0].XDot,interTwig[0].YDot,interTwig[1].XDot,interTwig[1].YDot,interFirst);
 GetDotInter(interTwig[interTwig.Coord.Count-1].XDot,interTwig[interTwig.Coord.Count-1].YDot,interTwig[interTwig.Coord.Count-2].XDot,interTwig[interTwig.Coord.Count-2].YDot,interSecond);
end;
Procedure drawRects;
var I,Count,Index:Integer;X1,Y1,X2,Y2:Double;Coord,Coord2:PCollection;
    D,D1,D2,D3:TDot;Dist,LineLength:Double;Znak:shortInt;
    Pi2:Double;AddDist,RectLength:Double;
    Retriger:boolean;Tw,Twig:TTwig;
begin
 Rects.Free;Rects:=PCollection.Create(1);
 If TwigL.Coord.Count<2 then exit;
 Coord:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 Coord2:=PCollection.Create(1);
// вставляем точки в Coord
 Dist:=0;RectLength:=RectParam/100;//Width*(RectParam)/4;
 try
  For I:=0 to Coord.Count-2 do Dist:=Dist+Distance(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot,TDot(Coord[I+1]).XDot,TDot(Coord[I+1]).YDot);
  Count:=Trunc(Dist/RectLength);
  For I:=0 to Coord.Count-1 do Coord2.Insert(TDot.Create(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot,-(I+1)));
  For I:=0 to Count do begin
   Index:=solving_point_on_polyline(Coord2, RectLength*(I), X1, Y1);
   {If Index<>0 then} Coord2.AtInsert(Index+1,TDot.Create(X1,Y1,I+1))
  end;
 //
 // For I:=0 to Coord2.Count-2 do If EqualPoints(Coord2[I],Coord2[I+1]) then TDot(Coord2[I+1]).What:=200;
 // For I:=Coord2.Count-1 downto 0 do  If TDot(Coord2[I]).What=200 then Coord2.AtFree(I);
 // Rects.Free;Rects:=PCollection.Create(1);
  Twig:=TwigL;
  For I:=0 to Coord2.Count-2 do begin
   D1:=Coord2[I];D2:=Coord2[I+1];D:=nil;
  // запускаем от первой точки D1
   Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.CreateAsDot(D1));
 //  PSetPixel(D1.XDot,D1.YDot);PSetPixel(D2.XDot,D2.YDot);
  // если точка не промежуточная -> берем сегмент слева или справа, иначе оставляем текщий
   If D1.What>0 then If not odd(D1.What) then Twig:=TwigL else Twig:=TwigR;
  //
   If D1.What>0 then Twig.GetTwigDist(D1.XDot,D1.YDot,X1,Y1) else
                       D:=Twig.GetNearestPoint(D1.XDot,D1.YDot,Index);
   If D<>nil then Tw.Insert(TDot.CreateAsDot(D)) else Tw.Insert(TDot.Create(X1,Y1,D1.What));
   D:=nil;
   If D2.What>0 then Twig.GetTwigDist(D2.XDot,D2.YDot,X1,Y1) else
                       D:=Twig.GetNearestPoint(D2.XDot,D2.YDot,Index);
   If D<>nil then Tw.Insert(TDot.CreateAsDot(D)) else Tw.Insert(TDot.Create(X1,Y1,D2.What));
   Tw.Insert(TDot.CreateAsDot(D2));Tw.Insert(TDot.CreateAsDot(D1));
  // Tw.Paint(Canvas.Handle);
   Rects.Insert(Tw);
  end;
 except end;
  Coord.Free;
 Coord2.Free;
end;
Procedure drawRects1;
var I,Count,Index,Index1,Index2:Integer;X1,Y1,X2,Y2:Double;Coord,Coord2:PCollection;
    D,D1,D2,D3,DL,DR:TDot;Dist,LineLength:Double;Znak:shortInt;
    Pi2:Double;AddDist,RectLength,SpaceLength:Double;
    Retriger:boolean;Tw,Twig,Tw1,Tw2:TTwig;
    Col:PCollection;Check:ShortInt;Delta:Integer;
begin
 Rects.Free;Rects:=PCollection.Create(1);
 If TwigL.Coord.Count<2 then exit;
 Coord:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 Coord2:=PCollection.Create(1);
// вставляем точки в Coord
 Dist:=0;RectLength:=RectWidth/100;SpaceLength:=RectSpace/100;
 For I:=0 to Coord.Count-2 do Dist:=Dist+Distance(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot,TDot(Coord[I+1]).XDot,TDot(Coord[I+1]).YDot);
 Count:=Trunc(Dist/RectLength);
 For I:=0 to Coord.Count-1 do Coord2.Insert(TDot.Create(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot,-(I+1)));
 LineLength:=RectLength;Count:=0;
 While True do begin
  Index:=solving_point_on_polyline(Coord2, LineLength, X1, Y1);
  {If Index<>0 then} Coord2.AtInsert(Index+1,TDot.Create(X1,Y1,Count+1));
  If odd(Count) then LineLength:=LineLength+RectLength else LineLength:=LineLength+SpaceLength;
  Inc(Count);
  If LineLength > (TwigL.GetLength) then break;
 end;
//
 For I:=0 to Coord2.Count-2 do If EqualPoints(Coord2[I],Coord2[I+1]) then TDot(Coord2[I+1]).What:=200;
 For I:=Coord2.Count-1 downto 0 do  If TDot(Coord2[I]).What=200 then Coord2.AtFree(I);
// Rects.Free;Rects:=PCollection.Create(1);
 Twig:=TwigL;
 Count:=0;
 Col:=PCollection.Create(1);
 For I:=0 to Coord2.Count-2 do begin
  D1:=Coord2[I];D2:=Coord2[I+1];D:=nil;
 // запускаем от первой точки D1
  Tw:=TTwig.Create(GSelector, 0);
//  PSetPixel(D1.XDot,D1.YDot);//PSetPixel(D2.XDot,D2.YDot);
 // если точка не промежуточная -> берем сегмент слева или справа, иначе оставляем текщий
  If D1.What>0 then begin
   TwigL.GetTwigDist(D1.XDot,D1.YDot,X1,Y1);//PTextOut(X1,Y1-2,'1L');
   TwigR.GetTwigDist(D1.XDot,D1.YDot,X2,Y2);//PTextOut(X2,Y2+2,'1R');
    Tw.Insert(TDot.Create(X1,Y1,0));
    Tw.Insert(TDot.CreateAsDot(D1));Tw.Insert(TDot.Create(X2,Y2,0));
  end else begin
   DL:=TwigL.GetNearestPoint(D1.XDot,D1.YDot,Index1);//PTextOut(DL.XDot,DL.YDot,'2L');
   DR:=TwigR.GetNearestPoint(D1.XDot,D1.YDot,Index2);//PTextOut(DR.XDot,DR.YDot,'2R');
   Tw.Insert(TDot.Create(DL.XDot,DL.YDot,0));
   Tw.Insert(TDot.CreateAsDot(D1));Tw.Insert(TDot.Create(DR.XDot,DR.YDot,0));
  end;
  Inc(Count);
   Col.Insert(Tw);

 end;
 Check:=1;RectLength:=Round(RectLength*100);SpaceLength:=Round(SpaceLength*100);Delta:=0;
 I:=0;
 try
  While True do begin
   Dist:=RectLength;
   While Check=1 do begin
    Tw1:=Col[I];Tw2:=Col[I+1]; PSetPixel(Tw1[1].XDot,Tw1[1].YDot);PSetPixel(Tw2[1].XDot,Tw2[1].YDot);
    Inc(I);
    Dist:=Dist-Round(Distance(Tw1[1].XDot,Tw1[1].YDot,Tw2[1].XDot,Tw2[1].YDot)*100);
   //
    If ((Dist >= 0) and odd(Check)) or (I=Col.Count-1) then begin
     Tw:=TTwig.Create(GSelector, 0);
     Tw.Insert(TDot.CreateAsDot(Tw1[0]));Tw.Insert(TDot.CreateAsDot(Tw1[1]));Tw.Insert(TDot.CreateAsDot(Tw1[2]));
     Tw.Insert(TDot.CreateAsDot(Tw2[2]));Tw.Insert(TDot.CreateAsDot(Tw2[1]));Tw.Insert(TDot.CreateAsDot(Tw2[0]));
     Tw.Insert(TDot.CreateAsDot(Tw1[0]));
     Rects.Insert(Tw);
    end;
    If Dist = 0 then begin Check:=0;break;end;
    If I=Col.Count-1 then break;
   end;
   Dist:=SpaceLength;
   If I=Col.Count-1 then break;
   While Check=0 do begin
    Tw1:=Col[I];Tw2:=Col[I+1];
    Inc(I);
    Dist:=Dist-Round(Distance(Tw1[1].XDot,Tw1[1].YDot,Tw2[1].XDot,Tw2[1].YDot)*100);
    If Dist = 0 then begin Check:=1;break;end;
    If I=Col.Count-1 then break;
   end;
   If I=Col.Count-1 then break;
  end; // While True
 except end;
 Coord.Free;
 Coord2.Free;
end;
Procedure drawRects2;
var I,Count,Index,Index1,Index2:Integer;X1,Y1,X2,Y2:Double;Coord,Coord2:PCollection;
    D,D1,D2,D3,DL,DR:TDot;Dist,LineLength:Double;Znak:shortInt;
    Pi2:Double;AddDist,RectLength:Double;
    Retriger:boolean;Tw,Twig,Tw1,Tw2:TTwig;
    Col:PCollection;Check:ShortInt;Delta:Integer;
begin
 Rects.Free;Rects:=PCollection.Create(1);
 If TwigL.Coord.Count<2 then exit;
 Coord:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 Tw:=TTwig.CreateAsTwig(TwigL,True);
 Tw.Coord.Insert(TDot.Create(TDot(Coord[Coord.Count-1]).XDot,TDot(Coord[Coord.Count-1]).YDot,0));
 For I:=TwigR.Coord.Count-1 downTo 0 do Tw.Coord.Insert(TDot.CreateAsDot(TwigR[I]));
 Tw.Coord.Insert(TDot.Create(TDot(Coord[0]).XDot,TDot(Coord[0]).YDot,0));
 Tw.Coord.Insert(TDot.CreateAsDot(Tw.Coord[0]));

 Rects.Insert(Tw);
 Coord.Free;
end;
Procedure DrawRects3;
const N17 = 0.17;
var I,Count,Index,Index1,Index2:Integer;X1,Y1,X2,Y2,X3,Y3,X4,Y4:Double;Coord,Coord2:PCollection;
    D,D1,D2,D3,DL,DR:TDot;Dist,LineLength:Double;Znak:shortInt;
    Pi2:Double;AddDist,RectLength:Double;
    Retriger:boolean;Tw,Twig,Tw1,Tw2:TTwig;
    Col:PCollection;Check:ShortInt;Delta:Integer;
    Arc:TTwigArc;AR:TArcRecord;
begin
 Rects.Free;Rects:=PCollection.Create(1);
 If TwigL.Coord.Count<2 then exit;
 Coord2:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 If Width<50 then begin TwigL.AddLines(-0.17,False);TwigR.AddLines(-0.17,False); end else begin TwigL.AddLines(-0.25,False);TwigR.AddLines(-0.25,False);end;
 Coord:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 Tw:=TTwig.CreateAsTwig(TwigL,True);
 Tw.Coord.Insert(TDot.Create(TDot(Coord[Coord.Count-1]).XDot,TDot(Coord[Coord.Count-1]).YDot,0));
 For I:=TwigR.Coord.Count-1 downTo 0 do Tw.Coord.Insert(TDot.CreateAsDot(TwigR[I]));
 Tw.Coord.Insert(TDot.Create(TDot(Coord[0]).XDot,TDot(Coord[0]).YDot,0));
 Tw.Coord.Insert(TDot.CreateAsDot(Tw.Coord[0]));
//

 Rects.Insert(Tw);
 // левая дуга
 AR:=TArcRecord.Create(TDot(Coord[0]).XDot,TDot(Coord[0]).YDot,TwigR[0].XDot,TwigR[0].YDot,TwigL[0].XDot,TwigL[0].YDot,TDot(Coord2[0]).XDot,TDot(Coord2[0]).YDot);
 Arc:=TTwigArc.Create(GSelector, 0,AR);
 Arc.Calculate;Arc.SetMinMax;
 Arc.ArcView:=1;
 Tw:=TTwig.CreateAsTwig(Arc,True);Arc.Free;AR.Free;
 Tw.Insert(TDot.CreateAsDot(Tw[0]));
 Rects.Insert(Tw);
 // правая дуга
 AR:=TArcRecord.Create(TDot(Coord[Coord.Count-1]).XDot,TDot(Coord[Coord.Count-1]).YDot,TwigR[TwigR.Coord.Count-1].XDot,TwigR[TwigR.Coord.Count-1].YDot,TwigL[TwigL.Coord.Count-1].XDot,TwigL[TwigL.Coord.Count-1].YDot,TDot(Coord2[Coord2.Count-1]).XDot,TDot(Coord2[Coord2.Count-1]).YDot);
 Arc:=TTwigArc.Create(GSelector, 0,AR);
 Arc.Calculate;Arc.SetMinMax;
 Arc.ArcView:=1;
 Tw:=TTwig.CreateAsTwig(Arc,True);Arc.Free;AR.Free;
 Tw.Insert(TDot.CreateAsDot(Tw[0]));
 Rects.Insert(Tw);
 Coord.Free;
 Coord2.Free;
// строим квадратики
 Coord:=parallel_twig(TwigL.Coord, Width/2, mx, my);
 For I:=0 to Coord.Count-2 do Dist:=Dist+Distance(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot,TDot(Coord[I+1]).XDot,TDot(Coord[I+1]).YDot);
 Count:=Trunc(Dist/N17);
 LineLength:=N17;Coord2:=PCollection.Create(1);
 For I:=0 to Coord.Count-1 do Coord2.Insert(TDot1.Create(TDot(Coord[I]).XDot,TDot(Coord[I]).YDot));
 While True do begin
  Index:=solving_point_on_polyline(Coord, LineLength, X1, Y1);
  {If Index<>0 then} Coord2.AtInsert(Index+1,TDot.Create(X1,Y1,Count+1));
  LineLength:=LineLength+N17;
  If LineLength > (TwigL.GetLength) then break;
 end;
 D1:=Coord2[0];D2:=Coord2[1];
 Angle:=Atan2(D1.YDot-D2.YDot,D1.XDot-D2.XDot);
 For I:=1 to Coord2.Count-2 do if Odd(I) then begin
  // вычисляем вершины
  D:=Coord2[I];
  X1:=D.XDot-(N17*Sin(Angle+Pi/2));
  Y1:=D.YDot-(N17*Cos(Angle+Pi/2));
  X2:=X1+(N17/2*Sin(Angle));
  Y2:=Y1+(N17/2*Cos(Angle));
  Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.Create(X1,Y1,0));Tw.Insert(TDot.Create(X2,Y2,0));
  X1:=D.XDot-(N17/2*Sin(Angle+Pi/2));
  Y1:=D.YDot-(N17/2*Cos(Angle+Pi/2));
  X2:=X1+(N17/2*Sin(Angle));
  Y2:=Y1+(N17/2*Cos(Angle));
  Tw.Insert(TDot.Create(X2,Y2,0));Tw.Insert(TDot.Create(X1,Y1,0));Tw.Insert(TDot.CreateAsDot(Tw[0]));
  Tw.SetMinMax;Tw.What:=150;
  Rects.Insert(Tw);
 //
  X3:=D.XDot-(N17*Sin(Angle-Pi/2));
  Y3:=D.YDot-(N17*Cos(Angle-Pi/2));
  X4:=X3+(N17/2*Sin(+Angle));
  Y4:=Y3+(N17/2*Cos(+Angle));
  Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.Create(X3,Y3,0));Tw.Insert(TDot.Create(X4,Y4,0));
  X3:=D.XDot-(N17/2*Sin(Angle-Pi/2));
  Y3:=D.YDot-(N17/2*Cos(Angle-Pi/2));
  X4:=X3+(N17/2*Sin(+Angle));
  Y4:=Y3+(N17/2*Cos(+Angle));
  Tw.Insert(TDot.Create(X4,Y4,0));Tw.Insert(TDot.Create(X3,Y3,0));Tw.Insert(TDot.CreateAsDot(Tw[0]));
  Tw.SetMinMax;Tw.What:=150;
  Rects.Insert(Tw);
 end;
 Coord.Free;
 Coord2.Free;
end;
begin
 TwigL.Coord.FreeAll;TwigR.Coord.FreeAll;TwigB.Coord.FreeAll;TwigT.Coord.FreeAll;
 Rects.FreeAll;
// ищем точку для TwigL
 If Twig.Coord.Count>0 then begin
  P:=PCollection.Create(1);x0:=Twig[Count-1].XDot;y0:=Twig[Count-1].YDot;
  P.Insert(TDot.Create(x0-1,y0,0));P.Insert(TDot.Create(x0+1,y0,0));
  addPi:=Pi/2;If Twig.Coord.Count>3 then If EqualPoints(Twig[0],Twig[Count-1]) then begin
   DD2:=Twig.GetThreeFold(Twig[0].XDot,Twig[1].YDot,DD1,DD3);
 //  triAngle:=Direct_Angle(DD2.YDot,DD2.XDot,DD1.YDot,DD1.XDot)-Direct_Angle(DD2.YDot,DD2.XDot,DD3.YDot,DD3.XDot);
  // Writeln('triAngle = ',triAngle*180/Pi:8:2);
//   If Angle = -90 then addPi:=addPi+Pi/4 else  addPi:=addPi-Pi/4;
  end;
  If Twig.Coord.Count=1 then Angle:=AddAngle+Pi/2 else Angle:=Atan2(Twig[Count-1].XDot-Twig[Count-2].XDot,Twig[Count-1].YDot-Twig[Count-2].YDot)+Pi/2;
  RotateDots(x0,y0,Angle,P);
  x0:=TDot(P[0]).XDot;y0:=TDot(P[0]).YDot;
  x1:=TDot(P[1]).XDot;y1:=TDot(P[1]).YDot;
 // PSetPixel(x0,y0);PTextOut(x0,y0,'0');
 // PSetPixel(x1,y1);PTextOut(x1,y1,'1');
{  If (twigStyle = hsLeft) then begin x0:=TDot(P[0]).XDot;y0:=TDot(P[0]).YDot end else
  If twigStyle = hsRight then begin x0:=TDot(P[1]).XDot;y0:=TDot(P[1]).YDot;end else begin
   x0:=TDot(P[0]).XDot;y0:=TDot(P[0]).YDot;
   x1:=TDot(P[1]).XDot;y1:=TDot(P[1]).YDot;
  end;}
  P.Free;
  If Twig.Coord.Count>1 then begin
   Case twigStyle of
    hsLeft,
    hsRight:begin
             WR:=Width;
             P1:=PCollection.Create(1);
             For I:=0 to Twig.Coord.Count-1 do P1.Insert(TDot1.Create(Twig[I].XDot,Twig[I].YDot));
             //P1:=parallel_twig(Twig.Coord, 0, x0, y0);
             P2:=parallel_twig(Twig.Coord, WR, mx, my);
              For I:=0 to P1.Count-1 do With TDot1(PCollection(P1).At(I)) do TwigL.Insert(TDot.Create(X,Y,0));
              For I:=0 to P2.Count-1 do With TDot1(PCollection(P2).At(I)) do TwigR.Insert(TDot.Create(X,Y,0));
              P1.Free;P2.Free;
              If ParaStyle = pfHatch then drawRects else
              If ParaStyle = pfStroke then drawRects1 else
              If ParaStyle = pfSolid then drawRects2 else
              If ParaStyle = pfIDN then drawRects3 else
            end;
    hsCenter:begin WR:=Width/2;
              P:=parallel_twig_II(Twig.Coord, WR,WR, x0,y0);
              With PCollection(P) do begin P1:=P[0];P2:=P[1];end;
               For I:=0 to P1.Count-1 do With TDot1(PCollection(P1).At(I)) do TwigL.Insert(TDot.Create(X,Y,0));
               For I:=0 to P2.Count-1 do With TDot1(PCollection(P2).At(I)) do TwigR.Insert(TDot.Create(X,Y,0));
              P.Free;
              If ParaStyle = pfHatch then drawRects else
              If ParaStyle = pfStroke then drawRects1 else
              If ParaStyle = pfSolid then drawRects2 else
              If ParaStyle = pfIDN then drawRects3 else
             end;
   end;
   TwigL.Calculate;TwigR.Calculate;
   // дотягиваем до interВеток
   DoInter(TwigL);DoInter(TwigR);
  end;
 end;
end;

procedure TTwigParaLine.Draw(const Canvas: ISkCanvas);
var Paint: ISkPaint;
    D: TDot;
    I: Integer;
begin
 if (Canvas = nil) or (Twig.Coord.Count = 0) then exit;
 Paint := SkPen(Canvas, Color, 1, True);
 SkDrawTwig(Canvas, TwigL, Paint);
 SkDrawTwig(Canvas, TwigR, Paint);
 D := Twig[Twig.Coord.Count - 1];
 if mX <> xyNull then Canvas.DrawLine(D.XDot, D.YDot, mX, mY, Paint);
// заливка (штриховка, прямоугольники) - черным пунктиром
 Paint := SkPen(Canvas, TAlphaColorRec.Black, 1, True);
 for I := 0 to Rects.Count - 1 do SkDrawTwig(Canvas, TTwig(Rects[I]), Paint);
end;

procedure TTwigParaLine.UpdateGeometry;
begin
 TwigL.Closed := 1;
 TwigL.Calculate;
 TwigR.Closed := 1;
 TwigR.Calculate;
 TwigVisible := True;
 UpdateOrthoMarker;
end;

{ TNearestPoint }

constructor TNearestPoint.Create(Dot_: TDot; Twig_: TTwig);
begin
 X:=Dot_.XDot;Y:=Dot_.YDot;
 RootTwig:=Twig_;
 Twig:=nil;
 If Twig_<>nil then begin
  Twig:=TTwigClass(Twig_.ClassType).CreateAsTwig(Twig_,True);
  Dot:=Twig[Twig_.TwigCoord.IndexOf(Dot_)];
 end else Dot:=Dot_;
end;

procedure TNearestPoint.DrawTo(const Canvas: ISkCanvas; X, Y: Double);
var OldX, OldY: Double;
    Error: AnsiString;
    Paint: ISkPaint;
    R: Single;
begin
 if Canvas = nil then exit;
 Paint := SkPen(Canvas, TAlphaColorRec.Red, 1, False);
 OldX := Dot.XDot;
 OldY := Dot.YDot;
 try
  if Twig <> nil then begin
  // ветвь с временно перемещенной точкой
   if not Twig.isMovePointValid(Twig.Coord.IndexOf(Dot), X, Y, Error) then exit;
   if not Twig.MovePoint(Twig.Coord.IndexOf(Dot), X, Y) then begin Dot.XDot := X; Dot.YDot := Y; end;
   Twig.Calculate;
   SkDrawTwig(Canvas, Twig, Paint);
  end else begin
  // точечный объект - квадрат в новом положении
   R := SkPixToWorld(Canvas, 4);
   Canvas.DrawRect(TRectF.Create(X - R, Y - R, X + R, Y + R), Paint);
  end;
 finally
  if Twig <> nil then begin
   if not Twig.MovePoint(Twig.Coord.IndexOf(Dot), OldX, OldY) then begin Dot.XDot := OldX; Dot.YDot := OldY; end;
  end else begin
   Dot.XDot := OldX;
   Dot.YDot := OldY;
  end;
 end;
end;

procedure TNearestPoint.UpdateTwig;
var I:integer;TW:TTwigArc;
begin
 If RootTwig is TTwigArc then With TTwigArc(RootTwig) do begin
  TW:=TTwigArc(Twig);
  C.XDot:=TW.C.XDot;C.YDot:=TW.C.YDot;
  A.XDot:=TW.A.XDot;A.YDot:=TW.A.YDot;
  B.XDot:=TW.B.XDot;B.YDot:=TW.B.YDot;
  D.XDot:=TW.D.XDot;D.YDot:=TW.D.YDot;
//  DOld.XDot:=TW.DOld.XDot;DOld.YDot:=TW.DOld.YDot;
  Calculate;SetMinMax;
 end else begin
  If not RootTwig.MovePoint(Twig.Coord.IndexOf(Dot),Dot.XDot,Dot.YDot) then begin
   RootTwig[Twig.Coord.IndexOf(Dot)].XDot:=Dot.XDot;
   RootTwig[Twig.Coord.IndexOf(Dot)].YDot:=Dot.YDot;
  end;
  RootTwig.Calculate;RootTwig.SetMinMax;
 end;
end;

{ TNearestPoints }

constructor TNearestPoints.Create(Form:TForm2);
begin
 TwgForm:=Form;
 selPoints:=PCollection.Create(1);
end;

function TNearestPoints.GetPoints(Objs:PCollection;X,Y:Double):Integer;
var I,J,K:Integer;Lot:TLot;Tw:TTwig;
    Dist,MinDist:Double;
begin
 Objects:=Objs;
 selPoints.FreeAll;
 MinDist:=100000000;
 For I:=0 to Objects.Count-1 do begin
 If (TObject(Objects[I]) is TPointDot) then With TDot(Objects[I]) do begin
  If Distance(X,Y,XDot,YDot)<MinDist then begin XSelect:=XDot;YSelect:=YDot;MinDist:=Distance(X,Y,XDot,YDot)end;
 end else
 If (TObject(Objects[I]) is TLot) then begin
  Lot:=TLot(Objects[I]);
  For J:=0 to Lot.Coord.Count-1 do begin
   Tw:=Lot.GetTwig(TwgForm.Twigs,J);
    For K:=0 to Tw.Coord.Count-1 do With Tw[K] do If Distance(X,Y,XDot,YDot)<MinDist then begin XSelect:=XDot;YSelect:=YDot;MinDist:=Distance(X,Y,XDot,YDot);end;
  end;
 end;
 end;
 If MinDist = 100000000 then exit;
 If XRasst(Distance(X,Y,XSelect,YSelect))<=TwgForm.Settings.psAutoDisst then begin
  For I:=0 to Objects.Count-1 do begin
  If (TObject(Objects[I]) is TPointDot) then With TDot(Objects[I]) do begin
   If Distance(XDot,YDot,XSelect,YSelect)<=0.001 then selPoints.Insert(TNearestPoint.Create(Objects[I],nil));
  end else
  If (TObject(Objects[I]) is TLot) then begin
   Lot:=TLot(Objects[I]);
   For J:=0 to Lot.Coord.Count-1 do begin
    Tw:=Lot.GetTwig(TwgForm.Twigs,J);
     For K:=0 to Tw.Coord.Count-1 do With Tw[K] do If Distance(XDot,YDot,XSelect,YSelect)<=0.001 then selPoints.Insert(TNearestPoint.Create(Tw[K],Tw));
   end;
  end;
  end;
 end;
 Result:=selPoints.Count;
end;

destructor TNearestPoints.Destroy;            
var I:Integer;
begin
 inherited;
// For I:=0 to SelPoints.Count-1 do If SelPoint[I].Twig<>nil then
 SelPoints.Free;
end;

procedure TNearestPoints.DrawTo(const Canvas: ISkCanvas; X, Y: Double);
var I: Integer;
begin
 for I := 0 to SelPoints.Count - 1 do SelPoint[I].DrawTo(Canvas, X, Y);
end;

function TNearestPoints.GetselPoint(Index: Integer): TNearestPoint;
begin
 Result:=selPoints[Index];
end;

function TNearestPoints.SetXY(X, Y: Double):boolean;
var I:Integer;OldX,OldY:Double;Error:AnsiString;
Function RedoLots(Twig:TTwig):boolean;
var Lot:TLot;I,J:Integer;
begin
 Result:=True;
 With TwgForm do
 For I:=0 to Twigs.LotsCount-1 do begin
  Lot:=Twigs.LAt(I);
   For J:=0 to Lot.Coord.Count-1 do begin
    If Lot.GetTwig(Twigs,J)=Twig then begin
     Result:=UpdateMessage.ModifiedPrim(Lot);
     if not Result then break;
    end;
   end;
 end;
end;
begin
 Result:=True;
 try
  For I:=selPoints.Count-1 downTo 0 do begin
   OldX:=selPoint[I].Dot.XDot;OldY:=selPoint[I].Dot.YDot;
   If selPoint[I].Twig<>nil then begin
    If not TTwigRect(SelPoint[I].Twig).MovePoint(SelPoint[I].Twig.Coord.IndexOf(SelPoint[I].Dot),X,Y,True) then begin
     SelPoint[I].Dot.XDot:=X;
     SelPoint[I].Dot.YDot:=Y;
    end;
   end else begin
     SelPoint[I].Dot.XDot:=X;
     SelPoint[I].Dot.YDot:=Y;
   end;
   If selPoint[I].Twig=nil then begin
    If TPointDot(SelPoint[I].Dot).userObj<>nil then
    // If TPointDot(SelPoint[I].Dot).userObj.objType=TWG_Ole then TPointDot(SelPoint[I].Dot).userObj.Move(X-OldX,Y-OldY,0);
   end;
   If selPoint[I].Twig<>nil then begin
   SelPoint[I].Twig.Calculate;
    If not SelPoint[I].Twig.isMovePointValid(SelPoint[I].Twig.Coord.IndexOf(SelPoint[I].Dot),X,Y,Error) then begin
     If not SelPoint[I].Twig.MovePoint(SelPoint[I].Twig.Coord.IndexOf(SelPoint[I].Dot),OldX,OldY) then begin
      SelPoint[I].Dot.XDot:=OldX;
      SelPoint[I].Dot.YDot:=OldY;
     end;
     selPoint[I].Twig.Calculate;
     Result:=False;
     exit;
    end;
    If not RedoLots(selPoint[I].Twig) then begin
     SelPoint[I].Dot.XDot:=OldX;
     SelPoint[I].Dot.YDot:=OldY;
     Result:=False;
    end else begin
     selPoint[I].UpdateTwig;
     selPoint[I].Twig.Calculate;
    end;
   end else
   If not UpdateMessage.ModifiedPrim(selPoint[I].Dot) then begin
    SelPoint[I].Dot.XDot:=OldX;
    SelPoint[I].Dot.YDot:=OldY;
    If SelPoint[I].Twig<>nil then SelPoint[I].Twig.Calculate;
    Result:=False;
   end;
  end;
 except ShowMessage('drawTwigs '+IntToStr(1218));Result:=False;end;
end;

function TNearestPoints.FindTwig(Tw: TTwig): Boolean;
var I:Integer;
begin
 Result:=True;
 For I:=0 to selPoints.Count-1 do If selPoint[I].RootTwig=Tw then Exit;
 Result:=False;
end;


function TNearestPoints.FindNearestPoint(X, Y: Double): TNearestPoint;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to selPoints.Count-1 do
  If EqualAnyPoints(selPoint[I].Dot.XDot,selPoint[I].Dot.YDot,X,Y) then begin
   Result:=selPoint[I];
   exit;
  end;
end;

function TNearestPoints.isBlock(X,Y:Double): boolean;
var sP:TNearestPoint;
begin
 Result:=False;exit;
 FindNearestPoint(X,Y)
end;

initialization
 OrthoTwigs:=TOrthoTwigs.Create;
finalization
 OrthoTwigs.Free;
end.
