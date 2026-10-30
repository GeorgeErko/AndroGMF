unit ogcMemStream;

interface uses Classes;

{TMemStream - поток в памяти с возможностью работы с внешним буфером (SetPointer)}

type
  TMemStream = class(TStream)
  private
   FMemory: Pointer;
   FSize, FPosition: NativeInt;
  protected
   procedure SetSize(const NewSize: Int64); override;
   function GetSize: Int64; override;
  public
   doFreeMemory: boolean;
   constructor Create(fMem: boolean = True);
   destructor Destroy; override;
   function Read(var Buffer; Count: Longint): Longint; override;
   function Write(const Buffer; Count: Longint): Longint; override;
   function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
   procedure SetPointer(Ptr: Pointer; Size_: NativeInt);
   property Memory: Pointer read FMemory write FMemory;
  end;

implementation

{ TMemStream }

constructor TMemStream.Create(fMem: boolean);
begin
 inherited Create;
 FMemory := nil;
 doFreeMemory := fMem;
end;

destructor TMemStream.Destroy;
begin
 if doFreeMemory and (FMemory <> nil) then FreeMem(FMemory);
 FMemory := nil;
 FSize := 0; FPosition := 0;
 inherited Destroy;
end;

procedure TMemStream.SetPointer(Ptr: Pointer; Size_: NativeInt);
begin
 FMemory := Ptr;
 FSize := Size_;
end;

function TMemStream.GetSize: Int64;
begin
 Result := FSize;
end;

procedure TMemStream.SetSize(const NewSize: Int64);
begin
 ReallocMem(FMemory, NewSize);
 FSize := NewSize;
 if FPosition > FSize then FPosition := FSize;
end;

function TMemStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := 0;
 if (FPosition < 0) or (Count <= 0) then exit;
 Result := FSize - FPosition;
 if Result <= 0 then begin Result := 0; exit; end;
 if Result > Count then Result := Count;
 Move((PByte(FMemory) + FPosition)^, Buffer, Result);
 Inc(FPosition, Result);
end;

function TMemStream.Write(const Buffer; Count: Longint): Longint;
var Pos: NativeInt;
begin
 Result := 0;
 if (FPosition < 0) or (Count <= 0) then exit;
 Pos := FPosition + Count;
 if Pos > FSize then begin
  ReallocMem(FMemory, Pos);
  FSize := Pos;
 end;
 System.Move(Buffer, (PByte(FMemory) + FPosition)^, Count);
 FPosition := Pos;
 Result := Count;
end;

function TMemStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 case Origin of
  soBeginning: FPosition := Offset;
  soCurrent: Inc(FPosition, Offset);
  soEnd: FPosition := FSize + Offset;
 end;
 Result := FPosition;
end;

end.
