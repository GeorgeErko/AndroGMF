unit objAddZas32;

// Перенос модуля objAddZasGB из Geomaster (Delphi 7, GDI), только операции
// кнопок ОЗН dnrPerp и dnrZas (TMasterDendro.dnrPerpClick/dnrZasClick):
// Lo_Perpend - установка точки методом перпендикуляров: щелчки - точки a и b
// базовой линии, затем точка (третий щелчок) или ввод расстояний по правой
// кнопке (от a вдоль линии и длина перпендикуляра);
// Lo_InvZas - обратная линейная засечка: щелчки - опорные точки (притягиваются
// к точкам карты, повторный щелчок по опорной точке снимает ее), с QuickInvZas
// третий щелчок ставит точку; по правой кнопке - ввод расстояний от опорных
// точек, точка - пересечение окружностей первых двух опорных точек (ближайшее
// к точке щелчка).
// Точка ставится в активный слой со свойствами по умолчанию редактора свойств.
// Обработчики мыши только меняют состояние и вызывают UpdateImage; все
// рисуется в DrawTemp, расстояния - в подсказке (Hint).
// Расчет засечки - в Double (TLineZas старой программы считал в Single).
// Не перенесено: остальные операции TZas (створы, прямая засечка, параллели,
// сегменты, перемещение точек и линий), уравнивание засечки по 3 и более
// точкам (Equalizing_Zasechka), кнопка «Очистить» диалога перпендикуляра.

interface uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
               FMX.Types, objMouse32, objMouseDraw32, Collect, EcDot, WptForm2, newSelector;

const
  Lo_Perpend = 401;
  Lo_InvZas = 403;

type
 TZas32 = class(TMousePainter)
  private
   FInputDialog: Boolean; // открыт диалог ввода расстояний - мышь не обрабатывается
   function GetPoint(Index: Integer): TDot;
  public
   X2, Y2: Double;        // курсор
   Perpend: TSect;        // XB,YB - основание перпендикуляра, XA,YA - курсор
   ActiveLine: TSect;     // базовая линия a-b
   Points: PCollection;   // поставленные точки (копии)
   QuickInvZas: Boolean;  // третий щелчок обратной засечки ставит точку
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Function Hint: String; override;
  //
   Procedure CreatePerpend(X, Y: Double);
   Procedure DrawPerpend(const Canvas: ISkCanvas);
   Procedure DrawInvZas(const Canvas: ISkCanvas);
   Procedure ToggleInvZasPoint(X, Y: Double);
   Procedure AddPoint(X, Y: Double);
   Procedure InputPerpend;
   Procedure InputInvZas(X, Y: Double);
   Property Point[Index: Integer]: TDot read GetPoint;
 end;

implementation uses System.Math, FMX.DialogService, maths_basic, GBFWUndo, UndoColNew,
                    FramePropEditor, newResource, drawTwigs32, Selector32;

var GActiveZas: TZas32; // обработчик жив - для отложенного результата диалога

function FmtDist(D: Double): String;
begin
 Result := FloatToStrF(D, ffFixed, 15, 2);
end;

// число из поля ввода: разделитель - точка или запятая; ошибка - NaN
function InputFloat(const S: String): Double;
begin
 Result := StrToFloatDef(StringReplace(Trim(S), ',', '.', [rfReplaceAll]), NaN, TFormatSettings.Invariant);
end;

// пересечение окружностей (X1,Y1,R1) и (X2,Y2,R2): две точки (касание - одна дважды)
function CirclesCross(X1, Y1, R1, X2, Y2, R2: Double; out XA, YA, XB, YB: Double): Boolean;
const Eps = 1E-6;
var D, A, H, XM, YM: Double;
begin
 D := Distance(X1, Y1, X2, Y2);
 Result := (D > Eps) and (D <= R1 + R2 + Eps) and (D >= Abs(R1 - R2) - Eps);
 if not Result then exit;
 A := (Sqr(R1) - Sqr(R2) + Sqr(D)) / (2 * D);
 H := Sqrt(Max(0, Sqr(R1) - Sqr(A)));
 XM := X1 + A * (X2 - X1) / D;
 YM := Y1 + A * (Y2 - Y1) / D;
 XA := XM + H * (Y2 - Y1) / D;
 YA := YM - H * (X2 - X1) / D;
 XB := XM - H * (Y2 - Y1) / D;
 YB := YM + H * (X2 - X1) / D;
end;

