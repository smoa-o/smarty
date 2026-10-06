# docs/build1/ST-16 Architectures Operation Reference Manual

## Instruction Encoding

### Summary - [Null]

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Insh. | 8b/12b | true     | See Below   |
| Rsvd? | 4b    | ?hasvn    | Reserved    |

### Summary - [Unary]

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Insh. | 8b/12b | true     | See Below   |
| AType | 4b    | true      | Argument Type |
| Arg  | 8b/16b | true      | Argument    |

**Notes**
> 1. hasvn must be 1.
> 2. The *Arg* type is *AType*

### Summary - [Binary]

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Insh. | 8b/12b | true     | See Below   |
| AType? | 4b   | ?hasvn    | Overall Type |
| Types | 8b    | true      | The Types   |
| ArgA | 8b/16b | true      | Argument A  |
| ArgB | 8b/16b | true      | Argument B  |

**Notes**
> 1. The *ArgA* type is *Types* [7:4]
> 2. The *ArgB* type is *Types* [3:0]

### Type Encoding

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Width | 2b    | true      | (empty)     |
| Type | 2b     | true      | (empty)     |

### Insh. Encoding

> *Insh.* means the instruction header.

**Encoding:**

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Inst. | 7b    | true      | The Instruction Type |
| hasvn. | 1b   | true      | Has Variant |
| variant? | 4b | ?hasvn    | The Variant |

**Notes**
> Instruction Table: see Annex

#### Variant? Encoding

| Name | Length | Conditions | Description |
| ---- | ------ | --------- | ----------- |
| Fum. | 1b | true | (empty) |
| Rsvd. | 3b    | true       | (empty)    |

**Notes**
> *Fum.* means *Flags Unmodifiable*

## Instruction Table

### Basic

| Opcode | Mnemonic | Arguement Length | Supported Argument Combination | Note |
| ------ | -------- | ---------------- | ------------------------------ | ---- |
| 0x0 | mov | 2 | rr rm mr mm ri mi | Move source to destination |
| 0x1 | push | 2 | rr rm mr mm | Push source to destination |
| 0x2 | pop | 2 | rr rm mr mm | Pop source to destination |
| 0x3 | xchg | 2 | rr rm mr mm | Exchange arguments |
| 0x4 | add | 2 | rr rm mr mm ri mi | Destination plus equals source |
| 0x5 | sub | 2 | rr rm mr mm ri mi | Destination minus equals source |
| 0x6 | inc | 1 | r m | Increment destination |
| 0x7 | dec | 1 | r m | Decrement destination |
| 0x8 | and | 2 | rr rm mr mm ri mi | Bitwise AND of destination and source |
| 0x9 | or | 2 | rr rm mr mm ri mi | Bitwise OR of destination and source |
| 0xa | xor | 2 | rr rm mr mm ri mi | Destination XORed with source |
| 0xb | xnor | 2 | rr rm mr mm ri mi | Destination XNORed with source |
| 0xc | not | 1 | r m | Bitwise negation of destination |
| 0xd | shl | 2 | rr mr mr mm ri mi | Shift destination left by source bits |
| 0xe | shr | 2 | rr mr mr mm ri mi | Shift destination right by source bits |
| 0xf | jmp | 1 | r m i | Move cfg.ip to source |
| 0x10 | jz | 1 | r m i | Jump if zero |
| 0x11 | jnz | 1 | r m i | Jump if not zero |
| 0x12 | jc | 1 | r m i | Jump if carry |
| 0x13 | jnc | 1 | r m i | Jump if not carry |
| 0x14 | ja | 1 | r m i | Jump if auxillary carry |
| 0x15 | jna | 1 | r m i | Jump if not auxillary carry |
| 0x16 | jp | 1 | r m i | Jump if parity |
| 0x17 | jnp | 1 | r m i | Jump if not parity |
| 0x18 | ji | 1 | r m i | Jump if interruptable |
| 0x19 | jni | 1 | r m i | Jump if uninterruptable |
| 0x1a | stz | 0 | - | Stay zero |
| 0x1b | stc | 0 | - | Stay carry |
| 0x1c | sta | 0 | - | Stay auxillary carry |
| 0x1d | stp | 0 | - | Stay parity |
| 0x1e | sti | 0 | - | Stay inetrruptable |
| 0x1f | clz | 0 | - | Close zero |
| 0x20 | clc | 0 | - | Close carry |
| 0x21 | cla | 0 | - | Close auxillary carry |
| 0x22 | clp | 0 | - | Close parity |
| 0x23 | cli | 0 | - | Close interruptable |
| 0x24 | call | 1 | r m i | Call source (push and jump) |
| 0x25 | ret | 0 | - | Return (pop and jump) |
| 0x26 | int | 1 | r m i | Interrupt source (move cpu.r1 and jump) |
| 0x27 | iret | 0 | - | Return interrupting (move cpu.r1 and jump) |
| 0x28 | hlt | 0 | - | Halt when interrupting |
| 0x29 | in | 2 | rr mr rm mm ri mi ir im ii | In source to I/O Port destination |
| 0x2a | out | 2 | rr mr rm mm ri mi ir im ii | Out source to I/O Port destination |

