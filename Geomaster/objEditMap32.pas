unit objEditMap32;

// Перенос модуля objEditMap из Geomaster (Delphi 7, GDI): операции
// редактирования карты. Переносится по группам операций; сейчас:
//  1. выделение - em_GetObject (клик), em_GetObjectFrag (рамка),
//     выделение многоугольником (em_GetObjectPolygon = 1, sysDrawRect),
//     em_MoveObjectPoints (перетаскивание вершин выделенных объектов).
// Выделенные объекты хранятся в Objects/Objects2 (TSelectedObjects), как в
// старой программе; захват через ICapturer не используется.
// Выделение рисуется в статическом оверлее (DrawTempStatic) и обновляется
// через Selector.OnInvalidateOverlayStatic; рамка и перетаскиваемые вершины -
// в live-слое (DrawTemp). Live-слой смешивается со сценой в режиме Difference:
// черный там не виден, поэтому рамка рисуется белым (аналог XOR-пера).
//  2. преобразование выделенного - em_ObjectMove (сдвиг), em_Copy (копии со
//     сдвигом, подряд), em_ObjectRotate (поворот: центр, начальное и конечное
//     направление), em_ObjectRotate90/180/270, em_Scale (масштаб: базовая
//     точка, точка направления, новое положение), em_Mirror (отраженная копия
//     с последующим сдвигом). Запуск - из меню выделенных объектов
//     (FrameObjects.PMEditMap, бывший FlyObjects.PMEditMap) по правому клику:
//     Tag пункта - код операции, TEditMap.DoCommand -> StartOperation;
//     Esc - отмена операции, Delete - удаление выделенного.
//     Предварительный вид - готовые SkPicture объектов сцены, нарисованные с
//     матрицей преобразования (без пересчета геометрии на каждом движении).
//     Для поворота и зеркала матрица строится по образам трех точек, которые
//     прогоняются через те же функции, что и при выполнении операции.
//     В отличие от старой программы, при сдвиге/повороте/масштабе копии
//     объектов не создаются (Pack у TForm2 пустой - их ветви оставались бы
//     в Twigs.Twigs); копии создаются только для em_Copy и em_Mirror.
// Не перенесено: растровые объекты (TBmpMgr, TRasterLot), подсказка GetHint,
// GPS/трек, всплывающее меню FlyFormObjects, буфер обмена (Copy(0/1)),
// многоформенный режим STS (useLevels), OLE-объекты.

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia, FMX.Graphics,
     Collect, ogcBasic, TwgDraw, EcDot, EcLot, WpTwigs, WpArcs, WptForm2,
     SelectedObjects, mpMarker,
     objMouse32, objMouseSelect32, objMouseDraw32, drawTwigs32;

const
  em_GetObjectPolygon: byte = 0;
  em_TwiceTwig = 502;
  em_ReTwiseTwig = 5021;
  em_ReTwiseTwigA = 5022;
  em_Stvor = 503;
  em_PointStvor = 504;
  em_OGZ = 505;
  em_PerPoint = 506;
  em_SetRect1 = 507;
  em_SetRect2 = 508;
  em_ResetLength = 509;
  em_FixedDist = 511;
  em_MergeTwig = 512;
 //
  em_MoveText2 = 2;
  em_RotateText2 = 3;
  em_StretchText2 = 4;
  em_Perpend = 5;
  em_Promer = 6;
  em_InvZas = 7;
  em_Polar = 8;
  em_MovePointOn = 9;
  em_InsertPoint = 510;
  em_DeletePoint = 11;
  em_newStvor = 12;
 // рисовка
  em_CreatePoint = 520;
  em_CreateLine = 521;
  em_CreatePolygon = 522;
  em_CreateRect = 526;
  em_NewLine = 523;
  em_NewPoly = 524;
  em_NewPolyA = 525;
  em_NewPolyLine = 590;
  em_MergeLineLot = 540;
  em_AutoLot = 541;
  em_CreateSpline = 527;
  em_CreateArc = 528;
  em_CreateCircle = 529;
  em_MergeProperties = 5290;
  em_MergeProperties1 = 52900;
 //
  em_ObjectRotate90 = 5092;
  em_ObjectRotate180 = 5182;
  em_ObjectRotate270 = 5272;
 //
  em_GetObject2 = 5273;
  em_CreateLine2 = 5274;
 //
  em_GetObjectProps = 5277;
 // команды меню выделенных объектов (не операции мыши); эти же числа -
 // в Tag пунктов FrameObjects.fmx
  em_SelectNone = 5301;
  em_SelectInvert = 5302;
  em_DeleteObjects = 5303;

type
 TEditMap = class(TMousePainter)
  private
   fOnDelete: TNotifyEvent;
   fonGetObject2: TNotifyEvent;
   function GetActiveLot(Index: Integer): TLot;
   function GetActiveLotCount: Integer;
  public
   OnlySQWLot: boolean;
   X1, Y1, X2, Y2, XO, YO: Double;
   beginX1, beginY1: Double;
   is_mouseDown: Boolean;
   fActiveTwigs, fActiveFonts, fActiveDots: PCollection;
   DrawTwig: TTwig;
   StvorTwigs: PCollection;
   DrawDot: TDot;
  // к засечке
   NSt, NNapr: String;
   XSt, YSt, XNapr, YNapr: Double;
  // выделенные объекты
   Objects: TSelectedObjects;
   Objects2: TSelectedObjects;
   OldObjects: TSelectedObjects;
   TwigSpline: TTwigSpline;
   TwigArc: TTwigArc;
   CondArc: Integer;
   TwigCircle: TTwigCircle;
   ObjectPoints: TNearestPoints;
   AutoCol: PCollection; // временная коллекция точек em_AutoLot
  //
   propMergeObject: TTD;
   destroyPropObject: boolean;
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
  // перехват сообщений мыши
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  //
   Procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); override;
  //
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Procedure emDrawGabarites(const Canvas: ISkCanvas; List: TSelectedObjects);
  //
   Function emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState = []): TTwgObject;
   Procedure emDrawSelectedObjects(const Canvas: ISkCanvas);
   Procedure emDrawFragment(const Canvas: ISkCanvas);
   Procedure emAddSelectedObjects;
   Procedure emAddSelectedObjectsPolygon;
   Function emGetNearestPointsOnObjects(X, Y: Double): boolean;
   Procedure emObjectPointsMoved;
  // выделение изменилось - перерисовка статического оверлея
   Procedure SelectionChanged;
  // объект изменен - перестроение его в сцене
   Procedure SceneModified(Obj: TObject);
  //
   Property ActiveLot[Index: Integer]: TLot read GetActiveLot;
   Property ActiveLotCount: Integer read GetActiveLotCount;
   Property OnDelete: TNotifyEvent read fOnDelete write fOnDelete;
   Property onGetObjects2: TNotifyEvent read fonGetObject2 write fonGetObject2;
  //
   Procedure SelectObjectByIndex(LotIndex_, AnyIndex_: Integer);
   Procedure SelectAll;
   Procedure SelectAllObjects;
  // команды меню выделенных объектов (FrameObjects) по коду (Tag пункта)
   Procedure DoCommand(Tag: Integer);
   Function CommandEnabled(Tag: Integer): Boolean;
   Procedure emInvertSelection;
   Procedure emDeleteObjects;
   Procedure PackTwigs(UseOnModified: Boolean);
  // преобразование выделенного
   Procedure StartOperation(Opr: Integer);
   Procedure EndTransform;
   Procedure Return(Sender: TObject); override;
   Procedure emMoveObjects(Dx, Dy: Double);
   Procedure emRotateObjects(XX, YY, Angle: Double);
   Procedure emScaleObjects(XX, YY, Kx, Ky: Double);
   Procedure emMirrorObjects(XX1, YY1, XX2, YY2: Double);
   Procedure ResetTwigOpr15;
   Function emModifyObjects(const UndoName: String; Apply: TProc<Boolean>): Boolean;
   Function emCloneObjects: TSelectedObjects;
   Function emAddCopyObjects(Copies: TSelectedObjects): Boolean;
   Procedure emMoveCopyObject(Dx, Dy: Double);
   Procedure emRotateCopyObjects(XX, YY, Angle: Double);
   Procedure emScaleCopyObject(XX1, YY1: Double);
   Procedure emCopyObjects(Dx, Dy: Double);
   Procedure emMirrorCopyObjects(XX1, YY1, XX2, YY2: Double);
   Function emRotateAngle: Double;
   Function emScaleKoef(XX1, YY1: Double; out Kx, Ky: Double): Boolean;
   Procedure emDrawTransform(const Canvas: ISkCanvas);
 end;

implementation

uses Math, System.Math.Vectors, System.Generics.Collections, FMX.Forms,
     GBFWUndo, UndoColNew, UpdateMessages, newSelector, newSettings, polygons,
     maths_basic, EMath, FramePropEditor, FrameAccuDraw, TextManager, TwgColle,
     newForm0, FrameObjects,
     ogcDrawerSkia, ogcMarker, objOutline, EcDot2, TwgBitmaps, newProcs, Writer, Selector32;

const
// отладка: рисовать габариты выделенных объектов (emDrawGabarites)
  DebugDrawGabarites = False;

type
 TMapXY = reference to procedure(var X, Y: Double);

// бывшие TTwig.GetMarkedPoints/GetMarkedPoints2 старого WpTwigs: точки ветви
// в прямоугольнике R (в многоугольнике P); при AllSelect - только если все
// точки внутри, иначе - если внутри хотя бы одна или ветвь пересекает границу
function TwigCrossesPolyline(Tw: TTwig; P: PCollection): Boolean;
var I, J: Integer;
    D1, D2, D3, D4: TDot;
    T, O: Double;
begin
 Result := False;
 for I := 0 to Tw.Coord.Count - 2 do begin
  D1 := Tw.Coord[I];
  D2 := Tw.Coord[I + 1];
  for J := 0 to P.Count - 2 do begin
   D3 := P[J];
   D4 := P[J + 1];
   if (intersection_straight_lines(D1.XDot, D1.YDot, D2.XDot, D2.YDot, D3.XDot, D3.YDot, D4.XDot, D4.YDot, T, O) = 1) and (Round(O * Const_Of_PrecCoord) >= 0) and (Round(O * Const_Of_PrecCoord) <= Const_Of_PrecCoord) and (Round(T * Const_Of_PrecCoord) >= 0) and (Round(T * Const_Of_PrecCoord) <= Const_Of_PrecCoord) then exit(True);
  end;
 end;
