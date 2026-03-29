unit dwgtext;

interface
Uses Collect, SysUtils, Polygons,
     Circle_di, FMX.Graphics, newFontScale, Types_Dimano, TwgDraw, newResource,
     newSelector, System.Types, maths_basic;

const
    pointDrawText:boolean=True;

type
  TVarType = (ttString, ttInt, ttFloat, tt_Number, tt_Z, tt_X, tt_Y);
  TVarTypeSet = Set of TVarType;

type
  TFontManager = class(PCollection)
    function AddFont(DC:hDc; fntName:AnsiString; H,W :Double; CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10): integer;
  end;

  { TDWG_Text }

  TDWG_Text = class(TTD)
    FX, FY: single;
    FName: AnsiString;
    FText: AnsiString;
    FFntName:AnsiString;
    FCharSet: Byte;
    FBl :Integer;
    Fit :Integer;
    FUn :Integer;
    FScale:Integer;
    FColor: Integer;
    FFontIndex: integer;
    FAng: single;
    FWidth, FHeight: single;
    {}
    Active:Byte;
    XF,YF,X2,Y2,DX,DY,Ugol1,XFOld,YFOld:Double;
   {}
    FVisible: boolean;
    FBg: boolean;
    FBgColor: Integer;
   {}
    FVarType: TVarType;
    FTextAlignX, FTextAlignY: single;
    oldFontIndex: integer;
    FParams: array[0..127 - 5 - 8 - sizeof(TVarType)] of byte;
   {}
    ShiftX,ShiftY:SmallInt;
   {}
    Selector: TSelector;
    constructor Create(x, y: single; DC:hDc; const txt, fntName:AnsiString; H, W :single;
          CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
    constructor Load(st: TBufStream); override;
    procedure Store(st: TbufStream); override;
    destructor Destroy; override;
//    function GetParams(MXX,MYY,ko,Ugol,X1,Y1:Double;ItsTest:Integer):TFontViewEx;
    function PointIn(x, y: single): double;
    function PointInPoint(x, y: single; var dist: single): integer;
    procedure SetFont(DC:hDc; const fntName:AnsiString; H,W :Double;
          CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
    function YMin:Double;
    function XMin:Double;
    function FH(C:Char):Double;
   {}
    function GetFV: TFontViewEx;
   {}
    Procedure SetGabarites(MRect_:TMRect);override;
    Procedure SetGabaritesBlock(MRect_:TMRect;X,Y,kX,kY,Angle:Double);override;
    Function TextAlign: Byte;
    Procedure GetRect(var L,T,R,B:Single);
   //
    Function isVisible: Boolean;
    Function GetParams(MXX,MYY,ko,Ugol,X1,Y1:Double;ItsTest:Integer):TFontViewEx;
    Procedure Draw32(X,Y:Double;Selector:TSelector;MXX,MYY,ko,Ugol:Double; r, g, b: byte; useclasColor: boolean; X1,Y1:Double;itstest:Integer);
  end;

var FontCol: TFontManager;

implementation uses Writer, FMX.Dialogs, ogcDrawerSkia, System.UITypes, newProcs, System.Skia;
//uses ptmainform;

function ColorToAlphaColor(const C: Integer): TAlphaColor;
var
  R, G, B: Integer;
begin
  R := (C and $FF);
  G := (C shr 8) and $FF;
  B := (C shr 16) and $FF;
  Result := TAlphaColor($FF000000 or (R shl 16) or (G shl 8) or B);
end;


{ TDWG_Text }

constructor TDWG_Text.Create(x, y: single; DC:hDc; const txt, fntName:AnsiString; H,W :single;
                CharSet: Byte; bl1, it1, un1 :Integer; fS:Integer=10);
begin
  FHeight := H;
  FWidth := W;
  FX := x;
  Fy := y;
  FText := txt;
  FCharSet := charset;
  FBl := bl1;
  Fit := it1;
  FUn := un1;
  FScale := fs;
  SetFont(dc, fntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  Active:=0;
end;

destructor TDWG_Text.Destroy;
begin
  inherited;
end;

function TDWG_Text.isVisible: Boolean;
var XMax,YMax,XMin,YMin:Single;
begin
 IsVisible:=True;
 If XF>X2 then begin XMax:=XF;XMin:=X2;end else begin XMax:=X2;XMin:=XF; end;
 If YF>Y2 then begin YMax:=YF;YMin:=Y2;end else begin YMax:=Y2;YMin:=YF; end;
 If GlobalRender then exit;
  With Selector.GRect do
    begin
     If XMax<Left then begin IsVisible:=False;Exit;end;
     If XMin>Right then begin IsVisible:=False;Exit;end;
     If YMin>Top then begin IsVisible:=False;Exit;end;
     If YMax<Bottom then begin IsVisible:=False;Exit;end;
    end;
end;

procedure TDWG_Text.Draw32(X, Y: Double; Selector: TSelector; MXX, MYY, ko,
  Ugol: Double; r, g, b: byte; useclasColor: boolean; X1, Y1: Double;
  itstest: Integer);
var
    xx, yy: integer;
    fv: TFontViewEx;
    Rop:Integer;
    AllPoly1:Array[0..4] of TPoint;
    TmpUg:Double;
    Col:Integer;
    G1:Double;
    Rect:PCollection;
    Anchor: TPointF;
    XP, YP: Double;
    H: Single;
    HBaseline: Single;
    S: string;
    Drawer: TObject;
function SkiaBaselineFromFullHeight(const AFontName: string; const ABold, AItalic: Boolean;
  const AFullHeightPix: Single): Single;
var
  Typeface: ISkTypeface;
  ProbeFont: ISkFont;
  FontStyle: TSkFontStyle;
  Weight: TSkFontWeight;
  Slant: TSkFontSlant;
  LocalFontName: string;
  CutPos: Integer;
  FontFile: string;
  M: TSkFontMetrics;
  AscentAbs: Single;
  Full: Single;
begin
  Result := AFullHeightPix;
  if AFullHeightPix <= 0 then
    Exit;

  LocalFontName := Trim(AFontName);
  if (LocalFontName <> '') and (LocalFontName[1] = '@') then
    LocalFontName := Trim(Copy(LocalFontName, 2, MaxInt));
  CutPos := Pos(',', LocalFontName);
  if CutPos > 0 then
    LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));
  CutPos := Pos('(', LocalFontName);
  if CutPos > 0 then
    LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));

  Weight := TSkFontWeight.Normal;
  if ABold then
    Weight := TSkFontWeight.Bold;
  Slant := TSkFontSlant.Upright;
  if AItalic then
    Slant := TSkFontSlant.Italic;
  FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

  Typeface := nil;
  FontFile := '';
  if LocalFontName <> '' then
    FontFile := GetRegisteredSkiaFontFile(LocalFontName);
  if FontFile <> '' then
    Typeface := TSkTypeface.MakeFromFile(FontFile);
  if (Typeface = nil) and (LocalFontName <> '') then
    Typeface := TSkTypeface.MakeFromName(LocalFontName, FontStyle);

  ProbeFont := TSkFont.Create(Typeface, 100);
  ProbeFont.GetMetrics(M);
  AscentAbs := -M.Ascent;
  Full := (-M.Ascent) + M.Descent;
  if (AscentAbs > 0.01) and (Full > 0.01) then
    Result := AFullHeightPix * (AscentAbs / Full);
