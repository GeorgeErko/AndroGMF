unit RPrims;
interface uses Collect, RBitBox, SysUtils, Classes,
               IniFiles, TwgDraw, userObject, newProperties, FMX.Graphics,
               newConsts, EcDot, newSelector, newResource, tmpPainter;


type
  TRastrParam=record
   GUID:TGUID;
    Name,FName:AnsiString;
    Mas,XR,YR:Integer;
    XGeo,YGeo:Double;
    Sloy:Double;
    Vkl:Boolean;
    Properties:TProperties;
    Selector:TSelector;
   end;

Type
 TBmpMgr=class(TTD)
  private
   fSelector:TSelector;
  public
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
   Name:AnsiString;//имя растра в регистрационной базе
   FileName:AnsiString;//имя файла
   NotInit:boolean;
  {}
   Box:TBitBox;
  {}
   BMName:AnsiString;
   SqlClose:Boolean;
   CheckVisible:Boolean;
   Dop:Array[1..100] of byte;
   Regions:PCollection;
   Color,BackColor:Integer;
   Properties:TProperties;
   Selector:TSelector;
    Function  GetSelector:TSelector;override;
    Procedure SetSelector(S:TSelector);override;
    Constructor CreateAsParam(P:TRastrParam;BM:AnsiString);
    Destructor Destroy;override;
    Constructor Load(S:TBufStream);override;
    Procedure   Store(S:TBufStream);override;
  {}
    Function  EqualParams(P:TRastrParam):Boolean;
    Procedure SetParams(P:TRastrParam);
    Function  GetParams:TRastrParam;
    Procedure InitBox;
  {}
    Function GetRegion(X,Y:Double;var Dot:TDot):Integer;//Flag =  -1 - за пределами, 0 - в пределах, 1 - на границе, 2 - на точке
    Procedure DrawAs100;
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
    Function Information:AnsiString;
  { Работа с файлом инициализации }
    Function BIF:AnsiString; // имя файла инициализации
    Function LoadBIFParams(var Params:TRastrParam):boolean;
    Function StoreBIFParams(Params:TRastrParam):boolean;
    Function GetHint(P:Pointer=nil):AnsiString;override;
   //
    Function GUIDStr:AnsiString;
   { Процедуры загрузки из базы данных }
    Constructor   LoadDB(GUID_:TGUID;Stream:TBufStream);
    Procedure     StoreDB(Stream:TBufStream);
   // свойства
    Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
    Function GetProperty(propName:AnsiString):AnsiString;override;
    Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
    Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
    function GetLayer: TResource;
    procedure SetLayer(PR: TResource);
    Function UseProperty(propName: AnsiString): boolean;override;
    Procedure DeleteProperty(propName: AnsiString);override;
    procedure MergeProperties(Obj: TTD;Flag:Boolean);override;
    procedure AddProperty(propName: AnsiString);override;
  end;

 TBmpSet=class(TTD)
   FileName:AnsiString;// имя файла регистрации
   Bitmaps :PCollection;
   FActive :Integer;
  {}
   Selector:TSelector;
    Constructor Create;
    Destructor Destroy;override;
    Procedure RebuildBmDirs;
    Constructor Load(S:TBufStream);override;
    Procedure   Store(S:TBufStream);override;
  {}
    Procedure Draw;
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

 Function GetBMFile(BMName,FName:AnsiString):AnsiString;
 Function TemporaryPath:AnsiString;

implementation uses WPTForm2, newProcs, WpTwigs, EcLot,
                    Maths_basic;

Function GetBMFile;
var S,S2:TStrings;I,J:Integer;
    FN:AnsiString;
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
//    if Session.isAlias(S[I]) then
     begin // узнаем путь к данным, если они не клиент-серверные
//      S2:=TAnsiStringList.Create;
//      Session.GetAliasParams(S[I],S2);
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

{ TBmpMgr }

Constructor TBmpMgr.CreateAsParam;
 begin
  Selector:=P.Selector;
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
  With Selector do begin
   Box:=TBitBox.Create(GNForm);
  // TBitBox(Box).QueryDPI:=False;
   Box.Initialize(GNForm,GCanvas);
   Box.UseStretch:=True;
   Box.UseStandart:=False;
   Box.BackColor:=TForm2(GTwgForm).Settings.bmBackColor;
   Box.Color:=TForm2(GTwgForm).Settings.bmColor;
  end;
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
 var S:AnsiString;
{ const xxxx: integer = 0;
       zzzz: integer = 0;}
 begin
{ Инициализация растра }
 If Box<>nil then Box.Free;
{ If UpperCase(ExtractFileExt(FileName))='.BMP' then
  Box:=TBitBox.Create(GnForm) else}
  With Selector do begin
   Box:=TBitBox.Create(GnForm);
  // TPcxBox(Box).QueryDPI:=False;
   Box.Bits:=nil;
   Box.Initialize(GNForm,GCanvas);
   Box.UseStretch:=True;
   Box.UseStandart:=False;
   Box.BackColor:=GGraphSet.bmBack;
   Box.Color:=GGraphSet.bmColor;
  end;
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
 var S:AnsiString;
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
  Selector:=S.Selector;
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
   If newConsts.Version>33 then begin
    S.Read(CheckVisible,SizeOf(CheckVisible));
    S.Read(Dop,SizeOf(Dop));
    If newConsts.Version>34 then begin
     Regions:=PCollection(S.Get);
     If newConsts.Version>37 then Properties:=TProperties(S.Get);
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
   S.Write(CheckVisible,SizeOf(CheckVisible));
   S.Write(Dop,SizeOf(Dop));
   S.Put(Regions);
   S.Put(Properties);
  If FileExists(FileName) then
   StoreBIFParams(GetParams);
 end;

