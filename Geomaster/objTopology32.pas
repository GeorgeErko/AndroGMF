unit objTopology32;

// Перенос части модуля objTopology из Geomaster (Delphi 7, GDI): операции
// с линейными условными знаками из панели линейных знаков (instLineSign,
// кнопки по Tag):
//  topo_RotateTwig (603) - переворот линии с условным обозначением: щелчок по
//                          линии - выбрать/снять выбор, правая кнопка -
//                          перевернуть выбранные линии;
//  topo_MoveOnTwig (604) - перемещение условного обозначения вдоль линии:
//                          левая кнопка нажата на линии, движение, отпускание;
//  topo_Perehlest (601)  - перехлесты сегментов (кнопка RbPere1 FlyBti, панель
//                          pnlLeft): при запуске - поиск в окне (вместо формы
//                          instPerehlest), щелчок у перехлеста - разорвать
//                          сегменты (или убрать перехлест из списка), правая
//                          кнопка - исправить все (нет перехлестов - искать
//                          снова). Перехлесты рисуются в статическом слое.
// Обработчики только меняют состояние, выбранные линии рисуются в DrawTemp.
// Не перенесено: висячие узлы (topo_notLink), мелкие отрезки (topo_minOtr),
// sbClock (проверка обхода контуров).

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     System.Generics.Collections, FMX.Types, objMouse32, objMouseSelect32,
     objMouseDraw32, drawTwigs32, Collect, EcDot, EcLot, WpTwigs, WptForm2;

const
  topo_Perehlest = 601;
  topo_RotateTwig = 603;
  topo_MoveOnTwig = 604;

type
 TMouseTopology = class(TMousePainter)
  public
   HotTwig: TTwig;              // линия под курсором
   ActiveTwigs: TList<TTwig>;   // выбранные для переворота линии
   MoveTwig: TTwig;             // линия, знак которой перемещается
   X1, Y1: Double;              // точка начала перемещения
   OldZDx: Single;              // смещение знака до перемещения
   FPere: Boolean;              // операция topo_Perehlest (LOperation к деструктору уже другая)
   FDialog: Boolean;            // открыт диалог подтверждения - мышь не обрабатывается
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Function Hint: String; override;
  //
   Function FindTwig(var X, Y: Double): TTwig;
  // перехлесты
   Procedure CollectPerehlests;
   Procedure PereChanged;
   Procedure PereModified;
   Procedure EditPerehlest(X, Y: Double);
   Procedure ModifyPerehlests;
   Procedure Confirm(const Msg: String; Yes: TProc; No: TProc = nil);
   Procedure RotateTwigs;
   Procedure UpdateTwigs(const Tws: array of TTwig);
   Procedure EndMove(Cancel: Boolean);
 end;

implementation

uses FMX.DialogService, GBFWUndo, UndoColNew, newSelector, TwgColle, notLink_, Writer, Selector32;

var GActiveTopology: TMouseTopology; // обработчик жив - для отложенного результата диалога

{ TMouseTopology }

constructor TMouseTopology.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 ActiveTwigs := TList<TTwig>.Create;
 GActiveTopology := Self;
 FPere := LOperation = topo_Perehlest;
 if FPere then CollectPerehlests;
end;

destructor TMouseTopology.Destroy;
begin
 if GActiveTopology = Self then GActiveTopology := nil;
// перемещение знака не закончено - вернуть смещение и отменить запись в Undo
 if MoveTwig <> nil then EndMove(True);
 ActiveTwigs.Free;
 if FPere then begin
  Twigs.newClearPerehlests;
  if (Selector <> nil) and Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 end;
 inherited;
end;

// поиск перехлестов в окне (CollectPerehlest старой программы)
procedure TMouseTopology.CollectPerehlests;
begin
 Twigs.newCollectPerehlests;
 PereChanged;
end;

// список перехлестов изменился - статический слой пересобирается
procedure TMouseTopology.PereChanged;
begin
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 UpdateImage;
end;

// сегменты разорваны: упаковка (Closed = 254 - разрезанные окружности) и сцена
procedure TMouseTopology.PereModified;
begin
 Twigs.newResetOpr;
 Twigs.ClassBuildII;
 Twigs.Pack(nil);
 Modified;
 Selector.UpdateImage(usmModify, nil);
end;

procedure TMouseTopology.Confirm(const Msg: String; Yes: TProc; No: TProc);
var T: TMouseTopology;
begin
 T := Self;
 FDialog := True;
 LMouseDown := False;
 RMouseDown := False;
 TDialogService.MessageDialog(Msg, TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
  procedure(const AResult: TModalResult)
  begin
   if GActiveTopology <> T then exit;
   FDialog := False;
   if AResult = mrYes then Yes else if Assigned(No) then No;
   PereChanged;
  end);
