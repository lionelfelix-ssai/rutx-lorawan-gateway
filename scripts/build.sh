#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SDK_DIR="${SDK_DIR:-$HOME/rutx11-lora/sdk/rutos-ipq40xx-rutx-sdk}"
SRC_DIR="${REPO_DIR}/src"
BUILD_OUT="${REPO_DIR}/build"

echo "=== RUTX11 LoRaWAN Gateway Build ==="

TC=$(ls -d ${SDK_DIR}/staging_dir/toolchain-arm_cortex-a7+neon-vfpv4_gcc-*_musl_eabi 2>/dev/null | head -1)
if [ -z "$TC" ]; then
    echo "ERROR: Toolchain not found at $SDK_DIR"
    echo "Set SDK_DIR to your Teltonika SDK path, or build the SDK first."
    exit 1
fi

export STAGING_DIR=${SDK_DIR}/staging_dir
export PATH=${TC}/bin:$PATH
export ARCH=arm
export CROSS_COMPILE=arm-openwrt-linux-muslgnueabi-
echo "Toolchain: $(${CROSS_COMPILE}gcc --version | head -1)"

if [ ! -d "${SRC_DIR}/sx1302_hal" ]; then
    echo "Cloning sx1302_hal..."
    mkdir -p "$SRC_DIR"
    git clone https://github.com/Lora-net/sx1302_hal.git "${SRC_DIR}/sx1302_hal"
    cd "${SRC_DIR}/sx1302_hal"
    git checkout V2.1.0
else
    cd "${SRC_DIR}/sx1302_hal"
fi

echo "Applying patches..."
for patch in ${REPO_DIR}/patches/*.patch; do
    [ -f "$patch" ] || continue
    echo "  $(basename $patch)"
    git apply --check "$patch" 2>/dev/null && git apply "$patch" || echo "  (already applied or skipped)"
done

# Also disable GPS serial path
sed -i 's|/dev/ttyS0||' packet_forwarder/global_conf.json.sx1250.US915.USB 2>/dev/null || true

echo "Building..."
make clean
make all -j$(nproc)

echo ""
file packet_forwarder/lora_pkt_fwd

if file packet_forwarder/lora_pkt_fwd | grep -q "ARM"; then
    echo "SUCCESS"
    mkdir -p "$BUILD_OUT"
    cp packet_forwarder/lora_pkt_fwd "$BUILD_OUT/"
    cp util_chip_id/chip_id "$BUILD_OUT/"
    cp packet_forwarder/global_conf.json.sx1250.US915.USB "$BUILD_OUT/global_conf.json"
    echo "Output: $BUILD_OUT/"
    ls -lh "$BUILD_OUT/"
else
    echo "FAILED: Binary is not ARM"
    exit 1
fi
