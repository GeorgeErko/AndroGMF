unit objHotSpot32;

// Перенос части модуля objHotSpot из Geomaster (Delphi 7, GDI): установка
// блоков из панели блоков (instBlockSign, кнопки по Tag):
//  spotSetBlock (2)  - установка блока щелчком; при привязке к линии блок
//                      поворачивается по ее сегменту (blockAngle);
//  spotSetAngle (21) - установка блока по направлению последней указанной
//                      линии (pastRotation).
// Правая кнопка - поворот блока на 90 градусов. Блок с флагом useBum
// разбивается в карту (bumToTwgForm), в дугу - по BehindTheWheel.
// Временный блок рисуется в DrawTemp тем же Draw32, что и сцена, белым
// силуэтом на live-слое (аналог XOR-отрисовки старой программы).
// Не перенесено: точка привязки (spotSet), лестницы (spotSetStair),
// прямоугольники (spotSetRect, spotSetBlockRect), обрезка/фаска/продление
// (spotTrim, spotFaska, spotRound, spotExtend), привязки (spotResetBind),
// фиксированная длина (fixPoint1/fixPoint2, AccuDraw).

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     FMX.Types, objMouse32, objMouseSelect32, objMouseDraw32, drawTwigs32,
     Collect, EcDot, EcLot, WpTwigs, WptForm2, newBlock;

const
  spotSetBlock = 2;
  spotSetAngle = 21;

type
 TMouseHotSpot = class(TMousePainter)
  private
   FBlock: TGeoBlock;
   procedure SetBlockObj(const Value: TGeoBlock);
  public
   bumBlock: Boolean;
   XBlock, YBlock: Double;  // точка установки (с привязкой)
   Rotate90: Double;        // поворот правой кнопкой
   blockWidth: Double;      // ширина линии привязки ('Ширина'), ZNull - нет
   tmpTwig: TTwig;          // линия, к которой притянут курсор
   BlockVisible: Boolean;   // положение блока задано движением мыши
   TempPoint: TPointDot;    // временная точка с блоком для DrawTemp
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Procedure Return(Sender: TObject); override;
  //
   Function BlockAngleNow: Double;
   Function GetBlockKoef(var XK, YK: Single; arcTwig: TTwig): Boolean;
   Procedure DrawBlock(const Canvas: ISkCanvas);
   Procedure SetBlock(X, Y, Angle: Double; arcTwig: TTwig = nil);
  // блок выбирается в панели блоков
   Property Block: TGeoBlock read FBlock write SetBlockObj;
 end;

implementation

uses Math, GBFWUndo, UndoColNew, newSelector, newResource, newProperties,
     WpArcs, maths_basic, ogcDrawerSkia, Writer, Selector32;

{ TMouseHotSpot }

constructor TMouseHotSpot.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 Rotate90 := 0;
 blockWidth := ZNull;
 blockAngle := 0;
 TempPoint := TPointDot.Create(0, 0, 0);
end;

destructor TMouseHotSpot.Destroy;
begin
// блок принадлежит списку блоков карты, временная точка его не освобождает
 if TempPoint <> nil then TempPoint.userObj := nil;
 TempPoint.Free;
 inherited;
end;

procedure TMouseHotSpot.SetBlockObj(const Value: TGeoBlock);
begin
 FBlock := Value;
 if FBlock <> nil then bumBlock := FBlock.useBum else bumBlock := False;
end;

// смена блока в панели блоков (TinstBlocks.CBPointZnakClick старой программы)
procedure TMouseHotSpot.Return(Sender: TObject);
begin
 UpdateImage;
end;

// угол установки: по сегменту линии привязки или по последней линии
function TMouseHotSpot.BlockAngleNow: Double;
begin
 if LOperation = spotSetAngle then Result := pastRotation else Result := blockAngle;
end;

