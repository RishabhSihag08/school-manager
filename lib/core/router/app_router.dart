import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/auth/create_account_screen.dart';
import '../../features/auth/join_class_code_screen.dart';
import '../../features/auth/welcome_role_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/student/student_attendance_calendar_screen.dart';
import '../../features/student/student_bento_home.dart';
import '../../features/student/student_results_screen.dart';
import '../../features/student/syllabus_vault_screen.dart';
import '../../features/student/timetable_view_screen.dart';
import '../../features/teacher/teacher_dashboard.dart';
import '../../features/teacher/mark_attendance_screen.dart';
import '../../features/teacher/create_homework_screen.dart';
import '../../features/teacher/teacher_syllabus_screen.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/admin/excel_upload_wizard.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bento_card.dart';

/// School Manager Route Path Constants
class AppRoutes {
  static const String onboarding = '/';
  static const String createAccount = '/create-account';
  static const String welcome = '/welcome';
  static const String joinClass = '/join-class';
  static const String studentHome = '/student';
  static const String studentAttendance = '/student/attendance';
  static const String studentTimetable = '/student/timetable';
  static const String studentSyllabus = '/student/syllabus';
  static const String studentResults = '/student/results';

  static const String teacherDashboard = '/teacher';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherCreateHomework = '/teacher/homework/new';
  static const String teacherSyllabus = '/teacher/syllabus';

  static const String adminDashboard = '/admin';
  static const String adminExcelWizard = '/admin/excel-wizard';

  static const String settings = '/settings';
}

/// Fallback / Shell view shown for routes until custom views are displayed
class RoutePlaceholderView extends ConsumerWidget {
  final String title;
  final String routePath;
  final IconData icon;
  final String description;

  const RoutePlaceholderView({
    super.key,
    required this.title,
    required this.routePath,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text(title, style: AppTypography.titleLarge),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BentoCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.brandPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            routePath,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BentoCard(
                padding: const EdgeInsets.all(16),
                child: Text(description, style: AppTypography.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Global GoRouter provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const WelcomeRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        name: 'createAccount',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'student';
          return CreateAccountScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinClass,
        name: 'joinClass',
        builder: (context, state) => const JoinClassCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'studentHome',
        builder: (context, state) => const StudentBentoHome(),
      ),
      GoRoute(
        path: AppRoutes.studentAttendance,
        name: 'studentAttendance',
        builder: (context, state) => const StudentAttendanceCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTimetable,
        name: 'studentTimetable',
        builder: (context, state) => const TimetableViewScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentSyllabus,
        name: 'studentSyllabus',
        builder: (context, state) => const SyllabusVaultScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentResults,
        name: 'studentResults',
        builder: (context, state) => const StudentResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherDashboard,
        name: 'teacherDashboard',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: AppRoutes.teacherAttendance,
        name: 'teacherAttendance',
        builder: (context, state) => const MarkAttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherCreateHomework,
        name: 'teacherCreateHomework',
        builder: (context, state) => const CreateHomeworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherSyllabus,
        name: 'teacherSyllabus',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TeacherSyllabusScreen(
            classSectionId: extra['class_section_id'] as String? ?? 'class-8b',
            className: extra['class_name'] as String? ?? 'Class 8-B',
            subjectName: extra['subject_name'] as String? ?? 'Mathematics',
            subjectCode: extra['subject_code'] as String? ?? 'MATH',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.adminExcelWizard,
        name: 'adminExcelWizard',
        builder: (context, state) => const ExcelUploadWizard(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
