## Preface

I want to learn embedded software development, specifically with Rust. Now, unlike other posts on
this blog, I'm not going to be writing about something I know how to do, but instead something that
I have _no idea_ how to do.

### Goal

_It's hard to write a specific goal for something that you don't really understand, but here goes._

- Target hardware: Raspberry Pi 3b+ (Broadcom BCM2837B0 chip, Cortex A-53 CPU)
- 64 bit kernel
- Boots at least on quemu's `raspi3b` machine type, although I do have a real one in the closet,
  stretch goal would be booting on real hardware
- Utilizes all 4 cores of the CPU
- Reads and writes over UART
- Can run arbitrary user space programs in ARM user mode (I think that's a thing?) with cooperative
  multi-tasking (no pre-emption or fancy scheduling).

Stretch goal: userspace TCP stack that I can use to send messages to the OS from my other machines.

_Explicit non-goals, just to be clear_:

- Anything involving USB
- File system
- Graphics

### Context

Where I'm coming from:

- I've lurked around on the osdev wiki, reading articles for the past couple of years.
- I've watched [gamozolabs](https://twitter.com/gamozolabs) build fuzzing systems on Twitch off and
  on.
- I've occassionally browsed through things like the minix source code, or read a chapter of
  Tanenbaum's "Modern Operating Systems" here or there, but I don't think I retained a lot.
- I'm a pretty competent user of systems languages and I can mostly _read_ arm64 assembly assuming I
  have the reference documentation handy.
- I have no idea about the raspberry PI in general -- all I've ever done is run linux & pihole on
  it, so I'm not familiar in general with using a PI for embedded development at all.

So to sum up, I have no idea what I'm doing. I expect there will be a good deal of floundering going
on this this devlog.

As a result, my plan here is to (rather than post articles), simply to append to this post here,
perhaps splitting it occassionally when I get to good stopping points so it doesn't get too long,
just to summarize how each day of development goes.

### Code

I'm currently keeping all the code for the project
[here](https://github.com/michaelhelvey/barnacle). Why is it called "barnacle"? Because I have no
idea what to name this and that's what Github suggested when I created the repository. Maybe I'll
think of a good name as I go along and re-christen it.
