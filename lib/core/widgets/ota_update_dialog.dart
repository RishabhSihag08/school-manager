import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/core_providers.dart';
import '../services/ota_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bento_card.dart';
import 'tactile_feedback.dart';

/// Modal dialog prompting the user to install a new OTA update.
/// Displays version, release notes, live download progress, and native installer launch.
/// Supports mandatory launch gate where the update must be applied before using the app.
class OtaUpdateDialog extends ConsumerStatefulWidget {
  final OtaReleaseInfo release;
  final bool isMandatory;
  final VoidCallback? onDismiss;

  const OtaUpdateDialog({
    super.key,
    required this.release,
    this.isMandatory = true,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required OtaReleaseInfo release,
    bool isMandatory = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => OtaUpdateDialog(
        release: release,
        isMandatory: isMandatory,
      ),
    );
  }

  @override
  ConsumerState<OtaUpdateDialog> createState() => _OtaUpdateDialogState();
}

class _OtaUpdateDialogState extends ConsumerState<OtaUpdateDialog> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _downloadedApkPath;
  double _progress = 0.0;
  String _statusText = 'Ready to download & install update';

  @override
  void initState() {
    super.initState();
    _checkExistingCachedApk();
  }

  Future<void> _checkExistingCachedApk() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/school-manager-v${widget.release.version}.apk');
      if (await apkFile.exists()) {
        final len = await apkFile.length();
        if (widget.release.apkSizeBytes <= 0 || len >= widget.release.apkSizeBytes - 1024) {
          if (mounted) {
            setState(() {
              _isDownloaded = true;
              _downloadedApkPath = apkFile.path;
              _progress = 1.0;
              _statusText = 'Update APK already downloaded and ready to install.';
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _isDownloaded = false;
      _progress = 0.0;
      _statusText = 'Connecting to release server...';
    });

    final otaService = ref.read(otaUpdateProvider.notifier);
    final success = await otaService.downloadAndInstallUpdate(
      release: widget.release,
      onProgress: (p, received, total) {
        if (mounted) {
          setState(() {
            _progress = p;
            final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
            _statusText = 'Downloading update (${(p * 100).toInt()}% • $mbReceived / $mbTotal MB)...';
          });
        }
      },
    );

    if (mounted) {
      if (success) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/school-manager-v${widget.release.version}.apk';
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _downloadedApkPath = path;
          _statusText = '✨ Download complete! Package installer launched.';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _statusText = 'Download interrupted. Tap below to retry or install via browser.';
        });
      }
    }
  }

  Future<void> _relaunchInstaller() async {
    if (_downloadedApkPath != null) {
      await OtaUpdateService.installApk(_downloadedApkPath!);
    } else {
      _startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMandatory = widget.isMandatory || widget.release.isForced;

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: BentoCard(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sparkle icon & version badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMandatory ? AppColors.coralLight : AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMandatory ? LucideIcons.shieldAlert : LucideIcons.sparkles,
                      color: isMandatory ? AppColors.coralStreak : AppColors.brandPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMandatory ? 'Mandatory Update Required' : 'New Update Available',
                          style: AppTypography.titleLarge.copyWith(
                            color: isMandatory ? AppColors.inkPrimary : AppColors.brandPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.coralLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${widget.release.version}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.coralStreak,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.release.formattedSize,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMandatory && !_isDownloading)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Mandatory explanation banner if applicable
              if (isMandatory) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A critical app update is required to continue using School Manager.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Release title
              Text(
                widget.release.title,
                style: AppTypography.bodySemibold.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Changelog container
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.release.changelog.isNotEmpty
                        ? widget.release.changelog
                        : 'General improvements, persistent login, and performance enhancements for School Manager.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Download progress bar
              if (_isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.secondarySurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.brandPrimary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_isDownloaded) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF065F46),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              if (!_isDownloading) ...[
                if (_isDownloaded) ...[
                  // Primary Action: Launch Package Installer
                  TactileFeedback(
                    onTap: _relaunchInstaller,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.downloadCloud, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Install APK Now',
                            style: AppTypography.buttonLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary Fallback: Install via Browser
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => OtaUpdateService.launchBrowserDownload(widget.release.apkDownloadUrl),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Install via Browser Fallback'),
                    ),
                  ),
                ] else ...[
                  // Initial Download Action
                  Row(
                    children: [
                      if (!isMandatory)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Later'),
                          ),
                        ),
                      if (!isMandatory) const SizedBox(width: 12),
                      Expanded(
                        flex: isMandatory ? 1 : 2,
                        child: TactileFeedback(
                          onTap: _startDownload,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isMandatory ? AppColors.coralStreak : AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isMandatory ? AppColors.coralStreak : AppColors.brandPrimary).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.download, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  isMandatory ? 'Update & Install Now' : 'Update Now',
                                  style: AppTypography.buttonLabel,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => OtaUpdateService.launchBrowserDownload(widget.release.apkDownloadUrl),
                      icon: const Icon(LucideIcons.externalLink, size: 14, color: AppColors.inkMuted),
                      label: Text(
                        'Direct Browser Download',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
