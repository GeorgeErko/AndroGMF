unit objTopo32;

// Перенос модуля objTopo из Geomaster (Delphi 7, GDI): установка точечных
// условных знаков из панели знаков (instPointSign, кнопки по Tag):
//  mp_SetP (1)        - установка знака щелчком; при удержании левой кнопки
//                       дольше 0,5 с - поворот знака движением мыши
//                       (mp_SetPAngle), установка - следующим щелчком;
//  mp_RotateP (2)     - поворот знака на карте: щелчок по знаку, движение,
//                       щелчок (mp_RotatePoint -> mp_RotateP2);
//  mp_SetPAttr (3)    - знак параллельно указанной линии; правая кнопка -
//                       разворот на 180 градусов;
//  mp_SetPPerLine (5) - знаки по створу: две точки и число частей.
// Знак новой точки - TopoZnakNum (выбранный в панели знаков, -1 - знак по
// слою); точка создается в активном слое. Обработчики только меняют
// состояние, временный знак рисуется в DrawTemp тем же Draw32, что и сцена,
// белым силуэтом на live-слое (аналог XOR-отрисовки старой программы).
// Знак с надписями: перед добавлением точки - диалог ввода значений атрибутов
// (SetTextManager: TTextManager.SetTexts, при VarSetForm1 > 0 - SetTexts2).
// Диалог не блокирует обработчик (на Android синхронного ShowModal нет): точка
// добавляется в карту в обработчикLе результата, по «Отмене» - не добавляется.
// Притягивание знаков деревьев (дендро, кнопки sbP2P, sSpeedButton40/39/42):
//  mp_Point2Point (101)  - точка к точке: щелчок по первой точке, по второй,
//                          следующий щелчок - первая переносится во вторую;
//  mp_Point2Point2 (102) - знак дерева под курсором и точки съемки в радиусе
//                          AttractionRadius - линии к ним; щелчок по линии -
//                          дерево переносится в точку (голубая линия - точка уже
//                          совпадает: возврат дерева на прежнее место);
//  mp_Point2Point3 (103) - то же, дерево выбирается щелчком;
//  mp_Point2Point4 (104) - автопритягивание: деревья, у которых в радиусе
//                          AutoRadius есть точка съемки, помечаются крестом
//                          (красный - одна точка, голубой - несколько, берется
//                          ближайшая); щелчок по дереву - перенос, правая
//                          кнопка - снять пометку, вне дерева - меню исправления
//                          (OnAttractionMenu, FixMarks).
// Пометки хранятся в обработчике (в старой программе - свойство '#Статус' и
// указатель на точку в TPointDot.Ins, 32 бита - на Win64/Android непригодно).
// Не перенесено: откосы (mp_CreateOrtho), площадные знаки (mp_MoveSQWZnak,
// mp_DelSQWZnak), LockedDendro.

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     System.Generics.Collections, FMX.Types, objMouse32, objMouseSelect32,
     objMouseDraw32, drawTwigs32, Collect, EcDot, WpTwigs, WptForm2, mpMarker;

const
  mp_SetP = 1;
  mp_SetPAngle = 11;
  mp_RotateP = 2;
  mp_RotateP2 = 20;
  mp_RotatePoint = 21;
  mp_SetPAttr = 3;
  mp_SetPAttrLine = 4;
  mp_SetPPerLine = 5;
  mp_Point2Point = 101;
  mp_Point2Point2 = 102;
  mp_Point2Point3 = 103;
  mp_Point2Point4 = 104;

var
// знак для новых точек (бывшее пользовательское свойство 'Знак' редактора
// свойств старой программы); задается панелью знаков через форму
  TopoZnakNum: Integer = -1;
// радиусы поиска точек съемки: ручные методы (102, 103) и автопритягивание
// (104); сохраняются в настройках (objTopo.AttrRadius, objTopo.AutoRadius)
  AttractionRadius: Double = 2;
  AutoRadius: Double = 0.5;

type
// пометка дерева автопритягивания: точка, в которую переносится дерево;
// Kind: 1 - в радиусе одна точка (красный), 2 - несколько (голубой)
 TAttractionMark = record
  Target: TPointDot;
  Kind: Byte;
 end;

