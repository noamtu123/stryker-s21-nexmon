SKIPUNZIP=0

ui_print " "
ui_print "  Stryker S21 Nexmon Backend"
ui_print "  native aircrack-ng / wireless_tools + launcher"
ui_print " "

# arm64 only. The ROM identity is spoofed on this device, so do NOT gate on
# model/brand -- just require an arm64 ABI.
case "$(getprop ro.product.cpu.abi)" in
  arm64*) ui_print "- arm64 device OK" ;;
  *) abort "! This module requires an arm64 device" ;;
esac

ui_print "- Installing native wireless tools into system/bin"
set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755

# Install / update the Stryker fork app when a framework is available
# (e.g. installing from the KernelSU-Next / Magisk manager app).
if [ -f "$MODPATH/stryker.apk" ]; then
  if pm path android >/dev/null 2>&1; then
    ui_print "- Installing / updating the Stryker fork app"
    if pm install -r -g "$MODPATH/stryker.apk" >/dev/null 2>&1; then
      ui_print "  app installed / updated"
    else
      ui_print "  app install deferred to first boot (signature or state)"
    fi
  else
    ui_print "- No framework now; the app installs on first boot"
  fi
fi

ui_print " "
ui_print "- Done. Tap this module's Action button to launch Stryker."
ui_print "- This module does not touch SELinux or firmware mounts."
ui_print " "
