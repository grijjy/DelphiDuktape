unit Demo.UpperCase;
{ UpperCase example from the the Duktape guide (http://duktape.org/guide.html) }

interface

uses
  Duktape,
  Demo;

type
  TDemoUpperCase = class(TDemo)
  private
    class function NativeUpperCase(const ADuktape: TDuktape): TdtResult; cdecl; static;
  public
    procedure Run; override;
  end;

implementation

{ TDemoUpperCase }

class function TDemoUpperCase.NativeUpperCase(
  const ADuktape: TDuktape): TdtResult;
var
  Val, S: DuktapeString;
  C: UTF8Char;
begin
  Val := ADuktape.RequireString(0);

  { We are going to need Length(Val) additional entries on the stack }
  ADuktape.RequireStack(Length(Val));

  for C in Val do
  begin
    S := UpCase(C);
    ADuktape.PushString(S);
  end;

  ADuktape.Concat(Length(Val));
  Result := TdtResult.HasResult;
end;

procedure TDemoUpperCase.Run;
const
  LINE = 'The Quick Brown Fox';
var
  Res: String;
begin
  Duktape.PushDelphiFunction(NativeUpperCase, 1);
  Duktape.PushString(LINE);
  Duktape.Call(1);
  Res := String(Duktape.ToString(-1));
  Log(LINE + ' -> ' + Res);
  Duktape.Pop;
end;

initialization
  TDemo.Register('Uppercase', TDemoUpperCase);

end.
