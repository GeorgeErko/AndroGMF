unit EcDot2;

interface uses Collect, newFontScale, newSelector, TwgDraw, Classes,
               SysUtils, EcDot, ogcBasic,
               System.Types, System.UITypes, FMX.Graphics, FMX.TextLayout,
               ogcDrawerSkia,
               System.Skia,
               System.Math.Vectors;

const
 param_idResetFontView = 1;

type
 TText = class(TTwgObject)
  fontIndex:Integer;
  fontView:TFontViewEx;
  Text:AnsiString;
  Height:Single;
  Align:Byte;
  Color:Integer;
  TransParent:boolean;
  AttrName:AnsiString;
 //
  curPos:Integer;
  Constructor Create(Text_:AnsiString;H_:Single;Align_:Byte;Color_:Integer;fontView_:TFontViewEx);
  Constructor CreateAs(Text_:TText);
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
  Destructor Destroy;override;
 //
  Procedure GetXPYP(var XP,YP:Double);
  Function GetRotateRect(X2,Y2,kx,Angle:Double;All:Boolean = True): PCollection;
  Function GetTextPoint(X,Y,XDot,YDot,XKoef,Ugol:Double):boolean;
  Procedure SetIt(var bl,it,un,ou:byte);
 end;

 { TDotText }

 TDotText = class(TPointDot)
  Text:TText;
  TextBitmap: TBitmap;
  OwnsTextBitmap: Boolean;
  TextDirty: Boolean;
  BaseLinePix: Single;
  BaseLineXPix: Single;
  RightPadPix: Single;
  SymbolTopPix: Single;
  SymbolHeightPix: Single;
  Selected:Boolean;
  GyperLink:TStrings;
  FontColEx:TFontManagerEx; // коллекция символов. должно присваивается через bufStream
//  textSect:TSect;
  Constructor Create(X,Y:Double;Text_:AnsiString;H:Single;Color:Integer;Align_:Byte;Ugol_:Single;fontView_:TFontViewEx);
  Constructor CreateAsPoint_(P:TPointDot);override;
  Constructor CreateAsPointDot_(P:TPointDot;AddCollections:Boolean;CreateTreesCopy:boolean=True);override;
  Destructor Destroy; override;
  Constructor Load(Stream:TBufStream);override;
  Procedure Store(Stream:TBufStream);override;
 //
  Function ResetParams(ParamID: Integer;Params: Pointer):boolean;override;
 //
  Function GetDistance(X,Y:Double;Flag:Boolean=False):Double;override;
  Function GetZnkFont(X,Y,Ko:Double;var What1:Integer):Integer;override;
 //
  Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);override;
  Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer = nil);override;
  Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):boolean;override;
  Function GetProperty(propName:AnsiString):AnsiString;override;
 //
  Function GetSect:TSect;override;
  Procedure ChangeXYKoef(XK,YK:Double);override;
 //
  Procedure SetGabarites(MRect_:TMRect);override;
 //
  Procedure Draw32(Drawer: TogsDrawer;PntZnk:TSortedCollection;FontViewEx:TFontManagerEx;AlwaysShowAttr:Boolean = False);override;
 end;

var AlignStrings:TStrings;

procedure RegisterSkiaTypefaceFromFile(const FileName: string);

implementation

uses Types_Dimano, Polygons, TextManager, Maths_Basic, userObject,
     newProcs, newSettings, newForm0, newProperties, newConsts,
     Writer, FMX.FontManager;

var
 SkiaFontFiles: TStringList;

procedure RegisterSkiaTypefaceFromFile(const FileName: string);
var
 TF: ISkTypeface;
 Fam: string;
 Idx: Integer;
begin
 if FileName = '' then Exit;
 if SkiaFontFiles = nil then
 begin
  SkiaFontFiles := TStringList.Create;
  SkiaFontFiles.CaseSensitive := False;
  SkiaFontFiles.Duplicates := dupIgnore;
  SkiaFontFiles.Sorted := True;
 end;

 TF := TSkTypeface.MakeFromFile(FileName);
 if TF = nil then Exit;

 Fam := TF.FamilyName;
 if Fam = '' then Exit;

 Idx := SkiaFontFiles.IndexOfName(Fam);
 if Idx < 0 then
  SkiaFontFiles.Add(Fam + '=' + FileName)
 else
 begin
  SkiaFontFiles.Delete(Idx);
  SkiaFontFiles.Add(Fam + '=' + FileName);
 end;
end;

function ResolveRegisteredFontFamily(const RequestedFamily: string): string;
var
 I: Integer;
begin
 Result := RequestedFamily;
 if RequestedFamily = '' then Exit;
 for I := 0 to TFontManager.CustomFontInfoCount - 1 do
  if SameText(TFontManager.CustomFontInfo[I].FamilyName, RequestedFamily) then
   Exit(TFontManager.CustomFontInfo[I].FamilyName);
end;

