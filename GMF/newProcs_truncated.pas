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

     etcIniName:String = 'etc'+SLash+'Registry.ini';



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

implementation uses {$IFDEF WIN64}Windows{$ELSE}IniFiles{$ENDIF}, Registry, MemStream,

                    Math;



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

