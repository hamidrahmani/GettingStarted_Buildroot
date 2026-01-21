#!/bin/sh
# verify_boot_image.sh
# Simple boot-time image verifier (practical, minimal):
# - Chooses a candidate image in /boot (fitImage, uImage, zImage)
# - Computes its SHA256 and compares it against a checksum file (image.sha256)
# - Verifies the checksum file's signature using an RSA public key and openssl
#
# Requirements on device: openssl (for verification) and coreutils (sha256sum)
#
TARGET=""
for candidate in /boot/fitImage /boot/uImage /boot/zImage; do
  [ -f "$candidate" ] && TARGET="$candidate" && break
done

LOG=/var/log/boot_verify.log
ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { printf '%s %s\n' "$(ts)" "$1" >>"$LOG" 2>/dev/null || true; }

if [ -z "$TARGET" ]; then
  log "no_boot_image_found"
  exit 0
fi

BASE="$TARGET"
CHECKFILE="${BASE}.sha256"
SIGFILE="${CHECKFILE}.sig"
PUBKEY="/etc/keys/public.pem"

if [ ! -f "$CHECKFILE" ]; then
  log "checksum_missing target=$TARGET"
  exit 1
fi

# Compute sha256 of target
computed=$(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}' || true)
if [ -z "$computed" ]; then
  log "sha256_failed target=$TARGET"
  exit 1
fi

# If signature + public key exist, verify checksum file signature first
if [ -f "$SIGFILE" ] && [ -f "$PUBKEY" ]; then
  if openssl dgst -sha256 -verify "$PUBKEY" -signature "$SIGFILE" "$CHECKFILE" >/dev/null 2>&1; then
    # signature OK, compare checksums
    expected=$(awk '{print $1}' "$CHECKFILE" | tr -d '\r\n')
    if [ "$computed" = "$expected" ]; then
      log "verify_ok target=$(basename "$TARGET")"
      exit 0
    else
      log "verify_mismatch target=$(basename "$TARGET") computed=$computed expected=$expected"
      exit 2
    fi
  else
    log "sig_verify_failed target=$(basename "$TARGET")"
    exit 3
  fi
else
  # No signature available — fallback to unsigned checksum compare (less secure)
  expected=$(awk '{print $1}' "$CHECKFILE" | tr -d '\r\n')
  if [ "$computed" = "$expected" ]; then
    log "verify_ok_unsigned target=$(basename "$TARGET")"
    exit 0
  else
    log "verify_mismatch_unsigned target=$(basename "$TARGET") computed=$computed expected=$expected"
    exit 4
  fi
fi

exit 0
