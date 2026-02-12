# Still - Implementation Guide
# Still - 实现指南

This repository contains the complete implementation specification for **Still**.
这个仓库包含 **Still** 的完整实现规范。

This README is for implementers (human or agent).
这份 README 面向实现者（人类或 Agent）。
It explains how each `.md` file should be used.
它说明每个 `.md` 文件应如何使用。

This is not a user-facing introduction.
这不是面向用户的介绍文档。

---

## File hierarchy (read this first)
## 文件层级（请先阅读）

These files are not equal.
这些文件并非同等权重。
They have different authority levels.
它们有不同的约束级别。

---

## 1. AGENTS.md (Immutable Constitution)
## 1. AGENTS.md（不可变宪法）

**Highest authority. Do not modify.**
**最高权重。不要修改。**

Defines:
定义：
- What Still is
- Still 是什么
- What Still is not
- Still 不是什么
- Absolute behavioral and product boundaries
- 绝对行为边界与产品边界

If any other file conflicts with AGENTS.md, AGENTS.md wins.
如与其他文件冲突，以 AGENTS.md 为准。

---

## 2. SKILL_STILL_IOS.md (Anti-drift Guardrails)
## 2. SKILL_STILL_IOS.md（防漂移护栏）

Defines:
定义：
- How to make implementation decisions
- 如何做实现决策
- How to review PRs
- 如何评审 PR
- How to detect philosophical drift
- 如何识别哲学漂移

Use this file during:
在以下场景使用该文件：
- Code reviews
- 代码评审
- Feature discussions
- 功能讨论
- Model integration
- 模型集成

If a feature violates this file, it should not be implemented.
若功能违反该文件，不应实现。

---

## 3. PRD.md (Product Rules)
## 3. PRD.md（产品规则）

Defines:
定义：
- What features exist in the MVP
- MVP 包含哪些功能
- What problems Still solves
- Still 解决哪些问题
- What problems it explicitly does not solve
- Still 明确不解决哪些问题

PRD.md is binding.
PRD.md 具有约束力。
Features not described here should not be added.
未在此定义的功能不应新增。

---

## 4. DESIGN.md (UI / UX Constraints)
## 4. DESIGN.md（UI / UX 约束）

Defines:
定义：
- Visual language
- 视觉语言
- Interaction patterns
- 交互模式
- Anti-patterns
- 反模式

DESIGN.md should be treated as a constraint, not inspiration.
DESIGN.md 应被视作约束，而非灵感来源。

If UI feels productive, engaging, or demanding, it is likely wrong.
如果 UI 显得高效率、强参与或有压迫感，通常就是错的。

---

## 5. SCHEMA.md (Data & Logic Source of Truth)
## 5. SCHEMA.md（数据与逻辑真相源）

Defines:
定义：
- Data models
- 数据模型
- State transitions
- 状态流转
- Memory and proactivity rules
- 记忆与主动性规则

SCHEMA.md is the single source of truth for:
SCHEMA.md 是以下内容的唯一真相源：
- Persistence
- 持久化
- Gating logic
- 门控逻辑
- Export behavior
- 导出行为

Do not infer additional meaning beyond this schema.
不要在该结构之外推断额外语义。

---

## 6. COPY.md (User-facing Language)
## 6. COPY.md（面向用户的语言）

Defines:
定义：
- All user-visible strings
- 所有用户可见文案
- Tone and wording boundaries
- 语气与措辞边界

Do not rewrite copy to be more motivating, emotional, or engaging.
不要将文案重写为更激励、更情绪化或更具参与感。
Minimal, calm language is intentional.
简洁、平静的语言是刻意设计。

---

## Implementation order (recommended)
## 实现顺序（推荐）

1. Read AGENTS.md and SKILL_STILL_IOS.md fully.
1. 完整阅读 AGENTS.md 与 SKILL_STILL_IOS.md。
2. Implement data layer strictly following SCHEMA.md.
2. 严格按 SCHEMA.md 实现数据层。
3. Implement core flows from PRD.md.
3. 按 PRD.md 实现核心流程。
4. Build UI constrained by DESIGN.md.
4. 按 DESIGN.md 约束实现 UI。
5. Use COPY.md verbatim for strings.
5. 字符串按 COPY.md 原文使用。

---

## Final check before shipping
## 发布前最终检查

Ask these questions:
请自检以下问题：

- Does the app allow the user to stop without finishing?
- 应用是否允许用户不完成就停下？
- Does anything encourage continuation or interpretation?
- 是否存在鼓励继续或解释的设计？
- Can the user export and leave without friction?
- 用户能否无摩擦导出并离开？
- Is silence treated as a valid outcome?
- 沉默是否被视作有效结果？

If the answer to any is "no", revisit the files above.
若任一答案为“否”，请回到上述文件重新核对。

---

Still holds position, not meaning.
Still 承接位置，不解释意义。
