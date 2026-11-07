# Native Tailscale TUN Module Changelog

## v1.104.5 (2026-11-07)
- Upstream engine updated to official Tailscale [v1.104.5](https://github.com/tailscale/tailscale/releases/tag/v1.104.5)
- Cross-compiled ARM64 native binaries with true Linux kernel TUN routing
- Conflict-free Android fwmarks (0x10020000) with protectedFromVpn bit

> **Upstream Notes**: Please refer to the changelog available at https://tailscale.com/changelog

## v1.104.4
- Official Tailscale upstream engine v1.104.4
- Direct kernel TUN device routing with high-order fwmarks (avoids Android netd conflicts)
- Automated ARM64 builds via GitHub Actions
- In-place binary updates via Action button in KernelSU / Magisk WebUI
- Support for Magisk and KernelSU module update notifications
