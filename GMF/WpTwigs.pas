{$N+}
Unit WpTwigs;

Interface

uses Classes, Collect, SysUtils, System.Types,
     ECDot, TwgDraw, newConsts, EMath, newResource, newProcs, maths_basic,
     Types_dimano, newProperties, Splines, newSelector;

{ }
{ Графические примитивы [.Twg] }
{ ----------------------------------------------------------------------- }

{ Ветвь-семантический код = TWG_Twig }

Const
 TWG_Twig = 1;
 TWG_LOT = 3;

 { Какого типа ветвь }
 Twig_Any = 0; // простая ветвь из сколки
 Twig_3D = 1; // 3D ветка
 Twig_Promer = 2; // промер
 Twig_Taheo = 3; // тахео
 Twig_Dxf = 4; // из DXF
 Twig_Data = 5; // из БД
 Twig_Arc = 6; // сплайн
 Twig_Coord = 7; // построена по координатам
 Twig_Lines = 8; // ветка для рисовки
 Twig_Class = 9; // ветка с кодом
 Twig_Scolka = 10; // ветка с кодом
 Twig_Cut = 11; // ветвь отсеченная полигоном
 Twig_PerPend = 12;
 Twig_Arc1 = 13;
 Twig_Spline = 14;
 Twig_3DSpline = 15;
 Twig_Triangle = 16;
 Twig_Coif = 17;
 Twig_Circle = 18;
 Twig_OrthoPoint = 19;
 // если захвачена точка то - это ветвь - направляющие по точке
 Twig_AutoCreate = 200;
 Twig_MultiLine = 20;

 { Флаги доступности }
 Acc_Twise = 1;
 Acc_InsPoint = 2;
 Acc_Union = 3;
 Acc_Edges = 4;
 Acc_Inter = 5;
 Acc_Join = 6;
 Acc_Hold = 7;
 Acc_LineNesost = 8;
 Acc_MoveOn = 9;
 Acc_Rotate = 10;
 Acc_DeletePoint = 11;

 { }
 Quants_For_Arcs: Integer = 30;
 GTwigsCount: Integer = 0;

Type
 TAccessFlag = Integer;
 TAngleFlag = (afonly90, afany);

Type
 hDc = Integer;
 { TTwig }

 TTwig = Class(TTD)
 private
  fSelector:TSelector;
  fOnDestroy: TNotifyEvent;
  function ReadDot(Index: Integer): TDot;
  procedure WriteDot(Index: Integer; const Value: TDot);
  function GetStColor: Integer;
 public
  { }
  ParentIndex: Integer; // индекс в коллекции ветвей
  TaheoIndex: SmallInt;
  { }
  Closed: Byte;
  Color: TRgbRec;
  Rang: SmallInt;
  UZnak: SmallInt;
  TwigCoord: PCollection; { Координаты ветви }
  Inv: Byte;
  Opr: Byte;
  XMax, YMax, XMin, YMin: Single;
  IsDraw: boolean;
  IsVis: boolean;
  isCheck: boolean;
  { }
  MakeUsel: boolean;
  NotPere: Byte;
  PereFree: Byte;
  PDraw: boolean;
  { }
  Locked: Byte; // ветка использует свой условный знак
  { }
  What: Byte; // означает тип ветви
  ArcView: Byte; // доступ к альтернативным координатам
  { }
  ZDx: Single; // смещение знаков по линии
  { }
  Koef: Single;
  Properties: TProperties;
  LineWidth: Single;
  { }
  Lots: PCollection;
  ClassHandle: TResource;
  AlwaysVisible: boolean;
  Function  GetSelector:TSelector;override;
  Procedure SetSelector(S:TSelector);override;
  function IsVisRect: boolean;
  function IsVisGlobal: boolean;
  Constructor Create(W1: Integer; Data: Pointer = nil); virtual;
  Constructor CreateAsTwig(Twig: TTwig; AddCoord: boolean); virtual;
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
  Function GetData: Pointer; virtual;
  Procedure Insert(P: TDot);
  Procedure Insert3DPoint(P: TPointDot);
  Procedure AtPut(Index: SmallInt; P: TDot);
  Procedure MinMax(X, Y: Double);
  { Рисование }
  Function IsVisible(R: TRect): boolean;
  Function IsMinimal: boolean;
  { }
  Function GetTwigDist(XDrag, YDrag: Double; Var X1, Y1: Double)
    : Double; Virtual;
  Procedure Rotation; virtual;
  { Захват и отображение точки при перемещении }
  Function GetNearestPoint(XDrag, YDrag: Double; var Index: Integer)
    : TDot; Virtual;
  { }
  Function isMovePointValid(Index: Integer; XX, YY: Double;
    var Error: AnsiString): boolean; Virtual;
  Function MovePoint(Index: Integer; XX, YY: Double; Drawing: boolean = False)
    : boolean; virtual;
  { }
  Function GetSegment(X, Y: Double): Integer; virtual;
  Function GetLength: Double; virtual;
  Destructor Destroy; Override;
  Procedure See;
  Procedure SetMinMax; virtual;
  Function DeleteMinOtr(Num: Extended): boolean;
  Function GetDist(X, Y: Double; var Dot: TDot): Double;
  Procedure AddLines(Dist: Double; AddPoint: boolean);
  Procedure AddLines2(Dist: Double);
  Procedure AddTwig(Twig2: TTwig);
  Function InterWith(Tw: TTwig; var X, Y: Double): boolean;
  Function InterWith2(Tw: TTwig; var X, Y: Double; Prec: Integer = 0): Byte;
  Function is3DTwig: boolean;
  { }
  Function GetPrim(R: TSect; Col: PCollection): boolean; override;
  { }
  Procedure Calculate; virtual;
  Function ReadTwigCoord: PCollection; virtual;
  Procedure WriteTwigCoord(C: PCollection); virtual;
  { }
  Procedure ZSetTwig(Z: Double); Virtual;
  Function ZValue: Double; Virtual;
  { }
  Property Coord: PCollection read ReadTwigCoord write WriteTwigCoord;
  Property Item[Index: Integer]: TDot read ReadDot write WriteDot; default;
  Procedure SetStColor(V: Integer);
  Property StColor: Integer read GetStColor write SetStColor;
  Function TwigColor: FixedInt;
  { }
  { Для тахео }
  Function GBS: Double;
  { Для перемещения знаков по линии }
  Function GetLineDistance(X1, Y1, XR, YR: Double): Double; virtual;
  Function GetDistOnLine(X, Y: Double): Double;
  Function OrthoTwig(var XR, YR: Double; addAngle: Double;
    Only90: boolean): Double;
  Function TwigFixAngle(var XR, YR: Double; fixAngle: Double): Double;
  { Работа с блоками }                                   { вся ветвь }
  Function GetDot(Index: Integer): TDot;
  Property Dots[Index: Integer]: TDot read GetDot;
  { }
  Procedure RotatePoints(X, Y: Double);
  Function First: TDot; virtual;
  Function Last: TDot; virtual;
  { }
  Function SUMTwig: Double;
  { }
  Procedure Move(Dx, Dy: Double); virtual;
  { }
  Function SetProperty(propName: AnsiString; propValue: AnsiString;
    Obj: TTD = nil): boolean; override;
  Function GetPRoperty(propName: AnsiString): AnsiString; override;
  Function UseProperty(propName: AnsiString): boolean; override;
  { }
  Function InPolygon(Polygon: PCollection): boolean; virtual;
  { }
  Function DeletePointWhat(W: Integer): Integer;
  Function DeleteLines(Dist: Double; Pack: boolean = False): Integer;
  //
  Property OnDestroy: TNotifyEvent read fOnDestroy write fOnDestroy;
  //
  Function GetSegmentDirect(Index: Integer;
    MouseX, MouseY, pointX, pointY: Double): Double;
  //
  Procedure CreateLotsView(Lot: Pointer);
  Procedure FreeLotsView;
  // UNIX
  Procedure Draw;virtual;
 end;

 TClassTwig = Class(TTwig)
  Code: Double;
  Constructor Create(W1: Integer; Cl: Pointer = nil); override;
  Constructor CreateAsTwig(Twig: TTwig; AddCoord: boolean); override;
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
  Function GetData: Pointer; override;
 end;

 T3DTwig = Class(TTwig)
  Z: Single;
  Constructor Create(W1: Integer; Z1: Pointer = nil); Override;
  Constructor CreateAsTwig(Twig: TTwig; AddCoord: boolean); override;
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
  Function GetData: Pointer; override;
  Procedure Calculate; override;
  { }
  Function ZValue: Double; override;
 end;

 TArcRecord = class(TTwgObject)
  XXC, YYC, XX1, YY1, XX2, YY2, XX3, YY3: Double;
  Constructor Create(XC, YC, X1, Y1, X2, Y2, X3, Y3: Double);
  // Constructor CreateAngles(A1,A2:Double);
 end;

 TTwigARC = class(TTwig) // ARC ветка
 public
  C, // координаты центра
  A, B, D, DOld: TDot; // координаты точек
  ArcCoord: PCollection;
  Procedure FillTwigCoord;
  Constructor Create(W1: Integer; Data: Pointer = nil); Override;
  Constructor CreateAsTwig(Twig: TTwig; AddCoord: boolean); override;
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
  Procedure ReCreate(XXC, YYC, XX1, YY1, XX2, YY2, XX3, YY3: Double);
  Procedure Calculate; override;
  Procedure MiddlePointSet;
  Procedure MiddlePointDraw;
  Procedure ArcCreate(Question: boolean);
  Function GetNearestPoint(XDrag, YDrag: Double; var Index: Integer)
    : TDot; override;
  { }
  { Доступ к координатам }
  Function ReadTwigCoord: PCollection; override;
  Procedure WriteTwigCoord(C: PCollection); override;
  { Разворот }
  Procedure Rotation; override;
  Procedure AChangeB;
  Function Radius: Double;
  { Расстояние до ветки }
  Function GetTwigDist(XDrag, YDrag: Double; Var X1, Y1: Double)
    : Double; override;
  { Виртуальные вершины для подсчета площадей }
  Procedure FreeVirtualVertex;
  Procedure SetMinMax; override;
  { Для перемещения знаков по линии }
  Function GetLineDistance(X1, Y1, XR, YR: Double): Double; override;
  { }
  Destructor Destroy; override;
  Function GetSegment(X, Y: Double): Integer; Override;
  //
  Function InPolygon(Polygon: PCollection): boolean; override;
  //
  Function GetLength: Double; override;
  Function LeftCircle: boolean;
  //
  Procedure Move(Dx, Dy: Double); override;
  Function CreateVirtualVertex: Integer;
 end;

 TTwigTriangle = class(TClassTwig)
  Constructor Create(W1: Integer; Data: Pointer = nil); override;
  Procedure Move(Dx, Dy: Double); override;
  Function GetTwigDist(XDrag, YDrag: Double; Var X1, Y1: Double)
    : Double; override;
 end;

 TTwigCoif = class(TClassTwig)
  Coif: TRealCollect;
  Pikets: PCollection;
  Constructor Create(W1: Integer; Data: Pointer = nil); override;
  Constructor CreateAsTwig(Twig: TTwig; AddCoord: boolean); override;
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
  Destructor Destroy; override;
 end;

 TDataTwig = Class(TClassTwig)
  Size: Integer;
  Data: Pointer;
  Constructor Create(Sz: Integer; Cl: Pointer = nil); override;
  Destructor Destroy; override;
  Constructor Load(Stream: TBufStream); override;
  Procedure Store(Stream: TBufStream); override;
 end;

 TTwigClass = class of TTwig;
 PTwigClass = ^TTwigClass;

