unit newFontScale;
interface
Uses Collect, SysUtils, Types_Dimano, Math, Classes, FMX.Graphics, System.Types,
        System.Skia, FMX.Skia;
var F: ISkFont;
Const KoefZoom:Single = 1;
      styleSym_Height:Char = 'A';
type
 PointArray = Array of TPoint;
 ByteArray  = Array of byte;
 IntArray   = Array of Integer;
//
 hDc = Integer;

type
 TFontScaleEx = class (TTwgObject)
  Symbol:Char;
  Lines:PointArray;
  Polygons:IntArray;
  PolyCount,PointsCount:Integer;
  XMin,XMax,YMin,YMax,MinX,MinY,MaxX,MaxY:Integer;
  XNext,YNext:Integer;
  A,B,C:Integer;
  TI2:Double;
//  GLList:GLuint;
   Constructor CreateView(DC:hDc;S:PChar;It:Boolean);
   Procedure RecreateSymbol(DC:hDc);
   Destructor Destroy;override;
   Constructor Load(Stream:TBufStream);override;
   Procedure Store(Stream:TBufStream);override;
 end;


 TFontManagerEx = class;
 TFontViewEx = class (TTwgObject)
  FontScales:PCollection;// коллекция символов
  Scale:Integer;
  bl,it,un,ov:Integer;
  FontName:AnsiString;
  CharSet:byte;
  begW:Integer;
  kUp,kUp2,KDown,TE,TI,TH,TD,Kline,kW:Double;
  Index:Integer;
  FontColEx:TFontManagerEx;
   Constructor Create(DC:hDc;FName:AnsiString;FH,FW:Double;CharSet1:Byte;bl1,it1,un1:Integer;FS:Integer=10);
   Procedure RecreateLoadedFonts(Canvas:TCanvas);
   Destructor Destroy;override;
   Constructor Load(Stream:TBufStream);override;
   Procedure Store(Stream:TBufStream);override;
  {}
   Procedure SetParams(FH,FW:Double);
   Procedure PaintText(DC:hDc;X,Y:Integer;Koef,Angle:Double;Text:AnsiString);
   Procedure FillText(DC:hDc;X,Y:Integer;Koef,Angle:Double;Text:AnsiString);
   Procedure GetTextLen(X,Y:Integer;Koef,Angle:Double;Text:AnsiString;var DX,DY:Double);
   Function GetTextPoint(XPoint,YPoint,X,Y:Integer;Koef,Angle:Double;Text:AnsiString):boolean;
  {}
   Function isEqual(FName:AnsiString;CHS:byte;bl1,it1,un1:Integer):boolean;
   Function YMin(C:Char):Integer;
   Function XMin(C:Char):Integer;
   Function RH(C:Char):Integer;
 end;


 TFontManagerEx = class(PCollection)
  function AddFont(DC:hDc; fntName:AnsiString; H,W :Double; CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10): integer;
  function AddFontView(DC:hDc;View:TFontViewEx):TFontViewEx;
 end;

var Lin:Array[0..10000] of TPoint;
    Typ:Array[0..10000] of byte;
    AllLin:Array[0..20000] of TPoint;
    AllPoly:Array[0..1000] of Integer;

implementation uses Maths_Lines;

{ TFontScaleEx }
constructor TFontScaleEx.CreateView(DC:hDc;S: PChar;It:Boolean);
var I:Integer;bkMode:Integer;Count:Integer;
    N,J:Integer;
    First,Second:Integer;
    P,AllP:PCollection;
    Rect:TRect;
  //  ABC:TABC;
