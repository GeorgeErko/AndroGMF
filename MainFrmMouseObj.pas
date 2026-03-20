unit MainFrmMouseObj;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  MainFrmSkia, FMX.Memo.Types, System.Skia, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.Skia, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo;

type
  TMainFormMouseObj = class(TMainFormSkia)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainFormMouseObj: TMainFormMouseObj;

implementation

{$R *.fmx}

end.
