unit objMouseDraw32;

// Перенос модуля objMouseDraw из Geomaster (Delphi 7, GDI): отрисовка
// примитивов во время создания (линия, полилиния, сплайн, дуги, окружность,
// прямоугольник, паралиния, правильный многоугольник).
// Обработчики мыши, таймер фиксации и клавиатура только меняют состояние
// (mpTwig, fixPoint1/2, OrthoTwigs) и вызывают UpdateImage (перерисовку
// live-слоя); все рисуется в DrawTemp. Новые примитивы добавляются в сцену
// через Selector.UpdateImage(usmAdd, ...).
// Новые примитивы получают свойства по умолчанию из редактора свойств
// (PropEditorForm.ApplyDefaults).
// Не перенесено: диалог выбора слоя (psQueryLayerDraw) - берется активный слой,
// форма LayerPolygon, растровый контур TRectLot.

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     FMX.Types, FMX.Graphics, FMX.Forms, objMouse32, objMouseSelect32,
     drawTwigs32, Collect, WpTwigs, WpArcs, WptForm2, mpMarker, EcLot;

// корневой объект для отрисовки примитивов во время создания,
// редактирования, одиночного и группового выделения

const
 SysDrawPoint = 10010;
 SysDrawLine = 10011;
 SysDrawLine2 = 100111;
 SysDrawPoly = 10012;
 SysDrawSpline = 10013;
 SysDrawArc = 10014;
 SysDrawCircle = 10015;
 SysDrawRect = 10016;
 SysDrawParaLine = 10017;
 SysLine = 10018;
 sysDrawKvant = 10019;
 sysDrawMultiLine = 10020;
 sysDrawArc2 = 10021;
 sysDrawArc3 = 10022;
 em_MovePoint = 501;
// MergedOperations
 sysDrawRastr = 1;

type
 TMousePainter = class (TMouseSelector)
  private
   fOnCreateLine: TNotifyEvent;
   function GetHatchTwig(Index: Integer): TTwig;
  public
   X0, Y0: Double;
   fixLength: Double;
   fixAngle: Double;
   fixBlock: Double;
   fixKoef: Double;
   arcfixLength: Double;
   arcfixRadius: Double;
   circfixRadius: Double;
   Stvor_: TStvorLine;
   ftwigStyle: Integer;
   fixPoint1: TMarker;
   fixPoint2: TMarker;
   fixDistance: Double;
   objTmp: Pointer;
   fixTimer: TTimer;
   PathMarker: TPathMarker;
  //
   cirKvant: Integer;
  //
   timerNoStarting: Boolean;
  //
   isMultiline: Boolean;
   LockedMultiLine: Boolean;
   LastPrim: Pointer;
   MultiLot: TLot;
   MergedOpr: Integer;
   HatchLot: PCollection;
  // значения панели параметров (AccuDraw главной формы): длина/радиус/сторона,
  // угол, ширина параллельной линии, многоугольник от центра (0) или от
  // отрезка (1); FAccuTag - Tag для Return
   accDistance: Double;
   accAngle: Double;
   accKoef: Double;
   accDirectAngle: Boolean;
   accIncrement: Boolean;
   fParaWidth: Double;
   kvantStyle: Integer;
   FAccuTag: TComponent;
   Procedure ApplyAccuValue;
   Procedure ClearAccuValue;
  // удаление последней точки рисуемого примитива (Z, кнопка «↶» панели);
  // последняя точка или фигура целиком - примитив снимается
   Procedure DeleteLastPoint;
   Procedure AccuUndoPoint(Sender: TObject);
  // сброс привязок (X, кнопка «X» панели): точка залипания и направляющие от
  // нее, маркер привязки
   Procedure ClearSnaps;
  // направляющие от точки залипания: оси 0/90/180/270 и направления линий,
  // проходящих через точку (с перпендикулярами), кроме окружностей и дуг
   Procedure AddSnapGuides(X, Y: Double);
   Procedure AccuClearSnaps(Sender: TObject);
   Procedure ShowAccuDraw;
   Procedure AccuDrawEnter(Sender: TObject);
   Procedure AccuDrawChange(Sender: TObject);
   Procedure AccuReturn(Tag: Integer);
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  //
   Function mpTwigVisible: Boolean;
   Procedure mpDrawTwig(const Canvas: ISkCanvas);
   Procedure CreateTwig(TwigClass: TTwigClass = nil);
   Procedure CreateTwigAs(Twig_: TTwig);
  //
   Function isKeyDownCheck: boolean; virtual;
   Procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure mpCreatePrim(Form: TForm2; itsEndOfMultiLine: boolean = false);
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  //
   Procedure mpUpdateTwigPath(X, Y: Double); // создает сегмент или вставляет в него точку
   Procedure mpMoveTwigPath(X, Y: Double);
   Procedure Return(Sender: TObject); override;
   Procedure SetCur(CurName: String); override;
   function GetTwigStyle: Integer;
   procedure SetTwigStyle(const Value: Integer);
   Property twigStyle: Integer read GetTwigStyle write SetTwigStyle;
  //
   Function CanDoUndo: Boolean; override;
  //
   Procedure UpdateFixedPoints(X, Y: Double);
   Procedure DrawFixedPoints(const Canvas: ISkCanvas);
   Procedure OnTimer(Sender: TObject);
   Procedure TimerOpen; override;
   Procedure TimerClose; override;
  //
   Procedure MakeHatchLot;
   Procedure DrawHatchLot(const Canvas: ISkCanvas);
   Property HatchTwig[Index: Integer]: TTwig read GetHatchTwig;
   Property onCreateLine2: TNotifyEvent read fOnCreateLine write fOnCreateLine;
  //
   Function Hint: String; override;
  // перпендикуляр - и от точки залипания (первым), затем от последней точки
   Function GetPerpendBase(Index: Integer; out X, Y: Double): Boolean; override;
  // линия, полилиния, параллельная линия, точки: контур из поставленных точек
   Function DrawnFixedTwig: TTwig; override;
 end;

implementation

uses Math, EcDot, GBFWUndo, UndoColNew, maths_basic, newClassBuilder, newBlock, FramePropEditor,
     newForm0, newResource, newSettings, newSelector, WpRects,
     FrameParaLine, newProcs, Writer, Selector32, System.Diagnostics, FMX.StdCtrls, instAccuDraw;

{ TMousePainter }

// панель параметров операции рисования (AccuDraw главной формы): элементы по
// операции, начальные значения (ширина, сторона параллельной линии, число
// сторон и построение многоугольника); прячется в деструкторе
procedure TMousePainter.ShowAccuDraw;
begin
 if AccuDrawPanel = nil then exit;
 case LOperation of
  sysDrawLine, sysDrawLine2, sysDrawPoint, sysDrawPoly, sysDrawSpline: AccuDrawPanel.Show(['Длина'], [TButton]);
  sysDrawCircle: AccuDrawPanel.Show(['Длина', 'Радиус'], [TButton, TButton]);
  sysDrawParaLine: AccuDrawPanel.Show(['Длина', 'Ширина', 'Слева', 'Справа', 'По центру'], [TButton, TButton, TRadioButton, TRadioButton, TRadioButton]);
  sysDrawKvant: AccuDrawPanel.Show(['Длина', 'Сторон', 'от центра', 'от отрезка'], [TButton, TButton, TRadioButton, TRadioButton]);
  sysDrawRect: AccuDrawPanel.Show(['Сторона'], [TButton]);
 else
  exit;
 end;
 AccuDrawPanel.ShownBy := Self;
 AccuDrawPanel.OnEnter := AccuDrawEnter;
 AccuDrawPanel.OnChange := AccuDrawChange;
 AccuDrawPanel.OnUndoPoint := AccuUndoPoint;
 AccuDrawPanel.OnClearSnaps := AccuClearSnaps;
 case LOperation of
  sysDrawParaLine: begin
    AccuDrawPanel.Values['Ширина'] := FloatToStr(fParaWidth, TFormatSettings.Invariant);
    case twigStyle of
     hsLeft: AccuDrawPanel.Values['Слева'] := 'True';
     hsRight: AccuDrawPanel.Values['Справа'] := 'True';
    else
     AccuDrawPanel.Values['По центру'] := 'True';
    end;
   end;
  sysDrawKvant: begin
    AccuDrawPanel.Values['Сторон'] := IntToStr(cirKvant);
    if kvantStyle = 0 then AccuDrawPanel.Values['от центра'] := 'True' else AccuDrawPanel.Values['от отрезка'] := 'True';
   end;
 end;
 WriteIn(['AccuDraw.Show op=', LOperation, ' vis=', AccuDrawPanel.Visible, ' H=', AccuDrawPanel.Height, ' Y=', AccuDrawPanel.Position.Y,
  ' parent=', AccuDrawPanel.Parent <> nil]);
end;

// Enter на панели или клавиатуре: точка сразу на заданном расстоянии (Return
// старой формы AccuDraw), затем значение очищается (ClearAccuValue)
procedure TMousePainter.AccuDrawEnter(Sender: TObject);
var N: String;
    V: Double;
