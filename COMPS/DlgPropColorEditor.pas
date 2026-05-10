unit DlgPropColorEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math,
  System.IOUtils,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.TabControl, FMX.Objects,
  DlgRootPropEditor, FMX.Controls.Presentation;

type
  TPropColorEditorForm = class(TRootPropEditorForm)
    TabControl1: TTabControl;
    Tab256: TTabItem;
    Tab16: TTabItem;
    TabGrad: TTabItem;
    Paint256: TPaintBox;
    Paint16: TPaintBox;
    PaintGrad: TPaintBox;
    RightLay: TLayout;
    PreviewRect: TRectangle;
    TrackR: TTrackBar;
    TrackG: TTrackBar;
    TrackB: TTrackBar;
    TrackA: TTrackBar;
    LabR: TLabel;
    LabG: TLabel;
    LabB: TLabel;
    LabA: TLabel;
    Label1: TLabel;
  private
    FUpdating: Boolean;
    FAcad256: array[0..255] of TAlphaColor;
    FStd16: array[0..15] of TAlphaColor;
    FGrad6x16: array[0..5,0..15] of TAlphaColor;
    FSelectedColor: TAlphaColor;

    procedure EnsurePalettes;
    procedure LoadAcad256FromFile(const FileName: string);
    class function MakeColor(const R, G, B, A: Byte): TAlphaColor; static;
    class function ClampByte(const V: Single): Byte; static;
    procedure SetSelectedColor(const C: TAlphaColor; const SyncSliders: Boolean);
    procedure SyncSlidersFromColor;
    procedure UpdatePreview;
    procedure UpdateLabels;

    procedure Paint256Paint(Sender: TObject; Canvas: TCanvas);
    procedure Paint16Paint(Sender: TObject; Canvas: TCanvas);
    procedure PaintGradPaint(Sender: TObject; Canvas: TCanvas);

    procedure Paint256MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Paint16MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintGradMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);

    procedure TrackChange(Sender: TObject);
  public
    function Execute(Row: TPropRow): String;
  end;

var PropColorEditorForm: TPropColorEditorForm;
    AcadColors : array [1..255] of TColorRef;

implementation uses newProcs;

{$R *.fmx}

{ TRootPropEditorForm1 }

class function TPropColorEditorForm.ClampByte(const V: Single): Byte;
var I: Integer;
begin
 I := Round(V);
 if I < 0 then I := 0;
 if I > 255 then I := 255;
 Result := Byte(I);
end;

class function TPropColorEditorForm.MakeColor(const R, G, B, A: Byte): TAlphaColor;
begin
 Result := (TAlphaColor(A) shl 24) or (TAlphaColor(R) shl 16) or (TAlphaColor(G) shl 8) or TAlphaColor(B);
end;

procedure TPropColorEditorForm.EnsurePalettes;
var I, J: Integer;
    Base: array[0..5] of TAlphaColor;
    R, G, B: Byte;
    T: Single;
begin
 LoadAcad256FromFile('');
 for I := 0 to 15 do
  FStd16[I] := FAcad256[I + 1];

 Base[0] := MakeColor(255, 0, 0, 255);
 Base[1] := MakeColor(255, 255, 0, 255);
 Base[2] := MakeColor(0, 255, 0, 255);
 Base[3] := MakeColor(0, 255, 255, 255);
 Base[4] := MakeColor(0, 0, 255, 255);
 Base[5] := MakeColor(255, 0, 255, 255);

 for I := 0 to 5 do
  for J := 0 to 15 do
  begin
   T := J / 15;
   R := ClampByte(TAlphaColorRec(Base[I]).R * T);
   G := ClampByte(TAlphaColorRec(Base[I]).G * T);
   B := ClampByte(TAlphaColorRec(Base[I]).B * T);
   FGrad6x16[I, J] := MakeColor(R, G, B, 255);
  end;
end;

procedure TPropColorEditorForm.LoadAcad256FromFile(const FileName: string);
var I: Integer;
begin
 for I := 0 to 255 do FAcad256[I] := AcadColors[I + 1];
end;

procedure TPropColorEditorForm.SetSelectedColor(const C: TAlphaColor; const SyncSliders: Boolean);
begin
 FSelectedColor := C;
 if SyncSliders then
  SyncSlidersFromColor;
 UpdatePreview;
 if Paint256 <> nil then Paint256.Repaint;
 if Paint16 <> nil then Paint16.Repaint;
 if PaintGrad <> nil then PaintGrad.Repaint;
