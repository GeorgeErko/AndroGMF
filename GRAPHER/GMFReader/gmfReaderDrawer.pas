unit gmfReaderDrawer;

interface

uses System.Classes, ogcBasic, ogcDrawerSkia;

// Невизуальный рисователь читателя GMF в библиотеке gmfreader.
// Selector и примитивы обращаются к Drawer за областью окна:
// Width/Height -> ActiveRect, XPix/YPix, geoDist.
// Наследник TogsDrawerSkia, а не TogsDrawer: модули GMF проверяют
// Drawer is TogsDrawerSkia и тогда измеряют текст средствами Skia
// (TDWG_Text.GetParams -> MeasureTextSkia); иначе вызывается старый
// TFontViewEx.GetTextLen, у которого в FMX-порте FontScales = nil.
// Канвы нет (SkCanvas = nil, SkPainter = nil) -> рисование не выполняется.

type

  { TgmfReaderDrawer }

  TgmfReaderDrawer = class(TogsDrawerSkia)
  public
  // размер условного окна в пикселах
   constructor CreateSize(Width_, Height_: Integer);
  end;

implementation

{ TgmfReaderDrawer }

constructor TgmfReaderDrawer.CreateSize(Width_, Height_: Integer);
begin
 inherited Create(nil, nil, nil);
 Width := Width_;
 Height := Height_;
 Disable := True;
end;

end.
