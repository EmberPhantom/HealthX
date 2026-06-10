import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_provider.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6EA8D0).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2E40),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.insightMessage,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A3A5C).withOpacity(0.65),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: provider.goalReached
                      ? const Color(0xFF4CAF50).withOpacity(0.12)
                      : const Color(0xFF4A9FD4).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  provider.goalReached ? Icons.check_circle : Icons.water_drop,
                  color: provider.goalReached
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4A9FD4),
                  size: 24,
                ),
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE0F0FA),
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.goalReached
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF4A9FD4),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.currentLiters.toStringAsFixed(1)}L / ${(provider.dailyGoal / 1000).toStringAsFixed(1)}L',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A3A5C).withOpacity(0.55),
                ),
              ),
              Text(
                '${(provider.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A9FD4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}