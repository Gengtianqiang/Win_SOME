#!/bin/bash
# Win_SOME 一键编译脚本
# 编译所有 Windows 兼容的 EtherCAT 工具

set -e

cd "$(dirname "$0")"

SRC="soem/ethercatbase.c soem/ethercatcoe.c soem/ethercatconfig.c \
    soem/ethercatdc.c soem/ethercatfoe.c soem/ethercatmain.c \
    soem/ethercatprint.c soem/ethercatsoe.c \
    osal/win32/osal.c oshw/win32/nicdrv.c oshw/win32/oshw.c"

INC="-Isoem -Iosal -Ioshw/win32 -Ioshw/win32/wpcap/Include -idirafter osal/win32"
LIB="-lws2_32 -lwinmm -lwpcap -lpacket -Loshw/win32/wpcap/Lib/x64"
OPT="-O2 -Wall"

echo "=== Building simple_test.exe ==="
gcc $INC $SRC test/simple_test/simple_test.c -o simple_test.exe $OPT $LIB
echo "OK"

echo "=== Building slaveinfo.exe ==="
gcc $INC $SRC test/slaveinfo/slaveinfo.c -o slaveinfo.exe $OPT $LIB
echo "OK"

echo "=== Building eepromtool.exe ==="
gcc $INC $SRC test/eepromtool/eepromtool.c -o eepromtool.exe $OPT $LIB
echo "OK"

echo "=== Building firm_update.exe ==="
gcc $INC $SRC test/firm_update/firm_update.c -o firm_update.exe $OPT $LIB
echo "OK"

echo ""
echo "All builds successful."
ls -la *.exe