// масштаб блока: параметры блока ('Масштаб' или 'Ширина'/'Высота') и
// автомасштаб по ширине линии привязки; у дуги - хорда ('Хорда')
function TMouseHotSpot.GetBlockKoef(var XK, YK: Single; arcTwig: TTwig): Boolean;
var bWidth, bHeight, bK, S, R: Double;
begin
 Result := True;
 XK := 1;
 YK := 1;
 if Block = nil then exit;
 if Block.useUserParams and (Block.Properties <> nil) then begin
  if Block.Properties.PropValue['Масштаб'] <> nil then begin
   try
    bK := Block.Properties.PropValue['Масштаб'].AsFloat;
    XK := bK / 1000;
    YK := bK / 1000;
   except
   end;
  end else begin
   if Block.Properties.PropValue['Ширина'] <> nil then
    try
     bWidth := Block.Properties.PropValue['Ширина'].AsFloat;
     XK := bWidth / Block.rectWidth;
    except
    end;
   if Block.Properties.PropValue['Высота'] <> nil then
    try
     bHeight := Block.Properties.PropValue['Высота'].AsFloat;
     YK := bHeight / Block.rectHeight;
    except
    end;
  end;
 end;
 if Block.useAutoScale and (blockWidth <> ZNull) then begin
  YK := blockWidth / Block.rectHeight;
 // в дугу - по хорде, если у блока задан параметр 'Хорда'
  if (arcTwig is TTwigArc) and Block.useUserParams and (Block.Properties <> nil) then
   if Block.Properties.PropValue['Хорда'] <> nil then
    try
     bWidth := Block.Properties.PropValue['Хорда'].AsFloat;
     R := TTwigArc(arcTwig).Radius;
     S := 2 * R * ArcSin(bWidth / (2 * R));
     XK := S / Block.rectWidth;
    except
    end;
 end;
end;

// временный блок: Draw32 на live-канве, затем белый силуэт (live-слой
// смешивается со сценой в режиме Difference - аналог XOR старой программы)
procedure TMouseHotSpot.DrawBlock(const Canvas: ISkCanvas);
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
begin
 if (Block = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 TempPoint.userObj := Block;
 TempPoint.Selector := Selector;
 TempPoint.XDot := XBlock;
 TempPoint.YDot := YBlock;
 TempPoint.Ugol := BlockAngleNow + Rotate90;
 GetBlockKoef(TempPoint.XKoef, TempPoint.YKoef, tmpTwig);
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  OldCanvas := Drawer.SwapSkCanvas(Canvas);
  PrevWorld := Drawer.UseWorldCoords;
  Drawer.UseWorldCoords := True;
  try
   TempPoint.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
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

procedure TMouseHotSpot.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 case LOperation of
  spotSetBlock, spotSetAngle: if BlockVisible then DrawBlock(Canvas);
 end;
end;

// установка блока (TMouseHotSpot.SetBlock старой программы)
procedure TMouseHotSpot.SetBlock(X, Y, Angle: Double; arcTwig: TTwig);
var PD: TPointDot;
    L: TResource;
    P: PCollection;
procedure InsertWheelTwigs;
var I: Integer;
    Twig: TTwig;
    Lot: TLot;
begin
 Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'AddArcObject from Block...'));
 for I := 0 to P.Count - 1 do begin
  Twig := P[I];
  Twigs.Twigs.Insert(TWG_Twig, Twig);
  Lot := TLot.Create(Twig.ClassHandle.ID, Twig.ClassHandle, 1);
  Lot.Selector := Selector;
  Lot.TypeLot := 1;
  Lot.Insert(Twigs.Twigs.TwigsCount - 1);
  Lot.SetMinMax(Twigs.Twigs);
  Twigs.Twigs.Insert(TWG_Lot, Lot);
  TPrimUndo(Undo.Last).AddModifiedPrim(Lot);
 end;
