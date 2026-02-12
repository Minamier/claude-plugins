@echo off
chcp 65001 >nul
title GLM Image 配置编辑脚本 (Windows)

set "SCRIPT_DIR=%~dp0"
set "SKILL_DIR=%SCRIPT_DIR%.."
set "ENV_FILE=%SKILL_DIR%\.env"
set "ENV_EXAMPLE_FILE=%SKILL_DIR%\.env.example"

:: 检查配置文件
if not exist "%ENV_FILE%" (
    if exist "%ENV_EXAMPLE_FILE%" (
        copy "%ENV_EXAMPLE_FILE%" "%ENV_FILE%" >nul
        echo ✅ 已创建配置文件: %ENV_FILE%
    ) else (
        echo ❌ 错误: 配置文件模板不存在
        pause
        exit /b 1
    )
)

echo 🎯 正在使用记事本打开配置文件:
echo    %ENV_FILE%
echo.
echo 📝 配置说明:
echo    GLM_API_KEY     : 您的GLM API密钥
echo    GLM_API_SECRET  : 您的GLM API密钥密码
echo    DEFAULT_WIDTH   : 默认图像宽度
echo    DEFAULT_HEIGHT  : 默认图像高度
echo    DEFAULT_MODEL   : 默认使用的模型
echo    DEFAULT_STYLE   : 默认图像风格
echo    SERVER_HOST     : 服务器监听地址
echo    SERVER_PORT     : 服务器监听端口
echo.
echo 🔗 API密钥获取地址: https://console.volcengine.com/
echo.
pause

notepad "%ENV_FILE%"

echo.
echo ✅ 配置文件已保存
echo.
echo 📋 当前配置:
echo ----------------------------------------
type "%ENV_FILE%" | findstr /r /c:"GLM_API_KEY=" /c:"GLM_API_SECRET=" /c:"DEFAULT_" /c:"SERVER_"
echo.
pause
