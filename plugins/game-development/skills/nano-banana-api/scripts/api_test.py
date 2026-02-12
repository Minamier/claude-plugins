#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nano Banana API 测试脚本
提供简单的命令行接口来测试 API 功能
"""

import argparse
import requests
import json
import base64
from io import BytesIO
from PIL import Image
import os


def print_response(response):
    """格式化输出响应"""
    try:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except:
        print(response.text)


def test_health_check(api_url):
    """测试健康检查"""
    print("\033[92m=== 健康检查 ===\033[0m")
    try:
        response = requests.get(f"{api_url}/ping")
        if response.status_code == 200:
            data = response.json()
            if data.get("status") == "ok":
                print("\033[92m✅ 健康检查通过\033[0m")
                print_response(response)
            else:
                print("\033[91m❌ 健康检查响应异常\033[0m")
                print_response(response)
        else:
            print(f"\033[91m❌ 健康检查失败，状态码: {response.status_code}\033[0m")
            print_response(response)
    except requests.exceptions.ConnectionError:
        print("\033[91m❌ 无法连接到服务器，请检查服务器是否已启动\033[0m")
    except Exception as e:
        print(f"\033[91m❌ 健康检查异常: {e}\033[0m")
    print()


def test_root_path(api_url):
    """测试根路径"""
    print("\033[92m=== 根路径测试 ===\033[0m")
    try:
        response = requests.get(f"{api_url}/")
        if response.status_code == 200:
            print("\033[92m✅ 根路径测试通过\033[0m")
            print_response(response)
        else:
            print(f"\033[91m❌ 根路径访问失败，状态码: {response.status_code}\033[0m")
            print_response(response)
    except Exception as e:
        print(f"\033[91m❌ 根路径测试异常: {e}\033[0m")
    print()


def test_text_to_image(api_url, prompt, output_dir="output"):
    """测试文本到图像"""
    print("\033[92m=== 文生图测试 ===\033[0m")
    print(f"使用提示词: \033[94m{prompt}\033[0m")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    payload = {
        "prompt": prompt,
        "negative_prompt": "ugly, blurry, low quality",
        "width": 512,
        "height": 512,
        "steps": 10,
        "samples": 1
    }

    try:
        response = requests.post(
            f"{api_url}/txt2img",
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=30
        )

        if response.status_code == 200:
            data = response.json()

            if "images" in data and data["images"]:
                # 保存图片
                for idx, img_info in enumerate(data["images"]):
                    if "base64" in img_info:
                        try:
                            # 解码并保存图片
                            img_data = base64.b64decode(img_info["base64"])
                            img = Image.open(BytesIO(img_data))
                            filename = f"image_{idx}.png"
                            filepath = os.path.join(output_dir, filename)
                            img.save(filepath)
                            print(f"\033[92m✅ 图片已保存: {filepath}\033[0m")
                        except Exception as e:
                            print(f"\033[91m❌ 保存图片失败: {e}\033[0m")
                    elif "error" in img_info:
                        print(f"\033[91m❌ 图片生成失败: {img_info['error']}\033[0m")
            else:
                print("\033[91m❌ 响应中没有图片数据\033[0m")

            print_response(response)
        else:
            print(f"\033[91m❌ 文生图请求失败，状态码: {response.status_code}\033[0m")
            print_response(response)
    except requests.exceptions.Timeout:
        print("\033[91m❌ 请求超时，服务器响应时间过长\033[0m")
    except requests.exceptions.ConnectionError:
        print("\033[91m❌ 无法连接到服务器，请检查服务器是否已启动\033[0m")
    except Exception as e:
        print(f"\033[91m❌ 文生图测试异常: {e}\033[0m")
        import traceback
        traceback.print_exc()
    print()


def load_config():
    """加载配置"""
    config = {}
    if os.path.exists(".env"):
        with open(".env", "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith("#")]

        for line in lines:
            if "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key == "SERVER_HOST":
                    config["host"] = value
                elif key == "SERVER_PORT":
                    config["port"] = int(value) if value.isdigit() else 5000

    return config


def main():
    # 加载配置
    config = load_config()

    parser = argparse.ArgumentParser(
        description="Nano Banana API 测试脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python api_test.py                     # 运行完整测试
  python api_test.py --health            # 只测试健康检查
  python api_test.py --txt2img           # 只测试文生图
  python api_test.py --txt2img --prompt "cartoon horse"  # 自定义提示词
        """.strip()
    )

    parser.add_argument(
        "--host",
        type=str,
        default=config.get("host", "127.0.0.1"),
        help=f"API 服务器地址 (默认: {config.get('host', '127.0.0.1')})"
    )

    parser.add_argument(
        "--port",
        type=int,
        default=config.get("port", 5000),
        help=f"API 服务器端口 (默认: {config.get('port', 5000)})"
    )

    parser.add_argument(
        "--health",
        action="store_true",
        help="只测试健康检查"
    )

    parser.add_argument(
        "--txt2img",
        action="store_true",
        help="只测试文生图"
    )

    parser.add_argument(
        "--prompt",
        type=str,
        default="cartoon horse, cute style, white background",
        help="文生图使用的提示词"
    )

    parser.add_argument(
        "--output",
        type=str,
        default="output",
        help="图片输出目录"
    )

    parser.add_argument(
        "--full",
        action="store_true",
        help="运行完整测试 (默认行为)"
    )

    args = parser.parse_args()

    # 构建 API URL
    api_url = f"http://{args.host}:{args.port}"

    # 确定要运行的测试
    if args.health:
        test_health_check(api_url)
    elif args.txt2img:
        test_text_to_image(api_url, args.prompt, args.output)
    else:
        # 默认运行完整测试
        test_health_check(api_url)
        test_root_path(api_url)
        test_text_to_image(api_url, args.prompt, args.output)

    print("\033[92m=== 测试完成 ===\033[0m")


if __name__ == "__main__":
    main()
