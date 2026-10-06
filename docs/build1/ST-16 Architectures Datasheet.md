# ST-16 Architectures Datasheet

## Introduction

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

#### Pnre-decode

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

Any stages may be optionally fused into a single stage. In fused mode, format parsing is performed
immediately after instruction fuser within the same pipeline stage, and the fused stages are eliminated
from the pipeline sequence.

## Communication Protocols

### Introduction

The architecture defines three communication protocols, classified by
participant count and usage scenario:

| Protocol | Parties | Alias | Status |
|----------|---------|-------|--------|
| Short Four-Echo | Two-party | — | Implemented |
| Three-Party Forwarding | Three-party (full forward) | \u638c\u53d1\u79bb (Wo-Fa-Li) | Implemented |
| Three-Party Direct | Three-party (handoff) | \u638c\u79bb\u53d1 (Wo-Li-Fa) | Implemented |
| Long Four-Echo | Two-party (off-chip) | — | Reserved |

### Short Four-Echo

Two-party protocol for direct communication between internal components
and the CU.

### Three-Party Four-Echo

Three-party protocol for caller-to-callee communication via CU.
Two variants exist.

#### Forwarding Variant (\u638c\u53d1\u79bb / Wo-Fa-Li)

B participates in every transaction as full forwarder. Four phases:
handshake -> send -> depart.

Note: In the direct variant, B does not participate in Phases 2–4 and
only performs initial introduction.

### Long Four-Echo

Off-chip communication protocol between CPU and external devices.
The basic flow mirrors Short Four-Echo, but the ack phase introduces
busy and timeout feedback mechanisms.

## Exception and Recovery

### Error Classification

| Level | Type | Handling |
|-------|------|----------|
| Recoverable | Logged fault | Write status register, arbitrated by Retire |
| Fatal | Hardware error (INVSTP, TMOUT, ...) | Direct RST assertion |

## Instruction Encoding

See `Operation Reference Manual`.
