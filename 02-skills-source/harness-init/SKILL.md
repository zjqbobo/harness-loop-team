---
name: harness-init
description: Use when user asks to 初始化项目规范, 生成项目约定, 分析工程约定, harness-init, project conventions, or wants AI to learn an existing codebase's structure before future coding
---

# Harness — 项目工程约定初始化

## 目标

为存量工程生成项目级工程约定文件：

```
<project>/.harness/docs/architecture/project-conventions.md
```

该文件用于后续 implementation/code-review，让 AI 优先复用现有工程结构、返回包装、分页对象、DTO/VO/Entity、枚举、常量、工具类、异常体系和测试风格。

<HARD-GATE>
执行前必须明确目标项目根目录。禁止在用户未确认项目根目录时生成 `.harness/` 文件。
生成前必须扫描现有代码，不得凭空编写项目约定。
</HARD-GATE>

## 执行流程

### Step 1: 技术栈检测

按 `docs/coding-standards/00-index.md` 的检测规则识别技术栈。

### Step 2: 扫描工程结构

必须扫描并记录：

| 类别 | 查找目标 |
|------|---------|
| 分层结构 | controller/handler/api/routes, service/usecase/domain, repository/dao/mapper/data |
| 返回包装 | Result, ApiResponse, Response, R, CommonResult |
| 分页对象 | PageResult, PageResp, PageRequest, Pageable |
| DTO/VO/Entity | Request/Response/DTO/VO/Entity/PO/DO 命名和位置 |
| Converter/Mapper | MapStruct、手写 converter、mapper 命名 |
| 异常体系 | BizException、AppError、ErrorCode、全局异常处理 |
| 枚举/常量 | enum/enums/constants/common/constant 包或目录 |
| 工具类 | util/utils/common/shared 包或目录 |
| 测试风格 | 测试框架、mock 方式、测试目录结构 |
| 典型样例 | 2-3 个最接近标准写法的接口/服务/测试文件 |

### Step 3: 生成文件

1. **先 Read 默认模板**：按路径解析规则读取 `docs/architecture/project-conventions.md`（harness 默认模板）
2. **基于模板章节结构生成**：覆盖模板中的**每一个章节**，不自行增删章节。模板中的注释（`<!-- TODO: ... -->`）替换为扫描结果，模板中已有内容保留
3. 生成位置：`<project>/.harness/docs/architecture/project-conventions.md`

模板是单一真相源，后续模板更新（如新增章节），harness-init 自动跟随，无需改此 SKILL。

### Step 4: 输出摘要

生成后向用户展示：

- 文件路径
- 识别出的核心约定
- 未识别/需要人工补充的部分

## 关键原则

**项目现有约定优先，Harness 最佳实践兜底。**

但以下底线不可被项目旧代码覆盖：

- 安全编码
- 测试覆盖
- 事务边界
- 数据一致性
- 敏感信息保护
- SQL/XSS/反序列化等安全风险

## 禁止行为

| 禁止 | 原因 |
|------|------|
| 未扫描代码直接生成 | 会变成通用模板，不是项目约定 |
| 新建与项目已有包装类重复的规范 | 导致 AI 后续造平行体系 |
| 只写目录树，不写复用清单 | 后续编码仍不知道复用谁 |
| 忽略测试风格 | 后续测试代码会割裂 |
