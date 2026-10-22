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
// Изменение атрибутов (нумерации) знака (sbNum - TMasterDendro.sbNumClick):
// обработчик TDataZnkSet (objDataZnk32), операция Lo_TextZnak, VarSetForm1 = 1.
// Притягивание (sbP2P 101, sSpeedButton40 102, sSpeedButton39 103,
// sSpeedButton42 104 - TSkinFormDendro.sbP2PClick): TMouseTopo (objTopo32),
// меню автопритягивания (PopUpAttraction), радиусы поиска UpDown1 (+-0.25) и
// UpDown2 (+-0.1, автопритягивание заново).
// Не перенесено: связь с сервером (dendroAddPrim, dendroModifiedPrim, Tree.gmf),
// засечки.

interface

{$DEFINE MOUSE32}

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmOSM, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  InstLayerFrame, FMX.Ani, FMX.Layouts, FMX.Skia, FMX.Objects,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Menus, FMX.ListBox,
  SelectedObjects, FrameDendro, FrameJSON;

const
// вкладка дендро-знаков панели точечных знаков
  DendroTabName = 'Паспорт зеленых насаждений';

type
  TMainFormDendro = class(TMainFormOSM)
    btnSave: TCornerButton;
    btnSaveAs: TCornerButton;
    procedure btnSaveClick(Sender: TObject);
    procedure btnSaveAsClick(Sender: TObject);
    procedure ToolButtonClick(Sender: TObject);
  private
    FLawnMenu: TPopupMenu;
    FAttractionMenu: TPopupMenu; // меню автопритягивания (PopUpAttraction)
    FGroupTag: Integer; // вид группы, контур которой рисуется
    FFrameDendro: TFrameDendro;
    FFrameJSON: TFrameJSON;
    FButtonMenu: TPopupMenu; // выпадающее меню кнопки (sbFindZN, sbExportCSV, sSpeedButton36)
    FMenuShade: TRectangle;  // Android: подложка меню кнопки-панели (нажатие мимо - закрыть)
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
   // изменение атрибутов знака под курсором (sbNum)
    procedure DendroNum(Sender: TObject);
   // притягивание (sbP2P, sSpeedButton40/39/42 - TSkinFormDendro.sbP2PClick):
   // TMouseTopo, операция = Tag кнопки (mp_Point2Point..mp_Point2Point4)
    procedure DendroAttraction(Sender: TObject);
    procedure AttractionMenuPopup(Sender: TObject);
    procedure BuildAttractionMenu;
    procedure AttractionMenuClick(Sender: TObject);
   // радиусы поиска (UpDown1 - ручные методы, UpDown2 - автопритягивание)
    procedure UpDown1Click(Sender: TObject);
    procedure UpDown2Click(Sender: TObject);
    procedure UpdateRadiusHints;
   // знак вида Tag на вкладке дендро-знаков панели точечных знаков
    function SelectDendroZnak(Tag: Integer): Boolean;
   // операции ЗН (pOprZN) и актуализация (pActual) старой программы
    function DendroFrame: TFrameDendro;
    function JSONFrame: TFrameJSON;
   // выбранные объекты (TEditMap), nil - выбора нет
    function SelectedObjects: TSelectedObjects;
   // карта изменена: пересборка классов, сцена заново
    procedure DendroChanged(Sender: TObject);
    procedure SaveMapTo(AskName: Boolean);
    procedure ShowButtonMenu(Btn: TControl; const Items: array of String; const Tags: array of Integer);
    procedure ButtonMenuClick(Sender: TObject);
   // Android: меню кнопки - панель в форме под кнопкой
    procedure ShowButtonMenuPanel(Btn: TControl; const Items: array of String; const Tags: array of Integer);
    procedure CloseButtonMenuPanel;
    procedure MenuShadeClick(Sender: TObject);
    procedure MenuPanelItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure OrderProperties;
    procedure AutoProps;
    procedure ImportTrees;
    procedure StatDelete(Restore: Boolean);
    procedure PointZNLawn(OldNums: Boolean);
    procedure ExportFoto;
    procedure ExportTrack;
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
     {$IFDEF MOUSE32}, objMouse32, objMouseDraw32, objTopo32, objDataZnk32, objEditMap32{$ENDIF}, Collect,
     StreamSelfTest, DlgGlobalSave, System.IOUtils, System.Generics.Collections, System.Generics.Defaults, FMX.DialogService,
     newConsts, newProperties, newResource, newBlock, UserObject, LBN, EcDot, EcLot,
     WpTwigs, FramePropEditor, WpTForm2, EcDot2, TwgDraw;

{$R *.fmx}

// сохранение в выбранную пользователем папку (DlgGlobalSave: Android -
// Download/подпапка, Windows - Документы/подпапка): путь - в About.Path и
// About.MyName, затем запись с проверкой записи/чтения (StreamSelfTest): .gmf и
// копия .gm3; отчет проверки и итог - сообщением (и при успехе, и при ошибке).
// AskName - «Сохранить как» (можно изменить имя файла)
procedure TMainFormDendro.SaveMapTo(AskName: Boolean);
begin
 if TwgForm = nil then exit;
 SaveMapPicker(string(TwgForm.About.MyName), AskName,
  procedure(FullPath: string)
  var Log: TStringList;
  begin
   if (FullPath = '') or (TwgForm = nil) then exit;
   TwgForm.About.Path := AnsiString(IncludeTrailingPathDelimiter(ExtractFileDir(FullPath)));
   TwgForm.About.MyName := AnsiString(ExtractFileName(FullPath));
   Log := TStringList.Create;
   try
    SaveGmfChecked(TwgForm, FullPath, Log);
    ShowMessage(Log.Text);
   finally
    Log.Free;
   end;
  end);
end;

procedure TMainFormDendro.btnSaveAsClick(Sender: TObject);
begin
 SaveMapTo(True);
end;

procedure TMainFormDendro.btnSaveClick(Sender: TObject);
begin
 SaveMapTo(False);
end;


constructor TMainFormDendro.Create(AOwner: TComponent);
begin
 inherited;
// Tablet := GReadInteger(AnsiString(Name + '_Tablet'), 1) = 1;
 Tablet := True;
 FGroupTag := -1;
 if cbOnlyAttr <> nil then cbOnlyAttr.OnChange := OnlyAttrChange;
// притягивание: стрелки радиусов поиска и подсказки кнопок
 UpDown1Up.OnClick := UpDown1Click;
 UpDown1Down.OnClick := UpDown1Click;
 UpDown2Up.OnClick := UpDown2Click;
 UpDown2Down.OnClick := UpDown2Click;
 sbP2P.Hint := 'Перенос точки в точку: щелчок по первой точке, по второй, затем щелчок - перенос';
 sSpeedButton40.Hint := 'Притягивание дерева к точке съемки: наведение на дерево, щелчок по линии к точке';
 sSpeedButton39.Hint := 'Притягивание дерева к точке съемки: щелчок по дереву, щелчок по линии к точке';
 sSpeedButton42.Hint := 'Автопритягивание деревьев к точкам съемки: щелчок по помеченному дереву, правая кнопка - меню';
