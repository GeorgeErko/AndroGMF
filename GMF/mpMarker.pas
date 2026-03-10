unit mpMarker;

interface uses tmpPainter,Collect, FMX.Graphics, newSelector, System.Types, System.UITypes;

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
  Colors:Array[0..7] of Integer;
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
  Selector:TSelector;
   Constructor Create(wnd:LongInt;mt,col,sz,mW:Integer);
   Procedure Draw(Canvas:TCanvas;X,Y:Double;inPix:Boolean = False);
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
  Constructor Create;
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
  Constructor Create(fixName_,Name_:String;Marker_:TMarker);
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
  Constructor Create(Wnd:LongInt);
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

implementation uses EcDot, newProcs, SysUtils;

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

{ TMarker }

procedure TMarker.AssignMarker(Marker: TMarker;Canvas:TCanvas);
begin
 Draw(Canvas,mX,mY);
  ID:='';
  mType:=Marker.mType;
  Size:=Marker.Size;
  Color:=Marker.Color;
  mWidth:=Marker.mWidth;
  Rotation:=Marker.Rotation;
 Draw(Canvas,mx,mY);
end;

constructor TMarker.Create(wnd: LongInt; mt, col, sz, mW: Integer);
begin
 OriginalSize:=sz;
 hWndParent:=wnd;
 mType:=mt; Color:=col; Size:=sz;
// mWidth:=mW;
 mX:=xyNull;
 Showing:=False;
 Iter:=0;
 Angle:=0;
 ID:='';
end;

procedure TMarker.Draw(Canvas: TCanvas;X,Y:Double;inPix:Boolean = False);
var xx,yy:Integer;r,I:Integer;                  
    {$IFDEF MSWINDOWS}
    Pen,Rop,Brush:hPen;
    {$ENDIF}
    Col,Col2:PCollection;
    D,D2:TDot;
    wr:Integer;
    bm:Boolean;
    Comm:TDrawLines;
    BMP:TBitmap;
    XOld,YOld:Integer;
    OldCanvas:TCanvas;
    {$IFDEF MSWINDOWS}
    Br:hBrush;
    R1:TRect;
    CM:TCopyMode;
    {$ENDIF}
    penColor:Integer;
begin
 If X=xyNull then Exit;
 With Selector do begin
  try
  If not inPix then begin xx:=XPix(X);yy:=YPix(Y);end else begin xx:=Round(X);yy:=Round(Y);end;
  except MessageError('Ошибка: mpMarker строка 215');Writeln('Exit',TiMeToStr(Now));exit;end;
  r:=Size div 2;
 // рисуем крест заданного размера формы и цвета
  bm:=GGraphSet.bmGlass;
  GGraphSet.bmGlass:=True;
  try
  XOld:=XX;YOld:=YY;
  OldCanvas:=Canvas;
  BMP:=TBitmap.Create;BMP.Width:=Size+2;BMP.Height:=Size+2;
  XX:=BMP.Width div 2;YY:=BMP.Height div 2;
  Canvas:=BMP.Canvas;
  {$IFDEF MSWINDOWS}
  R1.Left:=0;R1.Top:=0;R1.Right:=BMP.Width;R1.Bottom:=BMP.Height;
 // Br:=CreateSolidBrush(GlobalSettings.Settings.gsWindowColor);
  Br:=CreateSolidBrush(clBlack);
  FillRect(Canvas.Handle,R1,Br);
  DeleteObject(Br);
  {$ELSE}
  BMP.Clear(TAlphaColors.Black);
  {$ENDIF}
  If GlobalSettings.Settings.gsWindowColor <> TAlphaColors.Black then begin
   If Color = TAlphaColors.White then penColor:=notColor(Color) else
   penColor:=notColor(Color)
  end else begin
   If Color = TAlphaColors.Black then penColor:=notColor(Color) else
   penColor:=Color;
  end;
   {$IFDEF MSWINDOWS}
   Pen:=SelectObject(Canvas.Handle,CreatePen(ps_Solid,mWidth,penColor));
   {$ELSE}
   Canvas.Stroke.Kind:=TBrushKind.Solid;
   Canvas.Stroke.Color:=TAlphaColor(penColor);
   Canvas.Stroke.Thickness:=mWidth;
   Canvas.Fill.Kind:=TBrushKind.Solid;
   Canvas.Fill.Color:=TAlphaColor(penColor);
   {$ENDIF}
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
   Comm.PlayLines(Canvas,Angle);
   Comm.Free;
   {$IFDEF MSWINDOWS}
   CM:=OldCanvas.CopyMode;
   OldCanvas.CopyMode:=cmSrcInvert;
   OldCanvas.Draw(XOld-XX,YOld-YY,BMP);
   OldCanvas.CopyMode:=CM;
   {$ELSE}
   OldCanvas.Blending:=True;
  // OldCanvas.BlendMode := TBlendMode.Invert;
   OldCanvas.DrawBitmap(BMP,RectF(0,0,BMP.Width,BMP.Height),RectF(XOld-XX,YOld-YY,XOld-XX+BMP.Width,YOld-YY+BMP.Height),1);
  // OldCanvas.BlendMode:=TBlendMode.Normal;
     OldCanvas.Blending:=False;
   {$ENDIF}
  finally
   GGraphSet.bmGlass:=bm;
  end;
  {$IFDEF MSWINDOWS}
  SetRop2(Canvas.Handle,Rop);
  DeleteObject(SelectObject(Canvas.Handle,Pen));
  {$ENDIF}
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
 If Canvas<>nil then Draw(Canvas,mX,mY);
  mX:=X;mY:=Y;
  Angle:=newAngle;
 If Canvas<>nil then Draw(Canvas,mX,mY);
