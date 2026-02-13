#!/bin/bash
# Nano Banana API 配置编辑脚本
# 适用于 Windows (Git Bash), macOS 和 Linux 系统

set -e  # 遇到错误时停止执行

# 颜色输出函数
red() { echo -e "\033[0;31m$1\033[0m"; }
green() { echo -e "\033[0;32m$1\033[0m"; }
yellow() { echo -e "\033[0;33m$1\033[0m"; }
blue() { echo -e "\033[0;34m$1\033[0m"; }
white() { echo -e "\033[0;37m$1\033[0m"; }

# 检查配置文件是否存在
check_config() {
    if [ ! -f ".env" ]; then
        yellow ".env 配置文件不存在，正在从模板创建..."
        if [ -f "../.env.example" ]; then
            cp "../.env.example" ".env"
            green "已创建 .env 配置文件"
        else
            red "未找到 .env.example 模板文件！"
            red "请先运行安装脚本：./install.sh"
            exit 1
        fi
    fi
}

# 打开编辑器
open_editor() {
    blue "正在打开配置文件编辑器..."

    # 尝试自动检测系统默认编辑器
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        open -t .env
    elif [ "$OS" = "Windows_NT" ]; then
        # Windows (Git Bash)
        start notepad.exe .env
    elif [ -n "$EDITOR" ]; then
        # 使用环境变量指定的编辑器
        $EDITOR .env
    elif command -v nano &> /dev/null; then
        nano .env
    elif command -v vi &> /dev/null; then
        vi .env
    elif command -v vim &> /dev/null; then
        vim .env
    else
        red "未找到可用的文本编辑器！"
        red "请手动编辑 .env 文件"
        exit 1
    fi
}

# 显示成功信息
show_success() {
    echo
    green "=================================="
    green "配置文件编辑完成！"
    green "=================================="
    echo
    blue "下一步操作："
    echo "1. 启动 API 服务器：./start.sh"
    echo "2. 测试 API 功能：./test.sh"
    echo
    yellow "注意：如果您修改了 API 密钥，需要重启服务器才能生效"
}

# 主函数
main() {
    white "Nano Banana API 配置编辑器"
    echo
    check_config
    open_editor
    show_success
}

# 脚本执行入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
