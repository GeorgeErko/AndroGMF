unit FlyDraw1;

interface uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, FlyGeoMaster, Buttons, ResSpeedBtn, ExtCtrls, SzPanel, Menus,
  sSpeedButton;

type
  TFlyPainter = class(TFlyFormGeoMaster)
    RbPoint1: TResSpeedBtn;
    RbLine1: TResSpeedBtn;
    RbArc1: TResSpeedBtn;
    RbSpline1: TResSpeedBtn;
    RbCircle1: TResSpeedBtn;

    RbRect1: TResSpeedBtn;
    RbPolygon1: TResSpeedBtn;
    RbLine2: TResSpeedBtn;
    RbParaLine2: TResSpeedBtn;
    RbArc2: TResSpeedBtn;                        
    RbSpline2: TResSpeedBtn;
    RbCircle2: TResSpeedBtn;
    RbRect2: TResSpeedBtn;
    RbPolygon2: TResSpeedBtn;
    RbParaLine1: TResSpeedBtn;
    RbPoint2: TResSpeedBtn;
    ResSpeedBtn1: TResSpeedBtn;
    ResSpeedBtn2: TResSpeedBtn;
    ResSpeedBtn4: TResSpeedBtn;
    ResSpeedBtn6: TResSpeedBtn;
    ResSpeedBtn7: TResSpeedBtn;
    ResSpeedBtn3: TResSpeedBtn;
    RbLine: TResSpeedBtn;
    RbParaLine: TResSpeedBtn;
    ResSpeedBtn8: TResSpeedBtn;
    ResSpeedBtn5: TResSpeedBtn;
    RbArc: TResSpeedBtn;
    RbSpline: TResSpeedBtn;
    RbCirc: TResSpeedBtn;
    RbRect: TResSpeedBtn;
    RbPolygon: TResSpeedBtn;
    RbPoint: TResSpeedBtn;
    ResSpeedBtn9: TResSpeedBtn;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N31: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    MIUndo: TMenuItem;
    rbText: TResSpeedBtn;
    rbText1: TResSpeedBtn;
    rbText2: TResSpeedBtn;
    procedure RbPointClick(Sender: TObject);
    procedure N31Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure MIUndoClick(Sender: TObject);
  public
   lastTwigsCount:Integer;
   Procedure UpdateItems(Enable:Boolean);override;
   Procedure RemoveNeedButtons;override;
  end;

var
  FlyPainter: TFlyPainter;
                               
implementation uses UndoColNew, objMouseDraw, Selector, objMouse,UpdateMessages,
                    EcLot, WpTwigs, Procs, GBFWUndo, drawTwigs, EcDot,
                    objMouseText;

{$R *.dfm}                                         

procedure TFlyPainter.RbPointClick(Sender: TObject);
var Undo:TUndo;MergedOpr:Integer;
begin
 Undo:=V25.TwgForm.Undo;
 Undo.OnAddPrim:=UpdateMessage.AddPrim;
 Undo.OnModifiedPrim:=UpdateMessage.ModifiedPrim;
 Undo.OnDeletePrim:=UpdateMessage.DeletePrim;
 V25.SetFocus;
 If not (Sender as TSpeedButton).Down then begin
  ClearOperation;
  Exit;
 end;
 If (Sender as TSpeedButton).Down then begin
  If (GSpeedSelect<>nil) and (GSpeedSelect<>Sender) then GSpeedSelect.Down:=False;
  GSpeedSelect:=Sender as TSpeedButton;
  If V25.MouseObject<>nil then begin LOperation:=-1;V25.MouseObject.Free;end;
  LOperation:=(Sender as TSpeedButton).Tag;
  If LOperation>100000 then begin                         
   LOperation:=LOperation div 10;MergedOpr:=sysDrawRastr;
  end;
  If (LOperation>10000)then begin
   If (LOperation = 10030) then
   V25.CreateMouseObject(TMouseText) else
   V25.CreateMouseObject(TMousePainter);
    TMousePainter(V25.MouseObject).MergedOpr:=MergedOpr;
  end;
  If V25.MouseObject<>nil then begin
    TKeyMouseHook(V25.MouseObject).OnAddPrim:=UpdateMessage.AddPrim;
    TKeyMouseHook(V25.MouseObject).OnModifiedPrim:=UpdateMessage.ModifiedPrim;
    TKeyMouseHook(V25.MouseObject).OnSetActiveLayer:=UpdateMessage.SetActiveLayer;
    TKeyMouseHook(V25.MouseObject).OnDeletePrim:=UpdateMessage.DeletePrim;
    If LOperation = sysDrawMultiLine then begin
     TMousePainter(V25.MouseObject).isMultiLine:=True;
     lastTwigsCount:=V25.TwgForm.Twigs.TwigsCount;
     LOperation:=sysDrawLine;
     UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
    end;
    V25.MouseObject.Initialize;
    V25.MouseObject.PopupMenu:=PopUpMenu1;
  end;
 end;
 UpdateImage;
// V25.SetFocus;
end;

