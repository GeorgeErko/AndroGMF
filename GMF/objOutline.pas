unit objOutline;

// Контуры объектов для выделения. Строятся один раз и хранятся в TogsSkiaObject
// (OutlinePath, OutlineVertices, OutlineMidPoints); сбрасываются вместе с ним при
// Modified. Контур блока строится один раз в его локальных координатах
// (TGeoBlock.LocalOutline) и переносится на экземпляр матрицей.

interface

uses System.Types, System.UITypes, System.Skia, TwgDraw, newForm0, ogcDrawerSkia;

 procedure ogsEnsureOutline(Obj: TTD; Twigs: TTwigsCollect);
 procedure ogsDrawOutline(const Canvas: ISkCanvas; SkObj: TogsSkiaObject;
  const LineColor: TAlphaColor; const LineWidthPix: Single;
  const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
  const RectFillColor: TAlphaColor; const ViewScale: Single;
  const RadiusPix: Single);

implementation

uses System.Math.Vectors, System.Generics.Collections, EcDot, EcLot, WpTwigs,
     newBlock, WPTForm2;

procedure AddTwig(const Builder: ISkPathBuilder; Twig: TTwig; Dx, Dy: Double;
 Vertices, MidPoints: TList<TPointF>);
var J: Integer;
    D: TDot;
    P, Prev: TPointF;
begin
 if (Twig = nil) or (Twig.Coord = nil) or (Twig.Coord.Count = 0) then exit;
 Prev := TPointF.Zero;
 for J := 0 to Twig.Coord.Count - 1 do begin
  D := TDot(Twig.Coord[J]);
  P := TPointF.Create(D.XDot - Dx, D.YDot - Dy);
  if J = 0 then Builder.MoveTo(P) else begin
   Builder.LineTo(P);
   if MidPoints <> nil then MidPoints.Add(TPointF.Create((Prev.X + P.X) / 2, (Prev.Y + P.Y) / 2));
  end;
  if Vertices <> nil then Vertices.Add(P);
  Prev := P;
 end;
end;

function BlockLocalOutline(Block: TGeoBlock): ISkPath;
var Builder: ISkPathBuilder;
    Form: TForm2;
    Done: TDictionary<Pointer, Boolean>;
    I, K: Integer;
    Lot: TLot;
    Twig: TTwig;
    X0, Y0: Double;
begin
 Result := Block.LocalOutline;
 if Result <> nil then exit;
 Form := Block.TwgForm;
 if (Form = nil) or (Form.Twigs = nil) then exit;
// базовая точка блока, как в TGeoBlock.Draw32 / GetGabaritesDebug
 X0 := Block.X + Form.XXMin;
 Y0 := Block.Y + Form.YYMin;
 Builder := TSkPathBuilder.Create;
 Done := TDictionary<Pointer, Boolean>.Create;
 try
  for I := 0 to Form.Twigs.IndexCount - 1 do begin
   Lot := TLot(Form.Twigs.LAtIndex(I));
   if (Lot = nil) or (Lot.ClassHandle.Check = 0) then continue;
  // общие ветви соседних участков добавляем один раз
   for K := 0 to Lot.Coord.Count - 1 do begin
    Twig := Lot.GetTwig(Form.Twigs, K);
    if (Twig = nil) or Done.ContainsKey(Twig) then continue;
    Done.Add(Twig, True);
    AddTwig(Builder, Twig, X0, Y0, nil, nil);
   end;
  end;
 finally
  Done.Free;
 end;
 Result := Builder.Detach;
 Block.LocalOutline := Result;
end;

procedure ogsEnsureOutline(Obj: TTD; Twigs: TTwigsCollect);
var SkObj: TogsSkiaObject;
    Builder: ISkPathBuilder;
    Vertices, MidPoints: TList<TPointF>;
    Lot: TLot;
    PD: TPointDot;
    Local: ISkPath;
    M: TMatrix;
    KX, KY: Single;
    I: Integer;
