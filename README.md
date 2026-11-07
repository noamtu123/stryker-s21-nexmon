# Stryker S21 — Native Nexmon Wireless Backend

A fork of [StrykerOSS](https://github.com/zalexdev/strykerapp) tailored to the
**Samsung Galaxy S21 (Exynos 2100, SM‑G991B)** running the **Floppy kernel's
Nexmon** patch, with the Wi‑Fi attack tooling running **natively** on the
internal radio (`wlan0`) instead of through the chroot.

> Development build. Use only against networks and devices you own or are
> explicitly authorized to test.

## What's different from upstream

- **Native wireless backend.** `airodump-ng` and `aireplay-ng` (aircrack‑ng 1.7)
  and the legacy `wireless_tools` (`iwpriv`/`iwconfig`/`iwlist`) are
  cross‑compiled for aarch64 (Android PIE, statically linked against OpenSSL +
  zlib, **built without libnl**) and bundled as app assets. On `wlan0` the app
  runs these on the host (no chroot), gated by an `AIRCRACK_NEXMON=1` env var so
  the osdep layer only binds/reads/injects and leaves the nexutil‑armed radiotap
  monitor untouched.
- **Reliable monitor arming.** The Nexmon FullMAC firmware needs a warm‑up: the
  first arm after `svc wifi disable` often delivers no frames, so
  `MonitorManager` runs two arm/disarm cycles then a final arm. Channel is owned
  by `nexutil` (no `iw`‑based channel set on `wlan0`, which disrupts the
  monitor).
- **S21 behavior tweaks** carried from the fork: English/system language
  selector, Android Wi‑Fi auto‑disabled on open, internal deauth default on,
  startup consent removed. WPS/scan/deauth interfaces default to `wlan0`.

## Verified on device (S21, Floppy kernel)

- Native monitor **capture** (airodump on the radiotap interface).
- Packet **injection** (`aireplay-ng -9` self‑test).
- **Targeted deauth → WPA2 4‑way handshake** capture, end‑to‑end.
- **WPS** attack pipeline (Pixie‑Dust + PIN mode) drives full association /
  M1‑M2 / crypto via OneShot (`pixie.py`).
- **PMKID** via the native capture path.

WPA3/SAE (PMF) correctly defeats deauth — that's by design, not a tool gap.

## aircrack‑ng osdep patches

The native tools are built from a clean `aircrack-ng-1.7` tree with a small
patch set (recognise the radiotap interface, add the app `files/` dir +
`/system/bin` to the tool search path, and gate every radio‑touching op —
`set_monitor`, `SIOCSIFFLAGS`, `PROMISC`, channel/rate/freq/mtu — behind
`AIRCRACK_NEXMON`). Dependencies: aarch64 NDK (r27c), OpenSSL 3.0.x, zlib 1.3.1,
`wireless_tools` 29.

## Build

Android build fails in a path containing spaces, so build from a short path.

```
export JAVA_HOME=.../jdk-17
export ANDROID_HOME=.../Android/Sdk
gradle :app:assembleDebug --no-daemon
```

Output: `app/build/outputs/apk/debug/app-debug.apk` (debug‑signed,
development only).

## KernelSU‑Next module

`ksu-module/` builds a KernelSU‑Next / Magisk module that supplies the native
tools in `system/bin`, installs/updates the fork APK, and launches the app from
the module **Action** button. It does **not** change SELinux or remount
firmware (the separate `bcm_mon_boot` module keeps mounting the Nexmon
firmware). See `ksu-module/README.md`.
