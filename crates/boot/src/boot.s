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
