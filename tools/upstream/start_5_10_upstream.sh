#!/usr/bin/env bash
set -euo pipefail

# Bootstrap helper to start a 4.19.325 -> 5.10 migration in a reproducible way.

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
OUT_DIR=${OUT_DIR:-"$ROOT_DIR/out/upstream-5.10"}
REF_510_DIR=${REF_510_DIR:-"$OUT_DIR/linux-5.10"}
BASE_DEFCONFIG=${BASE_DEFCONFIG:-"universal9830_defconfig"}
ARCH=${ARCH:-arm64}
MAKE_JOBS=${MAKE_JOBS:-$(nproc)}

log() { printf '[upstream-5.10] %s\n' "$*"; }
fail() { printf '[upstream-5.10][error] %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need_cmd git
need_cmd make

mkdir -p "$OUT_DIR"

if [[ ! -d "$REF_510_DIR/.git" ]]; then
  log "cloning Linux 5.10.y reference into $REF_510_DIR"
  git clone --depth=1 --branch linux-5.10.y https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git "$REF_510_DIR"
else
  log "updating existing 5.10 reference in $REF_510_DIR"
  git -C "$REF_510_DIR" fetch --depth=1 origin linux-5.10.y
  git -C "$REF_510_DIR" checkout -q linux-5.10.y
  git -C "$REF_510_DIR" reset --hard -q FETCH_HEAD
fi

SRC_CFG="$ROOT_DIR/arch/$ARCH/configs/$BASE_DEFCONFIG"
[[ -f "$SRC_CFG" ]] || fail "defconfig not found: $SRC_CFG"

WORK_CFG="$OUT_DIR/$BASE_DEFCONFIG.from-4.19.config"
cp "$SRC_CFG" "$WORK_CFG"

log "normalizing current (4.19) defconfig"
make -C "$ROOT_DIR" ARCH="$ARCH" O="$OUT_DIR/build-4.19" "$BASE_DEFCONFIG" >/dev/null
cp "$OUT_DIR/build-4.19/.config" "$OUT_DIR/$BASE_DEFCONFIG.4.19.normalized.config"

log "running olddefconfig on 5.10 reference using 4.19 config"
cp "$OUT_DIR/$BASE_DEFCONFIG.4.19.normalized.config" "$REF_510_DIR/.config"
make -C "$REF_510_DIR" ARCH="$ARCH" olddefconfig >/dev/null
cp "$REF_510_DIR/.config" "$OUT_DIR/$BASE_DEFCONFIG.5.10.olddefconfig.config"

if [[ -x "$ROOT_DIR/scripts/diffconfig" ]]; then
  log "computing config delta with scripts/diffconfig"
  "$ROOT_DIR/scripts/diffconfig" \
    "$OUT_DIR/$BASE_DEFCONFIG.4.19.normalized.config" \
    "$OUT_DIR/$BASE_DEFCONFIG.5.10.olddefconfig.config" \
    > "$OUT_DIR/$BASE_DEFCONFIG.diffconfig.txt" || true
else
  log "scripts/diffconfig is not executable; skipping diffconfig report"
fi

log "collecting likely removed symbols"
awk -F= '/^CONFIG_/ {print $1}' "$OUT_DIR/$BASE_DEFCONFIG.4.19.normalized.config" | sort -u > "$OUT_DIR/symbols.4.19.txt"
awk -F= '/^CONFIG_/ {print $1}' "$OUT_DIR/$BASE_DEFCONFIG.5.10.olddefconfig.config" | sort -u > "$OUT_DIR/symbols.5.10.txt"
comm -23 "$OUT_DIR/symbols.4.19.txt" "$OUT_DIR/symbols.5.10.txt" > "$OUT_DIR/symbols.removed-or-disabled.txt" || true

log "writing summary"
cat > "$OUT_DIR/README.txt" <<SUMMARY
Generated artifacts:
- $OUT_DIR/$BASE_DEFCONFIG.4.19.normalized.config
- $OUT_DIR/$BASE_DEFCONFIG.5.10.olddefconfig.config
- $OUT_DIR/$BASE_DEFCONFIG.diffconfig.txt
- $OUT_DIR/symbols.removed-or-disabled.txt

Next steps:
1) Review *.diffconfig.txt and symbols.removed-or-disabled.txt
2) Build 5.10 with target BSP patches applied incrementally
3) Port broken drivers/subsystems one block at a time
SUMMARY

log "done"
