# Launch and community checklist

The goal is not to chase stars with unsafe claims. The goal is to make the
project easy to trust, easy to try, and easy to report against.

## Before announcing

- [ ] Push the repository and confirm the README renders on GitHub.
- [ ] Add repository description: “Open-source MediaTek cpuhvfs undervolt driver for Dimensity 8000/9000.”
- [ ] Add topics: `magisk`, `mediatek`, `dimensity`, `undervolt`, `android`, `kernel`, `mt6895`, `smart-power`.
- [ ] Upload `assets/social-preview.png` as the GitHub social preview.
- [ ] Create a tagged release with the Magisk zip and SHA256.
- [ ] Confirm `module.prop`'s `updateJson` URL and release asset URL.
- [ ] If a tag push is deduplicated, run the workflow manually with `workflow_dispatch` and `release_tag=v1.0.0`.
- [ ] Pin the compatibility matrix or an “install first” issue/discussion.
- [ ] Check that the old-module migration and rollback instructions are visible.

## Trust signals

- Source and binary have the same version and checksum.
- The tested device, kernel, and profile are stated explicitly.
- The binary is not advertised as universal.
- Safety limits, trip behavior, and rollback are documented.
- Issue forms ask for kernel/status/log evidence.
- Security reports go through GitHub Security Advisories.

## Launch channels

Use a short, factual post. Always include the exact kernel limitation and a
link to the safety guide.

| Channel | Angle |
|---|---|
| GitHub release | “Open-source replacement for the abandoned module; tested on pearl.” |
| Coolapk / 酷安 | Chinese install and migration walkthrough; screenshots and status table. |
| Xiaomi community | Redmi Note 12T Pro specific; link to compatibility matrix. |
| XDA / r/Magisk / r/AndroidRoot | Technical source, build reproducibility, safety model. |
| Telegram Magisk/MediaTek groups | Short demo and link; answer compatibility questions. |
| Smart Power users | Integration patch, `power.conf` keys, tested profile. |

Avoid mass-posting identical text. Disclose that the published `.ko` is for one
kernel. Do not imply that it bypasses root detection, verified boot, or Play
Integrity.

## Suggested release note

```text
v1.0.0 — first open-source release
- MediaTek cpufreq_v1 source from the Xiaomi pearl kernel tree
- kernel-locked cpuhvfs.ko for 5.10.136-pearl-cve43499
- driver-only default, namespaced state, reboot trip latch
- Smart Power managed-mode integration
- tested profile: -5 -8 -9 0 (measured -31.25/-50/-56.25/0 mV)
- source, config, vendor-symbol CRCs, and build guide included
```

## After launch

- Keep an “installation / compatibility” discussion pinned.
- Label issues by `install`, `kernel`, `smart-power`, `safety`, and `docs`.
- Ask every device report for `uname -r`, status output, and dmesg.
- Never mark a profile verified from a single anecdotal report.
- Publish a small release cadence rather than frequent unsafe binaries.
- Track downloads and issue quality, not only stars.
