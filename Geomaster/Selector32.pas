unit Selector32;

// Совместимость со старым модулем Selector (Geomaster, Delphi 7, GDI).
// Глобальные функции старого Selector перенаправляются на текущий TSelector
// (newSelector), который задается через SetGSelector.
// Старые примитивы рисования (PMoveTo, PLineTo, DrawLine, PSetPixel, PTextOut)
// рисуют на ISkCanvas в мировых координатах только между BeginSkiaDraw и
// EndSkiaDraw (в DrawTemp); вне этого блока они ничего не делают.
// Переменная LOperation старого Selector - это поле GSelector.LOperation;
// функция LOperation только читает его, запись - через GSelector.LOperation.

interface

uses System.Types, System.UITypes, System.Skia, FMX.Controls, FMX.Graphics,
     Collect, ogcBasic, newSettings, newSelector, drawGrid;

type
 TSect = newSelector.TSect;
 TShortSect = newSelector.TShortSect;
 PSect = newSelector.PSect;
 TRumb = newSelector.TRumb;
 TMRect = newSelector.TMRect;
 PGraphSet = ^TGraphSet;

var GSelector: TSelector; // текущий селектор

 procedure SetGSelector(ASelector: TSelector);
// преобразования
 function XPix(XCoord: Double): Int64;
 function YPix(YCoord: Double): Int64;
 function XGeo(XCoord: Double): Double;
 function YGeo(YCoord: Double): Double;
 function XRasst(XCoord: Double): LongInt;
 function YRasst(YCoord: Double): LongInt;
 function XGeoRasst(XCoord: Double): Double;
 function YGeoRasst(YCoord: Double): Double;
 function RealDouble(V: Double): Double;
 function RealInt(V: Double): Int64;
 function AngleToStr(Angle: Double; UseCalc: Boolean; Razd: String): String;
 function DirectToRumb(Angle: Double): TRumb;
// сравнение и видимость
 function EqualPoints(D1, D2: Pointer): Boolean;
 function EqualAnyPoints(X, Y, X2, Y2: Double): Boolean;
 function EqualCoord(P1, P2: Double): Boolean;
 function PointVis(X, Y: Double): Boolean;
 function PointVis1(X, Y: Double): Boolean;
 function LineVis(XX, YY, XX1, YY1: Double): Boolean;
 function PointInSect(X, Y: Double; Sect: TSect): Boolean;
// глобальное состояние старого Selector
 function GTwgForm: Pointer;
 function GNForm: TControl;
 function GCanvas: TCanvas;
 function GRect: TSect;
 function GPRect: TRect;
 function GDx: Double;
 function GDy: Double;
 function GMs: Double;
 function GLineCol: TSortedCollection;
 function GSqwearCol: TSortedCollection;
 function GPointCol: TSortedCollection;
 function GFontCollect: PCollection;
 function GFontSet: PCollection;
 function LOperation: Integer;
// модули ustnGlobalSettings, drawGrid, GGraphSet старой программы
 function GlobalSettings: TGlobalSettings;
 function GGraphSet: PGraphSet;
 function GridPath: TGridPath;
// перерисовка: в старой программе - перерисовка изображения, здесь - live-слоя
 procedure UpdateImage(Check: Boolean = False);
// курсоры (заглушки)
 procedure SetActiveCursor(const Cur: NativeUInt);
 function GetActiveCursor: NativeUInt;
 function LoadCursor(Instance: NativeUInt; Name: PChar): NativeUInt;
 function MakeIntResource(Value: Integer): PChar;
// рисование на ISkCanvas (только между BeginSkiaDraw и EndSkiaDraw)
 procedure BeginSkiaDraw(const Canvas: ISkCanvas; Color: TAlphaColor; WidthPix: Single = 1; Dashed: Boolean = False);
 procedure EndSkiaDraw;
 function SkiaDrawActive: Boolean;
 function SkiaCanvas: ISkCanvas;
 function PixToWorld(Pix: Single): Single;
 procedure SkiaPen(Color: TAlphaColor; WidthPix: Single = 1; Dashed: Boolean = False);
 procedure PMoveTo(X, Y: Double);
 procedure PLineTo(X, Y: Double);
 procedure DrawLine(XX, YY, XX1, YY1: Double);
 procedure PSetPixel(X, Y: Double);
 procedure PSetPixelDbl(X, Y: Double);
 procedure PTextOut(X, Y: Double; Text: String);

