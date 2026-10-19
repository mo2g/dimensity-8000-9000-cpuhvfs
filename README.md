# Dimensity 8000/9000 cpuhvfs

**Open-source MediaTek CPU undervolting driver for Dimensity 8000/9000, packaged as a kernel-locked Magisk module.**

[中文说明](README.zh-CN.md) · [Build guide](docs/BUILD.md) · [Smart Power integration](docs/INTEGRATION.md) · [Safety model](docs/SAFETY.md)

[![License: GPL-2.0](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](LICENSE)
[![Magisk](https://img.shields.io/badge/Magisk-30.6%2B-00A96E.svg)](https://github.com/topjohnwu/Magisk)
[![Android 13](https://img.shields.io/badge/Android-13-3DDC84.svg)](https://www.android.com/)
[![Kernel](https://img.shields.io/badge/kernel-5.10.136--pearl--cve43499-orange.svg)](docs/COMPATIBILITY.md)

> [!WARNING]
> This is an experimental kernel module, not a universal undervolting app.
> The included `.ko` is built for exactly `5.10.136-pearl-cve43499`.
> A mismatch is rejected by the installer and by `cpuhvfs-ctl`. Back up `boot` first.

![Terminal preview of the tested Smart Power status](assets/terminal-preview.svg)

*Example output from the tested device. `uv_live` is the measured firmware offset, not a requested profile.*

## Why this project exists

The popular closed-source `天玑8000/9000降压` module is unmaintained and ships a
kernel module that must be force-loaded across kernel versions. This project
builds the driver from the public MediaTek `cpufreq_v1` source in Xiaomi's
`pearl-s-oss` kernel tree and wraps it with kernel, dependency, and conflict
checks.

It is intentionally narrow: **one device family, one known-good kernel binary,
and a driver only by default**. That makes the project useful without pretending
that one `.ko` can be safe on every Dimensity phone.

## Features

- **Real vendor source** — MediaTek `cpuhvfs` source from the Xiaomi pearl kernel tree (GPL-2.0).
- **Kernel-locked** — `vermagic` and vendor-symbol CRCs are checked before loading.
- **Safe default** — the service loads the driver but never writes an undervolt by itself.
- **Namespaced state** — `/data/adb/dimensity-8000-9000-cpuhvfs/state`; no generic `/data/adb/cpuhvfs` collisions.
- **Crash latch** — an armed profile is invalidated when the next boot happens during observation.
- **Smart Power ready** — documented `power.conf` contract and a tested integration patch.
- **Auditable build** — source, exact config, vendor CRCs, and reproducible build instructions are in the repo.

## Tested configuration

This is the configuration used for the published build. Treat it as evidence,
not as a universal compatibility promise.

| Component | Tested value |
|---|---|
| Device | Redmi Note 12T Pro (`pearl`) |
| SoC | MediaTek Dimensity 8200-Ultra (`MT6895`) |
| ROM | MIUI 14 V14.0.5.0.TLHCNXM / Android 13 |
| Kernel | `5.10.136-pearl-cve43499` |
| Root | Magisk 30.6 |
| Smart Power | managed mode |
| Profile | little `-5`, middle `-8`, big `-9`, cci `0` |
| Measured offset | `-31.25 / -50.00 / -56.25 / 0.00 mV` |
| Observation | passed 600 s, state `stable` |

> The `-5 / -8 / -9 / 0` profile is the already-tested Smart Power profile on
> this specific device. The standalone `cpuhvfs-ctl` default is more conservative:
> `max_abs_steps=6` (about `-37.5 mV`).

## Quick start

### 1. Before flashing

1. Back up `boot_a` and know the rollback command.
2. Disable the old `dimensity_8100_9000_cpuhvfs` module and reboot.
3. Confirm no stale driver is loaded:

```sh
su -c 'lsmod | grep ^cpuhvfs || true'
su -c 'ls -l /proc/eem/eem_offset 2>/dev/null || true'
```

The module is systemless and does **not** format or wipe user data. It also does
not modify `boot`; a boot backup is still mandatory for kernel experiments.

### 2. Install

Download the latest release from the [GitHub Releases page](https://github.com/mo2g/dimensity-8000-9000-cpuhvfs/releases), install it with
Magisk, and reboot once so Magisk can activate the module normally.

For the live-switch procedure that avoids a reboot, see
[`docs/NO-REBOOT-SWITCH.md`](docs/NO-REBOOT-SWITCH.md). That procedure is only
for a device where the old driver is already unloaded and `/proc/eem` is absent.

### 3. Probe and load

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl probe'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl load'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl status'
```

Installation itself does not apply a voltage change.

### 4. Try a conservative profile

```sh
# little / middle / big / cci, in EEM steps
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl apply -3 -3 -3 0'
```

Restore and unload:

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl restore'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl unload'
```

If `trip=reboot_during_observation` appears, review stability first and then:

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl reset-trip'
```

## Smart Power integration

The tested setup uses Smart Power in `managed` mode. Add the following to
`/data/adb/smart-power/power.conf`:

```ini
uv_module_id=dimensity-8000-9000-cpuhvfs
uv_ko_path=/data/adb/modules/dimensity-8000-9000-cpuhvfs/lib/cpuhvfs.ko
uv_keep_module_enabled=1
```

Apply the compatibility patch if Smart Power does not already read these keys:

```sh
cd /data/adb/modules/smart_power
patch -p1 < /data/adb/modules/dimensity-8000-9000-cpuhvfs/patches/smart-power-uv.patch
```

Then use the normal Smart Power commands:

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh apply 0'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh persist on'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh status'
```

`uv_keep_module_enabled=1` prevents Smart Power from writing a `disable` marker
into this module; the module service is driver-only, so it is safe to keep the
Magisk module enabled while Smart Power owns the offsets and circuit breaker.

> `cpuhvfs-ctl status` tracks `cpuhvfs-ctl apply` only. When Smart Power writes
> `/proc/eem/eem_offset` directly, use `uv.sh status` or `powerctl status` for
> the live measured offsets.

## Compatibility

The binary in `lib/` supports only the kernel listed above. Other kernels,
ROMs, or devices require a rebuild against the matching kernel source,
`Module.symvers`, toolchain, and vendor module CRCs.

See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md) and
[`docs/BUILD.md`](docs/BUILD.md).

## Documentation

| Document | Purpose |
|---|---|
| [docs/INTEGRATION.md](docs/INTEGRATION.md) | Smart Power contract, exit codes, status fields |
| [docs/NO-REBOOT-SWITCH.md](docs/NO-REBOOT-SWITCH.md) | Tested live-switch procedure without a reboot |
| [docs/BUILD.md](docs/BUILD.md) | Rebuilding the `.ko` for another kernel |
| [docs/SAFETY.md](docs/SAFETY.md) | Limits, observation window, rollback, trip behavior |
| [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) | Tested matrix and build requirements |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Module, driver, `/proc/eem`, and Smart Power flow |
| [docs/FAQ.md](docs/FAQ.md) | Common install, kernel, and safety questions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Bug reports, testing, and pull requests |
| [ROADMAP.md](ROADMAP.md) | What is planned next |

## Project layout

```text
bin/cpuhvfs-ctl       CLI and safety checks
bin/lib.sh            scoped state and driver helpers
lib/cpuhvfs.ko        prebuilt, kernel-locked driver
src/                  MediaTek cpufreq_v1 source (GPL-2.0)
etc/limits.conf       conservative limits and observation window
configs/              device config and vendor symbol CRCs
patches/              Smart Power integration patch
docs/                 build, safety, compatibility, architecture
```

## Contributing and support

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
- Use the issue forms and include `uname -r`, `cpuhvfs-ctl status`,
  `uv.sh status`, and relevant `dmesg` lines.
- Do not publish a binary built for a different kernel without also publishing
  the matching source, config, and symbol provenance.
- If this project saves you time, a star helps other MediaTek users find it.

## License and credits

The driver source is MediaTek code from the Xiaomi pearl kernel tree. Original
copyright and GPL-2.0 notices are preserved. See [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This project is not affiliated with Xiaomi, MediaTek, Magisk, or Smart Power.
Use at your own risk.
