// =============================================================================
// ARENA — moderate-chat-message/logic.ts
// =============================================================================
// Logique PURE de détection/caviardage des mots interdits, extraite du handler
// (index.ts) pour être testable sans `Deno.serve` ni accès réseau/DB.
// =============================================================================

export interface BannedWord {
  word: string;
  language: string;
  severity: number;
  category: string | null;
}

export interface Match {
  word: string;
  severity: number;
  start: number; // index dans le contenu normalisé
  end: number;
}

export interface ScanResult {
  matches: Match[];
  maxSeverity: number;
  offendingWords: string[];
  redacted: string;
  reason: string;
}

/// Normalise pour la recherche : lowercase + retrait des accents (NFKD).
export function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "");
}

/// Cherche `needle` (déjà normalisé) dans `haystack` en respectant les
/// frontières de mot. Retourne l'index de match ou -1.
export function findWord(haystack: string, needle: string): number {
  const re = new RegExp(
    `(^|[^\\p{L}\\p{N}])${
      needle.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")
    }($|[^\\p{L}\\p{N}])`,
    "u",
  );
  const m = re.exec(haystack);
  return m ? m.index + (m[1]?.length ?? 0) : -1;
}

/// Caviarde toutes les occurrences (frontières de mot, case-insensitive) des
/// `words` dans la chaîne d'origine `content`, par des `*` de même longueur.
export function redact(content: string, words: string[]): string {
  let out = content;
  for (const w of words) {
    const re = new RegExp(
      `(?<=^|[^\\p{L}\\p{N}])${
        w.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")
      }(?=$|[^\\p{L}\\p{N}])`,
      "giu",
    );
    out = out.replace(re, "*".repeat(w.length));
  }
  return out;
}

/// Cœur de la modération : scanne `content` contre la liste `banned` et
/// renvoie le résultat (matches, sévérité max, mots, contenu caviardé,
/// raison) ou `null` si le message est propre.
export function scanMessage(
  content: string,
  banned: BannedWord[],
): ScanResult | null {
  const normalized = normalize(content);
  const matches: Match[] = [];
  for (const b of banned) {
    const needle = normalize(b.word);
    if (!needle) continue;
    const idx = findWord(normalized, needle);
    if (idx >= 0) {
      matches.push({
        word: b.word,
        severity: b.severity,
        start: idx,
        end: idx + needle.length,
      });
    }
  }
  if (matches.length === 0) return null;

  const maxSeverity = Math.max(...matches.map((m) => m.severity));
  const offendingWords = matches.map((m) => m.word);
  const redacted = redact(content, offendingWords);
  const reason = `banned_word(${maxSeverity}):${offendingWords.join(",")}`;
  return { matches, maxSeverity, offendingWords, redacted, reason };
}