begin
//И дальше поставь точку: F. и посмотри, есть ли у ISkFont один из методов:
//f.GetPath

 {$IFDEF WIN64}
 Symbol:=S[0];
 For I:=0 to 1 do begin
  bkMode:=SetBkMode(DC,Opaque);
   Rect.Left:=0;Rect.Top:=0;Rect.Right:=(XMax-XMin);Rect.Bottom:=YMax-YMin;
    beginPath(DC);
     TextOut(DC,0,0,S,1);
    endPath(DC);
   FlattenPath(DC);
   if I=0 then
    Count:=GetPath(DC,@Lin,@Typ,0) else begin
    Count:=GetPath(DC,@Lin,@Typ,Count);
   end;
  SetBkMode(DC,bkMode);
 end;
  AllP:=PCollection.Create(1);MinX:=10000;MinY:=10000;MaxX:=-10000;MaxY:=-10000;
  For I:=0 to Count-1 do begin
   Case Typ[I] of
    PT_MoveTo:begin
               P:=PCollection.Create(1);
               P.Insert(@Lin[I]);
               AllP.Insert(P);
              end;
    PT_LineTo:P.Insert(@Lin[I]);
    PT_LineTo or PT_CloseFigure:begin
                                 P.Insert(@Lin[I]);P.Insert(P[0]);
                                end;
   end;
    If I=0 then begin XMin:=Lin[I].X;YMin:=Lin[I].Y;end;
    If I=1 then XMax:=Lin[I].X;
    If I=2 then YMax:=Lin[I].Y;
    If I>5 then begin
     if Lin[I].X>MaxX then MaxX:=Lin[I].X;
     if Lin[I].Y>MaxY then MaxY:=Lin[I].Y;
     if Lin[I].X<MinX then MinX:=Lin[I].X;
     if Lin[I].Y<MinY then MinY:=Lin[I].Y;
    end;
  end;               
//  If It then begin
   A:=XMin+MinX;C:=XMax-MaxX;
   If A = 10000 then begin A:=0;C:=0;B:=0;end;
   If GetCharABCWidths(DC,ord(S[0]),ord(S[0]),ABC) then begin
//    Writeln('Symbol=',S,' A=',A,' C=',C,' ABC.A=',ABC.abcA,' ABC.B',ABC.abcC);
    A:=ABC.abcA;B:=ABC.abcB;C:=ABC.abcC;
   end;
//  end;
// Writeln('End1');
 SetLength(Polygons,AllP.Count*SizeOf(Integer));
 PolyCount:=AllP.Count;PointsCount:=0;
 For I:=0 to AllP.Count-1 do begin
  P:=AllP[I];
  Polygons[I]:=P.Count;
  Inc(PointsCount,P.Count);
 end;
 SetLength(Lines,PointsCount*SizeOf(TPoint)+1);
 N:=0;
  For I:=0 to AllP.Count-1 do begin
   P:=AllP[I];
    For J:=0 to P.Count-1 do begin Lines[N]:=PPoint(P[J])^;Inc(N);end;
   P.DeleteAll;
  end;
 AllP.DeleteAll;
//  Writeln('EndCreate=',PointsCount,' ',FontName,' ',Text);
// writeln(PointsCount);
// Writeln('MinMax=',XMin,' ',XMax,' ',YMin,' ',YMax);
{$ENDIF}
end;

procedure TFontScaleEx.RecreateSymbol(DC: hDc);
var I:Integer;bkMode:Integer;Count:Integer;
    N,J:Integer;
    First,Second:Integer;
    P,AllP:PCollection;
    Rect:TRect;