function WinColorToAlphaColor(const C: Integer): TAlphaColor;
var
 R, G, B: Integer;
begin
 R := (C and $FF);
 G := (C shr 8) and $FF;
 B := (C shr 16) and $FF;
 Result := TAlphaColor($FF000000 or (R shl 16) or (G shl 8) or B);
end;

{ TText }

constructor TText.Create(Text_:AnsiString;H_:Single;Align_:Byte;Color_:Integer;fontView_:TFontViewEx);
begin
 fontView:=fontView_;
 Text:=Text_;
 Height:=H_;
 Align:=Align_;
 Color:=Color_;
 curPos:=-1;
 TransParent:=True;
 AttrName:='';
end;

constructor TText.CreateAs(Text_: TText);
begin
 fontView:=Text_.fontView;
 Text:=Text_.Text;
 Height:=Text_.Height;
 Align:=Text_.Align;
 Color:=Text_.Color;
 curPos:=-1;
 TransParent:=Text_.Transparent;
 AttrName:=Text_.AttrName;
end;

destructor TText.Destroy;
begin
//
end;

constructor TText.Load(Stream: TBufStream);
begin
// FontView:=TSelector(Stream.Selector).FontView;
 Text:=Stream.ReadString;
 Stream.Read(fontIndex,SizeOf(fontIndex));
 Stream.Read(Height,SizeOf(Height));
 Stream.Read(Align,SizeOf(Align));
 Stream.Read(Color,SizeOf(Color));
 Stream.Read(TransParent,SizeOf(byte));
 AttrName:=Stream.ReadString;
end;

procedure TText.Store(Stream: TBufStream);
begin
 Stream.WriteString(Text);
 Stream.Write(FontView.Index, SizeOf(FontView.Index));
 Stream.Write(Height,SizeOf(Height));
 Stream.Write(Align,SizeOf(Align));
 Stream.Write(Color,SizeOf(Color));
 Stream.Write(TransParent,SizeOf(byte));
 Stream.WriteString(AttrName);
end;

procedure TText.GetXPYP(var XP, YP: Double);
begin
 If Align in [0,4,8] then begin
  If Align = 0 then begin XP:=0;YP:=-1 end else
  If Align = 4 then begin XP:=0.5;YP:=-1 end else
  If Align = 8 then begin XP:=1;YP:=-1 end;
 end else
 If Align in [1,5,9] then begin
  If Align = 1 then begin XP:=0;YP:=1 end else
  If Align = 5 then begin XP:=0.5;YP:=1 end else
  If Align = 9 then begin XP:=1;YP:=1 end;
 end else
 If Align in [2,6,10] then begin
  If Align = 2 then begin XP:=0;YP:=0.5 end else
  If Align = 6 then begin XP:=0.5;YP:=0.5 end else
  If Align = 10 then begin XP:=1;YP:=0.5 end;
 end else begin
  If Align = 3 then begin XP:=0;YP:=0 end else
  If Align = 7 then begin XP:=0.5;YP:=0 end else
  If Align = 11 then begin XP:=1;YP:=0 end;
 end;
end;

function TText.GetRotateRect(X2, Y2, kx, Angle:Double;All:Boolean): PCollection;
var GW1,GH1:Single;I:integer;GW,GH,Hsim,X1,Y1:double;
    XP,YP:Double;H:Double;
begin
 Angle:=-Angle*180/Pi;
If FontView<>nil then begin
  Hsim:=Height;
  H:=Height*(FontView.Scale/FontView.RH(StyleSym_Height));
  Y1:=Y2;X1:=X2;
  FontView.SetParams(H,kx);
  GetXPYP(XP,YP);
 //!!!
