@echo off
cd /d "c:\dev\quickcliq_legacy\.net\QC"
echo Building Quick Cliq...
dotnet build QC.net\QC.net.csproj -c Release
if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful!
    echo.
) else (
    echo.
    echo Build FAILED!
    pause
    exit /b 1
)
