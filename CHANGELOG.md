# CHANGELOG

**한국어** · [English](CHANGELOG.en.md)

---

## v1.0.6 (2026-05-02) — 데스크톱 워크스테이션

![v1.0.6 한글 입력](demo/v1.0.6-korean-input.jpg)

부팅 즉시 X11 데스크톱 + 한글 + Firefox + 한 줄도 안 쳐도 claude OAuth 끝나는 환경.

### 추가
- **X11 GUI 환경** — Xorg + fluxbox (가벼운 윈도우 매니저). 부팅 후 검은 콘솔이 아닌 데스크톱 화면.
- **한글 입력** — `ibus-hangul` + Noto CJK + **D2Coding** 폰트 (네이버, 한국 개발자 인기). 한영 키 토글.
- **xfce4-terminal** — `xterm` 대체. **Ctrl+Shift+V 붙여넣기**, 탭, modern UI, 다크 테마.
- **Firefox ESR** — `chromium` 대체. claude OAuth URL 자동 감지 후 새 탭 + 자동 focus. **첫 창 닫을 필요 없음**.
- **cco user (uid 1000)** — root 직접 사용 폐기. wheel/video/input/audio/tty group 박힘. `sudo NOPASSWD`.
- **`--dangerously-skip-permissions` 자동** — claude wrapper 가 항상 bypass mode 시작. 매번 Y 안 눌러도 됨.
- **VMware host 클립보드 연동** — `open-vm-tools` + `xf86-input-vmmouse`. host 의 복사 → VM 붙여넣기.
- **VMware SVGA 동적 해상도** — `xf86-video-vmware` + `xrandr`. host 창 크기 따라 자동 조정.
- **사용자 단축키** — F2 Firefox / F3 Terminal / F4 Claude / F11 Fullscreen / Alt+Mouse1 창 이동.
- **`script(1)` pty wrapper** — claude 의 `Input must be provided either through stdin or as a prompt argument` 오류 해결.
- **OAuth URL 자동 감지** — wrapper 가 claude 출력 모니터링 → `https://...` URL 감지 시 Firefox 새 탭 spawn.
- **Xorg setcap** — `cap_sys_rawio,cap_dac_override,cap_sys_admin+ep`. 일반 사용자가 X 띄울 때 I/O 포트 권한.
- **xhost + .Xauthority cookie 복사** — X 세션 권한 충돌 해결.
- **세계 최초 인증 + 데모 영상** — README 의 부팅 GIF · 한글 입력 스크린샷.

### 변경
- **버전 명명 규칙** SemVer (v1.0.0, v1.0.1, ...). 이전 v1~v25 폐기.
- **default user**: `root` → `cco`.
- **default browser**: `chromium --no-sandbox` → `firefox`.
- **default terminal**: `xterm` → `xfce4-terminal`.
- **autologin TTY**: tty1 root → tty1 cco → tty1 cco (sudo wheel) (최종).
- **plain tar overlay** — `cco-root.tar.gz` (gzip) → `cco-root.tar` (압축 X). busybox tar 가 1.5GB 풀기 30~60초 (gzip 보다 빠름).

### 수정
- 키보드 입력 안 됨 → `eudev` + `xf86-input-vmmouse` 추가.
- 화면 잘림 → `xf86-video-vmware` (SVGA) + xterm geometry 조정.
- `failed to enable I/O ports 0000-03ff` → Xorg setcap + cco 가 video/input group 멤버.
- `xauth: file /home/cco/.Xauthority does not exist` → root 의 .Xauthority cookie 를 cco home 으로 복사 + `xhost +SI:localuser:cco`.
- chromium 두 인스턴스 (사장님이 첫 창 닫아야 두 번째 보임) → firefox single-instance 로 해결.
- chromium 창 focus 안 옮겨감 → firefox + wmctrl auto-raise.
- `--print` 모드 자동 진입 → script(1) pty 보존으로 회피.

### ISO 정보
- 크기: ~1.9GB
- 패키지: 365 (firefox + xfce4-terminal + ibus + Xorg + chromium 잔존 fallback 포함)
- 빌드 시간: 약 5분
- 부팅 시간: VMware ESXi 기준 약 30~60초

---

## v1.0.0 (2026-05-01) — 첫 공개판 (Console only)

![v1 부팅](demo/boot.gif)

### 추가
- Alpine Linux 3.20 standard ISO 기반.
- initramfs `/init` 패치 — `tar xzf /cco-root.tar.gz` 으로 overlay 풀기.
- chroot 안에서 Node.js + npm + `@anthropic-ai/claude-code` 사전 설치.
- inittab tty1 autologin (root).
- `/etc/profile.d/cco.sh` — 배너 (ANSI 256-color cyan/gold), loopback 활성, IPv6 활성, NIC probe (vmxnet3/e1000), DHCP, sshd, exec claude.
- "Claude Code OS" ASCII 배너.
- 부팅 데모 영상 + GIF + 단일 프레임 스크린샷.
- 영문/한국어 README (한국어 우선).

### 한계
- 검은 콘솔만 (X11 없음).
- 키보드만, GUI 마우스 없음.
- 한글 입력 불가.
- claude OAuth = 다른 PC 브라우저에서 인증 후 코드 입력.
- root 권한 → `--dangerously-skip-permissions` 거부.

---

## 비교 표

| 항목 | v1.0.0 | v1.0.6 |
|---|---|---|
| 인터페이스 | 검은 콘솔 | X11 데스크톱 (fluxbox) |
| 사용자 | root | cco (sudo NOPASSWD) |
| 터미널 | TTY (Linux 콘솔) | xfce4-terminal (탭, Ctrl+Shift+V) |
| 폰트 | console default | D2Coding (한국 개발자 인기) |
| 한글 입력 | 불가 | ibus-hangul (한영 키) |
| 브라우저 | 없음 | Firefox ESR (자동 OAuth) |
| OAuth 인증 | 다른 PC 브라우저 + 코드 | VM 안에서 자동 (URL 감지 → 새 탭) |
| `--dangerously-skip-permissions` | 거부 (root) | 자동 (cco) |
| 마우스 | 안 됨 | 동작 (vmmouse) + Alt+드래그 창 이동 |
| 클립보드 | host 와 분리 | VMware 통합 (open-vm-tools) |
| 단축키 | 없음 | F2/F3/F4/F11 |
| ISO 크기 | ~400MB | ~1.9GB |
