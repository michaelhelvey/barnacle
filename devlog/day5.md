## Day 5 (4/30/24): I'm Not Even Sure Anymore

There is a day 4, I did work on this, but I just read the DeviceTree specification, and a bunch of
existing code on Github.
[Download a DTB spec here](https://github.com/devicetree-org/devicetree-specification/releases/tag/v0.4).

This allows me to read the files like
[this one](https://github.com/raspberrypi/linux/blob/6d523c00412b5c6bc2e3020bbc1b48abd8b68804/arch/arm/boot/dts/broadcom/bcm2837.dtsi)
in the Raspberry Pi Linux distribution to get an idea of the memory map for the device -- what
memory I can and can't use.

There's also this mailbox property interface that I can use to query certain attributes of the
system, which seems more applicable to what I'm doing now since I haven't written a DTB file parser
yet: https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface#get-arm-memory. I'm
sensing that writing a DTB file parser at some point in my future is inevitable, however.

Here are my notes about the memory map that I've gathered from de-compiling the 3-b-plus device
tree:

The first 4KB of memory, up to 0x1000, are reserved. I'm not exactly sure for what. Then we have the
following lines in the `soc` section of the DTB:

```
ranges = <0x7e000000 0x3f000000 0x1000000 0x40000000 0x40000000 0x1000>;
dma-ranges = <0xc0000000 0x00 0x3f000000 0x7e000000 0x3f000000 0x1000000>;
```

The specification says that these are triplets of (parent-bus-address, child-bus-address, length)
that map between the address space of a bus and the main memory space.

So, then, I gather that starting at 0x3f00_0000 and extending to 0x4f00_0000, we have some bus
memory, and then for an additional 4KB after 0x4000_0000 we have some more memory reserved for a
bus. I think that that means that 0x3f00_0000 is the MMIO base address?

What I'm a bit more confused about is where the GPU memory is. It's my understanding that the
VideoCore and the ARM share the same address space. Thankfully there _is_ a VideoCore mailbox at
0x7e00b880 (bus address, this would be MMIO base + 0xb880 in the ARM space) and I'm guessing I can
ask it questions about what it's using? Here are the
[docs for the mailbox property interface](https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface).
There's a request for "Get VC memory" that apparently returns a base address into wherever the VC
memory is.

So based on all this, I have the following vague idea of where I'm at:

1. In 64-bit mode, the "kernel" (kernel.img) will be loaded at 0x80000 (physical memory).
2. MMIO starts at 0x3f000000 (physical memory).
3. I assume we can remap some of this stuff later if we want to, that's what our bootloader will do.
4. When I boot up I'll need to ask VideoCore where it's base address starts for the framebuffer.
   Apparently this is dynamically allocated, but I'll be very intersted to know _where_ in physical
   memory it gets allocated.
5. Once I boot I need to design a reasonable virtual-to-physical memory map for my application and
   remap the kernel and the stack etc so that it fits into that space. I'll need to read the ARM MMU
   docs to figure out how / where these page tables should go.

I found two very useful projects where folks are doing this already in very simple C:

- https://github.com/bztsrc/raspi3-tutorial
- https://github.com/brianwiddas/pi-baremetal

I'll definitely be making use of this stuff once I start into the above list. I think the next step
is honestly starting on an assembly trampoline to set up a stack so that I can run Rust, as I think
writing some exploratory Rust bootloaders might be the next logical step to check my assumptions,
and I'm reasonably confident in my ability to at least get basic bootloader code running at this
point.
