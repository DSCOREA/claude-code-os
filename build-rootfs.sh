#!/bin/bash
# Build cco-root.squashfs — Alpine minirootfs + claude + desktop + Wi-Fi GUI + persistence
#
# Output: cco-root.squashfs (zstd, ~760 MB)
#
# Prerequisites (Linux/WSL):
#   - bash, sudo, tar, mksquashfs (squashfs-tools)
#   - alpine-minirootfs-3.20.3-x86_64.tar.gz in current directory
set -e

ROOT="$(pwd)/cco-rootfs"
[ "$EUID" = 0 ] || { echo "Run with sudo." >&2; exit 1; }
[ -f alpine-minirootfs-3.20.3-x86_64.tar.gz ] || { echo "alpine-minirootfs-3.20.3-x86_64.tar.gz missing." >&2; exit 1; }

# 1. Extract minirootfs
rm -rf "$ROOT"
mkdir -p "$ROOT"
tar xpzf alpine-minirootfs-3.20.3-x86_64.tar.gz -C "$ROOT"

# 2. Bind-mount /proc /sys /dev
mount --bind /proc "$ROOT/proc"
mount --bind /sys  "$ROOT/sys"
mount --bind /dev  "$ROOT/dev"
trap 'umount "$ROOT/proc" "$ROOT/sys" "$ROOT/dev" 2>/dev/null || true' EXIT
cp /etc/resolv.conf "$ROOT/etc/"

# 3. apk install (chroot)
cat > "$ROOT/etc/apk/repositories" <<EOF
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
EOF

chroot "$ROOT" /bin/sh -e <<'CHROOT'
apk update
apk add --no-cache \
  nodejs npm \
  xorg-server xf86-video-vmware xf86-video-vesa xf86-video-fbdev \
  xf86-input-vmmouse xf86-input-libinput \
  xinit xterm xrandr xset xauth setxkbmap xrdb \
  fluxbox xfce4-terminal feh \
  firefox-esr xdg-utils \
  ibus ibus-hangul ibus-gtk3 libhangul \
  font-noto-cjk font-noto-cjk-extra \
  open-vm-tools open-vm-tools-gtk open-vm-tools-guestinfo \
  eudev shadow sudo util-linux util-linux-misc libcap-utils \
  musl-locales coreutils wget unzip \
  linux-firmware-rtw88 linux-firmware-rtl_nic linux-firmware-rtl_bt \
  wpa_supplicant iw wireless-tools \
  networkmanager networkmanager-wifi networkmanager-tui \
  network-manager-applet iwd iwgtk \
  chrony

# claude code
npm install -g @anthropic-ai/claude-code

# D2Coding font (Naver, Korean dev favorite)
mkdir -p /usr/share/fonts/d2coding
cd /tmp && wget -q 'https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip' -O d2.zip
unzip -q d2.zip -d d2
find d2 -name '*.ttf' -exec cp {} /usr/share/fonts/d2coding/ \;
rm -rf d2 d2.zip
fc-cache -fv >/dev/null

# cco user (uid 1000) — sudo NOPASSWD
adduser -D -s /bin/sh -u 1000 cco
addgroup cco wheel; addgroup cco video; addgroup cco input; addgroup cco audio; addgroup cco tty
echo "cco:cco" | chpasswd
echo "root:cco" | chpasswd
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# firefox symlink
ln -sf firefox-esr /usr/bin/firefox

# Xorg setcap (one file per call; some Alpine versions only ship one path)
setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/bin/Xorg 2>/dev/null || true
[ -e /usr/libexec/Xorg ] && setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/libexec/Xorg 2>/dev/null || true

mkdir -p /etc/X11
printf 'allowed_users=anybody\nneeds_root_rights=yes\n' > /etc/X11/Xwrapper.config

# OpenRC services
rc-update add iwd default 2>/dev/null || true
rc-update add networkmanager default 2>/dev/null || true
rc-update add dbus default 2>/dev/null || true
rc-update add chronyd default 2>/dev/null || true
rc-update add devfs sysinit 2>/dev/null || true
rc-update add dmesg sysinit 2>/dev/null || true
rc-update add hwclock boot 2>/dev/null || true
rc-update add bootmisc boot 2>/dev/null || true
rc-update add hostname boot 2>/dev/null || true
rc-update add syslog boot 2>/dev/null || true
rc-update add urandom boot 2>/dev/null || true
rc-update add modules boot 2>/dev/null || true