Function CreateTwigAsTwig(TwClass: TTwigClass): TTwig;

var
 DoubleZ: Double = ZNull;

 { Const RTwig:TStreamRec=(
   ObjType:3001;
   VmtLink:Ofs(TypeOf(TTwig));
   Load   :@TTwig.Load;
   Store  :@TTwig.Store);
 }
 { ---------------------------------------------------------------------- }
 { Непосредственно указатель }

Type
 TPtr = class(TTwgObject)
  Register: Byte;
  Constructor Create(Reg1: Byte);
  Constructor Load(Stream: TBufStream); Override;
  Procedure Store(Stream: TBufStream); Override;
 end;

 { Const RPtr:TStreamRec=(
   ObjType:3999;
   VmtLink:Ofs(TypeOf(TPtr));
   Load   :@TPtr.Load;
   Store  :@TPtr.Store);

 }
Function Dist(X1, Y1, X2, Y2: Double): Double;

Implementation

uses circle_di, Polygons, Lib, Lines2, Lines3, Writer;

Function ArcCat(X1, Y1, X2, Y2: real; Var Znak: Byte): real;
Var
 Res, R, EndRes, Dy, Dx, Gr, Min, Sec: real;
begin
 Dy := Y2 - Y1;
 Dx := X2 - X1;
 If Dx = 0 then
  Dx := 1;
 Res := Arctan(Dy / Dx);
 IF (Dy >= 0) And (Dx >= 0) then
 begin
  EndRes := Res;
  Znak := 1
 End;
 IF (Dx <= 0) And (Dy >= 0) then
 Begin
  EndRes := 180 - Res;
  Znak := 2
 End;
 IF (Dx <= 0) And (Dy <= 0) then
 Begin
  EndRes := 180 + Res;
  Znak := 3
 End;
 IF (Dx >= 0) And (Dy <= 0) then
 Begin
  EndRes := 360 - Res;
  Znak := 4
 End;
 ArcCat := Res;
end;

function Dist(X1, Y1, X2, Y2: Double): Double;
begin
 Dist := sqrt(sqr(X2 - X1) + sqr(Y2 - Y1));
end;

function InInterval(A, B, C: Double): boolean;
begin
 InInterval := False;
 if (A >= B) and (A <= C) then
  InInterval := true;
 if (A <= B) and (A >= C) then
  InInterval := true;
end;

{ ---------------------------------------------------------------------- }
{ TTwig }
{ ---------------------------------------------------------------------- }

Function CreateTwigAsTwig;
begin
 Writeln(TwClass.ClassName);
end;

