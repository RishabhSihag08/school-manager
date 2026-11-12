# School Manager 🏫

> **Modern, High-Craft Indian School Management System**  
> Designed for Grades 1–12 with tactile Bento grids, instant Class Code onboarding, 30-second attendance, 3-step Excel exam processing, official CBSE printable PDF report cards, and a dual-layer OTA patch engine.

---

## 🌟 Architecture & Features

### 1. Dual-Layer OTA Update Engine
To enable zero-friction deployment to school administrators and parents without requiring app store re-certification for minor hotfixes:
- **Layer 1: Shorebird Code Push**: Delivers instant in-app Dart patches on app startup without rebuilding or re-downloading APK binaries.
- **Layer 2: GitHub Releases API**: Checks for full APK binary updates via GitHub API, downloads with live streaming byte progress, and launches the native Android installer.

### 2. Zero-OTP "Class Code" Onboarding
- Replaces SMS OTPs with unique 6-character alphanumeric join codes (e.g. `8B-K9X2`).
- Real-time verification banner confirms class and class teacher name on entry.
- 4 Indian school house shields: **Red Ruby**, **Blue Sapphire**, **Green Emerald**, and **Yellow Topaz**.
- Sibling Switcher allows parents with multiple children to switch profiles in one tap.

### 3. Student Bento Experience
- Asymmetric Warm Alabaster (`#F7F6F2`) Bento grid.
- **Today's Homework Mission**: Live daily progress bar and completion streaks.
- **Attendance % Ring**: Circular progress ring linked to a color-coded monthly attendance calendar.
- **Academic Quick Bar**: Direct access to View-Only Timetable, Syllabus Vault, and Holiday Announcements.
- **Interactive Homework Feed**: Filtered by subject pills with in-app Unified Media Viewer for photos, PDFs, and concept videos.

### 4. Teacher 2-Gear Dashboard
- **Gear 1 (Homeroom)**: Class 8-B banner with shareable join code, lock toggle, roster viewer, and class notice broadcaster.
- **30-Second Roll Call**: Fast 3-column student grid defaulting to Green Present; 1 tap toggles Red Absent, long press toggles Amber Leave; sticky bottom summary and instant submission.
- **Gear 2 (Subject Allocations)**: Multi-class allocation grid (`6-A Maths`, `8-B Maths`, etc.) with quick homework and syllabus management.

### 5. Office 3-Step Excel Wizard & CBSE Report Cards
- **Step 1 (Download Template)**: Exports `.xlsx` pre-filled with enrolled students in `Roll_No` order and subject columns.
- **Step 2 (Upload Excel)**: High-speed parser supporting numbers, `'AB'` (Absent), and `'ML'` (Medical Leave).
- **Step 3 (Validate & Publish)**: Interactive validation DataGrid with error cell highlighting and inline correction.
- **CBSE 8-Tier Automatic Grading**: Computes $A_1$, $A_2$, $B_1$, $B_2$, $C_1$, $C_2$, $D$, and $E$.
- **Printable A4 Report Cards**: Generates official CBSE-compliant PDFs with school letterhead, marks table, teacher remarks, and signature blocks.

---

## 🎨 Design System & Motion Philosophy

- **Canvas Background**: Warm Alabaster `#F7F6F2`
- **Card Surface**: Pure White `#FFFFFF` with $1\text{px}$ subtle border `#E6E4DD`
- **Primary Brand Ink**: Electric Indigo `#4F46E5`
- **Streak & Alert Pop**: CoVibe Coral `#FF6B4A`
- **Typography**:
  - Headings & Display: `Plus Jakarta Sans`
  - Body & Instructions: `Inter`
  - Monospace Data (Codes, Roll Nos, Marks): `JetBrains Mono`
- **Motion Engineering (Emil Kowalski Tokens)**:
  - Custom Cubic Curves: `easeOut = Cubic(0.23, 1.0, 0.32, 1.0)`, `easeInOut`, `easeDrawer`.
  - Durations strictly $\le 300\text{ ms}$ for responsive tactile feel.
  - Tactile Press: subtle $0.97$ scale with $140\text{ ms}$ response and haptics.
  - Strictly **no** $\text{scale}(0)$ anywhere.
  - Reduced-motion gating respects system accessibility preferences.

---

## 🛠️ Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.24+ recommended, Dart 3.5+)
- Android SDK (API level 21+)
- GitHub CLI (`gh`) for automated releases

### Setup & Run
```bash
cd school_manager
flutter pub get
flutter run
```

### Run Tests & Analysis
```bash
# Static analysis (0 warnings, 0 errors)
flutter analyze

# Complete test suite (40+ unit, service, widget, and motion tests)
flutter test
```

### Build Production APK
```bash
flutter build apk --release
```
The output APK is generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Publishing GitHub Release
```powershell
# Using the bundled PowerShell automation script
.\scripts\publish_release.ps1 -Version "1.0.0" -Tag "v1.0.0" -Title "School Manager v1.0.0"
```
Or via GitHub CLI directly:
```bash
gh release create v1.0.0 build/app/outputs/flutter-apk/app-release.apk \
  --title "School Manager v1.0.0 - Official Release" \
  --notes-file RELEASE_NOTES.md
```
