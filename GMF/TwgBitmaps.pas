unit TwgBitmaps;

interface uses Collect, FMX.Graphics, newSelector, TwgDraw, ogcBasic,
               System.Math, System.UITypes;

type
 TTwgBitmap = class(TTwgObject)
 private
  fSect: TSect;
  fBounds: PCollection;
  function GetWidth: Integer;
  function GetHeight: Integer;
 public
  Bitmap: TBitmap;
  rootObj: TTD;
  Constructor Create(rootObj_: TTD = nil);
  Constructor Load(Stream: TBufStream);override;
  Procedure Store(Stream: TBufStream);override;
  Constructor BINLoad(Stream: TBufStream);override;
  Procedure BINStore(Stream: TBufStream);override;
  Procedure SetBounds(X0, Y0, X1, Y1, X2, Y2, X3, Y3: Double);
  Procedure SetTransformedBounds(const SourceSect: TSect; X0, Y0, XB, YB, kX, kY, Angle: Double);
  Procedure DrawSect(Drawer: TogsDrawer; Color: TColor; Width: Single);
  Procedure DrawBounds(Drawer: TogsDrawer; Color: TColor; Width: Single);
  Destructor Destroy;override;
  Property Width: Integer read GetWidth;
  Property Height: Integer read GetHeight;
  Property Sect: TSect read fSect write fSect;
  Property Bounds: PCollection read fBounds;
 end;

 TTwgBitmaps = class(PCollection)
  private
   fSect: TSect;
   function GetBitmap(Index: Integer): TTwgBitmap;
  public
   Bitmap: TTwgBitmap;
   Constructor Create(ALimit: Integer; ADelta: Integer = 1);
   Destructor Destroy;override;
   Function InsertItem(Item: Pointer): Pointer;override;
   Procedure FreeItem(Item: Pointer);override;
   Procedure CalcSect;
   Procedure DrawSect(Drawer: TogsDrawer; Color, BitmapColor: TColor; Width: Single);
   Procedure DrawBounds(Drawer: TogsDrawer; Color, BitmapColor: TColor; Width: Single);
   Property Sect: TSect read fSect;
   Property Bitmaps[Index: Integer]: TTwgBitmap read GetBitmap;default;
 end;

implementation

{ TTwgBitmap }

function TTwgBitmap.GetWidth: Integer;
begin
 if Bitmap <> nil then Result := Bitmap.Width else Result := 0;
end;

function TTwgBitmap.GetHeight: Integer;
begin
 if Bitmap <> nil then Result := Bitmap.Height else Result := 0;
end;

constructor TTwgBitmap.Create(rootObj_: TTD);
begin
 inherited Create;
 Bitmap := TBitmap.Create;
 fBounds := nil;
 rootObj := rootObj_;
end;

constructor TTwgBitmap.Load(Stream: TBufStream);
begin
 inherited Create;
 Bitmap := TBitmap.Create;
 fBounds := nil;
 rootObj := nil;
end;

procedure TTwgBitmap.Store(Stream: TBufStream);
begin
end;

constructor TTwgBitmap.BINLoad(Stream: TBufStream);
begin
 Load(Stream);
end;

procedure TTwgBitmap.BINStore(Stream: TBufStream);
begin
 Store(Stream);
end;

procedure TTwgBitmap.SetBounds(X0, Y0, X1, Y1, X2, Y2, X3, Y3: Double);
var MRect: TMRect;
 procedure AddPoint(X_, Y_: Double);
 begin
  fBounds.Insert(TogsDot.Create(X_, Y_));
  MRect.Insert(X_, Y_);
 end;
begin
 if fBounds=nil then fBounds:=PCollection.Create(4) else fBounds.FreeAll;
 MRect:=TMRect.Create;
 try
  AddPoint(X0, Y0);
  AddPoint(X1, Y1);
  AddPoint(X2, Y2);
  AddPoint(X3, Y3);
  fSect:=MRect.Sect;
 finally
  MRect.Free;
 end;
end;

