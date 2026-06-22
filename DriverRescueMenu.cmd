@echo off
setlocal

:menu
cls
echo ========================================
echo        WinPE Driver Rescue Kit
echo ========================================
echo.
echo  1. Restore drivers
echo  2. Dry-run driver scan
echo  3. Unlock BitLocker volume
echo  4. Generate rescue report
echo  5. Open command prompt
echo  6. Reboot
echo  7. Exit menu
echo.
set /p CHOICE=Choose an option:

if "%CHOICE%"=="1" goto restore
if "%CHOICE%"=="2" goto dryrun
if "%CHOICE%"=="3" goto bitlocker
if "%CHOICE%"=="4" goto report
if "%CHOICE%"=="5" goto shell
if "%CHOICE%"=="6" goto reboot
if "%CHOICE%"=="7" goto end
goto menu

:restore
call X:\DriverRestore.cmd
pause
goto menu

:dryrun
powershell.exe -NoProfile -ExecutionPolicy Bypass -File X:\Tools\DriverRestore.ps1 -DryRun
pause
goto menu

:bitlocker
call X:\Unlock-BitLockerVolume.cmd
pause
goto menu

:report
powershell.exe -NoProfile -ExecutionPolicy Bypass -File X:\Tools\Generate-RescueReport.ps1
pause
goto menu

:shell
cmd.exe
goto menu

:reboot
wpeutil reboot
goto end

:end
endlocal
