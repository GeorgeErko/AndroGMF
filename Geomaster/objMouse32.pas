unit objMouse32;

// Перенос модуля objMouse из Geomaster (Delphi 7, GDI): базовый обработчик
// клавиатуры и мыши. Интерфейс совпадает с текущим MOUSE\objMouse
// (DrawTemp/DrawTempStatic на ISkCanvas, Selector, LOperation, Hint), чтобы
// форма могла перейти на этот модуль заменой в uses.
// Рисование выполняется только в DrawTemp (live-слой) и DrawTempStatic.

interface

uses System.Classes, System.Types, System.UITypes, System.Skia, FMX.Controls,
     FMX.Graphics, FMX.Forms, Collect, WPTForm2, newSelector, UpdateMessages,
     UndoColNew;

const
 keyNone = -1;

type
 TFreeProc = procedure of object;

type
 TKeyMouseHook = class(TTwgObject)
  private
   FOnAddPrim: procAddPrim;
   FOnDeletePrim: procDeletePrim;
   FOnModifiedPrim: procModifiedPrim;
   FOnSetActiveLayer: procSetLayer;
   fOnOpenFile: procOpenFile;
   fOnSetOperation: procSetOperation;
   function GetUndo: TUndo;
   function GetOperation: Integer;
   procedure SetOperation(const Value: Integer);
  public
   XInt, YInt: Integer;
   MouseX, MouseY: Double;
   RMouseX, RMouseY: Double;
   LMouseDown, RMouseDown, MMouseDown: boolean;
   ShiftPress, ControlPress: boolean;
  //
   Twigs: TForm2; // указатель на глобальную коллекцию примитивов
   Prims: TForm2; // примитивы блока, заботливо сложенные в коллекцию примитивов
  //
   FreeProc: TFreeProc;
   PopUpMenu: TPopup;
   MouseIntf: IUnknown;
  //
   Cursor, PrevCursor: Integer;
  //
   V25: Pointer;
  //
   Operation: Integer;
   objTemporary: TTwgObject;
   objMemory: TTwgObject;
   Error: String;
  //
   mForms: TList; // формы операции (сворачиваются вместе с ней)
  //
   class function MouseHook(Operation: Integer): boolean; virtual;
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); virtual;
   Procedure Initialize; virtual;
   Destructor Destroy; override;
   Procedure KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); virtual;
   Procedure KeyUp(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean); virtual;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); virtual;
   Procedure MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); virtual;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); virtual;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); virtual;
  //
   Procedure DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); virtual; // статический временный слой (кэш)
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); virtual; // live-слой: отрисовка при построении
   Procedure DrawActive(const Canvas: ISkCanvas); virtual; // отрисовка Prims с выделением
   Procedure Draw(const Canvas: ISkCanvas); virtual; // отрисовка Prims
   Procedure UpdateSettings(Sender: TObject); virtual;
   Procedure SetCur(CurName: String); virtual;
   Procedure ResetCur; virtual;
  // обработка события об изменении
   Procedure Return(Sender: TObject); virtual; abstract;
  //
   Procedure PopUpMenuPopUp(X, Y: Double);
  //
   Procedure Modified; virtual;
   Procedure NoModified; virtual;
  //
   Function CanDoUndo: Boolean; virtual;
   Function CanDoRedo: Boolean; virtual;
  //
   Function Selector: TSelector;
   Property LOperation: Integer read GetOperation write SetOperation;
   function XPix(X: Double): Integer; virtual;
   function YPix(Y: Double): Integer; virtual;
   function XGeo(X: Integer): Double; virtual;
   function YGeo(Y: Integer): Double; virtual;
   function geoDist(Value: Double): Double; virtual;
   function pixDist(Value: Double): Integer; virtual;
  // события об изменении метрик объектов
   Property OnModifiedPrim: procModifiedPrim read FOnModifiedPrim write FOnModifiedPrim;
   Property OnAddPrim: procAddPrim read FOnAddPrim write FOnAddPrim;
   Property OnDeletePrim: procDeletePrim read FOnDeletePrim write FOnDeletePrim;
   Property OnSetActiveLayer: procSetLayer read FOnSetActiveLayer write FOnSetActiveLayer;
   Property OnOpenFile: procOpenFile read fOnOpenFile write fOnOpenFile;
   Property OnSetOperation: procSetOperation read fOnSetOperation write fOnSetOperation;
   Property Undo: TUndo read GetUndo;
  //
   Procedure Minimize; virtual;
   Procedure Maximize; virtual;
  //
   Function Hint: String; virtual;
 end;

 TKeyMouseClass = class of TKeyMouseHook;

var MouseHookList: TList; // список зарегистрированных классов перехвата сообщений

 Procedure AddMouseHook(MouseHook: TKeyMouseClass);
 Function MouseHookClassName(CName: String): TKeyMouseClass;

implementation

uses SysUtils, newProcs, Writer, Selector32;

{ TKeyMouseHook }

constructor TKeyMouseHook.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 mForms := TList.Create;
 Twigs := ATwigs;
 Operation := LOperation;
 FreeProc := AFreeProc;
 Prims := TForm2.Create(0);
 ShiftPress := False;
 ControlPress := False;
 LMouseDown := False;
 RMouseDown := False;
 MMouseDown := False;
 MouseX := 0;
 MouseY := 0;
 PopUpMenu := nil;
 V25 := nil;
// автосохранение старой программы (AutoSave) не переносится
 UpdateMessage.SetOperation(Self.ClassName, IntToStr(LOperation));
 Application.Hint := ' ';
end;

destructor TKeyMouseHook.Destroy;
begin
 mForms.Free;
 Prims.Free;
 if Assigned(FreeProc) then FreeProc;
 ResetCur;
