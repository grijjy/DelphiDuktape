program DuktapeHighLevel;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Duktape.Api in '..\..\Duktape.Api.pas',
  Duktape.Glue in '..\..\Duktape.Glue.pas',
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

function NativeAdd(const AArg1, AArg2: Double): Double;
begin
  Result := AArg1 + AArg2;
end;

procedure Run;
var
  DukGlue: TDukGlue;
begin
  { Create Duktape Glue object, using Delphi's memory manager. }
  DukGlue := TDukGlue.Create(True);
  try
    { Register native function called "print" that takes a variable number of
      arguments. TDukGlue does not support native functions with a variable
      number of arguments, so use the underlying "medium" level API. }
    DukGlue.Duktape.PushDelphiFunction(NativePrint, DT_VARARGS);
    DukGlue.Duktape.PutGlobalString('print');

    { Register native function called "add" that takes 2 arguments.
      We can use TDukGlue for this. }
    DukGlue.RegisterFunction<Double, Double, Double>(NativeAdd, 'add');

    { Evaluate some JavaScript code.
      This will call into our NativePrint and Add functions. }
    DukGlue.Duktape.Eval('print("Hello", "World!");');
    DukGlue.Duktape.Eval('print("2 + 3 =", add(2, 3));');

    { Pop eval result }
    DukGlue.Duktape.Pop;
  finally
    DukGlue.Free;
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
