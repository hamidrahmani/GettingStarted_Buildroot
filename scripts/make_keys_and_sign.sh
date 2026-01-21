#!/bin/sh
# make_keys_and_sign.sh
# Convenience helper: generate RSA keypair (private.pem/public.pem) and
# sign a boot image checksum, then copy artifacts into the overlay.
#
# Usage:
#   ./scripts/make_keys_and_sign.sh --image path/to/fitImage --overlay overlays/beaglebone/rootfs-overlay/boot
#
set -eu

usage(){
  cat <<EOF
Usage: $0 --image IMAGE --overlay OVERLAY_BOOT [--out-keys DIR]

Generates private.pem and public.pem (if missing) in OUT_KEYS (default: scripts/keys),
creates checksum and signature for IMAGE and copies artifacts into the OVERLAY_BOOT.

Example:
  $0 --image output/images/fitImage --overlay overlays/beaglebone/rootfs-overlay/boot
EOF
  exit 1
}

IMAGE=""
OVERLAY_BOOT=""
OUT_KEYS="scripts/keys"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2;;
    --overlay) OVERLAY_BOOT="$2"; shift 2;;
    --out-keys) OUT_KEYS="$2"; shift 2;;
    --help|-h) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

[ -n "$IMAGE" ] || usage
[ -n "$OVERLAY_BOOT" ] || usage

mkdir -p "$OUT_KEYS"

PRIV="$OUT_KEYS/private.pem"
PUB="$OUT_KEYS/public.pem"

if [ ! -f "$PRIV" ] || [ ! -f "$PUB" ]; then
  echo "Generating RSA keypair -> $PRIV / $PUB"
  openssl genpkey -algorithm RSA -out "$PRIV" -pkeyopt rsa_keygen_bits:2048
  openssl rsa -in "$PRIV" -pubout -out "$PUB"
else
  echo "Using existing keys in $OUT_KEYS"
fi

# Call the existing artifact generator to produce checksum + signature and copy into overlay
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
"$SCRIPT_DIR/gen_and_deploy_artifacts.sh" --image "$IMAGE" --private-key "$PRIV" --public-key "$PUB" --overlay "$OVERLAY_BOOT"

echo "Done. Keys at: $PRIV, $PUB. Artifacts copied into $OVERLAY_BOOT."

exit 0
