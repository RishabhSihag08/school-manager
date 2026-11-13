import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'tactile_feedback.dart';

/// Representation of a media item for the UnifiedMediaViewer
class MediaAttachmentItem {
  final String title;
  final String url;
  final String type; // 'image', 'pdf', 'video', 'document'
  final int? sizeKb;

  const MediaAttachmentItem({
    required this.title,
    required this.url,
    required this.type,
    this.sizeKb,
  });

  factory MediaAttachmentItem.fromJson(Map<String, dynamic> json) {
    return MediaAttachmentItem(
      title: json['title'] ?? json['name'] ?? 'Attachment',
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      sizeKb: json['size_kb'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'type': type,
        if (sizeKb != null) 'size_kb': sizeKb,
      };
}

/// Unified In-App Media Viewer Modal
/// Supports pinch-to-zoom images, 90-degree rotation button, PDF viewing,
/// and smooth carousel transitions with zero external app redirects.
class UnifiedMediaViewer extends StatefulWidget {
  final List<MediaAttachmentItem> items;
  final int initialIndex;

  const UnifiedMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  /// Convenient modal opener
  static Future<void> show(
    BuildContext context, {
    required List<MediaAttachmentItem> items,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: AppMotion.durationModal,
        reverseTransitionDuration: AppMotion.durationFast,
        pageBuilder: (context, animation, secondaryAnimation) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: AppMotion.easeOut,
          );
          return FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: AppMotion.entryInitialScale,
                end: 1.0,
              ).animate(curve),
              child: UnifiedMediaViewer(
                items: items,
                initialIndex: initialIndex,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  State<UnifiedMediaViewer> createState() => _UnifiedMediaViewerState();
}

class _UnifiedMediaViewerState extends State<UnifiedMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  int _rotationQuarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF121214),
        body: Center(
          child: Text(
            'No attachments to preview',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final currentItem = widget.items[_currentIndex];
    final isImage = currentItem.type == 'image';

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0x99121214),
                border: Border(
                  bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  TactileFeedback(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.items.length > 1)
                          Text(
                            '${_currentIndex + 1} of ${widget.items.length}',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Rotate 90 deg button (visible for images)
                  if (isImage) ...[
                    TactileFeedback(
                      onTap: _rotateClockwise,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.rotateCw, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_rotationQuarterTurns * 90}°',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Content Area / Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _rotationQuarterTurns = 0; // reset rotation for next photo
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _buildItemViewer(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemViewer(MediaAttachmentItem item) {
    if (item.type == 'image') {
      ImageProvider provider;
      if (item.url.startsWith('http')) {
        provider = NetworkImage(item.url);
      } else {
        final localFile = File(item.url);
        if (localFile.existsSync()) {
          provider = FileImage(localFile);
        } else {
          provider = AssetImage(item.url);
        }
      }

      return Center(
        child: RotatedBox(
          quarterTurns: _rotationQuarterTurns,
          child: PhotoView(
            imageProvider: provider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3.0,
            backgroundDecoration: const BoxDecoration(
              color: Color(0xFF121214),
            ),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
              ),
            ),
            errorBuilder: (context, error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.imageOff, color: Colors.white38, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load image\n(${item.title})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (item.type == 'pdf') {
      return PdfPreview(
        build: (format) async {
          if (item.url.startsWith('http')) {
            final res = await http.get(Uri.parse(item.url));
            if (res.statusCode == 200) {
              return res.bodyBytes;
            }
          } else {
            final localFile = File(item.url);
            if (localFile.existsSync()) {
              return await localFile.readAsBytes();
            }
          }
          // Return a placeholder demo PDF if network is offline
          return _generateDemoPdfBytes(item.title);
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        actions: const [],
        loadingWidget: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
          ),
        ),
        onError: (context, error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.fileText, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(
                'PDF Preview: ${item.title}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    } else {
      // Generic document / Video link
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.file, color: AppColors.brandPrimary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: ${item.url}',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<Uint8List> _generateDemoPdfBytes(String title) async {
    // Basic fallback PDF generation
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'School Management Portal',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  title,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Academic Session 2026-2027 • Official Document',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
    return await doc.save();
  }
}
