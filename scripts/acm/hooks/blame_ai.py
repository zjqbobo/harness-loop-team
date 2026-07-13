#!/usr/bin/env python3
"""ACM Phase 3 — AI/human line-level attribution via 3-way diff."""
import difflib
import json
import os
import subprocess
from pathlib import Path
from datetime import datetime, timezone

commit_hash = os.environ['ACM_CURRENT_HASH']
repo_path = os.environ['ACM_REPO']
changed_files = set(f for f in os.environ.get('ACM_CHANGED_FILES', '').split() if f)
blame_dir = Path.home() / '.acm' / 'blame'
blame_dir.mkdir(parents=True, exist_ok=True)

# ── Step 1: collect AI edits from recent session JSONL ──────────────
ai_fp_edits = {}  # file_path -> [{old, new}, ...]
projects_dir = Path.home() / '.claude' / 'projects'
cutoff = datetime.now(timezone.utc).timestamp() - 300

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
                    matched = None
                    for cf in changed_files:
                        if cf and fp.endswith(cf):
                            matched = cf
                            break
                    if not matched:
                        continue
                    if 'old_string' in inp:
                        ai_fp_edits.setdefault(matched, []).append({
                            'old': inp['old_string'],
                            'new': inp['new_string'],
                        })
                    elif 'content' in inp:
                        ai_fp_edits.setdefault(matched, []).append({
                            'old': '',
                            'new': inp['content'],
                        })
    except Exception:
        continue


# ── Step 2: helper — label lines as AI or human ─────────────────────
def label_lines(old_lines, new_lines, edits):
    """Return list of (line_text, is_ai) for each line in new_lines.

    Uses content-based matching: a line in new_lines is AI-generated
    if it appears in the AI replay result but not in old_lines. Works
    for new files, partial edits, and large bulk changes.
    """
    # Replay all edits on old_lines to get ai_result
    ai_lines = list(old_lines)
    for edit in edits:
        o, n = edit['old'], edit['new']
        if not o:
            # Write: set initial content, continue processing later edits
            ai_lines = n.splitlines()
            continue
        joined = '\n'.join(ai_lines)
        idx = joined.find(o)
        if idx >= 0:
            joined = joined[:idx] + n + joined[idx + len(o):]
            ai_lines = joined.splitlines() if joined else []
        # retry with trailing newline (Write adds \n, Edit old_string may not have it)
        if idx < 0:
            o2 = o + '\n'
            idx = joined.find(o2)
            if idx >= 0:
                joined = joined[:idx] + n + joined[idx + len(o2):]
                ai_lines = joined.splitlines() if joined else []

    # Build content-based index: every line that is in ai_lines but
    # NOT in old_lines is AI-generated. Count occurrences to handle
    # duplicates correctly.
    old_counts = {}
    for line in old_lines:
        old_counts[line] = old_counts.get(line, 0) + 1
    ai_only_counts = {}
    for line in ai_lines:
        if old_counts.get(line, 0) <= 0:
            ai_only_counts[line] = ai_only_counts.get(line, 0) + 1
        else:
            old_counts[line] -= 1  # consume one occurrence from old

    labels = []
    consumed = {}
    for line in new_lines:
        available = ai_only_counts.get(line, 0) - consumed.get(line, 0)
        if available > 0:
            labels.append((line, True))
            consumed[line] = consumed.get(line, 0) + 1
        else:
            labels.append((line, False))

    return labels


# ── Step 3: per-file attribution ────────────────────────────────────
total_added = 0
ai_added = 0
total_deleted = 0
records = []

for numstat_line in os.environ['ACM_NUMSTAT'].splitlines():
    parts = numstat_line.split('\t')
    if len(parts) < 3:
        continue
    added = 0 if parts[0] == '-' else int(parts[0])
    deleted = 0 if parts[1] == '-' else int(parts[1])
    filepath = parts[2]
    total_added += added
    total_deleted += deleted

    ai_file_added = 0
    edits = []
    for fp_key, fp_edits in ai_fp_edits.items():
        if filepath and filepath in fp_key or fp_key.endswith(filepath) or fp_key.endswith('/' + filepath):
            edits = fp_edits
            break

    if added > 0 and edits:
        try:
            old_content = subprocess.run(
                ['git', 'show', f'HEAD~1:{filepath}'],
                cwd=repo_path, capture_output=True, text=True,
            ).stdout
        except Exception:
            old_content = ''
        try:
            new_content = subprocess.run(
                ['git', 'show', f'HEAD:{filepath}'],
                cwd=repo_path, capture_output=True, text=True,
            ).stdout
        except Exception:
            new_content = ''

        # Get the exact added lines from git diff
        try:
            diff_output = subprocess.run(
                ['git', 'diff', 'HEAD~1', 'HEAD', '--', filepath],
                cwd=repo_path, capture_output=True, text=True,
            ).stdout
        except Exception:
            diff_output = ''
        added_lines = []
        for line in diff_output.splitlines():
            if line.startswith('+') and not line.startswith('+++'):
                added_lines.append(line[1:])

        old_list = old_content.splitlines()
        new_list = new_content.splitlines()

        # Replay edits on old_lines to get AI's intended result
        replay_lines = list(old_list)
        for edit in edits:
            o, n = edit['old'], edit['new']
            if not o:
                replay_lines = n.splitlines()
                continue
            joined = '\n'.join(replay_lines)
            idx = joined.find(o)
            if idx >= 0:
                joined = joined[:idx] + n + joined[idx + len(o):]
                replay_lines = joined.splitlines() if joined else []
            if idx < 0:
                o2 = o + '\n'
                idx = joined.find(o2)
                if idx >= 0:
                    joined = joined[:idx] + n + joined[idx + len(o2):]
                    replay_lines = joined.splitlines() if joined else []

        # Build pool: for each edit, the lines that are NEW
        # in new_string relative to old_string are AI-added lines.
        ai_lines_pool = []
        for edit in edits:
            old_lines = edit['old'].splitlines() if edit['old'] else []
            new_lines = edit['new'].splitlines()
            # Subtract old from new: AI contributed the difference
            old_counts = {}
            for l in old_lines: old_counts[l] = old_counts.get(l, 0) + 1
            for l in new_lines:
                if old_counts.get(l, 0) > 0:
                    old_counts[l] -= 1
                else:
                    ai_lines_pool.append(l)

        consumed = {}
        for al in added_lines:
            total_available = ai_lines_pool.count(al)
            used = consumed.get(al, 0)
            if used < total_available:
                ai_file_added += 1
                consumed[al] = used + 1

        ai_file_added = min(ai_file_added, added)
    elif added > 0 and not ai_fp_edits:
        # No AI edits for this file — all human
        ai_file_added = 0

    ai_added += ai_file_added
    records.append({
        'file_path': filepath,
        'lines_added': added,
        'lines_deleted': deleted,
        'ai_lines_added': ai_file_added,
    })


# ── Step 4: write blame snapshot ────────────────────────────────────
data = {
    'snapshot_type': 'incremental',
    'phase': 'phase3',
    'commit_hash': commit_hash,
    'ai_involved': True,
    'total_lines_added': total_added,
    'ai_lines_added': ai_added,
    'total_lines_deleted': total_deleted,
    'file_records': records,
}
(blame_dir / f'{commit_hash}.json').write_text(json.dumps(data, ensure_ascii=False))


# ── Step 5: adoption rate (首次采纳率 / 总体采纳率) ──────────────
# Counting unit = "location" (位置).
# A location is a set of Edits to the same file whose old/new lines overlap.
# Writes (old=="") don't participate in location chains; a Write-only file
# counts as 1 location. When Writes and Edits mix on the same file, only
# the Edits define locations (the Write is just the "seed").

# Step 5a: flatten edits in session order, compute per-edit metadata
all_edits = []  # (fp, edit, is_write, new_only, new_set, old_set)
for fp, edits in ai_fp_edits.items():
    for e in edits:
        is_write = (e.get('old', '') == '')
        new_text = e.get('new', '')
        if not new_text:
            continue
        new_set = set(new_text.splitlines())
        old_set = set(e['old'].splitlines()) if e['old'] else set()
        new_only = new_set - old_set
        if not new_only and not is_write:
            continue
        all_edits.append((fp, e, is_write, new_only, new_set, old_set))

