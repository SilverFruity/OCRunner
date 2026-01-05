#!/bin/bash

# 构建 libffi.xcframework 的脚本
# 支持 iOS 设备 (arm64) 和 iOS Simulator (x86_64, arm64)
#
# 使用方法:
#   ./build_libffi_xcframework.sh [选项]
#
# 选项:
#   --enable-exec-static-tramp    启用 FFI_EXEC_STATIC_TRAMP 宏（默认：禁用）
#
# 依赖:
#   - Xcode Command Line Tools
#   - Python 3 (用于运行 generate-darwin-source-and-headers.py)
#   - autotools (autoconf, automake, libtool) - 如果 configure 脚本不存在
#
# 输出:
#   OCRunner/libffi/libffi.xcframework

set -e  # 遇到错误立即退出

# 默认配置
ENABLE_EXEC_STATIC_TRAMP=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录（build_libffi_scripts）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取项目根目录（build_libffi_scripts 的父目录）
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIBFFI_DIR="${PROJECT_ROOT}/libffi"
OUTPUT_DIR="${PROJECT_ROOT}/OCRunner/libffi"
XCFRAMEWORK_PATH="${OUTPUT_DIR}/libffi.xcframework"

# 清理函数
cleanup() {
    echo -e "${YELLOW}清理临时文件...${NC}"
    cd "${LIBFFI_DIR}"
    # 可以选择是否清理构建目录
    # rm -rf build_*
}

# 错误处理
trap cleanup EXIT

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --enable-exec-static-tramp)
                ENABLE_EXEC_STATIC_TRAMP=1
                shift
                ;;
            --help|-h)
                echo "使用方法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --enable-exec-static-tramp    启用 FFI_EXEC_STATIC_TRAMP 宏（默认：禁用）"
                echo "  --help, -h                    显示此帮助信息"
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun 未找到，请确保已安装 Xcode Command Line Tools"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        print_error "Python 未找到，需要 Python 来运行 generate-darwin-source-and-headers.py"
        exit 1
    fi
    
    PYTHON_CMD=$(command -v python3 || command -v python)
    print_info "使用 Python: $PYTHON_CMD"
    
    # 检查 libffi 目录是否存在
    if [ ! -d "${LIBFFI_DIR}" ]; then
        print_error "libffi 目录不存在: ${LIBFFI_DIR}"
        exit 1
    fi
}

# 准备构建环境
prepare_build_env() {
    print_info "准备构建环境..."
    cd "${LIBFFI_DIR}"
    
    # 检查是否需要运行 autogen.sh
    if [ ! -f "configure" ]; then
        print_info "运行 autogen.sh 生成 configure 脚本..."
        ./autogen.sh
    fi
    
    # 应用 patch 移除 iOS armv7 支持
    PATCH_SCRIPT="${SCRIPT_DIR}/apply-remove-ios-armv7-patch.py"
    PYTHON_FILE="${LIBFFI_DIR}/generate-darwin-source-and-headers.py"
    
    if [ -f "${PATCH_SCRIPT}" ] && [ -f "${PYTHON_FILE}" ]; then
        print_info "应用 patch 移除 iOS armv7 支持..."
        ${PYTHON_CMD} "${PATCH_SCRIPT}"
        if [ $? -ne 0 ]; then
            print_error "应用 patch 失败"
            exit 1
        fi
    elif [ -f "${PYTHON_FILE}" ]; then
        print_warning "Patch 脚本不存在，尝试直接运行 generate-darwin-source-and-headers.py（可能包含 armv7 构建）"
    fi
    
    # 应用 patch 导出 tramp.c 符号（针对 iOS Simulator x86_64）
    TRAMP_PATCH_SCRIPT="${SCRIPT_DIR}/apply-export-tramp-symbols-patch.py"
    TRAMP_FILE="${LIBFFI_DIR}/src/tramp.c"
    
    if [ -f "${TRAMP_PATCH_SCRIPT}" ] && [ -f "${TRAMP_FILE}" ]; then
        print_info "应用 patch 导出 tramp.c 符号（iOS Simulator x86_64）..."
        ${PYTHON_CMD} "${TRAMP_PATCH_SCRIPT}"
        if [ $? -ne 0 ]; then
            print_error "应用 tramp.c patch 失败"
            exit 1
        fi
    fi
    
    # 生成 iOS 源文件和头文件
    # 注意：这个脚本主要用于 Xcode 项目构建，对于 autotools 构建不是必须的
    # 但如果失败，我们仍然继续构建（因为我们使用 autotools 直接构建）
    if [ -f "generate-darwin-source-and-headers.py" ]; then
        print_info "生成 iOS 源文件和头文件..."
        ${PYTHON_CMD} generate-darwin-source-and-headers.py --only-ios || {
            print_warning "generate-darwin-source-and-headers.py 执行失败，但继续构建（我们使用 autotools 直接构建）"
        }
    fi
}

