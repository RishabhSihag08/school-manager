# School Manager v1.0.8 Release Notes 🚀

**Release Date:** November 13, 2026  
**Build:** `1.0.8+8`

---

## 🎯 What's New & Fixed in v1.0.8

### 1. 🕒 Announcement Date & Timestamp Display (Admin Portal)
- All announcements displayed in the Admin Portal now prominently feature their exact publication date and time formatted in standard Indian format (`dd MMM yyyy, hh:mm a`).
- Added expiration countdown indicators (`Expires: dd MMM yyyy, hh:mm a` or a red `EXPIRED` badge).

### 2. ⏳ Auto-Expiring Announcements
- Added an **"Expires In"** dropdown menu during announcement creation across Admin and Faculty portals:
  - Options: `Never (No Expiry)`, `1 Day`, `2 Days`, `3 Days`, `7 Days`, `14 Days`, and `30 Days`.
  - Automatically calculates and stores `expires_at` timestamp.
  - **Student Portal**: Automatically filters out expired announcements so students never see obsolete circulars.
  - **Admin & Faculty Portals**: Staff can still see expired announcements with an `EXPIRED` status badge for administrative record keeping.

### 3. 🎯 Multi-Scope Faculty Announcements
- Teachers can now broadcast announcements with customizable scope:
  - **Whole School (All Classes)**: Broadcasts to every student across the entire school.
  - **Class in Charge (Homeroom)**: Target only the specific class the teacher is in charge of.
  - **Classes You Teach**: Dynamic dropdown allowing the teacher to target any of their assigned subject classes.

### 4. 🛡️ Role-Based Announcement Deletion Guard
- Added permission guard: Faculty members are strictly prohibited from deleting Admin-issued circulars.
- Admin circulars displayed in the Faculty Portal show an immutable `[Admin Notice]` pill instead of the delete trash action icon.
- Teachers can still delete circulars published by themselves.

### 5. 🏷️ Removed Forced "Holiday Circular" Category Tag
- Fixed bug where every notice was forced into `[🏖️ HOLIDAY CIRCULAR]`.
- Circulars now default to **General Notice** (`📢 SCHOOL NOTICE`), with full category selection:
  - `General Notice 📢`, `Holiday 🏖️`, `Exam Alert 📝`, `Event 🎉`, and `Urgent 🚨`.
  - Clean target badge display (`🌍 Whole School`, `🏫 Class in Charge`, or specific class name).

### 6. 🔄 Faculty Announcement Supabase Persistence Fix
- Resolved database rejection where camelCase Dart enum values (`classNotice`) conflicted with PostgreSQL snake_case enum values (`class_notice`).
- Added `category.toDbCategory` converter for 100% reliable Supabase persistence and instant reactive UI reflection.

### 7. 📎 Genuine Real Media Attachments for Homework
- Purged dummy preset demo attachment options from the Homework Publisher.
- Integrated genuine device file picking:
  - **+ Photo**: Native device image picker via `FilePicker` (`FileType.image`).
  - **+ PDF Doc**: Native document picker filtering for `.pdf` files (`FileType.custom`).
  - **+ Video**: Interactive modal with options to enter a web/YouTube video URL or pick a video file directly from the device.
- Attached media chips are interactive and can be tapped immediately to preview via the `UnifiedMediaViewer`.

---

## 🛠️ Verification
- **`flutter analyze`**: 0 issues found across all files.
- **`flutter test`**: 61/61 unit, widget, and service tests passing.

---

# School Manager v1.0.7 Release Notes 🚀

**Release Date:** November 13, 2026  
**Build:** `1.0.7+7`

---

## 🎯 What's New & Fixed in v1.0.7

### 1. ⚡ Admin Console Persistence & Supabase RLS Migration
- **Root Cause Resolved**: Fixed database persistence where class section addition and deletion, student registrations, and announcements did not persist across sessions due to missing `anon` RLS policies and empty-list fallback revival.
- **SQL Migration Script (`supabase/v1_0_7_rls_and_fixes.sql`)**: Provides full CRUD policies for all tables, adds cascading deletes on `class_section_id`, and configures active academic year.
- **Immediate Reactive UI**: Class section addition and deletion immediately update Admin Console state and persist permanently in the database.

### 2. 📱 Class Cards Responsive Layout Fix ("Bus Card")
- Replaced overflow-prone single-row action button groups with responsive `Wrap` layouts.
- Dynamic padding and typography scaling prevent card elements from clipping on small screens (< 400px mobile displays).

### 3. 👥 Student Directory Full Roster Sync
- Admin Student Directory now queries the complete school student body via `getAllStudents()` instead of looping per-class.
- Newly registered students immediately appear in the Admin records screen without showing "no student is found".

### 4. 📊 Dynamic Subject Allocation Matrix
- Purged all hardcoded dummy matrix classes (`8-B`, `6-A`, `7-C`) and placeholder faculty names.
- Renders dynamically from the school's actual class roster and faculty allocations.
- Displays clear, italicized **"Not allocated"** badges for any subject without an assigned master.

### 5. 🧹 Complete Project-Wide Dummy Data Purge
- Deleted initial dummy classes (`8-B`, `6-A`, `7-C`).
- Purged all hardcoded names and placeholder references (`Mr. Ramesh Sharma`, `teacher-ramesh`, `dummy.pdf`, `ADM2026101`, etc.) across all screens, drawers, dialogs, PDFs, and services.
- Clean initial state for fresh school deployments.

### 6. 📝 Enhanced Excel Results Wizard
- **Custom Exam Names**: Added text input for custom and unit tests not present in standard presets.
- **Dynamic Maximum Marks**: Added numeric input and quick-select chips (`20`, `25`, `40`, `50`, `80`, `100`).
- **Subject Filtering**: Multi-select FilterChips with "Select All" and "Clear All" to select specific subjects for each examination.
- **Declaration Date**: Built-in date picker to declare and record the official result publication date.

### 7. 📅 Month & Academic Year Transition Resiliency
- Dynamic April-to-March Indian academic year calculation (`AppConfig.currentAcademicYear`) replacing hardcoded strings.
- Attendance calendar bounds dynamically calculate across $\pm 2$ years (`DateTime.now().year \pm 2`) to prevent app breaks during month or year rollovers.

### 8. 📢 Announcements Hub Instant Reflection
- Newly published announcements are immediately added to the top of the "Previous Announcements" list without requiring a manual refresh or re-login.

### 9. 🖼️ Timetable Preview Fix
- Uploaded timetable photos are now copied into persistent application storage (`timetables/timetable_<classId>.<ext>`).
- Image viewer seamlessly resolves local file paths via `FileImage` alongside network URLs, preventing "Unable to load timetable image" errors.

---

## 🛠️ Verification
- **`flutter analyze`**: 0 issues found across all files.
- **`flutter test`**: 60/60 unit, widget, and service tests passing.
