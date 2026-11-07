#!/system/bin/sh
# late_start service: runs on boot after the framework is up.
MODDIR=${0%/*}

# First-boot install of the fork app if it is bundled and not yet present.
if [ -f "$MODDIR/stryker.apk" ]; then
  (
    i=0
    while [ $i -lt 30 ]; do
      pm path android >/dev/null 2>&1 && break
      sleep 2; i=$((i+1))
    done
    if ! pm path com.zalexdev.stryker.devicefork >/dev/null 2>&1; then
      pm install -r -g "$MODDIR/stryker.apk" >/dev/null 2>&1
    fi
  ) &
fi
