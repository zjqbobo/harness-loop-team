#!/usr/bin/env python3
import json, os
from pathlib import Path

commit_hash = os.environ['ACM_CURRENT_HASH']
total_added = 0
total_deleted = 0
records = []

for line in os.environ['ACM_NUMSTAT'].splitlines():
    parts = line.split('	')
    if len(parts) < 3:
        continue
    added = 0 if parts[0] == '-' else int(parts[0])
    deleted = 0 if parts[1] == '-' else int(parts[1])
    filepath = parts[2]
    total_added += added
    total_deleted += deleted
    records.append({
        'file_path': filepath,
        'lines_added': added,
        'lines_deleted': deleted,
        'ai_lines_added': 0,
    })

data = {
    'snapshot_type': 'incremental',
    'commit_hash': commit_hash,
    'ai_involved': False,
    'total_lines_added': total_added,
    'ai_lines_added': 0,
    'total_lines_deleted': total_deleted,
    'file_records': records,
}

blame_dir = Path.home() / '.acm' / 'blame'
blame_dir.mkdir(parents=True, exist_ok=True)
(blame_dir / f'{commit_hash}.json').write_text(json.dumps(data, ensure_ascii=False))
