# Building the Duktape Libraries

This directory contains scripts for building the Duktape static and dynamic libraries for Windows, macOS, iOS, Android and Linux. You can use these to build new libraries for the latest Duktape version.

## All Platforms

* Download the [latest version of Duktape](http://duktape.org/download.html).
* Unpack to a directory of your choice.
* Copy the contents of the extracted `src` directory of the download to the `src`  subdirectory in this directory. You only need to copy the .h and .c files.

## Windows

The build script for Windows assumes you are using Visual Studio 2015 or later. The free version of Visual Studio suffices, as long as you have installed the C/C++ languages.

* Open duk_config.h
* Near the top is a line that reads:
    `#undef DUK_F_DLL_BUILD`
* Change this line to:
`#define DUK_F_DLL_BUILD`
* Open the "VS x86 Native Tools Command Prompt" and navigate to this directory (substitute "VS" for your Visual Studio version, eg. "VS2017").
* Execute `BuildWin32.bat`.
* Open the "VS x64 Native Tools Command Prompt" and navogate to this  directory. 
* Execute `BuildWin64.bat`.
* Undo the change you made to duk_config.h (eg. change `define` back to `undef`).

## Android

* Open a command prompt.
* Execute `BuildAndroid.bat`.

## macOS

* Copy this directory with subdirectories to your Mac.
* Open a terminal.
* Execute `./BuildMacOS.sh`.

## iOS

- Copy this directory with subdirectories to your Mac.
- Open a terminal.
- Execute `./BuildIOS.sh`.

## Linux

- Copy this directory with subdirectories to a Linux box.
- Open a terminal.
- Execute `./BuildLinux64.sh`.

