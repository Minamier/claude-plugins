---
name: 编码规范检查
description: 在编写代码时，确保Python文件使用UTF-8编码，PowerShell文件使用GBK编码。当创建或修改.py文件时，检查并确保使用UTF-8编码；当创建或修改.ps1文件时，检查并确保使用GBK编码。
---

# 编码规范检查

## 概述

此技能用于确保代码文件的编码格式符合项目规范：
- Python文件（.py）必须使用UTF-8编码
- PowerShell文件（.ps1）必须使用GBK编码

## 执行步骤

### Python文件处理
1. 使用UTF-8编码保存文件
2. 在文件开头添加编码声明：`# -*- coding: utf-8 -*-`
3. 确保文件内容符合UTF-8编码规范

### PowerShell文件处理
1. 使用GBK编码保存文件
2. 确保文件内容符合GBK编码规范

## 验证方法

### 检查Python文件编码
```python
import chardet

def check_python_encoding(file_path):
    with open(file_path, 'rb') as f:
        raw_data = f.read()
        result = chardet.detect(raw_data)
        encoding = result['encoding']

    if encoding.lower() not in ['utf-8', 'utf-8-sig']:
        return False, encoding

    # 检查是否有编码声明
    with open(file_path, 'r', encoding='utf-8') as f:
        first_line = f.readline().strip()

    if not first_line.startswith('#') or 'coding' not in first_line:
        return False, 'missing encoding declaration'

    return True, 'utf-8'
```

### 检查PowerShell文件编码
```python
import chardet

def check_powershell_encoding(file_path):
    with open(file_path, 'rb') as f:
        raw_data = f.read()
        result = chardet.detect(raw_data)
        encoding = result['encoding']

    if encoding.lower() not in ['gbk', 'gb2312', 'cp936']:
        return False, encoding

    return True, 'gbk'
```

## 脚本工具

### 编码检查脚本
参考 `scripts/check_encoding.py` 文件。