end;
function GetS(S:String):string;
var N:Integer;
begin
N:=Pos('\\',S);
If N<>0 then begin
 S[N]:=' ';
 Result:=S;
end else Result:=S;
end;
begin
 If not FVisible then exit;
 if Selector = nil then Exit;
 if FFontIndex = - 1 then Exit;
 if FText = '' then Exit;

 fv := GetParams(MXX, MYY, Ko, Ugol, X1, Y1, itsTest);
 if fv = nil then Exit;

 Drawer := Selector.Drawer;
 if (Drawer <> nil) and (Drawer is TogsDrawerSkia) then
 begin
 // if (not isVisible) and (itsTest <> its_Test) and (itsTest <> its_Printer) then
 //  Exit;

  // For DWG text we interpret FHeight as FULL glyph height (ascent+descent).
  // DrawTextAlignedPix expects Top->Baseline height, so convert.
  H := RealScaleLength(Selector.Drawer, FHeight, Ko);
  if H <= 0 then Exit;
  HBaseline := SkiaBaselineFromFullHeight(string(fv.FontName), fv.Bl <> 0, fv.It <> 0, H);

  Anchor := PointF(Single(XF), Single(YF));
  XP := FTextAlignX;
  YP := FTextAlignY;
  S := GetS(string(FText));

  if useclasColor then
   Col := RGBToCol(r, g, b)
  else
   Col := FColor;

  TogsDrawerSkia(Drawer).DrawTextAlignedPix(
    Anchor,
    S,
    ColorToAlphaColor(Col),
    HBaseline,
    Ugol,
    XP, YP,
    1,
    string(fv.FontName),
    fv.Bl <> 0,
    fv.It <> 0
  );
  Exit;
 end;

  if itsTest <> its_Printer then
   {If (Round(DY * Selector.) < GGraphSet.FFonts) then} exit;
