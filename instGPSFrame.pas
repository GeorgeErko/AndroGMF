unit instGPSFrame;

// Панель GPS поверх карты: «Старт»/«Стоп» приемника (GPSReceiver), «Следить» -
// карта сдвигается за положением, «К точке» - карта центрируется на нем
// (OnCenter формы). Строки - состояние приемника: решение, спутники, точность,
// DOP, сигнал, координаты WGS-84 и МСК, сближение меридианов, высота, скорость,
// источник, время фиксации.

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Controls.Presentation, GPSReceiver, AppForms;

type
  TInstGPSFrame = class(TFrame)
    Bg: TRectangle;
    TopLay: TLayout;
    sbStart: TSpeedButton;
    cbFollow: TCheckBox;
    sbCenter: TSpeedButton;
    Rows: TLayout;
    procedure sbStartClick(Sender: TObject);
    procedure sbCenterClick(Sender: TObject);
  private
    FGPS: TGPSReceiver;
    FValues: TArray<TLabel>;
    procedure CreateRows;
    procedure SetGPS(const Value: TGPSReceiver);
    procedure SetRow(Index: Integer; const S: String);
  public
   // «К точке»: форма центрирует карту на положении
    OnCenter: TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
   // показ состояния приемника (вызывается формой по OnUpdate приемника)
    procedure UpdateView;
    function Follow: Boolean;
    property GPS: TGPSReceiver read FGPS write SetGPS;
  end;

implementation

{$R *.fmx}

const
  RowNames: array[0..14] of String = ('Состояние', 'Решение', 'Спутники', 'Точность', 'DOP', 'Сигнал',
   'Широта', 'Долгота', 'X (север)', 'Y (восток)', 'Сближение', 'Высота', 'Скорость', 'Источник', 'Время');
  RowHeight = 17;

constructor TInstGPSFrame.Create(AOwner: TComponent);
begin
 inherited;
 Opaque := False; // свой фон Bg со скругленными углами
 CreateRows;
 Height := TopLay.Height + Length(RowNames) * RowHeight + 6;
end;

procedure TInstGPSFrame.CreateRows;
var I: Integer;
    L: TLayout;
    N: TLabel;
begin
 SetLength(FValues, Length(RowNames));
 for I := 0 to High(RowNames) do begin
  L := TLayout.Create(Self);
  L.Parent := Rows;
 // порядок строк при Align = Top - по Position.Y
  L.Position.Y := I * RowHeight;
  L.Align := TAlignLayout.Top;
  L.Height := RowHeight;
  L.HitTest := False;
  N := TLabel.Create(Self);
  N.Parent := L;
  N.Align := TAlignLayout.Left;
  N.Width := 78;
  N.Margins.Left := 6;
  N.Text := RowNames[I];
  N.StyledSettings := N.StyledSettings - [TStyledSetting.FontColor];
  N.TextSettings.FontColor := TAlphaColors.Dimgray;
  N.TextSettings.WordWrap := False;
  N.HitTest := False;
  FValues[I] := TLabel.Create(Self);
  FValues[I].Parent := L;
  FValues[I].Align := TAlignLayout.Client;
  FValues[I].TextSettings.WordWrap := False;
  FValues[I].TextSettings.Trimming := TTextTrimming.Character;
  FValues[I].HitTest := False;
  FValues[I].Text := '-';
 end;
end;

procedure TInstGPSFrame.SetRow(Index: Integer; const S: String);
begin
 if (Index >= 0) and (Index < Length(FValues)) then FValues[Index].Text := S;
end;

procedure TInstGPSFrame.SetGPS(const Value: TGPSReceiver);
begin
 FGPS := Value;
 UpdateView;
end;

function TInstGPSFrame.Follow: Boolean;
begin
 Result := cbFollow.IsChecked;
end;

procedure TInstGPSFrame.sbStartClick(Sender: TObject);
begin
 if FGPS = nil then exit;
 if FGPS.Active then FGPS.Stop else FGPS.Start;
 UpdateView;
end;

procedure TInstGPSFrame.sbCenterClick(Sender: TObject);
begin
 if Assigned(OnCenter) then OnCenter(Self);
end;

// градусы - ±Г°ММ'СС"
function DegToDMS(D: Double): String;
var A: Double;
    G, M: Integer;
    S: Double;
begin
 A := Abs(D);
 G := Trunc(A);
 M := Trunc((A - G) * 60);
 S := ((A - G) * 60 - M) * 60;
 Result := Format('%d°%.2d''%s%.1f"', [G, M, Copy('0', 1, Ord(S < 9.95)), S], TFormatSettings.Invariant);
 if D < 0 then Result := '-' + Result;
end;

function Num(V: Double; Digits: Integer; const Suffix: String = ''): String;
begin
 if IsNan(V) then Result := '-' else Result := FloatToStrF(V, ffFixed, 15, Digits, TFormatSettings.Invariant) + Suffix;
end;

procedure TInstGPSFrame.UpdateView;
var S: TGPSState;
    T: String;
begin
 if FGPS = nil then exit;
 S := FGPS.State;
 if FGPS.Active then sbStart.Text := 'Стоп' else sbStart.Text := 'Старт';
 sbStart.IsPressed := FGPS.Active;
 SetRow(0, S.Status);
 SetRow(1, GPSFixKindText(S.FixKind));
 if S.SatsUsed >= 0 then T := 'в решении ' + IntToStr(S.SatsUsed) else T := 'в решении -';
 if S.SatsInView >= 0 then T := T + ', видно ' + IntToStr(S.SatsInView);
 SetRow(2, T);
 T := '±' + Num(S.Accuracy, 1, ' м');
 if not IsNan(S.VAccuracy) then T := T + ', выс. ±' + Num(S.VAccuracy, 1, ' м');
 SetRow(3, T);
 SetRow(4, 'H ' + Num(S.HDOP, 1) + '  P ' + Num(S.PDOP, 1) + '  V ' + Num(S.VDOP, 1));
 SetRow(5, Num(S.MeanSNR, 0, ' дБ-Гц'));
 if S.HasFix then begin
  SetRow(6, Num(S.Lat, 7, '°'));
  SetRow(7, Num(S.Lon, 7, '°'));
  SetRow(10, DegToDMS(S.Convergence));
  SetRow(14, FormatDateTime('hh:nn:ss', S.FixTime));
 end else begin
  SetRow(6, '-');
  SetRow(7, '-');
  SetRow(10, '-');
  SetRow(14, '-');
 end;
 if S.HasFix and S.HasXY then begin
  SetRow(8, Num(S.North, 3));
  SetRow(9, Num(S.East, 3));
 end else begin
  SetRow(8, '-');
  SetRow(9, '-');
 end;
 SetRow(11, Num(S.Alt, 2, ' м'));
 if IsNan(S.Speed) then SetRow(12, '-') else SetRow(12, Num(S.Speed * 3.6, 1, ' км/ч'));
 if S.Provider = '' then SetRow(13, '-') else SetRow(13, S.Provider);
end;

end.