type
// признак жизни обработчика для отложенного результата диалога атрибутов
 IAliveFlag = interface
  ['{6B1C2E4A-9F3D-4A7B-8C21-5D0E7F3A9B14}']
  function Alive: Boolean;
  procedure Kill;
 end;

 TMouseTopo = class(TMousePainter)
  private
   FAlive: IAliveFlag;
   FTextsDialog: Boolean;  // открыт диалог атрибутов - мышь не обрабатывается
  public
   VarSetForm1: Byte;      // >0 - диалог атрибутов TTextManager.SetTexts2 (форма по режиму)
   DendroAttr, DendroValue: String; // атрибут, задаваемый до диалога (дендро)
   DendroUpdate: Boolean;  // значения атрибутов не берутся из последних введенных
   Point: TPointDot;
   PointCreating: Boolean; // Point создан здесь (не объект карты)
   PointVisible: Boolean;  // положение Point задано движением мыши
   PolySec500: Boolean;
   TimerTopo: TTimer;
   RotateAttr: Byte;
   Dot1: TDot;
   XM, YM: Double;
   OldUgol: Single;        // угол поворачиваемого знака до поворота
   Rotating: Boolean;      // поворот знака начат и не закончен
  // притягивание (mp_Point2Point*)
   Pnt1, Pnt2: TPointDot;  // точка к точке: первая и вторая точки
   Pnts: TList<TPointDot>; // [0] - дерево, далее - точки съемки в радиусе
   SaveX, SaveY: Double;   // положение дерева при выборе (возврат)
   SaveValid: Boolean;
   Marks: TDictionary<TPointDot, TAttractionMark>; // пометки автопритягивания
   OnAttractionMenu: TNotifyEvent; // правая кнопка вне дерева (104) - меню
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  // статический слой (обычное наложение, точные цвета): построения притягивания
   Procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  // смена знака в панели знаков - пересоздать устанавливаемую точку
   Procedure Return(Sender: TObject); override;
  //
   Function NewPoint(X, Y: Double): TPointDot;
   Procedure CreatePoint;
   Procedure FreePoint;
   Procedure DrawPoint(const Canvas: ISkCanvas);
   Procedure SetTextManager(const Attr, Value: String; UpdateResults: Boolean; const OnDone: TProc<Boolean>);
   Function InsertPoint(PD: TPointDot): Boolean;
   Procedure AddPointToMap;
   Procedure TimerTick(Sender: TObject);
   Procedure AskPerLine(X1, Y1, X2, Y2: Double);
   Procedure SetPPerLine(X1, Y1, X2, Y2: Double; CountParts: Integer; WithEnds: Boolean);
  // притягивание
   Procedure DrawDot(const Canvas: ISkCanvas; PD: TPointDot);
   Procedure DrawAttraction(const Canvas: ISkCanvas);
   Function MovePointTo(PD: TPointDot; X, Y: Double; const UndoName: String): Boolean;
   Function GetPPoint(X, Y: Double): Boolean;
   Procedure GetPPoint2(X, Y: Double);
   Function GetPnts(X, Y: Double): TPointDot;
   Procedure FindAutoMarks;
   Function MarkedNear(X, Y: Double): TPointDot;
  // построения притягивания изменились: статический слой и live-слой заново
   Procedure AttractionChanged;
  // меню автопритягивания: 1 - исправить красные, 2 - голубые, 3 - все
   Procedure FixMarks(Kind: Integer);
  // радиус ручных методов изменен - точки в радиусе выбранного дерева заново
   Procedure RefreshAttraction;
  // строка подсказки: состояние притягивания (найденные точки, пометки)
   Function Hint: String; override;
 end;

// радиусы притягивания: чтение из настроек (один раз) и запись
 procedure LoadAttractionRadius;
 procedure SaveAttractionRadius;

implementation

uses Math, FMX.DialogService, GBFWUndo, UndoColNew, newSelector, newClassBuilder,
     maths_basic, Lib, TextManager, ogcDrawerSkia, Writer, Selector32, FramePropEditor, VarSetForm,
     newProcs;

// расстояние от точки (X, Y) до отрезка (X1, Y1)-(X2, Y2)
function DistToSegment(X, Y, X1, Y1, X2, Y2: Double): Double;
var Dx, Dy, T: Double;
begin
 Dx := X2 - X1;
 Dy := Y2 - Y1;
 if (Dx = 0) and (Dy = 0) then T := 0 else T := ((X - X1) * Dx + (Y - Y1) * Dy) / (Dx * Dx + Dy * Dy);
 if T < 0 then T := 0 else if T > 1 then T := 1;
 Result := Distance(X, Y, X1 + T * Dx, Y1 + T * Dy);
end;

// знаки деревьев (лиственное, хвойное, кустарник) и точек съемки (притягивание)
// номер знака - по модулю: What бывает отрицательным (в знаковых коллекциях
// поиск всегда по abs(What))
function IsTreeZnak(PD: TPointDot): Boolean;
var Z: Integer;
begin
 Z := Abs(PD.GetZnak);
 Result := (Z = 40) or (Z = 34) or (Z = 97);
end;

function IsSurveyZnak(PD: TPointDot): Boolean;
var Z: Integer;
begin
 Z := Abs(PD.GetZnak);
 Result := (Z = 3901) or (Z = 394) or (Z = 3905) or (Z = 3906) or (Z = 3907) or (Z = 3952);
end;

type
 TAliveFlag = class(TInterfacedObject, IAliveFlag)
  private
   FAlive: Boolean;
  public
   constructor Create;
   function Alive: Boolean;
   procedure Kill;
 end;

constructor TAliveFlag.Create;
begin
 inherited Create;
 FAlive := True;
end;

function TAliveFlag.Alive: Boolean;
begin
 Result := FAlive;
end;

procedure TAliveFlag.Kill;
begin
 FAlive := False;
end;

{ TMouseTopo }

