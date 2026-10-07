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
// Не перенесено: откосы (mp_CreateOrtho), площадные знаки (mp_MoveSQWZnak,
// mp_DelSQWZnak), mp_Point2Point*, LockedDendro.

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     FMX.Types, objMouse32, objMouseSelect32, objMouseDraw32, drawTwigs32,
     Collect, EcDot, WpTwigs, WptForm2, mpMarker;

const
  mp_SetP = 1;
  mp_SetPAngle = 11;
  mp_RotateP = 2;
  mp_RotateP2 = 20;
  mp_RotatePoint = 21;
  mp_SetPAttr = 3;
  mp_SetPAttrLine = 4;
  mp_SetPPerLine = 5;

var
// знак для новых точек (бывшее пользовательское свойство 'Знак' редактора
// свойств старой программы); задается панелью знаков через форму
  TopoZnakNum: Integer = -1;

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
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
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
 end;

implementation

uses Math, FMX.DialogService, GBFWUndo, UndoColNew, newSelector, newClassBuilder,
     maths_basic, Lib, TextManager, ogcDrawerSkia, Writer, Selector32, FramePropEditor, VarSetForm;

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
 case LOperation of
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
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
begin
 if (Point = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  OldCanvas := Drawer.SwapSkCanvas(Canvas);
  PrevWorld := Drawer.UseWorldCoords;
  Drawer.UseWorldCoords := True;
  try
   Point.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
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
 end;
end;

procedure TMouseTopo.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
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

end.
