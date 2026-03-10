unit RectLot;

interface uses FMX.Controls, Collect, HatchLot, WpForm0, Windows, FMX.Graphics, Resource, EcLot,
               WpRects, Classes, TwgDraw, newProcs, WptOle, Selector,
               OleNew;
                              
type                                                                     
 TRectLot = class(THatchLot)
   Function   PointIn(Twf:TTwigsCollect;X,Y:Double;Param:Integer = -1):Boolean;override;
  //                                                     
   Procedure  FillDraw(Twf:TTwigsCollect;Handle:hDc);override;
   Procedure  FillDraw2(Twf:TTwigsCollect;Handle:hDc);override;
   Procedure  DrawRopLines(TWF:TTwigsCollect;PaintLines:Boolean=true);override;
   Procedure  DrawRopLines2(TWF:TTwigsCollect);override;
   Procedure  DevDrawRopLines(TWF:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer);override;
   Procedure  DevDrawRopLines2(TWF:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer);override;
   Procedure  DevDraw(Twf:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer);override;
   Procedure  DevDraw2(Twf:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer);override;
  //
   Function DrawObject(TWF:TTwigsCollect):byte;virtual;
   Function DevDrawObject(Twf:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer):byte;virtual;
 end;                            

const RasterPlo = 9000000000;

type
 TSpatialData = record
  bih:TBitmapInfoHeader;
  Width,Height:Double;
  Scale:Double;
 end;

 TRasterLot = class(TRectLot)
  FilePath:String;
  FileName:String;
  Obj:IRasterObject;
  Opened:Boolean;
  Checked:Boolean;
 //
  SpatialData:TSpatialData;
 //
  XRaster,YRaster:Double;
  Constructor   Create(CH:TResource;FilePath_,FileName_:String);
  Destructor Destroy;override;
  Procedure AssignLot(Lot:TLot;AddAllCollections:Boolean);override;
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
 //
  Procedure  DrawRopLines(TWF:TTwigsCollect;PaintLines:Boolean=true);override;
  Procedure  DrawRopLines2(TWF:TTwigsCollect);override;
 //
  Function LoadObject:Boolean;
  Function GetSpatialData: Byte; // возвращает 1, если необходимо запросить DPI
  Function RealHeight:Double;
  Function RealWidth:Double;
  Procedure CreateSpatialTwig(TWF:TTwigsCollect;var Twig:TTwigRect); // создание сегмента-границы прямоугольника растра
 //
  Procedure DrawMiddleRect(Dc:hDc;Rect:TRect);
  Function DrawObject(TWF:TTwigsCollect):byte;override;
  Function DevDrawObject(Twf:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer):byte;override;
 //
  Function  PointIn   (Twf:TTwigsCollect;X,Y:Double;Param:Integer=-1):Boolean;override;
  Function  PointInRaster(Twf:TTwigsCollect;X,Y:Double):Boolean;
  Function  SetSqwear(TWF:TTwigsCollect):SmallInt;override;
  Procedure GetObjectProps(propNames, propValues, propTypes: TStrings;Data:Pointer = nil);override;
  Procedure GetPropMerge(Obj: TTD; propNames, propValues,propTypes: TStrings);override;
  Function rasterColor:TRGBRec;
  Function rasterBG:TRGBRec;
  Function rasterGlass:boolean;
 //
  Function SetProperty(propName:String;propValue:String;Obj:TTD = nil):boolean;override;
  Procedure DrawRegions(Canvas:TCanvas);
 //
  Function Brightness:Integer;
 //
//  Procedure RasterPoint(TWF:TTwigsCollect;X,Y:Double;var X,Y:Integer);
//  Procedure GeoPoint(TWF:TTwigsCollect;X,Y:Integer;var X,Y:Double);
  Procedure Rotate(TWF:TTwigsCollect;X,Y,Angle:Double);
  Procedure Rescale(TWF:TTwigsCollect;var X,Y:Double;Scale:Double);
  Function GetHint(P:Pointer=nil):String;Override;
end;

 TOleLot = class(TRectLot)
  Ole:TGeoOle;
  Constructor Create(CH:TResource;BinaryData_:String;Sect_:TSect);
  Constructor CreateOleContainer(CH:TResource;OleCont_:TOleContainer;Sect_:TSect);
  Procedure AssignLot(Lot:TLot;AddAllCollections:Boolean);override;
  Destructor Destroy;override;
 //
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
 //
  Procedure CreateSpatialTwig(TWF:TTwigsCollect;var Twig:TTwigRect); // создание сегмента-границы прямоугольника объекта
 //
  Function DrawObject(TWF:TTwigsCollect):byte;override;
  Function DevDrawObject(Twf:TTwigsCollect;XGeoCent,YGeoCent:Extended;XPrintcent,YPrintCent:Integer):byte;override;
 end;

