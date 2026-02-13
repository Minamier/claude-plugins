@echo off
chcp 65001 >nul
title GLM Image 技能安装脚本 (Windows)

echo ============================================
echo         GLM Image 技能安装程序
echo ============================================
echo.

:: 检查Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 Python，请先安装 Python 3.7 或更高版本
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ Python 版本: %PYTHON_VERSION%

set "SCRIPT_DIR=%~dp0"
set "SKILL_DIR=%SCRIPT_DIR%.."
set "ENV_FILE=%SKILL_DIR%\.env"
set "ENV_EXAMPLE_FILE=%SKILL_DIR%\.env.example"

:: 创建配置文件
if not exist "%ENV_FILE%" (
    if exist "%ENV_EXAMPLE_FILE%" (
        copy "%ENV_EXAMPLE_FILE%" "%ENV_FILE%" >nul
        echo ✅ 已创建配置文件: %ENV_FILE%
    ) else (
        echo ❌ 错误: 配置文件模板不存在 %ENV_EXAMPLE_FILE%
        pause
        exit /b 1
    )
) else (
    echo ℹ️  配置文件已存在: %ENV_FILE%
)

:: 安装依赖
echo 📦 正在安装 Python 依赖库...
python -m pip install python-dotenv flask requests

if %errorlevel% equ 0 (
    echo ✅ 依赖库安装成功
) else (
    echo ❌ 依赖库安装失败，请检查网络连接
    pause
    exit /b 1
)

:: 检查API密钥
set "API_KEY="
set "API_SECRET="
for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /r /c:"GLM_API_KEY=" /c:"GLM_API_SECRET="') do (
    if "%%a"=="GLM_API_KEY" set "API_KEY=%%b"
    if "%%a"=="GLM_API_SECRET" set "API_SECRET=%%b"
)

:: 去除引号
set "API_KEY=%API_KEY:"=%"
set "API_SECRET=%API_SECRET:"=%"

if "%API_KEY%"=="" (
    echo ⚠️ GLM_API_KEY 未配置
)
if "%API_SECRET%"=="" (
    echo ⚠️ GLM_API_SECRET 未配置
)

if "%API_KEY%"=="" or "%API_SECRET%"=="" (
    echo.
    echo 请运行 edit_config.bat 配置 API 密钥
)

echo.
echo ============================================
echo ✅ 安装完成！
echo ============================================
echo.
echo 使用说明:
echo   🚀 启动服务器: start.bat
echo   📝 配置 API 密钥: edit_config.bat
echo   🧪 测试 API: test.bat
echo   📚 查看文档: type ..\SKILL.md
echo.
echo API 文档: https://docs.bigmodel.cn/api-reference/模型-api/图像生成

pause
