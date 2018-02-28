unit Duktape.Glue;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  System.Generics.Collections,
  Duktape,
  Duktape.Api;

type
  TdgProc = procedure;
  TdgProc<T1> = procedure(const AArg1: T1);
  TdgProc<T1, T2> = procedure(const AArg1: T1; const AArg2: T2);
  TdgProc<T1, T2, T3> = procedure(const AArg1: T1; const AArg2: T2;
    const AArg3: T3);
  TdgProc<T1, T2, T3, T4> = procedure(const AArg1: T1; const AArg2: T2;
    const AArg3: T3; const AArg4: T4);

  TdgFunc<TResult> = function: TResult;
  TdgFunc<T1, TResult> = function(const AArg1: T1): TResult;
  TdgFunc<T1, T2, TResult> = function(const AArg1: T1; const AArg2: T2): TResult;
  TdgFunc<T1, T2, T3, TResult> = function(const AArg1: T1; const AArg2: T2;
    const AArg3: T3): TResult;
  TdgFunc<T1, T2, T3, T4, TResult> = function(const AArg1: T1; const AArg2: T2;
    const AArg3: T3; const AArg4: T4): TResult;

type
  PdgInvokable = ^TdgInvokable;
  TdgInvokable = record
  public
    CodeAddress: Pointer;
    ReturnType: PTypeInfo;
    ArgCount: Integer;
    IsStatic: Boolean;
    IsConstructor: Boolean;
    // ArgTypes: array [0..0] of PTypeInfo;
  {$REGION 'Internal Declarations'}
  private
    function GetArgTypes: PPTypeInfo; inline;
  {$ENDREGION 'Internal Declarations'}
  public
    property ArgTypes: PPTypeInfo read GetArgTypes;
  end;

type
  { High-level Duktape class }
  TDukGlue = class
  {$REGION 'Internal Declarations'}
  private const
    PROP_INVOKABLE = #$FF'Invokable';
  private
    FDuktape: TDuktape;
    FInvokables: TList<PdgInvokable>;
    function GetContext: PDukContext; inline;
  private
    procedure RegisterProc(const AAddress: Pointer; const AName: String;
      const AArgTypes: array of PTypeInfo; const AReturnType: PTypeInfo);
  private
    class function NativeProc(const ADuktape: TDuktape): TdtResult; cdecl; static;
    class function ScriptArgToValue(const ADuktape: TDuktape;
      const AArgIndex: Integer; const AArgType: PTypeInfo;
      out AValue: TValue): Boolean; static;
    class function PushValue(const ADuktape: TDuktape; const AValue: TValue;
      const AType: PTypeInfo): Boolean; static;
    class function TypeToString(const AType: TdtType): String; static;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a new Duktape context and heap.

      Parameters:
        AUseDelphiMemoryManager: whether to use Delphi's memory manager.
          When False (default), the system memory manager is used. Set to True
          to have Delphi manage all memory (de)allocations for Duktape. That is
          useful if you want to check for memory leaks using the
          ReportMemoryLeaksOnShutdown global variable. }
    constructor Create(const AUseDelphiMemoryManager: Boolean = False);

    { Destroys the Duktape context and heap. }
    destructor Destroy; override;
  public
    procedure RegisterProcedure(const AProc: TdgProc;
      const AName: String); overload;
    procedure RegisterProcedure<T1>(const AProc: TdgProc<T1>;
      const AName: String); overload;
    procedure RegisterProcedure<T1, T2>(const AProc: TdgProc<T1, T2>;
      const AName: String); overload;
    procedure RegisterProcedure<T1, T2, T3>(const AProc: TdgProc<T1, T2, T3>;
      const AName: String); overload;
    procedure RegisterProcedure<T1, T2, T3, T4>(
      const AProc: TdgProc<T1, T2, T3, T4>; const AName: String); overload;

    procedure RegisterFunction<TResult>(
      const AFunc: TdgFunc<TResult>; const AName: String); overload;
    procedure RegisterFunction<T1, TResult>(
      const AFunc: TdgFunc<T1, TResult>; const AName: String); overload;
    procedure RegisterFunction<T1, T2, TResult>(
      const AFunc: TdgFunc<T1, T2, TResult>; const AName: String); overload;
    procedure RegisterFunction<T1, T2, T3, TResult>(
      const AFunc: TdgFunc<T1, T2, T3, TResult>; const AName: String); overload;
    procedure RegisterFunction<T1, T2, T3, T4, TResult>(
      const AFunc: TdgFunc<T1, T2, T3, T4, TResult>; const AName: String); overload;
  public
    { Access to the medium-level Duktape wrapper }
    property Duktape: TDuktape read FDuktape;

    { Access to the low-level Duktape context handle }
    property Context: PDukContext read GetContext;
  end;

