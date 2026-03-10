unit RBitBox;

interface

uses SysUtils, Classes, FMX.Graphics, Collect, FMX.Controls, System.Types, FMX.Surfaces{$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF};

{$IFNDEF MSWINDOWS}
type
 TPaletteEntry=packed record
  peRed:Byte;
  peGreen:Byte;
  peBlue:Byte;
  peFlags:Byte;
 end;
 TRGBQuad=packed record
  rgbBlue:Byte;
  rgbGreen:Byte;
  rgbRed:Byte;
  rgbReserved:Byte;
 end;

 TBitmapInfoHeader=packed record
  biSize:Cardinal;
  biWidth:FixedInt;
  biHeight:FixedInt;
  biPlanes:Word;
  biBitCount:Word;
  biCompression:Cardinal;
  biSizeImage:Cardinal;
  biXPelsPerMeter:FixedInt;
  biYPelsPerMeter:FixedInt;
  biClrUsed:Cardinal;
  biClrImportant:Cardinal;
 end;

 TBitmapInfo=packed record
  bmiHeader:TBitmapInfoHeader;
  bmiColors:array[0..0] of TRGBQuad;
 end;

 PBitmapInfo=^TBitmapInfo;

 TBitmapFileHeader=packed record
  bfType:Word;
  bfSize:Cardinal;
  bfReserved1:Word;
  bfReserved2:Word;
  bfOffBits:Cardinal;
 end;

 PBitmapFileHeader=^TBitmapFileHeader;

 hDc = Integer;
 hBitmap = Integer;
 THandle  =NativeUInt;

const
 INVALID_HANDLE_VALUE=THandle(NativeUInt(-1));
 DIB_RGB_COLORS=0;
 FILE_MAP_ALL_ACCESS=0;
 GENERIC_READ=0;
 GENERIC_WRITE=0;
 FILE_SHARE_READ=0;
 FILE_SHARE_WRITE=0;
 OPEN_EXISTING=0;
 PAGE_READWRITE=0;
{$ENDIF}

type
  pBmi = ^TBmi;
  TBMI  = record
    bminfo : TBitmapInfo;
    Colors : array[0..255] of TRGBQuad;
  end;

type
  TInt=class(TTwgObject)
    Value:Integer;
     Constructor Create(N:Integer);
   end;

  TDynaCol=class(PCollection)
   MaxValue:Integer;
   MaxCount:Integer;
    Procedure DynaSet(MV,MC:Integer);
    Procedure Insert(Item : Pointer); override;
   end;

// Нельзя предвидеть ничего, а с непредвиденного получить все.

type
  TBitBox = class(TComponent)
   Private
    FColor: FixedInt;
    FBackColor: FixedInt;
//    FWidth,FHeight,FTop,FLeft,FRight,FBottom:Integer;
   Public
    FWidth,FHeight,FTop,FLeft,FRight,FBottom:Integer;
    Viewer:TControl;
    RPrin:TRect;
    Print:Boolean;
    Canvas:TCanvas;
   // Общий растр
    FileName:AnsiString;
    bmFile : pBitmapFileHeader;
    bmi : TBmI;// TBitmapInfo с палитрой
    pb: pByteArray; // указатель на начало файла
    Bits : pointer; // указатель на начало битов растра
    hf, hm : THandle; // дескрипторы файла и отображения файла
    biWidth3:Integer;// ширина растра
    Error:Integer;// ошибки при отображении
//    Palette:hPalette;// палитра
   // Фрагмент
    UseStandart:Boolean;  //использовать стандартную рисовку растра
    UseStretch :Boolean;  //растягивать изображение (для тестирования)
    NewInfo  :PBitmapInfo;// динамически создаваемый заголовок с палитрой
    NewBitmap:Pointer;    // временный растр
    biNewWidth:Integer;   // ширина временного растра
    R:TRect;              // прямоугольник отображения
    XKoeff,YKoeff:Double; // коэффициент увеличения уменьшения
    DynaX,DynaY:TDynaCol; // коллекциии строк и столбцов при уменьшении
    ZoomFlag:Boolean;     // происходит увеличение
    TransParent:Boolean;
    PrinterDc:hDc;
   {}
    CopyMode:Integer;
    Win32CopyMode:Integer;
   {}
    Function  CreateNewBitmap(Box:TBitBox;FN:AnsiString;W,H:Integer):Boolean; virtual;
    Function  CreateMemBitmap(W,H:Integer;var Info:PBitmapInfo;var nWidth:Integer):Pointer;
{}   Procedure Initialize(V:TControl;C:TCanvas); virtual;
    Destructor Destroy;override;
   {}
{}    Procedure CreateView(FN:AnsiString; readonly: boolean); virtual;
{}    Procedure CloseView; virtual;
   {}
    Function  CreateBitmapInfo:Boolean;// создание нового NewBitmap
    Procedure DrawNewBitmap(Stretch:Boolean);
    Procedure ReplaceAndZoom(Zoom,Win:TRect);
    Procedure CreateDynaBits;
    Procedure SetView1x1;// отображение 1 к 1
    Procedure SetViewZoom;// растянутое отображение
    Procedure SetViewStretch;// сжатое отображение
   {}
{}  Procedure Paint(C:TCanvas);virtual;
   {}
    Function ViewDC:hDc;
    Function PPM:Integer; virtual; abstract;
    Function DPI:Integer; virtual; abstract;
    Function biWidth:Integer; virtual;
    Function biHeight:Integer; virtual;


    procedure AfterTrans(const s1, s2: AnsiString); virtual;

    procedure SetBackColor(const Value: FixedInt);
    procedure SetColor(const Value: FixedInt);

    procedure initBmi(const fn: AnsiString; w, h: integer); virtual;


   {}
     Procedure SetWidth(V:Integer);
    Property Width:Integer read FWidth write SetWidth;
     Procedure SetHeight(V:Integer);
    Property Height:Integer read FHeight write SetHeight;
     Procedure SetTop(V:Integer);
    Property Top:Integer read FTop write SetTop;
     Procedure SetLeft(V:Integer);
    Property Left:Integer read FLeft write SetLeft;
     Property Right:Integer read FRight;
     Property Bottom:Integer read FBottom;
   {}
      Function  GetbmPixel(Info:TBitmapInfo;Bitmap:Pointer;nWidth:Integer;X,Y:Integer):Boolean;
      Procedure SetbmPixel(Info:TBitmapInfo;Bitmap:Pointer;nWidth:Integer;X,Y:Integer;V:Boolean);
{      Function  GetPixel(X,Y:Integer):integer; virtual;
      Procedure SetPixel(X,Y:Integer;V:integer); virtual;
     Property Pixels[X,Y:Integer]:integer read GetPixel write SetPixel;}
     property BackColor: FixedInt read FBackColor write SetBackColor;
     property Color:FixedInt read FColor write SetColor;
   {}
  end;

  TBitBoxClass=class of TBitBox;

  function clip_rect( w, r : TRect ) : TRect;



