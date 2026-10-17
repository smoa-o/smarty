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
| 0x10 | jc | 1 | r m i | Jump if *someflag* |
| 0x11 | jnc | 1 | r m i | Jump if not *someflag* |
| 0x12 | stc | 0 | - | Stay *someflag* |
| 0x13 | clc | 0 | - | Close *someflag* |
| 0x14 | set | 1 | r m | Set detsination from *someflag* |
| 0x14 | get | 1 | r m i | Set *someflag* from source |
| 0x15 | call | 1 | r m i | Call source (push and jump) |
| 0x16 | ret | 0 | - | Return (pop and jump) |
| 0x17 | int | 1 | r m i | Interrupt source (move cpu.r1 and jump) |
| 0x18 | iret | 0 | - | Return interrupting (move cpu.r1 and jump) |
| 0x19 | hlt | 0 | - | Halt when interrupting |
| 0x20 | in | 2 | rr mr rm mm ri mi ir im ii | In source to I/O Port destination |
| 0x21 | out | 2 | rr mr rm mm ri mi ir im ii | Out source to I/O Port destination |

### Details

#### *someflag*

| Value | Brief |
| ----- | ----- |
| 0 | ZF |
| 1 | CF |
| 2 | AF |
| 3 | PF |
| 4 | IF |
| ... | Rsvd. |

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
