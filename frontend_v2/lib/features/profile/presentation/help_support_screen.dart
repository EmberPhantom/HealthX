import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../providers/profile_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportAsync = ref.watch(supportInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: supportAsync.when(
        data: (support) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Support Channels Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTACT SUPPORT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Our support team is available 24/7 to assist you with health tracking issues or appointments.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE5F7FF),
                                foregroundColor: const Color(0xFF0288D1),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _launchUrl(context, 'mailto:${support.email}?subject=HealthX Support Request');
                              },
                              icon: const Icon(PhosphorIconsRegular.envelopeSimple, size: 18),
                              label: const Text('Email Us', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8F5E9),
                                foregroundColor: const Color(0xFF2E7D32),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _launchUrl(context, 'https://wa.me/${support.whatsapp}?text=Hello%20HealthX%20Support');
                              },
                              icon: const Icon(PhosphorIconsRegular.whatsappLogo, size: 18),
                              label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. FAQs Section
                const Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),

                if (support.faqs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No FAQs available.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...support.faqs.map((faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildFaqTile(context, faq.question, faq.answer),
                      )),
              ],
            ),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ShimmerLoading(height: 160),
            SizedBox(height: 24),
            ShimmerLoading(height: 20),
            SizedBox(height: 12),
            ShimmerLoading(height: 60),
            SizedBox(height: 10),
            ShimmerLoading(height: 60),
            SizedBox(height: 10),
            ShimmerLoading(height: 60),
          ],
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading support info: $err', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    return CustomCard(
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8.0),
        collapsedIconColor: AppColors.neutral,
        iconColor: AppColors.secondary,
        shape: const Border(),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