constructor TTwig.Create(W1: Integer; Data: Pointer);
begin
 // old    TaheoIndex:=GMemMakeIndex;
 FillChar(Color, 3, #255);
 TwigCoord := PCollection.Create(1);
 XMax := -1000000;
 YMax := XMax;
 XMin := 1000000;
 YMin := XMin;
 Rang := 0;
 UZnak := -1;
 Closed := 1;
 Inv := 0;
 IsDraw := False;
 NotPere := 0;
 Locked := 0;
 What := W1;
 ClassHandle := nil;
 ArcView := 0;
 ZDx := 0;
 Properties := nil;
 LineWidth := -1;
end;

constructor TTwig.CreateAsTwig(Twig: TTwig; AddCoord: boolean);
var
 I: Integer;
begin
 Selector:=Twig.Selector;
 TaheoIndex := Twig.TaheoIndex;
 Color := Twig.Color;
 TwigCoord := PCollection.Create(1);
 If AddCoord then
  For I := 0 to Twig.Coord.Count - 1 do
   TwigCoord.Insert(TDot.CreateAsDot(Twig.Coord[I]));
 XMax := Twig.XMax;
 YMax := Twig.YMax;
 XMin := Twig.XMin;
 YMin := Twig.YMin;
 Rang := Twig.Rang;
 UZnak := Twig.UZnak;
 Closed := Twig.Closed;
 Inv := 0;
 IsDraw := False;
 NotPere := Twig.NotPere;
 Locked := Twig.Locked;
 What := Twig.What;
 MakeUsel := Twig.MakeUsel;
 ClassHandle := Twig.ClassHandle;
 ArcView := 0;
 ZDx := Twig.ZDx;
 Koef := Twig.Koef;
 If Twig.Properties <> nil then
  Properties := TProperties.CreateAs(Twig.Properties)
 else
  Properties := nil;
 LineWidth := Twig.LineWidth;
end;

constructor TTwig.Load(Stream: TBufStream);
var
 I: SmallInt;
 P: TDot;
 TI: ShortInt;
 N: Integer;
begin
 // GTwigsCount:=GTwigsCount+1;Writeln('Gtw=',GTwigsCount);
 Selector:=Stream.Selector;
 LineWidth := -1;
 ArcView := 0;
 ClassHandle := nil;
 NotPere := 0;
 If Version > 22 then
 begin
  If Version < 28 then
  begin
   Stream.Read(TI, SizeOf(TI));
   TaheoIndex := TI;
  end
  else
   Stream.Read(TaheoIndex, SizeOf(TaheoIndex))
 end
 else
  TaheoIndex := -1;
 // If GTwigsCount = 3250 then
 // Writeln(1);
 Stream.Read(Color, SizeOf(Color));
 Stream.Read(Rang, SizeOf(Rang));
 Stream.Read(UZnak, SizeOf(UZnak));
 Stream.Read(Closed, SizeOf(Closed));
 // Writeln(21);
 TwigCoord := PCollection(Stream.Get);
 // If GTwigsCount=3413 then
 // Writeln(2);
 If Version > 14 then
 begin
  Stream.Read(Locked, 1);
  Stream.Read(MakeUsel, 1);
  If Version > 17 then
   Stream.Read(What, SizeOf(What))
  else
   What := 0;
  If Version > 25 then
  begin
   Stream.Read(ZDx, SizeOf(ZDx));
   // Writeln('Versi=',Version);
   If Version > 37 then
   begin
    Stream.Read(Koef, SizeOf(Koef));
    Properties := TProperties(Stream.Get);
    If Version > 43 then
    begin
     Stream.Read(LineWidth, SizeOf(LineWidth));
{$IFDEF DEMO}
     If (Version = DEMOVERSION) { or (Version = 47) } then
      Stream.Read(I, SizeOf(I));
{$ENDIF}
    end;
   end
   else
    Properties := nil;
  end
  else
   ZDx := 0;
 end
 else
  Locked := 0;
 try
  SetMinMax;
 except
  Coord := PCollection.Create(1);
  Writeln('SetMinMax Except');
  readln;
 end;
 Inv := 0;
 IsDraw := False;
 // Writeln(3);
end;

procedure TTwig.Store(Stream: TBufStream);
begin
 Stream.Write(TaheoIndex, SizeOf(TaheoIndex));
 Stream.Write(Color, SizeOf(Color));
 Stream.Write(Rang, SizeOf(Rang));
 Stream.Write(UZnak, SizeOf(UZnak));
 Stream.Write(Closed, SizeOf(Closed));
 Stream.Put(TwigCoord);
 Stream.Write(Locked, 1);
 Stream.Write(MakeUsel, 1);
 Stream.Write(What, SizeOf(What));
 Stream.Write(ZDx, SizeOf(ZDx));
 Stream.Write(Koef, SizeOf(Koef));
 Stream.Put(Properties);
 Stream.Write(LineWidth, SizeOf(LineWidth));
{$IFDEF DEMO}
 Stream.Write(TaheoIndex, SizeOf(TaheoIndex));
{$ENDIF}
end;

procedure TTwig.Insert(P: TDot);
begin
 { If Coord.Count<>0 then
   If (TDot(Coord.At(Coord.Count-1)).XDot=P.XDot) and
   (TDot(Coord.At(Coord.Count-1)).YDot=P.YDot) then exit; }
 If P.Xdot > XMax then
  XMax := (P.Xdot);
 If P.Ydot > YMax then
  YMax := (P.Ydot);
 If P.Xdot < XMin then
  XMin := (P.Xdot);
 If P.Ydot < XMin then
  YMin := (P.Ydot);
 Coord.Insert(P);
end;

procedure TTwig.Insert3DPoint(P: TPointDot);
begin
 If P.Xdot > XMax then
  XMax := (P.Xdot);
 If P.Ydot > YMax then
  YMax := (P.Ydot);
 If P.Xdot < XMin then
  XMin := (P.Xdot);
 If P.Ydot < XMin then
  YMin := (P.Ydot);
 Coord.Insert(P);
end;

procedure TTwig.AtPut(Index: SmallInt; P: TDot);
begin
 If Coord.Count <> 0 then
  If (TDot(Coord.At(Coord.Count - 1)).Xdot = P.Xdot) and
    (TDot(Coord.At(Coord.Count - 1)).Ydot = P.Ydot) then
   exit;
 If P.Xdot > XMax then
  XMax := (P.Xdot);
 If P.Ydot > YMax then
  YMax := (P.Ydot);
 If P.Xdot < XMin then
  XMin := (P.Xdot);
 If P.Ydot < XMin then
  YMin := (P.Ydot);
 Coord.AtPut(Index, P);
end;

procedure TTwig.MinMax(X, Y: Double);
begin
 If X > XMax then
  XMax := (X);
 If X < XMin then
  XMin := (X);
 If Y > YMax then
  YMax := (Y);
 If Y < YMin then
  YMin := (Y);
end;

destructor TTwig.Destroy;
begin
 If TwigCoord <> nil then
  TwigCoord.Free;
 If Properties <> nil then
  Properties.Free;
 If Assigned(OnDestroy) then
  OnDestroy(Self);
end;
{ =========================================================================== }

{ =========================================================================== }
{ Painters }
{ =========================================================================== }

function TTwig.InterWith(Tw: TTwig; var X, Y: Double): boolean;
var
 D1, D2, D3, D4: TDot;
 t, o: Double;
 I, J: Integer;
begin
 Result := False;
 For I := 0 to Coord.Count - 2 do
 begin
  D1 := Coord[I];
  D2 := Coord[I + 1];
  For J := 0 to Tw.Coord.Count - 2 do
  begin
   D3 := Tw.Coord[J];
   D4 := Tw.Coord[J + 1];
   intersection_straight_lines(D1.Xdot, D1.Ydot, D2.Xdot, D2.Ydot, D3.Xdot,
     D3.Ydot, D4.Xdot, D4.Ydot, t, o);
   if ((Round(t * Const_Of_PrecCoord) > 0) and
     (Round(t * Const_Of_PrecCoord) < Const_Of_PrecCoord) and
     (Round(o * Const_Of_PrecCoord) > 0) and (Round(o * Const_Of_PrecCoord) <
     Const_Of_PrecCoord)) then
   begin
    Result := true;
    X := D3.Xdot + (D4.Xdot - D3.Xdot) * t;
    Y := D3.Ydot + (D4.Ydot - D3.Ydot) * t;
    exit;
   end;
  end;
 end;
end;

function TTwig.InterWith2(Tw: TTwig; var X, Y: Double; Prec: Integer): Byte;
var
 D1, D2, D3, D4: TDot;
 t, o, D, N: Double;
 I, J: Integer;
 COPC: Integer;
begin
 Result := 0;
 If Prec = 0 then
  Prec := Const_Of_PrecCoord;
 For I := 0 to Coord.Count - 2 do
 begin
  D1 := Coord[I];
  D2 := Coord[I + 1];
  For J := 0 to Tw.Coord.Count - 2 do
  begin
   D3 := Tw.Coord[J];
   D4 := Tw.Coord[J + 1];
   intersection_straight_lines(D1.Xdot, D1.Ydot, D2.Xdot, D2.Ydot, D3.Xdot,
     D3.Ydot, D4.Xdot, D4.Ydot, t, o);
   if ((Round(t * Prec) >= 0) and (Round(t * Prec) < Prec) and
     (Round(o * Prec) > 0) and (Round(o * Prec) < Prec)) then
   begin
    Result := 3;
    X := D3.Xdot + (D4.Xdot - D3.Xdot) * t;
    Y := D3.Ydot + (D4.Ydot - D3.Ydot) * t;
    exit;
   end
   else If (D1 <> D3) and (D4 <> D2) then
   begin
    COPC := Const_Of_PrecCoord;
    If Prec <> 0 then
     Const_Of_PrecCoord := Prec;
    With Selector do
     If (EqualPoints(D1, D3) and EqualPoints(D4, D2)) or
       (EqualPoints(D1, D4) and EqualPoints(D2, D3)) then
     begin
      Result := 3;
      X := D1.Xdot;
      Y := D1.Ydot;
      exit;
     end;
    Const_Of_PrecCoord := COPC;
   end;
  end;
 end;
end;

function TTwig.IsVisible(R: TRect): boolean;
var
 I: Integer;
begin
 { CLO }

 With Selector do
 begin
  If Rang <> 0 then
   if not GGraphSet.ShowClosed then
    if (Closed <> 1) then
    begin
     IsVisible := False;
     IsVis := False;
     exit;
    end;
  IsVisible := true;
  IsVis := true;
  // GCanvas.Pen.Color:=Rgb(255,0,0);
  // If Coord.Count>=2 then DrawLine(Item[0].XDot,Item[0].YDot,Item[1].XDot,Item[1].YDot);
  With GRect do
  begin
   If XMax < Left then
   begin
    IsVisible := False;
    IsVis := False;
    exit;
   end;
   If XMin > Right then
   begin
    IsVisible := False;
    IsVis := False;
    exit;
   end;
   If YMin > Top then
   begin
    IsVisible := False;
    IsVis := False;
    exit;
   end;
   If YMax < Bottom then
   begin
    IsVisible := False;
    IsVis := False;
    exit;
   end;
  end;
 end;
end;

function TTwig.IsMinimal: boolean;
begin
 With Selector do
  if (Abs(XRasst(XMax - XMin)) < GGraphSet.FClipTwig) and
    (Abs(YRasst(YMax - YMin)) < GGraphSet.FClipTwig) then
  begin
   Result := true;
  end
  else
   Result := False;
end;


function TTwig.GetTwigDist(XDrag, YDrag: Double; var X1, Y1: Double): Double;

var
 PD1, PD2: TDot;
 Dot: TDot;
 MinStor, S1, s2: Double;
 TmpX, TmpY: Double;
 I: SmallInt;
 Dx, Dy, k1, k2, b2, b1: Double;
 X, Y: Double;
begin
 Dot := TDot.Create(0, 0, 0);
 Dot.Xdot := XDrag;
 Dot.Ydot := YDrag;
 MinStor := 100000000;
 S1 := MinStor;
 for I := 0 to Coord.Count - 2 do
 begin
  PD1 := Coord.At(I);
  PD2 := Coord.At(I + 1);

  Dx := PD2.Xdot - PD1.Xdot;
  Dy := PD2.Ydot - PD1.Ydot;

  // Writeln(dx:8:10,' ',dy:8:10);

  if Abs(Dx) < 0.00001 then
  begin
   { вертикильная прямая . начало }
   X := PD1.Xdot;
   Y := Dot.Ydot;
   { вертикильная прямая .конец }
  end
  else
  begin
   k1 := Dy / Dx;
   b1 := PD1.Ydot - k1 * PD1.Xdot;
   If Abs(Dy) < 0.00001 then
   begin
    { гор. прямая . начало }
    X := Dot.Xdot;
    Y := PD1.Ydot;
    { гор. прямая . конец }
   end
   else
   begin
    k2 := -1 / k1;
    b2 := Dot.Ydot - k2 * Dot.Xdot;
    X := (b1 - b2) / (k2 - k1);
    Y := (k2 * b1 - k1 * b2) / (k2 - k1);
   end;
  end;

  { PMoveTo(DC,Dot.Xdot,Dot.ydot); }

  If InInterval(X, PD1.Xdot, PD2.Xdot) and InInterval(Y, PD1.Ydot, PD2.Ydot)
  then
  begin
   S1 := Dist(X, Y, Dot.Xdot, Dot.Ydot);
   { PLineTo(DC,X,y); }
   TmpX := X;
   TmpY := Y;
  end
  else
  begin
   S1 := Dist(Dot.Xdot, Dot.Ydot, PD1.Xdot, PD1.Ydot);
   s2 := Dist(Dot.Xdot, Dot.Ydot, PD2.Xdot, PD2.Ydot);
   if s2 < S1 then
   begin
    S1 := s2;
    TmpX := PD2.Xdot;
    TmpY := PD2.Ydot;
    { PLineTo(DC,PD2.xDot,PD2.yDot); }
   end
   else
   begin
    TmpX := PD1.Xdot;
    TmpY := PD1.Ydot;
    { PLineTo(DC,PD1.xDot,PD1.yDot); }
   end
  end;
  if S1 < MinStor then
  begin
   X1 := TmpX;
   Y1 := TmpY;
   MinStor := S1;
  end;
 end;
 GetTwigDist := MinStor;
 Dot.Free;
end;

{ ---------------------------------------------------------------------- }

procedure TTwig.Rotation;
var
 counter, I: SmallInt;
 PD1, PD2: TDot;
 pc: PCollection;
 C: AnsiChar;
begin
 counter := Coord.Count;
 pc := PCollection.Create(1);
 if not is3DTwig then
  for I := Coord.Count - 1 downTo 0 do
  begin
   PD1 := Coord.At(I);
   pc.Insert(TDot.CreateZ(PD1.Xdot, PD1.Ydot, PD1.Z, PD1.What));
  end
 else
  for I := Coord.Count - 1 downTo 0 do
  begin
   PD1 := Coord.At(I);
   pc.Insert(TPointDot.CreateAsDot(PD1));
  end;
 Coord.Free;
 Coord := pc;
end;

procedure TTwig.See;
begin
end;

{ ---------------------------------------------------------------------- }
{ TPtr }
{ ---------------------------------------------------------------------- }
Constructor TPtr.Create;
begin
 Register := Reg1;
end;

Constructor TPtr.Load;
begin
 Stream.Read(Register, SizeOf(Register));
end;

Procedure TPtr.Store;
begin
 Stream.Write(Register, SizeOf(Register));
end;

{ TTwig }
function TTwig.GetNearestPoint(XDrag, YDrag: Double; var Index: Integer): TDot;
var
 S, Mins: Double;
 N, I: SmallInt;
 PD: TDot;
begin
 Index := -1;
 Result := nil;
 If Coord.Count = 0 then
  exit;
 Index := 0;
 PD := Coord.At(0);
 Mins := Dist(XDrag, YDrag, PD.Xdot, PD.Ydot);
 for I := 1 to Coord.Count - 1 do
 begin
  PD := Coord.At(I);
  S := Dist(XDrag, YDrag, PD.Xdot, PD.Ydot);
  if S < Mins then
  begin
   Mins := S;
   Index := I;
  end;
 end;
 GetNearestPoint := Coord[Index];
end;

function TTwig.GetSegment(X, Y: Double): Integer;
var
 I: Integer;
 D1, D2: TDot;
 X1, Y1: Double;
 S, s2: Double;
 Tw: TTwig;
begin
 S := GetTwigDist(X, Y, X1, Y1);
 I := 1;
 Tw := TTwig.Create(0);
 s2 := 10000;
 Result := -1;
 For I := 0 to Coord.Count - 2 do
 begin
  D1 := Coord[I];
  D2 := Coord[I + 1];
  Tw.Coord.Insert(D1);
  Tw.Coord.Insert(D2);
  s2 := Tw.GetTwigDist(X, Y, X1, Y1);
  Tw.Coord.DeleteAll;
  If Abs(S - s2) <= 0.01 then
  begin
   Result := I + 1;
   break;
  end;
 end;
 Tw.Free;
 // If S<
 { while not((inter(x1,TDot(Coord.At(i)).XDot,TDot(Coord.At(i-1)).XDot))
   and(inter(y1,TDot(Coord.At(i)).YDot,TDot(Coord.At(i-1)).YDot))) do
   begin
   inc(i);
   end;
 }
end;

procedure TTwig.SetMinMax;
var
 I: SmallInt;
 dt: TDot;
begin
 If Coord.FList = nil then
 begin
  Closed := 254;
  exit;
 end;
 If Coord.Count = 0 then
 begin
  Closed := 254;
  exit;
 end;
 XMax := -1000000000;
 YMax := -1000000000;
 XMin := 1000000000;
 YMin := 1000000000;
 for I := 0 to Coord.Count - 1 do
 begin
  dt := Coord.At(I);
  try
   MinMax(dt.Xdot, dt.Ydot);
  except
   Closed := 254;
   Writeln(100000000);
  end;
  If (dt.What <> 100) and (dt.What <> 20) then
   if (I = 0) or (I = Coord.Count - 1) then
    dt.What := 10
   else
    dt.What := 0;
 end;
end;

{ ----------------------------- }
function TTwig.IsVisRect: boolean;
begin
 { if (IsVis and 1)<>0 then IsVisRect:=true else IsVisRect:=false; }
end;

{ ----------------------------- }
function TTwig.IsVisGlobal: boolean;
begin
 { if (IsVis and 2)<>0 then IsVisGlobal:=true else IsVisGlobal:=false; }
end;

{ ----------------------------- }
function TTwig.DeleteMinOtr(Num: Extended): boolean;
var
 D1, D2: TDot;
 I, CC, J: Integer;
 Flag: boolean;
 Function FoundEdge: Integer;
 var
  I: Integer;
 begin
  Result := -1;
  For I := 0 to Coord.Count - 3 do
  begin
   D1 := Coord.At(I);
   D2 := Coord.At(I + 1);
   if sqrt(sqr(D1.Xdot - D2.Xdot) + sqr(D1.Ydot - D2.Ydot)) <= Num then
   begin
    Result := I + 1;
    break;
   end;
  end;
 end;
 Function FoundEdgeRev: Integer;
 var
  I: Integer;
 begin
  Result := -1;
  For I := Coord.Count - 1 downTo 2 do
  begin
   D1 := Coord.At(I);
   D2 := Coord.At(I - 1);
   If sqrt(sqr(D1.Xdot - D2.Xdot) + sqr(D1.Ydot - D2.Ydot)) <= Num then
   begin
    Result := I - 1;
    break;
   end;
  end;
 end;

begin
 Result := False;
 Flag := False;
 CC := Coord.Count;
 Num := Num / 100;
 // If isVisible(GPRect) then
 begin
  // If IsMinimal then Exit;
  If Coord.Count <= 2 then
  begin
   If Coord.Count = 2 then
   begin
    D1 := Coord.At(0);
    D2 := Coord.At(1);
    If sqrt(sqr(D1.Xdot - D2.Xdot) + sqr(D1.Ydot - D2.Ydot)) <= Num then
    begin
     Closed := 254;
    end;
   end
   else
    Closed := 254;
   exit;
  end;
  I := FoundEdge;
  J := 0;
  Result := I <> -1;
  While I <> -1 do
  begin
   Coord.AtFree(I);
   if odd(J) then
    I := FoundEdge
   else
    I := FoundEdgeRev;
   Inc(J);
  end;
  {
    For I:=0 to Coord.Count-2 do
    begin
    D1:=Coord.At(I);
    D2:=Coord.At(I+1);
    If Sqrt(Sqr(D1.XDot-D2.XDot)+Sqr(D1.YDot-D2.YDot))<=Num then
    D2.What:=201;
    end;
    For I:=Coord.Count-1 downTo 0 do If TDot(Coord[I]).What=201 then begin Coord.AtFree(I);Flag:=True;end;
  }
  If Coord.Count = 2 then
  begin
   D1 := Coord.At(0);
   D2 := Coord.At(1);
   If sqrt(sqr(D1.Xdot - D2.Xdot) + sqr(D1.Ydot - D2.Ydot)) <= Num then
   begin
    Closed := 254;
   end;
  end
  else If Coord.Count < 2 then
   Closed := 254;
 end;
 if not Result then
  Result := Closed = 254;
 // Spline;
end;

function TTwig.GetDist(X, Y: Double; var Dot: TDot): Double;
var
 I: SmallInt;
 D, D2: TDot;
 S: Double;
 SMin: Double;
begin
 SMin := 1000000;
 For I := 0 to Coord.Count - 1 do
 begin
  D := Coord.At(I);
  With D do
   S := sqrt(sqr(Xdot - X) + sqr(Ydot - Y));
  If S < SMin then
  begin
   SMin := S;
   Dot := D;
  end;
 end;
 GetDist := SMin;
end;

function TTwig.GetLength: Double;
var
 I, J: Integer;
 D, D1: TDot;
begin
 Result := 0;
 For I := 0 to Coord.Count - 2 do
 begin
  D := Coord[I];
  D1 := Coord[I + 1];
  Result := Result + sqrt(sqr(D.Xdot - D1.Xdot) + sqr(D.Ydot - D1.Ydot));
 end;
end;

procedure TTwig.AddLines(Dist: Double; AddPoint: boolean);
var
 DtB, DtE: TDot;
 PDtb, PDtE: TDot;
 Dx, Dy: Double;
 B: Byte;
 Nx, Ny: Double;
 Dx1: Double;
 Angle: Double;
begin
 If Coord.Count >= 2 then
 begin
  DtB := Coord.At(0);
  DtE := Coord.At(Coord.Count - 1);
  PDtb := Coord.At(1);
  PDtE := Coord.At(Coord.Count - 2);
  Angle := Atan2(PDtb.Ydot - DtB.Ydot, PDtb.Xdot - DtB.Xdot) + Pi / 2;
  Dx := Dist * Cos(Angle);
  Dy := Dist * Sin(Angle);
  { }
  If AddPoint then
  begin
   Nx := DtB.Xdot + Dx;
   Ny := DtB.Ydot - Dy;
   DtB.What := 100;
   // Items[0].What := -10;
   Coord.AtInsert(0, TDot.Create(Nx, Ny, 10));
  end
  else
  begin
   DtB.Xdot := DtB.Xdot + Dx;
   DtB.Ydot := DtB.Ydot - Dy;
  end;
  { }
  Angle := Atan2(PDtE.Ydot - DtE.Ydot, PDtE.Xdot - DtE.Xdot) + Pi / 2;
  Dx := Dist * Cos(Angle);
  Dy := Dist * Sin(Angle);
  If AddPoint then
  begin
   Nx := DtE.Xdot + Dx;
   Ny := DtE.Ydot - Dy;
   // Items[Coord.Count-1].What := -10;
   Coord.Insert(TDot.Create(Nx, Ny, 10));
   DtE.What := 100;
  end
  else
  begin
   DtE.Xdot := DtE.Xdot + Dx;
   DtE.Ydot := DtE.Ydot - Dy;
  end;
 end;
end;

procedure TTwig.AddLines2(Dist: Double);
var
 DtB, DtE: TDot;
 PDtb, PDtE: TDot;
 Dx, Dy: Double;
 B: Byte;
 Nx, Ny: Double;
 Dx1: Double;
 Angle: Double;
begin
 If Coord.Count >= 2 then
 begin
  DtB := Coord.At(0);
  DtE := Coord.At(Coord.Count - 1);
  PDtb := Coord.At(1);
  PDtE := Coord.At(Coord.Count - 2);
  Angle := Atan2(PDtb.Ydot - DtB.Ydot, PDtb.Xdot - DtB.Xdot) + Pi / 2;
  Dx := Dist * Cos(Angle);
  Dy := Dist * Sin(Angle);
  { }
  DtB.Xdot := DtB.Xdot + Dx;
  DtB.Ydot := DtB.Ydot - Dy;
  { }
  Angle := Atan2(PDtE.Ydot - DtE.Ydot, PDtE.Xdot - DtE.Xdot) + Pi / 2;
  Dx := Dist * Cos(Angle);
  Dy := Dist * Sin(Angle);
  DtE.Xdot := DtE.Xdot - Dx;
  DtE.Ydot := DtE.Ydot + Dy;
 end;
end;

function TTwig.DeleteLines(Dist: Double; Pack: boolean = False): Integer;
var
 Deleted: boolean;
 I: Integer;
begin
 If Coord.Count <= 1 then
  exit;
 Deleted := False;
 If Round(Distance(Item[0].Xdot, Item[0].Ydot, Item[1].Xdot, Item[1].Ydot) *
   1000) = Round(Dist * 1000) then
 begin
  Coord.AtFree(0);
  Deleted := true;
 end;
 If Coord.Count <= 1 then
 begin
  Coord.AtFree(0);
  Closed := 254;
  exit;
 end;
 If Deleted then
  Item[0].What := 10;
 Deleted := False;
 If Round(Distance(Item[Coord.Count - 1].Xdot, Item[Coord.Count - 1].Ydot,
   Item[Coord.Count - 2].Xdot, Item[Coord.Count - 2].Ydot) * 1000)
   = Round(Dist * 1000) then
 begin
  Coord.AtFree(Coord.Count - 1);
  Deleted := true;
 end;
 If Coord.Count <= 1 then
 begin
  Coord.AtFree(0);
  Closed := 254;
  exit;
 end;
 If Deleted then
  Item[Coord.Count - 1].What := 10;
 If Pack then
  For I := Coord.Count - 1 downTo 0 do
  begin
   If Item[I].What = 100 then
    Coord.AtFree(I);
  end;
 For I := Coord.Count - 1 downTo 0 do
 begin
  If (I = 0) or (I = Coord.Count - 1) then
   Item[I].What := 10
  else
   Item[I].What := 0;
 end;
end;

procedure TTwig.AddTwig(Twig2: TTwig);
var
 DB, DE, DtB, DtE, D: TDot;
 I: SmallInt;
begin
 If Coord.Count = 0 then
 begin
  For I := 0 to Twig2.Coord.Count - 1 do
  begin
   D := Twig2.Coord.At(I);
   If (I = 0) or (I = Twig2.Coord.Count - 1) then
    Coord.Insert(TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 10))
   else
    Coord.Insert(TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 0));
  end;
  exit;
 end;
 DB := Coord.At(0);
 DtE := Twig2.Coord.At(Twig2.Coord.Count - 1);
 DE := Coord.At(Coord.Count - 1);
 DtB := Twig2.Coord.At(0);
 { }
 If (DB.Xdot = DtB.Xdot) and (DB.Ydot = DtB.Ydot) then
 begin
  For I := Twig2.Coord.Count - 1 downTo 1 do
  begin
   D := Twig2.Coord.At(I);
   Coord.AtInsert(0, TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 0));
  end;
 end
 else If (DE.Xdot = DtB.Xdot) and (DE.Ydot = DtB.Ydot) then
 begin
  For I := 1 to Twig2.Coord.Count - 1 do
  begin
   D := Twig2.Coord.At(I);
   Coord.Insert(TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 0));
  end;
 end
 else If (DE.Xdot = DtE.Xdot) and (DE.Ydot = DtE.Ydot) then
 begin
  For I := Twig2.Coord.Count - 2 downTo 0 do
  begin
   D := Twig2.Coord.At(I);
   Coord.Insert(TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 0));
  end;
 end
 else If (DB.Xdot = DtE.Xdot) and (DB.Ydot = DtE.Ydot) then
 begin
  For I := 0 to Twig2.Coord.Count - 2 do
  begin
   D := Twig2.Coord.At(I);
   Coord.AtInsert(0, TDot.CreateZ(D.Xdot, D.Ydot, D.Z, 0));
  end;
 end;
 TDot(Coord[0]).What := 10;
 TDot(Coord[Coord.Count - 1]).What := 10;
