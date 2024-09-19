@echo off
if "%~1"=="" (
    echo Please drag files onto this batch file to process them.
    pause
    exit /b 1
)

set "scriptPath=%~dp0DDStoDDSC.ps1"
echo Script path: %scriptPath%

:processFiles
if "%~1"=="" (
    pause
    exit /b 0
)

echo Processing file: %~1
set "filePath=%~1"
powershell.exe -ExecutionPolicy Bypass -File "%scriptPath%" -filePath "%filePath%" -mode "srgb"
if %errorlevel% neq 0 (
    echo Error processing file: %filePath%
)
shift
goto processFiles