unit HatchLot;

interface uses {$IFDEF WIN64}Windows,{$ENDIF} Collect, EcLot, newForm0, WpTwigs, TwgDraw,  newResource,
                    newSelector;

var FirstRgn:TRegion;

type
 TPolyTwig = class(TTwgObject)
  private
    function GetTwig(Index: Integer): TTwig;
    function GetCount: Integer;
  public
  Selector:TSelector;
  Inv:Byte;
  Color:Integer;
  Twigs:PCollection;
  Square:Double;
  Constructor Create(Square_:Double);
  Constructor CreateAs(PolyTwig:TPolyTwig);
   Constructor   Load  (Stream :TBufStream);override;
   Procedure     Store (Stream :TBufStream);override;
  Destructor Destroy;override;
 //
   Procedure AddTwig(Twig:TTwig);
   Procedure Calculate;
   Procedure Draw;
   Function PointIn(X,Y:Double):boolean;
   Function GetPoints(Col:PCollection;var XMin,YMin,XMax,YMax:Double):Integer;
 //
   Property Twig[Index:Integer]:TTwig read GetTwig;
   Property Count:Integer read GetCount;
   Function GetNearestTwigs(X,Y:Double;var XR,YR,Dist:Double):PCollection;
 end;

type
 THatchLot = class(TLot)
  protected
   function GetZero(Index: Integer): TPolyTwig;
  public
   Zeros:PCollection;// коллекция коллекций сегментов
   noClipping:Boolean;
  // создание/пересоздание
   Constructor   Create  (CH:TResource);
   Procedure     AssignLot(Lot:TLot;AddAllCollections:Boolean);override;
  // основные перекрытые ф-ции
   Function   PointIn   (Twf:TTwigsCollect;X,Y:Double;Param:Integer=-1):Boolean;override;
  //
   Procedure     SetMinMax(Twf:TTwigsCollect);override;
   Function      SetSqwear(TWF:TTwigsCollect):SmallInt;override;
   Function      SetClearSqwear(Index:Integer;TWF:TTwigsCollect;Os:AnsiString;PointsIns:boolean):Integer;override;
  // дырки
   Procedure AddZero(Zero:TPolyTwig);
   Property Zero[Index:Integer]:TPolyTwig read GetZero;
   Constructor   Load  (Stream :TBufStream);override;
   Procedure     Store (Stream :TBufStream);override;
   Procedure Move(Dx,Dy:Double);override;
   Procedure RotationPoints(Col:PCollection);override;
  //
   Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
 end;


implementation uses EcDot, Polygons, Maths_Basic, newSettings,
                    Lib, newProcs, Writer;

{ TPolyTwig }

constructor TPolyTwig.Create;
begin
 Twigs:=PCollection.Create(1);
 Square:=Square_;
end;

constructor TPolyTwig.CreateAs(PolyTwig: TPolyTwig);
var I:Integer;
begin
 Create(PolyTwig.Square);
 For I:=0 to PolyTwig.Twigs.Count-1 do AddTwig(TTwigClass(PolyTwig.Twig[I].ClassType).CreateAsTwig(PolyTwig.Twig[I],True));
 Calculate;
end;

destructor TPolyTwig.Destroy;
begin
 Twigs.Free;
end;

constructor TPolyTwig.Load(Stream: TBufStream);
begin
 Selector:=Stream.Selector;
 Stream.Read(Square,SizeOf(Square));
 Twigs:=PCollection(Stream.Get);
end;

procedure TPolyTwig.Store(Stream: TBufStream);
begin
 Stream.Write(Square,SizeOf(Square));
 Stream.Put(Twigs);
end;

procedure TPolyTwig.AddTwig(Twig: TTwig);
begin
 Twigs.Insert(Twig);
 Twig.Calculate;
end;

procedure TPolyTwig.Calculate;
var I:Integer;
begin
 For I:=0 to Twigs.Count-1 do Twig[I].Calculate;
 // поворачиваем ветки по порядку
end;

function TPolyTwig.PointIn(X, Y:Double): boolean;
var Points:PCollection;X1,Y1,X2,Y2:Double;
begin
 Points:=PCollection.Create(1);
  If GetPoints(Points,X1,Y1,X2,Y2)>2 then Result:=Point_Inside_Polygon(X,Y,Points)>-1;
 Points.DeleteAll;Points.Free;
end;

procedure TPolyTwig.Draw;
var I,Clo:Integer;
begin
 For I:=0 to Twigs.Count-1 do begin
  Twig[I].STColor:=wbColor(Selector,Color);Twig[I].Rang:=1;Clo:=Twig[I].Closed;Twig[I].Closed:=1;//Twig[I].SetMinMax;
  Twig[I].Inv:=Inv;
  Twig[I].UZnak:=-1;
  Twig[I].Draw;
  Twig[I].Inv:=0;
  Twig[I].Closed:=Clo;
 end;
end;

function TPolyTwig.GetTwig(Index: Integer): TTwig;
begin
 Result:=Twigs[Index];
end;

function TPolyTwig.GetCount: Integer;
begin
 Result:=Twigs.Count;
end;

