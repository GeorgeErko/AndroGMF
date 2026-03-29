unit mpMarker;

interface uses tmpPainter, Collect, FMX.Graphics, System.Types, System.UITypes,
               System.Skia, ogcBasic;

const
 xyNull = -1000000000;
{}
 mtCross = 0;
 mtDiagCross = 1;
 mtRect = 2;
 mtTriangle = 3;
 mtInvTriangle = 4;
 mt2Triangle = 5;
 mtMarker = 6;
{}
 moveNone = 0;
 moveCursor = 1;


const
 commMoveTo = 0;
 commLineTo = 1;
 commSetPixel = 2;

type
 TLineComm = class (TTwgObject)
  X,Y:Integer;Comm:Integer;Color:Integer;
  Constructor Create(_Comm:Integer;_X,_Y:Integer;_Color:Integer = 0);
 end;

 TDrawLines = class (TTwgObject)
 private
  function GetComm(Index: Integer): TLineComm;
 public
  X,Y:Integer;
  Comms:PCollection;
   Constructor Create(_X,_Y:Integer);
   Destructor Destroy;override;
   Procedure MoveTo_(X,Y:Integer);
   Procedure LineTo_(X,Y:Integer);
   Procedure SetPixel_(X,Y:Integer;Color:Integer);
   Procedure PlayLines(Canvas:TCanvas;Angle:Double);
  //
   Property Comm[Index:Integer]:TLineComm read GetComm;
 end;

type

 { TMarker }

 TMarker = class (TTwgObject)
  mType:Integer;
  Color:Integer;
  Colors:Array[0..7] of TColorRef;
  OriginalSize:Integer;
  Size:Integer;
  mX,mY,mZ:Double;
  hWndParent:THandle;
 {}
  Showing:boolean;
  Iter:Integer;
 {}
  Angle:Double;
  mWidth:Integer;
  Rotation:Boolean;
 {}
  markermoveStyle:Byte;
 {}
  ID:String;
 {}
  TwgForm:Pointer;
  Selector: Pointer;
   Constructor Create(Selector_: Pointer; wnd:LongInt;mt,col,sz,mW:Longint);
   Destructor Destroy;override;
   Procedure Draw(Canvas:TCanvas;X,Y:Double;inPix:Boolean = False); overload;
   Procedure Draw(const Canvas: ISkCanvas; X, Y: Double; inPix: Boolean = False); overload;
 {}
   Procedure Resize(Canvas:TCanvas;newSize:Integer);
   Procedure Move(Canvas:TCanvas;X,Y:Double;moveCur:Integer=moveNone;newAngle:Double=0;MoveName:String='');
   Procedure Remove(Canvas:TCanvas;RemoveName:String='');
   Function Visible:boolean;
 {}
   Procedure AssignMarker(Marker:TMarker;Canvas:TCanvas);
 end;

 TMarkerList = class (TTwgObject)
  private
   fSize:Integer;
   fColor:Integer;
   fWidth:Integer;
    function GetMarker(Index: Integer): TMarker;
    procedure SetColor(const Value: Integer);
    procedure SetSize(const Value: Integer);
    procedure SetWidth(const Value: Integer);
  public
  Markers:PCollection;
  Selector: Pointer;
  Constructor Create(Selector_: Pointer);
  Destructor Destroy;override;
  Procedure AddMarker(Style:Integer);
  Procedure Draw(Canvas:TCanvas;Index,X,Y:Integer);
 //
  Property Marker[Index:Integer]:TMarker read GetMarker;default;
  Property Size:Integer read fSize write SetSize;
  Property Color:Integer read fColor write SetColor;
  Property Width:Integer read fWidth write SetWidth;
 end;

