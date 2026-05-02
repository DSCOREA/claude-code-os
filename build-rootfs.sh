#!/bin/bash
# Build cco-rootfs.tar — Alpine minirootfs + claude + Korean IME + Firefox + xfce4-terminal + cco user
# Usage: sudo ./build-rootfs.sh
#
# Output: cco-root.tar  (uncompressed, ~1.5 GB)
#
# Prerequisites:
#   - Linux build host (or WSL)
#   - alpine-minirootfs-3.20.3-x86_64.tar.gz in current directory
#     (https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/)
set -e

ROOT="$(pwd)/cco-rootfs"
[ "$EUID" = 0 ] || { echo "Run with sudo." >&2; exit 1; }
[ -f alpine-minirootfs-3.20.3-x86_64.tar.gz ] || { echo "alpine-minirootfs-3.20.3-x86_64.tar.gz missing." >&2; exit 1; }

# 1. Extract minirootfs
rm -rf "$ROOT"
mkdir -p "$ROOT"
tar xpzf alpine-minirootfs-3.20.3-x86_64.tar.gz -C "$ROOT"

# 2. Bind-mount /proc /sys /dev for chroot
mount --bind /proc "$ROOT/proc"
mount --bind /sys  "$ROOT/sys"
mount --bind /dev  "$ROOT/dev"
trap 'umount "$ROOT/proc" "$ROOT/sys" "$ROOT/dev" 2>/dev/null || true' EXIT
cp /etc/resolv.conf "$ROOT/etc/"

# 3. Install everything inside chroot
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
  firefox-esr chromium xdg-utils \
  ibus ibus-hangul ibus-gtk3 libhangul \
  font-noto-cjk font-noto-cjk-extra \
  open-vm-tools open-vm-tools-gtk open-vm-tools-guestinfo \
  eudev shadow sudo util-linux libcap-utils \
  musl-locales coreutils wget unzip wmctrl

# claude code
npm install -g @anthropic-ai/claude-code

# D2Coding font (Naver, popular among Korean developers)
mkdir -p /usr/share/fonts/d2coding
cd /tmp
wget -q 'https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip' -O d2.zip
unzip -q d2.zip -d d2
find d2 -name '*.ttf' -exec cp {} /usr/share/fonts/d2coding/ \;
rm -rf d2 d2.zip
fc-cache -fv >/dev/null

# cco user (uid 1000) — sudo NOPASSWD
adduser -D -s /bin/sh -u 1000 cco
addgroup cco wheel
addgroup cco video
addgroup cco input
addgroup cco audio
addgroup cco tty
echo "cco:cco" | chpasswd
echo "root:cco" | chpasswd
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# firefox symlink (alpine ships firefox-esr only)
ln -sf firefox-esr /usr/bin/firefox

# Xorg setcap — let cco start X with I/O port access
setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/libexec/Xorg 2>/dev/null
setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/bin/Xorg 2>/dev/null

mkdir -p /etc/X11
cat > /etc/X11/Xwrapper.config <<EOX
allowed_users=anybody
needs_root_rights=yes
EOX

