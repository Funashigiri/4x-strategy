@echo off
rem Build the game. Usage: build.bat [run | test]
rem Override compiler location with: set ODIN=path\to\odin.exe
setlocal
cd /d "%~dp0"

if "%ODIN%"=="" set "ODIN=C:\odin\odin.exe"
if not exist build mkdir build

if /i "%~1"=="test" (
	"%ODIN%" test src -out:build\tests.exe -debug -vet
	exit /b
)

"%ODIN%" build src -out:build\game.exe -debug -vet
if errorlevel 1 exit /b 1

if /i "%~1"=="run" build\game.exe
