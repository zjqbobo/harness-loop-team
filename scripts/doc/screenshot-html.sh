#!/bin/bash
# Harness 标准截图脚本 — 自适应查找 headless 浏览器
# 查找优先级: Playwright Chromium → Puppeteer Chromium → 系统 Chrome
# 用法: ./screenshot-html.sh <html文件> [输出PNG] [视口宽度] [视口高度]

set -e

HTML="${1:?Usage: ./screenshot-html.sh <html-file> [output.png] [width] [height]}"
OUTPUT="${2:-$(basename "$HTML" .html).png}"
WIDTH="${3:-375}"
HEIGHT="${4:-2000}"

# ---- 自适应查找 headless 浏览器 ----
find_browser() {
  local pw pw_path pup pup_path sys_chrome

  # 1. Playwright Chromium
  pw_path="$HOME/Library/Caches/ms-playwright"
  if [ -d "$pw_path" ]; then
    pw="$(find "$pw_path" -name "chrome-headless-shell" -type f 2>/dev/null | sort -V | tail -1)"
    [ -n "$pw" ] && echo "$pw" && return 0
  fi

  # 2. Puppeteer Chromium
  pup_path="$HOME/.cache/puppeteer"
  if [ -d "$pup_path" ]; then
    pup="$(find "$pup_path" -name "chrome-headless-shell" -type f 2>/dev/null | sort -V | tail -1)"
    [ -n "$pup" ] && echo "$pup" && return 0
  fi

  # 3. 系统 Google Chrome
  sys_chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  if [ -f "$sys_chrome" ]; then
    echo "$sys_chrome" && return 0
  fi
  sys_chrome="$(which google-chrome 2>/dev/null || which google-chrome-stable 2>/dev/null)"
  if [ -n "$sys_chrome" ]; then
    echo "$sys_chrome" && return 0
  fi

  return 1
}

BROWSER="$(find_browser)"
if [ -z "$BROWSER" ]; then
  echo "❌ 未找到可用 headless 浏览器，请执行以下任一操作："
  echo "   1. npx playwright install chromium"
  echo "   2. npm install puppeteer"
  echo "   3. 安装 Google Chrome"
  exit 1
fi
echo "🔍 使用浏览器: $BROWSER"

# ---- 启动 HTTP 服务器 ----
HTML_DIR="$(cd "$(dirname "$HTML")" && pwd)"
HTML_NAME="$(basename "$HTML")"

PORT=8765
while lsof -i ":$PORT" &>/dev/null; do PORT=$((PORT+1)); done

python3 -m http.server "$PORT" --directory "$HTML_DIR" &
SERVER_PID=$!
sleep 1
trap "kill $SERVER_PID 2>/dev/null" EXIT

# ---- 截图 ----
"$BROWSER" --headless=new --disable-gpu \
  --window-size="$WIDTH,$HEIGHT" \
  --screenshot="$OUTPUT" \
  "http://localhost:$PORT/$HTML_NAME" 2>/dev/null

if [ -f "$OUTPUT" ]; then
  SIZE="$(python3 -c "from PIL import Image; img=Image.open('$OUTPUT'); print(f'{img.size[0]}x{img.size[1]}')" 2>/dev/null)"
  echo "✅ $OUTPUT ${SIZE:+($SIZE)}"
else
  echo "❌ 截图失败"
  exit 1
fi
