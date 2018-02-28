unit Demo.ProcessLine;
{ ProcessLines example from the the Duktape guide (http://duktape.org/guide.html) }

interface

uses
  Duktape,
  Demo;

type
  TDemoProcessLine = class(TDemo)
  public
    procedure Run; override;
  end;

implementation

{ TDemoProcessLine }

procedure TDemoProcessLine.Run;
const
  LINE = 'Escape HTML: <Test>, Make *bold*.';
begin
  PushResource('PROCESS');
  if (Duktape.ProtectedEval <> 0) then
  begin
    Log('Error: ' + String(Duktape.SafeToString(-1)));
    Exit;
  end;
  Duktape.Pop; // Ignore result

  Duktape.PushGlobalObject;
  Duktape.GetProp(-1, 'processLine');
  Duktape.PushString(LINE);

  if (Duktape.ProtectedCall(1) <> 0) then
    Log('Error: ' + String(Duktape.SafeToString(-1)))
  else
    Log(LINE + ' -> ' + String(Duktape.SafeToString(-1)));

  Duktape.Pop;
end;

initialization
  TDemo.Register('Process Line', TDemoProcessLine);

end.
