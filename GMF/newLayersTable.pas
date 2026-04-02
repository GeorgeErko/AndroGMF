unit newLayersTable;

interface uses Collect, FMX.Graphics, EcDot, newProcs, newResource, lib2, Lib, Lines3,
               Lines2, newConsts, Writer, newSelector;

const
 LayerTableGUID = '{08171EB9-30D0-46D3-A342-F8CEE46C8B79}';

type
  TZnakView = class(TTwgObject)
   znakName:String;
   znakNum:Integer;
   znakLayer:String;
   Znak:Pointer;
   Error:Integer;
   Constructor Create(ZName,ZNum:String;Z:Pointer);
  end;

  TGroupZnk = class(TTwgObject)
   Name:String;
   Items:PCollection;
   Index:Integer;
   Constructor Create(Name_:String);
   Destructor Destroy;override;
  //
    Procedure AddItem(Item_:Pointer);
    Function GetItem(Index:Integer):TZnakView;
    Property Item[Index:Integer]:TZnakView read GetItem;
    function GetNum(Num: Integer): Pointer;
    Property ItemByNum[Name:Integer]:Pointer read GetNum;
    function GetName(Name: String): Pointer;
    Property ItemByName[Name:String]:Pointer read GetName;
  end;

  TGroupCollection = class(PCollection)
   Procedure AddGroup(GroupName:String);
    function GetGroupZnk(Index: Integer): TGroupZnk;
   Property Group[Index:Integer]:TGroupZnk read GetGroupZnk;default;
    function GetGroupByName(Index: String): TGroupZnk;
   Property GroupByName[Index:String]:TGroupZnk read GetGroupByName;
  end;

 { TMosLib }
 TMosLib = class(TTwgObject)
 private
  procedure CreateIni;
  procedure CreateGroupView;
 public
  FileName:AnsiString;
  LayerTable:Pointer;
  PntZnk,SqwZnk,LineZnk,BaseZnk,GrpName:String;
  PntLib,SqwLib,LineLib:PCollection;
  PSLib,SSLib,LSLib:TSortedCollection;// сортированные коллекции знаков
 // группы знаков по типам
  PointGroup:TGroupCollection;
  LineGroup:TGroupCollection;
  SquareGroup:TGroupCollection;
 //
  Selector: TSelector;
  Constructor Create(FileName_:AnsiString);
  Destructor Destroy;override;
  Constructor CreateEmpty;
  Function SearchRes(Num:Extended):TResource;
  Function LoadZnaks(LibPath:AnsiString):boolean;
 end;

type
 TLayerTable = class (TTwgObject)
  private
   fActiveLayer:TResource;
   fActivepoint:TPoint_Sign;
   fActiveLine:TGeoLine;
   fActivesymbology: ShortInt;
//    FOnChange: procAddPrim;
    function GetLayer(Index: Integer): TResource;
    function GetLayerCout: Integer;
    function GetNullLayer: TResource;
    function GetActiveLayer: TResource;
    procedure SetActiveLayer(const Value: TResource);
    function GetActiveLine: TGeoLine;
    function GetActivePoint: TPoint_Sign;
    procedure SetActiveLine(const Value: TGeoLine);
    procedure SetActivePoint(const Value: TPoint_Sign);
    function GetLayerName(Index: AnsiString): TResource;
    function GetLayerLevel(Index: Integer): TResource;
    function GetLinearLayer(Index: Integer): TResource;
    function GetLinearLayerName(Index: AnsiString): TResource;
//    procedure SetOnChange(const Value: procAddPrim);
    function GetLinearLayerCout: Integer;
    function GetLayerByKey(Index: AnsiString): TResource;
  public
  MkLib:TMosLib;
  Layers:PCollection; // коллекция слоев TResource в данном объекте
  LinearLayers:PCollection;
 //
  Selector: TSelector;
  Constructor Create(Mk:TMosLib);
  Destructor Destroy;override;
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
  Function CreateLayersView(LayerCol:PCollection):Integer;
 //
  Property LayerCount:Integer read GetLayerCout;
  Property L2Count:Integer read GetLinearLayerCout;
  Property Layer[Index:Integer]:TResource read GetLayer;default;
  Property LayerName[Index:AnsiString]:TResource read GetLayerName;
  Property LayerByKey[Index:AnsiString]:TResource read GetLayerByKey;
  Property LayerLevel[Index:Integer]:TResource read GetLayerLevel;
  Property NullLayer:TResource read GetNullLayer;
  Property ActiveLayer:TResource read GetActiveLayer write SetActiveLayer;
  Property ActivePoint:TPoint_Sign read fActivePoint write fActivePoint;
  Property ActiveLine:TGeoLine read fActiveLine write fActiveLine;
  Property ActiveSymbology:ShortInt read fActivesymbology write fActiveSymbology;
 // линейная таблица
  Property LinearLayer[Index:Integer]:TResource read GetLinearLayer;
  Property LinearLayerName[Index:AnsiString]:TResource read GetLinearLayerName;
  Procedure FillLinearLayers;
 //
  Function SearchLayer(ID:Double):TResource;
  Procedure ShowLayerTable;
  Procedure CheckAllLayers(Check:boolean);
  Procedure SetMaxID(var ID:Extended);
  Procedure AddLayer(PR:TResource);
  Procedure AddSubLayer(PR:TResource);
  Function AddLayerByTemplate(Parent,Template:TResource):TResource;
  Procedure DeleteLayer(Index:Integer);
  Procedure DeleteSubLayer(PR:TResource);
  Procedure CreateSignView;
  Procedure ResetChildsLayer;
  Procedure ResetChildsLayerMkLib;
 //
