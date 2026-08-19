unit GPKGReader;

interface

uses System.SysUtils, System.Classes, System.Generics.Collections,
     System.IOUtils,
     FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
     FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
     FireDAC.Stan.Param,
     FireDAC.DatS,
     FireDAC.DApt.Intf, FireDAC.DApt,
     FireDAC.Phys.Intf, FireDAC.Phys, FireDAC.Phys.SQLite,
     FireDAC.Phys.SQLiteDef, FireDAC.UI.Intf, FireDAC.Comp.Client,
     FireDAC.Comp.DataSet

{$IFDEF ANDROID}
     , Posix.Dlfcn
{$ENDIF}

{$IFDEF MSWINDOWS}
     , Winapi.Windows
{$ENDIF}
     ;

type
  TGPKGLayer = record
   TableName: string;
   DataType: string;
   Identifier: string;
   Description: string;
   LastChange: string;
   MinX, MinY, MaxX, MaxY: Double;
   GeometryColumn: string;
   GeometryType: string;
   SrsId: Integer;
   HasZ: Integer;
   HasM: Integer;
   SrsOrganization: string;
   SrsOrganizationCoordSysId: Integer;
   SrsDefinition: string;
  end;

  TGPKGReader = class
  private
   FConnection: TFDConnection;
   FDriverLink: TFDPhysSQLiteDriverLink;
   FLayers: TArray<TGPKGLayer>;
   function ParseLayers: Boolean;
  //
  public
   constructor Create(const AFileName: string);
   destructor Destroy; override;
   function Open: Boolean;
   procedure Close;
   function GetLayerCount: Integer;
   function GetLayer(AIndex: Integer): TGPKGLayer;
   function GetTableNames: TStringList;
   function GetTableStructure(const ATableName: string): TStringList;
   function GetFeatureCount(const ATableName: string): Int64;
   function GetFeatureSample(const ATableName: string; ALimit: Integer): TStringList;
   function GetFeatureCoordSample(const ATableName: string; ALimit: Integer): TStringList;
   function GetTableForeignKeys(const ATableName: string): TStringList;
   function GetChildTablesReferencing(const AParentTableName: string): TStringList;
   function DumpLayerInfo(const ATableName: string; ASampleLimit: Integer): TStringList;
   function DumpLayerCoordsSrs(const ATableName: string): TStringList;
  end;

implementation

