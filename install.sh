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

# OS 检测
case "$(uname -s)" in
    Linux)  OS="linux";  PKG="apt install";  PKG_RSVG="apt install librsvg2-bin" ;;
    Darwin) OS="macos";  PKG="brew install";  PKG_RSVG="brew install librsvg" ;;
    *)      OS="unknown"; PKG="(请用系统包管理器安装)"; PKG_RSVG="(请用系统包管理器安装 librsvg)" ;;
esac
echo -e "   ℹ️  检测系统: ${OS}"

# 系统命令
echo ""
echo -e "   ${CYAN}[必装] 核心工具链${NC}"
check_cmd git          "git"              critical "${PKG} git"
check_cmd node         "Node.js"           critical "${PKG} nodejs 或 brew install node@22"
check_cmd npx          "npx"               critical "自带于 Node.js"
check_cmd pandoc       "pandoc"            critical "${PKG} pandoc"
check_cmd rsvg-convert "rsvg-convert"     critical "${PKG_RSVG}"
check_cmd python3      "Python 3"          critical "系统自带或 ${PKG} python3"

echo ""

# npm 全局包
echo -e "   ${CYAN}[必装] npm 全局包${NC}"
check_npm "@anthropic-ai/claude-code"  "Claude Code CLI"    critical "npm install -g @anthropic-ai/claude-code"
check_npm "@mermaid-js/mermaid-cli"    "mermaid-cli (mmdc)" critical "npm install -g @mermaid-js/mermaid-cli"

echo ""

# 推荐依赖
echo -e "   ${YELLOW}[推荐] E2E 测试${NC}"
echo -e "   ℹ️  Playwright 检测方式: 检查浏览器二进制 + npm list"
if [ -d "${HOME}/Library/Caches/ms-playwright" ] || [ -d "${HOME}/.cache/ms-playwright" ]; then
    echo -e "   ${GREEN}✅${NC} Playwright 浏览器: 已安装"
    installed_browsers=$(ls ~/Library/Caches/ms-playwright/ 2>/dev/null | tr '\n' ' ' || ls ~/.cache/ms-playwright/ 2>/dev/null | tr '\n' ' ')
    echo -e "   ℹ️  浏览器: ${installed_browsers}"
elif npm list -g playwright --depth=0 2>/dev/null | grep -q playwright; then
    echo -e "   ${YELLOW}⚠${NC}  Playwright 已安装但浏览器未安装 → npx playwright install chromium"
    missing_recommended=$((missing_recommended + 1))
else
    echo -e "   ${RED}❌${NC} Playwright: 未安装  →  npm install -g playwright && npx playwright install chromium"
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

# ── 3. 安装 ACM Agent ──────────────────────────────────────

echo ""
echo -e "${CYAN}📊 安装 ACM Agent (AI 编程效能指标采集)...${NC}"

# ── 读取 ACM 服务端地址 ──
ACM_CONFIG_FILE="${HOME}/.acm/config"
if [ -f "${ACM_CONFIG_FILE}" ]; then
    ACM_SERVER_URL=$(grep '^ACM_SERVER_URL=' "${ACM_CONFIG_FILE}" | cut -d'=' -f2-)
fi
if [ -z "${ACM_SERVER_URL:-}" ]; then
    read -p "   ACM 服务端地址 (默认: http://localhost:8080): " ACM_SERVER_URL
    ACM_SERVER_URL="${ACM_SERVER_URL:-http://localhost:8080}"
    mkdir -p "$(dirname "${ACM_CONFIG_FILE}")"
    echo "ACM_SERVER_URL=${ACM_SERVER_URL}" > "${ACM_CONFIG_FILE}"
fi
echo -e "   ${GREEN}✅${NC} ACM Server: ${ACM_SERVER_URL}"

ACM_DIR="${HARNESS_DIR}/scripts/acm"
ACM_HOOKS_SRC="${ACM_DIR}/hooks"
ACM_PENDING_DIR="${HOME}/.acm/pending"
ACM_BLAME_DIR="${HOME}/.acm/blame"
ACM_GLOBAL_HOOKS="${HOME}/.acm/hooks"
ACM_TEMPLATE_DIR="${HOME}/.claude/harness/scripts/acm/git-template"
ACM_TEMPLATE_HOOKS="${ACM_TEMPLATE_DIR}/hooks"

if [ -f "${ACM_HOOKS_SRC}/post-commit" ]; then
    echo -e "   ${GREEN}✅${NC} ACM hook 源文件: ${ACM_HOOKS_SRC}"
