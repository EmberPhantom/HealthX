import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/consults_provider.dart';
import '../../../core/models/consult_models.dart';
import '../../health/providers/health_records_provider.dart';
import '../../../core/models/health_record_model.dart';

class ConsultsScreen extends ConsumerStatefulWidget {
  const ConsultsScreen({super.key});

  @override
  ConsumerState<ConsultsScreen> createState() => _ConsultsScreenState();
}

class _ConsultsScreenState extends ConsumerState<ConsultsScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _appointmentTabIndex = 0;

  IconData _getSpecialtyIcon(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'diabetologist': return PhosphorIconsRegular.activity;
      case 'cardiologist': return PhosphorIconsRegular.heart;
      case 'general physician': return PhosphorIconsRegular.stethoscope;
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
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime getNextDayOfWeek(String dayName) {
    final days = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    final targetDay = days[dayName.toLowerCase()] ?? DateTime.monday;
    DateTime result = DateTime.now();
    int loopCount = 0;
    while (result.weekday != targetDay && loopCount < 8) {
      result = result.add(const Duration(days: 1));
      loopCount++;
    }
    return result;
  }

  Future<void> _confirmCancelAppointment(BuildContext context, WidgetRef ref, String apptId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await ref.read(consultsProvider.notifier).cancelUserAppointment(apptId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Appointment cancelled successfully' : 'Failed to cancel appointment'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('YES, CANCEL'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBookingSheet(BuildContext context, WidgetRef ref, Doctor doctor) async {
    if (doctor.availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available slots for this doctor.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final symptomsController = TextEditingController();
    AvailableSlot selectedSlot = doctor.availableSlots.first;
    String? selectedTime = selectedSlot.times.isNotEmpty ? selectedSlot.times.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Appointment with',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      doctor.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),

                    // Available Days List
                    const Text('Select Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: doctor.availableSlots.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final slot = doctor.availableSlots[index];
                          final isSelected = selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot.day),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  selectedSlot = slot;
                                  selectedTime = slot.times.isNotEmpty ? slot.times.first : null;
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available Times Grid
                    if (selectedSlot.times.isNotEmpty) ...[
                      const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedSlot.times.map((time) {
                          final isSelected = selectedTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ] else
                      const Text('No slots available for the selected day', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),

                    // Symptoms Text Field
                    const Text('Symptoms / Reason for Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: symptomsController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. fever, headache, routine checkup',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      text: 'CONFIRM BOOKING (₹${doctor.consultationFee.toInt()})',
                      onPressed: selectedTime != null
                          ? () async {
                              final apptDate = getNextDayOfWeek(selectedSlot.day);
                              final success = await ref.read(consultsProvider.notifier).bookDoctorSlot(
                                    doctor.id,
                                    apptDate,
                                    selectedTime!,
                                    symptoms: symptomsController.text.trim(),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Booking successful!' : 'Failed to book slot'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
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
    required Doctor doctor,
    required VoidCallback onBook,
  }) {
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
                        '${doctor.experience} years experience • Consultation fee: ₹${doctor.consultationFee.toInt()}',
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
                          StatusBadge(
                            text: doctor.isActive ? 'Available' : 'Unavailable',
                            dotColor: doctor.isActive ? const Color(0xFF10B981) : Colors.red,
                            backgroundColor: doctor.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFFEFE6),
                            textColor: doctor.isActive ? const Color(0xFF10B981) : Colors.red,
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
              text: 'BOOK APPOINTMENT',
              height: 38,
              onPressed: doctor.isActive ? () {
                HapticFeedback.lightImpact();
                context.push('/consults/doctor/${doctor.id}');
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Appointment> _filterAppointments(List<Appointment> all, bool upcoming) {
    final now = DateTime.now();
    return all.where((a) {
      final isFuture = a.appointmentDate.isAfter(now) ||
          (a.appointmentDate.day == now.day &&
              a.appointmentDate.month == now.month &&
              a.appointmentDate.year == now.year);
      final isActive = a.status.toLowerCase() != 'cancelled' && a.status.toLowerCase() != 'completed';
      return upcoming ? (isFuture && isActive) : (!isFuture || !isActive);
    }).toList()
      ..sort((a, b) => upcoming
          ? a.appointmentDate.compareTo(b.appointmentDate)
          : b.appointmentDate.compareTo(a.appointmentDate));
  }

  Widget _buildAppointmentsSection(BuildContext context, WidgetRef ref, List<Appointment> allAppointments) {
    if (allAppointments.isEmpty) return const SizedBox.shrink();

    final upcoming = _filterAppointments(allAppointments, true);
    final past = _filterAppointments(allAppointments, false);
    final displayed = _appointmentTabIndex == 0 ? upcoming : past;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MY APPOINTMENTS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Active appointment logs and consultant connections.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appointmentTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _appointmentTabIndex == 0 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'UPCOMING (${upcoming.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _appointmentTabIndex == 0 ? AppColors.secondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appointmentTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _appointmentTabIndex == 1 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'PAST (${past.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _appointmentTabIndex == 1 ? AppColors.secondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (displayed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                _appointmentTabIndex == 0 ? 'No upcoming appointments.' : 'No past appointments.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appt = displayed[index];
              final docName = appt.doctor?.name ?? 'Specialist Doctor';
              final formattedDate = DateFormat('EEE, MMM d, yyyy').format(appt.appointmentDate);

              final isCancelled = appt.status.toLowerCase() == 'cancelled';
              final statusColor = isCancelled
                  ? Colors.red
                  : appt.status.toLowerCase() == 'confirmed'
                      ? const Color(0xFF10B981)
                      : Colors.orange;
              final statusBg = isCancelled
                  ? const Color(0xFFFFEFE6)
                  : appt.status.toLowerCase() == 'confirmed'
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF9C3);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/consults/appointment/${appt.id}');
                },
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            docName.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          StatusBadge(
                            text: appt.status.toUpperCase(),
                            dotColor: statusColor,
                            backgroundColor: statusBg,
                            textColor: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(PhosphorIconsRegular.calendar, size: 16, color: AppColors.neutral),
                          const SizedBox(width: 8),
                          Text(
                            '$formattedDate at ${appt.timeSlot}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (appt.symptoms != null && appt.symptoms!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Symptoms: ${appt.symptoms}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (appt.status.toLowerCase() == 'confirmed' || appt.status.toLowerCase() == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close, size: 16),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red, width: 1),
                                  foregroundColor: Colors.red,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _confirmCancelAppointment(context, ref, appt.id),
                                label: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(PhosphorIconsRegular.chatDots, size: 16),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary),
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/consults/appointment/${appt.id}');
                                },
                                label: const Text('DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final consultsState = ref.watch(consultsProvider);
    final specialtiesAsync = ref.watch(specialtiesProvider);
    final recordsState = ref.watch(healthRecordsProvider);

    final searchQuery = _searchController.text.trim().toLowerCase();
    final locationQuery = _locationController.text.trim().toLowerCase();

    final filteredDoctors = consultsState.doctors.where((doc) {
      final matchesSearch = searchQuery.isEmpty ||
          doc.name.toLowerCase().contains(searchQuery) ||
          doc.specialty.toLowerCase().contains(searchQuery);
      final matchesLocation = locationQuery.isEmpty ||
          doc.city.toLowerCase().contains(locationQuery) ||
          doc.clinicName.toLowerCase().contains(locationQuery) ||
          doc.address.toLowerCase().contains(locationQuery);
      return matchesSearch && matchesLocation;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: consultsState.isLoading && consultsState.doctors.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ShimmerLoading(height: 74),
                const SizedBox(height: 16),
                ShimmerLoading(height: 120),
                const SizedBox(height: 16),
                ShimmerLoading(height: 140),
                const SizedBox(height: 12),
                ShimmerLoading(height: 140),
                const SizedBox(height: 12),
                ShimmerLoading(height: 140),
              ],
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(consultsProvider.notifier).refreshAll();
                await ref.read(healthRecordsProvider.notifier).fetchRecords();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specialties Horizontal Select Box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(PhosphorIconsBold.activity, color: AppColors.secondary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'DOCTOR SPECIALTIES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/consults/find');
                          },
                          child: const Text('View All', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 84,
                      child: specialtiesAsync.when(
                        data: (specialties) {
                          if (specialties.isEmpty) {
                            return const Center(
                              child: Text(
                                'No specialties available',
                                style: TextStyle(color: AppColors.neutral, fontSize: 12),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: specialties.length,
                            itemBuilder: (context, index) {
                              final specialty = specialties[index];
                              final icon = _getSpecialtyIcon(specialty);
                              return _buildSpecialtyTile(context, specialty, icon);
                            },
                          );
                        },
                        loading: () => ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, index) => Container(
                            width: 105,
                            margin: const EdgeInsets.only(right: 12),
                            child: const ShimmerLoading(height: 84, width: 105),
                          ),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                            hintText: 'Search specialty, doctor name...',
                            prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                            controller: _searchController,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            context: context,
                            hintText: 'Location / City...',
                            prefixIcon: PhosphorIconsRegular.mapPin,
                            controller: _locationController,
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'CLEAR FILTERS',
                            onPressed: searchQuery.isNotEmpty || locationQuery.isNotEmpty
                                ? () {
                                    setState(() {
                                      _searchController.clear();
                                      _locationController.clear();
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // My Bookings Section (Dynamic appointments list)
                    _buildAppointmentsSection(context, ref, consultsState.appointments),

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

                    // Dynamic Doctor List
                    if (filteredDoctors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No doctors found matching your criteria.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDoctors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doctor = filteredDoctors[index];
                          return _buildDoctorCard(
                            context: context,
                            doctor: doctor,
                            onBook: () => _showBookingSheet(context, ref, doctor),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // Refresh/Explore network button
                    PrimaryButton(
                      text: 'REFRESH NETWORK LIST',
                      icon: const Icon(
                        PhosphorIconsBold.arrowsClockwise,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                      onPressed: () async {
                        await ref.read(consultsProvider.notifier).refreshAll();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Health Records (Dark Theme Card)
                    CustomCard(
                      backgroundColor: AppColors.secondary,
                      borderSide: BorderSide.none,
                      child: Stack(
                        children: [
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HEALTH RECORDS',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/health/records');
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (recordsState.isLoading && recordsState.records.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              else if (recordsState.records.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'No health records found.',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                )
                              else ...[
                                for (int i = 0; i < recordsState.records.length.clamp(0, 3); i++) ...[
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/health/records');
                                    },
                                    child: _buildRecordRow(
                                      context,
                                      recordsState.records[i].name,
                                      DateFormat('MMM dd').format(recordsState.records[i].date).toUpperCase(),
                                    ),
                                  ),
                                  if (i < recordsState.records.length.clamp(0, 3) - 1)
                                    const Divider(color: Colors.white24, height: 24, thickness: 0.5),
                                ],
                              ],
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: 'UPLOAD RECORD',
                                icon: const Icon(
                                  PhosphorIconsBold.fileArrowUp,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/health/records?openUpload=true');
                                },
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
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/health/records');
                            },
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
                                    '${recordsState.records.where((r) => r.type == RecordType.scans).length}',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/health/records');
                            },
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
                                    '${recordsState.records.where((r) => r.specialist.isNotEmpty).length}',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _buildSpecialtyTile(BuildContext context, String specialtyName, IconData icon, {String? displayName}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/consults/list?specialty=${Uri.encodeComponent(specialtyName)}');
      },
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(right: 12),
        child: CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.secondary, size: 20),
              const SizedBox(height: 6),
              Text(
                displayName ?? specialtyName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
