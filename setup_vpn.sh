#!/bin/bash

# --- CONFIGURATION SCRIPT FOR TAILSCALE VPN EXIT NODES ---

# 1. Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (try: sudo ./setup_vpn.sh)"
  exit
fi

echo "=========================================="
echo "   STARTING AUTOMATED VPN MAINTENANCE"
echo "=========================================="

# 2. Update Operating System (Non-interactive)
echo "[1/5] Updating Raspberry Pi OS..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get upgrade -y -q

# 3. Enable IP Forwarding (Critical for Exit Node functionality)
echo "[2/5] configuring IP Forwarding..."
echo 'net.ipv4.ip_forward = 1' | tee /etc/sysctl.d/99-tailscale.conf > /dev/null
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf > /dev/null
sysctl -p /etc/sysctl.d/99-tailscale.conf > /dev/null

# 4. Update/Install Tailscale
echo "[3/5] Updating Tailscale..."
# This command installs it if missing, or updates it if present
curl -fsSL https://tailscale.com/install.sh | sh

# 5. Detect Local Subnet Automatically
echo "[4/5] Detecting Network Configuration..."
# This command asks "which IP do I use to talk to the internet?" and extracts it.
CURRENT_IP=$(ip route get 8.8.8.8 | awk '{print $7}')
# This takes "192.168.68.55" and turns it into "192.168.68.0/24"
SUBNET=$(echo $CURRENT_IP | cut -d. -f1,2,3).0/24

echo "      -> Device IP: $CURRENT_IP"
echo "      -> Advertising Subnet: $SUBNET"

# 6. Apply Tailscale Settings
echo "[5/5] Applying Tailscale Settings..."
# --ssh: Enables SSH
# --advertise-exit-node: Makes it a VPN server
# --advertise-routes: Allows LAN access
# --accept-routes: Allows this Pi to reach OTHER VPN sites
# --reset: Forces these settings to override any old mistakes
tailscale up --ssh --advertise-exit-node --advertise-routes=$SUBNET --accept-routes --reset

echo "=========================================="
echo "   SUCCESS! SETUP COMPLETE."
echo "=========================================="
echo "IMPORTANT REMINDER:"
echo "1. Go to https://login.tailscale.com/admin/machines"
echo "2. Find this device"
echo "3. Toggle 'Use as Exit Node' and the Subnet Route ($SUBNET) to ON."