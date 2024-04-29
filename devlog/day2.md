## Day 2 (4/26/24): Day 2 of Figuring how to boot linux

When I left off last time, I had some files, and I needed to try and turn them into a bootable
image.

I had a better idea since last time than just tryand figure out from scratch what's going on here,
why don't I download one of the images from their download page and see what's in there?

I'm not very familiar with the macos commands for all this, so I think what I'll do is spin a docker
container with linux in it, and mount my local directory into it, so I can use familiar linux
commands.

```shell
docker run --cap-add SYS_ADMIN --privileged --name osdev -v ./:/var/project -d --rm -it ubuntu:latest /bin/bash
```

Now I can `docker exec` into that and have linux commands, like `fdisk` that work in the expected
way.

I grabbed a "Raspberry PI OS Lite" image from the official downloads page, and now I can inspect it:

```shell
root@0af89a5fdacb:/var/project# unxz ./2024-03-15-raspios-bookworm-armhf-lite.img.xz
root@0af89a5fdacb:/var/project# fdisk -l ./2024-03-15-raspios-bookworm-armhf-lite.img
Disk ./2024-03-15-raspios-bookworm-armhf-lite.img: 2.37 GiB, 2541748224 bytes, 4964352 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x662b4900

Device                                        Boot   Start     End Sectors  Size Id Type
./2024-03-15-raspios-bookworm-armhf-lite.img1         8192 1056767 1048576  512M  c W95 FAT32 (LBA)
./2024-03-15-raspios-bookworm-armhf-lite.img2      1056768 4964351 3907584  1.9G 83 Linux
```

Ok, so we have a boot partition and a a linux partition, that makes sense. Let's see what's in the
boot partition first, since that's what we're trying to build here.

```shell
root@0af89a5fdacb:/var/project# mount -v -o offset=4194304 ./2024-03-15-raspios-bookworm-armhf-lite.img /mnt/rasp
mount: /dev/loop1 mounted on /mnt/rasp.

root@0af89a5fdacb:/var/project# ls -lah /mnt/rasp
total 93M
drwxr-xr-x 3 root root 6.0K Jan  1  1970 .
drwxr-xr-x 1 root root 4.0K Apr 26 11:07 ..
-rwxr-xr-x 1 root root 1.6K Mar 15 14:59 LICENCE.broadcom
-rwxr-xr-x 1 root root  29K Mar  7 14:51 bcm2708-rpi-b-plus.dtb
-rwxr-xr-x 1 root root  29K Mar  7 14:51 bcm2708-rpi-b-rev1.dtb
-rwxr-xr-x 1 root root  29K Mar  7 14:51 bcm2708-rpi-b.dtb
-rwxr-xr-x 1 root root  29K Mar  7 14:51 bcm2708-rpi-cm.dtb
-rwxr-xr-x 1 root root  31K Mar  7 14:51 bcm2708-rpi-zero-w.dtb
-rwxr-xr-x 1 root root  29K Mar  7 14:51 bcm2708-rpi-zero.dtb
-rwxr-xr-x 1 root root  31K Mar  7 14:51 bcm2709-rpi-2-b.dtb
-rwxr-xr-x 1 root root  31K Mar  7 14:51 bcm2709-rpi-cm2.dtb
-rwxr-xr-x 1 root root  31K Mar  7 14:51 bcm2710-rpi-2-b.dtb
-rwxr-xr-x 1 root root  34K Mar  7 14:51 bcm2710-rpi-3-b-plus.dtb
-rwxr-xr-x 1 root root  33K Mar  7 14:51 bcm2710-rpi-3-b.dtb
-rwxr-xr-x 1 root root  31K Mar  7 14:51 bcm2710-rpi-cm3.dtb
-rwxr-xr-x 1 root root  32K Mar  7 14:51 bcm2710-rpi-zero-2-w.dtb
-rwxr-xr-x 1 root root  32K Mar  7 14:51 bcm2710-rpi-zero-2.dtb
-rwxr-xr-x 1 root root  54K Mar  7 14:51 bcm2711-rpi-4-b.dtb
-rwxr-xr-x 1 root root  54K Mar  7 14:51 bcm2711-rpi-400.dtb
-rwxr-xr-x 1 root root  38K Mar  7 14:51 bcm2711-rpi-cm4-io.dtb
-rwxr-xr-x 1 root root  55K Mar  7 14:51 bcm2711-rpi-cm4.dtb
-rwxr-xr-x 1 root root  52K Mar  7 14:51 bcm2711-rpi-cm4s.dtb
-rwxr-xr-x 1 root root  76K Mar  7 14:51 bcm2712-rpi-5-b.dtb
-rwxr-xr-x 1 root root  76K Mar  7 14:51 bcm2712-rpi-cm5-cm4io.dtb
-rwxr-xr-x 1 root root  76K Mar  7 14:51 bcm2712-rpi-cm5-cm5io.dtb
-rwxr-xr-x 1 root root  76K Mar  7 14:51 bcm2712d0-rpi-5-b.dtb
-rwxr-xr-x 1 root root  52K Mar 15 14:59 bootcode.bin
-rwxr-xr-x 1 root root  154 Mar 15 15:06 cmdline.txt
-rwxr-xr-x 1 root root 1.2K Mar 15 14:59 config.txt
-rwxr-xr-x 1 root root 7.2K Mar 15 14:59 fixup.dat
-rwxr-xr-x 1 root root 5.4K Mar 15 14:59 fixup4.dat
-rwxr-xr-x 1 root root 3.2K Mar 15 14:59 fixup4cd.dat
-rwxr-xr-x 1 root root 8.3K Mar 15 14:59 fixup4db.dat
-rwxr-xr-x 1 root root 8.3K Mar 15 14:59 fixup4x.dat
-rwxr-xr-x 1 root root 3.2K Mar 15 14:59 fixup_cd.dat
-rwxr-xr-x 1 root root  11K Mar 15 14:59 fixup_db.dat
-rwxr-xr-x 1 root root  11K Mar 15 14:59 fixup_x.dat
-rwxr-xr-x 1 root root  10M Mar 15 15:07 initramfs
-rwxr-xr-x 1 root root  11M Mar 15 15:07 initramfs7
-rwxr-xr-x 1 root root  11M Mar 15 15:07 initramfs7l
-rwxr-xr-x 1 root root  11M Mar 15 15:07 initramfs8
-rwxr-xr-x 1 root root  145 Mar 15 15:07 issue.txt
-rwxr-xr-x 1 root root 6.8M Mar 15 14:59 kernel.img
-rwxr-xr-x 1 root root 7.1M Mar 15 14:59 kernel7.img
-rwxr-xr-x 1 root root 7.5M Mar 15 14:59 kernel7l.img
-rwxr-xr-x 1 root root 8.9M Mar 15 14:59 kernel8.img
drwxr-xr-x 2 root root  28K Mar 15 14:59 overlays
-rwxr-xr-x 1 root root 2.9M Mar 15 14:59 start.elf
-rwxr-xr-x 1 root root 2.2M Mar 15 14:59 start4.elf
-rwxr-xr-x 1 root root 790K Mar 15 14:59 start4cd.elf
-rwxr-xr-x 1 root root 3.6M Mar 15 14:59 start4db.elf
-rwxr-xr-x 1 root root 2.9M Mar 15 14:59 start4x.elf
-rwxr-xr-x 1 root root 790K Mar 15 14:59 start_cd.elf
-rwxr-xr-x 1 root root 4.7M Mar 15 14:59 start_db.elf
-rwxr-xr-x 1 root root 3.6M Mar 15 14:59 start_x.elf
root@0af89a5fdacb:/var/project#
```

