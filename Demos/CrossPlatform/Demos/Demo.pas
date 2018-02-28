unit Demo;

interface

uses
  System.Types,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  Duktape;

type
  TDemo = class;
  TDemoClass = class of TDemo;

  TDemoInfo = record
    Name: String;
    Clazz: TDemoClass;
  end;

  TDemo = class abstract
  {$REGION 'Internal Declarations'}
  private class var
    FDemos: TList<TDemoInfo>;
    FOutput: TStrings;
  private
    FDuktape: TDuktape;
  protected
    procedure PushResource(const AResourceName: String);
    class procedure Log(const AMsg: String); static;

    property Duktape: TDuktape read FDuktape;
  protected
    class function NativePrint(const ADuktape: TDuktape): TdtResult; cdecl; static;
  public
    class constructor Create;
    class destructor Destroy;
  {$ENDREGION 'Internal Declarations'}
  public
    class procedure Register(const AName: String; const AClass: TDemoClass); static;
    class function GetDemos: TArray<TDemoInfo>; static;
  public
    constructor Create(const AOutput: TStrings); virtual;
    destructor Destroy; override;

    procedure Run; virtual; abstract;
  end;

implementation

{$R 'Resources.res'}

{ TDemo }

class constructor TDemo.Create;
begin
  FDemos := TList<TDemoInfo>.Create;
end;

constructor TDemo.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
  FDuktape := TDuktape.Create(True);
  FDuktape.PushDelphiFunction(NativePrint, DT_VARARGS);
  FDuktape.PutGlobalString('print');
end;

destructor TDemo.Destroy;
begin
  FDuktape.Free;
  FOutput := nil;
  inherited;
end;

class destructor TDemo.Destroy;
begin
  FDemos.Free;
end;

class function TDemo.GetDemos: TArray<TDemoInfo>;
begin
  Result := FDemos.ToArray;
end;

class procedure TDemo.Log(const AMsg: String);
begin
  FOutput.Add(AMsg);
end;

class function TDemo.NativePrint(const ADuktape: TDuktape): TdtResult;
var
  S: DuktapeString;
begin
  ADuktape.PushString(' ');
  ADuktape.Insert(0);
  ADuktape.Join(ADuktape.GetTop - 1);
  S := ADuktape.SafeToString(-1);

  Log(String(S));

  Result := TdtResult.NoResult;
end;

procedure TDemo.PushResource(const AResourceName: String);
var
  Stream: TResourceStream;
  Source: DuktapeString;
begin
  Stream := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
  try
    SetLength(Source, Stream.Size);
    Stream.ReadBuffer(Source[Low(DuktapeString)], Stream.Size);
  finally
    Stream.Free;
  end;

  FDuktape.PushString(Source);
end;

class procedure TDemo.Register(const AName: String; const AClass: TDemoClass);
var
  Info: TDemoInfo;
begin
  Info.Name := AName;
  Info.Clazz := AClass;
  FDemos.Add(Info);
end;

end.
