#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT_DIR/install-kvm-cachyos.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_BIN="$TMP_DIR/bin"
mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/pacman" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK

cat > "$MOCK_BIN/sudo" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALL_LOG"
exit 0
MOCK

chmod +x "$MOCK_BIN/pacman" "$MOCK_BIN/sudo"

# Unsupported distributions must exit before sudo/pacman/systemctl/usermod.
cat > "$TMP_DIR/debian-os-release" <<'OS'
NAME="Debian GNU/Linux"
ID=debian
ID_LIKE=debian
OS

: > "$TMP_DIR/unsupported.log"
if PATH="$MOCK_BIN:$PATH" CALL_LOG="$TMP_DIR/unsupported.log" USER=test-user \
    OS_RELEASE_FILE="$TMP_DIR/debian-os-release" bash "$INSTALLER" --check; then
    echo "FAIL: Debian was unexpectedly accepted." >&2
    exit 1
fi

if [[ -s "$TMP_DIR/unsupported.log" ]]; then
    echo "FAIL: a privileged command ran on an unsupported distribution." >&2
    cat "$TMP_DIR/unsupported.log" >&2
    exit 1
fi

# CachyOS check-only mode must accept the host without invoking sudo.
cat > "$TMP_DIR/cachyos-os-release" <<'OS'
NAME="CachyOS"
ID=cachyos
ID_LIKE=arch
OS

: > "$TMP_DIR/check-only.log"
PATH="$MOCK_BIN:$PATH" CALL_LOG="$TMP_DIR/check-only.log" USER=test-user \
    OS_RELEASE_FILE="$TMP_DIR/cachyos-os-release" bash "$INSTALLER" --check

if [[ -s "$TMP_DIR/check-only.log" ]]; then
    echo "FAIL: --check invoked a privileged command." >&2
    cat "$TMP_DIR/check-only.log" >&2
    exit 1
fi

# Normal install path is exercised only through the sudo stub.
: > "$TMP_DIR/supported.log"
PATH="$MOCK_BIN:$PATH" CALL_LOG="$TMP_DIR/supported.log" USER=test-user \
    OS_RELEASE_FILE="$TMP_DIR/cachyos-os-release" bash "$INSTALLER"

grep -q '^pacman -S --needed ' "$TMP_DIR/supported.log"
grep -q '^systemctl enable --now libvirtd$' "$TMP_DIR/supported.log"
grep -q '^usermod -aG libvirt test-user$' "$TMP_DIR/supported.log"

# Arch-family metadata without pacman must fail before invoking sudo.
NO_PACMAN_BIN="$TMP_DIR/no-pacman-bin"
mkdir -p "$NO_PACMAN_BIN"
cat > "$NO_PACMAN_BIN/sudo" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALL_LOG"
exit 0
MOCK
ln -s "$(command -v awk)" "$NO_PACMAN_BIN/awk"
chmod +x "$NO_PACMAN_BIN/sudo"
: > "$TMP_DIR/missing-pacman.log"
if PATH="$NO_PACMAN_BIN" CALL_LOG="$TMP_DIR/missing-pacman.log" USER=test-user \
    OS_RELEASE_FILE="$TMP_DIR/cachyos-os-release" /bin/bash "$INSTALLER" --check; then
    echo "FAIL: installer accepted an Arch-family host without pacman." >&2
    exit 1
fi

if [[ -s "$TMP_DIR/missing-pacman.log" ]]; then
    echo "FAIL: a privileged command ran without pacman." >&2
    cat "$TMP_DIR/missing-pacman.log" >&2
    exit 1
fi

echo "PASS: unsupported OS is rejected without privileged commands."
echo "PASS: CachyOS --check succeeds without privileged commands."
echo "PASS: CachyOS install path invokes expected commands through the sudo stub."
echo "PASS: Arch-family OS without pacman is rejected safely."
