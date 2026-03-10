unit newPainter;

interface

uses
 Classes, SysUtils, Collect, newSelector, System.Types, FMX.Graphics,
 System.UITypes, FMX.Objects, Intervals,
 Polygons;


type
  TFPPenMode = (fp1, fp2, fp3);

 { TGrPen }

 TGrPen = class(TTwgObject)
 private
  fColor: TColor;
  fMode:  TFPPenMode;
  fWidth: Integer;
  procedure SetColor(AValue: TColor);
  procedure SetMode(AValue: TFPPenMode);
  procedure SetWidth(AValue: Integer);
 public
  Selector: TSelector;
  Canvas: TCanvas;
  constructor Create(Selector_: TSelector; Canvas_: TCanvas);
  property Color: TColor read fColor write SetColor;
  property Mode: TFPPenMode read fMode write SetMode;
  property Width: Integer read fWidth write SetWidth;
  procedure DrawLine(X1, Y1, X2, Y2: Double);
  procedure DrawPolyLine(MRect: TMRect;Points: PCollection);
 end;

var GrPoints: Array [0..100000] of TPoint;


type

 TGrDot = class(TTwgObject)
  X, Y: Double;
 end;

 { TGrBrush }

 TGrBrush = class(TTwgObject)
 private
  fColor:TColor;
  procedure SetColor(AValue: TColor);
 public
  Selector: TSelector;
  Canvas:TCanvas;
  constructor Create(Selector_: TSelector; Canvas_: TCanvas);
  property Color: TColor read fColor write SetColor;
  procedure DrawPolygon(MRect: TMRect;Points: PCollection);
 end;

 TGrFont = class(TTwgObject)

 end;

type

 { TPainterGDI }

 TPainterGDI = class(TTwgObject)
 private
  fPen: TGrPen;
  fBrush: TGrBrush;
  Selector: TSelector;
  Canvas: TCanvas;
  Image: TImage;
  fColor: TColor;
  fOnPaint: TNotifyEvent;
  procedure SetBrush(AValue: TGrBrush);
  procedure SetPen(AValue: TGrPen);
 public
  constructor Create(Selector_: TSelector);
  destructor Destroy;override;
  property Pen: TGrPen read fPen write SetPen;
  property Brush: TGrBrush read fBrush write SetBrush;
  property OnPaint: TNotifyEvent read fOnPaint write fOnPaint;
 // рисование
  procedure BeginPaint;
  procedure EndPaint;
  procedure DrawLine(X1, Y1, X2, Y2: Double);
 // общая процедура рисования
  procedure Paint;
 end;


implementation uses Writer, System.Math.Vectors;

{ TGrPen }

constructor TGrPen.Create(Selector_: TSelector; Canvas_: TCanvas);
begin
 Selector := Selector_;
 Canvas := Canvas_;
end;

procedure TGrPen.SetColor(AValue: TColor);
begin
 if fColor=AValue then Exit;
 fColor:=AValue;
 Canvas.Stroke.Color:=fColor;
end;

procedure TGrPen.SetMode(AValue: TFPPenMode);
begin
 if fMode=AValue then Exit;
 fMode:=AValue;
end;

procedure TGrPen.SetWidth(AValue: Integer);
begin
 if fWidth=AValue then Exit;
 fWidth:=AValue;
 Canvas.Stroke.Thickness:=fWidth;
end;

procedure TGrPen.DrawLine(X1, Y1, X2, Y2: Double);
begin
 With Selector, GRect do
 If PointVis(X1, Y1) and PointVis(X2, Y2) then begin
  Canvas.DrawLine(PointF(XPix(X1), YPix(Y1)), PointF(XPix(X2), YPix(Y2)), 1);
//  WriteIn(['Paint1=',XPix(X1), YPix(Y1),XPix(X2), YPix(Y2)]);
 end else
 If Clip_Interval(Left, Bottom, Right, Top, X1, Y1, X2, Y2) then begin
  Canvas.DrawLine(PointF(XPix(X1), YPix(Y1)), PointF(XPix(X2), YPix(Y2)), 1);
 end;
end;

procedure TGrPen.DrawPolyLine(MRect: TMRect; Points: PCollection);
var I, J, Count: Integer;
begin
 Count := 0;
 If not MRect.Visible(Selector.GRect) then exit;
 With Selector do
  If PointVis(MRect.XMax, MRect.YMax) and PointVis(MRect.XMin, MRect.YMin) then
   For I := 0 to Points.Count-1 do begin
    GrPoints[I+1].X := XPix(TGrDot(Points[I]).X);
    GrPoints[I+1].Y := YPix(TGrDot(Points[I]).Y);
    Inc(Count);
    If I = Points.Count-1 then
      for J:=2 to Count do
       Canvas.DrawLine(PointF(GrPoints[J-1].X,GrPoints[J-1].Y),PointF(GrPoints[J].X,GrPoints[J].Y),1);
   end
 else begin
  For I := 0 to Points.Count-2 do With TGrDot(Points[I]) do
    DrawLine(X, Y, TGrDot(Points[I+1]).X, TGrDot(Points[I+1]).Y);
  end;
end;

{ TGrBrush }

