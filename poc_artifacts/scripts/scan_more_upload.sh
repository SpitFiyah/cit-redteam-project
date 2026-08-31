#!/bin/bash
COOKIE="citexams_student_session=sqORhvi9INYGUQGnmufBEonBaGXqBEITFJEju1b"
URLS=(
  "https://student.citexams.in/upload"
  "https://student.citexams.in/student"
  "https://student.citexams.in/students"
  "https://student.citexams.in/student-data"
  "https://student.citexams.in/upload-data"
  "https://student.citexams.in/import"
  "https://student.citexams.in/import-student"
  "https://student.citexams.in/student-import"
  "https://student.citexams.in/excel-upload"
  "https://student.citexams.in/upload-excel"
  "https://student.citexams.in/upload-student-excel"
  "https://student.citexams.in/project"
  "https://student.citexams.in/profile"
  "https://student.citexams.in/attendance"
  "https://student.citexams.in/results"
  "https://student.citexams.in/exam-results"
)

for u in "${URLS[@]}"; do
  STATUS=$(proxychains4 curl -sk -o /dev/null -w "%{http_code}" -H "Cookie: ${COOKIE}" "$u")
  echo "$u -> $STATUS"
done
