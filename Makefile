.PHONY: distro v86 serve qemu

KERNEL_FILE = output/bzImage
INITRAMFS_FILE = output/initramfs.gz

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
		-netdev user,id=net0 \
		-device virtio-net-pci,netdev=net0

wtux.iso: $(KERNEL_FILE) $(INITRAMFS_FILE)
	@if command -v genisoimage &> /dev/null; then \
		echo "Creating ISO image..."; \
		mkdir -p iso_contents/boot/isolinux; \
		cp $(KERNEL_FILE) iso_contents/boot/isolinux/; \
		cp $(INITRAMFS_FILE) iso_contents/boot/isolinux/; \
		echo "default linux" > iso_contents/boot/isolinux/isolinux.cfg; \
		echo "label linux" >> iso_contents/boot/isolinux/isolinux.cfg; \
		echo "	kernel bzImage" >> iso_contents/boot/isolinux/isolinux.cfg; \
		echo "	append initrd=initramfs.gz" >> iso_contents/boot/isolinux/isolinux.cfg; \
		syslinux=""; \
		if command -v nix; then syslinux=/nix/store/*-syslinux-*/share/syslinux; fi; \
		if command -v apt; then syslinux=/usr/share/syslinux; fi; \
		test -d $$syslinux && cp $$syslinux/isolinux.bin $$syslinux/ldlinux.c32 iso_contents/boot/isolinux/. || { echo "error: could not copy $$isolinux_bin :/"; exit 1; }; \
		chmod +w iso_contents/boot/isolinux/*; \
		tree iso_contents; \
		genisoimage -o output/wtux.iso -b boot/isolinux/isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table iso_contents; \
		ls -lh output/*.iso; \
		rm -rf iso_contents; \
	else \
		echo "error: please install genisoimage to create the ISO image."; \
	        echo ""; \
		echo "     nix: nix-shell -p cdrkit syslinux"; \
		echo "  ubuntu: apt-get install cdrkit syslinux"; \
		exit 1; \
	fi