//  FontView.GetTextLen(XPix(X2),YPix(Y2),H*GMS/FontView.Scale,0,Text,GW1,GH1);GW:=GW1/GMS;GH:=GH1/GMS;
  if (Yp<>-1)then
     begin
     X1:=X2-(sin(Angle*10/1800*pi)*(H*FontView.kUp+Hsim*Yp))-(sin((900+Angle*10)/1800*pi)*GW*Xp);
     Y1:=Y2-(cos(Angle*10/1800*pi)*(H*FontView.kUp+Hsim*Yp))+(cos((-900+Angle*10)/1800*pi)*GW*Xp);
     end
  else
     begin
     X1:=X2-(sin(Angle*10/1800*pi)*GH)-(sin((900+Angle*10)/1800*pi)*GW*Xp);
     Y1:=Y2-(cos(Angle*10/1800*pi)*GH)+(cos((-900+Angle*10)/1800*pi)*GW*Xp);
     end;
  result:=PCollection.Create(6);
  result.Insert(TDot1.Create(X1+(sin((Angle*10)/1800*pi)*(H*FontView.kUp)),Y1+(cos((Angle*10)/1800*pi)*(H*FontView.kUp))));
  result.Insert(TDot1.Create(X1+(sin((Angle*10)/1800*pi)*GH),Y1+(cos((Angle*10)/1800*pi)*GH)));
  result.Insert(TDot1.Create(X1+(sin(Angle*10/1800*pi)*GH)+(sin((900+Angle*10)/1800*pi)*GW),Y1+(cos(Angle*10/1800*pi)*GH)+(cos((900+Angle*10)/1800*pi)*GW)));
  result.Insert(TDot1.Create(X1+(sin(Angle*10/1800*pi)*(H*FontView.kUp))+(sin((900+Angle*10)/1800*pi)*GW),Y1+(cos(Angle*10/1800*pi)*(H*FontView.kUp))+(cos((900+Angle*10)/1800*pi)*GW)));
  If All then begin
   result.Insert(TDot1.Create(X1+(sin((Angle*10)/1800*pi)*(H*FontView.kUp+Hsim)),Y1+(cos((Angle*10)/1800*pi)*(H*FontView.kUp+Hsim))));//DL
   result.Insert(TDot1.Create(X1+(sin(Angle*10/1800*pi)*(H*FontView.kUp+Hsim))+(sin((900+Angle*10)/1800*pi)*GW),Y1+(cos(Angle*10/1800*pi)*(H*FontView.kUp+Hsim))+(cos((900+Angle*10)/1800*pi)*GW)));//DR
  end else Result.Insert(TDot1.Create(TDot1(Result[0]).X,TDot1(Result[0]).Y));
end;
//  PSetPixel(TDot1(Result[0]).X,TDot1(Result[0]).Y);
end;

function TText.GetTextPoint(X, Y, XDot, YDot, XKoef, Ugol: Double): boolean;
var GW1,GH1:Single;Y1,X1,Hsim,GW,GH:double;
    Br,Pen:THandle;XP,YP:Double;H,Angle:Double;
    brColor:Integer;
begin
 Angle :=-Ugol*180/Pi;
 //
  Hsim:=Height;
  H:=Height*(FontView.Scale/FontView.RH(StyleSym_Height));
  FontView.SetParams(H,XKoef);
  Y1:=YDot;X1:=XDot;
  GetXPYP(XP,YP);
//!!  FontView.GetTextLen(0,0,H*GMS/FontView.Scale,0,Text,GW1,GH1);GW:=GW1/GMS; GH:=GH1/GMS;
  {writeln('-----------------');
  writeln('H=',H);
  writeln('?=',FontView.Kline);
  writeln(H*FontView.Kline); }
  if (Yp<>-1)then
     begin
     X1:=XDot-(sin(Angle*10/1800*pi)*(H*FontView.kUp+Hsim*Yp))-(sin((900+Angle*10)/1800*pi)*GW*Xp);
     Y1:=YDot-(cos(Angle*10/1800*pi)*(H*FontView.kUp+Hsim*Yp))+(cos((-900+Angle*10)/1800*pi)*GW*Xp);
//!!     Result:=FontView.GetTextPoint(XPix(X),YPix(Y),XPix(X1),YPix(Y1), H*GMS/FontView.Scale,Angle,Text);
     end
  else
     begin
     X1:=XDot-(sin(Angle*10/1800*pi)*GH)-(sin((900+Angle*10)/1800*pi)*GW*Xp);
     Y1:=YDot-(cos(Angle*10/1800*pi)*GH)+(cos((-900+Angle*10)/1800*pi)*GW*Xp);
//!!     Result:=FontView.GetTextPoint(XPix(X),YPix(Y),XPix(X1),YPix(Y1), H*GMS/FontView.Scale,Angle,Text);
     end;
end;

procedure TText.SetIt(var bl,it,un,ou:byte);
begin
 bl:=FontView.bl;
 it:=FontView.it;
 un:=FontView.un;
 ou:=FontView.ov;
end;


constructor TDotText.Create(X,Y:Double;Text_:AnsiString;H:Single;Color:Integer;Align_:Byte;Ugol_:Single;fontView_:TFontViewEx);
begin
 inherited Create(X,Y,0);
 Ugol:=Ugol_;
 Text:=TText.Create(Text_,H,Align_,Color,fontView_);
 XKoef:=1;
 What:=1;
 GyperLink:=TStringList.Create;
 TextBitmap := nil;
 OwnsTextBitmap := True;
 TextDirty := True;
end;

constructor TDotText.CreateAsPoint_(P: TPointDot);
begin
 inherited;
 Text := TText.CreateAs(TDotText(P).Text);
 TextBitmap := nil;
 OwnsTextBitmap := True;
 TextDirty := True;
 GyperLink:=TStringList.Create;
 GyperLink.Text:=TDotText(P).GyperLink.Text;
 XKoef:=TDotText(P).XKoef;
 What:=TDotText(P).What;
 Ugol:=TDotText(P).Ugol;
end;