end;

function TwigMarkedPoints(Tw: TTwig; R: TSect; Poly: PCollection; AllSelect: Boolean): Integer;
var I: Integer;
    D: TDot;
    P: PCollection;
    OldView: Byte;
    Inside: Boolean;
begin
 Result := 0;
// у дуг - аппроксимирующая ломаная (TTwigArc.GetMarkedPoints)
 OldView := Tw.ArcView;
 Tw.ArcView := 1;
 P := nil;
 try
  for I := 0 to Tw.Coord.Count - 1 do begin
   D := Tw.Coord[I];
   if Poly = nil then Inside := PointInSect(D.XDot, D.YDot, R) else Inside := Point_and_Polygon(D.XDot, D.YDot, Poly) > -1;
   if Inside then Inc(Result);
  end;
  if AllSelect then begin
   if Result <> Tw.Coord.Count then Result := 0;
   exit;
  end;
  if Result <> 0 then exit;
 // ни одной точки внутри: ищем пересечение ветви с границей
  if Poly = nil then begin
   P := PCollection.Create(5);
   P.Insert(TDot.Create(R.Left, R.Top, 0));
   P.Insert(TDot.Create(R.Right, R.Top, 0));
   P.Insert(TDot.Create(R.Right, R.Bottom, 0));
   P.Insert(TDot.Create(R.Left, R.Bottom, 0));
   P.Insert(TDot.Create(R.Left, R.Top, 0));
   if TwigCrossesPolyline(Tw, P) then Result := Tw.Coord.Count;
  end else
   if TwigCrossesPolyline(Tw, Poly) then Result := Tw.Coord.Count;
 finally
  Tw.ArcView := OldView;
  P.Free;
 end;
end;

// цвет Windows (BGR) в TAlphaColor
function WinColor(C: Integer): TAlphaColor;
begin
 Result := $FF000000 or (Cardinal(C and $FF) shl 16) or (Cardinal(C and $FF00)) or (Cardinal(C shr 16) and $FF);
end;

// операции группы 2 (преобразование выделенного)
function IsTransformOpr(Opr: Integer): Boolean;
begin
 case Opr of
  em_ObjectMove, em_Copy, em_ObjectRotate, em_ObjectRotate90, em_ObjectRotate180, em_ObjectRotate270, em_Scale, em_Mirror: Result := True;
 else
  Result := False;
 end;
end;

// фиксированная длина сдвига (fixLength, AccuDraw) - формула старой программы
procedure FixLengthXY(X1, Y1, L: Double; var X2, Y2: Double);
var Angle: Double;
begin
 if L = xyNull then exit;
 Angle := EMath.Atan2(Y1 - Y2, X1 - X2) + Pi / 2;
 X2 := X1 + L * Cos(Angle);
 Y2 := Y1 - L * Sin(Angle);
end;

// поворот точки вокруг (XX, YY) - как RotateDots старой программы
procedure RotateXY(XX, YY, Angle: Double; var X, Y: Double);
var XXX, YYY: Double;
begin
 mpMarker.Rotate(0, 0, Angle, X, Y);
 XXX := XX;
 YYY := YY;
 mpMarker.Rotate(XXX, YYY, Angle, XXX, YYY);
 X := X + XX - XXX;
 Y := Y + YY - YYY;
end;

// отражение точки относительно прямой через (AX, AY) и (BX, BY)
procedure MirrorXY(AX, AY, BX, BY: Double; var X, Y: Double);
var DX, DY, L, T: Double;
begin
 DX := BX - AX;
 DY := BY - AY;
 L := DX * DX + DY * DY;
 if L = 0 then exit;
 T := ((X - AX) * DX + (Y - AY) * DY) / L;
 X := 2 * (AX + T * DX) - X;
 Y := 2 * (AY + T * DY) - Y;
end;

// матрица аффинного преобразования по образам точек B, B+(D,0), B+(0,D):
// преобразование задается той же функцией, что и при выполнении операции
function AffineMatrix(BX, BY: Double; const Map: TMapXY): TMatrix;
const D = 100;
var X0, Y0, XA, YA, XB, YB: Double;
begin
 X0 := BX;
 Y0 := BY;
 Map(X0, Y0);
 XA := BX + D;
 YA := BY;
 Map(XA, YA);
 XB := BX;
 YB := BY + D;
 Map(XB, YB);
 Result := TMatrix.Identity;
 Result.m11 := (XA - X0) / D;
 Result.m12 := (YA - Y0) / D;
 Result.m21 := (XB - X0) / D;
 Result.m22 := (YB - Y0) / D;
// смещение - в Double, чтобы не терять точность на больших координатах
 Result.m31 := X0 - (BX * (XA - X0) + BY * (XB - X0)) / D;
 Result.m32 := Y0 - (BX * (YA - Y0) + BY * (YB - Y0)) / D;
end;

// габариты прямоугольника после преобразования матрицей
function MapRect(const M: TMatrix; const R: TRectF): TRectF;
var I: Integer;
    X, Y: Single;
    P: array[0..3] of TPointF;
begin
 P[0] := R.TopLeft;
 P[1] := PointF(R.Right, R.Top);
 P[2] := R.BottomRight;
 P[3] := PointF(R.Left, R.Bottom);
 for I := 0 to 3 do begin
  X := P[I].X * M.m11 + P[I].Y * M.m21 + M.m31;
  Y := P[I].X * M.m12 + P[I].Y * M.m22 + M.m32;
  if I = 0 then Result := TRectF.Create(X, Y, X, Y) else begin
   Result.Left := Min(Result.Left, X);
   Result.Top := Min(Result.Top, Y);
   Result.Right := Max(Result.Right, X);
   Result.Bottom := Max(Result.Bottom, Y);
  end;
 end;
end;

{ TEditMap }

constructor TEditMap.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited Create(ATwigs, AFreeProc);
 Quants_For_Arcs := Twigs.Settings.psArcCount;
 fActiveTwigs := PCollection.Create(1);
 fActiveFonts := PCollection.Create(1);
 fActiveDots := PCollection.Create(1);
 StvorTwigs := PCollection.Create(1);
 XNapr := ZNull;
 XSt := ZNull;
 if PropEditorForm = nil then begin
  Objects := TSelectedObjects.Create(Twigs, nil);
  Objects2 := TSelectedObjects.Create(Twigs, nil);
 end else begin
  Objects := TSelectedObjects.Create(Twigs, PropEditorForm.Update);
  Objects2 := TSelectedObjects.Create(Twigs, PropEditorForm.Update);
 end;
 DrawDot := nil;
 DrawTwig := nil;
 TwigSpline := nil;
 TwigArc := nil;
 CondArc := 0;
 TwigCircle := nil;
 ObjectPoints := TNearestPoints.Create(Twigs);
 Stvor_.X1 := xyNull;
 AutoCol := PCollection.Create(1);
// меню выделенных объектов (в старой программе - FlyFormObjects.PMEditMap)
 if ObjectsFrame <> nil then begin
  PopUpMenu := ObjectsFrame.PMEditMap;
  ObjectsFrame.EditMap := Self;
 end;
end;

destructor TEditMap.Destroy;
begin
 if (ObjectsFrame <> nil) and (ObjectsFrame.EditMap = Self) then begin
  ObjectsFrame.PMEditMap.IsOpen := False;
  ObjectsFrame.EditMap := nil;
 end;
 try
  Error := '0';
 // DrawTwig зарегистрирована в OrthoTwigs (OnDestroy), а inherited пересоздает
 // OrthoTwigs - освобождаем ее раньше
  if DrawTwig <> nil then FreeAndNil(DrawTwig);
  inherited Destroy;
  Error := '1';
  fActiveTwigs.DeleteAll;
  fActiveTwigs.Free;
  fActiveFonts.DeleteAll;
  fActiveFonts.Free;
  fActiveDots.DeleteAll;
  fActiveDots.Free;
  StvorTwigs.Free;
  Error := '4';
  if PropEditorForm <> nil then begin
   PropEditorForm.DetachObjects(Objects);
   PropEditorForm.DetachObjects(Objects2);
  end;
  Objects.DeleteAll;
  Objects2.DeleteAll;
  Objects.Free;
  Objects2.Free;
  if OldObjects <> nil then begin
   OldObjects.DeleteAll;
   OldObjects.Free;
   OldObjects := nil;
  end;
  Error := '5';
  if TwigSpline <> nil then TwigSpline.Free;
  if TwigArc <> nil then TwigArc.Free;
  if TwigCircle <> nil then TwigCircle.Free;
  ObjectPoints.Free;
  AutoCol.Free;
  AutoCol := nil;
 except
  WriteIn(['Отладчик : сообщение от ' + ClassName + '. Шаг отладки :' + Error + '. Операция отключена.']);
 end;
 if DestroyPropObject and (propMergeObject <> nil) then begin
  propMergeObject.Free;
  propMergeObject := nil;
 end;
end;

function TEditMap.GetActiveLot(Index: Integer): TLot;
begin
 Result := fActiveLots[Index];
end;

function TEditMap.GetActiveLotCount: Integer;
begin
 Result := fActiveLots.Count;
end;

procedure TEditMap.SelectionChanged;
begin
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic else UpdateImage;
end;

procedure TEditMap.SceneModified(Obj: TObject);
begin
 if Obj = nil then exit;
 WriteIn(['SceneMod=', TimeToStr(Now)]);
 Selector.UpdateImage(usmModify, Obj);
  WriteIn(['SceneMod2=', TimeToStr(Now)]);
end;

procedure TEditMap.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
 inherited;
// Esc - отмена преобразования
 if (Key = vkEscape) and IsTransformOpr(LOperation) then begin
  EndTransform;
  Key := 0;
  Hook := True;
  exit;
 end;
 if (Key = vkDelete) and (LOperation = em_GetObject) and (Objects.Count > 0) then begin
  DoCommand(em_DeleteObjects);
  Key := 0;
  Hook := True;
 end;
end;

procedure TEditMap.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Obj: TTwgObject;
    W: Byte;
    I, J: Integer;
    Lot: TLot;
begin
 if not (ShiftPress and ControlPress) then begin
  inherited MouseDown(Form, Button, Shift, X, Y, Hook);
  if ShiftPress or ControlPress then begin Hook := False; exit; end;
 end;
