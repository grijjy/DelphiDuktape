program DuktapeDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMain in 'FMain.pas' {FormMain},
  Demo in 'Demos\Demo.pas',
  Demo.Hello in 'Demos\Demo.Hello.pas',
  Demo.Eval in 'Demos\Demo.Eval.pas',
  Demo.UpperCase in 'Demos\Demo.UpperCase.pas',
  Demo.ProcessLine in 'Demos\Demo.ProcessLine.pas',
  Demo.Fibonacci in 'Demos\Demo.Fibonacci.pas',
  Demo.PrimeCheck in 'Demos\Demo.PrimeCheck.pas',
  Duktape.Api in '..\..\Duktape.Api.pas',
  Duktape in '..\..\Duktape.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
