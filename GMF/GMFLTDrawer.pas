unit GMFLTDrawer;

interface uses Classes, SysUtils, Lines3, circle_di, Collect,
               newSelector, intervals, maths_basic,
               FMX.Graphics, ogcBasic;

const
// игнорировать рисование оевой/левой/правой линии
// при рисовании двойной комплексной линии
 gmfIgnoreLineDrawing = $FF;

// Рисование сложных типов линий в режиме совместимости с форматом GMF
// в качестве обертки старого объекта TGeoLine с параметрами TLineStruct
// используется TgmfLineType
// Необходимо выполнить перенос TGeoLine -> TgmfLineType (см. GMFGeometry)
procedure DrawGeoLine(Drawer: TogsDrawer; GL: TGeoLine; ogsLine: PCollection;
                      Ko: Single; LineWidth: Single; Dx: Single; Selected: Boolean; Color: Integer);

implementation uses Lib, newProcs, Polygons, ogcMathUtils, Writer, types_dimano,
                    newSettings;

{ Локальные проуедуры модуля --------------------------------------------- }

Function Atan2(dx, dy: double): double;
var u: double;
begin
if dx = 0 then begin
	 if dy > 0 then Atan2 := Pi/2 else Atan2 := Pi*3/2;
         exit;
	end;
if dy = 0 then begin
	 if dx > 0 then Atan2 := 0 else Atan2 := Pi;
         exit;
	end;
u:=arctan(dy/dx);
Atan2 := U;
if (dx < 0) and (dy < 0) then Atan2 := U + Pi;
if (dx < 0) and (dy > 0) then Atan2 := U + Pi;
if (dx > 0) and (dy < 0) then Atan2 := U + 2*Pi;
end;

Function CutLine(Coord: PCollection; dNext, dPrev: Double): PCollection;
var I, J, K:Integer;
    D, D1: TDot1;
    X, Y: Double;
    LineLength, AllLength, Angle:Double;
begin
 Result:=nil;
 K:=-1;AllLength:=0;
 For I:=0 to Coord.Count-2 do begin
   D:=Coord.List[I];D1:=Coord.List[I+1];
    LineLength:=Distance(D.X,D.Y,D1.X,D1.Y);
    AllLength:=AllLength+LineLength;
    if K=-1 then begin
     If dNext>LineLength then begin
       dNext:=dNext-LineLength;
     end else begin K:=I;Angle:=Atan2(D1.X-D.X,D1.Y-D.Y);end;
    end;// if K=-1
 end;
  if (K<>-1) and (dNext+dPrev<AllLength) then begin
   Result:=PCollection.Create(Coord.Count);
   // получив точку вставляем все остальные в коллекцию
   For I:=K to Coord.Count-1 do Result.Insert(TDot1.CreateAs(Coord[I]));
   D:=Result.List[0];
   D.X:=D.X+dNext*cos(Angle);D.Y:=D.Y+dNext*sin(Angle);
    For I:=Result.Count-1 downto 1 do begin
     D:=Result.List[I];D1:=Result.List[I-1];
     LineLength:=Distance(D.X,D.Y,D1.X,D1.Y);
     if dPrev>LineLength then begin
      dPrev:=dPrev-LineLength;Result.AtDelete(I); end else
      begin Angle:=Atan2(D1.X-D.X,D1.Y-D.Y);break;end;
    end;
   D:=Result.List[Result.List.Count-1];
   D.X:=D.X+dPrev*cos(Angle);D.Y:=D.Y+dPrev*sin(Angle);
  end;
end;

Function LenPoints(Points: PCollection): Double;
var I:Integer;D,D1:TDot1;
begin
 Result:=0;
 For I:=0 to Points.Count-2 do
  begin
   D:=Points[I];D1:=Points[I+1];
   Result:=Result+Distance(D.X,D.Y,D1.X,D1.Y);
  end;
end;

Procedure DrawLine(Drawer: TogsDrawer; Coord1: PCollection; PS: TLineStruct;
                   Ko: Double; Dx: Double; rOfs: Single);
