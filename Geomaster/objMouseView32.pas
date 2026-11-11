unit objMouseView32;

// Pan and fragment zoom mouse handler for the objMouse32 architecture.
// btnPan selects mvPan; btnFrag selects mvFragmrny. The +/- view buttons
// keep using the form's centered Skia zoom handler.

interface

uses objMouse32, WPTForm2, System.UITypes, System.Classes, System.Types,
     System.Skia, ogcBasic;

const
  mvPan = 1;
  mvFragmrny = 2;
  winKZoom = 3;

type
 TMouseView32 = class(TKeyMouseHook)
 private
  fFragActive: Boolean;
  fFragX, fFragY: Double;
  function GetViewRect(out R: TogsRect): Boolean;
  procedure DoFragZoom(X, Y: Double; Button: TMouseButton);
 public
  procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: Boolean); override;
  procedure KeyUp(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: Boolean); override;
  procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: Boolean); override;
  procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: Boolean); override;
  procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: Boolean); override;
  procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: Boolean); override;
  procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
 end;

implementation

procedure TMouseView32.KeyDown(Form: TForm2; var Key: Word;
  Shift: TShiftState; var Hook: Boolean);
begin
 inherited;
end;

procedure TMouseView32.KeyUp(Form: TForm2; var Key: Word;
  Shift: TShiftState; var Hook: Boolean);
begin
 inherited;
end;

function TMouseView32.GetViewRect(out R: TogsRect): Boolean;
begin
 Result := False;
 R := nil;
 if Selector = nil then exit;
 R := Selector.ActiveRect;
 Result := (R <> nil) and R.isRect;
end;

procedure TMouseView32.DoFragZoom(X, Y: Double; Button: TMouseButton);
var ViewR, NewR: TogsRect;
    ZoomK, W, H: Double;
begin
 if not GetViewRect(ViewR) then exit;
 ZoomK := winKZoom;
 if Button = TMouseButton.mbRight then ZoomK := 1 / ZoomK;
 if ZoomK <= 0 then exit;
 W := ViewR.Width / ZoomK;
 H := ViewR.Height / ZoomK;
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

procedure TMouseView32.MouseDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: Boolean);
begin
 inherited;
 if Button = TMouseButton.mbMiddle then begin
  Hook := False;
  exit;
 end;
 if LOperation = mvPan then begin
  // перемещение выполняет форма: во время жеста она сдвигает снимок сцены,
  // полный кадр строится только после отпускания кнопки
  Hook := False;
  exit;
 end;
 Hook := True;
 if LOperation = mvFragmrny then begin
  fFragActive := True;
  fFragX := X;
  fFragY := Y;
  if Selector <> nil then Selector.UpdateOverlay;
 end;
end;

procedure TMouseView32.MouseRightDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: Boolean);
begin
 inherited;
 Hook := True;
end;

procedure TMouseView32.MouseUp(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: Boolean);
begin
 inherited;
 Hook := True;
 if LOperation = mvPan then begin
  Hook := False;
  exit;
 end;
 if LOperation = mvFragmrny then begin
  if fFragActive and (Button in [TMouseButton.mbLeft, TMouseButton.mbRight]) then
   DoFragZoom(X, Y, Button);
  fFragActive := False;
  if Selector <> nil then Selector.UpdateOverlay;
 end;
end;

procedure TMouseView32.MouseMove(Form: TForm2; Shift: TShiftState;
  X, Y: Double; var Hook: Boolean);
begin
 inherited;
 if LOperation = mvFragmrny then begin
  fFragX := X;
  fFragY := Y;
  if Selector <> nil then Selector.UpdateOverlay;
  Hook := True;
 end;
end;

procedure TMouseView32.DrawTemp(const Canvas: ISkCanvas;
  PaintOnImage: Boolean);
var ViewR: TogsRect;
    Paint: ISkPaint;
    Scale, W, H, StrokeW: Double;
    R: TRectF;
begin
 if (Canvas = nil) or (LOperation <> mvFragmrny) then exit;
 if not GetViewRect(ViewR) then exit;
 if winKZoom <= 0 then exit;
 Scale := Selector.GetScale;
 if Scale <= 0 then exit;
 W := ViewR.Width / winKZoom;
 H := ViewR.Height / winKZoom;
 StrokeW := 1 / Scale;
 R := RectF(Single(fFragX - W * 0.5), Single(fFragY - H * 0.5),
   Single(fFragX + W * 0.5), Single(fFragY + H * 0.5));
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.Color := $A0FF0000;
 Paint.StrokeWidth := Single(StrokeW);
 Canvas.DrawRect(R, Paint);
end;

end.