constructor TGPKGReader.Create(const AFileName: string);
var DllPath: string;
{$IFDEF MSWINDOWS}
    DllSize: Int64;
    DosHdr: TImageDosHeader;
    NtSignature: DWORD;
    FileHdr: TImageFileHeader;
    Machine: Word;
    Fs: TFileStream;
{$ENDIF}
{$IFDEF ANDROID}
    H: THandle;
    LibName: string;
{$ENDIF}
begin
 inherited Create;
 FDriverLink := TFDPhysSQLiteDriverLink.Create(nil);
{$IFDEF ANDROID}
 H := 0;
 LibName := '';
  H := dlopen(MarshaledAString(AnsiString('libsqliteX.so')), RTLD_LAZY);
 if H <> 0 then dlclose(H);
 if LibName <> '' then
  FDriverLink.VendorLib := LibName
 else
  raise Exception.Create('sqlite vendor library not found on Android (tried libsqlite3.so, libsqliteX.so, libsqlite.so, sqlite3). Add libsqlite3.so/libsqliteX.so to Deployment for each ABI.');
{$ENDIF}
{$IFDEF MSWINDOWS}
 DllPath := ExtractFilePath(ParamStr(0)) + 'sqlite3.dll';
 if FileExists(DllPath) then
  begin
   try
    DllSize := TFile.GetSize(DllPath);
   except
    DllSize := -1;
   end;
   Fs := TFileStream.Create(DllPath, fmOpenRead or fmShareDenyNone);
   try
    if Fs.Read(DosHdr, SizeOf(DosHdr)) <> SizeOf(DosHdr) then
     raise Exception.Create('sqlite3.dll: cannot read DOS header: ' + DllPath + ' size=' + IntToStr(DllSize));
    if DosHdr.e_magic <> IMAGE_DOS_SIGNATURE then
     raise Exception.Create('sqlite3.dll: invalid MZ signature: ' + DllPath + ' size=' + IntToStr(DllSize));
    if (DosHdr._lfanew <= 0) or (DosHdr._lfanew > Fs.Size - 256) then
     raise Exception.Create('sqlite3.dll: invalid PE header offset: ' + DllPath + ' size=' + IntToStr(DllSize));
    Fs.Position := DosHdr._lfanew;
    if Fs.Read(NtSignature, SizeOf(NtSignature)) <> SizeOf(NtSignature) then
     raise Exception.Create('sqlite3.dll: cannot read PE signature: ' + DllPath + ' size=' + IntToStr(DllSize));
    if NtSignature <> IMAGE_NT_SIGNATURE then
     raise Exception.Create('sqlite3.dll: invalid PE signature: ' + DllPath + ' size=' + IntToStr(DllSize));
    if Fs.Read(FileHdr, SizeOf(FileHdr)) <> SizeOf(FileHdr) then
     raise Exception.Create('sqlite3.dll: cannot read PE file header: ' + DllPath + ' size=' + IntToStr(DllSize));
    Machine := FileHdr.Machine;
{$IFDEF WIN64}
    if Machine <> IMAGE_FILE_MACHINE_AMD64 then
     raise Exception.Create('sqlite3.dll must be x64 for Win64: ' + DllPath);
{$ELSE}
    if Machine <> IMAGE_FILE_MACHINE_I386 then
     raise Exception.Create('sqlite3.dll must be x86 for Win32: ' + DllPath);
{$ENDIF}
   finally
    Fs.Free;
   end;
   FDriverLink.VendorLib := DllPath;
  end;
{$ENDIF}
 FConnection := TFDConnection.Create(nil);
 FConnection.Params.Clear;
 FConnection.Params.DriverID := 'SQLite';
 FConnection.Params.Database := AFileName;
 FConnection.LoginPrompt := False;
end;

destructor TGPKGReader.Destroy;
begin
 Close;
 FreeAndNil(FConnection);
 FreeAndNil(FDriverLink);
 inherited;
end;

function TGPKGReader.Open: Boolean;
begin
 Result := False;
 if FConnection = nil then exit;
 try
  if not FConnection.Connected then
   FConnection.Connected := True;
  Result := ParseLayers;
 except
  Result := False;
 end;
end;

procedure TGPKGReader.Close;
begin
 if (FConnection <> nil) and FConnection.Connected then
  FConnection.Connected := False;
end;

function TGPKGReader.ParseLayers: Boolean;
var Query: TFDQuery;
    Layers: TList<TGPKGLayer>;
    Layer: TGPKGLayer;
begin
 Result := False;
 SetLength(FLayers, 0);
 if (FConnection = nil) or (not FConnection.Connected) then exit;
