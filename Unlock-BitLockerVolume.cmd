@echo off
setlocal

where manage-bde.exe >nul 2>nul
if errorlevel 1 (
    echo manage-bde.exe was not found in this environment.
    echo BitLocker unlock is unavailable from this boot image.
    exit /b 1
)

set TARGET=%~1
if "%TARGET%"=="" set /p TARGET=Enter BitLocker volume letter, for example C:

echo.
echo Unlocking %TARGET%
set /p RECOVERY_KEY=Enter the 48-digit BitLocker recovery password:
echo.

manage-bde -unlock "%TARGET%" -RecoveryPassword "%RECOVERY_KEY%"
if errorlevel 1 (
    echo.
    echo Unlock failed. Check the drive letter and recovery key.
    set RECOVERY_KEY=
    exit /b 1
)

echo.
echo Disabling BitLocker protectors until Windows boots successfully.
manage-bde -protectors -disable "%TARGET%"

echo.
echo Done. Run DriverRestore.cmd after the volume is unlocked.
set RECOVERY_KEY=
endlocal
