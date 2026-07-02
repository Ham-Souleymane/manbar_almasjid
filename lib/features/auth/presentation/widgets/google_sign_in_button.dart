import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Styled Google Sign-In button with the Google "G" logo rendered via canvas.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'المتابعة عبر Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.charcoal,
          side: const BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleLogo(size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Google "G" logo painted with canvas ──────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // White background
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);

    // ── Draw the four arcs of the Google "G" ─────────────────
    final double strokeW = r * 0.28;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62);

    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // Red (top-right)
    p.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -0.5, 1.6, false, p);

    // Yellow (bottom)
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.1, 1.2, false, p);

    // Green (bottom-right)
    p.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 2.3, 0.9, false, p);

    // Blue (left + top-left)
    p.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 3.2, 1.7, false, p);

    // ── Blue horizontal bar (right side of G) ────────────────
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.62, cy),
      barPaint,
    );

    // White inner circle to create ring effect
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.62 - strokeW / 2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
