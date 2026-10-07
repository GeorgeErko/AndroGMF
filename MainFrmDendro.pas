unit MainFrmDendro;

// Главная форма ОЗН (дендро): кнопки панели ToolBarOZN (бывшая pDendro старой
// программы MainSkinFormDendro) и служебные процедуры из MasterDendroForm.
// Кнопки ОЗН идут в ToolButtonClick формы (единая схема включения операций
// мыши) и обрабатываются здесь (DendroButtonClick).
// Перенесено: установка дерева лиственного/хвойного, кустарника (sbSetD,
// sbSetE, sbSetK - TMasterDendro.sbSetDClick): знак на вкладке «Паспорт
// зеленых насаждений», операция TMouseTopo mp_SetP, диалог атрибутов
// TVarSetDlg1 (режим TABLET) или TVarSetDlg.
// Номер участка газона (sbNumUCH, Tag = 14): знак 201, диалог TVarSetDlg2; меню
// sbNumUchDropDown (pmLawn старой программы): «Ввод» - то же, в режиме TABLET -
// пункты «тип + состояние» (код 11..53): атрибуты газона без диалога.
// Группы (sbSetG - гк, sbGD - гд, sbGI - жи, sbGC - цв, sbGR - кр; Tag 0..4):
// рисуется контур (живая изгородь - линия, остальные - полигон), по его
// завершении (OnCreateLine2, TMasterDendro.CreateLine) - установка знака с
// атрибутом NAME = ГК/ГД/ЖИ/ЦВ, точка - в начало контура; при включенном
// cbOnlyAttr - только знак, без контура. Диалог: цветник - TVarSetDlg3,
// остальные - TVarSetDlg1 (режим TABLET).
// Не перенесено: связь с сервером (dendroAddPrim и др.), группы и контуры
// (рисование линии/полигона), нумерация, засечки, притягивание ЗН.

interface

{$DEFINE MOUSE32}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmOSM, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  InstLayerFrame, FMX.Ani, FMX.Layouts, FMX.Skia, FMX.Objects,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Menus;

const
// вкладка дендро-знаков панели точечных знаков
  DendroTabName = 'Паспорт зеленых насаждений';

type
  TMainFormDendro = class(TMainFormOSM)
  private
    FLawnMenu: TPopupMenu;
    FGroupTag: Integer; // вид группы, контур которой рисуется
   // Tag - вид насаждения (10, 11, 12, 14), Mode - режим диалога атрибутов
   // (TMouseTopo.VarSetForm1: 0 - TVarSetDlg, 1 - форма по виду, >1 - код газона)
    procedure DendroSetZnak(Sender: TObject; Tag: Integer; Mode: Byte);
    procedure LawnMenuPopup;
    procedure LawnMenuClick(Sender: TObject);
   // группы: Tag 0..4 - знак, контур, установка знака по контуру
    procedure DendroGroup(Sender: TObject; Tag: Integer);
    procedure DendroCreateLine(Sender: TObject);
    procedure OnlyAttrChange(Sender: TObject);
    procedure SetDendroDialogClass(Tag: Integer);
   // знак вида Tag на вкладке дендро-знаков панели точечных знаков
    function SelectDendroZnak(Tag: Integer): Boolean;
  protected
    function DendroButtonClick(Sender: TObject): Boolean; override;
  public
   // режим TABLET: диалог атрибутов TVarSetDlg1 (SetTexts2), иначе - TVarSetDlg
    Tablet: Boolean;
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainFormDendro: TMainFormDendro;

implementation

uses newProcs, newSelector, UpdateMessages, VarSetForm, VarSetForm1, VarSetForm2, VarSetForm3
     {$IFDEF MOUSE32}, objMouse32, objMouseDraw32, objTopo32{$ENDIF};

{$R *.fmx}

constructor TMainFormDendro.Create(AOwner: TComponent);
begin
 inherited;
// Tablet := GReadInteger(AnsiString(Name + '_Tablet'), 1) = 1;
 Tablet := True;
 FGroupTag := -1;
 if cbOnlyAttr <> nil then cbOnlyAttr.OnChange := OnlyAttrChange;
end;

// «только знак»: текущая операция отменяется (TMasterDendro.cbOnlyAttrClick)
procedure TMainFormDendro.OnlyAttrChange(Sender: TObject);
begin
 if MouseObject <> nil then btnEscClick(btnEsc);
end;

