program TestJson2;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Jsons in '..\src\Jsons.pas';

procedure RunTest;
var
  Json: TJson;
  Str: string;
begin
  Json := TJson.Create;

  try

    Json.Put('null-field', null);
    Json.Put('boolean-field-true', True);

    Json['boolean-field-false'].AsBoolean := not Json.Get('boolean-field-true').AsBoolean;
    Json['number-field'].AsNumber := 3.1415926535;
    Json['number-field-integer'].AsInteger := Json['number-field'].AsInteger;
    Json['string-field'].AsString := 'Hello world';

    Json.Put('array-field', [nil, False, True, 299792458, 2.7182818284,
      'The magic words are squeamish ossifrage', TJsonPair.New('array-object-field-1',
      null), TJsonPair.New('array-object-field-2', 'json4delphi')]);

    Json['array-field'].AsArray.Foreatch(
      procedure(Index: Integer; Item: TJsonValue)
      begin
        Writeln(Item.Stringify);
      end);

    Writeln;

    for Str in Json['array-field'].AsArray.AsString do
    begin
      Writeln(Str);
    end;

    Writeln;

    with Json.Put('object-field', empty).AsObject do
    begin
      Put('object-field-1', True);
      Put('object-field-2', 6.6260755e-34);
      Put('object-field-3');
    end;

    Str := Json.Pretty;
    Writeln(Str);
  finally
    Json.Free;
  end;
end;

begin
  RunTest;
  ReadLn;
end.