constructor TDotText.CreateAsPointDot_(P: TPointDot; AddCollections: Boolean; CreateTreesCopy: boolean);
begin
 inherited;
 Text := TText.CreateAs(TDotText(P).Text);
 TextBitmap := nil;
 OwnsTextBitmap := True;
 TextDirty := True;
 GyperLink:=TStringList.Create;
 GyperLink.Text:=TDotText(P).GyperLink.Text;
 XKoef:=TDotText(P).XKoef;
 What:=TDotText(P).What;
 Ugol:=TDotText(P).Ugol;
end;

constructor TDotText.Load(Stream: TBufStream);
var Index:Integer;
begin
 inherited;
 Text:=TText(Stream.Get);
 GyperLink:=TStringList.Create;
 GyperLink.Text:=Stream.ReadString;
 TextBitmap := nil;
 OwnsTextBitmap := True;
 TextDirty := True;
end;

function TDotText.ResetParams(ParamID:Integer;Params:Pointer):boolean;
const
 lodFixedHeight: Integer = 40;
var
  W: Integer;
  S: string;
  H: Double;
  Family: string;
  Candidate: string;
  I: Integer;
  FileName: string;
  Idx: Integer;
  Weight: TSkFontWeight;
  Slant: TSkFontSlant;
  Typeface: ISkTypeface;
  Font: ISkFont;
  FontSize: Single;
  ScaleK: Single;
  Metrics: TSkFontMetrics;
  Bounds: TRectF;
  TightAscentAbs: Single;
  ScaleCorr: Single;
  BaselineY: Single;
  DebugPaint: ISkPaint;
  YTop: Single;
  YAscent: Single;
  YBaseline: Single;
  YDescent: Single;
  YBottom: Single;
  ImgInfo: TSkImageInfo;
  Surface: ISkSurface;
  Paint: ISkPaint;
  D: TBitmapData;
  DataPtr: Pointer;
  RowBytes: Integer;
begin
 inherited ResetParams(ParamID, Params);
 What:=1;
 case ParamID of
  1:begin
     If Text.fontIndex>TFontManagerEx(Params).Count-1 then begin
      Text.fontIndex:=0;
     end;
     Text.FontView:=TFontManagerEx(Params)[Text.fontIndex];
     if Text.FontView <> nil then
     begin
      if TextBitmap = nil then
       if OwnsTextBitmap then
        TextBitmap := TBitmap.Create
       else
       begin
        Result := False;
        Exit;
       end;

      if (not TextDirty) and (TextBitmap.Width > 0) and (TextBitmap.Height > 0) then
      begin
       Result := True;
       Exit;
      end;

       Family := ResolveRegisteredFontFamily(string(Text.FontView.FontName));
       S := string(Text.Text);

       Weight := TSkFontWeight.Normal;
       if Text.FontView.Bl <> 0 then
        Weight := TSkFontWeight.Bold;

       Slant := TSkFontSlant.Upright;
       if Text.FontView.It <> 0 then
        Slant := TSkFontSlant.Italic;

       Typeface := nil;
       Candidate := ResolveRegisteredFontFamily(string(Text.FontView.FontName));

       FileName := '';
       if (SkiaFontFiles <> nil) and (Candidate <> '') then
       begin
        Idx := SkiaFontFiles.IndexOfName(Candidate);
        if Idx >= 0 then
         FileName := SkiaFontFiles.ValueFromIndex[Idx];
       end;

       if FileName <> '' then
        Typeface := TSkTypeface.MakeFromFile(FileName);

       if (Typeface = nil) and (Candidate <> '') then
        Typeface := TSkTypeface.MakeFromName(Candidate, TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant));

       if (Typeface = nil) and (Candidate <> '') then
        for I := 0 to TFontManager.CustomFontInfoCount - 1 do
         if SameText(TFontManager.CustomFontInfo[I].FamilyName, Candidate) then
         begin
          Typeface := TSkTypeface.MakeFromName(TFontManager.CustomFontInfo[I].FamilyName,
            TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant));
          if Typeface <> nil then
           Break;
         end;

       if Typeface = nil then
        Typeface := TSkTypeface.MakeFromName(Family, TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant));

       FontSize := lodFixedHeight;
       Font := TSkFont.Create(Typeface, FontSize);

       Font.GetMetrics(Metrics);
       if (-Metrics.Ascent) > 0.01 then
       begin
        ScaleK := lodFixedHeight / (-Metrics.Ascent);
        FontSize := FontSize * ScaleK;
        Font := TSkFont.Create(Typeface, FontSize);
       end;

       Paint := TSkPaint.Create;
       Paint.AntiAlias := True;
       Font.MeasureText(S, Bounds, Paint);
       TightAscentAbs := -Bounds.Top;
       if TightAscentAbs > 0.01 then
       begin
        ScaleCorr := lodFixedHeight / TightAscentAbs;
        if Abs(ScaleCorr - 1) > 1e-4 then
        begin
         FontSize := FontSize * ScaleCorr;
         Font := TSkFont.Create(Typeface, FontSize);
         Font.MeasureText(S, Bounds, Paint);
         TightAscentAbs := -Bounds.Top;
        end;
       end;

       BaseLineXPix := 2;
       RightPadPix := 4;

       W := Trunc(Bounds.Width + 0.9999);
       W := W + Round(BaseLineXPix + RightPadPix);
       if W < 2 then W := 2;

       SymbolTopPix := 2;
       SymbolHeightPix := TightAscentAbs;
       if SymbolHeightPix <= 0 then
        SymbolHeightPix := lodFixedHeight;
       BaseLinePix := SymbolTopPix + SymbolHeightPix;
       H := BaseLinePix + 2;
       TextBitmap.SetSize(W, Round(H));

       if TextBitmap.Map(TMapAccess.Write, D) then
       try
        ImgInfo := TSkImageInfo.Create(TextBitmap.Width, TextBitmap.Height, TSkColorType.BGRA8888, TSkAlphaType.Premul);
        DataPtr := D.Data;
        RowBytes := D.Pitch;
        if RowBytes < 0 then
        begin
         RowBytes := -RowBytes;
         DataPtr := Pointer(NativeInt(DataPtr) + NativeInt(RowBytes) * (TextBitmap.Height - 1));
        end;
        Surface := TSkSurface.MakeRasterDirect(ImgInfo, DataPtr, RowBytes);
        if Surface <> nil then
        begin
         Paint.Color := WinColorToAlphaColor(Text.Color);
         Surface.Canvas.Clear(0);

         BaselineY := BaseLinePix;

         Surface.Canvas.DrawSimpleText(S, BaseLineXPix - Bounds.Left, BaselineY, Font, Paint);
        end
       finally
        TextBitmap.Unmap(D);
       end;
       TextDirty := False;
       Result:=True;
     end;
    end;
  end;
