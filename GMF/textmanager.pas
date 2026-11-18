unit textmanager;

interface
uses Sysutils, Classes, Collect, EMath, FMX.Graphics, TwgBitmaps;

const
  tpBold = 1;
  tpItalic = 2;
  tpUnderline = 4;

type
 hDc = Integer;

 TTextManagerUpdateProfile=record
  SchemaMS: Int64;
  ReplaceMS: Int64;
  CreateTextsMS: Int64;
  BuildBitmapsMS: Int64;
  AfterLoadMS: Int64;
  RebuildMS: Int64;
  Calls: Int64;
  InitialCalls: Int64;
  FastCalls: Int64;
  RebuildCalls: Int64;
 end;

  { TTextParams }

  TTextParams = class(TTwgObject)
    FValue: AnsiString;
    FDx: single;
    FDy: single;
    FUgol: single;
    FH: single;
    FW: single;
    FAttr: byte;   // 1: bold, 2: italic, 4: underline
    tmFontIndex:Integer;
    AlignX, AlignY: single;
    DxfLock:Boolean;
    ShiftX,ShiftY:Smallint;// ñìåùåíèå îòíîñèòåëüíî òî÷êè
    FBg:Boolean;
 //   DxfFontName:AnsiString;
 //   FFontIndex: integer;
 //   FColor: TColor;
    constructor Create(const value: AnsiString; const Dx, Dy, Ugol, h, w: double; attr: byte;AlX,AlY:single;SX,SY:SmallInt;FBg_:Boolean);
    constructor Load(buf: TBufStream); override;
    procedure Store(buf: TBufStream);  override;
    destructor Destroy;override;
    function TextAlign: Byte;
  end;

type
 // результат диалога ввода атрибутов: OK - значения записаны
  TTextsDone = reference to procedure(OK: Boolean);

  TTextManager = class(TTwgObject)
  private
    function InitSL: TStringList;
    procedure AfterLoad(znaks: PCollection);
//    procedure AfterLoad2(znaks: PCollection);
    function CreateTexts(znaks: PCollection): PCollection;
    procedure ClearTextBitmaps;
    procedure BuildTextBitmaps;
    procedure EnsureTextBitmapsSize;
    procedure UpdateTextBitmaps;
  public
    FVars: TStringList;
    FSave: PCollection;
    oldBmp: TList;
    FValues: PCollection;
    FTexts: PCollection;
    FTextBitmaps: TTwgBitmaps;
    UpdateResults:Boolean;
    constructor Create;
    constructor CreateAsTextManager(T:TTextManager;Znaks:PCollection);
    destructor Destroy; override;
  // диалоги ввода значений атрибутов (VarSetForm). Диалог не блокирует
  // вызывающий код (на Android синхронного ShowModal нет): результат - в Done
    procedure SetTexts(MainForm: TObject; X, Y, Z: Double; UseCoord: Boolean; TwgForm_: Pointer; const Done: TTextsDone);
  // атрибуты знака точки Point_ в форме GlobalVarSetDlgClass (режим TABLET)
    procedure SetTexts2(TwgForm_: Pointer; Point_: Pointer; EditMode: Boolean; Mode: Byte; const Done: TTextsDone);
    procedure SetZnaks(znaks: PCollection);          // Âûçûâàòü ïîñëå Create èëè Load
    procedure Update(znaks: PCollection);            // Âûçûâàòü åñëè Znaks èçìåíèëñÿ

    function Equal(tm: TTextManager): boolean;
    function AttrValue(V: AnsiString): AnsiString;
    function SetAttrValue(V: AnsiString;Value:AnsiString):boolean;
    function GetXY(V:AnsiString;var X,Y:Double):boolean;
    function SetXY(V:AnsiString;X,Y:Double):boolean;
//
    procedure UpdateText(BackGround:Byte = 0);
    procedure Restore;
    procedure MoveText(Index:Integer;Dx,Dy:Double);
    procedure MoveTextShift(Index:Integer;Dx,Dy:Integer);
    procedure RotateText(Index:Integer;Angle:Double);
    procedure StretchText(Index:Integer;XText, YText, X ,Y, Ko, Ug:Double);
    function GetFontIndex(F:Pointer):Integer;
    procedure GetAttrNames(Names: TStrings;Values:TStrings = nil);
//
    constructor Load(buf: TBufStream); override;
    procedure Store(buf: TBufStream); override;
//
    procedure SetUserParams(FName:AnsiString;H:Double;Style:Integer);
//
    function SetSysValue(TypeOf:Byte;Value:AnsiString):boolean;
    function GetSysValue(TypeOf:Byte):AnsiString;
    Procedure SetSysSpatialData(X,Y,Z:AnsiString);
  //
    function GetAttrParams(V: AnsiString; var Angle, H, W: Double): boolean;
    function SetAttrParams(V: AnsiString; Angle, H, W: Double): boolean;
    function UseAttr(V: AnsiString): boolean;
  end;

Procedure StartTextManagerUpdateProfile;
Function StopTextManagerUpdateProfile: TTextManagerUpdateProfile;

