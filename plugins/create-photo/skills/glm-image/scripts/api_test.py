#!/usr/bin/env python3
"""
GLM Image API 测试脚本
"""

import sys
import argparse
import requests
import json
from pathlib import Path

def test_api(api_url):
    """测试API功能"""
    print("=" * 60)
    print("        GLM Image API 测试程序        ")
    print("=" * 60)
    print()

    # 健康检查
    print("🔍 测试健康检查接口...")
    try:
        response = requests.get(f"{api_url}/ping", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 成功: {data['message']}")
        else:
            print(f"❌ 失败: 状态码 {response.status_code}")
            print(f"   响应: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 错误: {str(e)}")
        return False

    print()

    # 测试图像生成
    print("🎨 测试图像生成接口...")
    test_data = {
        "prompt": "一只可爱的卡通猫，白色背景",
        "negative_prompt": "模糊，低质量，丑陋",
        "width": 1024,
        "height": 1024,
        "style": "卡通",
        "samples": 1
    }

    try:
        response = requests.post(f"{api_url}/txt2img", json=test_data, timeout=60)
        if response.status_code == 200:
            data = response.json()
            if "images" in data:
                print(f"✅ 成功: 生成 {len(data['images'])} 张图像")
                # 保存第一张图像到输出目录
                output_dir = Path(__file__).parent / "output"
                output_dir.mkdir(exist_ok=True)

                if data['images']:
                    first_image = data['images'][0]
                    if "base64" in first_image:
                        import base64
                        image_path = output_dir / "test_image.png"
                        with open(image_path, "wb") as f:
                            f.write(base64.b64decode(first_image["base64"]))
                        print(f"📸 图像已保存到: {image_path}")
            else:
                print(f"❌ 失败: 响应中无图像数据")
                print(f"   响应: {json.dumps(data, ensure_ascii=False, indent=2)}")
        else:
            print(f"❌ 失败: 状态码 {response.status_code}")
            print(f"   响应: {response.text}")
            return False

    except Exception as e:
        print(f"❌ 错误: {str(e)}")
        return False

    print()

    # 测试生成指定数量的图像
    print("📊 测试批量生成图像...")
    test_data = {
        "prompt": "美丽的风景，高山流水",
        "width": 512,
        "height": 512,
        "style": "写实",
        "samples": 2
    }

    try:
        response = requests.post(f"{api_url}/txt2img", json=test_data, timeout=60)
        if response.status_code == 200:
            data = response.json()
            if "images" in data:
                print(f"✅ 成功: 生成 {len(data['images'])} 张图像")
            else:
                print(f"❌ 失败: 响应中无图像数据")
                return False
    except Exception as e:
        print(f"❌ 错误: {str(e)}")
        return False

    print()
    print("=" * 60)
    print("✅ 所有测试完成！API 服务正常")
    print("=" * 60)

    return True

def main():
    parser = argparse.ArgumentParser(
        description="GLM Image API 测试脚本"
    )
    parser.add_argument("--url", type=str, default="http://127.0.0.1:5001",
                       help="API地址 (默认: http://127.0.0.1:5001)")

    args = parser.parse_args()

    api_url = args.url.strip("/")

    # 测试API
    success = test_api(api_url)

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
