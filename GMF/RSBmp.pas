unit rsbmp;

interface
uses Classes, SysUtils, Collect, RBitBox, FMX.Graphics;

const
 NULL = 0;

type
  TGetPixel = function (X, Y: integer): integer of object;
  TSetPixel = procedure (x, y: integer; v: integer) of object;

type
  TIntList = class(TList)
  private
    function GetItems(index: integer): integer;
    procedure SetItems(index: integer; const Value: integer);
  public
    property Items[index: integer]: integer read GetItems write SetItems; default;
  end;

  TRootBmp = class
  protected
    FHeight: integer;
    FWidth: integer;
  public
    GetPixel: TGetPixel;
    SetPixel: TSetPixel;
    property Width: integer read FWidth;
    property Height: integer read FHeight;
  end;

  TGetSlPart = procedure (p, bigmemcur: PByteArray; usedyna: boolean) of object;

  TSimpleBmp = class(TRootBmp)
  private
    FBmh: TBitmapInfoHeader;
    procedure GetSlPart1(p, bigmemcur: PByteArray; usedyna: boolean);
    procedure GetSlPart24(p, bigmemcur: PByteArray; usedyna: boolean);
    procedure GetSlPart4(p, bigmemcur: PByteArray; usedyna: boolean);
    procedure GetSlPart8(p, bigmemcur: PByteArray; usedyna: boolean);
  protected
    FDpi: integer;
    fppm: integer;
    FDynaX, FDynaY: TDynaCol;
    xstart, xend, ystart, yend: integer;

    finmemory: boolean;
    filesize: integer;

    hmem: THandle;
    hmap: pointer;

    FBpp: integer;
    FSlSize: integer;
    ScanLine: PByteArray;

    GetSLPart: TGetSlPart;

    function GetPartHeight: integer;
    function GetPartWidth: integer;
  protected
    procedure ReadHdr; virtual; abstract;
              {GetMem(Scanline); set: w, h, bpp, slsize; read fbmi.pal; init slstarts}

    procedure InitBMI; virtual;

    procedure GetLines(p: PAnsiChar); virtual;
//    procedure GetSlPart(p, bigmemcur: PByteArray; usedyna: boolean); virtual;
    procedure ReadScan(var p: PAnsiChar); virtual; abstract;

  public
    procedure WriteDpi(fn: AnsiString; dpi: integer); virtual; abstract;
    function ReadDpi(fn: AnsiString): integer; virtual; abstract;
    procedure CheckDPI(fn: AnsiString; querydpi: boolean); //проверяет и показывает диалог
                                                       //(если надо) установки дпи
  public
    FInvBWPal: boolean;

    bufnum: integer;
    SLStarts: TIntList;
    fstart : pAnsiChar;
    fbmi: PBitmapInfo;
    bigmem: PAnsiChar;
    fbigmem_size: integer;
    fbigmem_height: integer;

    fbitoffs: pAnsiChar;
    fp: PAnsiChar;                // file pointer
    querydpi: boolean;
  public
    constructor Create(const fn: TFilename; readonly: boolean; inmemory: boolean = false; querydpi_: boolean = true);
    destructor Destroy; override;

    function SaveBmp(y, y2, x, x2: integer; DynaX, DynaY: TDynaCol;
                 usedyna: boolean; all: boolean = false): Pointer; virtual;

    function GetImgSize: integer; virtual;

    procedure Part(usedyna: boolean); virtual;
    procedure SaveAsBmp(const bmp: AnsiString); virtual; abstract;
    procedure LoadFromBmp(const bmp, new: AnsiString); virtual; abstract;
    procedure Save(const fn: AnsiString); virtual; abstract;

    function GetPixel2(X, Y: integer): integer;
    procedure SetPixel2(x, y: integer; v: integer);

    function GetPixel4(X, Y: integer): integer;
    procedure SetPixel4(x, y: integer; v: integer);

    function GetPixel8(X, Y: integer): integer;
    procedure SetPixel8(x, y: integer; v: integer);

    function GetPixel24(X, Y: integer): integer;
    procedure SetPixel24(x, y: integer; v: integer);

    procedure CreateDitherPal;
    procedure SetPixelPalVal(x, y: integer; v: integer);
    function GetPixelVal(x, y: integer): integer;

    procedure SwapBWPal;

    property bpp: integer read FBpp;
    property dpi: integer read FDpi write FDpi;
    property ppm: integer read FPPM write FPpm;
    property SlSize: integer read FSlSize;
    property PartWidth: integer read GetPartWidth;
    property PartHeight: integer read GetPartHeight;
  end;

  function slwidth(w: integer; bpp: byte): integer;

