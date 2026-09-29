#!/usr/bin/env bash

set -euo pipefail

CONTAINER=optee
WORK=/home/dev/optee

die() { printf '\033[1;31m[run]\033[0m %s\n' "$*" >&2; exit 1; }

podman container exists "$CONTAINER" || die "No container. Try: ./install.sh"
podman start "$CONTAINER" >/dev/null
podman exec "$CONTAINER" test -e "$WORK/out/bin/uImage" \
  || die "Building failed. Try ./install.sh again"

cat <<'HELP'
────────────────────────────────────────────────────────────
  1. Enter in (qemu) c
  2. Ctrl-b w — choose OPTEE_...
     (left Normal World, right Secure World)
  3. buildroot login: root
     optee_example_hello_world
  4. Exit: q in (qemu), then exit in tmux
     Stop container: podman stop optee
────────────────────────────────────────────────────────────
HELP
sleep 3

exec podman exec -it "$CONTAINER" tmux new-session -A -s optee \
  "cd $WORK/build && make run-only QEMU_BIN=/usr/bin/qemu-system-aarch64; echo; echo 'QEMU stoped. exit — close tmux'; exec bash"