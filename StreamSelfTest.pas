unit StreamSelfTest;

// Проверка записи/чтения объектов карты через поток в памяти (TBufStream.Create
// - TMemoryStream), без файла.
// Для каждого объекта: Put (Store) в поток, Get (Load) из начала потока, затем
// повторный Put прочитанного объекта во второй поток. Ошибка, если:
//  - Get прочитал не столько байт, сколько записал Put (Load и Store расходятся
//    по набору или размеру полей);
//  - повторная запись отличается от первой (поле прочитано не туда или не так);
//  - исключение в Store или Load.
// Проверяются заголовок карты (StoreAbout/LoadAbout), ветви, контуры, объекты
// Any (точки, тексты), блоки, таблица слоев и шрифты карты. Вся карта целиком
// (Put(TwgForm)) не проверяется: TForm1.Load меняет глобальное состояние
// программы (Selector.GTwgForm, шрифты, классификатор).
// Итог - в журнал (WriteIn): по классам число проверенных и ошибок, первые
// ошибки подробно.

interface

uses System.SysUtils, System.Classes, Collect, WPTForm2;

// возвращает число ошибок; Log (если задан) - строки отчета
function RunStreamSelfTest(Form: TForm2; Log: TStrings = nil): Integer;

implementation

uses
  System.Generics.Collections, newConsts, newForm0, WPTForm0, Writer, ObjBlockList, newBlock, newResource;

const
  MaxDetails = 30; // подробно - первые ошибки

type
  // записанный объект: класс, границы его Store в потоке, вложенность
  TTraceRec = record
    Cls: string;
    StartPos, EndPos: Int64;
    Depth: Integer;
  end;

function RunStreamSelfTest(Form: TForm2; Log: TStrings): Integer;
var
  Stat: TDictionary<string, TPair<Integer, Integer>>; // класс -> (проверено, ошибок)
  Details: Integer;
  SaveVersion, SaveClassVersion: Integer;
procedure Report(const S: string);
begin
 WriteIn([S]);
 if Log <> nil then Log.Add(S);
end;
procedure Count(const Cls: string; Failed: Boolean);
var P: TPair<Integer, Integer>;
begin
 if not Stat.TryGetValue(Cls, P) then P := TPair<Integer, Integer>.Create(0, 0);
 P.Key := P.Key + 1;
 if Failed then P.Value := P.Value + 1;
 Stat.AddOrSetValue(Cls, P);
 if Failed then Inc(Result);
end;
procedure Fail(const What: string);
begin
 Inc(Details);
 if Details <= MaxDetails then Report('  FAIL ' + What);
end;
// содержимое потока - байты
function StreamBytes(B: TBufStream): TBytes;
var P: Int64;
begin
 P := B.Position;
 SetLength(Result, B.Size);
 B.Position := 0;
 if Length(Result) > 0 then B.Read(Result[0], Length(Result));
 B.Position := P;
end;
// байты потока около смещения Ofs (16-ричные)
function HexAround(const A: TBytes; Ofs: Integer): string;
var K: Integer;
begin
 Result := '';
 for K := Ofs - 8 to Ofs + 8 do
  if (K >= 0) and (K < Length(A)) then begin
   if K = Ofs then Result := Result + '[' + IntToHex(A[K], 2) + ']' else Result := Result + ' ' + IntToHex(A[K], 2);
  end;
end;
// самый вложенный записанный объект, внутри которого лежит смещение Ofs
function Innermost(const Trace: TList<TTraceRec>; Ofs: Int64): string;
var K, Best: Integer;
begin
 Best := -1;
 for K := 0 to Trace.Count - 1 do
  if (Trace[K].StartPos <= Ofs) and (Ofs < Trace[K].EndPos) then
   if (Best < 0) or (Trace[K].Depth > Trace[Best].Depth) then Best := K;
 if Best < 0 then exit('-');
 with Trace[Best] do
  Result := Format('%s (глубина %d, Store с %d по %d, байт %d от начала объекта)', [Cls, Depth, StartPos, EndPos, Ofs - StartPos]);
end;
procedure TestObject(Obj: TTwgObject; const Where: string);
var B1, B2: TBufStream;
    Obj2: TTwgObject;
    W, R: Int64;
    A1, A2: TBytes;
    Cls: string;
    I: Integer;
    T1, T2: TList<TTraceRec>;
begin
 if Obj = nil then exit;
 Cls := Obj.ClassName;
 B1 := TBufStream.Create;
 B2 := TBufStream.Create;
 T1 := TList<TTraceRec>.Create;
 T2 := TList<TTraceRec>.Create;
 Obj2 := nil;