// подпись высотой 14 px в мировых координатах
procedure SkLabel(const Canvas: ISkCanvas; X, Y: Double; const Text: String);
var Font: ISkFont;
    Paint: ISkPaint;
begin
 if (Canvas = nil) or (Text = '') then exit;
 Font := TSkFont.Create(nil, SkPixToWorld(Canvas, 14));
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Color := SkLiveColor(TAlphaColorRec.Red);
 Canvas.DrawSimpleText(Text, X, Y, Font, Paint);
end;

{ TZas32 }

constructor TZas32.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited Create(ATwigs, AFreeProc);
 ActiveLine.XA := ZNull;
 ActiveLine.XB := ZNull;
 Perpend.XA := ZNull;
 Perpend.XB := ZNull;
 X2 := ZNull;
 Y2 := ZNull;
 Points := PCollection.Create(1);
 Twigs.ClearSelection;
 GActiveZas := Self;
end;

destructor TZas32.Destroy;
begin
 if GActiveZas = Self then GActiveZas := nil;
 Points.FreeAll;
 Points.Free;
 inherited Destroy;
end;

function TZas32.GetPoint(Index: Integer): TDot;
begin
 Result := Points[Index];
end;

// основание перпендикуляра из (X,Y) на прямую a-b
procedure TZas32.CreatePerpend(X, Y: Double);
var Dx, Dy, L2, T: Double;
begin
 if (ActiveLine.XA = ZNull) or (ActiveLine.XB = ZNull) then exit;
 with ActiveLine do begin
  Dx := XB - XA;
  Dy := YB - YA;
  L2 := Sqr(Dx) + Sqr(Dy);
  if L2 > 0 then T := ((X - XA) * Dx + (Y - YA) * Dy) / L2 else T := 0;
  Perpend.XB := XA + T * Dx;
  Perpend.YB := YA + T * Dy;
 end;
 Perpend.XA := X;
 Perpend.YA := Y;
end;

// новая точка в активном слое (свойства по умолчанию - из редактора свойств)
procedure TZas32.AddPoint(X, Y: Double);
var PD: TPointDot;
    Layer: TResource;
begin
 Layer := Twigs.LayerTable.ActiveLayer;
 if Layer = nil then exit;
 PD := TPointDot.CreateTaheo(Layer, -1, '', X, Y, ZNull);
 PD.Selector := Selector;
 if Assigned(OnAddPrim) and not OnAddPrim(PD) then begin PD.Free; exit; end;
 if PropEditorForm <> nil then PropEditorForm.ApplyDefaults(PD);
 Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'UndoAddNewPoint...em_InvZas'));
 Twigs.Twigs.Insert(TWG_Point, PD);
 TPrimUndo(Undo.Last).AddModifiedPrim(PD);
 Twigs.ClassBuildII;
 Modified;
 Selector.UpdateImage(usmAdd, PD);
end;

// опорная точка обратной засечки: точка карты под курсором или точка щелчка;
// повторный щелчок по опорной точке снимает ее
procedure TZas32.ToggleInvZasPoint(X, Y: Double);
var D: TDot;
    I: Integer;
begin
 D := emGetNearestPoint(X, Y);
 if D <> nil then begin X := D.XDot; Y := D.YDot; end;
 for I := 0 to Points.Count - 1 do
  if EqualAnyPoints(Point[I].XDot, Point[I].YDot, X, Y) then begin
   Points.AtFree(I);
   exit;
  end;
 Points.Insert(TDot.Create(X, Y, 100));
end;

procedure TZas32.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FInputDialog then exit;
 inherited MouseDown(Form, Button, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if Button <> TMouseButton.mbLeft then exit;
 Hook := True;
 case LOperation of
  Lo_Perpend: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary);
    Points.Insert(TDot.Create(X, Y, 100));
   // третья точка - новая точка карты, базовая линия остается
    if Points.Count = 3 then begin
     AddPoint(X, Y);
     Points.AtFree(2);
     LMouseDown := False;
    end else
    if Points.Count = 2 then begin ActiveLine.XB := X; ActiveLine.YB := Y; end else
    if Points.Count = 1 then begin ActiveLine.XA := X; ActiveLine.YA := Y; end;
    CreatePerpend(X, Y);
    X2 := X;
    Y2 := Y;
   end;
  Lo_InvZas: begin
    Marker.Remove(GCanvas);
    if QuickInvZas and (Points.Count = 2) then begin
     AddPoint(X, Y);
     Points.FreeAll;
     LMouseDown := False;
    end else ToggleInvZasPoint(X, Y);
    X2 := X;
    Y2 := Y;
   end;
 end;
 UpdateImage;