end;
{ ----------------------------- }

function TTwig.GetPrim(R: TSect; Col: PCollection): boolean;
var
 I: Integer;
 D: TDot;
 Function GetP(Index: Integer): boolean;
 begin
  With TDot(Coord[Index]) do
   If (Xdot >= R.Left) and (Xdot <= R.Right) and (Ydot <= R.Top) and
     (Ydot >= R.Bottom) then
    Result := true
 end;

begin
 Result := true;
 For I := 0 to Coord.Count - 1 do
  Result := Result and GetP(I);
 if Result then
  For I := 0 to Coord.Count - 1 do
   Col.Insert(Coord[I]);
end;

// Виртуальные функции для ArcTwig
procedure TTwig.Calculate;
begin
 SetMinMax;
end;

function TTwig.ReadTwigCoord: PCollection;
begin
 Result := TwigCoord;
end;

procedure TTwig.WriteTwigCoord(C: PCollection);
begin
 TwigCoord := C;
end;

procedure TTwig.SetSelector(S: TSelector);
begin
 fSelector:=S;
end;

procedure TTwig.SetStColor(V: Integer);
begin
 Color.argb[1] := GetR(V);
 Color.argb[2] := GetG(V);
 Color.argb[3] := GetB(V);
end;

function TTwig.GetStColor: Integer;
begin
 Result := RGBToCol(Color.argb[1], Color.argb[2], Color.argb[3])
