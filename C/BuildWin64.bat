@echo off

REM Run this from the "VS x64 Native Tools Command Prompt"

cl /sdl- /GL /analyze- /W3 /Gy /Zc:wchar_t /I"src" /Gm- /O2 /Ob2 /Ot /sdl- /Zc:inline /fp:precise /D "NDEBUG" /D "_WINDOWS" /fp:except- /errorReport:prompt /WX- /Zc:forScope /Gd /Oy- /Oi /MT /LD /Fe"duktape64.dll" "src/duktape.c"

copy duktape64.dll ..\Bin
del *.obj
del duktape64.*