// радиусы из настроек читаются при первом использовании (MainPath на Android
// задается при открытии файла)
 UpdateRadiusHints;
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
           (Sender = sbCancel) or
           (Sender = sbOrderProperties) or (Sender = sbAutoDT) or (Sender = sbAutoZN) or (Sender = sbFLKZN) or
           (Sender = sbAttrZN) or (Sender = sbFindZN) or (Sender = sbExportCSV) or (Sender = sSpeedButton36) or
           (Sender = sbStatDelete) or (Sender = sbStatRestore);
 if not Result then exit;
// операции ЗН и актуализация
 if Sender = sbOrderProperties then OrderProperties else
 if Sender = sbAutoDT then AutoProps else
 if Sender = sbAutoZN then ImportTrees else
 if (Sender = sbFLKZN) or (Sender = sbAttrZN) then begin
  DendroFrame.CheckFLK(Sender = sbAttrZN);
  DendroChanged(nil);
 end else
 if Sender = sbFindZN then ShowButtonMenu(sbFindZN, ['Растений без газонов', 'Дубликатов растений'], [1, 2]) else
 if Sender = sbExportCSV then ShowButtonMenu(sbExportCSV, ['Импорт перечетки', 'Экспорт перечетки', '-', 'Экспорт фотофиксации', 'Экспорт трека'], [11, 12, 0, 13, 14]) else
 if Sender = sSpeedButton36 then ShowButtonMenu(sSpeedButton36, ['Из точечных', 'Из пространственных'], [21, -22]) else
 if (Sender = sbStatDelete) or (Sender = sbStatRestore) then StatDelete(Sender = sbStatRestore) else
 if (Sender = sbSetD) or (Sender = sbSetE) or (Sender = sbSetK) or (Sender = sbNumUCH) then
  DendroSetZnak(Sender, TComponent(Sender).Tag, Ord(Tablet)) else
 if Sender = sbNumUchDropDown then LawnMenuPopup else
 if Sender = sbNum then DendroNum(Sender) else
 if (Sender = sbP2P) or (Sender = sSpeedButton40) or (Sender = sSpeedButton39) or (Sender = sSpeedButton42) then DendroAttraction(Sender) else
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

procedure TMainFormDendro.ToolButtonClick(Sender: TObject);
begin
  inherited;

end;

// изменение атрибутов знака (TMasterDendro.sbNumClick -> TFlyZnkData.rsSetZnakClick
// с rsResetZnak2, VarSetForm1 = 1): знак под курсором, щелчок - диалог атрибутов
// по виду насаждения (TVarSetDlg1/2/3)
procedure TMainFormDendro.DendroNum(Sender: TObject);
{$IFDEF MOUSE32}
var I: Integer;
{$ENDIF}
begin
{$IFDEF MOUSE32}
 if (Selector = nil) or (TwgForm = nil) then exit;
// кнопки инструментов рисования отжимаются
 for I := 0 to ComponentCount - 1 do
  if (Components[I] is TSpeedButton) and (TSpeedButton(Components[I]).GroupName = 'PaintTools') then TSpeedButton(Components[I]).IsPressed := False;
 Selector.LOperation := Lo_TextZnak;
 MouseObject := TDataZnkSet.Create(TwgForm, nil);
 TDataZnkSet(MouseObject).VarSetForm1 := 1;
 MouseObject.OnAddPrim := UpdateMessage.AddPrim;
 MouseObject.OnModifiedPrim := UpdateMessage.ModifiedPrim;
 if LayerFrame <> nil then UpdateMessage.OnSetLayer := LayerFrame.ActivateLayer;
 MouseObject.OnSetActiveLayer := UpdateMessage.SetActiveLayer;
 MouseObject.OnDeletePrim := UpdateMessage.DeletePrim;
 UpdateEscButton(1);
{$ENDIF}
end;

// притягивание: обработчик TMouseTopo с операцией = Tag кнопки (101..104);
// автопритягивание - пометки деревьев сразу, меню по правой кнопке
procedure TMainFormDendro.DendroAttraction(Sender: TObject);
begin
{$IFDEF MOUSE32}
 InstPointsTool(Sender, TComponent(Sender).Tag);
 if MouseObject is TMouseTopo then TMouseTopo(MouseObject).OnAttractionMenu := AttractionMenuPopup;
 UpdateRadiusHints;
 InvalidateOverlayLive;
 RepaintLive;
{$ENDIF}
end;

// меню автопритягивания (PopUpAttraction): исправить красные, голубые, все
// меню вызывается из обработчика правой кнопки мыши: точка - положение
// курсора на экране в момент щелчка (MousePos - последнее движение над картой,
// не точка щелчка); меню показывается после выхода из обработчика мыши
// (очередью) и каждый раз создается заново - повторный Popup того же меню из
// обработчика мыши открывался в точке 0,0 окна
procedure TMainFormDendro.AttractionMenuPopup(Sender: TObject);
var P: TPointF;
begin
 P := Screen.MousePos;
 TThread.ForceQueue(nil,
  procedure
  begin
   BuildAttractionMenu;
   FAttractionMenu.Popup(P.X, P.Y);
  end);
end;

procedure TMainFormDendro.BuildAttractionMenu;
procedure AddItem(const AText: String; ATag: Integer);
var MI: TMenuItem;
begin
 MI := TMenuItem.Create(FAttractionMenu);
 MI.Text := AText;
 MI.Tag := ATag;
 if ATag > 0 then MI.OnClick := AttractionMenuClick;
 FAttractionMenu.AddObject(MI);
end;
begin
 FreeAndNil(FAttractionMenu);
 FAttractionMenu := TPopupMenu.Create(Self);
 FAttractionMenu.Parent := Self;
 AddItem('Исправить красные', 1);
 AddItem('Исправить голубые', 2);
 AddItem('-', 0);
 AddItem('Исправить все', 3);
end;

procedure TMainFormDendro.AttractionMenuClick(Sender: TObject);
begin
{$IFDEF MOUSE32}
 if MouseObject is TMouseTopo then TMouseTopo(MouseObject).FixMarks(TComponent(Sender).Tag);
 InvalidateOverlayLive;
 RepaintLive;
{$ENDIF}
end;

procedure TMainFormDendro.UpdateRadiusHints;
var S: String;
begin
{$IFDEF MOUSE32}
 S := 'Радиус поиска для ручных методов = ' + FloatToStrF(AttractionRadius, ffFixed, 15, 2);
 UpDown1Up.Hint := S;
 UpDown1Down.Hint := S;
 S := 'Радиус поиска для автопритягивания = ' + FloatToStrF(AutoRadius, ffFixed, 15, 1);
 UpDown2Up.Hint := S;
 UpDown2Down.Hint := S;
{$ENDIF}
end;