end;

function TTwig.is3DTwig: boolean;
var
 I: Integer;
begin
 Result := true;
 For I := 0 to Coord.Count - 1 do
  if TDot(Coord[I]).Z = ZNull then
  begin
   Result := False;
   exit;
  end;
end;

function TTwig.TwigColor: FixedInt;
begin
 Result := RGBToCol(Color.argb[1], Color.argb[2], Color.argb[3]);
end;

procedure TTwig.ZSetTwig(Z: Double);
var
 I: Integer;
begin
 For I := 0 to TwigCoord.Count - 1 do
  TDot(TwigCoord[I]).Z := Z;
end;

{ -------------------------------------------------------------- }
{ GBS }
{ -------------------------------------------------------------- }
function TTwig.GBS: Double;
begin
 Result := XMax + XMin + YMax + YMin;
end;

function TTwig.GetLineDistance(X1, Y1, XR, YR: Double): Double;
var
 Seg, Seg2: Integer;
 D1, D2: TDot;
begin
 Result := 0;
 Seg := GetSegment(X1, Y1);
 Seg2 := GetSegment(XR, YR);
 If (Seg = -1) or (Seg2 = -1) then
  exit;
 if Seg = Seg2 then
 begin
  D1 := Coord[Seg - 1];
  D2 := Coord[Seg];
  If Distance(X1, Y1, D1.Xdot, D1.Ydot) < Distance(XR, YR, D1.Xdot, D1.Ydot)
  then
   Result := Distance(X1, Y1, XR, YR)
  else
   Result := -Distance(X1, Y1, XR, YR);
 end
 else If Seg2 < Seg then
  Result := -Distance(X1, Y1, XR, YR)
 else
  Result := Distance(X1, Y1, XR, YR);
end;

function TTwig.GetDistOnLine(X, Y: Double): Double;
var
 I, Seg: Integer;
 D1, D2: TDot;
 Dist: Double;
begin
 Result := -1;
 Seg := GetSegment(X, Y);
 If (Seg = -1) then
  exit;
 Dist := 0;
 For I := 0 to Seg - 2 do
 begin
  D1 := Coord[I];
  D2 := Coord[I + 1];
  Dist := Dist + Distance(D1.Xdot, D1.Ydot, D2.Xdot, D2.Ydot);
 end;
 D1 := Coord[Seg - 1];
 Dist := Dist + Distance(D1.Xdot, D1.Ydot, X, Y);
 Result := Dist;