// FMX.Forms, WptForm2, EcDot, VarSetForm - для диалогов SetTexts/SetTexts2; в начале
// списка, чтобы не перекрывать идентификаторы следующих модулей
// GMF_READER - сборка читателя GMF (библиотека gmfreader): без диалогов VarSetForm
implementation uses FMX.Forms, WptForm2, EcDot, {$IFNDEF GMF_READER}VarSetForm, {$ENDIF}Lib, DwgText,
     newConsts, Writer, LConvEncoding, System.Diagnostics;

var
 TextManagerUpdateProfileEnabled: Boolean;
 TextManagerSchemaTicks: Int64;
 TextManagerReplaceTicks: Int64;
 TextManagerCreateTextsTicks: Int64;
 TextManagerBuildBitmapsTicks: Int64;
 TextManagerAfterLoadTicks: Int64;
 TextManagerRebuildTicks: Int64;
 TextManagerUpdateCalls: Int64;
 TextManagerInitialCalls: Int64;
 TextManagerFastCalls: Int64;
 TextManagerRebuildCalls: Int64;

Procedure StartTextManagerUpdateProfile;
begin
 TextManagerSchemaTicks:=0;
 TextManagerReplaceTicks:=0;
 TextManagerCreateTextsTicks:=0;
 TextManagerBuildBitmapsTicks:=0;
 TextManagerAfterLoadTicks:=0;
 TextManagerRebuildTicks:=0;
 TextManagerUpdateCalls:=0;
 TextManagerInitialCalls:=0;
 TextManagerFastCalls:=0;
 TextManagerRebuildCalls:=0;
 TextManagerUpdateProfileEnabled:=True;
end;

Function StopTextManagerUpdateProfile: TTextManagerUpdateProfile;
begin
 TextManagerUpdateProfileEnabled:=False;
 Result.SchemaMS:=Round(TextManagerSchemaTicks*1000/TStopwatch.Frequency);
 Result.ReplaceMS:=Round(TextManagerReplaceTicks*1000/TStopwatch.Frequency);
 Result.CreateTextsMS:=Round(TextManagerCreateTextsTicks*1000/TStopwatch.Frequency);
 Result.BuildBitmapsMS:=Round(TextManagerBuildBitmapsTicks*1000/TStopwatch.Frequency);
 Result.AfterLoadMS:=Round(TextManagerAfterLoadTicks*1000/TStopwatch.Frequency);
 Result.RebuildMS:=Round(TextManagerRebuildTicks*1000/TStopwatch.Frequency);
 Result.Calls:=TextManagerUpdateCalls;
 Result.InitialCalls:=TextManagerInitialCalls;
 Result.FastCalls:=TextManagerFastCalls;
 Result.RebuildCalls:=TextManagerRebuildCalls;
end;

{ TTextManager }

constructor TTextManager.Create;
begin
  FSave := PCollection.Create(1);
  FTexts := PCollection.Create(1);
  FValues := PCollection.Create(1);
  FTextBitmaps := TTwgBitmaps.Create(1);
  oldBmp := TList.Create;
end;

constructor TTextManager.Load(buf: TBufStream);
var ss: TCStrings;
    s: TStrings;
    I:Integer;
begin
  FSave := PCollection.Create(1);
  FTexts := PCollection.Create(1);
  FTextBitmaps := TTwgBitmaps.Create(1);
  oldBmp := TList.Create;

{  ss := TCStrings(buf.get);
  s := ss.GetStrings;}
  FValues := PCollection(buf.Get);
 {
  FValues.Assign(s);
  s.free;
  ss.free;
}
  ss := TCStrings(buf.get);
  s := ss.GetStrings;
  FVars := TStringList.Create;
  FVars.Assign(s);
//  WriteS(['Load.FVars=',FValues.Count,' ',FVars.Count,'---------------------------------------------']);
  For I:=0 to FVars.Count-1 do begin
//    WriteMsg([I,FVars[I]]);
   // WriteIN(['Index=',I,FVars.Count,FVars[I],' ',TTextParams(FValues[I]).FValue]);
  end;
  s.free;
  ss.free;
  //
end;

procedure TTextManager.Store(buf: TBufStream);
var sl: TStringList;
    ss: TCStrings;
begin
  ss := TCStrings.Create(1);
  sl := nil;
  try
    buf.Put(FValues);
{   ss.InsertStrings(FValues);
    buf.Put(ss);}
   // имена надписей - из надписей знака (FTexts); точка еще не построена по
   // библиотеке знаков (FTexts пуст после Load) - имена, прочитанные Load (FVars)
    if (FTexts.Count = 0) and (FVars <> nil) then
      ss.InsertStrings(FVars)
    else begin
      sl := InitSL;
      ss.InsertStrings(sl);
    end;
    buf.Put(ss);
  finally
    sl.Free;
    ss.free;
  end;
end;

destructor TTextManager.Destroy;
var I:Integer;
begin
(*  For I:=0 to FValues.Count-1 do begin
   WriteS([I,FValues.Count,'=',TTextParams(FValues[I]).FValue,'=']);
   TObject(FValues[I]).Free;
   WriteS([I,FValues.Count]);
  end;
*)
//  WriteIn(['FValues.Count',FValues.Count,' ',FTexts.Count]);
   For I:=0 to FValues.Count-1 do begin
//    WriteIn(['I=',I]);
//    WriteIn(['Name>Value',I,TDWG_Text(FTexts[I]).FName,TTextParams(FValues[I]).FValue]);
   end;

   FValues.Free;
