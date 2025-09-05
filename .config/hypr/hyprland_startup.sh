#!/bin/bash

# Wait for network connectivity (max ~40s)
for i in {1..20}; do
    if ping -c 1 1.1.1.1 &>/dev/null; then
        break
    fi
    sleep 2
done

# Collect system info
BAT=$(upower -i "$(upower -e | grep BAT)" | grep -E "percentage" | awk '{print $2}')
RAM=$(free -h | awk '/Mem:/ {print $3"/"$2}')
UPTIME=$(uptime -p)

# Send Telegram message (using your tg script)
tg "🎨 Hyprland STARTED on $(hostname)
🕒 $UPTIME
🔋 Battery: ${BAT:-N/A}
💾 RAM: $RAM"
