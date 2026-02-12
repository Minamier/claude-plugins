@echo off
chcp 65001 >nul
title GLM Image API 测试脚本 (Windows)

set "SCRIPT_DIR=%~dp0"
set "SKILL_DIR=%SCRIPT_DIR%.."
set "ENV_FILE=%SKILL_DIR%\.env"

echo ============================================
echo        GLM Image API 测试程序
echo ============================================
echo.

:: 检查配置文件
if not exist "%ENV_FILE%" (
    echo ℹ️  配置文件不存在，正在创建...
    if exist "%SKILL_DIR%\.env.example" (
        copy "%SKILL_DIR%\.env.example" "%ENV_FILE%" >nul
    ) else (
        echo ❌ 错误: 配置文件模板不存在
        pause
        exit /b 1
    )
)

:: 读取配置
set "SERVER_HOST="
set "SERVER_PORT="
for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /r /c:"SERVER_HOST=" /c:"SERVER_PORT="') do (
    if "%%a"=="SERVER_HOST" set "SERVER_HOST=%%b"
    if "%%a"=="SERVER_PORT" set "SERVER_PORT=%%b"
)

set "SERVER_HOST=%SERVER_HOST:"=%"
set "SERVER_PORT=%SERVER_PORT:"=%"

if "%SERVER_HOST%"=="" set "SERVER_HOST=127.0.0.1"
if "%SERVER_PORT%"=="" set "SERVER_PORT=5001"

set "API_URL=http://%SERVER_HOST%:%SERVER_PORT%"

echo 📋 API 配置:
echo    地址: %API_URL%
echo.

:: 检查服务器是否正在运行
echo 🔍 检查服务器状态...
curl -s "%API_URL%/ping" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 服务器正在运行
) else (
    echo ⚠️  服务器未运行，正在启动...
    start "" "%SCRIPT_DIR%\start.bat"
    echo ⏳ 等待服务器启动 (10秒)...
    timeout /t 10 /nobreak >nul

    curl -s "%API_URL%/ping" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ 服务器已启动
    ) else (
        echo ❌ 服务器启动失败
        echo.
        echo 请手动启动服务器并重新运行测试:
        echo    cd /d "%SCRIPT_DIR%"
        echo    start.bat
        pause
        exit /b 1
    )
)

echo.

:: 运行API测试
echo 🧪 正在运行 API 测试...
python "%SCRIPT_DIR%\api_test.py" --url "%API_URL%"

pause
