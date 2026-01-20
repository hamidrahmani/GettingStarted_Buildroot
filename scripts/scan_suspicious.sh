#!/usr/bin/env bash
set -euo pipefail

# Usage: scan_suspicious.sh [paths...]
# Scans for non-ASCII, zero-width chars, NBSP, fancy dashes, CRLF, HTML entities.
# Exits 0 if clean, 1 if issues found.

# Default paths: current dir
if [ "$#" -eq 0 ]; then
  set -- "."
fi

# Build find list filtering common build dirs
find_targets() {
  find "$@" -type f \
    -not -path "*/.git/*" \
    -not -path "*/build/*" \
    -not -path "*/out/*" \
    -not -path "*/dl/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/venv/*"
}

# Grep patterns (hex escapes are safer in some greps)
# Zero-width: U+200B, U+200C, U+200D
re_zws=$'\xE2\x80\x8B|\xE2\x80\x8C|\xE2\x80\x8D'
# NBSP: U+00A0; NNBSP: U+202F
re_nbsp=$'\xC2\xA0|\xE2\x80\xAF'
# Dashes: U+2010–U+2015
re_dashes=$'\xE2\x80\x90|\xE2\x80\x91|\xE2\x80\x92|\xE2\x80\x93|\xE2\x80\x94|\xE2\x80\x95'
# Smart quotes: U+2018–U+201F
re_quotes=$'\xE2\x80\x98|\xE2\x80\x99|\xE2\x80\x9A|\xE2\x80\x9B|\xE2\x80\x9C|\xE2\x80\x9D|\xE2\x80\x9E|\xE2\x80\x9F'

issues=0

echo "=== Scanning for suspicious characters / encodings ==="

# 1) Non-ASCII (except tabs, newlines, carriage return) – overview
if LC_ALL=C grep -rI --line-number --color=never -P "[^\x09\x0a\x0d\x20-\x7E]" $(find_targets "$@") >/tmp/_scan_nonascii.txt 2>/dev/null; then
  echo "[!] Non-ASCII bytes found:"
  cat /tmp/_scan_nonascii.txt
  issues=1
fi

# 2) Zero-width characters
if LC_ALL=C grep -rI --line-number --color=never -P "$re_zws" $(find_targets "$@") >/tmp/_scan_zws.txt 2>/dev/null; then
  echo "[!] Zero-width characters found (U+200B/C/D):"
  cat /tmp/_scan_zws.txt
  issues=1
fi

# 3) NBSP / narrow NBSP
if LC_ALL=C grep -rI --line-number --color=never -P "$re_nbsp" $(find_targets "$@") >/tmp/_scan_nbsp.txt 2>/dev/null; then
  echo "[!] NBSP (U+00A0) / NNBSP (U+202F) found:"
  cat /tmp/_scan_nbsp.txt
  issues=1
fi

# 4) Unicode dashes (incl. non-breaking hyphen U+2011)
if LC_ALL=C grep -rI --line-number --color=never -P "$re_dashes" $(find_targets "$@") >/tmp/_scan_dashes.txt 2>/dev/null; then
  echo "[!] Unicode dashes (U+2010..U+2015) found:"
  cat /tmp/_scan_dashes.txt
  issues=1
fi

# 5) Smart quotes
if LC_ALL=C grep -rI --line-number --color=never -P "$re_quotes" $(find_targets "$@") >/tmp/_scan_quotes.txt 2>/dev/null; then
  echo "[!] Smart quotes found:"
  cat /tmp/_scan_quotes.txt
  issues=1
fi

# 6) CRLF line endings
if grep -rI --line-number -U $'\r' $(find_targets "$@") >/tmp/_scan_crlf.txt 2>/dev/null; then
  echo "[!] CRLF (Windows) line endings found (showing \\r matches):"
  cat /tmp/_scan_crlf.txt
  issues=1
fi

# 7) HTML entities likely from copy/paste (&gt;, &lt;, &amp;, &quot;, &apos;)
if grep -rI --line-number -E "&(gt|lt|amp|quot|apos);" $(find_targets "$@") >/tmp/_scan_entities.txt 2>/dev/null; then
  echo "[!] HTML entities detected (replace with real characters):"
  cat /tmp/_scan_entities.txt
  issues=1
fi

if [ $issues -eq 0 ]; then
  echo "✓ No suspicious characters found."
else
  echo "✗ Suspicious content detected. Consider running tools/fix_suspicious.sh"
fi

exit $issues
