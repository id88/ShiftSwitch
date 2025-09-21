#!/bin/bash

# ShiftSwitch 发布脚本
# 用法: ./scripts/release.sh [version]
# 示例: ./scripts/release.sh v1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
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

# 检查参数
if [ $# -eq 0 ]; then
    print_error "请提供版本号"
    echo "用法: $0 <version>"
    echo "示例: $0 v1.0.0"
    exit 1
fi

VERSION=$1

# 验证版本号格式
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "版本号格式不正确，应为 vX.Y.Z 格式"
    echo "示例: v1.0.0, v2.1.3"
    exit 1
fi

print_info "开始发布 ShiftSwitch $VERSION"

# 检查是否在项目根目录
if [ ! -f "ShiftSwitch.xcodeproj/project.pbxproj" ]; then
    print_error "请在 ShiftSwitch 项目根目录运行此脚本"
    exit 1
fi

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    print_warning "有未提交的更改，是否继续？(y/N)"
    read -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        print_info "发布已取消"
        exit 0
    fi
fi

# 检查是否在正确的分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ ! $CURRENT_BRANCH =~ ^(main|master)$ ]]; then
    print_warning "当前在分支 '$CURRENT_BRANCH'，建议在 main/master 分支发布。是否继续？(y/N)"
    read -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        print_info "发布已取消"
        exit 0
    fi
fi

# 检查标签是否已存在
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    print_error "标签 $VERSION 已存在"
    exit 1
fi

# 拉取最新代码
print_info "拉取最新代码..."
git pull origin "$CURRENT_BRANCH"

# 清理构建目录
print_info "清理构建目录..."
rm -rf build
mkdir -p build

# 编译应用
print_info "编译 ShiftSwitch..."
xcodebuild -scheme ShiftSwitch \
    -configuration Release \
    -derivedDataPath ./build \
    clean build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
    print_error "编译失败"
    exit 1
fi

print_success "编译完成"

# 验证构建结果
APP_PATH="./build/Build/Products/Release/ShiftSwitch.app"
if [ ! -d "$APP_PATH" ]; then
    print_error "找不到编译后的应用: $APP_PATH"
    exit 1
fi

# 创建 ZIP 包
print_info "创建 ZIP 包..."
cd "./build/Build/Products/Release/"
zip -r "../../../../build/ShiftSwitch-$VERSION.zip" ShiftSwitch.app
cd "../../../../"

print_success "ZIP 包创建完成: build/ShiftSwitch-$VERSION.zip"

# 创建 DMG（如果有 create-dmg 工具）
if command -v create-dmg &> /dev/null; then
    print_info "创建 DMG 安装包..."
    create-dmg \
        --volname "ShiftSwitch $VERSION" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 400 190 \
        "./build/ShiftSwitch-$VERSION.dmg" \
        "$APP_PATH" 2>/dev/null || \
    create-dmg \
        --volname "ShiftSwitch $VERSION" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 400 190 \
        "./build/ShiftSwitch-$VERSION.dmg" \
        "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        print_success "DMG 包创建完成: build/ShiftSwitch-$VERSION.dmg"
    else
        print_warning "DMG 创建失败，但 ZIP 包已创建"
    fi
else
    print_warning "未安装 create-dmg，跳过 DMG 创建"
    print_info "可以运行: brew install create-dmg"
fi

# 显示构建信息
print_info "构建信息:"
ls -lh build/ShiftSwitch-$VERSION.*
file "$APP_PATH/Contents/MacOS/ShiftSwitch"

# 询问是否创建 Git 标签
print_warning "是否创建 Git 标签 $VERSION 并推送到远程仓库？(y/N)"
read -r response
if [[ $response =~ ^[Yy]$ ]]; then
    # 创建标签
    print_info "创建标签 $VERSION..."
    git tag -a "$VERSION" -m "Release $VERSION"
    
    # 推送标签
    print_info "推送标签到远程仓库..."
    git push origin "$VERSION"
    
    print_success "标签已推送，GitHub Actions 将自动构建和发布"
    print_info "查看构建状态: https://github.com/$(git config --get remote.origin.url | sed 's/.*[:/]\([^/]*\/[^/]*\)\.git/\1/')/actions"
else
    print_info "标签未创建，您可以稍后手动创建:"
    echo "  git tag -a $VERSION -m 'Release $VERSION'"
    echo "  git push origin $VERSION"
fi

print_success "发布准备完成！"
print_info "构建产物位置:"
echo "  - ZIP: build/ShiftSwitch-$VERSION.zip"
if [ -f "./build/ShiftSwitch-$VERSION.dmg" ]; then
    echo "  - DMG: build/ShiftSwitch-$VERSION.dmg"
fi

print_info "安装测试:"
echo "  sudo cp -R '$APP_PATH' /Applications/"
echo "  open /Applications/ShiftSwitch.app"
