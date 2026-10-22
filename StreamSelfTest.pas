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
// сохранение карты с проверкой: сначала RunStreamSelfTest; без ошибок - запись
// в FileName (.gmf), затем копия успешно сохраненного файла с расширением
// .gm3. Log - отчет проверки и итог сохранения. True - сохранено
function SaveGmfChecked(Form: TForm2; const FileName: string; Log: TStrings): Boolean;

implementation

uses
  System.Generics.Collections, System.IOUtils, System.Math, newConsts, newForm0, WPTForm0, Writer, ObjBlockList, newBlock, newResource,
  ECLot, WpTwigs, TwgColle;

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
  Notes: Integer; // блоки, нормализованные при чтении (не ошибка)
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
// размер записи объекта (Put в поток в памяти); -1 - исключение
function PutSize(Form: TForm2; Obj: TTwgObject): Int64;
var B: TBufStream;
begin
 B := TBufStream.Create;
 try
  B.Selector := Form.Selector;
  try
   B.Put(Obj);
   Result := B.Position;
  except
   Result := -1;
  end;
 finally
  B.Free;
 end;
end;
// все записанные объекты, внутри которых лежит смещение Ofs, - от внешнего к
// вложенному: 'TGeoBlock > TForm2 > ... > TDot'
function Chain(const Trace: TList<TTraceRec>; Ofs: Int64): string;
var K, D, Best: Integer;
begin
 Result := '';
 for D := 0 to 30 do begin
  Best := -1;
  for K := 0 to Trace.Count - 1 do
   if (Trace[K].Depth = D) and (Trace[K].StartPos <= Ofs) and (Ofs < Trace[K].EndPos) then Best := K;
  if Best < 0 then continue;
  if Result <> '' then Result := Result + ' > ';
  Result := Result + Trace[Best].Cls;
 end;
end;
// номера ветвей контура и число точек каждой ветви: '-2(5) 1(2) ...'
function LotTwigs(Form: TForm2; Lot: TLot): string;
var K, N: Integer;
    Tw: TTwig;
begin
 Result := '';
 for K := 0 to Lot.Coord.Count - 1 do begin
  N := TLong(Lot.Coord[K]).Num;
  Tw := nil;
  if (Abs(N) > 0) and (Abs(N) < Form.Twigs.TwigsCount) then Tw := TTwig(Form.Twigs.TAt(Abs(N)));
  if Tw <> nil then Result := Result + Format('%d(%d) ', [N, Tw.Coord.Count]) else Result := Result + Format('%d(?) ', [N]);
 end;
end;
// блок после записи и чтения отличается размером: что изменилось во вложенной
// карте блока - число ветвей, контуров, объектов; контуры с другим числом
// ветвей (Load перестраивает контуры - SetFromTwig) и ветви с другим числом точек
procedure BlockDiff(B1, B2: TGeoBlock);
var F1, F2: TForm2;
    K, Shown: Integer;
    L1, L2: TLot;
begin
 F1 := B1.TwgForm;
 F2 := B2.TwgForm;
 if (F1 = nil) or (F2 = nil) then exit;
 Report(Format('       блок "%s": ветвей %d/%d, контуров %d/%d, объектов %d/%d', [B1.Name,
  F1.Twigs.TwigsCount, F2.Twigs.TwigsCount, F1.Twigs.LotsCount, F2.Twigs.LotsCount, F1.Twigs.AnyCount, F2.Twigs.AnyCount]));
 Shown := 0;
 for K := 0 to Min(F1.Twigs.LotsCount, F2.Twigs.LotsCount) - 1 do begin
  L1 := TLot(F1.Twigs.LAt(K));
  L2 := TLot(F2.Twigs.LAt(K));
  if L1.Coord.Count = L2.Coord.Count then continue;
  Inc(Shown);
  if Shown > 5 then break;
  Report(Format('       контур #%d (TypeLot %d): ветвей %d -> %d', [K, L1.TypeLot, L1.Coord.Count, L2.Coord.Count]));
  Report('         до:    ' + LotTwigs(F1, L1));
  Report('         после: ' + LotTwigs(F2, L2));
 end;
 Shown := 0;
 for K := 1 to Min(F1.Twigs.TwigsCount, F2.Twigs.TwigsCount) - 1 do
  if TTwig(F1.Twigs.TAt(K)).Coord.Count <> TTwig(F2.Twigs.TAt(K)).Coord.Count then begin
   Inc(Shown);
   if Shown > 5 then break;
   Report(Format('       ветвь #%d: точек %d -> %d, Closed %d', [K, TTwig(F1.Twigs.TAt(K)).Coord.Count,
    TTwig(F2.Twigs.TAt(K)).Coord.Count, TTwig(F1.Twigs.TAt(K)).Closed]));
  end;