// средняя кнопка - пан карты в форме
 if (Button = TMouseButton.mbRight) or (Button = TMouseButton.mbMiddle) then exit;
 case LOperation of
  em_GetObject: begin
    if Marker.mX <> xyNull then begin
    // курсор на объекте: добавить в выделение или снять с него
     Marker.Remove(GCanvas);
     Obj := emGetObject(X, Y, W, Shift);
     if Obj <> nil then begin
      if Objects.IndexOf(Obj) = -1 then begin
       Objects.Insert(Obj);
       Objects.Coord[Objects.Count - 1] := TDot.Create(X, Y, 0);
       if Assigned(OnSetActiveLayer) then begin
        if Obj is TPointDot then OnSetActiveLayer(TPointDot(Obj).ClassHandle, 0) else
        if Obj is TLot then OnSetActiveLayer(TLot(Obj).ClassHandle, 0);
       end;
      end else begin
       Objects.AtDelete(Objects.IndexOf(Obj));
       if Obj is TLot then
        for I := 0 to TLot(Obj).Coord.Count - 1 do OrthoTwigs.Delete(TLot(Obj).GetTwig(Twigs.Twigs, I));
      end;
      SelectionChanged;
     end;
    end else
    if ObjectPoints.selPoints.Count > 0 then begin
    // курсор на вершине выделенного объекта: перетаскивание вершин
     LOperation := em_MoveObjectPoints;
     for I := 0 to Objects.Count - 1 do
      if TObject(Objects[I]) is TLot then begin
       Lot := TLot(Objects[I]);
       for J := 0 to Lot.Coord.Count - 1 do OrthoTwigs.Add(Lot.GetTwig(Twigs.Twigs, J), '');
      end;
     OrthoTwigs.UpdateTwigs;
     UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
     X2 := X;
     Y2 := Y;
     UpdateImage;
    end else
    if em_GetObjectPolygon = 1 then begin
    // выделение многоугольником
     LOperation := sysDrawRect;
     X0 := X;
     Y0 := Y;
     inherited;
     CondArc := 0;
    end else begin
    // выделение рамкой
     LOperation := em_GetObjectFrag;
     UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
     fRect.Left := X;
     fRect.Top := Y;
     fRect.Right := X;
     fRect.Bottom := Y;
     UpdateImage;
    end;
   end;
  sysDrawRect: begin
    Inc(CondArc);
    if CondArc = 2 then begin
     emAddSelectedObjectsPolygon;
     mpTwig.Free;
     mpTwig := nil;
     LOperation := em_GetObject;
     SelectionChanged;
     UpdateImage;
    end;
   end;
  em_MoveObjectPoints:
   if ObjectPoints.selPoints.Count > 0 then begin
    if fixPoint1.Visible then begin
     X2 := fixPoint2.mX;
     Y2 := fixPoint2.mY;
    end else if Marker.Visible then begin
     X2 := Marker.mX;
     Y2 := Marker.mY;
    end;
    Undo.StartTransAction;
    fActiveLots.DeleteAll;
    emFilterActiveLot(ObjectPoints.XSelect, ObjectPoints.YSelect);
    Undo.AddUndoItem(TPrimUndo.Create(Form, LU_ModifiedPrim, 'UndoLotsModified...em_MovePoint'));
    for I := 0 to fActiveLots.Count - 1 do TPrimUndo(Undo.Last).AddModifiedPrim(ActiveLot[I]);
    for I := 0 to ObjectPoints.selPoints.Count - 1 do
     if ObjectPoints.selPoint[I].Twig = nil then TPrimUndo(Undo.Last).AddModifiedPrim(ObjectPoints.selPoint[I].Dot);
    if ObjectPoints.SetXY(X2, Y2) then begin
     Modified;
     if emInsertPointInTwig(X2, Y2, nil, ObjectPoints) > 0 then Objects.DeleteAll;
     Undo.Commit;
    // все объекты, участвовавшие в перемещении - Modified и перестроение в сцене
     emObjectPointsMoved;
    end else
     Undo.RollBack;
    ObjectPoints.Free;
    ObjectPoints := TNearestPoints.Create(Twigs);
    fActiveLots.DeleteAll;
    LOperation := em_GetObject;
    UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
    TimerClose;
    Twigs.ClassBuildII;
    SelectionChanged;
    UpdateImage;
   end;
  em_GetObjectFrag: begin
    emAddSelectedObjects;
    LOperation := em_GetObject;
    UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
    SelectionChanged;
    UpdateImage;
   end;
 // сдвиг и копирование: базовая точка, затем точка назначения
  em_Copy, em_ObjectMove:
   if X1 = ZNull then begin
    if Marker.mX <> xyNull then begin
     X1 := Marker.mX;
     Y1 := Marker.mY;
     Marker.Remove(GCanvas);
    end else begin
     X1 := X;
     Y1 := Y;
    end;
    X2 := X1;
    Y2 := Y1;
    beginX1 := X1;
    beginY1 := Y1;
    UpdateImage;
   end else begin
    if fixPoint1.Visible then begin
     X2 := fixPoint2.mX;
     Y2 := fixPoint2.mY;
    end else if Marker.mX <> xyNull then begin
     X2 := Marker.mX;
     Y2 := Marker.mY;
    end;
    FixLengthXY(X1, Y1, fixLength, X2, Y2);
    if LOperation = em_Copy then begin
     emCopyObjects(X2 - X1, Y2 - Y1);
    // копирование продолжается: следующая копия - от последней поставленной
     X1 := X2;
     Y1 := Y2;
     Marker.Remove(GCanvas);
     if Objects.Count = 0 then EndTransform else begin
      SelectionChanged;
      UpdateImage;
     end;
     exit;
    end;
    emMoveCopyObject(X2 - X1, Y2 - Y1);
    EndTransform;
   end;
 // поворот на фиксированный угол: указывается центр
  em_ObjectRotate90, em_ObjectRotate180, em_ObjectRotate270: begin
    if Marker.mX <> xyNull then begin
     X1 := Marker.mX;
     Y1 := Marker.mY;
    end else begin
     X1 := X;
     Y1 := Y;
    end;
    emRotateCopyObjects(X1, Y1, (LOperation - em_ObjectRotate) * Pi / 180);
    EndTransform;
   end;
 // поворот (центр, начальное направление, конечное направление),
 // зеркало (две точки оси), масштаб (базовая точка, направление, новое положение)
  em_ObjectRotate, em_Mirror, em_Scale:
   if X1 = ZNull then begin
    if Marker.mX <> xyNull then begin
     X1 := Marker.mX;
     Y1 := Marker.mY;
     Marker.Remove(GCanvas);
    end else begin
     X1 := X;
     Y1 := Y;
    end;
    XO := X1;
    YO := Y1;
   // единственный точечный объект поворачивается сразу по направлению от центра
    if (LOperation = em_ObjectRotate) and (Objects.Count = 1) and (TObject(Objects[0]) is TPointDot) then
     if (TPointDot(Objects[0]).userObj <> nil) and (TPointDot(Objects[0]).userObj.objType <> TWG_Block) then begin
      X2 := X1;
      Y2 := Y1;
      XO := xyNull;
     end;
    UpdateImage;
   end else
   if X2 = ZNull then begin
    if Marker.mX <> xyNull then begin
     X2 := Marker.mX;
     Y2 := Marker.mY;
     Marker.Remove(GCanvas);
    end else begin
     X2 := X;
     Y2 := Y;
    end;
    if Distance(X1, Y1, X2, Y2) <= 0.001 then begin
     if LOperation = em_Scale then MessageInform('Выберите вторую точку не совпадающую с первой...');
     X2 := ZNull;
     exit;
    end;
    XO := X2;
    YO := Y2;
    if LOperation = em_Mirror then begin
     emMirrorCopyObjects(X1, Y1, X2, Y2);
     exit;
    end;
    if LOperation = em_Scale then begin
    // направление масштаба - направляющая для привязки
     DrawTwig := TTwig.Create(GSelector, 0);
     DrawTwig.Coord.Insert(TDot.Create(X1, Y1, 0));
     DrawTwig.Coord.Insert(TDot.Create(X2, Y2, 0));
     OrthoTwigs.Twigs.FreeAll;
     OrthoTwigs.Add(DrawTwig, '');
    end;
    UpdateImage;
   end else begin
    if LOperation = em_Scale then begin
     if fixPoint1.Visible then emScaleCopyObject(fixPoint2.mX, fixPoint2.mY) else
     if Marker.Visible then emScaleCopyObject(Marker.mX, Marker.mY) else emScaleCopyObject(X, Y);
    end else
     emRotateCopyObjects(X1, Y1, emRotateAngle);
    EndTransform;
   end;
 end;
end;

procedure TEditMap.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
var Obj: TTwgObject;
    W: Byte;
begin
 if not (ShiftPress and ControlPress) then begin
  inherited MouseMove(Form, Shift, X, Y, Hook);
  if ShiftPress or ControlPress then begin Hook := False; exit; end;
 end else
  LMouseDown := False;
 Hook := True;
 case LOperation of
  em_GetObjectFrag: begin
    fRect.Right := X;
    fRect.Bottom := Y;
    UpdateImage;
   end;
  em_GetObject: begin
    Marker.Remove(GCanvas);
   // курсор у вершины выделенного объекта - готовность к перетаскиванию
    if (Objects.Count > 0) and emGetNearestPointsOnObjects(X, Y) then begin
     X1 := X; Y1 := Y; X2 := X; Y2 := Y;
     UpdateImage;
     exit;
    end;
    Obj := emGetObject(X, Y, W, Shift);
    if Obj <> nil then begin
     if Obj is TPointDot then
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPointDot'], GCanvas)
     else if W = 2 then
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvPolygon'], GCanvas)
     else
      Marker.AssignMarker(GlobalSettings.MarkerView.NameOf['mvLine'], GCanvas);
     Marker.Move(GCanvas, X, Y);
    end;
    UpdateImage;
   end;
  em_MoveObjectPoints:
   if ObjectPoints.selPoints.Count > 0 then begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
    if fixPoint1.Visible then begin
     fixPoint2.mX := X;
     fixPoint2.mY := Y;
    end;
    UpdateFixedPoints(fixPoint2.mX, fixPoint2.mY);
    if fixPoint1.Visible then begin
     X2 := fixPoint2.mX;
     Y2 := fixPoint2.mY;
    end else begin
     X2 := X;
     Y2 := Y;
    end;
    UpdateImage;
   end;
  em_Copy, em_ObjectMove:
   if X1 = ZNull then begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
    UpdateImage;
   end else begin
    X2 := X;
    Y2 := Y;
    emGetDotMarker(X2, Y2, nil, Stvor_, objTemporary, True, True, True);
    if fixPoint1.Visible then begin
     fixPoint2.mX := X2;
     fixPoint2.mY := Y2;
    end;
    UpdateFixedPoints(fixPoint2.mX, fixPoint2.mY);
    if fixPoint1.Visible then begin
     X2 := fixPoint2.mX;
     Y2 := fixPoint2.mY;
    end;
    FixLengthXY(X1, Y1, fixLength, X2, Y2);
    UpdateImage;
   end;
 // центр поворота на фиксированный угол - за курсором
  em_ObjectRotate90, em_ObjectRotate180, em_ObjectRotate270: begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
    if Marker.mX <> xyNull then begin
     XO := Marker.mX;
     YO := Marker.mY;
    end else begin
     XO := X;
     YO := Y;
    end;
    UpdateImage;
   end;
  em_ObjectRotate, em_Mirror, em_Scale:
   if (X1 = ZNull) or (X2 = ZNull) then begin
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
   // вторая точка (ось отражения, направление) - за курсором
    if X1 <> ZNull then begin
     XO := X;
     YO := Y;
    end;
    UpdateImage;
   end else begin
    if LOperation = em_Mirror then exit;
    emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
    if LOperation = em_Scale then begin
     if Marker.Visible then begin
      XO := Marker.mX;
      YO := Marker.mY;
     end else begin
      XO := X;
      YO := Y;
     end;
     if fixPoint1.Visible then begin
      fixPoint2.mX := XO;
      fixPoint2.mY := YO;
     end;
     UpdateFixedPoints(fixPoint2.mX, fixPoint2.mY);
     if fixPoint1.Visible then begin
      XO := fixPoint2.mX;
      YO := fixPoint2.mY;
     end;
    end else
    if XO = xyNull then begin
     X2 := X;
     Y2 := Y;
    end else begin
     XO := X;
     YO := Y;
    end;
    UpdateImage;
   end;
 end;
