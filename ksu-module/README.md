# Stryker S21 Nexmon Backend — KernelSU‑Next module

A KernelSU‑Next / Magisk module that supports the Stryker S21 fork:

- **Supplies the native backend** — installs `airodump-ng`, `aireplay-ng`,
  `iwpriv`, `iwconfig`, `iwlist` and `nexutil` into `system/bin` (systemless
  overlay, fully reversible).
- **Installs / updates the fork app** — bundles the debug APK and installs it
  (via the manager app during flashing, with a first‑boot fallback in
  `service.sh`).
- **Action button** — tap *Action* on the module in KernelSU‑Next to launch the
  Stryker app (`action.sh`).

## What it deliberately does NOT do

- It does **not** run `setenforce` or change SELinux.
- It does **not** mount or remount the Nexmon firmware — the separate
  `bcm_mon_boot` module keeps doing that. Install/keep that module as before.
- It does **not** disable any other module.

## Install order

Per the kernel author's guidance, **set up the Stryker app first**, then install
this module from the KernelSU‑Next manager (it will update the app if bundled).
Keep `bcm_mon_boot` active for the firmware mount. Have USB/ADB recovery
available the first time, as with any module.

## Layout

```
module.prop        id / name / version / description
customize.sh       install-time: arm64 check, perms, install the app
service.sh         late_start: first-boot app install fallback
action.sh          KernelSU-Next Action: launch the app
system/bin/*       native wireless tools (added at build time)
stryker.apk        the fork app (added at build time)
META-INF/...       standard module installer stub
```

## Build the zip

`system/bin/*` and `stryker.apk` are build artifacts (git‑ignored). Assemble
with `build.sh`, pointing it at the built tools and APK:

```
AIRCRACK_DIR=~/native-wireless/src/aircrack-ng-1.7 \
WTOOLS_DIR=~/native-wireless/src/wireless_tools.29 \
NEXUTIL=.../assets/nexutil_device \
APK=.../app/build/outputs/apk/debug/app-debug.apk \
OUT=stryker-s21-backend-v1.0.0.zip \
bash build.sh
```
