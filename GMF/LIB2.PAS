Unit lib2;
{=========================================================================================}
interface uses lib, Collect;
{=========================================================================================}
type
  TPart=Class(TTwgObject)
		LineDx:single;
		Dx,Dy:single;
		MoveX,MoveY:single;
    RotateAngle:single;
		IndexOf:FixedInt;
     {}
		constructor Load(ST:TBufStream);Override;
		procedure Store(ST:TBufStream);Override;
	end;
{----------------------------------------------------------------}
	TSqwear_Sign=class(TTwgObject)
		PointerToLib:PCollection;
		NameOf:array[0..59] of AnsiChar;
                IdNum:SmallInt;
		Structura:PCollection;
		constructor Create(Name:AnsiString = '';Id:SmallInt = -1);
		Destructor Destroy;Override;
		constructor Load(ST:TBufStream);Override;
		procedure Store(ST:TBufStream);Override;
		function GetCoord(i,j,k:SmallInt;var X,Y,U:Single):boolean;
	end;

var
 GlobalSqwear: TSqwear_Sign;

{=========================================================================================}
 Type

   { SLIB }

   SLIB=Class(PLib)
     Function Compare(Key1,Key2:Pointer):Integer;override;
    end;

function SearchSqwear(PC:TSortedCollection;Num:Integer):SmallInt;
{=========================================================================================}
Implementation uses SysUtils, LConvEncoding;

function SLIB.Compare(Key1, Key2: Pointer): Integer;
begin
 If TSqwear_Sign(Key1).idNum<TSqwear_Sign(Key2).idNum then Result:=-1 else
 If TSqwear_Sign(Key1).idNum=TSqwear_Sign(Key2).idNum then Result:=0 else Result:=1;
end;

{=========================================================================================}
constructor TPart.Load;
var
	i:SmallInt;
begin
	ST.read(LineDx,4);
	ST.read(Dx,4);
	ST.read(Dy,4);
	ST.read(MoveX,4);
	ST.read(MoveY,4);
	ST.read(RotateAngle,4);
	ST.read(IndexOf,SizeOf(IndexOf));
end;
{----------------------------------------------------------------}
procedure TPart.store;
begin
	ST.write(LineDx,4);
	ST.write(Dx,4);
	ST.write(Dy,4);
	ST.write(MoveX,4);
	ST.write(MoveY,4);
	ST.write(RotateAngle,4);
	ST.write(IndexOf,SizeOf(IndexOf));
end;
{----------------------------------------------------------------}
constructor TSqwear_Sign.Create;
begin
	PointerToLib:=nil;
	Structura:=PCollection.Create(1);
 StrPCopy(NameOf,AnsiString(Name));
 IdNum:=Id;
end;
{----------------------------------------------------------------}
Destructor TSqwear_Sign.Destroy;
begin
	Structura.Free;
end;
{----------------------------------------------------------------}
constructor TSqwear_Sign.Load;
begin
	st.read(NameOf,30); StrPCopy(NameOf, CP1251ToUtf8(NameOf));
	st.read(idNum,sizeof(idNum));
	structura:=Pcollection(st.get);
end;
{----------------------------------------------------------------}
procedure TSqwear_Sign.Store;
begin
	st.write(NameOf,30);
	st.write(idNum,sizeof(idNum));
   st.put(Structura);
end;
{----------------------------------------------------------------}
function TSqwear_Sign.GetCoord(i,j,k:SmallInt;var X,Y,U:Single):boolean;
var
  p:TPart;
begin
   GetCoord:=false;
   p:=Structura.At(k);
   if p=nil then exit;
   X:=i*p.LineDx+p.MoveX+j*p.DX;
   Y:=j*p.Dy+p.MoveY;
   if P.RotateAngle<0 then U:=Random(63)/10
      else U:=P.RotateAngle;
end;
{----------------------------------------------------------------}

function SearchSqwear;
var i:Integer;
begin
Result:=-1;
if pc=nil then exit;
 GlobalSqwear.idNum:=Num;
 If Pc.Search(GlobalSqwear,I) then
  Result:=I;
end;

{----------------------------------------------------------------}
{=========================================================================================}
initialization
 GlobalSqwear := nil;
finalization
 If GlobalSqwear <> nil then GlobalSqwear.Free;
end.
