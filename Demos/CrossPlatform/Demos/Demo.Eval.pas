unit Demo.Eval;
{ Eval example.
  Evaluate an expression. }

interface

uses
  Demo,
  Duktape;

type
  TDemoEval = class(TDemo)
  private
    class function NativeEval(const ADuktape: TDuktape;
      const AUserData: Pointer): TdtResult; cdecl; static;

    class function NativeToString(const ADuktape: TDuktape;
      const AUserData: Pointer): TdtResult; cdecl; static;
  public
    procedure Run; override;
  end;

implementation

{ TDemoEval }

class function TDemoEval.NativeEval(const ADuktape: TDuktape;
  const AUserData: Pointer): TdtResult;
begin
  ADuktape.Eval;
  Result := TdtResult.HasResult;
end;

class function TDemoEval.NativeToString(const ADuktape: TDuktape;
  const AUserData: Pointer): TdtResult;
begin
  ADuktape.ToString(-1);
  Result := TdtResult.HasResult;
end;

procedure TDemoEval.Run;
const
  EXPRESSION = 'Math.sqrt(2.0)';
var
  Res: String;
begin
  Duktape.PushString(EXPRESSION);
  Duktape.SafeCall(NativeEval, nil, 1, 1);
  Duktape.SafeCall(NativeToString, nil, 1, 1);
  Res := String(Duktape.GetString(-1));
  Log(EXPRESSION + ' = ' + Res);
  Duktape.Pop;
end;

initialization
  TDemo.Register('Eval(Math.sqrt(2.0))', TDemoEval);

end.