# 构建单个架构
build_arch() {
    local SDK=$1
    local ARCH=$2
    local TARGET=$3
    local BUILD_DIR="build_${SDK}_${ARCH}"
    
    print_info "构建 ${SDK} ${ARCH}..."
    
    cd "${LIBFFI_DIR}"
    
    # 清理旧的构建目录
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    
    # 设置 SDK 路径
    SDKROOT=$(xcrun -sdk ${SDK} --show-sdk-path)
    
    # 设置 CFLAGS 和 LDFLAGS
    if [ "${SDK}" = "iphoneos" ]; then
        CFLAGS="-arch ${ARCH} -isysroot ${SDKROOT} -miphoneos-version-min=9.0"
    else
        # iOS Simulator 使用 -mios-simulator-version-min
        CFLAGS="-arch ${ARCH} -isysroot ${SDKROOT} -mios-simulator-version-min=9.0"
    fi
    LDFLAGS="${CFLAGS}"
    
    # 运行 configure
    print_info "配置 ${SDK} ${ARCH}..."
    export CC=$(xcrun -sdk ${SDK} -find clang)
    export CXX=$(xcrun -sdk ${SDK} -find clang++)
    export LD=$(xcrun -sdk ${SDK} -find ld)
    export AR=$(xcrun -sdk ${SDK} -find ar)
    export RANLIB=$(xcrun -sdk ${SDK} -find ranlib)
    export STRIP=$(xcrun -sdk ${SDK} -find strip)
    export CFLAGS
    export LDFLAGS
    export SDKROOT
    
    # 构建 configure 参数
    CONFIGURE_ARGS=(
        --host=${TARGET}
        --enable-static
        --disable-shared
        --disable-multi-os-directory
        --disable-docs
        --prefix=$(pwd)/install
    )
    
    # 根据选项决定是否启用 exec-static-tramp
    if [ ${ENABLE_EXEC_STATIC_TRAMP} -eq 1 ]; then
        CONFIGURE_ARGS+=(--enable-exec-static-tramp)
        print_info "启用 FFI_EXEC_STATIC_TRAMP 宏"
    else
        CONFIGURE_ARGS+=(--disable-exec-static-tramp)
    fi
    
    ../configure "${CONFIGURE_ARGS[@]}"
    
    # 编译
    print_info "编译 ${SDK} ${ARCH}..."
    make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # 安装到本地目录
    make install
    
    cd "${LIBFFI_DIR}"
}

# 构建 iOS 设备版本 (arm64)
build_ios_device() {
    build_arch "iphoneos" "arm64" "arm64-apple-ios"
}

# 构建 iOS Simulator x86_64
build_ios_simulator_x86_64() {
    build_arch "iphonesimulator" "x86_64" "x86_64-apple-ios-simulator"
}

# 构建 iOS Simulator arm64
build_ios_simulator_arm64() {
    build_arch "iphonesimulator" "arm64" "arm64-apple-ios-simulator"
}

# 验证库文件的目标平台
# 验证库文件的目标平台（对于静态库，只能做基本检查）
verify_lib_platform() {
    local LIB_FILE=$1
    local EXPECTED_PLATFORM=$2  # "ios" or "ios-simulator"
    
    if [ ! -f "${LIB_FILE}" ]; then
        print_error "库文件不存在: ${LIB_FILE}"
        return 1
    fi
    
    # 对于静态库文件，file 和 otool 可能无法准确区分 iOS 设备和 iOS Simulator
    # 我们主要依赖构建时使用的正确编译标志来确保平台正确
    # 这里只做基本的架构检查，平台验证在实际使用时会由链接器检查
    
    # 验证库文件架构
    local ARCH_INFO=$(xcrun lipo -info "${LIB_FILE}" 2>/dev/null)
    if [ $? -ne 0 ]; then
        print_error "无法读取库文件架构信息: ${LIB_FILE}"
        return 1
    fi
    
    print_info "库文件架构检查: ${LIB_FILE}"
    print_info "  ${ARCH_INFO}"
    
    # 对于静态库，我们信任构建时使用的编译标志
    # 实际的平台验证会在链接时由 Xcode 进行
    return 0
}

