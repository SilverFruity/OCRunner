# libffi.xcframework 构建脚本

此目录包含构建 libffi.xcframework 所需的所有脚本和 patch 文件。

## 文件说明

- `build_libffi_xcframework.sh` - 主构建脚本，用于构建 iOS 和 iOS Simulator 版本的 libffi 并生成 xcframework
- `apply-remove-ios-armv7-patch.py` - Python 脚本，用于应用 patch 移除 iOS armv7 支持
- `remove-ios-armv7.patch` - Patch 文件，用于移除 generate-darwin-source-and-headers.py 中的 iOS armv7 支持
- `apply-export-tramp-symbols-patch.py` - Python 脚本，用于应用 patch 导出 tramp.c 中的符号（针对 iOS Simulator x86_64）
- `export-tramp-symbols-x86_64.patch` - Patch 文件，用于导出 tramp.c 中的符号

## 使用方法

```bash
cd build_libffi_scripts
./build_libffi_xcframework.sh [选项]
```

### 选项

- `--enable-exec-static-tramp` - 启用 FFI_EXEC_STATIC_TRAMP 宏（默认：禁用）
- `--help` 或 `-h` - 显示帮助信息

### 示例

```bash
# 默认构建（禁用 FFI_EXEC_STATIC_TRAMP）
./build_libffi_xcframework.sh

# 启用 FFI_EXEC_STATIC_TRAMP
./build_libffi_xcframework.sh --enable-exec-static-tramp
```

构建完成后，xcframework 将输出到 `OCRunner/libffi/libffi.xcframework`。

## 依赖

- Xcode Command Line Tools
- Python 3
- autotools (autoconf, automake, libtool) - 如果 configure 脚本不存在

