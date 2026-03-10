unit newExtendedProcs;

interface

TYPE
  TExtended     = TExtended80Rec;
  PExtended     = ^TExtended;

//Function ToExtended80(D : Extended): TExtended;
//Function ToExtended(E : TExtended): Extended;

implementation

(*
{$IF SizeOf(Extended)=SizeOf(TExtended) }
PROCEDURE ExtendedToIntel(VAR D : Extended ; VAR E : TExtended); INLINE;
  BEGIN
    D:=Extended(E)
  END;

PROCEDURE IntelToExtended(VAR E : TExtended ; VAR D : Extended); INLINE;
  BEGIN
    E:=TExtended(D)
  END;
{$ENDIF}
{$IFDEF WIN64}
PROCEDURE ExtendedToIntel(VAR D : Extended {Double} ; VAR E : TExtended); ASSEMBLER;
  ASM
                FLD     QWORD PTR [RCX]
                FSTP    TBYTE PTR [RDX]
                FWAIT
  END;

PROCEDURE IntelToExtended(VAR E : TExtended ; VAR D : Extended {Double} ); ASSEMBLER;
  ASM
                FLD     TBYTE PTR [RCX]
                FSTP    QWORD PTR [RDX]
                FWAIT
  END;
{$ELSE}
PROCEDURE ExtendedToIntel(D : Extended ; VAR E : TExtended);
  BEGIN
    PExtended(@E)^:=TExtended(D)
  END;

PROCEDURE IntelToExtended(CONST E : TExtended ; VAR D : Extended);
  BEGIN
    D:=Double(PExtended(@E)^)
  END;
{$ENDIF}
*)

end.
