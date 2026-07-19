@echo off
setlocal EnableDelayedExpansion
title iRacing Pre-Launch Optimizer v1.0-template
color 0A

:: ================================================================
:: iRacing Pre-Launch Optimizer — TEMPLATE v1.0
:: Tested on: AMD Ryzen 7800X3D / RTX 4090 / Windows 11
:: ================================================================
:: USE AT YOUR OWN RISK. Run as Administrator before every session.
:: Read the full guide before customizing:
:: https://rcsracing93.github.io/iracing-stutter-fix/guide.html
::
:: HOW TO USE THIS TEMPLATE:
:: Run find_my_values.bat once, in this same folder -- it writes
:: my_values.bat, which is auto-loaded below. Everything else runs
:: as-is. (No my_values.bat? Fill in the CONFIG block by hand instead.)
:: ================================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin elevation...
    powershell -command "Start-Process cmd -ArgumentList '/k \"%~f0\"' -Verb RunAs"
    exit /b
)
echo [OK]   Running as Administrator

:: ================================================================
:: ============================ CONFIG ============================
:: These are fallback defaults, only used if my_values.bat is not
:: found next to this script (see below). Run find_my_values.bat to
:: generate that file instead of editing these by hand.
:: ================================================================
:: 1) AMD Ryzen Balanced power plan GUID   (find: powercfg /list)
set "POWER_GUID=YOUR-AMD-RYZEN-BALANCED-GUID"
:: 2) NVIDIA GPU VEN/DEV path -- the part AFTER ...\Enum\PCI\
set "NV_VENDEV=YOUR-GPU-VEN-DEV-PATH"
:: 3) NVIDIA device instances -- one "quoted" entry each, space-separated.
::    Add/remove entries to match how many your GPU has (usually 2-4).
set NV_INSTANCES="YOUR_INSTANCE_1" "YOUR_INSTANCE_2"
:: 4) Expected NVIDIA driver version string
set "NV_DRIVER=YOUR-DRIVER-VERSION"
:: ================================================================

:: Auto-load machine-specific values from my_values.bat if present
:: (written by find_my_values.bat into the same folder). Overrides
:: the CONFIG block above so nothing has to be copy/pasted by hand.
if exist "%~dp0my_values.bat" (
    call "%~dp0my_values.bat"
    echo [OK]   Loaded values from my_values.bat
) else (
    echo [WARN] my_values.bat not found - using values from the CONFIG block above. Run find_my_values.bat to generate it.
)

:: Refuse to run with placeholder values left over from the CONFIG
:: block - applying them would silently do nothing useful (or fail)
:: instead of telling you the setup step was skipped.
set "_BAD_CONFIG="
if "!POWER_GUID!"=="YOUR-AMD-RYZEN-BALANCED-GUID" set "_BAD_CONFIG=1"
if "!NV_VENDEV!"=="YOUR-GPU-VEN-DEV-PATH" set "_BAD_CONFIG=1"
if "!NV_DRIVER!"=="YOUR-DRIVER-VERSION" set "_BAD_CONFIG=1"
if not "!NV_INSTANCES:YOUR_INSTANCE=!"=="!NV_INSTANCES!" set "_BAD_CONFIG=1"
if defined _BAD_CONFIG (
    color 0C
    echo.
    echo ============================================================
    echo   [FAIL] CONFIG values are still placeholders - not running.
    echo.
    echo   Run find_my_values.bat in this same folder, then re-run
    echo   this script - it auto-loads the values from my_values.bat.
    echo   Or fill in the CONFIG block above by hand: see guide
    echo   Section 05 - NVIDIA values, or Section 06 - power-plan GUID.
    echo ============================================================
    echo.
    pause
    exit /b 1
)

:: Pending reboot check
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1
if %errorlevel%==0 (echo [WARN] Pending Windows reboot detected) else (echo [OK]   No pending reboot)

:: Defender — suspend real-time monitoring for session (requires Tamper Protection OFF)
start /b "" powershell -NonInteractive -NoProfile -command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
timeout /t 4 /nobreak >nul
powershell -NonInteractive -NoProfile -command "if ((Get-MpPreference).DisableRealtimeMonitoring) { exit 0 } else { exit 1 }" >nul 2>&1
set _DEFENDER_OFF=%errorlevel%
if %_DEFENDER_OFF%==0 (echo [OK]   Defender real-time monitoring suspended) else (echo [WARN] Defender still active - exclusions will be applied as fallback)

:: Xbox Game Bar
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]   Xbox Game Bar disabled

:: HAGS (Hardware-Accelerated GPU Scheduling)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK]   HAGS disabled

:: Windows Game Mode
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK]   Game Mode disabled

:: USB Selective Suspend
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK]   USB Selective Suspend disabled

:: DISABLE Windows Update (prevents mid-session restart)
sc config wuauserv start= disabled >nul 2>&1
sc stop wuauserv >nul 2>&1
timeout /t 2 /nobreak >nul
sc query wuauserv | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Update disabled and stopped) else (echo [WARN] Windows Update may still be running)

