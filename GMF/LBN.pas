unit LBN;

interface uses Classes, SysUtils, Collect, newProcs, WPTForm2;

type
 TNode = class(TTwgObject)
  Name: AnsiString;
  Childs:PCollection;
  Constructor Create(Name_: AnsiString);
  Function AddItem(S: AnsiString):TNode;
  Function Item(Index:Integer):TNode;
  Procedure SaveToFile(var F:Text);
//  Procedure ExportByTreeView(Items:TTreeNodes;Node:TTreeNode);
  Destructor Destroy;override;
  Function FindItem(Name: AnsiString):TNode;
 end;

 TTree = class(TTwgObject)
  Name:AnsiString;
  Levels:TStrings;
  Items:PCollection;
  Error: AnsiString;
  Constructor Create(Name_: AnsiString);
  Function AddItem(S: AnsiString):TNode;
  Function AddChildItem(Node:TNode;S: AnsiString):TNode;
  Procedure SaveToFile(FName: AnsiString);
//  Procedure ExportByTreeView(TreeView:TTreeView);
  Destructor Destroy;override;
  Function FindItem(Name: AnsiString):TNode;
  Function FindByTree(nodeValue: AnsiString;var SectionName: AnsiString):boolean;
 end;

type
 TSectionName = class(TCStrings)
  Name: AnsiString;
  Tree:TTree;
  Constructor Create(Name_: AnsiString);
  Destructor Destroy;override;
  Function Find(Str: AnsiString;UpperCase:Boolean):Integer;
  Function IndexName(Index:Integer): AnsiString;
  Function FindParam(Param: AnsiString; Index: Integer = 0): AnsiString;
  Function GetValueForIndex(Index, IndexFromValue: Integer): AnsiString;
  Function GetValueForName(Name_: AnsiString; IndexFromValue: Integer): AnsiString;
 end;

 TListByName = class(TTwgObject)
  Sections:PCollection;
  Additional:TListByName;
  Constructor Create(Num:Integer=0);
   Procedure LoadFromFile(FileName: AnsiString; objType: AnsiString);
   Procedure SaveToFile(FileName: AnsiString);
   Procedure AddField(Section,Value: AnsiString);
   Function FindByName(SectionName: AnsiString):TSectionName;
   Function FindByNameUpper(SectionName: AnsiString):TSectionName;
   Function FindByName2(SectionName: AnsiString;Index:Integer = 0):TSectionName;
   Function FindSubString(SectionName, ItemName: AnsiString;St:TStrings;var Error: AnsiString):boolean;
   Function FindSubStringForAll(SectionName, ItemName: AnsiString): AnsiString;
   Function FindSubStringForAll2(SectionName, ItemName: AnsiString): AnsiString;
  //
   Function FindEngSubString(SectionName,ItemName: AnsiString;var Value: AnsiString): AnsiString;
   Function FindRusSubString(SectionName, ItemName: AnsiString): AnsiString;
  Destructor Destroy;override;
 end;

function oghObjectType(TwgForm: TForm2): String;
function oghObjectTypeRus(TwgForm: TForm2): String;

var ListByName:TListByName;ListByDicts:TListByName;

implementation uses Writer;

function oghObjectType(TwgForm: TForm2): String;
begin
 Result := '';
 If TwgForm.Settings.Properties.PropValue['Тип объекта'] <> nil then begin
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ОДХ' then Result := '_odh' else
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ДТ' then Result := '_dt' else
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ОО' then Result := '_oo';
 end;
end;

function oghObjectTypeRus(TwgForm: TForm2): String;
begin
 Result := '';
 If TwgForm.Settings.Properties.PropValue['Тип объекта'] <> nil then begin
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ОДХ' then Result := 'ОДХ' else
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ДТ' then Result := 'ДТ' else
  If ansiUpperCase(TwgForm.Settings.Properties.PropValue['Тип объекта'].Value) = 'ОО' then Result := 'ОО';
 end;
end;

{ TNode }

function TNode.AddItem(S: AnsiString): TNode;
begin
 Childs.Insert(TNode.Create(S));
 Result:=Childs[Childs.Count-1];
end;

