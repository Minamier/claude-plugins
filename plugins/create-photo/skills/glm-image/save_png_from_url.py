#!/usr/bin/env python3
"""
从GLM Image API生成的URL下载并保存图像
"""

import requests
import os
import base64
from io import BytesIO
from PIL import Image
from pathlib import Path

import os

def save_png_from_url(image_url, photo_id, keywords, output_dir=None):
    """
    从GLM Image API返回的URL下载图像并保存

    Args:
        image_url: 图像下载URL
        photo_id: 图像的唯一标识符
        keywords: 图像的关键词（用于文件名）
        output_dir: 输出目录（默认：当前工作区根目录/OUT_ai_photo）

    Returns:
        str: 保存的文件路径
    """
    # 默认保存路径为当前工作区根目录/OUT_ai_photo
    if output_dir is None:
        # 获取当前工作区根目录（my-marketplace）
        root_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
        output_dir = os.path.join(root_path, 'OUT_ai_photo')
    try:
        # 确保输出目录存在
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        # 生成文件名
        # 使用关键词和照片ID的后四位
        id_suffix = photo_id[-4:] if photo_id else "0001"
        if keywords:
            filename = f"{keywords}_{id_suffix}.png"
        else:
            filename = f"{id_suffix}.png"
        save_path = output_path / filename

        print(f"📦 正在下载图像: {image_url}")
        print(f"💾 保存路径: {save_path}")

        # 下载图像
        response = requests.get(image_url, timeout=30)
        if response.status_code == 200:
            # 保存图像到文件
            with open(save_path, "wb") as f:
                f.write(response.content)

            print(f"✅ 图像已保存到: {save_path}")
            return str(save_path)
        else:
            print(f"❌ 下载失败，HTTP状态码: {response.status_code}")
            return None

    except Exception as e:
        print(f"❌ 保存图像时出错: {str(e)}")
        return None

def save_image_from_dict(image_data, photo_id, keywords, output_dir=None):
    """
    从generate_image返回的字典中保存图像（支持base64和url）

    Args:
        image_data: 包含图像信息的字典（来自generate_image的返回）
        photo_id: 图像的唯一标识符
        keywords: 图像的关键词（用于文件名）
        output_dir: 输出目录（默认：当前工作区根目录/OUT_ai_photo）

    Returns:
        str: 保存的文件路径
    """
    # 默认保存路径为当前工作区根目录/OUT_ai_photo
    if output_dir is None:
        # 获取当前工作区根目录（my-marketplace）
        root_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..'))
        output_dir = os.path.join(root_path, 'OUT_ai_photo')
    try:
        if image_data.get("base64"):
            print(f"📦 使用base64数据保存图像")
            img_data = base64.b64decode(image_data["base64"])
            img = Image.open(BytesIO(img_data))

            output_path = Path(output_dir)
            output_path.mkdir(exist_ok=True)

            id_suffix = photo_id[-4:] if photo_id else "0001"
            if keywords:
                filename = f"{keywords}_{id_suffix}.png"
            else:
                filename = f"{id_suffix}.png"
            save_path = output_path / filename

            img.save(save_path, "PNG")
            print(f"✅ 图像已保存到: {save_path}")
            return str(save_path)
        elif image_data.get("url"):
            return save_png_from_url(image_data["url"], photo_id, keywords, output_dir)
        else:
            print("❌ 图像数据无效：既没有base64数据也没有URL")
            return None
    except Exception as e:
        print(f"❌ 保存图像时出错: {str(e)}")
        return None
