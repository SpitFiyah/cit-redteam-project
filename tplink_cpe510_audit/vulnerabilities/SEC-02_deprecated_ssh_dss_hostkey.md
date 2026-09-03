# SEC-02: Deprecated SSH Host Key Algorithm (`ssh-dss`)

## Metadata Overview
- **Vulnerability ID:** SEC-02
- **Severity:** Medium (CVSS 5.3)
- **Vector:** `CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:L/A:N`
- **Target Component:** SSH Server (Dropbear 2016.74 on Port 22)
- **Affected Host:** `10.10.9.252`

---

## Technical Description

The SSH service running on port 22 strictly offers `ssh-dss` (Digital Signature Algorithm with 1024-bit key size) for host key authentication. DSA keys of 1024 bits are cryptographic legacy algorithms that have been deprecated across OpenSSH, IETF standards, and NIST guidelines due to weak collision resistance and vulnerability to cryptographic key recovery attacks when private key signatures share nonces.

### Empirical OpenSSH Negotiation Failure

```bash
ssh admin@10.10.9.252
```

**Output:**
```
Unable to negotiate with 10.10.9.252 port 22: no matching host key type found. Their offer: ssh-dss
```

---

## Security Impact

1. **Cryptographic Degradation:** DSA 1024-bit host keys do not meet modern security baseline standards (minimum RSA 2048-bit or Ed25519).
2. **Administrative Access Friction:** Modern SSH clients disable `ssh-dss` by default, forcing operators to explicitly enable insecure algorithms or use custom legacy clients.
3. **Man-in-the-Middle Risk:** Insecure host keys expose SSH management traffic to potential decryption or spoofing by network-adjacent attackers.

---

## Remediation

- Re-generate host keys on the device using RSA (>= 2048-bit) or Ed25519 algorithms.
- Disable `ssh-dss` support in Dropbear configuration.
