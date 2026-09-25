## Hardware & Architecture Overview

This project implements a **Multi-Protocol Conversion Unit** designed to translate serial communications dynamically between common embedded protocols.

## MPCU Block Diagram

```mermaid
flowchart LR
  SPI_M[SPI Master Data] --> SPI_IN[SPI Input Converter]
  I2C_M[I2C Master Data] --> I2C_IN[I2C Input Converter]
  UART_M[UART Rx Data] --> UART_IN[UART Input Converter]
  SPI_IN --> DEMUX["CTRL SIGS<br/>(2-bit) SELECT<br/>(DEMUX)"]
  I2C_IN --> DEMUX
  UART_IN --> DEMUX
  DEMUX --- BUS[DATA BUS]
  BUS --> SPI_OUT[SPI Output Converter] --> SPI_S[SPI Slave Data]
  BUS --> I2C_OUT[I2C Output Converter] --> I2C_S[I2C Slave Data]
  BUS --> UART_OUT[UART Output Converter] --> UART_S[UART Tx Data]
```

### Hardware Platform
- **FPGA Board:** Digilent Arty A7-100T (Xilinx Artix-7 FPGA)
- **System Clock:** 100 MHz

### Supported Protocols & Conversion Topology
The system supports bidirectional conversion across three standard communication interfaces:
- **UART**
- **SPI**
- **I2C**

#### Key Features:
- **One-to-One Conversion:** Direct translation between any single protocol pair (e.g., UART to SPI, SPI to I2C, I2C to UART).
- **One-to-All Conversion:** Simultaneous broadcast/conversion from one primary protocol to all three remaining targets (e.g., UART input replicated to SPI and I2C outputs concurrently).
