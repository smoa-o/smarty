# ST-16 Architectures Datasheet

## Introduction

<!-- For DS -->

This document describes the microarchitecture and internal communication protocol of a CPU core built
around a five-stage in-order pipeline, controlled by a centralized Control Unit (CU). The CU orchestrates
pipeline progression stage by stage and coordinates intra-component communication via the Short Four-Echo
protocol.

The *CU* acts as the pipeline master, driving each stage sequentially ( *Fetch* -> *Pre-decode* -> 
*Microcode-sequencer* -> *Execute* -> *Retire*). Each stage reports completion back to the CU before the next
Four-Echo handshake with internal components.

Design Goals:

- Deterministic timing - in-order pipeline, no speculative execution
- Centralized control - CU owns pipeline scheduling and communication arbitration
- Reliable intra-chip communication - four-way handshake with explicit completion acknowledgment

## Pipeline Architecture

<!-- Pipeline Architecture.Five Stage Assembly Line.*.Service Requests For EDS -->
<!-- Others For DS -->

### Five Stage Assembly Line

The *CU* acts as the pipeline master, driving each stage sequentially ( *Fetch* -> *Pre-decode* -> 
*Microcode-sequencer* -> *Execute* -> *Retire*). Each stage reports completion back to the CU before the next
stage is dispatched. Memory mapped access and other service requests are serviced by the CU through the Short
Four-Echo handshake with internal components.

All service requests follow the same model: the requesting stage submits
a request to the CU and waits for completion. The CU arbitrates all
accesses — whether to memory, registers, address units, or the ALU —
and returns results via the Short Four-Echo protocol. No pipeline stage
directly accesses any hardware resource.

#### CU, abbr. Control Unit

#### Fetch

Fetch is responsible for retrieving instructions from IMEM and maintaining
the instruction pointer (cfg.ip). Each fetch cycle consists of three steps:

1. **Read pointer** — RRG request to read cfg.ip, obtaining the current
   fetch address.
2. **Fetch instruction** — IMEMRD request to the CU, which services the
   memory access via the Short Four-Echo protocol.
3. **Update pointer** — WRG request to write back the updated instruction
   pointer (sequential increment or branch target).

All register and memory accesses are mediated by the CU through service
requests; Fetch does not directly access IMEM or the register file.

Key output: instruction word

##### Service Requests

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Register | RRG     | Read      | cfg.ip | Read current instruction pointer |
| Register | WRG     | Write     | cfg.ip | Update instruction pointer |
| Memory   | IMEMRD  | Read      | IMEM   | Fetch instruction word |

#### Pre-decode

Pre-decode receives the instruction word from the Fetch stage and performs
initial format parsing. It extracts the opcode class and decomposes the
instruction into fields usable by subsequent stages. Essentially, it acts
as a formatting layer and performs no complex logic.

Each pre-decode cycle consists of the following steps:

1. **Read input** — Read Back (RBF) request to read the raw instruction
   word from the preceding pipeline register.
2. **Format parsing** — Identify instruction format, extract opcode and
   operand layout.
3. **Output microcodes** — Emit parsed results as microcode entries for
   the uSeq stage to expand.

Pre-decode does not directly access memory or the register file. Its only
external request is the RBF read from the pipeline buffer.

Key output: microcode entries

##### Service Requests

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output (instruction word from Fetch) |

#### Microcode-sequencer (uSeq)

uSeq receives microcode entries from the Pre-decode stage and serializes
them into an executable micro-operation (μop) stream, dispatching each
μop to the Execute stage.

Each uSeq cycle consists of the following steps:

1. **Read input** — RBF request to read microcode entries from the
   preceding pipeline register.
2. **Sequence expansion** — Expand microcode entries into a μop sequence
   (via microcode store lookup or direct sequential issuance, depending
   on instruction complexity).
3. **Dispatch** — Deliver μops one by one to the Execute stage.

uSeq performs no computation and does not directly access the data path.
It is solely responsible for translating instructions into micro-operations
and scheduling their dispatch. Its only external request is the RBF read
from the pipeline buffer.

Key output: μop sequence

##### Service Requests

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output (microcode entries from PD) |

#### Execute

Execute is the most request-intensive stage in the pipeline. It receives
μops from uSeq, drives the ALU to perform computations, and issues various
service requests through the CU to complete address operations, register
accesses, and data path interactions.

Each Execute cycle consists of the following steps:

1. **Read input** — RBF request to read μops from the preceding
   pipeline register.
