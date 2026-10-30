unit objDataZnk32;

// Перенос модуля objDataZnk из Geomaster (Delphi 7, GDI), только операция
// Lo_TextZnak (2001, кнопка rsResetZnak2 «Изменение текста подписи» -
// TMasterDendro.sbNumClick, кнопка sbNum ОЗН): знак под курсором
// подсвечивается, щелчок - диалог атрибутов знака (TTextManager.SetTexts2,
// VarSetForm1 = 1): деревья/кустарники - TVarSetDlg1, газоны - TVarSetDlg2,
// цветники - TVarSetDlg3 (по атрибуту '*Тип (ОГХ)'), изменение с отменой.
// Знак ищется так же, как в TMouseTopo (mp_RotateP): emGetDotMarker.
// Диалог не блокирует обработчик (на Android синхронного ShowModal нет):
// изменение записывается в обработчике результата.
// Операция Lo_MoveText (931, кнопка ResSpeedBtn6 FlyDataZnk «Быстрое
// перемещение/масштабирование/поворот надписи», панель pnlLeft): у видимых
// надписей (TDotText) - контур и маркеры: кружок (угол Bounds[1]) - поворот
// вокруг точки надписи, квадрат (угол Bounds[2]) - масштаб (высота шрифта),
// внутри контура - перемещение. Нажатие - захват, движение - контур
// надписи (DrawTemp), отпускание - запись с отменой (LU_ModifiedPrim).
// Та же операция - атрибуты точечных знаков (Lo_MoveDataFont, кнопка rsMoveFont
// FlyDataZnk): контур и маркеры каждой подписи TextManager, смещение, угол и
// размер - в TTextParams.
// Не перенесено: остальные операции TDataZnkSet (Lo_AddDataZnk, промеры),
// связь с сервером (dendroModifiedPrim).

interface uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
               FMX.Types, objMouse32, objMouseDraw32, Collect, EcDot, EcDot2, GBFWUndo, TwgBitmaps, WptForm2;

const
  Lo_MoveText = 931;
  Lo_TextZnak = 2001;

type
// признак жизни обработчика для отложенного результата диалога атрибутов
 IDataZnkAlive = interface
  ['{3E7A51C2-8B4D-4F19-A6E0-2C9D7B15F842}']
  function Alive: Boolean;
  procedure Kill;
 end;

 TDataZnkSet = class(TMousePainter)
  private
   FAlive: IDataZnkAlive;
   FTextsDialog: Boolean; // открыт диалог атрибутов - мышь не обрабатывается
  // Lo_MoveText: захваченная надпись или знак с подписью FMoveAttr (-1 - надпись
  // TDotText), что меняется (0 - поворот, 1 - масштаб, 2 - перемещение), центр
  // поворота и масштаба, предыдущая точка курсора, накопленное преобразование и
  // контур до него
   FMoveDot: TPointDot;
   FMoveAttr: Integer;
   FMoveFlag: Integer;
   FPivotX, FPivotY: Double;
   FPrevX, FPrevY: Double;
   FDx, FDy, FDA, FK: Double;
   FBX, FBY: array[0..3] of Double;
   FPrimUndo: TPrimUndo;
   function TextMarker(Bmp: TTwgBitmap; X, Y, R: Double): Integer;
   function GrabText(PD: TPointDot; Attr: Integer; Bmp: TTwgBitmap; X, Y, R: Double): Boolean;
   procedure MovePoint(var X, Y: Double);
   procedure DrawTextMarkers(const Canvas: ISkCanvas);
   procedure ApplyAttrMove(PD: TPointDot);
   procedure EndMoveText;
  public
   VarSetForm1: Byte;     // 0 - TVarSetDlg; 1 - форма по виду насаждения
   PrevActiveDot: TPointDot; // знак под курсором
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  //
   Procedure DrawActiveDot(const Canvas: ISkCanvas);
   Function SetDialogClass(PD: TPointDot): Boolean;
   Procedure EditTexts(PD: TPointDot);
  // снятие выделения: подсветка знака под курсором и выделенные примитивы формы
   Procedure ClearSelected;
   Function Hint: String; override;
 end;

implementation uses FMX.DialogService, UndoColNew, newSelector, newClassBuilder,
                    TextManager, ogcDrawerSkia, VarSetForm, VarSetForm1, VarSetForm2,
                    VarSetForm3, Selector32, TwgColle, ogcBasic, Maths_Basic, drawTwigs32, newConsts;

type
 TDataZnkAlive = class(TInterfacedObject, IDataZnkAlive)
  private
   FAlive: Boolean;
  public
   constructor Create;
   function Alive: Boolean;
   procedure Kill;
 end;

