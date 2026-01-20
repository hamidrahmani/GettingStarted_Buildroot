#!/usr/bin/env bash
set -euo pipefail

# Usage: fix_suspicious.sh [paths...]
# Conservatively fixes common issues:
# * Replace HTML entities (&gt; &lt; &amp; &quot; &apos;)
# * Normalize Unicode dashes to ASCII '-'
# * Replace NBSP/NNBSP with ASCII space
# * Remove zero-width chars
# * Convert CRLF -> LF
# Creates .bak backups alongside changed files.

if [ "$#" -eq 0 ]; then
  set -- "."
fi

find_targets() {
  find "$@" -type f \
    -not -path "*/.git/*" \
    -not -path "*/build/*" \
    -not -path "*/out/*" \
    -not -path "*/dl/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/venv/*"
}

fix_file() {
  local f="$1"
  local tmp
  tmp="$(mktemp)"

  # Work on a copy, then compare
  cp -a "$f" "$tmp"

  # 1) Convert CRLF → LF
  if command -v dos2unix >/dev/null 2>&1; then
    dos2unix -q "$tmp" || true
  else
    # Pure POSIX: strip \r
    sed -i 's/\r$//' "$tmp"
  fi

  # 2) Replace HTML entities
  sed -i \
    -e 's/&gt;/>/g' \
    -e 's/&lt;/</g' \
    -e 's/&amp;/\&/g' \
    -e 's/&quot;/"/g' \
    -e "s/&apos;/'/g" \
    "$tmp"

  # 3) Remove zero-width (U+200B, U+200C, U+200D)
  perl -CS -pe 's/\x{200B}|\x{200C}|\x{200D}//g' -i "$tmp"

  # 4) Replace NBSP (U+00A0) / NNBSP (U+202F) with space
  perl -CS -pe 's/\x{00A0}|\x{202F}/ /g' -i "$tmp"

  # 5) Normalize dashes: U+2010..U+2015 → ASCII hyphen '-'
  perl -CS -pe 's/[\x{2010}-\x{2015}]/-/g' -i "$tmp"

  # 6) Strip any remaining non-printable except tab/newline
  #    (very conservative)
  LC_ALL=C sed -i 's/[^[:print:]\t]//g' "$tmp"

  # If changed, write .bak and replace
  if ! cmp -s "$f" "$tmp"; then
    cp -a "$f" "$f.bak"
    mv "$tmp" "$f"
    echo "[fixed] $f  (backup: $f.bak)"
  else
    rm -f "$tmp"
  fi
}

# Iterate targets
changed=0
while IFS= read -r -d '' f; do
  # Only text-like files (skip big binaries quickly)
  if file --mime "$f" 2>/dev/null | grep -qi 'charset=binary'; then
    continue
  fi
  fix_file "$f" || true
done < <(find_targets "$@" -print0)

echo "Done. Re-run scripts/scan_suspicious.sh to confirm."
