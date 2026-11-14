# School Manager v1.0.12 Release Notes 🚀

**Release Date:** November 14, 2026  
**Build:** `1.0.12+12`

---

## ⚡ Instant Auto-Sync on Launch & Offline Access Barrier (v1.0.12)

This release addresses two critical user experience improvements: eliminating the need for manual pull-to-refresh on startup through synchronous session restoration and lifecycle observers, and introducing a dedicated offline barrier screen that clearly communicates internet requirements and provides instant reconnection actions.

### 1. 🔄 Seamless Auto-Refresh & Pre-Restored Persistent Session
- **Zero-Latency Launch Data**: Resolved the bug where opening the app required a manual pull-to-refresh because data did not automatically deep-load.
- **Synchronous Session Pre-Restoration**: Student and staff login sessions are pre-restored from `SharedPreferences` in `main()` before `runApp()`, injecting initialized `currentStudentProvider`, `currentStaffProvider`, and `activeRoleProvider` states on frame 1.
- **Lifecycle Resume Sync**: Registered `WidgetsBindingObserver` lifecycle watchers across all core views (`AppLifecycleState.resumed`), automatically triggering background data refreshes when returning to the app without requiring user gesture.
- **Universal Coverage**: Implemented across **Student Bento Home**, **Teacher Dashboard**, **Admin Shell**, **Results Screen**, **Attendance Calendar**, **Syllabus Vault**, and **Timetable View**.

### 2. 🌐 Dedicated Internet Access Screen & Offline Protection
- **Clear Offline Barrier**: When internet connectivity is absent or lost, the app gracefully overlays a full-screen barrier explicitly stating that internet access is required to use School Manager.
- **CampusVibe Bento Aesthetics**: Styled with `LucideIcons.wifiOff`, subtle background ambiance, and an interactive connection troubleshooting checklist (Wi-Fi, Mobile Data, Airplane mode).
- **Auto-Dismiss & State Retention**: Wired into `MaterialApp.router`'s root builder as a floating overlay. The user's active page and navigation stack are fully preserved. As soon as internet connectivity returns, the barrier automatically dismisses and triggers a data refresh.
- **Interactive Retry CTA**: Features an interactive **"Retry Connection"** action with real-time feedback and dual DNS resolution/HTTP 204 network probes.

---

# School Manager v1.0.11 Release Notes 🚀

**Release Date:** November 13, 2026  
**Build:** `1.0.11+11`

---

## 👩‍🏫 Admin Faculty & Teachers Management Console Release (v1.0.11)

This release introduces comprehensive teacher and faculty administration directly within the School Manager Admin Console, empowering administrators to view, search, filter, register, completely edit, and safely delete teacher accounts with automatic relationship cleanup.

### 1. 🗂️ Faculty & Teachers Directory Screen (`AdminTeachersScreen`)
- **Dual-Mode Architecture**: Embedded directly into the desktop/web `AdminShell` left navigation drawer and available as an independent route (`/admin/teachers`).
- **Live Faculty Statistics**: Real-time summary strip featuring Total Faculty count, Class In-Charge homeroom count, and Subject Specialists count.
- **Search & Filter Engine**: Instant search across teacher names, login codes (`T-101`), phone numbers, subjects, and homeroom classes, paired with quick-filter chips (`All Teachers`, `Class In-Charge`, `Subject Specialists`).
- **Tactile Teacher Bento Cards**:
  - Teacher avatar with initials and active status badge.
  - Monospace login code pill and Security PIN with tap-to-reveal toggle.
  - Homeroom In-Charge amber badge linking directly to class sections.
  - Primary Subject Specialization pill with icon and subject code.
  - Teaching class allocation badges with multi-class chips.
  - Fast tactile `Edit` button and red destructive `Delete` action.

### 2. ✏️ Complete Teacher Profile Editing & Deletion
- **Edit Everything Modal**:
  - Full Name, Login Code, Security PIN, Phone Number, and Optional Email.
  - Homeroom Class In-Charge assignment with automatic synchronization to `class_sections` (unassigning prior classes to prevent orphaned class teachers).
  - Primary Subject Specialization with instant subject code binding.
  - Teaching Class Allocations with multi-select class chips.
