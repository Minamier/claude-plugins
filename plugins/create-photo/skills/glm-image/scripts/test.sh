#!/bin/bash
# GLM Image API 测试脚本 (Linux/macOS)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SKILL_DIR/.env"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}        GLM Image API 测试程序        ${NC}"
echo -e "${BLUE}=============================================${NC}"

# 检查配置文件
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}ℹ️  配置文件不存在，正在创建...${NC}"
    if [ -f "$SKILL_DIR/.env.example" ]; then
        cp "$SKILL_DIR/.env.example" "$ENV_FILE"
    else
        echo -e "${RED}❌ 错误: 配置文件模板不存在${NC}"
        exit 1
    fi
fi

# 读取配置
SERVER_HOST=$(grep -E '^SERVER_HOST=' "$ENV_FILE" | sed -E 's/SERVER_HOST=(.*)/\1/' | tr -d '"')
SERVER_PORT=$(grep -E '^SERVER_PORT=' "$ENV_FILE" | sed -E 's/SERVER_PORT=(.*)/\1/' | tr -d '"')

SERVER_HOST=${SERVER_HOST:-"127.0.0.1"}
SERVER_PORT=${SERVER_PORT:-"5001"}

API_URL="http://${SERVER_HOST}:${SERVER_PORT}"

echo -e "${BLUE}📋 API 配置:${NC}"
echo -e "   地址: $API_URL"
echo ""

# 检查服务器是否正在运行
echo -e "${BLUE}🔍 检查服务器状态...${NC}"
if curl -s "$API_URL/ping" > /dev/null; then
    echo -e "${GREEN}✅ 服务器正在运行${NC}"
else
    echo -e "${YELLOW}⚠️  服务器未运行，正在启动...${NC}"
    echo -e "${BLUE}启动服务器将在新窗口中运行...${NC}"
    if command -v x-terminal-emulator &> /dev/null; then
        x-terminal-emulator -e "bash $SCRIPT_DIR/start.sh" &
    elif command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "cd $SCRIPT_DIR && ./start.sh; exec bash" &
    elif command -v konsole &> /dev/null; then
        konsole -e "bash $SCRIPT_DIR/start.sh" &
    else
        echo -e "${RED}❌ 无法自动启动服务器，请手动运行: ./start.sh${NC}"
        echo ""
        read -p "按 Enter 键继续测试..."
    fi

    echo -e "${BLUE}⏳ 等待服务器启动 (10秒)...${NC}"
    sleep 10

    if curl -s "$API_URL/ping" > /dev/null; then
        echo -e "${GREEN}✅ 服务器已启动${NC}"
    else
        echo -e "${RED}❌ 服务器启动失败${NC}"
        echo ""
        echo -e "${BLUE}请手动启动服务器并重新运行测试:${NC}"
        echo "   cd $SCRIPT_DIR"
        echo "   ./start.sh"
        exit 1
    fi
fi

echo ""

# 运行API测试
echo -e "${BLUE}🧪 正在运行 API 测试...${NC}"
python3 "$SCRIPT_DIR/api_test.py" --url "$API_URL"
