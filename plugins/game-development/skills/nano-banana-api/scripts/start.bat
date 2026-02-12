@echo off
chcp 65001 > nul
echo.
echo ============================================
echo      Nano Banana API 启动脚本
echo ============================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python 解释器！
    pause
    exit /b 1
)

REM 检查主程序文件
if not exist "stable_diffusion_api.py" (
    echo [错误] 未找到 stable_diffusion_api.py 文件！
    echo 请先运行 install.bat 进行安装
    pause
    exit /b 1
)

REM 检查配置文件
if not exist ".env" (
    echo [错误] 未找到 .env 配置文件！
    echo 请先运行 install.bat 进行安装
    pause
    exit /b 1
)

REM 检查 API 密钥是否已配置
for /f "tokens=1,2 delims==" %%a in (.env) do (
    if "%%a"=="STABILITY_API_KEY" (
        set "API_KEY=%%b"
    )
)

set "API_KEY=%API_KEY:"=%"
if "%API_KEY%"=="" (
    echo [错误] STABILITY_API_KEY 未配置！
    echo 请先运行 edit_config.bat 配置 API 密钥
    echo API 密钥可从 https://beta.stability.ai/ 获取
    pause
    exit /b 1
)

echo [信息] 正在启动 Nano Banana API 服务器...
echo.
echo 服务器配置：
echo - 监听地址：127.0.0.1:5000
echo - 引擎：stable-diffusion-xl-1024-v1-0
echo - 调试模式：关闭
echo.
echo 按 Ctrl+C 停止服务器
echo.

REM 读取 .env 文件获取配置
for /f "tokens=1,2 delims==" %%a in (.env) do (
    if "%%a"=="STABILITY_API_KEY" (
        set "API_KEY=%%b"
    )
    if "%%a"=="SERVER_HOST" (
        set "HOST=%%b"
    )
    if "%%a"=="SERVER_PORT" (
        set "PORT=%%b"
    )
)

REM 去除引号
set "API_KEY=%API_KEY:"=%"
set "HOST=%HOST:"=%"
set "PORT=%PORT:"=%"

REM 设置默认值
if "%HOST%"=="" set "HOST=127.0.0.1"
if "%PORT%"=="" set "PORT=5000"

REM 检查 API 密钥
if "%API_KEY%"=="" (
    echo [警告] 未找到 API 密钥！
    echo 服务器将启动但文生图功能将不可用
    echo 请编辑 .env 文件并添加 STABILITY_API_KEY
    echo.
) else (
    echo [信息] 使用的 API 密钥：%API_KEY:~0,8%...
)

echo.
echo [信息] 正在启动服务器...
python "stable_diffusion_api.py" --host %HOST% --port %PORT%