procedure Register;

implementation uses FMX.Objects;

{}
Constructor TInt.Create;
 begin
  Value:=N;
 end;

Procedure TDynaCol.DynaSet;
 begin
  MaxValue:=MV;
  MaxCount:=MC;
 end;

Procedure TDynaCol.Insert;
 begin
  if TInt(Item).Value>MaxValue then Exit;
  if Count>MaxCount then Exit;
  inherited Insert(Item);
 end;

{}
Procedure TBitBox.Initialize;
 begin
  Viewer:=V;Canvas:=C;
  FTop:=0;FLeft:=0;FWidth:=0;FHeight:=0;FRight:=0;FBottom:=0;
  Bits:=nil;
  NewBitmap:=nil;
  DynaY:=TDynaCol.Create(1);
  DynaX:=TDynaCol.Create(1);
//  Palette := CreateHalftonePalette(ViewDC);
  XKoeff:=1;YKoeff:=1;
  UseStandart:=False;
  UseStretch:=True;
  TransParent:=False;
 end;

Destructor TBitBox.Destroy;
var ec: Integer;
 begin
  inherited Destroy;
 { освобождаем новый растр }
  CloseView;
//  if Palette <> 0 then DeleteObject(Palette);
  if NewBitmap<>nil then
   begin
    FreeMem(NewBitmap,biNewWidth*NewInfo^.bmiHeader.biHeight-1);
    FreeMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
   end;
  DynaX.Free;DynaY.Free;
 end;

{-----------------------------------------------------------------}
{ Создание отображения                                            }
{-----------------------------------------------------------------}
Procedure TBitBox.CreateView;
begin
 CloseView;
 FileName:=FN;
 Bits:=nil;
{$IFDEF WIN64}
 try
 hf := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
  FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
 if hf=INVALID_HANDLE_VALUE then
  raise EAbort.CreateFmt('Ошибка открытия файла %d',[GetLastError]);


 hm := CreateFileMapping(hf, nil, PAGE_READWRITE, 0,0,nil);
 if hm=0 then
   raise EAbort.CreateFmt('Ошибка создания объекта отображения %d',[GetLastError]);

   pb := MapViewOfFile(hm, FILE_MAP_ALL_ACCESS, 0,0,0);
 if pb=nil then
  raise EAbort.CreateFmt('Ошибка отображения в память %d',[GetLastError]);

 bmFile := pBitmapFileHeader(pb);
 if (bmFile^.bfType<>$4D42) then
    raise EAbort.CreateFmt('Неверный формат файла %s',[FileName]);

 bits := pointer(@pByteArray(bmFile)^[bmFile^.bfOffBits]);
 bmi := pBmi(@pb^[SizeOf(TBitmapFileHeader)])^;
 biWidth3:=bmi.bmInfo.bmiHeader.biWidth;
  While biWidth3 mod 32<>0 do inc(biWidth3);
 biWidth3:=biWidth3 div 8;
 except
  on E:EAbort do
   begin
    CloseView;
    raise;
   end;
 end;
{$ENDIF}
end;

Procedure TBitBox.CloseView;
var ec: Integer;
begin
 if Bits<>nil then
 begin
{  if not UnMapViewOfFile(Pb) then
   begin
    ec:=GetLastError;
    Bits:=nil;
   // raise exception.Create('Ошибка закрытия файла '+FileName);
   end;
}
{$IFDEF WIN64}
  if (hm<>0) and (hm<>INVALID_HANDLE_VALUE) then  CloseHandle(hm);
  if (hf<>0) and (hf<>INVALID_HANDLE_VALUE) then  CloseHandle(hf);
{$ENDIF}
  Bits:=nil
 end;
end;

{-----------------------------------------------------------------}
{ Создание и отображение NewBitmap                                }
{-----------------------------------------------------------------}
function clip_rect( w, r : TRect ) : TRect;
 var res : TRect;
 begin
   if r.Left < 0 then res.Left := -r.Left else res.Left := 0;
  {}
   if r.Top < 0 then res.Top := -r.Top else res.Top := 0;
  {}
   if r.Right >= w.Right then
    begin
     res.Right := w.Right-r.Left;
    end else
     res.Right := r.Right-R.Left;
  {}
   if r.Bottom >= w.Bottom then
    begin
      res.Bottom := w.Bottom-r.Top;
    end else
      res.Bottom := r.Bottom-R.Top;
  {}
   Result := res
 end;