- **Irreversible Account Deletion with Safeguards**:
  - Destructive confirmation dialog detailing consequences before removal.
  - Automatic cascade cleanup: removes teacher from all subject allocations and unassigns them from homeroom class sections (`classTeacherId: null`).
  - Seamless fallback and zero orphaned records across database and memory states.

### 3. ➕ Smart Teacher Registration
- **Smart Code Suggestion**: Auto-increments next available faculty login code (e.g., `T-101`, `T-102`).
- **One-Tap PIN Generator**: Generates random 4-digit security PIN for instant onboarding.
- **Instant Allocation**: Assigns homeroom and subject teaching classes right at registration.

### 4. 📐 Continuous Impeccable Layout Polish
- Fixed horizontal wrapping in teacher syllabus header cards and title editor cards.
- Enhanced `ClassSection.copyWith(clearClassTeacher: true)` ensuring reliable homeroom clearing.
- Verified 69/69 automated test suites passing with 0 analyzer issues.

---

# School Manager v1.0.10 Release Notes 🚀

**Release Date:** November 13, 2026  
**Build:** `1.0.10+10`

---

## 🎨 UI/UX Ergonomic Refinements & Layout Polish Release (v1.0.10)

This release delivers comprehensive UI/UX ergonomic enhancements and layout fixes across all mobile screen resolutions (360dp–390dp), informed directly by visual layout audits.

### 1. 📐 Anti-Warping & Layout Boundary Optimization
- **Single-Line Attendance Metric**: Wrapped attendance percentages and titles in responsive `FittedBox` containers, completely eliminating multi-line word breaks ("Attendan ce").
- **Timetable Section Re-architected**: Relocated the `Uploaded (Document)` / `Default Schedule Active` badge beneath class titles into its own row, eliminating horizontal title squeezing.
- **Academic Quick Bar Sizing**: Fine-tuned icon and typography scales (`11.5sp`) so "Timetable", "Syllabus", and "Notices" render without truncation.
- **Mission Streak Badge Constrained**: Applied flex boundaries to the "Today's Homework Mission" header so the streak flame badge never overflows off the right edge.
- **Syllabus Header & Action Alignment**: Converted syllabus title and chapter actions to flexible horizontal wraps with compact "Save" and "Add Chapter" actions, preventing button push-outs.
- **Admin Student Directory Records**: Converted student metadata into flexible chips and streamlined "Edit" action buttons to prevent overlapping with roll numbers and contact details.

### 2. 📱 Clean Input Fields & Production Onboarding
- **Demo Access Removed**: Removed "QUICK DEMO ACCESS" banner and demo auto-fill buttons from `WelcomeRoleScreen` and `JoinClassCodeScreen`.
- **Zero Prefilled Fields**: All input controllers (PINs, codes, titles, marks) start empty with intuitive placeholder hints.
- **Excel Wizard Preset Chips**: Exam maximum marks chips (`20`, `25`, `40`, `50`, `80`, `100`) wrap cleanly across rows without running off the right screen border; maximum marks input initializes clean.

### 3. 🎯 Homework Cards & Interactive Expanded View
- **Clean Description Card**: Replaced dark chalkboard styling with a clean, light-mode `BentoCard` matching application typography and design tokens.
- **Concise Media Badges**: Homework feeds now display clean summary chips (`📄 1 PDF`, `🖼️ 1 Photo`, `▶️ 1 Video`) instead of raw technical filenames.
- **Interactive Expanded Homework Sheet**: Tapping any homework card opens an expanded modal bottom sheet with full task descriptions, direct attachment previews in `UnifiedMediaViewer`, and one-tap completion toggles.

### 4. ⚡ Padding & Dialog Ergonomics
- **Dense Tactile Geometry**: Reduced default `BentoCard` padding from 16dp to 13dp and standard screen horizontal margins from 20dp down to 14dp, maximizing content density on mobile displays.
- **Clean Update Screen**: Removed changelog release notes box from `OtaUpdateDialog`, presenting a focused, streamlined update experience.
- **Monthly Attendance Milestone**: Adjusted percentage and compliance badge layouts to guarantee zero overlap with the 75% CBSE milestone ring.

