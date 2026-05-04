<#
.SYNOPSIS
  Claude Code OS — Ventoy USB 에 cco 파일 자동 설치 (Windows)

.DESCRIPTION
  Ventoy 가 설치된 USB drive 에 cco-alpine ISO + persistence + ventoy.json 자동 다운로드 + 복사.

.EXAMPLE
  PS> .\install-cco-on-ventoy.ps1 -Drive F:
  PS> .\install-cco-on-ventoy.ps1                # 자동 USB 검색

.NOTES
  Ventoy 미설치 시 https://www.ventoy.net 에서 먼저 설치.
#>

param(
    [string]$Drive = "",
    [string]$Version = "latest"
)

$ErrorActionPreference = 'Stop'

# 1. USB drive 자동 검색 (Ventoy label)
if (-not $Drive) {
    $vols = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.FileSystemLabel -eq 'VENTOY' -or $_.FileSystemLabel -eq 'Ventoy' }
    if ($vols.Count -eq 0) {
        Write-Host "Ventoy USB 못 찾음. -Drive 옵션으로 명시. 예: -Drive F:" -ForegroundColor Red
        Write-Host "또는 Ventoy 미설치 — https://www.ventoy.net 설치한 후 다시 실행."
        exit 1
    }
    $Drive = "$($vols[0].DriveLetter):"
    Write-Host "USB 발견: $Drive (label=$($vols[0].FileSystemLabel))" -ForegroundColor Green
}

if (-not (Test-Path $Drive)) {
    Write-Host "Drive $Drive 없음." -ForegroundColor Red
    exit 1
}

# 2. Latest version 검색
if ($Version -eq 'latest') {
    Write-Host "Latest version 검색..."
    $rel = Invoke-RestMethod 'https://api.github.com/repos/Hostingglobal-Tech/claude-code-os/releases/latest'
    $Version = $rel.tag_name
    Write-Host "Latest: $Version" -ForegroundColor Green
}

$base = "https://github.com/Hostingglobal-Tech/claude-code-os/releases/download/$Version"
$iso  = "cco-alpine-$Version.iso"

# 3. ISO download
$isoPath = "$Drive\$iso"
if (-not (Test-Path $isoPath)) {
    Write-Host "Downloading $iso (~930 MB)..." -ForegroundColor Cyan
    Invoke-WebRequest "$base/$iso" -OutFile $isoPath -UseBasicParsing
} else {
    Write-Host "Already exists: $iso" -ForegroundColor Yellow
}

# 4. persistence.dat download
$persistPath = "$Drive\cco-persistence.dat"
if (-not (Test-Path $persistPath)) {
    Write-Host "Downloading cco-persistence.dat (~1 GB)..." -ForegroundColor Cyan
    Invoke-WebRequest "$base/cco-persistence.dat" -OutFile $persistPath -UseBasicParsing
} else {
    Write-Host "Already exists: cco-persistence.dat" -ForegroundColor Yellow
}

# 5. ventoy.json
$ventoyDir = "$Drive\ventoy"
New-Item -ItemType Directory -Path $ventoyDir -Force | Out-Null
$jsonPath = "$ventoyDir\ventoy.json"
$json = @"
{
    "control": [
        { "VTOY_DEFAULT_MENU_MODE": "0" },
        { "VTOY_MENU_TIMEOUT": "3" },
        { "VTOY_DEFAULT_IMAGE": "/$iso" }
    ],
    "persistence": [
        {
            "image": "/$iso",
            "backend": "/cco-persistence.dat",
            "autosel": 1
        }
    ]
}
"@
Set-Content $jsonPath -Value $json -Encoding ASCII

Write-Host ""
Write-Host "=========================================="-ForegroundColor Green
Write-Host "  Done. Boot USB on target PC." -ForegroundColor Green
Write-Host "=========================================="-ForegroundColor Green
Write-Host ""
Write-Host "  USB: $Drive"
Get-ChildItem $Drive | Where-Object Name -match 'cco|ventoy' | Select-Object Name, @{n='MB';e={if($_.PSIsContainer){'<DIR>'}else{[math]::Round($_.Length/1MB)}}}
