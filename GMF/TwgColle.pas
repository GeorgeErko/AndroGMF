Unit TwgColle;
Interface uses Collect,SysUtils;

type
{ Элемент коллекции -PChar }
   TStr=Class(TTwgObject)
    Pch:PAnsiChar;
    Constructor Create(Pch1:PAnsiChar);
     Constructor Load(Stream:TBufStream);Override;
     Procedure   Store(Stream:TBufStream);Override;
     Destructor  Destroy;Override;
   end;

{ Элемент коллекции -LongInt }
 type
   TLong= Class(TTwgObject)
    Num:FixedInt;
     Constructor Create(Num1:FixedInt);
     Constructor Load(Stream:TBufStream);Override;
     Procedure   Store(Stream:TBufStream);Override;
    end;

   TLong2= Class(TLong)
    ID:FixedInt;
     Constructor CreateID(Num1,ID1:FixedInt);
    end;

   TExt= Class(TTwgObject)
    Num:Extended;
     Constructor Create(Num1:Extended);
     Constructor Load(Stream:TBufStream);Override;
     Procedure   Store(Stream:TBufStream);Override;
    end;

   TExt2= Class(TTwgObject)
    Num1,Num2:Extended;
     Constructor Create(Num1_,Num2_:Extended);
     Constructor Load(Stream:TBufStream);Override;
     Procedure   Store(Stream:TBufStream);Override;
    end;

   TExp= Class(TTwgObject)
	 Num  :Extended;
   Name :PAnsiChar;
	 Plo  :Extended;
   Plo2 :Extended;
	  Constructor Create(N1:Extended;Name1:PAnsiChar;Plo1,Plo22:Extended);
	  Procedure   Insert(Plo1,Plo22:Extended);
    Constructor Load(Stream:TBufStream);Override;
    Procedure   Store(Stream:TBufStream);Override;
	  Destructor  Destroy;Override;
	end;

    TIntNum=Class(TTwgObject)
      Num:SmallInt;
      Constructor Create(Num1:SmallInt);
      Constructor Load(Stream:TBufStream);Override;
      Procedure   Store(Stream:TBufStream);Override;
    end;

  {$H-}
    TExpColor=Class(TTwgObject)
      Name :AnsiString;
      Color:FixedInt;
      Plo1,Plo2:Extended;
      DoName:AnsiString;
       Constructor Create(N:String;C:FixedInt;P1,P2:Extended;Dn:AnsiString);
       Constructor Load(Stream:TBufStream);Override;
       Procedure   Store(Stream:TBufStream);Override;
       Destructor  Destroy;Override;
      end;
  {$H+}
    TNumCoord = class(TTwgObject)
     Num:Integer;
     X,Y,X1,Y1:Double;
     constructor Create(Num_: Integer; X_, Y_, X1_,Y1_: Double);
    end;

    TNew = class(TTwgObject)
     Num:Integer;
     Numbers:String;
     Constructor Create;
    end;

Implementation

 {}
 { TStr methods }
 {}

 Constructor TStr.Create;
  begin
   Pch:=StrNew(Pch1);
  end;

 Constructor TStr.Load;
  begin
   Pch:=Stream.StrRead;
  end;

 Procedure   TStr.Store;
  begin
   Stream.StrWrite(Pch);
  end;

 Destructor  TStr.Destroy;
  begin
   StrDispose(Pch);
  end;

 {}
 { TLong methods }
 {}

 Constructor TLong.Create;
  begin
   Num:=Num1;
  end;

 Constructor TLong.Load;
  begin                            
   Stream.Read(Num,SizeOf(Num));
  end;

 Procedure   TLong.Store;
  begin
   Stream.Write(Num,SizeOf(Num));
  end;

 Constructor TExt.Create;
  begin
   Num:=Num1;
  end;

 Constructor TExt.Load;
  begin
   Num:=Stream.ReadExtended;
  end;

 Procedure   TExt.Store;
  begin
   Stream.WriteExtended(Num);
  end;

 Constructor TExp.Create;
  begin
	 Num:=N1;
	 Plo:=Plo1;
	 Name:=StrNew(Name1);
    Plo2:=Plo22;
  end;

 Procedure   TExp.Insert;
  begin
	 Plo:=Plo+Plo1;
    Plo2:=Plo2+Plo22;
  end;

 Constructor TExp.Load;
  begin
  Stream.Read(Num,SizeOf(Num));
	Name:=Stream.StrRead;
	Stream.Read(Plo,SizeOf(Plo));
	Stream.Read(Plo2,SizeOf(Plo2));
  end;

 Procedure   TExp.Store;
  begin
	Stream.Write(Num,SizeOf(Num));
	Stream.StrWrite(Name);
	Stream.Write(Plo,SizeOf(Plo));
	Stream.Write(Plo2,SizeOf(Plo2));
  end;



 Destructor TExp.Destroy;
  begin
    StrDispose(Name);
  end;

  Constructor TIntNum.Create;
  begin
   Num:=Num1;
  end;

 Constructor TIntNum.Load;
  begin
   Stream.Read(Num,SizeOf(Num));
  end;

 Procedure   TIntNum.Store;
  begin
   Stream.Write(Num,SizeOf(Num));
  end;

 Constructor TExpColor.Create;
  var NN:Extended;Err:SmallInt;
  begin
   Color:=C;
   Name:=N;
   Plo1:=P1;
	Plo2:=P2;
	DoName:=Dn;
  end;

 Constructor TExpColor.Load;
  begin
  Stream.Read(Color,SizeOf(Color));
	Name:=Stream.ReadStr;
	Stream.Read(Plo1,SizeOf(Plo1));
	Stream.Read(Plo2,SizeOf(Plo2));
	DoName:=Stream.ReadStr;
  end;

 Procedure   TExpColor.Store;
  begin
	Stream.Write(Color,SizeOf(Color));
	Stream.WriteStr(Name);
	Stream.Write(Plo1,SizeOf(Plo1));
	Stream.Write(Plo2,SizeOf(Plo2));
	Stream.WriteStr(DoName);
  end;

 Destructor  TExpColor.Destroy;
  begin
   SetLength(Name,0);
   SetLength(DoName,0);
	end;

{ TLong2 }

constructor TLong2.CreateID(Num1, ID1: FixedInt);
begin
 Num:=Num1;ID:=ID1;
end;

{ TNumCoord }

constructor TNumCoord.Create(Num_: Integer; X_, Y_, X1_,Y1_: Double);
begin
 Num:=Num_;X:=X_;Y:=Y_;X1:=X1_;Y1:=Y1_;
end;

{ TExt2 }

constructor TExt2.Create(Num1_,Num2_: Extended);
begin
 Num1:=Num1_;Num2:=Num2_;
end;

constructor TExt2.Load(Stream: TBufStream);
begin
  inherited;

end;

procedure TExt2.Store(Stream: TBufStream);
begin
  inherited;

end;

{ TNew }

constructor TNew.Create;
begin
 Num:=1;
end;

begin
end.
