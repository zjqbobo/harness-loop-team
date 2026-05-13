#!/bin/bash
# ===========================================
# Harness 通用脚本：Mermaid 代码块 → PNG 图片
# 功能：
#   1. 提取 Markdown 中所有 ```mermaid 代码块
#   2. 保存为 .mmd 源文件到 images/ 目录
#   3. 渲染为 PNG 图片
#   4. 替换 Markdown 中的代码块为图片引用
# 依赖：mmdc (@mermaid-js/mermaid-cli) + Chrome
# ===========================================
set -e

if [ $# -lt 1 ]; then
    echo "用法: mermaid-render.sh <md文件路径>"
    echo "示例: mermaid-render.sh ./方案.md"
    exit 1
fi

MD_FILE=$(realpath "$1")
MD_DIR=$(dirname "$MD_FILE")
IMG_DIR="$MD_DIR/images"
MD_BASENAME=$(basename "$MD_FILE")

if [ ! -f "$MD_FILE" ]; then
    echo "❌ 文件不存在: $MD_FILE"
    exit 1
fi

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

mkdir -p "$IMG_DIR"

echo "📝 文件: $MD_BASENAME"
echo "📁 输出: $IMG_DIR"

# ========== Step 1: 提取并保存 .mmd ==========
echo ""
echo "🔍 Step 1: 提取 Mermaid 代码块..."

EXTRACT_PY=$(mktemp /tmp/_mermaid_extract.XXXXXX.py)
cat > "$EXTRACT_PY" << 'PYEOF'
import re, os, sys

md_file = os.environ['MERMAID_MD_FILE']
img_dir = os.environ['MERMAID_IMG_DIR']

with open(md_file, 'r') as f:
    content = f.read()

pattern = re.compile(r'```mermaid\n(.*?)\n```', re.DOTALL)
blocks = pattern.findall(content)

if not blocks:
    print("ℹ️  未找到 Mermaid 代码块")
    sys.exit(0)

print(f"找到 {len(blocks)} 个 Mermaid 代码块")

def get_type(code):
    first = code.strip().split('\n')[0].strip().lower()
    for kw in ['flowchart', 'classdiagram', 'sequencediagram', 'statediagram', 'erdiagram']:
        if kw in first:
            return kw.replace('diagram', '').replace('class', 'class').replace('flowchart', 'flowchart').replace('sequence', 'sequence').replace('state', 'state').replace('er', 'er')
    if 'classDiagram' in code[:50]: return 'class'
    if 'stateDiagram' in code[:50]: return 'state'
    if 'flowchart' in first: return 'flowchart'
    if 'sequenceDiagram' in code[:50]: return 'sequence'
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

export MERMAID_MD_FILE="$MD_FILE"
export MERMAID_IMG_DIR="$IMG_DIR"
python3 "$EXTRACT_PY"
rm -f "$EXTRACT_PY"

# Check if any .mmd were created
MMD_FILES=("$IMG_DIR"/mermaid-*.mmd)
MMD_COUNT=0
for f in "${MMD_FILES[@]}"; do
    [ -f "$f" ] && MMD_COUNT=$((MMD_COUNT+1))
done

if [ "$MMD_COUNT" -eq 0 ]; then
    echo "✅ 无 Mermaid 代码块，跳过后续步骤"
    exit 0
fi

# ========== Step 2: 渲染 .mmd → .png ==========
echo ""
echo "🎨 Step 2: 渲染 Mermaid → PNG..."

SUCCESS=0
FAIL=0
for f in "$IMG_DIR"/mermaid-*.mmd; do
    [ ! -f "$f" ] && continue
    png="${f%.mmd}.png"
    bname=$(basename "$f")
    if mmdc -i "$f" -o "$png" -w 1920 -H 1080 -b white 2>/tmp/_mmdc_err.log; then
        echo "  ✓ $(basename $png)"
        SUCCESS=$((SUCCESS+1))
    else
        echo "  ✗ $bname: $(head -1 /tmp/_mmdc_err.log 2>/dev/null)"
        FAIL=$((FAIL+1))
    fi
done

echo "  📊 $SUCCESS 成功, $FAIL 失败"

# ========== Step 3: 替换 MD 中的代码块 ==========
echo ""
echo "🔄 Step 3: 替换代码块为图片引用..."

REPLACE_PY=$(mktemp /tmp/_mermaid_replace.XXXXXX.py)
cat > "$REPLACE_PY" << 'PYEOF'
import re, os

md_file = os.environ['MERMAID_MD_FILE']

with open(md_file, 'r') as f:
    content = f.read()

pattern = re.compile(r'```mermaid\n(.*?)\n```', re.DOTALL)

idx = 0
def replace(match):
    global idx
    idx += 1
    block = match.group(1)
    first = block.strip().split('\n')[0].strip().lower()
    if 'flowchart' in first: p = 'flowchart'
    elif 'classdiagram' in first: p = 'class'
    elif 'statediagram' in first: p = 'state'
    elif 'sequencediagram' in first: p = 'sequence'
    else: p = 'mermaid'
    return f'![Mermaid {p} diagram](images/mermaid-{p}-{idx:02d}.png)'

new_content = pattern.sub(replace, content)

with open(md_file, 'w') as f:
    f.write(new_content)

print(f"✅ 已替换 {idx} 个代码块为图片引用")
PYEOF

export MERMAID_MD_FILE="$MD_FILE"
python3 "$REPLACE_PY"
rm -f "$REPLACE_PY"

echo ""
echo "✅ 全部完成！"
echo ""
echo "📋 产物:"
echo "  · $IMG_DIR/mermaid-*.mmd  (${MMD_COUNT} 个源文件)"
echo "  · $IMG_DIR/mermaid-*.png  (${SUCCESS} 个PNG)"
echo "  · $MD_FILE               (代码块→图片引用)"
