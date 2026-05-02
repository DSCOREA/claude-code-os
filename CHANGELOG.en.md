# CHANGELOG

[한국어](CHANGELOG.md) · **English**

---

## v1.0.6 (2026-05-02) — Desktop workstation

![v1.0.6 Korean input](demo/v1.0.6-korean-input.jpg)

X11 desktop + Korean IME + Firefox + zero-typing OAuth, all on first boot.

### Added
- **X11 GUI environment** — Xorg + fluxbox (lightweight WM). Desktop instead of black console after boot.
- **Korean input** — `ibus-hangul` + Noto CJK + **D2Coding** font (Naver, popular among Korean developers). Hangul/English toggle key.
- **xfce4-terminal** — replaces `xterm`. **Ctrl+Shift+V paste**, tabs, modern UI, dark theme.
- **Firefox ESR** — replaces `chromium`. Detects claude's OAuth URL and opens a new tab with auto-focus. **No need to close any window first.**
- **cco user (uid 1000)** — no more root. Member of wheel/video/input/audio/tty groups. `sudo NOPASSWD`.
- **`--dangerously-skip-permissions` automatic** — claude wrapper always starts in bypass mode. No more pressing Y every time.
- **VMware host clipboard sync** — `open-vm-tools` + `xf86-input-vmmouse`. Copy on host → paste in VM.
- **VMware SVGA dynamic resolution** — `xf86-video-vmware` + `xrandr`. Auto-resize with host window.
- **Keyboard shortcuts** — F2 Firefox / F3 Terminal / F4 Claude / F11 Fullscreen / Alt+Mouse1 to move windows.
- **`script(1)` pty wrapper** — fixes claude's `Input must be provided either through stdin or as a prompt argument` error.
- **Auto OAuth URL detection** — wrapper monitors claude output → `https://...` URL detected → spawns Firefox new tab.
- **Xorg setcap** — `cap_sys_rawio,cap_dac_override,cap_sys_admin+ep`. Lets normal users start X with I/O port access.
- **xhost + .Xauthority cookie copy** — resolves X session permission conflicts.
- **World-first marketing + demo video** — boot GIF + Korean input screenshot in README.

### Changed
- **Versioning** SemVer (v1.0.0, v1.0.1, ...). Older v1–v25 retired.
- **Default user**: `root` → `cco`.
- **Default browser**: `chromium --no-sandbox` → `firefox`.
- **Default terminal**: `xterm` → `xfce4-terminal`.
- **Autologin TTY**: tty1 root → tty1 cco → tty1 cco (sudo wheel) (final).
- **Plain tar overlay** — `cco-root.tar.gz` (gzip) → `cco-root.tar` (no compression). busybox tar extracts 1.5GB in 30–60s (faster than gzip).

### Fixed
- Keyboard not working → added `eudev` + `xf86-input-vmmouse`.
- Screen cropped → `xf86-video-vmware` (SVGA) + xterm geometry tweaks.
- `failed to enable I/O ports 0000-03ff` → Xorg setcap + cco in video/input groups.
- `xauth: file /home/cco/.Xauthority does not exist` → copy root's .Xauthority cookie to cco home + `xhost +SI:localuser:cco`.
- Two chromium instances (boss had to close first window before second appeared) → firefox single-instance.
- chromium window not focusable on click → firefox + wmctrl auto-raise.
- Auto-entered `--print` mode → bypassed via script(1) pty preservation.

### ISO info
- Size: ~1.9GB
- Packages: 365 (firefox + xfce4-terminal + ibus + Xorg + chromium fallback)
- Build time: ~5 minutes
- Boot time: ~30–60s on VMware ESXi

---

## v1.0.0 (2026-05-01) — First public release (console only)

![v1 boot](demo/boot.gif)

### Added
- Based on Alpine Linux 3.20 standard ISO.
- initramfs `/init` patch — extracts overlay via `tar xzf /cco-root.tar.gz`.
- Pre-installed Node.js + npm + `@anthropic-ai/claude-code` inside chroot.
- inittab tty1 autologin (root).
- `/etc/profile.d/cco.sh` — banner (ANSI 256-color cyan/gold), loopback up, IPv6 up, NIC probe (vmxnet3/e1000), DHCP, sshd, exec claude.
- "Claude Code OS" ASCII banner.
- Boot demo video + GIF + single-frame screenshot.
- English/Korean README (Korean first).

### Limitations
- Console only (no X11).
- Keyboard only, no GUI mouse.
- No Korean input.
- claude OAuth = authenticate on a separate PC browser, type the code.
- Runs as root → `--dangerously-skip-permissions` rejected.

---

## Comparison

| Item | v1.0.0 | v1.0.6 |
|---|---|---|
| Interface | Black console | X11 desktop (fluxbox) |
| User | root | cco (sudo NOPASSWD) |
| Terminal | TTY (Linux console) | xfce4-terminal (tabs, Ctrl+Shift+V) |
| Font | console default | D2Coding (Korean dev favorite) |
| Korean input | none | ibus-hangul (Hangul toggle) |
| Browser | none | Firefox ESR (auto OAuth) |
| OAuth flow | Separate PC + code | Inside the VM (URL → new tab) |
| `--dangerously-skip-permissions` | rejected (root) | automatic (cco) |
| Mouse | not working | working (vmmouse) + Alt+drag to move |
| Clipboard | isolated from host | VMware integrated (open-vm-tools) |
| Shortcuts | none | F2/F3/F4/F11 |
| ISO size | ~400MB | ~1.9GB |
