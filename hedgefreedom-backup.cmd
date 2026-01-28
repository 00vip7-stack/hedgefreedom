@echo off
set SRC="d:\HedgeFreedom"
set DEST="E:\HedgeFreedom_Backup"
echo 백업을 시작합니다...
xcopy %SRC% %DEST% /E /H /C /I /Y
echo 백업이 완료되었습니다.
pause
