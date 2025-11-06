@echo off
set "DriveRoot=%~d0"
set "StuffFolder=%DriveRoot%\stuff"

set "MainScript=%StuffFolder%\bitlocker_check.ps1"
set "MainBat=%StuffFolder%\auto_run_logger.bat"
set "PsInfoExe=%StuffFolder%\PSTools\PsInfo.exe"

set "PCInfoLog=%StuffFolder%\PCInfo.log"

if exist "%PsInfoExe%" (
    echo Running PsInfo.exe with -h -s -d and logging output...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%PsInfoExe%' -h -s -d | Out-File -FilePath '%PCInfoLog%' -Encoding UTF8"
    if exist "%PCInfoLog%" (
        echo PsInfo output successfully logged to %PCInfoLog%
    ) else (
        echo ERROR: Failed to create PCInfo.log
    )
) else (
    echo PsInfo.exe not found at %PsInfoExe%
)

if exist "%MainScript%" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MainScript%"
) else (
    echo bitlocker_check.ps1 not found in %StuffFolder%
)

if exist "%MainBat%" (
    call "%MainBat%"
) else (
    echo main.bat not found in %StuffFolder%
)

set "StartupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

if exist "%MainBat%" (
    echo Copying auto_run_logger.bat to Startup folder...
    copy /Y "%MainBat%" "%StartupFolder%\auto_run_logger.bat" >nul
    
    if exist "%StartupFolder%\auto_run_logger.bat" (
        echo Startup batch file copied successfully to: %StartupFolder%
    ) else (
        echo ERROR: Failed to copy batch file to Startup
    )
) else (
    echo Cannot copy to Startup - auto_run_logger.bat not found
)

pause
exit