end;

{ If (X<textSect.Left) or (Y<textSect.Bottom) or (X>textSect.Right) or (Y>textSect.Top) then begin
  exit;
 end;}
// P:=Text.GetRotateRect(XDot,YDot,XKoef,Ugol,False);
// For I:=0 to P.Count-1 do If I=0 then PMoveTo(TDot1(P[I]).X,TDot1(P[I]).Y) else PLineTo(TDot1(P[I]).X,TDot1(P[I]).Y);
//  If Point_and_Polygon(X,Y,P)>-1 then begin
//   If Text.GetTextPoint(X,Y,XDot,YDot,XKoef,Ugol) then Result:=0 else Result:=-1;
//  end else Result:=100000000;
//  WRiteln(Result);
// P.Free;
//end;

function TDotText.GetZnkFont(X, Y, Ko: Double; var What1: Integer): Integer;
begin
 If GetDistance(X,Y,False) = 0 then Result:=100 else Result:=-1;
end;

procedure TDotText.GetObjectProps(propNames, propValues, propTypes: TStrings;Data:Pointer = nil);
var I:Integer;
begin
 PropNames.Add('Цвет');PropNames.Add('Шрифт');PropNames.Add('Размер');PropNames.Add('Стиль');PropNames.Add('Выравнивание');PropNames.Add('Прозрачность');PropNames.Add('Растяжение');PropNames.Add('Угол');PropNames.Add('Текст');PropNames.Add('Аттрибут');PropNames.Add('Гиперссылка');
 If PropTypes<>nil then begin
  propTypes.Add('Color');propTypes.Add('FontName');propTypes.Add('Float');propTypes.Add('FontStyle');propTypes.Add('Align');propTypes.Add('Boolean');propTypes.Add('Float');propTypes.Add('Float');propTypes.Add('StringSpr');PropTypes.Add('AnsiString');PropTypes.Add('Memo');
 end;
 PropValues.Add(GetProperty('Цвет'));PropValues.Add(GetProperty('Шрифт'));PropValues.Add(GetProperty('Размер'));PropValues.Add(GetProperty('Стиль'));PropValues.Add(GetProperty('Выравнивание'));PropValues.Add(GetProperty('Прозрачность'));PropValues.Add(GetProperty('Растяжение'));PropValues.Add(GetProperty('Угол'));PropValues.Add(GetProperty('Текст'));PropValues.Add(GetProperty('Аттрибут'));PropValues.Add(GetProperty('Гиперссылка'));
 If Properties<>nil then
  For I:=0 to Properties.Count-1 do begin
   If Pos('*',Properties[I].PropName)=1 then begin PropNames.Add(Properties[I].PropName);propTypes.Add('AnsiString');propValues.Add(Properties[I].PropValue.Value);end;
  end;
end;

