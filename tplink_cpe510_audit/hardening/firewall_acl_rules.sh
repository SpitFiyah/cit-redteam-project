#!/bin/bash
# ==============================================================================
# TP-Link CPE510 (10.10.9.252) Blue Team Firewall & ACL Hardening Script
# Description: Rules for upstream router/switch to restrict access to 10.10.9.252
# ==============================================================================

TARGET_IP="10.10.9.252"
ADMIN_SUBNET="10.10.9.50/29" # Authorized Security Management Range
INTERFACE="eth0"

echo "[*] Applying Blue Team ACL Firewall Rules for $TARGET_IP..."

# 1. Allow ESTABLISHED, RELATED connections
iptables -A FORWARD -d $TARGET_IP -m state --state ESTABLISHED,RELATED -j ACCEPT

# 2. Allow HTTPS (443) and SSH (22) ONLY from Authorized Admin Subnet
iptables -A FORWARD -s $ADMIN_SUBNET -d $TARGET_IP -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s $ADMIN_SUBNET -d $TARGET_IP -p tcp --dport 22 -j ACCEPT

# 3. Block HTTP (80), HTTPS (443), and SSH (22) from all other internal subnets
iptables -A FORWARD -d $TARGET_IP -p tcp --dport 80 -j DROP
iptables -A FORWARD -d $TARGET_IP -p tcp --dport 443 -j DROP
iptables -A FORWARD -d $TARGET_IP -p tcp --dport 22 -j DROP

# 4. Log dropped management connection attempts
iptables -A FORWARD -d $TARGET_IP -p tcp -m multiport --dports 22,80,443 -j LOG --log-prefix "[SEC-252-BLOCKED]: "

echo "[+] Rules applied successfully."
