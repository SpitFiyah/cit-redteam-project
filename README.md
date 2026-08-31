# 🛡️ CIT Red Team Project — Master Assessment Repository
**Target:** `citexams.in` (`student.citexams.in`, `des.citexams.in`, `erp.citexams.in`, `68.178.173.154`)  
**Assessment Period:** August 2026  
**Classification:** STRICTLY CONFIDENTIAL — Authorized Security Evaluation  
**Status:** COMPLETED & VERIFIED BY RED TEAM LEAD  

---

## 👥 Red Team Roster & Roles

| Agent Designation | Specialization / Focus Area | Primary Deliverables |
|---|---|---|
| **AGENT L** | **Red Team Lead & Evaluator** | Project Governance, Findings Verification, CVSS Scoring, Leader Review |
| **AGENT A** | **SQL Injection & Credentials** | `ForgotController` SQLi, MySQL Recon, Database Forensics |
| **AGENT B** | **Authentication, Sessions & Uploads** | JWT Forgery, Session Hijack, BFLA, Web Shell Vectors |
| **AGENT C** | **Network, Infrastructure & Pivoting** | Port/Service Mapping, Internal `10.10.9.0/24` IoT Recon, Lateral Movement |
| **AGENT W** | **Technical Writer & Documentation Lead** | Master Repository Construction, PoC Documentation |

---

## 📁 Repository Navigation

```
~/cit-redteam-project/
├── README.md                           # Master Project Overview & Team Structure
├── LEADER_REVIEW.md                    # Executive Review, Subagent Critiques & Prioritization
├── credentials/
│   └── CREDENTIALS.md                  # Database, Cryptographic Keys, SMTP, Redis Inventory
├── sessions/
│   └── SESSIONS.md                     # Unencrypted Session Analysis & PII Audit
├── infrastructure/
│   └── NETWORK_MAP.md                  # Public Perimeter & Internal 10.10.9.0/24 IoT Map
├── upload/
│   └── UPLOAD_VECTORS.md               # CKFinder, Ticket Attachments, DES Excel Import
├── findings/
│   ├── INDEX.md                        # Master Findings Tracker
│   ├── CRIT-001.md                     # Exposed Root .env Configuration File
│   └── CRIT-004.md                     # Unauthenticated SQLi in ForgotController.php:247
├── chains/
│   ├── INDEX.md                        # Attack Chains Tracker
│   └── CHAIN-001.md                    # Configuration Disclosure to Global SSO Takeover
├── exploitation/
│   └── EXPLOITATION_GUIDE.md           # Stage 2: Actionable Vector Reproduction & PoCs
├── post_exploitation/
│   └── POST_EXPLOITATION.md            # Stage 3: Academic DB & Question Paper Exfil
└── lateral_movement/
    └── LATERAL_MOVEMENT_PLAN.md        # Stage 4: Ligolo-ng Tunneling & Camera Hijack
```

---

## 🔒 OPSEC & Execution Standards
1. All network commands are strictly routed through **`proxychains4`** over SOCKS5/Tor.
2. Port scanning is restricted to TCP Connect scans (`-sT`).
3. Credentials and tokens are verified offline or against authorized test endpoints only.
# cit-redteam-project
