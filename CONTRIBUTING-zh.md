# Contributing - Smarty

感谢你对该项目的关注。这是一个自研 CISC 指令集及其 CPU 实现项目，
门槛不低，但如果你对体系结构有热情，欢迎加入。

## 项目现状

- 当前版本：v0.1（第一个可运行版本开发中）
- ISA 手册：已完成，共 5 卷，位于 `docs/` 目录下
- 实现进度：核心取指-译码-执行链路部分完成，复杂指令尚未全部实现
- 当前最需要的帮助：见下方"我们需要什么"

## 开始之前（必读）

如果你打算参与开发，**请按顺序阅读以下文档**（位于 `docs/` 目录下）：

1. **ST-16 Architectures Roadmap** -- 总架构路线图 （先看这个建立整体概念）
1. **ST-16 Architectures Datasheet** —— 芯片概述、架构特性、基本参数
2. **ST-16 Architectures Software Developer's Manual** —— 编程模型、寄存器组织、内存模型、异常机制
3. **ST-16 Architectures Operation Reference Manual** —— 指令操作参考，每条指令的完整语义
4. **ST-16 Architectures Electronic Datasheet** —— 电气特性、硬件接口（实现层面重点关注）

不建议直接跳进代码。这个项目的复杂度在于指令之间的隐式依赖和
状态交互，不先理解 ISA 设计意图很容易迷失。

## 代码结构速览

| 目录/文件 | 作用 |
|---|---|
| `fpd.v` | Fetch + Pre-decode |
| `usexc.v` | uSeq + Exec |
| `retire.v` | Retire |
| `tb/` | 测试平台 |
| `cu.v` | CU |

## 推荐阅读代码的顺序

> 第一次看代码建议按这个路径走，不要从 master 开始硬啃：

1. `非fpd, usexc, retire, cu的代码文件` -- 理解内部数据结构
2. `tb/` -- 理解使用方法
2. `fpd` —— 理解指令怎么从内存出来
3. `usexc` —— 理解指令被分解成哪些微码以及运行阶段
4. 一条简单指令的完整执行路径 (比如 MOV 或 ADD)
5. 再看复杂指令

## 我们需要什么帮助

目前最缺人手的方向（按优先级）：

- **[ ] 指令实现**：按 ISA 手册补全尚未实现的指令
- **[ ] 测试用例**：为已实现的指令编写单元测试
- **[ ] 文档**：架构文档的补充、代码注释的完善
- **[ ] 工具链**：汇编器 / 反汇编器的开发

如果你不确定从哪开始，请看 Issues 里标记为 `good first issue` 的任务。

## 如何贡献

1. Fork 本仓库
2. 创建分支：`git checkout -b feature/your-feature`
3. 开发并测试
4. 提交 PR，PR 描述中请说明：
   - 改了什么
   - 为什么这么改
   - 如何验证（测试命令或预期行为）
5. 如果涉及 ISA 设计变更， **必须先开 Issue 讨论** ，不要直接提 PR

## 代码风格

- 关键逻辑必须带注释，说明"为什么这么做"而非"做了什么"
- CISC 指令实现中，请注明对应 ISA 手册中的哪条指令

## 沟通

- 有问题请先开 Issue 讨论
- QQ群群号: 183241333

## 关于 ISA 设计变更

ISA 手册是本项目的基础文档。如果你认为现有设计有问题或需要扩展：

1. 先在 Issue 中提出，说明动机
2. 讨论通过后再修改手册和代码
3. 不接受的变更会说明理由

## 签署要求（DCO）

本项目采用 [Developer Certificate of Origin (DCO)](./DCO)。

提交代码时，每个 commit 必须包含 `Signed-off-by` 行：

    git commit -s -m "你的提交信息"

这会自动在 commit message 末尾加上：

    Signed-off-by: 你的名字 <你的邮箱>

如果你已经提交了但没有签名，可以用以下命令补上：

    git commit --amend -s
    git rebase HEAD~n -x "git commit --amend -s"

---

再次感谢你的关注。这个项目不简单，但正因如此，每一个贡献都很有分量。
