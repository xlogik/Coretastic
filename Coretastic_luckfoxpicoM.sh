#!/bin/bash

# Project: Coretastic (Luckfox Pico M + Dual Core1262)
# Function: Full environment setup and OpenRC service generation

echo "===================================================="
echo "          CORETASTIC: ALL-IN-ONE DEPLOY             "
echo "===================================================="

# --- PHASE 1: SYSTEM PREP ---
echo "[1/3] Updating Alpine and installing build-base..."
apk update
# build-base, python3-dev, and libffi are critical for compiling C++ bridges
apk add bash git python3 python3-dev py3-pip build-base nodejs npm libffi-dev openssl-dev

# --- PHASE 2: HARDWARE INITIALIZATION ---
echo "[2/3] Configuring Core1262 GPIOs (Pins 36 & 37)..."

# Rockchip GPIO IDs: (Bank 1 * 32) + (Group C [2]*8) + Index 2/3
MOD1_CS=50
MOD2_CS=51

setup_hw() {
    for pin in $MOD1_CS $MOD2_CS; do
        if [ ! -d "/sys/class/gpio/gpio$pin" ]; then
            echo "$pin" > /sys/class/gpio/export 2>/dev/null
        fi
        echo "out" > "/sys/class/gpio/gpio$pin/direction"
    done
}
setup_hw

# Validate SPI
if [ -e "/dev/spidev0.0" ]; then
    echo "SUCCESS: Dual SPI Bus Detected."
else
    echo "CRITICAL: SPI not found. Ensure it is enabled in luckfox-config!"
fi

# Install Meshtastic Python Bridge
pip install --upgrade meshtastic --break-system-packages

# --- PHASE 3: OPENRC SERVICE CREATION ---
echo "[3/3] Generating 'coretastic' OpenRC service..."

cat <<EOF > /etc/init.d/coretastic
#!/sbin/openrc-run

name="coretastic"
description="Coretastic Meshcore-Meshtastic Bridge"
directory="/root/meshcore-rooms"
command="/usr/bin/node"
command_args="server.js"
pidfile="/run/coretastic.pid"
command_background="yes"

depend() {
    need net
    after bootmisc
}

start_pre() {
    # Ensure hardware is ready on every boot
    echo 50 > /sys/class/gpio/export 2>/dev/null
    echo 51 > /sys/class/gpio/export 2>/dev/null
    echo out > /sys/class/gpio/gpio50/direction
    echo out > /sys/class/gpio/gpio51/direction
}
EOF

# Set permissions and enable for boot
chmod +x /etc/init.d/coretastic
rc-update add coretastic default

echo "===================================================="
echo " CORETASTIC DEPLOYMENT COMPLETE! "
echo "----------------------------------------------------"
echo " Next Steps: "
echo " 1. Navigate to your Meshcore folder."
echo " 2. Run 'npm install' (Wait for compilation)."
echo " 3. Start your new service: 'rc-service coretastic start'"
echo "===================================================="
