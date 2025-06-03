@echo off
REM Compile resource
REM GoRC /fo resource.res resource.rc

REM Compile ASM
nasm -f win64 win.asm -o win.obj -O3

REM Link without resource
golink /entry Start win.obj kernel32.dll user32.dll shell32.dll gdi32.dll

REM Clean up
del win.obj
REM del resource.res

REM Run
win.exe