function TPolyTwig.GetPoints(Col: PCollection; var XMin,YMin,XMax,YMax:Double): Integer;
var I,J:Integer;AV:Integer;
begin
 Result:=0;
 XMax:=-1000000000;YMax:=-1000000000;XMin:=1000000000;YMin:=1000000000;
 For I:=0 to Twigs.Count-1 do begin
  AV:=Twig[I].ArcView;
  Twig[I].ArcView:=1;
  If Col.Count=0 then For J:=0 to Twig[I].Coord.Count-1 do Col.Insert(Twig[I].Coord[J]) else
  If Selector.EqualPoints(Col[Col.Count-1],Twig[I].Coord[0]) then
   For J:=1 to Twig[I].Coord.Count-1 do Col.Insert(Twig[I].Coord[J]) else
   For J:=Twig[I].Coord.Count-2 downTo 0 do Col.Insert(Twig[I].Coord[J]);
  Twig[I].ArcView:=AV;
 end;
 Result:=Col.Count;
 For I:=0 to Col.Count-1 do With TDot(Col[I]) do begin
  If XDot>XMax then XMax:=XDot;
  If XDot<XMin then XMin:=XDot;
  If YDot>YMax then YMax:=YDot;
  If YDot<YMin then YMin:=YDot;
 end;
end;

function TPolyTwig.GetNearestTwigs(X, Y: Double; var XR, YR, Dist:Double): PCollection;
var I, Index:Integer;MinDist:Double;
begin
 MinDist:=10000000;Result:=PCollection.Create(1);
 For I:=0 to Twigs.Count-1 do begin
  If Twig[I].GetTwigDist(X,Y,XR,YR)<=MinDist then begin
   Result.Insert(Twig[I]);MinDist:=Twig[I].GetTwigDist(X,Y,XR,YR);Dist:=MinDist;
  end;
 end;
end;

{ THatchLot }

constructor THatchLot.Create(CH: TResource);
begin
 inherited Create(CH.ID,CH,2);
 Zeros:=PCollection.Create(1);
 TypeLot:=2;
end;

procedure THatchLot.AssignLot(Lot: TLot; AddAllCollections: Boolean);
var I,J:Integer;asLot:THatchLot;
    PolyTwig:TPolyTwig;
begin
 inherited;
 Zeros:=PCollection.Create(1);
 asLot:=THatchLot(Lot);
 For I:=0 to asLot.Zeros.Count - 1 do AddZero(TPolyTwig.CreateAs(asLot.Zero[I]));
end;

constructor THatchLot.Load(Stream: TBufStream);
begin
 inherited;
 WriteS(['HatchLot.begin']);
 Zeros:=PCollection(Stream.Get);
 WriteS(['HatchLot.end']);
end;

procedure THatchLot.Store(Stream: TBufStream);
begin
 inherited;
 Stream.Put(Zeros);
end;

//=============================================================================

function THatchLot.PointIn(Twf: TTwigsCollect; X, Y: Double;Param:Integer=-1): Boolean;
var I:Integer;
begin
 Result:=inherited PointIn(Twf,X,Y);
 If not Result then Exit;
 For I:=0 to Zeros.Count-1 do
  If Zero[I].PointIn(X,Y) then begin
   Result:=False;exit;
  end;
end;


//=============================================================================

procedure THatchLot.SetMinMax(Twf: TTwigsCollect);
var I:Integer;
begin
 inherited;
 For I:=0 to Zeros.Count-1 do Zero[I].Calculate;
end;

function THatchLot.SetSqwear(TWF: TTwigsCollect): SmallInt;
var I:Integer;Square:Double;
begin
 Result:=Inherited SetSqwear(TWF);
 ClearPlo:=Plo;
 For I:=0 to Zeros.Count-1 do begin
  ClearPlo:=ClearPlo - Zero[I].Square;
 end;
end;

function THatchLot.SetClearSqwear(Index: Integer; TWF: TTwigsCollect;Os:AnsiString;PointsIns:boolean): Integer;
begin
 Result:=SetSqwear(TWF);
end;

//=============================================================================

procedure THatchLot.AddZero(Zero:TPolyTwig);
begin
 Zeros.Insert(Zero);
 Zero.Calculate;
end;

function THatchLot.GetZero(Index: Integer): TPolyTwig;
begin
 Result:=Zeros[Index];
end;

procedure THatchLot.Move(Dx, Dy: Double);
var I,J:Integer;
    PD:TPDot;
begin
 inherited Move(Dx,Dy);
 For I:=0 to Zeros.Count-1 do
  For J:=0 to Zero[I].Count-1 do Zero[I].Twig[J].Move(Dx,Dy);
end;

procedure THatchLot.RotationPoints(Col: PCollection);
var I,J,K:Integer;
begin
 inherited RotationPoints(Col);
 For I:=0 to Zeros.Count-1 do
  For J:=0 to Zero[I].Count-1 do With Zero[I].Twig[J] do
   For K:=0 to Coord.Count-1 do Col.Insert(Coord[K]);
end;

function THatchLot.SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;
begin
 If (propName = 'Тип заливки') or (propName = 'Масштаб') then begin
  Result:=inherited SetProperty(propName,propValue);
  UZnaks.FreeAll;
  Result:=True;
 end else Result := inherited SetProperty(propName,propValue);
end;

initialization
end.
