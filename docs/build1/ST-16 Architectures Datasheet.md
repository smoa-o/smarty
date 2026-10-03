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
|<--------------ack--|
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
|<--------------ack--|
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

# 8. Exception and Recovery

## Error Classification

| Level | Type | Handling |
|-------|------|----------|
| Recoverable | Logged fault | Write status register, arbitrated by Retire |
| Fatal | Hardware error (INVSTP, TMOUT, ...) | Direct RST assertion |

## Timeout Handling

- Short Four-Echo: timeout -\> TMOUT signal -\> RST or retry (configurable)
- Three-Party: forwarder timeout -\> return failure to caller
- Long Four-Echo: BSY/LBSY/TBSY graded response

## Retry Strategy

| Scenario | Retry Count | Action on Exhaust |
|----------|-------------|-------------------|
| Short Four-Echo | ? | TMOUT -\> RST |
| Long Four-Echo LBSY | ? | Abort or degrade |
| Long Four-Echo TBSY | 0 (no retry) | Immediate termination |

## Pipeline Flush Conditions

| Trigger | Scope | Description |
|---------|-------|-------------|
| RST asserted | Full pipeline | Immediately flush all stages |
| Retire fault | Current instruction | Clear current and subsequent |
| CU protocol error | Related stages | Clear affected stages |