:: DISABLE Update Orchestrator
sc config UsoSvc start= disabled >nul 2>&1
sc stop UsoSvc >nul 2>&1
echo [OK]   Windows Update Orchestrator disabled

:: DISABLE Windows Search
sc config WSearch start= disabled >nul 2>&1
sc stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
sc query WSearch | find "STOPPED" >nul 2>&1
if %errorlevel%==0 (echo [OK]   Windows Search disabled and stopped) else (echo [WARN] Windows Search may still be running)

:: Print Spooler
sc query Spooler | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop Spooler >nul 2>&1 & echo [OK]   Print Spooler stopped) else (echo [OK]   Print Spooler already stopped)

:: WiFi
sc query WlanSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop WlanSvc >nul 2>&1 & echo [OK]   WiFi service stopped) else (echo [OK]   WiFi already stopped)

:: Bluetooth
sc query BthAvctpSvc | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BthAvctpSvc >nul 2>&1)
sc query BTAGService | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop BTAGService >nul 2>&1)
sc query bthserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop bthserv >nul 2>&1 & echo [OK]   Bluetooth stopped) else (echo [OK]   Bluetooth already stopped)

:: Xbox Live
sc query XblAuthManager | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop XblAuthManager >nul 2>&1 & echo [OK]   Xbox Live Auth stopped) else (echo [OK]   Xbox Live Auth already stopped)

:: Backblaze (if installed)
sc query bzserv >nul 2>&1
if %errorlevel%==0 (
    sc query bzserv | find "RUNNING" >nul 2>&1
    if !errorlevel!==0 (sc stop bzserv >nul 2>&1 & echo [OK]   Backblaze stopped) else (echo [OK]   Backblaze already stopped)
) else (echo [OK]   Backblaze not installed)

:: OneDrive — stop to prevent sync conflicts with iRacing Documents folder
taskkill /IM OneDrive.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul
tasklist | find /i "OneDrive.exe" >nul 2>&1
if %errorlevel%==0 (echo [WARN] OneDrive still running) else (echo [OK]   OneDrive stopped)

:: Close Chrome and Claude before racing
taskkill /IM chrome.exe /F >nul 2>&1
tasklist | find /i "chrome.exe" >nul 2>&1
if %errorlevel%==0 (echo [WARN] Chrome still running) else (echo [OK]   Chrome closed)
taskkill /IM "Claude.exe" /F >nul 2>&1
taskkill /IM "claude-desktop.exe" /F >nul 2>&1
echo [OK]   Claude closed

:: Power plan -- AMD Ryzen Balanced (POWER_GUID is set in CONFIG at top)
powercfg /setactive %POWER_GUID% >nul 2>&1
if %errorlevel%==0 (echo [OK]   Power plan set to AMD Ryzen Balanced) else (echo [WARN] Could not set AMD Ryzen Balanced - check POWER_GUID in CONFIG / guide Section 06)

:: Process Lasso check
tasklist | find /i "ProcessLasso.exe" >nul 2>&1
if %errorlevel%==0 (
    echo [OK]   Process Lasso running
) else (
    echo [WARN] Starting Process Lasso...
    start "" "C:\Program Files\Process Lasso\ProcessLasso.exe"
    timeout /t 3 /nobreak >nul
)

:: Monitor refresh rate check - compares current Hz against the GPU-
:: reported max for the active mode (catches monitors that reset to a
:: lower Hz after sleep/reboot). Auto-detected every run, no setup
:: needed. Allows a 5Hz tolerance since drivers sometimes report 1-2
:: Hz under a panel's rated rate even while truly at max.
set "MONHZ="
set "MAXHZ="
for /f "tokens=1,2" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -command "$ErrorActionPreference='SilentlyContinue'; $d=Get-CimInstance Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'} | Select-Object -First 1; if($d -and $d.MaxRefreshRate){Write-Output ($d.CurrentRefreshRate.ToString()+' '+$d.MaxRefreshRate.ToString())}" 2^>nul') do (
    set "MONHZ=%%a"
    set "MAXHZ=%%b"
)
set "_REFRESH_DETECTED="
if defined MONHZ if defined MAXHZ if !MAXHZ! GTR 0 set "_REFRESH_DETECTED=1"
if defined _REFRESH_DETECTED (
    set /a "_MIN_REFRESH_HZ=!MAXHZ!-5"
    if !MONHZ! GEQ !_MIN_REFRESH_HZ! (
        echo [OK]   Monitor refresh rate: !MONHZ! Hz ^(max detected: !MAXHZ! Hz^)
    ) else (
        color 0C
        echo [FAIL] Monitor refresh rate: !MONHZ! Hz - below detected max ^(!MAXHZ! Hz^)
        echo        Fix: Settings ^> System ^> Display ^> Advanced display ^> refresh rate
        echo        Set ALL monitors to max Hz, then re-run this script
        pause
        color 0A
    )
) else (
    echo [WARN] Could not auto-detect monitor refresh rate - skipping check
)