# 创建通用库（合并多个架构）
create_universal_lib() {
    local OUTPUT_LIB=$1
    shift
    local INPUT_LIBS=("$@")
    
    print_info "创建通用库: ${OUTPUT_LIB}"
    
    # 验证输入库文件
    for lib in "${INPUT_LIBS[@]}"; do
        if [ ! -f "${lib}" ]; then
            print_error "库文件不存在: ${lib}"
            return 1
        fi
        print_info "  输入库: ${lib}"
        xcrun lipo -info "${lib}" || {
            print_error "无法读取库文件架构: ${lib}"
            return 1
        }
    done
    
    # 确保输出目录存在
    mkdir -p "$(dirname "${OUTPUT_LIB}")"
    
    # 使用 lipo 合并库
    xcrun lipo -create "${INPUT_LIBS[@]}" -output "${OUTPUT_LIB}"
    
    # 验证输出库
    print_info "输出库架构信息:"
    xcrun lipo -info "${OUTPUT_LIB}" || {
        print_error "无法验证输出库: ${OUTPUT_LIB}"
        return 1
    }
}

# 创建 module.modulemap 文件
create_module_map() {
    local HEADERS_DIR=$1
    
    if [ ! -d "${HEADERS_DIR}" ]; then
        print_warning "Headers 目录不存在: ${HEADERS_DIR}，跳过创建 module.modulemap"
        return 1
    fi
    
    print_info "创建 module.modulemap: ${HEADERS_DIR}/module.modulemap"
    
    # 创建 module.modulemap 文件
    # 使用 umbrella header 方式，ffi.h 是 libffi 的主头文件
    cat > "${HEADERS_DIR}/module.modulemap" <<EOF
module libffi {
    umbrella header "ffi.h"
    export *
    module * { export * }
}
EOF
    
    print_info "module.modulemap 创建完成"
}