function GetScanPixel2(X: integer; buf: pAnsiChar): integer;

implementation uses newProcs, System.UITypes;

{ TIntList }

function TIntList.GetItems(index: integer): integer;
begin
  if (Index < 0) or (Index >= Count) then Error('Îøèáêà intList %d', Index);
  Result := integer(List[Index]);
end;

procedure TIntList.SetItems(index: integer; const Value: integer);
begin
  if (Index < 0) or (Index >= Count) then Error('Îøèáêà intList %d', Index);
  List[Index] := pointer(value);
end;

{}

function slwidth(w: integer; bpp: byte): integer;
begin
  case bpp of
    1 : result := (w + 7) div 8;
    4 : result := w div 2 + ord(odd(w));
    8 : result := w;
    24: result := w * 3;
    32: result := w * 4;
  else raise Exception.Create('Ошибка: число битов на пиксел задано не верно');
  end;
end;


{ TSimpleBmp }


constructor TSimpleBmp.Create(const fn: TFilename; readonly: boolean; inmemory: boolean = false;
              querydpi_: boolean = true);
var fs, i: cardinal;
    hf: thandle;
    d: integer;
begin
  CheckDPI(fn, querydpi);
  Self.querydpi := querydpi;
{$IFDEF WIN65}
  SlStarts := TIntList.Create;
  finmemory := inmemory;
  if readonly then
    hf := CreateFile(pChar(fn), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0)
  else
    hf := CreateFile(pChar(fn), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if hf = INVALID_HANDLE_VALUE then RaiseLastWin32Error;
  fs := GetFileSize(hf, nil);
  filesize := fs;
  if inmemory then
  begin
    GetMem(hmap, fs);
    if not ReadFile(hf, hmap^, fs, i, nil) then RaiseLastWin32Error;
    if fs <> i then raise Exception.Create('Ошибка чтения файла.');
    CloseHandle(hf);
  end
  else
  begin
    if readonly then
      hmem := CreateFileMapping(hf, nil, PAGE_READONLY, 0, 0, nil)
    else
      hmem := CreateFileMapping(hf, nil, PAGE_READWRITE, 0, 0, nil);
//    If CloseHandle(hf)=false then ShowMessage('not closed') else ShowMEssage('closed');
    CloseHandle(hf);
    hf:=0;
    if hmem = NULL then RaiseLastWin32Error;
    if readonly then
      hmap := MapViewOfFile(hmem, FILE_MAP_READ, 0, 0, 0)
    else
      hmap := MapViewOfFile(hmem, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 0);
    if hmap = nil then RaiseLastWin32Error;
  end;
  fp := hmap;
  if fp = nil then raise Exception.Create('Неверный формат файла');
  ReadHdr;
  case bpp of
    1: begin
         SetPixel := SetPixel2;
         GetPixel := GetPixel2;
         GetSlPart := GetSlPart1;
       end;
    4: begin
         SetPixel := SetPixel4;
         GetPixel := GetPixel4;
         GetSlPart := GetSlPart4;
       end;
    8: begin
         SetPixel := SetPixel8;
         GetPixel := GetPixel8;
         GetSlPart := GetSlPart8;
       end;
    24: begin
         SetPixel := SetPixel24;
         GetPixel := GetPixel24;
         GetSlPart := GetSlPart24;
        end;
    else raise Exception.Create('Неверно указано число битов на цвет.');
  end;
  fbitoffs := pointer(SLStarts[0]);
{$ENDIF}

{  d := dpi;
  if (dpi in [0, 72, 96]) or querydpi then
  begin
      with TDPIDlg.Create(nil) do
      try
        if execute(d) then
        begin
          fdpi := d;
          fppm := round(d / 0.0254);
        end;
      finally
        free;
      end;
  end;}
end;

destructor TSimpleBmp.Destroy;
begin
  if fbmi <> nil then freemem(fbmi);
  SlStarts.Free;
{$IFDEF WIN65}
  if not finmemory then
  begin
    if hmap <> nil then UnmapViewOfFile(hmap);
    if hmem <> NULL then CloseHandle(hmem);
  end
  else if hmap <> nil then freemem(hmap);
{$ENDIF}
  if bigmem <> nil then freemem(bigmem);
  FreeMem(ScanLine, slsize);
end;

procedure TSimpleBmp.GetLines(p: PAnsiChar);
var i, h: integer;
begin
  h := Height;
  SlStarts.Clear;
  SlStarts.Count := h;
  for i := 0 to h - 1 do
  begin
    SlStarts[i] := integer(fp);
    ReadScan(fp);
  end;
  bufnum := h - 1;
end;

procedure TSimpleBmp.InitBMI;
begin
  if fbmi <> nil then freemem(fbmi);
  if bpp < 24 then GetMem(fbmi, SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry) * (1 shl bpp))
  else GetMem(fbmi, SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry) * 2);
  fbmi.bmiHeader.biSize := sizeof(fbmi.bmiHeader);
  fbmi.bmiHeader.biWidth := 0;
  fbmi.bmiHeader.biHeight := 0;
  fbmi.bmiHeader.biPlanes := 1;
  fbmi.bmiHeader.biBitCount := bpp;
  fbmi.bmiHeader.biCompression := 0; //BI_RGB;
  fbmi.bmiHeader.biSizeImage := 0;
  fbmi.bmiHeader.biXPelsPerMeter := 0;
  fbmi.bmiHeader.biYPelsPerMeter := 0;
  fbmi.bmiHeader.biClrUsed := 0;
  fbmi.bmiHeader.biClrImportant := 0;