constructor TDataZnkAlive.Create;
begin
 inherited Create;
 FAlive := True;
end;

function TDataZnkAlive.Alive: Boolean;
begin
 Result := FAlive;
end;

procedure TDataZnkAlive.Kill;
begin
 FAlive := False;
end;

{ TDataZnkSet }

constructor TDataZnkSet.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 FAlive := TDataZnkAlive.Create;
 VarSetForm1 := 1;
end;

destructor TDataZnkSet.Destroy;
begin
// результат открытого диалога атрибутов придет уже без обработчика
 if FAlive <> nil then FAlive.Kill;
// перемещение надписи не закончено - копия для отмены не нужна
 FPrimUndo.Free;
 inherited;
end;

// маркер контура Bmp под точкой (X,Y) с допуском R: 0 - поворот (Bounds[1]),
// 1 - масштаб (Bounds[2]), 2 - внутри контура, 10000 - мимо (GetMarker
// старой программы); без рассчитанного контура - мимо
function TDataZnkSet.TextMarker(Bmp: TTwgBitmap; X, Y, R: Double): Integer;
var B: PCollection;
function Near(I: Integer): Boolean;
begin
 Result := Distance(TogsDot(B[I]).X, TogsDot(B[I]).Y, X, Y) <= R;
end;
begin
 Result := 10000;
 if (Bmp = nil) or (Bmp.Bounds = nil) or (Bmp.Bounds.Count < 4) then exit;
 if not Bmp.PointInSect(X, Y, R) then exit;
 B := Bmp.Bounds;
 if Near(1) then Result := 0 else
 if Near(2) then Result := 1 else
 if Bmp.PointInB(X, Y) then Result := 2;
end;

// захват надписи (Attr = -1) или подписи Attr знака PD, если (X,Y) на контуре Bmp;
// центр: у надписи - ее точка, у подписи - точка привязки (XFOld в TDWG_Text.GetParams)
function TDataZnkSet.GrabText(PD: TPointDot; Attr: Integer; Bmp: TTwgBitmap; X, Y, R: Double): Boolean;
var K: Integer;
    TP: TTextParams;
    RX, RY: Double;
begin
 FMoveFlag := TextMarker(Bmp, X, Y, R);
 Result := FMoveFlag <> 10000;
 if not Result then exit;
 FMoveDot := PD;
 FMoveAttr := Attr;
 for K := 0 to 3 do begin
  FBX[K] := TogsDot(Bmp.Bounds[K]).X;
  FBY[K] := TogsDot(Bmp.Bounds[K]).Y;
 end;
 if Attr = -1 then begin
  FPivotX := PD.XDot;
  FPivotY := PD.YDot;
 end else begin
 // размер подписи, еще не заданный (FH = -1), берется из знака
  PD.TextManager.UpdateText;
  PD.TextManager.Restore;
  TP := PD.TextManager.FValues[Attr];
  if (PD.Koef > 0) or (TP.ShiftX = 0) then begin
   RX := RealScaleLength(Selector.Drawer, TP.FDx, PD.Koef);
   RY := RealScaleLength(Selector.Drawer, TP.FDy, PD.Koef);
  end else begin
   RX := RealScaleLength(Selector.Drawer, TP.ShiftX, 0);
   RY := RealScaleLength(Selector.Drawer, TP.ShiftY, 0);
  end;
  FPivotX := PD.XDot + RX * Cos(PD.Ugol) - RY * Sin(PD.Ugol);
  FPivotY := PD.YDot + RX * Sin(PD.Ugol) + RY * Cos(PD.Ugol);
 end;
 FPrevX := X;
 FPrevY := Y;
 FDx := 0;
 FDy := 0;
 FDA := 0;
 FK := 1;
 FPrimUndo := TPrimUndo.Create(Twigs, LU_ModifiedPrim, 'UndoMoveText...Lo_MoveText');
 FPrimUndo.AddModifiedPrim(PD);
end;

// точка контура захваченной надписи после накопленного преобразования:
// поворот на FDA и масштаб FK вокруг центра, сдвиг (FDx, FDy)
procedure TDataZnkSet.MovePoint(var X, Y: Double);
var C, S, DX, DY: Double;
begin
 C := Cos(FDA);
 S := Sin(FDA);
 DX := X - FPivotX;
 DY := Y - FPivotY;
 X := FPivotX + FK * (DX * C - DY * S) + FDx;
 Y := FPivotY + FK * (DX * S + DY * C) + FDy;
