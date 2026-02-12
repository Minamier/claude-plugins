---
name: nano-banana-api
description: 部署和管理 Stable Diffusion API 服务的技能。提供一键式 API 部署、配置管理和图像生成功能，支持本地和远程访问。
---

# Nano Banana API 部署技能

## 概述

本技能提供对 Stable Diffusion API 服务的完整管理功能，包括安装、配置、启动和使用。使用 Python Flask 框架和 Stability-AI SDK，提供简洁的 RESTful API 接口，支持文本到图像的生成功能。

## 部署流程

### 快速部署

#### 1. 依赖安装

```bash
# 检查并安装 Python 依赖库
python - <<END
import sys
import subprocess

# 检查是否安装了 Stability-AI 库
try:
    from stability_sdk import client
    print("Stability-AI SDK 已安装")
except ImportError:
    print("Stability-AI SDK 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "stability-sdk"], check=True)

# 检查是否安装了 Flask（用于创建 API 服务）
try:
    from flask import Flask, request, jsonify
    print("Flask 已安装")
except ImportError:
    print("Flask 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "flask"], check=True)

# 检查是否安装了 Pillow（用于图像处理）
try:
    from PIL import Image
    print("Pillow 已安装")
except ImportError:
    print("Pillow 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "Pillow"], check=True)
END
```

#### 2. 配置文件创建

```bash
# 创建 .env 配置文件
cat > .env <<'EOF'
# Stability-AI API 密钥配置文件
# 请在此处填写您的 Stability-AI API 密钥
# API 密钥可从 https://beta.stability.ai/ 获取

STABILITY_API_KEY=""

# 服务器配置
SERVER_HOST="127.0.0.1"
SERVER_PORT="5000"

# 图像生成配置（默认值）
DEFAULT_WIDTH="1024"
DEFAULT_HEIGHT="1024"
DEFAULT_STEPS="30"
DEFAULT_CFG_SCALE="7.5"

# 模型配置
# 可选值：
# - stable-diffusion-xl-1024-v1-0（SDXL 1024 模型）
# - stable-diffusion-xl-beta-v2-2-2（SDXL Beta 模型）
# - stable-diffusion-512-v2-1（SD 512 模型）
DEFAULT_ENGINE="stable-diffusion-xl-1024-v1-0"
EOF
```

#### 3. 服务器启动

```bash
# 启动 API 服务器
python stable_diffusion_api.py --host 0.0.0.0 --port 5000 --debug --api-key "your_actual_api_key_here"
```

### 后台运行

```bash
# 后台运行服务器（Windows）
start /B python stable_diffusion_api.py --host 0.0.0.0 --port 5000
```

## API 功能

### 健康检查

```bash
curl -X GET http://127.0.0.1:5000/ping
```

**响应：**
```json
{"status": "ok", "message": "API 服务正常运行"}
```

### 文本生成图像

```bash
curl -X POST http://127.0.0.1:5000/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "cartoon horse, cute style, white background",
    "negative_prompt": "ugly, blurry, low quality",
    "width": 512,
    "height": 512,
    "steps": 10,
    "samples": 1
  }'
```

**响应：**
```json
{
  "prompt": "cartoon horse, cute style, white background",
  "images": [
    {"base64": "base64_encoded_image_data"}
  ],
  "count": 1
}
```

## 项目结构

```
nano-banana-api/
├── SKILL.md                 # 技能文档（本文档）
├── stable_diffusion_api.py  # API 服务器主程序
├── .env                     # 配置文件
└── scripts/
    ├── install.sh           # 一键安装脚本
    ├── start.sh             # 启动脚本
    └── test.sh              # 测试脚本
```

## 配置选项

### 服务器配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| --host | 服务器监听地址 | 127.0.0.1 |
| --port | 服务器监听端口 | 5000 |
| --debug | 是否开启调试模式 | False |
| --api-key | Stability-AI API 密钥 | None |

### 图像生成配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| prompt | 正向提示词 | None |
| negative_prompt | 负向提示词 | 空 |
| width | 图像宽度 | 1024 |
| height | 图像高度 | 1024 |
| steps | 采样步数 | 30 |
| cfg_scale | 画面一致性 | 7.5 |
| samples | 生成数量 | 1 |

## 常见问题

### 1. API 密钥未找到

**错误信息：**
```
警告：未找到 Stability-AI API 密钥！
请设置 STABILITY_API_KEY 环境变量，或在代码中直接设置。
API 密钥可从 https://beta.stability.ai/ 获取。
```

**解决方法：**
- 在 .env 文件中设置 STABILITY_API_KEY
- 或者在启动时使用 --api-key 参数
- 访问 https://beta.stability.ai/ 获取 API 密钥

### 2. 服务器无法启动

**错误信息：**
```
OSError: [Errno 48] Address already in use
```

**解决方法：**
- 使用不同的端口号
- 检查端口是否被其他程序占用：`lsof -i :5000`
- 或者关闭占用端口的程序：`kill -9 <PID>`

### 3. 图像生成失败

**错误信息：**
```
UNAUTHENTICATED: Incorrect API key provided
```

**解决方法：**
- 检查 API 密钥是否正确
- 访问 https://beta.stability.ai/ 确认 API 密钥状态

## 高级功能

### 自定义模型

```python
# 在 stable_diffusion_api.py 中修改引擎配置
engine="stable-diffusion-512-v2-1"  # 使用 512x512 模型
```

### 多语言支持

```python
# 支持中文提示词
{"prompt": "卡通风格的马，可爱的造型，白色背景"}
```

### 批量生成

```bash
curl -X POST http://127.0.0.1:5000/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "cartoon horse",
    "width": 512,
    "height": 512,
    "steps": 10,
    "samples": 4
  }'
```

**响应：**
```json
{
  "prompt": "cartoon horse",
  "images": [
    {"base64": "..."},
    {"base64": "..."},
    {"base64": "..."},
    {"base64": "..."}
  ],
  "count": 4
}
```

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

### 硬件加速

- 使用 NVIDIA GPU 加速（需要 CUDA 支持）
- 减少图像分辨率和采样步数
- 调整 CFG 缩放值
- 使用多进程处理

### 资源管理

- 定期清理临时文件
- 监控服务器资源使用情况
- 优化图像处理流程
- 使用缓存机制

## 相关资源

- [Stability AI 官方文档](https://stability.ai/docs/)
- [Flask 框架文档](https://flask.palletsprojects.com/)
- [Python 图像库文档](https://pillow.readthedocs.io/)
- [API 开发最佳实践](https://blog.postman.com/rest-api-best-practices/)

该技能提供了完整的 API 部署和管理功能，适用于开发、测试和生产环境。通过简单的命令和配置，您可以快速搭建自己的图像生成服务。