end;

procedure TZas32.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited MouseRightDown(Form, Button, Shift, X, Y, Hook);
 Hook := False;
 if ShiftPress or ControlPress then exit;
 Hook := True;
 case LOperation of
  Lo_Perpend: if Points.Count > 1 then InputPerpend;
  Lo_InvZas: if Points.Count > 1 then InputInvZas(X, Y);
 end;
end;

procedure TZas32.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FInputDialog then exit;
 inherited MouseUp(Form, Button, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then Hook := False;
end;

procedure TZas32.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var D: TDot;
begin
 Hook := True;
 if FInputDialog then exit;
 inherited MouseMove(Form, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 Hook := True;
 case LOperation of
  Lo_Perpend: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary);
    CreatePerpend(X, Y);
   end;
  Lo_InvZas: begin
    D := emGetNearestPoint(X, Y);
    if D <> nil then Marker.Move(GCanvas, D.XDot, D.YDot) else Marker.Remove(GCanvas);
   end;
 end;
 X2 := X;
 Y2 := Y;
 UpdateImage;
end;

// базовая линия a-b, ее продолжение до основания и перпендикуляр
procedure TZas32.DrawPerpend(const Canvas: ISkCanvas);
var Pen, Dash: ISkPaint;
    D: Double;
begin
 Pen := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 1, False);
 Dash := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 1, True);
 with ActiveLine do begin
  if XA = ZNull then exit;
  SkLabel(Canvas, XA, YA, 'a');
 // одна точка - резиновая линия до курсора
  if XB = ZNull then begin
   if X2 <> ZNull then SkDrawLineClipped(Canvas, XA, YA, X2, Y2, Dash);
   exit;
  end;
  SkLabel(Canvas, XB, YB, 'b');
  SkDrawLineClipped(Canvas, XA, YA, XB, YB, Pen);
  if Perpend.XB = ZNull then exit;
 // основание за пределами a-b
  SkDrawLineClipped(Canvas, XA, YA, Perpend.XB, Perpend.YB, Dash);
  SkDrawLineClipped(Canvas, XB, YB, Perpend.XB, Perpend.YB, Dash);
 end;
 with Perpend do begin
  SkDrawLineClipped(Canvas, XA, YA, XB, YB, Pen);
  D := Distance(XA, YA, XB, YB);
  SkLabel(Canvas, (XA + XB) / 2, (YA + YB) / 2, FmtDist(D));
  SkLabel(Canvas, (ActiveLine.XA + XB) / 2, (ActiveLine.YA + YB) / 2, FmtDist(Distance(ActiveLine.XA, ActiveLine.YA, XB, YB)));
 end;
end;

// линии от опорных точек до курсора с расстояниями, номера опорных точек
procedure TZas32.DrawInvZas(const Canvas: ISkCanvas);
var Pen: ISkPaint;
    I: Integer;
    D: TDot;
begin
 Pen := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 1, True);
 for I := 0 to Points.Count - 1 do begin
  D := Point[I];
  SkLabel(Canvas, D.XDot, D.YDot, IntToStr(I + 1));
  if X2 = ZNull then continue;
  SkDrawLineClipped(Canvas, D.XDot, D.YDot, X2, Y2, Pen);
  SkLabel(Canvas, (D.XDot + X2) / 2, (D.YDot + Y2) / 2, FmtDist(Distance(D.XDot, D.YDot, X2, Y2)));
 end;
end;

procedure TZas32.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 case LOperation of
  Lo_Perpend: DrawPerpend(Canvas);
  Lo_InvZas: DrawInvZas(Canvas);
 end;
end;

// La - от a до основания, Lc - от b до основания, Lb - перпендикуляр;
// у засечки - расстояния от опорных точек до курсора
function TZas32.Hint: String;
var I: Integer;
begin
 Result := '';
 case LOperation of
  Lo_Perpend: if (Points.Count > 1) and (Perpend.XB <> ZNull) then with ActiveLine do
    Result := 'La = ' + FmtDist(Distance(XA, YA, Perpend.XB, Perpend.YB)) +
              '  Lc = ' + FmtDist(Distance(XB, YB, Perpend.XB, Perpend.YB)) +
              '  Lb = ' + FmtDist(Distance(Perpend.XA, Perpend.YA, Perpend.XB, Perpend.YB)) else
    Result := 'Перпендикуляр: укажите точки a и b базовой линии';
  Lo_InvZas: if (Points.Count = 0) or (X2 = ZNull) then Result := 'Обратная засечка: укажите опорные точки' else
    for I := 0 to Points.Count - 1 do
     Result := Result + 'L' + IntToStr(I + 1) + ' = ' + FmtDist(Distance(Point[I].XDot, Point[I].YDot, X2, Y2)) + '  ';
 end;
