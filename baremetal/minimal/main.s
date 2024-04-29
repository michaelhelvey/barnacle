# Bare metal hello world "kernel" (e.g. bootloader) that GPU ROM
# loads into memory at 0x8000 (linux default) and executes during
# PI boot process
.align 4
.text
.globl _start

_start:
    mov x0, #42            // load 42 into register x0
    nop                    // do nothing so I can inspect x0
