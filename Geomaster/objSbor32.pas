unit objSbor32;

// Перенос операций панели сборки FlySbor из Geomaster (Delphi 7, GDI):
// em_NewPoly (524, RbPolyLot - площадной объект по указанным сегментам,
// TEditMap), em_NewPolyA (525, RbAuto - площадной объект в автоматическом
// режиме, TForm1.SetLot), Lo_AddSegment (407, rbDosbor - изменение выбранного
// контура по указанным сегментам, TZas).
// em_NewPoly: щелчки отмечают сегменты (повторный щелчок снимает), правая
// кнопка - площадной объект в активном слое.
// em_NewPolyA: щелчок у сегмента собирает контур обходом смежных сегментов с
// наименьшим или наибольшим углом (берется контур, содержащий точку щелчка),
// правая кнопка - площадной объект в активном слое.
// Lo_AddSegment: первый щелчок выбирает контур, следующие добавляют/снимают
// сегменты, правая кнопка записывает изменение контура.
// Обработчики мыши только меняют состояние и вызывают UpdateImage; все
// рисуется в DrawTemp. Подтверждения - через TDialogService (на Android
// синхронного диалога нет).
// Не перенесено: диалог выбора слоя (psQueryLayerSbor) - берется активный слой,
// повторение автосборки по клавише, ветки PPLAN.

interface uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
               System.Generics.Collections, FMX.Types, objMouse32, objMouseDraw32, Collect,
               WpTwigs, EcLot, WptForm2;

const
  Lo_AddSegment = 407;

type
 TMouseSbor32 = class(TMousePainter)
  private
   FDialog: Boolean;        // открыт диалог подтверждения - мышь не обрабатывается
   FTwigs: TList<Integer>;  // em_NewPoly: отмеченные сегменты
   FAutoLot: TLot;          // em_NewPolyA: собранный контур
   FAutoClosed: Boolean;
   FTempLot: TLot;          // Lo_AddSegment: копия изменяемого контура
   FOldLot: TLot;           // Lo_AddSegment: изменяемый контур карты
   FMessage: String;        // причина, по которой контур не собран
   function NearestTwig(X, Y: Double): Integer;
   function PickLot(X, Y: Double): TLot;
   function BuildAutoLot(Start: Integer; Biggest: Boolean; out Closed: Boolean): TLot;
   procedure AutoSbor(X, Y: Double);
   procedure ToggleTwig(N: Integer);
   procedure ToggleTempTwig(N: Integer);
   procedure DrawLot(const Canvas: ISkCanvas; Lot: TLot; const Paint: ISkPaint);
   procedure CommitLot(Lot: TLot);
   procedure CommitNewPoly;
   procedure CommitAutoLot;
   procedure CommitAddSegment;
  // подтверждение: Yes - при согласии, No - при отказе или если обработчик уже
  // освобожден (не должен обращаться к обработчику)
   procedure Confirm(const Msg: String; Yes: TProc; No: TProc = nil);
   procedure SelectionChanged;
  public
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Function Hint: String; override;
 end;

// причина, по которой контур не собран (код TLot.SetFromTwig)
function IntToNoSborHint(V: Integer): String;

implementation uses System.Math, FMX.DialogService, maths_basic, EcDot, GBFWUndo, UndoColNew,
                    FramePropEditor, newResource, newSelector, drawTwigs32, Selector32,
                    objEditMap32, TwgColle, Writer;

var GActiveSbor: TMouseSbor32; // обработчик жив - для отложенного результата диалога

function IntToNoSborHint(V: Integer): String;
begin
 case V of
  -1: Result := 'Контур разомкнут';
  -2: Result := 'Удаленный сегмент';
  -3: Result := 'В сегменте меньше 2 точки';
  -4: Result := 'Контур без сегментов';
  -5: Result := 'Контур из 2-х точек';
  -6: Result := 'Нет точки внутри';
  -7: Result := 'Используется один сегмент';
  -8: Result := 'Самопересекающийся контур';
 else
  Result := 'Нет данных ' + IntToStr(V);
 end;
end;

// направление отрезка (X1,Y1)-(X2,Y2) в градусах 0..360 (ArcCat старой программы)
function DirDeg(X1, Y1, X2, Y2: Double): Double;
begin
 Result := Direct_Angle(X1, Y1, X2, Y2) * 180 / Pi;
 while Result < 0 do Result := Result + 360;
 while Result >= 360 do Result := Result - 360;
end;