procedure TFlyPainter.N31Click(Sender: TObject);
Label 1;
var Lot:TLot;Tw:TTwig;Hook:Boolean;X,Y:Double;
Procedure Proc;
begin
 With TMousePainter(V25.MouseObject) do begin
  // отменяем предыдущее построение
  If LastPrim<>nil then begin
    Tw:=LastPrim;
    LOperation:=TMenuItem(Sender).Tag;
    UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
  //  PSetPixel(Tw.Last.XDot,Tw.Last.YDot);
    X:=ZNULL;
    If Tw is TTwigArc then begin
     //if not prevAChangeB then begin X:=TTwigArc(Tw).A.XDot;Y:=TTwigArc(Tw).A.YDot end else begin X:=TTwigArc(Tw).B.XDot;Y:=TTwigArc(Tw).B.YDot;end;
     X:=xyACB.XDot;Y:=xyACB.YDot;
     X0:=X;Y0:=Y;
    end else begin
     X:=Tw.Last.XDot;Y:=Tw.Last.YDot;
     X0:=X;Y0:=Y;
    end;
 //   WRiteln('Pered=',PrevAChangeB);
   OrthoTwigs.Pack('');
   If mpTwig<>nil then begin mpTwig.Draw(GCanvas);mpTwig.Free;mpTwig:=nil;LastPrim:=nil;end;
   If X<>ZNULL then begin
    MouseDown(Self.V25.TwgForm,mbLeft,[],X,Y,Hook);
    MouseUp(Self.V25.TwgForm,mbLeft,[],X,Y,Hook);
   end;
   LockedMultiLine:=False;
 //   WRiteln('Posle=',PrevAChangeB);
  end else begin
   OrthoTwigs.Pack('');
   If mpTwig<>nil then begin mpTwig.Draw(GCanvas);mpTwig.Free;mpTwig:=nil;LastPrim:=nil;end;
   LOperation:=TMenuItem(Sender).Tag;
   UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
   LockedMultiLine:=False;
  end;
 end;                                                   
end;
begin
 With TMousePainter(V25.MouseObject) do begin
  Case LOperation of
   sysDrawLine,
   sysDrawSpline:begin
                  If (mpTwig<>nil) and (mpTwig.Twig.Coord.Count=1) then begin
                   LastPrim:=mpTwig.Twig;
                   Proc;
                  end else begin
                   mpCreatePrim(Self.V25.TwgForm);
                   If LastPrim<>nil then begin
                     Tw:=LastPrim;
                     LOperation:=TMenuItem(Sender).Tag;
                     UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
                   //  PSetPixel(Tw.Last.XDot,Tw.Last.YDot);
                     If Tw is TTwigArc then begin
                      //if not prevAChangeB then begin X:=TTwigArc(Tw).A.XDot;Y:=TTwigArc(Tw).A.YDot end else begin X:=TTwigArc(Tw).B.XDot;Y:=TTwigArc(Tw).B.YDot;end;
                      X:=xyACB.XDot;Y:=xyACB.YDot;
                     end else begin
                      X:=Tw.Last.XDot;Y:=Tw.Last.YDot;
                     end;
                     X0:=X;Y0:=Y;
                  //   WRiteln('Pered=',PrevAChangeB);
                     MouseDown(Self.V25.TwgForm,mbLeft,[],X,Y,Hook);
                     MouseUp(Self.V25.TwgForm,mbLeft,[],X,Y,Hook);
                  //   WRiteln('Posle=',PrevAChangeB);
                   end else begin
                    LOperation:=TMenuItem(Sender).Tag;
                    UpdateMessage.SetOperation(Self.ClassName,IntToStr(LOperation));
                    LockedMultiLine:=False;
                   end;
                  end;
                 end;
   sysDrawArc2,
   sysDrawArc3 :begin
                  If (mpTwig<>nil) then begin
                   Proc;
                  end else begin
                   Proc;
                  end;
                end;
   end;
 end;
end;

procedure TFlyPainter.N1Click(Sender: TObject);
begin
 // составляем контур...
 With TMousePainter(V25.MouseObject) do begin
  mpCreatePrim(Self.V25.TwgForm,True);
  If LastPrim<>nil then begin
   LastPrim:=nil;
   MultiLot:=nil;
   LockedMultiLine:=False;
   lastTwigsCount:=Self.V25.TwgForm.Twigs.TwigsCount;
   UpdateImage;
  end;
 end;
end;

procedure TFlyPainter.N2Click(Sender: TObject);
begin
 SendMessage(ApplicationMainForm.Handle,WM_KeyDown,VK_Escape,0);
end;

procedure TFlyPainter.MIUndoClick(Sender: TObject);
const VK_Z = 90;
begin
 With TMousePainter(V25.MouseObject) do begin
//  If LastPrim = nil then exit;            
  CanDoUndo;
  LockedMultiLine:=False;
 end;
end;

procedure TFlyPainter.UpdateItems(Enable: Boolean);
begin
 inherited;
{ If Pos('INVENTGAZ',ANSIUPPERCASE(ParamStr(0)))=0 then begin
  rbText.Enabled:=False;rbText.Enabled:=False;rbText.Enabled:=False;
 end else begin
  inherited;
 end;
} 
  rbText.Enabled:=True;rbText.Enabled:=True;rbText.Enabled:=True;
end;

procedure TFlyPainter.RemoveNeedButtons;
var I:Integer;
begin
 For I:=ControlCount-1 downTo 0 do RemoveControl(Controls[I]);
end;

end.
