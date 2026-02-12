#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from flask import Flask, request, jsonify
from PIL import Image
from io import BytesIO
import base64
import threading

# 检查是否已安装 Stability-AI SDK
try:
    import stability_sdk
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
    print("API 密钥可从 https://beta.stability.ai/ 获取。")

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
    """API 主页"""
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
    """健康检查"""
    return jsonify({"status": "ok", "message": "API 服务正常运行"})


@app.route("/txt2img", methods=["POST"])
def text_to_image():
    """文生图 API"""
    try:
        # 检查 API 密钥是否已配置
        if not STABILITY_API_KEY or not stability_api:
            return jsonify({"error": "未配置 Stability-AI API 密钥，请先在 .env 文件中配置 API 密钥"}), 500

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
            return jsonify({"error": "缺少必要参数：请提供要生成的图像描述（prompt）"}), 400

        # 验证尺寸（必须是 64 的倍数）
        if width % 64 != 0 or height % 64 != 0:
            return jsonify({"error": "图像尺寸不符合要求，宽度和高度必须是 64 的倍数"}), 400

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
                    images.append({"error": "图像内容不符合安全规范，请尝试调整提示词"})
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
        return jsonify({"error": f"生成图像时发生错误：{str(e)}，请稍后重试"}), 500


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

    # 尝试初始化客户端（但不强制要求成功）
    # 注意：不使用 global 声明，因为我们已经在全局作用域中定义了这个变量
    if STABILITY_API_KEY:
        try:
            stability_api = client.StabilityInference(
                key=STABILITY_API_KEY,
                verbose=True,
                engine="stable-diffusion-xl-1024-v1-0",
            )
            print("Stability-AI 客户端初始化成功")
        except Exception as e:
            print(f"初始化 Stability-AI 客户端失败：{e}")
            stability_api = None
    else:
        print("警告：未配置 Stability-AI API 密钥")
        print("API 服务仍会启动，但图像生成功能将无法使用")
        print("请在 .env 文件中配置 STABILITY_API_KEY 或使用 --api-key 参数")
        stability_api = None

    print(f"Stable Diffusion API 服务启动成功！")
    print(f"监听地址：http://{args.host}:{args.port}")
    print(f"主页：http://{args.host}:{args.port}/")
    print(f"API 文档：http://{args.host}:{args.port}/docs")

    # 启动 Flask 应用
    app.run(
        host=args.host,
        port=args.port,
        debug=args.debug,
        threaded=True
    )
