# dimensity-8000-9000-cpuhvfs

天玑 8000/9000（MT6895/MT6896）的 **开源 cpuhvfs 驱动 + Magisk 模块**，用于替代已停止维护、闭源的「天玑8000/9000降压」v2.0.1。

> 这是实验性内核模块。默认只加载驱动，**不会自动写入任何降压值**。必须使用与手机内核完全匹配的 `.ko`；内核不匹配时安装器会拒绝继续。

## 先回答：`/data/adb/cpuhvfs/state` 会冲突吗？

会。`/data/adb/cpuhvfs` 是全局目录，不绑定 Magisk 模块 ID；任何后来使用同名路径的模块（或旧版脚本）都会和它争用同一份 `state`/`config`，最后写入者覆盖前一个。

本模块已经改成：

```text
/data/adb/dimensity-8000-9000-cpuhvfs/state
/data/adb/dimensity-8000-9000-cpuhvfs/trip
/data/adb/dimensity-8000-9000-cpuhvfs/module.log
```

但内核侧仍然有全局命名，无法靠改目录解决：

- 内核模块名固定为 `cpuhvfs`；
- 调试接口是全局的 `/proc/eem/eem_offset`；
- 旧的 `dimensity_8100_9000_cpuhvfs` 模块如果仍然启用或驱动仍然加载，会和本模块冲突。

因此安装器会检查旧模块和 `/proc/eem`，发现冲突就中止。**目录命名空间和内核命名空间要分开理解。**

## 模块特性

- 源码来自小米公开的 `pearl-s-oss` 内核树中的 MediaTek `cpufreq_v1` 驱动（GPL-2.0）。
- 针对本机内核 `5.10.136-pearl-cve43499` 构建；`vermagic` 必须精确匹配。
- `cpuhvfs-ctl` 提供机器可读的 `probe/load/apply/restore/status`。
- 默认 `max_abs_steps=6`（约 `-37.5 mV`），只允许 `0` 或负偏移。
- `apply` 前先做内核、依赖、旧模块、`/proc/eem` 冲突检查；写入按簇逐个进行，失败会尝试清零。
- 写入前设置 `armed` 和本次 `boot_id`。如果观察期内重启，`post-fs-data.sh` 会触发熔断，禁止下次自动加载。
- 支持独立的 `power.conf` 或环境变量接入 Smart Power。

## 兼容性

当前随仓库提供的 `lib/cpuhvfs.ko` 只适用于：

```text
设备: Redmi Note 12T Pro (pearl)
内核: 5.10.136-pearl-cve43499
构建源: MiCode/Xiaomi_Kernel_OpenSource pearl-s-oss @ d96c1a04
```

其他内核、其他 ROM、或其他 MTK 机型必须按 [docs/BUILD.md](docs/BUILD.md) 重新编译，不能直接复用这个二进制。

## 安装

前置条件：

1. Magisk 已正常工作；
2. 手机当前内核与 `lib/cpuhvfs.ko` 的 `vermagic` 完全一致；
3. 旧降压模块已禁用并重启，确认 `/proc/eem/eem_offset` 不存在；
4. 已备份 `boot` 分区，知道如何回滚（刷内核模块本身不改 boot，但设备实验前仍应备份）。

安装后默认不降压：

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl status'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl probe'
```

手动应用一个保守配置（四簇依次为 little, middle, big, cci）：

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl apply -3 -3 -3 0'
```

恢复：

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl restore'
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl unload'
```

如果出现 `trip=reboot_during_observation`，先确认设备稳定，再执行：

```sh
su -c '/data/adb/modules/dimensity-8000-9000-cpuhvfs/bin/cpuhvfs-ctl reset-trip'
```

## 与 Smart Power 集成

Smart Power 当前版本把旧模块路径写死为 `dimensity_8100_9000_cpuhvfs`。本模块选择了独立模块 ID，所以需要在 Smart Power 的 `uv.sh` 中增加配置读取：

```sh
SP_UV_MOD_ID="${SP_UV_MOD_ID:-$(sp_get uv_module_id)}"
SP_UV_MOD_ID="${SP_UV_MOD_ID:-dimensity_8000_9000_cpuhvfs}"
SP_UV_MOD_DIR="${SP_UV_MOD_DIR:-/data/adb/modules/$SP_UV_MOD_ID}"
SP_UV_KO="${SP_UV_KO:-$(sp_get uv_ko_path)}"
SP_UV_KO="${SP_UV_KO:-$SP_UV_MOD_DIR/lib/cpuhvfs.ko}"
```

并在 `/data/adb/smart-power/config/power.conf` 写入：

```ini
uv_module_id=dimensity-8000-9000-cpuhvfs
uv_ko_path=/data/adb/modules/dimensity-8000-9000-cpuhvfs/lib/cpuhvfs.ko
```

完整契约、退出码和状态字段见 [docs/INTEGRATION.md](docs/INTEGRATION.md)。环境变量 `SP_UV_MOD_ID`、`SP_UV_KO` 仍然优先，便于测试。

## 安全说明

- 降压会改变 CPU 供电，错误配置可能导致死机、数据损坏或无法开机。先备份，先保守，先观察。
- 本模块不会自动把配置设为开机配置；重启后驱动最多被加载，偏移不会自动恢复。
- 内核模块和 `/proc/eem` 是全局资源，不能同时运行两个 `cpuhvfs`。
- 不要用 `allow_mismatch` 强行加载不同内核的 `.ko`；本模块的 `probe/load` 会拒绝不匹配。

## 构建

```sh
KERNEL_SRC=/path/to/pearl-s-oss \
KERNEL_OUT=/path/to/kernel/out \
CLANG_DIR=/path/to/llvm/bin \
./scripts/build-ko.sh --copy
```

详细的内核源码、`Module.symvers`、vendor 符号 CRC、LLVM 工具链说明见 [docs/BUILD.md](docs/BUILD.md)。

## 目录

```text
bin/cpuhvfs-ctl      命令行和安全检查
bin/lib.sh           路径、状态、写入辅助
lib/cpuhvfs.ko       本机内核预编译产物
src/                 MediaTek cpufreq_v1 源码（GPL-2.0）
etc/limits.conf      安全上限和观察时间
configs/             设备内核配置和 vendor 符号 CRC
docs/                集成、构建、安全文档
```

## 许可与归属

驱动源码来自 MediaTek，原始版权归 MediaTek Inc. 和 Chienwei Chang；内核树来自 Xiaomi `pearl-s-oss`。本仓库按 GPL-2.0 分发，详见 [LICENSE](LICENSE) 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

不提供任何明示或暗示担保。使用风险由设备所有者承担。
