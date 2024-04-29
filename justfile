boot:
    qemu-system-aarch64 \
        -machine type=raspi3 \
        -m 1024 \
        -kernel kernel8.img \
        -initrd initramfs \
        -cpu cortex-a53

blog:
    pnpm --dir $HOME/dev/helvetici/michaelhelvey.dev dev
