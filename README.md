# 🔐 Fault-Tolerant ALU  
### Multi-Level Error Detection using Parity Prediction, Carry Checking & Residue Codes (mod-3 / mod-5)

This project implements a **Fault-Tolerant Arithmetic Logic Unit (ALU)** in SystemVerilog with multiple parallel error detection techniques designed for reliable digital systems.

The architecture improves fault coverage by combining:

- ✅ Parity Prediction  
- ✅ Carry Chain Checking  
- ✅ Residue Code Checking (mod-3 and mod-5)  
- ✅ Multi-Level Error Decision Logic  

This design targets:
- Fault-resilient VLSI systems  
- AI accelerator datapaths  
- Safety-critical arithmetic units  
- FPGA/ASIC research implementations  

---

# 🏗 Architecture Diagram

![Fault Tolerant ALU Architecture](https://github.com/user-attachments/assets/533bd2a8-7000-4234-897c-65df6e1ebed6)

---

# 🧠 System Overview

The design consists of two primary sections:

## 1️⃣ ALU Core (Functional Unit)

- Performs arithmetic and logical operations.
- Generates result and internal carry chain.
- Parameterizable bit-width (default: 8-bit, scalable to 16/32-bit).

Supported operations:

| Opcode | Operation |
|--------|----------|
| 000 | ADD |
| 001 | SUB |
| 010 | AND |
| 011 | OR |
| 100 | XOR |
| 101 | Shift Left |
| 110 | Shift Right |

---

## 2️⃣ Error Detection Units (Parallel Checking)

Three independent mechanisms validate computation simultaneously.

---

### 🔹 Parity Prediction

- Input parity is computed:
  
  P(A) ⊕ P(B)

- Compared with output parity:
  
  P(Result)

If mismatch → `parity_error = 1`

✔ Low area overhead  
✔ Fast detection  
⚠ May miss some multi-bit symmetric errors  

---

### 🔹 Carry Chain Checking

- Monitors internal carry propagation.
- Detects carry corruption in ripple-carry structure.
- Ensures carry[i+1] consistency.

If invalid carry relation → `carry_error = 1`

✔ Strong for arithmetic datapath faults  

---

### 🔹 Residue Code Checking (mod-3 & mod-5)

For addition:

(A + B) mod m  ==  (A mod m + B mod m) mod m

Where m = 3 or 5.

Process:
- Compute residue of A
- Compute residue of B
- Compute residue of Result
- Compare predicted vs actual residue

If mismatch → `residue_error = 1`

✔ Detects multi-bit arithmetic faults  
✔ Higher coverage than parity alone  

---

# 🔎 Multi-Level Error Decision

Final fault signal:
