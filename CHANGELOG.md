# CHANGELOG

**한국어** · [English](CHANGELOG.en.md)

---

## v1.0.35 (2026-05-05) — Xauthority + iwd 첫 부팅 fix

### 수정
- **`.Xauthority does not exist`** — `/home/cco/.Xauthority` 빈 파일 미리 생성 (chmod 600). `.profile` 에 `startx` 직전 fallback 추가.
- **iwd 시작 실패** — `/etc/iwd/main.conf` 추가 (`EnableNetworkConfiguration=false` + `NameResolvingService=none` — NetworkManager 가 IP/DNS 담당). `/var/lib/iwd` 미리 생성. cco-infra.start 의 daemon spawn 을 OpenRC service 와 충돌 안 하게 `pgrep` 가드.

---

## v1.0.34 (2026-05-05) — 모든 예상 issue + Ventoy 자동 부팅

### 추가
- **chrony** 추가 — 시간 sync (1970 → 정확 시간 → SSL/OAuth 정상)
- **OpenRC service 활성** — devfs / dmesg / hwclock / bootmisc / hostname / syslog / urandom / modules / iwd / networkmanager / dbus / chronyd
- **`/etc/fstab`** — proc, sys, devpts (gid=5,mode=620), shm, run, tmp 표준 mount
- **`/etc/hosts`** + **`/etc/hostname` = claude-code-os**
- **`nomodloop` 폐기** — alpine modloop 사용 → kernel module 정상 load (Wi-Fi/USB driver 설치됨)
- **Ventoy 자동 부팅 ventoy.json**:
  - `VTOY_MENU_TIMEOUT: 3` — 3초 후 자동
  - `VTOY_DEFAULT_IMAGE: cco-alpine-v1.0.34.iso` — 자동 선택
  - `persistence.autosel: 1` — persistence 자동 enabled
- **자동 installer 스크립트**: `install-cco-on-ventoy.ps1` (Windows) + `.sh` (Linux/macOS) — 한 줄 명령으로 USB 설치
- **INSTALL.md** — 한국어 사용자 가이드

### 수정
- v1.0.33 의 PTY ("Failed to open PTY") — `/dev/pts` 설치
- v1.0.32 의 `/dev/tty1` — `mksquashfs -e dev` 폐기 + devtmpfs mount
- v1.0.31 의 squashfs 검색 — find / + diagnostic
- v1.0.30 의 init bypass fail — alpine init 본체 활용 + sed insert

---

## v1.0.30~33 (2026-05-04 → 05) — squashfs+overlay 검증

- v1.0.30 — alpine init 본체 + sed insert (v1.0.29 bypass fail 회복)
- v1.0.31 — squashfs 검색 path 11곳 + block device + find / + diagnostic
- v1.0.32 — `/dev/tty1` fix (devtmpfs mount on /sysroot)
- v1.0.33 — PTY fix (`/dev/pts` devpts mount)

---

## v1.0.27~29 (2026-05-04) — Ventoy persistence + alpine init bypass

- v1.0.27 — Ventoy persistence 자동 검색 (label `casper-rw` 또는 fat32 안 cco-persistence.dat)
- v1.0.28 — alpine init 우회 시도 (fail)
- v1.0.29 — squashfs+overlay alpine init bypass (fail — KOPT/helper 미도달)

---

## v1.0.21~26 (2026-05-04) — persistence + Wi-Fi GUI

- v1.0.20 — **iwgtk** (gtk Wi-Fi manager, click only) + iwd backend, RTL8821CE 호환
- v1.0.21 — USB persistence (cco-persistence init)
- v1.0.22 — boot 시간 단축 (TIMEOUT, loglevel, fastboot)
- v1.0.23~24 — squashfs+overlay 시도 (overlay workdir issue)
- v1.0.25 — plain tar 회귀 (검증)
- v1.0.26 — persistence USB FAT32 (cdrom remount fix)

---

## v1.0.13~19 (2026-05-02 → 04) — UI 정리 + Wi-Fi 진화

- v1.0.13 — fluxbox 메뉴 한글 폰트 (이후 영문 권장)
- v1.0.14 — xfce4-terminal 인자 fix (`--hold -x`)
- v1.0.15 — 메뉴 영문 only (한글 fallback 회피)
- v1.0.16 — Wi-Fi rfkill + cfg80211 + dbus + wpa_supplicant
- v1.0.17 — RTL8821CE firmware 정확 패키지명 fix
- v1.0.18 — Wi-Fi GUI (nm-connection-editor)
- v1.0.19 — Wi-Fi nmcli CLI prompt

---

## v1.0.7~12 (2026-05-02 → 04) — Wi-Fi/Ethernet driver

- v1.0.7 — linux-firmware-* 드라이버 설치 (RTL/Intel/Atheros/Broadcom/MediaTek)
- v1.0.8 — UEFI grub.cfg "Linux lts" → "Claude Code OS"
- v1.0.9~11 — squashfs 시도 (mount fail)
- v1.0.12 — plain tar 회귀

---

## v1.0.6 (2026-05-02) — 데스크톱 워크스테이션

- X11 + fluxbox + xfce4-terminal + Firefox + ibus-hangul + D2Coding
- cco user (sudo NOPASSWD), claude --dangerously-skip-permissions 자동
- VMware open-vm-tools 클립보드 sync
- 키보드 단축키 (F2/F3/F4/F11/Alt+드래그)

---

## v1.0.0 (2026-05-01) — 첫 공개

- Alpine Linux 3.20 standard ISO + initramfs `/init` 패치
- nodejs + npm + claude-code 사전 설치
- 검은 콘솔 only (X11 X)
- root autologin

---

## 비교 (v1.0.0 → v1.0.35)

| 항목 | v1.0.0 | v1.0.35 |
|---|---|---|
| 인터페이스 | 검은 콘솔 | X11 데스크톱 (fluxbox + xfce4-terminal) |
| 사용자 | root | cco (sudo NOPASSWD) |
| 한글 입력 | 불가 | ibus-hangul + D2Coding |
| Wi-Fi | 없음 | iwgtk + iwd (RTL8821CE 등) |
| OAuth | 다른 PC | Firefox 자동 |
| **Persistence** | 없음 | **Ventoy 자동 (cco-persistence.dat)** |
| 부팅 시간 | ~30s | ~30s + 3s Ventoy timeout |
| 압축 해제 | tar.gz | **squashfs 직접 mount + overlayfs (해제 0)** |
| 자동 설치 | 없음 | **`install-cco-on-ventoy.ps1/.sh` 한 줄** |
| ISO 크기 | ~400MB | ~930MB (squashfs zstd) |