begin
 if AccuDrawPanel = nil then exit;
 N := AccuDrawPanel.NameOf(Sender);
 if not AccuDrawPanel.FloatValue(N, V) then begin
  if Trim(AccuDrawPanel.Values[N]) <> '' then MessageError('Задайте число');
  exit;
 end;
 if (N = 'Длина') or (N = 'Радиус') or (N = 'Сторона') then begin
  accDistance := V;
  AccuReturn(1);
  ClearAccuValue;
 end else
 if N = 'Ширина' then begin
  if V <= 0 then exit;
  fParaWidth := V;
  GWriteFloat('ParaLine_Width', V);
  if mpTwig <> nil then begin
   mpTwig.Width := V;
   mpTwig.Calculate;
   UpdateImage;
  end;
 end else
 if N = 'Сторон' then begin
  if Round(V) < 3 then exit;
  cirKvant := Round(V);
  GWriteInteger('LayerPolygon_SE', cirKvant);
  AccuReturn(21);
 end;
end;

// изменено значение (ввод, очистка кнопки) - сразу в построение; переключатели:
// сторона параллельной линии, построение многоугольника
procedure TMousePainter.AccuDrawChange(Sender: TObject);
var N: String;
    V: Double;
begin
 if AccuDrawPanel = nil then exit;
 N := AccuDrawPanel.NameOf(Sender);
 if Sender is TButton then begin
  if not AccuDrawPanel.FloatValue(N, V) then V := xyNull;
  if (N = 'Длина') or (N = 'Радиус') or (N = 'Сторона') then begin
   if (V <> xyNull) and (V <= 0) then V := xyNull;
   accDistance := V;
   ApplyAccuValue;
  end else
  if (N = 'Ширина') and (V <> xyNull) and (V > 0) then begin
   fParaWidth := V;
   GWriteFloat('ParaLine_Width', V);
   if mpTwig <> nil then begin
    mpTwig.Width := V;
    mpTwig.Calculate;
    UpdateImage;
   end;
  end else
  if (N = 'Сторон') and (V <> xyNull) and (Round(V) >= 3) then begin
   cirKvant := Round(V);
   GWriteInteger('LayerPolygon_SE', cirKvant);
   AccuReturn(21);
  end;
  exit;
 end;
 if not (Sender is TRadioButton) then exit;
 if N = 'Слева' then twigStyle := hsLeft else
 if N = 'Справа' then twigStyle := hsRight else
 if N = 'По центру' then twigStyle := hsCenter else
 if (N = 'от центра') or (N = 'от отрезка') then begin
  kvantStyle := Ord(N = 'от отрезка');
  GWriteInteger('LayerPolygon_Style', kvantStyle);
  AccuReturn(21);
  exit;
 end else
  exit;
 GWriteInteger('ParaLineForm_lbHotSpot', twigStyle - hsLeft);
end;

// значение «Длина»/«Радиус»/«Сторона» действует, пока задано на панели
// (очищается нажатием на кнопку и после установки точки - ClearAccuValue):
// при точке
// залипания (fixPoint1) - расстояние от нее (fixDistance, точка fixPoint2),
// иначе - длина отрезка (fixLength; окружность, многоугольник - радиус).
// Мышь задает только направление. Вызывается при изменении значения, после
// установки точки и при появлении точки залипания (OnTimer)
// по точкам удаляются линия, полилиния, параллельная линия, сплайн, точки;
// окружность, многоугольник, прямоугольник, дуга задаются целиком - снимаются
procedure TMousePainter.DeleteLastPoint;
var ByPoints: Boolean;
begin
 if mpTwig = nil then exit;
 ByPoints := (LOperation = sysLine) or (LOperation = sysDrawPoly) or (LOperation = sysDrawParaLine) or
             (LOperation = sysDrawLine) or (LOperation = sysDrawLine2) or (LOperation = sysDrawSpline) or
             (LOperation = sysDrawPoint);
 if ByPoints and (mpTwig.Twig.Coord.Count > 1) then begin
 // DeletePoint удаляет точку только у TTwig (сплайн - здесь), затем пересчет
  if mpTwig.Twig.ClassName <> 'TTwig' then mpTwig.Twig.Coord.AtFree(mpTwig.Twig.Coord.Count - 1);
  mpTwig.DeletePoint(GCanvas);
  OrthoTwigs.UpdateTwigs;
 end else begin
  OrthoTwigs.Pack('');
  mpTwig.Free;
  mpTwig := nil;
 end;
 UpdateImage;
end;

function TMousePainter.DrawnFixedTwig: TTwig;
begin
 Result := nil;
 if (mpTwig = nil) or (mpTwig.Twig = nil) or (mpTwig.Twig.ClassName <> 'TTwig') then exit;
 if (LOperation = sysLine) or (LOperation = sysDrawPoly) or (LOperation = sysDrawParaLine) or
    (LOperation = sysDrawLine) or (LOperation = sysDrawLine2) or (LOperation = sysDrawPoint) then Result := mpTwig.Twig;
end;

function TMousePainter.GetPerpendBase(Index: Integer; out X, Y: Double): Boolean;
begin
 if (fixPoint1 <> nil) and fixPoint1.Visible then begin
  if Index = 0 then begin
   X := fixPoint1.mX;
   Y := fixPoint1.mY;
   exit(True);
  end;
  Result := inherited GetPerpendBase(Index - 1, X, Y);
 end else
  Result := inherited GetPerpendBase(Index, X, Y);
end;

procedure TMousePainter.AccuUndoPoint(Sender: TObject);
begin
 DeleteLastPoint;
end;

// значение расстояния панели после сброса - длина отрезка (точки залипания нет)
procedure TMousePainter.ClearSnaps;
begin
 TimerClose;
 fixPoint1.Remove(GCanvas);
 fixPoint2.Remove(GCanvas);
 fixDistance := xyNull;
 OrthoTwigs.Pack('fixPoint');
 Marker.Remove(GCanvas);
 TemporaryDot.What := tdNotUsed;
 if accDistance <> xyNull then ApplyAccuValue;
 UpdateImage;
end;

procedure TMousePainter.AddSnapGuides(X, Y: Double);
const Eps = 1E-3;
var Angles: array of Double;
    I: Integer;
procedure AddTwig(Tw: TTwig);
var J: Integer;
    D1, D2: TDot;
    L, T, DX, DY, PX, PY: Double;
begin
 if (Tw = nil) or (Tw is TTwigCircle) or (Tw is TTwigArc) or (Tw.Coord.Count < 2) then exit;
 if (X < Tw.XMin - Eps) or (X > Tw.XMax + Eps) or (Y < Tw.YMin - Eps) or (Y > Tw.YMax + Eps) then exit;
 for J := 1 to Tw.Coord.Count - 1 do begin
  D1 := Tw[J - 1];
  D2 := Tw[J];
  DX := D2.XDot - D1.XDot;
  DY := D2.YDot - D1.YDot;
  L := DX * DX + DY * DY;
  if L < 1E-12 then continue;
 // расстояние от точки до отрезка
  T := ((X - D1.XDot) * DX + (Y - D1.YDot) * DY) / L;
  if T < 0 then T := 0 else if T > 1 then T := 1;
  PX := D1.XDot + T * DX - X;
  PY := D1.YDot + T * DY - Y;
  if PX * PX + PY * PY > Eps * Eps then continue;
 // угол направляющих: направление (cos, -sin) - отсюда минус
  if Length(Angles) >= 9 then exit;
  SetLength(Angles, Length(Angles) + 1);
  Angles[High(Angles)] := -ArcTan2(DY, DX);
 end;
end;
begin
 SetLength(Angles, 1);
 Angles[0] := 0;
 for I := 1 to Twigs.Twigs.TwigsCount - 1 do
  if TTwig(Twigs.Twigs.TAt(I)).Closed = 1 then AddTwig(Twigs.Twigs.TAt(I));
 AddTwig(DrawnFixedTwig);
 OrthoTwigs.AddPointGuides(X, Y, Angles, 'fixPoint');
end;

procedure TMousePainter.AccuClearSnaps(Sender: TObject);
begin
 ClearSnaps;
end;

// точка поставлена (левая/правая кнопка, Enter): значение расстояния
// отработало - кнопка панели очищается, рисование без фиксации
procedure TMousePainter.ClearAccuValue;
var P: TInstAccuDrawFrame;
begin
 accDistance := xyNull;
 P := AccuDrawPanel(False);
 if (P <> nil) and (P.ShownBy = Self) then begin
  P.Values['Длина'] := '';
  P.Values['Радиус'] := '';
  P.Values['Сторона'] := '';
 end;
 ApplyAccuValue;
end;

procedure TMousePainter.ApplyAccuValue;
begin
 if fixPoint1.Visible then begin
  fixDistance := accDistance;
  fixLength := xyNull;
 end else begin
  fixDistance := xyNull;
  fixLength := accDistance;
 end;
 if (LOperation = sysDrawCircle) or (LOperation = sysDrawKvant) then circfixRadius := fixLength;
 if mpTwig <> nil then mpTwig.SetLength(GCanvas, fixLength);
 UpdateFixedPoints(fixPoint2.mX, fixPoint2.mY);
 UpdateImage;
end;

procedure TMousePainter.AccuReturn(Tag: Integer);
begin
 FAccuTag.Tag := Tag;
 Return(FAccuTag);
end;

