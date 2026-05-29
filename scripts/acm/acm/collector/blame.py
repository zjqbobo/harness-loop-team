"""Blame 采集器 — git blame 行级归属分析

支持两种模式：
- 增量 (incremental): commit 时对变更文件做 blame
- 全量 (full): 对整个仓库做 blame（用于初始快照）
"""
import subprocess
import re
from datetime import datetime
from typing import Set, List, Dict, Optional


def parse_blame_porcelain(porcelain_output: str) -> list:
    """解析 git blame --porcelain 输出，提取每行的 commit_hash 和行号"""
    lines = []
    current_hash = None

    for raw_line in porcelain_output.splitlines():
        header_match = re.match(r"^([0-9a-f]{7,40}) (\d+) (\d+)", raw_line)
        if header_match:
            current_hash = header_match.group(1)
        elif raw_line.startswith("\t") and current_hash:
            lines.append({"commit_hash": current_hash})
            current_hash = None

    return lines


def classify_lines(blame_lines: list, ai_commit_hashes: set) -> dict:
    """将 blame 行归类为 AI / 人工"""
    ai_lines = sum(1 for ln in blame_lines if ln["commit_hash"] in ai_commit_hashes)
    human_lines = len(blame_lines) - ai_lines
    return {
        "total_lines": len(blame_lines),
        "ai_lines": ai_lines,
        "human_lines": human_lines,
    }


def get_ai_commit_hashes(repo_path: str = ".") -> Set[str]:
    """获取仓库中所有 AI Co-Authored-By 的 commit hash"""
    try:
        output = subprocess.run(
            ["git", "log", "--all", "--format=%H%n%B%n---END---"],
            cwd=repo_path, capture_output=True, text=True, check=True,
        ).stdout
    except subprocess.CalledProcessError:
        return set()

    from acm.collector.commit import AI_TOOL_PATTERNS

    ai_hashes = set()
    for block in output.split("---END---"):
        block = block.strip()
        if not block:
            continue
        parts = block.splitlines()
        if not parts:
            continue
        commit_hash = parts[0].strip()
        body = "\n".join(parts[1:])
        if any(p.search(body) for p in AI_TOOL_PATTERNS.values()):
            ai_hashes.add(commit_hash)
    return ai_hashes


def blame_files(repo_path: str, file_paths: list, ai_hashes: set) -> List[dict]:
    """对指定文件列表执行 git blame，返回每个文件的归属统计"""
    records = []
    for fp in file_paths:
        try:
            output = subprocess.run(
                ["git", "blame", "--porcelain", fp],
                cwd=repo_path, capture_output=True, text=True, check=True,
            ).stdout
        except subprocess.CalledProcessError:
            continue

        lines = parse_blame_porcelain(output)
        classified = classify_lines(lines, ai_hashes)
        records.append({"file_path": fp, **classified})
    return records


def get_changed_files(repo_path: str) -> List[str]:
    """获取当前 commit 变更的文件列表"""
    try:
        output = subprocess.run(
            ["git", "diff", "--name-only", "HEAD~1", "HEAD"],
            cwd=repo_path, capture_output=True, text=True, check=True,
        ).stdout
    except subprocess.CalledProcessError:
        return []
    return [f.strip() for f in output.splitlines() if f.strip()]


def collect_incremental_blame(repo_path: str = ".") -> Optional[dict]:
    """增量 blame：对本次 commit 变更的文件做行级归属"""
    changed = get_changed_files(repo_path)
    if not changed:
        return None

    ai_hashes = get_ai_commit_hashes(repo_path)
    file_records = blame_files(repo_path, changed, ai_hashes)

    total_ai = sum(r["ai_lines"] for r in file_records)
    total_human = sum(r["human_lines"] for r in file_records)

    return {
        "snapshot_type": "incremental",
        "snapshot_date": datetime.now().strftime("%Y-%m-%d"),
        "total_lines": total_ai + total_human,
        "ai_lines": total_ai,
        "human_lines": total_human,
        "file_count": len(file_records),
        "file_records": file_records,
    }


def collect_full_blame(repo_path: str = ".") -> dict:
    """全量 blame：对整个仓库做行级归属（用于初始快照）"""
    try:
        output = subprocess.run(
            ["git", "ls-files"],
            cwd=repo_path, capture_output=True, text=True, check=True,
        ).stdout
    except subprocess.CalledProcessError:
        output = ""

    files = [f.strip() for f in output.splitlines() if f.strip()]
    ai_hashes = get_ai_commit_hashes(repo_path)
    file_records = blame_files(repo_path, files, ai_hashes)

    total_ai = sum(r["ai_lines"] for r in file_records)
    total_human = sum(r["human_lines"] for r in file_records)

    return {
        "snapshot_type": "full",
        "snapshot_date": datetime.now().strftime("%Y-%m-%d"),
        "total_lines": total_ai + total_human,
        "ai_lines": total_ai,
        "human_lines": total_human,
        "file_count": len(file_records),
        "file_records": file_records,
    }