// размер записи ветвей и контуров: какие объекты блока изменились при чтении
 Shown := 0;
 for K := 1 to Min(F1.Twigs.TwigsCount, F2.Twigs.TwigsCount) - 1 do
  if PutSize(F1, TTwgObject(F1.Twigs.TAt(K))) <> PutSize(F2, TTwgObject(F2.Twigs.TAt(K))) then begin
   Inc(Shown);
   if Shown > 5 then break;
   Report(Format('       ветвь #%d %s: запись %d -> %d байт, точек %d, ArcView %d/%d', [K, TTwig(F1.Twigs.TAt(K)).ClassName,
    PutSize(F1, TTwgObject(F1.Twigs.TAt(K))), PutSize(F2, TTwgObject(F2.Twigs.TAt(K))), TTwig(F1.Twigs.TAt(K)).Coord.Count,
    TTwig(F1.Twigs.TAt(K)).ArcView, TTwig(F2.Twigs.TAt(K)).ArcView]));
  end;
 Shown := 0;
 for K := 0 to Min(F1.Twigs.LotsCount, F2.Twigs.LotsCount) - 1 do
  if PutSize(F1, TTwgObject(F1.Twigs.LAt(K))) <> PutSize(F2, TTwgObject(F2.Twigs.LAt(K))) then begin
   Inc(Shown);
   if Shown > 5 then break;
   Report(Format('       контур #%d: запись %d -> %d байт', [K, PutSize(F1, TTwgObject(F1.Twigs.LAt(K))), PutSize(F2, TTwgObject(F2.Twigs.LAt(K)))]));
  end;
end;
procedure TestObject(Obj: TTwgObject; const Where: string);
var B1, B2, B3: TBufStream;
    Obj2, Obj3: TTwgObject;
    W, R: Int64;
    A1, A2, A3: TBytes;
    Cls: string;
    I: Integer;
    T1, T2: TList<TTraceRec>;
begin
 if Obj = nil then exit;
 Cls := Obj.ClassName;
 B1 := TBufStream.Create;
 B2 := TBufStream.Create;
 B3 := nil;
 T1 := TList<TTraceRec>.Create;
 T2 := TList<TTraceRec>.Create;
 Obj2 := nil;
 Obj3 := nil;
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
 // блок: Load нормализует вложенную карту - перестраивает контуры
 // (TLot.SetFromTwig: другое начало и направление обхода, лишние ветви
 // выбрасываются) и пересчитывает дуги дыр штриховки (TTwigARC.ArcCreate -
 // число точек по текущему Quants_For_Arcs). Проверяется, что нормализованный
 // блок записывается и читается без изменений: третья запись = второй (по
 // размеру - контуры могут снова начаться с другой ветви)
  if Obj is TGeoBlock then begin
   if Length(A1) <> Length(A2) then begin
    B2.Position := 0;
    try
     Obj3 := B2.Get;
     B3 := TBufStream.Create;
     B3.Selector := Form.Selector;
     B3.Put(Obj3);
     A3 := StreamBytes(B3);
    except
     on E: Exception do begin Count(Cls, True); Fail(Format('%s %s: третье чтение/запись - %s', [Cls, Where, E.Message])); exit; end;
    end;
    if Length(A3) <> Length(A2) then begin
     Count(Cls, True);
     Fail(Format('%s %s: нормализованный блок записывается по-разному (%d/%d байт)', [Cls, Where, Length(A2), Length(A3)]));
     if Details <= MaxDetails then BlockDiff(TGeoBlock(Obj2), TGeoBlock(Obj3));
     exit;
    end;
    Inc(Notes);
    if Notes <= MaxDetails then
     Report(Format('  блок %s "%s" нормализован при чтении: %d -> %d байт', [Where, TGeoBlock(Obj).Name, Length(A1), Length(A2)]));
   end;
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
    Report('       цепочка: ' + Chain(T1, I));
   end;
   exit;
  end;
  Count(Cls, False);
 finally
  PutTrace := nil;
  try Obj2.Free; except end;
  try Obj3.Free; except end;
  B3.Free;
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
 Notes := 0;
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
   for I := 0 to BlockList.Count - 1 do TestObject(BlockList[I], 'блок #' + {TGeoBlock(BlockList[I]).Name} IntToStr(I) + ' из: ' +IntToStr(BlockList.Count) );
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

function SaveGmfChecked(Form: TForm2; const FileName: string; Log: TStrings): Boolean;
var Buf: TBufStream;
    Errors: Integer;
    CopyName, TmpName: string;
procedure Report(const S: string);
begin
 WriteIn([S]);
 if Log <> nil then Log.Add(S);
end;
begin
 Result := False;
 if Form = nil then exit;
 Errors := RunStreamSelfTest(Form, Log);
 if Errors > 0 then begin
  Report(Format('Файл не сохранен: при проверке ошибок %d', [Errors]));
  exit;
 end;
// запись - во временный файл рядом; .gmf заменяется только после успешной
// записи (сбой на середине не портит прежний файл)
 TmpName := FileName + '.tmp';
 try
  Buf := TBufStream.InitFileStream(TmpName, fmCreate);
  try
   Form.About.ClassName := 'VCLASS\' + ExtractFileName(Form.About.ClassName);
   Buf.Put(Form);
  finally
   Buf.Free;
  end;
  if TFile.Exists(FileName) then TFile.Delete(FileName);
  TFile.Move(TmpName, FileName);
 except
  on E: Exception do begin
   Report('Ошибка сохранения ' + FileName + ': ' + E.Message);
  // прежний файл на месте - временный не нужен; удален, а замена не удалась -
  // записанная карта остается во временном
   try
    if TFile.Exists(TmpName) then
     if TFile.Exists(FileName) then TFile.Delete(TmpName) else Report('Карта записана в ' + TmpName);
   except
   end;
   exit;
  end;
 end;
 Report('Сохранено: ' + FileName);
 Result := True;
// дубликат успешно сохраненного файла
 CopyName := ChangeFileExt(FileName, '.gm3');
 try
  TFile.Copy(FileName, CopyName, True);
  Report('Копия: ' + CopyName);
 except
  on E: Exception do Report('Ошибка копии ' + CopyName + ': ' + E.Message);
 end;
end;

end.
