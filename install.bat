@echo off
chcp 65001 >nul
echo ============================================
echo   Laminar + SampleManager Installer
echo ============================================
echo.

:: --- 1. Obsidian vault 경로 ---
set "VAULT_PATH="
set /p VAULT_PATH="Obsidian vault 경로를 입력하세요: "

if not exist "%VAULT_PATH%\.obsidian" (
    echo ERROR: %VAULT_PATH%\.obsidian 폴더를 찾을 수 없습니다.
    pause
    exit /b 1
)

set "PLUGINS_DIR=%VAULT_PATH%\.obsidian\plugins"
if not exist "%PLUGINS_DIR%" mkdir "%PLUGINS_DIR%"

:: --- 2. 플러그인 복사 ---
echo [1/4] Laminar 플러그인 설치 중...
if not exist "%PLUGINS_DIR%\laminar" mkdir "%PLUGINS_DIR%\laminar"
copy /Y "%~dp0laminar\main.js" "%PLUGINS_DIR%\laminar\" >nul
copy /Y "%~dp0laminar\styles.css" "%PLUGINS_DIR%\laminar\" >nul
copy /Y "%~dp0laminar\manifest.json" "%PLUGINS_DIR%\laminar\" >nul
echo   OK: Laminar 플러그인 설치 완료

echo [2/4] Sample Manager Launcher 플러그인 설치 중...
if not exist "%PLUGINS_DIR%\obsidian-samplelog-main" mkdir "%PLUGINS_DIR%\obsidian-samplelog-main"
copy /Y "%~dp0obsidian-samplelog-main\main.js" "%PLUGINS_DIR%\obsidian-samplelog-main\" >nul
copy /Y "%~dp0obsidian-samplelog-main\manifest.json" "%PLUGINS_DIR%\obsidian-samplelog-main\" >nul
echo   OK: Launcher 플러그인 설치 완료

:: --- 3. SampleManager ---
set "SM_DIR=%~dp0..\Sample_Manager"
echo.
echo [3/4] SampleManager 확인 중...
if exist "%SM_DIR%\.git" (
    echo   업데이트 중...
    cd /d "%SM_DIR%" && git pull
    echo   OK: SampleManager 업데이트 완료
) else (
    echo   SampleManager clone 중...
    git clone https://github.com/F1rstPenguin/Sample_Manager.git "%SM_DIR%"
    echo   OK: SampleManager clone 완료
)

:: --- 4. Python 가상환경 ---
echo.
echo [4/4] Python 가상환경 확인 중...
if exist "%SM_DIR%\.venv" (
    echo   OK: 가상환경 이미 존재
) else (
    echo   가상환경 생성 중...
    python -m venv "%SM_DIR%\.venv"
    echo   패키지 설치 중...
    "%SM_DIR%\.venv\Scripts\pip" install -r "%SM_DIR%\requirements.txt" -q
    echo   OK: 가상환경 설정 완료
)

echo.
echo ============================================
echo   설치 완료!
echo ============================================
echo.
echo 다음 단계:
echo   1. Obsidian을 실행하고 vault를 엽니다
echo   2. 설정 - 커뮤니티 플러그인에서 Laminar, Sample Manager Launcher 활성화
echo   3. SampleManager 첫 실행 시 Obsidian vault 경로를 설정합니다
echo.
pause
