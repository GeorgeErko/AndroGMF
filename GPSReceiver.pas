unit GPSReceiver;

// GPS: положение и состояние приемника.
// Android - LocationManager (провайдер gps, нет его - network) и сообщения
// NMEA встроенного приемника (OnNmeaMessageListener):
//  GGA - тип решения (автономное, DGPS, RTK), спутники в решении, HDOP;
//  GSA - PDOP/HDOP/VDOP; GSV - видимые спутники и отношение сигнал/шум.
// Внешний RTK-приемник через подмену местоположения (mock location) дает
// координаты и точность, NMEA - только встроенного приемника.
// Windows - TLocationSensor (служба расположения Windows): координаты и, если
// служба дает, радиус ошибки.
// WGS-84 пересчитывается в МСК (ProjApi.Wgs84LonLatToMsk50XY); сближение
// меридианов - для поперечной Меркатора с осевым меридианом 37.5.
// OnUpdate - в главном потоке.

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math
  {$IFDEF ANDROID}, Androidapi.JNI.Location{$ENDIF}
  {$IFDEF MSWINDOWS}, System.Sensors, System.Sensors.Components{$ENDIF};

type
 // тип решения (GGA: 0 - нет, 1 - автономное, 2 - DGPS, 4 - RTK fixed,
 // 5 - RTK float, 6 - счисление); gkLocation - только от системы (без NMEA)
  TGPSFixKind = (gkNone, gkAutonomous, gkDGPS, gkRTKFixed, gkRTKFloat, gkEstimated, gkLocation);

  TGPSState = record
    HasFix: Boolean;
    Lat, Lon: Double;           // градусы WGS-84
    Alt: Double;                // м; NaN - нет
    Accuracy: Double;           // м, радиус ошибки в плане; NaN - нет
    VAccuracy: Double;          // м, по высоте; NaN - нет
    Speed: Double;              // м/с; NaN - нет
    Provider: String;
    FixTime: TDateTime;         // местное время фиксации
    HasXY: Boolean;
    North, East: Double;        // МСК: X (на север), Y (на восток)
    Convergence: Double;        // сближение меридианов, градусы
    FixKind: TGPSFixKind;
    SatsUsed: Integer;          // -1 - нет данных
    SatsInView: Integer;
    HDOP, PDOP, VDOP: Double;   // NaN - нет
    MeanSNR: Double;            // дБ-Гц, среднее по видимым; NaN - нет
    Status: String;
  end;

  TGPSReceiver = class
  private
    FState: TGPSState;
    FActive: Boolean;
    FOnUpdate: TNotifyEvent;
    FInView: TStringList;       // GSV по системам (GP, GL, GA, GB...): видимые
    FSnrSum, FSnrCnt: TStringList; // и сумма/число SNR последнего цикла
   {$IFDEF ANDROID}
    FManager: JLocationManager;
    FListener: JLocationListener;
    FNmea: JOnNmeaMessageListener;
   {$ENDIF}
   {$IFDEF MSWINDOWS}
    FSensor: TLocationSensor;
    procedure SensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
   {$ENDIF}
    procedure Changed;
    procedure SetStatus(const S: String);
    procedure StartPlatform;
    procedure StopPlatform;
  public
    constructor Create;
    destructor Destroy; override;
   // запуск: на Android - запрос разрешения на местоположение
    procedure Start;
    procedure Stop;
   // положение (главный поток): WGS-84, точность (м, NaN - нет), высота,
   // скорость, провайдер, время (мс от 1970, UTC)
    procedure SetLocation(Lat, Lon, Acc, Alt, VAcc, Speed: Double; const Provider: String; TimeMs: Int64; Sats: Integer);
   // строка NMEA (главный поток)
    procedure ParseNmea(const S: String);
   // мировые координаты карты (X - восток, Y - минус север, как Selector)
    function WorldXY(out WX, WY: Double): Boolean;
    property Active: Boolean read FActive;
    property State: TGPSState read FState;
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
  end;

