# Safety model

This module changes CPU voltage through MediaTek's EEM debug interface. It is
not a cosmetic tweak.

## Defaults

- `service.sh` loads the driver only.
- No boot profile and no automatic `apply`.
- `max_abs_steps=6`; positive offsets are rejected.
- Each cluster is written separately with a delay.
- A failed write attempts to restore all clusters to zero.

## Reboot / trip

Before an `apply`, the CLI records the current boot ID and sets `armed=1`.
`post-fs-data.sh` runs on the next boot:

- same boot ID and `armed=1`: still the current observation; nothing changes;
- different boot ID and `armed=1`: writes `trip=reboot_during_observation`,
  clears the applied state, and refuses to auto-load the driver.

This is deliberately conservative: an intentional reboot during observation
also trips. Use `confirm` before a planned reboot if the profile has been
stable for the full observation window, or `reset-trip` after reviewing logs.

## Limits

`etc/limits.conf` is installed with the module and can be edited:

```ini
max_abs_steps=6
ramp_delay_sec=1
observe_sec=600
```

`max_*` values are per-cluster caps. Keep `cci` at `0` unless there is a
specific, measured reason to change it.

## Before testing

1. Back up `boot_a` and know the rollback command.
2. Confirm `/proc/eem/eem_offset` is absent before installing.
3. Disable the old `dimensity_8100_9000_cpuhvfs` module and reboot.
4. Start with a small offset such as `-2` or `-3`, not the maximum.
5. Do not test while driving, during an important call, or before a backup.
6. If the phone bootloops, remove/disable the module from Magisk safe mode
   or restore `boot_a`; this module does not modify the boot partition.

The `.ko` is kernel-locked. Never bypass the `vermagic` check by editing the
module or using a vendor `allow_mismatch` option.
