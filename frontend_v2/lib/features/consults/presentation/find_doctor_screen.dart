import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../providers/consults_provider.dart';

class FindDoctorScreen extends ConsumerStatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  ConsumerState<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends ConsumerState<FindDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  IconData _getSpecialtyIcon(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'diabetologist': return PhosphorIconsRegular.activity;
      case 'cardiologist': return PhosphorIconsRegular.heart;
      case 'general physician': return PhosphorIconsRegular.firstAid;
      case 'dermatologist': return PhosphorIconsRegular.sparkle;
      case 'neurologist': return PhosphorIconsRegular.brain;
      case 'nephrologist': return PhosphorIconsRegular.circle;
      case 'consulting physician': return PhosphorIconsRegular.stethoscope;
      case 'endocrinologist': return PhosphorIconsRegular.fingerprint;
      case 'psychiatrist': return PhosphorIconsRegular.smiley;
      case 'gynaecologist': return PhosphorIconsRegular.genderFemale;
      case 'pulmonologist': return PhosphorIconsRegular.wind;
      case 'gastroenterologist': return PhosphorIconsRegular.shield;
      case 'orthopedician': return PhosphorIconsRegular.barbell;
      case 'pediatrician': return PhosphorIconsRegular.baby;
      case 'ent': return PhosphorIconsRegular.ear;
      case 'ophthalmologist': return PhosphorIconsRegular.eye;
      case 'oncologist': return PhosphorIconsRegular.virus;
      case 'rheumatologist': return PhosphorIconsRegular.handGrabbing;
      default: return PhosphorIconsRegular.stethoscope;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialtiesAsync = ref.watch(specialtiesProvider);

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
        title: Text(
          'Select Specialty',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                decoration: InputDecoration(
                  hintText: 'Search medical specialty...',
                  hintStyle: TextStyle(
                    color: AppColors.neutral.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.neutral, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Specialties Grid
          Expanded(
            child: specialtiesAsync.when(
              data: (specialties) {
                final filtered = specialties
                    .where((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No specialties match your search.',
                      style: TextStyle(color: AppColors.neutral),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final specialtyName = filtered[index];
                    final icon = _getSpecialtyIcon(specialtyName);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/consults/list?specialty=${Uri.encodeComponent(specialtyName)}');
                      },
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(icon, color: AppColors.secondary, size: 20),
                            ),
                            Text(
                              specialtyName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