end;

procedure TEditMap.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if LOperation <> sysDrawRect then inherited MouseRightDown(Form, Button, Shift, X, Y, Hook);
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 Hook := True;
 case LOperation of
  em_GetObject: if (PopupMenu <> nil) and (Objects.Count <> 0) then PopupMenuPopUp(X, Y);
 end;
end;

procedure TEditMap.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if not (ShiftPress and ControlPress) then begin
  inherited MouseUp(Form, Button, Shift, X, Y, Hook);
  if ShiftPress or ControlPress then begin Hook := False; exit; end;
 end else
  LMouseDown := False;
 Hook := True;
end;

procedure TEditMap.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
// направляющие, маркер, путь построения (sysDrawRect), точки фиксации
 inherited;
 if Canvas = nil then exit;
 case LOperation of
  em_GetObjectFrag: emDrawFragment(Canvas);
  em_MoveObjectPoints: begin
   // пунктир от вершины, с которой началось перемещение, к текущей точке
    SkDrawLineClipped(Canvas, ObjectPoints.XSelect, ObjectPoints.YSelect, X2, Y2, SkPen(Canvas, TAlphaColorRec.White, 1, True));
    ObjectPoints.DrawTo(Canvas, X2, Y2);
   end;
 else
  if IsTransformOpr(LOperation) then emDrawTransform(Canvas);
 end;
end;

procedure TEditMap.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 emDrawSelectedObjects(Canvas);
end;

procedure TEditMap.emDrawFragment(const Canvas: ISkCanvas);
var R: TRectF;
begin
// рамка выделения: сплошная - объекты целиком внутри, пунктир (справа
// налево) - пересекающие рамку
 R := TRectF.Create(Min(fRect.Left, fRect.Right), Min(fRect.Top, fRect.Bottom), Max(fRect.Left, fRect.Right), Max(fRect.Top, fRect.Bottom));
 Canvas.DrawRect(R, SkPen(Canvas, TAlphaColorRec.White, 1, fRect.Right <= fRect.Left));
end;

procedure TEditMap.emDrawSelectedObjects(const Canvas: ISkCanvas);
var FillPaint, LinePaint: ISkPaint;
    RPix: Single;
procedure DrawVertex(X, Y: Double);
var R: Single;
begin
 R := SkPixToWorld(Canvas, RPix);
 Canvas.DrawRect(TRectF.Create(X - R, Y - R, X + R, Y + R), FillPaint);
end;
procedure DrawList(List: TSelectedObjects);
var I, J: Integer;
    Obj: TObject;
    SkObj: TogsSkiaObject;
begin
 for I := 0 to List.Count - 1 do begin
  Obj := TObject(List[I]);
  if not (Obj is TTD) then continue;
  if (Obj is TLot) and (TLot(Obj).ClassHandle.Check <> 1) then continue;
  if (Obj is TPointDot) and not TPointDot(Obj).isNoClosed then continue;
  if not (TTD(Obj).DrawerObject is TogsSkiaObject) then continue;
  SkObj := TogsSkiaObject(TTD(Obj).DrawerObject);
 // объект цветом выделения (в старой программе - отрисовка с Inv)
  if Obj is TLot then begin
  // контуры (линейные и с заливкой) пока выделяются линией по ветвям; тонировка
  // картинки контура отключена (у контура с заливкой закрашивалась вся площадь)
  //  ogsDrawPictureEffect(Canvas, SkObj.BoundsWorld, SkObj.Pictures[LOD1_INDEX], GlobalSettings.Settings.gsSelectColor, pemTintSrcATop, 255);
   for J := 0 to TLot(Obj).Coord.Count - 1 do SkDrawTwig(Canvas, TLot(Obj).GetTwig(Twigs.Twigs, J), LinePaint);
  end else
   ogsDrawPictureEffect(Canvas, SkObj.BoundsWorld, SkObj.Pictures[LOD1_INDEX], GlobalSettings.Settings.gsSelectColor, pemTintSrcATop, 255);
 // вершины ветвей (у точечного объекта - точка вставки)
  ogsEnsureOutline(TTD(Obj), Twigs.Twigs);
  for J := 0 to High(SkObj.OutlineVertices) do DrawVertex(SkObj.OutlineVertices[J].X, SkObj.OutlineVertices[J].Y);
 end;
end;
begin
 if Canvas = nil then exit;
 FillPaint := TSkPaint.Create;
 FillPaint.AntiAlias := True;
 FillPaint.Color := WinColor(GlobalSettings.Settings.gsSelectPointColor);
 RPix := Max(2, GlobalSettings.Settings.gsPointSize / 1);
// линия выделенного контура
 LinePaint := SkPen(Canvas, WinColor(GlobalSettings.Settings.gsSelectColor), 2, False);
 DrawList(Objects);
 DrawList(Objects2);
 if DebugDrawGabarites then begin
  emDrawGabarites(Canvas, Objects);
  emDrawGabarites(Canvas, Objects2);
 end;
end;

// отладка: габариты выделенных объектов (TPointDot, TDotText, TLot):
//  красный  - габарит объекта (точка - Sect, контур - XMin..XMax, YMin..YMax;
//             по нему - видимость и выбор);
//  зеленый  - границы картинки объекта в сцене (TogsSkiaObject.BoundsWorld);
//  синий    - прямоугольники надписей знака/блока (BlockTextBitmaps);
//  пурпурный - контур надписи TDotText (TextBitmap)
procedure TEditMap.emDrawGabarites(const Canvas: ISkCanvas; List: TSelectedObjects);
var I: Integer;
    Obj: TObject;
    PD: TPointDot;
    R: TSect;
    PenSect, PenScene: ISkPaint;
procedure DrawSect(const S: TSect; const Paint: ISkPaint);
begin
 Canvas.DrawRect(TRectF.Create(Min(S.Left, S.Right), Min(S.Top, S.Bottom), Max(S.Left, S.Right), Max(S.Top, S.Bottom)), Paint);
end;
begin
 if (Canvas = nil) or (List = nil) then exit;
 PenSect := SkPen(Canvas, TAlphaColorRec.Red, 1, False);
 PenScene := SkPen(Canvas, TAlphaColorRec.Lime, 1, True);
 for I := 0 to List.Count - 1 do begin
  Obj := TObject(List[I]);
 // контур: габарит и границы картинки в сцене
  if Obj is TLot then begin
   if TLot(Obj).XMin <= TLot(Obj).XMax then
    Canvas.DrawRect(TRectF.Create(TLot(Obj).XMin, TLot(Obj).YMin, TLot(Obj).XMax, TLot(Obj).YMax), PenSect);
   if TLot(Obj).DrawerObject is TogsSkiaObject then
    Canvas.DrawRect(TogsSkiaObject(TLot(Obj).DrawerObject).BoundsWorld, PenScene);
   continue;
  end;
  if not (Obj is TPointDot) then continue;
  PD := TPointDot(Obj);
  R := PD.Sect;
  DrawSect(R, PenSect);
  if PD.DrawerObject is TogsSkiaObject then
   Canvas.DrawRect(TogsSkiaObject(PD.DrawerObject).BoundsWorld, PenScene);
  if PD.BlockTextBitmaps <> nil then PD.BlockTextBitmaps.DrawSect(Canvas, TAlphaColorRec.Blue, TAlphaColorRec.Blue, 1);
  if (PD is TDotText) and (TDotText(PD).TextBitmap <> nil) then TDotText(PD).TextBitmap.DrawBounds(Canvas, TAlphaColorRec.Magenta, 1);
 end;
end;

function TEditMap.emGetObject(var X, Y: Double; var TypeLot: Byte; Shift: TShiftState): TTwgObject;
var Lot: TLot;
    I: Integer;
    X1, Y1: Double;
    PD: TPointDot;
    B: Byte;
// курсор внутри контура надписи (повернутые габариты Bounds): у TDotText -
// TextBitmap, у точки - надписи знака/блока (BlockTextBitmaps)
function TextHit(P: TPointDot): boolean;
begin
 Result := False;
 if (P is TDotText) and (TDotText(P).TextBitmap <> nil) and TDotText(P).TextBitmap.PointInB(X, Y) then exit(True);
 if (P.BlockTextBitmaps <> nil) and P.BlockTextBitmaps.PointInB(X, Y) then exit(True);
end;
function PointIn(K: Integer): boolean;
var Tw: TTwig;
    I: Integer;
    S: Double;
begin
 Result := False;
 for I := 0 to Lot.Coord.Count - 1 do begin
  Tw := Lot.GetTwig(Twigs.Twigs, I);
  if (Tw = nil) or not Tw.IsVisible(GRect) then continue;
  S := Tw.GetTwigDist(X, Y, X1, Y1);
  if XRasst(S) <= Twigs.Settings.psAutoDisst * K then exit(True);
 end;
