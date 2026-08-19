unit ProjApi;

interface
uses System.SysUtils;

type
  projPJ = Pointer;

 function ProjCreate(const Def: AnsiString): projPJ;
 procedure ProjFree(P: projPJ);
 function ProjTransform(Src, Dst: projPJ; var X, Y, Z: Double): Integer;
 procedure ProjSetSearchPath(const ADir: string);
 function Msk50ToWgs84LonLat(const X, Y: Double; out LonDeg, LatDeg: Double): Boolean;
 function Wgs84LonLatToMsk50XY(const LonDeg, LatDeg: Double; out X, Y: Double): Boolean;
 function Wgs84LonLatToWebMercator(const LonDeg, LatDeg: Double; out MX, MY: Double): Boolean;

implementation
uses System.Math, FMX.Dialogs, System.IOUtils, Writer, newProcs
 {$IFDEF MSWINDOWS}
 , Winapi.Windows
 {$ENDIF}
 {$IFDEF ANDROID}
 , Androidapi.JNI
 {$ENDIF}
 ;

const
  {$IFDEF ANDROID}
  PROJ_DLL = 'libproj.so';
  {$ELSE}
  PROJ_DLL = 'proj.dll';
  {$ENDIF}
  {$IFDEF ANDROID}
  RTLD_NOW = 2;
  {$ENDIF}
  DEG_TO_RAD = 0.0174532925199432958;
  RAD_TO_DEG = 57.2957795130823208768;

type
  TPjInitPlus = function(Def: PAnsiChar): projPJ; cdecl;
  TPjFree = procedure(P: projPJ); cdecl;
  TPjTransform = function(Src, Dst: projPJ; PointCount: NativeInt; PointOffset: Integer;
   X, Y, Z: PDouble): Integer; cdecl;
  TPjSetSearchPath = procedure(Count: Integer; Path: PPAnsiChar); cdecl;

var ProjHandle: Pointer;
    pj_init_plus: TPjInitPlus;
    pj_free: TPjFree;
    pj_transform: TPjTransform;
    pj_set_searchpath: TPjSetSearchPath;

{$IFDEF ANDROID}
function dlopen(filename: PAnsiChar; flag: Integer): Pointer; cdecl; external 'libdl.so' name 'dlopen';
function dlsym(handle: Pointer; symbol: PAnsiChar): Pointer; cdecl; external 'libdl.so' name 'dlsym';
function dlerror: PAnsiChar; cdecl; external 'libdl.so' name 'dlerror';
{$ENDIF}

function GetProjProc(const AName: AnsiString): Pointer;
begin
 Result := nil;
 if ProjHandle = nil then exit;
 {$IFDEF MSWINDOWS}
  Result := GetProcAddress(HMODULE(ProjHandle), PAnsiChar(AName));
 {$ENDIF}
 {$IFDEF ANDROID}
 Result := dlsym(ProjHandle, PAnsiChar(AName));
 {$ENDIF}
end;

function EnsureProjLoaded: Boolean;
begin
 Result := Assigned(pj_init_plus) and Assigned(pj_free) and Assigned(pj_transform) and Assigned(pj_set_searchpath);
 if Result then exit;
 {$IFDEF MSWINDOWS}
 ProjHandle := Pointer(LoadLibrary(PChar(PROJ_DLL)));
 {$ENDIF}
 {$IFDEF ANDROID}
 WriteIn([TPath.GetDocumentsPath + '/libproj.so', FileExists(TPath.GetDocumentsPath + '/libproj.so')]);
 ProjHandle := dlopen(PAnsiChar(AnsiString('libproj.so')), RTLD_NOW);
 if ProjHandle = nil then
  WriteIn(['dlerror=', string(AnsiString(dlerror))]);
 {$ENDIF}
 WriteIn(['Handle = ', ProjHandle = nil]);
 if ProjHandle = nil then exit(False);
 pj_init_plus := GetProjProc('pj_init_plus');
 pj_free := GetProjProc('pj_free');
 pj_transform := GetProjProc('pj_transform');
 pj_set_searchpath := GetProjProc('pj_set_searchpath');
 WriteIn([Assigned(pj_init_plus), Assigned(pj_free), Assigned(pj_transform),Assigned( pj_set_searchpath)]);
 Result := Assigned(pj_init_plus) and Assigned(pj_free) and Assigned(pj_transform) and Assigned(pj_set_searchpath);
