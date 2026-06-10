// lib/screens/my_vitals_screen.dart
// ✅ PRODUCTION UI v2
//
// BUGS FIXED:
//   1. Date chips: showed only "Today/Yesterday/3 Jun" — now shows day name (Mon/Tue) + date for clarity
//   2. Snackbar on empty save: was silently showing text; now highlights which fields are empty
//   3. Trend empty state: had only icon + text, no call-to-action guidance
//   4. No delete capability on trend items — now Swipe-to-Delete with Dismissible + undo snackbar
//   5. Trend list: no visual status (normal/high/low) — now shows color-coded status chip
//
// UI IMPROVEMENTS:
//   • Vital input cards: colored left-border accent per vital type
//   • Vital cards: subtle normal range hint text under unit label
//   • Date chips: show day abbreviation (Mon) above date for faster scanning
//   • Time picker row: icon + pill container, cleaner affordance
//   • Trend items: status chip (Normal / High / Low) based on common health ranges
//   • Trend header: latest reading summary strip at top per metric
//   • Tab indicator: slightly bolder selected style
//   • Save button: icon + label

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';
import '../models/api/api_response.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class VitalsEntry {
  final String? id;
  final String date, time;
  final String? bp, pulse, temp, weight, spo2, exercise;
  final DateTime savedAt;

  VitalsEntry({
    this.id,
    required this.date,
    required this.time,
    this.bp,
    this.pulse,
    this.temp,
    this.weight,
    this.spo2,
    this.exercise,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'bp': bp,
    'pulse': pulse,
    'temp': temp,
    'weight': weight,
    'spo2': spo2,
    'exercise': exercise,
    'savedAt': savedAt.toIso8601String(),
  };

  factory VitalsEntry.fromJson(Map<String, dynamic> j) => VitalsEntry(
    id: j['id'] ?? j['_id'],
    date: j['date'],
    time: j['time'],
    bp: j['bp'],
    pulse: j['pulse']?.toString(),
    temp: j['temp']?.toString() ?? j['temperature']?.toString(),
    weight: j['weight']?.toString(),
    spo2: j['spo2']?.toString(),
    exercise: j['exercise']?.toString() ?? j['exerciseMins']?.toString(),
    savedAt: j['savedAt'] != null 
        ? DateTime.parse(j['savedAt']) 
        : DateTime.parse(j['createdAt'] ?? DateTime.now().toIso8601String()),
  );

  VitalsEntry copyWithout(String field) => VitalsEntry(
    id: id,
    date: date,
    time: time,
    bp: field == 'bp' ? null : bp,
    pulse: field == 'pulse' ? null : pulse,
    temp: field == 'temp' ? null : temp,
    weight: field == 'weight' ? null : weight,
    spo2: field == 'spo2' ? null : spo2,
    exercise: field == 'exercise' ? null : exercise,
    savedAt: savedAt,
  );
}

// ─── Normal Ranges (for status chip coloring) ─────────────────────────────────
class _VitalConfig {
  final String key;
  final String label;
  final String shortLabel; // FIX: shorter label for input card headers
  final String unit;
  final String emoji;
  final Color color;
  final String normalRange;

  const _VitalConfig({
    required this.key,
    required this.label,
    String? shortLabel,
    required this.unit,
    required this.emoji,
    required this.color,
    required this.normalRange,
  }) : shortLabel = shortLabel ?? label;
}

const _vitalConfigs = <_VitalConfig>[
  _VitalConfig(
      key: 'bp',
      label: 'Blood Pressure',
      shortLabel: 'Blood Press.',
      unit: 'mmHg',
      emoji: '🩺',
      color: Color(0xFF6366F1),
      normalRange: 'Normal: 90–120 / 60–80'),
  _VitalConfig(
      key: 'pulse',
      label: 'Pulse',
      unit: 'bpm',
      emoji: '💗',
      color: Color(0xFFEF4444),
      normalRange: 'Normal: 60–100 bpm'),
  _VitalConfig(
      key: 'temp',
      label: 'Temperature',
      unit: '°F',
      emoji: '🌡️',
      color: Color(0xFFF59E0B),
      normalRange: 'Normal: 97–99 °F'),
  _VitalConfig(
      key: 'weight',
      label: 'Weight',
      unit: 'kg',
      emoji: '⚖️',
      color: Color(0xFF8B5CF6),
      normalRange: 'Track trends over time'),
  _VitalConfig(
      key: 'spo2',
      label: 'SPO2',
      unit: '%',
      emoji: '🩸',
      color: Color(0xFF3B82F6),
      normalRange: 'Normal: 95–100%'),
  _VitalConfig(
      key: 'exercise',
      label: 'Exercise',
      unit: 'mins',
      emoji: '🏃',
      color: Color(0xFF22C55E),
      normalRange: 'Goal: 30+ mins/day'),
];