end;

procedure TPropColorEditorForm.SyncSlidersFromColor;
begin
 if (TrackR = nil) or (TrackG = nil) or (TrackB = nil) or (TrackA = nil) then Exit;
 FUpdating := True;
 try
  TrackA.Value := TAlphaColorRec(FSelectedColor).A;
  TrackR.Value := TAlphaColorRec(FSelectedColor).R;
  TrackG.Value := TAlphaColorRec(FSelectedColor).G;
  TrackB.Value := TAlphaColorRec(FSelectedColor).B;
 finally
  FUpdating := False;
 end;
 UpdateLabels;
end;

procedure TPropColorEditorForm.UpdateLabels;
begin
 if LabA <> nil then LabA.Text := 'A: ' + IntToStr(TAlphaColorRec(FSelectedColor).A);
 if LabR <> nil then LabR.Text := 'R: ' + IntToStr(TAlphaColorRec(FSelectedColor).R);
 if LabG <> nil then LabG.Text := 'G: ' + IntToStr(TAlphaColorRec(FSelectedColor).G);
 if LabB <> nil then LabB.Text := 'B: ' + IntToStr(TAlphaColorRec(FSelectedColor).B);
end;

procedure TPropColorEditorForm.UpdatePreview;
begin
 if PreviewRect <> nil then
  PreviewRect.Fill.Color := FSelectedColor;
 UpdateLabels;
end;

procedure TPropColorEditorForm.Paint256Paint(Sender: TObject; Canvas: TCanvas);
var I, C, R0: Integer; Cell, OffX, OffY: Single; R: TRectF;
begin
 Cell := Min(Paint256.Width / 16, Paint256.Height / 16);
 OffX := (Paint256.Width - Cell * 16) / 2;
 OffY := (Paint256.Height - Cell * 16) / 2;
 for I := 0 to 255 do
 begin
  C := I mod 16;
  R0 := I div 16;
  R := RectF(OffX + C * Cell, OffY + R0 * Cell, OffX + (C + 1) * Cell, OffY + (R0 + 1) * Cell);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FAcad256[I];
  Canvas.FillRect(R, 0, 0, [], 1);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := TAlphaColorRec.Black;
  Canvas.DrawRect(R, 0, 0, [], 1);
  if FAcad256[I] = FSelectedColor then
  begin
   Canvas.Stroke.Thickness := 2;
   Canvas.Stroke.Color := TAlphaColorRec.White;
   Canvas.DrawRect(R, 0, 0, [], 1);
   Canvas.Stroke.Thickness := 1;
  end;
 end;
end;

procedure TPropColorEditorForm.Paint16Paint(Sender: TObject; Canvas: TCanvas);
var I, C, R0: Integer; Cell, OffX, OffY: Single; R: TRectF;
begin
 Cell := Min(Paint16.Width / 8, Paint16.Height / 2);
 OffX := (Paint16.Width - Cell * 8) / 2;
 OffY := (Paint16.Height - Cell * 2) / 2;
 for I := 0 to 15 do
 begin
  C := I mod 8;
  R0 := I div 8;
  R := RectF(OffX + C * Cell, OffY + R0 * Cell, OffX + (C + 1) * Cell, OffY + (R0 + 1) * Cell);
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := FStd16[I];
  Canvas.FillRect(R, 0, 0, [], 1);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := TAlphaColorRec.Black;
  Canvas.DrawRect(R, 0, 0, [], 1);
  if FStd16[I] = FSelectedColor then
  begin
   Canvas.Stroke.Thickness := 2;
   Canvas.Stroke.Color := TAlphaColorRec.White;
   Canvas.DrawRect(R, 0, 0, [], 1);
   Canvas.Stroke.Thickness := 1;
  end;
 end;
end;