//
 Layers := TList<TGPKGLayer>.Create;
 try
  Query := TFDQuery.Create(nil);
  try
   Query.Connection := FConnection;
   Query.SQL.Text :=
    'select c.table_name, c.data_type, c.identifier, c.description, c.last_change, c.min_x, c.min_y, c.max_x, c.max_y, ' +
    'g.column_name as geom_column, g.geometry_type_name as geom_type, ' +
    'coalesce(g.srs_id, t.srs_id, -1) as srs_id, g.z as has_z, g.m as has_m, ' +
    's.organization as srs_organization, s.organization_coordsys_id as srs_organization_coordsys_id, s.definition as srs_definition ' +
    'from gpkg_contents c ' +
    'left join gpkg_geometry_columns g on g.table_name = c.table_name ' +
    'left join gpkg_tile_matrix_set t on t.table_name = c.table_name ' +
    'left join gpkg_spatial_ref_sys s on s.srs_id = coalesce(g.srs_id, t.srs_id)';
   Query.Open;
   while not Query.Eof do begin
    Layer.TableName := Query.FieldByName('table_name').AsString;
    Layer.DataType := Query.FieldByName('data_type').AsString;
    Layer.Identifier := Query.FieldByName('identifier').AsString;
    Layer.Description := Query.FieldByName('description').AsString;
    Layer.LastChange := Query.FieldByName('last_change').AsString;
    Layer.MinX := Query.FieldByName('min_x').AsFloat;
    Layer.MinY := Query.FieldByName('min_y').AsFloat;
    Layer.MaxX := Query.FieldByName('max_x').AsFloat;
    Layer.MaxY := Query.FieldByName('max_y').AsFloat;
    Layer.GeometryColumn := Query.FieldByName('geom_column').AsString;
    Layer.GeometryType := Query.FieldByName('geom_type').AsString;
    Layer.SrsId := Query.FieldByName('srs_id').AsInteger;
    Layer.HasZ := Query.FieldByName('has_z').AsInteger;
    Layer.HasM := Query.FieldByName('has_m').AsInteger;
    try
     Layer.SrsOrganization := Query.FieldByName('srs_organization').AsString;
    except
     Layer.SrsOrganization := '';
    end;
    try
     Layer.SrsOrganizationCoordSysId := Query.FieldByName('srs_organization_coordsys_id').AsInteger;
    except
     Layer.SrsOrganizationCoordSysId := -1;
    end;
    try
     Layer.SrsDefinition := Query.FieldByName('srs_definition').AsString;
    except
     Layer.SrsDefinition := '';
    end;
    Layers.Add(Layer);
    Query.Next;
   end;
   FLayers := Layers.ToArray;
   Result := True;
  finally
   Query.Free;
  end;
 finally
  Layers.Free;
 end;
end;

function TGPKGReader.GetLayerCount: Integer;
begin
 Result := Length(FLayers);
end;

function TGPKGReader.GetLayer(AIndex: Integer): TGPKGLayer;
begin
 if (AIndex < 0) or (AIndex >= Length(FLayers)) then
  raise ERangeError.Create('Layer index out of range');
 Result := FLayers[AIndex];
end;

function TGPKGReader.GetTableNames: TStringList;
var Query: TFDQuery;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
//
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text := 'select name from sqlite_master where type="table" order by name';
  Query.Open;
  while not Query.Eof do begin
   Result.Add(Query.Fields[0].AsString);
   Query.Next;
  end;
 finally
  Query.Free;
 end;
end;

function TGPKGReader.GetTableStructure(const ATableName: string): TStringList;
var Query: TFDQuery;
    Str: string;
    ColName, ColType: string;
    NotNull, Pk: Integer;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
//
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text := 'pragma table_info(' + ATableName + ')';
  Query.Open;
  while not Query.Eof do begin
   ColName := Query.FieldByName('name').AsString;
   ColType := Query.FieldByName('type').AsString;
   NotNull := Query.FieldByName('notnull').AsInteger;
   Pk := Query.FieldByName('pk').AsInteger;
   Str := ColName + ': ' + ColType + ' (notnull=' + IntToStr(NotNull) + ', pk=' + IntToStr(Pk) + ')';
   Result.Add(Str);
   Query.Next;
  end;
 finally
  Query.Free;
 end;
end;

function TGPKGReader.GetFeatureCount(const ATableName: string): Int64;
var Query: TFDQuery;
begin
 Result := 0;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if ATableName = '' then exit;
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text := 'select count(*) as cnt from ' + ATableName;
  Query.Open;
  Result := Query.FieldByName('cnt').AsLargeInt;
 finally
  Query.Free;
 end;
end;

