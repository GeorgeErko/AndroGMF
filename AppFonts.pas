unit AppFonts;

// размер шрифта по умолчанию на Android (FMX: Android 14, Windows 12):
// служба IFMXSystemFontService подменяется своей, чтобы TLabel, TCheckBox,
// TButton и др. (Size в StyledSettings) имели тот же размер, что и в Windows.
// Модуль должен стоять в uses .dpr до модулей с формами.
// UnfixButtonHeights - высота TSpeedButton и TToolBar не навязывается стилем
// платформы (FixedHeight: Android 48), оформление стиля не меняется

interface

const
 Font_Size_For_Android_Const = 12;

// стиль платформы: у speedbuttonstyle и toolbarstyle снимается FixedHeight -
// кнопки и тулбары получают высоту из формы (Height). Вызов - в .dpr после
// Application.Initialize, до создания форм: элементы берут стиль из
// исправленного образца
procedure UnfixButtonHeights;

implementation

uses System.Types, FMX.Types, FMX.Controls, FMX.Styles{$IFDEF ANDROID}, FMX.Platform, FMX.Graphics{$ENDIF};

procedure UnfixButtonHeights;
const Names: array[0..1] of String = ('speedbuttonstyle', 'toolbarstyle');
var S, R: TFmxObject;
    N: String;
begin
 S := TStyleManager.ActiveStyle(nil);
 if S = nil then exit;
 for N in Names do begin
  R := S.FindStyleResource(N);
  if R is TControl then TControl(R).FixedSize := TSize.Create(0, 0);
 end;
end;

{$IFDEF ANDROID}
// TFont запоминает службу при первом обращении к размеру по умолчанию, поэтому
// подмена - в initialization, до создания форм (Application.CreateForm)

type
  TAppFontService = class(TInterfacedObject, IFMXSystemFontService)
  private
   FOld: IFMXSystemFontService;
  public
   constructor Create(const AOld: IFMXSystemFontService);
   function GetDefaultFontFamilyName: string;
   function GetDefaultFontSize: Single;
  end;

constructor TAppFontService.Create(const AOld: IFMXSystemFontService);
begin
 inherited Create;
 FOld := AOld;
end;

// семейство - системное (Roboto)
function TAppFontService.GetDefaultFontFamilyName: string;
begin
 if FOld <> nil then Result := FOld.GetDefaultFontFamilyName else Result := 'Roboto';
end;

function TAppFontService.GetDefaultFontSize: Single;
begin
 Result := Font_Size_For_Android_Const;
end;

procedure InstallAppFontService;
var Old: IFMXSystemFontService;
begin
 Old := nil;
 if TPlatformServices.Current.SupportsPlatformService(IFMXSystemFontService, Old) then TPlatformServices.Current.RemovePlatformService(IFMXSystemFontService);
 TPlatformServices.Current.AddPlatformService(IFMXSystemFontService, TAppFontService.Create(Old));
end;

initialization
 InstallAppFontService;
{$ENDIF}
end.
