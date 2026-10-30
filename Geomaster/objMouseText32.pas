unit objMouseText32;

// Перенос модуля objMouseText из Geomaster (Delphi 7, GDI): установка
// надписи (TDotText) щелчком - кнопка btnToolText (txt_SingleText).
// Параметры текста (форма instText старой программы: шрифт, высота, жирный,
// курсив, подчеркнутый, цвет, выравнивание) - на панели параметров
// (AccuDraw главной формы); хранятся в настройках как в instText.
// Щелчок ставит точку надписи: панель показывает поле «Текст» и полную
// клавиатуру, на карте - вводимый текст и мигающий курсор (DrawTemp).
// Повторный щелчок переносит точку, Enter или правая кнопка - надпись в
// карту, Esc - отмена надписи (без надписи - выход из инструмента).

interface

uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
     FMX.Types, objMouse32, objMouseSelect32, objMouseDraw32, drawTwigs32,
     Collect, EcDot, EcDot2, newFontScale, WptForm2;

const
  txt_SingleText = 10030;

type
  TMouseText = class(TMousePainter)
  private
   FText: TDotText; // редактируемая надпись; nil - ждем щелчок
   FBlink: TTimer;
   FCursorOn: Boolean;
   FUpdating: Boolean; // значения панели ставятся кодом - OnChange не читает их
  // параметры текста (instText)
   FFontName: String;
   FHeight: Double;
   FColor: Integer;
   FAlign: Integer;
   FBl, FIt, FUn: Byte;
  //
   procedure BlinkTimer(Sender: TObject);
   procedure ShowTextPanel(Edit: Boolean);
   procedure PanelChange(Sender: TObject);
   procedure PanelEnter(Sender: TObject);
   procedure ReadPanel;
   procedure SaveParams;
   procedure ApplyParams;
   function FontView: TFontViewEx;
   procedure StartText(X, Y: Double);
   procedure CommitText;
   procedure CancelText;
   procedure DrawText(const Canvas: ISkCanvas);
   function CursorLine(out X1, Y1, X2, Y2: Double): Boolean;
  public
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure ShowAccuDraw; override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
   Procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Function Hint: String; override;
 end;

implementation

uses Math, GBFWUndo, UndoColNew, newSelector, newResource, newProcs,
     ogcDrawerSkia, mpMarker, FMX.StdCtrls, FMX.ListBox, instAccuDraw, Writer,
     Selector32;

// цвета списка «Цвет» (цвет Windows, $00BBGGRR - как Text.Color)
const
  ColorNames: array[0..9] of String = ('Черный', 'Красный', 'Зеленый', 'Синий', 'Коричневый', 'Пурпурный', 'Голубой', 'Желтый', 'Серый', 'Белый');
  ColorValues: array[0..9] of Integer = ($000000, $0000FF, $008000, $FF0000, $2A2AA5, $FF00FF, $FFFF00, $00FFFF, $808080, $FFFFFF);
  DefaultFonts: array[0..3] of String = ('Arial', 'Times New Roman', 'Courier New', 'Roboto');
  CharSetDefault = 1;

{ TMouseText }

constructor TMouseText.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 FBlink := TTimer.Create(nil);
 FBlink.Interval := 500;
 FBlink.Enabled := False;
 FBlink.OnTimer := BlinkTimer;
end;

destructor TMouseText.Destroy;
begin
 FBlink.Free;
 FText.Free;
 inherited;
end;

// панель параметров: при создании (из конструктора TMousePainter) - параметры
// из настроек; без надписи - параметры, с надписью - и поле «Текст»
procedure TMouseText.ShowAccuDraw;
begin
 FFontName := GReadString('instTextForm_cbFonts', 'Arial');
 FAlign := GReadInteger('instTextForm_cbAlign', 1);
 FHeight := GReadFloat('instTextForm_EH', 3.5);
 FColor := GReadInteger('instTextForm_cbColor', 0);
 FBl := GReadInteger('instTextForm_sBl', 0);
 FIt := GReadInteger('instTextForm_SI', 0);
 FUn := GReadInteger('instTextForm_SU', 0);
 if FHeight <= 0 then FHeight := 3.5;
 ShowTextPanel(False);
end;