end;

procedure TSimpleBmp.GetSlPart1(p, bigmemcur: PByteArray; usedyna: boolean);
var bit, rbit: byte;
    byt, rbyt: integer;
    i, v: integer;
begin
  rbyt := 0;
  rbit := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
    byt := v div 8;
    bit := 7 - v mod 8;
    if (p[byt] and (1 shl bit)) <> 0 then bigmemcur[rbyt] := bigmemcur[rbyt] or (1 shl (7 - rbit));
    if rbit >= 7 then
    begin
      rbit := 0;
      inc(rbyt);
    end
    else inc(rbit);
  end;
end;

procedure TSimpleBmp.GetSlPart4(p, bigmemcur: PByteArray; usedyna: boolean);
var bit, rbit: byte;
    byt, rbyt: integer;
    i, v: integer;
    b1, b2: byte;
    procedure sl24bpp;
    begin
      bigmemcur[rbyt] := p[v * 3];
      inc(rbyt);
      bigmemcur[rbyt] := p[v * 3 + 1];
      inc(rbyt);
      bigmemcur[rbyt] := p[v * 3 + 2];
      inc(rbyt);
    end;

    procedure sl8bpp;
    begin
      bigmemcur[rbyt] := p[v];
      inc(rbyt);
    end;

begin
  rbyt := 0;
  rbit := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
      b1 := p[v div 2];
      if v mod 2 <> 0 then b1 := (b1 and $0f) shl 4
      else b1 := (b1 and $f0);
      if rbit = 0 then
      begin
        bigmemcur[rbyt] := b1;
        inc(rbit);
      end
      else
      begin
        bigmemcur[rbyt] := bigmemcur[rbyt] or (b1 shr 4);
        rbit := 0;
        inc(rbyt);
      end;
  end;
end;

procedure TSimpleBmp.GetSlPart8(p, bigmemcur: PByteArray; usedyna: boolean);
var
    rbyt: integer;
    i, v: integer;
begin
  rbyt := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
    bigmemcur[rbyt] := p[v];
    inc(rbyt);
  end;
end;

procedure TSimpleBmp.GetSlPart24(p, bigmemcur: PByteArray; usedyna: boolean);
var rbyt: integer;
    i, v: integer;
begin
  rbyt := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
    bigmemcur[rbyt] := p[v * 3];
    inc(rbyt);
    bigmemcur[rbyt] := p[v * 3 + 1];
    inc(rbyt);
    bigmemcur[rbyt] := p[v * 3 + 2];
    inc(rbyt);
  end;