type
 TMarkerOperation = class (TTwgObject)
  fixName:String;
  Name:String;
  Marker:TMarker;
  Checked:Boolean;
  Dop:Array[0..100-SizeOf(Integer)-1] of byte;
 //
  Selector: Pointer;
  Constructor Create(Selector_: Pointer; fixName_,Name_:String;Marker_:TMarker);
  Constructor Load(Buf:TBufStream);override;
  Procedure Store(Buf:TBufStream);override;
 end;

 TMarkerView = class (TTwgObject)
  private
    function GetMarkerOperation(Index: Integer): TMarkerOperation;
    function GetNameOf(Index: String): TMarker;
    function GetMarkerChecked(Index: String): boolean;
  public
  Operations:PCollection;
  Selector: Pointer;
  Constructor Create(Selector_: Pointer);
  Destructor Destroy;override;
 //
  Constructor Load(Buf:TBufStream);override;
  Procedure Store(Buf:TBufStream);override;
  Property Operation[Index:Integer]:TMarkerOperation read GetMarkerOperation;default;
  Property Checked[Index:String]:boolean read GetMarkerChecked;
  Property NameOf[Index:String]:TMarker read GetNameOf;
  Function Count:Integer;
 end;

var MarkerList:TMarkerList;

{ TLotMarker = class(TThread)
  Lot:TLot;
  Constructor Create();
 end;}

Procedure Rotate(X2,Y2,Angle:Double;var X,Y:Double);
procedure Move(Dx, Dy: Double; var X, Y: Double);
Procedure RotateDots(XX, YY, Angle: Double; Col: PCollection);

procedure DrawMarkerOverlay(const ASelector: Pointer; const Canvas: ISkCanvas);
procedure RequestMarkerRedraw(const ASelector: Pointer);

implementation uses EcDot, newProcs, SysUtils, newSelector, ogcDrawerSkia,
                 System.Generics.Collections, Writer, FMX.Controls, FMX.Skia,
                 System.Classes;

var
  MarkerRegistry: TList<TMarker>;

procedure RegisterMarker(const M: TMarker);
begin
  if M = nil then
    Exit;
  if MarkerRegistry = nil then
    MarkerRegistry := TList<TMarker>.Create;
  if MarkerRegistry.IndexOf(M) < 0 then
    MarkerRegistry.Add(M);
end;

procedure UnregisterMarker(const M: TMarker);
var
  Idx: Integer;
begin
  if (M = nil) or (MarkerRegistry = nil) then
    Exit;
  Idx := MarkerRegistry.IndexOf(M);
  if Idx >= 0 then
    MarkerRegistry.Delete(Idx);
end;

procedure DrawMarkerOverlay(const ASelector: Pointer; const Canvas: ISkCanvas);
var
  I: Integer;
  M: TMarker;
  Sel: TSelector;
begin
  if (Canvas = nil) or (ASelector = nil) or (MarkerRegistry = nil) then
    Exit;
  Sel := TSelector(ASelector);
  if Sel = nil then
    Exit;
  for I := 0 to MarkerRegistry.Count - 1 do
  begin
    M := MarkerRegistry[I];
    if (M <> nil) and (M.Selector = ASelector) and M.Visible then
      M.Draw(Canvas, Sel.XPix(M.mX), Sel.YPix(M.mY), True);
  end;
end;

procedure RequestMarkerRedraw(const ASelector: Pointer);
var
  Sel: TSelector;
  Ov: TSkPaintBox;
begin
  if ASelector = nil then
    Exit;
  Sel := TSelector(ASelector);

  Ov := nil;
  try
    if Sel <> nil then
      Ov := Sel.ovrPainter;
  except
  end;

  if Ov <> nil then
    Ov.Redraw
  else
    Exit;
end;

Procedure Rotate(X2,Y2,Angle:Double;var X,Y:Double);
var XD,YD,XD1:Double;
    Dx,Dy:Double;
begin
 XD:=-Y;
 YD:=X;XD1:=XD;
 XD:=XD*COS(Angle)-SIN(Angle)*YD;
 YD:=COS(Angle)*YD+SIN(Angle)*XD1;
 X:=YD;
 Y:=-XD;
end;

Procedure Move(Dx, Dy: Double; var X, Y: Double);
begin
 X:=X+Dx;Y:=Y+Dy;
end;

Procedure RotateDots(XX, YY, Angle: Double; Col: PCollection);
var I:Integer;Dot:TDot;Dx,Dy:Double;XXX,YYY:Double;
begin
 For I:=0 to Col.Count-1 do begin
  Dot:=Col.At(I);
  Rotate(0,0,Angle,Dot.XDot,Dot.YDot);
  XXX:=XX;YYY:=YY;
  Rotate(XXX,YYY,Angle,XXX,YYY);
  Dx:=XXX-XX;Dy:=YYY-YY;
  Move(-Dx,-Dy,Dot.XDot,Dot.YDot);
 end;