// itsTest:=its_Test;
//   If fText='157.69' then Writeln('CON=',XF:8:3,' ',YF:8:3,' ',X1:8:3,' ',Y1:8:3,' ',Ko);
    if (isVisible) or (itsTest=its_Test) or (ItsTest=its_Printer) then begin
      XX:=Selector.XPix(XF);YY:=Selector.YPix(YF);
     // fBg:=True;
     If (FBg) and (itsTest<>its_Test)   then begin
      TmpUg:=Ugol1;
      If (itsTest=0) then With Selector do begin
       AllPoly1[0].X:=XPix(XF);AllPoly1[0].Y:=YPix(YF);
       AllPoly1[1].X:=XPix(XF+cos(TmpUg)*DX);AllPoly1[1].Y:=YPix(YF-sin(TmpUg)*DX);
       AllPoly1[2].X:=XPix(XF+cos(Pi/2-TmpUg)*DY+cos(TmpUg)*DX);AllPoly1[2].Y:=YPix(YF+sin(Pi/2-TmpUg)*DY-sin(TmpUg)*DX);
       AllPoly1[3].X:=XPix(XF+cos(Pi/2-TmpUg)*DY);AllPoly1[3].Y:=YPix(YF+sin(Pi/2-TmpUg)*DY);
      end;
       AllPoly1[4].X:=AllPoly1[0].X;Allpoly1[4].Y:=Allpoly1[0].Y;
      if fBg then begin
       //Pen:=SelectObject(DC,CreatePen(ps_Solid,0,GlobalSettings.Settings.gsWindowColor{GGraphSet.ColWin}));
       //Br:=SelectObject(DC,CreateSolidBrush(GlobalSettings.Settings.gsWindowColor));
       // Polygon(DC,AllPoly1,5);
       //DeleteObject(SelectObject(DC,Pen));
       //DeleteObject(SelectObject(DC,Br));
      end;
     end;
//      if itsTest=its_Test then SetPixel(dc,XX,YY,clRed);
      if Active=0 then begin
     //  if useclasColor then Bitmap.PenColor:=Color32(RGB(r, g, b)) else Bitmap.PenColor:=Color32(fColor);
      end else  // åñëè àêòèâíûé
     //  Bitmap.PenColor:=Color32(GlobalSettings.Settings.gsSelectPointColor);
     //
      // Col:=Bitmap.PenColor;
     // fv.FillTextGR32(Bitmap, xX, yY, RealScaleLength((FHeight * Myy),Ko)  / fv.Scale,  fang - ugol * 180 / pi, GetS(ftext),Col);
      If fv.Un=1 then begin
       {Pen:=SelectObject(Dc,CreatePen(ps_Solid,Round(Ko*0.1*Gms),Col));
        MoveTo(DC,AllPoly1[2].X,AllPoly1[2].Y);
        LineTo(DC,AllPoly1[3].X,AllPoly1[3].Y);
       DeleteObject(SelectObject(Dc,Pen));
       }
      end;
    If (Active>0) and (ItsTest<>its_Printer) and (ItsTest<>its_Test) then begin
      {Rop:=SetRop2(Dc,R2_Not);
      Pen:=SelectObject(Dc,CreatePen(ps_Solid,0,0));
       //GetText(0,0);
      If Active=1 then begin
       PArcEx2(Dc,XF+cos(Ugol1)*DX,YF-sin(Ugol1)*DX,GGraphSet.fntMarker);
       PKrestEx2(Dc,XF+cos(Pi/2-Ugol1)*DY+cos(Ugol1)*DX,YF+sin(Pi/2-Ugol1)*DY-sin(Ugol1)*DX,GGraphSet.fntMarker);
      end;
      DeleteObject(SelectObject(Dc,Pen));
      SetRop2(Dc,Rop);
     }
    end;
   end;