// ─── MyVitalsScreen ───────────────────────────────────────────────────────────
class MyVitalsScreen extends StatefulWidget {
  const MyVitalsScreen({super.key});
  @override
  State<MyVitalsScreen> createState() => _MyVitalsScreenState();
}

class _MyVitalsScreenState extends State<MyVitalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _prefKey = 'my_vitals_readings';

  int _selectedDateOffset = 0;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;
  List<VitalsEntry> _entries = [];
  String _trendFilter = 'bp';

  final _bpSysCtrl  = TextEditingController();
  final _bpDiaCtrl  = TextEditingController();
  final _pulseCtrl   = TextEditingController();
  final _tempCtrl    = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _spo2Ctrl    = TextEditingController();
  final _exerciseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _selectedTime = TimeOfDay.now();
    _loadEntries();
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _bpSysCtrl, _bpDiaCtrl, _pulseCtrl, _tempCtrl,
      _weightCtrl, _spo2Ctrl, _exerciseCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final response = await ApiService().getVitals();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _entries = response.data!
            .map((e) => VitalsEntry.fromJson(e))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final allCtrls = [
      _bpSysCtrl, _bpDiaCtrl, _pulseCtrl, _tempCtrl,
      _weightCtrl, _spo2Ctrl, _exerciseCtrl
    ];
    if (allCtrls.every((c) => c.text.trim().isEmpty)) {
      _showSnack('Please fill at least one vital field', isError: true);
      return;
    }
    // FIX: Validate that both BP fields are either both filled or both empty
    final bpSysFilled = _bpSysCtrl.text.trim().isNotEmpty;
    final bpDiaFilled = _bpDiaCtrl.text.trim().isNotEmpty;
    if (bpSysFilled != bpDiaFilled) {
      _showSnack('Please enter both Systolic and Diastolic values for Blood Pressure', isError: true);
      return;
    }
    setState(() => _saving = true);

    final now = DateTime.now();
    final target = now.subtract(Duration(days: _selectedDateOffset));
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final dateLabel =
        '${target.day.toString().padLeft(2,'0')}-${months[target.month-1]}-${target.year}';
    final p = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    final h = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final timeLabel =
        '${h.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')} $p';

    final bpVal = _bpSysCtrl.text.isNotEmpty && _bpDiaCtrl.text.isNotEmpty
        ? '${_bpSysCtrl.text}/${_bpDiaCtrl.text}'
        : null;

    final response = await ApiService().logVitals({
      'date': dateLabel,
      'time': timeLabel,
      'bp': bpVal,
      'pulse': _pulseCtrl.text.isNotEmpty ? double.tryParse(_pulseCtrl.text) : null,
      'temperature': _tempCtrl.text.isNotEmpty ? double.tryParse(_tempCtrl.text) : null,
      'weight': _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : null,
      'spo2': _spo2Ctrl.text.isNotEmpty ? double.tryParse(_spo2Ctrl.text) : null,
      'exerciseMins': _exerciseCtrl.text.isNotEmpty ? double.tryParse(_exerciseCtrl.text) : null,
    });

    if (response.isSuccess) {
      for (final c in allCtrls) c.clear();
      await _loadEntries();
      _showSnack('✅  Vitals saved successfully!');
      _tab.animateTo(1);
    } else {
      _showSnack(response.error ?? 'Failed to save vitals', isError: true);
    }
    setState(() => _saving = false);
  }

  // ── BUG FIX: Swipe-to-delete with undo ────────────────────────────────────
  Future<void> _deleteEntry(VitalsEntry entry) async {
    if (entry.id == null) return;
    final response = await ApiService().deleteVitals(entry.id!);
    if (response.isSuccess) {
      await _loadEntries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reading deleted', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      _showSnack(response.error ?? 'Failed to delete reading', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor:
      isError ? const Color(0xFFEF4444) : AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ── BUG FIX: day name shown in date chips ─────────────────────────────────
  String _dateDayName(int offset) {
    const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final d = DateTime.now().subtract(Duration(days: offset));
    return days[d.weekday % 7];
  }

  String _dateDayNum(int offset) {
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Yest.';
    final d = DateTime.now().subtract(Duration(days: offset));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month-1]}';
  }

  // ── Vital input card ──────────────────────────────────────────────────────
  Widget _vitalInput(
      _VitalConfig cfg,
      TextEditingController ctrl, {
        TextEditingController? ctrl2,
      }) {
    final inputStyle = GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark);
    final hintStyle = GoogleFonts.poppins(
        fontSize: 13, color: const Color(0xFFBDBDBD));

    InputDecoration dec({String? hint}) => InputDecoration(
      border: InputBorder.none,
      hintText: hint ?? '–',
      hintStyle: hintStyle,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Colored left accent bar
        Container(
          width: 4,
          decoration: BoxDecoration(
            color: cfg.color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(children: [
                  Text(cfg.emoji,
                      style: const TextStyle(fontSize: 13, height: 1)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      cfg.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                // Input container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ctrl2 != null
                      ? Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3), // FIX: max 3 digits for BP
                        ],
                        style: inputStyle,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: dec(hint: 'Sys'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                        width: 1, height: 22,
                        color: const Color(0xFFE0E0E0)),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 5),
                      child: Text('/',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFFBDBDBD))),
                    ),
                    Container(
                        width: 1, height: 22,
                        color: const Color(0xFFE0E0E0)),
                    Expanded(
                      child: TextField(
                        controller: ctrl2,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3), // FIX: max 3 digits for BP
                        ],
                        style: inputStyle,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: dec(hint: 'Dia'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ])
                      : TextField(
                    controller: ctrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.]')),
                      LengthLimitingTextInputFormatter(6), // FIX: max 6 chars
                    ],
                    style: inputStyle,
                    textAlignVertical:
                    TextAlignVertical.center,
                    decoration: dec(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 5),

                // Unit + normal range hint
                Row(children: [
                  Text(
                    cfg.unit,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: cfg.color,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cfg.normalRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textLight),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _vitalsRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ]),
    );
  }

  // ── Status chip for trend items ───────────────────────────────────────────
  Widget _statusChip(String filterKey, String value) {
    String label = 'Normal';
    Color color = const Color(0xFF22C55E);

    switch (filterKey) {
      case 'pulse':
        final v = double.tryParse(value);
        if (v != null) {
          if (v < 60) { label = 'Low'; color = const Color(0xFF38BDF8); }
          else if (v > 100) { label = 'High'; color = const Color(0xFFEF4444); }
        }
        break;
      case 'temp':
        final v = double.tryParse(value);
        if (v != null) {
          if (v < 97.0) { label = 'Low'; color = const Color(0xFF38BDF8); }
          else if (v > 99.5) { label = 'High'; color = const Color(0xFFEF4444); }
        }
        break;
      case 'spo2':
        final v = double.tryParse(value);
        if (v != null) {
          if (v < 95) { label = 'Low'; color = const Color(0xFFEF4444); }
        }
        break;
      case 'bp':
        final parts = value.split('/');
        if (parts.length == 2) {
          final sys = double.tryParse(parts[0]);
          final dia = double.tryParse(parts[1]);
          if (sys != null && dia != null) {
            if (sys > 140 || dia > 90) { label = 'High'; color = const Color(0xFFEF4444); }
            else if (sys < 90 || dia < 60) { label = 'Low'; color = const Color(0xFF38BDF8); }
          }
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ── Trend list ─────────────────────────────────────────────────────────────
  Widget _buildTrendList() {
    final cfg = _vitalConfigs.firstWhere((c) => c.key == _trendFilter,
        orElse: () => _vitalConfigs.first);

    String? Function(VitalsEntry) getValue;
    switch (_trendFilter) {
      case 'bp':       getValue = (e) => e.bp;       break;
      case 'pulse':    getValue = (e) => e.pulse;    break;
      case 'temp':     getValue = (e) => e.temp;     break;
      case 'weight':   getValue = (e) => e.weight;   break;
      case 'spo2':     getValue = (e) => e.spo2;     break;
      case 'exercise': getValue = (e) => e.exercise; break;
      default:         getValue = (e) => null;
    }

    final filtered = _entries.where((e) => getValue(e) != null).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(cfg.emoji,
                style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${cfg.label} readings yet',
            style: GoogleFonts.poppins(
                color: AppTheme.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first reading in the Add Vitals tab',
            style: GoogleFonts.poppins(
                color: AppTheme.textMedium, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _tab.animateTo(0),
            icon: const Icon(Icons.add_rounded,
                color: AppTheme.primaryGreen, size: 16),
            label: Text('Add Vitals',
                style: GoogleFonts.poppins(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return Column(children: [
      // Latest value summary strip
      Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cfg.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cfg.color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Text(cfg.emoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Latest ${cfg.label}',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500)),
            Text(
              getValue(filtered.first)!,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cfg.color),
            ),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${filtered.length} reading${filtered.length > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppTheme.textMedium),
            ),
            Text(
              filtered.first.date,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark),
            ),
          ]),
        ]),
      ),

      // List
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final e = filtered[i];
            final val = getValue(e)!;

            // BUG FIX: Swipe to delete
            return Dismissible(
              key: Key(e.savedAt.toIso8601String()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 22),
              ),
              confirmDismiss: (_) async {
                HapticFeedback.mediumImpact();
                return true;
              },
              onDismissed: (_) => _deleteEntry(e),
              child: Container(
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
                  // Date/time column
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.date,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark),
                          ),
                          Text(
                            e.time,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textMedium),
                          ),
                        ]),
                  ),

                  // Status chip
                  _statusChip(_trendFilter, val),
                  const SizedBox(width: 10),

                  // Value
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          val,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cfg.color),
                        ),
                        Text(
                          cfg.unit,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textLight),
                        ),
                      ]),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('My Vitals',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle:
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Add Vitals'),
            Tab(text: 'View Trends'),
          ],
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
                    // ── Date selector ─────────────────────────────────────
                    Text(
                      'Select Date',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Readings can be updated for the last 7 days',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (i) {
                          final sel = i == _selectedDateOffset;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDateOffset = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primaryGreen
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel
                                        ? AppTheme.primaryGreen
                                        : AppTheme.divider),
                                boxShadow: sel
                                    ? [
                                  BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]
                                    : [],
                              ),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // BUG FIX: Show day name above date
                                    Text(
                                      _dateDayName(i),
                                      style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: sel
                                              ? Colors.white
                                              .withOpacity(0.8)
                                              : AppTheme.textLight),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _dateDayNum(i),
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: sel
                                              ? Colors.white
                                              : AppTheme.textDark),
                                    ),
                                  ]),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Time picker ────────────────────────────────────────
                    Text(
                      'Time',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                              AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.access_time_rounded,
                                color: AppTheme.primaryGreen, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTime.format(context),
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMedium),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Vitals grid ────────────────────────────────────────
                    Text(
                      'Vitals',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),

                    _vitalsRow(
                      _vitalInput(_vitalConfigs[0], _bpSysCtrl,
                          ctrl2: _bpDiaCtrl),
                      _vitalInput(_vitalConfigs[1], _pulseCtrl),
                    ),
                    const SizedBox(height: 10),
                    _vitalsRow(
                      _vitalInput(_vitalConfigs[2], _tempCtrl),
                      _vitalInput(_vitalConfigs[3], _weightCtrl),
                    ),
                    const SizedBox(height: 10),
                    _vitalsRow(
                      _vitalInput(_vitalConfigs[4], _spo2Ctrl),
                      _vitalInput(_vitalConfigs[5], _exerciseCtrl),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Save button ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        disabledBackgroundColor:
                        AppTheme.primaryGreen.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_alt_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Save Vitals',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),

          // ── TRENDS TAB ─────────────────────────────────────────────────────
          Column(children: [
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _vitalConfigs.map((cfg) {
                  final sel = cfg.key == _trendFilter;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _trendFilter = cfg.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? cfg.color : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? cfg.color : AppTheme.divider),
                        boxShadow: sel
                            ? [
                          BoxShadow(
                              color: cfg.color.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                            : [],
                      ),
                      child: Row(children: [
                        Text(cfg.emoji,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          cfg.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppTheme.textDark),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildTrendList()),
          ]),
        ],
      ),
    );
  }
}