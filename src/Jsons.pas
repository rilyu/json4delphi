{****************************************************************************
Copyright (c) 2014 Randolph

mail: rilyu@sina.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

201804 - Fix - VGS - Refactor FixedFloatToStr (best use case and optimization)
201805 - Add - VGS - Add OBjectToJson and JsonToObject, rtti based, cross platform Delphi10+ and FPC 3+Refactor
201807 - Fix - VGS - String unicode (\uxxx) encoding and decoding.
202008 - Add - MaiconSoft - Constructor "New" for fast initialize Objects
202008 - Add - MaiconSoft - JsonArray.Put support multiples values at same time
202008 - Fix - MaiconSoft - Put without parameter will be 'empty' by default
202008 - Add - MaiconSoft - Add 'Pretty', stringify version for human read
202008 - Add - MaiconSoft - Add 'Foreatch' in TJsonArray
202008 - Add - MaiconSoft - Add TJsonArray export to TArray<T> (filter invalid values)

****************************************************************************}

unit Jsons;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, jsonsutilsEx;

type
  TJsonValueType = (jvNone, jvNull, jvString, jvNumber, jvBoolean, jvObject, jvArray);

  TJsonStructType = (jsNone, jsArray, jsObject);

  TJsonNull = (null);

  TJsonEmpty = (empty);