// концы ветви и соседние с ними точки (у дуг - по аппроксимирующей ломаной)
procedure TwigEnds(T: TTwig; out B, BS, E, ES: TDot);
var AV: Byte;
begin
 AV := T.ArcView;
 T.ArcView := 1;
 try
  B := T.Coord[0];
  BS := T.Coord[1];
  E := T.Coord[T.Coord.Count - 1];
  ES := T.Coord[T.Coord.Count - 2];
 finally
  T.ArcView := AV;
 end;
end;

{ TMouseSbor32 }

constructor TMouseSbor32.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited Create(ATwigs, AFreeProc);
 FTwigs := TList<Integer>.Create;
 Twigs.ClearSelection;
 GActiveSbor := Self;
 WriteIn(['TMouseSbor32.Create LOperation=', LOperation]);
end;

destructor TMouseSbor32.Destroy;
begin
 if GActiveSbor = Self then GActiveSbor := nil;
 FTwigs.Free;
 FAutoLot.Free;
 FTempLot.Free;
 if (Selector <> nil) and Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 inherited Destroy;
end;

// ближайшая к (X,Y) ветвь в пределах допуска TwigTolerancePix: индекс или -1
function TMouseSbor32.NearestTwig(X, Y: Double): Integer;
var I: Integer;
    Tw: TTwig;
    R, D, MinD, X1, Y1: Double;
begin
 Result := -1;
 R := XGeoRasst(TwigTolerancePix(Twigs.Settings.psAutoDisst));
 MinD := R;
 for I := 1 to Twigs.Twigs.TwigsCount - 1 do begin
  Tw := Twigs.Twigs.TAt(I);
  if (Tw.Closed = 254) or (Tw.Coord.Count < 2) then continue;
 // габариты (могут быть не рассчитаны или с переставленными Y) - только отсев
  if (Tw.XMin < Tw.XMax) and ((X < Min(Tw.XMin, Tw.XMax) - R) or (X > Max(Tw.XMin, Tw.XMax) + R) or
     (Y < Min(Tw.YMin, Tw.YMax) - R) or (Y > Max(Tw.YMin, Tw.YMax) + R)) then continue;
  D := Tw.GetTwigDist(X, Y, X1, Y1);
  if D <= MinD then begin MinD := D; Result := I; end;
 end;
end;

// контур под точкой (TForm.GetLot): последний по порядку видимый
function TMouseSbor32.PickLot(X, Y: Double): TLot;
var J: Integer;
    L: TLot;
begin
 Result := nil;
 for J := Twigs.Twigs.LotsCount - 1 downto 0 do begin
  L := Twigs.Twigs.LAt(J);
  if L.TypeLot = 254 then continue;
  if (L.ClassHandle <> nil) and (L.ClassHandle.Check = 0) then continue;
  if L.PointIn(Twigs.Twigs, X, Y) then exit(L);
 end;
end;

// автосборка (TForm1.SetLot, Sbor/CreateLotView): от ветви Start по смежным
// ветвям с наименьшим (Biggest = True) или наибольшим углом поворота, пока
// конец не придет в начало; Closed - контур замкнулся
function TMouseSbor32.BuildAutoLot(Start: Integer; Biggest: Boolean; out Closed: Boolean): TLot;
var Lot: TLot;
    Used: TBits;
    B, BS, E, ES: TDot;
function NextTwig: Boolean;
var I, Best: Integer;
    T: TTwig;
    B1, BS1, E1, ES1: TDot;
    Dir1, A, BestA: Double;
    Rev, BestRev: Boolean;
begin
 Result := False;
 Best := -1;
 BestA := 0;
 BestRev := False;
 Dir1 := DirDeg(E.XDot, E.YDot, ES.XDot, ES.YDot);
 for I := 1 to Twigs.Twigs.TwigsCount - 1 do begin
  if Used[I] then continue;
  T := Twigs.Twigs.TAt(I);
  if (T.Closed <> 1) or (T.Opr = 254) or (T.Coord.Count < 2) then continue;
  if (T.ClassName = 'TTwigCircle') or (T.ClassName = 'TTwigEllipse') then continue;
  TwigEnds(T, B1, BS1, E1, ES1);
  if EqualPoints(E, B1) then begin A := DirDeg(B1.XDot, B1.YDot, BS1.XDot, BS1.YDot); Rev := False; end else
  if EqualPoints(E, E1) then begin A := DirDeg(E1.XDot, E1.YDot, ES1.XDot, ES1.YDot); Rev := True; end else continue;
  A := A - Dir1;
  if A < 0 then A := A + 360;
  if (Round(A * 100) = 0) or (Round(A * 100) = 36000) then continue;
  if (Best = -1) or (Biggest and (A < BestA)) or (not Biggest and (A > BestA)) then begin Best := I; BestA := A; BestRev := Rev; end;
 end;
 if Best = -1 then exit;
 Used[Best] := True;
 T := Twigs.Twigs.TAt(Best);
 TwigEnds(T, B1, BS1, E1, ES1);
