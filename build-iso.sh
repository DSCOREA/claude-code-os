#!/bin/bash
# Build cco-alpine-vX.Y.Z.iso — patches Alpine standard ISO with cco-root.tar overlay
# Usage: sudo ./build-iso.sh [version]
#
# Output: cco-alpine-${VERSION}.iso
#
# Prerequisites:
#   - cco-root.tar (from build-rootfs.sh)
#   - alpine-standard-3.20.3-x86_64.iso in current directory
#     (https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/)
#   - xorriso, cpio, gzip
set -e

VERSION="${1:-1.0.6}"
[ "$EUID" = 0 ] || { echo "Run with sudo." >&2; exit 1; }
[ -f cco-root.tar ] || { echo "cco-root.tar missing. Run build-rootfs.sh first." >&2; exit 1; }
[ -f alpine-standard-3.20.3-x86_64.iso ] || { echo "alpine-standard-3.20.3-x86_64.iso missing." >&2; exit 1; }

# 1. Extract upstream initramfs
rm -rf alpine-extract initrd-extract
mkdir -p alpine-extract initrd-extract
xorriso -osirrox on -indev alpine-standard-3.20.3-x86_64.iso \
  -extract /boot alpine-extract/boot 2>/dev/null

cd initrd-extract
gunzip -c ../alpine-extract/boot/initramfs-lts | cpio -idm 2>/dev/null
cd ..

# 2. Patch /init — extract cco-root.tar onto /sysroot before switch_root
INIT=initrd-extract/init
cp "$INIT" "${INIT}.bak"

sed -i '/^exec switch_root/i \
echo "=== CCO v'"$VERSION"' overlay ==="\
FOUND=""\
for D in /media/cdrom /media/sr0 /media/sda /.modloop /sysroot/media/cdrom /cdrom; do\
  [ -f "$D/cco-root.tar" ] && FOUND="$D/cco-root.tar" && break\
done\
if [ -z "$FOUND" ]; then\
  FOUND=$(find / -maxdepth 4 -name cco-root.tar 2>/dev/null | head -1)\
fi\
if [ -n "$FOUND" ]; then\
  echo "=== overlay from $FOUND ==="\
  tar xpf "$FOUND" -C /sysroot/ && echo "=== OK overlay ==="\
else\
  echo "=== FAIL no cco-root.tar found ==="\
fi' "$INIT"

# 3. Repack initramfs
( cd initrd-extract && find . | cpio -o -H newc 2>/dev/null | gzip > "$PWD/../alpine-extract/boot/initramfs-lts" )

# 4. Add cco-root.tar to ISO root
cp cco-root.tar alpine-extract/cco-root.tar

# 5. Repack ISO with patched initramfs + overlay
ISO_OUT="cco-alpine-v${VERSION}.iso"
rm -f "$ISO_OUT"
xorriso -indev alpine-standard-3.20.3-x86_64.iso -outdev "$ISO_OUT" \
  -boot_image any replay -volid 'Claude-Code-OS' \
  -map alpine-extract/boot/initramfs-lts /boot/initramfs-lts \
  -map alpine-extract/cco-root.tar /cco-root.tar \
  -commit 2>&1 | tail -3

ls -la "$ISO_OUT"
echo
echo "Done. Boot it:"
echo "  qemu-system-x86_64 -m 4096 -smp 2 -cdrom $ISO_OUT -boot d"
echo "Or burn to USB:"
echo "  sudo dd if=$ISO_OUT of=/dev/sdX bs=4M status=progress oflag=sync"
