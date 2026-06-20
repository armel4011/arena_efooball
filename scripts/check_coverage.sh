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
# chantier tests). Plancher 37 % (couverture mesurée à 38,35 % le 2026-06-20,
# après les chantiers tests UI #6 + offline/pgTAP/EF de la dette P1 ; buffer
# ~1,3 pt pour absorber la variance CI). À relever quand ça remonte.
#
# Usage:  bash scripts/check_coverage.sh           # plancher par défaut (37)
#         MIN_COVERAGE=40 bash scripts/check_coverage.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

cd "$(dirname "$0")/.."

MIN_COVERAGE="${MIN_COVERAGE:-37}"
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
