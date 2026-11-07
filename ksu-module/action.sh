#!/system/bin/sh
# KernelSU-Next Action button: launch the Stryker S21 fork app.
PKG=com.zalexdev.stryker.devicefork

am start -n "$PKG/com.zalexdev.stryker.MainActivity" >/dev/null 2>&1 \
  || monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

echo "Launched Stryker S21 (dev)."