end;

function S(P: Pointer): TSelector;
begin
 Result := P;
end;

{ TMarker }

procedure TMarker.AssignMarker(Marker: TMarker;Canvas:TCanvas);
begin
  ID:='';
  mType:=Marker.mType;
  Size:=Marker.Size;
  Color:=Marker.Color;
  mWidth:=Marker.mWidth;
  Rotation:=Marker.Rotation;
 RequestMarkerRedraw(Selector);
end;

constructor TMarker.Create(Selector_: Pointer; wnd: LongInt; mt, col, sz, mW: Longint);
begin
 Selector := Selector_;
 OriginalSize:=sz;
 hWndParent:=wnd;
 mType:=mt; Color:=col; Size:=sz;
// mWidth:=mW;
 mX:=xyNull;
 Showing:=False;
 Iter:=0;
 Angle:=0;
 ID:='';
 RegisterMarker(Self);
end;

destructor TMarker.Destroy;
begin
  UnregisterMarker(Self);
  inherited;
end;

procedure TMarker.Draw(const Canvas: ISkCanvas; X, Y: Double; inPix: Boolean);
var
  xx, yy: Single;
  r: Single;
  penColor: TAlphaColor;
  ViewScale: Single;
  Sel: TSelector;
begin
// Writein([inpix, x, y]);
  if Canvas = nil then
    Exit;
  if X = xyNull then
    Exit;

  try
    if inPix then
    begin
      xx := Single(X);
      yy := Single(Y);
    end
    else
    begin
      xx := Single(X);
      yy := Single(Y);
    end;
  except
    Exit;
  end;

  ViewScale := 1;
  if Selector <> nil then
  begin
    try
      ViewScale := Single(TSelector(Selector).GetScale);
    except
      ViewScale := 1;
    end;
  end;
  if ViewScale <= 0 then
    ViewScale := 1;

  r := Size * 0.5;
  if r < 1 then
    r := 1;
 //
  penColor := TAlphaColor(Color);
 //
  Sel := TSelector(Selector);
  if mWidth > 0 then
    Sel.ovrPaint.StrokeWidth := mWidth + 1
  else
    Sel.ovrPaint.StrokeWidth := 2;
  Sel.ovrPaint.Color := penColor;
//
  If (not Rotation) or (mType=mtMarker) then Angle:=0;
//  Writein(['Ang=', Angle]);
 //
  Canvas.Save;
  try
    Canvas.Translate(xx, yy);
    if (Abs(ViewScale) > 1e-6) and (Abs(ViewScale - 1) > 1e-6) then
      Canvas.Scale(1 / ViewScale, 1 / ViewScale);
    if Abs(Angle) > 1e-6 then
      Canvas.Rotate(Angle * 57.29577951308232);
    case mType of
      mtCross:
        begin
          Canvas.DrawLine(-r, 0, r, 0, Sel.ovrPaint);
          Canvas.DrawLine(0, -r, 0, r, Sel.ovrPaint);
        end;
      mtDiagCross:
        begin
          Canvas.DrawLine(-r, -r, r, r, Sel.ovrPaint);
          Canvas.DrawLine(r, -r, -r, r, Sel.ovrPaint);
        end;
      mtRect:
        begin
          Canvas.DrawRect(TRectF.Create(-r, -r, r, r), Sel.ovrPaint);
        end;
      mtTriangle:
        begin
          Canvas.DrawLine(0, -r, r, r, Sel.ovrPaint);
          Canvas.DrawLine(r, r, -r, r, Sel.ovrPaint);
          Canvas.DrawLine(-r, r, 0, -r, Sel.ovrPaint);
        end;
      mtInvTriangle:
        begin
          Canvas.DrawLine(0, r, -r, -r, Sel.ovrPaint);
          Canvas.DrawLine(-r, -r, r, -r, Sel.ovrPaint);
          Canvas.DrawLine(r, -r, 0, r, Sel.ovrPaint);
        end;
    else
      begin
        Canvas.DrawLine(-r, 0, r, 0, Sel.ovrPaint);
        Canvas.DrawLine(0, -r, 0, r, Sel.ovrPaint);
      end;
    end;
  finally
    Canvas.Restore;
  end;