begin
{$IFDEF WIN64}
 For I:=0 to 1 do begin
  bkMode:=SetBkMode(DC,Opaque);
   Rect.Left:=0;Rect.Top:=0;Rect.Right:=(XMax-XMin);Rect.Bottom:=YMax-YMin;
    beginPath(DC);
     TextOut(DC,0,0,PChar(AnsiString(Symbol+#0)),1);
    endPath(DC);
   FlattenPath(DC);
   if I=0 then
    Count:=GetPath(DC,@Lin,@Typ,0) else begin
    Count:=GetPath(DC,@Lin,@Typ,Count);
   end;
  SetBkMode(DC,bkMode);
 end;
  AllP:=PCollection.Create(1);//MinX:=10000;MinY:=10000;MaxX:=-10000;MaxY:=-10000;
  For I:=0 to Count-1 do begin
   Case Typ[I] of
    PT_MoveTo:begin
               P:=PCollection.Create(1);
               P.Insert(@Lin[I]);
               AllP.Insert(P);
              end;
    PT_LineTo:P.Insert(@Lin[I]);
    PT_LineTo or PT_CloseFigure:begin
                                 P.Insert(@Lin[I]);P.Insert(P[0]);
                                end;
   end;
  end;
// Writeln('End1');
 SetLength(Polygons,AllP.Count*SizeOf(Integer));
 PolyCount:=AllP.Count;PointsCount:=0;
 For I:=0 to AllP.Count-1 do begin
  P:=AllP[I];
  Polygons[I]:=P.Count;
  Inc(PointsCount,P.Count);
 end;
 SetLength(Lines,PointsCount*SizeOf(TPoint)+1);
 N:=0;
  For I:=0 to AllP.Count-1 do begin
   P:=AllP[I];
    For J:=0 to P.Count-1 do begin Lines[N]:=PPoint(P[J])^;Inc(N);end;
   P.DeleteAll;
  end;
 AllP.DeleteAll;
// Writeln('EndCreate=',PointsCount,' ',FontName,' ',Text);
// writeln(PointsCount);
// Writeln('MinMax=',XMin,' ',XMax,' ',YMin,' ',YMax);
{$ENDIF}
end;

destructor TFontScaleEx.Destroy;
begin
 SetLength(Lines,0);
 Lines:=nil;
 SetLength(Polygons,0);
 Polygons:=nil;
// glDeleteLists(GLList,1);
end;

constructor TFontScaleEx.Load(Stream: TBufStream);
begin
 Stream.Read(Symbol,SizeOf(Symbol));
 Stream.Read(PolyCount,SizeOf(PolyCount));
 Stream.Read(PointsCount,SizeOf(PointsCount));
 SetLength(Lines,PointsCount*SizeOf(TPoint)+1);
 SetLength(Polygons,PolyCount*SizeOf(Integer));
 Stream.Read(Lines[0],Length(Lines));
 Stream.Read(Polygons[0],Length(Polygons));
 Stream.Read(XMin,SizeOf(XMin));
 Stream.Read(XMax,SizeOf(XMax));
 Stream.Read(YMin,SizeOf(YMin));
 Stream.Read(YMax,SizeOf(YMax));
 Stream.Read(MinX,SizeOf(MinX));
 Stream.Read(MinY,SizeOf(MinY));
 Stream.Read(MaxX,SizeOf(MaxX));
 Stream.Read(MaxY,SizeOf(MaxY));
 Stream.Read(XNext,SizeOf(XNext));
 Stream.Read(YNext,SizeOf(YNext));
 Stream.Read(TI2,SizeOf(TI2));
end;

procedure TFontScaleEx.Store(Stream: TBufStream);
begin
 Stream.Write(Symbol,SizeOf(Symbol));
 Stream.Write(PolyCount,SizeOf(PolyCount));
 Stream.Write(PointsCount,SizeOf(PointsCount));
 Stream.Write(Lines[0],Length(Lines));
 Stream.Write(Polygons[0],Length(Polygons));
 Stream.Write(XMin,SizeOf(XMin));
 Stream.Write(XMax,SizeOf(XMax));
 Stream.Write(YMin,SizeOf(YMin));
 Stream.Write(YMax,SizeOf(YMax));
 Stream.Write(MinX,SizeOf(MinX));
 Stream.Write(MinY,SizeOf(MinY));
 Stream.Write(MaxX,SizeOf(MaxX));
 Stream.Write(MaxY,SizeOf(MaxY));
 Stream.Write(XNext,SizeOf(XNext));
 Stream.Write(YNext,SizeOf(YNext));
 Stream.Write(TI2,SizeOf(TI2));
end;

{ TFontViewEx }
constructor TFontViewEx.Create(DC: hDc; FName: AnsiString; FH, FW: Double;
  CharSet1: Byte; bl1, it1, un1, FS: Integer);
var I:Integer;
 //   F:hFont; tm :TTextmetric; //FMX
    HH:Double;
    FS1:TFontScaleEx;
begin
 {$IFDEF WIN64}
// begW:=Trunc(FS*FW/FH);
 FontName:=FName;Scale:=FS;
 bl:=bl1;it:=it1;un:=0;
 CharSet:=CharSet1;
 FontScales:=PCollection.Create(1);
 F:=SelectObject(DC,CreateFont(FS,0,0,0,bl1*600+100,It,0,0,CharSet,0,0,0,0,PChar(FName)));
{ If It = 0 then
 F:=SelectObject(DC,CreateFont(FS,0,0,0,bl1*600+100,0,0,0,CharSet,0,0,0,0,PChar(FName))) else
 F:=SelectObject(DC,CreateFont(FS,0,0,0,0,0,0,0,CharSet,0,0,0,0,PChar(FName)));
 For I:=0 to 255 do FontScales.Insert(TFontScaleEx.CreateView(DC,PChar(AnsiString(Chr(I)+#0))));
 If (It = 1) then begin
  DeleteObject(SelectObject(DC,F));
  F:=SelectObject(DC,CreateFont(FS,0,0,0,bl1*600+100,It,0,0,CharSet,0,0,0,0,PChar(FName)));
  For I:=0 to 255 do TFontScaleEx(FontScales[I]).ReCreateSymbol(DC);
 end;}
 For I:=0 to 255 do FontScales.Insert(TFontScaleEx.CreateView(DC,PChar(AnsiString(Chr(I)+#0)),It=1));
 GetTextMetrics(DC,tm);  {tm}
 FS1:=FontScales[ord(stylesym_Height)];
 TE:=FS1.MaxY;
 TD:=FS1.MinY;
 TH:=FS1.MaxY-FS1.MinY;
 kUp:=FS1.MinY/FS;//1000;
 KDown:=FS1.MaxY/FS;//1000;
 //Kline:=(FS1.MinY-FS1.YMin)/TH;
 Kline:=(tm.tmExternalLeading);
 // Kline:=(FS1.MinY-FS1.YMin)/(FS1.YMax-FS1.Ymin);
 DeleteObject(SelectObject(DC,F));
{$ENDIF}
end;

procedure TFontViewEx.RecreateLoadedFonts;
var I:Integer;
   // F:hFont; tm :TTextmetric;  //FMX
    HH:Double;
    FS1:TFontScaleEx;
begin
{$IFDEF WIN64}
(* только по Windows *)
 FontScales:=PCollection.Create(1);
 F:=SelectObject(Canvas.Handle,CreateFont(Scale,0,0,0,bl*600+100,It,0,0,CharSet,0,0,0,0,PChar(FontName)));
{ If It = 0 then
 F:=SelectObject(DC,CreateFont(FS,0,0,0,bl1*600+100,0,0,0,CharSet,0,0,0,0,PChar(FName))) else
 F:=SelectObject(DC,CreateFont(FS,0,0,0,0,0,0,0,CharSet,0,0,0,0,PChar(FName)));
 For I:=0 to 255 do FontScales.Insert(TFontScaleEx.CreateView(DC,PChar(AnsiString(Chr(I)+#0))));
 If (It = 1) then begin
  DeleteObject(SelectObject(DC,F));
  F:=SelectObject(DC,CreateFont(FS,0,0,0,bl1*600+100,It,0,0,CharSet,0,0,0,0,PChar(FName)));
  For I:=0 to 255 do TFontScaleEx(FontScales[I]).ReCreateSymbol(DC);
 end;}
 For I:=0 to 255 do FontScales.Insert(TFontScaleEx.CreateView(Canvas.Handle,PChar(AnsiString(Chr(I)+#0)),It=1));
 GetTextMetrics(Canvas.Handle,tm);  {tm}
 FS1:=FontScales[ord(stylesym_Height)];
 TE:=FS1.MaxY;
 TD:=FS1.MinY;
 TH:=FS1.MaxY-FS1.MinY;
 kUp:=FS1.MinY/Scale;//1000;
 KDown:=FS1.MaxY/Scale;//1000;
 //Kline:=(FS1.MinY-FS1.YMin)/TH;
 Kline:=(tm.tmExternalLeading);
 // Kline:=(FS1.MinY-FS1.YMin)/(FS1.YMax-FS1.Ymin);
 DeleteObject(SelectObject(Canvas.Handle,F));
{$ENDIF}
end;

destructor TFontViewEx.Destroy;
begin
 FontScales.Free;
end;

procedure TFontViewEx.GetTextLen;
var F:TFontScaleEx;I:Integer;DDX:Double;
begin
 DDX:=0;
 Koef:=Koef*KoefZoom;
 For I:=1 to Length(Text) do begin
  F:=FontScales[ord(Text[I])];
  DDX:=DDX+(F.A+F.B+F.C)*Koef;
  if I=1 then DY:=((F.YMax-F.YMin)*Koef);
 end;
 DX:=(DDX*Kw);
end;

function TFontViewEx.isEqual(FName: AnsiString; CHS:byte; bl1, it1, un1: Integer): boolean;
begin
 Result:=(AnsiUpperCase(FontName)=AnsiUpperCase(FName)) and (bl=bl1) and (it=it1) and (un=un1) and (CharSet=CHS);
end;

procedure TFontViewEx.PaintText;
var F:TFontScaleEx;I,J,PointCount,PolyCount:Integer;
    X1,Y1,Max:Double;
begin
 Max:=0;PointCount:=0;PolyCount:=0;
 For I:=1 to Length(Text) do begin
  F:=FontScales[ord(Text[I])];
   For J:=5 to F.PointsCount-1 do begin
    AllLin[PointCount].X:=Round(F.Lines[J].X*KW+Max);
    AllLin[PointCount].Y:=F.Lines[J].Y;
    inc(PointCount);
   end;
   For J:=1 to F.PolyCount-1 do begin
    AllPoly[PolyCount]:=F.Polygons[J];
    inc(PolyCount);
   end;
   Max:=Max+(F.A+F.B+F.C)*kW;
//  Max:=Max+(F.XMax)*kW;
 end;
{ Рисовка }
 Angle:=Angle/180*Pi;
 Koef:=KOef*KoefZoom;
 For I:=0 to PointCount-1 do begin
  X1:=AllLin[I].X * Koef;Y1:=AllLin[I].Y * Koef;
  AllLin[I].X:=Round(X+(Cos(Pi/2-Angle)*Y1+Cos(Angle)*X1));
  AllLin[I].Y:=Round(Y+(Sin(Pi/2-Angle)*Y1-Sin(Angle)*X1));
 end;
{$IFDEF WIN64}
 Windows.PolyPolyLine(DC,AllLin[0],AllPoly[0],PolyCount);
{$ENDIF}
end;

procedure TFontViewEx.FillText;
var F,FNext:TFontScaleEx;I,J,PointCount,PolyCount:Integer;
    X1,Y1,Max:Double;
begin
 Max:=0;PointCount:=0;PolyCount:=0;
 For I:=1 to Length(Text) do begin
  F:=FontScales[ord(Text[I])];
   For J:=5 to F.PointsCount-1 do begin
    AllLin[PointCount].X:=Round(F.Lines[J].X*KW+Max);
    AllLin[PointCount].Y:=F.Lines[J].Y;
    inc(PointCount);
   end;
   For J:=1 to F.PolyCount-1 do begin
    AllPoly[PolyCount]:=F.Polygons[J];
    inc(PolyCount);
   end;
   Max:=Max+(F.A+F.B+F.C)*kW;
//   Max:=Max+(F.XMax)*kW;
 end;
{ Рисовка }
 Angle:=Angle/180*Pi;
 Koef:=Koef*KoefZoom;
 For I:=0 to PointCount-1 do begin
  X1:=AllLin[I].X * Koef;Y1:=AllLin[I].Y * Koef;
  AllLin[I].X:=Round(X+(Cos(Pi/2-Angle)*Y1+Cos(Angle)*X1));
  AllLin[I].Y:=Round(Y+(Sin(Pi/2-Angle)*Y1-Sin(Angle)*X1));
 end;
{$IFDEF WIN64}
 Windows.PolyPolyGon(DC,AllLin[0],AllPoly[0],PolyCount);
{$ENDIF}
end;

function TFontViewEx.GetTextPoint(XPoint, YPoint, X, Y: Integer; Koef, Angle: Double; Text: AnsiString): boolean;
var F,FNext:TFontScaleEx;I,J,PointCount,PolyCount:Integer;
    X1,Y1,Max:Double;
   // Pen:hPen;
begin
 Result:=False;
 Max:=0;PointCount:=0;PolyCount:=0;
 For I:=1 to Length(Text) do begin
  F:=FontScales[ord(Text[I])];
   For J:=5 to F.PointsCount-1 do begin
    AllLin[PointCount].X:=Round(F.Lines[J].X*KW+Max);
    AllLin[PointCount].Y:=F.Lines[J].Y;
    inc(PointCount);
   end;
   For J:=1 to F.PolyCount-1 do begin
    AllPoly[PolyCount]:=F.Polygons[J];
    inc(PolyCount);
   end;
   Max:=Max+(F.A+F.B+F.C)*kW;
 end;
{ Рисовка }
 Angle:=Angle/180*Pi;
 Koef:=Koef*KoefZoom;
 For I:=0 to PointCount-1 do begin
  X1:=AllLin[I].X * Koef;Y1:=AllLin[I].Y * Koef;
  AllLin[I].X:=Round(X+(Cos(Pi/2-Angle)*Y1+Cos(Angle)*X1));
  AllLin[I].Y:=Round(Y+(Sin(Pi/2-Angle)*Y1-Sin(Angle)*X1));
  If I>0 then begin
   If Dist_Point_Edge(XPoint,YPoint,AllLin[I].X,AllLin[I].Y,AllLin[I-1].X,AllLin[I-1].Y)<=2 then begin
{    SetPixel(GCanvas.Handle,XPoint,YPoint,RGB(255,0,0));
    Writeln('XR=',Dist_Point_Edge(XPoint,YPoint,AllLin[I].X,AllLin[I].Y,AllLin[I-1].X,AllLin[I-1].Y));
    Pen:=SelectObject(GCanvas.Handle,CreatePen(ps_Solid,2,RGB(0,255,0)));
    MoveTo(GCanvas.Handle,AllLin[I].X,AllLin[I].Y);LineTo(GCanvas.Handle,AllLin[I-1].X,AllLin[I-1].Y);
    DeleteObject(SelectObject(GCanvas.Handle,Pen));}
    Result:=True;exit;
   end;
  end;
 end;
end;


procedure TFontViewEx.SetParams(FH, FW: Double);
begin
 kW:=FW;
end;

function TFontViewEx.YMin(C: Char): Integer;
var FS:TFontScaleEx;
begin
 FS:=FontScales[ord(C)];
 Result:=FS.MinY;
end;

function TFontViewEx.RH(C: Char): Integer;
var FS:TFontScaleEx;
begin
 FS:=FontScales[ord(C)];
 Result:=FS.MaxY-FS.MinY;
end;

function TFontViewEx.XMin(C: Char): Integer;
var FS:TFontScaleEx;
begin
 FS:=FontScales[ord(C)];
 Result:=FS.MinX;
end;

constructor TFontViewEx.Load(Stream: TBufStream);
begin
  //inherited Load(Stream);
  Stream.Read(Scale,SizeOf(Scale));
  Stream.Read(bl,SizeOf(bl));
  Stream.Read(it,SizeOf(it));
  Stream.Read(un,SizeOf(un));
  Stream.Read(ov,SizeOf(ov));
  FontName:=Stream.ReadString;
  Stream.Read(CharSet,SizeOf(CharSet));
  Stream.Read(Index,SizeOf(Index));
 {
  Stream.Read(begW,SizeOf(begW));
  Stream.Read(begW,SizeOf(begW));
  Stream.Read(kUp,SizeOf(kUp));
  Stream.Read(kUp2,SizeOf(kUp2));
  Stream.Read(KDown,SizeOf(KDown));
  Stream.Read(TE,SizeOf(TE));
  Stream.Read(TI,SizeOf(TI));
  Stream.Read(TH,SizeOf(TH));
  Stream.Read(TD,SizeOf(TD));
  Stream.Read(Kline,SizeOf(Kline));
  Stream.Read(kW,SizeOf(kW));
  FontScales:=PCollection(Stream.Get);
 }
end;

procedure TFontViewEx.Store(Stream: TBufStream);
begin
  //inherited Store(Stream);
  Stream.Write(Scale,SizeOf(Scale));
  Stream.Write(bl,SizeOf(bl));
  Stream.Write(it,SizeOf(it));              
  Stream.Write(un,SizeOf(un));
  Stream.Write(ov,SizeOf(ov));
  Stream.WriteString(FontName);
  Stream.Write(CharSet,SizeOf(CharSet));
  Stream.Write(Index,SizeOf(Index));
{
  Stream.Write(begW,SizeOf(begW));
  Stream.Write(begW,SizeOf(begW));
  Stream.Write(kUp,SizeOf(kUp));
  Stream.Write(kUp2,SizeOf(kUp2));
  Stream.Write(KDown,SizeOf(KDown));
  Stream.Write(TE,SizeOf(TE));
  Stream.Write(TI,SizeOf(TI));
  Stream.Write(TH,SizeOf(TH));
  Stream.Write(TD,SizeOf(TD));
  Stream.Write(Kline,SizeOf(Kline));
  Stream.Write(kW,SizeOf(kW));
  Stream.Put(FontScales);
}
end;

{ TFontManagerEx }
function TFontManagerEx.AddFont(DC: hDc; fntName: AnsiString; H, W: Double;
  CharSet: Byte; bl1, it1, un1, fS: Integer): integer;
var i: integer;
    fv: TFontViewEx;
begin
 Fs:=1000;
// charSet := Default_CharSet;  FMX
  result := -1;
  for i := 0 to count - 1 do
  begin
    fv := items[i];
    if fv.isEqual(fntname, charset, bl1, it1, un1) then
    begin
      fv.FontColEx:=Self;
      result := i;
      exit;
    end;
  end;
  fv := TFontViewEx.Create(dc, fntName, h, w, CharSet, bl1, it1, un1, fs);
 // Writeln('Add=',FntName,' ',bl1,' ',It1,' ',Un1,' ',Count);
  Insert(fv);
  fv.Index:=Count-1;
  fv.FontColEx:=Self;
  result := count - 1;
end;

function TFontManagerEx.AddFontView(DC:hDc;View: TFontViewEx): TFontViewEx;
var IndexFont:Integer;
begin
 With View do IndexFont:=AddFont(DC,fontName,0,0,CharSet,bl,it,un,Scale);
 Result:=Items[IndexFont];
end;


initialization
finalization
end.