// новый конец - противоположный конец добавленной ветви
 if BestRev then begin Lot.Insert(-Best); E := B1; ES := BS1; end else begin Lot.Insert(Best); E := E1; ES := ES1; end;
 if EqualPoints(E, B) then Closed := True else Result := True;
end;
var Twig: TTwig;
begin
 Closed := False;
 Twig := Twigs.Twigs.TAt(Start);
 Lot := TLot.Create(0.0, Twigs.LayerTable.ActiveLayer, Lot_AutoSbor);
 Lot.NLot := -10;
 Lot.Insert(Start);
 Result := Lot;
 TwigEnds(Twig, B, BS, E, ES);
 if EqualPoints(Twig.Coord[0], Twig.Coord[Twig.Coord.Count - 1]) then begin Closed := True; exit; end;
 Used := TBits.Create;
 try
  Used.Size := Twigs.Twigs.TwigsCount;
  Used[Start] := True;
  while NextTwig do;
 finally
  Used.Free;
 end;
 Lot.SetMinMax(Twigs.Twigs);
end;

// контур у точки щелчка: оба направления обхода, предпочтение - замкнутому,
// содержащему точку
procedure TMouseSbor32.AutoSbor(X, Y: Double);
var N, I, Code: Integer;
    Lot: array[0..1] of TLot;
    Closed: array[0..1] of Boolean;
    Ok: array[0..1] of Boolean;
    Best: Integer;
begin
 FreeAndNil(FAutoLot);
 FMessage := '';
 N := NearestTwig(X, Y);
 if N < 0 then begin FMessage := 'Сегмент не найден: укажите ближе к линии'; exit; end;
 for I := 0 to 1 do begin
  Lot[I] := BuildAutoLot(N, I = 0, Closed[I]);
  Lot[I].TypeLot := 2;
  Ok[I] := Closed[I] and (Lot[I].SetFromTwig(Twigs.Twigs) = 0);
 end;
 Best := 0;
 if Ok[0] and Lot[0].PointIn(Twigs.Twigs, X, Y) then Best := 0 else
 if Ok[1] and Lot[1].PointIn(Twigs.Twigs, X, Y) then Best := 1 else
 if not Ok[0] and Ok[1] then Best := 1;
 FAutoLot := Lot[Best];
 FAutoClosed := Ok[Best];
 Lot[1 - Best].Free;
 if not FAutoClosed then begin
  Code := FAutoLot.SetFromTwig(Twigs.Twigs);
  if Code = 0 then Code := -1;
  FMessage := 'Контур не собран. Причина -> ' + IntToNoSborHint(Code);
 end;
end;

procedure TMouseSbor32.ToggleTwig(N: Integer);
begin
 if N < 0 then exit;
 if FTwigs.IndexOf(N) >= 0 then FTwigs.Remove(N) else FTwigs.Add(N);
end;

// сегмент изменяемого контура: есть - снимается, нет - добавляется (AddTwig)
procedure TMouseSbor32.ToggleTempTwig(N: Integer);
var I: Integer;
begin
 if (N < 0) or (FTempLot = nil) then exit;
 for I := 0 to FTempLot.Coord.Count - 1 do
  if Abs(TLong(FTempLot.Coord[I]).Num) = N then begin
   FTempLot.Coord.AtFree(I);
   exit;
  end;
 FTempLot.Insert(N);
end;

procedure TMouseSbor32.Confirm(const Msg: String; Yes: TProc; No: TProc);
var S: TMouseSbor32;
begin
 S := Self;
 FDialog := True;
 LMouseDown := False;
 RMouseDown := False;
 TDialogService.MessageDialog(Msg, TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
  procedure(const AResult: TModalResult)
  begin
   if GActiveSbor <> S then begin
    if Assigned(No) then No;
    exit;
   end;
   FDialog := False;
   if AResult = mrYes then Yes else if Assigned(No) then No;
   SelectionChanged;
  end);
end;

// новый площадной объект Lot (владение переходит) в активном слое
procedure TMouseSbor32.CommitLot(Lot: TLot);
var Layer: TResource;
    I, N: Integer;
    Tw1, Tw2: TTwig;