// радиус ручных методов +-0.25 (Tag стрелки 1/-1); выбранное дерево - заново
procedure TMainFormDendro.UpDown1Click(Sender: TObject);
begin
{$IFDEF MOUSE32}
 LoadAttractionRadius;
 AttractionRadius := AttractionRadius + 0.25 * TComponent(Sender).Tag;
 if AttractionRadius < 0.25 then AttractionRadius := 0.25;
 SaveAttractionRadius;
 UpdateRadiusHints;
 if PanelHint <> nil then PanelHint.Text := TControl(Sender).Hint;
 if (MouseObject is TMouseTopo) and (TMouseTopo(MouseObject).LOperation in [mp_Point2Point2, mp_Point2Point3]) then begin
  TMouseTopo(MouseObject).RefreshAttraction;
  InvalidateOverlayLive;
  RepaintLive;
 end;
{$ENDIF}
end;

// радиус автопритягивания +-0.1; автопритягивание запускается заново
procedure TMainFormDendro.UpDown2Click(Sender: TObject);
begin
{$IFDEF MOUSE32}
 LoadAttractionRadius;
 AutoRadius := AutoRadius + 0.1 * TComponent(Sender).Tag;
 if AutoRadius < 0.1 then AutoRadius := 0.1;
 SaveAttractionRadius;
 UpdateRadiusHints;
 if PanelHint <> nil then PanelHint.Text := TControl(Sender).Hint;
 DendroAttraction(sSpeedButton42);
{$ENDIF}
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

{ операции ЗН и актуализация }

function TMainFormDendro.DendroFrame: TFrameDendro;
begin
 if FFrameDendro = nil then FFrameDendro := TFrameDendro.Create(Self);
 FFrameDendro.TwgForm := TwgForm;
 Result := FFrameDendro;
end;

function TMainFormDendro.JSONFrame: TFrameJSON;
begin
 if FFrameJSON = nil then begin
  FFrameJSON := TFrameJSON.Create(Self);
  FFrameJSON.OnChanged := DendroChanged;
 end;
 Result := FFrameJSON;
end;

function TMainFormDendro.SelectedObjects: TSelectedObjects;
begin
 Result := nil;
{$IFDEF MOUSE32}
 if MouseObject is TEditMap then Result := TEditMap(MouseObject).Objects;
{$ENDIF}
end;

procedure TMainFormDendro.DendroChanged(Sender: TObject);
begin
 if TwgForm = nil then exit;
 TwgForm.Modified := True;
 SceneDirty := True;
 InvalidateOverlayAll;
 if SkPainter <> nil then SkPainter.Redraw;
end;

// выпадающее меню под кнопкой (pmFind, pmCSV, pmAttr старой программы); Tag
// пункта < 0 - пункт недоступен (не перенесен), 0 - разделитель. Меню каждый
// раз создается заново
procedure TMainFormDendro.ShowButtonMenu(Btn: TControl; const Items: array of String; const Tags: array of Integer);
var I: Integer;
    MI: TMenuItem;
    P: TPointF;
begin
{$IFDEF ANDROID}
 ShowButtonMenuPanel(Btn, Items, Tags);
 exit;
{$ENDIF}
 FreeAndNil(FButtonMenu);
 FButtonMenu := TPopupMenu.Create(Self);
 FButtonMenu.Parent := Self;
 for I := 0 to High(Items) do begin
  MI := TMenuItem.Create(FButtonMenu);
  MI.Text := Items[I];
  MI.Tag := Tags[I];
  MI.Enabled := Tags[I] >= 0;
  if Tags[I] > 0 then MI.OnClick := ButtonMenuClick;
  FButtonMenu.AddObject(MI);
 end;
 P := Btn.LocalToScreen(PointF(0, Btn.Height));
 FButtonMenu.Popup(P.X, P.Y);
end;

// TPopupMenu на Android - отдельное окно, его позиция по экранным координатам
// смещается (как у TPopup списка слоев), и меню оказывалось не под кнопкой.
// Панель - в самой форме, поверх прозрачной подложки на всю форму; пункт - как
// TMenuItem (Tag < 0 - недоступен, 0 - разделитель)
procedure TMainFormDendro.ShowButtonMenuPanel(Btn: TControl; const Items: array of String; const Tags: array of Integer);
const RowH = 36;
      SepH = 7;
var I: Integer;
    Panel: TRectangle;
    LB: TListBox;
    It: TListBoxItem;
    P: TPointF;
    W, H: Single;
begin
 CloseButtonMenuPanel;
 FMenuShade := TRectangle.Create(Self);
 FMenuShade.Stored := False;
 FMenuShade.Parent := Self;
 FMenuShade.Align := TAlignLayout.Contents;
 FMenuShade.Fill.Kind := TBrushKind.None;
 FMenuShade.Stroke.Kind := TBrushKind.None;
 FMenuShade.HitTest := True;
 FMenuShade.OnClick := MenuShadeClick;
 Panel := TRectangle.Create(FMenuShade);
 Panel.Parent := FMenuShade;
 Panel.Fill.Color := TAlphaColors.White;
 Panel.Stroke.Color := TAlphaColors.Gray;
 Panel.Padding.Rect := TRectF.Create(1, 1, 1, 1);
 LB := TListBox.Create(Panel);
 LB.Parent := Panel;
 LB.Align := TAlignLayout.Client;
 LB.ShowScrollBars := False;
 LB.OnItemClick := MenuPanelItemClick;
 H := 2;
 for I := 0 to High(Items) do begin
  It := TListBoxItem.Create(LB);
  It.Parent := LB;
  It.Tag := Tags[I];
  if Tags[I] = 0 then begin
   It.Height := SepH;
   It.Enabled := False;
  end else begin
   It.Text := Items[I];
   It.Height := RowH;
   It.Enabled := Tags[I] > 0;
  end;
  H := H + It.Height;
 end;
 W := Btn.Width;
 if W < 220 then W := 220;
 if W > ClientWidth then W := ClientWidth;
 P := Btn.LocalToAbsolute(PointF(0, Btn.Height));
 if P.X + W > ClientWidth then P.X := ClientWidth - W;
 if P.X < 0 then P.X := 0;
// снизу не помещается - над кнопкой
 if P.Y + H > ClientHeight then begin
  P.Y := Btn.LocalToAbsolute(PointF(0, 0)).Y - H;
  if P.Y < 0 then P.Y := 0;
 end;
 Panel.SetBounds(P.X, P.Y, W, H);
 FMenuShade.BringToFront;
end;

// закрытие - после обработчика нажатия: подложка и пункт еще в событии
procedure TMainFormDendro.CloseButtonMenuPanel;
begin
 FreeAndNil(FMenuShade);
end;