Function TBitBox.CreateBitmapInfo;
   var biWidth2,n:Integer;
     LeftLeft,LeftRight,RightLeft,RightRight:Integer;
  Function inLeft:boolean;
   begin Result:=(Left>0)end;
  Function inTop:boolean;
   begin Result:=(Top>0)end;
 {}
 begin
  Result:=False;
 // создаем новый растр
 // узнаем фрагмент
 if not Print then
  begin
   if Left>=Viewer.Width then Exit;
   if Top>=Viewer.Height then Exit;
   if Left+Width<=0 then Exit;
   if Top+Height<=0 then Exit;
  end else
  begin
   if Left>=RPrin.Right-RPrin.Left then Exit;
   if Top>=RPrin.Bottom-RPrin.Top then Exit;
   if Left+Width<=0 then Exit;
   if Top+Height<=0 then Exit;
  end;
 { освобождаем старый растр }
  if NewBitmap<>nil then
   begin
    FreeMem(NewBitmap,biNewWidth*NewInfo^.bmiHeader.biHeight);
    FreeMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
   end;
 {}
  R.Left:=Left;R.Top:=Top;R.Bottom:=Bottom;R.Right:=Right;
 if not Print then
  R:=Clip_Rect(Viewer.BoundsRect.Round,R) else
 begin
  R:=Clip_Rect(RPrin,R);
end;
  // вычисляем коэффициент увеличения
   XKoeff:=bmi.bminfo.bmiHeader.biWidth/Width;
   YKoeff:=bmi.bminfo.bmiHeader.biHeight/Height;
  // создаем новый растр
  GetMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
  NewInfo^:=pBitmapInfo(@bmi.bminfo)^;
 // устанавливаем параметры * Koeff
{}
 if XKoeff>1 then begin XKoeff:=1/XKoeff;ZoomFlag:=True; end else ZoomFlag:=False;
 if YKoeff>1 then begin YKoeff:=1/YKoeff;ZoomFlag:=True; end else ZoomFlag:=False;
{}
 if not ZoomFlag then
  biNewWidth:=Round((R.Right-R.Left)*XKoeff) else
  biNewWidth:=Round((R.Right-R.Left));
 {}
 if not ZoomFlag then
  NewInfo^.bmiHeader.biHeight:=Round((R.Bottom-R.Top)*YKoeff) else
  NewInfo^.bmiHeader.biHeight:=Round((R.Bottom-R.Top));
  NewInfo^.bmiHeader.biWidth:=biNewWidth;
 {}
 {}
//  With NewInfo^.bmiColors[0] do begin rgbBlue:=GetBValue(BackColor);rgbGreen:=GetGValue(BackColor);rgbRed:=GetRValue(BackColor);end;
    N:=1;
//  With NewInfo^.bmiColors[N] do begin rgbBlue:=GetBValue(Color);rgbGreen:=GetGValue(Color);rgbRed:=GetRValue(Color);end;
 {}
  While biNewWidth mod 32<>0 do inc(biNewWidth);
 {}
  NewInfo^.bmiHeader.biSizeImage:=biNewWidth div 8*NewInfo^.bmiHeader.biHeight;
 {}
  GetMem(NewBitmap,NewInfo^.bmiHeader.biSizeImage-1);
  FillChar(NewBitmap^,NewInfo^.bmiHeader.biSizeImage-1,0);
  Result:=True;
 end;

Procedure TbitBox.DrawNewBitmap;
 var I,J,N,M,CNB:Integer;CByte:Byte;Rect:TRect;
     Mem:TMemoryStream;
     lFile:tBitmapFileHeader;
     Bitmap:TBitmap;
 begin
  if Left<0 then Rect.Left:=0 else Rect.Left:=Left;
  if Top<0 then Rect.Top:=0 else Rect.Top:=Top;
  Rect.Right:=Rect.Left+(R.Right-R.Left);
  Rect.Bottom:=Rect.Top+(R.Bottom-R.Top);
(*  N:=0;
   with NewInfo^.bmiHeader do
   begin
    Bitmap:=TBitmap.Create;
    if Print then Writeln(biHeight,' ',biWidth);
    Bitmap.Height:=biHeight;
    Bitmap.Width:=biWidth;
    For I:=0 to biHeight-1 do
     begin
      CNB:=0;
      For M:=0 to biNewWidth div 8-1 do
       begin
        CByte:=pByteArray(NewBitmap)^[N];
        if CByte<>0 then
        For J:=7 downTo 0 do
         begin
         if (CByte and (1 shl J))=1 shl J then
          begin
           Windows.SetPixel(Bitmap.Canvas.Handle,Cnb,biHeight-I,Color);
          end;
          Inc(Cnb);
         end else Inc(Cnb,8);
        Inc(N);
       end;
     end;
    end;
   Canvas.CopyMode:=cmSrcAnd;
  if Stretch then
   Canvas.StretchDraw(Rect,Bitmap) else
   Canvas.Draw(Rect.Left,Rect.Top,Bitmap);
 Bitmap.Free;
*)
  Mem:=TMemoryStream.Create;
  lFile:= bmFile^;
  lFile.bfSize:=SizeOf(TBitmapFileHeader)+
                SizeOf(TBitMapInfoHeader)+sizeOf(TPaletteEntry)*2+NewInfo^.bmiHeader.biSizeImage; // размер файла в байтах
  mem.Write(lFile,SizeOf(lFile));
  mem.Write(NewInfo^,SizeOf(TBitmapInfoheader)+sizeOf(TPaletteEntry)*2);
  mem.Write(NewBitmap^,NewInfo^.bmiHeader.biSizeImage);
  mem.Position:=0;
  {}
   Bitmap:=TBitmap.Create;
   Bitmap.LoadFromStream(Mem);
  // Bitmap.Transparent:=True;
  if Stretch then
   Canvas.DrawBitmap(Bitmap,RectF(0,0,Bitmap.Width,Bitmap.Height),TRectF.Create(Rect),1)
  else
   Canvas.DrawBitmap(Bitmap,RectF(0,0,Bitmap.Width,Bitmap.Height),RectF(Rect.Left,Rect.Top,Rect.Left+Bitmap.Width,Rect.Top+Bitmap.Height),1);
   Bitmap.Free;
  Mem.Free;
 end;

