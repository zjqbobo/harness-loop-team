#!/bin/bash
# ===========================================
# Harness 端到端脚本：图表渲染 + MD → DOCX
# 功能：一条命令完成 图表PNG渲染 → 代码块替换 → MD转DOCX
# 依赖：render-diagrams.sh + md2docx.sh
# ===========================================
set -e

USAGE="
用法: doc-pipeline.sh <md文件路径> [--mode <mermaid|fireworks>] [--skip-render] [--skip-docx]
  --mode         图表工具，默认 mermaid (mermaid | fireworks)
  --skip-render  跳过图表渲染（图表已是PNG引用）
  --skip-docx    跳过DOCX转换（只做渲染）

示例:
  doc-pipeline.sh ./方案.md                        # mermaid渲染 + 转docx
  doc-pipeline.sh ./方案.md --mode fireworks       # fireworks渲染 + 转docx
  doc-pipeline.sh ./方案.md --skip-render           # 只转docx（图表已处理）
  doc-pipeline.sh ./方案.md --skip-docx             # 只渲染图表
"

if [ $# -lt 1 ]; then
    echo "$USAGE"
    exit 1
fi

MD_FILE=$(realpath "$1")
shift
MODE="mermaid"
SKIP_RENDER=false
SKIP_DOCX=false

while [ $# -gt 0 ]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --skip-render) SKIP_RENDER=true; shift ;;
        --skip-docx) SKIP_DOCX=true; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

if [ ! -f "$MD_FILE" ]; then
    echo "❌ 文件不存在: $MD_FILE"
    exit 1
fi

# 定位脚本目录（支持符号链接）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Harness 文档流水线"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 文件: $(basename "$MD_FILE")"
echo "🔧 模式: $MODE"
echo ""

# ========== Phase 1: 图表渲染 ==========
if [ "$SKIP_RENDER" = false ]; then
    echo "📐 Phase 1: 图表渲染 ($MODE)"
    echo "──────────────────────────────"

    if [ "$MODE" = "mermaid" ]; then
        "$SCRIPT_DIR/render-diagrams.sh" "$MD_FILE" --mode mermaid
    elif [ "$MODE" = "fireworks" ]; then
        "$SCRIPT_DIR/render-diagrams.sh" "$MD_FILE" --mode fireworks
    else
        echo "❌ 未知模式: $MODE"
        exit 1
    fi

    echo ""
else
    echo "⏭️  Phase 1: 跳过图表渲染"
    echo ""
fi

# ========== Phase 2: MD → DOCX ==========
if [ "$SKIP_DOCX" = false ]; then
    echo "📄 Phase 2: MD → DOCX"
    echo "──────────────────────────────"

    "$SCRIPT_DIR/md2docx.sh" "$MD_FILE"

    echo ""
else
    echo "⏭️  Phase 2: 跳过DOCX转换"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 文档流水线完成！"
