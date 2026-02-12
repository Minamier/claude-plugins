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
    api_secret = os.getenv("GLM_API_SECRET")

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
            print("WARN   GLM_API_KEY 未配置，请运行配置命令: python glm_image_api.py config set-key YOUR_API_KEY YOUR_API_SECRET")
            return None

    if not api_secret or api_secret.strip() == "":
        if interactive:
            print("WARN   GLM_API_SECRET 未配置！")
            try:
                api_secret = input("请输入您的GLM API Secret: ").strip()
                update_config("GLM_API_SECRET", api_secret)
            except EOFError:
                print("ERROR 无法获取输入，请手动配置API密钥")
                return None
        else:
            print("WARN   GLM_API_SECRET 未配置，请运行配置命令: python glm_image_api.py config set-key YOUR_API_KEY YOUR_API_SECRET")
            return None

    config = {
        "api_key": api_key,
        "api_secret": api_secret,
        "default_width": int(os.getenv("DEFAULT_WIDTH", "1024")),
        "default_height": int(os.getenv("DEFAULT_HEIGHT", "1024")),
        "default_model": os.getenv("DEFAULT_MODEL", "cogview-3"),
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

def get_access_token():
    """获取访问令牌"""
    if config is None:
        load_config()

    url = "https://aip.baidubce.com/oauth/2.0/token"
    params = {
        "grant_type": "client_credentials",
        "client_id": config["api_key"],
        "client_secret": config["api_secret"]
    }

    try:
        response = requests.post(url, params=params, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if "access_token" in result:
                return result["access_token"]
            else:
                print(f"ERROR 无法获取访问令牌: {result}")
                return None
        else:
            print(f"ERROR API 请求失败: 状态码 {response.status_code}")
            return None
    except Exception as e:
        print(f"ERROR  请求异常: {str(e)}")
        return None

def generate_image(prompt, negative_prompt="", width=1024, height=1024,
                  model="cogview-3", style="写实", samples=1):
    """生成图像"""
    if config is None:
        load_config()

    access_token = get_access_token()
    if not access_token:
        return None, "无法获取访问令牌"

    url = f"https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/image2text/text2image?access_token={access_token}"

    payload = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "width": width,
        "height": height,
        "model": model,
        "style": style,
        "samples": samples
    }

    try:
        response = requests.post(url, json=payload, timeout=60)
        if response.status_code == 200:
            result = response.json()

            if "data" in result:
                images = []
                for item in result["data"]:
                    if "b64_image" in item:
                        images.append({
                            "base64": item["b64_image"],
                            "url": None
                        })

                return images, "成功"
            else:
                error_msg = result.get("error_msg", "未知错误")
                return None, error_msg
        else:
            return None, f"API 请求失败: 状态码 {response.status_code}"
    except Exception as e:
        return None, f"请求异常: {str(e)}"

@app.route("/ping", methods=["GET"])
def ping():
    """健康检查接口"""
    return jsonify({"status": "ok", "message": "GLM Image API 服务正常运行"})

@app.route("/txt2img", methods=["POST"])
def txt2img():
    """文本生成图像接口"""
    if config is None:
        load_config()

    try:
        data = request.get_json()
        prompt = data.get("prompt")

        if not prompt:
            return jsonify({"error": "缺少必填参数: prompt"}), 400

        images, status = generate_image(
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
                "count": len(images)
            })
        else:
            return jsonify({"error": status}), 500

    except Exception as e:
        return jsonify({"error": f"请求处理失败: {str(e)}"}), 500

def save_image(b64_image, output_path):
    """保存图像到文件"""
    try:
        image_data = base64.b64decode(b64_image)
        with open(output_path, "wb") as f:
            f.write(image_data)
        return True
    except Exception as e:
        print(f"ERROR  保存图像失败: {str(e)}")
        return False

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
    set_key_parser.add_argument("api_secret", type=str, help="API Secret")

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

        images, status = generate_image(
            prompt=args.prompt,
            negative_prompt=args.negative,
            width=args.width,
            height=args.height,
            model=args.model,
            style=args.style,
            samples=args.samples
        )

        if images:
            output_dir = Path(args.output)
            output_dir.mkdir(exist_ok=True)

            for i, img in enumerate(images):
                output_path = output_dir / f"image_{i+1}.png"
                if save_image(img["base64"], output_path):
                    print(f"OK  已保存: {output_path}")
            print(f"✅ 图像生成完成！共生成 {len(images)} 张图像")
        else:
            print(f"ERROR  图像生成失败: {status}")

    elif args.subcommand == "config":
        if args.config_subcommand == "set-key":
            update_config("GLM_API_KEY", args.api_key)
            update_config("GLM_API_SECRET", args.api_secret)
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
        os.system(f"{sys.executable} -m pip install python-dotenv flask requests")

    main()
