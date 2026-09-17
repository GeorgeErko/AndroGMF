unit WPTForm2;

interface

uses Collect, EcDot, WPTForm12, WPTwigs, Classes, SysUtils, newProcs, System.Types,
     System.Skia, System.UITypes, ogcBasic, ogcCaptureIntf, ogcDrawerSkia,
     TwgDraw, ogcMarker;

type
 TCapturePt = class
 private
  FBaseDot: TDot;
  FMoveDot: TDot;
  FDashColor: TAlphaColor;
  FCaptureRec: TCaptureRec;
 public
  constructor Create(const ABaseDot, AMoveDot: TDot; const ADashColor: TAlphaColor; ACaptureRec: TCaptureRec);
  procedure Draw(const Canvas: ISkCanvas; const ViewScale: Single);
  property BaseDot: TDot read FBaseDot write FBaseDot;
  property MoveDot: TDot read FMoveDot write FMoveDot;
 end;

 TCapturePoints = class
 private
  FItems: PCollection;
 public
  constructor Create;
  destructor Destroy; override;
  function Add(const ABaseDot, AMoveDot: TDot; const ADashColor: TAlphaColor; ACaptureRec: TCaptureRec): TCapturePt;
  procedure Clear;
  procedure Draw(const Canvas: ISkCanvas; const ViewScale: Single);
  property Items: PCollection read FItems;
 end;

 TForm2 = class(TFormTaheo, IInterface, IogsPrimitiveCapturer, IogsSelectionAccess)
 private
  function FillPtList(Obj: TTD; var R: TRectF): TPolyPolyline;
 protected
  APoint: TPointDot;
  ParentMap:Pointer;
  FObjects: TTwgObject;
  LastCaptureRec: TCaptureRec;
 //
  function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  function _AddRef: Integer; stdcall;
  function _Release: Integer; stdcall;
 public
 // old TForm2
  Function  CreateAs(F:TForm2):TForm2;
  Function  CreateObjectView(QueryOnCreate:Boolean):Boolean;override;
  Function  CreateView:Pointer;override;
  Procedure SaveObjView(View:Pointer);override;
  Procedure ClearObject;
 // new
  function GetHitTestMarker(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
  function HitTestPointWorld(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer = 1): Integer;
  function SelectRectWorld(const Rect: TSect; Mode: TogsRectSelectMode; const Filter: TogsCaptureFilter): Integer;
  function GetPrimitiveBoundsWorld(const PrimitiveId: TogsPrimitiveId; out Bounds: TSect): Boolean;
  function getLastCaptureRec: TCaptureRec;
  procedure PainSelection(const Canvas: ISkCanvas);
  function ClearSelection: boolean;
 //
  function selectedCount: Integer;
  function selectedPtr(Index: Integer): Pointer;
  function indexValid(Index: Integer): Boolean;
  function get(Index: Integer): Pointer;
 end;

implementation

uses SelectedObjects, ecLot, ecDot2, Writer, FramePropEditor;

{ TCapturePt }

constructor TCapturePt.Create(const ABaseDot, AMoveDot: TDot; const ADashColor: TAlphaColor; ACaptureRec: TCaptureRec);
begin
 inherited Create;
 FBaseDot := ABaseDot;
 FMoveDot := AMoveDot;
 FDashColor := ADashColor;
 FCaptureRec := ACaptureRec;
end;

procedure TCapturePt.Draw(const Canvas: ISkCanvas; const ViewScale: Single);
var Paint: ISkPaint;
    InvScale, DashLen: Single;
    P0, P1: TPointF;
begin
 if (Canvas = nil) or (FBaseDot = nil) or (FMoveDot = nil) then
  exit;
 if ViewScale <= 0 then
  InvScale := 1
 else
  InvScale := 1 / ViewScale;
 DashLen := 4 * InvScale;
 P0 := TPointF.Create(Single(FBaseDot.XDot), Single(FBaseDot.YDot));
 P1 := TPointF.Create(Single(FMoveDot.XDot), Single(FMoveDot.YDot));
 Paint := TSkPaint.Create;
 Paint.AntiAlias := True;
 Paint.Style := TSkPaintStyle.Stroke;
 Paint.StrokeWidth := 1 * InvScale;
 Paint.Color := FDashColor;
 Paint.PathEffect := TSkPathEffect.MakeDash(TArray<Single>.Create(DashLen, DashLen), 0);
 Canvas.DrawLine(P0, P1, Paint);
end;

{ TCapturePoints }

constructor TCapturePoints.Create;
begin
 inherited Create;
 FItems := PCollection.Create(8);
end;

destructor TCapturePoints.Destroy;
begin
 if FItems <> nil then begin
  FItems.FreeAll;
  FItems.Free;
 end;
 inherited;
end;

function TCapturePoints.Add(const ABaseDot, AMoveDot: TDot; const ADashColor: TAlphaColor; ACaptureRec: TCaptureRec): TCapturePt;
begin
 Result := TCapturePt.Create(ABaseDot, AMoveDot, ADashColor, ACaptureRec);
 if FItems <> nil then
  FItems.Insert(Result);
end;

procedure TCapturePoints.Clear;
begin
 if FItems <> nil then
  FItems.FreeAll;
end;

procedure TCapturePoints.Draw(const Canvas: ISkCanvas; const ViewScale: Single);
var I: Integer;
begin
 if (Canvas = nil) or (FItems = nil) then
  exit;
 for I := 0 to FItems.Count - 1 do
  if FItems[I] <> nil then
   TCapturePt(FItems[I]).Draw(Canvas, ViewScale);
end;

{ TForm2 }

Function TForm2.CreateObjectView;
 var I:Integer;
 begin
  try
   ObjView:=TForm2.Create(0);
   ObjView.Twigs.Insert(TWG_Twig,TTwig.CreateAsTwig(Twigs.TAt(0),True));
   ObjView.About.XMin:=-100000000;
   ObjView.About:=About;
   ObjView.ClName:=ClName;
   ObjView.hWndParent:=hWndParent;
   ObjView.V25:=V25;
   ObjView.Taheo:=Taheo;
   ObjView.MkLib:=MkLib;
   ObjView.LayerTable:=LayerTable;
   ObjView.MirrorObject:=True;
   // тахеометрия
   For I:=0 to Twigs.TaheoIndexes.Count-1 do ObjView.Twigs.TaheoIndexes.Add(Twigs.TaheoIndexes[I]);
   Result:=True;
  except Result:=False;raise;end;
 end;

Function TForm2.CreateView;
 begin
   Result:=TForm2.Create(0);
   TForm2(Result).Twigs.Insert(TWG_Twig,TTwig.CreateAsTwig(Twigs.TAt(0),True));
   TForm2(Result).About:=About;
 end;

 Procedure TForm2.saveObjView;
  var Buf:TBufStream;S:String;I:Integer;V:TForm2;
  begin
   V:=View;
   S:=(TForm2(View).About.Path)+'\'+(TForm2(View).About.MyName);
   try
    Buf:=TBufStream.InitFileStream(S, fmCreate);
    try
//     Writeln('Info==================');
//     Writeln(V.Twigs.TwigsCount);
     For I:=1 to V.Twigs.TwigsCount-1 do begin
//      writeln('Cnt=', TTwig(V.Twigs.TAt(I)).Coord.Count,' ',TTwig(V.Twigs.TAT(I)).ClassName);
     end;
     Buf.Put(TForm2(View));
//     Writeln('End==================');
    finally
     Buf.Free;
    end;
   except on E:Exception do
    MessageError('Невозможно создать файл '+S+'->'+E.Message)
   end;
  end;

function TForm2.selectedCount: Integer;
begin
 if FObjects = nil then Result := 0 else Result := TSelectedObjects(FObjects).Count;
end;

function TForm2.selectedPtr(Index: Integer): Pointer;
begin
 if (FObjects = nil) then Result := nil else
 if (Index < 0) or (Index > TSelectedObjects(FObjects).Count) then Result := nil
  else
   Result := TSelectedObjects(FObjects)[Index];
end;

function TForm2.indexValid(Index: Integer): Boolean;
begin
 Result := (Index >= 0) and (Index < selectedCount);
end;

function TForm2.get(Index: Integer): Pointer;
begin
 Result := selectedPtr(Index);
end;

function TForm2.getLastCaptureRec: TCaptureRec;
begin
 Result := LastCaptureRec;
end;

function TForm2.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
 if GetInterface(IID, Obj) then
  Result := S_OK
 else
  Result := E_NOINTERFACE;
end;

function TForm2._AddRef: Integer;
begin
 Result := -1;
end;

function TForm2._Release: Integer;
begin
 Result := -1;
end;

Function TForm2.CreateAs(F: TForm2):TForm2;
begin
 If CreateObjectView(False) then begin
  Result:=TForm2(ObjView);
  ObjView:=nil;
 end else Result:= nil;
end;

procedure TForm2.ClearObject;
var I:Integer;
begin
 For I:=Twigs.TwigsCount-1 downTo 1 do begin
  Twigs.AtDelete(TWG_Twig,I);
 end;
 For I:=Twigs.LotsCount-1 downTo 0 do begin
  Twigs.AtDelete(TWG_Lot,I);
 end;
 For I:=Twigs.AnyCount-1 downTo 0 do begin
  Twigs.DelAAt(I);
 end;
 Twigs.Bitmaps.Bitmaps.FreeAll;
end;

//==============================================================================
//
//==============================================================================

function TForm2.FillPtList(Obj: TTD; var R: TRectF): TPolyPolyline;
var I, J: Integer;
    PP: TPolyPolyLine;
    Lot: TLot; Twig: TTwig;
    List: Tlist;
begin
 Result := TPolyPolyline.Create;
 if Obj is TLot then begin
 // передаем точки сегментов контура
  R.Left := TLot(Obj).XMin; R.Top := TLot(Obj).YMin; R.Right := TLot(Obj).XMax; R.Bottom := TLot(Obj).YMax;
  Lot := TLot(Obj);
  for I := 0 to Lot.Coord.Count - 1 do begin
   List := Result.AddPolyline;
   Twig := Lot.GetTwig(Twigs, I);
   For J := 0 to Twig.Coord.Count - 1 do  List.Add(Twig.Coord[J]);
  end;
 end else begin
  R.Left := TDot(Obj).XDot; R.Top := TDot(Obj).YDot; R.Right := TDot(Obj).XDot; R.Bottom := TDot(Obj).YDot;
 // полилиния будет состоять из одной точки
  List := Result.AddPolyline;
  List.Add(TDot(Obj));
 end;
end;

function TForm2.GetHitTestMarker(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
var XClick, YClick: Double;
    I: Integer; B:Byte;
    CaptureDrawer: TogsCaptureDrawerSkia;
    Params: TCaptureRec;
    Lot: TLot;
    Sect: TogsRect;
    PD: TPointDot;
    DT: TDotText;
    Sel: TSelectedObjects;
    ptList: TPolyPolyline;
    R: TRectF;
begin
 Result := 0;
 LastCaptureRec := CRClearParams([]);
 XClick := X;
 YClick := Y;
 CaptureDrawer := nil;
 try
  CaptureDrawer := TogsCaptureDrawerSkia.CreateCapture(Selector);
  Params := CRClearParams([ckPoint, ckLine, ckPolygon, ckMidLine]);
  if Selector <> nil then
   Params.CaptureParam := Selector.GlobalSettings.Settings.gsPointSize * 2;
  CaptureDrawer.BeginCapture(XClick, YClick, Params);
  CaptureDrawer.UseWorldCoords := True;
 // поиск по SelectedObjects
  Sel := TSelectedObjects(FObjects);
  if Sel <> nil  then begin
   for I := 0 to Sel.Count - 1  do begin
    ptList := FillPtList(Sel[I], R);
    if ptList = nil then continue;
    ogsGetPoint(ptList, Selector, X, Y, Params);
    if Params.resObject <> nil then begin
     Params.resObject := Sel[I];
     LastCaptureRec := Params;
     Result := 1;
     ptList.Free;
     exit;
    end else
     ptList.Free; //
   end;
  end;
 // проход по TPointDot
  for I := Twigs.AnyCount - 1 downto 0 do begin
   PD := Twigs.AAt(I, B);
   if (PD.Closed) {or (PD.isCaptured)}  then continue;
   if not PD.PoinInTwgBitmaps(X, Y) then continue;
  //
   CaptureDrawer.BeginPrimitive(Int64(NativeInt(PD)), PD);
   try
    PD.DrawTwgBitmapBounds(CaptureDrawer);
   finally
    CaptureDrawer.EndPrimitive;
   end;
  // PD.PointInCapture(X, Y, Params);
   if Params.resObject <> nil then begin
    LastCaptureRec := Params;
    Result := 1;
    break;
   end;  //
  end;
  if Result > 0 then exit;
 //
  for I := Twigs.IndexCount - 1 downto 0 do begin
   Lot := Twigs.LAtIndex(I);
  //
   if (Lot = nil) or (Lot.Closed = 0) or (Lot.TypeLot = 254) {or (Lot.isCaptured)} then continue;
   if not Lot.IsVisible(Selector.GPRect) then continue;
   //if (X >= Lot.XMax) or (X <= Lot.XMin) or (Y >= Lot.YMax) or (Y <= Lot.YMin) then continue;
  //
   Lot.Selector := Selector;
   CaptureDrawer.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
   try
    Lot.Draw32(Twigs);
   finally
    CaptureDrawer.EndPrimitive;
   end;
   {
   ptList := FillPtList(Lot, R);
   if ptList = nil then continue;
    ogsGetPoint(ptList.List, Selector, X, Y, Params);
   ptList.Free;
   }
  //
   if Params.resObject <> nil then begin
    Params.resObject := Lot;
    LastCaptureRec := Params;
    Result := 1;
    Sect := TogsRect.Create;
    Sect.Insert(Lot.XMin, Lot.YMin); Sect.Insert(Lot.XMax, Lot.YMax);
    Sect.Insert(Lot.XMin, Lot.YMax); Sect.Insert(Lot.XMax, Lot.YMin);
    With Lot do
    // WriteIn(['Lot =', XMin, YMin, XMax, YMax , 'Sect =', Sect.XMin, Sect.YMin, Sect.XMax, Sect.YMax]);
     Sect.Free;
    break;
   end;
  end;
 finally
  if CaptureDrawer <> nil then begin
   CaptureDrawer.EndCapture;
   CaptureDrawer.Free;
  end;
 end;
end;

function TForm2.HitTestPointWorld(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
var Params: TCaptureRec; Index: Integer;
begin
 LastCaptureRec.resObject := nil;
 GetHitTestMarker(X, Y, RadiusWorld, Filter, MaxResults);
 if LastCaptureRec.resObject <> nil then
  Writein([TTD(LastCaptureRec.resObject).ClassName]) else
   Writein([nil]);
 if LastCaptureRec.resObject <> nil then begin
  if FObjects = nil then FObjects := TSelectedObjects.Create(Self, PropEditorForm.Update);
  Index := TSelectedObjects(FObjects).IndexOf(LastCaptureRec.resObject);
  If Index <> -1 then
   TSelectedObjects(FObjects).AtDelete(Index)
  else
   TSelectedObjects(FObjects).Insert(LastCaptureRec.resObject);
  Result := 1;
  exit;
 end;
end;

function TForm2.GetPrimitiveBoundsWorld(const PrimitiveId: TogsPrimitiveId; out Bounds: TSect): Boolean;
begin
 Bounds := Default(TSect);
 Result := False;
end;

function TForm2.SelectRectWorld(const Rect: TSect; Mode: TogsRectSelectMode; const Filter: TogsCaptureFilter): Integer;
begin
 Result := 0;
end;

procedure TForm2.PainSelection(const Canvas: ISkCanvas);
var Sel: TSelectedObjects;
    I: Integer;
    P: Pointer;
    Obj: TTD;
    SkObj: TogsSkiaObject;
    Pic: ISkPicture;
    R: TRectF;
    ptList:TPolyPolyline;
begin
 if (Canvas = nil) or (FObjects = nil) then exit;
// R := Canvas.GetLocalClipBounds;
 Sel := TSelectedObjects(FObjects);
  for I := 0 to Sel.Count - 1 do begin
   P := Sel[I];
   if (P <> nil) and (TObject(P) is TTD) then begin
    Obj := TTD(P);
    SkObj := Obj.DrawerObject as TogsSkiaObject;
    if SkObj = nil then continue;
    Pic := SkObj.Pictures[LOD1_INDEX];
    if Pic = nil then continue;
    ptList := FillPtList(Obj, R);
    if ptList = nil then continue;
    //OgsDrawPictureEffect(Canvas, R, Pic, $FFFFCC00, pemTintSrcATop, 110);
    //continue;
    OgsDrawPictureEffectLot(Canvas, ptList,
           TAlphaColorRec.Maroon, 2,
           TAlphaColorRec.Blue, 1.5,
           TAlphaColorRec.Aqua,
           Selector.GetScale, 4, rdmFillStroke);
    //
    ptList.Free;
   end;
  end;
end;

function TForm2.ClearSelection: boolean;
begin
 if FObjects <> nil then
  TSelectedObjects(FObjects).DeleteAll;
end;


end.