end;

function TTwig.OrthoTwig(var XR, YR: Double; addAngle: Double; Only90: boolean
 ): Double;
var
 D1, D2: TDot;
 Dist, Angle1, Angle2, Angle3, Min, Ind: Double;
 Tw: TTwig;
 C: Integer;
 X, Y: Double;
begin
 Result := 0;
 C := Chetvert(addAngle);
 If Coord.Count < 1 then
  exit;
 If Coord.Count > 1 then
  D1 := Coord[Coord.Count - 2]
 else
  D1 := Coord[Coord.Count - 1];
 D2 := Coord[Coord.Count - 1];
 if Coord.Count > 1 then
  Angle1 := Direct_Angle(D2.Ydot, D2.Xdot, D1.Ydot, D1.Xdot) * 180 / Pi
 else
 begin
  X := D2.Xdot + 10 * Cos(addAngle);
  Y := D2.Ydot + 10 * Sin(addAngle);
  D1 := TDot.Create(X, Y, 0);
  // PSetPixel(X,Y);
  Angle1 := Direct_Angle(D2.Ydot, D2.Xdot, D1.Ydot, D1.Xdot) * 180 / Pi
 end;
 Angle2 := Direct_Angle(D2.Ydot, D2.Xdot, YR, XR) * 180 / Pi;
 Angle3 := Angle1 - Angle2;
 If Angle3 < 0 then
  Angle3 := 360 + Angle3;
 Min := Abs(90 - Angle3);
 Ind := 90;
 If not Only90 then
  If Abs(180 - Angle3) < Min then
  begin
   Min := Abs(180 - Angle3);
   Ind := 180;
  end;
 If Abs(270 - Angle3) < Min then
 begin
  Min := Abs(270 - Angle3);
  Ind := 270;
 end;
 If not Only90 then
  If Abs(360 - Angle3) < Min then
  begin
   Min := Abs(360 - Angle3);
   Ind := 360;
  end;
 If not Only90 then
  If Abs(0 - Angle3) < Min then
  begin
   Min := Abs(0 - Angle3);
   Ind := 0;
  end;
 If Coord.Count > 1 then
  Angle1 := Direct_Angle(D2.Xdot, D2.Ydot, D1.Xdot, D1.Ydot) * 180 / Pi
 else
 begin
  Angle1 := Direct_Angle(D2.Xdot, D2.Ydot, D1.Xdot, D1.Ydot) * 180 / Pi;
  D1.Free;
 end;
 Angle3 := Angle1 + Ind;
 { If Coord.Count>1 then begin
   Tw:=TTwig.Create(0);
   Tw.Insert(TDot.CreateAsDot(Coord[0]));Tw.Insert(TDot.CreateAsDot(Coord[1]));
   Dist:=Tw.GetTwigDist(XR,YR,XR,YR);
   end else } Dist := Distance(D2.Xdot, D2.Ydot, XR, YR);
 XR := D2.Xdot + Dist * Cos(Angle3 * Pi / 180);
 YR := D2.Ydot + Dist * Sin(Angle3 * Pi / 180);
 Result := Dist;
end;

{ ---------------------------------------------------------------------- }
{ TClassTwig }
{ ---------------------------------------------------------------------- }
Constructor TClassTwig.Create;
begin
 inherited Create(W1);
 ClassHandle := Cl;
 Code := ClassHandle.ID;
 Closed := ClassHandle.Check;
 MakeUsel := ClassHandle.MakeUsel;
 Rang := Trunc(ClassHandle.Rang);
 UZnak := ClassHandle.ZnkInd.LInd;
end;

function TClassTwig.GetData: Pointer;
begin
 Result := ClassHandle;
end;

Constructor TClassTwig.CreateAsTwig;
begin
 inherited CreateAsTwig(Twig, AddCoord);
 if Twig is TClassTwig then
 begin
  ClassHandle := TClassTwig(Twig).ClassHandle;
  Code := TClassTwig(Twig).Code;
  TaheoIndex := Twig.TaheoIndex;
 end;
end;

Constructor TClassTwig.Load;
begin
 inherited Load(Stream);
 Stream.Read(Code, SizeOf(Code));
 Closed := 1;
 Inv := 0;
end;

Procedure TClassTwig.Store;
begin
 inherited Store(Stream);
 Stream.Write(Code, SizeOf(Code));
end;

{ ---------------------------------------------------------------------- }
{ T3DTwig }
{ ---------------------------------------------------------------------- }
Constructor T3DTwig.Create;
begin
 inherited Create(Twig_3D);
 if Z1 <> nil then
  Z := PDouble(Z1)^
 else
  Z := ZNull;
end;

constructor T3DTwig.CreateAsTwig(Twig: TTwig; AddCoord: boolean);
begin
 Inherited CreateAsTwig(Twig, AddCoord);
 if Twig is T3DTwig then
  Z := T3DTwig(Twig).Z
 else
  Z := ZNull;
end;

Constructor T3DTwig.Load;
begin
 inherited Load(Stream);
 Stream.Read(Z, SizeOf(Z));
end;

Procedure T3DTwig.Store;
begin
 inherited Store(Stream);
 Stream.Write(Z, SizeOf(Z));
end;

{ -------------------------------------------------------------------- }
{ TTwigARC }
{ -------------------------------------------------------------------- }

Constructor TTwigARC.Create;
begin
 inherited Create(W1);
 With TArcRecord(Data) do
 begin
  C := TDot.Create(XXC, YYC, 20);
  A := TDot.Create(XX1, YY1, 10);
  B := TDot.Create(XX2, YY2, 10);
  D := TDot.Create(XX3, YY3, 0);
  DOld := TDot.CreateAsDot(D);
 end;
 ArcCoord := PCollection.Create(1);
 FillTwigCoord;
end;

Destructor TTwigARC.Destroy;
begin
 TwigCoord.DeleteAll;
 TwigCoord.Free;
 ArcCoord.Free;
 C.Free;
 A.Free;
 B.Free;
 D.Free;
 DOld.Free;
end;

Procedure TTwigARC.ReCreate;
begin
 C.Xdot := XXC;
 C.Ydot := YYC;
 A.Xdot := XX1;
 A.Ydot := YY1;
 B.Xdot := XX2;
 B.Ydot := YY2;
 D.Xdot := XX3;
 D.Ydot := YY3;
 DOld.Xdot := XX3;
 DOld.Ydot := YY3;
end;

Procedure TTwigARC.FillTwigCoord;
begin
 TwigCoord.DeleteAll;
 TwigCoord.Insert(A);
 TwigCoord.Insert(D);
 TwigCoord.Insert(C);
 TwigCoord.Insert(B);
end;

Procedure TTwigARC.Calculate;
var
 AV: Integer;
begin
 // try
 solving_arc_circle(A.Xdot, A.Ydot, B.Xdot, B.Ydot, D.Xdot, D.Ydot,
   C.Xdot, C.Ydot);
 ArcCreate(true);
 MiddlePointSet;
 DOld.Xdot := D.Xdot;
 DOld.Ydot := D.Ydot;
 AV := ArcView;
 ArcView := 1;
 SetMinMax;
 ArcView := AV;
 C.What := 30;
 // except Closed:=254;end;
 // Writeln('TwigArcC=',ArcCoord.Count);
end;

procedure TTwigARC.ArcCreate;
var
 AV, Quants: Integer;
 P: PCollection;
 I: Integer;
 D1, D2: TDot1;
begin
 Quants := Quants_For_Arcs;
 ArcCoord.FreeAll;
 If Question then
  If LeftCircle then
   AChangeB;
 P := Arc_Circle3(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot, Quants);
 For I := 0 to P.Count - 2 do
 begin
  D1 := P[I];
  D2 := P[I + 1];
  ArcCoord.Insert(TDot.Create(D1.X, D1.Y, 0));
 end;
 ArcCoord.Insert(TDot.Create(D2.X, D2.Y, 0));
 AV := ArcView;
 ArcView := 1;
 SetMinMax;
 ArcView := AV;
 P.Free;
end;

Function TTwigARC.LeftCircle: boolean;
begin
 Result := (B.Xdot * (D.Ydot - A.Ydot) + B.Ydot * (A.Xdot - D.Xdot) - A.Xdot *
   (D.Ydot - A.Ydot) + A.Ydot * (D.Xdot - A.Xdot)) < 0;
end;

procedure TTwigARC.MiddlePointSet;
var
 X, Y: Double;
begin
 { if LeftCircle
   then Middle_Point_of_Arc_Circle( C.XDot, C.YDot, B.XDot, B.YDot, A.XDot, A.YDot, D.XDot, D.YDot) }
 Middle_Point_of_Arc_Circle(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot,
   D.Xdot, D.Ydot);
end;

procedure TTwigARC.MiddlePointDraw;
var
 X, Y: Double;
begin
 if LeftCircle then
  Middle_Point_of_Arc_Circle(C.Xdot, C.Ydot, B.Xdot, B.Ydot, A.Xdot, A.Ydot,
    D.Xdot, D.Ydot)
 else
  Middle_Point_of_Arc_Circle(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot,
    D.Xdot, D.Ydot);
end;

function TTwigARC.GetNearestPoint;
var
 S: Array [1 .. 4] of Double;
 Min: Double;