constructor TMouseTopo.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 FAlive := TAliveFlag.Create;
 Pnts := TList<TPointDot>.Create;
 Marks := TDictionary<TPointDot, TAttractionMark>.Create;
 LoadAttractionRadius;
 case LOperation of
 // автопритягивание: пометки деревьев сразу
  mp_Point2Point4: FindAutoMarks;
  mp_SetP: begin
    CreatePoint;
    TimerTopo := TTimer.Create(nil);
    TimerTopo.Interval := 500;
    TimerTopo.Enabled := False;
    TimerTopo.OnTimer := TimerTick;
   end;
  mp_SetPAttr: CreatePoint;
 end;
end;

destructor TMouseTopo.Destroy;
begin
// результат открытого диалога атрибутов придет уже без обработчика
 if FAlive <> nil then FAlive.Kill;
// поворот знака не закончен - вернуть угол и отменить запись в Undo (форма
// меняет Selector.LOperation до освобождения обработчика, поэтому - по флагу)
 if Rotating and (Point <> nil) then begin
  Point.Ugol := OldUgol;
  Undo.RollBack;
  UpdateImage;
 end;
 if PointCreating then FreePoint;
 TimerTopo.Free;
 Dot1.Free;
 Pnts.Free;
 Marks.Free;
 inherited;
end;

// новая точка с выбранным знаком в активном слое
function TMouseTopo.NewPoint(X, Y: Double): TPointDot;
begin
 Result := TPointDot.CreateTaheo(Twigs.LayerTable.ActiveLayer, -1, '', X, Y, ZNull);
 Result.Selector := Selector;
// свойства по умолчанию из редактора свойств, знак - выбранный в панели знаков
 if PropEditorForm <> nil then PropEditorForm.ApplyDefaults(Result);
 if TopoZnakNum <> -1 then Result.SetProperty('Знак', IntToStr(TopoZnakNum));
 BuildPoint1(Selector, Twigs.LayerTable, Twigs.Twigs, Result);
end;

procedure TMouseTopo.CreatePoint;
var X, Y: Double;
begin
 X := 0;
 Y := 0;
 if Point <> nil then begin
  X := Point.XDot;
  Y := Point.YDot;
 end;
 Point := NewPoint(X, Y);
 PointCreating := True;
end;

procedure TMouseTopo.FreePoint;
begin
 FreeAndNil(Point);
 PointCreating := False;
end;

procedure TMouseTopo.TimerTick(Sender: TObject);
begin
 PolySec500 := True;
 TimerTopo.Enabled := False;
end;

procedure TMouseTopo.Return(Sender: TObject);
var X, Y: Double;
    Ugol: Single;
begin
 case LOperation of
  mp_SetP, mp_SetPAngle, mp_SetPAttr:
   if PointCreating then begin
    X := Point.XDot;
    Y := Point.YDot;
    Ugol := Point.Ugol;
    FreePoint;
    Point := NewPoint(X, Y);
    Point.Ugol := Ugol;
    PointCreating := True;
    UpdateImage;
   end;
 end;
end;

// временный знак: Draw32 на live-канве, затем белый силуэт (live-слой
// смешивается со сценой в режиме Difference - аналог XOR старой программы)
procedure TMouseTopo.DrawPoint(const Canvas: ISkCanvas);
begin
 DrawDot(Canvas, Point);
end;

procedure TMouseTopo.DrawDot(const Canvas: ISkCanvas; PD: TPointDot);
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
begin
 if (PD = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  OldCanvas := Drawer.SwapSkCanvas(Canvas);
  PrevWorld := Drawer.UseWorldCoords;
  Drawer.UseWorldCoords := True;
  try
   PD.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
  finally
   Drawer.UseWorldCoords := PrevWorld;
   Drawer.RestoreSkCanvas(OldCanvas);
  end;
  Paint := TSkPaint.Create;
  Paint.Color := TAlphaColorRec.White;
  Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcIn);
  Canvas.DrawPaint(Paint);
 finally
  Canvas.Restore;
 end;
end;

procedure TMouseTopo.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var Pen: ISkPaint;
begin
 inherited;
 if Canvas = nil then exit;
 Pen := SkPen(Canvas, TAlphaColorRec.White, 1, True);
 case LOperation of
  mp_SetP, mp_SetPAngle, mp_SetPAttr: if PointVisible then DrawPoint(Canvas);
  mp_RotatePoint: begin
    DrawPoint(Canvas);
   // направление поворота
    if Point <> nil then SkDrawLineClipped(Canvas, Point.XDot, Point.YDot, XM, YM, Pen);
   end;
  mp_SetPPerLine: if Dot1 <> nil then SkDrawLineClipped(Canvas, Dot1.XDot, Dot1.YDot, XM, YM, Pen);
 // выбранное дерево - белым силуэтом (live-слой, Difference), построения -
 // в статическом слое (DrawTempStatic)
  mp_Point2Point2, mp_Point2Point3: if Pnts.Count > 0 then DrawDot(Canvas, Pnts[0]);
 end;
end;

