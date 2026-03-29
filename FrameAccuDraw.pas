unit FrameAccuDraw;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation;

const
  prim_Line = 1;
  prim_Rect = 2;
  prim_Arc = 3;
  prim_Circle = 4;
  prim_Koef = 5;
  prim_Coord = 6;

type
  TAccuDrawFrame = class(TFrame)
    pLine: TPanel;
    C1: TCheckBox;
    E1: TEdit;
    CA: TCheckBox;
    EA: TEdit;
    pRect: TPanel;
    C2: TCheckBox;
    E2: TEdit;
    C3: TCheckBox;
    E3: TEdit;
    pArc: TPanel;
    CR: TCheckBox;
    ER: TEdit;
    pKoef: TPanel;
    CK: TCheckBox;
    EK: TEdit;
  private
    fOnReturn: TNotifyEvent;
    procedure SetAutoSize(const Value: boolean);
  public
   Distance:Double;
   Angle:Double;
   DirectAngle:Double;
   useDirectAngle:Boolean;
   useIncrementDistance:Boolean;
   Koef:Double;
   PrimType:Integer;
   X,Y:Double;
   useLevels:boolean;
   procedure ResetPrim(PrimType_:Integer;Key:Char);
   property AutoSize:boolean write SetAutoSize;
   procedure SetChar(E:TEdit;Key:Char);
  //
   Property OnReturn: TNotifyEvent read fOnReturn write fOnReturn;
  end;

var GlobalAccuDraw: TAccuDrawFrame;

implementation

{$R *.fmx}

{ TAccuDrawFrame }

procedure TAccuDrawFrame.ResetPrim(PrimType_:Integer;Key:Char);
function isNumericKey:boolean;
begin
 Result:=Key in ['0'..'9','.']
end;
begin
 useDirectAngle:=False;
 PrimType:=PrimType_;
 pLine.Visible:=False;
 pRect.Visible:=False;
 pArc.Visible:=False;
 pKoef.Visible:=False;
 Case PrimType of
  prim_Line:begin pLine.Visible:=True;end;
  prim_Rect:pRect.Visible:=True;
  prim_Arc,
  prim_Circle:pArc.Visible:=True;
  prim_Koef:pKoef.Visible:=True;
 end;
 AutoSize:=True;
 Show;
 Case PrimType of
  prim_Line:If Key in ['a','A','ô','Ô','D','d','Â','â'] then begin
             If Key in ['D','d','Â','â'] then useDirectAngle:=True else useDirectAngle:=False;
             EA.SetFocus;
            end else
            If Key in ['+','='] then begin
             E1.SetFocus;
             SetChar(TEdit(E1),'+');
            end else begin
             E1.SetFocus;If isNumericKey then
             SetChar(TEdit(E1),Key);
            end;
  prim_Rect:begin E2.SetFocus;if isNumericKey then SetChar(TEdit(E2),Key);end;
  prim_Arc,
  prim_Circle:begin
               ER.SetFocus;if isNumericKey then SetChar(TEdit(ER),Key);
              end;
  prim_Koef:begin
              EK.SetFocus;if isNumericKey then SetChar(TEdit(ER),Key);
            end;
 end;
end;

procedure TAccuDrawFrame.SetAutoSize(const Value: boolean);
begin
//
end;

procedure TAccuDrawFrame.SetChar(E: TEdit; Key: Char);
begin
 E.Text := ''; E.Text:=Key; If Key='.' then E.Text:='0.';
 E.GoToTextEnd;
// SendMessage(E.Handle,WM_KeyDown,VK_END,0);
end;

end.
