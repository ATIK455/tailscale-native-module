# Native Tailscale TUN Module for Magisk & KernelSU

[![Build Official Tailscale ARM64 & Module](https://github.com/ATIK455/tailscale-native-module/actions/workflows/build.yml/badge.svg)](https://github.com/ATIK455/tailscale-native-module/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/ATIK455/tailscale-native-module?include_prereleases&color=06B6D4)](https://github.com/ATIK455/tailscale-native-module/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance Android root module that runs a native `tailscaled` daemon directly with true Linux kernel TUN (`/dev/tun`) and policy routing. 

Built automatically from official [tailscale/tailscale](https://github.com/tailscale/tailscale) upstream releases via GitHub Actions.

---

## ⚡ Features

- **True Kernel TUN (`/dev/tun`)**: Routes traffic directly through the Linux kernel without the performance penalties, JNI latency, or memory overhead of Android's userspace `VpnService`.
- **Zero Conflict with Other VPNs**: Claimed `protectedFromVpn` bit and high-order firewall marks (`0x10020000`) prevent collisions with Android's system `netd` daemon and allow coexistence with third-party VPN apps.
- **Official Tailscale Engine**: Automatically cross-compiled from official upstream release tags (`v1.104.4+`).
- **Lightweight Flashable ZIP**: The installation zip (`tailscale-native.zip`) is ~6 KB. It downloads and validates verified ARM64 binaries during installation.
- **In-Place Daemon Updates**: Tap the **Action** button in Magisk, KernelSU, or KernelSU WebUI to update `tailscale` and `tailscaled` in-place without rebooting.

---

## 📥 Installation

1. Download **`tailscale-native.zip`** from the [Latest Release](https://github.com/ATIK455/tailscale-native-module/releases/latest).
2. Flash the zip in **KernelSU**, **Magisk**, or **APatch**.
   *(The installer will download the latest compiled ARM64 binaries and verify ELF integrity).*
3. Disconnect or uninstall the official unprivileged Tailscale Android app to prevent TUN conflicts.
4. Reboot your device to start the native daemon service.

---

## 💻 CLI & Control Commands

All control operations interface with the native daemon via its dedicated Unix domain socket (`/data/adb/tailscale-native/tailscaled.sock`).

### Convenient Alias (Termux / Root Shell)
To avoid typing the full socket path every time, add this alias to your shell profile (`~/.bashrc` or `~/.zshrc` in Termux):
```bash
alias ts='su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock"'
```

---

### 1. Connection & Login

#### Standard Interactive Login (Tailscale SaaS)
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock up"
```
*(Visit the URL printed in the terminal to authenticate this node in your Tailscale control plane).*

#### Headscale / Self-Hosted Control Plane
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock up --login-server=https://headscale.yourdomain.com --auth-key=tskey-auth-xxxx"
```

#### Connect with Subnet Routes & MagicDNS
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock up --accept-routes=true --accept-dns=true"
```

#### Connect Using an Exit Node
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock up --exit-node=100.x.y.z --exit-node-allow-lan-access=true"
```

#### Advertise This Device as an Exit Node
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock up --advertise-exit-node"
```

---

### 2. Status & Network Diagnostics

#### View Tailnet Status & Connected Peers
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock status"
```

#### Run DERP Relay & Latency Check (Netcheck)
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock netcheck"
```

#### Ping a Peer on Your Tailnet
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock ping 100.x.y.z"
```

---

### 3. Disconnect & Logout

#### Disconnect Session (Puts Daemon into Standby)
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock down"
```

#### Log Out Completely
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock logout"
```

---

### 4. Background Daemon Lifecycle

To completely start, stop, or restart the background `tailscaled` daemon service:

#### Start the Daemon
```bash
su -c "/data/adb/modules/native_tailscale/service.sh"
```

#### Stop the Daemon
```bash
su -c "kill \$(cat /data/adb/tailscale-native/tailscaled.pid) && rm -f /data/adb/tailscale-native/tailscaled.pid /data/adb/tailscale-native/tailscaled.sock"
```

#### Restart the Daemon
```bash
su -c "/data/adb/modules/native_tailscale/action.sh"
```

---

### 5. Taildrop (Encrypted File Transfers)

#### Send a File to a Peer
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock file cp /sdcard/Download/photo.jpg peer-hostname:"
```

#### Fetch Received Files into Storage
```bash
su -c "/data/adb/tailscale-native/bin/tailscale --socket=/data/adb/tailscale-native/tailscaled.sock file get /sdcard/Download"
```

---

## 🔄 Updating the Daemon

You can update the native binaries anytime without rebooting:
* **KernelSU / Magisk**: Open the Manager app, go to **Modules**, and tap the **Action** button next to **Native Tailscale TUN**.
* **KernelSU WebUI**: Tap the **Action** button.
* **Terminal**: Run:
  ```bash
  su -c "/data/adb/modules/native_tailscale/action.sh"
  ```

---

## 🤖 Automated Builds

This repository automatically tracks upstream [Tailscale releases](https://github.com/tailscale/tailscale/releases) on a weekly schedule. The GitHub Actions CI/CD pipeline patches the source, cross-compiles static ARM64 binaries using pure Go, and publishes verified module zip assets with cryptographic checksums.

---

## 📜 Credits & Acknowledgements

- **[Tailscale](https://github.com/tailscale/tailscale)** (Tailscale Inc.) - Official Tailscale engine, WireGuard implementation, and protocol.
- **[kxxt](https://github.com/android-kxxt)** ([`android-kxxt/external_tailscale`](https://github.com/android-kxxt/external_tailscale)) - Groundbreaking research on native AOSP integration, Android kernel TUN routing, and conflict-free firewall mark (`fwmarks`) allocation.
- **[Iridule](https://github.com/iridule)** - Initial bootstrap packaging and Magisk service script foundation.

---

## 📄 License

This project's packaging scripts and module structure are licensed under the [MIT License](LICENSE), respecting the original work by [Iridule](https://github.com/iridule).

Upstream [Tailscale](https://github.com/tailscale/tailscale) source code, libraries, and compiled binaries are licensed under the [BSD 3-Clause License](https://github.com/tailscale/tailscale/blob/main/LICENSE).
