// lib/screens/blood_glucose_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import 'my_vitals_screen.dart';
import 'insulin_dosage_screen.dart';
import 'set_reminders_screen.dart';
import '../services/api/api_service.dart';
import '../models/api/api_response.dart';

class BloodGlucoseReading {
  final String? id;
  final String date;
  final String time;
  final double value;
  final String status;
  final DateTime savedAt;

  BloodGlucoseReading({
    this.id,
    required this.date,
    required this.time,
    required this.value,
    required this.status,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'value': value,
    'status': status,
    'savedAt': savedAt.toIso8601String(),
  };

  factory BloodGlucoseReading.fromJson(Map<String, dynamic> j) {
    final DateTime dt = j['loggedAt'] != null 
        ? DateTime.parse(j['loggedAt']) 
        : (j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now());
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final timeStr = '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';

    String statusStr = j['status'] ?? '';
    if (statusStr.isEmpty && j['readingType'] != null) {
      switch (j['readingType']) {
        case 'fasting':
          statusStr = 'Fasting Blood Sugar';
          break;
        case 'post_meal':
          statusStr = 'After Meal (2hrs)';
          break;
        case 'random':
        default:
          statusStr = 'Random Blood Sugar';
          break;
      }
    }

    return BloodGlucoseReading(
      id: j['id'] ?? j['_id'],
      date: dateStr,
      time: timeStr,
      value: (j['level'] ?? j['value'] as num).toDouble(),
      status: statusStr,
      savedAt: dt,
    );
  }
}

class BloodGlucoseScreen extends StatefulWidget {
  const BloodGlucoseScreen({super.key});
  @override
  State<BloodGlucoseScreen> createState() => _BloodGlucoseScreenState();
}

class _BloodGlucoseScreenState extends State<BloodGlucoseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _prefKey = 'blood_glucose_readings';

  int _selectedDateOffset = 0;
  final _valueController = TextEditingController();
  String _selectedStatus = 'Fasting Blood Sugar';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;
  List<BloodGlucoseReading> _readings = [];

  final List<String> _foodStatuses = [
    'Fasting Blood Sugar',
    'Before Meal',
    'After Meal (2hrs)',
    'Random Blood Sugar',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _selectedTime = TimeOfDay.now();
    _loadReadings();
  }

