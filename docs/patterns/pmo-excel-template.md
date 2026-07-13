# PMO Excel 生成参考

> 来源：`harness-pmo` skill Step 4.5。提供 openpyxl 生成精美项目规划 Excel 的代码模板。

## 依赖

```bash
pip install openpyxl
```

## 颜色方案

| 用途 | 色号 | 示例 |
|------|------|------|
| M1 主题色 | `#2563eb` (蓝) | 表头背景 |
| M2 主题色 | `#16a34a` (绿) | 表头背景 |
| M3 主题色 | `#ea580c` (橙) | 表头背景 |
| M4 主题色 | `#9333ea` (紫) | 表头背景 |
| P0 背景 | `#fef2f2` (淡红) | 行背景 |
| P1 背景 | `#fefce8` (淡黄) | 行背景 |
| P2 背景 | `#f9fafb` (淡灰) | 行背景 |
| 表头字体 | `#ffffff` (白) | 深色背景上 |
| 边框 | `#d4d4d4` (灰) | 所有单元格 |
| 标题背景 | `#1e293b` (深灰) | 总览页标题行 |

## Sheet 结构

```
02-project-plan.xlsx
├── Sheet 1: "项目总览"     ← 里程碑路线图 + 史诗矩阵 + 统计
├── Sheet 2: "M1-<名称>"    ← 史诗 → 故事 → 任务
├── Sheet 3: "M2-<名称>"    ← 同上
├── Sheet 4: "M3-<名称>"    ← 同上
└── Sheet 5: "M4-<名称>"    ← 同上 (如只有 3 个里程碑则无)
```

## 生成代码模板

```python
python3 << 'PYEOF'
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = Workbook()

# ── 通用样式 ──
thin_border = Border(
    left=Side(style='thin', color='d4d4d4'),
    right=Side(style='thin', color='d4d4d4'),
    top=Side(style='thin', color='d4d4d4'),
    bottom=Side(style='thin', color='d4d4d4')
)
header_font = Font(name='Calibri', size=11, bold=True, color='ffffff')
title_font = Font(name='Calibri', size=14, bold=True, color='ffffff')
body_font = Font(name='Calibri', size=11)
body_font_bold = Font(name='Calibri', size=11, bold=True)
center_align = Alignment(horizontal='center', vertical='center', wrap_text=True)
left_align = Alignment(horizontal='left', vertical='center', wrap_text=True)

M_COLORS = ['2563eb', '16a34a', 'ea580c', '9333ea']  # M1-M4
P_COLORS = {'P0': 'fef2f2', 'P1': 'fefce8', 'P2': 'f9fafb'}

def style_header_row(ws, row, cols, color):
    """给表头行上色"""
    fill = PatternFill(start_color=color, end_color=color, fill_type='solid')
    for c in range(1, cols+1):
        cell = ws.cell(row=row, column=c)
        cell.font = header_font
        cell.fill = fill
        cell.alignment = center_align
        cell.border = thin_border

def style_data_cell(ws, row, col, bold=False):
    cell = ws.cell(row=row, column=col)
    cell.font = body_font_bold if bold else body_font
    cell.alignment = left_align if col <= 2 else center_align
    cell.border = thin_border
    return cell

# ── Sheet 1: 项目总览 ──
ws_summary = wb.active
ws_summary.title = '项目总览'

# 标题行
ws_summary.merge_cells('A1:H1')
title_cell = ws_summary.cell(row=1, column=1, value='[项目名] — 项目规划总表')
title_cell.font = title_font
title_cell.fill = PatternFill(start_color='1e293b', end_color='1e293b', fill_type='solid')
title_cell.alignment = center_align
ws_summary.row_dimensions[1].height = 36

# 里程碑路线图 (row 3-6)
milestone_headers = ['', 'M1', 'M2', 'M3', 'M4']
milestone_rows = ['名称', '目标', '时间盒', '关键交付物']
# ... 填入数据，M1-M4 用对应颜色表头

# 史诗×故事矩阵 (row 9+)
# ... P0=红底, P1=黄底, P2=灰底

# 统计汇总 (末段)
# ... 浅灰背景

# ── Sheet 2-N: 每个里程碑一页 ──
for mi, m in enumerate(milestones):
    ws = wb.create_sheet(title=f'M{mi+1}-{m["name"][:20]}')
    color = M_COLORS[mi]
    # 顶部信息行
    # 史诗分组 → 用户故事表 → 任务拆解表

# ── 保存 ──
output_path = '04-changes/<变更>/02-project-plan.xlsx'
wb.save(output_path)
print(f'✅ Excel 已生成: {output_path}')
PYEOF
```

## 实用函数参考

```python
def set_col_widths(ws, widths):
    """批量设置列宽，widths = {1: 8, 2: 40, 3: 30, ...}"""
    for col, width in widths.items():
        ws.column_dimensions[get_column_letter(col)].width = width

def merge_and_fill(ws, start_row, end_row, col, text, fill_color, font=None):
    """合并单元格并填充"""
    ws.merge_cells(start_row=start_row, start_column=col, end_row=end_row, end_column=col)
    cell = ws.cell(row=start_row, column=col, value=text)
    cell.fill = PatternFill(start_color=fill_color, end_color=fill_color, fill_type='solid')
    if font:
        cell.font = font
    cell.alignment = center_align
    cell.border = thin_border
```
