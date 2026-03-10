unit RPrims;
interface
Uses Windows, Selector, Collect, Graphics, BitBox, PcxBox, SysUtils, UstnRec,
     Resource, VcPrint, Printers, Classes, DBTables, IniFiles, EcDot, varConsts,
     TwgDraw, userObject;


type
  TRastrParam=record
   GUID:TGUID;
    Name,FName:String;
    Mas,XR,YR:Integer;
    XGeo,YGeo:Double;
    Sloy:Double;
    Vkl:Boolean;
    Properties:TProperties;
   end;

Type
 TBmpMgr=class(TTD)
   GUID:TGUID;
  {}
   Code:Double;
   ClassHandle:TResource;
  {}
   FActive:Boolean; // является ли активным
  {}
   X,Y:Double; // Координаты точки привязки на местности
   XR,YR:Integer;// Координаты точки привязки на растре
   Left,Top,Right,Bottom:Double;// координаты на местности = Const
   LeftR,TopR,RightR,BottomR:Integer;// координаты относительно окна
   DPI,Mas:Integer;// число пикселей на сантиметр и масштаб
   Name:String;//имя растра в регистрационной базе
   FileName:String;//имя файла
   NotInit:boolean;
  {}
   Box:TBitBox;
  {}
   BMName:String;
   SqlClose:Boolean;
   CheckVisible:Boolean;
   Dop:Array[1..100] of byte;
   Regions:PCollection;
   Color,BackColor:Integer;
   Properties:TProperties;
    Constructor CreateAsParam(P:TRastrParam;BM:String);
    Destructor Destroy;override;
    Constructor Load(S:TBufStream);override;
    Procedure   Store(S:TBufStream);override;
  {}
    Function  EqualParams(P:TRastrParam):Boolean;
    Procedure SetParams(P:TRastrParam);
    Function  GetParams:TRastrParam;
    Procedure InitBox;
  {}
    Procedure DrawBorder;
    Procedure Draw;
    Procedure DrawRegions(Canvas:TCanvas);
    Function GetRegion(X,Y:Double;var Dot:TDot):Integer;//Flag =  -1 - за пределами, 0 - в пределах, 1 - на границе, 2 - на точке
    Procedure DrawAs100;
    Procedure DevDraw(Dc:hDc;XGeoCent,YGeoCent:Extended;XprintCent,YprintCent,L,T,R,B:Integer);
    Function  Visible:boolean;
    Procedure Calculate;
    Function XGeoToRaster(X:Double):Integer;
    Function YGeoToRaster(Y:Double):Integer;
    Function XRasterToGeo(X:Integer):Double;
    Function YRasterToGeo(Y:Integer):Double;
    Procedure SetNewPoint(XX,YY:Double;XXR,YYR:Integer);
    Procedure Move(Dx,Dy:Double);
  { Свойства }
    Procedure SetActive(V:Boolean);
    Property Active:Boolean read FActive write SetActive;
    Function GetSect:TSect;
    Function Information:String;
  { Работа с файлом инициализации }
    Function BIF:String; // имя файла инициализации
    Function LoadBIFParams(var Params:TRastrParam):boolean;
    Function StoreBIFParams(Params:TRastrParam):boolean;
    Function GetHint(P:Pointer=nil):string;override;
   //
    Function GUIDStr:String;
   { Процедуры загрузки из базы данных }
    Constructor   LoadDB(GUID_:TGUID;Stream:TBufStream);
    Procedure     StoreDB(Stream:TBufStream);
   // свойства
    Function SetProperty(propName:String;propValue:String;Obj:TTD = nil):boolean;override;
    Function GetProperty(propName:String):String;override;
    Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
    Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
    function GetLayer: TResource;
    procedure SetLayer(PR: TResource);
    Function UseProperty(propName: String): boolean;override;
    Procedure DeleteProperty(propName: String);override;
    procedure MergeProperties(Obj: TTD;Flag:Boolean);override;
    procedure AddProperty(propName: String);override;
  end;

 TBmpSet=class(TTwgObject)
   FileName:String;// имя файла регистрации
   Bitmaps :PCollection;
   FActive :Integer;
  {}
    Constructor Create;
    Destructor Destroy;override;
    Procedure RebuildBmDirs;
    Constructor Load(S:TBufStream);override;
    Procedure   Store(S:TBufStream);override;
  {}
    Procedure Draw;
    Procedure DevDraw(Dc:hDc;XGeoCent,YGeoCent:Extended;XprintCent,YprintCent,L,T,R,B:Integer);
    Procedure ClearBitmaps;
    Procedure DeleteBitmap(Index:Integer);
  {}
    Function GetBitmap(Index:Integer):TBmpMgr;
    Property Bitmap[Index:Integer]:TBmpMgr read GetBitmap;default;
    Procedure SetActive(V:Integer);
    Property Active:Integer read FActive write SetActive;
    Function GetGabarites:TSect;
    Function PointIn(X,Y:Double):Integer;
    Function VisibleActiveRaster:TBmpMgr;
    Function Count:Integer;
  end;

 Function GetBMFile(BMName,FName:String):String;
 Function TemporaryPath:String;

implementation uses WptForm, Procs, ECConst, WpTwigs, EcLot, Forms, Controls,
                    Maths, Dialogs, PropertyEditors, ustnGlobalSettings;