end;

function TDWG_Text.GetFV: TFontViewEx;
begin
  result := nil;
  if FFontIndex <> - 1 then
    result := fontcol[FFontIndex];
end;

function TDWG_Text.GetParams(MXX, MYY, ko, Ugol, X1,
  Y1: Double;ItsTest:Integer): TFontViewEx;
var GM:Double;FDx,fDy:Double;ko2:Double;
    dd1, dd2: double;
    R1, R2: Single;
  function GetS(const S: string): string;
  var
    N: Integer;
    T: string;
  begin
    T := S;
    N := Pos('\\', T);
    if N <> 0 then
    begin
      T[N] := ' ';
      Result := T;
    end
    else
      Result := T;
  end;

  procedure MeasureTextSkia(const AText: string; const AFontName: string;
    const ABold, AItalic: Boolean; const AFontSizePix: Single;
    out ADXPix, ADYPix: Double);
  var
    Paint: ISkPaint;
    Typeface: ISkTypeface;
    Font: ISkFont;
    ProbeFont: ISkFont;
    FontStyle: TSkFontStyle;
    Weight: TSkFontWeight;
    Slant: TSkFontSlant;
    LocalFontName: string;
    CutPos: Integer;
    FontFile: string;
    ProbeMetrics: TSkFontMetrics;
    Metrics: TSkFontMetrics;
    Bounds: TRectF;
    ProbeSize: Single;
    AscentRatio: Single;
    Oversample: Single;
    EffectiveFontSize: Single;
    DrawerObj: TObject;
  begin
    ADXPix := 0;
    ADYPix := 0;

    if AText = '' then
      Exit;

    Oversample := 1;
    DrawerObj := Selector.Drawer;
    if (DrawerObj <> nil) and (DrawerObj is TogsDrawerSkia) and TogsDrawerSkia(DrawerObj).UseWorldCoords then
      Oversample := 10;

    Paint := TSkPaint.Create;
    Paint.AntiAlias := True;

    LocalFontName := Trim(AFontName);
    if (LocalFontName <> '') and (LocalFontName[1] = '@') then
      LocalFontName := Trim(Copy(LocalFontName, 2, MaxInt));
    CutPos := Pos(',', LocalFontName);
    if CutPos > 0 then
      LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));
    CutPos := Pos('(', LocalFontName);
    if CutPos > 0 then
      LocalFontName := Trim(Copy(LocalFontName, 1, CutPos - 1));

    Weight := TSkFontWeight.Normal;
    if ABold then
      Weight := TSkFontWeight.Bold;
    Slant := TSkFontSlant.Upright;
    if AItalic then
      Slant := TSkFontSlant.Italic;
    FontStyle := TSkFontStyle.Create(Weight, TSkFontWidth.Normal, Slant);

    Typeface := nil;
    FontFile := '';
    if LocalFontName <> '' then
      FontFile := GetRegisteredSkiaFontFile(LocalFontName);
    if FontFile <> '' then
      Typeface := TSkTypeface.MakeFromFile(FontFile);
    if (Typeface = nil) and (LocalFontName <> '') then
      Typeface := TSkTypeface.MakeFromName(LocalFontName, FontStyle);

    ProbeSize := 100;
    ProbeFont := TSkFont.Create(Typeface, ProbeSize);
    ProbeFont.GetMetrics(ProbeMetrics);
    if (-ProbeMetrics.Ascent) > 0.01 then
      AscentRatio := (-ProbeMetrics.Ascent) / ProbeSize
    else
      AscentRatio := 1;

    EffectiveFontSize := (AFontSizePix / AscentRatio) * Oversample;
    Font := TSkFont.Create(Typeface, EffectiveFontSize);
    Font.GetMetrics(Metrics);
    Font.MeasureText(AText, Bounds, Paint);

    ADXPix := Bounds.Width / Oversample;
    ADYPix := (-Metrics.Ascent) / Oversample;
  end;
begin
 Result:=TFontViewEx(fontcol[FFontIndex]);