begin
 if (Obj = nil) or not (Obj.DrawerObject is TogsSkiaObject) then exit;
 SkObj := TogsSkiaObject(Obj.DrawerObject);
 if SkObj.OutlineValid then exit;
 Vertices := TList<TPointF>.Create;
 MidPoints := TList<TPointF>.Create;
 try
  Builder := TSkPathBuilder.Create;
  if Obj is TLot then begin
   Lot := TLot(Obj);
   for I := 0 to Lot.Coord.Count - 1 do AddTwig(Builder, Lot.GetTwig(Twigs, I), 0, 0, Vertices, MidPoints);
  end else if Obj is TPointDot then begin
   PD := TPointDot(Obj);
   Vertices.Add(TPointF.Create(PD.XDot, PD.YDot));
  // блок: локальный контур, перенесенный матрицей экземпляра (масштаб, поворот, сдвиг)
   if (PD.userObj <> nil) and (PD.userObj.objType = TWG_Block) then begin
    Local := BlockLocalOutline(TGeoBlock(PD.userObj));
    if Local <> nil then begin
     KX := PD.XKoef;
     if KX = 0 then KX := 1;
     KY := PD.YKoef;
     if KY = 0 then KY := 1;
     M := TMatrix.CreateScaling(KX, KY) * TMatrix.CreateRotation(PD.Ugol) * TMatrix.CreateTranslation(PD.XDot, PD.YDot);
     Builder.AddPath(Local.Transform(M));
    end;
   end;
  end;
  SkObj.OutlinePath := Builder.Detach;
  SkObj.OutlineVertices := Vertices.ToArray;
  SkObj.OutlineMidPoints := MidPoints.ToArray;
  SkObj.OutlineValid := True;
 finally
  Vertices.Free;
  MidPoints.Free;
 end;
end;

procedure ogsDrawOutline(const Canvas: ISkCanvas; SkObj: TogsSkiaObject;
 const LineColor: TAlphaColor; const LineWidthPix: Single;
 const RectStrokeColor: TAlphaColor; const RectStrokeWidthPix: Single;
 const RectFillColor: TAlphaColor; const ViewScale: Single;
 const RadiusPix: Single);
var PaintLine, PaintStroke, PaintFill: ISkPaint;
    InvScale, R: Single;
    I: Integer;
    P: TPointF;
    RR: TRectF;
begin
 if (Canvas = nil) or (SkObj = nil) or not SkObj.OutlineValid then exit;
 if ViewScale <= 0 then InvScale := 1 else InvScale := 1 / ViewScale;
 R := RadiusPix * InvScale;
// толщины и размеры заданы в пикселах экрана и переводятся в мировые единицы
 PaintLine := TSkPaint.Create;
 PaintLine.AntiAlias := True;
 PaintLine.Style := TSkPaintStyle.Stroke;
 PaintLine.Color := LineColor;
 PaintLine.StrokeWidth := LineWidthPix * InvScale;
 PaintStroke := TSkPaint.Create;
 PaintStroke.AntiAlias := True;
 PaintStroke.Style := TSkPaintStyle.Stroke;
 PaintStroke.Color := RectStrokeColor;
 PaintStroke.StrokeWidth := RectStrokeWidthPix * InvScale;
 PaintFill := TSkPaint.Create;
 PaintFill.AntiAlias := True;
 PaintFill.Style := TSkPaintStyle.Fill;
 PaintFill.Color := RectFillColor;
//
 if SkObj.OutlinePath <> nil then Canvas.DrawPath(SkObj.OutlinePath, PaintLine);
 for I := 0 to High(SkObj.OutlineMidPoints) do begin
  Canvas.DrawCircle(SkObj.OutlineMidPoints[I], R, PaintFill);
  Canvas.DrawCircle(SkObj.OutlineMidPoints[I], R, PaintStroke);
 end;
 for I := 0 to High(SkObj.OutlineVertices) do begin
  P := SkObj.OutlineVertices[I];
  RR := TRectF.Create(P.X - R, P.Y - R, P.X + R, P.Y + R);
  Canvas.DrawRect(RR, PaintFill);
  Canvas.DrawRect(RR, PaintStroke);
 end;
end;

end.
