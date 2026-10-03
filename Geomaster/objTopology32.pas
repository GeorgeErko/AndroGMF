unit objTopology32;

// Перенос части модуля objTopology из Geomaster (Delphi 7, GDI): операции
// с линейными условными знаками из панели линейных знаков (instLineSign,
// кнопки по Tag):
//  topo_RotateTwig (603) - переворот линии с условным обозначением: щелчок по
//                          линии - выбрать/снять выбор, правая кнопка -
//                          перевернуть выбранные линии;
//  topo_MoveOnTwig (604) - перемещение условного обозначения вдоль линии:
//                          левая кнопка нажата на линии, движение, отпускание.
// Обработчики только меняют состояние, выбранные линии рисуются в DrawTemp.
// Не перенесено: висячие узлы (topo_notLink), перехлесты (topo_Perehlest),
// мелкие отрезки (topo_minOtr), sbClock (проверка обхода контуров).

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     System.Generics.Collections, FMX.Types, objMouse32, objMouseSelect32,
     objMouseDraw32, drawTwigs32, Collect, EcDot, EcLot, WpTwigs, WptForm2;

const
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
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  //
   Function FindTwig(var X, Y: Double): TTwig;
   Procedure RotateTwigs;
   Procedure UpdateTwigs(const Tws: array of TTwig);
   Procedure EndMove(Cancel: Boolean);
 end;

implementation

uses GBFWUndo, UndoColNew, newSelector, TwgColle, Writer, Selector32;

{ TMouseTopology }

constructor TMouseTopology.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 ActiveTwigs := TList<TTwig>.Create;
end;

destructor TMouseTopology.Destroy;
begin
// перемещение знака не закончено - вернуть смещение и отменить запись в Undo
 if MoveTwig <> nil then EndMove(True);
 ActiveTwigs.Free;
 inherited;
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

procedure TMouseTopology.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Tw: TTwig;
begin
 Hook := True;
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
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
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
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
 inherited;
 if ShiftPress or ControlPress or (MoveTwig <> nil) then begin Hook := False; exit; end;
 case LOperation of
  topo_RotateTwig: begin
    RotateTwigs;
    UpdateImage;
   end;
 end;
end;

end.
