#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUT="${REPO_DIR}/build"
RUTX_HOST="${1:-root@192.168.1.1}"

echo "=== RUTX11 LoRaWAN Gateway Deploy ==="
echo "Target: $RUTX_HOST"

if [ ! -f "$BUILD_OUT/lora_pkt_fwd" ]; then
    echo "ERROR: No built binary found. Run scripts/build.sh first."
    exit 1
fi

echo "Checking kmod-usb-acm..."
ssh "$RUTX_HOST" "opkg list-installed | grep -q kmod-usb-acm" || {
    echo "Installing kmod-usb-acm..."
    ssh "$RUTX_HOST" "opkg update && opkg install kmod-usb-acm"
}

echo "Creating directories..."
ssh "$RUTX_HOST" "mkdir -p /usr/local/lora/bin /etc/lora"

echo "Copying binaries..."
scp "$BUILD_OUT/lora_pkt_fwd" "$RUTX_HOST:/usr/local/lora/bin/"
scp "$BUILD_OUT/chip_id" "$RUTX_HOST:/usr/local/lora/bin/"
scp "$BUILD_OUT/global_conf.json" "$RUTX_HOST:/etc/lora/"

echo "Copying scripts and configs..."
scp "$REPO_DIR/deploy/usr/local/lora/bin/start_pkt_fwd.sh" "$RUTX_HOST:/usr/local/lora/bin/"
scp "$REPO_DIR/deploy/usr/local/lora/bin/reset_lgw.sh" "$RUTX_HOST:/usr/local/lora/bin/"
scp "$REPO_DIR/deploy/etc/lora/lns.conf" "$RUTX_HOST:/etc/lora/"
scp "$REPO_DIR/deploy/etc/init.d/lora-pkt-fwd" "$RUTX_HOST:/etc/init.d/"

echo "Setting permissions..."
ssh "$RUTX_HOST" "chmod +x /usr/local/lora/bin/* /etc/init.d/lora-pkt-fwd"

echo "Reading gateway EUI..."
EUI=$(ssh "$RUTX_HOST" "/usr/local/lora/bin/chip_id -u -d /dev/ttyACM0 2>/dev/null" | grep "concentrator EUI" | awk '{print $NF}' | sed 's/0x//')

echo ""
echo "========================================="
echo "  Gateway EUI: ${EUI:-UNKNOWN (is RAK7371 plugged in?)}"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Register this EUI on your LNS (TTN, ChirpStack)"
echo "  2. Edit /etc/lora/lns.conf on the RUTX11"
echo "  3. Test: ssh $RUTX_HOST '/usr/local/lora/bin/start_pkt_fwd.sh'"
echo "  4. Enable auto-start: ssh $RUTX_HOST '/etc/init.d/lora-pkt-fwd enable && /etc/init.d/lora-pkt-fwd start'"
