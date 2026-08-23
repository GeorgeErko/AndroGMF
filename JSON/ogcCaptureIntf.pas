unit ogcCaptureIntf;

interface uses ogcBasic, System.Skia;

type
  TogsPrimitiveKind = (
   opkUnknown,
   opkVertex,
   opkSegment,
   opkPolyline,
   opkArc,
   opkCircle,
   opkEllipse,
   opkText,
   opkFace,
   opkHatch
  );

  TogsPrimitiveKindSet = set of TogsPrimitiveKind;

  TogsRectSelectMode = (
   orsInside,
   orsCrossing
  );

  TogsPrimitiveId = record
   A, B: Integer;
   class function Create(A_, B_: Integer): TogsPrimitiveId; static;
   class function Empty: TogsPrimitiveId; static;
   function isEmpty: Boolean;
  end;

  TogsCaptureFilter = record
   Kinds: TogsPrimitiveKindSet;
   class function AllKinds: TogsCaptureFilter; static;
  end;

  TogsCaptureHit = record
   Owner: TObject;
   PrimitiveId: TogsPrimitiveId;
   Kind: TogsPrimitiveKind;
   SubIndex: Integer;
   XHitWorld, YHitWorld: Double;
   DistanceWorld: Double;
   Priority: Integer;
  end;

  TogsCaptureHitArray = array of TogsCaptureHit;
  TogsPrimitiveIdArray = array of TogsPrimitiveId;

  IogsPrimitiveCapturer = interface
   ['{3A7160E3-5E8B-4C3D-8C17-2B9B86B96C0E}']
   function GetHitTestMarker(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer): Integer;
   function HitTestPointWorld(X, Y: Double; RadiusWorld: Double; const Filter: TogsCaptureFilter; MaxResults: Integer = 1): Integer;
   function SelectRectWorld(const Rect: TSect; Mode: TogsRectSelectMode; const Filter: TogsCaptureFilter): Integer;
   function GetPrimitiveBoundsWorld(const PrimitiveId: TogsPrimitiveId; out Bounds: TSect): Boolean;
   procedure PainSelection(const Canvas: ISkCanvas);
  end;

  IogsSelectionAccess = interface
   ['{C2B2E6C8-8C3E-4B04-B1B8-5A8A0B769AC4}']
   function selectedCount: Integer;
   function selectedPtr(Index: Integer): Pointer;
  end;

implementation

{ TogsPrimitiveId }

class function TogsPrimitiveId.Create(A_, B_: Integer): TogsPrimitiveId;
begin
 Result.A := A_;
 Result.B := B_;
end;

class function TogsPrimitiveId.Empty: TogsPrimitiveId;
begin
 Result.A := -1;
 Result.B := -1;
end;

function TogsPrimitiveId.isEmpty: Boolean;
begin
 Result := (A < 0) and (B < 0);
end;

{ TogsCaptureFilter }

class function TogsCaptureFilter.AllKinds: TogsCaptureFilter;
begin
 Result.Kinds := [Low(TogsPrimitiveKind)..High(TogsPrimitiveKind)];
end;

end.