# 创建 xcframework
create_xcframework() {
    print_info "创建 xcframework..."
    
    # 确保输出目录存在
    mkdir -p "${OUTPUT_DIR}"
    
    # 备份或删除旧的 xcframework
    if [ -d "${XCFRAMEWORK_PATH}" ]; then
        print_info "备份旧的 xcframework..."
        BACKUP_PATH="${XCFRAMEWORK_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${XCFRAMEWORK_PATH}" "${BACKUP_PATH}"
        print_info "旧版本已备份到: ${BACKUP_PATH}"
    fi
    
    # 创建新的 xcframework 目录结构
    mkdir -p "${XCFRAMEWORK_PATH}"
    
    # iOS 设备版本
    IOS_DEVICE_DIR="${XCFRAMEWORK_PATH}/ios-arm64"
    mkdir -p "${IOS_DEVICE_DIR}/Headers"
    
    # 复制库文件并验证架构
    if [ -f "${LIBFFI_DIR}/build_iphoneos_arm64/install/lib/libffi.a" ]; then
        print_info "验证 iOS 设备库文件架构..."
        xcrun lipo -info "${LIBFFI_DIR}/build_iphoneos_arm64/install/lib/libffi.a"
        verify_lib_platform "${LIBFFI_DIR}/build_iphoneos_arm64/install/lib/libffi.a" "ios"
        cp "${LIBFFI_DIR}/build_iphoneos_arm64/install/lib/libffi.a" "${IOS_DEVICE_DIR}/libffi.a"
    else
        print_error "找不到 iOS 设备库文件: ${LIBFFI_DIR}/build_iphoneos_arm64/install/lib/libffi.a"
        exit 1
    fi
    
    # 复制头文件（按优先级尝试多个位置）
    HEADERS_COPIED=0
    if [ -d "${LIBFFI_DIR}/build_iphoneos_arm64/install/include" ]; then
        cp -R "${LIBFFI_DIR}/build_iphoneos_arm64/install/include/"* "${IOS_DEVICE_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ] && [ -d "${LIBFFI_DIR}/build_iphoneos_arm64/include" ]; then
        cp -R "${LIBFFI_DIR}/build_iphoneos_arm64/include/"* "${IOS_DEVICE_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ] && [ -d "${LIBFFI_DIR}/include" ]; then
        cp -R "${LIBFFI_DIR}/include/"* "${IOS_DEVICE_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ]; then
        print_warning "未能复制头文件，请检查构建结果"
    fi
    
    # 创建 module.modulemap
    create_module_map "${IOS_DEVICE_DIR}/Headers"
    
    # iOS Simulator 版本（合并 x86_64 和 arm64）
    IOS_SIMULATOR_DIR="${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator"
    mkdir -p "${IOS_SIMULATOR_DIR}/Headers"
    
    # 创建模拟器通用库
    SIMULATOR_LIBS=()
    if [ -f "${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/lib/libffi.a" ]; then
        print_info "验证 iOS Simulator x86_64 库文件架构..."
        xcrun lipo -info "${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/lib/libffi.a"
        verify_lib_platform "${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/lib/libffi.a" "ios-simulator"
        SIMULATOR_LIBS+=("${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/lib/libffi.a")
    fi
    if [ -f "${LIBFFI_DIR}/build_iphonesimulator_arm64/install/lib/libffi.a" ]; then
        print_info "验证 iOS Simulator arm64 库文件架构..."
        xcrun lipo -info "${LIBFFI_DIR}/build_iphonesimulator_arm64/install/lib/libffi.a"
        verify_lib_platform "${LIBFFI_DIR}/build_iphonesimulator_arm64/install/lib/libffi.a" "ios-simulator"
        SIMULATOR_LIBS+=("${LIBFFI_DIR}/build_iphonesimulator_arm64/install/lib/libffi.a")
    fi
    
    if [ ${#SIMULATOR_LIBS[@]} -eq 0 ]; then
        print_error "找不到 iOS Simulator 库文件"
        exit 1
    fi
    
    create_universal_lib "${IOS_SIMULATOR_DIR}/libffi.a" "${SIMULATOR_LIBS[@]}"
    
    # 验证最终输出的模拟器库架构
    verify_lib_platform "${IOS_SIMULATOR_DIR}/libffi.a" "ios-simulator"
    
    # 复制头文件（使用任一架构的头文件即可）
    HEADERS_COPIED=0
    if [ -d "${LIBFFI_DIR}/build_iphonesimulator_arm64/install/include" ]; then
        cp -R "${LIBFFI_DIR}/build_iphonesimulator_arm64/install/include/"* "${IOS_SIMULATOR_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ] && [ -d "${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/include" ]; then
        cp -R "${LIBFFI_DIR}/build_iphonesimulator_x86_64/install/include/"* "${IOS_SIMULATOR_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ] && [ -d "${LIBFFI_DIR}/include" ]; then
        cp -R "${LIBFFI_DIR}/include/"* "${IOS_SIMULATOR_DIR}/Headers/" 2>/dev/null && HEADERS_COPIED=1
    fi
    if [ ${HEADERS_COPIED} -eq 0 ]; then
        print_warning "未能复制头文件，请检查构建结果"
    fi
    
    # 创建 module.modulemap
    create_module_map "${IOS_SIMULATOR_DIR}/Headers"
    
    # 创建 Info.plist
    cat > "${XCFRAMEWORK_PATH}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AvailableLibraries</key>
	<array>
		<dict>
			<key>BinaryPath</key>
			<string>libffi.a</string>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>ios-arm64</string>
			<key>LibraryPath</key>
			<string>libffi.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
		</dict>
		<dict>
			<key>BinaryPath</key>
			<string>libffi.a</string>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>ios-arm64_x86_64-simulator</string>
			<key>LibraryPath</key>
			<string>libffi.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
				<string>x86_64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
			<key>SupportedPlatformVariant</key>
			<string>simulator</string>
		</dict>
	</array>
	<key>CFBundlePackageType</key>
	<string>XFWK</string>
	<key>XCFrameworkFormatVersion</key>
	<string>1.0</string>
</dict>
</plist>
EOF
    
    print_info "xcframework 创建完成: ${XCFRAMEWORK_PATH}"
    print_info "验证 xcframework..."
    xcrun xcodebuild -checkFirstLaunchStatus
    xcrun xcodebuild -framework "${XCFRAMEWORK_PATH}" -checkFirstLaunchStatus 2>/dev/null || true
}

# 主函数
main() {
    print_info "开始构建 libffi.xcframework"
    print_info "工作目录: ${LIBFFI_DIR}"
    
    if [ ${ENABLE_EXEC_STATIC_TRAMP} -eq 1 ]; then
        print_info "配置: FFI_EXEC_STATIC_TRAMP 已启用"
    else
        print_info "配置: FFI_EXEC_STATIC_TRAMP 已禁用（默认）"
    fi
    
    # 检查依赖
    check_dependencies
    
    # 准备构建环境
    prepare_build_env
    
    # 构建各个架构
    build_ios_device
    build_ios_simulator_x86_64
    build_ios_simulator_arm64
    
    # 创建 xcframework
    create_xcframework
    
    print_info "构建完成！"
    print_info "xcframework 位置: ${XCFRAMEWORK_PATH}"
}

# 解析命令行参数
parse_args "$@"

# 运行主函数
main