end;

procedure TMarker.Draw(Canvas: TCanvas;X,Y:Double;inPix:Boolean = False);
var xx,yy:Integer;r,I:Integer;
    Col,Col2:PCollection;
    D,D2:TDot;
    wr:Integer;
    bm:Boolean;
    Comm:TDrawLines;
    BMP:TBitmap;
    XOld,YOld:Integer;
    OldCanvas:TCanvas;
    Br:hBrush;
    R1:TRect;
    penColor:Integer;

begin
 Exit;
 // рисуем крест заданного размера формы и цвета
  With S(Selector) do begin
  bm:=GGraphSet.bmGlass;
  GGraphSet.bmGlass:=True;
  try
  XOld:=XX;YOld:=YY;
  OldCanvas:=Canvas;
  BMP:=TBitmap.Create;BMP.Width:=Size+2;BMP.Height:=Size+2;
  XX:=BMP.Width div 2;YY:=BMP.Height div 2;
  Canvas:=BMP.Canvas;
  BMP.Clear(TAlphaColors.Black);
  If GlobalSettings.Settings.gsWindowColor <> TAlphaColors.Black then begin
   If Color = TAlphaColors.White then penColor:=notColor(Color) else
   penColor:=notColor(Color)
  end else begin
   If Color = TAlphaColors.Black then penColor:=notColor(Color) else
   penColor:=Color;
  end;
   Canvas.Stroke.Kind:=TBrushKind.Solid;
   Canvas.Stroke.Color:=TAlphaColor(penColor);
   Canvas.Stroke.Thickness:=mWidth;
   Canvas.Fill.Kind:=TBrushKind.Solid;
   Canvas.Fill.Color:=TAlphaColor(penColor);
   // Writeln('Col=',Color);
 // Brush:=SelectObject(Canvas.Handle,CreateSolidBrush(Color));
 // Rop:=SetRop2(Canvas.Handle,R2_NotXorPen);
  // вычисляем повернутый маркер
  //
  Comm:=TDrawLines.Create(xx,yy);
  Col:=PCollection.Create(1);
  Col2:=PCollection.Create(1);
  With Comm do
  Case mType of
   mtCross:begin
            MoveTo_(xx-r-1,yy);LineTo_(xx+r,yy);
            MoveTo_(xx,yy-r);LineTo_(xx,yy+r);
            If mWidth>0 then SetPixel_(xx-r-1,yy-1,(penColor));
            //MoveTo_(xx,yy);LineTo_(xx,yy-r);
           end;
   mtDiagCross:begin
                 MoveTo_(xx-r,yy-r);LineTo_(xx+r,yy+r);
                 MoveTo_(xx+r,yy-r);LineTo_(xx-r,yy+r);
               end;
   mtRect:begin
            MoveTo_(xx-r,yy-r);LineTo_(xx-r,yy+r);LineTo_(xx+r,yy+r);LineTo_(xx+r,yy-r);LineTo_(xx-r,yy-r);
            If mWidth>0 then begin
             SetPixel_(xx-r,yy-r,(penColor));SetPixel_(xx-r,yy+r,(penColor));SetPixel_(xx+r,yy+r,(penColor));SetPixel_(xx+r,yy-r,(penColor));
            end;
           end;
   mtTriangle:begin
               MoveTo_(xx,yy-r);LineTo_(xx+r,yy+r);LineTo_(xx-r,yy+r);LineTo_(xx,yy-r);
               If mWidth>0 then begin
                SetPixel_(xx,yy-r,(penColor));SetPixel_(xx+r,yy+r,(penColor));SetPixel_(xx-r,yy+r,(penColor));
               end;
              end;
   mtInvTriangle:begin
                  MoveTo_(xx,yy+r);LineTo_(xx-r,yy-r);LineTo_(xx+r,yy-r);LineTo_(xx,yy+r);
                 If mWidth>0 then begin
                  SetPixel_(xx,yy+r,(penColor));SetPixel_(xx-r,yy-r,(penColor));SetPixel_(xx+r,yy-r,(penColor));
                 end;
                 end;
   mt2Triangle:begin
                wr:=r div 2;
                MoveTo_(xx,yy);LineTo_(xx-wr,yy-r);LineTo_(xx+wr,yy-r);LineTo_(xx,yy);
                              LineTo_(xx+wr,yy+r);LineTo_(xx-wr,yy+r);LineTo_(xx,yy);
                             If mWidth>0 then begin
                              SetPixel_(xx-wr,yy-r,(penColor));SetPixel_(xx-wr,yy-r-1,(penColor));SetPixel_(xx+wr,yy-r,(penColor));
                              SetPixel_(xx+wr,yy+r,(penColor));SetPixel_(xx-wr,yy+r,(penColor));
                             end;
                              //SetPixel_(xx,yy,(penColor));
               end;
   mtMarker:begin
              Col.Insert(TDot.Create(xx-r,yy,0));Col.Insert(TDot.Create(xx+r,yy,0));
              Col.Insert(TDot.Create(xx,yy-r,0));Col.Insert(TDot.Create(xx,yy+r,0));
               RotateDots(xx,yy,Angle,Col);
              Col2.Insert(TDot.Create(xx-r/2,yy,0));Col2.Insert(TDot.Create(xx+r/2,yy,0));
              Col2.Insert(TDot.Create(xx,yy-r/2,0));Col2.Insert(TDot.Create(xx,yy+r/2,0));
            // Col2.Insert(TDot.Create(xx-r/2,yy,0));
               RotateDots(xx,yy,Angle,Col2);
             For I:=0 to Col.Count-1 do begin
              D:=Col[I];
              D2:=Col2[I];
              MoveTo_(Round(D2.XDot),Round(D2.YDot));LineTo_(Round(D.XDot),Round(D.YDot));
             // If I=0 then RectAngle(Round(D.XDot-2),Round(D.YDot-2),Round(D.XDot+2),Round(D.YDot+2));
             end;
            end;
  end;
   If (not Rotation) or (mType=mtMarker) then Angle:=0;
   Comm.PlayLines(Canvas, Angle);
   Comm.Free;
   OldCanvas.Blending:=True;
  // OldCanvas.BlendMode := TBlendMode.Invert;
   OldCanvas.DrawBitmap(BMP,RectF(0,0,BMP.Width,BMP.Height),RectF(XOld-XX,YOld-YY,XOld-XX+BMP.Width,YOld-YY+BMP.Height),1);
  // OldCanvas.BlendMode:=TBlendMode.Normal;
    OldCanvas.Blending:=False;
  finally
   GGraphSet.bmGlass:=bm;
  end;
  Showing:=not Showing;
  Inc(Iter);
  Col.Free;
  Col2.Free;
  BMP.Free;
 end; // With Selector
