unit DropDownButton;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Forms, newProcs;

type
  TDropDownButton = class(TLayout)
  private
   FButton: TButton;
   FPopup: TPopup;
   FOverlay: TLayout;
   FContent: TControl;
   FPopupMinWidth: Single;
   FPopupMinHeight: Single;
   procedure EnsureControls;
   procedure EnsureOverlay;
   procedure ButtonClick(Sender: TObject);
   procedure OverlayMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
   procedure PopupClosed(Sender: TObject);
   procedure SetContent(const Value: TControl);
   function GetText: string;
   procedure SetText(const Value: string);
   function MainForm: TCommonCustomForm;
   procedure AlignPopup;
  protected
   procedure DoResized; override;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure Open;
   procedure Close;
   function IsOpen: Boolean;
   property Popup: TPopup read FPopup;
  published
   property Align;
   property Position;
   property Size;
   property Margins;
   property Padding;
   property Text: string read GetText write SetText;
   property Content: TControl read FContent write SetContent;
   property PopupMinWidth: Single read FPopupMinWidth write FPopupMinWidth;
   property PopupMinHeight: Single read FPopupMinHeight write FPopupMinHeight;
  end;

implementation

{ TDropDownButton }

constructor TDropDownButton.Create(AOwner: TComponent);
begin
 inherited;
 FPopupMinWidth := 0;
 FPopupMinHeight := 0;
 EnsureControls;
end;

destructor TDropDownButton.Destroy;
begin
 if FOverlay <> nil then FOverlay.Free;
 if FPopup <> nil then FPopup.Free;
 if FButton <> nil then FButton.Free;
 inherited;
end;

procedure TDropDownButton.DoResized;
begin
 inherited;
 if (FButton <> nil) then
 begin
  FButton.Align := TAlignLayout.Client;
 end;
 if (FPopup <> nil) and FPopup.IsOpen then
  AlignPopup;
end;

procedure TDropDownButton.EnsureControls;
begin
 if FButton = nil then
 begin
  FButton := TButton.Create(Self);
  FButton.Parent := Self;
  FButton.Align := TAlignLayout.Client;
  FButton.Stored := False;
  FButton.OnClick := ButtonClick;
 end;

 if FPopup = nil then
 begin
  FPopup := TPopup.Create(Self);
  FPopup.Parent := Self;
  FPopup.Stored := False;
  FPopup.Visible := False;
  FPopup.PlacementTarget := FButton;
  FPopup.Placement := TPlacement.Bottom;
  FPopup.OnClosePopup := PopupClosed;
 end;
end;

procedure TDropDownButton.EnsureOverlay;
var F: TCommonCustomForm;
begin
 if FOverlay <> nil then Exit;
 F := MainForm;
 if F = nil then Exit;
 FOverlay := TLayout.Create(Self);
 FOverlay.Parent := F;
 FOverlay.Align := TAlignLayout.Client;
 FOverlay.Stored := False;
 FOverlay.Visible := False;
 FOverlay.HitTest := True;
 FOverlay.Opacity := 0;
 FOverlay.OnMouseDown := OverlayMouseDown;
end;

function TDropDownButton.GetText: string;
begin
 EnsureControls;
 if FButton = nil then Result := '' else Result := FButton.Text;
end;

procedure TDropDownButton.SetText(const Value: string);
begin
 EnsureControls;
 if FButton <> nil then FButton.Text := Value;
end;

function TDropDownButton.MainForm: TCommonCustomForm;
begin
 Result := ApplicationMainForm;
end;

function TDropDownButton.IsOpen: Boolean;
begin
 if FPopup = nil then Result := False else Result := FPopup.IsOpen;
end;

procedure TDropDownButton.Open;
begin
 EnsureControls;
 EnsureOverlay;
 if (FPopup = nil) or (FButton = nil) then Exit;
 if FPopup.IsOpen then Exit;

 if (FContent <> nil) and (FContent.Parent <> FPopup) then
  FContent.Parent := FPopup;

 if (FPopupMinWidth > 0) and (FPopup.Width < FPopupMinWidth) then
  FPopup.Width := FPopupMinWidth;
 if (FPopupMinHeight > 0) and (FPopup.Height < FPopupMinHeight) then
  FPopup.Height := FPopupMinHeight;

 AlignPopup;

 if FOverlay <> nil then
 begin
  FOverlay.Visible := True;
  FOverlay.BringToFront;
 end;

 FPopup.IsOpen := True;
 FPopup.BringToFront;
end;

procedure TDropDownButton.Close;
begin
 if FPopup <> nil then
  FPopup.IsOpen := False;
 if FOverlay <> nil then
  FOverlay.Visible := False;
end;

procedure TDropDownButton.ButtonClick(Sender: TObject);
begin
 if IsOpen then Close else Open;
end;

procedure TDropDownButton.OverlayMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
 Close;
end;

procedure TDropDownButton.PopupClosed(Sender: TObject);
begin
 if FOverlay <> nil then
  FOverlay.Visible := False;
end;

procedure TDropDownButton.AlignPopup;
var
 BtnScr, BtnScrTop: TPointF;
 FormScrTL: TPointF;
 FormScrBR: TPointF;
 PopupW, PopupH: Single;
 PlaceBelow: Boolean;
 XOff: Single;
begin
 if (FPopup = nil) or (FButton = nil) then Exit;
 if MainForm = nil then Exit;

 PopupW := FPopup.Width;
 PopupH := FPopup.Height;

 BtnScr := FButton.LocalToScreen(PointF(0, FButton.Height));
 BtnScrTop := FButton.LocalToScreen(PointF(0, 0));

 FormScrTL := MainForm.ClientToScreen(PointF(0, 0));
 FormScrBR := MainForm.ClientToScreen(PointF(MainForm.ClientWidth, MainForm.ClientHeight));

 PlaceBelow := (BtnScr.Y + PopupH <= FormScrBR.Y);
 if not PlaceBelow then
  FPopup.Placement := TPlacement.Top
 else
  FPopup.Placement := TPlacement.Bottom;

 FPopup.PlacementTarget := FButton;

 XOff := 0;
 if (BtnScr.X + XOff < FormScrTL.X) then
  XOff := FormScrTL.X - BtnScr.X;
 if (BtnScr.X + XOff + PopupW > FormScrBR.X) then
  XOff := FormScrBR.X - (BtnScr.X + PopupW);

 FPopup.HorizontalOffset := XOff;
 if PlaceBelow then
  FPopup.VerticalOffset := 0
 else
  FPopup.VerticalOffset := 0;
end;

procedure TDropDownButton.SetContent(const Value: TControl);
begin
 if FContent = Value then Exit;
 FContent := Value;
 EnsureControls;
 if (FContent <> nil) and (FPopup <> nil) then
  FContent.Parent := FPopup;
end;

end.
