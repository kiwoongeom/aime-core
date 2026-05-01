@echo off
REM ============================================
REM   Aime Start - Daemon + Mining + Wallet
REM ============================================
REM
REM Auto-detects aimed/wallet-cli in WSL home (~/aime-core/build/...).
REM Override via WSL env vars: AIME_DAEMON, AIME_WALLET_CLI, AIME_WALLET_FILE.
REM
REM Required setup (one-time, in WSL):
REM   git clone https://github.com/kiwoongeom/aime-core.git ~/aime-core
REM   cd ~/aime-core && make release
REM   git clone https://github.com/kiwoongeom/aime-miner.git ~/aime-miner
REM   ~/aime-miner/aime-set-address.sh A...your-95-char-address
REM
REM Optional: save wallet password for auto-login (security risk):
REM   echo your-password > %USERPROFILE%\.aime\wallet-password.txt

title Aime Start
color 0A

echo.
echo ============================================
echo   Aime Start (Daemon + Mining + Wallet)
echo ============================================
echo.

REM Read wallet address (required)
if not exist "%USERPROFILE%\.aime\last-wallet-address.txt" (
    echo ERROR: Wallet address not set.
    echo.
    echo In WSL run:
    echo   ~/aime-miner/aime-set-address.sh A...your-95-char-address
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

REM Read wallet password (optional auto-login)
set "PASS_FLAG="
if exist "%USERPROFILE%\.aime\wallet-password.txt" (
    set /p WALLET_PASS=<"%USERPROFILE%\.aime\wallet-password.txt"
    set "PASS_FLAG=--password %WALLET_PASS%"
    echo Wallet auto-login enabled
) else (
    echo Wallet password not saved - you will be prompted
)
echo.

REM Cleanup previous instances
echo [0/4] Cleaning up previous instances...
wsl -- pkill -9 -f aimed 2>nul
wsl -- pkill -f xmrig 2>nul
timeout /t 2 /nobreak >nul

REM Start daemon
echo [1/4] Opening Daemon window...
start "Aime Daemon" cmd /k "wsl -- bash -lc '~/aime-core/scripts/linux/aime-daemon.sh'"

REM Wait for daemon RPC
echo [2/4] Waiting for daemon to be ready...
set /a TRIES=0
:wait_daemon
timeout /t 2 /nobreak >nul
set /a TRIES=TRIES+1
powershell -NoProfile -Command "try { Invoke-WebRequest 'http://127.0.0.1:17081/get_info' -UseBasicParsing -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" 2>nul
if errorlevel 1 (
    if %TRIES% GTR 30 (
        echo ERROR: Daemon did not respond on port 17081 within 60 seconds.
        echo Check the Daemon window for errors.
        pause
        exit /b 1
    )
    goto wait_daemon
)
echo Daemon ready.

REM Start mining via RPC
echo [3/4] Starting mining...
powershell -NoProfile -Command "$body = @{miner_address='%ADDR%'; threads_count=4} | ConvertTo-Json; $r = Invoke-WebRequest 'http://127.0.0.1:17081/start_mining' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing; ($r.Content | ConvertFrom-Json).status"
echo.

REM Open wallet
echo [4/4] Opening Wallet window...
start "Aime Wallet" cmd /k "wsl -- bash -lc '~/aime-core/scripts/linux/aime-wallet.sh %PASS_FLAG%'"

echo.
echo ============================================
echo   Mining started + Wallet ready
echo ============================================
echo.
echo Wallet useful commands:
echo   refresh    Sync chain
echo   balance    Show AIME balance
echo   address    Show your address
echo   exit       Quit
echo.
echo To stop: run aime-stop.bat
echo Default mining threads: 4 (edit this script to change)
echo.
timeout /t 8 >nul
exit