end;

(*
procedure TSimpleBmp.GetSlPart(p, bigmemcur: PByteArray; usedyna: boolean);
var bit, rbit: byte;
    byt, rbyt: integer;
    i, v: integer;

    procedure sl1bpp;
    begin
      byt := v div 8;
      bit := 7 - v mod 8;
      if (p[byt] and (1 shl bit)) <> 0 then bigmemcur[rbyt] := bigmemcur[rbyt] or (1 shl (7 - rbit));
      if rbit >= 7 then
      begin
        rbit := 0;
        inc(rbyt);
      end
      else inc(rbit);
    end;

    procedure sl24bpp;
    begin
      bigmemcur[rbyt] := p[v * 3];
      inc(rbyt);
      bigmemcur[rbyt] := p[v * 3 + 1];
      inc(rbyt);
      bigmemcur[rbyt] := p[v * 3 + 2];
      inc(rbyt);
    end;

    procedure sl8bpp;
    begin
      bigmemcur[rbyt] := p[v];
      inc(rbyt);
    end;

    procedure sl4bpp;
    var b1, b2: byte;
    begin
      b1 := p[v div 2];
      if v mod 2 <> 0 then b1 := (b1 and $0f) shl 4
      else b1 := (b1 and $f0);
      if rbit = 0 then
      begin
        bigmemcur[rbyt] := b1;
        inc(rbit);
      end
      else
      begin
        bigmemcur[rbyt] := bigmemcur[rbyt] or (b1 shr 4);
        rbit := 0;
        inc(rbyt);
      end;
    end;
begin
  rbyt := 0;
  rbit := 0;
  bigmemcur[rbyt] := 0;
  for i := xstart to xend - 1 do
  begin
    if usedyna then v := TInt(FDynaX[i - xstart]).value
    else v := i;
    case bpp of
      1: sl1bpp;
      4: sl4bpp;
      8: sl8bpp;
      24: sl24bpp;
    end;
  end;
end;
*)
procedure TSimpleBmp.Part(usedyna: boolean);
var i, zzz, kkk, k: integer;
    pp: pAnsiChar;
    bigmemcur: PAnsiChar;
    imsize: integer;
begin
  imsize := getImgSize;
  if (imsize and 3) <> 0 then imsize := (imsize or 3) + 1;
  if bigmem <> nil then
  begin
    FreeMem(bigmem);
    bigmem := nil;
  end;
  GetMem(bigmem, imsize * (yend - ystart + 1));
  fbigmem_size := imsize * (yend - ystart + 1);
  fbigmem_height := (yend - ystart + 1);
  fillChar(bigmem^,imsize * (yend - ystart + 1), 0);
  bigmemcur := bigmem + imsize * (yend - ystart);
  zzz := 0;
  for i := ystart to yend - 1 do
  begin
    dec(bigmemcur, imsize);
    if usedyna then fp := pointer(SlStarts[TInt(FDynaY[zzz]).value])
    else if i < SlStarts.count then fp := pointer(SlStarts[i])
    else
    begin
      bufnum := i;
      exit;
    end;
    ReadScan(fp);
    pointer(pp) := ScanLine;
    GetSLPart(PByteArray(pp), PByteArray(bigmemcur), usedyna);
    inc(zzz);
  end;
  bufnum := yend - 1;
end;

function TSimpleBmp.SaveBmp(y, y2, x, x2: integer; DynaX, DynaY: TDynaCol; usedyna: boolean; all: boolean = false): Pointer;
var i: integer;
begin
  FDynaX := DynaX;
  FDynaY := DynaY;
  xstart := x;
  ystart := y;
  xend   := x2;
  yend   := y2;
  fbmi.bmiHeader.biWidth := xend - xstart;
  fbmi.bmiHeader.biHeight := yend - ystart ;
  if fbmi.bmiHeader.biWidth < 0 then fbmi.bmiHeader.biWidth := 0;
  if fbmi.bmiHeader.biHeight < 0 then fbmi.bmiHeader.biHeight := 0;
  if (fbmi.bmiHeader.biWidth <= 0) or (fbmi.bmiHeader.biHeight <= 0) then
    exit;
  i := 1;
  if usedyna then Part(true)
  else Part(false);
  if (fbmi.bmiHeader.biHeight > 0) and (fbmi.bmiHeader.biWidth > 0) then result := bigmem
  else result := nil;
