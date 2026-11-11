// Smoke test for RSD on the FPGA harness.
// It runs from RAM at 0x8000_0000 (the boot ROM jumps there) and writes its
// results at 0x8000_1000:
//   +0x00: 0x21534e48 ("HNS!")
//   +0x04: misa
//   +0x08: mhartid
//   +0x0c: a word loaded from .rodata (0xc0ffee42)
//   +0x10: 1234 * 5678 / 7 (0x000f45f6)
//   +0x14: four byte stores (0x44332211)
//   +0x18: two halfword stores (0x66665555)
//   +0x1c: a store read back by the very next load (0x12345678)
//   +0x20: mcause of the timer interrupt raised through mtimecmp (0x80000007)
//   +0x24: 0x600d600d, written last
// The data cache writes back, so the program then reads 8 KB elsewhere, twice
// the size of the cache, to push the results out to memory. It also prints
// them on the serial output, one word per line, and then "done".
#define RESULT 0x80001000
#define SWEEP  0x80020000
#define TIMER  0x40000000
#define SERIAL 0x40002000

.section .text.start, "ax", @progbits
.globl _start
_start:
  li   sp, 0x80040000
  li   t0, RESULT
  li   t1, 0x21534e48
  sw   t1, 0x00(t0)
  csrr t1, misa
  sw   t1, 0x04(t0)
  csrr t1, mhartid
  sw   t1, 0x08(t0)
  la   t2, pattern
  lw   t1, 0(t2)
  sw   t1, 0x0c(t0)
  li   t1, 1234
  li   t2, 5678
  mul  t1, t1, t2
  li   t2, 7
  divu t1, t1, t2
  sw   t1, 0x10(t0)
  li   t1, 0x11
  sb   t1, 0x14(t0)
  li   t1, 0x22
  sb   t1, 0x15(t0)
  li   t1, 0x33
  sb   t1, 0x16(t0)
  li   t1, 0x44
  sb   t1, 0x17(t0)
  li   t1, 0x5555
  sh   t1, 0x18(t0)
  li   t1, 0x6666
  sh   t1, 0x1a(t0)
  li   t1, 0x12345678
  sw   t1, 0x1c(t0)
  lw   t2, 0x1c(t0)
  sw   t2, 0x1c(t0)

  // The timer interrupt. mtimecmp = mtime + 200; the high word goes to all
  // ones first, so the compare does not match half-written.
  la   t1, trap
  csrw mtvec, t1
  li   t1, 0x80            // mie: MTIE
  csrw mie, t1
  csrsi mstatus, 8         // MIE
  li   t2, TIMER
  lw   t1, 0(t2)
  lw   t3, 4(t2)
  addi t4, t1, 200
  sltu t1, t4, t1
  add  t3, t3, t1
  li   t1, -1
  sw   t1, 12(t2)
  sw   t4, 8(t2)
  sw   t3, 12(t2)
1:
  lw   t1, 0x20(t0)
  beqz t1, 1b

  li   t1, 0x600d600d
  sw   t1, 0x24(t0)

  // Push the results out of the data cache.
  li   t1, SWEEP
  li   t2, SWEEP + 8192
2:
  lw   zero, 0(t1)
  addi t1, t1, 8
  bne  t1, t2, 2b

  // Print the ten words.
  li   s0, RESULT
  li   s1, RESULT + 0x28
3:
  lw   a0, 0(s0)
  call puthex
  addi s0, s0, 4
  bne  s0, s1, 3b
  la   a0, done
  call puts
4:
  j    4b

// Prints a0 as eight hex digits and a newline.
puthex:
  li   t2, SERIAL
  li   t3, 8
5:
  srli t1, a0, 28
  slli a0, a0, 4
  addi t1, t1, '0'
  li   t4, '9'
  ble  t1, t4, 6f
  addi t1, t1, 'a' - '0' - 10
6:
  sw   t1, 0(t2)
  addi t3, t3, -1
  bnez t3, 5b
  li   t1, '\n'
  sw   t1, 0(t2)
  ret

// Prints the string at a0.
puts:
  li   t2, SERIAL
7:
  lbu  t1, 0(a0)
  beqz t1, 8f
  sw   t1, 0(t2)
  addi a0, a0, 1
  j    7b
8:
  ret

.balign 4
trap:
  csrr s2, mcause
  sw   s2, 0x20(t0)
  li   s3, TIMER
  li   s4, -1
  sw   s4, 12(s3)          // mtimecmp = all ones: no more
  sw   s4, 8(s3)
  mret

.section .rodata
.balign 4
pattern:
  .word 0xc0ffee42
done:
  .string "done\n"
