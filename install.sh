#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Harness Engineering — 一键安装脚本
# GitHub: https://github.com/<org>/harness-engineering
#
# 用法:
#   git clone https://github.com/<org>/harness-engineering.git ~/.claude/harness
#   cd ~/.claude/harness && ./install.sh
#
# 做了什么:
#   1. 将 02-skills-source/ 中的 skill 通过 symlink 注册到 ~/.claude/skills/
#   2. 将 CLAUDE.md symlink 到 ~/.claude/CLAUDE.md
#   3. 验证安装完整性
#
# 卸载:
#   删除 ~/.claude/skills/harness-* 的 symlink 即可
# ============================================

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Harness Engineering — 安装中...         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 0. 依赖检查 ──────────────────────────────────────

echo -e "${CYAN}🔍 检查依赖...${NC}"
echo ""

missing_critical=0
missing_recommended=0

check_cmd() {
    local cmd="$1" label="$2" level="$3" hint="$4"
    if command -v "$cmd" &>/dev/null; then
        local ver="$($cmd --version 2>/dev/null | head -1 | tr '\n' ' ')"
        echo -e "   ${GREEN}✅${NC} ${label}: ${ver}"
        return 0
    else
        echo -e "   ${RED}❌${NC} ${label}: 未安装  →  ${hint}"
        if [ "$level" = "critical" ]; then
            missing_critical=$((missing_critical + 1))
        elif [ "$level" = "recommended" ]; then
            missing_recommended=$((missing_recommended + 1))
        fi
        return 1
    fi
}

check_npm() {
    local pkg="$1" label="$2" level="$3" hint="$4"
    if npm list -g "$pkg" --depth=0 2>/dev/null | grep -q "$pkg"; then
        local ver="$(npm list -g "$pkg" --depth=0 2>/dev/null | grep "$pkg" | sed 's/.*@//')"
        echo -e "   ${GREEN}✅${NC} ${label}: ${ver}"
        return 0
    else
        echo -e "   ${RED}❌${NC} ${label}: 未安装  →  ${hint}"
        if [ "$level" = "critical" ]; then
            missing_critical=$((missing_critical + 1))
        elif [ "$level" = "recommended" ]; then
            missing_recommended=$((missing_recommended + 1))
        fi
        return 1
    fi
}

# 系统命令
echo -e "   ${CYAN}[必装] 核心工具链${NC}"
check_cmd git          "git"              critical "brew install git"
check_cmd node         "Node.js"           critical "brew install node@22"
check_cmd npx          "npx"               critical "自带于 Node.js"
check_cmd pandoc       "pandoc"            critical "brew install pandoc"
check_cmd rsvg-convert "rsvg-convert"     critical "brew install librsvg"
check_cmd python3      "Python 3"          critical "系统自带或 brew install python@3"

echo ""

# npm 全局包
echo -e "   ${CYAN}[必装] npm 全局包${NC}"
check_npm "@anthropic-ai/claude-code"  "Claude Code CLI"    critical "npm install -g @anthropic-ai/claude-code"
check_npm "@mermaid-js/mermaid-cli"    "mermaid-cli (mmdc)" critical "npm install -g @mermaid-js/mermaid-cli"

echo ""

# 推荐依赖
echo -e "   ${YELLOW}[推荐] E2E 测试${NC}"
echo -e "   ℹ️  Playwright 检测方式: npx playwright --version"
if npx playwright --version &>/dev/null 2>&1; then
    echo -e "   ${GREEN}✅${NC} Playwright: $(npx playwright --version 2>/dev/null)"
else
    echo -e "   ${RED}❌${NC} Playwright: 未安装  →  npx playwright install chromium"
    missing_recommended=$((missing_recommended + 1))
fi

echo ""

echo -e "   ${YELLOW}[可选] 增强工具${NC}"
check_npm "agent-browser" "agent-browser" optional "npm install -g agent-browser && agent-browser install"

echo ""

# 汇总
if [ "$missing_critical" -gt 0 ] || [ "$missing_recommended" -gt 0 ]; then
    echo -e "${YELLOW}╔══════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  依赖检查未通过                        ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════╣${NC}"
    if [ "$missing_critical" -gt 0 ]; then
        echo -e "${YELLOW}║  🔴 必装缺失 ${missing_critical} 项 — 请先安装再继续         ║${NC}"
    fi
    if [ "$missing_recommended" -gt 0 ]; then
        echo -e "${YELLOW}║  🟡 推荐缺失 ${missing_recommended} 项 — 部分功能不可用      ║${NC}"
    fi
    echo -e "${YELLOW}╚══════════════════════════════════════════╝${NC}"
    echo ""
    if [ "$missing_critical" -gt 0 ]; then
        echo -e "${RED}必装依赖缺失，终止安装。请按上方提示安装后重试。${NC}"
        exit 1
    fi
    echo -e "${CYAN}推荐依赖缺失不影响核心功能，继续安装...${NC}"
