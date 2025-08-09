#!/bin/bash
# =========================================================
# KVM + Libvirt + Virt-Manager Installer for CachyOS (Arch)
# Author: Alb Kestrel
# =========================================================

echo "🔧 Installing KVM + Libvirt + Virt-Manager on CachyOS..."

# Install required packages
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
echo "👤 Adding $USER to libvirt group..."
sudo usermod -aG libvirt "$USER" || {
    echo "❌ Failed to add user to libvirt group."
    exit 1
}

echo "✅ KVM + Libvirt + Virt-Manager installation complete."
echo "ℹ️ Please log out and back in for group changes to take effect."
