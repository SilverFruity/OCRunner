#!/usr/bin/env python3
"""
应用 patch 导出 tramp.c 中的符号（针对 iOS Simulator x86_64）
"""

import sys
import os
import re

def apply_patch(file_path):
    """应用 patch 导出 tramp.c 中的符号"""
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
    if 'FFI_TRAMP_EXPORT' in content:
        print("Patch 已应用，跳过")
        return True
    
    # 找到 "#else /* !FFI_EXEC_STATIC_TRAMP */" 后的块
    else_pattern = r'(#else\s*/\*\s*!FFI_EXEC_STATIC_TRAMP\s*\*/)'
    match = re.search(else_pattern, content)
    
    if not match:
        print("错误：找不到 #else /* !FFI_EXEC_STATIC_TRAMP */ 块", file=sys.stderr)
        return False
    
    # 在 #else 后添加导出宏定义
    else_pos = match.end()
    
    # 添加导出宏定义
    export_macro = '''

#ifdef __APPLE__
#include <TargetConditionals.h>
#if TARGET_OS_SIMULATOR && defined(__x86_64__)
/* 在 iOS Simulator x86_64 上，确保符号被导出 */
#define FFI_TRAMP_EXPORT __attribute__((visibility("default")))
#else
#define FFI_TRAMP_EXPORT
#endif
#else
#define FFI_TRAMP_EXPORT
#endif

'''
    
    # 在 #else 后插入宏定义
    content = content[:else_pos] + export_macro + content[else_pos:]
    
    # 修改函数声明，在返回类型前添加 FFI_TRAMP_EXPORT
    # 匹配模式：int\nffi_tramp_is_supported(void)
    # 需要匹配：返回类型（int/void */void）在单独一行，函数名在下一行
    function_patterns = [
        (r'^(int)\s*\n\s*(ffi_tramp_is_supported\(void\))', r'FFI_TRAMP_EXPORT int\n\2'),
        (r'^(void \*)\s*\n\s*(ffi_tramp_alloc\s*\([^)]*\))', r'FFI_TRAMP_EXPORT void *\n\2'),
        (r'^(void)\s*\n\s*(ffi_tramp_set_parms\s*\([^)]*\))', r'FFI_TRAMP_EXPORT void\n\2'),
        (r'^(void \*)\s*\n\s*(ffi_tramp_get_addr\s*\([^)]*\))', r'FFI_TRAMP_EXPORT void *\n\2'),
        (r'^(void)\s*\n\s*(ffi_tramp_free\s*\([^)]*\))', r'FFI_TRAMP_EXPORT void\n\2'),
    ]
    
    for pattern, replacement in function_patterns:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # 写回文件
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("Patch 已成功应用，tramp.c 符号导出已启用（iOS Simulator x86_64）")
    return True

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # 脚本在 build_libffi_scripts 目录，libffi 目录在父目录下
    project_root = os.path.dirname(script_dir)
    target_file = os.path.join(project_root, 'libffi', 'src', 'tramp.c')
    
    if apply_patch(target_file):
        sys.exit(0)
    else:
        sys.exit(1)
