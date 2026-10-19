# Security policy

This is a kernel module that changes CPU voltage. Treat it as privileged
device software.

Report crashes, boot loops, module-load failures, or security issues through
the repository issue tracker with:

- device model and ROM;
- exact `uname -r`;
- `cpuhvfs-ctl status`;
- relevant `dmesg` lines;
- whether the old module or another `/proc/eem` provider was active.

Never attach a proprietary boot image, vendor firmware, or personal data.
Do not use this module to bypass a device owner's security controls.

No warranty is provided. See `LICENSE`.
