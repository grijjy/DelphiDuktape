# JavaScripting with Duktape for Delphi

Looking to add JavaScript capabilities to you app, but without the bulk and overhead of JIT engines like V8, SpiderMonkey and Chakra? Then take a look at [Duktape](http://duktape.org/index.html).

Duktape is a lightweight, embeddable and cross-platform JavaScript engine. It fits into a DLL just over half a megabyte in size but supports the complete ECMAScript 5.1 specification (as well as parts of ECMAScript 2015 and 2016).

## Duktape for Delphi

Duktape uses a C API, so that it can be accessed from other languages. We created header translations for this API and some higher level wrappers to make these easier to use in Delphi. In addition, we supply prebuilt binaries of the Duktape library for Windows (32-bit and 64-bit), macOS, iOS, Android and Linux.

This repository contains the source code, Duktape libraries and a couple of sample applications. In addition it contains build scripts for building the Duktape libraries for all platforms.

The Delphi header translations and binaries apply to the latest Duktape version (2.2.0) at the time of writing. You can use the build scripts to build newer binaries if needed.

## Deploying the Duktape Libraries

For iOS and Android, the Duktape library is statically linked into the executable and there are no additional files that need to be deployed. For the other platforms, you need to deploy a dynamic library:

* **Windows**: Place `duktape32.dll` or `duktape64.dll` (depending on platform) in your application directory.
* **macOS**: Add `libduktape_osx32.dylib` to the deployment manager, using `Contents\MacOS\` as the Remote Path.
* **Linux**: Add `libduktape_linux64.so` to the deployment manager, using `.\` as the Remote Path.

## API Levels

We provide three API levels for working with Duktape. The low-level API consists of the C header translations. The medium-level API adds a very thin layer on top of this that is a bit easier to use. Finally, a limited high-level API makes it easier to register Delphi routines that can be called from JavaScript code.

In presenting these APIs, we won't go into any details of how Duktape works. I suggest you take a look at the [Duktape Programmer's Guide](http://duktape.org/guide.html) to learn about its architecture. Most of what is presented there applies to Delphi as well.

## Low-Level API

The low-level API follows the C API exactly. So please refer to the [Duktapi API documentation](http://duktape.org/api.html) for detailed information about this API. An example usage of this API level can be found in the `DuktapeLowLevel` demo project. It registers 2 functions that can be called from JavaScript code:

* A function called `print` that takes a variable number of arguments and outputs these to the console window.
* A function called `add` that adds two numbers together.

It then evaluates some JavaScript code that calls these Delphi functions:

```delphi
procedure Run;
var
  Context: PDukContext;
begin
  { Create Duktape context }
  Context := duk_create_heap_default;
  try
    { Register native function called "print" that takes a
      variable number of arguments. }
    duk_push_c_function(Context, NativePrint, DUK_VARARGS);
    duk_put_global_string(Context, 'print');

    { Register native function called "add" that takes 2 arguments. }
    duk_push_c_function(Context, NativeAdd, 2);
    duk_put_global_string(Context, 'add');

    { Evaluate some JavaScript code.
      This will call into our NativePrint and Add functions. }
    duk_eval_string(Context, 'print("Hello", "World!");');
    duk_eval_string(Context, 'print("2 + 3 =", add(2, 3));');

    { Pop eval result }
    duk_pop(Context);
  finally
    duk_destroy_heap(Context);
  end;
end;
```

The top half registers the Delphi functions and the bottom half executes some JavaScript code that calls these functions. The Delphi `NativePrint` function is called when the JavaScript code calls `print`. It concatenates all arguments together and writes them to the console window:

```delphi
function NativePrint(AContext: PDukContext): TDukRet; cdecl;
var
  S: UTF8String;
begin
  { Join all arguments together with spaces between them. }
  duk_push_string(AContext, ' ');
  duk_insert(AContext, 0);
  duk_join(AContext, duk_get_top(AContext) - 1);

  { Get result and output to console }
  S := UTF8String(duk_safe_to_string(AContext, -1));
  WriteLn(S);

  { "print" function does not return a value. }
  Result := 0;
end;
```

Likewise, the `NativeAdd` function is called when JavaScript calls `add`:

```delphi
function NativeAdd(AContext: PDukContext): TDukRet; cdecl;
var
  Sum: Double;
begin
  { Add two arguments together }
  Sum := duk_to_number(AContext, 0) + duk_to_number(AContext, 1);

  { Push result }
  duk_push_number(AContext, Sum);

  { "add" function returns a single value. }
  Result := 1;
end;
```

Note that all Delphi functions that can be called from JavaScript must have the following signature:

* A single parameter containing the Duktape context.
* A return value of type `TDukRet`. This is just an integer and should be set to 1 if the function returns a value, 0 if it does not return a value, or a negative value representing an error code.
* It must use the `cdecl` calling convention.

## Medium-Level API

The medium-level API just adds a very thin layer on top of the low-level API. The purposes of this layer are:

* Provides a more object-oriented interface: the Duktape context is encapsulated in a `TDuktape` object (actually a record).
* Most Duktape APIs are now methods of the `TDuktape` object. These methods use Delphi naming conventions and types, make them more familiar.
* It takes care of marshalling data to the lower level. In particular the marshalling of strings to pointers to UTF8 C strings.
* It uses enumerated types instead of integers to improve type safety.

Other than that, the medium-level API is the same as the low-level API and doesn't provide other benefits or simplifications.

The medium-level API covers all aspects of the low-level API, so there should rarely be a need to use the low-level API directly.

The medium-level version of the example above (see the `DuktapeMediumLevel` demo project) looks like this:

```delphi
procedure Run;
var
  Duktape: TDuktape;
begin
  { Create Duktape object, using Delphi's memory manager. }
  Duktape := TDuktape.Create(True);
  try
    { Register native function called "print" that takes a
      variable number of arguments. }
    Duktape.PushDelphiFunction(NativePrint, DT_VARARGS);
    Duktape.PutGlobalString('print');
    
    { Register native function called "add" that takes 2 arguments. }
    Duktape.PushDelphiFunction(NativeAdd, 2);
    Duktape.PutGlobalString('add');
    
    { Evaluate some JavaScript code.
      This will call into our NativePrint and Add functions. }
    Duktape.Eval('print("Hello", "World!");');
    Duktape.Eval('print("2 + 3 =", add(2, 3));');
    
    { Pop eval result }
    Duktape.Pop;
  finally
    Duktape.Free;
  end;
end;
```

This time, you create a Duktape context by creating a `TDuktape` object. You pass a single parameter to the constructor indicating whether you want to use Delphi's memory manager (True) or Duktape's own memory manager (False). Using Delphi's memory manager can be useful for detecting memory leaks (through the `ReportMemoryLeaksOnShutdown` global variable).

The code looks very similar to the low-level version, just a bit more Delphi-like. The Delphi versions of the `print` and `add` functions are also similar to the ones above:

```delphi
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

function NativeAdd(const ADuktape: TDuktape): TdtResult; cdecl;
var
  Sum: Double;
begin
  { Add two arguments together }
  Sum := ADuktape.ToNumber(0) + ADuktape.ToNumber(1);

  { Push result }
  ADuktape.PushNumber(Sum);

  { "add" function returns a value. }
  Result := TdtResult.HasResult;
end;
```

These functions take a `TDuktape` parameter now and return a value of the enumerated type `TdtResult`.

## High-Level API

The high-level API is designed to make it easier to register Delphi functions. This API level is in no way complete, so you still need to use the medium (or low) level API for most other functions.

To goal of this API level is that you can write your Delphi functions like this:

```delphi
function NativeAdd(const AArg1, AArg2: Double): Double;
begin
  Result := AArg1 + AArg2;
end;
```

You'll probably agree that this is much easier than the version above. To register this function, you use the `TDukGlue` class:

```delphi
DukGlue.RegisterFunction<Double, Double, Double>(NativeAdd, 'add');
```

This is a generic function that takes up to 4 type parameters for the types of the arguments, and 1 type parameter for the function result type. In this example, the two parameters and the function result are all of type `Double`.

> Delphi is not able to use type inference for the generic `RegisterFunction` method, so you have to provide the type parameters yourself.
>

The complete high-level example looks like this (as found in the `DuktapeHighLevel` demo project):

```delphi
procedure Run;
var
  DukGlue: TDukGlue;
begin
  { Create Duktape Glue object, using Delphi's memory manager. }
  DukGlue := TDukGlue.Create(True);
  try
    { Register native function called "print" that takes a
      variable number of arguments. TDukGlue does not support
      native functions with a variable number of arguments,
      so use the underlying "medium" level API. }
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
```

Instead of a `TDuktape` object, you create a `TDukGlue` object instead and use its `RegisterProcedure` or `RegisterFunction` methods to register Delphi routines.

The medium-level API is exposed through its `Duktape` property. You can also access the low-level API if desired with the `Context` property.

The high-level API is less performant than the other levels, although this usually doesn't matter much.

## Wish List

The name `TDukGlue` is borrowed from a [C++ wrapper for Duktape](https://github.com/Aloshi/dukglue). Like the C++ wrapper, the goal of this class is to greatly simplify common JavaScript+Delphi scenarios.

However, I only implemented a couple of simplifications, such as registering Delphi routines. It would be very nice if you could register complete Delphi classes and make them available to JavaScript. This is possible with the Duktapi API and the Delphi RTTI interface. But since we don't need this for our purposes at Grijjy, I didn't get around to implementing it.

But of course we welcome your pull requests. So if you create any additions that improve this library, please let us know!