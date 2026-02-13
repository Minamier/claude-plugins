@echo off
chcp 65001 >nul
title GLM Image API 服务器 (Windows)

set "SCRIPT_DIR=%~dp0"
set "SKILL_DIR=%SCRIPT_DIR%.."
set "ENV_FILE=%SKILL_DIR%\.env"
set "API_SCRIPT=%SKILL_DIR%\glm_image_api.py"

echo ============================================
echo        GLM Image API 服务器启动
echo ============================================
echo.

:: 检查API脚本是否存在
if not exist "%API_SCRIPT%" (
    echo ❌ 错误: API 脚本不存在: %API_SCRIPT%
    pause
    exit /b 1
)

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

:: 读取并检查API密钥
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
    echo ⚠️  GLM_API_KEY 未配置
    set /p API_KEY="请输入您的GLM API Key: "
    python - <<END
import os
env_file = r"%ENV_FILE%"
with open(env_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()
updated = False
for i, line in enumerate(lines):
    if line.strip().startswith('GLM_API_KEY='):
        lines[i] = f'GLM_API_KEY="{API_KEY}"\n'
        updated = True
if not updated:
    lines.append(f'GLM_API_KEY="{API_KEY}"\n')
with open(env_file, 'w', encoding='utf-8') as f:
    f.writelines(lines)
END
    echo ✅ GLM_API_KEY 已更新
)

if "%API_SECRET%"=="" (
    echo ⚠️  GLM_API_SECRET 未配置
    set /p API_SECRET="请输入您的GLM API Secret: "
    python - <<END
import os
env_file = r"%ENV_FILE%"
with open(env_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()
updated = False
for i, line in enumerate(lines):
    if line.strip().startswith('GLM_API_SECRET='):
        lines[i] = f'GLM_API_SECRET="{API_SECRET}"\n'
        updated = True
if not updated:
    lines.append(f'GLM_API_SECRET="{API_SECRET}"\n')
with open(env_file, 'w', encoding='utf-8') as f:
    f.writelines(lines)
END
    echo ✅ GLM_API_SECRET 已更新
)

:: 读取服务器配置
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

echo.
echo 📋 服务器配置:
echo    地址: %SERVER_HOST%
echo    端口: %SERVER_PORT%
echo.
echo 🚀 正在启动 GLM Image API 服务器...
echo 📖 按 Ctrl+C 停止服务器
echo ============================================
echo.

:: 启动服务器
python "%API_SCRIPT%" server --host "%SERVER_HOST%" --port "%SERVER_PORT%"

pause
