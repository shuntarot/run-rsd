# Address map

This is RSD's own map (`MemoryMapTypes.sv`), with two I/O addresses added in
this repository: the serial input and `tohost` (`PATCHES` in
`scripts/flatten.py`). All addresses are the ones a program uses.

## Memory

| Address | Size | Region |
|---|---|---|
| `0x0000_1000` – `0x0000_FFFF` | 60 KB | Boot ROM. The core starts at `0x1000`. |
| `0x8000_0000` – `0x8003_FFFF` | 256 KB | RAM: the board's DRAM. |

Nothing else is mapped. The 8 bytes at `0x8000_1000` are I/O (`tohost`), not
RAM.

**Boot ROM.** `rtl/rsd_top.veryl` answers these reads. The ROM sets `mtvec`
to a loop, then jumps to `0x8000_0000`. The rest of the 60 KB reads as 0.

**RAM.** The data cache is 4 KB, writes back, and has no flush. The host
sees a store in the DRAM only after the cache has pushed that line out. To
pass data to the host, use an I/O address instead.

## I/O

| Address | Read | Write | Port of `rsd_top` | From |
|---|---|---|---|---|
| `0x4000_0000` | `mtime`, low 32 bits | `mtime`, low 32 bits | — | RSD |
| `0x4000_0004` | `mtime`, high 32 bits | `mtime`, high 32 bits | — | RSD |
| `0x4000_0008` | `mtimecmp`, low 32 bits | `mtimecmp`, low 32 bits | — | RSD |
| `0x4000_000C` | `mtimecmp`, high 32 bits | `mtimecmp`, high 32 bits | — | RSD |
| `0x4000_2000` | — | serial output: the low 8 bits | `o_uart_valid`, `o_uart_data` | RSD |
| `0x4000_2004` | serial input: `{16'h0, seq[7:0], char[7:0]}` | serial input ack: the low 8 bits | `i_rx`, `o_rx_ack` | added |
| `0x8000_1000` | the last value written | `tohost` | `o_tohost` | added |
| `0x8000_1004` | 0 | ignored | — | added |

**Timer.** `mtime` counts up by one every core clock cycle. A timer
interrupt is pending while `mtime >= mtimecmp`.

**Serial output.** Each store sends one character. It waits in a FIFO of
256 entries in the harness until the host reads it
(`hio drain --text uart`). The core cannot wait for room: when the FIFO is
full, the character is lost and `uart_drops` counts it.

**Serial input.** The host gives one character at a time:

1. The host writes `{seq, char}` to `i_rx`, with `seq` one more than the last
   time.
2. The program reads `0x4000_2004`. If `seq` is the same as the last one it
   took, there is nothing new. If not, it takes `char` and writes `seq` back
   to `0x4000_2004`.
3. The host sees that `seq` on `o_rx_ack`, and gives the next character.

Both sides start from `seq` 0. `rsd_bsp::getc` and `scripts/run.sh` do this.

**tohost.** The riscv-tests convention: 1 means pass, `(n << 1) | 1` means
test `n` failed. `rsd_bsp::exit(code)` writes `(code << 1) | 1`. The host
reads it with `hio read o_tohost`.

## Rules for I/O

RSD runs loads out of order and before it knows they are needed. I/O follows
from that:

- **Use `lw` and `sw` at the exact addresses above.** I/O stores carry no
  byte enables, so `sb` and `sh` are not defined.
- **A load from I/O must have no side effect.** The core may run it early,
  more than once, or on a path it then throws away. That is why the serial
  input uses `seq` and not "read to take".
- **Do not read back what you just wrote.** An I/O load can run before an
  older I/O store has gone out, and then sees the old value.
- **Stores go out in order.** An I/O store leaves the core when its
  instruction retires, in program order, and does not wait in the data cache.
- **Reading an address with no read value returns `mtimecmp` high.** For
  example `0x4000_2000`. This is the default branch of RSD's read mux, not a
  feature to rely on.
