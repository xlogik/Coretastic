#!/bin/bash
# CORETASTIC MASTER TUI (Coredash)
# Dependencies: meshtastic, bash, awk, sed

# --- CONFIGURATION ---
MOD1_PORT="/dev/spidev0.0"
MOD2_PORT="/dev/spidev0.1"

# --- UI COLORS ---
ORANGE='\e[38;5;208m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
RESET='\e[0m'

get_node_list() {
    # Grabs the last 5 active nodes from the primary module
    meshtastic --port $MOD1_PORT --nodes | grep -v "│" | head -n 8 | tail -n 5
}

radio_config_menu() {
    clear
    echo -e "${BLUE}=== CORETASTIC CONFIGURATOR ===${RESET}"
    echo "1) Change Spreading Factor (SF)"
    echo "2) Set Transmit Power (dBm)"
    echo "3) Reset Node DB"
    echo "4) Return to Dashboard"
    read -p "Selection [1-4]: " choice
    case $choice in
        1) read -p "SF (7-12): " sf; meshtastic --port $MOD1_PORT --set lora.spread_factor $sf; meshtastic --port $MOD2_PORT --set lora.spread_factor $sf ;;
        2) read -p "dBm (1-22): " pwr; meshtastic --port $MOD1_PORT --set lora.tx_power $pwr; meshtastic --port $MOD2_PORT --set lora.tx_power $pwr ;;
        3) meshtastic --port $MOD1_PORT --reset-nodedb; meshtastic --port $MOD2_PORT --reset-nodedb ;;
        *) return ;;
    esac
    echo "Settings applied. Press any key..." && read -n 1
}

while true; do
    clear
    # Header / Neofetch Section
    echo -e "${ORANGE}      /\\_/\\      ${RESET}  ${BLUE}CORETRASTIC NODE${RESET}"
    echo -e "${ORANGE}     ( o.o )     ${RESET}  OS: Alpine Linux (RV1106)"
    echo -e "${ORANGE}      > ^ <      ${RESET}  CPU: Rockchip Luckfox Pico M"
    echo -e "                 UPTIME: $(uptime -p | sed 's/up //')"
    echo -e "----------------------------------------------------"

    # System Stats (htop style)
    echo -e "${GREEN}[ SYSTEM RESOURCES ]${RESET}"
    free -m | awk 'NR==2{printf "RAM: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
    top -bn1 | grep "CPU:" | awk '{print "CPU LOAD: " $2 + $4 "%"}'
    
    # Radio Stats
    echo -e "\n${BLUE}[ DUAL CORE1262 STATUS ]${RESET}"
    # Fetching RSSI/SNR live
    M1_INFO=$(meshtastic --port $MOD1_PORT --info | grep -m 1 "rssi" || echo "Searching...")
    M2_INFO=$(meshtastic --port $MOD2_PORT --info | grep -m 1 "rssi" || echo "Searching...")
    echo -e "Mod 1 (Gateway): ${YELLOW}$M1_INFO${RESET}"
    echo -e "Mod 2 (Relay)  : ${YELLOW}$M2_INFO${RESET}"

    # Network Discovery
    echo -e "\n${GREEN}[ RECENT DISCOVERY ]${RESET}"
    get_node_list
    
    echo -e "----------------------------------------------------"
    echo -e " [C] Config | [R] Refresh | [Q] Quit"
    
    read -t 10 -n 1 key
    case $key in
        c|C) radio_config_menu ;;
        q|Q) clear; exit 0 ;;
        r|R) continue ;;
    esac
done