  @override
  void dispose() {
    _tab.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadReadings() async {
    final response = await ApiService().getGlucose();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _readings = response.data!
            .map((e) => BloodGlucoseReading.fromJson(e))
            .toList();
      });
    }
  }

  Future<void> _saveReading() async {
    final val = double.tryParse(_valueController.text.trim());
    if (val == null || val <= 0) {
      _showSnack('Please enter a valid glucose value');
      return;
    }
    setState(() => _saving = true);

    String readingType = 'random';
    if (_selectedStatus == 'Fasting Blood Sugar') {
      readingType = 'fasting';
    } else if (_selectedStatus == 'Before Meal') {
      readingType = 'random';
    } else if (_selectedStatus == 'After Meal (2hrs)') {
      readingType = 'post_meal';
    } else if (_selectedStatus == 'Random Blood Sugar') {
      readingType = 'random';
    }

    final now = DateTime.now();
    final targetDate = now.subtract(Duration(days: _selectedDateOffset));
    final loggedAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).toIso8601String();

    final response = await ApiService().logGlucose({
      'level': val,
      'readingType': readingType,
      'loggedAt': loggedAt,
    });

    if (response.isSuccess) {
      _valueController.clear();
      await _loadReadings();
      _showSnack('Reading saved successfully!');
      _tab.animateTo(1);
    } else {
      _showSnack(response.error ?? 'Failed to save glucose reading');
    }
    setState(() => _saving = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _dateLabel(int offset) {
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Yesterday';
    final d = DateTime.now().subtract(Duration(days: offset));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Color _statusColor(double val) {
    if (val < 70) return const Color(0xFF3B82F6);
    if (val <= 99) return AppTheme.primaryGreen;
    if (val <= 125) return AppTheme.orange;
    return AppTheme.red;
  }

  String _statusBadge(double val) {
    if (val < 70) return 'Low';
    if (val <= 99) return 'Normal';
    if (val <= 125) return 'Pre-Diabetic';
    return 'High';
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Blood Glucose',
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Diabetic Care Quick Nav ──────────────────────────────────
              _DiabetesQuickNav(current: 'glucose'),
              // ── Original TabBar ──────────────────────────────────────────
              TabBar(
                controller: _tab,
                labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.textMedium,
                indicatorColor: AppTheme.primaryGreen,
                indicatorWeight: 2.5,
                tabs: const [Tab(text: 'Add Reading'), Tab(text: 'View Trends')],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── ADD TAB ────────────────────────────────────────────────────────
          Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Select Date: *'),
                    const SizedBox(height: 4),
                    Text(
                      'Readings can be updated for the last 7 days',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 10),
                    // ✅ HitTestBehavior.opaque ensures tap registers even on
                    // transparent/padded edges of each date chip.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (i) {
                          final sel = i == _selectedDateOffset;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                setState(() => _selectedDateOffset = i),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primaryGreen
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.primaryGreen
                                      : AppTheme.divider,
                                ),
                              ),
                              child: Text(
                                _dateLabel(i),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textDark),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Glucose Reading *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter Glucose Reading',
                        hintStyle: GoogleFonts.poppins(
                            color: AppTheme.textLight),
                        suffixText: 'mg/dL',
                        suffixStyle:
                        GoogleFonts.poppins(color: AppTheme.textMedium),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryGreen, width: 1.5)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Time *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(children: [
                          const Icon(Icons.access_time_rounded,
                              color: AppTheme.textMedium, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: AppTheme.textDark),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.textMedium),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Food Intake Status: *'),
                    const SizedBox(height: 8),
                    ...List.generate(_foodStatuses.length, (i) {
                      final s = _foodStatuses[i];
                      return RadioListTile<String>(
                        value: s,
                        groupValue: _selectedStatus,
                        onChanged: (v) =>
                            setState(() => _selectedStatus = v!),
                        title: Text(s,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppTheme.textDark)),
                        activeColor: AppTheme.primaryGreen,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    // ✅ Small bottom buffer so last item isn't hidden behind button
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // ✅ SafeArea + bottom button — no magic height hack needed
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                        : Text(
                      'Add Reading',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ]),

          // ── TRENDS TAB ─────────────────────────────────────────────────────
          _readings.isEmpty
              ? Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.show_chart_rounded,
                  size: 64, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(
                'No readings yet',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMedium, fontSize: 15),
              ),
            ]),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _readings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = _readings[i];
              final color = _statusColor(r.value);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.date}, ${r.time}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.status,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textMedium),
                          ),
                        ]),
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          r.value.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                        Text(
                          'mg/dL',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textLight),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusBadge(r.value),
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ),
                      ]),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}
// ─── Diabetes Care Quick Nav Strip ───────────────────────────────────────────
// Shared horizontal pill nav — shows across Blood Glucose, My Vitals,
// Insulin Dosage, Set Reminders. Current screen is highlighted.
class _DiabetesQuickNav extends StatelessWidget {
  final String current; // 'glucose' | 'vitals' | 'insulin' | 'reminders'
  const _DiabetesQuickNav({required this.current});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(id: 'glucose',   icon: Icons.water_drop_rounded,        label: 'Glucose'),
      _NavItem(id: 'insulin',   icon: Icons.medication_rounded,         label: 'Insulin'),
      _NavItem(id: 'vitals',    icon: Icons.monitor_heart_outlined,     label: 'Vitals'),
      _NavItem(id: 'reminders', icon: Icons.notifications_active_rounded, label: 'Reminders'),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            final isActive = item.id == current;
            return GestureDetector(
              onTap: isActive ? null : () => _navigate(context, item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryGreen
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? null
                      : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 13,
                      color: isActive ? Colors.white : AppTheme.textMedium,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String id) {
    HapticFeedback.lightImpact();
    Widget screen;
    switch (id) {
      case 'insulin':   screen = const InsulinDosageScreen(); break;
      case 'vitals':    screen = const MyVitalsScreen();      break;
      case 'reminders': screen = const SetRemindersScreen();  break;
      default:          return; // already on glucose
    }
    // push — so back arrow returns to glucose (root of diabetic nav)
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final IconData icon;
  final String label;
  const _NavItem({required this.id, required this.icon, required this.label});
}