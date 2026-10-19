# dimensity-8000-9000-cpuhvfs

Open-source MediaTek `cpuhvfs` driver and Magisk module for Dimensity 8000/9000 (MT6895/MT6896). It replaces the abandoned closed-source module.

**Important:** the included `lib/cpuhvfs.ko` is built only for `5.10.136-pearl-cve43499`. The installer refuses a kernel mismatch. The default action is driver-only; no voltage offset is applied automatically.

## State path collision

A generic `/data/adb/cpuhvfs/state` is global and can collide with another module. This project uses:

```text
/data/adb/dimensity-8000-9000-cpuhvfs/state
```

The kernel module name `cpuhvfs` and `/proc/eem/eem_offset` are still global; the installer refuses to run alongside the old enabled module or a foreign `/proc/eem`.

## Quick start

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl probe'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl apply -3 -3 -3 0'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl restore'
```

See [docs/INTEGRATION.md](docs/INTEGRATION.md), [docs/BUILD.md](docs/BUILD.md), and [docs/SAFETY.md](docs/SAFETY.md). GPL-2.0; see [LICENSE](LICENSE).
