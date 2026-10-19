# Third-party notices

## MediaTek cpufreq debug driver

`src/cpufreq-dbg.c`, `src/eem-dbg.c`, `src/eem-dbg-v1.h`, and
`src/mtk_cpu_dbg.h` are from the MediaTek `cpufreq_v1` driver included in the
Xiaomi `pearl-s-oss` kernel source tree.

Original copyright:

```text
Copyright (c) 2020 MediaTek Inc.
Chienwei Chang <chienwei.chang@mediatek.com>
```

The source files retain their SPDX GPL-2.0 headers. They are distributed
under GPL-2.0; see `LICENSE`.

## Xiaomi kernel source

Kernel source and configuration information:

```text
MiCode/Xiaomi_Kernel_OpenSource
branch: pearl-s-oss
commit: d96c1a04b701bcf1d39ed1b8ab4b3137ff6490f9
```

The kernel image, vendor modules, and device firmware are not part of this
repository.

## Reference

The public `Seyud/cpuhvfs` repository was used only as a cross-check for
historical reverse-engineering. The driver in this repository is built from
the MediaTek source in the Xiaomi kernel tree, not from that binary. If you
reuse anything from that project, preserve its attribution and license terms.
