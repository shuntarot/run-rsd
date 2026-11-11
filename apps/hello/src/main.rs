//! The smallest program: one line on the serial output, then exit status 0.

#![no_std]
#![no_main]

use rsd_bsp::{entry, exit, println};

#[entry]
fn main() -> ! {
    println!("hello from RSD");
    exit(0)
}
