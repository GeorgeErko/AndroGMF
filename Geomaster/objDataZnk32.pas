unit objDataZnk32;

// Перенос модуля objDataZnk из Geomaster (Delphi 7, GDI), только операция
// Lo_TextZnak (2001, кнопка rsResetZnak2 «Изменение текста подписи» -
// TMasterDendro.sbNumClick, кнопка sbNum ОЗН): знак под курсором
// подсвечивается, щелчок - диалог атрибутов знака (TTextManager.SetTexts2,
// VarSetForm1 = 1): деревья/кустарники - TVarSetDlg1, газоны - TVarSetDlg2,
// цветники - TVarSetDlg3 (по атрибуту '*Тип (ОГХ)'), изменение с отменой.
// Знак ищется так же, как в TMouseTopo (mp_RotateP): emGetDotMarker.
// Диалог не блокирует обработчик (на Android синхронного ShowModal нет):
// изменение записывается в обработчике результата.
// Не перенесено: остальные операции TDataZnkSet (Lo_AddDataZnk, промеры,
// перемещение подписей), связь с сервером (dendroModifiedPrim).

interface uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.Skia,
               FMX.Types, objMouse32, objMouseDraw32, Collect, EcDot, WptForm2;

const
  Lo_TextZnak = 2001;

type
// признак жизни обработчика для отложенного результата диалога атрибутов
 IDataZnkAlive = interface
  ['{3E7A51C2-8B4D-4F19-A6E0-2C9D7B15F842}']
  function Alive: Boolean;
  procedure Kill;
 end;

 TDataZnkSet = class(TMousePainter)
  private
   FAlive: IDataZnkAlive;
   FTextsDialog: Boolean; // открыт диалог атрибутов - мышь не обрабатывается
  public
   VarSetForm1: Byte;     // 0 - TVarSetDlg; 1 - форма по виду насаждения
   PrevActiveDot: TPointDot; // знак под курсором
  //
   Constructor Create(ATwigs: Pointer; AFreeProc: TFreeProc); override;
   Destructor Destroy; override;
   Procedure MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean); override;
   Procedure DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean = False); override;
  //
   Procedure DrawActiveDot(const Canvas: ISkCanvas);
   Function SetDialogClass(PD: TPointDot): Boolean;
   Procedure EditTexts(PD: TPointDot);
  // снятие выделения: подсветка знака под курсором и выделенные примитивы формы
   Procedure ClearSelected;
 end;

implementation uses FMX.DialogService, GBFWUndo, UndoColNew, newSelector, newClassBuilder,
                    TextManager, ogcDrawerSkia, VarSetForm, VarSetForm1, VarSetForm2,
                    VarSetForm3, EcDot2, Selector32;

type
 TDataZnkAlive = class(TInterfacedObject, IDataZnkAlive)
  private
   FAlive: Boolean;
  public
   constructor Create;
   function Alive: Boolean;
   procedure Kill;
 end;

constructor TDataZnkAlive.Create;
begin
 inherited Create;
 FAlive := True;
end;

function TDataZnkAlive.Alive: Boolean;
begin
 Result := FAlive;
end;

procedure TDataZnkAlive.Kill;
begin
 FAlive := False;
end;

{ TDataZnkSet }

constructor TDataZnkSet.Create(ATwigs: Pointer; AFreeProc: TFreeProc);
begin
 inherited;
 FAlive := TDataZnkAlive.Create;
 VarSetForm1 := 1;
end;

destructor TDataZnkSet.Destroy;
begin
// результат открытого диалога атрибутов придет уже без обработчика
 if FAlive <> nil then FAlive.Kill;
 inherited;
end;

// подсветка знака под курсором: Draw32 на live-канве, затем белый силуэт
// (live-слой смешивается со сценой в режиме Difference, как в TMouseTopo)
procedure TDataZnkSet.DrawActiveDot(const Canvas: ISkCanvas);
var Drawer: TogsDrawerSkia;
    OldCanvas: ISkCanvas;
    PrevWorld: Boolean;
    Paint: ISkPaint;
begin
 if (PrevActiveDot = nil) or (Canvas = nil) or not (Selector.Drawer is TogsDrawerSkia) then exit;
 Drawer := TogsDrawerSkia(Selector.Drawer);
 Canvas.SaveLayer(Canvas.GetLocalClipBounds, nil);
 try
  OldCanvas := Drawer.SwapSkCanvas(Canvas);
  PrevWorld := Drawer.UseWorldCoords;
  Drawer.UseWorldCoords := True;
  try
   PrevActiveDot.Draw32(Drawer, Twigs.MkLib.PSLib, Twigs.FontColEx);
  finally
   Drawer.UseWorldCoords := PrevWorld;
   Drawer.RestoreSkCanvas(OldCanvas);
  end;
  Paint := TSkPaint.Create;
  Paint.Color := TAlphaColorRec.White;
  Paint.Blender := TSkBlender.MakeMode(TSkBlendMode.SrcIn);
  Canvas.DrawPaint(Paint);
 finally
  Canvas.Restore;
 end;
