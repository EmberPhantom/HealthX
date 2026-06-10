// lib/screens/insulin_dosage_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';
import '../models/api/api_response.dart';

class InsulinEntry {
  final String? id;
  final String date, time;
  final double dosage;
  final String unit;
  final String brand;
  final DateTime savedAt;

  InsulinEntry({
    this.id,
    required this.date,
    required this.time,
    required this.dosage,
    required this.unit,
    required this.brand,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'time': time,
    'dosage': dosage,
    'unit': unit,
    'brand': brand,
    'savedAt': savedAt.toIso8601String(),
  };

  factory InsulinEntry.fromJson(Map<String, dynamic> j) {
    final DateTime dt = j['loggedAt'] != null 
        ? DateTime.parse(j['loggedAt']) 
        : (j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now());
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year}';
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final timeStr = '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';

    return InsulinEntry(
      id: j['id'] ?? j['_id'],
      date: dateStr,
      time: timeStr,
      dosage: (j['dose'] ?? j['dosage'] as num).toDouble(),
      unit: j['note'] ?? j['unit'] ?? 'units',
      brand: j['insulinType'] ?? j['brand'] ?? '',
      savedAt: dt,
    );
  }
}

class InsulinDosageScreen extends StatefulWidget {
  const InsulinDosageScreen({super.key});
  @override
  State<InsulinDosageScreen> createState() => _InsulinDosageScreenState();
}

class _InsulinDosageScreenState extends State<InsulinDosageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _prefKey = 'insulin_entries';

  int _selectedDateOffset = 0;
  final _dosageCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  String _selectedUnit = 'units';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;
  List<InsulinEntry> _entries = [];

  final List<String> _units = ['units', 'ml', 'IU'];

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
    _dosageCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final response = await ApiService().getInsulin();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _entries = response.data!
            .map((e) => InsulinEntry.fromJson(e))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final val = double.tryParse(_dosageCtrl.text.trim());
    if (val == null || val <= 0) {
      _showSnack('Please enter a valid dosage');
      return;
    }
    if (_brandCtrl.text.trim().isEmpty) {
      _showSnack('Please enter insulin brand name');
      return;
    }
    setState(() => _saving = true);

    final now = DateTime.now();
    final target = now.subtract(Duration(days: _selectedDateOffset));
    final loggedAt = DateTime(
      target.year,
      target.month,
      target.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).toIso8601String();

    final response = await ApiService().logInsulin({
      'dose': val,
      'insulinType': _brandCtrl.text.trim(),
      'note': _selectedUnit,
      'loggedAt': loggedAt,
    });

    if (response.isSuccess) {
      _dosageCtrl.clear();
      _brandCtrl.clear();
      await _loadEntries();
      _showSnack('Insulin log saved!');
      _tab.animateTo(1);
    } else {
      _showSnack(response.error ?? 'Failed to save insulin log');
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
        // ✅ Fixed: was 'Insulin' — now matches screen purpose
        title: Text('Insulin Dosage',
            style:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tab,
          labelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [Tab(text: 'Add Insulin'), Tab(text: 'View Trends')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── ADD TAB ──────────────────────────────────────────────────────
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
                    // ✅ HitTestBehavior.opaque — tap registers on full chip area
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
                    _label('Dosage *'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _dosageCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'))
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.poppins(
                                color: AppTheme.textLight, fontSize: 24),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 1.5)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          underline: const SizedBox(),
                          items: _units
                              .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textDark)),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedUnit = v!),
                        ),
                      ),
                    ]),

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
                    _label('Insulin Brand *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _brandCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Enter brand name',
                        hintStyle: GoogleFonts.poppins(
                            color: AppTheme.textLight),
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
                    // ✅ Minimal bottom buffer — button is in SafeArea, not floating
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
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
                      'Add Insulin Log',
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
          _entries.isEmpty
              ? Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.medication_liquid_rounded,
                  size: 64, color: AppTheme.textLight),
              const SizedBox(height: 12),
              Text(
                'No insulin logs yet',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMedium, fontSize: 15),
              ),
            ]),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final e = _entries[i];
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
                          '${e.date}, ${e.time}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Brand',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textLight),
                        ),
                        Text(
                          e.brand,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          e.dosage.toStringAsFixed(0),
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen),
                        ),
                        Text(
                          e.unit,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textLight),
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