function TGPKGReader.GetFeatureSample(const ATableName: string; ALimit: Integer): TStringList;
type
 TGpkgGeomInfo = record
  HasGpkgHeader: Boolean;
  IsPlainWkb: Boolean;
  WkbType: Cardinal;
 end;
 function ReadUInt32LE(const B: TBytes; const Ofs: Integer): Cardinal;
 begin
  Result := Cardinal(B[Ofs]) or (Cardinal(B[Ofs + 1]) shl 8) or (Cardinal(B[Ofs + 2]) shl 16) or (Cardinal(B[Ofs + 3]) shl 24);
 end;
 function ParseGeom(const Blob: TBytes): TGpkgGeomInfo;
 var ByteOrder: Byte;
     Ofs: Integer;
 begin
  Result.HasGpkgHeader := False;
  Result.IsPlainWkb := False;
  Result.WkbType := 0;
  if Length(Blob) < 5 then exit;
  if (Blob[0] = Ord('G')) and (Blob[1] = Ord('P')) then
  begin
   Result.HasGpkgHeader := True;
   Ofs := 8;
   if Length(Blob) <= (Ofs + 5) then exit;
   ByteOrder := Blob[Ofs];
   if ByteOrder = 0 then
    Result.WkbType := (Cardinal(Blob[Ofs + 4]) or (Cardinal(Blob[Ofs + 3]) shl 8) or (Cardinal(Blob[Ofs + 2]) shl 16) or (Cardinal(Blob[Ofs + 1]) shl 24))
   else
    Result.WkbType := ReadUInt32LE(Blob, Ofs + 1);
   exit;
  end;
  if (Blob[0] = 0) or (Blob[0] = 1) then
  begin
   ByteOrder := Blob[0];
   if ByteOrder = 0 then
    Result.WkbType := (Cardinal(Blob[4]) or (Cardinal(Blob[3]) shl 8) or (Cardinal(Blob[2]) shl 16) or (Cardinal(Blob[1]) shl 24))
   else
    Result.WkbType := ReadUInt32LE(Blob, 1);
   Result.IsPlainWkb := True;
  end;
 end;
var Query: TFDQuery;
    Layer: TGPKGLayer;
    I: Integer;
    ColGeom: string;
    Blob: TBytes;
    Info: TGpkgGeomInfo;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if ATableName = '' then exit;
 if ALimit <= 0 then ALimit := 10;
 ColGeom := '';
 for I := 0 to GetLayerCount - 1 do begin
  Layer := GetLayer(I);
  if SameText(Layer.TableName, ATableName) then
  begin
   ColGeom := Layer.GeometryColumn;
   break;
  end;
 end;
 if ColGeom = '' then
 begin
  Result.Add('no geometry column for table: ' + ATableName);
  exit;
 end;
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text := 'select ' + ColGeom + ' as geom from ' + ATableName + ' limit ' + IntToStr(ALimit);
  Query.Open;
  I := 0;
  while not Query.Eof do begin
   try
    Blob := Query.FieldByName('geom').AsBytes;
   except
    SetLength(Blob, 0);
   end;
   if (Length(Blob) > 0) and ((Blob[0] = Ord('{')) or (Blob[0] = Ord('['))) then
   begin
    Result.Add('row ' + IntToStr(I) + ': geojson? bytes=' + IntToStr(Length(Blob)) + ' head=' + Copy(TEncoding.UTF8.GetString(Blob), 1, 200));
   end
   else
   begin
    Info := ParseGeom(Blob);
    if Info.HasGpkgHeader then
     Result.Add('row ' + IntToStr(I) + ': gpkg bytes=' + IntToStr(Length(Blob)) + ' wkb=' + IntToStr(Integer(Info.WkbType)))
    else if Info.IsPlainWkb then
     Result.Add('row ' + IntToStr(I) + ': wkb bytes=' + IntToStr(Length(Blob)) + ' wkb=' + IntToStr(Integer(Info.WkbType)))
    else
     Result.Add('row ' + IntToStr(I) + ': unknown bytes=' + IntToStr(Length(Blob)));
   end;
   Inc(I);
   Query.Next;
  end;
 finally
  Query.Free;
 end;
end;

