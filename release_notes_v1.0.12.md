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
