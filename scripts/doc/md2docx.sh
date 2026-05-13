#!/bin/bash
# ===========================================
# Harness 通用脚本：Markdown 转 Word (.docx)
# 功能：自动识别并嵌入本地图片，支持相对路径
# 依赖：pandoc
# ===========================================
set -e

if [ $# -lt 1 ]; then
    echo "用法: md2docx.sh <md文件路径> [输出docx路径]"
    echo "示例: md2docx.sh ./方案.md ./方案.docx"
    exit 1
fi

MD_FILE="$1"
OUTPUT_FILE="${2:-${MD_FILE%.md}.docx}"

# 检查文件是否存在
if [ ! -f "$MD_FILE" ]; then
    echo "❌ 文件不存在: $MD_FILE"
    exit 1
fi

# 检查 pandoc
if ! command -v pandoc &> /dev/null; then
    echo "❌ 未找到 pandoc，请先安装:"
    echo "   macOS: brew install pandoc"
    echo "   Linux: sudo apt install pandoc"
    exit 1
fi

# 获取md文件所在目录
MD_DIR=$(dirname "$MD_FILE")

# 进入md文件目录执行转换（确保相对路径图片正确）
cd "$MD_DIR"
MD_BASENAME=$(basename "$MD_FILE")
OUTPUT_BASENAME=$(basename "$OUTPUT_FILE")

echo "🔄 正在转换: $MD_BASENAME -> $OUTPUT_BASENAME"
echo "📁 工作目录: $MD_DIR"

# 使用 pandoc 转换（pandoc 会自动处理相对路径图片）
pandoc -s "$MD_BASENAME" -o "$OUTPUT_BASENAME"

# 验证图片是否嵌入
echo "✅ 转换完成: $OUTPUT_FILE"
echo "📊 文件大小: $(du -h "$OUTPUT_BASENAME" | cut -f1)"

# 统计嵌入的图片数量
IMAGE_COUNT=$(unzip -l "$OUTPUT_BASENAME" 2>/dev/null | grep -E "\.(png|jpg|jpeg)$" | wc -l)
echo "🖼️  嵌入图片数: $IMAGE_COUNT"
