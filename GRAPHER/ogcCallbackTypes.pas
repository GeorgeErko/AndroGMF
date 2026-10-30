unit ogcCallbackTypes;

interface

uses Classes, SysUtils, ogcMathUtils;

const
  gpPoint = 0;
  gpSpacer = 1;

type
// геоточка
 PGeoPoint = ^TGeoPoint;
 { TGeoPoint - лднонаправленный список точек}
 TGeoPoint = record
  X, Y, Z: Double;
  Count: Integer;
  Next: PGeoPoint;
  procedure Create(X_, Y_, Z_: Double);
  procedure AddPoint(X_, Y_, Z_: Double);
  procedure FreeAll;
  procedure Write(S : String);
 end;

 PGeoEdge = ^TGeoEdge;
 { TGeoEdge - однонаправленный список отрезков/дуг}
 TGeoEdge = record
  XA, YA, ZA: Double;
  XB, YB, ZB: Double;
  XD, YD: Double;
  Bulge: Double;
  Count: Integer;
  Next: PGeoEdge;
  procedure Create(XA_, YA_, ZA_, XB_, YB_, ZB_: Double);
  procedure SetBulge(AValue: Double);
  procedure AddCoord(XA_, YA_, ZA_, XB_, YB_, ZB_: Double);
  function GetArcRec: TArcRec;
  procedure FreeAll;
  procedure Write(S : String);
 end;

 const
 // слой типа линии
  bt_Line   = 0;
  bt_Arc    = 1;
  bt_Custom = 2;
 // метод рисования примитивов
  ls_Dinamic1 = 1;
  ls_Dinamic2 = 32;
  ls_DblLine = 2;
  ls_Solid1 = 4;
  ls_Solid2 = 8;
  ls_OrientOn = 16;
  ls_OnlyInDot = 32;
  ls_ToNext = 64;
  ls_ToPred = 128;

 { TPartOfLine }

type

 { TPartOfLineType }

 TPartOfLineType = record
   BitOf: byte;
   DrawState: SmallInt; 	{флаги для линии}
   Param0 : single;		{смещение dL (1)}
   Param1 : single;		{толщина линии (1)}
   Param2 : single;		{отрезок линии (1)/радиус окружности/угол поворота объекта}
   Param3 : single;		{начальное смещение (0>=..<1)*Param0}
               	        {для 2 линий}
   Param4 : single;		{расстояние м-ду линиями/Номер усл. зн.}
   Param5 : single;		{смещение dL (1)}
   Param6 : single;		{толщина линии (2)}
   Param7 : single;		{отрезок линии (2)}
   Param8 : single;		{начальное смещение (2)}
   lVorign: single;      {поперечное смещение}
   rVOrign: single;      {поперечное смещение}
   Color  : integer;
   bkColor: integer;
  //
   Param4S: PAnsiChar;  {строковок имя блока из таблицы блоков}
                         {конечное смещение?}
   procedure Create;
   procedure Free;
   procedure SetParam4S(S: String);
   procedure Write;
 end;

implementation uses System.AnsiStrings, Writer;

{ TPartOfLineType }

procedure TPartOfLineType.Create;
begin
 BitOf := bt_Line;
 DrawState := ls_Solid1;
 Param0 := 0;
 Param1 := 0.1;
 Param2 := 0;
 Param3 := 0;
 Param4 := 0;
 Param5 := 0;
 Param6 := 0;
 Param7 := 0;
 Param8 := 0;
 Color  := 0;
 bkColor := 0;
 Param4S := System.AnsiStrings.StrNew(PAnsiChar(AnsiString('')));
end;

procedure TPartOfLineType.Free;
begin
 If Param4S <> nil then System.AnsiStrings.StrDispose(Param4S);
 Param4S := nil;
end;

procedure TPartOfLineType.SetParam4S(S: String);
begin
 If Param4S <> nil then System.AnsiStrings.StrDispose(Param4S);
 Param4S := System.AnsiStrings.StrNew(PAnsiChar(AnsiString(S)));
end;

procedure TPartOfLineType.Write;
begin
 WriteIn(['bitOf', BitOf]);
 WriteIn(['DrawState', DrawState]);
 WriteIn(['Param0', Param0]);
 WriteIn(['Param1', Param1]);
 WriteIn(['Param2', Param2]);
 WriteIn(['Param3', Param3]);
 WriteIn(['Param4', Param4]);
 WriteIn(['Param5', Param5]);
 WriteIn(['Param6', Param6]);
 WriteIn(['Param7', Param7]);
 WriteIn(['Param8', Param8]);
 WriteIn(['Color', Color]);
 WriteIn(['bkColor', bkColor]);
 WriteIn(['Param4S', String(AnsiString(Param4S))]);
end;

{ TGeoPoint }

procedure TGeoPoint.Create(X_, Y_, Z_: Double);
begin
 X := X_; Y := Y_; Z := Z_;
 Count := 0;
 Next := nil;
end;

procedure TGeoPoint.AddPoint(X_, Y_, Z_: Double);
begin
 New(Next);
 Next.Create(X_, Y_, Z_);
 Next.Count := Count + 1;
// Writeln('dllNext=', Next.X, Next.Y,' ', Next.Count);
end;

procedure TGeoPoint.FreeAll;
var P: PGeoPoint;
begin
// WriteIn(['dll.Free', Count]);
 If Next = nil then exit;
 Next.FreeAll;
 Dispose(Next);
end;

procedure TGeoPoint.Write(S: String);
begin
 WriteIn(['dllS=',S]);
end;

{ TGeoEdge }

procedure TGeoEdge.Create(XA_, YA_, ZA_, XB_, YB_, ZB_: Double);
begin
 XA := XA_; YA := YA_; XB := XB_; YB := YB_;
 ZA := ZA_; ZB := ZB_;
 XD := 0; YD := 0;
 Bulge := 0;
 Count := 0;
 Next := nil;
end;

procedure TGeoEdge.SetBulge(AValue: Double);
begin
 Bulge := AValue;
// вычисляем координаты XD, YD
end;

procedure TGeoEdge.AddCoord(XA_, YA_, ZA_, XB_, YB_, ZB_: Double);
begin
 New(Next);
 Next.Create(XA_, YA_, ZA_, XB_, YB_, ZB_);
 Next.Count := Count + 1;
end;

function TGeoEdge.GetArcRec: TArcRec;
begin
 Result := TArcRec.Create(XA, YA, ZA, XB, YB, ZB, XD, YD, 0);
end;

procedure TGeoEdge.FreeAll;
begin
 If Next = nil then exit;
 Next.FreeAll;
 Dispose(Next);
end;

procedure TGeoEdge.Write(S: String);
begin
 WriteIn(['dllS=',S]);
end;

end.