implementation

uses System.Math.Vectors, SysUtils;

var FSkCanvas: ISkCanvas;
    FSkPaint: ISkPaint;
    FSkScale: Single;
    FCurX, FCurY: Single;

procedure SetGSelector(ASelector: TSelector);
begin
 GSelector := ASelector;
end;

{ преобразования }

function XPix(XCoord: Double): Int64;
begin
 Result := GSelector.XPix(XCoord);
end;

function YPix(YCoord: Double): Int64;
begin
 Result := GSelector.YPix(YCoord);
end;

function XGeo(XCoord: Double): Double;
begin
 Result := GSelector.XGeo(Round(XCoord));
end;

function YGeo(YCoord: Double): Double;
begin
 Result := GSelector.YGeo(Round(YCoord));
end;

function XRasst(XCoord: Double): LongInt;
begin
 Result := GSelector.XRasst(XCoord);
end;

function YRasst(YCoord: Double): LongInt;
begin
 Result := GSelector.YRasst(YCoord);
end;

function XGeoRasst(XCoord: Double): Double;
begin
 Result := GSelector.XGeoRasst(XCoord);
end;

function YGeoRasst(YCoord: Double): Double;
begin
 Result := GSelector.YGeoRasst(YCoord);
end;

function RealDouble(V: Double): Double;
begin
 Result := GSelector.RealDouble(V);
end;

function RealInt(V: Double): Int64;
begin
 Result := GSelector.RealInt(V);
end;

function AngleToStr(Angle: Double; UseCalc: Boolean; Razd: String): String;
begin
 Result := GSelector.AngleToStr(Angle, UseCalc, Razd);
end;

function DirectToRumb(Angle: Double): TRumb;
begin
 Result := GSelector.DirectToRumb(Angle);
end;

{ сравнение и видимость }

function EqualPoints(D1, D2: Pointer): Boolean;
begin
 Result := GSelector.EqualPoints(D1, D2);
end;

function EqualAnyPoints(X, Y, X2, Y2: Double): Boolean;
begin
 Result := GSelector.EqualAnyPoints(X, Y, X2, Y2);
end;

function EqualCoord(P1, P2: Double): Boolean;
begin
 Result := GSelector.EqualCoord(P1, P2);
end;

function PointVis(X, Y: Double): Boolean;
begin
 Result := GSelector.PointVis(X, Y);
end;

function PointVis1(X, Y: Double): Boolean;
begin
 Result := GSelector.PointVis1(X, Y);
end;

function LineVis(XX, YY, XX1, YY1: Double): Boolean;
begin
 Result := GSelector.LineVis(XX, YY, XX1, YY1);
end;

function PointInSect(X, Y: Double; Sect: TSect): Boolean;
begin
 Result := GSelector.PointInSect(X, Y, Sect);
end;

{ глобальное состояние }

function GTwgForm: Pointer;
begin
 Result := GSelector.GTwgForm;
end;

function GNForm: TControl;
begin
 Result := GSelector.GNForm;
end;

function GCanvas: TCanvas;
begin
 Result := GSelector.GCanvas;
end;

function GRect: TSect;
begin
 Result := GSelector.GRect;
end;

function GPRect: TRect;
begin
 Result := GSelector.GPRect;
end;

function GDx: Double;
begin
 Result := GSelector.GDx;
end;

function GDy: Double;
begin
 Result := GSelector.GDy;
end;

function GMs: Double;
begin
 Result := GSelector.GMS;
end;

function GLineCol: TSortedCollection;
begin
 Result := GSelector.GLineCol;
end;

function GSqwearCol: TSortedCollection;
begin
 Result := GSelector.GSqwearCol;
end;

function GPointCol: TSortedCollection;
begin
 Result := GSelector.GPointCol;
end;

function GFontCollect: PCollection;
begin
 Result := GSelector.GFontCollect;
end;

function GFontSet: PCollection;
begin
 Result := GSelector.GFontSet;
end;

