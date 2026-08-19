unit MainFrmOSM;

interface

uses
  System.Classes, System.Generics.Collections, System.Math, System.Net.HttpClient,
     System.SysUtils, System.Threading, System.Types, System.UITypes, FMX.Ani,
     FMX.Controls, FMX.Controls.Presentation, FMX.Dialogs, FMX.Forms,
     FMX.Graphics, FMX.ImgList, FMX.Layouts, FMX.Memo, FMX.Memo.Types,
     FMX.Objects, FMX.ScrollBox, FMX.Skia, FMX.StdCtrls, FMX.Types,
     InstLayerFrame, MainFrmMouseObj, ProjApi, System.ImageList, System.IOUtils, System.Skia;

type
  TMainFormOSM = class(TMainFormMouseObj)
    lMas: TLabel;
    procedure btnDocClick(Sender: TObject);
    procedure btnGPKGBClick(Sender: TObject);
    procedure btnLocalOpenClick(Sender: TObject);
  private
   type
    TOsmTile = record
      Z, X, Y: Integer;
      Key: string;
    end;
  private
    FOsmZoom: Integer;
    FOsmTiles: TDictionary<string, ISkImage>;
    FOsmTileList: TArray<TOsmTile>;
    FOsmLonMin, FOsmLatMin, FOsmLonMax, FOsmLatMax: Double;
    FOsmOriginPx, FOsmOriginPy: Double;
    FOsmScale: Double;
    FOsmHasView: Boolean;
    FOsmRequestId: Int64;
    FOsmPaintLogged: Boolean;
    FOsmClosing: Boolean;
    FOsmScaleDenom: Double;
    FOsmScaleDenomManual: Boolean;
    FOsmReqTimer: TTimer;
    FCachedTiles: Boolean;
    FOsmRedrawPending: Boolean;
    FOsmLastReqXMin, FOsmLastReqYMin, FOsmLastReqXMax, FOsmLastReqYMax: Double;
    FOsmLastReqValid: Boolean;
    procedure OsmReqTimer(Sender: TObject);
    procedure MaybeScheduleOsmRequest;
    function TryClientToGeo(const X, Y: Single; out GeoX, GeoY: Double): Boolean;
    function GetOsmTileCacheFileName(const Z, X, Y: Integer): string;
    procedure EnsureOsmTileCacheDir(const Z, X: Integer);
    function TryEstimateScaleDenom(out ADenom: Double): Boolean;
    procedure EnsureOsm;
    procedure ClearOsm;
    procedure ClearOsmTileCache;
    procedure RequestOsmTilesFromActiveRect;
    procedure DownloadTileAsync(const Tile: TOsmTile; const RequestId: Int64);
    function TryGetOsmBboxWgs84FromActiveRect(out LonMin, LatMin, LonMax, LatMax: Double): Boolean;
    procedure BuildOsmView(const LonMin, LatMin, LonMax, LatMax: Double; const Dest: TRectF);
    procedure DrawOsmTiles(const ACanvas: ISkCanvas; const Rect: TRectF);
    class function ScaleDenomToZoom(const ADenom, LatCenterDeg: Double): Integer; static;
    class function ClampInt(const V, AMin, AMax: Integer): Integer; static;
    class function LonToTileX(const LonDeg: Double; const Z: Integer): Integer; static;
    class function LatToTileY(const LatDeg: Double; const Z: Integer): Integer; static;
    class function LonToGlobalPx(const LonDeg: Double; const Z: Integer): Double; static;
    class function LatToGlobalPy(const LatDeg: Double; const Z: Integer): Double; static;
  protected
    procedure Loaded; override;
    destructor Destroy; override;
    procedure OpenGmfFileSkia(const LocalPath: string); override;
    procedure PaintBefore(const ACanvas: ISkCanvas; const Rect: TRectF); override;
    procedure PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF); override;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetOsmScaleDenom(const ADenom: Double);
    property CachedTiles: Boolean read FCachedTiles write FCachedTiles;
  end;

var
  MainFormOSM: TMainFormOSM;

implementation uses ogcBasic, Writer, DlgLocalOpen, OpenForm, GPKGReader;

{$R *.fmx}

