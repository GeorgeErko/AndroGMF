unit EcDot2;

interface uses Collect, newFontScale, newSelector, TwgDraw, Classes,
               SysUtils, EcDot, ogcBasic;

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

implementation uses Types_Dimano, Polygons, TextManager, Maths_Basic, userObject,
                    newProcs, newSettings, newForm0, newProperties, newConsts,
                    Writer;

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

procedure TText.SetIt(var bl, it, un, ou: byte);
begin
 bl:=FontView.bl;
 it:=FontView.it;
 un:=FontView.un;
 ou:=FontView.ov;
end;


{ TDotText }

constructor TDotText.Create(X,Y:Double;Text_:AnsiString;H:Single;Color:Integer;Align_:Byte;Ugol_:Single;fontView_:TFontViewEx);
begin
 inherited Create(X,Y,0);
 Ugol:=Ugol_;
 Text:=TText.Create(Text_,H,Align_,Color,fontView_);
 XKoef:=1;
 What:=1;
 GyperLink:=TStringList.Create;
end;

constructor TDotText.CreateAsPoint_(P: TPointDot);
begin
 inherited;
 Text:=TText.CreateAs(TDotText(P).Text);
 GyperLink:=TStringList.Create;
 GyperLink.Text:=TDotText(P).GyperLink.Text;
 XKoef:=TDotText(P).XKoef;
 What:=TDotText(P).What;
 Ugol:=TDotText(P).Ugol;
end;

constructor TDotText.CreateAsPointDot_(P: TPointDot; AddCollections: Boolean;CreateTreesCopy:boolean = True);
begin
 inherited;
 Text:=TText.CreateAs(TDotText(P).Text);
 GyperLink:=TStringList.Create;
 GyperLink.Text:=TDotText(P).GyperLink.Text;
 XKoef:=TDotText(P).XKoef;
 What:=TDotText(P).What;
 Ugol:=TDotText(P).Ugol;
end;

destructor TDotText.Destroy;
begin
 inherited;
 Text.Free;
 GyperLink.Free;
end;

procedure TDotText.Draw32(Drawer: TogsDrawer; PntZnk: TSortedCollection;
  FontViewEx: TFontManagerEx; AlwaysShowAttr: Boolean);
begin
//
end;

procedure TDotText.Store(Stream: TBufStream);
begin
 inherited;
 Stream.Put(Text);
 Stream.WriteString(GyperLink.Text);
end;

constructor TDotText.Load(Stream: TBufStream);
var Index:Integer;
begin
 inherited;
 Text:=TText(Stream.Get);
 GyperLink:=TStringList.Create;
 GyperLink.Text:=Stream.ReadString;
end;

function TDotText.ResetParams(ParamID:Integer;Params:Pointer):boolean;
begin
 inherited ResetParams(ParamID,Params);
 What:=1;
 case ParamID of
  1:begin
     If Text.fontIndex>TFontManagerEx(Params).Count-1 then begin
      Text.fontIndex:=0;
     end;
     Text.FontView:=TFontManagerEx(Params)[Text.fontIndex];
     Result:=True;
    end;                                                
 end;
end;

function TDotText.GetDistance(X, Y: Double; Flag: Boolean): Double;
var P:PCollection;I:Integer;
begin             
 Result:=100000000;   
{ If (X<textSect.Left) or (Y<textSect.Bottom) or (X>textSect.Right) or (Y>textSect.Top) then begin
  exit;
 end;}
 P:=Text.GetRotateRect(XDot,YDot,XKoef,Ugol,False);
// For I:=0 to P.Count-1 do If I=0 then PMoveTo(TDot1(P[I]).X,TDot1(P[I]).Y) else PLineTo(TDot1(P[I]).X,TDot1(P[I]).Y);
  If Point_and_Polygon(X,Y,P)>-1 then begin
   If Text.GetTextPoint(X,Y,XDot,YDot,XKoef,Ugol) then Result:=0 else Result:=-1;
  end else Result:=100000000;
//  WRiteln(Result);
 P.Free;
end;

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
  Result:=True;
 end else
 If propName = 'Размер' then begin
  try Text.Height:=GStrToFloat(propValue);except end;
  Result:=True;
 end else
 If propName = 'Стиль' then begin
  try Style:=StrToInt(propValue);except exit;end;
   FUn := ord((Style and tpUnderline) <> 0);
   FBl := ord((Style and tpBold) <> 0);
   FIt := ord((Style and tpItalic) <> 0);
  Index:=Text.fontView.FontColEx.AddFont(0{GCanvas.Handle},Text.fontView.FontName,0,0,Text.fontView.CharSet,FBl,FIt,FUn,Text.fontView.Scale);
  Text.fontView:=Text.fontView.FontColEx[Index];
  Result:=True;
 end else
 If PropName = 'Прозрачность' then begin
  //S:=GetProperty('Прозрачность');
  //Text.Transparent:=True;
  S:=propValue;
  If S = 'Нет' then Text.Transparent:=False else
  If S = 'Да' then Text.Transparent:=True else
  If S = byLayer then Text.TransParent:=ClassHandle.GlassFon;
  Result:=True;
 end else
 If PropName = 'Текст' then begin
  If propValue=byLayer then exit;
  Text.Text:=propValue;
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
var P:PCollection;M:TMRect;I:Integer;S:TSect;D:Double;
begin
 If Text.FontView = nil then begin
  Result := inherited GetSect;
  exit;
 end;
  Result := inherited GetSect;
  WriteIn(['TDotText.Getsect =', Result.Left, Result.Top]);
  exit;
 //
 M:=TMRect.Create;
 P:=Text.GetRotateRect(XDot,YDot,XKoef,Ugol,False);
  For I:=0 to P.Count-1 do M.Insert(TDot1(P[I]).X,TDot1(P[I]).Y);
 Result:=M.Sect;D:=Result.Top;Result.Top:=Result.Bottom;Result.Bottom:=D;
 M.Free;
 P.Free;
end;

procedure TDotText.ChangeXYKoef(XK, YK: Double);
begin
 XKoef:=XK;Text.Height:=Text.Height*YK;
end;

procedure TDotText.SetGabarites(MRect_: TMRect);
begin
//
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
