# docs/build1/ST-16 Architectures Electronic Datasheet

## Pipeline Architecture

### Five Stage Assembly Line - Service Requests (Recommended)

#### Fetch

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Register | RRG     | Read      | cfg.ip | Read current instruction pointer |
| Register | WRG     | Write     | cfg.ip | Update instruction pointer |
| Buffer   | WBF     | Write     | Pipeline Register | Write preceding stage output |

#### Pre-decode

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output |
| Buffer   | WBF     | Write     | Pipeline Register | Write preceding stage output |

#### Microcode-sequencer (uSeq)

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output |
| Buffer   | WBF     | Write     | Pipeline Register | Write preceding stage output |

#### Execute

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Buffer   | RBF     | Read      | Pipeline Register | Read preceding stage output |
| Address  | RAD     | Read      | Address Register/Unit | Read base or index |
| Address  | WAD     | Write     | Address Register/Unit | Write effective address or result |
| Register | RRG     | Read      | Register File | Read source operand |
| Register | WRG     | Write     | Register File | Write back computation result |
| ALU     | rALU    | Exec->Read | ALU | Drive ALU for arithmetic/logic operation |

#### Retire

| Category | Request | Direction | Target | Description |
|----------|---------|-----------|--------|-------------|
| Register | RRG     | Read      | Register File | Read status/configuration for fault evaluation |
| Address  | RAD     | Read      | Address Register/Unit | Read fault context address information |

## Communication Protocols - Timings (Required)

### Introduction

Notation:

| Symbol | Meaning |
|--------|---------|
| `->` / `<-` | A <-> B |
| `->>` / `<<-` | A \<-\> C |
| `-!>` / `<!-` | B \<-\> C |

Role definitions:

- A: Caller
- B: Forwarder
- C: Callee

For usage scenarios and protocol selection, see `Datasheet`.

### Short Four-Echo

Flow: syn -> ack -> fin&data -> cln

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

#### Forwarding Variant

B participates in every transaction as full forwarder. Four phases:
handshake -> send -> depart.

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


#### Direct Variant

B only participates in initial handshake, then exits. A and C communicate
directly thereafter. Four phases: handshake → exit → send.

```
Phase 1: Handshake establishment
A -syn+gms> B
B <ack- A
B -syn!> C
C <!ack- B

Phase 2: B exits; A/C communicate directly (exactly two snd rounds)
A -snd>> C
C <<ack- A
A -snd>> C
C <<ack- A

Phase 3: Completion return
C <<fin+data- A
A -ack>> C
Phase 4: Cleanup
A -cln>> C
```

Note: In the direct variant, B does not participate in Phases 2–4 and
only performs initial introduction.

#### Protocol Comparison

| | Short | Forwarding | Direct |
|-|-------|---------------------|-----------------|
| Parties | A ↔ B | A ↔ B ↔ C | A ↔ B ↔ C (then A ↔ C) |
| B role | Server | Full forwarder | Introduction only |
| Data path | A–B | A–B–C round-trip | A–C direct |
| Latency | Lowest | Highest (2 hops/step) | Medium |
| Use case | Component↔CU | C only reachable via B | C supports direct link to A |

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

`cln` indicates "done, you may clear data now." If the device is
still not ready, it may return BSY or LBSY (TBSY is not issued here).
If latency is critically high, device issues TBSY and forcibly clears
data immediately.

## Signal Table Format (Recommended)

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

### Timeout Handling

- Short Four-Echo: timeout -> TMOUT signal -> RST or retry (configurable)
- Three-Party: forwarder timeout -> return failure to caller
- Long Four-Echo: BSY/LBSY/TBSY graded response

### Retry Strategy

| Scenario | Retry Count | Action on Exhaust |
|----------|-------------|-------------------|
| Short Four-Echo | 0 (no retry) | TMOUT -\> RST |
| Long Four-Echo LBSY | 0 (no retry) | Abort or degrade |
| Long Four-Echo TBSY | 0 (no retry) | Immediate termination |

### Pipeline Flush Conditions