implementation

{ TDukGlue }

constructor TDukGlue.Create(const AUseDelphiMemoryManager: Boolean);
begin
  inherited Create;
  FDuktape := TDuktape.Create(AUseDelphiMemoryManager);
  FInvokables := TList<PdgInvokable>.Create;
end;

destructor TDukGlue.Destroy;
var
  I: Integer;
begin
  if Assigned(FInvokables) then
  begin
    for I := 0 to FInvokables.Count - 1 do
      FreeMem(FInvokables[I]);
    FInvokables.Free;
  end;
  FDuktape.Free;
  inherited;
end;

function TDukGlue.GetContext: PDukContext;
begin
  Result := FDuktape.Context;
end;

class function TDukGlue.NativeProc(const ADuktape: TDuktape): TdtResult;
var
  Invokable: PdgInvokable;
  ArgType: PPTypeInfo;
  Args: TArray<TValue>;
  ReturnValue: TValue;
  ArgCount, I: Integer;
begin
  ADuktape.PushCurrentFunction;
  ADuktape.GetProp(-1, PROP_INVOKABLE);

  Invokable := ADuktape.RequirePointer(-1);
  if (Invokable = nil) then
  begin
    ADuktape.Error(TdtErrCode.Error, 'Internal NativeProc error');
    Exit(TdtResult.Error);
  end;

  ADuktape.Pop2;

  ArgCount := Invokable.ArgCount;
  SetLength(Args, ArgCount);
  if (ArgCount > 0) then
  begin
    ArgType := Invokable.ArgTypes;
    for I := 0 to ArgCount - 1 do
    begin
      if (not ScriptArgToValue(ADuktape, I, ArgType^, Args[I])) then
        Exit(TdtResult.TypeError);
      Inc(ArgType);
    end;
  end;

  ReturnValue := Invoke(Invokable.CodeAddress, Args, TCallConv.ccReg,
    Invokable.ReturnType, Invokable.IsStatic, Invokable.IsConstructor);

  if Assigned(Invokable.ReturnType) then
  begin
    if (PushValue(ADuktape, ReturnValue, Invokable.ReturnType)) then
      Result := TdtResult.HasResult
    else
      Result := TdtResult.TypeError;
  end
  else
    Result := TdtResult.NoResult;
end;

class function TDukGlue.PushValue(const ADuktape: TDuktape;
  const AValue: TValue; const AType: PTypeInfo): Boolean;
var
  TypeData: PTypeData;
  S: DuktapeString;
begin
  case AType.Kind of
    tkInteger:
      begin
        TypeData := GetTypeData(AType);
        if (TypeData.MinValue < 0) then
          ADuktape.PushInt(AValue.AsInteger)
        else
          ADuktape.PushUInt(AValue.AsOrdinal);
      end;

    tkInt64:
      ADuktape.PushNumber(AValue.AsInt64);

    tkEnumeration:
      begin
        if (AType = TypeInfo(Boolean)) then
          ADuktape.PushBoolean(AValue.AsBoolean)
        else
          ADuktape.PushInt(AValue.AsOrdinal);
      end;

    tkFloat:
      ADuktape.PushNumber(AValue.AsType<Double>);

    tkLString,
    tkUString:
      begin
        S := DuktapeString(AValue.AsString);
        ADuktape.PushString(S);
      end;
  end;
  Result := True;
end;

procedure TDukGlue.RegisterFunction<TResult>(const AFunc: TdgFunc<TResult>;
  const AName: String);
begin
  RegisterProc(@AFunc, AName, [], TypeInfo(TResult));