procedure TTwgBitmap.SetTransformedBounds(const SourceSect: TSect; X0, Y0, XB, YB, kX, kY, Angle: Double);
var MRect: TMRect; C, S: Double;
 procedure AddPoint(X_, Y_: Double);
 var xx, yy: Double;
 begin
  xx := XB + ((X_ - X0) * kX * C - ((Y_ - Y0) * kY * S));
  yy := YB + ((X_ - X0) * kX * S + ((Y_ - Y0) * kY * C));
  fBounds.Insert(TogsDot.Create(xx, yy));
  MRect.Insert(xx, yy);
 end;
begin
 if fBounds=nil then fBounds:=PCollection.Create(4) else fBounds.FreeAll;
 MRect:=TMRect.Create;
 try
  C:=Cos(Angle);S:=Sin(Angle);
  AddPoint(SourceSect.Left, SourceSect.Top);
  AddPoint(SourceSect.Right, SourceSect.Top);
  AddPoint(SourceSect.Right, SourceSect.Bottom);
  AddPoint(SourceSect.Left, SourceSect.Bottom);
  fSect:=MRect.Sect;
 finally
  MRect.Free;
 end;
end;

procedure TTwgBitmap.DrawSect(Drawer: TogsDrawer; Color: TColor; Width: Single);
var OldPen: TogsPen;
begin
 if Drawer=nil then Exit;
 if (fSect.Left=fSect.Right) and (fSect.Top=fSect.Bottom) then Exit;
 OldPen:=Drawer.SelectPen(TogsPen.Create(Color, Width, nil));
 try
  Drawer.DrawLine(fSect.Left, fSect.Top, fSect.Right, fSect.Top, False);
  Drawer.DrawLine(fSect.Right, fSect.Top, fSect.Right, fSect.Bottom, False);
  Drawer.DrawLine(fSect.Right, fSect.Bottom, fSect.Left, fSect.Bottom, False);
  Drawer.DrawLine(fSect.Left, fSect.Bottom, fSect.Left, fSect.Top, False);
 finally
  Drawer.DeletePen(Drawer.SelectPen(OldPen));
 end;
end;

procedure TTwgBitmap.DrawBounds(Drawer: TogsDrawer; Color: TColor; Width: Single);
var OldPen: TogsPen; P0, P1, P2, P3: TogsDot;
begin
 if Drawer=nil then Exit;
 if (fBounds=nil) or (fBounds.Count<4) then Exit;
 P0:=TogsDot(fBounds[0]);
 P1:=TogsDot(fBounds[1]);
 P2:=TogsDot(fBounds[2]);
 P3:=TogsDot(fBounds[3]);
 OldPen:=Drawer.SelectPen(TogsPen.Create(Color, Width, nil));
 try
  Drawer.DrawLine(P0.X, P0.Y, P1.X, P1.Y, False);
  Drawer.DrawLine(P1.X, P1.Y, P2.X, P2.Y, False);
  Drawer.DrawLine(P2.X, P2.Y, P3.X, P3.Y, False);
  Drawer.DrawLine(P3.X, P3.Y, P0.X, P0.Y, False);
 finally
  Drawer.DeletePen(Drawer.SelectPen(OldPen));
 end;
end;

destructor TTwgBitmap.Destroy;
begin
 if Bitmap <> nil then Bitmap.Free;
 if fBounds <> nil then  fBounds.Free;
 inherited;
end;

{ TTwgBitmaps }

constructor TTwgBitmaps.Create(ALimit: Integer; ADelta: Integer);
begin
 inherited Create(ALimit);
 Bitmap := TTwgBitmap.Create;
 fSect.Left:=0;fSect.Right:=0;fSect.Top:=0;fSect.Bottom:=0;
end;

destructor TTwgBitmaps.Destroy;
begin
 if Bitmap <> nil then Bitmap.Free;
 inherited;
end;

function TTwgBitmaps.GetBitmap(Index: Integer): TTwgBitmap;
begin
 Result := TTwgBitmap(At(Index));
end;

function TTwgBitmaps.InsertItem(Item: Pointer): Pointer;
begin
 Result := inherited InsertItem(Item);
end;

procedure TTwgBitmaps.FreeItem(Item: Pointer);
begin
 if Item=Self then Exit;
 if TObject(Item) <> nil then TObject(Item).Free;
end;

