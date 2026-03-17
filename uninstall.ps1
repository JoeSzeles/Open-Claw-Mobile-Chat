$ErrorActionPreference = "Stop"

$BACKUP_DIR = ".mobile-chat-backup"

Write-Host ""
Write-Host "  OpenClaw Mobile Chat Uninstaller" -ForegroundColor Cyan
Write-Host ""

function Detect-OpenClaw($arg) {
    if ($arg -and (Test-Path $arg -PathType Container)) { return (Resolve-Path $arg).Path }
    $candidates = @(
        (Join-Path $HOME "openclaw"),
        (Join-Path (Get-Location) "openclaw"),
        (Get-Location).Path
    )
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c $BACKUP_DIR)) { return (Resolve-Path $c).Path }
    }
    return $null
}

$OPENCLAW_ROOT = Detect-OpenClaw $args[0]

if (-not $OPENCLAW_ROOT) {
    Write-Host "ERROR: Could not find OpenClaw installation with Mobile Chat backup." -ForegroundColor Red
    Write-Host "Usage: .\uninstall.ps1 C:\path\to\openclaw"
    exit 1
}

$BACKUP_PATH = Join-Path $OPENCLAW_ROOT $BACKUP_DIR
$INSTALLED_LIST = Join-Path $BACKUP_PATH "installed-files.txt"
$BACKED_UP_LIST = Join-Path $BACKUP_PATH "backed-up-files.txt"

if (-not (Test-Path $INSTALLED_LIST)) {
    Write-Host "ERROR: No installation record found." -ForegroundColor Red
    exit 1
}

Write-Host "OpenClaw root: $OPENCLAW_ROOT"
Write-Host ""

$installedFiles = Get-Content $INSTALLED_LIST
$backedUpFiles = if (Test-Path $BACKED_UP_LIST) { Get-Content $BACKED_UP_LIST } else { @() }
$removed = 0
$restored = 0

Write-Host "[1/3] Removing new files..."

foreach ($rel in $installedFiles) {
    if ($rel -in $backedUpFiles) { continue }
    $target = Join-Path $OPENCLAW_ROOT $rel
    if (Test-Path $target) {
        Remove-Item $target -Force
        $removed++
    }
}

Write-Host "  Removed $removed new files"
Write-Host ""

Write-Host "[2/3] Restoring original files..."

foreach ($rel in $backedUpFiles) {
    $backup = Join-Path $BACKUP_PATH $rel
    $target = Join-Path $OPENCLAW_ROOT $rel
    if (Test-Path $backup) {
        $dir = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Copy-Item $backup $target -Force
        $restored++
    }
}

Write-Host "  Restored $restored original files"
Write-Host ""

Write-Host "[3/3] Cleaning up backup..."
Remove-Item $BACKUP_PATH -Recurse -Force
Write-Host "  Removed $BACKUP_DIR\"
Write-Host ""
Write-Host "  UNINSTALL COMPLETE" -ForegroundColor Green
Write-Host "  Removed: $removed  |  Restored: $restored"
Write-Host ""
