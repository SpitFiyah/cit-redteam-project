#!/usr/bin/env python3
"""
TP-Link CPE510 (10.10.9.252) PharOS Security Audit Script
Automated check for unauthenticated metadata disclosure and SSH hostkey algorithms.
"""

import sys
import json
import urllib3
import requests
import asyncssh
import asyncio

urllib3.disable_warnings()

TARGET = "10.10.9.252"

def check_web_metadata():
    print(f"[*] Auditing Web API endpoints on http://{TARGET}/...")
    endpoints = ["version.json", "sysmod.json", "configState.json"]
    for ep in endpoints:
        url = f"http://{TARGET}/data/{ep}"
        try:
            r = requests.get(url, timeout=4)
            if r.status_code == 200:
                print(f"[!] VULNERABLE SEC-01: Unauthenticated endpoint {url} exposed!")
                data = r.json()
                print(f"    - Device: {data.get('devInfo')} (Ver: {data.get('devVer')})")
                print(f"    - Operating Mode: {data.get('mode')}")
                print(f"    - Internal IP: {data.get('ip')}")
                print(f"    - Admin User: {data.get('username')}")
                print(f"    - Failed Login Count: {data.get('failedCount')}")
            else:
                print(f"[+] Endpoint {url} returned HTTP {r.status_code} (Secured)")
        except Exception as e:
            print(f"[-] Error querying {url}: {e}")

async def check_ssh_hostkey():
    print(f"\n[*] Auditing SSH Host Key algorithms on {TARGET}:22...")
    try:
        async with asyncssh.connect(TARGET, known_hosts=None, login_timeout=4) as conn:
            pass
    except (asyncssh.Error, Exception) as e:
        print(f"[!] SEC-02 / SEC-03 Identified: SSH Connection result -> {type(e).__name__}: {e}")

def main():
    check_web_metadata()
    asyncio.run(check_ssh_hostkey())

if __name__ == "__main__":
    main()
