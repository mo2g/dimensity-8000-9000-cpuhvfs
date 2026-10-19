# 免重启切换：旧 cpuhvfs → 新模块

适用条件（全部满足才可操作）：

- 旧 `dimensity_8100_9000_cpuhvfs` 已存在 `disable`，或你能先安全地停止它；
- `lsmod` 中没有 `cpuhvfs`；
- `/proc/eem/eem_offset` 不存在；
- 新模块 `.ko` 的 `vermagic` 与当前内核完全一致；
- 已备份 `boot`、Smart Power 的 `uv.sh`、`power.conf` 和 `uv/settings`。

## 1. 停旧模块但不重启

```sh
su -c 'touch /data/adb/modules/dimensity_8100_9000_cpuhvfs/disable'
su -c 'lsmod | grep ^cpuhvfs || true'
su -c 'ls -l /proc/eem/eem_offset 2>/dev/null || true'
```

如果旧 `cpuhvfs` 已经加载，先通过 Smart Power 或脚本把所有偏移写回 0，再执行
`rmmod cpuhvfs`。**不能在旧驱动仍加载时直接加载新驱动。**

## 2. 安装新模块并就地激活

Magisk 30.x 的 `--install-module` 会先放到
`/data/adb/modules_update/<id>`。当前系统没有重启时，可以确认旧驱动未加载后
把它提升为正式模块目录：

```sh
su -c 'magisk --install-module /data/local/tmp/dimensity-8000-9000-cpuhvfs-v1.0.0.zip'
su -c 'ls -la /data/adb/modules_update/dimensity-8000-9000-cpuhvfs'
```

确认安装目录完整且没有 `disable` 后：

```sh
su -c 'rm -f /data/adb/modules/dimensity-8000-9000-cpuhvfs/module.prop \
  /data/adb/modules/dimensity-8000-9000-cpuhvfs/update'
su -c 'rmdir /data/adb/modules/dimensity-8000-9000-cpuhvfs'
su -c 'mv /data/adb/modules_update/dimensity-8000-9000-cpuhvfs \
  /data/adb/modules/dimensity-8000-9000-cpuhvfs'
su -c 'rmdir /data/adb/modules_update 2>/dev/null || true'
```

这是 Magisk 的目录布局，不是内核操作；执行前必须先确认
`/data/adb/modules_update/<id>` 是本次安装的模块，避免移动错误的更新。

## 3. 只加载新驱动，不加压

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl probe'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl load'
```

成功标志：

```text
ko_match=1
cpuhvfs_loaded=1
eem_present=1
```

此时还没有写入任何电压偏移。

## 4. 用 Smart Power 应用已测试配置

Smart Power 需要读取本模块 ID 和 `.ko` 路径。使用
`patches/smart-power-uv.patch`，并在 `/data/adb/smart-power/power.conf` 加入：

```ini
uv_module_id=dimensity-8000-9000-cpuhvfs
uv_ko_path=/data/adb/modules/dimensity-8000-9000-cpuhvfs/lib/cpuhvfs.ko
uv_keep_module_enabled=1
```

`uv_keep_module_enabled=1` 很关键：Smart Power 的 managed 模式通常会把被管理的
模块写成 `disable`；本模块的 service 只加载驱动、不自动写偏移，因此可以保持
Magisk 模块启用，由 Smart Power 负责实际偏移和熔断。

应用已验证的 `-5 -8 -9 0`：

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh apply 0'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh persist on'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh status'
```

`persist on` 只影响下一次开机；当前偏移由 `apply` 立即生效。观察期内不要主动
重启，否则 Smart Power 会熔断并移除永久配置。

## 5. 回滚

```sh
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh rollback'
su -c 'sh /data/adb/modules/smart_power/bin/uv.sh persist off'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl unload'
```

如果需要回到旧模块，先从备份恢复 Smart Power 的 `uv.sh` 和 `power.conf`，
再移除旧模块的 `disable`；旧模块的自动加载要等到下一次开机或手动执行其
`service.sh`。
