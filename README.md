# 🔐 Fault-Tolerant ALU  
### Multi-Level Error Detection using Parity Prediction, Carry Checking & Residue Codes (mod-3 / mod-5)

This project implements a **Fault-Tolerant Arithmetic Logic Unit (ALU)** in SystemVerilog with multiple parallel error detection techniques designed for reliable digital systems.

---

## 🚀 Key Features

- ✅ Parity Prediction  
- ✅ Carry Chain Checking  
- ✅ Residue Code Checking (mod-3 and mod-5)  
- ✅ Multi-Level Error Decision Logic  

---

## 🎯 Applications

- Fault-resilient VLSI systems  
- AI accelerator datapaths  
- Safety-critical arithmetic units  
- FPGA/ASIC research implementations  

---

## 🏗 Architecture Diagram

![Fault Tolerant ALU](https://github.com/user-attachments/assets/0f08a08c-4b6c-4635-a4a8-51df241f3ad9)

---

## 🧠 System Overview

The design consists of two primary sections:

---

### 1️⃣ ALU Core (Functional Unit)

- Performs arithmetic and logical operations  
- Generates result and internal carry chain  
- Parameterizable bit-width (8/16/32-bit scalable)  

#### Supported Operations

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

### 2️⃣ Error Detection Units (Parallel Checking)

Three independent mechanisms validate computation simultaneously.

---

#### 🔹 Parity Prediction

- Input parity: `P(A) ⊕ P(B)`  
- Compared with: `P(Result)`  

If mismatch → `parity_error = 1`

✔ Low area overhead  
✔ Fast detection  
⚠ May miss some multi-bit symmetric errors  

---

#### 🔹 Carry Chain Checking

- Monitors internal carry propagation  
- Ensures carry consistency across stages  

If invalid relation → `carry_error = 1`

✔ Strong for arithmetic datapath faults  

---

#### 🔹 Residue Code Checking (mod-3 & mod-5)

For addition:
