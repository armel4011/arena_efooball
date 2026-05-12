# ─────────────────────────────────────────────────────────────────────────────
# scripts/check_spacing.ps1 — Arena design-system spacing guard (Windows)
# ─────────────────────────────────────────────────────────────────────────────
# Mirror of check_spacing.sh for PowerShell users.
# Reports every hardcoded numeric literal passed to EdgeInsets.* / SizedBox()
# in lib/. Use `ArenaSpacing.{xs,sm,md,lg,xl,xxl,xxxl}` instead.
#
# Usage:  pwsh scripts/check_spacing.ps1
#         pwsh scripts/check_spacing.ps1 -Strict
# ─────────────────────────────────────────────────────────────────────────────
param([switch]$Strict)

$root = Split-Path -Parent $PSCommandPath | Split-Path -Parent
Set-Location $root

$patterns = @(
  'EdgeInsets\.all\([0-9]+\.?[0-9]*\)',
  'EdgeInsets\.only\([^)]*[a-z]:\s*[0-9]+\.?[0-9]*',
  'EdgeInsets\.symmetric\([^)]*[a-z]:\s*[0-9]+\.?[0-9]*',
  'EdgeInsets\.fromLTRB\([0-9\s,\.]+\)',
  'SizedBox\([^)]*(height|width):\s*[0-9]+\.?[0-9]*'
)

$total = 0
foreach ($p in $patterns) {
  $hits = Get-ChildItem -Path lib -Recurse -Filter *.dart |
          Select-String -Pattern $p
  if ($hits.Count -gt 0) {
    Write-Host "── $p ($($hits.Count) occurrences)"
    $hits | Select-Object -First 5 | ForEach-Object {
      Write-Host "  $($_.Path):$($_.LineNumber)"
    }
    Write-Host "  …"
    $total += $hits.Count
  }
}

Write-Host ""
Write-Host "Total spacing violations: $total"
Write-Host "Target tokens: ArenaSpacing.xs (4) / sm (8) / md (12) / lg (16) / xl (20) / xxl (24) / xxxl (32)"

if ($Strict -and $total -gt 0) { exit 1 }
