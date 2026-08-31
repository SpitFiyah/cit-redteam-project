# JENKINS ANALYSIS REPORT
## CIT Red Team — Stage 7 Jenkins Exploitation
**Analyst:** AGENT G — Jenkins & CI/CD Exploitation Specialist  
**Date:** 2026-08-31  
**Classification:** RED TEAM INTERNAL — RESTRICTED

---

## 1. Jenkins Instance Intelligence

### 1.1 Version Identification
- **Jenkins Core Version:** `2.492.2` (LTS)
- **Host:** Internal network — confirmed via log hostname resolution failures against `updates.jenkins.io`
- **Web Server:** Jetty (Eclipse Jetty EE9 — confirmed via stack traces in logs)
- **JDK:** Java base module references indicate Java 17+ (Thread.java:1583)

### 1.2 Target URLs Probed
| URL | Port | Status |
|-----|------|--------|
| `http://10.10.9.208:8080/` | 8080 | Primary candidate — standard Jenkins port |
| `http://10.10.9.208:80/` | 80 | Secondary candidate |
| `http://68.178.173.154:8080/` | 8080 | External IP candidate |

### 1.3 Log File Analysis — Key Findings

**Log Timeframe:** Aug 12–14, 2026 (10:18 AM – 5:46 PM)

#### Confirmed Usernames from Logs
| Username | Source | Notes |
|----------|--------|-------|
| `admin` | Lines 1148, 1152 | CSRF filter denials — active admin account confirmed |

#### Attack Activity Observed in Logs (Pre-Existing / Prior Actor)
**Line 1045 — CLI Path Traversal Attack Evidence:**
```
Read back: 0x00 0x00 0x00 0x0e 0x00 0x00 0x0c 'connect-node' 0x00 0x00 0x00 0x0e 0x00 0x00 0x0c '@/etc/passwd' ...
```
- **CRITICAL**: Someone already attempted a CLI `connect-node @/etc/passwd` path traversal attack
- Attack vector: Jenkins CLI `PlainCLIProtocol` — reading `/etc/passwd` via node connection parameter
- The `@<filename>` syntax in Jenkins CLI reads file contents as parameter input
- Consistent with **CVE-2024-23897** (Jenkins arbitrary file read via CLI)
- Attack was **partially mitigated** — `DiagnosedStreamCorruptionException` thrown but file content may have been partially read before stream corruption
- **Attacker locale fingerprint: `en_AE`** (UAE locale identified in CLI packet at line 1045)

**Lines 1080–1082 — Path Injection Attempt:**
```
Denying HTTP POST to /ucmdb-ui/cms/loginRequest.do; as it has an illegal semicolon in the path.
```
- External actor probing `/ucmdb-ui/cms/loginRequest.do` — HP UCMdb path injection attempt
- `SuspiciousRequestFilter` blocked semicolon in URL path

**Lines 1084–1091 — Authentication Corruption / Credential Stuffing:**
```
Corrupted data — java.lang.IllegalArgumentException: Last unit does not have enough valid bits
```
- Malformed Base64 credential in HTTP Basic Auth header — possible brute-force or credential stuffing
- Triggered by same request session as ucmdb path injection

**Lines 1146–1152 — CSRF Token Failures by Admin:**
```
No valid crumb was included in request for /index2.html by admin. Returning 403.
No valid crumb was included in request for /VisionHubWebApi/api/Login by admin. Returning 403.
```
- `admin` user making requests without valid CSRF crumbs — suggests automated tooling or API token misuse
- Targets: `/index2.html` and `/VisionHubWebApi/api/Login` — non-standard paths
- `VisionHubWebApi` confirms HP Vision Hub / UCMDB integration with this Jenkins host

#### Infrastructure Indicators
- **Lines 956–981:** `UnknownHostException: updates.jenkins.io` — Jenkins had **no direct internet access** on Aug 12 (air-gapped or firewall-restricted)
- **Lines 999–1013:** Update check succeeded on Aug 13 — network restored or proxy re-enabled
- **Build Tools Confirmed Active:** Maven (`hudson.tasks.Maven.MavenInstaller`), Ant (`hudson.tasks.Ant.AntInstaller`), Gradle (`hudson.plugins.gradle.GradleInstaller`)
- **Hudson Background Jobs:** `Periodic background build discarder` running — active build environment

