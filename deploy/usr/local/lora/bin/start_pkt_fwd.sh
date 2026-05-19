#!/bin/sh
CONF_DIR=/etc/lora
LNS_CONF=${CONF_DIR}/lns.conf
GW_CONF=${CONF_DIR}/global_conf.json
RUNTIME_CONF=/tmp/lora_runtime.json
BIN_DIR=/usr/local/lora/bin

if [ ! -f "$LNS_CONF" ]; then
    logger -t lora "ERROR: $LNS_CONF not found"
    exit 1
fi
. "$LNS_CONF"

EUI_FILE=${CONF_DIR}/gateway_eui
if [ ! -f "$EUI_FILE" ]; then
    EUI=$($BIN_DIR/chip_id -u -d /dev/ttyACM0 2>/dev/null | grep "concentrator EUI" | awk '{print $NF}' | sed 's/0x//')
    if [ -z "$EUI" ]; then
        logger -t lora "ERROR: Could not read gateway EUI"
        exit 1
    fi
    echo "$EUI" > "$EUI_FILE"
    logger -t lora "Gateway EUI detected: $EUI"
else
    EUI=$(cat "$EUI_FILE")
fi

cp "$GW_CONF" "$RUNTIME_CONF"
sed -i "s/\"server_address\":.*/\"server_address\": \"${LNS_ADDRESS}\",/" "$RUNTIME_CONF"
sed -i "s/\"serv_port_up\":.*/\"serv_port_up\": ${LNS_PORT_UP},/" "$RUNTIME_CONF"
sed -i "s/\"serv_port_down\":.*/\"serv_port_down\": ${LNS_PORT_DOWN},/" "$RUNTIME_CONF"
sed -i "s/\"gateway_ID\":.*/\"gateway_ID\": \"${EUI}\",/" "$RUNTIME_CONF"

logger -t lora "Starting lora_pkt_fwd -> ${LNS_ADDRESS}:${LNS_PORT_UP} (EUI: ${EUI})"
cd "$BIN_DIR"
exec ./lora_pkt_fwd -c "$RUNTIME_CONF"