2. **Address operations** — RAD/WAD requests for address calculation
   (base read, effective address write, etc.).
3. **Register operations** — RRG/WRG requests to read source operands
   and write back results to the register file.
4. **ALU execution** — rALU request to drive the ALU for arithmetic
   or logic operations.
5. **Output result** — Pass computation result to the Retire stage.

Execute is the actual executor of all data path operations. Except for
RBF, all requests are mediated by the CU.

Key output: computation result (data + status flags)

##### Service Requests

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output (μop from uSeq) |
| Address  | RAD     | Read      | Address Register/Unit | Read base or index |
| Address  | WAD     | Write     | Address Register/Unit | Write effective address or result |
| Register | RRG     | Read      | Register File | Read source operand |
| Register | WRG     | Write     | Register File | Write back computation result |
| ALU     | rALU    | Execute   | ALU | Drive ALU for arithmetic/logic operation |

#### Retire

Retire is the final pipeline stage, responsible for checking execution
results, validating instruction commit eligibility, and triggering
recovery when an exception occurs.

Each Retire cycle consists of the following steps:

1. **Read input** — RBF request to read the computation result from
   the preceding pipeline register.
2. **Fault check** — Check fault status (flagged by Execute or CU).
3a. **No fault** — Confirm normal completion and report back to CU.
3b. **Fault detected** — Trigger RST flow and clean up pipeline state.
4. **State readback** — RRG/RAD requests to read status information
    and, if necessary, restore context.

Retire does not write back computation results (already done by Execute).
Its role is "finalization and arbitration": if all is well, it commits;
if a problem is found, it initiates recovery.

Key output: completion confirmation / exception signal

##### Service Requests

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output (result from Execute) |
| Register | RRG     | Read      | Register File | Read status/configuration for fault evaluation |
| Address  | RAD     | Read      | Address Register/Unit | Read fault context address information |

#### Error Classification and RST

Errors in the architecture are classified into two levels:

- **Recoverable faults** — Logged to the fault status register;
  Retire stage checks and arbitrates subsequent handling
  (retry or software intervention).
- **Hardware fatal errors** — Any stage detecting an unrecoverable
  hardware exception asserts RST directly to reset the entire
  pipeline, bypassing the CU service request flow.

RST is a hardwired control signal with priority over all protocol
handshakes. Upon assertion, the pipeline is immediately flushed,
all stages return to their initial state and trigger hardware reset.

### Footer

Fetch and Pre-decode may be optionally fused into a single stage, retaining the name "Fetch". In fused mode,
format parsing is performed immediately after instruction fetch within the same pipeline stage, and the
Pre-decode stage is eliminated from the pipeline sequence.

## Communication Protocols

<!-- Timing For EDS -->
<!-- Others For DS -->

### Introduction

The architecture defines three communication protocols, classified by
participant count and usage scenario:

| Protocol | Parties | Alias | Status |
|----------|---------|-------|--------|
| Short Four-Echo | Two-party | — | Implemented |
| Three-Party Forwarding | Three-party (full forward) | \u638c\u53d1\u79bb (Wo-Fa-Li) | Implemented |
| Three-Party Direct | Three-party (handoff) | \u638c\u79bb\u53d1 (Wo-Li-Fa) | Implemented |
| Long Four-Echo | Two-party (off-chip) | — | Reserved |

Notation:

| Symbol | Meaning |
|--------|---------|
| `->` / `<-` | A \<-\> B |
| `->>` / `<<-` | A \<-\> C |
| `-!>` / `<!-` | B \<-\> C |

Role definitions:
- A: Caller
- B: Forwarder (CU)
- C: Callee

### Short Four-Echo

Two-party protocol for direct communication between internal components
and the CU.

Flow: syn -\> ack -\> fin&data -\> cln

Normal timing:

```
Caller (A) Forwarder (B)

|                    |
|-syn--------------->|
|<--------------ack--|
|                    |
|<-------fin&data----|
|                    |
|----cln------------>|
```

Exception timing:

- Timeout: B fails to ack within limit -\> A retries syn or triggers TMOUT
- Failure: B returns nack -\> A terminates current request

### Three-Party Four-Echo

Three-party protocol for caller-to-callee communication via CU.
Two variants exist.

#### Forwarding Variant (\u638c\u53d1\u79bb / Wo-Fa-Li)

B participates in every transaction as full forwarder. Four phases:
handshake -\> send -\> depart.

