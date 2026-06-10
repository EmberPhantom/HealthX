import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Summary",
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tuesday, Oct 24 • Focus: Recovery',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                  text: 'OPTIMIZED',
                  dotColor: AppColors.primary,
                  backgroundColor: Color(0xFFFCFDF2),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily Score Chart Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAILY SCORE',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '88%',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Custom Line Chart
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // X Axis Labels
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('W', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('F', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('S', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('S', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('M', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macros Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MACROS',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(
                        '2,140',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 38,
                            ),
                      ),
                      Text(
                        ' / 2500 kcal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildMacroRow(
                    context: context,
                    label: 'PROTEIN',
                    current: 140,
                    target: 180,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  _buildMacroRow(
                    context: context,
                    label: 'CARBS',
                    current: 210,
                    target: 250,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  _buildMacroRow(
                    context: context,
                    label: 'FAT',
                    current: 55,
                    target: 70,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid of 4 Items (Steps, Sleep, Hydration, Glucose)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                // Steps Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('STEPS', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: 0.75,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade100,
                                color: AppColors.primary,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            const Icon(PhosphorIconsFill.footprints, color: AppColors.secondary, size: 20),
                          ],
                        ),
                      ),
                      Center(
                        child: Text(
                          '8,432',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sleep Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SLEEP', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: 0.85,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey.shade100,
                                color: AppColors.secondary,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            const Icon(PhosphorIconsFill.moon, color: AppColors.secondary, size: 20),
                          ],
                        ),
                      ),
                      Center(
                        child: Text(
                          '7h 12m',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hydration Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('HYDRATION', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                      // Bar Chart mockup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMiniBar(height: 50, color: AppColors.secondary),
                          _buildMiniBar(height: 50, color: AppColors.secondary),
                          _buildMiniBar(height: 50, color: AppColors.secondary),
                          _buildMiniBar(height: 50, color: AppColors.secondary),
                          _buildMiniBar(height: 30, color: AppColors.primary),
                          _buildMiniBar(height: 10, color: Colors.grey.shade200),
                        ],
                      ),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                            children: [
                              const TextSpan(text: '2.4 '),
                              TextSpan(
                                text: 'Liters',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Glucose Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GLUCOSE', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10)),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neutral,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textBaseline: TextBaseline.alphabetic,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              Text(
                                '94',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ng/dL',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            'Last: 2h ago',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                      PrimaryButton(
                        text: 'LOG READING',
                        height: 36,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow({
    required BuildContext context,
    required String label,
    required double current,
    required double target,
    required Color color,
  }) {
    final double percent = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              '${current.toInt()}G / ${target.toInt()}G',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBar({required double height, required Color color}) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// Custom Painter for drawing the smooth daily score line chart
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill;

    // Define coordinates based on mockups
    final List<Offset> points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.16, size.height * 0.55),
      Offset(size.width * 0.33, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.66, size.height * 0.3),
      Offset(size.width * 0.83, size.height * 0.5),
      Offset(size.width, size.height * 0.2),
    ];

    // Create Path for Line
    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    // Draw smooth cubic bezier curve
    for (int i = 0; i < points.length - 1; i++) {
      final double xc = (points[i].dx + points[i + 1].dx) / 2;
      final double yc = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Create Path for Gradient Fill
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Create Gradient for fill
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    fillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.3),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(rect);

    // Draw grid lines (horizontal dashed lines)
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const int gridRows = 3;
    for (int i = 1; i <= gridRows; i++) {
      final double y = size.height * (i / (gridRows + 1));
      // Draw simple dashed line
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 5, y), gridPaint);
        startX += 10;
      }
    }

    // Draw Fill & Line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw Point Dots
    final Paint dotPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    
    final Paint dotOutlinePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final Offset point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5, dotOutlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