---

# School Manager v1.0.9 Release Notes 🚀

**Release Date:** November 13, 2026  
**Build:** `1.0.9+9`

---

## 🎨 Complete UI/UX Overhaul & Tactile Craft Release (v1.0.9)

### 1. 🌟 Impeccable Design System & Surface Hierarchy
- **4-Tier Surface Tokens**: Soft Sand Canvas (`#F7F6F2`), Pure White Bento Cards (`#FFFFFF`), Soft Sand Input Fill (`#EFECE6`), and Frosted Glass Overlays (`rgba(255, 255, 255, 0.85)`).
- **Emil Kowalski Tactile Motion**: Responsive `0.97` press scale, custom cubic curves (`Cubic(0.23, 1.0, 0.32, 1.0)`), durations strictly $\le 300\text{ ms}$, and zero `scale(0)`.
- **Accessible Motion Gating**: Seamlessly falls back to instantaneous transitions when system `prefers-reduced-motion` is enabled.
- **Enhanced Role Tokens**: Added `accentStreak` (`#FF6B4A`), `accentStem` (`#7C3AED` Electric Violet), and `accentAchievement` (`#F59E0B` Golden Topaz).

### 2. 🚀 Zero-OTP Onboarding & Gateway Redesign
- **3-Role Gateway**: Elevated `WelcomeRoleScreen` with 3 tactile Bento cards (Student & Parent, Faculty, Admin), demo login shortcuts, and $48\times 48\text{ dp}$ touch targets.
- **Class Code Ticket (`8B-K9X2`)**: Upper ticket section with JetBrains Mono auto-formatting boxes, dashed perforation divider with edge notches, and instant sliding Emerald celebration banner on validation.
- **iOS-Style Sibling Switcher**: Smooth bottom drawer (`AppMotion.easeDrawer`) with active child indicator and instant profile switching.
- **Reusable `AppEmptyState`**: Replaces blank list states with friendly illustrations, contextual copy, and primary action buttons.

### 3. 📱 Student Bento & Academic Hub
- **Asymmetric Bento Grid**: Top full-width "Today's Homework Mission" card with animated progress bar and glowing streak badge (`🔥 4 Day Streak`).
- **Middle Bento Row**: Interactive Attendance Ring ($92.4\%$) and Latest Exam Hub card (`88.4% • Grade A1`).
- **Interactive Homework Feed**: Filtered subject pills, media chips (`📄 1 PDF`, `🖼️ 2 Photos`), and springy bouncy checkboxes with animated strikethrough.
- **Academic Suite**: Color-coded Monthly Attendance Calendar, Timeline Timetable with lunch break separators, Syllabus Vault with accordion topics, and printable CBSE Report Card modal preview.

### 4. 👩‍🏫 Teacher Faculty Portal & 30-Second Roll Call
- **Gear 1 (Homeroom Pinned Banner)**: Midnight to Electric Indigo gradient banner with gold crown badge, 6-character shareable join code, lock code toggle, and live roster count.
- **Gear 2 (Allocated Subject Classes)**: Responsive grid with student counts and instant `+ Homework`, `Syllabus`, and `Marks` action pills.
- **30-Second Attendance Roll Call**: 3-column student cards defaulting to Green Present; 1 tap toggles to Red Absent, long-press toggles to Amber Leave with tactile spring bounce and sticky bottom summary bar.
- **Chalkboard Homework Creator**: Quick template chips (+ Question Numbers, + Notebook Check, + Formulas) and cellular-optimized multi-media upload chips.

### 5. 🏢 Office Administration & Excel Processing
- **Responsive Admin Shell**: Desktop sidebar and mobile drawer with real-time class metrics and school circular broadcaster.
- **3-Step Excel Wizard**: Pre-formatted `.xlsx` template generator, drag-and-drop parser supporting numbers, `'AB'`, and `'ML'`, and interactive DataGrid validation with CBSE 8-tier auto-grade publishing.

---

## 🛠️ Verification
- **`flutter analyze`**: 0 issues found across all packages.
- **`flutter test`**: 64/64 unit, widget, and motion tests passing.

---

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