procedure TPropColorEditorForm.PaintGradPaint(Sender: TObject; Canvas: TCanvas);
var I, J: Integer; Cell, OffX, OffY: Single; R: TRectF;
begin
 Cell := Min(PaintGrad.Width / 16, PaintGrad.Height / 6);
 OffX := (PaintGrad.Width - Cell * 16) / 2;
 OffY := (PaintGrad.Height - Cell * 6) / 2;
 for I := 0 to 5 do
  for J := 0 to 15 do
  begin
   R := RectF(OffX + J * Cell, OffY + I * Cell, OffX + (J + 1) * Cell, OffY + (I + 1) * Cell);
   Canvas.Fill.Kind := TBrushKind.Solid;
   Canvas.Fill.Color := FGrad6x16[I, J];
   Canvas.FillRect(R, 0, 0, [], 1);
   Canvas.Stroke.Kind := TBrushKind.Solid;
   Canvas.Stroke.Color := TAlphaColorRec.Black;
   Canvas.DrawRect(R, 0, 0, [], 1);
   if FGrad6x16[I, J] = FSelectedColor then
   begin
    Canvas.Stroke.Thickness := 2;
    Canvas.Stroke.Color := TAlphaColorRec.White;
    Canvas.DrawRect(R, 0, 0, [], 1);
    Canvas.Stroke.Thickness := 1;
   end;
  end;
end;

procedure TPropColorEditorForm.Paint256MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var C, R0, Idx: Integer; Cell, OffX, OffY: Single;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 Cell := Min(Paint256.Width / 16, Paint256.Height / 16);
 OffX := (Paint256.Width - Cell * 16) / 2;
 OffY := (Paint256.Height - Cell * 16) / 2;
 X := X - OffX;
 Y := Y - OffY;
 if (X < 0) or (Y < 0) then Exit;
 C := Trunc(X / Cell);
 R0 := Trunc(Y / Cell);
 if (C < 0) or (C > 15) or (R0 < 0) or (R0 > 15) then Exit;
 Idx := R0 * 16 + C;
 if (Idx < 0) or (Idx > 255) then Exit;
 SetSelectedColor(FAcad256[Idx], True);
end;

procedure TPropColorEditorForm.Paint16MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var C, R0, Idx: Integer; Cell, OffX, OffY: Single;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 Cell := Min(Paint16.Width / 8, Paint16.Height / 2);
 OffX := (Paint16.Width - Cell * 8) / 2;
 OffY := (Paint16.Height - Cell * 2) / 2;
 X := X - OffX;
 Y := Y - OffY;
 if (X < 0) or (Y < 0) then Exit;
 C := Trunc(X / Cell);
 R0 := Trunc(Y / Cell);
 if (C < 0) or (C > 7) or (R0 < 0) or (R0 > 1) then Exit;
 Idx := R0 * 8 + C;
 if (Idx < 0) or (Idx > 15) then Exit;
 SetSelectedColor(FStd16[Idx], True);
end;

procedure TPropColorEditorForm.PaintGradMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var C, R0: Integer; Cell, OffX, OffY: Single;
begin
 if Button <> TMouseButton.mbLeft then Exit;
 Cell := Min(PaintGrad.Width / 16, PaintGrad.Height / 6);
 OffX := (PaintGrad.Width - Cell * 16) / 2;
 OffY := (PaintGrad.Height - Cell * 6) / 2;
 X := X - OffX;
 Y := Y - OffY;
 if (X < 0) or (Y < 0) then Exit;
 C := Trunc(X / Cell);
 R0 := Trunc(Y / Cell);
 if (C < 0) or (C > 15) or (R0 < 0) or (R0 > 5) then Exit;
 SetSelectedColor(FGrad6x16[R0, C], True);
end;

procedure TPropColorEditorForm.TrackChange(Sender: TObject);
var A, R, G, B: Byte;
begin
 if FUpdating then Exit;
 A := ClampByte(TrackA.Value);
 R := ClampByte(TrackR.Value);
 G := ClampByte(TrackG.Value);
 B := ClampByte(TrackB.Value);
 SetSelectedColor(MakeColor(R, G, B, A), False);
end;