procedure TMainFormOSM.EnsureOsm;
begin
 if FOsmTiles = nil then
  FOsmTiles := TDictionary<string, ISkImage>.Create;
 if FOsmZoom <= 0 then
  FOsmZoom := 16;
end;

procedure TMainFormOSM.ClearOsm;
begin
 EnsureOsm;
 FOsmTiles.Clear;
 SetLength(FOsmTileList, 0);
 FOsmHasView := False;
 FOsmPaintLogged := False;
end;

procedure TMainFormOSM.ClearOsmTileCache;
var
 CacheDir: string;
begin
 CacheDir := TPath.Combine(TPath.GetCachePath, 'OSM');
 if TDirectory.Exists(CacheDir) then
 begin
  try
   TDirectory.Delete(CacheDir, True);
   WriteIn(['OSM tile cache cleared: ', CacheDir]);
  except on E: Exception do
   WriteIn(['OSM tile cache clear error: ', E.Message]);
  end;
 end;
end;

destructor TMainFormOSM.Destroy;
begin
 FOsmClosing := True;
 Inc(FOsmRequestId);
 if FOsmReqTimer <> nil then
 begin
  FOsmReqTimer.Enabled := False;
  FOsmReqTimer.Free;
  FOsmReqTimer := nil;
 end;
 FOsmTiles.Free;
 inherited;
end;

procedure TMainFormOSM.Loaded;
begin
 inherited;
 EnsureOsm;
 FCachedTiles := True;
 FOsmRedrawPending := False;
end;

procedure TMainFormOSM.OsmReqTimer(Sender: TObject);
begin
 WriteIn(['OSM CachePath: ', TPath.GetCachePath]);
 if FOsmReqTimer <> nil then
  FOsmReqTimer.Enabled := False;
 if FOsmClosing then exit;
 RequestOsmTilesFromActiveRect;
end;

procedure TMainFormOSM.MaybeScheduleOsmRequest;
var
 XMin, YMin, XMax, YMax: Double;
 W, H, Dx, Dy, Dx2, Dy2: Double;
 Need: Boolean;
begin
 if FOsmClosing then exit;
 if Selector = nil then exit;
 if (Selector.ActiveRect = nil) or (not Selector.ActiveRect.isRect) then exit;
 XMin := Selector.ActiveRect.XMin;
 YMin := Selector.ActiveRect.YMin;
 XMax := Selector.ActiveRect.XMax;
 YMax := Selector.ActiveRect.YMax;
 Need := not FOsmLastReqValid;
 if not Need then
 begin
  W := Abs(FOsmLastReqXMax - FOsmLastReqXMin);
  H := Abs(FOsmLastReqYMax - FOsmLastReqYMin);
  if W <= 0 then W := 1;
  if H <= 0 then H := 1;
  Dx := Abs(XMin - FOsmLastReqXMin) / W;
  Dy := Abs(YMin - FOsmLastReqYMin) / H;
  Dx2 := Abs(XMax - FOsmLastReqXMax) / W;
  Dy2 := Abs(YMax - FOsmLastReqYMax) / H;
  if (Dx > 0.03) or (Dy > 0.03) or (Dx2 > 0.03) or (Dy2 > 0.03) then
   Need := True;
 end;
 if not Need then exit;
 EnsureOsm;
 if FOsmReqTimer = nil then
 begin
  FOsmReqTimer := TTimer.Create(Self);
  FOsmReqTimer.Enabled := False;
  FOsmReqTimer.Interval := 250;
  FOsmReqTimer.OnTimer := OsmReqTimer;
 end;
 FOsmReqTimer.Enabled := False;
 FOsmReqTimer.Enabled := True;
end;

function TMainFormOSM.TryClientToGeo(const X, Y: Single; out GeoX, GeoY: Double): Boolean;
var
 XPix, YPix: Double;
begin
 Result := False;
 if Selector = nil then exit;
 if LastCanvasScale <= 0 then exit;
 XPix := X * LastCanvasScale;
 YPix := Y * LastCanvasScale;
 GeoX := -Selector.YGeo(Round(YPix));
 GeoY := Selector.XGeo(Round(XPix));
 Result := True;
end;