procedure TMouseTopo.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 case LOperation of
  mp_Point2Point, mp_Point2Point2, mp_Point2Point3, mp_Point2Point4: DrawAttraction(Canvas);
 end;
end;

// знак с надписями (TMouseTopo.SetTextManager старой программы): менеджер
// текстов по знаку, атрибут Attr = Value, диалог ввода значений атрибутов.
// OnDone(True) - точку можно добавлять (без надписей - сразу, без диалога);
// OnDone(False) - «Отмена». Точка ставится в начало последнего примитива
// (LastPrim), если он есть (дендро: знак на нарисованной линии)
procedure TMouseTopo.SetTextManager(const Attr, Value: String; UpdateResults: Boolean; const OnDone: TProc<Boolean>);
var I: Integer;
    UZnak: TPoint_Sign;
    P: PCollection;
    A: IAliveFlag;
    Done: TTextsDone;
begin
 BuildPoint1(Selector, Twigs.LayerTable, Twigs.Twigs, Point);
 I := -1;
 if Point.What <> -1 then I := SearchThis(Twigs.MkLib.PSLib, Abs(Point.What));
 if (I = -1) or not TPoint_Sign(Twigs.MkLib.PSLib[I]).UseFont then begin
  OnDone(True);
  exit;
 end;
 UZnak := Twigs.MkLib.PSLib[I];
 if Point.TextManager = nil then begin
  P := PCollection.Create(1);
  try
   P.Insert(UZnak);
   Point.TextManager := TTextManager.Create;
   Point.TextManager.SetZnaks(P);
  finally
   P.DeleteAll;
   P.Free;
  end;
 end;
 if Attr <> '' then Point.TextManager.SetAttrValue(AnsiString(Attr), AnsiString(Value));
 Point.TextManager.UpdateResults := UpdateResults;
 A := FAlive;
 Done :=
  procedure(OK: Boolean)
  var D: TDot;
  begin
  // обработчик мог быть освобожден, пока открыт диалог
   if not A.Alive then exit;
   FTextsDialog := False;
   LMouseDown := False;
   if Point.TextManager <> nil then Point.TextManager.UpdateResults := False;
   if not OK then begin
    if not UpdateResults then Point.FreeTextManager;
   end else
   if LastPrim <> nil then
    try
     D := TTwig(LastPrim).Coord[0];
     Point.XDot := D.XDot;
     Point.YDot := D.YDot;
    except
    end;
   OnDone(OK);
  end;
 FTextsDialog := True;
// длина последнего нарисованного примитива (дендро: протяженность изгороди)
 if LastPrim <> nil then GLastPrimLength := TTwig(LastPrim).GetLength else GLastPrimLength := -1;
 if VarSetForm1 > 0 then
  Point.TextManager.SetTexts2(Twigs, Point, False, VarSetForm1, Done)
 else
  Point.TextManager.SetTexts(nil, Point.XDot, Point.YDot, Point.Z, True, Twigs, Done);
end;

// добавление точки в карту с отменой и в сцену
function TMouseTopo.InsertPoint(PD: TPointDot): Boolean;
begin
 Result := False;
 if Assigned(OnAddPrim) and not OnAddPrim(PD) then exit;
 Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'Undo.AddNewPrim...em_CreateZnak'));
 Twigs.Twigs.Insert(TWG_Point, PD);
 TPrimUndo(Undo.Last).AddModifiedPrim(PD);
 BuildPoint1(Selector, Twigs.LayerTable, Twigs.Twigs, PD);
 Modified;
 Selector.UpdateImage(usmAdd, PD);
 Result := True;
end;

// установленная точка уходит в карту, для следующей создается новая
procedure TMouseTopo.AddPointToMap;
var X, Y: Double;
begin
 X := Point.XDot;
 Y := Point.YDot;
 if not InsertPoint(Point) then exit;
 Point := nil;
 PointCreating := False;
 CreatePoint;
 Point.XDot := X;
 Point.YDot := Y;
end;