end;

procedure TMarker.Move(Canvas: TCanvas; X, Y: Double; moveCur: Integer = moveNone;newAngle:Double=0;MoveName:String='');
var PC:TPoint;
begin
// Writeln(1,' ',X,' ',Y);
// Writeln('MoveMarker..',MoveName);
//  WriteIn(['Marker.Move2=', X, Y]);
  mX:=X;mY:=Y;
  Angle:=newAngle;
// Writeln(2,' ',XPix(mX),' ',YPix(mY));
 If moveCur=moveCursor then begin
  PC.X:=S(Selector).XPix(mX);PC.Y:=S(Selector).YPix(mY);
//  {$IFDEF WIN64}
//  ClientToScreen(hWndParent,PC);
//  SetCursorPos(PC.X,PC.Y);
//  {$ELSE}
//   assert(False,'TMarker.Move');
 // {$ENDIF}
 end;
 RequestMarkerRedraw(Selector);
end;

procedure TMarker.Remove(Canvas: TCanvas; RemoveName: String = '');
begin
// Writeln('ReMoveMarker..',RemoveName);
 mX:=xyNull;
 RequestMarkerRedraw(Selector);
end;

procedure TMarker.Resize(Canvas: TCanvas; newSize: Integer);
begin
  Size:=newSize;
 RequestMarkerRedraw(Selector);