// отметка записанных объектов (для поиска места расхождения)
 PutTrace :=
  procedure(Stream: TBufStream; O: TTwgObject; StartPos, EndPos: Int64; Depth: Integer)
  var Rec: TTraceRec;
  begin
   Rec.Cls := O.ClassName; Rec.StartPos := StartPos; Rec.EndPos := EndPos; Rec.Depth := Depth;
   if Stream = B1 then T1.Add(Rec) else if Stream = B2 then T2.Add(Rec);
  end;
 try
  B1.Selector := Form.Selector;
  B2.Selector := Form.Selector;
  try
   B1.Put(Obj);
  except
   on E: Exception do begin Count(Cls, True); Fail(Format('%s %s: Store - %s', [Cls, Where, E.Message])); exit; end;
  end;
  W := B1.Position;
  B1.Position := 0;
  try
   Obj2 := B1.Get;
  except
   on E: Exception do begin Count(Cls, True); Fail(Format('%s %s: Load - %s (записано %d байт, прочитано %d)', [Cls, Where, E.Message, W, B1.Position])); exit; end;
  end;
  R := B1.Position;
  if R <> W then begin
   Count(Cls, True);
   Fail(Format('%s %s: записано %d байт, прочитано %d', [Cls, Where, W, R]));
   exit;
  end;
  try
   B2.Put(Obj2);
  except
   on E: Exception do begin Count(Cls, True); Fail(Format('%s %s: повторный Store - %s', [Cls, Where, E.Message])); exit; end;
  end;
  A1 := StreamBytes(B1);
  A2 := StreamBytes(B2);
 // блок: Load перестраивает контуры (TLot.SetFromTwig - другое начало и
 // направление обхода тех же ветвей), повторная запись отличается номерами -
 // только размер
  if (Obj is TGeoBlock) and (Length(A1) = Length(A2)) then begin
   Count(Cls, False);
   exit;
  end;
  if (Length(A1) <> Length(A2)) or ((Length(A1) > 0) and not CompareMem(@A1[0], @A2[0], Length(A1))) then begin
   I := 0;
   while (I < Length(A1)) and (I < Length(A2)) and (A1[I] = A2[I]) do Inc(I);
   Count(Cls, True);
   Fail(Format('%s %s: повторная запись отличается (байт %d из %d/%d)', [Cls, Where, I, Length(A1), Length(A2)]));
   if Details <= MaxDetails then begin
    Report('       в записи 1: ' + Innermost(T1, I));
    Report('       в записи 2: ' + Innermost(T2, I));
    Report('       байты 1: ' + HexAround(A1, I));
    Report('       байты 2: ' + HexAround(A2, I));
   end;
   exit;
  end;
  Count(Cls, False);
 finally
  PutTrace := nil;
  try Obj2.Free; except end;
  B1.Free;
  B2.Free;
  T1.Free;
  T2.Free;
 end;
end;
// заголовок карты: StoreAbout / LoadAbout
procedure TestAbout;
var B: TBufStream;
    A: EcAboutObject;
    W: Int64;
begin
 B := TBufStream.Create;
 try
  try
   StoreAbout(Form.About, B);
   W := B.Position;
   B.Position := 0;
   LoadAbout(A, B);
   if B.Position <> W then begin
    Count('About', True);
    Fail(Format('About: записано %d байт, прочитано %d', [W, B.Position]));
   end else
   if (A.MyName <> Form.About.MyName) or (Abs(A.XMin - Form.About.XMin) > 1e-6) or (Abs(A.YMax - Form.About.YMax) > 1e-6) then begin
    Count('About', True);
    Fail('About: прочитанные значения отличаются от записанных');
   end else
    Count('About', False);
  except
   on E: Exception do begin Count('About', True); Fail('About: ' + E.Message); end;
  end;
 finally
  B.Free;
 end;
end;
var I: Integer;
    W: Byte;
    Keys: TArray<string>;
begin
 Result := 0;
 Details := 0;
 if (Form = nil) or (Form.Twigs = nil) then exit;
 Stat := TDictionary<string, TPair<Integer, Integer>>.Create;
// Load проверяет версию формата: при чтении - текущая (как у только что записанного)
 SaveVersion := newConsts.Version;
 newConsts.Version := VerConst;
// слои (TResource) читаются по версии таблицы слоев - тоже текущая
 SaveClassVersion := newResource.ClassVersion;
 newResource.ClassVersion := ClassVerConst;
 try
  Report('=== Проверка записи/чтения через поток в памяти ===========================================================');
  TestAbout;
  with Form.Twigs do begin
   for I := 1 to TwigsCount - 1 do TestObject(TAt(I), 'ветвь #' + IntToStr(I));
   for I := 0 to LotsCount - 1 do TestObject(LAt(I), 'контур #' + IntToStr(I));
   for I := 0 to AnyCount - 1 do TestObject(AAt(I, W), 'объект #' + IntToStr(I) + ' (тип ' + IntToStr(W) + ')');
   if BlockList <> nil then
   for I := 0 to BlockList.Count - 1 do TestObject(BlockList[I], 'блок #' + IntToStr(I));
  end;
  TestObject(Form.LayerTable, 'таблица слоев');
  TestObject(Form.FontColEx, 'шрифты карты');
  Keys := Stat.Keys.ToArray;
  TArray.Sort<string>(Keys);
  for I := 0 to High(Keys) do
   Report(Format('%-20s проверено %6d  ошибок %6d', [Keys[I], Stat[Keys[I]].Key, Stat[Keys[I]].Value]));
  Report(Format('=== Итого ошибок: %d ===', [Result]));
 finally
  newConsts.Version := SaveVersion;
  newResource.ClassVersion := SaveClassVersion;
  Stat.Free;
 end;
end;

end.
