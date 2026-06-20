import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/consults_provider.dart';
import '../../../core/models/consult_models.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO', style: TextStyle(color: AppColors.neutral))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(consultsProvider.notifier).cancelUserAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Appointment cancelled' : 'Failed to cancel'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) context.pop();
      }
    }
  }

  Future<void> _rescheduleAppointment() async {
    final state = ref.read(consultsProvider);
    final appt = state.appointments.where((a) => a.id == widget.appointmentId).firstOrNull;
    if (appt == null) return;

    final doctor = state.doctors.where((d) => d.id == appt.doctorId).firstOrNull;
    if (doctor == null || doctor.availableSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No slots available for rescheduling'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    AvailableSlot selectedSlot = doctor.availableSlots.first;
    String? selectedTime = selectedSlot.times.isNotEmpty ? selectedSlot.times.first : null;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RESCHEDULE APPOINTMENT', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
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
                            setSheetState(() {
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
                if (selectedSlot.times.isNotEmpty) ...[
                  const Text('Select Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
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
                          if (val) setSheetState(() => selectedTime = time);
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'CONFIRM RESCHEDULE',
                  onPressed: selectedTime != null ? () => Navigator.pop(ctx, {'day': selectedSlot.day, 'time': selectedTime!}) : null,
                ),
              ],
            ),
          );
        });
      },
    );

    if (result != null && mounted) {
      final days = {
        'monday': DateTime.monday, 'tuesday': DateTime.tuesday, 'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday, 'friday': DateTime.friday, 'saturday': DateTime.saturday, 'sunday': DateTime.sunday,
      };
      final targetDay = days[result['day']!.toLowerCase()] ?? DateTime.monday;
      DateTime newDate = DateTime.now();
      int loopCount = 0;
      while (newDate.weekday != targetDay && loopCount < 8) {
        newDate = newDate.add(const Duration(days: 1));
        loopCount++;
      }

      final success = await ref.read(consultsProvider.notifier).rescheduleAppointment(
        widget.appointmentId, newDate, result['time']!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Appointment rescheduled' : 'Failed to reschedule'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultsState = ref.watch(consultsProvider);
    final appt = consultsState.appointments.where((a) => a.id == widget.appointmentId).firstOrNull;

    if (appt == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Appointment Details'), backgroundColor: AppColors.tertiary),
        body: consultsState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : const Center(child: Text('Appointment not found')),
      );
    }

    final doctor = appt.doctor ?? consultsState.doctors.where((d) => d.id == appt.doctorId).firstOrNull;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(appt.appointmentDate);
    final isUpcoming = appt.appointmentDate.isAfter(DateTime.now()) && appt.status.toLowerCase() != 'cancelled' && appt.status.toLowerCase() != 'completed';

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
        title: const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor card
            if (doctor != null)
              CustomCard(
                child: Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(doctor.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 32)),
                            )
                          : const Icon(PhosphorIconsFill.user, color: AppColors.secondary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('${doctor.specialty} • ${doctor.qualification}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(PhosphorIconsFill.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('${doctor.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: appt.status.toUpperCase(),
                      dotColor: appt.status.toLowerCase() == 'confirmed' ? const Color(0xFF10B981) : appt.status.toLowerCase() == 'cancelled' ? Colors.red : Colors.orange,
                      backgroundColor: appt.status.toLowerCase() == 'confirmed' ? const Color(0xFFD1FAE5) : appt.status.toLowerCase() == 'cancelled' ? const Color(0xFFFFEFE6) : const Color(0xFFFEF9C3),
                      textColor: appt.status.toLowerCase() == 'confirmed' ? const Color(0xFF10B981) : appt.status.toLowerCase() == 'cancelled' ? Colors.red : Colors.orange,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Appointment details card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('APPOINTMENT INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                  const Divider(height: 20),
                  _detailRow(PhosphorIconsRegular.calendar, 'Date', formattedDate),
                  const SizedBox(height: 12),
                  _detailRow(PhosphorIconsRegular.clock, 'Time', appt.timeSlot),
                  const SizedBox(height: 12),
                  _detailRow(PhosphorIconsRegular.currencyInr, 'Fee', '₹${appt.consultationFee.toInt()}'),
                  if (doctor != null) ...[
                    const SizedBox(height: 12),
                    _detailRow(PhosphorIconsRegular.storefront, 'Clinic', doctor.clinicName),
                    const SizedBox(height: 12),
                    _detailRow(PhosphorIconsRegular.mapPin, 'Address', '${doctor.address}, ${doctor.city}'),
                  ],
                ],
              ),
            ),

            if (appt.symptoms != null && appt.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PATIENT NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                    const Divider(height: 20),
                    Text(appt.symptoms!, style: const TextStyle(fontSize: 14)),
                    if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(appt.notes!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            if (isUpcoming) ...[
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'RESCHEDULE',
                      icon: const Icon(PhosphorIconsBold.arrowsClockwise, color: AppColors.secondary, size: 16),
                      onPressed: _rescheduleAppointment,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(PhosphorIconsRegular.chatDots, size: 18),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/consults/appointment/${appt.id}/chat');
                      },
                      label: const Text('CHAT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.x, size: 18),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _cancelAppointment,
                  label: const Text('CANCEL APPOINTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            if (appt.status.toLowerCase() == 'completed') ...[
              PrimaryButton(
                text: 'VIEW PRESCRIPTION',
                icon: const Icon(PhosphorIconsBold.fileText, color: AppColors.secondary, size: 16),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/consults/appointment/${appt.id}/prescription');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.neutral),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
