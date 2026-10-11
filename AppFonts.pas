unit AppFonts;

// размер шрифта по умолчанию на Android (FMX: Android 14, Windows 12):
// служба IFMXSystemFontService подменяется своей, чтобы TLabel, TCheckBox,
// TButton и др. (Size в StyledSettings) имели тот же размер, что и в Windows.
// Модуль должен стоять в uses .dpr до модулей с формами

interface

const
 Font_Size_For_Android_Const = 12;

implementation

{$IFDEF ANDROID}
uses FMX.Platform, FMX.Graphics;

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