// Writeln(2,' ',XPix(mX),' ',YPix(mY));
 If moveCur=moveCursor then begin
  PC.X:=Selector.XPix(mX);PC.Y:=Selector.YPix(mY);
  {$IFDEF WIN64}
  ClientToScreen(hWndParent,PC);
  SetCursorPos(PC.X,PC.Y);
  {$ELSE}
   assert(False,'TMarker.Move');
  {$ENDIF}
 end;
end;

procedure TMarker.Remove(Canvas: TCanvas; RemoveName: String);
begin
// Writeln('ReMoveMarker..',RemoveName);
 try
 If mX<>xyNull then Draw(Canvas,mX,mY);
 except end;
 mX:=xyNull;
end;

procedure TMarker.Resize(Canvas: TCanvas; newSize: Integer);
begin
 Draw(Canvas,mX,mY);
  Size:=newSize;
 Draw(Canvas,mX,mY);
end;

function TMarker.Visible: boolean;
begin
 Result:=mX<>xyNull;
end;

{ TMarkerList }

procedure TMarkerList.AddMarker(Style: Integer);
begin
 Markers.Insert(TMarker.Create(0,Style,0,0,0));
end;

constructor TMarkerList.Create;
begin
 Markers:=PCollection.Create(1);
end;

destructor TMarkerList.Destroy;
begin
 Markers.Free;
end;

procedure TMarkerList.Draw(Canvas:TCanvas;Index,X,Y:Integer);
begin
 Marker[Index].Draw(Canvas,X,Y,True);
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
    {$IFDEF MSWINDOWS}
    MoveToEx(Canvas.Handle,Comm[I].X,Comm[I].Y,nil);
    {$ELSE}
    CurX:=Comm[I].X;CurY:=Comm[I].Y;
    {$ENDIF}
   end;
   commLineTo:begin
    {$IFDEF MSWINDOWS}
    LineTo(Canvas.Handle,Comm[I].X,Comm[I].Y);
    {$ELSE}
    Canvas.DrawLine(PointF(CurX,CurY),PointF(Comm[I].X,Comm[I].Y),1);
    CurX:=Comm[I].X;CurY:=Comm[I].Y;
    {$ENDIF}
    // Writeln('ColLinePix=',Comm[I].Color);
   end;
   commSetPixel:begin
    {$IFDEF MSWINDOWS}
    SetPixel(Canvas.Handle,Comm[I].X,Comm[I].Y,Comm[I].Color);
    {$ELSE}
    Canvas.FillRect(RectF(Comm[I].X,Comm[I].Y,Comm[I].X+1,Comm[I].Y+1),0,0,[],1);
    {$ENDIF}
    // Writeln('ColsetPix=',Comm[I].Color);
    end;
  end;
end;

constructor TMarkerOperation.Create(fixName_,Name_: String; Marker_: TMarker);
begin
 fixName:=fixName_;Name:=Name_;Marker:=Marker_;Checked:=True;
end;

constructor TMarkerOperation.Load(Buf: TBufStream);
begin
 // считываем имя и свойства маркера
 fixName:=Buf.ReadString;
 Name:=Buf.ReadString;
 Marker:=TMarker.Create(0,0,0,0,0);
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
var clRed: Integer;
begin
clRed := TAlphaColors.Red;
 Operations:=PCollection.Create(1);
 Operations.Insert(TMarkerOperation.Create('mvPoint','Захват точки',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvLine','Захват отрезка',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvPolygon','Захват полигона',TMarker.Create(Wnd,mtCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvCenterLine','Захват центра отрезка',TMarker.Create(Wnd,mtTriangle,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvCenter','Захват центра фигуры',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvInterSect','Пересечение примитивов',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
// Operations.Insert(TMarkerOperation.Create('mvInter','Пересечение с направляющей',TMarker.Create(Wnd,mtDiagCross,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvPointDot','Захват блока/текста/знака и т.п.',TMarker.Create(Wnd,mtRect,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvGrid','Захват узла/линии сетки',TMarker.Create(Wnd,mtRect,clRed,20,0)));
 Operations.Insert(TMarkerOperation.Create('mvPerpend','Перпендикуляр к линии',TMarker.Create(Wnd,mtCross,clRed,10,0)));
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
 Operations:=PCollection(Buf.Get);
 If Operations.Count<9 then begin
  Operations.Insert(TMarkerOperation.Create('mvPerpend','Перпендикуляр к линии',
                     TMarker.Create({ApplicationMainForm.Handle}0,mtCross, TAlphaColors.Red,10,0)));
 end;
end;

procedure TMarkerView.Store(Buf: TBufStream);
begin
 Buf.Put(Operations);
end;

initialization
finalization
 MarkerList.Free;
end.
