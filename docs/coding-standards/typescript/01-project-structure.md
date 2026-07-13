# TypeScript 项目结构规范

## 前端项目（React/Vue/Next.js）🔴

```
src/
├── components/             # 可复用 UI 组件
│   ├── ui/                 # 基础 UI（Button/Input/Modal）
│   │   ├── Button.tsx
│   │   └── Button.test.tsx
│   └── layout/             # 布局组件（Header/Sidebar）
├── pages/                  # 页面级组件（Next.js）或 views/（Vue）
│   ├── dashboard/
│   │   ├── DashboardPage.tsx
│   │   └── components/     # 页面私有组件
│   └── settings/
├── hooks/                  # 自定义 Hooks（React）/ composables（Vue）
│   ├── useAuth.ts
│   └── useFetch.ts
├── services/               # API 调用层（封装 fetch/axios）
│   └── userService.ts
├── stores/                 # 状态管理（Zustand/Pinia/Redux）
│   └── userStore.ts
├── utils/                  # 工具函数
│   └── formatDate.ts
├── types/                  # 共享类型定义
│   ├── user.ts
│   └── api.ts
├── constants/              # 常量
│   └── routes.ts
└── styles/                 # 全局样式
    └── globals.css
```

## 后端项目（Express/Fastify/NestJS）🔴

```
src/
├── routes/                 # 路由注册
│   └── userRoutes.ts
├── controllers/            # 请求处理（NestJS：controller 装饰器）
│   └── userController.ts
├── services/               # 业务逻辑接口 + 实现
│   ├── interfaces/         # Service 接口定义
│   │   └── IUserService.ts
│   └── userService.ts      # Service 实现
├── repositories/           # 数据访问接口 + 实现
│   ├── interfaces/         # Repository 接口定义
│   │   └── IUserRepository.ts
│   └── userRepository.ts   # Repository 实现（Prisma/Drizzle/TypeORM）
├── consumers/              # MQ 消费者
│   └── orderCreatedConsumer.ts
├── schedulers/             # 定时任务
│   └── orderExpiryJob.ts
├── middleware/              # 中间件（auth/validation/logging）
│   └── authMiddleware.ts
├── models/                 # 数据库实体（PO，对应 DB schema）
├── dto/                    # 数据传输对象（Service 层出入参）
│   ├── request/            # 请求 DTO
│   └── response/           # 响应 DTO
├── mapper/                 # Entity ↔ DTO 转换器
│   └── userMapper.ts
├── types/                  # 共享类型定义
├── config/                 # 配置
│   └── env.ts
└── utils/
    └── logger.ts
```

### 后端跨层调用规则 🔴

| 调用方向 | 是否允许 | 说明 |
|---------|---------|------|
| Controller → Service | ✅ | 唯一合法调用方向 |
| Service → Repository | ✅ | 唯一合法调用方向 |
| Controller → Repository | 🔴 禁止 | 必须经由 Service |
| Service → Service | 🟡 允许 | 注意避免循环调用 |
| Repository → Service | 🔴 禁止 | 数据层不可依赖业务层 |

### 后端横切关注点 🔴

**MQ 消费者**
- 统一放在 `consumers/` 目录
- 职责：消息接收 → 反序列化为 DTO → 调用 Service → 确认/拒绝
- **禁止**：在 Consumer 中包含业务逻辑、直接操作 Repository

**定时任务**
- 统一放在 `schedulers/` 或 `jobs/` 目录
- 职责：调度触发 → 调用 Service → 记录执行结果
- **禁止**：在定时任务中包含业务逻辑、直接操作 Repository

**对外接口定义（gRPC/tRPC）**
- 对外暴露的 RPC 接口定义放在独立模块（如 `packages/api/`）或 `interfaces/` 目录
- 出入参必须是 DTO，禁止直接暴露数据库实体

### 后端数据隔离与转换 🔴