//  Property OnChange:procAddPrim read FOnChange write SetOnChange;
 //
  Procedure MergeTable(mergeTable:TLayerTable;divLayers:PCollection;addNullLayers:boolean);
 //
  Procedure SaveToFile(FileName:AnsiString);
  Function LoadFromFile(FileName: AnsiString;OnlyColor:boolean = False;OnlyCheck:boolean = False): boolean;
 //
  Function AddExistSysLayer(lName:AnsiString):TResource;
 //
  Procedure DuplicateGroup;
 end;

//Procedure DrawGeoLayer(Canvas:TCanvas;Layer:TResource;State:TCustomDrawState;Rect:TRect;Images:TImageList);

var Cells: Array [0..4] of Integer;

implementation uses TwgColle, Classes, System.IniFiles, System.SysUtils;

{ TZnakView }

constructor TZnakView.Create(ZName,ZNum:String;Z: Pointer);
var S:String;
begin
 znakName:=ZName;Znak:=Z;
 znakLayer:='';
// разбираем номер знака
 If Pos('/',ZNum)<>0 then begin
  S:=Copy(ZNum,1,Pos('/',ZNum)-1);
  try znakNum:=StrToInt(S);except Error:=1;exit;end;
  znakLayer:=Copy(ZNum,Pos('/',ZNum)+1,Length(ZNum));
 end else try
  znakNum:=StrToInt(ZNum);
 except Error:=2;end;
end;

{ TGroupZnk }

procedure TGroupZnk.AddItem(Item_:Pointer);
begin
 Items.Insert(Item_);
end;

constructor TGroupZnk.Create;
begin
 Name:=Name_;
 Items:=PCollection.Create(1);
end;

destructor TGroupZnk.Destroy;
begin
 Items.DeleteAll;Items.Free;
end;

function TGroupZnk.GetItem(Index: Integer): TZnakView;
begin
 Result:=Items[Index]
end;

function TGroupZnk.GetName(Name: String): Pointer;
var I:Integer;
begin
 Result:=nil;Index:=-1;
 For I:=0 to Items.Count-1 do If AnsiUpperCase(Item[I].znakName) = AnsiUpperCase(Name) then begin
  Result:=Items[I];Index:=I;exit;
 end;
end;

function TGroupZnk.GetNum(Num: Integer): Pointer;
var I:Integer;
begin
 Result:=nil;Index:=-1;
 For I:=0 to Items.Count-1 do If Item[I].znakNum = Num then begin
  Result:=Items[I];Index:=I;exit;
 end;
end;

{ TGroupCollection }

procedure TGroupCollection.AddGroup(GroupName: String);
begin
 Insert(TGroupZnk.Create(GroupName));
end;

function TGroupCollection.GetGroupByName(Index: String): TGroupZnk;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to Count-1 do If Group[I].Name = Index then begin Result:=Group[I];exit;end;
end;

function TGroupCollection.GetGroupZnk(Index: Integer): TGroupZnk;
begin
 Result:=Items[Index];
end;