//  WriteS(['Free']);
//  WriteS(['end']);
  FSave.Free;

 FreeAndNil(FTextBitmaps);
// BLOCK_DEBUG:=True;
// BLOCK_DEBUG:=False;
  FTexts.DeleteAll;
  FTexts.free;
  If FVars<>nil then FVars.Free;
  oldBmp.Free;
end;

procedure TTextManager.ClearTextBitmaps;
var I: Integer;
begin
  if FTextBitmaps = nil then Exit;
  FTextBitmaps.FreeAll;
end;

procedure TTextManager.BuildTextBitmaps;
var I: Integer;
    B: TTwgBitmap;
begin
  if (FTexts = nil) or (FTextBitmaps = nil) then Exit;
  ClearTextBitmaps;
  for I := 0 to FTexts.Count - 1 do
  begin
    B := TTwgBitmap.Create(TDWG_Text(FTexts[I]));
    FTextBitmaps.Insert(B);
    TDWG_Text(FTexts[I]).TextBitmap := B;
  end;
end;

procedure TTextManager.EnsureTextBitmapsSize;
var I: Integer;
begin
  if (FTexts = nil) or (FTextBitmaps = nil) then Exit;

  while FTextBitmaps.Count > FTexts.Count do
  begin
    I := FTextBitmaps.Count - 1;
    if TObject(FTextBitmaps[I]) <> nil then
      TObject(FTextBitmaps[I]).Free;
    FTextBitmaps.AtDelete(I);
  end;

  while FTextBitmaps.Count < FTexts.Count do
    FTextBitmaps.Insert(TTwgBitmap.Create(TDWG_Text(FTexts[FTextBitmaps.Count])));
end;

procedure TTextManager.UpdateTextBitmaps;
var I: Integer;
begin
  if (FTexts = nil) or (FTextBitmaps = nil) then Exit;
  EnsureTextBitmapsSize;
  for I := 0 to FTexts.Count - 1 do
    TDWG_Text(FTexts[I]).TextBitmap := TTwgBitmap(FTextBitmaps[I]);
end;

procedure TTextManager.SetZnaks(znaks: PCollection);
var
 Tick: Int64;
begin
 if TextManagerUpdateProfileEnabled then Tick:=TStopwatch.GetTimeStamp;
  FTexts.DeleteAll;FTexts.Free;
  FTexts := CreateTexts(znaks);
 if TextManagerUpdateProfileEnabled then begin
  Inc(TextManagerCreateTextsTicks,TStopwatch.GetTimeStamp-Tick);
  Tick:=TStopwatch.GetTimeStamp;
 end;
  BuildTextBitmaps;
 if TextManagerUpdateProfileEnabled then begin
  Inc(TextManagerBuildBitmapsTicks,TStopwatch.GetTimeStamp-Tick);
  Tick:=TStopwatch.GetTimeStamp;
 end;
  if FVars <> nil then
  begin
    AfterLoad(znaks);
    if TextManagerUpdateProfileEnabled then
     Inc(TextManagerAfterLoadTicks,TStopwatch.GetTimeStamp-Tick);
    exit;
  end;
end;

procedure TTextManager.Update(znaks: PCollection);
var col: PCollection;
    tmp: PCollection;
          function SameTextSchema: boolean;
          var I: Integer;
              J: Integer;
              TextIndex: Integer;
              Sign: TPoint_Sign;
              Meth: TMeth;
          begin
           Result:=False;
           if FValues.Count<>FTexts.Count then exit;
           TextIndex:=0;
           for I:=0 to znaks.Count-1 do begin
            Sign:=znaks[I];
            for J:=0 to Sign.MethodCol.Count-1 do begin
             Meth:=Sign.MethodCol[J];
             if Meth.MT<>m_Text then continue;
             if TextIndex>=FTexts.Count then exit;
             if AnsiCompareText(TDWG_Text(FTexts[TextIndex]).FName,
                                TDWG_Text(Meth.PT).FName)<>0 then exit;
             Inc(TextIndex);
            end;
           end;
           Result:=TextIndex=FTexts.Count;
          end;
          procedure ReplaceTexts;
          var I: Integer;
              J: Integer;
              Sign: TPoint_Sign;
              Meth: TMeth;
          begin
           FTexts.DeleteAll;
           for I:=0 to znaks.Count-1 do begin
            Sign:=znaks[I];
            for J:=0 to Sign.MethodCol.Count-1 do begin
             Meth:=Sign.MethodCol[J];
             if Meth.MT=m_Text then FTexts.Insert(Meth.PT);
            end;
           end;
          end;
          function xxx(const s: AnsiString): boolean;
          var j, i: integer;
          begin
            result := false;
            for j := 0 to FTexts.Count - 1 do
              if ansicomparetext(TDWG_Text(FTexts[j]).FName, s) = 0 then
              begin
                col.insert(FValues[j]);
                result := true;
                exit;
              end;
          end;

var i, j, k: integer;
    txt, txt2: TDWG_Text;
    s: AnsiString;
    p: pcollection;
    oldvalcount: integer;
    indlist: TList;
    b: byte;
    Tick: Int64;
    SameSchema: Boolean;
