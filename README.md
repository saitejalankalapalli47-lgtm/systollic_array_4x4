# Systollic_Array_4x4
## Complete System Description

* The proposed system is an FPGA-based hardware accelerator designed to perform convolution on a **6×6 input image** and **3×3 weights** using a **4×4 systolic array architecture**. The system integrates both software and hardware components to achieve efficient computation.

* The overall design is divided into two main parts:

     **Processing System (PS):** MicroBlaze<br>
     **Programmable Logic (PL):** Custom hardware modules

* The Processing System is responsible for data preparation, control, and result interpretation, while the Programmable Logic performs high-speed parallel computation.

* The workflow begins with the input image, which is processed by the **MicroBlaze** processor. The image is converted into **Q8.8 fixed-point format** (16-bit hexadecimal values) to ensure compatibility with hardware arithmetic operations. These pixel values, along with convolution kernel weights, are transferred to the Programmable Logic using the **AXI interface**.

* Inside the Programmable Logic, the data is stored in **Block RAM (BRAM)** modules and then passed through buffers to a systolic array. The systolic array performs convolution using parallel **Multiply-Accumulate (MAC)** operations. The computed output is stored back in memory and later retrieved by the MicroBlaze processor for reconstruction into image format.

* This architecture ensures efficient data handling, reduced latency, and improved throughput compared to traditional processing methods.

  ---

## Data Flow Explanation
The system follows a structured data flow from input to output. Each stage is designed to ensure efficient processing and minimal delay.

### Step 1: Image Input and Conversion
- A 6×6 image is provided as input
- The MicroBlaze processor reads the image
- Pixel values are converted into Q8.8 fixed point format

### Step 2: Data Transfer to PL
- Pixel values are written into Pixel Input BRAM
- Kernel weights are written into Weight BRAM
- Data transfer is done via AXI interface

### Step 3: Data Loading into Buffers
- Pixel data is loaded into Line Buffer
- Weight data is loaded into Weight Buffer
- Buffers ensure continuous data availability

### Step 4: Systolic Array Computation
- Pixel values move horizontally
- Weight values move vertically
- Each Processing Element performs:
  - Multiplication
  - Accumulation
- Convolution operation is executed in parallel

### Step 5: Output Storage
- Computed values are stored in Output BRAM
- Data is ready for retrieval

### Step 6: Output Retrieval and Reconstruction
- MicroBlaze reads output values from BRAM via AXI
- Converts fixed point values back to pixel format
- Reconstructs output image

  ---

## Block Diagram of 4X4 Systollic Array

<img width="559" height="484" alt="image" src="https://github.com/user-attachments/assets/c7df319c-42c3-46a7-8fcf-bb2c1e80b6ed" />

---
## Complete Architecture Block Diagram 

<img width="536" height="229" alt="image" src="https://github.com/user-attachments/assets/f8304189-13bd-4bf3-8549-7fed05305ac0" />

---
## Overall Data Flow and Hierarchy

The complete system operates in a pipeline manner:

1. External system provides pixel and weight data to the top module.
2. Data is stored in respective BRAMs.
3. BRAM outputs are fed into line buffers.
4. Buffered data is streamed into the systolic array.
5. Parallel multiply-accumulate operations are performed.
6. Results are written into output BRAM.
7. Final output is read and provided externally.

The hierarchical organization can be summarized as:

```text
Top Module (bram_to_buf)
├── Pixel BRAM (BRAM_2_outdata)
├── Weight BRAM (BRAM_Buffer)
├── Line Buffers (multiple BRAM_Buffer)
├── PE Array (pe_array)
│   └── Processing Elements (PE)
└── Output BRAM (BRAM_Buffer)
```

---
## Complete FSM 

<img width="629" height="905" alt="image" src="https://github.com/user-attachments/assets/265947a4-0f42-4aa8-8317-0662f8a098f2" />

