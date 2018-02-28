unit Demo.Hello;
{ Hello world example.
  Very simple example, most useful for compilation tests. }

interface

uses
  Duktape,
  Demo;

type
  TDemoHello = class(TDemo)
  private
    class function NativeAdder(const ADuktape: TDuktape): TdtResult; cdecl; static;
  public
    procedure Run; override;
  end;

implementation

{ TDemoHello }

class function TDemoHello.NativeAdder(const ADuktape: TDuktape): TdtResult;
var
  I, N: Integer;
  Res: Double;
begin
  N := ADuktape.GetTop; // Number of arguments
  Res := 0;

  for I := 0 to N - 1 do
    Res := Res + ADuktape.ToNumber(I);

  ADuktape.PushNumber(Res);

  Result := TdtResult.HasResult;
end;

procedure TDemoHello.Run;
begin
  Duktape.PushDelphiFunction(NativeAdder, DT_VARARGS);
  Duktape.PutGlobalString('adder');

  Duktape.Eval('print("Hello World!");');

  Duktape.Eval('print("2+3=" + adder(2, 3));');
  Duktape.Pop; // Pop eval result
end;

initialization
  TDemo.Register('Hello World!', TDemoHello);

end.