{$IFNDEF GEOMASTER}
Function GetBMFile;
 var S,S2:TStrings;I,J:Integer;
 begin
  Result:='';
  S:=TStringList.Create;
   try
    S.LoadFromFile(BmName);
   Except
    S.Free;
     Exit;
   end;
   For I:=0 to S.Count-1 do
    If FileExists(S[I]+'\'+FName) then
     begin
      Result:=S[I];
      If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
      Result:=S[I]+'\'+FName;S.Free;Exit;
     end else
    if Session.isAlias(S[I]) then
     begin // ?????? ???? ? ??????, ???? ??? ?? ??????-?????????
      S2:=TStringList.Create;
      Session.GetAliasParams(S[I],S2);
       For J:=0 to S2.Count-1 do
        If Pos('PATH=',S2[J])=1 then
         begin
          Result:=Copy(S2[J],Length('PATH=')+1,Length(S2[J]));
          If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
          Result:=Result+'\'+FName;
//         Writeln('R=',Result,' ',FileExists(Result));
          If FileExists(Result) then begin S.Free;S2.Free;Exit;end else Result:='';
          break;
         end;
      S2.Free;
     end;
  S.Free;
 end;

{$ELSE}

Function GetBMFile;
var S,S2:TStrings;I,J:Integer;
    FN:String;
begin
  Result:='';
  S:=TStringList.Create;
  If FileExists(FName) then Result:=FName else begin
   // пытаемся найти файл в каталогах загруженных из INI-файла
    FN:=GExtractFilePath(FName);
    // OpenINI;
      S.Text:=MakeString(GReadString('Raster'+'RasterForm_Direct',''),';');
    // CloseINI;
     For I:=0 to S.Count-1 do
      If FileExists(S[I]+'\'+ExtractFileName(FName)) then
       begin
        Result:=S[I];
        If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
        Result:=S[I]+'\'+ExtractFileName(FName);S.Free;Exit;
       end;
    S.Free;
    Exit;
   end;
   For I:=0 to S.Count-1 do
    If FileExists(S[I]+'\'+FName) then
     begin
      Result:=S[I];
      If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
      Result:=S[I]+'\'+FName;S.Free;Exit;
     end else
    if Session.isAlias(S[I]) then
     begin // узнаем путь к данным, если они не клиент-серверные
      S2:=TStringList.Create;
      Session.GetAliasParams(S[I],S2);
       For J:=0 to S2.Count-1 do
        If Pos('PATH=',S2[J])=1 then
         begin
          Result:=Copy(S2[J],Length('PATH=')+1,Length(S2[J]));
          If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
          Result:=Result+'\'+FName;
//         Writeln('R=',Result,' ',FileExists(Result));
          If FileExists(Result) then begin S.Free;S2.Free;Exit;end else Result:='';
          break;
         end;
      S2.Free;
     end;
  S.Free;
 end;

{$ENDIF}

{ TBmpMgr }

Constructor TBmpMgr.CreateAsParam;
 begin
  Box:=nil;
 {$IFDEF GEOMASTER}
  BmName:=BM;
 {$ELSE}
  BmName:=MainPath+'\Images\'+Copy(BM,1,Length(BM)-3)+'.Dir';
 {$ENDIF}
  FActive:=False;
  Left:=0;Top:=0;Right:=0;Bottom:=0;
  LeftR:=0;TopR:=0;RightR:=0;BottomR:=0;
 { Инициализация растра }
{  If UpperCase(ExtractFileExt(P.FName))='.BMP' then
  Box:=TBitBox.Create(GnForm) else}
  Box:=TPcxBox.Create(GnForm);
  TPcxBox(Box).QueryDPI:=False;
  Box.Initialize(GNForm,GCanvas);
  Box.UseStretch:=True;
  Box.UseStandart:=False;
  Box.BackColor:=WptForm.TForm(GTwgForm).Settings.bmBackColor;
  Box.Color:=WptForm.TForm(GTwgForm).Settings.bmColor;
{ If GetBMFile(BMName,FileName)<>'' then
  Box.CreateView(GetBMFile(BMName,FileName));
  NotInit:=False;}
 {}
  SetParams(P);
  If P.Properties<>nil then Properties:=TProperties.CreateAs(P.Properties);
  Code:=-1;
  ClassHandle:=nil;
  SqlClose:=False;
  Regions:=PCollection.Create(1);
 end;

Destructor TBmpMgr.Destroy;
begin
 Box.Free;
 Regions.Free;
 If Properties<>nil then Properties.Free;
end;

Procedure TBmpMgr.InitBox;
 var S:String;
{ const xxxx: integer = 0;
       zzzz: integer = 0;}
 begin
{ Инициализация растра }
 If Box<>nil then Box.Free;
{ If UpperCase(ExtractFileExt(FileName))='.BMP' then
  Box:=TBitBox.Create(GnForm) else}
  Box:=TPcxBox.Create(GnForm);
  TPcxBox(Box).QueryDPI:=False;
  Box.Bits:=nil;
  Box.Initialize(GNForm,GCanvas);
  Box.UseStretch:=True;
  Box.UseStandart:=False;
  Box.BackColor:=GGraphSet.bmBack;
  Box.Color:=GGraphSet.bmColor;
  if Box.Bits<>nil then Box.CloseView;
// Writeln('Init=',BmName,' ',FileName);
  S:=GetBMFile(BmName,FileName);
//  Screen.Cursor:=crHourGlass;
  try
  if S<>'' then
  begin
   Box.CreateView(S,true);
  end;
  NotInit:=Box.Bits=nil;
  finally
 //  Screen.Cursor:=crDefault;
  end;
 {}
 end;

Function TBmpMgr.EqualParams;
 begin
  Result:=(P.FName<>FileName) or (P.Mas<>Mas);
 end;

Procedure TBmpMgr.SetParams;
 var S:String;
 begin
  GUID:=P.GUID;
   X:=P.XGeo;
   Y:=P.YGeo;
   XR:=P.XR;YR:=P.YR;
   Left:=X;Top:=Y;
   DPI:=38;
   Name:=P.Name;
   FileName:=P.FName;
   Mas:=P.Mas;
   CheckVisible:=P.Vkl;
   if Box.Bits<>nil then Box.CloseView;
   S:=GetBMFile(BmName,FileName);
{   if S<>'' then
    Box.CreateView(S);}
   InitBox;
   Calculate;
  // NotInit:=Box.Bits=nil;
  end;

Function  TBmpMgr.GetParams:TRastrParam;
 var P:TRastrParam;
 begin
  P.GUID:=GUID;
   P.XGeo:=X;
   P.YGeo:=Y;
   P.XR:=XR;P.YR:=YR;
   P.Name:=Name;
   P.FName:=FileName;
   P.Mas:=Mas;
   P.Vkl:=CheckVisible;
   P.Properties:=Properties;
   Result:=P;
 end;

Constructor TBmpMgr.Load;
 begin
  CreateGUID(GUID);
   S.Read(X,SizeOf(X));
   S.Read(Y,SizeOf(Y));
   S.Read(XR,SizeOf(XR));
   S.Read(YR,SizeOf(YR));
   S.Read(Left,SizeOf(Double));
   S.Read(Top,SizeOf(Double));
   S.Read(Right,SizeOf(Double));
   S.Read(Bottom,SizeOf(Double));
   S.Read(LeftR,SizeOf(Integer));
   S.Read(TopR,SizeOf(Integer));
   S.Read(RightR,SizeOf(Integer));
   S.Read(BottomR,SizeOf(Integer));
   Name:=S.ReadString;
   FileName:=S.ReadString;
//   Writeln('Load=',FileName);
   S.Read(Mas,SizeOf(Mas));
   S.Read(Code,SizeOf(Code));
   If EcConst.Version>33 then begin
    S.Read(CheckVisible,SizeOf(CheckVisible));
    S.Read(Dop,SizeOf(Dop));
    If EcConst.Version>34 then begin
     Regions:=PCollection(S.Get);
     If EcConst.Version>37 then Properties:=TProperties(S.Get);
    end else Regions:=PCollection.Create(1);
   end;
   Box:=nil;
   NotInit:=True;
   ClassHandle:=nil;
   SqlClose:=False;
 end;

Procedure TBmpMgr.Store;
 begin
   S.Write(X,SizeOf(X));
   S.Write(Y,SizeOf(Y));
   S.Write(XR,SizeOf(XR));
   S.Write(YR,SizeOf(YR));
   S.Write(Left,SizeOf(Double));
   S.Write(Top,SizeOf(Double));
   S.Write(Right,SizeOf(Double));
   S.Write(Bottom,SizeOf(Double));
   S.Write(LeftR,SizeOf(Integer));
   S.Write(TopR,SizeOf(Integer));
   S.Write(RightR,SizeOf(Integer));
   S.Write(BottomR,SizeOf(Integer));
   S.WriteString(Name);
   S.WriteString(FileName);
   S.Write(Mas,SizeOf(Mas));
   S.Write(Code,SizeOf(Code));
  {$IFDEF GEOMASTER}
   S.Write(CheckVisible,SizeOf(CheckVisible));
   S.Write(Dop,SizeOf(Dop));
   S.Put(Regions);
   S.Put(Properties);
  {$ENDIF}
  If FileExists(FileName) then
   StoreBIFParams(GetParams);
 end;

Procedure TBmpMgr.DrawBorder;
 var Pen:hPen;
 begin
//  If not GGraphSet.UseRastrRect then Exit;
  if Active then
   Pen:=SelectObject(GCanvas.Handle,CreatePen(ps_Solid,0,clRed)) else
   Pen:=SelectObject(GCanvas.Handle,CreatePen(ps_Solid,0,notCol(GGraphSet.ColWin)));
    DrawLine(Left,Top,Right,Top);DrawLine(Left,Top,Right,Top);
    DrawLine(Right,Top,Right,Bottom);DrawLine(Right,Bottom,Left,Bottom);
    DrawLine(Left,Top,Left,Bottom);
  DeleteObject(SelectObject(GCanvas.Handle,Pen));
 end;

Procedure TBmpMgr.Draw;
var I,J:Integer;Tw:TTwig;D:TDot;Rgn:hRgn;
    Xmm,Ymm:Double;First:Integer;
    Col,backCol,Transp:String;
    PaintBlackRectangle:Boolean;
Procedure PaintRect;
var Pen:hPen;Br:hBrush;Rop:Integer;
begin
 Rop:=SetRop2(GCanvas.Handle,R2_Not);
 Pen:=SelectObject(GCanvas.Handle,CreatePen(ps_Null,0,0));
  Br:=SelectObject(GCanvas.Handle,CreateSolidBrush(0));
   Rectangle(GCanvas.Handle,XPix(Left),YPix(Top),XPix(Right)+1,YPix(Bottom)+1);
  DeleteObject(SelectObject(GCanvas.Handle,Br));
 DeleteObject(SelectObject(GCanvas.Handle,Pen));
 SetRop2(GCanvas.Handle,Rop);
end;
begin
 PaintBlackRectangle:=False;
  if Box=nil then Exit;
  if Box.Bits=nil then Exit;
  If not CheckVisible then Exit;
//  Writeln('Name=',FileName);
  try
//  If ClassHandle=nil then
//   begin
  If SqlClose then Exit;
  Col:=GetProperty('Цвет');
  backCol:=GetProperty('Цвет фона');
  Transp:=GetProperty('Прозрачный фон');
  If ClassHandle=nil then begin
   If Col = byLayer then Box.Color:=WptForm.TForm(GTwgForm).Settings.bmColor else Box.Color:=StrToInt(Col);
   If backCol = byLayer then Box.BackColor:=WptForm.TForm(GTwgForm).Settings.bmBackColor else Box.BackColor:=StrToInt(backCol);
   If Transp = byLayer then Box.TransParent:=WptForm.TForm(GTwgForm).Settings.bmGlass else Box.TransParent:=Transp='Да';
  end else With ClassHandle do begin
    If Check=0 then Exit;
     If Col = byLayer then Box.Color:=LineColor else Box.Color:=StrToInt(Col);
     If backCol = byLayer then Box.BackColor:=Windows.RGB(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]) else Box.BackColor:=StrToInt(backCol);
     If Transp = byLayer then Box.TransParent:=GlassFon else Box.TransParent:=Transp='Да';
  end;
  If Box.TransParent then Box.Color:=wbColor(Box.Color);
  Box.backColor:=Box.backColor;
  Box.CopyMode:=cmSrcCopy;
  Box.Win32CopyMode:=SrcCopy;
  If Box.TransParent then begin
   If GlobalSettings.Settings.gsWindowColor = clBlack then begin
    If Box.BackColor=clWhite then Box.BackColor:=notColor(Box.BackColor);
    Box.Color:=Box.Color;
    Box.CopyMode:=cmSRCInvert;
    Box.Win32CopyMode:=SRCINVERT;
   end else
   If GlobalSettings.Settings.gsWindowColor = clWhite then begin
    Box.BackColor:=notColor(Box.BackColor);
    Box.Color:=notColor(Box.Color);
    Box.CopyMode:=cmSrcInvert;
    Box.Win32CopyMode:=SrcInvert;
    If TPcxBox(Box).Img.Bpp>1 then PaintBlackRectangle:=True;
   end;
  end;
{   end else With ClassHandle do begin
     If (Check=0) or (SqlClose) then Exit;
     Box.Color:=Windows.RGB(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]);
     Box.BackColor:=FColor;
     Box.TransParent:=Opaque;
    end;}
//    If Active then Box.Color:=GGraphSet.ActiveRasterCol;
    Box.Print:=False;
   // создаем области отсечения
    First:=-1;
    For I:=0 to Regions.Count-1 do begin
     Tw:=Regions[I];
     If Tw.Closed=0 then begin
      Inc(First);
      For J:=0 to Tw.Coord.Count-1 do begin
       D:=Tw.Coord[J];
       Xmm:=(D.XDot/Box.PPM*1000);Ymm:=(D.Ydot/Box.PPM*1000);
      // векторные координаты
       LotRgn[J+1].X:=XPix(Left+(Xmm*Mas)/1000);
       LotRgn[J+1].Y:=YPix(Top+(Ymm*Mas)/1000);
      end;
      Rgn:=CreatePolygonRgn(LotRgn,J,Winding);
      If First=0 then begin
       If Tw.What=0 then ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_And) else
       If Tw.What=10 then ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_Xor);
      end else begin
       If Tw.What=0 then ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_Or) else
       If Tw.What=10 then ExtSelectClipRgn(GCanvas.Handle,Rgn,RGN_Xor);
      end;                                       
      DeleteObject(Rgn);
     end;
    end;
   //
  //  If Box.TransParent then GV25.Color:=clBlack;
     Box.Paint(GCanvas);
   If PaintBlackRectangle then PaintRect;
  //  If Box.TransParent then GV25.Color:=clWhite;
   finally
    If WptForm.TForm(GTwgForm).Settings.bmFrame then DrawBorder;
    ExtSelectClipRgn(GCanvas.Handle,0,Rgn_Copy);
   end;
