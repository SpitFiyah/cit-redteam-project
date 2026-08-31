#!/bin/bash
COOKIE="citexams_student_session=sqORhvi9INYGUQGnmufBEonBaGXqBEITFJEju1b"
URLS=(
  "https://student.citexams.in/project/index"
  "https://student.citexams.in/project/create"
  "https://student.citexams.in/project/upload"
  "https://student.citexams.in/attendance/view"
  "https://student.citexams.in/course-registration/history"
  "https://student.citexams.in/exam-application/history"
  "https://student.citexams.in/revaluation"
  "https://student.citexams.in/challenge-revaluation"
  "https://student.citexams.in/photocopy-request"
  "https://student.citexams.in/igrade"
  "https://student.citexams.in/notification"
  "https://student.citexams.in/feedback"
  "https://student.citexams.in/settings"
)

for u in "${URLS[@]}"; do
  STATUS=$(proxychains4 curl -sk -o /dev/null -w "%{http_code}" -H "Cookie: ${COOKIE}" "$u")
  echo "$u -> $STATUS"
done