begin
 S[1] := Distance(XDrag, YDrag, A.Xdot, A.Ydot);
 S[2] := Distance(XDrag, YDrag, D.Xdot, D.Ydot);
 S[3] := Distance(XDrag, YDrag, B.Xdot, B.Ydot);
 S[4] := Distance(XDrag, YDrag, C.Xdot, C.Ydot);
 Min := S[1];
 Index := 0;
 Result := A;
 If S[2] < Min then
 begin
  Min := S[2];
  Index := 1;
  Result := D;
 end;
 If S[3] < Min then
 begin
  Min := S[3];
  Index := 3;
  Result := B;
 end;
 If S[4] < Min then
 begin
  Min := S[4];
  Index := 4;
  Result := C;
 end;
end;

constructor TTwigARC.Load(Stream: TBufStream);
begin
 ArcCoord := nil;
 inherited Load(Stream);
 ArcCoord := PCollection(Stream.Get);
 // ArcCoord.FreeAll;
 A := TwigCoord[0];
 A.What := 10;
 D := TwigCoord[1];
 D.What := 0;
 B := TwigCoord[3];
 B.What := 10;
 C := TwigCoord[2];
 DOld := TDot.CreateAsDot(D);
 // Calculate;
 SetMinMax;
 ArcView := 0;
end;

procedure TTwigARC.Store(Stream: TBufStream);
begin
 inherited Store(Stream);
 Stream.Put(ArcCoord);
 // Stream.Put(C);
end;

function TTwigARC.ReadTwigCoord: PCollection;
begin
 if ArcView > 0 then
 begin
  Result := ArcCoord;
 end
 else
  Result := TwigCoord;
end;

procedure TTwigARC.WriteTwigCoord(C: PCollection);
begin
 if ArcView > 0 then
 begin
  ArcCoord := C;
 end
 else
  TwigCoord := C;
end;

constructor TTwigARC.CreateAsTwig(Twig: TTwig; AddCoord: boolean);
begin
 inherited CreateAsTwig(Twig, AddCoord);
 if Twig is TTwigARC then
 begin
  C := TDot.CreateAsDot(TTwigARC(Twig).C);
  A := TDot.CreateAsDot(TTwigARC(Twig).A);
  B := TDot.CreateAsDot(TTwigARC(Twig).B);
  D := TDot.CreateAsDot(TTwigARC(Twig).D);
  DOld := TDot.CreateAsDot(D);
  ArcCoord := PCollection.Create(1);
  FillTwigCoord;
 end;
end;

procedure TTwigARC.Rotation;
var
 P: TDot;
begin
 // inherited Rotation;
 // P:=A;A:=B;B:=P;
end;

function TTwig.GetDot(Index: Integer): TDot;
begin
 Result := Coord[Index];
end;

function TTwig.ZValue: Double;
begin
 Result := ZNull;
end;

procedure TTwig.RotatePoints(X, Y: Double);
var
 I: Integer;
 D: TDot;
 P: PCollection;
begin
 GetNearestPoint(X, Y, I);
 If (I <> 0) and (I <> Coord.Count - 1) then
 begin
  P := PCollection.Create(1);
  For I := I to Coord.Count - 2 do
   P.Insert(TDot.CreateAsDot(Coord[I]));
  For I := 0 to I do
   P.Insert(TDot.CreateAsDot(Coord[I]));
  Coord.Free;
  Coord := P;
 end;
end;

function TTwig.ReadDot(Index: Integer): TDot;
begin
 If (Index < 0) or (Index > Coord.Count - 1) then
  Result := nil
 else
  Result := Coord[Index];
end;

procedure TTwig.WriteDot(Index: Integer; const Value: TDot);
begin
 TObject(Coord[Index]).Free;
 Coord[Index] := Value;
end;

function TTwig.First: TDot;
begin
 If Coord.Count = 0 then
  Result := nil
 else
  Result := Coord[0];
end;

function TTwig.Last: TDot;
begin
 If Coord.Count = 0 then
  Result := nil
 else
  Result := Coord[Coord.Count - 1];
end;

function TTwig.TwigFixAngle(var XR, YR: Double; fixAngle: Double): Double;
begin

end;

function TTwig.SUMTwig: Double;
var
 I: Integer;
begin
 Result := 0;
 For I := 0 to Coord.Count - 1 do
 begin
  Result := Result + (TDot(Coord[I]).Xdot + TDot(Coord[I]).Ydot);
 end;
end;

procedure TTwig.Move(Dx, Dy: Double);
var
 I: Integer;
 D: TDot;
begin
 For I := 0 to TwigCoord.Count - 1 do
 begin
  D := TwigCoord.FList[I];
  D.Xdot := D.Xdot + Dx;
  D.Ydot := D.Ydot + Dy;
 end;
 XMax := XMax + Dx;
 YMax := YMax + Dy;
 XMin := XMin + Dx;
 YMin := YMin + Dy;
 // Calculate;
end;

function TTwig.SetProperty(propName: AnsiString; propValue: AnsiString; Obj: TTD
 ): boolean;
begin
 If Properties = nil then
  Properties := TProperties.Create;
 Properties.AddProperty(propName, propValue);
end;

function TTwig.InPolygon(Polygon: PCollection): boolean;
var
 I: Integer;
 D1, D2: TDot;
begin
 Result := true;
 For I := 0 to Coord.Count - 1 do
  If point_and_polygon(Item[I].Xdot, Item[I].Ydot, Polygon) = -1 then
  begin
   Result := False;
   exit;
  end;
 For I := 0 to Coord.Count - 2 do
 begin
  D1 := Coord[I];
  D2 := Coord[I + 1];
  If point_and_polygon((D1.Xdot + D2.Xdot) / 2, (D1.Ydot + D2.Ydot) / 2,
    Polygon) = -1 then
  begin
   Result := False;
   exit;
  end;
 end;
end;

function TTwig.DeletePointWhat(W: Integer): Integer;
var
 I: Integer;
begin
 For I := Coord.Count - 1 downTo 0 do
  If Item[I].What = W then
   Coord.AtFree(I);
end;

function TTwig.GetSegmentDirect(Index: Integer;
  MouseX, MouseY, pointX, pointY: Double): Double;
var
 D1, D2: TDot;
 Angle, Dist: Double;
 X1, Y1, X2, Y2: Double;
begin
 // определяет угол по которому необходимо строить перпендикулярные отрезки относительно выбранного сегмента
 D1 := Coord[Index - 1];
 D2 := Coord[Index];
 // PTextOut(D1.XDot,D1.YDot,'D1');PTextOut(D2.XDot,D2.YDot,'D2');
 Angle := Direct_Angle(D1.Xdot, D1.Ydot, D2.Xdot, D2.Ydot);
 Dist := Distance(D1.Xdot, D1.Ydot, D2.Xdot, D2.Ydot);
 X1 := pointX + Dist * Cos(Angle + Pi / 2);
 Y1 := pointY + Dist * Sin(Angle + Pi / 2);
 X2 := pointX + Dist * Cos(Angle - Pi / 2);
 Y2 := pointY + Dist * Sin(Angle - Pi / 2);
 If Distance(MouseX, MouseY, X1, Y1) < Distance(MouseX, MouseY, X2, Y2) then
  Result := Pi / 2
 else
  Result := -Pi / 2;
 // DrawLine(MouseX,MouseY,pointX,pointY);
 // DrawLine(MouseX,MouseY,X1,Y1);DrawLine(MouseX,MouseY,X2,Y2);
 // PTextOut(X1,Y1,'1');PTextOut(X2,Y2,'2');
 // PTextOut(pointX,pointY,'p');//PTextOut(X2,Y2,'1');
end;

function TTwig.GetSelector: TSelector;
begin
 Result:=fSelector;
end;

function TTwig.GetPRoperty(propName: AnsiString): AnsiString;
var
 V: TPropValue;
begin
 If Properties <> nil then
 begin
  V := Properties.propValue[propName];
  If V = nil then
   Result := byLayer
  else
   Result := V.Value;
 end
 else
  Result := byLayer;
end;

function TTwig.UseProperty(propName: AnsiString): boolean;
begin
 Result := False;
 If Properties <> nil then
  Result := Properties.propValue[propName] <> nil;
end;

function TTwig.MovePoint(Index: Integer; XX, YY: Double;
  Drawing: boolean = False): boolean;
begin
 Result := False;
end;

procedure TTwig.CreateLotsView(Lot: Pointer);
begin
 If Lots = nil then
  Lots := PCollection.Create(1);
 Lots.Insert(Lot);
end;

procedure TTwig.FreeLotsView;
begin
 If Lots <> nil then
 begin
  Lots.DeleteAll;
  Lots.Free;
  Lots := nil;
 end;
end;

procedure TTwig.Draw;
begin
 //
end;

{ TArcRecord }

Constructor TArcRecord.Create(XC, YC, X1, Y1, X2, Y2, X3, Y3: Double);
begin
 XXC := XC;
 YYC := YC;
 XX1 := X1;
 YY1 := Y1;
 XX2 := X2;
 YY2 := Y2;
 XX3 := X3;
 YY3 := Y3;
end;

procedure TTwigARC.AChangeB;
var
 P: TDot;
 AV: Integer;
begin
 P := A;
 A := B;
 B := P;
 FillTwigCoord;
 // Rotation;
 { AV:=ArcView;ArcView:=1;
   SetMinMax;
   ArcView:=AV; }