end;

procedure TKeyMouseHook.Draw(const Canvas: ISkCanvas);
begin
end;

procedure TKeyMouseHook.DrawActive(const Canvas: ISkCanvas);
begin
end;

procedure TKeyMouseHook.DrawTempStatic(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
end;

procedure TKeyMouseHook.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
end;

procedure TKeyMouseHook.Initialize;
begin
 SetCur('');
end;

procedure TKeyMouseHook.KeyDown(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
 if Key = vkShift then ShiftPress := True;
 if Key = vkControl then ControlPress := True;
end;

procedure TKeyMouseHook.KeyUp(Form: TForm2; var Key: Word; Shift: TShiftState; var Hook: boolean);
begin
 if Key = vkShift then ShiftPress := False;
 if Key = vkControl then ControlPress := False;
end;

procedure TKeyMouseHook.MouseRightDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 RMouseX := X;
 RMouseY := Y;
end;

procedure TKeyMouseHook.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if Button = TMouseButton.mbLeft then LMouseDown := True;
 if Button = TMouseButton.mbRight then RMouseDown := True;
 if Button = TMouseButton.mbMiddle then MMouseDown := True;
 MouseX := X;
 MouseY := Y;
 XInt := XPix(X);
 YInt := YPix(Y);
 Hook := True;
 if RMouseDown then MouseRightDown(Form, Button, Shift, X, Y, Hook);
end;

procedure TKeyMouseHook.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 MouseX := X;
 MouseY := Y;
end;

procedure TKeyMouseHook.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if Button = TMouseButton.mbLeft then LMouseDown := False;
 if Button = TMouseButton.mbRight then RMouseDown := False;
 if Button = TMouseButton.mbMiddle then MMouseDown := False;
 MouseX := X;
 MouseY := Y;
end;

procedure TKeyMouseHook.UpdateSettings(Sender: TObject);
begin
end;

procedure TKeyMouseHook.ResetCur;
begin
 SetActiveCursor(PrevCursor);
end;

procedure TKeyMouseHook.SetCur(CurName: String);
begin
// курсоры старой программы (ресурсы V25*) - заглушки Selector32
 PrevCursor := GetActiveCursor;
 if CurName = '' then begin
  try
   Cursor := LoadCursor(hInstance, MakeIntResource(LOperation))
  except
   Cursor := 0;
  end;
 end else
  Cursor := LoadCursor(hInstance, PChar(CurName));
 if Cursor <> 0 then SetActiveCursor(Cursor);
end;

procedure TKeyMouseHook.PopUpMenuPopUp(X, Y: Double);
begin
 if PopUpMenu = nil then exit;
 RMouseDown := False;
 LMouseDown := False;
{$IFDEF VIEWER}
 exit;
{$ENDIF}
 PopUpMenu.Position.X := XPix(X);
 PopUpMenu.Position.Y := YPix(Y);
 PopUpMenu.Popup;
end;

procedure TKeyMouseHook.Modified;
begin
 Twigs.Modified := True;
end;

procedure TKeyMouseHook.NoModified;
begin
 Twigs.Modified := False;
end;

class function TKeyMouseHook.MouseHook(Operation: Integer): boolean;
begin
 Result := False;
end;

function TKeyMouseHook.CanDoUndo: Boolean;
begin
 Result := False;
end;

function TKeyMouseHook.CanDoRedo: Boolean;
begin
 Result := False;
end;

function TKeyMouseHook.GetUndo: TUndo;
begin
 Result := Twigs.Undo;
end;

procedure TKeyMouseHook.Maximize;
var I: Integer;
begin
 for I := 0 to mForms.Count - 1 do TForm(mForms[I]).Show;
end;

procedure TKeyMouseHook.Minimize;
var I: Integer;
begin
 for I := 0 to mForms.Count - 1 do TForm(mForms[I]).Hide;
end;

function TKeyMouseHook.Selector: TSelector;
begin
 Result := Twigs.Selector;
end;

function TKeyMouseHook.GetOperation: Integer;
begin
 Result := Selector.LOperation;
end;

procedure TKeyMouseHook.SetOperation(const Value: Integer);
begin
 Selector.LOperation := Value;
end;

function TKeyMouseHook.XPix(X: Double): Integer;
begin
 Result := Selector.XPix(X);
end;

function TKeyMouseHook.YPix(Y: Double): Integer;
begin
 Result := Selector.YPix(Y);
end;

function TKeyMouseHook.XGeo(X: Integer): Double;
begin
 Result := Selector.XGeo(X);
end;

function TKeyMouseHook.YGeo(Y: Integer): Double;
begin
 Result := Selector.YGeo(Y);
end;

function TKeyMouseHook.geoDist(Value: Double): Double;
begin
 Result := Selector.geoDist(Value);
end;

function TKeyMouseHook.pixDist(Value: Double): Integer;
begin
 Result := Selector.pixDist(Value);
end;

function TKeyMouseHook.Hint: String;
begin
 Result := ClassName;
end;

Procedure AddMouseHook(MouseHook: TKeyMouseClass);
begin
 if MouseHookList = nil then MouseHookList := TList.Create;
 MouseHookList.Add(MouseHook);
end;

Function MouseHookClassName(CName: String): TKeyMouseClass;
var I: Integer;
begin
 Result := nil;
 if MouseHookList = nil then exit;
 for I := 0 to MouseHookList.Count - 1 do
  if TKeyMouseClass(MouseHookList[I]).ClassName = CName then exit(MouseHookList[I]);
end;

initialization

finalization
 if MouseHookList <> nil then MouseHookList.Free;
end.
