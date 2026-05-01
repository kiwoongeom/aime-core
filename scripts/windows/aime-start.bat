@echo off
REM ============================================
REM   Aime Start - Template (Windows + WSL)
REM ============================================
REM
REM Reads:
REM   %USERPROFILE%\.aime\last-wallet-address.txt   (your address)
REM   %USERPROFILE%\.aime\wallet-password.txt       (your password, optional)
REM
REM Set up address first via:
REM   wsl ./aime-set-address.sh A...your-address...
REM
REM Set wallet password (one-time, optional for auto-login):
REM   echo your-password > %USERPROFILE%\.aime\wallet-password.txt
REM ============================================

title Aime Start
color 0A

echo.
echo ============================================
echo   Aime Start (Daemon + Mining + Wallet)
echo ============================================
echo.

REM --- Read wallet address ---
if not exist "%USERPROFILE%\.aime\last-wallet-address.txt" (
    echo ERROR: Wallet address file not found.
    echo.
    echo Set it first via WSL:
    echo   wsl ~/aime-miner/aime-set-address.sh A...your-address...
    echo.
    pause
    exit /b 1
)
set /p ADDR=<"%USERPROFILE%\.aime\last-wallet-address.txt"
if "%ADDR%"=="" (
    echo ERROR: Wallet address file is empty.
    pause
    exit /b 1
)
echo Address: %ADDR:~0,16%...
echo.

REM --- Read wallet password (optional) ---
set "PASS_FLAG="
if exist "%USERPROFILE%\.aime\wallet-password.txt" (
    set /p WALLET_PASS=<"%USERPROFILE%\.aime\wallet-password.txt"
    set "PASS_FLAG=--password %WALLET_PASS%"
    echo Wallet auto-login enabled
) else (
    echo Wallet password not saved - you will be prompted
)
echo.

REM --- Cleanup previous instances ---
echo [0/4] Cleaning up previous instances...
wsl -u root -- pkill -9 -f aimed 2>nul
wsl -u root -- pkill -f xmrig 2>nul
timeout /t 2 /nobreak >nul

REM --- Start daemon ---
echo [1/4] Opening Daemon window...
start "Aime Daemon" cmd /k "wsl -u root -- /root/aime/scripts/linux/aime-daemon.sh"

REM --- Wait for daemon RPC ready ---
echo [2/4] Waiting for daemon to be ready...
set /a TRIES=0
:wait_daemon
timeout /t 2 /nobreak >nul
set /a TRIES=TRIES+1
powershell -NoProfile -Command "try { Invoke-WebRequest 'http://127.0.0.1:17081/get_info' -UseBasicParsing -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" 2>nul
if errorlevel 1 (
    if %TRIES% GTR 30 (
        echo ERROR: Daemon did not start within 60s.
        pause
        exit /b 1
    )
    goto wait_daemon
)
echo Daemon ready.

REM --- Start mining ---
echo [3/4] Starting mining via daemon RPC...
powershell -NoProfile -Command "$body = @{miner_address='%ADDR%'; threads_count=4} | ConvertTo-Json; $r = Invoke-WebRequest 'http://127.0.0.1:17081/start_mining' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing; ($r.Content | ConvertFrom-Json).status"
echo.

REM --- Open wallet ---
echo [4/4] Opening Wallet window...
start "Aime Wallet" cmd /k "wsl -u root -- /root/aime/src/aime/build/Linux/aime-main/release/bin/aime-wallet-cli --wallet-file /root/aime-real --daemon-address 127.0.0.1:17081 %PASS_FLAG%"

echo.
echo ============================================
echo   Mining started (4 threads default)
echo ============================================
echo.
echo To change thread count: edit threads_count value in this script
echo.
timeout /t 8 >nul
exit
