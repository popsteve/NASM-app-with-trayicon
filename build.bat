@echo off
REM Compile resource
echo Compiling resources...
GoRC /fo resource.res resource.rc
echo GoRC finished.
pause

REM Compile ASM
echo Assembling win.asm...
nasm -f win64 win.asm -o win.obj -O3
echo NASM finished.
pause

REM Link with resource
echo Linking...
golink /entry Start win.obj resource.res kernel32.dll user32.dll shell32.dll gdi32.dll
echo GoLink finished.
pause

REM Clean up
REM del win.obj
REM del resource.res

REM Run
REM win.exe
echo Build script finished.
pause