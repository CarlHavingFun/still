# Still - Data Schema
# Still - 数据结构

## Storage
## 存储
Local-only SQLite.
仅本地 SQLite。

---

## Events (append-only)
## Events（仅追加）
- id
- id
- timestamp
- timestamp
- kind (user_input, still_reply, proactive)
- kind（user_input、still_reply、proactive）
- text
- text

---

## MemoryItems
## MemoryItems
- id
- id
- category (kept, held, passing)
- category（kept、held、passing）
- body
- body
- confidence
- confidence
- ttl (for passing)
- ttl（用于 passing）
- status (active, deleted)
- status（active、deleted）

Rules:
规则：
- Held never auto-promotes
- Held 绝不自动升级
- Passing expires
- Passing 会过期
- No document merging
- 不允许文档合并

---

## ProactivityState
## ProactivityState
- enabled
- enabled
- last_sent
- last_sent
- ignored_streak
- ignored_streak
- silence_until
- silence_until
- quiet_hours
- quiet_hours