end;

procedure TBmpMgr.DrawRegions(Canvas:TCanvas);
var Tw,TwDraw:TTwig;I,J:Integer;D:TDot;Xmm,Ymm:Double;
    R2, Pen:hResult;
begin
 R2:=SetRop2(GCanvas.Handle,R2_NotXorPen);
 For I:=0 to Regions.Count-1 do begin
  Tw:=Regions[I];
  TwDraw:=TTwig.Create(0);
  If Tw.isVis then Pen:=SelectObject(GCanvas.Handle,CreatePen(ps_Dot,0,GlobalSettings.Settings.gsSelectColor));
   For J:=0 to Tw.Coord.Count-1 do begin
    D:=Tw.Coord[J];
    Xmm:=(D.XDot/Box.PPM*1000);Ymm:=(D.Ydot/Box.PPM*1000);
    X:=Left+(Xmm*Mas)/1000;Y:=Top+(Ymm*Mas)/1000;
   // векторные координаты
    TwDraw.Insert(TDot.Create(X,Y,0));
    If J<>Tw.Coord.Count-1 then Rectangle(GCanvas.Handle,XPix(X)-3,YPix(Y)-3,XPix(X)+3,YPix(Y)+3);
   end;
  TwDraw.Paint(GCanvas.Handle);
  If Tw.isVis then DeleteObject(SelectObject(GCanvas.Handle,Pen));
  TwDraw.Free;
 end;
 SetRop2(GCanvas.Handle,R2);
