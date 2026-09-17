unit objMouseView;

interface uses objMouse, WPTForm2, System.UITypes, Classes, System.Types,
               System.Skia, ogcBasic;

const
  mvPan = 1;
  mvFragmrny = 2;
  winKZoom = 3;

type
 TMouseView = class(TKeyMouseHook)
 private
  fPanActive: boolean;
  fPanXInt, fPanYInt: Integer;
  fFragActive: boolean;
  fFragX, fFragY: Double;
  fFragButton: TMouseButton;
  function GetViewRect(out R: TogsRect): boolean;
  procedure DoPan(X, Y: Double);
  procedure DoFragZoom(X, Y: Double; Button: TMouseButton);
 public
  procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); override;
  procedure KeyUp(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); override;
  procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
  procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
 end;

implementation

procedure TMouseView.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
end;

procedure TMouseView.KeyUp(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
end;

function TMouseView.GetViewRect(out R: TogsRect): boolean;
begin
 Result := False;
 R := nil;
 if Selector = nil then exit;
 R := Selector.ActiveRect;
 Result := (R <> nil) and R.isRect;
end;

procedure TMouseView.DoPan(X, Y: Double);
var CurXInt, CurYInt: Integer;
    DxPix, DyPix: Integer;
    DxGeo, DyGeo: Double;
begin
 if Selector = nil then exit;
 CurXInt := XPix(X);
 CurYInt := YPix(Y);
 DxPix := CurXInt - fPanXInt;
 DyPix := CurYInt - fPanYInt;
 fPanXInt := CurXInt;
 fPanYInt := CurYInt;
 if (DxPix = 0) and (DyPix = 0) then exit;
 DxGeo := geoDist(DxPix);
 DyGeo := geoDist(DyPix);
 Selector.Move(-DxGeo, -DyGeo);
 Selector.UpdateImage;
end;

procedure TMouseView.DoFragZoom(X, Y: Double; Button: TMouseButton);
var ViewR, NewR: TogsRect;
    ZoomK, W, H: Double;
begin
 if not GetViewRect(ViewR) then exit;
 ZoomK := winKZoom;
 if ZoomK <= 0 then exit;
 if Button = TMouseButton.mbRight then ZoomK := 1 / ZoomK;
 if ZoomK <= 0 then exit;
 W := (ViewR.XMax - ViewR.XMin) / ZoomK;
 H := (ViewR.YMax - ViewR.YMin) / ZoomK;
 NewR := TogsRect.Create;
 try
  NewR.XMin := X - W * 0.5;
  NewR.XMax := X + W * 0.5;
  NewR.YMin := Y - H * 0.5;
  NewR.YMax := Y + H * 0.5;
  NewR.Iter := 1;
  Selector.ActiveRect := NewR;
 finally
  NewR.Free;
 end;
 Selector.UpdateImage;
end;

procedure TMouseView.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := False;
 if Button = TMouseButton.mbMiddle then exit;
 Hook := True;
 if LOperation = mvPan then begin
  fPanActive := True;
  fPanXInt := XPix(X);
  fPanYInt := YPix(Y);
  exit;
 end;
 if LOperation = mvFragmrny then begin
  fFragActive := True;
  fFragButton := Button;
  fFragX := X;
  fFragY := Y;
  if Selector <> nil then Selector.UpdateOverlay;
  exit;
 end;
end;

procedure TMouseView.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
end;

procedure TMouseView.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 inherited;
 Hook := True;
 if LOperation = mvPan then begin
  fPanActive := False;
  exit;
 end;
 if LOperation = mvFragmrny then begin
  if fFragActive and ((Button = TMouseButton.mbLeft) or (Button = TMouseButton.mbRight)) then DoFragZoom(X, Y, Button);
  fFragActive := False;
  if Selector <> nil then Selector.UpdateOverlay;
  exit;
 end;
end;

procedure TMouseView.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if LOperation = mvPan then begin
  MouseX := X;
  MouseY := Y;
  if fPanActive and (LMouseDown or RMouseDown) then DoPan(X, Y);
  exit;
 end;
 if LOperation = mvFragmrny then begin
  inherited;
  fFragX := X;
  fFragY := Y;
  if Selector <> nil then Selector.UpdateOverlay;
  Hook := True;
  exit;
 end;
 inherited;
end;

procedure TMouseView.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
var ViewR: TogsRect;
    Paint: ISkPaint;
    Scale, W, H, StrokeW: Double;
    R: TRectF;
begin
 if Canvas = nil then exit;
 if LOperation <> mvFragmrny then exit;
 if not GetViewRect(ViewR) then exit;
 if winKZoom <= 0 then exit;
 Scale := Selector.GetScale;
 if Scale = 0 then exit;
 W := (ViewR.XMax - ViewR.XMin) / winKZoom;
 H := (ViewR.YMax - ViewR.YMin) / winKZoom;
 StrokeW := 1 / Scale;
 R := RectF(Single(fFragX - W * 0.5), Single(fFragY - H * 0.5), Single(fFragX + W * 0.5), Single(fFragY + H * 0.5));
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.Color := $A0FF0000;
 Paint.StrokeWidth := Single(StrokeW);
 Canvas.DrawRect(R, Paint);
end;

end.
