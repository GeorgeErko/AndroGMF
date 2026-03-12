unit Types_dimano;


interface uses Collect, Classes, FMX.Graphics;


 Const Erko=50;
 const hue_undefined = -333; // for procedures transitions RGB and HSV (HSB).
 const RealNull : double = -111111111111111;
 type TF = function( a, b, R1, X1c, R2, X2c : double ) : double;

 Type
  TDot1 = class( TTwgObject )
    X, Y : Double;
     Constructor Create( X1, Y1 : Double);
     Constructor CreateAs(Dot: TDot1);
   end;

  TDot2 = class( TTwgObject )
    X, Y : Double;
    x0, y0, z0 : double;
     Constructor Create( X1, Y1 : Double);
   end;

  TDot1Class=class of TDot1;

  TEdge = class( TTwgObject )
    X1, Y1, X2, Y2 : Double;
     Constructor Create( X11, Y11 ,X22, Y22 : Double);
   end;

  T3DPoint = class(TDot1)
   Z : Double;
    Constructor Create(X1,Y1,Z1:Double);
    Constructor   Load  (Stream :TBufStream);Override;
    Procedure     Store (Stream :TBufStream);Override;
   end;

  THorizont = class(TTwgObject)
   Z:Double;
   Points:PCollection;
    Constructor Create(Z1:Double);
    Destructor Destroy;Override;
     Function GetPoint(Index:Integer):T3DPoint;
     Property Point[Index:Integer]:T3DPoint read GetPoint;Default;
  end;

  TDouble=class(TTwgObject)
    Num:Double;
     Constructor Create(N:Double);
     Constructor   Load  (Stream :TBufStream);Override;
     Procedure     Store (Stream :TBufStream);Override;
   end;

  TInt=class(TTwgObject)
    Num:Integer;
     Constructor Create(N:Integer);
   end;

  TMatrica=class(TTwgObject)
    P:PCollection;
    Constructor Create(XC,YC:Integer);
    Destructor Destroy;Override;
    Function GetPoint(X,Y:Integer):Double;
    Procedure SetPoint(X,Y:Integer;Value:Double);
    Property Point[X,Y:Integer]:Double read GetPoint write SetPoint;Default;
   end;

  TIntCollect=class(PCollection)
    Function Get(Index: Integer): Pointer;Override;
    Procedure Put(Index: Integer; Item: Pointer);Override;
    Function GetI(Index:Integer):Integer;
    Procedure PutI(Index: Integer; Item: Integer);
     Property Point[Index:Integer]:Integer read GetI write PutI;Default;
   end;

  TRealCollect=class(TIntCollect)
    Function GetI(Index:Integer):Double;
    Procedure PutI(Index: Integer; Item: Double);
     Property Point[Index:Integer]:Double read GetI write PutI;Default;
   end;


implementation

Constructor TDot1.Create;
  begin
    X := X1;
    Y := Y1;
  end;

Constructor TDot2.Create;
  begin
    X := X1;
    Y := Y1;
    x0 := RealNull;
    y0 := RealNull;
    z0 := RealNull;
  end;

Constructor TEdge.Create;
  begin
    X1 := X11; Y1 := Y11;
    X2 := X22; Y2 := Y22;
  end;
Constructor TDouble.Create;
 begin
  Num:=N;
 end;

Constructor TInt.Create;
 begin
  Num:=N;
 end;

Constructor TMatrica.Create;
 var I,J:Integer;PC:PCollection;
 begin
  P:=PCollection.Create(Erko);
   For I:=1 to YC do
    begin
     PC:=PCollection.Create(Erko);
     P.Insert(PC);
      For J:=1 to XC do PC.Insert(TDouble.Create(0));
    end;
 end;

Destructor TMatrica.Destroy;
 begin
  P.Free;
 end;

Function TMatrica.GetPoint;
 var PC:PCollection;
 begin
  PC:=P[Y-1];
  Result:=TDouble(PC[X-1]).Num;
 end;