end;

// щелчок у перехлеста: разорвать сегменты или убрать перехлест из списка
procedure TMouseTopology.EditPerehlest(X, Y: Double);
var R: Double;
begin
 R := Selector.XGeoRasst(TwigTolerancePix(Twigs.Settings.psAutoDisst));
 if Twigs.newFindPereTwig(X, Y, R) > 0 then
  Confirm('Разорвать сегменты?',
   procedure
   begin
    Twigs.newEditPerehlests;
    PereModified;
   end,
   procedure
   begin
    Twigs.newDeletePerehlest;
   end)
 else begin
 // у перехлеста не осталось сегментов для разрыва
  Twigs.newDeletePerehlest;
  PereChanged;
 end;
end;

// правая кнопка: исправить все перехлесты; нет перехлестов - искать снова
procedure TMouseTopology.ModifyPerehlests;
begin
 if Twigs.Perehlests.Count = 0 then begin
  CollectPerehlests;
  exit;
 end;
 Confirm('Исправить ' + IntToStr(Twigs.Perehlests.Count) + ' перехлестов?',
  procedure
  var Err: String;
  begin
   Err := Twigs.newModifyPerehlests;
   PereModified;
   if Err <> '' then TDialogService.ShowMessage(Err);
   Twigs.newCollectPerehlests;
  end);
end;

// линия под курсором (в старой программе - TForm2.FindTwig); дуги не
// переворачиваются и не несут знаков (TTwigARC.isAccessibleTwig)
function TMouseTopology.FindTwig(var X, Y: Double): TTwig;
begin
 Result := nil;
 emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
 if (objTemporary is TTwig) and not (objTemporary is TTwigARC) then Result := TTwig(objTemporary);
end;

// ветви изменены: ветвь не самостоятельный примитив сцены (нет DrawerObject) -
// контуры, в которые входят ветви Tws, помечаются измененными (картинка
// контура перезаписывается) и сцена перерисовывается
procedure TMouseTopology.UpdateTwigs(const Tws: array of TTwig);
var I, J, K: Integer;
    Lot: TLot;
    Tw: TTwig;
begin
 for I := 0 to Twigs.Twigs.LotsCount - 1 do begin
  Lot := Twigs.Twigs.LAt(I);
  for K := 0 to Lot.Coord.Count - 1 do begin
   Tw := Lot.GetTwig(Twigs.Twigs, K);
   for J := 0 to High(Tws) do
    if Tws[J] = Tw then begin
     Lot.Modified := True;
     break;
    end;
   if Lot.Modified then break;
  end;
 end;
 Selector.UpdateImage;
end;

// переворот выбранных линий (TForm1.RotateTwig старой программы): в контурах
// ссылки на ветку меняют знак, чтобы контур не изменился
procedure TMouseTopology.RotateTwigs;
var I, K: Integer;
    Lot: TLot;
    TwigCol, LotCol: PCollection;
begin
 if ActiveTwigs.Count = 0 then exit;
 TwigCol := PCollection.Create(1);
 LotCol := PCollection.Create(1);
 try
  for I := 0 to ActiveTwigs.Count - 1 do TwigCol.Insert(ActiveTwigs[I]);
  Undo.StartTransAction;
  try
   Twigs.ModifiedTwigsUndo(TwigCol, LotCol);
   for I := 0 to LotCol.Count - 1 do begin
    Lot := LotCol[I];
    if Lot.Coord.Count > 1 then
     for K := 0 to Lot.Coord.Count - 1 do
      if ActiveTwigs.IndexOf(Lot.GetTwig(Twigs.Twigs, K)) <> -1 then TLong(Lot.Coord[K]).Num := -TLong(Lot.Coord[K]).Num;
   end;
   for I := 0 to ActiveTwigs.Count - 1 do begin
    ActiveTwigs[I].Rotation;
    ActiveTwigs[I].Inv := 0;
   end;
   Undo.Commit;
   Modified;
  except
   on E: Exception do begin
    WriteIn(['RotateTwigs exception ', E.Message]);
    Undo.RollBack;
   end;
  end;
  UpdateTwigs(ActiveTwigs.ToArray);
 finally
  TwigCol.DeleteAll;
  TwigCol.Free;
  LotCol.DeleteAll;
  LotCol.Free;
 end;
 ActiveTwigs.Clear;
end;