function GPSFixKindText(K: TGPSFixKind): String;

implementation

uses System.DateUtils, ProjApi
 {$IFDEF ANDROID}, System.Permissions, Androidapi.JNIBridge, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Os, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.Helpers{$ENDIF};

const
  Msk50Lon0 = 37.5; // осевой меридиан МСК (ProjApi: +lon_0=37.5)

function GPSFixKindText(K: TGPSFixKind): String;
begin
 case K of
  gkAutonomous: Result := 'автономное';
  gkDGPS: Result := 'DGPS';
  gkRTKFixed: Result := 'RTK fixed';
  gkRTKFloat: Result := 'RTK float';
  gkEstimated: Result := 'счисление';
  gkLocation: Result := 'есть';
 else
  Result := 'нет';
 end;
end;

{$IFDEF ANDROID}
type
  TGPSLocationListener = class(TJavaLocal, JLocationListener)
  private
    FOwner: TGPSReceiver;
  public
    constructor Create(AOwner: TGPSReceiver);
    procedure onFlushComplete(requestCode: Integer); cdecl;
    procedure onLocationChanged(location: JLocation); overload; cdecl;
    procedure onLocationChanged(locations: JList); overload; cdecl;
    procedure onProviderDisabled(provider: JString); cdecl;
    procedure onProviderEnabled(provider: JString); cdecl;
    procedure onStatusChanged(provider: JString; status: Integer; extras: JBundle); cdecl;
  end;

  TGPSNmeaListener = class(TJavaLocal, JOnNmeaMessageListener)
  private
    FOwner: TGPSReceiver;
  public
    constructor Create(AOwner: TGPSReceiver);
    procedure onNmeaMessage(message: JString; timestamp: Int64); cdecl;
  end;

constructor TGPSLocationListener.Create(AOwner: TGPSReceiver);
begin
 inherited Create;
 FOwner := AOwner;
end;

procedure TGPSLocationListener.onFlushComplete(requestCode: Integer);
begin
end;

// поток Java - данные копируются и передаются в главный поток
procedure TGPSLocationListener.onLocationChanged(location: JLocation);
var Lat, Lon, Acc, Alt, VAcc, Speed: Double;
    Prov: String;
    T: Int64;
    Sats: Integer;
    Ex: JBundle;
    O: TGPSReceiver;
begin
 if location = nil then exit;
 Lat := location.getLatitude;
 Lon := location.getLongitude;
 if location.hasAccuracy then Acc := location.getAccuracy else Acc := NaN;
 if location.hasAltitude then Alt := location.getAltitude else Alt := NaN;
 if location.hasVerticalAccuracy then VAcc := location.getVerticalAccuracyMeters else VAcc := NaN;
 if location.hasSpeed then Speed := location.getSpeed else Speed := NaN;
 Prov := JStringToString(location.getProvider);
 T := location.getTime;
// число спутников в решении - в дополнительных данных (не у всех устройств)
 Sats := -1;
 Ex := location.getExtras;
 if Ex <> nil then Sats := Ex.getInt(StringToJString('satellites'), -1);
 O := FOwner;
 TThread.Queue(nil, procedure begin O.SetLocation(Lat, Lon, Acc, Alt, VAcc, Speed, Prov, T, Sats); end);
end;

procedure TGPSLocationListener.onLocationChanged(locations: JList);
begin
 if (locations <> nil) and (locations.size > 0) then
  onLocationChanged(TJLocation.Wrap((locations.get(locations.size - 1) as ILocalObject).GetObjectID));
end;

procedure TGPSLocationListener.onProviderDisabled(provider: JString);
var O: TGPSReceiver;
    S: String;
begin
 O := FOwner;
 S := 'выключен: ' + JStringToString(provider);
 TThread.Queue(nil, procedure begin O.SetStatus(S); end);
end;

procedure TGPSLocationListener.onProviderEnabled(provider: JString);
var O: TGPSReceiver;
    S: String;
begin
 O := FOwner;
 S := 'включен: ' + JStringToString(provider);
 TThread.Queue(nil, procedure begin O.SetStatus(S); end);
