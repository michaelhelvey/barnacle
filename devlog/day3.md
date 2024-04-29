## Day 3 (4/26/24): Learning QEMU Properly

The main thing that I learned from the first couple of days is that I need to stop fighting with my
development environment and copy/pasting randoming magic commands from the internet and properly
learn my tools, starting with qemu.

So today, I'm going to sit down with the
[system emulation section](https://www.qemu.org/docs/master/system/index.html) of the qemu docs, and
read until I understand how to use qemu at a decent level. For example, I want to know how to write
some code in qemu and step through it in a debugger. Ultimately, I want to feel comfortable booting
a small Linux system from scratch through qemu, emulating fairly traditional hardware.

The following simply represents some reading notes based on reading through the documentation. I
won't attempt to summarize the documentation itself or re-explain it.

- There are many
  [example command lines](https://www.qemu.org/docs/master/system/targets.html#system-targets-ref)
  in the "System Emulator Targets" section of the manual. This a goldmine of resources about to
  emulate various different kinds of boards and system configurations, including the raspberry pi.

- The general form of a qemu command to start a machine is as follows:

```shell
$ qemu-system-x86_64 [machine opts] \
                [cpu opts] \
                [accelerator opts] \
                [device opts] \
                [backend opts] \
                [interface opts] \
                [boot opts]
```

Having read through the entirety of the "introduction" to qemu, I already feel like I know more not
only about qemu itself, but how computers boot in general. I have the Linux kernel documentation
pulled up on the side so I can look up how various things correspond to the Linux boot process, and
it's incredibly helpful. I can't believe I tried to boot Raspberry Pi OS for 2 days without just
doing this to begin with.

Having read a fair bit of documentation, the next thing I'm going to do to test out my knowledge is
attempt to run some bare metal code. Can I execute some instructions on a chip using qmeu, and debug
it? I want to avoid any of the config.txt, bootcode.bin, or any of the other "magic" as much as
possible...I'm more than happy to use those things once I understand them but I don't really feel
like I understand them yet.

First things first, I need to know where to put my instructions on the machine. Presumbably this CPU
is going to start executing instructions at some address once it powers on. I need to figure out how
to put some stuff there that I want to execute. I downloaded the official ARM architecture
reference, but that was 14k pages long, and so it's not very useful for a beginner like me who
doesn't really know what to look up to begin with.

Thankfully there was a "baremetal raspberry PI"
[guide written by dwelch67 on github](https://github.com/dwelch67/raspberrypi/blob/master/baremetal/README)
that told me everything I needed to know about the PI boot process for my use-cases. Apparently the
broad strokes, as they are relevant to my current project, is the following:

- When the device powers on, it starts the GPU, with the ARM Core _off_, and the SDRAM disabled.
- The GPU then runs some code on the SoC ROM that reads some files off of the SD card.
- Then it (the GPU) executes bootcode.bin, start.elf, etc, which enables SDRAM and loads the
  `kernel.img` file (whatever user code you give it) into memory at 0x8000. This seems to be more or
  less a magic number that was chosen because it's the Linux default, and the PI is more or less
  built to run Linux. The GPU seems to use the memory below that address to store things like
  `cmdline.txt` and other configuration.
- Anyway, so if I put some code at 0x8000 and run the machine, it should work, right?

Turns out, yes! I wrote the smallest program possible just to test out this theory.

```asm
# Bare metal hello world "kernel" (e.g. bootloader) that GPU ROM
# loads into memory at 0x8000 (linux default) and executes during
# PI boot process
.align 4
.text
.globl _start

_start:
    mov x0, #42            // load 42 into register x0
    nop                    // do nothing so I can inspect x0
```

Then I goofed around trying to build this with MacOS tools until I just gave up and installed
`aarch64-elf-binutils` via `homebrew` so I could do things using the more standard GNU toolchain.

With that I could write a `makefile` to build my little program into a valid `kernel.img`. First I
needed the linker to position the instructions at the right address (as far as I know, this wouldn't
matter for this particular program because I'm not doing anything, but as soon as I wrote any
position dependent code it would, so I might as well just start out correct):

Here's the linker script:

```
ENTRY(_start)

SECTIONS {
    . = 0x8000;
    .text : {
        *(.text)
    }
}
```

And the makefile:

```makefile
all: kernel.img

clean:
	rm -f *.o
	rm -f *.img
	rm -f *.macho

kernel.img: linker.ld main.o
	aarch64-elf-ld -T linker.ld -o main.macho main.o
	aarch64-elf-objcopy main.macho -O binary kernel.img

main.o: main.s
	aarch64-elf-as -D -o main.o main.s
```

With that, I can run qemu, specifying my custom kernel, and set it up to expose a debugger on port
1234, and to pause execution until I connect to the debugger:

```shell
qemu-system-aarch64 -machine raspi3b -cpu cortex-a53 -nographic -kernel kernel.img -s -S
```

Then I could connect via `lldb`, run `gdb-remote localhost:1234` to connect to qemu, and step
through the first few initial instructions that jump to 0x8000 just like I was told would happen,
and then I saw this beautiful sight:

```
(lldb) n
Process 1 stopped
* thread #1, stop reason = instruction step over
    frame #0: 0x0000000000080000
->  0x80000: mov    x0, #0x2a                 ; =42
    0x80004: nop
    0x80008: udf    #0x0
    0x8000c: udf    #0x0
```

42, being moved into x0, just like I had written. This is a long way from a functional computer
program that does anything useful at all, but I'm compiling instructions and running them on an
emulated raspberry PI, and stepping through it with a debugger. I have a tremendous amount to learn
but I feel like I've made my first real step towards writing an OS on this thing. If I can run
assembly, surely Rust isn't far off ;)

Before I get into Rust, I kinda want to try and make my assembly do something a little more useful.
For example, I may not know what I'm doing, but I at least need to know that I need to figure out
the memory map of the machine a little, what addresses I'm allowed to use, what I'm not allowed to
use, how to manage the different CPU cores, etc. etc. Once I feel like I've wrapped my head around
that with some simple assembly programs, I'll work on figuring how to write a trampoline to get Rust
running.
