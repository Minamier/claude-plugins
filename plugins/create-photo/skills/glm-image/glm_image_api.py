#!/usr/bin/env python3
"""
GLM Image API 服务器
使用字节跳动GLM模型提供图像生成功能
"""

import os
import sys
import json
import base64
import argparse
import requests
from dotenv import load_dotenv
from flask import Flask, request, jsonify
from pathlib import Path

app = Flask(__name__)

# 配置文件路径
ENV_FILE = Path(__file__).parent / ".env"
ENV_EXAMPLE_FILE = Path(__file__).parent / ".env.example"

# 配置变量（模块级别）
config = None

# 加载配置
def load_config(interactive=True):
    """加载配置文件"""
    global config

    if not ENV_FILE.exists():
        if ENV_EXAMPLE_FILE.exists():
            with open(ENV_EXAMPLE_FILE, "r", encoding="utf-8") as f:
                config_content = f.read()
            with open(ENV_FILE, "w", encoding="utf-8") as f:
                f.write(config_content)
            print("OK 已创建配置文件: .env (从 .env.example 复制)")
        else:
            print("ERROR 配置文件模板不存在: .env.example")
            sys.exit(1)

    load_dotenv(ENV_FILE)

    # 检查API密钥
    api_key = os.getenv("GLM_API_KEY")

    if not api_key or api_key.strip() == "":
        if interactive:
            print("WARN   GLM_API_KEY 未配置！")
            try:
                api_key = input("请输入您的GLM API Key: ").strip()
                update_config("GLM_API_KEY", api_key)
            except EOFError:
                print("ERROR 无法获取输入，请手动配置API密钥")
                return None
        else:
            print("WARN   GLM_API_KEY 未配置，请运行配置命令: python glm_image_api.py config set-key YOUR_API_KEY")
            return None

    config = {
        "api_key": api_key,
        "default_width": int(os.getenv("DEFAULT_WIDTH", "1024")),
        "default_height": int(os.getenv("DEFAULT_HEIGHT", "1024")),
        "default_model": os.getenv("DEFAULT_MODEL", "glm-image"),
        "default_style": os.getenv("DEFAULT_STYLE", "写实"),
        "server_host": os.getenv("SERVER_HOST", "127.0.0.1"),
        "server_port": int(os.getenv("SERVER_PORT", "5001"))
    }

    return config

def update_config(key, value):
    """更新配置文件"""
    if not ENV_FILE.exists():
        load_config(interactive=False)

    with open(ENV_FILE, "r", encoding="utf-8") as f:
        lines = f.readlines()

    updated = False
    for i, line in enumerate(lines):
        if line.strip().startswith(f"{key}="):
            lines[i] = f"{key}=\"{value}\"\n"
            updated = True

    if not updated:
        lines.append(f"{key}=\"{value}\"\n")

    with open(ENV_FILE, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"OK 配置 {key} 已更新")

def generate_image(prompt, negative_prompt="", width=1024, height=1024,
                  model="glm-image", style="写实", samples=1):
    """生成图像

    Args:
        prompt: 图像描述
        negative_prompt: 负向提示词（可选）
        width: 图像宽度（默认：1024，最大：4096）
        height: 图像高度（默认：1024，最大：4096）
        model: 使用的模型（默认：glm-image）
        style: 图像风格（默认：写实）
        samples: 生成数量（默认：1）

    Returns:
        (list, str, str): 图像数据列表，状态信息，照片ID
    """
    """生成图像"""
    if config is None:
        load_config()

    url = "https://open.bigmodel.cn/api/paas/v4/images/generations"

    # 构建请求头
    headers = {
        "Authorization": f"Bearer {config['api_key']}",
        "Content-Type": "application/json"
    }

    # 构建请求数据
    payload = {
        "model": model,
        "prompt": prompt,
        "size": f"{width}x{height}",
        "watermark_enabled": False,
        "quality": "hd"
    }

    # 可选参数
    if negative_prompt:
        payload["negative_prompt"] = negative_prompt
    if samples > 1:
        payload["n"] = samples

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=240)
        if response.status_code == 200:
            result = response.json()

            if "data" in result:
                images = []
                for item in result["data"]:
                    if "url" in item:
                        images.append({
                            "base64": None,
                            "url": item["url"]
                        })
                    elif "b64_image" in item:
                        images.append({
                            "base64": item["b64_image"],
                            "url": None
                        })

                # 保存照片id
                photo_id = result.get("id", "")
                return images, "成功", photo_id
            else:
                error_msg = result.get("error_msg", "未知错误")
                return None, error_msg, None
        else:
            return None, f"API 请求失败: 状态码 {response.status_code} - {response.text}", None
    except Exception as e:
        return None, f"请求异常: {str(e)}", None

@app.route("/ping", methods=["GET"])
def ping():
    """健康检查接口"""
    return jsonify({"status": "ok", "message": "GLM Image API 服务正常运行"})

@app.route("/txt2img", methods=["POST"])
def txt2img():
    """文生图 API"""
    if config is None:
        load_config()

    try:
        data = request.get_json()
        prompt = data.get("prompt")

        if not prompt:
            return jsonify({"error": "缺少必填参数: prompt"}), 400

        images, status, photo_id = generate_image(
            prompt=prompt,
            negative_prompt=data.get("negative_prompt", ""),
            width=data.get("width", config["default_width"]),
            height=data.get("height", config["default_height"]),
            model=data.get("model", config["default_model"]),
            style=data.get("style", config["default_style"]),
            samples=data.get("samples", 1)
        )

        if images:
            return jsonify({
                "prompt": prompt,
                "images": images,
                "count": len(images),
                "photo_id": photo_id
            })
        else:
            return jsonify({"error": status}), 500

    except Exception as e:
        return jsonify({"error": f"请求处理失败: {str(e)}"}), 500

