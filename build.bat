@echo off
rem Build the game. Usage: build.bat [run | test]
rem Override compiler location with: set ODIN=path\to\odin.exe
setlocal
cd /d "%~dp0"

if "%ODIN%"=="" set "ODIN=C:\odin\odin.exe"
if not exist build mkdir build

if /i "%~1"=="test" goto test

"%ODIN%" build src -out:build\game.exe -debug -vet
if errorlevel 1 exit /b 1

if /i "%~1"=="run" build\game.exe
exit /b 0

:test
rem Outside of a ( ) block, so %errorlevel% is read after odin finishes.
"%ODIN%" test src -out:build\tests.exe -debug -vet
exit /b %errorlevel%
