# Contributing - Smarty

Thank you for your interest in this project. This is a self-designed CISC
instruction set and its CPU implementation. The barrier to entry is fairly
high, but if you are passionate about computer architecture, you are welcome
to join.

## Project Status

- Current version: v0.1 (first runnable version in development)
- ISA Manual: Complete, 4 volumes total, located under `docs/`
- Implementation progress: Core fetch-decode-execute pipeline partially
  complete; complex instructions not yet fully implemented
- What we need most right now: see "What We Need Help With" below

## Before You Start (Required Reading)

If you plan to contribute, **please read the following documents in order**
(located in the `docs/` directory):

1. **ST-16 Architectures Datasheet** — Chip overview, architectural
   features, basic parameters (start here to build a general mental model)
2. **ST-16 Architectures Software Developer's Manual** — Programming model,
   register organization, memory model, exception mechanism
3. **ST-16 Architectures Operation Reference Manual** — Instruction
   operation reference, complete semantics for every instruction
4. **ST-16 Architectures Electronic Datasheet** — Electrical characteristics,
   hardware interfaces (key focus area for implementation work)

We do not recommend diving straight into the code. The complexity of this
project lies in the implicit dependencies and state interactions between
instructions; without first understanding the ISA design intent, it is very
easy to get lost.

## Code Structure Overview

| Directory / File | Purpose |
|---|---|
| `fpd.v` | Fetch + Pre-decode |
| `usexc.v` | uSeq + Exec |
| `retire.v` | Retire |
| `tb/` | Testbench |
| `cu.v` | CU |

## Recommended Code Reading Order

> On your first pass through the code, we suggest following this path rather
> than trying to tackle `master` head-on:

1. Files other than `fpd`, `usexc`, `retire`, `cu` — understand internal data structures
2. `tb/` — understand usage
3. `fpd` — understand how instructions are fetched from memory
4. `usexc` — understand how instructions are decomposed into microcode and executed
5. The complete execution path of a simple instruction (e.g., MOV or ADD)
6. Then move on to complex instructions

## What We Need Help With

Areas where we are most short-handed right now (in priority order):

- **[ ] Instruction implementation**: Fill in unimplemented instructions per
  the ISA manual
- **[ ] Test cases**: Write unit tests for implemented instructions
- **[ ] Documentation**: Supplementing architecture docs, improving code comments
- **[ ] Toolchain**: Assembler / disassembler development

If you are unsure where to start, please check the Issues tagged
`good first issue`.

## How to Contribute

1. Fork this repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Develop and test
4. Submit a PR. In the PR description, please explain:
   - What was changed
   - Why it was changed
   - How to verify (test commands or expected behavior)
5. If the change involves ISA design modifications, **you must open an
   Issue for discussion first** — do not submit a PR directly

## Code Style

- Critical logic must be commented to explain *why* it is done this way,
  not just *what* it does
- In CISC instruction implementations, please cite the corresponding
  instruction from the ISA manual

## Communication

- If you have questions, please open an Issue for discussion first
- QQ Group: 183241333

## Regarding ISA Design Changes

The ISA manual is the foundational document of this project. If you believe
the current design has issues or needs extension:

1. Propose it in an Issue first, explaining the motivation
2. After discussion is approved, modify the manual and code
3. Rejected changes will include an explanation

## Signing Requirements (DCO)

This project adopts the [Developer Certificate of Origin (DCO)](./DCO).

When submitting code, every commit must include a `Signed-off-by` line:

    git commit -s -m "Your commit message"

This will automatically append the following to the end of the commit message:

    Signed-off-by: Your Name <your.email@example.com>

If you have already committed but forgot to sign off, you can add it retroactively with the following commands:

    git commit --amend -s
    git rebase HEAD~n -x "git commit --amend -s"

---

Thank you again for your interest. This project is not simple, but
precisely because of that, every contribution carries real weight.