procedure TMouseText.SaveParams;
begin
 GWriteString('instTextForm_cbFonts', FFontName);
 GWriteInteger('instTextForm_cbAlign', FAlign);
 GWriteFloat('instTextForm_EH', FHeight);
 GWriteInteger('instTextForm_cbColor', FColor);
 GWriteInteger('instTextForm_sBl', FBl);
 GWriteInteger('instTextForm_SI', FIt);
 GWriteInteger('instTextForm_SU', FUn);
end;

// элементы панели (стандартный Show) и их значения из параметров; Edit - поле
// «Текст» (активное) и полная клавиатура
procedure TMouseText.ShowTextPanel(Edit: Boolean);
var P: TInstAccuDrawFrame;
    Fonts: TStringList;
    I: Integer;
    C: String;
begin
 P := AccuDrawPanel;
 if P = nil then exit;
 FUpdating := True;
 Fonts := TStringList.Create;
 try
  if Edit then
   P.Show(['Текст', 'Шрифт', 'Высота', 'Ж', 'К', 'Ч', 'Цвет', 'Выравнивание'], [TButton, TComboBox, TButton, TCheckBox, TCheckBox, TCheckBox, TComboBox, TComboBox])
  else
   P.Show(['Шрифт', 'Высота', 'Ж', 'К', 'Ч', 'Цвет', 'Выравнивание'], [TComboBox, TButton, TCheckBox, TCheckBox, TCheckBox, TComboBox, TComboBox]);
  P.ShownBy := Self;
  P.OnEnter := PanelEnter;
  P.OnChange := PanelChange;
  P.OnUndoPoint := nil;
  P.OnClearSnaps := AccuClearSnaps;
  FAccuOp := LOperation;
 // шрифты: стандартные и шрифты карты
  Fonts.CaseSensitive := False;
  for C in DefaultFonts do Fonts.Add(C);
  if Twigs.FontColEx <> nil then
   for I := 0 to Twigs.FontColEx.Count - 1 do
    if Fonts.IndexOf(String(TFontViewEx(Twigs.FontColEx[I]).FontName)) < 0 then Fonts.Add(String(TFontViewEx(Twigs.FontColEx[I]).FontName));
  if Fonts.IndexOf(FFontName) < 0 then Fonts.Add(FFontName);
  P.SetItems('Шрифт', Fonts.ToStringArray);
  P.SetItems('Цвет', ColorNames);
  P.SetItems('Выравнивание', AlignStrings.ToStringArray);
  P.Values['Шрифт'] := FFontName;
  P.Values['Высота'] := FloatToStr(FHeight, TFormatSettings.Invariant);
  P.Values['Ж'] := BoolToStr(FBl <> 0, True);
  P.Values['К'] := BoolToStr(FIt <> 0, True);
  P.Values['Ч'] := BoolToStr(FUn <> 0, True);
  C := '';
  for I := 0 to High(ColorValues) do
   if ColorValues[I] = FColor then C := ColorNames[I];
  P.Values['Цвет'] := C;
  if (FAlign >= 0) and (FAlign < AlignStrings.Count) then P.Values['Выравнивание'] := AlignStrings[FAlign];
  if Edit then begin
   P.Values['Текст'] := String(FText.Text.Text);
   P.ActiveEditButton := TButton(P.ControlByName('Текст'));
  end;
  P.FullKeyboard := Edit;
 finally
  Fonts.Free;
  FUpdating := False;
 end;
end;

// параметры из панели; пустые и неверные значения не меняют параметр
procedure TMouseText.ReadPanel;
var P: TInstAccuDrawFrame;
    V: Double;
    I: Integer;
    S: String;
begin
 P := AccuDrawPanel(False);
 if (P = nil) or (P.ShownBy <> Self) then exit;
 S := P.Values['Шрифт'];
 if S <> '' then FFontName := S;
 if P.FloatValue('Высота', V) and (V > 0) then FHeight := V;
 FBl := Ord(SameText(P.Values['Ж'], 'True'));
 FIt := Ord(SameText(P.Values['К'], 'True'));
 FUn := Ord(SameText(P.Values['Ч'], 'True'));
 S := P.Values['Цвет'];
 for I := 0 to High(ColorNames) do
  if ColorNames[I] = S then FColor := ColorValues[I];
 I := AlignStrings.IndexOf(P.Values['Выравнивание']);
 if I >= 0 then FAlign := I;
end;

// шрифт с параметрами в коллекции шрифтов карты
function TMouseText.FontView: TFontViewEx;
begin
 Result := TFontViewEx(Twigs.FontColEx[Twigs.FontColEx.AddFont(0, AnsiString(FFontName), FHeight, -1, CharSetDefault, FBl, FIt, FUn, 500)]);
