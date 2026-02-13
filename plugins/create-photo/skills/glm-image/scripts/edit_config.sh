#!/bin/bash
# GLM Image 配置编辑脚本 (Linux/macOS)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SKILL_DIR/.env"
ENV_EXAMPLE_FILE="$SKILL_DIR/.env.example"

# 检查配置文件
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE_FILE" ]; then
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        echo "✓ 已创建配置文件: $ENV_FILE"
    else
        echo "❌ 错误: 配置文件模板不存在"
        exit 1
    fi
fi

# 检查并获取系统编辑器
if command -v nano &> /dev/null; then
    EDITOR=nano
elif command -v vim &> /dev/null; then
    EDITOR=vim
elif command -v vi &> /dev/null; then
    EDITOR=vi
elif command -v gedit &> /dev/null; then
    EDITOR=gedit
elif command -v xed &> /dev/null; then
    EDITOR=xed
else
    echo "⚠️  未找到文本编辑器，请手动编辑: $ENV_FILE"
    echo
    cat "$ENV_FILE"
    exit 0
fi

echo "🎯 正在打开配置文件: $ENV_FILE"
echo "📝 使用 $EDITOR 编辑器"
echo
echo "配置说明:"
echo "  GLM_API_KEY     : 您的GLM API密钥"
echo "  GLM_API_SECRET  : 您的GLM API密钥密码"
echo "  DEFAULT_WIDTH   : 默认图像宽度"
echo "  DEFAULT_HEIGHT  : 默认图像高度"
echo "  DEFAULT_MODEL   : 默认使用的模型"
echo "  DEFAULT_STYLE   : 默认图像风格"
echo "  SERVER_HOST     : 服务器监听地址"
echo "  SERVER_PORT     : 服务器监听端口"
echo
echo "API密钥获取地址: https://console.volcengine.com/"
echo
read -p "按 Enter 键继续..."

"$EDITOR" "$ENV_FILE"

echo
echo "✅ 配置文件已保存"
echo
echo "📋 当前配置:"
echo "----------------------------------------"
cat "$ENV_FILE" | grep -E '^(GLM_API_KEY|GLM_API_SECRET|DEFAULT_|SERVER_)='
