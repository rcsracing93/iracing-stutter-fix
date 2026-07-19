@echo off
setlocal
title iRacing - Find My Values
color 0B

echo ============================================================
echo   find_my_values.bat   (READ-ONLY - changes nothing)
echo.
echo   This writes my_values.bat next to this script. Keep that
echo   file in the same folder as pre_iracing_launch.bat and it
echo   will be loaded automatically - no copy/paste needed.
echo   Tip: run as Administrator for complete results.
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $q=[char]34; $pg=([regex]'[0-9a-fA-F-]{36}').Match((powercfg /list | Select-String 'Ryzen Balanced' | Out-String)).Value; if(-not $pg){$pg='YOUR-AMD-RYZEN-BALANCED-GUID'}; $d=Get-CimInstance Win32_VideoController | Where-Object {$_.Name -match 'NVIDIA'} | Select-Object -First 1; if($d){$base=($d.PNPDeviceID -split '\\')[1]; $drv=$d.DriverVersion; $ins=Get-ChildItem ('HKLM:\SYSTEM\CurrentControlSet\Enum\PCI\'+$base) | Select-Object -ExpandProperty PSChildName} else {$base='YOUR-GPU-VEN-DEV-PATH'; $drv='YOUR-DRIVER-VERSION'; $ins=@()}; if($ins){$il=(($ins | ForEach-Object {$q+$_+$q}) -join ' ')} else {$il=$q+'YOUR_INSTANCE_1'+$q+' '+$q+'YOUR_INSTANCE_2'+$q}; Write-Host ('set '+$q+'POWER_GUID='+$pg+$q); Write-Host ('set '+$q+'NV_VENDEV='+$base+$q); Write-Host ('set NV_INSTANCES='+$il); Write-Host ('set '+$q+'NV_DRIVER='+$drv+$q)" > "%~dp0my_values.bat"

echo   Wrote my_values.bat:
echo   ------------------------------------------------------------
type "%~dp0my_values.bat"
echo   ------------------------------------------------------------
echo.
echo   Notes:
echo   - NV_INSTANCES lists every device instance found, each quoted.
echo   - Any value shown as YOUR-... could not be detected - see the
echo     guide (Section 05 / 06) to find it manually, then edit
echo     my_values.bat in a text editor (keep the same quoting).
echo   - The script targets CPU 7 by default; to pick another core
echo     see Section 05 and benchmark with AutoGpuAffinity.
echo   - Re-run this script any time your GPU or driver changes -
echo     it overwrites my_values.bat each time.
echo.
pause
