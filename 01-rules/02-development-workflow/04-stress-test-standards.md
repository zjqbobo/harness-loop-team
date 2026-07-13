# 压测标准规范

> 本文件为 `harness-testing` Path C 的详细压测流程。
> testing SKILL.md 中保留触发逻辑和引用，详细步骤见本文件。

## 触发规则

单元测试和 E2E 测试全部通过后，必须触发压测询问环节。此环节不可跳过，但用户可以选择跳过压测本身。

## 执行流程

以下 Step 中的选项内容、mock 列表、报告指标均为示例。实际执行时，必须根据本次 session 的真实代码改动动态生成：

- **C1 改动清单**：读取 git diff / session edited files，列出真实新增/修改的类和方法
- **C2 mock 列表**：分析被测代码的 import/依赖树，列出真实外部依赖（不照抄 SKILL.md 中的示例）
- **C5 报告指标**：根据被测功能选择有意义的指标（Reader→吞吐/行延迟，Writer→写入速率，API→QPS/P99）
- **门禁阈值**：根据数据规模和功能类型动态设定（10万行门槛 ≠ 1万行门槛）

### Step C1: 展示改动清单（AskUserQuestion，多选）

1. 读取 session 修改/新增的文件列表（`git diff --name-only` 或 `get_session_edited_files`）
2. 过滤出实现类（非接口、非枚举、非 POJO）
3. 每个候选 item 的 description 根据代码角色自动判断：
   - Reader/解析器/入口类 → "核心性能路径"
   - Writer/序列化类 → "核心性能路径"
   - Factory/Builder → "逻辑简单，压测价值低"
4. 使用 `AskUserQuestion` 让用户勾选，超 4 个拆多次调用

### Step C2: 压测配置（AskUserQuestion，分两轮）

**第一轮：基础配置（4 题）**

Q3 的 mock 列表必须从被测代码的真实 import 中提取：

```
Q1: 数据规模？     options: [1万行, 10万行, 50万行]            (single)
Q2: 并发度？       options: [单线程, 4线程, 8线程]             (single)
Q3: 要 mock 哪些？  options: [不mock, <真实依赖1>, <真实依赖2>]  (multi, 动态)
Q4: 跑几轮？       options: [3轮, 5轮, 10轮]                  (single)
```

**第二轮：Mock 耗时（动态，每个被选中的依赖独立问一次）**

mock 耗时**不预设数值**，用 `Other` 机制让用户自由输入 ms。禁止在选项 label 里预填耗时：
```
Q: Mock [真实依赖名] 每[操作单位]注入多少ms延迟？
   options: [0ms（仅隔离依赖）, 自定义耗时(ms)]  (single)
   → 选"自定义耗时"后，用户在 Other 中填入数字
```

### Step C3: Mock 选择规则

| 规则 | 说明 |
|------|------|
| **默认不 mock** | 压力测试旨在反映真实性能，默认走真实路径 |
| **可 mock 列表** | 自动分析改动代码的依赖树，列出所有外部依赖（IO/网络/DB/MQ） |
| **不 mock 内部代码** | 被测代码本身永远不 mock |
| **mock 耗时可配** | 每个 mock 独立设置固定耗时，模拟慢依赖 |

### Step C4: 执行压测

```bash
# Java 项目
mvn test -Dtest=*StressTest -Dstress.rows=100000 -Dstress.threads=4

# Node.js 项目 — autocannon / k6
npx autocannon -d 60 -c 100 http://localhost:3000/api/import

# Python 项目 — locust / pytest-benchmark
pytest --benchmark-only benchmark/
```

### Step C5: 压测报告

报告必须根据被测功能动态生成：

```
📈 压测报告 — [被测类名] ([数据规模], [轮次]轮)

单轮明细:
| 指标   | Round 1  | Round 2  | ... |
|--------|----------|----------|-----|
| 耗时   | [实测值]  | [实测值]  |     |
| [核心指标]| [...]  | [...]    |     |
| CPU    | [实测%]  | [...]    |     |
| 内存增量| [实测MB] | [...]    |     |

汇总:
| 指标        | 均值         | 门禁            | 状态 |
|-------------|-------------|-----------------|------|
| [核心指标]   | [均值]      | [动态阈值]       | ✓/✗  |
| CPU 均值    | [均值%]     | ≤ 80%           | ✓/✗  |
| 堆内存增量  | [均值MB]    | < [规模×系数]MB  | ✓/✗  |
| GC 次数     | [次数]      | < 10             | ✓/✗  |
| GC 耗时     | [耗时ms]    | -                | -    |
```

**指标选择规则**：

| 被测功能类型 | 核心指标 | 辅助指标 |
|-------------|---------|---------|
| Reader/解析器 | 吞吐(行/s 或 MB/s) | 每行耗时, P99延迟 |
| Writer/序列化 | 写入速率(行/s), 文件大小 | 每行耗时 |
| API/Service | QPS, P50/P99延迟 | 错误率, 连接数 |
| DB/Repository | 查询/秒, 连接池占用 | 慢查询数 |
| 通用(所有类型) | 耗时, CPU%, 堆内存增量, GC次数/耗时 | — |

### Step C6: 压测后链式移交

```
压测完成
    ↓
  ├─ 通过（性能达标）  → 进入链式移交
  ├─ 性能劣化（回归）  → 返回 harness-implementation 分析修复
  └─ 环境问题         → 报告用户，暂停流水线
```
