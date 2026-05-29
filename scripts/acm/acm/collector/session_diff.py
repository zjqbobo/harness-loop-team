"""Phase 3 session diff — 行级拆分 AI/人工代码

commit 被标记为 AI 参与后，读取 session JSONL 中匹配文件的 Edit/Write 事件，
与 commit diff 做行级比对，区分同 commit 内 AI 写的新增行和人工写的新增行。
"""
import json
import os
import difflib
from pathlib import Path
from typing import Dict, List, Optional, Set


def _find_session_dir(repo_path: str) -> Optional[Path]:
    """根据仓库路径查找对应的 session 目录"""
    projects = Path.home() / ".claude" / "projects"
    if not projects.exists():
        return None

    repo = Path(repo_path).resolve()
    # session 目录命名规则: /Users/.../repo-name → ~/.claude/projects/-Users-...-repo-name
    repo_str = str(repo)
    # 查找包含仓库路径子串的目录
    for proj_dir in projects.iterdir():
        if not proj_dir.is_dir():
            continue
        dirname = proj_dir.name
        # 检查是否匹配: -Users-gl001529-IdeaProjects-acm → /Users/gl001529/IdeaProjects/acm
        expected = dirname.replace("-", "/")
        if expected in repo_str or repo_str.endswith(expected) or repo_str in expected:
            return proj_dir
    return None


def extract_ai_edits(session_dir: Path, changed_files: Set[str], time_window: int = 300) -> Dict[str, List[dict]]:
    """从 session JSONL 中提取与变更文件相关的 AI Edit/Write 事件

    Args:
        session_dir: session JSONL 所在目录
        changed_files: 本次 commit 变更的文件路径集合
        time_window: 时间窗口（秒），只扫描最近 N 秒内有活动的 session

    Returns:
        {file_path: [{"old": str, "new": str}, ...]}  按文件分组的所有 AI 编辑
    """
    import time as _time

    cutoff = _time.time() - time_window
    all_sessions = []
    for sf in session_dir.glob("*.jsonl"):
        try:
            all_sessions.append((sf.stat().st_mtime, sf))
        except OSError:
            continue
    all_sessions.sort(reverse=True)

    result: Dict[str, List[dict]] = {}

    for mtime, session_file in all_sessions:
        if mtime < cutoff:
            break

        try:
            with open(session_file) as f:
                for line in f:
                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    msg = event.get("message")
                    if not msg or msg.get("role") != "assistant":
                        continue

                    for item in msg.get("content", []):
                        inp = item.get("input", {})
                        fp = inp.get("file_path", "")

                        # 模糊匹配: commit 中 src/main/foo.java 匹配 session 中 /abs/path/src/main/foo.java
                        matched = False
                        for cf in changed_files:
                            if cf and (cf in fp or fp.endswith(cf) or fp.endswith("/" + cf)):
                                matched = True
                                break
                        if not matched:
                            continue

                        if "old_string" in inp:
                            result.setdefault(fp, []).append({
                                "old": inp["old_string"],
                                "new": inp["new_string"],
                            })
                        elif "content" in inp:
                            result.setdefault(fp, []).append({
                                "old": "",   # Write 视为全量替换
                                "new": inp["content"],
                            })
        except Exception:
            continue

    return result


def apply_edits_to_content(edits: List[dict], original: str = "") -> str:
    """将一组 Edit 操作应用到文本上，得到 AI 编辑后的版本

    按顺序应用 edits，每个 edit 替换第一个匹配的 old_string
    """
    result = original
    for edit in edits:
        old = edit["old"]
        new = edit["new"]
        if old:
            # 精确替换第一个匹配位置
            idx = result.find(old)
            if idx >= 0:
                result = result[:idx] + new + result[idx + len(old):]
            else:
                # fuzzy: 如果精确匹配失败，追加 new 到末尾
                result += "\n" + new
        else:
            # Write: 整个文件内容被替换
            result = new
    return result


def classify_lines_by_session(
    commit_old_content: str,
    commit_new_content: str,
    ai_edits: List[dict],
) -> dict:
    """对 commit diff 中的新增行做 AI/人工分类

    算法:
    1. 从 commit_old_content 出发，仅应用 AI edits，得到 "ai_only" 版本
    2. 对 commit_old → commit_new 做 diff，提取新增行块
    3. 对 commit_old → ai_only 做 diff，提取 AI 新增行块
    4. commit 新增行 ∩ ai_only 新增行 = AI 行; 其余新增行 = 人工行

    Returns:
        {"ai_added": int, "human_added": int, "ai_changed_lines": set, "human_changed_lines": set}
    """
    if not ai_edits:
        return {"ai_added": 0, "human_added": 0}

    # 重建 AI-only 版本
    ai_only = apply_edits_to_content(ai_edits, commit_old_content)

    old_lines = commit_old_content.splitlines(keepends=True)
    new_lines = commit_new_content.splitlines(keepends=True)
    ai_only_lines = ai_only.splitlines(keepends=True)

    # 从 old → new 提取新增行（commit 的实际变更）
    commit_added_blocks = _get_added_blocks(old_lines, new_lines)

    # 从 old → ai_only 提取新增行（AI session 的变更）
    ai_added_blocks = _get_added_blocks(old_lines, ai_only_lines)

    # 交集: commit 新增行中有多少来自 AI
    # 行级比对: 对每个 commit 新增行，检查是否在 AI-only 版本中
    ai_new_lines = set(ai_only.splitlines())
    old_line_set = set(commit_old_content.splitlines())
    commit_new_line_list = commit_new_content.splitlines()

    ai_added = 0
    for new_line in commit_new_line_list:
        if new_line not in old_line_set:
            if new_line in ai_new_lines:
                ai_added += 1

    total_added = sum(1 for nl in commit_new_line_list if nl not in old_line_set)
    human_added = total_added - ai_added

    return {"ai_added": ai_added, "human_added": human_added}


def _get_added_blocks(old_lines: list, new_lines: list) -> List[str]:
    """从两个文本版本中提取新增的行块（insert + replace 中的 new 部分）"""
    matcher = difflib.SequenceMatcher(None, old_lines, new_lines)
    blocks = []
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag in ("insert", "replace"):
            block = "".join(new_lines[j1:j2])
            blocks.append(block)
    return blocks


def compute_file_line_attribution(
    repo_path: str,
    file_path: str,
    commit_old: str,
    commit_new: str,
    ai_edits: List[dict],
) -> dict:
    """对单个文件计算 AI/人工新增行归属

    Args:
        repo_path: 仓库路径
        file_path: 文件在仓库中的相对路径
        commit_old: 文件在 commit 前的内容
        commit_new: 文件在 commit 后的内容
        ai_edits: 该文件的 AI Edit 事件列表

    Returns:
        {"ai_lines_added": int, "human_lines_added": int}
    """
    classification = classify_lines_by_session(commit_old, commit_new, ai_edits)
    return {
        "file_path": file_path,
        "ai_lines_added": classification["ai_added"],
        "human_lines_added": classification["human_added"],
    }
