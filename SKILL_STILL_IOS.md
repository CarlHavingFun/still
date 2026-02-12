# Still iOS - Development Skill
# Still iOS - 开发技能护栏

## North star
## 北极星
Still holds position, not meaning.
Still 承接位置，不解释意义。

---

## Never allow
## 绝不允许
- Emotional interpretation
- 情绪解读
- Pattern detection
- 模式识别
- Long-form document growth
- 长文持续增长
- Engagement mechanics
- 参与度驱动机制

---

## Always allow
## 必须允许
- Silence
- 沉默
- Exit
- 退出
- Editing or deletion
- 编辑或删除
- Unfinished states
- 未完成状态

---

## Review question
## 评审问题
Does this change help the user stop -
or does it push them forward?
这个改动是在帮助用户停下来，
还是在把用户继续向前推？

If it pushes forward, do not ship.
如果它在推动用户向前，就不要发布。

---

## Postmortem checklist
## 复盘检查清单
- Placeholder lifecycle must be explicit: empty input should always show hint text unless user is actively typing.
- 提示文案生命周期必须明确：输入为空时应始终可见，除非用户正在输入。
- Keyboard show/hide must not reshape or tear the background canvas; verify with repeated focus and collapse.
- 键盘弹出/收起不能导致背景画布拉伸或撕裂；需反复聚焦与收起验证。
- Export and import must be symmetric: exported JSON should be restorable without data loss.
- 导出与导入必须对称：导出的 JSON 必须可无损恢复。
- Every import/export change requires a round-trip automated test in CI.
- 每次导入/导出变更都必须补充 CI 的往返自动化测试。