end;

function TBmpMgr.GetRegion(X, Y: Double; var Dot:TDot): Integer;
var Tw,TwDraw:TTwig;I,J,Index:Integer;D:TDot;Xmm,Ymm,Dist:Double;
    XX,YY:Double;
begin
 Dot:=nil;Result:=-1;
 For I:=0 to Regions.Count-1 do begin
  Tw:=Regions[I];Tw.isVis:=False;
  TwDraw:=TTwig.Create(0);
   For J:=0 to Tw.Coord.Count-1 do begin
    D:=Tw.Coord[J];
    Xmm:=(D.XDot/Box.PPM*1000);Ymm:=(D.Ydot/Box.PPM*1000);
    XX:=Left+(Xmm*Mas)/1000;YY:=Top+(Ymm*Mas)/1000;
   // векторные координаты
    TwDraw.Insert(TDot.Create(XX,YY,0));
   end;
   D:=TwDraw.GetNearestPoint(X,Y,Index);
   If XRasst(Distance(X,Y,D.XDot,D.YDot))<=GGraphSet.skShift then begin
    // захватили точку
    Tw.isVis:=True;
    Result:=I;
    Dot:=Tw.Coord[Index];
    exit;
   end else begin
    Dist:=TwDraw.GetTwigDist(X,Y,Xmm,Ymm);
    If XRasst(Dist)<=GGraphSet.skShift then begin
     // захватил ветку
     Result:=I;
     Tw.isVis:=True;
     exit;
    end;
   end;
   // узнаем захвачена ли точка
  TwDraw.Free;
 end;
