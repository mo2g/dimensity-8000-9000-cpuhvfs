# Building `cpuhvfs.ko`

The shipped binary was built from the public Xiaomi pearl source, not from a
reverse-engineered replacement:

```text
repo:   MiCode/Xiaomi_Kernel_OpenSource
branch: pearl-s-oss
commit: d96c1a04b701bcf1d39ed1b8ab4b3137ff6490f9
kernel: 5.10.136
local:  -pearl-cve43499
toolchain: AOSP clang 12 / LLVM 12 (the device kernel's toolchain family)
```

The source directory is extracted from
`pearl-s-oss-d96c1a04.tar.gz`:

```text
drivers/misc/mediatek/cpufreq_v1/
```

## Why an ordinary external-module build is not enough

The device kernel was built with `CONFIG_MODVERSIONS` and vendor modules.
`Module.symvers` from the kernel image contains vmlinux exports, but these
three symbols are exported by vendor modules, not vmlinux:

```text
get_mcupm_ipidev       from mcupm.ko
mtk_ipi_register       from mtk_tinysys_ipi.ko
mtk_ipi_send_compl     from mtk_tinysys_ipi.ko
```

Their CRCs must match the `mcupm.ko` / `mtk_tinysys_ipi.ko` already on the
device. For the tested device they are:

```text
0x73e08ef8  get_mcupm_ipidev   mcupm           EXPORT_SYMBOL_GPL
0xa183ffc0  mtk_ipi_register   mtk_tinysys_ipi EXPORT_SYMBOL
0xb2ebd287  mtk_ipi_send_compl mtk_tinysys_ipi EXPORT_SYMBOL
```

They are stored in `configs/pearl-vendor-symbols.symvers`. The file format
requires tabs and a fifth (namespace) field, even when it is empty.

If your vendor module changes, regenerate the CRC values:

```sh
nm -a /path/to/mcupm.ko | grep __crc_get_mcupm_ipidev
nm -a /path/to/mtk_tinysys_ipi.ko | grep __crc_mtk_ipi_register
nm -a /path/to/mtk_tinysys_ipi.ko | grep __crc_mtk_ipi_send_compl
```

## Build

You need the kernel source and the exact output directory used to build the
running kernel. The output must contain `.config`, `Module.symvers`, and
`include/config/kernel.release`.

```sh
KERNEL_SRC=/path/to/pearl-s-oss \
KERNEL_OUT=/path/to/kernel/out \
CLANG_DIR=/usr/lib/llvm-12/bin \
./scripts/build-ko.sh --copy
```

The script temporarily copies `src/` to
`drivers/misc/mediatek/cpuhvfs-build` so the original `../mcupm/include`
relative includes resolve correctly. It then runs:

```sh
make -C "$KERNEL_SRC" O="$KERNEL_OUT" \
  M=drivers/misc/mediatek/cpuhvfs-build \
  ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  CONFIG_MEDIATEK_CPUFREQ_DEBUG=m \
  CONFIG_MTK_TINYSYS_MCUPM_SUPPORT=m \
  CONFIG_MTK_IPI=m \
  KBUILD_EXTRA_SYMBOLS=configs/pearl-vendor-symbols.symvers \
  modules
```

The command-line `CONFIG_*` overrides are required because the production
device config leaves those debug options disabled. They only affect this
external module build; they do not modify the kernel `.config`.

## Verify before loading

```sh
modinfo -F vermagic lib/cpuhvfs.ko
modprobe --dump-modversions lib/cpuhvfs.ko |
  grep -E 'module_layout|get_mcupm_ipidev|mtk_ipi_(register|send_compl)'
```

Expected vermagic for the shipped binary:

```text
5.10.136-pearl-cve43499
```

Expected CRCs:

```text
0x7c24b32d  module_layout
0x73e08ef8  get_mcupm_ipidev
0xa183ffc0  mtk_ipi_register
0xb2ebd287  mtk_ipi_send_compl
```

Do not load a module whose `vermagic`, `module_layout`, or vendor CRCs differ.
A module can compile successfully and still be rejected or crash at load time.

## Rebuilding for another kernel

The source is portable only within the matching MediaTek kernel family. You
must rebuild against the other kernel's `Module.symvers`, config, toolchain,
and vendor modules. Do not publish a single `.ko` as universal for all
Dimensity 8000/9000 phones.