procedure TMouseTopo.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var D: TPointDot;
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
 case LOperation of
  mp_SetP: if not PolySec500 then TimerTopo.Enabled := True;
 // знак повернут - установка следующим отпусканием кнопки
  mp_SetPAngle: begin
    TimerTopo.Enabled := False;
    PolySec500 := False;
    LOperation := mp_SetP;
   end;
 // щелчок по знаку - начало поворота
  mp_RotateP, mp_RotateP2:
   if Point <> nil then begin
    OldUgol := Point.Ugol;
    Undo.StartTransAction;
    Undo.AddUndoItem(TPrimUndo.Create(Form, LU_ModifiedPrim, 'Undo.ModifiedPrim...em_RotateZnak'));
    TPrimUndo(Undo.Last).AddModifiedPrim(Point);
    Rotating := True;
    XM := X;
    YM := Y;
    LOperation := mp_RotatePoint;
    UpdateImage;
   end;
 // второй щелчок - поворот закончен
  mp_RotatePoint: begin
    Rotating := False;
    if Assigned(OnModifiedPrim) and not OnModifiedPrim(Point) then begin
     Point.Ugol := OldUgol;
     Undo.RollBack;
    end else begin
     Undo.Commit;
     Modified;
    end;
    Selector.UpdateImage(usmModify, Point);
    LOperation := mp_RotateP2;
    UpdateImage;
   end;
  mp_SetPAttr:
   SetTextManager('', '', False,
    procedure(OK: Boolean)
    begin
     if not OK then exit;
     AddPointToMap;
     UpdateImage;
    end);
 // створ: первая точка, затем вторая и число частей
  mp_SetPPerLine: begin
    if Marker.Visible then begin
     X := Marker.mX;
     Y := Marker.mY;
    end;
    XM := X;
    YM := Y;
    if Dot1 = nil then Dot1 := TDot.Create(X, Y, 0) else begin
     AskPerLine(Dot1.XDot, Dot1.YDot, X, Y);
     FreeAndNil(Dot1);
    end;
    UpdateImage;
   end;
 // точка к точке: выбраны обе - первая переносится во вторую
  mp_Point2Point:
   if (Pnt1 <> nil) and (Pnt2 <> nil) then begin
    MovePointTo(Pnt1, Pnt2.XDot, Pnt2.YDot, 'Undo.ModifiedPrim...mp_Point2Point');
    Pnt1 := nil;
    Pnt2 := nil;
    AttractionChanged;
   end else
   if GetPPoint(X, Y) then AttractionChanged;
 // дерево выбирается щелчком, затем щелчок по линии к точке съемки
  mp_Point2Point3:
   if Pnts.Count < 2 then begin
    GetPPoint2(X, Y);
    AttractionChanged;
   end else begin
    D := GetPnts(X, Y);
    if D <> nil then MovePointTo(Pnts[0], D.XDot, D.YDot, 'Undo.ModifiedPrim...mp_Point2Point3') else begin
     Pnts.Clear;
     GetPPoint2(X, Y);
    end;
    AttractionChanged;
   end;
 // дерево выбрано наведением, щелчок по линии к точке съемки
  mp_Point2Point2: begin
    D := GetPnts(X, Y);
    if D <> nil then MovePointTo(Pnts[0], D.XDot, D.YDot, 'Undo.ModifiedPrim...mp_Point2Point2') else begin
     Pnts.Clear;
     GetPPoint2(X, Y);
    end;
    AttractionChanged;
   end;
 // автопритягивание: щелчок по помеченному дереву - перенос в его точку,
 // с Ctrl - только снять пометку
  mp_Point2Point4: begin
    D := MarkedNear(X, Y);
    if D = nil then exit;
    if not (ssCtrl in Shift) then MovePointTo(D, Marks[D].Target.XDot, Marks[D].Target.YDot, 'Undo.ModifiedPrim...mp_Point2Point4');
    Marks.Remove(D);
    AttractionChanged;
   end;
 end;
end;

procedure TMouseTopo.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 case LOperation of
  mp_SetP:
   if not PolySec500 then begin
    TimerTopo.Enabled := False;
    if Button <> TMouseButton.mbLeft then exit;
    LMouseDown := False;
    SetTextManager(DendroAttr, DendroValue, DendroUpdate,
     procedure(OK: Boolean)
     begin
      if not OK then exit;
      AddPointToMap;
      UpdateImage;
     end);
   end else
  // кнопка удерживалась дольше 0,5 с - поворот знака движением мыши
    LOperation := mp_SetPAngle;
 end;
end;

procedure TMouseTopo.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Tw: TTwig;
    D1, D2: TDot;
    Seg: Integer;
begin
 if FTextsDialog then begin Hook := True; exit; end; // открыт диалог атрибутов
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 case LOperation of
  mp_SetP: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True, True);
    Point.XDot := X;
    Point.YDot := Y;
    PointVisible := True;
    UpdateImage;
   end;
  mp_SetPAngle: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True, True);
    Point.Ugol := Direct_Angle(Point.XDot, Point.YDot, X, Y) + Pi / 2;
    UpdateImage;
   end;
  mp_RotatePoint: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True, True);
    XM := X;
    YM := Y;
    Point.Ugol := Direct_Angle(Point.XDot, Point.YDot, X, Y) + Pi / 2;
    UpdateImage;
   end;
 // поиск знака под курсором (в старой программе - по маркеру привязки)
  mp_RotateP, mp_RotateP2: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
    if objTemporary is TPointDot then Point := TPointDot(objTemporary) else Point := nil;
    UpdateImage;
   end;
 // знак параллельно линии, к которой притянут курсор
  mp_SetPAttr: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True);
    Point.XDot := X;
    Point.YDot := Y;
    PointVisible := True;
    if (objTemporary <> nil) and (objTemporary is TTwig) then begin
     Tw := TTwig(objTemporary);
     Seg := Tw.GetSegment(X, Y);
     if (Seg > 0) and (Seg < Tw.Coord.Count) then begin
      D1 := Tw.Coord[Seg - 1];
      D2 := Tw.Coord[Seg];
      Point.Ugol := Direct_Angle(D2.XDot, D2.YDot, D1.XDot, D1.YDot) + RotateAttr * Pi;
     end;
    end;
    UpdateImage;
   end;
  mp_SetPPerLine: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True);
    XM := X;
    YM := Y;
    UpdateImage;
   end;
 // дерево под курсором и точки съемки в радиусе (без дерева - прежние)
  mp_Point2Point2: begin
    if Pnts.Count <> 0 then D1 := Pnts[0] else D1 := nil;
    GetPPoint2(X, Y);
    if Pnts.Count <> 0 then D2 := Pnts[0] else D2 := nil;
    if D1 <> D2 then AttractionChanged;
   end;
 end;
