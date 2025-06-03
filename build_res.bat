@echo off
echo Building resources...
GoRC /fo resource.res resource.rc
if errorlevel 1 (
    echo Resource compilation failed!
    pause
    exit /b 1
)
echo Resource compilation successful! 