unit ClipStrm;

interface
uses Classes, Clipbrd,{$IFDEF WIN64} Windows {$ELSE} BaseUnix {$ENDIF};


type
  TClipboardMode = ( cmRead, cmWrite );

  TClipboardStream = class( TMemoryStream )
  private
    FMode: TClipboardMode;
    FFormat: Word;
  public
    constructor Create( Format: Word; Mode: TClipboardMode );
    destructor Destroy; override;
  end;

implementation

constructor TClipboardStream.Create( Format: Word; Mode: TClipboardMode );
const HeapAllocFlags = 2;
var
  Handle: THandle;
  MemPtr: Pointer;
begin
  inherited Create;
  FMode := Mode;
  FFormat := Format;

{ In "read mode," immediately read clipboard data
  into the stream... }
  if ( FMode = cmRead ) and Clipboard.HasFormat( FFormat ) then
  begin
    Clipboard.Open;
    try
  //TY    Handle := Clipboard.GetAsHandle( FFormat );
    {$IFDEF WIN64}
      MemPtr := GlobalLock( Handle );
      try
        Write( MemPtr^, GlobalSize( Handle ));
      finally
        GlobalUnlock( Handle );
      end;
    {$ELSE}
      ClipBoard.GetFormat(Format,Self);
    {$ENDIF}
      Position := 0;
    finally
      Clipboard.Close;
    end;
  end;
end;

destructor TClipboardStream.Destroy;
const HeapAllocFlags = 2;
var
  P: PChar;
begin
  { In "write mode," copy to the clipboard whatever the
    stream contains... }
  if FMode = cmWrite then
  begin
   {$IFDEF WIN64}
    P := GlobalAllocPtr( HeapAllocFlags, Size );
    try
      Position := 0;
      Read( P^, Size );
     // Clipboard.SetAsHandle( FFormat, GlobalHandle( P ));
    except
      GlobalFreePtr( P );
    end;
   {$ELSE}
    Position := 0;
    Clipboard.SetFormat(FFormat, Self);
   {$ENDIF}
  end;
  inherited Destroy;
end;

end.

