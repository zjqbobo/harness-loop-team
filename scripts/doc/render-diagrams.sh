#!/bin/bash
# ===========================================
# Harness 通用脚本：MD 图表代码块 → PNG 截图
# 功能：
#   1. 扫描 MD 文件中的图表代码块（mermaid / fireworks）
#   2. mermaid 模式：提取 .mmd → mmdc 渲染 PNG
#   3. fireworks 模式：AI 生成 SVG → rsvg-convert 渲染 PNG
#   4. 替换 MD 中的代码块为图片引用
# 依赖：
#   mermaid 模式: mmdc (@mermaid-js/mermaid-cli) + Chrome
#   fireworks 模式: rsvg-convert (librsvg)
# ===========================================
set -e

USAGE="
用法: render-diagrams.sh <md文件路径> [--mode <mermaid|fireworks>]
  --mode  指定图表工具，默认 mermaid
         mermaid:   提取 ```mermaid 代码块 → mmdc 渲染 → 替换
         fireworks: AI 需先已将 ```mermaid 替换为 SVG，
                    此脚本只做 SVG→PNG + 替换 MD 中的 SVG 代码块

示例:
  render-diagrams.sh ./方案.md
  render-diagrams.sh ./方案.md --mode fireworks
"

if [ $# -lt 1 ]; then
    echo "$USAGE"
    exit 1
fi

MD_FILE=$(realpath "$1")
shift
MODE="mermaid"

while [ $# -gt 0 ]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

MD_DIR=$(dirname "$MD_FILE")
IMG_DIR="$MD_DIR/images"
MD_BASENAME=$(basename "$MD_FILE")

if [ ! -f "$MD_FILE" ]; then
    echo "❌ 文件不存在: $MD_FILE"
    exit 1
fi

mkdir -p "$IMG_DIR"

echo "📝 文件: $MD_BASENAME"
echo "🔧 模式: $MODE"
echo "📁 输出: $IMG_DIR"
echo ""

# ============================================================
#  Mermaid 模式
# ============================================================
if [ "$MODE" = "mermaid" ]; then
    if ! command -v mmdc &> /dev/null; then
        echo "❌ 未找到 mmdc，请先安装: npm install -g @mermaid-js/mermaid-cli"
        exit 1
    fi

    # 自动检测 Chrome
    if [ -z "$PUPPETEER_EXECUTABLE_PATH" ]; then
        if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
            export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        elif command -v google-chrome &> /dev/null; then
            export PUPPETEER_EXECUTABLE_PATH=$(which google-chrome)
        elif command -v chromium &> /dev/null; then
            export PUPPETEER_EXECUTABLE_PATH=$(which chromium)
        fi
    fi

    # Step 1: 提取 .mmd
    echo "🔍 Step 1: 提取 Mermaid 代码块..."

    EXTRACT_PY=$(mktemp /tmp/_render_diag_extract.XXXXXX.py)
    cat > "$EXTRACT_PY" << 'PYEOF'
import re, os, sys

md_file = os.environ['RD_MD_FILE']
img_dir = os.environ['RD_IMG_DIR']

with open(md_file, 'r') as f:
    content = f.read()

pattern = re.compile(r'```mermaid\n(.*?)\n```', re.DOTALL)
blocks = pattern.findall(content)

if not blocks:
    print("ℹ️  未找到 Mermaid 代码块")
    sys.exit(0)

print(f"找到 {len(blocks)} 个 Mermaid 代码块")

def get_type(code):
    first_line = code.strip().split('\n')[0].strip().lower()
    if 'flowchart' in first_line or 'graph' in first_line: return 'flowchart'
    if 'sequencediagram' in code[:80]: return 'sequence'
    if 'classdiagram' in code[:80]: return 'class'
    if 'statediagram' in code[:80]: return 'state'
    if 'erdiagram' in code[:80]: return 'er'
    return 'mermaid'

for i, block in enumerate(blocks):
    t = get_type(block)
    fname = f"mermaid-{t}-{i+1:02d}.mmd"
    fpath = os.path.join(img_dir, fname)
    with open(fpath, 'w') as f:
        f.write(block)
    print(f"  [{i+1:02d}] {t:10s} → {fname}")

print(f"\n💾 {len(blocks)} 个 .mmd 源文件已保存")
PYEOF

    export RD_MD_FILE="$MD_FILE"
    export RD_IMG_DIR="$IMG_DIR"
    python3 "$EXTRACT_PY"
    rm -f "$EXTRACT_PY"

    MMD_FILES=("$IMG_DIR"/mermaid-*.mmd)
    MMD_COUNT=0
    for f in "${MMD_FILES[@]}"; do
        [ -f "$f" ] && MMD_COUNT=$((MMD_COUNT+1))
    done

    if [ "$MMD_COUNT" -eq 0 ]; then
        echo "✅ 无 Mermaid 代码块，跳过"
        exit 0
    fi

    # Step 2: 渲染 .mmd → .png
    echo ""
    echo "🎨 Step 2: 渲染 Mermaid → PNG..."

    SUCCESS=0
    FAIL=0
    for f in "$IMG_DIR"/mermaid-*.mmd; do
        [ ! -f "$f" ] && continue
        png="${f%.mmd}.png"
        if mmdc -i "$f" -o "$png" -w 1920 -H 1080 -b white 2>/tmp/_mmdc_err.log; then
            echo "  ✓ $(basename "$png")"
            SUCCESS=$((SUCCESS+1))
        else
            echo "  ✗ $(basename "$f"): $(head -1 /tmp/_mmdc_err.log 2>/dev/null)"
            FAIL=$((FAIL+1))
        fi
    done

    echo "  📊 $SUCCESS 成功, $FAIL 失败"

    # Step 3: 替换 MD 中的代码块
    echo ""
    echo "🔄 Step 3: 替换代码块为图片引用..."

    REPLACE_PY=$(mktemp /tmp/_render_diag_replace.XXXXXX.py)
    cat > "$REPLACE_PY" << 'PYEOF'
import re, os

md_file = os.environ['RD_MD_FILE']

with open(md_file, 'r') as f:
    content = f.read()

pattern = re.compile(r'```mermaid\n(.*?)\n```', re.DOTALL)

idx = 0
def replace(match):
    global idx
    idx += 1
    block = match.group(1)
    first_line = block.strip().split('\n')[0].strip().lower()
    if 'flowchart' in first_line or 'graph' in first_line: p = 'flowchart'
    elif 'sequencediagram' in block[:80]: p = 'sequence'
    elif 'classdiagram' in block[:80]: p = 'class'
    elif 'statediagram' in block[:80]: p = 'state'
    elif 'erdiagram' in block[:80]: p = 'er'
    else: p = 'mermaid'
    return f'![Mermaid {p} diagram](images/mermaid-{p}-{idx:02d}.png)'

new_content = pattern.sub(replace, content)

with open(md_file, 'w') as f:
    f.write(new_content)

print(f"✅ 已替换 {idx} 个代码块为图片引用")
PYEOF

    export RD_MD_FILE="$MD_FILE"
    python3 "$REPLACE_PY"
    rm -f "$REPLACE_PY"

# ============================================================
#  Fireworks 模式
# ============================================================
elif [ "$MODE" = "fireworks" ]; then
    if ! command -v rsvg-convert &> /dev/null; then
        echo "❌ 未找到 rsvg-convert，请先安装:"
        echo "   macOS: brew install librsvg"
        echo "   Linux: sudo apt install librsvg2-bin"
        exit 1
    fi

    # Step 1: 渲染 images/ 下所有 SVG → PNG
    echo "🎨 Step 1: 渲染 SVG → PNG..."

    SVG_COUNT=0
    SUCCESS=0
    FAIL=0

    for svg in "$IMG_DIR"/*.svg; do
        [ ! -f "$svg" ] && continue
        SVG_COUNT=$((SVG_COUNT+1))
        png="${svg%.svg}.png"
        if rsvg-convert -w 1920 "$svg" -o "$png" 2>/dev/null; then
            echo "  ✓ $(basename "$png")"
            SUCCESS=$((SUCCESS+1))
        else
            echo "  ✗ $(basename "$svg") 渲染失败"
            FAIL=$((FAIL+1))
        fi
    done

    if [ "$SVG_COUNT" -eq 0 ]; then
        echo "ℹ️  images/ 目录下未找到 SVG 文件"
        echo "   提示：fireworks 模式下，AI 应先使用 fireworks-tech-graph 技能"
        echo "   生成 SVG 到 images/ 目录，再运行此脚本"
        exit 0
    fi

    echo "  📊 $SUCCESS 成功, $FAIL 失败"

    # Step 2: 替换 MD 中的 mermaid 代码块为 PNG 引用
    #   （fireworks 模式下，AI 已将 mermaid 替换为 SVG，
    #     但可能仍有残留的 mermaid 代码块或 SVG 代码块）
    echo ""
    echo "🔄 Step 2: 替换 MD 中的图表代码块..."

    REPLACE_PY=$(mktemp /tmp/_render_diag_fw.XXXXXX.py)
    cat > "$REPLACE_PY" << 'PYEOF'
import re, os, glob

md_file = os.environ['RD_MD_FILE']
img_dir = os.environ['RD_IMG_DIR']

with open(md_file, 'r') as f:
    content = f.read()

replaced = 0

# 1. 替换残留的 ```mermaid 代码块
mermaid_pattern = re.compile(r'```mermaid\n.*?\n```', re.DOTALL)

# 收集 images/ 下的 PNG 文件名
png_files = sorted(glob.glob(os.path.join(img_dir, '*.png')))
png_idx = 0

def get_png_name():
    global png_idx
    if png_idx < len(png_files):
        name = os.path.basename(png_files[png_idx])
        png_idx += 1
        return name
    return None

def replace_mermaid(match):
    global replaced
    png = get_png_name()
    if png:
        replaced += 1
        return f'![Diagram](images/{png})'
    return match.group(0)

content = mermaid_pattern.sub(replace_mermaid, content)

# 2. 替换 ```svg 代码块
svg_pattern = re.compile(r'```svg\n.*?\n```', re.DOTALL)

def replace_svg(match):
    global replaced
    png = get_png_name()
    if png:
        replaced += 1
        return f'![Diagram](images/{png})'
    return match.group(0)

content = svg_pattern.sub(replace_svg, content)

with open(md_file, 'w') as f:
    f.write(content)

print(f"✅ 已替换 {replaced} 个代码块为图片引用")
PYEOF

    export RD_MD_FILE="$MD_FILE"
    export RD_IMG_DIR="$IMG_DIR"
    python3 "$REPLACE_PY"
    rm -f "$REPLACE_PY"

else
    echo "❌ 未知模式: $MODE (支持: mermaid, fireworks)"
    exit 1
fi

echo ""
echo "✅ 全部完成！"
echo ""
echo "📋 产物:"
echo "  · $IMG_DIR/  (PNG 图片)"
echo "  · $MD_FILE   (代码块→图片引用)"
