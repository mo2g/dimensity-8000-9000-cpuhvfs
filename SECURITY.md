# Security policy

This is a privileged kernel module that changes CPU voltage. Treat it as
device firmware-adjacent software.

## Reporting a vulnerability

Please use the repository's **Security → Report a vulnerability** flow
(GitHub Security Advisories) instead of opening a public issue. Include:

- device model, ROM, and exact `uname -r`;
- `cpuhvfs-ctl status` (redact serial numbers);
- relevant `dmesg` lines;
- whether the old module or another `/proc/eem` provider was active;
- a minimal reproduction, if available.

Do not attach proprietary boot images, vendor firmware, personal data, or
another person's device logs. Do not test a kernel exploit or destructive
payload on a device you do not own.

## Scope

Security-relevant reports include:

- a way to bypass the kernel/module compatibility checks;
- unsafe state handling that can apply an offset without the trip latch;
- module-loading paths that can execute unintended commands;
- release binaries that do not match the published source or checksums.

General undervolt tuning issues are support questions, not security
vulnerabilities. No warranty is provided; see [LICENSE](LICENSE).
