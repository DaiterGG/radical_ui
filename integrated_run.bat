@echo off
setlocal

set "SECONDS=20"
if /I "%~1"=="--seconds" (
	if "%~2"=="" (
		echo Missing value for --seconds.
		exit /b 2
	)
	set "SECONDS=%~2"
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0integrated_run.ps1" -Seconds "%SECONDS%"
exit /b %ERRORLEVEL%
