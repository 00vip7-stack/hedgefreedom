@echo off
REM Git 저장소 변경사항을 커밋하고 푸시하는 스크립트 (최초 커밋/브랜치 자동 처리)

set /p msg="커밋 메시지를 입력하세요: "
if "%msg%"=="" set msg=auto-commit

git add .
git commit -m "%msg%"

REM main 브랜치가 없으면 생성 및 이동
for /f "delims=" %%b in ('git branch --show-current') do set branch=%%b
if not "%branch%"=="main" git branch -M main

git push -u origin main

pause