else
    echo -e "   ${RED}❌${NC} ACM hook 源文件缺失: ${ACM_HOOKS_SRC}"
fi

# 安装 Python agent（隔离 venv，不写系统 Python）
echo -e "   ${CYAN}🐍 安装 ACM Python 环境...${NC}"
ACM_VENV="${HOME}/.acm/venv"
if [ ! -x "${ACM_VENV}/bin/python" ]; then
    if python3 -m venv "${ACM_VENV}" 2>&1; then
        "${ACM_VENV}/bin/pip" install --quiet --upgrade pip 2>&1 || true
        "${ACM_VENV}/bin/pip" install --quiet "requests>=2.28" 2>&1 || true
        echo -e "   ${GREEN}✅${NC} ACM venv: ${ACM_VENV}"
    else
        echo -e "   ${YELLOW}⚠${NC}  venv 创建失败（已有 Python 3 即可，不影响 skill 安装）"
    fi
else
    echo -e "   ${GREEN}✅${NC} ACM venv 已存在: ${ACM_VENV}"
fi
# 确保 post-commit hook 使用 venv 中的 Python
if [ -x "${ACM_VENV}/bin/python" ]; then
    echo "ACM_PYTHON=${ACM_VENV}/bin/python" > "${HOME}/.acm/env"
    echo -e "   ${GREEN}✅${NC} ACM_PYTHON 写入 ~/.acm/env"
fi

# 创建本地数据目录
mkdir -p "${ACM_PENDING_DIR}"
mkdir -p "${ACM_BLAME_DIR}"
echo -e "   ${GREEN}✅${NC} 数据目录: ~/.acm/"

# ── 安装 ACM hooks + Python 脚本到 ~/.acm/hooks/ ──
mkdir -p "${ACM_GLOBAL_HOOKS}"
cp "${ACM_HOOKS_SRC}/"* "${ACM_GLOBAL_HOOKS}/"
chmod +x "${ACM_GLOBAL_HOOKS}/"*
echo -e "   ${GREEN}✅${NC} ACM hooks: ${ACM_GLOBAL_HOOKS}/"

# ── Git init.templateDir（新 clone 仓库走模板）──
mkdir -p "${ACM_TEMPLATE_HOOKS}"
cp "${ACM_HOOKS_SRC}/"* "${ACM_TEMPLATE_HOOKS}/"
chmod +x "${ACM_TEMPLATE_HOOKS}/"*
git config --global init.templateDir "${ACM_TEMPLATE_DIR}"
echo -e "   ${GREEN}✅${NC} Git 模板目录: ${ACM_TEMPLATE_DIR}"

# ── 注入 ACM 到已有 hooksPath（保护原有 hook）──
EXISTING_HOOKSPATH=$(git config --global core.hooksPath 2>/dev/null || true)
if [ -n "${EXISTING_HOOKSPATH}" ]; then
    EXISTING_POSTCOMMIT="${EXISTING_HOOKSPATH/\~/${HOME}}/post-commit"
    if [ -f "${EXISTING_POSTCOMMIT}" ] && ! grep -q ".acm/hooks/post-commit" "${EXISTING_POSTCOMMIT}" 2>/dev/null; then
        # 在 exit 之前注入 ACM 调用
        if grep -q "^exit " "${EXISTING_POSTCOMMIT}"; then
            sed -i '' "/^exit /i\\
