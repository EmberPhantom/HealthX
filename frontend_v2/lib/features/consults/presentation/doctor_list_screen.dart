import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/consults_provider.dart';
import '../../../core/models/consult_models.dart';

class DoctorListScreen extends ConsumerStatefulWidget {
  final String? specialty;

  const DoctorListScreen({super.key, this.specialty});

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consultsState = ref.watch(consultsProvider);
    final allDoctors = consultsState.doctors;

    // Filter by specialty & search query
    final filtered = allDoctors.where((doc) {
      final matchesSpecialty = widget.specialty == null ||
          doc.specialty.toLowerCase() == widget.specialty!.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.clinicName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSpecialty && matchesSearch;
    }).toList();

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
          widget.specialty ?? 'Find Doctors',
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
      body: consultsState.isLoading && allDoctors.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Search field
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
                        hintText: 'Search by doctor or clinic name...',
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

                // Doctor list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(consultsProvider.notifier).refreshAll(),
                    color: AppColors.primary,
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No consultants found matching your criteria.',
                              style: TextStyle(color: AppColors.neutral),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              return _buildDoctorCard(context, doc);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/consults/doctor/${doctor.id}');
      },
      child: CustomCard(
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            doctor.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 30),
                          ),
                        )
                      : const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doctor.specialty.toUpperCase()} • ${doctor.qualification}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${doctor.experience} years experience • Clinic: ${doctor.clinicName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(PhosphorIconsFill.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.rating} (${doctor.reviewCount} reviews)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '₹${doctor.consultationFee.toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'VIEW PROFILE & BOOK',
              height: 38,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/consults/doctor/${doctor.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