constructor TMousePainter.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 mpTwig := nil;
 paraLineForm := nil;
 if Twigs.LayerTable.ActiveLayer = nil then Twigs.LayerTable.ActiveLayer := Twigs.LayerTable.NULLLayer;
 fixLength := xyNull;
 arcfixLength := xyNull;
 arcfixRadius := xyNull;
 circfixRadius := xyNull;
 fixKoef := xyNull;
 fixAngle := xyNull;
 Stvor_.X1 := xyNull;
 cirKvant := Twigs.Settings.psArcCount;
 case LOperation of
  sysDrawParaLine: begin
    paraLineForm := TParaLineFrame.Create(GSelector.GNForm);
    paraLineForm.OnReturn := Return;
    twigStyle := GReadInteger('ParaLineForm_lbHotSpot', 0) + 1000;
    cirKvant := Twigs.Settings.psArcCount;
   end;
 // форма LayerPolygon не перенесена: количество сторон по умолчанию
  sysDrawKvant: cirKvant := GReadInteger('LayerPolygon_SE', 6);
 end;
 accDistance := xyNull;
 accAngle := xyNull;
 accKoef := xyNull;
 accDirectAngle := False;
 accIncrement := False;
 fParaWidth := GReadFloat('ParaLine_Width', 0.5);
 kvantStyle := GReadInteger('LayerPolygon_Style', 0);
 FAccuTag := TComponent.Create(nil);
 ShowAccuDraw;
 fixPoint1 := TMarker.Create(GSelector, 0, mtRect, TAlphaColorRec.Blue, 8, 2);
 fixPoint2 := TMarker.Create(GSelector, 0, mtCross, TAlphaColorRec.Blue, 4, 2);
 fixTimer := TTimer.Create(nil);
 fixTimer.Interval := 500;
 fixTimer.OnTimer := OnTimer;
 PathMarker := TPathMarker.Create(0, 0);
 MultiLot := nil;
 HatchLot := PCollection.Create(1);
end;

destructor TMousePainter.Destroy;
var I:Integer;
begin
 if (AccuDrawPanel(False) <> nil) and (AccuDrawPanel(False).ShownBy = Self) then AccuDrawPanel(False).Hide;
 FreeAndNil(FAccuTag);
 TimerClose;
 try
 Error:='0';
 inherited Destroy;
 If mpTwig<>nil then begin mpTwig.Twig:=nil;mpTwig.Free;mpTwig:=nil;end;
 Error:='1';
 Error:='2';
 Error:='3';
 if paraLineForm <> nil then begin
  paraLineForm.Free;
  paraLineForm := nil;
 end;
 Error:='4';
 fixPoint1.Free;fixPoint2.Free;
 Error:='5';
 fixTimer.Free;
 PathMarker.Free;
 // удаляем ветки не вошедшие в MultiLot
 For I:=Twigs.Twigs.TwigsCount-1 downto 1 do If TTwig(Twigs.Twigs.TAt(I)).What = Twig_MultiLine then
  Twigs.Twigs.AtDelete(TWG_Twig,I);
 except
  WriteIn(['Отладчик : сообщение от '+ClassName+'. Шаг отладки :'+Error]);
  If Assigned(FreeProc) then FreeProc;
  fixTimer.Free;
 { If Error='1' then  begin AccuDrawForm:=TAccuDrawForm.Create(ApplicationMainForm);
                           AccuDrawForm.OnReturn:=Return;
                     end;}
 end;
 HatchLot.Free;
// unfixTimer.Free;
end;

procedure TMousePainter.CreateTwig;
begin
 if mpTwig<>nil then mpTwig.Free;
 if TwigClass=nil then mpTwig:=TTwigPath.Create(TTwig) else mpTwig:=TTwigPath.Create(TwigClass);
end;

procedure TMousePainter.CreateTwigAs(Twig_: TTwig);
begin
 if mpTwig<>nil then mpTwig.Free;
 mpTwig:=TTwigPath.CreateAsTwig(Twig_);
end;

procedure TMousePainter.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var Kvant, I: Integer;
    Paint: ISkPaint;
begin
// направляющие и маркер привязки рисует TMouseSelector.DrawTemp.
// В старой программе здесь же стирались (XOR) направляющие - OrthoTwigs.HideLines;
// отрисовка не должна менять состояние, поэтому это не переносится
 inherited;
 if Canvas = nil then exit;
 case LOperation of
  sysDrawLine, sysDrawLine2, sysDrawPoint, sysDrawPoly, sysDrawSpline, sysDrawArc,
  sysDrawCircle, sysDrawRect, sysDrawParaLine, sysLine, sysDrawKvant, sysDrawArc2,
  sysDrawArc3: begin
    Kvant := Quants_For_Arcs;
    try
     Quants_For_Arcs := cirKvant;
    // ветви незавершенного мультиконтура
     if MultiLot <> nil then begin
      if Twigs.Settings.psWidthPath then Paint := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 2, False) else Paint := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 1, True);
      for I := 0 to MultiLot.Coord.Count - 1 do SkDrawTwig(Canvas, MultiLot.GetTwig(Twigs.Twigs, I), Paint);
     end;
     mpDrawTwig(Canvas);
     DrawHatchLot(Canvas);
    finally
     Quants_For_Arcs := Kvant;
    end;
   end;
 end;
 DrawFixedPoints(Canvas);
end;

Function TMousePainter.isKeyDownCheck:boolean;
begin
 Result:=(mpTwig<> nil) or fixPoint1.Visible;
end;

// клавиша буквы в любой раскладке и регистре: Key - код клавиши (латинская
// буква - код заглавной) или код символа (KeyChar формы; коды русских букв
// больше 255 - сравнение, не множество)
function IsKey(Key: Word; Lat, Rus: Char): Boolean;
begin
 Result := (Key = Ord(UpCase(Lat))) or (Key = Ord(LowerCase(Lat)[1])) or
           (Key = Ord(AnsiUpperCase(Rus)[1])) or (Key = Ord(AnsiLowerCase(Rus)[1]));
end;

procedure TMousePainter.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState;
  var Hook: boolean);
// панель параметров, показанная этой операцией: цифры, точка, Backspace,
// Enter - в активную кнопку панели (Enter - применить значение)
Function AccuDrawKey: boolean;
var P: TInstAccuDrawFrame;
begin
 Result:=False;
 P:=AccuDrawPanel(False);
 If (P = nil) or (P.ShownBy <> Self) or not P.Visible then exit;
 If Key in [96..105] then Key:=Ord('0')+(Key-96);
 If Key in [Ord('0')..Ord('9')] then P.AddChar(Chr(Key)) else
 If Key in [190,110] then P.AddChar('.') else
 If Key = vkBack then P.BackChar else
 If Key = vkReturn then P.DoEnter else exit;
 Result:=True;
end;
Procedure SetTwigStyle(Key:Word);
begin
// If Key in [ord('Q'),ord('q'),ord('Й'),ord('й')] then twigStyle:=hsLeft else
 If IsKey(Key,'W','Ц') then twigStyle:=hsCenter else
// If Key in [ord('E'),ord('e'),ord('У'),ord('у')] then twigStyle:=hsRight;
end;
begin
 If (Shift = []) and AccuDrawKey then begin
  Key:=0;
  Hook:=True;
  exit;
 end;
 inherited;
 If Shift <> [] then exit;
 If IsKey(Key,'Q','Й') or IsKey(Key,'W','Ц') or IsKey(Key,'E','У') then
  If LOperation = sysDrawParaLine then begin
   SetTwigStyle(Key);
  end;
// Z - удаление последней точки (Ctrl+Z старой программы)
 If IsKey(Key,'Z','Я') then begin
  TimerClose;
  If mpTwig<>nil then begin
   DeleteLastPoint;
   Key:=0;
   Hook:=True;
  end;
 end;
// X - сброс привязок
 If IsKey(Key,'X','Ч') and (Shift = []) then begin
  ClearSnaps;
  Key:=0;
  Hook:=True;
 end;
end;

procedure TMousePainter.MouseDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
var P:PCollection;B:Boolean;
    AccuUsed:Boolean;