// кнопки панели ОЗН; остальные кнопки - обычные операции мыши
function TMainFormDendro.DendroButtonClick(Sender: TObject): Boolean;
begin
 Result := (Sender = sbSetD) or (Sender = sbSetE) or (Sender = sbSetK) or (Sender = sbGD) or
           (Sender = sbSetG) or (Sender = sbGI) or (Sender = sbGC) or (Sender = sbGR) or
           (Sender = sbNum) or (Sender = sbNumUCH) or (Sender = sbNumUchDropDown) or
           (Sender = dnrPerp) or (Sender = dnrZas) or (Sender = sbP2P) or (Sender = sSpeedButton40) or
           (Sender = sSpeedButton39) or (Sender = sSpeedButton42) or (Sender = SpeedButton6) or
           (Sender = sbCancel);
 if not Result then exit;
 if (Sender = sbSetD) or (Sender = sbSetE) or (Sender = sbSetK) or (Sender = sbNumUCH) then
  DendroSetZnak(Sender, TComponent(Sender).Tag, Ord(Tablet)) else
 if Sender = sbNumUchDropDown then LawnMenuPopup else
 if (Sender = sbSetG) or (Sender = sbGD) or (Sender = sbGI) or (Sender = sbGC) or (Sender = sbGR) then
  DendroGroup(Sender, TComponent(Sender).Tag);
// остальные кнопки ОЗН пока не реализованы
end;

// установка дендро-знака точкой (TMasterDendro.sbSetDClick): Tag - вид
// насаждения (10 - дерево лиственное, 11 - хвойное, 12 - кустарник, 14 - номер
// участка газона)
// знак вида насаждения Tag: 10 - дерево лиственное, 11 - хвойное, 12 - кустарник,
// 14 - номер участка газона, 0 - группа кустарников, 1 - группа деревьев,
// 2 - живая изгородь, 3 - цветник, 4 - растения Красной книги
function TMainFormDendro.SelectDendroZnak(Tag: Integer): Boolean;
var Z: Integer;
begin
 Result := False;
 case Tag of
  10: Z := 40;
  11: Z := 34;
  12: Z := 97;
  14: Z := 201;
  0: Z := 98;
  1: Z := 99;
  2: Z := 95;
  3: Z := 28;
  4: Z := 103;
 else
  exit;
 end;
 if (Selector = nil) or (TwgForm = nil) or (InstPoints = nil) then exit;
// знак на вкладке панели точечных знаков (слой знака - активный, знак новых
// точек); панель не открывается - фрейм заполнен и при скрытой панели
 Result := InstPoints.SelectZnakByNum(DendroTabName, Z);
 if not Result then
  FMX.Dialogs.ShowMessage('Не найден знак ' + IntToStr(Z) + ' на вкладке «' + DendroTabName + '» панели точечных знаков');
end;

// форма диалога атрибутов: без режима TABLET - TVarSetDlg; газон - TVarSetDlg2,
// цветник - TVarSetDlg3, остальные - TVarSetDlg1
procedure TMainFormDendro.SetDendroDialogClass(Tag: Integer);
begin
 if not Tablet then GlobalVarSetDlgClass := TVarSetDlg else
 if Tag = 14 then GlobalVarSetDlgClass := TVarSetDlg2 else
 if Tag = 3 then GlobalVarSetDlgClass := TVarSetDlg3 else
                 GlobalVarSetDlgClass := TVarSetDlg1;
end;

procedure TMainFormDendro.DendroSetZnak(Sender: TObject; Tag: Integer; Mode: Byte);
begin
 if not SelectDendroZnak(Tag) then exit;
 SetDendroDialogClass(Tag);
// установка знака точкой (TMouseTopo, mp_SetP)
{$IFDEF MOUSE32}
 InstPointsTool(Sender, mp_SetP);
 if MouseObject is TMouseTopo then TMouseTopo(MouseObject).VarSetForm1 := Mode;
{$ENDIF}
end;

// меню номера участка газона (pmLawn): «Ввод» и, в режиме TABLET, коды
// «тип + состояние» - номер = код, десятки - тип, единицы - состояние
procedure TMainFormDendro.LawnMenuPopup;
const LawnTypes: array[1..5] of String = ('Обыкновенный', 'Луговой', 'Партерный', 'На откосе', 'Иного типа');
      LawnStates: array[1..3] of String = ('Хорошее', 'Удовлетворительное', 'Неудовлетворительное');
var T, St: Integer;
    MI: TMenuItem;
    P: TPointF;
