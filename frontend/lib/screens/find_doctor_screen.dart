// lib/screens/find_doctor_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';
import 'health_records.dart'; // ← uses healthRecordsState & HealthRecordsScreen

// ─── Specialty Model ──────────────────────────────────────────────────────────
class AppSpecialty {
  final String name;
  final IconData icon;
  final Color bgColor;
  const AppSpecialty(this.name, this.icon, this.bgColor);
}

final List<AppSpecialty> allSpecialties = [
  AppSpecialty('Dermatologist',        Icons.face_retouching_natural_rounded, const Color(0xFFFFB3BA)),
  AppSpecialty('Neurologist',          Icons.psychology_rounded,              const Color(0xFFFFDFBA)),
  AppSpecialty('Nephrologist',         Icons.water_drop_rounded,              const Color(0xFFBAFFCE)),
  AppSpecialty('Consulting Physician', Icons.medical_information_rounded,     const Color(0xFFBAD4FF)),
  AppSpecialty('Diabetologist',        Icons.monitor_heart_rounded,           const Color(0xFFFFB3BA)),
  AppSpecialty('Cardiologist',         Icons.favorite_rounded,                const Color(0xFFFFB3D9)),
  AppSpecialty('General Physician',    Icons.local_hospital_rounded,          const Color(0xFFBAFFEE)),
  AppSpecialty('Endocrinologist',      Icons.biotech_rounded,                 const Color(0xFFE8BAFF)),
  AppSpecialty('Psychiatrist',         Icons.self_improvement_rounded,        const Color(0xFFFFE4BA)),
  AppSpecialty('Gynaecologist',        Icons.pregnant_woman_rounded,          const Color(0xFFFFBAD4)),
  AppSpecialty('Pulmonologist',        Icons.air_rounded,                     const Color(0xFFBAF0FF)),
  AppSpecialty('Gastroenterologist',   Icons.airline_seat_flat_rounded,       const Color(0xFFBAFFBA)),
  AppSpecialty('Orthopedician',        Icons.accessibility_new_rounded,       const Color(0xFFFFDFBA)),
  AppSpecialty('Pediatrician',         Icons.child_care_rounded,              const Color(0xFFFFB3BA)),
  AppSpecialty('ENT',                  Icons.hearing_rounded,                 const Color(0xFFBAD4FF)),
  AppSpecialty('Ophthalmologist',      Icons.visibility_rounded,              const Color(0xFFE8BAFF)),
  AppSpecialty('Oncologist',           Icons.science_rounded,                 const Color(0xFFFFBAD4)),
  AppSpecialty('Rheumatologist',       Icons.elderly_rounded,                 const Color(0xFFBAFFCE)),
];

Color _darken(Color c) => Color.fromARGB(
    c.alpha, (c.red * 0.5).round(), (c.green * 0.5).round(), (c.blue * 0.5).round());