# ACM AI metrics collection\\
if [ -x \"\$HOME/.acm/hooks/post-commit\" ]; then\\
    \"\$HOME/.acm/hooks/post-commit\" \"\$@\" || true\\
fi
" "${EXISTING_POSTCOMMIT}"
        else
            echo "" >> "${EXISTING_POSTCOMMIT}"
            echo "# ACM AI metrics collection" >> "${EXISTING_POSTCOMMIT}"
            echo "if [ -x \"\$HOME/.acm/hooks/post-commit\" ]; then" >> "${EXISTING_POSTCOMMIT}"
            echo "    \"\$HOME/.acm/hooks/post-commit\" \"\$@\" || true" >> "${EXISTING_POSTCOMMIT}"
            echo "fi" >> "${EXISTING_POSTCOMMIT}"
        fi
        echo -e "   ${GREEN}✅${NC} ACM 已注入到现有 hooksPath: ${EXISTING_POSTCOMMIT}"
    elif [ -f "${EXISTING_POSTCOMMIT}" ]; then
        echo -e "   ${GREEN}✅${NC} ACM 已存在于: ${EXISTING_POSTCOMMIT}"
    fi
else
    git config --global core.hooksPath "${ACM_GLOBAL_HOOKS}"
    echo -e "   ${GREEN}✅${NC} core.hooksPath: ${ACM_GLOBAL_HOOKS}"
fi

echo -e "   ${GREEN}✅${NC} ACM Agent 安装完成，无需手动操作"

# ── 4. 创建公司级覆盖目录 ──────────────────────────────────────

OVERLAY_DIR="${HOME}/.claude/harness.local"
echo ""
echo -e "${CYAN}📁 创建公司级覆盖目录...${NC}"

mkdir -p "${OVERLAY_DIR}/09-templates"
mkdir -p "${OVERLAY_DIR}/docs"
mkdir -p "${OVERLAY_DIR}/01-rules"
mkdir -p "${OVERLAY_DIR}/scripts"

echo -e "   ${GREEN}✅${NC} ${OVERLAY_DIR}/09-templates/  — 放入你的自定义文档模板"
echo -e "   ${GREEN}✅${NC} ${OVERLAY_DIR}/docs/          — 放入你的业务知识库"
echo -e "   ${GREEN}✅${NC} ${OVERLAY_DIR}/01-rules/       — 覆盖/补充编码规范"
echo -e "   ${GREEN}✅${NC} ${OVERLAY_DIR}/scripts/        — 覆盖/补充工具脚本"
echo -e "   ℹ️  此目录与 harness 默认隔离，git pull 更新不冲突"

# ── 5. 验证 ──────────────────────────────────────

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

# 验证脚本（主入口 + 核心渲染）
if [ -f "${HARNESS_DIR}/scripts/doc/doc-pipeline.sh" ] && [ -f "${HARNESS_DIR}/scripts/doc/render-diagrams.sh" ]; then
    echo -e "   ${GREEN}✅${NC} 工具脚本（doc-pipeline + render-diagrams 等）"
elif [ -f "${HARNESS_DIR}/scripts/doc/md2docx.sh" ]; then
    echo -e "   ${GREEN}✅${NC} 工具脚本（基础）"
else
    echo -e "   ${RED}❌${NC} 工具脚本不存在"
fi

# 验证知识索引
if [ -f "${HARNESS_DIR}/00-harness-core/knowledge-index.yaml" ]; then
    echo -e "   ${GREEN}✅${NC} 知识索引"
else
    echo -e "   ${YELLOW}⚠${NC}  知识索引（knowledge-index.yaml）不存在"
fi

# 验证 ACM
if [ -f "${HARNESS_DIR}/scripts/acm/hooks/post-commit" ]; then
    echo -e "   ${GREEN}✅${NC} ACM Agent (AI 指标采集)"
else
    echo -e "   ${YELLOW}⚠${NC}  ACM Agent 缺失"
fi

# ── 6. 完成 ──────────────────────────────────────

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Harness Engineering 安装完成         ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  🎯 v2.0 新增：设计文档智能索引             ║${NC}"
echo -e "${GREEN}║  大文档按需加载，节省上下文消耗              ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  现在你可以用自然语言触发所有能力：          ║${NC}"
echo -e "${GREEN}║  • \"帮我设计...\" → brainstorming          ║${NC}"
echo -e "${GREEN}║  • \"审核方案...\" → design-review          ║${NC}"
echo -e "${GREEN}║  • \"帮我写方案...\" → 文档生成全流程         ║${NC}"
echo -e "${GREEN}║  • \"帮我修bug...\" → 系统调试               ║${NC}"
echo -e "${GREEN}║  • \"帮我review...\" → 代码审查              ║${NC}"
echo -e "${GREEN}║  • \"初始化项目规范...\" → harness-init       ║${NC}"
echo -e "${GREEN}║  • \"帮我实现...\" → TDD + 编码规范          ║${NC}"
echo -e "${GREEN}║  • \"拆任务/排期...\" → 项目管理(PMO)        ║${NC}"
echo -e "${GREEN}║  • \"帮我写测试...\" → 单测 + E2E             ║${NC}"
echo -e "${GREEN}║  • \"帮我做下压测...\" → 压力测试+性能报告    ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  📊 ACM Agent 已安装（自动生效）            ║${NC}"
echo -e "${GREEN}║  AI 指标采集已启用，无需手动操作              ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  更新: cd ~/.claude/harness && git pull    ║${NC}"
echo -e "${GREEN}║  定制: ~/.claude/harness.local/ 覆盖模板/知识库 ║${NC}"
echo -e "${GREEN}║  卸载: rm ~/.claude/skills/harness-*       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