begin
  if TextManagerUpdateProfileEnabled then Inc(TextManagerUpdateCalls);
  if FTexts.Count>0 then begin
   if TextManagerUpdateProfileEnabled then Tick:=TStopwatch.GetTimeStamp;
   SameSchema:=SameTextSchema;
   if TextManagerUpdateProfileEnabled then
    Inc(TextManagerSchemaTicks,TStopwatch.GetTimeStamp-Tick);
   if SameSchema then begin
    if TextManagerUpdateProfileEnabled then begin
     Inc(TextManagerFastCalls);
     Tick:=TStopwatch.GetTimeStamp;
    end;
    ReplaceTexts;
    if TextManagerUpdateProfileEnabled then
     Inc(TextManagerReplaceTicks,TStopwatch.GetTimeStamp-Tick);
    exit;
   end;
  end;
  if FTexts.Count = 0 then
  begin
    if TextManagerUpdateProfileEnabled then Inc(TextManagerInitialCalls);
    SetZnaks(znaks);
    exit;
  end;
  if TextManagerUpdateProfileEnabled then begin
   Inc(TextManagerRebuildCalls);
   Tick:=TStopwatch.GetTimeStamp;
  end;
  oldvalcount := FValues.count;
  tmp := CreateTexts(znaks);
  col := PCollection.Create(1);
  indlist := TList.Create;
  try
    for i := 0 to tmp.Count - 1 do
    begin
      if not xxx(TDWG_Text(tmp[i]).FName) then
      begin
        if i < oldvalcount then
        begin
          if (i < FValues.Count) then col.insert(FValues[i]);
        end
        else
        begin
          indlist.Add(pointer(i));
        end;
      end;
    end;
    for j := 0 to indlist.Count - 1 do
    begin
      i := integer(indlist[j]);
      txt2 := TDWG_Text(tmp[i]);
      b := 0;
      if txt2.FUn=1 then b := tpUnderline;
      if txt2.FBl=1 then b := b or tpBold;
      if txt2.Fit=1 then b := b or tpItalic;
      col.Insert(TTextParams.Create(txt2.FText, txt2.FX, txt2.fy, txt2.FAng,
        txt2.FHeight, txt2.FWidth, b, txt2.FTextAlignX,txt2.FTextAlignY, txt2.ShiftX, txt2.ShiftY, txt2.FBg));
    end;
    FTexts.DeleteAll;
//    FTexts.free;
//    FTexts := tmp;
    for i := 0 to tmp.Count - 1 do
      FTexts.Insert(tmp[i]);

    i := 0;
    while i < FValues.Count do
    begin
      if col.IndexOf(FValues[i]) <> - 1 then
      begin
        FValues.Delete(FValues[i]);
        continue;
      end;
      inc(i);
    end;
    FValues.free;
    FValues := col;

  //  UpdateTextBitmaps;
  finally
    indlist.free;
    tmp.deleteall;
    tmp.free;
  end;
  if TextManagerUpdateProfileEnabled then
   Inc(TextManagerRebuildTicks,TStopwatch.GetTimeStamp-Tick);
end;


{ âûçîâ äèàëîãà äëÿ çàïîëíåíèÿ àòðèáóòîâ }

(*function TTextManager.SetTexts(MAINFORM: TFORM;X,Y,Z:Double;UseCoord:boolean=False;TwgForm_:Pointer = nil): boolean;
var sl: TStringList;
    i: integer;
begin
  with TVarSetDlg.Create(MAINFORM) do
  begin
   TwgForm:=TwgForm_;
   UpdateResults:=Self.UpdateResults;
    try
      sl := InitSL;
      result := execute(sl, FValues, FTEXTS,X,Y,Z,UseCoord, TwgForm_);
    finally
      free;
      sl.free;
    end;
  end;
end;
*)

// диалог атрибутов (TTextManager.SetTexts старой программы)
procedure TTextManager.SetTexts(MainForm: TObject; X, Y, Z: Double; UseCoord: Boolean; TwgForm_: Pointer; const Done: TTextsDone);
{$IFNDEF GMF_READER}
var Dlg: TVarSetDlg;
    SL: TStringList;
    Owner_: TComponent;
{$ENDIF}
begin
{$IFNDEF GMF_READER}
 if MainForm is TComponent then Owner_ := TComponent(MainForm) else Owner_ := Application.MainForm;
 Dlg := TVarSetDlg.Create(Owner_);
 Dlg.UpdateResults := UpdateResults;
 SL := InitSL;
 try
  Dlg.Execute_Old(SL, FValues, FTexts, X, Y, Z, UseCoord, TForm2(TwgForm_), Done);
 finally
  SL.Free;
 end;
{$ENDIF}
// GMF_READER: читатель GMF не показывает диалогов
end;

// диалог атрибутов знака точки в форме по режиму (TTextManager.SetTexts2)
procedure TTextManager.SetTexts2(TwgForm_: Pointer; Point_: Pointer; EditMode: Boolean; Mode: Byte; const Done: TTextsDone);
{$IFNDEF GMF_READER}
var Dlg: TVarSetDlg;
{$ENDIF}
begin
{$IFNDEF GMF_READER}
 Dlg := GlobalVarSetDlgClass.Create(Application.MainForm);
 Dlg.UpdateResults := UpdateResults;
 Dlg.Execute(TForm2(TwgForm_), TPointDot(Point_), EditMode, Mode, Done);
{$ENDIF}
// GMF_READER: читатель GMF не показывает диалогов
end;