// ═══════════════════════════════════════════════════════════════════════════════
//  Find Doctor Screen  (specialty grid)
// ═══════════════════════════════════════════════════════════════════════════════

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<AppSpecialty> get _filtered => _query.isEmpty
      ? allSpecialties
      : allSpecialties
      .where((s) =>
      s.name.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Find A Doctor',
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ────────────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by Speciality',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                prefixIcon:
                const Icon(Icons.search, color: AppTheme.textMedium),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppTheme.textMedium, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryGreen, width: 1.5)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Search by Speciality',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 10),

            // ── Specialty Grid ────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 52, color: AppTheme.textLight),
                      const SizedBox(height: 10),
                      Text('No speciality found',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textMedium, fontSize: 14)),
                    ]),
              )
                  : GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.80,
                ),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final s = _filtered[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AnalyzingScreen(
                                    specialty: s))),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: s.bgColor,
                                  shape: BoxShape.circle),
                              child: Icon(s.icon,
                                  color: _darken(s.bgColor), size: 26),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5),
                              child: Text(
                                s.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textDark,
                                    height: 1.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Analyzing Screen
//  Flow:
//  1. Check records for specialist → show status (records found / missing).
//  2. User sees "Analysing your past data" step with edit icon if records exist,
//     or upload prompt if missing.
//  3. On "Confirm", animate the 3 steps with ticks → navigate to doctors list.
// ═══════════════════════════════════════════════════════════════════════════════

enum _AnalyzePhase { preview, animating, done }

class AnalyzingScreen extends StatefulWidget {
  final AppSpecialty specialty;
  const AnalyzingScreen({super.key, required this.specialty});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with TickerProviderStateMixin {
  _AnalyzePhase _phase = _AnalyzePhase.preview;

  // Step completion flags
  bool _step1Done = false;
  bool _step2Done = false;
  bool _step3Done = false;

  bool get _hasRecords =>
      healthRecordsState.hasRecordsForSpecialist(widget.specialty.name);

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Called when user taps "Confirm & Find Doctors"
  Future<void> _startAnalyzing() async {
    setState(() => _phase = _AnalyzePhase.animating);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step1Done = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step2Done = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step3Done = true);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = _AnalyzePhase.done);

    // Navigate to doctors list
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SelectDoctorScreen(
            specialty: widget.specialty.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            children: [
              // ── Doctor illustration ──────────────────────────
              ScaleTransition(
                scale: _pulseAnim,
                child: Image.asset(
                  'assets/images/doctor_search.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: const Icon(Icons.search_rounded,
                        size: 60, color: AppTheme.primaryGreen),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Finding the best doctors for you',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 5),
              // Specialty pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Text(
                  widget.specialty.name,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen),
                ),
              ),

              const SizedBox(height: 22),

              // ── Step 1 ───────────────────────────────────────
              _StepCard(
                label: 'Analysing your past data',
                isDone: _step1Done,
                isActive: true,
                trailing: _phase == _AnalyzePhase.preview
                    ? _RecordStatusWidget(
                  specialty: widget.specialty.name,
                  hasRecords: _hasRecords,
                )
                    : null,
              ),

              const SizedBox(height: 10),

              // ── Step 2 ───────────────────────────────────────
              _StepCard(
                label: 'Finding doctors near you',
                isDone: _step2Done,
                isActive: _step1Done,
              ),

              const SizedBox(height: 10),

              // ── Step 3 ───────────────────────────────────────
              _StepCard(
                label: 'Finding the best doctors that match your health profile',
                isDone: _step3Done,
                isActive: _step2Done,
              ),

              const SizedBox(height: 20),

              // ── CTA ──────────────────────────────────────────
              if (_phase == _AnalyzePhase.preview) ...[
                if (!_hasRecords) ...[
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.amber.shade700, size: 17),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'No ${widget.specialty.name} records found. Upload records for better doctor matching.',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.amber.shade800,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HealthRecordsScreen(
                                specialist: widget.specialty.name),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.upload_rounded,
                          color: AppTheme.primaryGreen, size: 17),
                      label: Text(
                          'Upload ${widget.specialty.name} Records',
                          style: GoogleFonts.poppins(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startAnalyzing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm & Find Doctors',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              if (_phase == _AnalyzePhase.animating) ...[
                const SizedBox(height: 8),
                const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.primaryGreen)),
                const SizedBox(height: 10),
                Text('Please wait…',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textMedium)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Record Status Widget ─────────────────────────────────────────────────────
// Shown in Step 1 during preview phase. Shows edit icon if records exist,
// or an upload nudge if not.

class _RecordStatusWidget extends StatelessWidget {
  final String specialty;
  final bool hasRecords;
  const _RecordStatusWidget(
      {required this.specialty, required this.hasRecords});

  @override
  Widget build(BuildContext context) {
    if (hasRecords) {
      final count =
          healthRecordsState.forSpecialist(specialty).length;
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HealthRecordsScreen(specialist: specialty),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.emerald50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded,
                  size: 13, color: AppTheme.primaryGreen),
              const SizedBox(width: 4),
              Text(
                '$count record${count > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 13, color: Colors.red.shade400),
            const SizedBox(width: 4),
            Text(
              'No records',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
  }
}

// ─── Step Card ────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final Widget? trailing;

  const _StepCard({
    required this.label,
    required this.isDone,
    required this.isActive,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.white
            : isActive
            ? Colors.white
            : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDone
            ? [
          BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ]
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
        border: isDone
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppTheme.textDark : AppTheme.textLight,
                  height: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          if (trailing != null) trailing!,
          if (trailing == null)
            isDone
                ? Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16),
            )
                : isActive
                ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGreen.withOpacity(0.5)),
            )
                : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Doctor Data Model
// ═══════════════════════════════════════════════════════════════════════════════

class _Doctor {
  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final int experience;
  final int fee;
  final String hospital;
  final String city;
  final double rating;
  final int reviewCount;
  final String? avatarUrl;
  final List<String> languages;

  const _Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.experience,
    required this.fee,
    required this.hospital,
    required this.city,
    required this.rating,
    required this.reviewCount,
    this.avatarUrl,
    required this.languages,
  });

  factory _Doctor.fromJson(Map<String, dynamic> json) {
    return _Doctor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: json['experience'] ?? 0,
      fee: json['consultationFee'] ?? 0,
      hospital: json['clinicName'] ?? '',
      city: json['city'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] ?? 0,
      avatarUrl: json['avatarUrl'],
      languages: List<String>.from(json['languages'] ?? []),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Select Doctor Screen
// ═══════════════════════════════════════════════════════════════════════════════

class SelectDoctorScreen extends StatefulWidget {
  final String specialty;
  const SelectDoctorScreen({super.key, required this.specialty});

  @override
  State<SelectDoctorScreen> createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends State<SelectDoctorScreen> {
  List<_Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService().getDoctors(specialty: widget.specialty);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.isSuccess && response.data != null) {
          _doctors = response.data!.map((x) => _Doctor.fromJson(x)).toList();
        } else {
          _errorMessage = response.errorMessage ?? 'Failed to load doctors';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(widget.specialty,
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.emerald50,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.primaryGreen, size: 16),
                const SizedBox(width: 6),
                Text('All doctors have ratings over 4.5/5',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!,
                                style: GoogleFonts.poppins(color: AppTheme.textMedium)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchDoctors,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _doctors.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_rounded,
                                    size: 52, color: AppTheme.textLight),
                                const SizedBox(height: 10),
                                Text('No doctors available for ${widget.specialty}',
                                    style: GoogleFonts.poppins(
                                        color: AppTheme.textMedium, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _doctors.length,
                            itemBuilder: (ctx, i) {
                              final doc = _doctors[i];
                              return _DoctorCard(
                                doctor: doc,
                                specialty: widget.specialty,
                                onSchedule: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleAppointmentScreen(
                                        doctor: doc, specialty: widget.specialty),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Doctor Card Widget ───────────────────────────────────────────────────────

class _DoctorCard extends StatefulWidget {
  final _Doctor doctor;
  final String specialty;
  final VoidCallback onSchedule;
  const _DoctorCard(
      {required this.doctor, required this.specialty, required this.onSchedule});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> {
  int _selectedDayIndex = 0;
  String? _selectedSlot;
  List<String> _todaySlots = [];
  List<String> _tomorrowSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final results = await Future.wait([
      ApiService().getDoctorSlots(widget.doctor.id, today),
      ApiService().getDoctorSlots(widget.doctor.id, tomorrow),
    ]);

    final todayRes = results[0];
    final tomorrowRes = results[1];

    if (mounted) {
      setState(() {
        if (todayRes.isSuccess && todayRes.data != null) {
          _todaySlots = todayRes.data!;
        }
        if (tomorrowRes.isSuccess && tomorrowRes.data != null) {
          _tomorrowSlots = tomorrowRes.data!;
        }
        _isLoadingSlots = false;
      });
    }
  }

  int get _todayTotal => _todaySlots.length;
  int get _tomorrowTotal => _tomorrowSlots.length;

  List<String> get _currentMorningSlots {
    final slots = _selectedDayIndex == 0 ? _todaySlots : _tomorrowSlots;
    return slots.where((s) => s.toUpperCase().contains('AM')).toList();
  }

  List<String> get _currentAfternoonSlots {
    final slots = _selectedDayIndex == 0 ? _todaySlots : _tomorrowSlots;
    return slots.where((s) => s.toUpperCase().contains('PM')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: AppTheme.emerald50,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person_rounded,
                      color: AppTheme.primaryGreen, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(doc.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppTheme.emerald50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppTheme.primaryGreen, size: 12),
                                const SizedBox(width: 3),
                                Text('${doc.rating}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(doc.qualification,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, color: AppTheme.textMedium)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('${doc.experience} yr Exp',
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AppTheme.textMedium,
                                  fontWeight: FontWeight.w500)),
                          Text('  |  ',
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AppTheme.textLight)),
                          Text('Rs ${doc.fee}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AppTheme.textMedium,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: AppTheme.emerald50,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppTheme.primaryGreen, size: 13),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${doc.hospital}, ${doc.city}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textMedium),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _DayTab(
                  label: 'Today',
                  slots: _todayTotal,
                  selected: _selectedDayIndex == 0,
                  onTap: () => setState(
                          () { _selectedDayIndex = 0; _selectedSlot = null; }),
                ),
                const SizedBox(width: 8),
                _DayTab(
                  label: 'Tomorrow',
                  slots: _tomorrowTotal,
                  selected: _selectedDayIndex == 1,
                  onTap: () => setState(
                          () { _selectedDayIndex = 1; _selectedSlot = null; }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (_isLoadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            )
          else ...[
            if (_selectedDayIndex == 0) ...[
              if (_currentMorningSlots.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Text('Morning Session',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                ),
                _SlotRow(
                  slots: _currentMorningSlots,
                  selectedSlot: _selectedSlot,
                  onSelect: (s) => setState(() => _selectedSlot = s),
                ),
                const SizedBox(height: 8),
              ],
              if (_currentAfternoonSlots.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Text('Afternoon Session',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                ),
                _SlotRow(
                  slots: _currentAfternoonSlots,
                  selectedSlot: _selectedSlot,
                  onSelect: (s) => setState(() => _selectedSlot = s),
                ),
                const SizedBox(height: 8),
              ],
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Text('Available Slots',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
              ),
              _SlotRow(
                slots: _tomorrowSlots,
                selectedSlot: _selectedSlot,
                onSelect: (s) => setState(() => _selectedSlot = s),
              ),
              const SizedBox(height: 8),
            ],
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: ElevatedButton(
              onPressed:
              _selectedSlot != null ? widget.onSchedule : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                disabledBackgroundColor:
                AppTheme.primaryGreen.withOpacity(0.4),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _selectedSlot != null
                    ? 'Schedule Appointment · $_selectedSlot'
                    : 'Select a Slot to Schedule',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Day Tab Widget ───────────────────────────────────────────────────────────

class _DayTab extends StatelessWidget {
  final String label;
  final int slots;
  final bool selected;
  final VoidCallback onTap;
  const _DayTab(
      {required this.label,
        required this.slots,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryGreen
                  : Colors.grey.withOpacity(0.25)),
        ),
        child: Text(
          '$label  ($slots)',
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textDark),
        ),
      ),
    );
  }
}

// ─── Slot Row Widget ──────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final List<String> slots;
  final String? selectedSlot;
  final void Function(String) onSelect;
  const _SlotRow(
      {required this.slots,
        required this.selectedSlot,
        required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: slots.map((s) {
          final isSelected = s == selectedSlot;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Colors.grey.withOpacity(0.25),
                ),
              ),
              child: Text(s,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textDark)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Schedule Appointment Screen
// ═══════════════════════════════════════════════════════════════════════════════

class ScheduleAppointmentScreen extends StatefulWidget {
  final _Doctor doctor;
  final String specialty;
  const ScheduleAppointmentScreen(
      {super.key, required this.doctor, required this.specialty});

  @override
  State<ScheduleAppointmentScreen> createState() =>
      _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState
    extends State<ScheduleAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;
  String? _selectedSlot;
  List<String> _todaySlots = [];
  List<String> _tomorrowSlots = [];
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSlots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final results = await Future.wait([
      ApiService().getDoctorSlots(widget.doctor.id, today),
      ApiService().getDoctorSlots(widget.doctor.id, tomorrow),
    ]);

    final todayRes = results[0];
    final tomorrowRes = results[1];

    if (mounted) {
      setState(() {
        if (todayRes.isSuccess && todayRes.data != null) {
          _todaySlots = todayRes.data!;
        }
        if (tomorrowRes.isSuccess && tomorrowRes.data != null) {
          _tomorrowSlots = tomorrowRes.data!;
        }
        _isLoadingSlots = false;
      });
    }
  }

  List<String> get _currentMorningSlots {
    return _todaySlots.where((s) => s.toUpperCase().contains('AM')).toList();
  }

  List<String> get _currentAfternoonSlots {
    return _todaySlots.where((s) => s.toUpperCase().contains('PM')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Schedule Appointment',
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: AppTheme.emerald50,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_rounded,
                        color: AppTheme.primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        Text(
                            '${doc.qualification} · ${widget.specialty}',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppTheme.textMedium)),
                        Text('${doc.hospital}, ${doc.city}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Consultation Type Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12)),
                labelStyle: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                GoogleFonts.poppins(fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMedium,
                tabs: const [
                  Tab(text: 'Video Consult'),
                  Tab(text: 'Visit Clinic'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Day selection
            Text('Select Date',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                _DayTab(
                  label: 'Today',
                  slots: _todaySlots.length,
                  selected: _selectedDayIndex == 0,
                  onTap: () => setState(() {
                    _selectedDayIndex = 0;
                    _selectedSlot = null;
                  }),
                ),
                const SizedBox(width: 8),
                _DayTab(
                  label: 'Tomorrow',
                  slots: _tomorrowSlots.length,
                  selected: _selectedDayIndex == 1,
                  onTap: () => setState(() {
                    _selectedDayIndex = 1;
                    _selectedSlot = null;
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Slots
            Text('Select Time Slot',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 10),

            if (_isLoadingSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              )
            else ...[
              if (_selectedDayIndex == 0) ...[
                if (_currentMorningSlots.isNotEmpty) ...[
                  Text('Morning',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textMedium)),
                  const SizedBox(height: 6),
                  _SlotRow(
                      slots: _currentMorningSlots,
                      selectedSlot: _selectedSlot,
                      onSelect: (s) => setState(() => _selectedSlot = s)),
                  const SizedBox(height: 10),
                ],
                if (_currentAfternoonSlots.isNotEmpty) ...[
                  Text('Afternoon',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textMedium)),
                  const SizedBox(height: 6),
                  _SlotRow(
                      slots: _currentAfternoonSlots,
                      selectedSlot: _selectedSlot,
                      onSelect: (s) => setState(() => _selectedSlot = s)),
                ],
              ] else ...[
                _SlotRow(
                    slots: _tomorrowSlots,
                    selectedSlot: _selectedSlot,
                    onSelect: (s) => setState(() => _selectedSlot = s)),
              ],
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSlot != null
                    ? () => _showConfirmation(context, doc)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  disabledBackgroundColor:
                  AppTheme.primaryGreen.withOpacity(0.4),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedSlot != null
                      ? 'Book · $_selectedSlot'
                      : 'Select a Time Slot',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, _Doctor doc) {
    final isVideoCall = _tabController.index == 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool isSubmitting = false;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Confirm Appointment',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 16),
                _ConfirmRow(
                    icon: Icons.person_rounded,
                    label: 'Doctor',
                    value: doc.name),
                _ConfirmRow(
                    icon: Icons.medical_services_rounded,
                    label: 'Speciality',
                    value: widget.specialty),
                _ConfirmRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _selectedDayIndex == 0 ? 'Today' : 'Tomorrow'),
                _ConfirmRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _selectedSlot ?? ''),
                _ConfirmRow(
                    icon: isVideoCall
                        ? Icons.videocam_rounded
                        : Icons.local_hospital_rounded,
                    label: 'Type',
                    value: isVideoCall ? 'Video Call' : 'Visit Clinic'),
                _ConfirmRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Fee',
                    value: 'Rs ${doc.fee}'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);

                            final date = _selectedDayIndex == 0
                                ? DateTime.now()
                                : DateTime.now().add(const Duration(days: 1));

                            final response = await ApiService().bookAppointment({
                              'doctorId': doc.id,
                              'appointmentDate': date.toIso8601String(),
                              'timeSlot': _selectedSlot,
                              'type': isVideoCall ? 'video' : 'in-person',
                              'symptoms': 'Routine consultation',
                              'notes': 'Booked via app',
                            });

                            if (!mounted) return;
                            setModalState(() => isSubmitting = false);

                            if (response.isSuccess) {
                              Navigator.pop(modalContext); // pop modal
                              _showSuccess(context);  // show success dialog
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response.errorMessage ?? 'Failed to book appointment'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Confirm Booking',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: AppTheme.emerald50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen, size: 42),
              ),
              const SizedBox(height: 16),
              Text('Appointment Booked!',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text(
                'Your appointment with ${widget.doctor.name} has been successfully scheduled.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: AppTheme.textMedium, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // pops dialog
                  Navigator.pop(context); // pops ScheduleAppointmentScreen
                  Navigator.pop(context); // pops SelectDoctorScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Done',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Confirm Row Widget ───────────────────────────────────────────────────────

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.emerald50,
                borderRadius: BorderRadius.circular(8)),
            child:
            Icon(icon, color: AppTheme.primaryGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Text('$label:',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppTheme.textMedium)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }
}