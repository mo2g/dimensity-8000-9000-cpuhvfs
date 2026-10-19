# Changelog

## v1.0.0

- First standalone open-source module.
- Uses the MediaTek `cpufreq_v1` source from the Xiaomi pearl kernel tree.
- Namespaced state directory:
  `/data/adb/dimensity-8000-9000-cpuhvfs`.
- Driver-only default; no automatic undervolt.
- Kernel vermagic, vendor-symbol, old-module, and `/proc/eem` conflict checks.
- Safe `cpuhvfs-ctl` CLI and Smart Power integration contract.
