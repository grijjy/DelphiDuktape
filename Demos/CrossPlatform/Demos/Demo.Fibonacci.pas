unit Demo.Fibonacci;
{ Fib.js example from the the Duktape guide (http://duktape.org/guide.html) }

interface

uses
  Duktape,
  Demo;

type
  TDemoFibonacci = class(TDemo)
  public
    procedure Run; override;
  end;

implementation

{ TDemoFibonacci }

procedure TDemoFibonacci.Run;
begin
  PushResource('FIB');

  if (Duktape.ProtectedEval <> 0) then
  begin
    Log('Error: ' + String(Duktape.SafeToString(-1)));
    Exit;
  end;

  Duktape.Pop; // Ignore result
end;

initialization
  TDemo.Register('Fibonacci', TDemoFibonacci);

end.
