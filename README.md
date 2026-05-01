# Claude Code OS (CCO) — LiveCD

A bootable LiveCD where **Claude Code is the OS**.

Boot from this ISO, and instead of dropping you at a shell, the system logs you in as root, brings up the network, and immediately drops you into `claude`. The terminal is your desktop. The AI is your shell. There is nothing else.

![boot demo](demo/boot.gif)

> ▶ Full-quality boot recording: [demo/boot.mp4](demo/boot.mp4) · Single frame: [demo/screenshot.png](demo/screenshot.png)

**Languages**: [English](#english) · [한국어](#한국어)

---

## English

### Why this exists

Talking to an AI shouldn't require installing an OS, then drivers, then a browser, or alternately Linux + Node + npm install + login. Every layer in between is friction. The AI is the interface — so we made the OS *be* the AI. Boot, 15 seconds, OAuth code, done.

### What's good about it

1. **Anyone can use it.** Plug in a USB, boot, and you're talking to an AI in natural language. No shell command, no setup wizard, no IT helpdesk.
2. **OS install step disappears.** Deploy time = boot time. No installation manual, no driver hunt.
3. **Any PC becomes an AI workstation.** Old laptops, conference-room PCs, hotel PCs, café PCs, retired hardware. Nothing is written to the disk.
4. **Work starts the moment power comes on.** No login, no desktop, no app launcher between you and the work.
5. **No distractions.** No mail, no YouTube, no notifications, no ads. The screen has one purpose.
6. **Kiosk-ready, classroom-ready, demo-ready.** One purpose, one screen, no way to get lost.
7. **Clean shutdown.** Disk is untouched, so the next user gets a fresh machine.

### What it does (boot flow)

```
BIOS POST
  ↓
Alpine Linux 3.20 kernel + initramfs
  ↓
init patch: extract overlay tar onto sysroot
  ↓
switch_root → real Alpine userland with Node.js + npm + claude-code installed
  ↓
inittab autologin on tty1 as root
  ↓
/etc/profile.d/cco.sh:
    - banner (ANSI 256-color cyan/gold)
    - bring up loopback (lo)
    - enable IPv6 on lo (Claude OAuth callback needs ::1)
    - probe NIC drivers (vmxnet3 / e1000)
    - DHCP via udhcpc
    - start sshd
    - exec claude
  ↓
You see Claude Code, type your OAuth code, and you are in.
```

No display server. No window manager. No file manager. The OS is one program.

### Architecture

```
┌──────────────────────────────────────────────┐
│  Alpine Standard ISO 3.20.3 (upstream, vanilla)│
│  └─ /boot/initramfs-lts (patched)             │
│       └─ /init: extract /cco-root.tar.gz onto│
│                 /sysroot before switch_root  │
│  └─ /cco-root.tar.gz (we add this — the rootfs│
│      built by chroot installing nodejs + npm  │
│      + @anthropic-ai/claude-code globally)    │
└──────────────────────────────────────────────┘
```

Two design choices worth calling out:

1. **No squashfs.** Earlier iterations mounted a squashfs overlay at init time, but loop module wasn't loaded that early. busybox `tar` is always available, so the rootfs ships as a plain `.tar.gz` and we extract it directly onto `/sysroot/`. Slightly larger, but bulletproof.

2. **No apkovl auto-detect.** Alpine's standard apkovl mechanism wants to find the overlay via syslinux APPEND args, and that path was unreliable across QEMU/VMware/bare-metal. We bypass it by patching `/init` to find the tar at any of `/media/cdrom`, `/media/sr0`, `/.modloop`, `/sysroot/media/cdrom`, with a `find /` fallback.

### Build

You need a Linux build host (or WSL) with:

- `bash`, `sudo`, `tar`, `cpio`, `gzip`, `xorriso`
- Internet (for `apk` and `npm install`)
- Disk: ~2 GB free

```bash
# 1. Get the upstream Alpine ISO once
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-standard-3.20.3-x86_64.iso

# 2. Get a minirootfs tarball
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz \
  -O alpine-minirootfs.tar.gz

# 3. Build (asks for sudo password once)
sudo ./build-rootfs.sh    # apk add + npm install + chroot fixups → cco-root.tar.gz
sudo ./build-iso.sh       # patches initramfs, repackages ISO → cco-livecd.iso

# 4. Boot it
qemu-system-x86_64 -m 2048 -cdrom cco-livecd.iso -boot d
```

### Run on VMware

```
- 2 vCPU / 2 GB RAM minimum
- Network adapter: e1000 or vmxnet3 (both work — drivers auto-probed)
- Boot order: CD/DVD first
- Mount cco-livecd.iso, power on
- After ~15 seconds you should see the banner + claude prompt
```

### Default credentials

The image ships with a deliberately weak demo password:

```
user: root
pass: cco
```

This is a LiveCD for tinkering. If you want to expose SSH on a network you don't trust, change the root password (`passwd`) and regenerate the SSH host keys (`rm /etc/ssh/ssh_host_*; ssh-keygen -A`) on first boot.

### What it is not

- Not a daily driver OS. There is no GUI, no package manager UI, no installer. The disk is read-only.
- Not a sandbox. `claude` runs as root with full network access. Don't run it on a machine you care about.
- Not affiliated with Anthropic. This image just happens to install their official CLI from npm.

### License

MIT. See [LICENSE](LICENSE).

The Alpine Linux base is under its own license (mostly MIT/BSD/GPL — see Alpine's docs). The Claude Code CLI (`@anthropic-ai/claude-code`) is licensed by Anthropic under their own terms; this repo only ships build scripts that fetch it from npm at build time.

---

## 한국어

부팅 가능한 LiveCD ISO 입니다. **Claude Code 가 OS 자체** 입니다.

이 ISO 로 부팅하면 데스크톱도, 브라우저도, 메뉴바도 없습니다. 자동 로그인 → 네트워크 자동 연결 → 화면에 바로 `claude` 가 뜹니다. 터미널이 데스크톱이고, AI 가 셸입니다. 그 외엔 아무것도 없습니다.

### 왜 이렇게 만들었나

AI 와 대화 한 번 하려고 — Windows 깔고, 드라이버 잡고, 브라우저 깔고. 또는 Linux 깔고, Node 깔고, `npm install` 하고, 로그인하고. 단계가 너무 많습니다. 컴퓨터 좀 한다는 사람도 헤매고, 모르는 사람한테는 거의 불가능에 가깝습니다.

AI 가 인터페이스 그 자체인데, 왜 그 앞에 OS 와 설치 과정을 끼워두는가. 그래서 OS 자체를 AI 로 만들었습니다.

부팅 → 15초 → 인증 → AI.

### 이렇게 만들어서 좋은 점

1. **누구나 씁니다.** 컴퓨터 모르는 초보자도, USB 한 개만 꽂고 부팅하면 그 자리에서 AI 와 대화. shell 한 줄, 명령어 한 개 칠 필요 없습니다. 자연어로 시키면 AI 가 알아서 합니다.

2. **OS 설치 단계 자체가 사라집니다.** 디플로이 시간 = 부팅 시간. 설치 매뉴얼도, IT 지원 콜도 필요 없습니다.

3. **버려진 PC, 낡은 노트북, 회의실 PC, 호텔 PC, 카페 PC — 어디든 즉시 AI 워크스테이션이 됩니다.** 디스크에 흔적도 남지 않습니다.

4. **켜자마자 일이 시작됩니다.** 단계 0. 시동에서 작업 사이에 군더더기가 없습니다.

5. **딴 앱으로 새지 않습니다.** 메일, 유튜브, 알림, 광고 — 산만함의 원천이 화면에 존재하지 않습니다. AI 한 가지에만 집중.

6. **키오스크, 교육실, 데모 부스에 그대로 박을 수 있습니다.** 단일 목적 = 단일 화면. 사용자가 헤맬 여지 자체가 없습니다.

7. **종료하면 깨끗.** 디스크에 아무것도 남지 않습니다. 다음 사람한테 PC 넘겨도 안전.

### 빌드 방법

Linux 또는 WSL 환경에서 (위 영어 섹션의 [Build](#build) 참고):

```bash
# 1. Alpine 표준 ISO 다운로드
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-standard-3.20.3-x86_64.iso

# 2. minirootfs 다운로드
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz \
  -O alpine-minirootfs.tar.gz

# 3. 빌드
sudo ./build-rootfs.sh
sudo ./build-iso.sh

# 4. 부팅
qemu-system-x86_64 -m 2048 -cdrom cco-livecd.iso -boot d
```

### 기본 로그인

```
user: root
pass: cco
```

이 비밀번호는 demo 용이라 일부러 약합니다. 신뢰할 수 없는 네트워크에 SSH 를 열 거라면 부팅 후 `passwd` 로 변경하고, `rm /etc/ssh/ssh_host_*; ssh-keygen -A` 로 호스트 키를 새로 만드세요.

### 이건 이런 게 아닙니다

- 데일리 드라이버 OS 가 아닙니다. GUI, 패키지 매니저 UI, 설치 프로그램 없음.
- 샌드박스가 아닙니다. `claude` 가 root 로 동작하며 네트워크 권한 풀로 가집니다. 중요한 머신에는 띄우지 마세요.
- Anthropic 과 무관합니다. 빌드 시 npm 에서 공식 CLI 를 받아 설치할 뿐입니다.

### 라이선스

MIT. [LICENSE](LICENSE) 참고.

Alpine Linux 베이스는 자체 라이선스 (대부분 MIT/BSD/GPL — Alpine 문서 참고). Claude Code CLI (`@anthropic-ai/claude-code`) 는 Anthropic 의 자체 라이선스. 이 저장소는 빌드 시 npm 에서 받아오는 스크립트만 포함합니다.
