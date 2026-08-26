unit WPTForm2;

interface uses Collect, EcDot, WPTForm12, WPTwigs, Classes, SysUtils, newProcs,
              System.Types, System.Skia,
              ogcBasic, ogcCaptureIntf, ogcDrawerSkia;

type
 TForm2 = class(TFormTaheo, IInterface, IogsPrimitiveCapturer, IogsSelectionAccess)
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
 //
  Function  CreateAs(F:TForm2):TForm2;
  Function  CreateObjectView(QueryOnCreate:Boolean):Boolean;override;
  Function  CreateView:Pointer;override;
  Procedure SaveObjView(View:Pointer);override;
 //
  Procedure ClearObject;
 //
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

implementation uses SelectedObjects, ecLot, Writer, ogcMarker, TwgDraw, FramePropEditor,
                    System.UITypes;

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

function TForm2.GetHitTestMarker(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
var XClick, YClick: Double;
    I: Integer;
    CaptureDrawer: TogsCaptureDrawerSkia;
    Params: TCaptureRec;
    Lot: TLot;
    Sect: TogsRect;
begin
 Result := 0;
 LastCaptureRec := CRClearParams([]);
 XClick := X;
 YClick := Y;
 CaptureDrawer := nil;
 try
  CaptureDrawer := TogsCaptureDrawerSkia.CreateCapture(Selector);
  Params := CRClearParams([ckLine, ckPolygon]);
  if Selector <> nil then
   Params.CaptureParam := Selector.GlobalSettings.Settings.gsPointSize * 2;
  CaptureDrawer.BeginCapture(XClick, YClick, Params);
  CaptureDrawer.UseWorldCoords := True;
  for I := Twigs.IndexCount - 1 downto 0 do begin
   Lot := Twigs.LAtIndex(I);
  //
   if (Lot = nil) or (Lot.Closed = 0) or (Lot.TypeLot = 254) then continue;
   if not Lot.IsVisible(Selector.GPRect) then continue;
   if (X > Lot.XMax) or (X < Lot.XMin) or (Y > Lot.YMax) or (Y < Lot.YMin) then continue;
  //
   Lot.Selector := Selector;
   CaptureDrawer.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
   try
    Lot.Draw32(Twigs);
   finally
    CaptureDrawer.EndPrimitive;
   end;
   if Params.resObject <> nil then begin
    LastCaptureRec := Params;
    Result := 1;
    Sect := TogsRect.Create;
    Sect.Insert(Lot.XMin, Lot.YMin); Sect.Insert(Lot.XMax, Lot.YMax);
    Sect.Insert(Lot.XMin, Lot.YMax); Sect.Insert(Lot.XMax, Lot.YMin);
    With Lot do
     WriteIn(['Lot =', XMin, YMin, XMax, YMax , 'Sect =', Sect.XMin, Sect.YMin, Sect.XMax, Sect.YMax]);
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
    if Obj is TLot then begin R.Left := TLot(P).XMin; R.Top := TLot(P).YMin; R.Right := TLot(P).XMax; R.Bottom := TLot(P).YMax; end;
   // OgsDrawPictureEffect(Canvas, R, Pic, $FFFFCC00, pemTintSrcATop, 110);
    TLot(Obj).insClipDotsParall(Twigs);
     OgsDrawPictureEffect2(Canvas, TLot(Obj).Points.List,
      TAlphaColorRec.Maroon, 2,
      TAlphaColorRec.Blue, 1.5,
      TAlphaColorRec.Aqua,
      Selector.GetScale, 3, rdmFillStroke);
     TLot(Obj).Points.Free;
   end;
  end;
end;

function TForm2.ClearSelection: boolean;
begin
 if FObjects <> nil then
  TSelectedObjects(FObjects).DeleteAll;
end;


end.
