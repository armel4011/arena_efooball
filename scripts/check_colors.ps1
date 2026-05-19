# ─────────────────────────────────────────────────────────────────────────────
# scripts/check_colors.ps1 — Arena design-system color guard (Windows)
# ─────────────────────────────────────────────────────────────────────────────
# Mirror of check_colors.sh for PowerShell users. Reports every hardcoded
# color literal in lib/ (`Color(0xFF...)` or `Colors.{white,black,…}`).
#
# Files in scripts/colors_allowlist.txt are exempt (brand-protected,
# overlay isolate, scrim, etc.). Violations in non-allowlisted files
# are flagged as regressions.
#
# Usage:  pwsh scripts/check_colors.ps1
#         pwsh scripts/check_colors.ps1 -Strict
# ─────────────────────────────────────────────────────────────────────────────
param([switch]$Strict)

$root = Split-Path -Parent $PSCommandPath | Split-Path -Parent
Set-Location $root

$allowlistFile = "scripts/colors_allowlist.txt"
$allowed = @()
if (Test-Path $allowlistFile) {
  $allowed = Get-Content $allowlistFile | ForEach-Object {
    # Strip comments + trim
    ($_ -replace '#.*$', '').Trim()
  } | Where-Object { $_ -ne '' }
}

$pattern = 'Color\(0x[0-9A-Fa-f]{8}\)|Colors\.(white|black|red|blue|green|yellow|orange|purple|grey|gray|amber|cyan|pink|teal|indigo|lime|brown)'

$hits = Get-ChildItem -Path lib -Recurse -Filter *.dart |
        Where-Object { $_.FullName -notmatch 'core[\\/]theme' } |
        Select-String -Pattern $pattern

if ($hits.Count -eq 0) {
  Write-Host "0 color violations in lib/. ✅"
  exit 0
}

$allowedCount = 0
$regressions = @()

foreach ($h in $hits) {
  $relPath = (Resolve-Path -Relative $h.Path) -replace '^\.[\\/]', '' -replace '\\', '/'
  if ($allowed -contains $relPath) {
    $allowedCount++
  } else {
    $regressions += "${relPath}:$($h.LineNumber): $($h.Line.Trim())"
  }
}

Write-Host "── Color violations report"
Write-Host "  Allowed (KEEP, see scripts/colors_allowlist.txt): $allowedCount"
Write-Host "  Regressions (un-allowlisted files):              $($regressions.Count)"

if ($regressions.Count -gt 0) {
  Write-Host ""
  Write-Host "── Regressions (first 20 lines):"
  $regressions | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
  Write-Host ""
  Write-Host "Action requise : remplacer par un token ArenaColors.*, OU ajouter"
  Write-Host "le fichier à scripts/colors_allowlist.txt si la KEEP est justifiée"
  Write-Host "(brand-protected, overlay isolate, scrim, contrast gradient, etc.)."
}

if ($Strict -and $regressions.Count -gt 0) { exit 1 }
