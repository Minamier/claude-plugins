#!/bin/bash
# GLM Image 技能安装脚本 (Linux/macOS)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$SKILL_DIR/.env"
ENV_EXAMPLE_FILE="$SKILL_DIR/.env.example"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}        GLM Image 技能安装程序        ${NC}"
echo -e "${BLUE}=============================================${NC}"

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到 Python 3，请先安装 Python 3.7 或更高版本${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo -e "${GREEN}✅ Python 版本: $PYTHON_VERSION${NC}"

# 创建配置文件
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE_FILE" ]; then
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        echo -e "${GREEN}✅ 已创建配置文件: $ENV_FILE${NC}"
    else
        echo -e "${RED}❌ 错误: 配置文件模板不存在 $ENV_EXAMPLE_FILE${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}ℹ️  配置文件已存在: $ENV_FILE${NC}"
fi

# 安装依赖
echo -e "${BLUE}📦 正在安装 Python 依赖库...${NC}"

pip3 install python-dotenv flask requests

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 依赖库安装成功${NC}"
else
    echo -e "${RED}❌ 依赖库安装失败，请检查网络连接${NC}"
    exit 1
fi

# 检查API密钥
API_KEY=$(grep -E '^GLM_API_KEY=' "$ENV_FILE" | sed -E 's/GLM_API_KEY=(.*)/\1/' | tr -d '"')
API_SECRET=$(grep -E '^GLM_API_SECRET=' "$ENV_FILE" | sed -E 's/GLM_API_SECRET=(.*)/\1/' | tr -d '"')

if [ -z "$API_KEY" ] || [ "$API_KEY" == "" ] || [ -z "$API_SECRET" ] || [ "$API_SECRET" == "" ]; then
    echo -e "${YELLOW}⚠️  API 密钥未配置${NC}"
    echo -e "${BLUE}请运行 ./edit_config.sh 或 edit_config.bat 配置 API 密钥${NC}"
fi

echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}✅ 安装完成！${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${BLUE}使用说明:${NC}"
echo -e "  🚀 启动服务器: ./start.sh"
echo -e "  📝 配置 API 密钥: ./edit_config.sh"
echo -e "  🧪 测试 API: ./test.sh"
echo -e "  📚 查看文档: cat ../SKILL.md"
echo ""
echo -e "${BLUE}API 文档: https://docs.bigmodel.cn/api-reference/模型-api/图像生成${NC}"
