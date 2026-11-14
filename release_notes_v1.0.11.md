## 🚀 School Manager v1.0.11 — Instant Sync, Offline Barrier & Faculty Management

### 🌟 What's New in v1.0.11

#### ⚡ 1. Seamless Auto-Refresh & Pre-Restored Session
- **Instant Data Loading on Launch**: Fixed the issue where users had to manually refresh the page upon opening the app. Student, teacher, and role sessions are now pre-restored synchronously from local persistence prior to frame rendering and injected via Riverpod overrides.
- **Background Resume Sync**: Added `WidgetsBindingObserver` lifecycle watchers across all core views. Whenever the app resumes from the background or is brought back to focus, dashboard data, attendance, timetable, and syllabus automatically refresh in real time.
- **Coverage**: Applied across **Student Bento Home**, **Teacher Dashboard**, **Admin Shell**, **Results Screen**, **Attendance Calendar**, **Syllabus Vault**, and **Timetable View**.

#### 🌐 2. Dedicated Internet Access Screen & Offline Protection
- **Clear Offline Barrier**: When no active internet connection is available, the app displays a full-screen barrier explicitly stating that internet access is required to operate School Manager.
- **CampusVibe Design**: Styled with `LucideIcons.wifiOff`, subtle background ambiance, and an interactive connection troubleshooting checklist (Wi-Fi, Mobile Data, Airplane mode).
- **Auto-Dismiss & Retry CTA**: Features an interactive **"Retry Connection"** action with real-time feedback. The moment internet connectivity is restored, the barrier automatically dismisses and triggers a data refresh without losing your current navigation state.
- **Robust Probes**: Employs real-world DNS resolution lookups with fallback HTTP 204 connectivity probes.

#### 👨‍🏫 3. Admin Faculty & Teachers Management
- **Full Faculty Directory**: Added the dedicated `AdminTeachersScreen` empowering school administrators to view, search, and filter teachers by department with real-time stats.
- **Complete CRUD Controls**: Add, edit teacher qualifications/subjects, and safely delete faculty profiles with confirmation guards.
- **Database Migrations**: Includes Supabase schema migration scripts for faculty & teacher management.

---

### 🛠️ Stability & Quality Assurance
- 🧪 **73/73 Automated Tests Passing**: Comprehensive test suite covering model serialization, CBSE grading calculations, auth flows, widgets, OTA services, and connectivity lifecycle.
- 📦 **Optimized Release Binary**: Tree-shaken vector icons and compiled with release optimizations for smooth 60 FPS animations.

---

### 📲 Download & Installation
- Download the attached **`school-manager-v1.0.11.apk`** below to install or update.
- Existing installations can also update directly from **Settings > Check for Updates** via the in-app OTA engine.