#### HealthChecker Flood (Lines 1–940)
- `jenkins.metrics.api.Metrics$HealthChecker` repeatedly aborting — 400+ repetitions across log
- Indicates severe resource contention or health check deadlock — system under heavy load
- **Exploitation implication:** Overloaded system → timeout-based CSRF bypass windows more likely

### 1.4 Inferred Jenkins Workspace / Build Context
- Maven, Ant, Gradle installers active → Java build environment
- `DailyCheck` executor present → scheduled pipeline jobs running
- `hudson.model.AsyncPeriodicWork` → background job executor confirmed

---

## 2. Vulnerability Summary — Confirmed Installed Components

| Plugin/Component | Version | Issue | Severity | Fix Available |
|-----------------|---------|-------|----------|---------------|
| Jenkins Core | 2.492.2 | Multiple security vulns (pre-auth RCE) | **CRITICAL** | Not applied |
| LDAP Plugin | 780.vcb_33c9a_e4332 | RCE via unvalidated LDAP referrals | **CRITICAL** | Not applied |
| Pipeline: Groovy | 4106.v7a_8a_8176d450 | CSRF + unrestricted type instantiation | **CRITICAL** | **NO FIX** |
| Pipeline: Groovy Libraries | 752.vdddedf804e72 | Arbitrary file read (symlinks) | HIGH | Not applied |
| Script Security Plugin | 1373.vb_b_4a_a_c26fa_00 | Sandbox bypass (multiple) | **CRITICAL** | Not applied |
| Git client plugin | 6.1.3 | OS command injection on agents | **CRITICAL** | Partial (**NO FIX** for one) |
| Credentials Binding Plugin | 687.v619cb_15e923f | Path traversal + improper masking | HIGH | Not applied |
| Email Extension Plugin | 1876.v28d8d38315b_d | Arbitrary file read | HIGH | Not applied |
| Matrix Authorization Strategy | 3.2.6 | Unsafe deserialization | HIGH | Not applied |
| Jakarta Mail API | 2.1.3-2 | SMTP command injection | MEDIUM | Not applied |
| GitHub Branch Source | 1822.v9eec8e5e69e3 | Permission check bypass (2x) | MEDIUM | **NO FIX** |
| GitHub Plugin | 1.43.0 | XSS | MEDIUM | Not applied |

---

## 3. Attack Surface Assessment

### Priority Attack Vectors (Ranked)
1. **Script Console RCE** — If admin session obtainable → direct Groovy execution → OS command injection
2. **CLI File Read (CVE-2024-23897 pattern)** — Already observed in logs; `@/etc/passwd` via `connect-node`
3. **Pipeline: Groovy CSRF + Type Instantiation** — No fix available; craft pipeline to instantiate arbitrary types
4. **LDAP Plugin RCE** — Trigger LDAP referral to attacker-controlled LDAP server
5. **Script Security Sandbox Bypass** — Execute arbitrary Java via crafted Groovy in sandboxed pipelines
6. **Matrix Auth Deserialization** — Send crafted serialized object via Matrix plugin endpoint
7. **Email Extension Arbitrary File Read** — Read sensitive files via email template injection

### Session/Auth Context
- `admin` user confirmed active (CSRF log entries Aug 14)
- CSRF protection active but admin bypassing via direct API requests
- Malformed Basic Auth observed → credential stuffing attempt from prior actor

---

## 4. Network Topology Inference

```
[External Actor / en_AE locale]
         |
         v
[68.178.173.154:8080] ← Possible external-facing Jenkins
         |
    (NAT/Proxy?)
         |
         v
[10.10.9.208:8080] ← Internal Jenkins LTS 2.492.2 (Jetty/Java 17)
         |
    [Windows Host] ← Registry dump indicates Windows OS
         |
    [Domain-joined] ← HKLM\SECURITY\Cache NL$1-10 entries present
         |
    [HP UCMDB/Vision Hub integration] ← /VisionHubWebApi/api/Login in logs
         |
    [Build Targets] ← Maven/Ant/Gradle build environment
```

---

## 5. Files Referenced
- `JENKINS_CVE_CHAIN.md` — Full exploitation methodology
- `DCACHE_CREDENTIALS.md` — Domain-cached credential analysis  
- `poc_artifacts/scripts/jenkins_rce.sh` — PoC shell script
- `poc_artifacts/evidence/jenkins_evidence.md` — Evidence collection
