# 项目工程约定

> 本文件由 `/harness-init` 或"初始化项目工程规范"生成。
> 项目级真实内容应放在 `<project>/.harness/docs/architecture/project-conventions.md`。
> 若本文件仍为 TODO，implementation/code-review 不应直接使用，应扫描现有代码临时归纳。

## 1. 项目技术栈

<!-- TODO: 由 harness-init 扫描生成 -->

## 2. 目录/包结构

<!-- TODO: 记录 controller/service/repository/domain/data 等目录实际命名 -->

## 3. 接口层约定

<!-- TODO: 记录 Controller/Handler/Router 命名、路径、返回格式 -->

## 4. Service / UseCase 约定

<!-- TODO: 记录接口化、实现类、事务边界、UseCase 拆分习惯 -->

## 5. Repository / DAO / Data 约定

<!-- TODO: 记录数据访问层命名、ORM/Mapper、查询方法命名 -->

## 6. 出入参和返回包装

<!-- TODO: 记录 Result/ApiResponse/PageResult/DTO/VO/Entity/PO/DO 等 -->

## 7. 分页规范

<!-- TODO: 记录分页请求/响应对象、参数命名、默认 pageSize -->

## 8. 异常体系和错误码

<!-- TODO: 记录 BizException/AppException/ErrorCode/全局异常处理 -->

## 9. 枚举、常量、工具类复用清单

<!-- TODO: 记录 enums/constants/utils/common/shared 等位置和典型类 -->

## 10. Converter / Mapper 规范

<!-- TODO: 记录对象转换位置、工具、命名和示例 -->

## 11. 测试风格

<!-- TODO: 记录测试框架、mock 方式、测试目录结构和命名 -->

## 12. 典型参考文件

<!-- TODO: 列出 2-3 个最值得仿照的 Controller/Service/Repository/Test 文件 -->

## 13. Reuse Before Create 清单

新增代码前必须先查找并复用：

- 返回包装类
- 分页对象
- 错误码/异常类
- 枚举/常量
- 工具类
- Converter/Mapper
- 测试基类/测试工具

<!-- TODO: 由 harness-init 填入具体类名和路径 -->

## 14. 待改善项（请勿复制）

如果存量工程中存在已知坏味道，在此记录。AI 生成代码时，结构/命名/复用仍跟项目，但方法体内实现质量跟 harness 规范，这些项不会被复制。

| 存量模式 | 位置（哪些类/文件） | 新代码应改用 |
|---|---|---|
| `BeanUtils.copyProperties` | <!-- TODO --> | MapStruct Converter |
| 手动逐字段 setter 转换 | <!-- TODO --> | Converter 层 |
| 字符串拼 SQL | <!-- TODO --> | 参数化查询 |
| 方法超 80 行 | <!-- TODO --> | 提取私有方法 |
| Controller 直接返回 Entity | <!-- TODO --> | DTO 隔离 |
| 日志用 print/console | <!-- TODO --> | 结构化 Logger |