function TPropColorEditorForm.Execute(Row: TPropRow): String;
var V: Integer; Res: TModalResult;
begin
 LoadPosition;
 TabControl1.ActiveTab := TabControl1.Tabs[GReadInteger(Name + '_Tab', 0)];
 EnsurePalettes;
 if (Row <> nil) and (Row.Value <> '') and (Row.Value <> byLayer) then
 begin
  if TryStrToInt(Row.Value, V) then
   SetSelectedColor(TAlphaColor(V), True)
  else
   SetSelectedColor(MakeColor(0, 0, 0, 255), True);
 end
 else
  SetSelectedColor(MakeColor(0, 0, 0, 255), True);

 if (Paint256 <> nil) then
 begin
  Paint256.OnPaint := Paint256Paint;
  Paint256.OnMouseDown := Paint256MouseDown;
 end;
 if (Paint16 <> nil) then
 begin
  Paint16.OnPaint := Paint16Paint;
  Paint16.OnMouseDown := Paint16MouseDown;
 end;
 if (PaintGrad <> nil) then
 begin
  PaintGrad.OnPaint := PaintGradPaint;
  PaintGrad.OnMouseDown := PaintGradMouseDown;
 end;

 if TrackR <> nil then TrackR.OnChange := TrackChange;
 if TrackG <> nil then TrackG.OnChange := TrackChange;
 if TrackB <> nil then TrackB.OnChange := TrackChange;
 if TrackA <> nil then TrackA.OnChange := TrackChange;

 fResult := '';
 Res := ShowModal;
 if (fResult = byLayer) then
 begin
  Result := byLayer;
  Exit;
 end;
 if Res = mrCancel then
 begin
  fResult := '';
  Result := '';
 end
 else
 begin
  fResult := IntToStr(Integer(FSelectedColor));
  Result := fResult;
 end;
 SavePosition;
 GWriteInteger(Name + '_Tab', TabControl1.ActiveTab.Index);
end;

initialization
// Stsndart
 AcadColors[1]:=RGBToCol(255,0,0);
 AcadColors[2]:=RGBToCol(255,255,0);
 AcadColors[3]:=RGBToCol(0,255,0);
 AcadColors[4]:=RGBToCol(0,255,255);
 AcadColors[5]:=RGBToCol(0,0,255);
 AcadColors[6]:=RGBToCol(255,0,255);
 AcadColors[7]:=RGBToCol(255,255,255);
 AcadColors[8]:=RGBToCol(128,128,128);
 AcadColors[9]:=RGBToCol(192,192,192);