function TTextManager.InitSL: TStringList;
var i: integer;
begin
  result := TStringList.Create;
  for i := 0 to FTexts.Count - 1 do
    result.Add(TDwg_text(FTexts[i]).FName);
end;

procedure TTextManager.AfterLoad(znaks: PCollection);
var
 I: Integer;
 K: Integer;
 Col: PCollection;
 OldValues: PCollection;
 Reused: array of Boolean;
begin
 if (FVars.Count=FTexts.Count) and (FValues.Count=FTexts.Count) then begin
  I:=0;
  while (I<FTexts.Count) and
        (AnsiCompareText(FVars[I],TDWG_Text(FTexts[I]).FName)=0) do Inc(I);
  if I=FTexts.Count then begin
   FVars.Free;
   FVars:=nil;
   Exit;
  end;
 end;
//
 OldValues:=FValues;
 SetLength(Reused,OldValues.Count);
 Col:=PCollection.Create(1);
 try
  for I:=0 to FTexts.Count-1 do begin
   if (I<FVars.Count) and
      (AnsiCompareText(FVars[I],TDWG_Text(FTexts[I]).FName)=0) then K:=I
   else K:=FVars.IndexOf(TDWG_Text(FTexts[I]).FName);
   if (K>=0) and (K<OldValues.Count) then begin
    Col.Insert(OldValues[K]);
    Reused[K]:=True;
   end else if I<OldValues.Count then begin
    Col.Insert(OldValues[I]);
    Reused[I]:=True;
   end else
    Col.Insert(TTextParams.Create('',0,0,0,-1,-1,0,0,0,0,0,False));
  end;
 finally
  for I:=OldValues.Count-1 downto 0 do
   if Reused[I] then OldValues.AtDelete(I);
  OldValues.Free;
  FValues:=Col;
  FVars.Free;
  FVars:=nil;
 end;
end;

function TTextManager.CreateTexts(znaks: PCollection): PCollection;
var
 I: Integer;
 J: Integer;
 P: TPoint_Sign;
 M: TMeth;
 B: Byte;
begin
 Result:=PCollection.Create(1);
 try
  for I:=0 to znaks.Count-1 do begin
   P:=znaks[I];
   for J:=0 to P.MethodCol.Count-1 do begin
    M:=P.MethodCol[J];
    if M.MT=m_Text then begin
     Result.Insert(M.PT);
     if FVars=nil then with TDWG_Text(M.PT) do begin
      B:=0;
      if FUn=1 then B:=tpUnderline;
      if Fit=1 then B:=B or tpItalic;
      if FBl=1 then B:=B or tpBold;
      FValues.Insert(TTextParams.Create(FText,FX,FY,FAng,FHeight,FWidth,
       B,FTextAlignX,FTextAlignY,ShiftX,ShiftY,FBg));
     end;
    end;
   end;
  end;
 except
  Result.Free;
  raise;
 end;
end;

procedure TTextManager.UpdateText;
var i: integer;
  b: byte;
  tp: TTextParams;
begin
  FSave.freeall;
  oldBmp.Clear;
  for i := 0 to FTexts.count - 1  do
  begin
   with TDwg_text(FTexts[i]) do
   begin
//     write(' u:', fname);
//     write(' v:', fx:8:3, fy:8:3);

    b := 0;
    if FUn=1 then b := 4;
    if Fit=1 then b := b or 2;
    if FBl=1 then b := b or 1;
//!!!!!!!!@@@@@@@@@
     tp := TTextParams.Create(FText, FX, FY, FAng, FHeight, FWidth, b, FTextAlignX, FTextAlignY, ShiftX,ShiftY, FBg);
     FSave.Insert(tp);
     tp := TTextParams(FValues[i]);
    //
     oldBmp.Add(TDwg_text(FTexts[i]).TextBitmap);
     FText := tp.FValue;
    // If FText = '2.43' then
     FAng := tp.FUgol;
     FX :=  tp.FDx;
     Fy :=  tp.FDy;
     if tp.FH = - 1 then
     begin
       tp.FH := FHeight;
       tp.FW := FWidth;
     end;
     FHeight :=  tp.FH;
     FWidth :=  tp.FW;
     FUn := ord((tp.FAttr and tpUnderline) <> 0);
     Fbl := ord((tp.FAttr and tpBold) <> 0);
     Fit := ord((tp.FAttr and tpItalic) <> 0);
     If tp.tmFontIndex<>-1 then fFontIndex:=tp.tmFontIndex else fFontIndex:=oldFontIndex;
     If tp.AlignX<>-1 then begin
      FTextAlignX:=tp.AlignX; FTextAlignY:=tp.AlignY;
     end;
     ShiftX:=tp.ShiftX;
     ShiftY:=tp.ShiftY;
     If BackGround <>0 then begin
      FBg:=BackGround = 2;
     end;
      // TextDirty := True;
//     Writeln('ShiftXY=',ShiftX,' ',ShiftY);
     //Writeln('FI=',fFontIndex,' ',tp.tmFontIndex,' ',tp.FValue);
   end;
  end;
 UpdateTextBitmaps;
end;

procedure TTextManager.Restore;
var
  i: integer;
  tp: TTextParams;
