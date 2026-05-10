unit DlgPropFontEditor;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListBox,
  FMX.Skia,
  DlgRootPropEditor, FMX.Controls.Presentation, System.Skia, FMX.Layouts;

type
  TPropFontEditorForm = class(TRootPropEditorForm)
    ListBox1: TListBox;
    SkPreview: TSkPaintBox;
  private
    FUpdating: Boolean;
    FSelectedFile: string;
    procedure FillFontsFromMainPath(const SelectedFamily: string);
    procedure ListBoxChange(Sender: TObject);
    procedure PreviewDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
    procedure ItemDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
  public
    function Execute(Row: TPropRow): String;
  end;

var
  PropFontEditorForm: TPropFontEditorForm;

implementation uses newProcs, newFontScale;

{$R *.fmx}

procedure TPropFontEditorForm.ItemDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var PB: TSkPaintBox;
    It: TListBoxItem;
    FileName: string;
    Typeface: ISkTypeface;
    Paint: ISkPaint;
    Font: ISkFont;
    S: string;
    X, Y: Single;
begin
 PB := TSkPaintBox(ASender);
 if (PB = nil) or (PB.Parent = nil) or not (PB.Parent is TListBoxItem) then Exit;
 It := TListBoxItem(PB.Parent);
 FileName := It.TagString;
 S := It.Text;

 Typeface := nil;
 if FileName <> '' then
  try
   Typeface := TSkTypeface.MakeFromFile(FileName);
  except
  end;

 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Color := $FF000000;
 Font := TSkFont.Create(Typeface, 16);

 X := ADest.Left + 8;
 Y := ADest.Top + (ADest.Height + 16) / 2;
 ACanvas.DrawSimpleText(S, X, Y, Font, Paint);
end;

procedure TPropFontEditorForm.PreviewDraw(ASender: TObject; const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var Typeface: ISkTypeface;
    Paint: ISkPaint;
    Font: ISkFont;
    S: string;
    X, Y: Single;
begin
 S := 'The quick brown fox jumps over the lazy dog 0123456789';
 Typeface := nil;
 if FSelectedFile <> '' then
  try
   Typeface := TSkTypeface.MakeFromFile(FSelectedFile);
  except
  end;
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Color := $FF000000;
 Font := TSkFont.Create(Typeface, 18);
 X := ADest.Left + 8;
 Y := ADest.Top + (ADest.Height + 18) / 2;
 ACanvas.DrawSimpleText(S, X, Y, Font, Paint);
end;

procedure TPropFontEditorForm.FillFontsFromMainPath(const SelectedFamily: string);
var Dir: string;
    Files: TStringDynArray;
    F: string;
    TF: ISkTypeface;
    Fam: string;
    It: TListBoxItem;
begin
 if ListBox1 = nil then Exit;
 FUpdating := True;
 try
  ListBox1.Clear;
  Dir := MainPath;
  if Dir = '' then Exit;
  try
   Files := TDirectory.GetFiles(Dir, '*.ttf');
   for F in Files do
   begin
    TF := TSkTypeface.MakeFromFile(F);
    Fam := '';
    if TF <> nil then Fam := TF.FamilyName;
    if Fam = '' then Fam := TPath.GetFileNameWithoutExtension(F);
    RegisterSkiaFontFile(Fam, F);
    It := TListBoxItem.Create(ListBox1);
    It.Parent := ListBox1;
    It.Text := Fam;
    It.TagString := F;
    It.Height := ListBox1.ItemHeight;
    It.TextSettings.FontColor := $00000000;
    It.StyledSettings := It.StyledSettings - [TStyledSetting.FontColor];
    with TSkPaintBox.Create(It) do
    begin
     Stored := False;
     Parent := It;
     Align := TAlignLayout.Client;
     HitTest := False;
     OnDraw := ItemDraw;
    end;
    if SameText(Fam, SelectedFamily) then
     ListBox1.ItemIndex := It.Index;
   end;
  except
  end;
  try
   Files := TDirectory.GetFiles(Dir, '*.otf');
   for F in Files do
   begin
    TF := TSkTypeface.MakeFromFile(F);
    Fam := '';
    if TF <> nil then Fam := TF.FamilyName;
    if Fam = '' then Fam := TPath.GetFileNameWithoutExtension(F);
    RegisterSkiaFontFile(Fam, F);
    It := TListBoxItem.Create(ListBox1);
    It.Parent := ListBox1;
    It.Text := Fam;
    It.TagString := F;
    It.Height := ListBox1.ItemHeight;
    It.TextSettings.FontColor := $00000000;
    It.StyledSettings := It.StyledSettings - [TStyledSetting.FontColor];
    with TSkPaintBox.Create(It) do
    begin
     Stored := False;
     Parent := It;
     Align := TAlignLayout.Client;
     HitTest := False;
     OnDraw := ItemDraw;
    end;
    if SameText(Fam, SelectedFamily) then
     ListBox1.ItemIndex := It.Index;
   end;
  except
  end;
 finally
  FUpdating := False;
 end;
end;

procedure TPropFontEditorForm.ListBoxChange(Sender: TObject);
var It: TListBoxItem;
begin
 if FUpdating then Exit;
 if (ListBox1 = nil) or (ListBox1.ItemIndex < 0) then Exit;
 It := ListBox1.ListItems[ListBox1.ItemIndex];
 if It <> nil then
  FSelectedFile := It.TagString
 else
  FSelectedFile := '';
 if SkPreview <> nil then SkPreview.Redraw;
end;

function TPropFontEditorForm.Execute(Row: TPropRow): String;
var Sel: string;
    Res: TModalResult;
begin
 LoadPosition;
 Sel := '';
 if (Row <> nil) and (Row.Value <> '') and (Row.Value <> byLayer) then
  Sel := Row.Value;
 FillFontsFromMainPath(Sel);
 if ListBox1 <> nil then ListBox1.OnChange := ListBoxChange;
 if SkPreview <> nil then SkPreview.OnDraw := PreviewDraw;
 if (ListBox1 <> nil) and (ListBox1.ItemIndex >= 0) then
  ListBoxChange(ListBox1);
 fResult := '';
 Res := ShowModal;
 if (fResult = byLayer) then
 begin
  Result := byLayer;
  Exit;
 end;
 if Res = mrCancel then
 begin
  fResult := '';
  Result := '';
 end
 else
 begin
  if (ListBox1 <> nil) and (ListBox1.ItemIndex >= 0) then
   fResult := ListBox1.Items[ListBox1.ItemIndex]
  else
   fResult := '';
  Result := fResult;
 end;
 SavePosition;
end;

end.
