# TODO - Marksheet School Name Update

## Goal
Update marksheet PDF to show the teacher's school name instead of hardcoded "PARAKK SCHOOL".

## Tasks
- [x] 1. Modify MarksheetService.generateMarksheetPDF() to accept schoolName parameter
- [x] 2. Update results_screen.dart to fetch teacher's school name and pass it to PDF generator
- [x] 3. Test the changes (flutter analyze passed)

## Support Screen Fixes
- [x] 4. Add LSApplicationQueriesSchemes to Info.plist for url_launcher
- [x] 5. Add Call Class Teacher option (uses class teacher phone, falls back to admin phone)
- [x] 6. Add Email Class Teacher option
- [x] 7. Fix School Admin call option to show phone number
- [x] 8. Add Email School Admin option

## Details
- Fallback school name: "Study Buddy SCHOOL"
- Use `enteredBy` field from MarksModel to fetch teacher's schoolName

