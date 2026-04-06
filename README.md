# 🔐 Fault-Tolerant ALU  
### Multi-Level Error Detection using Parity Prediction, Carry Checking & Residue Codes (mod-3 / mod-5)

✔ Full RTL → GDSII implementation using Cadence Innovus  

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

For addition: (A + B) mod m == (A mod m + B mod m) mod m


Where `m = 3 or 5`

**Process:**
- Compute residue of A  
- Compute residue of B  
- Compute residue of Result  
- Compare predicted vs actual  

If mismatch → `residue_error = 1`

✔ Detects multi-bit arithmetic faults  
✔ Higher coverage than parity alone  

---

## 🔎 Multi-Level Error Decision

```verilog
error_flag = parity_error 
           | carry_error 
           | residue3_error 
           | residue5_error;
🏭 RTL → GDSII Design Flow
SystemVerilog RTL
        ↓
Functional Simulation
        ↓
Synthesis
        ↓
Floorplanning
        ↓
Placement
        ↓
Clock Tree Synthesis (CTS)
        ↓
Routing
        ↓
Static Timing Analysis (STA)
        ↓
Physical Verification (DRC/LVS)
        ↓
GDSII Generation

📊 Physical Design Results
📐 Area
Total Cell Area : 6868.11 µm²
Total Instances : 979 cells
⚡ Timing
Clock Frequency : 100 MHz
Worst Setup Slack : +0.061 ns ✅
Timing Status : Met
🧪 Verification
DRC Violations : 0 ✅
Connectivity : Clean ✅
🔌 Power
Supply Voltage : 0.9V
⚠ Power net connection warnings observed (requires globalNetConnect refinement)

<p align="center">
  <img src="https://github.com/user-attachments/assets/1b09e07e-c886-4b31-86c0-03c3a013c851" width="800"/>
</p>

🧪 Fault Coverage
Parity → detects bit-level errors
Carry checking → detects arithmetic faults
Residue codes → detects multi-bit errors

✔ Combined approach significantly improves fault detection coverage

🧰 Tools & Technologies
RTL Design : Verilog
Simulation : ModelSim / XSIM
Synthesis : Cadence / Synopsys / Vivado
Physical Design : Cadence Innovus
Verification : Custom Testbench
