# JENKINS EXPLOITATION EVIDENCE
## CIT Red Team — Stage 7 PoC Evidence Collection
**Analyst:** AGENT G  
**Date:** 2026-08-31  
**Classification:** RED TEAM INTERNAL — RESTRICTED

---

## EVIDENCE-01: Jenkins Version Confirmation

**Source:** `/home/BlueDragon/jenkins.txt` (CIT Target Intel)

```
Jenkins 2.492.2 core and libraries
    Multiple security vulnerabilities in Jenkins 2.503 and earlier, LTS 2.492.2 and earlier
```

**Source:** `/home/BlueDragon/jenkins_logs.txt` (Stack trace references)
```
Jenkins Main ClassLoader//org.eclipse.jetty.ee9.nested...
java.base/java.lang.Thread.run(Thread.java:1583)
```

**Assessment:** Confirmed Jenkins 2.492.2 LTS running on Jetty EE9 with Java 17+. Multiple unpatched CVEs apply.

---

## EVIDENCE-02: Confirmed Admin Username

**Source:** `jenkins_logs.txt` — Lines 1148 and 1152

```
Aug 14, 2026 5:46:45 PM WARNING hudson.security.csrf.CrumbFilter doFilter

No valid crumb was included in request for /index2.html by admin. Returning 403.

Aug 14, 2026 5:46:47 PM WARNING hudson.security.csrf.CrumbFilter doFilter

No valid crumb was included in request for /VisionHubWebApi/api/Login by admin. Returning 403.
```

**Assessment:** Username `admin` is confirmed active and making API requests as of Aug 14, 2026 at 5:46 PM. The user was accessing non-standard paths including `VisionHubWebApi` endpoint — indicating integration with HP Vision Hub / UCMDB platform.

---

## EVIDENCE-03: CLI Arbitrary File Read Attack (CVE-2024-23897 Pattern)

**Source:** `jenkins_logs.txt` — Lines 1027–1061

```
Aug 14, 2026 5:41:43 PM WARNING hudson.cli.PlainCLIProtocol$FramedReader run

null
org.eclipse.jetty.util.StaticException: Unconsumed request content
Caused: java.io.IOException
    ...
Caused: hudson.cli.DiagnosedStreamCorruptionException
Read back: 0x00 0x00 0x00 0x0e 0x00 0x00 0x0c 'connect-node' 
           0x00 0x00 0x00 0x0e 0x00 0x00 0x0c '@/etc/passwd' 
           0x00 0x00 0x00 0x07 0x02 0x00 0x05 'UTF-8' 
           0x00 0x00 0x00 0x07 0x01 0x00 0x05 'en_AE' 
           0x00 0x00 0x00 0x00 0x03
Read ahead: 
Diagnosis problem:
    java.io.IOException: org.eclipse.jetty.util.StaticException: Unconsumed request content
```

**Assessment:** 
- A prior actor sent Jenkins CLI command: `connect-node @/etc/passwd`
- The `@/etc/passwd` syntax in Jenkins CLI (args4j library) reads file contents as argument input
- Attacker locale: `en_AE` (United Arab Emirates — Arabic/English)
- Encoding: UTF-8
- Jenkins threw `DiagnosedStreamCorruptionException` — stream was corrupted AFTER initial parsing
- File may have been partially read before the exception terminated the stream

---

## EVIDENCE-04: HP UCMDB Path Injection Attempt

**Source:** `jenkins_logs.txt` — Lines 1080–1113

```
Aug 14, 2026 5:46:44 PM WARNING jenkins.security.SuspiciousRequestFilter doFilter

Denying HTTP POST to /ucmdb-ui/cms/loginRequest.do; as it has an illegal semicolon in the path. 
This behavior can be overridden by setting the system property 
jenkins.security.SuspiciousRequestFilter.allowSemicolonsInPath to true. 
For more information, see https://www.jenkins.io/redirect/semicolons-in-urls
```

**Assessment:** External actor attempted HP UCMDB web UI path injection via semicolon in URL. Jenkins `SuspiciousRequestFilter` blocked it. Confirms Jenkins is integrated with or running alongside HP UCMDB.

---

## EVIDENCE-05: Malformed Authentication / Credential Stuffing

**Source:** `jenkins_logs.txt` — Lines 1084–1091

```
Aug 14, 2026 5:46:44 PM WARNING hudson.util.Scrambler descramble

Corrupted data
java.lang.IllegalArgumentException: Last unit does not have enough valid bits
    at java.base/java.util.Base64$Decoder.decode0(Base64.java:872)
    at java.base/java.util.Base64$Decoder.decode(Base64.java:570)
    at hudson.util.Scrambler.descramble(Scrambler.java:50)
    at jenkins.security.BasicHeaderProcessor.doFilter(BasicHeaderProcessor.java:71)
```

**Assessment:** Malformed Base64 credential submitted in HTTP Basic Auth `Authorization` header. Consistent with credential stuffing or brute-force tool generating malformed auth headers. Same session as the UCMDB path injection.

---

## EVIDENCE-06: Jenkins Air-Gap / Network Isolation (Aug 12)

**Source:** `jenkins_logs.txt` — Lines 956–993

```
Aug 12, 2026 2:16:40 PM INFO hudson.util.Retrier start

Attempt #1 to do the action check updates server

The attempt #1 to do the action check updates server failed with an allowed exception:
java.net.UnknownHostException: updates.jenkins.io
    at java.base/sun.nio.ch.NioSocketImpl.connect(NioSocketImpl.java:567)
    ...

Error checking update sites for 1 attempt(s). Last exception was: 
UnknownHostException: updates.jenkins.io
```

