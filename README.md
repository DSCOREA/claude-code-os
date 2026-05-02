# Claude Code OS (CCO) — LiveCD

**Claude Code 가 OS 자체** 인 부팅 가능한 LiveCD ISO 입니다.

USB 한 개 꽂고 부팅하면 — 자동 로그인 → 데스크톱 → 한글 입력 가능한 터미널 → claude 자동 시작 → OAuth URL 자동으로 Firefox 새 탭에 뜸. 사장님은 인증만 하면 끝.

![v1.0.6 한글 입력](demo/v1.0.6-korean-input.jpg)

> 위 화면: v1.0.6 부팅 후 한글 입력 + claude 응답. xfce4-terminal + D2Coding 폰트 + ibus-hangul.

> 📋 [전체 변경 이력 (v1.0.0 → v1.0.6)](CHANGELOG.md) · [Initial console boot](demo/boot.gif) · [부팅 영상 mp4](demo/boot.mp4)

**Languages**: [한국어](#한국어) · [English](#english)

---

## 한국어

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

### 부팅 흐름

```
BIOS POST
  ↓
Alpine Linux 3.20 커널 + initramfs
  ↓
init patch: overlay tar 를 sysroot 위에 풀기
  ↓
switch_root → Node.js + npm + claude-code 가 박힌 실 Alpine 환경
  ↓
inittab 가 tty1 에 root 자동 로그인
  ↓
/etc/profile.d/cco.sh:
    - 배너 표시 (ANSI 256-color cyan/gold)
    - loopback (lo) 활성
    - lo IPv6 활성 (Claude OAuth callback 이 ::1 에 bind)
    - NIC 드라이버 probe (vmxnet3 / e1000)
    - DHCP (udhcpc)
    - sshd 시작
    - exec claude
  ↓
Claude Code 화면이 뜨고, OAuth 코드 입력하면 끝.
```

디스플레이 서버 없음. 윈도우 매니저 없음. 파일 매니저 없음. OS 가 곧 한 프로그램입니다.

### ISO 다운로드 + 사용

빌드된 `cco-alpine-vX.Y.Z.iso` 를 [Releases](https://github.com/Hostingglobal-Tech/claude-code-os/releases) 에서 다운로드 후:

**VMware 에서 실행**
```
- 2 vCPU / 4 GB RAM 이상 권장
- 네트워크 어댑터: e1000 또는 vmxnet3
- 부팅 순서: CD/DVD 우선
- ISO 마운트 후 전원 ON
- 약 30~60초 후 데스크톱 + claude 프롬프트
```

**물리 PC 에 USB 로 굽기** (Windows)
```powershell
# Rufus 또는 Etcher 사용 (DD 모드)
# 또는 PowerShell 의 dd 명령
```

**물리 PC 에 USB 로 굽기** (Linux/macOS)
```bash
sudo dd if=cco-alpine-vX.Y.Z.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### 기본 로그인 (v1.0.6)

```
user: cco         (자동 로그인, sudo NOPASSWD)
pass: cco
root pass: cco    (응급 시만)
```

`cco` 사용자가 데스크톱 + claude 모두 실행. `root` 직접 사용 X (claude 의 `--dangerously-skip-permissions` 가 root 거부).

데모 비번이라 약합니다. 신뢰할 수 없는 네트워크에 SSH 를 열 거라면 부팅 후 `sudo passwd cco` 로 변경하고, `sudo rm /etc/ssh/ssh_host_*; sudo ssh-keygen -A` 로 호스트 키를 새로 만드세요.

### 단축키 (v1.0.6)

| 키 | 동작 |
|---|---|
| `F2` | Firefox |
| `F3` | 새 터미널 |
| `F4` | 새 Claude |
| `F11` | Fullscreen |
| `Alt+Mouse1` | 창 이동 |
| `Alt+Mouse3` | 창 크기 조정 |
| `Alt+Tab` | 창 전환 |
| `Ctrl+Shift+V` | 터미널 붙여넣기 |
| 한영 | 한글/영문 토글 |
| 우클릭 (바탕화면) | 메뉴 |

### 이건 이런 게 아닙니다

- 데일리 드라이버 OS 가 아닙니다. GUI, 패키지 매니저 UI, 설치 프로그램 없음.
- 샌드박스가 아닙니다. `claude` 가 root 로 동작하며 네트워크 권한 풀로 가집니다. 중요한 머신에는 띄우지 마세요.
- Anthropic 과 무관합니다. 빌드 시 npm 에서 공식 CLI 를 받아 설치할 뿐입니다.

### 라이선스

MIT. [LICENSE](LICENSE) 참고.

Alpine Linux 베이스는 자체 라이선스 (대부분 MIT/BSD/GPL — Alpine 문서 참고). Claude Code CLI (`@anthropic-ai/claude-code`) 는 Anthropic 의 자체 라이선스. 이 저장소는 빌드 시 npm 에서 받아오는 스크립트만 포함합니다.

---

## English

A bootable LiveCD where **Claude Code is the OS**. Boot from this ISO, and instead of dropping you at a shell, the system logs you in as root, brings up the network, and immediately drops you into `claude`. The terminal is your desktop. The AI is your shell. There is nothing else.

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

### Download + run

Grab `cco-alpine-vX.Y.Z.iso` from the [Releases](https://github.com/Hostingglobal-Tech/claude-code-os/releases) page.

**VMware**
- 2 vCPU / 4 GB RAM (recommended)
- Network adapter: e1000 or vmxnet3
- Boot order: CD/DVD first
- ~30–60s after power-on, you'll see the desktop + claude prompt.

**USB on bare metal** (Linux/macOS)
```bash
sudo dd if=cco-alpine-vX.Y.Z.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Windows: use Rufus or balenaEtcher in DD mode.

### Default credentials (v1.0.6)

```
user: cco         (autologin, sudo NOPASSWD)
pass: cco
root pass: cco    (emergency only)
```

`cco` runs the desktop and claude. `root` is not used directly — claude's `--dangerously-skip-permissions` rejects root.

Demo password — change it (`sudo passwd cco`) and regenerate SSH host keys (`sudo rm /etc/ssh/ssh_host_*; sudo ssh-keygen -A`) before exposing on an untrusted network.

### Keyboard shortcuts (v1.0.6)

| Key | Action |
|---|---|
| `F2` | Firefox |
| `F3` | New terminal |
| `F4` | New Claude |
| `F11` | Fullscreen |
| `Alt+Mouse1` | Move window |
| `Alt+Mouse3` | Resize window |
| `Alt+Tab` | Switch window |
| `Ctrl+Shift+V` | Paste in terminal |
| Hangul key | Korean/English toggle |
| Right-click on desktop | Menu |

### What it is not

- Not a daily-driver OS. No GUI, no installer, no package manager UI.
- Not a sandbox. `claude` runs as root with full network access — don't run it on a machine you care about.
- Not affiliated with Anthropic. We just install their official CLI from npm at build time.

### License

MIT. See [LICENSE](LICENSE). Alpine Linux base is under its own licenses (mostly MIT/BSD/GPL). The Claude Code CLI (`@anthropic-ai/claude-code`) is licensed by Anthropic; this repo only contains build scripts that fetch it from npm.