end;

function TBmpMgr.XGeoToRaster(X: Double): Integer;
begin
 Result:=Round((X-Left)*Box.PPM/Mas);
end;

function TBmpMgr.YGeoToRaster(Y: Double): Integer;
begin
 Result:=Round((Y-Top)*Box.PPM/Mas);
end;

function TBmpMgr.XRasterToGeo(X: Integer): Double;
begin
 Result:=Left+((X/Box.PPM*1000)*Mas/1000);
end;

function TBmpMgr.YRasterToGeo(Y: Integer): Double;
begin
 Result:=Top+((Y/Box.PPM*1000)*Mas/1000);
end;

procedure TBmpMgr.DrawAs100;
begin
 if Box=nil then Exit;
 if Box.Bits=nil then Exit;
 If not CheckVisible then Exit;
end;

Procedure TBmpMgr.DevDraw;
var Xmm,Ymm:Double;XX,YY:Integer;First:Integer;
    I, J:Integer;
    Tw:TTwig;D:TDot;
    Rgn:hRgn;
    Col,backCol,Transp:String;
    WC:Integer;
    PaintBlackRectangle:Boolean;
Procedure Calc(X,Y:Double;var X1,Y1:Integer);
 var DXPrinter,DYPrinter:Integer;DXGeo,DYGeo:Extended;
 begin
  DXGeo:=-XGeoCent+X;DYGeo:=YGeoCent+Y;
   DXPrinter:=MMX(DXGeo/(GPrn.Mas/1000));
   DYPrinter:=MMY(DYGeo/(GPrn.Mas/1000));
  X1:=XPrintCent+DXPrinter;Y1:=YPrintCent+DYPrinter;
 end;
Procedure PaintRect;
var Pen:hPen;Br:hBrush;Rop:Integer;
begin
 Rop:=SetRop2(PrinterDc,R2_Not);
 Pen:=SelectObject(PrinterDc,CreatePen(ps_Null,0,0));
  Br:=SelectObject(PrinterDc,CreateSolidBrush(0));
   Rectangle(PrinterDc,LeftR,TopR,RightR+1,BottomR+1);
  DeleteObject(SelectObject(PrinterDc,Br));
 DeleteObject(SelectObject(PrinterDc,Pen));
 SetRop2(PrinterDc,Rop);
end;
Function prnVisible:boolean;
begin
 Result:=False;
 If Right<GSector.Left then Exit;
 If Left>GSector.Right then Exit;
 If Bottom<GSector.Top then Exit;
 If Top>GSector.Bottom then Exit;
 Result:=True;
end;                                                   
 begin                                                   
  PaintBlackRectangle:=False;
   if Box=nil then Exit;
   if Box.Bits=nil then Exit;
   If not CheckVisible then Exit;
   If not prnVisible then Exit;
//   Writeln('DevDraw=',FileName);
  // вычислим принтерные координаты
  Calc(Left,Top,LeftR,TopR);Calc(Right,Bottom,RightR,BottomR);
 {}
   Box.Left:=LeftR;Box.Width:=RightR-LeftR;
   Box.Top:=TopR;Box.Height:=BottomR-TopR;
 // передаем принтерные координаты планшета
   Box.RPrin.Left:=L;Box.RPrin.Top:=T;Box.RPrin.Right:=R;Box.RPrin.Bottom:=B;
 // конец
  Col:=GetProperty('Цвет');
  backCol:=GetProperty('Цвет фона');
  Transp:=GetProperty('Прозрачный фон');
  If ClassHandle=nil then begin
   If Col = byLayer then Box.Color:=WptForm.TForm(GTwgForm).Settings.bmColor else Box.Color:=StrToInt(Col);
   If backCol = byLayer then Box.BackColor:=WptForm.TForm(GTwgForm).Settings.bmBackColor else Box.BackColor:=StrToInt(backCol);
   If Transp = byLayer then Box.TransParent:=WptForm.TForm(GTwgForm).Settings.bmGlass else Box.TransParent:=Transp='Да';
  end else With ClassHandle do begin
    If Check=0 then Exit;
     If Col = byLayer then Box.Color:=LineColor else Box.Color:=StrToInt(Col);
     If backCol = byLayer then Box.BackColor:=Windows.RGB(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]) else Box.BackColor:=StrToInt(backCol);
     If Transp = byLayer then Box.TransParent:=GlassFon else Box.TransParent:=Transp='Да';
  end;
  WC:=GlobalSettings.Settings.gsWindowColor;
  GlobalSettings.Settings.gsWindowColor:=clWhite;
  If Box.TransParent then Box.Color:=wbColor(Box.Color);
  Box.backColor:=Box.backColor;
  Box.CopyMode:=cmSrcCopy;
  Box.Win32CopyMode:=SrcCopy;
  If Box.TransParent then begin
   If GlobalSettings.Settings.gsWindowColor = clBlack then begin
    If Box.BackColor=clWhite then Box.BackColor:=notColor(Box.BackColor);
    Box.Color:=Box.Color;
    Box.CopyMode:=cmSRCInvert;
    Box.Win32CopyMode:=SRCINVERT;
   end else
   If GlobalSettings.Settings.gsWindowColor = clWhite then begin
    Box.BackColor:=notColor(Box.BackColor);
    Box.Color:=notColor(Box.Color);
    Box.CopyMode:=cmSrcInvert;
    Box.Win32CopyMode:=SrcInvert;
    //If TPcxBox(Box).Img.Bpp>1 then PaintBlackRectangle:=True;
   end;
  end;
 try
//  Box.Color:=wbColor(Box.Color);
//  Box.backColor:=Box.backColor;
//  Box.Color:=wbColor(Box.Color);
//  Box.backColor:=wbColor(Box.backColor);
  {}
