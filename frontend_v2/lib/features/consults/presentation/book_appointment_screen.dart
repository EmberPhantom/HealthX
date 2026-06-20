import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/consults_provider.dart';
import '../../../core/models/consult_models.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String day;
  final String time;

  const BookAppointmentScreen({
    super.key,
    required this.doctorId,
    required this.day,
    required this.time,
  });

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _appointmentDate;

  @override
  void initState() {
    super.initState();
    _appointmentDate = _getNextDayOfWeek(widget.day);
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _getNextDayOfWeek(String dayName) {
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

  Future<void> _confirmBooking(Doctor doctor) async {
    HapticFeedback.vibrate();
    
    final success = await ref.read(consultsProvider.notifier).bookDoctorSlot(
          doctor.id,
          _appointmentDate,
          widget.time,
          symptoms: _symptomsController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (mounted) {
      if (success) {
        // Go back twice to return to Consultations listing
        Navigator.pop(context); // Pop book screen
        Navigator.pop(context); // Pop profile screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final stateError = ref.read(consultsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(stateError ?? 'Failed to book appointment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: const Center(child: Text('Doctor details not found')),
      );
    }

    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_appointmentDate);

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
          'Confirm Appointment',
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
            // 1. Consultant summary card
            CustomCard(
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.stethoscope, size: 36, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${doctor.specialty} • ${doctor.qualification}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Booking Slot details
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APPOINTMENT TIME',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.calendar, size: 18, color: AppColors.neutral),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.clock, size: 18, color: AppColors.neutral),
                      const SizedBox(width: 8),
                      Text(
                        widget.time,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.currencyInr, size: 18, color: AppColors.neutral),
                      const SizedBox(width: 8),
                      Text(
                        '₹${doctor.consultationFee.toInt()} Consultation Fee',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. User Form Details
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PATIENT NOTES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  const Divider(height: 20),
                  const Text('Reason for Visit / Symptoms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: InputDecoration(
                      hintText: 'e.g. routine diabetes follow-up, high fever, throat pain',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Additional Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe any current medications or details the doctor should know...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            PrimaryButton(
              text: 'CONFIRM & BOOK APPOINTMENT',
              isLoading: consultsState.isLoading,
              onPressed: () => _confirmBooking(doctor),
            ),
          ],
        ),
      ),
    );
  }
}