end;

// контуры и маркеры надписей: захваченная - контур после преобразования,
// иначе - все видимые надписи и подписи знаков окна (белым: live-слой, Difference)
procedure TDataZnkSet.DrawTextMarkers(const Canvas: ISkCanvas);
var I, J, K: Integer;
    B: Byte;
    PD: TPointDot;
    Pen: ISkPaint;
    R: Single;
    G: TSect;
    X, Y: array[0..3] of Double;
procedure DrawBox;
var Builder: ISkPathBuilder;
    N: Integer;
begin
 Builder := TSkPathBuilder.Create;
 for N := 0 to 3 do if N = 0 then Builder.MoveTo(X[N], Y[N]) else Builder.LineTo(X[N], Y[N]);
 Builder.Close;
 Canvas.DrawPath(Builder.Detach, Pen);
 Canvas.DrawCircle(X[1], Y[1], R, Pen);
 Canvas.DrawRect(TRectF.Create(X[2] - R, Y[2] - R, X[2] + R, Y[2] + R), Pen);
end;
procedure DrawBitmap(Bmp: TTwgBitmap);
var N: Integer;
begin
 if (Bmp = nil) or (Bmp.Bounds = nil) or (Bmp.Bounds.Count < 4) or not Bmp.SectVisible(G) then exit;
 for N := 0 to 3 do begin
  X[N] := TogsDot(Bmp.Bounds[N]).X;
  Y[N] := TogsDot(Bmp.Bounds[N]).Y;
 end;
 DrawBox;
end;
begin
 Pen := SkPen(Canvas, TAlphaColorRec.White, 1, False);
 R := SkPixToWorld(Canvas, 5);
 if FMoveDot <> nil then begin
  for K := 0 to 3 do begin
   X[K] := FBX[K];
   Y[K] := FBY[K];
   MovePoint(X[K], Y[K]);
  end;
  DrawBox;
  exit;
 end;
 G := GRect;
 for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if not (TObject(PD) is TPointDot) or not PD.isNoClosed then continue;
  if PD is TDotText then DrawBitmap(TDotText(PD).TextBitmap) else
  if (PD.TextManager <> nil) and (PD.userObj = nil) then
   for J := 0 to PD.TextManager.FTextBitmaps.Count - 1 do DrawBitmap(PD.TextManager.FTextBitmaps[J]);
 end;
end;

// смещение, угол и размер подписи FMoveAttr (MouseMove Lo_MoveDataFont старой
// программы): смещение мира - в систему знака (поворот на -Ugol); Koef > 0 -
// в единицах знака, иначе - в пикселях (ShiftX, ShiftY: знак постоянного размера)
procedure TDataZnkSet.ApplyAttrMove(PD: TPointDot);
var TP: TTextParams;
    U, DX, DY, K: Double;
begin
 TP := PD.TextManager.FValues[FMoveAttr];
 U := 2 * Pi - PD.Ugol;
 DX := FDx * Cos(U) - FDy * Sin(U);
 DY := FDx * Sin(U) + FDy * Cos(U);
 if PD.Koef > 0 then begin
  TP.FDx := TP.FDx + DX / PD.Koef;
  TP.FDy := TP.FDy + DY / PD.Koef;
 end else begin
  K := Abs(PD.Koef) * Selector.DevScale;
  if K = 0 then K := 1;
  if TP.ShiftX = 0 then begin
   TP.ShiftX := Round(TP.FDx * K);
   TP.ShiftY := Round(TP.FDy * K);
  end;
  TP.ShiftX := TP.ShiftX + Selector.XRasst(DX);
  TP.ShiftY := TP.ShiftY + Selector.YRasst(DY);
 end;
// угол подписи откладывается против угла знака (Ugol - FUgol)
 TP.FUgol := TP.FUgol - FDA * 180 / Pi;
 TP.FH := TP.FH * FK;
 TP.FW := TP.FW * FK;
end;

// конец перемещения надписи: изменение - в надпись или подпись и в Undo; без
// изменения или отказ OnModifiedPrim - копия для отмены не нужна
procedure TDataZnkSet.EndMoveText;
var PD: TPointDot;
    Attr: Integer;
    TP, Old: TTextParams;
    OldX, OldY: Double;
    OldUgol, OldHeight: Single;