Procedure TMatrica.SetPoint;
 var PC:PCollection;
 begin
  PC:=P[Y-1];
  TDouble(PC[X-1]).Num:=Value;
 end;


{var M:TMatrica;
    D:Double;

 M:=TMatrica.Create(5,5);

 D:=456.67;

 M[X,Y]:=D;

 D:=M[X,Y];

 M.Free;
}

Function TIntCollect.Get;
Begin
 Result:=Inherited Get(Index-1);
End;

Procedure TIntCollect.Put;
Begin
 Inherited Put(Index-1,Item);
End;

Function TIntCollect.GetI;
Begin
// Result:=TInt(Items[Index]).Num;
{$IFDEF NEWCOL}
  Result:=TInt(FList[Index-1]).Num;
{$ELSE}
  Result:=TInt(FList.List[Index-1]).Num;
{$ENDIF}
End;

Procedure TINtCOllect.PUtI;
 begin
//  TINt(GET(INdex)).NUM:=Item;
{$IFDEF NEWCOL}
   TInt(FList[Index-1]).NUm:=Item;
{$ELSE}
   TInt(FList.List[Index-1]).NUm:=Item;
{$ENDIF}

 end;

Procedure TREalCOllect.PUtI;
 begin
//  TDOUble(GET(INdex)).NUm:=Item;
{$IFDEF NEWCOL}
   TDouble(FList[Index-1]).NUm:=Item;
{$ELSE}
   TDouble(FList.List[Index-1]).NUm:=Item;
{$ENDIF}

 end;

Function TRealCollect.GetI;
Begin
// Result:=TDouble(Items[Index]).Num;
{$IFDEF NEWCOL}
   Result:=TDouble(FList[Index-1]).Num;
{$ELSE}
  Result:=TDouble(FList.List[Index-1]).Num;
{$ENDIF}
End;

Constructor T3DPoint.Create;
 begin
  X:=X1;Y:=Y1;Z:=Z1;
 end;

Constructor THorizont.Create;
 begin
  Z:=Z1;
  Points:=PCollection.Create(Erko);
 end;

Function THorizont.GetPoint;
 begin
  Result:=Points[Index];
 end;

Destructor THorizont.Destroy;
 begin
  Points.Free;
 end;

{
 var Uch:TUch;
  begin
   Uch:=TUch.Create('GOGA');
    // insert
     Uch.InsertXY('12',X,Y);
     Uch.InsertRed('12',X,Y,.....);
    For I:=0 to Uch.Count-1 do
      If Uch[I].R=0 then
       Writeln(Uch2.InsertXY(UCH[I].Name,Uch[I].X,Uch[Y]));
   Uch.Free;
  end;

           rl.Coord.AtInsert(k+1,TRed.CreateRed('',
             TDot( aux_col[l] ).x, TDot( aux_col[l] ).y, rl[k].xcl,
             rl[k].ycl, rl[k].r, rl[k].xrl, rl[k].yrl ));
//}


constructor TDouble.Load(Stream: TBufStream);
begin
 Stream.Read(Num,SizeOf(Num));
end;

procedure TDouble.Store(Stream: TBufStream);
begin
 Stream.Write(Num,SizeOf(Num));
end;

constructor T3DPoint.Load(Stream: TBufStream);
begin
 Stream.Read(X,SizeOf(X));
 Stream.Read(Y,SizeOf(Y));
 Stream.Read(Z,SizeOf(Z));
end;

procedure T3DPoint.Store(Stream: TBufStream);
begin
 Stream.Write(X,SizeOf(X));
 Stream.Write(Y,SizeOf(Y));
 Stream.Write(Z,SizeOf(Z));
end;

constructor TDot1.CreateAs(Dot: TDot1);
begin
 X := Dot.X;
 Y := Dot.Y;
end;

initialization
end.
