#!/usr/bin/env python3
"""
应用 patch 移除 generate-darwin-source-and-headers.py 中的 iOS armv7 支持
"""

import sys
import os
import re

def apply_patch(file_path):
    """应用 patch 移除 iOS armv7 支持"""
    if not os.path.exists(file_path):
        print(f"错误：文件 {file_path} 不存在", file=sys.stderr)
        return False
    
    # 备份原文件
    backup_path = file_path + '.orig'
    if not os.path.exists(backup_path):
        with open(file_path, 'r') as f:
            content = f.read()
        with open(backup_path, 'w') as f:
            f.write(content)
        print(f"已备份原文件到 {backup_path}")
    
    # 读取文件内容
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 检查是否已经应用过 patch
    if 'class ios_device_armv7_platform' not in content:
        print("Patch 已应用或文件已修改，跳过")
        return True
    
    # 使用正则表达式删除 ios_device_armv7_platform 类定义
    # 匹配从 class 开始到空行结束的整个类定义
    pattern = r'class ios_device_armv7_platform\(armv7_platform\):.*?\n\n'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    # 删除 copy_src_platform_files(ios_device_armv7_platform) 调用
    content = re.sub(r'^\s*copy_src_platform_files\(ios_device_armv7_platform\)\s*$\n', '', content, flags=re.MULTILINE)
    
    # 删除 build_target(ios_device_armv7_platform, platform_headers) 调用
    content = re.sub(r'^\s*build_target\(ios_device_armv7_platform, platform_headers\)\s*$\n', '', content, flags=re.MULTILINE)
    
    # 写回文件
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("Patch 已成功应用，iOS armv7 支持已移除")
    return True

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # 脚本在 build_libffi_scripts 目录，libffi 目录在父目录下
    project_root = os.path.dirname(script_dir)
    target_file = os.path.join(project_root, 'libffi', 'generate-darwin-source-and-headers.py')
    
    if apply_patch(target_file):
        sys.exit(0)
    else:
        sys.exit(1)
