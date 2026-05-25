unit ObjBlockList;

interface Uses Collect, FMX.Graphics, newResource, Classes, TwgBitmaps;

type
  TBlockList=class(TTwgObject)
  private
    function GetBlock(Index: Integer): Pointer;
  public
   Blocks:PCollection; // коллекция блоков
   TempBlock:Pointer;  // временный блок
   {блок использует ссылку на примитивы графического объекта}
     Constructor Create;
     Destructor Destroy;override;
   {сохранение и загрузка блока}
     Constructor Load(B:TBufStream);override;
     Procedure Store(B:TBufStream);override;
   {}
     Procedure Insert(P:Pointer);
     Procedure Delete(Index:Integer);
     Function BlockByName(Name:AnsiString;var Index:Integer):Pointer;
     Function Count:Integer;
     Property Block[Index:Integer]:Pointer read GetBlock;default;
    //
     Function thisLayerExists(PR:TResource;List:TStrings):boolean;
    //
     Function GetBlockNames:TStrings;
     Function FindByProperty(PropName,PropValue:AnsiString):Pointer;
    //
     procedure CreateBitmaps;
   end;


type
 TLinkFiles = class (TTwgObject)
  Paths:TCStrings;
  Objects:TCStrings;
  Constructor Create;
  Destructor Destroy;override;
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
 //
  Procedure AddObject(objName:AnsiString);
 //
  Function FoundObjectPath(objName:AnsiString):AnsiString; // возвращает каталог где найден объект
  Procedure Clear;
  Function Count:Integer;
 //
  Function SearchFileName(FName:AnsiString):AnsiString;
 end;


 TTexture = class(TTwgObject)
  FileName:AnsiString;
// GDI+  Image:TGPImage;
  Used:Boolean;
  Settings:array [0..20] of byte;
  Constructor Create(FName_:AnsiString);
  Destructor Destroy;override;
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
 end;

 TTextureList = class(TTwgObject)
  private
   function GetTexture(Index: Integer): TTexture;
   procedure SetTexture(Index: Integer; const Value: TTexture);
  public
   Textures:PCollection;
   Settings:array [0..20] of byte;
   Constructor Create;
   Destructor Destroy;override;
   Property Texture[Index:Integer]:TTexture read GetTexture write SetTexture;
   Function Add(FName:AnsiString):TTexture;
   Function Find(FName:AnsiString):TTexture;
   Constructor Load(Stream:TBufStream);override;
   Procedure Store(Stream:TBufStream);override;
 end;


implementation uses newBlock, SysUtils, newProcs, userObject, newProperties,
                    Writer,
                    newSelector, ogcDrawerCanvas, ogcDrawerSkia,
                    FMX.Controls, EcLot, WPTwigs, ogcBasic, System.UITypes,
                    System.Types;
{ TBlockList }

Function ByBlock(P:Pointer):TGeoBlock; // ретипизация TGeoBlock
begin
 Result:= TGeoBlock(P);
end;

function TBlockList.BlockByName(Name: AnsiString;var Index:Integer): Pointer;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to Count-1 do If AnsiUpperCase(ByBlock(Blocks[I]).Name) = AnsiUpperCase(Name) then begin
  Result:=Blocks[I];Index:=I;exit;
 end;
end;

function TBlockList.Count: Integer;
begin
 Result:=Blocks.Count;
end;

constructor TBlockList.Create;
begin
 Blocks:=PCollection.Create(1);
 TempBlock:=nil;
end;

procedure TBlockList.Delete(Index: Integer);
begin
 Blocks.AtFree(Index);
end;

destructor TBlockList.Destroy;
begin
 Blocks.Free;
end;

function TBlockList.FindByProperty(PropName, PropValue: AnsiString): Pointer;
var I:Integer;Value:TPropValue;
begin
 Result:=nil;
 For I:=0 to Blocks.Count-1 do begin
  If TGeoBlock(Blocks[I]).Properties<>nil then
   Value:=TGeoBlock(Block[I]).Properties.propValue[PropName];
   If Value <> nil then
    If Value.Value = PropValue then begin
     Result:=Blocks[I];
     exit;
    end;
 end;
end;

function TBlockList.GetBlock(Index: Integer): Pointer;
begin
 Result:=Blocks[Index];
end;