//    Box.BackColor:=notColor(Box.BackColor);
//    Box.Color:=notColor(Box.Color);
  {}
  GlobalSettings.Settings.gsWindowColor:=WC;
    Box.Print:=True;
    Box.PrinterDc:=Dc;
   // создаем области отсечения
    First:=-1;
    For I:=0 to Regions.Count-1 do begin
     Tw:=Regions[I];
     If Tw.Closed=0 then begin
      Inc(First);
      For J:=0 to Tw.Coord.Count-1 do begin
       D:=Tw.Coord[J];
       Xmm:=(D.XDot/Box.PPM*1000);Ymm:=(D.Ydot/Box.PPM*1000);
       Calc(Left+(Xmm*Mas)/1000,Top+(Ymm*Mas)/1000,XX,YY);
      // векторные координаты
       LotRgn[J+1].X:=XX;
       LotRgn[J+1].Y:=YY;                         
      end;
      Rgn:=CreatePolygonRgn(LotRgn,J,Winding);
      If First=0 then begin
       If Tw.What=0 then ExtSelectClipRgn(PrinterDc,Rgn,RGN_And) else
       If Tw.What=10 then ExtSelectClipRgn(PrinterDc,Rgn,RGN_Xor);
      end else begin
       If Tw.What=0 then ExtSelectClipRgn(PrinterDc,Rgn,RGN_Or) else
       If Tw.What=10 then ExtSelectClipRgn(PrinterDc,Rgn,RGN_Xor);
      end;
      DeleteObject(Rgn);                     
     end;
    end;
   //
  try                                                                          
    Box.Paint(nil);
    If (Box.TransParent)and(TPcxBox(Box).Img.bpp>1) then PaintRect;
  finally
    SelectClipRgn(PrinterDC,PrinterClipRgn);
  end;
 finally
  GlobalSettings.Settings.gsWindowColor:=WC;
 end;
//  DrawBorder;
{    Canvas.MoveTo(LeftR,TopR);Canvas.LineTo(RightR,TopR);Canvas.LineTo(RightR,BottomR);
    Canvas.LineTo(LeftR,BottomR);Canvas.LineTo(LeftR,TopR);}
 end;

Function TBmpMgr.Visible;
 begin
  Calculate;
  Result:=True;
   If Right<GRect.Left then begin Result:=False;end;
   If Left>GRect.Right then begin Result:=False;end;
   If Top>GRect.Top then begin Result:=False;end;
   If Bottom<GRect.Bottom then begin Result:=False;end;
 end;

Procedure TBmpMgr.Calculate;
 var Xmm,Ymm:Double;
 begin
  // Вычислим реальные координаты
   if Left=0 then
    begin
     Left:=GXMin;
     Top:=GYMin;
     X:=Left;Y:=Top;
    end;
  if Box=nil then Exit;  
  if Box.Bits=nil then Exit;
  // растровые координаты
   LeftR:=XPix(Left);TopR:=YPix(Top);
   Xmm:=(Box.biWidth/Box.PPM*1000);
   Ymm:=(Box.biHeight/Box.PPM*1000);
  // векторные координаты
   Right :=Left+(Xmm*Mas)/1000;
   Bottom:=Top+(Ymm*Mas)/1000;
   RightR:=XPix(Right);BottomR:=YPix(Bottom);
  {}
   Box.Left:=LeftR;Box.Width:=RightR-LeftR;
   Box.Top:=TopR;Box.Height:=BottomR-TopR;
  {}
 end;

Procedure TBmpMgr.SetNewPoint;
 var Xmm,Ymm:Double;
 begin
   XR:=XXR;YR:=YYR;
   if XX=0 then XX:=0.00001;
   X:=XX;Y:=YY;
  // расчет Left,Top относительно X,Y
  // расчитаем расстояния в миллиметрах
//  Writeln('BoxPPM=', Box.PPM);
   Xmm:=Round(XR/Box.PPM*1000);
   Ymm:=Round(YR/Box.PPM*1000);
  // расчитаем это расстояние в метрах
   Xmm:=(Xmm*Mas)/1000;
   Ymm:=(Ymm*Mas)/1000;
  // => Left= X - XMM и т.п
   Left:=X-Xmm;
   Top:=Y-Ymm;
 {}
   X:=Left;Y:=Top;
   XR:=0;YR:=0;
 end;

Procedure TBmpMgr.Move(Dx,Dy:Double);
 var Xmm,Ymm:Double;
 begin
   Left:=Left+Dx;
   Top:=Top+Dy;
   X:=Left;Y:=Top;
   XR:=0;YR:=0;
 end;

Procedure TBmpMgr.SetActive(V:Boolean);
 begin
  try
   DrawBorder; //процедура отключает планшет если он был активен
  except end;
  FActive:=V;
  try
   DrawBorder; //процедура отключает планшет если он был активен
  except end;
 end;

Function TBmpMgr.GetSect;
 begin
  //Calculate;
  Result.Left:=Left;
  Result.Top:=Top;
  Result.Right:=Right;
  Result.Bottom:=Bottom;
 end;

function TBmpMgr.Information: String;
begin
 Result:='';
 If Box.Bits=nil then begin Result:='не загружен' end else begin
  If Left=0 then Result:='нет данных привязки' else
  Result:='М 1:'+IntToStr(Mas);
 end
end;

function TBmpMgr.BIF: String;
var S:String;
begin
 // возвращает имя файла, в который на данный момент можно записать
 // данные о состоянии растра включая различные привязки .. хм выпил
 S:=GetBMFile('',FileName);
 S:=Copy(S,1,Length(S)-4)+'.ini';
 Result:=S;
end;

