unit JsonsUtilsEx;

interface

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$DEFINE LINEBREAKJSONFORMAT} //Desactivate for a non "minimal better human-readable format".

uses SysUtils;

function FixedFloatToStr(const Value: Extended): string;
function FixedTryStrToFloat(const S: string; out Value: Extended): Boolean;
function FixedStrToFloat(const S: string): Extended;

Type
  TObjectDynArray = array of TObject;
  TStringDynArray = array of string;
  TIntegerDynArray = array of Integer;

Const
  GLB_JSON_STD_DECIMALSEPARATOR = '.';
Var
  JsonsUtils_GLB_DECIMALSEPARATOR : Char;

implementation

Uses TypInfo,
     Math,
     DateUtils;

const
  MAX_SAFE_INTEGER  = 9007199254740991;
Type
  PPPTypeInfo = ^PPTypeInfo;


//JSON date base conversion utility : taken "as is" from but quite incomplete. Will be replaced. TODO.

function ZeroFillStr(Number, Size : integer) : String;
begin
  Result := IntToStr(Number);
  while length(Result) < Size do
    Result := '0'+Result;
end;

function JSONDateToString(aDate : TDateTime) : String;
begin
  Result := '"'+ZeroFillStr(YearOf(aDate),4)+'-'+
            ZeroFillStr(MonthOf(aDate),2)+'-'+
            ZeroFillStr(DayOf(aDate),2)+'T'+
            ZeroFillStr(HourOf(aDate),2)+':'+
            ZeroFillStr(MinuteOf(aDate),2)+':'+
            ZeroFillStr(SecondOf(aDate),2)+'.'+
            ZeroFillStr(SecondOf(aDate),3)+'Z"';
end;

function JSONStringToDate(aDate : String) : TDateTime;
begin
  Result :=
    EncodeDateTime(
      StrToInt(Copy(aDate,1,4)),
      StrToInt(Copy(aDate,6,2)),
      StrToInt(Copy(aDate,9,2)),
      StrToInt(Copy(aDate,12,2)),
      StrToInt(Copy(aDate,15,2)),
      StrToInt(Copy(aDate,18,2)),
      StrToInt(Copy(aDate,21,3)));
end;

function JSONStringIsCompatibleDate(aJSONDate : String) : boolean;
var ldummy: integer;
    lval, lnum : Boolean;
begin
  lval := TryStrToInt(Copy(aJSONDate,1,4),ldummy) and  TryStrToInt(Copy(aJSONDate,6,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,9,2),ldummy) and  TryStrToInt(Copy(aJSONDate,12,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,15,2),ldummy) and TryStrToInt(Copy(aJSONDate,18,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,21,3),ldummy);

  lnum := (Length(aJSONDate)=24) and
            (aJSONDate[5] = '-') and
            (aJSONDate[8] = '-') and
            (aJSONDate[11] = 'T') and
            (aJSONDate[14] = ':') and
            (aJSONDate[17] = ':') and
            (aJSONDate[20] = '.') and
            (aJSONDate[24] = 'Z');

  Result := lval and lNum;
end;


{**
 * Fixed FloatToStr to convert DecimalSeparator to dot (.) decimal separator, FloatToStr returns
 * DecimalSeparator as decimal separator, but JSON uses dot (.) as decimal separator.
 *}
function GetDecimalSeparator : Char;
  {$IFDEF FPC}
var
  LFormatSettings: TFormatSettings;
  {$ENDIF}
begin
  {$IFNDEF FPC}
  Result :=  FormatSettings.DecimalSeparator;
  {$ELSE}
  LFormatSettings := DefaultFormatSettings;
  Result :=  LFormatSettings.DecimalSeparator;
  {$ENDIF}
end;


function FixedFloatToStr(const Value:Extended):string;
var
  lS : string;
begin
  if Abs(Value)<=MAX_SAFE_INTEGER then
  begin
    lS := FloatToStr(Frac(Value));
    if lS='0' then
    begin
      Result := IntToStr(Int64(Trunc(Value)));
      Exit;
    end;
  end;
  lS := FloatToStr(Value);
  if JsonsUtils_GLB_DECIMALSEPARATOR = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    Result := LS;
  end
  else
  begin
    Result := StringReplace( lS,
                             JsonsUtils_GLB_DECIMALSEPARATOR,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             [rfReplaceAll]);
  end;
end;

{**
 * Fixed TryStrToFloat to convert dot (.) decimal separator to DecimalSeparator, TryStrToFloat expects
 * decimal separator to be DecimalSeparator, but JSON uses dot (.) as decimal separator.
 *}
function FixedTryStrToFloat(const S: string; out Value: Extended): Boolean;
var
  FixedS: string;
begin
  if JsonsUtils_GLB_DECIMALSEPARATOR = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    Result := TryStrToFloat(S, Value);
  end
  else
  begin
    FixedS := StringReplace( S,
                             JsonsUtils_GLB_DECIMALSEPARATOR,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             [rfReplaceAll]);
    Result := TryStrToFloat(FixedS, Value);
  end;
end;

{**
 * Fixed StrToFloat to convert dot (.) decimal separator to DecimalSeparator, StrToFloat expects
 * decimal separator to be DecimalSeparator, but JSON uses dot (.) as decimal separator.
 *}
function FixedStrToFloat(const S: string): Extended;
var
  FixedS: string;
begin
  if JsonsUtils_GLB_DECIMALSEPARATOR = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    if not TryStrToFloat(S,Result) then Result := NAN;
  end
  else
  begin
    FixedS := StringReplace( S,
                             JsonsUtils_GLB_DECIMALSEPARATOR,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             [rfReplaceAll]);
    if not TryStrToFloat(FixedS,Result) then Result := NAN;
  end;
end;

function InArray(Str : string; ary : array of String) : boolean;
var
  i: Integer;
begin
  Result := Length(ary)=0;
  for i := 0 to Length(ary) - 1 do
  begin
    if CompareText(ary[i],Str) = 0 then
    begin
      Result := True;
      break;
    end;
  end;
end;

Initialization

JsonsUtils_GLB_DECIMALSEPARATOR := GetDecimalSeparator;

Finalization

end.