end;

procedure TMouseTopo.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var D: TPointDot;
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 case LOperation of
 // разворот знака на 180 градусов относительно линии
  mp_SetPAttr: begin
    if RotateAttr = 0 then begin
     Point.Ugol := Point.Ugol + Pi;
     RotateAttr := 1;
    end else begin
     Point.Ugol := 0;
     RotateAttr := 0;
    end;
    UpdateImage;
   end;
 // автопритягивание: у дерева - снять пометку, иначе - меню исправления
  mp_Point2Point4: begin
    D := MarkedNear(X, Y);
    if D <> nil then begin
     Marks.Remove(D);
     AttractionChanged;
    end else
    if Assigned(OnAttractionMenu) then OnAttractionMenu(Self);
   end;
 end;
end;

// параметры створа (в старой программе - диалог TFixedDistDlg)
procedure TMouseTopo.AskPerLine(X1, Y1, X2, Y2: Double);
begin
 if Distance(X1, Y1, X2, Y2) <= 0.001 then exit;
 TDialogService.InputQuery('Знаки по створу', ['Количество частей', 'Знаки в концах створа (1 - да, 0 - нет)'], ['2', '1'],
  procedure(const AResult: TModalResult; const AValues: array of string)
  var N: Integer;
  begin
   if AResult <> mrOk then exit;
   N := StrToIntDef(Trim(AValues[0]), 0);
   if N < 1 then exit;
   SetPPerLine(X1, Y1, X2, Y2, N, Trim(AValues[1]) = '1');
  end);
end;

// знаки по створу (X1,Y1)-(X2,Y2): CountParts частей, в концах - по WithEnds;
// знаки повернуты поперек створа
procedure TMouseTopo.SetPPerLine(X1, Y1, X2, Y2: Double; CountParts: Integer; WithEnds: Boolean);
var I: Integer;
    X, Y, MidDist, Angle: Double;
procedure AddPoint(XP, YP: Double);
var PD: TPointDot;
begin
 PD := NewPoint(XP, YP);
 PD.Ugol := Angle + Pi / 2;
 if not InsertPoint(PD) then PD.Free;
end;
begin
 Angle := Direct_Angle(X1, Y1, X2, Y2);
 MidDist := Distance(X1, Y1, X2, Y2) / CountParts;
 Undo.StartTransAction;
 try
  if WithEnds then begin
   AddPoint(X1, Y1);
   AddPoint(X2, Y2);
  end;
  X := X1;
  Y := Y1;
  for I := 0 to CountParts - 2 do begin
   X := X + MidDist * Cos(Angle);
   Y := Y + MidDist * Sin(Angle);
   AddPoint(X, Y);
  end;
  Undo.Commit;
 except
  on E: Exception do begin
   WriteIn(['SetPPerLine exception ', E.Message]);
   Undo.RollBack;
  end;
 end;
 UpdateImage;
end;

{ притягивание }

// направляющая от дерева P к точке съемки P1 - в мировых координатах: из
// точки дерева через точку съемки и дальше на четверть расстояния (линия
// проходит точно через точку и не меняется при масштабировании); Result -
// точка совпадает с деревом (направления нет, отметка - голубой круг у дерева)
function AttractionLineEnd(P, P1: TPointDot; out XX, YY: Double): Boolean;
const Extend = 0.25;
begin
 Result := Distance(P.XDot, P.YDot, P1.XDot, P1.YDot) < 0.001;
 XX := P1.XDot + (P1.XDot - P.XDot) * Extend;
 YY := P1.YDot + (P1.YDot - P.YDot) * Extend;
end;

// перенос точки PD в (X, Y) с отменой; OnModifiedPrim отклонил - назад
function TMouseTopo.MovePointTo(PD: TPointDot; X, Y: Double; const UndoName: String): Boolean;
var OldX, OldY: Double;
    Item: TPrimUndo;
begin
 Result := False;
 if PD = nil then exit;
 OldX := PD.XDot;
 OldY := PD.YDot;
// копия до изменения; при заблокированной Undo AddUndoItem освобождает запись
 Item := TPrimUndo.Create(Twigs, LU_ModifiedPrim, UndoName);
 Item.AddModifiedPrim(PD);
 Undo.AddUndoItem(Item);
 PD.XDot := X;
 PD.YDot := Y;
 if Assigned(OnModifiedPrim) and not OnModifiedPrim(PD) then begin
  PD.XDot := OldX;
  PD.YDot := OldY;
  if Undo.Last = Item then Undo.LastFree;
  exit;
 end;
 Modified;
 Selector.UpdateImage(usmModify, PD);
 Result := True;
