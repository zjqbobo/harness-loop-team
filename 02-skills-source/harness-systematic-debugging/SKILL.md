---
name: harness-systematic-debugging
description: Use when user reports 修bug, 调试, 报错, 不工作, 出问题, 异常,
  debug, fix bug, error, broken, not working, crash, exception
  — enforces 4-phase systematic debugging: root cause investigation → pattern analysis
  → single hypothesis testing → minimal fix. NO FIXES WITHOUT ROOT CAUSE FIRST.
  Triggers on: 帮我修, 报错了, 不工作, 出bug了, 调试一下, 这个错误, 挂了.
---

# Harness — 系统调试

<HARD-GATE>
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.
Do NOT guess. Do NOT try random fixes.
Follow the 4 phases in order. Previous phase must complete before next begins.
</HARD-GATE>

## 铁律

> 猜测模式调试平均耗时 2-3 小时；系统调试平均 15-30 分钟。

## Phase 1: 根因调查

- [ ] 完整读取错误信息（不是"看一眼"，是"读完整"）
- [ ] 稳定复现步骤
- [ ] 检查最近的 git 变更（`git log --oneline -10`, `git diff HEAD~1`）
- [ ] 对多组件系统，在每个边界打诊断日志，先跑一次收集证据

## Phase 2: 模式分析

- [ ] 找到同一个 codebase 里类似的、能跑通的代码
- [ ] 和坏的代码逐项对比差异——每一个差异，不管多小，都列出来
- [ ] 理解依赖和假设条件

## Phase 3: 单假设验证

- [ ] 写下具体假设："我认为 X 是根因，因为 Y"
- [ ] 做最小变更验证
- [ ] 不对的话：换新假设，不要叠加改动

## Phase 4: 实现修复

- [ ] 先写能复现问题的测试
- [ ] 只改一处
- [ ] **三次失败规则**：如果试了 3 次还没有解决 → 停下来讨论是不是架构问题，不继续猜

## 常见借口 vs 真相

| 借口 | 真相 |
|------|------|
| "这个 issue 很简单，不用走流程" | 简单的 bug 也有根因，流程对简单问题反而更快 |
| "紧急情况，没时间调查" | 系统性调试比猜测快多了，"紧急"不是理由 |
| "先试一下再说" | 第一次就确立猜测模式，后面就一直猜 |
| "我已经大概知道问题在哪了" | 知道症状不等于知道根因 |

## 与 Superpowers 对齐

此 skill 是对 Superpowers `systematic-debugging` 的 harness 实现。