type
  TJsonBase = class(TObject)
  private
    FOwner: TJsonBase;
    function GetOwner: TJsonBase;
  protected
    function GetOwnerName: string;
    procedure RaiseError(const Msg: string);
    procedure RaiseParseError(const JsonString: string);
    procedure RaiseAssignError(Source: TJsonBase);
  public
    constructor Create(AOwner: TJsonBase);
    destructor Destroy; override;
    procedure Parse(JsonString: string); virtual; abstract;
    function Stringify: string; virtual; abstract;
    function Pretty(IdentLevel: Integer = 0): string; virtual; abstract;
    procedure Assign(Source: TJsonBase); virtual; abstract;
    function Encode(const S: string): string;
    function Decode(const S: string): string;
    procedure Split(const S: string; const Delimiter: Char; Strings: TStrings);
    function IsJsonObject(const S: string): Boolean;
    function IsJsonArray(const S: string): Boolean;
    function IsJsonString(const S: string): Boolean;
    function IsJsonNumber(const S: string): Boolean;
    function IsJsonBoolean(const S: string): Boolean;
    function IsJsonNull(const S: string): Boolean;
    function AnalyzeJsonValueType(const S: string): TJsonValueType;
  public
    property Owner: TJsonBase read GetOwner;
  end;

  TJsonObject = class;

  TJsonArray = class;

  TJsonValue = class(TJsonBase)
  private
    FValueType: TJsonValueType;
    FStringValue: string;
    FNumberValue: Extended;
    FBooleanValue: Boolean;
    FObjectValue: TJsonObject;
    FArrayValue: TJsonArray;
    function GetAsArray: TJsonArray;
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Extended;
    function GetAsObject: TJsonObject;
    function GetAsString: string;
    function GetIsNull: Boolean;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsNumber(const Value: Extended);
    procedure SetAsString(const Value: string);
    procedure SetIsNull(const Value: Boolean);
    procedure SetAsArray(const Value: TJsonArray);
    procedure SetAsObject(const Value: TJsonObject);
    function GetIsEmpty: Boolean;
    procedure SetIsEmpty(const Value: Boolean);
  protected
    procedure RaiseValueTypeError(const AsValueType: TJsonValueType);
  public
    constructor Create(AOwner: TJsonBase);
    destructor Destroy; override;
    procedure Parse(JsonString: string); override;
    function Stringify: string; override;
    function Pretty(IdentLevel: Integer = 0): string; override;
    procedure Assign(Source: TJsonBase); override;
    procedure Clear;
  public
    property ValueType: TJsonValueType read FValueType;
    property AsString: string read GetAsString write SetAsString;
    property AsNumber: Extended read GetAsNumber write SetAsNumber;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsObject: TJsonObject read GetAsObject write SetAsObject;
    property AsArray: TJsonArray read GetAsArray write SetAsArray;
    property IsNull: Boolean read GetIsNull write SetIsNull;
    property IsEmpty: Boolean read GetIsEmpty write SetIsEmpty;
  end;

  TJsonArray = class(TJsonBase)
  private
    FList: TList;
    function GetItems(Index: Integer): TJsonValue;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TJsonBase = nil);
    destructor Destroy; override;
    procedure Parse(JsonString: string); override;
    function Stringify: string; override;
    function Pretty(IdentLevel: Integer = 0): string; override;
    procedure Assign(Source: TJsonBase); override;
    procedure Merge(Addition: TJsonArray);
    function Add: TJsonValue;
    function Insert(const Index: Integer): TJsonValue;
    function Put(): TJsonValue; overload;
    function Put(const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Value: TJsonNull): TJsonValue; overload;
    function Put(const Value: Boolean): TJsonValue; overload;
    function Put(const Value: Integer): TJsonValue; overload;
    function Put(const Value: Extended): TJsonValue; overload;
    function Put(const Value: string): TJsonValue; overload;
    function Put(const Value: TJsonArray): TJsonValue; overload;
    function Put(const Value: TJsonObject): TJsonValue; overload;
    function Put(const Value: TJsonValue): TJsonValue; overload;
    function Put(const Args: array of const; FreeOrphanObj: Boolean = True):
      TJsonArray; overload;
    procedure Delete(const Index: Integer);
    procedure Clear;
    procedure Foreatch(func: TProc<Integer, TJsonValue>);
    function AsInteger: TArray<Integer>;
    function AsString: TArray<string>;
    function AsBoolean: TArray<Boolean>;
    function AsExtended: TArray<Extended>;
  public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TJsonValue read GetItems; default;
  end;

  TJsonPair = class(TJsonBase)
  private
    FName: string;
    FValue: TJsonValue;
    procedure SetName(const Value: string);
    procedure Assign(Source: TJsonBase);
  public
    constructor Create(AOwner: TJsonBase; const AName: string = '');
    destructor Destroy; override;
    procedure Parse(JsonString: string); override;
    function Stringify: string; override;
    function Pretty(IdentLevel: Integer = 0): string; override;
    class function New(Name: string; Value: TJsonEmpty; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: TJsonNull; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: Boolean; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: Integer; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: Extended; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: string; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: TJsonArray; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: TJsonObject; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
    class function New(Name: string; Value: TJsonValue; AOwner: TJsonBase = nil):
      TJsonObject; overload; static;
  public
    property Name: string read FName write SetName;
    property Value: TJsonValue read FValue;
  end;

  TJsonObject = class(TJsonBase)
  private
    FList: TList;
    FAutoAdd: Boolean;
    function GetCount: Integer;
    function GetItems(Index: Integer): TJsonPair;
    function GetValues(Name: string): TJsonValue;
    procedure Assign(Source: TJsonBase);
  public
    constructor Create(AOwner: TJsonBase = nil);
    destructor Destroy; override;
    procedure Parse(JsonString: string); override;
    function Stringify: string; override;
    function Pretty(IdentLevel: Integer = 0): string; override;
    procedure Merge(Addition: TJsonObject);
    function Add(const Name: string = ''): TJsonPair;
    function Insert(const Index: Integer; const Name: string = ''): TJsonPair;
    function Put(const Name: string): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonNull): TJsonValue; overload;
    function Put(const Name: string; const Value: Boolean): TJsonValue; overload;
    function Put(const Name: string; const Value: Integer): TJsonValue; overload;
    function Put(const Name: string; const Value: Extended): TJsonValue; overload;
    function Put(const Name: string; const Value: string): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonArray): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonObject): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonValue): TJsonValue; overload;
    function Put(const Name: string; const Value: array of const): TJsonValue; overload;
    function Put(const Value: TJsonPair): TJsonValue; overload;
    function Find(const Name: string): Integer;
    procedure Delete(const Index: Integer); overload;
    procedure Delete(const Name: string); overload;
    procedure Clear;
  public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TJsonPair read GetItems;
    property Values[Name: string]: TJsonValue read GetValues; default;
    property AutoAdd: Boolean read FAutoAdd write FAutoAdd;
  end;

  TJson = class(TJsonBase)
  private
    FStructType: TJsonStructType;
    FJsonArray: TJsonArray;
    FJsonObject: TJsonObject;
    function GetCount: Integer;
    function GetJsonArray: TJsonArray;
    function GetJsonObject: TJsonObject;
    function GetValues(Name: string): TJsonValue;
    function FixIdent(Data: string): string;
  protected
    procedure CreateArrayIfNone;
    procedure CreateObjectIfNone;
    procedure RaiseIfNone;
    procedure RaiseIfNotArray;
    procedure RaiseIfNotObject;
    procedure CheckJsonArray;
    procedure CheckJsonObject;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Parse(JsonString: string); override;
    function Stringify: string; override;
    function Pretty(IdentLevel: Integer = -1): string; override;
    procedure Assign(Source: TJsonBase); override;
    procedure Delete(const Index: Integer); overload;
    procedure Delete(const Name: string); overload;
    procedure Clear;
    function Get(const Index: Integer): TJsonValue; overload; //for both
    function Get(const Name: string): TJsonValue; overload; //for JsonObject

    //for JsonArray
    function Put(): TJsonValue; overload;
    function Put(const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Value: TJsonNull): TJsonValue; overload;
    function Put(const Value: Boolean): TJsonValue; overload;
    function Put(const Value: Integer): TJsonValue; overload;
    function Put(const Value: Extended): TJsonValue; overload;
    function Put(const Value: string): TJsonValue; overload;
    function Put(const Value: TJsonArray): TJsonValue; overload;
    function Put(const Value: TJsonObject): TJsonValue; overload;
    function Put(const Value: TJsonValue): TJsonValue; overload;
    function Put(const Value: TJson): TJsonValue; overload;

    //for JsonObject
    function Put(const Name: string; const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonNull): TJsonValue; overload;
    function Put(const Name: string; const Value: Boolean): TJsonValue; overload;
    function Put(const Name: string; const Value: Integer): TJsonValue; overload;
    function Put(const Name: string; const Value: Extended): TJsonValue; overload;
    function Put(const Name: string; const Value: string): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonArray): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonObject): TJsonValue; overload;
    function Put(const Name: string; const Value: TJsonValue): TJsonValue; overload;
    function Put(const Name: string; const Value: TJson): TJsonValue; overload;
    function Put(const Name: string; const Value: array of const): TJsonValue; overload;
    function Put(const Value: TJsonPair): TJsonValue; overload;
  public
    property StructType: TJsonStructType read FStructType;
    property JsonObject: TJsonObject read GetJsonObject;
    property JsonArray: TJsonArray read GetJsonArray;
    property Count: Integer read GetCount;
    property Values[Name: string]: TJsonValue read GetValues; default; //for JsonObject

  end;

implementation

function Ident(level: Integer): string;
begin
  if level < 0 then
    exit('');
  Result := string.Create(' ', level * 4);
end;

{ TJsonBase }

function TJsonBase.AnalyzeJsonValueType(const S: string): TJsonValueType;
var
  Len: Integer;
  Number: Extended;
begin
  Result := jvNone;
  Len := Length(S);
  if Len >= 2 then
  begin
    if (S[1] = '{') and (S[Len] = '}') then
      Result := jvObject
    else if (S[1] = '[') and (S[Len] = ']') then
      Result := jvArray
    else if (S[1] = '"') and (S[Len] = '"') then
      Result := jvString
    else if SameText(S, 'null') then
      Result := jvNull
    else if SameText(S, 'true') or SameText(S, 'false') then
      Result := jvBoolean
    else if FixedTryStrToFloat(S, Number) then
      Result := jvNumber;
  end
  else if FixedTryStrToFloat(S, Number) then
    Result := jvNumber;
end;

constructor TJsonBase.Create(AOwner: TJsonBase);
begin
  FOwner := AOwner;
end;

