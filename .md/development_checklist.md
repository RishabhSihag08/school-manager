# School Management App — Execution Checklist

Use this phased checklist to track your progress from zero to handing over the finished project to the school.

---

## Phase 1: Foundation, OTA Updates & Class-Code Onboarding
- [x] Initialize Flutter project with **Android, iOS, and Web** targets enabled.
- [x] Set up folder structure (`core/`, `features/auth`, `features/student`, `features/teacher`, `features/admin`, `features/announcements`).
- [x] Configure Design System (`AppColors`, `AppTypography`, custom Bento card widgets).
- [x] Set up Supabase backend credentials in `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MASTER_KEY=SirChotuRam`).
- [x] **OTA Update Service (`ota_update_service.dart`)**:
  - [x] Configure Shorebird Quick Patch checker and GitHub Releases full APK downloader in `main.dart`.
  - [x] Android `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>` and package archive intent queries added to `AndroidManifest.xml`.
  - [x] Mandatory Launch Update Gate: blocks app access if a newer release exists on GitHub, displays changelog, download progress with MB counter, automatic package installer dispatch, and browser fallback.
  - [x] APK caching: detects existing downloaded APK in cache and installs without redundant re-downloads.
- [x] **Master Administrative Security Key**:
  - [x] Require case-sensitive master key (default `SirChotuRam` stored in `.env`) for creating Teacher and Staff/Admin accounts.
  - [x] Enforced verification in `CreateAccountScreen` before staff accounts can be created.
- [x] **Single Unified Onboarding / Welcome Screen**:
  - [x] Removed redundant intermediate onboarding screen.
  - [x] Unified default landing screen (`WelcomeRoleScreen`) with Instant Class Code Join ticket, Student Roll+PIN login, Faculty portal login, and Create Account entry.
- [x] **Persistent Session Management (`session_service.dart`)**:
  - [x] User sessions (`student`, `teacher`, `admin`) are preserved in `SharedPreferences` across app restarts.
  - [x] App automatically opens directly into `StudentBentoHome`, `TeacherDashboard`, or `AdminShell` without logging the user out on app close.
  - [x] Clean session clearing on explicit "Log Out" or "Switch Role" in Settings, Teacher Dashboard, and Admin Shell.
- [x] **Student "Class Code" Join Flow (No OTP)**:
  - [x] Build **"Join Class with Code"** screen where student pastes the 6-character Class Code (e.g., `8B-K9X2`).
  - [x] Build Student Registration Form (Full Name, Roll Number, Admission No., Parent Name, Parent Mobile, House Color, and 4-digit PIN).
  - [x] Build Returning Student Login (`Class + Roll No + PIN`) with persistent session.
  - [x] Build **Sibling Switcher** so parents can join multiple classes on one phone using each child's Class Code.
- [x] Build **Teacher & Admin Login** with Role Router (`student` -> Student Shell, `teacher` -> Teacher Shell, `admin` -> Admin Responsive Shell).

---

## Phase 2: Class Teacher vs. Subject Teacher & Class Code Management
- [x] Build Admin screen to create `Classes` (1st–12th) and `Sections` (A, B, C, etc.) with auto-generated unique **Class Codes**.
- [x] Build Admin screen to create `Subjects` (Maths, Science, English, Hindi, SST, Computer, etc.).
- [x] **Class Teacher Assignment**: Dropdown on each `ClassSection` to assign exactly one Homeroom Class Teacher.
- [x] **Subject Teacher Matrix**: Multi-select UI where Admin assigns which Teacher teaches which Subject in each `ClassSection` (crucial for 6th–12th).
- [x] **Class Teacher Homeroom Controls**:
  - [x] Shareable **Class Code Banner** (Copy code, Share on WhatsApp, Regenerate code, or Lock code once all students join).
  - [x] Connected Student Roster view (verify joined students and edit roll numbers if a student made a typo).

---

