#!/usr/bin/env bash
# =========================================================
# KVM + Libvirt + Virt-Manager Installer for CachyOS (Arch)
# Author: Alb Kestrel
# =========================================================

set -o pipefail

# Keep this overridable so OS detection can be tested with a fixture.
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

read_os_release_field() {
    local field="$1"
    awk -F= -v key="$field" '
        $1 == key {
            sub(/^[^=]*=/, "")
            gsub(/"/, "")
            print
            exit
        }
    ' "$OS_RELEASE_FILE"
}

detect_host_os() {
    if [[ ! -r "$OS_RELEASE_FILE" ]]; then
        echo "❌ Cannot read $OS_RELEASE_FILE; refusing to continue." >&2
        return 1
    fi

    OS_ID="$(read_os_release_field ID)"
    OS_ID_LIKE="$(read_os_release_field ID_LIKE)"
    OS_NAME="$(read_os_release_field NAME)"

    if [[ -z "$OS_ID" ]]; then
        echo "❌ The operating system ID is missing from $OS_RELEASE_FILE; refusing to continue." >&2
        return 1
    fi

    printf 'ℹ️ Detected host: %s (ID=%s, ID_LIKE=%s)\n' "${OS_NAME:-unknown}" "$OS_ID" "${OS_ID_LIKE:-none}"

    # This installer uses pacman and Arch-specific package names.
    # Accept CachyOS, Arch Linux, and distributions that explicitly
    # declare Arch in ID_LIKE. Everything else fails closed.
    case "$OS_ID" in
        cachyos|arch)
            ;;
        *)
            case " ${OS_ID_LIKE,,} " in
                *" arch "*)
                    ;;
                *)
                    echo "❌ Unsupported host distribution: ID=$OS_ID ID_LIKE=${OS_ID_LIKE:-unset}." >&2
                    echo "   This installer supports CachyOS and Arch-family distributions only." >&2
                    echo "   No package manager or service commands have been executed." >&2
                    return 1
                    ;;
            esac
            ;;
    esac

    if ! command -v pacman >/dev/null 2>&1; then
        echo "❌ This host identifies as Arch-family, but pacman was not found." >&2
        echo "   Refusing to run an installer whose package manager is unavailable." >&2
        return 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "❌ sudo was not found. Install/configure sudo, then run this script again." >&2
        return 1
    fi

    return 0
}

echo "🔍 Detecting host operating system..."
if ! detect_host_os; then
    exit 2
fi

echo "🔧 Installing KVM + Libvirt + Virt-Manager on $OS_NAME..."

# Install required packages only after the host has passed validation.
sudo pacman -S --needed qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat libvirt iptables-nft || {
    echo "❌ Package installation failed."
    exit 1
}

# Enable and start libvirtd
echo "🚀 Enabling and starting libvirtd..."
sudo systemctl enable --now libvirtd || {
    echo "❌ Failed to enable libvirtd."
    exit 1
}

# Add current user to libvirt group
TARGET_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "$TARGET_USER" ]]; then
    echo "❌ Could not determine the invoking user; refusing to modify group membership."
    exit 1
fi

echo "👤 Adding $TARGET_USER to libvirt group..."
sudo usermod -aG libvirt "$TARGET_USER" || {
    echo "❌ Failed to add user to libvirt group."
    exit 1
}

echo "✅ KVM + Libvirt + Virt-Manager installation complete."
echo "ℹ️ Please log out and back in for group changes to take effect."