end;

function TMarker.Visible: boolean;
begin
 Result:=mX<>xyNull;
end;

{ TMarkerList }

procedure TMarkerList.AddMarker(Style: Integer);
begin
 Markers.Insert(TMarker.Create(Selector, 0,Style,0,0,0));
end;

constructor TMarkerList.Create;
begin
 Selector := Selector_;
 Markers:=PCollection.Create(1);
end;

destructor TMarkerList.Destroy;
begin
 Markers.Free;
end;

procedure TMarkerList.Draw(Canvas:TCanvas;Index,X,Y:Integer);
begin
 Exit;
end;

function TMarkerList.GetMarker(Index: Integer): TMarker;
begin
 Result:=Markers[Index];
end;

procedure TMarkerList.SetColor(const Value: Integer);
var I:Integer;
begin
 fColor:=Value;
 For I:=0 to Markers.Count-1 do Marker[I].Color:=Value;
end;

procedure TMarkerList.SetSize(const Value: Integer);
var I:Integer;
begin
 If Value > 50 then exit;
 fSize:=Value;
 For I:=0 to Markers.Count-1 do Marker[I].Size:=Value;
end;

procedure TMarkerList.SetWidth(const Value: Integer);
var I:Integer;
begin
 fWidth:=Value;
 For I:=0 to Markers.Count-1 do Marker[I].mWidth:=Value;
end;

{ TLineComm }

constructor TLineComm.Create(_Comm: Integer; _X, _Y: Integer;_Color:Integer = 0);
begin
 Comm:=_Comm;
 X:=_X;Y:=_Y;
 Color:=_Color;
end;

{ TDrawLines }

constructor TDrawLines.Create;
begin
 X:=_X;Y:=_Y;
 Comms:=PCollection.Create(1);
end;

destructor TDrawLines.Destroy;
begin
 Comms.Free;
end;

function TDrawLines.GetComm(Index: Integer): TLineComm;
begin
 Result:=Comms[Index];
end;

procedure TDrawLines.LineTo_(X, Y: Integer);
begin
 Comms.Insert(TLineComm.Create(commLineTo,X,Y));
end;

procedure TDrawLines.MoveTo_(X, Y: Integer);
begin
 Comms.Insert(TLineComm.Create(commMoveTo,X,Y));
end;

procedure TDrawLines.SetPixel_(X, Y, Color: Integer);
begin
 Comms.Insert(TLineComm.Create(commSetPixel,X,Y,Color));
end;

procedure TDrawLines.PlayLines(Canvas: TCanvas;Angle:Double);
var I:Integer;Col:PCollection;
    CurX,CurY:Integer;
begin
// поворачиваем точки
 Col:=PCollection.Create(1);
  For I:=0 to Comms.Count-1 do Col.Insert(TDot.Create(Comm[I].X,Comm[I].Y,0));
  RotateDots(X,Y,Angle,Col);
  For I:=0 to Col.Count-1 do begin Comm[I].X:=Round(TDot(Col[I]).XDot);Comm[I].Y:=Round(TDot(Col[I]).YDot);end;
 Col.Free;
//
 CurX:=0;CurY:=0;
 For I:=0 to Comms.Count-1 do
  Case Comm[I].Comm of
   commMoveTo:begin
    CurX:=Comm[I].X;CurY:=Comm[I].Y;
   end;
   commLineTo:begin
    Canvas.DrawLine(PointF(CurX,CurY),PointF(Comm[I].X,Comm[I].Y),1);
    CurX:=Comm[I].X;CurY:=Comm[I].Y;
    // Writeln('ColLinePix=',Comm[I].Color);
   end;
   commSetPixel:begin
    Canvas.FillRect(RectF(Comm[I].X,Comm[I].Y,Comm[I].X+1,Comm[I].Y+1),0,0,[],1);
    // Writeln('ColsetPix=',Comm[I].Color);
    end;
  end;
end;

constructor TMarkerOperation.Create(Selector_: Pointer; fixName_,Name_: String; Marker_: TMarker);
begin
 Selector := Selector_;
 fixName:=fixName_;Name:=Name_;Marker:=Marker_;Checked:=True;
end;