end;

function TTwig.isMovePointValid(Index: Integer; XX, YY: Double;
 var Error: AnsiString): boolean;
begin
 Result := true;
 Error := '';
end;

function TTwig.GetData: Pointer;
begin
 Result := nil;
end;

function T3DTwig.GetData: Pointer;
begin
 DoubleZ := Z;
 Result := @DoubleZ;
end;

procedure T3DTwig.Calculate;
var
 I: Integer;
begin
 For I := 0 to Coord.Count - 1 do
  TDot(Coord[I]).Z := Z;
end;

function TTwigARC.Radius: Double;
begin
 Result := Distance(C.Xdot, C.Ydot, A.Xdot, A.Ydot);
end;

{ procedure TTwigARC.SetMinMax;
  var AV:Integer;
  begin
  AV:=ArcView;ArcView:=1;
  inherited SetMinMax;
  ArcView:=AV;
  end; }

function TTwigARC.GetTwigDist(XDrag, YDrag: Double; var X1, Y1: Double): Double;
begin
 Result := dist_to_arc(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot, XDrag,
   YDrag, X1, Y1);
 If Result < 0 then
  Result := ZNull;
end;

Procedure TTwigARC.FreeVirtualVertex;
var
 Quants, AV: Integer;
 P: PCollection;
 I: Integer;
 D1, D2: TDot1;
begin
 Quants := Quants_For_Arcs;
 ArcCoord.FreeAll;
 if LeftCircle then
  P := Arc_Circle3(C.Xdot, C.Ydot, B.Xdot, B.Ydot, A.Xdot, A.Ydot, Quants)
 else
  P := Arc_Circle3(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot, Quants);
 For I := 0 to P.Count - 2 do
 begin
  D1 := P[I];
  D2 := P[I + 1];
  ArcCoord.Insert(TDot.Create(D1.X, D1.Y, 0));
 end;
 ArcCoord.Insert(TDot.Create(D2.X, D2.Y, 0));
 AV := ArcView;
 ArcView := 1;
 SetMinMax;
 ArcView := AV;
 P.Free;
end;

procedure TTwigARC.SetMinMax;
var
 AV: Integer;
begin
 if ArcCoord <> nil then
 begin
  AV := ArcView;
  ArcView := 1;
  try
   inherited SetMinMax;
  except
   Closed := 254;
  end;
  ArcView := AV;
 end;
end;

function TTwigARC.GetLineDistance(X1, Y1, XR, YR: Double): Double;
begin
 Result := 0;
end;

{ TTwigTriangle }

constructor TTwigTriangle.Create(W1: Integer; Data: Pointer);
begin
 inherited Create(W1, Data);
 What := Twig_Triangle;
end;

function TTwigTriangle.GetTwigDist(XDrag, YDrag: Double;
  var X1, Y1: Double): Double;
begin
 Result := Abs(ZNull);
end;

procedure TTwigTriangle.Move(Dx, Dy: Double);
begin
 { }
end;

{ TTwigCoif }

constructor TTwigCoif.Create(W1: Integer; Data: Pointer);
begin
 inherited Create(W1, Data);
 What := Twig_Coif;
 Coif := nil;
 Pikets := nil;
end;

constructor TTwigCoif.CreateAsTwig(Twig: TTwig; AddCoord: boolean);
var
 I: Integer;
 P: T3DPoint;
 D: TDouble;
 Tw: TTwigCoif;
begin
 inherited CreateAsTwig(Twig, AddCoord);
 Coif := TRealCollect.Create(1);
 Pikets := PCollection.Create(1);
 Tw := TTwigCoif(Twig);
 For I := 0 to Tw.Coif.Count - 1 do
 begin
  D := Tw.Coif.At(I);
  Coif.Insert(TDouble.Create(D.Num));
 end;
 For I := 0 to Tw.Pikets.Count - 1 do
 begin
  P := Tw.Pikets[I];
  Pikets.Insert(T3DPoint.Create(P.X, P.Y, P.Z));
 end;
end;

destructor TTwigCoif.Destroy;
begin
 inherited Destroy;
 Coif.Free;
 Pikets.Free;
end;

constructor TTwigCoif.Load(Stream: TBufStream);
begin
 inherited Load(Stream);
 Coif := TRealCollect(Stream.Get);
 Pikets := PCollection(Stream.Get);
end;

procedure TTwigCoif.Store(Stream: TBufStream);
begin
 inherited Store(Stream);
 Stream.Put(Coif);
 Stream.Put(Pikets);
end;

function T3DTwig.ZValue: Double;
begin
 Result := Z;
end;

{ TDataTwig }

constructor TDataTwig.Create(Sz: Integer; Cl: Pointer);
begin
 Size := Sz;
 Data := Cl;
 Code := 0;
 Coord := PCollection.Create(1);
end;

destructor TDataTwig.Destroy;
begin
 TwigCoord.Free;
 FreeMem(Data, Size);
end;

constructor TDataTwig.Load(Stream: TBufStream);
begin
 Code := 0;
 Stream.Read(Size, SizeOf(Size));
 GetMem(Data, Size);
 Stream.Read(Data, Size);
 TwigCoord := PCollection.Create(1);
end;

procedure TDataTwig.Store(Stream: TBufStream);
begin
 Stream.Write(Size, SizeOf(Size));
 Stream.Write(Data, Size);
end;

function TTwigARC.GetSegment(X, Y: Double): Integer;
begin
 Result := inherited GetSegment(X, Y);
end;

Function TTwigARC.InPolygon(Polygon: PCollection): boolean;
begin
 Result := (point_and_polygon(A.Xdot, A.Ydot, Polygon) > -1) and
   (point_and_polygon(D.Xdot, D.Ydot, Polygon) > -1) and
   (point_and_polygon(B.Xdot, B.Ydot, Polygon) > -1);
end;

Function TTwigARC.GetLength: Double;
var
 A1, A2, A3: Double;
begin
 A1 := Direct_Angle(C.Xdot, C.Ydot, A.Xdot, A.Ydot);
 A2 := Direct_Angle(C.Xdot, C.Ydot, B.Xdot, B.Ydot);
 A3 := A1 - A2;
 If A3 < 0 then
  A3 := 2 * Pi + A3
 else If A3 > 2 * Pi then
  A3 := A3 - 2 * Pi;
 Result := A3 * Radius;
end;

Procedure TTwigARC.Move(Dx, Dy: Double);
var
 I: Integer;
 D: TDot;
begin
 inherited Move(Dx, Dy);
 For I := 0 to ArcCoord.Count - 1 do
 begin
  D := ArcCoord.FList[I];
  D.Xdot := D.Xdot + Dx;
  D.Ydot := D.Ydot + Dy;
 end;
end;

function TTwigARC.CreateVirtualVertex: Integer;
var
 A1, A2, A3: Double;
 N: Integer;
 Quants, AV: Integer;
 P: PCollection;
 I: Integer;
 D1, D2: TDot1;
 sErr: Double;
begin
 With Selector do
 begin
  sErr := GGraphSet.MaxPlo;
  if sErr = 0 then
   GGraphSet.MaxPlo := 1;
  sErr := GGraphSet.MaxPlo;
 end;
 { D1:=Direct_Angle(C.XDot,C.YDot,A.XDot,A.YDot);
   D2:=Direct_Angle(C.XDot,C.YDot,B.XDot,B.YDot);
   D3:=D1-D2;If D3<0 then D3:=2*Pi-D3;
   Writeln('D3=',D3*180/Pi);
   N:=Round(2*10/(SQR(Radius)*(D3-sin(D3))));
   Writeln('N=',N,' ',SQR(Radius)*(D3-sin(D3))); }
 A1 := Direct_Angle(C.Xdot, C.Ydot, A.Xdot, A.Ydot);
 A2 := Direct_Angle(C.Xdot, C.Ydot, B.Xdot, B.Ydot);
 A3 := A1 - A2;
 If A3 < 0 then
  A3 := 2 * Pi - A3;
 // Writeln('D3=',D3*180/Pi);
 N := Round(sqrt(sqr(Radius) * A3 * A3 * A3 / (12 * sErr)));
 If N = 0 then
  N := Quants_For_Arcs;
 Quants := N;
 ArcCoord.FreeAll;
 if LeftCircle then
  P := Arc_Circle3(C.Xdot, C.Ydot, B.Xdot, B.Ydot, A.Xdot, A.Ydot, Quants)
 else
  P := Arc_Circle3(C.Xdot, C.Ydot, A.Xdot, A.Ydot, B.Xdot, B.Ydot, Quants);
 For I := 0 to P.Count - 2 do
 begin
  D1 := P[I];
  D2 := P[I + 1];
  If I = 0 then
   ArcCoord.Insert(TDot.CreateZ(D1.X, D1.Y, Radius, 100))
  else
   ArcCoord.Insert(TDot.CreateZ(D1.X, D1.Y, Radius, 200));
 end;
 ArcCoord.Insert(TDot.CreateZ(D2.X, D2.Y, Radius, 100));
 AV := ArcView;
 ArcView := 1;
 SetMinMax;
 ArcView := AV;
 P.Free;
 For I := 0 to ArcCoord.Count - 1 do
 begin
  If (I = 0) or (I = ArcCoord.Count - 1) then
   TDot(ArcCoord[I]).What := 100
  else
   TDot(ArcCoord[I]).What := 200;
 end;
end;

begin
end.