**Assessment:** On Aug 12, Jenkins host had no DNS resolution for external hosts — indicates firewall/ACL blocking or air-gapped network. By Aug 13, updates succeeded — network access was restored.

---

## EVIDENCE-07: Active Build Environment Confirmation

**Source:** `jenkins_logs.txt` — Lines 999–1025

```
Aug 13, 2026 12:26:08 PM INFO hudson.util.Retrier start
Attempt #1 to do the action check updates server

Aug 13, 2026 12:26:15 PM INFO hudson.model.DownloadService$Downloadable load
Obtained the updated data file for hudson.tasks.Maven.MavenInstaller

Aug 13, 2026 12:26:17 PM INFO hudson.model.DownloadService$Downloadable load
Obtained the updated data file for hudson.tasks.Ant.AntInstaller

Aug 13, 2026 12:26:18 PM INFO hudson.model.DownloadService$Downloadable load
Obtained the updated data file for hudson.plugins.gradle.GradleInstaller
```

**Assessment:** Maven, Ant, and Gradle build tools are installed and actively maintained. This is an active CI/CD build server — high value target for supply chain attack.

---

## EVIDENCE-08: Windows Host Confirmation via Registry Dump

**Source:** `/home/BlueDragon/jenkins_lateral_movement.txt`

```
HKEY_LOCAL_MACHINE\SECURITY\Cache
    NL$Control    REG_BINARY    040001000A000000
    NL$1          REG_BINARY    000000000000000000000000...
    NL$2          REG_BINARY    000000000000000000000000...
    [NL$3 through NL$10 — all zero-filled]
```

**Assessment:**
- `HKLM\SECURITY\Cache` is a Windows-only registry key — confirms Jenkins host is **Windows**
- `NL$Control` value `0A000000` (little-endian) = decimal 10 = **10 credential cache slots configured**
- All NL$1–NL$10 entries are zero-filled (304 bytes each of `0x00`)
- Zero-fill indicates: either no domain users have authenticated, or cache was cleared/dumped in sanitized form
- The fact that `HKLM\SECURITY` was successfully dumped confirms **SYSTEM-level access** was available at time of collection
- **Action Required:** Re-dump the SECURITY hive live from the host to obtain real cache contents

---

## EVIDENCE-09: Health Checker Overload / Resource Exhaustion

**Source:** `jenkins_logs.txt` — Lines 1–940 (400+ repetitions)

```
Aug 12, 2026 2:16:38 PM INFO jenkins.metrics.api.Metrics$HealthChecker doRun

jenkins.metrics.api.Metrics$HealthChecker thread is still running. Execution aborted.
[repeated 400+ times]
```

**Assessment:** Massive health checker thread starvation. Jenkins is under severe resource contention — system is highly stressed. This creates larger timeout windows and may contribute to race conditions exploitable for CSRF bypass or session fixation.

---

## EVIDENCE-10: Confirmed Plugin Vulnerabilities (No Fixes Applied)

**Source:** `/home/BlueDragon/jenkins.txt`

```
Pipeline: Groovy 4106.v7a_8a_8176d450
    CSRF vulnerability and unrestricted instantiation of types (no fix available)
    No fixes for these issues are available.

Git client plugin 6.1.3
    OS command injection vulnerability on agents (no fix available)

GitHub Branch Source Plugin 1822.v9eec8e5e69e3
    Missing permission check allows enumerating GitHub Enterprise server URLs (no fix available)
    Missing permission check allows performing a connection test (no fix available)
```

**Assessment:** Three plugin vulnerabilities explicitly have **no fix available** and remain permanently exploitable on this instance until plugins are uninstalled.

---

## Evidence Timeline Summary

| Timestamp | Event | Significance |
|-----------|-------|-------------|
| Aug 12, 10:18 AM | HealthChecker flooding begins | System overloaded |
| Aug 12, 2:16 PM | DNS fails for updates.jenkins.io | Network isolated |
| Aug 12, 2:16 PM | Build discarder aborting | Resource exhaustion |
| Aug 13, 12:26 PM | Maven/Ant/Gradle updates succeed | Network restored |
| Aug 14, 12:26 PM | Build tool updates repeated | Active build environment |
| Aug 14, 5:41 PM | CLI @/etc/passwd attack | Prior actor file read attempt |
| Aug 14, 5:41 PM | en_AE locale fingerprint | Attacker geo-fingerprint |
| Aug 14, 5:46 PM | UCMDB path injection attempt | Integration probing |
| Aug 14, 5:46 PM | Malformed Basic Auth | Credential stuffing |
| Aug 14, 5:46 PM | Admin CSRF failures x2 | Admin user confirmed active |

---

## Files Written — Full Path Index

| File | Location | Purpose |
|------|----------|---------|
| `JENKINS_ANALYSIS.md` | `stage7_jenkins/` | Full log + vuln analysis |
| `JENKINS_CVE_CHAIN.md` | `stage7_jenkins/` | CVE exploitation chains |
| `DCACHE_CREDENTIALS.md` | `stage7_jenkins/` | DCC2 registry analysis |
| `jenkins_rce.sh` | `poc_artifacts/scripts/` | PoC exploitation script |
| `jenkins_evidence.md` | `poc_artifacts/evidence/` | This file |
