FROM debian:bullseye

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    bc \
    bzip2 \
    cpio \
    flex \
    bison \
    libelf-dev \
    gcc-i686-linux-gnu \
    binutils-i686-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# Create rootfs
WORKDIR /build
RUN mkdir -p /build/rootfs/bin \
    /build/rootfs/dev \
    /build/rootfs/proc \
    /build/rootfs/sys \
    /build/rootfs/etc

# Get and build busybox
RUN wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2 && \
    tar xf busybox-1.35.0.tar.bz2 && \
    rm busybox-1.35.0.tar.bz2 && \
    cd /build/busybox-1.35.0 && \
    make defconfig ARCH=i386 CROSS_COMPILE=i686-linux-gnu- && \
    sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config && \
    sed -i 's/^CONFIG_FEATURE_MOUNT_NFS=y/CONFIG_FEATURE_MOUNT_NFS=n/' .config && \
    sed -i 's/^CONFIG_FEATURE_INETD_RPC=y/CONFIG_FEATURE_INETD_RPC=n/' .config && \
    make LDFLAGS='-static' ARCH=i386 CROSS_COMPILE=i686-linux-gnu- -j$(nproc) && \
    i686-linux-gnu-strip busybox && \
    cp busybox /build/rootfs/bin/ && \
    cd /build/rootfs/bin && \
    chmod +x busybox && \
    ln -s busybox sh && \
    cd /build && \
    rm -rf busybox-1.35.0

# Create network config
RUN echo "nameserver 8.8.8.8" > /build/rootfs/etc/resolv.conf

# Add hostname
RUN echo "minimal" > /build/rootfs/etc/hostname

# Create init
RUN echo '#!/bin/busybox sh' > /build/rootfs/init && \
    echo '/bin/busybox mount -t proc none /proc' >> /build/rootfs/init && \
    echo '/bin/busybox mount -t sysfs none /sys' >> /build/rootfs/init && \
    echo '/bin/busybox mount -t devtmpfs none /dev' >> /build/rootfs/init && \
    echo '/bin/busybox --install -s /bin' >> /build/rootfs/init && \
    echo '/bin/busybox ip link set dev eth0 up' >> /build/rootfs/init && \
    echo '/bin/busybox ip addr add 10.0.2.15/24 dev eth0' >> /build/rootfs/init && \
    echo '/bin/busybox ip route add default via 10.0.2.2' >> /build/rootfs/init && \
    echo '/bin/busybox setsid /bin/busybox sh -c "exec /bin/busybox sh </dev/ttyS0 >/dev/ttyS0 2>&1"' >> /build/rootfs/init && \
    chmod +x /build/rootfs/init

# Get and build kernel
RUN wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.137.tar.xz && \
    tar xf linux-5.15.137.tar.xz && \
    rm linux-5.15.137.tar.xz

COPY kernel.config /build/linux-5.15.137/.config
RUN cd /build/linux-5.15.137 && \
    make ARCH=i386 CROSS_COMPILE=i686-linux-gnu- oldconfig < /dev/null && \
    make ARCH=i386 CROSS_COMPILE=i686-linux-gnu- bzImage -j$(nproc) && \
    cp arch/x86/boot/bzImage /build/ && \
    cd /build && \
    rm -rf linux-5.15.137

# Create initramfs
WORKDIR /build/rootfs
RUN find . | cpio -H newc -o | gzip > /build/initramfs.gz && \
    cd /build && \
    rm -rf rootfs

# Copy outputs
RUN mkdir -p /output && \
    mv /build/bzImage /output/ && \
    mv /build/initramfs.gz /output/ && \
    chmod -R 777 /output && \
    rm -rf /build/*

CMD ["/bin/sh", "-c", "cp -f /output/* /output-mount/"]