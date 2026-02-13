#!/usr/bin/env python3
"""测试GLM图像生成API的Python脚本"""

import requests
import json

def test_glm_image_api():
    """测试GLM图像生成API"""
    api_key = "3becfafe5a65490486c6e357498938cd.EUb1RRbv5k0Il7mQ"
    url = "https://open.bigmodel.cn/api/paas/v4/images/generations"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "glm-image",
        "prompt": "马年迎春，写实风格的骏马，春节喜庆氛围，红色装饰，金色元素",
        "size": "1024x1024",
        "watermark_enabled": False,
        "quality": "hd"
    }

    try:
        print("正在测试GLM图像生成API...")
        print(f"请求URL: {url}")
        print(f"请求头: {headers}")
        print(f"请求体: {json.dumps(payload, indent=2, ensure_ascii=False)}")

        # 发送请求，忽略SSL证书验证（用于测试）
        response = requests.post(url, headers=headers, json=payload, verify=False)

        print(f"响应状态码: {response.status_code}")
        print(f"响应内容: {response.text}")

        if response.status_code == 200:
            result = response.json()
            print("API调用成功！")
            print(f"响应结果: {json.dumps(result, indent=2, ensure_ascii=False)}")
        else:
            print(f"API调用失败，状态码: {response.status_code}")
            print(f"错误信息: {response.text}")

    except Exception as e:
        print(f"请求失败: {str(e)}")

if __name__ == "__main__":
    test_glm_image_api()
