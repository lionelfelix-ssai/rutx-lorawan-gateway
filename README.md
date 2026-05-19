# rutx-lorawan-gateway

Turn a Teltonika RUTX11 into an 8-channel LoRaWAN gateway using a RAK7371 USB concentrator.
NOTE: THIS WAS TESTED ON RAK7371 WisGate Developer Base US 915 Mhz SKU: 716039 from 
https://store.rokland.com/products/rakwireless-rak7371-wisgate-developer-base-us-915-mhz-sku-716039

**This is believed to be the first documented implementation of a Teltonika RUTX-series router functioning as a LoRaWAN gateway via USB concentrator.**

## What This Does

A RAK7371 WisGate Developer Base (SX1303, 8-channel LoRaWAN concentrator) plugs into the RUTX11 USB port. The cross-compiled Semtech packet forwarder runs on the RUTX11 and forwards LoRaWAN packets to any network server that speaks Semtech UDP -- The Things Network, ChirpStack, or any other LNS.

One device handles LTE/Ethernet backhaul, BLE, WiFi, AND LoRaWAN gateway -- no separate gateway hardware needed.

## Hardware Required

- Teltonika RUTX11 (firmware RUTX_R_00.07.x)
- RAK7371 WisGate Developer Base (US915 for North America, EU868 for Europe)
- USB-C to USB-A cable (included with RAK7371)

## Why the RUTX11

The RUTX11 is the only BLE-enabled router in Teltonika's lineup. For IoT deployments, BLE is a critical part of the stack -- asset tracking, beacons, environmental sensors. Adding LoRaWAN gateway capability to a device that already handles BLE, dual-SIM LTE, Ethernet, and WiFi means one box covers the entire wireless IoT transport layer at a site.

## Quick Start

### 1. Build (on an x86_64 Linux machine)

Download the Teltonika RUTX GPL SDK matching your router firmware version from https://wiki.teltonika-networks.com/view/FW_&_SDK_Downloads

Extract and build the toolchain, then build the packet forwarder:

    git clone https://github.com/lionelfelix-ssai/rutx-lorawan-gateway.git
    cd rutx-lorawan-gateway
    SDK_DIR=/path/to/rutos-ipq40xx-rutx-sdk scripts/build.sh

### 2. Deploy (to the RUTX11)

Plug the RAK7371 into the RUTX11 USB port, then:

    scripts/deploy.sh root@RUTX11_IP

### 3. Configure

Edit /etc/lora/lns.conf on the RUTX11 to point to your network server. Register the gateway EUI (printed by the deploy script) on your LNS.

### 4. Run

    # Manual test
    /usr/local/lora/bin/start_pkt_fwd.sh

    # Enable auto-start
    /etc/init.d/lora-pkt-fwd enable
    /etc/init.d/lora-pkt-fwd start

## What Success Looks Like

    INFO: [main] concentrator started, packet can now be received
    INFO: concentrator EUI: 0x0016c001f12a743e
    INFO: [down] PULL_ACK received in 97 ms
    INFO: [up] PUSH_ACK received in 102 ms

## File Layout on RUTX11

    /usr/local/lora/bin/
        lora_pkt_fwd            Packet forwarder (statically linked ARM binary)
        chip_id                 Gateway EUI reader
        reset_lgw.sh            No-op reset (USB mode)
        start_pkt_fwd.sh        Startup wrapper (reads lns.conf, patches config)

    /etc/lora/
        global_conf.json        Radio/channel config (US915 USB)
        lns.conf                Server selection -- edit this to swap LNS
        gateway_eui             Auto-generated on first boot

    /etc/init.d/
        lora-pkt-fwd            procd service script

## Patches Applied to sx1302_hal

The upstream Semtech sx1302_hal (https://github.com/Lora-net/sx1302_hal) requires three patches to run on RutOS (musl-based OpenWrt):

1. Static linking -- musl dynamic linking causes segfaults in the packet forwarder threading
2. Thread stack size -- musl default 128KB thread stack is too small; patched to 1MB
3. GPS serial disabled -- RUTX11 has no GPS on /dev/ttyS0

See the patches/ directory.

## Build Host Requirements

- x86_64 Linux (Ubuntu 22.04 or 24.04 LTS recommended)
- 50GB disk, 8GB RAM, 4+ CPU cores
- See docs/UBUNTU-2604-FIXES.md if building on Ubuntu 26.04+

## Tested With

- RUTX11 firmware: RUTX_R_00.07.23.1
- RAK7371 WisGate Developer Base (US915)
- sx1302_hal: V2.1.0
- LNS: The Things Stack Cloud (Things Industries)

## Roadmap

- .ipk package for Teltonika package manager
- Test across RUTX series (RUTX12, RUTX14, RUTX50)
- EU868 channel plan support
- LoRa Basics Station (authenticated/encrypted connections)
- ChirpStack integration guide

## Credits

Developed by Lionel Felix (StructureSense.ai) in collaboration with Claude (Anthropic). The feasibility analysis, cross-compilation architecture, musl compatibility patches, and deployment automation were produced through a real-time human-AI pairing session.

## License

MIT -- see LICENSE.
