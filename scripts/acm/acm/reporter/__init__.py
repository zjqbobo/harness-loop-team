"""ACM Reporter — HTTP 批量上报"""
import os
import json
import logging

import requests

from acm.storage import LocalStore

logger = logging.getLogger("acm")

DEFAULT_SERVER_URL = os.getenv("ACM_SERVER_URL", "http://localhost:8080")
BATCH_SIZE = 100


class Reporter:
    """从 LocalStore 读取待上报数据，批量 HTTP POST 到中央服务器"""

    def __init__(self, store: LocalStore = None, server_url: str = None):
        self.store = store or LocalStore()
        self.server_url = server_url or DEFAULT_SERVER_URL

    def run(self):
        pending = self.store.get_pending(limit=BATCH_SIZE)
        if not pending:
            return

        payload = self._build_payload(pending)
        success = self._post_batch(payload)

        if success:
            hashes = [r["commit_hash"] for r in pending]
            self.store.mark_reported(hashes)
            logger.info(f"Reported {len(hashes)} commits")
        else:
            logger.warning(f"Failed to report {len(pending)} commits, will retry")

        self.store.cleanup()

    def _build_payload(self, rows: list) -> dict:
        commits = []
        for r in rows:
            commit_hash = r["commit_hash"]
            blame = self._get_blame_for(commit_hash)
            commit = {
                "commit_hash": commit_hash,
                "author_email": r["author_email"],
                "commit_time": r["commit_time"],
                "ai_involved": bool(r.get("ai_involved")),
                "ai_tools": self._parse_tools(r.get("ai_tools", "[]")),
                "lines_added": r.get("lines_added", 0),
                "lines_deleted": r.get("lines_deleted", 0),
                "edits_total": r.get("edits_total", 0),
                "edits_accepted": r.get("edits_accepted", 0),
                "edits_self_revised": r.get("edits_self_revised", 0),
                "ai_lines_added": blame.get("ai_lines_added", 0),
            }
            commits.append(commit)

        return {
            "agent_id": self._get_agent_id(),
            "repo_id": self._get_repo_id(),
            "commits": commits,
        }

    def _get_blame_for(self, commit_hash: str) -> dict:
        """读取指定 commit 的 blame 快照文件"""
        blame_file = self.store.base_dir / "blame" / f"{commit_hash}.json"
        if not blame_file.exists():
            return {}
        try:
            with open(blame_file) as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return {}

    @staticmethod
    def _parse_tools(tools):
        if isinstance(tools, str):
            try:
                return json.loads(tools)
            except json.JSONDecodeError:
                return []
        return tools or []

    def _post_batch(self, payload: dict) -> bool:
        try:
            resp = requests.post(
                f"{self.server_url}/api/v1/commits/batch",
                json=payload,
                timeout=10,
            )
            return resp.status_code == 200
        except requests.RequestException as e:
            logger.warning(f"Upload failed: {e}")
            return False

    @staticmethod
    def _get_agent_id() -> str:
        import socket
        return f"agent-{os.getenv('USER', 'unknown')}-{socket.gethostname()}"

    @staticmethod
    def _get_repo_id() -> str:
        import subprocess
        try:
            result = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                capture_output=True, text=True,
            )
            url = result.stdout.strip()
            if url:
                return url.split(":")[-1].replace(".git", "").replace("/", "-")
        except Exception:
            pass
        # fallback: use git toplevel dir name
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"],
                capture_output=True, text=True,
            )
            toplevel = result.stdout.strip()
            if toplevel:
                return os.path.basename(toplevel)
        except Exception:
            pass
        return os.path.basename(os.getcwd())