function TBmpMgr.LoadBIFParams(var Params: TRastrParam): boolean;
Const NULL = -10000000000;
var FName:String;Ini:TIniFile;S:String;
begin
 Result:=False;
 FName:=BIF;
 If FileExists(FName) then begin
  Ini:=TIniFile.Create(FName);
   S:=Ini.ReadString('Params','XGeo','*');
   If S<>'*' then Params.XGeo:=GStrToFloat(S) else Params.XGeo:=ZNULL;
   S:=Ini.ReadString('Params','YGeo','*');
   If S<>'*' then Params.YGeo:=GStrToFloat(S) else Params.YGeo:=ZNULL;
   Params.XR:=Ini.ReadInteger('Params','XR',-1);
   Params.YR:=Ini.ReadInteger('Params','YR',-1);
   Params.Name:=Name;
   Params.FName:=FileName;
   Params.Mas:=Ini.ReadInteger('Params','Scale',-1);
   Params.GUID:=StringToGUID(Ini.ReadString('Params','GUID',GUIDToString(GUID)));
  Ini.Free;
  With Params do Result:=(XGeo<>NULL)and(YGeo<>NULL)and(Mas<>-1)and(XR<>-1)and(YR<>-1);
 end;
end;

function TBmpMgr.StoreBIFParams(Params: TRastrParam): boolean;
var FName:String;Ini:TIniFile;
begin

 Move(0,0);
 Result:=False;
 FName:=BIF;
  Ini:=TIniFile.Create(FName);
//  If ExtractFileName(FName)='3461x.ini' then begin
  try
   Ini.WriteFloat('Params','XGeo',Params.XGeo);
   Ini.WriteFloat('Params','YGeo',Params.YGeo);
   Ini.WriteInteger('Params','XR',Params.XR);
   Ini.WriteInteger('Params','YR',Params.YR);
   Ini.WriteFloat('Params','Scale',Params.Mas);
   Ini.WriteString('Params','FileName',Params.FName);
   Ini.WriteString('Params','Name',Params.Name);
   Ini.WriteString('Params','GUID',GUIDToString(GUID));
  except end;
  Ini.Free;
//  end;
end;

function TBmpMgr.GetHint(P: Pointer): string;
begin
 Result:='Bitmap='+GUIDToString(GUID);
end;

function TBmpMgr.GUIDStr: String;
begin
 Result:=GUIDToString(GUID);
end;

constructor TBmpMgr.LoadDB(GUID_: TGUID; Stream: TBufStream);
begin
 GUID:=GUID_;
 Stream.Read(X,SizeOf(X));
 Stream.Read(Y,SizeOf(Y));
 Stream.Read(XR,SizeOf(XR));
 Stream.Read(YR,SizeOf(YR));
 Stream.Read(Left,SizeOf(Double));
 Stream.Read(Top,SizeOf(Double));
 Stream.Read(Right,SizeOf(Double));
 Stream.Read(Bottom,SizeOf(Double));
 Stream.Read(LeftR,SizeOf(Integer));
 Stream.Read(TopR,SizeOf(Integer));
 Stream.Read(RightR,SizeOf(Integer));
 Stream.Read(BottomR,SizeOf(Integer));
 Name:=Stream.ReadString;
 FileName:=Stream.ReadString;
 Stream.Read(Mas,SizeOf(Mas));
 Stream.Read(Code,SizeOf(Code));
 Stream.Read(CheckVisible,SizeOf(CheckVisible));
 Stream.Read(Dop,SizeOf(Dop));
 Regions:=PCollection(Stream.Get);
end;

procedure TBmpMgr.StoreDB(Stream: TBufStream);
begin
 Stream.Write(X,SizeOf(X));
 Stream.Write(Y,SizeOf(Y));
 Stream.Write(XR,SizeOf(XR));
 Stream.Write(YR,SizeOf(YR));
 Stream.Write(Left,SizeOf(Double));
 Stream.Write(Top,SizeOf(Double));
 Stream.Write(Right,SizeOf(Double));
 Stream.Write(Bottom,SizeOf(Double));
 Stream.Write(LeftR,SizeOf(Integer));
 Stream.Write(TopR,SizeOf(Integer));
 Stream.Write(RightR,SizeOf(Integer));
 Stream.Write(BottomR,SizeOf(Integer));
 Stream.WriteString(Name);
 Stream.WriteString(FileName);
 Stream.Write(Mas,SizeOf(Mas));
 Stream.Write(Code,SizeOf(Code));
 Stream.Write(CheckVisible,SizeOf(CheckVisible));
 Stream.Write(Dop,SizeOf(Dop));
 Stream.Put(Regions);
 StoreBIFParams(GetParams);
end;

//=============================================================================

Function TBmpMgr.SetProperty(propName: String; propValue: String;Obj:TTD = nil):boolean;
begin
// Writeln('SetProperty for Lot = '+propName+'  '+propValue);
 If Properties=nil then  begin
  If String(PropValue) = byLayer then exit;
  Properties:=TProperties.Create;
 end;
 If String(PropValue) = byLayer then begin
  Properties.DeleteProperty(propName);
  Result:=True;
  If Properties.Count = 0 then begin Properties.Free;Properties:=nil;end;
 end else begin
  Result:=True;
  If GetProperty(propName) <> propValue then Properties.AddProperty(propName,propValue) else Result:=False;
 end;
end;

function TBmpMgr.GetProperty(propName:String): String;
var V:TPropValue;
begin
 If Properties<>nil then begin
  V:=Properties.PropValue[propName];
  If V=nil then Result:=byLayer else Result:=V.Value;
 end else Result:=byLayer;
end;

procedure TBmpMgr.GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);
begin
  PropNames.Add('Цвет');PropNames.Add('Цвет фона');PropNames.Add('Прозрачный фон');PropNames.Add('Масштаб листа');
  If PropTypes<>nil then begin propTypes.Add('Color');propTypes.Add('Color');propTypes.Add('Boolean');propTypes.Add('Integer');end;
  If propValues<>nil then begin propValues.Add(GetProperty('Цвет'));propValues.Add(GetProperty('Цвет фона'));propValues.Add(GetProperty('Прозрачный фон'));propValues.Add(GetProperty('Масштаб листа'));end;
