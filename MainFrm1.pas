unit MainFrm1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrm, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Objects, FMX.Skia, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo;

type
  TMainForm1 = class(TMainForm)
    SkPaintBox1: TSkPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PainterClick(Sender: TObject);
    procedure SkPaintBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm1: TMainForm1;

implementation

{$R *.fmx}

procedure TMainForm1.FormCreate(Sender: TObject);
begin
  inherited;
 //
end;

procedure TMainForm1.FormDestroy(Sender: TObject);
begin
  inherited;
 //
end;

procedure TMainForm1.PainterClick(Sender: TObject);
begin
  inherited;
 ShowMessage('1');
end;

procedure TMainForm1.SkPaintBox1Click(Sender: TObject);
begin
  inherited;
  ShowMessage('1');
end;

end.