// Writeln('FI=',FFontIndex,' ',Result.FontName);
 if Ko=0 then Exit;
 Result.SetParams(fheight, fwidth);
 If itsTest = its_Test then
  GM:=Result.Scale/(Ko*fHeight) else
  GM:=Result.Scale/(RealScaleLength(Selector.ogsDrawer, fHeight,Ko)*Myy);
{ If Ko<0 then begin
  GM:=Result.Scale/FHeight;
  Ko:=Abs(Ko);
 end;
}
// Writeln('KoefText=',Ko,' ',fText);
 GM:=Result.Scale/(RealScaleLength(Selector.Drawer, fHeight, Ko)*Myy);

 if (Selector.Drawer <> nil) and (Selector.Drawer is TogsDrawerSkia) then
 begin
   MeasureTextSkia(GetS(string(fText)), string(Result.FontName), Result.Bl <> 0, Result.It <> 0,
     RealScaleLength(Selector.Drawer, fHeight, Ko), fDX, fDY);
 end
 else
   Result.GetTextLen(0,0,1/GM,0,fText, fDX, fDY);
 Dx:=fDx * GM;Dy:=fDy * GM;
 If (itsTest=0){or(itsTest=its_Test)} then begin DX:=Selector.GeoDist(fDX);DY:=Selector.GeoDist(fDY); end else
{!!!}
 If itsTest=its_Printer then begin
 { If Ko>0 then begin
   ko2:=Ko/GPrn.Mas*1000;
   DX:=PrnXGeoRasst(fDX*ko2/ko);DY:=PrnYGeoRasst(fDY*ko2/ko);
  end else begin
   ko2:=Abs(Ko)/GPrn.Mas*1000;
   DX:=PrnXGeoRasst(fDX*ko2/Abs(ko));DY:=PrnYGeoRasst(fDY*ko2/Abs(ko));
  end;}
 end;
 If (Ko>0)or(ShiftX=0) then begin
  R1 := RealScaleLength(Selector.Drawer,fx,ko);
  R2 := RealScaleLength(Selector.Drawer,fx,ko);
  XF:=X1+(RealScaleLength(Selector.Drawer,fx,ko)*cos(Ugol)-RealScaleLength(Selector.Drawer,fy,ko)*sin(Ugol));
  YF:=Y1+(RealScaleLength(Selector.Drawer,fx,ko)*sin(Ugol)+RealScaleLength(Selector.Drawer,fy,ko)*cos(Ugol));
//
 XFOld:=XF;YFOld:=YF;
 double_transform_sys_coords2D( -FTextAlignX*DX, FTextAlignY*DY,
                                  fang * pi / 180,
                                  RealScaleLength(Selector.Drawer,fx,KO), RealScaleLength(Selector.Drawer,-fy,KO),  -ugol, 0, 0, dd1, dd2);
 XF:=X1+dd1;
 YF:=Y1-dd2;
// Writeln(X1:8:2,' ',Y1:8:2,' ',dd1:8:2,'' ,dd2:8:2);
 Ugol1:=fAng/180*Pi-(Ugol);
 X2:=XF+cos(Pi/2-Ugol1)*DY+cos(Ugol1)*DX;
 Y2:=YF+sin(Pi/2-Ugol1)*DY-sin(Ugol1)*DX;
// MoveToEx(XF,YF);LineToEx(X2,YF);PLineTo(X2,Y2);PLineTo(XF,Y2);PLineTo(XF,YF);PLineTo(X2,Y2);
 end else begin// If Ko<0
//  Writeln('ShiftGetText=',ShiftX,' ',ShiftY);
//  XF:=X1+(RealScaleLength(fx,0)*cos(Ugol)-RealScaleLength(fy,0)*sin(Ugol));
//  YF:=Y1+(RealScaleLength(fx,0)*sin(Ugol)+RealScaleLength(fy,0)*cos(Ugol));
 //
  XFOld:=XF;YFOld:=YF;
  double_transform_sys_coords2D( -FTextAlignX*DX, FTextAlignY*DY,
                                  fang * pi / 180,
                                  RealScaleLength(Selector.Drawer,ShiftX,0), RealScaleLength(Selector.Drawer,-ShiftY,0),  -ugol, 0, 0, dd1, dd2);
// Writeln(dd1:8:2,' ',dd2:8:2,' ',RealScaleLength(ShiftX,0));
 XF:=X1+dd1;
 YF:=Y1-dd2;
