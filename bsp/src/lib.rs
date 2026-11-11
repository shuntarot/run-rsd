//! Board support for RSD under veryl-harness.
//!
//! An application depends on this crate and nothing else:
//!
//! ```ignore
//! #![no_std]
//! #![no_main]
//!
//! use rsd_bsp::{entry, exit, println};
//!
//! #[entry]
//! fn main() -> ! {
//!     println!("hello");
//!     exit(0)
//! }
//! ```
//!
//! `print!` goes to RSD's serial output, one character per store. The
//! characters wait in a FIFO in the harness until the host drains it
//! (`hio drain --text uart`). `getc` reads the serial input, one character
//! at a time from the host. `exit` writes tohost. `scripts/run.sh` does the
//! host's part of all three.

#![no_std]

use core::sync::atomic::{AtomicU8, Ordering};

pub use riscv;
pub use riscv_rt::entry;

/// RSD's serial output. It takes the low 8 bits of a word store.
const SERIAL: *mut u32 = 0x4000_2000 as *mut u32;
/// The serial input: a load gives {seq, char} as the host set it, and a
/// store of seq tells the host that the character was taken.
const SERIAL_IN: *mut u32 = 0x4000_2004 as *mut u32;
/// tohost, as riscv-tests use it: (status << 1) | 1 ends the program.
const TOHOST: *mut u32 = 0x8000_1000 as *mut u32;

/// Sends one byte to the serial output.
pub fn putc(c: u8) {
    // A whole word: RSD's I/O stores have no byte strobes.
    unsafe { SERIAL.write_volatile(u32::from(c)) }
}

/// Backend of `print!`. Not meant to be called directly.
#[doc(hidden)]
pub fn _print(args: core::fmt::Arguments) {
    use core::fmt::Write;
    let _ = Console.write_fmt(args);
}

struct Console;

impl core::fmt::Write for Console {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        s.bytes().for_each(putc);
        Ok(())
    }
}

/// The seq of the last character taken. Both sides start from 0 at reset.
static TAKEN: AtomicU8 = AtomicU8::new(0);

/// Reads one byte the host typed, or `None`. Never blocks.
pub fn getc() -> Option<u8> {
    let word = unsafe { SERIAL_IN.read_volatile() };
    let seq = (word >> 8) as u8;
    // The same seq is the character already taken. RSD may run this load
    // before the store below has gone out, and then sees that seq again.
    if seq == TAKEN.load(Ordering::Relaxed) {
        return None;
    }
    TAKEN.store(seq, Ordering::Relaxed);
    unsafe { SERIAL_IN.write_volatile(u32::from(seq)) }
    Some(word as u8)
}

/// Ends the program with `code`. `scripts/run.sh` exits with the same status.
pub fn exit(code: u8) -> ! {
    unsafe { TOHOST.write_volatile((u32::from(code) << 1) | 1) }
    #[allow(clippy::empty_loop)]
    loop {}
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => {
        $crate::_print(core::format_args!($($arg)*))
    };
}

#[macro_export]
macro_rules! println {
    ()            => { $crate::print!("\n") };
    ($($arg:tt)*) => { $crate::print!("{}\n", core::format_args!($($arg)*)) };
}

/// Any exception without its own handler: show where, then stop with 102.
#[export_name = "ExceptionHandler"]
fn exception_handler(trap_frame: &riscv_rt::TrapFrame) -> ! {
    use riscv::register::{mcause, mepc, mtval};
    println!();
    println!("*** exception ***");
    println!("  mcause {:#010x}", mcause::read().bits());
    println!("  mepc   {:#010x}", mepc::read());
    println!("  mtval  {:#010x}", mtval::read());
    println!("  ra     {:#010x}", trap_frame.ra);
    exit(102)
}

/// A panic stops with 101, as a panicking Rust program does.
#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    println!();
    println!("*** panic ***");
    println!("{info}");
    exit(101)
}