function TMainFormOSM.GetOsmTileCacheFileName(const Z, X, Y: Integer): string;
begin
 Result := TPath.Combine(TPath.GetCachePath, TPath.Combine('OSM',
  TPath.Combine(IntToStr(Z), TPath.Combine(IntToStr(X), IntToStr(Y) + '.png'))));
end;

procedure TMainFormOSM.EnsureOsmTileCacheDir(const Z, X: Integer);
var
 Dir: string;
begin
 Dir := TPath.Combine(TPath.GetCachePath, TPath.Combine('OSM', TPath.Combine(IntToStr(Z), IntToStr(X))));
 if not TDirectory.Exists(Dir) then
  TDirectory.CreateDirectory(Dir);
end;

function TMainFormOSM.TryEstimateScaleDenom(out ADenom: Double): Boolean;
var
 GX0, GY0, GX1, GY1, GX2, GY2: Double;
 D1, D2, MppGround, MppScreen: Double;
begin
 Result := False;
 ADenom := 0;
 if (SkPainter = nil) or (Selector = nil) then exit;
 if LastCanvasScale <= 0 then exit;
 if not TryClientToGeo(0, 0, GX0, GY0) then exit;
 if not TryClientToGeo(1, 0, GX1, GY1) then exit;
 if not TryClientToGeo(0, 1, GX2, GY2) then exit;
 D1 := Hypot(GX1 - GX0, GY1 - GY0);
 D2 := Hypot(GX2 - GX0, GY2 - GY0);
 MppGround := (D1 + D2) * 0.5;
 if MppGround <= 0 then exit;
 MppScreen := 0.00028;
 if MppScreen <= 0 then exit;
 ADenom := MppGround / MppScreen;
 Result := ADenom > 0;
end;

procedure TMainFormOSM.SetOsmScaleDenom(const ADenom: Double);
begin
 if ADenom <= 0 then exit;
 FOsmScaleDenom := ADenom;
 FOsmScaleDenomManual := True;
end;

class function TMainFormOSM.ScaleDenomToZoom(const ADenom, LatCenterDeg: Double): Integer;
var
 Mpp, Mpp0, LatRad, K: Double;
 Z: Double;
begin
 Result := 16;
 if ADenom <= 0 then exit;
 LatRad := DegToRad(LatCenterDeg);
 K := Cos(LatRad);
 if K < 0.01 then K := 0.01;
 Mpp := ADenom * 0.00028;
 if Mpp <= 0 then exit;
 Mpp0 := 156543.03392804097;
 Z := Ln((Mpp0 * K) / Mpp) / Ln(2);
 Result := ClampInt(Round(Z), 1, 18);
end;

class function TMainFormOSM.ClampInt(const V, AMin, AMax: Integer): Integer;
begin
 Result := V;
 if Result < AMin then Result := AMin;
 if Result > AMax then Result := AMax;
end;

class function TMainFormOSM.LonToTileX(const LonDeg: Double; const Z: Integer): Integer;
var N: Double;
begin
 N := Power(2, Z);
 Result := Floor((LonDeg + 180.0) / 360.0 * N);
 Result := ClampInt(Result, 0, Trunc(N) - 1);
end;

class function TMainFormOSM.LatToTileY(const LatDeg: Double; const Z: Integer): Integer;
var
 N, LatRad, Y: Double;
begin
 N := Power(2, Z);
 LatRad := DegToRad(LatDeg);
 Y := (1.0 - Ln(Tan(LatRad) + 1.0 / Cos(LatRad)) / Pi) / 2.0 * N;
 Result := Floor(Y);
 Result := ClampInt(Result, 0, Trunc(N) - 1);
end;

class function TMainFormOSM.LonToGlobalPx(const LonDeg: Double; const Z: Integer): Double;
var N: Double;
begin
 N := Power(2, Z) * 256.0;
 Result := (LonDeg + 180.0) / 360.0 * N;
end;

class function TMainFormOSM.LatToGlobalPy(const LatDeg: Double; const Z: Integer): Double;
var
 N, LatRad, Y: Double;
begin
 N := Power(2, Z) * 256.0;
 LatRad := DegToRad(LatDeg);
 Y := (1.0 - Ln(Tan(LatRad) + 1.0 / Cos(LatRad)) / Pi) / 2.0;
 Result := Y * N;