// конец перемещения знака: Cancel или отказ OnModifiedPrim - вернуть смещение
procedure TMouseTopology.EndMove(Cancel: Boolean);
begin
 if MoveTwig = nil then exit;
 if not Cancel and Assigned(OnModifiedPrim) and not OnModifiedPrim(MoveTwig) then Cancel := True;
 if Cancel then begin
  MoveTwig.ZDx := OldZDx;
  Undo.RollBack;
 end else begin
  Undo.Commit;
  Modified;
 end;
 UpdateTwigs([MoveTwig]);
 MoveTwig := nil;
end;

procedure TMouseTopology.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var I: Integer;
    Pen: ISkPaint;
begin
 inherited;
 if Canvas = nil then exit;
 Pen := SkPen(Canvas, TAlphaColorRec.White, 3, False);
 for I := 0 to ActiveTwigs.Count - 1 do SkDrawTwig(Canvas, ActiveTwigs[I], Pen);
 Pen := SkPen(Canvas, TAlphaColorRec.White, 1, True);
 if (HotTwig <> nil) and (MoveTwig = nil) then SkDrawTwig(Canvas, HotTwig, Pen);
end;

// перехлесты в окне - голубыми кружками (ShowPerehlests старой программы);
// статический слой накладывается на сцену обычным образом - цвет как есть
procedure TMouseTopology.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var I: Integer;
    W: TWorkPere;
    Pen: ISkPaint;
    R: Single;
    G: TSect;
begin
 inherited;
 if (Canvas = nil) or not FPere then exit;
 Pen := SkPen(Canvas, TAlphaColorRec.Cyan, 2, False);
 R := SkPixToWorld(Canvas, 6);
 G := GRect;
 for I := 0 to Twigs.Perehlests.Count - 1 do begin
  W := Twigs.Perehlests[I];
  if (W.X > G.Left) and (W.X < G.Right) and (W.Y < G.Top) and (W.Y > G.Bottom) then Canvas.DrawCircle(W.X, W.Y, R, Pen);
 end;
end;

function TMouseTopology.Hint: String;
begin
 if not FPere then begin Result := inherited Hint; exit; end;
 if Twigs.Perehlests.Count = 0 then Result := 'В данном окне не найдено перехлестов; правая кнопка - искать снова' else
  Result := 'Перехлестов: ' + IntToStr(Twigs.Perehlests.Count) + '; щелчок у перехлеста - разорвать, правая кнопка - исправить все';
end;

procedure TMouseTopology.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Tw: TTwig;
begin
 Hook := True;
 if FDialog then exit;
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
 if FPere then begin
  EditPerehlest(X, Y);
  exit;
 end;
 Tw := FindTwig(X, Y);
 if Tw = nil then exit;
 case LOperation of
 // щелчок по линии - выбрать/снять выбор
  topo_RotateTwig: begin
    if ActiveTwigs.IndexOf(Tw) = -1 then ActiveTwigs.Add(Tw) else ActiveTwigs.Remove(Tw);
    UpdateImage;
   end;
 // линия с условным обозначением - начало перемещения знака
  topo_MoveOnTwig:
   if Tw.UZnak <> -1 then begin
    Undo.StartTransAction;
    Twigs.ModifiedTwigsUndo(nil, nil, Tw);
    MoveTwig := Tw;
    OldZDx := Tw.ZDx;
    X1 := X;
    Y1 := Y;
    UpdateImage;
   end;
 end;
end;

procedure TMouseTopology.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FDialog then exit;
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if FPere then exit;
// знак сдвигается на расстояние вдоль линии от точки нажатия
 if MoveTwig <> nil then begin
  emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
  MoveTwig.ZDx := OldZDx + MoveTwig.GetLineDistance(X1, Y1, X, Y);
  UpdateTwigs([MoveTwig]);
  exit;
 end;
 HotTwig := FindTwig(X, Y);
 if (LOperation = topo_MoveOnTwig) and (HotTwig <> nil) and (HotTwig.UZnak = -1) then HotTwig := nil;
 UpdateImage;
end;

procedure TMouseTopology.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FDialog then exit;
 inherited;
 if ShiftPress or ControlPress or (Button = TMouseButton.mbRight) then begin Hook := False; exit; end;
 if MoveTwig <> nil then begin
  EndMove(False);
  UpdateImage;
 end;
end;

procedure TMouseTopology.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FDialog then exit;
 inherited;
 if ShiftPress or ControlPress or (MoveTwig <> nil) then begin Hook := False; exit; end;
 if FPere then begin
  RMouseDown := False;
  ModifyPerehlests;
  exit;
 end;
 case LOperation of
  topo_RotateTwig: begin
    RotateTwigs;
    UpdateImage;
   end;
 end;
end;

end.
