json4delphi
===========

JSON for Delphi, support for older versions of Delphi (6 or above)

Object-pascal native code, using classes only TList, TStrings and TStringList

Example:

var Json: TJson;

//put
Json.Put('field1', null);
Json.Put('field2', True);
Json.Put('field3', 3.14);
Json.Put('field4', 'hello world');

//another way
Json['field5'].AsBoolean := False;
Json['field6'].AsString := 'hello world';

//get
Str := Json['field4'].AsString;

//parse
Json.Parse('{"a":1}');

//stringify
Str := Json.Stringify;
