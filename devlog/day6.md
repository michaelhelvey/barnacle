# Day 6: Booting Rust

My goal for today is to get Rust code running on my emulator. If I'm particularly successful, maybe
I can even write a serial driver and get some output printing to the console, but that's honestly
more than I expect to be able to get done in one day.

First, I'll write a simple no_std main file:

```rust
#![no_std]
#![no_main]

use core::{panic::PanicInfo};

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
```

Beautiful bootloader there, we're basically done. :) After putting a default build target of
`aarch64-unknown-none` in my `.cargo/config.toml` file, we at least have it building, but now I need
to somehow run this thing, and to do that, I need to run an assembly trampoline. Now in C I'd just
write an assembly file and link it in my makefile along with everything else but I have no idea how
to do that with cargo.

Turns out, however, that I can just `include_str` an asm file directly into my rust file and that
just...works. Rust is sick. But now I also need to figure out how to pass linker options to Rust so
that my code is loaded at the right address and what not.

Ah, so apparently you can include a `-C link-arg=--script=./some-linker-script.ld` in your
rustflags, and that will use the relevant linker script. Easy enough.

[45 minutes pass, curse words are said, I go get another coffee]

Ok so I added this line to my `main.rs` file:

```rust
global_asm!(include_str!("boot.s"));
```

It took me a while to figure out why the first code above produced a file with no code in it. Turns
out because I didn't include the expected symbol (\_start) that the Rust linker wanted, everything
just got optimized out, which makes total sense now that I think about it. It's always the painfully
obvious things that get you. But once I included an assembly file that jumped into my `kernel_entry`
function, everything proceded as normal. My linker script even worked!

Progress so far:

```
// .cargo/config.toml
[build]
target = "aarch64-unknown-none"

[target.aarch64-unknown-none]
rustflags = ["-C", "link-arg=--script=./crates/boot/linker.ld"]
```

```
// ./crates/boot/linker.ld
ENTRY(_start)

SECTIONS {
    . = 0x80000;
    .text : {
        *(.text)
    }
}
```

```asm
// ./crates/boot/src/boot.s
.text
.globl _start

_start:
    mov x0, #42            // load 42 into register x0
    nop                    // do nothing so I can inspect x0

    // Yes, yes, this is wrong I need to set up the stack and do all the things, I'm just
    // testing compilation output here!

    bl kernel_entry        // jump into Rust
```

And finally, I can use `cargo-binutils` dump my output,
`cargo objdump --bin boot --release -- --disassemble --no-show-raw-insn --print-imm-hex`:

```
boot:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000080000 <_start>:
   80000:      	mov	x0, #0x2a               // =42
   80004:      	nop
   80008:      	bl	0x8000c <kernel_entry>

Disassembly of section .text.kernel_entry:

000000000008000c <kernel_entry>:
   8000c:      	mov	w8, #0x1024             // =4132
   80010:      	mov	w9, #0x45               // =69
   80014:      	str	x9, [x8]
   80018:      	b	0x80018 <kernel_entry+0xc>
```

Beautiful. It's loading it at the right address and everything. Hopefully all I need to do now is
write a proper trampoline and probably flesh out the linker script to align data sections and what
not. I will be shamelessly following the
[osdev wiki raspberry PI bare bones documentation](https://wiki.osdev.org/Raspberry_Pi_Bare_Bones)
to do this.

Here's my final trampoline code for the day:

```asm
.section ".text"
.globl _start

// Assembly trampoline for setting up the stack and jumping into Rust
// Note: supposedly we get started with a pointer to the DTB file in x0 by the GPU.  I haven't
// tested this, but I won't clobber the register for now just in case
// My understanding is also that it automatically starts the other CPU cores in a spin loop so
// I don't have to manually stop them.  I guess we'll find out :)
_start:
    // Stack setup:
    ldr x5, =_start        // Set stack pointer to our _start
    mov sp,x5

    // Init anything in the BSS section to 0, based on the addresses from the linker script:
    ldr x5,=__bss_start
    ldr w6,=__bss_size
1:
    cbz     w6, 2f          // If BSS section is 0, skip
    str     xzr, [x5], #8   // Store 0 into x5 then increment by 8 bytes
    sub     w6, w6, #1
    cbnz    w6, 1b          // Loop until bss is clear
2:
    bl kernel_entry        // jump into Rust

```

With that, and a
`qemu-system-aarch64 -machine raspi3b -cpu cortex-a53 -nographic -kernel target/aarch64-unknown-none/release/boot -s -S`
and a `gdb-remote` from my debugger, I can step through all the instructions, and then here we are!
There's that `core::ptr::write_volatile` from Rust! Our bootloader is executing Rust!

```
Process 1 stopped
* thread #1, stop reason = instruction step over
    frame #0: 0x0000000000080040
->  0x80040: mov    w9, #0x45                 ; =69
    0x80044: str    x9, [x8]
    0x80048: b      0x80048
```

I feel like this is a pretty big milestone, honestly. Tomorrow I can start on a serial driver.
