unit newProcs;

interface uses SysUtils, Classes, Collect, newSelector, System.UITypes, FMX.Forms, FMX.Graphics;

 const
 {$IFDEF WIN64}
  Slash = '\';
 {$ELSE}
  Slash = '/';
 {$ENDIF}
 var MainPath:AnsiString;
     ApplicationMainForm:TForm;
     etcIniName:String = {$IFDEF UNIX}'etc'+ {$ENDIF}SLash+'Registry.ini';

// Конвертация
 Function GStrToFloat(S: AnsiString):Double;
 Function RoundDblToDbl(Value: Double; Digits: Integer): Double;
// Работа со строками
 Function MakeString(S:AnsiString;Mask:AnsiChar):AnsiString;
 Function MakeString2(S:AnsiString;Mask:AnsiString):AnsiString;
 Function ConcatString(S,S1,S2:AnsiString;var Res:AnsiString):AnsiString;
 Function MakeStringOne(S:AnsiString;Mask:AnsiString):AnsiString;
 Function ValidString(S:AnsiString;Values:AnsiString):boolean;
 Function Upper(S:AnsiString):AnsiString;
 Function DelSubStr(var S:AnsiString;Sub:AnsiString):AnsiString;
 Function DelSubStr2(S:AnsiString;Sub:AnsiString):AnsiString;
 Function DelSubStr3(S:AnsiString;Sub:AnsiString):AnsiString;
// Окна сообщений
 Function MessageConfirm(S:AnsiString):Word;
 Function MessageInform(S:AnsiString):Word;
 Function MessageError(S:AnsiString):Word;
 Function MessageErrorYN(S:AnsiString):Word;
// Чтение-запись реестра
 Function  GWriteString(Name:AnsiString;S:AnsiString):boolean;
 Function  GWriteInteger(Name:AnsiString;S:Integer):boolean;
 Function  GWriteFloat(Name:AnsiString;S:Double):boolean;
 Function  GWriteBinary(Name:AnsiString;var S;BufSize:Integer):boolean;
 Function  GWriteObject(Name:AnsiString;obj:TTwgObject):boolean;
 Function  GWriteVCLProp(Name:AnsiString;obj:TComponent):boolean;
 //
 Function  GReadString(Name:AnsiString;Def:AnsiString):AnsiString;
 Function  GReadInteger(Name:AnsiString;Def:Integer):Integer;
 Function  GReadFloat(Name:AnsiString;Def:Double):Double;
 Function  GReadBinary(Name:AnsiString;var S;BufSize:Integer):boolean;
 Function  GReadObject(Name:AnsiString):TTwgObject;
 Function  GReadVCLProp(Name:AnsiString;obj:TComponent):boolean;
// Цвет
 Function RGBToCol(R,G,B:Byte):TColor;
 Function GetR(Color:TColor):Byte;
 Function GetG(Color:TColor):Byte;
 Function GetB(Color:TColor):Byte;
 Function wbRGB(View:TSelector;var R,G,B:Byte):Integer; // черно-белый цвет
 Function wbColor(View:TSelector;Color:Integer):Integer; // черно-белый цвет
 Function winColor(View:TSelector;Color:Integer):Integer; // цвет относительно цвета окна
 Function fillColor(View:TSelector;Color:Integer):Integer; // цвет заливки контура
 Function notColor(Color:Integer):Integer; // цвет заливки контура
// Файлы
 Function GExtractFilePath(FN:AnsiString):AnsiString;
 Function SetSlashCorrect(FN:AnsiString):AnsiString;
// Консоль

implementation uses IniFiles, Math, FMX.DialogService, System.Types,
                    System.UIConsts;

// Конвертация

function GStrToFloat(S: AnsiString): Double;
 var D:Double;I:Integer;C:Char;
 begin
  if (formatSETTINGS.DateSeparator=',')and(Pos('.',S)<>0) then begin
   S[Pos('.',S)]:=',';
   Result:=StrToFloat(S);
  end else
  if (formatSETTINGS.DateSeparator='.')and(Pos(',',S)<>0) then begin
   S[Pos(',',S)]:='.';
   Result:=StrToFloat(S);
  end else
   Result:=StrToFloat(S);
 end;

  function RoundDblToDbl(Value: Double; Digits: Integer): Double;
 begin
  Result:=(SimpleRoundTo(Value*(exp(Digits*ln(10))), 0))/(exp(Digits*ln(10)));
 end;