begin
  for i := 0 to FSave.count - 1  do
  begin
    with TDwg_text(FTexts[i]) do
    begin
       tp := TTextParams(FSave[i]);
       FText := tp.FValue;
       FAng := tp.FUgol;
       FX := tp.FDx;
       Fy := tp.FDy;
       FHeight :=  tp.FH;
       FWidth :=  tp.FW;
       FUn := ord((tp.FAttr and tpUnderline) <> 0);
       Fbl := ord((tp.FAttr and tpBold) <> 0);
       Fit := ord((tp.FAttr and tpItalic) <> 0);
       If tp.tmFontIndex<>-1 then fFontIndex:=tp.tmFontIndex else fFontIndex:=oldFontIndex;
       FTextAlignX := tp.AlignX;
       FTextAlignY := tp.AlignY;
       ShiftX:=tp.ShiftX;
       ShiftY:=tp.ShiftY;
       FBg:=tp.FBg;
       if i < oldBmp.Count then
        TextBitmap := TTwgBitmap(oldBmp[I]);
      // TextDirty := True;
    end;
  end;
  FSave.FreeAll;
end;

function TTextManager.Equal(tm: TTextManager): boolean;
var i: integer;
    tp1, tp2: TTextParams;
begin
  result := false;
  if tm.ftexts.Count <> ftexts.Count then exit;
  if FValues.Count <> tm.FValues.Count then exit;
  for i := 0 to FTexts.count - 1 do
    if FTexts[i] <> tm.ftexts[i] then exit;

  for i := 0 to FValues.count - 1 do
  begin
    tp1 := FValues[i];
    tp2 := tm.FValues[i];
    if (tp1.FValue <> tp2.FValue) or (tp1.FDx <> tp2.FDx)
      or (tp1.FDy <> tp2.FDy) or (tp1.FUgol <> tp2.FUgol)
      or (tp1.FH <> tp2.FH) or (tp1.FW <> tp2.FW)
      or (tp1.Fattr <> tp2.Fattr)
    then exit;
  end;
  result := true;
end;


procedure TTextManager.MoveText(Index: Integer; Dx, Dy: Double);
var TP:TTextParams;DT:TDwg_Text;
begin
 If (Index>FValues.Count-1) or (Index = -1) then raise Exception.Create('?????? ? ??????????? ??????? ??????? (MoveText) :'+IntToStr(Index));
 TP:=FValues[Index];DT:=FTexts[Index];
 TP.fDx:={TP.fDx+}Dx;TP.fDy:={TP.fDy+}Dy;
end;

procedure TTextManager.MoveTextShift(Index, Dx, Dy: Integer);
var TP:TTextParams;
begin
 If (Index>FValues.Count-1) or (Index = -1) then raise Exception.Create('?????? ? ??????????? ??????? ??????? (MoveTextShift) :'+IntToStr(Index));
 TP:=FValues[Index];
 TP.ShiftX:=Dx;TP.ShiftY:=Dy;
end;

function TTextManager.GetFontIndex(F: Pointer): Integer;
var I:Integer;
begin
 Result:=FTexts.IndexOf(F);                  
// If Result = -1 then raise Exception.Create('?????? ? ??????????? ????????? ??????? (GetFontIndex) .?? ??????...');
end;

procedure TTextManager.RotateText(Index: Integer; Angle:Double);
var TP:TTextParams;DT:TDwg_Text;
begin
 If (Index>FValues.Count-1) or (Index = -1) then raise Exception.Create('?????? ? ??????????? ??????? ??????? (RotateText) :'+IntToStr(Index));
 TP:=FValues[Index];DT:=FTexts[Index];
 TP.fUgol:=Angle*180/Pi;
end;

