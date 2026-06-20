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

class DoctorProfileScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  AvailableSlot? _selectedSlot;
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final consultsState = ref.watch(consultsProvider);
    final doctor = consultsState.doctors.firstWhere(
      (d) => d.id == widget.doctorId,
      orElse: () => const Doctor(
        id: '',
        name: 'Doctor Not Found',
        specialty: '',
        qualification: '',
        experience: 0,
        consultationFee: 0,
        rating: 5,
        reviewCount: 0,
        clinicName: '',
        address: '',
        city: '',
        languages: [],
        availableSlots: [],
        isActive: false,
      ),
    );

    if (doctor.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Doctor Profile')),
        body: const Center(child: Text('Doctor profile not found')),
      );
    }

    // Initialize slot selection if not done yet
    if (_selectedSlot == null && doctor.availableSlots.isNotEmpty) {
      _selectedSlot = doctor.availableSlots.first;
      if (_selectedSlot!.times.isNotEmpty) {
        _selectedTime = _selectedSlot!.times.first;
      }
    }

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
          'Doctor Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Doctor Profile Header
            CustomCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              doctor.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 40),
                            ),
                          )
                        : const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doctor.specialty.toUpperCase()} • ${doctor.qualification}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(PhosphorIconsFill.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor.rating} (${doctor.reviewCount} reviews)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doctor.experience} years experience',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Practice Info
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRACTICE INFO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const Divider(height: 20),
                  _buildPracticeDetailTile(
                    icon: PhosphorIconsRegular.storefront,
                    title: 'Clinic Name',
                    value: doctor.clinicName,
                  ),
                  const SizedBox(height: 12),
                  _buildPracticeDetailTile(
                    icon: PhosphorIconsRegular.mapPin,
                    title: 'Clinic Address',
                    value: '${doctor.address}, ${doctor.city}',
                  ),
                  const SizedBox(height: 12),
                  _buildPracticeDetailTile(
                    icon: PhosphorIconsRegular.currencyInr,
                    title: 'Consultation Fee',
                    value: '₹${doctor.consultationFee.toInt()}',
                  ),
                  const SizedBox(height: 12),
                  _buildPracticeDetailTile(
                    icon: PhosphorIconsRegular.translate,
                    title: 'Languages Spoken',
                    value: doctor.languages.join(', '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Slot Picker
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT AVAILABLE SLOT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const Divider(height: 20),
                  if (doctor.availableSlots.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No slots currently available.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else ...[
                    // Days Select
                    const Text('Available Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: doctor.availableSlots.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final slot = doctor.availableSlots[index];
                          final isSelected = _selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot.day),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedSlot = slot;
                                  _selectedTime = slot.times.isNotEmpty ? slot.times.first : null;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Times Select
                    if (_selectedSlot != null && _selectedSlot!.times.isNotEmpty) ...[
                      const Text('Available Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedSlot!.times.map((time) {
                          final isSelected = _selectedTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedTime = time;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ] else
                      const Text('No slots available for the selected day', style: TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Proceed to book button
            PrimaryButton(
              text: 'PROCEED TO BOOKING',
              onPressed: _selectedTime != null
                  ? () {
                      HapticFeedback.lightImpact();
                      context.push(
                        '/consults/book/${doctor.id}?day=${Uri.encodeComponent(_selectedSlot!.day)}&time=${Uri.encodeComponent(_selectedTime!)}',
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeDetailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.neutral),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