# Step 5b: helper — get diff set for a file (cached)
_diff_cache = {}
def _diff_set(fp):
    if fp not in _diff_cache:
        try:
            out = subprocess.run(
                ['git', 'diff', 'HEAD~1', 'HEAD', '--', fp],
                cwd=repo_path, capture_output=True, text=True,
            ).stdout
        except Exception:
            out = ''
        s = set()
        for line in out.splitlines():
            if line.startswith('+') and not line.startswith('+++'):
                s.add(line[1:])
        _diff_cache[fp] = s
    return _diff_cache[fp]

# Step 5c: group Edits (non-Writes) into locations by overlap
#   Two Edits are at the same location if a LATER edit's old_set
#   overlaps with an EARLIER edit's new_set.
per_file = {}  # fp -> [edit_data, ...]
for i, (fp, e, is_write, new_only, new_set, old_set) in enumerate(all_edits):
    if not is_write:
        per_file.setdefault(fp, []).append((i, e, new_only, new_set, old_set))

location_groups = []  # [(fp, [edit_data, ...]), ...]
for fp, edits in per_file.items():
    n = len(edits)
    parent = list(range(n))
    def find(x):
        while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
        return x
    def union(a, b): parent[find(b)] = find(a)

    for i in range(n):
        _iidx, _e, _no, inew_set, _ = edits[i]
        for j in range(i + 1, n):
            _jidx, _e2, _no2, _, jold_set = edits[j]
            if inew_set & jold_set:
                union(i, j)

    groups = {}
    for i in range(n):
        root = find(i)
        groups.setdefault(root, []).append(edits[i])
    for g in groups.values():
        g.sort(key=lambda x: x[0])  # sort by session order
        location_groups.append((fp, g))

# Step 5d: per-location adoption judgement
total_locations = 0
first_adopted = 0      # 首次采纳
self_revised = 0        # 被 AI 自己修正（算总体采纳）

for fp, group in location_groups:
    total_locations += 1
    diff_set = _diff_set(fp)
    if not diff_set:
        continue

    if len(group) == 1:
        # 只有一个编辑 → 首次采纳（如果全部行存活）
        _i, _e, new_only, _ns, _os = group[0]
        if new_only and new_only <= diff_set:
            first_adopted += 1
    else:
        # 多个编辑 → 检查是否全部被 AI 自己覆盖（无人工修改）
        fully_revised = True
        for i in range(len(group)):
            _i, _e, new_only, _ns, _os = group[i]
            missing = new_only - diff_set
            if not missing:
                continue
            later_removed = set()
            for j in range(i + 1, len(group)):
                _j, je, _, _, jold_set = group[j]
                jnew_set = set(je['new'].splitlines())
                later_removed |= (jold_set - jnew_set)
            if not (missing <= later_removed):
                fully_revised = False
                break
        if fully_revised:
            self_revised += 1
        # else: 被人手动改过 → 不计入采纳

# Step 5e: count Write-only files as 1 location each
#   (files where ONLY Writes happened, no Edits)
files_with_edits = set(fp for fp, _ in location_groups)
for fp, edits in ai_fp_edits.items():
    if fp in files_with_edits:
        continue  # already counted via Edits
    if all(e.get('old', '') == '' for e in edits):
        diff_set = _diff_set(fp)
        if not diff_set:
            continue
        total_locations += 1
        last_write = edits[-1]
        new_set = set(last_write['new'].splitlines())
        if new_set <= diff_set:
            first_adopted += 1


# ── Step 6: update pending record ───────────────────────────────────
pending_dir = Path.home() / '.acm' / 'pending'
pending_file = pending_dir / f'{commit_hash}.json'
if pending_file.exists():
    rec = json.loads(pending_file.read_text())
    rec['edits_total'] = total_locations
    rec['edits_accepted'] = first_adopted
    rec['edits_self_revised'] = self_revised
    pending_file.write_text(json.dumps(rec, ensure_ascii=False))
