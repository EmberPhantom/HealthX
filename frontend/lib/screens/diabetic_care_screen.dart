// lib/screens/diabetic_care_screen.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import 'find_doctor_screen.dart';
import 'health_records.dart'; // ← HealthRecord, healthRecordsState, HealthRecordsScreen

// ─── Profile Model & State ────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String name;
  final String? photoPath; // local file path after camera/gallery pick
  final String phone;
  final String gender; // 'Male' | 'Female' | 'Others'
  final int age;
  final String ageUnit; // 'Years' | 'Months'

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.photoPath,
    this.gender = 'Male',
    this.age = 0,
    this.ageUnit = 'Years',
  });

  UserProfile copyWith({
    String? name,
    String? photoPath,
    String? gender,
    int? age,
    String? ageUnit,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        phone: phone,
        photoPath: photoPath ?? this.photoPath,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        ageUnit: ageUnit ?? this.ageUnit,
      );
}

class _ProfilesState extends ChangeNotifier {
  final List<UserProfile> _profiles = []; // ✅ ISSUE 1 FIXED: Empty list - no dummy profiles
  int _activeIndex = 0;
  bool _isLoaded = false;

  List<UserProfile> get profiles => List.unmodifiable(_profiles);

  // ✅ ISSUE 5 FIXED: Safe getter that returns null if list is empty
  UserProfile? get activeOrNull =>
      _profiles.isNotEmpty ? _profiles[_activeIndex] : null;

  // Keep for backward compatibility but guard against crashes
  UserProfile get active => activeOrNull ??
      UserProfile(id: 'default', name: 'My Profile', phone: '');

  bool get isLoaded => _isLoaded;

  // ✅ ISSUE 2 FIXED: Load profiles from SharedPreferences on init
  Future<void> loadProfiles() async {
    if (_isLoaded) return;
    try {
      final prefs = await _getPrefs();
      final profilesJson = prefs.getStringList('user_profiles') ?? [];

      _profiles.clear();
      for (final json in profilesJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          _profiles.add(UserProfile(
            id: map['id'] as String,
            name: map['name'] as String,
            phone: map['phone'] as String,
            photoPath: map['photoPath'] as String?,
            gender: map['gender'] as String? ?? 'Male',
            age: map['age'] as int? ?? 0,
            ageUnit: map['ageUnit'] as String? ?? 'Years',
          ));
        } catch (e) {
          print('Error decoding profile: $e');
        }
      }

      _activeIndex = prefs.getInt('active_profile_index') ?? 0;
      if (_activeIndex >= _profiles.length) _activeIndex = 0;

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading profiles: $e');
      _isLoaded = true;
    }
  }

  // ✅ ISSUE 2 FIXED: Save profiles to SharedPreferences
  Future<void> _saveProfiles() async {
    try {
      final prefs = await _getPrefs();
      final profilesJson = _profiles.map((p) => jsonEncode({
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'photoPath': p.photoPath,
        'gender': p.gender,
        'age': p.age,
        'ageUnit': p.ageUnit,
      })).toList();

      await prefs.setStringList('user_profiles', profilesJson);
      await prefs.setInt('active_profile_index', _activeIndex);
    } catch (e) {
      print('Error saving profiles: $e');
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  void switchTo(int index) {
    if (index >= 0 && index < _profiles.length) {
      _activeIndex = index;
      notifyListeners();
      _saveProfiles();
    }
  }

  void addProfile(UserProfile p) {
    _profiles.add(p);
    _activeIndex = _profiles.length - 1;
    notifyListeners();
    _saveProfiles();
  }

  void updateActive(UserProfile updated) {
    if (_activeIndex >= 0 && _activeIndex < _profiles.length) {
      _profiles[_activeIndex] = updated;
      notifyListeners();
      _saveProfiles();
    }
  }

  // ✅ ISSUE 4 FIXED: Delete profile method
  Future<void> deleteProfile(int index) async {
    if (index >= 0 && index < _profiles.length) {
      _profiles.removeAt(index);

      // Adjust active index if needed
      if (_activeIndex >= _profiles.length && _profiles.isNotEmpty) {
        _activeIndex = _profiles.length - 1;
      } else if (_profiles.isEmpty) {
        _activeIndex = 0;
      }

      notifyListeners();
      await _saveProfiles();
    }
  }
}

final _profilesState = _ProfilesState();

// ═══════════════════════════════════════════════════════════════════════════════
//  DiabeticCareScreen
// ═══════════════════════════════════════════════════════════════════════════════

class DiabeticCareScreen extends StatefulWidget {
  const DiabeticCareScreen({super.key});

  @override
  State<DiabeticCareScreen> createState() => _DiabeticCareScreenWidgetState();
}

class _DiabeticCareScreenWidgetState extends State<DiabeticCareScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ ISSUE 2 FIXED: Load profiles from SharedPreferences on app start
    _profilesState.loadProfiles().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: AnimatedBuilder(
          animation: healthRecordsState,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                // ── Hero SliverAppBar ────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: AppTheme.darkGreen,
                  titleSpacing: 0,
                  title: Text(
                    'Consultants',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/bg_consultant_care.png',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.darkGreen.withOpacity(0.55),
                                AppTheme.primaryGreen.withOpacity(0.45),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.favorite_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Expert Guidance',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Monitor & manage your health',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── My Profile – Specialist Quick Pick ────────
                        const _MyProfileSpecialistRow(),

                        const SizedBox(height: 14),

                        // ── Find A Doctor Banner ──────────────────────
                        _FindDoctorBanner(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FindDoctorScreen())),
                        ),

                        const SizedBox(height: 14),

                        // ── Upcoming Appointments ─────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Appointments',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                              child: Text(
                                'View All',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _AppointmentsCard(
                          onBookNew: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FindDoctorScreen())),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Find A Doctor Banner ─────────────────────────────────────────────────────

