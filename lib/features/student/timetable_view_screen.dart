import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/unified_media_viewer.dart';

class TimetableViewScreen extends ConsumerStatefulWidget {
  final String? classSectionId;
  const TimetableViewScreen({super.key, this.classSectionId});

  @override
  ConsumerState<TimetableViewScreen> createState() =>
      _TimetableViewScreenState();
}

class _TimetableViewScreenState extends ConsumerState<TimetableViewScreen> {
  bool _isLoading = true;
  String? _className;
  String? _timetableFileUrl;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final currentStudent = ref.read(currentStudentProvider);
    final classId =
        widget.classSectionId ?? currentStudent?.classSectionId ?? '';

    if (classId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final cls = await repo.getClassSectionById(classId);

    if (!mounted) return;
    setState(() {
      _className = cls?.displayName;
      _timetableFileUrl = cls?.timetableFileUrl;
      _isLoading = false;
    });
  }

  void _openFullScreenViewer() {
    if (_timetableFileUrl == null || _timetableFileUrl!.isEmpty) return;
    UnifiedMediaViewer.show(
      context,
      items: [
        MediaAttachmentItem(
          title: _className != null
              ? '$_className Timetable'
              : 'Class Timetable',
          url: _timetableFileUrl!,
          type: 'image',
        ),
      ],
    );
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  ImageProvider _resolveImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    final file = File(url);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        _timetableFileUrl != null && _timetableFileUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          _className != null ? '$_className Timetable' : 'Class Timetable',
          style: AppTypography.titleLarge,
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.studentHome);
            }
          },
        ),
        actions: [
          if (hasPhoto) ...[
            IconButton(
              icon: const Icon(LucideIcons.rotateCw, size: 20),
              tooltip: 'Rotate 90°',
              onPressed: _rotateImage,
            ),
            IconButton(
              icon: const Icon(LucideIcons.maximize2, size: 20),
              tooltip: 'Full Screen',
              onPressed: _openFullScreenViewer,
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandPrimary,
                ),
              )
            : !hasPhoto
                ? _buildEmptyState()
                : _buildPhotoViewer(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.secondarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.calendarOff,
                  size: 40,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Timetable Uploaded Yet',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The school administration has not uploaded the timetable photo for your class yet.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoViewer() {
    return Column(
      children: [
        // Helper pill bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.zoomIn,
                size: 14,
                color: AppColors.inkSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Pinch to zoom • Double tap to expand',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Photo view with pinch-to-zoom
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: RotatedBox(
                quarterTurns: _rotationQuarterTurns,
                child: PhotoView(
                  imageProvider: _resolveImageProvider(_timetableFileUrl!),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  initialScale: PhotoViewComputedScale.contained,
                  backgroundDecoration: const BoxDecoration(
                    color: AppColors.cardSurface,
                  ),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.imageOff,
                          color: AppColors.inkMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load timetable image',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
