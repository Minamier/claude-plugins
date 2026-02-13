#!/bin/bash
# Nano Banana API 测试脚本
# 适用于 Windows (Git Bash), macOS 和 Linux 系统

set -e  # 遇到错误时停止执行

# 颜色输出函数
red() { echo -e "\033[0;31m$1\033[0m"; }
green() { echo -e "\033[0;32m$1\033[0m"; }
yellow() { echo -e "\033[0;33m$1\033[0m"; }
blue() { echo -e "\033[0;34m$1\033[0m"; }
white() { echo -e "\033[0;37m$1\033[0m"; }

# 配置变量
API_HOST="127.0.0.1"
API_PORT="5000"

# 检查 curl 是否可用
check_curl() {
    if ! command -v curl &> /dev/null; then
        red "未找到 curl 命令！"
        red "请先安装 curl（Windows 系统可通过 Git Bash 或 Chocolatey 安装）"
        exit 1
    fi
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
                API_HOST="$2"
                shift
                shift
                ;;
            --port)
                API_PORT="$2"
                shift
                shift
                ;;
            *)
                echo "未知参数: $1"
                echo "使用 --help 查看可用参数"
                exit 1
                ;;
        esac
    done
}

# 显示帮助信息
show_help() {
    cat << 'EOF'
Nano Banana API 测试脚本

Usage: ./test.sh [OPTIONS]

测试 Nano Banana API 的功能

Options:
  -h, --help          显示此帮助信息
  --host HOST         API 服务器地址（默认：127.0.0.1）
  --port PORT         API 服务器端口（默认：5000）

Examples:
  ./test.sh
  ./test.sh --host 0.0.0.0 --port 8080
EOF
}

# 测试健康检查
test_ping() {
    blue "正在测试健康检查 API..."
    local url="http://${API_HOST}:${API_PORT}/ping"

    if response=$(curl -s -w "%{http_code}" "$url" -o api_response.txt); then
        if [ "$response" -eq 200 ]; then
            if grep -q '"status":"ok"' api_response.txt; then
                green "✅ 健康检查通过"
                cat api_response.txt
                echo
            else
                red "❌ 健康检查响应内容不正确"
                cat api_response.txt
                echo
            fi
        else
            red "❌ 健康检查失败，HTTP 状态码: $response"
            if [ -s api_response.txt ]; then
                cat api_response.txt
                echo
            fi
        fi
    else
        red "❌ 无法连接到服务器"
    fi
}

# 测试根路径
test_root() {
    blue "正在测试根路径 API..."
    local url="http://${API_HOST}:${API_PORT}/"

    if response=$(curl -s -w "%{http_code}" "$url" -o api_response.txt); then
        if [ "$response" -eq 200 ]; then
            if grep -q '"message":"Stable Diffusion API 服务已启动"' api_response.txt; then
                green "✅ 根路径 API 测试通过"
                if [ "$(wc -l < api_response.txt)" -le 20 ]; then
                    cat api_response.txt
                else
                    head -20 api_response.txt
                    echo "..."
                fi
                echo
            else
                red "❌ 根路径响应内容不正确"
                head -10 api_response.txt
                echo "..."
                echo
            fi
        else
            red "❌ 根路径访问失败，HTTP 状态码: $response"
            if [ -s api_response.txt ]; then
                cat api_response.txt
                echo
            fi
        fi
    else
        red "❌ 无法连接到服务器"
    fi
}

# 测试文生图 API（无 API 密钥）
test_txt2img_no_key() {
    blue "正在测试文生图 API（无 API 密钥）..."
    local url="http://${API_HOST}:${API_PORT}/txt2img"
    local payload='{"prompt":"cartoon horse","width":512,"height":512,"steps":10,"samples":1}'

    if response=$(curl -s -w "%{http_code}" -X POST "$url" -H 'Content-Type: application/json' -d "$payload" -o api_response.txt); then
        if [ "$response" -eq 500 ]; then
            if grep -q 'API 密钥未配置或无效' api_response.txt; then
                yellow "⚠️  预期的 API 密钥错误：API 密钥未配置或无效"
                cat api_response.txt
                echo
            else
                red "❌ 未预期的错误响应"
                cat api_response.txt
                echo
            fi
        else
            red "❌ 预期 500 错误，但收到状态码: $response"
            cat api_response.txt
            echo
        fi
    else
        red "❌ 无法连接到服务器"
    fi
}