function TBlockList.GetBlockNames: TStrings;
var I:Integer;
begin
 Result:=TStringList.Create;
 For I:=0 to Blocks.Count-1 do begin
  Result.Add(TGeoBlock(Block[I]).Name);
 end;
end;

procedure TBlockList.Insert(P: Pointer);
begin
 Blocks.Insert(P);
end;

constructor TBlockList.Load(B: TBufStream);
begin
 WriteS(['##BlocksLoad']);
 Blocks:=PCollection(B.Get);
 WriteS(['##BlocksCount=',Blocks.Count]);
end;

procedure TBlockList.Store(B: TBufStream);
begin
 B.Put(Blocks);
end;


function TBlockList.thisLayerExists(PR: TResource;
  List: TStrings): boolean;
var I:Integer;
begin
 Result:=False;
 For I:=0 to Blocks.Count-1 do If TGeoBlock(Block[I]).LayerExists(PR) then List.Add('"'+TGeoBlock(Block[I]).Name+'"');
 Result:=List.Count>0;
end;

procedure TBlockList.CreateBitmaps;
var I, J, K:Integer;
    Lot: TLot; Twig : TTwig; Drawer: TogsDrawerCanvas;
    newSelector: TSelector; oldSelector: Pointer;
    Control: TControl;
begin
 Control := TControl.Create(nil);
 Control.Width := 100; Control.Height := 100;
 try
  For K := 0 to Blocks.Count-1 do
   With TGeoBlock(Blocks[K]) do begin
    try
     Drawer := TogsDrawerCanvas.Create(nil, Control, 1, nil);
     newSelector := TSelector.Create(Drawer);
     Drawer.ogsSelector := newSelector;
     newSelector.GNForm := Control;
     GlobalRender := True;
     Drawer.BeginPaint;
     Drawer.Clear(0);
     for I := 1 to TwgForm.Twigs.TwigsCount - 1 do begin
      Twig := TwgForm.Twigs.TAt(I);
      for J := 0 to Twig.Coord.Count - 1 do
        newSelector.AddCoord(Twig[J].XDot, Twig[J].YDot);
     end;
     newSelector.UpdateRects(True);
     For I := 0 to  TwgForm.Twigs.IndexCount-1 do begin
      Lot:=TwgForm.Twigs.LAtIndex(I);If Lot.ClassHandle.Check = 0 then continue;
      Lot.SetMinMax2(TwgForm.Twigs);
      oldSelector := Lot.Selector; Lot.Selector := newSelector;
      GlobalRender := True;
      try
       Lot.Draw32(TwgForm.Twigs);
      finally
       Lot.Selector := oldSelector;
       GlobalRender := False;
      end;
     end;
    {
     // временный тест: рисуем диагональный крест через Canvas/Drawer
     if (Drawer <> nil) and (Drawer.Canvas <> nil) then
     begin
      Drawer.Canvas.Stroke.Kind := TBrushKind.Solid;
      Drawer.Canvas.Stroke.Thickness := 2;

      Drawer.Canvas.Stroke.Color := TAlphaColorRec.Red;
      Drawer.Canvas.DrawLine(PointF(0, 0),
                             PointF(Control.Width, Control.Height), 1);

      Drawer.Canvas.Stroke.Color := TAlphaColorRec.Blue;
      Drawer.Canvas.DrawLine(PointF(0, Control.Height),
                             PointF(Control.Width, 0), 1);
     end;
    }
     Drawer.EndPaint;
    // копируем битмап в блок (уже с нарисованным крестом через Drawer.Canvas)
     if BlockBitmap = nil then
      BlockBitmap := TTwgBitmap.Create;
   //  BlockBitmap.AlphaFormat := TAlphaFormat.Premultiplied;
     BlockBitmap.Bitmap.Assign(Drawer.Bitmap);
   //  BlockBitmap.AlphaFormat := TAlphaFormat.Premultiplied;
     FreeAndNil(ogsRect);
     ogsRect := TogsRect.Create;
     ogsRect.InsertRect(newSelector.ActiveRect);
     BlockX := newSelector.XPix(X + TwgForm.XXMin); BlockY := newSelector.YPix(Y + TwgForm.YYMin);
     finally
      // отладочное сохранение при необходимости
    //  ShowMessage(MainPath + Name +'.jpg');
    //  BlockBitmap.SaveToFile(MainPath + Name +'.jpg');
      newSelector.Free;
      Drawer.Free;
     end;
   end;
  finally
   Control.Free;
  end;