procedure TMainFormDendro.MenuShadeClick(Sender: TObject);
begin
 TThread.ForceQueue(nil, procedure begin CloseButtonMenuPanel; end);
end;

procedure TMainFormDendro.MenuPanelItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
 if (Item = nil) or (Item.Tag <= 0) then exit;
 TThread.ForceQueue(nil, procedure begin CloseButtonMenuPanel; end);
 ButtonMenuClick(Item);
end;

procedure TMainFormDendro.ButtonMenuClick(Sender: TObject);
begin
 if TwgForm = nil then exit;
 case TComponent(Sender).Tag of
 // поиск
  1: begin
    DendroFrame.FindWithoutLawn;
    DendroChanged(nil);
   end;
  2: begin
   // удаляемые точки не должны оставаться в выделении
    if SelectedObjects <> nil then SelectedObjects.DeleteAll;
    TwgForm.ClearSelection;
    if DendroFrame.DeleteDuplicates > 0 then DendroChanged(nil);
   end;
 // CSV: импорт - текущая операция отменяется; экспорт - выбранные ЗН
  11: begin
    if MouseObject <> nil then btnEscClick(btnEsc);
    JSONFrame.ExecuteImportExport(nil, TwgForm, True);
   end;
  12: JSONFrame.ExecuteImportExport(SelectedObjects, TwgForm, False);
  13: ExportFoto;
  14: ExportTrack;
 // атрибуты газонов из точечных: нумерация - по новой технологии или старой
  21: TDialogService.MessageDialog('Принять по новой технологии нумерации?', TMsgDlgType.mtConfirmation,
       [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbYes, 0,
       procedure(const AResult: TModalResult)
       begin
        PointZNLawn(AResult = mrNo);
       end);
 end;
end;

type
 TPropByIndex = class(TComparer<TProperty>)
  function Compare(const Left, Right: TProperty): Integer; override;
 end;

function TPropByIndex.Compare(const Left, Right: TProperty): Integer;
begin
 Result := Left.Index - Right.Index;
end;

// сортировка атрибутов ЗН по справочнику (sbOrderPropertiesClick): свойства из
// секции Names.txt вида '*Тип (ОГХ)' - в начало списка в порядке секции
procedure TMainFormDendro.OrderProperties;
var I, J, Idx, CurrentIndex: Integer;
    PD: TPointDot;
    B: Byte;
    LNames: TListByName;
    Section: TSectionName;
    Changed: Boolean;
function SortByIndex: Boolean;
var I: Integer;
    List: TList<TProperty>;
begin
 Result := False;
 List := TList<TProperty>.Create(TPropByIndex.Create);
 try
  for I := PD.Properties.Count - 1 downto 0 do
   if PD.Properties[I].Index > 0 then begin
    List.Add(PD.Properties[I]);
    PD.Properties.Properties.AtDelete(I);
    Result := True;
   end;
  List.Sort;
  for I := List.Count - 1 downto 0 do PD.Properties.Properties.AtInsert(0, List[I]);
 finally
  List.Free;
 end;
end;
begin
 if TwgForm = nil then exit;
 Changed := False;
 LNames := TListByName.Create;
 try
  LNames.LoadFromFile(AnsiString(DendroDictPath('Names.txt')), AnsiString(oghObjectType(TwgForm)));
  with TwgForm do
   for I := 0 to Twigs.AnyCount - 1 do begin
    PD := Twigs.AAt(I, B);
    if (B <> TWG_Point) or (PD.Properties = nil) then continue;
    if not (PD.What in [40, 97, 95, 34, 98, 99, 28, 103, 201]) then continue;
    if PD.GetProperty(OGHType) = byLayer then continue;
    Section := LNames.FindByName2(PD.GetProperty(OGHType), 0);
    if Section = nil then continue;
    for J := 0 to PD.Properties.Count - 1 do PD.Properties[J].Index := 0;
    CurrentIndex := 1;
    for J := 0 to Section.Count - 1 do begin
     Idx := PD.Properties.IndexOf('*' + Section.GetValueForIndex(J, 0));
     if Idx = -1 then continue;
     PD.Properties[Idx].Index := CurrentIndex;
     Inc(CurrentIndex);
    end;
    if SortByIndex then Changed := True;
   end;
 finally
  LNames.Free;
 end;
 if Changed and (PropEditorForm <> nil) and (SelectedObjects <> nil) then PropEditorForm.Update(SelectedObjects);
end;

// этажность здания по подписям внутри контура (odhGetFloors)
function GetFloors(TwgForm: TForm2; Lot: TLot): String;
var I, Max, Floor: Integer;
    PD: TPointDot;
    B: Byte;
    Material, S: String;
procedure Del(const Sub: String);
begin
 Material := StringReplace(Material, Sub, '', [rfReplaceAll]);
end;
begin
 Max := 1;
 with TwgForm do
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if not Lot.PointIn(Twigs, PD.XDot, PD.YDot) then continue;
   Material := '';
   if PD is TDotText then Material := String(TDotText(PD).Text.Text) else
   if PD.TextManager <> nil then Material := String(PD.TextManager.AttrValue('Этажность'));
   if Trim(Material) = '' then continue;
   Material := Trim(AnsiUpperCase(Material));
   S := Material;
   Del('МН'); Del('КН'); Del('Д'); Del('КЖ'); Del('СМН'); Del('СМЖ'); Del('Н'); Del('Ж');
   if S = Material then continue;
   Floor := StrToIntDef(Trim(Material), 0);
   if Floor > Max then Max := Floor;
  end;
 Result := IntToStr(Max);
end;

// автоматизация ДТ (TMasterReliefVersia.MIAutoProps): свойства по умолчанию из
// слоя (и по номеру знака '#<знак>'), количество/площадь/протяженность,
// принадлежность объекту, признак «Разновысотные отметки»
procedure TMainFormDendro.AutoProps;
var I: Integer;
    B: Byte;
    PD: TPointDot;
    Lot: TLot;
    Block: TGeoBlock;
    T: AnsiString;
function Num(V: Double; Digits: Integer): AnsiString;
begin
 Result := AnsiString(FloatToStrF(V, ffFixed, _LD, Digits));
end;
procedure SetPropRVO(Obj: TTD);
begin
 if AnsiLowerCase(String(Obj.GetProperty('*Признак «Разновысотные отметки»'))) <> 'да' then
  Obj.SetProperty('*Признак «Разновысотные отметки»', 'Нет');
end;
procedure SetProperties(Prim: TTD; Properties: TProperties; const Znak: String);
var I: Integer;
    St: TStrings;
    Props2: TProperties;
begin
 if Properties = nil then exit;
 gEqualCaseInsProps := False;
 try
  for I := 0 to Properties.Count - 1 do
   if Pos('*', String(Properties[I].PropName)) = 1 then
    if (Znak = '@') or (Prim.GetProperty(Properties[I].PropName) = byLayer) or (Prim.GetProperty(Properties[I].PropName) = '-') then
     Prim.SetProperty(Properties[I].PropName, Properties[I].PropValue.Value);
  if Znak = '@' then exit;
 // свойства по номеру знака: '#<знак>' = 'имя=значение;...'
  St := TStringList.Create;
  try
   for I := 0 to Properties.Count - 1 do
    if (Pos('#', String(Properties[I].PropName)) = 1) and (Znak = String(DelSubStr2(Properties[I].PropName, '#'))) then begin
     St.Text := String(MakeString(Properties[I].PropValue.Value, ';'));
     Props2 := TProperties.Create;
     try
      Props2.GetList(St);
      SetProperties(Prim, Props2, '@');
     finally
      Props2.Free;
     end;
    end;
  finally
   St.Free;
  end;
 finally
  gEqualCaseInsProps := True;
 end;
end;
procedure AddIn(PD: TPointDot; Prim: TTD);
var I, TL: Integer;
    L: TLot;
    S, Prin: AnsiString;
    Sel: TSelectedObjects;
    P: PCollection;
begin
 Prin := '-';
 with TwgForm do
  for I := Twigs.LotsCount - 1 downto 0 do begin
   L := Twigs.LAtIndex(I);
   if (L = Prim) or (L.TypeLot = 1) then continue;
   if L.PointIn(Twigs, PD.XDot, PD.YDot) then begin
    Prin := 'Иного типа';
    S := L.GetProperty(OGHType);
    if S <> byLayer then begin
     Prim.SetProperty('*Принадлежность объекту', S);
     exit;
    end;
   end;
  end;
// площадной контур внутри выбранного контура - 'Иного типа'
 Sel := SelectedObjects;
 if (Prim is TLot) and (TLot(Prim).TypeLot = 2) and (Sel <> nil) then
  for I := 0 to Sel.Count - 1 do
   if TObject(Sel[I]) is TLot then begin
    L := Sel[I];
    TL := L.TypeLot;
    if L.TypeLot = 1 then L.TypeLot := 2;
    P := TLot(Prim).Points;
    try
     L.SetSqwear(TwgForm.Twigs);
     if L.LotIn(TwgForm.Twigs, TLot(Prim)) then begin
      Prim.SetProperty('*Принадлежность объекту', 'Иного типа');
      exit;
     end;
    finally
     L.TypeLot := TL;
     if TL = 1 then L.Plo := 0;
     TLot(Prim).Points := P;
    end;
   end;
 Prim.SetProperty('*Принадлежность объекту', Prin);
end;
procedure ClearStarProps(Props: TProperties);
var I: Integer;
begin
 for I := Props.Count - 1 downto 0 do
  if Pos('*', String(Props[I].PropName)) = 1 then Props.Properties.AtFree(I);
end;
procedure AddPropertiesPoint;
begin
 if PD.Properties = nil then PD.Properties := TProperties.Create;
 if PD.ClassHandle <> nil then SetProperties(PD, PD.ClassHandle.Properties, IntToStr(PD.GetZnak));
 if PD.UseProperty('*Количество') then begin
  PD.SetProperty('*Количество', '1');
  PD.SetProperty('*Единица измерения', 'Штуки');
 end;
 SetPropRVO(PD);
 if not PD.UseProperty('*Принадлежность объекту') then exit;
 AddIn(PD, PD);
 if PD.GetProperty('*Принадлежность объекту') = '-' then ClearStarProps(PD.Properties);
end;
procedure AddPropertiesBlock;
var I: Integer;
begin
 for I := 0 to Block.Properties.Count - 1 do
  if Pos('*', String(Block.Properties[I].PropName)) = 1 then
   if (PD.Properties = nil) or (PD.GetProperty(Block.Properties[I].PropName) = byLayer) or (PD.GetProperty(Block.Properties[I].PropName) = '-') then
    PD.SetProperty(Block.Properties[I].PropName, Block.Properties[I].PropValue.Value);
 if PD.UseProperty('*Количество') then begin
  PD.SetProperty('*Количество', '1');
  PD.SetProperty('*Единица измерения', 'Штуки');
 end;
 SetPropRVO(PD);
 if not PD.UseProperty('*Принадлежность объекту') then exit;
 AddIn(PD, PD);
 if (PD.Properties <> nil) and (PD.GetProperty('*Принадлежность объекту') = '-') then ClearStarProps(PD.Properties);
end;
procedure AddPropertiesLot;
var ODN, MGN: AnsiString;
    UseODN, UseMGN: Boolean;
    D: TPointDot;
    Len: AnsiString;
procedure SetODN(Required: Boolean);
begin
 if (ODN = '0') or (ODN = '-') or Required then Lot.SetProperty('*Однолетники, кв.м.', Num(Lot.ClearPlo, Const_Of_DecimalSqwear));
end;
procedure SetMGN(Required: Boolean);
begin
 if (MGN = '0') or (MGN = '-') or Required then Lot.SetProperty('*Многолетники, кв.м.', Num(Lot.ClearPlo, Const_Of_DecimalSqwear));
end;
procedure SetLength;
begin
 Len := Num(Lot.GetLength(TwgForm.Twigs), Const_Of_DecimalLength);
 if Lot.UseProperty('*Количество') then begin
  Lot.SetProperty('*Количество', Len);
  Lot.SetProperty('*Единица измерения', 'Метры погонные');
 end;
 if Lot.UseProperty('*Количество, п.м.') then Lot.SetProperty('*Количество, п.м.', Len);
 if Lot.UseProperty('*Протяженность, п.м.') then Lot.SetProperty('*Протяженность, п.м.', Len);
end;
begin
 if Lot.Properties = nil then Lot.Properties := TProperties.Create;
 if Lot.ClassHandle <> nil then SetProperties(Lot, Lot.ClassHandle.Properties, IntToStr(Lot.csLineZnak));
// площадным - площадь, линейным - протяженность
 if Lot.TypeLot = 2 then begin
  if Lot.UseProperty('*Количество') then begin
   Lot.SetProperty('*Количество', Num(Lot.ClearPlo, Const_Of_DecimalSqwear));
   Lot.SetProperty('*Единица измерения', 'Метры квадратные');
  end;
  if Lot.UseProperty('*Площадь, кв.м.') then Lot.SetProperty('*Площадь, кв.м.', Num(Lot.ClearPlo, Const_Of_DecimalSqwear));
  if Lot.GetProperty(OGHType) = 'Цветники' then begin
   UseODN := Lot.UseProperty('*Однолетники, кв.м.');
   UseMGN := Lot.UseProperty('*Многолетники, кв.м.');
   ODN := Lot.GetProperty('*Однолетники, кв.м.');
   MGN := Lot.GetProperty('*Многолетники, кв.м.');
   if not UseODN then begin
    if UseMGN then SetMGN(False) else SetODN(True);
   end else
   if not UseMGN then SetODN(False) else
   if (MGN = '-') or (MGN = '0') then SetODN(False);
  end;
 end else
 if Lot.GetProperty(OGHType) = 'Деревья/Кустарники' then begin
  if Lot.ClassHandle = TwgForm.LayerTable.LayerName['Кустарник ряд'] then SetLength else begin
   Lot.DeleteProperty('*Протяженность, п.м.');
   Lot.DeleteProperty('*Количество, п.м.');
  end;
 end else
  SetLength;
 if not Lot.UseProperty('*Принадлежность объекту') then exit;
// ограждения и т.п.: принадлежность объекту по точке внутри контура
 Lot.SetProperty('*Принадлежность объекту', 'Иного типа');
 D := TPointDot.Create(0, 0, 0);
 try
  Lot.InsClipDotsParall(TwgForm.Twigs);
  Lot.GetPointIn(D, TwgForm.Twigs);
  AddIn(D, Lot);
 finally
  Lot.Points.Free;
  Lot.Points := nil;
  D.Free;
 end;
 if Lot.GetProperty('*Принадлежность объекту') = '-' then ClearStarProps(Lot.Properties);
end;
begin
 if TwgForm = nil then exit;
 with TwgForm do begin
  for I := 0 to LayerTable.LinearLayers.Count - 1 do LayerTable.LinearLayer[I].CreateProperties;
  try
  // площадные и линейные объекты
   for I := 0 to Twigs.LotsCount - 1 do begin
    Lot := Twigs.LAtIndex(I);
    if Lot.Closed = 0 then continue;
    AddPropertiesLot;
    if Lot.UseProperty('*Этажность') then Lot.SetProperty('*Этажность', AnsiString(GetFloors(TwgForm, Lot)));
    T := Lot.GetProperty(OGHType);
    if (T = 'Дворовые территории') and (Lot.GetProperty('*Список файлов') = byLayer) then Lot.SetProperty('*Список файлов', '-');
    if T = 'Места сбора отходов' then Lot.SetProperty('*ID', '-');
    if T = 'Системы функционального обеспечения' then begin
     if Lot.ClassHandle = LayerTable.LayerName['Дорожная разметка для аварийно-спасательной техники'] then
      Lot.SetProperty('*Признак «Разновысотные отметки»', 'Да') else SetPropRVO(Lot);
    end else
    if (T = 'Газоны') or (T = 'Объекты капитального строительства') or (T = 'Дорожно-тропиночные сети') or
       (T = 'Места сбора отходов') or (T = 'Плоскостные сооружения') or
       (T = 'Некапитальные объекты для обеспечения производственной деятельности по содержанию и ремонту территорий') or
       (T = 'Закрытые велопарковки для долгосрочного хранения велосипедов') or (T = 'Цветники') or
       (T = 'Элементы благоустройства для маломобильных групп населения') or (T = 'Элементы организации рельефа') or
       (T = 'Малые архитектурные формы и элементы благоустройства') or (T = 'Иные некапитальные объекты') or
       (T = 'Иной объект капитального строительства') or (T = 'Объекты озеленения') then SetPropRVO(Lot) else
    if T = 'Деревья/Кустарники' then begin
     SetPropRVO(Lot);
     if Lot.TypeLot = 2 then Lot.TypeLot := 1;
    end;
   end;
  // точечные объекты и блоки (МАФ)
   for I := 0 to Twigs.AnyCount - 1 do begin
    PD := Twigs.AAt(I, B);
    if (B <> TWG_Point) or PD.Closed or (PD.GetZnak = 5056) then continue;
    if PD.userObj is TGeoBlock then begin
     Block := TGeoBlock(PD.userObj);
     if Block.Properties <> nil then AddPropertiesBlock;
    end else
     AddPropertiesPoint;
   end;
  finally
   for I := 0 to LayerTable.LinearLayers.Count - 1 do LayerTable.LinearLayer[I].FreeProperties;
  end;
 end;
 DendroChanged(nil);
 MessageInform('Автоматизация ДТ выполнена');
end;

// автоматизация ЗН (TMasterReliefVersia.MIAutoZelenkaClick -> dtImportTrees):
// атрибуты растений из подписей знака, атрибуты групп - их контурам
procedure TMainFormDendro.ImportTrees;
var I, N: Integer;
    PD: TPointDot;
    B: Byte;
function ValidV(const V: AnsiString): Boolean;
begin
 Result := not ((V = byLayer) or (V = byNone) or (V = '-') or (V = ''));
end;
procedure ImportProps(Point: TPointDot);
function T(const S: AnsiString): AnsiString;
begin
 Result := DelSubStr2(S, '''');
 if (Result = byLayer) or (Result = '-') then Result := '';
end;
procedure SetSost(S: String);
procedure SetBoth(const Sost, Utoch: AnsiString);
begin
 Point.SetProperty('*Состояние', Sost);
 Point.SetProperty('*Уточнения состояния', Utoch);
end;
begin
 SetBoth('-', '-');
 S := AnsiLowerCase(S);
 if Pos('без признаков ослабления', S) <> 0 then SetBoth('Хорошее', 'без признаков ослабления') else
 if Pos('сильно ослабленные', S) <> 0 then SetBoth('Удовлетворительное', 'сильно ослабленное') else
 if Pos('ослабленные', S) <> 0 then SetBoth('Удовлетворительное', 'ослабленное') else
 if Pos('сухостой прошлых лет', S) <> 0 then SetBoth('Неудовлетворительное', 'сухостой прошлых лет') else
 if Pos('сухостой тек. года', S) <> 0 then SetBoth('Неудовлетворительное', 'сухостой текущего года') else
 if Pos('усыхающие', S) <> 0 then SetBoth('Неудовлетворительное', 'усыхающее') else
 if Pos('сухостой', S) <> 0 then SetBoth('Неудовлетворительное', 'cухостой прошлых лет');
 if Point.GetProperty('*Состояние') = '-' then Point.DeleteProperty('*Состояние');
 if Point.GetProperty('*Уточнения состояния') = '-' then Point.DeleteProperty('*Уточнения состояния');
end;
procedure SetProp(const PropName, PropValue: AnsiString);
begin
 if ValidV(Point.GetProperty(PropName)) then begin
  if PropValue <> '' then Point.SetProperty(PropName, PropValue);
 end else
 if PropValue <> '' then Point.SetProperty(PropName, PropValue) else Point.DeleteProperty(PropName);
end;
begin
 if Point.TextManager = nil then exit;
 with Point.TextManager do begin
  if (Point.Properties <> nil) and (Point.GetProperty('*№дерева') <> byLayer) then begin
   Point.DeleteProperty('*№растения');
   Point.Properties.RenameProperty('*№дерева', '*№Растения');
  end;
  SetProp('*Тип (ОГХ)', 'Деревья/Кустарники');
  SetProp('*№Участка', AttrValue('№ участка'));
  SetProp('*№Растения', AttrValue('№ растения'));
  Point.SetProperty('*№Биогруппы', '0');
  SetProp('*Тип насаждения', AttrValue('Тип насаждения'));
  SetProp('*Порода', T(AttrValue('Порода')));
  SetProp('*Характеристика состояния', T(AttrValue('Характеристика состояния')));
  SetProp('*Рекомендации по уходу', T(AttrValue('Рекомендации')));
  SetProp('*Количество, шт.', AttrValue('Количество (шт)'));
  SetProp('*Диаметр на высоте 1.3м., см.', AttrValue('Диаметр'));
  SetProp('*Возраст, лет', AttrValue('Возраст'));
  SetProp('*Высота, м.', AttrValue('Высота'));
  SetProp('*Жизненная форма ДИТ', AttrValue('Жизненная форма'));
  SetProp('*Площадь, кв.м.', AttrValue('Количество (кв.м)'));
  SetProp('*Акция Миллион деревьев', 'Нет');
  SetProp('*Протяженность, п.м.', AttrValue('Количество (пог.м)'));
  if ValidV(AttrValue('Состояние')) then SetSost(String(AttrValue('Состояние'))) else
  if not ValidV(Point.GetProperty('*Состояние')) then begin
   SetProp('*Состояние', 'Хорошее');
   SetProp('*Уточнения состояния', 'без признаков ослабления');
  end;
 end;
end;
// группа, изгородь, цветник: атрибуты точки - контуру, на линии которого она
procedure GetGroup(Point: TPointDot);
const Props: array[0..18] of AnsiString = ('*№Участка', '*№Растения', '*№Биогруппы', '*Тип насаждения', '*Порода',
       '*Характеристика состояния', '*Рекомендации по уходу', '*Количество, шт.', '*Диаметр на высоте 1.3м., см.',
       '*Возраст, лет', '*Высота, м.', '*Жизненная форма ДИТ', '*Площадь, кв.м.', '*Акция Миллион деревьев',
       '*Протяженность, п.м.', '*Состояние', '*Уточнения состояния', '*Признак «Особо ценные»',
       '*Признак «Разновысотные отметки»');
var I, J, K: Integer;
    Lot: TLot;
    Tw: TTwig;
    MM: Double;
    OnLine: Boolean;
begin
 if not (Point.GetZnak in [95, 98, 99, 28]) then exit;
 with TwgForm do
  for I := 0 to Twigs.LotsCount - 1 do begin
   Lot := Twigs.LAt(I);
   if (Lot.ClassHandle = nil) or (Lot.ClassHandle.Parent = nil) then continue;
   if Pos(AnsiLowerCase('Деревья'), AnsiLowerCase(String(Lot.ClassHandle.Parent.RecString))) <> 1 then continue;
   OnLine := False;
   for K := 0 to Lot.Coord.Count - 1 do begin
    Tw := Lot.GetTwig(Twigs, K);
    if (Tw <> nil) and (Tw.GetTwigDist(Point.XDot, Point.YDot, MM, MM) <= 0.03) then begin
     OnLine := True;
     break;
    end;
   end;
   if not OnLine then continue;
   Lot.SetProperty('*Тип (ОГХ)', 'Деревья/Кустарники');
   for J := 0 to High(Props) do Lot.SetProperty(Props[J], Point.GetProperty(Props[J]));
   if Lot.Properties <> nil then
    for J := Lot.Properties.Count - 1 downto 0 do
     if Lot.GetProperty(Lot.Properties[J].PropName) = byLayer then Lot.DeleteProperty(Lot.Properties[J].PropName);
  end;
end;
begin
 if TwgForm = nil then exit;
 with TwgForm do
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if B <> TWG_Point then continue;
   N := PD.GetZnak;
   if not (N in [40, 97, 34, 95, 98, 99, 28]) then continue;
   ImportProps(PD);
   GetGroup(PD);
  end;
 DendroChanged(nil);
 MessageInform('Автоматизация ЗН выполнена');
end;

// признак удаления для выбранных точечных ЗН (sbStatDeleteClick)
procedure TMainFormDendro.StatDelete(Restore: Boolean);
var I, Count: Integer;
    PD: TPointDot;
    Sel: TSelectedObjects;
begin
 Sel := SelectedObjects;
 if (Sel = nil) or (Sel.Count = 0) then begin
  MessageError('Выберите точечные ЗН');
  exit;
 end;
 Count := 0;
 for I := 0 to Sel.Count - 1 do begin
  if not (TObject(Sel[I]) is TPointDot) then continue;
  PD := Sel[I];
  if not (PD.What in [40, 97, 95, 34, 98, 99, 28, 103, 201]) then continue;
  if PD.Properties = nil then continue;
  if Restore then PD.Properties.DeleteProperty('#Статус') else PD.Properties.InsertProperty(0, '#Статус', 'Удаление');
  Inc(Count);
 end;
 if Count = 0 then MessageError('Выберите точечные ЗН') else begin
  DendroChanged(nil);
  MessageInform(AnsiString('Выполнено для ' + IntToStr(Count) + ' объектов ЗН'));
 end;
end;

// атрибуты газонов из точечных (MIPointZNLawnClick): номер участка газона из
// подписи №УУ знака 201 (по новой технологии - тип и состояние газона по
// цифрам номера) - газону и точечным ЗН на нем
procedure TMainFormDendro.PointZNLawn(OldNums: Boolean);
var I, Count, LotCount: Integer;
    PD: TPointDot;
    B: Byte;
    Lot: TLot;
function EduLawnPoint: Boolean;
var I, N: Integer;
    S, LawnS: String;
    Point: TPointDot;
    B: Byte;
procedure MarkDelete;
begin
 if PD.Properties = nil then PD.Properties := TProperties.Create;
 PD.Properties.InsertProperty(0, '#Статус', 'Удаление');
end;
begin
 Result := False;
 LawnS := String(PD.TextManager.AttrValue('№УУ'));
 if OldNums then begin
 // по старому алгоритму: не число - только цифры номера
  S := LawnS;
  if not TryStrToInt(LawnS, N) then begin
   S := '';
   for I := 1 to Length(LawnS) do
    if CharInSet(LawnS[I], ['0'..'9']) then S := S + LawnS[I];
  end;
  if S = '' then begin
   MarkDelete;
   exit;
  end;
  PD.TextManager.SetAttrValue('№УУ', AnsiString(S));
  PD.SetProperty('*№Участка', AnsiString(S));
  LawnS := S;
 end else begin
 // по новой технологии: две цифры - тип и состояние газона
  PD.SetProperty('*№Участка', AnsiString(LawnS));
  if Length(LawnS) <> 2 then exit;
  Result := True;
  if not TryStrToInt(LawnS, N) then begin
   MarkDelete;
   exit(False);
  end;
  case N mod 10 of
   1: PD.SetProperty('*Состояние газона', 'Хорошее');
   2: PD.SetProperty('*Состояние газона', 'Удовлетворительное');
   3: PD.SetProperty('*Состояние газона', 'Неудовлетворительное');
  end;
  case N div 10 of
   1: PD.SetProperty('*Тип газона', 'Обыкновенный');
   2: PD.SetProperty('*Тип газона', 'Луговой');
   3: PD.SetProperty('*Тип газона', 'Партерный');
   4: PD.SetProperty('*Тип газона', 'На откосе');
   5: PD.SetProperty('*Тип газона', 'Иного типа');
  end;
 end;
// газон: номер, тип, состояние - ему и точечным ЗН на нем
 if znPointIn(TwgForm, PD, Lot, False) and (Lot <> nil) then begin
  Lot.SetProperty('*№Участка', AnsiString(LawnS));
  Lot.SetProperty('*Тип газона', PD.GetProperty('*Тип газона'));
  Lot.SetProperty('*Состояние газона', PD.GetProperty('*Состояние газона'));
  with TwgForm do
   for I := 0 to Twigs.AnyCount - 1 do begin
    Point := Twigs.AAt(I, B);
    if (B <> TWG_Point) or not (Point.What in [40, 97, 95, 34, 98, 99, 28]) then continue;
    if not Lot.PointIn(Twigs, Point.XDot, Point.YDot) then continue;
    if Point.TextManager <> nil then
     if Point.What = 28 then Point.SetProperty('*№Растения', Point.TextManager.AttrValue('PLANT_ID')) else
      Point.SetProperty('*№Растения', Point.TextManager.AttrValue('№ растения'));
    Point.SetProperty('*№Участка', AnsiString(LawnS));
   end;
  Inc(LotCount);
 end else
  PD.SetProperty('#Статус', 'Удаление');
end;
begin
 if TwgForm = nil then exit;
 Count := 0;
 LotCount := 0;
 with TwgForm do begin
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if (B = TWG_Point) and (PD.GetZnak = 201) and (PD.TextManager <> nil) and EduLawnPoint then Inc(Count);
  end;
 // номер растения и участка - контурам групп
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if (B <> TWG_Point) or not (PD.What in [40, 97, 95, 34, 98, 99, 28]) then continue;
   if znPointIn(TwgForm, PD, Lot, False) and (Lot <> nil) then begin
    Lot.SetProperty('*№Растения', PD.GetProperty('*№Растения'));
    Lot.SetProperty('*№Участка', PD.GetProperty('*№Участка'));
   end;
  end;
 end;
 DendroChanged(nil);
 MessageInform(AnsiString('Обучено: ' + IntToStr(Count) + ' точечных, ' + IntToStr(LotCount) + ' площадных газонов'));
end;

// экспорт фотофиксации (N3Click): блоки Foto_X с номером - Номер;X;Y
procedure TMainFormDendro.ExportFoto;
const Sep = ';';
var I: Integer;
    PD: TPointDot;
    B: Byte;
    Block: TGeoBlock;
    St: TStrings;
begin
 if TwgForm = nil then exit;
 St := TStringList.Create;
 St.Add('Номер' + Sep + 'X' + Sep + 'Y');
 with TwgForm do
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if not (PD.userObj is TGeoBlock) then continue;
   Block := TGeoBlock(PD.userObj);
   if Block.Name <> 'Foto_X' then continue;
   if Block.GetProperty('Номер') = byLayer then continue;
   St.Add(String(PD.GetProperty('Номер')) + Sep + CsvFloatStr(-PD.YDot) + Sep + CsvFloatStr(PD.XDot));
  end;
 DendroSaveFile(Self, String(TwgForm.About.Path), 'Фотофиксация.csv',
  procedure(FileName: String)
  begin
   try
    if FileName = '' then exit;
    CsvSave(St, FileName);
    MessageInform(AnsiString(IntToStr(St.Count - 1) + ' точек фотофиксации сохранено в файле ' + FileName));
   finally
    St.Free;
   end;
  end);
end;

// экспорт трека (N5Click): контуры слоя Корректура_фотофиксация - номер
// трека (подпись начала/конца, знак 2003), X;Y точки, Geometry 'X,Y|X,Y...'
procedure TMainFormDendro.ExportTrack;
var Pr: TResource;
    Lot: TLot;
    St: TStrings;
    S: String;
    I: Integer;
function FindPoint: String;
var I, J: Integer;
    PD: TPointDot;
    B: Byte;
    D: TDot;
begin
 Result := '';
 if Lot.Points.Count = 0 then exit;
 with TwgForm do
  for I := 0 to Twigs.AnyCount - 1 do begin
   PD := Twigs.AAt(I, B);
   if (B <> TWG_Point) or (PD.ClassHandle <> Pr) or (PD.What <> 2003) or (PD.TextManager = nil) then continue;
   if Selector.EqualPoints(PD, Lot.Points[0]) then begin
    Result := String(PD.TextManager.AttrValue('Трек_начало')) + ';' + CsvFloatStr(-PD.YDot) + ';' + CsvFloatStr(PD.XDot) + ';';
    break;
   end;
   if Selector.EqualPoints(PD, Lot.Points[Lot.Points.Count - 1]) then begin
    Result := String(PD.TextManager.AttrValue('Трек_конец')) + ';' + CsvFloatStr(-PD.YDot) + ';' + CsvFloatStr(PD.XDot) + ';';
    break;
   end;
  end;
 if Result = '' then Result := ';;;';
 for J := 0 to Lot.Points.Count - 1 do begin
  D := TDot(Lot.Points[J]);
  Result := Result + CsvFloatStr(-D.YDot) + ',' + CsvFloatStr(D.XDot);
  if J <> Lot.Points.Count - 1 then Result := Result + '|';
 end;
end;
begin
 if TwgForm = nil then exit;
 Pr := TwgForm.LayerTable.LayerName['Корректура_фотофиксация'];
 if Pr = nil then begin
  MessageError('Не найден слой "Корректура_фотофиксация"');
  exit;
 end;
 St := TStringList.Create;
 St.Add('Номер трека;X;Y;Geometry');
 with TwgForm do
  for I := 0 to Twigs.LotsCount - 1 do begin
   Lot := Twigs.LAt(I);
   if Lot.ClassHandle <> Pr then continue;
   Lot.InsClipDotsParall(Twigs);
   try
    S := FindPoint;
    if S <> '' then St.Add(S);
   finally
    Lot.Points.Free;
    Lot.Points := nil;
   end;
  end;
 DendroSaveFile(Self, String(TwgForm.About.Path), 'Трек.csv',
  procedure(FileName: String)
  begin
   try
    if FileName = '' then exit;
    CsvSave(St, FileName);
    MessageInform(AnsiString(IntToStr(St.Count - 1) + ' треков сохранено в файле ' + FileName));
   finally
    St.Free;
   end;
  end);
end;

end.