// AcadColors
 AcadColors[18]:=RGBToCol(38,0,0);
 AcadColors[28]:=RGBToCol(38,9,0);
 AcadColors[38]:=RGBToCol(38,19,0);
 AcadColors[48]:=RGBToCol(38,28,0);
 AcadColors[58]:=RGBToCol(38,38,0);
 AcadColors[68]:=RGBToCol(28,38,0);
 AcadColors[78]:=RGBToCol(19,38,0);
 AcadColors[88]:=RGBToCol(9,38,0);
 AcadColors[98]:=RGBToCol(0,38,0);
 AcadColors[108]:=RGBToCol(0,38,9);
 AcadColors[118]:=RGBToCol(0,38,19);
 AcadColors[128]:=RGBToCol(0,38,28);
 AcadColors[138]:=RGBToCol(0,38,38);
 AcadColors[148]:=RGBToCol(0,28,38);
 AcadColors[158]:=RGBToCol(0,19,38);
 AcadColors[168]:=RGBToCol(0,9,38);
 AcadColors[178]:=RGBToCol(0,0,38);
 AcadColors[188]:=RGBToCol(9,0,38);
 AcadColors[198]:=RGBToCol(19,0,38);
 AcadColors[208]:=RGBToCol(28,0,38);
 AcadColors[218]:=RGBToCol(38,0,38);
 AcadColors[228]:=RGBToCol(38,0,38);
 AcadColors[238]:=RGBToCol(38,0,19);
 AcadColors[248]:=RGBToCol(38,0,9);
 AcadColors[16]:=RGBToCol(76,0,0);
 AcadColors[26]:=RGBToCol(76,19,0);
 AcadColors[36]:=RGBToCol(76,38,0);
 AcadColors[46]:=RGBToCol(76,57,0);
 AcadColors[56]:=RGBToCol(76,76,0);
 AcadColors[66]:=RGBToCol(57,76,0);
 AcadColors[76]:=RGBToCol(38,76,0);
 AcadColors[86]:=RGBToCol(19,76,0);
 AcadColors[96]:=RGBToCol(0,76,0);
 AcadColors[106]:=RGBToCol(0,76,19);
 AcadColors[116]:=RGBToCol(0,76,38);
 AcadColors[126]:=RGBToCol(0,76,57);
 AcadColors[136]:=RGBToCol(0,76,76);
 AcadColors[146]:=RGBToCol(0,57,76);
 AcadColors[156]:=RGBToCol(0,38,76);
 AcadColors[166]:=RGBToCol(0,19,76);
 AcadColors[176]:=RGBToCol(0,0,76);
 AcadColors[186]:=RGBToCol(19,0,76);
 AcadColors[196]:=RGBToCol(38,0,76);
 AcadColors[206]:=RGBToCol(57,0,76);
 AcadColors[216]:=RGBToCol(76,0,76);
 AcadColors[226]:=RGBToCol(76,0,76);
 AcadColors[236]:=RGBToCol(76,0,38);
 AcadColors[246]:=RGBToCol(76,0,19);
 AcadColors[14]:=RGBToCol(127,0,0);
 AcadColors[24]:=RGBToCol(127,31,0);
 AcadColors[34]:=RGBToCol(127,63,0);
 AcadColors[44]:=RGBToCol(127,95,0);
 AcadColors[54]:=RGBToCol(127,127,0);
 AcadColors[64]:=RGBToCol(95,127,0);
 AcadColors[74]:=RGBToCol(63,127,0);
 AcadColors[84]:=RGBToCol(31,127,0);
 AcadColors[94]:=RGBToCol(0,127,0);
 AcadColors[104]:=RGBToCol(0,127,31);
 AcadColors[114]:=RGBToCol(0,127,63);
 AcadColors[124]:=RGBToCol(0,127,95);
 AcadColors[134]:=RGBToCol(0,127,127);
 AcadColors[144]:=RGBToCol(0,95,127);
 AcadColors[154]:=RGBToCol(0,63,127);
 AcadColors[164]:=RGBToCol(0,31,127);
 AcadColors[174]:=RGBToCol(0,0,127);
 AcadColors[184]:=RGBToCol(31,0,127);
 AcadColors[194]:=RGBToCol(63,0,127);
 AcadColors[204]:=RGBToCol(95,0,127);
 AcadColors[214]:=RGBToCol(127,0,127);
 AcadColors[224]:=RGBToCol(127,0,95);
 AcadColors[234]:=RGBToCol(127,0,63);
 AcadColors[244]:=RGBToCol(127,0,31);
 AcadColors[12]:=RGBToCol(165,0,0);
 AcadColors[22]:=RGBToCol(165,41,0);
 AcadColors[32]:=RGBToCol(165,82,0);
 AcadColors[42]:=RGBToCol(165,124,0);
 AcadColors[52]:=RGBToCol(165,165,0);
 AcadColors[62]:=RGBToCol(124,165,0);
 AcadColors[72]:=RGBToCol(82,165,0);
 AcadColors[82]:=RGBToCol(41,165,0);
 AcadColors[92]:=RGBToCol(0,165,0);
 AcadColors[102]:=RGBToCol(0,165,41);
 AcadColors[112]:=RGBToCol(0,165,82);
 AcadColors[122]:=RGBToCol(0,165,124);
 AcadColors[132]:=RGBToCol(0,165,165);
 AcadColors[142]:=RGBToCol(0,124,165);
 AcadColors[152]:=RGBToCol(0,82,165);
 AcadColors[162]:=RGBToCol(0,41,165);
 AcadColors[172]:=RGBToCol(0,0,165);
 AcadColors[182]:=RGBToCol(41,0,165);
 AcadColors[192]:=RGBToCol(82,0,165);
 AcadColors[202]:=RGBToCol(124,0,165);
 AcadColors[212]:=RGBToCol(165,0,165);
 AcadColors[222]:=RGBToCol(165,0,124);
 AcadColors[232]:=RGBToCol(165,0,82);
 AcadColors[242]:=RGBToCol(165,0,41);
 AcadColors[10]:=RGBToCol(255,0,0);
 AcadColors[20]:=RGBToCol(255,63,0);
 AcadColors[30]:=RGBToCol(255,127,0);
 AcadColors[40]:=RGBToCol(255,191,0);
 AcadColors[50]:=RGBToCol(255,255,0);
 AcadColors[60]:=RGBToCol(191,255,0);
 AcadColors[70]:=RGBToCol(127,255,0);
 AcadColors[80]:=RGBToCol(63,255,0);
 AcadColors[90]:=RGBToCol(0,255,0);
 AcadColors[100]:=RGBToCol(0,255,63);
 AcadColors[110]:=RGBToCol(0,255,127);
 AcadColors[120]:=RGBToCol(0,255,191);
 AcadColors[130]:=RGBToCol(0,255,255);
 AcadColors[140]:=RGBToCol(0,191,255);
 AcadColors[150]:=RGBToCol(0,127,255);
 AcadColors[160]:=RGBToCol(0,63,255);
 AcadColors[170]:=RGBToCol(0,0,255);
 AcadColors[180]:=RGBToCol(63,0,255);
 AcadColors[190]:=RGBToCol(127,0,255);
 AcadColors[200]:=RGBToCol(191,0,255);
 AcadColors[210]:=RGBToCol(255,0,255);
 AcadColors[220]:=RGBToCol(255,0,191);
 AcadColors[230]:=RGBToCol(255,0,127);
 AcadColors[240]:=RGBToCol(255,0,63);
 AcadColors[11]:=RGBToCol(255,127,127);
 AcadColors[21]:=RGBToCol(255,159,127);
 AcadColors[31]:=RGBToCol(255,191,127);
 AcadColors[41]:=RGBToCol(255,223,127);
 AcadColors[51]:=RGBToCol(255,255,127);
 AcadColors[61]:=RGBToCol(223,255,127);
 AcadColors[71]:=RGBToCol(191,255,127);
 AcadColors[81]:=RGBToCol(159,255,127);
 AcadColors[91]:=RGBToCol(127,255,127);
 AcadColors[101]:=RGBToCol(127,255,159);
 AcadColors[111]:=RGBToCol(127,255,191);
 AcadColors[121]:=RGBToCol(127,255,223);
 AcadColors[131]:=RGBToCol(127,255,255);
 AcadColors[141]:=RGBToCol(127,223,255);
 AcadColors[151]:=RGBToCol(127,191,255);
 AcadColors[161]:=RGBToCol(127,159,255);
 AcadColors[171]:=RGBToCol(127,127,255);
 AcadColors[181]:=RGBToCol(159,127,255);
 AcadColors[191]:=RGBToCol(191,127,255);
 AcadColors[201]:=RGBToCol(223,127,255);
 AcadColors[211]:=RGBToCol(255,127,255);
 AcadColors[221]:=RGBToCol(255,127,223);
 AcadColors[231]:=RGBToCol(255,127,191);
 AcadColors[241]:=RGBToCol(255,127,159);
 AcadColors[13]:=RGBToCol(165,82,82);
 AcadColors[23]:=RGBToCol(165,103,82);
 AcadColors[33]:=RGBToCol(165,124,82);
 AcadColors[43]:=RGBToCol(165,145,82);
 AcadColors[53]:=RGBToCol(165,165,82);
 AcadColors[63]:=RGBToCol(145,165,82);
 AcadColors[73]:=RGBToCol(124,165,82);
 AcadColors[83]:=RGBToCol(103,165,82);
 AcadColors[93]:=RGBToCol(82,165,82);
 AcadColors[103]:=RGBToCol(82,165,103);
 AcadColors[113]:=RGBToCol(82,165,124);
 AcadColors[123]:=RGBToCol(82,165,145);
 AcadColors[133]:=RGBToCol(82,165,165);
 AcadColors[143]:=RGBToCol(82,145,165);
 AcadColors[153]:=RGBToCol(82,124,165);
 AcadColors[163]:=RGBToCol(82,103,165);
 AcadColors[173]:=RGBToCol(82,82,165);
 AcadColors[183]:=RGBToCol(103,82,165);
 AcadColors[193]:=RGBToCol(124,82,165);
 AcadColors[203]:=RGBToCol(145,82,165);
 AcadColors[213]:=RGBToCol(165,82,165);
 AcadColors[223]:=RGBToCol(165,82,145);
 AcadColors[233]:=RGBToCol(165,82,124);
 AcadColors[243]:=RGBToCol(165,82,103);
 AcadColors[15]:=RGBToCol(127,63,63);
 AcadColors[25]:=RGBToCol(127,79,63);
 AcadColors[35]:=RGBToCol(127,95,63);
 AcadColors[45]:=RGBToCol(127,111,63);
 AcadColors[55]:=RGBToCol(127,127,63);
 AcadColors[65]:=RGBToCol(111,127,63);
 AcadColors[75]:=RGBToCol(95,127,63);
 AcadColors[85]:=RGBToCol(79,127,63);
 AcadColors[95]:=RGBToCol(63,127,63);
 AcadColors[105]:=RGBToCol(63,127,79);
 AcadColors[115]:=RGBToCol(63,127,95);
 AcadColors[125]:=RGBToCol(63,127,111);
 AcadColors[135]:=RGBToCol(63,127,127);
 AcadColors[145]:=RGBToCol(63,111,127);
 AcadColors[155]:=RGBToCol(63,95,127);
 AcadColors[165]:=RGBToCol(63,79,127);
 AcadColors[175]:=RGBToCol(63,63,127);
 AcadColors[185]:=RGBToCol(79,63,127);
 AcadColors[195]:=RGBToCol(95,63,127);
 AcadColors[205]:=RGBToCol(111,63,127);
 AcadColors[215]:=RGBToCol(127,63,127);
 AcadColors[225]:=RGBToCol(127,63,111);
 AcadColors[235]:=RGBToCol(127,63,95);
 AcadColors[245]:=RGBToCol(127,63,79);
 AcadColors[17]:=RGBToCol(76,38,38);
 AcadColors[27]:=RGBToCol(76,47,38);
 AcadColors[37]:=RGBToCol(76,57,38);
 AcadColors[47]:=RGBToCol(76,66,38);
 AcadColors[57]:=RGBToCol(76,76,38);
 AcadColors[67]:=RGBToCol(66,76,38);
 AcadColors[77]:=RGBToCol(57,76,38);
 AcadColors[87]:=RGBToCol(47,76,38);
 AcadColors[97]:=RGBToCol(38,76,38);
 AcadColors[107]:=RGBToCol(38,76,47);
 AcadColors[117]:=RGBToCol(38,76,57);
 AcadColors[127]:=RGBToCol(38,76,66);
 AcadColors[137]:=RGBToCol(38,76,76);
 AcadColors[147]:=RGBToCol(38,66,76);
 AcadColors[157]:=RGBToCol(38,57,76);
 AcadColors[167]:=RGBToCol(38,47,76);
 AcadColors[177]:=RGBToCol(38,38,76);
 AcadColors[187]:=RGBToCol(47,38,76);
 AcadColors[197]:=RGBToCol(57,38,76);
 AcadColors[207]:=RGBToCol(66,38,76);
 AcadColors[217]:=RGBToCol(76,38,76);
 AcadColors[227]:=RGBToCol(76,38,66);
 AcadColors[237]:=RGBToCol(76,38,57);
 AcadColors[247]:=RGBToCol(76,38,47);
 AcadColors[19]:=RGBToCol(38,19,19);
 AcadColors[29]:=RGBToCol(38,23,19);
 AcadColors[39]:=RGBToCol(38,28,19);
 AcadColors[49]:=RGBToCol(38,33,19);
 AcadColors[59]:=RGBToCol(38,38,19);
 AcadColors[69]:=RGBToCol(33,38,19);
 AcadColors[79]:=RGBToCol(28,38,19);
 AcadColors[89]:=RGBToCol(23,38,19);
 AcadColors[99]:=RGBToCol(19,38,19);
 AcadColors[109]:=RGBToCol(19,38,23);
 AcadColors[119]:=RGBToCol(19,38,28);
 AcadColors[129]:=RGBToCol(19,38,33);
 AcadColors[139]:=RGBToCol(19,38,38);
 AcadColors[149]:=RGBToCol(19,33,38);
 AcadColors[159]:=RGBToCol(19,28,38);
 AcadColors[169]:=RGBToCol(19,23,38);
 AcadColors[179]:=RGBToCol(19,19,38);
 AcadColors[189]:=RGBToCol(23,19,38);
 AcadColors[199]:=RGBToCol(28,19,38);
 AcadColors[209]:=RGBToCol(33,19,38);
 AcadColors[219]:=RGBToCol(38,19,38);
 AcadColors[229]:=RGBToCol(38,19,33);
 AcadColors[239]:=RGBToCol(38,19,28);
 AcadColors[249]:=RGBToCol(38,19,23);
// ExColors
 AcadColors[250]:=RGBToCol(51,51,51);
 AcadColors[251]:=RGBToCol(91,91,91);
 AcadColors[252]:=RGBToCol(132,132,132);
 AcadColors[253]:=RGBToCol(173,173,173);
 AcadColors[254]:=RGBToCol(214,214,214);
 AcadColors[255]:=RGBToCol(255,255,255);
end.