implementation uses SysUtils, WpTwigs, TwgColle, WptForm,      
                    ustnGlobalSettings, EcDot, Polygons;

{ TRectLot }

procedure TRectLot.DrawRopLines(TWF: TTwigsCollect; PaintLines: Boolean);
begin
 inherited DrawRopLines(TWF,PaintLines);
end;

procedure TRectLot.DrawRopLines2(TWF: TTwigsCollect);
begin
 inherited DrawRopLines2(TWF);
end;

procedure TRectLot.FillDraw(Twf: TTwigsCollect; Handle: hDc);
begin
 If DrawObject(TWF) = 0 then DrawRopLines(Twf,False);
end;

procedure TRectLot.FillDraw2(Twf: TTwigsCollect; Handle: hDc);
begin
 If DrawObject(TWF) = 0 then DrawRopLines(Twf,False);
end;

procedure TRectLot.DevDrawRopLines(TWF: TTwigsCollect; XGeoCent, YGeoCent: Extended; XPrintcent, YPrintCent: Integer);
begin
 DevDrawObject(TWF, XGeoCent, YGeoCent, XPrintcent, YPrintCent);
end;

procedure TRectLot.DevDrawRopLines2(TWF: TTwigsCollect; XGeoCent, YGeoCent: Extended; XPrintcent, YPrintCent: Integer);
begin
 DevDrawObject(TWF, XGeoCent, YGeoCent, XPrintcent, YPrintCent);
end;

procedure TRectLot.DevDraw(Twf: TTwigsCollect; XGeoCent, YGeoCent: Extended; XPrintcent, YPrintCent: Integer);
begin
 DevDrawObject(TWF, XGeoCent, YGeoCent, XPrintcent, YPrintCent);
end;

procedure TRectLot.DevDraw2(Twf: TTwigsCollect; XGeoCent,YGeoCent: Extended; XPrintcent, YPrintCent: Integer);
begin
 DevDrawObject(TWF, XGeoCent, YGeoCent, XPrintcent, YPrintCent);
end;

function TRectLot.PointIn(Twf: TTwigsCollect; X, Y: Double;Param:Integer=-1): Boolean;
var P:PCollection;
begin
 P:=Zeros;
 Zeros:=PCollection.Create(1);
 Result:=inherited PointIn(Twf,X,Y);
 Zeros.Free;Zeros:=P;
end;

function TRectLot.DrawObject(TWF: TTwigsCollect):byte;
begin
 Result:=0;
end;

function TRectLot.DevDrawObject(Twf: TTwigsCollect; XGeoCent,
  YGeoCent: Extended; XPrintcent, YPrintCent: Integer): byte;
begin
 Result:=0;
end;

{ TRasterLot }

constructor TRasterLot.Create(CH: TResource; FilePath_, FileName_: String);
begin
 inherited Create(CH);
 FilePath:=FilePath_;FileName:=FileName_;
 Checked:=True;
end;

destructor TRasterLot.Destroy;
begin
 inherited;
 Obj:=nil;
end;

procedure TRasterLot.AssignLot(Lot: TLot; AddAllCollections: Boolean);
begin
 inherited;
 FilePath:=TRasterLot(Lot).FilePath;
 FileName:=TRasterLot(Lot).FileName;
 Obj:=TRasterLot(Lot).Obj;
 Opened:=TRasterLot(Lot).Opened;
 SpatialData:=TRasterLot(Lot).SpatialData;
 Checked:=True;
end;

constructor TRasterLot.Load(Stream: TBufStream);
begin
 inherited;
 FilePath:=Stream.ReadString;
 FileName:=Stream.ReadString;
 Stream.Read(SpatialData,SizeOf(SpatialData));
 Stream.Read(Checked,SizeOf(Checked));
 LoadObject;
end;

procedure TRasterLot.Store(Stream: TBufStream);
begin
  inherited;
 Stream.WriteString(FilePath);
 Stream.WriteString(FileName);
 Stream.Write(SpatialData,SizeOf(SpatialData));
 Stream.Write(Checked,SizeOf(Checked));
end;

procedure TRasterLot.DrawRopLines(TWF: TTwigsCollect; PaintLines: Boolean);
begin
 If GetTwig(TWF,0) = nil then Exit;
 GetTwig(TWF,0).Inv:=Inv;GetTwig(TWF,0).StColor:=LotLineColor;GetTwig(TWF,0).Draw;
end;

procedure TRasterLot.DrawRopLines2(TWF: TTwigsCollect);
begin
 If GetTwig(TWF,0) = nil then Exit;
 GetTwig(TWF,0).Inv:=Inv;GetTwig(TWF,0).StColor:=LotLineColor;GetTwig(TWF,0).Draw;
end;

