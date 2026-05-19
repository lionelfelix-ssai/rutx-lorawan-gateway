# Troubleshooting

## /dev/ttyACM0 missing
kmod-usb-acm not installed or not loaded. Run opkg install kmod-usb-acm. Check USB cable and RAK7371 green LED.

## "not found" when running binary
Wrong architecture. file /usr/local/lora/bin/lora_pkt_fwd must say ARM, EABI5, statically linked.

## Segfault after "concentrator started"
Ensure you applied both patches: static linking (001) AND thread stack size (002). Rebuild and redeploy.

## No PULL_ACK from TTN
- DNS: nslookup the LNS address from the RUTX11
- Firewall: outbound UDP 1700 must be allowed
- TTN: "Require authenticated connection" must be UNCHECKED
- EUI: must match exactly between config and TTN registration

## Gateway online but no uplinks
- Sensor on wrong sub-band (US915 has 8 sub-bands)
- Sensor out of range
- Sensor needs OTAA join -- register device on TTN first

## Cannot write to /opt/
RutOS uses read-only squashfs root. Use /usr/local/ (writable overlay).