end;

function TMainFormOSM.TryGetOsmBboxWgs84FromActiveRect(out LonMin, LatMin, LonMax, LatMax: Double): Boolean;
var
 L0, B0, L1, B1, L2, B2, L3, B3: Double;
 GX, GY: Double;
 W, H: Single;
begin
 Result := False;
 if Selector = nil then exit;
 if SkPainter = nil then exit;
 if LastCanvasScale <= 0 then exit;
 W := SkPainter.Width;
 H := SkPainter.Height;
 if (W <= 1) or (H <= 1) then exit;
 if not TryClientToGeo(0, 0, GX, GY) then exit;
 if not Msk50ToWgs84LonLat(GY, GX, L0, B0) then exit;
 if not TryClientToGeo(W, 0, GX, GY) then exit;
 if not Msk50ToWgs84LonLat(GY, GX, L1, B1) then exit;
 if not TryClientToGeo(0, H, GX, GY) then exit;
 if not Msk50ToWgs84LonLat(GY, GX, L2, B2) then exit;
 if not TryClientToGeo(W, H, GX, GY) then exit;
 if not Msk50ToWgs84LonLat(GY, GX, L3, B3) then exit;
 LonMin := Min(Min(L0, L1), Min(L2, L3));
 LonMax := Max(Max(L0, L1), Max(L2, L3));
 LatMin := Min(Min(B0, B1), Min(B2, B3));
 LatMax := Max(Max(B0, B1), Max(B2, B3));
 Result := True;
end;

procedure TMainFormOSM.btnDocClick(Sender: TObject);
var X, Y: Double;
begin
 Wgs84LonLatToMsk50XY(37.721103, 55.617586, X, Y);
 WriteIn(['Belova XY = ', X, Y]);
end;

procedure TMainFormOSM.btnGPKGBClick(Sender: TObject);
begin
  inherited;
//
end;

procedure TMainFormOSM.btnLocalOpenClick(Sender: TObject);
begin
 localOpenForm := TlocalOpenForm.Create(Self);
{$IFDEF ANDROID}
 localOpenForm.BaseDir := GetAppExternalFilesDir;
{$ENDIF}
 localOpenForm.FCallBack :=
  procedure(const LocalPath: string)
  var Ext: string;
      Reader: TGPKGReader;
      I: Integer;
      Layer: TGPKGLayer;
      S: TStringList;
  begin
   if LocalPath = '' then exit;
   Ext := LowerCase(ExtractFileExt(LocalPath));
   if Ext = '.gpkg' then
   begin
    WriteIn(['gpkg: ', LocalPath]);
    Reader := TGPKGReader.Create(LocalPath);
    try
     if not Reader.Open then
     begin
      WriteIn(['open gpkg failed']);
      exit;
     end;
     WriteIn(['layers: ', Reader.GetLayerCount]);
     for I := 0 to Reader.GetLayerCount - 1 do
     begin
      Layer := Reader.GetLayer(I);
      WriteIn([' layer ', I, ': ', Layer.TableName, ' | ', Layer.Identifier, ' | ', Layer.DataType]);
      S := Reader.DumpLayerCoordsSrs(Layer.TableName);
      WriteIn([S.Text]);
      WriteIn(['endDump============================']);
      S.Free;
     end;
    finally
     Reader.Free;
    end;
    exit;
   end;
   OpenGmfFile(LocalPath);
  end;
 localOpenForm.Show;
end;

procedure TMainFormOSM.BuildOsmView(const LonMin, LatMin, LonMax, LatMax: Double; const Dest: TRectF);
var Px0, Py0, Px1, Py1, W, H: Double;
begin
 FOsmLonMin := LonMin;
 FOsmLatMin := LatMin;
 FOsmLonMax := LonMax;
 FOsmLatMax := LatMax;
 Px0 := LonToGlobalPx(LonMin, FOsmZoom);
 Py0 := LatToGlobalPy(LatMax, FOsmZoom);
 Px1 := LonToGlobalPx(LonMax, FOsmZoom);
 Py1 := LatToGlobalPy(LatMin, FOsmZoom);
 W := Max(1.0, Px1 - Px0);
 H := Max(1.0, Py1 - Py0);
 FOsmOriginPx := Px0;
 FOsmOriginPy := Py0;
 FOsmScale := Min(Dest.Width / W, Dest.Height / H);
 FOsmHasView := True;
