# AI Agent 平台 (aPaaS) V1.0 项目方案设计

| 文档编号 | PDD-AIAP-001 | 文档密级 | 内部 |
| --- | --- | --- | --- |
| 归属项目 | AI Agent 平台 (aPaaS) 建设项目 | 归属部门 | AI 平台部 |
| 编写人 | AI 架构设计 | 编写日期 | 2026-05-14 |
| 审核人 |  | 审核日期 |  |

---

## 版本历史

| 版本/状态 | 作者 | 变更日期 | 备注 | 审阅 |
| --- | --- | --- | --- | --- |
| V1.0 | AI 架构设计 | 2026-05-14 | 初始版本——基于《AI技术体系架构设计方案》提取改动汇总 | 待审阅 |

---

## 1 项目概述

### 1.1 背景

企业 AI 能力建设面临三重鸿沟：大模型能力强但落地到业务需要大量工程化工作；通用 Agent 平台缺乏行业深度；企业级安全合规和数据治理要求缺乏体系化支撑。本方案基于"让每个行业的企业都能像搭建 SaaS 工作流一样搭建 AI 数字员工"的定位，建设一个多行业可复用的 AI Agent aPaaS 平台。

### 1.2 目标

1. 交付一套完整的四层融合 AI Agent 平台架构设计方案（基础设施层 + AI 能力层 + Agent 平台层 + 行业解决方案层）
2. 输出从零搭建路线图：5 个 Phase / 12 周 / 可执行的部署方案
3. 以物流运输异常处理为案例，验证全链路调用和数据流转
4. 建立 Agent 准确率五维提升体系，目标综合准确率 ≥88%

### 1.3 需求范围

| 序号 | 需求编号 | 需求名称 | 需求概述 | 优先级 |
| --- | --- | --- | --- | --- |
| 1 | REQ-001 | 总体架构设计 | 四层融合架构全景（基础设施→AI能力→Agent平台→行业方案） | P0 |
| 2 | REQ-002 | 基础设施层设计 | GPU集群/向量数据库/图数据库/消息队列/存储/安全/可观测性 | P0 |
| 3 | REQ-003 | AI能力层设计 | 模型网关(多供应商+Falback)/RAG引擎/Prompt Hub/知识图谱/MLOps/语义缓存 | P0 |
| 4 | REQ-004 | Agent平台层设计 | Agent生命周期/编排引擎(LangGraph+自研)/技能市场/分层记忆/评估监控 | P0 |
| 5 | REQ-005 | 行业解决方案层设计 | 行业包模型/多租户隔离/连接器生态/物流+金融Agent矩阵 | P1 |
| 6 | REQ-006 | 从零搭建路线图 | Phase 1-5搭建步骤(K8s/GPU/组件/AI能力/Agent平台/行业方案/上线验证) | P0 |
| 7 | REQ-007 | 物流异常处理Agent案例 | 完整Agent定义/调用链路/数据流转/5类异常全流程 | P1 |
| 8 | REQ-008 | Agent准确率提升体系 | 五维模型/Prompt工程/RAG质量/Skill路由/HITL/90天提升路径 | P0 |
| 9 | REQ-009 | 平台横切能力设计 | 安全合规五层/多租户计费/开发者体验 | P1 |
| 10 | REQ-010 | 技术选型矩阵 | 15+核心组件选型及决策记录/国产化适配策略 | P1 |

### 1.4 关联项目

| 序号 | 项目名称 | 项目编号 | 备注 |
| --- | --- | --- | --- |
| 1 | AI 技术体系架构设计方案 | — | 主设计文档，本文档为改动汇总 |

---

## 2 业务流程

### 2.1 平台四个核心业务流程

**Agent 生命周期流程：** Draft → Testing → Review → Published → Running → Archived（详见主设计文档 §5.2 Agent 生命周期状态机图）

**模型网关请求处理流程：** Agent请求 → Model Gateway → 智能路由(速度/质量/成本/合规四维度) → 模型推理 → Fallback链兜底 → 语义缓存 → 返回（详见主设计文档 §4.2）

**RAG 检索增强流程：** Query输入 → Query理解(改写+拆解+分类) → 多路召回(Milvus向量+ES关键词+Neo4j图+SQL) → 融合排序(Rerank) → 上下文组装 → LLM生成 → 引用来源输出（详见主设计文档 §4.3 RAG流水线图）

**物流异常处理 Agent 业务流程：** 客户投诉 → Agent识别异常类型(延迟/破损/丢件等) → 查询运单状态(TMS) → 查询承运商SLA → 判定责任 → P1/P2/P3分级 → 推荐方案 → Human-in-the-Loop审批 → 客户通知（详见主设计文档 §11.3）

---

## 3 跨系统交互

### 3.1 平台内部系统交互

**改造前：** 无统一AI平台，各业务线独立对接LLM API，Prompt散落各处，知识库不共享，无Agent编排能力。

