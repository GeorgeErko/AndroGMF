unit drawGrid;

interface uses Collect, newSelector, maths_Basic, FMX.Graphics;


type
 TTile = class(TTwgObject)
  Left,Top,Right,Bottom:Double;
  Image:TBitmap;
  Constructor Create(L,T,R,B:Double);
  Destructor Destroy;override;
  Function Width:Double;
  Function Height:Double;
 end;

type
 TGridPath = class (TTwgObject)
  XLine,YLine:PCollection;
  Selector: TSelector;
  Constructor Create(Selector_: TSelector);
   Procedure Paint(Canvas:TCanvas);
  Destructor Destroy;override;
 //
  Function CellWidth:Double;
  Function CellHeight:Double;
 //
  Function GetNearestPoint(var X,Y:Double):boolean;
 //
//  Function GetTiles(P:PCollection):Integer;
 end;

implementation uses EcDot, WpTwigs, WptForm2, newProcs;

{ TTile }

constructor TTile.Create(L, T, R, B: Double);
begin
 Left:=L;Top:=T;Right:=R;B:=Bottom;
 Image:=TBitmap.Create;
end;

destructor TTile.Destroy;
begin
 Image.Free;
end;

function TTile.Height: Double;
begin
 Result:=Bottom-Top;
end;

function TTile.Width: Double;
begin
 Result:=Right-Left;
end;

{ TGridPath }

function TGridPath.CellHeight: Double;
begin
 With TForm2(Selector.GTwgForm).Settings do Result:=(10*gsGridCellHeight*gsScale)/1000;
end;

function TGridPath.CellWidth: Double;
begin
 With TForm2(Selector.GTwgForm).Settings do Result:=(10*gsGridCellWidth*gsScale)/1000;
end;

constructor TGridPath.Create;
begin
 Selector := Selector_;
 XLine:=PCollection.Create(1);
 YLine:=PCollection.Create(1);
end;

destructor TGridPath.Destroy;
begin
 XLine.Free;
 YLine.Free;
end;

function TGridPath.GetNearestPoint(var X, Y: Double): boolean;
var XX,YY,XXR,YYR:Double;I,J:Integer;Tw:TTwig;
    Dist,MinDist:Double;Index:Integer;
begin
Result:=False;
with TForm2(Selector.GTwgForm).Settings do begin
 If not gsShowGrid then Exit;
  For I:=0 to XLine.Count-1 do
   For J:=0 to YLine.Count-1 do
    If Selector.XRasst(Distance(TDot(XLine[I]).XDot,TDot(YLine[J]).YDot,X,Y))<=psAutoDisst then begin
     Result:=True;
     X:=TDot(XLine[I]).XDot;Y:=TDot(YLine[J]).YDot;
     exit;
    end;
  If gsGridType = 0 then With Selector do begin
   MinDist:=100000;
   For I:=0 to XLine.Count-1 do With TDot(XLine[I]) do begin
    Tw:=TTwig.Create(Selector, 0);Tw.Insert(TDot.Create(XDot,GRect.Top,0));Tw.Insert(TDot.Create(XDot,GRect.Bottom,0));
    Dist:=Tw.GetTwigDist(X,Y,XX,YY);
    If Dist<MinDist then begin MinDist:=Dist;Index:=I;XXR:=XX;YYR:=YY;end;
    Tw.Free;
   end;
   For I:=0 to YLine.Count-1 do With TDot(YLine[I]) do begin
    Tw:=TTwig.Create(Selector, 0);Tw.Insert(TDot.Create(GRect.Left,YDot,0));Tw.Insert(TDot.Create(GRect.Right,YDot,0));
    Dist:=Tw.GetTwigDist(X,Y,XX,YY);
    If Dist<MinDist then begin MinDist:=Dist;Index:=-I;XXR:=XX;YYR:=YY;end;
    Tw.Free;
   end;
   If Selector.XRasst(MinDist) <= psAutoDisst then begin
    Result:=True;
    X:=XXR;Y:=YYR;
    Exit;
   end;
  end;
 end;
end;

procedure TGridPath.Paint(Canvas: TCanvas);
var Left,Top:Double;XCount,YCount:Integer;
    I,J,K,GLW:Integer;
    XBeg,YBeg:Double;
    Pen,Rop:THandle;
    GMS, Delta:Integer;
    X,Y:Double;
begin
 With Selector, TForm2(GTwgForm).Settings do begin
  XLine.FreeAll;YLine.FreeAll;
  XBeg:=CellWidth*Trunc(GRect.Left/CellWidth);
  YBeg:=CellHeight*Trunc(GRect.Bottom/CellHeight);
  XCount:=Round((GRect.Right-GRect.Left)/CellWidth)+1;
  YCount:=Round((GRect.Top-GRect.Bottom)/CellHeight)+1;
  If (XRasst(CellWidth)<10) or (YRasst(CellHeight)<10) then exit;
  For I:=0 to XCount do XLine.Insert(TDot.Create(XBeg+CellWidth*I,0,0));
  For I:=0 to YCount do YLine.Insert(TDot.Create(0,YBeg+CellHeight*I,0));
//  If gsGlass then Rop:=SetRop2(Canvas.Handle,R2_NotXorPen);
   If gsGridType = 0 then begin
  //  Pen:=SelectObject(Canvas.Handle,CreatePen(ps_Solid,gsGridLineWidth,wbColor(gsGridColor)));
    For I:=0 to XCount do begin
    // XLine.Insert(TDot.Create(XBeg+CellWidth*I,0,0));
     If gsShowGrid then begin PMoveTo(XBeg+CellWidth*I,GRect.Top);PLineTo(XBeg+CellWidth*I,GRect.Bottom);end;
    end;
    For I:=0 to YCount do begin
    // YLine.Insert(TDot.Create(0,YBeg+CellHeight*I,0));
     If gsShowGrid then begin PMoveTo(GRect.Left,YBeg+CellHeight*I);PLineTo(GRect.Right,YBeg+CellHeight*I);end;
    end;
   end else
   If gsGridType = 1 then begin
   // Pen:=SelectObject(Canvas.Handle,CreatePen(ps_Solid,0,wbColor(gsGridColor)));
   // GMS:=XRasst((10*gsGridSize*gsScale)/1000/2);
   // If GMS=0 then GMS:=1;
    GLW:=Trunc(gsGridLineWidth/2);
    If GLW>1 then GLW:=1;
    If gsShowGrid then
    For I:=0 to XCount do
     For J:=0 to YCount do begin
      X:=XBeg+CellWidth*I;Y:=YBeg+CellHeight*J;
 //      MoveTo(GCanvas.Handle,XPix(X)-1,YPix(Y));LineTo(GCanvas.Handle,XPix(X)+2,YPix(Y));
 //      MoveTo(GCanvas.Handle,XPix(X),YPix(Y)-1);LineTo(GCanvas.Handle,XPix(X),YPix(Y)+2);
       For K:=-GLW to GLW do begin
       // DrawLinePix(XPix(X)-GMS,YPix(Y)+K,XPix(X)+GMS+1,YPix(Y)+K);
       // DrawLinePix(XPix(X)+K,YPix(Y)-GMS,XPix(X)+K,YPix(Y)+GMS+1);
       end;
     end;
  //  DeleteObject(SelectObject(Canvas.Handle,Pen));
   end;
//  If gsGlass then SetRop2(Canvas.Handle,Rop);
 end;
end;


end.