end;
begin
 Result := nil;
 TypeLot := 0;
 if (Twigs.Twigs.TwigsCount = 1) and (Twigs.Twigs.AnyCount = 0) then exit;
// сначала привязка: точечный объект под курсором
 timerNoStarting := True;
 emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
 if (objTemporary <> nil) and (objTemporary is TPointDot) and TPointDot(objTemporary).isNoClosed then begin
  Result := objTemporary;
  X := TPointDot(objTemporary).XDot;
  Y := TPointDot(objTemporary).YDot;
  exit;
 end;
 if Marker.Visible then Marker.Remove(GCanvas);
// надпись или точка с надписями: захват по контуру надписи, а не только по
// расстоянию до точки вставки (на мобильных - касанием надписи); верхние - первыми
 for I := Twigs.Twigs.AnyCount - 1 downto 0 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if not (TObject(PD) is TPointDot) or not PD.isNoClosed then continue;
  if TextHit(PD) then begin
   X := PD.XDot;
   Y := PD.YDot;
   exit(PD);
  end;
 end;
// контур: площадной - точка внутри, линейный - курсор у линии
 for I := Twigs.Twigs.IndexCount - 1 downto 0 do begin
  Lot := Twigs.Twigs.LAtIndex(I);
  if (Lot.Closed = 0) or (Lot.TypeLot = 254) then continue;
  if not Lot.IsVisible(Selector.GPRect) then continue;
  if Lot.TypeLot = 2 then begin
   if Lot.PointIn(Twigs.Twigs, X, Y) then begin
    TypeLot := Lot.TypeLot;
    exit(Lot);
   end;
  end else if PointIn(1) then begin
   X := X1;
   Y := Y1;
   exit(Lot);
  end;
 end;
end;

procedure TEditMap.emAddSelectedObjects;
var Lot: TLot;
    I: Integer;
    invertSelect: boolean;
    PD: TPointDot;
    B: Byte;
    R: Double;
function GetLotInFrag: boolean;
var I, N: Integer;
begin
 N := 0;
 for I := 0 to Lot.Coord.Count - 1 do N := N + Ord(TwigMarkedPoints(Lot.GetTwig(Twigs.Twigs, I), fRect, nil, not invertSelect) <> 0);
 if invertSelect then Result := N <> 0 else Result := N = Lot.Coord.Count;
end;
begin
 Objects.Locked := True;
 try
 // рамка справа налево - выделяются и пересекающие ее объекты
  invertSelect := fRect.Right <= fRect.Left;
  if fRect.Right < fRect.Left then begin R := fRect.Right; fRect.Right := fRect.Left; fRect.Left := R; end;
  if fRect.Bottom < fRect.Top then begin R := fRect.Bottom; fRect.Bottom := fRect.Top; fRect.Top := R; end;
  for I := 0 to Twigs.Twigs.LotsCount - 1 do begin
   Lot := Twigs.Twigs.LAt(I);
   if (Lot.Closed <> 0) and (Lot.TypeLot <> 254) and Lot.isVisible(Selector.GPRect) then
    if GetLotInFrag and (Objects.IndexOf(Lot) = -1) then Objects.Insert(Lot);
  end;
  for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
   PD := Twigs.Twigs.AAt(I, B);
   if (B = TWG_Point) and PD.isNoClosed then
    if PD.PointInSect(fRect, invertSelect) and (Objects.IndexOf(PD) = -1) then Objects.Insert(PD);
  end;
 finally
  Objects.Locked := False;
  if Objects.Count > 0 then Objects.Update;
 end;
end;

procedure TEditMap.emAddSelectedObjectsPolygon;
var Lot: TLot;
    I: Integer;
    invertSelect: boolean;
    PD: TPointDot;
    B: Byte;
function GetRight: boolean;
var Angle, A1, A2: Double;
begin
 with mpTwig do begin
  A1 := Direct_Angle(Twig[0].XDot, Twig[0].YDot, Twig[Count - 2].XDot, Twig[Count - 2].YDot) * 180 / Pi;
  A2 := Direct_Angle(Twig[0].XDot, Twig[0].YDot, Twig[1].XDot, Twig[1].YDot) * 180 / Pi;
  Angle := A1 - A2;
  if Angle < 0 then Angle := 360 + Angle;
  Result := Round(Angle) = 270;
 end;
end;
function GetLotInFrag: boolean;
var I, N: Integer;
begin
 N := 0;
 for I := 0 to Lot.Coord.Count - 1 do N := N + Ord(TwigMarkedPoints(Lot.GetTwig(Twigs.Twigs, I), fRect, mpTwig.Twig.Coord, not invertSelect) <> 0);
 if invertSelect then Result := N <> 0 else Result := N = Lot.Coord.Count;
end;
begin
 Objects.Locked := True;
 try
  invertSelect := GetRight;
  for I := 0 to Twigs.Twigs.LotsCount - 1 do begin
   Lot := Twigs.Twigs.LAt(I);
   if (Lot.Closed <> 0) and (Lot.TypeLot <> 254) and Lot.isVisible(Selector.GPRect) then
    if GetLotInFrag and (Objects.IndexOf(Lot) = -1) then Objects.Insert(Lot);
  end;
  for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
   PD := Twigs.Twigs.AAt(I, B);
   if (B = TWG_Point) and PD.isNoClosed then
    if PD.PointInSect2(mpTwig.Twig.Coord, invertSelect) and (Objects.IndexOf(PD) = -1) then Objects.Insert(PD);
  end;
 finally
  Objects.Locked := False;
  if Objects.Count > 0 then Objects.Update;
 end;
end;

function TEditMap.emGetNearestPointsOnObjects(X, Y: Double): boolean;
begin
 Result := ObjectPoints.GetPoints(Objects.GeoObjects, X, Y) > 0;
end;

// после перемещения вершин (em_MoveObjectPoints): Modified := True и
// перестроение в сцене у всех объектов, участвовавших в перемещении:
//  - контуры с вершиной в старой точке (fActiveLots, собраны до SetXY), в том
//    числе невыделенные с общей ветвью;
//  - контуры с вершиной в новой точке (ветви, в которые вставлена точка);
//  - все контуры, использующие сдвинутые ветви (RootTwig - ветвь карты, Twig -
//    ее копия для предпросмотра);
//  - точечные объекты, блоки и тексты (selPoint без ветви).
// У контуров пересчитываются габариты: по ним строится BoundsWorld картинки
procedure TEditMap.emObjectPointsMoved;
var I, J: Integer;
    Lot: TLot;
    Moved: TDictionary<Pointer, Byte>;
    Changed: TList<TObject>;
procedure Add(Obj: TObject);
begin
 if (Obj <> nil) and (Changed.IndexOf(Obj) = -1) then Changed.Add(Obj);
end;
begin
 Moved := TDictionary<Pointer, Byte>.Create;
 Changed := TList<TObject>.Create;
 try
  emFilterActiveLot(X2, Y2);
  for I := 0 to fActiveLots.Count - 1 do Add(ActiveLot[I]);
  for I := 0 to ObjectPoints.selPoints.Count - 1 do
   if ObjectPoints.selPoint[I].RootTwig = nil then Add(ObjectPoints.selPoint[I].Dot) else Moved.AddOrSetValue(ObjectPoints.selPoint[I].RootTwig, 0);
  if Moved.Count > 0 then
   for I := 0 to Twigs.Twigs.LotsCount - 1 do begin
    Lot := Twigs.Twigs.LAt(I);
    for J := 0 to Lot.Coord.Count - 1 do
     if Moved.ContainsKey(Lot.GetTwig(Twigs.Twigs, J)) then begin
      Add(Lot);
      break;
     end;
   end;
  for I := 0 to Changed.Count - 1 do begin
   if Changed[I] is TLot then TLot(Changed[I]).SetMinMax(Twigs.Twigs);
   if Changed[I] is TTD then TTD(Changed[I]).Modified := True;
   SceneModified(Changed[I]);
  end;
 finally
  Moved.Free;
  Changed.Free;
 end;
end;

procedure TEditMap.SelectObjectByIndex(LotIndex_, AnyIndex_: Integer);
var I: Integer;
    PD: TPointDot;
    B: Byte;
begin
 for I := 0 to Twigs.Twigs.LotsCount - 1 do if I >= LotIndex_ then Objects.Insert(Twigs.Twigs.LAt(I));
 for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
  PD := Twigs.Twigs.AAt(I, B);
  if (B = TWG_Point) and (I >= AnyIndex_) then Objects.Insert(PD);
 end;
 SelectionChanged;
end;

procedure TEditMap.SelectAll;
var I: Integer;
    B: Byte;
begin
 for I := 0 to Twigs.Twigs.LotsCount - 1 do Objects.Insert(Twigs.Twigs.LAt(I));
 for I := 0 to Twigs.Twigs.AnyCount - 1 do Objects.Insert(Twigs.Twigs.AAt(I, B));
 SelectionChanged;
end;

procedure TEditMap.SelectAllObjects;
var I: Integer;
    B: Byte;
begin
 Objects.DeleteAll;
 for I := 0 to Twigs.Twigs.LotsCount - 1 do
  if TLot(Twigs.Twigs.LAt(I)).ClassHandle.Check = 1 then Objects.Insert(Twigs.Twigs.LAt(I));
 for I := 0 to Twigs.Twigs.AnyCount - 1 do
  if TPointDot(Twigs.Twigs.AAt(I, B)).ClassHandle.Check = 1 then Objects.Insert(Twigs.Twigs.AAt(I, B));
 SelectionChanged;
end;

{ команды меню выделенных объектов }

procedure TEditMap.DoCommand(Tag: Integer);
begin
 if not CommandEnabled(Tag) then exit;
 case Tag of
  em_SelectNone: begin
    Objects.DeleteAll;
    Marker.Remove(GCanvas);
    SelectionChanged;
    UpdateImage;
   end;
  em_SelectInvert: emInvertSelection;
  em_DeleteObjects: if Assigned(fOnDelete) then fOnDelete(nil) else emDeleteObjects;
 else
  StartOperation(Tag);
 end;
end;

// доступность пунктов меню (бывший FlyObjects.PMEditMapPopup)
function TEditMap.CommandEnabled(Tag: Integer): Boolean;
begin
 Result := False;
 if LOperation <> em_GetObject then exit;
 case Tag of
  em_SelectInvert: Result := True;
  em_SelectNone, em_DeleteObjects: Result := Objects.Count > 0;
 else
  Result := IsTransformOpr(Tag) and (Objects.Count > 0);
 end;
