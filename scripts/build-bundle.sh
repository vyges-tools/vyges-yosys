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

echo "== build =="
make config-gcc
make -j"$(nproc)" PREFIX="$PREFIX"
make install PREFIX="$PREFIX"

# --- assemble the relocatable bundle ---
NAME="vyges-yosys-${VERSION}-g${SHORT}"
B="$OUT_DIR/$NAME"
rm -rf "$B"; mkdir -p "$B"
cp -a "$PREFIX/." "$B/"
for L in COPYING LICENSE; do [ -f "$YOSYS_TREE/$L" ] && cp "$YOSYS_TREE/$L" "$B/LICENSE.yosys" && break; done

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
