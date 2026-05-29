"""Commit 采集器 — 从 git commit 中提取 AI 参与信息"""
import subprocess
import re

# AI 工具的 Co-Authored-By 匹配模式
AI_TOOL_PATTERNS = {
    "claude-code": re.compile(r"co-authored-by:\s*claude", re.IGNORECASE),
    "copilot": re.compile(r"co-authored-by:\s*copilot", re.IGNORECASE),
}


def detect_ai_tools(commit_body: str) -> list:
    """检测 commit body 中的 AI 工具 Co-Authored-By 标记"""
    tools = []
    for tool_id, pattern in AI_TOOL_PATTERNS.items():
        if pattern.search(commit_body):
            tools.append(tool_id)
    return tools


class CommitCollector:
    """采集当前 commit 的元数据"""

    def __init__(self, repo_path: str = "."):
        self.repo_path = repo_path

    def _git(self, *args, check=True):
        result = subprocess.run(
            ["git"] + list(args),
            cwd=self.repo_path,
            capture_output=True,
            text=True,
            check=check,
        )
        return result.stdout.strip()

    def collect(self) -> dict:
        commit_hash = self._git("rev-parse", "HEAD")
        author_email = self._git("log", "-1", "--format=%ae")
        commit_time = self._git("log", "-1", "--format=%aI")
        commit_body = self._git("log", "-1", "--format=%b")

        ai_tools = detect_ai_tools(commit_body)
        ai_involved = len(ai_tools) > 0

        lines_added = 0
        lines_deleted = 0
        try:
            numstat = self._git("diff", "--numstat", "HEAD~1", "HEAD")
            for line in numstat.splitlines():
                parts = line.split("\t")
                if len(parts) >= 2:
                    added = parts[0]
                    deleted = parts[1]
                    if added != "-":
                        lines_added += int(added)
                    if deleted != "-":
                        lines_deleted += int(deleted)
        except subprocess.CalledProcessError:
            pass  # first commit has no parent

        return {
            "commit_hash": commit_hash,
            "author_email": author_email,
            "commit_time": commit_time,
            "ai_involved": ai_involved,
            "ai_tools": ai_tools,
            "lines_added": lines_added,
            "lines_deleted": lines_deleted,
        }
