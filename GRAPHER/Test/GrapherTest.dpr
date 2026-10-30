program GrapherTest;

// Windows: консольное приложение - отладочный вывод WriteIn (Writeln) в консоль
{$IFDEF MSWINDOWS}
{$APPTYPE CONSOLE}
{$ENDIF}

// Тестовый FMX-проект иерархии GRAPHER (TogsMapSpace + ogcSkiaDrawer).
// Рядом с exe (или в папке проекта) ожидаются sample.geojson и папка Fonts.

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  Writer in '..\..\GMF\Writer.pas',
  ogcMemStream in '..\ogcMemStream.pas',
  ogcBasic in '..\ogcBasic.pas',
  ogcMathUtils in '..\ogcMathUtils.pas',
  ogcProperties in '..\ogcProperties.pas',
  ogcClipPolyline in '..\ogcClipPolyline.pas',
  ogcGeometry in '..\ogcGeometry.pas',
  ttfGeometry in '..\ttfGeometry.pas',
  ogcCallbackTypes in '..\ogcCallbackTypes.pas',
  ogcLType in '..\ogcLType.pas',
  ogcTypedCollect in '..\ogcTypedCollect.pas',
  ogcLTDrawer in '..\ogcLTDrawer.pas',
  GMFGeometry in '..\GMFGeometry.pas',
  ogcMapSpace in '..\ogcMapSpace.pas',
  ogcSkiaDrawer in '..\ogcSkiaDrawer.pas',
  GrapherTestMain in 'GrapherTestMain.pas' {FormGrapherTest},
  ogcMapIndex in '..\ogcMapIndex.pas';

{$R *.res}

begin
{$IFDEF ANDROID}
// строки GMF (AnsiString) - cp1251, как в AndroGMF
  SetMultiByteConversionCodePage(1251);
{$ENDIF}
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TFormGrapherTest, FormGrapherTest);
  Application.Run;
end.
