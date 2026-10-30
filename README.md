# KVM + Libvirt + Virt-Manager Installer for CachyOS (Arch)

A Bash installer for setting up **QEMU/KVM**, **libvirt**, and **virt-manager** on CachyOS and supported Arch-family Linux distributions.

## Supported operating systems

The installer reads `/etc/os-release` before executing any package-manager or service command.

- **CachyOS** (`ID=cachyos`)
- **Arch Linux** (`ID=arch`)
- Other distributions that explicitly declare Arch in `ID_LIKE`, provided `pacman` and `sudo` are available

Unsupported distributions, missing OS metadata, and Arch-family systems without `pacman` are rejected safely. The script does **not** fall back to `apt`, `dnf`, `zypper`, or another package manager.

## Features

- Installs QEMU/KVM, Libvirt, Virt-Manager, and networking utilities.
- Enables and starts the `libvirtd` service.
- Adds the invoking user to the `libvirt` group.
- Detects the host distribution before making system changes.
- Fails closed on unsupported or unidentifiable operating systems.

## Installation and usage

Clone the repository:

```bash
git clone https://github.com/SokolSaitiAlb/install-kvm-cachyos.sh.git
cd install-kvm-cachyos.sh
```

Review the script before running it:

```bash
less install-kvm-cachyos.sh
```

Make it executable and run it as your regular user (the script invokes `sudo` for privileged operations):

```bash
chmod +x install-kvm-cachyos.sh
./install-kvm-cachyos.sh
```

Log out and back in after completion so the new `libvirt` group membership takes effect. Then launch:

```bash
virt-manager
```

## Detection behavior

The script uses the `ID` and `ID_LIKE` fields in `/etc/os-release`. It accepts CachyOS, Arch Linux, and distributions whose `ID_LIKE` explicitly contains `arch`. It also verifies that `pacman` and `sudo` are available.

If detection fails or the distribution is unsupported, the script exits before calling `pacman`, `systemctl`, or `usermod`. This is intentional: package names and service assumptions in this installer are Arch-specific.

## Included packages

- `qemu-full` — QEMU virtualization packages
- `virt-manager` — graphical VM manager
- `virt-viewer` — VM console viewer
- `dnsmasq` — virtual network DHCP/DNS support
- `vde2`, `bridge-utils` — virtual networking utilities
- `openbsd-netcat` — networking utility
- `libvirt` — virtualization management
- `iptables-nft` — firewall backend used by libvirt networking

## Prerequisites and notes

- Enable Intel VT-x or AMD-V/SVM in BIOS/UEFI.
- Run the script as a regular user with working `sudo` privileges.
- Review package prompts before confirming installation.
- If Virt-Manager has scaling issues under Wayland, try:

  ```bash
  GDK_SCALE=1 virt-manager
  ```

- Check libvirt domains with:

  ```bash
  virsh -c qemu:///system list --all
  ```

## Testing

The OS detection function can be exercised with a temporary os-release fixture by setting `OS_RELEASE_FILE`. For example:

```bash
OS_RELEASE_FILE=/path/to/test-os-release ./install-kvm-cachyos.sh
```

Do not use a fabricated OS-release file for a real installation.

## License

This script is provided "as-is" without warranty. Use it only after reviewing the commands and understanding the system changes it makes.