begin
 PD := FMoveDot;
 Attr := FMoveAttr;
 FMoveDot := nil;
 if PD = nil then exit;
 if (FDx = 0) and (FDy = 0) and (FDA = 0) and (FK = 1) then begin
  FreeAndNil(FPrimUndo);
  UpdateImage;
  exit;
 end;
 if Attr <> -1 then begin
  TP := PD.TextManager.FValues[Attr];
  Old := TTextParams.Create(TP.FValue, TP.FDx, TP.FDy, TP.FUgol, TP.FH, TP.FW, TP.FAttr, TP.AlignX, TP.AlignY, TP.ShiftX, TP.ShiftY, TP.FBg);
  try
   ApplyAttrMove(PD);
   if Assigned(OnModifiedPrim) and not OnModifiedPrim(PD) then begin
    TP.FDx := Old.FDx;
    TP.FDy := Old.FDy;
    TP.FUgol := Old.FUgol;
    TP.FH := Old.FH;
    TP.FW := Old.FW;
    TP.ShiftX := Old.ShiftX;
    TP.ShiftY := Old.ShiftY;
    FreeAndNil(FPrimUndo);
    UpdateImage;
    exit;
   end;
  finally
   Old.Free;
  end;
 // размер подписи - свой, не из знака (при пересборке не сбрасывается)
  PD.SetProperty('Размер', byNone);
  BuildPoint1(Selector, Twigs.LayerTable, Twigs.Twigs, PD);
 end else begin
  OldX := PD.XDot;
  OldY := PD.YDot;
  OldUgol := PD.Ugol;
  OldHeight := TDotText(PD).Text.Height;
  PD.XDot := PD.XDot + FDx;
  PD.YDot := PD.YDot + FDy;
  PD.Ugol := PD.Ugol + FDA;
  TDotText(PD).Text.Height := TDotText(PD).Text.Height * FK;
  TDotText(PD).TextDirty := True;
  if Assigned(OnModifiedPrim) and not OnModifiedPrim(PD) then begin
   PD.XDot := OldX;
   PD.YDot := OldY;
   PD.Ugol := OldUgol;
   TDotText(PD).Text.Height := OldHeight;
   FreeAndNil(FPrimUndo);
   UpdateImage;
   exit;
  end;
 end;
 Undo.AddUndoItem(FPrimUndo);
 FPrimUndo := nil;
 Modified;
 Selector.UpdateImage(usmModify, PD);
 UpdateImage;
end;

