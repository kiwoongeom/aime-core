@echo off
REM ============================================
REM   Aime Wallet - Template (Windows + WSL)
REM ============================================
REM
REM Optional auto-login: save password to
REM   %USERPROFILE%\.aime\wallet-password.txt
REM ============================================

title Aime Wallet
color 0B

echo.
echo ============================================
echo   Aime Wallet
echo ============================================
echo.

REM Check daemon
powershell -NoProfile -Command "try { Invoke-WebRequest 'http://127.0.0.1:17081/get_info' -UseBasicParsing -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR: Daemon not running.
    echo Run aime-start.bat first.
    pause
    exit /b 1
)
echo Daemon OK
echo.

REM Wallet password (optional auto-login)
set "PASS_FLAG="
if exist "%USERPROFILE%\.aime\wallet-password.txt" (
    set /p WALLET_PASS=<"%USERPROFILE%\.aime\wallet-password.txt"
    set "PASS_FLAG=--password %WALLET_PASS%"
    echo Auto-login enabled
) else (
    echo Will prompt for password
)
echo.
echo Useful commands:
echo   refresh        Sync chain
echo   balance        Show balance
echo   address        Show your address
echo   exit           Quit
echo.
echo ============================================
echo.

wsl -u root -- /root/aime/src/aime/build/Linux/aime-main/release/bin/aime-wallet-cli --wallet-file /root/aime-real --daemon-address 127.0.0.1:17081 %PASS_FLAG%

echo.
echo Wallet closed.
pause