end;

procedure TDataZnkSet.DrawTemp(const Canvas: ISkCanvas; PaintOnImage: Boolean);
begin
 inherited;
 if Canvas = nil then exit;
 if LOperation = Lo_TextZnak then DrawActiveDot(Canvas);
end;

// форма диалога атрибутов по виду насаждения (SetTexts1 старой программы)
function TDataZnkSet.SetDialogClass(PD: TPointDot): Boolean;
var Kind: String;
begin
 Result := True;
 if VarSetForm1 = 0 then begin
  GlobalVarSetDlgClass := TVarSetDlg;
  exit;
 end;
 Kind := String(PD.GetProperty('*Тип (ОГХ)'));
 if Kind = 'Деревья/Кустарники' then GlobalVarSetDlgClass := TVarSetDlg1 else
 if Kind = 'Газоны' then GlobalVarSetDlgClass := TVarSetDlg2 else
 if Kind = 'Цветники' then GlobalVarSetDlgClass := TVarSetDlg3 else begin
  TDialogService.ShowMessage('Выберите растение, газон или цветник');
  ClearSelected;
  Result := False;
 end;
end;

procedure TDataZnkSet.ClearSelected;
begin
 PrevActiveDot := nil;
 LMouseDown := False;
 Twigs.ClearSelection;
// слой выделения (статический оверлей) и live-слой с подсветкой
 if Assigned(Selector.OnInvalidateOverlayStatic) then Selector.OnInvalidateOverlayStatic;
 UpdateImage;
end;

// диалог атрибутов знака PD; изменение записывается в Undo (LU_ModifiedPrim)
procedure TDataZnkSet.EditTexts(PD: TPointDot);
var NilTextManager: Boolean;
    PrimUndo: TPrimUndo;
    A: IDataZnkAlive;
    Form: TForm2;
begin
 if (PD = nil) or (PD is TDotText) then exit;
 if not SetDialogClass(PD) then exit;
 NilTextManager := PD.TextManager = nil;
 if NilTextManager then PD.CreateTextManager;
 if PD.TextManager = nil then exit;
 PD.TextManager.UpdateResults := True;
// копия знака до изменения - для отмены
 PrimUndo := TPrimUndo.Create(Twigs, LU_ModifiedPrim, 'UndoTextZnak...Lo_TextZnak');
 PrimUndo.AddModifiedPrim(PD);
 A := FAlive;
 Form := Twigs;
 FTextsDialog := True;
 PD.TextManager.SetTexts2(Twigs, PD, True, VarSetForm1,
  procedure(OK: Boolean)
  begin
  // форма или знак могли смениться, пока открыт диалог
   if not A.Alive then begin
    PrimUndo.Free;
    exit;
   end;
   FTextsDialog := False;
   LMouseDown := False;
   if not OK or (Assigned(OnModifiedPrim) and not OnModifiedPrim(PD)) then begin
    if NilTextManager then PD.FreeTextManager else
    if PD.TextManager <> nil then PD.TextManager.UpdateResults := False;
    PrimUndo.Free;
    ClearSelected;
    exit;
   end;
   if PD.TextManager <> nil then PD.TextManager.UpdateResults := False;
   BuildPoint1(Selector, Form.LayerTable, Form.Twigs, PD);
   Undo.AddUndoItem(PrimUndo);
   Modified;
   Selector.UpdateImage(usmModify, PD);
   ClearSelected;
  end);
end;

procedure TDataZnkSet.MouseDown(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if not LMouseDown then exit;
 if LOperation = Lo_TextZnak then EditTexts(PrevActiveDot);
end;

procedure TDataZnkSet.MouseUp(Form: TForm2; Button: TMouseButton; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 Hook := True;
 if FTextsDialog then exit; // открыт диалог атрибутов
 inherited;
 if ShiftPress or ControlPress then Hook := False;
end;

// знак под курсором (в старой программе - по подписи знака или расстоянию
// psAutoDisst; здесь - поиск знака, как у поворота знака TMouseTopo)
procedure TDataZnkSet.MouseMove(Form: TForm2; Shift: TShiftState; X, Y: Double; var Hook: boolean);
begin
 if FTextsDialog then begin Hook := True; exit; end; // открыт диалог атрибутов
 inherited;
 Hook := True;
 if ShiftPress or ControlPress then begin Hook := False; exit; end;
 if LOperation <> Lo_TextZnak then exit;
 emGetDotMarker(X, Y, nil, Stvor_, objTemporary, False, False);
 if (objTemporary is TPointDot) and not (objTemporary is TDotText) then PrevActiveDot := TPointDot(objTemporary) else PrevActiveDot := nil;
 UpdateImage;
end;

end.
