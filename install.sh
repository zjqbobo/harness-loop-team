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
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║  更新: cd ~/.claude/harness && git pull    ║${NC}"
echo -e "${GREEN}║  卸载: rm ~/.claude/skills/harness-*       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
