library gmfreader;

// Читатель GMF в отдельной библиотеке: Win64 - gmfreader.dll, Android64 - libgmfreader.so.
// Собирается со старыми модулями GMF и JSON\ogcBasic, поэтому не конфликтует
// с иерархией GRAPHER в вызывающей программе. Контракт - gmfReaderAPI.pas.
// Обязательно: Project Options > Building > Delphi Compiler > Conditional defines =
// GMF_READER (все конфигурации и платформы) - иначе в библиотеку попадают формы
// приложения (FramePropEditor -> MainFrm и диалоги).

{$DEFINE GMF_READER}

{$IFNDEF GMF_READER}
  {$MESSAGE ERROR 'gmfreader: добавьте GMF_READER в Conditional defines проекта'}
{$ENDIF}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  gmfReaderAPI in 'gmfReaderAPI.pas',
  gmfReaderDrawer in 'gmfReaderDrawer.pas',
  Circle in '..\..\GMF\Circle.pas',
  circle_di in '..\..\GMF\circle_di.pas',
  Collect in '..\..\GMF\Collect.pas',
  drawGrid in '..\..\GMF\drawGrid.pas',
  dsolve in '..\..\GMF\dsolve.pas',
  dwgtext in '..\..\GMF\dwgtext.pas',
  EcDot in '..\..\GMF\EcDot.pas',
  EcDot2 in '..\..\GMF\EcDot2.pas',
  ECLot in '..\..\GMF\ECLot.pas',
  ECText in '..\..\GMF\ECText.pas',
  EMath in '..\..\GMF\EMath.pas',
  GBFWUndo in '..\..\GMF\GBFWUndo.pas',
  GMFLTDrawer in '..\..\GMF\GMFLTDrawer.pas',
  HatchLot in '..\..\GMF\HatchLot.pas',
  intervals in '..\..\GMF\intervals.pas',
  LConvEncoding in '..\..\GMF\LConvEncoding.pas',
  Lib in '..\..\GMF\Lib.pas',
  LIB2 in '..\..\GMF\LIB2.PAS',
  Lines2 in '..\..\GMF\Lines2.pas',
  Lines3 in '..\..\GMF\Lines3.pas',
  maths_basic in '..\..\GMF\maths_basic.pas',
  Maths_Lines in '..\..\GMF\Maths_Lines.pas',
  maths_versia in '..\..\GMF\maths_versia.pas',
  mpMarker in '..\..\GMF\mpMarker.pas',
  newBlock in '..\..\GMF\newBlock.pas',
  newClassBuilder in '..\..\GMF\newClassBuilder.pas',
  newConsts in '..\..\GMF\newConsts.pas',
  newFontScale in '..\..\GMF\newFontScale.pas',
  newForm0 in '..\..\GMF\newForm0.pas',
  newLayersTable in '..\..\GMF\newLayersTable.pas',
  newpainter in '..\..\GMF\newpainter.pas',
  newProcs in '..\..\GMF\newProcs.pas',
  newProperties in '..\..\GMF\newProperties.pas',
  newResource in '..\..\GMF\newResource.pas',
  newSelector in '..\..\GMF\newSelector.pas',
  newSettings in '..\..\GMF\newSettings.pas',
  newUtil in '..\..\GMF\newUtil.pas',
  notLink_ in '..\..\GMF\notLink_.pas',
  ObjBlockList in '..\..\GMF\ObjBlockList.pas',
  objOutline in '..\..\GMF\objOutline.pas',
  ogcBasic in '..\..\JSON\ogcBasic.pas',
  ogcCaptureIntf in '..\..\JSON\ogcCaptureIntf.pas',
  ogcDrawerSkia in '..\..\JSON\ogcDrawerSkia.pas',
  ogcMarker in '..\..\JSON\ogcMarker.pas',
  ogcMathUtils in '..\..\JSON\ogcMathUtils.pas',
  ogcPolyPolyline in '..\..\JSON\ogcPolyPolyline.pas',
  polygons in '..\..\GMF\polygons.pas',
  RBitBox in '..\..\GMF\RBitBox.pas',
  RPrims in '..\..\GMF\RPrims.pas',
  SelectedObjects in '..\..\GMF\SelectedObjects.pas',
  SelectorObj in '..\..\GMF\SelectorObj.pas',
  Splines in '..\..\GMF\Splines.pas',
  Tata3 in '..\..\GMF\Tata3.pas',
  textmanager in '..\..\GMF\textmanager.pas',
  tmppainter in '..\..\GMF\tmppainter.pas',
  TwgBitmaps in '..\..\GMF\TwgBitmaps.pas',
  TwgColle in '..\..\GMF\TwgColle.pas',
  TwgDraw in '..\..\GMF\TwgDraw.pas',
  types2 in '..\..\GMF\types2.pas',
  Types_dimano in '..\..\GMF\Types_dimano.pas',
  uExecRegisterClass in '..\..\uExecRegisterClass.pas',
  UndoColNew in '..\..\GMF\UndoColNew.pas',
  UndoItem in '..\..\GMF\UndoItem.pas',
  UndoStream in '..\..\GMF\UndoStream.pas',
  UpdateMessages in '..\..\GMF\UpdateMessages.pas',
  UserObject in '..\..\GMF\UserObject.pas',
  Util in '..\..\GMF\Util.pas',
  WpArcs in '..\..\GMF\WpArcs.pas',
  WpGeo in '..\..\GMF\WpGeo.pas',
  WpRects in '..\..\GMF\WpRects.pas',
  WPTForm0 in '..\..\GMF\WPTForm0.pas',
  WPTForm1 in '..\..\GMF\WPTForm1.pas',
  WPTForm12 in '..\..\GMF\WPTForm12.pas',
  WPTForm2 in '..\..\GMF\WPTForm2.pas',
  WpTwigs in '..\..\GMF\WpTwigs.pas',
  Writer in '..\..\GMF\Writer.pas'
  {$IFDEF ANDROID}, Androidapi.Log{$ENDIF};