end;

function TSimpleBmp.GetImgSize: integer;
var imsize: integer;
begin
  imsize := xend - xstart;
  case bpp of
    1: begin
         imsize := (imsize + 7) div 8;
       end;
    4: begin
         imsize := imsize + ord(odd(imsize));
         imsize := imsize div 2;
       end;
    8: ;//imsize := imsize;
    24: imsize := imsize * 3;
    32: imsize := imsize * 4;
  end;
  result := imsize;
//  if odd(result) then inc(result);
//  if (result and 3) <> 0 then result := (result or 3) + 1;
end;

function TSimpleBmp.GetPartHeight: integer;
begin
  result := fbmi.bmiHeader.biHeight;
end;

function TSimpleBmp.GetPartWidth: integer;
begin
  result := fbmi.bmiHeader.biWidth;
end;
{
function TSimpleBmp.GetPixel2(X, Y: integer): integer;
var byt, bit: integer;
    b: byte;
    p: pAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts[y]);
    ReadScan(p);
  end;
  byt := x div 8;
  bit := 7 - x mod 8;
  b := ScanLine[byt];
  result := ord((b and byte(1 shl bit)) <> 0);
end;

procedure TSimpleBmp.SetPixel2(x, y, v: integer);
var byt: integer;
    bit: byte;
    p, pp: PAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  byt := x div 8;
  bit := 7 - x mod 8;
  pp := pAnsiChar(SlStarts[y] + byt);
  p := pp;
  if v <> 0 then
    p^ := chr(ord(pp^) or byte(1 shl bit));
end;

function TSimpleBmp.GetPixel4(X, Y: integer): integer;
var b1: byte;
    p: pAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts[y]);
    ReadScan(p);
  end;
  b1 := ScanLine[x div 2];
  if x mod 2 <> 0 then b1 := (b1 and $0f) shl 4
  else b1 := (b1 and $f0);
  result := b1 shr 4;
end;

procedure TSimpleBmp.SetPixel4(x, y, v: integer);
var p: pAnsiChar;
    b: byte;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  b := byte(v);
  p := SLStarts[y] + pAnsiChar((x div 2));
  if x mod 2 = 0 then p^ := chr(ord(p^) or ((b shr 4) and $0F))
  else p^ := chr(b);
end;
}

procedure TSimpleBmp.SetPixel2(x, y: integer; v: integer);
var p: PAnsiChar;
    byt: integer;
    bit: byte;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  byt := x div 8;
  bit := 7 - x mod 8;
  p := PAnsiChar(SlStarts.list[y]) + (byt);
  if v <> 0 then p^ := AnsiChar(chr(ord(p^) or byte(1 shl bit)))
  else
  p^ := AnsiChar(chr(byte(ord(p^) and not byte(1 shl bit))))
end;

function TSimpleBmp.GetPixel2(X, Y: integer): integer;
var p: PAnsiChar;
    bit: byte;
    byt: integer;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts.list[y]);
    ReadScan(p);
  end;
  byt := x div 8;
  bit := 7 - x mod 8;
  result := ScanLine[byt];
  result := ord((result and (1 shl bit)) <> 0);
end;

function TSimpleBmp.GetPixel4(X, Y: integer): integer;
var b1: byte;
    p: pAnsiChar;
begin
  if (y < 0) or (y > height) or (x < 0) or (x > width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts.list[y]);
    ReadScan(p);
  end;

  b1 := ScanLine[x div 2];
  if x mod 2 <> 0 then b1 := (b1 shl 4) and $F0
  else b1 := (b1 and $f0);
  result := b1;
end;

procedure TSimpleBmp.SetPixel4(x, y, v: integer);
var b1: byte;
    p: pAnsiChar;
begin
  if (y < 0) or (y > height) or (x < 0) or (x > width) then exit;
  p := pAnsiChar(SLStarts.list[y]);
  inc(p, x div 2);
  b1 := v;
  if x mod 2 <> 0 then p^ := AnsiChar(chr((ord(p^) and $f0) or ((b1 shr 4) and $0f)))
  else p^ := AnsiChar(chr((ord(p^) and $0f) or (b1 and $f0)));
