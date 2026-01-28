@echo off
:: 오늘 날짜로 백업 폴더 생성 (예: backup\2026-01-28)
set SRC="d:\HedgeFreedom"
set BACKUPROOT="d:\HedgeFreedom\backup"
for /f "tokens=2 delims==." %%I in ('wmic os get localdatetime /value') do set dt=%%I
set YYYY=%dt:~0,4%
set MM=%dt:~4,2%
set DD=%dt:~6,2%
set TODAY=%YYYY%-%MM%-%DD%
set DEST=%BACKUPROOT%\%TODAY%

if not exist %DEST% mkdir %DEST%

echo 변경된 파일만 %DEST% 폴더에 백업합니다...
robocopy %SRC% %DEST% /E /XO /XC /XN /XX
echo 백업이 완료되었습니다.
pause
