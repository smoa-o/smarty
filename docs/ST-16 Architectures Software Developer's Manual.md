# docs/build1/ST-16 Architectures Software Developer's Manual

## Register File

### Overview

Brief description of the register file organization: total number of
registers, width, access ports, and reset behavior.

The register file provides 2 read ports and 1 write ports (2R1W), allowing simultaneous reads by Fetch
(cfg.ip) and Execute (source operand) without port conflict in single-thread mode. IMEM provides 2R2W
access for similar reasons.

In single-thread mode, the 2R1W organization eliminates read port contention between Fetch and Execute
stages. Multi-thread arbitration (v2) will be defined separately.

### Register Map Summary

| Index | Name | Width | Reset Value | Access | Category | Brief |
|-------|------|-------|-------------|--------|----------|-------|
| 0x0   | ax   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x1   | bx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x2   | cx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x3   | dx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x4   | ex   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x5   | fx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x6   | gx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x7   | hx   | b w   | 0           | RW     | (GPR)       | (null) |
| 0x8   | bp   | b w   | 0           | RW     | (GPR)       | base pointer |
| 0x9   | cfg.ip  | w  | 0           | R      | (SPR)       | instruction pointer |
| 0xa   | cfg.csp | w  | 0           | RW     | (GPR)       | call stack pointer |
| 0xb   | cfg.dsp | w  | 0           | RW     | (GPR)       | data stack pointer |
| 0xc   | cfg.flg | b  | 0           | R      | (SPR)       | flags |
| 0xd   | cpu.r0  | w  | 0           | R      | (SPR)       | cpu flags register |
| 0xe   | cpu.r1  | w  | 0           | R      | (SPR)       | cpu flags register (interrupt) |

### Register Detailed Description

#### [Group: GPR]

**Description:** General Purpose Register

**Access Rules:**

- Read: anyone
- Write: anyone
- Hardware may clear: When RST

#### [Group: SPR]

**Description:** Special Purpose Register

**Access Rule:**

- Read: ? (need specifiec)
- Write: ? (need specifiec)
- Hardware may clear: ? (need specifiec)

**Note:** See `Electronic Datasheet`.

## Instruction Table - Basic

See `Operation Reference Manual`.

## Flag Effect Table

By default, all instructions do not modify the status bit.
When possessing Fum., the flag update rule be hereinafter.
