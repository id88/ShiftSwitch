#!/bin/bash

# 🔒 ShiftSwitch 代码签名修复脚本
# 此脚本帮助解决 macOS "应用已损坏" 错误

set -e

APP_PATH="/Applications/ShiftSwitch.app"
SCRIPT_NAME="$(basename "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "🔒 ShiftSwitch 代码签名修复工具"
    echo "=================================="
    echo -e "${NC}"
}

check_app_exists() {
    if [ ! -d "$APP_PATH" ]; then
        print_error "未找到 ShiftSwitch.app"
        print_info "请确保应用已安装到 /Applications 文件夹"
        exit 1
    fi
}

show_app_info() {
    print_info "应用路径: $APP_PATH"
    
    # 检查当前签名状态
    if codesign -dv "$APP_PATH" 2>/dev/null; then
        print_info "当前签名状态:"
        codesign -dv "$APP_PATH" 2>&1 | grep -E "(Authority|Identifier|TeamIdentifier)" || true
    else
        print_warning "应用当前未签名"
    fi
    
    # 检查扩展属性
    if xattr "$APP_PATH" 2>/dev/null | grep -q quarantine; then
        print_warning "检测到隔离属性（quarantine）"
    else
        print_info "未检测到隔离属性"
    fi
}

fix_quarantine() {
    print_info "正在移除隔离属性..."
    
    if sudo xattr -rd com.apple.quarantine "$APP_PATH" 2>/dev/null; then
        print_success "隔离属性已移除"
    else
        print_warning "移除隔离属性失败，尝试移除所有扩展属性..."
        if sudo xattr -c "$APP_PATH" 2>/dev/null; then
            print_success "所有扩展属性已移除"
        else
            print_error "移除扩展属性失败"
            return 1
        fi
    fi
}

adhoc_sign() {
    print_info "正在执行 ad-hoc 签名..."
    
    if codesign --force --deep --sign - "$APP_PATH" 2>/dev/null; then
        print_success "Ad-hoc 签名完成"
        
        # 验证签名
        if codesign --verify --verbose "$APP_PATH" 2>/dev/null; then
            print_success "签名验证通过"
        else
            print_warning "签名验证失败，但应用可能仍然可以运行"
        fi
    else
        print_error "Ad-hoc 签名失败"
        print_info "这可能是由于权限问题，尝试使用 sudo"
        
        if sudo codesign --force --deep --sign - "$APP_PATH" 2>/dev/null; then
            print_success "Ad-hoc 签名完成（使用 sudo）"
        else
            print_error "签名失败，请手动尝试右键打开应用"
            return 1
        fi
    fi
}

test_app() {
    print_info "测试应用是否可以通过 Gatekeeper..."
    
    # 检查 Gatekeeper 状态
    if spctl -a -v "$APP_PATH" 2>&1 | grep -q "accepted"; then
        print_success "应用通过 Gatekeeper 检查"
    else
        print_warning "应用未通过 Gatekeeper 检查"
        print_info "这是正常的，因为应用使用 ad-hoc 签名"
        print_info "您仍需要右键点击应用选择'打开'"
    fi
}

show_instructions() {
    echo
    print_info "修复完成！现在您可以："
    echo
    echo "方法1: 双击打开（可能仍需确认）"
    echo "方法2: 右键点击 → 选择'打开'"
    echo "方法3: 使用终端: open '$APP_PATH'"
    echo
    print_warning "如果仍然遇到问题，请查看详细指南:"
    print_info "https://github.com/id88/ShiftSwitch/blob/main/.github/CODE_SIGNING.md"
}

main() {
    print_header
    
    # 检查管理员权限
    if [ "$EUID" -ne 0 ] && [ "$1" != "--no-sudo" ]; then
        print_warning "此脚本需要管理员权限来修改应用"
        print_info "正在请求 sudo 权限..."
        sudo "$0" --no-sudo
        exit $?
    fi
    
    check_app_exists
    show_app_info
    
    echo
    print_info "开始修复过程..."
    
    # 1. 移除隔离属性
    fix_quarantine
    
    # 2. 执行 ad-hoc 签名
    adhoc_sign
    
    # 3. 测试应用
    test_app
    
    # 4. 显示使用说明
    show_instructions
    
    print_success "修复完成！"
}

# 显示帮助信息
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_header
    echo "用法: $SCRIPT_NAME [选项]"
    echo
    echo "选项:"
    echo "  --help, -h     显示帮助信息"
    echo "  --no-sudo      内部使用，请勿手动调用"
    echo
    echo "此脚本会:"
    echo "1. 移除应用的隔离属性"
    echo "2. 执行 ad-hoc 代码签名"
    echo "3. 验证签名状态"
    echo "4. 测试 Gatekeeper 兼容性"
    echo
    echo "更多信息请访问:"
    echo "https://github.com/id88/ShiftSwitch"
    exit 0
fi

# 运行主函数
main "$@"