end;


{ TLinkFiles }

procedure TLinkFiles.AddObject;
var I:Integer;FoundPath:Boolean;
begin
 FoundPath:=False;
 For I:=0 to Paths.Count-1 do If AnsiUpperCase(Paths[I]) = AnsiUpperCase(GExtractFilePath(objName)) then begin FoundPath:=True;break;end;
 If not FoundPath then Paths.InsertStr(GExtractFilePath(objName));
 Objects.InsertStr(ExtractFileName(objName));
end;

constructor TLinkFiles.Create;
begin
 Paths:=TCStrings.Create(1);
 Objects:=TCStrings.Create(1);
end;

destructor TLinkFiles.Destroy;
begin
 Paths.Free;
 Objects.Free;
end;

constructor TLinkFiles.Load(Stream: TBufStream);
begin
 Paths:=TCStrings(Stream.Get);
 Objects:=TCStrings(Stream.Get);
end;

function TLinkFiles.FoundObjectPath(objName: AnsiString): AnsiString;
var S:AnsiString;I:Integer;
begin
 S:=ExtractFileName(objName);
 Result:='';
 For I:=0 to Paths.Count-1 do If FileExists(Paths[I]+'\'+S) then begin Result:=Paths[I];exit; end;
end;

procedure TLinkFiles.Store(Stream: TBufStream);
begin
 Stream.Put(Paths);
 Stream.Put(Objects);
end;

procedure TLinkFiles.Clear;
begin
 Objects.FreeAll;
end;

function TLinkFiles.Count: Integer;
begin
 Result:=Objects.Count;
end;

function TLinkFiles.SearchFileName(FName: AnsiString): AnsiString;
var I:Integer;
begin
 Result:='';
 For I:=Paths.Count-1 downTo 0 do If FileExists(Paths[I]+'\'+FName) then begin
  Result:=Paths[I]+'\'+FName;
  exit;
 end;
end;

{ TTexture }

constructor TTexture.Create(FName_: AnsiString);
begin
 FileName:=FName_;
// try Image:=TGPImage.Create(MainPath+'\Textures\'+FName_);except Image:=nil;end;
end;

destructor TTexture.Destroy;
begin
// If Image<>nil then Image.Free;
end;

constructor TTexture.Load(Stream: TBufStream);
begin
 FileName:=Stream.ReadString;
 Stream.Read(Settings,SizeOf(Settings));
// Image:=TGPImage.Create(MainPath+'\Textures\'+FileName);
end;

procedure TTexture.Store(Stream: TBufStream);
begin
 Stream.WriteString(FileName);
 Stream.Write(Settings,SizeOf(Settings));
end;

{ TTextureList }

function TTextureList.Add(FName: AnsiString): TTexture;
begin
 Result:=nil;
 If not FileExists(MainPath+'\Textures\'+FName) then exit;
 Result:=Find(FName);
 If Result<>nil then exit;
 Result:=TTexture.Create(FName);
 Textures.Insert(Result);
end;

function TTextureList.Find(FName: AnsiString): TTexture;
var I:Integer;
begin
 Result:=nil;
 For I:=0 to Textures.Count-1 do
  If Texture[I].FileName = FName then begin
   Result:=Textures[I];exit;
  end;
end;

function TTextureList.GetTexture(Index: Integer): TTexture;
begin
 Result:=Textures[Index];
end;

procedure TTextureList.SetTexture(Index: Integer; const Value: TTexture);
begin
 If Textures[Index]<>nil then TObject(Textures[Index]).Free;
 Textures[Index]:=Value;
end;

constructor TTextureList.Load(Stream: TBufStream);
begin
 Textures:=PCollection(Stream.Get);
 If Textures=nil then Textures:=PCollection.Create(1);
 Stream.Read(Settings,SizeOf(Settings));
end;

procedure TTextureList.Store(Stream: TBufStream);
begin
 Stream.Put(Textures);
 Stream.Write(Settings,SizeOf(Settings));
end;

constructor TTextureList.Create;
begin
 Textures:=PCollection.Create(1);
end;

destructor TTextureList.Destroy;
begin
 Textures.Free;
end;

initialization
end.
