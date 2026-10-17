# Governance

## Project Lead

本项目由 **SeaMc** 作为项目负责人（Project Lead），负责：

- ISA 设计的最终决策
- 版本发布节奏
- 维护者任命
- 争议仲裁

## Decision Making

### ISA 设计变更

ISA 是本项目的基础，任何设计变更必须经过：

1. 开 Issue 提出动机和方案
2. 公开讨论（至少 7 天，除非是紧急修复）
3. Project Lead 做出最终决定并说明理由

### 代码合并

- 一般代码变更：至少一个维护者 Review 后合并
- 核心模块变更（`fpd.v`、`usexc.v`、`retire.v`、`cu.v`）：需 Project Lead 确认
- ISA 相关变更：需同步更新手册和代码，且 Project Lead 确认

### 争议解决

当意见分歧无法在讨论中达成一致时，由 Project Lead 做出最终决定。决定会记录在相关 Issue 中。

## Maintainers

| Role | Name | Contact |
|---|---|---|
| Project Lead | SeaMc | sauthm_2015@qq.com |
| Maintainer | -- | -- |

维护者由 Project Lead 任命。贡献者在满足以下条件后可被考虑：

- 持续贡献至少 3 个月
- 实现过至少 5 条指令或等价工作量
- 参与过代码 Review
- 了解 ISA 设计意图和项目方向

## Becoming a Maintainer

如果你对本项目有持续贡献并希望成为维护者，请开 Issue 表达意向，Project Lead 会评估你的贡献记录和参与情况。

## Code of Conduct

所有参与者必须遵守 [行为准则](CODE_OF_CONDUCT.md)。违反者可能被取消参与资格。

---

*本文档可随时修订。修订需 Project Lead 批准并在仓库中公告。*