// Работа со строками

  function DelSubStr(var S: AnsiString; Sub: AnsiString): AnsiString;
  begin
   While(Pos(Sub,S)<>0) do
    begin
     Delete(S,Pos(Sub,S),Length(Sub));
    end;
    DelSubStr:=S;
  end;

  function DelSubStr2(S: AnsiString; Sub: AnsiString): AnsiString;
  begin
   While(Pos(Sub,S)<>0) do
    begin
     Delete(S,Pos(Sub,S),Length(Sub));
    end;
    DelSubStr2:=S;
  end;

  function DelSubStr3(S: AnsiString; Sub: AnsiString): AnsiString;
  var I:Integer;
  begin
   Result:='';
   For I:=1 to Length(S) do
    If S[I]<>Sub then Result:=Result+S[I];
  end;

  function MakeString(S: AnsiString; Mask: AnsiChar): AnsiString;
 var I:Integer;
  begin
   Result:='';
   For I:=1 to Length(S) do If S[1]=Mask then
    Result:=Result+#13#10 else Result:=Result+S[I];
  end;

  function ConcatString(S, S1, S2: AnsiString; var Res: AnsiString): AnsiString;
 var P1,P2,I:Integer;
 begin
  Res:='';Result:=S;
  While True do begin
   P1:=Pos(S1,S);P2:=Pos(S2,S);
   If (P1=0) or (P2=0) then exit;
   If P2<=P1 then exit;
   Res:='';
   For I:=P1+1 to P2 do begin Res:=Res+S[I];S[I]:='#';end;
   DelSubStr(S,'#');
   Result:=S;
  end;
 end;

  function MakeString2(S: AnsiString; Mask: AnsiString): AnsiString;
  var I,Index:Integer;St:TStrings;S2:AnsiString;Found:boolean;
 begin
  St:=TStringList.Create;
   S2:='';
   While Pos(Mask,S)<>0 do begin
    Index:=Pos(Mask,S);
    For I:=1 to Index-1 do S2:=S2+S[I];
    St.Add(S2);
    Delete(S,1,Index+Length(Mask)-1);
    S2:='';
   end;
  If St.Text = '' then Result:=S else begin
   St.Add(S);
    Result:=St.Text;
  end;
  St.Free;
 end;

  function MakeStringOne(S: AnsiString; Mask: AnsiString): AnsiString;
 var I,J:Integer;One:byte;
  begin
   Result:='';One:=0;
   For I:=1 to Length(S) do If S[I]=Mask then begin
                            Result:=Result+#13#10;Inc(One);
                           end else begin
                            Result:=Result+S[I];
                            If One>0 then begin
                             For J:=I+1 to Length(S) do Result:=Result+S[J];
                             exit;
                            end;
                           end;
  end;

  function ValidString(S: AnsiString; Values: AnsiString): boolean;
 var St:TStrings;I:Integer;
 begin
  St:=TStringList.Create;
  St.Text:=MakeString(Values,',');
  For I:=0 to ST.Count-1 do If AnsiUpperCase(S) = AnsiUpperCase(ST[I]) then begin
   Result:=True;
   St.Free;
   exit;
  end;
  St.Free;
  Result:=False;
 end;

 function Upper(S:AnsiString):AnsiString;
 var I:Integer;S1:AnsiString;
 begin
  S:=AnsiLowerCase(S);
  For I:=1 to Length(S) do If S[I] in ['?'..'?'] then begin
   S1:=S[I];
   S1:=AnsiUpperCase(S1);
   S[I]:=S1[1];break;
  end;
  Result:=S;
 end;

