#!/bin/sh
# board/<yourboard>/post-build.sh
# Existing functionality + build-time metadata insertion

set -eu

BOARD_DIR="$(dirname $0)"
 

# Copy uEnv.txt into final image output
cp "$BOARD_DIR/uEnv.txt" "$BINARIES_DIR/uEnv.txt"

# Install extlinux.conf
install -m 0644 -D "$BOARD_DIR/extlinux.conf" "$BINARIES_DIR/extlinux/extlinux.conf"

# -------------------------
# 2) Build-time metadata
# -------------------------

# --- Create simple image version file in /etc/imageVersion ---
IMAGEINFO="${TARGET_DIR}/etc/imageVersion"

# Generate the version at build time
IMAGE_VERSION="${IMAGE_VERSION:-$(git describe --tags --dirty --always 2>/dev/null || echo unknown)}"
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$IMAGEINFO")"

cat > "$IMAGEINFO" <<EOF
Image Version : ${IMAGE_VERSION}
Build Date    : ${BUILD_DATE}
EOF

echo "[post-build] Created /etc/imageVersion"
