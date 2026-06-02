#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/check_colors.sh — Arena design-system color guard
# ─────────────────────────────────────────────────────────────────────────────
# Reports every hardcoded color literal in lib/ (`Color(0xFF...)` or
# `Colors.{white,black,red,...}`). The Arena design system exposes
# `ArenaColors.*` tokens and these should be used instead.
#
# Files in `scripts/colors_allowlist.txt` are flagged as known KEEPs
# (brand-protected widgets, overlay isolate, gradient contrast, etc.).
# Any violation in a NON-allowlisted file is treated as a regression.
#
# Usage:  bash scripts/check_colors.sh           # report all violations
#         bash scripts/check_colors.sh --strict  # exit 1 if regression found
#
# Mirror of `check_spacing.sh` — applies until custom_lint is compatible
# with analyzer 7.7+. See `analysis_options.yaml` for project context.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

cd "$(dirname "$0")/.."

allowlist_file="scripts/colors_allowlist.txt"

# Forbidden literal patterns:
#   Color(0xFF1A1A22)       → ArenaColors.carbon2 ✅
#   Colors.white            → ArenaColors.bone ou Colors.white avec KEEP
#   Colors.black.withValues(alpha: 0.35) → KEEP (scrim, voir allowlist)
# NB : `(^|[^A-Za-z])` devant `Colors\.` évite les faux positifs sur les
# tokens du design system dont le nom contient "Colors." en sous-chaîne
# (ex. `ArenaColors.blackPure` matchait `Colors.black`).
pattern='(Color\(0x[0-9A-Fa-f]{8}\)|(^|[^A-Za-z])Colors\.(white|black|red|blue|green|yellow|orange|purple|grey|gray|amber|cyan|pink|teal|indigo|lime|brown))'

# Load allowlist into a bash array (skip comments and empty lines).
allowed=()
if [ -f "$allowlist_file" ]; then
  while IFS= read -r line; do
    trimmed="${line%%#*}"
    trimmed="${trimmed#"${trimmed%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    if [ -n "$trimmed" ]; then
      allowed+=("$trimmed")
    fi
  done < "$allowlist_file"
fi

is_allowed() {
  local file="$1"
  for a in "${allowed[@]+"${allowed[@]}"}"; do
    if [ "$file" = "$a" ]; then return 0; fi
  done
  return 1
}

# Collect all violations as `<path>:<line>:<match>` then split by allow.
# Note: `--exclude-dir` matches by basename only, so we filter `core/theme`
# explicitly via grep -v after collection.
violations="$(grep -REn --include='*.dart' -E -- "$pattern" lib 2>/dev/null \
  | grep -Ev '(^|/)lib/core/theme/' || true)"

if [ -z "$violations" ]; then
  echo "0 color violations in lib/. ✅"
  exit 0
fi

regression_count=0
allowed_count=0
regression_files=()

while IFS= read -r line; do
  [ -z "$line" ] && continue
  file="${line%%:*}"
  # Normalize separators in case grep returns Windows-style paths.
  file="${file//\\//}"
  if is_allowed "$file"; then
    allowed_count=$((allowed_count + 1))
  else
    regression_count=$((regression_count + 1))
    regression_files+=("$line")
  fi
done <<< "$violations"

echo "── Color violations report"
echo "  Allowed (KEEP, see scripts/colors_allowlist.txt): $allowed_count"
echo "  Regressions (un-allowlisted files):              $regression_count"

if [ "$regression_count" -gt 0 ]; then
  echo ""
  echo "── Regressions (first 20 lines):"
  printf '%s\n' "${regression_files[@]}" | head -20
  echo ""
  echo "Action requise : remplacer par un token ArenaColors.*, OU ajouter"
  echo "le fichier à scripts/colors_allowlist.txt si la KEEP est justifiée"
  echo "(brand-protected, overlay isolate, scrim, contrast gradient, etc.)."
fi

if [ "${1:-}" = "--strict" ] && [ "$regression_count" -gt 0 ]; then
  exit 1
fi
