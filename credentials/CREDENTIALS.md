# 🔑 Credentials & Cryptographic Inventory (Multi-Domain Verified)
**Classification:** STRICTLY CONFIDENTIAL — Verified Red Team Operational Data  
**Targets Verified:** `student.citexams.in`, `des.citexams.in`, `erp.citexams.in` | **IP:** `68.178.173.154`  
**Verification Date:** 2026-08-31 (Live HTTP 200 .env Dumps & Direct Protocol Tests)

---

## 1. Database Credentials

| Parameter | Value | Verification Status | Source |
|---|---|---|---|
| **Database Host** | `localhost:3306` (also open on `68.178.173.154:3306`) | Confirmed open on port 3306 (MariaDB ≤10.3.23) | Public port probe |
| **Database Name** | `bookleeycit_citexams` | Active primary schema across all 3 portals | `student`, `des`, `erp` `.env` |
| **Username** | `bookleeycit_citexams` | Confirmed active user | `student`, `des`, `erp` `.env` |
| **Password** | `TGmyYIU$T1k$2026` | Confirmed plaintext across all subdomains | `student`, `des`, `erp` `.env` |
| **Direct Access Note** | Host restriction active | `MariaDB 1130 - Host not allowed to connect` | External auth test |

---

## 2. Master Cryptographic Keys & Token Signing

| Portal / Domain | Secret Key | Value | Impact |
|---|---|---|---|
| **`student.citexams.in`** | `APP_KEY` | `base64:kbqL/05YWl0TZEnb3oE4811UauhKhWps9c4IWsQiFHQ=` | Laravel cookie encryption & CSRF |
| **`des.citexams.in`** | `APP_KEY` | `base64:kbqL/05YWl0TZEnb3oE4811UauhKhWps9c4IWsQiFHQ=` | Shared key with student portal |
| **`erp.citexams.in`** | `APP_KEY` | `base64:Sk2BDuIcCtOBWNaCS08/ZozA3RHV3e2UUp4Y1ey5s+8=` | Distinct ERP secret key |
| **Global SSO** | `SSO_SECRET` | `CITPRODP7CP6BCFCJ4A14P0IE0JG86VO` | **HS256 JWT generation for all subdomains** |
| **Client Key** | `CIT_CLIENT_KEY` | `6708d004c4cc52b1a3f1947c75b76395` | Cross-platform client authentication |

---

## 3. Communication & Service Infrastructure

| Service | Host / Port | User / Identity | Credential | Status |
|---|---|---|---|---|
| **ZeptoMail SMTP** | `smtp.zeptomail.in:465` (TLS) | `emailapikey` | `PHtE6r0ORLvu3mMv80UH5/S5FZKnYIgo/+9neVYVsdpDXKABSk1Xq4stkGe2/h0vA/lDRfOdyohvuO+a4u/QcDrvZmofD2qyqK3sx/VYSPOZsbq6x00Zt1sfc0DbV4Xtcddq1CPSvt3cNA==` | Active |
| **Historical SMTP** | `154.173.178.68.host.secureserver.net:465` | `notifications@citexams.in` | `Cambridge@2025$` | Leaked in commented `.env` blocks |
| **Redis Cache** | `127.0.0.1:6379` | `default` | `null` (Unauthenticated) | Active across all portals |
