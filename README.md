# TileLink-UH-Slave

This repository contains a slave interface for communicating with RISCV cores that implement the TileLink UH protocol (Version 1.9.3).

The slave contains 16 registers of 32 bits. It implements all UH operations minus Hints. It has logic for verification if the Master is trying to Put in unaligned directions.
