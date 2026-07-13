# 图表验证规则（Token 优化）

## 核心规则

验证/查看图表时，若同目录存在同名 SVG 文件，**必须 Read SVG，禁止 Read PNG**。

## 适用范围

- fireworks-tech-graph 生成图表后
- harness-document-generation 生成含图文档时
- harness-design-review 审核设计文档时
- harness-implementation 编码实现时查阅图表

## SVG 验证清单

Read SVG（文本）后逐项确认：
- 文字标签是否与设计文档一致
- 架构组件是否完整（无遗漏模块）
- 连线/箭头方向是否正确
- 分层结构是否符合设计意图

## 辅助检查（不消耗 token）

不 Read 文件即可完成的检查：
- 图片分辨率：`sips -g pixelWidth -g pixelHeight <file.png>`
- 文件存在性：`ls <file.png>`
- Markdown 引用路径：Grep `!\[.*\]\(.*\.png\)`

## 唯一例外

用户明确说"给我看看这张图/截图/效果图"时，才 Read PNG。此例外不适用于 AI 自行发起的验证行为。
