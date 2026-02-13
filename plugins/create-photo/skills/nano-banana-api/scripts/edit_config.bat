@echo off
chcp 65001 > nul
echo.
echo ============================================
echo      Nano Banana API 配置编辑器
echo ============================================
echo.

REM 检查配置文件是否存在
if not exist ".env" (
    echo [警告] .env 配置文件不存在，正在从模板创建...
    if exist "..\.env.example" (
        copy "..\.env.example" ".env" >nul
        echo [成功] 已创建 .env 配置文件
    ) else (
        echo [错误] 未找到 .env.example 模板文件！
        echo 请先运行 install.bat 进行安装
        pause
        exit /b 1
    )
)

echo [信息] 正在打开 .env 配置文件...
echo [提示] 请在记事本中编辑配置，完成后保存并关闭窗口
echo.

REM 使用记事本打开配置文件
notepad.exe .env

echo.
echo ============================================
echo      配置文件编辑完成！
echo ============================================
echo.
echo 下一步操作：
echo 1. 启动 API 服务器：start.bat
echo 2. 测试 API 功能：test.bat
echo.
echo 注意：如果您修改了 API 密钥，需要重启服务器才能生效
echo.
pause