:: NVIDIA MSI disable + interrupt affinity to CPU 7. NV_VENDEV and
:: NV_INSTANCES are set in CONFIG at the top. The loop applies the fix
:: to every instance; the quotes keep the & in each instance ID literal.
set "NV=HKLM\System\CurrentControlSet\Enum\PCI\%NV_VENDEV%"
for %%I in (%NV_INSTANCES%) do call :nvidia_affinity %%I

echo [OK]   NVIDIA interrupt affinity set to CPU 7 on all instances

:: Defender exclusions - only needed if real-time monitoring is still active
if %_DEFENDER_OFF%==0 goto :skip_exclusions
echo [WARN] Applying Defender exclusions as fallback...
set "_DP=C:\Program Files (x86)\iRacing" & set "_DL=iRacing install" & call :defender_path
set "_DP=%USERPROFILE%\Documents\iRacing" & set "_DL=iRacing documents" & call :defender_path
set "_DP=C:\Program Files\Process Lasso" & set "_DL=Process Lasso" & call :defender_path
set "_DP=C:\Program Files\CapFrameX" & set "_DL=CapFrameX" & call :defender_path
set "_DC=iRacingSim64DX11.exe" & call :defender_proc
set "_DC=iracinglocalserver64.exe" & call :defender_proc
set "_DC=iRacingService.exe" & call :defender_proc
set "_DC=CapFrameX.exe" & call :defender_proc
set "_DC=ProcessLasso.exe" & call :defender_proc
goto :after_exclusions
:skip_exclusions
echo [OK]   Defender exclusion checks skipped - monitoring suspended
:after_exclusions

:: NVIDIA driver version check (NV_DRIVER is set in CONFIG at top)
for /f "tokens=*" %%a in ('powershell -command "(Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like '*NVIDIA*'}).DriverVersion" 2^>nul') do set NVDRIVER=%%a
if defined NVDRIVER (
    if "!NVDRIVER!"=="%NV_DRIVER%" (echo [OK]   NVIDIA driver confirmed: !NVDRIVER!) else (echo [WARN] NVIDIA driver changed: !NVDRIVER! - re-verify GoInterruptPolicy settings after driver updates)
) else (echo [WARN] Could not read NVIDIA driver version)

:: Final wuauserv check
sc query wuauserv | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (sc stop wuauserv >nul 2>&1 & echo [WARN] Windows Update restarted itself - stopped again) else (echo [OK]   Windows Update confirmed stopped)

echo.
echo ============================================================
echo   Pre-launch complete. Launch iRacing now.
echo   Run post_iracing_session.bat when done racing.
echo ============================================================
echo.
pause
goto :eof

:: ---------------------------------------------------------------
:: Subroutine: set NVIDIA interrupt affinity on one device instance to CPU 7
:: Usage: call :nvidia_affinity INSTANCE_ID
:nvidia_affinity
set "_BASE=%NV%\%~1\Device Parameters\Interrupt Management"
:: Disable MSI mode — required on Win11 or affinity is silently ignored
reg add "!_BASE!\MessageSignaledInterruptProperties" /v MSISupported /t REG_DWORD /d 0 /f >nul 2>&1
:: Set interrupt affinity to CPU 7
reg add "!_BASE!\Affinity Policy" /v DevicePolicy /t REG_DWORD /d 4 /f >nul 2>&1
reg add "!_BASE!\Affinity Policy" /v AssignmentSetOverride /t REG_BINARY /d 8000000000000000 /f >nul 2>&1
reg add "!_BASE!\Affinity Policy" /v DevicePriority /t REG_DWORD /d 3 /f >nul 2>&1
if !errorlevel!==0 (echo [OK]   NVIDIA MSI disabled + affinity CPU7: "%~1") else (echo [WARN] Could not set: "%~1")
exit /b

:: ---------------------------------------------------------------
:: Subroutine: check and auto-add Defender path exclusion
:defender_path
powershell -command "$p=(Get-MpPreference).ExclusionPath; if ($p -contains '!_DP!') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel!==1 (
    powershell -command "Add-MpPreference -ExclusionPath '!_DP!'" >nul 2>&1
    if !errorlevel!==0 (echo [FIXED] Defender exclusion added: "!_DL!") else (echo [FAIL]  Could not add exclusion: "!_DP!")
) else (echo [OK]    Defender exclusion: "!_DL!")
exit /b

:: Subroutine: check and auto-add Defender process exclusion
:defender_proc
powershell -command "$p=(Get-MpPreference).ExclusionProcess; if ($p -contains '!_DC!') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel!==1 (
    powershell -command "Add-MpPreference -ExclusionProcess '!_DC!'" >nul 2>&1
    if !errorlevel!==0 (echo [FIXED] Defender process exclusion added: "!_DC!") else (echo [FAIL]  Could not add: "!_DC!")
) else (echo [OK]    Defender exclusion: "!_DC!" ^(process^))
exit /b
