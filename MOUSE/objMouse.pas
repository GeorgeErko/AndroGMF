unit objMouse;
interface
 uses Collect, Classes, FMX.Controls, WpTForm2, FMX.Graphics, newSelector,
      UpdateMessages, UndoColNew, System.UITypes, System.Types, System.Skia,
      drawTwigs;

const
 keyNone=-1;

type
 TFreeProc=procedure of object;

type
 TKeyMouseHook=class(TTwgObject)
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
  XInt,YInt:Integer;
  MouseX,MouseY:Double;
  RMouseX,RMouseY:Double;
  LMouseDown,RMouseDown:boolean;
  ShiftPress,ControlPress:boolean;
 {}
  Twigs:TForm2; // указатель на глобальную коллекцию примитивов
  Prims:TForm2; // примитивы блока, заботливо сложенные в коллекцию примитивов
 {}
  FreeProc:TFreeProc;
  PopUpMenu:TPopUp;
  MouseIntf:IUnknown;
 {}
  Cursor,PrevCursor:Integer;
 {}
  V25:Pointer;
 {}
  Operation:Integer;
  objTemporary:TTwgObject;
  objMemory:TTwgObject;
  Error:String;
 //
  mForms:TList;
   class function MouseHook(Operation:Integer):boolean;virtual;
 {}
   Constructor Create(ATwigs:Pointer;AFreeProc:TFreeProc); virtual;
   Procedure Initialize;virtual;
   Destructor Destroy;override;
   Procedure KeyDown(Form:TForm2; var Key: Word; Shift: TShiftState; var Hook:boolean);virtual;
   Procedure KeyUp(Form:TForm2; var Key: Word; Shift: TShiftState; var Hook:boolean);virtual;
   Procedure MouseDown(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);virtual;
   Procedure MouseRightDown(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);virtual;
   Procedure MouseUp(Form:TForm2; Button: TMouseButton;Shift: TShiftState;X, Y: Double; var Hook:boolean);virtual;
   Procedure MouseMove(Form:TForm2; Shift: TShiftState;X, Y: Double; var Hook:boolean);virtual;
  {}
   Procedure DrawTemp(const Canvas: ISkCanvas;PaintOnImage:Boolean=False);virtual;// отрисовка при построении
   Procedure DrawActive(const Canvas:ISkCanvas);virtual;// отрисовка Prims с выделением
   Procedure Draw(const Canvas:ISkCanvas);virtual; // отрисовка Prims
   Procedure UpdateSettings(Sender:TObject);virtual;
   Procedure SetCur(CurName:String);virtual;
   Procedure ResetCur;virtual;
  {обработка события об изменении}
   Procedure Return(Sender:TObject);virtual;abstract;
  {}
   Procedure PopUpMenuPopUp(X,Y:Double);
  {}
   Procedure Modified;virtual;
   Procedure NoModified;virtual;
  {}
   Function CanDoUndo:Boolean;virtual;
   Function CanDoRedo:Boolean;virtual;
  {события об изменении метрик объектов}
   Function Selector: TSelector;
   Property LOperation: Integer read GetOperation write SetOperation;
   function XPix(X: Double): Integer; virtual;
   function YPix(Y: Double): Integer; virtual;
   function XGeo(X: Integer): Double; virtual;
   function YGeo(Y: Integer): Double; virtual;
   function geoDist(Value: Double): Double; virtual;
   function pixDist(Value: Double): Integer; virtual;

  //
   Property OnModifiedPrim:procModifiedPrim read FOnModifiedPrim write FOnModifiedPrim;
   Property OnAddPrim:procAddPrim read FOnAddPrim write FOnAddPrim;
   Property OnDeletePrim:procDeletePrim read FOnDeletePrim write FOnDeletePrim;
   Property OnSetActiveLayer:procSetLayer read FOnSetActiveLayer write FOnSetActiveLayer;
   Property OnOpenFile:procOpenFile read fOnOpenFile write fOnOpenFile;
   Property OnSetOperation:procSetOperation read fOnSetOperation write fOnSetOperation;
   Property Undo:TUndo read GetUndo;
  //
   Procedure Minimize;virtual;
   Procedure Maximize;virtual;
  end;

implementation uses SysUtils, newProcs, newSettings, FMX.Forms, Writer;

{ TKeyMouseHook }

constructor TKeyMouseHook.Create;
begin
 WriteIn(['KM', 1]);
 Twigs:=ATwigs;
 mForms:=TList.Create;
 Operation := LOperation;
 WriteIn(['KM', 2]);
 FreeProc:=AFreeProc;
 Prims:=TForm2.Create(0);
 WriteIn(['KM', 3]);
 ShiftPress:=False;ControlPress:=False;
 LMouseDown:=False;RMouseDown:=False;MouseX:=0;MouseY:=0;
 PopUpMenu:=nil;
 WriteIn(['KM', 4]);
// Initialize;
 V25:=nil;
// Writeln(AnsiUpperCase(ExtractFileExt(Twigs.About.MyName)));
// If not ((AnsiUpperCase(ExtractFileExt(Twigs.About.MyName)) = '.GM2') or (AnsiUpperCase(ExtractFileExt(Twigs.About.MyName)) = '.GM3')) then
// Writeln('AutoSaveEna=',AutoSaveEnabled);
// If not Twigs.MirrorObject then If AutoSaveEnabled then try If not AutoSave(Twigs) then Writeln('AutoSaveFALSE');
 UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
 WriteIn(['KM', 5]);
