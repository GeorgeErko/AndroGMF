unit AppForms;

// Базовые классы форм и фреймов программы: размеры интерфейса из AppUI.
// Перекрывающие классы (interposer): TForm и TFrame здесь - наследники
// FMX.Forms.TForm/TFrame. Модуль формы или фрейма пишет, как обычно,
// class(TForm)/class(TFrame) - дизайнер видит обычную форму и фрейм (с
// предком другого имени фрейм открывался в дизайнере как форма), а компилятор
// берет классы отсюда, если AppForms стоит в uses после FMX.Forms.
// TForm - главные формы и диалоги, TFrame - фреймы (панели и
// псевдо-диалоги поверх карты). В Loaded и при смене профиля или масштаба UI
// (TUIMetricsChangedMessage) вызывается ApplyUI: снятие закрепленных стилем
// платформы высот и правила кнопок (AppUI.ApplyUIRules). Наследник дополняет ApplyUI своими размерами.
// Фрейм непрозрачен (Opaque, по умолчанию True): FMX-фрейм и TLayout не имеют
// фона, и через псевдо-диалог на Android просвечивала карта. Фон - прямоугольник
// цвета UI.PanelColor с рамкой UI.PanelBorderColor под всеми элементами
// фрейма; он же перехватывает касания (до карты не доходят). Встроенным
// панелям со своим фоном (таблица слоев в тулбаре, панель GPS) - Opaque := False
// в конструкторе.

interface

uses
  System.SysUtils, System.Classes, System.Messaging, FMX.Types, FMX.Controls, FMX.Forms, FMX.Objects;

type
  TForm = class(FMX.Forms.TForm)
  private
    FUIMessageId: Integer;
    procedure UIMetricsChanged(const Sender: TObject; const M: TMessage);
  protected
    procedure Loaded; override;
   // размеры UI - элементам формы
    procedure ApplyUI; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFrame = class(FMX.Forms.TFrame)
  private
    FUIMessageId: Integer;
    FOpaque: Boolean;
    FBackground: TRectangle;
    procedure UIMetricsChanged(const Sender: TObject; const M: TMessage);
    procedure SetOpaque(const Value: Boolean);
    procedure UpdateBackground;
  protected
    procedure Loaded; override;
   // размеры и фон UI - элементам фрейма
    procedure ApplyUI; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
   // непрозрачный фон с рамкой (по умолчанию True)
    property Opaque: Boolean read FOpaque write SetOpaque;
  end;

implementation

uses AppUI;

{ TForm }

constructor TForm.Create(AOwner: TComponent);
begin
 FUIMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TUIMetricsChangedMessage, UIMetricsChanged);
 inherited;
end;

destructor TForm.Destroy;
begin
 TMessageManager.DefaultManager.Unsubscribe(TUIMetricsChangedMessage, FUIMessageId);
 inherited;
end;

// образцы стиля формы исправляются до первой отрисовки, элементы - после загрузки
procedure TForm.Loaded;
begin
 UnfixFormButtonHeights(Self);
 inherited;
 ApplyUI;
end;

procedure TForm.ApplyUI;
begin
 ApplyUIRules(Self);
end;

procedure TForm.UIMetricsChanged(const Sender: TObject; const M: TMessage);
begin
 ApplyUI;
end;

{ TFrame }

constructor TFrame.Create(AOwner: TComponent);
begin
 FOpaque := True;
 FUIMessageId := TMessageManager.DefaultManager.SubscribeToMessage(TUIMetricsChangedMessage, UIMetricsChanged);
 inherited;
end;

destructor TFrame.Destroy;
begin
 TMessageManager.DefaultManager.Unsubscribe(TUIMetricsChangedMessage, FUIMessageId);
 inherited;
end;

procedure TFrame.Loaded;
begin
 inherited;
 ApplyUI;
end;

procedure TFrame.ApplyUI;
begin
 ApplyUIRules(Self);
 UpdateBackground;
end;

procedure TFrame.UIMetricsChanged(const Sender: TObject; const M: TMessage);
begin
 ApplyUI;
end;

procedure TFrame.SetOpaque(const Value: Boolean);
begin
 if FOpaque = Value then exit;
 FOpaque := Value;
 UpdateBackground;
end;

// фон - первым дочерним (под остальными), Align = Contents: отступы и
// выравнивание элементов фрейма не меняются; не сохраняется в fmx
procedure TFrame.UpdateBackground;
begin
 if not FOpaque then begin
  FreeAndNil(FBackground);
  exit;
 end;
 if FBackground = nil then begin
  FBackground := TRectangle.Create(Self);
  FBackground.Stored := False;
  FBackground.Locked := True;
  FBackground.Align := TAlignLayout.Contents;
  FBackground.Parent := Self;
  FBackground.SendToBack;
 end;
 FBackground.Fill.Color := UI.PanelColor;
 FBackground.Stroke.Color := UI.PanelBorderColor;
 FBackground.Stroke.Thickness := 1;
 FBackground.HitTest := True;
end;

end.