var LastError: String;

// временная отладка: без строк Delphi и менеджера памяти - работает и без инициализации RTL библиотеки
procedure RawTrace(Msg: PAnsiChar);
begin
{$IFDEF ANDROID}
 __android_log_write(ANDROID_LOG_INFO, 'DELPHI', Msg);
{$ENDIF}
end;

function gmfReaderVersion: Integer; cdecl;
begin
// RawTrace('gmfreader.so: raw version');
// WriteIn(['gmfreader.so: version']);
 Result := cGMFReaderVersion;
end;

function gmfReaderOpen(FileName, AppPath: PChar; Callback: TgmfReaderCallback;
                       UserData: Pointer): Integer; cdecl;
var Path, Msg: String;
    Drawer: TgmfReaderDrawer;
    Selector: TSelector;
    Stream: TBufStream;
    Obj: TObject;
    TwgForm: TForm2;
    Info: TgmfReaderInfo;
    I, J: Integer;
    B: Byte;
    PP: TPointDot;
    Twig: TTwig;
begin
 RawTrace('gmfreader.so: 00 raw enter');
// пробы RTL библиотеки: менеджер памяти, String -> AnsiString, UTF-8
 if DefaultSystemCodePage = 1251 then RawTrace('gmfreader.so: 00a CodePage=1251') else RawTrace('gmfreader.so: 00a CodePage<>1251 (главный блок не выполнялся?)');
 Path := 'gmf';
 Path := Path + 'reader';
 RawTrace('gmfreader.so: 00b String concat (GetMem) ok');
 Msg := IntToStr(DefaultSystemCodePage);
 RawTrace('gmfreader.so: 00c IntToStr ok');
 RawTrace(PAnsiChar(UTF8Encode(Msg)));
 RawTrace('gmfreader.so: 00d UTF8Encode ok');
 RawTrace(PAnsiChar(AnsiString(Path)));
 RawTrace('gmfreader.so: 00e AnsiString ok');
 WriteIn(['gmfreader.so: 01 enter']);
 LastError := '';
 WriteIn(['gmfreader.so: 02 LastError']);
 try
  Path := String(FileName);
  WriteIn(['gmfreader.so: 03 Path=', Path]);
  if not FileExists(Path) then begin
   LastError := 'Файл не найден: ' + Path;
   WriteIn(['gmfreader.so: 04 ', LastError]);
   exit(gmfErrFileNotFound);
  end;
  WriteIn(['gmfreader.so: 04 FileExists']);
 // регистрация классов GMF для TBufStream.Get (в AndroGMF - при запуске)
  RegPrimitives;
  WriteIn(['gmfreader.so: 05 RegPrimitives']);
 // MainPath - каталог вызывающей программы (классификатор, настройки);
 // по умолчанию: Windows - каталог exe (ParamStr(0) в dll - exe вызывающей
 // программы), Android - каталог данных приложения, как в AndroGMF
  if (AppPath <> nil) and (AppPath^ <> #0) then newProcs.MainPath := AnsiString(String(AppPath)) else
{$IFDEF ANDROID}
   newProcs.MainPath := AnsiString(TPath.GetDocumentsPath);
{$ELSE}
   newProcs.MainPath := AnsiString(ExtractFilePath(ParamStr(0)));
{$ENDIF}
  WriteIn(['gmfreader.so: 06 MainPath=', String(newProcs.MainPath)]);
 // Selector с невизуальным рисователем: примитивы получают область окна
 // через Drawer (Width/Height); контрола нет (GNForm = nil)
  Drawer := TgmfReaderDrawer.CreateSize(1024, 1024);
  WriteIn(['gmfreader.so: 07 Drawer']);
  Selector := TSelector.Create(Drawer);
  WriteIn(['gmfreader.so: 08 Selector']);
  try
   Stream := TBufStream.InitFileStream(AnsiString(Path), fmOpenRead);
   WriteIn(['gmfreader.so: 09 InitFileStream']);
   try
    Stream.Selector := Selector;
    WriteIn(['gmfreader.so: 10 Stream.Selector']);
    Obj := Stream.Get;
    if Obj = nil then WriteIn(['gmfreader.so: 11 Get = nil']) else WriteIn(['gmfreader.so: 11 Get ', Obj.ClassName]);
   finally
    Stream.Free;
   end;
   WriteIn(['gmfreader.so: 12 Stream.Free']);
   if not (Obj is TForm2) then begin
    Obj.Free;
    LastError := 'Файл не является картой GMF: ' + Path;
    WriteIn(['gmfreader.so: 13 ', LastError]);
    exit(gmfErrNotGMF);
   end;
   TwgForm := TForm2(Obj);
   WriteIn(['gmfreader.so: 13 TForm2']);
   try
   // окружение Selector после загрузки - как в TMainForm.OpenGmfFile
    Selector.GLineCol := TwgForm.MkLib.LSLib;
    Selector.GSqwearCol := TwgForm.MkLib.SSLib;
    Selector.GPointCol := TwgForm.MkLib.PSLib;
    WriteIn(['gmfreader.so: 14 MkLib']);
    Selector.GFontCollect := TwgForm.Twigs.FontS;
    Selector.GFontSet := TwgForm.Twigs.FontSet;
    Selector.GGraphSet := TwgForm.fGraphSet;
    WriteIn(['gmfreader.so: 15 FontS/FontSet/GraphSet']);
    if TwgForm.FontColEx <> nil then
     for I := 0 to TwgForm.Twigs.AnyCount - 1 do begin
      PP := TwgForm.Twigs.AAt(I, B);
      PP.ResetParams(param_idResetFontView, TwgForm.FontColEx);
     end;
    WriteIn(['gmfreader.so: 16 ResetFontView']);
   // габариты карты по ветвям и окно на всю карту
    for I := 1 to TwgForm.Twigs.TwigsCount - 1 do begin
     Twig := TwgForm.Twigs.TAt(I);
     for J := 0 to Twig.Coord.Count - 1 do Selector.AddCoord(Twig[J].XDot, Twig[J].YDot);
    end;
    WriteIn(['gmfreader.so: 17 AddCoord']);
    Selector.UpdateRects(True);
    WriteIn(['gmfreader.so: 18 UpdateRects']);
   //
    FillChar(Info, SizeOf(Info), 0);
    Info.Size := SizeOf(Info);
    Info.LotsCount := TwgForm.Twigs.LotsCount;
    Info.TwigsCount := TwgForm.Twigs.TwigsCount;
    Info.AnyCount := TwgForm.Twigs.AnyCount;
    if TwgForm.Twigs.BlockList <> nil then Info.BlocksCount := TwgForm.Twigs.BlockList.Count;
    WriteIn(['gmfreader.so: 19 Info']);
   // кириллица в сообщении - проверка передачи строк через границу библиотеки
    Msg := Format('Файл %s: контуров %d, ветвей %d, точек и текстов %d, блоков %d',
                  [ExtractFileName(Path), Info.LotsCount, Info.TwigsCount, Info.AnyCount, Info.BlocksCount]);
    if Assigned(Callback) then Callback(UserData, @Info, PChar(Msg));
    WriteIn(['gmfreader.so: 20 Callback']);
    Result := Info.LotsCount;
   finally
    TwgForm.Free;
    WriteIn(['gmfreader.so: 21 TwgForm.Free']);
   end;
  finally
   Selector.Free;
   Drawer.Free;
   WriteIn(['gmfreader.so: 22 Selector/Drawer.Free']);
  end;
 except
  on E: Exception do begin
   LastError := E.ClassName + ': ' + E.Message;
   WriteIn(['gmfreader.so: exception ', LastError]);
   Result := gmfErrLoad;
  end;
 end;
end;

function gmfReaderLastError(Buf: PChar; BufLen: Integer): Integer; cdecl;
begin
 Result := Length(LastError);
 if (Buf <> nil) and (BufLen > 0) then StrPLCopy(Buf, LastError, BufLen - 1);
end;

exports
  gmfReaderVersion,
  gmfReaderOpen,
  gmfReaderLastError;

begin
 RawTrace('gmfreader.so: raw main block');
 WriteIn(['gmfreader.so: main block']);
{$IFDEF ANDROID}
// AnsiString <-> String через cp1251 - как в AndroGMF (AndroGMF.dpr):
// строки GMF (имена, пути классификатора) хранятся в cp1251
 SetMultiByteConversionCodePage(1251);
{$ENDIF}
end.
