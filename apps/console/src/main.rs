//! Checks that startup set up the sections, then echoes what you type.
//! Typing `q` exits with status 0.

#![no_std]
#![no_main]

use core::ptr::addr_of;

use rsd_bsp::{entry, exit, getc, print, println};

/// In .rodata: neither copied nor cleared.
static RODATA: u32 = 0xaaaa_5555;
/// In .data: copied from its load address.
static mut DATA: u32 = 0x1234_5678;
/// In .bss: cleared.
static mut BSS: u32 = 0;

#[entry]
fn main() -> ! {
    println!("RSD console");

    // SAFETY: one hart and no interrupts, so nothing else touches them.
    let (data, bss) = unsafe {
        (
            addr_of!(DATA).read_volatile(),
            addr_of!(BSS).read_volatile(),
        )
    };
    let ok = RODATA == 0xaaaa_5555 && data == 0x1234_5678 && bss == 0;
    println!(
        "  sections  .rodata {RODATA:#010x} .data {data:#010x} .bss {bss:#010x} -> {}",
        if ok { "ok" } else { "WRONG" }
    );

    println!("type something; q exits");
    loop {
        if let Some(key) = getc() {
            if key == b'q' {
                println!();
                exit(if ok { 0 } else { 1 })
            }
            print!("{}", key as char);
        }
    }
}