procedure RemoveCopies;
var K: Integer;
begin
 if Twigs.Settings.psNoAssociativeFill then
  for K := 0 to Lot.Coord.Count - 1 do Twigs.Twigs.AtDelete(TWG_Twig, Twigs.Twigs.TwigsCount - 1);
end;
begin
 Layer := Twigs.LayerTable.ActiveLayer;
 if Layer = nil then begin Lot.Free; exit; end;
 Lot.ClassHandle := Layer;
 Lot.ClassCode := Layer.ID;
 Lot.TypeLot := 2;
 Lot.Selector := Selector;
 Lot.SetSqwear(Twigs.Twigs);
 Lot.Symbol := Twigs.LayerTable.ActiveSymbology;
// неассоциативная заливка: контур из копий сегментов
 if Twigs.Settings.psNoAssociativeFill then
  for I := 0 to Lot.Coord.Count - 1 do begin
   N := TLong(Lot.Coord[I]).Num;
   Tw1 := Twigs.Twigs.TAt(N);
   Tw2 := TTwigClass(Tw1.ClassType).CreateAsTwig(Tw1, True);
   Tw2.Calculate;
   Tw2.What := Twig_AutoCreate;
   Twigs.Twigs.Insert(TWG_Twig, Tw2);
   if N < 0 then TLong(Lot.Coord[I]).Num := -(Twigs.Twigs.TwigsCount - 1) else TLong(Lot.Coord[I]).Num := Twigs.Twigs.TwigsCount - 1;
  end;
 if Assigned(OnAddPrim) and not OnAddPrim(Lot) then begin
  RemoveCopies;
  Lot.Free;
  exit;
 end;
 if PropEditorForm <> nil then PropEditorForm.ApplyDefaults(Lot);
 Twigs.Twigs.Insert(TWG_LOT, Lot);
 Lot.SetFromTwig(Twigs.Twigs);
 Lot.SetMinMax(Twigs.Twigs);
 TPrimUndo(Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'Undo.AddNewPrim...em_New...'))).AddModifiedPrim(Lot);
 Twigs.ClassBuildII;
 Modified;
 Selector.UpdateImage(usmAdd, Lot);
end;

// em_NewPoly: контур из отмеченных сегментов; не собран - подтверждение
procedure TMouseSbor32.CommitNewPoly;
var Lot: TLot;
    Layer: TResource;
    I, Code: Integer;
begin
 Layer := Twigs.LayerTable.ActiveLayer;
 if (Layer = nil) or (FTwigs.Count = 0) then exit;
 Lot := TLot.Create(Layer.ID, Layer, 1);
 for I := 0 to FTwigs.Count - 1 do Lot.Insert(FTwigs[I]);
 Code := Lot.SetFromTwig(Twigs.Twigs);
 if Code = 0 then begin
  FTwigs.Clear;
  CommitLot(Lot);
  exit;
 end;
 Confirm('Контур не собран. Причина -> ' + IntToNoSborHint(Code) + ' Продолжить?',
  procedure
  begin
   FTwigs.Clear;
   CommitLot(Lot);
  end,
  procedure
  begin
   Lot.Free;
  end);
end;

// em_NewPolyA: собранный контур; не замкнут - подтверждение
procedure TMouseSbor32.CommitAutoLot;
var Lot: TLot;
begin
 if FAutoLot = nil then exit;
 if FAutoClosed then begin
  Lot := FAutoLot;
  FAutoLot := nil;
  CommitLot(Lot);
  exit;
 end;
 Confirm(FMessage + ' Продолжить?',
  procedure
  var L: TLot;
  begin
   L := FAutoLot;
   FAutoLot := nil;
   if L <> nil then CommitLot(L);
  end);
end;

// Lo_AddSegment: сегменты изменяемого контура записываются в контур карты
procedure TMouseSbor32.CommitAddSegment;
var Coord: PCollection;
begin
 if (FTempLot = nil) or (FOldLot = nil) then exit;
 if (FTempLot.TypeLot = 2) and (FTempLot.SetFromTwig(Twigs.Twigs) <> 0) then begin
  TDialogService.ShowMessage('Контур не замкнут. Укажите замкнутую фигуру!');
  RMouseDown := False;
  exit;
 end;
 Coord := FOldLot.Coord;
 TPrimUndo(Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_ModifiedPrim, 'UndoModifiedLot...Lo_AddSegment'))).AddModifiedPrim(FOldLot);
 FOldLot.Coord := FTempLot.Coord;
 if Assigned(OnModifiedPrim) and not OnModifiedPrim(FOldLot) then begin
  FOldLot.Coord := Coord;
  Undo.LastFree;
  SelectionChanged;
  exit;
 end;
 FTempLot.Coord := PCollection.Create(1);
 Coord.Free;
 FOldLot.SetFromTwig(Twigs.Twigs);
 FOldLot.SetMinMax(Twigs.Twigs);
 if FOldLot.TypeLot = 2 then FOldLot.SetSqwear(Twigs.Twigs);
 Twigs.ClassBuildII;
 Modified;
 Selector.UpdateImage(usmModify, FOldLot);
 FreeAndNil(FTempLot);
 FOldLot := nil;