function TRasterLot.LoadObject:Boolean;              
begin
 Screen.Cursor:=crHourGlass;
 try
  Obj:=CoRasterObject.Create();
 except
  Opened:=False;Obj:=nil;
 end;
 {}
 try
  Opened:=Obj.OpenEx(FilePath+'\'+FileName,1);
 except Opened:=False;end;                   
 Result:=Opened;                                           
 If not Opened then Obj:=nil;                         
 Screen.Cursor:=crDefault;                   
end;                                 

function TRasterLot.GetSpatialData: Byte;
var FS:TFileStream;bfh: TBitmapFileHeader;
                   bih: TBitmapInfoHeader;
begin
 Result:=0;                                           
 If Obj = nil then exit;
 If not Opened then exit;                           
 FS := TFileStream.Create(Obj.GetTempFileName, fmOpenRead or fmShareDenyWrite);
 try                                               
  FS.Read(bfh, sizeof(bfh));
  FS.Read(bih, sizeof(bih));
  Writeln('Obj=',Obj.GetSrcFileType);
  If bih.biXPelsPerMeter = 0 then begin                              
   Result:=1;
   bih.biXPelsPerMeter:=Round(72/0.0254);
  end;                                                     
  SpatialData.bih:=bih;                          
  If Obj.GetSrcFileType in [0,4,3] then begin
   SpatialData.Width:=bih.biWidth/bih.biXPelsPerMeter*100;
   SpatialData.Height:=bih.biHeight/bih.biXPelsPerMeter*100;
  end else                              
  If Obj.GetSrcFileType = 2 then begin
   SpatialData.Width:=bih.biWidth/(bih.biXPelsPerMeter*4.166)*100;
   SpatialData.Height:=bih.biHeight/(bih.biYPelsPerMeter*4.166)*100;
  end else begin
   SpatialData.Width:=bih.biWidth/(bih.biXPelsPerMeter*100/2.54)*100;
   SpatialData.Height:=bih.biHeight/(bih.biXPelsPerMeter*100/2.54)*100;
  end;
  SpatialData.Scale:=100;
 finally FS.free; end;
 Result:=2;
end;

procedure TRasterLot.DrawMiddleRect(Dc: hDc; Rect: TRect);
var rW,rH:Integer;Scale:Double;
begin
// рисуем изображение в прямоугольнике - по центру
 If not Opened then Exit;
 rW:=Rect.Right - Rect.Left;rH:=Rect.Bottom - Rect.Top;
 If rW / SpatialData.bih.biWidth < rH / SpatialData.bih.biHeight then Scale:=rW / SpatialData.bih.biWidth else
                                                                      Scale:=rH / SpatialData.bih.biHeight;
 Obj.DrawToDC(Dc, 0, 0, rW , rH, 0, 0, Scale, 0)
end;

(*function TRasterLot.DrawObject(TWF: TTwigsCollect): byte;
var Twig:TTwigRect;Scale:Double;propColor,propBG:String;
    I,Color,BG:Integer;Rgn:hRgn;
    ROperation:Integer;inCount,exCount:Integer;
Procedure PaintInvertPolygon;
var Rop:Integer;
begin
 Rop:=SetRop2(GCanvas.Handle,R2_Not);
  Windows.PolyGon(GCanvas.Handle,LotRgn,I);
 SetRop2(GCanvas.Handle,Rop);
end;
Procedure ClipRegions;
var I:Integer;
Function ClipRegion(Region:TPolyTwig;ClipRegionFlag:Integer):Integer;
var Count:Integer;Col:PCollection;
    XMin1,YMin1,XMax1,YMax1:Double;Rop:Integer;
    Rgn:hRgn;
begin
Result:=0;
Col:=PCollection.Create(1);
Count:=ClipPolygon(Points,XMin1,YMin1,XMax1,YMax1);
If Count<>-1 then begin
 Rgn:=CreatePolygonRgn(LotRgn,Count,Winding);
  ExtSelectClipRgn(GCanvas.Handle,Rgn,ClipRegionFlag);
 DeleteObject(Rgn);
 Result:=1;
end;
Col.DeleteAll;Col.Free;
end;
begin
// создаем области отсечения
 exCount:=0;inCount:=0;
 If noClipping then Exit;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 1 then begin Inc(exCount,ClipRegion(Zero[I],RGN_XOR));end;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 0 then begin If inCount = 0 then Inc(InCount,ClipRegion(Zero[I],RGN_And)) else Inc(inCount,ClipRegion(Zero[I],RGN_OR));
//  inc(inCount);
 end;
 Result:=exCount+inCount;
end;
begin
 Result:=1;
 If (Closed<>1) or (TypeLot = 254) or (not Checked) then exit;
  Twig:=TTwigRect(GetTwig(TWF,0));Twig.Proportional:=True;Twig.Inversion:=True;
 If Opened then begin
  Twig:=TTwigRect(GetTwig(TWF,0));Twig.Proportional:=True;Twig.Inversion:=True;
 // выбор масштаба
  Scale:=Twig.Width/XGeoRasst(SpatialData.bih.biWidth);
  If SpatialData.bih.biBitCount = 1 then begin
   With rasterColor do Obj.SetPaletteColor(0,wbColor(RGB(ARGB[1],ARGB[2],ARGB[3])));
   With rasterBG do begin
    Obj.SetPaletteColor(1,RGB(ARGB[1],ARGB[2],ARGB[3]));
    If GlobalSettings.Settings.gsWindowColor = clBlack then
     If RGB(ARGB[1],ARGB[2],ARGB[3])=clWhite then
      Obj.SetPaletteColor(1,notCol(RGB(ARGB[1],ARGB[2],ARGB[3])));
   end;
  end else begin
  end;
  SpatialData.Scale:=Twig.Width/SpatialData.Width*100;
  // управление палитрой
  If rasterGlass then begin
   If GlobalSettings.Settings.gsWindowColor = clBlack then ROperation:=SRCInvert else ROperation := SRCInvert;
   // отсечение по сегменту
   ClipRegions;
   If inCount = 0 then begin
    I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax);
    If I = -1 then exit else begin Rgn:=CreatePolygonRgn(LotRgn,I,Winding);ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_And);DeleteObject(Rgn);end;
   end;
    Obj.DrawToDC2(GCanvas.Handle,0,0,GPRect.Right,GPRect.Bottom,XPix(Twig[0].XDot),YPix(Twig[0].YDot),Scale,-Twig.Angle*180/Pi,False,ROperation,HalfTone);
