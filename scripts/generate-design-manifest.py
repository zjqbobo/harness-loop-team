#!/usr/bin/env python3
"""
设计文档章节索引生成器
自动分析设计文档结构，生成用于按需加载的索引文件

使用：
    python generate-design-manifest.py <设计文档路径> [--output <输出路径>]

索引文件仅提供章节位置信息，由 AI 自行判断加载哪些章节。
"""

import re
import json
import argparse
from pathlib import Path
from datetime import datetime


def generate_manifest(doc_path: str) -> dict:
    """生成设计文档索引"""
    doc_file = Path(doc_path)

    if not doc_file.exists():
        raise FileNotFoundError(f"设计文档不存在: {doc_path}")

    content = doc_file.read_text(encoding='utf-8')
    lines = content.split('\n')

    # 提取章节
    sections = {}
    section_list = []  # 有序列表，用于计算结束行

    for i, line in enumerate(lines, 1):
        # 匹配一级或二级标题
        match = re.match(r'^(#{1,2})\s+(.+)$', line)
        if match:
            title = match.group(2).strip()

            # 生成章节ID（标题关键词 + 行号）
            keywords_raw = re.findall(r'[一-龥]+|[a-zA-Z]+', title)
            keywords_clean = keywords_raw[:3] if keywords_raw else ['section']
            section_id = '-'.join(keywords_clean).lower() + f'-{i}'

            # 提取章节关键词（标题 + 后10行）
            preview = '\n'.join(lines[i:i+10])
            all_keywords = re.findall(r'[一-龥]{2,}|[a-zA-Z]{3,}', title + ' ' + preview)
            keywords = list(dict.fromkeys(all_keywords))[:5]  # 去重，取前5个

            section_list.append({
                'id': section_id,
                'title': title,
                'start_line': i,
                'end_line': i,  # 后面补
                'keywords': keywords
            })

    # 计算结束行
    for idx, section in enumerate(section_list):
        if idx < len(section_list) - 1:
            section['end_line'] = section_list[idx + 1]['start_line'] - 1
        else:
            section['end_line'] = len(lines)

        # 转换为字典索引
        sections[section['id']] = {
            'title': section['title'],
            'line_range': [section['start_line'], section['end_line']],
            'keywords': section['keywords']
        }

    # 构建索引
    manifest = {
        'source_file': doc_file.name,
        'source_size': doc_file.stat().st_size,
        'source_mtime': datetime.fromtimestamp(doc_file.stat().st_mtime).isoformat(),
        'manifest_mtime': datetime.now().isoformat(),
        'total_lines': len(lines),
        'sections': sections
    }

    return manifest


def main():
    parser = argparse.ArgumentParser(description='生成设计文档章节索引')
    parser.add_argument('doc_path', help='设计文档路径')
    parser.add_argument('--output', '-o', help='输出路径（默认与设计文档同目录）', default=None)
    args = parser.parse_args()

    # 生成索引
    manifest = generate_manifest(args.doc_path)

    # 确定输出路径
    if args.output:
        output_path = Path(args.output)
    else:
        doc_file = Path(args.doc_path)
        output_path = doc_file.parent / (doc_file.stem + '.manifest.json')

    # 写入文件
    output_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding='utf-8'
    )

    # 输出摘要
    print(f"✅ 索引已生成: {output_path}")
    print(f"   - 设计文档: {manifest['source_file']}")
    print(f"   - 文档行数: {manifest['total_lines']}")
    print(f"   - 章节数量: {len(manifest['sections'])}")

    # 列出章节
    if manifest['sections']:
        print(f"\n📋 章节列表：")
        for sec_id, sec in manifest['sections'].items():
            lines = sec['line_range'][1] - sec['line_range'][0] + 1
            print(f"   - {sec['title']} ({sec['line_range'][0]}-{sec['line_range'][1]}行，{lines}行)")


if __name__ == '__main__':
    main()