# 测试文生图 API（带 API 密钥）
test_txt2img_with_key() {
    blue "正在测试文生图 API（带 API 密钥）..."
    local url="http://${API_HOST}:${API_PORT}/txt2img"
    local api_key=$(grep -E '^STABILITY_API_KEY=' .env | sed -e 's/^STABILITY_API_KEY="//' -e 's/"$//')

    if [ -z "$api_key" ]; then
        yellow "⚠️  .env 文件中未找到有效的 API 密钥，跳过测试"
        return
    fi

    # 如果是占位值，则跳过测试
    if [[ "$api_key" == *"your_actual_api_key"* ]] || [[ "$api_key" == *"fake_key"* ]] || [[ "$api_key" == "" ]]; then
        yellow "⚠️  找到无效的 API 密钥，跳过测试"
        return
    fi

    local payload="{\"prompt\":\"cartoon horse, cute style, white background\",\"negative_prompt\":\"ugly, blurry, low quality\",\"width\":512,\"height\":512,\"steps\":10,\"samples\":1}"

    if response=$(curl -s -w "%{http_code}" -X POST "$url" -H 'Content-Type: application/json' -d "$payload" -o api_response.txt); then
        if [ "$response" -eq 200 ]; then
            if grep -q '"base64":' api_response.txt; then
                green "✅ 文生图 API 测试通过"
                local count=$(grep -o '"base64":' api_response.txt | wc -l)
                white "生成了 $count 张图片"
                local img_data=$(grep -o '"base64":"[^"]*"' api_response.txt | head -1 | cut -d'"' -f4 | head -20)
                blue "第一张图片数据: ${img_data}..."
                echo
            else
                red "❌ 文生图 API 响应内容不正确"
                cat api_response.txt
                echo
            fi
        else
            red "❌ 文生图 API 失败，HTTP 状态码: $response"
            cat api_response.txt
            echo
        fi
    else
        red "❌ 无法连接到服务器"
    fi
}

# 显示汇总信息
show_summary() {
    green "=================================="
    green "Nano Banana API 测试完成！"
    green "=================================="
    echo
    blue "服务器信息："
    white "  - 地址: http://${API_HOST}:${API_PORT}"
    if [ -f ".env" ]; then
        local api_key=$(grep -E '^STABILITY_API_KEY=' .env | sed -e 's/^STABILITY_API_KEY="//' -e 's/"$//')
        if [ -n "$api_key" ]; then
            white "  - API 密钥: ${api_key:0:8}..."
        fi
    fi
    echo
    blue "测试结果："
    if [ "$TEST_PING" = "success" ]; then
        green "  ✅ 健康检查通过"
    else
        red "  ❌ 健康检查失败"
    fi
    if [ "$TEST_ROOT" = "success" ]; then
        green "  ✅ 根路径 API 通过"
    else
        red "  ❌ 根路径 API 失败"
    fi
    if [ "$TEST_TXT2IMG_NO_KEY" = "success" ]; then
        yellow "  ⚠️  文生图 API（无密钥）：预期错误"
    else
        red "  ❌ 文生图 API（无密钥）：未预期响应"
    fi
    if [ "$TEST_TXT2IMG_WITH_KEY" = "success" ]; then
        green "  ✅ 文生图 API（有密钥）通过"
    else
        red "  ❌ 文生图 API（有密钥）失败"
    fi
}

# 主函数
main() {
    white "开始测试 Nano Banana API..."
    echo

    check_curl
    check_arguments "$@"
    echo

    # 初始化测试结果变量
    TEST_PING="fail"
    TEST_ROOT="fail"
    TEST_TXT2IMG_NO_KEY="fail"
    TEST_TXT2IMG_WITH_KEY="fail"

    # 执行测试
    echo "测试 1: 健康检查"
    test_ping && TEST_PING="success"
    echo "----------------------------------"
    echo

    echo "测试 2: 根路径"
    test_root && TEST_ROOT="success"
    echo "----------------------------------"
    echo

    echo "测试 3: 文生图 API（无密钥）"
    test_txt2img_no_key && TEST_TXT2IMG_NO_KEY="success"
    echo "----------------------------------"
    echo

    echo "测试 4: 文生图 API（有密钥）"
    test_txt2img_with_key && TEST_TXT2IMG_WITH_KEY="success"
    echo "----------------------------------"
    echo

    # 清理临时文件
    if [ -f api_response.txt ]; then
        rm -f api_response.txt
    fi

    show_summary
}

# 脚本执行入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