end;

procedure TDukGlue.RegisterFunction<T1, TResult>(
  const AFunc: TdgFunc<T1, TResult>; const AName: String);
begin
  RegisterProc(@AFunc, AName, [TypeInfo(T1)], TypeInfo(TResult));
end;

procedure TDukGlue.RegisterFunction<T1, T2, TResult>(
  const AFunc: TdgFunc<T1, T2, TResult>; const AName: String);
begin
  RegisterProc(@AFunc, AName, [TypeInfo(T1), TypeInfo(T2)], TypeInfo(TResult));
end;

procedure TDukGlue.RegisterFunction<T1, T2, T3, TResult>(
  const AFunc: TdgFunc<T1, T2, T3, TResult>; const AName: String);
begin
  RegisterProc(@AFunc, AName, [TypeInfo(T1), TypeInfo(T2),
    TypeInfo(T3)], TypeInfo(TResult));
end;

procedure TDukGlue.RegisterFunction<T1, T2, T3, T4, TResult>(
  const AFunc: TdgFunc<T1, T2, T3, T4, TResult>; const AName: String);
begin
  RegisterProc(@AFunc, AName, [TypeInfo(T1), TypeInfo(T2), TypeInfo(T3),
    TypeInfo(T4)], TypeInfo(TResult));
end;

procedure TDukGlue.RegisterProc(const AAddress: Pointer; const AName: String;
  const AArgTypes: array of PTypeInfo; const AReturnType: PTypeInfo);
var
  Invokable: PdgInvokable;
begin
  { TODO : Check if AArgTypes and AReturnType are usuable with Duktape }

  GetMem(Invokable, SizeOf(TdgInvokable) + (Length(AArgTypes) * SizeOf(PTypeInfo)));
  FInvokables.Add(Invokable);

  Invokable.CodeAddress := AAddress;
  Invokable.ReturnType := AReturnType;
  Invokable.ArgCount := Length(AArgTypes);
  Invokable.IsStatic := True;
  Invokable.IsConstructor := False;

  if (Length(AArgTypes) > 0) then
    Move(AArgTypes[0], Invokable.ArgTypes^, Length(AArgTypes) * SizeOf(PTypeInfo));

  FDuktape.PushDelphiFunction(NativeProc, Length(AArgTypes));
  FDuktape.PushPointer(Invokable);
  FDuktape.PutProp(-2, PROP_INVOKABLE);
  FDuktape.PutGlobalString(DuktapeString(AName));
end;

procedure TDukGlue.RegisterProcedure(const AProc: TdgProc; const AName: String);
begin
  RegisterProc(@AProc, AName, [], nil);
end;

procedure TDukGlue.RegisterProcedure<T1>(const AProc: TdgProc<T1>;
  const AName: String);
begin
  RegisterProc(@AProc, AName, [TypeInfo(T1)], nil);
end;

procedure TDukGlue.RegisterProcedure<T1, T2>(const AProc: TdgProc<T1, T2>;
  const AName: String);
begin
  RegisterProc(@AProc, AName, [TypeInfo(T1), TypeInfo(T2)], nil);
end;

procedure TDukGlue.RegisterProcedure<T1, T2, T3>(
  const AProc: TdgProc<T1, T2, T3>; const AName: String);
begin
  RegisterProc(@AProc, AName, [TypeInfo(T1), TypeInfo(T2), TypeInfo(T3)], nil);
end;

procedure TDukGlue.RegisterProcedure<T1, T2, T3, T4>(
  const AProc: TdgProc<T1, T2, T3, T4>; const AName: String);
begin
  RegisterProc(@AProc, AName, [TypeInfo(T1), TypeInfo(T2), TypeInfo(T3),
    TypeInfo(T4)], nil);
end;

class function TDukGlue.ScriptArgToValue(const ADuktape: TDuktape;
  const AArgIndex: Integer; const AArgType: PTypeInfo;
  out AValue: TValue): Boolean;
var
  TypeData: PTypeData;
  S: Single;
  D: Double;
  E: Extended;
  CU: Currency;
