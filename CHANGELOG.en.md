# CHANGELOG

[한국어](CHANGELOG.md) · **English**

---

## v1.0.34 (2026-05-05) — All expected fixes + Ventoy auto-boot

### Added
- **chrony** — time sync (1970 → correct → SSL/OAuth works)
- **OpenRC services** — devfs, dmesg, hwclock, bootmisc, hostname, syslog, urandom, modules, iwd, networkmanager, dbus, chronyd
- **`/etc/fstab`** — proc, sys, devpts (gid=5,mode=620), shm, run, tmp standard mounts
- **`/etc/hosts`** + **`/etc/hostname` = claude-code-os**
- **modloop re-enabled** — kernel modules load correctly (Wi-Fi, USB drivers)
- **Ventoy auto-boot** ventoy.json: `VTOY_MENU_TIMEOUT: 3`, `VTOY_DEFAULT_IMAGE`, `persistence.autosel: 1`
- **Auto installer**: `install-cco-on-ventoy.ps1` (Windows) + `.sh` (Linux/macOS)
- **INSTALL.md** — Korean user guide

### Fixed
- v1.0.33 PTY ("Failed to open PTY") — `/dev/pts` mount
- v1.0.32 `/dev/tty1` — devtmpfs explicit mount
- v1.0.31 squashfs search — find / + diagnostic
- v1.0.30 init bypass fail — alpine init reuse + sed insert

---

## v1.0.27~33 (2026-05-04 → 05) — squashfs+overlay validated

- v1.0.27 — Ventoy persistence auto-detect (label `casper-rw`, FAT32 cco-persistence.dat)
- v1.0.30 — alpine init reuse + sed insert (workdir fix)
- v1.0.32 — devtmpfs on /sysroot
- v1.0.33 — devpts mount

---

## v1.0.20~26 — Wi-Fi GUI + persistence

- v1.0.20 — **iwgtk** (gtk3 Wi-Fi manager) + iwd backend, RTL8821CE compatible
- v1.0.21 — USB persistence (cco-persistence init)
- v1.0.22 — fast boot (timeouts, loglevel, fastboot)
- v1.0.25 — plain tar fallback (validated)
- v1.0.26 — persistence on USB FAT32 (cdrom remount fix)

---

## v1.0.13~19 — UI cleanup + Wi-Fi evolution

- v1.0.15 — English-only menus (font fallback workaround)
- v1.0.16 — Wi-Fi rfkill + cfg80211 + dbus + wpa_supplicant
- v1.0.17 — RTL8821CE firmware correct package names
- v1.0.18~19 — Wi-Fi GUI/CLI experiments

---

## v1.0.7~12 — Wi-Fi/Ethernet drivers

- v1.0.7 — linux-firmware-* drivers (RTL/Intel/Atheros/Broadcom/MediaTek)
- v1.0.8 — UEFI grub.cfg "Linux lts" → "Claude Code OS"

---

## v1.0.6 — Desktop workstation

- X11 + fluxbox + xfce4-terminal + Firefox + ibus-hangul + D2Coding
- cco user (sudo NOPASSWD), claude --dangerously-skip-permissions automatic
- VMware open-vm-tools clipboard sync

---

## v1.0.0 — First public release

- Alpine Linux 3.20 base + initramfs `/init` patch
- nodejs + npm + claude-code preinstalled
- Console-only (no X11), root autologin

---

## Comparison (v1.0.0 → v1.0.35)

| Item | v1.0.0 | v1.0.35 |
|---|---|---|
| Interface | Black console | X11 desktop (fluxbox + xfce4-terminal) |
| User | root | cco (sudo NOPASSWD) |
| Korean input | none | ibus-hangul + D2Coding |
| Wi-Fi | none | iwgtk + iwd (RTL8821CE etc.) |
| OAuth | Separate PC | Firefox automatic |
| **Persistence** | none | **Ventoy auto (cco-persistence.dat)** |
| Decompression | tar.gz | **squashfs direct-mount + overlayfs** |
| Auto installer | none | **`install-cco-on-ventoy.{ps1,sh}` one-liner** |
| ISO size | ~400 MB | ~930 MB (squashfs zstd) |