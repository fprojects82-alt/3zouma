import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// The signature ring: it fills in saffron around the step number as the
/// step's timer runs, and turns red in the last 10%.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.label,
    required this.progress,
    this.size = 96,
    this.alert = false,
    this.onDark = false,
    this.active = true,
  });

  final String label;

  /// 0 to 1.
  final double progress;
  final double size;
  final bool alert;
  final bool onDark;

  /// When false the ring is drawn as an empty track (a step with no timer).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ink = onDark ? OzColors.linen : OzColors.ink;
    return Semantics(
      label: label,
      value: active ? '${(progress * 100).round()}%' : null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: active ? progress : 0,
            color: alert ? OzColors.alert : OzColors.saffron,
            track: onDark ? Colors.white.withValues(alpha: 0.28) : OzColors.saffronSoft,
            stroke: size * 0.09,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ink,
                    fontSize: size * 0.4,
                    height: 1,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track, required this.stroke});

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.stroke != stroke;
}