function TBmpMgr.GetRegion(X, Y: Double; var Dot:TDot): Integer;
var Tw,TwDraw:TTwig;I,J,Index:Integer;D:TDot;Xmm,Ymm,Dist:Double;
    XX,YY:Double;
begin
 Dot:=nil;Result:=-1;
 With Selector do
 For I:=0 to Regions.Count-1 do begin
  Tw:=Regions[I];Tw.isVis:=False;
  TwDraw:=TTwig.Create(Selector, 0);
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

Function TBmpMgr.Visible;
 begin
  Calculate;
  Result:=True;
  With Selector do begin
   If Right<GRect.Left then begin Result:=False;end;
   If Left>GRect.Right then begin Result:=False;end;
   If Top>GRect.Top then begin Result:=False;end;
   If Bottom<GRect.Bottom then begin Result:=False;end;
  end;
 end;

Procedure TBmpMgr.Calculate;
 var Xmm,Ymm:Double;
 begin
  // Вычислим реальные координаты
  With Selector do begin
   if Left=0 then
    begin
     Left:= Selector.GlobalRect.XMin;
     Top := Selector.GlobalRect.YMin;
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
  end;
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
  FActive:=V;
 end;

Function TBmpMgr.GetSect;
 begin
  //Calculate;
  Result.Left:=Left;
  Result.Top:=Top;
  Result.Right:=Right;
  Result.Bottom:=Bottom;
 end;

function TBmpMgr.GetSelector: TSelector;
begin
 Result:=fSelector;
end;

function TBmpMgr.Information: AnsiString;
begin
 Result:='';
 If Box.Bits=nil then begin Result:='не загружен' end else begin
  If Left=0 then Result:='нет данных привязки' else
  Result:='М 1:'+IntToStr(Mas);
 end
end;

function TBmpMgr.BIF: AnsiString;
var S:AnsiString;
begin
 // возвращает имя файла, в который на данный момент можно записать
 // данные о состоянии растра включая различные привязки .. хм выпил
 S:=GetBMFile('',FileName);
 S:=Copy(S,1,Length(S)-4)+'.ini';
 Result:=S;
end;

function TBmpMgr.LoadBIFParams(var Params: TRastrParam): boolean;
Const NULL = -10000000000;
var FName:AnsiString;Ini:TIniFile;S:AnsiString;
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
var FName:AnsiString;Ini:TIniFile;
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

function TBmpMgr.GetHint(P: Pointer): AnsiString;
begin
 Result:='Bitmap='+GUIDToString(GUID);
end;

function TBmpMgr.GUIDStr: AnsiString;
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

Function TBmpMgr.SetProperty(propName: AnsiString; propValue: AnsiString;Obj:TTD = nil):boolean;
begin
// Writeln('SetProperty for Lot = '+propName+'  '+propValue);
 If Properties=nil then  begin
  If AnsiString(PropValue) = byLayer then exit;
  Properties:=TProperties.Create;
 end;
 If AnsiString(PropValue) = byLayer then begin
  Properties.DeleteProperty(propName);
  Result:=True;
  If Properties.Count = 0 then begin Properties.Free;Properties:=nil;end;
 end else begin
  Result:=True;
  If GetProperty(propName) <> propValue then Properties.AddProperty(propName,propValue) else Result:=False;
 end;
end;

procedure TBmpMgr.SetSelector(S: TSelector);
begin
 fSelector:=S;
end;

function TBmpMgr.GetProperty(propName:AnsiString): AnsiString;
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

procedure TBmpMgr.DeleteProperty(propName: AnsiString);
begin
 //
end;

procedure TBmpMgr.AddProperty(propName: AnsiString);
begin
 //
end;

function TBmpMgr.UseProperty(propName: AnsiString): boolean;
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
  Selector:=S.Selector;
  FileName:=S.ReadString;
  BitMaps:=PCollection(S.Get);
  If newConsts.Version>42 then begin
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
    // Bitmap[I].Draw;
     if (Bitmap[I].Active) and (Bitmap[I].CheckVisible) then J:=I;
    end;
  end;
 // if J<>-1 then If TForm1(Selector.GTwgForm).Settings.BmFrame then Bitmap[J].DrawBorder;
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
  If Selector.PointInSect(X,Y,Bitmap[I].GetSect) then begin Result:=I;Exit;end;
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

Function TemporaryPath:AnsiString;
 begin
 // Result:=GetTempDir;
 // If Result[Length(Result)]='\' then SetLength(Result,Length(Result)-1);
 end;

Initialization
end.
