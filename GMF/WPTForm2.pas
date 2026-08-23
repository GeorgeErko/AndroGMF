unit WPTForm2;

interface uses Collect, EcDot, WPTForm12, WPTwigs, Classes, SysUtils, newProcs,
              System.Types, System.Skia,
              ogcBasic, ogcCaptureIntf, ogcDrawerSkia;

type
 TForm2 = class(TFormTaheo, IogsPrimitiveCapturer, IogsSelectionAccess)
 protected
  FObjects: TTwgObject;
 public
  APoint: TPointDot;
  ParentMap:Pointer;
  LastCaptureRec: TCaptureRec;

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
  procedure PainSelection(const Canvas: ISkCanvas);
 //
  function selectedCount: Integer;
  function selectedPtr(Index: Integer): Pointer;
 end;

implementation uses SelectedObjects, ecLot;

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
 if FObjects = nil then Result := 0 else Result := 1;
end;

function TForm2.selectedPtr(Index: Integer): Pointer;
begin
 if (Index <> 0) or (FObjects = nil) then
  Result := nil
 else
  Result := FObjects;
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
begin
 Result := 0;
 FObjects := nil;
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
   if (Lot = nil) or (Lot.Closed = 0) or (Lot.TypeLot = 254) then
    continue;
   if not Lot.IsVisible(Selector.GPRect) then
    continue;
   Lot.Selector := Selector;
   CaptureDrawer.BeginPrimitive(Int64(NativeInt(Lot)), Lot);
   try
    Lot.Draw32(Twigs);
   finally
    CaptureDrawer.EndPrimitive;
   end;
   if Params.resObject <> nil then begin
    FObjects := TTwgObject(Params.resObject);
    LastCaptureRec := Params;
    Result := 1;
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

function TForm2.SelectRectWorld(const Rect: TSect; Mode: TogsRectSelectMode; const Filter: TogsCaptureFilter): Integer;
begin
 Result := 0;
end;

function TForm2.GetPrimitiveBoundsWorld(const PrimitiveId: TogsPrimitiveId; out Bounds: TSect): Boolean;
begin
 Bounds := Default(TSect);
 Result := False;
end;

function TForm2.HitTestPointWorld(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
begin

end;

procedure TForm2.PainSelection(const Canvas: ISkCanvas);
begin
end;

end.