end;

procedure TMouseSbor32.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var L: TLot;
begin
 Hook := True;
 if FDialog then exit;
 inherited MouseDown(Form, Button, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if Button <> TMouseButton.mbLeft then exit;
 Hook := True;
 case LOperation of
  em_NewPoly: ToggleTwig(NearestTwig(X, Y));
  em_NewPolyA: AutoSbor(X, Y);
  Lo_AddSegment: if FTempLot = nil then begin
    L := PickLot(X, Y);
    if L <> nil then begin
     FOldLot := L;
     FTempLot := TLotClass(L.ClassType).CreateAsLotWithAll(L);
    end;
   end else ToggleTempTwig(NearestTwig(X, Y));
 end;
// отладка: операция, сегменты и контур после щелчка
 WriteIn(['TMouseSbor32.MouseDown op=', LOperation, ' X=', X, ' Y=', Y, ' twig=', NearestTwig(X, Y), ' marked=', FTwigs.Count,
          ' auto=', FAutoLot <> nil, ' temp=', FTempLot <> nil]);
 SelectionChanged;
end;

procedure TMouseSbor32.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited MouseRightDown(Form, Button, Shift, X, Y, Hook);
 Hook := False;
 if FDialog or ShiftPress or ControlPress then exit;
 Hook := True;
 RMouseDown := False;
 case LOperation of
  em_NewPoly: CommitNewPoly;
  em_NewPolyA: CommitAutoLot;
  Lo_AddSegment: CommitAddSegment;
 end;
 SelectionChanged;
end;

procedure TMouseSbor32.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FDialog then exit;
 inherited MouseUp(Form, Button, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then Hook := False;
end;

procedure TMouseSbor32.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FDialog then exit;
 inherited MouseMove(Form, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then Hook := False;
end;

procedure TMouseSbor32.DrawLot(const Canvas: ISkCanvas; Lot: TLot; const Paint: ISkPaint);
var K: Integer;
begin
 if Lot = nil then exit;
 for K := 0 to Lot.Coord.Count - 1 do SkDrawTwig(Canvas, Lot.GetTwig(Twigs.Twigs, K), Paint);
end;

// выбранные сегменты меняются - статический слой пересобирается
procedure TMouseSbor32.SelectionChanged;
begin
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 UpdateImage;
end;

// выбранные сегменты - в статическом слое: он накладывается на сцену обычным
// образом, цвет Lime как есть (на live-слое Difference меняет цвет по фону)
procedure TMouseSbor32.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var Paint: ISkPaint;
    I: Integer;
begin
 inherited;
 if Canvas = nil then exit;
 Paint := SkPen(Canvas, TAlphaColorRec.Lime, 3, False);
 case LOperation of
  em_NewPoly: for I := 0 to FTwigs.Count - 1 do SkDrawTwig(Canvas, Twigs.Twigs.TAt(FTwigs[I]), Paint);
  em_NewPolyA: DrawLot(Canvas, FAutoLot, Paint);
  Lo_AddSegment: DrawLot(Canvas, FTempLot, Paint);
 end;
end;

function TMouseSbor32.Hint: String;
begin
 case LOperation of
  em_NewPoly: Result := 'Площадной объект: укажите сегменты (' + IntToStr(FTwigs.Count) + '), правая кнопка - создать';
  em_NewPolyA: if FMessage <> '' then Result := FMessage else
   if FAutoLot <> nil then Result := 'Контур собран, правая кнопка - создать' else Result := 'Автосборка: укажите сегмент контура';
  Lo_AddSegment: if FTempLot = nil then Result := 'Изменение контура: укажите контур' else
   Result := 'Изменение контура: укажите сегменты, правая кнопка - записать';
 else
  Result := inherited Hint;
 end;
end;

initialization
 AddMouseHook(TMouseSbor32);
end.