constructor TGrBrush.Create(Selector_: TSelector; Canvas_: TCanvas);
begin
 Selector := Selector_;
 Canvas := Canvas_;
end;

procedure TGrBrush.SetColor(AValue: TColor);
begin
 Canvas.Fill.Color:=AValue;
end;

procedure TGrBrush.DrawPolygon(MRect: TMRect; Points: PCollection);
var I, Count: Integer; Poly: TPolygon;
Procedure Draw;
var I: Integer;
begin
 SetLength(Poly, Count);
 With Selector do
  for I:=0 to Count-1 do
   Poly[I]:=PointF(XPix(TGrDot(Points[I]).X),YPix(TGrDot(Points[I]).Y));
 Canvas.FillPolygon(Poly,1);
end;
begin
 Count := 0;
 If not MRect.Visible(Selector.GRect) then exit;
 With Selector do
  If PointVis(MRect.XMax, MRect.YMax) and PointVis(MRect.XMin, MRect.YMin) then
   begin
    Count:=Points.Count;
    if Count>2 then Draw;
   end
  else begin
   With GRect do Clip_Polygon(Left, Bottom, Right, Top, Points);
   Count:=Points.Count;
   If Count>2 then Draw;
  end;
end;

{ TPainterGDI }

constructor TPainterGDI.Create(Selector_: TSelector);
begin
// используем селектор для масштабирования
 Selector := Selector_;
// изображение на котором рисуем
 Image := TImage.Create(Selector.GNForm);
// Image.Visible := False;
 Image.BoundsRect := RectF(0,0,Selector.GNForm.Width,Selector.GNForm.Height);
// Selector.GNForm.InsertControl(Image);
 Image.Bitmap.SetSize(Round(Image.Width),Round(Image.Height));
 Canvas := Image.Bitmap.Canvas;
 fColor := TAlphaColors.White; // по умолчанию
 fPen := TGrPen.Create(Selector_, Canvas);
 fBrush := TGrBrush.Create(Selector_, Canvas);
end;

destructor TPainterGDI.Destroy;
begin
 inherited Destroy;
 Image.Free;
 if fPen <> nil then fPen.Free;
end;

procedure TPainterGDI.SetPen(AValue: TGrPen);
begin
 if fPen = AValue then exit;
 fPen.Free;
 fPen := AValue;
end;

procedure TPainterGDI.SetBrush(AValue: TGrBrush);
begin
 if fBrush = AValue then Exit;
 fBrush.Free;
 fBrush := AValue;
end;

procedure TPainterGDI.BeginPaint;
begin
// Image.Picture:=nil;
 Canvas.Fill.Color:=fColor;
 Canvas.FillRect(RectF(0,0,Image.Width,Image.Height),0,0,[],1);
end;

procedure TPainterGDI.EndPaint;
begin
 if Image.Bitmap.Width>0 then
  Selector.GCanvas.DrawBitmap(Image.Bitmap,RectF(0,0,Image.Bitmap.Width,Image.Bitmap.Height),RectF(0,0,Image.Width,Image.Height),1);
end;

procedure TPainterGDI.DrawLine(X1, Y1, X2, Y2: Double);
begin
 fPen.DrawLine(X1, Y1, X2, Y2);
end;

procedure TPainterGDI.Paint;
begin
 BeginPaint;
//  If not Assigned(fOnPaintPrev) then fOnPaintPrev(Self);
   If not Assigned(fOnPaint) then fOnPaint(Self);
//   If not Assigned(fOnPaintNext) then fOnPaint(Self);
 EndPaint;
end;

end.








{ TPainter32 }

 TPainter32 = class(TTwgObject)
  Selector:TSelector;
  Image32:TImage32;
  Constructor Create(Selector_:TSelector);
  Destructor Destroy;override;
 //
  procedure Paint(Canvas: TCanvas);
 end;


{ TPainter32 }

constructor TPainter32.Create(Selector_: TSelector);
begin
 Selector:=Selector_;
 //
 Image32:=TImage32.Create(Selector.GNForm);Selector.GNForm.InsertControl(Image32);
 Image32.BoundsRect:=Selector.GNForm.ClientRect;
 Image32.Visible:=False;
 Image32.Width:=Selector.GNForm.ClientWidth;
 Image32.Height:=Selector.GNForm.ClientHeight;
// WriteIn(['bmp.Width',Image32.Bitmap.width]);
 Image32.Bitmap.Width:=Selector.GNForm.Width;
 Image32.Bitmap.Height:=Selector.GNForm.Height;
end;

destructor TPainter32.Destroy;
begin
 inherited Destroy;
 Image32.Free;
end;

procedure TPainter32.Paint(Canvas:TCanvas);
var I:Integer;Col:TColor32Entry;
begin
 Col.R:=255;Col.G:=0;Col.B:=0;Col.A:=255;
// Image32.BeginUpdate;
 Image32.Buffer.Clear(Color32(clWhite));
 For I:=0 to 100000 do
 With Image32 do Buffer.LineS(Random(Width),Random(Width),Random(Width),Random(Width),Color32(clRed));
 WriteIn([Random(Image32.Width)]);
// Image32.EndUpdate;
 Image32.Buffer.DrawTo(Canvas.Handle,0,0);
end;