Ok, so we have one file for every imaginable machine could theoretically boot using this, but that
tells us quite a bit, honestly. For one thing, `config.txt` is empty, so apparently that's fine. I
think the next thing to do is try and create a bootable disk partition of my directory and start it
with qemu. Without a OS partition with all the required linux stuff, I'm guessing that the kernel
won't really _do_ anything when we start it, but hey, we can verify that we've made some progress
towards understanding how a PI boots.

Definitely going to be doing some googling here like I do every time I have to use the `dd` command
to build boot partitions, which is about every 3 years.

```shell
root@0af89a5fdacb:/var/project# dd if=/dev/null of=boot.img bs=1M seek=2048
0+0 records in
0+0 records out
0 bytes copied, 0.000158542 s, 0.0 kB/s
root@0af89a5fdacb:/var/project# mkfs.fat ./boot.img
mkfs.fat 4.2 (2021-01-31)
root@0af89a5fdacb:/var/project# file ./boot.img
./boot.img: DOS/MBR boot sector, code offset 0x58+2, OEM-ID "mkfs.fat", sectors/cluster 8, Media descriptor 0xf8, sectors/track 63, heads 128, sectors 4194288 (volumes > 32 MB), FAT (32 bit), sectors/FAT 4088, serial number 0xf82a111e, unlabeled
root@0af89a5fdacb:/var/project# mkdir /mnt/prep/
root@0af89a5fdacb:/var/project# mount -o loop boot.img /mnt/prep/
```

After some copying and an `unmount`, I now in theory should have a FAT32 formatted boot sector for
use with qemu.

Back on my main machine, and some more googling to find the relevant qemu arguments, here goes
nothing:

```shell
❮ qemu-system-aarch64 -machine raspi3b -cpu cortex-a53 -nographic -dtb bcm2710-rpi-3-b.dtb -m 1G -smp 4 -kernel kernel8.img -sd boot.img -append "rw earlyprintk loglevel=8 console=ttyS0 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1" -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22
WARNING: Image format was not specified for 'boot.img' and probing guessed raw.
         Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.
         Specify the 'raw' format explicitly to remove the restrictions.
usbnet: failed control transaction: request 0x8006 value 0x600 index 0x0 length 0xa
usbnet: failed control transaction: request 0x8006 value 0x600 index 0x0 length 0xa
usbnet: failed control transaction: request 0x8006 value 0x600 index 0x0 length 0xa
```

Hmm, well, hey, it executed code. Doesn't seem like the kernel booted though. If I remove the usb
device from qemu, it writes nothing at all...maybe a bad DTB file? I'm also don't have any overlays
in my boot image either, so that seems problematic, since apparently it's the job of the `start.elf`
code to combine one of these files with the appropriate base device tree. I'll just dive back into
my docker container and copy some more overlays and dtb files into my boot image in the hope that I
get some ones that work on this qemu device.

Well, that didn't work either. Even booting the official image with no modifications produced the
same result. Clearly I'm doing something wrong, and I need to stop googling and try to understand
what I'm doing a little better. There's a lot of garbage in those kernel parameters, and I suspect
that I'm not getting kernel output on the right tty, perhaps?

Overall not as much progress I would have liked today, but at least I'm creating and _trying_ to
boot some stuff on qemu.