procedure TDotText.GetPropMerge(Obj: TTD; propNames, propValues, propTypes: TStrings);
var I,Index:Integer;Names,Values,Types:TStrings;
begin
 If propNames.Count=0 then begin
  GetObjectProps(propNames,propValues,propTypes);                                                                                                                                                                                                                                                         
 end else begin
  Names:=TStringList.Create;Values:=TStringList.Create;Types:=TStringList.Create;
  GetObjectProps(Names,Values,Types);
  For I:=0 to Names.Count-1 do begin
   Index:=propNames.IndexOf(Names[I]);
   If Index<>-1 then propNames.Objects[Index]:=Self;
  end;
  Names.Free;Values.Free;Types.Free;
{}
  For I:=propNames.Count-1 downTo 0 do If propNames.Objects[I]<>Self then begin
   propNames.Delete(I);
   propValues.Delete(I);
   propTypes.Delete(I);
  end;
 end;
end;

function TDotText.GetProperty(propName: AnsiString): AnsiString;
var V:TPropValue;Style:Integer;
begin
(*
 If propName = 'Цвет' then begin
  Result:=IntToStr(Text.Color);//inherited GetProperty(propName);
{  If Text.Color = RGB(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]) then Result:=byLayer else
                                                                                                    Result:=;
}
 // Result:=inherited GetProperty(propName);
 end else
*)
 If PropName ='Шрифт' then begin
  Result:=Text.fontView.FontName;
 end else
 If propName = 'Размер' then begin
  Result:=FloatToStrF(Text.Height,ffFixed,_LD,2);
 end else
 If propName ='Стиль' then begin
  Style:=Text.fontView.bl;
  If Text.fontView.It=1 then Style:=Style or tpItalic;If Text.fontView.Un=1 then Style:=Style or tpUnderline;
  Result:=IntToStr(Style);
 end else
 If propName = 'Прозрачность' then begin
  If Text.TransParent then Result:='Да' else Result:='Нет';
 end else
 If propName = 'Текст' then begin
  Result:=Text.Text;
 end else
 If propName = 'Аттрибут' then begin
  Result:=Text.AttrName;
 end else
 If propName = 'Растяжение' then begin
  Result:=FloatToStrF(XKoef,ffFixed,_LD,2);
 end else
 If propName = 'Выравнивание' then begin
  Result:=AlignStrings[Text.Align];
 end else
 If PropName = 'Угол' then Result:=FloatToStrF(Ugol*180/Pi,ffFixed,_LD,1) else
 If Properties<>nil then begin
  V:=Properties.PropValue[propName];
  If V=nil then Result:=byLayer else Result:=V.Value;
 end else Result:=byNone;
end;

function TDotText.SetProperty(propName: AnsiString; propValue: AnsiString;Obj: TTD): boolean;
var Index,Style:Integer;FUn,FBl,FIt:Integer;S:AnsiString;
begin
{ If propName = 'Цвет' then begin
  If propValue = byLayer then begin
   Text.Color:=RGB(ClassHandle.RGB.Argb[1],ClassHandle.RGB.Argb[2],ClassHandle.RGB.Argb[3]);
  end else try Text.Color:=StrToInt(propValue);except exit;end;
  Result:=True;
 end else}
 If propName = 'Шрифт' then begin
  Text.fontView.FontColEx:=FontColEx;
  Index:=Text.fontView.FontColEx.AddFont(0{GCanvas.Handle},propValue,0,0,Text.fontView.CharSet,Text.fontView.Bl,Text.fontView.It,Text.fontView.Un,Text.fontView.Scale);
  Text.fontView:=Text.fontView.FontColEx[Index];
  TextDirty := True;
  Result:=True;
 end else
 If propName = 'Размер' then begin
  try Text.Height:=GStrToFloat(propValue);except end;
  TextDirty := True;
  Result:=True;
 end else
 If propName = 'Стиль' then begin
  try Style:=StrToInt(propValue);except exit;end;
   FUn := ord((Style and tpUnderline) <> 0);
   FBl := ord((Style and tpBold) <> 0);
   FIt := ord((Style and tpItalic) <> 0);
  Index:=Text.fontView.FontColEx.AddFont(0{GCanvas.Handle},Text.fontView.FontName,0,0,Text.fontView.CharSet,FBl,FIt,FUn,Text.fontView.Scale);
  Text.fontView:=Text.fontView.FontColEx[Index];
  TextDirty := True;
  Result:=True;
 end else
 If PropName = 'Прозрачность' then begin
  //S:=GetProperty('Прозрачность');
  //Text.Transparent:=True;
  S:=propValue;
  If S = 'Нет' then Text.Transparent:=False else
  If S = 'Да' then Text.Transparent:=True else
  If S = byLayer then Text.TransParent:=ClassHandle.GlassFon;
  TextDirty := True;
  Result:=True;
 end else
 If PropName = 'Текст' then begin
  If propValue=byLayer then exit;
  Text.Text:=propValue;
  TextDirty := True;
  Result:=True;
 end else
 If PropName = 'Аттрибут' then begin
  if propValue = '' then exit;
  Text.AttrName:=propValue;
  Result:=True;
 end else
 If PropName = 'Растяжение' then begin
  try XKoef:=GStrToFloat(propValue); except exit;end;
  Result:=True;
 end else
 If PropName = 'Выравнивание' then begin
  If AlignStrings.IndexOf(propValue)<>-1 then Text.Align:=AlignStrings.IndexOf(propValue);
  Result:=True;
 end else begin
 If Properties=nil then  begin
  If AnsiString(PropValue) = byLayer then exit;
  Properties:=TProperties.Create;
 end;
 If AnsiString(PropValue) = byLayer then begin
  Properties.DeleteProperty(propName);
  Result:=True;
  If Properties.Count = 0 then begin Properties.Free;Properties:=nil;end;
 end else
 If PropName = 'Угол' then begin Ugol:=StrToFloat(propValue)*Pi/180;Result:=True;exit;end
 else begin
  Result:=True;
  If AnsiString(GetProperty(propName)) <> AnsiString(propValue) then begin
   Properties.AddProperty(propName,propValue);
  end else Result:=False;
 end;
 end;
