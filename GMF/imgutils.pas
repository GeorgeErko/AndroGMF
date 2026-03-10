unit imgutils;

interface uses RSBmp, rBitBox,  System.Types;

Const NULL = 0;

procedure SetfDpi(const fn: string; dpi: integer);
function OpenImgFile(const fn: string; readonly: boolean): TSimpleBmp;
function clip_rect(const w, r : TRect ) : TRect;
procedure writebmp(const fn: string; bits: pointer; bmi: PBitmapInfo);
function CreateNewBitmap( FN: String; BPP, W, H, DPI: Integer;
           const spal: array of trgbquad): boolean;
function GetImgSize4(w, bpp: integer): integer;
function GetImgSize1(w: integer; bpp: byte): integer;



implementation uses sysutils, classes, collect, rbmpfile, newProcs;

function GetImgSize1(w: integer; bpp: byte): integer;
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


function GetImgSize4(w, bpp: integer): integer;
begin
  case bpp of
    1: w := (w + 7) div 8;
    4: begin
         w := w + ord(odd(w));
         w := w div 2;
       end;
    8: ;//imsize := imsize;
    24: w := w * 3;
    32: w := w * 4;
  end;
  result := w;
  if (result and 3) <> 0 then result := (result or 3) + 1;
end;

procedure SetfDpi(const fn: string; dpi: integer);
{var ext: string;
    img: TSimpleBmp;
    pcxh: TPCXHdr;
    hf, hmem: THandle;
    hmap: pointer;
    p: pointer;
    }
begin
//  ext := UpperCase(ExtractFileExt(fn));
//  fn := UpperCase(ExtractFileName(fn));
{$IFDEF MSWINDOWS}
  hf := CreateFile(pchar(fn), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if hf = INVALID_HANDLE_VALUE then RaiseLastWin32Error;
  hmem := CreateFileMapping(hf, nil, PAGE_READWRITE, 0, 0, nil);
  CloseHandle(hf);
  if hmem = NULL then RaiseLastWin32Error;
  hmap := MapViewOfFile(hmem, FILE_MAP_READ or FILE_MAP_WRITE, 0, 0, 0);
  if hmap = nil then RaiseLastWin32Error;
  p := hmap;
  try
    if ext = '.PCX' then
    begin
      tpcxhdr(hmap^).HRes := dpi;
      tpcxhdr(hmap^).VRes := dpi;
    end
    else if ext = '.BMP' then
    begin
    // Уточнить размер p в Win64  inc(integer(p), sizeof(TBitmapFileHeader));
      TBitmapInfoHeader(p^).biXPelsPerMeter := round(dpi / 0.0254);
      TBitmapInfoHeader(p^).biYPelsPerMeter := round(dpi / 0.0254); 
    end;
  finally
    if hmap <> nil then UnmapViewOfFile(hmap);
    if hmem <> NULL then CloseHandle(hmem);
  end;
{$ENDIF}
end;

function OpenImgFile(const fn: string; readonly: boolean): TSimpleBmp;
var s: string;
begin
{
  s := UpperCase(ExtractFileExt(fn));
  if s = '.PCX' then  result := TPcx2file.Create(fn, readonly)
//  else if s = '.TIF' then  result := TTiffFile.Create(fn, readonly)
  else if s = '.BMP' then result := TBmpFile.Create(fn, readonly)
  else raise Exception.Create('Неподдерживаемый формат файла');
}
end;

function clip_rect(const w, r : TRect ) : TRect;
var res : TRect;
begin
  if r.Left < 0 then res.Left := -r.Left else res.Left := 0;
  if r.Top < 0 then res.Top := -r.Top else res.Top := 0;
  if r.Right >= w.Right then res.Right := w.Right-r.Left
  else res.Right := r.Right-R.Left;
  if r.Bottom >= w.Bottom then res.Bottom := w.Bottom-r.Top
  else res.Bottom := r.Bottom-R.Top;
  Result := res
end;

procedure writebmp(const fn: string; bits: pointer; bmi: pBitmapInfo);
var f: TFileStream;
    bmfh: TBitmapFileHeader;
    s: integer;
begin
  f := TFileStream.Create(fn, fmCreate or fmShareDenyWrite);
  try
    bmfh.bfType := $4d42;
    bmfh.bfSize := 0;
    bmfh.bfReserved1 := 0;
    bmfh.bfReserved2 := 0;
    if bmi.bmiHeader.biBitCount < 24 then
      s := sizeof(tBitmapInfoHeader) + sizeof(TRgbQuad) * (1 shl bmi.bmiHeader.biBitCount)
    else s := sizeof(tBitmapInfoHeader);
    bmfh.bfOffBits := sizeof(bmfh) + s;
    f.Write(bmfh, sizeof(bmfh));
    f.Write(bmi^, s);
    s := ((bmi.bmiHeader.biWidth * bmi.bmiHeader.biBitCount +31) and not 31) div 8 *
          bmi.bmiHeader.biHeight;
    f.Write(bits^, s);
  finally
    f.free;
  end;
end;

function CreateNewBitmap( FN: String; BPP, W, H, DPI: Integer;
           const spal: array of trgbquad): boolean;
var i, j, k, zzzz, isz: integer;
    bi: TBitmapInfoHeader;
    bfh: TBitmapFileHeader;
    pal: array[0..255] of TRGBQuad;
    buf: TBufStream;
    p: PChar;
    bsw, sss: integer;
    c: byte;
    bbb: PByteArray;
begin
  result := false;
  c := 0;
  buf := TBufStream.InitFileStream(fn, fmCreate or fmShareDenyWrite);
  try
    try
    result := true;
      bfh.bfType := $4d42;
      bfh.bfSize := 0;
      bfh.bfReserved1 := 0;
      bfh.bfReserved2 := 0;
      bfh.bfOffBits := 0;
      buf.Write(bfh, sizeof(bfh));
      with bi do
      begin
        biSize := sizeof(bi);
        biWidth := W;
        biHeight := H;
        biPlanes := 1;
        biBitCount := bpp;
        biCompression := 0;//BI_RGB;
        biSizeImage := 0;
        biXPelsPerMeter := round(DPI / 0.0254);
        biYPelsPerMeter := round(DPI / 0.0254);
        biClrUsed := 0;
        biClrImportant := 0;
      end;
      buf.Write(bi, sizeof(bi));
      zzzz := (1 shl bpp);
      if bpp < 24 then
        for i := 0 to zzzz - 1 do
        begin
          pal[i].rgbBlue := spal[i].rgbBlue;
          pal[i].rgbRed := spal[i].rgbRed;
          pal[i].rgbGreen := spal[i].rgbGreen;
          pal[i].rgbReserved := 0;
        end;
      if bpp < 24 then
        buf.Write(pal, sizeof(pal[0]) * zzzz);
      
      bfh.bfOffBits := buf.position;
      isz := getimgSize4(w, bpp);
      Getmem(bbb, isz);
      try
        fillchar(bbb^, 0, isz);
        for i := 0 to  h - 1 do
        begin
          buf.Write(bbb^, isz);
        end;
      finally
        freemem(bbb);
      end;
      buf.Position := 0;
      bfh.bfSize := buf.Size;
      buf.Write(bfh, sizeof(bfh));
    finally
      buf.Free;
    end;
  except
    on e: Exception do
    begin
      MessageError(PChar(e.Message));
      result := false;
    end;
  end;
end;

end.