end;

// параметры - редактируемой надписи
procedure TMouseText.ApplyParams;
begin
 if FText = nil then exit;
 FText.Text.fontView := FontView;
 FText.Text.Height := FHeight;
 FText.Text.Color := FColor;
 FText.Text.Align := FAlign;
 FText.TextDirty := True;
end;

// значение панели изменено: текст - в надпись, параметры - в надпись и настройки
procedure TMouseText.PanelChange(Sender: TObject);
var P: TInstAccuDrawFrame;
begin
 if FUpdating then exit;
 P := AccuDrawPanel(False);
 if (P = nil) or (P.ShownBy <> Self) then exit;
 if (FText <> nil) and (P.NameOf(Sender) = 'Текст') then begin
  FText.Text.Text := AnsiString(P.Values['Текст']);
  FText.TextDirty := True;
  FCursorOn := True;
 end else begin
  ReadPanel;
  SaveParams;
  ApplyParams;
 end;
 UpdateImage;
end;

// Enter: «Текст» - надпись в карту; «Высота» - проверка числа, затем снова ввод
// текста
procedure TMouseText.PanelEnter(Sender: TObject);
var P: TInstAccuDrawFrame;
    N: String;
    V: Double;
begin
 P := AccuDrawPanel(False);
 if (P = nil) or (P.ShownBy <> Self) then exit;
 N := P.NameOf(Sender);
 if N = 'Текст' then begin
  CommitText;
  exit;
 end;
 if N = 'Высота' then
  if not P.FloatValue(N, V) or (V <= 0) then begin
   MessageError('Задайте число');
   exit;
  end;
 if FText <> nil then P.ActiveEditButton := TButton(P.ControlByName('Текст'));
end;

// надпись в точке X, Y в активном слое; ввод текста
procedure TMouseText.StartText(X, Y: Double);
begin
 FText := TDotText.Create(X, Y, '', FHeight, FColor, FAlign, 0, FontView);
 FText.Selector := Selector;
 FText.ClassHandle := Twigs.LayerTable.ActiveLayer;
 FText.Code := FText.ClassHandle.ID;
 FText.FontColEx := Twigs.FontColEx;
 FCursorOn := True;
 FBlink.Enabled := True;
 ShowTextPanel(True);
end;

// надпись в карту (пустая - отменяется); снова панель параметров
procedure TMouseText.CommitText;
var T: TDotText;
begin
 if FText = nil then exit;
 if Trim(String(FText.Text.Text)) = '' then begin
  CancelText;
  exit;
 end;
 T := FText;
 FText := nil;
 FBlink.Enabled := False;
 if Assigned(OnAddPrim) and not OnAddPrim(T) then T.Free else begin
  Undo.AddUndoItem(TPrimUndo.Create(Twigs, LU_AddPrim, 'Undo.AddNewPrim...txt_SingleText'));
  Twigs.Twigs.Insert(TWG_Point, T);
  TPrimUndo(Undo.Last).AddModifiedPrim(T);
  Twigs.ClassBuildII;
  Modified;
  Selector.UpdateImage(usmAdd, T);
 end;
 ShowTextPanel(False);
 UpdateImage;
end;

procedure TMouseText.CancelText;
begin
 if FText = nil then exit;
 FreeAndNil(FText);
 FBlink.Enabled := False;
 ShowTextPanel(False);
 UpdateImage;
end;

procedure TMouseText.BlinkTimer(Sender: TObject);
begin
 FCursorOn := not FCursorOn;
 UpdateImage;
end;

// курсор - за последним символом (по ширине текста с пробелами), высота
// строки; размер шрифта и выравнивание - как в TDotText.GetGabaritesDebug,
// координаты - мировые
function TMouseText.CursorLine(out X1, Y1, X2, Y2: Double): Boolean;
var S: String;
    Typeface: ISkTypeface;
    Font, ProbeFont: ISkFont;
    Paint: ISkPaint;
    ProbeMetrics: TSkFontMetrics;
    Bounds: TRectF;
    XP, YP: Double;
    FontSize, AscentRatio, TightAscentAbs, Advance, DrawX, DrawY, H, SX: Single;