end;

procedure TGPSLocationListener.onStatusChanged(provider: JString; status: Integer; extras: JBundle);
begin
end;

constructor TGPSNmeaListener.Create(AOwner: TGPSReceiver);
begin
 inherited Create;
 FOwner := AOwner;
end;

procedure TGPSNmeaListener.onNmeaMessage(message: JString; timestamp: Int64);
var O: TGPSReceiver;
    S: String;
begin
 if message = nil then exit;
 O := FOwner;
 S := JStringToString(message);
 TThread.Queue(nil, procedure begin O.ParseNmea(S); end);
end;
{$ENDIF}

{ TGPSReceiver }

constructor TGPSReceiver.Create;
begin
 inherited Create;
 FInView := TStringList.Create;
 FSnrSum := TStringList.Create;
 FSnrCnt := TStringList.Create;
 FState.Alt := NaN;
 FState.Accuracy := NaN;
 FState.VAccuracy := NaN;
 FState.Speed := NaN;
 FState.SatsUsed := -1;
 FState.SatsInView := -1;
 FState.HDOP := NaN;
 FState.PDOP := NaN;
 FState.VDOP := NaN;
 FState.MeanSNR := NaN;
 FState.Status := 'выключен';
end;

destructor TGPSReceiver.Destroy;
begin
 FOnUpdate := nil;
 Stop;
 FInView.Free;
 FSnrSum.Free;
 FSnrCnt.Free;
 inherited;
end;

procedure TGPSReceiver.Changed;
begin
 if Assigned(FOnUpdate) then FOnUpdate(Self);
end;

procedure TGPSReceiver.SetStatus(const S: String);
begin
 FState.Status := S;
 Changed;
end;

procedure TGPSReceiver.Start;
{$IFDEF ANDROID}
const PermFine = 'android.permission.ACCESS_FINE_LOCATION';
      PermCoarse = 'android.permission.ACCESS_COARSE_LOCATION';
{$ENDIF}
begin
 if FActive then exit;
{$IFDEF ANDROID}
 if not PermissionsService.IsPermissionGranted(PermFine) then begin
  SetStatus('запрос разрешения');
  PermissionsService.RequestPermissions([PermFine, PermCoarse],
   procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
   begin
    if (Length(AGrantResults) > 0) and (AGrantResults[0] = TPermissionStatus.Granted) then StartPlatform else
     SetStatus('нет разрешения на местоположение');
   end);
  exit;
 end;
{$ENDIF}
 StartPlatform;
end;

{$IFDEF ANDROID}
procedure TGPSReceiver.StartPlatform;
var M: JLocationManager;
    Prov: JString;
    Last: JLocation;
begin
 M := TJLocationManager.Wrap((TAndroidHelper.Context.getSystemService(TJContext.JavaClass.LOCATION_SERVICE) as ILocalObject).GetObjectID);
 if M = nil then begin
  SetStatus('нет службы местоположения');
  exit;
 end;
 Prov := TJLocationManager.JavaClass.GPS_PROVIDER;
 if not M.isProviderEnabled(Prov) then begin
  Prov := TJLocationManager.JavaClass.NETWORK_PROVIDER;
  if not M.isProviderEnabled(Prov) then begin
   SetStatus('местоположение выключено в настройках');
   exit;
  end;
 end;
 FManager := M;
 FListener := TGPSLocationListener.Create(Self);
 FNmea := TGPSNmeaListener.Create(Self);
 try
  M.requestLocationUpdates(Prov, 1000, 0, FListener, TJLooper.JavaClass.getMainLooper);
 except
  on E: Exception do begin
   FManager := nil;
   FListener := nil;
   FNmea := nil;
   SetStatus('ошибка запуска: ' + E.Message);
   exit;
  end;
 end;
