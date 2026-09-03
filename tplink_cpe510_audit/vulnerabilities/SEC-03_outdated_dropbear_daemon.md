# SEC-03: Outdated Dropbear SSH Daemon (`2016.74`)

## Metadata Overview
- **Vulnerability ID:** SEC-03
- **Severity:** Low / Medium (CVSS 4.3)
- **Vector:** `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`
- **Target Component:** Embedded Dropbear SSH Daemon v2016.74
- **Affected Host:** `10.10.9.252:22`

---

## Technical Description

Banner identification of port 22 reveals:
`SSH-2.0-dropbear_2016.74`

Dropbear version `2016.74` was released in 2016 and is outdated by several years. Outdated Dropbear binaries contain known security flaws, memory management issues, and lack modern cryptographic primitives (such as ChaCha20-Poly1305 and modern key exchange curves).

---

## Security Impact

1. **Known Vulnerability Exposure:** Older Dropbear builds are vulnerable to resource exhaustion and legacy cipher suite vulnerabilities.
2. **Missing Security Features:** Lacks default post-quantum and modern key exchange algorithms.

---

## Remediation

- Upgrade embedded Dropbear daemon via vendor firmware updates.
- If custom firmware builds are used, recompile Dropbear with version 2022.+ or higher.