**改造后：** Agent 平台作为统一入口，通过 Model Gateway 统一管理多模型接入，RAG Engine 统一知识检索，Prompt Hub 集中管理 Prompt 版本，Skill Registry 集中管理 Skills，Kafka 事件流贯穿审计/监控/计费全链路。

**核心交互链路：**
- Agent Runtime ↔ Model Gateway（LLM 调用 + Fallback）
- Agent Runtime ↔ RAG Engine（知识检索 + Rerank）
- Agent Runtime ↔ Skill Registry（MCP/A2A/API 技能调用）
- Agent Runtime ↔ Memory Store（分层记忆读写）
- Agent Runtime → Kafka（状态变更/审计/计费事件）
- Admin UI ↔ Agent Runtime/Prompt Hub/Skill Registry（管理操作）

### 3.2 物流案例外部系统交互

**Agent ↔ TMS系统**：通过 MCP 协议调用 `track-query` 技能，获取运单实时状态
**Agent ↔ 异常检测服务**：通过 API 调用 `abnormal-detection` 技能，返回异常类型和根因
**Agent ↔ 通知系统**：通过 API 调用 `customer-notify` 技能，发送短信/邮件通知
**Agent ↔ 承运商系统**：通过 API 调用 `carrier-sla-lookup`，查询 SLA 和赔偿条款

---

## 4 改动汇总

> 本次为新建项目（从0到1），以下按新建维度组织。

### 4.1 概要设计改动

| 需求 | 改动类型 | 改动说明 |
| --- | --- | --- |
| REQ-001 总体架构设计 | 新增 | 四层融合架构：基础设施层 + AI能力层 + Agent平台层 + 行业解决方案层，含横切能力层 |
| REQ-010 技术选型矩阵 | 新增 | 15+核心组件选型：K8s/vLLM/Milvus/Neo4j/Kafka/Redis/PostgreSQL/LangGraph等 |

### 4.2 功能设计改动

| 需求 | 改动类型 | 改动说明 |
| --- | --- | --- |
| REQ-004 Agent平台层 | 新增 | Agent生命周期管理(7阶段状态机)、编排引擎(5种编排模式+5种多Agent协作拓扑)、技能市场(Skill DSL+发布流程)、分层记忆(4层:工作→短期→长期→知识)、评估监控(离线评估+在线监控+反馈闭环) |
| REQ-005 行业方案层 | 新增 | 行业包模型(Industry Pack)、多租户隔离(Tier1/2/3)、连接器生态(3层)、物流8个Agent+金融4个Agent |
| REQ-009 横切能力 | 新增 | 安全合规五层(L1-L5: 基础设施→网络→应用→AI→数据)、多模式计费(订阅+按量+增值)、开发者工具链(SDK/CLI/VS Code/Playground) |

### 4.3 数据设计改动

| 需求 | 改动类型 | 改动说明 |
| --- | --- | --- |
| REQ-002 基础设施层 | 新增 | 数据存储矩阵：热数据(Redis Cluster) + 温数据(PostgreSQL 读写分离) + 冷数据(MinIO S3)；向量数据库：Milvus主存储 + Qdrant热缓存 + ES混合检索；图数据库：Neo4j知识图谱 + PG递归CTE权限关系 |
| REQ-007 物流案例 | 新增 | Agent执行期间数据流转：Redis(Session State/短期记忆)、Milvus(知识检索/长期记忆)、Neo4j(承运商关系)、ES(关键词匹配)、PostgreSQL(Agent定义/Skill/Prompt/评估集/租户配置)、Kafka(事件流/审计) |

### 4.4 接口设计改动

| 需求 | 改动类型 | 改动说明 |
| --- | --- | --- |
| REQ-003 AI能力层 | 新增 | Model Gateway: OpenAI API兼容 `/v1/chat/completions` 协议；Skill 注册 API: POST `/skills`；Prompt Hub API: CRUD `/prompts`；评估服务 API: POST `/datasets`、GET `/evaluations` |
| REQ-004 Agent平台层 | 新增 | Agent Runtime API: POST `/agents/{id}/run`、GET `/agents/{id}`；Session API: POST `/sessions`；内部gRPC: Agent间通信；外部协议: MCP(技能连接) + A2A(Agent间通信) |
| REQ-007 物流案例 | 新增 | 8个技能接口注册：track-query(MCP)、abnormal-detection(API)、carrier-sla-lookup(API)、route-recommend(API)、customer-notify(API)、carrier-notify(API)、weather-query(API)、claim-init(API) |

---

## 5 上下游系统影响分析