## Phase 3: Daily Attendance, View-Only Timetable & Class Syllabus
- [x] **Daily Attendance Management**:
  - [x] Build **Class Teacher 30-Second Attendance Screen**: All students default to `Present` (Green); tap a student to toggle `Absent` (Red) or `Leave` (Amber) -> 1-tap Submit.
  - [x] Build **Student Attendance Bento Card & Calendar**: Overall Attendance % ring + monthly color-coded calendar (`table_calendar`).
- [x] **View-Only Timetable System**:
  - [x] Build Admin/Class Teacher Timetable entry.
  - [x] Build **Student View-Only Timetable Screen** with Day Tabs (`Mon`–`Sat`), Period numbers, Time slots, Subject pills, and Teacher names.
- [x] **Class & Subject Syllabus System**:
  - [x] Build Teacher/Admin Syllabus uploader (select Class, Subject, Exam Term -> add chapter list + Syllabus PDF).
  - [x] Build **Student Syllabus Vault** filtered by Subject and Exam Term (`UT-1`, `Half Yearly`, `Finals`).

---

## Phase 4: Announcements (Holidays & Circulars) & Multimedia Homework
- [x] **Announcements & Holiday Noticeboard**:
  - [x] Build Admin/Teacher Announcement creator with category badges (`Holiday 🏖️`, `Exam 📝`, `Event 🎉`, `Urgent 🚨`, `Class Notice 📢`) and PDF/Image attachment support.
  - [x] Build **Pinned Holiday/Urgent Banner** on the Student Home Screen + dedicated Announcements Feed.
- [x] **Teacher Multimedia Homework Publisher**:
  - [x] Select Class & Subject (auto-filtered to only the classes/subjects they teach).
  - [x] Add Title, Instructions, Due Date, and attachments (Camera Photo, Gallery Image, PDF, Video/YouTube URL).
- [x] **Unified In-App Media Viewer (Zero External App Redirects)**:
  - [x] **Image Viewer**: Full-screen `PhotoView` with pinch-to-zoom and $90^\circ$ rotation button.
  - [x] **PDF Viewer**: In-app page scroller for Homework PDFs, Syllabus PDFs, and Holiday Circulars.
- [x] **Student Homework Checklist**:
  - [x] Interactive checkbox with haptic feedback + Homework Streak counter.

---

## Phase 5: Excel Result Engine & Interactive Report Cards
- [x] **Result Upload via Excel (Office Staff Priority)**:
  - [x] Create Exam categories (`Unit Test 1`, `Unit Test 2`, `Half Yearly`, `Annual Finals`).
  - [x] Build **"Download Pre-Filled Result Template"** button that exports an `.xlsx` pre-populated with all students joined in that class (ordered by `Roll_No`) and Subject columns.
  - [x] Build **"Upload Result Excel"** parser supporting numeric marks + `'AB'` (Absent) / `'ML'` (Medical Leave) codes.
  - [x] Build **Validation Preview Table** (highlights invalid marks in red before saving).
  - [x] Add **"Publish Results"** toggle.
- [x] **Student Result Dashboard & PDF Report Card**:
  - [x] Exam selector pills (`UT-1`, `Half Yearly`, `UT-2`, `Finals`) with confetti reveal.
  - [x] Overall Summary Card (Total Marks, Percentage, Grade Badge `A1`–`E`) + Subject-wise breakdown + `fl_chart` trend graph.
  - [x] **"Download / Share PDF Report Card"** generator with school header, marks table, and signature blocks.

---

## Phase 6: Testing, Polish & Handover
- [x] Test the complete **Class Code Join -> Attendance -> Homework -> Excel Result Upload -> Student Report Card** loop end-to-end on physical ADB device.
- [x] Upgrade all iconography to `lucide_icons_flutter: ^4.0.3` (zero broken character boxes or missing glyphs).
- [x] Verify zero hardcoded school names (neutral `School Manager` ecosystem).
- [x] Remove all test bypasses and test controls; production ready.
- [x] Publish GitHub Releases with release APK attached (`v1.0.2`).
- [ ] End-to-end verification of Master Key, Single Onboarding, Persistent Session, and Mandatory In-App Update Gate on physical Samsung Galaxy S24.
