# School Manager v1.0.0 — Official Release

**School Manager** is a modern, high-craft, production-grade school management platform tailored for Indian schools (Grades 1 to 12). Built with Flutter, Supabase, and Riverpod, it replaces legacy spreadsheet-style school portals with warm tactile Bento grids, instant Class Code onboarding, a 30-second attendance engine, and an automated CBSE report card generator.

---

## 🚀 Key Highlights & Capabilities

### 1. Dual-Layer OTA (Over-The-Air) Update Architecture
- **Layer 1: Quick Patch Engine (Shorebird Code Push)**: Instant in-app Dart hotfixes delivered silently in the background without requiring APK reinstallation or administrative approval.
- **Layer 2: Full Version Engine (GitHub Releases API)**: Direct standalone APK release distribution with streaming download progress, byte counter, and native Android package installer launch via `open_filex`.

### 2. Zero-OTP "Class Code" Onboarding (Google Classroom Style)
- Replaces SMS/OTP friction with unique 6-character alphanumeric Class Join Codes (e.g., `8B-K9X2`).
- Real-time class verification banner (*"🎉 Found Class 8-B • Class Teacher: Ramesh Sharma"*).
- Profile setup with 4 house shields: **Red Ruby**, **Blue Sapphire**, **Green Emerald**, and **Yellow Topaz**, plus a 4-digit secret PIN.
- **Sibling Switcher**: Parents with multiple children can link all siblings on a single device and switch between them in one tap.

### 3. Student Bento Experience
- Asymmetric Warm Alabaster (`#F7F6F2`) Bento grid designed for Indian sunlight visibility.
- **Today's Homework Mission**: Live daily progress bar and homework completion streaks.
- **Attendance Progress Ring**: Circular indicator with CBSE $\ge 75\%$ compliance indicator linking to a monthly colored calendar.
- **Interactive Homework Feed**: Subject pastel pills, multimedia attachments (PDFs, photos, concept videos), and bouncy completion checkboxes.

### 4. Teacher 2-Gear Dashboard & 30-Second Roll Call
- **Gear 1 (Homeroom)**: Class 8-B banner with shareable join code, lock controls, roster modal, and class announcements.
- **30-Second Roll Call**: 3-column student grid defaulting to Green Present; 1 tap toggles Red Absent, long-press toggles Amber Leave; sticky bottom summary with 1-tap submission.
- **Gear 2 (Subject Classes)**: Multi-class allocation grid (`6-A Maths`, `8-B Maths`, etc.) with quick actions for homework publishing and syllabus updates.

### 5. Office 3-Step Excel Wizard & CBSE Report Cards
- **Step 1 (Download Template)**: Dynamically generates `.xlsx` templates pre-filled with enrolled students in `Roll_No` order and allocated subject columns.
- **Step 2 (Upload Excel)**: High-speed parser supporting numbers, `'AB'` for Absent, and `'ML'` for Medical Leave with automatic whitespace trimming.
- **Step 3 (Validate & Publish)**: Interactive validation DataGrid highlighting invalid cells in red with instant inline corrections.
- **CBSE 8-Tier Automatic Grading**: Computes $A_1$ (91–100%), $A_2$ (81–90%), $B_1$ (71–80%), $B_2$ (61–70%), $C_1$ (51–60%), $C_2$ (41–50%), $D$ (33–40%), and $E$ (<33%).
- **Official Printable A4 Report Cards**: Generates CBSE-compliant PDFs with school letterhead, student profile matrix, marks table, teacher remarks, and signature blocks.

### 6. Design & Motion Engineering (Emil Kowalski Philosophy)
- Custom cubic curves: `easeOut` $\text{Cubic}(0.23, 1.0, 0.32, 1.0)$, `easeInOut`, and `easeDrawer`.
- Tactile press feedback: subtle $0.97$ scale with $140\text{ ms}$ response and haptics.
- Strictly **no** $\text{scale}(0)$; all modal entrances use $0.95$ initial scale + opacity.
- Accessible reduced-motion gating: automatically disables position animations and collapses durations to zero when requested.

---

## 📦 Distribution Artifacts
- **APK**: `campusvibe-v1.0.0.apk` / `app-release.apk`
- **Minimum Android SDK**: API 21 (Android 5.0 Lollipop)
- **Target Android SDK**: API 34 (Android 14)
