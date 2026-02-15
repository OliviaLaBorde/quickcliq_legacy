@echo off
cd /d "c:\dev\quickcliq_legacy\.net\QC"
echo === Quick Cliq .NET ===
echo Config: %cd%\Data\qc_config.json
echo.
echo Starting app (NOT building - build separately if needed)...
echo.
dotnet run --project QC.net\QC.net.csproj -c Release --no-build
pause