var I,J,K:Integer;D1,D2:TDot1;
    Angle:Double; // дир. угол текущего отрезка
    dNext,dPrev,dDop{поперечное смещение}:Double; // остаток длины переходящий в след отрезок
    X1,Y1,X2,Y2:Double; // координаты штриха
    LineLength,PolyLength:Double; // длина линии и полилинии
    ScanLength:Double; // длина от начала линии до рассчитанной точки штриха
    Scan,Scan1,Space:Double; // длина штриха и пробела
    DrawingScan:boolean; // дорисовывать окончание
    BeginDrawing:boolean;
    Coord,Coord2:PCollection;
    B:Boolean;
    CLines:Integer;
    TS: TDateTime;
    Counter: Integer;
    ogsCoord: TogsCollection;
begin
 Counter := 0;
// dNext:=PS.Param3*Ko;dPrev:=PS.Param3*Ko;B:=False;
// TS := GetTickCount;
 dNext := RealScaleLength(Drawer, PS.Param3, Ko);
 dPrev := RealScaleLength(Drawer, PS.Param3, Ko);
 dDop  := RealScaleLength(Drawer, PS.lVOrign, Ko);
 B:=False;
 If dNext+dPrev<>0 then begin // отсечение ломаной
  Coord:=CutLine(Coord1,dNext,dPrev);
  B:=True;
 end else
 If (PS.DRawState and ls_dblLine=0) and (dDop<>0) then begin
  Coord:=CutLine(Coord1,0,dDop);
  B:=True;
 end else Coord:=Coord1;
  // процедура отрисовки одинарной линии
  if Coord<>nil then
   begin
    If PS.DrawState and ls_solid1 <> 0 then
     begin // рисуем сплошную линию с отсечением
      ogsCoord := TogsCollection.Create;
       For I:=0 to Coord.Count - 1 do With TDot1(Coord.List[I]) do
        ogsCoord.Add(TlDot.Create(X, Y));
       Drawer.DrawPolyLine(ogsCoord, False);
      ogsCoord.Free;
     { For I:=0 to Coord.Count-2 do
       With TDot1(Coord.List[I]) do
        begin
         D1:=Coord.List[I+1];
         Drawer.DrawLine(X,Y,D1.X,D1.Y);
        end;}
     end else
     begin // рисуем пунктирную линию с отсечением штрихов
      // просчитываем все начальные и конечные точки пунктирной линии
      Scan:=RealScaleLength(Drawer, PS.Param2, Ko);
      Space:=RealScaleLength(Drawer, PS.Param0 - PS.Param2, Ko);
      K:=0;
      If Dx<>0 then begin // учитываем смещение вдоль ломаной
        if Dx>0 then While Dx>0 do Dx:=Dx-(Scan+Space) else // вычисление отрицательного смещения
        If Dx<0 then While Dx+(Scan+Space)<0 do Dx:=Dx+(Scan+Space);
        if Dx<>0 then begin // продолжаем, если смещение не <> 0
         Dx:=Dx+(Scan); // смещение со штрихом
         If Dx>0 then begin // рисуем штрих
         {}
           For K:=0 to Coord.List.Count-2 do
            With TDot1(Coord.List[K]) do begin
              D1:=Coord.List[K+1];
              LineLength:=Distance(X,Y,D1.X,D1.Y);
               If Dx>LineLength then begin
                 Dx:=Dx-LineLength;
                 Drawer.DrawLine(D1.X,D1.Y,X,Y);
                end else break;
             end;
          {}
         if Coord.List.Count>K+1 then begin
          D2:=Coord.List[K];D1:=Coord.List[K+1];
          Angle:=Atan2(D1.X-D2.X,D1.Y-D2.Y);
          X1:=D2.X+Dx*cos(Angle);Y1:=D2.Y+Dx*sin(Angle);
          Drawer.DrawLine(D2.X,D2.Y,X1,Y1);
         end;
          Dx:=Dx+Space;
         end else Dx:=Dx+Space;
        end;
       end;
      DrawingScan:=False;
      dNext:=Dx;
      CLines:=0;
      For I:=K to Coord.List.Count-2 do
       With TDot1(Coord.List[I]) do
         begin
          D1:=Coord.List[I+1];
          LineLength:=Distance(X,Y,D1.X,D1.Y);
          if (dNext>LineLength) then begin
            if DrawingScan then Drawer.DrawLine(X,Y,D1.X,D1.Y);
            dNext:=dNext-LineLength;continue;
          end;
          Angle:=Atan2(D1.X-X,D1.Y-Y);// считаем дир угол в радианах
          X1:=X+dNext*cos(Angle);Y1:=Y+dNext*sin(Angle);
          if DrawingScan then begin // дорисовка окончания
           Inc(CLines);
           Drawer.DrawLine(X,Y,X1,Y1);DrawingScan:=False;
          end else DrawingScan:=True;
          X2:=X1;Y2:=Y1;
          // рисуем штрихи в пределах линии с переносом на след. линию
          Counter :=0;
           While True do
            begin // получаем вторую точку штриха
             Inc(Counter);
             If DrawingScan then begin
              Scan1:=Scan;
              If BeginDrawing then begin {if dNext=0 then Scan1:=Scan/2;}BeginDrawing:=False; end;
              X2:=X1+Scan1*cos(Angle);Y2:=Y1+Scan1*sin(Angle);
              ScanLength:=Distance(X,Y,X2,Y2);
              If ScanLength>LineLength then begin // если остаточная длина больше чем длина текущего
                Inc(CLines);
                dNext:=ScanLength-LineLength;
                Drawer.DrawLine(X1,Y1,D1.X,D1.Y);
              //  Drawer.DrawMarker(X1, Y1);
                DrawingScan:=True;
                break;
              end;
               Inc(CLines);
               Drawer.DrawLine(X1,Y1,X2,Y2);
             //  Drawer.DrawMarker(X1, Y1);
             end;
              DrawingScan:=False;
             X1:=X2+Space*cos(Angle);Y1:=Y2+Space*sin(Angle);
             ScanLength:=Distance(X,Y,X1,Y1);
              If ScanLength>LineLength then begin// если остаточная длина больше чем длина текущего
                dNext:=ScanLength-LineLength;X2:=D1.X;Y2:=D1.Y;DrawingScan:=False;break;
              end else DrawingScan:=True;
            end;
         end;
     end;
     If B then Coord.Free;
    end;
