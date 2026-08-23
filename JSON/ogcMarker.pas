unit ogcMarker;

interface

uses
 System.Types, System.UITypes, System.Skia, System.Generics.Collections, System.Math;

type
 TogsMarkerType = (
  mtNone, // невидимый
  mtPolygon,
  mtLine,
  mtPoint,
  mtCenterLine,
  mtCenterLine2,
  mtCenterPoly,
  mtPerpend,
  mtLineStvor
 );

 TogsMarkerShape = (
  msNone,
  msCross,
  msDiagCross,
  msRect,
  msTriangle,
  msInvTriangle,
  ms2Triangle,
  msSmallCross, // по умолчанию msCross в 1.5 раза меньше
  msSmallDiagCross
 );

 TStickPt = class
 public
  X: Double;
  Y: Double;
  Z: Double;
  Color: TAlphaColor;
  LineColor: TAlphaColor;
  constructor Create(const AX, AY: Double; const AColor: TAlphaColor; const ALineColor: TAlphaColor; const AZ: Double = 0);
 end;

 TogsMarker = class
 private
 //
  FState: TogsMarkerType;
  FSize: Single;
  FColor: TAlphaColor;
  FLineColor: TAlphaColor;
  FStickPts: TObjectList<TStickPt>;
 public
  constructor Create;
  destructor Destroy; override;
 //
  class function StateToShape(const AState: TogsMarkerType): TogsMarkerShape; static;
 //
  procedure ClearStickPts;
  function StickPtCount: Integer;
  function StickPt(Index: Integer): TStickPt;
  procedure AddStickPt(Pt: TStickPt);
 //
  procedure Draw(const Canvas: ISkCanvas; const P: TPointF);
  procedure DrawStickPts(const Canvas: ISkCanvas; const FromP: TPointF);
 //
  property State: TogsMarkerType read FState write FState;
  property Size: Single read FSize write FSize;
  property Color: TAlphaColor read FColor write FColor;
  property LineColor: TAlphaColor read FLineColor write FLineColor;
 end;

implementation uses Writer;

{ TStickPt }

constructor TStickPt.Create(const AX, AY: Double; const AColor: TAlphaColor; const ALineColor: TAlphaColor; const AZ: Double);
begin
 inherited Create;
 X := AX;
 Y := AY;
 Z := AZ;
 Color := AColor;
 LineColor := ALineColor;
end;

{ TogsMarker }

constructor TogsMarker.Create;
begin
 inherited Create;
 FState := mtPolygon;
 FSize := 10;
 FColor := TAlphaColors.Lime;
 FLineColor := TAlphaColors.Lime;
 FStickPts := TObjectList<TStickPt>.Create(True);
end;

destructor TogsMarker.Destroy;
begin
 FStickPts.Free;
 inherited;
end;

class function TogsMarker.StateToShape(const AState: TogsMarkerType): TogsMarkerShape;
begin
 case AState of
  mtPolygon: Result := msCross;
  mtLine: Result := msDiagCross;
  mtPoint: Result := msRect;
  mtCenterLine: Result := msTriangle;
  mtCenterLine2: Result := msInvTriangle;
  mtCenterPoly: Result := ms2Triangle;
  mtPerpend: Result := msSmallCross;
  mtLineStvor: Result := msSmallDiagCross;
 else
  Result := msCross;
 end;
end;

procedure TogsMarker.ClearStickPts;
begin
 FStickPts.Clear;
end;

function TogsMarker.StickPtCount: Integer;
begin
 Result := FStickPts.Count;
end;

function TogsMarker.StickPt(Index: Integer): TStickPt;
begin
 Result := FStickPts[Index];
end;

procedure TogsMarker.AddStickPt(Pt: TStickPt);
begin
 if Pt = nil then Exit;
 FStickPts.Add(Pt);
end;

procedure TogsMarker.DrawStickPts(const Canvas: ISkCanvas; const FromP: TPointF);
var I: Integer;
    Pt: TStickPt;
    Paint: ISkPaint;
    PTo: TPointF;
    R: TRectF;
    S: Single;
begin
 if (Canvas = nil) or (FStickPts = nil) or (FStickPts.Count = 0) then Exit;
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.StrokeWidth := 1;
 S := Max(2, FSize * 0.35);
 for I := 0 to FStickPts.Count - 1 do begin
  Pt := FStickPts[I];
  if Pt = nil then continue;
  PTo := TPointF.Create(Single(Pt.X), Single(Pt.Y));
  Paint.Color := Pt.LineColor;
  Canvas.DrawLine(FromP, PTo, Paint);
  Paint.Color := Pt.Color;
  R := TRectF.Create(PTo.X - S, PTo.Y - S, PTo.X + S, PTo.Y + S);
  Canvas.DrawRect(R, Paint);
 end;
end;

procedure TogsMarker.Draw(const Canvas: ISkCanvas; const P: TPointF);
var Paint: ISkPaint;
    Shape: TogsMarkerShape;
    S: Single;
    R: TRectF;
    A, B, C: TPointF;
begin
 if Canvas = nil then Exit;
 WriteIn(['Markerpos=', P.X, P.Y]);
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.Color := FColor;
 Paint.StrokeWidth := 1;
//
 Shape := StateToShape(FState);
 S := Max(1, FSize);
//
 case Shape of
  msCross:
   begin
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y), TPointF.Create(P.X + S, P.Y), Paint);
    Canvas.DrawLine(TPointF.Create(P.X, P.Y - S), TPointF.Create(P.X, P.Y + S), Paint);
   end;
  msDiagCross:
   begin
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y - S), TPointF.Create(P.X + S, P.Y + S), Paint);
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y + S), TPointF.Create(P.X + S, P.Y - S), Paint);
   end;
  msRect:
   begin
    R := TRectF.Create(P.X - S, P.Y - S, P.X + S, P.Y + S);
    Canvas.DrawRect(R, Paint);
   end;
  msTriangle:
   begin
    A := TPointF.Create(P.X, P.Y - S);
    B := TPointF.Create(P.X - S, P.Y + S);
    C := TPointF.Create(P.X + S, P.Y + S);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  msInvTriangle:
   begin
    A := TPointF.Create(P.X, P.Y + S);
    B := TPointF.Create(P.X - S, P.Y - S);
    C := TPointF.Create(P.X + S, P.Y - S);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  ms2Triangle:
   begin
    A := TPointF.Create(P.X, P.Y - S);
    B := TPointF.Create(P.X - S, P.Y);
    C := TPointF.Create(P.X + S, P.Y);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
  //
    A := TPointF.Create(P.X, P.Y + S);
    B := TPointF.Create(P.X - S, P.Y);
    C := TPointF.Create(P.X + S, P.Y);
    Canvas.DrawLine(A, B, Paint);
    Canvas.DrawLine(B, C, Paint);
    Canvas.DrawLine(C, A, Paint);
   end;
  msNone:
   begin
    Canvas.DrawCircle(P.X, P.Y, S, Paint);
    Canvas.DrawLine(TPointF.Create(P.X - S, P.Y), TPointF.Create(P.X + S, P.Y), Paint);
    Canvas.DrawLine(TPointF.Create(P.X, P.Y - S), TPointF.Create(P.X, P.Y + S), Paint);
   end;
 end;
//
 DrawStickPts(Canvas, P);
end;

end.
