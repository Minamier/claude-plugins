@echo off
chcp 65001 > nul
echo.
echo ============================================
echo      Nano Banana API 一键安装脚本
echo ============================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python 解释器！
    echo 请先安装 Python 3.8 或更高版本
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [信息] Python 版本:
python --version

echo.
echo [信息] 正在检查依赖库...
python - <<END
import sys
import subprocess
import os

# 检查是否安装了 Stability-AI 库
try:
    from stability_sdk import client
    print("✅ Stability-AI SDK 已安装")
except ImportError:
    print("⚠️ Stability-AI SDK 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "stability-sdk"], check=True)

# 检查是否安装了 Flask（用于创建 API 服务）
try:
    from flask import Flask
    print("✅ Flask 已安装")
except ImportError:
    print("⚠️ Flask 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "flask"], check=True)

# 检查是否安装了 Pillow（用于图像处理）
try:
    from PIL import Image
    print("✅ Pillow 已安装")
except ImportError:
    print("⚠️ Pillow 未安装，正在安装...")
    subprocess.run([sys.executable, "-m", "pip", "install", "Pillow"], check=True)

print("✅ 所有依赖库检查完成！")
END

echo.
echo [信息] 正在检查配置文件...
if not exist ".env" (
    echo [警告] .env 配置文件不存在，正在从模板创建...
    if exist "..\.env.example" (
        copy "..\.env.example" ".env" >nul
        echo [成功] 已从 .env.example 创建 .env 配置文件
    ) else (
        echo.
        echo # Stability-AI API 密钥配置文件 > .env
        echo # 请在此处填写您的 Stability-AI API 密钥 >> .env
        echo # API 密钥可从 https://beta.stability.ai/ 获取 >> .env
        echo. >> .env
        echo STABILITY_API_KEY="" >> .env
        echo. >> .env
        echo # 服务器配置 >> .env
        echo SERVER_HOST="127.0.0.1" >> .env
        echo SERVER_PORT="5000" >> .env
        echo. >> .env
        echo # 图像生成配置（默认值） >> .env
        echo DEFAULT_WIDTH="1024" >> .env
        echo DEFAULT_HEIGHT="1024" >> .env
        echo DEFAULT_STEPS="30" >> .env
        echo DEFAULT_CFG_SCALE="7.5" >> .env
        echo. >> .env
        echo # 模型配置 >> .env
        echo # 可选值： >> .env
        echo # - stable-diffusion-xl-1024-v1-0（SDXL 1024 模型） >> .env
        echo # - stable-diffusion-xl-beta-v2-2-2（SDXL Beta 模型） >> .env
        echo # - stable-diffusion-512-v2-1（SD 512 模型） >> .env
        echo DEFAULT_ENGINE="stable-diffusion-xl-1024-v1-0" >> .env

        echo [信息] .env 配置文件创建成功！
    )
)

echo.
echo [信息] 正在检查主程序文件...
if not exist "stable_diffusion_api.py" (
    echo [警告] stable_diffusion_api.py 文件不存在，正在创建...
    python - <<END
with open("stable_diffusion_api.py", "w", encoding="utf-8") as f:
    f.write('''
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from flask import Flask, request, jsonify
from PIL import Image
from io import BytesIO
import base64

# 检查是否已安装 Stability-AI SDK
try:
    from stability_sdk import client
    import stability_sdk.interfaces.gooseai.generation.generation_pb2 as generation
except ImportError:
    print("Stability-AI SDK 未安装，请先运行安装命令：")
    print("pip install stability-sdk")
    sys.exit(1)

# 创建 Flask 应用
app = Flask(__name__)

# 配置 Stability-AI API 密钥（需要从环境变量中获取）
STABILITY_API_KEY = os.getenv("STABILITY_API_KEY")

if not STABILITY_API_KEY:
    print("警告：未找到 Stability-AI API 密钥！")
    print("请设置 STABILITY_API_KEY 环境变量，或在代码中直接设置。")
    print("API 密钥可从 https://platform.stability.ai/获取。")

# 初始化 Stability-AI 客户端
stability_api = None
try:
    if STABILITY_API_KEY:
        stability_api = client.StabilityInference(
            key=STABILITY_API_KEY,
            verbose=True,
            engine="stable-diffusion-xl-1024-v1-0",  # 使用 SDXL 模型
        )
except Exception as e:
    print(f"初始化 Stability-AI 客户端失败：{e}")


@app.route("/")
def index():
    \"\"\"API 主页\"\"\"
    return jsonify({
        "message": "Stable Diffusion API 服务已启动",
        "endpoints": {
            "/txt2img": "文生图 API",
            "/ping": "健康检查"
        },
        "version": "1.0.0"
    })


@app.route("/ping")
def ping():
    \"\"\"健康检查\"\"\"
    return jsonify({"status": "ok", "message": "API 服务正常运行"})


@app.route("/txt2img", methods=["POST"])
def text_to_image():
    \"\"\"文生图 API\"\"\"
    try:
        # 检查 API 密钥是否已配置
        if not STABILITY_API_KEY or not stability_api:
            return jsonify({"error": "API 密钥未配置或无效"}), 500

        # 获取请求参数
        data = request.json
        prompt = data.get("prompt")
        negative_prompt = data.get("negative_prompt", "")
        width = data.get("width", 1024)
        height = data.get("height", 1024)
        steps = data.get("steps", 30)
        cfg_scale = data.get("cfg_scale", 7.5)
        samples = data.get("samples", 1)

        if not prompt:
            return jsonify({"error": "缺少必要参数：prompt"}), 400

        # 验证尺寸（必须是 64 的倍数）
        if width % 64 != 0 or height % 64 != 0:
            return jsonify({"error": "尺寸必须是 64 的倍数"}), 400

        # 直接使用字符串列表而不是复杂的 Prompt 对象
        if negative_prompt:
            prompts = [
                prompt,
                f"--neg {negative_prompt}"
            ]
        else:
            prompts = [prompt]

        # 生成图像
        answers = stability_api.generate(
            prompt=prompts,
            width=width,
            height=height,
            steps=steps,
            cfg_scale=cfg_scale,
            samples=samples,
            sampler=generation.SAMPLER_K_DPM_2_ANCESTRAL,
        )

        # 处理生成结果
        images = []
        for resp in answers:
            for artifact in resp.artifacts:
                if artifact.finish_reason == generation.FILTER:
                    images.append({"error": "图像内容不符合安全规范"})
                elif artifact.type == generation.ARTIFACT_IMAGE:
                    img = Image.open(BytesIO(artifact.binary))
                    # 将图像转换为 base64 字符串
                    buffered = BytesIO()
                    img.save(buffered, format="PNG")
                    img_str = base64.b64encode(buffered.getvalue()).decode()
                    images.append({"base64": img_str})

        # 返回结果
        return jsonify({
            "prompt": prompt,
            "images": images,
            "count": len(images)
        })

    except Exception as e:
        print(f"生成图像时出错：{e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Stable Diffusion API 服务"
    )
    parser.add_argument(
        "--host",
        type=str,
        default="127.0.0.1",
        help="监听地址（默认：127.0.0.1）"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=5000,
        help="监听端口（默认：5000）"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="启用调试模式"
    )
    parser.add_argument(
        "--api-key",
        type=str,
        help="Stability-AI API 密钥"
    )

    args = parser.parse_args()

    # 设置 API 密钥
    if args.api_key:
        STABILITY_API_KEY = args.api_key

    # 再次尝试初始化客户端（如果之前失败）
    if not STABILITY_API_KEY:
        print("错误：未找到 Stability-AI API 密钥！")
        print("请使用 --api-key 参数或设置 STABILITY_API_KEY 环境变量。")
        sys.exit(1)

    try:
        stability_api = client.StabilityInference(
            key=STABILITY_API_KEY,
            verbose=True,
            engine="stable-diffusion-xl-1024-v1-0",
        )
    except Exception as e:
        print(f"初始化 Stability-AI 客户端失败：{e}")
        sys.exit(1)

    print(f"Stable Diffusion API 服务启动成功！")
    print(f"监听地址：http://{args.host}:{args.port}")
    print(f"主页：http://{args.host}:{args.port}/")

    # 启动 Flask 应用
    app.run(
        host=args.host,
        port=args.port,
        debug=args.debug,
        threaded=True
    )
''')
    print("✅ stable_diffusion_api.py 文件创建成功！")
END
)

echo.
echo ============================================
echo      Nano Banana API 安装成功！
echo ============================================
echo.
echo 下一步操作：
echo 1. 编辑配置文件：edit_config.bat
echo 2. 启动 API 服务器：start.bat
echo 3. 测试 API 功能：test.bat
echo.
echo API 密钥获取地址：https://platform.stability.ai/
echo.
echo 服务器启动后，可以通过以下地址访问：
echo  - 健康检查：http://127.0.0.1:5000/ping
echo  - 主页：http://127.0.0.1:5000/
echo  - 文生图 API：http://127.0.0.1:5000/txt2img
echo.
pause
