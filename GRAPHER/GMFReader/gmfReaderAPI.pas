unit gmfReaderAPI;

interface

// Контракт библиотеки читателя GMF: gmfreader.dll (Win64) / libgmfreader.so (Android64).
// У библиотеки собственная копия RTL и менеджера памяти, поэтому через границу
// передаются только простые типы, записи, PChar и указатели; строки Delphi, объекты
// и исключения - нет. Строка PChar действительна только во время вызова.
// Соглашение cdecl на обеих платформах.

const
  cGMFReaderLib = {$IFDEF MSWINDOWS}'gmfreader.dll'{$ELSE}'libgmfreader.so'{$ENDIF};
  cGMFReaderVersion = 1;
// коды ошибок gmfReaderOpen (< 0)
  gmfErrFileNotFound = -1;
  gmfErrLoad = -2;
  gmfErrNotGMF = -3;

type

  { TgmfReaderInfo - сведения о прочитанном файле }

  PgmfReaderInfo = ^TgmfReaderInfo;
  TgmfReaderInfo = record
   Size: Integer;        // SizeOf(TgmfReaderInfo) - контроль версии записи
   LotsCount: Integer;   // контуры (площадные и линейные)
   TwigsCount: Integer;  // ветви
   AnyCount: Integer;    // точки и тексты
   BlocksCount: Integer; // блоки
  end;

// обратный вызов: UserData - данные вызывающего, Info - сведения о файле,
// Msg - текстовое сообщение библиотеки
  TgmfReaderCallback = procedure(UserData: Pointer; Info: PgmfReaderInfo; Msg: PChar); cdecl;

// экспортируемые функции библиотеки
  TgmfReaderVersionFunc = function: Integer; cdecl;
// FileName - путь к .gmf, AppPath - каталог вызывающей программы (newProcs.MainPath:
// классификатор, настройки); '' -> Windows: каталог exe, Android: TPath.GetDocumentsPath;
// результат - число контуров или код ошибки (< 0)
  TgmfReaderOpenFunc = function(FileName, AppPath: PChar; Callback: TgmfReaderCallback;
                                UserData: Pointer): Integer; cdecl;
// текст последней ошибки в Buf (не более BufLen символов с #0), результат - длина текста
  TgmfReaderLastErrorFunc = function(Buf: PChar; BufLen: Integer): Integer; cdecl;

implementation

end.