//    except end;
    If GlobalSettings.Settings.gsWindowColor = clWhite then begin
     I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax);
     If I<>-1 then PaintInvertPolygon;
    end;
   ExtSelectClipRgn(GCanvas.Handle,0,Rgn_Copy);
  end else begin
   ClipRegions;
   If inCount = 0 then begin I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax);If I = -1 then exit;end;
   Obj.DrawToDC(GCanvas.Handle,0,0,GPRect.Right,GPRect.Bottom,XPix(Twig[0].XDot),YPix(Twig[0].YDot),Scale,-Twig.Angle*180/Pi);//False,//,SRCCopy,HalfTone);
//   except end;
   ExtSelectClipRgn(GCanvas.Handle,0,Rgn_Copy);
  end;
 end;
 Twig.Inv:=Inv;Twig.StColor:=LotLineColor;Twig.Draw;
end;
*)
function TRasterLot.DrawObject(TWF: TTwigsCollect): byte;
var Twig:TTwigRect;Scale:Double;propColor,propBG:String;
    I,Color,BG:Integer;Rgn:hRgn;
    ROperation:Integer;inCount,exCount:Integer;
Procedure PaintInvertPolygon;
var Rop:Integer;
begin
 Rop:=SetRop2(GCanvas.Handle,R2_Not);
  Windows.PolyGon(GCanvas.Handle,LotRgn,I);
 SetRop2(GCanvas.Handle,Rop);
end;
Procedure ClipRegions;
var I:Integer;
Function ClipRegion(Region:TPolyTwig;ClipRegionFlag:Integer):Integer;
var Count:Integer;Col:PCollection;
    XMin1,YMin1,XMax1,YMax1:Double;Rop:Integer;
    Rgn:hRgn;
begin
Result:=0;
Col:=PCollection.Create(1);
Region.GetPoints(Col,XMin1,YMin1,XMax1,YMax1);
Count:=ClipPolygon(Col,XMin1,YMin1,XMax1,YMax1);
If Count<>-1 then begin
 Rgn:=CreatePolygonRgn(LotRgn,Count,Winding);
  ExtSelectClipRgn(GCanvas.Handle,Rgn,ClipRegionFlag);
 DeleteObject(Rgn);
 Result:=1;
end;
Col.DeleteAll;Col.Free;
end;
begin
// создаем области отсечения
 exCount:=0;inCount:=0;
 If noClipping then Exit;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 1 then begin Inc(exCount,ClipRegion(Zero[I],RGN_XOR));end;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 0 then begin If inCount = 0 then Inc(InCount,ClipRegion(Zero[I],RGN_And)) else Inc(inCount,ClipRegion(Zero[I],RGN_OR));
//  inc(inCount);
 end;
 Result:=exCount+inCount;
end;
procedure DrawPolyGon;
const C=100;
var GPBrush:TGPTextureBrush;GPSolid:TGPSolidBrush;Count,J:Integer;D:TDot;
    RGB:TRGBRec;Color:Integer;Percent:Byte;
