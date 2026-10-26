# Readme - Smarty

> Smarty Technology 16-bit CISC instruction set architecture and CPU implementation, STIS.CI. 16

ST-16 is a 16-bit CISC ISA designed for developer **ergonomics** -- easier to program than x86, more
flexible than fixed-width RISC. This repository contains the Verilog CPU implementation, targeting
OS-capable execution.

Smarty is a scalable architecture family; 32 / 64 / 128-bit variants are planned for the future.

## What is this

- **ISA**: Self-designed CISC instruction set, 5-volume specification
- **Implementation**: CPU core written in Verilog
- **Status**: *build1* in-development
- **Goal**: Boot an operating system
- **Design philosophy**: Developer-friendly instruction encoding, variable-length instructions, no x86-level complexity

## Quick Start

### Prerequisites

- **Icarus Verilog** (v0.10+)
- **GNU Make** (optional, for build automation)

### Build & Test

```bash
git clone <this-repo>
cd <this-repo>
make -j$(nproc) self-test
```

### Expected output

The last line should display `all test passed.`.

## Documentation

ISA manuals are located in `docs/` (4 volumes)

| Documentation | Content |
|--|-- | 
| Architectures Datasheet | Chip overview, architectural features, basic parameters |
| Architectures Software Developer's Manual | Programming model, registers, memory model, exceptions |
| Architectures Operation Reference Manual | Complete instruction semantics |
| Architectures Electronic Datasheet | Electrical characteristics, hardware interfaces |

**Read these before diving into code.** The complexity of this project lies in implicit
instruction dependencies and state interactions -- understanding the ISA design intent first
will save you hours.

For a guided code reading path, see _CONTRIBUTING.md_.

## Contributing

See _CONTRIBUTING.md_ for development setup, code structure, and how to get involved.

We especially need help with: instruction implementation, test cases, documentation,
and toolchain (assembler/disassembler).

## Communication

- QQ Group: 183241333
- Issues: See _Gitee Issues_