//   WRiteln('Clines=',CLines);
end;

Procedure DrawDoubleLine(Drawer: TogsDrawer; Coord: PCollection; PS: TLineStruct;
                         LWK, Ko: Double; LWByLayer: Boolean; ROfs, LOfs: Single; Dx: Double);
var Delta,Delta1:Double;X,Y,X1,Y1:Double;D1,D2,D3,D4,DC:TDot1;
    Angle,RevAngle,DimAngle,Angle1,Angle2,Angle3:Double;
    Coord1,Coord2:PCollection;
    I:Integer;
    PS1:TLineStruct;// дополнительный стиль для второго отрезка
    LWK1:Single;
    rOfs1,lOfs1,rOfs2,lOfs2:Single;
    timeStart: TDateTime;
begin
// timeStart := GetTickCount;
 Coord1:=PCollection.Create(Coord.Count);Coord2:=PCollection.Create(Coord.Count);
 Delta:=RealScaleLength(Drawer, PS.Param4/2, Ko);
 lOfs1:=RealScaleLength(Drawer, lOfs, Ko);
 rOfs1:=RealScaleLength(Drawer, rOfs, Ko);
 D1:=Coord.List[0];D2:=Coord.List[1];
 Angle:=Atan2(D2.X-D1.X,D2.Y-D1.Y);
 X:=D1.X+(Delta+lOfs1)*Cos(Angle+Pi/2);Y:=D1.Y+(Delta+lOfs1)*Sin(Angle+Pi/2);
 Coord1.Insert(TDot1.Create(X,Y));
 X1:=D1.X+(Delta+rOfs1)*Cos(Angle-Pi/2);Y1:=D1.Y+(Delta+rOfs1)*Sin(Angle-Pi/2);
 Coord2.Insert(TDot1.Create(X1,Y1));
 For I:=1 to Coord.List.Count-2 do begin
   D1:=Coord.List[I-1];DC:=Coord.List[I];D3:=Coord.List[I+1];
   Angle1:=Atan2(D1.X-DC.X,D1.Y-DC.Y);Angle2:=Atan2(D3.X-DC.X,D3.Y-DC.Y);
   Angle3:=(Angle1)+Pi/2; // прямой угол
   Angle:=Angle2-Angle1;If Angle<0 then Angle:=Pi*2+Angle;
   Angle:=(Angle/2+Angle1);//Writeln(Angle1*180/Pi:8:2,' ',Angle*180/Pi:8:2);
   Angle3:=Abs(Angle3-Angle);
   Delta1:=abs(Delta/Cos(Angle3));//Writeln(Angle3*180/Pi:8:3,' ',' ',Sin(Angle3),' ' ,Delta1:8:3);
   rOfs2:=rOfs1/Cos(Angle3);lOfs2:=lOfs1/Cos(Angle3);
   X:=DC.X+(Delta1+rOfs2)*Cos(Angle);Y:=DC.Y+(Delta1+rOfs2)*Sin(Angle);
   X1:=DC.X-(Delta1+lOfs2)*Cos(Angle);Y1:=DC.Y-(Delta1+lOfs2)*Sin(Angle);
  // получаем дополнения до всего
   Coord2.Insert(TDot1.Create(X,Y));Coord1.Insert(TDot1.Create(X1,Y1));
 //    UDrawLine(X,Y,X1,Y1);
  end;
 D3:=Coord.List[Coord.List.Count-2];D4:=Coord.List[Coord.List.Count-1];
 Angle:=Atan2(D4.X-D3.X,D4.Y-D3.Y);
 X:=D4.X+(Delta+lOfs1)*Cos(Angle+Pi/2);Y:=D4.Y+(Delta+lOfs1)*Sin(Angle+Pi/2);
 Coord1.Insert(TDot1.Create(X,Y));
 X1:=D4.X+(Delta+rOfs1)*Cos(Angle-Pi/2);Y1:=D4.Y+(Delta+rOfs1)*Sin(Angle-Pi/2);
 Coord2.Insert(TDot1.Create(X1,Y1));
  PS1:=TLineStruct.Create();
   PS1.Param0:=PS.Param5;PS1.Param1:=PS.Param6;PS1.Param2:=PS.Param7;PS1.Param3:=PS.Param8;
   If PS.DrawState and ls_Solid2 = 0 then PS1.DrawState:=0;
  // Толщина линии
   If (LWK < 0)and(not LWBYLayer) then LWK1:=Abs(LWK) else LWK1:=LWK*PS.Param1;
     //Pen:=SelectObject(Dc1,CreatePenSelector(round(LWK1),Color));
   If lOfs <> gmfIgnoreLineDRawing then
    DrawLine(Drawer, Coord1, PS, Ko, Dx, 0);
    //DeleteObject(SelectObject(Dc1,Pen));
    If (LWK < 0)and(not LWBYLayer) then LWK1:=Abs(LWK) else LWK1:=LWK*PS.Param1;
     //Pen:=SelectObject(Dc1,CreatePenSelector(round(LWK1),Color));
  If lOfs <> gmfIgnoreLineDrawing then
   DrawLine(Drawer, Coord2, PS1, Ko, Dx, 0) else
   DrawLine(Drawer, Coord2, PS, Ko, Dx, 0);
  // DeleteObject(SelectObject(Dc1,Pen));
  PS1.Free;
 Coord1.Free;Coord2.Free;