constructor TNode.Create(Name_: AnsiString);
begin
 Name:=Name_;
 Childs:=PCollection.Create(1);
end;

destructor TNode.Destroy;
begin
 Childs.Free;
end;

function TNode.Item(Index: Integer): TNode;
begin
 Result:=Childs[Index];
end;

procedure TNode.SaveToFile(var F: Text);
var I:Integer;
begin
 Writeln(F,Name);
 For I:=0 to Childs.Count-1 do begin
  Writeln(F,TNode(Childs[I]).Name);
 end;
end;

function TNode.FindItem(Name: AnsiString): TNode;
var I:Integer;
begin
 For I:=0 to Childs.Count-1 do If ansiLowerCase(Item(I).Name) = ansiLowerCase(Name)  then begin
  Result:=Item(I);                               
  exit;
 end;
 Result:=nil;
end;

{ TTree }

constructor TTree.Create(Name_: AnsiString);
begin
 Name:=Name_;
 Levels:=TStringList.Create;
 Levels.Text:=MakeString(Name,'+');
 Items:=PCollection.Create(1);
 Error:='';
end;

destructor TTree.Destroy;
begin
 Levels.Free;
 Items.Free;
end;

function TTree.AddChildItem(Node: TNode; S: AnsiString): TNode;
begin                                 
 Result:=Node.AddItem(DelSubStr2(S,#9));
end;

function TTree.AddItem(S: AnsiString): TNode;
begin
 Items.Insert(TNode.Create(DelSubStr2(S,#9)));
 Result:=Items[Items.Count-1];
end;

procedure TTree.SaveToFile(FName: AnsiString);
var F:Text;I,J:Integer;
begin
AssignFile(F,'C:\D\atesttree.txt');
Rewrite(F);
 For I:=0 to Items.Count-1 do begin      
  Writeln(F,TNode(Items[I]).Name);
  For J:=0 to TNode(Items[I]).Childs.Count-1 do TNode(TNode(Items[I]).Childs[J]).SaveToFile(F);
 end;
CloseFile(F);
end;

function TTree.FindItem(Name: AnsiString): TNode;
var I:Integer;
begin
 For I:=0 to Items.Count-1 do
  If ansiLowerCase(TNode(Items[I]).Name) = ansiLowerCase(Name) then begin
   Result:=Items[I];Exit;
  end;
 Result:=nil;
end;

function TTree.FindByTree(nodeValue: AnsiString; var SectionName: AnsiString): boolean;
var St:TStrings;Node:TNode;Level:Integer;
    StErr, StCorr:TStrings;
Function GetErr(S: AnsiString): AnsiString;
var I:Integer;
begin
 Result:='';
 For I:=0 to StErr.Count-1 do
  If Result = '' then Result:=Result+StErr[I] else Result:= Result+','+StErr[I];
end;
Function FindByNode(Node:TNode;nodeValue: AnsiString): TNode;
var I,J,Count,SaveL:Integer;
    St1: TStrings;
    Res: Pointer;
begin
 If Error <> '' then exit;
// If Node.Name = 'Развилка ствола' then
//  Writeln(1);
 St1:=TStringList.Create;
 St1.Text:=MakeString2(nodeValue,',');
// Result:=Pointer(Self);
 try
  Count:=0;
 // проверяем, есть-ли среди значений St1, элемент из Node
  For I:=0 to St1.Count - 1 do If (St1[I]<>'-') and (St1[I]<>byLayer) then begin
   Res:=Node.FindItem(St1[I]);
   Count:=Count+ord(Res<>nil);
   If Res = nil then begin
    If (StErr.IndexOf(St1[I])=-1) and (StCorr.IndexOf(St1[I])=-1) then StErr.Add(St1[I]);
   end else begin
    StCorr.Add(St1[I]);
   // удаляем значение из StErr, как найденное в одной из секций
    If StErr.IndexOf(St1[I]) <> -1 then StErr.Delete(StErr.IndexOf(St1[I]));
   end;
  end;
 // если нет, то проверяем, может-ли он быть пустым
  If Count = 0 then
   If Node.FindItem('*') = nil then begin
    Result:=nil;
    Error:='Для секции "'+Node.Name+'" не найдено ни одного значения';
    exit;
   end;
  SaveL:=Level;
  For I:=0 to St1.Count - 1 do begin
   Level:=SaveL;
   If Error <> '' then exit;
   Result:=Node.FindItem(St1[I]);
   If Result<>nil then begin
    Inc(Level);
    If Level>Levels.Count-1 then continue;
    SectionName:=Levels[Level];
    Result:=FindByNode(Result,St[Level]);
    If Result = nil then continue;
   end;
   { else begin
    Error:='В секции "'+Node.Name+'" не найдено значение "'+St1[I]+'"';
    exit;
   end;}
  end;
 finally
  St1.Free;
 end;
end;
begin
 Result:=False;
 Error:='';
 If Levels.Count=0 then exit;
 StErr:=TStringList.Create;
 StCorr:=TStringList.Create;
// Write('Name =',Name,' nodeName=',nodeValue,' Levels=',Levels.Text,' Count=',Items.Count);readln;
  St:=TStringList.Create;St.Text:=MakeString(nodeValue,';');
 try
  Node:=FindItem(St[0]);              
  If Node = nil then begin
   Error:='Для секции "'+Levels[0]+'" не найдено значение:'+ St[0];
   SectionName:=Levels[0];
   exit;
  end;
 //
  Level:=1;
  SectionName:=Levels[Level];
  Node:=FindByNode(Node,St[Level]);
  If Node=nil then begin
   If Error = '' then
    If StErr.Count>0 then Error:='Ошибка (не найдены значения):'+GetErr(StErr.Text);
    Result:=Error='';
    exit;
  end;
 If StErr.Count>0 then begin
  Error:='Ошибка (не найдены значения):'#13#10+GetErr(StErr.Text);
  exit;
 end;
 //
 finally
  St.Free;
  StErr.Free;
  StCorr.Free;
 end;
 //
 Result:=True;
end;

{ TSectionName }

constructor TSectionName.Create(Name_: AnsiString);
begin
 Name:=Name_;
 inherited Create(1);
end;

destructor TSectionName.Destroy;
begin
 inherited Destroy;
end;

function TSectionName.Find(Str: AnsiString; UpperCase: Boolean): Integer;
var I:Integer;
begin
 For I:=0 to Count-1 do
  If UpperCase then begin
   If AnsiUpperCase(Strings[I])=AnsiUpperCase(Str) then begin Result:=I;exit;end;
  end else If Strings[I]=Str then begin Result:=I;exit;end;
 Result:=-1;
end;

function TSectionName.FindParam(Param: AnsiString; Index: Integer = 0): AnsiString;
var I:Integer;S: AnsiString;St:TStrings;
begin
 Result:='';//Writeln(1,' ',Param);
 St:=TStringList.Create;
 For I:=0 to Count-1 do begin
  If Trim(Strings[I]) = '' then continue;
  St.Text:=MakeString(Strings[I],'=');
  If St.Count > index then begin
   //Writeln('c1 ',St.Count);
   If AnsiUpperCase(St[0])=AnsiUpperCase(Param) then begin Result:=St[Index]; St.Free; exit;end;
  end;      
 end;
 St.Free;
// Writeln(2);
end;

function TSectionName.GetValueForIndex(Index, IndexFromValue: Integer): AnsiString;
var St: TStrings;
begin
 St:=TStringList.Create;
  St.Text:=MakeString(Strings[Index],'=');
  If IndexFromValue < St.Count then Result:=St[IndexFromValue] else Result:='';
 St.Free;
end;

function TSectionName.GetValueForName(Name_: AnsiString; IndexFromValue: Integer): AnsiString;
var Index: Integer;
begin
 Result := '';
 Index := Find(Name_, False);
 If Index = - 1 then exit;
 Result := GetValueForIndex(Index, IndexFromValue);
end;

function TSectionName.IndexName(Index: Integer): AnsiString;
var St:TStrings;
begin
 St:=TStringList.Create;
  St.Text:=MakeString(Name,'=');
  If Index<St.Count then Result:=St[Index] else Result:='';
 St.Free;
end;

{ TListByName }

procedure TListByName.AddField(Section, Value: AnsiString);
var SN:TSectionName;
begin
 SN:=FindByName2(Section,0);
 If SN=nil then MessageError('Не найдена секция: '+ Section) else begin
  If SN[SN.Count-1]='' then SN.AtInsert(SN.Count-1,TStrClass.Create(Value)) else SN.InsertStr(Value);
 end;
end;

constructor TListByName.Create;
begin
 Sections:=PCollection.Create(1);
 If Num<1 then Additional:=TListByName.Create(1);
end;

destructor TListByName.Destroy;
begin
 Sections.Free;
 If Additional <> nil then Additional.Free;
end;

function TListByName.FindByName(SectionName: AnsiString): TSectionName;
var I,Index:Integer;
begin
 Result:=nil;
 For I:=0 to Sections.Count-1 do If SectionName=TSectionName(Sections[I]).Name then begin
  Result:=Sections[I];
  exit;
 end;
// поиск секций с деревом
 For I:=0 to Sections.Count-1 do If TSectionName(Sections[I]).Tree<>nil then
  If TSectionName(Sections[I]).Tree.Levels.IndexOf(SectionName)<>-1 then begin
   Result:=Sections[I];
   exit;
  end;
//!!!
  If Additional<>nil then Result:=Additional.FindByName(SectionName);
end;

function TListByName.FindByName2(SectionName: AnsiString;Index:Integer = 0): TSectionName;
var I:Integer;S: AnsiString;
begin
 Result:=nil;
 If Pos('[',SectionName)<>0 then begin
  S:=SectionName;
  S:=Copy(S,1,Pos('[',S)-1);
  SectionName:=Trim(S);
 end;
// Writein(['===============================']);
 For I:=0 to Sections.Count-1 do begin
//  Writein([SectionName, TSectionName(Sections[I]).IndexName(Index) ]);
  If SectionName=TSectionName(Sections[I]).IndexName(Index) then begin
  Result:=Sections[I];
  exit;
 end;
 end;
// поиск секций с деревом
 For I:=0 to Sections.Count-1 do If TSectionName(Sections[I]).Tree<>nil then
  If TSectionName(Sections[I]).Tree.Levels.IndexOf(SectionName)<>-1 then begin
   Result:=Sections[I];
   exit;
  end;                                
 //!!!
 If Additional<>nil then
  Result:=Additional.FindByName2(SectionName,Index);
end;

function TListByName.FindByNameUpper(SectionName: AnsiString): TSectionName;
var I:Integer;S: AnsiString;
begin
 Result:=nil;
 For I:=0 to Sections.Count-1 do If UpperCase(SectionName)=UpperCase(TSectionName(Sections[I]).IndexName(I)) then begin
  Result:=Sections[I];
  exit;
 end;
 //!!!
 If Additional<>nil then Result:=Additional.FindByNameUpper(SectionName);
end;

function TListByName.FindEngSubString(SectionName, ItemName: AnsiString;var Value: AnsiString): AnsiString;  // ищем по Названию секции SN.IndexName(1) числовое значение Rus атрибута
var SN:TSectionName;First,Second,Third: AnsiString;
    I,J:Integer;
begin
 Result:='';Value:='';
 For I:=0 to Sections.Count-1 do begin
  SN:=Sections[I];
  If (AnsiUpperCase(SN.indexName(1)) = AnsiUpperCase(SectionName)) then begin
   // нашли секцию по второму имени -> ищем элемент по второму имени
   First:='';Second:='';Third:='';
   For J:=0 to SN.Count-1 do If (Pos('[',SN[J])>1) and (Pos(';',SN[J])>1) then begin
    // отделем первое имя
    First:=Trim(Copy(SN[J],1,Pos('[',SN[J])-1));
    Second:=SN[J];
    Second:=DelSubStr2(Second,First);
    Third:=Second;
    Second:=Trim(Copy(Second,Pos('[',Second)+1,Pos(';',Second)-Pos('[',Second)-1));
    Third:=Trim(Copy(Third, Pos(';',Third)+1,Pos(']',Third)-1 - (Pos(';',Third))));
    If Second = ItemName then begin
     Result:=First;
     Value:=Third;
    // MessageError(First+' = '+Second+' = '+Third);
     exit;
    end;
   end;// For J
   exit; // нашли секцию, не нашли значение
  end;
 end;
end;

function TListByName.FindRusSubString(SectionName, ItemName: AnsiString): AnsiString; // ищем по Названию секции SN.IndexName(0) числовое значение Eng - атрибута
var SN:TSectionName;First,Second,Third: AnsiString;
    I,J:Integer;
begin
 Result:='';
 If ItemName = 'sports_ground' then begin
  I:=0;
 end;
 For I:=0 to Sections.Count-1 do begin
  SN:=Sections[I];
  If (AnsiUpperCase(SN.indexName(0)) = AnsiUpperCase(SectionName)) then begin
   // нашли секцию по второму имени -> ищем элемент о второму имени
   First:='';Second:='';Third:='';
   For J:=0 to SN.Count-1 do If (Pos('[',SN[J])>1) and (Pos(';',SN[J])>1) then begin
    // отделем первое имя
    First:=Trim(Copy(SN[J],1,Pos('[',SN[J])-1));
    Second:=SN[J];
    Second:=DelSubStr2(Second,First);
    Third:=Second;
    Second:=Trim(Copy(Second,Pos('[',Second)+1,Pos(';',Second)-Pos('[',Second)-1));
    Third:=Trim(Copy(Third, Pos(';',Third)+1,Pos(']',Third)-1 - (Pos(';',Third))));
    If Second = ItemName then begin
     Result:=Third;
     //MessageError(First+' = '+Second);
     exit;
    end;
   end;// For J
  // exit; // нашли секцию, не нашли значение
  end;
 end;
 If Additional<>nil then begin
  Result:=Additional.FindRusSubString(SectionName,ItemName);
 end;
end;

function TListByName.FindSubString(SectionName, ItemName: AnsiString;St: TStrings;var Error: AnsiString): boolean;
var I,J:Integer;SN:TSectionName;S: AnsiString;
begin
 Error:='';
 For I:=0 to Sections.Count-1 do begin
  SN:=Sections[I];If SN.indexName(0) = SectionName then
 begin
  // нашли секцию, если не найдем значение - вернем ошибку
   For J:=0 to SN.Count-1 do If Pos('[',SN[J])>1 then begin
    If Pos('[',SN[J])<>0 then S:=Trim(Copy(SN[J],1,Pos('[',SN[J])-1));
    If Pos('[',ItemName)>1 then ItemName:=Trim(Copy(ItemName,1,Pos('[',ItemName)-1));
    If ansiLowerCase(ItemName) = ansiLowerCase(S) then begin
     S:=SN[J];
     If Pos('[',SN[J])<>0 then begin
      S:=Copy(S,Pos('[',S)+1,Pos(']',S)-1);DelSubStr(S,']');
      If Pos('/',S)<>0 then
       S:=Copy(S,Pos(';',S)+1,Pos('/',S)-Pos(';',S)-1) else
       S:=Copy(S,Pos(';',S)+1,Length(S));
     end;
     DelSubStr(S,#13#10);
     St.Add(Trim(S));
    end;
   end;
  If St.Count=0 then Error:=SectionName+'|'+ItemName;
 end;
 end;
 Result:=St.Count>0;
 //!!!
 If Additional<>nil then begin
  Result:=Additional.FindSubString(SectionName,ItemName,St,Error);
 end;
end;

function TListByName.FindSubStringForAll(SectionName, ItemName: AnsiString): AnsiString;
var I,J:Integer;SN:TSectionName;S: AnsiString;FinalName: AnsiString;
begin
 Result:='';
 For I:=0 to Sections.Count-1 do begin
  SN:=Sections[I];If SN.indexName(0) = SectionName then
   For J:=0 to SN.Count-1 do If Pos('[',SN[J])>1 then begin
    S:=SN[J];
//    If Pos('[',ItemName)>1 then FinalName:=Trim(Copy(ItemName,1,Pos('[',ItemName)-1));
    If Pos(ItemName,S)<>0 then begin
     Result:=Trim(Copy(S,1,Pos('[',S)-1));
     exit;
    end;
   end;
 end;
 //!!!
 If Additional<>nil then Result:=Additional.FindSubStringForAll(SectionName,ItemName);
end;

function TListByName.FindSubStringForAll2(SectionName, ItemName: AnsiString): AnsiString;
var I,J:Integer;SN:TSectionName;S: AnsiString;FinalName: AnsiString;
begin
 Result:='';
 For I:=0 to Sections.Count-1 do begin
  SN:=Sections[I];If SN.indexName(0) = SectionName then
   For J:=0 to SN.Count-1 do If Pos('[',SN[J])>1 then begin
    S:=SN[J];
//    If Pos('[',ItemName)>1 then FinalName:=Trim(Copy(ItemName,1,Pos('[',ItemName)-1));
    If ItemName = S then begin
     Result := S;
     exit;
    end else
    If Pos(ItemName,S)<>0 then begin
     Result:=Trim(Copy(S,Pos('[',S)+1,Pos(']',S) - Pos('[',S) - 1));
     exit;
    end;
   end else
    If ItemName = SN[J] then begin
     Result := ItemName;
     exit;
    end; // for J
 end; // For I:=
 //!!!
 If Additional<>nil then Result:=Additional.FindSubStringForAll(SectionName,ItemName);
end;

procedure TListByName.LoadFromFile(FileName: AnsiString; objType: AnsiString);
var F:TextFile;
    I:Integer;
    S: AnsiString;
    SectionName:TSectionName;
    Tree:TTree;
    N1,N2,N3,N4,N5:TNode;
    Ext: AnsiString;
Function sCount:Integer;
var I:Integer;
begin
 Result:=0;
 For I:=1 to Length(S) do If S[I]=#9 then Inc(Result);
end;
begin
If objType <> '' then begin
 Ext := ExtractFileExt(FileName);
 DelSubStr(FileName, Ext);
 FileName := FileName + objType + Ext;
end;
AssignFile(F,FileName);
Reset(F);
try
SectionName:=nil;
 While not Eof(F) do begin
  Readln(F,S);//S:=Trim(S);
  If Pos('[',S) = 1 then begin
   DelSubStr(S,'[');DelSubStr(S,']');S:=Trim(S);
   SectionName :=TSectionName.Create(S);
   If Pos('+',S)<>0 then
    Tree:=TTree.Create(S) else
    Tree:=nil;
   SectionName.Tree:=Tree;
   Sections.Insert(SectionName);
  end else If SectionName<>nil then begin
   If Tree = nil then SectionName.InsertStr(S) else begin
    If sCount=0 then
     N1:=Tree.AddItem(S) else
    If sCount=1 then
     N2:=Tree.AddChildItem(N1,S) else
    If sCount=2 then
     N3:=Tree.AddChildItem(N2,S) else
    If sCount=3 then
     N4:=Tree.AddChildItem(N3,S) else
    If sCount=4 then
     N5:=Tree.AddChildItem(N4,S) else
   end;
  end;
 end;
// открываем вспомогательный, пользовательский файл с +
 If Additional <> nil then begin
  S:=ExtractFileExt(FileName);
  Delete(FileName,Pos(S,FileName),Length(S));
  FileName:=FileName+'+'+S;
  If FileExists(FileName) then Additional.LoadFromFile(FileName, objType);
 end;
finally
 CloseFile(F);
// WriteIn([FileName, Sections.Count]);
// Tree.SaveToFile('lll');
end;
end;

procedure TListByName.SaveToFile(FileName: AnsiString);
var I,J:Integer;St:TStrings;
begin
 St:=TStringList.Create;
 For I:=0 to Sections.Count-1 do begin
  St.Add('['+TSectionName(Sections[I]).Name+']');
  For J:=0 to TSectionName(Sections[I]).Count-1 do St.Add(TSectionName(Sections[I])[J]);
  If St[St.Count-1]<>'' then St.Add('');
 end;
 St.SaveToFile(FileName);
 St.Free;
end;

initialization
 ListByName := nil;
 ListByDicts := nil;
end.