```
Phase 1: Connection establishment

A -syn> B
B <ack- A
B -syn!> C
C <!ack- B

Phase 2: Data transfer (A->B->C)

B -snd> B
B <ack- A
B -snd!> C
C <!ack- B

Phase 3: Completion return (C->B->A)

C -gms!> B          (Get Message)
B <!ack- C
C <!fin&data- B
B -ack!> C
B <ack&data- A
A -ack> B

Phase 4: Cleanup

A -ack+cln> B
B <ack- A
B -cln!> C
C <!ack- B
B <ack- A
```

Note: In the direct variant, B does not participate in Phases 2–4 and
only performs initial introduction.

### Long Four-Echo

Off-chip communication protocol between CPU and external devices.
The basic flow mirrors Short Four-Echo, but the ack phase introduces
busy and timeout feedback mechanisms.

Flow: syn -\> ack (with status) -\> fin&data -\> cln

#### Normal Timing

```
A (CPU)            C (External Device)

|                    |
|-syn--------------->|
|<--------------ack--|  (ready, fetching data)
|                    |
|<-------fin&data----|  (done, data valid)
|                    |
|----cln------------>|  (clear data)
```

#### ACK Phase Status Responses

| Response | Meaning | Condition | Handling |
|----------|---------|-----------|----------|
| ack | Ready, fetching | Device ready | Proceed to fin&data |
| BSY | Busy, not ready | Device busy on message receipt | Retry/wait |
| LBSY | Lightly overloaded | 10 consecutive BSY or no reply within 100 cycles | High latency, expect 35clk/resume |
| TBSY | Heavily overloaded | 5 consecutive LBSY or no reply within 135 cycles | Critical overload, expect 70clk/resume |
| TBSY (immediate) | Terminate | Device completely unavailable | Immediate session abort and data clear |

#### Timeout Rules

- BSY: Device not ready; A continues waiting, device returns BSY.
- LBSY: 10 consecutive BSY or no reply within 100 cycles -\> device
  returns LBSY indicating high latency. Expected recovery: 35clk/retry.
  A may continue waiting or abort.
- TBSY: 5 consecutive LBSY or no reply within 135 cycles -\> device
  returns TBSY indicating critical overload. Expected recovery:
  70clk/resume. A terminates the session immediately upon receiving TBSY.

#### Cleanup Phase

`-cln>` indicates "done, you may clear data now." If the device is
still not ready, it may return BSY or LBSY (TBSY is not issued here).
If latency is critically high, device issues TBSY and forcibly clears
data immediately.

## Signal Table Format

<!-- For EDS -->

Extracted directly from Verilog module ports.

