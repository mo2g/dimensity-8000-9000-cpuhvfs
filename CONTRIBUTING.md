# Contributing

Thank you for helping make Dimensity undervolting safer and easier to audit.

By participating, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Before opening an issue

Collect:

```sh
uname -r
getprop ro.product.device
getprop ro.build.version.release
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl probe'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl status'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh status' 2>/dev/null || true
su -c 'dmesg' | grep -iE 'cpuhvfs|eem|unknown symbol|disagrees|verification'
```

Do not attach proprietary boot images, vendor firmware, or personal data.

## Pull requests

- Keep scripts POSIX `sh` and Android toybox compatible. Do not introduce
  Bash-only arrays or `local` in module scripts.
- Keep all persistent state under `/data/adb/<module-id>/`.
- Do not bypass `vermagic`, vendor-symbol CRC, or conflict checks.
- Do not add a prebuilt `.ko` without its source, build config, and license
  provenance.
- Update `CHANGELOG.md` and relevant docs.
- Add a test note describing the device, kernel, and observations.

## Build and package checks

```sh
for f in bin/lib.sh bin/cpuhvfs-ctl customize.sh post-fs-data.sh service.sh uninstall.sh action.sh; do
  sh -n "$f"
done
bash -n scripts/build-ko.sh scripts/package.sh
./scripts/package.sh
```

For a kernel build, follow [docs/BUILD.md](docs/BUILD.md) and record the exact
`modinfo` and `modprobe --dump-modversions` output.

## Safety policy

A profile that causes a reboot, kernel warning, or boot loop must not be marked
verified or shipped as a default. The default must remain driver-only.
