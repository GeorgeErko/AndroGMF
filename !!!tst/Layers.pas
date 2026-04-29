unit FlySloy;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, FlyVer25, Buttons, StdCtrls, ExtCtrls, SzPanel, ImgList,
  ChildPnl, ResSpeedBtn, NumInp12, ComboPanel, Colorbox, Spin, Resource,
  Menus, FlyGeoMaster, ComCtrls, ResourceView, WptBlock, DlgSelectLayer,
  sSpeedButton, sPanel;
                                                            
const Delta = 4;

type                                                 
  TFlyLayer = class(TFlyFormGeoMaster)
    SpeedButton1: TSpeedButton;
    SB4: TSpeedButton;                
    CP1: TChildPanel;
    CPLayers: TComboPanel;
    CP2: TChildPanel;
    CBLineType: TListBox;
    Panel2: TComboPanel;
    Images: TImageList;
    CP3: TChildPanel;
    CCB: TColorComboBox;
    SB1: TScrollBar;
    SB2: TScrollBar;
    SB3: TScrollBar;
    SbColor: TResSpeedBtn;
    SpeedButton4: TSpeedButton;
    Panel3: TsPanel;
    PopupMenu1: TPopupMenu;                                         
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    CP4: TChildPanel;
    CBPointZnak: TListBox;
    SBZnak: TResSpeedBtn;
    EZnkName: TEdit;
    SBOK: TSpeedButton;
    SBCancel: TSpeedButton;
    Panel4: TPanel;
    ELineName: TEdit;
    CPLayers1: TComboPanel;
    SpeedButton2: TSpeedButton;
    LayerList: TResourceView;
    List: TListBox;
    PopupMenu2: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MIAddLayer: TMenuItem;
    MIAddView: TMenuItem;
    MenuItem4: TMenuItem;
    MIAddLayerClass: TMenuItem;
    MIAddLayerNew: TMenuItem;
    MIAddViewNew: TMenuItem;
    MIAddViewClass: TMenuItem;
    SpeedButton6: TSpeedButton;
    BlockTableView: TSpeedButton;
    BlockTableView1: TSpeedButton;
    MIMoveLayer: TMenuItem;
    N5: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N6: TMenuItem;
    N9: TMenuItem;
    MI1: TMenuItem;
    MICheckGroup: TMenuItem;
    sbProp2: TSpeedButton;
    sbProp1: TSpeedButton;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    OD: TOpenDialog;
    SD: TSaveDialog;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    N18: TMenuItem;
    N19: TMenuItem;
    N01: TMenuItem;
    N110: TMenuItem;
    N101: TMenuItem;
    N251: TMenuItem;
    N501: TMenuItem;
    N991: TMenuItem;
    N1001: TMenuItem;
    miDupGroup: TMenuItem;
    N20: TMenuItem;
    MIGroupSelect: TMenuItem;
    sOk: TsSpeedButton;
    sCancel: TsSpeedButton;
    sbOn: TsSpeedButton;
    sbOff: TsSpeedButton;
    sbInvert: TsSpeedButton;
    procedure CBLineTypeDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure CBLineTypeChange(Sender: TObject);
    procedure PanelPaint(Sender:TObject;Rect: TRect);
    procedure FormActivate(Sender: TObject);
    procedure SB4Click(Sender: TObject);
    procedure CBLineTypeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Panel2Paint(Sender: TObject; Rect: TRect);
    procedure SB1Change(Sender: TObject);
    procedure CCBChange(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure CP3Show(Sender: TObject);
    procedure SbColorPaint(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure CPLayersMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure CBPointZnakDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure CBPointZnakMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CBPointZnakClick(Sender: TObject);
    procedure EZnkNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SBOKClick(Sender: TObject);
    procedure SBCancelClick(Sender: TObject);
    procedure SBZnakPaint(Sender: TObject);
    procedure CBLineTypeMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ELineNameChange(Sender: TObject);
    procedure ELineNameEnter(Sender: TObject);
    procedure ELineNameMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CBPointZnakMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CP2Show(Sender: TObject);
    procedure ELineNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EZnkNameChange(Sender: TObject);
    procedure CP1Show(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MIAddLayerClick(Sender: TObject);
    procedure MIAddViewClick(Sender: TObject);
    procedure LayerListUpdateLayer(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure LayerListLayerSettings(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure CP1Resize(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure MIAddViewClassClick(Sender: TObject);
    procedure BlockTableViewClick(Sender: TObject);
    procedure sbOffClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure MICheckGroupClick(Sender: TObject);
    procedure LayerListDblClick(Sender: TObject);
    procedure LayerListMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure sbProp1Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure N13Click(Sender: TObject);
    procedure N1001Click(Sender: TObject);
    procedure miDupGroupClick(Sender: TObject);
    procedure N20Click(Sender: TObject);
    procedure SpeedBtnOkClick(Sender: TObject);
   private
    fChangeQuickLayer: TNotifyEvent;
    fFileNameChanged: TNotifyEvent;
    procedure SynchronizeLayerTable;
   public
    AddOnView:Boolean;
    XO,YO:Integer;
    OnUpdateItems:TNotifyEvent;
    OnLayerChange:TNotifyEvent;
    SelectedBlockEditorBlock:TGeoBlock;
    OnPanelShow: TNotifyEvent;
    OnPanelPaint: TPaintItem;
    Procedure CreateV25WndParams;override;
    Procedure CreateReplication;override;
    Procedure UpdateItems(Enable:Boolean);Override;
    Function ResetLayerProperties(PR:TResource):boolean;
    Procedure OnAddButtonClick(Sender:TObject);
   //
    procedure SetActiveLayer(Layer:TResource;Symbol:Integer);
   //
    procedure ClickMove(Sender:TObject);
    function OnChangeLayerTable(Prim:TObject):boolean;
   //
    procedure CheckEditMapObjects;
   //
    Property OnChangeQuickLayer:TNotifyEvent read fChangeQuickLayer write fChangeQuickLayer;
    Property OnFileNameChanged:TNotifyEvent read fFileNameChanged write fFileNameChanged;
  end;

var
  FlyLayer: TFlyLayer;

implementation uses Collect, TwgColle, Lines3, BigDlg, Lines2,
                    ClassLib, Procs, ClassForm, Selector, ClassMak,
                    Colors, Lib,
                    ClassDlg, LayersTable, UpdateMessages, DlgBlockTable,
                    objHotSpot, EcDot, objEditMap, EcLot, RPrims,
                    DlgPropEditor, ThSet0, DlgSelectFlag;

{$R *.dfm}

procedure TFlyLayer.CreateReplication;
begin                                        
 inherited;
 UpdateItems(True);
end;

procedure TFlyLayer.CreateV25WndParams;
begin
 CanResize:=False;
 StartW:=Round(PixelsPerInch*4.58)*2;
 StartH:=Round(PixelsPerInch*0.625)*2;
 inherited;                                        
end;                               

                                                      
procedure TFlyLayer.CBLineTypeDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var L:TGeoLine;                                         
begin
 Index:=SearchLine(V25.TwgForm.MkLib.LSLib,StrToInt(CBLineType.Items[Index]));
 If Index<>-1 then L:=V25.TwgForm.MkLib.LSLib[Index] else exit;
 If (odSelected in State) then CBLineType.Canvas.Brush.Color:=clSilver;
 CBLineType.Canvas.FillRect(Rect);                
 Zoom:=3.5;LeftRight:=7;                          
 BigDlg.DrawLine(CBLineType.Canvas.Handle,L,V25.TwgForm.MkLib.PSLib,Rect);
end;

procedure TFlyLayer.CBLineTypeChange(Sender: TObject);
var Index:Integer;L:TGeoLine;
begin
 Index:=SearchLine(V25.TwgForm.MkLib.LSLib,StrToInt(CBLineType.Items[CBLineType.ItemIndex]));
 If Index<>-1 then L:=V25.TwgForm.MkLib.LSLib[Index] else exit;
 CBLineType.Hint:=Upper(L.NameOf);
end;                                     

procedure TFlyLayer.PanelPaint(Sender:TObject;Rect: TRect);
var CP:TComboPanel;
begin
 If Assigned(OnPanelPaint) then OnPanelPaint(Sender, Rect);
 CP:=Sender as TComboPanel;
 if CP.Item<>nil then  begin
  InflateRect(Rect, 0, 0);
  Rect.Bottom:=Rect.Bottom+1;
  DrawLayerProp(CP.Item,CP.Canvas,[],Rect,Images,False);
 end;
end;

procedure TFlyLayer.FormActivate(Sender: TObject);
begin                                                         
 SPH.Visible:=False;                                          
// SPH.Visible:=True;
end;

procedure TFlyLayer.SB4Click(Sender: TObject);
var CP:TComboPanel;
begin                                               
 CP:=TComboPanel.Create(Self);
 CP.Left:=30;CP.Top:=30;CP.Width:=100;CP.Height:=80;
 CP.Visible:=True;
 Hide;Show;
end;

procedure TFlyLayer.CBLineTypeMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Index:Integer;L:TGeoLine;
begin
  Index:=StrToInt(CBLineType.Items[CBLineType.ItemIndex]);
  Index:=SearchLine(V25.TwgForm.MkLib.LSLib,Index);
  If Index<>-1 then L:=V25.TwgForm.MkLib.LSLib[Index] else exit;
  Panel2.Item:=L;
  V25.TwgForm.LayerTable.ActiveLine:=L;
  CP2.Hide;
end;

procedure TFlyLayer.Panel2Paint(Sender: TObject; Rect: TRect);
begin
 if Panel2.Item<>nil then begin
  InflateRect(Rect, -0, -0);
  BigDlg.DrawLine(Panel2.Canvas.Handle,Panel2.Item,V25.TwgForm.MkLib.PSLib,Rect);
//GB  SBZnak.Hint:=V25.TwgForm.LayerTable.ActiveLine.MyNameIs;
 end;
end;

procedure TFlyLayer.UpdateItems(Enable: Boolean);
var I:Integer;Layers:PCollection;
    L:TGeoLine;
    P:TPoint_Sign;
begin
 inherited;
 If V25 = nil then Exit;
 CBLineType.Align:=alClient;
// Edit1
 // Заполняем таблицу слоев и линий
 V25.TwgForm.LayerTable.OnChange:=OnChangeLayerTable;
 LayerList.LayerTable:=V25.TwgForm.LayerTable;
 CPLayers.Item:=V25.TwgForm.LayerTable.ActiveLayer;CPLayers1.Item:=V25.TwgForm.LayerTable.ActiveLayer;
 CPLayers.Refresh;CPLayers1.Refresh;
 CBLineType.Items.Clear;
 If V25.TwgForm.MkLib.LineLib<>nil then
 For I:=0 to V25.TwgForm.MkLib.LineLib.Count-1 do begin
  L:=V25.TwgForm.MkLib.LineLib[I];
  CBLineType.Items.Add(IntToStr(L.IdNum));
 end;
 CBPointZnak.Items.Clear;
 If V25.TwgForm.MkLib.PntLib<>nil then
 For I:=0 to V25.TwgForm.MkLib.PntLib.Count-1 do begin
  P:=V25.TwgForm.MkLib.PntLib[I];
  CBPointZnak.Items.Add(IntToStr(P.MyInd));
 end;
// Layers.DeleteAll;Layers.Free;
 Panel2.Item:=nil;
 If Assigned(OnUpdateItems) then OnUpdateItems(nil);
 BlockTableView.Enabled:=SelectedBlockEditorBlock=nil;
 BlockTableView1.Enabled:=SelectedBlockEditorBlock=nil;
end;

procedure TFlyLayer.SB1Change(Sender: TObject);
var SB:TScrollBar;RGB:TRgbRec;
begin
 SB:=Sender as TScrollBar;
 RGB.Argb[1]:=GetRValue(CCB.ColorItem);
 RGB.Argb[2]:=GetGValue(CCB.ColorItem);
 RGB.Argb[3]:=GetBValue(CCB.ColorItem);
 Rgb.Argb[SB.Tag]:=SB.Position;
 CCB.ColorItem:=Windows.RGB(RGB.Argb[1],RGB.Argb[2],RGB.Argb[3]);
 SbColorPaint(nil);
end;

procedure TFlyLayer.CCBChange(Sender: TObject);
begin
 SB1.Position:=GetRValue(CCB.ColorItem);
 SB2.Position:=GetGValue(CCB.ColorItem);
 SB3.Position:=GetBValue(CCB.ColorItem);
 SbColorPaint(nil);
end;
                                                             
procedure TFlyLayer.SpeedButton4Click(Sender: TObject);
begin
 CP3.Hide;
end;

procedure TFlyLayer.CP3Show(Sender: TObject);
begin
 CCBChange(CCB);
end;

procedure TFlyLayer.SbColorPaint(Sender: TObject);
begin
 SbColor.Canvas.Brush.Color:=CCB.ColorItem;                         
 SbColor.Canvas.Rectangle(3,3,20,20);
end;

procedure TFlyLayer.MIAddViewClassClick(Sender: TObject);
begin
 AddOnView:=True;
 try
  ClassTree:=TClassTree.Create(Self,V25.TwgForm,OnAddButtonClick);
   if ClassTree.Execute then begin end;
    ClassRebuildBlock:=True;
    ClassBuild(nil,V25.TwgForm.ClName,V25.TwgForm.Twigs,V25.TwgForm.MkLib);
  UpdateItems(True);
  ClassTree.Free;
 finally AddOnView:=False; end;
end;

procedure TFlyLayer.SpeedButton1Click(Sender: TObject);
var Layers:PCollection;
begin
SelectLayerForm:=TSelectLayerForm.Create(ApplicationMainForm);
SelectLayerForm.Execute('Выбор слоя для точечного объекта...',V25.TwgForm.LayerTable);
SelectLayerForm.Free;
// Layers:=PCollection.Create(1);
//  V25.TwgForm.CreateLayersView(Layers);
// Layers.Free;
{  ClassView:=TClassView.Create(Self);
  ActiveClassName:=V25.TwgForm.ClName;
  ClassView.Execute(V25.TwgForm.MkLib,Pointer(V25.TwgForm),1.1,Layers);
 ClassView.Free;}
{ AddOnView:=False;
 ClassTree:=TClassTree.Create(Self,V25.TwgForm,OnAddButtonClick);
  if ClassTree.Execute then begin end;
  ClassRebuildBlock:=True;
   ClassBuild(nil,V25.TwgForm.ClName,V25.TwgForm.Twigs,V25.TwgForm.MkLib);
 UpdateItems(True);
 ClassTree.Free;
 }
end;

procedure TFlyLayer.OnAddButtonClick(Sender: TObject);
var PR:TResource;Num:Double;
    F:TextFile;
begin
// добавляем слой в таблицу слоев из классификатора
 PR:=Sender as TResource;
// V25.TwgForm.LayerTable.ShowLayerTable;
 If V25.TwgForm.LayerTable.SearchLayer(PR.ID)=nil then begin
  V25.TwgForm.LayerTable.ShowLayerTable;
   PR:=TResource.CreateRes(PR.GetResRec);
  If AddOnView then begin
   // добавляем вид
   LayerList.AddLayer(V25.TwgForm.LayerTable.ActiveLayer,PR);
  end else begin
   PR:=TResource.CreateRes(PR.GetResRec);
   V25.TwgForm.LayerTable.AddLayer(PR);
  end;
  UpdateItems(True);
  V25.TwgForm.LayerTable.ShowLayerTable;
  V25.TwgForm.LayerTable.ActiveLayer:=PR;
  V25.TwgForm.MkLib.ActiveLayer:=PR;
  CPLayers.Item:=PR;
  CPLayers1.Item:=PR;
 end;
end;

procedure TFlyLayer.CPLayersMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var PR:tResource;CP:TComboPanel;
begin
 CP:=Sender as TComboPanel;
 PR:=CP.Item;
 If PR=nil then Exit;
  If X>List.ItemHeight*2+Delta then begin end else
  If X>List.ItemHeight+Delta then begin
   If PR.Check=1 then PR.Check:=0 else PR.Check:=1;
    CP.Item:=PR;
   If Assigned(OnPanelPaint) then OnPanelPaint(Sender, CP.ItemRect);
   ClassRebuildBlock:=True;
    V25.TwgForm.ClassBuildII;
    CheckEditMapObjects;
    UpdateImage;
  end else
  If X>6 then ResetLayerProperties(PR);
//  SynchronizeLayerTable;
end;

Function TFlyLayer.ResetLayerProperties(PR:TResource):boolean;
var Sloi:PCollection;F:TResRec;FBm:TBitmapRec;
begin
 // устанавливаем свойства слоя            
 Result:=False;
 Sloi:=PCollection.Create(1);
 ColorDlg:=TColorDlg.Create(ApplicationMainForm);
 V25.TwgForm.MkLib.FillCollection(Sloi);
 F:=PR.GetResRec;
 FBm:=PR.GetBitmapRec;
  If ColorDlg.Execute(F,FBm,Sloi,V25.TwgForm.MkLib.LayerTable,V25.TwgForm.MkLib.BaseName) then begin
   Result:=True;
   PR.Restruct(F);
   If V25.TwgForm.Taheo<>nil then TTaheoSet0(V25.TwgForm.Taheo).TwgForm:=V25.TwgForm;
//   PR.RestructBitmap(FBm);
//   Writeln('Ok=',F.RGB.ARGB[1],' ',PR.RGB.Argb[1]);
   If V25.TwgForm.LayerTable.SearchLayer(PR.ID)=nil then
    V25.TwgForm.LayerTable.AddLayer(PR) else begin
    //If Assigned(V25.TwgForm.LayerTable.OnChange) then
    // V25.TwgForm.LayerTable.OnChange(V25.TwgForm.LayerTable);
   // вместо OnChange
    UpdateMessage.AddPrim(V25.TwgForm.LayerTable);
   end;
 //..                                                         
   UpdateItems(True);
 //  CPLayers.Item:=PR;CPLayers1.Item:=PR;
 ClassRebuildBlock:=True;
   V25.TwgForm.ClassBuildII;
//   V25.TwgForm.LayerTable.ResetChildsLayerMkLib;
   UpdateImage;
   Windows.SetFocus(V25.TwgForm.HWndParent);
  end;
 ColorDlg.Free;
 Sloi.DeleteAll;
 Sloi.Free;
end;

procedure TFlyLayer.N1Click(Sender: TObject);
var PR:TResource;
begin
 SpeedButton1Click(Sender);
 // устанавливаем свойства слоя
// PR:=TResource.CreateNew;
// if not ResetLayerProperties(PR) then PR.Free;
end;

procedure TFlyLayer.CBPointZnakDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var N:Integer;R:TRect;
begin
 R:=Rect;
 If (odSelected in State) then CBPointZnak.Canvas.Brush.Color:=clSilver else CBPointZnak.Canvas.Brush.Color:=CBPointZnak.Color;
 CBPointZnak.Canvas.FillRect(Rect);
// R.Bottom:=R.Bottom-((R.Bottom-R.Top) div 3);
 With V25.TwgForm.MkLib,V25.TwgForm do begin
  N:=SearchThis(PSLib,StrToInt(CBPointZnak.Items[Index]));
  If N<>-1 then begin
   DrawPoint(CBPointZnak.Canvas.Handle,PSLib[N],R,4);
  end;
 end;
end;

procedure TFlyLayer.CBPointZnakMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 CP4.ClosePanel;
 SBOKClick(SBOk);
end;

procedure TFlyLayer.CBPointZnakClick(Sender: TObject);
var N:Integer;
begin
  N:=SearchThis(V25.TwgForm.MkLib.PSLib,StrToInt(CBPointZnak.Items[CBPointZnak.ItemIndex]));
  If N<>-1 then begin
   EZnkName.Text:=TPoint_Sign(V25.TwgForm.MkLib.PSLib[N]).MyNameIs
  end else EZnkName.Text:='';
end;

procedure TFlyLayer.ELineNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var Index:Integer;L:TGeoLine;
begin
 If Key=VK_Return then begin
  begin
    Index:=StrToInt(CBLineType.Items[CBLineType.ItemIndex]);
    Index:=SearchLine(V25.TwgForm.MkLib.LSLib,Index);
    If Index<>-1 then L:=V25.TwgForm.MkLib.LSLib[Index] else exit;
    Panel2.Item:=L;
    V25.TwgForm.LayerTable.ActiveLine:=L;
    CP2.Hide;
  end;
 end else If Key=VK_Escape then CP2.ClosePanel;
end;

procedure TFlyLayer.EZnkNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 If Key=VK_Return then SbOkClick(Sender) else If Key=VK_Escape then SbCancelClick(Sender);
end;

procedure TFlyLayer.SBOKClick(Sender: TObject);
var N:Integer;
begin
 If CBPointZnak.ItemIndex<>-1 then begin
  N:=SearchThis(V25.TwgForm.MkLib.PSLib,StrToInt(CBPointZnak.Items[CBPointZnak.ItemIndex]));
  If N<>-1 then V25.TwgForm.LayerTable.ActivePoint:=V25.TwgForm.MkLib.PSLib[N];
  SBZnak.Refresh;
 end;
end;

procedure TFlyLayer.SBCancelClick(Sender: TObject);
begin
 CP4.ClosePanel;
end;

procedure TFlyLayer.SBZnakPaint(Sender: TObject);
begin
 R:=SBZnak.ClientRect;
 If V25.TwgForm.LayerTable.ActivePoint<>nil then begin
 // Rectangle(SBZnak.Canvas.Handle,2,2,20,20);
  DrawPoint(SBZnak.Canvas.Handle,V25.TwgForm.LayerTable.ActivePoint,R,3);//,False);
  SBZnak.Hint:=V25.TwgForm.LayerTable.ActivePoint.MyNameIs;
 //  SBZnak.Canvas.Rectangle(2,2,20,20);
 end;
end;

procedure TFlyLayer.CBLineTypeMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var P:TPoint;N:Integer;
begin
 P.X:=X;P.Y:=Y;
 N:=CBLineType.ItemAtPos(P,True);
 If N=-1 then ELineName.Text:='' else begin
  N:=StrToInt(CBLineType.Items[N]);
  N:=SearchLine(V25.TwgForm.MkLib.LSLib,N);
  If N<>-1 then ELineName.Text:=TGeoLine(V25.TwgForm.MkLib.LSLib[N]).NameOf;
 end;
end;

procedure TFlyLayer.ELineNameChange(Sender: TObject);
var N:Integer;
begin
// N:=SearchLineName(V25.TwgForm.MkLib.LineLib,ELineName.Text);
 if N<>-1 then CBLineType.ItemIndex:=N;
end;

procedure TFlyLayer.ELineNameEnter(Sender: TObject);
begin
 ELineName.SelectAll;
end;

procedure TFlyLayer.ELineNameMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 ELineName.SelectAll;
end;

procedure TFlyLayer.CBPointZnakMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var P:TPoint;N:Integer;
begin
 P.X:=X;P.Y:=Y;
 N:=CBPointZnak.ItemAtPos(P,True);
 If N=CBPointZnak.ItemIndex then exit;
 If N=-1 then EZnkName.Text:='' else begin
  CBPointZnak.ItemIndex:=N;
  N:=StrToInt(CBPointZnak.Items[N]);                 
  N:=SearchThis(V25.TwgForm.MkLib.PSLib,N);
  If N<>-1 then EZnkName.Text:=TPoint_Sign(V25.TwgForm.MkLib.PSLib[N]).MyNameIs;
 end;
end;

procedure TFlyLayer.CP2Show(Sender: TObject);
begin
//
end;
                                          
procedure TFlyLayer.EZnkNameChange(Sender: TObject);
var N:Integer;
begin
// N:=SearchPointName(V25.TwgForm.MkLib.PntLib,EZnkName.Text);
 if N<>-1 then CBPointZnak.ItemIndex:=N;
end;

procedure TFlyLayer.CP1Show(Sender: TObject);
begin
 If Assigned(OnPanelShow) then OnPanelShow(CP1) else
 If (PanelName ='None') and Visible then begin
  CP1.FixedPosition:=fp_ComboBoxWindow;
  CP1.Width:=CPLayers1.Width+CPLayers1.Width div 4;
  CP1.DeltaX:=CPLayers1.Width div 4;
  CPLayers1.SetFocus;
//  CP1.Left:=Left+CPLayers.Left;
  CP1.DeltaY:=4;
 end else begin
  CP1.FixedPosition:=fp_ComboBox;
  CP1.Width:=CPLayers1.Width+CPLayers.Width div 4;
  CP1.DeltaX:=CPLayers1.Width div 4;
//  CP1.Left:=SPH.Left+CPLayers.Left;
  CP1.DeltaY:=4;
  CPLayers.SetFocus;
 end;
 LayerList.SelectedLayer:=V25.TwgForm.LayerTable.ActiveLayer;
// fActiveLayer:=Layers.ActiveLayer;
end;

procedure TFlyLayer.FormResize(Sender: TObject);
begin
 inherited;
 CPLayers1.Width:=Width-SbProp1.Width*3-20;
 CPLayers1.Left:=(SbProp1.Left+SbProp1.Width)+5;         
end;

procedure TFlyLayer.SynchronizeLayerTable;
var I:Integer; LT:TLayerTable;                             
    PR:TResource;
begin
 LT:=V25.TwgForm.MkLib.LayerTable;
 For I:=LT.LayerCount-1 downTo 0 do begin
  PR:=V25.TwgForm.MkLib.SearchRes(LT.Layer[I].ID);
  If (PR=nil) then begin
   If LT.Layer[I].ID<>0 then LT.DeleteLayer(I);
  end else begin
   PR.Restruct(LT.Layer[I].GetResRec);
  end;
 end;
end;

procedure TFlyLayer.MIAddLayerClick(Sender: TObject);
begin
 LayerList.AddLayer(nil,nil);
end;

procedure TFlyLayer.MIAddViewClick(Sender: TObject);
begin
 LayerList.AddLayer(V25.TwgForm.LayerTable.ActiveLayer,nil);
end;

procedure TFlyLayer.LayerListUpdateLayer(Sender: TObject);
var I:Integer;
begin
 CPLayers.Refresh;
 CPLayers1.Refresh;
 ClassRebuildBlock:=True;
 V25.TwgForm.ClassBuildII;
 CheckEditMapObjects;
 UpdateImage;
end;

procedure TFlyLayer.SpeedButton3Click(Sender: TObject);
begin
 try
 If LayerList.ActiveNode<>nil then begin
  V25.TwgForm.LayerTable.ActiveLayer:=LayerList.ActiveNode.Data;
  CPLayers.Item:=V25.TwgForm.LayerTable.ActiveLayer;
  CPLayers1.Item:=V25.TwgForm.LayerTable.ActiveLayer;
  V25.TwgForm.MkLib.ActiveLayer:=V25.TwgForm.LayerTable.ActiveLayer;
  CP1.ClosePanel;
  If Assigned(OnChangeQuickLayer) then OnChangeQuickLayer(V25.TwgForm.LayerTable.ActiveLayer);
  If V25.MouseObject<>nil then
   If Assigned(V25.MouseObject.OnSetActiveLayer) then begin
    V25.MouseObject.OnSetActiveLayer(V25.TwgForm.LayerTable.ActiveLayer,-1);
   end;
  If Assigned(OnPanelPaint) then OnPanelPaint(CPLayers1, CPLayers1.BoundsRect); 
  V25.SetFocus;
 end;
 except
  V25.SetFocus;
 end;
end;                      

procedure TFlyLayer.LayerListLayerSettings(Sender: TObject);
begin
 ResetLayerProperties(TResource(Sender));
end;

procedure TFlyLayer.SpeedButton5Click(Sender: TObject);
begin
 CP1.ClosePanel;
 V25.SetFocus;
end;

procedure TFlyLayer.CP1Resize(Sender: TObject);
begin
 LayerList.Width:=CP1.Width - LayerList.Left*2;
// sOk.Left := Panel3.Width - (333 - 246);
// sCancel.Left := Panel3.Width - (333 - 280);
end;

procedure TFlyLayer.MenuItem1Click(Sender: TObject);
var PR:TResource;
begin
 If not CP1.Visible then PR:=CPLayers.Item else PR:=LayerList.ActiveNode.Data;
 ResetLayerProperties(PR);
end;

procedure TFlyLayer.SetActiveLayer(Layer: TResource; Symbol: Integer);
begin
 CPLayers.Item:=Layer;
 CPLayers1.Item:=Layer;
 V25.TwgForm.LayerTable.ActiveLayer:=Layer;
 If Assigned(OnLayerChange) then OnLayerChange(Self);
 If Assigned(OnPanelPaint) then OnPanelPaint(CPLayers, CPLayers.ItemRect);
end;

procedure TFlyLayer.SpeedButton6Click(Sender: TObject);
begin
 ClassRebuildBlock:=True;
 V25.TwgForm.ClassBuildII;
 UpdateImage;
end;

procedure TFlyLayer.BlockTableViewClick(Sender: TObject);
var MOHS:Boolean;
    I:Integer;B:Byte;
begin
 // форма с таблицей блоков
 GlobalIniLoad:=False;
 try
  MOHS:=False;If V25.MouseObject<>nil then If V25.MouseObject is TMouseHotSpot then MOHS:=True;
  BlockTableForm:=TBlockTableForm.Create(ApplicationMainForm);
   If SelectedBlockEditorBlock<>nil then
    B:=ord(BlockTableForm.Execute(V25.TwgForm,V25.TwgForm.Twigs.BlockList,nil,SelectedBlockEditorBlock.Name,True)) else
    B:=ord(BlockTableForm.Execute(V25.TwgForm,V25.TwgForm.Twigs.BlockList,nil,'*'));
   If bool(B) then begin
   // вставка выбранного блока
    If V25.MouseObject<>nil then begin {LOperation:=-1;V25.MouseObject.Free;}ClearOperation;end;
    If not BlockTableForm.cbRect.Checked then LOperation:=spotSetBlock else LOperation:=spotSetBlockRect;
    V25.CreateMouseObject(TMouseHotSpot);
    TMouseHotSpot(V25.MouseObject).Block:=BlockTableForm.SelectedBlock;
    TMouseHotSpot(V25.MouseObject).bumBlock:=BlockTableForm.cbBum.Checked;
    TMouseHotSpot(V25.MouseObject).OnAddPrim:=UpdateMessage.AddPrim;
    TMouseHotSpot(V25.MouseObject).OnModifiedPrim:=UpdateMessage.ModifiedPrim;
    TMouseHotSpot(V25.MouseObject).OnSetActiveLayer:=UpdateMessage.SetActiveLayer;
    TMouseHotSpot(V25.MouseObject).OnDeletePrim:=UpdateMessage.DeletePrim;
   //
   end;
  If Assigned(OnFileNameChanged) then OnFileNameChanged(Self);
  BlockTableForm.Free;
  V25.SetParams;
  UpdateImage;
  If V25.MouseObject<>nil then If V25.MouseObject is TMouseHotSpot then begin
   If not MOHS then TMouseHotSpot(V25.MouseObject).DrawBlock(GCanvas,-100000,-100000,0,ZNull);
  end;
 finally
  GlobalIniLoad:=True;
 end;
end;

procedure TFlyLayer.sbOffClick(Sender: TObject);
var I:Integer; LT:TLayerTable;
    PR:TResource;
begin
 LT:=V25.TwgForm.MkLib.LayerTable;
 For I:=LT.L2Count-1 downTo 0 do If Sender=sbOn then LT.LinearLayer[I].Check:=1 else
                                 If Sender=sbOff then LT.LinearLayer[I].Check:=0 else
                                 If Sender=sbInvert then If LT.LinearLayer[I].Check=1 then LT.LinearLayer[I].Check:=0 else LT.LinearLayer[I].Check:=1;
 LayerList.Refresh;
 ClassRebuildBlock:=True;
 V25.TwgForm.ClassBuildII;
 UpdateImage;
end;

procedure TFlyLayer.Button1Click(Sender: TObject);
var I:integer;B:Byte;
begin
 SpeedButton3Click(Sender);
{
 With V25.TwgForm do begin
  For I:=0 to Twigs.AnyCount-1 do begin
   TPointDot(Twigs.AAt(I,B)).Ugol:=10*Pi/180;
  end;
  UpdateImage;
 end;
 }
end;

procedure TFlyLayer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 If CP1.PanelVisible then CP1.Hide;
end;

procedure TFlyLayer.ClickMove(Sender: TObject);
var MI:TMenuItem;PR:TResource;NewParentNode:TResource;
begin
 MI:=TMenuItem(Sender);
 If not CP1.Visible then PR:=CPLayers.Item else PR:=LayerList.ActiveNode.Data;
 NewParentNode:=TResource(MI.Tag);
 If PR.Parent<>nil then PR.Parent.Resources.AtDelete(PR.Parent.Resources.IndexOf(PR)) else V25.TwgForm.LayerTable.Layers.AtDelete(V25.TwgForm.LayerTable.Layers.IndexOf(PR));
 PR.Parent:=NewParentNode;
 NewParentNode.Resources.Insert(PR);
 LayerList.FillList(V25.TwgForm.LayerTable);
 LayerList.SelectedLayer:=PR;
 V25.TwgForm.Modified:=True;
end;

procedure TFlyLayer.PopupMenu2Popup(Sender: TObject);
var I:Integer;ALayer:TResource;
Function GetChecked:boolean;
var I:Integer;
begin
 Result:=True;
 For I:=0 to ALayer.Resources.Count-1 do
  If TResource(ALayer.Resources[I]).Check=1 then Exit;
 Result:=False;
end;
Procedure FillMoveLayer;
var I,J:Integer;MI:TMenuItem;PR:TResource;
begin
 If not CP1.Visible then PR:=CPLayers.Item else PR:=LayerList.ActiveNode.Data;
   For I:=MIMoveLayer.Count-1 downto 0 do MIMoveLayer.Items[I].Free;
 J:=1;
 With V25.TwgForm.LayerTable do
  For I:=0 to Layers.Count-1 do begin
   If (Layer[I].Resources.Count>0)and(Layer[I]<>PR.Parent) then begin
    If J=0 then MI:=MIMoveLayer.Items[0] else MI:=TMenuItem.Create(Self);
    MI.Caption:=Layer[I].RecString;MI.Tag:=Integer(Layers[I]);MI.OnClick:=ClickMove;
    If J<>0 then MIMoveLayer.Add(MI);
    J:=1;
   end;
  end;
end;
begin
 If not CP1.Visible then ALayer:=CPLayers.Item else ALayer:=LayerList.ActiveNode.Data;
 MIMoveLayer.Visible:=(ALayer.Parent<>nil)or(ALayer.Resources.Count = 0);
 FillMoveLayer;
 //
 MenuItem3.Visible:=CP1.Visible;
 MenuItem4.Visible:=CP1.Visible;
 MIMoveLayer.Visible:=CP1.Visible;
 N6.Visible:=CP1.Visible;N9.Visible:=CP1.Visible;
 If (ALayer.Parent=nil) then begin
  MI1.Visible:=True;
  MICheckGroup.Visible:=True;
  MIDupGroup.Visible:=True;
  MiCheckGroup.Checked:=GetChecked;
  If MiCheckGroup.Checked then MICheckGroup.Caption:='Отключить группу' else MICheckGroup.Caption:='Включить группу';
  MIGroupSelect.Visible:=True;
 end else begin
  MI1.Visible:=False;
  MICheckGroup.Visible:=False;
  MIDupGroup.Visible:=True;
  MIGroupSelect.Visible:=False;
 end;
end;

procedure TFlyLayer.N5Click(Sender: TObject);
var P:PCollection;PR,PR1:TResource;
    CountLayers, I:Integer;
    St:TStrings;
begin
 // удаление слоя
 If not CP1.Visible then PR:=CPLayers.Item else PR:=LayerList.ActiveNode.Data;
 If PR.Resources.Count>0 then begin
  MessageInform('Cлой "'+PR.RecString+'" является корневым. Предварительно необходимо удалить дочерние слои (виды)...');
  exit;
 end;
 With V25.TwgForm do begin
  P:=PCollection.Create(1);
  CreateLayersView(P);
  CountLayers:=0;
  For I:=0 to P.Count-1 do begin
//   WRiteln();
   If Round(PR.ID*100) = Round(TwgColle.TExt(P[I]).Num*100) then Inc(CountLayers);
  end;
  If CountLayers<>0 then MessageInform('На слое "'+PR.RecString+'" находится '+IntToStr(CountLayers)+' объект(ов). Удалите объекты на слое и повторите операцию.') else begin
   St:=TStringList.Create;
    If Twigs.BlockList.thisLayerExists(PR,ST) then begin
     MessageInform('На слое "'+PR.RecString+'" находится '+IntToStr(ST.Count)+' блок(ов): '#13#10+ST.Text+#13#10+'Удалите блоки на слое и повторите операцию.')
    end else begin
   // удаляем слой
     If PR.Parent<>nil then PR1:=PR.Parent else PR1:=LayerTable.Layers[0];
     LayerTable.DeleteSubLayer(PR);
     LayerList.FillList(LayerTable);
     LayerList.SelectedLayer:=PR1;
    end;
   St.Free;
  end;
  P.Free;
 end;
end;

procedure TFlyLayer.N8Click(Sender: TObject);
var EM:TEditMap;PR:TResource;
begin
 If not CP1.Visible then PR:=CPLayers.Item else PR:=LayerList.ActiveNode.Data;
 With V25 do begin
  If MouseObject=nil then EM:=TEditMap(CreateMouseObject(TEditMap)) else
  If MouseObject.ClassName<>'TEditMap' then begin
   LOperation:=-1;MouseObject.Free;
   EM:=TEditMap(CreateMouseObject(TEditMap));
  end else EM:=TEditMap(V25.MouseObject);
  If Sender = N14 then EM.emSelectObjectbyLayer(nil,PR,1,0,0) else
  If Sender = N15 then EM.emSelectObjectbyLayer(nil,PR,0,1,0) else
  If Sender = N16 then EM.emSelectObjectbyLayer(nil,PR,0,0,1) else
  If Sender = N8 then EM.emSelectObjectbyLayer(nil,PR,1,1,1) else begin
   SelectFlagForm:=TSelectFlagForm.Create(ApplicationMainForm);
   if SelectFlagForm.Execute('Выбор слоев',['Площадные','Линейные','Точечные']) then
    With SelectFlagForm do EM.emSelectObjectbyLayer(PR,PR,ord(List.Checked[0]),ord(List.Checked[1]),ord(List.Checked[2]));
   SelectFlagForm.Free;
  end;
  UpdateImage         
 end;
end;                                         

function TFlyLayer.OnChangeLayerTable(Prim: TObject):boolean;
begin
 UpdateItems(True);             
end;                                                        

procedure TFlyLayer.MICheckGroupClick(Sender: TObject);
var I:Integer;ALayer:TResource;
begin
 MiCheckGroup.Checked:=not(MiCheckGroup.Checked);
 If not CP1.Visible then ALayer:=CPLayers.Item else ALayer:=LayerList.ActiveNode.Data;
 For I:=0 to ALayer.Resources.Count-1 do
  TResource(ALayer.Resources[I]).Check:=ord(MiCheckGroup.Checked);
 ALayer.Check:=ord(MiCheckGroup.Checked);
 LayerList.Refresh;
 CPLayers.Refresh;
 ClassRebuildBlock:=True;
 V25.TwgForm.ClassBuildII;
 UpdateImage;
end;

procedure TFlyLayer.CheckEditMapObjects;
var I:Integer;
begin                                                          
 If V25.MouseObject<>nil then If (V25.MouseObject is TEditMap) then With TEditMap(V25.MouseObject) do begin
  For I:=Objects.Count-1 downTo 0 do
   If (TObject(Objects[I]) is TLot) then begin
    If TLot(Objects[I]).ClassHandle.Check=0 then Objects.AtDelete(I);
   end else
   If (TObject(Objects[I]) is TPointDot) then begin
    If TPointDot(Objects[I]).ClassHandle.Check=0 then Objects.AtDelete(I);
   end else
   If (TObject(Objects[I]) is TBmpMgr) then If TBmpMgr(Objects[I]).ClassHandle<>nil then  begin
    If TBmpMgr(Objects[I]).ClassHandle.Check=0 then Objects.AtDelete(I);
   end;
 end;
end;

procedure TFlyLayer.LayerListDblClick(Sender: TObject);
begin
 If TResource(LayerList.ActiveNode.Data).Resources.Count>0 then begin
   LayerList.XO:=XO;LayerList.YO:=YO;
   LayerList.MouseDblClick(LayerList);
   exit;
 end;
 SpeedButton3Click(nil);
end;

procedure TFlyLayer.LayerListMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
 XO:=X;YO:=Y;
end;

procedure TFlyLayer.sbProp1Click(Sender: TObject);
begin
 If V25.MouseObject <>nil then begin
  PropEditorForm.TwgForm:=V25.TwgForm;
  If V25.MouseObject is TEditMap then PropEditorForm.Execute(TEditMap(V25.MouseObject).Objects) else PropEditorForm.Execute(nil);
 end;
end;
                             
procedure TFlyLayer.N11Click(Sender: TObject);
begin
 SD.InitialDir:=MainPath+'\VClass';
If SD.Execute then
 V25.TwgForm.LayerTable.SaveToFile(SD.FileName);
end;

procedure TFlyLayer.N12Click(Sender: TObject);
begin
 OD.InitialDir:=MainPath+'\VClass';
 If OD.Execute then begin
  V25.TwgForm.LayerTable.LoadFromFile(OD.FileName);
 ClassRebuildBlock:=True;
  V25.TwgForm.ClassBuildII;UpdateImage;
 end;
end;

procedure TFlyLayer.N13Click(Sender: TObject);
begin
 OD.InitialDir:=MainPath+'\VClass';
 If OD.Execute then begin
  V25.TwgForm.LayerTable.LoadFromFile(OD.FileName,True);
 ClassRebuildBlock:=True;
  V25.TwgForm.ClassBuildII;UpdateImage;
 end;
end;

procedure TFlyLayer.N1001Click(Sender: TObject);
var I:Integer;ALayer:TResource;
begin
exit;
 If not CP1.Visible then ALayer:=CPLayers.Item else ALayer:=LayerList.ActiveNode.Data;
 For I:=0 to ALayer.Resources.Count-1 do
  TResource(ALayer.Resources[I]).Rang:=Trunc(TResource(ALayer.Resources[I]).Rang)+TMenuItem(Sender).Tag/100;
 LayerList.Refresh;
 CPLayers.Refresh;
 ClassRebuildBlock:=True;
 ClassRebuildIndex:=True;
 V25.TwgForm.ClassBuildII;
 UpdateImage;
end;

procedure TFlyLayer.miDupGroupClick(Sender: TObject);
begin
 V25.TwgForm.LayerTable.ActiveLayer:=LayerList.ActiveNode.Data;
 If MessageConfirm('Выполнить дублирование группы +['+V25.TwgForm.LayerTable.ActiveLayer.RecString+']') = mrNo then exit;
 try V25.TwgForm.LayerTable.DuplicateGroup; except exit; end;
 UpdateItems(True);
end;

procedure TFlyLayer.N20Click(Sender: TObject);
begin
 OD.InitialDir:=MainPath+'\VClass';
 If OD.Execute then begin
  V25.TwgForm.LayerTable.LoadFromFile(OD.FileName,False,True);
 ClassRebuildBlock:=True;
  V25.TwgForm.ClassBuildII;UpdateImage;
 end;
end;

procedure TFlyLayer.SpeedBtnOkClick(Sender: TObject);
begin
 Button1Click(Sender);
end;

end.