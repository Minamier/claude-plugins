---
name: glm-image
description: 使用GLM模型根据用户描述生成符合要求的图片的技能。提供API密钥管理、参数配置和图像生成功能。
---

# GLM Image 图像生成技能

## 概述

本技能提供对字节跳动GLM模型图像生成API的完整管理功能，包括API密钥配置、参数设置和图像生成功能。支持根据用户描述生成高质量图片，提供直观的配置和使用体验。

## API 文档参考

本技能基于字节跳动火山引擎的GLM图像生成API，详细文档请参考：
[GLM图像生成API文档](https://docs.bigmodel.cn/api-reference/模型-api/图像生成)

## 快速开始

### 1. 一键安装

```bash
# Linux / macOS
cd plugins/glm-image/skills/glm-image/scripts
chmod +x install.sh edit_config.sh start.sh test.sh
./install.sh

# Windows
cd plugins\glm-image\skills\glm-image\scripts
install.bat
```

### 2. API密钥配置

#### 首次使用配置

```bash
# Linux / macOS
./edit_config.sh

# Windows
edit_config.bat
```

#### 配置文件内容

```env
# GLM Image API 配置文件
# 请在此处填写您的火山引擎API密钥
# 访问 https://console.volcengine.com/ 获取 API 密钥

GLM_API_KEY=""
GLM_API_SECRET=""

# 图像生成配置（默认值）
DEFAULT_WIDTH="1024"
DEFAULT_HEIGHT="1024"
DEFAULT_MODEL="cogview-3"
DEFAULT_STYLE="写实"

# 服务器配置
SERVER_HOST="127.0.0.1"
SERVER_PORT="5001"
```

## API 功能

### 健康检查

```bash
curl -X GET http://127.0.0.1:5001/ping
```

**响应：**
```json
{"status": "ok", "message": "GLM Image API 服务正常运行"}
```

### 文本生成图像

```bash
curl -X POST http://127.0.0.1:5001/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "一只可爱的卡通猫，白色背景",
    "negative_prompt": "模糊，低质量，丑陋",
    "width": 1024,
    "height": 1024,
    "model": "cogview-3",
    "style": "卡通"
  }'
```

**响应：**
```json
{
  "prompt": "一只可爱的卡通猫，白色背景",
  "images": [
    {"base64": "base64_encoded_image_data"}
  ],
  "count": 1
}
```

## 项目结构

```
glm-image/
├── SKILL.md                 # 技能文档（本文档）
├── .env.example             # 配置文件模板
├── glm_image_api.py         # API 服务器主程序
├── .env                     # 配置文件（运行时创建）
└── scripts/
    ├── install.sh           # 一键安装脚本（Linux/macOS）
    ├── install.bat          # 一键安装脚本（Windows）
    ├── start.sh             # 启动脚本（Linux/macOS）
    ├── start.bat            # 启动脚本（Windows）
    ├── edit_config.sh       # 配置编辑器（Linux/macOS）
    ├── edit_config.bat      # 配置编辑器（Windows）
    ├── test.sh              # 测试脚本（Linux/macOS）
    ├── test.bat             # 测试脚本（Windows）
    └── api_test.py          # API 测试程序
```

## 配置选项

### API 配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| GLM_API_KEY | 火山引擎API密钥 | None |
| GLM_API_SECRET | 火山引擎API密钥密码 | None |

### 图像生成配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| prompt | 正向提示词 | None |
| negative_prompt | 负向提示词 | 空 |
| width | 图像宽度 | 1024 |
| height | 图像高度 | 1024 |
| model | 使用模型 | cogview-3 |
| style | 图像风格 | 写实 |
| samples | 生成数量 | 1 |

## 使用方法

### 命令行接口

#### 直接生成图像

```bash
python glm_image_api.py --generate "一只可爱的卡通猫" --style "卡通" --width 1024 --height 1024
```

#### 启动服务器

```bash
python glm_image_api.py --server --host 0.0.0.0 --port 5001
```

### 服务器模式

启动服务器后，可以通过 HTTP API 进行访问：

```bash
# 健康检查
curl http://127.0.0.1:5001/ping

# 生成图像
curl -X POST http://127.0.0.1:5001/txt2img -H "Content-Type: application/json" -d '{
  "prompt": "一只可爱的卡通猫",
  "style": "卡通",
  "width": 1024,
  "height": 1024
}'
```

## 常见问题

### 1. API 密钥未配置

**错误信息：**
```
错误：GLM_API_KEY 未配置！
请先运行配置编辑器：./edit_config.sh（Linux/macOS）或 edit_config.bat（Windows）
API 密钥可从 https://console.volcengine.com/ 获取
```

**解决方法：**
- 运行 `./edit_config.sh`（Linux/macOS）或 `edit_config.bat`（Windows）打开配置文件
- 在 `.env` 文件中设置 `GLM_API_KEY` 和 `GLM_API_SECRET` 配置项
- 访问 https://console.volcengine.com/ 获取 API 密钥

### 2. 服务器无法启动

**错误信息：**
```
OSError: [Errno 48] Address already in use
```

**解决方法：**
- 使用不同的端口号：`--port 5002`
- 检查端口是否被其他程序占用
- 或者关闭占用端口的程序

### 3. 图像生成失败

**错误信息：**
```
Unauthorized: Incorrect API key provided
```

**解决方法：**
- 检查 API 密钥是否正确
- 确认 API 密钥是否已过期
- 访问 https://console.volcengine.com/ 确认 API 密钥状态

## 安全考虑

### API 密钥保护

- 不要将 API 密钥硬编码在代码中
- 使用环境变量或配置文件存储敏感信息
- 定期轮换 API 密钥
- 限制 API 访问范围

### 服务器安全

- 使用 HTTPS 协议（生产环境）
- 配置访问控制和身份验证
- 限制 API 请求频率
- 定期更新依赖库

## 性能优化

### 图像参数优化

- 根据需求调整图像分辨率
- 合理设置生成步数
- 选择合适的模型
- 优化提示词质量

### 资源管理

- 定期清理临时文件
- 监控服务器资源使用情况
- 优化图像处理流程
- 使用缓存机制

## 高级功能

### 批量生成

```bash
curl -X POST http://127.0.0.1:5001/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "卡通风格的动物",
    "width": 512,
    "height": 512,
    "samples": 4
  }'
```

### 自定义模型

```python
# 在 glm_image_api.py 中修改默认模型
DEFAULT_MODEL = "cogview-3"
```

### 多语言支持

```python
# 支持中文提示词
{"prompt": "卡通风格的马，可爱的造型，白色背景"}
```

## 相关资源

- [GLM图像生成API文档](https://docs.bigmodel.cn/api-reference/模型-api/图像生成)
- [火山引擎控制台](https://console.volcengine.com/)
- [Python 官方文档](https://docs.python.org/)
- [Flask 框架文档](https://flask.palletsprojects.com/)

该技能提供了完整的 GLM 图像生成 API 管理功能，适用于开发、测试和生产环境。通过简单的命令和配置，您可以快速搭建自己的图像生成服务。