else
    echo -e "${GREEN}✅ 所有依赖检查通过${NC}"
fi

echo ""

# ── 1. 注册 skills ──────────────────────────────────────

echo -e "${CYAN}📦 注册自然语言触发 skills...${NC}"
mkdir -p "${SKILLS_DIR}"

skill_count=0
for skill_dir in "${HARNESS_DIR}/02-skills-source/"*/; do
    skill_name="$(basename "${skill_dir}")"
    target="${SKILLS_DIR}/${skill_name}"

    if [ -L "${target}" ]; then
        current_link="$(readlink "${target}")"
        if [ "${current_link}" = "${skill_dir}" ]; then
            echo -e "   ${GREEN}⏭${NC}  ${skill_name}（已安装，跳过）"
            skill_count=$((skill_count + 1))
            continue
        else
            echo -e "   ${YELLOW}⚠${NC}   ${skill_name} 指向旧路径，更新..."
            rm -f "${target}"
        fi
    elif [ -d "${target}" ]; then
        echo -e "   ${YELLOW}⚠${NC}   ${skill_name} 已存在（非 symlink），备份后覆盖..."
        mv "${target}" "${target}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    ln -s "${skill_dir}" "${target}"
    echo -e "   ${GREEN}✅${NC} ${skill_name}"
    skill_count=$((skill_count + 1))
done

# ── 2. 安装 CLAUDE.md ──────────────────────────────────────

echo ""
echo -e "${CYAN}📋 安装全局 CLAUDE.md...${NC}"

CLAUDE_MD_SRC="${HARNESS_DIR}/CLAUDE.md"
CLAUDE_MD_DST="${HOME}/.claude/CLAUDE.md"

if [ -f "${CLAUDE_MD_DST}" ] && [ ! -L "${CLAUDE_MD_DST}" ]; then
    backup="${CLAUDE_MD_DST}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${CLAUDE_MD_DST}" "${backup}"
    echo -e "   ${YELLOW}⚠${NC}   已有 CLAUDE.md 备份为 ${backup}"
fi

ln -sf "${CLAUDE_MD_SRC}" "${CLAUDE_MD_DST}"
echo -e "   ${GREEN}✅${NC} CLAUDE.md → ${CLAUDE_MD_SRC}"

# ── 3. 验证 ──────────────────────────────────────

echo ""
echo -e "${CYAN}🔍 验证安装...${NC}"

# 统计注册的 harness skill
registered_count=$(find -L "${SKILLS_DIR}" -path '*/harness-*/SKILL.md' -maxdepth 3 | wc -l | tr -d ' ')
echo -e "   Harness skills 注册: ${registered_count} 个"

# 验证 CLAUDE.md
if [ -f "${CLAUDE_MD_DST}" ]; then
    echo -e "   ${GREEN}✅${NC} CLAUDE.md"
else
    echo -e "   ${RED}❌${NC} CLAUDE.md 安装失败"
fi

# 验证 harness 目录
if [ -d "${HARNESS_DIR}" ]; then
    echo -e "   ${GREEN}✅${NC} Harness 目录"
else
    echo -e "   ${RED}❌${NC} Harness 目录不存在"
fi

# 验证模板
if [ -d "${HARNESS_DIR}/09-templates" ]; then
    echo -e "   ${GREEN}✅${NC} 文档模板"
else
    echo -e "   ${RED}❌${NC} 文档模板不存在"
fi

# 验证脚本
if [ -f "${HARNESS_DIR}/scripts/doc/md2docx.sh" ]; then
    echo -e "   ${GREEN}✅${NC} 工具脚本"
else
    echo -e "   ${RED}❌${NC} 工具脚本不存在"
fi

# ── 4. 完成 ──────────────────────────────────────

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Harness Engineering 安装完成         ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  现在你可以用自然语言触发所有能力：          ║${NC}"
echo -e "${GREEN}║  • \"帮我设计...\" → brainstorming          ║${NC}"
echo -e "${GREEN}║  • \"帮我写方案...\" → 文档生成全流程         ║${NC}"
echo -e "${GREEN}║  • \"帮我修bug...\" → 系统调试               ║${NC}"
echo -e "${GREEN}║  • \"帮我review...\" → 代码审查              ║${NC}"
echo -e "${GREEN}║  • \"帮我实现...\" → TDD + 编码规范          ║${NC}"
echo -e "${GREEN}║  • \"帮我写测试...\" → 单测 + E2E             ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  更新: cd ~/.claude/harness && git pull    ║${NC}"
echo -e "${GREEN}║  卸载: rm ~/.claude/skills/harness-*       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
