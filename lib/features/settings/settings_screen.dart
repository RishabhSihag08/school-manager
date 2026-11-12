import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ota_update_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final otaState = ref.watch(otaUpdateProvider);
    final otaService = ref.read(otaUpdateProvider.notifier);
    final reduceMotion = ref.watch(reduceMotionProvider);
    final currentStudent = ref.watch(currentStudentProvider);
    final currentStaff = ref.watch(currentStaffProvider);
    final activeRole = ref.watch(activeRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Settings & Updates', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              if (activeRole == 'student') {
                context.go(AppRoutes.studentHome);
              } else if (activeRole == 'teacher') {
                context.go(AppRoutes.teacherDashboard);
              } else {
                context.go(AppRoutes.adminDashboard);
              }
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // School Info Card
              _buildSchoolInfoCard(),

              const SizedBox(height: 20),

              // Active User & Session Profile
              _buildActiveSessionCard(currentStudent, currentStaff, activeRole),

              const SizedBox(height: 20),

              // Over-The-Air (OTA) Software Update Hub
              _buildGitHubReleaseCard(otaState, otaService),

              const SizedBox(height: 20),

              // Accessibility & Display Preferences
              _buildAccessibilityCard(reduceMotion),

              const SizedBox(height: 20),

              // App Architecture & Version Badge
              _buildSystemInfoCard(),

              const SizedBox(height: 20),

              // Prominent Log Out
              _buildLogoutButton(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoCard() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.school,
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unified Digital Campus System',
                      style: GoogleFonts.inter(
                        color: AppColors.inkSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoMiniPill('Academic Year', AppConfig.currentAcademicYear),
              _infoMiniPill('Syllabus Format', 'CBSE / NCERT'),
              _infoMiniPill('Grade Span', 'Grades 1 – 12'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoMiniPill(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionCard(
    dynamic currentStudent,
    Map<String, dynamic>? currentStaff,
    String activeRole,
  ) {
    String name = 'Guest User';
    String roleDetail = 'Not Signed In';
    Color roleColor = AppColors.brandPrimary;
    Color roleBg = AppColors.brandPrimaryLight;

    if (activeRole == 'student' && currentStudent != null) {
      name = currentStudent.fullName;
      roleDetail = 'Student • Roll #${currentStudent.rollNo}';
      roleColor = AppColors.brandPrimary;
      roleBg = AppColors.brandPrimaryLight;
    } else if (activeRole == 'teacher' && currentStaff != null) {
      name = currentStaff['full_name'] ?? 'Teacher';
      roleDetail = 'Faculty • ${currentStaff['subject_name'] ?? currentStaff['homeroom_class_name'] ?? 'Instructor'}';
      roleColor = const Color(0xFF059669);
      roleBg = const Color(0xFFECFDF5);
    } else if (activeRole == 'admin') {
      name = 'Principal Office';
      roleDetail = 'School Administrator';
      roleColor = const Color(0xFF7C3AED);
      roleBg = const Color(0xFFF5F3FF);
    }

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleBg,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: GoogleFonts.plusJakartaSans(
                color: roleColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  roleDetail,
                  style: GoogleFonts.inter(
                    color: AppColors.inkSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TactileFeedback(
            onTap: () => SessionService.confirmAndLogout(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.logOut, size: 14, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    'Log Out',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.danger.withValues(alpha: 0.3),
      onTap: () => SessionService.confirmAndLogout(context, ref),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.logOut, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Text(
            'Log Out of School Manager',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubReleaseCard(
    OtaUpdateState state,
    OtaUpdateService service,
  ) {
    final release = state.availableRelease;
    final hasUpdate = release != null;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      borderColor: hasUpdate ? AppColors.coralStreak : AppColors.cardBorder,
      borderWidth: hasUpdate ? 1.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasUpdate ? AppColors.coralLight : AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.download,
                        color: hasUpdate ? AppColors.coralStreak : AppColors.inkSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Software Update',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasUpdate ? AppColors.coralLight : AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasUpdate ? 'Update Available ✨' : 'Up to Date ✅',
                  style: GoogleFonts.inter(
                    color: hasUpdate ? AppColors.coralStreak : AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Current Version: ',
                style: AppTypography.bodySmall,
              ),
              Text(
                'v${AppConfig.currentVersion}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasUpdate) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version v${release.version}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      Text(
                        release.formattedSize,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    release.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    release.changelog,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading update bundle...',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        '${(state.downloadProgress * 100).toInt()}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.downloadProgress > 0 ? state.downloadProgress : null,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (state.totalBytes > 0)
                    Text(
                      '${(state.bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB of ${(state.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (state.localApkPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'APK downloaded ready to install!',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF065F46),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TactileFeedback(
              onTap: state.isDownloading
                  ? null
                  : () {
                      service.downloadAndInstallUpdate(release: release);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: state.isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.download,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.localApkPath != null
                                  ? 'Launch Native Installer'
                                  : 'Download & Install v${release.version}',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ] else ...[
            TactileFeedback(
              onTap: state.isChecking
                  ? null
                  : () async {
                      await service.checkForUpdates();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandPrimary),
                ),
                child: Center(
                  child: state.isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.refreshCw,
                              color: AppColors.brandPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check for Updates',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibilityCard(bool reduceMotion) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.accessibility,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text('Motion & Accessibility', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reduce Motion', style: AppTypography.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Disables scaling and spring animations for vestibular comfort.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reduceMotion,
                activeTrackColor: AppColors.brandPrimary,
                onChanged: (val) {
                  ref.read(reduceMotionProvider.notifier).state = val;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Information', style: AppTypography.titleSmall),
          const SizedBox(height: 10),
          _sysRow('Installed Version', 'v${AppConfig.currentVersion}'),
          _sysRow('Build Number', '#${AppConfig.currentBuildNumber}'),
          _sysRow('Framework', 'Flutter 3.x • Dart 3.x'),
          _sysRow('State Management', 'Riverpod 2.6 • GoRouter 14.8'),
          _sysRow('Design Language', 'School Manager Warm Tactile Bento'),
        ],
      ),
    );
  }

  Widget _sysRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.inkPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
