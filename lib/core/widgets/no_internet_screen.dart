import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bento_card.dart';
import 'tactile_feedback.dart';

/// Full-screen barrier shown whenever no internet connection is detected.
/// States clearly that internet access is required to use the School Manager app
/// and provides a live retry mechanism.
class NoInternetScreen extends ConsumerStatefulWidget {
  const NoInternetScreen({super.key});

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final notifier = ref.read(connectivityStatusProvider.notifier);
    final isOnline = await notifier.checkConnectivity();

    if (mounted) {
      setState(() {
        _isChecking = false;
        if (!isOnline) {
          _statusMessage = 'Still unable to reach internet. Please check your Wi-Fi or mobile data.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prominent Wifi-Off Icon Badge
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.coralLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.coralStreak.withOpacity(0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.coralStreak.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.wifiOff,
                        size: 44,
                        color: AppColors.coralStreak,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Headline
                  Text(
                    'Internet Access Needed',
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mandatory Internet Access Statement
                  Text(
                    'Internet access is required to use School Manager. '
                    'An active network connection is needed to sync homework, attendance, class timetables, and school announcements.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bento Information Card
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.info,
                              size: 18,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How to reconnect:',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTipRow(
                          icon: LucideIcons.wifi,
                          title: 'Check Wi-Fi or Mobile Data',
                          desc: 'Ensure your Wi-Fi router or cellular data is turned on.',
                        ),
                        const SizedBox(height: 12),
                        _buildTipRow(
                          icon: LucideIcons.plane,
                          title: 'Turn Off Airplane Mode',
                          desc: 'Make sure Airplane mode is disabled in your device settings.',
                        ),
                        const SizedBox(height: 12),
                        _buildTipRow(
                          icon: LucideIcons.refreshCw,
                          title: 'Tap Retry Below',
                          desc: 'Once connected, tap the button to automatically restore your session.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.coralStreak.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 18,
                            color: AppColors.coralStreak,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.coralStreak,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  TactileFeedback(
                    onTap: _isChecking ? null : _handleRetry,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isChecking ? null : _handleRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.refreshCw, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Retry Connection',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceField,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
