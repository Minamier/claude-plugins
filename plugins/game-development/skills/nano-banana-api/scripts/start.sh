#!/bin/bash
# Nano Banana API 启动脚本
# 适用于 Windows (Git Bash), macOS 和 Linux 系统

set -e  # 遇到错误时停止执行

# 颜色输出函数
red() { echo -e "\033[0;31m$1\033[0m"; }
green() { echo -e "\033[0;32m$1\033[0m"; }
yellow() { echo -e "\033[0;33m$1\033[0m"; }
blue() { echo -e "\033[0;34m$1\033[0m"; }
white() { echo -e "\033[0;37m$1\033[0m"; }

# 检查 Python 版本
check_python() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        red "未找到 Python 解释器！"
        red "请先安装 Python 3.8 或更高版本"
        exit 1
    fi

    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
}

# 检查配置文件
check_config() {
    if [ ! -f ".env" ]; then
        red ".env 配置文件不存在！"
        red "请先运行安装脚本：./install.sh"
        exit 1
    fi
}

# 检查主程序文件
check_main_program() {
    if [ ! -f "stable_diffusion_api.py" ]; then
        red "stable_diffusion_api.py 文件不存在！"
        red "请先运行安装脚本：./install.sh"
        exit 1
    fi
}

# 加载配置
load_config() {
    # 检查是否有 .env 文件
    if [ -f ".env" ]; then
        # 读取配置
        while IFS= read -r line; do
            # 忽略注释和空行
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ "$line" != "" ]]; then
                # 分割 key=value
                if [[ "$line" == *=* ]]; then
                    key=$(echo "$line" | cut -d'=' -f1 | tr -d '[:space:]')
                    value=$(echo "$line" | cut -d'=' -f2- | sed -e 's/^"//' -e 's/"$//' -e 's/^'\''//' -e 's/'\''$//')

                    if [ "$key" != "" ]; then
                        # 存储配置
                        case "$key" in
                            STABILITY_API_KEY)
                                API_KEY="$value"
                                ;;
                            SERVER_HOST)
                                HOST="$value"
                                ;;
                            SERVER_PORT)
                                PORT="$value"
                                ;;
                        esac
                    fi
                fi
            fi
        done < .env
    fi

    # 设置默认值
    : ${HOST:="127.0.0.1"}
    : ${PORT:="5000"}
    : ${API_KEY:=""}
}

# 检查参数
check_arguments() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -h|--help)
                show_help
                exit 0
                ;;
            --host)
                HOST="$2"
                shift
                shift
                ;;
            --port)
                PORT="$2"
                shift
                shift
                ;;
            --api-key)
                API_KEY="$2"
                shift
                shift
                ;;
            --debug)
                DEBUG="--debug"
                shift
                ;;
            --background)
                BACKGROUND="--background"
                shift
                ;;
            *)
                echo "未知参数: $1"
                echo "使用 --help 查看可用参数"
                exit 1
                ;;
        esac
    done

    # 验证端口号
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        red "端口号必须是数字：$PORT"
        exit 1
    fi

    if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        red "端口号必须在 1-65535 范围内：$PORT"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << 'EOF'
Nano Banana API 启动脚本

Usage: ./start.sh [OPTIONS]

启动 Nano Banana API 服务器

Options:
  -h, --help          显示此帮助信息
  --host HOST         服务器监听地址（默认：127.0.0.1）
  --port PORT         服务器监听端口（默认：5000）
  --api-key KEY       Stability-AI API 密钥（优先级高于 .env）
  --debug             开启调试模式
  --background        在后台运行（Windows 下使用 start /B，其他系统使用 nohup）

Environment variables:
  STABILITY_API_KEY   Stability-AI API 密钥（在 .env 文件中配置）

Examples:
  ./start.sh
  ./start.sh --host 0.0.0.0 --port 8080
  ./start.sh --api-key "your-key-here" --background
EOF
}