{
Procedure DrawGeoLayer(Canvas:TCanvas;Layer:TResource;State:TCustomDrawState;Rect:TRect;Images:TImageList);
var R3:TRect;HItem:Integer;
    Pen,Brush:hPen;
Function GetFontColor:Integer;
begin
 Result:=clWindowText;
 If Layer=nil then Exit;
 if cdsSelected in State then begin
   Canvas.Brush.Color:=clSilver;
  // если слой используется в объекте
   Result:=clGray;
   If Layer.Resources.Count>0 then Canvas.Font.Style:=[fsBold] else Canvas.Font.Style:=[];
  // If Layer.Resources.Count>0 then Result:=clBlack else Result:=clGray;
 end else begin
   Canvas.Brush.Color:=clWindow;
   Result:=clGray;
   If Layer.Resources.Count>0 then Canvas.Font.Style:=[fsBold] else Canvas.Font.Style:=[];
  // If Layer.Resources.Count>0 then Result:=clWindowText else Result:=clGray;
 end;
end;
begin
 Canvas.Font.Color:=GetFontColor;
 HItem:=Rect.Bottom-Rect.Top;
// Rect.Left:=Rect.Left-HItem;
 Rect.Left:=Rect.Left-HItem;
 Cells[0]:=Rect.Left;
 Cells[1]:=Cells[0]+HItem+2;
 Cells[2]:=Cells[1]+HItem;
 Cells[3]:=Cells[2]+HItem+HItem div 2-HItem div 4;
 Cells[4]:=Cells[3]+HItem div 2+2;
 Canvas.FillRect(Rect);
 If Layer=nil then Exit;
 Pen:=SelectObject(Canvas.Handle,CreatePen(ps_Solid,0,Layer.LineColor));
 If Layer.Hatch=0 then
  Brush:=SelectObject(Canvas.Handle,CreateSolidBrush(Layer.GetColor)) else
  Brush:=SelectObject(Canvas.Handle,CreateHatchBrush(Layer.Hatch-2,fillColor(Layer.GetColor)));
 R3:=Rect;R3.Left:=Cells[1]+2;R3.Top:=R3.Top+2;R3.Bottom:=R3.Top+HItem-4;R3.Right:=Cells[1]+HItem-2;
 Rectangle(Canvas.Handle,R3.Left,R3.Top,R3.Right,R3.Bottom);
 DeleteObject(SelectObject(Canvas.Handle,Pen));
 DeleteObject(SelectObject(Canvas.Handle,Brush));
 If Images<>nil then Images.Draw(Canvas,Cells[2],Rect.Top,Layer.Check,True);
 Canvas.TextOut(Cells[2]+HItem+3,Rect.Top+1,Upper(Layer.RecString));
end;
}
{ TLayerTable }

constructor TLayerTable.Create(Mk:TMosLib);
begin
 MkLib:=Mk;
 if MkLib<>nil then MkLib.LayerTable:=Self;
 Layers:=PCollection.Create(1);
 LinearLayers:=PCollection.Create(1);
 factiveLayer:=nil;
 factiveSymbology:=-1;
// Writeln('TableCreate');
end;

destructor TLayerTable.Destroy;
begin
 Layers.Free;
 LinearLayers.DeleteAll;LinearLayers.Free;
end; 

constructor TLayerTable.Load(Stream: TBufStream);
var ID:Double;
begin
// Writeln('TableLoad');
 Selector := Stream.Selector;
 Stream.Read(ClassVersion,SizeOf(ClassVersion));
 Stream.Read(ID,SizeOf(ID));
 Layers:=PCollection(Stream.Get);
 LinearLayers:=PCollection.Create(1);
 FillLinearLayers;
  If ID=0 then fActiveLayer:=Layers[0] else fActiveLayer:=SearchLayer(ID);
end;

procedure TLayerTable.Store(Stream: TBufStream);
var ID:Double;
begin
 if fActiveLayer=nil then ID:=0 else ID:=fActiveLayer.ID;
 ClassVersion:=ClassVerConst;
 Stream.Write(ClassVersion,SizeOf(ClassVersion));
 Stream.Write(ID,SizeOf(ID));
 Stream.Put(Layers);                                    
end;

function TLayerTable.CreateLayersView(LayerCol:PCollection): Integer;
var PR:TResource;I:Integer;
begin
 Layers.FreeAll;
 //заполняем таблицу слоев из TwgForm.Mklib
 Layers.Insert(TResource.CreateNew);
 //DisposeStr(Layer[0].RecString);
 Layer[0].RecString:='Системный';
 If LayerCol<>nil then
 For I:=0 to LayerCol.Count-1 do begin
  PR:=MkLib.SearchRes(TExt(LayerCol[I]).Num);
  If PR<>nil then begin
   Layers.Insert(TResource.CreateRes(PR.GetResRec));
   LinearLayers.Insert(Layers[Layers.Count-1]);
  end;
 end;
 fActiveLayer:=Layers[0];
 FillLinearLayers;
// Writeln('LayersCount=',Layers.Count);
end;

function TLayerTable.GetLayer(Index: Integer): TResource;
begin
 Result:=Layers[Index];
end;

function TLayerTable.GetLayerCout: Integer;
begin
 Result:=Layers.Count;
end;

function TLayerTable.SearchLayer(ID: Double): TResource;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to LinearLayers.Count-1 do begin
 // Writeln(Round(Layer[I].ID*100),' ',Round(ID*100),Round(Layer[I].ID*100)=Round(ID*100));
  If Round(LinearLayer[I].ID*100)=Round(ID*100) then begin
  Result:=LinearLayer[I];exit;
 end;
 end;
end;

procedure TLayerTable.ShowLayerTable;
var I:Integer;F:TextFile;
begin
 exit;
// Writeln('---------------',LayerCount);
// AssignFile(F,'C:\Layers.txt');
// Rewrite(F);
 For I:=0 to LinearLayers.Count-1 do begin
  If LinearLayer[I].Parent=nil then
  Writeln(F,LinearLayer[I].RecString) else Writeln(F,'          ',LinearLayer[I].RecString);
 end;