function TJsonBase.Decode(const S: string): string;

  function HexValue(C: Char): Byte;
  begin
    case C of
      '0'..'9':
        Result := Byte(C) - Byte('0');
      'a'..'f':
        Result := (Byte(C) - Byte('a')) + 10;
      'A'..'F':
        Result := (Byte(C) - Byte('A')) + 10;
    else
      raise Exception.Create('Illegal hexadecimal characters "' + C + '"');
    end;
  end;

var
  I: Integer;
  C: Char;
  ubuf: integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    C := S[I];
    Inc(I);
    if C = '\' then
    begin
      C := S[I];
      Inc(I);
      case C of
        'b':
          Result := Result + #8;
        't':
          Result := Result + #9;
        'n':
          Result := Result + #10;
        'f':
          Result := Result + #12;
        'r':
          Result := Result + #13;
        'u':
          begin
            if not TryStrToInt('$' + Copy(S, I, 4), ubuf) then
              raise Exception.Create(format('Invalid unicode \u%s', [Copy(S, I, 4)]));
            result := result + WideChar(ubuf);
            Inc(I, 4);
          end;
      else
        Result := Result + C;
      end;
    end
    else
      Result := Result + C;
  end;
end;

destructor TJsonBase.Destroy;
begin
  inherited Destroy;
end;

function TJsonBase.Encode(const S: string): string;
var
  I, UnicodeValue: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':
        Result := Result + '\' + C;
      '\':
        Result := Result + '\' + C;
      '/':
        Result := Result + '\' + C;
      #8:
        Result := Result + '\b';
      #9:
        Result := Result + '\t';
      #10:
        Result := Result + '\n';
      #12:
        Result := Result + '\f';
      #13:
        Result := Result + '\r';
    else
      if (C < WideChar(32)) or (C > WideChar(127)) then
      begin
        Result := result + '\u';
        UnicodeValue := Ord(C);
        Result := result + lowercase(IntToHex((UnicodeValue and 61440) shr 12, 1));
        Result := result + lowercase(IntToHex((UnicodeValue and 3840) shr 8, 1));
        Result := result + lowercase(IntToHex((UnicodeValue and 240) shr 4, 1));
        Result := result + lowercase(IntToHex((UnicodeValue and 15), 1));
      end
      else
        Result := Result + C;

    end;
  end;
end;

function TJsonBase.GetOwner: TJsonBase;
begin
  Result := FOwner;
end;

function TJsonBase.GetOwnerName: string;
var
  TheOwner: TJsonBase;
begin
  Result := '';
  TheOwner := Owner;
  while True do
  begin
    if not Assigned(TheOwner) then
      Break
    else if TheOwner is TJsonPair then
    begin
      Result := (TheOwner as TJsonPair).Name;
      Break;
    end
    else
      TheOwner := TheOwner.Owner;
  end;
end;

function TJsonBase.IsJsonArray(const S: string): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >= 2) and (S[1] = '[') and (S[Len] = ']');
end;

function TJsonBase.IsJsonBoolean(const S: string): Boolean;
begin
  Result := SameText(lowercase(S), 'true') or SameText(lowercase(S), 'false');
end;

function TJsonBase.IsJsonNull(const S: string): Boolean;
begin
  Result := SameText(S, 'null');
end;

function TJsonBase.IsJsonNumber(const S: string): Boolean;
var
  Number: Extended;
begin
  Result := FixedTryStrToFloat(S, Number);
end;

function TJsonBase.IsJsonObject(const S: string): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >= 2) and (S[1] = '{') and (S[Len] = '}');
end;

function TJsonBase.IsJsonString(const S: string): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >= 2) and (S[1] = '"') and (S[Len] = '"');
end;

procedure TJsonBase.RaiseAssignError(Source: TJsonBase);
var
  SourceClassName: string;
begin
  if Source is TObject then
    SourceClassName := Source.ClassName
  else
    SourceClassName := 'nil';
  RaiseError(Format('assign error: %s to %s', [SourceClassName, ClassName]));
end;

procedure TJsonBase.RaiseError(const Msg: string);
var
  S: string;
begin
  S := Format('<%s>%s', [ClassName, Msg]);
  raise Exception.Create(S);
end;

procedure TJsonBase.RaiseParseError(const JsonString: string);
begin
  RaiseError(Format('"%s" parse error: %s', [GetOwnerName, JsonString]));
end;

