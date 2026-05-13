#!/bin/bash
# ===========================================
# Harness 通用脚本：SVG 批量转 PNG（用于文档插图）
# 功能：将目录下所有 SVG 转为 1920px 宽度的 PNG（文档标准分辨率）
# 依赖：rsvg-convert (librsvg)
# ===========================================
set -e

INPUT_DIR="${1:-.}"
WIDTH="${2:-1920}"

# 检查依赖
if ! command -v rsvg-convert &> /dev/null; then
    echo "❌ 未找到 rsvg-convert，请先安装: brew install librsvg"
    exit 1
fi

echo "🔄 正在转换 SVG -> PNG (宽度: ${WIDTH}px)..."
COUNT=0

for svg in "$INPUT_DIR"/*.svg; do
    if [ -f "$svg" ]; then
        png="${svg%.svg}.png"
        rsvg-convert -w "$WIDTH" "$svg" -o "$png"
        echo "  ✅ $(basename "$svg") -> $(basename "$png")"
        COUNT=$((COUNT + 1))
    fi
done

echo ""
echo "✅ 转换完成！共转换 $COUNT 个文件"
echo "📁 输出目录: $INPUT_DIR"
