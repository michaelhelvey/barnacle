#![no_std]
#![no_main]

use core::{arch::global_asm, panic::PanicInfo};

global_asm!(include_str!("boot.s"));

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

/// Kernel entry point that is jumped to from the assembly trampoline after it sets up the stack.
#[no_mangle]
pub extern "C" fn kernel_entry() -> ! {
    unsafe {
        // Honestly I have no idea what a valid memory address I can write to is but I'll just pick
        // something under my kernel and above 0x1000, so as far as I know this is not reserved for
        // anything else
        core::ptr::write_volatile(0x1024 as *mut usize, 69);
    }
    loop {}
}
