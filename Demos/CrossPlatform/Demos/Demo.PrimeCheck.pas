unit Demo.PrimeCheck;
{ PrimeCheck example from the the Duktape guide (http://duktape.org/guide.html) }

interface

uses
  Duktape,
  Demo;

type
  TDemoPrimeCheck = class(TDemo)
  private
    class function NativePrimeCheck(const ADuktape: TDuktape): TdtResult; cdecl; static;
  public
    procedure Run; override;
  end;

implementation

{ TDemoPrimeCheck }

class function TDemoPrimeCheck.NativePrimeCheck(
  const ADuktape: TDuktape): TdtResult;
var
  I, Val, Lim: Integer;
begin
  Val := ADuktape.RequireInt(0);
  Lim := ADuktape.RequireInt(1);

  for I := 2 to Lim do
  begin
    if ((Val mod I) = 0) then
    begin
      ADuktape.PushFalse;
      Exit(TdtResult.HasResult);
    end;
  end;

  ADuktape.PushTrue;
  Result := TdtResult.HasResult;
end;

procedure TDemoPrimeCheck.Run;
begin
  Duktape.PushGlobalObject;
  Duktape.PushDelphiFunction(NativePrimeCheck, 2);
  Duktape.PutProp(-2, 'primeCheckNative');

  PushResource('PRIME');

  if (Duktape.ProtectedEval <> 0) then
  begin
    Log('Error: ' + String(Duktape.SafeToString(-1)));
    Exit;
  end;
  Duktape.Pop; // Ignore result

  Duktape.GetProp(-1, 'primeTest');
  if (Duktape.ProtectedCall(0) <> 0) then
    Log('Error: ' + String(Duktape.SafeToString(-1)));

  Duktape.Pop; // Ignore result
end;

initialization
  TDemo.Register('Prime Check', TDemoPrimeCheck);

end.
