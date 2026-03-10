unit CreateTwg;
interface
 uses  Collect,Windows,WptForm2,WpTwigs,EcDot,SysUtils, newForm0,Classes;

const NumOf:Integer = 2;

Function CreateNewTwg(Dir,FileName:String;tempForm:TForm2):Boolean;
Function OpenTwg(Dir,FileName:String):TForm2;
Function CreateEmptyTWG:TForm2;
Function AutoSave(TwgForm:TForm2):boolean;
Function SaveTWG(TwgForm:TForm2):boolean;

implementation uses Dialogs, newProcs, newLayersTable, WptForm0;

Function CreateNewTwg(Dir,FileName:String;tempForm:TForm2):Boolean;
 var F:Boolean;Form:TForm2;
     Twig:TTwig;Buf:TBufStream;
     P:Array[0..255] of Char;
begin
Result:=False;
 GetTempPath(255,P);
 Buf:=TBufStream.InitFileStream(P+tempForm.About.MyName,fmCreate);
 try
  try
   Buf.Put(tempForm);
  except exit;end;
 finally Buf.Free;end;
 Buf:=TBufStream.InitFileStream(P+tempForm.About.MyName,fmOpenRead);
 try
  try
   Form:=TForm2(Buf.Get);
   Form.ClearObject;
  except exit;end;
 finally Buf.Free;end;
 ForceDirectories(Dir);
 Buf:=TBufStream.InitFileStream(Dir+'\'+FileName,fmCreate);
 try
  try
   Buf.Put(Form);
   Form.Free;
  except MessageError('Не удалось создать файл "'+FileName+'" в каталоге "'+Dir+'".');exit;end;
 finally Buf.Free; end;
 Result:=True;
end;

Function OpenTwg;
 label 1;
 var Form:TForm2;
     Buf:TBufStream;
     P,P1:Array[0..255] of char;
     Tw,Twig:TTwig;D1,D2:TDot;I:Integer;
 begin
  Result:=nil;                                
    Try
      Buf:=TBufStream.InitFileStream(Dir+'\'+FileName,fmOpenRead);
    except on E:Exception do
    begin
      MessageDlg('Объект загрузить невозможно '+E.Message,mtError,[mbOk],0);
      exit;
    end;
    end;
    try
//     Buf.List:=Tlist.Create;
      Form:=TForm2(Buf.Get);
    Except on E:Exception do             
     begin
       if Buf.Status=100 then
          MessageDlg('Объект загрузить невозможно.Неверный формат файла',mtError,[mbOk],0) else
       if Buf.Status=200 then
          MessageDlg('Объект загрузить невозможно.Ошибка при классификации данных.'+E.Message,mtError,[mbOk],0) else
          MessageDlg('Объект загрузить невозможно.Неизвестная ошибка :'+E.Message,mtError,[mbOk],0);
          Form:=nil;
          Buf.Free;
          exit;
     end;
    end; {Exception}
    Buf.Free;
    Form.About.Path:=Dir;
    Form.About.MyName:=FileName;
    Result:=Form;
    Form.SetGabarites;
    StrPCopy(P,(Form.About.Path)+'\'+(Form.About.MyName));
    StrCopy(P1,P);
    P1[StrLen(P)-1]:='2';
    CopyFile(P,P1,False);
 end;

Function CreateEmptyTWG:TForm2;
 var Twig:TTwig;Ab:EcAboutObjectOld;
begin
  Result:=TForm2.Create(0);
  Twig:=TTwig.Create(Twig_Any);
// With GPlanUstn do
  Twig.Coord.Insert(TDot.Create(0,-0,0));
  Twig.Coord.Insert(TDot.Create(-10,-10,0));
  Result.Twigs.Insert(Twg_Twig,Twig);
  FillChar(Ab,SizeOf(Ab),#0);
  CopyFromIn(Ab,Result.About);
  Result.MkLib:=TMosLib.CreateEmpty;
  Result.LayerTable:=TLayerTable.Create(Result.MkLib);
  Result.LayerTable.CreateLayersView(nil);
end;

Function AutoSave(TwgForm:TForm2):boolean;
var Dir:String;Buf:TBufStream;
begin
{$IFDEF DEMOPLAN}
 Result:=False;
 exit;
{$ENDIF}
{$IFDEF AUTOSAVE}
 Result:=True;
// If Pos('TWG',UpperCase(TwgForm.About.MyName))<>0  then exit;
 If not TwgForm.Modified2 then exit;
 If TwgForm.About.MyName='' then exit;
// Dir:=SetExtFile(TwgForm.About.Path+'\'+TwgForm.About.MyName,'');
 Dir:=TwgForm.About.Path;
// ForceDirectories(Dir);
// While FileExists(Dir+'\'+SetExtFile(TwgForm.About.MyName,'')+'_'+IntToStr(NumOf)+'.gmf') do Inc(NumOf);
// If NumOf>2 then NumOf:=1;
 Writeln('AutoSave=',Dir+'\'+SetExtFile(TwgForm.About.MyName,'')+'_'+IntToStr(NumOf)+'.gmf');
// Writeln('NumOf=',NumOf);
 Buf:=TBufStream.InitFileStream(TwgForm.About.Path+'\'+SetExtFile(TwgForm.About.MyName,'')+'.gm'+IntToStr(NumOf),fmCreate);
 try
   Buf.Put(TwgForm);
 except Result:=False;end;
 If Result then begin
  TwgForm.Modified2:=False;
  If NumOf = 2 then NumOf:=3 else NumOf:=2;
 end;
 Buf.Free;
{ If Result then begin
  Buf:=TBufStream.InitFileStream(TwgForm.About.Path+'\'+TwgForm.About.MyName,fmCreate);
  Result:=True;
  try
   Buf.Put(TwgForm);
   Writeln('AutoSave = ',TimeToStr(Now));
  except Result:=False;end;
  Buf.Free;
 end;}
 {$ENDIF}
end;

Function SaveTWG(TwgForm:TForm2):boolean;
var Dir:String;Buf:TBufStream;
begin
 Result:=True;
 If not TwgForm.Modified then exit;
 If TwgForm.About.MyName='' then exit;
 Dir:=TwgForm.About.Path;
 Buf:=TBufStream.InitFileStream(TwgForm.About.Path+'\'+TwgForm.About.MyName,fmCreate);
 try
   Buf.Put(TwgForm);
 except Result:=False;end;
 Buf.Free;
end;

end.

