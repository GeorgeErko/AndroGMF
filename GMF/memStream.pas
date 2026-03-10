unit MemStream;



interface uses Classes;



{TMemStream}



type

  TMemStream = class(TStream)

  private

    FMemory: Pointer;

    FSize, FPosition: Longint;

    procedure SetSize(const Value:Longint);

  protected

  public

   doFreeMemory:boolean;

    constructor Create(fMem:boolean=True);

    function Read(var Buffer; Count: Longint): Longint; override;

    function Write(const Buffer; Count: Longint): Longint; override;

    function Seek(Offset: Longint; Origin: Word): Longint; override;

    procedure SetPointer(Ptr: Pointer; Size_: Longint);

    property Memory: Pointer read FMemory write FMemory;

    property Size:Longint read FSize write SetSize;

    Destructor Destroy;override;

  end;



implementation



{ TMemStream }



procedure TMemStream.SetPointer(Ptr: Pointer; Size_: Longint);

begin

  FMemory := Ptr;

  FSize := Size_;

end;



function TMemStream.Read(var Buffer; Count: Longint): Longint;

begin

  if (FPosition >= 0) and (Count >= 0) then

  begin

    Result := FSize - FPosition;

    if Result > 0 then

    begin

      if Result > Count then Result := Count;

      Move(Pointer(Longint(FMemory) + FPosition)^, Buffer, Result);

      Inc(FPosition, Result);

      Exit;

    end;

  end;

  Result := 0;

end;



function TMemStream.Seek(Offset: Longint;  Origin: Word): Longint;

begin

  case Origin of

    soFromBeginning: FPosition := Offset;

    soFromCurrent: Inc(FPosition, Offset);

    soFromEnd: FPosition := FSize + Offset;

  end;

  Result := FPosition;

end;



function TMemStream.Write(const Buffer; Count: Longint): Longint;

const HeapAllocFlags = 2;

var

  Pos: Longint;

begin

  if (FPosition >= 0) and (Count >= 0) then

  begin

    Pos := FPosition + Count;

    if Pos > 0 then

    begin

      if Pos > FSize then

      begin

      {$IFDEF WIN64}

       If FSize=0 then begin

        FMemory := GlobalAllocPtr(HeapAllocFlags, Pos)

       end else begin

        FMemory:=GlobalReallocPtr(FMemory, Pos, HeapAllocFlags);

       end;

      {$ELSE}

       If FSize=0 then begin

        FMemory := AllocMem(Pos)

       end else begin

        ReallocMem(FMemory, Pos);

       end;

      {$ENDIF}

       FSize := Pos;

      end;

      System.Move(Buffer, Pointer(Longint(FMemory) + FPosition)^, Count);

      FPosition := Pos;

      Result := Count;

      Exit;

    end;

  end;

  Result := 0;

end;



destructor TMemStream.Destroy;

begin

 If doFreeMemory then begin

  {$IFDEF WIN64}

   GlobalFreePtr(FMemory);

  {$ELSE}

   FreeMem(FMemory);

  {$ENDIF}

  fSize:=0;Position:=0;

 end;

 inherited Destroy;

end;



constructor TMemStream.Create(fMem: boolean);

begin

 inherited Create;

 fMemory:=nil;

 doFreeMemory:=fMem;

end;



procedure TMemStream.SetSize(const Value: Longint);

const HeapAllocFlags = 2;

begin                                        

 fSize := Value;

 {$IFDEF WIN64}

 If fMemory=nil then fMemory:=GlobalAllocPtr(HeapAllocFlags, fSize) else

                     fMemory:=GlobalReAllocPtr(fMemory, HeapAllocFlags, fSize);

 {$ELSE}

 If fMemory=nil then fMemory:=AllocMem(fSize) else

                     ReAllocMem(fMemory, fSize);

 {$ENDIF}

end;



end.

