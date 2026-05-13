# Win_SOME — SOEM Windows 构建笔记

## 环境

- **OS:** Windows 10 Pro for Workstations (x64)
- **编译器:** MinGW-w64 gcc 14.2.0 (x86_64)
- **网卡:** Realtek PCIe GbE Family Controller
- **NPcap:**  已安装，NPF 驱动已加载
- **SOEM 版本:** Source-based (早期版本，含 ethercatbase/coe/config/dc/foe/main/print/soe)

## 目录结构

```
Win_SOME/
├── soem/           # SOEM 核心源码
│   ├── ethercatbase.c/h
│   ├── ethercatcoe.c/h
│   ├── ethercatconfig.c/h
│   ├── ethercatconfiglist.h
│   ├── ethercatdc.c/h
│   ├── ethercatfoe.c/h
│   ├── ethercatmain.c/h
│   ├── ethercatprint.c/h
│   ├── ethercatsoe.c/h
│   ├── ethercattype.h
│   └── Makefile
├── osal/           # 操作系统抽象层
│   ├── osal.h
│   └── win32/
│       ├── osal.c
│       ├── osal_win32.h
│       ├── stdint.h      (MSVC only)
│       └── inttypes.h    (MSVC only)
├── oshw/           # 硬件抽象层 (WinPcap)
│   └── win32/
│       ├── nicdrv.c/h
│       ├── oshw.c/h
│       └── wpcap/
│           ├── Include/  (WinPcap headers)
│           └── Lib/
│               ├── libwpcap.a, libpacket.a       (32-bit)
│               └── x64/
│                   ├── wpcap.lib, Packet.lib      (MSVC)
│                   ├── libwpcap.a, libpacket.a    (MinGW, by gendef+dlltool)
│                   └── wpcap.def                  (by gendef)
├── test/
│   ├── simple_test/simple_test.c
│   ├── slaveinfo/slaveinfo.c
│   ├── eepromtool/eepromtool.c
│   └── ...
├── doc/html/       # Doxygen 文档
├── simple_test.exe (已编译)
├── slaveinfo.exe   (已编译)
└── BUILD.md        (本文件)
```

## 编译方法

### 使用 gcc (MinGW)

```bash
cd /c/Users/Yharim/Desktop/workspace/win_ethercat/Win_SOME

gcc \
  -Isoem -Iosal -Ioshw/win32 -Ioshw/win32/wpcap/Include \
  -idirafter osal/win32 \
  soem/ethercatbase.c soem/ethercatcoe.c soem/ethercatconfig.c \
  soem/ethercatdc.c soem/ethercatfoe.c soem/ethercatmain.c \
  soem/ethercatprint.c soem/ethercatsoe.c \
  osal/win32/osal.c \
  oshw/win32/nicdrv.c oshw/win32/oshw.c \
  test/simple_test/simple_test.c \
  -o simple_test.exe \
  -O2 -Wall \
  -lws2_32 -lwinmm \
  -lwpcap -lpacket \
  -Loshw/win32/wpcap/Lib/x64
```

### 关键点

1. **`-idirafter osal/win32`** — 必须用 `-idirafter` 而非 `-I`，否则 `<stdint.h>` 会解析到 `osal/win32/stdint.h`（MSVC 专用），而不是系统的 stdint.h
2. **WinPcap 导入库** — 原项目带的 `.lib/.a` 是 32-bit 或 MSVC COFF 格式，MinGW x64 不兼容。需要用 `gendef` + `dlltool` 从系统 `wpcap.dll` / `Packet.dll` 重新生成：

   ```bash
   gendef /c/Windows/System32/wpcap.dll   # → wpcap.def
   dlltool -d wpcap.def -l libwpcap.a -m i386:x86-64

   gendef /c/Windows/System32/Packet.dll  # → Packet.def
   dlltool -d Packet.def -l libpacket.a -m i386:x86-64
   ```

3. **链接库:** `-lws2_32 -lwinmm -lwpcap -lpacket`

## MinGW 兼容性修改

| 文件 | 修改 | 原因 |
|------|------|------|
| `osal/win32/osal_win32.h` | 添加 `#include <sys/time.h>` | MinGW 在此头文件中定义 `struct timezone` |
| `osal/osal.h` | `osal_timer_is_expired` 参数加 `const` | 声明与实现（osal.c）的 const 限定符不匹配 |

## 运行结果

```text
SOEM (Simple Open EtherCAT Master)
Simple test
Starting simple test
ec_init on \Device\NPF_{...} succeeded.
1 slaves found and configured.
Slaves mapped, state to SAFE_OP.
Operational state reached for all slaves.
Processdata cycle 4, WKC 3, O: 04 00 I: 07 00 T:11685360
  ... (25000+ cycles) ...
End simple test, close socket
End program
```

- 成功发现 1 个 EtherCAT 从站
- 从站正常进入 OP 状态，WKC = 3 保持稳定
- 实时周期任务正常运行，IO 数据可读写

## 可用工具

| 工具 | 命令 | 说明 |
|------|------|------|
| simple_test | `./simple_test.exe "\Device\NPF_{GUID}"` | 基本 EtherCAT 通信测试 |
| slaveinfo | `./slaveinfo.exe "\Device\NPF_{GUID}" [-sdo] [-map]` | 从站信息查看 (可选 SDO/映射) |
| eepromtool | `./eepromtool.exe "\Device\NPF_{GUID}" <slave> <option> <file>` | 从站 EEPROM 读写 |
| firm_update | `./firm_update.exe "\Device\NPF_{GUID}" <slave> <firmware.bin>` | 通过 FoE 升级固件 |
| ebox | (Linux only) | E/BOX 高速流模式测试 |
| red_test | (Linux only) | 双网卡冗余测试 |

所有工具先运行不带参数查看可用网卡和 GUID：

```bash
./simple_test.exe
```

详细使用说明参见 [USAGE.md](USAGE.md)。