end;

// точка к точке: щелчок по выбранной точке снимает выбор, иначе - первая,
// затем вторая точка
function TMouseTopo.GetPPoint(X, Y: Double): Boolean;
var I: Integer;
    B: Byte;
    PD: TPointDot;
begin
 Result := True;
 for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if (B <> TWG_Point) or (Selector.XRasst(Distance(PD.XDot, PD.YDot, X, Y)) >= 10) then continue;
  if PD = Pnt1 then begin Pnt1 := nil; exit; end;
  if PD = Pnt2 then begin Pnt2 := nil; exit; end;
  if Pnt1 = nil then begin Pnt1 := PD; exit; end;
  if Pnt2 = nil then begin Pnt2 := PD; exit; end;
 end;
 Result := False;
end;

// дерево у (X, Y) и точки съемки в радиусе AttractionRadius; дерева нет -
// выбор прежний
procedure TMouseTopo.GetPPoint2(X, Y: Double);
var I, J: Integer;
    B, B2: Byte;
    PD, D: TPointDot;
begin
 for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if (B <> TWG_Point) or not IsTreeZnak(PD) or (Selector.XRasst(Distance(PD.XDot, PD.YDot, X, Y)) >= 10) then continue;
  Pnts.Clear;
  Pnts.Add(PD);
  SaveX := PD.XDot;
  SaveY := PD.YDot;
  SaveValid := True;
  for J := 0 to Twigs.Twigs.AnyCount - 1 do begin
   D := Twigs.Twigs.AAt(J, B2);
   if (D = PD) or (B2 <> TWG_Point) or not IsSurveyZnak(D) then continue;
   if Distance(PD.XDot, PD.YDot, D.XDot, D.YDot) <= AttractionRadius then Pnts.Add(D);
  end;
 end;
end;

// точка съемки, к направляющей которой щелкнули (не дальше 4 пикселов);
// голубой круг (точка совпадает с деревом, щелчок не дальше 6 пикселов от
// дерева) - дерево возвращается на прежнее место
function TMouseTopo.GetPnts(X, Y: Double): TPointDot;
var I: Integer;
    P, P1: TPointDot;
    XX, YY: Double;
begin
 Result := nil;
 if Pnts.Count = 0 then exit;
 P := Pnts[0];
 for I := 1 to Pnts.Count - 1 do begin
  P1 := Pnts[I];
  if AttractionLineEnd(P, P1, XX, YY) then begin
   if Selector.XRasst(Distance(X, Y, P.XDot, P.YDot)) <= 6 then begin
    if SaveValid then MovePointTo(P, SaveX, SaveY, 'Undo.ModifiedPrim...mp_Point2Point_Return');
    exit;
   end;
  end else
  if Selector.XRasst(DistToSegment(X, Y, P.XDot, P.YDot, XX, YY)) <= 4 then begin
   Result := P1;
   exit;
  end;
 end;
end;

// автопритягивание: видимые деревья с точкой съемки в радиусе AutoRadius
// (совпадающие точки не считаются); несколько точек - голубая пометка и
// ближайшая точка
procedure TMouseTopo.FindAutoMarks;
var I, J: Integer;
    B, B2: Byte;
    PD, D: TPointDot;
    Dist: Double;
    M: TAttractionMark;
begin
 Marks.Clear;
 for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if (B <> TWG_Point) or not IsTreeZnak(PD) or not PD.isVisible then continue;
  for J := 0 to Twigs.Twigs.AnyCount - 1 do begin
   D := Twigs.Twigs.AAt(J, B2);
   if (D = PD) or (B2 <> TWG_Point) or not IsSurveyZnak(D) then continue;
   Dist := Distance(PD.XDot, PD.YDot, D.XDot, D.YDot);
   if (Dist > AutoRadius) or (Dist <= 0.001) then continue;
   if Marks.TryGetValue(PD, M) then begin
    M.Kind := 2;
    if Dist < Distance(PD.XDot, PD.YDot, M.Target.XDot, M.Target.YDot) then M.Target := D;
    Marks[PD] := M;
   end else begin
    M.Target := D;
    M.Kind := 1;
    Marks.Add(PD, M);
   end;
  end;
 end;
end;

// помеченное дерево у (X, Y), не дальше 10 пикселов
function TMouseTopo.MarkedNear(X, Y: Double): TPointDot;
var PD: TPointDot;
begin
 Result := nil;
 for PD in Marks.Keys do
  if Selector.XRasst(Distance(PD.XDot, PD.YDot, X, Y)) <= 10 then begin
   Result := PD;
   exit;
  end;
end;

// меню автопритягивания (MIIsp3Click старой программы): помеченные деревья
// вида Kind (3 - все) переносятся в свои точки одной операцией отмены
// (в старой программе Undo очищалась), все пометки снимаются
procedure TMouseTopo.FixMarks(Kind: Integer);
var Pair: TPair<TPointDot, TAttractionMark>;
    List: TList<TPair<TPointDot, TAttractionMark>>;