end;

procedure TMainFormOSM.DownloadTileAsync(const Tile: TOsmTile; const RequestId: Int64);
begin
 if FOsmClosing then exit;
 WriteIn(['DownloadTileAsync start ', Tile.Key, ' RequestId=', RequestId]);
 TTask.Run(
  procedure
  var Client: THTTPClient;
      Resp: IHTTPResponse;
      Url: string;
      MS: TMemoryStream;
      Img: ISkImage;
      FileName: string;
  begin
   if FOsmClosing then exit;
   WriteIn(['DownloadTileAsync task start ', Tile.Key]);
   Client := nil;
   MS := nil;
   try
    FileName := GetOsmTileCacheFileName(Tile.Z, Tile.X, Tile.Y);
    if FCachedTiles then
    begin
     WriteIn(['Tile cache file: ', FileName, ' exists: ', TFile.Exists(FileName)]);
     if TFile.Exists(FileName) then
     begin
      WriteIn(['Loading tile from local cache: ', FileName]);
      MS := TMemoryStream.Create;
      MS.LoadFromFile(FileName);
      MS.Position := 0;
      Img := TSkImage.MakeFromEncodedStream(MS);
      WriteIn(['Tile loaded from cache, Img <> nil: ', Img <> nil]);
      if Img <> nil then
      begin
       MS.Free;
       MS := nil;
       TThread.Queue(nil,
        procedure
        begin
         if FOsmClosing then exit;
         if RequestId <> FOsmRequestId then exit;
         EnsureOsm;
         FOsmTiles.AddOrSetValue(Tile.Key, Img);
         if SkPainter <> nil then
          SkPainter.Redraw;
        end);
       exit;
      end;
      MS.Free;
      MS := nil;
     end;
    end;

    Url := Format('https://tile.openstreetmap.org/%d/%d/%d.png', [Tile.Z, Tile.X, Tile.Y]);
    WriteIn(['OSM GET start ', Url]);
    Client := THTTPClient.Create;
    Client.UserAgent := 'AndroGMF/1.0';
    Client.ConnectionTimeout := 30000;
    Client.ResponseTimeout := 30000;
    try
     Resp := Client.Get(Url);
    except on E: Exception do
     begin
      WriteIn(['OSM GET exception ', E.ClassName, ' ', E.Message, ' ', Url]);
      exit;
     end;
    end;
    if Resp = nil then
    begin
     WriteIn(['OSM HTTP nil resp ', Url]);
     exit;
    end;
    WriteIn(['OSM HTTP status ', Resp.StatusCode, ' ', Url]);
    if Resp.StatusCode <> 200 then
    begin
     WriteIn(['OSM HTTP non-200 status ', Resp.StatusCode, ' ', Url]);
     exit;
    end;
    if Resp.ContentStream = nil then
    begin
     WriteIn(['OSM HTTP empty stream ', Url]);
     exit;
    end;
    MS := TMemoryStream.Create;
    MS.CopyFrom(Resp.ContentStream, 0);
    MS.Position := 0;
    WriteIn(['OSM bytes received ', MS.Size, ' ', Url]);
    if MS.Size <= 0 then
    begin
     WriteIn(['OSM empty bytes ', Url]);
     exit;
    end;
    Img := TSkImage.MakeFromEncodedStream(MS);
    if Img = nil then
    begin
     WriteIn(['OSM decode failed ', Url]);
     exit;
    end;
    WriteIn(['OSM decoded ', Url]);
    if FCachedTiles then
    begin
     try
      EnsureOsmTileCacheDir(Tile.Z, Tile.X);
      MS.SaveToFile(FileName);
     except
     end;
    end;
    WriteIn(['Before TThread.Queue ', Tile.Key, ' FOsmClosing=', FOsmClosing, ' RequestId=', RequestId, ' FOsmRequestId=', FOsmRequestId]);
    TThread.Queue(nil,
     procedure
     begin
      WriteIn(['TThread.Queue start ', Tile.Key]);
      try
       if FOsmClosing then
       begin
        WriteIn(['TThread.Queue FOsmClosing true ', Tile.Key]);
        exit;
       end;
       if RequestId <> FOsmRequestId then
       begin
        WriteIn(['TThread.Queue RequestId mismatch ', Tile.Key, ' RequestId=', RequestId, ' FOsmRequestId=', FOsmRequestId]);
        exit;
       end;
       WriteIn(['TThread.Queue EnsureOsm ', Tile.Key]);
       EnsureOsm;
       WriteIn(['TThread.Queue AddOrSetValue ', Tile.Key]);
       FOsmTiles.AddOrSetValue(Tile.Key, Img);
       WriteIn(['OSM cached ', Tile.Key, ' SkPainter=', SkPainter <> nil]);
       if SkPainter <> nil then
       begin
        if not FOsmRedrawPending then
        begin
         FOsmRedrawPending := True;
         WriteIn(['Before SkPainter.Redraw ', Tile.Key]);
         try
          SkPainter.Redraw;
          WriteIn(['After SkPainter.Redraw ', Tile.Key]);
         except on E: Exception do
          WriteIn(['SkPainter.Redraw exception ', E.ClassName, ' ', E.Message]);
         end;
         FOsmRedrawPending := False;
        end
         else
         WriteIn(['SkPainter.Redraw skipped (pending) ', Tile.Key]);
       end;
       WriteIn(['TThread.Queue end ', Tile.Key]);
      except on E: Exception do
       WriteIn(['OSM Queue exception ', E.ClassName, ' ', E.Message]);
      end;
     end);
   except on E: Exception do
    WriteIn(['OSM HTTP exception ', E.ClassName, ' ', E.Message]);
   end;
   WriteIn(['DownloadTileAsync task end ', Tile.Key]);
   if MS <> nil then
    MS.Free;
   if Client <> nil then
    Client.Free;
   WriteIn(['EndOfProc==================== ', Tile.Key]);
  end);
