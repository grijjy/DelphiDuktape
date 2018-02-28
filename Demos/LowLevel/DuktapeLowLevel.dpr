program DuktapeLowLevel;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Duktape.Api in '..\..\Duktape.Api.pas';

function NativePrint(AContext: PDukContext): TDukRet; cdecl;
var
  S: UTF8String;
begin
  { Join all arguments together with spaces between them. }
  duk_push_string(AContext, ' ');
  duk_insert(AContext, 0);
  duk_join(AContext, duk_get_top(AContext) - 1);

  { Get result and output to console }
  S := UTF8String(duk_safe_to_string(AContext, -1));
  WriteLn(S);

  { "print" function does not return a value. }
  Result := 0;
end;

function NativeAdd(AContext: PDukContext): TDukRet; cdecl;
var
  Sum: Double;
begin
  { Add two arguments together }
  Sum := duk_to_number(AContext, 0) + duk_to_number(AContext, 1);

  { Push result }
  duk_push_number(AContext, Sum);

  { "add" function returns a single value. }
  Result := 1;
end;

procedure Run;
var
  Context: PDukContext;
begin
  { Create Duktape context }
  Context := duk_create_heap_default;
  try
    { Register native function called "print" that takes a variable number of
      arguments. }
    duk_push_c_function(Context, NativePrint, DUK_VARARGS);
    duk_put_global_string(Context, 'print');

    { Register native function called "add" that takes 2 arguments. }
    duk_push_c_function(Context, NativeAdd, 2);
    duk_put_global_string(Context, 'add');

    { Evaluate some JavaScript code.
      This will call into our NativePrint and Add functions. }
    duk_eval_string(Context, 'print("Hello", "World!");');
    duk_eval_string(Context, 'print("2 + 3 =", add(2, 3));');

    { Pop eval result }
    duk_pop(Context);
  finally
    duk_destroy_heap(Context);
  end;
end;

begin
  try
    WriteLn('Running demo...');
    Run;
    WriteLn('Demo completed. Press [Enter].');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