end;

// инверсия выбора (бывший FlyObjects.MIInvertSelectClick): выделяются все
// объекты, кроме выделенных
procedure TEditMap.emInvertSelection;
var I: Integer;
    B: Byte;
    Old: TDictionary<Pointer, Byte>;
    P: Pointer;
begin
 Old := TDictionary<Pointer, Byte>.Create;
 Objects.Locked := True;
 try
  for I := 0 to Objects.Count - 1 do Old.AddOrSetValue(Objects[I], 0);
  Objects.DeleteAll;
  for I := 0 to Twigs.Twigs.LotsCount - 1 do begin
   P := Twigs.Twigs.LAt(I);
   if not Old.ContainsKey(P) then Objects.Insert(P);
  end;
  for I := 0 to Twigs.Twigs.AnyCount - 1 do begin
   P := Twigs.Twigs.AAt(I, B);
   if not Old.ContainsKey(P) then Objects.Insert(P);
  end;
 finally
  Objects.Locked := False;
  Old.Free;
 end;
 Objects.Update;
 SelectionChanged;
 UpdateImage;
end;

// удаление выделенного с отменой (бывший FlyObjects.MIDeleteClick); в
// отличие от старой программы обработчик мыши не освобождается
procedure TEditMap.emDeleteObjects;
var I, Index: Integer;
    P: PCollection;
    Obj: TObject;
begin
 if Objects.Count = 0 then exit;
 P := PCollection.Create(1);
 try
  for I := 0 to Objects.Count - 1 do P.Insert(Objects[I]);
 // выделение снимается до удаления: DeleteAll обращается к объектам
  Objects.DeleteAll;
  Marker.Remove(GCanvas);
  Undo.StartTransAction;
  try
   Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_DeletedPrim, 'DeleteObjects...'));
   for I := 0 to P.Count - 1 do begin
    Obj := P[I];
    if Assigned(OnDeletePrim) and not OnDeletePrim(Obj) then continue;
    if Obj is TPointDot then Index := Twigs.Twigs.AnyLarge.IndexOf(Obj) else
    if Obj is TLot then Index := Twigs.Twigs.LotsLarge.IndexOf(Obj) else Index := -1;
    if Index = -1 then continue;
    TPrimUndo(Undo.Last).AddModifiedPrim(Obj);
   // картинка объекта убирается из сцены, пока объект еще существует
    Selector.UpdateImage(usmDelete, Obj);
    if Obj is TPointDot then Twigs.Twigs.DelAAt(Index) else Twigs.Twigs.AtDelete(TWG_Lot, Index);
   end;
   Undo.Commit;
  except
   on E: Exception do begin
    WriteIn(['emDeleteObjects exception ', E.Message]);
    Undo.RollBack;
   end;
  end;
 finally
  P.DeleteAll;
  P.Free;
 end;
 OrthoTwigs.Free;
 OrthoTwigs := TOrthoTwigs.Create;
 Modified;
// ветви удаленных контуров остаются без контура (Rang = 0) - упаковка
 Twigs.ClassBuildII;
 PackTwigs(False);
 SelectionChanged;
 UpdateImage;
end;

// упаковка коллекций после изменения объектов (как в старой программе).
// Перед вызовом обязателен Twigs.ClassBuildII: он выставляет Rang ветвей
// (0 - ветвь без контура). Pack физически удаляет ветви с Closed = 254 и
// Rang = 0, перенумеровывает TLong.Num в контурах и удаляет контуры без
// ветвей. После Pack индексы ветвей и ссылки на удаленные объекты
// недействительны, поэтому найденные вершины (ObjectPoints) сбрасываются
procedure TEditMap.PackTwigs(UseOnModified: Boolean);
begin
 if UseOnModified then Twigs.Pack(OnModifiedPrim) else Twigs.Pack(nil);
 ObjectPoints.Free;
 ObjectPoints := TNearestPoints.Create(Twigs);
end;

{ преобразование выделенного }

procedure TEditMap.StartOperation(Opr: Integer);
begin
 if (Objects.Count = 0) or not IsTransformOpr(Opr) then exit;
 if IsTransformOpr(LOperation) then EndTransform;
 LOperation := Opr;
 X1 := ZNull;
 X2 := ZNull;
 XO := xyNull;
 YO := xyNull;
 UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
 UpdateImage;
end;

procedure TEditMap.EndTransform;
begin
// DrawTwig зарегистрирована в OrthoTwigs - освобождаем до пересоздания
 if DrawTwig <> nil then FreeAndNil(DrawTwig);
 OrthoTwigs.Free;
 OrthoTwigs := TOrthoTwigs.Create;
 Marker.Remove(GCanvas);
 X1 := ZNull;
 X2 := ZNull;
 XO := xyNull;
 YO := xyNull;
 LOperation := em_GetObject;
 UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
 TimerClose;
 SelectionChanged;
 UpdateImage;
end;

procedure TEditMap.Return(Sender: TObject);
var Kx, Ky: Double;
begin
 case LOperation of
 // масштаб с коэффициентом из AccuDraw
  em_Scale:
   if TComponent(Sender).Tag = 6 then begin
    if Objects.Count = 0 then exit;
    if X1 = ZNull then begin
     MessageError('Укажите точку от которой будет выполняться масштабирование объекта, либо две точки для направления масштабирования ...');
     exit;
    end;
    fixKoef := GlobalAccuDraw.Koef;
    if (fixKoef <> xyNull) and (Abs(fixKoef) > 1E-6) then begin
     Kx := fixKoef;
     Ky := fixKoef;
     emModifyObjects('Scale_Objects...', procedure(Inverse: Boolean) begin if Inverse then emScaleObjects(X1, Y1, 1 / Kx, 1 / Ky) else emScaleObjects(X1, Y1, Kx, Ky); end);
     fixKoef := xyNull;
     GlobalAccuDraw.CR.IsChecked := False;
     EndTransform;
    end;
   end else inherited Return(Sender);
 // поворот на угол из AccuDraw
  em_ObjectRotate:
   if TComponent(Sender).Tag = 4 then begin
    fixAngle := GlobalAccuDraw.Angle;
    if fixAngle <> xyNull then begin
     if (X1 = ZNull) and (Objects.Count = 1) and (TObject(Objects[0]) is TPointDot) then begin
      X1 := TPointDot(Objects[0]).XDot;
      Y1 := TPointDot(Objects[0]).YDot;
     end;
     if X1 = ZNull then begin
      MessageError('Выберите точку, относительно которой будет произведен поворот объекта.');
      exit;
     end;
     emRotateCopyObjects(X1, Y1, fixAngle * Pi / 180);
     GlobalAccuDraw.CA.IsChecked := False;
     fixAngle := xyNull;
     EndTransform;
    end;
    GlobalAccuDraw.useLevels := False;
   end else inherited Return(Sender);
 else
  inherited Return(Sender);
 end;
end;

procedure TEditMap.ResetTwigOpr15;
var I, J: Integer;
    Lot: TLot;
begin
 for I := 0 to Objects.Count - 1 do
  if TObject(Objects[I]) is TLot then begin
   Lot := TLot(Objects[I]);
   for J := 0 to Lot.Coord.Count - 1 do Lot.GetTwig(Twigs.Twigs, J).Opr := 0;
  end;
end;

// сдвиг выделенного без отмены (Opr = 15 - ветвь, общая для нескольких
// выделенных контуров, уже сдвинута)
procedure TEditMap.emMoveObjects(Dx, Dy: Double);
var I, J, K: Integer;
    PD: TPointDot;
    Lot: TLot;
    Tw: TTwig;
begin
 try
  for I := 0 to Objects.Count - 1 do
   if TObject(Objects[I]) is TPointDot then begin
    PD := Objects[I];
    PD.XDot := PD.XDot + Dx;
    PD.YDot := PD.YDot + Dy;
   end else
   if TObject(Objects[I]) is TLot then begin
    Lot := Objects[I];
    for J := 0 to Lot.Coord.Count - 1 do begin
     Tw := Lot.GetTwig(Twigs.Twigs, J);
     if Tw.Opr <> 15 then begin
      Tw.Opr := 15;
      for K := 0 to Tw.Coord.Count - 1 do with TDot(Tw.Coord[K]) do begin
       XDot := XDot + Dx;
       YDot := YDot + Dy;
      end;
     end;
     Tw.Calculate;
    end;
    Lot.Move(Dx, Dy);
   end;
 finally
  ResetTwigOpr15;
 end;
end;

// поворот выделенного вокруг (XX, YY) без отмены
procedure TEditMap.emRotateObjects(XX, YY, Angle: Double);
var I, J, K: Integer;
    PD: TPointDot;
    Lot: TLot;
    Tw: TTwig;
    Col: PCollection;
    D: TDot;
begin
 try
  for I := 0 to Objects.Count - 1 do
   if TObject(Objects[I]) is TPointDot then begin
    PD := Objects[I];
    RotateXY(XX, YY, Angle, PD.XDot, PD.YDot);
    PD.Ugol := PD.Ugol + Angle;
   end else
   if TObject(Objects[I]) is TLot then begin
    Lot := Objects[I];
   // знаки и штриховки контура
    Col := PCollection.Create(1);
    Lot.RotationPoints(Col);
    for J := 0 to Col.Count - 1 do begin
     D := Col[J];
     RotateXY(XX, YY, Angle, D.XDot, D.YDot);
     if D is TPDot then TPDot(D).Ugol := TPDot(D).Ugol + Angle;
    end;
    Col.DeleteAll;
    Col.Free;
    for J := 0 to Lot.Coord.Count - 1 do begin
     Tw := Lot.GetTwig(Twigs.Twigs, J);
     if Tw.Opr = 15 then continue;
     Tw.Opr := 15;
     for K := 0 to Tw.Coord.Count - 1 do begin
      D := Tw.Coord[K];
      RotateXY(XX, YY, Angle, D.XDot, D.YDot);
     end;
    end;
   end;
 finally
  ResetTwigOpr15;
 end;
end;

// масштаб выделенного относительно (XX, YY) без отмены. Как в старой
// программе (emDrawScaleObject): у точечных объектов меняются XKoef/YKoef и
// размеры текста; коэффициенты здесь умножаются, а не присваиваются, чтобы
// операция была обратимой
procedure TEditMap.emScaleObjects(XX, YY, Kx, Ky: Double);
var I, J, K: Integer;
    PD: TPointDot;
    Lot: TLot;
    Tw: TTwig;
    Col: PCollection;
    TP: TTextParams;
    OldXK: Double;
