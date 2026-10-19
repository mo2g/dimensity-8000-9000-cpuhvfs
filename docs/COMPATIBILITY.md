# Compatibility and support matrix

## Published binary

`lib/cpuhvfs.ko` is intentionally kernel-locked:

```text
Device:        Redmi Note 12T Pro (pearl)
SoC:           MediaTek Dimensity 8200-Ultra (MT6895)
Kernel:        5.10.136-pearl-cve43499
Kernel source: MiCode/Xiaomi_Kernel_OpenSource pearl-s-oss @ d96c1a04
Toolchain:     AOSP clang 12 / LLVM 12 family
```

`cpuhvfs-ctl probe` returns `ko_match=0` and exit code 2 for every other
`uname -r`. The Magisk installer aborts before installing a mismatched binary.

## Verified environment

| Item | Value |
|---|---|
| ROM | MIUI 14 V14.0.5.0.TLHCNXM |
| Android | 13 |
| Magisk | 30.6 |
| Kernel | 5.10.136-pearl-cve43499 |
| Smart Power | managed mode, tested profile `-5 -8 -9 0` |
| Observation | 600 s, passed, `uv_state=stable` |

The tested profile is:

```text
little=-5  middle=-8  big=-9  cci=0
```

Measured firmware offsets were approximately:

```text
-31.25 mV / -50.00 mV / -56.25 mV / 0.00 mV
```

## What is not claimed

- It is not a universal Dimensity 8000/9000 binary.
- It is not tested on HyperOS, MIUI 15, other regions, other kernels, or other
  OEM boot images.
- It does not bypass Android verified boot, SELinux, Play Integrity, or root
  detection in apps.
- It does not include any boot image or firmware.

## Rebuild requirements

To add support for another kernel, you need:

1. The matching kernel source tree and commit.
2. The exact `.config` and `Module.symvers` from that kernel build.
3. The vendor `mcupm.ko` and `mtk_tinysys_ipi.ko` CRC values.
4. The same LLVM/LTO/CFI configuration and `LOCALVERSION`.
5. A boot backup and a recovery path.

See [BUILD.md](BUILD.md).

## Reporting compatibility

Open a bug report with:

```text
Device / ROM / Android:
uname -r:
Magisk version:
cpuhvfs-ctl probe:
cpuhvfs-ctl status:
uv.sh status (if Smart Power):
dmesg | grep -iE 'cpuhvfs|eem|unknown symbol|disagrees|verification'
```

Do not attach proprietary firmware, boot images, or personal data.
