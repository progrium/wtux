.PHONY: distro v86 serve qemu

distro:
	rm -rf output
	mkdir -p output
	docker build -t wtux-i386-builder .
	docker run --rm -v "$(PWD)/output:/output-mount" wtux-i386-builder
	@ls -lh output/

v86:
	docker build -t v86-builder ./v86
	docker run --rm -v "$(PWD)/v86:/dst" v86-builder

serve:
	python3 -m http.server 8000

qemu:
	qemu-system-i386 \
		-kernel output/bzImage \
		-initrd output/initramfs.gz \
		-append "console=tty1" \
		-netdev user,id=net0 \
		-device virtio-net-pci,netdev=net0
