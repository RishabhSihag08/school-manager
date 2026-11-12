import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Modern educational vector logo for School Manager.
/// Features a CustomPainter rendering an Electric Indigo shield,
/// modern graduation cap, open book of knowledge, and a golden excellence star.
class SchoolManagerLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;

  const SchoolManagerLogo({
    super.key,
    this.size = 64.0,
    this.showText = false,
    this.subtitle,
  });

  /// Horizontal variant with icon + title + subtitle
  static Widget horizontal({
    double iconSize = 44.0,
    String? subtitle = 'Modern Indian School System',
    TextStyle? titleStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SchoolManagerLogo(size: iconSize),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Manager',
              style: titleStyle ??
                  GoogleFonts.plusJakartaSans(
                    fontSize: iconSize * 0.45,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.3,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: iconSize * 0.26,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final crest = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SchoolManagerLogoPainter(),
      ),
    );

    if (!showText) return crest;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        crest,
        const SizedBox(height: 12),
        Text(
          'School Manager',
          style: GoogleFonts.plusJakartaSans(
            fontSize: max(16.0, size * 0.28),
            fontWeight: FontWeight.w800,
            color: AppColors.inkPrimary,
            letterSpacing: -0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: max(12.0, size * 0.18),
              fontWeight: FontWeight.w500,
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SchoolManagerLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final scale = min(w, h) / 512.0;

    canvas.save();
    // Center within available bounds
    canvas.translate((w - 512 * scale) / 2, (h - 512 * scale) / 2);
    canvas.scale(scale);

    // 1. Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x331E1B4B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final outerPath = Path()
      ..moveTo(256, 44)
      ..cubicTo(370, 44, 430, 90, 430, 190)
      ..cubicTo(430, 320, 330, 410, 256, 464)
      ..cubicTo(182, 410, 82, 320, 82, 190)
      ..cubicTo(82, 90, 142, 44, 256, 44)
      ..close();
    canvas.drawPath(outerPath.shift(const Offset(0, 8)), shadowPaint);

    // 2. Shield Body with Gradient
    final shieldShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
    ).createShader(const Rect.fromLTWH(82, 44, 348, 420));

    final shieldPaint = Paint()
      ..shader = shieldShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, shieldPaint);

    // 3. Inner Subtle Glow Border
    final innerPath = Path()
      ..moveTo(256, 66)
      ..cubicTo(350, 66, 408, 105, 408, 194)
      ..cubicTo(408, 304, 318, 386, 256, 436)
      ..cubicTo(194, 386, 104, 304, 104, 194)
      ..cubicTo(104, 105, 162, 66, 256, 66)
      ..close();

    final glowPaint = Paint()
      ..color = const Color(0x66818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(innerPath, glowPaint);

    // 4. Graduation Cap (Mortarboard)
    // Skull Base
    final capBase = Path()
      ..moveTo(180, 189)
      ..lineTo(180, 230)
      ..cubicTo(180, 265, 332, 265, 332, 230)
      ..lineTo(332, 189)
      ..lineTo(256, 220)
      ..close();
    final capBasePaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawPath(capBase, capBasePaint);

    // Top Rhombus
    final capTop = Path()
      ..moveTo(256, 120)
      ..lineTo(376, 170)
      ..lineTo(256, 220)
      ..lineTo(136, 170)
      ..close();
    final capTopPaint = Paint()..color = Colors.white;
    canvas.drawPath(capTop, capTopPaint);

    // Cap Tassel & Golden Button
    final goldShader = const LinearGradient(
      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    ).createShader(const Rect.fromLTWH(240, 160, 150, 100));

    final goldPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(256, 170), 9, goldPaint);

    final tasselPath = Path()
      ..moveTo(256, 170)
      ..quadraticBezierTo(370, 185, 375, 245);
    final tasselLinePaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tasselPath, tasselLinePaint);

    final tasselEnd = RRect.fromRectAndRadius(
      const Rect.fromLTWH(371, 245, 8, 20),
      const Radius.circular(3),
    );
    canvas.drawRRect(tasselEnd, goldPaint);

    // 5. Open Book
    // Left Page
    final leftPage = Path()
      ..moveTo(252, 295)
      ..cubicTo(212, 282, 152, 286, 142, 298)
      ..cubicTo(138, 302, 138, 368, 138, 374)
      ..cubicTo(152, 362, 212, 358, 252, 374)
      ..close();
    canvas.drawPath(leftPage, Paint()..color = Colors.white);

    // Right Page
    final rightPage = Path()
      ..moveTo(260, 295)
      ..cubicTo(300, 282, 360, 286, 370, 298)
      ..cubicTo(374, 302, 374, 368, 374, 374)
      ..cubicTo(360, 362, 300, 358, 260, 374)
      ..close();
    canvas.drawPath(rightPage, Paint()..color = const Color(0xFFF8FAFC));

    // Spine
    final spinePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(256, 293), const Offset(256, 380), spinePaint);

    // Page Lines
    final pageLinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(162, 316), const Offset(232, 308), pageLinePaint);
    canvas.drawLine(const Offset(162, 334), const Offset(232, 326), pageLinePaint);
    canvas.drawLine(const Offset(162, 352), const Offset(216, 345), pageLinePaint);

    canvas.drawLine(const Offset(280, 308), const Offset(350, 316), pageLinePaint);
    canvas.drawLine(const Offset(280, 326), const Offset(350, 334), pageLinePaint);
    canvas.drawLine(const Offset(280, 345), const Offset(334, 352), pageLinePaint);

    // 6. Golden Excellence Star
    final star = Path()
      ..moveTo(256, 396)
      ..lineTo(262, 408)
      ..lineTo(275, 410)
      ..lineTo(265, 420)
      ..lineTo(268, 433)
      ..lineTo(256, 427)
      ..lineTo(244, 433)
      ..lineTo(247, 420)
      ..lineTo(237, 410)
      ..lineTo(250, 408)
      ..close();
    canvas.drawPath(star, goldPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
