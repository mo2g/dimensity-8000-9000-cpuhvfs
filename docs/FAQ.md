# FAQ

## Does installing this erase data?

No. This is a systemless Magisk module and does not format userdata. It does
not modify the boot partition either. However, it loads a kernel module that
changes CPU voltage, so a boot backup and a rollback plan are still required.

## Does this root my phone?

No. You need an already-working root solution, currently tested with Magisk.

## Can I use it on another Dimensity 8000/9000 phone?

Not with the published `.ko` unless its `uname -r` is exactly
`5.10.136-pearl-cve43499`. Rebuild from that device's kernel source, config,
`Module.symvers`, vendor modules, and matching toolchain.

## Why does the installer refuse a kernel mismatch?

Because kernel modules use `vermagic`, `module_layout`, and per-symbol CRCs.
A binary can compile successfully and still crash, reject, or corrupt state on
a different kernel.

## Is the default safe?

The service loads the driver only. It does not apply a profile automatically.
The `cpuhvfs-ctl` default limit is `max_abs_steps=6`. The tested Smart Power
profile `-5 / -8 / -9 / 0` is more aggressive and is owned by Smart Power's
managed mode and observation logic.

## Why does `cpuhvfs-ctl status` show `applied=0` while Smart Power shows offsets?

Because Smart Power writes `/proc/eem/eem_offset` directly. `cpuhvfs-ctl` only
records offsets written through `cpuhvfs-ctl apply`. Use:

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh status'
```

for the live measured offsets.

## What is `/data/adb/dimensity-8000-9000-cpuhvfs/state`?

It is the namespaced state directory for this module. Do not use
`/data/adb/cpuhvfs/state`; that generic path can collide with another module.

## Can I run the old module and this module together?

No. Both expose the kernel name `cpuhvfs` and the global `/proc/eem` interface.
Keep exactly one enabled and unload the other driver before switching.

## Does it help with PayPal or other root-detection apps?

No. This is a CPU voltage driver, not a root-hiding solution. Root detection is
a separate problem involving the root implementation, package visibility,
injection, and app-specific RASP behavior.

## Does it include CVE-2026-43499 or a kernel exploit?

No. It is a privileged debug-driver module. Kernel hardening and CVE fixes are
separate concerns; use a kernel with the relevant fixes if needed.

## How do I uninstall?

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh rollback'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl unload'
```

Then remove the module in Magisk. If you migrated from the old module, restore
your Smart Power configuration from the backup you made before the switch.