**Service/Repository 接口化**
- Service 和 Repository **必须定义接口**，对上层屏蔽实现
- Service 接口放在 `services/interfaces/`，Repository 接口放在 `repositories/interfaces/`
- Controller 只依赖接口，不依赖实现类

**DTO 隔离**

```
Controller  ←→  Request DTO / Response DTO
    ↓ 转换（Mapper）
Service    ←→  DTO
    ↓ 转换（Mapper）
Repository ←→  Entity（Prisma model / ORM entity）
```

| 层 | 使用对象 | 禁止 |
|----|---------|------|
| Controller | Request/Response DTO | 直接使用 Entity/Service DTO |
| Service | DTO | 返回 Entity 给 Controller |
| Repository | Entity | 接收/返回 DTO |

- **Service 入参和出参必须是 DTO**，禁止用 Entity 跨层传递
- **Controller 不得把 Entity 直接返回前端**

**Mapper 转换层**
- Entity ↔ DTO 转换统一放在 `mapper/` 目录
- 使用纯函数转换（或 class-transformer/Automapper），禁止在 Service/Controller 中散落转换逻辑
- 命名：`userMapper.ts`、`orderMapper.ts`

### Service 层复杂度管控 🟡

当 Service 膨胀（单个文件 > 500 行或函数 > 80 行），引入 **UseCase 模式** 拆分：

- 每个 UseCase 只做一件事（单一职责）
- UseCase 由 Service 编排调用，对外仍暴露 Service 接口
- 适用于：跨多个 Repository 的复杂编排、多步骤事务流程

```
services/
├── interfaces/
│   └── IOrderService.ts         # Service 接口
├── orderService.ts              # Service 实现（编排 UseCase）
└── usecases/                    # UseCase（复杂业务拆分）
    ├── CreateOrderUseCase.ts
    └── CancelOrderUseCase.ts
```

## 文件命名规范 🔴

| 类型 | 规则 | 示例 |
|------|------|------|
| React 组件 | `PascalCase.tsx` | `UserProfile.tsx` |
| 页面组件 | `PascalCase` + `Page` 后缀 | `DashboardPage.tsx` |
| Hook | `use` 前缀 + `camelCase.ts` | `useAuth.ts` |
| 工具/服务 | `camelCase.ts` | `formatDate.ts`、`userService.ts` |
| 类型文件 | `camelCase.ts` | `user.ts`（放入 types/ 目录） |
| 测试文件 | 同名 + `.test.ts(x)` | `Button.test.tsx` |
| 常量文件 | `camelCase.ts` | `routes.ts` |

## 导入规范 🔴

```typescript
// ✅ ES Module（禁止 require）
import { UserService } from "@/services/userService";
import type { User } from "@/types/user";

// ✅ 导入顺序：外部库 → 内部模块 → 类型 → 样式
import React from "react";
import { useRouter } from "next/navigation";
import { UserService } from "@/services/userService";
import type { User } from "@/types/user";
import "./styles.css";

// ❌ require（禁止）
const express = require("express");

// ❌ 相对导入过深
import Button from "../../../components/ui/Button";
```

## Monorepo 布局 🟡

```
project/
├── apps/
│   ├── web/                  # Next.js 前端
│   └── api/                  # Express/Fastify 后端
├── packages/
│   ├── shared/               # 共享类型和工具
│   ├── ui/                   # 共享 UI 组件库
│   └── config/               # ESLint/TS 配置
├── package.json              # workspace root
└── turbo.json                # Turborepo 配置
```

## 禁止行为 🔴

| 禁止 | 原因 |
|------|------|
| 循环导入 | 构建失败/运行时错误 |
| 相对导入超过 `../../` | 重构困难 |
| `require()` 混用 | 模块系统混乱 |
| `index.ts` 桶文件过大 | Tree shaking 失效 |
| 深层嵌套 > 4 层 | 难以查找和理解 |