function TGPKGReader.GetTableForeignKeys(const ATableName: string): TStringList;
var Query: TFDQuery;
    FromCol, ToCol, RefTable: string;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if ATableName = '' then exit;
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text := 'pragma foreign_key_list(' + ATableName + ')';
  Query.Open;
  while not Query.Eof do begin
   try
    RefTable := Query.FieldByName('table').AsString;
   except
    RefTable := '';
   end;
   try
    FromCol := Query.FieldByName('from').AsString;
   except
    FromCol := '';
   end;
   try
    ToCol := Query.FieldByName('to').AsString;
   except
    ToCol := '';
   end;
   if RefTable <> '' then Result.Add(ATableName + '.' + FromCol + ' -> ' + RefTable + '.' + ToCol);
   Query.Next;
  end;
 finally
  Query.Free;
 end;
end;

function TGPKGReader.GetFeatureCoordSample(const ATableName: string; ALimit: Integer): TStringList;
type
 TByteOrder = (boBE, boLE);
 function ByteHex(const B: Byte): string;
 const Hex: array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
 begin
  Result := Hex[B shr 4] + Hex[B and $F];
 end;
 function HeadHex(const B: TBytes; const AOfs, ACount: Integer): string;
 var I, N: Integer;
 begin
  Result := '';
  if ACount <= 0 then exit;
  N := Length(B) - AOfs;
  if N <= 0 then exit;
  if N > ACount then N := ACount;
  for I := 0 to N - 1 do
  begin
   if Result <> '' then Result := Result + ' ';
   Result := Result + ByteHex(B[AOfs + I]);
  end;
 end;
 function ReadUInt32(const B: TBytes; var Ofs: Integer; const Order: TByteOrder): Cardinal;
 begin
  Result := 0;
  if (Ofs + 4) > Length(B) then exit;
  if Order = boLE then
   Result := Cardinal(B[Ofs]) or (Cardinal(B[Ofs + 1]) shl 8) or (Cardinal(B[Ofs + 2]) shl 16) or (Cardinal(B[Ofs + 3]) shl 24)
  else
   Result := Cardinal(B[Ofs + 3]) or (Cardinal(B[Ofs + 2]) shl 8) or (Cardinal(B[Ofs + 1]) shl 16) or (Cardinal(B[Ofs]) shl 24);
  Inc(Ofs, 4);
 end;
 function ReadDouble(const B: TBytes; var Ofs: Integer; const Order: TByteOrder): Double;
 var U: UInt64;
 begin
  Result := 0;
  if (Ofs + 8) > Length(B) then exit;
  if Order = boLE then
   U := UInt64(B[Ofs]) or (UInt64(B[Ofs + 1]) shl 8) or (UInt64(B[Ofs + 2]) shl 16) or (UInt64(B[Ofs + 3]) shl 24) or
        (UInt64(B[Ofs + 4]) shl 32) or (UInt64(B[Ofs + 5]) shl 40) or (UInt64(B[Ofs + 6]) shl 48) or (UInt64(B[Ofs + 7]) shl 56)
  else
   U := UInt64(B[Ofs + 7]) or (UInt64(B[Ofs + 6]) shl 8) or (UInt64(B[Ofs + 5]) shl 16) or (UInt64(B[Ofs + 4]) shl 24) or
        (UInt64(B[Ofs + 3]) shl 32) or (UInt64(B[Ofs + 2]) shl 40) or (UInt64(B[Ofs + 1]) shl 48) or (UInt64(B[Ofs]) shl 56);
  Move(U, Result, SizeOf(Result));
  Inc(Ofs, 8);
 end;
 function ReadByteOrder(const B: TBytes; var Ofs: Integer; out Order: TByteOrder): Boolean;
 var V: Byte;
 begin
  Result := False;
  if (Ofs + 1) > Length(B) then exit;
  V := B[Ofs];
  Inc(Ofs);
  if V = 0 then Order := boBE
  else if V = 1 then Order := boLE
  else exit;
  Result := True;
 end;
 function WkbDimFromType(const WkbType: Cardinal): Integer;
 var Base: Cardinal;
 begin
  Base := WkbType mod 1000;
  if WkbType >= 3000 then Result := 4
  else if WkbType >= 2000 then Result := 3
  else if WkbType >= 1000 then Result := 3
  else Result := 2;
  if Base = 0 then Result := 2;
 end;
 function SkipExtraDims(const B: TBytes; var Ofs: Integer; const Order: TByteOrder; const Dim: Integer): Boolean;
 var I: Integer;
 begin
  Result := True;
  for I := 3 to Dim do begin
   ReadDouble(B, Ofs, Order);
   if Ofs > Length(B) then
   begin
    Result := False;
    exit;
   end;
  end;
 end;
 function ReadFirstPointFromWkb(const B: TBytes; var Ofs: Integer; out X, Y: Double; out Kind: string): Boolean;
 var Order: TByteOrder;
     WkbType, BaseType, Dim: Cardinal;
     Cnt, RingCnt, PtCnt: Cardinal;
     TmpOfs: Integer;
 begin
  Result := False;
  Kind := '';
  X := 0;
  Y := 0;
  if not ReadByteOrder(B, Ofs, Order) then exit;
  WkbType := ReadUInt32(B, Ofs, Order);
  BaseType := WkbType mod 1000;
  Dim := WkbDimFromType(WkbType);
  if BaseType = 1 then
  begin
   Kind := 'POINT';
   X := ReadDouble(B, Ofs, Order);
   Y := ReadDouble(B, Ofs, Order);
   if not SkipExtraDims(B, Ofs, Order, Dim) then exit;
   Result := True;
   exit;
  end;
  if BaseType = 2 then
  begin
   Kind := 'LINESTRING';
   PtCnt := ReadUInt32(B, Ofs, Order);
   if PtCnt = 0 then exit;
   X := ReadDouble(B, Ofs, Order);
   Y := ReadDouble(B, Ofs, Order);
   if not SkipExtraDims(B, Ofs, Order, Dim) then exit;
   Result := True;
   exit;
  end;
  if BaseType = 3 then
  begin
   Kind := 'POLYGON';
   RingCnt := ReadUInt32(B, Ofs, Order);
   if RingCnt = 0 then exit;
   PtCnt := ReadUInt32(B, Ofs, Order);
   if PtCnt = 0 then exit;
   X := ReadDouble(B, Ofs, Order);
   Y := ReadDouble(B, Ofs, Order);
   if not SkipExtraDims(B, Ofs, Order, Dim) then exit;
   Result := True;
   exit;
  end;
  if (BaseType = 4) or (BaseType = 5) or (BaseType = 6) then
  begin
   if BaseType = 4 then Kind := 'MULTIPOINT'
   else if BaseType = 5 then Kind := 'MULTILINESTRING'
   else Kind := 'MULTIPOLYGON';
   Cnt := ReadUInt32(B, Ofs, Order);
   if Cnt = 0 then exit;
   TmpOfs := Ofs;
   if ReadFirstPointFromWkb(B, TmpOfs, X, Y, Kind) then
   begin
    Result := True;
    exit;
   end;
   exit;
  end;
 end;
 function GetWkbOffsetFromGpkg(const Blob: TBytes; out WkbOfs: Integer): Boolean;
 var Flags: Byte;
     EType: Integer;
 begin
  Result := False;
  WkbOfs := 0;
  if Length(Blob) < 8 then exit;
  if (Blob[0] <> Ord('G')) or (Blob[1] <> Ord('P')) then exit;
  Flags := Blob[3];
  EType := (Flags shr 1) and 7;
  WkbOfs := 8;
  case EType of
   0: ;
   1: Inc(WkbOfs, 32);
   2, 3: Inc(WkbOfs, 48);
   4: Inc(WkbOfs, 64);
  else
   exit;
  end;
  if WkbOfs >= Length(Blob) then exit;
  Result := True;
 end;
 function IsPlausibleWkbType(const T: Cardinal): Boolean;
 var Base: Cardinal;
 begin
  Base := T mod 1000;
  Result := (Base >= 1) and (Base <= 7);
 end;
 function TryScanWkbStart(const Blob: TBytes; out StartOfs: Integer): Boolean;
 var I, Ofs: Integer;
     Order: TByteOrder;
     T: Cardinal;
 begin
  Result := False;
  StartOfs := -1;
  for I := 0 to Length(Blob) - 6 do
  begin
   if (Blob[I] <> 0) and (Blob[I] <> 1) then continue;
   if Blob[I] = 0 then Order := boBE else Order := boLE;
   Ofs := I + 1;
   T := ReadUInt32(Blob, Ofs, Order);
   if IsPlausibleWkbType(T) then
   begin
    StartOfs := I;
    Result := True;
    exit;
   end;
  end;
 end;