end;

procedure TMainFormOSM.RequestOsmTilesFromActiveRect;
var
  LonMin, LatMin, LonMax, LatMax: Double;
  X0, X1, Y0, Y1, X, Y: Integer;
  Tile: TOsmTile;
  I: Integer;
  LatCenter: Double;
  NewZoom: Integer;
  DenomAuto: Double;
begin
 if FOsmClosing then exit;
 EnsureOsm;
 if (Selector <> nil) and (Selector.ActiveRect <> nil) and Selector.ActiveRect.isRect then
 begin
  FOsmLastReqXMin := Selector.ActiveRect.XMin;
  FOsmLastReqYMin := Selector.ActiveRect.YMin;
  FOsmLastReqXMax := Selector.ActiveRect.XMax;
  FOsmLastReqYMax := Selector.ActiveRect.YMax;
  FOsmLastReqValid := True;
 end;
 Inc(FOsmRequestId);
 ClearOsm;
 if Selector <> nil then
  WriteIn(['OSM ActiveRect ', Selector.ActiveRect.XMin, ' ', Selector.ActiveRect.YMin,
   '  ', Selector.ActiveRect.XMax, ' ', Selector.ActiveRect.YMax]);
 if not TryGetOsmBboxWgs84FromActiveRect(LonMin, LatMin, LonMax, LatMax) then
 begin
  WriteIn(['OSM bbox transform failed']);
  exit;
 end;
 if not FOsmScaleDenomManual then
  if TryEstimateScaleDenom(DenomAuto) then
   FOsmScaleDenom := DenomAuto;
 LatCenter := (LatMin + LatMax) * 0.5;
 if FOsmScaleDenom > 0 then
 begin
  NewZoom := ScaleDenomToZoom(FOsmScaleDenom, LatCenter);
  WriteIn(['OSM scale 1:', FOsmScaleDenom, ' lat=', LatCenter, ' zoom=', NewZoom]);
  if NewZoom <> FOsmZoom then
   FOsmZoom := NewZoom;
 end;
 if lMas <> nil then
  lMas.Text := IntToStr(FOsmZoom);
 WriteIn(['OSM bbox WGS84 lon/lat ', LonMin, ' ', LatMin, '  ', LonMax, ' ', LatMax]);
 X0 := LonToTileX(LonMin, FOsmZoom);
 X1 := LonToTileX(LonMax, FOsmZoom);
 Y0 := LatToTileY(LatMax, FOsmZoom);
 Y1 := LatToTileY(LatMin, FOsmZoom);
 if X0 > X1 then begin I := X0; X0 := X1; X1 := I; end;
 if Y0 > Y1 then begin I := Y0; Y0 := Y1; Y1 := I; end;
 X0 := Max(0, X0 - 1);
 Y0 := Max(0, Y0 - 1);
 X1 := X1 + 1;
 Y1 := Y1 + 1;
 WriteIn(['OSM tiles z=', FOsmZoom, ' x=', X0, '..', X1, ' y=', Y0, '..', Y1]);
 SetLength(FOsmTileList, 0);
 for X := X0 to X1 do
  for Y := Y0 to Y1 do
  begin
   Tile.Z := FOsmZoom;
   Tile.X := X;
   Tile.Y := Y;
   Tile.Key := Format('%d/%d/%d', [Tile.Z, Tile.X, Tile.Y]);
   SetLength(FOsmTileList, Length(FOsmTileList) + 1);
   FOsmTileList[High(FOsmTileList)] := Tile;
  end;
 FOsmLonMin := LonMin;
 FOsmLatMin := LatMin;
 FOsmLonMax := LonMax;
 FOsmLatMax := LatMax;
 for I := 0 to Length(FOsmTileList) - 1 do
  DownloadTileAsync(FOsmTileList[I], FOsmRequestId);
 if SkPainter <> nil then
  SkPainter.Redraw;