end;

procedure TSimpleBmp.SetPixel8(x, y: integer; v: integer);
var p: pAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  p := PAnsiChar(SlStarts.list[y]) + x;
  p^ := AnsiChar(v);
end;

function TSimpleBmp.GetPixel8(X, Y: integer): integer;
var p: PAnsiChar;
    bit: byte;
    byt: integer;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := 0;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts.list[y]);
    ReadScan(p);
  end;
    result := ScanLine[x];
{  bit := 7 - (x mod 8);
  byt := (x div 8);
  result := not (byte(ScanLine[byt] and (1 shl bit)) <> 0);}
end;

function TSimpleBmp.GetPixel24(X, Y: integer): integer;
var p: pAnsiChar;
begin
  result := TAlphaColors.White;
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then
  begin
    result := TAlphaColors.White;
    exit;
  end;
  if bufnum <> y then
  begin
    bufnum := y;
    p := pointer(SlStarts.list[y]);
    ReadScan(p);
  end;
  x := x * 3;
  result := RGBToCol(ScanLine[x],  ScanLine[x + 1], ScanLine[x + 2]);
end;

procedure TSimpleBmp.SetPixel24(x, y, v: integer);
var p: pAnsiChar;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  p := PAnsiChar(SlStarts.list[y]) + (x * 3);
  p^ := AnsiChar(chr(GetR(v)));
  inc(p);
  p^ := AnsiChar(chr(GetG(v)));
  inc(p);
  p^ := AnsiChar(chr(GetB(v)));
end;

function TSimpleBmp.GetPixelVal(x, y: integer): integer;
var i: integer;
begin
  if FBpp <> 24 then
    with fbmi.bmiColors[GetPixel(x, y)] do
      result := RGBToCol(rgbBlue, rgbGreen, rgbRed)
  else result := GetPixel(x, y);
end;

procedure TSimpleBmp.SetPixelPalVal(x, y, v: integer);
var r, g, b: byte;
begin
  if (y < 0) or (y >= height) or (x < 0) or (x >= width) then exit;
  r := GetR(v);
  g := GetG(v);
  b := GetB(v);
end;

procedure TSimpleBmp.CreateDitherPal;
var i, k, n, m: integer;
begin
  k := 0;
  n := 32;
  m := 0;
  for i := 0 to 31 do
    for k := 0 to 5 do
    begin
      fbmi.bmiColors[m].rgbBlue := k * n;
      m := m + 1;
    end;
  for i := 0 to 31 do
    for k := 0 to 5 do
    begin
      fbmi.bmiColors[m].rgbGreen := k * n;
      m := m + 1;
    end;
  for i := 0 to 31 do
    for k := 0 to 7 do
    begin
      fbmi.bmiColors[m].rgbRed := k * n;
      m := m + 1;
    end;
end;



function GetScanPixel2(X: integer; buf: pAnsiChar): integer;
var p: PAnsiChar;
    bit: byte;
    byt: integer;
begin
  byt := x div 8;
  bit := 7 - x mod 8;
  result := ord((buf + byt)^);
  result := ord((result and (1 shl bit)) <> 0);
end;

procedure TSimpleBmp.CheckDPI(fn: AnsiString; querydpi: boolean);
var
//  dlg: TDPIDlg;
  dpi: integer;
begin
  FInvBWPal := false;
  //dlg := TDPIDlg.Create(nil);
  try
    dpi := ReadDpi(fn);
    if (dpi in [0]) or {, 72, 96]) or} querydpi then WriteDpi(fn, 96);
     //dlg.execute(dpi, FInvBWPal, fn, self)
  finally
    //dlg.free;
  end;
end;

procedure TSimpleBmp.SwapBWPal;
var
  i: integer;
  rgb: TRGBQuad;
begin
  if FBmi = nil then exit;
  i := 1;
  rgb := fbmi.bmiColors[i];
  fbmi.bmiColors[i] := fbmi.bmiColors[0];
  fbmi.bmiColors[0] := rgb; 
end;

end.
