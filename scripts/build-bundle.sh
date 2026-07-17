#!/usr/bin/env bash
# build-bundle.sh — build Yosys at the pinned commit and assemble a RELOCATABLE
# tar.gz into $OUT_DIR. THE TAR.GZ IS THE PRODUCT.
# Env: YOSYS_COMMIT (req), VERSION (default dev), OUT_DIR (default /out),
#      YOSYS_TREE (default /tmp/yosys — a recursive clone of Yosys).
set -euo pipefail

YOSYS_COMMIT="${YOSYS_COMMIT:?set YOSYS_COMMIT}"
VERSION="${VERSION:-dev}"
OUT_DIR="${OUT_DIR:-/out}"
YOSYS_TREE="${YOSYS_TREE:-/tmp/yosys}"
PREFIX="/tmp/yosys-install"
mkdir -p "$OUT_DIR"

cd "$YOSYS_TREE"
git checkout -q "$YOSYS_COMMIT"
git submodule update --init --recursive
SHORT="$(git rev-parse --short=12 HEAD)"

echo "== build yosys (+ yosys-abc) =="
make config-gcc
make -j"$(nproc)" PREFIX="$PREFIX"
make install PREFIX="$PREFIX"        # installs bin/yosys AND bin/yosys-abc

# --- OpenSTA (static timing) — built + installed into the SAME prefix ---
OPENSTA_REF="${OPENSTA_REF:-v2.7.0}"
OPENSTA_TREE="${OPENSTA_TREE:-/tmp/opensta}"
echo "== build OpenSTA ($OPENSTA_REF) =="
[ -d "$OPENSTA_TREE/.git" ] || git clone https://github.com/parallaxsw/OpenSTA "$OPENSTA_TREE"
git -C "$OPENSTA_TREE" checkout -q "$OPENSTA_REF"
cmake -S "$OPENSTA_TREE" -B "$OPENSTA_TREE/build" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release
cmake --build "$OPENSTA_TREE/build" -j"$(nproc)"
cmake --install "$OPENSTA_TREE/build" 2>/dev/null || cp "$OPENSTA_TREE/build/app/sta" "$PREFIX/bin/sta"

# --- assemble the relocatable bundle (yosys + yosys-abc + sta) ---
NAME="vyges-yosys-${VERSION}-g${SHORT}"
B="$OUT_DIR/$NAME"
rm -rf "$B"; mkdir -p "$B"
cp -a "$PREFIX/." "$B/"
for L in COPYING LICENSE; do [ -f "$YOSYS_TREE/$L" ] && cp "$YOSYS_TREE/$L" "$B/LICENSE.yosys" && break; done
[ -f "$OPENSTA_TREE/LICENSE" ] && cp "$OPENSTA_TREE/LICENSE" "$B/LICENSE.opensta" || true

# env.sh makes the bundle relocatable (yosys finds its share/ via the binary path)
cat > "$B/env.sh" <<'EOS'
D="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export PATH="$D/bin:$PATH"
EOS

echo "== tarball (THE PRODUCT) =="
ARCH="$(uname -m)"                      # x86_64 or aarch64 — not hardcoded
TARBALL="${NAME}-linux-${ARCH}.tar.gz"
tar -C "$OUT_DIR" -czf "$OUT_DIR/${TARBALL}" "$NAME"
du -sh "$B" "$OUT_DIR/${TARBALL}"
echo "BUILD_BUNDLE_OK short=$SHORT arch=$ARCH tarball=${TARBALL}"
