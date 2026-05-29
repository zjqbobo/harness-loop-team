"""ACM Storage — 本地 JSONL 文件缓存

按天分文件，append-only 写入，崩溃安全。
目录结构：
  ~/.acm/
    pending/          ← 待上报的 commit，每个 commit 一个 JSON 文件
      abc123.json     ← 以 commit_hash 命名
    reported/         ← 已上报的 commit，按天归档
      2026-05-27.jsonl
"""
import os
import json
from datetime import datetime, timedelta
from pathlib import Path

DEFAULT_BASE_DIR = os.path.expanduser("~/.acm")


class LocalStore:
    """本地 JSONL 文件存储，用于暂存待上报的 commit 数据"""

    def __init__(self, base_dir: str = None):
        self.base_dir = Path(base_dir or DEFAULT_BASE_DIR)
        self.pending_dir = self.base_dir / "pending"
        self.reported_dir = self.base_dir / "reported"
        self.pending_dir.mkdir(parents=True, exist_ok=True)
        self.reported_dir.mkdir(parents=True, exist_ok=True)

    def insert_commit(self, data: dict):
        """写入一条 commit，以 commit_hash 为文件名实现去重"""
        commit_hash = data["commit_hash"]
        file_path = self.pending_dir / f"{commit_hash}.json"
        if file_path.exists():
            return  # 去重
        record = {**data, "created_at": datetime.utcnow().isoformat()}
        # 原子写入：先写临时文件再 rename，防写一半断电
        tmp_path = file_path.with_suffix(".tmp")
        tmp_path.write_text(json.dumps(record, ensure_ascii=False))
        tmp_path.rename(file_path)

    def get_pending(self, limit: int = 100) -> list:
        """获取待上报的 commit 列表"""
        results = []
        cutoff = (datetime.utcnow() - timedelta(days=7)).isoformat()
        for file_path in sorted(self.pending_dir.glob("*.json")):
            try:
                record = json.loads(file_path.read_text())
                # 跳过超过 7 天的
                if record.get("created_at", "") < cutoff:
                    continue
                results.append(record)
                if len(results) >= limit:
                    break
            except (json.JSONDecodeError, OSError):
                continue
        return results

    def mark_reported(self, commit_hashes: list):
        """将已上报的 commit 从 pending 移到 reported（按天归档）"""
        if not commit_hashes:
            return
        today = datetime.utcnow().strftime("%Y-%m-%d")
        reported_file = self.reported_dir / f"{today}.jsonl"

        with open(reported_file, "a", encoding="utf-8") as f:
            for commit_hash in commit_hashes:
                src = self.pending_dir / f"{commit_hash}.json"
                if src.exists():
                    record = src.read_text()
                    f.write(record.rstrip("\n") + "\n")
                    src.unlink()

    def cleanup(self, days: int = 7):
        """清理超过 N 天的已上报归档文件"""
        cutoff = (datetime.utcnow() - timedelta(days=days)).strftime("%Y-%m-%d")
        for file_path in self.reported_dir.glob("*.jsonl"):
            date_str = file_path.stem
            if date_str < cutoff:
                file_path.unlink()
