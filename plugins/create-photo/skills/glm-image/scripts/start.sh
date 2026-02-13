#!/bin/bash
# GLM Image API 启动脚本 (Linux/macOS)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SKILL_DIR/.env"
API_SCRIPT="$SKILL_DIR/glm_image_api.py"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}        GLM Image API 服务器启动        ${NC}"
echo -e "${BLUE}=============================================${NC}"

# 检查API脚本是否存在
if [ ! -f "$API_SCRIPT" ]; then
    echo -e "${RED}❌ 错误: API 脚本不存在: $API_SCRIPT${NC}"
    exit 1
fi

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

# 检查API密钥
API_KEY=$(grep -E '^GLM_API_KEY=' "$ENV_FILE" | sed -E 's/GLM_API_KEY=(.*)/\1/' | tr -d '"')
API_SECRET=$(grep -E '^GLM_API_SECRET=' "$ENV_FILE" | sed -E 's/GLM_API_SECRET=(.*)/\1/' | tr -d '"')

if [ -z "$API_KEY" ] || [ "$API_KEY" == "" ]; then
    echo -e "${YELLOW}⚠️  GLM_API_KEY 未配置${NC}"
    read -p "请输入您的GLM API Key: " API_KEY
    sed -i.bak "s/^GLM_API_KEY=.*/GLM_API_KEY=\"$API_KEY\"/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
    echo -e "${GREEN}✅ GLM_API_KEY 已更新${NC}"
fi

if [ -z "$API_SECRET" ] || [ "$API_SECRET" == "" ]; then
    echo -e "${YELLOW}⚠️  GLM_API_SECRET 未配置${NC}"
    read -p "请输入您的GLM API Secret: " API_SECRET
    sed -i.bak "s/^GLM_API_SECRET=.*/GLM_API_SECRET=\"$API_SECRET\"/" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
    echo -e "${GREEN}✅ GLM_API_SECRET 已更新${NC}"
fi

# 读取配置
SERVER_HOST=$(grep -E '^SERVER_HOST=' "$ENV_FILE" | sed -E 's/SERVER_HOST=(.*)/\1/' | tr -d '"')
SERVER_PORT=$(grep -E '^SERVER_PORT=' "$ENV_FILE" | sed -E 's/SERVER_PORT=(.*)/\1/' | tr -d '"')

SERVER_HOST=${SERVER_HOST:-"127.0.0.1"}
SERVER_PORT=${SERVER_PORT:-"5001"}

echo -e "${BLUE}📋 服务器配置:${NC}"
echo -e "   地址: $SERVER_HOST"
echo -e "   端口: $SERVER_PORT"
echo ""
echo -e "${BLUE}🚀 正在启动 GLM Image API 服务器...${NC}"
echo -e "${BLUE}📖 按 Ctrl+C 停止服务器${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# 启动服务器
python3 "$API_SCRIPT" server --host "$SERVER_HOST" --port "$SERVER_PORT"
