@echo off

REM Run this from the "VS x86 Native Tools Command Prompt"

cl /sdl- /GL /analyze- /W3 /Gy /Zc:wchar_t /I"src" /Gm- /O2 /Ob2 /Ot /sdl- /Zc:inline /fp:precise /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /fp:except- /errorReport:prompt /WX- /Zc:forScope /arch:SSE2 /Gd /Oy- /Oi /MT /LD /Fe"duktape32.dll" "src/duktape.c"

copy duktape32.dll ..\Bin
del *.obj
del duktape32.*