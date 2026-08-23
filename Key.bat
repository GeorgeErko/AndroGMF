mkdir "C:\D\!!!DZ\Delphi-Andro\Keystore"
"C:\Program Files\Java\jdk1.8.0_60\bin\keytool.exe" ^
  -genkey -v ^
  -keystore "C:\D\!!!DZ\Delphi-Andro\Keystore\geomaster-release.keystore" ^
  -alias geomaster_alias ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000