Procedure TBitBox.ReplaceAndZoom;
 var Info:PBitmapInfo;Bitmap:Pointer;nWidth,nWidth8,oWidth8:Integer;
     I,J,N:Integer;XK,YK:Double;
 begin
  GetMem(Info,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
  BitMap:=CreateMemBitmap(Zoom.Right-Zoom.Left,Zoom.Bottom-Zoom.Top,Info,nWidth);
  if Bitmap=nil then Exit;
//  Writeln(Info^.bmiHeader.biWidth,' ',Info^.bmiHeader.biHeight);readln;
 XK:=Info^.bmiHeader.biWidth/NewInfo^.bmiHeader.biWidth;
 YK:=Info^.bmiHeader.biHeight/NewInfo^.bmiHeader.biHeight;
//  Writeln(XK:8:4,' ',1/XKoeff:8:4,' ',YK:8:4,' ',1/YKoeff:8:4);
//  XK:=XKoeff;YK:=YKoeff;
  nWidth8:=nWidth div 8;
  oWidth8:=biNewWidth div 8;
  N:=0;
   For I:=0 to Info^.bmiHeader.biHeight-1 do
    For J:=0 to Info^.bmiHeader.biWidth-1 do
     begin
//      if (Trunc(J/XK)>NewInfo^.bmiHeader.biWidth) or (Trunc(I/YK)>NewInfo^.bmiHeader.biHeight) then
      begin
//       writeln('X=',I,' Y=',J,' X1=',Trunc(J/XK),' Y1=',Trunc(I/YK),' ',NewInfo^.bmiHeader.biWidth,' ',NewInfo^.bmiHeader.biHeight);readln;
      end;
      inc(N);
      if GetbmPixel(NewInfo^,NewBitmap,oWidth8,Trunc(J/XK),Trunc(I/YK)) then
       begin
        SetbmPixel(Info^,BitMap,nWidth8,J,I,True);
       end;
     end;
//   Writeln(N,' ',NEwInfo.bmiHeader.biWidth*NEwInfo.bmiHeader.biHeight);
   FreeMem(NewBitmap,biNewWidth*NewInfo^.bmiHeader.biHeight-1);
   FreeMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
   NewBitMap:=BitMap;
   NewInfo:=Info;
   biNewWidth:=nWidth;
 end;


Procedure TBitBox.SetView1x1;
 var OldWidth,OldWidth8,OldSize,OldRight8:Integer;
     NewWidth,NewWidth8,NewSize:Integer;
     OldAddr,OldAddrBegin,OldAddrEnd:Integer;
     NewAddr,NewAddrBegin,NewAddrEnd:Integer;
    {}
     OldByte:Byte;
     NewByte:PByte;
    {}
     I,J,K:Integer;
    {}
     NewCX,NewCY:Integer;
     Rect:TRect;
     Dc,hBm,hDc,hBj,vDC:hBitmap;
     P:TPoint;
     Img:TImage;
     Mem:TMemoryStream;
     lFile:tBitmapFileHeader;
     Bitmap:TBitmap;
 begin
  if Left<0 then Rect.Left:=0 else Rect.Left:=Left;
  if Top<0 then Rect.Top:=0 else Rect.Top:=Top;
  with bmi.bminfo.bmiHeader do
   begin // старый растр
    // вычисляем ширину растра в битах
    OldWidth:=biWidth;
     While OldWidth mod 32<>0 do inc(OldWidth);
    // вычисляем ширину растра в байтах
    OldWidth8:=OldWidth div 8;
    biSizeImage:=OldWidth8*biHeight;
    OldSize:=biSizeImage;
    // правая граница старого растра в байтах
    OldRight8:=R.Right div 8+ord(R.Right mod 8<>0);
   end;
  with NewInfo^.bmiHeader do
   begin // старый растр
    NewWidth :=biNewWidth;    // в битах
    NewWidth8:=NewWidth div 8;// в байтах
    NewSize:=biSizeImage;
//    Writeln(OldSize,' ',NewSize);
   end;
  // считываем растр с первой строки
   For I:=R.Top to R.Bottom-1 do
    begin
     NewCY:=I-R.Top;
     OldAddrBegin:=(OldSize)-I*OldWidth8+R.Left div 8-OldWidth8;
     OldAddrEnd:=(OldSize)-I*OldWidth8+OldRight8-OldWidth8;
//      Writeln(OldSize,' ',R.Left div 8,' ',OldRight8,' ',OldAddrBegin,' ',OldAddrEnd);
      NewCX:=0;
      For OldAddr:=OldAddrBegin to OldAddrEnd-1 do
       begin
        // считываем байт старого растра
        OldByte:=pByteArray(Bits)^[OldAddr];
         For J:=7 downto 0 do
          begin
             if not ((OldByte and (1 shl J))=1 shl J) then
              begin
               // вычисляем адрес байта нового растра
                NewAddr:=NewSize-NewCY*NewWidth8+NewCX div 8-NewWidth8;
               // вычисляем адрес бита нового растра
               // устанавливаем биты в новом растре
               NewByte:=@pByteArray(NewBitmap)^[NewAddr];
               NewByte^:=NewByte^ or (1 shl J);
//               Writeln(OldAddr,' ',NewAddr);
//               Writeln(NewCX,' ',I);
//              SetPixel(ViewDc,NewCX+left,I+top,clMaroon);
              end;
           Inc(NewCx);
          end;
       end;
    {}
    {}
    end;
 if TransParent then
  DrawNewBitmap(False) else
{$IFDEF WIN64}
  SetDIBitsToDevice(ViewDc,Rect.Left,Rect.Top,R.Right-R.Left,R.Bottom-R.Top,
                             0,0,0,R.Bottom-R.Top,
                             NewBitmap, NewInfo^, DIB_RGB_COLORS);
{$ENDIF}
end;

Procedure TBitBox.SetViewZoom;
var Cnt,CX,CY,CNewX,Index,I,J,N,M,biWidth2,Dc,XBit,YBit:Integer;Dib:pBytearray;CByte:Byte;BT:PByte;
    Size:Integer;R2,R3:trect;
    Right_CX,XYBit,NewWidth,BeginLeft:Integer;
    Rect:TRect;
 begin
  Dc := ViewDC;
  with bmi.bminfo.bmiHeader do
  begin
  biWidth2:=biWidth;
  While biWidth2 mod 32<>0 do inc(biWidth2);
//    Writeln('U1',TimeToStr(Now));
    Size:=NewInfo^.bmiHeader.biSizeImage;
  R2:=R;
 // деление окна
   R.Top:=Round(R.Top*YKoeff);R.Bottom:=Trunc(R.Bottom*YKoeff);
   R.Left:=Round(R.Left*XKoeff);R.Right:=Trunc(R.Right*XKoeff);
  R3:=R;
 {}
   if R.Top=0 then N:=biSizeImage-1 else N:=(biSizeImage-1)-(R.Top)*(biWidth2 div 8);
 Cnt:=0;
 // пересчет координат по оси X
  I:=biWidth2-R.Left;
  R.Left :=I-(R.Right-R.Left)-1;
  R.Right:=I-1;
// ширина фрагмента в байтах
// Writeln('Koeff=',Koeff);
  NewWidth:=biNewWidth div 8;
  BeginLeft:=R.Left div 8;
   try
      For M:=R.Bottom-1 downTo R.Top do
       begin
        CY:=M;CX:=0;
        For I:=biWidth2 div 8-1 downto 0 do
         begin
//         if (N<0) or (N>biSizeImage) then Writeln('Old=',N);
          CByte:=pByteArray(Bits)^[N];
          For J:=0 to 7 do
           begin
            if (CX>=R.Left)and(CX<=R.Right) then
            begin
             if not ((CByte and (1 shl J))=1 shl J) then
              begin
               Right_CX:=(R.Right-(CX));
               Index:=Right_CX-(Right_CX div 8)*8;
               Index:=7-Index;
               // устанавливаем биты в новом растре
               XYBit:=Right_CX div 8+(CY-R.Top)*NewWidth;
//               if (XYBit<0) or (XYBit>Size) then Writeln('New=',XYBIT);
               Bt:=@pByteArray(NewBitmap)^[XYBit];
               Bt^:=Bt^ or (1 shl Index);
              //SetPixel(Dc,R.Right-Cx,R.Bottom-CY,clMaroon);
              end;
            end;
            Inc(CX);
            If CX>R.Right then Break;
           end;// For J:=7 downTo 0 do
         Dec(N);
        end;
       end;
     finally
     end;
//    Writeln('U2',TimeToStr(Now));
end;
  if Left<0 then Rect.Left:=0 else Rect.Left:=Left;
  if Top<0 then Rect.Top:=0 else Rect.Top:=Top;
{$IFDEF WIN64}
 if TransParent then
  begin
//   ReplaceAndZoom(R2,R);
//   R:=R2;
//   DrawNewBitmap(True);
   StretchDIBits(ViewDC,Rect.Left,Rect.Top,R2.Right-R2.Left,R2.Bottom-R2.Top,
    0,0,R.Right-R.Left,R.Bottom-R.Top,
    NewBitmap, NewInfo^, DIB_RGB_COLORS,
    SRCAND);
  end else
  begin
//   R:=R2;
   StretchDIBits(ViewDC,Rect.Left,Rect.Top,R2.Right-R2.Left,R2.Bottom-R2.Top,
    0,0,R.Right-R.Left,R.Bottom-R.Top,
    NewBitmap, NewInfo^, DIB_RGB_COLORS,
    SRCCOPY);
  end;
{$ENDIF}
end;

Procedure TBitBox.CreateDynaBits;
 var K,K3,K2:Double;K1:Integer;
     I:Integer;RP:TRect;Cnt:Integer;
/////////////////////     s: AnsiString[100];
 begin
//  Writeln('kdb');
  RP:=R;
  RP.Left:=Trunc(RP.Left*XKoeff);
  RP.Right:=Trunc(RP.Right*XKoeff);
  RP.Bottom:=Trunc(RP.Bottom*YKoeff);
  RP.Top:=Trunc(RP.Top*YKoeff);
//  Koeff:=Trunc(Koeff);
  K:=(XKoeff+YKoeff)/2;
  K1:=Trunc(K);
  K2:=Frac(K);
  If K2<>0 then K3:=1/K2; // группа столбцов для отображения 1/K2 столбцов
   Dynax.FreeAll;DynaY.FreeAll;
   DynaX.DynaSet(Rp.Right,R.Right-R.Left-1);
   DynaY.DynaSet(Rp.Bottom,R.Bottom-R.Top-1);
   If K2=0 then
    begin
     For I:=RP.Left to RP.Right do
      If I mod K1=0 then DynaX.Insert(TInt.Create(I));
     For I:=RP.Top to RP.Bottom-1 do
      If I mod K1=0 then DynaY.Insert(TInt.Create(I));
    end else
    begin
//     Writeln('=',R.Left);
     For I:=R.Left to R.Right-1 do
       DynaX.Insert(TInt.Create(Round(I*XKoeff)));
     For I:=R.Top to R.Bottom-1 do
       DynaY.Insert(TInt.Create(Round(I*YKoeff)));
   end;
{
   /////////////////////////
  log('========= class: ' + classname + ' =========');
  log(' X = %d', [DynaX.Count]);
    s := '';
    for i := 0 to DynaX.Count - 1 do
    begin
      s := s + ' ' + inttostr(TInt(dynax[i]).value);
      if length(s) >= 75 then
      begin
        log(s);
        s := ''
      end;
    end;
    if length(S) <> 0 then log(s);
    log(' Y = %d', [DynaY.Count]);
    s := '';
    for i := 0 to DynaX.Count - 1 do
    begin
      s := s + ' ' + inttostr(TInt(dynax[i]).value);
      if length(s) >= 75 then
      begin
        log(s);
        s := ''
      end;
    end;
    if length(S) <> 0 then log(s);
    LogFlush;

 }
{  write('y ');
  for i := 0 to DynaX.Count - 1 do
     write(TInt(dynax[i]).value, ' ');
  writeln;
 }
/////////////////////////


 end;

Procedure TBitBox.SetViewStretch;
 var OldWidth,OldWidth8,OldSize,OldRight8:Integer;
     NewWidth,NewWidth8,NewSize:Integer;
     OldAddr,OldAddrBegin,OldAddrEnd:Integer;
     NewAddr,NewAddrBegin,NewAddrEnd:Integer;
    {}
     OldByte:Byte;
     NewByte:PByte;
    {}
     I,J,K:Integer;
    {}
     OldCX:Integer;
     NewCX,NewCY:Integer;
     Rect,R2:TRect;
     YOfs,XOfs:Integer;
     Index:Integer;
 begin
  CreateDynaBits;
  R2:=R;
 // деление окна
   R.Top:=Round(R.Top*YKoeff);R.Bottom:=Trunc(R.Bottom*YKoeff);
   R.Left:=Round(R.Left*XKoeff);R.Right:=Trunc(R.Right*XKoeff);
 {
  Writeln(R.Bottom-R.Top,' ',R2.Bottom-R2.Top,' =',DynaY.Count,'= ',Koeff:8:2);
  Writeln(R.Right-R.Left,' ',R2.Right-R2.Left,' =',DynaX.Count,'= ',Koeff:8:2);
 }
  with bmi.bminfo.bmiHeader do
   begin // старый растр
    // вычисляем ширину растра в битах
    OldWidth:=biWidth;
     While OldWidth mod 32<>0 do inc(OldWidth);
    // вычисляем ширину растра в байтах
    OldWidth8:=OldWidth div 8;
    biSizeImage:=OldWidth8*biHeight;
    OldSize:=biSizeImage;
    // правая граница старого растра в байтах
    OldRight8:=R.Right div 8+ord(R.Right mod 8<>0);
   end;
  with NewInfo^.bmiHeader do
   begin // старый растр
    NewWidth :=biNewWidth;    // в битах
    NewWidth8:=NewWidth div 8;// в байтах
    NewSize:=biSizeImage;
//   Writeln('Cnt=',DynaY.Count,' biHeight=',biHeight);
   end;
  // считываем растр с первой строки
   For I:=DynaY.Count-1 downTo 0 do
    begin
     YOfs:=TInt(DynaY[I]).Value;
     OldAddr:=(OldSize)-(YOfs+1)*OldWidth8{+R.Left div 8-OldWidth8};
     OldCX:=0;
     NewCX:=0;
     XOfs:=TInt(DynaX[NewCX]).Value;
       For K:=0 to OldWidth8-1 do
         begin
{           if (OldAddr<0) or (OldAddr>bmi.bminfo.bmiHeader.biSizeImage) then
            begin
             Writeln(OldAddr,' ',bmi.bminfo.bmiHeader.biSizeImage,' ',YOfs,' ',biHeight);readln;
            end;}
           OldByte:=pByteArray(Bits)^[OldAddr];
              For J:=7 downto 0 do
               begin
                if OldCX=XOfs then
                 begin
                {}
                if not ((OldByte and (1 shl J))=1 shl J) then
                 begin
                  // вычисляем адрес байта нового растра
                  NewAddr:=NewSize-I*NewWidth8+NewCX div 8-NewWidth8;
                  Index:=NewCX-(NewCX div 8)*8;
                  Index:=7-Index;
                  // вычисляем адрес бита нового растра
                  // устанавливаем биты в новом растре
                  NewByte:=@pByteArray(NewBitmap)^[NewAddr];
                  NewByte^:=NewByte^ or (1 shl Index);
                 end;
                 {}
                  Inc(NewCX);
                if NewCX<DynaX.Count then
                   XOfs:=TInt(DynaX[NewCX]).Value;
                end;// else begin Writeln('No=',OldCX,'=',XOfs);end;
                Inc(OldCX);
               end;// For J:=7 downTo 0 do
             Inc(OldAddr);
            end;
      end;
// Exit;
  R:=R2;
  if Left<0 then Rect.Left:=0 else Rect.Left:=Left;
  if Top<0 then Rect.Top:=0 else Rect.Top:=Top;
 {}
{$IFDEF WIN64}
 if TransParent then begin
   StretchDIBits(ViewDC,Rect.Left,Rect.Top,R2.Right-R2.Left,R2.Bottom-R2.Top,
    0,0,R2.Right-R2.Left,R2.Bottom-R2.Top,
    NewBitmap, NewInfo^, DIB_RGB_COLORS,
    SRCAND) end else
  // DrawNewBitmap(False) else
   SetDIBitsToDevice(ViewDC,Rect.Left,Rect.Top,R2.Right-R2.Left,R2.Bottom-R2.Top,
                             0,0,0,R2.Bottom-R2.Top,
                             NewBitmap, NewInfo^, DIB_RGB_COLORS);
{$ENDIF}
end;

Procedure TBitBox.Paint;
// var OldP : hPalette;i : integer;P:Tpoint;
//     Koeff:Double;
begin
{  Canvas:=C;
  if (Width=0) or (Height=0) then Exit;
  if not Assigned(Bits) then Exit;
   OldP := SelectPalette(ViewDC, Palette, False);
   RealizePalette(ViewDC);
   SetStretchBltMode(ViewDC, STRETCH_DELETESCANS);
  if not CreateBitmapInfo then exit;
//  if Print then Writeln('Zoom=',ZoomFlag);
  if ZoomFlag then begin XKoeff:=1/XKoeff;YKoeff:=1/YKoeff;end;
  Koeff:=(XKOeff+YKoeff)/2;
  if Koeff=1 then begin SetViewStretch end else
   if Koeff<1 then begin SetViewZoom; end else begin SetViewStretch;end;
  if (i=0) or (i=GDI_ERROR) then
     begin
      Error :=GetLastError;
     end;
   SelectPalette(ViewDC, OldP, False);
{   With Canvas do
    begin
     MoveTo(R.Left,R.Top);LineTo(R.Right,R.Top);
     LineTo(R.Right,R.Bottom);LineTo(R.Left,R.Bottom);
     LineTo(R.Left,R.Top);
    end;
}
 end;

{-----------------------------------------------------------------}
{ Свойства                                                        }
{-----------------------------------------------------------------}
Function TBitBox.CreateNewBitmap;
 var N:Integer;lFile:TBitmapFileHeader;
     Buf:TBufSTream;
     Mem:Pointer;I:Integer;
 begin
  box.initBmi(fn, w, h);
  Result:=True;
  GetMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
  NewInfo^:=pBitmapInfo(@Box.bmi.bminfo)^;
 {}
  biNewWidth:=W;
  NewInfo^.bmiHeader.biHeight:=H;
  NewInfo^.bmiHeader.biWidth:=biNewWidth;
 {}
    N:=1;
//  With NewInfo^.bmiColors[N] do begin rgbBlue:=GetBValue(Box.BackColor);rgbGreen:=GetGValue(Box.BackColor);rgbRed:=GetRValue(Box.BackColor);end;
//  With NewInfo^.bmiColors[0] do begin rgbBlue:=GetBValue(Box.Color);rgbGreen:=GetGValue(Box.Color);rgbRed:=GetRValue(Box.Color);end;
  While biNewWidth mod 32<>0 do inc(biNewWidth);
  NewInfo^.bmiHeader.biSizeImage:=biNewWidth div 8*NewInfo^.bmiHeader.biHeight;


 { записываем в файл }
  try
  Buf:=TBufStream.InitFileStream(FN,fmCreate);
  try
  lFile:= Box.bmFile^;
  lFile.bfSize:=SizeOf(TBitmapFileHeader)+
                SizeOf(TBitMapInfoHeader)+SizeOf(TPaletteEntry)*2+NewInfo^.bmiHeader.biSizeImage; // размер файла в байтах
   Buf.Write(lFile,SizeOf(lFile));
   Buf.Write(NewInfo^,SizeOf(TBitmapInfoheader)+sizeOf(TPaletteEntry)*2);
 {}
  GetMem(Mem,biNewWidth div 8);
  FillChar(Mem^,biNewWidth div 8,255);
  For I:=0 to H-1 do
   Buf.Write(Mem^,biNewWidth div 8);
  FreeMem(Mem,biNewWidth div 8);
 {}
  finally
   Buf.Free;
  End;
  FreeMem(NewInfo,SizeOf(TBitmapInfoHeader)+sizeOf(TPaletteEntry)*2);
  Except
   Result:=False;
  end;
 end;

Function TBitBox.CreateMemBitmap;
 var N:Integer;LFile:TBitmapFileHeader;
     Buf:TBufSTream;
     Mem:Pointer;I:Integer;
 begin
  Result:=nil;
 try
  Info^:=pBitmapInfo(@bmi.bminfo)^;
 {}
  nWidth:=W;
  Info^.bmiHeader.biHeight:=H;
  Info^.bmiHeader.biWidth:=W;
 {}
    N:=1;
//  With Info^.bmiColors[N] do begin rgbBlue:=GetBValue(BackColor);rgbGreen:=GetGValue(BackColor);rgbRed:=GetRValue(BackColor);end;
//  With Info^.bmiColors[0] do begin rgbBlue:=GetBValue(Color);rgbGreen:=GetGValue(Color);rgbRed:=GetRValue(Color);end;
  While nWidth mod 32<>0 do inc(nWidth);
  Info^.bmiHeader.biSizeImage:=nWidth div 8*Info^.bmiHeader.biHeight;
 { записываем в файл }
  GetMem(Mem,Info^.bmiHeader.biSizeImage);
  FillChar(Mem^,Info^.bmiHeader.biSizeImage,0);
 Except
  Exit;
 end;
  Result:=Mem;
 end;

Function TBitBox.ViewDc;
 begin
  if Canvas<>nil then
 {$IFDEF MSWINDOWS}
  Result:=Canvas.Handle else
 {$ELSE}
  Result := 0 else
 {$ENDIF}
  Result:=PrinterDc;
 end;
{
Function TBitBox.PPM:Integer;
 begin
  if Assigned(Bits) then Result:=Round(bmi.bminfo.bmiHeader.biXPelsPerMeter) else Result:=-1;
 end;

Function TBitBox.DPI:Integer;
 begin
  if Assigned(Bits) then Result:=Round(bmi.bminfo.bmiHeader.biXPelsPerMeter/10000*254) else Result:=-1;
 end;
}
Function TBitBox.biWidth:Integer;
 begin
  if Assigned(Bits) then Result:= bmi.bminfo.bmiHeader.biWidth else Result:=-1;
 end;

Function TBitBox.biHeight:Integer;
 begin
  if Assigned(Bits) then Result:=bmi.bminfo.bmiHeader.biHeight else Result:=-1;
 end;

Procedure TBitBox.SetWidth(V:Integer);
 begin
  FWidth:=V;
  FRight:=FLeft+FWidth;
 end;

Procedure TBitBox.SetHeight(V:Integer);
 begin
  FHeight:=V;
  FBottom:=FTop+FHeight;
 end;

Procedure TBitBox.SetTop(V:Integer);
 begin
  FTop:=V;
  FBottom:=FTop+FHeight;
 end;

Procedure TBitBox.SetLeft(V:Integer);
 begin
  FLeft:=V;
  FRight:=FLeft+FWidth;
 end;

Function  TBitBox.GetbmPixel;
 var Addr,Index:Integer;CByte:Byte;
 begin
{  Result:=False;
  if (X>nWidth*8) or (Y>Info.bmiHeader.biHeight) then Exit;}
   Addr:=(Info.bmiHeader.biSizeImage)-Y*nWidth+X div 8-nWidth;
   Index:=7-(X-(X div 8)*8);
//   if (Addr<0) or (Addr>Info.bmiHeader.biSizeImage) then Writeln('GP ',Addr);
   CByte:=pByteArray(BitMap)^[Addr];
   Result:=((CByte and (1 shl Index))=1 shl Index);
 end;

Procedure TBitBox.SetbmPixel;
 var Addr,Index:Integer;CByte:PByte;
 begin
   Addr:=(Info.bmiHeader.biSizeImage)-Y*nWidth+X div 8-nWidth;
   Index:=7-(X-(X div 8)*8);
//   if (Addr<0) or (Addr>Info.bmiHeader.biSizeImage) then Writeln('SP ',Addr);
   CByte:=@pByteArray(BitMap)^[Addr];
   CByte^:=CByte^ or (1 shl Index);
 end;             
(*
Function  TBitBox.GetPixel(X,Y:Integer):integer;
 var Addr,Index:Integer;CByte:Byte;
 begin
{  Result:=false;
  if (Bits=nil) or (X>biWidth*8) or (Y>biHeight) then Exit;
   Addr:=(bmi.bmInfo.bmiHeader.biSizeImage)-Y*biWidth3+X div 8-biWidth3;
   Index:=7-(X-(X div 8)*8);
   CByte:=pByteArray(Bits)^[Addr];
//   Result:=not ((CByte and (1 shl Index))=1 shl Index);
}
 end;

Procedure TBitBox.SetPixel(X,Y:Integer;V:integer);
 var Addr,Index:Integer;CByte:PByte;
 begin
//  Writeln((Bits=nil) ,' ', (X>biWidth*8),' ', (Y>biHeight) );
  if (Bits=nil) or (X>=biWidth) or (Y>=biHeight) or (X<0) or (Y<0) then Exit;
   Addr:=(bmi.bmInfo.bmiHeader.biSizeImage)-Y*biWidth3+X div 8-biWidth3;
   Index:=7-(X-(X div 8)*8);
// if (Addr<0) or (Addr>bmi.bmInfo.bmiHeader.biSizeImage) then begin Writeln(Addr,' ' ,x,' ',Y,' ',biWidth,' ',biHeight);readln;end;
   CByte:=@pByteArray(Bits)^[Addr];
//   CByte^:=CByte^ or (1 shl Index);
     CByte^:=CByte^ and not(1 shl Index);
//   Writeln('Ok');

 end;
*)

procedure Register;
begin
  RegisterComponents('Version', [TBitBox]);
end;

procedure TBitBox.AfterTrans;
begin

end;

procedure TBitBox.SetBackColor(const Value: FixedInt);
begin
  FBackColor := Value;
end;

procedure TBitBox.SetColor(const Value: FixedInt);
begin
  FColor := Value;
end;

procedure TBitBox.initBmi(const fn: AnsiString; w, h: integer);
begin

end;

begin
end.
