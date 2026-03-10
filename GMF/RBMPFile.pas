unit RBMPFile;
interface
uses sysutils, classes, RSBmp, rBitBox, Collect;

type
  TBmpFile = class(TSimpleBmp)
  public
    bfh: TBitmapFileHeader;
    bih: TBitmapInfoHeader;
  public
    procedure WriteDpi(fn: AnsiString; dpi: integer); override;
    function ReadDpi(fn: AnsiString): integer; override;
    procedure ReadHdr; override;
    procedure GetLines(p: PAnsiChar); override;
    procedure ReadScan(var p: PAnsiChar); override;
    function GetImgSize: integer; override; // sl part size
    procedure Save(const fn: AnsiString); override;
    procedure ReadPal;
    class function slwidth(w: integer; bpp: byte): integer;
  end;

implementation uses newProcs;

{ TBmpFile }
class function TBmpFile.slwidth(w: integer; bpp: byte): integer;
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

procedure TBmpFile.ReadHdr;
begin
  move(fp^, bfh, sizeof(bfh));
  if bfh.bfType <> $4d42 then raise Exception.Create('Неверный формат файла');
  inc(fp, sizeof(bfh));
  move(fp^, bih, sizeof(bih));
  FHeight := bih.biHeight;
  FWidth := bih.biWidth;
  FBpp := bih.biBitCount;
  FSlSize := slwidth(FWidth, fbpp);
  while FSlsize mod 4 <> 0 do inc(fslsize);
//  if (FSlSize and 3) <> 0 then FSlSize := (FSlSize or 3) + 1;
  GetMem(ScanLine, SlSize);
  inc(fp, sizeof(bih));
  InitBMI;
  readpal;
  fp := pAnsiChar(pAnsiChar(hmap) + bfh.bfOffBits);
  fstart := fp;

  fdpi :=Round(bih.biXPelsPerMeter * 0.0254);
  fbmi.bmiHeader.biXPelsPerMeter := bih.biXPelsPerMeter;
  fbmi.bmiHeader.biYPelsPerMeter := bih.biYPelsPerMeter;


  fppm := bih.biXPelsPerMeter;
  GetLines(fp)
end;

procedure TBmpFile.GetLines(p: PAnsiChar);
var i: integer;
begin
  SlStarts.Clear;
  SlStarts.Count := Height;
  for i := height - 1 downto 0 do
  begin
    SLStarts[i] := integer(p);
    inc(p, slsize);
  end;
  bufnum := 0;
end;

function TBmpFile.GetImgSize: integer;
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
//  if (result and 3) <> 0 then result := (result or 3) + 1;
end;

procedure TBmpFile.ReadScan(var p: PAnsiChar);
begin
  move(p^, ScanLine^, slsize);
  inc(p, slsize);
end;

procedure TBmpFile.ReadPal;
var
  i: integer;
  q: TRGBQuad;
begin
  if FBpp > 8 then exit;
  move(fp^, fbmi^.bmiColors, (1 shl FBpp) * sizeof(TRGBQuad));
  if (FBpp = 1) and (FInvBWPal) then
  begin
    i := 1;
    q := fbmi.bmiColors[i];
    fbmi.bmiColors[i] := fbmi.bmiColors[0];
    fbmi.bmiColors[0] := q;
  end;
end;

function TBmpFile.ReadDpi(fn: AnsiString): integer;
var
  f: TFileStream;
begin
  f := TFileStream.Create(fn, fmOpenRead or fmShareDenyWrite);
  try
    f.Read(bfh, sizeof(bfh));
    f.Read(bih, sizeof(bih));
    Result := round(bih.biXPelsPerMeter * 0.0254);
  finally
    f.free;
  end;
end;

procedure TBmpFile.WriteDpi(fn: AnsiString; dpi: integer);
var
  f: TFileStream;
begin
  f := TFileStream.Create(fn, fmOpenReadWrite);
  try
    f.read(bfh, sizeof(bfh));
    f.read(bih, sizeof(bih));
    f.Seek(0, soFromBeginning);
    bih.biXPelsPerMeter := round(dpi / 0.0254);
    bih.biYPelsPerMeter := round(dpi / 0.0254);
    f.write(bfh, sizeof(bfh));
    f.write(bih, sizeof(bih));
  finally
    f.free;
  end;
end;

procedure TBmpFile.Save(const fn: AnsiString);
var
  buf: TBufStream;
  j, i, k: integer;
  p: pAnsiChar;
begin
  try
    buf := TBufStream.InitFileStream(fn, fmCreate or fmShareDenyWrite);
    try
      buf.Write(bfh, sizeof(bfh));
      buf.Write(bih, sizeof(bih));
      if bpp < 24 then buf.Write(fbmi.bmiColors, sizeof(TRgbQuad) * (1 shl FBpp));

      bfh.bfOffBits := buf.position;

      for i := height - 1 downto 0 do
      begin
        p := PAnsiChar(SlStarts[i]);
        ReadScan(p);
        buf.Write(ScanLine^, slsize);
      end;
      bufnum := 0;
      bfh.bfSize := buf.Size;

      buf.Position := 0;
      buf.Write(bfh, sizeof(bfh));
    finally
      buf.Free;
    end;
  except
    on e: Exception do
    begin
      MessageError(PChar(e.Message));
    end;
  end;
end;

end.