// CloseFile(F);
// Writeln('---------------');
end;

function TLayerTable.GetNullLayer: TResource;
begin
 Result:=Layer[0];
end;

function TLayerTable.GetActiveLayer: TResource;
begin
 Result:=fActiveLayer;
end;

procedure TLayerTable.SetActiveLayer(const Value: TResource);
begin
 if LinearLayers.IndexOf(Value)<>-1 then fActiveLayer:=Value else raise Exception.Create('[LayerTable] Не найден слой '+FloatToStr(Value.ID));
end;

procedure TLayerTable.CheckAllLayers(Check: boolean);
var I:Integer;
begin
 For I:=0 to LinearLayers.Count-1 do LinearLayer[I].Check:=ord(Check);
end;

procedure TLayerTable.SetMaxID(var ID: Extended);
var I:Integer;Max:Double;
begin
 Max:=1;
 For I:=0 to LinearLayers.Count-1 do If LinearLayer[I].ID<Max then Max:=LinearLayer[I].ID;
 ID:=Max-0.01;
end;

procedure TLayerTable.AddLayer(PR: TResource);
begin
 If Round(PR.ID*100)=0 then SetMaxID(PR.ID);
 Layers.Insert(PR);
 LinearLayers.Insert(PR);
// If Assigned(OnChange) then OnChange(Self);
end;

procedure TLayerTable.AddSubLayer(PR: TResource);
begin
 If Round(PR.ID)=0 then SetMaxID(PR.ID);
 If ActiveLayer.Parent<>nil then ActiveLayer.Parent.InsertLayer(PR) else ActiveLayer.InsertLayer(PR);
 LinearLayers.Insert(PR);
// If Assigned(OnChange) then OnChange(Self);
end;

function TLayerTable.AddLayerByTemplate(Parent, Template:TResource):TResource;
var PR:TResource;
begin
 PR:=TResource.CreateRes(Template.GetResRec);
 If Round(PR.ID)=0 then SetMaxID(PR.ID);
 If Parent<>nil then begin
  Parent.InsertLayer(PR);
  LinearLayers.Insert(PR);
 end else begin
  Layers.Insert(PR);
  LinearLayers.Insert(PR);
 end;
 Result:=PR;
end;

procedure TLayerTable.CreateSignView;
var I,N:Integer;
begin
 If MkLib=nil then exit;
 For I:=0 to LinearLayers.Count-1 do begin
 // точечный знак
  N:=SearchThis(MkLib.PSLib,LinearLayer[I].ZnkInd.SPInd);
  If N<>-1 then LinearLayer[I].Point:=MkLib.PSLib[N] else LinearLayer[I].Point:=nil;
 // линейный знак
  N:=SearchLine(MkLib.LSLib,LinearLayer[I].ZnkInd.LInd);
  If N<>-1 then LinearLayer[I].Line:=MkLib.LSLib[N] else LinearLayer[I].Line:=nil;
 // площадной знак
  N:=SearchLine(MkLib.SSLib,LinearLayer[I].SSInd);
  If N<>-1 then LinearLayer[I].Sqwear:=MkLib.SSLib[N] else LinearLayer[I].Sqwear:=nil;
 end;
// If Assigned(OnChange) then OnChange(Self);
end;

function TLayerTable.GetActiveLine: TGeoLine;
begin

end;

function TLayerTable.GetActivePoint: TPoint_Sign;
begin
end;

procedure TLayerTable.SetActiveLine(const Value: TGeoLine);
begin
end;

procedure TLayerTable.SetActivePoint(const Value: TPoint_Sign);
begin

end;

function TLayerTable.GetLayerName(Index: AnsiString): TResource;
var I:Integer;PR:TResource;
begin
 Result:=nil;
 For I:=0 to LinearLayers.Count-1 do begin
//  Writeln(AnsiUpperCase(Layer[I].RecString)=AnsiUpperCase(Index),' ',AnsiUpperCase(Layer[I].RecString),' ',AnsiUpperCase(Index));
  If AnsiUpperCase(LinearLayer[I].RecString)=AnsiUpperCase(Index) then begin
  Result:=LinearLayers[I];break;
 end;
 end;
// Writeln('Result=',Result=nil);
end;

function TLayerTable.GetLayerByKey(Index: AnsiString): TResource;
var I:Integer;PR:TResource;
begin
 Result:=nil;
 For I:=0 to LinearLayers.Count-1 do begin
  If Pos(AnsiUpperCase(Index),AnsiUpperCase(LinearLayer[I].RecString))=1 then begin
   Result:=LinearLayers[I];break;
  end;
 end;
end;

function TLayerTable.GetLayerLevel(Index: Integer): TResource;
var I:Integer;PR:TResource;
begin
 Result:=nil;
 For I:=0 to Layers.Count-1 do
  If Layer[I].Level=Index then begin
  Result:=Layer[I];break;
 end;
end;

