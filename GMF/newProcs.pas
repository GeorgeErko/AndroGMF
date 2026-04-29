unit newProcs;

interface uses SysUtils, Classes, Collect, newSelector, System.UITypes, FMX.Forms, FMX.Graphics;

 const
 {$IFDEF WIN64}
  Slash = '\';
 {$ELSE}
  Slash = '/';
 {$ENDIF}
  byLayer = 'По слою';
  byNone = 'None';

//
 var MainPath:AnsiString;
     ApplicationMainForm:TForm;
     GlobalRender: Boolean = False;
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
 Procedure ShowMessage(S:AnsiString);
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
 Function RGBToCol(R,G,B:Byte):TColorRef;
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
 Function SetExtFile(S,newExt:string):String;
// Консоль

implementation uses IniFiles, Math, System.Types,
                    FMX.DialogService,
                    FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Controls.Presentation,
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

  function _MessageDialogSync(const Msg: string; const DlgType: TMsgDlgType;
    const Buttons: array of TMsgDlgBtn; const DefaultButton: TMsgDlgBtn): TModalResult;
  var
    F: TForm;
    L: TLabel;
    Btn: TButton;
    BtnW: Single;
    BtnH: Single;
    I: Integer;
    X0: Single;
    Modal: TModalResult;
    TitleText: string;
    BtnText: string;
    BtnResult: TModalResult;
    BtnDefault: Boolean;
  begin
    F := TForm.CreateNew(nil);
    try
      F.Position := TFormPosition.ScreenCenter;
      F.BorderStyle := TFmxFormBorderStyle.Sizeable;
      F.Width := 420;
      F.Height := 180;

      TitleText := '';
      case DlgType of
        TMsgDlgType.mtWarning: TitleText := 'Warning';
        TMsgDlgType.mtError: TitleText := 'Error';
        TMsgDlgType.mtInformation: TitleText := 'Info';
        TMsgDlgType.mtConfirmation: TitleText := 'Confirm';
      end;
      F.Caption := TitleText;

      L := TLabel.Create(F);
      L.Parent := F;
      L.Position.X := 16;
      L.Position.Y := 16;
      L.Width := F.ClientWidth - 32;
      L.Height := F.ClientHeight - 80;
      L.WordWrap := True;
      L.Text := Msg;

      BtnW := 96;
      BtnH := 36;
      if Length(Buttons) > 0 then
        X0 := (F.ClientWidth - (Length(Buttons) * BtnW + (Length(Buttons) - 1) * 12)) / 2
      else
        X0 := (F.ClientWidth - BtnW) / 2;

      for I := 0 to High(Buttons) do
      begin
        case Buttons[I] of
          TMsgDlgBtn.mbOK: begin BtnText := 'OK'; BtnResult := mrOk; end;
          TMsgDlgBtn.mbCancel: begin BtnText := 'Cancel'; BtnResult := mrCancel; end;
          TMsgDlgBtn.mbYes: begin BtnText := 'Yes'; BtnResult := mrYes; end;
          TMsgDlgBtn.mbNo: begin BtnText := 'No'; BtnResult := mrNo; end;
          else begin BtnText := 'OK'; BtnResult := mrOk; end;
        end;

        BtnDefault := Buttons[I] = DefaultButton;
        Btn := TButton.Create(F);
        Btn.Parent := F;
        Btn.Text := BtnText;
        Btn.Width := BtnW;
        Btn.Height := BtnH;
        Btn.Position.X := X0 + I * (BtnW + 12);
        Btn.Position.Y := F.ClientHeight - BtnH - 16;
        Btn.ModalResult := BtnResult;
        Btn.Default := BtnDefault;
      end;

      Modal := F.ShowModal;
      Result := Modal;
    finally
      F.Free;
    end;
  end;

  function MessageConfirm(S: AnsiString): Word;
  begin
{$IFDEF ANDROID}
    TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
    TDialogService.MessageDialog(string(S), TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0, nil);
    Result := mrNo;
{$ELSE}
    Result := _MessageDialogSync(string(S), TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes);
{$ENDIF}
  end;

  function MessageInform(S: AnsiString): Word;
  begin
{$IFDEF ANDROID}
    TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
    TDialogService.MessageDialog(string(S), TMsgDlgType.mtInformation,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Result := mrOk;
{$ELSE}
    Result := _MessageDialogSync(string(S), TMsgDlgType.mtInformation,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK);
{$ENDIF}
  end;

  function MessageError(S: AnsiString): Word;
  begin
{$IFDEF ANDROID}
    TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
    TDialogService.MessageDialog(string(S), TMsgDlgType.mtError,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    Result := mrOk;
{$ELSE}
    Result := _MessageDialogSync(string(S), TMsgDlgType.mtError,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK);
{$ENDIF}
  end;

  function MessageErrorYN(S: AnsiString): Word;
  begin
{$IFDEF ANDROID}
    TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
    TDialogService.MessageDialog(string(S), TMsgDlgType.mtError,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0, nil);
    Result := mrNo;
{$ELSE}
    Result := _MessageDialogSync(string(S), TMsgDlgType.mtError,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes);
{$ENDIF}
  end;

  procedure ShowMessage(S: AnsiString);
  begin
{$IFDEF ANDROID}
    TDialogService.PreferredMode := TDialogService.TPreferredMode.Platform;
    TDialogService.MessageDialog(string(S), TMsgDlgType.mtInformation,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
{$ELSE}
    _MessageDialogSync(string(S), TMsgDlgType.mtInformation,
      [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK);
{$ENDIF}
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


function RGBToCol(R, G, B: Byte): TColorRef;
begin
Result := MakeColor(R, G, B);
end;

function GetR(Color: TColor): Byte;
begin
 Result:=TAlphaColorRec(Color).R;
end;

function GetG(Color: TColor): Byte;
begin
 Result:=TAlphaColorRec(Color).G;
end;

function GetB(Color: TColor): Byte;
begin
 Result:=TAlphaColorRec(Color).B;
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

  Function SetExtFile;
   var S1:String;
  begin
   Result:=S;
   If Length(S)<=4 then Exit;
   If Length(ExtractFileExt(S1))>2 then Exit;
   If NewExt='' then begin
    S1:=S;
    Delete(S1,Length(S1)-Length(ExtractFileExt(S1))+1,Length(S1));
    Result:=S1;
    exit;
   end;
   S1:=S;
    Delete(S1,Length(S1)-Length(ExtractFileExt(S1))+1,Length(S1));
    S1:=S1+NewExt;
    SetExtFile:=S1;
  end;
initialization
end.


