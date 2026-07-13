#!/usr/bin/env python3
"""Detect AI involvement by scanning recent session JSONL for Edit/Write tool calls."""
import json
import os
from datetime import datetime, timezone
from pathlib import Path

cutoff = datetime.now(timezone.utc).timestamp() - 300
projects_dir = Path.home() / '.claude' / 'projects'
commit_files = set(f for f in os.environ.get('ACM_CHANGED_FILES', '').split() if f)

all_sessions = []
for proj_dir in projects_dir.iterdir():
    if not proj_dir.is_dir():
        continue
    for sf in proj_dir.glob('*.jsonl'):
        try:
            all_sessions.append((sf.stat().st_mtime, sf))
        except Exception:
            continue
all_sessions.sort(reverse=True)

ai = False

for _mtime, sf in all_sessions:
    if _mtime < cutoff:
        break
    try:
        with open(sf) as f:
            for line in f:
                try:
                    event = json.loads(line)
                except Exception:
                    continue
                msg = event.get('message')
                if not msg or msg.get('role') != 'assistant':
                    continue
                for item in msg.get('content', []):
                    inp = item.get('input', {})
                    fp = inp.get('file_path', '')
                    if not fp:
                        continue
                    for cf in commit_files:
                        if cf and (cf in fp or fp.endswith(cf) or fp.endswith('/' + cf)):
                            ai = True
                            break
                    if ai:
                        break
                if ai:
                    break
    except Exception:
        continue
    if ai:
        break

print('["claude-code"]' if ai else '[]')
