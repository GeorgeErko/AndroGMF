unit Writer;

interface uses Classes, SysUtils, FMX.Dialogs;

var GLines:TStrings = nil;
    GFileS:String = '';

Function  AsParam(Const V:TVarRec;C:Integer=3):AnsiString;
Function  Fmt(Params:Array of Const;C:Integer=3):AnsiString;
Procedure WriteS(Params:Array of Const;C:Integer=3);
Procedure WriteIn(Params:Array of Const;C:Integer=3);
Procedure WriteOn(Lines:TStrings;Params:Array of Const;C:Integer=3);
Procedure Write_(Params:Array of Const;C:Integer=3);
Procedure WriteMsg(Params:Array of Const;C:Integer=3);
Procedure Delay(Sleep: Integer = 1000);

implementation Uses FMX.Types, System.Threading;

Function AsParam(Const V:TVarRec;C:Integer=3):AnsiString;
var S:AnsiString;
begin
 with V do
  case VType of
   vtWideChar:Result:=V.VWideChar;
   vtUnicodeString:Result:=WideCharToString(V.VUnicodeString);
   vtInt64:begin
               Str(V.VInt64^:-1,S);
               Result:=S;
             end;
   vtInteger:begin
               Str(V.VInteger:-1,S);
               Result:=S;
             end;
   vtBoolean:if V.VBoolean then AsParam:='True' else AsParam:='False' ;
   vtExtended:begin
               Str(V.VExtended^:-1:C,S);
               AsParam:=S;
              end;
   vtString:AsParam:=V.VString^;
   vtAnsiString:begin
                 S:=AnsiString(V.VAnsiString);
                 AsPAram:=S;
                end;
   vtChar:begin
           S:=V.VChar;
           AsPAram:=S;
          end;
   vtPChar:AsPAram:=V.VPChar;
   vtPointer:AsParam:=IntToStr(Integer(V.VPointer));
  end;
end;

Function Fmt(Params:Array of Const;C:Integer=3):AnsiString;
var S1,S2,Fmt1:AnsiString;I:Integer;J:TVarRec;V:Variant;
Function AsParam(Const V:TVarRec):AnsiString;
var S:AnsiString;
begin
 with V do
  case VType of
   vtWideChar:Result:=V.VWideChar;
   vtUnicodeString:Result:=WideCharToString(V.VUnicodeString);
//   vtPWideChar:Result:=V.VWideChar;
   vtInt64:begin
            Str(V.VInt64^:-1,S);
            Result:=S;
           end;
   vtInteger:begin
               Str(V.VInteger:-1,S);
               Result:=S;
             end;
   vtBoolean:if V.VBoolean then AsParam:='True' else AsParam:='False' ;
   vtExtended:begin
               Str(V.VExtended^:-1:C,S);
               AsParam:=S;
              end;
   vtString:AsParam:=V.VString^;
   vtAnsiString:begin
                 S:=AnsiString(V.VAnsiString);
                 AsPAram:=S;
                end;
   vtChar:begin
           S:=V.VChar;
           AsPAram:=S;
          end;
   vtPChar:AsPAram:=V.VPChar;
   vtPointer:AsParam:=IntToStr(Integer(V.VPointer));
  end;
end;
begin
 Fmt1:='';
 For I:=Low(Params) to High(Params) do
  begin
    S1:=AsParam(Params[I]);
    Fmt1:=Fmt1+S1+' ';
  end;
 Result:=Fmt1;
end;

Procedure WriteS(Params:Array of Const;C:Integer=3);
begin
 if Glines<>nil then begin
 // GLines.Add(Fmt(Params,C));
 // If GFileS <> '' then GLines.SaveToFile(GFileS);
 end;
// If Assigned(OnUpdateWriter) then OnUpdateWriter(Fmt);
end;

procedure WriteOn(Lines:TStrings;Params:Array of Const;C:Integer=3);
begin
 if Lines<>nil then Lines.Add(Fmt(Params,C)) else
 if GLines<>nil then GLines.Add(Fmt(Params,C));
// If Assigned(OnUpdateWriter) then OnUpdateWriter(Fmt);
end;

procedure Write_(Params: array of const; C: Integer);
begin
 if GLines<>nil then
 if GlInes.Count = 0 then GLines.Add(Fmt(Params,C)) else GLines[GLines.Count-1]:=GLines[GLines.Count-1]+(Fmt(Params,C));
end;

procedure WriteMsg(Params: array of const; C: Integer);
begin
 ShowMessage(Fmt(Params,C));
end;

procedure WriteLog(const Message: string);
begin
 Log.d(Message);
end;

Procedure WriteIn(Params:Array of Const;C:Integer=3);
begin
 if GLines<>nil then begin
  GLines.BeginUpdate;
  GLines.Add(Fmt(Params,C));
  GLines.EndUpdate;
 end;
// WriteLog(Fmt(Params,C));
end;

Procedure Delay(Sleep: Integer = 1000);
begin
 TThread.Sleep(Sleep);
end;

end.
