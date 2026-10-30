# Native Tailscale TUN Module for Magisk & KernelSU

[![Build Official Tailscale ARM64 & Module](https://github.com/ATIK455/tailscale-native-module/actions/workflows/build.yml/badge.svg)](https://github.com/ATIK455/tailscale-native-module/actions/workflows/build.yml)

A high-performance root module for Android that runs a full-featured, native `tailscaled` daemon with true Linux kernel TUN (`/dev/tun`) and policy routing.

Built directly from official [tailscale/tailscale](https://github.com/tailscale/tailscale) releases with automated GitHub Actions.

---

## ⚡ Features
- **Official Tailscale Engine**: Automatically cross-compiled from official upstream tags (`v1.104.4+`).
- **Zero VpnService Overhead**: Operates directly at the Linux kernel level via `/dev/tun`.
- **Conflict-Free Fwmarks**: Patched firewall marks (`0x10020000`) and `protectedFromVpn` bit avoid collisions with Android's system `netd` daemon and allow coexistence with third-party VPN apps.
- **Lightweight Flashable ZIP**: The installation zip (`tailscale-native.zip`) is only ~10 KB. It automatically downloads and verifies the latest binary during installation.
- **One-Tap In-Place Updates**: Tap **Action** in Magisk or KernelSU (or KernelSU WebUI) to seamlessly update the daemon binaries without rebooting.

---

## 📥 Installation

1. Download **`tailscale-native.zip`** from the [Latest Release](https://github.com/ATIK455/tailscale-native-module/releases/latest).
2. Flash the zip in **Magisk**, **KernelSU**, or **APatch**.
3. Reboot your device to start the daemon.

---

## 🔄 Updating Binaries

You can update the daemon anytime without rebooting:
* **KernelSU / Magisk**: Open the Manager app, go to **Modules**, and tap the **Action** button next to **Native Tailscale TUN**.
* **Terminal / Termux**: Run:
  ```bash
  su -c "/data/adb/modules/native_tailscale/action.sh"
  ```

---

## 🤖 Automated Builds via GitHub Actions

This repository automatically compiles and releases new versions when triggered or on a weekly schedule.

To build any specific official Tailscale release:
1. Go to the **Actions** tab in this repo.
2. Select **Build Official Tailscale ARM64 & Module**.
3. Click **Run workflow** (enter any tag, e.g. `v1.104.4`, or leave blank for latest).
