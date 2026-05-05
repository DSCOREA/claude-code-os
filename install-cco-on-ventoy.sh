#!/bin/bash
# Claude Code OS — Ventoy USB 에 cco 파일 자동 설치 (Linux/macOS)
#
# Usage:
#   ./install-cco-on-ventoy.sh                 # 자동 USB 검색
#   ./install-cco-on-ventoy.sh /mnt/usb        # mount point 명시
#   ./install-cco-on-ventoy.sh /mnt/usb v1.0.34
set -e

USB_PATH="${1:-}"
VERSION="${2:-latest}"

# 1. USB 자동 검색 (Ventoy label)
if [ -z "$USB_PATH" ]; then
    if command -v lsblk >/dev/null 2>&1; then
        USB_PATH=$(lsblk -no MOUNTPOINT,LABEL | awk '$2 ~ /^[Vv]entoy$/ {print $1; exit}')
    fi
    if [ -z "$USB_PATH" ] && [ -d /Volumes/Ventoy ]; then  # macOS
        USB_PATH=/Volumes/Ventoy
    fi
    if [ -z "$USB_PATH" ]; then
        echo "Error: Ventoy USB 못 찾음. mount point 명시: $0 /mnt/usb"
        echo "Ventoy 미설치 시 https://www.ventoy.net 설치한 후 다시 실행."
        exit 1
    fi
    echo "USB 발견: $USB_PATH"
fi

[ -d "$USB_PATH" ] || { echo "Error: $USB_PATH not a directory"; exit 1; }

# 2. Latest version 검색
if [ "$VERSION" = "latest" ]; then
    echo "Latest version 검색..."
    VERSION=$(curl -s 'https://api.github.com/repos/Hostingglobal-Tech/claude-code-os/releases/latest' | grep -oE '"tag_name":\s*"[^"]+"' | head -1 | cut -d'"' -f4)
    echo "Latest: $VERSION"
fi

BASE="https://github.com/Hostingglobal-Tech/claude-code-os/releases/download/$VERSION"
ISO="cco-alpine-$VERSION.iso"

# 3. ISO download
if [ ! -f "$USB_PATH/$ISO" ]; then
    echo "Downloading $ISO (~930 MB)..."
    curl -L -o "$USB_PATH/$ISO" "$BASE/$ISO"
else
    echo "Already exists: $ISO"
fi

# 4. persistence.dat
if [ ! -f "$USB_PATH/cco-persistence.dat" ]; then
    echo "Downloading cco-persistence.dat (~1 GB)..."
    curl -L -o "$USB_PATH/cco-persistence.dat" "$BASE/cco-persistence.dat"
else
    echo "Already exists: cco-persistence.dat"
fi

# 5. ventoy.json
mkdir -p "$USB_PATH/ventoy"
cat > "$USB_PATH/ventoy/ventoy.json" <<EOF
{
    "control": [
        { "VTOY_DEFAULT_MENU_MODE": "0" },
        { "VTOY_MENU_TIMEOUT": "3" },
        { "VTOY_DEFAULT_IMAGE": "/$ISO" }
    ],
    "persistence": [
        {
            "image": "/$ISO",
            "backend": "/cco-persistence.dat",
            "autosel": 1
        }
    ]
}
EOF

echo ""
echo "=========================================="
echo "  Done. Boot USB on target PC."
echo "=========================================="
echo ""
echo "  USB: $USB_PATH"
ls -lah "$USB_PATH" | grep -E 'cco-|ventoy'
