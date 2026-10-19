# Roadmap

This roadmap is intentionally conservative. Safety and reproducible evidence
come before adding more devices.

## v1.0.x

- Keep the published binary locked to the tested pearl kernel.
- Improve issue templates and compatibility reporting.
- Add release checksums and reproducible-build notes.
- Keep Smart Power integration documented and tested.

## v1.1

- Add a machine-readable build matrix for additional pearl kernels.
- Provide a one-command local build that verifies vendor-symbol CRCs.
- Add a small read-only status helper for Smart Power users.
- Collect more thermal and stability observations from the tested device.

## Later

- Optional WebUI for `probe` and `status` only.
- More MediaTek source trees, each with its own signed/compatible artifact.
- Automated static checks for shell and package layout.
- Community-maintained device reports with clear provenance.

## Non-goals

- Universal one-binary support across all Dimensity phones.
- Bypassing root detection or Play Integrity.
- Shipping unsigned, undocumented binaries without source.
- Replacing kernel security fixes with a Magisk module.