procedure ScaleDot(D: TDot);
begin
 D.XDot := XX + (D.XDot - XX) * Kx;
 D.YDot := YY + (D.YDot - YY) * Ky;
end;
begin
 try
  for I := 0 to Objects.Count - 1 do
   if TObject(Objects[I]) is TLot then begin
    Lot := Objects[I];
    Col := PCollection.Create(1);
    Lot.RotationPoints(Col);
    for J := 0 to Col.Count - 1 do ScaleDot(Col[J]);
    Col.DeleteAll;
    Col.Free;
    for J := 0 to Lot.Coord.Count - 1 do begin
     Tw := Lot.GetTwig(Twigs.Twigs, J);
     if Tw.Opr = 15 then continue;
     Tw.Opr := 15;
     for K := 0 to Tw.Coord.Count - 1 do ScaleDot(Tw.Coord[K]);
    end;
   end else
   if TObject(Objects[I]) is TPointDot then begin
    PD := Objects[I];
    ScaleDot(PD);
    OldXK := PD.XKoef;
    PD.XKoef := PD.XKoef * Kx;
    PD.YKoef := PD.YKoef * Ky;
   // у текста (TDotText) - высота шрифта, ширина остается прежней
    PD.ChangeXYKoef(OldXK, Ky);
    if PD.TextManager <> nil then
     for J := 0 to PD.TextManager.FValues.Count - 1 do begin
      TP := PD.TextManager.FValues[J];
      TP.FW := TP.FW * Kx;
      TP.FH := TP.FH * Ky;
     end;
   end;
 finally
  ResetTwigOpr15;
 end;
end;

// отражение выделенного относительно прямой (XX1, YY1)-(XX2, YY2) без отмены
procedure TEditMap.emMirrorObjects(XX1, YY1, XX2, YY2: Double);
var I, J, K: Integer;
    PD: TPointDot;
    Lot: TLot;
    Tw: TTwig;
    Col: PCollection;
    D: TDot;
begin
 try
  for I := 0 to Objects.Count - 1 do
   if TObject(Objects[I]) is TPointDot then begin
    PD := Objects[I];
    MirrorXY(XX1, YY1, XX2, YY2, PD.XDot, PD.YDot);
    PD.Ugol := PD.Ugol + Pi;
   end else
   if TObject(Objects[I]) is TLot then begin
    Lot := Objects[I];
    Col := PCollection.Create(1);
    Lot.RotationPoints(Col);
    for J := 0 to Col.Count - 1 do begin
     D := Col[J];
     MirrorXY(XX1, YY1, XX2, YY2, D.XDot, D.YDot);
    end;
    Col.DeleteAll;
    Col.Free;
    for J := 0 to Lot.Coord.Count - 1 do begin
     Tw := Lot.GetTwig(Twigs.Twigs, J);
     if Tw.Opr = 15 then continue;
     Tw.Opr := 15;
     for K := 0 to Tw.Coord.Count - 1 do begin
      D := Tw.Coord[K];
      MirrorXY(XX1, YY1, XX2, YY2, D.XDot, D.YDot);
     end;
     Tw.Calculate;
    end;
    Lot.SetMinMax(Twigs.Twigs);
   end;
 finally
  ResetTwigOpr15;
 end;
end;

// изменение выделенных объектов с отменой (бывшие emMoveCopyObject,
// emRotateCopyObjects, emScaleCopyObject): Apply(False) - выполнить,
// Apply(True) - вернуть, если OnModifiedPrim отказал. Контуры, у которых
// общие ветви с выделенными, тоже попадают в отмену и перестраиваются в сцене
function TEditMap.emModifyObjects(const UndoName: String; Apply: TProc<Boolean>): Boolean;
var I, J: Integer;
    Lot: TLot;
    P, LotCol: PCollection;
    Changed: TList<TObject>;
    notModified: Boolean;
procedure AddChanged(Obj: TObject);
begin
 if (Obj <> nil) and (Changed.IndexOf(Obj) = -1) then Changed.Add(Obj);
end;
procedure Recalc;
var I: Integer;
begin
 for I := 0 to P.Count - 1 do TTwig(P[I]).Calculate;
 for I := 0 to Changed.Count - 1 do
  if Changed[I] is TLot then TLot(Changed[I]).SetMinMax(Twigs.Twigs);
end;
begin
 Result := False;
 if Objects.Count = 0 then exit;
 P := PCollection.Create(1);
 LotCol := PCollection.Create(1);
 Changed := TList<TObject>.Create;
 try
  Undo.StartTransAction;
  try
   Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_ModifiedPrim, UndoName));
   for I := 0 to Objects.Count - 1 do begin
    AddChanged(Objects[I]);
    if TObject(Objects[I]) is TPointDot then TPrimUndo(Undo.Last).AddModifiedPrim(Objects[I]) else
    if TObject(Objects[I]) is TLot then begin
     Lot := Objects[I];
     for J := 0 to Lot.Coord.Count - 1 do if P.IndexOf(Lot.GetTwig(Twigs.Twigs, J)) = -1 then P.Insert(Lot.GetTwig(Twigs.Twigs, J));
    end;
   end;
   for I := 0 to Twigs.Twigs.LotsCount - 1 do TLot(Twigs.Twigs.LAt(I)).CreateLotsView(Twigs.Twigs);
   Twigs.ModifiedTwigsUndo(P, LotCol, nil, True);
   for I := 1 to Twigs.Twigs.TwigsCount - 1 do TTwig(Twigs.Twigs.TAt(I)).FreeLotsView;
   for I := 0 to LotCol.Count - 1 do AddChanged(LotCol[I]);
   Apply(False);
   Recalc;
   notModified := False;
   if Assigned(OnModifiedPrim) then
    for I := 0 to Objects.Count - 1 do
     if not OnModifiedPrim(Objects[I]) then begin
      notModified := True;
      break;
     end;
   if notModified then begin
    Apply(True);
    Recalc;
    Undo.RollBack;
    exit;
   end;
   Undo.Commit;
   Modified;
   Twigs.ClassBuildII;
   for I := 0 to Changed.Count - 1 do SceneModified(Changed[I]);
  // как в старой программе: после операции выделение снимается, затем
  // упаковка (ClassBuildII уже выполнен выше)
   Objects.DeleteAll;
   PackTwigs(True);
   Result := True;
  except
   on E: Exception do begin
    WriteIn([UndoName, ' exception ', E.Message]);
    Undo.RollBack;
   end;
  end;
 finally
  P.DeleteAll;
  P.Free;
  LotCol.DeleteAll;
  LotCol.Free;
  Changed.Free;
 end;
end;

procedure TEditMap.emMoveCopyObject(Dx, Dy: Double);
begin
 emModifyObjects('Move_Objects...', procedure(Inverse: Boolean) begin if Inverse then emMoveObjects(-Dx, -Dy) else emMoveObjects(Dx, Dy); end);
end;

procedure TEditMap.emRotateCopyObjects(XX, YY, Angle: Double);
begin
 if fixAngle <> xyNull then Angle := fixAngle * Pi / 180;
 emModifyObjects('Rotate_Objects...', procedure(Inverse: Boolean) begin if Inverse then emRotateObjects(XX, YY, -Angle) else emRotateObjects(XX, YY, Angle); end);
end;

procedure TEditMap.emScaleCopyObject(XX1, YY1: Double);
var Kx, Ky: Double;
begin
 if not emScaleKoef(XX1, YY1, Kx, Ky) then exit;
 emModifyObjects('Scale_Objects...', procedure(Inverse: Boolean) begin if Inverse then emScaleObjects(X1, Y1, 1 / Kx, 1 / Ky) else emScaleObjects(X1, Y1, Kx, Ky); end);
end;

// копии выделенных объектов (бывший Copy старой программы); ветви копий
// контуров сразу добавляются в Twigs.Twigs
function TEditMap.emCloneObjects: TSelectedObjects;
var I, J: Integer;
    Lot: TLot;
    Src: TTwig;
    Tw: TTwig;
    Num: Integer;
begin
 Result := TSelectedObjects.Create(Twigs, nil);
 Result.Locked := True;
 for I := 0 to Objects.Count - 1 do
  if TObject(Objects[I]) is TPointDot then
   Result.Insert(TPointClass(TObject(Objects[I]).ClassType).CreateAsPointDot_(Objects[I], True))
  else
  if TObject(Objects[I]) is TLot then begin
   Lot := TLotClass(TObject(Objects[I]).ClassType).CreateAsLotWithAll(Objects[I]);
   for J := 0 to Lot.Coord.Count - 1 do begin
    Num := TLong(Lot.Coord[J]).Num;
    Src := Lot.GetTwig(Twigs.Twigs, J);
    Tw := TTwigClass(Src.ClassType).CreateAsTwig(Src, True);
    Tw.Calculate;
    Twigs.Twigs.Insert(TWG_Twig, Tw);
   // знак номера - направление обхода ветви в контуре
    if Num < 0 then TLong(Lot.Coord[J]).Num := -(Twigs.Twigs.TwigsCount - 1) else TLong(Lot.Coord[J]).Num := Twigs.Twigs.TwigsCount - 1;
   end;
   Lot.SetMinMax(Twigs.Twigs);
   Result.Insert(Lot);
  end;
end;

// добавление копий в карту с отменой (бывший emAddCopyObject); копии, которые
// не принял OnAddPrim, удаляются. Выделение - добавленные копии
function TEditMap.emAddCopyObjects(Copies: TSelectedObjects): Boolean;
var I, J: Integer;
    Obj: TObject;
    Added, Rejected: PCollection;
    Live: TDictionary<Pointer, Byte>;
