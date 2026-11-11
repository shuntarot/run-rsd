# run-rsd

Runs the [RSD](https://github.com/shioyadan/RSD) RISC-V core (RV32IM, out of
order, superscalar) on FPGA boards with
[veryl-harness](https://github.com/shuntarot/uharness).

The host loads a program with `hio`, and the program talks to the host
through a serial output and input.

## Address map

What a program sees. Each register is described in
[doc/address.md](doc/address.md).

| Address | Size | What | Here it is |
|---|---|---|---|
| `0x0000_1000` – `0x0000_FFFF` | 60 KB | Boot ROM; the core starts at `0x1000` | a jump to `0x8000_0000` (`rtl/rsd_top.veryl`) |
| `0x4000_0000` – `0x4000_000F` | 16 B | Timer: `mtime`, `mtimecmp` | in the core |
| `0x4000_2000` | 4 B | Serial output | a FIFO the host reads |
| `0x4000_2004` | 4 B | Serial input | a register the host writes |
| `0x8000_0000` – `0x8003_FFFF` | 256 KB | RAM, through a 4 KB write-back data cache | the board's DRAM |
| `0x8000_1000` – `0x8000_1007` | 8 B | `tohost`, inside the RAM range but I/O | a register the host reads |

Nothing else is mapped. A program runs from `0x8000_0000`. Use `lw` / `sw`
for I/O: there are no byte enables.

## Requirements

- Veryl, with `veryl-harness` and `hio`
- Vivado
- A board with room for the core (it does not fit the Arty A7-35; see the
  table below) on USB
- A RISC-V toolchain (`riscv64-unknown-elf-gcc`), to rebuild `asm/smoke.elf`
- Rust (rustup), for the programs in `apps/`
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

## Programs in Rust

`bsp/` starts a Rust program and gives it `print!` on the serial output,
`getc` on the serial input, and `exit`, through `tohost`. `cargo run` loads
the program, prints its serial output and sends it what you type until it
exits, and exits with its status (`scripts/run.sh`). Ctrl-C leaves.

```bash
cargo run -p hello
cargo run -p console      # echoes what you type; q exits
make -C sim elf ELF=../target/riscv32im-unknown-none-elf/debug/console RX='hi q'   # in Verilator
```

RSD has no debug module, so `hio cpu boot` does not apply. Nor does the RTT
console: the host cannot see what is in the data cache. The input is one
character at a time, each a few round trips to the board: fast enough to type,
not to send a file. The program is placed from 0x8000_2000, after `tohost`;
the word at 0x8000_0000 jumps there.

## riscv-tests

The tests report through `tohost` at 0x8000_1000. Here that word is an I/O
address, so a store to it leaves the core at once, and `o_tohost` shows the
last value (a register in the harness).

```bash
scripts/riscv-tests.sh <riscv-tests>/share/riscv-tests/isa    # on the board
make -C sim isa ISA=<riscv-tests>/share/riscv-tests/isa      # in Verilator
```

Both pass rv32um-p (8/8) and all of rv32ui-p but `fence_i` and `ma_data`:
RSD's `fence.i` does not make stores visible to fetches, and RSD has no
misaligned loads or stores. `rv32ui-p-ld_st` is linked with `tohost` at
0x8000_2000 and is skipped.

## The core

`rtl/rsd.sv` is RSD's `Processor/Src` as one file, written by
`scripts/flatten.py` (`make rsd RSD=<RSD checkout>`). It is built as RSD
builds it for Vivado, with these changes:

- an 8-bit serial output, one character per store;
- no debug register outputs;
- `tohost` (the 8 bytes at 0x8000_1000) is an I/O address with an output
  port;
- a serial input at 0x4000_2004, with an input port and an output port
  ([doc/address.md](doc/address.md)).

The changes are `PATCHES` in the script.

`rtl/rsd_axi.sv` puts RSD's core and its own AXI4 master behind plain ports.
`rtl/rsd_top.veryl` adds the boot ROM and sends the rest to the DRAM.

RSD's data cache writes back and has no flush. The host sees a store in the
DRAM only once the line has been pushed out of the 4 KB cache;
`asm/smoke.S` reads 8 KB elsewhere to do that. Stores to I/O addresses (the
serial output, `tohost`) do not wait in the cache.

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
| `doc/address.md` | the address map, register by register |
| `rtl/rsd_top.veryl`, `Harness.toml` | the DUT with its boot ROM, and where each port goes |
| `rtl/rsd_axi.sv` | RSD's core and AXI4 master behind plain ports |
| `rtl/rsd.sv`, `scripts/flatten.py` | RSD as one file, and the script that writes it |
| `asm/`, `sim/` | the test program, and the DUT in Verilator |
| `bsp/`, `apps/` | Rust programs: the startup, `hello` and `console` |
| `scripts/run.sh`, `scripts/riscv-tests.sh` | a program, and riscv-tests, on the board |

Put paths for your machine in `local.mk`; see `Makefile`.

## License

MIT (`LICENSE`). RSD (`rtl/rsd.sv`) and `rtl/rsd_axi.sv`, which is adapted
from it, are under the Apache License 2.0 (`rtl/LICENSE.RSD`).
