unit ogcTypedCollect;

interface

uses Classes, SysUtils, ogcBasic;

type

  { TStringItem }

  TStringItem = class(TogsBasic)
   ID: AnsiString;  // идентификатор
   Data: TogsBasic; // объект
   constructor Create(ID_: AnsiString; Data_: TogsBasic = nil);
   destructor Destroy; override;
  end;

var ogsStringItem: TStringItem;

type

  { TStrTypedCollection }

  TStrTypedCollection = class(TogsSortedCollection)
  private
   fCaseIgnore: Boolean;
   function GetItem(Index: Integer): TStringItem;
   function GetDataItem(Index: Integer): TogsBasic;
   function GetStringItem(Index: Integer): AnsiString;
   procedure SetCaseIgnore(AValue: Boolean);
   procedure SetDataItem(Index: Integer; AValue: TogsBasic);
   procedure SetStringItem(Index: Integer; AValue: AnsiString);
  public
   constructor CreateTyped(CaseIgnore_: Boolean = False);
  //
   function Add(Value: AnsiString; Data_: TogsBasic = nil): Integer; overload;
   function SearchBy(Value: AnsiString): TogsBasic; overload; virtual;
   function SearchBy(Value: AnsiString; var Index: Integer): TogsBasic; overload;
   function WriteObj(Params: array of Const): String; override;
  //
   property Item[Index: Integer]: TStringItem read GetItem; default;
   property ItemStr[Index: Integer]: AnsiString read GetStringItem write SetStringItem;
   property ItemData[Index: Integer]: TogsBasic read GetDataItem write SetDataItem;
   property CaseIgnore: Boolean read fCaseIgnore write SetCaseIgnore;
  end;

implementation uses Writer;

function StringSortedProc(Item1, Item2: Pointer): Integer;
begin
 If TStringItem(Item1).ID < TStringItem(Item2).ID then Result := -1 else
 If TStringItem(Item1).ID = TStringItem(Item2).ID then Result := 0 else
 If TStringItem(Item1).ID > TStringItem(Item2).ID then Result := 1;
end;

// Case Ignored
function StringSortedProcCI(Item1, Item2: Pointer): Integer;
begin
 If AnsiUpperCase(TStringItem(Item1).ID) < AnsiUpperCase(TStringItem(Item2).ID) then Result := -1 else
 If AnsiUpperCase(TStringItem(Item1).ID) = AnsiUpperCase(TStringItem(Item2).ID) then Result := 0 else
 If AnsiUpperCase(TStringItem(Item1).ID) > AnsiUpperCase(TStringItem(Item2).ID) then Result := 1;
end;

{ TStringItem }

constructor TStringItem.Create(ID_: AnsiString; Data_: TogsBasic);
begin
 ID := ID_;
 Data := Data_;
end;

destructor TStringItem.Destroy;
begin
 If Data <> nil then Data.Free;
 inherited Destroy;
end;

{ TStrTypedCollection }

constructor TStrTypedCollection.CreateTyped(CaseIgnore_: Boolean);
begin
 fCaseIgnore := CaseIgnore_;
 If fCaseIgnore then
  inherited Create(StringSortedProcCI, False) else
  inherited Create(StringSortedProc, False);
end;

procedure TStrTypedCollection.SetCaseIgnore(AValue: Boolean);
begin
 If fCaseIgnore = AValue then exit;
 fCaseIgnore := AValue;
 If fCaseIgnore then fOnCompare := StringSortedProcCI else
                     fOnCompare := StringSortedProc;
end;

function TStrTypedCollection.GetItem(Index: Integer): TStringItem;
begin
 Result := FList[Index];
end;

function TStrTypedCollection.GetStringItem(Index: Integer): AnsiString;
begin
 Result := TStringItem(FList[Index]).ID;
end;

procedure TStrTypedCollection.SetStringItem(Index: Integer; AValue: AnsiString);
begin
 TStringItem(FList[Index]).ID := AValue;
end;

function TStrTypedCollection.GetDataItem(Index: Integer): TogsBasic;
begin
 Result := TStringItem(FList[Index]).Data;
end;

procedure TStrTypedCollection.SetDataItem(Index: Integer; AValue: TogsBasic);
begin
 If FList[Index] = AValue then exit;
 If TStringItem(FList[Index]).Data <> nil then
  TStringItem(FList[Index]).Data.Free;
//
 TStringItem(FList[Index]).Data := AVAlue;
end;

function TStrTypedCollection.Add(Value: AnsiString; Data_: TogsBasic = nil): Integer;
var Item: TStringItem;
begin
 Item := TStringItem.Create(Value, Data_);
 Result := inherited Add(Item);
 If Result = -1 then Item.Free;
end;

function TStrTypedCollection.WriteObj(Params: array of const): String;
var I: Integer;
begin
 Result := String(Fmt(['Count', Count]));
 For I := 0 to Count - 1 do
  Result := Result + #13#10 + String(ItemStr[I]);
end;

function TStrTypedCollection.SearchBy(Value: AnsiString): TogsBasic;
var Index: Integer;
begin
 ogsStringItem.ID := Value;
 If Search(ogsStringItem, Index) then
  Result := TStringItem(FList[Index]).Data
   else
    Result := nil;
end;

function TStrTypedCollection.SearchBy(Value: AnsiString; var Index: Integer): TogsBasic;
begin
 ogsStringItem.ID := Value;
 If Search(ogsStringItem, Index) then
  Result := TStringItem(FList[Index]).Data
   else
    Result := nil;
end;


initialization
 ogsStringItem := TStringItem.Create('');
finalization
 ogsStringItem.Free;
end.