end;

procedure TMainFormOSM.DrawOsmTiles(const ACanvas: ISkCanvas; const Rect: TRectF);
var
 I: Integer;
 Tile: TOsmTile;
 Img: ISkImage;
 Px, Py: Double;
 Dst: TRectF;
 Src: TRectF;
begin
 if not FOsmHasView then
  BuildOsmView(FOsmLonMin, FOsmLatMin, FOsmLonMax, FOsmLatMax, Rect);
 for I := 0 to Length(FOsmTileList) - 1 do
 begin
  Tile := FOsmTileList[I];
  if not FOsmTiles.TryGetValue(Tile.Key, Img) then
   Continue;
  Src := TRectF.Create(0, 0, Img.Width, Img.Height);
  Px := Tile.X * 256.0;
  Py := Tile.Y * 256.0;
  Dst.Left := Rect.Left + (Px - FOsmOriginPx) * FOsmScale;
  Dst.Top := Rect.Top + (Py - FOsmOriginPy) * FOsmScale;
  Dst.Right := Dst.Left + 256.0 * FOsmScale;
  Dst.Bottom := Dst.Top + 256.0 * FOsmScale;
  ACanvas.DrawImageRect(Img, Src, Dst, TSkSamplingOptions.High);
 end;
end;
//
procedure TMainFormOSM.OpenGmfFileSkia(const LocalPath: string);
begin
 inherited;
 RequestOsmTilesFromActiveRect;
end;
//
procedure TMainFormOSM.PaintBefore(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
 EnsureOsm;
 if FOsmClosing then exit;
 MaybeScheduleOsmRequest;
 if Length(FOsmTileList) = 0 then exit;
 if (not FOsmPaintLogged) and (FOsmTiles <> nil) and (FOsmTiles.Count > 0) then
 begin
  FOsmPaintLogged := True;
  WriteIn(['OSM PaintBefore tiles=', Length(FOsmTileList), ' cached=', FOsmTiles.Count]);
 end;
 DrawOsmTiles(ACanvas, Rect);
end;
//
procedure TMainFormOSM.PaintAfter(const ACanvas: ISkCanvas; const Rect: TRectF);
begin
 EnsureOsm;
 if FOsmClosing then exit;
 if Length(FOsmTileList) = 0 then exit;
 if (not FOsmPaintLogged) and (FOsmTiles <> nil) and (FOsmTiles.Count > 0) then
 begin
  FOsmPaintLogged := True;
  WriteIn(['OSM PaintAfter tiles=', Length(FOsmTileList), ' cached=', FOsmTiles.Count]);
 end;
 DrawOsmTiles(ACanvas, Rect);
end;

end.