// подсветка знака под курсором: Draw32 на live-канве, затем белый силуэт
// (live-слой смешивается со сценой в режиме Difference, как в TMouseTopo)
procedure TDataZnkSet.DrawActiveDot(const Canvas: ISkCanvas);
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
begin
 if (PrevActiveDot = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  OldCanvas := Drawer.SwapSkCanvas(Canvas);
  PrevWorld := Drawer.UseWorldCoords;
  Drawer.UseWorldCoords := True;
  try
   PrevActiveDot.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
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

procedure TDataZnkSet.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 if LOperation = Lo_TextZnak then DrawActiveDot(Canvas) else
 if LOperation = Lo_MoveText then DrawTextMarkers(Canvas);
end;

// форма диалога атрибутов по виду насаждения (SetTexts1 старой программы)
function TDataZnkSet.SetDialogClass(PD: TPointDot): Boolean;
var Kind: String;
begin
 Result := True;
 if VarSetForm1 = 0 then begin
  GlobalVarSetDlgClass := TVarSetDlg;
  exit;
 end;
 Kind := String(PD.GetProperty('*Тип (ОГХ)'));
 if Kind = 'Деревья/Кустарники' then GlobalVarSetDlgClass := TVarSetDlg1 else
 if Kind = 'Газоны' then GlobalVarSetDlgClass := TVarSetDlg2 else
 if Kind = 'Цветники' then GlobalVarSetDlgClass := TVarSetDlg3 else begin
  TDialogService.ShowMessage('Выберите растение, газон или цветник');
  ClearSelected;
  Result := False;
 end;
end;

procedure TDataZnkSet.ClearSelected;
begin
 PrevActiveDot := nil;
 LMouseDown := False;
 Twigs.ClearSelection;
// слой выделения (статический оверлей) и live-слой с подсветкой
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 UpdateImage;
end;

// диалог атрибутов знака PD; изменение записывается в Undo (LU_ModifiedPrim)
procedure TDataZnkSet.EditTexts(PD: TPointDot);
var NilTextManager: Boolean;
    PrimUndo: TPrimUndo;
    A: IDataZnkAlive;
    Form: TForm2;
begin
 if (PD = nil) or (PD is TDotText) then exit;
 if not SetDialogClass(PD) then exit;
 NilTextManager := PD.TextManager = nil;
 if NilTextManager then PD.CreateTextManager;
 if PD.TextManager = nil then exit;
 PD.TextManager.UpdateResults := True;
// копия знака до изменения - для отмены
 PrimUndo := TPrimUndo.Create(Twigs, LU_ModifiedPrim, 'UndoTextZnak...Lo_TextZnak');
 PrimUndo.AddModifiedPrim(PD);
 A := FAlive;
 Form := Twigs;
 FTextsDialog := True;
 PD.TextManager.SetTexts2(Twigs, PD, True, VarSetForm1,
  procedure(OK: Boolean)
  begin
  // форма или знак могли смениться, пока открыт диалог
   if not A.Alive then begin
    PrimUndo.Free;
    exit;
   end;
   FTextsDialog := False;
   LMouseDown := False;
   if not OK or (Assigned(OnModifiedPrim) and not OnModifiedPrim(PD)) then begin
    if NilTextManager then PD.FreeTextManager else
    if PD.TextManager <> nil then PD.TextManager.UpdateResults := False;
    PrimUndo.Free;
    ClearSelected;
    exit;
   end;
   if PD.TextManager <> nil then PD.TextManager.UpdateResults := False;
   BuildPoint1(Selector, Form.LayerTable, Form.Twigs, PD);
   Undo.AddUndoItem(PrimUndo);
   Modified;
   Selector.UpdateImage(usmModify, PD);
   ClearSelected;
  end);
end;

procedure TDataZnkSet.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var I, J: Integer;
    B: Byte;
    PD: TPointDot;
    R: Double;
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
 if LOperation = Lo_TextZnak then EditTexts(PrevActiveDot) else
 if LOperation = Lo_MoveText then begin
 // захват надписи или подписи знака: маркер или контур, верхние - первыми
  EndMoveText;
  R := Selector.XGeoRasst(TwigTolerancePix(0));
  for I := Twigs.Twigs.AnyCount - 1 downto 0 do begin
   PD := Twigs.Twigs.AAt(I, B);
   if not (TObject(PD) is TPointDot) or not PD.isNoClosed then continue;
   if PD is TDotText then begin
    if GrabText(PD, -1, TDotText(PD).TextBitmap, X, Y, R) then break;
   end else
   if (PD.TextManager <> nil) and (PD.userObj = nil) then begin
    for J := PD.TextManager.FTextBitmaps.Count - 1 downto 0 do
     if (J < PD.TextManager.FValues.Count) and GrabText(PD, J, PD.TextManager.FTextBitmaps[J], X, Y, R) then break;
    if FMoveDot <> nil then break;
   end;
  end;
  UpdateImage;
 end;
end;

procedure TDataZnkSet.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then Hook := False;
 if (LOperation = Lo_MoveText) and (Button = TMouseButton.mbLeft) then EndMoveText;
end;

// знак под курсором (в старой программе - по подписи знака или расстоянию
// psAutoDisst; здесь - поиск знака, как у поворота знака TMouseTopo)
procedure TDataZnkSet.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var D0, D1: Double;
begin
 if FTextsDialog then begin Hook := True; exit; end; // открыт диалог атрибутов
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
// захваченная надпись: поворот - на приращение направления от точки надписи,
// масштаб - на отношение расстояний до нее, перемещение - на сдвиг курсора
 if (LOperation = Lo_MoveText) and (FMoveDot <> nil) then begin
  case FMoveFlag of
   0: FDA := FDA + Direct_Angle(FPivotX, FPivotY, X, Y) - Direct_Angle(FPivotX, FPivotY, FPrevX, FPrevY);
   1: begin
     D0 := Distance(FPivotX, FPivotY, FPrevX, FPrevY);
     D1 := Distance(FPivotX, FPivotY, X, Y);
     if (D0 > 0) and (D1 > 0) and (FK * D1 / D0 > 0.05) then FK := FK * D1 / D0;
    end;
   2: begin
     FDx := FDx + X - FPrevX;
     FDy := FDy + Y - FPrevY;
    end;
  end;
  FPrevX := X;
  FPrevY := Y;
  UpdateImage;
  exit;
 end;
 if LOperation <> Lo_TextZnak then exit;
 emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
 if (objTemporary is TPointDot) and not (objTemporary is TDotText) then PrevActiveDot := TPointDot(objTemporary) else PrevActiveDot := nil;
 UpdateImage;
end;

function TDataZnkSet.Hint: String;
begin
 if LOperation = Lo_MoveText then Result := 'Надпись, атрибут знака: внутри контура - переместить, кружок - повернуть, квадрат - масштаб' else Result := inherited Hint;
end;

end.
