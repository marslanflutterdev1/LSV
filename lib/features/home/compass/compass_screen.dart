import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';

import '../../../core/theme/custom_colors.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

String getCardinalDirection(double heading) {
  if (heading >= 337.5 || heading < 22.5) {
    return 'N';
  }
  if (heading >= 22.5 && heading < 67.5) {
    return 'NE';
  }
  if (heading >= 67.5 && heading < 112.5) {
    return 'E';
  }
  if (heading >= 112.5 && heading < 157.5) {
    return 'SE';
  }
  if (heading >= 157.5 && heading < 202.5) {
    return 'S';
  }
  if (heading >= 202.5 && heading < 247.5) {
    return 'SW';
  }
  if (heading >= 247.5 && heading < 292.5) {
    return 'W';
  }
  return 'NW';
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Compass',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: CustomColors.primaryColor,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => BottomNavBarScreen()),
                (r) => false,
              );
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomColors.iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back,
                  color: CustomColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _statusCard(
                        context,
                        'Could not read compass sensor.',
                        subtitle: 'Please rotate your device and try again.',
                        icon: Icons.error_outline_rounded,
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final heading = snapshot.data?.heading;
                    if (heading == null) {
                      return _statusCard(
                        context,
                        'Device does not support compass sensor.',
                        subtitle:
                            'Move the phone and check if the sensor is available.',
                        icon: Icons.sensors_off_rounded,
                      );
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'Live compass heading',
                          style: textTheme.headlineSmall?.copyWith(
                            color: CustomColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${heading.toStringAsFixed(0)}° ${getCardinalDirection(heading)}',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CustomColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 28),
                        CustomPaint(
                          size: const Size(310, 310),
                          painter: _CompassDialPainter(heading: heading),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(310, 310),
                                painter: _CompassNeedlePainter(),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.brown.shade800,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Hold the phone level and rotate it slowly to watch the needle align with north.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: CustomColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BannerAdmob(),
      ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    String title, {
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: CustomColors.primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  const _CompassDialPainter({required this.heading});

  final double heading;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final headingRadians = heading * (math.pi / 180);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingRadians);
    canvas.translate(-center.dx, -center.dy);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius + 10, shadowPaint);

    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [Color(0xFFFDFBF6), Color(0xFFE7DEC8)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, backgroundPaint);

    final patinaPaint = Paint()
      ..color = const Color(0xFFB48F68).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 10; i++) {
      final angle = i * 0.55;
      final start =
          center +
          Offset(
            math.cos(angle) * (radius * 0.38),
            math.sin(angle) * (radius * 0.38),
          );
      final end =
          center +
          Offset(
            math.cos(angle + 0.5) * (radius * 0.68),
            math.sin(angle + 0.5) * (radius * 0.68),
          );
      canvas.drawLine(start, end, patinaPaint);
    }

    final bezelOuter = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // colors: [Color(0xFFB6A08E), Color(0xFF3B2418)],
        colors: [
          CustomColors.primaryColor.withOpacity(0.6),
          CustomColors.primaryColor,
          // Color(0xFFB6A08E), Color(0xFF3B2418)
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bezelOuter);

    final bezelInner = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, radius - 4, bezelInner);

    final innerRing = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.74, innerRing);

    final highlightRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.78, highlightRing);

    for (var degree = 0; degree < 360; degree += 5) {
      final angle = degree * (math.pi / 180);
      final length = degree % 45 == 0
          ? 18
          : degree % 15 == 0
          ? 13
          : 8;
      final double strokeWidth = degree % 45 == 0
          ? 2.5
          : degree % 15 == 0
          ? 1.5
          : 1.0;
      final color = degree % 45 == 0
          ? Colors.green.shade900
          : Colors.green.shade700;

      final start =
          center +
          Offset(
            math.cos(angle) * (radius - 24),
            math.sin(angle) * (radius - 24),
          );
      final end =
          center +
          Offset(
            math.cos(angle) * (radius - 24 + length.toDouble()),
            math.sin(angle) * (radius - 24 + length.toDouble()),
          );

      final tickPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, tickPaint);
    }

    final labels = <String>['N', 'E', 'S', 'W'];
    final labelPositions = <Offset>[
      Offset(center.dx, center.dy - radius + 34),
      Offset(center.dx + radius - 34, center.dy),
      Offset(center.dx, center.dy + radius - 34),
      Offset(center.dx - radius + 34, center.dy),
    ];

    for (var index = 0; index < labels.length; index++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(
            color: Colors.green.shade900,
            fontSize: index == 0 ? 24 : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset =
          labelPositions[index] -
          Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }

    final centerDot = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerDot);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.heading != heading;
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 28;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - 14, center.dy - 24)
      ..lineTo(center.dx + 14, center.dy - 24)
      ..close();

    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - 12, center.dy + 26)
      ..lineTo(center.dx + 12, center.dy + 26)
      ..close();

    final northShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(northPath, northShadow);
    canvas.drawPath(southPath, northShadow);

    final northGlow = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(center.dx, center.dy - radius + 8), 12, northGlow);

    final northPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;

    final southPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(northPath, northPaint);
    canvas.drawPath(southPath, southPaint);

    final needleStroke = Paint()
      ..color = Colors.green.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius),
      needleStroke,
    );
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy + radius),
      needleStroke,
    );

    final shaftPaint = Paint()
      ..color = Colors.green.shade900.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 18),
      Offset(center.dx, center.dy + 18),
      shaftPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
