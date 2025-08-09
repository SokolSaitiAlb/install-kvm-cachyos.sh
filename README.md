````markdown
# KVM + Libvirt + Virt-Manager Installer for CachyOS (Arch)

This script installs and configures **KVM virtualization** on CachyOS (or any Arch-based system) with `virt-manager` for a graphical interface.

## 📋 Features
- Installs **QEMU/KVM**, Libvirt, Virt-Manager, and networking utilities.
- Enables and starts the `libvirtd` service automatically.
- Adds your user to the `libvirt` group for non-root VM management.
- Works on CachyOS, Arch Linux, and other Arch-based distributions.

## 🚀 Installation & Usage

1. **Download the script**  
   ```bash
   wget https://example.com/install-kvm-cachyos.sh
````

2. **Make it executable**

   ```bash
   chmod +x install-kvm-cachyos.sh
   ```

3. **Run the script**

   ```bash
   ./install-kvm-cachyos.sh
   ```

4. **Log out and back in**
   This step is required so group changes take effect.

5. **Launch Virt-Manager**

   ```bash
   virt-manager
   ```

## 🛠 Included Packages

* `qemu-full` — Full QEMU virtualization support
* `virt-manager` — GUI for managing VMs
* `virt-viewer` — Lightweight VM viewer
* `dnsmasq` — Network configuration for VMs
* `vde2`, `bridge-utils` — Networking utilities for virtual bridges
* `openbsd-netcat` — Networking tool
* `libvirt` — Virtualization management daemon
* `iptables-nft` — Firewall backend for networking

## ⚠️ Notes

* Make sure virtualization is enabled in your BIOS/UEFI (`Intel VT-x` / `AMD-V`).
* If you use **Wayland** and Virt-Manager has scaling issues, run it with:

  ```bash
  GDK_SCALE=1 virt-manager
  ```
* To check if KVM is running:

  ```bash
  sudo virsh list --all
  ```

## 📄 License

This script is provided "as-is" without warranty. Use at your own risk.

```

---

