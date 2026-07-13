#!/usr/bin/env python3
import json, os
from datetime import datetime
from pathlib import Path

base = Path(os.path.expanduser('~/.acm'))
pending = base / 'pending'
pending.mkdir(parents=True, exist_ok=True)

hash_val = os.environ['ACM_HASH']
target = pending / f'{hash_val}.json'

if not target.exists():
    record = {
        'commit_hash': hash_val,
        'author_email': os.environ['ACM_EMAIL'],
        'commit_time': os.environ['ACM_TIME'],
        'ai_involved': int(os.environ['ACM_AI']),
        'ai_tools': os.environ['ACM_TOOLS'],
        'lines_added': int(os.environ.get('ACM_ADDED', '0')),
        'lines_deleted': int(os.environ.get('ACM_DELETED', '0')),
        'edits_total': 0,
        'edits_accepted': 0,
        'created_at': datetime.utcnow().isoformat(),
    }
    tmp = target.with_suffix('.tmp')
    tmp.write_text(json.dumps(record, ensure_ascii=False))
    tmp.rename(target)

if os.environ['ACM_AI'] == '1':
    ai_cache = base / 'ai_hashes_cache'
    with open(ai_cache, 'a') as f:
        f.write(os.environ['ACM_HASH'] + '\n')