end;

procedure TBmpMgr.GetPropMerge(Obj:TTD;propNames,propValues,propTypes: TStrings);
var I,Index:Integer;
begin
 If propNames.Count=0 then begin
  GetObjectProps(propNames,propValues,propTypes);
 end else begin
  If (Obj is Self.ClassType) then Exit;
 //
  Index:=propNames.IndexOf('Цвет');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Цвет фона');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Прозрачный фон');If Index<>-1 then propNames.Objects[Index]:=Self;
  Index:=propNames.IndexOf('Масштаб листа');If Index<>-1 then propNames.Objects[Index]:=Self;
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
 end;
end;


procedure TBmpMgr.MergeProperties(Obj: TTD;Flag:Boolean);
begin
//
end;

function TBmpMgr.GetLayer: TResource;
begin
 Result:=ClassHandle;
end;

procedure TBmpMgr.SetLayer(PR: TResource);
begin
 ClassHandle:=PR;Code:=PR.ID;
end;

procedure TBmpMgr.DeleteProperty(propName: String);
begin
 //
end;

procedure TBmpMgr.AddProperty(propName: String);
begin
 //
end;

function TBmpMgr.UseProperty(propName: String): boolean;
begin
 Result:=False;
 If Properties<>nil then Result:=Properties.PropValue[propName]<>nil;
end;

{ TBmpSet }


Constructor TBmpSet.Create;
 begin
  FileName:='';
  FActive:=-1;
  BitMaps:=PCollection.Create(1);
 end;

Procedure TBmpSet.RebuildBmDirs;
 var I:Integer;
 begin
  For I:=0 to BitMaps.Count-1 do
   BitMap[I].BmName:=MainPath+'\Images\'+Copy(ExtractFileName(FileName),1,Length(ExtractFileName(FileName))-3)+'.Dir';
 end;

Constructor TBmpSet.Load;
 begin
  FileName:=S.ReadString;
  BitMaps:=PCollection(S.Get);
  If Version>42 then begin
   S.Read(FActive,SizeOf(FActive));
  end else FActive:=-1;
  if BitMaps.Count=1 then Bitmap[0].FActive:=True else
  if BitMaps.Count=0 then FActive:=-1 else Active:=FActive;
  RebuildBmDirs;
 end;

Procedure TBmpSet.Store;
 begin
  S.WriteString(FileName);
  S.Put(BitMaps);
  S.Write(FActive,SizeOf(FActive));
 end;

Procedure TBmpSet.Draw;
 var I,J:Integer;
 begin
  J:=-1;
  For I:=0 to Bitmaps.Count-1 do begin
   if Bitmap[I].Visible then
    begin
     Bitmap[I].Draw;
     if (Bitmap[I].Active) and (Bitmap[I].CheckVisible) then J:=I;
    end;
  end;
  if J<>-1 then If WptForm.TForm(GTwgForm).Settings.BmFrame then Bitmap[J].DrawBorder;
 end;

Procedure TBmpSet.DevDraw;
 var I:Integer;
 begin
  For I:=0 to Bitmaps.Count-1 do
   Bitmap[I].DevDraw(Dc,XGeoCent,YGeoCent,XPrintCent,YPrintCent,L,T,R,B);
 end;

Procedure TBmpSet.ClearBitmaps;
 begin
  Bitmaps.FreeAll;
  FActive:=-1;
 end;

Procedure TBmpSet.DeleteBitmap;
 begin
  Bitmaps.AtFree(Index);
 end;

Function TBmpSet.GetBitmap;
begin
  If Index=-1 then Result:=nil else Result:=Bitmaps[Index];
end;

Procedure TBmpSet.SetActive;
 var I:Integer;
 begin
   For I:=0 to Bitmaps.Count-1 do
     Bitmap[I].FActive:=False;
 {}
  if V=-1 then Exit;
  if V>Bitmaps.Count-1 then Exit;
 {}
  Bitmap[V].Active:=True;
  FActive:=V;
 end;

Function TBmpSet.GetGabarites:TSect;
var R,R2:TSect;I:Integer;
 begin
  if Bitmaps.Count=0 then Exit;
  R:=Bitmap[0].GetSect;
  For I:=1 to Bitmaps.Count-1 do
   begin
    R2:=Bitmap[I].GetSect;
    if R2.Left<R.Left then R.Left:=R2.Left;
    if R2.Top<R.Top then R.Top:=R2.Top;
    if R2.Right>R.Right then R.Right:=R2.Right;
    if R2.Bottom>R.Bottom then R.Bottom:=R2.Bottom;
   end;
  Result:=R;
 end;

function TBmpSet.PointIn(X, Y: Double): Integer;
 var I:Integer;
begin
 Result:=-1;
 For I:=0 to Bitmaps.Count-1 do
  If Bitmap[I].CheckVisible then
  If PointInSect(X,Y,Bitmap[I].GetSect) then begin Result:=I;Exit;end;
end;

function TBmpSet.VisibleActiveRaster: TBmpMgr;
begin
 Result:=nil;
 If Active<>-1 then If Bitmap[Active].CheckVisible then Result:=Bitmap[Active];
end;

destructor TBmpSet.Destroy;
begin
  inherited;
  Bitmaps.Free;
end;

function TBmpSet.Count: Integer;
begin
// Writeln(111);
 Result:=Bitmaps.Count;
// Writeln(112);
end;

Function TemporaryPath:String;
var P:Array[0..255] of AnsiChar;
 begin
  GetTempPath(256,P);
  Result:=P;
  If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
 end;

Initialization
 RegisterObject(TBmpMgr,101);
 RegisterObject(TBmpSet,102);
end.
