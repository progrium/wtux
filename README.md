# wtux

Minimal i386 Linux distro for Wanix/v86

## Prerequisites 

* Docker (build on any platform)
* QEMU (for testing)

## Building

```sh
./build.sh
```

This uses Docker to produce a kernel and initramfs in `./output` which together should be just over 4MB. Would love to make this smaller.

## Testing

```sh
qemu-system-i386 \
    -kernel output/bzImage \
    -initrd output/initramfs.gz \
    -append "console=ttyS0 init=/init" \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    -no-reboot
```

## Caveats

No idea what I'm doing. Got this far working with Claude. Unfortunately, we started going in circles trying to get DNS working.

## TODO

* [ ] Fix DNS (`bad address`)
* [ ] Test in v86
* [ ] Test virtio 9P root
* [ ] Make it smaller!
* [ ] Add musl and apk for Alpine package support?