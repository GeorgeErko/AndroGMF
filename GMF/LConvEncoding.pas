unit LConvEncoding;

interface

uses
  System.SysUtils, System.Classes;

function CP1251ToUtf8(const S: String): UTF8String; overload;
function Utf8ToCP1251(const S: UTF8String): RawByteString; overload;

function CP1251ToUtf8Bytes(const B: TBytes): TBytes;
function Utf8ToCP1251Bytes(const B: TBytes): TBytes;

implementation

function CP1251ToUtf8(const S: String): UTF8String;
var
  A: TBytes;
  U: UnicodeString;
begin
  if S = '' then
    Exit('');
  //SetLength(A, Length(S));
 // U := TEncoding.GetEncoding(1251).GetString(S);
  Result := AnsiToUTF8(S);
end;

function Utf8ToCP1251(const S: UTF8String): RawByteString;
var
  U: UnicodeString;
  A: TBytes;
begin
  if S = '' then
    Exit('');
  U := UnicodeString(S);
  A := TEncoding.GetEncoding(1251).GetBytes(U);
  SetString(Result, PAnsiChar(@A[0]), Length(A));
end;

function CP1251ToUtf8Bytes(const B: TBytes): TBytes;
var
  U: UnicodeString;
begin
  if Length(B) = 0 then
    Exit(nil);
  U := TEncoding.GetEncoding(1251).GetString(B);
  Result := TEncoding.UTF8.GetBytes(U);
end;

function Utf8ToCP1251Bytes(const B: TBytes): TBytes;
var
  U: UnicodeString;
begin
  if Length(B) = 0 then
    Exit(nil);
  U := TEncoding.UTF8.GetString(B);
  Result := TEncoding.GetEncoding(1251).GetBytes(U);
end;

end.