### Optimized

- [Moving Optimizing, 0x2a~0x30] mov <OR-A>
- [Stack Optimizing, 0x31~0x4d]
    push cfg.csp, <OR-A>
    push cfg.dsp, <OR-A>
    pop <OR-A>, cfg.csp
    pop <OR-A>, cfg.dsp
- [Arithmetic Optimizing, 0x4e~0x5e]
    add <OR-A>, ...
    sub <OR-A>, ...
    shl <OR-A>, ...
    shr <OR-A>, ...
- [Unary Arithmetic Optimizing, 0x5f~0x6b]
    inc <OR-A>
    dec <OR-A>
    not <OR-A>
- [Jumping Optimizing, 0x6c~0x78]
    jmp <OR-A>
    jz <OR-A>
    jc <OR-A>
- [Calling Optimizing, 0x79~0x7f]
    call <OR-A>
    int <OR-C>

- Optimized Registers A (OR-A): ax bx cx dx cpu.r0 cpu.r1 bp
- Optimized Registers B (OR-B): ax bx cx dx cpu.r0 cpu.r1
- Optimized Registers C (OR-C): ax bx cx cpu.r0 cpu.r1

### Width/Type Table

#### Width

| Key | Brief |
| --- | ----- |
| 0   | byte,b |
| 1   | word,w |
| 2   | *Rsvd.* |
| 3   | *Rsvd.* |

#### Type

| Key | Brief |
| --- | ----- |
| 0   | reg,r |
| 1   | mem,m |
| 2   | imm,i |
| 3   | *Rsvd.* |

## Microcode Table

The following micro-operations are guaranteed to be supported by the Execute stage.
Implementation details including storage format, sequencing, and expansion strategy are not
specified and may vary between implementations.

Instructions in the ISA are expanded into sequences of the following μops by the uSeq stage. The expansion is
implementation-defined; this section only specifies the minimum μop set that must be available to the Execute
stage. Complex instructions (e.g., *call* , *int* , *push* / *pop*  with stack pointer auto-update)
require multiple microcodes from the set below.

| Recommended Mnemonic | Service | Brief |
| -------- | ------- | ------ |
| xrad | IMEM | Read Address |
| xwad | IMEM | Write Address |
| xrrg | Regfile | Read Register |
| xwrg | Regfile | Write Register |
| xjmp | IMEM+ | Jump to address |
| xjcc | IMEM Regfile+ | Jump if condition |
| xadd | ALU | Calculate the cumulative sum of arguments |
| xsub | ALU | Calculate arguments differences |
| xand | ALU | Bitwise AND of arguments |
| xor | ALU | Bitwise OR of arguments |
| xnot | ALU | Bitwise NOT of argument(s) |
| xxor | ALU | Bitwise XORed of arguments |
| xshl | ALU | Argument(s) shift to the left |
| xshr | ALU | Argument(s) shift to the right |
| xhlt | Regfile+ | Waiting interrupt |
