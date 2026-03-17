$ErrorActionPreference = "Stop"

$VERSION = "2026.3.17"
$BACKUP_DIR = ".mobile-chat-backup"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$FILES_DIR = Join-Path $SCRIPT_DIR "files"

Write-Host ""
Write-Host "  OpenClaw Mobile Chat Installer v$VERSION" -ForegroundColor Cyan
Write-Host "  Hands-Free - Bluetooth - Phone Capabilities" -ForegroundColor DarkCyan
Write-Host ""

function Detect-OpenClaw($arg) {
    if ($arg -and (Test-Path $arg -PathType Container)) { return (Resolve-Path $arg).Path }
    $candidates = @(
        (Join-Path $HOME "openclaw"),
        (Join-Path (Get-Location) "openclaw"),
        (Get-Location).Path
    )
    foreach ($c in $candidates) {
        if ((Test-Path (Join-Path $c "package.json")) -and (Test-Path (Join-Path $c "dist"))) {
            return (Resolve-Path $c).Path
        }
    }
    return $null
}

$OPENCLAW_ROOT = Detect-OpenClaw $args[0]

if (-not $OPENCLAW_ROOT) {
    Write-Host "ERROR: Could not find OpenClaw installation." -ForegroundColor Red
    Write-Host "Usage: .\install.ps1 C:\path\to\openclaw"
    exit 1
}

if (-not (Test-Path $FILES_DIR)) {
    Write-Host "ERROR: files\ directory not found." -ForegroundColor Red
    exit 1
}

Write-Host "OpenClaw root: $OPENCLAW_ROOT"
Write-Host ""

$BACKUP_PATH = Join-Path $OPENCLAW_ROOT $BACKUP_DIR
New-Item -ItemType Directory -Force -Path $BACKUP_PATH | Out-Null

$files = Get-ChildItem -Path $FILES_DIR -Recurse -File | ForEach-Object {
    $_.FullName.Substring($FILES_DIR.Length + 1)
} | Sort-Object

$backedUp = @()
$installed = @()

Write-Host "[1/2] Backing up files that will be overwritten..."

foreach ($rel in $files) {
    $target = Join-Path $OPENCLAW_ROOT $rel
    if (Test-Path $target) {
        $backupTarget = Join-Path $BACKUP_PATH $rel
        $backupDir = Split-Path -Parent $backupTarget
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        Copy-Item $target $backupTarget -Force
        $backedUp += $rel
    }
}

$backedUp | Out-File (Join-Path $BACKUP_PATH "backed-up-files.txt") -Encoding utf8
Write-Host "  Backed up $($backedUp.Count) existing files to $BACKUP_DIR\"
Write-Host ""

Write-Host "[2/2] Installing Mobile Chat files..."

foreach ($rel in $files) {
    $src = Join-Path $FILES_DIR $rel
    $target = Join-Path $OPENCLAW_ROOT $rel
    $targetDir = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item $src $target -Force
    $installed += $rel
}

$installed | Out-File (Join-Path $BACKUP_PATH "installed-files.txt") -Encoding utf8
$newFiles = $installed.Count - $backedUp.Count

Write-Host "  Installed $($installed.Count) files ($newFiles new, $($backedUp.Count) updated)"
Write-Host ""
Write-Host "  INSTALL COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "  Access Mobile Chat at:"
Write-Host "    https://your-openclaw-domain/mobile-chat.html" -ForegroundColor Cyan
Write-Host ""