| 影响方向 | 系统名称 | 影响说明 | 是否需配合改造 | 配合方/负责人 |
| --- | --- | --- | --- | --- |
| 上游 | 无（新建平台） | — | 否 | — |
| 下游 | TMS 运输管理系统 | 对接运单查询 MCP 接口 | 否（已有API） | TMS 团队 |
| 下游 | 异常检测服务 | 对接异常检测 API | 否（已有API） | Logistics 团队 |
| 下游 | 通知服务 | 对接短信/邮件发送 API | 否（已有API） | 基础服务团队 |
| 下游 | 承运商系统 | 对接 SLA 查询 API | 是（需标准化SLA字段） | 供应链团队 |
| 下游 | 监控平台(Prometheus/Grafana) | 新增 Agent 监控 Dashboard | 否 | SRE 团队 |

---

## 6 技术风险评估

| 序号 | 风险描述 | 影响范围 | 风险等级 | 应对措施 | 责任人 |
| --- | --- | --- | --- | --- | --- |
| 1 | GPU 供应链风险（A100/H100 供货紧张） | 基础设施层 | 中 | 支持国产芯片(昇腾/寒武纪)；多云混合调度；合理储备 | 基础设施 |
| 2 | 模型能力瓶颈（LLM 能力不足以支撑复杂 Agent 推理） | Agent 平台层 | 中 | 多模型网关+Falback；持续评估最新模型；短期加入人工干预兜底 | AI 算法 |
| 3 | Agent 不可控行为（错误Skill选择、幻觉输出导致业务损失） | Agent 平台层 | 高 | 多级安全护栏；Human-in-the-loop 审批机制；灰度发布+自动回滚；行为边界约束 | AI 平台 |
| 4 | 客户 AI 认知不足（客户不理解 Agent 能做什么/不能做什么） | 行业方案层 | 高 | Phase 1 聚焦灯塔客户联合打磨；提供咨询式交付；标杆案例沉淀 | 行业方案 |
| 5 | 竞品快速跟进 | 整体 | 高 | 行业 know-how 壁垒（连接器+知识库+本体）；ISV 生态绑定 | 平台负责人 |

---

## 7 迁移/切换方案

### 7.1 数据迁移

本次为新建项目，无存量数据迁移需求。首次导入：

| 序号 | 迁移内容 | 源 | 目标 | 迁移方式 | 验证方式 | 预计耗时 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 物流 SOP 文档 | 飞书文档/本地 | Milvus 知识库 | doc-processor 管道导入 | 检索 Top-5 准确率 | 2h |
| 2 | 承运商合同 | PDF 文件 | Milvus 知识库 | doc-processor 管道导入 | 检索 Top-3 准确率 | 1h |

### 7.2 切换策略

- **切换方式**：灰度发布（10% → 50% → 100%），每阶段观察 30min，P95 延迟 <5s 且错误率 <1% 则继续
- **回滚方案**：任一指标恶化 → 自动回滚到上一稳定版本；Prompt 回归测试不通过 → 阻断发布
- **切换前置条件**：E2E 测试 4/4 通过、评估集 Score ≥0.85、P95 延迟 <5s、Skill 调用准确率 ≥90%

### 7.3 配置变更

| 序号 | 配置项 | 变更前 | 变更后 | 所属系统 |
| --- | --- | --- | --- | --- |
| 1 | 模型路由策略 | —（新增） | 速度优先→DeepSeek；质量优先→Claude；合规→私有模型 | Model Gateway |
| 2 | Fallback 链 | —（新增） | Claude→DeepSeek→Qwen→降级模型 | Model Gateway |
| 3 | Human-in-the-Loop 审批阈值 | —（新增） | 金额>5000/置信度<0.75/P1异常→审批 | Agent Runtime |
| 4 | 语义缓存阈值 | —（新增） | 相似度>0.95→直接返回；>0.85→缓存+补充 | AI 能力层 |

---

## 8 里程碑与排期

| 阶段 | 内容 | 计划开始 | 计划结束 | 负责人 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 方案设计 | AI技术体系架构方案设计 | 2026-05-14 | 2026-05-14 | AI 架构设计 | ✅ 已完成 |
| Phase 1: 基础设施 | K8s+GPU+DB+消息队列+存储+监控 | Week 1 | Week 2 | 基础设施 | 待开始 |
| Phase 2: AI能力层 | 模型网关+vLLM+RAG+Prompt Hub | Week 3 | Week 4 | AI 算法 | 待开始 |
| Phase 3: Agent平台层 | Agent运行时+编排引擎+技能+记忆+评估 | Week 5 | Week 8 | AI 平台 | 待开始 |
| Phase 4: 行业方案 | 物流Agent部署+知识库+技能+端到端验证 | Week 9 | Week 10 | 行业方案 | 待开始 |
| Phase 5: 上线验证 | E2E测试+压测+灰度+监控 | Week 11 | Week 12 | AI 平台+SRE | 待开始 |

---

## 9 参考说明

| 名称 | 链接 |
| --- | --- |
| AI 技术体系架构设计方案 | `04-changes/20260514-AI技术体系架构/00-design.md` |
| AI 技术体系架构设计方案 (DOCX) | `output/AI技术体系架构设计方案.docx` |
