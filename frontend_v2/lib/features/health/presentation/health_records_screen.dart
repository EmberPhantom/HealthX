import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../core/models/health_record_model.dart';
import '../providers/health_records_provider.dart';
import '../../../core/network/api_constants.dart';
String _resolveRecordUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  final cleanUrl = url.startsWith('/') ? url : '/$url';
  return '${ApiConfig.baseUrl}$cleanUrl';
}

class HealthRecordsScreen extends ConsumerStatefulWidget {
  final String? specialist;
  final bool autoOpenUpload;
  final RecordType? initialUploadType;

  const HealthRecordsScreen({
    super.key,
    this.specialist,
    this.autoOpenUpload = false,
    this.initialUploadType,
  });

  @override
  ConsumerState<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen> {
  RecordType? _filterType;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(healthRecordsProvider.notifier).fetchRecords(specialist: widget.specialist);
      if (widget.autoOpenUpload) {
        _openUploadSheet();
      }
    });
  }

  void _openUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadRecordSheet(
        defaultSpecialist: widget.specialist ?? '',
        initialType: widget.initialUploadType ?? _filterType,
        onUploadDone: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(healthRecordsProvider);

    final filteredRecords = recordsState.records.where((record) {
      final matchesSpecialist = widget.specialist == null ||
          record.specialist.toLowerCase() == widget.specialist!.toLowerCase();
      final matchesType = _filterType == null || record.type == _filterType;
      return matchesSpecialist && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.specialist != null ? '${widget.specialist} Records' : 'Health Records',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
        ),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: recordsState.isLoading && recordsState.records.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ShimmerLoading(height: 80),
                SizedBox(height: 12),
                ShimmerLoading(height: 80),
                SizedBox(height: 12),
                ShimmerLoading(height: 80),
              ],
            )
          : Column(
              children: [
                // Specialist tag if scoped
                if (widget.specialist != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsRegular.stethoscope, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Showing records for ${widget.specialist}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Filter chips
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    children: [
                      _buildFilterChip('All', _filterType == null, () => setState(() => _filterType = null)),
                      ...RecordType.values.map((t) => _buildFilterChip(
                            t.label,
                            _filterType == t,
                            () => setState(() => _filterType = t),
                          )),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filteredRecords.isEmpty
                      ? _buildEmptyView()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(healthRecordsProvider.notifier).fetchRecords(specialist: widget.specialist);
                          },
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filteredRecords.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final record = filteredRecords[index];
                              return _RecordTile(
                                record: record,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecordDetailScreen(record: record),
                                  ),
                                ),
                                onDelete: () async {
                                  await ref.read(healthRecordsProvider.notifier).deleteRecord(record.id);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadSheet,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.tertiary,
        icon: const Icon(PhosphorIconsBold.fileArrowUp, size: 18),
        label: const Text('Upload New', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.secondary : AppColors.border, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.tertiary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.fileText, size: 40, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Records Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your medical reports, scan logs, and prescriptions to access them dynamically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'UPLOAD RECORDS',
              isFullWidth: false,
              onPressed: _openUploadSheet,
              icon: const Icon(PhosphorIconsBold.fileArrowUp, color: AppColors.secondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = record.fileUrls.isNotEmpty ? record.fileUrls.first : null;
    final isPdf = thumbUrl?.toLowerCase().endsWith('.pdf') ?? false;

    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child: (thumbUrl != null && !isPdf)
                    ? Image.network(
                        _resolveRecordUrl(thumbUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: record.type.color.withValues(alpha: 0.1),
                          child: Icon(record.type.icon, color: record.type.color, size: 28),
                        ),
                      )
                    : Container(
                        color: record.type.color.withValues(alpha: 0.1),
                        child: Icon(
                          isPdf ? PhosphorIconsRegular.filePdf : record.type.icon,
                          color: isPdf ? Colors.red : record.type.color,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        text: record.type.label.toUpperCase(),
                        dotColor: record.type.color,
                        backgroundColor: record.type.color.withValues(alpha: 0.1),
                        textColor: record.type.color,
                      ),
                      if (record.specialist.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        StatusBadge(
                          text: record.specialist.toUpperCase(),
                          dotColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          textColor: AppColors.secondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(record.date),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: AppColors.neutral, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (val) {
                if (val == 'view') onTap();
                if (val == 'share') {
                  Share.share('Medical record: ${record.name}\n${record.fileUrls.join('\n')}');
                }
                if (val == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.eye, size: 16),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.shareNetwork, size: 16),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.trash, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class RecordDetailScreen extends StatefulWidget {
  final HealthRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Record Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.shareNetwork, color: AppColors.secondary),
            onPressed: () {
              Share.share('Medical record: ${record.name}\n${record.fileUrls.join('\n')}');
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.tertiary,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    StatusBadge(
                      text: record.type.label.toUpperCase(),
                      dotColor: record.type.color,
                      backgroundColor: record.type.color.withValues(alpha: 0.1),
                      textColor: record.type.color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.calendar, size: 14, color: AppColors.neutral),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(record.date),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (record.specialist.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(PhosphorIconsRegular.stethoscope, size: 14, color: AppColors.neutral),
                      const SizedBox(width: 6),
                      Text(
                        record.specialist,
                        style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.tertiary,
            child: Row(
              children: [
                _buildTab('Summary', 0),
                _buildTab('Original Document', 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tabIndex == 0 ? _buildSummaryTab() : _buildDocumentTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.fileText, size: 36, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Summary Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI summary view is not generated yet for this document.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTab() {
    if (widget.record.fileUrls.isEmpty) {
      return const Center(child: Text('No files attached', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.record.fileUrls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final url = widget.record.fileUrls[i];
        final isPdf = url.toLowerCase().endsWith('.pdf');

        if (isPdf) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.filePdf, color: Colors.red, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        url.split('/').last,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'PDF Document',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(PhosphorIconsRegular.download, color: AppColors.secondary, size: 20),
              ],
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _resolveRecordUrl(url),
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            },
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              color: Colors.grey.shade100,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.warningCircle, color: Colors.red, size: 32),
                  SizedBox(height: 8),
                  Text('Failed to load image preview', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UploadRecordSheet extends ConsumerStatefulWidget {
  final RecordType? initialType;
  final String defaultSpecialist;
  final VoidCallback onUploadDone;

  const _UploadRecordSheet({
    this.initialType,
    required this.defaultSpecialist,
    required this.onUploadDone,
  });

  @override
  ConsumerState<_UploadRecordSheet> createState() => _UploadRecordSheetState();
}

class _UploadRecordSheetState extends ConsumerState<_UploadRecordSheet> {
  late RecordType _selectedType;
  final List<File> _pickedFiles = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? RecordType.labTests;
  }

  Future<void> _pickFromCamera() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (xfile != null) {
      setState(() => _pickedFiles.add(File(xfile.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final xfiles = await _picker.pickMultiImage(imageQuality: 85);
    if (xfiles.isNotEmpty) {
      setState(() => _pickedFiles.addAll(xfiles.map((x) => File(x.path))));
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        _pickedFiles.addAll(result.paths.whereType<String>().map((p) => File(p)));
      });
    }
  }

  void _proceed() {
    if (_pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one image/document.'),
          backgroundColor: AppColors.error,
        ),
      );
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
          onConfirm: () {
            widget.onUploadDone();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Report Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecordType.values.map((t) {
                final sel = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? t.color : AppColors.tertiary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? t.color : AppColors.border, width: 0.8),
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload files via',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildUploadButton(PhosphorIconsRegular.camera, 'Camera', _pickFromCamera),
                const SizedBox(width: 12),
                _buildUploadButton(PhosphorIconsRegular.image, 'Gallery', _pickFromGallery),
                const SizedBox(width: 12),
                _buildUploadButton(PhosphorIconsRegular.fileText, 'Files', _pickFiles),
              ],
            ),
            if (_pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.checkCircle, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_pickedFiles.length} file(s) selected',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _pickedFiles.clear()),
                      child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'PROCEED',
              onPressed: _proceed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.secondary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordPreviewScreen extends ConsumerStatefulWidget {
  final List<File> files;
  final RecordType type;
  final String defaultSpecialist;
  final VoidCallback onConfirm;

  const RecordPreviewScreen({
    super.key,
    required this.files,
    required this.type,
    required this.defaultSpecialist,
    required this.onConfirm,
  });

  @override
  ConsumerState<RecordPreviewScreen> createState() => _RecordPreviewScreenState();
}

class _RecordPreviewScreenState extends ConsumerState<RecordPreviewScreen> {
  late List<File> _files;
  late RecordType _selectedType;
  DateTime _selectedDate = DateTime.now();
  final _nameCtrl = TextEditingController();
  late String _selectedSpecialist;
  final _picker = ImagePicker();

  static const List<String> _specialties = [
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
    _selectedSpecialist = widget.defaultSpecialist.isNotEmpty ? widget.defaultSpecialist : 'General';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _upload() async {
    final name = _nameCtrl.text.trim().isEmpty ? _selectedType.label : _nameCtrl.text.trim();
    final specialist = _selectedSpecialist == 'General' ? '' : _selectedSpecialist;

    final success = await ref.read(healthRecordsProvider.notifier).uploadRecord(
          name: name,
          type: _selectedType.name,
          date: _selectedDate.toIso8601String(),
          specialist: specialist,
          filePaths: _files.map((f) => f.path).toList(),
        );

    if (!mounted) return;

    if (success) {
      widget.onConfirm();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record uploaded successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(healthRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Upload Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  if (i == _files.length) {
                    return GestureDetector(
                      onTap: _addMoreImages,
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.imageSquare, color: AppColors.secondary, size: 28),
                            SizedBox(height: 6),
                            Text(
                              'Add Image',
                              style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final file = _files[i];
                  final isPdf = file.path.toLowerCase().endsWith('.pdf');

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140,
                          height: 180,
                          color: AppColors.tertiary,
                          child: isPdf
                              ? const Center(child: Icon(PhosphorIconsRegular.filePdf, size: 48, color: Colors.red))
                              : Image.file(file, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _files.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(PhosphorIconsRegular.x, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Record Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Annual Blood Panel',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Specialist Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSpecialist,
                  isExpanded: true,
                  icon: const Icon(PhosphorIconsRegular.caretDown),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  items: _specialties
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSpecialist = val!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Report Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.calendar, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(PhosphorIconsRegular.caretDown, color: AppColors.neutral),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'CONFIRM UPLOAD',
              isLoading: recordsState.isLoading,
              onPressed: _upload,
            ),
          ],
        ),
      ),
    );
  }
}