begin
 List := TList<TPair<TPointDot, TAttractionMark>>.Create;
 try
  for Pair in Marks do
   if (Kind = 3) or (Pair.Value.Kind = Kind) then List.Add(Pair);
  Marks.Clear;
  if List.Count > 0 then begin
   Undo.StartTransAction;
   try
    for Pair in List do MovePointTo(Pair.Key, Pair.Value.Target.XDot, Pair.Value.Target.YDot, 'Undo.ModifiedPrim...mp_Point2Point4');
    Undo.Commit;
   except
    on E: Exception do begin
     WriteIn(['FixMarks exception ', E.Message]);
     Undo.RollBack;
    end;
   end;
  end;
 finally
  List.Free;
 end;
 AttractionChanged;
end;

function TMouseTopo.Hint: String;
begin
 case LOperation of
  mp_Point2Point:
   if Pnt1 = nil then Result := 'Точка в точку: щелкните первую точку' else
   if Pnt2 = nil then Result := 'Точка в точку: щелкните вторую точку' else
    Result := 'Точка в точку: щелчок - перенос первой точки во вторую';
  mp_Point2Point2, mp_Point2Point3:
   if Pnts.Count = 0 then Result := 'Притягивание: выберите дерево' else
    Result := Format('Притягивание: точек съемки в радиусе %.2f - %d', [AttractionRadius, Pnts.Count - 1]);
  mp_Point2Point4: Result := Format('Автопритягивание: помечено деревьев - %d (радиус %.1f)', [Marks.Count, AutoRadius]);
 else
  Result := inherited Hint;
 end;
end;

procedure TMouseTopo.RefreshAttraction;
begin
 if not SaveValid then exit;
 Pnts.Clear;
 GetPPoint2(SaveX, SaveY);
 AttractionChanged;
end;

procedure TMouseTopo.AttractionChanged;
begin
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 UpdateImage;
end;

// построения притягивания в статическом слое: слой накладывается на сцену
// обычным образом, поэтому цвета - как есть (на live-слое Difference меняет
// цвет в зависимости от фона); без сглаживания - чистый цвет, как перо GDI
procedure TMouseTopo.DrawAttraction(const Canvas: ISkCanvas);
var I: Integer;
    P, P1: TPointDot;
    XX, YY, R: Double;
    Pen: ISkPaint;
    Pair: TPair<TPointDot, TAttractionMark>;
function MakePen(Color: TAlphaColor): ISkPaint;
begin
 Result := SkPen(Canvas, Color, 2, False);
 Result.AntiAlias := False;
end;
procedure DrawBox(PD: TPointDot; Color: TAlphaColor);
begin
 if PD = nil then exit;
 R := Selector.XGeoRasst(6);
 Canvas.DrawRect(TRectF.Create(PD.XDot - R, PD.YDot - R, PD.XDot + R, PD.YDot + R), MakePen(Color));
end;
begin
 case LOperation of
  mp_Point2Point: begin
    DrawBox(Pnt1, TAlphaColors.Red);
    DrawBox(Pnt2, TAlphaColors.Blue);
   end;
  mp_Point2Point2, mp_Point2Point3:
   if Pnts.Count > 0 then begin
    P := Pnts[0];
    for I := 1 to Pnts.Count - 1 do begin
     P1 := Pnts[I];
     if AttractionLineEnd(P, P1, XX, YY) then
     // точка уже совпадает с деревом - голубой круг
      Canvas.DrawCircle(P.XDot, P.YDot, Selector.XGeoRasst(6), MakePen(TAlphaColors.Blue))
     else
     // направляющая через точку съемки
      SkDrawLineClipped(Canvas, P.XDot, P.YDot, XX, YY, MakePen(TAlphaColors.Red));
    end;
   end;
 // пометки: красный крест - одна точка в радиусе, голубой - несколько
  mp_Point2Point4: begin
    R := Selector.XGeoRasst(5);
    for Pair in Marks do begin
     if Pair.Value.Kind = 1 then Pen := MakePen(TAlphaColors.Red) else Pen := MakePen(TAlphaColors.Aqua);
     P := Pair.Key;
     SkDrawLineClipped(Canvas, P.XDot - R, P.YDot - R, P.XDot + R, P.YDot + R, Pen);
     SkDrawLineClipped(Canvas, P.XDot - R, P.YDot + R, P.XDot + R, P.YDot - R, Pen);
    end;
   end;
 end;
end;

// радиусы поиска - из настроек при первом обработчике, в настройки - формой
// при изменении (UpDown1, UpDown2)
var RadiusLoaded: Boolean = False;

procedure LoadAttractionRadius;
begin
 if RadiusLoaded then exit;
 RadiusLoaded := True;
 AttractionRadius := GReadFloat('objTopo.AttrRadius', AttractionRadius);
 AutoRadius := GReadFloat('objTopo.AutoRadius', AutoRadius);
end;

procedure SaveAttractionRadius;
begin
 GWriteFloat('objTopo.AttrRadius', AttractionRadius);
 GWriteFloat('objTopo.AutoRadius', AutoRadius);
end;

end.
