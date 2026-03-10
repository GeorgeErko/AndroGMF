unit dsolve;

interface
 uses Types_dimano;

 function solving_linear_system_by_gauss( a : TMatrica; h : TRealCollect;
                                          var cond : double ) : boolean;
 procedure Solve ( N : integer; A, B : TRealCollect; Ipvt : TIntCollect );
 procedure Decomp ( N : integer; A, Work : TRealCollect; Ipvt : TIntCollect;
                    var Cond : double );
 function Indx ( N, i, j : integer ) : integer;

implementation

function Indx ( N, i, j : integer ) : integer;
  begin Indx := N * pred( i ) + j end;

procedure Solve ( N : integer; A, B : TRealCollect; Ipvt : TIntCollect );
  var
    T : double;
    i, k, m, kb : integer;
  begin
    if N <> 1 then
      begin
        for k := 1 to N-1 do
          begin
            m := Ipvt[k];
            T := B[m];
            B[m] := B[k];
            B[k] := T;
            for i := k+1 to N do B[i] := B[i] + A[ Indx( N, i, k ) ] * T;
          end;
        for kb := 1 to N-1 do
          begin
            k := N - kb +1;
            B[k] := B[k] / A[ Indx( N, k, k ) ];
            T := -B[k];
            for i := 1 to N-kb do B[i] := B[i] + A[ Indx( N, i, k ) ] * T
          end
      end;
    B[1] := B[1] / A[1]
  end;

procedure Decomp ( N : integer; A, Work : TRealCollect; Ipvt : TIntCollect;
                   var Cond : double );
  var
    i, j, k, m, kb : integer;
    EK, T, Anorm, Ynorm, Znorm : double;
  begin
    Cond := 1.0E+32;
    Ipvt[N] := 1;
    if N = 1 then begin if A[1] <> 0 then Cond := 1;
                        Exit
                  end;
    Anorm := 0;
    for j := 1 to N do
      begin
        T := 0;
        for i := 1 to N do T := T + abs( A[ Indx( N, i, j ) ] );
        if T > Anorm then Anorm := T
      end;
    for k := 1 to N-1 do
      begin
        m := k;
        for i := k+1 to N
         do if abs( A[ Indx( N, i, k ) ] )  > abs( A[ Indx( N, m, k ) ] )
             then m := i;
        Ipvt[k] := m;
        if m <> k then Ipvt[N] := -Ipvt[N];
        T := A[ Indx( N, m, k ) ];
        A[ Indx( N, m, k ) ] := A[ Indx( N, k, k ) ];
        A[ Indx( N, k, k ) ] := T;
        if T <> 0 then
          begin
            for i := k+1 to N
             do A[ Indx( N, i, k ) ] := -A[ Indx( N, i, k ) ] / T;
            for j := k+1 to N do
              begin
                T := A[ Indx( N, m, j ) ];
                A[ Indx( N, m, j ) ] := A[ Indx( N, k, j ) ];
                A[ Indx( N, k, j ) ] := T;
                if T <> 0 then for i := k+1 to N
                 do A[ Indx( N, i, j ) ] := A[ Indx( N, i, j ) ] +
                                          A[ Indx( N, i, k ) ] * T
              end
          end
      end;
    for k := 1 to N do
      begin
        T := 0;
        if k <> 1 then for i := 1 to k-1
                        do T := T + A[ Indx( N, i, k ) ] * Work[i];
        EK := 1;
        if T < 0 then Ek := -1;
        if A[ Indx( N, k, k ) ] = 0 then Exit;
        Work[k] := -( EK + T ) / A[ Indx( N, k, k ) ]
      end;
    for kb := 1 to N-1 do
      begin
        k := N - kb;
        T := 0;
        for i := k+1 to N do T := T + A[ Indx( N, i, k ) ] * Work[k];
        Work[k] := T;
        m := Ipvt[k];
        if m <> k then begin
                         T := Work[m];
                         Work[m] := Work[k];
                         Work[k] := T;
                       end
      end;
    Ynorm := 0;
    for i := 1 to N do Ynorm := Ynorm + abs( Work[i] );
    Solve( N, A, Work, Ipvt );
    Znorm := 0;
    for i := 1 to N do Znorm := Znorm + abs( Work[i] );

    Cond := Anorm * Znorm / Ynorm;
    if Cond < 1 then Cond := 1;
  end;

function solving_linear_system_by_gauss( a : TMatrica; h : TRealCollect;
                                         var cond : double ) : boolean;
 var
   Work, bb : TRealCollect;
   Ipvt : TIntCollect;
   i, j, n : integer;
 begin
   Result := TRUE;
   Ipvt := TIntCollect.Create(1);
   Work := TRealCollect.Create(1);
   bb := TRealCollect.Create(1);
   n := h.Count;
    for i := 1 to n do
      begin
        for j := 1 to n do bb.Insert( TDouble.Create(1) );
        Work.Insert( TDouble.Create(1) );
        Ipvt.Insert( TInt.Create(1) );
      end;
   for i := 1 to n do for j := 1 to n do bb[indx(n,i,j)] := A[i,j];
   Decomp( N, bb, Work, Ipvt, Cond );
   if ( cond+1 = cond ) then Result := FALSE else solve( N, bb, h, Ipvt );
   bb.Free;
   Work.Free;
   Ipvt.Free;
 end;

end.
