# Win_SOME 工具使用说明

Win_SOME 是 SOEM (Simple Open EtherCAT Master) 在 Windows 平台的移植版本。  
编译环境: MinGW-w64 gcc 14.2.0, 依赖 WinPcap/NPcap 驱动。

---

## 目录

1. [simple_test](#1-simple_test) — 基本 EtherCAT 通信测试
2. [slaveinfo](#2-slaveinfo) — 从站信息查看
3. [eepromtool](#3-eepromtool) — 从站 EEPROM 读写
4. [firm_update](#4-firm_update) — 从站固件升级 (FoE)
5. [ebox / red_test (Linux only)](#5-ebox--red_test-linux-only)
6. [统一编译方法](#6-统一编译方法)

---

## 1. simple_test

**文件:** `simple_test.exe`  
**源码:** `test/simple_test/simple_test.c`

### 功能

最基本的 EtherCAT 通信测试。初始化主站、扫描从站、自动配置 PDO 映射、进入 OP 状态、循环收发过程数据。

### 用法

```bash
# 查看可用网卡（不带参数运行）
./simple_test.exe

# 连接到指定网卡并运行测试
./simple_test.exe "\\Device\\NPF_{GUID}"
```

### 输出示例

```
SOEM (Simple Open EtherCAT Master)
Simple test
Starting simple test
ec_init on \Device\NPF_{...} succeeded.
1 slaves found and configured.
Slaves mapped, state to SAFE_OP.
Operational state reached for all slaves.
Processdata cycle 4, WKC 3, O: 04 00 I: 07 00 T:11685360
  ... (500个周期) ...
End simple test, close socket
End program
```

### 说明

- 运行 500 个周期 (每个周期 50ms)，共约 25s
- 输出格式: `Processdata cycle <序号>, WKC <工作计数器>, O: <输出十六进制> I: <输入十六进制> T: <DC时间戳>`
- 内置 Beckhoff EL7031 和 Copley AEP 从站的自动识别与初始化
- 通过 Windows 多媒体定时器 (`timeSetEvent`) 实现 1ms 周期的实时线程
- 独立的错误监控线程自动检测从站丢失并尝试恢复

---

## 2. slaveinfo

**文件:** `slaveinfo.exe`  
**源码:** `test/slaveinfo/slaveinfo.c`

### 功能

枚举 EtherCAT 总线上的所有从站，显示详细配置信息和状态。可选查看 CoE 对象字典和 PDO 映射。

### 用法

```bash
# 查看可用网卡
./slaveinfo.exe

# 显示所有从站基本信息
./slaveinfo.exe "\\Device\\NPF_{GUID}"

# 显示从站信息 + CoE 对象字典（SDO 内容）
./slaveinfo.exe "\\Device\\NPF_{GUID}" -sdo

# 显示从站信息 + PDO 映射详情
./slaveinfo.exe "\\Device\\NPF_{GUID}" -map
```

### 输出内容说明

每个从站显示的信息包括:

| 字段 | 说明 |
|------|------|
| Name | 从站名称 (从 SII 读取) |
| Output size | 输出数据大小 (bits) |
| Input size | 输入数据大小 (bits) |
| State | 当前状态 (0=INIT, 1=PREOP, 2=BOOT, 4=SAFEOP, 8=OP) |
| Delay | 传播延迟 (ns) |
| Has DC | 是否支持分布式时钟 |
| Active ports | 活动端口状态 |
| Man / ID / Rev | 制造商 ID / 产品代码 / 版本号 |
| SM0-3 | SyncManager 配置 (地址、长度、标志、类型) |
| FMMU | FMMU 通道配置 |
| CoE/FoE/EoE/SoE | 支持的协议细节 |
| Ebus current | 总线电流消耗 (mA) |

### `-sdo` 模式

遍历并打印从站 CoE 对象字典中的所有对象及其子索引，包括数据类型、位长度、访问属性和当前值。

### `-map` 模式

从 CoE (如果支持) 或 SII 中读取 PDO 映射信息，显示每个 PDO 的地址偏移、位位置、对象索引和数据类型。

---

## 3. eepromtool

**文件:** `eepromtool.exe`  
**源码:** `test/eepromtool/eepromtool.c`

### 功能

读取或写入 EtherCAT 从站的 EEPROM (SII 配置存储器)。

### 用法

```bash
# 查看用法
./eepromtool.exe

# 读取从站 EEPROM，输出二进制文件
./eepromtool.exe "\\Device\\NPF_{GUID}" <slave> -r <输出文件.bin>

# 读取从站 EEPROM，输出 Intel Hex 格式
./eepromtool.exe "\\Device\\NPF_{GUID}" <slave> -ri <输出文件.hex>

# 写入从站 EEPROM，输入二进制文件
./eepromtool.exe "\\Device\\NPF_{GUID}" <slave> -w <输入文件.bin>

# 写入从站 EEPROM，输入 Intel Hex 格式
./eepromtool.exe "\\Device\\NPF_{GUID}" <slave> -wi <输入文件.hex>
```

### 参数

| 参数 | 说明 |
|------|------|
| ifname | 网卡名称，e.g. `\Device\NPF_{GUID}` |
| slave | 从站编号，1..n (按 EtherCAT 总线顺序) |
| `-r`  | 读取 EEPROM，保存为原始二进制格式 |
| `-ri` | 读取 EEPROM，保存为 Intel Hex 格式 |
| `-w`  | 写入 EEPROM，输入为原始二进制格式 |
| `-wi` | 写入 EEPROM，输入为 Intel Hex 格式 |

### 输出示例

```
SOEM (Simple Open EtherCAT Master)
EEPROM tool
ec_init on \Device\NPF_{...} succeeded.
2 slaves found.
Slave 1 data
 PDI Control      : 0000
 PDI Config       : 0000
 Config Alias     : 0000
 Checksum         : 0123
 Vendor ID        : 00000002
 Product Code     : 07D43052
 Revision Number  : 00100000
 Serial Number    : 00000000
 Mailbox Protocol : 0000
 Size             : 003E = 62*128 = 7936 bytes
 Version          : 0001

Total EEPROM read time : 1234ms
End, close socket
End program
```

### 读取解析信息

读取时会自动解析前 128 字节头信息:
- **PDI Control** — 物理设备接口控制
- **PDI Config** — PDI 配置
- **Config Alias** — 配置别名地址
- **Checksum** — EEPROM 校验和
- **Vendor ID** — 制造商 ID
- **Product Code** — 产品代码
- **Revision Number** — 版本号
- **Serial Number** — 序列号
- **Mailbox Protocol** — 邮箱协议支持
- **Size** — EEPROM 总大小
- **Version** — SII 版本

### 写入说明

- 支持写入二进制或 Intel Hex 格式
- 写入前会验证 Vendor ID / Product Code / Revision 信息
- 写入过程中会显示 `.` 表示进度 (每 100 字写入)
- **注意：错误的 EEPROM 写入可能导致从站无法正常工作！**

> **EEPROM 写入时序:** 工具会先将 EEPROM 控制权从 PDI (从站微处理器) 切换到主站，写入完成后保持主站控制状态。如果从站重新上电，会自动恢复到 PDI 控制。

---

## 4. firm_update

**文件:** `firm_update.exe`  
**源码:** `test/firm_update/firm_update.c`

### 功能

通过 FoE (File over EtherCAT) 协议升级从站固件。支持 Beckhoff 等支持 FoE 的从站。

### 用法

```bash
# 查看用法
./firm_update.exe

# 升级从站固件
./firm_update.exe "\\Device\\NPF_{GUID}" <slave> <固件文件.bin>
```

### 参数

| 参数 | 说明 |
|------|------|
| ifname | 网卡名称 |
| slave | 从站编号，1..n |
| fname | 固件二进制文件路径 (最大 8MB) |

### 流程说明

该工具执行以下步骤:

1. **初始化 SOEM** — 连接网卡
2. **扫描从站** — 检测总线上的所有从站
3. **设置 INIT 状态** — 将目标从站切换到 INIT
4. **读取 BOOT 邮箱配置** — 从 SII 中读取启动邮箱 (SM0/SM1) 地址和大小
5. **配置 SyncManager** — 编程 SM0 (主→从) 和 SM1 (从→主) 邮箱
6. **请求 BOOT 状态** — 将从站切换到 BOOT 状态
7. **读取固件文件** — 从本地读取 .bin 文件
8. **FoE 写入** — 通过 `ec_FOEwrite()` 将固件发送到从站
9. **恢复 INIT** — 写入完成后将从站恢复到 INIT 状态

### 输出示例

```
SOEM (Simple Open EtherCAT Master)
Firmware update example
ec_init on \Device\NPF_{...} succeeded.
1 slaves found and configured.
Request init state for slave 1
Slave 1 state to INIT.
 SM0 A:1000 L:128 F:00000000
 SM1 A:1080 L:128 F:00000000
Request BOOT state for slave 1
Slave 1 state to BOOT.
File read OK, 123456 bytes.
FoE write....result 1.
Request init state for slave 1
End firmware update example, close socket
End program
```

### 注意事项

- **仅支持支持 FoE 的从站** (Beckhoff 等)
- **固件文件错误可能导致从站变砖！** 请确保使用正确的固件文件
- 固件缓冲区最大 8MB
- 写入过程中从站会通过状态机自动切换到 BOOT 模式以接收固件
- 完成后从站回到 INIT 状态，需重新配置并切换到 OP 才能正常运行

---

## 5. ebox / red_test (Linux Only)

### ebox

**源码:** `test/ebox/ebox.c`

专为 Beckhoff E/BOX 远程 I/O 设计的测试程序。支持高速流模式数据采集 (最高 125kHz)，包含 DC 时钟同步。

**Linux 依赖:** pthread, sched.h (SCHED_FIFO 实时调度)

### red_test

**源码:** `test/red_test/red_test.c`

双网卡冗余测试。使用 `ec_init_redundant()` 初始化两张网卡，当主链路故障时自动切换。

**Linux 依赖:** pthread, sched.h (SCHED_FIFO 实时调度)

### Windows 移植说明

这两个程序使用了 Linux 特有的 API:
- `pthread.h` — POSIX 线程 (pthread_create, pthread_cond_timedwait)
- `sched.h` — 实时调度策略 (sched_setscheduler, SCHED_FIFO)

如果需要移植到 Windows:
1. 安装 pthread-w32 库，将 pthread API 映射到 Windows 线程
2. `sched_setscheduler()` 无直接对应，需替换为 `SetThreadPriority()`
3. `pthread_cond_timedwait()` 可替换为 `WaitForSingleObject()` + 高分辨率定时器
4. `gettimeofday()` / `usleep()` 在 MinGW 中已有实现

---

## 6. 统一编译方法

### 一键编译脚本

`build_all.sh` 脚本位于项目根目录，可一键编译所有 Windows 兼容的工具:

```bash
cd /c/Users/Yharim/Desktop/workspace/win_ethercat/Win_SOME
./build_all.sh
```

### 手动编译命令

```bash
SRC="soem/ethercatbase.c soem/ethercatcoe.c soem/ethercatconfig.c \
    soem/ethercatdc.c soem/ethercatfoe.c soem/ethercatmain.c \
    soem/ethercatprint.c soem/ethercatsoe.c \
    osal/win32/osal.c oshw/win32/nicdrv.c oshw/win32/oshw.c"

INC="-Isoem -Iosal -Ioshw/win32 -Ioshw/win32/wpcap/Include -idirafter osal/win32"
LIB="-lws2_32 -lwinmm -lwpcap -lpacket -Loshw/win32/wpcap/Lib/x64"

# 编译 simple_test
gcc $INC $SRC test/simple_test/simple_test.c -o simple_test.exe -O2 -Wall $LIB

# 编译 slaveinfo
gcc $INC $SRC test/slaveinfo/slaveinfo.c -o slaveinfo.exe -O2 -Wall $LIB

# 编译 eepromtool (含 timersub 补丁)
gcc $INC $SRC test/eepromtool/eepromtool.c -o eepromtool.exe -O2 -Wall $LIB

# 编译 firm_update
gcc $INC $SRC test/firm_update/firm_update.c -o firm_update.exe -O2 -Wall $LIB
```

### 编译要点

| 要点 | 说明 |
|------|------|
| `-idirafter` | 必须用 `-idirafter` 而非 `-I` 引用 `osal/win32/`，避免 MinGW 的 `<stdint.h>` 被 MSVC 专用版本覆盖 |
| WinPcap 库 | 如果 `oshw/win32/wpcap/Lib/x64/` 下的 `.a` 文件不兼容，需重新生成 |
| NPcap | 如果使用 NPcap，需使用 `\Device\NPF_{GUID}` 格式的网卡名称 |

### WinPcap 导入库重新生成方法

```bash
gendef /c/Windows/System32/wpcap.dll   # → wpcap.def
dlltool -d wpcap.def -l libwpcap.a -m i386:x86-64

gendef /c/Windows/System32/Packet.dll  # → Packet.def
dlltool -d Packet.def -l libpacket.a -m i386:x86-64
```