procedure TJsonBase.Split(const S: string; const Delimiter: Char; Strings: TStrings);

  function IsPairBegin(C: Char): Boolean;
  begin
    Result := (C = '{') or (C = '[') or (C = '"');
  end;

  function GetPairEnd(C: Char): Char;
  begin
    case C of
      '{':
        Result := '}';
      '[':
        Result := ']';
      '"':
        Result := '"';
    else
      Result := #0;
    end;
  end;

  function MoveToPair(P: PChar): PChar;
  var
    PairBegin, PairEnd: Char;
    C: Char;
  begin
    PairBegin := P^;
    PairEnd := GetPairEnd(PairBegin);
    Result := P;
    while Result^ <> #0 do
    begin
      Inc(Result);
      C := Result^;
      if C = PairEnd then
        Break
      else if (PairBegin = '"') and (C = '\') then
        Inc(Result)
      else if (PairBegin <> '"') and IsPairBegin(C) then
        Result := MoveToPair(Result);
    end;
  end;

var
  PtrBegin, PtrEnd: PChar;
  C: Char;
  StrItem: string;
begin
  PtrBegin := PChar(S);
  PtrEnd := PtrBegin;
  while PtrEnd^ <> #0 do
  begin
    C := PtrEnd^;
    if C = Delimiter then
    begin
      StrItem := Trim(Copy(PtrBegin, 1, PtrEnd - PtrBegin));
      Strings.Add(StrItem);
      PtrBegin := PtrEnd + 1;
      PtrEnd := PtrBegin;
      Continue;
    end
    else if IsPairBegin(C) then
      PtrEnd := MoveToPair(PtrEnd);
    Inc(PtrEnd);
  end;
  StrItem := Trim(Copy(PtrBegin, 1, PtrEnd - PtrBegin));
  if StrItem <> '' then
    Strings.Add(StrItem);
end;

{ TJsonValue }

procedure TJsonValue.Assign(Source: TJsonBase);
var
  Src: TJsonValue;
begin
  Clear;
  if not (Source is TJsonValue) and not (Source is TJsonObject) and not (Source
    is TJsonArray) then
    RaiseAssignError(Source);
  if Source is TJsonObject then
  begin
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
    FObjectValue.Assign(Source);
  end
  else if Source is TJsonArray then
  begin
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
    FArrayValue.Assign(Source);
  end
  else if Source is TJsonValue then
  begin
    Src := Source as TJsonValue;
    FValueType := Src.FValueType;
    case FValueType of
      jvNone, jvNull:
        ;
      jvString:
        FStringValue := Src.FStringValue;
      jvNumber:
        FNumberValue := Src.FNumberValue;
      jvBoolean:
        FBooleanValue := Src.FBooleanValue;
      jvObject:
        begin
          FObjectValue := TJsonObject.Create(Self);
          FObjectValue.Assign(Src.FObjectValue);
        end;
      jvArray:
        begin
          FArrayValue := TJsonArray.Create(Self);
          FArrayValue.Assign(Src.FArrayValue);
        end;
    end;
  end;
end;

procedure TJsonValue.Clear;
begin
  case FValueType of
    jvNone, jvNull:
      ;
    jvString:
      FStringValue := '';
    jvNumber:
      FNumberValue := 0;
    jvBoolean:
      FBooleanValue := False;
    jvObject:
      begin
        FObjectValue.Free;
        FObjectValue := nil;
      end;
    jvArray:
      begin
        FArrayValue.Free;
        FArrayValue := nil;
      end;
  end;
  FValueType := jvNone;
end;

constructor TJsonValue.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FStringValue := '';
  FNumberValue := 0;
  FBooleanValue := False;
  FObjectValue := nil;
  FArrayValue := nil;
  FValueType := jvNone;
end;

destructor TJsonValue.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TJsonValue.GetAsArray: TJsonArray;
begin
  if IsEmpty then
  begin
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
  end;
  if FValueType <> jvArray then
    RaiseValueTypeError(jvArray);
  Result := FArrayValue;
end;

function TJsonValue.GetAsBoolean: Boolean;
begin
  Result := False;
  case FValueType of
    jvNone, jvNull:
      Result := False;
    jvString:
      Result := SameText(lowercase(FStringValue), 'true');
    jvNumber:
      Result := (FNumberValue <> 0);
    jvBoolean:
      Result := FBooleanValue;
    jvObject, jvArray:
      RaiseValueTypeError(jvBoolean);
  end;
end;

function TJsonValue.GetAsInteger: Integer;
begin
  Result := 0;
  case FValueType of
    jvNone, jvNull:
      Result := 0;
    jvString:
      Result := Trunc(StrToInt(FStringValue));
    jvNumber:
      Result := Trunc(FNumberValue);
    jvBoolean:
      Result := Ord(FBooleanValue);
    jvObject, jvArray:
      RaiseValueTypeError(jvNumber);
  end;
end;

function TJsonValue.GetAsNumber: Extended;
begin
  Result := 0;
  case FValueType of
    jvNone, jvNull:
      Result := 0;
    jvString:
      Result := FixedStrToFloat(FStringValue);
    jvNumber:
      Result := FNumberValue;
    jvBoolean:
      Result := Ord(FBooleanValue);
    jvObject, jvArray:
      RaiseValueTypeError(jvNumber);
  end;
end;

function TJsonValue.GetAsObject: TJsonObject;
begin
  if IsEmpty then
  begin
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
  end;
  if FValueType <> jvObject then
    RaiseValueTypeError(jvObject);
  Result := FObjectValue;
end;

function TJsonValue.GetAsString: string;
const
  BooleanStr: array[Boolean] of string = ('false', 'true');
begin
  Result := '';
  case FValueType of
    jvNone, jvNull:
      Result := '';
    jvString:
      Result := FStringValue;
    jvNumber:
      Result := FixedFloatToStr(FNumberValue);
    jvBoolean:
      Result := BooleanStr[FBooleanValue];
    jvObject, jvArray:
      RaiseValueTypeError(jvString);
  end;
end;

function TJsonValue.GetIsEmpty: Boolean;
begin
  Result := (FValueType = jvNone);
end;

function TJsonValue.GetIsNull: Boolean;
begin
  Result := (FValueType = jvNull);
end;

procedure TJsonValue.Parse(JsonString: string);
begin
  Clear;
  JsonString := Trim(JsonString);
  FValueType := AnalyzeJsonValueType(JsonString);
  case FValueType of
    jvNone:
      RaiseParseError(JsonString);
    jvNull:
      ;
    jvString:
      FStringValue := Decode(Copy(JsonString, 2, Length(JsonString) - 2));
    jvNumber:
      FNumberValue := FixedStrToFloat(JsonString);
    jvBoolean:
      FBooleanValue := SameText(JsonString, 'true');
    jvObject:
      begin
        FObjectValue := TJsonObject.Create(Self);
        FObjectValue.Parse(JsonString);
      end;
    jvArray:
      begin
        FArrayValue := TJsonArray.Create(Self);
        FArrayValue.Parse(JsonString);
      end;
  end;
end;

function TJsonValue.Pretty(IdentLevel: Integer): string;
const
  StrBoolean: array[Boolean] of string = ('false', 'true');
begin
  Result := '';
  case FValueType of
    jvNone, jvNull:
      Result := Ident(IdentLevel + 1) + 'null';
    jvString:
      Result := ident(IdentLevel + 1) + '"' + Encode(FStringValue) + '"';
    jvNumber:
      Result := ident(IdentLevel + 1) + FixedFloatToStr(FNumberValue);
    jvBoolean:
      Result := ident(IdentLevel + 1) + StrBoolean[FBooleanValue];
    jvObject:
      Result := FObjectValue.Pretty(IdentLevel + 1);
    jvArray:
      Result := FArrayValue.Pretty(IdentLevel + 1);
  end;
end;

procedure TJsonValue.RaiseValueTypeError(const AsValueType: TJsonValueType);
const
  StrJsonValueType: array[TJsonValueType] of string = ('jvNone', 'jvNull',
    'jvString', 'jvNumber', 'jvBoolean', 'jvObject', 'jvArray');
var
  S: string;
begin
  S := Format('"%s" value type error: %s to %s', [GetOwnerName, StrJsonValueType
    [FValueType], StrJsonValueType[AsValueType]]);
  RaiseError(S);
end;

procedure TJsonValue.SetAsArray(const Value: TJsonArray);
begin
  if FValueType <> jvArray then
  begin
    Clear;
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
  end;
  FArrayValue.Assign(Value);
end;

procedure TJsonValue.SetAsBoolean(const Value: Boolean);
begin
  if FValueType <> jvBoolean then
  begin
    Clear;
    FValueType := jvBoolean;
  end;
  FBooleanValue := Value;
end;

procedure TJsonValue.SetAsInteger(const Value: Integer);
begin
  SetAsNumber(Value);
end;

procedure TJsonValue.SetAsNumber(const Value: Extended);
begin
  if FValueType <> jvNumber then
  begin
    Clear;
    FValueType := jvNumber;
  end;
  FNumberValue := Value;
end;

procedure TJsonValue.SetAsObject(const Value: TJsonObject);
begin
  if FValueType <> jvObject then
  begin
    Clear;
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
  end;
  FObjectValue.Assign(Value);
end;

procedure TJsonValue.SetAsString(const Value: string);
begin
  if FValueType <> jvString then
  begin
    Clear;
    FValueType := jvString;
  end;
  FStringValue := Value;
end;

procedure TJsonValue.SetIsEmpty(const Value: Boolean);
const
  EmptyValueType: array[Boolean] of TJsonValueType = (jvNull, jvNone);
begin
  if FValueType <> EmptyValueType[Value] then
  begin
    Clear;
    FValueType := EmptyValueType[Value];
  end;
end;

procedure TJsonValue.SetIsNull(const Value: Boolean);
const
  NullValueType: array[Boolean] of TJsonValueType = (jvNone, jvNull);
begin
  if FValueType <> NullValueType[Value] then
  begin
    Clear;
    FValueType := NullValueType[Value];
  end;
end;

function TJsonValue.Stringify: string;
const
  StrBoolean: array[Boolean] of string = ('false', 'true');
begin
  Result := '';
  case FValueType of
    jvNone, jvNull:
      Result := 'null';
    jvString:
      Result := '"' + Encode(FStringValue) + '"';
    jvNumber:
      Result := FixedFloatToStr(FNumberValue);
    jvBoolean:
      Result := StrBoolean[FBooleanValue];
    jvObject:
      Result := FObjectValue.Stringify;
    jvArray:
      Result := FArrayValue.Stringify;
  end;
end;

{ TJsonArray }

function TJsonArray.Add: TJsonValue;
begin
  Result := TJsonValue.Create(Self);
  FList.Add(Result);
end;

function TJsonArray.AsBoolean: TArray<Boolean>;
var
  Acount: Integer;
  buffer: TArray<Boolean>;
begin
  if count = 0 then
    exit;

  SetLength(buffer, count);

  Acount := 0;
  Foreatch(
    procedure(Index: integer; Item: TJsonValue)
    begin
      if Item.ValueType = jvBoolean then
      begin
        buffer[Acount] := Item.AsBoolean;
        inc(Acount);
      end;
    end);
  SetLength(buffer, Acount);
  Result := buffer;
end;

function TJsonArray.AsExtended: TArray<Extended>;
var
  Acount: Integer;
  buffer: TArray<Extended>;
begin
  if count = 0 then
    exit;

  SetLength(buffer, count);

  Acount := 0;
  Foreatch(
    procedure(Index: integer; Item: TJsonValue)
    begin
      if Item.ValueType = jvNumber then
      begin
        buffer[Acount] := Item.AsNumber;
        inc(Acount);
      end;
    end);
  SetLength(buffer, Acount);
  Result := buffer;
end;

function TJsonArray.AsInteger: TArray<Integer>;
var
  Acount: Integer;
  buffer: TArray<Integer>;
begin
  if count = 0 then
    exit;

  SetLength(buffer, count);

  Acount := 0;
  Foreatch(
    procedure(Index: integer; Item: TJsonValue)
    begin
      if Item.ValueType = jvNumber then
      begin
        buffer[Acount] := Item.AsInteger;
        inc(Acount);
      end;
    end);
  SetLength(buffer, Acount);
  Result := buffer;
end;

procedure TJsonArray.Assign(Source: TJsonBase);
var
  Src: TJsonArray;
  I: Integer;
begin
  Clear;
  if not (Source is TJsonArray) then
    RaiseAssignError(Source);
  Src := Source as TJsonArray;
  for I := 0 to Src.Count - 1 do
    Add.Assign(Src[I]);
end;

function TJsonArray.AsString: TArray<string>;
var
  Acount: Integer;
  buffer: TArray<string>;
begin
  if count = 0 then
    exit;

  SetLength(buffer, count);

  Acount := 0;
  Foreatch(
    procedure(Index: integer; Item: TJsonValue)
    begin
      if Item.ValueType = jvString then
      begin
        buffer[Acount] := Item.Asstring;
        inc(Acount);
      end;
    end);
  SetLength(buffer, Acount);
  Result := buffer;
end;

procedure TJsonArray.Clear;
var
  I: Integer;
  Item: TJsonValue;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonValue(FList[I]);
    Item.Free;
  end;
  FList.Clear;
end;

constructor TJsonArray.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FList := TList.Create;
end;

procedure TJsonArray.Delete(const Index: Integer);
var
  Item: TJsonValue;
begin
  Item := TJsonValue(FList[Index]);
  Item.Free;
  FList.Delete(Index);
end;

destructor TJsonArray.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

procedure TJsonArray.Foreatch(func: TProc<Integer, TJsonValue>);
var
  i: Integer;
begin
  if Assigned(func) then
    for i := 0 to FList.Count - 1 do
      func(i, TJsonValue(FList[i]));
end;

function TJsonArray.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TJsonArray.GetItems(Index: Integer): TJsonValue;
begin
  Result := TJsonValue(FList[Index]);
end;

function TJsonArray.Insert(const Index: Integer): TJsonValue;
begin
  Result := TJsonValue.Create(Self);
  FList.Insert(Index, Result);
end;

procedure TJsonArray.Merge(Addition: TJsonArray);
var
  I: Integer;
begin
  for I := 0 to Addition.Count - 1 do
    Add.Assign(Addition[I]);
end;

procedure TJsonArray.Parse(JsonString: string);
var
  I: Integer;
  S: string;
  List: TStringList;
  Item: TJsonValue;
begin
  Clear;
  JsonString := Trim(JsonString);
  if not IsJsonArray(JsonString) then
    RaiseParseError(JsonString);
  S := Trim(Copy(JsonString, 2, Length(JsonString) - 2));
  List := TStringList.Create;
  try
    Split(S, ',', List);
    for I := 0 to List.Count - 1 do
    begin
      Item := Add;
      Item.Parse(List[I]);
    end;
  finally
    List.Free;
  end;
end;

function TJsonArray.Pretty(IdentLevel: Integer): string;
var
  I: Integer;
  Item: TJsonValue;
  ItemList: string;
begin
  if FList.Count = 0 then
    Exit(Ident(IdentLevel) + '[]');
  Result := Ident(IdentLevel) + '[' + #10;
  ItemList := '';
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonValue(FList[I]);
    if I > 0 then
      ItemList := ItemList + ','#10;
    ItemList := ItemList + Item.Pretty(IdentLevel);
  end;
  Result := Result + ItemList + #10 + Ident(IdentLevel) + ']';
end;

function TJsonArray.Put(const Value: Boolean): TJsonValue;
begin
  Result := Add;
  Result.AsBoolean := Value;
end;

function TJsonArray.Put(const Value: Integer): TJsonValue;
begin
  Result := Add;
  Result.AsInteger := Value;
end;

function TJsonArray.Put(const Value: TJsonEmpty): TJsonValue;
begin
  Result := Add;
  Result.IsEmpty := True;
end;

function TJsonArray.Put(const Value: TJsonNull): TJsonValue;
begin
  Result := Add;
  Result.IsNull := True;
end;

function TJsonArray.Put(const Value: Extended): TJsonValue;
begin
  Result := Add;
  Result.AsNumber := Value;
end;

function TJsonArray.Put(const Value: TJsonObject): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Put(const Value: TJsonValue): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Put(const Value: string): TJsonValue;
begin
  Result := Add;
  Result.AsString := Value;
end;

function TJsonArray.Put(const Value: TJsonArray): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Stringify: string;
var
  I: Integer;
  Item: TJsonValue;
begin
  Result := '[';
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonValue(FList[I]);
    if I > 0 then
      Result := Result + ',';
    Result := Result + Item.Stringify;
  end;
  Result := Result + ']';
end;

function TJsonArray.Put(const Args: array of const; FreeOrphanObj: Boolean): TJsonArray;
var
  rec: TVarRec;
  JsonObj: TJsonObject;
  JsonVal: TJsonValue;
begin
  Result := self;

  for rec in Args do
  begin
    with rec do
    begin
      case VType of
        vtInteger:
          Put(VInteger);
        vtBoolean:
          Put(VBoolean);
        vtChar, vtWideChar:
          Put(VChar);
        vtExtended:
          Put(VExtended^);
        vtString:
          Put(VString^);
        vtPChar:
          Put(VPChar);
        vtPointer:
          if VPointer = nil then
            Put(null);
        vtObject:
          begin
            if VObject.ClassName = 'TJsonValue' then
            begin
              JsonVal := TJsonValue(VObject);
              Put(JsonVal);
              if (JsonVal.Owner = nil) and (FreeOrphanObj) then
                JsonVal.Free;
              Continue;
            end;
            if VObject.ClassName = 'TJsonObject' then
            begin
              JsonObj := TJsonObject(VObject);
              Put(JsonObj);
              if (JsonObj.Owner = nil) and (FreeOrphanObj) then
                JsonObj.Free;
              Continue;
            end;
          end;
        vtAnsiString:
          Put(string(VAnsiString));
        vtCurrency:
          Put(VCurrency^);
        vtVariant:
          Put(string(VVariant^));
        vtInt64:
          Put(VInt64^);
        vtUnicodeString:
          Put(string(VUnicodeString));
      end;
    end;
  end;
end;

function TJsonArray.Put: TJsonValue;
begin
  Result := put(empty);
end;

{ TJsonPair }

procedure TJsonPair.Assign(Source: TJsonBase);
var
  Src: TJsonPair;
begin
  if not (Source is TJsonPair) then
    RaiseAssignError(Source);
  Src := Source as TJsonPair;
  FName := Src.FName;
  FValue.Assign(Src.FValue);
end;

constructor TJsonPair.Create(AOwner: TJsonBase; const AName: string);
begin
  inherited Create(AOwner);
  FName := AName;
  FValue := TJsonValue.Create(Self);
end;

destructor TJsonPair.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

class function TJsonPair.New(Name: string; Value: TJsonEmpty; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: TJsonNull; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: Boolean; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: Extended; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: Integer; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: string; AOwner: TJsonBase =
  nil): TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

procedure TJsonPair.Parse(JsonString: string);
var
  List: TStringList;
  StrName: string;
begin
  List := TStringList.Create;
  try
    Split(JsonString, ':', List);
    if List.Count <> 2 then
      RaiseParseError(JsonString);
    StrName := List[0];
    if not IsJsonString(StrName) then
      RaiseParseError(StrName);
    FName := Decode(Copy(StrName, 2, Length(StrName) - 2));
    FValue.Parse(List[1]);
  finally
    List.Free;
  end;
end;

function TJsonPair.Pretty(IdentLevel: Integer): string;
begin
  Result := Ident(IdentLevel) + Format('"%s": %s', [Encode(FName), FValue.Pretty()]);
end;

procedure TJsonPair.SetName(const Value: string);
begin
  FName := Value;
end;

function TJsonPair.Stringify: string;
begin
  Result := Format('"%s":%s', [Encode(FName), FValue.Stringify]);
end;

class function TJsonPair.New(Name: string; Value: TJsonArray; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: TJsonObject; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

class function TJsonPair.New(Name: string; Value: TJsonValue; AOwner: TJsonBase):
  TJsonObject;
begin
  Result := TJsonObject.Create(AOwner);
  Result.Put(Name, Value);
end;

{ TJsonObject }

function TJsonObject.Add(const Name: string): TJsonPair;
begin
  Result := TJsonPair.Create(Self, Name);
  FList.Add(Result);
end;

procedure TJsonObject.Assign(Source: TJsonBase);
var
  Src: TJsonObject;
  I: Integer;
begin
  Clear;
  if not (Source is TJsonObject) then
    RaiseAssignError(Source);
  Src := Source as TJsonObject;
  for I := 0 to Src.Count - 1 do
    Add.Assign(Src.Items[I]);
end;

procedure TJsonObject.Clear;
var
  I: Integer;
  Item: TJsonPair;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonPair(FList[I]);
    Item.Free;
  end;
  FList.Clear;
end;

constructor TJsonObject.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FList := TList.Create;
  FAutoAdd := True;
end;

procedure TJsonObject.Delete(const Index: Integer);
var
  Item: TJsonPair;
begin
  Item := TJsonPair(FList[Index]);
  Item.Free;
  FList.Delete(Index);
end;

procedure TJsonObject.Delete(const Name: string);
var
  Index: Integer;
begin
  Index := Find(Name);
  if Index < 0 then
    RaiseError(Format('"%s" not found', [Name]));
  Delete(Index);
end;

destructor TJsonObject.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TJsonObject.Find(const Name: string): Integer;
var
  I: Integer;
  Pair: TJsonPair;
begin
  Result := -1;
  for I := 0 to FList.Count - 1 do
  begin
    Pair := TJsonPair(FList[I]);
    if SameText(Name, Pair.Name) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TJsonObject.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TJsonObject.GetItems(Index: Integer): TJsonPair;
begin
  Result := TJsonPair(FList[Index]);
end;

function TJsonObject.GetValues(Name: string): TJsonValue;
var
  Index: Integer;
  Pair: TJsonPair;
begin
  Index := Find(Name);
  if Index < 0 then
  begin
    if not FAutoAdd then
      RaiseError(Format('%s not found', [Name]));
    Pair := Add(Name);
  end
  else
    Pair := TJsonPair(FList[Index]);
  Result := Pair.Value;
end;

function TJsonObject.Insert(const Index: Integer; const Name: string): TJsonPair;
begin
  Result := TJsonPair.Create(Self, Name);
  FList.Insert(Index, Result);
end;

procedure TJsonObject.Merge(Addition: TJsonObject);
var
  I: Integer;
begin
  for I := 0 to Addition.Count - 1 do
    Add.Assign(Addition.Items[I]);
end;

procedure TJsonObject.Parse(JsonString: string);
var
  I: Integer;
  S: string;
  List: TStringList;
  Item: TJsonPair;
begin
  Clear;
  JsonString := Trim(JsonString);
  if not IsJsonObject(JsonString) then
    RaiseParseError(JsonString);
  S := Trim(Copy(JsonString, 2, Length(JsonString) - 2));
  List := TStringList.Create;
  try
    Split(S, ',', List);
    for I := 0 to List.Count - 1 do
    begin
      Item := Add;
      Item.Parse(List[I]);
    end;
  finally
    List.Free;
  end;
end;

function TJsonObject.Pretty(IdentLevel: Integer): string;
var
  I: Integer;
  Item: TJsonPair;
  ItemList: string;
begin
  if FList.Count = 0 then
  begin
    exit(Ident(IdentLevel) + '{}');
  end;

  // short single objects
  if (FList.Count = 1) then
  begin
    Item := TJsonPair(FList[0]);
    if not (Item.Value.FValueType in [jvArray, jvArray]) then
      exit(Ident(IdentLevel) + '{ ' + Item.Pretty(-1) + ' }');
  end;

  Result := Ident(IdentLevel) + '{'#10;
  ItemList := '';

  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonPair(FList[I]);
    if I > 0 then
      ItemList := ItemList + ','#10;
    ItemList := ItemList + Item.Pretty(IdentLevel + 1);
  end;
  Result := Result + ItemList + #10 + Ident(IdentLevel) + '}';
end;

function TJsonObject.Put(const Name: string; const Value: Integer): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.AsInteger := Value;
end;

function TJsonObject.Put(const Name: string; const Value: Extended): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.AsNumber := Value;
end;

function TJsonObject.Put(const Name: string; const Value: Boolean): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.AsBoolean := Value;
end;

function TJsonObject.Put(const Name: string; const Value: TJsonEmpty): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.IsEmpty := True;
end;

function TJsonObject.Put(const Name: string; const Value: TJsonNull): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.IsNull := True;
end;

function TJsonObject.Put(const Name: string; const Value: TJsonValue): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Put(const Value: TJsonPair): TJsonValue;
var
  Pair: TJsonPair;
begin
  Pair := Add;
  Pair.Assign(Value);
  Result := Pair.Value;
end;

function TJsonObject.Put(const Name: string; const Value: array of const): TJsonValue;
begin
  Result := Put(Name, empty);
  Result.AsArray.Put(Value);
end;

function TJsonObject.Put(const Name: string): TJsonValue;
begin
  Result := put(Name, empty);
end;

function TJsonObject.Put(const Name: string; const Value: TJsonObject): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Put(const Name, Value: string): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.AsString := Value;
end;

function TJsonObject.Put(const Name: string; const Value: TJsonArray): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Stringify: string;
var
  I: Integer;
  Item: TJsonPair;
begin
  Result := '{';
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonPair(FList[I]);
    if I > 0 then
      Result := Result + ',';
    Result := Result + Item.Stringify;
  end;
  Result := Result + '}';
end;

{ TJson }

procedure TJson.Assign(Source: TJsonBase);
begin
  Clear;
  if Source is TJson then
  begin
    case (Source as TJson).FStructType of
      jsNone:
        ;
      jsArray:
        begin
          CreateArrayIfNone;
          FJsonArray.Assign((Source as TJson).FJsonArray);
        end;
      jsObject:
        begin
          CreateObjectIfNone;
          FJsonObject.Assign((Source as TJson).FJsonObject);
        end;
    end;
  end
  else if Source is TJsonArray then
  begin
    CreateArrayIfNone;
    FJsonArray.Assign(Source);
  end
  else if Source is TJsonObject then
  begin
    CreateObjectIfNone;
    FJsonObject.Assign(Source);
  end
  else if Source is TJsonValue then
  begin
    if (Source as TJsonValue).ValueType = jvArray then
    begin
      CreateArrayIfNone;
      FJsonArray.Assign((Source as TJsonValue).AsArray);
    end
    else if (Source as TJsonValue).ValueType = jvObject then
    begin
      CreateObjectIfNone;
      FJsonObject.Assign((Source as TJsonValue).AsObject);
    end
    else
      RaiseAssignError(Source);
  end
  else
    RaiseAssignError(Source);
end;

procedure TJson.CheckJsonArray;
begin
  CreateArrayIfNone;
  RaiseIfNotArray;
end;

procedure TJson.CheckJsonObject;
begin
  CreateObjectIfNone;
  RaiseIfNotObject;
end;

procedure TJson.Clear;
begin
  case FStructType of
    jsNone:
      ;
    jsArray:
      begin
        FJsonArray.Free;
        FJsonArray := nil;
      end;
    jsObject:
      begin
        FJsonObject.Free;
        FJsonObject := nil;
      end;
  end;
  FStructType := jsNone;
end;

constructor TJson.Create;
begin
  inherited Create(nil);
  FStructType := jsNone;
  FJsonArray := nil;
  FJsonObject := nil;
end;

procedure TJson.CreateArrayIfNone;
begin
  if FStructType = jsNone then
  begin
    FStructType := jsArray;
    FJsonArray := TJsonArray.Create(Self);
  end;
end;

procedure TJson.CreateObjectIfNone;
begin
  if FStructType = jsNone then
  begin
    FStructType := jsObject;
    FJsonObject := TJsonObject.Create(Self);
  end;
end;

procedure TJson.Delete(const Index: Integer);
begin
  RaiseIfNone;
  case FStructType of
    jsArray:
      FJsonArray.Delete(Index);
    jsObject:
      FJsonObject.Delete(Index);
  end;
end;

procedure TJson.Delete(const Name: string);
begin
  RaiseIfNotObject;
  FJsonObject.Delete(Name);
end;

destructor TJson.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TJson.FixIdent(Data: string): string;
var
  WrongIdent: string;
begin
  WrongIdent := ':' + Ident(1);
  Result := Data.Replace(WrongIdent, ': ', [rfReplaceAll]);
end;

function TJson.Get(const Index: Integer): TJsonValue;
begin
  Result := nil;
  RaiseIfNone;
  case FStructType of
    jsArray:
      Result := FJsonArray.Items[Index];
    jsObject:
      Result := FJsonObject.Items[Index].Value;
  end;
end;

function TJson.Get(const Name: string): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Values[Name];
end;

function TJson.GetCount: Integer;
begin
  case FStructType of
    jsArray:
      Result := FJsonArray.Count;
    jsObject:
      Result := FJsonObject.Count;
  else
    Result := 0;
  end;
end;

function TJson.GetJsonArray: TJsonArray;
begin
  CheckJsonArray;
  Result := FJsonArray;
end;

function TJson.GetJsonObject: TJsonObject;
begin
  CheckJsonObject;
  Result := FJsonObject;
end;

function TJson.GetValues(Name: string): TJsonValue;
begin
  Result := Get(Name);
end;

procedure TJson.Parse(JsonString: string);
begin
  Clear;
  JsonString := Trim(JsonString);
  if IsJsonArray(JsonString) then
  begin
    CreateArrayIfNone;
    FJsonArray.Parse(JsonString);
  end
  else if IsJsonObject(JsonString) then
  begin
    CreateObjectIfNone;
    FJsonObject.Parse(JsonString);
  end
  else
    RaiseParseError(JsonString);
end;

function TJson.Pretty(IdentLevel: Integer): string;
begin
  case FStructType of
    jsArray:
      Result := FJsonArray.Pretty(IdentLevel + 1);
    jsObject:
      Result := FJsonObject.Pretty(IdentLevel + 1);
  else
    Result := '';
  end;
  Result := FixIdent(Result);
end;

function TJson.Put(const Value: Integer): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: Extended): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: Boolean): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonEmpty): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonNull): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: string): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonValue): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonObject): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonArray): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Name: string; const Value: Integer): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: Extended): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: Boolean): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: TJsonEmpty): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: TJsonNull): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: TJsonValue): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Value: TJsonPair): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Value);
end;