procedure TLayerTable.DeleteLayer;
begin
 If Index<>0 then begin
  Layers.AtFree(Index);
 // If Assigned(OnChange) then OnChange(Self);
 end;
end;


function TLayerTable.GetLinearLayer(Index: Integer): TResource;
begin
 Result:=LinearLayers[Index];
end;

function TLayerTable.GetLinearLayerName(Index: AnsiString): TResource;
var I:integer;
begin
 Result:=nil;
 For I:=0 to LinearLayers.Count-1 do If LinearLayer[I].RecString = Index then begin
  Result:=LinearLayer[I];exit;
 end;
end;

procedure TLayerTable.FillLinearLayers;
var I,J:Integer;
begin
 LinearLayers.DeleteAll;
 For I:=0 to Layers.Count-1 do begin
  LinearLayers.Insert(Layers[I]);
  Layer[I].Childs.DeleteAll;
  For J:=0 to Layer[I].Resources.Count-1 do begin
   LinearLayers.Insert(Layer[I].Resources[J]);
   TResource(Layer[I].Resources[J]).Parent:=Layer[I];
   TResource(Layer[I].Resources[J]).Childs.DeleteAll;
  end;
 end;
end;


procedure TLayerTable.DeleteSubLayer(PR: TResource);
var I, Index:Integer;
begin
 // процедура не уничтожает слой, оставляя его для завершения операций над объектами данного слоя
 If PR.Parent<>nil then begin
  Index:=PR.Parent.Resources.IndexOf(PR);
  If Index<>-1 then begin
   PR.Parent.Resources.AtFree(Index);
   FillLinearLayers;
  // If Assigned(OnChange) then OnChange(Self);
  end;
 end else begin
  Index:=Layers.IndexOf(PR);
  If Index<>-1 then begin
   Layers.AtDelete(Index);
  // If Assigned(OnChange) then OnChange(Self);
  end;
 end;
end;

procedure TLayerTable.ResetChildsLayer;
var I, J:Integer;Pr,Pr1:TResource;Ext:TExt;
    P:PCollection;
begin
 For I:=0 to LinearLayers.Count-1 do begin
  Pr:=LinearLayer[I];
  P:=PCollection.Create(1);
  For J:=0 to Pr.Childs.Count-1 do
   begin
    Ext:=Pr.Childs[J];
    Pr1:=SearchLayer(Ext.Num);
    If Pr1<>nil then P.Insert(Pr1);
   end;
  Pr.Childs.Free;
  Pr.Childs:=P;
 end;
end;

procedure TLayerTable.ResetChildsLayerMkLib;
var I, J:Integer;Pr,Pr1:TResource;Ext:TExt;
    P:PCollection;
begin
 For I:=0 to LinearLayers.Count-1 do begin
  Pr:=LinearLayer[I];
  P:=PCollection.Create(1);
  For J:=0 to Pr.Childs.Count-1 do begin
    Ext:=Pr.Childs[J];
   try
    Pr1:=MkLib.SearchRes(Ext.Num);
    If Pr1<>nil then P.Insert(Pr1);
   except continue; end;
   end;
  Pr.Childs.Free;
  Pr.Childs:=P;
 end;
end;

{
procedure TLayerTable.SetOnChange(const Value: procAddPrim);
begin
 FOnChange := Value;
// Writeln('TableSetOnChange');
end;
}

function TLayerTable.GetLinearLayerCout: Integer;
begin
 Result:=LinearLayers.Count;
end;


procedure TLayerTable.MergeTable(mergeTable: TLayerTable;divLayers:PCollection;addNullLayers:boolean);
var F:TextFile;PR:TResource;oldID:Extended;
Procedure AddLayer_(Pr:TResource);
begin
 If (not Pr.usedInObject) and (not addNullLayers) then begin
  exit;
 end;
 If Pr.Parent<>nil then begin
 // Writeln(F,'AddSubLayer=',PR.Parent.RecString,' ',PR.RecSTring);
  Pr.Resources.DeleteAll;
  If LinearLayerName[PR.Parent.RecString]=nil then begin
   PR.Parent.ID:=0;
   AddLayer(PR.Parent);
  end;
  LinearLayerName[PR.Parent.RecString].Resources.Insert(PR);
  PR.Parent:=LinearLayerName[PR.Parent.RecString];
  oldID:=Pr.ID;Pr.ID:=0;
  SetMaxID(PR.ID);
  If divLayers<>nil then If oldID<>Pr.ID then divLayers.Insert(TExt2.Create(oldID,Pr.ID));
 end else begin
//  Writeln(F,'AddLAyer=',Pr.RecString);
  Pr.Resources.DeleteAll;
  oldID:=Pr.ID;Pr.ID:=0;
  AddLayer(Pr);
  If divLayers<>nil then If oldID<>Pr.ID then divLayers.Insert(TExt2.Create(oldID,Pr.ID));
 end;
 FillLinearLayers;