// Writeln('ShiftXY=',ShiftX,' ',ShiftY);
 // Writeln(X1:8:2,' ',Y1:8:2,' ',dd1:8:2,'' ,dd2:8:2);
  Ugol1:=fAng/180*Pi-(Ugol);
  X2:=XF+cos(Pi/2-Ugol1)*DY+cos(Ugol1)*DX;
  Y2:=YF+sin(Pi/2-Ugol1)*DY-sin(Ugol1)*DX;
 // MoveToEx(XF,YF);LineToEx(X2,YF);PLineTo(X2,Y2);PLineTo(XF,Y2);PLineTo(XF,YF);PLineTo(X2,Y2);
 end;
end;

procedure TDWG_Text.GetRect(var L, T, R, B: Single);
var TmpUg:Double;XMax,YMax,XMin,YMin:Double;P:PCollection;
    I:Integer;
begin
try
  TmpUg:=Ugol1;
  P:=PCollection.Create(5);

//  GetParams(1,1,0.5,
  P.Insert(TDot1.Create(FX,FY));
  P.Insert(TDot1.Create(FX+cos(TmpUg)*DX,FY-sin(TmpUg)*DX));
  P.Insert(TDot1.Create(FX+cos(Pi/2-TmpUg)*DY+cos(TmpUg)*DX,FY+sin(Pi/2-TmpUg)*DY-sin(TmpUg)*DX));
  P.Insert(TDot1.Create(FX+cos(Pi/2-TmpUg)*DY,FY+sin(Pi/2-TmpUg)*DY));
  P.Insert(TDot1.Create(FX,FY));
  XMax:=-1000000000;XMin:=10000000000;YMin:=100000000000;YMax:=-10000000000;
 // Writeln('---------------------');
   For I:=0 to P.Count-1 do With TDot1(P[I]) do begin
 //   Writeln(X:8:2,' ',Y:8:2);
    If X>XMax then XMax:=X;
    If X<XMin then XMin:=X;
    If Y>YMax then YMax:=Y;
    If Y<YMin then YMin:=Y;
 //   If I =0 then PMoveTo(X,Y) else PLineTo(X,Y);
 //   Writeln('XMax=',XMAx:8:2,' ',XMin:8:2);
   end;
 // Writeln('---------------------');
  L:=XMin;R:=XMax;T:=YMax;B:=YMin;
  P.Free;
 except end;
end;