function TJson.Put(const Name: string; const Value: array of const): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put: TJsonValue;
begin
  Result := Put(empty);
end;

function TJson.Put(const Name: string; const Value: TJsonObject): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name, Value: string): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: string; const Value: TJsonArray): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Value: TJson): TJsonValue;
begin
  CheckJsonArray;
  case Value.FStructType of
    jsArray:
      Result := Put(Value.FJsonArray);
    jsObject:
      Result := Put(Value.FJsonObject);
  else
    Result := nil;
  end;
end;

function TJson.Put(const Name: string; const Value: TJson): TJsonValue;
begin
  CheckJsonObject;
  case Value.FStructType of
    jsArray:
      Result := Put(Name, Value.FJsonArray);
    jsObject:
      Result := Put(Name, Value.FJsonObject);
  else
    Result := nil;
  end;
end;

procedure TJson.RaiseIfNone;
begin
  if FStructType = jsNone then
    RaiseError('json struct type is jsNone');
end;

procedure TJson.RaiseIfNotArray;
begin
  if FStructType <> jsArray then
    RaiseError('json struct type is not jsArray');
end;

procedure TJson.RaiseIfNotObject;
begin
  if FStructType <> jsObject then
    RaiseError('json struct type is not jsObject');
end;

function TJson.Stringify: string;
begin
  case FStructType of
    jsArray:
      Result := FJsonArray.Stringify;
    jsObject:
      Result := FJsonObject.Stringify;
  else
    Result := '';
  end;
end;

end.

