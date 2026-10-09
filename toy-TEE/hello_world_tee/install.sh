set -euo pipefail
cd "$(dirname "$0")"

IMAGE=optee
CONTAINER=optee
JOBS=${JOBS:-2}
WORK=/home/dev/optee
ARTIFACTS="bl1.bin Image uImage rootfs.cpio.gz rootfs.cpio.uboot"

log() { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[install]\033[0m %s\n' "$*" >&2; exit 1; }

TTY=()
if [ -t 0 ] && [ -t 1 ]; then TTY=(-it); fi
in_container() { podman exec "${TTY[@]}" "$CONTAINER" bash -c "$1"; }

artifacts_ok() {
  podman exec "$CONTAINER" bash -c "cd $WORK/out/bin 2>/dev/null && for f in $ARTIFACTS; do test -e \$f || exit 1; done"
}

command -v podman >/dev/null || die "Podman not found"

# Image
log "Building image: $IMAGE"
podman build --build-arg UID="$(id -u)" -t "$IMAGE" .

mkdir -p optee
NET=()
if [ "${HOST_NETWORK:-0}" = 1 ]; then NET=(--network=host); fi
if podman container exists "$CONTAINER"; then
  log "Remake container $CONTAINER "
  podman rm -f "$CONTAINER" >/dev/null
fi
podman run -dit --name "$CONTAINER" --userns=keep-id "${NET[@]}" \
  -v "$PWD/optee:$WORK:Z" "$IMAGE" >/dev/null

if [ ! -f optee/build/Makefile ] || [ "${FORCE_SYNC:-0}" = 1 ]; then
  if [ ! -d optee/.repo ]; then
    log "repo init"
    in_container "cd $WORK && repo init --depth=1 -u https://github.com/OP-TEE/manifest.git -m qemu_v8.xml"
  fi
  log "repo sync (JOBS=$JOBS)"
  in_container "cd $WORK && repo sync -c --no-tags -j$JOBS"
else
  log "Sources found, sync skipped (FORCE_SYNC=1 — sync again)"
fi
log "Toolchains"
in_container "make -C $WORK/build toolchains -j$JOBS"


for attempt in 1 2 3; do
  if artifacts_ok && [ "$attempt" -gt 1 ]; then break; fi
  log "Building, attempt $attempt/3. logs: ./optee/build.log"
  in_container "cd $WORK/build && make -j$JOBS -k > $WORK/build.log 2>&1; tail -20 $WORK/build.log" || true
  if artifacts_ok; then break; fi
done

if artifacts_ok; then
  log "Done! To run: ./run.sh"
else
  in_container "ls -la $WORK/out/bin" || true
  die "Error: ($ARTIFACTS). Try: grep -n 'Error' optee/build.log"
fi