function LOperation: Integer;
begin
 Result := GSelector.LOperation;
end;

function GlobalSettings: TGlobalSettings;
begin
 Result := GSelector.GlobalSettings;
end;

function GGraphSet: PGraphSet;
begin
 Result := @GSelector.GGraphSet;
end;

function GridPath: TGridPath;
begin
 Result := TGridPath(GSelector.GridPath);
end;

{ перерисовка }

procedure UpdateImage(Check: Boolean);
begin
 if GSelector <> nil then GSelector.UpdateOverlay;
end;

{ курсоры }

procedure SetActiveCursor(const Cur: NativeUInt);
begin
end;

function GetActiveCursor: NativeUInt;
begin
 Result := 0;
end;

function LoadCursor(Instance: NativeUInt; Name: PChar): NativeUInt;
begin
 Result := 0;
end;

function MakeIntResource(Value: Integer): PChar;
begin
 Result := PChar(NativeUInt(Word(Value)));
end;

{ рисование на ISkCanvas }

procedure BeginSkiaDraw(const Canvas: ISkCanvas; Color: TAlphaColor; WidthPix: Single; Dashed: Boolean);
var M: TMatrix;
begin
 FSkCanvas := Canvas;
 FSkScale := 1;
 if Canvas <> nil then begin
 // толщины и размеры в пикселах переводятся в локальные (мировые) единицы канвы
  M := Canvas.GetLocalToDeviceAs3x3;
  FSkScale := Sqrt(Sqr(M.m11) + Sqr(M.m12));
  if FSkScale <= 0 then FSkScale := 1;
 end;
 FCurX := 0;
 FCurY := 0;
 SkiaPen(Color, WidthPix, Dashed);
end;

procedure EndSkiaDraw;
begin
 FSkCanvas := nil;
 FSkPaint := nil;
end;

function SkiaDrawActive: Boolean;
begin
 Result := FSkCanvas <> nil;
end;

function SkiaCanvas: ISkCanvas;
begin
 Result := FSkCanvas;
end;

function PixToWorld(Pix: Single): Single;
begin
 Result := Pix / FSkScale;
end;

procedure SkiaPen(Color: TAlphaColor; WidthPix: Single; Dashed: Boolean);
var Dash: Single;
begin
 FSkPaint := TSkPaint.Create;
 FSkPaint.AntiAlias := True;
 FSkPaint.Style := TSkPaintStyle.Stroke;
 FSkPaint.Color := Color;
 FSkPaint.StrokeWidth := PixToWorld(WidthPix);
// аналог пера ps_Dot
 if Dashed then begin
  Dash := PixToWorld(3);
  FSkPaint.PathEffect := TSkPathEffect.MakeDash([Dash, Dash], 0);
 end;
end;

procedure PMoveTo(X, Y: Double);
begin
 FCurX := X;
 FCurY := Y;
end;

procedure PLineTo(X, Y: Double);
begin
 if FSkCanvas <> nil then FSkCanvas.DrawLine(FCurX, FCurY, X, Y, FSkPaint);
 FCurX := X;
 FCurY := Y;
end;

procedure DrawLine(XX, YY, XX1, YY1: Double);
begin
 if FSkCanvas = nil then exit;
 FSkCanvas.DrawLine(XX, YY, XX1, YY1, FSkPaint);
end;

procedure PSetPixel(X, Y: Double);
var R: Single;
begin
 if FSkCanvas = nil then exit;
// точка размером 3 px текущим цветом пера
 R := PixToWorld(1.5);
 FSkCanvas.DrawRect(TRectF.Create(X - R, Y - R, X + R, Y + R), FSkPaint);
end;

procedure PSetPixelDbl(X, Y: Double);
begin
 PSetPixel(X, Y);
end;

procedure PTextOut(X, Y: Double; Text: String);
var Font: ISkFont;
    Paint: ISkPaint;
begin
 if (FSkCanvas = nil) or (Text = '') then exit;
// подпись высотой 12 px текущим цветом пера
 Font := TSkFont.Create(nil, PixToWorld(12));
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Color := FSkPaint.Color;
 FSkCanvas.DrawSimpleText(Text, X, Y, Font, Paint);
end;

end.