function TTextManager.AttrValue(V: AnsiString): AnsiString;
var DT:TDwg_Text;I,N:Integer;
begin
 Result:='';
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   Result:=TTextParams(FValues[I]).FValue;
   N:=Pos('\',Result);
   If N<>0 then begin
    SetLength(Result,N-1);
   end;
   exit;
  end;
 end;
end;

function TTextManager.SetAttrValue(V, Value: AnsiString): boolean;
var DT:TDwg_Text;I,N:Integer;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCase(V) then begin
   TTextParams(FValues[I]).FValue:=Value;
   DT.TextDirty := True;
   Result:=True;
   exit;
  end else
  If (V = '*') and (I=0) then begin
   TTextParams(FValues[I]).FValue:=Value;
   DT.TextDirty := True;
   Result:=True;
   exit;
  end;
 end;
end;

function TTextManager.SetAttrParams(V: AnsiString;Angle,H,W: Double): boolean;
var DT:TDwg_Text;I,N:Integer;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   TTextParams(FValues[I]).FUgol:=Angle;
   TTextParams(FValues[I]).FH:=H;
   TTextParams(FValues[I]).FW:=W;
   DT.TextDirty := True;
   Result:=True;
   exit;
  end;
 end;
end;

function TTextManager.GetAttrParams(V: AnsiString;var Angle, H,W: Double): boolean;
var DT:TDwg_Text;I,N:Integer;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   Angle:=TTextParams(FValues[I]).FUgol;
   H:=TTextParams(FValues[I]).FH;
   W:=TTextParams(FValues[I]).FW;
   Result:=True;
   exit;
  end;
 end;
end;

constructor TTextManager.CreateAsTextManager(T: TTextManager;Znaks:PCollection);
var
  bs: TBufStream;
  ver:Integer;
begin
  bs := TBufStream.Create;
  try
   ver:=Version;
   Version:=newConsts.VerConst;
    t.Store(bs);
    bs.Position := 0;
    bs.seek(0, soFromBeginning);
    Load(bs);
    Update(Znaks);
  finally
   Version:=Ver;
    bs.Free;
  end;
end;

procedure TTextManager.GetAttrNames(Names: TStrings;Values:TStrings = nil);
var I:Integer;
begin
 For I:=0 to FTexts.Count-1 do begin
  Names.Add(TDwg_Text(FTexts[I]).FName);
  If Values<>nil then Values.Add(TTextParams(FValues[I]).FValue);
 end;
end;

function TTextManager.GetXY(V: AnsiString; var X, Y: Double): boolean;
var I:Integer;DT:TDwg_Text;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   X:=TTextParams(FValues[I]).Fdx;
   Y:=TTextParams(FValues[I]).Fdy;
   Result:=True;Exit;
  end;
 end;
end;

function TTextManager.SetXY(V: AnsiString; X, Y: Double): boolean;
var I:Integer;DT:TDwg_Text;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   TTextParams(FValues[I]).Fdx:=X;
   TTextParams(FValues[I]).Fdy:=Y;
   Result:=True;Exit;
  end;
 end;
end;

procedure TTextManager.StretchText(Index: Integer; XText,YText, X, Y, Ko, Ug: Double);
var DX,DY:Double;TP:TTextParams;DT:TDwg_Text;
    DyF,DxF:single;
    TmpUgol:single;
    OldX,OldY:word;
    OldDX,OldDY:single;
    Dxx,Dyy:Double;
begin
 If (Index>FValues.Count-1) or (Index = -1) then raise Exception.Create('?????? ? ??????????? ??????? ??????? (StrechText) :'+IntToStr(Index));
 TP:=FValues[Index];DT:=FTexts[Index];
 If Ko<0 then begin

 end else begin
 DX:=TP.FW/Ko;DY:=TP.FH/Ko;
  {}
  try
   TmpUgoL:=TP.fUgol*Pi/180+Ug;
    OldDx:=sqrt(sqr(cos(TmpUgol)*DX*Length(TP.FValue))+sqr(sin(TmpUgol)*DX*Length(TP.FValue)));
    Dx:=((TP.fDX*Ko+XText)-X);
    Dy:=((TP.fDY*KO+YText)-Y);
    DxF:=-(Dx*cos(-TmpUgol)+Dy*sin(-TmpUgol));
    DyF:=-(-Dx*sin(-TmpUgol)+Dy*cos(-TmpUgol));
    if Dxf<0 then Dxf:=0.1;
    if Dyf<0 then Dyf:=0.1;
    TP.FH:=DyF/Ko{*10};
  //        if TP.FW=0 then WF:=TP.FH*0.5;
          // Writeln('FW=',TP.FW,' ',OldDx);
           TP.FW:=(Dxf/Length(TP.FValue)/Ko)/(OldDx/(TP.FW/Ko*Length(TP.FValue)));
           Dx:=Dxf;Dy:=Dyf;
  except on EInvalidOp do
   begin
     TP.FH:=1;
     TP.FW:=1;
   end;
  end;
 end;
end;


procedure TTextManager.SetUserParams(FName: AnsiString; H: Double;Style:Integer);
var I:Integer;TP:TTextParams;DT:TDwg_Text;
    Dc:hDc; FUn,FBl,FIt:Integer;
begin
 For I:=0 to FValues.Count-1 do begin
  TP:=FValues[I];
  DT:=FTexts[I];
  If H<>-10000 then begin
  If H=0 then begin
   If not TP.DxfLock then begin TP.FH:=DT.FHeight;TP.FW:=DT.FWidth;end;
  end else begin TP.FH:=H;TP.FW:=TP.FH*0.375; end;
  end;
 // {$IFDEF WIN64}Dc:=GetDc(0);{$ELSE}Dc:=0;{$ENDIF}
  If Style<>-1 then tp.FAttr:=Style else If not TP.DxfLock then begin
    tp.FAttr := 0;
    if DT.FUn=1 then tp.FAttr := tpUnderline;
    if DT.FBl=1 then tp.FAttr := tp.FAttr or tpBold;
    if DT.FIt=1 then tp.FAttr := tp.FAttr or tpItalic;
  end;
  FUn := ord((tp.FAttr and tpUnderline) <> 0);
  Fbl := ord((tp.FAttr and tpBold) <> 0);
  Fit := ord((tp.FAttr and tpItalic) <> 0);
  If FName = '' then begin
   If not TP.DxfLock then TP.tmFontIndex:=-1
  end else begin
   TP.tmFontIndex:=DWGText.FontCol.AddFont(DC, fName, TP.FH, TP.FW, DT.fCharSet, fBl, fIt, fUn);
  end;
//  {$IFDEF WIN64}ReleaseDc(0,Dc);{$ENDIF}
 end;
end;

function TTextManager.SetSysValue(TypeOf:Byte;Value: AnsiString): boolean;
var I:Integer;DT:TDwg_Text;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If DT.fVarType=TVarType(TypeOf) then begin
   TTextParams(FValues[I]).FValue:=Value;
   Result:=True;
   exit;
  end;
 end;
end;

function TTextManager.GetSysValue(TypeOf: Byte): AnsiString;
var I:Integer;DT:TDwg_Text;
begin
 Result:='';
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If DT.fVarType=TVarType(TypeOf) then begin
   Result:=TTextParams(FValues[I]).FValue;
   exit;
  end;
 end;
end;

procedure TTextManager.SetSysSpatialData(X, Y, Z: AnsiString);
var I:Integer;DT:TDwg_Text;
begin
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If DT.fVarType=tt_X then TTextParams(FValues[I]).FValue:=X else
  If DT.fVarType=tt_Y then TTextParams(FValues[I]).FValue:=Y else
  If DT.fVarType=tt_Z then TTextParams(FValues[I]).FValue:=Z;
 end;
end;

function TTextManager.UseAttr(V: AnsiString): boolean;
var I:Integer;DT:TDwg_Text;
begin
 Result:=False;
 For I:=0 to FTexts.Count-1 do begin
  DT:=FTexts[I];
  If AnsiUpperCase(DT.FName)=AnsiUpperCAse(V) then begin
   Result:=True;Exit;
  end;
 end;
end;

{ TTextParams }

constructor TTextParams.Create(const value: AnsiString; const Dx, Dy, Ugol, h,
 w: double; attr: byte; AlX, AlY: single; SX, SY: SmallInt; FBg_: Boolean);
begin
  FValue := value;
  FDx := dx;
  FDy := dy;
  FUgol := Ugol;
  FH := h;
  FW := w;
  FAttr := attr;
  tmFontIndex:=-1;
  AlignX:=AlX;AlignY:=AlY;
  DxfLock:=False;
  ShiftX:=SX;ShiftY:=SY;
  fBg:=fBg_;
//  DxfFontName:='';
end;

constructor TTextParams.Load(buf: TBufStream);
var
  d: double;
  DC:hDc;
begin
  FValue := buf.ReadString;
//  If Length(FValue)>1 then WriteMsg(['=',FValue]);
  if version > 30 then
  begin
    buf.Read(FDx, sizeof(FDx));
    buf.Read(FDy, sizeof(FDy));
    buf.Read(FUgol, sizeof(FUgol));
    buf.Read(FH, sizeof(FH));
    buf.Read(FW, sizeof(FW));
    buf.Read(FAttr, sizeof(FAttr));
    tmFontIndex:=-1;
    If version > 40 then begin
     buf.Read(AlignX, sizeof(AlignX));
     buf.Read(AlignY, sizeof(AlignY));
     buf.Read(DxfLock, sizeOf(Boolean));
      If version > 43 then begin
       buf.Read(ShiftX, sizeof(ShiftX));
       buf.Read(ShiftY, sizeof(ShiftY));
      end;
    { If Version > 41 then begin
      DxfFontName:=buf.ReadString;
     end else DxfFontName:='';}
    end else begin
     AlignX:=-1;AlignY:=-1;
    end;
  end
  else
  begin
    buf.Read(d, sizeof(d));
    FDx := d;
    buf.Read(D, sizeof(D));
    FDy := d;
    buf.Read(d, sizeof(d));
    FUgol := d;
    FH := -1;
    FW := -1;
    FAttr := 0;
  end;
end;

procedure TTextParams.Store(buf: TBufStream);
begin
  buf.WriteString(FValue);
  buf.Write(FDx, sizeof(FDx));
  buf.Write(FDy, sizeof(FDy));
  buf.Write(FUgol, sizeof(FUgol));
//
  buf.write(FH, sizeof(FH));
  buf.write(FW, sizeof(FW));
  buf.write(FAttr, sizeof(FAttr));
//
  buf.Write(AlignX, sizeof(AlignX));  
  buf.Write(AlignY, sizeof(AlignY));
  buf.Write(DxfLock, sizeOf(Boolean));
  buf.Write(ShiftX, sizeof(ShiftX));
  buf.Write(ShiftY, sizeof(ShiftY));
//
//  buf.WriteString(DxfFontName);
end;

destructor TTextParams.Destroy;
begin
// inherited Destroy;
 FValue:='';
end;

function TTextParams.TextAlign: Byte;
begin
 If (AlignX = 0) and (AlignY = 0) then Result:= 1 else
 If (AlignX = 0) and (AlignY = 0.5) then Result:= 2 else
 If (AlignX = 0) and (AlignY = 1) then Result:= 3 else
 If (AlignX = 0.5) and (AlignY = 0) then Result:= 5 else
 If (AlignX = 0.5) and (AlignY = 0.5) then Result:= 6 else
 If (AlignX = 0.5) and (AlignY = 1) then Result:= 7 else
 If (AlignX = 1) and (AlignY = 0) then Result:= 9 else
 If (AlignX = 1) and (AlignY = 0.5) then Result:= 10 else
 If (AlignX = 1) and (AlignY = 1) then Result:= 11;
{ Add('влево-основание');
 Add('влево-низ');
 Add('влево-центр');
 Add('влево-верх');
 Add('центр-основание');
 Add('центр-низ');
 Add('центр-центр');
 Add('центр-верх');
 Add('вправо-основание');
 Add('вправо-низ');
 Add('вправо-центр');
 Add('вправо-верх');
}
end;

initialization
end.

