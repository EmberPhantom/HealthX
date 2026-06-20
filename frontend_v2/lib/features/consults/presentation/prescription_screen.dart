import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../services/consult_service.dart';
import '../providers/consults_provider.dart';

class PrescriptionScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const PrescriptionScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  final _service = ConsultService();
  Prescription? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final p = await _service.getPrescription(widget.appointmentId);
    if (mounted) {
      setState(() {
        _prescription = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultsProvider);
    final appt = state.appointments.where((a) => a.id == widget.appointmentId).firstOrNull;
    final doctorName = appt?.doctor?.name ?? 'Doctor';

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
        title: const Text('Prescription', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
        ),
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ShimmerLoading(height: 120),
                SizedBox(height: 16),
                ShimmerLoading(height: 200),
              ],
            )
          : _prescription == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.fileText, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No prescription available', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('The prescription will appear here once issued', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor & Date header
                      CustomCard(
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.stethoscope, size: 36, color: AppColors.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctorName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('Issued: ${DateFormat('MMM d, yyyy').format(_prescription!.issuedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Medications
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MEDICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                            const Divider(height: 20),
                            ..._prescription!.medications.map((med) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _pill(med.dosage, AppColors.primary),
                                      const SizedBox(width: 8),
                                      _pill(med.frequency, Colors.blue),
                                      if (med.duration != null) ...[
                                        const SizedBox(width: 8),
                                        _pill(med.duration!, Colors.teal),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),

                      // Doctor's notes
                      if (_prescription!.doctorNotes != null && _prescription!.doctorNotes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DOCTOR\'S NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                              const Divider(height: 20),
                              Text(_prescription!.doctorNotes!, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
