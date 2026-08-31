# 🌐 Infrastructure & Network Topology Analysis
**Target:** `citexams.in` (Public Perimeter & Internal Campus Subnets)  
**Lead Evaluator:** AGENT L | **Analyst:** AGENT C  

---

## 1. Public Perimeter Attack Surface (`68.178.173.154`)

**Host:** `154.173.178.68.host.secureserver.net` (GoDaddy / SecureServer Infrastructure)

| Port | Protocol | State | Service | Notes & Exploitation Paths |
|---|---|---|---|---|
| **22** | TCP | OPEN | OpenSSH | Potential brute-force / key authentication |
| **80 / 443** | TCP | OPEN | HTTP / HTTPS (Apache) | Primary web applications (`student`, `des`, `erp`) |
| **3306** | TCP | OPEN | MySQL 5.5+ / MariaDB | **Directly exposed to public internet** — vulnerable to `bookleeycit_citexams` / `TGmyYIU$T1k$2026` login |
| **2082 / 2083** | TCP | OPEN | cPanel / cPanel SSL | Web hosting management interface |
| **2086 / 2087** | TCP | OPEN | WHM / WHM SSL | Web Host Manager |
| **465 / 587** | TCP | OPEN | SMTPS / Submission | Mail transport |
| **993 / 995** | TCP | OPEN | IMAPS / POP3S | Encrypted mailbox access |
| **4190** | TCP | OPEN | Sieve | Mail filtering daemon |

---

## 2. Internal Subnet Topology & IoT Footprint (`10.10.9.0/24`)

Confirmed hosts and devices discovered on the internal Cambridge network:

| IP Address | MAC Address | Vendor / Hardware | Discovered Services & Ports | Risk / Role |
|---|---|---|---|---|
| **`10.10.9.101`** | `B4:A3:82:DF:37:0A` | Hangzhou Hikvision Digital Tech | 80 (HTTP Admin), 554 (RTSP), 8000, 9010 | Network Video Recorder (NVR) |
| **`10.10.9.103`** | `24:32:AE:6F:0F:49` | Hangzhou Hikvision Digital Tech | 80 (HTTP Config), 554 (RTSP), 8000, 9010 | IP Surveillance Camera |
| **`10.10.9.108`** | `24:B1:05:35:13:04` | Prama Hikvision India Pvt Ltd | 80 (HTTP Config), 554 (RTSP), 8000, 9010 | IP Surveillance Camera |
| **`10.10.9.109`** | `24:B1:05:B7:DF:6B` | Prama Hikvision India Pvt Ltd | 80 (HTTP webserver), 554 (RTSP), 8000 | IP Surveillance Camera |
| **`10.10.9.110`** | `24:B1:05:B7:DF:6C` | Prama Hikvision India Pvt Ltd | 80 (HTTP webserver), 554 (RTSP), 8000 | IP Surveillance Camera |
| **`10.10.9.128`** | `40:ED:00:A0:BE:ED` | TP-Link Systems | Network switch / AP | Network Routing |
| **`10.10.9.133`** | `54:F0:B1:C8:2F:CE` | Hewlett Packard Enterprise | 80, 443, 8080 (`mini_httpd`) | HPE Management / OOB Interface |
| **`10.10.9.208`** | `48:4D:7E:F4:5A:2E` | Dell Inc. | 902 (VMware Auth), 912, 5357 (HTTPAPI) | Windows Server / VMware Host |
| **`10.10.9.252`** | `98:25:4A:B3:B2:82` | TP-Link Systems | 22 (Dropbear SSH), 80/443 (HTTPD 1.0) | Gateway Switch / Router |

---

## 3. Internal Pivoting Methodology

```
[Attacker via Proxychains]
       │
       ▼ (Compromised Web / DB Foothold: 68.178.173.154)
[Ligolo-ng Proxy Agent / SSH Dynamic SOCKS on Port 1080]
       │
       ├─────────────────────────────────────────┐
       ▼                                         ▼
[Subnet 10.10.9.0/24: Surveillance NVRs]   [Subnet 10.10.9.208: Dell/VMware]
(RTSP Stream Exfil & Camera Hijack)        (Internal AD / Host Lateral Movement)
```
