#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/check_coverage.sh — Arena coverage ratchet
# ─────────────────────────────────────────────────────────────────────────────
# Calcule la couverture de lignes globale depuis `coverage/lcov.info` et échoue
# si elle passe SOUS un plancher figé (`MIN_COVERAGE`). Ratchet anti-régression :
# on n'impose pas un objectif ambitieux, on empêche la couverture de baisser.
#
# Quand on monte la couverture durablement, RELEVER `MIN_COVERAGE` (jamais le
# baisser pour faire passer la CI — c'est tout l'intérêt du cliquet).
#
# Même posture progressive que `check_colors.sh --strict` (cf. audit 2026-06-14,
# chantier tests). Plancher initial = 30 % (mesuré 30,05 % au 2026-06-14).
#
# Usage:  bash scripts/check_coverage.sh           # plancher par défaut (30)
#         MIN_COVERAGE=35 bash scripts/check_coverage.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

cd "$(dirname "$0")/.."

MIN_COVERAGE="${MIN_COVERAGE:-30}"
lcov_file="coverage/lcov.info"

if [[ ! -f "$lcov_file" ]]; then
  echo "❌ $lcov_file introuvable — lance d'abord 'flutter test --coverage'." >&2
  exit 1
fi

read -r total covered pct < <(
  awk '/^DA:/ {
        split(substr($0, 4), a, ",")
        total++
        if (a[2] + 0 > 0) covered++
      }
      END {
        if (total == 0) { print 0, 0, 0; exit }
        printf "%d %d %.2f\n", total, covered, (covered / total) * 100
      }' "$lcov_file"
)

echo "Couverture de lignes : ${pct}%  (${covered}/${total} lignes)"
echo "Plancher requis      : ${MIN_COVERAGE}%"

# Comparaison flottante via awk (bash ne gère pas les décimaux).
if awk -v p="$pct" -v m="$MIN_COVERAGE" 'BEGIN { exit (p + 0 < m + 0) ? 0 : 1 }'; then
  echo "❌ Régression de couverture : ${pct}% < ${MIN_COVERAGE}%." >&2
  echo "   Ajoute des tests, ou justifie puis ajuste MIN_COVERAGE." >&2
  exit 1
fi

echo "✅ Couverture OK (≥ ${MIN_COVERAGE}%)."