procedure Transform(PX, PY: Single; out TX, TY: Double);
begin
 TX := FText.XDot + PX * Cos(FText.Ugol) - PY * Sin(FText.Ugol);
 TY := FText.YDot + PX * Sin(FText.Ugol) + PY * Cos(FText.Ugol);
end;
begin
 Result := False;
 if (FText = nil) or (FText.Text.FontView = nil) then exit;
 S := String(FText.Text.Text);
 H := FText.Text.Height;
 Advance := 0;
 Bounds := TRectF.Empty;
 if S <> '' then begin
  Paint := TSkPaint.Create;
  Typeface := ResolveSkiaTypefaceForView(FText.Text.FontView);
  ProbeFont := TSkFont.Create(Typeface, 100);
  ProbeFont.GetMetrics(ProbeMetrics);
  if (-ProbeMetrics.Ascent) > 0.01 then AscentRatio := (-ProbeMetrics.Ascent) / 100 else AscentRatio := 1;
  FontSize := H / AscentRatio;
  Font := TSkFont.Create(Typeface, FontSize);
  Advance := Font.MeasureText(S, Bounds, Paint);
  TightAscentAbs := -Bounds.Top;
  if (TightAscentAbs > 0.0001) and (Abs(H / TightAscentAbs - 1) > 1e-4) then begin
   Font := TSkFont.Create(Typeface, FontSize * H / TightAscentAbs);
   Advance := Font.MeasureText(S, Bounds, Paint);
  end;
 end;
 FText.Text.GetXPYP(XP, YP);
 DrawX := -(Bounds.Left + Single(XP) * Bounds.Width);
 if YP < 0 then DrawY := 0 else DrawY := H * (1 - Single(YP));
 SX := FText.XKoef;
 if Abs(SX) < 1e-6 then SX := 1;
 Transform((DrawX + Advance) * SX, DrawY - H, X1, Y1);
 Transform((DrawX + Advance) * SX, DrawY + H * 0.2, X2, Y2);
 Result := True;
end;

// надпись тем же Draw32, что и сцена, и курсор; белым силуэтом на live-слое
// (смешивается со сценой в режиме Difference), как временный блок objHotSpot32
procedure TMouseText.DrawText(const Canvas: ISkCanvas);
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
    X1, Y1, X2, Y2: Double;
begin
 if (FText = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  if FText.Text.Text <> '' then begin
   OldCanvas := Drawer.SwapSkCanvas(Canvas);
   PrevWorld := Drawer.UseWorldCoords;
   Drawer.UseWorldCoords := True;
   try
    FText.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
   finally
    Drawer.UseWorldCoords := PrevWorld;
    Drawer.RestoreSkCanvas(OldCanvas);
   end;
  end;
  if FCursorOn and CursorLine(X1, Y1, X2, Y2) then Canvas.DrawLine(X1, Y1, X2, Y2, SkPen(Canvas, TAlphaColorRec.White, 2, False));
  Paint := TSkPaint.Create;
  Paint.Color := TAlphaColorRec.White;
  Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcIn);
  Canvas.DrawPaint(Paint);
 finally
  Canvas.Restore;
 end;
end;

procedure TMouseText.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 if LOperation = txt_SingleText then DrawText(Canvas);
end;

// Esc - отмена надписи; без надписи - инструменту (выход)
procedure TMouseText.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
 if (Key = vkEscape) and (FText <> nil) then begin
  CancelText;
  Key := 0;
  Hook := True;
  exit;
 end;
 inherited;
end;

procedure TMouseText.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if LOperation <> txt_SingleText then exit;
 Stvor_.X1 := xyNull;
 if Twigs.Settings.psAuto then emGetDotMarker(X, Y, nil, Stvor_, objTemporary, True, True, True);
 UpdateImage;
end;

// щелчок: новая надпись или перенос точки редактируемой
procedure TMouseText.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown or (LOperation <> txt_SingleText) then exit;
 if Marker.Visible then begin
  X := Marker.mX;
  Y := Marker.mY;
 end;
 if FText = nil then StartText(X, Y) else begin
  FText.XDot := X;
  FText.YDot := Y;
  FText.TextDirty := True;
 end;
 UpdateImage;
end;

// правая кнопка - надпись в карту
procedure TMouseText.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 CommitText;
end;

function TMouseText.Hint: String;
begin
 if FText = nil then Result := 'Текст: щелкните точку надписи' else
  Result := 'Текст: Enter - в карту, Esc - отмена, щелчок - перенос';
end;

end.