procedure AddItem(const AText: String; ATag: Integer);
begin
 MI := TMenuItem.Create(FLawnMenu);
 MI.Text := AText;
 MI.Tag := ATag;
 MI.OnClick := LawnMenuClick;
 FLawnMenu.AddObject(MI);
end;
begin
 if FLawnMenu = nil then begin
  FLawnMenu := TPopupMenu.Create(Self);
  FLawnMenu.Parent := Self;
  AddItem('Ввод', 0);
  for T := 1 to 5 do
   for St := 1 to 3 do
    AddItem(Format('%d. %s + %s', [T * 10 + St, LawnTypes[T], LawnStates[St]]), T * 10 + St);
 end;
// коды - только в режиме TABLET (PMLawnPopup старой программы)
 for T := 0 to FLawnMenu.ItemsCount - 1 do
  FLawnMenu.Items[T].Visible := (FLawnMenu.Items[T].Tag = 0) or Tablet;
 P := sbNumUchDropDown.LocalToScreen(PointF(0, sbNumUchDropDown.Height));
 FLawnMenu.Popup(P.X, P.Y);
end;

procedure TMainFormDendro.LawnMenuClick(Sender: TObject);
var Code: Integer;
begin
 Code := TComponent(Sender).Tag;
 if Code = 0 then DendroSetZnak(sbNumUCH, 14, Ord(Tablet)) else
                  DendroSetZnak(sbNumUCH, 14, Code);
end;


// группа (TMasterDendro.sbSetDClick, Tag 0..4): знак группы; с cbOnlyAttr -
// сразу установка знака, иначе - рисование контура (живая изгородь - линия,
// остальные - полигон), знак - по завершении контура (DendroCreateLine)
procedure TMainFormDendro.DendroGroup(Sender: TObject; Tag: Integer);
var I: Integer;
begin
 if not SelectDendroZnak(Tag) then exit;
 SetDendroDialogClass(Tag);
 if cbOnlyAttr.IsChecked then begin
  DendroSetZnak(Sender, Tag, Ord(Tablet));
  exit;
 end;
{$IFDEF MOUSE32}
 FGroupTag := Tag;
// кнопки инструментов рисования отжимаются
 for I := 0 to ComponentCount - 1 do
  if (Components[I] is TSpeedButton) and (TSpeedButton(Components[I]).GroupName = 'PaintTools') then TSpeedButton(Components[I]).IsPressed := False;
 //if Tag = 2 then Selector.LOperation := sysDrawLine else Selector.LOperation := sysDrawPoly;
 Selector.LOperation := sysDrawLine;
 MouseObject := nil;
 MouseObject := TMousePainter.Create(TwgForm, nil);
 MouseObject.OnAddPrim := UpdateMessage.AddPrim;
 MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
 MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
 MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 TMousePainter(MouseObject).OnCreateLine2 := DendroCreateLine;
 UpdateEscButton(1);
{$ENDIF}
end;

// контур группы нарисован (TMasterDendro.CreateLine): установка знака группы
// с атрибутом NAME, точка - в начало контура (LastPrim). Обработчик мыши
// заменяется после выхода из обработчика рисования (он вызывает это событие)
procedure TMainFormDendro.DendroCreateLine(Sender: TObject);
{$IFDEF MOUSE32}
var LastPrim: Pointer;
    Lot: TObject;
    Tag: Integer;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if not (MouseObject is TMousePainter) then exit;
 LastPrim := TMousePainter(MouseObject).LastPrim;
 Lot := Sender;
 Tag := FGroupTag;
 TThread.ForceQueue(nil,
  procedure
  var T: TMouseTopo;
  begin
  // новый контур - в сцену
   if (Lot is TObject) and (Selector <> nil) then Selector.UpdateImage(usmAdd, Lot);
   InstPointsTool(sbSetG, mp_SetP);
   if not (MouseObject is TMouseTopo) then exit;
   T := TMouseTopo(MouseObject);
   T.VarSetForm1 := Ord(Tablet);
   T.LastPrim := LastPrim;
   case Tag of
    0: T.DendroValue := 'ГК';
    1: T.DendroValue := 'ГД';
    2: T.DendroValue := 'ЖИ';
    3: T.DendroValue := 'ЦВ';
   end;
   if Tag in [0..3] then T.DendroAttr := 'NAME';
   T.DendroUpdate := True;
  end);
{$ENDIF}
end;

end.
