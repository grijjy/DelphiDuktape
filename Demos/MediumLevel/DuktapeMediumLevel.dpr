program DuktapeMediumLevel;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Duktape.Api in '..\..\Duktape.Api.pas',
  Duktape in '..\..\Duktape.pas';

function NativePrint(const ADuktape: TDuktape): TdtResult; cdecl;
var
  S: DuktapeString;
begin
  { Join all arguments together with spaces between them. }
  ADuktape.PushString(' ');
  ADuktape.Insert(0);
  ADuktape.Join(ADuktape.GetTop - 1);

  { Get result and output to console }
  S := ADuktape.SafeToString(-1);
  WriteLn(S);

  { "print" function does not return a value. }
  Result := TdtResult.NoResult;
end;

function NativeAdd(const ADuktape: TDuktape): TdtResult; cdecl;
var
  Sum: Double;
begin
  { Add two arguments together }
  Sum := ADuktape.ToNumber(0) + ADuktape.ToNumber(1);

  { Push result }
  ADuktape.PushNumber(Sum);

  { "add" function returns a value. }
  Result := TdtResult.HasResult;
end;

procedure Run;
var
  Duktape: TDuktape;
begin
  { Create Duktape object, using Delphi's memory manager. }
  Duktape := TDuktape.Create(True);
  try
    { Register native function called "print" that takes a variable number of
      arguments. }
    Duktape.PushDelphiFunction(NativePrint, DT_VARARGS);
    Duktape.PutGlobalString('print');

    { Register native function called "add" that takes 2 arguments. }
    Duktape.PushDelphiFunction(NativeAdd, 2);
    Duktape.PutGlobalString('add');

    { Evaluate some JavaScript code.
      This will call into our NativePrint and Add functions. }
    Duktape.Eval('print("Hello", "World!");');
    Duktape.Eval('print("2 + 3 =", add(2, 3));');

    { Pop eval result }
    Duktape.Pop;
  finally
    Duktape.Free;
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