| Signal Name | Direction | Width | Active | Driver | Receiver | Description |
|-------------|-----------|-------|--------|--------|----------|-------------|
| CLK | IN/OUT | 1 | Posedge | clock | <all> | Clock Signal |
| RST | OUT | 1 | High | clock | <all> | Reset Signal |
| RADSYN | OUT | 1 | High | <any> | <any> | Read Address Synchronization |
| ROPSYN | OUT | 1 | High | <any> | <any> | Read Operation Length Synchronization |
| RRGSYN | OUT | 1 | High | <any> | <any> | Read Register Synchronization |
| WADSYN | OUT | 1 | High | <any> | <any> | Write Address Synchronization |
| WRGSYN | OUT | 1 | High | <any> | <any> | Write Register Synchronization |
| RADACK | IN | 1 | High | <any> | <any> | Read Address Acknowledgement |
| ROPACK | IN | 1 | High | <any> | <any> | Read Operation Length Acknowledgement |
| RRGACK | IN | 1 | High | <any> | <any> | Read Register Acknowledgement |
| WADACK | IN | 1 | High | <any> | <any> | Write Address Acknowledgement |
| WRGACK | IN | 1 | High | <any> | <any> | Write Register Acknowledgement |
| RADFIN | IN | 1 | High | <any> | <any> | Read Address Finish |
| ROPFIN | IN | 1 | High | <any> | <any> | Read Operation Length Finish |
| RRGFIN | IN | 1 | High | <any> | <any> | Read Register Finish |
| WADFIN | IN | 1 | High | <any> | <any> | Write Address Finish |
| WRGFIN | IN | 1 | High | <any> | <any> | Write Register Finish |
| RADCLN | OUT | 1 | Posedge | <any> | <any> | Read Address Cleanable |
| ROPCLN | OUT | 1 | Posedge | <any> | <any> | Read Operation Length Cleanable |
| RRGCLN | OUT | 1 | Posedge | <any> | <any> | Read Register Cleanable |
| WADCLN | OUT | 1 | Posedge | <any> | <any> | Write Address Cleanable |
| WRGCLN | OUT | 1 | Posedge | <any> | <any> | Write Register Cleanable |
| RADRADA | OUT | 16 | When RADSYN | <any> | <any> | Readed Address, Passage A |
| ROPIID | OUT | 8 | When RADSYN | <any> | <any> | Readed Instruction ID |
| RRGRADA | OUT | 16 | When RADSYN | <any> | <any> | Readed Register, Passage A |
| WADRADA | OUT | 16 | When RADSYN | <any> | <any> | Writed Address, Passage A |
| WRGRADA | OUT | 16 | When RADSYN | <any> | <any> | Writed Register, Passage A |
| RADRADB | OUT | 16 | When RADSYN | <any> | <any> | Readed Address, Passage B |
| RRGRADB | OUT | 16 | When RADSYN | <any> | <any> | Readed Register, Passage B |
| WADRADB | OUT | 16 | When RADSYN | <any> | <any> | Writed Address, Passage B |
| WRGRADB | OUT | 16 | When RADSYN | <any> | <any> | Writed Register, Passage B |
| RADRDTA | IN | 8 | When RADSYN | <any> | <any> | Readed Data, Passage A |
| ROPOUT | IN | 2 | When RADSYN | <any> | <any> | Readed Operation Length |
| RRGRDTA | IN | 16 | When RADSYN | <any> | <any> | Readed Data, Passage A |
| WADRDTA | OUT | 8 | When RADSYN | <any> | <any> | Writed Data, Passage A |
| WRGRDTA | OUT | 16 | When RADSYN | <any> | <any> | Writed Data, Passage A |
| RADRDTB | IN | 8 | When RADSYN | <any> | <any> | Readed Data, Passage B |
| RRGRDTB | IN | 16 | When RADSYN | <any> | <any> | Readed Data, Passage B |
| WADRDTB | OUT | 8 | When RADSYN | <any> | <any> | Writed Data, Passage B |
| WRGRDTB | OUT | 16 | When RADSYN | <any> | <any> | Writed Data, Passage B |
| RADRECA | IN | 8 | When RADSYN | <any> | <any> | Reading Error Code, Passage A |
| RRGRECA | IN | 8 | When RADSYN | <any> | <any> | Reading Error Code, Passage A |
| WADRECA | IN | 8 | When RADSYN | <any> | <any> | Writing Error Code, Passage A |
| WRGRECA | IN | 8 | When RADSYN | <any> | <any> | Writing Error Code, Passage A |
| RADRECB | IN | 8 | When RADSYN | <any> | <any> | Reading Error Code, Passage B |
| RRGRECB | IN | 8 | When RADSYN | <any> | <any> | Reading Error Code, Passage B |
| WADRECB | IN | 8 | When RADSYN | <any> | <any> | Writing Error Code, Passage B |
| WRGRECB | IN | 8 | When RADSYN | <any> | <any> | Writing Error Code, Passage B |
| (other...) | | | | | | |

## Exception and Recovery

<!-- Need Specifiec -->

### Error Classification

<!-- For DS -->

| Level | Type | Handling |
|-------|------|----------|
| Recoverable | Logged fault | Write status register, arbitrated by Retire |
| Fatal | Hardware error (INVSTP, TMOUT, ...) | Direct RST assertion |

### Timeout Handling

<!-- For EDS -->

- Short Four-Echo: timeout -\> TMOUT signal -\> RST or retry (configurable)
- Three-Party: forwarder timeout -\> return failure to caller
- Long Four-Echo: BSY/LBSY/TBSY graded response

### Retry Strategy

<!--For EDS -->

| Scenario | Retry Count | Action on Exhaust |
|----------|-------------|-------------------|
| Short Four-Echo | 0 (no retry) | TMOUT -\> RST |
| Long Four-Echo LBSY | 0 (no retry) | Abort or degrade |
| Long Four-Echo TBSY | 0 (no retry) | Immediate termination |

### Pipeline Flush Conditions

<!-- For EDS -->

| Trigger | Scope | Description |
|---------|-------|-------------|
| RST asserted | Full pipeline | Immediately flush all stages |
| Retire fault | Current instruction | Clear current and subsequent |
| CU protocol error | Related stages | Clear affected stages |

## Register File

<!-- Others For SDM -->

### Overview

Brief description of the register file organization: total number of
registers, width, access ports, and reset behavior.