procedure TTwgBitmaps.CalcSect;
var I: Integer; TwgBitmap: TTwgBitmap; MRect: TMRect;
 procedure InsertSect(const Sect_: TSect);
 begin
  if (Sect_.Left=Sect_.Right) and (Sect_.Top=Sect_.Bottom) then Exit;
  MRect.Insert(Sect_.Left, Sect_.Top);
  MRect.Insert(Sect_.Right, Sect_.Bottom);
 end;
begin
 MRect:=TMRect.Create;
 try
  if Bitmap<>nil then InsertSect(Bitmap.Sect);
  for I:=0 to Count-1 do begin
   if Items[I]=Pointer(Self) then Continue;
   TwgBitmap:=TTwgBitmap(Items[I]);
   if TwgBitmap<>nil then InsertSect(TwgBitmap.Sect);
  end;
  if MRect.Iter<>0 then fSect:=MRect.Sect else begin
   fSect.Left:=0;fSect.Right:=0;fSect.Top:=0;fSect.Bottom:=0;
  end;
 finally
  MRect.Free;
 end;
end;

procedure TTwgBitmaps.DrawSect(Drawer: TogsDrawer; Color, BitmapColor: TColor; Width: Single);
var I: Integer; TwgBitmap: TTwgBitmap; OldPen: TogsPen;
 procedure DrawSect_(const Sect_: TSect);
 begin
  if (Sect_.Left=Sect_.Right) and (Sect_.Top=Sect_.Bottom) then Exit;
  OldPen:=Drawer.SelectPen(TogsPen.Create(BitmapColor, Width, nil));
  try
   Drawer.DrawLine(Sect_.Left, Sect_.Top, Sect_.Right, Sect_.Top, False);
   Drawer.DrawLine(Sect_.Right, Sect_.Top, Sect_.Right, Sect_.Bottom, False);
   Drawer.DrawLine(Sect_.Right, Sect_.Bottom, Sect_.Left, Sect_.Bottom, False);
   Drawer.DrawLine(Sect_.Left, Sect_.Bottom, Sect_.Left, Sect_.Top, False);
  finally
   Drawer.DeletePen(Drawer.SelectPen(OldPen));
  end;
 end;
begin
 if Drawer=nil then Exit;
 for I:=0 to Count-1 do begin
  if Items[I]=Pointer(Self) then Continue;
  TwgBitmap:=TTwgBitmap(Items[I]);
  if TwgBitmap<>nil then TwgBitmap.DrawSect(Drawer, Color, Width);
 end;
 if Bitmap<>nil then Bitmap.DrawSect(Drawer, BitmapColor, Width);
 DrawSect_(fSect);
end;

procedure TTwgBitmaps.DrawBounds(Drawer: TogsDrawer; Color, BitmapColor: TColor; Width: Single);
var I: Integer; TwgBitmap: TTwgBitmap; OldPen: TogsPen;
 procedure DrawSect_(const Sect_: TSect);
 begin
  if (Sect_.Left=Sect_.Right) and (Sect_.Top=Sect_.Bottom) then Exit;
  OldPen:=Drawer.SelectPen(TogsPen.Create(BitmapColor, Width, nil));
  try
   Drawer.DrawLine(Sect_.Left, Sect_.Top, Sect_.Right, Sect_.Top, False);
   Drawer.DrawLine(Sect_.Right, Sect_.Top, Sect_.Right, Sect_.Bottom, False);
   Drawer.DrawLine(Sect_.Right, Sect_.Bottom, Sect_.Left, Sect_.Bottom, False);
   Drawer.DrawLine(Sect_.Left, Sect_.Bottom, Sect_.Left, Sect_.Top, False);
  finally
   Drawer.DeletePen(Drawer.SelectPen(OldPen));
  end;
 end;
begin
 if Drawer=nil then Exit;
 for I:=0 to Count-1 do begin
  if Items[I]=Pointer(Self) then Continue;
  TwgBitmap:=TTwgBitmap(Items[I]);
  if TwgBitmap<>nil then TwgBitmap.DrawBounds(Drawer, Color, Width);
 end;
 if Bitmap<>nil then Bitmap.DrawBounds(Drawer, BitmapColor, Width);
 DrawSect_(fSect);
end;

end.
