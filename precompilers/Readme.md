# Precompiler Examples

This directory contains sample programs illustrating the use of Oracle Precompilers (Pro*C and Pro*COBOL).
It also includes makefiles for building and compiling these samples into executables.

## Prerequisites

### Oracle Packages / Components

If you are using the Oracle Instant Client, install the following packages for your platform:

- **Basic**
- **SDK**
- **Precompiler**

### Compilers

- A  **C/C++ compiler** is required for the Pro*C samples.  
- A  **COBOL compiler** is required for the Pro*COBOL samples.  

### Minimum Required Version

The minimum required **Oracle Database** and **Oracle Client** versions are **19c** in both cases.

## Included Files

| File Name             | Description                                                                                   |
|-----------------------|-----------------------------------------------------------------------------------------------|
| [`procdemo.pc`](./procdemo.pc) | Sample Pro*C program demonstrating basic database operations using Oracle Precompiler. |
| [`procobdemo.pco`](./procobdemo.pco) | Sample Pro*COBOL program illustrating database interaction using Oracle Precompiler. |
| [`makefile_proc.mk`](./makefile_proc.mk) | Makefile for compiling the Pro*C example, managing dependencies, and generating the executable. |
| [`makefile_procob.mk`](./makefile_procob.mk) | Makefile for compiling the Pro*COBOL example, handling build processes, and producing the executable. |

## How to Compile and Run

To build the sample programs:

- Use `make -f makefile_proc.mk` for **Pro*C** samples.  
- Use `make -f makefile_procob.mk` for **Pro*COBOL** samples.  

Refer to the respective makefiles for more detailed instructions on compilation and execution steps.