// Окна сообщений

  function MessageConfirm(S: AnsiString): Word;
  var lResult: Word;
  begin
   TDialogService.PreferredMode:=TDialogService.TPreferredMode.Platform;
   TDialogService.MessageDialog(S,TMsgDlgType.mtConfirmation,[TMsgDlgBtn.mbYes,TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes,0,
             procedure (const AResult: TModalResult)
              begin
                lResult := AResult;
              end);
   Result:= lResult;
  end;

  function MessageInform(S: AnsiString): Word;
  var lResult: Word;
  begin
   TDialogService.PreferredMode:=TDialogService.TPreferredMode.Platform;
   TDialogService.MessageDialog(S,TMsgDlgType.mtInformation,[TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk,0,
             procedure (const AResult: TModalResult)
              begin
                lResult := AResult;
              end);
   Result:= lResult;
  end;

  function MessageError(S: AnsiString): Word;
   var lResult: Word;
  begin
   TDialogService.PreferredMode:=TDialogService.TPreferredMode.Platform;
   TDialogService.MessageDialog(S,TMsgDlgType.mtError,[TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOk,0,
             procedure (const AResult: TModalResult)
              begin
                lResult := AResult;
              end);
   Result:= lResult;
  end;

  function MessageErrorYN(S: AnsiString): Word;
   var lResult: Word;
  begin
   TDialogService.PreferredMode:=TDialogService.TPreferredMode.Platform;
   TDialogService.MessageDialog(S,TMsgDlgType.mtError,[TMsgDlgBtn.mbYes,TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes,0,
             procedure (const AResult: TModalResult)
              begin
                lResult := AResult;
              end);
   Result:= lResult;
  end;


function GWriteString(Name: AnsiString; S: AnsiString): boolean;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Ini.WriteString('Registry',Name,S);
 Ini.Free;
end;

function GWriteInteger(Name: AnsiString; S: Integer): boolean;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Ini.Writeinteger('Registry',Name,S);
 Ini.Free;
end;

function GWriteFloat(Name: AnsiString; S: Double): boolean;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Ini.WriteFloat('Registry',Name,S);
 Ini.Free;
end;

function GWriteBinary(Name: AnsiString; var S; BufSize: Integer): boolean;
var Ini:TIniFile;St:TBufStream;
begin
 St:= TBufStream.Create;
 St.Write(S,BufSize);
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Ini.WriteBinaryStream('Binary',Name,St.Stream);
 Ini.Free;
 St.Free;
end;

function GWriteObject(Name: AnsiString; obj: TTwgObject): boolean;
var Ini:TIniFile;Buf:TBufStream;
begin
 Buf:=TBufStream.Create;Buf.Put(obj);
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Ini.WriteBinaryStream('Binary',Name,Buf.Stream);
 Ini.Free;
 Buf.Free;
end;

function GWriteVCLProp(Name: AnsiString; obj: TComponent): boolean;
begin
 //
end;

function GReadString(Name: AnsiString; Def: AnsiString): AnsiString;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Result:=Ini.ReadString('Registry',Name,Def);
 Ini.Free;
end;

function GReadInteger(Name: AnsiString; Def: Integer): Integer;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Result:=Ini.ReadInteger('Registry',Name,Def);
 Ini.Free;
end;

function GReadFloat(Name: AnsiString; Def: Double): Double;
var Ini:TIniFile;
begin
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Result:=Ini.ReadFloat('Registry',Name,Def);
 Ini.Free;
end;

function GReadBinary(Name: AnsiString; var S; BufSize: Integer): boolean;
var Ini:TIniFile;St:TStream;
begin
 St:=TMemoryStream.Create;
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  Result:=Ini.ReadBinaryStream('Registry',Name,St) = BufSize;
  St.Position:=0;St.Write(S,BufSize);
 Ini.Free;
 St.Free;
end;

function GReadObject(Name: AnsiString): TTwgObject;
var Ini:TIniFile;Buf:TBufStream;
begin
 Buf:=TBufStream.Create;
 Ini:=TIniFile.Create(MainPath+Slash+etcIniName);
  If Ini.ReadBinaryStream('Binary',Name,Buf.Stream)>0 then Result:=Buf.Get else Result:=nil;
 Ini.Free;
 Buf.Free;
end;

function GReadVCLProp(Name: AnsiString; obj: TComponent): boolean;
begin
 //
end;


function RGBToCol(R, G, B: Byte): TColor;
begin
 {$IFDEF WIN64} Result:=RGB(R,G,B);{$ELSE} Result := MakeColor(R, G, B);{$ENDIF}
end;

function GetR(Color: TColor): Byte;
begin
{$IFDEF WIN64} Result:=GetRValue(Color);{$ELSE} Result:=TAlphaColorRec(Color).R;{$ENDIF}
end;

function GetG(Color: TColor): Byte;
begin
{$IFDEF WIN64} Result:=GetGValue(Color);{$ELSE} Result:=TAlphaColorRec(Color).G;{$ENDIF}
end;

function GetB(Color: TColor): Byte;
begin
{$IFDEF WIN64} Result:=GetBValue(Color);{$ELSE} Result:=TAlphaColorRec(Color).B;{$ENDIF}
end;

function wbRGB(View: TSelector; var R, G, B: Byte): Integer; // черно-белый цвет
begin
 Result:=RGBToCol(R,G,B);
 {$IFNDEF GEOBASEGRAPH}
 If View.GlobalSettings = nil then exit;
 If (Result = View.GlobalSettings.Settings.gsWindowColor) and ((Result = TAlphaColors.Black) or (Result = TAlphaColors.White)) then begin
  R:=not(R);G:=not(G);B:=not(B);
  Result:=RGBToCol(R,G,B);
 end;
 {$ENDIF}
end;

function wbColor(View: TSelector; Color: Integer): Integer; // черно-белый цвет
var R,G,B:Byte;
begin
 Result:=Color;
 {$IFNDEF GEOBASEGRAPH}
 If View.GlobalSettings = nil then exit;
 R:=GetR(Color);G:=GetG(Color);B:=GetB(Color);
 If (Color = View.GlobalSettings.Settings.gsWindowColor) and ((Color = TAlphaColors.Black) or (Color = TAlphaColors.White)) then begin
  Result:=wbRGB(View,R,G,B);
 end;
 {$ENDIF}
end;

function winColor(View: TSelector; Color: Integer): Integer;
var R,G,B:Byte;
begin
 Result:=Color;
 {$IFNDEF GEOBASEGRAPH}
 If (View.GlobalSettings.Settings.gsWindowColor = TAlphaColors.Black) then begin
  R:=GetR(Color);G:=GetG(Color);B:=GetB(Color);
  R:=not(R);G:=not(G);B:=not(B);
  Result:=RGBToCol(R,G,B);
 end;
 {$ENDIF}
end;

function notColor(Color: Integer): Integer;
var R,G,B:Byte;
begin
 Result:=Color;
 R:=GetR(Color);G:=GetG(Color);B:=GetB(Color);
 R:=not(R);G:=not(G);B:=not(B);
 Result:=RGBToCol(R,G,B);
end;

function fillColor(View: TSelector; Color: Integer): Integer;
var R,G,B:Byte;
begin
 If View.GGraphSet.bmGlass then begin
  Result:=winColor(View,Color);
 {$IFNDEF GEOBASEGRAPH}
  If (View.GlobalSettings.Settings.gsWindowColor = TAlphaColors.Black) then begin
   If Color<>TAlphaColors.Black then begin
    R:=GetR(Color);G:=GetG(Color);B:=GetB(Color);
    R:=not(R);G:=not(G);B:=not(B);
    Result:=RGBToCol(R,G,B);
   end else begin
    Result:=Color;
   end;
  end;
  {$ENDIF}
 end else begin
  Result:=Color;
 {$IFNDEF GEOBASEGRAPH}
  If (View.GlobalSettings.Settings.gsWindowColor = TAlphaColors.Black)and(Result = TAlphaColors.Black) then begin
   R:=GetR(Color);G:=GetG(Color);B:=GetB(Color);
   R:=not(R);G:=not(G);B:=not(B);
   Result:=RGBToCol(R,G,B);
  end else
  If (View.GlobalSettings.Settings.gsWindowColor = TAlphaColors.Black)and(Result <> TAlphaColors.Black) then begin
   Result:=Result;
  end;
 {$ENDIF}
 end;
end;

  function GExtractFilePath(FN: AnsiString): AnsiString;
  begin
   Result:=ExtractFilePath(FN);
   If Result='' then Exit;
   If Result[Length(Result)]=Slash then SetLength(Result,Length(Result)-1);
  end;

  function SetSlashCorrect(FN: AnsiString): AnsiString;
  var I:Integer;
  begin
   For I:=1 to Length(FN) do
    {$IFDEF UNIX} If FN[I] = '\' then FN[I]:='/';{$ELSE}  If FN[I] = '/' then FN[I]:='\';{$ENDIF}
   Result:=FN;
  end;

initialization
end.