end;
var I:Integer;
begin
// AssignFile(F,'C:\TST.TXT');
// Rewrite(F);
 For I:=0 to mergeTable.LinearLayers.Count-1 do begin
  If LinearLayerName[mergeTable.LinearLayer[I].RecString] = nil then begin
   PR:=TResource.CreateRes(mergeTable.LinearLayer[I].GetResRec);
   PR.Childs:=PCollection.Create(1);
   AddLayer_(PR);
  end else begin
   // если слой был найден и ID разный -> записываем различия в коллекцию divLayers
   If divLayers<>nil then divLayers.Insert(TExt2.Create(mergeTable.LinearLayer[I].ID,LinearLayerName[mergeTable.LinearLayer[I].RecString].ID));
//   Writeln(F,'Found=',LinearLayerName[mergeTable.LinearLayer[I].RecString].RecString);
  end;
 end;
 FillLinearLayers;
 CreateSignView;
// CloseFile(F);
// !!! If Assigned(OnChange) then OnChange(Self);
// очищаем merge-таблицу
{ For I:=mergeTable.LayerCount-1 downTo 0 do begin
  Layer[I].Resources.DeleteAll;Layers.AtDelete(I);
 end;}
end;

function TLayerTable.LoadFromFile(FileName: AnsiString;OnlyColor:boolean = False;OnlyCheck:boolean = False): boolean;
var Buf:TBufStream;Table:TLayerTable;PR:TResource;I:Integer;
begin
 Buf:=TBufStream.InitFileStream(FileName,cmRead);
 try
  Table:=TLayerTable(Buf.Get);
 except Result:=False;Buf.Free;exit;end;
 Buf.Free;
 For I:=0 to Table.LinearLayers.Count-1 do begin
  PR:=LinearLayerName[Table.LinearLayer[I].RecString];
  If PR<>nil then begin
   If OnlyColor then begin
    PR.RGB.ARGB[1]:=Table.LinearLayer[I].RGB.ARGB[1];
    PR.RGB.ARGB[2]:=Table.LinearLayer[I].RGB.ARGB[2];
    PR.RGB.ARGB[3]:=Table.LinearLayer[I].RGB.ARGB[3];
   end else
   If OnlyCheck then begin
    PR.Check:=Table.LinearLayer[I].Check;
   end else 
   begin
    PR.Restruct(Table.LinearLayer[I].GetResRec,False);
   end;
   Table.LinearLayer[I].Childs:=PCollection.Create(1);
  end;
 end;
 FillLinearLayers;
 CreateSignView;
// !!! If Assigned(OnChange) then OnChange(Self);
//
 Table.Free;
end;

procedure TLayerTable.SaveToFile(FileName: AnsiString);
var Buf:TBufStream;
begin
 Buf:=TBufStream.InitFileStream(FileName,fmCreate);
  Buf.Put(Self);
 Buf.Free;
end;

function TLayerTable.AddExistSysLayer(lName: AnsiString): TResource;
var I:Integer;
begin
 For I:=0 to NullLayer.Resources.Count-1 do
  If AnsiUpperCase(NullLayer.Items[I].RecString)=AnsiUpperCase(lName) then begin Result:=NullLayer.Items[I];exit;end;
 Result:=AddLayerByTemplate(NULLLayer,NullLayer);
 //DisposeStr(Result.RecString);
 Result.RecString:=PAnsiChar(lName);
end;

procedure TLayerTable.DuplicateGroup;
var I,Index:Integer;DupLayer,DupSubLayer:TResource;S:AnsiString;
begin
 If ActiveLayer = nil then exit;
 If ActiveLayer.Resources.Count>0 then begin
  Index:=Layers.IndexOf(ActiveLayer);
  If Index = -1 then exit;
  DupLayer:=TResource.CreateRes(ActiveLayer.GetResRec);
  S:=DupLayer.RecString;S:=S+'_дубликат';
  DupLayer.RecString:=PAnsiChar(S);
  SetMaxID(DupLayer.ID);
 // добавляем Resources;
  If Index < Layers.Count-1 then Layers.AtInsert(Index+1,DupLayer) else Layers.Insert(DupLayer);
  LinearLayers.Insert(DupLayer);
  For I:=0 to ActiveLayer.Resources.Count-1 do begin
   DupSubLayer:=TResource.CreateRes(ActiveLayer[I].GetResRec);
   SetMaxID(DupSubLayer.ID);
   DupLayer.Resources.Insert(DupSubLayer);
   LinearLayers.Insert(DupSubLayer);
  end;
 end else MessageInform('Выбранный слой не является группой.');
end;


{ TMosLib }

constructor TMosLib.Create(FileName_: AnsiString);
begin
 FileName:=FileName_;
 PSLib:=PLib.Create(1);
 SSLib:=SLib.Create(1);
 LSLib:=LLib.Create(1);
 GrpName:='Topo500';
end;

