#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/check_spacing.sh — Arena design-system spacing guard
# ─────────────────────────────────────────────────────────────────────────────
# Reports every hardcoded numeric literal passed to EdgeInsets.* or SizedBox()
# in lib/. The Arena design system exposes `ArenaSpacing.{xs,sm,md,lg,xl,xxl,
# xxxl}` and these should be used instead. Picked up by dev workflow until
# `custom_lint` becomes compatible with analyzer 7.x (see pubspec.yaml).
#
# Usage:  bash scripts/check_spacing.sh           # report all violations
#         bash scripts/check_spacing.sh --strict  # exit 1 if any found
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

cd "$(dirname "$0")/.."

# Forbidden literal patterns:
#   EdgeInsets.all(12)        / .all(ArenaSpacing.md) ✅
#   EdgeInsets.only(top: 6)   / .only(top: ArenaSpacing.xs)
#   EdgeInsets.symmetric(horizontal: 14, vertical: 10)
#   SizedBox(height: 8)
#   SizedBox(width: 12)
patterns=(
  'EdgeInsets\.all\([0-9]+\.?[0-9]*\)'
  'EdgeInsets\.only\([^)]*[a-z]: ?[0-9]+\.?[0-9]*'
  'EdgeInsets\.symmetric\([^)]*[a-z]: ?[0-9]+\.?[0-9]*'
  'EdgeInsets\.fromLTRB\([0-9 ,.]+\)'
  'SizedBox\([^)]*(height|width): ?[0-9]+\.?[0-9]*'
)

total=0
for p in "${patterns[@]}"; do
  count=$(grep -REn --include='*.dart' -- "$p" lib | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    echo "── $p ($count occurrences)"
    grep -REn --include='*.dart' -- "$p" lib | head -5
    echo "  …"
    total=$((total + count))
  fi
done

echo ""
echo "Total spacing violations: $total"
echo "Target tokens: ArenaSpacing.xs (4) / sm (8) / md (12) / lg (16) / xl (20) / xxl (24) / xxxl (32)"

if [ "${1:-}" = "--strict" ] && [ "$total" -gt 0 ]; then
  exit 1
fi
