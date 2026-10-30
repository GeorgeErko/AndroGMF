unit GrapherTestMain;

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes,
     System.IOUtils, System.Math, FMX.Types, FMX.Controls, FMX.Forms,
     FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Skia,
     System.Skia, ogcBasic, ogcGeometry, ttfGeometry, ogcMapSpace,
     ogcSkiaDrawer;

// Тест иерархии GRAPHER: загрузка GeoJSON в TogsMapSpace, отрисовка
// ogcSkiaDrawer в TSkPaintBox, текст шрифтом из папки Fonts,
// сохранение в GeoJSON и двоичный файл.
// Колесо мыши - масштаб, левая кнопка - сдвиг карты.
// "Открыть GMF" - временно: чтение GMF исходными модулями GMF (rewriteGMF),
// только с define GMF (иначе модули GMF не подключаются, вызов - ошибка).
// Отладочный вывод - WriteIn: консоль (Windows), logcat (Android).

type
  TFormGrapherTest = class(TForm)
   procedure FormCreate(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
  private
   fPaintBox: TSkPaintBox;
   fToolBar: TToolBar;
   fOpenDialog: TOpenDialog;
   fSaveDialog: TSaveDialog;
   fDrawer: TogsSkiaDrawer;
   fMap: TogsMapSpace;
   fMousePos: TPointF;
   fDragging: Boolean;
  // пользователь изменил вид (масштаб/сдвиг): при изменении размера не вписывать
   fUserView: Boolean;
   procedure AddButton(const Caption: String; OnClick: TNotifyEvent);
   procedure SyncDrawerSize;
  // события карты
   procedure PaintBoxDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
   procedure PaintBoxResize(Sender: TObject);
   procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
   procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
  // команды
   procedure OpenGeoJSONClick(Sender: TObject);
   procedure SaveGeoJSONClick(Sender: TObject);
   procedure OpenBinaryClick(Sender: TObject);
   procedure SaveBinaryClick(Sender: TObject);
   procedure LoadFontClick(Sender: TObject);
   procedure AddTextClick(Sender: TObject);
   procedure FitClick(Sender: TObject);
   procedure OpenGMFClick(Sender: TObject);
  public
   function FontsPath: String;
  end;

var
  FormGrapherTest: TFormGrapherTest;

implementation

// Writer.WriteIn - отладочный вывод: консоль (Windows), logcat (Android);
// rewriteGMF (и через него модули GMF) - только с define GMF
uses Writer{$IFDEF GMF}, rewriteGMF{$ENDIF};

{$R *.fmx}

const
  cGeoJSONFilter = 'GeoJSON (*.geojson;*.json)|*.geojson;*.json';
  cBinaryFilter = 'Карта GRAPHER (*.ogs)|*.ogs';

// файл/папка рядом с exe, иначе в папке проекта (exe в Win64\Debug)
function FindNearExe(const Name: String): String;
begin
 Result := TPath.Combine(ExtractFilePath(ParamStr(0)), Name);
 if FileExists(Result) or TDirectory.Exists(Result) then exit;
 Result := ExpandFileName(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\' + Name));
end;

function TFormGrapherTest.FontsPath: String;
begin
// Windows: Fonts рядом с exe или в папке проекта, Android: Documents/Fonts
{$IFDEF ANDROID}
 Result := TPath.Combine(TPath.GetDocumentsPath, ');
{$ELSE}
 Result := FindNearExe('');
{$ENDIF}
end;

procedure TFormGrapherTest.FormCreate(Sender: TObject);
begin
 fToolBar := TToolBar.Create(Self);
 fToolBar.Parent := Self;
 AddButton('Открыть GeoJSON', OpenGeoJSONClick);
 AddButton('Сохранить GeoJSON', SaveGeoJSONClick);
 AddButton('Открыть .ogs', OpenBinaryClick);
 AddButton('Сохранить .ogs', SaveBinaryClick);
 AddButton('Шрифт...', LoadFontClick);
 AddButton('Текст', AddTextClick);
 AddButton('Вписать', FitClick);
 AddButton('Открыть GMF', OpenGMFClick);
//
 fPaintBox := TSkPaintBox.Create(Self);
 fPaintBox.Parent := Self;
 fPaintBox.Align := TAlignLayout.Client;
 fPaintBox.HitTest := True;
 fPaintBox.OnDraw := PaintBoxDraw;
 fPaintBox.OnResize := PaintBoxResize;
 fPaintBox.OnMouseDown := PaintBoxMouseDown;
 fPaintBox.OnMouseMove := PaintBoxMouseMove;
 fPaintBox.OnMouseUp := PaintBoxMouseUp;
 fPaintBox.OnMouseWheel := PaintBoxMouseWheel;
//
 fOpenDialog := TOpenDialog.Create(Self);
 fSaveDialog := TSaveDialog.Create(Self);
// рисователь без Selector: карта создает свой Selector и связывает его с рисователем
 fDrawer := TogsSkiaDrawer.CreatePaintBox(nil, fPaintBox);
 fMap := TogsMapSpace.Create(fDrawer, FontsPath);
 fMap.ogsSelector.DevicePPI := 96;
 SyncDrawerSize;
 WriteIn([Format('Шрифтов: %d (%s)', [ogsFontManager.Count, FontsPath])]);
// пример рядом с exe или в папке проекта
 if FileExists(FindNearExe('sample.geojson')) then begin
  fMap.LoadGeoJSON(FindNearExe('sample.geojson'));
  WriteIn([Format('sample.geojson: %d объектов, шрифтов: %d', [fMap.Geometry.Count, ogsFontManager.Count])]);
 end;
end;

procedure TFormGrapherTest.FormDestroy(Sender: TObject);
begin
 FreeAndNil(fMap);
 FreeAndNil(fDrawer);
end;

procedure TFormGrapherTest.AddButton(const Caption: String; OnClick: TNotifyEvent);
var B: TButton;
begin
 B := TButton.Create(Self);
 B.Parent := fToolBar;
 B.Align := TAlignLayout.Left;
 B.Text := Caption;
 B.Width := Length(Caption) * 8 + 24;
 B.Margins.Left := 4;
 B.OnClick := OnClick;
end;

procedure TFormGrapherTest.SyncDrawerSize;
begin
 if fDrawer = nil then exit;
 fDrawer.Width := Max(1, Round(fPaintBox.Width));
 fDrawer.Height := Max(1, Round(fPaintBox.Height));
end;

procedure TFormGrapherTest.PaintBoxDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
begin
 if (fMap = nil) or (fDrawer = nil) then exit;
 fDrawer.BeginFrame(ACanvas, ADest);
 try
  fDrawer.Clear(TColorRec.White);
  fMap.Draw(fDrawer);
 finally
  fDrawer.EndFrame;
 end;
end;

procedure TFormGrapherTest.PaintBoxResize(Sender: TObject);
begin
 if fMap = nil then exit;
// масштаб сохраняется, видимая область пересчитывается под новый размер
 SyncDrawerSize;
 if fUserView then fMap.ogsSelector.UpdateRects(False) else fMap.UpdateObject(True);
 fPaintBox.Redraw;
end;

procedure TFormGrapherTest.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 fMousePos := PointF(X, Y);
 fDragging := Button = TMouseButton.mbLeft;
end;

procedure TFormGrapherTest.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var Selector: TogsSelector;
begin
 if fDragging and (fMap <> nil) then begin
  Selector := fMap.ogsSelector;
 // сдвиг карты вслед за мышью (ось Y модели направлена вниз, как у экрана)
  Selector.Move(-Selector.geoDist(X - fMousePos.X), -Selector.geoDist(Y - fMousePos.Y));
  fUserView := True;
  fPaintBox.Redraw;
 end;
 fMousePos := PointF(X, Y);
end;

procedure TFormGrapherTest.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 fDragging := False;
end;

procedure TFormGrapherTest.PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
 if fMap = nil then exit;
// масштаб относительно точки под курсором (TogsDrawer.MouseWheel)
 fDrawer.MouseWheel(Sender, Shift, WheelDelta, Point(Round(fMousePos.X), Round(fMousePos.Y)), Handled);
 Handled := True;
 fUserView := True;
 fPaintBox.Redraw;
end;

procedure TFormGrapherTest.OpenGeoJSONClick(Sender: TObject);
var N: Integer;
begin
 fOpenDialog.Filter := cGeoJSONFilter;
 if not fOpenDialog.Execute then exit;
 fUserView := False;
 N := fMap.LoadGeoJSON(fOpenDialog.FileName);
 WriteIn([Format('%s: загружено объектов %d, блоков %d, типов линий %d', [ExtractFileName(fOpenDialog.FileName), N, fMap.PLib.Count, fMap.LLib.Count])]);
end;

procedure TFormGrapherTest.SaveGeoJSONClick(Sender: TObject);
var N: Integer;
begin
 fSaveDialog.Filter := cGeoJSONFilter;
 fSaveDialog.DefaultExt := 'geojson';
 if not fSaveDialog.Execute then exit;
 N := fMap.SaveGeoJSON(fSaveDialog.FileName);
 WriteIn([Format('%s: записано Feature %d', [ExtractFileName(fSaveDialog.FileName), N])]);
end;

procedure TFormGrapherTest.OpenBinaryClick(Sender: TObject);
var NewMap: TogsMapSpace;
begin
 fOpenDialog.Filter := cBinaryFilter;
 if not fOpenDialog.Execute then exit;
// новая карта создает свой Selector и связывает его с рисователем
 NewMap := TogsMapSpace.LoadFromFile(fOpenDialog.FileName, fDrawer);
 fMap.Free;
 fMap := NewMap;
 fUserView := False;
 WriteIn([Format('%s: объектов %d', [ExtractFileName(fOpenDialog.FileName), fMap.Geometry.Count])]);
end;

procedure TFormGrapherTest.SaveBinaryClick(Sender: TObject);
begin
 fSaveDialog.Filter := cBinaryFilter;
 fSaveDialog.DefaultExt := 'ogs';
 if not fSaveDialog.Execute then exit;
 fMap.SaveToFile(fSaveDialog.FileName);
 WriteIn([ExtractFileName(fSaveDialog.FileName) + ': сохранено']);
end;

procedure TFormGrapherTest.LoadFontClick(Sender: TObject);
var Index: Integer;
begin
 fOpenDialog.Filter := 'Шрифты (*.ttf;*.otf)|*.ttf;*.otf';
 if not fOpenDialog.Execute then exit;
 Index := ogsFontManager.LoadFontFile(nil, fOpenDialog.FileName);
 if Index < 0 then WriteIn(['Ошибка загрузки шрифта: ' + ogsFontManager.Errors.Text]) else
  WriteIn([Format('Шрифт "%s" загружен, всего шрифтов: %d', [ogsFontManager.Item[Index].fontName, ogsFontManager.Count])]);
end;

procedure TFormGrapherTest.AddTextClick(Sender: TObject);
var FC: TFontCollect;
    R: TogsRect;
    TextPrim: TogsTextString;
begin
 if ogsFontManager.Count = 0 then begin
  WriteIn(['Нет шрифтов: положите *.ttf в ' + FontsPath + ' или загрузите кнопкой "Шрифт..."']);
  exit;
 end;
// шрифт FreeSans, иначе первый загруженный
 ogsFontManager.FindBy('FreeSans', [], FC);
 R := fMap.ogsSelector.ActiveRect;
 TextPrim := TogsTextString.Create(fMap.ogsSelector, FC, (R.XMin + R.XMax) / 2, (R.YMin + R.YMax) / 2, 0,
                               R.Height / 15, 0, 1, [ftaCenter, ftaVerticalCenter],
                               FC.FontName + ': Привет, GRAPHER!', '', TColorRec.Navy);
 fMap.AddPrim(TextPrim);
 fMap.UpdateObject(False);
 WriteIn([Format('Добавлен текст шрифтом "%s", объектов: %d', [FC.FontName, fMap.Geometry.Count])]);
end;

procedure TFormGrapherTest.FitClick(Sender: TObject);
begin
 fUserView := False;
 fMap.UpdateObject(True);
end;

// временно: карта GMF читается исходными модулями GMF (rewriteGMF) и переводится
// в fMap; без define GMF модули GMF не подключаются - ошибка при вызове
procedure TFormGrapherTest.OpenGMFClick(Sender: TObject);
{$IFDEF GMF}
var FileName, AppPath: String;
    Files: TStringDynArray;
    N: Integer;
begin
{$IFDEF ANDROID}
// классификатор и карта: каталог данных приложения, первый .gmf из него
 AppPath := TPath.GetDocumentsPath;
 Files := TDirectory.GetFiles(AppPath, '*.gmf');
 if Length(Files) = 0 then begin
  WriteIn(['Нет файлов *.gmf в ' + AppPath]);
  exit;
 end;
 FileName := Files[0];
{$ELSE}
// классификатор: каталог exe
 AppPath := ExtractFilePath(ParamStr(0));
 fOpenDialog.Filter := 'Карта GMF (*.gmf)|*.gmf';
 if not fOpenDialog.Execute then exit;
 FileName := fOpenDialog.FileName;
{$ENDIF}
 fUserView := False;
 try
  N := LoadGMF(fMap, FileName, AppPath);
  WriteIn([Format('%s: загружено объектов %d, блоков %d, типов линий %d', [ExtractFileName(FileName), N, fMap.PLib.Count, fMap.LLib.Count])]);
 except
  on E: Exception do WriteIn(['rewriteGMF: ', E.ClassName, ': ', E.Message]);
 end;
end;
{$ELSE}
begin
 raise Exception.Create('Чтение GMF не подключено: нужен define GMF (модуль rewriteGMF)');
end;
{$ENDIF}

end.