begin
  case AArgType.Kind of
    tkInteger,
    tkInt64:
      begin
        if (not ADuktape.IsNumber(AArgIndex)) then
        begin
          ADuktape.Error(TdtErrCode.TypeError,
            DuktapeString(Format('Argument %d: expected numeric type but got type "%s"',
              [AArgIndex, TypeToString(ADuktape.GetType(AArgIndex))])));
          Exit(False);
        end;

        if (AArgType.Kind = tkInt64) then
          AValue := Trunc(ADuktape.GetNumber(AArgIndex))
        else
        begin
          TypeData := GetTypeData(AArgType);
          if (TypeData.MinValue < 0) then
            AValue := TValue.FromOrdinal(AArgType, ADuktape.GetInt(AArgIndex))
          else
            AValue := TValue.FromOrdinal(AArgType, ADuktape.GetUInt(AArgIndex));
        end;
      end;

    tkEnumeration:
      begin
        if (AArgType = TypeInfo(Boolean)) then
        begin
          if (not ADuktape.IsBoolean(AArgIndex)) then
          begin
            ADuktape.Error(TdtErrCode.TypeError,
              DuktapeString(Format('Argument %d: expected boolean type but got type "%s"',
                [AArgIndex, TypeToString(ADuktape.GetType(AArgIndex))])));
            Exit(False);
          end;
          AValue := ADuktape.GetBoolean(AArgIndex);
        end
        else
          Exit(ScriptArgToValue(ADuktape, AArgIndex, TypeInfo(Integer), AValue));
      end;

    tkFloat:
      begin
        if (not ADuktape.IsNumber(AArgIndex)) then
        begin
          ADuktape.Error(TdtErrCode.TypeError,
            DuktapeString(Format('Argument %d: expected numeric type but got type "%s"',
              [AArgIndex, TypeToString(ADuktape.GetType(AArgIndex))])));
          Exit(False);
        end;

        TypeData := GetTypeData(AArgType);
        case TypeData.FloatType of
          ftSingle:
            begin
              S := ADuktape.GetNumber(AArgIndex);
              AValue := S;
            end;

          ftDouble:
            begin
              D := ADuktape.GetNumber(AArgIndex);
              AValue := D;
            end;

          ftExtended:
            begin
              E := ADuktape.GetNumber(AArgIndex);
              AValue := E;
            end;

          ftCurr:
            begin
              CU := ADuktape.GetNumber(AArgIndex);
              AValue := CU;
            end;
        else
          Assert(False);
        end;
      end;

    tkUString,
    tkLString:
      begin
        if (not ADuktape.IsString(AArgIndex)) then
        begin
          ADuktape.Error(TdtErrCode.TypeError,
            DuktapeString(Format('Argument %d: expected string type but got type "%s"',
              [AArgIndex, TypeToString(ADuktape.GetType(AArgIndex))])));
          Exit(False);
        end;

        if (AArgType.Kind = tkUString) then
          AValue := String(ADuktape.GetString(AArgIndex))
        else
          AValue := TValue.From<DuktapeString>(ADuktape.GetString(AArgIndex));
      end;
  else
    ADuktape.Error(TdtErrCode.TypeError,
      DuktapeString(Format('Argument %d: unsupported type "%s"',
        [AArgIndex, TypeToString(ADuktape.GetType(AArgIndex))])));
    Exit(False);
  end;
  Result := True;
end;

class function TDukGlue.TypeToString(const AType: TdtType): String;
begin
  case AType of
    TdtType.None: Result := '(none)';
    TdtType.Undefined: Result := 'undefined';
    TdtType.Null: Result := 'null';
    TdtType.Boolean: Result := 'boolean';
    TdtType.Number: Result := 'number';
    TdtType.Str: Result := 'string';
    TdtType.Obj: Result := 'object';
    TdtType.Buffer: Result := 'buffer';
    TdtType.Pointer: Result := 'pointer';
    TdtType.LightFunc: Result := 'lightfunc';
  else
    Result := '(invalid)';
  end;
end;

{ TdgInvokable }

function TdgInvokable.GetArgTypes: PPTypeInfo;
begin
  Result := Pointer(PByte(@Self) + SizeOf(TdgInvokable));
end;

end.