end;

// ввод расстояний перпендикуляра (TPerpendQuickForm): от a вдоль a-b и длина
// перпендикуляра; сторона - по текущему положению курсора
procedure TZas32.InputPerpend;
var Z: TZas32;
    La, Lb: Double;
begin
 if Perpend.XB = ZNull then CreatePerpend(MouseX, MouseY);
 La := Distance(ActiveLine.XA, ActiveLine.YA, Perpend.XB, Perpend.YB);
 Lb := Distance(Perpend.XA, Perpend.YA, Perpend.XB, Perpend.YB);
 Z := Self;
 FInputDialog := True;
 LMouseDown := False;
 RMouseDown := False;
 TDialogService.InputQuery('Перпендикуляр', ['Расстояние от a', 'Перпендикуляр'], [FmtDist(La), FmtDist(Lb)],
  procedure(const AResult: TModalResult; const AValues: array of string)
  var A, C, L, Ux, Uy, Side: Double;
  begin
   if GActiveZas <> Z then exit;
   FInputDialog := False;
   if AResult <> mrOk then exit;
   A := InputFloat(AValues[0]);
   C := InputFloat(AValues[1]);
   if IsNan(A) or IsNan(C) then begin TDialogService.ShowMessage('Введите корректные расстояния'); exit; end;
   with ActiveLine do begin
    L := Distance(XA, YA, XB, YB);
    if L = 0 then exit;
    Ux := (XB - XA) / L;
    Uy := (YB - YA) / L;
   // сторона перпендикуляра: знак векторного произведения (a-b) x (a-курсор)
    Side := Ux * (Perpend.YA - YA) - Uy * (Perpend.XA - XA);
    if Side < 0 then Side := -1 else Side := 1;
    Perpend.XB := XA + A * Ux;
    Perpend.YB := YA + A * Uy;
   end;
   Perpend.XA := Perpend.XB - Side * C * Uy;
   Perpend.YA := Perpend.YB + Side * C * Ux;
   AddPoint(Perpend.XA, Perpend.YA);
   UpdateImage;
  end);
end;

// ввод расстояний от опорных точек (TInvZas): точка - пересечение окружностей
// первых двух опорных точек, ближайшее к точке щелчка (X,Y)
procedure TZas32.InputInvZas(X, Y: Double);
var Z: TZas32;
    Prompts, Values: array of String;
    I: Integer;
begin
 SetLength(Prompts, Points.Count);
 SetLength(Values, Points.Count);
 for I := 0 to Points.Count - 1 do begin
  Prompts[I] := 'S' + IntToStr(I + 1);
  Values[I] := FmtDist(Distance(Point[I].XDot, Point[I].YDot, X, Y));
 end;
 Z := Self;
 FInputDialog := True;
 LMouseDown := False;
 RMouseDown := False;
 TDialogService.InputQuery('Обратная засечка', Prompts, Values,
  procedure(const AResult: TModalResult; const AValues: array of string)
  var R1, R2, XA, YA, XB, YB: Double;
  begin
   if GActiveZas <> Z then exit;
   FInputDialog := False;
   if AResult <> mrOk then exit;
   R1 := InputFloat(AValues[0]);
   R2 := InputFloat(AValues[1]);
   if IsNan(R1) or IsNan(R2) or (R1 <= 0) or (R2 <= 0) or
      not CirclesCross(Point[0].XDot, Point[0].YDot, R1, Point[1].XDot, Point[1].YDot, R2, XA, YA, XB, YB) then begin
    TDialogService.ShowMessage('Невозможно просчитать засечку. Введите корректные расстояния.');
    exit;
   end;
   if Distance(XA, YA, X, Y) <= Distance(XB, YB, X, Y) then AddPoint(XA, YA) else AddPoint(XB, YB);
   Points.FreeAll;
   UpdateImage;
  end);
end;

initialization
 AddMouseHook(TZas32);
end.