begin
 InsClipDotsParall(TWF);
 With GRect do
  Clip_Polygon(Left-XGeoRasst(C),Bottom-XGeoRasst(C),Right+XGeoRasst(C),
                              Top+XGeoRasst(C),Points);
  For J:=0 to Points.Count-1 do begin
    D:=Points[J];LotRgn[J+1].X:=XPix(D.XDot);LotRgn[J+1].Y:=YPix(D.YDot);
  end;
  If Brightness>0 then begin Color:=clWhite;Percent:=Trunc((Brightness/100)*255); end else begin Color:=clBlack;Percent:=Trunc((Abs(Brightness)/100)*255);end;
  GPSolid:=TGPSolidBrush.Create(MakeColor(Percent,GetRValue(Color),GetGValue(Color),GetBValue(Color)));
   GDIGraphics.FillPolyGon(GPSolid,@LotRgn,Points.Count);
  GPSolid.Free;
 Points.Free;
end;
begin
 Result:=1;
If Obj = nil then exit;
 If (Closed<>1) or (TypeLot = 254) or (not Checked) then exit;
  Twig:=TTwigRect(GetTwig(TWF,0));Twig.Proportional:=True;Twig.Inversion:=True;
//  Opened:=True;
 If Opened then begin
//  Twig:=TTwigRect(GetTwig(TWF,0));Twig.Proportional:=True;Twig.Inversion:=True;
 // выбор масштаба
  Scale:=Twig.Width/XGeoRasst(SpatialData.bih.biWidth);
  If SpatialData.bih.biBitCount = 1 then begin
   With rasterColor do Obj.SetPaletteColor(0,wbColor(RGB(ARGB[1],ARGB[2],ARGB[3])));
   With rasterBG do begin
    Obj.SetPaletteColor(1,RGB(ARGB[1],ARGB[2],ARGB[3]));
    If GlobalSettings.Settings.gsWindowColor = clBlack then
     If RGB(ARGB[1],ARGB[2],ARGB[3])=clWhite then
      Obj.SetPaletteColor(1,notCol(RGB(ARGB[1],ARGB[2],ARGB[3])));
   end;
  end else begin
  end;
  SpatialData.Scale:=Twig.Width/SpatialData.Width*100;
  // управление палитрой
  If rasterGlass then begin
   If GlobalSettings.Settings.gsWindowColor = clBlack then ROperation:=SRCInvert else ROperation := SRCInvert;
   // отсечение по сегменту
   ClipRegions; 
   If inCount = 0 then begin
    I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax);
    If I = -1 then exit else begin Rgn:=CreatePolygonRgn(LotRgn,I,Winding);ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_And);DeleteObject(Rgn);end;
   end;
    Obj.DrawToDC2(GCanvas.Handle,0,0,GPRect.Right,GPRect.Bottom,XPix(Twig[0].XDot),YPix(Twig[0].YDot),Scale,-Twig.Angle*180/Pi,False,ROperation,HalfTone);
//    except end;
    If GlobalSettings.Settings.gsWindowColor = clWhite then begin
     I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax);
     If I<>-1 then PaintInvertPolygon;
    end;
   ExtSelectClipRgn(GCanvas.Handle,0,Rgn_Copy);
  end else begin
   ClipRegions;
   If inCount = 0 then begin I:=ClipPolygon(GetTwig(TWF,0).TwigCoord,XMin,YMin,XMax,YMax);If I = -1 then exit;end;
   Obj.DrawToDC(GCanvas.Handle,0,0,GPRect.Right,GPRect.Bottom,XPix(TDot(Twig.TwigCoord.At(0)).XDot),YPix(TDot(Twig.TwigCoord.At(0)).YDot),Scale,-Twig.Angle*180/Pi);//False,//,SRCCopy,HalfTone);
//   except end;
   If Brightness<>0 then begin
    // рисуем поверх полигон с яркостью
    DrawPolygon;
   end;
   ExtSelectClipRgn(GCanvas.Handle,0,Rgn_Copy);
  end;
 end;
 Twig.Inv:=Inv;Twig.StColor:=LotLineColor;Twig.Draw;
end;

function TRasterLot.DevDrawObject(Twf: TTwigsCollect; XGeoCent, YGeoCent: Extended; XPrintcent, YPrintCent: Integer): byte;
var Twig:TTwigRect;Scale:Double;propColor,propBG:String;
    I,Color,BG:Integer;Rgn:hRgn;
    ROperation:Integer;inCount,exCount:Integer;
Procedure PaintInvertPolygon;
var Rop:Integer;
begin
 Rop:=SetRop2(PrinterDC,R2_Not);
  Windows.PolyGon(PrinterDc,LotRgn,I);
 SetRop2(PrinterDc,Rop);
end;
Procedure ClipRegions;
var I:Integer;
Function ClipRegion(Region:TPolyTwig;ClipRegionFlag:Integer):Integer;
var Count:Integer;Col:PCollection;
    XMin1,YMin1,XMax1,YMax1:Double;Rop:Integer;
    Rgn:hRgn;