var Query: TFDQuery;
    Layer: TGPKGLayer;
    I: Integer;
    ColGeom: string;
    Blob: TBytes;
    WkbOfs, Ofs: Integer;
    ScanOfs: Integer;
    X, Y: Double;
    Kind: string;
    Tp, Hx: string;
    Ln: Integer;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if ATableName = '' then exit;
 if ALimit <= 0 then ALimit := 10;
 ColGeom := '';
 for I := 0 to GetLayerCount - 1 do begin
  Layer := GetLayer(I);
  if SameText(Layer.TableName, ATableName) then
  begin
   ColGeom := Layer.GeometryColumn;
   break;
  end;
 end;
 if ColGeom = '' then
 begin
  Result.Add('no geometry column for table: ' + ATableName);
  exit;
 end;
 Query := TFDQuery.Create(nil);
 try
  Query.Connection := FConnection;
  Query.SQL.Text :=
   'select typeof(' + ColGeom + ') as tp, length(' + ColGeom + ') as ln, ' +
   'hex(substr(cast(' + ColGeom + ' as blob), 1, 32)) as hx, ' +
   'cast(' + ColGeom + ' as blob) as geom ' +
   'from ' + ATableName + ' limit ' + IntToStr(ALimit);
  Query.Open;
  I := 0;
  while not Query.Eof do begin
   try
    Tp := Query.FieldByName('tp').AsString;
   except
    Tp := '';
   end;
   try
    Ln := Query.FieldByName('ln').AsInteger;
   except
    Ln := -1;
   end;
   try
    Hx := Query.FieldByName('hx').AsString;
   except
    Hx := '';
   end;
   try
    Blob := Query.FieldByName('geom').AsBytes;
   except
    SetLength(Blob, 0);
   end;
   if Length(Blob) = 0 then
    Result.Add('row ' + IntToStr(I) + ': empty tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx)
   else if (Blob[0] = Ord('{')) or (Blob[0] = Ord('[')) then
    Result.Add('row ' + IntToStr(I) + ': json tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx)
   else
   begin
    if GetWkbOffsetFromGpkg(Blob, WkbOfs) then Ofs := WkbOfs
    else Ofs := 0;
    if ReadFirstPointFromWkb(Blob, Ofs, X, Y, Kind) then
     Result.Add('row ' + IntToStr(I) + ': ' + Kind + ' x=' + Format('%.3f', [X]) + ' y=' + Format('%.3f', [Y]) + ' tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx)
    else
    begin
     if TryScanWkbStart(Blob, ScanOfs) then
     begin
      Ofs := ScanOfs;
      if ReadFirstPointFromWkb(Blob, Ofs, X, Y, Kind) then
       Result.Add('row ' + IntToStr(I) + ': scan ' + Kind + ' x=' + Format('%.3f', [X]) + ' y=' + Format('%.3f', [Y]) + ' tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx)
      else
       Result.Add('row ' + IntToStr(I) + ': cannot parse tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx + ' bytes=' + IntToStr(Length(Blob)) + ' head=' + HeadHex(Blob, 0, 24) + ' wkbOfs=' + IntToStr(WkbOfs) + ' at=' + IntToStr(ScanOfs) + ' headAt=' + HeadHex(Blob, ScanOfs, 12));
     end
     else
      Result.Add('row ' + IntToStr(I) + ': cannot parse tp=' + Tp + ' ln=' + IntToStr(Ln) + ' hx=' + Hx + ' bytes=' + IntToStr(Length(Blob)) + ' head=' + HeadHex(Blob, 0, 24) + ' wkbOfs=' + IntToStr(WkbOfs) + ' headAt=' + HeadHex(Blob, WkbOfs, 12));
    end;
   end;
   Inc(I);
   Query.Next;
  end;
 finally
  Query.Free;
 end;
end;


function TGPKGReader.GetChildTablesReferencing(const AParentTableName: string): TStringList;
var Tables: TStringList;
    Tbl, RefTable: string;
    Query: TFDQuery;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if AParentTableName = '' then exit;
 Tables := GetTableNames;
 try
  Query := TFDQuery.Create(nil);
  try
   Query.Connection := FConnection;
   for Tbl in Tables do begin
    Query.Close;
    Query.SQL.Text := 'pragma foreign_key_list(' + Tbl + ')';
    try
     Query.Open;
    except
     continue;
    end;
    while not Query.Eof do begin
     try
      RefTable := Query.FieldByName('table').AsString;
     except
      RefTable := '';
     end;
     if SameText(RefTable, AParentTableName) then begin
      if Result.IndexOf(Tbl) < 0 then Result.Add(Tbl);
      break;
     end;
     Query.Next;
    end;
   end;
  finally
   Query.Free;
  end;
 finally
  Tables.Free;
 end;
end;

function TGPKGReader.DumpLayerInfo(const ATableName: string; ASampleLimit: Integer): TStringList;
var S: TStringList;
begin
 Result := TStringList.Create;
 if (FConnection = nil) or (not FConnection.Connected) then exit;
 if ATableName = '' then exit;
 Result.Add('table: ' + ATableName);
 Result.Add('features: ' + IntToStr(GetFeatureCount(ATableName)));
 S := GetTableStructure(ATableName);
 try
  Result.Add('columns:');
  Result.AddStrings(S);
 finally
  S.Free;
 end;
 S := GetTableForeignKeys(ATableName);
 try
  Result.Add('foreign_keys:');
  Result.AddStrings(S);
 finally
  S.Free;
 end;
 S := GetChildTablesReferencing(ATableName);
 try
  Result.Add('child_tables:');
  Result.AddStrings(S);
 finally
  S.Free;
 end;
 S := GetFeatureSample(ATableName, ASampleLimit);
 try
  Result.Add('geom_sample:');
  Result.AddStrings(S);
 finally
  S.Free;
 end;
end;

function TGPKGReader.DumpLayerCoordsSrs(const ATableName: string): TStringList;
var I: Integer;
    Layer: TGPKGLayer;
    Found: Boolean;
    S: TStringList;
begin
 Result := TStringList.Create;
 if ATableName = '' then exit;
 Found := False;
 for I := 0 to GetLayerCount - 1 do begin
  Layer := GetLayer(I);
  if SameText(Layer.TableName, ATableName) then begin
   Found := True;
   break;
  end;
 end;
 if not Found then begin
  Result.Add('table: ' + ATableName);
  Result.Add('layer not found in gpkg_contents');
  exit;
 end;
 Result.Add('table: ' + Layer.TableName);
 Result.Add('data_type: ' + Layer.DataType);
 Result.Add('identifier: ' + Layer.Identifier);
 Result.Add('bbox: ' + Format('%.6f,%.6f,%.6f,%.6f', [Layer.MinX, Layer.MinY, Layer.MaxX, Layer.MaxY]));
 Result.Add('geom: ' + Layer.GeometryColumn + ' | ' + Layer.GeometryType + ' | z=' + IntToStr(Layer.HasZ) + ' m=' + IntToStr(Layer.HasM));
 Result.Add('srs_id: ' + IntToStr(Layer.SrsId));
 Result.Add('srs_org: ' + Layer.SrsOrganization + ':' + IntToStr(Layer.SrsOrganizationCoordSysId));
 Result.Add('srs_def: ' + Layer.SrsDefinition);
 S := GetFeatureCoordSample(Layer.TableName, 1);
 try
  Result.Add('coord_sample:');
  Result.AddStrings(S);
 finally
  S.Free;
 end;
end;

end.
