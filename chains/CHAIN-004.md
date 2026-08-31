# ⚔️ Attack Chain 004: Internal CI/CD Compromise to Active Directory Domain Escalation
**Severity:** 🔴 CRITICAL | **Lead Evaluator:** AGENT L | **Technical Author:** AGENT W  

---

## 1. Execution Flow

```
[Attacker with Network Access to 10.10.9.x]
    │
    ▼ (1) Target Internal Jenkins Server (2.492.2)
[Script Console / LDAP Referral Exploit]
    │ └── System command execution as NT AUTHORITY\SYSTEM
    ▼ (2) Dump Windows Domain Cached Credentials
[HKEY_LOCAL_MACHINE\SECURITY\Cache (NL$1-10)]
    │ └── 10 DCC2 Domain User Password Hashes Extracted
    ▼ (3) Offline Hashcat DCC2 Cracking (Mode 2100)
[Active Directory Domain User / Admin Credentials Recovered]
```