// NMEA - для статистики; нет - работаем без нее
 try
  M.addNmeaListener(FNmea, TJHandler.JavaClass.init(TJLooper.JavaClass.getMainLooper));
 except
  FNmea := nil;
 end;
 FActive := True;
 SetStatus('поиск спутников (' + JStringToString(Prov) + ')');
 Last := M.getLastKnownLocation(Prov);
 if Last <> nil then FListener.onLocationChanged(Last);
end;

procedure TGPSReceiver.StopPlatform;
begin
 if FManager = nil then exit;
 try
  if FListener <> nil then FManager.removeUpdates(FListener);
  if FNmea <> nil then FManager.removeNmeaListener(FNmea);
 except
 end;
 FNmea := nil;
 FListener := nil;
 FManager := nil;
end;
{$ELSEIF DEFINED(MSWINDOWS)}
procedure TGPSReceiver.StartPlatform;
begin
 if FSensor = nil then begin
  FSensor := TLocationSensor.Create(nil);
  FSensor.OnLocationChanged := SensorLocationChanged;
 end;
 FSensor.Active := True;
 if not FSensor.Active or (FSensor.Sensor = nil) then begin
  SetStatus('нет датчика местоположения');
  exit;
 end;
 FActive := True;
 SetStatus('поиск (служба расположения Windows)');
end;

procedure TGPSReceiver.StopPlatform;
begin
 if FSensor <> nil then begin
  FSensor.Active := False;
  FreeAndNil(FSensor);
 end;
end;

procedure TGPSReceiver.SensorLocationChanged(Sender: TObject; const OldLocation, NewLocation: TLocationCoord2D);
var Acc, Alt: Double;
begin
 Acc := NaN;
 Alt := NaN;
 if (FSensor <> nil) and (FSensor.Sensor <> nil) then try
  Acc := FSensor.Sensor.ErrorRadius;
  Alt := FSensor.Sensor.Altitude;
  if Acc <= 0 then Acc := NaN;
 except
 end;
 SetLocation(NewLocation.Latitude, NewLocation.Longitude, Acc, Alt, NaN, NaN, 'windows', DateTimeToUnix(Now, False) * 1000, -1);
end;
{$ELSE}
procedure TGPSReceiver.StartPlatform;
begin
 SetStatus('GPS на этой платформе не поддерживается');
end;

procedure TGPSReceiver.StopPlatform;
begin
end;
{$ENDIF}

procedure TGPSReceiver.Stop;
begin
 StopPlatform;
 if not FActive then exit;
 FActive := False;
 FState.HasFix := False;
 SetStatus('выключен');
end;

procedure TGPSReceiver.SetLocation(Lat, Lon, Acc, Alt, VAcc, Speed: Double; const Provider: String; TimeMs: Int64; Sats: Integer);
var E, N, DL: Double;
begin
 if not FActive then exit;
 FState.HasFix := True;
 FState.Lat := Lat;
 FState.Lon := Lon;
 FState.Accuracy := Acc;
 if not IsNan(Alt) then FState.Alt := Alt;
 FState.VAccuracy := VAcc;
 FState.Speed := Speed;
 FState.Provider := Provider;
 FState.FixTime := UnixToDateTime(TimeMs div 1000, False);
 if Sats >= 0 then FState.SatsUsed := Sats;
// без NMEA тип решения неизвестен
 if FState.FixKind = gkNone then FState.FixKind := gkLocation;
 FState.HasXY := Wgs84LonLatToMsk50XY(Lon, Lat, E, N);
 if FState.HasXY then begin
  FState.North := N;
  FState.East := E;
 end;
// сближение меридианов поперечной Меркатора: tg(g) = tg(L - L0) * sin(B)
 DL := DegToRad(Lon - Msk50Lon0);
 FState.Convergence := RadToDeg(ArcTan(Tan(DL) * Sin(DegToRad(Lat))));
 FState.Status := 'есть решение';
 Changed;
end;

function TGPSReceiver.WorldXY(out WX, WY: Double): Boolean;
begin
 Result := FState.HasFix and FState.HasXY;
 if not Result then exit;
 WX := FState.East;
 WY := -FState.North;
end;

