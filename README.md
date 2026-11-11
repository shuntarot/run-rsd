# run-rsd

Runs the [RSD](https://github.com/shioyadan/RSD) RISC-V core (RV32IM, out of
order, superscalar) on FPGA boards with
[veryl-harness](https://github.com/shuntarot/uharness).

RSD's address map is its own: a boot ROM at 0x1000 (the reset vector), 256 KB
of RAM from 0x8000_0000, a timer at 0x4000_0000 and a serial output at
0x4000_2000. Here the RAM is the board's DRAM, and the boot ROM is a few
instructions in `rtl/rsd_top.veryl` that jump to 0x8000_0000. A program is
linked to run from 0x8000_0000 and loaded by the host while the core is held
in reset. What it writes to the serial output waits in a FIFO that the host
drains.

## Requirements

- Veryl, with `veryl-harness` and `hio`
- Vivado
- A board with room for the core (it does not fit the Arty A7-35; see the
  table below) on USB
- A RISC-V toolchain (`riscv64-unknown-elf-gcc`), to rebuild `asm/smoke.elf`
- Verilator 5, to run it without the board

## Run

```bash
veryl harness gen --target digilent/arty-a7-100
make -C hns/syn
hio program
hio run bringup.hio       # loads asm/smoke.elf, reads back what it wrote, drains the serial output
```

`make sim` runs the same program on `rsd_top` in Verilator, with an AXI4
memory in place of the DRAM.

## The core

`rtl/rsd.sv` is RSD's `Processor/Src` as one file, written by
`scripts/flatten.py` (`make rsd RSD=<RSD checkout>`). It is built as RSD
builds it for Vivado, with these changes:

- an 8-bit serial output, one character per store;
- no debug register outputs.

`rtl/rsd_axi.sv` puts RSD's core and its own AXI4 master behind plain ports.
`rtl/rsd_top.veryl` adds the boot ROM and sends the rest to the DRAM.

RSD's data cache writes back and has no flush. The host sees a store in the
DRAM only once the line has been pushed out of the 4 KB cache;
`asm/smoke.S` reads 8 KB elsewhere to do that.

## Size

LUT and FF counts, block RAM in 36 Kb blocks, after place and route. The core
is the DUT alone; the design adds the harness and the memory behind it.

| Target | Clock | Core LUT / FF / BRAM / DSP | Design LUT / FF / BRAM / DSP |
|---|---|---|---|
| `digilent/arty-a7-100` | 40 MHz | 15,659 / 7,760 / 10 / 4 | 22,930 / 15,352 / 10 / 4 |
| `digilent/pynq-z1` | 40 MHz | 15,667 / 7,760 / 10 / 4 | 17,364 / 10,651 / 10 / 4 |
| `xilinx/vcu118` | 40 MHz | 15,214 / 7,796 / 9 / 4 | 35,194 / 31,932 / 34.5 / 7 |

The Arty A7-35 has 20,800 LUTs; the design needs about 23,900 there. The
PYNQ-Z1 misses 50 MHz by a little inside the core, so the clock is 40 MHz.

The PYNQ-Z1's DRAM is in the PS and not counted.

## Files

| | |
|---|---|
| `rtl/rsd_top.veryl`, `Harness.toml` | the DUT with its boot ROM, and where each port goes |
| `rtl/rsd_axi.sv` | RSD's core and AXI4 master behind plain ports |
| `rtl/rsd.sv`, `scripts/flatten.py` | RSD as one file, and the script that writes it |
| `asm/`, `sim/` | the test program, and the DUT in Verilator |

Put paths for your machine in `local.mk`; see `Makefile`.

## License

MIT (`LICENSE`). RSD (`rtl/rsd.sv`) and `rtl/rsd_axi.sv`, which is adapted
from it, are under the Apache License 2.0 (`rtl/LICENSE.RSD`).
