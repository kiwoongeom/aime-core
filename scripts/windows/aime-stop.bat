@echo off
REM ============================================
REM   Aime Stop - kills daemon, miner, wallet
REM ============================================

title Aime Stop
color 0C

echo.
echo ============================================
echo   Aime Stop
echo ============================================
echo.

echo [1/3] Closing wallet (if open)...
wsl -- pkill -f aime-wallet-cli 2>nul

echo [2/3] Stopping miner threads (via RPC if daemon up)...
powershell -NoProfile -Command "try { Invoke-WebRequest 'http://127.0.0.1:17081/stop_mining' -Method POST -ContentType 'application/json' -Body '{}' -UseBasicParsing -TimeoutSec 2 | Out-Null } catch {}" 2>nul
wsl -- pkill -f xmrig 2>nul

echo [3/3] Stopping daemon...
wsl -- pkill -9 -f aimed 2>nul

timeout /t 2 /nobreak >nul

echo.
echo Stopped. You may close any remaining windows.
echo.
timeout /t 4 >nul
exit