begin
Result:=0;
Col:=PCollection.Create(1);
Region.GetPoints(Col,XMin1,YMin1,XMax1,YMax1);
Count:=ClipPolygon(Col,XMin1,YMin1,XMax1,YMax1,True);
If Count<>-1 then begin
 Rgn:=CreatePolygonRgn(LotRgn,Count,Winding);
  ExtSelectClipRgn(PrinterDC,Rgn,ClipRegionFlag);
 DeleteObject(Rgn);
 Result:=1;
end;
Col.DeleteAll;Col.Free;
end;
begin
// создаем области отсечения
 exCount:=0;inCount:=0;
 If noClipping then Exit;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 1 then begin Inc(exCount,ClipRegion(Zero[I],RGN_XOR));end;
 For I:=0 to Zeros.Count-1 do If Zero[I].Twig[0].Closed<>0 then If Zero[I].Twig[0].Opr = 0 then begin If inCount = 0 then Inc(InCount,ClipRegion(Zero[I],RGN_And)) else Inc(inCount,ClipRegion(Zero[I],RGN_OR));
//  inc(inCount);
 end;
 Result:=exCount+inCount;
end;
begin
 Result:=1;
 If (Closed<>1) or (TypeLot = 254) or (not Checked) then exit;
 If Opened then begin
  Twig:=TTwigRect(GetTwig(TWF,0));Twig.Proportional:=True;
 // выбор масштаба
  Scale:=Twig.Width/PrnXGeoRasst(SpatialData.bih.biWidth);
  If SpatialData.bih.biBitCount = 1 then begin
   With rasterColor do Obj.SetPaletteColor(0,wbColor(RGB(ARGB[1],ARGB[2],ARGB[3])));
   With rasterBG do begin
    Obj.SetPaletteColor(1,RGB(ARGB[1],ARGB[2],ARGB[3]));
    If GlobalSettings.Settings.gsWindowColor = clBlack then
     If RGB(ARGB[1],ARGB[2],ARGB[3])=clWhite then
      Obj.SetPaletteColor(1,notCol(RGB(ARGB[1],ARGB[2],ARGB[3])));
   end;
  end else begin
  end;
  // управление палитрой
  If rasterGlass then begin
   If GlobalSettings.Settings.gsWindowColor = clBlack then ROperation:=SRCInvert else ROperation := SRCInvert;
   // отсечение по сегменту
   ClipRegions;
   If inCount = 0 then begin
    I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax,True);
    If I = -1 then exit else begin Rgn:=CreatePolygonRgn(LotRgn,I,Winding);ExtSelectClipRgn(PrinterDC,Rgn,RGN_And);DeleteObject(Rgn);end;
   end;
    Obj.DrawToDC2(PrinterDC,0,0,PrnXPix(GSector.Right),PrnYPix(GSector.Bottom),PrnXPix(Twig[0].XDot),PrnYPix(Twig[0].YDot),Scale,-Twig.Angle*180/Pi,False,ROperation,HalfTone);
//    except end;
    If GlobalSettings.Settings.gsWindowColor = clWhite then begin
     I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax,True);
     If I<>-1 then PaintInvertPolygon;
    end;
   ExtSelectClipRgn(PrinterDC,0,Rgn_Copy);
  end else begin
   ClipRegions;
   If inCount = 0 then begin I:=ClipPolygon(GetTwig(TWF,0).Coord,XMin,YMin,XMax,YMax,True);If I = -1 then exit;end;
   Obj.DrawToDC(PrinterDC,0,0,PrnXPix(GSector.Right),PrnYPix(GSector.Bottom),PrnXPix(Twig[0].XDot),PrnYPix(Twig[0].YDot),Scale,-Twig.Angle*180/Pi);//False,//,SRCCopy,HalfTone);
//   except end;
   SelectClipRgn(PrinterDc,PrinterClipRgn);
  end;
 end;
// Twig.Inv:=Inv;Twig.StColor:=LotLineColor;Twig.Draw;
end;

procedure TRasterLot.CreateSpatialTwig(TWF: TTwigsCollect; var Twig: TTwigRect);
var Sect:TSect;
begin
 With SpatialData do begin
  If Twig = nil then begin Sect.Left:=GRect.Left;Sect.Top:=GRect.Bottom;end else begin
   Sect.Left:=Twig[0].XDot;Sect.Top:=Twig[0].YDot;
  end;
  Sect.Right:=Sect.Left+RealWidth;Sect.Bottom:=Sect.Top+RealHeight;
  If Twig = nil then begin
   Twig:=TTwigRect.Create(0,@Sect);Twig.Proportional:=True;Twig.Inversion:=True;
   TWF.Insert(TWG_Twig,Twig);
   Coord.FreeAll;Coord.Insert(TLong.Create(TWF.TwigsCount-1));
  end else begin
   Sect.Right:=RealWidth;Sect.Bottom:=RealHeight;
   Twig.Sect:=Sect;Twig.Proportional:=True;Twig.Inversion:=True;
  end;
  SetMinMax(TWF);
 end;
