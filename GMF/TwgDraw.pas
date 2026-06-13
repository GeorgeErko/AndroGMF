{$N+}
Unit TwgDraw;
 Interface
  Uses FMX.Objects, FMX.Graphics, System.Types, Collect, newConsts, newResource, Classes, newFontScale, newSelector;

 { Процедуры линейного преобразования координат }

 const
  its_test=12345;
  its_printer=12346;
  its_Dxf=12347;

type
  TXY = record
   X,Y:Double;
  end;

var
  brushStyle:Byte;
  brushColor:Integer;
  penStyle,penWidth:byte;
  penColor:Integer;
  xyArray:Array[0..50000] of TXY;
  sSect:TShortSect;

type
  TRegion=Array[1..100000] of TPoint;
  TLRG=Array[1..1000] of TPoint;

var LotRgn:TRegion;

 Type
   PTD=^TTD;
    TTD=class(TTwgObject)
//      Owner    :Pointer;
       Constructor Create(O:Pointer);
     // Селектор + габариты
       Function  GetSelector:TSelector;virtual;abstract;
       Procedure SetSelector(S:TSelector);virtual;abstract;
       Property Selector:TSelector read GetSelector write SetSelector;
       Function  GetGabarites(MRect_:TMRect; X, Y, kX, kY, Angle:Double) : Integer; virtual; abstract; // габариты с учетом поворота-масштабирования
       Procedure SetGabarites(MRect_:TMRect);virtual;abstract;
       Procedure SetGabaritesBlock(MRect_:TMRect; X, Y, kX, kY, Angle:Double);virtual;abstract;
     // Процедура захвата примитива во фрагмент; возвращается набор точек и подписей
       Function GetPrim(R:TSect;Col:PCollection):Boolean;virtual;abstract;
       Function GetHint(P:Pointer=nil):AnsiString;virtual;abstract;
       Function SetProperty(propName:AnsiString;propValue:AnsiString;Obj:TTD = nil):Boolean;virtual;abstract;
       Function GetProperty(propName:AnsiString):AnsiString;virtual;abstract;
       Procedure GetPropMerge(Obj:TTD;propNames,propValues,propTypes:TStrings);virtual;abstract;
       Procedure GetObjectProps(propNames,propValues,propTypes:TStrings;Data:Pointer=nil);virtual;abstract;
       Function UseProperty(propName:AnsiString):boolean;virtual;abstract;
       Procedure DeleteProperty(propName:AnsiString);virtual;abstract;
       Procedure AddProperty(propName:AnsiString);virtual;abstract;
       Function propIndex(Index:Integer):AnsiString;virtual;abstract;
       Function GetPropValue(propName:AnsiString):Pointer;virtual;abstract;
     //
       Function GetLayer:TResource;virtual;abstract;
       Procedure SetLayer(PR:TResource);virtual;abstract;
       Procedure MergeProperties(Obj:TTD;Flag:Boolean);virtual;
     //
       Procedure Move(Dx,Dy:Double);virtual;
       Procedure Rotate(XX,YY,Angle:Double);virtual;
       Procedure RotationPoints(Col:PCollection);virtual;
       Procedure ApplyInternalProps(Obj:TTD);virtual;
     //
       Function ResetParams(ParamID: Integer;Params: Pointer):boolean;virtual;
       Procedure SetActive(Active:Byte);virtual;
       Procedure ChangeXYKoef(XK,YK:Double);virtual;
       Function  deVisible(XB, YB, Ugol,XKoef,YKoef: Double;var Sect:TShortSect):Boolean;virtual;abstract;
     //
       Procedure binDrawPen(Buf:TMemoryStream);virtual;
       Procedure binDrawBrush(Buf:TMemoryStream);virtual;
       Procedure binLoadSect(Buf:TMemoryStream);virtual;
     //
       Function GetDrawerObject: TObject; virtual; abstract;
       Procedure SetDrawerObject(Obj: TObject); virtual; abstract;
       Property DrawerObject: TObject read GetDrawerObject write SetDrawerObject;
    end;


Implementation uses Intervals, Types_Dimano, Polygons;

{-----------------------------------------------------------------}
{ Я наверное полюбил бы ее                                        }
{-----------------------------------------------------------------}
procedure TTD.ApplyInternalProps(Obj: TTD);
begin
 //
end;

procedure TTD.binDrawBrush(Buf: TMemoryStream);
var procNum:byte;
begin
 procNum:=2;
 Buf.Read(brushStyle,SizeOf(brushStyle));
 Buf.Read(brushColor,SizeOf(brushColor));
end;

procedure TTD.binDrawPen(Buf: TMemoryStream);
var procNum:byte;
begin
 procNum:=1;
 Buf.Read(penStyle,SizeOf(penStyle));
 Buf.Read(penWidth,SizeOf(penWidth));
 Buf.Read(penColor,SizeOf(penColor));
end;

procedure TTD.binLoadSect(Buf: TMemoryStream);
begin
 Buf.Read(sSect,SizeOf(TSect));
end;

procedure TTD.ChangeXYKoef(XK, YK: Double);
begin
//
end;

Constructor TTD.Create;
 begin
//   Owner:=O;
 end;

procedure TTD.MergeProperties(Obj: TTD;Flag:Boolean);
var I:Integer;propNames,propValues,propTypes:TStrings;
begin
 If not Flag then Self.SetLayer(Obj.GetLayer);
 propNames:=TStringList.Create;propValues:=TStringList.Create;propTypes:=TStringList.Create;
 Obj.GetObjectProps(propNames,propValues,propTypes);
 If not Flag then GetPropMerge(Obj,propNames,propValues,propTypes);
 For I:=0 to propNames.Count-1 do begin
  If Flag then begin If ((Pos('*',propNames[I])<>0) or (Pos('##',propNames[I])<>0)) then
   SetProperty(propNames[I],propValues[I],Obj);end else
   SetProperty(propNames[I],propValues[I],Obj);
 end;
 ApplyInternalProps(Obj);
 propNames.Free;propValues.Free;propTypes.Free;
end;

procedure TTD.Move(Dx, Dy: Double);
begin
//
end;

function TTD.ResetParams(ParamID: Integer;Params: Pointer): boolean;
begin
 Result:=False;
end;

procedure TTD.Rotate(XX, YY, Angle: Double);
begin
//
end;

procedure TTD.RotationPoints(Col: PCollection);
begin
//
end;

procedure TTD.SetActive(Active: Byte);
begin
//
end;


initialization
// Polygon32:=TPolygon32.Create;Polygon32.Antialiased:=False;
finalization
// Polygon32.Free;
end.
