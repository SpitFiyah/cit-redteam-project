# 🛠️ TP-Link CPE510 Blue Team Remediation & Hardening Guide

**Target Host:** `10.10.9.252`  
**Device:** TP-Link CPE510 (PharOS Outdoor Access Point)  
**Author:** Blue Team Security Lead  

---

## 1. Executive Remediation Overview

To secure `10.10.9.252` against unauthorized access, network reconnaissance, and cryptographic degradation, execute the following 4-step hardening workflow:

```
[ Step 1: Firmware Upgrade ]
           │
           ▼
[ Step 2: Management VLAN Isolation ]
           │
           ▼
[ Step 3: SSH Cipher & Key Hardening ]
           │
           ▼
[ Step 4: Access Control & Lockout Configuration ]
```

---

## 2. Step-by-Step Mitigation Instructions

### Step 1: Firmware Upgrade
1. Download the latest official firmware build for **CPE510 V3.20+** from [TP-Link Official Support](https://www.tp-link.com).
2. Log into the PharOS Web Interface (`https://10.10.9.252`).
3. Navigate to **System** -> **Firmware Update**.
4. Upload the official `.bin` firmware file and execute the update.
5. *Validation:* Confirm that `/data/version.json` requires valid authentication cookies post-update.

### Step 2: Network & VLAN Isolation
1. Assign `10.10.9.252` management access to **Management VLAN 99**.
2. Configure upstream switch ports (TP-Link Switch `10.10.9.128`) to block HTTP (80), HTTPS (443), and SSH (22) traffic from general campus subnets (`10.10.9.0/24`).
3. Permit management traffic *only* from authorized Security Admin IP range (`10.10.9.50/29`).

### Step 3: SSH Daemon Hardening
1. In PharOS administrative settings under **System** -> **Management Services**, update SSH configuration:
   - Regenerate SSH Host Keys (replace `ssh-dss` with RSA 2048+ / Ed25519).
   - Change default SSH Port from `22` to a non-standard port (e.g., `22222`).
   - Restrict SSH login users to strong, complex passwords or public keys.

### Step 4: Web Interface & Lockout Tuning
1. Set **Account Lockout Threshold** to `5` failed attempts.
2. Set **Lockout Duration** (`lockTime`) to `900` seconds (15 minutes).
3. Disable plain HTTP administration on Port 80, forcing HTTPS-only access.