destructor TMosLib.Destroy;
begin
 if PSLib<>nil then PSLib.Free;
 if SSLib<>nil then SSLib.Free;
 if LSLib<>nil then LSLib.Free;
end;

constructor TMosLib.CreateEmpty;
begin
 LoadZnaks('');
 GrpName:='Topo500';
end;

function TMosLib.LoadZnaks(LibPath: AnsiString): boolean;
var Buf:TBufStream;
    I,N:Integer;C:array[0..3] of AnsiChar;
    PR:TResource;PZ:TPoint_Sign;
    FName:String;
begin
//If GrpName<>'' then GrpName:=GrpName_;
 FName:=DelSubStr2(FileName,ExtractFileExt(FileName));
 if PSLib<>nil then PSLib.Free;
 if SSLib<>nil then SSLib.Free;
 if LSLib<>nil then LSLib.Free;
  PSLib:=PLib.Create(1);
  SSLib:=SLib.Create(1);
  LSLib:=LLib.Create(1);
Try
   PntZnk := FName+'.lib';
   Buf:=TBufStream.InitFileStream(FName+'.lib',fmOpenRead);
   Buf.Selector := Selector;
   Buf.Read(C,SizeOf(C));
    If C[1]+C[2]+C[3]='GO1' then VersionOfZnk:=1 else
    If C[1]+C[2]+C[3]='GO2' then VersionOfZnk:=2 else
    If C[1]+C[2]+C[3]='GO3' then VersionOfZnk:=3 else
    VersionOfZnk:=0;
    If VersionOfZnk=0 then Buf.Position:=0;
    PntLib:=PCollection(Buf.Get);
   Buf.Free;
   LineZnk := FName+'.lb2';
   Buf:=TBufStream.InitFileStream(FName+'.lb2',fmOpenRead);
   Buf.Selector := Selector;
    SqwLib:=PCollection(Buf.Get);
   Buf.Free;
//     SqwLib:=PCollection.Create(1);
   SqwZnk := FName+'.lb3';
   Buf:=TBufStream.InitFileStream(FName+'.lb3',fmOpenRead);
   Buf.Selector := Selector;
     LineLib:=PCollection(Buf.Get);
   Buf.Free;
  except on EStreamError do
   begin
     raise Exception.Create('Ошибка загрузки SIGN-библиотеки'+FName);
    try
     If PntLib<>nil then PntLib.Free;
     If SqwLib<>nil then SqwLib.Free;
     If LineLib<>nil then LineLib.Free;
    except end;
     Exit;
   end;
   end;
   For I:=0 to PntLib.Count-1 do
    PSLib.Insert(PntLib[I]);
   For I:=0 to SqwLib.Count-1 do
    SSLib.Insert(SqwLib[I]);
   For I:=0 to LineLib.Count-1 do
    begin
     TGeoLine(LineLib[I]).CreatePoints(PSLib);
     LSLib.Insert(LineLib[I]);
    end;
 // группировка INI-файл
  CreateINI;
  CreateGroupView;
 //
  PntLib.DeleteAll;PntLib.Free;
  SqwLib.DeleteAll;SqwLib.Free;
  LineLib.DeleteAll;LineLib.Free;
end;

function TMosLib.SearchRes(Num: Extended): TResource;
begin
 Result:=nil;
end;

procedure TMosLib.CreateIni;
var Ini:TIniFile;
Function GetGroupN(NameOf:String;var zName:String):String;
begin
 Result:='';
 If (Pos('[',NameOf)<>0) and (Pos(']',NameOf)<>0) then begin
  Result:=Copy(NameOf,Pos('[',NameOf)+1,Pos(']',NameOf)-Pos('[',NameOf)-1);
  zName:=Copy(NameOf,1,Pos('[',NameOf)-2);
 end;
end;
Procedure CreateLibNames(Col:PCollection;What:Byte);
var I,J:Integer;P:Pointer;St:TStrings;
    groupName,znkName:String;S:String;
Function ZnakName:String;begin case What of 0:Result:=TPoint_Sign(P).MyNameIs;1:Result:=TGeoLine(P).NameOf;2:Result:=TSqwear_Sign(P).NameOf;end;end;
Function ZnakInd:Integer;begin case What of 0:Result:=TPoint_Sign(P).MyInd;1:Result:=TGeoLine(P).IdNum;2:Result:=TSqwear_Sign(P).IdNum;end;end;
Procedure SetName(Nm:String);begin case What of 0:StrPCopy(TPoint_Sign(P).MyNameIs,Nm);1:StrPCopy(TGeoLine(P).NameOf,PChar(Nm));2:StrPCopy(TSqwear_Sign(P).NameOf,PChar(Nm));end;end;
begin
 For I:=0 to Col.Count-1 do begin
  P:=Col[I];
  znkName:=ZnakName;
  groupName:=GetGroupN(ZnakName,znkName);
  SetName(znkName);
  If groupName<>'' then begin
   St:=TStringList.Create;Ini.ReadSectionValues(groupName,St);
   For J:=St.Count-1 downTo 0 do If Pos('=',St[J])<>0 then begin
    St[J]:=Copy(St[J],Pos('=',St[J])+1,Length(St[J]));
    If Pos('/',St[J])>0 then begin
     S:=Copy(St[J],1,Pos('/',St[J])-1);
     ST[J]:=S;
    end;
   end else St.Delete(J);
   If St.IndexOf(IntToStr(ZnakInd))=-1 then
    // Ini.WriteString(groupName,znkName,IntToStr(ZnakInd))
    else
   St.Free;
  end;
 end;
