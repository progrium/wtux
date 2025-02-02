# wtux

Minimal i386 Linux distro for Wanix/v86

## Prerequisites 

* make
* Docker (build on any platform)
* QEMU (for testing)
* python3 (for http)

## Building

```sh
make distro
```

This uses Docker to produce a kernel and initramfs in `./output` which together should be about 3MB. Would love to make this even smaller.

## Testing with QEMU

```sh
make qemu
```

This will run QEMU using the files in `./output`. 

## Testing with v86

First build v86 files. This only needs to be done once:

```sh
make v86
```

Now start an HTTP server. This make task uses python3:

```sh
make serve
```

Now browse to `http://localhost:8000`.

## Source

* Kernel config is in `kernel.config`
* Kernel and busybox are built in `Dockerfile`
* Init script is defined in `init`