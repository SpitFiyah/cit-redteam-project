# SEC-04: Unrestricted Management Surface Exposure

## Metadata Overview
- **Vulnerability ID:** SEC-04
- **Severity:** Low / Medium (CVSS 4.3)
- **Vector:** `CVSS:3.1/AV:A/AC:L/PR:N/UI:N/S:U/C:L/I:L/A:N`
- **Target Component:** Network Routing & Management Access Control
- **Affected Host:** `10.10.9.252` (Ports 22, 80, 443)

---

## Technical Description

The management interfaces of `10.10.9.252` (PharOS Web UI on 80/443 and Dropbear SSH on 22) are bound to all network interfaces and accessible to any host on the internal `10.10.9.0/24` subnet without IP restriction or management VLAN isolation. Furthermore, plain HTTP (Port 80) accepts connections and relies on web redirects to HTTPS rather than dropping or restricting unencrypted access.

---

## Security Impact

1. **Broad Internal Attack Surface:** Any host on the `10.10.9.0/24` subnet (including potentially compromised IoT cameras or student devices) can reach administrative web and SSH portals.
2. **Credential Sniffing Risk:** Plaintext HTTP connection attempts on port 80 are vulnerable to man-in-the-middle interception before redirection occurs.

---

## Remediation

- Move management IP to an isolated VLAN (Management VLAN 99).
- Implement switch ACLs / firewall filtering to allow management access only from designated admin subnets or jump boxes.
- Disable Port 80 HTTP web server or enforce strict HSTS headers.
