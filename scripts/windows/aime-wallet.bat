@echo off
REM ============================================
REM   Aime Wallet - opens CLI wallet
REM ============================================
REM
REM Auto-detects wallet-cli and wallet file (~/aime-real by default).
REM Override via WSL env vars: AIME_WALLET_CLI, AIME_WALLET_FILE.
REM
REM Optional auto-login: save password to
REM   %USERPROFILE%\.aime\wallet-password.txt
REM (Plain text - only acceptable for low-stakes wallets.)

title Aime Wallet
color 0B

echo.
echo ============================================
echo   Aime Wallet
echo ============================================
echo.

REM Verify daemon running
powershell -NoProfile -Command "try { Invoke-WebRequest 'http://127.0.0.1:17081/get_info' -UseBasicParsing -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR: Daemon not running on port 17081.
    echo Start it first with aime-start.bat
    pause
    exit /b 1
)
echo Daemon OK
echo.

REM Optional auto-login
set "PASS_FLAG="
if exist "%USERPROFILE%\.aime\wallet-password.txt" (
    set /p WALLET_PASS=<"%USERPROFILE%\.aime\wallet-password.txt"
    set "PASS_FLAG=--password %WALLET_PASS%"
    echo Auto-login enabled
) else (
    echo Will prompt for wallet password
)
echo.
echo Useful commands:
echo   refresh    Sync chain
echo   balance    Show balance
echo   address    Show your address
echo   exit       Quit
echo.
echo ============================================
echo.

wsl -- bash -lc "~/aime-core/scripts/linux/aime-wallet.sh %PASS_FLAG%"

echo.
echo Wallet closed.
pause