//
 Application.Hint:=' ';
end;

destructor TKeyMouseHook.Destroy;
begin
 mForms.Free;
 Prims.Free;
 if @FreeProc<>nil then FreeProc;
 ResetCur;
end;

procedure TKeyMouseHook.Draw(const Canvas: ISkCanvas);
begin
end;

procedure TKeyMouseHook.DrawActive(const Canvas: ISkCanvas);
begin
end;

procedure TKeyMouseHook.DrawTemp(const Canvas:ISkCanvas;PaintOnImage:Boolean=False);
begin
end;

function TKeyMouseHook.geoDist(Value: Double): Double;
begin
 Result := Twigs.Selector.geoDist(Value);
end;

procedure TKeyMouseHook.Initialize;
begin
 SetCur('');
end;

procedure TKeyMouseHook.KeyDown;
begin
 if Key=VKShift then ShiftPress:=True;
 if Key=VKControl then ControlPress:=True;
end;

procedure TKeyMouseHook.KeyUp;
begin
 if Key=VKShift then ShiftPress:=False;
 if Key=VKControl then ControlPress:=False;
end;

procedure TKeyMouseHook.MouseRightDown(Form: TForm2; Button: TMouseButton;
  Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 RMouseX:=X;RMouseY:=Y;
end;

procedure TKeyMouseHook.MouseDown;
begin
 If Button = TMouseButton.mbLeft then LMouseDown:=True;
 If Button = TMouseButton.mbRight then RMouseDown:=True;
 MouseX:=X;MouseY:=Y;
 XInt:=XPix(X);YInt:=YPix(Y);
 Hook:=True;
 if RMouseDown then MouseRightDown(Form, Button, Shift, X, Y, Hook);
end;

procedure TKeyMouseHook.MouseMove;
begin
 MouseX:=X;MouseY:=Y;
 Hook := False;
end;

procedure TKeyMouseHook.MouseUp;
begin
 If Button = TMouseButton.mbLeft then LMouseDown:=False;
 If Button = TMouseButton.mbRight then RMouseDown:=False;
 MouseX:=X;MouseY:=Y;
 Hook := False;
end;

procedure TKeyMouseHook.UpdateSettings;
begin
// ClassBuild(nil,Twigs.ClName,Twigs.Twigs,Twigs.MkLib);
end;

function TKeyMouseHook.XGeo(X: Integer): Double;
begin
 Result := Twigs.Selector.XGeo(X);
end;

function TKeyMouseHook.XPix(X: Double): Integer;
begin
 Result := Twigs.Selector.XPix(X);
end;

function TKeyMouseHook.YGeo(Y: Integer): Double;
begin
 Result := Twigs.Selector.YGeo(Y);
end;

function TKeyMouseHook.YPix(Y: Double): Integer;
begin
 Result := Twigs.Selector.YPix(Y);
end;

procedure TKeyMouseHook.ResetCur;
begin
// if Cursor<>0 then DestroyCursor(Cursor);
// SetActiveCursor(PrevCursor);
end;

function TKeyMouseHook.Selector: TSelector;
begin
 Result := Twigs.Selector;
end;

procedure TKeyMouseHook.SetCur(CurName: String);
begin
{
 PrevCursor:=GetActiveCursor;
 If CurName='' then begin
  try
   Cursor:=LoadCursor(hInstance,MakeIntResource(LOperation))
  except Cursor:=0; end;
 end else Cursor:=LoadCursor(hInstance,PChar(CurName));
 If Cursor<>0 then SetActiveCursor(Cursor);
}
end;

procedure TKeyMouseHook.SetOperation(const Value: Integer);
begin
 Selector.Loperation := Value;
end;

procedure TKeyMouseHook.PopUpMenuPopUp(X, Y: Double);
var P:TPoint;
begin
 P.X:=XPix(X);P.Y:=YPix(Y);
 If PopUpMenu<>nil then begin
  RMouseDown:=False;
  LMouseDown:=False;
  If Assigned(PopUpMenu.OnPopup) then PopUpMenu.OnPopup(PopupMenu);
 {$IFDEF VIEWER}
  exit;
 {$ENDIF}
  PopUpMenu.Position.X := P.X; PopUpMenu.Position.X := P.Y;
  PopUpMenu.PopUp;
 end;
end;

procedure TKeyMouseHook.Modified;
begin
 Twigs.Modified:=True;
end;

procedure TKeyMouseHook.NoModified;
begin
 Twigs.Modified:=False;
end;

function TKeyMouseHook.pixDist(Value: Double): Integer;
begin

end;

class function TKeyMouseHook.MouseHook(Operation: Integer): boolean;
begin
 Result:=False;
end;

function TKeyMouseHook.CanDoUndo: Boolean;
begin
 Result:=False;
end;

function TKeyMouseHook.CanDoRedo: Boolean;
begin
 Result:=False;
end;

function TKeyMouseHook.GetOperation: Integer;
begin
 Selector.execEscape;
 Result := Selector.LOperation;
end;

function TKeyMouseHook.GetUndo: TUndo;
begin
 Result:=Twigs.Undo;
end;

procedure TKeyMouseHook.Maximize;
var I:Integer;
begin
 For I:=0 to mForms.Count-1 do TForm(mForms[I]).Show;
end;

procedure TKeyMouseHook.Minimize;
var I:Integer;
begin
 For I:=0 to mForms.Count-1 do TForm(mForms[I]).Hide;
end;

initialization

finalization
end.

