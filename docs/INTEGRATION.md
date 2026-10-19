# Smart Power integration contract

This document is the machine-facing contract between
`dimensity-8000-9000-cpuhvfs` and Smart Power (or another controller).

The module intentionally does **not** apply an undervolt at boot. It only
loads the driver. The controller decides whether to call `cpuhvfs-ctl apply`.

## 1. Module identity and paths

```text
module id:  dimensity-8000-9000-cpuhvfs
module dir: /data/adb/modules/dimensity-8000-9000-cpuhvfs
ko:         .../lib/cpuhvfs.ko
ctl:        .../bin/cpuhvfs-ctl
state:      /data/adb/dimensity-8000-9000-cpuhvfs/state
trip:       /data/adb/dimensity-8000-9000-cpuhvfs/trip
log:        /data/adb/dimensity-8000-9000-cpuhvfs/module.log
```

Do **not** use `/data/adb/cpuhvfs/state`: that path is not namespaced by the
Magisk module ID and would collide with another module.

## 2. `power.conf` keys

Add these to `/data/adb/smart-power/config/power.conf`:

```ini
uv_module_id=dimensity-8000-9000-cpuhvfs
uv_ko_path=/data/adb/modules/dimensity-8000-9000-cpuhvfs/lib/cpuhvfs.ko
```

The equivalent environment variables remain supported and take precedence:

```sh
SP_UV_MOD_ID=dimensity-8000-9000-cpuhvfs \
SP_UV_KO=/data/adb/modules/dimensity-8000-9000-cpuhvfs/lib/cpuhvfs.ko \
sh /data/adb/modules/smart_power/bin/uv.sh status
```

**Important:** if Smart Power keeps its existing direct-write path, it writes
`/proc/eem/eem_offset` itself and does not consult this module's
`etc/limits.conf`. Set Smart Power's own limit as well:

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh limit 6'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh confirm-sec 600'
```

## 3. Minimal Smart Power patch

Current Smart Power `bin/uv.sh` defaults to the old module ID. Replace the
two default assignments near the top of the script with:

```sh
SP_UV_MOD_ID="${SP_UV_MOD_ID:-$(sp_get uv_module_id)}"
SP_UV_MOD_ID="${SP_UV_MOD_ID:-dimensity_8000_9000_cpuhvfs}"
SP_UV_MOD_DIR="${SP_UV_MOD_DIR:-/data/adb/modules/$SP_UV_MOD_ID}"
SP_UV_KO="${SP_UV_KO:-$(sp_get uv_ko_path)}"
SP_UV_KO="${SP_UV_KO:-$SP_UV_MOD_DIR/lib/cpuhvfs.ko}"
```

`sp_get` must already have loaded `power.conf`; current Smart Power calls
`sp_load_conf` before these assignments, so the patch is a drop-in. A ready-to-apply
diff is in `patches/smart-power-uv.patch`.

The old module is **not** a safe fallback for this module because both expose
the same kernel name `cpuhvfs` and `/proc/eem`. Keep exactly one of them
enabled.

## 4. CLI contract

All commands print `key=value` lines. Errors go to stderr and use the exit
codes below.

| Command | Exit codes | Meaning |
|---|---:|---|
| `probe` | 0 | kernel/ko match and no blocking conflict |
| | 2 | `ko_match=0` or `.ko` missing |
| | 5 | old module, foreign `/proc/eem`, or trip |
| `load` | 0 | `cpuhvfs` loaded and `/proc/eem/eem_offset` exists |
| | 2 | kernel/ko vermagic mismatch |
| | 3 | `insmod` failed, dependency missing, or `/proc/eem` did not appear |
| | 5 | conflict or trip |
| `apply L M B C` | 0 | all four offsets written |
| | 2/3 | preflight/load/write failure |
| | 4 | invalid argument or limit violation |
| | 5 | conflict or trip |
| `restore` | 0 | zeros written (or `/proc/eem` absent) |
| | 3 | write failure |
| `unload` | 0 | driver removed |
| | 3 | `rmmod` failed |
| `confirm` | 0 | clears the standalone armed flag |
| `reset-trip` | 0 | clears trip and zeros offsets |
| `status` | 0 | always; read-only |
| `version` | 0 | prints `1.0.0` |

Offsets are EEM steps. The module accepts only `0` or negative values.
`max_abs_steps=6` by default (about `-37.5 mV` at `6.25 mV/step`). Optional
per-cluster caps are `max_little`, `max_middle`, `max_big`, `max_cci`.

## 5. `status` output

Example:

```text
module=dimensity-8000-9000-cpuhvfs
version=1.0.0
kernel=5.10.136-pearl-cve43499
ko_vermagic=5.10.136-pearl-cve43499
ko_match=1
ko_loaded=1
eem_present=1
max_abs_steps=6
applied=-5 -8 -9 0
armed=1
state=ready
boot_id=...
trip=none
```

`armed=1` means the standalone safety latch is set. `post-fs-data.sh` turns
a reboot in that state into `trip=reboot_during_observation`. Smart Power's
own observation window is independent and remains authoritative when
Smart Power writes `/proc/eem` directly.

## 6. Recommended controller flow

1. `probe`; require exit 0.
2. Check battery temperature and charge state in Smart Power.
3. `apply L M B C` with a conservative profile.
4. Observe. If the device reboots unexpectedly, next boot is blocked by the
   trip file.
5. After a deliberate reboot, run `reset-trip` only after confirming the
   previous configuration was acceptable.
6. `restore` before `unload`, module removal, or returning to the old module.