begin
 inherited MouseDown(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 // средняя кнопка - пан карты в форме
 if (Button = TMouseButton.mbRight) or (Button = TMouseButton.mbMiddle) then Exit;
 Hook:=True;
// значение панели задано: направление - по точке щелчка (касание пером без
// предварительного движения), точка - на заданном расстоянии
 If accDistance<>xyNull then
  If fixPoint1.Visible and (fixDistance<>xyNull) then UpdateFixedPoints(X,Y) else
  If (mpTwig<>nil) and (fixLength<>xyNull) then mpMoveTwigPath(X,Y);
// Writeln('MouseDown=',X,' ',Y,' ', LOperation);
{}
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant   :begin
                    if fixPoint1.Visible then begin
                     X0:=fixPoint2.mX;Y0:=fixPoint2.mY;
                    end;// else begin X0:=X;Y0:=Y;end;
                    B:=False;
                   // значение панели использовано точкой: расстояние от точки
                   // залипания или длина отрезка от уже поставленной точки
                   // (первая точка линии, центр окружности - еще нет)
                    AccuUsed:=(accDistance<>xyNull) and ((fixPoint1.Visible and (fixDistance<>xyNull)) or
                              ((mpTwig<>nil) and (fixLength<>xyNull)));
                    mpUpdateTwigPath(X0,Y0);
                    If AccuUsed then ClearAccuValue else
                    If accDistance<>xyNull then ApplyAccuValue;
                    {
                    If B then
                     If (ObjTemporary<>nil) then If (objTemporary is TTwig) then
                      If TTwig(objTemporary).Properties<>nil then
                       If TTwig(objTemporary).Properties.PropValue['Ширина']<>nil then
                        If paraLineForm<>nil then begin
                         paraLineForm.SetWidth(TTwig(objTemporary).Properties.PropValue['Ширина'].asFloat);
                        end;
                     }
                    {
                    If (ObjTemporary<>nil) then If (objTemporary is TTwig) then If mpTwig<>nil then begin
                     If mpTwig.Count=1 then
                      mpTwig.interFirst:=TTwig(objTemporary);
                    end;
                    }
//                     P:=PCollection.Create(1);
//                     Writeln('FindTwigs=',Twigs.FindTwigs(X0,Y0,P));
//                     P.DeleteAll;P.Free;
                   end;
  sysDrawArc2,
  sysDrawArc3:begin
               if fixPoint1.Visible then begin
                X0:=fixPoint2.mX;Y0:=fixPoint2.mY;
               end;// else begin X0:=X;Y0:=Y;end;
               If mpTwig=nil then mpUpdateTwigPath(X0,Y0) else begin
                 If TTwigPathArc(mpTwig).CondArc<2 then mpUpdateTwigPath(X0,Y0) else begin
                  If mpTwig.Twig is TTwigArc then begin
                   B:=Distance(X,Y,TTwigArc(mpTwig.Twig).A.XDot,TTwigArc(mpTwig.Twig).A.YDot)<Distance(X,Y,TTwigArc(mpTwig.Twig).B.XDot,TTwigArc(mpTwig.Twig).B.YDot);
                   If B then xyACB:=TTwigArc(mpTwig.Twig).A else xyACB:=TTwigArc(mpTwig.Twig).B;
                  end;
                   mpCreatePrim(Form);
                   mpUpdateTwigPath(X0,Y0);
                 end
               end;  
              end;
  end;
end;

procedure TMousePainter.MouseMove(Form: TForm2; Shift: TShiftState; X,
  Y: Double; var Hook: boolean);
var Kvant:Integer;
    SW: TStopwatch;
    MsMarker, MsPath, MsFixed, MsImage: Double; // отладка фризов, мс
begin
 SW := TStopwatch.StartNew;
 MsMarker := 0; MsPath := 0; MsFixed := 0; MsImage := 0;
 inherited MouseMove(Form,Shift,X,Y,Hook);
 if ShiftPress or ControlPresS then begin Hook:=False;Exit;end;
 Hook:=True;
 SetCur('');
{}
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysDrawParaLine,
   sysLine,
   sysDrawKvant,
   sysDrawArc2,
   sysDrawArc3    :begin
                    Kvant:=Quants_For_Arcs;
                    try
                     Quants_For_Arcs:=cirKvant;
                     If mpTwig<>nil then begin
                      X0:=X;Y0:=Y;
                      if Twigs.Settings.psAuto then emGetDotMarker(X0,Y0,mpTwig.FirstPoint,mpTwig.mpStvor,objTemporary,True,True,True);
                      MsMarker := SW.Elapsed.TotalMilliseconds;
                      mpMoveTwigPath(X0,Y0);
                      MsPath := SW.Elapsed.TotalMilliseconds;
                      If fixPoint1.Visible then begin fixPoint2.mX:=X0;fixPoint2.mY:=Y0;end;
                     end else begin
                      Stvor_.X1:=xyNull;
                      if Twigs.Settings.psAuto then emGetDotMarker(X,Y,nil,Stvor_,objTemporary,True,True,True);
                      MsMarker := SW.Elapsed.TotalMilliseconds;
                      MsPath := MsMarker;
                      X0:=X;Y0:=Y;
                      If fixPoint1.Visible then begin fixPoint2.mX:=X0;fixPoint2.mY:=Y0;end;
                     end;
 //                     Writeln('1===',fixPoint2.mX,' ',fixPoint2.mY);
                     UpdateFixedPoints(fixPoint2.mX,fixPoint2.mY);
                     MsFixed := SW.Elapsed.TotalMilliseconds;
 //                     Writeln('2===',fixPoint2.mX,' ',fixPoint2.mY);
                    // перерисовка live-слоя (резиновая линия, маркер, направляющие)
                     UpdateImage;
                     MsImage := SW.Elapsed.TotalMilliseconds;
                    finally
                     Quants_For_Arcs:=Kvant;
                    end;
                   end;
  end;
// отладка фризов: части обработки движения (мс), если всего 10 мс и больше
 if MsImage >= 10 then
  WriteIn(['MousePainter.MouseMove marker=', FloatToStrF(MsMarker, ffFixed, 8, 1),
   ' path=', FloatToStrF(MsPath - MsMarker, ffFixed, 8, 1),
   ' fixed=', FloatToStrF(MsFixed - MsPath, ffFixed, 8, 1),
   ' image=', FloatToStrF(MsImage - MsFixed, ffFixed, 8, 1),
   ' ortho=', OrthoTwigs.Twigs.Count]);
end;

procedure TMousePainter.MouseRightDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
var I:Integer;D1,D2:TDot;PD:TPointDot;
    DrawTwig:TTwig;Lot,twLot:TLot;
    R1:TRect;
    Layer,Layer1:TResource;
    SavedTwig:TTwigPath;
    QLD:Boolean;
    Tw:TTwig;
    CountTwig,CountLot,Kvant:Integer;
    B:Boolean;
    Block:TGeoBlock;
    GUID:TGUID;
    XBl,YBl:Double;
begin
 inherited MouseRightDown(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 Hook:=True;
// значение расстояния на панели отработало - рисование без фиксации
 If accDistance<>xyNull then ClearAccuValue;

{}
  Case LOperation of
   sysDrawPoint:If mpTwig<>nil then begin
                  // диалог выбора слоя (psQueryLayerDraw) не перенесен - активный слой
                  Layer:=Twigs.LayerTable.ActiveLayer;
                   If Layer<>nil then begin
                     Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_CreatePoint'));
                     For I:=0 to mpTwig.Count-1 do begin
                      D1:=mpTwig.Coord[I];
                     {$IFDEF GEOBUILDER}
                      PD:=TPointDot.CreateTaheo(Form.LayerTable.ActiveLayer,-1,'',D1.XDot,D1.YDot,ZNull);
                      PD.Symbol:=Form.LayerTable.ActiveSymbology;
                     {$ELSE}
                      PD:=TPointDot.CreateTaheo(Layer,-1,'',D1.XDot,D1.YDot,ZNull);
                      PD.Selector:=Selector;
                     {$ENDIF}
                      If OnAddPrim(PD) then begin
                       // свойства по умолчанию из редактора свойств
                       If PropEditorForm <> nil then PropEditorForm.ApplyDefaults(PD);
                       Twigs.Twigs.Insert(TWG_Point,PD);
                       TPrimUndo(Undo.Last).AddModifiedPrim(PD);
                      end else PD.Free;
                     end;
                     OrthoTwigs.Pack('');
                     mpTwig.Free;mpTwig:=nil;
                     Marker.Remove(GCanvas);
                     Form.ClassBuildII;
                     TimerClose;
                     Modified;
                     Selector.UpdateImage(usmAdd, PD);
                  end; // If Layer<>nil
                end;
   sysDrawLine,sysDrawLine2,
   sysDrawPoly,
   sysDrawSpline,
   sysDrawArc,
   sysDrawCircle,
   sysDrawRect,
   sysLine,
   sysDrawKvant,
   sysDrawArc2,
   sysDrawArc3  :begin
                  //If LOperation = sysDrawArc3 then
                  { If mpTwig<>nil then
                    If mpTwig.Twig is TTwigArc then begin
                     B:=Distance(X,Y,TTwigArc(mpTwig.Twig).A.XDot,TTwigArc(mpTwig.Twig).A.YDot)<Distance(X,Y,TTwigArc(mpTwig.Twig).B.XDot,TTwigArc(mpTwig.Twig).B.YDot);
                     If B then xyACB:=TTwigArc(mpTwig.Twig).A else xyACB:=TTwigArc(mpTwig.Twig).B;
                    end;}
                   If (isMultiLine)and(not LockedMultiLine) then begin
                    If LOperation = sysDrawArc3 then begin

                    end;
                    PopupMenuPopup(X,Y);
                   // LockedMultiLine:=True;
                    exit;
                   end else begin
                   If (LOperation = sysDrawLine2) and (PopUpMenu<>nil) then begin
                    PopupMenuPopup(X,Y);
                   end else
                    mpCreatePrim(Form);
                   end;
                  end;
   sysDrawParaLine: If mpTwig = nil then begin
                     // ищем сегмент, устанавливаем автоширину паралинии
                     If (ObjTemporary<>nil) then If (objTemporary is TTwig) then
                      If TTwig(objTemporary).Properties<>nil then
                       If TTwig(objTemporary).Properties.PropValue['Ширина']<>nil then
                        If paraLineForm<>nil then begin
                        // автоширина паралинии по сегменту: SetWidth нет во фрейме ParaLine
                        end;
                    end else
                    If mpTwig<>nil then If mpTwig.Count>1 then With Twigs do try
                    Layer:=LayerTable.ActiveLayer;
                    RMouseDown:=False;
                    If Layer<>nil then
                    QLD:=Form.Settings.psQueryLayerDraw;
                    Form.Settings.psQueryLayerDraw:=False;
                    SavedTwig:=mpTwig;mpTwig:=TTwigPath.Create(TTwig);mpTwig.Twig:=TTwigParaLine(SavedTwig).TwigL;
                    LOperation:=sysDrawLine;
                    X0:=SavedTwig.FirstPoint.XDot;Y0:=SavedTwig.FirstPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interFirst:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interFirst:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    X0:=SavedTwig.LastPoint.XDot;Y0:=SavedTwig.LastPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interSecond:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interSecond:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    mpTwig.Twig.SetProperty('Ширина',FloatToStr(SavedTwig.Width));//!!!!!
                   // если чертим параллельные - рисуем первую линию, если штриховку - не рисуем
                     MouseRightDown(Form,Button,Shift,X,Y,Hook);
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=0;
                   //
                    X0:=SavedTwig.FirstPoint.XDot;Y0:=SavedTwig.FirstPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interFirst:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interFirst:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    X0:=SavedTwig.LastPoint.XDot;Y0:=SavedTwig.LastPoint.YDot;
                    emGetDotMarker(X0,Y0,SavedTwig.FirstPoint,SavedTwig.mpStvor,objTemporary,False,False);
                    If (ObjTemporary<>nil) then begin
                     If (objTemporary is TTwig) then begin SavedTwig.interSecond:=TTwig(objTemporary);SavedTwig.Calculate;end else
                    // If (objTemporaryTwig<>nil) then begin SavedTwig.interSecond:=TTwig(objTemporaryTwig);SavedTwig.Calculate;end;
                    end;
                    if TTwigParaLine(SavedTwig).ParaStyle = pfNone then TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=1;
                   // добавляем mpTwig.Rects
                     mpTwig:=TTwigPath.Create(TTwig);mpTwig.Twig:=TTwigParaLine(SavedTwig).TwigR;
                    mpTwig.Twig.SetProperty('Ширина',FloatToStr(SavedTwig.Width));
                    twLot:=nil;
                   Self.Undo.StartTransAction;
                   try
                    B:=False;
                    // создаем блок -> добавляем в него новые примитивы
                    //Block:=TGeoBlock.Create(Form,nil);
                    For I:=0 to TTwigParaLine(SavedTwig).Rects.Count-1 do With Self.Twigs do begin
                    {}
                     If (TTwigParaLine(SavedTwig).ParaStyle = pfHatch) then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка ИДН');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If (TTwigParaLine(SavedTwig).ParaStyle = pfStroke) then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка прерывистая');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If (TTwigParaLine(SavedTwig).ParaStyle = pfSolid) then begin
                      Layer:=LayerTable.AddExistSysLayer('Разметка сплошная желтая');
                      Layer.RGB.ARGB[1]:=255;Layer.RGB.ARGB[2]:=255;Layer.RGB.ARGB[3]:=0;
                      Layer:=LayerTable.AddExistSysLayer('Разметка сплошная');
                      Layer.RGB.ARGB[1]:=254;Layer.RGB.ARGB[2]:=254;Layer.RGB.ARGB[3]:=254;
                     end else If (TTwigParaLine(SavedTwig).ParaStyle = pfIDN) then begin
                      {If I>2 then begin
                       Layer:=LayerTable.AddExistSysLayer('ИДН желтая краска');
                       Layer.RGB.ARGB[1]:=255;Layer.RGB.ARGB[2]:=255;Layer.RGB.ARGB[3]:=0;
                      end else} begin
                       Layer:=LayerTable.AddExistSysLayer('ИДН');
                       Layer.RGB.ARGB[1]:=40;Layer.RGB.ARGB[2]:=40;Layer.RGB.ARGB[3]:=40;
                      end;
                     end;
                     If I=0 then begin
//                      twLot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур из всех сегментов Rects
//                      twLot.TypeLot:=1;
                     end;
                    {}
                     Twigs.Insert(TWG_Twig,TTwigParaLine(SavedTwig).Rects[I]);
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).Closed:=1;
                     If I=0 then begin
                      XBl:=TTwig(Twigs.TAt(Twigs.TwigsCount-1))[0].XDot;YBl:=TTwig(Twigs.TAt(Twigs.TwigsCount-1))[0].YDot;
                     end;
                     TTwig(Twigs.TAt(Twigs.TwigsCount-1)).SetMinMax;
                     Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                     Lot.Selector := Selector;
                     If ((TTwigParaLine(SavedTwig).ParaStyle = pfIDN))and(I>2) then Lot.SetProperty('Цвет заливки',IntToStr($00FFFF{clYellow}));
                     Lot.SetProperty('Тип линии','-1');
                    // Lot.SetProperty('Цвет',IntToStr(Rgb(1,100,1)));
                    // Lot.SetProperty('Цвет заливки',IntToStr(Rgb(1,,1)));
                     Lot.Insert(Twigs.TwigsCount-1);
                     Lot.SetMinMax(Twigs);
                    // twLot.Insert(Twigs.TwigsCount-1);
                    // twLot.SetMinMax(Twigs);
                     Twigs.Insert(TWG_Lot,Lot);
                     TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'UndoAddNewPointBlock...em_SetBlock'))).AddModifiedPrim(Lot);
