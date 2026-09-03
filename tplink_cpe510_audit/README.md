# 🛡️ TP-Link CPE510 (PharOS 3.20) Security Audit & Blue Team Repository

**Target IP:** `10.10.9.252`  
**MAC Address:** `98:25:4A:B3:B2:82`  
**Hardware Model:** TP-Link CPE510 (Outdoor Access Point / Gateway)  
**Firmware Version:** PharOS 3.20 (devVer: 3.20)  
**Assessment Date:** September 2026  
**Role:** Blue Team Defensive Security & Hardening  

---

## 📁 Repository Structure

```
tplink_cpe510_audit/
├── README.md                                       # Master Repository Overview & Device Specs
├── vulnerabilities/
│   ├── SEC-01_unauthenticated_metadata_disclosure.md # Info Leak via /data/*.json Endpoints
│   ├── SEC-02_deprecated_ssh_dss_hostkey.md           # Deprecated DSA (ssh-dss) Host Key Algorithm
│   ├── SEC-03_outdated_dropbear_daemon.md            # Embedded Dropbear SSH 2016.74 Audit
│   └── SEC-04_unrestricted_management_exposure.md    # Management Interface Exposure (HTTP/HTTPS/SSH)
├── hardening/
│   ├── remediation_guide.md                        # Blue Team Hardening & Mitigation Action Plan
│   └── firewall_acl_rules.sh                       # Sample Network Filtering & VLAN Segmentation Script
└── scripts/
    └── metadata_audit.py                           # Python Audit Tool for PharOS & SSH Fingerprinting
```

---

## 📊 Summary of Audit Findings

| ID | Title | Severity | CVSS v3.1 | Status |
|---|---|---|---|---|
| **SEC-01** | Unauthenticated System Info Disclosure (`/data/version.json`) | **MEDIUM** | 5.3 | Confirmed & Documented |
| **SEC-02** | Deprecated SSH Host Key Algorithm (`ssh-dss`) | **MEDIUM** | 5.3 | Confirmed & Documented |
| **SEC-03** | Outdated Dropbear SSH Daemon (`2016.74`) | **LOW / MED** | 4.3 | Confirmed & Documented |
| **SEC-04** | Unrestricted Management Surface Exposure | **LOW / MED** | 4.3 | Confirmed & Documented |

---

## 🎯 Primary Defensive Goals
1. Upgrade device firmware to patch unauthenticated `.json` API responses.
2. Replace legacy `ssh-dss` keys with RSA (>=2048-bit) or Ed25519 host keys.
3. Isolate management traffic to a dedicated Management VLAN.
4. Disable plaintext HTTP management listener (Port 80).