end;

function ProjCreate(const Def: AnsiString): projPJ;
begin
 Result := nil;
 if not EnsureProjLoaded then exit;
 Result := pj_init_plus(PAnsiChar(Def));
end;

function Wgs84LonLatToMsk50XY(const LonDeg, LatDeg: Double; out X, Y: Double): Boolean;
var Src, Dst: projPJ;
    XX, YY, ZZ: Double;
    Err: Integer;
begin
 Result := False;
 Src := nil;
 Dst := nil;
 try
  Src := ProjCreate('+proj=longlat +datum=WGS84 +no_defs');
  Dst := ProjCreate(
   '+proj=tmerc +lat_0=55.66666666667 +lon_0=37.5 +k=1 +x_0=16.098 +y_0=14.512 '
   + '+ellps=bessel +towgs84=316.151,78.924,589.650,-1.57273,2.69209,2.34693,8.4507 '
   + '+units=m +no_defs');
  if (Src = nil) or (Dst = nil) then exit;
  XX := LonDeg * DEG_TO_RAD;
  YY := LatDeg * DEG_TO_RAD;
  ZZ := 0;
  Err := ProjTransform(Src, Dst, XX, YY, ZZ);
  if Err <> 0 then exit;
  X := XX;
  Y := YY;
  Result := True;
 finally
  ProjFree(Dst);
  ProjFree(Src);
 end;
end;

procedure ProjFree(P: projPJ);
begin
 if not EnsureProjLoaded then exit;
 if P <> nil then
  pj_free(P);
end;

function ProjTransform(Src, Dst: projPJ; var X, Y, Z: Double): Integer;
begin
 Result := -1;
 if not EnsureProjLoaded then exit;
 Result := pj_transform(Src, Dst, 1, 0, @X, @Y, @Z);
end;

procedure ProjSetSearchPath(const ADir: string);
var P: PAnsiChar;
begin
 if not EnsureProjLoaded then exit;
 P := PAnsiChar(AnsiString(ADir));
 pj_set_searchpath(1, @P);
end;

function Msk50ToWgs84LonLat(const X, Y: Double; out LonDeg, LatDeg: Double): Boolean;
var Src, Dst: projPJ;
    XX, YY, ZZ: Double;
    Err: Integer;
begin
 Src := nil;
 Dst := nil;
 try
  Src := ProjCreate(
   '+proj=tmerc +lat_0=55.66666666667 +lon_0=37.5 +k=1 +x_0=16.098 +y_0=14.512 '
   + '+ellps=bessel +towgs84=316.151,78.924,589.650,-1.57273,2.69209,2.34693,8.4507 '
   + '+units=m +no_defs');
  Dst := ProjCreate('+proj=longlat +datum=WGS84 +no_defs');
  if (Src = nil) or (Dst = nil) then exit(False);
  XX := X;
  YY := Y;
  ZZ := 0;
  Err := ProjTransform(Src, Dst, XX, YY, ZZ);
  if Err <> 0 then exit(False);
  LonDeg := XX * RAD_TO_DEG;
  LatDeg := YY * RAD_TO_DEG;
  Result := True;
 finally
  ProjFree(Dst);
  ProjFree(Src);
 end;
end;

function Wgs84LonLatToWebMercator(const LonDeg, LatDeg: Double; out MX, MY: Double): Boolean;
var Src, Dst: projPJ;
    XX, YY, ZZ: Double;
    Err: Integer;
begin
 Src := nil;
 Dst := nil;
 try
  Src := ProjCreate('+proj=longlat +datum=WGS84 +no_defs');
  Dst := ProjCreate('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs');
  if (Src = nil) or (Dst = nil) then exit(False);
  XX := LonDeg * DEG_TO_RAD;
  YY := LatDeg * DEG_TO_RAD;
  ZZ := 0;
  Err := ProjTransform(Src, Dst, XX, YY, ZZ);
  if Err <> 0 then exit(False);
  MX := XX;
  MY := YY;
  Result := True;
 finally
  ProjFree(Dst);
  ProjFree(Src);
 end;
end;

end.