constructor TDWG_Text.Load(st: TBufStream);
var Dc:hDc;
begin
 Selector := st.Selector;
  st.read(FX, sizeof(fx));
  st.read(Fy, sizeof(fx));
  st.read(FColor, sizeof(FColor));
  st.read(FFontindex, sizeof(FFontindex));
  OldFontIndex:=FFontIndex;
  st.read(FAng, sizeof(FAng));
  st.read(FWidth, sizeof(FWidth));
  st.read(FHeight, sizeof(FHeight));
  FName := st.readString;
  FText := st.readString;
  WriteS(['Load.dwgText=',FName,FText]);
  st.read(fcharset, sizeof(fcharset));
  st.read(fbl, sizeof(fbl));
  st.read(fit, sizeof(fit));
  st.read(fun, sizeof(fun));
  st.read(fscale, sizeof(fscale));
  ffntname := st.ReadString;
  Dc:=0;
  FFontIndex := -1;
   SetFont(Dc, ffntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  Active:=0;
  st.read(fvisible, sizeof(fvisible));
  st.read(fBg, sizeof(FBg));
  st.read(fBgColor, sizeof(FBgColor));
 {}
  st.read(FVarType, sizeof(FVarType));
  st.read(FTextAlignX, sizeof(FTextAlignX));
  st.read(FTextAlignY, sizeof(FTextAlignY));
  st.read(FParams, sizeof(FParams));
//  isfirstdraw := true;
end;

procedure TDWG_Text.Store(st: TbufStream);
var fv: TFontViewEx;
    i: integer;
begin
  st.Write(FX, sizeof(fx));
  st.Write(Fy, sizeof(fx));
  st.Write(FColor, sizeof(FColor));
  st.Write(FFontindex, sizeof(FFontindex));
  st.Write(FAng, sizeof(FAng));
  st.Write(FWidth, sizeof(FWidth));
  st.Write(FHeight, sizeof(FHeight));
  st.WriteString(FName);
  st.WriteString(FText);
  st.write(fcharset, sizeof(fcharset));
  st.write(fbl, sizeof(fbl));
  st.write(fit, sizeof(fit));
  st.write(fun, sizeof(fun));
  st.write(fscale, sizeof(fscale));
  st.writeString(FFntName);
//  fvisible := true;
  st.write(fvisible, sizeof(fvisible));
  st.write(fbg, sizeof(fbg));
  st.write(fbgcolor, sizeof(fbgcolor));
  st.write(FVarType, sizeof(FVarType));
  st.write(FTextAlignX, sizeof(FTextAlignX));
  st.write(FTextAlignY, sizeof(FTextAlignY));
  st.write(FParams, sizeof(FParams));
end;

function TDWG_Text.PointIn(x, y: single): double;
begin
  result := sqrt(sqr(x - fx) + sqr(y - fy));
end;

function TDWG_Text.PointInPoint(x, y: single; var dist: single): integer;
begin
  result := - 1;
  dist := 10000000;
end;

procedure TDWG_Text.SetFont(DC: hDc; const fntName: AnsiString; H, W: Double;
 CharSet: Byte; bl1, it1, un1: Integer; fS: Integer);
begin
  FHeight := h;
  FWidth := w;
  ffntname := FntName;
  FCharSet := char_set;
  FBl := bl1;
  Fit := it1;
  FUn := un1;
  FScale := 500;
  FFontIndex := fontcol.AddFont(dc, ffntName, FHeight, FWidth, fCharSet, fbl, fit, fun, fscale);
  OldFontIndex:=FFontIndex;
end;

function TDWG_Text.FH(C: Char): Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FHeight*F.RH(C)/F.Scale;
end;

function TDWG_Text.YMin: Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FY+FY*F.YMin('W')/F.Scale;
end;

function TDWG_Text.XMin: Double;
var F:TFontViewEx;
begin
 Result:=0;
 if FFontIndex=-1 then Exit;
 F:=fontCol[FFontIndex];
  Result:=FX+FX*F.XMin('W')/F.Scale;
end;

procedure TDWG_Text.SetGabarites(MRect_: TMRect);
begin
 ShowMessage('1');
end;

procedure TDWG_Text.SetGabaritesBlock(MRect_: TMRect; X, Y, kX, kY,
 Angle: Double);
begin
 ShowMessage('2');
end;

function TDWG_Text.TextAlign: Byte;
begin
 If (fTextAlignX = 0) and (fTextAlignY = 0) then Result:= 1 else
 If (fTextAlignX = 0) and (fTextAlignY = 0.5) then Result:= 2 else
 If (fTextAlignX = 0) and (fTextAlignY = 1) then Result:= 3 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 0) then Result:= 5 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 0.5) then Result:= 6 else
 If (fTextAlignX = 0.5) and (fTextAlignY = 1) then Result:= 7 else
 If (fTextAlignX = 1) and (fTextAlignY = 0) then Result:= 9 else
 If (fTextAlignX = 1) and (fTextAlignY = 0.5) then Result:= 10 else
 If (fTextAlignX = 1) and (fTextAlignY = 1) then Result:= 11;
{ Add('влево-основание');
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
}
end;

{ TFontManager }

function TFontManager.AddFont(DC: hDc; fntName: AnsiString; H, W: Double;
  CharSet: Byte; bl1, it1, un1, fS: Integer): integer;
var I: Integer;
    fv: TFontViewEx;
begin
 Fs:=350;
// charSet:=Default_CharSet;  FMX
  result := -1;
  for i := 0 to count - 1 do
  begin
    fv := items[i];
    if fv.isEqual(fntname, charset, bl1, it1, un1) then
    begin
      result := i;
      exit;
    end;
  end;
  fv := TFontViewEx.Create(dc, fntName, h, w, CharSet, bl1, it1, un1, fs);
 // Writeln('Add=',FntName,' ',bl1,' ',It1,' ',Un1,' ',Count);
  Insert(fv);
  fv.Index:=Count-1;
  result := count - 1;
end;

initialization
  FontCol := TFontManager.Create(1);
finalization
  FontCol.free;
end.
