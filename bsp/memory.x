/* RSD on run-rsd's harness: 256 KB of RAM from 0x8000_0000, where the boot
 * ROM jumps. The 8 bytes at 0x8000_1000 are tohost, an I/O address that does
 * not reach the RAM, so the program is placed from 0x8000_2000 and the first
 * word of the RAM jumps there. */

MEMORY
{
  JUMP (rx)  : ORIGIN = 0x80000000, LENGTH = 4K
  RAM  (rwx) : ORIGIN = 0x80002000, LENGTH = 256K - 8K
}

REGION_ALIAS("REGION_TEXT",   RAM);
REGION_ALIAS("REGION_RODATA", RAM);
REGION_ALIAS("REGION_DATA",   RAM);
REGION_ALIAS("REGION_BSS",    RAM);
REGION_ALIAS("REGION_HEAP",   RAM);
REGION_ALIAS("REGION_STACK",  RAM);

_max_hart_id     = 0;
_hart_stack_size = 8K;
_heap_size       = 0;

SECTIONS
{
  /* j 0x80002000, where riscv-rt's _start is */
  .jump ORIGIN(JUMP) : { LONG(0x0000206f) } > JUMP
} INSERT BEFORE .text.dummy;

ASSERT(_start == ORIGIN(RAM), "the jump at 0x8000_0000 does not reach _start");