end;
begin
 Ini:=TIniFile.Create(MainPath+'\'+SetExtFile(PntZnk,'.grp'));
  If PntLib<>nil then CreateLibNames(PntLib,0);
 Ini.Free;
 Ini:=TIniFile.Create(MainPath+'\'+SetExtFile(PntZnk,'.gr1'));
  If LineLib<>nil then CreateLibNames(LineLib,1);
 Ini.Free;
 Ini:=TIniFile.Create(MainPath+'\'+SetExtFile(SqwZnk,'.gr2'));
  If SqwLib<>nil then CreateLibNames(SqwLib,2);
 Ini.Free;
end;

Procedure TMosLib.CreateGroupView;
Function GetLibZnaks(IniName:String;Lib:TSortedCollection;Group:TGroupCollection;Flag:Integer):boolean;
var I,J,N:Integer;
    Ini:TIniFile;
    Names,Items,Values:TStrings;
    ZnkView:TZnakView;
begin
 Ini:=TIniFile.Create(IniName);
 Names:=TStringList.Create;Items:=TStringList.Create;Values:=TStringList.Create;
 Ini.ReadSections(Names);
  For I:=0 to Names.Count-1 do begin
   Group.AddGroup(Names[I]);
   Case Flag of  0:Group[I].AddItem(TZnakView.Create(byLayer,'0',TPoint_Sign.Create(0,0,byLayer))); 1:Group[I].AddItem(TZnakView.Create(byLayer,'0',TGeoLine.Create(byLayer)));
                 2:Group[I].AddItem(TZnakView.Create(byLayer,'0',TSqwear_Sign.Create(byLayer)));
   end;
   Ini.ReadSectionValues(Names[I],Values);
   Items.Text:=Values.Text;
   For J:=Values.Count-1 downTo 0 do
    If Pos('=',Values[J])<>0 then begin
     Values[J]:=Copy(Values[J],Pos('=',Values[J])+1,Length(Values[J]));
     Items[J]:=Copy(Items[J],1,Pos('=',Items[J])-1);
    end else begin
     Values.Delete(J);
     Items.Delete(J);
    end;
   //заполняем группу знаками
   For J:=0 to Values.Count-1 do begin
    try
     ZnkView:=TZnakView.Create(Items[J],Values[J],nil);
     If ZnkView.Error<>0 then begin ZnkView.Free;continue;end;
     Case Flag of 0:N:=SearchThis(Lib,ZnkView.znakNum);1:N:=SearchLine(Lib,ZnkView.znakNum);2:N:=SearchLine(Lib,ZnkView.znakNum);end;
     If N<>-1 then begin
      Case Flag of 0:ZnkView.Znak:=PSLIb[N];1:ZnkView.Znak:=LSLib[N];
                   2:ZnkView.Znak:=SSLib[N];
      end;
     Group.GroupByName[Names[I]].AddItem(ZnkView);
     // переименовываем знак
      Case Flag of 0:StrPCopy(TPoint_Sign(PSLib[N]).MyNameIs,PChar(Items[J]));1:StrPCopy(TGeoLine(LSLib[N]).NameOf,PChar(Items[J]));
                   2:StrPCopy(TSqwear_Sign(SSLib[N]).NameOf,PChar(Items[J]));
      end; // Case

     end; // If N<>-1
    except end;
   end;
  end;
 Names.Free;Items.Free;Values.Free;
 Ini.Free;
end;
begin
 If PointGroup<>nil then PointGroup.Free;
 If LineGroup<>nil then LineGroup.Free;
 If SquareGroup<>nil then SquareGroup.Free;
{}
 PointGroup:=TGroupCollection.Create(1);
 LineGroup:=TGroupCollection.Create(1);
 SquareGroup:=TGroupCollection.Create(1);
If FileExists(MainPath+GrpName+'.grp') then begin
// MessageInform('Невозможно загрузить файл таблицы групп условных обозначений '+GrpName+'. Загружены значения по умолчанию.');
 GetLibZnaks(SetExtFile(PntZnk,'.grp'),PSLib,PointGroup,0);
 GetLibZnaks(SetExtFile(LineZnk,'.gr1'),LSLib,LineGroup,1);
 GetLibZnaks(SetExtFile(SqwZnk,'.gr2'),SSLib,SquareGroup,2);
end;
{}
end;

initialization
end.
