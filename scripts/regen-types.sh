#!/usr/bin/env bash
# =============================================================================
# ARENA — Régénère les types TypeScript depuis le schéma Supabase distant.
# =============================================================================
# Usage : bash scripts/regen-types.sh
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_JSON="$REPO_ROOT/.mcp.json"
OUTPUT_FILE="$REPO_ROOT/supabase/functions/_shared/database.types.ts"

[[ -f "$MCP_JSON" ]] || { echo "Erreur : .mcp.json introuvable"; exit 1; }

# Extrait project-ref via node (présent dans tous les envs Flutter)
PROJECT_REF=$(node -e "
  const m = JSON.parse(require('fs').readFileSync('$MCP_JSON', 'utf8'));
  const arg = m.mcpServers.supabase.args.find(a => a.startsWith('--project-ref='));
  if (!arg) { process.exit(1); }
  console.log(arg.replace('--project-ref=', ''));
")

[[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]] || {
  echo "Erreur : SUPABASE_ACCESS_TOKEN absent dans l'environnement."
  exit 1
}

echo "→ Génération des types pour project-ref: $PROJECT_REF"

mkdir -p "$(dirname "$OUTPUT_FILE")"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

npx -y supabase gen types typescript --project-id "$PROJECT_REF" > "$TMP"

grep -q "export type Database" "$TMP" || {
  echo "Erreur : sortie invalide (pas de 'export type Database')"
  cat "$TMP"
  exit 1
}

mv "$TMP" "$OUTPUT_FILE"
echo "✓ Types écrits dans $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE") octets)"
