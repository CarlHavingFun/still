# Still - Product Requirements Document (PRD)
# Still - 产品需求文档（PRD）

## One-line definition
## 一句话定义
Still is a quiet, local-first presence that remembers where the user stopped.
Still 是一个安静、以本地优先为原则的存在，记住用户停下的地方。

---

## What Still is for
## Still 用来做什么
- Leaving thoughts unfinished without losing them
- 允许想法未完成，同时不丢失它们
- Returning without starting over
- 回来时无需从头开始
- Having a place that does not demand clarity
- 拥有一个不要求“想清楚”的地方

## What Still is NOT for
## Still 不用于什么
- Emotional analysis
- 情绪分析
- Therapy or coaching
- 心理治疗或教练
- Journaling insights
- 日志洞察
- Productivity or self-improvement
- 效率提升或自我优化

---

## Core interaction model
## 核心交互模型

- One user input = one Event
- 一次用户输入 = 一个 Event
- Events are not merged into documents
- Event 不会被合并成文档
- Continuity is represented by state, not by text length
- 连续性由状态表示，而不是文本长度

Non-goal:
非目标：
- Never merge multiple inputs into a single article or note.
- 绝不把多次输入合并成单篇文章或笔记。

---

## Screens (MVP)
## 页面（MVP）

### Home
### 首页
- One line: "Still here."
- 一行文案：“Still here.”
- One multiline input
- 一个多行输入框
- No prompts, no history, no feed
- 无提示、无历史、无信息流

### Memory
### 记忆
- Three sections:
- 三个分区：
  - Kept
  - Kept
  - Held
  - Held
  - Passing
  - Passing
- Editable, deletable
- 可编辑、可删除
- No timestamps, no counts
- 无时间戳、无计数

### Settings
### 设置
- Proactive messages toggle
- 主动消息开关
- Quiet hours
- 静默时段
- Export everything
- 全量导出
- Delete everything
- 全量删除
- Boundaries / About
- 边界说明 / 关于

---

## Memory rules
## 记忆规则

### Kept
### Kept
- Only explicit confirmation
- 仅明确确认后写入
- Or repeated confirmation across time
- 或随时间被重复确认

### Held
### Held
- Default for unfinished thoughts
- 未完成想法的默认去处
- Never auto-promoted
- 绝不自动升级

### Passing
### Passing
- Temporary states
- 临时状态
- TTL-based expiration
- 基于 TTL 的过期机制

---

## Proactivity rules
## 主动性规则

- Max 1 per day
- 每天最多 1 次
- Quiet hours default 23:00-09:00
- 默认静默时段 23:00-09:00
- Ignored twice -> silence for 72 hours
- 连续忽略两次 -> 静默 72 小时
- Messages from whitelist only
- 消息仅允许来自白名单

---

## Success criteria
## 成功标准

- User can stop mid-thought without loss
- 用户可在半途停下且不丢失内容
- App never pressures continuation
- 应用不会施压要求继续
- User can leave with their data anytime
- 用户可随时带着数据离开