begin
 Result := False;
 Added := PCollection.Create(1);
 Rejected := PCollection.Create(1);
 try
  Undo.StartTransAction;
  try
   Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'CopyObjects...'));
   for I := 0 to Copies.Count - 1 do begin
    Obj := TObject(Copies[I]);
    if Obj is TLot then TLot(Obj).SetMinMax(Twigs.Twigs);
    if not Assigned(OnAddPrim) or OnAddPrim(Obj) then begin
     TPrimUndo(Undo.Last).AddModifiedPrim(Obj);
     if Obj is TPointDot then Twigs.Twigs.Insert(TWG_Point, Obj) else begin
      Twigs.Twigs.Insert(TWG_Lot, Obj);
      TLot(Obj).SetFromTwig(Twigs.Twigs);
      TLot(Obj).SetMinMax(Twigs.Twigs);
     end;
     Added.Insert(Obj);
    end else begin
    // ветви непринятой копии помечаются удаленными
     if Obj is TLot then for J := 0 to TLot(Obj).Coord.Count - 1 do TLot(Obj).GetTwig(Twigs.Twigs, J).Closed := 254;
     Rejected.Insert(Obj);
    end;
   end;
   Undo.Commit;
   Result := True;
  except
   on E: Exception do begin
    WriteIn(['emAddCopyObjects exception ', E.Message]);
    Undo.RollBack;
   end;
  end;
  Copies.DeleteAll;
  Copies.Free;
  Rejected.FreeAll;
  if Added.Count > 0 then Modified;
 // упаковка: ветви непринятых копий (Closed = 254) удаляются, индексы
 // ветвей в контурах перенумеровываются
  Twigs.ClassBuildII;
  PackTwigs(True);
 // Pack мог удалить контур копии - в сцену и выделение идут только оставшиеся
 // (удаленный объект уже освобожден, поэтому сверка только по указателю)
  Live := TDictionary<Pointer, Byte>.Create;
  try
   for I := 0 to Twigs.Twigs.LotsCount - 1 do Live.AddOrSetValue(Twigs.Twigs.LAt(I), 0);
   for I := 0 to Twigs.Twigs.AnyCount - 1 do Live.AddOrSetValue(Twigs.Twigs.AnyLarge[I], 0);
   for I := Added.Count - 1 downto 0 do
    if not Live.ContainsKey(Added[I]) then Added.AtDelete(I);
  finally
   Live.Free;
  end;
  for I := 0 to Added.Count - 1 do Selector.UpdateImage(usmAdd, Added[I]);
  Objects.Locked := True;
  try
   Objects.DeleteAll;
   for I := 0 to Added.Count - 1 do Objects.Insert(Added[I]);
  finally
   Objects.Locked := False;
   if Objects.Count > 0 then Objects.Update;
  end;
 finally
  Added.DeleteAll;
  Added.Free;
  Rejected.Free;
 end;
end;

// копия выделенного со сдвигом
procedure TEditMap.emCopyObjects(Dx, Dy: Double);
var Copies, Save: TSelectedObjects;
begin
 Copies := emCloneObjects;
 Save := Objects;
 Objects := Copies;
 try
  emMoveObjects(Dx, Dy);
 finally
  Objects := Save;
 end;
 emAddCopyObjects(Copies);
end;

// отраженная копия выделенного; затем - сдвиг этой копии (как в старой программе)
procedure TEditMap.emMirrorCopyObjects(XX1, YY1, XX2, YY2: Double);
var Copies, Save: TSelectedObjects;
begin
 Copies := emCloneObjects;
 Save := Objects;
 Objects := Copies;
 try
  emMirrorObjects(XX1, YY1, XX2, YY2);
 finally
  Objects := Save;
 end;
 emAddCopyObjects(Copies);
 if DrawTwig <> nil then FreeAndNil(DrawTwig);
 OrthoTwigs.Free;
 OrthoTwigs := TOrthoTwigs.Create;
 X1 := ZNull;
 X2 := ZNull;
 XO := xyNull;
 YO := xyNull;
 if Objects.Count = 0 then begin
  EndTransform;
  exit;
 end;
 LOperation := em_ObjectMove;
 UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
 SelectionChanged;
 UpdateImage;
end;

// угол поворота: от направления (X1,Y1)-(X2,Y2) к (X1,Y1)-(XO,YO); у
// единственного точечного объекта (XO = xyNull) - направление (X1,Y1)-(X2,Y2)
function TEditMap.emRotateAngle: Double;
begin
 if fixAngle <> xyNull then exit(fixAngle * Pi / 180);
 if XO = xyNull then Result := Direct_Angle(-Y1, X1, -Y2, X2) else Result := Direct_Angle(-Y1, X1, -YO, XO) - Direct_Angle(-Y1, X1, -Y2, X2);
end;

// коэффициенты масштаба: базовая точка (X1,Y1), точка направления (X2,Y2)
// переходит в (XX1,YY1)
function TEditMap.emScaleKoef(XX1, YY1: Double; out Kx, Ky: Double): Boolean;
begin
 if Abs(X2 - X1) > 1E-9 then Kx := (XX1 - X1) / (X2 - X1) else Kx := 1;
 if Abs(Y2 - Y1) > 1E-9 then Ky := (YY1 - Y1) / (Y2 - Y1) else Ky := 1;
 Result := (Abs(Kx) > 1E-6) and (Abs(Ky) > 1E-6);
end;

// предварительный вид преобразования: готовые картинки объектов сцены
// с матрицей M, залитые белым в отдельном слое (live-слой смешивается со
// сценой в режиме Difference - аналог R2_Not старой программы)
procedure TEditMap.emDrawTransform(const Canvas: ISkCanvas);
var M: TMatrix;
    Pen: ISkPaint;
    Angle, Kx, Ky, XC, YC, L: Double;
procedure Line(XA, YA, XB, YB: Double);
begin
 SkDrawLineClipped(Canvas, XA, YA, XB, YB, Pen);
end;
function PictureOf(Obj: TObject): ISkPicture;
begin
 Result := nil;
 if (Obj is TTD) and (TTD(Obj).DrawerObject is TogsSkiaObject) then Result := TogsSkiaObject(TTD(Obj).DrawerObject).Pictures[LOD1_INDEX];
end;
procedure DrawObjects;
var I, J: Integer;
    Obj: TObject;
    R, B: TRectF;
    HasPic, HasBounds, FullLayer: Boolean;
    W: Single;
    Paint: ISkPaint;
begin
 HasPic := False;
 HasBounds := False;
 FullLayer := False;
 for I := 0 to Objects.Count - 1 do begin
  Obj := TObject(Objects[I]);
  if PictureOf(Obj) = nil then continue;
  HasPic := True;
  B := TogsSkiaObject(TTD(Obj).DrawerObject).BoundsWorld;
  if (B.Right < B.Left) or (B.Bottom < B.Top) then begin
   FullLayer := True;
   continue;
  end;
  B := MapRect(M, B);
  if HasBounds then begin
   R.Left := Min(R.Left, B.Left);
   R.Top := Min(R.Top, B.Top);
   R.Right := Max(R.Right, B.Right);
   R.Bottom := Max(R.Bottom, B.Bottom);
  end else R := B;
  HasBounds := True;
 end;
 if HasPic then begin
 // габариты слоя - объединение габаритов объектов после преобразования
 // (с запасом на толщину линий)
  if FullLayer or not HasBounds then R := Canvas.GetLocalClipBounds else begin
   W := SkPixToWorld(Canvas, 8);
   R.Inflate(W, W);
  end;
  Canvas.SaveLayer(R, nil);
  try
   for I := 0 to Objects.Count - 1 do
    if PictureOf(TObject(Objects[I])) <> nil then Canvas.DrawPicture(PictureOf(TObject(Objects[I])), M);
   Paint := TSkPaint.Create;
   Paint.Color := TAlphaColorRec.White;
   Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcIn);
   Canvas.DrawPaint(Paint);
  finally
   Canvas.Restore;
  end;
 end;
// контуры без готовой картинки - ветвями
 Canvas.Save;
 try
  Canvas.Concat(M);
  for I := 0 to Objects.Count - 1 do begin
   Obj := TObject(Objects[I]);
   if (Obj is TLot) and (PictureOf(Obj) = nil) then
    for J := 0 to TLot(Obj).Coord.Count - 1 do SkDrawTwig(Canvas, TLot(Obj).GetTwig(Twigs.Twigs, J), Pen);
  end;
 finally
  Canvas.Restore;
 end;
end;
begin
 if (Canvas = nil) or (Objects.Count = 0) then exit;
 Pen := SkPen(Canvas, TAlphaColorRec.White, 1, True);
 case LOperation of
  em_Copy, em_ObjectMove: begin
    if X1 = ZNull then exit;
    Line(X1, Y1, X2, Y2);
    M := TMatrix.CreateTranslation(X2 - X1, Y2 - Y1);
   end;
  em_ObjectRotate90, em_ObjectRotate180, em_ObjectRotate270: begin
    if XO = xyNull then exit;
    XC := XO;
    YC := YO;
    Angle := (LOperation - em_ObjectRotate) * Pi / 180;
    if fixAngle <> xyNull then Angle := fixAngle * Pi / 180;
    M := AffineMatrix(XC, YC, procedure(var X, Y: Double) begin RotateXY(XC, YC, Angle, X, Y); end);
   end;
  em_ObjectRotate: begin
    if X1 = ZNull then exit;
    if X2 = ZNull then begin
     if XO <> xyNull then Line(X1, Y1, XO, YO);
     exit;
    end;
    Line(X1, Y1, X2, Y2);
    if XO <> xyNull then Line(X1, Y1, XO, YO);
    XC := X1;
    YC := Y1;
    Angle := emRotateAngle;
    M := AffineMatrix(XC, YC, procedure(var X, Y: Double) begin RotateXY(XC, YC, Angle, X, Y); end);
   end;
  em_Mirror: begin
    if (X1 = ZNull) or (XO = xyNull) then exit;
    L := Distance(X1, Y1, XO, YO);
    if L <= 0.001 then exit;
   // ось отражения - прямая через две точки
    L := 1E6 / L;
    Line(X1 - (XO - X1) * L, Y1 - (YO - Y1) * L, XO + (XO - X1) * L, YO + (YO - Y1) * L);
    XC := X1;
    YC := Y1;
    Kx := XO;
    Ky := YO;
    M := AffineMatrix(XC, YC, procedure(var X, Y: Double) begin MirrorXY(XC, YC, Kx, Ky, X, Y); end);
   end;
  em_Scale: begin
    if X1 = ZNull then exit;
    if X2 = ZNull then begin
     if XO <> xyNull then Line(X1, Y1, XO, YO);
     exit;
    end;
    Line(X1, Y1, X2, Y2);
    Line(X1, Y1, XO, YO);
    if not emScaleKoef(XO, YO, Kx, Ky) then exit;
    M := TMatrix.Identity;
    M.m11 := Kx;
    M.m22 := Ky;
    M.m31 := X1 - X1 * Kx;
    M.m32 := Y1 - Y1 * Ky;
   end;
 else
  exit;
 end;
 DrawObjects;
end;

end.
