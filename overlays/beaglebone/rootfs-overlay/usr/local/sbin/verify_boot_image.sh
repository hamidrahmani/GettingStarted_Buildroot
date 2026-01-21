#!/bin/sh
# verify_boot_image.sh – Verify /boot/sdcard.img via signed checksum.
# - Computes sha256 of /boot/sdcard.img
# - Compares with /boot/sdcard.img.sha256
# - If /boot/sdcard.img.sha256.sig and /etc/keys/public.pem exist, verify signature too.

set -eu

IMG="/boot/sdcard.img"
CHECK="${IMG}.sha256"
SIG="${CHECK}.sig"
PUBKEY="/etc/keys/public.pem"
LOG="/var/log/boot_verify.log"

# Optional guard: skip verification if image is excessively large (can be slow).
# Set MAX_MB=0 to disable the guard.
MAX_MB="${VERIFY_MAX_MB:-4096}"   # default 4 GiB
ENFORCE="${ENFORCE_VERIFY:-0}"    # if 1, we won't skip due to size

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log_file() { printf '%s %s\n' "$(ts)" "$1" >>"$LOG" 2>/dev/null || true; }
log() {
  echo "[verify] $*" >&2
  command -v logger >/dev/null 2>&1 && logger -t verify "$*"
  log_file "$*"
}

# Basic presence checks
if [ ! -f "$IMG" ]; then
  log "image_missing path=$IMG"
  exit 0
fi
if [ ! -f "$CHECK" ]; then
  log "checksum_missing path=$CHECK"
  exit 1
fi

# Optional size guard
if [ "${MAX_MB}" -gt 0 ]; then
  # Use stat(1) if available, else fallback to wc -c
  if command -v stat >/dev/null 2>&1; then
    size_bytes="$(stat -c%s "$IMG" 2>/dev/null || echo 0)"
  else
    size_bytes="$(wc -c <"$IMG" 2>/dev/null || echo 0)"
  fi
  # Convert to MiB (round up)
  size_mib=$(( (size_bytes + 1024*1024 - 1) / (1024*1024) ))
  if [ "$ENFORCE" -eq 0 ] && [ "$size_mib" -gt "$MAX_MB" ]; then
    log "skipping_due_to_size image_mib=${size_mib} limit_mib=${MAX_MB} (set ENFORCE_VERIFY=1 or VERIFY_MAX_MB=0 to force)"
    exit 0
  fi
fi

# Compute sha256 of the sdcard.img (this may take a while)
log "computing_sha256 target=$(basename "$IMG")"
computed="$(sha256sum "$IMG" 2>/dev/null | awk '{print $1}' || true)"
if [ -z "$computed" ]; then
  log "sha256_failed target=$IMG"
  exit 1
fi

# Read expected hash (first field) from checksum file
expected="$(awk '{print $1}' "$CHECK" | tr -d '\r\n')"
if [ -z "$expected" ]; then
  log "checksum_file_empty path=$CHECK"
  exit 1
fi

# If signature + public key present, verify the checksum file authenticity
if [ -f "$SIG" ] && [ -f "$PUBKEY" ]; then
  if openssl dgst -sha256 -verify "$PUBKEY" -signature "$SIG" "$CHECK" >/dev/null 2>&1; then
    if [ "$computed" = "$expected" ]; then
      log "verify_ok_signed target=$(basename "$IMG")"
      exit 0
    else
      log "verify_mismatch_signed target=$(basename "$IMG") computed=$computed expected=$expected"
      exit 2
    fi
  } else
    log "sig_verify_failed target=$(basename "$IMG")"
    exit 3
  fi
else
  # Unsigned fallback (less secure)
  if [ "$computed" = "$expected" ]; then
    log "verify_ok_unsigned target=$(basename "$IMG")"
    exit 0
  else
    log "verify_mismatch_unsigned target=$(basename "$IMG") computed=$computed expected=$expected"
    exit 4
  fi
fi