end;

function TRasterLot.RealHeight: Double;
begin
 With SpatialData do Result:=(Height*10)*Scale/1000;
end;

function TRasterLot.RealWidth: Double;
begin
 With SpatialData do Result:=(Width*10)*Scale/1000;
end;

function TRasterLot.PointIn(Twf: TTwigsCollect; X, Y: Double;Param:Integer): Boolean;
begin
 TypeLot:=2;
 try
  Result:=inherited PointIn(Twf,X,Y)
 finally TypeLot:=2;end;
end;                                                  

function TRasterLot.SetSqwear(TWF: TTwigsCollect): SmallInt;
begin
//
end;

procedure TRasterLot.GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);
begin
  PropNames.Add('Цвет');PropNames.Add('Цвет заливки');PropNames.Add('Яркость');PropNames.Add('Прозрачность');PropNames.Add('Масштаб листа');
  If PropTypes<>nil then begin propTypes.Add('Color');propTypes.Add('Color');PropTypes.Add('Percents');propTypes.Add('Boolean');propTypes.Add('Integer');end;
  If propValues<>nil then begin propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Цвет заливки'));propValues.Add(GetProperty('Яркость'));propValues.Add(GetProperty('Прозрачность'));propValues.Add(GetProperty('Масштаб листа'));end;
end;

procedure TRasterLot.GetPropMerge(Obj:TTD;propNames,propValues,propTypes: TStrings);
var I,Index:Integer;
begin
 If propNames.Count=0 then begin
  GetObjectProps(propNames,propValues,propTypes);
 end else begin
  If (Obj is Self.ClassType) then Exit;
 //
  Index:=propNames.IndexOf('Цвет');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Цвет заливки');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Яркость');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Прозрачность');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Масштаб листа');If Index<>-1 then propNames.Objects[Index]:=Self;
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
 end;
end;

function TRasterLot.rasterBG: TRGBRec;
var S:String;Res:Integer;
begin
 Result.ARGB[1]:=ClassHandle.RGB.ARGB[3];Result.ARGB[2]:=ClassHandle.RGB.ARGB[2];Result.ARGB[3]:=ClassHandle.RGB.ARGB[1];
 S:=GetProperty('Цвет заливки');
 If S<>byLayer then
 try
  Res:=StrToInt(S);
  Result.ARGB[1]:=GetBValue(Res);Result.ARGB[2]:=GetGValue(Res);Result.ARGB[3]:=GetRValue(Res);
 except SetProperty('Цвет заливки',byLayer);end;
end;

function TRasterLot.rasterColor: TRGBRec;
var S:String;Res:Integer;
begin
 Res:=ClassHandle.LineColor;
 Result.ARGB[1]:=GetBValue(Res);Result.ARGB[2]:=GetGValue(Res);Result.ARGB[3]:=GetRValue(Res);
 S:=GetProperty('Цвет');
 If S<>byLayer then
 try
  Res:=StrToInt(S);
  Result.ARGB[1]:=GetBValue(Res);Result.ARGB[2]:=GetGValue(Res);Result.ARGB[3]:=GetRValue(Res);
 except SetProperty('Цвет',byLayer);end;
end;

function TRasterLot.rasterGlass: boolean;
var S:String;
begin
 Result:=TForm(GTwgForm).Settings.bmGlass;
 S:=GetProperty('Прозрачность');
 If S = 'Нет' then Result:= False else
 If S = 'Да' then Result:=True;
end;

function TRasterLot.SetProperty(propName: String;propValue: String;Obj:TTD = nil): boolean;
var Sect:TSect;Tw:TTwigRect;Scale:Double;
begin
 If PropName = 'Масштаб листа' then
  try
   Scale:=abs(StrToFloat(propValue));
   Tw:=TTwigRect(GetTwig(TForm(GTwgForm).Twigs,0));                                             
   Sect.Right:=RealWidth*Scale/SpatialData.Scale;Sect.Bottom:=RealHeight*Scale/SpatialData.Scale;
   SpatialData.Scale:=Scale;
   Tw.Sect:=Sect;
  // SpatialData.Scale:=Twig.Width/SpatialData.Width*100;
  except PropValue:=FloatToStrF(SpatialData.Scale,ffFixed,_LD,0);end;
 Result:=inherited SetProperty(propName,propValue);
end;

procedure TRasterLot.DrawRegions(Canvas: TCanvas);
begin
end;

function TRasterLot.PointInRaster(Twf: TTwigsCollect; X, Y: Double): Boolean;
begin
 Result:=inherited PointIn(TWF,X,Y)
end;