The register file provides 2 read ports and 2 write ports (2R2W), allowing simultaneous reads by Fetch
(cfg.ip) and Execute (source operand) without port conflict in single-thread mode. IMEM provides 2R2W
access for similar reasons.

In single-thread mode, the 2R2W organization eliminates read port contention between Fetch and Execute
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

#### [cfg.ip]

<!-- [Group: SPR] In SDM, Precisions for EDS -->

**Description:** Instruction Pointer

**Access Rule:**

- Read: anyone
- Write: hardware (use special instruction)
- Hardware may clear: When RST

### Access Constraints

<!-- For EDS -->

- Hardware is readable and writable in anything.

### Aliases and Mirrored Registers

<!-- For EDS -->

Nothing.

### Reset Behavior

<!-- For EDS -->

| Register Group | Reset Value | Reset Source |
|----------------|-------------|--------------|
| Default        | 0           | RST          |

## Instruction Encoding

<!-- For ORM, But provide reference externally -->
<!-- All Reference For DS -->

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

# ST-16 Architectures Datasheet Annex

## Electrical and Timing Characteristics

<!-- For EDS -->

### Clock Characteristics

| Parameter | Symbol | Min | Typ | Max | Unit | Condition | Description |
| --------- | ------ | --- | --- | --- | ---- | --------- | ----------- |
| Clock frequency | Fclk | - | - | TBD | MHz | - | - |
| Clock period | Tclk | TBD | - | TBD | ns | - | - |
| Clock high/low duty | - | 40% | 50% | 60% | - | - | - |
| Reset pulse width | Trst | 2 | - | - | clk | Synchronous to CLK | - |

### Protocol Timing Parameters

| Parameter | Symbol | Value | Unit | Condition | Description |
| --------- | ------ | ----- | ---- | --------- | ----------- |
| Short Four-Echo timeout | T_s4e_tmo | TBD | clk | - | B fails to acknowledge within limit |
| LBSY threshold (consecutive BSY) | T_lbsy_cnt | 10 | - | - | Consecutive BSY before LBSY |
| LBSY threshold (cycles) | T_lbsy_cyc | 100 | clk | - | No reply within this window |
| LBSY recovery latency | T_lbsy_rec | 35 | clk | - | Expected before retry |
| Cleanup phase retry window | T_cln_rty | TBD | clk | - | Device still not ready |

### Pipeline Stage Latency

| Parameter | Latency (best) | Latency (worst) | Note |
| --------- | -------------- | --------------- | ---- |
| Fetch | TBD | TBD | RAD + RRG + WRG |
| Pre-decode | TBD | TBD | Format parse, single RBF |
| uSeq | TBD | TBD | Depends on microcode count |
| Execute | TBD | TBD | ALU + reg/mem access |
| Retire | TBD | TBD | Fault check + state readback |
| Fused Fetch+PD | TBD | TBD | Optional single-stage mode |

### Signal Timing Requirements

| Signal | Setup Time | Hold Time | Valid Window | Notes |
| \*SYN -> \*ACK | TBD | TBD | - | Request to acknowledge |
| \*ACK -> \*FIN | TBD | TBD | - | Acknowledge to data valid |
| \*FIN -> \*CLN | TBD | TBD | - | Data valid to cleanup |
| \*CLN -> next \*SYN | TBD | TBD | - | Cleanup Complete |

## Instruction Table

<!-- For ORM, But provide reference externally -->

### Basic

<!-- This reference for SDM -->

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

## Microcode Table

<!-- For ORM -->

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

## Flags Distribution

<!-- Unspecifiec -->

<!-- Flag Impact Table -> ORM -->
<!-- Flag Bit Table -> EDS -->
<!-- Software get/set flags -> SDM -->

### At [cfg.flg]

| Bit | Mnemonic |
| --- | -------- |
| 7 | ZF |
| 6 | CF |
| 5 | AF |
| 4 | PF |
| 3 | IF |
| 2 | Rsvd. |
| 1 | Rsvd. |
| 0 | Rsvd. |

## Width/Type Table

<!-- For ORM (In Instruction Encoding) -->

### Width

| Key | Brief |
| --- | ----- |
| 0   | byte,b |
| 1   | word,w |
| 2   | *Rsvd.* |
| 3   | *Rsvd.* |

### Type

| Key | Brief |
| --- | ----- |
| 0   | reg,r |
| 1   | mem,m |
| 2   | imm,i |
| 3   | *Rsvd.* |
