// lib/screens/health_records.dart
// ─── Standalone Health Records module ────────────────────────────────────────
// All record models, state, screens and widgets live here.
// Import this file wherever HealthRecord / healthRecordsState / HealthRecordsScreen
// are needed.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';
import '../services/api/api_service.dart';
import '../services/api/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Record Type
// ═══════════════════════════════════════════════════════════════════════════════

enum RecordType { labTests, prescription, scans, other }

extension RecordTypeLabel on RecordType {
  String get label {
    switch (this) {
      case RecordType.labTests:     return 'Lab Tests';
      case RecordType.prescription: return 'Prescription';
      case RecordType.scans:        return 'Scans';
      case RecordType.other:        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordType.labTests:     return Icons.biotech_rounded;
      case RecordType.prescription: return Icons.medication_rounded;
      case RecordType.scans:        return Icons.document_scanner_rounded;
      case RecordType.other:        return Icons.folder_rounded;
    }
  }

  Color get color {
    switch (this) {
      case RecordType.labTests:     return const Color(0xFF2196F3);
      case RecordType.prescription: return const Color(0xFF4CAF50);
      case RecordType.scans:        return const Color(0xFF9C27B0);
      case RecordType.other:        return const Color(0xFFFF9800);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HealthRecord Model
// ═══════════════════════════════════════════════════════════════════════════════

class HealthRecord {
  final String id;
  final String name;
  final RecordType type;
  final DateTime date;
  final List<String> fileUrls;
  /// The specialist this record belongs to, e.g. 'Cardiologist'.
  /// Empty string means "general / unassigned".
  final String specialist;

  HealthRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.fileUrls,
    this.specialist = '',
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'other';
    RecordType rType;
    switch (typeStr) {
      case 'labTests':
        rType = RecordType.labTests;
        break;
      case 'prescription':
        rType = RecordType.prescription;
        break;
      case 'scans':
        rType = RecordType.scans;
        break;
      default:
        rType = RecordType.other;
    }

    return HealthRecord(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: rType,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
      specialist: json['specialist'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Records State (singleton in-memory store)
// ═══════════════════════════════════════════════════════════════════════════════

class HealthRecordsState extends ChangeNotifier {
  final List<HealthRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<HealthRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Records for a specific specialist (case-insensitive).
  List<HealthRecord> forSpecialist(String specialist) => _records
      .where((r) => r.specialist.toLowerCase() == specialist.toLowerCase())
      .toList();

  bool hasRecordsForSpecialist(String specialist) =>
      _records.any((r) => r.specialist.toLowerCase() == specialist.toLowerCase());

  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService().getHealthRecords();
    if (response.isSuccess && response.data != null) {
      _records.clear();
      _records.addAll(response.data!.map((json) => HealthRecord.fromJson(json)));
    } else {
      _error = response.errorMessage ?? 'Failed to load health records';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteRecord(String id) async {
    final response = await ApiService().deleteHealthRecord(id);
    if (response.isSuccess) {
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  void addRecord(HealthRecord record) {
    _records.add(record);
    notifyListeners();
  }
}

/// Global singleton – import and use everywhere.
final healthRecordsState = HealthRecordsState();

// ═══════════════════════════════════════════════════════════════════════════════
//  HealthRecordsScreen  (main list)
// ═══════════════════════════════════════════════════════════════════════════════

class HealthRecordsScreen extends StatefulWidget {
  /// When provided, the screen scopes itself to that specialist.
  final String? specialist;
  /// When true, the upload sheet opens automatically on first frame.
  final bool autoOpenUpload;
  /// When provided, the upload sheet pre-selects this record type.
  final RecordType? initialUploadType;

  const HealthRecordsScreen({
    super.key,
    this.specialist,
    this.autoOpenUpload = false,
    this.initialUploadType,
  });

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  RecordType? _filterType;

  @override
  void initState() {
    super.initState();
    healthRecordsState.loadRecords();
    if (widget.autoOpenUpload) {
      // Open the upload sheet after the first frame so the screen is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openUploadSheet();
      });
    }
  }

  List<HealthRecord> get _base => widget.specialist != null
      ? healthRecordsState.forSpecialist(widget.specialist!)
      : healthRecordsState.records;

  List<HealthRecord> get _filtered {
    if (_filterType == null) return _base;
    return _base.where((r) => r.type == _filterType).toList();
  }

  void _openUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadRecordSheet(
        defaultSpecialist: widget.specialist ?? '',
        initialType: widget.initialUploadType ?? _filterType,
        onUploadDone: (_) {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          widget.specialist != null
              ? '${widget.specialist} Records'
              : 'Health Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: healthRecordsState,
        builder: (context, _) {
          if (healthRecordsState.isLoading && healthRecordsState.records.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }
          return Column(
            children: [
              // ── Specialist tag if scoped ───────────────────────
              if (widget.specialist != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.medical_services_rounded,
                          color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Showing records for ${widget.specialist}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // ── Filter chips ───────────────────────────────────
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterType == null,
                      onTap: () => setState(() => _filterType = null),
                    ),
                    ...RecordType.values.map((t) => _FilterChip(
                      label: t.label,
                      isSelected: _filterType == t,
                      onTap: () => setState(() => _filterType = t),
                    )),
                  ],
                ),
              ),

              // ── List / Empty ───────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? _EmptyRecordsView(onUpload: _openUploadSheet)
                    : RefreshIndicator(
                        onRefresh: () => healthRecordsState.loadRecords(),
                        color: AppTheme.primaryGreen,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final record = _filtered[i];
                            return _RecordTile(
                              record: record,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          RecordDetailScreen(record: record))),
                              onDelete: () {
                                healthRecordsState.deleteRecord(record.id);
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadSheet,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.upload_rounded, color: Colors.white),
        label: Text('Upload New',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 3,
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.withOpacity(0.25),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textMedium),
        ),
      ),
    );
  }
}

// ─── Empty Records View ───────────────────────────────────────────────────────

class _EmptyRecordsView extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyRecordsView({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file_rounded,
                size: 50, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 16),
          Text('No Records Yet',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text(
            'Start uploading records to help\nyour doctor understand your concerns',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5, color: AppTheme.textMedium, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_rounded, color: Colors.white, size: 18),
            label: Text('Upload Records',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Record Tile ──────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _RecordTile(
      {required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = record.fileUrls.isNotEmpty ? record.fileUrls.first : null;
    final isPdf = thumbUrl?.toLowerCase().endsWith('.pdf') ?? false;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: (thumbUrl != null && !isPdf)
                      ? Image.network(
                          thumbUrl.startsWith('http') ? thumbUrl : '${ApiConfig.baseUrl}$thumbUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: record.type.color.withOpacity(0.12),
                            child: Icon(record.type.icon,
                                color: record.type.color, size: 34),
                          ),
                        )
                      : Container(
                          color: record.type.color.withOpacity(0.12),
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : record.type.icon,
                            color: isPdf ? Colors.red : record.type.color,
                            size: 34,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: record.type.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(record.type.label,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: record.type.color)),
                        ),
                        if (record.specialist.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(record.specialist,
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(record.name,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(DateFormat('dd MMM yyyy').format(record.date),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textMedium)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textMedium, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'view') onTap();
                  if (val == 'share') {
                    final urls = record.fileUrls
                        .map((url) => url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url')
                        .join('\n');
                    Share.share('Medical record: ${record.name}\n$urls');
                  }
                  if (val == 'delete') _confirmDelete(context, onDelete);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(children: [
                      const Icon(Icons.visibility_rounded,
                          size: 16, color: AppTheme.textMedium),
                      const SizedBox(width: 8),
                      Text('View', style: GoogleFonts.poppins(fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(children: [
                      const Icon(Icons.share_rounded,
                          size: 16, color: AppTheme.textMedium),
                      const SizedBox(width: 8),
                      Text('Share', style: GoogleFonts.poppins(fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_rounded,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.red)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Record',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Are you sure you want to delete this record?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Upload Record Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _UploadRecordSheet extends StatefulWidget {
  final void Function(HealthRecord) onUploadDone;
  final RecordType? initialType;
  final String defaultSpecialist;

  const _UploadRecordSheet({
    required this.onUploadDone,
    this.initialType,
    this.defaultSpecialist = '',
  });

  @override
  State<_UploadRecordSheet> createState() => _UploadRecordSheetState();
}

class _UploadRecordSheetState extends State<_UploadRecordSheet> {
  late RecordType _selectedType;
  final List<File> _pickedFiles = [];
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? RecordType.labTests;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final xfile =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (xfile != null) setState(() => _pickedFiles.add(File(xfile.path)));
  }

  Future<void> _pickFromGallery() async {
    final xfiles = await _picker.pickMultiImage(imageQuality: 85);
    if (xfiles.isNotEmpty) {
      setState(() => _pickedFiles.addAll(xfiles.map((x) => File(x.path))));
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() => _pickedFiles
          .addAll(result.paths.whereType<String>().map((p) => File(p))));
    }
  }

  void _proceed() {
    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please add at least one file',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    final chosenType = _selectedType;
    final chosenFiles = List<File>.from(_pickedFiles);

    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPreviewScreen(
          files: chosenFiles,
          type: chosenType,
          defaultSpecialist: widget.defaultSpecialist,
          onConfirm: (name, date, finalType, specialist, resolvedFiles) {
            final record = HealthRecord(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name.trim().isEmpty ? finalType.label : name.trim(),
              type: finalType,
              date: date,
              fileUrls: resolvedFiles.map((f) => f.path).toList(),
              specialist: specialist,
            );
            widget.onUploadDone(record);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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

            Text('Select Report Type',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecordType.values.map((t) {
                final sel = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? t.color : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? t.color : Colors.grey.withOpacity(0.25)),
                      boxShadow: sel
                          ? [
                        BoxShadow(
                            color: t.color.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                          : [],
                    ),
                    child: Text(t.label,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppTheme.textMedium)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            Text('Upload files via',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),

            Row(
              children: [
                _UploadMethodBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: _pickFromCamera,
                ),
                const SizedBox(width: 12),
                _UploadMethodBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Images',
                  onTap: _pickFromGallery,
                ),
                const SizedBox(width: 12),
                _UploadMethodBtn(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Files',
                  onTap: _pickFiles,
                ),
              ],
            ),

            if (_pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.emerald50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_pickedFiles.length} file${_pickedFiles.length > 1 ? 's' : ''} selected',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkGreen),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _pickedFiles.clear()),
                      child: Text('Clear',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Next  →',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadMethodBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _UploadMethodBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Icon(icon, size: 22, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Preview Upload Screen
// ═══════════════════════════════════════════════════════════════════════════════

class RecordPreviewScreen extends StatefulWidget {
  final List<File> files;
  /// When provided, screen navigates instantly and loads files in background.
  final Future<List<File>>? filesFuture;
  final RecordType type;
  final String defaultSpecialist;
  final void Function(String name, DateTime date, RecordType type,
      String specialist, List<File> files) onConfirm;

  const RecordPreviewScreen({
    this.files = const [],
    this.filesFuture,
    required this.type,
    required this.onConfirm,
    this.defaultSpecialist = '',
  });

  @override
  State<RecordPreviewScreen> createState() => RecordPreviewScreenState();
}

class RecordPreviewScreenState extends State<RecordPreviewScreen> {
  late List<File> _files;
  bool _isLoadingFiles = false;
  late RecordType _selectedType;
  DateTime _selectedDate = DateTime.now();
  final _nameCtrl = TextEditingController();
  late String _selectedSpecialist;
  final _picker = ImagePicker();

  // Full specialty list
  static const List<String> _allSpecialists = [
    'General',
    'Dermatologist',
    'Neurologist',
    'Nephrologist',
    'Consulting Physician',
    'Diabetologist',
    'Cardiologist',
    'General Physician',
    'Endocrinologist',
    'Psychiatrist',
    'Gynaecologist',
    'Pulmonologist',
    'Gastroenterologist',
    'Orthopedician',
    'Pediatrician',
    'ENT',
    'Ophthalmologist',
    'Oncologist',
    'Rheumatologist',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
    _selectedType = widget.type;
    _selectedSpecialist = widget.defaultSpecialist.isNotEmpty
        ? widget.defaultSpecialist
        : 'General';

    // If a future was passed, resolve it in background — screen is already visible
    if (widget.filesFuture != null) {
      _isLoadingFiles = true;
      widget.filesFuture!.then((files) {
        if (mounted) {
          setState(() {
            _files = files;
            _isLoadingFiles = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _isLoadingFiles = false);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMoreImages() async {
    final xfiles = await _picker.pickMultiImage(imageQuality: 85);
    if (xfiles.isNotEmpty) {
      setState(() => _files.addAll(xfiles.map((x) => File(x.path))));
    }
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _upload() async {
    setState(() => _isLoadingFiles = true);

    final response = await ApiService().createHealthRecord(
      name: _nameCtrl.text.trim().isEmpty ? _selectedType.label : _nameCtrl.text.trim(),
      type: _selectedType.name,
      date: _selectedDate.toIso8601String(),
      specialist: _selectedSpecialist == 'General' ? '' : _selectedSpecialist,
      filePaths: _files.map((f) => f.path).toList(),
    );

    if (!mounted) return;
    setState(() => _isLoadingFiles = false);

    if (response.isSuccess) {
      widget.onConfirm(
        _nameCtrl.text.trim().isEmpty ? _selectedType.label : _nameCtrl.text.trim(),
        _selectedDate,
        _selectedType,
        _selectedSpecialist == 'General' ? '' : _selectedSpecialist,
        _files,
      );
      healthRecordsState.loadRecords();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record uploaded successfully!',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.errorMessage ?? 'Failed to upload record'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Upload Record',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 17)),
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
            // ── File previews ─────────────────────────────────────────
            SizedBox(
              height: 200,
              child: _isLoadingFiles
              // ── Shimmer placeholder while image future resolves ──
                  ? ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => _ShimmerBox(
                    width: 160, height: 200, radius: 12),
              )
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  if (i == _files.length) {
                    return GestureDetector(
                      onTap: _addMoreImages,
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                              AppTheme.primaryGreen.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded,
                                color: AppTheme.primaryGreen, size: 32),
                            const SizedBox(height: 6),
                            Text('Add Another\nImage',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }
                  final file = _files[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file,
                            width: 160, height: 200, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _files.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Record name ───────────────────────────────────────────
            Text('Record Name',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Blood Test Report',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                filled: true,
                fillColor: Colors.white,
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
              ),
            ),

            const SizedBox(height: 16),

            // ── Specialist ────────────────────────────────────────────
            Text('Specialist',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSpecialist,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMedium),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textDark),
                  selectedItemBuilder: (ctx) => _allSpecialists
                      .map((s) => _SpecialistDropdownItem(name: s))
                      .toList(),
                  items: _allSpecialists
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: _SpecialistDropdownItem(name: s),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSpecialist = v!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Report type ───────────────────────────────────────────
            Text('Report Type',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RecordType>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMedium),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textDark),
                  items: RecordType.values
                      .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label,
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedType = v!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Date ──────────────────────────────────────────────────
            Text('Record Date',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd-MMM-yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textDark),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textMedium),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_files.isEmpty || _isLoadingFiles) ? null : _upload,
                icon: _isLoadingFiles
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                    _isLoadingFiles ? 'Loading files...' : 'Upload Record',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer loading placeholder ──────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox(
      {required this.width, required this.height, required this.radius});
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(
              const Color(0xFFE0E0E0), const Color(0xFFF5F5F5), _anim.value),
        ),
        child: const Center(
          child: Icon(Icons.image_rounded, size: 40, color: Color(0xFFBDBDBD)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Specialist Dropdown Item — icon + colored circle + name
// ═══════════════════════════════════════════════════════════════════════════════

class _SpecialistDropdownItem extends StatelessWidget {
  final String name;
  const _SpecialistDropdownItem({required this.name});

  static const Map<String, _SpecMeta> _meta = {
    'General':               _SpecMeta(Icons.local_hospital_rounded,          Color(0xFFBAFFEE), Color(0xFF1B7A5A)),
    'Dermatologist':         _SpecMeta(Icons.face_retouching_natural_rounded,  Color(0xFFFFB3BA), Color(0xFFB71C1C)),
    'Neurologist':           _SpecMeta(Icons.psychology_rounded,               Color(0xFFFFDFBA), Color(0xFFE65100)),
    'Nephrologist':          _SpecMeta(Icons.water_drop_rounded,               Color(0xFFBAFFCE), Color(0xFF1B5E20)),
    'Consulting Physician':  _SpecMeta(Icons.medical_information_rounded,      Color(0xFFBAD4FF), Color(0xFF0D47A1)),
    'Diabetologist':         _SpecMeta(Icons.monitor_heart_rounded,            Color(0xFFFFB3BA), Color(0xFFC62828)),
    'Cardiologist':          _SpecMeta(Icons.favorite_rounded,                 Color(0xFFFFB3D9), Color(0xFFAD1457)),
    'General Physician':     _SpecMeta(Icons.local_hospital_rounded,           Color(0xFFBAFFEE), Color(0xFF1B7A5A)),
    'Endocrinologist':       _SpecMeta(Icons.biotech_rounded,                  Color(0xFFE8BAFF), Color(0xFF6A1B9A)),
    'Psychiatrist':          _SpecMeta(Icons.self_improvement_rounded,         Color(0xFFFFE4BA), Color(0xFFBF6000)),
    'Gynaecologist':         _SpecMeta(Icons.pregnant_woman_rounded,           Color(0xFFFFBAD4), Color(0xFF880E4F)),
    'Pulmonologist':         _SpecMeta(Icons.air_rounded,                      Color(0xFFBAF0FF), Color(0xFF01579B)),
    'Gastroenterologist':    _SpecMeta(Icons.airline_seat_flat_rounded,        Color(0xFFBAFFBA), Color(0xFF1B5E20)),
    'Orthopedician':         _SpecMeta(Icons.accessibility_new_rounded,        Color(0xFFFFDFBA), Color(0xFFBF360C)),
    'Pediatrician':          _SpecMeta(Icons.child_care_rounded,               Color(0xFFFFB3BA), Color(0xFFB71C1C)),
    'ENT':                   _SpecMeta(Icons.hearing_rounded,                  Color(0xFFBAD4FF), Color(0xFF1565C0)),
    'Ophthalmologist':       _SpecMeta(Icons.visibility_rounded,               Color(0xFFE8BAFF), Color(0xFF4A148C)),
    'Oncologist':            _SpecMeta(Icons.science_rounded,                  Color(0xFFFFBAD4), Color(0xFF880E4F)),
    'Rheumatologist':        _SpecMeta(Icons.elderly_rounded,                  Color(0xFFBAFFCE), Color(0xFF2E7D32)),
    'Others':                _SpecMeta(Icons.category_rounded,                 Color(0xFFE3E8F0), Color(0xFF455A64)),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta[name] ??
        const _SpecMeta(Icons.medical_services_rounded, Color(0xFFBAD4FF), Color(0xFF0D47A1));
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: m.bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(m.icon, color: m.iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SpecMeta {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _SpecMeta(this.icon, this.bgColor, this.iconColor);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Record Detail Screen
// ═══════════════════════════════════════════════════════════════════════════════

class RecordDetailScreen extends StatefulWidget {
  final HealthRecord record;
  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  int _tabIndex = 0;

  void _showActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _ActionSheetBtn(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                final urls = widget.record.fileUrls
                    .map((url) => url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url')
                    .join('\n');
                Share.share('Medical record: ${widget.record.name}\n$urls');
              },
            ),
            const Divider(height: 1),
            _ActionSheetBtn(
              icon: Icons.delete_rounded,
              label: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete Record',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    content: Text(
                        'Are you sure you want to delete this record?',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textMedium)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await healthRecordsState
                              .deleteRecord(widget.record.id);
                          if (success && mounted) {
                            Navigator.pop(context); // pop dialog
                            Navigator.pop(context); // pop detail screen
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0),
                        child: Text('Delete',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _ActionSheetBtn(
              icon: Icons.download_rounded,
              label: 'Download',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File saved to Downloads',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Record Details',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: _showActionsSheet,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(record.name,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: record.type.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(record.type.label,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: record.type.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppTheme.textMedium),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(record.date),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textMedium)),
                    if (record.specialist.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.medical_services_rounded,
                          size: 14, color: AppTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(record.specialist,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            child: Row(
              children: [
                _DetailTab(
                  label: 'Summary',
                  isSelected: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                _DetailTab(
                  label: 'Original Document',
                  isSelected: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 1),

          Expanded(
            child: _tabIndex == 0
                ? _SummaryTab(record: record)
                : _DocumentTab(record: record),
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _DetailTab(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                isSelected ? AppTheme.primaryGreen : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                isSelected ? AppTheme.primaryGreen : AppTheme.textMedium),
          ),
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final HealthRecord record;
  const _SummaryTab({required this.record});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_rounded,
                size: 50, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 16),
          Text('No Summary Available',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text(
            'Summary view is not available\nfor this specific lab report',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5, color: AppTheme.textMedium, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DocumentTab extends StatelessWidget {
  final HealthRecord record;
  const _DocumentTab({required this.record});

  @override
  Widget build(BuildContext context) {
    if (record.fileUrls.isEmpty) {
      return Center(
        child: Text('No files attached',
            style: GoogleFonts.poppins(
                color: AppTheme.textMedium, fontSize: 13)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: record.fileUrls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final url = record.fileUrls[i];
        final isPdf = url.toLowerCase().endsWith('.pdf');
        final fullUrl = url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';

        if (isPdf) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        url.split('/').last,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PDF Document',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.description_rounded, color: AppTheme.primaryGreen),
              ],
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionSheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionSheetBtn(
      {required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ],
        ),
      ),
    );
  }
}