function TRasterLot.Brightness: Integer;
var S:String;Res:Integer;
begin
 Result:=0;
 S:=GetProperty('Яркость');
 If S<>byLayer then
 try
  Result:=StrToInt(S);
  Result:=(Result - 50) * 2;
 except SetProperty('Яркость',byLayer);end;
end;


{procedure TRasterLot.GeoPoint(TWF:TTwigsCollect;X, Y: Integer; var X, Y: Double);
var Tw:TTwig;
begin
// Tw:=
end;

procedure TRasterLot.RasterPoint(TWF:TTwigsCollect;X, Y: Double; var X, Y: Integer);
var Tw:TTwig;
begin

end;
}
procedure TRasterLot.Rotate(TWF:TTwigsCollect;X, Y, Angle: Double);
var Tw:TTwigRect;XOld,YOld:Double;
begin
 Tw:=TTwigRect(GetTwig(TWF,0));
 XOld:=X;YOld:=Y;
 Tw.Rotate(Angle,X,Y);
 Tw.Move(XOld-X,YOld-Y);
end;

procedure TRasterLot.Rescale(TWF: TTwigsCollect; var X, Y:Double; Scale: Double);
var Tw:TTwigRect;XOld,YOld:Double;
begin
 XOld:=X;YOld:=Y;
 Tw:=TTwigRect(GetTwig(TWF,0));
 Tw.ReScale(X,Y,Scale);
end;

function TRasterLot.GetHint(P:Pointer=nil): String;
begin
 Result:=FileName;
end;

{ TOleLot }

constructor TOleLot.Create(CH: TResource; BinaryData_: String; Sect_: TSect);
begin
 inherited Create(CH);
 Ole:=TGeoOle.Create(BinaryData_,Sect_);
 TypeLot:=1;
end;

constructor TOleLot.CreateOleContainer(CH: TResource; OleCont_: TOleContainer; Sect_: TSect);
begin
 inherited Create(CH);
 Ole:=TGeoOle.CreateOleContainer(OleCont_,Sect_);
 TypeLot:=1;
end;

procedure TOleLot.AssignLot(Lot: TLot; AddAllCollections: Boolean);
begin
 inherited;
 Ole:=TGeoOle.CreateAsUserObject(TOleLot(Lot).Ole);
 TypeLot:=1;
end;

destructor TOleLot.Destroy;
begin
 inherited;
 Ole.Free;
end;

constructor TOleLot.Load(Stream: TBufStream);
begin
 inherited;
 Ole:=TGeoOle.Load(Stream);TypeLot:=1;
end;

procedure TOleLot.Store(Stream: TBufStream);
begin
 inherited;
 Ole.Store(Stream);
end;

function TOleLot.DrawObject(TWF: TTwigsCollect): byte;
var Tw:TTwigRect;XKoef,YKoef:Double;
begin
 Result:=1;TypeLot:=1;
 Tw:=TTwigRect(GetTwig(TWF,0));Tw.Proportional:=True;Tw.Inversion:=False;
// вычисляем коэффициент
 XKoef:=Tw.Width/(Ole.oleRect.Right-Ole.oleRect.Left);
 Ole.Draw(GCanvas,Tw[0].XDot,Tw[0].YDot,0,XKoef,XKoef,false,false);
 Tw.Inv:=Inv;Tw.StColor:=LotLineColor;
// Writeln('Inv=',Inv,' ',Tw.StColor,' ',Tw.Inv);
 Tw.Draw;
end;

function TOleLot.DevDrawObject(Twf: TTwigsCollect; XGeoCent, YGeoCent: Extended; XPrintcent, YPrintCent: Integer): byte;
var Tw:TTwigRect;XKoef:Double;
begin
 Result:=1;
 Tw:=TTwigRect(GetTwig(TWF,0));Tw.Proportional:=True;
// вычисляем коэффициент
 XKoef:=Tw.Width/(Ole.oleRect.Right-Ole.oleRect.Left);
 Ole.DevDraw(PrinterDC,XGeoCent,YGeoCent,XPrintcent,YPrintCent,XKoef,XKoef);
// Twig.Inv:=Inv;Twig.StColor:=LotLineColor;Twig.Draw;
end;

procedure TOleLot.CreateSpatialTwig(TWF: TTwigsCollect;var Twig: TTwigRect);
var Sect:TSect;
begin
 Sect:=Ole.oleRect;
 If Twig = nil then begin
  Twig:=TTwigRect.Create(0,@Sect);Twig.Proportional:=True;Twig.Inversion:=False;
  TWF.Insert(TWG_Twig,Twig);
  Coord.FreeAll;Coord.Insert(TLong.Create(TWF.TwigsCount-1));
 end;
 SetMinMax(TWF);
end;

initialization
 RegisterObject(TRectLot,3106);
 RegisterObject(TRasterLot,3107);
 RegisterObject(TOleLot,3108);
end.