//                     twLot.Insert(Twigs.TwigsCount-1);
                    {With Block do begin
                     TwgForm.SetGabaritesPrivate;
                     With TwgForm,blockRect do begin Left:=XXMin;Top:=YYMin;Right:=XXMax;Bottom:=YYMax;
                      Block.X:=XBl-XXMin;//(XXMin+XXMax)/2;
                      Block.Y:=YBl-YYMin;//(YYMin+YYMax)/2;
                      //Writeln(XXMin:8:2,' ',YYMin:8:2,' ',XXMax:8:2,' ',YYMax:8:2);
                     end;
                    }
                    end;
                    ClassBuildII;
                    CreateGUID(GUID);
                   {                                        `
                    Block.Name:=GUIDToString(GUID);
                    Twigs.Insert(TWG_Block,Block);
                   // создаем точку с блоком
                     PD:=TPointDot.Create(XBl,YBl,0);
                     PD.userObj:=Block;
                     PD.Code:=Self.Twigs.LayerTable.ActiveLayer.ID;
                     PD.ClassHandle:=Self.Twigs.LayerTable.ActiveLayer;
                     PD.XKoef:=1;PD.YKoef:=1;
                    //
                     TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'UndoAddNewPointBlock...em_SetBlock'))).AddModifiedPrim(PD);
                     Twigs.Insert(TWG_Point,PD);
                   //
                    }
                     B:=True;
                   finally
                    If B then Self.Undo.Commit else Self.Undo.RollBack;
                    If B and (TTwigParaLine(SavedTwig).Rects.Count > 0) then Selector.UpdateImage(usmAdd, Lot);
                   end;
                   // если чертим параллельные - рисуем первую линию, если штриховку - не рисуем
                   // if twLot<>nil then Twigs.Insert(TWG_Lot,twLot);
                    TTwigParaLine(SavedTwig).Rects.DeleteAll;
                  // если чертим параллельные - рисуем вторую линию, если штриховку - не рисуем
                     MouseRightDown(Form,Button,Shift,X,Y,Hook);
                   finally
                    LOperation:=sysDrawParaLine;
                    Form.Settings.psQueryLayerDraw:=QLD;
                   end;
  end;
end;

procedure TMousePainter.mpCreatePrim(Form:TForm2;itsEndOfMultiLine:boolean = False);
var DrawTwig,RectTwig:TTwig;Lot:TLot;
    R1:TRect;
    Layer:TResource;
    SavedTwig:TTwigPath;
    QLD:Boolean;
    Tw:TTwig;
    CountTwig,CountLot,Kvant:Integer;
    I,M,Index:Integer;D1,D2:TDot;PD:TPointDot;
Procedure CreateLotArcTwig;
var M:Integer;
begin
If Twigs.Settings.psLineArc then
 For M:=0 to Lot.Coord.Count-1 do begin
  Tw:=Lot.GetTwig(Twigs.Twigs,M);
  If Tw is TTwigArc then begin
   Index:=Twigs.Twigs.TwigsLarge.IndexOf(Tw);
   TTwigArc(Tw).ArcView:=1;
   Tw:=TTwig.CreateAsTwig(Tw,True);
   Twigs.Twigs.TwigsLarge.AtPut(Index,Tw);
  end;
 end;
end;
begin
LastPrim:=nil;
If mpTwig<>nil then With Twigs do begin
                   If LOperation = sysDrawArc3 then begin
                   If mpTwig is TTwigPathArc then begin
                    If TTwigPathArc(mpTwig).CondArc = 1 then begin
                     MessageError('Закончите построение дуги...');
                    LockedMultiLine:=False;
                    exit;
                    end;
                   end;
                   end;
                   If mpTwig.Count<2 then begin
                    If LOperation=sysDrawLine then MessageError('Укажите как минимум 2 точки');
                    If LOperation=sysDrawPoly then MessageError('Укажите как минимум 3 точки');
                    If LOperation=sysDrawSpline then MessageError('Укажите как минимум 3 точки');
                    LockedMultiLine:=False;
                    exit;
                   end else
                    If LOperation=sysDrawPoly then If mpTwig.Count<3 then begin
                     MessageError('Укажите как минимум 3 точки');
                     LockedMultiLine:=False;
                     exit;
                    end;
                     If (not isMultiLine)or(itsEndOfMultiLine) then Self.Undo.StartTransAction;
                     try
                    // разбиваем сегменты, если сработало автопритягивание
                    If LOperation = sysDrawKvant then begin
                     Kvant:=Quants_For_Arcs;
                      Quants_For_Arcs:=cirKvant;
                     try
                      mpTwig.Twig.ArcView:=1;mpTwig.Twig.Calculate;
                      DrawTwig:=TTwig.CreateAsTwig(mpTwig.Twig,True);DrawTwig.Closed:=1;
                      DrawTwig.Calculate;
                      mpTwig.Twig.Free;
                     finally Quants_For_Arcs:=Kvant;end;
                    end else begin
                     DrawTwig:=mpTwig.Twig;DrawTwig.Closed:=1;
                     DrawTwig.Calculate;
                    end;
                    //Writeln('CC=',DrawTwig.Coord.Count);
                   // try DrawTwig.Calculate;except exit; end;
                    If (LOperation<>sysDrawKvant) and (LOperation<>sysDrawCircle) and (LOperation<>sysDrawRect) then
                    If (Settings.psAuto)and(Settings.psInsert or Settings.psTwise) then begin
                      emInsertPointInTwig(mpTwig.FirstPoint.XDot,mpTwig.FirstPoint.YDot,nil,nil);
                      emInsertPointInTwig(mpTwig.LastPoint.XDot,mpTwig.LastPoint.YDot,nil,nil);
                    end;
                  // запрашиваем слой
                    // диалог выбора слоя (psQueryLayerDraw) не перенесен - активный слой
                    Layer:=LayerTable.ActiveLayer;
                    If LOperation = sysDrawLine2 then Layer:=LayerTable.AddExistSysLayer('Линия раздела');
                    RMouseDown:=False;
                   If Layer<>nil then try
                   {$IFDEF GEOBUILDER}
                     Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                    // Lot.Insert(Twigs.TwigsCount-1);
                      If LOperation=sysDrawPoly then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                      Lot.Symbol:=LayerTable.ActiveSymbology;
                   {$ELSE}
                      If isMultiLine then begin
                       If MultiLot=nil then begin
                        Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                        Lot.Selector := Selector;
                        If (LOperation=sysDrawPoly) {or (LOperation=sysDrawRect)} then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                        // свойства по умолчанию (после TypeLot: от него зависит набор свойств)
                        If PropEditorForm <> nil then PropEditorForm.ApplyDefaults(Lot);
                       end else Lot:=MultiLot;
                      end else begin
                       // создание контура по MergedOpr
                      // растровый контур TRectLot (MergedOpr = sysDrawRastr) не перенесен
                        Lot:=TLot.Create(Layer.ID,Layer,1); // создаем линейный контур
                        Lot.Selector := Selector;
                       If (LOperation=sysDrawPoly) {or (LOperation=sysDrawRect)} then Lot.TypeLot:=2 else Lot.TypeLot:=1;
                       // свойства по умолчанию (после TypeLot: от него зависит набор свойств)
                       If PropEditorForm <> nil then PropEditorForm.ApplyDefaults(Lot);
                        If LOperation = sysDrawLine2 then begin
                         Lot.SetProperty('Цвет',IntToStr($0000FF{clRed}));Lot.SetProperty('Толщина','0.5');
                        end;
                      end;
                   {$ENDIF}
                       If Lot.TypeLot=2 then begin
                        DrawTwig.Insert(TDot.CreateAsDot(DrawTwig[0]));
                       end;
                      If LOperation<>sysLine then begin
                       Case MergedOpr of
                        sysDrawRastr:begin
                                      RectTwig:=TTwigRect.CreateAsTwig(DrawTwig,True);
                                      DrawTwig.Free;DrawTwig:=RectTwig;
                                     end;
                       end;
                       If paraLineForm=nil then begin
                        Twigs.Insert(Twg_Twig,DrawTwig);
                        DrawTwig.SetMinMax;
                        Lot.Insert(Twigs.TwigsCount-1);
                        Lot.SetMinMax(Twigs);
                        Lot.NLot:=10000000;
                        If (Operation = sysDrawLine2) and Assigned(OnCreateLine2) then begin
                         LMouseDown := False;
                         RMouseDown := False;
                         onCreateLine2(Lot);exit;
                        end;
                       end else begin
                       // заливка паралинии (sbHatch...) добавляется в MouseRightDown
                        Twigs.Insert(Twg_Twig,DrawTwig);
                        DrawTwig.SetMinMax;
                        Lot.Insert(Twigs.TwigsCount-1);
                        Lot.SetMinMax(Twigs);
                       end;
                      end else begin
                       CountTwig:=Twigs.TwigsCount;CountLot:=Twigs.LotsCount;
                       For I:=0 to DrawTwig.Coord.Count-2 do begin
                        D1:=DrawTwig[I];D2:=DrawTwig[I+1];
                        Tw:=TTwig.Create(GSelector, 0);Tw.Insert(TDot.CreateAsDot(D1));Tw.Insert(TDot.CreateAsDot(D2));
                        Tw.SetMinMax;
                        Twigs.Insert(TWG_Twig,Tw);
                        If I<>0 then begin
                         Lot:=TLot.Create(Layer.ID,Layer,1);Lot.TypeLot:=1;
                         Lot.Selector := Selector;
                         If PropEditorForm <> nil then PropEditorForm.ApplyDefaults(Lot);
                        end;
                        Lot.Insert(Twigs.TwigsCount-1);Lot.SetMinMax(Twigs);
                        If OnAddPrim(Lot) then begin
                         Twigs.Insert(Twg_Lot,Lot);
                         TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                        end else begin
                         Twigs.AtDelete(TWG_Lot,Twigs.LotsCount-1);
                         Lot.Free;
                         Lot:=nil;
                        end;
                       end;
                       DrawTwig.Coord.DeleteAll;DrawTwig.Free;
                      end;
                      If LOperation<>sysLine then begin
                       If OnAddPrim(Lot) then begin
                         If isMultiLine then begin If MultiLot<>nil then begin
                          If itsEndOfMultiLine then begin
                           Twigs.Insert(Twg_Lot,Lot);
                           // делаем из дуг точки
                           CreateLotArcTwig;
                           TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                          end;
                         end else begin
                          If itsEndOfMultiLine then begin
                           Twigs.Insert(Twg_Lot,Lot);
                           // делаем из дуг точки
                           CreateLotArcTwig;
                           TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                          end;
                          MultiLot:=Lot;
                         end;
                         MultiLot.SetMinMax(Form.Twigs);
                        end else begin
                         Twigs.Insert(Twg_Lot,Lot);
                         // делаем из дуг точки
                           CreateLotArcTwig;
                         TPrimUndo(Self.Undo.AddUndoItem(TPrimUndo.Create(Form,LU_AddPrim,'Undo.AddNewPrim...em_Create...'+IntToStr(LOperation)))).AddModifiedPrim(Lot);
                       end;
                      end else begin
                       Twigs.AtDelete(TWG_Lot,Twigs.LotsCount-1);
                       Lot.Free;Lot:=nil;
                      end;
                     end;
                    If Lot<>nil then If Lot.TypeLot = 2 then Lot.SetSqwear(Twigs);
                    Modified;
                    LockedMultiLine:=False;
                   finally
                      ClassRebuildIndex:=True;
                      ClassBuildII;
                     // новый примитив - в сцену
                      If Lot <> nil then Selector.UpdateImage(usmAdd, Lot);
                      Marker.Remove(GCanvas);
                      OrthoTwigs.Pack('');
                      If isMultiLine then begin
                       If itsEndOfMultiLine then begin
                        For I:=0 to MultiLot.Coord.Count-1 do MultiLot.GetTwig(Twigs,I).What:=0;
                       end else
                       If mpTwig.Twig<>nil then mpTwig.Twig.What:=Twig_MultiLine;
                      end;
                      mpTwig.Twig:=nil;mpTwig.Free;mpTwig:=nil;
                      OrthoTwigs.Free;OrthoTwigs:=TOrthoTwigs.Create;
                      TimerClose;
                   end;
                     If (not isMultiLine) or(itsEndOfMultiLine) then Self.Undo.Commit;
                    LastPrim:=Form.Twigs.TAt(Form.Twigs.TwigsCount-1);
                    If Assigned(OnCreateLine2) then begin
                     LMouseDown := False;
                     RMouseDown := False;
                     onCreateLine2(Lot);exit;
                    end;
                    except
                      ShowMessage('objMouseDraw '+IntToStr(481));
                      If (not isMultiLine)or(itsEndOfMultiLine) then Self.Undo.RollBack;
                     end;
                 end;
end;

procedure TMousePainter.MouseUp(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited MouseUp(Form,Button,Shift,X,Y,Hook);
 if ShiftPress or ControlPress then begin Hook:=False;Exit;end;
 Hook:=True;
end;

procedure TMousePainter.mpDrawTwig(const Canvas: ISkCanvas);
begin
// геометрия пути обновляется в mpMoveTwigPath/mpUpdateTwigPath, здесь только отрисовка
 if mpTwig = nil then exit;
 mpTwig.Draw(Canvas);
 if (mpTwig.Marker <> nil) and mpTwig.Marker.Visible then mpTwig.Marker.Draw(Canvas, mpTwig.Marker.mX, mpTwig.Marker.mY);
end;

function TMousePainter.mpTwigVisible: Boolean;
begin
 Result:=False;
 if mpTwig<>nil then Result:=mpTwig.TwigVisible;
end;

procedure TMousePainter.mpUpdateTwigPath(X, Y: Double);
var AR:TArcRecord;CR:TCircRecord;
begin
try
 If mpTwig=nil then begin
  Case LOperation of
   sysDrawLine,sysDrawLine2,
   sysDrawPoint,
   sysDrawPoly,
   sysLine    :begin
                mpTwig:=TTwigPath.Create(TTwig);
                mpTwig.fixLength:=fixLength;
                mpTwig.fixAngle:=fixAngle;
                mpTwig.AddPoint(GCanvas,X,Y);
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawSpline:begin
                  mpTwig:=TTwigPath.Create(TTwigSpline);
                  mpTwig.fixLength:=fixLength;
                  mpTwig.AddPoint(GCanvas,X,Y);
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawArc:begin
               AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
               mpTwig:=TTwigPathArc.Create(TTwigArc,AR);
               AR.Free;
               mpTwig.fixLength:=arcfixLength;
               fixPoint1.Remove(GCanvas);
              end;
   sysDrawArc2:begin
                AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR);
                AR.Free;
                mpTwig.AddPoint(GCanvas,X,Y);
                mpTwig.fixLength:=arcfixLength;
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawArc3:begin
                AR:=TArcRecord.Create(X,Y,X,Y,X,Y,X,Y);
                If (MultiLot<>nil) and (MultiLot.Coord.Count>0) then
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR,MultiLot.GetTwig(Twigs.Twigs,MultiLot.Coord.Count-1)) else
                 mpTwig:=TTwigPathArc2.Create(TTwigArc,AR);
                AR.Free;
                mpTwig.AddPoint(GCanvas,X,Y);
                mpTwig.fixLength:=arcfixLength;
                fixPoint1.Remove(GCanvas);
               end;
   sysDrawCircle:begin
                  CR:=TCircRecord.Create(X,Y,X+2,Y+2);
                  mpTwig:=TTwigPath.Create(TTwigCircle,CR);
                  CR.Free;
                  mpTwig.fixLength:=circfixRadius;
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawKvant :begin
                  CR:=TCircRecord.Create(X,Y,X+2,Y+2);
                  mpTwig:=TTwigPathKvant.Create(TTwigCircle,CR,X,Y);
                  mpTwig.twigStyle:=1;
                  mpTwig.cirKvant:=cirKvant;
                  mpTwig.twigStyle:=kvantStyle;
                  CR.Free;
                  mpTwig.fixLength:=circfixRadius;
                  fixPoint1.Remove(GCanvas);
                 end;
   sysDrawRect:begin
                  mpTwig:=TTwigPathRect.Create(TTwig);
                  mpTwig.fixLength:=fixLength;
                  mpTwig.AddPoint(GCanvas,X,Y);
                  fixPoint1.Remove(GCanvas);
               end;
   sysDrawParaLine:begin
                    mpTwig:=TTwigParaLine.Create(TTwig);
                    mpTwig.fixLength:=fixLength;
                    mpTwig.Width:=fParaWidth;
                    mpTwig.twigStyle:=twigStyle;
                    mpTwig.AddPoint(GCanvas,X,Y);
                    fixPoint1.Remove(GCanvas);
                   end else begin
                    mpTwig:=TTwigPath.Create(TTwig);
                    mpTwig.AddPoint(GCanvas,X,Y);
                    fixPoint1.Remove(GCanvas);
                   end;
  end;
  If (mpTwig<>nil) and (LOperation<>sysDrawRect)and(LOperation<>sysDrawPoint){and(LOperation<>sysDrawCircle)
   and(LOperation<>sysDrawKvant)} then begin
   mpTwig.addAngle:=addAngle;
   OrthoTwigs.Add(mpTwig.Twig,'');
  end;
 end else begin
 // OrthoTwigs.Draw(GCanvas);
  mpTwig.AddPoint(GCanvas,X,Y);
   OrthoTwigs.UpdateTwigs;
  fixPoint1.Remove(GCanvas);
 // отрисовка - в DrawTemp
  UpdateImage;
//  UpdateImage;
 end;
 except ShowMessage('objMouseDraw '+intToStr(636));end;
end;

procedure TMousePainter.mpMoveTwigPath(X, Y: Double);
var Dot:TDot;
begin
 if mpTwig<>nil then begin
  mpTwig.Move(GCanvas,X,Y);
  X0:=mpTwig.mX;
  Y0:=mpTwig.mY;
  Dot:=mpTwig[mpTwig.Twig.Coord.Count-1];
  Application.Hint:='#L='+FloatToStrF(Distance(Dot.XDot,Dot.YDot,X0,Y0),ffFixed,_LD,Const_Of_DecimalLength);
 end;
end;

procedure TMousePainter.Return(Sender: TObject);
var Hook:Boolean;CRect:Integer;Kvant:Integer;
Function GetIncrementDistance:Double;
var I:Integer;Angle,prevAngle:Double;
    D1,D2:TDot;
begin
 Result:=0;
 If mpTwig.Count>1 then
 If accIncrement then begin
//  Angle:=Direct_Angle(mpTwig.LastPoint.XDot,mpTwig.LastPoint.YDot,mpTwig.mX,mpTwig.mY);
  For I:=mpTwig.Twig.Coord.Count-1 downTo 1  do begin
   D1:=mpTwig.Twig[I];D2:=mpTwig.Twig[I-1];
   prevAngle:=Direct_Angle(D2.XDot,D2.YDot,D1.XDot,D1.YDot)-Pi/2;
   If I=mpTwig.Twig.Coord.Count-1 then Angle:=prevAngle;
   mpTwig.SaveAngle:=mpTwig.fixAngle;mpTwig.fixAngle:=Angle*180/Pi;
   If Round(prevAngle) = Round(Angle) then Result:=Result+Distance(D1.XDot,D1.YDot,D2.XDot,D2.YDot) else exit;
  end;
 end;
end;
begin
 Case TComponent(Sender).Tag of
  -1:begin
      fixDistance:=xyNull;
      fixAngle:=xyNull;
      fixLength:=xyNull;
      arcFixLength:=xyNull;
      UpdateFixedPoints(fixPoint2.mX,fixpoint2.mY);
      if mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
      if mpTwig<>nil then mpTwig.SetAngle(GCanvas,fixAngle,False);
      UpdateImage;
     end;
  1,2,3:begin
         // если Distance = xyNull тогда режим фиксации длины отключен
         If fixPoint1.Visible then begin
          fixDistance:=accDistance;
          UpdateFixedPoints(fixPoint2.mX,fixpoint2.mY);
          If fixDistance<>xyNull then begin
           If fixPoint1.markermoveStyle = 0 then begin
            MouseDown(Twigs,TMouseButton.mbLeft,[],fixPoint2.mX,fixpoint2.mY,Hook);
            MouseUp(Twigs,TMouseButton.mbLeft,[],fixPoint2.mX,fixpoint2.mY,Hook);
            fixDistance:=xyNull;
            UpdateImage;
           end else begin
            TimerClose;
            TemporaryDot.What:=tdUsed;
            TemporaryDot.XDot:=fixPoint2.mX;TemporaryDot.YDot:=fixPoint2.mY;
            OrthoTwigs.addAngle:=Pi*2 - addAngle;
            OnTimer(Self);
           end;
          end;
          exit;
         end;
         fixLength:=accDistance;
         if (mpTwig<>nil)and(fixLength<>xyNull) then begin
          if fixLength-GetIncrementDistance<=0 then begin
           MessageInform('Расстояние задано неверно');
           mpTwig.fixAngle:=xyNull;
           fixLength:=xyNull;
           exit;
          end;
          If accIncrement then begin
          // Writeln(fixLength:8:2,' ',GetIncrementDistance:8:2);
           mpTwig.SetIncrementalLength(GCanvas,fixLength-GetIncrementDistance)
          end else
           mpTwig.SetLength(GCanvas,fixLength-GetIncrementDistance);
          If (LOperation = sysDrawCircle)or(LOperation = sysDrawKvant) then begin
           //If mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
           mpTwig.fixAngle:=xyNull;
           fixLength:=xyNull;
           OrthoTwigs.UpdateTwigs;
            MouseDown(Twigs,TMouseButton.mbRight,[],mpTwig.mX,mpTwig.mY,Hook);
            MouseUp(Twigs,TMouseButton.mbRight,[],0,0,Hook);
           exit;
          end else
          If LOperation = sysDrawRect then CRect:=TTwigPathRect(mpTwig).CondRect;
          mpTwig.AddPoint(GCanvas,mpTwig.mX,mpTwig.mY);
          mpTwig.fixAngle:=xyNull;
          fixLength:=xyNull;
          OrthoTwigs.UpdateTwigs;
           If LOperation = sysDrawRect then begin If CRect = 2 then begin
             mpTwig.Move(GCanvas,mpTwig.mX,mpTwig.mY);
             MouseDown(Twigs,TMouseButton.mbRight,[],mpTwig.mX,mpTwig.mY,Hook);
             MouseUp(Twigs,TMouseButton.mbRight,[],0,0,Hook);
             exit;
           end;
          end;
         end;
         If mpTwig<>nil then mpTwig.SetLength(GCanvas,fixLength);
         UpdateImage;
       end;
  4:begin
     If accAngle<>xyNull then fixAngle:=accAngle+180 else fixAngle:=xyNull;
     if mpTwig<>nil then mpTwig.SetAngle(GCanvas,fixAngle,accDirectAngle);
     UpdateImage;
    end;
  5:begin
     arcFixLength:=accDistance;
      if mpTwig<>nil then mpTwig.SetLength(GCanvas,arcFixLength);
     UpdateImage;
    end;
  hsLeft,
  hsRight,
  hsCenter:begin
            twigStyle:=TComponent(Sender).Tag;                         
           end;
  10:begin
      twigStyle:=ftwigStyle;
     end;
  21:begin
      // форма LayerPolygon не перенесена
      If mpTwig<>nil then begin
       mpTwig.twigStyle:=kvantStyle;
       mpTwig.cirKvant:=cirKvant;
       mpTwig.Calculate;
       If mpTwig.twigStyle = 0 then With TTwigPathKvant(mpTwig) do begin
        Coord[0].XDot:=X1;Coord[0].YDot:=Y1;
       end;
      end;
      UpdateImage;
     end;
 end;
end;


procedure TMousePainter.SetCur(CurName: String);
begin
 If Marker=nil then Inherited else begin
  If not Marker.Visible then Inherited else begin
   Cursor:=LoadCursor(HInstance,'V25Arrow');
   SetActiveCursor(Cursor);
  end;
 end;
// Cursor:=LoadCursor(HInstance,'V25Arrow');
// SetActiveCursor(Cursor);
end;

function TMousePainter.GetTwigStyle: Integer;
begin
 Result:=ftwigStyle;
end;

procedure TMousePainter.SetTwigStyle(const Value: Integer);
begin
 ftwigStyle:=Value;
 If mpTwig<>nil then begin
  mpTwig.twigStyle:=Value;
  if LOperation = sysDrawParaLine then mpTwig.Width:=fParaWidth;
  mpTwig.Calculate;
  UpdateImage;
 end;
end;

function TMousePainter.CanDoUndo: Boolean;
begin
 Result:=False;
 If mpTwig<>nil then begin
  If (LOperation = sysLine)or(LOperation = sysDrawPoly)or(LOperation = sysDrawParaLine)or(LOperation = sysDrawLine)or(LOperation = sysDrawLine2) then begin
   mpTwig.DeletePoint(GCanvas);
   UpdateImage;
   Result:=True;
  end else Result:=True;
 end;
end;

procedure TMousePainter.UpdateFixedPoints;
var Angle,pointAngle,XArc,YArc,D,S:Double;Arc:TTwigArc;
begin
 If not fixPoint1.Visible then exit;
 PathMarker.GetPoint(X,Y);
 If fixDistance=xyNull then begin
  fixPoint2.mX:=X;fixPoint2.mY:=Y;
  exit;
 end;
//
 If objTemporary<>nil then
  If objTemporary is TTwigArc then begin
  // расчитывем по угловой мере введенную длину
  //!!!! учесть не точку маркера, а точку начала дуги
   Arc:=TTwigArc(objTemporary);
  // расчитываем по хорде
   If fixDistance<0 then S:=2*Arc.Radius*arcSin(Abs(fixDistance)/(2*Arc.Radius)) else S:=Abs(fixDistance);
  //
   Angle:=S/Arc.Radius;
   pointAngle:=Direct_Angle(Arc.C.XDot,Arc.C.YDot,fixPoint1.mX,fixPoint1.mY);
   Angle:=pointAngle+Angle;
   XArc:=Arc.C.XDot+Arc.Radius*Cos(Angle);
   YArc:=Arc.C.YDot+Arc.Radius*Sin(Angle);
   D:=Distance(fixPoint1.mX,fixPoint1.mY,XArc,YArc);
   Angle:=Direct_Angle(fixPoint1.mX,fixPoint1.mY,XArc,YArc);
   fixPoint2.mX:=fixPoint1.mX+D*Cos(Angle);
   fixPoint2.mY:=fixPoint1.mY+D*Sin(Angle);
  //
   exit;
  end;
 Angle:=Direct_Angle(fixPoint1.mX,fixPoint1.mY,X,Y);
 fixPoint2.mX:=fixPoint1.mX+fixDistance*Cos(Angle);
 fixPoint2.mY:=fixPoint1.mY+fixDistance*Sin(Angle);
end;

procedure TMousePainter.DrawFixedPoints(const Canvas: ISkCanvas);
begin
// точка фиксации (по таймеру) и отмер от нее
 if (Canvas = nil) or not fixPoint1.Visible then exit;
 SkDrawLineClipped(Canvas, fixPoint1.mX, fixPoint1.mY, fixPoint2.mX, fixPoint2.mY, SkPen(Canvas, TAlphaColorRec.Lime, 1, True));
 fixPoint1.Size := GlobalSettings.Settings.gsPointSize * 2;
 fixPoint2.Size := GlobalSettings.Settings.gsPointSize * 2 - 2;
 fixPoint1.Color := GlobalSettings.Settings.gsGlueMarkerColor;
 fixPoint2.Color := GlobalSettings.Settings.gsGlueMarkerColor;
 fixPoint1.mWidth := 1;
 fixPoint2.mWidth := 1;
 fixPoint1.Draw(Canvas, fixPoint1.mX, fixPoint1.mY);
end;

procedure TMousePainter.OnTimer(Sender: TObject);
var I, J:Integer;
begin
// If Key in [ord('Z'),ord('z'),ord('Я'),ord('я')] then begin
 try
 If ((TemporaryDot.What = tdUsed) and (Sender<>fixTimer))or(TemporaryDot.What = tdDop) then With TemporaryDot do begin
   fixPoint1.mX:=XDot;fixPoint1.mY:=YDot;fixPoint1.markerMoveStyle:=ord(Sender = nil);
   fixPoint2.mX:=XDot;fixPoint2.mY:=YDot;
   PathMarker.Restore(XDot,YDot); // маркер для притягивания к осям X,Y
  fixDistance:=xyNull;
 // направляющие через точку: оси и линии, на которых она лежит
  AddSnapGuides(XDot,YDot);
 end else
 If Marker.Visible then
   If objTemporary = objTmp then If objTemporary is TDot then With TDot(objTemporary) do begin
   // Writeln('SetFixedTwig');
  fixPoint1.mX:=XDot;fixPoint1.mY:=YDot;fixPoint1.markerMoveStyle:=0;
  fixPoint2.mX:=XDot;fixPoint2.mY:=YDot;
  PathMarker.Restore(XDot,YDot); // маркер для притягивания к осям X,Y
  emFilterActiveLot(XDot,YDot);
//  OrthoTwigs.Pack('fixPoint');
// Writeln('ActLot.Count=',fActiveLots.Count);
  For I:=0 to fActiveLots.Count-1 do begin For J:=0 to TLot(fActiveLots[I]).Coord.Count-1 do OrthoTwigs.Add(TLot(fActiveLots[I]).GetTwig(Twigs.Twigs,J),'fixPoint');end;
  fActiveLots.DeleteAll;
 // направляющие через точку (TPointDot, вершина): оси и прилегающие отрезки
  AddSnapGuides(XDot,YDot);
//  UpdateImage;
//  OrthoTwigs.Draw(GCanvas,True);
  OrthoTwigs.addAngle:=Pi/2;
  fixDistance:=xyNull;
 end;
 // значение панели - от новой точки залипания
 If accDistance<>xyNull then ApplyAccuValue;
 // точка фиксации и направляющие изменились - перерисовка live-слоя
 UpdateImage;
 except ShowMessage('objMouseDraw '+IntToStr(864));fixTimer.Enabled:=False;OrthoTwigs.Pack('fixPoint'); end;
end;

procedure TMousePainter.TimerOpen;
begin
 If not timerNoStarting then begin
  fixTimer.Enabled:=False;
  fixTimer.Enabled:=True;
 end else
  fixTimer.Enabled:=False;
 objTmp:=objTemporary;
 timernoStarting:=False;
end;

procedure TMousePainter.TimerClose;
begin
 fixTimer.Enabled:=False;
 fixPoint1.Remove(GCanvas);
 fixPoint1.markermoveStyle:=0;
  OrthoTwigs.Pack('');
  OrthoTwigs.Pack('fixPoint');
 try UpdateImage;except end;
end;


procedure TMousePainter.DrawHatchLot(const Canvas: ISkCanvas);
var I: Integer;
    Paint: ISkPaint;
begin
 if (Canvas = nil) or (HatchLot.Count = 0) then exit;
 Paint := SkPen(Canvas, SkLiveColor(TAlphaColorRec.Red), 1, True);
 for I := 0 to HatchLot.Count - 1 do SkDrawTwig(Canvas, HatchTwig[I], Paint);
end;

function TMousePainter.Hint: String;
begin
 if (mpTwig <> nil) and (mpTwig.Twig <> nil) then Result := ClassName + ' Длина=' + FloatToStrF(mpTwig.Twig.GetLength, ffFixed, 15, 3) else Result := inherited Hint;
end;

function TMousePainter.GetHatchTwig(Index: Integer): TTwig;
begin
 Result:=HatchLot[Index];
end;

procedure TMousePainter.MakeHatchLot;
begin

end;

initialization
 AddMouseHook(TMousePainter);
end.