# 启动服务器
start_server() {
    blue "启动 Nano Banana API 服务器..."
    blue "监听地址: http://${HOST}:${PORT}"
    blue "调试模式: ${DEBUG:+开启}${DEBUG:-关闭}"
    blue "后台运行: ${BACKGROUND:+是}${BACKGROUND:-否}"
    echo

    # 准备命令参数
    COMMAND="$PYTHON_CMD stable_diffusion_api.py"
    if [ "$HOST" != "127.0.0.1" ]; then
        COMMAND="$COMMAND --host $HOST"
    fi
    if [ "$PORT" != "5000" ]; then
        COMMAND="$COMMAND --port $PORT"
    fi
    if [ -n "$API_KEY" ]; then
        COMMAND="$COMMAND --api-key \"$API_KEY\""
    fi
    if [ -n "$DEBUG" ]; then
        COMMAND="$COMMAND --debug"
    fi

    # 启动服务器
    if [ -n "$BACKGROUND" ]; then
        if [ "$(uname)" = "Darwin" ] || [ "$(uname)" = "Linux" ]; then
            # macOS/Linux: 使用 nohup
            nohup $COMMAND > api.log 2>&1 < /dev/null &
            PID=$!
            echo $PID > api.pid
            green "服务器已在后台启动，PID: $PID"
            blue "日志文件: $(pwd)/api.log"
        elif [ "$OS" = "Windows_NT" ]; then
            # Windows: 使用 start /B
            start /B $COMMAND > api.log 2>&1
            green "服务器已在后台启动"
            blue "日志文件: $(pwd)/api.log"
        else
            red "不支持的操作系统"
            exit 1
        fi
    else
        # 前台运行
        $COMMAND
    fi
}

# 显示成功信息
show_success() {
    green "=================================="
    green "Nano Banana API 启动成功！"
    green "=================================="
    echo
    blue "服务器信息："
    white "  - 地址: http://${HOST}:${PORT}"
    if [ -n "$API_KEY" ]; then
        white "  - API 密钥: ${API_KEY:0:8}..."
    fi
    white "  - 调试模式: ${DEBUG:+开启}${DEBUG:-关闭}"
    echo
    blue "测试命令："
    white "  curl -X GET http://${HOST}:${PORT}/ping"
    white "  curl -X POST http://${HOST}:${PORT}/txt2img \\"
    white "    -H 'Content-Type: application/json' \\"
    white "    -d '{\"prompt\":\"cartoon horse\",\"width\":512,\"height\":512}'"
}

# 检查是否已在运行
check_running() {
    # 检查是否有 pid 文件
    if [ -f "api.pid" ]; then
        PID=$(cat "api.pid")
        if kill -0 "$PID" 2>/dev/null; then
            yellow "检测到服务器已在运行 (PID: $PID)"
            read -p "是否要停止当前运行的服务器？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill "$PID"
                rm -f api.pid
                blue "服务器已停止"
                sleep 2
            else
                green "服务器继续运行"
                show_success
                exit 0
            fi
        else
            blue "PID 文件无效，可能是之前的运行残留"
            rm -f api.pid
        fi
    fi

    # 检查端口是否被占用
    if command -v lsof &> /dev/null; then
        if lsof -i :$PORT >/dev/null 2>&1; then
            yellow "端口 $PORT 已被占用"
            read -p "是否要继续使用这个端口？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
            yellow "端口 $PORT 已被占用"
            read -p "是否要继续使用这个端口？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    elif [ "$OS" = "Windows_NT" ]; then
        if netstat -an | findstr ":$PORT" >nul; then
            yellow "端口 $PORT 已被占用"
            read -p "是否要继续使用这个端口？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# 主函数
main() {
    white "启动 Nano Banana API..."
    echo

    check_python
    check_config
    check_main_program
    load_config
    check_arguments "$@"
    check_running
    start_server
    if [ -z "$BACKGROUND" ]; then
        # 前台运行时不会显示成功信息，因为命令阻塞了
    else
        show_success
    fi
}

# 脚本执行入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
