#!/bin/bash

# 生成应用图标脚本
# 使用方法: ./generate_icons.sh ShiftSwitch.png

set -e

if [ $# -eq 0 ]; then
    echo "用法: $0 <源图标文件>"
    echo "例如: $0 ShiftSwitch.png"
    exit 1
fi

SOURCE_IMAGE="$1"
ICONSET_DIR="../ShiftSwitch/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "错误: 找不到源图标文件 $SOURCE_IMAGE"
    exit 1
fi

echo "正在从 $SOURCE_IMAGE 生成macOS应用图标..."

# 创建图标集目录（如果不存在）
mkdir -p "$ICONSET_DIR"

# 生成各种尺寸的图标
# 16x16
sips -z 16 16 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16.png"
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png"

# 32x32
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32.png"
sips -z 64 64 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png"

# 128x128
sips -z 128 128 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128.png"
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png"

# 256x256
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256.png"
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png"

# 512x512
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512.png"
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png"

echo "图标生成完成！"
echo "生成的文件位于: $ICONSET_DIR"

# 列出生成的文件
echo ""
echo "生成的图标文件:"
ls -la "$ICONSET_DIR"/*.png
