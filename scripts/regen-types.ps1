#!/usr/bin/env pwsh
# =============================================================================
# ARENA - Regenerate TypeScript types from the remote Supabase schema.
# =============================================================================
# Usage : pwsh scripts/regen-types.ps1
#         (or  : .\scripts\regen-types.ps1 from PowerShell)
#
# Prerequisites :
#   - Node.js (for npx)
#   - User env var SUPABASE_ACCESS_TOKEN (already configured)
#
# What it does :
#   1. Reads project-ref from .mcp.json (single source of truth)
#   2. Verifies SUPABASE_ACCESS_TOKEN is set
#   3. Calls "npx supabase gen types typescript --project-id <ref>"
#   4. Writes result to supabase/functions/_shared/database.types.ts
# =============================================================================

$ErrorActionPreference = "Stop"

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$McpJson    = Join-Path $RepoRoot ".mcp.json"
$OutputFile = Join-Path $RepoRoot "supabase\functions\_shared\database.types.ts"

# 1. project-ref from .mcp.json
if (-not (Test-Path $McpJson)) { throw ".mcp.json not found: $McpJson" }
$mcp = Get-Content $McpJson -Raw | ConvertFrom-Json
$projectArgs = $mcp.mcpServers.supabase.args
$projectRef  = ($projectArgs | Where-Object { $_ -like "--project-ref=*" }) -replace "^--project-ref=", ""
if (-not $projectRef) { throw "project-ref not found in .mcp.json" }

# 2. Token : env (process) -> env (user, permanent) -> .env file
$token = $env:SUPABASE_ACCESS_TOKEN
if (-not $token) {
  $token = [Environment]::GetEnvironmentVariable("SUPABASE_ACCESS_TOKEN", "User")
}
if (-not $token) {
  $envFile = Join-Path $RepoRoot ".env"
  if (Test-Path $envFile) {
    $line = Select-String -Path $envFile -Pattern "^\s*SUPABASE_ACCESS_TOKEN\s*=\s*(.+)$" | Select-Object -First 1
    if ($line) { $token = $line.Matches[0].Groups[1].Value.Trim('"', "'", " ") }
  }
}
if (-not $token) {
  throw "SUPABASE_ACCESS_TOKEN not found in env nor in .env file."
}
$env:SUPABASE_ACCESS_TOKEN = $token

Write-Host "-> Generating types for project-ref: $projectRef" -ForegroundColor Cyan

# 3. Generation (Supabase CLI via npx) - uses cmd /c so npm stderr warnings
#    don't trip PowerShell's NativeCommandError.
$outDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$tmp = New-TemporaryFile
try {
  cmd /c "npx -y supabase gen types typescript --project-id $projectRef > `"$tmp`" 2>NUL"
  if ($LASTEXITCODE -ne 0) { throw "supabase gen types failed (code $LASTEXITCODE)" }

  # 4. Sanity check : must contain "export type Database"
  $content = Get-Content $tmp -Raw
  if (-not $content -or $content -notmatch "export type Database") {
    throw "Invalid output (no 'export type Database' detected)."
  }

  Move-Item -Force $tmp $OutputFile
  $size = (Get-Item $OutputFile).Length
  Write-Host "[OK] Types written to $OutputFile ($size bytes)" -ForegroundColor Green
}
finally {
  if (Test-Path $tmp) { Remove-Item -Force $tmp -ErrorAction SilentlyContinue }
}