rm -rf /var/cache/apk/*
CHROOT

# 4. inittab — autologin cco on tty1
sed -i '/^tty1::/d' "$ROOT/etc/inittab"
echo 'tty1::respawn:/bin/login -f cco' >> "$ROOT/etc/inittab"

# 5. /etc/local.d/cco-infra.start — boot-time infra (network, sshd, vmtoolsd, setcap)
cat > "$ROOT/etc/local.d/cco-infra.start" <<'EOI'
#!/bin/sh
/sbin/udevd --daemon 2>/dev/null
udevadm trigger 2>/dev/null
udevadm settle 2>/dev/null
ip link set lo up 2>/dev/null
sysctl -w net.ipv6.conf.lo.disable_ipv6=0 2>/dev/null
modprobe vmxnet3 2>/dev/null; modprobe e1000 2>/dev/null; sleep 2
for i in eth0 ens33 enp0s3; do
  ip link show $i >/dev/null 2>&1 && { ip link set $i up; udhcpc -i $i -t 8 -n -q; break; }
done
[ -s /etc/resolv.conf ] || echo 'nameserver 1.1.1.1' > /etc/resolv.conf
/usr/sbin/sshd 2>/dev/null
[ -f /etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -A 2>/dev/null
/usr/bin/vmtoolsd -b /var/run/vmtoolsd.pid 2>/dev/null &
chmod 664 /dev/dri/card0 /dev/dri/renderD128 2>/dev/null
setcap 'cap_sys_rawio,cap_dac_override,cap_sys_admin+ep' /usr/libexec/Xorg /usr/bin/Xorg 2>/dev/null
EOI
chmod +x "$ROOT/etc/local.d/cco-infra.start"
sed -i '/cco-infra/d' "$ROOT/etc/inittab"
sed -i '/::sysinit:.*sysinit/a ::sysinit:/etc/local.d/cco-infra.start' "$ROOT/etc/inittab"

# 6. cco-banner
cat > "$ROOT/usr/local/bin/cco-banner" <<'EOB'
#!/bin/sh
clear
printf '\033[1;38;5;51m'
echo '  ╔══════════════════════════════════════════════════╗'
echo '  ║   C L A U D E    C O D E    O S    v1.0.6        ║'
echo '  ║   user: cco (sudo NOPASSWD)                       ║'
echo '  ║   F2 Firefox  F3 Term  F4 Claude  F11 Fullscreen  ║'
echo '  ╚══════════════════════════════════════════════════╝'
printf '\033[0m\n'
EOB
chmod +x "$ROOT/usr/local/bin/cco-banner"

# 7. claude wrapper — pty preservation + auto OAuth URL detection
cat > "$ROOT/usr/local/bin/claude-cco" <<'EOW'
#!/bin/sh
[ -z "$BROWSER" ] && export BROWSER='firefox'
LOG=/tmp/claude-$$.log
SEEN=/tmp/cco-oauth-seen.$$
: > "$LOG"; : > "$SEEN"
( tail -n 0 -F "$LOG" 2>/dev/null | while IFS= read -r LINE; do
    URL=$(printf '%s' "$LINE" | grep -oE 'https://[A-Za-z0-9./?=#&_:%+~-]+' | head -1)
    if [ -n "$URL" ] && ! grep -qF "$URL" "$SEEN" 2>/dev/null; then
      echo "$URL" >> "$SEEN"
      firefox --new-tab "$URL" >/dev/null 2>&1 &
      sleep 1
      command -v wmctrl >/dev/null 2>&1 && wmctrl -a firefox 2>/dev/null
    fi
  done ) &
WATCHER=$!
SHELL=/bin/sh script -q -f -c "claude --dangerously-skip-permissions $*" "$LOG"
kill $WATCHER 2>/dev/null
rm -f "$LOG" "$SEEN"
echo
echo "─── claude session ended ───"
EOW
chmod +x "$ROOT/usr/local/bin/claude-cco"

# 8. cco home — .profile (autostart X), .xinitrc, .fluxbox/{startup,keys,menu}
mkdir -p "$ROOT/home/cco/.fluxbox" "$ROOT/home/cco/.config/xfce4/terminal"

cat > "$ROOT/home/cco/.profile" <<'EOP'
[ -f /tmp/cco-done ] && return
[ "$(tty)" = /dev/tty1 ] || return
/usr/local/bin/cco-banner
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS="@im=ibus"
export BROWSER='firefox'
touch /tmp/cco-done
exec startx
EOP

echo "exec startfluxbox" > "$ROOT/home/cco/.xinitrc"

cat > "$ROOT/home/cco/.fluxbox/startup" <<'EOX'
#!/bin/sh
ibus-daemon -drx --panel=disable &
sleep 1
ibus engine hangul 2>/dev/null
/usr/bin/vmware-user-suid-wrapper 2>/dev/null &
xfce4-terminal --title='Claude Code OS' --geometry=110x35+5+5 --hide-menubar -e 'claude-cco' --hold &
exec fluxbox
EOX
chmod +x "$ROOT/home/cco/.fluxbox/startup"

cat > "$ROOT/home/cco/.fluxbox/keys" <<'EOK'
OnWindow Mod1 Mouse1 :StartMoving
OnWindow Mod1 Mouse3 :StartResizing NearestCorner
OnWindow Mod4 Mouse1 :StartMoving
OnDesktop Mouse3 :RootMenu
None F2 :Exec firefox
None F3 :Exec xfce4-terminal --hide-menubar
None F4 :Exec xfce4-terminal --hide-menubar -e claude-cco --hold
None F11 :Fullscreen
Mod1 Tab :NextWindow
Mod1 F4 :Close
EOK

cat > "$ROOT/home/cco/.fluxbox/menu" <<'EOM'
[begin] (Claude Code OS)
  [exec] (Firefox)         {firefox}
  [exec] (Terminal — F3)   {xfce4-terminal --hide-menubar}
  [exec] (Claude — F4)     {xfce4-terminal --hide-menubar -e claude-cco --hold}
  [separator]
  [exec] (Reboot)   {sudo reboot}
  [exec] (Shutdown) {sudo poweroff}
[end]
EOM

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

# 9. Pack rootfs — uncompressed tar (busybox tar extracts faster than gzip)
trap - EXIT
umount "$ROOT/proc" "$ROOT/sys" "$ROOT/dev"
tar cf cco-root.tar -C "$ROOT" .
ls -la cco-root.tar
echo "Done. Now run: sudo ./build-iso.sh"
