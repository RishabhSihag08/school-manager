import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/ota_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bento_card.dart';
import 'tactile_feedback.dart';

/// Modal dialog prompting the user to install a new OTA update.
/// Displays version, release notes, live download progress, and installer launch.
class OtaUpdateDialog extends ConsumerStatefulWidget {
  final OtaReleaseInfo release;
  final VoidCallback? onDismiss;

  const OtaUpdateDialog({
    super.key,
    required this.release,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required OtaReleaseInfo release,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !release.isForced,
      builder: (context) => OtaUpdateDialog(release: release),
    );
  }

  @override
  ConsumerState<OtaUpdateDialog> createState() => _OtaUpdateDialogState();
}

class _OtaUpdateDialogState extends ConsumerState<OtaUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Ready to download';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Connecting to release server...';
    });

    final otaService = OtaUpdateService();
    final success = await otaService.downloadAndInstallUpdate(
      release: widget.release,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _progress = p;
            _statusText = 'Downloading update (${(p * 100).toInt()}%)...';
          });
        }
      },
    );

    if (mounted) {
      if (success) {
        setState(() {
          _statusText = 'Download complete! Launching package installer...';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _statusText = 'Failed to download update. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Update Available',
                        style: AppTypography.titleLarge,
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
                if (!widget.release.isForced && !_isDownloading)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Release title
            Text(
              widget.release.title,
              style: AppTypography.bodySemibold.copyWith(
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Changelog container
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
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
                      : 'General improvements and performance enhancements for School Manager.',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),

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
            ],

            // Action Buttons
            if (!_isDownloading)
              Row(
                children: [
                  if (!widget.release.isForced)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Later'),
                      ),
                    ),
                  if (!widget.release.isForced) const SizedBox(width: 12),
                  Expanded(
                    flex: widget.release.isForced ? 1 : 2,
                    child: TactileFeedback(
                      onTap: _startDownload,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.release.isForced
                              ? 'Required Update • Install'
                              : 'Update Now',
                          style: AppTypography.buttonLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