def main():
    """主函数"""
    # 先加载配置
    if load_config() is None:
        print("配置失败，程序退出")
        return 1

    parser = argparse.ArgumentParser(
        description="GLM Image API - 使用字节跳动GLM模型生成图像"
    )

    subparsers = parser.add_subparsers(title="子命令", dest="subcommand")

    # 服务器模式
    server_parser = subparsers.add_parser("server", help="启动API服务器")
    server_parser.add_argument("--host", type=str, default=config["server_host"],
                           help=f"服务器监听地址 (默认: {config['server_host']})")
    server_parser.add_argument("--port", type=int, default=config["server_port"],
                           help=f"服务器监听端口 (默认: {config['server_port']})")
    server_parser.add_argument("--debug", action="store_true",
                           help="开启调试模式")

    # 直接生成模式
    generate_parser = subparsers.add_parser("generate", help="直接生成图像")
    generate_parser.add_argument("prompt", type=str, help="图像描述")
    generate_parser.add_argument("--negative", type=str, default="",
                           help="负向提示词")
    generate_parser.add_argument("--width", type=int, default=config["default_width"],
                           help=f"图像宽度 (默认: {config['default_width']})")
    generate_parser.add_argument("--height", type=int, default=config["default_height"],
                           help=f"图像高度 (默认: {config['default_height']})")
    generate_parser.add_argument("--model", type=str, default=config["default_model"],
                           help=f"使用模型 (默认: {config['default_model']})")
    generate_parser.add_argument("--style", type=str, default=config["default_style"],
                           help=f"图像风格 (默认: {config['default_style']})")
    generate_parser.add_argument("--samples", type=int, default=1,
                           help="生成数量 (默认: 1)")
    generate_parser.add_argument("--output", type=str, default="output",
                           help="输出目录 (默认: output)")

    # 配置管理
    config_parser = subparsers.add_parser("config", help="配置管理")
    config_subparsers = config_parser.add_subparsers(title="配置子命令",
                                                  dest="config_subcommand")

    # 设置API密钥
    set_key_parser = config_subparsers.add_parser("set-key", help="设置API密钥")
    set_key_parser.add_argument("api_key", type=str, help="API Key")

    # 查看配置
    view_parser = config_subparsers.add_parser("view", help="查看当前配置")

    args = parser.parse_args()

    if args.subcommand == "server":
        print(f"🚀 启动 GLM Image API 服务器")
        print(f"📡 服务器地址: http://{args.host}:{args.port}")
        print(f"🔧 调试模式: {args.debug}")

        app.run(host=args.host, port=args.port, debug=args.debug)

    elif args.subcommand == "generate":
        print(f"🎨 正在生成图像...")
        print(f"📝 提示词: {args.prompt}")
        print(f"🎯 风格: {args.style}")
        print(f"📏 尺寸: {args.width}x{args.height}")

        images, status, photo_id = generate_image(
            prompt=args.prompt,
            negative_prompt=args.negative,
            width=args.width,
            height=args.height,
            model=args.model,
            style=args.style,
            samples=args.samples
        )

        if images:
            # 导入save_png_from_url模块
            import save_png_from_url

            # 根据提示词提取关键词（AI判断）
            keywords = extract_keywords(args.prompt)

            # 保存图像
            output_dir = Path(args.output)
            output_dir.mkdir(exist_ok=True)

            for i, img in enumerate(images):
                saved_path = save_png_from_url.save_image_from_dict(img, photo_id, keywords, str(output_dir))

            print(f"✅ 图像生成完成！共生成 {len(images)} 张图像")
        else:
            print(f"ERROR  图像生成失败: {status}")

    elif args.subcommand == "config":
        if args.config_subcommand == "set-key":
            update_config("GLM_API_KEY", args.api_key)
            print("✅ API密钥已更新")

        elif args.config_subcommand == "view":
            print("📋 当前配置:")
            with open(ENV_FILE, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        print(line)

        else:
            config_parser.print_help()

    else:
        parser.print_help()

def extract_keywords(prompt):
    """
    提取关键词（不超过5个字）

    Args:
        prompt: 用户输入的提示词

    Returns:
        str: 提取的关键词（不超过5个字）
    """
    # AI智能提取关键词
    import re

    # 常见核心词汇优先匹配列表
    priority_keywords = ["福字", "春联", "灯笼", "鞭炮", "年夜饭", "压岁钱", "春晚"]

    # 去除标点符号和空格
    cleaned_prompt = re.sub(r'[^\u4e00-\u9fff]', '', prompt)

    # 优先匹配常见核心词汇
    for kw in priority_keywords:
        if kw in cleaned_prompt:
            return kw[:5]

    # 如果没有匹配到常见核心词汇，使用默认方法提取
    if cleaned_prompt:
        return cleaned_prompt[:5]

    return "图像"

if __name__ == "__main__":
    # 设置控制台编码为UTF-8
    import sys
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

    # 检查依赖
    try:
        import dotenv
        from flask import Flask
    except ImportError:
        print("WARN   缺少依赖库，正在安装...")
        os.system(f"{sys.executable} -m pip install python-dotenv flask requests pillow")

    main()
