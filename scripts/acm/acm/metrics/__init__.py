"""ACM Metrics — 指标计算模块"""


def compute_acr(commits: list) -> dict:
    """计算 AI 提交率 (ACR)"""
    total = len(commits)
    if total == 0:
        return {"total_commits": 0, "ai_commits": 0, "ai_commit_rate": 0.0}

    ai_count = sum(1 for c in commits if c.get("ai_involved"))
    return {
        "total_commits": total,
        "ai_commits": ai_count,
        "ai_commit_rate": round(ai_count / total, 4),
    }


def compute_alcr(snapshot: dict) -> float:
    """计算 AI 代码行占比 (ALCR)"""
    total = snapshot.get("total_lines", 0)
    if total == 0:
        return 0.0
    ai_lines = snapshot.get("ai_lines", 0)
    return round(ai_lines / total, 4)


def compute_hmr(ai_lines: int, modified_ai_lines: int) -> float:
    """计算人工修改率 (HMR)"""
    total_ai = ai_lines + modified_ai_lines
    if total_ai == 0:
        return 0.0
    return round(modified_ai_lines / total_ai, 4)
