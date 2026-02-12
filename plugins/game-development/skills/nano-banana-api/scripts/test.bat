@echo off
chcp 65001 > nul
echo.
echo ============================================
echo      Nano Banana API 测试脚本
echo ============================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python 解释器！
    pause
    exit /b 1
)

REM 检查主程序是否正在运行
tasklist | findstr "python" >nul
if %errorlevel% neq 0 (
    echo [警告] 服务器可能没有正在运行
    echo 建议先运行 start.bat 启动服务器
    echo.
    echo 是否要先启动服务器？(Y/N)
    set /p "choice="
    if /i "%choice%"=="Y" (
        start "Nano Banana API" /min "start.bat"
        echo [信息] 服务器正在启动中，请等待几秒钟后再次运行测试
        echo.
        pause
        exit /b 0
    )
)

REM 执行测试脚本
echo [信息] 正在运行 API 测试...
python "api_test.py" %*

echo.
echo ============================================
echo      测试完成
echo ============================================
echo.
echo 测试结果说明：
echo ✅ 表示测试通过
echo ❌ 表示测试失败
echo ⚠️  表示警告或预期的错误
echo.
echo 如果文生图测试失败，请检查：
echo 1. 服务器是否正常运行
echo 2. .env 文件中是否配置了正确的 API 密钥
echo 3. 是否有网络连接问题
echo.
pause
