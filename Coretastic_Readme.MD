# Coretastic

Coretastic is a **field-ready bridge** between Meshtastic and Meshcore, built around a Luckfox Pico M and dual Core1262 LoRa modules. It lets Meshtastic users seamlessly communicate with Meshcore “rooms” through a small, rugged gateway node.

***

## Features

- Luckfox Pico M + dual Core1262 LoRa gateway/relay node  
- Bidirectional Meshtastic ↔ Meshcore messaging (LoRa ↔ IP bridge)  
- OpenRC service for always-on operation  
- Text-based monitoring and control via the `coredash` TUI  
- Minimal Alpine Linux footprint to maximize CPU for Meshcore Rooms

***

## Architecture Overview

- **OS:** Minimal Alpine Linux (e.g., RV1106/RV1103) tuned for running Meshcore Rooms.  
- **Radio:** Dual Core1262 modules for parallel Gateway/Relay tasks.  
- **Bridge:** Node.js “meshcore-rooms” server plus Meshtastic Python bridge to pass messages between LoRa and IP.  
- **TUI:** `coredash` for real-time visibility into mesh activity and system health.

Meshtastic users send/receive messages over LoRa, the Coretastic node picks them up via Meshtastic, and the Node.js Meshcore Rooms service relays them into/out of Meshcore.

***

## Deployment Script (`coretastic.sh`)

The `coretastic.sh` script is the all-in-one deployer for a Coretastic node.

It:

- Updates the system and installs dependencies (bash, git, python3, build tools, nodejs, npm, meshtastic, etc.).  
- Configures GPIO and SPI for the dual Core1262 modules (pins 50 and 51).  
- Verifies the SPI interface (`/dev/spidev0.0`) is present and aborts if not.  
- Installs/updates the Meshtastic Python package.  
- Optionally creates a non-root service user for the Node.js process.  
- Creates an OpenRC service `coretastic` that:
  - Runs `node server.js` in your Meshcore Rooms directory.  
  - Initializes the GPIOs on every boot via a small helper script.  
  - Logs to `/var/log/coretastic.log` and `/var/log/coretastic.err`.  
  - Starts automatically at boot.

### Integration with `coredash`

The deployment script should also:

- Install the TUI script to `/usr/local/bin/coredash`.  
- Ensure it is executable so it can be launched from anywhere.

Example final step in your deploy:

```bash
chmod +x /usr/local/bin/coredash
```

After that, you can simply type:

```bash
coredash
```

from any directory to bring up the Coretastic dashboard.

***

## Coredash: Coretastic Master TUI

`coredash` is the interactive “operations console” for your Coretastic node. It runs in a terminal and talks directly to your Meshtastic radios via the Meshtastic CLI.

### What Coredash Does

- Connects to both Core1262 radios:
  - Gateway: `/dev/spidev0.0`
  - Relay: `/dev/spidev0.1`
- Shows **system stats**:
  - Uptime (via `uptime -p`)  
  - RAM usage (via `free -m`)  
  - CPU load (via `top -bn1`)
- Shows **radio stats**:
  - Per-module RSSI/SNR from `meshtastic --info` so you can quickly judge link health.  
- Shows **recent mesh nodes**:
  - Last 5 active nodes from `meshtastic --nodes` on the primary module.
- Provides a **radio config menu**:
  - Change LoRa spreading factor (SF 7–12) on both modules.  
  - Set transmit power (1–22 dBm) on both modules.  
  - Reset the Meshtastic node database on both modules.

### Interference / Antenna Spacing

Use the RSSI/SNR readouts in `coredash` to watch RF health:

- If your SNR is consistently worse than about `-10`, your antennas are likely too close or poorly placed.  
- As a rule of thumb, keep at least **20 cm to 0.5 m** separation between antennas to reduce self-interference.

***

## Final Deployment Checklist

1. **Run the deployment script**  
   On your Coretastic node (as root):

   ```bash
   ./coretastic.sh
   ```

   This will install dependencies, set up hardware, install Meshtastic, create the OpenRC service, and (once integrated) install `coredash`.

2. **Make `coredash` executable and global**

   ```bash
   chmod +x /usr/local/bin/coredash
   ```

3. **Prepare your Meshcore project**

   ```bash
   cd /root/meshcore-rooms
   npm install
   ```

4. **Enable and start the service**

   ```bash
   rc-service coretastic start
   rc-update add coretastic default
   ```

5. **Launch the TUI**

   ```bash
   coredash
   ```

   Use it to:
   - Monitor CPU/RAM usage (ensure Meshcore Rooms has enough headroom).  
   - Watch RSSI/SNR on both radios and adjust antenna placement if needed.  
   - Confirm nearby Meshtastic nodes are visible.  
   - Tune SF/Tx power to suit your range and interference environment.

***

## Project Goals

- Make it trivial to deploy a Meshtastic ↔ Meshcore bridge on small Luckfox boards.  
- Provide a reproducible, scriptable deployment path for field gateways.  
- Give operators a clear, low-friction way to monitor and tune their off-grid mesh nodes.