end;

function TDotText.GetSect: TSect;
const
 lodFixedHeight: Single = 40;
var
 GX, GY: Double;
 SX, SY: Double;
 XP, YP: Double;
 OffX, OffY: Double;
 W, H: Double;
 X0, Y0, X1, Y1: Double;
 X2, Y2, X3, Y3: Double;
 C, S: Double;
 M: TMRect;
 RX, RY: Double;
 N: Integer;
begin
 If Text.FontView = nil then begin
  Result := inherited GetSect;
  exit;
 end;
 if (TextBitmap = nil) or (TextBitmap.Width <= 0) or (TextBitmap.Height <= 0) then
 begin
  Result := inherited GetSect;
  Exit;
 end;
 try
 N := 0;
 GX := Text.Height / lodFixedHeight;
 GY := Text.Height / lodFixedHeight;
 SX := GX;
 SY := GY;
 if XKoef <> 0 then
  SX := SX * XKoef;

 W := TextBitmap.Width * SX;
 H := TextBitmap.Height * SY;

  N := 1;
  Text.GetXPYP(XP, YP);
   N := 2;
 OffX := (BaseLineXPix + (TextBitmap.Width - BaseLineXPix - RightPadPix) * XP) * SX;
 if YP < 0 then
  OffY := BaseLinePix * SY
 else
  OffY := (SymbolTopPix + SymbolHeightPix * YP) * SY;

 X0 := -OffX;
 Y0 := -OffY;
 X1 := -OffX + W;
 Y1 := -OffY;
 X2 := -OffX + W;
 Y2 := -OffY + H;
 X3 := -OffX;
 Y3 := -OffY + H;

 C := Cos(Ugol);
 S := Sin(Ugol);
  N := 3;
 M := TMRect.Create;
 try
  RX := X0 * C - Y0 * S; RY := X0 * S + Y0 * C; M.Insert(XDot + RX, YDot + RY);
  RX := X1 * C - Y1 * S; RY := X1 * S + Y1 * C; M.Insert(XDot + RX, YDot + RY);
  RX := X2 * C - Y2 * S; RY := X2 * S + Y2 * C; M.Insert(XDot + RX, YDot + RY);
  RX := X3 * C - Y3 * S; RY := X3 * S + Y3 * C; M.Insert(XDot + RX, YDot + RY);
  Result := M.Sect;
   N := 4;
 except
  raise Exception.Create(Fmt(['Error Message = ', N]));
 end;
 finally
  M.Free;
 end;
end;

procedure TDotText.ChangeXYKoef(XK, YK: Double);
begin
 XKoef:=XK;Text.Height:=Text.Height*YK;
end;

procedure TDotText.SetGabarites(MRect_: TMRect);
begin
//
end;

destructor TDotText.Destroy;
begin
 if OwnsTextBitmap and (TextBitmap <> nil) then
  TextBitmap.Free;
 if GyperLink <> nil then
  GyperLink.Free;
 if Text <> nil then
  Text.Free;
 inherited;
end;

procedure TDotText.Store(Stream: TBufStream);
begin
 inherited;
 Stream.Put(Text);
 Stream.WriteString(GyperLink.Text);
end;

function TDotText.GetDistance(X, Y: Double; Flag: Boolean): Double;
begin
 Result := inherited GetDistance(X, Y, Flag);
end;

procedure TDotText.Draw32(Drawer: TogsDrawer; PntZnk: TSortedCollection; FontViewEx: TFontManagerEx;
 AlwaysShowAttr: Boolean);
label VectorText;
const
 lodFixedHeight: Single = 40;
var
 S: Single;
 SX, SY: Single;
 H, W: Single;
 HPix: Single;
 OffX, OffY: Single;
 AnchorPix: TPointF;
 St: TCanvasSaveState;
 Dst: TRectF;
 XP, YP: Double;
 TxtColor: TAlphaColor;