# NetworkManager + iwd backend
mkdir -p /etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' > /etc/NetworkManager/conf.d/wifi-backend.conf

# iwd main config — NetworkManager handles IP, iwd handles only Wi-Fi auth
mkdir -p /etc/iwd
cat > /etc/iwd/main.conf <<'IWD'
[General]
EnableNetworkConfiguration=false
[Network]
NameResolvingService=none
IWD

rm -rf /var/cache/apk/*
CHROOT

# 4. inittab + autologin
sed -i '/^tty1::/d' "$ROOT/etc/inittab"
echo 'tty1::respawn:/bin/login -f cco' >> "$ROOT/etc/inittab"

# 5. Standard mount points + fstab + hosts
mkdir -p "$ROOT/dev/pts" "$ROOT/dev/shm" "$ROOT/proc" "$ROOT/sys" "$ROOT/run" "$ROOT/tmp"
cat > "$ROOT/etc/fstab" <<'EOF'
proc       /proc        proc    nosuid,noexec,nodev          0 0
sys        /sys         sysfs   nosuid,noexec,nodev          0 0
devpts     /dev/pts     devpts  gid=5,mode=620,nosuid,noexec 0 0
tmpfs      /dev/shm     tmpfs   nosuid,nodev                 0 0
tmpfs      /run         tmpfs   nosuid,nodev,mode=0755       0 0
tmpfs      /tmp         tmpfs   nosuid,nodev                 0 0
EOF
cat > "$ROOT/etc/hosts" <<'EOF'
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain
EOF
echo "claude-code-os" > "$ROOT/etc/hostname"

# 6. /etc/local.d/cco-infra.start — boot-time setup + persistence auto-mount
cat > "$ROOT/etc/local.d/cco-infra.start" <<'EOI'
#!/bin/sh
/sbin/udevd --daemon 2>/dev/null
udevadm trigger 2>/dev/null
udevadm settle 2>/dev/null
rfkill unblock all 2>/dev/null

# Aggressive Wi-Fi/NIC modprobe
for m in cfg80211 mac80211 iwlwifi rtl8821ce rtw88_pci rtw88_8821ce rtw88_8822be rtw89_pci \
         ath10k_pci ath11k_pci ath9k brcmfmac mt7921e \
         vmxnet3 e1000 e1000e r8169 r8168 igb ixgbe; do
  modprobe "$m" 2>/dev/null
done
sleep 2

ip link set lo up 2>/dev/null
sysctl -w net.ipv6.conf.lo.disable_ipv6=0 2>/dev/null

# === Ventoy / generic persistence: scan all block devices ===
PERSIST=""
for dev in /dev/sd*[0-9] /dev/nvme*n*p* /dev/mmcblk*p*; do
  [ -b "$dev" ] || continue
  LABEL=$(blkid -o value -s LABEL "$dev" 2>/dev/null)
  if [ "$LABEL" = "casper-rw" ] || [ "$LABEL" = "cco-data" ] || [ "$LABEL" = "persistence" ]; then
    mkdir -p /persistence
    mount -o rw "$dev" /persistence 2>/dev/null && PERSIST="$dev" && break
  fi
done
if [ -z "$PERSIST" ]; then
  for dev in /dev/sd*[0-9] /dev/nvme*n*p* /dev/mmcblk*p*; do
    [ -b "$dev" ] || continue
    FSTYPE=$(blkid -o value -s TYPE "$dev" 2>/dev/null)
    case "$FSTYPE" in
      vfat|exfat)
        mkdir -p /tmp/scan
        if mount -o rw "$dev" /tmp/scan 2>/dev/null; then
          if [ -f /tmp/scan/cco-persistence.dat ]; then
            mkdir -p /persistence
            mount -o loop,rw /tmp/scan/cco-persistence.dat /persistence 2>/dev/null && PERSIST="loop" && break
          fi
          umount /tmp/scan 2>/dev/null
        fi
        ;;
    esac
  done
fi
if mountpoint -q /persistence 2>/dev/null; then
  for d in home/cco etc/NetworkManager var/lib/iwd etc/iwd; do
    [ -d "/persistence/$d" ] || { mkdir -p "/persistence/$d"; [ -d "/$d" ] && cp -a "/$d/." "/persistence/$d/" 2>/dev/null; }
    mkdir -p "/$d"
    mount --bind "/persistence/$d" "/$d" 2>/dev/null
  done
  chown -R 1000:1000 /persistence/home/cco 2>/dev/null
fi

mkdir -p /var/run/dbus /var/lib/iwd
dbus-uuidgen --ensure 2>/dev/null
# OpenRC services (iwd, NetworkManager, dbus, chronyd) start via rc-update,
# this fallback only runs if the OpenRC start failed for some reason.
pgrep -x dbus-daemon >/dev/null 2>&1 || dbus-daemon --system --fork 2>/dev/null
sleep 1
pgrep -x iwd >/dev/null 2>&1 || iwd -B 2>/dev/null
pgrep -x NetworkManager >/dev/null 2>&1 || NetworkManager 2>/dev/null &
sleep 3
/usr/sbin/sshd 2>/dev/null
[ -f /etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -A 2>/dev/null
/usr/bin/vmtoolsd -b /var/run/vmtoolsd.pid 2>/dev/null &

chmod 664 /dev/dri/card0 /dev/dri/renderD128 2>/dev/null
setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/bin/Xorg 2>/dev/null || true
[ -e /usr/libexec/Xorg ] && setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/libexec/Xorg 2>/dev/null || true
EOI
chmod +x "$ROOT/etc/local.d/cco-infra.start"

# 7. /usr/local/bin/{cco-banner, claude-cco, cco-startup, cco-persistence} — see GitHub repo for full content
# (omitted from public build script — see runtime ISO for current versions)

# 8. cco home — autostart X
mkdir -p "$ROOT/home/cco/.fluxbox" "$ROOT/home/cco/.config/xfce4/terminal"
cat > "$ROOT/home/cco/.profile" <<'EOP'
[ -f /tmp/cco-done ] && return
[ "$(tty)" = /dev/tty1 ] || return
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS="@im=ibus"
export BROWSER='firefox'
[ -f "$HOME/.Xauthority" ] || { touch "$HOME/.Xauthority"; chmod 600 "$HOME/.Xauthority"; }
touch /tmp/cco-done
exec startx
EOP

# Pre-create empty Xauthority so first startx doesn't spam "does not exist"
touch "$ROOT/home/cco/.Xauthority"
chmod 600 "$ROOT/home/cco/.Xauthority"
echo "exec startfluxbox" > "$ROOT/home/cco/.xinitrc"

cat > "$ROOT/home/cco/.fluxbox/startup" <<'EOX'
#!/bin/sh
ibus-daemon -drx --panel=disable &
sleep 1
ibus engine hangul 2>/dev/null
/usr/bin/vmware-user-suid-wrapper 2>/dev/null &
command -v iwgtk >/dev/null && iwgtk -i &
xfce4-terminal --hide-menubar --hold -x /usr/local/bin/cco-startup &
exec fluxbox
EOX
chmod +x "$ROOT/home/cco/.fluxbox/startup"

cat > "$ROOT/home/cco/.config/xfce4/terminal/terminalrc" <<'EOT'
[Configuration]
ColorBackground=#1e1e1e
ColorForeground=#d4d4d4
FontName=D2Coding 12
FontUseSystem=FALSE
ScrollingLines=10000
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
EOT

chown -R 1000:1000 "$ROOT/home/cco"

# 9. Pack rootfs as squashfs
trap - EXIT
umount "$ROOT/proc" "$ROOT/sys" "$ROOT/dev"
mksquashfs "$ROOT" cco-root.squashfs -comp zstd -Xcompression-level 6 -b 1M -no-progress -e proc sys dev run
ls -la cco-root.squashfs
echo "Done. Now run: sudo ./build-iso.sh"