// поля строки NMEA (без $ и контрольной суммы)
function NmeaFields(const S: String): TArray<String>;
var T: String;
    P: Integer;
begin
 T := Trim(S);
 if (T <> '') and (T[1] = '$') then Delete(T, 1, 1);
 P := Pos('*', T);
 if P > 0 then T := Copy(T, 1, P - 1);
 Result := T.Split([',']);
end;

function NmeaInt(const F: TArray<String>; I: Integer; Def: Integer = -1): Integer;
begin
 if (I >= Length(F)) or not TryStrToInt(F[I], Result) then Result := Def;
end;

function NmeaFloat(const F: TArray<String>; I: Integer): Double;
begin
 if (I >= Length(F)) or not TryStrToFloat(F[I], Result, TFormatSettings.Invariant) then Result := NaN;
end;

procedure TGPSReceiver.ParseNmea(const S: String);
var F: TArray<String>;
    Kind, Talker: String;
    I, N, Q, Snr, Total, Cnt: Integer;
    Sum: Double;
begin
 if not FActive then exit;
 F := NmeaFields(S);
 if (Length(F) = 0) or (Length(F[0]) < 5) then exit;
 Talker := Copy(F[0], 1, 2);
 Kind := Copy(F[0], 3, 3);
 if Kind = 'GGA' then begin
  Q := NmeaInt(F, 6, 0);
  case Q of
   1: FState.FixKind := gkAutonomous;
   2: FState.FixKind := gkDGPS;
   4: FState.FixKind := gkRTKFixed;
   5: FState.FixKind := gkRTKFloat;
   6: FState.FixKind := gkEstimated;
  else
   FState.FixKind := gkNone;
  end;
  N := NmeaInt(F, 7);
  if N >= 0 then FState.SatsUsed := N;
  if not IsNan(NmeaFloat(F, 8)) then FState.HDOP := NmeaFloat(F, 8);
  Changed;
 end else
 if Kind = 'GSA' then begin
  if not IsNan(NmeaFloat(F, 15)) then FState.PDOP := NmeaFloat(F, 15);
  if not IsNan(NmeaFloat(F, 16)) then FState.HDOP := NmeaFloat(F, 16);
  if not IsNan(NmeaFloat(F, 17)) then FState.VDOP := NmeaFloat(F, 17);
 end else
 if Kind = 'GSV' then begin
 // $xxGSV,всего сообщений,номер,видимых, (номер,высота,азимут,SNR) x 4
  N := NmeaInt(F, 3, 0);
  FInView.Values[Talker] := IntToStr(N);
  if NmeaInt(F, 2) = 1 then begin
   FSnrSum.Values[Talker] := '0';
   FSnrCnt.Values[Talker] := '0';
  end;
  I := 7;
  while I < Length(F) do begin
   Snr := NmeaInt(F, I, 0);
   if Snr > 0 then begin
    FSnrSum.Values[Talker] := IntToStr(StrToIntDef(FSnrSum.Values[Talker], 0) + Snr);
    FSnrCnt.Values[Talker] := IntToStr(StrToIntDef(FSnrCnt.Values[Talker], 0) + 1);
   end;
   Inc(I, 4);
  end;
 // итоги по всем системам - после последнего сообщения цикла
  if NmeaInt(F, 2) = NmeaInt(F, 1) then begin
   Total := 0;
   for I := 0 to FInView.Count - 1 do Inc(Total, StrToIntDef(FInView.ValueFromIndex[I], 0));
   FState.SatsInView := Total;
   Sum := 0;
   Cnt := 0;
   for I := 0 to FSnrSum.Count - 1 do begin
    Sum := Sum + StrToIntDef(FSnrSum.ValueFromIndex[I], 0);
    Inc(Cnt, StrToIntDef(FSnrCnt.Values[FSnrSum.Names[I]], 0));
   end;
   if Cnt > 0 then FState.MeanSNR := Sum / Cnt else FState.MeanSNR := NaN;
   Changed;
  end;
 end;
end;

end.