class _FindDoctorBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _FindDoctorBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find A Doctor',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Book an appointment with a\nreputed doctor from the\nHealthX network.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search,
                                    color: AppTheme.primaryGreen, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'Search',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 58),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Health Records Banner ────────────────────────────────────────────────────

class _RecordsBanner extends StatelessWidget {
  final int recordCount;
  final VoidCallback onTap;
  const _RecordsBanner({required this.recordCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  right: -12,
                  top: -12,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Health Records',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (recordCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$recordCount',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Store & share your lab reports,\nprescriptions and scans\nsecurely in one place.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_rounded,
                                    color: Color(0xFF1565C0), size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  recordCount > 0
                                      ? 'View Records'
                                      : 'Upload Record',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1565C0),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.folder_special_rounded,
                        color: Colors.white, size: 58),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Appointments Card ────────────────────────────────────────────────────────

class _AppointmentsCard extends StatelessWidget {
  final VoidCallback onBookNew;
  const _AppointmentsCard({required this.onBookNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No upcoming appointments',
              style: GoogleFonts.poppins(
                color: AppTheme.textMedium,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onBookNew,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Book New',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── My Profile – Specialist Row ─────────────────────────────────────────────
// Collapsed: auto-scroll PageView-style with smooth snap.
// Expanded: full 4-column grid.

class _MyProfileSpecialistRow extends StatefulWidget {
  const _MyProfileSpecialistRow();

  @override
  State<_MyProfileSpecialistRow> createState() =>
      _MyProfileSpecialistRowState();
}

class _MyProfileSpecialistRowState extends State<_MyProfileSpecialistRow> {
  bool _expanded = false;

  static const List<_SpecItem> _specs = [
    _SpecItem('Dermatologist',          Icons.face_retouching_natural_rounded, Color(0xFFFFB3BA), Color(0xFFB71C1C)),
    _SpecItem('Neurologist',            Icons.psychology_rounded,              Color(0xFFFFDFBA), Color(0xFFE65100)),
    _SpecItem('Nephrologist',           Icons.water_drop_rounded,              Color(0xFFBAFFCE), Color(0xFF1B5E20)),
    _SpecItem('Consulting Physician',   Icons.medical_information_rounded,     Color(0xFFBAD4FF), Color(0xFF0D47A1)),
    _SpecItem('Diabetologist',          Icons.monitor_heart_rounded,           Color(0xFFFFB3BA), Color(0xFFC62828)),
    _SpecItem('Cardiologist',           Icons.favorite_rounded,                Color(0xFFFFB3D9), Color(0xFFAD1457)),
    _SpecItem('General Physician',      Icons.local_hospital_rounded,          Color(0xFFBAFFEE), Color(0xFF1B7A5A)),
    _SpecItem('Endocrinologist',        Icons.biotech_rounded,                 Color(0xFFE8BAFF), Color(0xFF6A1B9A)),
    _SpecItem('Psychiatrist',           Icons.self_improvement_rounded,        Color(0xFFFFE4BA), Color(0xFFBF6000)),
    _SpecItem('Gynaecologist',          Icons.pregnant_woman_rounded,          Color(0xFFFFBAD4), Color(0xFF880E4F)),
    _SpecItem('Pulmonologist',          Icons.air_rounded,                     Color(0xFFBAF0FF), Color(0xFF01579B)),
    _SpecItem('Gastroenterologist',     Icons.airline_seat_flat_rounded,       Color(0xFFBAFFBA), Color(0xFF1B5E20)),
    _SpecItem('Orthopedician',          Icons.accessibility_new_rounded,       Color(0xFFFFDFBA), Color(0xFFBF360C)),
    _SpecItem('Pediatrician',           Icons.child_care_rounded,              Color(0xFFFFB3BA), Color(0xFFB71C1C)),
    _SpecItem('ENT',                    Icons.hearing_rounded,                 Color(0xFFBAD4FF), Color(0xFF1565C0)),
    _SpecItem('Ophthalmologist',        Icons.visibility_rounded,              Color(0xFFE8BAFF), Color(0xFF4A148C)),
    _SpecItem('Oncologist',             Icons.science_rounded,                 Color(0xFFFFBAD4), Color(0xFF880E4F)),
    _SpecItem('Rheumatologist',         Icons.elderly_rounded,                 Color(0xFFBAFFCE), Color(0xFF2E7D32)),
    _SpecItem('General',                Icons.local_hospital_rounded,          Color(0xFFBAFFEE), Color(0xFF1B7A5A)),
    _SpecItem('Others',                 Icons.category_rounded,                Color(0xFFE3E8F0), Color(0xFF455A64)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: healthRecordsState,
      builder: (_, __) {
        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medical_services_rounded,
                          color: AppTheme.primaryGreen, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Records',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark),
                        ),
                        Text(
                          'Tap to view records',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textLight),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Expand/collapse toggle — only visible when ≥ 5 records
                    AnimatedBuilder(
                      animation: healthRecordsState,
                      builder: (_, __) {
                        final total = healthRecordsState.records.length;
                        if (total < 5) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _expanded
                                  ? AppTheme.emerald50
                                  : AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _expanded
                                      ? AppTheme.primaryGreen.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _expanded ? 'Collapse' : 'View All',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: _expanded
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textMedium,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 3),
                                AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 15,
                                      color: _expanded
                                          ? AppTheme.primaryGreen
                                          : AppTheme.textMedium),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Add record "+" button
                    GestureDetector(
                      onTap: () => _showAddRecordSheet(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Collapsed: only specialists that HAVE records ──────────
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Builder(builder: (ctx) {
                    final withRecs = _specs
                        .where((s) => healthRecordsState
                        .hasRecordsForSpecialist(s.name))
                        .toList();

                    if (withRecs.isEmpty) {
                      // No records yet — subtle empty hint
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 13,
                                color: AppTheme.textLight),
                            const SizedBox(width: 6),
                            Text(
                              'No records uploaded yet',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: withRecs.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final s = withRecs[i];
                          return SizedBox(
                            width: 76,
                            height: 100,
                            child: _SpecChip(
                              spec: s,
                              hasRecords: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HealthRecordsScreen(
                                      specialist: s.name),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),

              // ── Expanded: grid of specialists WITH records only ────────
              if (_expanded)
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Builder(builder: (ctx) {
                      final withRecs = _specs
                          .where((s) => healthRecordsState
                          .hasRecordsForSpecialist(s.name))
                          .toList();
                      if (withRecs.isEmpty) return const SizedBox.shrink();
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: withRecs.length,
                        itemBuilder: (ctx, i) {
                          final s = withRecs[i];
                          return _SpecChip(
                            spec: s,
                            hasRecords: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HealthRecordsScreen(specialist: s.name),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Add Record Flow ─────────────────────────────────────────────────────────
  // Step 1: Bottom sheet – select report type
  // Step 2: Camera / Gallery source picker
  // Step 3: Navigate to _PreviewUploadScreen (from health_records.dart)

  void _showAddRecordSheet(BuildContext context) {
    RecordType _selectedType = RecordType.labTests;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomPad = MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_chart_rounded,
                            color: AppTheme.primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Report Type',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark)),
                          Text(
                              'Choose the type of record to upload',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textMedium)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Report type cards
                  ...RecordType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? type.color.withOpacity(0.08)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? type.color
                                : Colors.grey.withOpacity(0.18),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(isSelected ? 0.18 : 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(type.icon,
                                  color: type.color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                type.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? type.color
                                        : AppTheme.textDark),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Icon(Icons.check_circle_rounded,
                                  key: const ValueKey('check'),
                                  color: type.color,
                                  size: 22)
                                  : const SizedBox(
                                  key: ValueKey('empty'),
                                  width: 22,
                                  height: 22),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 6),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _showSourcePickerSheet(context, _selectedType);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Continue',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Step 2: Camera / Gallery / Files source picker
  void _showSourcePickerSheet(BuildContext context, RecordType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetCtx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: type.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(type.icon, color: type.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload ${type.label}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                      Text('How would you like to add this record?',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textMedium)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Camera — navigate INSTANTLY, image loads inside preview screen
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                subtitle: 'Capture document using camera',
                color: const Color(0xFF1565C0),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final picker = ImagePicker();
                  final future = picker
                      .pickImage(
                      source: ImageSource.camera, imageQuality: 85)
                      .then((x) =>
                  x != null ? [File(x.path)] : <File>[]);
                  _goToPreviewFuture(context, future, type);
                },
              ),
              const SizedBox(height: 10),

              // Gallery — navigate INSTANTLY, images load inside preview screen
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                subtitle: 'Select photos from your gallery',
                color: const Color(0xFF7B1FA2),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final picker = ImagePicker();
                  final future = picker
                      .pickMultiImage(imageQuality: 85)
                      .then((xs) =>
                      xs.map((x) => File(x.path)).toList());
                  _goToPreviewFuture(context, future, type);
                },
              ),
              const SizedBox(height: 10),

              // Files (PDF / Docs) — navigate INSTANTLY
              _SourceOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'Upload File',
                subtitle: 'PDF, JPG, PNG from your storage',
                color: const Color(0xFFE65100),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final future = FilePicker.platform
                      .pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  )
                      .then((r) => r == null
                      ? <File>[]
                      : r.paths
                      .whereType<String>()
                      .map((p) => File(p))
                      .toList());
                  _goToPreviewFuture(context, future, type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Step 3a: Navigate INSTANTLY with a Future — zero waiting on the sheet
  void _goToPreviewFuture(
      BuildContext context, Future<List<File>> filesFuture, RecordType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPreviewScreen(
          filesFuture: filesFuture,
          type: type,
          defaultSpecialist: '',
          onConfirm: (name, date, finalType, specialist, resolvedFiles) {
            final record = HealthRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name.trim().isEmpty ? finalType.label : name.trim(),
              type: finalType,
              date: date,
              fileUrls: resolvedFiles.map((f) => f.path).toList(),
              specialist: specialist,
            );
            healthRecordsState.addRecord(record);
          },
        ),
      ),
    );
  }

  // Step 3b: Navigate with pre-loaded files (used from _UploadRecordSheet flow)
  void _goToPreview(
      BuildContext context, List<File> files, RecordType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPreviewScreen(
          files: files,
          type: type,
          defaultSpecialist: '',
          onConfirm: (name, date, finalType, specialist, resolvedFiles) {
            final record = HealthRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name.trim().isEmpty ? finalType.label : name.trim(),
              type: finalType,
              date: date,
              fileUrls: resolvedFiles.map((f) => f.path).toList(),
              specialist: specialist,
            );
            healthRecordsState.addRecord(record);
          },
        ),
      ),
    );
  }
}

// ─── Source Option Tile ───────────────────────────────────────────────────────
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: color.withOpacity(0.2), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textMedium)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Spec Item model ──────────────────────────────────────────────────────────
class _SpecItem {
  final String name;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _SpecItem(this.name, this.icon, this.bgColor, this.iconColor);
}

// ─── Spec Chip ────────────────────────────────────────────────────────────────
// Every card is exactly the same size. Text uses FittedBox so it ALWAYS
// scales down to fit — no mid-word breaks, no overflow, ever.
class _SpecChip extends StatelessWidget {
  final _SpecItem spec;
  final bool hasRecords;
  final VoidCallback onTap;
  const _SpecChip({
    required this.spec,
    required this.hasRecords,
    required this.onTap,
  });

  // Clean two-line labels
  String get _label {
    switch (spec.name) {
      case 'Dermatologist':        return 'Dermato-\nlogist';
      case 'Neurologist':          return 'Neuro-\nlogist';
      case 'Nephrologist':         return 'Nephro-\nlogist';
      case 'Consulting Physician': return 'Consulting\nPhysician';
      case 'Diabetologist':        return 'Diabeto-\nlogist';
      case 'Cardiologist':         return 'Cardio-\nlogist';
      case 'General Physician':    return 'General\nPhysician';
      case 'Endocrinologist':      return 'Endocrino-\nlogist';
      case 'Psychiatrist':         return 'Psychia-\ntrist';
      case 'Gynaecologist':        return 'Gynaeco-\nlogist';
      case 'Pulmonologist':        return 'Pulmono-\nlogist';
      case 'Gastroenterologist':   return 'Gastro-\nentero';
      case 'Orthopedician':        return 'Orthope-\ndician';
      case 'Pediatrician':         return 'Pediatri-\ncian';
      case 'ENT':                  return 'ENT';
      case 'Ophthalmologist':      return 'Ophthal-\nmologist';
      case 'Oncologist':           return 'Onco-\nlogist';
      case 'Rheumatologist':       return 'Rheumato-\nlogist';
      case 'General':              return 'General';
      case 'Others':               return 'Others';
      default:                     return spec.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: spec.bgColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: spec.iconColor.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Icon circle with record dot ──────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: spec.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(spec.icon,
                      color: spec.iconColor, size: 20),
                ),
                if (hasRecords)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Label ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}