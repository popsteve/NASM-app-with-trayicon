@echo off
echo Compiling resources...
GoRC /fo resource.res resource.rc
if errorlevel 1 exit /b 1

echo Assembling win.asm...
nasm -f win64 win.asm -o win.obj -O3
if errorlevel 1 exit /b 1

echo Linking...
golink /entry Start win.obj resource.res kernel32.dll user32.dll shell32.dll gdi32.dll
if errorlevel 1 exit /b 1

echo Build success.
