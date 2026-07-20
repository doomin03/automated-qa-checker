@echo off
setlocal

call "%~dp0scripts\setup-local.bat" %*
exit /b %errorlevel%
