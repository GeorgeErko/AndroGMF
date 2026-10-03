unit FrameObjects;

// Перенос всплывающего меню FlyObjects.PMEditMap (Geomaster): команды над
// выделенными объектами TEditMap (objEditMap32). Меню - TPopup (в отличие от
// TPopupMenu работает на всех платформах FMX). Как в старой программе:
// TEditMap при создании берет меню (PopUpMenu := ObjectsFrame.PMEditMap) и
// показывает его по правому клику (MouseRightDown -> PopUpMenuPopUp).
// Tag пункта - код команды TEditMap (em_*), выполняется TEditMap.DoCommand;
// доступность пунктов - TEditMap.CommandEnabled (бывший PMEditMapPopup).
// Фрейм создается формой один раз (глобальная ссылка ObjectsFrame).

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes,
     FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Layouts,
     FMX.ListBox, FMX.Controls.Presentation, objEditMap32;

type
 TObjectsFrame = class(TFrame)
   PMEditMap: TPopup;
   lbEditMap: TListBox;
   lbiSelectNone: TListBoxItem;
   lbiSelectInvert: TListBoxItem;
   lbSep1: TListBoxSeparatorItem;
   lbiDelete: TListBoxItem;
   lbSep2: TListBoxSeparatorItem;
   lbiCopy: TListBoxItem;
   lbSep3: TListBoxSeparatorItem;
   lbiMove: TListBoxItem;
   lbiRotate: TListBoxItem;
   lbiRotate90: TListBoxItem;
   lbiRotate180: TListBoxItem;
   lbiRotate270: TListBoxItem;
   lbiMirror: TListBoxItem;
   lbiScale: TListBoxItem;
   procedure PMEditMapPopup(Sender: TObject);
   procedure lbEditMapItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
  public
   EditMap: TEditMap; // текущий обработчик выделения (бывший V25.MouseObject)
   Constructor Create(AOwner: TComponent); override;
   Destructor Destroy; override;
 end;

var ObjectsFrame: TObjectsFrame;

implementation

{$R *.fmx}

constructor TObjectsFrame.Create(AOwner: TComponent);
begin
 inherited;
 ObjectsFrame := Self;
end;

destructor TObjectsFrame.Destroy;
begin
 if ObjectsFrame = Self then ObjectsFrame := nil;
 inherited;
end;

procedure TObjectsFrame.PMEditMapPopup(Sender: TObject);
var I: Integer;
    Item: TListBoxItem;
begin
 lbEditMap.ItemIndex := -1;
 for I := 0 to lbEditMap.Count - 1 do begin
  Item := lbEditMap.ListItems[I];
  if Item.Tag <> 0 then Item.Enabled := (EditMap <> nil) and EditMap.CommandEnabled(Item.Tag);
 end;
end;

procedure TObjectsFrame.lbEditMapItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
var Tag: Integer;
begin
 if (Item = nil) or (Item.Tag = 0) or not Item.Enabled then exit;
 Tag := Item.Tag;
// меню закрывается и команда выполняется после выхода из обработчика списка:
// при закрытии TPopup его содержимое (и сам список) переносится обратно
 TThread.ForceQueue(nil, procedure
  begin
   if ObjectsFrame <> Self then exit;
   PMEditMap.IsOpen := False;
   if EditMap <> nil then EditMap.DoCommand(Tag);
  end);
end;

end.
