import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';

class ConsultsScreen extends StatelessWidget {
  const ConsultsScreen({super.key});

  Widget _buildTextField({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral.withValues(alpha: 0.7),
              ),
          prefixIcon: Icon(prefixIcon, color: AppColors.neutral, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDoctorCard({
    required BuildContext context,
    required String name,
    required String imageUrl,
    required String statusText,
    required Color statusDotColor,
  }) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect with elite specialists for better health tracking.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 12),
                    StatusBadge(
                      text: statusText,
                      dotColor: statusDotColor,
                      backgroundColor: Colors.grey.shade50,
                      textColor: AppColors.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIND CONSULTANTS',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    hintText: 'Search specialty, doctor name.',
                    prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context: context,
                    hintText: 'Location',
                    prefixIcon: PhosphorIconsRegular.mapPin,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'SEARCH',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Expert Guidance Section
            Text(
              'EXPERT GUIDANCE',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect with elite specialists for better health tracking.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Doctor List
            _buildDoctorCard(
              context: context,
              name: 'DR. SARAH CHEN',
              imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?fit=crop&w=150&h=150',
              statusText: 'Available Today',
              statusDotColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildDoctorCard(
              context: context,
              name: 'DR. MARCUS WONG',
              imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?fit=crop&w=150&h=150',
              statusText: 'Next Avail: Thu',
              statusDotColor: AppColors.neutral,
            ),
            const SizedBox(height: 16),

            // Explore Network button
            PrimaryButton(
              text: 'EXPLORE NETWORK',
              icon: const Icon(
                PhosphorIconsBold.arrowRight,
                color: AppColors.secondary,
                size: 16,
              ),
              onPressed: () {},
            ),
            const SizedBox(height: 24),

            // Health Records (Dark Theme Card)
            CustomCard(
              backgroundColor: AppColors.secondary,
              borderSide: BorderSide.none,
              child: Stack(
                children: [
                  // Document watermark decoration
                  const Positioned(
                    right: -10,
                    top: -10,
                    child: Opacity(
                      opacity: 0.08,
                      child: Icon(
                        PhosphorIconsFill.fileText,
                        size: 120,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HEALTH RECORDS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _buildRecordRow(context, 'Latest Blood Panel', 'OCT 12'),
                      const Divider(color: Colors.white24, height: 24, thickness: 0.5),
                      _buildRecordRow(context, 'MRI Scan Results', 'SEP 28'),
                      const Divider(color: Colors.white24, height: 24, thickness: 0.5),
                      _buildRecordRow(context, 'Vaccination History', 'AUG 05'),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'UPLOAD RECORD',
                        icon: const Icon(
                          PhosphorIconsBold.fileArrowUp,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid row
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL SCANS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '14',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHARED W/ DOCS',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '8',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
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

  Widget _buildRecordRow(BuildContext context, String title, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.tertiary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
