# ⚔️ Attack Chain 003: Internal LAN Pivoting & Physical Security Surveillance Hijack
**Severity:** 🟠 HIGH | **Lead Evaluator:** AGENT L | **Technical Author:** AGENT W  

---

## 1. Execution Flow

```
[Attacker Foothold on 10.10.9.187]
    │
    ▼ (1) Direct LAN ICMP / ARP Discovery
[10.10.9.0/24 Subnet]
    │ ├── 10.10.9.101 (Hikvision NVR: DNVRS-Webs on Port 80)
    │ ├── 10.10.9.103-110 (Hikvision Cameras on RTSP Port 554)
    │ └── 10.10.9.133 (HPE Aruba Network Switch on Port 8080)
    ▼ (2) Direct RTSP Stream Interception
[Campus Surveillance Video Streams] (Zero-Authentication RTSP Frame Capture)
```

---

## 2. Step-by-Step Execution
1. **Discover Live Cameras:** Ping sweep verifies `10.10.9.101`, `.103`, `.108`, `.109`, `.110` are active.
2. **Stream Interception:** Connect directly to RTSP endpoint over port 554 to capture surveillance feeds without entering physical premises.
