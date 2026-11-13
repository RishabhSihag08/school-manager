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
