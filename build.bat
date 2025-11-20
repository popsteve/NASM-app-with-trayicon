@echo off
REM Compile resource
echo Compiling resources...
GoRC /fo resource.res resource.rc
if errorlevel 1 (
    echo Resource compilation failed! Make sure logo.ico is present.
    pause
    exit /b 1
)
echo GoRC finished.
pause

REM Compile ASM
echo Assembling win.asm...
nasm -f win64 win.asm -o win.obj -O3
if errorlevel 1 (
    echo Assembly failed!
    pause
    exit /b 1
)
echo NASM finished.
pause

REM Link with resource
echo Linking...
golink /entry Start win.obj resource.res kernel32.dll user32.dll shell32.dll gdi32.dll
if errorlevel 1 (
    echo Linking failed!
    pause
    exit /b 1
)
echo GoLink finished.
pause

REM Clean up
del win.obj
del resource.res

REM Run
echo Running win.exe...
win.exe

echo Build script finished.
pause