end;

procedure DrawArc(Drawer: TogsDrawer; Coord1: PCollection; PS: TLineStruct;
                  Ko, KoPoint: Double; Znak: TPoint_Sign; Dx: Single; Selected: Boolean);
var I,J,K:Integer;D1,D2:TDot1;
    Angle:Double; // дир. угол текущего отрезка
    dNext,dPrev:Double; // остаток длины переходящий в след отрезок
    X1,Y1:Double; // координаты кружка
    LineLength,PolyLength:Double; // длина линии и полилинии
    ScanLength:Double; // длина от начала линии до рассчитанной точки кружка
    Scan,Scan1:Double; // расстояние между кружками
    BeginDrawing:boolean;// начало рисовки
    R,R2:TSect; // габариты кружка для отсечения
    Coord:PCollection;B1:Boolean;
Function Vis:boolean;
begin
{!!! проверить на FMX }
 Result:=True;
   With Drawer.ogsSelector.ActiveRect do
       begin
        If R2.Right < XMin then Result:=False else
        If R2.Left > XMax then Result:=False else
        If R2.Top > YMax then Result:=False else
        If R2.Bottom < YMin then Result:=False;
       end;
end;
Procedure DrawZnak;
begin
 Znak.X:=X1;
 Znak.Y:=Y1;
  if (PS.DrawState and ls_OrientOn)<>0 then Znak.Ugol:=Angle+PS.Param2 else Znak.Ugol:=PS.Param2;
  With TSelector(Drawer.ogsSelector) do
   Znak.Draw32(Drawer,GMS,GMS,Drawer.R,Drawer.G,Drawer.B,ZnakDrawMode,GPRect,KoPoint,(GGraphSet.ShowAttributes),False);