constructor TMarkerOperation.Load(Buf: TBufStream);
begin
 // считываем имя и свойства маркера
 Selector := Buf.Selector;
 fixName:=Buf.ReadString;
 Name:=Buf.ReadString;
 Marker:=TMarker.Create(Selector, 0,0,0,0,0);
 Buf.Read(Marker.Color,SizeOf(Marker.Color));
 Buf.Read(Marker.Size,SizeOf(Marker.Size));
 Buf.Read(Marker.mWidth,SizeOf(Marker.mWidth));
 Buf.Read(Marker.Rotation,SizeOf(Marker.Rotation));
 Buf.Read(Marker.mType,SizeOf(Marker.mType));
 Buf.Read(Checked,SizeOf(Checked));
 Buf.Read(Dop,SizeOf(Dop));
end;

procedure TMarkerOperation.Store(Buf: TBufStream);
begin
 Buf.WriteString(fixName);
 Buf.WriteString(Name);
 Buf.Write(Marker.Color,SizeOf(Marker.Color));
 Buf.Write(Marker.Size,SizeOf(Marker.Size));
 Buf.Write(Marker.mWidth,SizeOf(Marker.mWidth));
 Buf.Write(Marker.Rotation,SizeOf(Marker.Rotation));
 Buf.Write(Marker.mType,SizeOf(Marker.mType));
 Buf.Write(Checked,SizeOf(Checked));
 Buf.Write(Dop,SizeOf(Dop));
end;

{ TMarkerView }

function TMarkerView.Count: Integer;
begin
 Result:=Operations.Count;
end;

constructor TMarkerView.Create;
var clRed, Wnd: Longint;
begin
 Selector := Selector_;
 clRed := TAlphaColors.Red;
 Operations:=PCollection.Create(1);
 Operations.Insert(TMarkerOperation.Create(Selector, 'mvPoint','Захват точки',TMarker.Create(Selector,Wnd, mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvLine','Захват отрезка',TMarker.Create(Selector,Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvPolygon','Захват полигона',TMarker.Create(Selector,Wnd,mtCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvCenterLine','Захват центра отрезка',TMarker.Create(Selector,Wnd,mtTriangle,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvCenter','Захват центра фигуры',TMarker.Create(Selector,Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvInterSect','Пересечение примитивов',TMarker.Create(Selector,Wnd,mtDiagCross,clRed,20,0)));
// Operations.Insert(TMarkerOperation.Create('mvInter','Пересечение с направляющей',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvPointDot','Захват блока/текста/знака и т.п.',TMarker.Create(Selector,Wnd,mtRect,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvGrid','Захват узла/линии сетки',TMarker.Create(Selector,Wnd,mtRect,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create(Selector,'mvPerpend','Перпендикуляр к линии',TMarker.Create(Selector,Wnd,mtCross,clRed,10,0)));
// Operations.Insert(TMarkerOperation.Create('Захват линии сетки',TMarker.Create(Wnd,mtCross,clRed,20,0)));
end;

destructor TMarkerView.Destroy;
begin
 Operations.Free;
end;

function TMarkerView.GetMarkerChecked(Index: String): boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Operations.Count-1 do If Operation[I].fixName=Index then Result:=Operation[I].Checked;
end;

function TMarkerView.GetMarkerOperation(Index: Integer): TMarkerOperation;
begin
 Result:=Operations[Index];
end;

function TMarkerView.GetNameOf(Index: String): TMarker;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to Operations.Count-1 do If Operation[I].fixName=Index then Result:=Operation[I].Marker;
 If Result = nil then Result:=Operation[0].Marker;
end;

Constructor TMarkerView.Load(Buf: TBufStream);
begin
 Selector := Buf.Selector;
 Operations:=PCollection(Buf.Get);
 If Operations.Count<9 then begin
  Operations.Insert(TMarkerOperation.Create(Selector, 'mvPerpend','Перпендикуляр к линии',
                     TMarker.Create(Selector, 0,mtCross, TAlphaColors.Red,10,0)));
 end;
end;

procedure TMarkerView.Store(Buf: TBufStream);
begin
 Buf.Put(Operations);
end;

initialization
finalization
// MarkerList.Free;
end.
