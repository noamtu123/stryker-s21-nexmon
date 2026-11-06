# S21 suite: research and device findings

## Device verified
- Exynos 2100, BCM4375, Floppy v1.1.2 with PR 10 native Nexmon driver changes.
- Monitor frames captured on channel 6 and channel 36. Disarm and rearm changed reported interface type, but repeated recovery and GUI handshake capture remain unverified.
- Kernel reports CONFIG_USB_CONFIGFS, CONFIG_USB_CONFIGFS_F_HID, CONFIG_USB_CONFIGFS_MASS_STORAGE and CONFIG_USB_CONFIGFS_RNDIS enabled. A UDC exists; no host-side HID execution tested.
- SELinux currently permissive. Passive capture succeeded during a temporary enforcing test; an enforcing boot and other ROM functions remain unverified.

## Tool assessment
- Aircrack-ng: native capture/injection tool family. Android-compatible arm64 binaries and runtime dependencies must be verified before replacing the Debian chroot path. https://github.com/aircrack-ng/aircrack-ng
- Wifite2: Python orchestrator around Aircrack-ng and other tools, not a substitute for radio control. Requires dependency/version detection; tell it to use the prepared interface and guard cross-band changes. https://github.com/derv82/wifite2
- OneShot-Extended: WPS tool using wpa_supplicant and a different interface workflow; monitor-mode assumptions cannot simply be reused. Verify dependencies and radio ownership. https://github.com/chkndrp/OneShot-Extended
- Android USB gadget projects use configfs/f_hid and require controller and device node access. The hardware check is only a prerequisite, not proof of HID compatibility. USB gadget switching may interrupt ADB and needs recovery. https://github.com/Netdex/android-usb-script

## Current fork constraints
- /system/bin/nexutil or the bundled fallback is used by the initial internal-radio path. Capture workflows still use the Debian rootfs; no native airodump/aireplay on the inspected phone.
- The separate package/rootfs is intended to protect the original Stryker install. It still needs installation, upgrade, uninstall and concurrency audits.
- Initial monitor integration, band rearming, language and recovery need end-to-end testing in the installed app. No valid handshake has yet been verified.
- Bluetooth helper in the upstream module is tailored to a NetHunter chroot and stops Android Bluetooth; do not use unchanged.