end;
begin
 if Block = nil then exit;
 if not bumBlock then begin
 // точка с блоком в слое блока (AutoLayer) или в активном слое
  if Block.AutoLayer <> 0 then begin
   L := Twigs.LayerTable.SearchLayer(Block.AutoLayer);
   if L <> nil then begin
    Twigs.LayerTable.ActiveLayer := L;
    if Assigned(OnSetActiveLayer) then OnSetActiveLayer(L, 0);
   end;
  end;
  PD := TPointDot.Create(X, Y, 0);
  PD.Selector := Selector;
  PD.Ugol := Angle + Rotate90;
  PD.userObj := Block;
  PD.Code := Twigs.LayerTable.ActiveLayer.ID;
  PD.ClassHandle := Twigs.LayerTable.ActiveLayer;
  GetBlockKoef(PD.XKoef, PD.YKoef, nil);
  if Assigned(OnAddPrim) and not OnAddPrim(PD) then begin
   PD.userObj := nil;
   PD.Free;
   exit;
  end;
  Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'UndoAddNewPointBlock...em_SetBlock'));
  Twigs.Twigs.Insert(TWG_Point, PD);
  TPrimUndo(Undo.Last).AddModifiedPrim(PD);
  Twigs.ClassBuildII;
  Modified;
  Selector.UpdateImage(usmAdd, PD);
 end else begin
 // блок разбивается в карту (в дугу - сегменты между дугами)
  PD := TPointDot.Create(X, Y, 0);
  try
   PD.Ugol := Angle + Rotate90;
   PD.userObj := Block;
   GetBlockKoef(PD.XKoef, PD.YKoef, arcTwig);
   Block.MoveTo(PD.XDot, PD.YDot, PD.Ugol, PD.XKoef, PD.YKoef, PD.Extrusion);
   try
    if arcTwig is TTwigArc then P := Block.BehindTheWheel(X, Y, PD.XKoef, PD.YKoef, PD.Ugol, TTwigArc(arcTwig), False) else P := nil;
    Undo.StartTransAction;
    try
     if P = nil then Block.bumToTwgForm(Twigs, True, True, True) else InsertWheelTwigs;
     Undo.Commit;
     Modified;
    except
     on E: Exception do begin
      WriteIn(['SetBlock exception ', E.Message]);
      Undo.RollBack;
      Twigs.Pack(nil);
     end;
    end;
    if P <> nil then begin
     P.DeleteAll;
     P.Free;
    end;
   finally
    Block.MoveUp;
   end;
  finally
   PD.userObj := nil;
   PD.Free;
  end;
  tmpTwig := nil;
  Selector.UpdateImage;
 end;
 Rotate90 := 0;
end;

procedure TMouseHotSpot.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
 case LOperation of
  spotSetBlock, spotSetAngle:
   if BlockVisible then begin
    SetBlock(XBlock, YBlock, BlockAngleNow, tmpTwig);
    UpdateImage;
   end;
 end;
end;

procedure TMouseHotSpot.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 case LOperation of
  spotSetBlock, spotSetAngle: begin
  // линия под курсором (ширина для автомасштаба, угол сегмента - blockAngle)
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, True);
    tmpTwig := nil;
    if objTemporary is TTwig then tmpTwig := TTwig(objTemporary) else
    if objTemporaryTwig <> nil then tmpTwig := objTemporaryTwig;
    blockWidth := ZNull;
    if (tmpTwig <> nil) and (tmpTwig.Properties <> nil) then begin
     try
      if tmpTwig.Properties.PropValue['Ширина'] <> nil then blockWidth := tmpTwig.Properties.PropValue['Ширина'].AsFloat;
     except
     end;
     if blockWidth = 0 then blockWidth := ZNull;
    end;
    if Marker.Visible then begin
     X := Marker.mX;
     Y := Marker.mY;
    end;
    XBlock := X;
    YBlock := Y;
    BlockVisible := True;
    UpdateImage;
   end;
 end;
end;

// правая кнопка - поворот блока на 90 градусов
procedure TMouseHotSpot.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 case LOperation of
  spotSetBlock, spotSetAngle: begin
    Rotate90 := Rotate90 + Pi / 2;
    if Rotate90 > 2 * Pi then Rotate90 := Rotate90 - 2 * Pi;
    UpdateImage;
   end;
 end;
end;

end.
