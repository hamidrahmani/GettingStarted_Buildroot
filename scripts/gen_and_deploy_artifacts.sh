#!/bin/sh
# gen_and_deploy_artifacts.sh
#
# Simple host-side helper to generate checksum and optional signature for a
# boot image, and deploy the artifacts either into the overlay (for inclusion
# in the built image) or directly to a running board via scp.
#
# Usage:
#   ./scripts/gen_and_deploy_artifacts.sh --image /path/to/fitImage \
#       [--private-key /path/to/private.pem] \
#       [--overlay overlays/beaglebone/rootfs-overlay/boot] \
#       [--deploy user@host:/boot]
#
# If --private-key is provided, the script will create a detached signature
# of the checksum file using OpenSSL. The public key should be copied to
# /etc/keys/public.pem on the board (the script can place it into the
# overlay if you provide --overlay).

set -eu

usage() {
  sed -n '1,200p' "$0" | sed -n '1,80p'
  echo
  echo "Examples:" 
  echo "  $0 --image out/images/fitImage --private-key ~/.ssh/private.pem --overlay overlays/beaglebone/rootfs-overlay/boot"
  echo "  $0 --image build/output/boot/uImage --deploy root@192.0.2.10:/boot"
  exit 1
}

IMAGE=""
PRIVKEY=""
OVERLAY_BOOT=""
DEPLOY_TARGET=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2;;
    --private-key) PRIVKEY="$2"; shift 2;;
    --overlay) OVERLAY_BOOT="$2"; shift 2;;
    --deploy) DEPLOY_TARGET="$2"; shift 2;;
    --help|-h) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [ -z "$IMAGE" ]; then
  echo "Error: --image is required" >&2
  usage
fi

if [ ! -f "$IMAGE" ]; then
  echo "Error: image not found: $IMAGE" >&2
  exit 2
fi

command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum not found" >&2; exit 3; }

BASEDIR=$(dirname "$IMAGE")
BASE=$(basename "$IMAGE")
CHECKFILE="$BASEDIR/$BASE.sha256"
SIGFILE="$CHECKFILE.sig"

echo "Generating checksum for $IMAGE -> $CHECKFILE"
sha256sum "$IMAGE" | awk '{print $1 "  " $2}' > "$CHECKFILE"

if [ -n "$PRIVKEY" ]; then
  if [ ! -f "$PRIVKEY" ]; then
    echo "Private key not found: $PRIVKEY" >&2
    exit 4
  fi
  command -v openssl >/dev/null 2>&1 || { echo "openssl not found" >&2; exit 5; }
  echo "Signing checksum with private key -> $SIGFILE"
  openssl dgst -sha256 -sign "$PRIVKEY" -out "$SIGFILE" "$CHECKFILE"
fi

if [ -n "$OVERLAY_BOOT" ]; then
  # create overlay boot dir if missing
  mkdir -p "$OVERLAY_BOOT" || { echo "cannot create overlay target: $OVERLAY_BOOT" >&2; exit 6; }
  echo "Copying artifacts into overlay: $OVERLAY_BOOT"
  cp -a "$IMAGE" "$OVERLAY_BOOT/$BASE" 
  cp -a "$CHECKFILE" "$OVERLAY_BOOT/$BASE.sha256"
  if [ -f "$SIGFILE" ]; then
    cp -a "$SIGFILE" "$OVERLAY_BOOT/$BASE.sha256.sig"
  fi
  if [ -n "$PRIVKEY" ]; then
    # also copy public key location hint: expect public.pem next to privkey with .pub or user provides separately
    PUBKEY="${PRIVKEY%.*}.pub.pem"
    if [ -f "$PUBKEY" ]; then
      mkdir -p "$(dirname "$OVERLAY_BOOT")/etc/keys"
      cp -a "$PUBKEY" "$(dirname "$OVERLAY_BOOT")/etc/keys/public.pem"
      echo "Copied public key to overlay: $(dirname "$OVERLAY_BOOT")/etc/keys/public.pem"
    else
      echo "Note: public key not found at $PUBKEY. Place public.pem in overlay at etc/keys/public.pem if you want automatic verification on device." 
    fi
  fi
fi

if [ -n "$DEPLOY_TARGET" ]; then
  echo "Deploying artifacts to $DEPLOY_TARGET"
  # DEPLOY_TARGET form: user@host:/path
  scp "$IMAGE" "$DEPLOY_TARGET/$(basename "$IMAGE")"
  scp "$CHECKFILE" "$DEPLOY_TARGET/$(basename "$CHECKFILE")"
  if [ -f "$SIGFILE" ]; then
    scp "$SIGFILE" "$DEPLOY_TARGET/$(basename "$SIGFILE")"
  fi
  echo "Deployed. You may need to run 'sync' or restart services on the device." 
fi

echo "Done. Artifacts generated:" 
ls -l "$CHECKFILE" ${SIGFILE:+"$SIGFILE"} || true

exit 0
