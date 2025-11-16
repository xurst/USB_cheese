@ECHO OFF
SETLOCAL

SET "reg_key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

FOR /F "tokens=3" %%A IN ('REG QUERY "%reg_key%" /v CurrentBuild 2^>nul') DO SET "MajorBuild=%%A"
FOR /F "tokens=3" %%A IN ('REG QUERY "%reg_key%" /v UBR 2^>nul') DO SET "UBRraw=%%A"

IF NOT DEFINED MajorBuild (
    ECHO Error: Could not read 'CurrentBuild' from the registry.
    ECHO Make sure the script is run with sufficient privileges.
    GOTO :End
)
IF NOT DEFINED UBRraw (
    ECHO Error: Could not read 'UBR' from the registry.
    ECHO Make sure the script is run with sufficient privileges.
    GOTO :End
)

SET /A UBR=%UBRraw%

ECHO Detected Build: %MajorBuild%.%UBR%
ECHO.

SET "BrokenStart=6899"
SET "FixedStart=6901"

IF "%MajorBuild%"=="26100" GOTO :ProcessKnownBuild
IF "%MajorBuild%"=="26200" GOTO :ProcessKnownBuild

ECHO Status: UNKNOWN
ECHO This script is intended for Windows 11 24H2 (26100.x) and 25H2 (26200.x).
ECHO.
ECHO Creating a verbose log file for your analysis...

SET "LOGFILE=%~dp0winre_bug_check_log.txt"

(
    ECHO.======================================================================
    ECHO. WinRE Bug Check - Verbose Log
    ECHO.======================================================================
    ECHO.
    ECHO. Log generated on: %DATE% at %TIME%
    ECHO.
    ECHO. -- System Information Detected --
    ECHO.
    ECHO.   Major Build         : %MajorBuild%
    ECHO.   UBR (Raw from Reg)  : %UBRraw%
    ECHO.   UBR (Decimal)       : %UBR%
    ECHO.   Full Version String : %MajorBuild%.%UBR%
    ECHO.
    ECHO. -- Script Analysis --
    ECHO.
    ECHO. This build was marked as 'UNKNOWN' because the Major Build (%MajorBuild%)
    ECHO. is not one of the specific builds this script targets (26100 or 26200).
    ECHO.
    ECHO. -- Information for Your Research --
    ECHO.
    ECHO. The WinRE USB input bug this script checks for was introduced in a Cumulative
    ECHO. Update (KB5066835) for builds 26100 and 26200, and was fixed by a later
    ECHO. update (KB5070773).
    ECHO.
    ECHO. The script's thresholds for those builds are:
    ECHO.   - Broken UBR Range: %BrokenStart% - 6900
    ECHO.   - Fixed UBR Start : %FixedStart%
    ECHO.
    ECHO. These UBR numbers are specific to builds 26100/26200 and likely DO NOT APPLY
    ECHO. to your build (%MajorBuild%).
    ECHO.
    ECHO. To determine if you are affected, please research your specific full build
    ECHO. number (%MajorBuild%.%UBR%) online to see its update history and known issues.
    ECHO.
) > "%LOGFILE%"

ECHO.
ECHO Success! Log file saved to:
ECHO %LOGFILE%
ECHO.
GOTO :End

:ProcessKnownBuild
IF "%MajorBuild%"=="26100" ECHO Branch: Windows 11 24H2
IF "%MajorBuild%"=="26200" ECHO Branch: Windows 11 25H2

IF %UBR% LSS %BrokenStart% (
    ECHO Status: NOT AFFECTED
    ECHO This build is earlier than the KB5066835 WinRE bug.
    GOTO :End
)

IF %UBR% GEQ %BrokenStart% (
    IF %UBR% LSS %FixedStart% (
        ECHO Status: BROKEN
        ECHO Your build is inside the KB5066835 WinRE mouse/keyboard input bug window.
        GOTO :End
    )
)

IF %UBR% GEQ %FixedStart% (
    ECHO Status: FIXED
    ECHO Your build contains KB5070773 or later. WinRE USB input is repaired.
    GOTO :End
)

:End
ENDLOCAL
PAUSE