begin
 if Drawer = nil then Exit;
 if Selector = nil then Exit;
 if Text = nil then Exit;
 HPix := Selector.XRasst(Text.Height);

 // Skia path: draw raster TextBitmap onto Skia canvas (LOD)
 if (Drawer is TogsDrawerSkia) and (HPix <= 40) then
 begin
  if Selector.GetScale = 0 then Exit;
  if (TextBitmap = nil) or TextDirty or (TextBitmap.Width <= 0) or (TextBitmap.Height <= 0) then
   if FontViewEx <> nil then
    ResetParams(1, FontViewEx)
   else
    TextDirty := True;
  if (TextBitmap = nil) or (TextBitmap.Width <= 0) or (TextBitmap.Height <= 0) then
   goto VectorText;

  H := HPix;
  if H <= 0 then Exit;

  if SymbolHeightPix > 0 then
   S := H / SymbolHeightPix
  else
   S := H / lodFixedHeight;
  SX := S;
  SY := S;
  if XKoef <> 0 then
   SX := SX * XKoef;

  W := TextBitmap.Width * SX;
  H := TextBitmap.Height * SY;

  Text.GetXPYP(XP, YP);
  OffX := (BaseLineXPix + (TextBitmap.Width - BaseLineXPix - RightPadPix) * Single(XP)) * SX;
  if YP < 0 then
   OffY := BaseLinePix * SY
  else
   OffY := (SymbolTopPix + SymbolHeightPix * Single(YP)) * SY;

  if TogsDrawerSkia(Drawer).UseWorldCoords then
  begin
   AnchorPix := PointF(Single(XDot), Single(YDot));
   W := W / Selector.GetScale;
   H := H / Selector.GetScale;
   OffX := OffX / Selector.GetScale;
   OffY := OffY / Selector.GetScale;
  end
  else
   AnchorPix := PointF(Selector.XPix(XDot), Selector.YPix(YDot));

  Dst := RectF(-OffX, -OffY, -OffX + W, -OffY + H);
  TogsDrawerSkia(Drawer).DrawBitmapAlignedPix(AnchorPix, TextBitmap, Dst, Ugol);
  Exit;
 end;

 // Skia vector text path
 if (Drawer is TogsDrawerSkia) then
 begin
VectorText:
  if Selector.GetScale = 0 then Exit;
  if TogsDrawerSkia(Drawer).UseWorldCoords then
   H := Text.Height
  else
   H := Selector.XRasst(Text.Height);
  if H <= 0 then Exit;

  Text.GetXPYP(XP, YP);
  AnchorPix := PointF(Single(XDot), Single(YDot));
  TxtColor := WinColorToAlphaColor(Text.Color);

  TogsDrawerSkia(Drawer).DrawTextAlignedPix(
    AnchorPix,
    string(Text.Text),
    TxtColor,
    H,
    Ugol,
    XP, YP,
    XKoef,
    Text.FontView
  );
  Exit;
 end;

 // FMX canvas path (legacy)
 if Drawer.Canvas = nil then Exit;
 if TextBitmap = nil then Exit;
 if (TextBitmap.Width <= 0) or (TextBitmap.Height <= 0) then Exit;

 H := Selector.XRasst(Text.Height);
 if H <= 0 then Exit;

 if BaseLinePix > 0 then
  S := H / BaseLinePix
 else
  S := H / lodFixedHeight;
 SX := S;
 SY := S;
 if XKoef <> 0 then
  SX := SX * XKoef;

 W := TextBitmap.Width * SX;
 H := TextBitmap.Height * SY;

 Text.GetXPYP(XP, YP);
 OffX := (BaseLineXPix + (TextBitmap.Width - BaseLineXPix - RightPadPix) * Single(XP)) * SX;
 if YP < 0 then
  OffY := BaseLinePix * SY
 else
  OffY := (SymbolTopPix + SymbolHeightPix * Single(YP)) * SY;

 AnchorPix := PointF(Selector.XPix(XDot), Selector.YPix(YDot));
 St := Drawer.Canvas.SaveState;
 try
  Drawer.Canvas.MultiplyMatrix(TMatrix.CreateTranslation(AnchorPix.X, AnchorPix.Y));
  Drawer.Canvas.MultiplyMatrix(TMatrix.CreateRotation(Ugol));
  Dst := RectF(-OffX, -OffY, -OffX + W, -OffY + H);
  Drawer.Canvas.DrawBitmap(TextBitmap, RectF(0, 0, TextBitmap.Width, TextBitmap.Height), Dst, 1, True);
 finally
  Drawer.Canvas.RestoreState(St);
 end;
end;


initialization
 AlignStrings:=TStringList.Create;
 With AlignStrings do begin
  Add('влево-основание');
  Add('влево-низ');
  Add('влево-центр');
  Add('влево-верх');
  Add('центр-основание');
  Add('центр-низ');
  Add('центр-центр');
  Add('центр-верх');
  Add('вправо-основание');
  Add('вправо-низ');
  Add('вправо-центр');
  Add('вправо-верх');
 end;
finalization
 AlignStrings.Free;
end.