end;
begin
// dNext:=PS.Param3*Ko;dPrev:=PS.Param8*Ko;B1:=False;
dNext:=RealScaleLength(Drawer,PS.Param3,Ko);dPrev:=RealScaleLength(Drawer,PS.Param8,Ko);B1:=False;
If dNext+dPrev<>0 then
 begin // отсечение ломаной
  Coord:=CutLine(Coord1,dNext,dPrev);
  B1:=True;
 end else Coord:=Coord1;
 if Coord<>nil then
  begin
   // находим габариты кружка, нач. смещ. и расст. между кружками
    R.Left:=-PS.Param2*Ko;R.Right:=PS.Param2*Ko;
    R.Top:=R.Left;R.Bottom:=R.Right;
   // If Ko=-1 then Scan:=XGeoRasst(Round(PS.Param0*GlobalMas)) else Scan:=PS.Param0*Ko;
    Scan:=RealScaleLength(Drawer, PS.Param0,Ko);
    K:=0;
     If Dx<>0 then begin // учитываем смещение вдоль ломаной
       if Dx>0 then While Dx>0 do Dx:=Dx-Scan else // вычисление отрицательного смещения
       If Dx<0 then While Dx+(Scan)<0 do Dx:=Dx+(Scan);
       if Dx<>0 then begin // продолжаем, если смещение не <> 0
        Dx:=Dx+(Scan); // смещение со штрихом
        If Dx>0 then begin // рисуем штрих
        {}
          For K:=0 to Coord.List.Count-2 do
           With TDot1(Coord.List[K]) do begin
             D1:=Coord.List[K+1];
             LineLength:=Distance(X,Y,D1.X,D1.Y);
              If Dx>LineLength then begin
                Dx:=Dx-LineLength;
               end else break;
            end;
         {}
        if Coord.List.Count>K+1 then begin
         D2:=Coord.List[K];D1:=Coord.List[K+1];
         Angle:=Atan2(D1.X-D2.X,D1.Y-D2.Y);
         X1:=D2.X+Dx*cos(Angle);Y1:=D2.Y+Dx*sin(Angle);
        // рисуем
         R2.Left:=X1+R.Left;R2.Top:=Y1+R.Top;
         R2.Right:=X1+R.Right;R2.Bottom:=Y1+R.Bottom;
         If Znak<>nil then DrawZnak else
         if Vis then
          Drawer.DrawCircle(X1, Y1, (R2.Right - R2.Left)/2);
         end;
         Dx:=Dx+Scan;
        end else Dx:=Dx+Scan;
       end;
       dNext:=Dx;
      end else dNext:=0;
  // с учетом начального смещения начинаем рисовку
{      if dNext<>0 then begin // просчитываем начальное смещение на ломаной
      For K:=0 to Coord.List.Count-2 do
       With TDot1(Coord.List[K]) do
        begin
         D1:=Coord.List[K+1];
         LineLength:=Distance(XDot,YDot,D1.X,D1.Y);
          If dNext>LineLength then begin
            dNext:=dNext-LineLength;
           end else break;
        end;
     end; // if dNext<>0}
    // вперед
 //    Index:=0
     For I:=K to Coord.List.Count-2 do
      With TDot1(Coord.List[I]) do
       begin
         D1:=Coord.List[I+1];
         LineLength:=Distance(X,Y,D1.X,D1.Y);
         if (dNext>LineLength) then begin
           dNext:=dNext-LineLength;continue;
         end;
         Angle:=Atan2(D1.X-X,D1.Y-Y);// считаем дир угол в радианах
         X1:=X+dNext*cos(Angle);Y1:=Y+dNext*sin(Angle);
         R2.Left:=X1+R.Left;R2.Top:=Y1+R.Top;
         R2.Right:=X1+R.Right;R2.Bottom:=Y1+R.Bottom;
         If Znak<>nil then DrawZnak else
         if Vis then
          Drawer.DrawCircle(X1, Y1, (R2.Right - R2.Left)/2);
         // рисуем кружки переносом на след. линию
          While True do
           begin // получаем вторую точку штриха
            X1:=X1+Scan*cos(Angle);Y1:=Y1+Scan*sin(Angle);
            ScanLength:=Distance(X,Y,X1,Y1);
             If ScanLength>LineLength then begin // если остаточная длина больше чем длина текущего
               dNext:=ScanLength-LineLength;
               break;
             end else begin
                       R2.Left:=X1+R.Left;R2.Top:=Y1+R.Top;
                       R2.Right:=X1+R.Right;R2.Bottom:=Y1+R.Bottom;
                       If Znak<>nil then DrawZnak else
                       if Vis then
                        Drawer.DrawCircle(X1, Y1, (R2.Right - R2.Left)/2);
                      end;
           end;
       end;
    if B1 then Coord.Free;
  end;
end;

Procedure DrawSymbol(Drawer: TogsDrawer; Coord: PCollection; PS: TLineStruct;
                     Ko, KoPoint: Double; Znak: TPoint_Sign; Dx:Single; Selected: Boolean);
var D1, D2: TDot1;
    I, J: Integer;
    B1: Boolean;
    dNext, DPrev: Double;
    X, Y, Angle: Double;
Procedure DrawZnak;
begin
 Znak.X:=X;
 Znak.Y:=Y;
  if (PS.DrawState and ls_OrientOn)<>0 then Znak.Ugol:=Angle+PS.Param2 else Znak.Ugol:=PS.Param2;
  With TSelector(Drawer.ogsSelector) do
  Znak.Draw32(Drawer,GMS,GMS,Drawer.R,Drawer.G,Drawer.B,ZnakDrawMode,GPRect,KoPoint,(GGraphSet.ShowAttributes),False);
end;
begin
// если ставим знак только в середине сегментов
  If PS.Param7=1 then
   begin
    For J:=0 to Coord.Count-2 do
     With TDot1(Coord.List[J]) do
      begin
       D2 := Coord.List[J+1];
       X:= (X+D2.X)/2;
       Y:= (Y+D2.Y)/2;
        if (PS.DrawState and ls_ToNext)<>0 then
          Angle := Atan2(D2.X-X,D2.Y-Y) else
        if (PS.DrawState and ls_ToPred)<>0 then
           Angle := Atan2(X - D2.X, Y - D2.Y) else Angle := PS.Param2;
      {}
       DrawZnak;
     end;
   end else
  If PS.Param6=1 then
   begin
    D1:=Coord.List[0];D2:=Coord.List[1];
    X:=D1.X;Y:=D1.Y;
      Angle:=PS.Param2;
      if (PS.DrawState and ls_ToNext)<>0 then
         Angle:=Atan2(D2.X-D1.X,D2.Y-D1.Y) else
      if (PS.DrawState and ls_ToPred)<>0 then
         Angle:=Atan2(D1.X-D2.X,D1.Y-D2.Y);
      DrawZnak;
   end else
  If PS.Param6=2 then
   begin
    D1:=Coord.List[Coord.List.Count-2];D2:=Coord.List[Coord.List.Count-1];
    X :=D2.X;Y:=D2.Y;
    Angle := PS.Param2;
      if (PS.DrawState and ls_ToNext)<>0 then
         Angle := Atan2(D2.X-D1.X,D2.Y-D1.Y) else
      if (PS.DrawState and ls_ToPred)<>0 then
         Angle := Atan2(D1.X-D2.X,D1.Y-D2.Y);
      DrawZnak;
   end else
  If PS.DrawState and ls_OnlyInDot<>0 then
   begin
    If ((PS.DrawState and ls_ToNext)=0) and ((PS.DrawState and ls_ToPred)=0) then
    For J:=0 to Coord.Count-2 do
     With TDot1(Coord.List[J]) do
      begin
       D2:=Coord.List[J+1];
       X:=X;
       Y:=Y;
       Angle := PS.Param2;
       DrawZnak;
      end else
    For J:=0 to Coord.Count-2 do
     With TDot1(Coord.List[J]) do
      begin
       D2:=Coord.List[J+1];
       X:=X;
       Y:=Y;
        if (PS.DrawState and ls_ToNext)<>0 then
         Angle:=Atan2(D2.X-X,D2.Y-Y) else Angle:=PS.Param2;
       DrawZnak;
      {}
        X:=D2.X;
        Y:=D2.Y;
        if (PS.DrawState and ls_ToPred)<>0 then
         Angle:=Atan2(X-D2.X,Y-D2.Y) else Angle:=PS.Param2;
       DrawZnak;
      {}
      end;
// оисование знвка интервалами вдоль полилинии
   end else begin
    DrawArc(Drawer, Coord, PS, Ko, Ko, Znak, Dx, Selected);
   end;
end;

procedure DrawGeoLine(Drawer: TogsDrawer; GL: TGeoLine; ogsLine: PCollection;
                      Ko: Single; LineWidth: Single; Dx: Single; Selected: Boolean; Color: Integer);
var I, Index: Integer; PS: TLineStruct;
    LWK,LWK1,Ko1:Double;// коэффициент утолщения линий
    Znak:TPoint_Sign; R,G,B:Byte;
    D1,D2:TDot1;
    LWByLayer:Boolean;
   // Brush: TLogBrush; // ранее был выбор типа рисования концов утолщенных линий
    FLE:Byte;
    PCTwig: PCollection;
    Pen: TogsPen; Brush: TogsBrush;
begin
// переводим полилинию в систему координат ogsMatrix
 PCTwig := PCollection.Create(1);
 For I := 0 to ogsLine.Count - 1 do begin
  PCTwig.Insert(TDot1.Create(TDot1(ogsLine[I]).X, TDot1(ogsLine[I]).Y));
 end;
 LWByLayer:=False;
 try
  If Ko<0 then begin
   Ko1:=abs(Ko) * Drawer.ogsSelector.fScale;
   If LineWidth=-1 then LWByLayer:=True else LWK:=-(LineWidth * Drawer.ogsSelector.fScale);
  end else begin
   Ko1:=KO;LWK:=KO1 * Drawer.ogsSelector.fScale;
   If LineWidth<>-1 then LWK:=-(LineWidth * Drawer.ogsSelector.fScale) else LWByLayer:=True;
  end;
  // LWK:=KO1*GMS; // установка коэффициента для толщины линии
  ZnakDrawMode:=0;
 //
  If LWK = 0 then Exit;
 //If BlockGlobalWidth then begin LWK:=0;LWK1:=0;end;
 // R:=GetRValue(Color);G:=GetGValue(Color);B:=GetBValue(Color);
// WriteIn(['GL = nil', GL = nil, GL.NameOf]);
  For I:=0 to GL.Structura.Count-1 do
   begin
    PS:=GL.Structura.At(I);
     case PS.BitOf of
       bt_Line  :begin
                  try
                  // FLE:=GGraphSet.FlatLineEnd;
                   If GL.Layer<>nil then begin
                   // If GL.Layer.Standart=0 then GGraphSet.FlatLineEnd:=GL.Layer.FlatLineEnd;
                   end;
                   If PS.DRawState and ls_dblLine=0 then begin // рисуем одинарную линию
                    // вычисляем коэффициент
                    If LWK < 0 then LWK1:=LWK else LWK1:=LWK*PS.Param1;
                    //If Ko<0 then Pen:=SelectObject(Dc,CreatePen(ps_Solid,round(LWK),Color))else
 //                   Writeln(GL.IdNum,' ',PS.lVOrign);
 //                  If GL.IdNum = 21022 then
                    If PS.lVorign = 0 then begin
                     If LineWidth < 0 then
                      Pen := Drawer.SelectPen(TogsPen.Create(Color, -LineWidth * PS.Param1 * Ko, nil)) else
                      Pen := Drawer.SelectPen(TogsPen.Create(Color, LineWidth * PS.Param1 * Ko, nil));
                     Brush := Drawer.SelectBrush(TogsBrush.Create(Color, nil));
                    // Brush.lbStyle:=BS_Solid; Brush.lbColor:=Color;
                    // Pen:=SelectObject(Dc,CreatePenSelector(round(LWK1),Color));
                    //  Drawer.penColor := Color;
                    //  Drawer.penWidth := Abs(round(LWK1));
                      DrawLine(Drawer, PCTwig, PS, Ko, PS.lVorign, Dx);
                     Drawer.DeletePen(Drawer.SelectPen(Pen));
                     Drawer.DeleteBrush(Drawer.SelectBrush(Brush));
                    // DeleteObject(SelectObject(Dc,Pen));
                    end else begin
                     DrawDoubleLine(Drawer, PCTwig, PS, LWK, Ko, LWByLayer, PS.lVorign,gmfIgnoreLineDrawing, Dx);
                    end;
                   end else begin
                     DrawDoubleLine(Drawer, PCTwig, PS, LWK, Ko, LWByLayer, PS.lVorign, PS.rVOrign, Dx);
                   end;
                  finally {GGraphSet.FlatLineEnd:=FLE;} end;
                 end;
       bt_Arc   :begin
                  If LWK < 0 then LWK1:=LWK else LWK1:=LWK*PS.Param1;
                 // Pen:=SelectObject(Dc,CreatePen(ps_Solid,round(LWK1),Color));
                   //Drawer.penColor := Color;
                   //Drawer.penWidth := Abs(round(LWK1));
                   DrawArc(Drawer, PCTwig, PS, Ko1, Ko1, nil, Dx, Selected);
                 // DeleteObject(SelectObject(Dc,Pen));
                 end;
       bt_Custom:begin
                   Znak:=GL.Points.List[I];
                   If Znak<>@ZnakNil then begin
                  // Pen:=SelectObject(Dc,CreatePen(ps_Solid,0,Color{Rgb(0,255,0)}));
                  // Writeln('Ko=',Ko);   Gmx:=1;GMy:=1;
                    If Ko<0 then DrawSymbol(Drawer, PCTwig, PS, Ko, Ko, Znak, Dx, Selected) else
                                 DrawSymbol(Drawer, PCTwig, PS, Ko1, Ko1, Znak ,Dx, Selected);
                  // DeleteObject(SelectObject(Dc,Pen));
                  end;
                 end;
     end; // case PS.BitOf
  end; // For I:=0 to GL.Structure.Count-1 ...
 finally
  PCTwig.Free;
 end;
end;

end.