| Trigger | Scope | Description |
|---------|-------|-------------|
| RST asserted | Full pipeline | Immediately flush all stages |
| Retire fault | Current instruction | Clear current and subsequent |
| CU protocol error | Related stages | Clear affected stages |

## Register Group

### Register Detailed Description

#### [cfg.ip]

**Description:** Instruction Pointer

**Access Rule:**

- Read: anyone
- Write: hardware (use special instruction)
- Hardware may clear: When RST

#### [cpu.*]

**Description:** CPU Registers

**Default Access Rule:**

- Read: anyone
- Write: hardware (use special instruction)
- Hardware may clear: When RST

#### [cpu.r0]

**Description:** CPU Flag

**Bit Map:**

| offset | name | description |
| ------ | ---- | ----------- |
| 7 | RF | Retire Failed |
| ... | Rsvd. | Reserved |

**Access Rule**:

- Read: hardware
- Write: hardware

### [cpu.r1]

**Description:** Interrupting Return Address, IRA.

### Access Constraints

- Hardware is readable and writable in anything.

### Aliases and Mirrored Registers

Nothing.

### Reset Behavior

| Register Group | Reset Value | Reset Source |
|----------------|-------------|--------------|
| Default        | 0           | RST          |

## Electrical and Timing Characteristics

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

## Flag Distribution - Bit Table

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

## Stack Architecture

### Overview

The architecture defines two independent hardware-managed stacks, each growing
downward with unaligned, contiguous storage. Every stack entry is self-describing:
data is immediately followed by a 1-byte width tag. No alignment padding is
inserted between entries.

| Stack | Pointer | Width | Purpose |
|-------|---------|-------|---------|
| Call Stack | cfg.csp | 16-bit | Return addresses (call/ret/int/iret) |
| Data Stack | cfg.dsp | 16-bit | Data operands (push/pop) |

### Storage Layout

Each stack grows toward lower addresses. A push operation writes data first,
then the width tag immediately below it. The stack pointer (csp or dsp) always
points to the lowest valid entry's width byte after a push completes.

Memory layout after a push (higher addresses above):

```
[width_byte]    <- SP + data_width
[data]          <- SP
```

Width encoding follows the Width Table (see Operation Reference Manual):

| Value | Meaning |
|-------|---------|
| 0x00  | byte (1 byte) |
| 0x01  | word (2 bytes) |

### Push Behavior

1. Decrement SP by data width.
2. Write data to [SP].
3. Decrement SP by 1.
4. Write width byte to [SP].

Resulting SP movement:

| Data Width | Total SP Decrement |
|------------|-------------------|
| byte       | 2                 |
| word       | 3                 |

### Pop Behavior

1. Read width byte from [SP].
2. Increment SP by 1.
3. Read data from [SP] using width to determine byte count.
4. Increment SP by data width.

### Call Stack Operations

#### call

Push return address (cfg.ip) onto call stack:

- Data: cfg.ip (word, 2 bytes)
- Width tag: 0x01
- Total SP decrement: 3

#### ret

Pop return address from call stack:

- Read width byte (expected 0x01)
- Restore cfg.ip from stack data
- Total SP increment: 3

#### int

Push return address onto call stack (same layout as call), then redirect cfg.ip
to interrupt vector target.

#### iret

Pop return address from call stack, restore cfg.ip. Additional behavior defined
by interrupt handling specification.

### Data Stack Operations

#### push

Push source operand onto data stack. Width tag determined by operand type
(byte or word). Supported source forms: register, memory, immediate.

#### pop

Pop value from data stack. Width is read from the tag; destination receives
data truncated or zero-extended according to destination width.

### Reset Behavior

| Pointer | Reset Value | Reset Source |
|---------|-------------|--------------|
| cfg.csp | 0           | RST          |
| cfg.dsp | 0           | RST          |

### Notes

- Stack operations are not atomic at the micro-architecture level; expansion
  into micro-operations is implementation-defined.
- Stack overflow and underflow detection are not defined in this revision
  (TBD for v2).
- No alignment constraints are enforced; unaligned memory access is permitted
  for stack operations.
